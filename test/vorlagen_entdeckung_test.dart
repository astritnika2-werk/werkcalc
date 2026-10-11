import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/katalog.dart';

void main() {
  test('kompakt', () {
    final k = baueKatalog();
    const p = [
      'Mehrschichtverbundrohr', 'Edelstahlrohr', 'PE-X', 'Kugelhahn', 'Rohrschelle Ø22', 'Isolierung Ø22', 'Dübel ',
      'Duscharmatur', 'Duschsiphon', 'Badewannensiphon', 'Badheizkörper', 'Dichtband', 'Pressfitting Bogen 90° Ø22',
      'Pressfitting Muffe Ø22', 'Pressfitting T-Stück Ø22', 'Pressfitting Endkappe Ø22', 'Schraubfitting', 'Dichtung WC',
      'Körperschalldämmung', 'Wandwinkel', 'Montagekleber', 'Duschwanne', 'Badewanne', 'Duschtür', 'Haltegriff',
    ];
    final b = StringBuffer();
    for (final x in p) {
      final n = k.where((a) => a.name.startsWith(x)).map((a) => a.name.substring(x.length).trim()).toSet().toList();
      b.writeln('#$x(${n.length}):${n.take(14).join('|')}');
    }
    fail(b.toString());
  });
}
