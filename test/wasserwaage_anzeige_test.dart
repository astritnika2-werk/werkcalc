// Digitale Anzeige: Marker-Position kommt linear aus denselben Messwerten.
import 'dart:math' as math;
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

  group('Anzeige-Beruhigung (nur Darstellung)', () {
    test('Ruhe: Anzeige = Messwert exakt (kein Versatz, kein Einfrieren)', () {
      final f = AnzeigeFilter();
      for (var i = 0; i < 300; i++) {
        f.update(0.31, -0.22, 9.78, 0.033);
      }
      expect(f.x, closeTo(0.31, 1e-9));
      expect(f.y, closeTo(-0.22, 1e-9));
      expect(f.z, closeTo(9.78, 1e-9));
    });
    test('folgt einer Änderung: nach tau rund 63 %, danach vollständig', () {
      final f = AnzeigeFilter();
      f.update(0, 0, 9.81, 0.033);
      var t = 0.0;
      while (t < kAnzeigeTau - 1e-9) {
        f.update(1.0, 0, 9.81, 0.033);
        t += 0.033;
      }
      expect(f.x, inInclusiveRange(0.55, 0.75));
      for (var i = 0; i < 300; i++) {
        f.update(1.0, 0, 9.81, 0.033);
      }
      expect(f.x, closeTo(1.0, 1e-6));
    });
    test('Rauschen wird um mehr als ein Drittel kleiner', () {
      final rnd = math.Random(7);
      final f = AnzeigeFilter();
      f.update(0, 0, 9.81, 0.033);
      var roh = 0.0, geglaettet = 0.0;
      const n = 3000;
      for (var i = 0; i < n; i++) {
        final r = (rnd.nextDouble() - 0.5) * 0.4;
        f.update(r, 0, 9.81, 0.033);
        roh += r * r;
        geglaettet += f.x * f.x;
      }
      expect(math.sqrt(geglaettet / n), lessThan(math.sqrt(roh / n) * 0.67));
    });
    test('Glättung ist beschränkt (reagiert weiter flüssig): 95 % nach rund 3 tau', () {
      final f = AnzeigeFilter();
      f.update(0, 0, 9.81, 0.033);
      var t = 0.0;
      while (t < 3 * kAnzeigeTau) {
        f.update(1.0, 0, 9.81, 0.033);
        t += 0.033;
      }
      expect(f.x, greaterThan(0.93));
      expect(t, lessThan(0.9)); // ≈ 3 × 0,279 s: Anzeige absichtlich um 30 % langsamer
    });
    test('Zahlen und Marker kommen aus demselben geglätteten Vektor', () {
      final f = AnzeigeFilter();
      for (var i = 0; i < 200; i++) {
        f.update(0.5, 9.78, 0.3, 0.033);
      }
      final l = berechneLinie(Modus.linieDisplay, f.x, f.y, f.z);
      final roh = berechneLinie(Modus.linieDisplay, 0.5, 9.78, 0.3);
      expect(l.grad, closeTo(roh.grad, 1e-9));
      expect(skalaAnteil(l.grad), closeTo(skalaAnteil(roh.grad), 1e-9));
    });
  });
}
