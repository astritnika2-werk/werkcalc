import 'package:flutter/material.dart';

import 'materialliste.dart';
import 'materialliste_pages.dart' show MaterialListePage, zeigeMengeDialog;
import 'materialliste_store.dart';

/// Ein Materialvorschlag eines Rechners. [name] ist der EXAKTE Name eines
/// Katalogartikels; gibt es ihn nicht, wird der Vorschlag nicht angezeigt.
class Vorschlag {
  const Vorschlag(this.name, this.menge, this.grund);

  final String name;
  final double menge;

  /// Kurze Begründung, z. B. „Anschluss DN 25“.
  final String grund;
}

/// Zeigt die Vorschläge zum Ankreuzen. Nichts wird automatisch hinzugefügt:
/// Der Nutzer wählt aus und bestätigt mit „Zur Materialliste hinzufügen“.
class VorschlagKarte extends StatefulWidget {
  const VorschlagKarte({super.key, required this.vorschlaege});

  final List<Vorschlag> vorschlaege;

  @override
  State<VorschlagKarte> createState() => _VorschlagKarteState();
}

class _VorschlagKarteState extends State<VorschlagKarte> {
  final _store = MaterialListenStore.instance;
  final Set<String> _aktiv = {};
  final Map<String, double> _mengen = {};
  final Map<String, String> _einheiten = {};

  @override
  void initState() {
    super.initState();
    _store.laden();
  }

  KatalogArtikel? _finde(String name) {
    for (final a in _store.katalog) {
      if (a.name == name) return a;
    }
    return null;
  }

  Future<String?> _waehleBaustelle() async {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'In welche Baustelle?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            for (final b in _store.listen)
              ListTile(
                leading: const Icon(Icons.assignment),
                title: Text(b.name),
                subtitle: Text('${b.anzahl} Positionen'),
                onTap: () => Navigator.pop(ctx, b.id),
              ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Neue Baustelle …'),
              onTap: () async {
                final c = TextEditingController();
                final name = await showDialog<String>(
                  context: ctx,
                  builder: (d) => AlertDialog(
                    title: const Text('Neue Baustelle'),
                    content: TextField(
                      controller: c,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(hintText: 'Name'),
                      onSubmitted: (v) => Navigator.pop(d, v.trim()),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(d), child: const Text('Abbrechen')),
                      FilledButton(
                        onPressed: () => Navigator.pop(d, c.text.trim()),
                        child: const Text('Anlegen'),
                      ),
                    ],
                  ),
                );
                if (name == null || name.isEmpty) return;
                final b = await _store.neueBaustelle(name);
                if (ctx.mounted) Navigator.pop(ctx, b.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _hinzufuegen(List<_Zeile> zeilen) async {
    final gewaehlt = [for (final z in zeilen) if (_aktiv.contains(z.v.name)) z];
    if (gewaehlt.isEmpty) return;
    final id = await _waehleBaustelle();
    if (id == null || !mounted) return;
    for (final z in gewaehlt) {
      await _store.hinzufuegen(
        id,
        name: z.artikel.name,
        menge: _mengen[z.v.name] ?? z.v.menge,
        einheit: _einheiten[z.v.name] ?? z.artikel.einheit,
      );
    }
    if (!mounted) return;
    final b = _store.finde(id);
    setState(_aktiv.clear);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${gewaehlt.length} Positionen zu „${b?.name ?? 'Liste'}“ hinzugefügt'),
          action: SnackBarAction(
            label: 'Öffnen',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => MaterialListePage(baustelleId: id)),
            ),
          ),
        ),
      );
  }

  Future<void> _menge(_Zeile z) async {
    final r = await zeigeMengeDialog(
      context,
      name: z.artikel.name,
      menge: _mengen[z.v.name] ?? z.v.menge,
      einheit: _einheiten[z.v.name] ?? z.artikel.einheit,
      ok: 'Übernehmen',
    );
    if (r == null) return;
    setState(() {
      _mengen[z.v.name] = r.menge;
      _einheiten[z.v.name] = r.einheit;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final zeilen = <_Zeile>[
          for (final v in widget.vorschlaege)
            if (_finde(v.name) case final a?) _Zeile(v, a),
        ];
        if (zeilen.isEmpty) return const SizedBox.shrink();
        final anzahl = zeilen.where((z) => _aktiv.contains(z.v.name)).length;
        final scheme = Theme.of(context).colorScheme;
        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(top: 16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Passende Materialien (Vorschläge)',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          if (anzahl == zeilen.length) {
                            _aktiv.clear();
                          } else {
                            _aktiv.addAll(zeilen.map((z) => z.v.name));
                          }
                        }),
                        child: Text(anzahl == zeilen.length ? 'Keine' : 'Alle'),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(8, 0, 8, 4),
                  child: Text(
                    'Nur Vorschläge – wähle aus, was du wirklich brauchst.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ),
                for (final z in zeilen)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _aktiv.contains(z.v.name),
                    onChanged: (x) => setState(() {
                      if (x ?? false) {
                        _aktiv.add(z.v.name);
                      } else {
                        _aktiv.remove(z.v.name);
                      }
                    }),
                    title: Text(z.artikel.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: Text(z.v.grund, style: const TextStyle(fontSize: 13)),
                    secondary: InkWell(
                      onTap: () => _menge(z),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${formatMenge(_mengen[z.v.name] ?? z.v.menge)} ${_einheiten[z.v.name] ?? z.artikel.einheit}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.secondary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      onPressed: anzahl == 0 ? null : () => _hinzufuegen(zeilen),
                      icon: const Icon(Icons.playlist_add),
                      label: Text('Zur Materialliste hinzufügen ($anzahl)'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Zeile {
  const _Zeile(this.v, this.artikel);

  final Vorschlag v;
  final KatalogArtikel artikel;
}
