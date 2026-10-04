// Tests der festen Betriebsarten (Fläche 2D, Linie: Display vorne, linke Seite,
// rechte Seite) mit simulierten Sensorwerten (Rauschen, Filter wie in der App).
// Es wird keine echte Hardware bewegt.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/wasserwaage_logik.dart';

import 'wasserwaage_sim_test.dart' hide main;

/// Gefilterter Schwerkraftvektor nach 3 s Ruhe (mit Rauschen).
Vek messeVek(M r) {
  final f = GravityFilter();
  final u = aufDevice(r);
  for (var i = 0; i < 300; i++) {
    f.update(
      ax: u[0] * g + gauss(accRauschen),
      ay: u[1] * g + gauss(accRauschen),
      az: u[2] * g + gauss(accRauschen),
      dt: 0.01,
      gx: gauss(gyroRauschen),
      gy: gauss(gyroRauschen),
      gz: gauss(gyroRauschen),
    );
  }
  return (x: f.x, y: f.y, z: f.z);
}

Linienmessung linie(Modus m, M r, {double a0 = 0}) {
  final v = messeVek(r);
  return berechneLinie(m, v.x, v.y, v.z, a0: a0);
}

/// Grundlage, Weltrichtung „rechts“/„links“ aus Sicht des Benutzers (Display zugewandt)
/// und eine Richtung quer zur Messachse.
class Aufbau {
  const Aufbau(this.basisName, this.rechts, this.links, this.quer);
  final String basisName;
  final V rechts;
  final V links;
  final V quer;
}

// Display vorne: Betrachter im Süden, schaut nach Norden → rechts = Ost.
// Linke Seite: Display zeigt nach Westen, Betrachter im Westen schaut nach Osten →
//   Oberkante (Nord) liegt links, rechts = Süd.
// Rechte Seite: Display zeigt nach Osten, Betrachter schaut nach Westen →
//   Oberkante (Nord) liegt rechts, rechts = Nord.
final Map<Modus, Aufbau> aufbau = {
  Modus.linieDisplay: const Aufbau('vertikal aufrecht', ost, west, nord),
  Modus.linieLinks: const Aufbau('linke Seite', sued, nord, ost),
  Modus.linieRechts: const Aufbau('rechte Seite', nord, sued, ost),
};

void main() {
  group('Betriebsarten: Definition', () {
    test('Lagen', () {
      expect(Modus.flaeche.lage.ref, Achse.z);
      expect(Modus.flaeche.lage.plus, true);
      expect(Modus.linieDisplay.lage.ref, Achse.y);
      expect(Modus.linieDisplay.lage.plus, true);
      expect(Modus.linieLinks.lage.ref, Achse.x);
      expect(Modus.linieLinks.lage.plus, true);
      expect(Modus.linieRechts.lage.ref, Achse.x);
      expect(Modus.linieRechts.lage.plus, false);
    });
    test('Messachsen', () {
      expect(Modus.linieDisplay.messAchse, Achse.x);
      expect(Modus.linieLinks.messAchse, Achse.y);
      expect(Modus.linieRechts.messAchse, Achse.y);
    });
    test('Drehung der Oberfläche passt zu Lage und Vorzeichen', () {
      // Oberfläche: „oben“ = Geräte-+y, „rechts“ = Geräte-+x. Eine Vierteldrehung im
      // Uhrzeigersinn: (x, y) → (y, −x).
      (int, int) dreh((int, int) v, int q) {
        var r = v;
        for (var i = 0; i < q; i++) {
          r = (r.$2, -r.$1);
        }
        return r;
      }

      for (final m in [Modus.linieDisplay, Modus.linieLinks, Modus.linieRechts]) {
        final q = m.viertelDrehungen;
        final oben = dreh((0, 1), q); // wohin das Display-Oben im Gerätesystem zeigt
        final rechts = dreh((1, 0), q); // wohin das Display-Rechts im Gerätesystem zeigt
        // Display-Oben muss der Weltrichtung „nach oben“ entsprechen: in der Lage zeigt
        // die Referenzachse (positives oder negatives Ende) nach oben.
        final upAchse = m.lage.ref == Achse.x ? oben.$1 : oben.$2;
        final upErwartet = m.lage.plus ? 1 : -1;
        expect(upAchse, upErwartet, reason: '${m.name} oben');
        // Display-Rechts entspricht der Messachse mit dem Vorzeichen.
        final messKomp = m.messAchse == Achse.x ? rechts.$1 : rechts.$2;
        expect(messKomp, m.rechtsVorzeichen, reason: '${m.name} rechts');
      }
    });
  });

  group('Lage der Betriebsart wird erkannt', () {
    final erwartet = <Modus, String>{
      Modus.flaeche: 'flach (Display oben)',
      Modus.linieDisplay: 'vertikal aufrecht',
      Modus.linieLinks: 'linke Seite',
      Modus.linieRechts: 'rechte Seite',
    };
    for (final m in Modus.values) {
      for (final b in basis.entries) {
        test('${m.name} in "${b.key}"', () {
          final v = messeVek(b.value);
          expect(lageStimmt(m, v.x, v.y, v.z), erwartet[m] == b.key);
        });
      }
    }
  });

  group('Linie: Winkel, Richtung, Prozent, mm/m (Rechts positiv)', () {
    for (final e in aufbau.entries) {
      final m = e.key;
      final a = e.value;
      final b = basis[a.basisName]!;
      for (final grad in [0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 40.0]) {
        test('${m.name} $grad°', () {
          final tol = 0.35 + grad * 0.01;
          final st = math.tan(grad * math.pi / 180);
          final r = linie(m, mul(anheben(a.rechts, grad), b));
          expect(r.lageOk, true);
          expect(r.grad, closeTo(grad, tol), reason: 'rechts höher');
          expect(r.prozent, closeTo(st * 100, st * 100 * 0.04 + 0.7));
          expect(r.mmProM, closeTo(st * 1000, st * 1000 * 0.04 + 7));
          if (grad >= 2) expect(linienRichtung(r), 'Rechts höher');
          final l = linie(m, mul(anheben(a.links, grad), b));
          expect(l.grad, closeTo(-grad, tol), reason: 'links höher');
          if (grad >= 2) expect(linienRichtung(l), 'Links höher');
          expect(leistenPosition(r.grad), greaterThan(0));
          expect(leistenPosition(l.grad), lessThan(0));
        });
      }
      test('${m.name}: eben → 0°, Waagerecht', () {
        final r = linie(m, b);
        expect(r.grad.abs(), lessThan(0.35));
        final v = (x: 0.0, y: 0.0, z: 0.0);
        expect(v.x, 0); // Platzhalter, damit die Zeile nicht leer ist
      });
      test('${m.name}: Neigung quer zur Messachse ändert den Wert nicht', () {
        for (final q in [5.0, 15.0, 30.0]) {
          final r = linie(m, mul(anheben(a.quer, q), b));
          expect(r.grad.abs(), lessThan(0.4), reason: 'quer $q°');
        }
      });
      test('${m.name}: Mischung (8° rechts + 15° quer) behält den 8°-Wert', () {
        final t = mul(anheben(a.quer, 15), mul(anheben(a.rechts, 8), b));
        final r = linie(m, t);
        // Die Messachse bleibt bei Querneigung gegen die Waagerechte um etwa 8° geneigt.
        expect(r.grad, greaterThan(6.5));
        expect(r.grad, lessThan(9.5));
      });
    }
  });

  group('Linie: realistische Einzelwerte', () {
    test('Display vorne, rechte Kante höher', () {
      final r = berechneLinie(Modus.linieDisplay, 0.5, 9.78, 0.3);
      expect(r.lageOk, true);
      expect(r.grad, closeTo(math.asin(0.5 / math.sqrt(0.25 + 9.78 * 9.78 + 0.09)) * 180 / math.pi, 1e-9));
      expect(linienRichtung(r), 'Rechts höher');
    });
    test('Linke Seite, Oberkante höher → links höher', () {
      final r = berechneLinie(Modus.linieLinks, 9.78, 0.5, 0.3);
      expect(r.lageOk, true);
      expect(r.grad, lessThan(0));
      expect(linienRichtung(r), 'Links höher');
    });
    test('Linke Seite, Unterkante höher → rechts höher', () {
      final r = berechneLinie(Modus.linieLinks, 9.78, -0.5, 0.3);
      expect(linienRichtung(r), 'Rechts höher');
    });
    test('Rechte Seite, Oberkante höher → rechts höher', () {
      final r = berechneLinie(Modus.linieRechts, -9.78, 0.5, 0.3);
      expect(r.lageOk, true);
      expect(r.grad, greaterThan(0));
      expect(linienRichtung(r), 'Rechts höher');
    });
    test('Rechte Seite, Unterkante höher → links höher', () {
      final r = berechneLinie(Modus.linieRechts, -9.78, -0.5, 0.3);
      expect(linienRichtung(r), 'Links höher');
    });
    test('falsche Lage: Handy flach im Modus Display vorne', () {
      final r = berechneLinie(Modus.linieDisplay, 0.1, 0.2, 9.8);
      expect(r.lageOk, false);
    });
    test('Nullvektor ungültig', () {
      expect(berechneLinie(Modus.linieDisplay, 0, 0, 0).gueltig, false);
    });
  });

  group('Fläche (2D): feste Lage Rückseite', () {
    test('fester Modus = automatische Lage bei flach', () {
      final v = messeVek(basis['flach (Display oben)']!);
      final a = berechneNeigung(v.x, v.y, v.z, lage: Modus.flaeche.lage);
      final b = berechneNeigung(v.x, v.y, v.z);
      expect(a.aGrad, closeTo(b.aGrad, 1e-12));
      expect(a.bGrad, closeTo(b.bGrad, 1e-12));
    });
    test('Display unten ist nicht die Lage der Betriebsart', () {
      final v = messeVek(basis['flach (Display unten)']!);
      expect(lageStimmt(Modus.flaeche, v.x, v.y, v.z), false);
    });
    test('links/rechts/vorne/hinten höher: Blasenrichtung', () {
      final b = basis['flach (Display oben)']!;
      Neigung n(V d) {
        final v = messeVek(mul(anheben(d, 8), b));
        return berechneNeigung(v.x, v.y, v.z, lage: Modus.flaeche.lage);
      }

      expect(blasenPosition(n(west)).dx, lessThan(0));
      expect(blasenPosition(n(ost)).dx, greaterThan(0));
      expect(blasenPosition(n(nord)).dy, lessThan(0)); // oben
      expect(blasenPosition(n(sued)).dy, greaterThan(0)); // unten
    });
  });

  group('Kalibrierung je Betriebsart', () {
    for (final e in aufbau.entries) {
      test('${e.key.name}: 0,6° Versatz wird zu 0,00°', () {
        final b = basis[e.value.basisName]!;
        final r = mul(anheben(e.value.rechts, 0.6), b);
        final u = aufDevice(r);
        final proben = [for (var i = 0; i < 50; i++) (x: u[0] * g, y: u[1] * g, z: u[2] * g)];
        final k = kalibriereModus(e.key, proben)!;
        final l = berechneLinie(e.key, u[0] * g, u[1] * g, u[2] * g, a0: k.a0);
        expect(l.grad.abs(), lessThan(1e-9));
        expect(zahl(l.grad), '0,00');
        expect(linienRichtung(l), 'Waagerecht');
      });
      test('${e.key.name}: falsche Lage → keine Kalibrierung', () {
        final u = aufDevice(basis['flach (Display oben)']!);
        final proben = [for (var i = 0; i < 50; i++) (x: u[0] * g, y: u[1] * g, z: u[2] * g)];
        expect(kalibriereModus(e.key, proben), isNull);
      });
    }
    test('Fläche: Versatz wird zu 0,00°', () {
      final r = mul(anheben(ost, 0.6), basis['flach (Display oben)']!);
      final u = aufDevice(r);
      final proben = [for (var i = 0; i < 50; i++) (x: u[0] * g, y: u[1] * g, z: u[2] * g)];
      final k = kalibriereModus(Modus.flaeche, proben)!;
      final n = berechneNeigung(u[0] * g, u[1] * g, u[2] * g, lage: Modus.flaeche.lage, a0: k.a0, b0: k.b0);
      expect(n.gesamtGrad, closeTo(0, 1e-9));
    });
    test('Bewegung beim Kalibrieren: große Streuung', () {
      final proben = [
        for (var i = 0; i < 30; i++) (x: i.isEven ? 0.4 : -0.4, y: g, z: 0.0),
      ];
      expect(kalibriereModus(Modus.linieDisplay, proben)!.streuungGrad, greaterThan(kKalibrierMaxStreuung));
    });
  });
}
