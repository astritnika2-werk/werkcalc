import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'datensicherung.dart';
import 'logic.dart' show formatDatum;
import 'materialliste_store.dart';

/// Datensicherung: Export und Wiederherstellen der Baustellen und Materiallisten.
class DatensicherungPage extends StatefulWidget {
  const DatensicherungPage({super.key});

  @override
  State<DatensicherungPage> createState() => _DatensicherungPageState();
}

class _DatensicherungPageState extends State<DatensicherungPage> {
  final _store = MaterialListenStore.instance;
  bool _busy = false;
  late Future<({Sicherung? auto, Sicherung? vorAenderung})> _lokal = _store.lokaleSicherungen();

  void _neuLaden() => setState(() => _lokal = _store.lokaleSicherungen());

  void _meldung(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _fehlerDialog(String titel, String text) {
    return showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(titel),
        content: Text(text),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
      ),
    );
  }

  Future<bool> _frage(String titel, String text, String ok) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(titel),
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(ok)),
        ],
      ),
    );
    return r == true;
  }

  Future<void> _teilen(String text, String name, String betreff) async {
    try {
      await Share.shareXFiles(
        [XFile.fromData(Uint8List.fromList(utf8.encode(text)), mimeType: 'application/json', name: name)],
        fileNameOverrides: [name],
        subject: betreff,
      );
    } catch (_) {
      _meldung('Teilen ist auf diesem Gerät nicht möglich.');
    }
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final text = await _store.sicherungText();
      await _teilen(text, sicherungDateiname(DateTime.now()), 'WerkCalc Datensicherung');
    } catch (_) {
      _meldung('Die Sicherung konnte nicht erstellt werden.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _beschreibung(Sicherung s) =>
      '${s.listen.length} Baustellen mit ${s.anzahlPositionen} Positionen'
      '${s.materialkosten == null ? '' : ', ${s.materialkosten!.length} Materialkosten-Positionen'}';

  /// Text der Sicherung eingeben/einfügen (aus der Zwischenablage).
  Future<String?> _textEingabe() {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sicherungstext einfügen'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text(
              'Öffnen Sie die gespeicherte Sicherungsdatei in einer Text-App, kopieren Sie den ganzen Inhalt '
              'und fügen Sie ihn hier ein.',
            ),
            const SizedBox(height: 10),
            TextField(
              controller: c,
              maxLines: 6,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '{"format":"werkcalc-datensicherung", …'),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final d = await Clipboard.getData(Clipboard.kTextPlain);
                  if (d?.text != null) c.text = d!.text!;
                },
                icon: const Icon(Icons.content_paste),
                label: const Text('Aus Zwischenablage einfügen'),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Prüfen')),
        ],
      ),
    );
  }

  Future<void> _kopieren() async {
    setState(() => _busy = true);
    try {
      final text = await _store.sicherungText();
      await Clipboard.setData(ClipboardData(text: text));
      _meldung('Sicherungstext kopiert. In einer Notiz-App oder Nachricht einfügen und sicher aufbewahren.');
    } catch (_) {
      _meldung('Die Sicherung konnte nicht erstellt werden.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _ausText() async {
    final text = await _textEingabe();
    if (text == null || !mounted) return;
    if (text.length > kSicherungMaxZeichen) {
      await _fehlerDialog('Text zu groß', 'Das ist keine WerkCalc-Sicherung (Text zu groß). Ihre Daten wurden nicht verändert.');
      return;
    }
    final pr = pruefeSicherung(text);
    if (!pr.ok) {
      await _fehlerDialog('Wiederherstellen nicht möglich', '${pr.fehler}\n\nIhre Daten wurden nicht verändert.');
      return;
    }
    final s = pr.sicherung!;
    final ja = await _frage(
      'Aus Sicherung wiederherstellen?',
      'Die Sicherung enthält ${_beschreibung(s)}'
      '${s.erstellt.millisecondsSinceEpoch > 0 ? ' (erstellt am ${formatDatum(s.erstellt)})' : ''}.\n\n'
      'Die aktuellen Baustellen und Materiallisten werden dadurch ersetzt. '
      'Der Stand davor wird als lokale Sicherung festgehalten.',
      'Wiederherstellen',
    );
    if (!ja) return;
    setState(() => _busy = true);
    final fehler = await _store.wiederherstellen(text);
    if (!mounted) return;
    setState(() => _busy = false);
    _neuLaden();
    if (fehler != null) {
      await _fehlerDialog('Wiederherstellen fehlgeschlagen', fehler);
    } else {
      _meldung('Wiederhergestellt: ${_beschreibung(s)}');
    }
  }

  Future<void> _lokalWiederherstellen(Sicherung s, bool vorAenderung) async {
    final ja = await _frage(
      'Lokale Sicherung wiederherstellen?',
      '${_beschreibung(s)}.\n\nDie aktuellen Daten werden ersetzt; ihr Stand wird als lokale Sicherung festgehalten.',
      'Wiederherstellen',
    );
    if (!ja) return;
    setState(() => _busy = true);
    final fehler = await _store.ausLokalerSicherung(vorAenderung: vorAenderung);
    if (!mounted) return;
    setState(() => _busy = false);
    _neuLaden();
    if (fehler != null) {
      await _fehlerDialog('Wiederherstellen fehlgeschlagen', fehler);
    } else {
      _meldung('Wiederhergestellt: ${_beschreibung(s)}');
    }
  }

  Future<void> _defekteTeilen() async {
    final text = await _store.defekteDatenText();
    if (text == null) {
      _meldung('Keine beschädigten Daten gespeichert.');
      return;
    }
    await _teilen(text, 'werkcalc-defekte-daten.json', 'WerkCalc beschädigte Daten');
  }

  Future<void> _neuBeginnen() async {
    final ja = await _frage(
      'Mit dem lesbaren Rest weiterarbeiten?',
      'Nicht lesbare Einträge werden nicht übernommen. Die beschädigten Rohdaten bleiben als Kopie auf dem Gerät erhalten '
      '(unten „Beschädigte Daten teilen“).',
      'Weiterarbeiten',
    );
    if (!ja) return;
    await _store.neuBeginnen();
    _neuLaden();
  }

  Widget _lokaleZeile(String titel, Sicherung? s, bool vor) {
    if (s == null) {
      return ListTile(
        leading: const Icon(Icons.history),
        title: Text(titel),
        subtitle: const Text('Noch keine vorhanden'),
      );
    }
    final wann = s.erstellt.millisecondsSinceEpoch > 0 ? formatDatum(s.erstellt) : 'Datum unbekannt';
    return ListTile(
      leading: const Icon(Icons.history),
      title: Text(titel),
      subtitle: Text('$wann · ${_beschreibung(s)}'),
      trailing: TextButton(
        onPressed: _busy ? null : () => _lokalWiederherstellen(s, vor),
        child: const Text('Wiederherstellen'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datensicherung')),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_store.problem != null)
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_store.problem!, style: const TextStyle(fontSize: 16)),
                      if (_store.datenBeschaedigt) ...[
                        const SizedBox(height: 10),
                        Wrap(spacing: 8, children: [
                          OutlinedButton(onPressed: _busy ? null : _neuBeginnen, child: const Text('Mit lesbarem Rest weiterarbeiten')),
                          OutlinedButton(onPressed: _defekteTeilen, child: const Text('Beschädigte Daten teilen')),
                        ]),
                      ],
                    ],
                  ),
                ),
              ),
            const Text(
              'Die Sicherung enthält alle Baustellen und Materiallisten, eigene und zuletzt verwendete Artikel '
              'und die Liste der Materialkosten. Sie ist eine Datei (oder ein Text), die Sie selbst speichern oder weitergeben. '
              'WerkCalc sendet nichts ins Internet.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _export,
              icon: const Icon(Icons.upload_file),
              label: const Text('Sicherung exportieren'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy ? null : _kopieren,
              icon: const Icon(Icons.copy),
              label: const Text('Sicherungstext kopieren'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy ? null : _ausText,
              icon: const Icon(Icons.download),
              label: const Text('Aus Sicherungstext wiederherstellen'),
            ),
            const SizedBox(height: 24),
            Text('Lokale Sicherungen auf dem Gerät', style: Theme.of(context).textTheme.titleMedium),
            FutureBuilder<({Sicherung? auto, Sicherung? vorAenderung})>(
              future: _lokal,
              builder: (context, snap) {
                final d = snap.data;
                if (d == null) return const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator());
                return Column(children: [
                  _lokaleZeile('Beim letzten Start', d.auto, false),
                  _lokaleZeile('Vor der letzten größeren Änderung', d.vorAenderung, true),
                ]);
              },
            ),
            const Text(
              'Lokale Sicherungen liegen im App-Speicher und werden beim Deinstallieren der App gelöscht. '
              'Für echten Schutz die Sicherung exportieren und an einem sicheren Ort ablegen.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
