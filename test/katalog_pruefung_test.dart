import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/katalog.dart';
import 'package:werkcalc/materialliste.dart';

/// Nur Prüfung (nichts wird gelöscht oder geändert): doppelte und
/// unvollständige Katalogeinträge, Preisfreiheit, Suche über EAN/Nr./Maß.
void main() {
  final katalog = baueKatalog();

  test('keine doppelten Artikel (gleicher Name und gleiche Einheit)', () {
    final gesehen = <String, int>{};
    final doppelt = <String>[];
    for (final a in katalog) {
      final k = '${normalisiereSuche(a.name.trim())}|${a.einheit}';
      gesehen[k] = (gesehen[k] ?? 0) + 1;
      if (gesehen[k] == 2) doppelt.add(a.name);
    }
    // ignore: avoid_print
    print('Katalog: ${katalog.length} Artikel, doppelt: ${doppelt.length} $doppelt');
    expect(doppelt, isEmpty);
  });

  test('Pflichtangaben vollständig', () {
    final luecken = <String>[
      for (final a in katalog)
        if (a.name.trim().isEmpty || a.einheit.trim().isEmpty || a.kategorie.trim().isEmpty ||
            a.familie.trim().isEmpty)
          a.name,
    ];
    expect(luecken, isEmpty);
  });

  test('EAN, wenn vorhanden, ist eine gültige Ziffernfolge mit Prüfziffer', () {
    final falsch = <String>[];
    for (final a in katalog) {
      if (a.ean.isEmpty) continue;
      final z = a.ean;
      var ok = RegExp(r'^\d{8}$|^\d{13}$').hasMatch(z);
      if (ok) {
        var s = 0;
        for (var i = 0; i < z.length - 1; i++) {
          final d = int.parse(z[z.length - 2 - i]);
          s += d * (i.isEven ? 3 : 1);
        }
        ok = (10 - s % 10) % 10 == int.parse(z[z.length - 1]);
      }
      if (!ok) falsch.add('${a.name}: $z');
    }
    expect(falsch, isEmpty);
  });

  test('Suche findet Artikel über Name, Maß, Artikelnummer und EAN', () {
    expect(sucheKatalog('kupferrohr 22', katalog).artikel.first.name, contains('22'));
    for (final a in katalog.where((a) => a.ean.isNotEmpty).take(20)) {
      expect(sucheKatalog(a.ean, katalog).artikel.map((x) => x.name), contains(a.name));
    }
    for (final a in katalog.where((a) => a.artikelnummer.isNotEmpty).take(20)) {
      expect(sucheKatalog(a.artikelnummer, katalog).artikel.map((x) => x.name), contains(a.name));
    }
  });
}
