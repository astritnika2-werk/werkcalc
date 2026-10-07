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
/// zusätzlich geglättet. Dritte Stufe: Bewegung rund 30 % langsamer (Geschwindigkeit × 0,7,
/// also Zeitkonstante 0,195 s / 0,7 ≈ 0,279 s). Im Ruhezustand bleibt der Wert exakt der Messwert.
/// Interner Anzeigewert, keine Herstellervorgabe, keine Norm.
const double kAnzeigeTau = 0.349;

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

  final Map<Modus, ModusKalibrierung> _kals = {};
  bool _kalLaeuft = false;
  int _kalStart = 0;
  String? _kalMeldung;
  String? _kalOk;
  final List<Vek> _kalProben = [];
  bool _einstellungenOffen = false; // Einstellungen offen: Automatik pausiert

  @override
  void initState() {
    super.initState();
    // Der Bildschirm bleibt im Hochformat (Achsen und Richtungen bleiben eindeutig). In den Seitenlagen
    // wird die ganze Oberfläche per RotatedBox gedreht; die Messung hängt nicht an der Drehung.
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
        if (_auto && !_kalLaeuft && !_einstellungenOffen) {
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


  void _modusWaehlen(Modus m, {bool manuell = true}) {
    if (manuell && _auto) {
      // Wer selbst wählt, behält diese Wahl: die Automatik schaltet sich aus.
      setState(() => _auto = false);
    }
    _umschalter.setze(m);
    if (m == _modus) return;
    setState(() {
      _modus = m;
      _kalLaeuft = false;
      _kalMeldung = null;
      _kalOk = null;
    });
  }


  Future<void> _einstellungen() async {
    setState(() => _einstellungenOffen = true);
    await showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (c) => StatefulBuilder(
        builder: (c, setD) => Dialog.fullscreen(
          backgroundColor: _kBg,
          // Auch die Einstellungen werden in den Seitenlagen mitgedreht.
          child: SafeArea(
            child: RotatedBox(
              quarterTurns: _modus.viertelDrehungen,
              child: EinstellungenInhalt(
                modus: _modus,
                auto: _auto,
                onAuto: (v) {
                  setState(() {
                    _auto = v;
                    _umschalter.setze(_modus);
                  });
                  setD(() {});
                },
                onModus: (neu) {
                  _modusWaehlen(neu);
                  Navigator.pop(c);
                },
                onSchliessen: () => Navigator.pop(c),
              ),
            ),
          ),
        ),
      ),
    );
    if (mounted) setState(() => _einstellungenOffen = false);
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

    // Seitenlage: Die ganze Oberfläche (Skala, Texte, Tasten) wird gedreht, damit sie in dieser Lage
    // aufrecht lesbar ist (linke Seite: Oberkante zeigt nach links → Drehung im Uhrzeigersinn;
    // rechte Seite: umgekehrt). In der gedrehten Ansicht ist der Platz breit und flach (Querformat-Layout).
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: RotatedBox(
          quarterTurns: m.viertelDrehungen,
          child: WasserwaageAnsicht(
            modus: m,
            neigung: n,
            linie: l,
            lageOk: lageOk,
            hatWerte: _hatWerte,
            fehler: _fehler,
            kalibriert: kal != null,
            kalLaeuft: _kalLaeuft,
            kalOk: _kalOk,
            kalMeldung: _kalMeldung,
            onKalibrieren: (_hatWerte && !_kalLaeuft) ? _kalibrierenStart : null,
            onZuruecksetzen: (_kals.isNotEmpty && !_kalLaeuft) ? _zuruecksetzen : null,
            onEinstellungen: _einstellungen,
            onZurueck: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Hauptansicht (kompakt, ohne Scrollen) ─────────────────────────

String _modusKurz(Modus m) => switch (m) {
      Modus.flaeche => 'FLÄCHE (2D)',
      Modus.linieDisplay => 'LINIE · DISPLAY VORNE',
      Modus.linieLinks => 'LINIE · LINKE SEITE',
      Modus.linieRechts => 'LINIE · RECHTE SEITE',
    };

String _lageHinweis(Modus m) => switch (m) {
      Modus.flaeche => 'Handy flach auf den Rücken legen',
      Modus.linieDisplay => 'Handy aufrecht, Display zum Benutzer',
      Modus.linieLinks => 'Handy auf die linke Seite stellen',
      Modus.linieRechts => 'Handy auf die rechte Seite stellen',
    };

/// Die Messansicht: Kopf (Name, aktuelle Betriebsart, ⚙), Hauptbereich mit der Messung,
/// Fuß (Kalibrieren). Kein Scrollen, nichts kann überlaufen: Der Hauptbereich teilt sich den
/// verfügbaren Platz selbst ein. Rein darstellend – alle Werte kommen fertig von außen.
class WasserwaageAnsicht extends StatelessWidget {
  const WasserwaageAnsicht({
    super.key,
    required this.modus,
    required this.neigung,
    required this.linie,
    required this.lageOk,
    required this.hatWerte,
    this.fehler,
    required this.kalibriert,
    required this.kalLaeuft,
    this.kalOk,
    this.kalMeldung,
    this.onKalibrieren,
    this.onZuruecksetzen,
    this.onEinstellungen,
    this.onZurueck,
  });

  final Modus modus;
  final Neigung? neigung;
  final Linienmessung? linie;
  final bool lageOk;
  final bool hatWerte;
  final String? fehler;
  final bool kalibriert;
  final bool kalLaeuft;
  final String? kalOk;
  final String? kalMeldung;
  final VoidCallback? onKalibrieren;
  final VoidCallback? onZuruecksetzen; // null: Zurücksetzen wird nicht angezeigt
  final VoidCallback? onEinstellungen;
  final VoidCallback? onZurueck;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final breit = c.maxWidth >= c.maxHeight;
      if (breit) return _breit();
      return Column(children: [
        _Kopf(modus: modus, onEinstellungen: onEinstellungen, onZurueck: onZurueck),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
            child: fehler != null
                ? Center(child: _Karte(child: Text(fehler!, style: const TextStyle(color: _kText))))
                : (modus.istFlaeche ? _flaecheHoch() : _linieHoch()),
          ),
        ),
        _Fuss(
          breit: breit,
          kalibriert: kalibriert,
          kalLaeuft: kalLaeuft,
          kalOk: kalOk,
          kalMeldung: kalMeldung,
          onKalibrieren: onKalibrieren,
          onZuruecksetzen: onZuruecksetzen,
        ),
      ]);
    });
  }

  // Status/Richtungsfeld: (Text, Zusatz, waagerecht, Warnung, nicht waagerecht)
  ({String text, String? unter, bool waagerecht, bool warn, bool nicht}) _status(String? richtung, String? unterOk) {
    if (richtung != null) {
      if (richtung.toUpperCase() == 'WAAGERECHT') {
        return (text: 'WAAGERECHT', unter: unterOk, waagerecht: true, warn: false, nicht: false);
      }
      return (text: 'NICHT WAAGERECHT', unter: richtung, waagerecht: false, warn: false, nicht: true);
    }
    if (!hatWerte) return (text: 'WARTE AUF SENSOR', unter: null, waagerecht: false, warn: false, nicht: false);
    if (!lageOk) return (text: 'NICHT IN LAGE', unter: _lageHinweis(modus), waagerecht: false, warn: true, nicht: false);
    return (text: '–', unter: null, waagerecht: false, warn: false, nicht: false);
  }

  Linienmessung? get _gueltigeLinie {
    final l = linie;
    return (l != null && l.gueltig && lageOk) ? l : null;
  }

  Neigung? get _gueltigeNeigung {
    final n = neigung;
    return (n != null && n.gueltig && lageOk) ? n : null;
  }

  // ───────── Breit/flach (Seitenlagen, Querformat): alles in einer schmalen Kopfleiste,
  // die Skala bzw. Fläche nutzt den ganzen restlichen Platz ─────────
  Widget _breit() {
    final kal = _kalStatus(kalLaeuft: kalLaeuft, kalMeldung: kalMeldung, kalOk: kalOk, kalibriert: kalibriert);
    final Widget mitte;
    final Widget haupt;
    if (modus.istFlaeche) {
      final m = _gueltigeNeigung;
      final st = _status(m == null ? null : richtungsText(m), null);
      mitte = Row(mainAxisSize: MainAxisSize.min, children: [
        _XY(label: 'X', grad: m?.aGrad, steigung: m?.sx),
        const SizedBox(width: 14),
        _XY(label: 'Y', grad: m?.bGrad, steigung: m?.sy),
        const SizedBox(width: 14),
        _Chip(st.warn ? (st.unter ?? st.text) : st.text, waagerecht: st.waagerecht, warn: st.warn, nicht: st.nicht),
      ]);
      haupt = LayoutBuilder(builder: (context, k) {
        final d = math.min(k.maxWidth, k.maxHeight);
        return Center(
          child: SizedBox(width: d, height: d, child: CustomPaint(size: Size(d, d), painter: FlaechePainter(neigung: m))),
        );
      });
    } else {
      final m = _gueltigeLinie;
      final st = _status(m == null ? null : linienRichtung(m).toUpperCase(), null);
      mitte = Row(mainAxisSize: MainAxisSize.min, children: [
        Text(m == null ? '–' : '${zahl(m.grad)}°',
            key: const Key('winkel'),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: _kText, fontFeatures: _ziffern)),
        const SizedBox(width: 14),
        _Chip(st.warn ? (st.unter ?? st.text) : st.text, waagerecht: st.waagerecht, warn: st.warn, nicht: st.nicht),
        const SizedBox(width: 14),
        _Mini(wert: m == null ? '–' : '${zahl(m.prozent)} %', label: 'Gefälle'),
        const SizedBox(width: 10),
        _Mini(wert: m == null ? '–' : '${zahl(m.mmProM, 0)} mm/m', label: 'Gefälle'),
      ]);
      haupt = Stack(children: [
        Positioned.fill(
          child: CustomPaint(
            painter: SkalaPainter(grad: m?.grad ?? 0.0, aktiv: m != null),
            child: const SizedBox.expand(),
          ),
        ),
        // Kalibrieren: kleine Leiste oben mittig zwischen LINKS HÖHER und RECHTS HÖHER.
        Positioned(
          top: 5,
          left: 0,
          right: 0,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: _kBlau,
                        minimumSize: const Size(0, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2)),
                    onPressed: onKalibrieren,
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.my_location, size: 16),
                      SizedBox(width: 6),
                      Text('Kalibrieren', style: TextStyle(fontSize: 12)),
                    ]),
                  ),
                  if (onZuruecksetzen != null) ...[
                    const SizedBox(width: 6),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: _kText,
                          side: const BorderSide(color: _kRand),
                          minimumSize: const Size(0, 30),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2)),
                      onPressed: onZuruecksetzen,
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.restart_alt, size: 16),
                        SizedBox(width: 4),
                        Text('Zurücksetzen', style: TextStyle(fontSize: 11)),
                      ]),
                    ),
                  ],
                ]),
                const SizedBox(height: 3),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(kal.text,
                      key: const Key('kalStatus'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kal.farbe, fontSize: 10, height: 1.2)),
                ),
              ]),
            ),
          ),
        ),
      ]);
    }
    return Column(children: [
      SizedBox(
        height: 46,
        child: Row(children: [
          _IconKlein(icon: Icons.arrow_back, tooltip: 'Zurück', onPressed: onZurueck),
          Flexible(
            flex: 2,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Wasserwaage',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _kText, fontWeight: FontWeight.w800, fontSize: 15, height: 1.1)),
              Text(_modusKurz(modus),
                  key: const Key('modusLabel'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _kText2, fontWeight: FontWeight.w700, fontSize: 9.5, letterSpacing: 0.8, height: 1.2)),
            ]),
          ),
          Expanded(flex: 5, child: Center(child: fehler != null ? const SizedBox() : FittedBox(fit: BoxFit.scaleDown, child: mitte))),
          _IconKlein(icon: Icons.settings_outlined, tooltip: 'Einstellungen', onPressed: onEinstellungen),
        ]),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
          child: fehler != null
              ? Center(child: _Karte(child: Text(fehler!, style: const TextStyle(color: _kText))))
              : Row(children: [
                  Expanded(child: haupt),
                  if (modus.istFlaeche) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 104,
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: 104,
                          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            Text(kal.text,
                                key: const Key('kalStatus'),
                                maxLines: 6,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: kal.farbe, fontSize: 10, height: 1.2)),
                            const SizedBox(height: 6),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: _kBlau,
                                  minimumSize: const Size(0, 44),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4)),
                              onPressed: onKalibrieren,
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.my_location, size: 20),
                                  Text('Kalibrieren', style: TextStyle(fontSize: 12)),
                                ]),
                              ),
                            ),
                            if (onZuruecksetzen != null) ...[
                              const SizedBox(height: 6),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: _kText,
                                    side: const BorderSide(color: _kRand),
                                    minimumSize: const Size(0, 32),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2)),
                                onPressed: onZuruecksetzen,
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Icons.restart_alt, size: 16),
                                    SizedBox(width: 4),
                                    Text('Zurücksetzen', style: TextStyle(fontSize: 11)),
                                  ]),
                                ),
                              ),
                            ],
                          ]),
                        ),
                      ),
                    ),
                  ),
                  ],
                ]),
        ),
      ),
    ]);
  }

  // ───────── Linie (1D), Hochformat ─────────
  Widget _linieHoch() {
    final m = _gueltigeLinie;
    final st = _status(m == null ? null : linienRichtung(m).toUpperCase(), null);
    final skala = CustomPaint(
      painter: SkalaPainter(grad: m?.grad ?? 0.0, aktiv: m != null),
      child: const SizedBox.expand(),
    );
    final winkel = Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(m == null ? '–' : '${zahl(m.grad)}°',
            key: const Key('winkel'),
            style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: _kText, fontFeatures: _ziffern)),
      ),
    );
    final werte = Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(child: _Wert(label: 'Gefälle', wert: m == null ? '–' : '${zahl(m.prozent)} %')),
      const SizedBox(width: 8),
      Expanded(child: _Wert(label: 'Gefälle', wert: m == null ? '–' : '${zahl(m.mmProM, 0)} mm/m')),
    ]);
    final banner = _Status(text: st.text, unter: st.unter, waagerecht: st.waagerecht, warn: st.warn, nicht: st.nicht);
    return Column(children: [
      Expanded(flex: 14, child: skala),
      Expanded(flex: 4, child: winkel),
      Expanded(flex: 2, child: banner),
      const SizedBox(height: 6),
      Expanded(flex: 2, child: werte),
    ]);
  }

  // ───────── Fläche (2D), Hochformat ─────────
  Widget _flaecheHoch() {
    final m = _gueltigeNeigung;
    final st = _status(m == null ? null : richtungsText(m),
        m == null ? null : 'Neigung gemessen: ${zahl(m.gesamtGrad)}°');
    Widget panel(double d) => SizedBox(
          width: d,
          height: d,
          child: CustomPaint(size: Size(d, d), painter: FlaechePainter(neigung: m)),
        );
    final karten = Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(child: _AchsenKachel(titel: 'X (links/rechts)', grad: m?.aGrad, steigung: m?.sx)),
      const SizedBox(width: 8),
      Expanded(child: _AchsenKachel(titel: 'Y (vorne/hinten)', grad: m?.bGrad, steigung: m?.sy)),
    ]);
    final banner = _Status(text: st.text, unter: st.unter, waagerecht: st.waagerecht, warn: st.warn, nicht: st.nicht);
    return LayoutBuilder(builder: (context, c) {
      final d = math.min(c.maxWidth, math.max(100.0, c.maxHeight - 130));
      return Column(children: [
        panel(d),
        const SizedBox(height: 6),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 190),
              child: Column(children: [
                Expanded(flex: 3, child: karten),
                const SizedBox(height: 6),
                Expanded(flex: 2, child: banner),
              ]),
            ),
          ),
        ),
      ]);
    });
  }
}

/// Text und Farbe der Kalibrierungsanzeige.
({String text, Color farbe}) _kalStatus(
    {required bool kalLaeuft, required String? kalMeldung, required String? kalOk, required bool kalibriert}) {
  if (kalLaeuft) return (text: 'Kalibrierung läuft – Handy ruhig halten …', farbe: _kText);
  if (kalMeldung != null) return (text: kalMeldung, farbe: const Color(0xFFFFB4A9));
  if (kalOk != null) return (text: 'Kalibriert ✓ ($kalOk)', farbe: _kText);
  if (kalibriert) return (text: 'Kalibriert (diese Betriebsart)', farbe: _kText2);
  return (text: 'Nicht kalibriert (diese Betriebsart)', farbe: _kText2);
}

class _IconKlein extends StatelessWidget {
  const _IconKlein({required this.icon, required this.tooltip, required this.onPressed});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon, color: _kText, size: 22),
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      );
}

/// Kleines Richtungsfeld für die Kopfleiste der breiten Ansicht.
class _Chip extends StatelessWidget {
  const _Chip(this.text, {required this.waagerecht, required this.warn, this.nicht = false});
  final String text;
  final bool waagerecht;
  final bool warn;
  final bool nicht;

  @override
  Widget build(BuildContext context) {
    final Color bg = waagerecht ? const Color(0xFF123F27) : nicht ? const Color(0xFF4A2A10) : (warn ? const Color(0xFF4A3A12) : const Color(0xFFDCE8FB));
    final Color rand = waagerecht ? _kGruen : nicht ? _kOrange : (warn ? const Color(0xFFFFD27A) : const Color(0xFF9DB9E6));
    final Color tx = (waagerecht || warn || nicht) ? _kText : const Color(0xFF0B2A5B);
    return Container(
      key: const Key('status'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: rand)),
      child: Text(text, style: TextStyle(fontSize: 14, letterSpacing: 0.8, fontWeight: FontWeight.w800, color: tx)),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.wert, required this.label});
  final String wert;
  final String label;

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        Text(wert, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kText, fontFeatures: _ziffern)),
        Text(label, style: const TextStyle(fontSize: 10, color: _kText2)),
      ]);
}

class _XY extends StatelessWidget {
  const _XY({required this.label, required this.grad, required this.steigung});
  final String label;
  final double? grad;
  final double? steigung;

  @override
  Widget build(BuildContext context) {
    final g = grad, s = steigung;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('$label ${g == null ? '–' : '${zahl(g)}°'}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _kText, fontFeatures: _ziffern)),
      Text(s == null ? '–' : '${zahl(s * 100, 1)} % · ${zahl(s * 1000, 0)} mm/m',
          style: const TextStyle(fontSize: 10, color: _kText2, fontFeatures: _ziffern)),
    ]);
  }
}

class _Kopf extends StatelessWidget {
  const _Kopf({required this.modus, this.onEinstellungen, this.onZurueck});
  final Modus modus;
  final VoidCallback? onEinstellungen;
  final VoidCallback? onZurueck;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 52,
        child: Row(children: [
          IconButton(
              icon: const Icon(Icons.arrow_back, color: _kText), tooltip: 'Zurück', onPressed: onZurueck),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Wasserwaage',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _kText, fontWeight: FontWeight.w800, fontSize: 18, height: 1.1)),
              Text(_modusKurz(modus),
                  key: const Key('modusLabel'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _kText2, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 1, height: 1.2)),
            ]),
          ),
          IconButton(
              icon: const Icon(Icons.settings_outlined, color: _kText),
              tooltip: 'Einstellungen',
              onPressed: onEinstellungen),
        ]),
      );
}

class _Fuss extends StatelessWidget {
  const _Fuss({
    required this.breit,
    required this.kalibriert,
    required this.kalLaeuft,
    required this.kalOk,
    required this.kalMeldung,
    required this.onKalibrieren,
    required this.onZuruecksetzen,
  });
  final bool breit;
  final bool kalibriert;
  final bool kalLaeuft;
  final String? kalOk;
  final String? kalMeldung;
  final VoidCallback? onKalibrieren;
  final VoidCallback? onZuruecksetzen;

  @override
  Widget build(BuildContext context) {
    final ks = _kalStatus(kalLaeuft: kalLaeuft, kalMeldung: kalMeldung, kalOk: kalOk, kalibriert: kalibriert);
    final text = ks.text;
    final farbe = ks.farbe;
    final status = Text(text,
        key: const Key('kalStatus'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: breit ? TextAlign.start : TextAlign.center,
        style: TextStyle(color: farbe, fontSize: 12, height: 1.2));

    Widget label(IconData icon, String t) => FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 18), const SizedBox(width: 6), Text(t)]),
        );
    final kalTaste = FilledButton(
      style: FilledButton.styleFrom(
          backgroundColor: _kBlau, minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 10)),
      onPressed: onKalibrieren,
      child: label(Icons.my_location, 'Kalibrieren'),
    );
    final resetTaste = onZuruecksetzen == null
        ? null
        : OutlinedButton(
            style: OutlinedButton.styleFrom(
                foregroundColor: _kText,
                side: const BorderSide(color: _kRand),
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 10)),
            onPressed: onZuruecksetzen,
            child: label(Icons.restart_alt, 'Zurücksetzen'),
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: breit
          ? Row(children: [
              Expanded(flex: 3, child: status),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: kalTaste),
              if (resetTaste != null) ...[const SizedBox(width: 8), Expanded(flex: 2, child: resetTaste)],
            ])
          : Column(mainAxisSize: MainAxisSize.min, children: [
              status,
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: kalTaste),
                if (resetTaste != null) ...[const SizedBox(width: 8), Expanded(child: resetTaste)],
              ]),
            ]),
    );
  }
}

// ───────────────────────── Einstellungen ─────────────────────────

/// Inhalt der Einstellungen (hinter ⚙): Automatik, manuelle Betriebsart, Hilfe, Hinweis.
class EinstellungenInhalt extends StatelessWidget {
  const EinstellungenInhalt({
    super.key,
    required this.modus,
    required this.auto,
    required this.onAuto,
    required this.onModus,
    required this.onSchliessen,
  });
  final Modus modus;
  final bool auto;
  final ValueChanged<bool> onAuto;
  final ValueChanged<Modus> onModus;
  final VoidCallback onSchliessen;

  static const _hilfe =
      'Die Betriebsart wechselt automatisch, sobald das Handy kurz (ca. 1 Sekunde) ruhig in einer der '
      'vier Lagen liegt. Kleine Bewegungen lösen keinen Wechsel aus. Wer hier selbst eine Betriebsart '
      'wählt, schaltet die Automatik aus. Gemessen wird immer nur in der aktuellen Betriebsart.\n\n'
      'Fläche (2D): Handy flach auf die Rückseite (Display oben). Der Marker zeigt die Neigung in '
      'zwei Achsen (X nach rechts, Y nach vorne) und steht bei X 0,00° / Y 0,00° genau in der Mitte.\n'
      'Linie – Display vorne: Handy aufrecht, Display zum Benutzer. Gemessen wird links/rechts '
      'über die Breite (X-Achse).\n'
      'Linie – Linke/Rechte Seite: Das Handy steht auf der linken bzw. rechten Seitenkante, Display zum '
      'Benutzer. Gemessen wird entlang der Längskante (Y-Achse). Die ganze Anzeige wird dafür mitgedreht, '
      'damit sie in dieser Lage lesbar ist.\n'
      'Der Marker bewegt sich immer zur höheren Seite. Skala: ±5° (darüber bleibt der Marker am Rand und wird orange).\n\n'
      'Kalibrieren: Handy auf eine Referenzfläche legen und „Kalibrieren“ tippen. Die Lage in '
      'dieser Zeit (ca. 2 Sekunden) gilt danach als 0,00°. Die Kalibrierung gilt für die '
      'aktuelle Betriebsart. „Zurücksetzen“ (erscheint nur, wenn kalibriert wurde) löscht alle.\n\n'
      'Neigung: Winkel gegen die Senkrechte der Lage. Gefälle %: Höhenunterschied je 100 cm. '
      'Gefälle mm/m: Höhenunterschied je Meter.\n\n'
      'Die Anzeige ist linear und verwendet exakt die gemessenen Werte. Die Werte werden mit dem '
      'Gyroskop geglättet, damit sie nicht springen; im Ruhezustand entspricht der Wert genau der Messung.';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          const Expanded(
            child: Text('Einstellungen', style: TextStyle(color: _kText, fontWeight: FontWeight.w800, fontSize: 20)),
          ),
          IconButton(
              icon: const Icon(Icons.close, color: _kText), tooltip: 'Schließen', onPressed: onSchliessen),
        ]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
          decoration:
              BoxDecoration(color: _kKarte, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kRand)),
          child: Row(children: [
            const Icon(Icons.screen_rotation_alt_outlined, color: _kText2, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Automatisch umschalten',
                    style: TextStyle(color: _kText, fontWeight: FontWeight.w700, fontSize: 14)),
                Text(
                  auto
                      ? 'Die Ansicht wechselt, sobald das Handy kurz ruhig in einer der vier Lagen liegt.'
                      : 'Aus: Die Betriebsart bleibt, wie Sie sie gewählt haben.',
                  style: const TextStyle(color: _kText2, fontSize: 12),
                ),
              ]),
            ),
            Switch(value: auto, onChanged: onAuto),
          ]),
        ),
        const SizedBox(height: 16),
        const Text('Betriebsart manuell wählen',
            style: TextStyle(color: _kText2, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 6),
        for (final m in Modus.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              key: Key('modus_${m.name}'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => onModus(m),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: m == modus ? _kBlau : _kKarte,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: m == modus ? Colors.white : _kRand),
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.name2, style: const TextStyle(color: _kText, fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(m.anleitung, style: const TextStyle(color: _kText2, fontSize: 12)),
                    ]),
                  ),
                  if (m == modus) const Icon(Icons.check_circle, color: _kText),
                ]),
              ),
            ),
          ),
        const SizedBox(height: 8),
        const _Karte(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hilfe', style: TextStyle(fontWeight: FontWeight.bold, color: _kText)),
            SizedBox(height: 6),
            Text(_hilfe, style: TextStyle(color: _kText2, fontSize: 13)),
          ]),
        ),
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
                SizedBox(height: 8),
                Text('„Waagerecht“ gilt bis ±0,01° je Achse (rund 0,17 mm/m) – Zielwert, interner Richtwert, '
                    'keine Herstellervorgabe, keine Norm. Die reale Genauigkeit hängt vom Gerät und der Kalibrierung ab.',
                    style: TextStyle(color: _kText2)),
              ]),
            ),
          ]),
        ),
      ],
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

/// Kachel mit einem Wert; füllt den gegebenen Platz, Inhalt passt sich per FittedBox an.
class _Wert extends StatelessWidget {
  const _Wert({required this.label, required this.wert});
  final String label;
  final String wert;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _kKarte,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kRand.withValues(alpha: 0.6)),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(label, style: const TextStyle(color: _kText2, fontSize: 13)),
              Text(wert,
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: _kText, fontFeatures: _ziffern)),
            ]),
          ),
        ),
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
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _kKarte,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kRand.withValues(alpha: 0.6)),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(titel, style: const TextStyle(color: _kText2, fontSize: 13)),
            Text(g == null ? '–' : '${zahl(g)}°',
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: _kText, fontFeatures: _ziffern)),
            Text(s == null ? '–' : '${zahl(s * 100, 1)} %  ·  ${zahl(s * 1000, 0)} mm/m',
                style: const TextStyle(color: _kText, fontSize: 14, fontFeatures: _ziffern)),
          ]),
        ),
      ),
    );
  }
}

/// Richtungsfeld (WAAGERECHT / LINKS HÖHER / …); füllt den gegebenen Platz.
class _Status extends StatelessWidget {
  const _Status({required this.text, required this.unter, required this.waagerecht, required this.warn, this.nicht = false});
  final String text;
  final String? unter;
  final bool waagerecht;
  final bool warn;
  final bool nicht;

  @override
  Widget build(BuildContext context) {
    final Color bg = waagerecht ? const Color(0xFF123F27) : nicht ? const Color(0xFF4A2A10) : (warn ? const Color(0xFF4A3A12) : const Color(0xFFDCE8FB));
    final Color rand = waagerecht ? _kGruen : nicht ? _kOrange : (warn ? const Color(0xFFFFD27A) : const Color(0xFF9DB9E6));
    final Color tx = (waagerecht || warn || nicht) ? _kText : const Color(0xFF0B2A5B);
    final Color tx2 = (waagerecht || warn || nicht) ? _kText2 : const Color(0xFF28446F);
    return Container(
      key: const Key('status'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: rand)),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(text, style: TextStyle(fontSize: 26, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: tx)),
            if (unter != null) Text(unter!, style: TextStyle(fontSize: 13, color: tx2)),
          ]),
        ),
      ),
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
/// Bei exakt 0° steht der Marker genau in der Mitte. Alle Maße richten sich nach der
/// verfügbaren Größe (die Skala füllt ihren Platz).
class SkalaPainter extends CustomPainter {
  SkalaPainter({required this.grad, required this.aktiv});
  final double grad;
  final bool aktiv;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final u = math.max(1.0, math.min(h, w * 0.55)); // Bezugsgröße für alle Maße
    final k = (u / 150).clamp(0.7, 2.2).toDouble(); // Strichstärken
    final box = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(14));
    canvas.drawRRect(box, Paint()..color = _kKarte);
    canvas.drawRRect(
        box,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = _kRand);

    final rand = w * 0.07;
    final x0 = rand, x1 = w - rand;
    final cx = (x0 + x1) / 2;
    final achseY = h * 0.58;
    double xAt(double g) => cx + (g / _kSkala) * (x1 - x0) / 2;

    // Kopfzeile: Richtung der Seiten.
    final kopfSize = (u * 0.055).clamp(9.0, 18.0).toDouble();
    final kopfY = achseY - u * 0.40;
    _beschriften(canvas, '◀ LINKS HÖHER', Offset(w * 0.04, kopfY), size: kopfSize, anker: Alignment.centerLeft);
    _beschriften(canvas, 'RECHTS HÖHER ▶', Offset(w * 0.96, kopfY), size: kopfSize, anker: Alignment.centerRight);

    final achse = Paint()
      ..color = _kText2
      ..strokeWidth = 2 * k;
    canvas.drawLine(Offset(x0, achseY), Offset(x1, achseY), achse);

    // Teilstriche: alle 0,5°, groß bei −5, −2,5, 0, +2,5, +5.
    for (var i = -10; i <= 10; i++) {
      final g = i * 0.5;
      final gross = i % 5 == 0;
      final null0 = i == 0;
      final len = u * (null0 ? 0.24 : (gross ? 0.16 : 0.07));
      canvas.drawLine(
        Offset(xAt(g), achseY),
        Offset(xAt(g), achseY + len),
        Paint()
          ..color = null0 ? _kLimeMitte : _kText2
          ..strokeWidth = (null0 ? 3 : (gross ? 2 : 1)) * k,
      );
    }
    final labelSize = (u * 0.075).clamp(10.0, 26.0).toDouble();
    const marken = <double>[-5, -2.5, 0, 2.5, 5];
    for (final g in marken) {
      final t = g == 0 ? '0°' : '${g > 0 ? '+' : '−'}${zahl(g.abs(), g.abs() == 2.5 ? 1 : 0)}°';
      _beschriften(canvas, t, Offset(xAt(g), achseY + u * 0.24 + labelSize * 1.0),
          color: g == 0 ? _kText : _kText2, size: labelSize, weight: g == 0 ? FontWeight.w800 : FontWeight.w600);
    }

    // Marker.
    final ausserhalb = grad.abs() > _kSkala;
    final mx = cx + (aktiv ? skalaAnteil(grad) : 0) * (x1 - x0) / 2;
    final farbe = !aktiv
        ? const Color(0xFF8E99AB)
        : (ausserhalb ? _kOrange : (imToleranzbereich(grad) ? _kGruen : _kOrange));
    final triTop = achseY - u * 0.30;
    final triH = u * 0.10, triB = u * 0.045;
    canvas.drawLine(
        Offset(mx, triTop),
        Offset(mx, achseY),
        Paint()
          ..color = farbe.withValues(alpha: 0.55)
          ..strokeWidth = 2 * k);
    final dreieck = Path()
      ..moveTo(mx - triB, triTop)
      ..lineTo(mx + triB, triTop)
      ..lineTo(mx, triTop + triH)
      ..close();
    canvas.drawPath(dreieck, Paint()..color = farbe);
    final r = (u * 0.05).clamp(7.0, 18.0).toDouble();
    canvas.drawCircle(Offset(mx, achseY), r, Paint()..color = farbe);
    canvas.drawCircle(
        Offset(mx, achseY),
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * k
          ..color = _kBg);
    if (aktiv && ausserhalb) {
      // Hinweis auf der dem Marker gegenüberliegenden Seite (oben mittig sitzt die Kalibrierleiste).
      final links = grad > 0;
      _beschriften(canvas, 'außerhalb ±${zahl(_kSkala, 0)}°', Offset(links ? w * 0.04 : w * 0.96, achseY - u * 0.18),
          color: _kOrange, size: kopfSize, weight: FontWeight.w700, anker: links ? Alignment.centerLeft : Alignment.centerRight);
    }
  }

  @override
  bool shouldRepaint(SkalaPainter o) => true;
}

/// Digitale Fläche (2D): X/Y in Grad, Skala ±5°, Marker bewegt sich linear mit
/// den Messwerten (X nach rechts, Y nach oben = vorne). Exakt in der Mitte bei X 0,00° / Y 0,00°.
/// Die Fläche ist quadratisch (Seitenlänge = kleinere Seite der Zeichenfläche); alle Maße skalieren mit.
class FlaechePainter extends CustomPainter {
  FlaechePainter({required this.neigung});
  final Neigung? neigung; // null: kein gültiger Messwert

  @override
  void paint(Canvas canvas, Size size) {
    final n = neigung;
    final aktiv = n != null;
    final w = math.max(1.0, math.min(size.width, size.height));
    final f = (w * 0.033).clamp(9.0, 16.0).toDouble(); // Schriftgröße
    final k = (w / 300).clamp(0.7, 2.0).toDouble(); // Strichstärken
    final box = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, w), const Radius.circular(16));
    canvas.drawRRect(box, Paint()..color = _kKarte);
    canvas.drawRRect(
        box,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = _kRand);

    final rand = math.max(w * 0.115, f * 3.0);
    final feld = Rect.fromLTWH(rand, rand, w - 2 * rand, w - 2 * rand);
    final mitte = feld.center;
    final halb = feld.width / 2;
    double px(double g) => mitte.dx + g / _kSkala * halb;
    double py(double g) => mitte.dy - g / _kSkala * halb;

    canvas.drawRect(feld, Paint()..color = const Color(0xFF0A2149));
    // Raster: alle 1°, kräftiger bei ±2,5.
    for (var i = -5; i <= 5; i++) {
      final fein = Paint()
        ..strokeWidth = 1
        ..color = _kRand.withValues(alpha: 0.55);
      canvas.drawLine(Offset(px(i.toDouble()), feld.top), Offset(px(i.toDouble()), feld.bottom), fein);
      canvas.drawLine(Offset(feld.left, py(i.toDouble())), Offset(feld.right, py(i.toDouble())), fein);
    }
    final kraeftig = Paint()
      ..strokeWidth = 1.5 * k
      ..color = _kText2.withValues(alpha: 0.8);
    for (final g in const [-2.5, 2.5]) {
      canvas.drawLine(Offset(px(g), feld.top), Offset(px(g), feld.bottom), kraeftig);
      canvas.drawLine(Offset(feld.left, py(g)), Offset(feld.right, py(g)), kraeftig);
    }
    canvas.drawRect(
        feld,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * k
          ..color = _kText2);
    // Achsenkreuz und Mittenring.
    final kreuz = Paint()
      ..strokeWidth = 2.5 * k
      ..color = Colors.white;
    canvas.drawLine(Offset(feld.left, mitte.dy), Offset(feld.right, mitte.dy), kreuz);
    canvas.drawLine(Offset(mitte.dx, feld.top), Offset(mitte.dx, feld.bottom), kreuz);
    canvas.drawCircle(
        mitte,
        halb * 0.06,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * k
          ..color = _kLimeMitte);

    // Beschriftung der Skala und der Seiten.
    for (final g in const [-5.0, -2.5, 0.0, 2.5, 5.0]) {
      final t = g == 0 ? '0°' : '${g > 0 ? '+' : '−'}${zahl(g.abs(), g.abs() == 2.5 ? 1 : 0)}°';
      _beschriften(canvas, t, Offset(px(g), feld.bottom + f * 0.9), size: f);
      _beschriften(canvas, t, Offset(feld.left - f * 0.5, py(g)), size: f, anker: Alignment.centerRight);
    }
    _beschriften(canvas, 'VORNE', Offset(mitte.dx, f * 0.9), size: f, weight: FontWeight.w800);
    _beschriften(canvas, 'HINTEN', Offset(mitte.dx, w - f * 0.9), size: f, weight: FontWeight.w800);
    _beschriften(canvas, 'LINKS', Offset(w * 0.02, w - f * 0.9), size: f, weight: FontWeight.w800, anker: Alignment.centerLeft);
    _beschriften(canvas, 'RECHTS', Offset(w * 0.98, w - f * 0.9), size: f, weight: FontWeight.w800, anker: Alignment.centerRight);

    // Marker. Außerhalb der Skala bleibt er am Rand (Richtung bleibt erhalten) und wird orange.
    final fm = flaechenAnteil(n?.aGrad ?? 0.0, n?.bGrad ?? 0.0);
    final ausserhalb = fm.ausserhalb;
    final pos = Offset(mitte.dx + fm.x * halb, mitte.dy - fm.y * halb);
    final nn = n;
    final farbe = nn == null
        ? const Color(0xFF8E99AB)
        : (ausserhalb ? _kOrange : (imToleranzbereich(nn.aGrad) && imToleranzbereich(nn.bGrad) ? _kGruen : _kOrange));
    final r = (w * 0.03).clamp(7.0, 17.0).toDouble();
    canvas.drawCircle(pos, r * 1.65, Paint()..color = farbe.withValues(alpha: 0.28));
    canvas.drawCircle(pos, r, Paint()..color = farbe);
    canvas.drawCircle(
        pos,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * k
          ..color = _kBg);
    if (aktiv && ausserhalb) {
      _beschriften(canvas, 'außerhalb ±${zahl(_kSkala, 0)}°', Offset(feld.right - 4, feld.top + f * 1.1),
          color: _kOrange, size: f, weight: FontWeight.w700, anker: Alignment.centerRight);
    }
  }

  @override
  bool shouldRepaint(FlaechePainter o) => true;
}
