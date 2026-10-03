import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/katalog.dart';
import 'package:werkcalc/materialliste.dart';

void main() {
  final katalog = baueKatalog();

  List<String> namen(String q, {int n = 8}) =>
      sucheKatalog(q, katalog).artikel.take(n).map((a) => a.name).toList();

  group('Katalog', () {
    test('ist groß und hat Kategorien', () {
      expect(katalog.length, greaterThan(2000));
      final baum = kategorienBaum(katalog);
      expect(baum.keys.toList(), kKategorieReihenfolge);
      expect(baum['Rohre'], contains('Kupferrohre'));
      expect(baum['Fittings'], contains('Pressfittings'));
      expect(baum['Fittings'], contains('Flansche'));
      expect(baum['Wärmeerzeuger'], containsAll(['Gasheizung', 'Wärmepumpe']));
      expect(baum['Lüftung'], contains('Flachkanäle'));
    });

    test('jede Hauptkategorie hat genug Artikel', () {
      for (final kat in kKategorieReihenfolge) {
        final n = katalog.where((a) => a.kategorie == kat).length;
        expect(n, greaterThan(40), reason: kat);
      }
    });

    test('Größen: mm, Zoll und DN kommen vor', () {
      for (final w in ['Ø15', 'Ø18', 'Ø22', 'Ø28', 'Ø35', 'Ø42', 'Ø54', '½"', '¾"', '1¼"', '1½"', '2"', 'DN 40', 'DN 50', 'DN 75', 'DN 100', 'DN 125', 'DN 150']) {
        expect(katalog.any((a) => a.name.contains(w)), isTrue, reason: w);
      }
    });

    test('JSON-Erweiterung wird gelesen, Doppelte und Fehler übersprungen', () {
      final extra = katalogAusJson(
        '[{"name":"Testartikel A","einheit":"m","kategorie":"Rohre","unter":"Test"},'
        '{"name":"Kupferrohr Ø22 mm"},{"name":""},5,{"name":"Testartikel A"}]',
        vorhandeneNamen: {'Kupferrohr Ø22 mm'},
      );
      expect(extra.length, 1);
      expect(extra.single.einheit, 'm');
      expect(extra.single.unter, 'Test');
      expect(katalogAusJson('kaputt'), isEmpty);
      expect(katalogAusJson('{"artikel":[{"name":"X"}]}').length, 1);
    });

    test('Artikelnamen sind eindeutig', () {
      final seen = <String>{};
      final doppelt = <String>[];
      for (final a in katalog) {
        if (!seen.add(a.name)) doppelt.add(a.name);
      }
      expect(doppelt, isEmpty);
    });
  });

  group('Suche', () {
    test('„gyp“ liefert alle Rohr-Familien', () {
      final r = sucheKatalog('gyp', katalog);
      final fam = r.familien.map((f) => f.name).toList();
      for (final erwartet in [
        'Kupferrohr',
        'Edelstahlrohr',
        'Mehrschichtverbundrohr',
        'Kunststoffrohr',
        'HT-Rohr',
        'KG-Rohr',
        'Stahlrohr',
      ]) {
        expect(fam, contains(erwartet));
      }
    });

    test('„gyp baker“ findet Kupferrohre', () {
      final r = sucheKatalog('gyp baker', katalog, limit: 100).artikel;
      final n = r.map((a) => a.name).toList();
      expect(n, contains('Kupferrohr Ø22 mm'));
      expect(n.every((x) => x.toLowerCase().contains('rohr') && x.toLowerCase().contains('kupfer')), isTrue);
    });

    test('„kthesë baker 22“ findet Kupferbögen', () {
      expect(namen('kthesë baker 22', n: 20), contains('Kupferbogen 90° I/I Ø22'));
    });

    test('„wc“ findet WC, Spülkasten, Vorwandelement, Drückerplatte', () {
      final n = sucheKatalog('wc', katalog, limit: 400).artikel.map((a) => a.name).toList();
      expect(n.any((x) => x.startsWith('WC ')), isTrue);
      expect(n.any((x) => x.startsWith('WC-Sitz')), isTrue);
      expect(n.any((x) => x.startsWith('Spülkasten')), isTrue);
      expect(n.any((x) => x.startsWith('Vorwandelement')), isTrue);
      expect(n.any((x) => x.startsWith('Drückerplatte')), isTrue);
      expect(n.any((x) => x.startsWith('WC-Anschluss')), isTrue);
    });

    test('„pomp 25“ findet Umwälz-, Zirkulationspumpen und Pumpengruppen', () {
      final n = sucheKatalog('pomp 25', katalog, limit: 200).artikel.map((a) => a.name).toList();
      expect(n, contains('Umwälzpumpe Hocheffizienz 25-40'));
      expect(n, contains('Zirkulationspumpe DN 25'));
      expect(n, contains('Pumpengruppe DN 25 gemischt'));
    });

    test('Albanisch: lavaman, bojler, rubinet, pompë qarkullimi, kanalizim', () {
      expect(namen('lavaman', n: 30).any((x) => x.startsWith('Waschtisch')), isTrue);
      expect(namen('bojler', n: 30).any((x) => x.contains('speicher') || x.contains('Speicher')), isTrue);
      expect(namen('rubinet', n: 30).any((x) => x.contains('armatur') || x.contains('Armatur')), isTrue);
      expect(namen('pompë qarkullimi', n: 30).any((x) => x.contains('Umwälzpumpe')), isTrue);
      expect(namen('kanalizim', n: 30), isNotEmpty);
    });

    test('„kup 22“ findet zuerst Kupferrohr Ø22 mm', () {
      expect(namen('kup 22').first, 'Kupferrohr Ø22 mm');
    });

    test('„bogen 22“ findet die Kupferbögen Ø22', () {
      final n = namen('bogen 22', n: 20);
      expect(n, contains('Kupferbogen 90° I/I Ø22'));
      expect(n, contains('Kupferbogen 90° I/A Ø22'));
      expect(n, contains('Kupferbogen 45° Ø22'));
      expect(n.any((x) => x.contains('Ø28')), isFalse);
    });

    test('„press 22“ findet zuerst die Pressfittings Ø22', () {
      final n = namen('press 22', n: 20);
      expect(n, contains('Pressfitting Bogen 90° Ø22 (Kupfer)'));
      expect(n, contains('Pressfitting T-Stück Ø22 (Edelstahl)'));
      expect(n.every((x) => x.startsWith('Pressfitting') && x.contains('22')), isTrue);
    });

    test('Zahl 22 trifft nicht 122 oder 220', () {
      final n = namen('kup 2', n: 50);
      expect(n.any((x) => x.contains('Ø22')), isFalse);
    });

    test('Handwerkersprache: kthesë 22, mufë 22, izolim 22', () {
      expect(namen('kthesë 22', n: 20), contains('Kupferbogen 90° I/I Ø22'));
      expect(namen('mufë 22', n: 20), contains('Muffe Kupfer Ø22'));
      expect(namen('izolim 22').first, 'Isolierung Ø22');
    });

    test('„T“ liefert T-Stücke, „reduksion“ Reduzierungen', () {
      final t = namen('t 22', n: 20);
      expect(t.any((x) => x.contains('T-Stück')), isTrue);
      final r = namen('reduksion 22', n: 20);
      expect(r.every((x) => x.contains('Reduzierung')), isTrue);
      expect(r, isNotEmpty);
    });

    test('„ventil“ und „pompe“', () {
      expect(namen('ventil').every((x) => x.toLowerCase().contains('ventil')), isTrue);
      expect(namen('pompe').first.toLowerCase(), contains('pumpe'));
    });

    test('ue/ae/oe wie Umlaute', () {
      expect(normalisiereSuche('Übergang'), normalisiereSuche('uebergang'));
      expect(namen('uebergang 22'), isNotEmpty);
    });

    test('Brüche und Zoll', () {
      expect(namen('kugelhahn 3/4').first, contains('¾"'));
    });

    test('leere Eingabe und Unsinn', () {
      expect(sucheKatalog('', katalog).artikel, isNotEmpty);
      expect(sucheKatalog('qqqqzzzz', katalog).artikel, isEmpty);
    });
  });

  group('Liste', () {
    test('Artikel hinzufügen addiert gleiche Artikel', () {
      var l = <ListenArtikel>[];
      l = artikelHinzufuegen(l, id: '1', name: 'Kupferrohr Ø22 mm', menge: 20, einheit: 'm');
      l = artikelHinzufuegen(l, id: '2', name: 'Kupferrohr Ø22 mm', menge: 5, einheit: 'm');
      l = artikelHinzufuegen(l, id: '3', name: 'Kupferrohr Ø22 mm', menge: 2, einheit: 'Stk.');
      expect(l.length, 2);
      expect(l.first.menge, 25);
    });

    test('Menge formatieren', () {
      expect(formatMenge(20), '20');
      expect(formatMenge(2.5), '2,5');
      expect(formatMenge(0.25), '0,25');
    });

    test('Kopie hat neue IDs und nichts abgehakt', () {
      final b = Baustelle(
        id: 'b1',
        name: 'Müllerstraße',
        erstellt: DateTime(2026, 10, 3),
        artikel: const [
          ListenArtikel(id: 'a', name: 'Muffe Kupfer Ø22', menge: 10, einheit: 'Stk.', erledigt: true),
        ],
      );
      final k = kopiereBaustelle(
        b,
        neueId: 'b2',
        neuerName: 'Müllerstraße (Kopie)',
        jetzt: DateTime(2026, 10, 4),
        idFuerArtikel: (i) => 'neu$i',
      );
      expect(k.id, 'b2');
      expect(k.artikel.single.id, 'neu0');
      expect(k.artikel.single.erledigt, isFalse);
      expect(k.artikel.single.menge, 10);
    });

    test('Speichern und Laden (JSON)', () {
      final b = Baustelle(
        id: 'b1',
        name: 'Test',
        erstellt: DateTime.fromMillisecondsSinceEpoch(1000),
        artikel: const [
          ListenArtikel(id: 'a', name: 'Hanf', menge: 2, einheit: 'Pack', erledigt: true),
        ],
      );
      final neu = Baustelle.fromJson(b.toJson());
      expect(neu.name, 'Test');
      expect(neu.artikel.single.erledigt, isTrue);
      expect(neu.artikel.single.einheit, 'Pack');
    });

    test('Text zum Teilen', () {
      final b = Baustelle(
        id: 'b1',
        name: 'Müllerstraße',
        erstellt: DateTime(2026, 10, 3),
        artikel: const [
          ListenArtikel(id: 'a', name: 'Kupferrohr Ø22 mm', menge: 20, einheit: 'm'),
          ListenArtikel(id: 'b', name: 'Muffe Kupfer Ø22', menge: 10, einheit: 'Stk.', erledigt: true),
        ],
      );
      final t = listeAlsText(b, datum: DateTime(2026, 10, 3));
      expect(t, contains('Materialliste: Müllerstraße'));
      expect(t, contains('☐ Kupferrohr Ø22 mm — 20 m'));
      expect(t, contains('☑ Muffe Kupfer Ø22 — 10 Stk.'));
      expect(t, contains('03.10.2026'));
    });
  });

  group('Reihenfolge der Ergebnisse', () {
    final k = baueKatalog();
    List<String> fam(String q, int n) =>
        sucheKatalog(q, k).familien.take(n).map((f) => f.name).toList();
    String erst(String q) => sucheKatalog(q, k).artikel.first.name;

    test('izolim', () {
      expect(fam('izolim', 6), ['Rohrisolierung', 'Heizungsisolierung', 'Kälteisolierung', 'Sanitärisolierung', 'Brandschutzisolierung', 'Pumpenisolierschale']);
    });
    test('klima', () {
      expect(fam('klima', 8), ['Klimagerät', 'Split-Klimagerät', 'Außengerät', 'Innengerät', 'Multisplit', 'Kondensatpumpe', 'Kältemittelleitung', 'Verbindungskabel']);
    });
    test('lavaman', () {
      expect(fam('lavaman', 5), ['Waschtisch', 'Waschbecken', 'Doppelwaschtisch', 'Waschtischarmatur', 'Waschtisch-Siphon']);
    });
    test('wc', () {
      expect(fam('wc', 6), ['WC', 'WC-Sitz', 'Spülkasten', 'Vorwandelement', 'Drückerplatte', 'WC-Anschluss']);
    });
    test('pompë qarkullimi', () {
      expect(fam('pompë qarkullimi', 4), ['Umwälzpumpe', 'Zirkulationspumpe', 'Heizkreispumpe', 'Pumpengruppe']);
    });
    test('erste Artikel', () {
      expect(erst('gyp'), startsWith('Kupferrohr'));
      expect(erst('gyp baker'), startsWith('Kupferrohr'));
      expect(erst('kthesë').toLowerCase(), contains('bogen'));
      expect(erst('mufë'), startsWith('Muffe'));
      expect(erst('press'), startsWith('Pressfitting'));
      expect(erst('ventil').toLowerCase(), contains('ventil'));
      expect(erst('pompë').toLowerCase(), contains('pumpe'));
      expect(erst('bojler').toLowerCase(), anyOf(contains('speicher'), contains('boiler')));
      expect(erst('kanalizim'), anyOf(startsWith('HT'), startsWith('KG')));
    });
  });
}
