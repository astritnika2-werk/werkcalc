import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/katalog.dart';
import 'package:werkcalc/materialliste.dart';
import 'package:werkcalc/pdf_materialliste.dart';

/// Praxis-Ablauf: Suchproben, Liste mit 30 Positionen, Mengen ändern,
/// Abhaken, Kopie, Text, PDF und Geschwindigkeit. Schreibt einen Bericht
/// nach test_report.txt (wird im CI als Hinweis angezeigt).
void main() {
  final katalog = baueKatalog();
  final bericht = StringBuffer();

  tearDownAll(() {
    File('test_report.txt').writeAsStringSync(bericht.toString());
  });

  test('Suchproben (15 Begriffe)', () {
    bericht.writeln('Katalog: ${katalog.length} Artikel');
    const proben = [
      'gyp', 'gyp baker 22', 'kthesë baker 22', 'mufë 22', 'press 22',
      'lavaman', 'wc', 'pompë', 'pompë qarkullimi', 'bojler', 'rubinet',
      'kanalizim', 'izolim', 'klima', 'ventil',
    ];
    for (final q in proben) {
      final r = sucheKatalog(q, katalog);
      expect(r.artikel, isNotEmpty, reason: q);
      final fam = r.familien.take(8).map((f) => f.name).join(', ');
      final art = r.artikel.take(4).map((a) => a.name).join(' | ');
      bericht.writeln('„$q“ → Familien: [$fam] Artikel: $art');
    }
  });

  test('Geschwindigkeit der Suche', () {
    // Erste Suche baut den Cache, danach zählt jede Eingabe.
    sucheKatalog('kup', katalog);
    final sw = Stopwatch()..start();
    var n = 0;
    for (final q in ['g', 'gy', 'gyp', 'gyp b', 'gyp ba', 'gyp bak', 'gyp baker', 'gyp baker 2', 'gyp baker 22', 'press 22', 'wc', 'pompë qarkullimi']) {
      sucheKatalog(q, katalog);
      n++;
    }
    sw.stop();
    final ms = sw.elapsedMilliseconds / n;
    bericht.writeln('Suche: ${ms.toStringAsFixed(1)} ms pro Eingabe (Ø)');
    expect(ms, lessThan(60));
  });

  test('Liste mit 30 Positionen, Menge, Abhaken, Kopie, Text, PDF', () async {
    final auswahl = <String>[
      'kup 22', 'kup 15', 'kup 28', 'bogen 22', 'bogen 28', 'muffe 22',
      'press 22', 'press 28', 'kugelhahn 3/4', 'kugelhahn 1', 'wc',
      'waschtisch 60', 'pomp 25', 'siphon', 'isolierung 22', 'ht-rohr 100',
      'kg-rohr 110', 'rohrschelle 22', 'dübel 8', 'hanf', 'silikon',
      'heizkörper typ 22', 'thermostat', 'ausdehnungsgefäß 18', 'bodenablauf',
      'schraube', 'gewindestange m8', 'lüftungsrohr 125', 'split klima', 'wärmepumpe',
    ];
    var liste = <ListenArtikel>[];
    var i = 0;
    for (final q in auswahl) {
      final r = sucheKatalog(q, katalog).artikel;
      expect(r, isNotEmpty, reason: q);
      final a = r.first;
      i++;
      liste = artikelHinzufuegen(
        liste,
        id: 'id$i',
        name: a.name,
        menge: (i % 7 + 1) * (a.einheit == 'm' ? 5 : 2).toDouble(),
        einheit: a.einheit,
      );
    }
    bericht.writeln('Liste: ${liste.length} Positionen');
    expect(liste.length, greaterThanOrEqualTo(25));

    // Menge ändern, abhaken, löschen (wie im Store).
    liste = [for (final a in liste) a.id == 'id1' ? a.copyWith(menge: 99) : a];
    expect(liste.first.menge, 99);
    liste = [for (final a in liste) a.id == 'id2' ? a.copyWith(erledigt: true) : a];
    expect(liste.where((a) => a.erledigt).length, 1);
    final vorher = liste.length;
    final geloescht = liste[3];
    liste = [for (final a in liste) if (a.id != geloescht.id) a];
    expect(liste.length, vorher - 1);
    liste = [...liste.sublist(0, 3), geloescht, ...liste.sublist(3)]; // Undo
    expect(liste[3].id, geloescht.id);

    final b = Baustelle(id: 'b', name: 'Müllerstraße 5', artikel: liste, erstellt: DateTime(2026, 10, 3));
    final k = kopiereBaustelle(b, neueId: 'c', neuerName: 'Kopie', jetzt: DateTime(2026, 10, 4), idFuerArtikel: (x) => 'k$x');
    expect(k.artikel.length, b.artikel.length);
    expect(k.anzahlErledigt, 0);

    final text = listeAlsText(b, datum: DateTime(2026, 10, 3));
    expect(text, contains('Müllerstraße 5'));
    expect('\n'.allMatches(text).length, greaterThan(liste.length));

    ByteData laden(String pfad) {
      final bytes = File(pfad).readAsBytesSync();
      return ByteData.view(Uint8List.fromList(bytes).buffer);
    }
    final pdf = await buildMaterialListePdf(
      b,
      regular: laden('assets/fonts/DejaVuSans.ttf'),
      bold: laden('assets/fonts/DejaVuSans-Bold.ttf'),
      logo: File('assets/brand/logo_mark_color.png').readAsBytesSync(),
    );
    expect(pdf.length, greaterThan(2000));
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
    bericht.writeln('PDF: ${pdf.length} Bytes, ${liste.length} Positionen');

    // Gespeichert und wieder geladen (JSON).
    final neu = Baustelle.fromJson(b.toJson());
    expect(neu.artikel.length, b.artikel.length);
  });
}
