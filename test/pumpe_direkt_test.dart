import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/pumpe_analyse.dart';
import 'package:werkcalc/pumpe_direkt.dart';

/// Strom von Sensorwerten: [pumpeAb] Sekunde, ab der die Pumpe (Ton) „anliegt“; Handzittern bis [ruheAb].
List<(double, double, double, double)> strom(math.Random r, double dauer, double fs,
    {double amp = 0, double f0 = 47, double noise = 0.03, double zittern = 0.0, double pumpeAb = 0, double pumpeBis = 1e9, double ruheAb = 0}) {
  double gauss() {
    final u = 1 - r.nextDouble();
    return math.sqrt(-2 * math.log(u)) * math.cos(2 * math.pi * r.nextDouble());
  }

  final out = <(double, double, double, double)>[];
  var t = 0.0;
  final ph = r.nextDouble() * 6.28;
  while (t < dauer) {
    t += (1 / fs) * (1 + 0.03 * gauss()).clamp(0.3, 1.7);
    final an = t >= pumpeAb && t < pumpeBis;
    final s = an ? amp * math.sin(2 * math.pi * f0 * t + ph) : 0.0;
    final h = t < ruheAb ? 1.5 * math.sin(2 * math.pi * 2.5 * t) : zittern * math.sin(2 * math.pi * 3 * t);
    out.add((t, 0.3 + 0.5 * s + h + noise * gauss(), 0.2 + 0.3 * s + 0.5 * h + noise * gauss(), 9.81 + 0.8 * s + 0.7 * h + noise * gauss()));
  }
  return out;
}

/// Spielt den Strom ab und wertet wie die App einmal pro Sekunde aus. Liefert den Zustand nach jeder Sekunde.
List<PumpeAnzeige> abspielen(List<(double, double, double, double)> s) {
  final a = DirektAuswertung();
  final out = <PumpeAnzeige>[];
  var next = 1.0;
  for (final e in s) {
    a.add(e.$1, e.$2, e.$3, e.$4);
    if (e.$1 >= next) {
      out.add(a.auswerten());
      next += 1;
    }
  }
  return out;
}

void main() {
  test('Pumpe läuft, Handy liegt sofort an: nach wenigen Sekunden 🟢, danach stabil', () {
    final r = math.Random(1);
    for (final fs in [150.0, 200.0]) {
      for (var i = 0; i < 12; i++) {
        final z = abspielen(strom(r, 14, fs, amp: 0.15, f0: 25 + r.nextDouble() * 40, noise: [0.02, 0.05][i % 2], zittern: 0.05));
        expect(z.sublist(0, 2), everyElement(PumpeAnzeige.analyse), reason: 'vor 3 s nie ein Ergebnis');
        expect(z.sublist(6), everyElement(PumpeAnzeige.laeuft), reason: 'fs=$fs i=$i: $z');
      }
    }
  });

  test('Pumpe aus: nie 🟢; ruhige Messung ab 150 Hz → 🔴', () {
    final r = math.Random(2);
    var steht = 0;
    for (var i = 0; i < 20; i++) {
      final z = abspielen(strom(r, 14, 200, noise: 0.02, zittern: 0.03));
      expect(z, isNot(contains(PumpeAnzeige.laeuft)));
      if (z.last == PumpeAnzeige.steht) steht++;
    }
    expect(steht, greaterThanOrEqualTo(17));
  });

  test('Handy wird erst nach 5 s (vorher in der Hand geschwenkt) an die laufende Pumpe gelegt', () {
    final r = math.Random(3);
    for (var i = 0; i < 8; i++) {
      final z = abspielen(strom(r, 20, 200, amp: 0.15, f0: 30 + i * 4.0, noise: 0.03, pumpeAb: 5, ruheAb: 5));
      expect(z, isNot(contains(PumpeAnzeige.steht)), reason: 'beim Schwenken nie 🔴: $z');
      expect(z.sublist(0, 4), isNot(contains(PumpeAnzeige.laeuft)));
      expect(z.last, PumpeAnzeige.laeuft, reason: '$z');
    }
  });

  test('Pumpe wird während der Messung abgeschaltet: Anzeige wechselt auf 🔴 und nie auf 🟢 danach', () {
    final r = math.Random(4);
    final z = abspielen(strom(r, 24, 200, amp: 0.15, noise: 0.02, zittern: 0.03, pumpeBis: 8));
    expect(z[7], PumpeAnzeige.laeuft);
    expect(z.last, PumpeAnzeige.steht, reason: '$z');
  });

  test('Nur 100-Hz-Sensor: nie 🔴 (nur unsicher, höchstens 🟢 bei erkanntem Ton)', () {
    final r = math.Random(5);
    for (var i = 0; i < 10; i++) {
      final z = abspielen(strom(r, 16, 100, noise: 0.03, zittern: 0.03));
      expect(z, isNot(contains(PumpeAnzeige.steht)));
      expect(z, isNot(contains(PumpeAnzeige.laeuft)));
    }
  });

  test('Dauerhaft nicht eindeutig (starkes Wackeln): nach 14 s „nicht eindeutig“, nie 🟢/🔴', () {
    final r = math.Random(6);
    final z = abspielen(strom(r, 24, 200, noise: 0.03, zittern: 2.5));
    expect(z, everyElement(anyOf(PumpeAnzeige.analyse, PumpeAnzeige.unklar)));
    expect(z.last, PumpeAnzeige.unklar);
  });

  test('Direktbewertung eines Fensters: Ton gefunden, Frequenz stimmt', () {
    final r = math.Random(7);
    final s = strom(r, 6, 200, amp: 0.2, f0: 50, noise: 0.03);
    final sig = PumpeSignal(t: [for (final e in s) e.$1], x: [for (final e in s) e.$2], y: [for (final e in s) e.$3], z: [for (final e in s) e.$4]);
    final b = bewertePumpeDirekt(analysiere(sig));
    expect(b.spitzeHz! - 50, inInclusiveRange(-1.0, 1.0));
    expect(b.text, kTextDirektLaeuft);
  });
}
