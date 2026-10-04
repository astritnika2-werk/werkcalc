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
  gueteTests();
  qualitaetTests();
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

void gueteTests() {
  test('Signalguete nach Abtastrate', () {
    expect(signalGuete(100), SignalGuete.gut);
    expect(signalGuete(50), SignalGuete.mittel);
    expect(signalGuete(10), SignalGuete.schwach);
  });
}

void qualitaetTests() {
  List<double> s(double amp, int n, {double base = 0}) =>
      [for (var i = 0; i < n; i++) base + amp * math.sin(i * 0.9)];
  test('Referenz mit sehr starker Schwankung (1,09 m/s2) ist nicht stabil', () {
    final unruhig = LaufMessung(acc: s(1.5, 300, base: 0.3), mag: s(0.3, 300, base: 45));
    final st = bewerteReferenz(unruhig);
    expect(st.stabil, false);
    expect(st.grund, LaufGrund.refUnruhig);
    expect(st.text, kTextRefUnruhig);
  });
  test('Bewertung mit unruhiger Referenz liefert unklar mit Grund', () {
    final unruhig = LaufMessung(acc: s(1.5, 300, base: 0.3), mag: s(0.3, 300, base: 45));
    final probe = LaufMessung(acc: s(0.01, 300), mag: s(0.1, 300, base: 45));
    final e = bewerteLauf(unruhig, probe);
    expect(e.status, LaufStatus.unklar);
    expect(e.grundTyp, LaufGrund.refUnruhig);
  });
  test('Kennwerte', () {
    final k = kennwerte([1, 2, 3, 4]);
    expect(k.n, 4);
    expect(k.mittel, 2.5);
    expect(k.min, 1);
    expect(k.max, 4);
    expect(k.streuung, closeTo(1.118, 0.001));
    expect(k.rms, closeTo(2.7386, 0.001));
  });
  test('Vergleichbarkeit nach Abtastrate', () {
    final a = LaufMessung(acc: s(0.01, 600), mag: s(0.1, 300), dauerMs: 6000);
    final b = LaufMessung(acc: s(0.01, 80), mag: s(0.1, 80), dauerMs: 8000);
    expect(vergleichbar(a, b), false);
    expect(vergleichbar(a, a), true);
  });
}
