import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/katalog.dart';
import 'package:werkcalc/materialliste.dart';
import 'package:werkcalc/produkt_bild.dart';

void main() {
  final katalog = baueKatalog();

  List<String> namen(String q, {int n = 8}) =>
      sucheKatalog(q, katalog, limit: n > 60 ? n : 60).artikel.take(n).map((a) => a.name).toList();

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
      expect(namen('press 22', n: 500), contains('Pressfitting T-Stück Ø22 (Edelstahl)'));
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

  group('Fittings-Varianten und Karten', () {
    final k = baueKatalog();
    final namen = {for (final a in k) a.name};

    test('Namen sind eindeutig', () {
      expect(namen.length, k.length);
    });

    test('Varianten, die es nicht gibt, fehlen', () {
      for (final n in const [
        'Kupferbogen 45° A/A Ø22',
        'Pressfitting Bogen 90° A/A Ø22 (Kupfer)',
        'Gewindefitting Winkel 45° AG/AG 1" (Edelstahl)',
        'PP-R Wandwinkel Ø110 × 3" Innengewinde',
        'HT-Bogen 15° DN 32',
        'Gewindefitting Muffe IG/IG 4" (Messing)',
      ]) {
        expect(namen, isNot(contains(n)), reason: n);
      }
    });

    test('Kupfer Ø22: alle gewünschten Varianten vorhanden', () {
      for (final n in const [
        'Kupferbogen 45° I/I Ø22', 'Kupferbogen 45° I/A Ø22',
        'Kupferbogen 90° I/I Ø22', 'Kupferbogen 90° I/A Ø22', 'Kupferbogen 90° A/A Ø22',
        'Kupferbogen 90° mit Innengewinde Ø22 × ¾"', 'Kupferbogen 90° mit Außengewinde Ø22 × ¾"',
        'T-Stück Kupfer Ø22', 'Reduzierung Kupfer 28 × 22', 'Muffe Kupfer Ø22',
        'Übergang Kupfer Ø22 × ¾" Innengewinde', 'Übergang Kupfer Ø22 × ¾" Außengewinde',
        'Verschraubung Kupfer Ø22',
      ]) {
        expect(namen, contains(n), reason: n);
      }
    });

    test('gleiche Logik für Edelstahl, Stahl, Mehrschicht, Kunststoff', () {
      for (final n in const [
        'Pressfitting Bogen 45° I/I Ø22 (Edelstahl)', 'Pressfitting Bogen 90° I/A Ø22 (C-Stahl)',
        'Pressfitting Bogen 90° I/A Ø26 (Mehrschicht)', 'Pressfitting Reduzierung 28 × 22 (Edelstahl)',
        'Pressfitting Übergang Ø22 × ¾" Außengewinde (Kupfer)',
        'Gewindefitting Winkel 90° IG/AG ¾" (verzinkt)', 'Gewindefitting Winkel 45° IG/AG 1" (Edelstahl)',
        'Schweißbogen 90° lange Ausführung DN 50 (Stahl)', 'PP-R Winkel 90° Ø25',
        'PVC-U Winkel 45° Ø50', 'HT-Abzweig 45° DN 100/100', 'KG-Abzweig 87° DN 160/110',
      ]) {
        expect(namen, contains(n), reason: n);
      }
    });

    test('„bogen 22“: Kupferbögen zuerst, alle Varianten einzeln', () {
      final r = sucheKatalog('bogen 22', k, limit: 60);
      final top = r.artikel.take(8).map((a) => a.name).toList();
      expect(top.every((n) => n.startsWith('Kupferbogen')), isTrue, reason: '$top');
      expect(r.artikel.map((a) => a.name), contains('Kupferbogen 90° I/I Ø22'));
      expect(r.artikel.map((a) => a.name), contains('Kupferbogen 45° I/I Ø22'));
    });

    test('Karte: Werkstoff, Maß und Art', () {
      final a = k.firstWhere((x) => x.name == 'Kupferbogen 90° I/I Ø22');
      expect(a.werkstoffAnzeige, 'Kupfer');
      expect(a.massAnzeige, '22 mm');
      expect(a.artAnzeige, 'Bogen 90° I/I');
      expect(a.kurzInfo, 'Kupfer · 22 mm · Bogen 90° I/I');
      final r = k.firstWhere((x) => x.name == 'Reduzierung Kupfer 28 × 22');
      expect(r.massAnzeige, '28 × 22 mm');
    });

    test('Jeder Artikel hat Karte und Skizze', () {
      for (final a in k) {
        expect(a.kurzInfo, isA<String>());
        expect(bildInfo(a).art, isA<BildArt>());
      }
    });

    test('Skizze: Winkel und Enden', () {
      KatalogArtikel f(String n) => k.firstWhere((x) => x.name == n);
      final b = bildInfo(f('Kupferbogen 45° I/A Ø22'));
      expect(b.art, BildArt.bogen);
      expect(b.winkel, 45);
      expect(b.ende1, EndeArt.innen);
      expect(b.ende2, EndeArt.aussen);
      final g = bildInfo(f('Gewindefitting Winkel 90° IG/AG ¾" (verzinkt)'));
      expect(g.ende1, EndeArt.innengewinde);
      expect(g.ende2, EndeArt.aussengewinde);
      expect(bildInfo(f('T-Stück Kupfer Ø22')).art, BildArt.tstueck);
      expect(bildInfo(f('Muffe Kupfer Ø22')).art, BildArt.muffe);
      expect(bildInfo(f('Reduzierung Kupfer 28 × 22')).art, BildArt.reduzierung);
    });
  });

  group('Foto oder Skizze, Handelsdaten', () {
    final k = baueKatalog();

    test('Skizze für alle genannten Produktgruppen', () {
      const erwartet = <String, BildArt>{
        'WC wandhängend Tiefspüler': BildArt.wc,
        'Waschtisch 60 cm': BildArt.waschtisch,
        'Waschtischarmatur Einhebelmischer': BildArt.armatur,
        'Umwälzpumpe Hocheffizienz 25-40': BildArt.pumpe,
        'Warmwasserspeicher 100 l': BildArt.speicher,
        'Absperrventil ½"': BildArt.ventil,
        'HT-Rohr DN 50': BildArt.rohr,
        'HT-Bogen 87° DN 100': BildArt.bogen,
      };
      erwartet.forEach((name, art) {
        final a = k.firstWhere((x) => x.name == name, orElse: () => throw 'fehlt: $name');
        expect(bildInfo(a).art, art, reason: name);
      });
    });

    test('Suchbegriffe der Gruppen liefern Skizzen statt Platzhalter', () {
      const gruppen = <String, BildArt>{
        'wc-sitz': BildArt.wcSitz,
        'spülkasten': BildArt.spuelkasten,
        'vorwandelement': BildArt.vorwand,
        'siphon': BildArt.siphon,
        'heizkörper': BildArt.heizkoerper,
        'thermostat': BildArt.thermostat,
        'ausdehnungsgefäß': BildArt.ausdehnung,
        'wärmetauscher': BildArt.waermetauscher,
        'wärmepumpe': BildArt.waermepumpe,
        'klimagerät': BildArt.klimageraet,
        'lüftungsgerät': BildArt.lueftungsgeraet,
        'rohrschelle': BildArt.schelle,
        'badewanne': BildArt.wanne,
      };
      gruppen.forEach((q, art) {
        final r = sucheKatalog(q, k, limit: 200).artikel;
        expect(r, isNotEmpty, reason: q);
        expect(r.any((a) => bildInfo(a).art == art), isTrue, reason: q);
      });
    });

    test('Ohne Foto: Skizze; Foto-Schlüssel und Handelsdaten vorhanden', () {
      final a = k.first;
      expect(a.foto, isEmpty);
      expect(a.hersteller, isEmpty);
      expect(a.preis, isNull);
      expect(fotoSlug('Kupferbogen 90° I/I Ø22'), 'kupferbogen_90_i_i_o22');
      final b = KatalogArtikel(name: 'Test X', einheit: 'Stk.', ean: '4012345678901', artikelnummer: 'AB-12');
      expect(b.fotoSchluessel, ['4012345678901', 'ab_12', 'test_x']);
    });

    test('JSON ergänzt Hersteller, Artikelnummer, EAN, Foto, Preis, Händler, Lager', () {
      const roh = '''[
        {"name": "Kupferbogen 90° I/I Ø22", "hersteller": "Musterwerk", "artikelnummer": "KB-2290",
         "ean": "4012345678901", "foto": "assets/produkte/kb.jpg", "preis": 3.4,
         "grosshaendler": "Beispiel GmbH", "lagerbestand": 120, "details": {"Norm": "EN 1254-1"}},
        {"name": "Neuer Testartikel Ø99", "einheit": "m", "material": "Kupfer"}
      ]''';
      final basis = katalogAnreichern(k, roh);
      final a = basis.firstWhere((x) => x.name == 'Kupferbogen 90° I/I Ø22');
      expect(a.hersteller, 'Musterwerk');
      expect(a.artikelnummer, 'KB-2290');
      expect(a.ean, '4012345678901');
      expect(a.foto, 'assets/produkte/kb.jpg');
      expect(a.preis, 3.4);
      expect(a.grosshaendler, 'Beispiel GmbH');
      expect(a.lagerbestand, 120);
      expect(a.details['Norm'], 'EN 1254-1');
      expect(a.massAnzeige, '22 mm'); // Katalogdaten bleiben erhalten
      expect(basis.length, k.length);
      final neu = katalogAusJson(roh, vorhandeneNamen: {for (final x in k) x.name});
      expect(neu.map((x) => x.name), ['Neuer Testartikel Ø99']);
      // Suche findet auch über Hersteller, Artikelnummer und EAN.
      expect(sucheKatalog('musterwerk', basis).artikel.first.name, 'Kupferbogen 90° I/I Ø22');
      expect(sucheKatalog('KB-2290', basis).artikel.first.name, 'Kupferbogen 90° I/I Ø22');
      expect(sucheKatalog('4012345678901', basis).artikel.first.name, 'Kupferbogen 90° I/I Ø22');
    });
  });
}
