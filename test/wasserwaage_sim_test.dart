// Simulation der Wasserwaage mit realistischen Sensorwerten.
//
// Es wird KEINE echte Hardware bewegt. Eine Handy-Lage wird als
// Drehmatrix (Gerät → Welt) beschrieben, daraus entstehen die Messwerte, die
// ein Beschleunigungssensor (Gegenkraft der Schwerkraft, Rauschen) und ein
// Gyroskop (Drehrate im Gerätesystem, Rauschen) liefern würden. Diese Werte
// laufen durch denselben GravityFilter und dieselbe Neigungsberechnung wie in
// der App. Geprüft wird gegen die Geometrie der Lage, nicht gegen die App.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/wasserwaage_logik.dart';

typedef M = List<List<double>>;
typedef V = List<double>;

const g = 9.81;

M mul(M a, M b) => [
      for (var i = 0; i < 3; i++)
        [for (var j = 0; j < 3; j++) a[i][0] * b[0][j] + a[i][1] * b[1][j] + a[i][2] * b[2][j]],
    ];
M tr(M a) => [
      for (var i = 0; i < 3; i++) [for (var j = 0; j < 3; j++) a[j][i]],
    ];
V mv(M m, V v) => [for (var i = 0; i < 3; i++) m[i][0] * v[0] + m[i][1] * v[1] + m[i][2] * v[2]];
V cross(V a, V b) => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];

/// Gerätachsen (x rechts, y oben, z aus dem Display) in Weltkoordinaten
/// (x Ost, y Nord, z oben) als Spalten der Matrix.
M spalten(V ex, V ey, V ez) => [
      for (var i = 0; i < 3; i++) [ex[i], ey[i], ez[i]],
    ];

M rodrigues(V k, double winkel) {
  final c = math.cos(winkel), s = math.sin(winkel);
  final kk = [
    [0.0, -k[2], k[1]],
    [k[2], 0.0, -k[0]],
    [-k[1], k[0], 0.0],
  ];
  final k2 = mul(kk, kk);
  return [
    for (var i = 0; i < 3; i++)
      [for (var j = 0; j < 3; j++) (i == j ? 1.0 : 0.0) + s * kk[i][j] + (1 - c) * k2[i][j]],
  ];
}

/// Dreht das ganze Handy so, dass der Punkt in waagerechter Weltrichtung [d] um [grad] steigt.
M anheben(V d, double grad) => rodrigues(cross([0, 0, 1], d), -grad * math.pi / 180);

final M ident = [
  [1.0, 0, 0],
  [0, 1.0, 0],
  [0, 0, 1.0],
];

/// Grundlagen: wie das Handy ohne Neigung liegt.
final Map<String, M> basis = {
  'flach (Display oben)': spalten([1, 0, 0], [0, 1, 0], [0, 0, 1]),
  'flach (Display unten)': spalten([1, 0, 0], [0, -1, 0], [0, 0, -1]),
  'linke Seite': spalten([0, 0, 1], [0, 1, 0], [-1, 0, 0]),
  'rechte Seite': spalten([0, 0, -1], [0, 1, 0], [1, 0, 0]),
  'vertikal aufrecht': spalten([1, 0, 0], [0, 0, 1], [0, -1, 0]),
  'vertikal kopfüber': spalten([1, 0, 0], [0, 0, -1], [0, 1, 0]),
};

final Map<String, (Achse, bool)> erwarteteLage = {
  'flach (Display oben)': (Achse.z, true),
  'flach (Display unten)': (Achse.z, false),
  'linke Seite': (Achse.x, true),
  'rechte Seite': (Achse.x, false),
  'vertikal aufrecht': (Achse.y, true),
  'vertikal kopfüber': (Achse.y, false),
};

const west = [-1.0, 0.0, 0.0], ost = [1.0, 0.0, 0.0], nord = [0.0, 1.0, 0.0], sued = [0.0, -1.0, 0.0];

V aufDevice(M r) => mv(tr(r), [0, 0, 1]); // „oben“ im Gerätesystem (Einheitsvektor)

final _rnd = math.Random(42);
double gauss(double sigma) {
  final u1 = 1 - _rnd.nextDouble(), u2 = _rnd.nextDouble();
  return sigma * math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
}

const accRauschen = 0.05; // m/s², typisch für Handy-Beschleunigungssensoren
const gyroRauschen = 0.005; // rad/s

/// Ruhende Lage: 3 s Messung bei 100 Hz.
Neigung messeRuhe(M r) {
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
  return berechneNeigung(f.x, f.y, f.z);
}

int vz(double v) => v > 0 ? 1 : (v < 0 ? -1 : 0);

void main() {
  test('Simulation: anheben() hebt die gewünschte Weltrichtung', () {
    for (final d in [west, ost, nord, sued]) {
      final r = anheben(d, 10);
      expect(mv(r, d)[2], closeTo(math.sin(10 * math.pi / 180), 1e-9));
    }
  });

  group('Alle Grundlagen × 9 Neigungsrichtungen (aus Sensorwerten mit Rauschen)', () {
    final richtungen = <String, List<(V, double)>>{
      'eben': [],
      'links höher': [(west, 8)],
      'rechts höher': [(ost, 8)],
      'vorne höher': [(nord, 8)],
      'hinten höher': [(sued, 8)],
      'links-vorne': [(west, 6), (nord, 6)],
      'rechts-vorne': [(ost, 6), (nord, 6)],
      'rechts-hinten': [(ost, 6), (sued, 6)],
      'links-hinten': [(west, 6), (sued, 6)],
    };
    for (final b in basis.entries) {
      for (final rt in richtungen.entries) {
        test('${b.key} · ${rt.key}', () {
          var t = ident;
          for (final (d, grad) in rt.value) {
            t = mul(anheben(d, grad), t);
          }
          final r = mul(t, b.value);
          final n = messeRuhe(r);

          // 1) Lage erkannt
          final (achse, plus) = erwarteteLage[b.key]!;
          expect(n.lage.ref, achse, reason: 'Referenzachse');
          expect(n.lage.plus, plus, reason: 'Richtung der Referenzachse');

          // 2) Gesamtneigung = Winkel der Referenzachse zur Senkrechten (aus der Drehmatrix)
          final spalte = n.lage.ref.index; // Spalte der Referenzachse in R
          final wahr = math.acos(r[2][spalte].abs().clamp(0.0, 1.0)) * 180 / math.pi;
          expect(n.gesamtGrad, closeTo(wahr, 0.45), reason: 'Gesamtneigung');

          // 3) Vorzeichen: Das positive Ende einer Achse liegt höher, wenn seine Weltkoordinate z > 0 ist.
          final hoeheA = r[2][n.lage.a.index];
          final hoeheB = r[2][n.lage.b.index];
          if (hoeheA.abs() > 0.02) expect(vz(n.aGrad), vz(hoeheA), reason: 'Achse a');
          if (hoeheB.abs() > 0.02) expect(vz(n.bGrad), vz(hoeheB), reason: 'Achse b');

          // 4) Blase wandert zur höheren Seite (a → rechts, b → oben)
          final p = blasenPosition(n);
          if (hoeheA.abs() > 0.02) expect(vz(p.dx), vz(hoeheA), reason: 'Blase x');
          if (hoeheB.abs() > 0.02) expect(vz(p.dy), -vz(hoeheB), reason: 'Blase y');

          // 5) Zahlen und Blase aus derselben Rechnung: Abstand = Skala der Gesamtneigung
          if (n.gesamtGrad > 0.5) {
            expect(math.sqrt(p.dx * p.dx + p.dy * p.dy), closeTo(anzeigeSkala(n.gesamtGrad), 1e-9));
          }
        });
      }
    }
  });

  group('Beschriftung (Handy flach, Display oben)', () {
    String text(List<(V, double)> k) {
      var t = ident;
      for (final (d, grad) in k) {
        t = mul(anheben(d, grad), t);
      }
      // rauschfreie Sensorwerte: exakte Beschriftung; mit Rauschen siehe unten
      final u = aufDevice(mul(t, basis['flach (Display oben)']!));
      return richtungsText(berechneNeigung(u[0] * g, u[1] * g, u[2] * g));
    }

    test('mit Sensorrauschen: Hauptrichtung steht an erster Stelle', () {
      final b = basis['flach (Display oben)']!;
      expect(richtungsText(messeRuhe(mul(anheben(west, 8), b))), startsWith('Links höher'));
      expect(richtungsText(messeRuhe(mul(anheben(ost, 8), b))), startsWith('Rechts höher'));
      expect(richtungsText(messeRuhe(mul(anheben(nord, 8), b))), contains('orne höher'));
      expect(richtungsText(messeRuhe(mul(anheben(sued, 8), b))), contains('inten höher'));
    });
    test('eben → Waagerecht', () => expect(messeRuhe(basis['flach (Display oben)']!).gesamtGrad, lessThan(0.3)));
    test('links höher', () => expect(text([(west, 8)]), 'Links höher'));
    test('rechts höher', () => expect(text([(ost, 8)]), 'Rechts höher'));
    test('vorne höher', () => expect(text([(nord, 8)]), 'Vorne höher'));
    test('hinten höher', () => expect(text([(sued, 8)]), 'Hinten höher'));
    test('links-vorne', () => expect(text([(west, 6), (nord, 6)]), 'Links höher, vorne höher'));
    test('rechts-vorne', () => expect(text([(ost, 6), (nord, 6)]), 'Rechts höher, vorne höher'));
    test('rechts-hinten', () => expect(text([(ost, 6), (sued, 6)]), 'Rechts höher, hinten höher'));
    test('links-hinten', () => expect(text([(west, 6), (sued, 6)]), 'Links höher, hinten höher'));
  });

  group('Zwischenwinkel (flach): Winkel, %, mm/m', () {
    for (final grad in [0.5, 1.0, 2.0, 3.0, 5.0, 7.5, 10.0, 15.0, 20.0, 30.0, 40.0]) {
      test('$grad° links/rechts/vorne/hinten', () {
        final tol = 0.35 + grad * 0.01;
        final tanWert = math.tan(grad * math.pi / 180);
        final rl = messeRuhe(mul(anheben(west, grad), basis['flach (Display oben)']!));
        expect(rl.aGrad, closeTo(-grad, tol));
        expect(rl.bGrad.abs(), lessThan(0.4));
        expect(rl.prozent, closeTo(tanWert * 100, tanWert * 100 * 0.04 + 0.7));
        final rr = messeRuhe(mul(anheben(ost, grad), basis['flach (Display oben)']!));
        expect(rr.aGrad, closeTo(grad, tol));
        final rv = messeRuhe(mul(anheben(nord, grad), basis['flach (Display oben)']!));
        expect(rv.bGrad, closeTo(grad, tol));
        final rh = messeRuhe(mul(anheben(sued, grad), basis['flach (Display oben)']!));
        expect(rh.bGrad, closeTo(-grad, tol));
        expect(rv.mmProM, closeTo(rv.prozent * 10, 1e-6));
      });
    }
  });

  group('Bewegung: langsames Neigen mit Gyroskop und Rauschen', () {
    /// Neigt das Handy gleichmäßig von 0 auf [maxGrad] in [sek] Sekunden.
    List<({Neigung n, M r})> neigen(M basisPose, V richtung, double maxGrad, double sek, bool mitGyro) {
      final f = GravityFilter();
      const dt = 0.01;
      final schritte = (sek / dt).round();
      M rVorher = basisPose;
      final out = <({Neigung n, M r})>[];
      for (var i = 0; i <= schritte; i++) {
        final r = mul(anheben(richtung, maxGrad * i / schritte), basisPose);
        final u = aufDevice(r);
        // Drehrate im Gerätesystem aus zwei aufeinanderfolgenden Lagen
        final rel = mul(tr(rVorher), r);
        final w = [
          (rel[2][1] - rel[1][2]) / (2 * dt),
          (rel[0][2] - rel[2][0]) / (2 * dt),
          (rel[1][0] - rel[0][1]) / (2 * dt),
        ];
        f.update(
          ax: u[0] * g + gauss(accRauschen),
          ay: u[1] * g + gauss(accRauschen),
          az: u[2] * g + gauss(accRauschen),
          dt: dt,
          gx: mitGyro ? w[0] + gauss(gyroRauschen) : null,
          gy: mitGyro ? w[1] + gauss(gyroRauschen) : null,
          gz: mitGyro ? w[2] + gauss(gyroRauschen) : null,
        );
        rVorher = r;
        out.add((n: berechneNeigung(f.x, f.y, f.z), r: r));
      }
      return out;
    }

    double fehlerMax(List<({Neigung n, M r})> l) {
      var m = 0.0;
      for (final e in l.skip(20)) {
        final wahr = math.acos(e.r[2][e.n.lage.ref.index].abs().clamp(0.0, 1.0)) * 180 / math.pi;
        m = math.max(m, (e.n.gesamtGrad - wahr).abs());
      }
      return m;
    }

    test('flach: rechts hoch 0→35° in 3 s: folgt, Blase wandert stetig nach rechts', () {
      final l = neigen(basis['flach (Display oben)']!, ost, 35, 3, true);
      expect(fehlerMax(l), lessThan(0.6));
      var last = -1.0;
      for (var i = 50; i < l.length; i += 25) {
        final dx = blasenPosition(l[i].n).dx;
        expect(dx, greaterThan(last), reason: 'Schritt $i');
        last = dx;
      }
      expect(blasenPosition(l.last.n).dy.abs(), lessThan(0.15));
    });

    test('Gyroskop-Stützung folgt einer Drehung genauer als der Beschleunigungsmesser allein', () {
      final mit = neigen(basis['flach (Display oben)']!, nord, 40, 1.5, true);
      final ohne = neigen(basis['flach (Display oben)']!, nord, 40, 1.5, false);
      expect(fehlerMax(mit), lessThan(fehlerMax(ohne)));
      expect(fehlerMax(mit), lessThan(1.0));
    });

    test('auf der linken Seite: Oberkante hoch 0→20°: Winkel b/a folgen, Blase stetig', () {
      final l = neigen(basis['linke Seite']!, nord, 20, 2, true);
      expect(fehlerMax(l), lessThan(0.6));
      expect(l.every((e) => e.n.lage.ref == Achse.x && e.n.lage.plus), true);
    });

    test('vertikal: Display-Seite nach oben neigen 0→20°', () {
      final l = neigen(basis['vertikal aufrecht']!, sued, 20, 2, true);
      expect(fehlerMax(l), lessThan(0.6));
      expect(l.every((e) => e.n.lage.ref == Achse.y), true);
    });

    test('Übergang flach → Seite: Lage wechselt genau bei gleichen Achsbeträgen (≈45°)', () {
      final l = neigen(basis['flach (Display oben)']!, west, 90, 6, true);
      // Achse z führt unter 44°, Achse x über 46° (Drehung um die y-Achse)
      for (var i = 0; i < l.length; i++) {
        final winkel = 90 * i / (l.length - 1);
        if (winkel < 43) expect(l[i].n.lage.ref, Achse.z, reason: 'bei ${winkel.toStringAsFixed(1)}°');
        if (winkel > 47) expect(l[i].n.lage.ref, Achse.x, reason: 'bei ${winkel.toStringAsFixed(1)}°');
      }
    });
  });

  group('Realistische Einzelwerte (Android: x rechts, y oben, z aus dem Display)', () {
    test('Handy flach auf dem Tisch', () {
      final n = berechneNeigung(0.12, -0.08, 9.78);
      expect(n.lage.ref, Achse.z);
      expect(n.gesamtGrad, lessThan(1.0));
    });
    test('linke Kante angehoben (x negativ)', () {
      final n = berechneNeigung(-1.2, 0.05, 9.7);
      expect(n.aGrad, lessThan(-6));
      expect(richtungsText(n), startsWith('Links höher'));
    });
    test('Vorderkante angehoben (y positiv)', () {
      final n = berechneNeigung(0.03, 1.5, 9.68);
      expect(n.bGrad, greaterThan(8));
      expect(richtungsText(n), contains('orne höher'));
    });
    test('auf der linken Seite (x ≈ +9,8)', () {
      final n = berechneNeigung(9.79, 0.1, 0.4);
      expect(n.lage.ref, Achse.x);
      expect(n.lage.plus, true);
      expect(n.lage.beschreibung, contains('linken Seite'));
    });
    test('auf der rechten Seite (x ≈ −9,8)', () {
      final n = berechneNeigung(-9.8, 0.1, 0.4);
      expect(n.lage.beschreibung, contains('rechten Seite'));
    });
    test('vertikal (y ≈ +9,8)', () {
      final n = berechneNeigung(0.2, 9.79, 0.5);
      expect(n.lage.ref, Achse.y);
    });
  });

  group('Kalibrierung in simulierter Lage', () {
    test('flach schräg (0,6°): nach Kalibrierung 0,00°', () {
      final r = mul(anheben(ost, 0.6), basis['flach (Display oben)']!);
      final u = aufDevice(r);
      final proben = [for (var i = 0; i < 50; i++) (x: u[0] * g, y: u[1] * g, z: u[2] * g)];
      final k = kalibriere(proben)!;
      final n = berechneNeigung(u[0] * g, u[1] * g, u[2] * g, lage: k.lage, a0: k.a0, b0: k.b0);
      expect(n.gesamtGrad, closeTo(0, 1e-6));
      expect(zahl(n.aGrad), '0,00');
      expect(richtungsText(n), 'Waagerecht');
    });
  });
}
