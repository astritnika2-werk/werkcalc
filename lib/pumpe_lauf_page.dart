import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'pumpe_lauf_logik.dart';

const _kHinweis = 'Interne Richtwerte – keine Herstellervorgabe und keine Norm. '
    'Orientierende Messung mit den Sensoren des Handys (Vibration und Magnetfeld); '
    'sie ersetzt keine Prüfung mit Messgerät. Bei „nicht eindeutig“ wird bewusst kein Betrieb gemeldet.';

/// Pumpe läuft prüfen: Referenz fern der Pumpe, dann Messung an der Pumpe.
class PumpeLaufPage extends StatefulWidget {
  const PumpeLaufPage({super.key});

  @override
  State<PumpeLaufPage> createState() => _PumpeLaufPageState();
}

class _PumpeLaufPageState extends State<PumpeLaufPage> {
  static const _refSek = 6;
  static const _probeSek = 8;

  StreamSubscription<UserAccelerometerEvent>? _sa;
  StreamSubscription<MagnetometerEvent>? _sm;
  Timer? _timer;

  final List<double> _acc = [];
  final List<double> _mag = [];
  final List<double> _live = [];
  LaufMessung? _ref;
  LaufMessung? _probe;
  LaufErgebnis? _erg;
  String? _phase; // 'ref' | 'probe'
  int _rest = 0;
  String? _fehler;

  @override
  void dispose() {
    _stopp();
    super.dispose();
  }

  void _stopp() {
    _sa?.cancel();
    _sm?.cancel();
    _timer?.cancel();
    _sa = _sm = null;
    _timer = null;
  }

  void _start(String phase) {
    _stopp();
    _acc.clear();
    _mag.clear();
    _live.clear();
    final sek = phase == 'ref' ? _refSek : _probeSek;
    setState(() {
      _phase = phase;
      _rest = sek;
      _fehler = null;
      if (phase == 'ref') {
        _ref = null;
        _probe = null;
        _erg = null;
      } else {
        _probe = null;
        _erg = null;
      }
    });
    const rate = Duration(milliseconds: 10);
    _sa = userAccelerometerEventStream(samplingPeriod: rate).listen((e) {
      final v = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      _acc.add(v);
      _live.add(v);
      if (_live.length > 300) _live.removeAt(0);
    }, onError: (_) => _sensorFehler());
    _sm = magnetometerEventStream(samplingPeriod: rate).listen((e) {
      _mag.add(math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z));
    }, onError: (_) => _sensorFehler());
    _timer = Timer.periodic(const Duration(milliseconds: 250), (t) {
      final ms = t.tick * 250;
      final left = sek - ms ~/ 1000;
      if (ms >= sek * 1000) {
        _fertig(phase);
      } else if (mounted) {
        setState(() => _rest = left);
      }
    });
  }

  void _sensorFehler() {
    _stopp();
    if (!mounted) return;
    setState(() {
      _phase = null;
      _fehler = 'Sensor nicht verfügbar – dieses Handy liefert keine Messwerte für diese Prüfung.';
    });
  }

  void _fertig(String phase) {
    _stopp();
    final m = LaufMessung(acc: List.of(_acc), mag: List.of(_mag));
    setState(() {
      _phase = null;
      if (phase == 'ref') {
        _ref = m;
      } else {
        _probe = m;
        _erg = bewerteLauf(_ref!, m);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messen = _phase != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Pumpe läuft prüfen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Prüft vor Ort, ob eine eingebaute Pumpe in Betrieb ist – unabhängig von Hersteller und Typ.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: messen ? null : () => _start('ref'),
            icon: const Icon(Icons.looks_one),
            label: const Text('Referenz messen ($_refSek s)'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'Handy ruhig auf einen festen Untergrund legen, mindestens 1 m von Pumpe und Motoren entfernt.',
              style: TextStyle(fontSize: 12.5),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: (messen || _ref == null) ? null : () => _start('probe'),
            icon: const Icon(Icons.looks_two),
            label: const Text('An der Pumpe messen ($_probeSek s)'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'Handy fest an Pumpengehäuse oder Motor drücken und ruhig halten.',
              style: TextStyle(fontSize: 12.5),
            ),
          ),
          if (_fehler != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_fehler!, style: const TextStyle(color: Colors.red)),
            ),
          if (messen) ...[
            const SizedBox(height: 12),
            Text('Messung läuft … noch $_rest s',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 90,
              child: StreamBuilder<int>(
                stream: Stream.periodic(const Duration(milliseconds: 100), (i) => i),
                builder: (c, _) => CustomPaint(
                  painter: _LivePainter(List.of(_live), Theme.of(context).colorScheme.primary),
                  size: Size.infinite,
                ),
              ),
            ),
            StreamBuilder<int>(
              stream: Stream.periodic(const Duration(milliseconds: 300), (i) => i),
              builder: (c, _) {
                final n = _acc.length;
                final tail = n > 100 ? _acc.sublist(n - 100) : _acc;
                return Text(
                  'Live-Messwert Vibration: ${(schwankungRms(tail) * 1000).toStringAsFixed(1)} mm/s²',
                );
              },
            ),
          ],
          if (_ref != null && _phase != 'ref') ...[
            const SizedBox(height: 8),
            Text(
              'Referenz: Vibration ${(_ref!.accRms * 1000).toStringAsFixed(1)} mm/s², '
              'Magnetfeld ${_ref!.magRms.toStringAsFixed(2)} µT',
              style: const TextStyle(fontSize: 12.5),
            ),
          ],
          if (_erg != null && _probe != null) _ergebnis(_erg!, _probe!),
          const SizedBox(height: 16),
          const Text(_kHinweis, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _ergebnis(LaufErgebnis e, LaufMessung p) {
    final (farbe, titel) = switch (e.status) {
      LaufStatus.laeuft => (Colors.green, '🟢 Pumpe läuft – Betrieb erkannt'),
      LaufStatus.steht => (Colors.red, '🔴 Pumpe steht – kein Betrieb erkannt'),
      LaufStatus.unklar => (
          Colors.orange,
          '🟡 Kein eindeutiger Pumpenbetrieb erkannt – Messung wiederholen'
        ),
    };
    String x(double? v) => v == null ? '–' : '${v.toStringAsFixed(1).replaceAll('.', ',')}×';
    return Card(
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: farbe, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titel, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(e.grund),
            const SizedBox(height: 8),
            Text('Vibration: ${(p.accRms * 1000).toStringAsFixed(1)} mm/s² (${x(e.verhaeltnisAcc)} Referenz)'),
            Text('Magnetfeld: ${p.magRms.toStringAsFixed(2)} µT (${x(e.verhaeltnisMag)} Referenz)'),
            Text('Messwerte: ${p.acc.length} / ${p.mag.length}'),
          ],
        ),
      ),
    );
  }
}

class _LivePainter extends CustomPainter {
  _LivePainter(this.v, this.color);
  final List<double> v;
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final bg = Paint()..color = color.withOpacity(0.08);
    canvas.drawRect(Offset.zero & s, bg);
    if (v.length < 2) return;
    final hi = v.reduce(math.max);
    final lo = v.reduce(math.min);
    final span = math.max(hi - lo, 0.01);
    final path = Path();
    for (var i = 0; i < v.length; i++) {
      final x = s.width * i / 299;
      final y = s.height - (v[i] - lo) / span * (s.height - 8) - 4;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant _LivePainter old) => true;
}
