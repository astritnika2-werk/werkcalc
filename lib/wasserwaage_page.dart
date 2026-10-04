import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'wasserwaage_auto.dart';
import 'wasserwaage_logik.dart';

const _kHinweis =
    'Die Messung erfolgt mit den Bewegungssensoren des Smartphones. '
    'Die Genauigkeit hängt vom Gerät, der Positionierung und der Kalibrierung ab.';

// Farben der Messgeräte-Oberfläche (Wasserwaage).
const _kBg = Color(0xFF071B3F);
const _kKarte = Color(0xFF0E2A57);
const _kRand = Color(0xFF244A86);
const _kText = Colors.white;
const _kText2 = Color(0xFFA9B9D6);
const _kBlau = Color(0xFF0B4A9F);
const _kLimeMitte = Color(0xFFA6EA00);
const _kGruen = Color(0xFF2FBF4A);
const _ziffern = [FontFeature.tabularFigures()];

/// Zeitkonstante der reinen Anzeige-Beruhigung in Sekunden. Die Messung (GravityFilter,
/// Kalibrierung, Berechnung) bleibt unverändert; nur was auf dem Bildschirm steht, wird
/// zusätzlich geglättet. Die Messglättung hat 0,5 s, 0,15 s = rund 30 % davon
/// (erster Versuch; 0,2 s wären rund 40 %). Interner Anzeigewert, keine Herstellervorgabe, keine Norm.
const double kAnzeigeTau = 0.15;

/// Einfache exponentielle Glättung (Tiefpass erster Ordnung) des Schwerkraftvektors
/// nur für die Anzeige. Im Ruhezustand ist das Ergebnis exakt der Messwert (kein Versatz,
/// kein Einfrieren); bei Bewegung folgt die Anzeige flüssig mit kleiner Verzögerung.
class AnzeigeFilter {
  AnzeigeFilter({this.tau = kAnzeigeTau});
  final double tau;
  double x = 0, y = 0, z = 0;
  bool initialisiert = false;

  void update(double ax, double ay, double az, double dt) {
    if (!initialisiert) {
      x = ax;
      y = ay;
      z = az;
      initialisiert = true;
      return;
    }
    if (dt <= 0) return;
    final k = 1 - math.exp(-dt / tau);
    x += k * (ax - x);
    y += k * (ay - y);
    z += k * (az - z);
  }
}

/// Wasserwaage / digitaler Nivellierer.
/// Sensorik: Beschleunigungssensor (Schwerkraft) + Gyroskop zur Glättung.
/// Die Lage des Handys (flach, auf der Seite, aufrecht) wird aus dem
/// Schwerkraftvektor bestimmt, nicht aus der Bildschirmdrehung.
class WasserwaagePage extends StatefulWidget {
  const WasserwaagePage({super.key});

  @override
  State<WasserwaagePage> createState() => _WasserwaagePageState();
}

class _WasserwaagePageState extends State<WasserwaagePage> {
  static const _kalibrierMs = 2000;

  StreamSubscription<AccelerometerEvent>? _sa;
  StreamSubscription<GyroscopeEvent>? _sg;
  Timer? _timer;
  final Stopwatch _uhr = Stopwatch();
  final GravityFilter _filter = GravityFilter();
  final AnzeigeFilter _anzeige = AnzeigeFilter(); // nur Darstellung, nicht Messung
  int _anzeigeUs = 0;
  final ModusUmschalter _umschalter = ModusUmschalter(Modus.flaeche);
  bool _auto = true; // automatische Umschaltung (manuelle Wahl schaltet sie aus)
  int _autoUs = 0;
  int _letzteUs = 0;
  double? _gx, _gy, _gz; // letzte Drehrate (rad/s)
  bool _hatWerte = false;
  String? _fehler;
  Modus _modus = Modus.flaeche; // vom Nutzer gewählt, wird nicht erraten
  Modus _linie = Modus.linieDisplay; // zuletzt gewählte Linien-Betriebsart

  final Map<Modus, ModusKalibrierung> _kals = {};
  bool _kalLaeuft = false;
  int _kalStart = 0;
  String? _kalMeldung;
  String? _kalOk;
  final List<Vek> _kalProben = [];

  @override
  void initState() {
    super.initState();
    // Das Layout bleibt im Hochformat; die Messung hängt nicht an der Drehung.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _uhr.start();
    _sa = accelerometerEventStream(samplingPeriod: const Duration(milliseconds: 10)).listen(_beschleunigung,
        onError: (_) {
      if (mounted) {
        setState(() => _fehler = 'Beschleunigungssensor nicht verfügbar – dieses Handy liefert keine Messwerte.');
      }
    });
    _sg = gyroscopeEventStream(samplingPeriod: const Duration(milliseconds: 10)).listen((e) {
      _gx = e.x;
      _gy = e.y;
      _gz = e.z;
    }, onError: (_) {
      _gx = _gy = _gz = null; // ohne Gyroskop: nur Beschleunigungsglättung
    });
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (!mounted) return;
      if (_kalLaeuft && _hatWerte) {
        _kalProben.add((x: _filter.x, y: _filter.y, z: _filter.z));
        if (_uhr.elapsedMilliseconds - _kalStart >= _kalibrierMs) _kalibrierungAbschliessen();
      }
      if (_hatWerte) {
        final jetzt0 = _uhr.elapsedMicroseconds;
        final dtAuto = math.min((jetzt0 - _autoUs) / 1e6, 0.1);
        _autoUs = jetzt0;
        if (_auto && !_kalLaeuft) {
          final neu = _umschalter.update(_filter.x, _filter.y, _filter.z, dtAuto);
          if (neu != null) _modusWaehlen(neu, manuell: false);
        } else {
          _umschalter.zuruecksetzen();
        }
        final jetzt = _uhr.elapsedMicroseconds;
        _anzeige.update(_filter.x, _filter.y, _filter.z, (jetzt - _anzeigeUs) / 1e6);
        _anzeigeUs = jetzt;
      }
      setState(() {});
    });
  }

  void _beschleunigung(AccelerometerEvent e) {
    final jetzt = _uhr.elapsedMicroseconds;
    final dt = _hatWerte ? (jetzt - _letzteUs) / 1e6 : 0.0;
    _letzteUs = jetzt;
    _filter.update(ax: e.x, ay: e.y, az: e.z, dt: dt, gx: _gx, gy: _gy, gz: _gz);
    _hatWerte = true;
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _sa?.cancel();
    _sg?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _kalibrierenStart() {
    _kalProben.clear();
    _kalMeldung = null;
    _kalOk = null;
    _kalLaeuft = true;
    _kalStart = _uhr.elapsedMilliseconds;
    setState(() {});
  }

  void _kalibrierungAbschliessen() {
    _kalLaeuft = false;
    final k = kalibriereModus(_modus, List.of(_kalProben));
    if (k == null) {
      _kalMeldung = 'Kalibrierung nicht möglich: Das Handy liegt nicht in der Lage dieser Betriebsart '
          '(${_modus.name2}) oder es gibt keinen Sensorwert. Bitte wiederholen.';
    } else if (k.streuungGrad > kKalibrierMaxStreuung) {
      _kalMeldung = 'Das Handy wurde während der Kalibrierung bewegt. Bitte ruhig hinlegen und wiederholen.';
    } else {
      _kals[_modus] = k;
      _kalOk = _modus.name2;
      _kalMeldung = null;
    }
  }

  void _zuruecksetzen() {
    setState(() {
      _kals.clear();
      _kalMeldung = null;
      _kalOk = null;
      _kalLaeuft = false;
    });
  }

  void _hilfe() {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Wasserwaage'),
        content: SingleChildScrollView(
          child: Text(
            'Die Betriebsart wechselt automatisch, sobald das Handy kurz (ca. 1 Sekunde) ruhig in einer der '
            'vier Lagen liegt. Kleine Bewegungen lösen keinen Wechsel aus. Mit dem Schalter „Automatisch '
            'umschalten“ oder durch eigene Wahl einer Betriebsart können Sie die Automatik ausschalten. '
            'Gemessen wird immer nur in der gewählten Betriebsart.\n\n'
            'Fläche (2D): Handy flach auf die Rückseite (Display oben). Der Marker zeigt die Neigung in '
            'zwei Achsen (X nach rechts, Y nach vorne) und steht bei X 0,00° / Y 0,00° genau in der Mitte.\n'
            'Linie – Display vorne: Handy aufrecht, Display zum Benutzer. Gemessen wird links/rechts '
            'über die Breite (X-Achse).\n'
            'Linie – Linke Seite: Handy steht auf der linken Seitenkante, Display zum Benutzer '
            '(Oberkante zeigt nach links). Gemessen wird entlang der Längskante (Y-Achse). Die '
            'Anzeige ist dafür gedreht, damit sie in dieser Lage lesbar ist.\n'
            'Linie – Rechte Seite: wie links, nur auf der rechten Seitenkante (Oberkante zeigt nach rechts).\n'
            'Der Marker bewegt sich immer zur höheren Seite. Skala: ±5° (darüber bleibt der Marker am Rand und wird orange).\n\n'
            'Kalibrieren: Handy auf eine Referenzfläche legen und „Kalibrieren“ tippen. Die Lage in '
            'dieser Zeit (ca. 2 Sekunden) gilt danach als 0,00°. Die Kalibrierung gilt für die '
            'gewählte Betriebsart. „Zurücksetzen“ löscht alle.\n\n'
            'Neigung: Winkel gegen die Senkrechte der Lage. Gefälle %: Höhenunterschied je 100 cm. '
            'Gefälle mm/m: Höhenunterschied je Meter.\n\n'
            'Die Anzeige ist linear und verwendet exakt die gemessenen Werte. Die Werte werden mit dem Gyroskop geglättet, damit sie nicht '
            'springen; im Ruhezustand entspricht der Wert genau der Messung.\n\n$_kHinweis',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
      ),
    );
  }

  void _modusWaehlen(Modus m, {bool manuell = true}) {
    if (manuell && _auto) {
      // Wer selbst wählt, behält diese Wahl: die Automatik schaltet sich aus.
      setState(() => _auto = false);
    }
    _umschalter.setze(m);
    if (m == _modus) return;
    setState(() {
      _modus = m;
      if (!m.istFlaeche) _linie = m;
      _kalLaeuft = false;
      _kalMeldung = null;
      _kalOk = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = _modus;
    final kal = _kals[m];
    Neigung? n;
    Linienmessung? l;
    var lageOk = false;
    if (_hatWerte) {
      lageOk = lageStimmt(m, _anzeige.x, _anzeige.y, _anzeige.z);
      if (m.istFlaeche) {
        n = berechneNeigung(_anzeige.x, _anzeige.y, _anzeige.z, lage: m.lage, a0: kal?.a0 ?? 0, b0: kal?.b0 ?? 0);
      } else {
        l = berechneLinie(m, _anzeige.x, _anzeige.y, _anzeige.z, a0: kal?.a0 ?? 0);
      }
    }

    final koerper = <Widget>[
      _Umschalter(modus: m, linie: _linie, onChanged: _modusWaehlen),
      const SizedBox(height: 8),
      _AutoSchalter(
        an: _auto,
        onChanged: (v) => setState(() {
          _auto = v;
          _umschalter.setze(_modus);
        }),
      ),
      const SizedBox(height: 10),
      Text(m.name2, style: const TextStyle(color: _kText, fontWeight: FontWeight.w700, fontSize: 15)),
      const SizedBox(height: 2),
      Text(m.anleitung, style: const TextStyle(color: _kText2, fontSize: 13)),
      const SizedBox(height: 4),
      Text(
        !_hatWerte
            ? 'Warte auf Sensor …'
            : (lageOk ? 'Handy liegt in der Lage dieser Betriebsart' : 'Handy liegt nicht in dieser Lage'),
        style: TextStyle(color: (_hatWerte && !lageOk) ? const Color(0xFFFFD27A) : _kText2, fontSize: 12),
      ),
      const SizedBox(height: 12),
      if (_fehler != null)
        _Karte(child: Text(_fehler!, style: const TextStyle(color: _kText)))
      else if (m.istFlaeche)
        ..._flaecheAnsicht(n, lageOk)
      else
        ..._linieAnsicht(m, l, lageOk),
      const SizedBox(height: 12),
      _kalibrierung(kal),
      const SizedBox(height: 12),
      const _Karte(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, color: _kText2, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Hinweis zur Messung', style: TextStyle(fontWeight: FontWeight.bold, color: _kText)),
              SizedBox(height: 4),
              Text(_kHinweis, style: TextStyle(color: _kText2)),
            ]),
          ),
        ]),
      ),
    ];

    final drehung = m.viertelDrehungen;
    if (drehung == 0) {
      return Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          title: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Wasserwaage'),
              Text('Digitaler Nivellierer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
            ],
          ),
          centerTitle: true,
          actions: [IconButton(icon: const Icon(Icons.help_outline), tooltip: 'Hilfe', onPressed: _hilfe)],
        ),
        body: ListView(padding: const EdgeInsets.all(16), children: koerper),
      );
    }

    // Seitenlage: Die Oberfläche wird gedreht, damit sie in dieser Lage aufrecht lesbar ist
    // (linke Seite: Oberkante zeigt nach links → Drehung im Uhrzeigersinn; rechte Seite: umgekehrt).
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: RotatedBox(
          quarterTurns: drehung,
          child: Column(
            children: [
              Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: _kText),
                  tooltip: 'Zurück',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const Expanded(
                  child: Text('Wasserwaage – Digitaler Nivellierer',
                      style: TextStyle(color: _kText, fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                IconButton(
                    icon: const Icon(Icons.help_outline, color: _kText), tooltip: 'Hilfe', onPressed: _hilfe),
              ]),
              Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: koerper)),
            ],
          ),
        ),
      ),
    );
  }

  // ───────── Fläche (2D) ─────────
  List<Widget> _flaecheAnsicht(Neigung? n, bool lageOk) {
    final Neigung? m = (n != null && n.gueltig && lageOk) ? n : null;
    return [
      Center(
        child: Text(
          m == null ? 'X – / Y –' : 'X ${zahl(m.aGrad)}° / Y ${zahl(m.bGrad)}°',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _kText, fontFeatures: _ziffern),
        ),
      ),
      const SizedBox(height: 10),
      LayoutBuilder(builder: (context, c) {
        final d = math.min(c.maxWidth, 420.0);
        return Center(
          child: SizedBox(
            width: d,
            height: d,
            child: CustomPaint(size: Size(d, d), painter: FlaechePainter(neigung: m)),
          ),
        );
      }),
      const SizedBox(height: 10),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _AchsenKachel(titel: 'X (links/rechts)', grad: m?.aGrad, steigung: m?.sx)),
        const SizedBox(width: 10),
        Expanded(child: _AchsenKachel(titel: 'Y (vorne/hinten)', grad: m?.bGrad, steigung: m?.sy)),
      ]),
      const SizedBox(height: 10),
      _Banner(n: m),
    ];
  }

  // ───────── Linie (1D) ─────────
  List<Widget> _linieAnsicht(Modus modus, Linienmessung? l, bool lageOk) {
    final Linienmessung? m = (l != null && l.gueltig && lageOk) ? l : null;
    final grad = m?.grad ?? 0.0;
    final text = m == null ? '–' : linienRichtung(m).toUpperCase();
    final waagerecht = m != null && text == 'WAAGERECHT';
    return [
      Center(
        child: Text(m == null ? '–' : '${zahl(grad)}°',
            style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w800, color: _kText, fontFeatures: _ziffern)),
      ),
      Center(
        child: Text(
          m == null ? '–' : '${zahl(m.prozent)} %   |   ${zahl(m.mmProM, 0)} mm/m',
          style: const TextStyle(fontSize: 19, color: _kText, fontFeatures: _ziffern),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 120,
        child: CustomPaint(
          painter: SkalaPainter(grad: grad, aktiv: m != null),
          child: const SizedBox.expand(),
        ),
      ),
      const SizedBox(height: 6),
      Center(child: Text(modus.achseText, style: const TextStyle(color: _kText2, fontSize: 12))),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: waagerecht ? const Color(0xFF123F27) : const Color(0xFFDCE8FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: waagerecht ? _kGruen : const Color(0xFF9DB9E6)),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 22,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
                color: waagerecht ? _kText : const Color(0xFF0B2A5B))),
      ),
    ];
  }

  Widget _kalibrierung(ModusKalibrierung? kal) {
    return _Karte(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_kalLaeuft)
          const Row(children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _kText)),
            SizedBox(width: 10),
            Expanded(child: Text('Kalibrierung läuft – Handy ruhig halten …', style: TextStyle(color: _kText))),
          ])
        else if (_kalOk != null)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.verified_outlined, color: _kGruen, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('Kalibrierung abgeschlossen\n($_kalOk)', style: const TextStyle(color: _kText))),
          ])
        else if (kal != null)
          const Text('Kalibriert (diese Betriebsart)', style: TextStyle(color: _kText))
        else
          const Text('Nicht kalibriert (diese Betriebsart)', style: TextStyle(color: _kText2)),
        if (_kalMeldung != null) ...[
          const SizedBox(height: 8),
          Text(_kalMeldung!, style: const TextStyle(color: Color(0xFFFFB4A9))),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _kBlau, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: (_hatWerte && !_kalLaeuft) ? _kalibrierenStart : null,
              icon: const Icon(Icons.my_location),
              label: const Text('Kalibrieren'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _kText,
                side: const BorderSide(color: _kRand),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: (_kals.isNotEmpty && !_kalLaeuft) ? _zuruecksetzen : null,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Zurücksetzen'),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ───────────────────────── Bausteine ─────────────────────────

class _Karte extends StatelessWidget {
  const _Karte({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kKarte,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kRand.withValues(alpha: 0.6)),
        ),
        child: child,
      );
}

class _Umschalter extends StatelessWidget {
  const _Umschalter({required this.modus, required this.linie, required this.onChanged});
  final Modus modus;
  final Modus linie;
  final ValueChanged<Modus> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(String text, bool aktiv, VoidCallback tap, {double size = 15}) => Expanded(
          child: GestureDetector(
            onTap: tap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: aktiv ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: size, fontWeight: FontWeight.w700, color: aktiv ? const Color(0xFF0B2A5B) : _kText)),
            ),
          ),
        );
    BoxDecoration rahmen() =>
        BoxDecoration(color: _kKarte, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kRand));
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(4),
        decoration: rahmen(),
        child: Row(children: [
          tab('Fläche (2D)', modus.istFlaeche, () => onChanged(Modus.flaeche)),
          tab('Linie (1D)', !modus.istFlaeche, () => onChanged(linie)),
        ]),
      ),
      if (!modus.istFlaeche) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: rahmen(),
          child: Row(children: [
            for (final m in [Modus.linieDisplay, Modus.linieLinks, Modus.linieRechts])
              tab(m.name2, modus == m, () => onChanged(m), size: 13),
          ]),
        ),
      ],
    ]);
  }
}

class _AutoSchalter extends StatelessWidget {
  const _AutoSchalter({required this.an, required this.onChanged});
  final bool an;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
        decoration: BoxDecoration(
            color: _kKarte, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kRand)),
        child: Row(children: [
          const Icon(Icons.screen_rotation_alt_outlined, color: _kText2, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Automatisch umschalten',
                  style: TextStyle(color: _kText, fontWeight: FontWeight.w700, fontSize: 14)),
              Text(
                an
                    ? 'Die Ansicht wechselt, sobald das Handy kurz ruhig in einer der vier Lagen liegt.'
                    : 'Aus: Die Betriebsart bleibt, wie Sie sie gewählt haben.',
                style: const TextStyle(color: _kText2, fontSize: 12),
              ),
            ]),
          ),
          Switch(value: an, onChanged: onChanged),
        ]),
      );
}

class _AchsenKachel extends StatelessWidget {
  const _AchsenKachel({required this.titel, required this.grad, required this.steigung});
  final String titel;
  final double? grad;
  final double? steigung;

  @override
  Widget build(BuildContext context) {
    final g = grad, s = steigung;
    return _Karte(
      child: Column(children: [
        Text(titel, style: const TextStyle(color: _kText2, fontSize: 13)),
        const SizedBox(height: 4),
        Text(g == null ? '–' : '${zahl(g)}°',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: _kText, fontFeatures: _ziffern)),
        const SizedBox(height: 2),
        Text(s == null ? '–' : '${zahl(s * 100, 1)} %',
            style: const TextStyle(color: _kText, fontSize: 14, fontFeatures: _ziffern)),
        Text(s == null ? '–' : '${zahl(s * 1000, 0)} mm/m',
            style: const TextStyle(color: _kText, fontSize: 14, fontFeatures: _ziffern)),
      ]),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.n});

  /// null, wenn kein gültiger Messwert vorliegt.
  final Neigung? n;

  @override
  Widget build(BuildContext context) {
    final neigung = n;
    final text = neigung == null ? '–' : richtungsText(neigung);
    final waagerecht = neigung != null && text == 'Waagerecht';
    final unter = neigung == null ? 'Warte auf Messwert' : 'Neigung gemessen: ${zahl(neigung.gesamtGrad)}°';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: waagerecht ? const Color(0xFF123F27) : const Color(0xFFDCE8FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: waagerecht ? _kGruen : const Color(0xFF9DB9E6)),
      ),
      child: Row(children: [
        Icon(waagerecht ? Icons.check_circle : Icons.explore_outlined,
            size: 30, color: waagerecht ? _kGruen : const Color(0xFF0B4A9F)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(text,
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800, color: waagerecht ? _kText : const Color(0xFF0B2A5B))),
            Text(unter, style: TextStyle(fontSize: 13, color: waagerecht ? _kText2 : const Color(0xFF28446F))),
          ]),
        ),
      ]),
    );
  }
}

// ───────────────────────── Zeichnung ─────────────────────────

/// Skalenbereich der digitalen Anzeige in Grad (±). Die Anzeige ist linear;
/// darüber hinaus bleibt der Marker am Rand stehen und wird orange.
const double _kSkala = 5.0;

/// Lage des Markers auf der 1D-Skala: −1 (links, −5°) … 0 (Mitte, 0°) … +1 (rechts, +5°).
/// Linear im Messwert; über den Rand hinaus bleibt der Marker am Rand.
double skalaAnteil(double grad) => (grad / _kSkala).clamp(-1.0, 1.0);

/// Lage des Markers in der 2D-Fläche (x nach rechts, y nach oben, −1…1), linear in den
/// Messwerten X und Y (Grad). Außerhalb der Skala bleibt die Richtung erhalten.
({double x, double y, bool ausserhalb}) flaechenAnteil(double xGrad, double yGrad) {
  final groesst = math.max(xGrad.abs(), yGrad.abs());
  if (groesst > _kSkala) {
    return (x: xGrad / groesst, y: yGrad / groesst, ausserhalb: true);
  }
  return (x: xGrad / _kSkala, y: yGrad / _kSkala, ausserhalb: false);
}
const _kOrange = Color(0xFFFFA24A);

void _beschriften(Canvas canvas, String text, Offset pos,
    {Color color = _kText2, double size = 12, FontWeight weight = FontWeight.w600, Alignment anker = Alignment.center}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size, fontWeight: weight, fontFeatures: _ziffern)),
    textDirection: TextDirection.ltr,
  )..layout();
  final dx = pos.dx - tp.width * (anker.x + 1) / 2;
  final dy = pos.dy - tp.height * (anker.y + 1) / 2;
  tp.paint(canvas, Offset(dx, dy));
}

/// Digitale Skala (1D): −5° … +5°, Marker bewegt sich linear mit dem Messwert.
/// Bei exakt 0° steht der Marker genau in der Mitte.
class SkalaPainter extends CustomPainter {
  SkalaPainter({required this.grad, required this.aktiv});
  final double grad;
  final bool aktiv;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final box = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(14));
    canvas.drawRRect(box, Paint()..color = _kKarte);
    canvas.drawRRect(
        box,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = _kRand);

    const rand = 28.0;
    final x0 = rand, x1 = w - rand;
    final cx = (x0 + x1) / 2;
    final achseY = h * 0.62;
    double xAt(double g) => cx + (g / _kSkala) * (x1 - x0) / 2;

    // Kopfzeile: Richtung der Seiten.
    _beschriften(canvas, '◀ LINKS HÖHER', Offset(14, 14), size: 11, anker: Alignment.centerLeft);
    _beschriften(canvas, 'RECHTS HÖHER ▶', Offset(w - 14, 14), size: 11, anker: Alignment.centerRight);

    final achse = Paint()
      ..color = _kText2
      ..strokeWidth = 2;
    canvas.drawLine(Offset(x0, achseY), Offset(x1, achseY), achse);

    // Teilstriche: alle 0,5°, groß bei −5, −2,5, 0, +2,5, +5.
    for (var i = -10; i <= 10; i++) {
      final g = i * 0.5;
      final gross = i % 5 == 0;
      final null0 = i == 0;
      final len = null0 ? 26.0 : (gross ? 18.0 : 8.0);
      canvas.drawLine(
        Offset(xAt(g), achseY),
        Offset(xAt(g), achseY + len),
        Paint()
          ..color = null0 ? _kLimeMitte : _kText2
          ..strokeWidth = null0 ? 3 : (gross ? 2 : 1),
      );
    }
    const marken = <double>[-5, -2.5, 0, 2.5, 5];
    for (final g in marken) {
      final t = g == 0 ? '0°' : '${g > 0 ? '+' : '−'}${zahl(g.abs(), g.abs() == 2.5 ? 1 : 0)}°';
      _beschriften(canvas, t, Offset(xAt(g), achseY + 38),
          color: g == 0 ? _kText : _kText2, size: 13, weight: g == 0 ? FontWeight.w800 : FontWeight.w600);
    }

    // Marker.
    final ausserhalb = grad.abs() > _kSkala;
    final mx = cx + (aktiv ? skalaAnteil(grad) : 0) * (x1 - x0) / 2;
    final farbe = !aktiv
        ? const Color(0xFF8E99AB)
        : (ausserhalb ? _kOrange : (zahl(grad) == '0,00' ? _kGruen : Colors.white));
    canvas.drawLine(Offset(mx, 30), Offset(mx, achseY), Paint()
      ..color = farbe.withValues(alpha: 0.55)
      ..strokeWidth = 2);
    final dreieck = Path()
      ..moveTo(mx - 10, 30)
      ..lineTo(mx + 10, 30)
      ..lineTo(mx, 46)
      ..close();
    canvas.drawPath(dreieck, Paint()..color = farbe);
    canvas.drawCircle(Offset(mx, achseY), 9, Paint()..color = farbe);
    canvas.drawCircle(
        Offset(mx, achseY),
        9,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = _kBg);
    if (aktiv && ausserhalb) {
      _beschriften(canvas, 'außerhalb ±${zahl(_kSkala, 0)}°', Offset(cx, 14), color: _kOrange, size: 11, weight: FontWeight.w700);
    }
  }

  @override
  bool shouldRepaint(SkalaPainter o) => true;
}

/// Digitale Fläche (2D): X/Y in Grad, Skala ±5°, Marker bewegt sich linear mit
/// den Messwerten (X nach rechts, Y nach oben = vorne). Exakt in der Mitte bei X 0,00° / Y 0,00°.
class FlaechePainter extends CustomPainter {
  FlaechePainter({required this.neigung});
  final Neigung? neigung; // null: kein gültiger Messwert

  @override
  void paint(Canvas canvas, Size size) {
    final n = neigung;
    final aktiv = n != null;
    final w = size.width;
    final box = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, w), const Radius.circular(16));
    canvas.drawRRect(box, Paint()..color = _kKarte);
    canvas.drawRRect(
        box,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = _kRand);

    const rand = 36.0;
    final feld = Rect.fromLTWH(rand, rand, w - 2 * rand, w - 2 * rand);
    final mitte = feld.center;
    final halb = feld.width / 2;
    double px(double g) => mitte.dx + g / _kSkala * halb;
    double py(double g) => mitte.dy - g / _kSkala * halb;

    canvas.drawRect(feld, Paint()..color = const Color(0xFF0A2149));
    // Raster: alle 1°, kräftiger bei 0, ±2,5, ±5.
    for (var i = -5; i <= 5; i++) {
      final fein = Paint()
        ..strokeWidth = 1
        ..color = _kRand.withValues(alpha: 0.55);
      canvas.drawLine(Offset(px(i.toDouble()), feld.top), Offset(px(i.toDouble()), feld.bottom), fein);
      canvas.drawLine(Offset(feld.left, py(i.toDouble())), Offset(feld.right, py(i.toDouble())), fein);
    }
    final kraeftig = Paint()
      ..strokeWidth = 1.5
      ..color = _kText2.withValues(alpha: 0.8);
    for (final g in const [-2.5, 2.5]) {
      canvas.drawLine(Offset(px(g), feld.top), Offset(px(g), feld.bottom), kraeftig);
      canvas.drawLine(Offset(feld.left, py(g)), Offset(feld.right, py(g)), kraeftig);
    }
    canvas.drawRect(
        feld,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _kText2);
    // Achsenkreuz und Mittenring.
    final kreuz = Paint()
      ..strokeWidth = 2.5
      ..color = Colors.white;
    canvas.drawLine(Offset(feld.left, mitte.dy), Offset(feld.right, mitte.dy), kreuz);
    canvas.drawLine(Offset(mitte.dx, feld.top), Offset(mitte.dx, feld.bottom), kreuz);
    canvas.drawCircle(
        mitte,
        halb * 0.06,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _kLimeMitte);

    // Beschriftung der Skala und der Seiten.
    for (final g in const [-5.0, -2.5, 0.0, 2.5, 5.0]) {
      final t = g == 0 ? '0°' : '${g > 0 ? '+' : '−'}${zahl(g.abs(), g.abs() == 2.5 ? 1 : 0)}°';
      _beschriften(canvas, t, Offset(px(g), feld.bottom + 10), size: 11);
      _beschriften(canvas, t, Offset(feld.left - 6, py(g)), size: 11, anker: Alignment.centerRight);
    }
    _beschriften(canvas, 'VORNE', Offset(mitte.dx, 11), size: 11, weight: FontWeight.w800);
    _beschriften(canvas, 'HINTEN', Offset(mitte.dx, w - 11), size: 11, weight: FontWeight.w800);
    _beschriften(canvas, 'LINKS', Offset(6, w - 11), size: 11, weight: FontWeight.w800, anker: Alignment.centerLeft);
    _beschriften(canvas, 'RECHTS', Offset(w - 6, w - 11), size: 11, weight: FontWeight.w800, anker: Alignment.centerRight);

    // Marker. Außerhalb der Skala bleibt er am Rand (Richtung bleibt erhalten) und wird orange.
    final fm = flaechenAnteil(n?.aGrad ?? 0.0, n?.bGrad ?? 0.0);
    final ausserhalb = fm.ausserhalb;
    final pos = Offset(mitte.dx + fm.x * halb, mitte.dy - fm.y * halb);
    final nn = n;
    final farbe = nn == null
        ? const Color(0xFF8E99AB)
        : (ausserhalb ? _kOrange : (zahl(nn.aGrad) == '0,00' && zahl(nn.bGrad) == '0,00' ? _kGruen : _kLimeMitte));
    canvas.drawCircle(pos, 15, Paint()..color = farbe.withValues(alpha: 0.28));
    canvas.drawCircle(pos, 9, Paint()..color = farbe);
    canvas.drawCircle(
        pos,
        9,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = _kBg);
    if (aktiv && ausserhalb) {
      _beschriften(canvas, 'außerhalb ±${zahl(_kSkala, 0)}°', Offset(feld.right - 4, feld.top + 12),
          color: _kOrange, size: 11, weight: FontWeight.w700, anker: Alignment.centerRight);
    }
  }

  @override
  bool shouldRepaint(FlaechePainter o) => true;
}
