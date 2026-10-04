// Digitale Anzeige: Marker-Position kommt linear aus denselben Messwerten.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/wasserwaage_logik.dart';
import 'package:werkcalc/wasserwaage_page.dart';

void main() {
  group('1D-Skala', () {
    test('0° → genau Mitte', () => expect(skalaAnteil(0), 0));
    test('links = negativ, rechts = positiv', () {
      expect(skalaAnteil(-2.5), -0.5);
      expect(skalaAnteil(2.5), 0.5);
      expect(skalaAnteil(-5), -1);
      expect(skalaAnteil(5), 1);
    });
    test('linear', () => expect(skalaAnteil(1.0), closeTo(0.2, 1e-12)));
    test('außerhalb bleibt am Rand', () {
      expect(skalaAnteil(12), 1);
      expect(skalaAnteil(-40), -1);
    });
    test('Vorzeichen wie die Messung (alle Linien-Betriebsarten)', () {
      // rechts höher: Messwert positiv, Marker rechts
      final r = berechneLinie(Modus.linieDisplay, 0.5, 9.78, 0.3);
      expect(skalaAnteil(r.grad), greaterThan(0));
      final l = berechneLinie(Modus.linieLinks, 9.78, 0.5, 0.3); // Oberkante höher → links höher
      expect(skalaAnteil(l.grad), lessThan(0));
      final rr = berechneLinie(Modus.linieRechts, -9.78, 0.5, 0.3);
      expect(skalaAnteil(rr.grad), greaterThan(0));
    });
  });

  group('2D-Fläche', () {
    test('X 0 / Y 0 → Mitte', () {
      final p = flaechenAnteil(0, 0);
      expect(p.x, 0);
      expect(p.y, 0);
      expect(p.ausserhalb, false);
    });
    test('rechts/links/vorne/hinten und diagonal', () {
      expect(flaechenAnteil(2.5, 0).x, 0.5);
      expect(flaechenAnteil(-2.5, 0).x, -0.5);
      expect(flaechenAnteil(0, 2.5).y, 0.5); // vorne höher → oben
      expect(flaechenAnteil(0, -2.5).y, -0.5);
      final d = flaechenAnteil(-1.0, 2.0);
      expect(d.x, closeTo(-0.2, 1e-12));
      expect(d.y, closeTo(0.4, 1e-12));
    });
    test('außerhalb: Richtung bleibt, Rand erreicht', () {
      final p = flaechenAnteil(10, 5);
      expect(p.ausserhalb, true);
      expect(p.x, 1);
      expect(p.y, closeTo(0.5, 1e-12));
    });
    test('Fläche: Messwerte → Markerseite', () {
      final b = berechneNeigung(0.5, 0.0, 9.8, lage: Modus.flaeche.lage); // rechts höher
      expect(flaechenAnteil(b.aGrad, b.bGrad).x, greaterThan(0));
      final v = berechneNeigung(0.0, 0.5, 9.8, lage: Modus.flaeche.lage); // vorne höher
      expect(flaechenAnteil(v.aGrad, v.bGrad).y, greaterThan(0));
    });
  });

  test('Anzeige zeichnet ohne Fehler (alle Zustände)', () {
    for (final n in <Neigung?>[
      null,
      berechneNeigung(0, 0, 9.81, lage: Modus.flaeche.lage),
      berechneNeigung(0.4, -0.3, 9.8, lage: Modus.flaeche.lage),
      berechneNeigung(4, 2, 9.0, lage: Modus.flaeche.lage),
    ]) {
      final rec = PictureRecorder();
      final c = Canvas(rec);
      FlaechePainter(neigung: n).paint(c, const Size(360, 360));
      rec.endRecording();
    }
    for (final (g, a) in [(0.0, true), (-3.3, true), (7.0, true), (0.0, false)]) {
      final rec = PictureRecorder();
      SkalaPainter(grad: g, aktiv: a).paint(Canvas(rec), const Size(360, 120));
      rec.endRecording();
    }
  });
}
