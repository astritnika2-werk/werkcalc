import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/katalog.dart';
import 'package:werkcalc/materialliste.dart';

/// Kontrollliste: welche Katalogartikel haben (noch) kein lizenziertes Foto?
/// Schreibt foto_liste.csv (alle Artikel) und foto_zusammenfassung.csv
/// (je Produktfamilie). Es werden keine Fotos angelegt oder verändert.
String q(String s) => '"${s.replaceAll('"', '""')}"';

void main() {
  test('Foto-Kontrollliste schreiben', () {
    var k = baueKatalog();
    final zusatz = File('assets/katalog/zusatz.json');
    if (zusatz.existsSync()) {
      final roh = zusatz.readAsStringSync();
      final extra = katalogAusJson(roh, vorhandeneNamen: {for (final a in k) a.name});
      k = katalogAnreichern(k, roh);
      if (extra.isNotEmpty) k = [...k, ...extra];
    }
    // Rechte aus assets/produkte/fotos.json + vorhandene Bilddateien
    final rechte = <String, Map<String, dynamic>>{};
    final f = File('assets/produkte/fotos.json');
    if (f.existsSync()) {
      final m = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      m.forEach((key, v) => rechte[key] = Map<String, dynamic>.from(v as Map));
    }
    final dateien = <String>{
      for (final e in Directory('assets/produkte').listSync())
        if (e is File) e.uri.pathSegments.last.split('.').first,
    };

    final b = StringBuffer('﻿Kategorie;Unterkategorie;Produktfamilie;Produkt;Hersteller;Artikelnummer;EAN;Foto vorhanden;Lizenz vorhanden;Quelle\n');
    final zus = <String, List<int>>{}; // [artikel, mit foto, mit lizenz, mit hersteller]
    var mitFoto = 0, mitLizenz = 0;
    for (final a in k) {
      var foto = a.foto.isNotEmpty;
      var lizenz = a.fotoLizenz.trim().isNotEmpty;
      var quelle = a.fotoQuelle;
      for (final s in a.fotoSchluessel) {
        if (dateien.contains(s)) foto = true;
        final r = rechte[s];
        if (r != null && ('${r['lizenz'] ?? ''}').trim().isNotEmpty) {
          lizenz = true;
          if (quelle.isEmpty) quelle = '${r['quelle'] ?? ''}';
        }
      }
      if (foto) mitFoto++;
      if (foto && lizenz) mitLizenz++;
      b.writeln([
        q(a.kategorie), q(a.unter), q(a.familie), q(a.name), q(a.hersteller),
        q(a.artikelnummer), q(a.ean), foto ? 'Ja' : 'Nein', lizenz ? 'Ja' : 'Nein', q(quelle),
      ].join(';'));
      final z = zus.putIfAbsent('${a.kategorie};${a.unter};${a.familie}', () => [0, 0, 0, 0]);
      z[0]++;
      if (foto) z[1]++;
      if (lizenz) z[2]++;
      if (a.hersteller.isNotEmpty) z[3]++;
    }
    File('foto_liste.csv').writeAsStringSync(b.toString());
    final s = StringBuffer('﻿Kategorie;Unterkategorie;Produktfamilie;Artikel;davon mit Foto;davon mit Lizenz;davon mit Hersteller\n');
    zus.forEach((key, z) => s.writeln('${key.split(';').map(q).join(';')};${z.join(';')}'));
    File('foto_zusammenfassung.csv').writeAsStringSync(s.toString());
    expect(k.isNotEmpty, true);
    // ignore: avoid_print
    print('Artikel ${k.length}, mit Foto $mitFoto, mit Foto+Lizenz $mitLizenz');
  });
}
