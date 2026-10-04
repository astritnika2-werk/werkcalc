import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/wasserwaage_logik.dart';

// Synthetische Vektoren aus bekannter Neigung (keine echten Messdaten).
({double x, double y, double z}) vec(double rollDeg, double pitchDeg) {
  const g = 9.81;
  final sx = math.tan(rollDeg * math.pi / 180), sy = math.tan(pitchDeg * math.pi / 180);
  final z = g / math.sqrt(1 + sx * sx + sy * sy);
  return (x: z * sx, y: z * sy, z: z);
}

void main() {
  test('flach = 0', () {
    final v = vec(0, 0);
    final n = berechneNeigung(v.x, v.y, v.z);
    expect(n.gesamtGrad, closeTo(0, 1e-9));
    expect(n.prozent, closeTo(0, 1e-9));
    expect(n.flach, true);
  });
  test('1 Grad rechts hoch: Prozent und mm/m', () {
    final v = vec(1, 0);
    final n = berechneNeigung(v.x, v.y, v.z);
    expect(n.rollGrad, closeTo(1, 1e-6));
    expect(n.pitchGrad, closeTo(0, 1e-6));
    expect(n.prozent, closeTo(1.7455, 1e-3));
    expect(n.mmProM, closeTo(17.455, 1e-2));
  });
  test('2 Prozent Gefälle vorne hoch', () {
    final grad = math.atan(0.02) * 180 / math.pi;
    final v = vec(0, grad);
    final n = berechneNeigung(v.x, v.y, v.z);
    expect(n.pitchGrad, closeTo(grad, 1e-6));
    expect(n.prozent, closeTo(2.0, 1e-6));
    expect(n.mmProM, closeTo(20.0, 1e-5));
  });
  test('Kalibrierung zieht Referenz ab', () {
    final proben = [for (var i = 0; i < 30; i++) vec(0.8, -0.4)];
    final k = kalibriere(proben)!;
    expect(k.roll0, closeTo(0.8, 1e-6));
    expect(k.pitch0, closeTo(-0.4, 1e-6));
    expect(k.streuungGrad, closeTo(0, 1e-9));
    final v = vec(0.8, -0.4);
    final n = berechneNeigung(v.x, v.y, v.z, roll0: k.roll0, pitch0: k.pitch0);
    expect(n.gesamtGrad, closeTo(0, 1e-6));
  });
  test('Kalibrierung mit Bewegung hat große Streuung', () {
    final proben = [for (var i = 0; i < 30; i++) vec(i.isEven ? 1.5 : -1.5, 0)];
    expect(kalibriere(proben)!.streuungGrad, greaterThan(kKalibrierMaxStreuung));
  });
  test('Display unten oder zu wenige Proben', () {
    expect(berechneNeigung(0, 0, -9.81).flach, false);
    expect(kalibriere([vec(0, 0)]), isNull);
  });

  group('Blasenposition (Display: x rechts, y nach unten)', () {
    test('links höher → Blase nach links', () {
      final p = blasenPosition(-3, 0);
      expect(p.dx, lessThan(0));
      expect(p.dy, 0);
    });
    test('rechts höher → Blase nach rechts', () {
      expect(blasenPosition(3, 0).dx, greaterThan(0));
    });
    test('vorne höher → Blase nach oben', () {
      final p = blasenPosition(0, 3);
      expect(p.dy, lessThan(0));
      expect(p.dx, 0);
    });
    test('hinten höher → Blase nach unten', () {
      expect(blasenPosition(0, -3).dy, greaterThan(0));
    });
    test('Sensor: linke Kante angehoben → Blase links', () {
      // linke Kante hoch ⇒ Beschleunigung x negativ
      final n = berechneNeigung(-0.5, 0, 9.8);
      expect(blasenPosition(n.rollGrad, n.pitchGrad).dx, lessThan(0));
    });
    test('Sensor: Vorderkante angehoben → Blase oben', () {
      final n = berechneNeigung(0, 0.5, 9.8);
      expect(blasenPosition(n.rollGrad, n.pitchGrad).dy, lessThan(0));
    });
  });
}
