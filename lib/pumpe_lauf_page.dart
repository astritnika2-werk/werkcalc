import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'pumpe_lauf_logik.dart';

const _kHinweis = 'Die Prüfung ist eine orientierende Messung mit den Sensoren des Smartphones '
    '(Vibration und Magnetfeld). Sie ersetzt keine elektrische oder messtechnische Prüfung. '
    'Die Bewertungsgrenzen sind interne Richtwerte – keine Herstellervorgabe und keine Norm. '
    'Bei „nicht eindeutig“ wird bewusst kein Betrieb gemeldet.';

String _z(double v, [int d = 1]) => v.toStringAsFixed(d).replaceAll('.', ',');

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
  final Stopwatch _uhr = Stopwatch();

  final List<double> _acc = [];
  final List<double> _mag = [];
  final List<double> _live = [];
  LaufMessung? _ref;
  LaufMessung? _probe;
  LaufErgebnis? _erg;
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
    _sm?.cancel();
    _timer?.cancel();
    _sa = _sm = null;
    _timer = null;
    _uhr.stop();
  }

  void _start(String phase) {
    _stopp();
    _acc.clear();
    _mag.clear();
    _live.clear();
    final sek = phase == 'ref' ? _refSek : _probeSek;
    setState(() {
      _phase = phase;
      _verstrichenMs = 0;
      _fehler = null;
      if (phase == 'ref') _ref = null;
      _probe = null;
      _erg = null;
    });
    const rate = Duration(milliseconds: 10);
    _sa = userAccelerometerEventStream(samplingPeriod: rate).listen((e) {
      final v = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      _acc.add(v);
      _live.add(v * 1000);
      if (_live.length > 300) _live.removeAt(0);
    }, onError: (_) => _sensorFehler());
    _sm = magnetometerEventStream(samplingPeriod: rate).listen((e) {
      _mag.add(math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z));
    }, onError: (_) => _sensorFehler());
    _uhr
      ..reset()
      ..start();
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
      _fehler = 'Sensor nicht verfügbar – dieses Handy liefert keine Messwerte für diese Prüfung.';
    });
  }

  void _fertig(String phase) {
    final ms = _uhr.elapsedMilliseconds;
    _stopp();
    final m = LaufMessung(acc: List.of(_acc), mag: List.of(_mag), dauerMs: ms);
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

  void _neu() {
    _stopp();
    setState(() {
      _phase = null;
      _ref = null;
      _probe = null;
      _erg = null;
    });
  }

  void _hilfe() {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('So funktioniert die Messung'),
        content: const SingleChildScrollView(
          child: Text(
            '1. Referenz: Das Handy liegt ruhig, mindestens 1 m von Pumpe und Motoren entfernt. '
            'So wird die normale Umgebung gemessen.\n\n'
            '2. Pumpe: Das Handy wird fest an Gehäuse oder Motor gehalten. Gemessen werden die '
            'Schwankungen von Vibration und Magnetfeld.\n\n'
            'Läuft die Pumpe, liegen beide Werte deutlich über der Referenz. Ist das Signal nicht '
            'stark genug, meldet die App „nicht eindeutig“ und nie „läuft“.\n\n$_kHinweis',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Widget inhalt;
    if (_erg != null && _probe != null && _ref != null) {
      inhalt = _ergebnisSeite(_erg!, _ref!, _probe!);
    } else {
      final stufe = _ref == null && _phase != 'probe' ? 1 : 2;
      inhalt = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _kopf(scheme),
          const SizedBox(height: 12),
          _Stepper(stufe: stufe, refFertig: _ref != null),
          const SizedBox(height: 12),
          if (stufe == 1) _schritt1(scheme) else _schritt2(scheme),
          if (_fehler != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_fehler!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pumpe läuft prüfen'),
        actions: [
          IconButton(icon: const Icon(Icons.help_outline), tooltip: 'Hilfe', onPressed: _hilfe),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [inhalt, const SizedBox(height: 16)],
      ),
    );
  }

  Widget _kopf(ColorScheme scheme) => _Karte(
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Prüft vor Ort, ob eine eingebaute Umwälzpumpe wahrscheinlich in Betrieb ist.',
                style: TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 72,
              height: 64,
              child: CustomPaint(painter: _PumpePainter(scheme.primary)),
            ),
          ],
        ),
      );

  Widget _schritt1(ColorScheme scheme) {
    final messen = _phase == 'ref';
    return _Karte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SchrittTitel(1, 'Schritt 1 – Referenzmessung'),
          const SizedBox(height: 8),
          const Text(
            'Legen Sie das Handy ruhig auf einen festen Untergrund. '
            'Abstand zur Pumpe: mindestens 1 m.',
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: CustomPaint(
              painter: _AbstandPainter(scheme.primary),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 8),
          _Chip(Icons.timer_outlined, 'Messdauer: $_refSek Sekunden'),
          const SizedBox(height: 10),
          if (messen)
            _Fortschritt(verstrichenMs: _verstrichenMs, sek: _refSek)
          else
            FilledButton.icon(
              onPressed: () => _start('ref'),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Referenz messen ($_refSek s)'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          const SizedBox(height: 10),
          const _Tipp(
            'Die Referenzmessung sollte an einem ruhigen Ort ohne Vibrationen erfolgen '
            '(z. B. Tisch, Regal oder Boden).',
          ),
        ],
      ),
    );
  }

  Widget _schritt2(ColorScheme scheme) {
    final messen = _phase == 'probe';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Karte(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SchrittTitel(2, 'Schritt 2 – Messung an der Pumpe'),
              const SizedBox(height: 8),
              const Text(
                'Handy fest und ruhig an das Pumpengehäuse oder den Motor halten. '
                'Während der Messung nicht bewegen.',
              ),
              const SizedBox(height: 8),
              _Chip(Icons.timer_outlined, 'Messdauer: $_probeSek Sekunden'),
              const SizedBox(height: 10),
              if (messen)
                _Fortschritt(verstrichenMs: _verstrichenMs, sek: _probeSek)
              else ...[
                FilledButton.icon(
                  onPressed: () => _start('probe'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('An der Pumpe messen ($_probeSek s)'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
                TextButton.icon(
                  onPressed: _neu,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Referenz wiederholen'),
                ),
              ],
            ],
          ),
        ),
        if (messen) ...[const SizedBox(height: 12), _liveKarte(scheme)],
      ],
    );
  }

  Widget _liveKarte(ColorScheme scheme) => _Karte(
        child: StreamBuilder<int>(
          stream: Stream.periodic(const Duration(milliseconds: 150), (i) => i),
          builder: (c, _) {
            List<double> tail(List<double> l) => l.length > 100 ? l.sublist(l.length - 100) : l;
            final vib = schwankungRms(tail(_acc)) * 1000;
            final mag = schwankungRms(tail(_mag));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Titel(Icons.speed, 'Live-Messwerte'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _Messwert(Icons.vibration, 'Vibration', _z(vib), 'mm/s²')),
                    const SizedBox(width: 8),
                    Expanded(child: _Messwert(Icons.explore_outlined, 'Magnetfeld', _z(mag, 2), 'µT')),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Vibrationssignal (Live)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                SizedBox(
                  height: 120,
                  child: CustomPaint(
                    painter: _SignalPainter(List.of(_live), scheme.primary, Theme.of(context).brightness),
                    size: Size.infinite,
                  ),
                ),
                const Center(child: Text('Zeit (s)', style: TextStyle(fontSize: 12))),
              ],
            );
          },
        ),
      );

  Widget _ergebnisSeite(LaufErgebnis e, LaufMessung ref, LaufMessung p) {
    final scheme = Theme.of(context).colorScheme;
    final (farbe, icon, titel, untertitel, text) = switch (e.status) {
      LaufStatus.laeuft => (
          Colors.green.shade700,
          Icons.check_circle,
          'Pumpe läuft',
          'Betrieb erkannt',
          'Die Messwerte an der Pumpe unterscheiden sich deutlich von der Referenzmessung. '
              'Die Sensoren erkennen Hinweise auf laufenden Pumpenbetrieb.'
        ),
      LaufStatus.steht => (
          Colors.red.shade700,
          Icons.cancel,
          'Pumpe steht',
          'Kein Betrieb erkannt',
          'Die Messwerte an der Pumpe liegen nicht über der Referenz. '
              'Voraussetzung: Das Handy hatte festen Kontakt zur Pumpe.'
        ),
      LaufStatus.unklar => (
          Colors.orange.shade800,
          Icons.help,
          'Kein eindeutiger Pumpenbetrieb erkannt',
          'Messung wiederholen',
          e.grund
        ),
    };
    String diff(double? r) => r == null ? '–' : '${r >= 1 ? '+' : ''}${_z((r - 1) * 100, 0)} %';
    Widget pfeil(double? r) {
      if (r == null) return const SizedBox();
      if (r > 1.1) return Icon(Icons.arrow_upward, color: Colors.green.shade700);
      if (r < 0.9) return Icon(Icons.arrow_downward, color: Colors.red.shade700);
      return const Icon(Icons.arrow_forward, color: Colors.grey);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: farbe.withOpacity(0.10),
            border: Border.all(color: farbe.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PUMPENSTATUS',
                  style: TextStyle(color: farbe, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(icon, color: farbe, size: 52),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titel,
                            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: farbe)),
                        Text(untertitel, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  SizedBox(width: 56, height: 50, child: CustomPaint(painter: _PumpePainter(scheme.primary))),
                ],
              ),
              const SizedBox(height: 8),
              Text(text),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Karte(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Titel(Icons.compare_arrows, 'Messwerte im Vergleich'),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _Vergleich('Referenz (Schritt 1)', ref, scheme.primary)),
                  const SizedBox(width: 8),
                  Expanded(child: _Vergleich('An der Pumpe (Schritt 2)', p, farbe)),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Differenz zur Referenz', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: _Diff('Vibration', diff(e.verhaeltnisAcc), pfeil(e.verhaeltnisAcc))),
                        Expanded(child: _Diff('Magnetfeld', diff(e.verhaeltnisMag), pfeil(e.verhaeltnisMag))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Karte(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Titel(Icons.signal_cellular_alt, 'Signalqualität (Abtastrate)'),
              const SizedBox(height: 8),
              _Guete('Vibrationssignal', signalGuete(p.rateAcc)),
              const SizedBox(height: 6),
              _Guete('Magnetfeldsignal', signalGuete(p.rateMag)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => setState(() {
                  _probe = null;
                  _erg = null;
                }),
                icon: const Icon(Icons.refresh),
                label: const Text('Erneut messen'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _neu,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              child: const Text('Neue Referenz'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Aufklapp(Icons.analytics_outlined, 'Vibrationsanalyse (an der Pumpe)', [
          _Zeile('Signalamplitude (RMS)', '${_z(p.accRms * 1000)} mm/s²'),
          _Zeile('Schwankungsbreite (Spitze–Spitze)', '${_z(p.accSpitze * 1000)} mm/s²'),
          _Zeile('Abtastrate Vibration', '${_z(p.rateAcc, 0)} Hz'),
          const SizedBox(height: 6),
          SizedBox(
            height: 110,
            child: CustomPaint(
              painter: _SignalPainter(
                  [for (final v in p.acc.length > 300 ? p.acc.sublist(p.acc.length - 300) : p.acc) v * 1000],
                  scheme.primary,
                  Theme.of(context).brightness),
              size: Size.infinite,
            ),
          ),
          const Center(child: Text('Signalverlauf / Zeit (s)', style: TextStyle(fontSize: 12))),
        ]),
        _Aufklapp(Icons.fact_check_outlined, 'Messdetails', [
          const Text('Referenz (Schritt 1)', style: TextStyle(fontWeight: FontWeight.w700)),
          _Zeile('Vibration', '${_z(ref.accRms * 1000)} mm/s²'),
          _Zeile('Magnetfeld', '${_z(ref.magRms, 2)} µT'),
          _Zeile('Messwerte (Vib. / Magnet.)', '${ref.acc.length} / ${ref.mag.length}'),
          const SizedBox(height: 6),
          const Text('An der Pumpe (Schritt 2)', style: TextStyle(fontWeight: FontWeight.w700)),
          _Zeile('Vibration', '${_z(p.accRms * 1000)} mm/s²'),
          _Zeile('Magnetfeld', '${_z(p.magRms, 2)} µT'),
          _Zeile('Messwerte (Vib. / Magnet.)', '${p.acc.length} / ${p.mag.length}'),
          _Zeile('Messdauer', '${_z(p.dauerMs / 1000)} s'),
        ]),
        _Aufklapp(Icons.info_outline, 'Hinweis zur Messung', [const Text(_kHinweis)]),
      ],
    );
  }
}

// ───────── Bausteine ─────────

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

class _Titel extends StatelessWidget {
  const _Titel(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
        ],
      );
}

class _SchrittTitel extends StatelessWidget {
  const _SchrittTitel(this.nr, this.text);
  final int nr;
  final String text;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: c,
          child: Text('$nr', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: c.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: c, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Tipp extends StatelessWidget {
  const _Tipp(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: c.withOpacity(0.07), borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 20, color: c),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: 'Tipp\n', style: TextStyle(color: c, fontWeight: FontWeight.w800)),
              TextSpan(text: text),
            ])),
          ),
        ],
      ),
    );
  }
}

class _Fortschritt extends StatelessWidget {
  const _Fortschritt({required this.verstrichenMs, required this.sek});
  final int verstrichenMs;
  final int sek;
  @override
  Widget build(BuildContext context) {
    final rest = math.max(0, sek - (verstrichenMs / 1000).floor());
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text('Messung läuft … $rest s', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: (verstrichenMs / (sek * 1000)).clamp(0.0, 1.0),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.stufe, required this.refFertig});
  final int stufe;
  final bool refFertig;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    Widget punkt(int nr, bool aktiv, bool fertig) => CircleAvatar(
          radius: 17,
          backgroundColor: (aktiv || fertig) ? c : Colors.grey.shade400,
          child: fertig
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : Text('0$nr', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        );
    return _Karte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Messung in 2 Schritten', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          Row(
            children: [
              punkt(1, stufe == 1, refFertig && stufe == 2),
              Expanded(child: Container(height: 3, color: stufe == 2 ? c : Colors.grey.shade400)),
              punkt(2, stufe == 2, false),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Referenz', style: TextStyle(fontWeight: stufe == 1 ? FontWeight.w700 : FontWeight.w500)),
              Text('An der Pumpe', style: TextStyle(fontWeight: stufe == 2 ? FontWeight.w700 : FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Messwert extends StatelessWidget {
  const _Messwert(this.icon, this.label, this.wert, this.einheit);
  final IconData icon;
  final String label;
  final String wert;
  final String einheit;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 20, backgroundColor: c.withOpacity(0.12), child: Icon(icon, color: c)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12)),
                Text(wert, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                Text(einheit, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Vergleich extends StatelessWidget {
  const _Vergleich(this.titel, this.m, this.farbe);
  final String titel;
  final LaufMessung m;
  final Color farbe;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: farbe.withOpacity(0.08),
          border: Border.all(color: farbe.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titel, style: TextStyle(color: farbe, fontWeight: FontWeight.w700, fontSize: 12.5)),
            const SizedBox(height: 6),
            const Text('Vibration', style: TextStyle(fontSize: 12)),
            Text('${_z(m.accRms * 1000)} mm/s²', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 6),
            const Text('Magnetfeld', style: TextStyle(fontSize: 12)),
            Text('${_z(m.magRms, 2)} µT', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
      );
}

class _Diff extends StatelessWidget {
  const _Diff(this.label, this.wert, this.pfeil);
  final String label;
  final String wert;
  final Widget pfeil;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              Text(wert, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          const SizedBox(width: 6),
          pfeil,
        ],
      );
}

class _Guete extends StatelessWidget {
  const _Guete(this.label, this.g);
  final String label;
  final SignalGuete g;
  @override
  Widget build(BuildContext context) {
    final (balken, farbe, text) = switch (g) {
      SignalGuete.gut => (6, Colors.green.shade700, 'Gut'),
      SignalGuete.mittel => (4, Colors.orange.shade700, 'Mittel'),
      SignalGuete.schwach => (2, Colors.red.shade700, 'Schwach'),
    };
    return Row(
      children: [
        SizedBox(width: 130, child: Text(label)),
        for (var i = 0; i < 6; i++)
          Container(
            width: 16,
            height: 12,
            margin: const EdgeInsets.only(right: 3),
            color: i < balken ? farbe : Colors.grey.shade300,
          ),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: farbe, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _Aufklapp extends StatelessWidget {
  const _Aufklapp(this.icon, this.titel, this.kinder);
  final IconData icon;
  final String titel;
  final List<Widget> kinder;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
              title: Text(titel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
              children: kinder,
            ),
          ),
        ),
      );
}

class _Zeile extends StatelessWidget {
  const _Zeile(this.l, this.r);
  final String l;
  final String r;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(l)),
            Text(r, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

// ───────── Zeichnungen (eigene Skizzen, keine Herstellerfotos) ─────────

class _PumpePainter extends CustomPainter {
  _PumpePainter(this.farbe);
  final Color farbe;
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final body = Paint()..color = farbe;
    final dunkel = Paint()..color = Color.lerp(farbe, Colors.black, 0.55)!;
    final hell = Paint()..color = Colors.white.withOpacity(0.85);
    // Anschlüsse
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, h * 0.50, w * 0.16, h * 0.20), const Radius.circular(2)),
        dunkel);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.22, 0, w * 0.18, h * 0.16), const Radius.circular(2)),
        dunkel);
    // Pumpengehäuse
    canvas.drawCircle(Offset(w * 0.38, h * 0.60), h * 0.34, body);
    canvas.drawCircle(Offset(w * 0.38, h * 0.60), h * 0.15, hell);
    canvas.drawCircle(Offset(w * 0.38, h * 0.60), h * 0.06, body);
    // Motor
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.62, h * 0.22, w * 0.36, h * 0.76), const Radius.circular(6)),
        dunkel);
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(Rect.fromLTWH(w * 0.67, h * (0.34 + i * 0.16), w * 0.26, h * 0.04), hell);
    }
  }

  @override
  bool shouldRepaint(covariant _PumpePainter old) => old.farbe != farbe;
}

class _AbstandPainter extends CustomPainter {
  _AbstandPainter(this.farbe);
  final Color farbe;
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    // Tisch
    canvas.drawRect(Rect.fromLTWH(0, h * 0.78, w, h * 0.10), Paint()..color = Colors.brown.shade300);
    // Handy (liegend)
    final handy = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.62, w * 0.24, h * 0.16), const Radius.circular(5));
    canvas.drawRRect(handy, Paint()..color = const Color(0xFF263238));
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.07, h * 0.645, w * 0.20, h * 0.11), const Radius.circular(3)),
        Paint()..color = farbe.withOpacity(0.55));
    // Pumpe (Skizze)
    canvas.save();
    canvas.translate(w * 0.76, h * 0.30);
    _PumpePainter(Colors.blueGrey).paint(canvas, Size(w * 0.20, h * 0.50));
    canvas.restore();
    // Bemaßung
    final y = h * 0.40;
    final x0 = w * 0.30, x1 = w * 0.72;
    final linie = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.6;
    for (var x = x0; x < x1 - 6; x += 10) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 5, x1 - 6), y), linie);
    }
    canvas.drawLine(Offset(x0, y - 7), Offset(x0, y + 7), linie);
    final pf = Path()
      ..moveTo(x1, y)
      ..lineTo(x1 - 8, y - 5)
      ..lineTo(x1 - 8, y + 5)
      ..close();
    canvas.drawPath(pf, Paint()..color = Colors.black87);
    final tp = TextPainter(
      text: const TextSpan(text: '≥ 1 m', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((x0 + x1) / 2 - tp.width / 2, y - 24));
  }

  @override
  bool shouldRepaint(covariant _AbstandPainter old) => old.farbe != farbe;
}

class _SignalPainter extends CustomPainter {
  _SignalPainter(this.v, this.farbe, this.helligkeit);
  final List<double> v;
  final Color farbe;
  final Brightness helligkeit;

  @override
  void paint(Canvas canvas, Size s) {
    const links = 40.0, unten = 4.0, oben = 6.0;
    final bw = s.width - links;
    final bh = s.height - unten - oben;
    final text = helligkeit == Brightness.dark ? Colors.white70 : Colors.black54;
    canvas.drawRect(Rect.fromLTWH(links, oben, bw, bh), Paint()..color = farbe.withOpacity(0.06));
    var hi = 1.0, lo = 0.0;
    if (v.length >= 2) {
      hi = v.reduce(math.max);
      lo = math.min(0.0, v.reduce(math.min));
    }
    final span = math.max(hi - lo, 1.0);
    final grid = Paint()
      ..color = text.withOpacity(0.25)
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = oben + bh * i / 3;
      canvas.drawLine(Offset(links, y), Offset(s.width, y), grid);
      final wert = hi - span * i / 3;
      final tp = TextPainter(
        text: TextSpan(text: wert.toStringAsFixed(0), style: TextStyle(fontSize: 10, color: text)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(links - tp.width - 4, y - tp.height / 2));
    }
    if (v.length < 2) return;
    final path = Path();
    for (var i = 0; i < v.length; i++) {
      final x = links + bw * i / 299;
      final y = oben + bh - (v[i] - lo) / span * bh;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = farbe
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
  }

  @override
  bool shouldRepaint(covariant _SignalPainter old) => true;
}
