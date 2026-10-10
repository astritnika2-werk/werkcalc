import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/datensicherung.dart';
import 'package:werkcalc/logic.dart' show MaterialPosition;
import 'package:werkcalc/materialliste.dart';

Baustelle baustelle(String id, String name, {int n = 2}) => Baustelle(
      id: id,
      name: name,
      erstellt: DateTime.fromMillisecondsSinceEpoch(1760000000000),
      artikel: [
        for (var i = 0; i < n; i++)
          ListenArtikel(id: '$id-$i', name: 'Kupferrohr Ø22 mm', menge: 2.5 + i, einheit: 'm', erledigt: i.isEven),
      ],
    );

Sicherung muster({bool kosten = false}) => Sicherung(
      erstellt: DateTime(2026, 10, 10, 12),
      listen: [baustelle('a', 'Müllerstraße'), baustelle('b', 'Bahnhofstr. 5', n: 0)],
      eigene: [KatalogArtikel(name: 'Sonderteil', einheit: 'Stk.')],
      zuletzt: [KatalogArtikel(name: 'Muffe Kupfer Ø22', einheit: 'Stk.')],
      materialkosten: kosten ? [const MaterialPosition(name: 'Rohr', menge: 3, einzelpreis: 4.5)] : null,
    );

String mit(Map<String, dynamic> Function(Map<String, dynamic>) f) {
  final m = jsonDecode(sicherungAlsJson(muster())) as Map<String, dynamic>;
  return jsonEncode(f(m));
}

void main() {
  group('Sicherung: Format und Rundlauf', () {
    test('Rundlauf ohne Verlust', () {
      final r = pruefeSicherung(sicherungAlsJson(muster(kosten: true)));
      expect(r.ok, isTrue, reason: r.fehler);
      final s = r.sicherung!;
      expect(s.listen.length, 2);
      expect(s.listen.first.name, 'Müllerstraße');
      expect(s.listen.first.artikel.length, 2);
      expect(s.listen.first.artikel[1].menge, 3.5);
      expect(s.listen.first.artikel[0].erledigt, isTrue);
      expect(s.listen.first.artikel[1].erledigt, isFalse);
      expect(s.eigene.single.name, 'Sonderteil');
      expect(s.zuletzt.single.name, 'Muffe Kupfer Ø22');
      expect(s.materialkosten!.single.einzelpreis, 4.5);
      expect(s.anzahlPositionen, 2);
    });

    test('Ohne Materialkosten bleiben die Materialkosten unberührt (null)', () {
      expect(pruefeSicherung(sicherungAlsJson(muster())).sicherung!.materialkosten, isNull);
    });

    test('Dateiname', () {
      expect(sicherungDateiname(DateTime(2026, 1, 5)), 'werkcalc-sicherung-2026-01-05.json');
    });
  });

  group('Sicherung: ungültige Dateien werden abgelehnt (nichts wird übernommen)', () {
    void lehneAb(String name, String text, [String? teil]) {
      test(name, () {
        final r = pruefeSicherung(text);
        expect(r.ok, isFalse);
        expect(r.fehler, isNotEmpty);
        if (teil != null) expect(r.fehler, contains(teil));
      });
    }

    lehneAb('leer', '', 'leer');
    lehneAb('nur Leerzeichen', '   \n', 'leer');
    lehneAb('kein JSON', 'das ist kein json', 'JSON');
    lehneAb('abgeschnitten', sicherungAlsJson(muster()).substring(0, 60), 'JSON');
    lehneAb('JSON-Liste statt Objekt', '[1,2,3]', 'keine WerkCalc');
    lehneAb('falsches Format', '{"format":"anderes","version":1,"listen":[]}', 'Format');
    lehneAb('Version fehlt', '{"format":"$kSicherungFormat","listen":[]}', 'Version');
    lehneAb('neuere Version', '{"format":"$kSicherungFormat","version":99,"listen":[]}', 'neueren');
    lehneAb('listen fehlt', '{"format":"$kSicherungFormat","version":1}', 'Baustellen');
    lehneAb('listen kein Array', '{"format":"$kSicherungFormat","version":1,"listen":{}}', 'Baustellen');
    lehneAb('Baustelle ohne leere Kennung', mit((m) {
      ((m['listen'] as List)[0] as Map)['id'] = '';
      return m;
    }), 'Kennung');
    lehneAb('Baustelle ist kein Objekt', mit((m) {
      (m['listen'] as List)[0] = 5;
      return m;
    }), 'Baustelle 1');
    lehneAb('Baustelle ohne Kennung', mit((m) {
      ((m['listen'] as List)[0] as Map).remove('id');
      return m;
    }), 'Kennung');
    lehneAb('doppelte Baustelle', mit((m) {
      (m['listen'] as List).add((m['listen'] as List)[0]);
      return m;
    }), 'doppelt');
    lehneAb('Position mit Menge 0', mit((m) {
      ((((m['listen'] as List)[0] as Map)['artikel'] as List)[0] as Map)['menge'] = 0;
      return m;
    }), 'Menge');
    lehneAb('Position mit Text als Menge', mit((m) {
      ((((m['listen'] as List)[0] as Map)['artikel'] as List)[0] as Map)['menge'] = 'viel';
      return m;
    }), 'Menge');
    lehneAb('Position ohne Namen', mit((m) {
      ((((m['listen'] as List)[0] as Map)['artikel'] as List)[0] as Map)['name'] = ' ';
      return m;
    }), 'Namen');
    lehneAb('doppelte Position', mit((m) {
      final a = ((m['listen'] as List)[0] as Map)['artikel'] as List;
      a.add(a[0]);
      return m;
    }), 'doppelt');
    lehneAb('artikel kein Array', mit((m) {
      ((m['listen'] as List)[0] as Map)['artikel'] = 'x';
      return m;
    }), 'Positionen');
    lehneAb('eigene Artikel kaputt', mit((m) {
      m['eigeneArtikel'] = [5];
      return m;
    }), 'eigenen Artikel');
    lehneAb('Materialkosten kaputt', mit((m) {
      m['materialkosten'] = [
        {'n': 'x', 'm': 'zwei', 'p': 1}
      ];
      return m;
    }), 'Materialkosten');
    lehneAb('unplausibel groß', 'x' * (kSicherungMaxZeichen + 1), 'zu groß');
  });

  group('Lokale Ablage: streng lesen, nichts stillschweigend verlieren', () {
    Baustelle bau(Map<String, dynamic> m) => Baustelle.fromJson(m);

    test('bisheriges Format (so wie die App es bisher schreibt) wird gelesen', () {
      final alt = jsonEncode([for (final b in muster().listen) b.toJson()]);
      final r = leseListeStreng<Baustelle>(alt, bau);
      expect(r.defekt, isFalse);
      expect(r.daten.length, 2);
      expect(jsonEncode([for (final b in r.daten) b.toJson()]), alt, reason: 'Format bleibt unverändert');
    });

    test('fehlend oder leer ist kein Defekt', () {
      expect(leseListeStreng<Baustelle>(null, bau).defekt, isFalse);
      expect(leseListeStreng<Baustelle>('', bau).defekt, isFalse);
      expect(leseListeStreng<Baustelle>('[]', bau).daten, isEmpty);
    });

    test('kaputtes JSON ist ein Defekt', () {
      expect(leseListeStreng<Baustelle>('{kaputt', bau).defekt, isTrue);
      expect(leseListeStreng<Baustelle>('{"a":1}', bau).defekt, isTrue);
    });

    test('ein kaputter Eintrag: der Rest bleibt erhalten, Defekt wird gemeldet', () {
      final gut = jsonEncode(baustelle('x', 'Gut').toJson());
      final r = leseListeStreng<Baustelle>('[$gut, 5, {"artikel":"nein"}]', bau);
      expect(r.defekt, isTrue);
      expect(r.daten.single.name, 'Gut');
    });
  });
}
