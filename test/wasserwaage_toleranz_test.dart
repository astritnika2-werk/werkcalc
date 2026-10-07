import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/wasserwaage_logik.dart';

const g = 9.80665;

/// Beschleunigung für ein Handy, das flach liegt und um [a]° um die Y- bzw. [b]° um die X-Achse geneigt ist.
(double, double, double) vec(double a, double b) {
  final ra = a * math.pi / 180, rb = b * math.pi / 180;
  return (g * math.sin(ra), g * math.sin(rb), g * math.cos(ra) * math.cos(rb));
}

void main() {
  test('flach (0°/0°): 0,00° und „Waagerecht“', () {
    final v = vec(0, 0);
    final n = berechneNeigung(v.$1, v.$2, v.$3);
    expect(zahl(n.aGrad), '0,00');
    expect(zahl(n.bGrad), '0,00');
    expect(richtungsText(n), 'Waagerecht');
  });

  test('Sensorrauschen ±0,02 m/s² um flach bleibt in der Toleranz', () {
    final r = math.Random(1);
    for (var i = 0; i < 500; i++) {
      final nx = (r.nextDouble() - 0.5) * 0.04, ny = (r.nextDouble() - 0.5) * 0.04;
      final n = berechneNeigung(nx, ny, g);
      expect(richtungsText(n), 'Waagerecht', reason: 'x=$nx y=$ny a=${n.aGrad} b=${n.bGrad}');
    }
  });

  test('Toleranzgrenze 0,2°: 0,15° waagerecht, 0,3° nicht', () {
    expect(imToleranzbereich(0.15), isTrue);
    expect(imToleranzbereich(-0.2), isTrue);
    expect(imToleranzbereich(0.3), isFalse);
    expect(imToleranzbereich(-0.5), isFalse);
  });

  test('Neigung ändert die Anzeige in allen vier Richtungen: Gradzahl stimmt, Richtung stimmt', () {
    for (final t in [0.5, 1.0, 2.0, 5.0]) {
      final r = vec(t, 0);
      final l = vec(-t, 0);
      final h = vec(0, t);
      final v = vec(0, -t);
      expect(berechneNeigung(r.$1, r.$2, r.$3).aGrad, closeTo(t, 0.02));
      expect(berechneNeigung(l.$1, l.$2, l.$3).aGrad, closeTo(-t, 0.02));
      expect(berechneNeigung(h.$1, h.$2, h.$3).bGrad, closeTo(t, 0.02));
      expect(berechneNeigung(v.$1, v.$2, v.$3).bGrad, closeTo(-t, 0.02));
      for (final w in [r, l, h, v]) {
        expect(richtungsText(berechneNeigung(w.$1, w.$2, w.$3)), isNot('Waagerecht'), reason: 'Neigung $t°');
      }
    }
  });

  test('Eine Achse in Toleranz, die andere nicht: nur die abweichende wird genannt', () {
    final w = vec(0.1, 1.0);
    final t = richtungsText(berechneNeigung(w.$1, w.$2, w.$3));
    expect(t.split(',').length, 1);
  });

  test('Linie (Display vorne, Y senkrecht): 0,1° waagerecht, 1° nicht; Richtung stimmt', () {
    double rad(double d) => d * math.pi / 180;
    final a = berechneLinie(Modus.linieDisplay, g * math.sin(rad(0.1)), g * math.cos(rad(0.1)), 0);
    expect(linienRichtung(a), 'Waagerecht');
    final b = berechneLinie(Modus.linieDisplay, g * math.sin(rad(1)), g * math.cos(rad(1)), 0);
    expect(linienRichtung(b), 'Rechts höher');
    final c = berechneLinie(Modus.linieDisplay, -g * math.sin(rad(1)), g * math.cos(rad(1)), 0);
    expect(linienRichtung(c), 'Links höher');
  });
}
