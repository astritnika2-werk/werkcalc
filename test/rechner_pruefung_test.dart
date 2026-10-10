import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/logic.dart';
import 'package:werkcalc/rechner_pruefung.dart';

void main() {
  group('Fehlermeldungen statt allgemeinem Hinweis', () {
    test('Rohrinhalt: Null und fehlende Werte', () {
      expect(pruefeRohrinhalt([0, 1, 5]), contains('Durchmesser muss größer als 0'));
      expect(pruefeRohrinhalt([20, 1, 0]), contains('Länge muss größer als 0'));
      expect(pruefeRohrinhalt([20, 1, 10]), isNull);
    });
    test('Gefälle', () {
      expect(pruefeGefaelle([null, 5, null, 2]), contains('Durchmesser'));
      expect(pruefeGefaelle([20, null, null, 2]), contains('Rohrlänge'));
      expect(pruefeGefaelle([null, null, 0, 2]), contains('Rohrlänge muss größer als 0'));
      expect(pruefeGefaelle([null, null, 10, null]), contains('Gefälle'));
      expect(pruefeGefaelle([null, null, 10, 2]), isNull);
      expect(pruefeGefaelle([20, 3, null, 2]), isNull);
    });
    test('Isolierung und Heizkörper', () {
      expect(pruefeIsolierung([0, 20, 5]), contains('Rohrdurchmesser'));
      expect(pruefeIsolierung([22, 0, 5]), isNull); // 0 mm Dämmung ist rechnerisch möglich
      expect(pruefeHeizkoerper([0, 2.5, 100]), contains('Raumgröße'));
      expect(pruefeHeizkoerper([20, 0, 100]), contains('Raumhöhe'));
      expect(pruefeHeizkoerper([20, 2.5, 100]), isNull);
    });
    test('Druckverlust', () {
      expect(pruefeDruckverlust([null, 1, 20, 10]), contains('Volumenstrom'));
      expect(pruefeDruckverlust([0, 1, 20, 10]), contains('Volumenstrom muss größer'));
      expect(pruefeDruckverlust([10, 1, 0, 10]), contains('Innendurchmesser'));
      expect(pruefeDruckverlust([10, 1, 20, null]), contains('Rohrlänge'));
      expect(pruefeDruckverlust([10, 1, 20, 10]), isNull);
    });
    test('Pumpe wählen', () {
      // v: Q, kW, ΔT, d, L
      expect(prueferPumpe([null, null, null, 20, 50]), contains('Volumenstrom eingeben'));
      expect(prueferPumpe([0, null, null, 20, 50]), contains('Volumenstrom muss größer'));
      expect(prueferPumpe([null, 10, 0, 20, 50]), contains('Spreizung'));
      expect(prueferPumpe([null, 0, 20, 20, 50]), contains('Heizleistung'));
      expect(prueferPumpe([1.2, null, null, 0, 50]), contains('Innendurchmesser'));
      expect(prueferPumpe([1.2, null, null, 20, null]), contains('Rohrlänge'));
      expect(prueferPumpe([1.2, null, null, 20, 50]), isNull);
      expect(prueferPumpe([null, 10, 20, 20, 50]), isNull);
      expect(prueferPumpe([0, 10, 20, 20, 50]), isNull); // Q=0 → Leistung/ΔT zählt
    });
    test('MwSt. und Arbeitszeit', () {
      expect(pruefeMwst([null, null, 19]), isNotNull);
      expect(pruefeMwst([100, null, 19]), isNull);
      expect(pruefeArbeitszeit([null, 50, 0, 19]), contains('Stunden'));
      expect(pruefeArbeitszeit([2, null, 0, 19]), contains('Stundenlohn'));
      expect(pruefeArbeitszeit([2, 50, 0, 19]), isNull);
    });
    test('Einfelder', () {
      expect(pruefeEinFeld([null, null]), isNotNull);
      expect(pruefeEinFeld([null, 3]), isNull);
    });
  });

  group('Formeln gegen unabhängige Handrechnung', () {
    test('Rohrinhalt: Ø20 mm, 10 m = π·(0,01 m)²·10 m = 3,1416 l', () {
      expect(rohrInhaltLiter(20, 10), closeTo(math.pi * 0.01 * 0.01 * 10 * 1000, 1e-9));
      expect(rohrInhaltLiter(20, 10), closeTo(3.14159, 1e-4));
    });
    test('Rohrlänge ist die Umkehrung des Rohrinhalts', () {
      for (final d in [10.0, 22.0, 54.0, 100.0]) {
        expect(rohrLaengeM(d, rohrInhaltLiter(d, 7.5)), closeTo(7.5, 1e-9));
      }
    });
    test('Gefälle: 2 % auf 10 m = 20 cm', () {
      expect(gefaelleHoeheCm(10, 2), closeTo(20, 1e-9));
      expect(gefaelleHoeheCm(0, 2), 0);
    });
    test('Isolierung: Ø22 + 2·20 mm Dämmung', () {
      final i = berechneIsolierung(rohrMm: 22, daemmMm: 20, laengeM: 10);
      expect(i.aussenDurchmesserMm, closeTo(62, 1e-9));
      expect(i.umfangM, closeTo(math.pi * 0.062, 1e-9));
    });
    test('Einheiten', () {
      expect(mmToZoll(25.4), closeTo(1, 1e-12));
      expect(zollToMm(0.5), closeTo(12.7, 1e-12));
      expect(kwToBtuh(1), closeTo(3412.14, 0.01));
      expect(btuhToKw(kwToBtuh(12.34)), closeTo(12.34, 1e-9));
      expect(literToM3(1500), closeTo(1.5, 1e-12));
      expect(m3ToLiter(0.25), closeTo(250, 1e-9));
    });
    test('MwSt. und Angebot (auf Cent)', () {
      expect(nettoZuBrutto(100, 19), closeTo(119, 1e-9));
      expect(nettoZuBrutto(100, 7), closeTo(107, 1e-9));
      expect(bruttoZuNetto(119, 19), closeTo(100, 1e-9));
      expect(nettoZuBrutto(100, 0), closeTo(100, 1e-9));
      final a = berechneAngebot(stunden: 2, stundenlohn: 50, anfahrt: 20, mwstProzent: 19);
      expect(a.netto, closeTo(120, 1e-9));
      expect(a.mwst, closeTo(22.8, 1e-9));
      expect(a.brutto, closeTo(142.8, 1e-9));
    });
    test('Druckverlust: Einzelwiderstand = ζ·ρ·v²/2', () {
      final r = berechneDruckverlust(
        volumenstromM3s: 0.0003,
        durchmesserMm: 20,
        laengeM: 10,
        temperaturC: 20,
        rauheitMm: 0.0015,
        zetaSumme: 5,
      );
      final rho = wasserEigenschaften(20).dichte;
      expect(r.dpEinzelPa, closeTo(5 * rho * r.geschwindigkeit * r.geschwindigkeit / 2, 1e-6));
      final v = 0.0003 / (math.pi * 0.01 * 0.01);
      expect(r.geschwindigkeit, closeTo(v, 1e-9));
      expect(r.dpGesamtPa, closeTo(r.dpRohrPa + r.dpEinzelPa, 1e-6));
    });
    test('Druckverlust steigt mit dem Volumenstrom (turbulent, ~Q^1,75…2)', () {
      double dp(double q) => berechneDruckverlust(
              volumenstromM3s: q, durchmesserMm: 20, laengeM: 10, temperaturC: 20, rauheitMm: 0.0015, zetaSumme: 0)
          .dpRohrPa;
      final f = dp(0.0006) / dp(0.0003);
      expect(f, inInclusiveRange(3.0, 4.2));
    });
    test('Nullwerte erzeugen kein NaN/Infinity', () {
      expect(rohrInhaltLiter(0, 10), 0);
      expect(rohrInhaltLiter(20, 0), 0);
      expect(gefaelleHoeheCm(10, 0), 0);
    });
  })

  test('Rohrrauheit: Verbundrohr (k = 0,007 mm) hat mehr Rohrreibung als 0,0015 mm', () {
    double r(double k) => berechneDruckverlust(
            volumenstromM3s: 0.0003, durchmesserMm: 20, laengeM: 10, temperaturC: 60, rauheitMm: k)
        .rPaProM;
    expect(r(0.007), greaterThan(r(0.0015)));
    expect(r(0.007), lessThan(r(0.0015) * 1.3));
  });
}
