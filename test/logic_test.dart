import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/logic.dart';

/// Referenzwerte stammen aus tools/verify_formulas.py (fluids, iapws).
void main() {
  group('Rohre', () {
    test('Rohrinhalt: 20 mm, 10 m = 3,1416 Liter', () {
      expect(rohrInhaltLiter(20, 10), closeTo(3.14159, 0.0001));
    });

    test('Rohrinhalt: 28 mm, 10 m = 6,1575 Liter', () {
      expect(rohrInhaltLiter(28, 10), closeTo(6.15752, 0.0001));
    });

    test('Rohrlänge ist die Umkehrung des Rohrinhalts', () {
      final liter = rohrInhaltLiter(26, 37.5);
      expect(rohrLaengeM(26, liter), closeTo(37.5, 1e-9));
    });

    test('Gefälle: 10 m bei 2 % = 20 cm', () {
      expect(gefaelleHoeheCm(10, 2), closeTo(20, 1e-9));
    });
  });

  group('Einheiten', () {
    test('mm <-> Zoll', () {
      expect(mmToZoll(25.4), closeTo(1, 1e-12));
      expect(mmToZoll(28), closeTo(1.1024, 0.0001));
      expect(zollToMm(0.5), closeTo(12.7, 1e-12));
    });

    test('kW <-> BTU/h', () {
      expect(kwToBtuh(1), closeTo(3412.14, 0.01));
      expect(btuhToKw(kwToBtuh(7.5)), closeTo(7.5, 1e-9));
    });

    test('Liter <-> m3', () {
      expect(literToM3(1500), closeTo(1.5, 1e-12));
      expect(m3ToLiter(0.006), closeTo(6, 1e-12));
    });
  });

  group('Isolierung und Heizleistung', () {
    test('Isolierung: Rohr 28 mm, Dämmung 50 mm, 10 m', () {
      final i = berechneIsolierung(rohrMm: 28, daemmMm: 50, laengeM: 10);
      expect(i.aussenDurchmesserMm, closeTo(128, 1e-9));
      expect(i.umfangM, closeTo(0.4021, 0.0001));
      expect(i.oberflaecheM2, closeTo(4.02124, 0.00001));
      expect(i.volumenM3, closeTo(0.122522, 0.000001));
    });

    test('Heizleistung: 20 m2, 2,5 m, Altbau 100 W/m2 = 2000 W', () {
      expect(
        heizleistungW(flaecheM2: 20, hoeheM: 2.5, wattProM2: 100),
        closeTo(2000, 1e-9),
      );
    });

    test('Heizleistung skaliert mit der Raumhöhe', () {
      expect(
        heizleistungW(flaecheM2: 20, hoeheM: 3, wattProM2: 100),
        closeTo(2400, 1e-9),
      );
    });
  });

  group('Wasser-Stoffwerte', () {
    test('Stützstelle 60 °C (IAPWS-IF97)', () {
      final w = wasserEigenschaften(60);
      expect(w.dichte, closeTo(983.210, 0.001));
      expect(w.viskositaet, closeTo(4.740014e-7, 1e-12));
    });

    test('Interpolation zwischen 60 und 65 °C', () {
      final w = wasserEigenschaften(62.5);
      expect(w.dichte, closeTo(981.8875, 0.001));
      expect(w.viskositaet, closeTo(4.5774655e-7, 1e-12));
    });

    test('Außerhalb der Tabelle wird geklemmt', () {
      expect(wasserEigenschaften(-5).dichte, closeTo(999.844, 0.001));
      expect(wasserEigenschaften(120).dichte, closeTo(961.894, 0.001));
    });
  });

  group('Reibungsbeiwert (Colebrook-White)', () {
    test('Re 1e5, e/D 1e-4', () {
      expect(reibungsbeiwert(1e5, 1e-4), closeTo(0.0185139, 1e-6));
    });

    test('glattes Rohr, Re 1e5', () {
      expect(reibungsbeiwert(1e5, 0), closeTo(0.0179898, 1e-6));
    });

    test('Re 2e4, e/D 7,5e-5', () {
      expect(reibungsbeiwert(2e4, 7.5e-5), closeTo(0.0260471, 1e-6));
    });

    test('Re 5e5, e/D 2e-3', () {
      expect(reibungsbeiwert(5e5, 2e-3), closeTo(0.0237888, 1e-6));
    });

    test('laminar: 64 / Re', () {
      expect(reibungsbeiwert(1000, 1e-3), closeTo(0.064, 1e-12));
    });
  });

  group('Druckverlust', () {
    test('Einheiten des Volumenstroms', () {
      final ref = volumenstromZuM3s(10, 1);
      expect(ref, closeTo(10 / 60000, 1e-15));
      expect(volumenstromZuM3s(600, 2), closeTo(ref, 1e-15));
      expect(volumenstromZuM3s(0.6, 3), closeTo(ref, 1e-15));
    });

    test('Kupfer 20 mm, 10 l/min, 10 m, 60 °C', () {
      final r = berechneDruckverlust(
        volumenstromM3s: volumenstromZuM3s(10, 1),
        durchmesserMm: 20,
        laengeM: 10,
        temperaturC: 60,
        rauheitMm: 0.0015,
      );
      expect(r.geschwindigkeit, closeTo(0.5305, 0.0001));
      expect(r.reynolds, closeTo(22385, 5));
      expect(r.lambda, closeTo(0.0253561, 1e-6));
      expect(r.rPaProM, closeTo(175.415, 0.05));
      expect(r.dpRohrPa, closeTo(1754.15, 0.5));
      expect(r.dpEinzelPa, 0);
      expect(r.uebergangsbereich, isFalse);
    });

    test('mit Einzelwiderständen Σζ = 5', () {
      final r = berechneDruckverlust(
        volumenstromM3s: volumenstromZuM3s(10, 1),
        durchmesserMm: 20,
        laengeM: 10,
        temperaturC: 60,
        rauheitMm: 0.0015,
        zetaSumme: 5,
      );
      expect(r.dpEinzelPa, closeTo(691.81, 0.2));
      expect(r.dpGesamtPa, closeTo(2445.96, 0.7));
    });

    test('Kunststoff 16 mm, 5 l/min, 25 m, 10 °C', () {
      final r = berechneDruckverlust(
        volumenstromM3s: volumenstromZuM3s(5, 1),
        durchmesserMm: 16,
        laengeM: 25,
        temperaturC: 10,
        rauheitMm: 0.007,
      );
      expect(r.reynolds, closeTo(5077, 5));
      expect(r.lambda, closeTo(0.0377196, 1e-6));
      expect(r.dpGesamtPa, closeTo(5060.64, 2));
    });

    test('Stahl 26 mm, 30 l/min, 12 m, 70 °C, Σζ = 2', () {
      final r = berechneDruckverlust(
        volumenstromM3s: volumenstromZuM3s(30, 1),
        durchmesserMm: 26,
        laengeM: 12,
        temperaturC: 70,
        rauheitMm: 0.045,
        zetaSumme: 2,
      );
      expect(r.rPaProM, closeTo(424.233, 0.2));
      expect(r.dpRohrPa, closeTo(5090.80, 2));
      expect(r.dpEinzelPa, closeTo(867.18, 0.5));
      expect(r.dpGesamtPa, closeTo(5957.97, 2.5));
    });

    test('laminare Strömung 0,5 l/min, 16 mm, 10 m, 20 °C', () {
      final r = berechneDruckverlust(
        volumenstromM3s: volumenstromZuM3s(0.5, 1),
        durchmesserMm: 16,
        laengeM: 10,
        temperaturC: 20,
        rauheitMm: 0.0015,
      );
      expect(r.reynolds, closeTo(660.9, 0.5));
      expect(r.lambda, closeTo(64 / r.reynolds, 1e-12));
      expect(r.rPaProM, closeTo(5.1891, 0.01));
      expect(r.dpGesamtPa, closeTo(51.89, 0.1));
    });

    test('Übergangsbereich wird erkannt (Re 2.300 bis 4.000)', () {
      final r = berechneDruckverlust(
        volumenstromM3s: volumenstromZuM3s(2, 1),
        durchmesserMm: 12,
        laengeM: 5,
        temperaturC: 20,
        rauheitMm: 0.0015,
      );
      expect(r.reynolds, closeTo(3525, 5));
      expect(r.uebergangsbereich, isTrue);
      expect(r.dpGesamtPa, closeTo(750.78, 1.5));
    });
  });

  group('Angebot', () {
    test('MwSt. 19 %', () {
      expect(nettoZuBrutto(100, 19), closeTo(119, 1e-9));
      expect(bruttoZuNetto(119, 19), closeTo(100, 1e-9));
    });

    test('Arbeitszeit & Lohn: 8 h x 25 EUR + 30 EUR Anfahrt', () {
      final a = berechneAngebot(stunden: 8, stundenlohn: 25, anfahrt: 30);
      expect(a.netto, closeTo(230, 1e-9));
      expect(a.mwst, closeTo(43.7, 1e-9));
      expect(a.brutto, closeTo(273.7, 1e-9));
    });

    test('Arbeit + Anfahrt + Material: MwSt. nur einmal auf Netto', () {
      final a = berechneAngebot(
        stunden: 8,
        stundenlohn: 25,
        anfahrt: 30,
        materialkosten: 105,
      );
      expect(a.netto, closeTo(335, 1e-9));
      expect(a.mwst, closeTo(63.65, 1e-9));
      expect(a.brutto, closeTo(398.65, 1e-9));
    });

    test('Materialzuschlag 10 %', () {
      final a = berechneAngebot(
        stunden: 1,
        stundenlohn: 60,
        materialkosten: 100,
        materialZuschlagProzent: 10,
      );
      expect(a.material, closeTo(110, 1e-9));
      expect(a.netto, closeTo(170, 1e-9));
    });

    test('Beträge direkt (PDF-Formular)', () {
      final a = berechneAngebotAusBetraegen(
        arbeit: 200,
        anfahrt: 30,
        material: 105,
      );
      expect(a.netto, closeTo(335, 1e-9));
      expect(a.mwst, closeTo(63.65, 1e-9));
      expect(a.brutto, closeTo(398.65, 1e-9));
    });

    test('Cent-Rundung: 33,333 EUR netto', () {
      final a = berechneAngebotAusBetraegen(arbeit: 33.333);
      expect(a.netto, closeTo(33.33, 1e-9));
      expect(a.mwst, closeTo(6.33, 1e-9));
      expect(a.brutto, closeTo(39.66, 1e-9));
    });

    test('Kleinunternehmer: MwSt. 0 %', () {
      final a = berechneAngebotAusBetraegen(arbeit: 100, mwstProzent: 0);
      expect(a.mwst, 0);
      expect(a.brutto, closeTo(100, 1e-9));
    });

    test('Angebotsnummer und Datum', () {
      expect(formatAngebotsnummer(2026, 7), 'AN-2026-007');
      expect(formatAngebotsnummer(2026, 123), 'AN-2026-123');
      expect(formatDatum(DateTime(2026, 10, 3)), '03.10.2026');
    });
  });

  group('Materialliste', () {
    const liste = [
      MaterialPosition(name: 'Kupferrohr 28 mm', menge: 10, einzelpreis: 3.5),
      MaterialPosition(name: 'Isolierung 50 mm', menge: 10, einzelpreis: 2.5),
      MaterialPosition(name: 'Pressfitting 28 mm', menge: 4, einzelpreis: 3),
      MaterialPosition(name: 'Kugelhahn 1"', menge: 1, einzelpreis: 18),
      MaterialPosition(name: 'Dämmmaterial', menge: 1, einzelpreis: 15),
    ];

    test('Summe netto 105,00 EUR', () {
      expect(materialSumme(liste), closeTo(105, 1e-9));
    });

    test('MwSt. 19 % auf die Netto-Summe: 19,95 und 124,95 EUR', () {
      final a = berechneAngebotAusBetraegen(arbeit: 0, material: materialSumme(liste));
      expect(a.mwst, closeTo(19.95, 1e-9));
      expect(a.brutto, closeTo(124.95, 1e-9));
    });

    test('Positionssumme wird auf Cent gerundet', () {
      const p = MaterialPosition(name: 'x', menge: 3, einzelpreis: 0.333);
      expect(p.summe, closeTo(1.0, 1e-9));
    });

    test('JSON hin und zurück', () {
      final p = MaterialPosition.fromJson(liste[0].toJson());
      expect(p.name, 'Kupferrohr 28 mm');
      expect(p.menge, 10);
      expect(p.einzelpreis, 3.5);
    });

    test('Rohrinhalt mit Zoll-Durchmesser: 1 Zoll = 25,4 mm', () {
      expect(
        rohrInhaltLiter(zollToMm(1), 10),
        closeTo(rohrInhaltLiter(25.4, 10), 1e-12),
      );
    });
  });

  group('Formatierung', () {
    test('Deutsche Zahlen', () {
      expect(fmt(1234.5), '1.234,50');
      expect(fmt(1234567.891), '1.234.567,89');
      expect(fmt(0.5, digits: 4), '0,5000');
      expect(fmt(-12.3), '-12,30');
      expect(fmt(3412.14, digits: 0), '3.412');
    });

    test('Zahlen lesen mit Komma und Punkt', () {
      expect(parseNum('12,5'), 12.5);
      expect(parseNum('12.5'), 12.5);
      expect(parseNum('1.234,56'), 1234.56);
      expect(parseNum('1,234.56'), 1234.56);
      expect(parseNum('1.234.567,5'), 1234567.5);
      expect(parseNum('105,00'), 105.0);
      expect(parseNum(''), isNull);
      expect(parseNum('abc'), isNull);
    });

    test('Deutsche Schreibweise: 1,5 / 1.234 / 1.234,56 €', () {
      expect(parseNum('1,5'), 1.5);
      expect(parseNum('1.234'), 1234);
      expect(parseNum('12.345'), 12345);
      expect(parseNum('1.234.567'), 1234567);
      expect(parseNum('1.234,56'), 1234.56);
      expect(parseNum('1.234,56 €'), 1234.56);
      expect(parseNum('1.234,56€'), 1234.56);
      expect(parseNum(' 1 234,5 '), 1234.5);
      expect(parseNum('1\u00A0234,5'), 1234.5);
      expect(parseNum('1.000'), 1000);
      expect(parseNum('10.500'), 10500);
    });

    test('Bestehende Eingaben mit Dezimalpunkt bleiben Dezimalzahlen', () {
      expect(parseNum('12.5'), 12.5);
      expect(parseNum('1.5'), 1.5);
      expect(parseNum('0.0015'), 0.0015);
      expect(parseNum('0.123'), 0.123);
      expect(parseNum('1.2345'), 1.2345);
      expect(parseNum('.5'), 0.5);
      expect(parseNum(',5'), 0.5);
      expect(parseNum('2,50'), 2.5);
      expect(parseNum('1,234'), 1.234); // Komma ist immer das Dezimalzeichen
      expect(parseNum('1,234.56'), 1234.56);
    });

    test('Ungültige Eingaben ergeben null', () {
      for (final t in ['1,2,3', '1.2.3', '1,234,567', '--1', '1e', ',', '.', '€', '1.234,5.6', '1,2.3,4']) {
        expect(parseNum(t), isNull, reason: t);
      }
    });

    test('Dezimal-Variante für Felder ohne Tausender (Kennlinien)', () {
      expect(parseNumDezimal('1.250'), 1.25);
      expect(parseNumDezimal('2,5'), 2.5);
      expect(parseNumDezimal('1.234,56'), 1234.56);
      expect(parseNumDezimal('abc'), isNull);
    });

    test('Hinweis nur bei Punkt-Dreiergruppen', () {
      expect(zahlWirdAlsTausenderGelesen('1.234'), isTrue);
      expect(zahlWirdAlsTausenderGelesen('1.234.567'), isTrue);
      expect(zahlWirdAlsTausenderGelesen('12.5'), isFalse);
      expect(zahlWirdAlsTausenderGelesen('0.123'), isFalse);
      expect(zahlWirdAlsTausenderGelesen('1.234,5'), isFalse);
      expect(zahlWirdAlsTausenderGelesen('1234'), isFalse);
    });

    test('Rundlauf fmt → parseNum', () {
      for (final v in [0.0, 1.5, 12.34, 999.99, 1234.5, 98765.43, 1234567.89]) {
        expect(parseNum(fmt(v)), closeTo(v, 0.0051), reason: '$v');
      }
    });
  });
}
