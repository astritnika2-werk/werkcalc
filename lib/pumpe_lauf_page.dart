import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'pumpe_analyse.dart';
import 'pumpe_lauf_logik.dart' show LaufStatus;

const _kHinweis = 'Die Prüfung ist eine orientierende Messung mit dem Beschleunigungssensor des '
    'Smartphones. Sie erkennt nur, ob am Gehäuse eine typische gleichbleibende Motorvibration '
    'vorhanden ist. Der Wasser-Volumenstrom wird NICHT gemessen. Sie ersetzt keine elektrische '
    'oder messtechnische Prüfung. Die Bewertungsgrenzen sind interne Richtwerte – keine '
    'Herstellervorgabe und keine Norm.';

String _z(double v, [int d = 1]) => v.toStringAsFixed(d).replaceAll('.', ',');

/// Pumpe läuft prüfen: Referenz fern der Pumpe, dann Messung direkt an der Pumpe.
class PumpeLaufPage extends StatefulWidget {
  const PumpeLaufPage({super.key});

  @override
  State<PumpeLaufPage> createState() => _PumpeLaufPageState();
}

class _PumpeLaufPageState extends State<PumpeLaufPage> {
  static const _refSek = 6;
  static const _probeSek = 10;

  StreamSubscription<AccelerometerEvent>? _sa;
  Timer? _timer;
  final Stopwatch _uhr = Stopwatch();

  final List<double> _t = [], _x = [], _y = [], _z3 = [];
  Spektrum? _ref;
  PumpeBefund? _befund;
  Spektrum? _probe;
  String? _phase; // 'ref' | 'probe'
  int _verstrichenMs = 0;
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

  void _start(String phase) {
    _stopp();
    _t.clear();
    _x.clear();
    _y.clear();
    _z3.clear();
    final sek = phase == 'ref' ? _refSek : _probeSek;
    setState(() {
      _phase = phase;
      _verstrichenMs = 0;
      _fehler = null;
      if (phase == 'ref') _ref = null;
      _probe = null;
      _befund = null;
    });
    _uhr
      ..reset()
      ..start();
    DateTime? t0;
    _sa = accelerometerEventStream(samplingPeriod: const Duration(milliseconds: 5)).listen((e) {
      t0 ??= e.timestamp;
      _t.add(e.timestamp.difference(t0!).inMicroseconds / 1e6);
      _x.add(e.x);
      _y.add(e.y);
      _z3.add(e.z);
    }, onError: (_) => _sensorFehler());
    _timer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      final ms = _uhr.elapsedMilliseconds;
      if (ms >= sek * 1000) {
        _fertig(phase);
      } else if (mounted) {
        setState(() => _verstrichenMs = ms);
      }
    });
  }

  void _sensorFehler() {
    _stopp();
    if (!mounted) return;
    setState(() {
      _phase = null;
      _fehler = 'Beschleunigungssensor nicht verfügbar – dieses Handy liefert keine Messwerte für diese Prüfung.';
    });
  }

  void _fertig(String phase) {
    final ms = _uhr.elapsedMilliseconds;
    _stopp();
    final sig = PumpeSignal(t: List.of(_t), x: List.of(_x), y: List.of(_y), z: List.of(_z3)).bereinigt(ms);
    final sp = analysiere(sig);
    setState(() {
      _phase = null;
      if (phase == 'ref') {
        _ref = sp;
      } else {
        _probe = sp;
        _befund = bewertePumpe(_ref!, sp);
      }
    });
  }

  void _neu() {
    _stopp();
    setState(() {
      _phase = null;
      _ref = null;
      _probe = null;
      _befund = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pumpe läuft prüfen')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_fehler != null) _karte(Colors.red, Icons.error_outline, _fehler!),
            if (_befund != null) _ergebnis(_befund!) else ..._schritte(),
            const SizedBox(height: 12),
            ExpansionTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Hinweis zur Messung'),
              children: const [
                Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 16), child: Text(_kHinweis)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _karte(Color c, IconData icon, String text) => Card(
        color: c.withOpacity(0.12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: c),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ]),
        ),
      );

  Widget _fortschritt(int sek) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(children: [
          LinearProgressIndicator(value: (_verstrichenMs / (sek * 1000)).clamp(0.0, 1.0)),
          const SizedBox(height: 6),
          Text('Messung läuft … ${_z(_verstrichenMs / 1000)} / $sek s – Handy ruhig halten'),
        ]),
      );

  List<Widget> _schritte() {
    final refOk = _ref != null && bewerteReferenzSpektrum(_ref!).ok;
    final refText = _ref == null ? null : bewerteReferenzSpektrum(_ref!);
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('1. Referenz', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text('Handy flach auf einen festen, ruhigen Untergrund legen – weit weg von der Pumpe. '
                'Nicht berühren.'),
            if (_phase == 'ref') _fortschritt(_refSek) else ...[
              if (refText != null) ...[
                const SizedBox(height: 8),
                refOk
                    ? Row(children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text('Referenz ruhig (${_z(_ref!.fs, 0)} Hz Abtastrate)'),
                      ])
                    : Text(refText.text, style: const TextStyle(color: Colors.orange)),
              ],
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _phase == null ? () => _start('ref') : null,
                icon: const Icon(Icons.play_arrow),
                label: Text(_ref != null ? 'Referenz wiederholen ($_refSek s)' : 'Referenz messen ($_refSek s)'),
              ),
            ],
          ]),
        ),
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('2. An der Pumpe messen', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text('Handy mit der Rückseite fest an das Pumpengehäuse (Motor) drücken und ruhig halten. '
                'Nicht an Rohr oder Kabel, nicht mit den Fingern „wackeln“.'),
            if (_phase == 'probe')
              _fortschritt(_probeSek)
            else ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: refOk && _phase == null ? () => _start('probe') : null,
                icon: const Icon(Icons.vibration),
                label: const Text('An der Pumpe messen ($_probeSek s)'),
              ),
              if (!refOk) const Padding(padding: EdgeInsets.only(top: 6), child: Text('Zuerst eine ruhige Referenz messen.')),
            ],
          ]),
        ),
      ),
    ];
  }

  Widget _ergebnis(PumpeBefund b) {
    final (Color c, String kopf) = switch (b.status) {
      LaufStatus.laeuft => (Colors.green, '🟢 Pumpe läuft – Vibration erkannt'),
      LaufStatus.steht => (Colors.red, '🔴 Keine typische Pumpenvibration erkannt – Pumpe möglicherweise aus'),
      LaufStatus.unklar => (Colors.amber.shade800, '🟡 Messung nicht eindeutig – bitte erneut messen'),
    };
    String? zeile(String l, double? v, String u, [int d = 1]) => v == null ? null : '$l: ${_z(v, d)} $u';
    final details = <String?>[
      zeile('Stärkste Schwingung bei', b.spitzeHz, 'Hz'),
      zeile('Amplitude (rms)', b.spitzeRms == null ? null : b.spitzeRms! * 1000, 'mm/s²', 1),
      zeile('Überhöhung gegenüber Referenz', b.ueberhoehung, '×'),
      zeile('Tonalität (Spitze/Rauschboden)', b.tonalitaet, '×'),
      b.persistenzAnteil == null ? null : 'In ${_z(b.persistenzAnteil! * 100, 0)} % der Abschnitte vorhanden',
      zeile('Rauschen Pumpe/Referenz', b.breitband, '×'),
      zeile('Nachweisgrenze', b.nachweisGrenze == null ? null : b.nachweisGrenze! * 1000, 'mm/s²', 1),
      if (_probe != null) 'Abtastrate: ${_z(_probe!.fs, 0)} Hz, ${_probe!.n} Messwerte',
    ].whereType<String>().toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Card(
        color: c.withOpacity(0.14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: c, width: 2)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(kopf, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(b.text),
          ]),
        ),
      ),
      const SizedBox(height: 4),
      ExpansionTile(
        leading: const Icon(Icons.analytics_outlined),
        title: const Text('Messwerte (Details)'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final d in details) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(d)),
              const SizedBox(height: 6),
              const Text('Interne Richtwerte, keine Herstellervorgabe, keine Norm.',
                  style: TextStyle(fontStyle: FontStyle.italic)),
            ]),
          ),
        ],
      ),
      const SizedBox(height: 8),
      FilledButton.icon(
        onPressed: () => _start('probe'),
        icon: const Icon(Icons.refresh),
        label: const Text('Erneut an der Pumpe messen'),
      ),
      TextButton(onPressed: _neu, child: const Text('Neue Referenz messen')),
    ]);
  }
}
