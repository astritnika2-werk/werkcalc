import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'pumpe_analyse.dart';
import 'pumpe_direkt.dart';

const _kHinweis = 'Die Prüfung ist eine orientierende Messung mit dem Beschleunigungssensor des '
    'Smartphones. Sie erkennt nur, ob am Gehäuse eine typische gleichbleibende Motorvibration '
    'vorhanden ist. Der Wasser-Volumenstrom wird NICHT gemessen. Gleichbleibende Vibrationen '
    'anderer Maschinen oder des Untergrunds können nicht von der Pumpe unterschieden werden. '
    'Sie ersetzt keine elektrische oder messtechnische Prüfung. Die Bewertungsgrenzen sind '
    'interne Richtwerte – keine Herstellervorgabe und keine Norm.';

String _z(double v, [int d = 1]) => v.toStringAsFixed(d).replaceAll('.', ',');

/// Pumpe läuft prüfen: Handy an die Pumpe halten – die App misst und zeigt das Ergebnis automatisch.
class PumpeLaufPage extends StatefulWidget {
  const PumpeLaufPage({super.key});

  @override
  State<PumpeLaufPage> createState() => _PumpeLaufPageState();
}

class _PumpeLaufPageState extends State<PumpeLaufPage> with SingleTickerProviderStateMixin {
  final DirektAuswertung _auswertung = DirektAuswertung();
  StreamSubscription<AccelerometerEvent>? _sa;
  Timer? _timer;
  late final AnimationController _anim;
  DateTime? _t0;
  String? _fehler;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _start();
  }

  @override
  void dispose() {
    _sa?.cancel();
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  void _start() {
    _sa?.cancel();
    _timer?.cancel();
    _auswertung.neu();
    _t0 = null;
    _fehler = null;
    _sa = accelerometerEventStream(samplingPeriod: const Duration(milliseconds: 5)).listen((e) {
      _t0 ??= e.timestamp;
      _auswertung.add(e.timestamp.difference(_t0!).inMicroseconds / 1e6, e.x, e.y, e.z);
    }, onError: (_) {
      _sa?.cancel();
      _timer?.cancel();
      if (mounted) {
        setState(() => _fehler = 'Beschleunigungssensor nicht verfügbar – dieses Handy liefert keine Messwerte für diese Prüfung.');
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final alt = _auswertung.anzeige;
      final neu = _auswertung.auswerten();
      if (!mounted) return;
      if (neu != alt) _animationAnpassen(neu);
      setState(() {});
    });
    _animationAnpassen(PumpeAnzeige.analyse);
  }

  void _animationAnpassen(PumpeAnzeige a) {
    switch (a) {
      case PumpeAnzeige.laeuft:
        _anim
          ..duration = const Duration(milliseconds: 1400)
          ..repeat();
      case PumpeAnzeige.steht:
      case PumpeAnzeige.unklar:
        _anim.stop();
      case PumpeAnzeige.analyse:
        _anim
          ..duration = const Duration(milliseconds: 1600)
          ..repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _auswertung.anzeige;
    final (Color c, String titel, String unter) = switch (a) {
      PumpeAnzeige.laeuft => (const Color(0xFF2FBF4A), 'PUMPE LÄUFT', 'Zirkulation erkannt'),
      PumpeAnzeige.steht => (const Color(0xFFE5484D), 'PUMPE STEHT', 'Keine typische Pumpenvibration erkannt'),
      PumpeAnzeige.unklar => (
          const Color(0xFFF5B301),
          'MESSUNG NICHT EINDEUTIG',
          _auswertung.befund?.text ?? kTextDirektNaeher,
        ),
      PumpeAnzeige.analyse => (
          const Color(0xFFF5B301),
          'ANALYSE LÄUFT …',
          _auswertung.laufzeit < DirektAuswertung.minSek
              ? 'Smartphone fest an die Pumpe halten und ruhig bleiben'
              : 'Bitte weiter ruhig halten',
        ),
    };
    final b = _auswertung.befund;
    final sp = _auswertung.spektrum;
    final details = <String>[
      'Messdauer: ${_z(_auswertung.laufzeit)} s (Fenster ${_z(_auswertung.fensterDauer)} s)',
      if (sp != null) 'Abtastrate: ${_z(sp.fs, 0)} Hz, ${sp.n} Messwerte',
      if (b?.spitzeHz != null) 'Stärkste Schwingung bei: ${_z(b!.spitzeHz!)} Hz',
      if (b?.spitzeRms != null) 'Amplitude (rms): ${_z(b!.spitzeRms! * 1000)} mm/s²',
      if (b?.tonalitaet != null) 'Tonalität (Spitze/Rauschboden): ${_z(b!.tonalitaet!)} ×',
      if (b?.persistenzAnteil != null) 'In ${_z(b!.persistenzAnteil! * 100, 0)} % der Abschnitte vorhanden',
      if (b?.nachweisGrenze != null) 'Nachweisgrenze: ${_z(b!.nachweisGrenze! * 1000)} mm/s²',
      if (sp != null) 'Handbewegung (1,5–8 Hz): ${_z(sp.lfRms * 1000)} mm/s²',
      'Interne Richtwerte, keine Herstellervorgabe, keine Norm.',
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Pumpe läuft prüfen')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_fehler != null)
              Card(child: Padding(padding: const EdgeInsets.all(14), child: Text(_fehler!))),
            const SizedBox(height: 8),
            Center(
              child: AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => SizedBox(
                  width: 260,
                  height: 260,
                  child: CustomPaint(
                    key: const Key('rotor'),
                    painter: RotorPainter(zustand: a, farbe: c, t: _anim.value),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(titel,
                key: const Key('pumpeTitel'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: c, letterSpacing: 1)),
            const SizedBox(height: 6),
            Text(unter, key: const Key('pumpeUnter'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            if (_fehler == null)
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => setState(_start),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Neu messen'),
                ),
              ),
            const SizedBox(height: 12),
            ExpansionTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text('Messwerte (Details)'),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (final d in details) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(d)),
                  ]),
                ),
              ],
            ),
            const ExpansionTile(
              leading: Icon(Icons.info_outline),
              title: Text('Hinweis zur Messung'),
              children: [Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 16), child: Text(_kHinweis))],
            ),
          ],
        ),
      ),
    );
  }
}

/// Rotor-Kreis: dreht sich nur bei erkannter Vibration, steht still bei „steht“/„unklar“, pulsiert bei Analyse.
class RotorPainter extends CustomPainter {
  RotorPainter({required this.zustand, required this.farbe, required this.t});
  final PumpeAnzeige zustand;
  final Color farbe;
  final double t; // 0…1 (Umdrehung bzw. Puls)

  @override
  void paint(Canvas canvas, Size size) {
    final mitte = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 8;
    final puls = zustand == PumpeAnzeige.analyse ? (0.5 - 0.5 * math.cos(t * math.pi)) : 0.0;
    canvas.drawCircle(mitte, r, Paint()..color = farbe.withValues(alpha: 0.10 + 0.14 * puls));
    canvas.drawCircle(
        mitte,
        r * (0.97 + 0.03 * puls),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..color = farbe.withValues(alpha: 0.55 + 0.45 * (zustand == PumpeAnzeige.analyse ? puls : 1)));
    final winkel = zustand == PumpeAnzeige.laeuft ? t * 2 * math.pi : 0.0;
    final fluegel = Paint()..color = farbe.withValues(alpha: zustand == PumpeAnzeige.analyse ? 0.45 + 0.4 * puls : 0.9);
    canvas.save();
    canvas.translate(mitte.dx, mitte.dy);
    canvas.rotate(winkel);
    for (var i = 0; i < 4; i++) {
      canvas.rotate(math.pi / 2);
      final p = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(r * 0.40, -r * 0.10, r * 0.62, -r * 0.55)
        ..quadraticBezierTo(r * 0.10, -r * 0.45, 0, 0);
      canvas.drawPath(p, fluegel);
    }
    canvas.restore();
    canvas.drawCircle(mitte, r * 0.09, Paint()..color = farbe);
  }

  @override
  bool shouldRepaint(RotorPainter o) => o.t != t || o.zustand != zustand || o.farbe != farbe;
}
