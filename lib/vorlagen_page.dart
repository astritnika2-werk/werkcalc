import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'logic.dart' show parseNum;
import 'materialliste.dart';
import 'materialliste_pages.dart' show MaterialListePage;
import 'materialliste_store.dart';
import 'vorlagen.dart';

/// Liste der Vorlagen. Jede Vorlage erzeugt eine NEUE Baustelle; bestehende
/// Baustellen und Materiallisten werden nicht verändert.
class VorlagenAuswahlPage extends StatelessWidget {
  const VorlagenAuswahlPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vorlage wählen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(kVorlagenHinweis, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          for (final v in kVorlagen)
            Card(
              child: ListTile(
                title: Text(v.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                subtitle: Text(v.beschreibung),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => VorlagePage(vorlage: v)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class VorlagePage extends StatefulWidget {
  const VorlagePage({super.key, required this.vorlage});

  final Vorlage vorlage;

  @override
  State<VorlagePage> createState() => _VorlagePageState();
}

class _VorlagePageState extends State<VorlagePage> {
  final _store = MaterialListenStore.instance;
  final Map<String, String> _param = {};
  final Map<String, String> _modus = {}; // Zone → Modus-Label
  final Map<String, String> _variante = {}; // Posten-Schlüssel → Katalogname
  final Map<String, ({String? typ, int? hoehe, int? laenge})> _hk = {};
  final Map<String, TextEditingController> _menge = {};
  bool _laedt = true;

  @override
  void initState() {
    super.initState();
    _store.laden().then((_) {
      if (mounted) setState(() => _laedt = false);
    });
  }

  @override
  void dispose() {
    for (final c in _menge.values) {
      c.dispose();
    }
    super.dispose();
  }

  Set<String> get _namen => {for (final a in _store.katalog) a.name};

  Map<String, String> get _einheit => {for (final a in _store.katalog) a.name: a.einheit};

  TextEditingController _ctrl(String key) => _menge.putIfAbsent(key, () => TextEditingController());

  void _parameterGeaendert() {
    for (final c in _menge.values) {
      c.clear();
    }
    _variante.clear();
    _hk.clear();
  }

  /// Der tatsächlich gewählte Katalogname eines Eintrags (oder null).
  String? _name(String key, VorlagenPosten p) {
    if (p.heizkoerper) {
      final h = _hk[key];
      if (h == null || h.typ == null || h.hoehe == null || h.laenge == null) return null;
      final n = kompaktheizkoerperName(h.typ!, h.hoehe!, h.laenge!);
      return _namen.contains(n) ? n : null;
    }
    final da = [for (final v in p.varianten) if (_namen.contains(v)) v];
    if (da.isEmpty) return null;
    final w = _variante[key];
    return (w != null && da.contains(w)) ? w : da.first;
  }

  Iterable<(String, VorlagenPosten)> _sichtbarePosten() sync* {
    for (final z in widget.vorlage.zonenMit(_param)) {
      for (final p in z.posten) {
        yield ('${z.name}|-|${p.label}', p);
      }
      final m = _modus[z.name];
      for (final mo in z.modi) {
        if (mo.label != m) continue;
        for (final p in mo.posten) {
          yield ('${z.name}|${mo.label}|${p.label}', p);
        }
      }
    }
  }

  ({List<VorlagenAuswahl> auswahl, List<String> fehler}) _pruefe() {
    final zeilen = <({String name, double? menge})>[];
    final fehler = <String>[];
    for (final (key, p) in _sichtbarePosten()) {
      final t = _menge[key]?.text.trim() ?? '';
      if (t.isEmpty) continue;
      final name = _name(key, p);
      if (name == null) {
        fehler.add('${p.label}: Bitte zuerst die Variante vollständig wählen.');
        continue;
      }
      final m = parseNum(t);
      if (m == null) {
        fehler.add('${p.label}: Die Menge „$t“ ist nicht lesbar.');
        continue;
      }
      zeilen.add((name: name, menge: m));
    }
    final r = pruefeAuswahl(zeilen, _namen);
    return (auswahl: r.auswahl, fehler: [...fehler, ...r.fehler]);
  }

  Future<void> _anlegen(List<VorlagenAuswahl> auswahl) async {
    final c = TextEditingController(text: widget.vorlage.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Neue Baustelle'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name der Baustelle'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Anlegen')),
        ],
      ),
    );
    if (name == null || !mounted) return;
    final b = await vorlageAlsNeueBaustelle(_store, name, auswahl);
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => MaterialListePage(baustelleId: b.id)),
    );
  }

  Widget _statusChip(VorlagenStatus s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(s.text, style: const TextStyle(fontSize: 12)),
      );

  Widget _dropdown<T>({
    required String label,
    required T? wert,
    required List<T> optionen,
    required String Function(T) text,
    required void Function(T?) aenderung,
  }) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: optionen.contains(wert) ? wert : null,
          isExpanded: true,
          hint: const Text('wählen'),
          items: [for (final o in optionen) DropdownMenuItem<T>(value: o, child: Text(text(o)))],
          onChanged: aenderung,
        ),
      ),
    );
  }

  Widget _postenKarte(String key, VorlagenPosten p) {
    final name = _name(key, p);
    final da = [for (final v in p.varianten) if (_namen.contains(v)) v];
    final einheit = name == null ? null : _einheit[name];
    Widget auswahl;
    if (p.heizkoerper) {
      final k = kompaktheizkoerperKombinationen(_namen);
      final h = _hk[key] ?? (typ: null, hoehe: null, laenge: null);
      final typen = k.keys.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
      final hoehen = h.typ == null ? <int>[] : (k[h.typ]!.keys.toList()..sort());
      final laengen = (h.typ == null || h.hoehe == null) ? <int>[] : (k[h.typ]![h.hoehe] ?? <int>[]);
      auswahl = Column(children: [
        _dropdown<String>(
          label: 'Typ', wert: h.typ, optionen: typen, text: (t) => 'Typ $t',
          aenderung: (v) => setState(() => _hk[key] = (typ: v, hoehe: null, laenge: null)),
        ),
        const SizedBox(height: 8),
        _dropdown<int>(
          label: 'Höhe (mm)', wert: h.hoehe, optionen: hoehen, text: (t) => '$t',
          aenderung: (v) => setState(() => _hk[key] = (typ: h.typ, hoehe: v, laenge: null)),
        ),
        const SizedBox(height: 8),
        _dropdown<int>(
          label: 'Länge (mm)', wert: h.laenge, optionen: laengen, text: (t) => '$t',
          aenderung: (v) => setState(() => _hk[key] = (typ: h.typ, hoehe: h.hoehe, laenge: v)),
        ),
      ]);
    } else if (da.isEmpty) {
      auswahl = const Text('Im Katalog nicht verfügbar.', style: TextStyle(color: Colors.black54));
    } else if (da.length == 1) {
      auswahl = Text(da.first, style: const TextStyle(fontSize: 15));
    } else {
      auswahl = _dropdown<String>(
        label: 'Variante', wert: name, optionen: da, text: (t) => t,
        aenderung: (v) => setState(() => _variante[key] = v ?? da.first),
      );
    }
    final verfuegbar = p.heizkoerper || da.isNotEmpty;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(p.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
              _statusChip(p.status),
            ]),
            if (p.hinweis != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(p.hinweis!, style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ),
            const SizedBox(height: 8),
            auswahl,
            if (verfuegbar) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _ctrl(key),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: InputDecoration(
                  labelText: 'Menge (leer = nicht aufnehmen)',
                  suffixText: einheit,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _zone(VorlagenZone z) {
    final m = _modus[z.name];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 6),
          child: Text(z.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        ),
        if (z.hinweis != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(z.hinweis!, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ),
        for (final p in z.posten) _postenKarte('${z.name}|-|${p.label}', p),
        if (z.modi.isNotEmpty) ...[
          if (z.modusFrage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(z.modusFrage!, style: const TextStyle(fontSize: 14)),
            ),
          Wrap(spacing: 8, children: [
            for (final mo in z.modi)
              ChoiceChip(
                label: Text(mo.label),
                selected: m == mo.label,
                onSelected: (sel) => setState(() {
                  if (sel) {
                    _modus[z.name] = mo.label;
                  } else {
                    _modus.remove(z.name);
                  }
                }),
              ),
          ]),
          for (final mo in z.modi)
            if (mo.label == m)
              for (final p in mo.posten) _postenKarte('${z.name}|${mo.label}|${p.label}', p),
        ],
        if (z.nichtVerfuegbar.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Im Katalog nicht verfügbar:', style: TextStyle(fontWeight: FontWeight.w700)),
          for (final n in z.nichtVerfuegbar)
            Row(children: [
              const Icon(Icons.block, size: 16, color: Colors.black45),
              const SizedBox(width: 6),
              Expanded(child: Text(n)),
            ]),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vorlage;
    if (_laedt) {
      return Scaffold(appBar: AppBar(title: Text(v.name)), body: const Center(child: CircularProgressIndicator()));
    }
    final zonen = v.zonenMit(_param);
    final r = _pruefe();
    final parameterOffen = v.parameter.isNotEmpty && zonen.isEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(v.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          Text(kVorlagenHinweis, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          if (v.hinweis != null) ...[
            const SizedBox(height: 8),
            Text(v.hinweis!, style: const TextStyle(fontSize: 14)),
          ],
          const SizedBox(height: 12),
          for (final p in v.parameter)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _dropdown<String>(
                label: p.label,
                wert: _param[p.schluessel],
                optionen: p.optionen(_param),
                text: (t) => t,
                aenderung: (x) => setState(() {
                  if (x == null) {
                    _param.remove(p.schluessel);
                  } else {
                    _param[p.schluessel] = x;
                  }
                  // Werkstoff geändert → Durchmesser zurücksetzen
                  if (p.schluessel == 'werkstoff') _param.remove('durchmesser');
                  _parameterGeaendert();
                }),
              ),
            ),
          if (parameterOffen)
            const Text('Bitte zuerst Werkstoff und Durchmesser wählen.', style: TextStyle(fontSize: 15)),
          for (final z in zonen) _zone(z),
          if (r.fehler.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final f in r.fehler) Text(f, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: (r.auswahl.isEmpty || r.fehler.isNotEmpty) ? null : () => _anlegen(r.auswahl),
            icon: const Icon(Icons.playlist_add),
            label: Text('Als neue Baustelle anlegen (${r.auswahl.length} Artikel)'),
          ),
        ),
      ),
    );
  }
}
