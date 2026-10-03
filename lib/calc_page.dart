import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'logic.dart';

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

typedef ComputeFn = List<ResultRow> Function(List<double?> values);

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
  });

  final String title;
  final List<CalcField> fields;
  final ComputeFn compute;

  /// true: Ergebnisse erst, wenn alle Felder gefüllt sind.
  /// false: sobald mindestens ein Feld gefüllt ist (compute entscheidet).
  final bool requireAll;
  final String? note;

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

  @override
  Widget build(BuildContext context) {
    final values = [for (final c in _controllers) parseNum(c.text)];
    final ready = widget.requireAll
        ? values.every((v) => v != null)
        : values.any((v) => v != null);
    final rows = ready ? widget.compute(values) : <ResultRow>[];
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
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Text(
              'Bitte gültige Werte eingeben.',
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
        ],
      ),
    );
  }
}
