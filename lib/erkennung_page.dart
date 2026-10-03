import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'erkennung.dart';
import 'materialliste.dart';
import 'materialliste_pages.dart' show zeigeMengeDialog;
import 'materialliste_store.dart';

// ─────────────────────── Foto → Text (offline, auf dem Gerät) ───────────────────────

Future<void> starteScan(BuildContext context, String baustelleId) async {
  final quelle = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Foto aufnehmen'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Aus Galerie wählen'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (quelle == null || !context.mounted) return;
  String text = '';
  try {
    final bild = await ImagePicker().pickImage(source: quelle, imageQuality: 90);
    if (bild == null || !context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Text wird gelesen …'),
          ],
        ),
      ),
    );
    final erkenner = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final r = await erkenner.processImage(InputImage.fromFilePath(bild.path));
      text = r.text;
    } finally {
      await erkenner.close();
    }
  } catch (_) {
    text = '';
  }
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop(); // Lade-Dialog
  if (text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kein Text erkannt. Bitte näher und gerade fotografieren.')),
    );
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ErkennungPage(baustelleId: baustelleId, text: text, quelle: 'Foto'),
    ),
  );
}

// ─────────────────────── Sprache → Text ───────────────────────

Future<void> starteSprache(BuildContext context, String baustelleId) async {
  final text = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _SprachDialog(),
  );
  if (text == null || text.trim().isEmpty || !context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ErkennungPage(baustelleId: baustelleId, text: text, quelle: 'Sprache'),
    ),
  );
}

class _SprachDialog extends StatefulWidget {
  const _SprachDialog();

  @override
  State<_SprachDialog> createState() => _SprachDialogState();
}

class _SprachDialogState extends State<_SprachDialog> {
  final _stt = SpeechToText();
  String _text = '';
  String _status = 'Mikrofon wird gestartet …';
  bool _hoert = false;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    bool ok = false;
    try {
      ok = await _stt.initialize(
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _hoert = false;
            _status = 'Fehler: ${e.errorMsg}. Mikrofon erlaubt?';
          });
        },
        onStatus: (s) {
          if (!mounted) return;
          if (s == 'done' || s == 'notListening') {
            setState(() {
              _hoert = false;
              if (_text.isNotEmpty) _status = 'Fertig? Dann „Übernehmen“.';
            });
          }
        },
      );
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    if (!ok) {
      setState(() => _status = 'Spracheingabe nicht verfügbar (Mikrofon-Erlaubnis?).');
      return;
    }
    await _hoeren();
  }

  Future<void> _hoeren() async {
    setState(() {
      _hoert = true;
      _status = 'Sprich jetzt …';
    });
    await _stt.listen(
      localeId: 'de_DE',
      listenFor: const Duration(seconds: 90),
      pauseFor: const Duration(seconds: 6),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
      onResult: (r) {
        if (!mounted) return;
        setState(() => _text = r.recognizedWords);
      },
    );
  }

  @override
  void dispose() {
    _stt.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.mic, color: _hoert ? Colors.red : null),
          const SizedBox(width: 8),
          const Expanded(child: Text('Sprache')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_status, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 80),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _text.isEmpty ? 'z. B. „20 Meter Kupferrohr 22, 12 Bogen 90 Grad I/I, 8 Muffen 22“' : _text,
              style: TextStyle(fontSize: 17, color: _text.isEmpty ? Colors.black45 : null),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        if (!_hoert)
          TextButton(onPressed: _hoeren, child: const Text('Nochmal')),
        FilledButton(
          onPressed: _text.trim().isEmpty
              ? null
              : () async {
                  await _stt.stop();
                  if (context.mounted) Navigator.pop(context, _text);
                },
          child: const Text('Übernehmen'),
        ),
      ],
    );
  }
}

// ─────────────────────── Erkannt – bitte prüfen ───────────────────────

class ErkennungPage extends StatefulWidget {
  const ErkennungPage({
    super.key,
    required this.baustelleId,
    required this.text,
    required this.quelle,
  });

  final String baustelleId;
  final String text;
  final String quelle;

  @override
  State<ErkennungPage> createState() => _ErkennungPageState();
}

class _ErkennungPageState extends State<ErkennungPage> {
  final _store = MaterialListenStore.instance;
  late final TextEditingController _c = TextEditingController(text: widget.text);
  List<ErkanntePosition> _pos = [];
  Timer? _warte;

  @override
  void initState() {
    super.initState();
    _pos = erkenneText(widget.text, _store.katalog);
  }

  @override
  void dispose() {
    _warte?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _textGeaendert(String t) {
    _warte?.cancel();
    _warte = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _pos = erkenneText(t, _store.katalog));
    });
  }

  int get _anzahl => _pos.where((p) => p.aktiv && p.gewaehlt != null).length;

  Future<void> _waehleArtikel(ErkanntePosition p) async {
    final a = await showModalBottomSheet<KatalogArtikel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ArtikelWahl(start: p.suche, vorschlaege: p.treffer),
    );
    if (a == null) return;
    setState(() {
      p.gewaehlt = a;
      p.einheit = a.einheit;
      p.aktiv = true;
    });
  }

  Future<void> _menge(ErkanntePosition p) async {
    final r = await zeigeMengeDialog(
      context,
      name: p.gewaehlt?.name ?? p.suche,
      menge: p.menge,
      einheit: p.einheit,
      ok: 'Übernehmen',
    );
    if (r == null) return;
    setState(() {
      p.menge = r.menge;
      p.einheit = r.einheit;
    });
  }

  Future<void> _hinzufuegen() async {
    var n = 0;
    for (final p in _pos) {
      final a = p.gewaehlt;
      if (!p.aktiv || a == null) continue;
      await _store.hinzufuegen(widget.baustelleId, name: a.name, menge: p.menge, einheit: p.einheit);
      n++;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$n Positionen zur Liste hinzugefügt')),
    );
  }

  Color _farbe(Sicherheit s) => switch (s) {
        Sicherheit.sicher => Colors.green.shade700,
        Sicherheit.mehrere => Colors.orange.shade800,
        Sicherheit.keiner => Colors.red.shade700,
      };

  String _hinweis(ErkanntePosition p) => switch (p.sicherheit) {
        Sicherheit.sicher => 'Gefunden',
        Sicherheit.mehrere => 'Mehrere Treffer – bitte prüfen',
        Sicherheit.keiner => 'Nicht im Katalog – bitte suchen',
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('Erkannt – bitte prüfen (${widget.quelle})')),
      body: Column(
        children: [
          ExpansionTile(
            title: const Text('Erkannter Text (bearbeiten)'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            children: [
              TextField(
                controller: _c,
                minLines: 3,
                maxLines: 8,
                onChanged: _textGeaendert,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  helperText: 'Eine Position pro Zeile oder mit Komma trennen.',
                ),
              ),
            ],
          ),
          Expanded(
            child: _pos.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Keine Positionen erkannt. Text oben anpassen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 17),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _pos.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = _pos[i];
                      final a = p.gewaehlt;
                      final farbe = _farbe(p.sicherheit);
                      return ListTile(
                        contentPadding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                        leading: Checkbox(
                          value: p.aktiv && a != null,
                          onChanged: a == null ? null : (v) => setState(() => p.aktiv = v ?? false),
                        ),
                        title: Text(
                          a?.name ?? '„${p.suche}“',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: a == null ? Colors.black54 : null,
                          ),
                        ),
                        subtitle: Text(
                          '${_hinweis(p)}${p.mengeAngegeben ? '' : ' · Menge 1 angenommen'}\nText: ${p.roh}',
                          style: TextStyle(fontSize: 13, color: farbe),
                        ),
                        isThreeLine: true,
                        trailing: InkWell(
                          onTap: () => _menge(p),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${formatMenge(p.menge)} ${p.einheit}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        onTap: () => _waehleArtikel(p),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.secondary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            onPressed: _anzahl == 0 ? null : _hinzufuegen,
            icon: const Icon(Icons.check),
            label: Text('$_anzahl hinzufügen'),
          ),
        ),
      ),
    );
  }
}

/// Auswahl eines KATALOG-Artikels (Vorschläge + eigene Suche).
class _ArtikelWahl extends StatefulWidget {
  const _ArtikelWahl({required this.start, required this.vorschlaege});

  final String start;
  final List<KatalogArtikel> vorschlaege;

  @override
  State<_ArtikelWahl> createState() => _ArtikelWahlState();
}

class _ArtikelWahlState extends State<_ArtikelWahl> {
  late final TextEditingController _c = TextEditingController(text: widget.start);
  late List<KatalogArtikel> _liste = widget.vorschlaege;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _suche(String t) {
    final r = sucheKatalog(t, MaterialListenStore.instance.katalog, limit: 30);
    setState(() => _liste = r.artikel);
  }

  @override
  Widget build(BuildContext context) {
    final hoehe = MediaQuery.of(context).size.height * 0.75;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: hoehe,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _c,
                onChanged: _suche,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Artikel im Katalog suchen',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: _liste.isEmpty
                  ? const Center(child: Text('Nichts gefunden.'))
                  : ListView.builder(
                      itemCount: _liste.length,
                      itemBuilder: (context, i) {
                        final a = _liste[i];
                        return ListTile(
                          title: Text(a.name),
                          subtitle: Text(a.kurzInfo),
                          onTap: () => Navigator.pop(context, a),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
