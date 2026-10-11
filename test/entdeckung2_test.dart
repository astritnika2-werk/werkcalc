import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/katalog.dart';

void main() {
  for (final kw in ['Edelstahl', 'Mehrschicht', 'PE-X', 'PE-RT']) {
    test('W $kw', () {
      final k = baueKatalog();
      final m = <String, List<String>>{};
      for (final a in k) {
        if (a.name.contains(kw) || a.familie.contains(kw)) (m[a.familie] ??= []).add(a.name);
      }
      final b = StringBuffer('=$kw\n');
      m.forEach((f, l) => b.writeln('$f(${l.length}): ${l.first}'));
      fail(b.toString());
    });
  }
}
