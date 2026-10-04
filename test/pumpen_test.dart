import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/pumpen_logik.dart';

/// ACHTUNG: erfundene Testkurve nur für Unit-Tests (keine echte Pumpe!).
PumpenKurve testKurve({String q = 'm3h', String h = 'm'}) => PumpenKurve(
      name: 'Test',
      qEinheit: q,
      hEinheit: h,
      punkte: const [QH(0, 4.0), QH(1, 3.8), QH(2, 3.2), QH(3, 2.3), QH(3.5, 1.6), QH(4, 0.8)],
    );

void main() {
  group('Kennlinie', () {
    test('Interpolation', () {
      final k = testKurve().normiert;
      expect(hBeiQ(k, 0), 4.0);
      expect(hBeiQ(k, 1.5), closeTo(3.5, 1e-9));
      expect(hBeiQ(k, 4), closeTo(0.8, 1e-9));
      expect(hBeiQ(k, 4.5), isNull);
    });

    test('Einheiten l/min und kPa werden umgerechnet', () {
      final k = PumpenKurve(
        name: 'x',
        qEinheit: 'lmin',
        hEinheit: 'kpa',
        punkte: const [QH(0, 39.2266), QH(60, 29.4), QH(120, 9.8)],
      ).normiert;
      expect(k.first.h, closeTo(4.0, 0.01));
      expect(k[1].q, closeTo(3.6, 1e-9));
      expect(k.last.q, closeTo(7.2, 1e-9));
    });

    test('Validierung', () {
      expect(pruefeKurve(const [QH(0, 4), QH(1, 3)]), isNotNull);
      expect(pruefeKurve(const [QH(1, 4), QH(0, 3), QH(2, 1)]), isNotNull);
      expect(pruefeKurve(const [QH(0, 3), QH(1, 4), QH(2, 1)]), isNotNull);
      expect(pruefeKurve(const [QH(0, -1), QH(1, -2), QH(2, -3)]), isNotNull);
      expect(pruefeKurve(testKurve().normiert), isNull);
    });

    test('Text lesen: Komma, Semikolon, Fehler', () {
      final r = parsePunkte('0 4,0\n1;3,8\n\n2 3.2');
      expect(r.fehler, isEmpty);
      expect(r.punkte.length, 3);
      expect(r.punkte[1].h, 3.8);
      expect(parsePunkte('1 2 3').fehler, isNotEmpty);
      expect(parsePunkte('abc').fehler, isNotEmpty);
    });

    test('JSON hin und zurück', () {
      final p = PumpenDaten(
        id: '1',
        hersteller: 'H',
        modell: 'M',
        quelle: 'Datenblatt',
        kurven: [testKurve()],
      );
      final p2 = PumpenDaten.fromJson(p.toJson());
      expect(p2.titel, 'H M');
      expect(p2.kurven.single.punkte.length, 6);
      expect(p2.verifiziert, isFalse);
    });
  });

  group('Prüfung', () {
    test('geeignet bei großer Reserve', () {
      final r = pruefePumpe(q: 1.5, h: 2.0, kurve: testKurve());
      expect(r.eignung, Eignung.geeignet);
      expect(r.reserveH, closeTo(0.75, 1e-9));
    });

    test('Grenzbereich bei knapper Reserve', () {
      final r = pruefePumpe(q: 3, h: 2.0, kurve: testKurve());
      expect(r.eignung, Eignung.grenzbereich);
    });

    test('Grenzbereich nahe Kurvenende', () {
      final r = pruefePumpe(q: 3.8, h: 1.0, kurve: testKurve());
      expect(r.eignung, Eignung.grenzbereich);
    });

    test('nicht geeignet: Förderhöhe zu klein', () {
      final r = pruefePumpe(q: 3, h: 2.6, kurve: testKurve());
      expect(r.eignung, Eignung.nichtGeeignet);
    });

    test('nicht geeignet: Q über Kurvenende', () {
      final r = pruefePumpe(q: 5, h: 1, kurve: testKurve());
      expect(r.eignung, Eignung.nichtGeeignet);
    });

    test('stark überdimensioniert → Grenzbereich-Hinweis', () {
      final r = pruefePumpe(q: 0.5, h: 0.5, kurve: testKurve());
      expect(r.eignung, Eignung.grenzbereich);
      expect(r.gruende.any((g) => g.contains('überdimensioniert')), isTrue);
    });

    test('ohne Kennlinie keine Prüfung', () {
      final r = pruefePumpe(q: 1, h: 1);
      expect(r.eignung, Eignung.nichtPruefbar);
    });

    test('kaputte Kennlinie keine Prüfung', () {
      final k = PumpenKurve(name: 'x', punkte: const [QH(0, 1), QH(1, 2)]);
      expect(pruefePumpe(q: 1, h: 1, kurve: k).eignung, Eignung.nichtPruefbar);
    });

    test('Schnittpunkt liegt auf beiden Kurven', () {
      final r = pruefePumpe(q: 1.5, h: 2.0, kurve: testKurve());
      expect(r.schnittQ, isNotNull);
      final k = testKurve().normiert;
      final hp = hBeiQ(k, r.schnittQ!)!;
      final sys = 2.0 * (r.schnittQ! / 1.5) * (r.schnittQ! / 1.5);
      expect(hp, closeTo(sys, 0.01));
    });

    test('Einheiten kPa/l/min ergeben dasselbe Ergebnis wie m/m³/h', () {
      final a = pruefePumpe(q: 1.5, h: 2.0, kurve: testKurve());
      final k2 = PumpenKurve(
        name: 'y',
        qEinheit: 'lmin',
        hEinheit: 'kpa',
        punkte: [
          for (final p in testKurve().punkte) QH(p.q / 0.06, p.h * 9.80665),
        ],
      );
      final b = pruefePumpe(q: 1.5, h: 2.0, kurve: k2);
      expect(b.eignung, a.eignung);
      expect(b.reserveH, closeTo(a.reserveH!, 1e-6));
    });
  });
}
