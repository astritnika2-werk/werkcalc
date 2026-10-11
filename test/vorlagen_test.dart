import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:werkcalc/katalog.dart';
import 'package:werkcalc/materialliste.dart';
import 'package:werkcalc/materialliste_store.dart';
import 'package:werkcalc/vorlagen.dart';

Iterable<VorlagenPosten> alle(Vorlage v, Map<String, String> p) sync* {
  for (final z in v.zonenMit(p)) {
    yield* z.posten;
    for (final m in z.modi) {
      yield* m.posten;
    }
  }
}

Vorlage vorlage(String name) => kVorlagen.firstWhere((v) => v.name == name);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final katalog = baueKatalog();
  final namen = {for (final a in katalog) a.name};

  test('fünf Vorlagen', () {
    expect(kVorlagen.map((v) => v.name), [
      'Heizkörper austauschen', 'Waschbecken montieren', 'WC montieren',
      'Wasserleitung verlegen', 'Badsanierung',
    ]);
  });

  test('jeder Artikelname der Vorlagen 1, 2, 3, 5 ist ein exakter Katalogname', () {
    final fehlend = <String>[];
    for (final n in ['Heizkörper austauschen', 'Waschbecken montieren', 'WC montieren', 'Badsanierung']) {
      for (final p in alle(vorlage(n), {})) {
        for (final v in p.varianten) {
          if (!namen.contains(v)) fehlend.add('$n: $v');
        }
      }
    }
    expect(fehlend, isEmpty);
  });

  test('Vorlage 4: alle Namen für alle Durchmesser beider Werkstoffe existieren (Kugelhahn nur Ø15–35)', () {
    final v = vorlage('Wasserleitung verlegen');
    final fehlend = <String>[];
    for (final (werkstoff, ds) in [(kWerkstoffKupfer, kKupferDurchmesser), (kWerkstoffEdelstahl, kEdelstahlDurchmesser)]) {
      for (final d in ds) {
        final p = {'werkstoff': werkstoff, 'durchmesser': '$d'};
        final posten = alle(v, p).toList();
        expect(posten, isNotEmpty);
        for (final x in posten) {
          for (final n in x.varianten) {
            if (!namen.contains(n)) fehlend.add('$werkstoff Ø$d: $n');
          }
          if (x.label == 'Kugelhahn Press') {
            expect(x.varianten.isNotEmpty, kKugelhahnPressDurchmesser.contains(d), reason: 'Kugelhahn Ø$d');
          }
        }
      }
    }
    expect(fehlend, isEmpty);
    expect(kKugelhahnPressDurchmesser, [15, 18, 22, 28, 35]);
  });

  test('Vorlage 4: ungültige Kombination liefert nichts; kein Mehrschichtverbund/PE-X', () {
    final v = vorlage('Wasserleitung verlegen');
    expect(v.zonenMit({}), isEmpty);
    expect(v.zonenMit({'werkstoff': kWerkstoffEdelstahl, 'durchmesser': '12'}), isEmpty);
    expect(v.zonenMit({'werkstoff': 'PE-X', 'durchmesser': '16'}), isEmpty);
    expect(v.parameter[0].optionen({}), [kWerkstoffKupfer, kWerkstoffEdelstahl]);
    final alleNamen = [
      for (final w in [kWerkstoffKupfer, kWerkstoffEdelstahl])
        for (final d in (w == kWerkstoffKupfer ? kKupferDurchmesser : kEdelstahlDurchmesser))
          for (final x in alle(v, {'werkstoff': w, 'durchmesser': '$d'})) ...x.varianten,
    ];
    expect(alleNamen.where((n) => n.contains('Mehrschicht') || n.contains('PE-X') || n.contains('PE-RT')), isEmpty);
    // Kupfer-Fittings erscheinen nur bei Kupfer, Edelstahl-Fittings nur bei Edelstahl
    for (final x in alle(v, {'werkstoff': kWerkstoffKupfer, 'durchmesser': '22'})) {
      expect(x.varianten.where((n) => n.contains('(Edelstahl)')), isEmpty);
    }
    for (final x in alle(v, {'werkstoff': kWerkstoffEdelstahl, 'durchmesser': '22'})) {
      expect(x.varianten.where((n) => n.contains('(Kupfer)')), isEmpty);
    }
  });

  test('Heizkörper: Typ, Höhe, Länge nur aus real vorhandenen Katalogartikeln', () {
    final k = kompaktheizkoerperKombinationen(namen);
    expect(k.keys, containsAll(['10', '11', '21', '22', '33']));
    for (final e in k.entries) {
      for (final h in e.value.entries) {
        for (final l in h.value) {
          expect(namen, contains(kompaktheizkoerperName(e.key, h.key, l)));
        }
      }
    }
    expect(vorlage('Heizkörper austauschen').zonen.first.posten.first.heizkoerper, isTrue);
  });

  test('Heizkörper: Anschlussset und Einzelteile sind Alternativen', () {
    final z = vorlage('Heizkörper austauschen').zonen.firstWhere((z) => z.name == 'Anschluss');
    expect(z.modi.map((m) => m.label), ['Einzelteile', 'Set']);
    expect(z.posten, isEmpty);
    expect(z.modi[1].posten.single.status, VorlagenStatus.situativ);
    expect(z.modi[1].posten.single.varianten, ['Heizkörper-Anschlussset']);
  });

  test('Waschbecken: Ablaufgarnitur nur die 3 realen Katalogvarianten', () {
    final p = vorlage('Waschbecken montieren').zonen.expand((z) => z.posten).firstWhere((p) => p.label == 'Ablaufgarnitur Waschtisch');
    expect(p.varianten.toSet(), {
      'Ablaufgarnitur Waschtisch mit Überlauf', 'Ablaufgarnitur Waschtisch ohne Überlauf',
      'Ablaufgarnitur Waschtisch Push-Open',
    });
  });

  test('WC: Vorwandelement, Drückerplatte, Spülkasten situativ; Anschlussbogen DN 90 und DN 100', () {
    final posten = vorlage('WC montieren').zonen.expand((z) => z.posten).toList();
    for (final l in ['Vorwandelement WC', 'Drückerplatte', 'Spülkasten']) {
      expect(posten.firstWhere((p) => p.label == l).status, VorlagenStatus.situativ);
    }
    expect(posten.firstWhere((p) => p.label == 'WC-Anschlussbogen').varianten.toSet(),
        {'WC-Anschlussbogen DN 90', 'WC-Anschlussbogen DN 100'});
  });

  test('Badsanierung: 8 Zonen, Dusche/Wanne als Alternativen, Abdichtung nur Verfügbares', () {
    final z = vorlage('Badsanierung').zonen;
    expect(z.map((e) => e.name), [
      'WC', 'Waschtisch', 'Dusche oder Wanne', 'Heizung', 'Abdichtung', 'Montage', 'Anschlüsse', 'Fugen',
    ]);
    expect(z[2].modi.map((m) => m.label), ['Dusche', 'Wanne']);
    expect(z[2].posten, isEmpty);
    final abd = z[4];
    expect(abd.posten.expand((p) => p.varianten).toSet(), {
      'Verbundabdichtung Dusche', 'Dichtband Wand/Boden', 'Dichtband selbstklebend', 'Dichtmanschette Bodenablauf',
    });
    expect(abd.nichtVerfuegbar, ['Abdichtungsgrundierung', 'Dichtschlämme', 'Abdichtmanschetten für Wand/Rohr']);
    for (final n in abd.nichtVerfuegbar) {
      expect(namen.where((k) => k.toLowerCase().contains(n.toLowerCase().split(' ').first)), isEmpty,
          reason: '$n darf nicht im Katalog sein, sonst Text anpassen');
    }
  });

  group('Auswahl und Speichern', () {
    test('Menge: leer = nicht ausgewählt, 0/negativ = Fehler, unbekannter Name = Fehler', () {
      final r = pruefeAuswahl([
        (name: 'Thermostatkopf', menge: 2),
        (name: 'Hanf Zopf 100 g', menge: null),
        (name: 'Dübel 8 mm', menge: 0),
        (name: 'Erfundener Artikel', menge: 1),
      ], namen);
      expect(r.auswahl.map((a) => a.name), ['Thermostatkopf']);
      expect(r.fehler.length, 2);
    });

    test('Struktur: keine Standardmengen und keine Preise in den Vorlagen', () {
      // Die Datenklassen haben weder Mengen- noch Preisfelder; Mengen kommen nur vom Nutzer.
      for (final v in kVorlagen) {
        for (final p in alle(v, {'werkstoff': kWerkstoffKupfer, 'durchmesser': '22'})) {
          expect(p.varianten.every((n) => namen.contains(n)), isTrue);
        }
      }
    });

    test('Vorlage legt NEUE Baustelle an; bestehende Baustellen bleiben unverändert', () async {
      final alt = [
        Baustelle(
          id: 'a', name: 'Müllerstraße', erstellt: DateTime.fromMillisecondsSinceEpoch(1760000000000),
          artikel: const [ListenArtikel(id: 'a-0', name: 'Thermostatkopf', menge: 3, einheit: 'Stk.')],
        ),
      ];
      final vorher = jsonEncode([for (final b in alt) b.toJson()]);
      SharedPreferences.setMockInitialValues({'materiallisten_v1': vorher});
      final s = MaterialListenStore.fuerTest();
      await s.laden();
      final neu = await vorlageAlsNeueBaustelle(s, 'Bad Test', const [
        VorlagenAuswahl('Thermostatkopf', 2),
        VorlagenAuswahl('Hanf Zopf 100 g', 1.5),
      ]);
      expect(s.listen.length, 2);
      expect(neu.id, isNot('a'));
      final b = s.finde(neu.id)!;
      expect(b.name, 'Bad Test');
      expect(b.artikel.map((x) => (x.name, x.menge)), [('Thermostatkopf', 2.0), ('Hanf Zopf 100 g', 1.5)]);
      final a = s.finde('a')!;
      expect(jsonEncode(a.toJson()), jsonEncode(alt.first.toJson()));
    });
  });
}
