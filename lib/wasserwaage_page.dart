import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'wasserwaage_logik.dart';

String _z(double v, [int d = 2]) {
  final s = v.toStringAsFixed(d).replaceAll('.', ',');
  // „−0,00“ vermeiden
  return RegExp(r'^-0[,0]*$').hasMatch(s) ? s.substring(1) : s;
}

const _kHinweis =
    'Die Messung erfolgt mit den Bewegungssensoren des Smartphones. '
    'Die Genauigkeit hängt vom Gerät, der Positionierung und der Kalibrierung ab.';

/// Wasserwaage: Neigung aus dem Schwerkraftvektor (Beschleunigungssensor,
/// mit Gyroskop geglättet), in jeder Lage des Handys.
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

  final Map<String, Kalibrierung> _kals = {};
  bool _kalLaeuft = false;
  int _kalStart = 0;
  String? _kalMeldung;
  String? _kalOk;
  final List<Vek> _kalProben = [];

  @override
  void initState() {
    super.initState();
    // Die Messung hängt nicht an der Bildschirmdrehung. Das Layout bleibt im
    // Hochformat; Lage und Seiten werden aus dem Sensor bestimmt und benannt.
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
    final k = kalibriere(List.of(_kalProben));
    if (k == null) {
      _kalMeldung = 'Kalibrierung nicht möglich: kein Sensorwert. Bitte wiederholen.';
    } else if (k.streuungGrad > kKalibrierMaxStreuung) {
      _kalMeldung = 'Das Handy wurde während der Kalibrierung bewegt. Bitte ruhig hinlegen und wiederholen.';
    } else {
      _kals[k.lage.schluessel] = k;
      _kalOk = k.lage.beschreibung;
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
            'Legen Sie das Handy ruhig auf das Bauteil – flach, auf die Seite oder aufrecht an eine '
            'Fläche. Die Anzeige erkennt die Lage selbst und zeigt die aktuelle Neigung.\n\n'
            'Kalibrieren: Handy auf eine Referenzfläche legen und „Kalibrieren“ tippen. Die Lage in '
            'dieser Zeit (ca. 2 Sekunden) gilt danach als 0,00°. Die Kalibrierung gilt für die Lage, '
            'in der sie gemacht wurde (z. B. flach mit Display oben). „Zurücksetzen“ löscht alle.\n\n'
            'Neigung: Winkel gegen die Senkrechte der Lage.\nGefälle %: Höhenunterschied je 100 cm.\n'
            'Gefälle mm/m: Höhenunterschied je Meter.\n\n'
            'Die Blase wandert zur höheren Seite. Kleine Neigungen sind darin vergrößert gezeichnet; '
            'die Zahlen sind unverändert. Die Werte werden mit dem Gyroskop geglättet, damit sie '
            'nicht springen; im Ruhezustand entspricht der Wert genau der Messung.\n\n$_kHinweis',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Neigung? n0;
    Kalibrierung? kal0;
    if (_hatWerte) {
      final lage = bestimmeLage(_filter.x, _filter.y, _filter.z);
      kal0 = _kals[lage.schluessel];
      n0 = berechneNeigung(_filter.x, _filter.y, _filter.z, lage: lage, a0: kal0?.a0 ?? 0, b0: kal0?.b0 ?? 0);
    }
    final Neigung? n = n0;
    final Kalibrierung? kal = kal0;
    final gueltig = n != null && n.gueltig;
    final eben = n != null && n.gueltig && n.gesamtGrad < 0.1;

    String richtung() {
      if (n == null || !n.gueltig) return '–';
      final t = <String>[];
      if (_z(n.aGrad) != '0,00') t.add('${n.lage.seite(n.lage.a, n.aGrad > 0)} höher');
      if (_z(n.bGrad) != '0,00') t.add('${n.lage.seite(n.lage.b, n.bGrad > 0)} höher');
      return t.isEmpty ? 'Waagerecht' : t.join('  ·  ');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wasserwaage'),
        actions: [IconButton(icon: const Icon(Icons.help_outline), tooltip: 'Hilfe', onPressed: _hilfe)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Icon(Icons.phone_android, color: scheme.onPrimaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Handy auf das Bauteil legen',
                        style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onPrimaryContainer)),
                    const SizedBox(height: 2),
                    Text('Legen Sie das Handy ruhig auf das Bauteil. Die Anzeige zeigt die aktuelle Neigung.',
                        style: TextStyle(color: scheme.onPrimaryContainer)),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          if (_fehler != null)
            Card(
              color: scheme.errorContainer,
              child: Padding(padding: const EdgeInsets.all(14), child: Text(_fehler!)),
            )
          else ...[
            _Anzeige(n: n, kalibriert: kal != null, richtung: richtung()),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(children: [
                  LayoutBuilder(
                    builder: (context, c) {
                      final h = (c.maxWidth - 52) + 112;
                      return SizedBox(
                        height: h,
                        child: CustomPaint(
                          size: Size(c.maxWidth, h),
                          painter: _LibellePainter(
                            neigung: n,
                            aktiv: gueltig,
                            eben: eben,
                            primary: scheme.primary,
                            linie: scheme.outline,
                            text: scheme.onSurfaceVariant,
                            grund: scheme.surfaceContainerHighest,
                          ),
                        ),
                      );
                    },
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.check_circle_outline, color: scheme.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text('Neigung gemessen', style: TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 10),
                  if (_kalLaeuft)
                    Row(children: [
                      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Kalibrierung läuft – Handy ruhig halten …')),
                    ])
                  else if (_kalOk != null)
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.verified_outlined, color: scheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Kalibrierung abgeschlossen\n($_kalOk)')),
                    ])
                  else if (kal != null)
                    const Text('Kalibriert für diese Lage')
                  else
                    Text('Nicht kalibriert (für diese Lage)', style: TextStyle(color: scheme.onSurfaceVariant)),
                  if (_kalMeldung != null) ...[
                    const SizedBox(height: 8),
                    Text(_kalMeldung!, style: TextStyle(color: scheme.error)),
                  ],
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: (_hatWerte && !_kalLaeuft) ? _kalibrierenStart : null,
                        icon: const Icon(Icons.tune),
                        label: const Text('Kalibrieren'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: (_kals.isNotEmpty && !_kalLaeuft) ? _zuruecksetzen : null,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Reset'),
                    ),
                  ]),
                ]),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline, color: scheme.primary, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Hinweis zur Messung', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(_kHinweis),
                  ]),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Große digitale Anzeige im Stil eines Messgeräts.
class _Anzeige extends StatelessWidget {
  const _Anzeige({required this.n, required this.kalibriert, required this.richtung});

  final Neigung? n;
  final bool kalibriert;
  final String richtung;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final neigung = n;
    final ok = neigung != null && neigung.gueltig;
    const ziffern = [FontFeature.tabularFigures()];
    Widget kachel(String titel, String wert) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titel, style: const TextStyle(fontSize: 12, color: Colors.white70)),
              const SizedBox(height: 2),
              Text(wert,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, fontFeatures: ziffern)),
            ]),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Text(
              neigung == null ? 'Warte auf Sensor …' : neigung.lage.beschreibung,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          if (kalibriert)
            const Chip(
              label: Text('kalibriert', style: TextStyle(fontSize: 12)),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
        ]),
        const SizedBox(height: 6),
        Center(
          child: Text(
            ok ? '${_z(neigung!.gesamtGrad)}°' : '–',
            style: const TextStyle(
                fontSize: 64, fontWeight: FontWeight.w800, color: Colors.white, fontFeatures: ziffern, height: 1.05),
          ),
        ),
        const Center(child: Text('Neigung', style: TextStyle(color: Colors.white70))),
        const SizedBox(height: 4),
        Center(
          child: Text(
            richtung,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          kachel('Gefälle', ok ? '${_z(neigung!.prozent)} %' : '–'),
          const SizedBox(width: 8),
          kachel('Gefälle', ok ? '${_z(neigung!.mmProM, 1)} mm/m' : '–'),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          kachel(neigung?.lage.titelA ?? 'Achse A', ok ? '${_z(neigung!.aGrad)}°' : '–'),
          const SizedBox(width: 8),
          kachel(neigung?.lage.titelB ?? 'Achse B', ok ? '${_z(neigung!.bGrad)}°' : '–'),
        ]),
      ]),
    );
  }
}

/// Libelle: Kreis mit Blase und Skalenringen, dazu eine waagerechte und eine
/// senkrechte Leiste. Die Blase wandert zur höheren Seite und kommt aus
/// derselben Rechnung wie die Zahlen. Grün nur als Darstellung bei < 0,1°.
class _LibellePainter extends CustomPainter {
  _LibellePainter({
    required this.neigung,
    required this.aktiv,
    required this.eben,
    required this.primary,
    required this.linie,
    required this.text,
    required this.grund,
  });

  final Neigung? neigung;
  final bool aktiv, eben;
  final Color primary, linie, text, grund;

  static const _ringe = [1.0, 5.0, 15.0, 30.0, 45.0];

  void _beschrifte(Canvas c, String s, Offset mitte, {double size = 12, FontWeight w = FontWeight.w400}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: size, color: text, fontWeight: w)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, mitte - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final farbe = !aktiv ? linie : (eben ? const Color(0xFF2E7D32) : primary);
    final duenn = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = linie.withValues(alpha: 0.6);
    final stark = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = linie;

    final n = neigung;
    final lage = n?.lage ?? const Lage(Achse.z, true);

    const links = 12.0, rechtsPlatz = 40.0, oben = 26.0;
    final r = (size.width - links - rechtsPlatz) / 2;
    final br = r * 0.11; // Blasenradius
    final skalaR = r - br; // Radius, bei dem die größte Neigung der Lage liegt
    final mitte = Offset(links + r, oben + r);

    // Kreis, Skalenringe, Fadenkreuz.
    canvas.drawCircle(mitte, r, Paint()..color = grund);
    canvas.drawCircle(mitte, r, stark);
    for (final a in _ringe) {
      final rr = skalaR * anzeigeSkala(a);
      canvas.drawCircle(mitte, rr, duenn);
      _beschrifte(canvas, '${a.toInt()}°', mitte + Offset(rr * 0.7071 + 9, -rr * 0.7071 - 1), size: 10);
    }
    canvas.drawLine(mitte - Offset(r, 0), mitte + Offset(r, 0), duenn);
    canvas.drawLine(mitte - Offset(0, r), mitte + Offset(0, r), duenn);
    canvas.drawCircle(mitte, 4, stark); // klare Mitte

    // Blase.
    final pos = (n == null || !n.gueltig) ? (dx: 0.0, dy: 0.0) : blasenPosition(n);
    final bm = mitte + Offset(pos.dx, pos.dy) * skalaR;
    canvas.drawCircle(bm, br, Paint()..color = farbe.withValues(alpha: 0.8));
    canvas.drawCircle(
        bm,
        br,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = farbe);
    canvas.drawCircle(bm - Offset(br * 0.3, br * 0.3), br * 0.25, Paint()..color = Colors.white.withValues(alpha: 0.6));

    // Beschriftung oben/unten (b-Achse).
    _beschrifte(canvas, '↑ ${lage.seite(lage.b, true)}', Offset(mitte.dx, oben - 12), w: FontWeight.w600);
    _beschrifte(canvas, '↓ ${lage.seite(lage.b, false)}', Offset(mitte.dx, mitte.dy + r + 12), w: FontWeight.w600);

    final aGrad = n?.aGrad ?? 0, bGrad = n?.bGrad ?? 0;

    // Waagerechte Leiste (a-Achse) unter dem Kreis.
    final ly = mitte.dy + r + 44;
    final halb = r;
    final leiste = RRect.fromRectAndRadius(
        Rect.fromLTWH(mitte.dx - halb, ly - 8, 2 * halb, 16), const Radius.circular(8));
    canvas.drawRRect(leiste, Paint()..color = grund);
    canvas.drawRRect(leiste, stark);
    final halbNutz = halb - 12;
    for (final a in _ringe) {
      for (final s in [-1, 1]) {
        final tx = mitte.dx + s * anzeigeSkala(a) * halbNutz;
        canvas.drawLine(Offset(tx, ly - 4), Offset(tx, ly + 4), duenn);
      }
    }
    canvas.drawLine(Offset(mitte.dx, ly - 8), Offset(mitte.dx, ly + 8), stark);
    canvas.drawCircle(Offset(mitte.dx + leistenPosition(aGrad) * halbNutz, ly), 10, Paint()..color = farbe);
    _beschrifte(canvas, '← ${lage.seite(lage.a, false)}', Offset(mitte.dx - halb + 40, ly + 24), w: FontWeight.w600);
    _beschrifte(canvas, '${lage.seite(lage.a, true)} →', Offset(mitte.dx + halb - 40, ly + 24), w: FontWeight.w600);

    // Senkrechte Leiste (b-Achse) rechts neben dem Kreis.
    final vx = size.width - 14;
    final vh = skalaR;
    final vleiste = RRect.fromRectAndRadius(
        Rect.fromLTWH(vx - 8, mitte.dy - r, 16, 2 * r), const Radius.circular(8));
    canvas.drawRRect(vleiste, Paint()..color = grund);
    canvas.drawRRect(vleiste, stark);
    for (final a in _ringe) {
      for (final s in [-1, 1]) {
        final ty = mitte.dy - s * anzeigeSkala(a) * vh;
        canvas.drawLine(Offset(vx - 4, ty), Offset(vx + 4, ty), duenn);
      }
    }
    canvas.drawLine(Offset(vx - 8, mitte.dy), Offset(vx + 8, mitte.dy), stark);
    canvas.drawCircle(Offset(vx, mitte.dy - leistenPosition(bGrad) * vh), 10, Paint()..color = farbe);
  }

  @override
  bool shouldRepaint(_LibellePainter o) => true;
}
