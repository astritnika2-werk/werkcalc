import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/pumpe_analyse.dart';
import 'package:werkcalc/pumpe_lauf_logik.dart' show LaufStatus;

/// Simuliertes Sensorsignal: Pumpenton (f0, Amplitude amp je Achse-Richtung), Rauschen,
/// Handzittern (3 Hz), Zeitstempel-Jitter wie bei echten Android-Sensoren.
PumpeSignal sim(math.Random r, double dauer, double fs,
    {double amp = 0, double f0 = 47, double noise = 0.05, double tremor = 0, double jit = 0.03}) {
  double gauss() {
    final u = 1 - r.nextDouble();
    final v = r.nextDouble();
    return math.sqrt(-2 * math.log(u)) * math.cos(2 * math.pi * v);
  }

  final n = (dauer * fs).round();
  final t = <double>[], x = <double>[], y = <double>[], z = <double>[];
  final ph = r.nextDouble() * 6.28, pt = r.nextDouble() * 6.28;
  var tt = 0.0;
  for (var i = 0; i < n; i++) {
    tt += (1 / fs) * (1 + jit * gauss()).clamp(0.3, 1.7);
    final s = amp * math.sin(2 * math.pi * f0 * tt + ph);
    final h = tremor * math.sin(2 * math.pi * 3 * tt + pt);
    t.add(tt);
    x.add(0.3 + 0.5 * s + h + noise * gauss());
    y.add(0.2 + 0.3 * s + 0.5 * h + noise * gauss());
    z.add(9.81 + 0.8 * s + 0.7 * h + noise * gauss());
  }
  return PumpeSignal(t: t, x: x, y: y, z: z);
}

PumpeBefund lauf(math.Random r, double fs, double amp, double noise, double tremor) {
  final ref = analysiere(sim(r, 6, fs, noise: noise));
  final probe = analysiere(sim(r, 10, fs, amp: amp, f0: 22 + r.nextDouble() * 43, noise: noise, tremor: tremor));
  return bewertePumpe(ref, probe);
}

void main() {
  final rauschen = [0.02, 0.05, 0.08];
  final zittern = [0.03, 0.15, 0.3];

  test('Pumpe EIN (≥0,1 m/s²) wird bei 150/200 Hz fast immer erkannt, nie als „steht“', () {
    final r = math.Random(11);
    for (final fs in [150.0, 200.0]) {
      var ok = 0, steht = 0;
      const n = 60;
      for (var i = 0; i < n; i++) {
        final b = lauf(r, fs, 0.1 + r.nextDouble() * 0.3, rauschen[i % 3], zittern[(i ~/ 3) % 3]);
        if (b.status == LaufStatus.laeuft) ok++;
        if (b.status == LaufStatus.steht) steht++;
      }
      expect(steht, 0, reason: 'fs=$fs');
      expect(ok, greaterThanOrEqualTo((n * 0.9).round()), reason: 'fs=$fs erkannt=$ok');
    }
  });

  test('Pumpe AUS wird nie als „läuft“ gemeldet (alle Rausch-/Zitterstufen, 100–200 Hz)', () {
    final r = math.Random(5);
    for (final fs in [100.0, 150.0, 200.0]) {
      var laeuft = 0;
      for (var i = 0; i < 60; i++) {
        final b = lauf(r, fs, 0, rauschen[i % 3], zittern[(i ~/ 3) % 3]);
        if (b.status == LaufStatus.laeuft) laeuft++;
      }
      expect(laeuft, 0, reason: 'fs=$fs');
    }
  });

  test('Pumpe AUS bei ruhiger Messung und ≥150 Hz: überwiegend „steht“', () {
    final r = math.Random(9);
    var steht = 0;
    const n = 40;
    for (var i = 0; i < n; i++) {
      final b = lauf(r, 200, 0, 0.02, 0.03);
      if (b.status == LaufStatus.steht) steht++;
    }
    expect(steht, greaterThanOrEqualTo((n * 0.8).round()), reason: 'steht=$steht');
  });

  test('Sensor mit nur 100 Hz meldet nie „steht“', () {
    final r = math.Random(21);
    for (var i = 0; i < 30; i++) {
      final b = lauf(r, 100, 0, rauschen[i % 3], 0.03);
      expect(b.status, isNot(LaufStatus.steht));
    }
  });

  test('Starkes Wackeln an der Pumpe → „nicht eindeutig“', () {
    final r = math.Random(3);
    final ref = analysiere(sim(r, 6, 200, noise: 0.03));
    final probe = analysiere(sim(r, 10, 200, noise: 0.03, tremor: 2.0));
    expect(bewertePumpe(ref, probe).status, LaufStatus.unklar);
  });

  test('Unruhige Referenz → „nicht eindeutig“', () {
    final r = math.Random(4);
    final ref = analysiere(sim(r, 6, 200, noise: 0.03, tremor: 0.6));
    final probe = analysiere(sim(r, 10, 200, amp: 0.3, noise: 0.03));
    final b = bewertePumpe(ref, probe);
    expect(b.status, LaufStatus.unklar);
    expect(b.grund, PumpeGrund.refUnruhig);
  });

  test('Zu wenige Messwerte → „nicht eindeutig“', () {
    final r = math.Random(8);
    final ref = analysiere(sim(r, 6, 200));
    final probe = analysiere(sim(r, 1, 20, amp: 0.3));
    expect(bewertePumpe(ref, probe).status, LaufStatus.unklar);
  });

  test('Erkannter Ton: Frequenz stimmt, Details gefüllt', () {
    final r = math.Random(2);
    final ref = analysiere(sim(r, 6, 200, noise: 0.03));
    final probe = analysiere(sim(r, 10, 200, amp: 0.2, f0: 50, noise: 0.03, tremor: 0.03));
    final b = bewertePumpe(ref, probe);
    expect(b.status, LaufStatus.laeuft);
    expect((b.spitzeHz! - 50).abs(), lessThanOrEqualTo(1.0));
    expect(b.persistenzAnteil, greaterThanOrEqualTo(kPersistLaeuft));
  });
}
