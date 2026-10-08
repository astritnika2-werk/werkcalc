import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/pumpe_direkt.dart' show PumpeAnzeige;
import 'package:werkcalc/pumpe_schnell.dart';

typedef Probe = (double, double, double, double);

List<Probe> laden(String datei) {
  final m = jsonDecode(File('test/fixtures/$datei').readAsStringSync()) as Map<String, dynamic>;
  final t = (m['t'] as List).cast<num>(), x = (m['x'] as List).cast<num>();
  final y = (m['y'] as List).cast<num>(), z = (m['z'] as List).cast<num>();
  return [for (var i = 0; i < t.length; i++) (t[i].toDouble(), x[i].toDouble(), y[i].toDouble(), z[i].toDouble())];
}

class Gauss {
  Gauss(int seed) : r = math.Random(seed);
  final math.Random r;
  double call() => math.sqrt(-2 * math.log(1 - r.nextDouble())) * math.cos(2 * math.pi * r.nextDouble());
}

double quant(double v, [double q = 0.0047]) => (v / q).roundToDouble() * q;

/// Ruhiges Sensorsignal (Schwerkraft + Rauschen, quantisiert wie der echte Sensor).
List<Probe> ruhe(Gauss g, double ab, double dauer, {double fs = 476, double noise = 0.01, double hand = 0, bool bursts = false}) {
  final out = <Probe>[];
  var t = ab;
  var burstBis = -1.0;
  while (t < ab + dauer) {
    t += (1 / fs) * (1 + 0.03 * g()).clamp(0.3, 1.7);
    if (bursts && t > burstBis + 1.5 && g.r.nextDouble() < 0.002) burstBis = t + 0.1 + 0.4 * g.r.nextDouble();
    final b = t < burstBis ? 1.0 : 0.0;
    final h = hand * (math.sin(2 * math.pi * 2.5 * t) + 0.6 * math.sin(2 * math.pi * 6.1 * t + 1));
    out.add((t, quant(0.3 + h + noise * g() + b * g()), quant(0.2 + 0.5 * h + noise * g() + b * g()), quant(9.6 + 0.7 * h + noise * g() + b * g())));
  }
  return out;
}

/// Spielt ab und wertet wie die App (alle 0,25 s) aus. Liefert (Zeit, Zustand, signalVerloren).
List<(double, PumpeAnzeige, bool)> abspielen(List<Probe> s) {
  final a = SchnellAuswertung();
  final out = <(double, PumpeAnzeige, bool)>[];
  var next = 0.25;
  for (final e in s) {
    a.add(e.$1, e.$2, e.$3, e.$4);
    if (e.$1 - s.first.$1 >= next) {
      a.auswerten();
      out.add((e.$1, a.anzeige, a.signalVerloren));
      next += 0.25;
    }
  }
  return out;
}

double? ersteZeit(List<(double, PumpeAnzeige, bool)> z, PumpeAnzeige a) {
  for (final e in z) {
    if (e.$2 == a) return e.$1;
  }
  return null;
}

void main() {
  const pumpen = {
    'ups_32_80_ein_gehaeuse.json': ('Grundfos UPS 32-80 180 – EIN – am Gehäuse', 5.0),
    'alpha2_32_60_ein_gehaeuse.json': ('Grundfos ALPHA2 32-60 180 – EIN – am Gehäuse', 8.0),
    'magna3_50_60_ein_gehaeuse.json': ('Grundfos MAGNA3 50-60 F 240 – EIN – am Gehäuse', 4.5),
  };

  for (final e in pumpen.entries) {
    test('echte Aufnahme ${e.value.$1}: 🟢 schnell und danach stabil', () {
      final z = abspielen(laden(e.key));
      final t = ersteZeit(z, PumpeAnzeige.laeuft);
      expect(t, isNotNull, reason: 'nie grün');
      expect(t!, lessThanOrEqualTo(e.value.$2), reason: 'erstes Grün bei $t s (inkl. Handauflegen)');
      final danach = z.where((x) => x.$1 > t).map((x) => x.$2);
      expect(danach, everyElement(PumpeAnzeige.laeuft), reason: 'nach dem ersten Grün wieder gewechselt');
    });
  }

  test('Handy weg von der Pumpe (MAGNA3-Aufnahme, dann nur Ruhe): erst 🟡 Signal verloren, dann 🔴', () {
    final s = laden('magna3_50_60_ein_gehaeuse.json');
    final ende = s.last.$1;
    final z = abspielen([...s, ...ruhe(Gauss(7), ende, 16, noise: 0.01)]);
    final nach = z.where((x) => x.$1 > ende).toList();
    expect(nach.any((x) => x.$2 == PumpeAnzeige.analyse && x.$3), isTrue, reason: 'keine gelbe „Signal verloren“-Phase');
    final rot = ersteZeit(nach, PumpeAnzeige.steht);
    expect(rot, isNotNull, reason: 'nie rot');
    expect(rot! - ende, greaterThan(6.0), reason: 'Rot nicht verzögert: ${rot - ende} s');
    expect(nach.where((x) => x.$1 > ende + 9).map((x) => x.$2), everyElement(PumpeAnzeige.steht));
    // zwischen Grün und Rot nie wieder Grün
    final ersteNichtGruen = nach.indexWhere((x) => x.$2 != PumpeAnzeige.laeuft);
    expect(nach.sublist(ersteNichtGruen).any((x) => x.$2 == PumpeAnzeige.laeuft), isFalse);
  });

  test('Handy weit weg (Signal der MAGNA3 auf 2 % abgeschwächt, Rauschen bleibt): nicht grün', () {
    final s = laden('magna3_50_60_ein_gehaeuse.json');
    final mx = s.map((e) => e.$2).reduce((a, b) => a + b) / s.length;
    final my = s.map((e) => e.$3).reduce((a, b) => a + b) / s.length;
    final mz = s.map((e) => e.$4).reduce((a, b) => a + b) / s.length;
    final g = Gauss(11);
    final w = [for (final e in s) (e.$1, quant(mx + 0.02 * (e.$2 - mx) + 0.01 * g()), quant(my + 0.02 * (e.$3 - my) + 0.01 * g()), quant(mz + 0.02 * (e.$4 - mz) + 0.01 * g()))];
    expect(abspielen(w).map((x) => x.$2), isNot(contains(PumpeAnzeige.laeuft)));
  });

  test('simulierte Pumpenlinie (47 Hz, Oberwelle) am Gehäuse: 🟢 innerhalb weniger Sekunden', () {
    final g = Gauss(3);
    final s = ruhe(g, 0, 12, noise: 0.01);
    final w = [for (final e in s) (e.$1, e.$2 + 0.03 * math.sin(2 * math.pi * 47 * e.$1), e.$3 + 0.02 * math.sin(2 * math.pi * 47 * e.$1), e.$4 + 0.03 * math.sin(2 * math.pi * 47 * e.$1) + 0.015 * math.sin(2 * math.pi * 94 * e.$1))];
    final t = ersteZeit(abspielen(w), PumpeAnzeige.laeuft);
    expect(t, isNotNull);
    expect(t!, lessThan(4.5));
  });

  group('niemals Grün ohne Pumpe (simuliert, quantisierter Sensor)', () {
    for (var seed = 0; seed < 4; seed++) {
      test('Ruhe/Rauschen seed $seed', () {
        final g = Gauss(100 + seed);
        for (final n in [0.002, 0.01, 0.03]) {
          expect(abspielen(ruhe(g, 0, 40, noise: n)).map((x) => x.$2), isNot(contains(PumpeAnzeige.laeuft)), reason: 'noise $n');
        }
      });
      test('Handbewegung seed $seed', () {
        final g = Gauss(200 + seed);
        expect(abspielen(ruhe(g, 0, 40, hand: 0.4)).map((x) => x.$2), isNot(contains(PumpeAnzeige.laeuft)));
      });
      test('Stöße/Klopfen seed $seed', () {
        final g = Gauss(300 + seed);
        expect(abspielen(ruhe(g, 0, 40, noise: 0.01, bursts: true)).map((x) => x.$2), isNot(contains(PumpeAnzeige.laeuft)));
      });
    }
  });

  test('Ruhe: nach 8 s ohne Linie 🔴, vorher nicht', () {
    final z = abspielen(ruhe(Gauss(5), 0, 14, noise: 0.01));
    expect(z.where((x) => x.$1 < 7.5).map((x) => x.$2), isNot(contains(PumpeAnzeige.steht)));
    expect(z.last.$2, PumpeAnzeige.steht);
  });
}
