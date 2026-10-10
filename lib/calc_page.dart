import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'logic.dart';
import 'vorschlag.dart';

/// Eine Auswahl-Option (Dropdown); [value] wird als Zahl an die Rechnung gegeben.
class CalcOption {
  const CalcOption(this.label, this.value);

  final String label;
  final String value;
}

class CalcField {
  const CalcField(this.label, this.unit, {this.initial, this.options});

  final String label;
  final String unit;
  final String? initial;

  /// Wenn gesetzt, wird statt eines Zahlenfelds ein Dropdown gezeigt.
  final List<CalcOption>? options;
}

class ResultRow {
  const ResultRow(this.label, this.value, {this.highlight = false});

  final String label;
  final String value;
  final bool highlight;
}

/// Materialvorschläge zu den eingegebenen Werten.
typedef VorschlagFn = List<Vorschlag> Function(List<double?> values);

/// Hinweis „Richtwert“ unter dem Ergebnis.
const String kRichtwertHinweis =
    'Richtwert – endgültige Auslegung nach Herstellerangaben und geltenden technischen Regeln.';

/// Weiterführender Schritt (z. B. Druckverlust → Pumpe wählen).
class CalcWeiter {
  const CalcWeiter(this.label, this.ziel);

  final String label;
  final Widget Function(List<double?> values) ziel;
}

typedef ComputeFn = List<ResultRow> Function(List<double?> values);

/// Liefert eine konkrete Fehlermeldung oder null, wenn gerechnet werden kann.
typedef PruefFn = String? Function(List<double?> values);

/// Generische Rechner-Seite: Eingabefelder oben, Ergebnisse live darunter.
/// Alles läuft lokal auf dem Gerät, es werden keine Daten gespeichert.
class CalcPage extends StatefulWidget {
  const CalcPage({
    super.key,
    required this.title,
    required this.fields,
    required this.compute,
    this.requireAll = true,
    this.note,
    this.vorschlaege,
    this.richtwert = false,
    this.weiter,
    this.pruefung,
  });

  final PruefFn? pruefung;
  final String title;
  final List<CalcField> fields;
  final ComputeFn compute;

  /// true: Ergebnisse erst, wenn alle Felder gefüllt sind.
  /// false: sobald mindestens ein Feld gefüllt ist (compute entscheidet).
  final bool requireAll;
  final String? note;
  final VorschlagFn? vorschlaege;

  /// true: zeigt unter dem Ergebnis den Richtwert-Hinweis.
  final bool richtwert;
  final CalcWeiter? weiter;

  @override
  State<CalcPage> createState() => _CalcPageState();
}

class _CalcPageState extends State<CalcPage> {
  late final List<TextEditingController> _controllers;

  String _initialText(CalcField f) => f.initial ?? f.options?.first.value ?? '';

  @override
  void initState() {
    super.initState();
    _controllers = [
      for (final f in widget.fields) TextEditingController(text: _initialText(f)),
    ];
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _reset() {
    setState(() {
      for (var i = 0; i < _controllers.length; i++) {
        _controllers[i].text = _initialText(widget.fields[i]);
      }
    });
  }

  InputDecoration _decoration(CalcField f) => InputDecoration(
        labelText: f.label,
        suffixText: f.unit.isEmpty ? null : f.unit,
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      );

  Widget _buildField(int i) {
    final f = widget.fields[i];
    final options = f.options;
    if (options != null) {
      final current = _controllers[i].text;
      final selected = options.any((o) => o.value == current)
          ? current
          : options.first.value;
      return InputDecorator(
        decoration: _decoration(f),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selected,
            isExpanded: true,
            items: [
              for (final o in options)
                DropdownMenuItem<String>(
                  value: o.value,
                  child: Text(o.label, style: const TextStyle(fontSize: 18)),
                ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _controllers[i].text = val);
            },
          ),
        ),
      );
    }
    return TextField(
      controller: _controllers[i],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      style: const TextStyle(fontSize: 22),
      decoration: _decoration(f),
      onChanged: (_) => setState(() {}),
    );
  }

  String _leerText(List<double?> values, bool ready) {
    final fehlt = <String>[];
    final unlesbar = <String>[];
    for (var i = 0; i < values.length; i++) {
      final f = widget.fields[i];
      if (values[i] != null || f.options != null) continue;
      (_controllers[i].text.trim().isEmpty ? fehlt : unlesbar).add(f.label);
    }
    if (unlesbar.isNotEmpty) {
      return 'Eingabe nicht lesbar: ${unlesbar.join(', ')}. '
          'Bitte nur Ziffern und ein Komma verwenden, z. B. 12,5.';
    }
    if (!ready && widget.requireAll && fehlt.isNotEmpty) {
      return 'Bitte noch eingeben: ${fehlt.join(', ')}.';
    }
    if (!ready) return 'Bitte mindestens einen Wert eingeben.';
    return 'Mit diesen Werten ist keine Berechnung möglich. Bitte die Eingaben prüfen.';
  }

  @override
  Widget build(BuildContext context) {
    final values = [for (final c in _controllers) parseNum(c.text)];
    final ready = widget.requireAll
        ? values.every((v) => v != null)
        : values.any((v) => v != null);
    final meldung = ready ? widget.pruefung?.call(values) : null;
    final rows = (ready && meldung == null) ? widget.compute(values) : <ResultRow>[];
    final leerText = meldung ?? _leerText(values, ready);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Zurücksetzen',
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.note != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(widget.note!, style: Theme.of(context).textTheme.bodyMedium),
            ),
          for (var i = 0; i < widget.fields.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildField(i),
            ),
          if (_controllers.any((c) => zahlWirdAlsTausenderGelesen(c.text)))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Hinweis: „1.234“ wird als 1234 gelesen (Punkt = Tausendertrenner). '
                'Für Dezimalstellen das Komma verwenden, z. B. „1,234“.',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
              ),
            ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Text(
              leerText,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16),
            )
          else
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (final r in rows)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                r.label,
                                style: TextStyle(
                                  fontSize: r.highlight ? 18 : 16,
                                  fontWeight:
                                      r.highlight ? FontWeight.w700 : FontWeight.w400,
                                ),
                              ),
                            ),
                            Text(
                              r.value,
                              style: TextStyle(
                                fontSize: r.highlight ? 22 : 18,
                                fontWeight:
                                    r.highlight ? FontWeight.w800 : FontWeight.w600,
                                color: r.highlight ? scheme.primary : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (rows.isNotEmpty && widget.richtwert)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                kRichtwertHinweis,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, fontStyle: FontStyle.italic),
              ),
            ),
          if (rows.isNotEmpty && widget.weiter != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => widget.weiter!.ziel(values)),
                ),
                icon: const Icon(Icons.arrow_forward),
                label: Text(widget.weiter!.label),
              ),
            ),
          if (rows.isNotEmpty && widget.vorschlaege != null)
            VorschlagKarte(vorschlaege: widget.vorschlaege!(values)),
        ],
      ),
    );
  }
}
