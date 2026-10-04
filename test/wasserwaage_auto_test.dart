// Automatische Umschaltung der Betriebsart, getestet mit simulierten Sensorwerten
// (Rauschen, GravityFilter wie in der App). Keine echte Hardware.
import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/wasserwaage_auto.dart';
import 'package:werkcalc/wasserwaage_logik.dart';

import 'wasserwaage_sim_test.dart' hide main;

final Map<String, Modus?> erwartet = {
  'flach (Display oben)': Modus.flaeche,
  'vertikal aufrecht': Modus.linieDisplay,
  'linke Seite': Modus.linieLinks,
  'rechte Seite': Modus.linieRechts,
  'flach (Display unten)': null,
  'vertikal kopfüber': null,
};

Vek vek(M r) {
  final u = aufDevice(r);
  return (x: u[0] * g, y: u[1] * g, z: u[2] * g);
}

/// Simuliert eine Folge von Lagen mit Rauschen, Filter (100 Hz) und Umschalter (alle 33 ms).
class Lauf {
  Lauf(M start, Modus modus) : umschalter = ModusUmschalter(modus) {
    r = start;
  }
  final ModusUmschalter umschalter;
  final GravityFilter filter = GravityFilter();
  late M r;
  final List<(double, Modus)> wechsel = [];
  double zeit = 0;
  int _schritt = 0;

  void schritt(M pose, {V? omega}) {
    final u = aufDevice(pose);
    filter.update(
      ax: u[0] * g + gauss(accRauschen),
      ay: u[1] * g + gauss(accRauschen),
      az: u[2] * g + gauss(accRauschen),
      dt: 0.01,
      gx: (omega?[0] ?? 0) + gauss(gyroRauschen),
      gy: (omega?[1] ?? 0) + gauss(gyroRauschen),
      gz: (omega?[2] ?? 0) + gauss(gyroRauschen),
    );
    zeit += 0.01;
    _schritt++;
    if (_schritt % 3 == 0) {
      final neu = umschalter.update(filter.x, filter.y, filter.z, 0.03);
      if (neu != null) wechsel.add((zeit, neu));
    }
  }

  void ruhe(M pose, double sekunden) {
    for (var i = 0; i < (sekunden * 100).round(); i++) {
      schritt(pose);
    }
    r = pose;
  }

  /// Dreht von [start] um [achse] um [grad] in [sekunden] (sanfte Bewegung).
  M dreh(M start, V achse, double grad, double sekunden) {
    final n = (sekunden * 100).round();
    M pose = start;
    for (var i = 1; i <= n; i++) {
      final s = i / n;
      pose = mul(rodrigues(achse, grad * s * 3.141592653589793 / 180), start);
      schritt(pose);
    }
    r = pose;
    return pose;
  }
}

void main() {
  group('erkenneLage: eindeutige Lage', () {
    for (final b in basis.entries) {
      test('${b.key} → ${erwartet[b.key]?.name ?? 'keine'}', () {
        final v = vek(b.value);
        expect(erkenneLage(v.x, v.y, v.z), erwartet[b.key]);
      });
    }
    test('stimmt mit lageStimmt überein', () {
      for (final b in basis.entries) {
        final v = vek(b.value);
        final m = erkenneLage(v.x, v.y, v.z);
        if (m != null) expect(lageStimmt(m, v.x, v.y, v.z), true);
      }
    });
    test('Neigung bis 20° in alle Richtungen ändert die Erkennung nicht', () {
      for (final b in basis.entries) {
        for (final d in [west, ost, nord, sued]) {
          final v = vek(mul(anheben(d, 20), b.value));
          expect(erkenneLage(v.x, v.y, v.z), erwartet[b.key], reason: '${b.key} $d');
        }
      }
    });
    test('Diagonale Neigung 14°+14° bleibt erkannt', () {
      for (final b in basis.entries) {
        final v = vek(mul(anheben(ost, 14), mul(anheben(nord, 14), b.value)));
        expect(erkenneLage(v.x, v.y, v.z), erwartet[b.key]);
      }
    });
    test('dazwischen (45°) und stark geneigt (40°): keine eindeutige Lage', () {
      final flach = basis['flach (Display oben)']!;
      for (final grad in [40.0, 45.0, 50.0]) {
        final v = vek(mul(anheben(nord, grad), flach));
        expect(erkenneLage(v.x, v.y, v.z), isNull, reason: '$grad°');
      }
    });
    test('Nullvektor: keine Lage', () => expect(erkenneLage(0, 0, 0), isNull));
  });

  group('ModusUmschalter: Verzögerung und Stabilität', () {
    test('neue Lage 1 s stabil → genau ein Wechsel nach ca. 0,8 s', () {
      final u = ModusUmschalter(Modus.flaeche);
      final v = vek(basis['vertikal aufrecht']!);
      Modus? neu;
      var t = 0.0;
      while (neu == null && t < 3) {
        neu = u.update(v.x, v.y, v.z, 0.033);
        t += 0.033;
      }
      expect(neu, Modus.linieDisplay);
      expect(t, inInclusiveRange(0.8, 1.0));
      expect(u.aktuell, Modus.linieDisplay);
      // danach kein weiterer Wechsel
      for (var i = 0; i < 100; i++) {
        expect(u.update(v.x, v.y, v.z, 0.033), isNull);
      }
    });
    test('kurze Lage (0,5 s) löst nichts aus', () {
      final u = ModusUmschalter(Modus.flaeche);
      final seite = vek(basis['linke Seite']!);
      final flach = vek(basis['flach (Display oben)']!);
      for (var i = 0; i < 15; i++) {
        expect(u.update(seite.x, seite.y, seite.z, 0.033), isNull);
      }
      for (var i = 0; i < 100; i++) {
        expect(u.update(flach.x, flach.y, flach.z, 0.033), isNull);
      }
      expect(u.aktuell, Modus.flaeche);
    });
    test('Flackern zwischen zwei Lagen löst nichts aus', () {
      final u = ModusUmschalter(Modus.flaeche);
      final a = vek(basis['linke Seite']!);
      final b = vek(basis['rechte Seite']!);
      for (var i = 0; i < 300; i++) {
        final v = i.isEven ? a : b;
        expect(u.update(v.x, v.y, v.z, 0.033), isNull);
      }
    });
    test('uneindeutige Zwischenlage unterbricht und setzt zurück', () {
      final u = ModusUmschalter(Modus.flaeche);
      final auf = vek(basis['vertikal aufrecht']!);
      final mitte = vek(mul(anheben(nord, 45), basis['flach (Display oben)']!));
      for (var i = 0; i < 20; i++) {
        u.update(auf.x, auf.y, auf.z, 0.033); // 0,66 s
      }
      u.update(mitte.x, mitte.y, mitte.z, 0.033);
      Modus? neu;
      for (var i = 0; i < 20; i++) {
        neu = u.update(auf.x, auf.y, auf.z, 0.033) ?? neu;
      }
      expect(neu, isNull); // nach der Unterbrechung beginnt die Zeit von vorn (0,66 s)
    });
    test('uneindeutige Lage ändert die aktuelle Betriebsart nicht (Hysterese)', () {
      final u = ModusUmschalter(Modus.linieDisplay);
      final mitte = vek(mul(anheben(nord, 45), basis['flach (Display oben)']!));
      for (var i = 0; i < 300; i++) {
        expect(u.update(mitte.x, mitte.y, mitte.z, 0.033), isNull);
      }
      expect(u.aktuell, Modus.linieDisplay);
    });
    test('setze() übernimmt die manuelle Wahl und löscht den Kandidaten', () {
      final u = ModusUmschalter(Modus.flaeche);
      final auf = vek(basis['vertikal aufrecht']!);
      for (var i = 0; i < 20; i++) {
        u.update(auf.x, auf.y, auf.z, 0.033);
      }
      u.setze(Modus.linieRechts);
      expect(u.aktuell, Modus.linieRechts);
      Modus? neu;
      for (var i = 0; i < 20; i++) {
        neu = u.update(auf.x, auf.y, auf.z, 0.033) ?? neu;
      }
      expect(neu, isNull); // Zeit beginnt neu
    });
  });

  group('Ablauf mit Sensor-Simulation (Rauschen, Filter, Bewegung)', () {
    final flach = basis['flach (Display oben)']!;

    test('Handy liegt ruhig flach: nie ein Wechsel', () {
      final l = Lauf(flach, Modus.flaeche);
      l.ruhe(flach, 20);
      expect(l.wechsel, isEmpty);
    });

    test('flach → aufstellen → flach → linke Seite → flach → rechte Seite → flach', () {
      final l = Lauf(flach, Modus.flaeche);
      l.ruhe(flach, 1.5);
      final sequenz = <(V, double, Modus)>[
        (ost, 90, Modus.linieDisplay),
        (ost, -90, Modus.flaeche),
        (nord, -90, Modus.linieLinks),
        (nord, 90, Modus.flaeche),
        (nord, 90, Modus.linieRechts),
        (nord, -90, Modus.flaeche),
      ];
      var pose = flach;
      for (final (achse, grad, ziel) in sequenz) {
        final davor = l.wechsel.length;
        final t0 = l.zeit;
        pose = l.dreh(pose, achse, grad, 1.0); // 1 s drehen
        l.ruhe(pose, 1.8); // danach ruhig liegen
        expect(l.wechsel.length, davor + 1, reason: 'genau ein Wechsel nach $ziel');
        expect(l.wechsel.last.$2, ziel);
        // nicht schon während der ersten 0,3 s der Bewegung
        expect(l.wechsel.last.$1 - t0, greaterThan(0.3));
        expect(l.umschalter.aktuell, ziel);
      }
    });

    test('Wackeln (±15° um flach) löst keinen Wechsel aus', () {
      final l = Lauf(flach, Modus.flaeche);
      var pose = flach;
      for (var k = 0; k < 6; k++) {
        pose = l.dreh(flach, k.isEven ? ost : nord, k.isEven ? 15 : -15, 0.4);
        pose = l.dreh(pose, k.isEven ? ost : nord, 0, 0.4);
      }
      l.ruhe(flach, 2);
      expect(l.wechsel, isEmpty);
    });

    test('Anheben auf 50° und wieder zurück: kein Wechsel', () {
      final l = Lauf(flach, Modus.flaeche);
      l.ruhe(flach, 1);
      final hoch = l.dreh(flach, ost, 50, 0.8);
      l.ruhe(hoch, 0.4);
      l.dreh(flach, ost, 0, 0.1);
      l.ruhe(flach, 2);
      expect(l.wechsel, isEmpty);
    });

    test('seitlich: leicht schräg (10°) abgestellt, bleibt linke Seite', () {
      final seite = basis['linke Seite']!;
      final l = Lauf(seite, Modus.linieLinks);
      l.ruhe(mul(anheben(nord, 10), seite), 10);
      expect(l.wechsel, isEmpty);
    });
  });

  test('Messwerte werden von der Umschaltung nicht verändert', () {
    // Die Umschaltung liest nur; dieselben Vektoren ergeben dieselbe Messung.
    final v = vek(basis['vertikal aufrecht']!);
    final vorher = berechneLinie(Modus.linieDisplay, v.x, v.y, v.z);
    ModusUmschalter(Modus.flaeche).update(v.x, v.y, v.z, 0.5);
    final nachher = berechneLinie(Modus.linieDisplay, v.x, v.y, v.z);
    expect(nachher.grad, vorher.grad);
    expect(nachher.prozent, vorher.prozent);
  });
}
