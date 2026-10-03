import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'logic.dart';
import 'storage.dart';

/// Materialliste: Artikel mit Menge und Einzelpreis (netto), Summe,
/// und Übernahme der Netto-Summe ins PDF-Angebot. Nur lokal gespeichert.
class MaterialkostenPage extends StatefulWidget {
  const MaterialkostenPage({super.key});

  @override
  State<MaterialkostenPage> createState() => _MaterialkostenPageState();
}

class _MaterialkostenPageState extends State<MaterialkostenPage> {
  List<MaterialPosition> _liste = [];

  @override
  void initState() {
    super.initState();
    _laden();
  }

  Future<void> _laden() async {
    final l = await AngebotStorage.ladeMaterial();
    if (mounted) setState(() => _liste = l);
  }

  Future<void> _hinzufuegen() async {
    final p = await showModalBottomSheet<MaterialPosition>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ArtikelSheet(),
    );
    if (p == null) return;
    setState(() => _liste = [..._liste, p]);
    await AngebotStorage.speichereMaterial(_liste);
  }

  Future<void> _entfernen(int index) async {
    setState(() => _liste = [
          for (var i = 0; i < _liste.length; i++)
            if (i != index) _liste[i],
        ]);
    await AngebotStorage.speichereMaterial(_liste);
  }

  Future<void> _alleLoeschen() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Liste leeren?'),
        content: const Text('Alle Artikel werden entfernt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leeren'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _liste = []);
    await AngebotStorage.speichereMaterial(_liste);
  }

  @override
  Widget build(BuildContext context) {
    final netto = materialSumme(_liste);
    final a = berechneAngebotAusBetraegen(arbeit: 0, material: netto);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Materialkosten'),
        actions: [
          IconButton(
            tooltip: 'Liste leeren',
            icon: const Icon(Icons.delete_sweep),
            onPressed: _liste.isEmpty ? null : _alleLoeschen,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _hinzufuegen,
        icon: const Icon(Icons.add),
        label: const Text('Artikel hinzufügen'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _liste.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Noch keine Artikel. Tippe unten auf "Artikel hinzufügen".',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: _liste.length,
                    itemBuilder: (context, i) {
                      final m = _liste[i];
                      final menge = fmt(m.menge, digits: m.menge % 1 == 0 ? 0 : 2);
                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(
                            m.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text('$menge × ${fmt(m.einzelpreis)} €'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${fmt(m.summe)} €',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Entfernen',
                                icon: const Icon(Icons.close),
                                onPressed: () => _entfernen(i),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _zeile('Material (netto)', '${fmt(a.material)} €'),
                  _zeile('MwSt. (19 %)', '${fmt(a.mwst)} €'),
                  _zeile(
                    'Material (brutto)',
                    '${fmt(a.brutto)} €',
                    fett: true,
                    farbe: scheme.primary,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 17),
                      ),
                      onPressed: netto > 0
                          ? () {
                              materialUebernahme.value = netto;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${fmt(netto)} € netto ins Angebot übernommen (Tab PDF).',
                                  ),
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.description),
                      label: const Text('In Angebot übernehmen'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _zeile(String label, String wert, {bool fett = false, Color? farbe}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fett ? 18 : 16,
                fontWeight: fett ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            wert,
            style: TextStyle(
              fontSize: fett ? 21 : 17,
              fontWeight: fett ? FontWeight.w800 : FontWeight.w600,
              color: farbe,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtikelSheet extends StatefulWidget {
  const _ArtikelSheet();

  @override
  State<_ArtikelSheet> createState() => _ArtikelSheetState();
}

class _ArtikelSheetState extends State<_ArtikelSheet> {
  final _name = TextEditingController();
  final _menge = TextEditingController(text: '1');
  final _preis = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _menge.dispose();
    _preis.dispose();
    super.dispose();
  }

  Widget _feld(
    TextEditingController c,
    String label, {
    String? suffix,
    bool zahl = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: zahl
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        textCapitalization:
            zahl ? TextCapitalization.none : TextCapitalization.sentences,
        inputFormatters:
            zahl ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))] : null,
        style: const TextStyle(fontSize: 20),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menge = parseNum(_menge.text);
    final preis = parseNum(_preis.text);
    final gueltig =
        _name.text.trim().isNotEmpty && menge != null && menge > 0 && preis != null && preis >= 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Artikel hinzufügen',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            _feld(_name, 'Bezeichnung'),
            Row(
              children: [
                Expanded(child: _feld(_menge, 'Menge', zahl: true)),
                const SizedBox(width: 12),
                Expanded(
                  child: _feld(_preis, 'Einzelpreis (netto)', suffix: '€', zahl: true),
                ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                onPressed: gueltig
                    ? () => Navigator.pop(
                          context,
                          MaterialPosition(
                            name: _name.text.trim(),
                            menge: menge!,
                            einzelpreis: preis!,
                          ),
                        )
                    : null,
                child: const Text('Hinzufügen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
