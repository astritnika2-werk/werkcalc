import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

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
const _kLimeHell = Color(0xFFD9FF4A);
const _kLimeMitte = Color(0xFFA6EA00);
const _kLimeDunkel = Color(0xFF68B400);
const _kGruen = Color(0xFF2FBF4A);
const _ziffern = [FontFeature.tabularFigures()];

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
            'Wählen Sie die Betriebsart, passend zur Lage des Handys. Gemessen wird nur in dieser Lage; '
            'nichts wird automatisch erraten.\n\n'
            'Fläche (2D): Handy flach auf die Rückseite (Display oben). Die Blase zeigt die Neigung in '
            'zwei Achsen und wandert zur höheren Seite.\n'
            'Linie – Display vorne: Handy aufrecht, Display zum Benutzer. Gemessen wird links/rechts '
            'über die Breite (X-Achse).\n'
            'Linie – Linke Seite: Handy steht auf der linken Seitenkante, Display zum Benutzer '
            '(Oberkante zeigt nach links). Gemessen wird entlang der Längskante (Y-Achse). Die '
            'Anzeige ist dafür gedreht, damit sie in dieser Lage lesbar ist.\n'
            'Linie – Rechte Seite: wie links, nur auf der rechten Seitenkante (Oberkante zeigt nach rechts).\n'
            'Die Blase wandert immer zur höheren Seite.\n\n'
            'Kalibrieren: Handy auf eine Referenzfläche legen und „Kalibrieren“ tippen. Die Lage in '
            'dieser Zeit (ca. 2 Sekunden) gilt danach als 0,00°. Die Kalibrierung gilt für die '
            'gewählte Betriebsart. „Zurücksetzen“ löscht alle.\n\n'
            'Neigung: Winkel gegen die Senkrechte der Lage. Gefälle %: Höhenunterschied je 100 cm. '
            'Gefälle mm/m: Höhenunterschied je Meter.\n\n'
            'Die Skala der Blase ist vergrößert gezeichnet, damit kleine Neigungen sichtbar sind; die '
            'Zahlen sind unverändert. Die Werte werden mit dem Gyroskop geglättet, damit sie nicht '
            'springen; im Ruhezustand entspricht der Wert genau der Messung.\n\n$_kHinweis',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
      ),
    );
  }

  void _modusWaehlen(Modus m) {
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
      lageOk = lageStimmt(m, _filter.x, _filter.y, _filter.z);
      if (m.istFlaeche) {
        n = berechneNeigung(_filter.x, _filter.y, _filter.z, lage: m.lage, a0: kal?.a0 ?? 0, b0: kal?.b0 ?? 0);
      } else {
        l = berechneLinie(m, _filter.x, _filter.y, _filter.z, a0: kal?.a0 ?? 0);
      }
    }

    final koerper = <Widget>[
      _Umschalter(modus: m, linie: _linie, onChanged: _modusWaehlen),
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
      LayoutBuilder(builder: (context, c) {
        final d = math.min(c.maxWidth, 420.0);
        return Center(
          child: SizedBox(
            width: d,
            height: d,
            child: CustomPaint(size: Size(d, d), painter: _LibellePainter(neigung: m)),
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
    return [
      SizedBox(
        height: 84,
        child: CustomPaint(
          painter: _RoehrePainter(waagerecht: true, grad: grad, aktiv: m != null),
          child: const SizedBox.expand(),
        ),
      ),
      const SizedBox(height: 8),
      Center(
        child: Text(m == null ? '–' : '${zahl(grad)}°',
            style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w800, color: _kText, fontFeatures: _ziffern)),
      ),
      Center(
        child: Text(
          m == null ? '–' : '${zahl(m.prozent)} %   |   ${zahl(m.mmProM, 0)} mm/m',
          style: const TextStyle(fontSize: 17, color: _kText, fontFeatures: _ziffern),
        ),
      ),
      const SizedBox(height: 4),
      Center(child: Text(modus.achseText, style: const TextStyle(color: _kText2, fontSize: 12))),
      const SizedBox(height: 8),
      _Richtung(text: m == null ? '–' : linienRichtung(m)),
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

class _Richtung extends StatelessWidget {
  const _Richtung({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => _Karte(
        child: Row(children: [
          const Icon(Icons.straighten, color: _kText2),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kText)),
          ),
        ]),
      );
}

// ───────────────────────── Zeichnung ─────────────────────────

/// Kreislibelle (2D). Die Blase kommt aus derselben Rechnung wie die Zahlen
/// ([blasenPosition]); sie wandert zur höheren Seite.
class _LibellePainter extends CustomPainter {
  _LibellePainter({required this.neigung});
  final Neigung? neigung;

  static const _ringe = [1.0, 5.0, 15.0, 30.0, 45.0];

  @override
  void paint(Canvas canvas, Size size) {
    final n = neigung; // null, wenn kein gültiger Messwert
    final aktiv = n != null;
    final mitte = size.center(Offset.zero);
    final r = size.width / 2 - 4;
    final rand = r * 0.07;
    final inner = r - rand;

    // Metallring und Scheibe.
    canvas.drawCircle(
      mitte,
      r,
      Paint()
        ..shader = const SweepGradient(colors: [
          Color(0xFF5B6678), Color(0xFFC3CBD8), Color(0xFF4A5568), Color(0xFFB0B9C8), Color(0xFF5B6678),
        ]).createShader(Rect.fromCircle(center: mitte, radius: r)),
    );
    canvas.drawCircle(
      mitte,
      inner,
      Paint()
        ..shader = const RadialGradient(
          colors: [_kLimeHell, _kLimeMitte, _kLimeDunkel],
          stops: [0.0, 0.65, 1.0],
        ).createShader(Rect.fromCircle(center: mitte, radius: inner)),
    );

    final dunkel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF0B2A5B).withValues(alpha: 0.75);
    final fein = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF0B2A5B).withValues(alpha: 0.28);

    final br = inner * 0.12; // Blasenradius
    final skalaR = inner - br; // Radius der größten Neigung der Lage
    for (final a in _ringe) {
      canvas.drawCircle(mitte, skalaR * anzeigeSkala(a), a == 1.0 ? dunkel : fein);
    }
    canvas.drawLine(mitte - Offset(inner, 0), mitte + Offset(inner, 0), dunkel);
    canvas.drawLine(mitte - Offset(0, inner), mitte + Offset(0, inner), dunkel);
    // Teilstriche am Rand.
    for (var i = 0; i < 4; i++) {
      final w = i * math.pi / 2;
      final d = Offset(math.cos(w), math.sin(w));
      canvas.drawLine(mitte + d * (inner - 10), mitte + d * inner, dunkel..strokeWidth = 2);
    }

    // Blase.
    final pos = n != null ? blasenPosition(n) : (dx: 0.0, dy: 0.0);
    final bm = mitte + Offset(pos.dx, pos.dy) * skalaR;
    canvas.drawCircle(bm + Offset(br * 0.15, br * 0.2), br * 1.05, Paint()..color = Colors.black.withValues(alpha: 0.25));
    canvas.drawCircle(
      bm,
      br,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: aktiv
              ? const [Color(0xFFE9FFB5), Color(0xFF2FBF4A), Color(0xFF0B7A2B)]
              : const [Color(0xFFE0E5EE), Color(0xFF8E99AB), Color(0xFF5B6678)],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: bm, radius: br)),
    );
  }

  @override
  bool shouldRepaint(_LibellePainter o) => true;
}

/// Libellenrohr (1D), waagerecht oder senkrecht. Positiver Winkel: das positive
/// Ende der Achse (rechts bzw. oben) liegt höher, die Blase wandert dorthin.
class _RoehrePainter extends CustomPainter {
  _RoehrePainter({required this.waagerecht, required this.grad, required this.aktiv});
  final bool waagerecht;
  final double grad;
  final bool aktiv;

  @override
  void paint(Canvas canvas, Size size) {
    final laenge = waagerecht ? size.width : size.height;
    final breite = waagerecht ? size.height : size.width;
    // In waagerechter Richtung zeichnen und bei senkrecht drehen (oben = positiv).
    canvas.save();
    if (!waagerecht) {
      canvas.translate(0, size.height);
      canvas.rotate(-math.pi / 2);
    }
    final rect = Rect.fromLTWH(0, 0, laenge, breite);
    final rr = RRect.fromRectAndRadius(rect.deflate(2), Radius.circular(breite / 2.4));
    canvas.drawRRect(rr, Paint()..color = const Color(0xFF14233F));
    final innen = RRect.fromRectAndRadius(rect.deflate(breite * 0.13), Radius.circular(breite / 2.8));
    canvas.drawRRect(
      innen,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kLimeHell, _kLimeMitte, _kLimeDunkel],
          stops: [0.0, 0.5, 1.0],
        ).createShader(innen.outerRect),
    );
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = const Color(0xFFB4BDCB));

    final br = breite * 0.30;
    final nutz = laenge / 2 - breite * 0.13 - br - 2;
    final cx = laenge / 2, cy = breite / 2;
    final strich = Paint()
      ..strokeWidth = 1.6
      ..color = const Color(0xFF0B2A5B).withValues(alpha: 0.75);
    final dx1 = anzeigeSkala(1.0) * nutz; // Marken bei ±1°
    for (final x in [cx - dx1 - br, cx + dx1 + br, cx]) {
      canvas.drawLine(Offset(x, breite * 0.13), Offset(x, breite * 0.87), strich);
    }
    final bx = cx + (aktiv ? leistenPosition(grad) : 0) * nutz;
    canvas.drawCircle(Offset(bx + br * 0.12, cy + br * 0.18), br * 1.05, Paint()..color = Colors.black.withValues(alpha: 0.25));
    canvas.drawCircle(
      Offset(bx, cy),
      br,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: aktiv
              ? const [Color(0xFFE9FFB5), Color(0xFF2FBF4A), Color(0xFF0B7A2B)]
              : const [Color(0xFFE0E5EE), Color(0xFF8E99AB), Color(0xFF5B6678)],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(bx, cy), radius: br)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RoehrePainter o) => true;
}
