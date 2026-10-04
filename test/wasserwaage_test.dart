import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/wasserwaage_logik.dart';

const g = 9.81;
double rad(double d) => d * math.pi / 180;
double sin_(double d) => math.sin(rad(d));
double cos_(double d) => math.cos(rad(d));

Neigung nz(double x, double y, double z) => berechneNeigung(x, y, z);

void main() {
  group('Lagen (Schwerkraftvektor → Referenzachse)', () {
    test('flach, Display oben', () {
      final n = nz(0, 0, g);
      expect(n.lage.ref, Achse.z);
      expect(n.lage.plus, true);
      expect(n.gesamtGrad, closeTo(0, 1e-9));
      expect(n.prozent, closeTo(0, 1e-9));
      final p = blasenPosition(n);
      expect(p.dx, 0);
      expect(p.dy, 0);
    });
    test('flach, Display unten', () {
      final n = nz(0, 0, -g);
      expect(n.lage.ref, Achse.z);
      expect(n.lage.plus, false);
      expect(n.gesamtGrad, closeTo(0, 1e-9));
    });
    test('Telefon auf linker Seite (x positiv)', () {
      final n = nz(g, 0, 0);
      expect(n.lage.ref, Achse.x);
      expect(n.lage.plus, true);
      expect(n.lage.beschreibung, contains('linken Seite'));
      expect(n.gesamtGrad, closeTo(0, 1e-9));
    });
    test('Telefon auf rechter Seite (x negativ)', () {
      final n = nz(-g, 0, 0);
      expect(n.lage.ref, Achse.x);
      expect(n.lage.plus, false);
      expect(n.lage.beschreibung, contains('rechten Seite'));
    });
    test('vertikal / aufrecht (y positiv) und kopfüber', () {
      expect(nz(0, g, 0).lage.ref, Achse.y);
      expect(nz(0, g, 0).lage.plus, true);
      expect(nz(0, -g, 0).lage.plus, false);
    });
  });

  group('Neigung in jeder Lage', () {
    test('flach: links hoch → X negativ, Blase links', () {
      final n = nz(-g * sin_(10), 0, g * cos_(10));
      expect(n.aGrad, closeTo(-10, 1e-9));
      expect(n.bGrad, closeTo(0, 1e-9));
      expect(n.gesamtGrad, closeTo(10, 1e-9));
      final p = blasenPosition(n);
      expect(p.dx, lessThan(0));
      expect(p.dy, closeTo(0, 1e-9));
    });
    test('flach: rechts hoch → X positiv, Blase rechts', () {
      final n = nz(g * sin_(10), 0, g * cos_(10));
      expect(n.aGrad, closeTo(10, 1e-9));
      expect(blasenPosition(n).dx, greaterThan(0));
    });
    test('flach: vorne hoch → Y positiv, Blase oben', () {
      final n = nz(0, g * sin_(10), g * cos_(10));
      expect(n.bGrad, closeTo(10, 1e-9));
      final p = blasenPosition(n);
      expect(p.dy, lessThan(0));
      expect(p.dx, closeTo(0, 1e-9));
    });
    test('flach: hinten hoch → Y negativ, Blase unten', () {
      final n = nz(0, -g * sin_(10), g * cos_(10));
      expect(n.bGrad, closeTo(-10, 1e-9));
      expect(blasenPosition(n).dy, greaterThan(0));
    });
    test('flach: diagonal links+vorne hoch → Blase links oben', () {
      final n = nz(-g * sin_(7), g * sin_(7), g * cos_(10));
      final p = blasenPosition(n);
      expect(p.dx, lessThan(0));
      expect(p.dy, lessThan(0));
    });
    test('Display unten, rechte Kante hoch → X positiv', () {
      final n = nz(g * sin_(6), 0, -g * cos_(6));
      expect(n.lage.plus, false);
      expect(n.aGrad, closeTo(6, 1e-9));
    });
    test('auf linker Seite: Oberkante hoch → a = Y positiv, Blase rechts', () {
      final n = nz(g * cos_(5), g * sin_(5), 0);
      expect(n.lage.a, Achse.y);
      expect(n.aGrad, closeTo(5, 1e-9));
      expect(n.gesamtGrad, closeTo(5, 1e-9));
      expect(n.lage.seite(Achse.y, true), 'Oberkante');
      expect(blasenPosition(n).dx, greaterThan(0));
    });
    test('auf linker Seite: Display-Seite hoch → b = Z positiv, Blase oben', () {
      final n = nz(g * cos_(5), 0, g * sin_(5));
      expect(n.lage.b, Achse.z);
      expect(n.bGrad, closeTo(5, 1e-9));
      expect(blasenPosition(n).dy, lessThan(0));
    });
    test('auf rechter Seite: Oberkante hoch', () {
      final n = nz(-g * cos_(5), g * sin_(5), 0);
      expect(n.lage.ref, Achse.x);
      expect(n.lage.plus, false);
      expect(n.aGrad, closeTo(5, 1e-9));
    });
    test('vertikal aufrecht: rechte Kante hoch 3° → a = X positiv', () {
      final n = nz(g * sin_(3), g * cos_(3), 0);
      expect(n.lage.ref, Achse.y);
      expect(n.lage.a, Achse.x);
      expect(n.aGrad, closeTo(3, 1e-9));
      expect(blasenPosition(n).dx, greaterThan(0));
    });
    test('vertikal aufrecht: Display zeigt 4° nach oben → b = Z positiv', () {
      final n = nz(0, g * cos_(4), g * sin_(4));
      expect(n.lage.b, Achse.z);
      expect(n.bGrad, closeTo(4, 1e-9));
      expect(blasenPosition(n).dy, lessThan(0));
    });
    test('Gesamtneigung = Winkel der Referenzachse zur Senkrechten (beliebige Lage)', () {
      for (final v in [
        (x: 1.2, y: -0.7, z: 9.6),
        (x: 9.7, y: 1.0, z: -0.5),
        (x: -0.4, y: 9.8, z: 1.3),
      ]) {
        final n = nz(v.x, v.y, v.z);
        final ref = math.max(v.x.abs(), math.max(v.y.abs(), v.z.abs()));
        final betrag = math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
        expect(n.gesamtGrad, closeTo(math.acos(ref / betrag) * 180 / math.pi, 1e-6));
      }
    });
    test('1° Neigung: Prozent und mm/m', () {
      final n = nz(g * sin_(1), 0, g * cos_(1));
      expect(n.prozent, closeTo(1.7455, 1e-3));
      expect(n.mmProM, closeTo(17.455, 1e-2));
    });
    test('2 % Gefälle', () {
      final grad = math.atan(0.02) * 180 / math.pi;
      final n = nz(0, g * sin_(grad), g * cos_(grad));
      expect(n.prozent, closeTo(2.0, 1e-6));
      expect(n.mmProM, closeTo(20.0, 1e-5));
    });
    test('Nullvektor ist ungültig, Blase mittig', () {
      final n = nz(0, 0, 0);
      expect(n.gueltig, false);
      final p = blasenPosition(n);
      expect(p.dx, 0);
      expect(p.dy, 0);
    });
  });

  group('Blasenposition: kontinuierlich, ohne Anschlag', () {
    test('streng wachsend von 1° bis 44° (Referenz z)', () {
      var last = 0.0;
      for (var d = 1; d <= 44; d++) {
        final x = blasenPosition(nz(g * sin_(d.toDouble()), 0, g * cos_(d.toDouble()))).dx;
        expect(x, greaterThan(last), reason: 'bei $d°');
        last = x;
      }
      expect(last, lessThanOrEqualTo(1.0));
    });
    test('Abstand = Anzeigeskala der Gesamtneigung', () {
      final n = nz(2.0, 3.0, 9.4);
      final p = blasenPosition(n);
      expect(math.sqrt(p.dx * p.dx + p.dy * p.dy), closeTo(anzeigeSkala(n.gesamtGrad), 1e-9));
    });
    test('Leiste: Vorzeichen bleibt', () {
      expect(leistenPosition(-5), lessThan(0));
      expect(leistenPosition(5), greaterThan(0));
      expect(leistenPosition(0), 0);
    });
  });

  group('Kalibrierung', () {
    Vek v(double x, double y, double z) => (x: x, y: y, z: z);

    test('zieht die Referenz ab (flach)', () {
      final proben = [for (var i = 0; i < 30; i++) v(g * sin_(0.8), -g * sin_(0.4), g * cos_(0.8))];
      final k = kalibriere(proben)!;
      expect(k.lage.ref, Achse.z);
      final n = berechneNeigung(proben[0].x, proben[0].y, proben[0].z, lage: k.lage, a0: k.a0, b0: k.b0);
      expect(n.gesamtGrad, closeTo(0, 1e-9));
      expect(k.streuungGrad, closeTo(0, 1e-9));
    });
    test('Kalibrierung gilt je Lage (auf der Seite)', () {
      final proben = [for (var i = 0; i < 30; i++) v(g * cos_(0.5), g * sin_(0.3), 0)];
      final k = kalibriere(proben)!;
      expect(k.lage.ref, Achse.x);
      expect(k.lage.plus, true);
      expect(k.a0, closeTo(0.3, 1e-3));
    });
    test('Bewegung beim Kalibrieren: große Streuung', () {
      final proben = [for (var i = 0; i < 30; i++) v(i.isEven ? 0.25 : -0.25, 0, g)];
      expect(kalibriere(proben)!.streuungGrad, greaterThan(kKalibrierMaxStreuung));
    });
    test('zu wenige Proben', () {
      expect(kalibriere([v(0, 0, g)]), isNull);
    });
  });

  group('GravityFilter (Glättung)', () {
    test('Ruhe: Ergebnis = Messwert, ohne Versatz', () {
      final f = GravityFilter();
      for (var i = 0; i < 400; i++) {
        f.update(ax: 0.3, ay: -0.2, az: 9.8, dt: 0.01);
      }
      expect(f.x, closeTo(0.3, 1e-3));
      expect(f.y, closeTo(-0.2, 1e-3));
      expect(f.z, closeTo(9.8, 1e-3));
    });
    test('Rauschen wird deutlich geglättet', () {
      final f = GravityFilter();
      final rnd = math.Random(3);
      var maxF = 0.0;
      for (var i = 0; i < 600; i++) {
        final n = (rnd.nextDouble() - 0.5) * 1.2; // ±0,6 m/s² Rauschen
        f.update(ax: n, ay: 0, az: g, dt: 0.01);
        if (i > 200) maxF = math.max(maxF, f.x.abs());
      }
      expect(maxF, lessThan(0.3));
    });
    test('Drehung mit Gyroskop: folgt ohne Verzögerung', () {
      const w = 0.5; // rad/s um die y-Achse
      final f = GravityFilter();
      var maxFehler = 0.0;
      for (var i = 0; i <= 100; i++) {
        final th = w * i * 0.01;
        final ax = -g * math.sin(th), az = g * math.cos(th);
        f.update(ax: ax, ay: 0, az: az, dt: 0.01, gx: 0, gy: w, gz: 0);
        final fehler = (math.atan2(f.x, f.z) - math.atan2(ax, az)).abs() * 180 / math.pi;
        maxFehler = math.max(maxFehler, fehler);
      }
      expect(maxFehler, lessThan(0.1));
    });
    test('Ohne Gyroskop: folgt mit kleiner Verzögerung, aber stabil', () {
      const w = 0.5;
      final f = GravityFilter();
      for (var i = 0; i <= 300; i++) {
        final th = w * i * 0.01;
        f.update(ax: -g * math.sin(th), ay: 0, az: g * math.cos(th), dt: 0.01);
      }
      final th = w * 3.0;
      final fehler = (math.atan2(f.x, f.z) - math.atan2(-g * math.sin(th), g * math.cos(th))).abs() * 180 / math.pi;
      expect(fehler, lessThan(6));
    });
  });
}
