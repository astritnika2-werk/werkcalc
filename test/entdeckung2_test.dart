import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/katalog.dart';

void main() {
  test('Werkstoffe', () {
    final k = baueKatalog();
    final b = StringBuffer();
    for (final kw in ['Kupfer', 'Edelstahl', 'Mehrschicht', 'Verbund', 'PE-X', 'PE-RT']) {
      final m = <String, List<String>>{};
      for (final a in k) {
        if (a.name.contains(kw)) (m[a.familie] ??= []).add(a.name);
      }
      b.writeln('=$kw');
      m.forEach((f, l) => b.writeln('$f(${l.length}): ${l.first}${l.length > 1 ? ' / ${l[1]}' : ''}'));
    }
    fail(b.toString());
  });
}
