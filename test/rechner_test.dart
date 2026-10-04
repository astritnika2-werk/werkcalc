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

    test('Volumenstrom: Prüfwerte, kleineres ΔT → mehr Volumenstrom', () {
      expect(volumenstromAusLeistung(20, 20), inInclusiveRange(0.86, 0.87));
      expect(volumenstromAusLeistung(30, 20), inInclusiveRange(1.28, 1.30));
      expect(volumenstromAusLeistung(20, 10), inInclusiveRange(1.71, 1.73));
      expect(volumenstromAusLeistung(20, 30), inInclusiveRange(0.56, 0.58));
      expect(volumenstromAusLeistung(10, 20), inInclusiveRange(0.42, 0.46));
      expect(volumenstromAusLeistung(20, 10), greaterThan(volumenstromAusLeistung(20, 20)));
    });

    test('Test 1: 10 kW, ΔT 20, Ø22, 100 m, Σζ 10', () {
      final a = berechnePumpe(
        heizleistungKw: 10,
        deltaTK: 20,
        durchmesserMm: 22,
        laengeM: 100,
        zetaSumme: 10,
      )!;
      expect(a.volumenstromM3h * 1000 / 60, inInclusiveRange(7.0, 7.7));
      expect(a.foerderhoeheM, greaterThan(0.3));
      expect(a.foerderhoeheM, lessThan(1.5));
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

    test('Empfohlener Bereich: Min ≤ Empfehlung ≤ Max', () {
      final a = berechnePumpe(
        heizleistungKw: 20,
        deltaTK: 20,
        durchmesserMm: 25,
        laengeM: 60,
        zetaSumme: 20,
        zusatzMbar: 150,
      )!;
      // ignore: avoid_print
      print('Praxis: V=${a.volumenstromM3h} H=${a.foerderhoeheM} ${a.typMin}/${a.typ}/${a.typMax}');
      expect(a.typ, isNotNull);
      final namen = kPumpenTypen[a.dn]!.map((t) => t.$1).toList();
      final iMin = namen.indexOf(a.typMin!);
      final iEmp = namen.indexOf(a.typ!);
      final iMax = namen.indexOf(a.typMax!);
      expect(iMin <= iEmp, isTrue);
      expect(iEmp <= iMax, isTrue);
    });

    test('keine Standardpumpe → kein Bereich', () {
      final a = berechnePumpe(volumenstromM3h: 8, durchmesserMm: 54, laengeM: 20)!;
      expect(a.typMin, isNull);
      expect(a.typMax, isNull);
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
