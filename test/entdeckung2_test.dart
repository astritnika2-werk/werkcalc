import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/katalog.dart';

void main() {
  test('W', () {
    final k = baueKatalog();
    final b = StringBuffer();
    for (final kw in ['PE-X', 'PE-RT', 'Verbund', 'Klemmring', 'Presshülse', 'Alu-Verbund', 'Sauerstoff']) {
      final m = <String, List<String>>{};
      for (final a in k) {
        if (a.name.contains(kw) || a.familie.contains(kw)) (m[a.familie] ??= []).add(a.name);
      }
      b.writeln('=$kw ${m.entries.map((e) => '${e.key}(${e.value.length}):${e.value.first}').join(' ; ')}');
    }
    fail(b.toString());
  });
}
