import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/pumpe_lauf_logik.dart';

// Synthetische Testsignale (keine echten Pumpendaten).
List<double> sig(double amp, int n, {double base = 0, double f = 0.9}) {
  final r = math.Random(1);
  return [
    for (var i = 0; i < n; i++)
      base + amp * math.sin(i * f) + 0.0005 * (r.nextDouble() - .5)
  ];
}

void main() {
  final ref = LaufMessung(acc: sig(0.004, 300, base: 0.02), mag: sig(0.1, 300, base: 45));
  test('laeuft bei starkem Signal beider Sensoren', () {
    final p = LaufMessung(acc: sig(0.08, 300, base: 0.1), mag: sig(1.5, 300, base: 48));
    expect(bewerteLauf(ref, p).status, LaufStatus.laeuft);
  });
  test('steht bei Signal wie Referenz', () {
    final p = LaufMessung(acc: sig(0.004, 300, base: 0.02), mag: sig(0.1, 300, base: 45));
    expect(bewerteLauf(ref, p).status, LaufStatus.steht);
  });
  test('unklar bei nur schwachem Signal', () {
    final p = LaufMessung(acc: sig(0.03, 300, base: 0.03), mag: sig(0.2, 300, base: 45));
    expect(bewerteLauf(ref, p).status, LaufStatus.unklar);
  });
  test('unklar bei Handbewegung', () {
    final p = LaufMessung(acc: sig(0.08, 300, base: 1.0), mag: sig(1.5, 300, base: 48));
    expect(bewerteLauf(ref, p).status, LaufStatus.unklar);
  });
  test('unklar bei zu wenigen Werten', () {
    final p = LaufMessung(acc: sig(0.08, 50), mag: sig(1.5, 50));
    expect(bewerteLauf(ref, p).status, LaufStatus.unklar);
  });
  test('unklar bei unruhiger Referenz', () {
    final r2 = LaufMessung(acc: sig(0.1, 300, base: 0.1), mag: sig(0.1, 300, base: 45));
    expect(bewerteLauf(r2, ref).status, LaufStatus.unklar);
  });
}
