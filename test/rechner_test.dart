import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/katalog.dart';
import 'package:werkcalc/logic.dart';

void main() {
  final namen = {for (final a in baueKatalog()) a.name};

  group('Pumpe wählen (Richtwert)', () {
    test('Volumenstrom aus Leistung und ΔT', () {
      // 10 kW, ΔT 20 K: etwa 0,44 m³/h
      final v = volumenstromAusLeistung(10, 20);
      expect(v, inInclusiveRange(0.42, 0.46));
    });

    test('kleine Anlage: DN 25, kleine Förderhöhe', () {
      final a = berechnePumpe(
        heizleistungKw: 10,
        deltaTK: 20,
        durchmesserMm: 20,
        laengeM: 60,
      )!;
      // ignore: avoid_print
      print('V=${a.volumenstromM3h} v=${a.geschwindigkeit} H=${a.foerderhoeheM} typ=${a.typ}');
      expect(a.dn, 25);
      expect(a.typ, '25-40');
      expect(a.foerderhoeheM, greaterThan(0));
      expect(a.foerderhoeheM, lessThan(2));
    });

    test('höhere Widerstände → größere Pumpe', () {
      final klein = berechnePumpe(volumenstromM3h: 1.5, durchmesserMm: 26, laengeM: 40)!;
      final gross = berechnePumpe(
        volumenstromM3h: 1.5,
        durchmesserMm: 26,
        laengeM: 40,
        zusatzMbar: 300,
      )!;
      expect(gross.foerderhoeheM, greaterThan(klein.foerderhoeheM + 2.5));
      expect(gross.typ, isNot(klein.typ));
    });

    test('Volumenstrom 4 m³/h → DN 32, über 6 m³/h → keine Standardpumpe', () {
      expect(berechnePumpe(volumenstromM3h: 4, durchmesserMm: 40, laengeM: 20)!.dn, 32);
      final gross = berechnePumpe(volumenstromM3h: 8, durchmesserMm: 54, laengeM: 20)!;
      expect(gross.dn, isNull);
      expect(gross.typ, isNull);
      expect(gross.hinweis, isNotNull);
    });

    test('ohne Volumenstrom und ohne Leistung kein Ergebnis', () {
      expect(berechnePumpe(durchmesserMm: 20, laengeM: 10), isNull);
    });

    test('alle Pumpen-Vorschläge gibt es im Katalog', () {
      kPumpenTypen.forEach((dn, typen) {
        final g = kPumpenGewinde[dn]!;
        for (final t in typen) {
          for (final n in [
            'Umwälzpumpe Hocheffizienz ${t.$1}',
            'Pumpenverschraubung $g',
            'Kugelhahn $g IG/IG',
            'Flachdichtung Fiber $g',
          ]) {
            expect(namen, contains(n), reason: n);
          }
        }
      });
      expect(namen, contains('Pumpenisolierschale Heizung'));
    });

    test('Vorschläge für Heizkörper und Isolierung gibt es im Katalog', () {
      for (final n in const [
        'Thermostatkopf',
        'Thermostatventil gerade ½"',
        'Rücklaufverschraubung gerade ½"',
        'Heizkörper-Entlüfter ½"',
        'Isolierung Ø22',
      ]) {
        expect(namen, contains(n), reason: n);
      }
    });
  });
}
