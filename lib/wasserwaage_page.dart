import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'wasserwaage_logik.dart';

String _z(double v, [int d = 1]) => v.toStringAsFixed(d).replaceAll('.', ',');

const _kHinweis =
    'Die Messung erfolgt mit den Bewegungssensoren des Smartphones. '
    'Die Genauigkeit hängt vom Gerät, der Positionierung und der Kalibrierung ab.';

/// Anzeigebereich der Libelle (nur Darstellung, keine Bewertung).
const double _skalaGrad = 5;

/// Wasserwaage: Neigung aus dem Beschleunigungssensor (mit Schwerkraft).
class WasserwaagePage extends StatefulWidget {
  const WasserwaagePage({super.key});

  @override
  State<WasserwaagePage> createState() => _WasserwaagePageState();
}

class _WasserwaagePageState extends State<WasserwaagePage> {
  static const _alpha = 0.15;
  static const _kalibrierMs = 2000;

  StreamSubscription<AccelerometerEvent>? _sa;
  Timer? _timer;
  final Stopwatch _uhr = Stopwatch();
  double _x = 0, _y = 0, _z0 = 0;
  bool _hatWerte = false;
  String? _fehler;

  Kalibrierung? _kal;
  bool _kalibriert = false;
  String? _kalMeldung;
  final List<({double x, double y, double z})> _kalProben = [];
  int _kalStart = 0;

  @override
  void initState() {
    super.initState();
    _sa = accelerometerEventStream(samplingPeriod: const Duration(milliseconds: 20)).listen((e) {
      if (!_hatWerte) {
        _x = e.x;
        _y = e.y;
        _z0 = e.z;
        _hatWerte = true;
      } else {
        _x += _alpha * (e.x - _x);
        _y += _alpha * (e.y - _y);
        _z0 += _alpha * (e.z - _z0);
      }
      if (_kalibriert == false && _kalStart > 0) {
        _kalProben.add((x: e.x, y: e.y, z: e.z));
      }
    }, onError: (_) {
      if (mounted) {
        setState(() => _fehler = 'Beschleunigungssensor nicht verfügbar – dieses Handy liefert keine Messwerte.');
      }
    });
    _uhr.start();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      if (_kalStart > 0 && _uhr.elapsedMilliseconds - _kalStart >= _kalibrierMs) {
        _kalibrierungAbschliessen();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _sa?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _kalibrierenStart() {
    _kalProben.clear();
    _kalibriert = false;
    _kalMeldung = null;
    _kalStart = _uhr.elapsedMilliseconds == 0 ? 1 : _uhr.elapsedMilliseconds;
    setState(() {});
  }

  void _kalibrierungAbschliessen() {
    _kalStart = 0;
    final k = kalibriere(List.of(_kalProben));
    if (k == null) {
      _kalMeldung = 'Kalibrierung nicht möglich: Handy mit dem Display nach oben auf eine Fläche legen.';
    } else if (k.streuungGrad > kKalibrierMaxStreuung) {
      _kalMeldung = 'Das Handy wurde während der Kalibrierung bewegt. Bitte ruhig hinlegen und wiederholen.';
    } else {
      _kal = k;
      _kalibriert = true;
      _kalMeldung = null;
    }
  }

  void _zuruecksetzen() {
    setState(() {
      _kal = null;
      _kalibriert = false;
      _kalMeldung = null;
      _kalStart = 0;
    });
  }

  void _hilfe() {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Wasserwaage'),
        content: SingleChildScrollView(
          child: Text(
            'Legen Sie das Handy mit dem Display nach oben ruhig auf das Bauteil. '
            'Die Anzeige zeigt die aktuelle Neigung.\n\n'
            'Kalibrieren: Handy auf eine Referenzfläche legen und „Kalibrieren“ tippen. '
            'Die Lage in dieser Zeit (ca. 2 Sekunden) gilt danach als 0,0°.\n\n'
            'Neigung: Winkel gegen die Waagerechte.\nGefälle %: Höhenunterschied je 100 cm.\n'
            'Gefälle mm/m: Höhenunterschied je Meter.\n\n$_kHinweis',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final n = _hatWerte
        ? berechneNeigung(_x, _y, _z0, roll0: _kal?.roll0 ?? 0, pitch0: _kal?.pitch0 ?? 0)
        : null;
    final kalibriertGerade = _kalStart > 0;
    final eben = n != null && n.flach && n.gesamtGrad < 0.1;

    String richtung() {
      if (n == null || !n.flach) return '–';
      final t = <String>[];
      if (n.rollGrad.abs() >= 0.05) t.add(n.rollGrad > 0 ? 'rechts höher' : 'links höher');
      if (n.pitchGrad.abs() >= 0.05) t.add(n.pitchGrad > 0 ? 'vorne höher' : 'hinten höher');
      return t.isEmpty ? 'waagerecht' : t.join(', ');
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(n == null ? '–' : '${_z(n.gesamtGrad)}°',
                        style: TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: scheme.primary)),
                  ]),
                  Text('Neigung', style: TextStyle(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 280,
                    child: CustomPaint(
                      painter: _LibellePainter(
                        roll: n?.flach == true ? n!.rollGrad : 0,
                        pitch: n?.flach == true ? n!.pitchGrad : 0,
                        aktiv: n?.flach == true,
                        eben: eben,
                        primary: scheme.primary,
                        linie: scheme.outline,
                        text: scheme.onSurfaceVariant,
                        grund: scheme.surfaceContainerHighest,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    n == null
                        ? 'Warte auf Sensor …'
                        : (n.flach ? richtung() : 'Handy mit dem Display nach oben flach hinlegen'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Kachel('Gefälle', n == null ? '–' : '${_z(n.prozent)} %')),
              const SizedBox(width: 8),
              Expanded(child: _Kachel('Gefälle', n == null ? '–' : '${_z(n.mmProM)} mm/m')),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _Kachel('Winkel X (links/rechts)', n == null ? '–' : '${_z(n.rollGrad, 2)}°')),
              const SizedBox(width: 8),
              Expanded(child: _Kachel('Winkel Y (vorne/hinten)', n == null ? '–' : '${_z(n.pitchGrad, 2)}°')),
            ]),
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
                  if (kalibriertGerade)
                    Row(children: [
                      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Kalibrierung läuft – Handy ruhig halten …')),
                    ])
                  else if (_kalibriert)
                    Row(children: [
                      Icon(Icons.verified_outlined, color: scheme.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text('Kalibrierung abgeschlossen'),
                    ])
                  else
                    Text('Nicht kalibriert', style: TextStyle(color: scheme.onSurfaceVariant)),
                  if (_kalMeldung != null) ...[
                    const SizedBox(height: 8),
                    Text(_kalMeldung!, style: TextStyle(color: scheme.error)),
                  ],
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: (_hatWerte && !kalibriertGerade) ? _kalibrierenStart : null,
                        icon: const Icon(Icons.tune),
                        label: const Text('Kalibrieren'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: (_kal != null && !kalibriertGerade) ? _zuruecksetzen : null,
                      child: const Text('Zurücksetzen'),
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

class _Kachel extends StatelessWidget {
  const _Kachel(this.titel, this.wert);
  final String titel;
  final String wert;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titel, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(wert, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}

/// Libelle: Kreis mit Blase, dazu waagerechte und senkrechte Leiste.
/// Die Blase wandert zur höheren Seite. Grün nur als Darstellung bei < 0,1°.
class _LibellePainter extends CustomPainter {
  _LibellePainter({
    required this.roll,
    required this.pitch,
    required this.aktiv,
    required this.eben,
    required this.primary,
    required this.linie,
    required this.text,
    required this.grund,
  });

  final double roll, pitch;
  final bool aktiv, eben;
  final Color primary, linie, text, grund;

  void _beschrifte(Canvas c, String s, Offset mitte) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: 12, color: text)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, mitte - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final farbe = !aktiv ? linie : (eben ? const Color(0xFF2E7D32) : primary);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = linie;

    // Kreis in der Mitte, Platz links/rechts für Beschriftung, unten für Leiste.
    const rand = 56.0;
    final r = math.min(size.width - 2 * rand, size.height - 56) / 2;
    final mitte = Offset(size.width / 2, r + 4);
    canvas.drawCircle(mitte, r, Paint()..color = grund);
    canvas.drawCircle(mitte, r, stroke);
    canvas.drawCircle(mitte, r * 2 / 3, stroke..strokeWidth = 1);
    canvas.drawCircle(mitte, r / 3, stroke);
    canvas.drawLine(mitte - Offset(r, 0), mitte + Offset(r, 0), stroke);
    canvas.drawLine(mitte - Offset(0, r), mitte + Offset(0, r), stroke);

    double lim(double v) => (v / _skalaGrad).clamp(-1.0, 1.0);
    // Vektor der Blase, auf den Kreis begrenzt.
    var dx = lim(roll), dy = -lim(pitch);
    final len = math.sqrt(dx * dx + dy * dy);
    if (len > 1) {
      dx /= len;
      dy /= len;
    }
    final br = r * 0.14;
    final bm = mitte + Offset(dx, dy) * (r - br);
    canvas.drawCircle(bm, br, Paint()..color = farbe.withValues(alpha: 0.85));
    canvas.drawCircle(bm, br, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = farbe);

    _beschrifte(canvas, '← Links', Offset(rand / 2 + 2, mitte.dy));
    _beschrifte(canvas, 'Rechts →', Offset(size.width - rand / 2 - 2, mitte.dy));
    _beschrifte(canvas, '↑ Vorne', Offset(mitte.dx, mitte.dy - r - 0));
    _beschrifte(canvas, '↓ Hinten', Offset(mitte.dx, mitte.dy + r + 2));

    // Waagerechte Leiste unten.
    final ly = size.height - 18;
    final lb = size.width - 2 * rand;
    final l0 = rand;
    final leiste = RRect.fromRectAndRadius(
        Rect.fromLTWH(l0, ly - 7, lb, 14), const Radius.circular(7));
    canvas.drawRRect(leiste, Paint()..color = grund);
    canvas.drawRRect(leiste, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = linie);
    for (var i = -5; i <= 5; i++) {
      final tx = l0 + lb / 2 + i * (lb / 2 - 10) / 5;
      canvas.drawLine(Offset(tx, ly - (i == 0 ? 7 : 4)), Offset(tx, ly + (i == 0 ? 7 : 4)),
          Paint()..color = linie..strokeWidth = i == 0 ? 2 : 1);
    }
    final bx = l0 + lb / 2 + lim(roll) * (lb / 2 - 10);
    canvas.drawCircle(Offset(bx, ly), 9, Paint()..color = farbe);
    _beschrifte(canvas, '← Links  ─  ●  ─  Rechts →', Offset(size.width / 2, ly + 14));

    // Senkrechte Leiste rechts außen.
    final vx = size.width - 12;
    final vt = mitte.dy - r * 0.8;
    final vh = r * 1.6;
    final vleiste = RRect.fromRectAndRadius(
        Rect.fromLTWH(vx - 7, vt, 14, vh), const Radius.circular(7));
    canvas.drawRRect(vleiste, Paint()..color = grund);
    canvas.drawRRect(vleiste, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = linie);
    for (var i = -5; i <= 5; i++) {
      final ty = vt + vh / 2 - i * (vh / 2 - 10) / 5;
      canvas.drawLine(Offset(vx - (i == 0 ? 7 : 4), ty), Offset(vx + (i == 0 ? 7 : 4), ty),
          Paint()..color = linie..strokeWidth = i == 0 ? 2 : 1);
    }
    final by = vt + vh / 2 - lim(pitch) * (vh / 2 - 10);
    canvas.drawCircle(Offset(vx, by), 9, Paint()..color = farbe);
  }

  @override
  bool shouldRepaint(_LibellePainter o) =>
      o.roll != roll || o.pitch != pitch || o.aktiv != aktiv || o.eben != eben;
}
