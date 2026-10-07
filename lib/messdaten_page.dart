import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:share_plus/share_plus.dart';

import 'messdaten_logik.dart';

const _kAppKennung = 'WerkCalc 0.9.0 (Testaufzeichnung v09x)';
const _kDauerSek = 10;

/// Testwerkzeug: nimmt Beschleunigungs-Rohwerte und Mikrofon-Spektren auf und gibt sie als Datei
/// zum Teilen aus. Keine Erkennung, kein Audio gespeichert.
class MessdatenPage extends StatefulWidget {
  const MessdatenPage({super.key});

  @override
  State<MessdatenPage> createState() => _MessdatenPageState();
}

class _MessdatenPageState extends State<MessdatenPage> {
  String _szenario = kMessSzenarien.first;
  final _notiz = TextEditingController();
  bool _laeuft = false;
  int _ms = 0;
  String? _meldung;
  String? _datei;
  String? _json;
  String? _zusammenfassung;

  @override
  void dispose() {
    _notiz.dispose();
    super.dispose();
  }

  Future<void> _aufnehmen() async {
    setState(() {
      _laeuft = true;
      _ms = 0;
      _meldung = null;
      _datei = null;
      _json = null;
      _zusammenfassung = null;
    });
    final acc = AccAufnahme();
    final mik = MikroAnalysator();
    final uhr = Stopwatch();
    AudioRecorder? rec;
    StreamSubscription<Uint8List>? sm;
    StreamSubscription<AccelerometerEvent>? sa;
    var mikStatus = 'nicht gestartet';
    try {
      rec = AudioRecorder();
      if (await rec.hasPermission()) {
        final stream = await rec.startStream(const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          autoGain: false,
          echoCancel: false,
          noiseSuppress: false,
        ));
        sm = stream.listen((b) => mik.addPcm16(b));
        mikStatus = 'ok';
      } else {
        mikStatus = 'Mikrofon-Berechtigung verweigert – nur Beschleunigungssensor aufgenommen';
      }
    } catch (e) {
      mikStatus = 'Mikrofon-Fehler: $e';
    }
    uhr.start();
    DateTime? t0;
    double off = 0;
    sa = accelerometerEventStream(samplingPeriod: const Duration(milliseconds: 5)).listen((e) {
      if (t0 == null) {
        t0 = e.timestamp;
        off = uhr.elapsedMicroseconds / 1e6;
      }
      acc.add(off + e.timestamp.difference(t0!).inMicroseconds / 1e6, e.x, e.y, e.z);
    }, onError: (_) {});
    final ende = DateTime.now().add(const Duration(seconds: _kDauerSek));
    while (DateTime.now().isBefore(ende)) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) break;
      setState(() => _ms = uhr.elapsedMilliseconds);
    }
    final dauer = uhr.elapsedMicroseconds / 1e6;
    await sa.cancel();
    await sm?.cancel();
    try {
      await rec?.stop();
      await rec?.dispose();
    } catch (_) {}
    if (!mounted) return;
    final jetzt = DateTime.now();
    final json = messdatenJson(
      szenario: _szenario,
      notiz: _notiz.text.trim(),
      zeit: jetzt,
      dauerSek: dauer,
      acc: acc,
      mikro: mikStatus == 'ok' ? mik : null,
      mikroStatus: mikStatus,
      app: _kAppKennung,
    );
    setState(() {
      _laeuft = false;
      _json = json;
      _datei = messDateiname(_szenario, jetzt);
      _zusammenfassung = 'Beschleunigung: ${acc.t.length} Werte, ${acc.fsMittel.toStringAsFixed(0)} Hz\n'
          'Mikrofon: ${mikStatus == 'ok' ? '${mik.zeiten.length} Spektren (kein Audio gespeichert)' : mikStatus}\n'
          'Größe: ${(json.length / 1024).toStringAsFixed(0)} KB';
    });
  }

  Future<void> _teilen() async {
    final json = _json, name = _datei;
    if (json == null || name == null) return;
    try {
      await Share.shareXFiles(
        [XFile.fromData(Uint8List.fromList(utf8.encode(json)), mimeType: 'application/json', name: name)],
        fileNameOverrides: [name],
        subject: name,
      );
    } catch (e) {
      if (mounted) setState(() => _meldung = 'Teilen nicht möglich: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messdaten aufzeichnen (Test)')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text('Testwerkzeug zum Sammeln echter Pumpensignale. Es erkennt nichts und bewertet nichts. '
                    'Aufgenommen werden Beschleunigungs-Rohwerte (mit Zeitstempeln) und Mikrofon-Spektren. '
                    'Es wird kein Audio gespeichert. Die Datei verlässt das Handy nur, wenn du sie selbst teilst.'),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _szenario,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Messung', border: OutlineInputBorder()),
              items: [for (final s in kMessSzenarien) DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))],
              onChanged: _laeuft ? null : (v) => setState(() => _szenario = v ?? _szenario),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notiz,
              enabled: !_laeuft,
              decoration: const InputDecoration(
                labelText: 'Notiz (z. B. Position, Pumpenstufe, Raum)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_laeuft) ...[
              LinearProgressIndicator(value: (_ms / (_kDauerSek * 1000)).clamp(0.0, 1.0)),
              const SizedBox(height: 8),
              Text('Aufnahme läuft … ${(_ms / 1000).toStringAsFixed(1)} / $_kDauerSek s – Handy ruhig halten'),
            ] else
              FilledButton.icon(
                onPressed: _aufnehmen,
                icon: const Icon(Icons.fiber_manual_record),
                label: const Text('$_kDauerSek Sekunden aufnehmen'),
              ),
            if (_zusammenfassung != null) ...[
              const SizedBox(height: 16),
              Card(child: Padding(padding: const EdgeInsets.all(14), child: Text('$_datei\n\n$_zusammenfassung'))),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(onPressed: _teilen, icon: const Icon(Icons.share), label: const Text('Datei teilen / senden')),
            ],
            if (_meldung != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_meldung!)),
          ],
        ),
      ),
    );
  }
}
