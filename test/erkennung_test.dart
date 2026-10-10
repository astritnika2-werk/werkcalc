import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/erkennung.dart';
import 'package:werkcalc/katalog.dart';
import 'package:werkcalc/materialliste.dart';

void main() {
  final katalog = baueKatalog();
  final namenImKatalog = {for (final a in katalog) a.name};

  String zeige(List<ErkanntePosition> l) => [
        for (final p in l)
          '${formatMenge(p.menge)} | ${p.suche} | ${p.sicherheit.name} | ${p.gewaehlt?.name}',
      ].join('\n');

  group('Abschnitte', () {
    test('Komma, Zeilen, und', () {
      expect(
        teileAbschnitte('20 m Kupferrohr 22, 12 Bogen\n8 Muffen und 2 Ventile'),
        ['20 m Kupferrohr 22', '12 Bogen', '8 Muffen', '2 Ventile'],
      );
    });

    test('Dezimalkomma bleibt', () {
      expect(teileAbschnitte('2,5 m Rohr'), ['2.5 m Rohr']);
    });

    test('Sprache ohne Kommas: neue Position bei neuer Menge', () {
      expect(
        teileAbschnitte('20 Meter Kupferrohr 22 12 Bogen 90 Grad I/I 8 Muffen 22'),
        ['20 Meter Kupferrohr 22', '12 Bogen 90 Grad I/I', '8 Muffen 22'],
      );
    });

    test('Zahlwörter', () {
      expect(teileAbschnitte('zwanzig Meter Kupferrohr 22 zwölf Bogen'), ['zwanzig Meter Kupferrohr 22', 'zwölf Bogen']);
    });
  });

  group('Zahlen aus kopiertem Text', () {
    test('Tausenderpunkt und Dezimalpunkt', () {
      expect(erkenneText('1.000 Muffen 22', katalog).first.menge, 1000);
      expect(erkenneText('2.5 m Kupferrohr 22', katalog).first.menge, 2.5);
      expect(erkenneText('20 m Kupferrohr 22', katalog).first.menge, 20);
    });
  });

  group('Erkennung', () {
    test('Beispiel des Nutzers', () {
      final r = erkenneText(
        '20 Meter Kupferrohr 22, 12 Bogen 90 Grad I/I, 8 Muffen 22.',
        katalog,
      );
      // ignore: avoid_print
      print(zeige(r));
      expect(r.length, 3);
      expect(r[0].menge, 20);
      expect(r[1].menge, 12);
      expect(r[2].menge, 8);
      expect(r[0].gewaehlt!.name, contains('Kupferrohr'));
      expect(r[0].gewaehlt!.name, contains('22'));
      expect(r[1].gewaehlt!.name, contains('90° I/I'));
      expect(r[2].gewaehlt!.name, contains('Muffe'));
    });

    test('nur Katalogartikel, nie neue', () {
      final r = erkenneText(
        '5 Stk Kupferrohr 22\nfliegender Teppich 3000\n3 Pressfitting Muffe 22',
        katalog,
      );
      // ignore: avoid_print
      print(zeige(r));
      for (final p in r) {
        if (p.gewaehlt != null) expect(namenImKatalog, contains(p.gewaehlt!.name));
        for (final t in p.treffer) {
          expect(namenImKatalog, contains(t.name));
        }
      }
      final teppich = r.firstWhere((p) => p.suche.contains('teppich'));
      expect(teppich.sicherheit, Sicherheit.keiner);
      expect(teppich.gewaehlt, isNull);
      expect(teppich.aktiv, isFalse);
    });

    test('ohne Menge: 1 angenommen, markiert', () {
      final r = erkenneText('Kupferrohr 22', katalog);
      expect(r.single.menge, 1);
      expect(r.single.mengeAngegeben, isFalse);
    });

    test('Menge hinten', () {
      final r = erkenneText('Kupferrohr 22 - 20 m', katalog);
      expect(r.single.menge, 20);
    });

    test('mehrdeutig ist nicht vorab aktiv', () {
      final r = erkenneText('12 Bogen 90 I/I', katalog);
      expect(r.single.sicherheit, Sicherheit.mehrere);
      expect(r.single.aktiv, isFalse);
      expect(r.single.treffer, isNotEmpty);
    });
  });
}
