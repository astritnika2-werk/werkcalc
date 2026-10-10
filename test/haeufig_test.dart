import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/materialliste.dart';

Baustelle b(String id, List<String> namen) => Baustelle(
      id: id,
      name: id,
      erstellt: DateTime.fromMillisecondsSinceEpoch(1760000000000),
      artikel: [
        for (var i = 0; i < namen.length; i++)
          ListenArtikel(id: '$id$i', name: namen[i], menge: 1, einheit: 'Stk.'),
      ],
    );

void main() {
  test('häufigste Artikel: nach Anzahl der Listen, dann alphabetisch, Mindestanzahl 2', () {
    final l = [
      b('a', ['Muffe', 'Bogen', 'Einmalig']),
      b('b', ['Muffe', 'Bogen', 'Dübel']),
      b('c', ['Muffe', 'Dübel']),
    ];
    expect(haeufigsteArtikel(l), ['Muffe', 'Bogen', 'Dübel']);
    expect(haeufigsteArtikel(l, limit: 1), ['Muffe']);
    expect(haeufigsteArtikel(l, minimum: 3), ['Muffe']);
    expect(haeufigsteArtikel(const []), isEmpty);
    expect(haeufigsteArtikel([b('x', ['A'])]), isEmpty);
  });
}
