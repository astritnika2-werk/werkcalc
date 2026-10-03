import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'logic.dart';
import 'materialliste.dart';
import 'materialliste_store.dart';
import 'pdf_materialliste.dart';

// ─────────────────────────── Hilfsdialoge ───────────────────────────

Future<String?> _textDialog(
  BuildContext context, {
  required String titel,
  required String hinweis,
  String start = '',
  String ok = 'Speichern',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextDialog(titel: titel, hinweis: hinweis, start: start, ok: ok),
  );
}

class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.titel,
    required this.hinweis,
    required this.start,
    required this.ok,
  });

  final String titel;
  final String hinweis;
  final String start;
  final String ok;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final TextEditingController _c = TextEditingController(text: widget.start);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _fertig() => Navigator.of(context).pop(_c.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titel),
      content: TextField(
        controller: _c,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(fontSize: 20),
        decoration: InputDecoration(
          hintText: widget.hinweis,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _fertig(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(onPressed: _fertig, child: Text(widget.ok)),
      ],
    );
  }
}

Future<bool> _bestaetigen(
  BuildContext context, {
  required String titel,
  required String text,
  required String ok,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titel),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(ok),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Ergebnis des Mengendialogs.
class MengeEingabe {
  const MengeEingabe(this.menge, this.einheit);

  final double menge;
  final String einheit;
}

Future<MengeEingabe?> zeigeMengeDialog(
  BuildContext context, {
  required String name,
  required double menge,
  required String einheit,
  String ok = 'Hinzufügen',
}) {
  return showDialog<MengeEingabe>(
    context: context,
    builder: (_) => _MengeDialog(name: name, menge: menge, einheit: einheit, ok: ok),
  );
}

class _MengeDialog extends StatefulWidget {
  const _MengeDialog({
    required this.name,
    required this.menge,
    required this.einheit,
    required this.ok,
  });

  final String name;
  final double menge;
  final String einheit;
  final String ok;

  @override
  State<_MengeDialog> createState() => _MengeDialogState();
}

class _MengeDialogState extends State<_MengeDialog> {
  late final TextEditingController _c;
  late String _einheit;
  String? _fehler;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: formatMenge(widget.menge));
    _c.selection = TextSelection(baseOffset: 0, extentOffset: _c.text.length);
    _einheit = widget.einheit;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _fertig() {
    final m = parseNum(_c.text);
    if (m == null || m <= 0) {
      setState(() => _fehler = 'Bitte eine Menge eingeben');
      return;
    }
    Navigator.of(context).pop(MengeEingabe(m, _einheit));
  }

  @override
  Widget build(BuildContext context) {
    final schnell = _einheit == 'm'
        ? const ['1', '2', '3', '5', '10', '15', '20', '25', '30', '50']
        : const ['1', '2', '3', '4', '5', '6', '8', '10', '12', '20'];
    return AlertDialog(
      title: Text(widget.name, style: const TextStyle(fontSize: 17)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _c,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Menge',
                suffixText: _einheit,
                errorText: _fehler,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_fehler != null) setState(() => _fehler = null);
              },
              onSubmitted: (_) => _fertig(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final q in schnell)
                  ActionChip(
                    label: Text(q, style: const TextStyle(fontSize: 16)),
                    onPressed: () => setState(() {
                      _c.text = q;
                      _c.selection = TextSelection.collapsed(offset: q.length);
                      _fehler = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final e in kMaterialEinheiten)
                  ChoiceChip(
                    label: Text(e),
                    selected: _einheit == e,
                    onSelected: (_) => setState(() => _einheit = e),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(onPressed: _fertig, child: Text(widget.ok)),
      ],
    );
  }
}

// ─────────────────────────── Listenübersicht ───────────────────────────

/// Tab „Listen“: alle Baustellen mit ihren Materiallisten.
class MaterialListenTab extends StatefulWidget {
  const MaterialListenTab({super.key});

  @override
  State<MaterialListenTab> createState() => _MaterialListenTabState();
}

class _MaterialListenTabState extends State<MaterialListenTab> {
  final _store = MaterialListenStore.instance;

  @override
  void initState() {
    super.initState();
    _store.laden();
  }

  Future<void> _neu() async {
    final name = await _textDialog(
      context,
      titel: 'Neue Baustelle',
      hinweis: 'z. B. Müllerstraße',
      ok: 'Anlegen',
    );
    if (name == null || !mounted) return;
    final b = await _store.neueBaustelle(name);
    if (!mounted) return;
    _oeffne(b.id);
  }

  void _oeffne(String id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MaterialListePage(baustelleId: id)),
    );
  }

  Future<void> _menue(String wahl, Baustelle b) async {
    switch (wahl) {
      case 'umbenennen':
        final n = await _textDialog(
          context,
          titel: 'Baustelle umbenennen',
          hinweis: 'Name',
          start: b.name,
        );
        if (n != null && n.isNotEmpty) await _store.umbenennen(b.id, n);
      case 'kopieren':
        await _store.kopieren(b.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Liste kopiert')),
          );
        }
      case 'loeschen':
        final ja = await _bestaetigen(
          context,
          titel: 'Liste löschen?',
          text: '„${b.name}“ mit ${b.anzahl} Positionen wird gelöscht.',
          ok: 'Löschen',
        );
        if (ja) await _store.loeschen(b.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Materiallisten')),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final listen = _store.listen;
          if (listen.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Lege eine Baustelle an und stelle dein Material '
                  'schnell zusammen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: listen.length,
            itemBuilder: (context, i) {
              final b = listen[i];
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
                  leading: Icon(
                    b.alleErledigt ? Icons.check_circle : Icons.checklist,
                    size: 30,
                    color: b.alleErledigt
                        ? Colors.green.shade700
                        : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    b.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    b.anzahl == 0
                        ? 'Noch leer'
                        : '${b.anzahlErledigt} von ${b.anzahl} abgehakt',
                  ),
                  onTap: () => _oeffne(b.id),
                  trailing: PopupMenuButton<String>(
                    onSelected: (w) => _menue(w, b),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'umbenennen', child: Text('Umbenennen')),
                      PopupMenuItem(value: 'kopieren', child: Text('Liste kopieren')),
                      PopupMenuItem(value: 'loeschen', child: Text('Löschen')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _neu,
        icon: const Icon(Icons.add),
        label: const Text('Neue Baustelle'),
      ),
    );
  }
}

// ─────────────────────────── Listendetail ───────────────────────────

class MaterialListePage extends StatefulWidget {
  const MaterialListePage({super.key, required this.baustelleId});

  final String baustelleId;

  @override
  State<MaterialListePage> createState() => _MaterialListePageState();
}

class _MaterialListePageState extends State<MaterialListePage> {
  final _store = MaterialListenStore.instance;
  bool _busy = false;

  Baustelle? get _b => _store.finde(widget.baustelleId);

  void _meldung(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _hinzufuegen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MaterialAuswahlPage(baustelleId: widget.baustelleId),
      ),
    );
  }

  Future<void> _mengeAendern(ListenArtikel a) async {
    final r = await zeigeMengeDialog(
      context,
      name: a.name,
      menge: a.menge,
      einheit: a.einheit,
      ok: 'Speichern',
    );
    if (r == null) return;
    await _store.mengeSetzen(widget.baustelleId, a.id, r.menge, r.einheit);
  }

  Future<void> _textTeilen() async {
    final b = _b;
    if (b == null) return;
    await Share.share(listeAlsText(b), subject: 'Materialliste ${b.name}');
  }

  String _dateiname(Baustelle b) {
    final n = b.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return 'Materialliste_$n.pdf';
  }

  Future<void> _pdf({required bool teilen}) async {
    final b = _b;
    if (b == null || _busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await erzeugeMaterialListePdf(b);
      if (teilen) {
        await Printing.sharePdf(bytes: bytes, filename: _dateiname(b));
      } else {
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: _dateiname(b),
        );
      }
    } catch (_) {
      _meldung('PDF konnte nicht erstellt werden.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _menue(String wahl) async {
    final b = _b;
    if (b == null) return;
    switch (wahl) {
      case 'pdf_anzeigen':
        await _pdf(teilen: false);
      case 'alle':
        await _store.alleAbhaken(b.id, !b.alleErledigt);
      case 'entfernen':
        if (b.anzahlErledigt == 0) {
          _meldung('Nichts abgehakt.');
          return;
        }
        final ja = await _bestaetigen(
          context,
          titel: 'Abgehakte entfernen?',
          text: '${b.anzahlErledigt} abgehakte Positionen werden aus der Liste gelöscht.',
          ok: 'Entfernen',
        );
        if (ja) await _store.abgehakteEntfernen(b.id);
      case 'kopieren':
        await _store.kopieren(b.id);
        _meldung('Liste kopiert (zu finden unter „Listen“)');
      case 'umbenennen':
        final n = await _textDialog(
          context,
          titel: 'Baustelle umbenennen',
          hinweis: 'Name',
          start: b.name,
        );
        if (n != null && n.isNotEmpty) await _store.umbenennen(b.id, n);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final b = _b;
        if (b == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Materialliste')),
            body: const Center(child: Text('Liste nicht gefunden.')),
          );
        }
        final scheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: Text(b.name, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: 'Teilen (WhatsApp, E-Mail)',
                icon: const Icon(Icons.share),
                onPressed: b.anzahl == 0 ? null : _textTeilen,
              ),
              IconButton(
                tooltip: 'Als PDF',
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: b.anzahl == 0 || _busy ? null : () => _pdf(teilen: true),
              ),
              PopupMenuButton<String>(
                onSelected: _menue,
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'pdf_anzeigen', child: Text('PDF anzeigen / drucken')),
                  PopupMenuItem(
                    value: 'alle',
                    child: Text(b.alleErledigt ? 'Alle zurücksetzen' : 'Alle abhaken'),
                  ),
                  const PopupMenuItem(value: 'entfernen', child: Text('Abgehakte entfernen')),
                  const PopupMenuItem(value: 'kopieren', child: Text('Liste kopieren')),
                  const PopupMenuItem(value: 'umbenennen', child: Text('Umbenennen')),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              if (b.anzahl > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${b.anzahlErledigt} von ${b.anzahl} abgehakt',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: b.anzahl == 0 ? 0 : b.anzahlErledigt / b.anzahl,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: b.anzahl == 0
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Noch kein Material. Tippe unten auf '
                            '„Material hinzufügen“.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        itemCount: b.artikel.length,
                        itemBuilder: (context, i) {
                          final a = b.artikel[i];
                          return Dismissible(
                            key: ValueKey(a.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red.shade400,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) {
                              _store.artikelLoeschen(b.id, a.id);
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text('${a.name} gelöscht'),
                                    action: SnackBarAction(
                                      label: 'Rückgängig',
                                      onPressed: () =>
                                          _store.artikelWiederherstellen(b.id, a, i),
                                    ),
                                  ),
                                );
                            },
                            child: _ArtikelZeile(
                              artikel: a,
                              onHaken: (v) => _store.abhaken(b.id, a.id, v),
                              onMenge: (neu) =>
                                  _store.mengeSetzen(b.id, a.id, neu, a.einheit),
                              onBearbeiten: () => _mengeAendern(a),
                            ),
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
                onPressed: _hinzufuegen,
                icon: const Icon(Icons.add),
                label: const Text('Material hinzufügen'),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ArtikelZeile extends StatelessWidget {
  const _ArtikelZeile({
    required this.artikel,
    required this.onHaken,
    required this.onMenge,
    required this.onBearbeiten,
  });

  final ListenArtikel artikel;
  final ValueChanged<bool> onHaken;
  final ValueChanged<double> onMenge;
  final VoidCallback onBearbeiten;

  @override
  Widget build(BuildContext context) {
    final a = artikel;
    final grau = Colors.grey.shade600;
    return Material(
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        ),
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform.scale(
              scale: 1.25,
              child: Checkbox(
                value: a.erledigt,
                onChanged: (v) => onHaken(v ?? false),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: a.erledigt ? grau : null,
                        decoration: a.erledigt ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Weniger',
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: a.menge > 1 ? () => onMenge(a.menge - 1) : null,
                        ),
                        InkWell(
                          onTap: onBearbeiten,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Text(
                              '${formatMenge(a.menge)} ${a.einheit}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Mehr',
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => onMenge(a.menge + 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Material hinzufügen ───────────────────────────

IconData _kategorieIcon(String kat) {
  switch (kat) {
    case 'Sanitär / Wasser':
      return Icons.water_drop;
    case 'Heizung':
      return Icons.local_fire_department;
    case 'Wärmeerzeuger':
      return Icons.whatshot;
    case 'Klima':
      return Icons.ac_unit;
    case 'Lüftung':
      return Icons.air;
    case 'Abwasser / Kanalisation':
      return Icons.water;
    case 'Rohre':
      return Icons.plumbing;
    case 'Fittings':
      return Icons.settings_input_component;
    case 'Wassertechnik':
      return Icons.opacity;
    case 'Installation / Montage':
      return Icons.hardware;
    case 'Isolierung':
      return Icons.layers;
    case 'Werkzeug':
      return Icons.build;
    case 'Verbrauchsmaterial':
      return Icons.inventory_2;
    case 'Bad / Sanitär-Ausstattung':
      return Icons.bathtub;
    case 'Regenerative Energien':
      return Icons.wb_sunny;
    case 'Messen / Prüfen':
      return Icons.speed;
    case 'Elektro / Anschluss für SHK':
      return Icons.electrical_services;
    default:
      return Icons.edit;
  }
}

/// Material auswählen: Suche mit Vorschlägen oder Kategorien durchblättern.
/// Nach dem Tippen auf einen Artikel genügt die Menge, dann ist er in der Liste.
class MaterialAuswahlPage extends StatefulWidget {
  const MaterialAuswahlPage({super.key, required this.baustelleId});

  final String baustelleId;

  @override
  State<MaterialAuswahlPage> createState() => _MaterialAuswahlPageState();
}

class _MaterialAuswahlPageState extends State<MaterialAuswahlPage> {
  final _store = MaterialListenStore.instance;
  final _suche = TextEditingController();
  final _fokus = FocusNode();

  String? _kat;
  String? _unter;
  String? _typ;
  int _neu = 0;

  @override
  void dispose() {
    _suche.dispose();
    _fokus.dispose();
    super.dispose();
  }

  Future<void> _waehle(KatalogArtikel a) async {
    final r = await zeigeMengeDialog(
      context,
      name: a.name,
      menge: 1,
      einheit: a.einheit,
    );
    if (r == null || !mounted) return;
    await _store.hinzufuegen(
      widget.baustelleId,
      name: a.name,
      menge: r.menge,
      einheit: r.einheit,
    );
    if (!mounted) return;
    setState(() {
      _neu++;
      _suche.clear();
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('${a.name}: ${formatMenge(r.menge)} ${r.einheit} hinzugefügt'),
        ),
      );
    _fokus.requestFocus();
  }

  String _gross(String s) {
    final t = s.trim();
    return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
  }

  Widget _kopf(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );

  Widget _artikelKachel(KatalogArtikel a, Set<String> inListe) {
    final drin = inListe.contains(a.name);
    return ListTile(
      title: Text(a.name, style: const TextStyle(fontSize: 17)),
      subtitle: Text(a.unter),
      trailing: drin
          ? Icon(Icons.check_circle, color: Colors.green.shade700)
          : Text(a.einheit, style: const TextStyle(fontSize: 15)),
      onTap: () => _waehle(a),
    );
  }

  Widget _suchErgebnis(String eingabe, Set<String> inListe) {
    final r = sucheKatalog(eingabe, _store.katalog);
    final eigener = ListTile(
      leading: const Icon(Icons.add_circle_outline),
      title: Text('„${eingabe.trim()}“ als eigenen Artikel anlegen'),
      onTap: () => _waehle(KatalogArtikel(name: _gross(eingabe), einheit: 'Stk.')),
    );
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (r.familien.isNotEmpty) ...[
          _kopf('Vorschläge'),
          for (final f in r.familien)
            ListTile(
              leading: const Icon(Icons.arrow_outward),
              title: Text(f.name, style: const TextStyle(fontSize: 17)),
              trailing: Text('${f.anzahl} Artikel'),
              onTap: () {
                _suche.text = '${f.name} ';
                _suche.selection = TextSelection.collapsed(offset: _suche.text.length);
                setState(() {});
                _fokus.requestFocus();
              },
            ),
        ],
        if (r.artikel.isNotEmpty) ...[
          _kopf('Artikel'),
          for (final a in r.artikel) _artikelKachel(a, inListe),
        ] else
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Nichts gefunden.', style: TextStyle(fontSize: 16)),
          ),
        const Divider(),
        eigener,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _durchsuchen(Set<String> inListe) {
    final baum = kategorienBaum(_store.katalog);
    final katalog = _store.katalog;

    if (_kat == null) {
      final zuletzt = _store.zuletzt;
      return ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          if (zuletzt.isNotEmpty) ...[
            _kopf('Zuletzt verwendet'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final a in zuletzt.take(10))
                    ActionChip(
                      label: Text(a.name),
                      onPressed: () => _waehle(a),
                    ),
                ],
              ),
            ),
          ],
          _kopf('Kategorien'),
          for (final k in baum.keys)
            ListTile(
              leading: Icon(_kategorieIcon(k), size: 28),
              title: Text(k, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              subtitle: Text('${katalog.where((a) => a.kategorie == k).length} Artikel'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() {
                _kat = k;
                _unter = null;
                _typ = null;
              }),
            ),
        ],
      );
    }

    final kat = _kat!;
    if (_unter == null) {
      return ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.arrow_back),
            title: const Text('Alle Kategorien'),
            onTap: () => setState(() => _kat = null),
          ),
          _kopf(kat),
          for (final u in baum[kat] ?? const <String>[])
            ListTile(
              title: Text(u, style: const TextStyle(fontSize: 17)),
              subtitle: Text(
                '${katalog.where((a) => a.kategorie == kat && a.unter == u).length} Artikel',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() {
                _unter = u;
                _typ = null;
              }),
            ),
        ],
      );
    }

    final unter = _unter!;
    final alle = [
      for (final a in katalog)
        if (a.kategorie == kat && a.unter == unter) a,
    ];
    final typen = <String>[];
    for (final a in alle) {
      if (a.typ.isNotEmpty && !typen.contains(a.typ)) typen.add(a.typ);
    }
    final gefiltert = [
      for (final a in alle)
        if (_typ == null || a.typ == _typ) a,
    ];
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.arrow_back),
          title: Text(unter, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(kat),
          onTap: () => setState(() {
            _unter = null;
            _typ = null;
          }),
        ),
        if (typen.length > 1)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('Alle'),
                    selected: _typ == null,
                    onSelected: (_) => setState(() => _typ = null),
                  ),
                ),
                for (final t in typen)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t),
                      selected: _typ == t,
                      onSelected: (_) => setState(() => _typ = t),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: gefiltert.length,
            itemBuilder: (context, i) => _artikelKachel(gefiltert[i], inListe),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _suche,
          focusNode: _fokus,
          autofocus: true,
          cursorColor: scheme.onPrimary,
          style: TextStyle(color: scheme.onPrimary, fontSize: 19),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Suchen: kup 22, bogen, gyp …',
            hintStyle: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.7)),
          ),
          onChanged: (_) => setState(() {}),
        ),
        actions: [
          if (_suche.text.isNotEmpty)
            IconButton(
              tooltip: 'Löschen',
              icon: const Icon(Icons.close),
              onPressed: () => setState(_suche.clear),
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final b = _store.finde(widget.baustelleId);
          final inListe = {for (final a in b?.artikel ?? const <ListenArtikel>[]) a.name};
          final eingabe = _suche.text;
          return eingabe.trim().isEmpty
              ? _durchsuchen(inListe)
              : _suchErgebnis(eingabe, inListe);
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.check),
            label: Text(_neu == 0 ? 'Fertig' : 'Fertig ($_neu hinzugefügt)'),
          ),
        ),
      ),
    );
  }
}
