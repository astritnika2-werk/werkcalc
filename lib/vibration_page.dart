import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'pumpe_lauf_logik.dart';

String _z(double v, [int d = 1]) => v.toStringAsFixed(d).replaceAll('.', ',');

const _kHinweis =
    'Reine Messwerte des Beschleunigungssensors im Handy (ohne Schwerkraft) – keine Bewertung '
    'und kein Normnachweis. Handy-Sensoren sind nicht kalibriert; Beurteilungen nach Norm '
    '(z. B. Schwinggeschwindigkeit) sind damit nicht möglich. Die Werte eignen sich für den '
    'Vergleich gleicher Messungen am gleichen Bauteil.';

/// Vibration prüfen: 8 s Messung mit dem Beschleunigungssensor.
class VibrationPage extends StatefulWidget {
  const VibrationPage({super.key});

  @override
  State<VibrationPage> createState() => _VibrationPageState();
}

class _VibrationPageState extends State<VibrationPage> {
  static const _sek = 8;

  StreamSubscription<UserAccelerometerEvent>? _sa;
  Timer? _timer;
  final Stopwatch _uhr = Stopwatch();
  final List<double> _werte = []; // |a| in mm/s²
  final List<int> _zeiten = []; // ms seit Start
  bool _messen = false;
  bool _fertig = false;
  int _ms = 0;
  String? _fehler;

  @override
  void dispose() {
    _stopp();
    super.dispose();
  }

  void _stopp() {
    _sa?.cancel();
    _timer?.cancel();
    _sa = null;
    _timer = null;
    _uhr.stop();
  }

  void _start() {
    _stopp();
    _werte.clear();
    _zeiten.clear();
    setState(() {
      _messen = true;
      _fertig = false;
      _ms = 0;
      _fehler = null;
    });
    _uhr
      ..reset()
      ..start();
    _sa = userAccelerometerEventStream(samplingPeriod: const Duration(milliseconds: 10)).listen((e) {
      _werte.add(math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z) * 1000);
      _zeiten.add(_uhr.elapsedMilliseconds);
    }, onError: (_) {
      _stopp();
      if (mounted) {
        setState(() {
          _messen = false;
          _fehler = 'Beschleunigungssensor nicht verfügbar – dieses Handy liefert keine Messwerte.';
        });
      }
    });
    _timer = Timer.periodic(const Duration(milliseconds: 150), (t) {
      final ms = _uhr.elapsedMilliseconds;
      if (ms >= _sek * 1000) {
        _stopp();
        setState(() {
          _messen = false;
          _fertig = true;
          _ms = _sek * 1000;
        });
      } else if (mounted) {
        setState(() => _ms = ms);
      }
    });
  }

  void _hilfe() {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Vibration prüfen'),
        content: SingleChildScrollView(
          child: Text(
            'Telefon fest an das Bauteil halten und während der Messung ruhig halten. '
            'Gemessen wird 8 Sekunden lang der Betrag der Beschleunigung (ohne Schwerkraft).\n\n'
            'RMS: Effektivwert aller Messwerte.\nMaximum: höchster Messwert.\n'
            'Schwankung: Standardabweichung der Messwerte.\nAktueller Messwert: letzter Messwert.\n\n$_kHinweis',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final k = kennwerte(_werte);
    final aktuell = _werte.isEmpty ? 0.0 : _werte.last;
    final rate = _ms > 0 ? _werte.length * 1000 / _ms : 0.0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vibration prüfen'),
        actions: [IconButton(icon: const Icon(Icons.help_outline), tooltip: 'Hilfe', onPressed: _hilfe)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _Karte(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Telefon an das Bauteil halten und während der Messung ruhig halten.',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                _Zeile(Icons.timer_outlined, 'Messdauer', '$_sek Sekunden'),
                const SizedBox(height: 6),
                _Zeile(Icons.sensors, 'Sensor', 'Beschleunigungssensor'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _messen ? null : _start,
                  icon: Icon(_fertig ? Icons.refresh : Icons.play_arrow),
                  label: Text(_fertig ? 'Erneut messen ($_sek s)' : 'Messung starten ($_sek s)'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
                if (_messen) ...[
                  const SizedBox(height: 10),
                  Text('Messung läuft … noch ${math.max(0, _sek - (_ms / 1000).floor())} s',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(minHeight: 8, value: (_ms / (_sek * 1000)).clamp(0.0, 1.0)),
                  ),
                ],
                if (_fehler != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_fehler!, style: const TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),
          if (_messen || _fertig) ...[
            const SizedBox(height: 12),
            _Karte(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_fertig ? 'MESSERGEBNIS' : 'LIVE-MESSUNG',
                      style: TextStyle(
                          color: scheme.primary, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.2,
                    children: [
                      _Kachel('RMS', _z(k.rms), 'mm/s²'),
                      _Kachel('Maximum', _z(k.max), 'mm/s²'),
                      _Kachel('Schwankung', _z(k.streuung), 'mm/s² (Std.-Abw.)'),
                      _Kachel(_fertig ? 'Letzter Messwert' : 'Aktueller Messwert', _z(aktuell), 'mm/s²'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Vibrationssignal', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 170,
                    child: CustomPaint(
                      painter: _DiagrammPainter(
                        List.of(_werte),
                        List.of(_zeiten),
                        _sek,
                        scheme.primary,
                        Theme.of(context).brightness,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                  const Center(child: Text('Zeit (s)', style: TextStyle(fontSize: 12))),
                ],
              ),
            ),
          ],
          if (_fertig) ...[
            const SizedBox(height: 12),
            _Karte(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Messdetails', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 6),
                  _Detail('Mittelwert', '${_z(k.mittel)} mm/s²'),
                  _Detail('RMS', '${_z(k.rms)} mm/s²'),
                  _Detail('Minimum', '${_z(k.min)} mm/s²'),
                  _Detail('Maximum', '${_z(k.max)} mm/s²'),
                  _Detail('Spitze–Spitze', '${_z(k.max - k.min)} mm/s²'),
                  _Detail('Schwankung (Std.-Abw.)', '${_z(k.streuung)} mm/s²'),
                  _Detail('Schwankung (Hochpass-RMS)', '${_z(schwankungRms([for (final v in _werte) v]))} mm/s²'),
                  _Detail('Messwerte', '${k.n}'),
                  _Detail('Messdauer', '${_z(_ms / 1000)} s'),
                  _Detail('Abtastrate', '${_z(rate, 0)} Hz (${switch (signalGuete(rate)) {
                    SignalGuete.gut => 'Gut',
                    SignalGuete.mittel => 'Mittel',
                    SignalGuete.schwach => 'Schwach',
                  }})'),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text(_kHinweis, style: TextStyle(fontSize: 12)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Karte extends StatelessWidget {
  const _Karte({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Padding(padding: const EdgeInsets.all(14), child: child),
      );
}

class _Zeile extends StatelessWidget {
  const _Zeile(this.icon, this.label, this.wert);
  final IconData icon;
  final String label;
  final String wert;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: c)),
          Expanded(child: Text(wert, style: TextStyle(color: c, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _Kachel extends StatelessWidget {
  const _Kachel(this.titel, this.wert, this.einheit);
  final String titel;
  final String wert;
  final String einheit;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(titel, style: const TextStyle(fontSize: 12)),
            Text(wert, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(einheit, style: const TextStyle(fontSize: 11)),
          ],
        ),
      );
}

class _Detail extends StatelessWidget {
  const _Detail(this.l, this.r);
  final String l;
  final String r;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Expanded(child: Text(l)), Text(r, style: const TextStyle(fontWeight: FontWeight.w700))],
        ),
      );
}

/// Technisches Messdiagramm: Raster, beschriftete Achsen (mm/s² über Zeit in s).
class _DiagrammPainter extends CustomPainter {
  _DiagrammPainter(this.v, this.t, this.sek, this.farbe, this.helligkeit);
  final List<double> v;
  final List<int> t;
  final int sek;
  final Color farbe;
  final Brightness helligkeit;

  @override
  void paint(Canvas canvas, Size s) {
    const links = 44.0, unten = 18.0, oben = 6.0, rechts = 6.0;
    final bw = s.width - links - rechts;
    final bh = s.height - unten - oben;
    final text = helligkeit == Brightness.dark ? Colors.white70 : Colors.black54;
    canvas.drawRect(Rect.fromLTWH(links, oben, bw, bh), Paint()..color = farbe.withOpacity(0.05));
    final hi = v.isEmpty ? 10.0 : math.max(v.reduce(math.max), 1.0);
    final grid = Paint()
      ..color = text.withOpacity(0.25)
      ..strokeWidth = 1;
    void beschrifte(String s0, Offset o, {bool zentriert = false}) {
      final tp = TextPainter(
        text: TextSpan(text: s0, style: TextStyle(fontSize: 10, color: text)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, zentriert ? Offset(o.dx - tp.width / 2, o.dy) : Offset(o.dx - tp.width, o.dy - tp.height / 2));
    }

    for (var i = 0; i <= 4; i++) {
      final y = oben + bh * i / 4;
      canvas.drawLine(Offset(links, y), Offset(links + bw, y), grid);
      beschrifte((hi * (1 - i / 4)).toStringAsFixed(0), Offset(links - 4, y));
    }
    for (var i = 0; i <= sek; i += 2) {
      final x = links + bw * i / sek;
      canvas.drawLine(Offset(x, oben), Offset(x, oben + bh), grid);
      beschrifte('$i', Offset(x, oben + bh + 3), zentriert: true);
    }
    if (v.length < 2) return;
    // Fläche + Linie (technischer Verlauf des Beschleunigungsbetrags)
    final linie = Path();
    final flaeche = Path()..moveTo(links, oben + bh);
    for (var i = 0; i < v.length; i++) {
      final x = links + bw * (t[i] / (sek * 1000)).clamp(0.0, 1.0);
      final y = oben + bh - (v[i] / hi) * bh;
      i == 0 ? linie.moveTo(x, y) : linie.lineTo(x, y);
      flaeche.lineTo(x, y);
    }
    flaeche.lineTo(links + bw * (t.last / (sek * 1000)).clamp(0.0, 1.0), oben + bh);
    flaeche.close();
    canvas.drawPath(flaeche, Paint()..color = farbe.withOpacity(0.12));
    canvas.drawPath(
        linie,
        Paint()
          ..color = farbe
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3);
  }

  @override
  bool shouldRepaint(covariant _DiagrammPainter old) => true;
}
