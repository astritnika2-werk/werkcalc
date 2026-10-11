import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/katalog.dart';

void main() {
  test('Listen', () {
    final k = baueKatalog();
    final namen = {for (final a in k) a.name};
    final c = <String>[];
    for (final d in [12, 15, 18, 22, 28, 35, 42, 54]) {
      c.addAll(['Kupferrohr Ø$d mm', 'Pressfitting Bogen 90° Ø$d (Kupfer)', 'Pressfitting Bogen 45° Ø$d (Kupfer)',
        'Pressfitting T-Stück Ø$d (Kupfer)', 'Pressfitting Muffe Ø$d (Kupfer)', 'Pressfitting Kappe Ø$d (Kupfer)',
        'Pressfitting Endkappe Ø$d (Kupfer)', 'Rohrschelle Ø$d mit Gummieinlage', 'Isolierung Ø$d', 'Kugelhahn Press Ø$d']);
    }
    for (final d in [15, 18, 22, 28, 35, 42, 54]) {
      c.addAll(['Edelstahlrohr Ø$d mm', 'Pressfitting Bogen 90° Ø$d (Edelstahl)', 'Pressfitting Bogen 45° Ø$d (Edelstahl)',
        'Pressfitting T-Stück Ø$d (Edelstahl)', 'Pressfitting Muffe Ø$d (Edelstahl)', 'Pressfitting Kappe Ø$d (Edelstahl)',
        'Pressfitting Endkappe Ø$d (Edelstahl)', 'Rohrschelle Ø$d Edelstahl', 'Rohrschelle Ø$d mit Gummieinlage']);
    }
    c.addAll(['Duschwanne 90×90', 'Duscharmatur Aufputz', 'Duscharmatur Unterputz Set', 'Duschtür Schiebetür',
      'Badewanne 170×75', 'Badewannensiphon', 'Duschsiphon', 'Badheizkörper 800×500', 'Dichtband Wand/Boden',
      'Dichtband selbstklebend', 'Verbundabdichtung Dusche', 'Körperschalldämmung Dusche', 'Raumsparsiphon',
      'Heizkörper-Verschraubung ¾"', 'Heizkörperkonsole', 'Kompaktheizkörper Typ 22 500×800',
      'Kompaktheizkörper Typ 33 500×800', 'Kompaktheizkörper Typ 10 500×800', 'Spülkasten Unterputz',
      'Hanf Zopf 200 g', 'Dübel 6 mm', 'Dübel 10 mm', 'Silikon Sanitär transparent', 'Montagekleber Polymer',
      'Waschtisch Aufsatz rund', 'Waschtisch Aufsatz eckig', 'Waschtisch 120 cm']);
    final fehlt = [for (final n in c) if (!namen.contains(n)) n];
    final b = StringBuffer('FEHLT(${fehlt.length}/${c.length}): ${fehlt.join(' | ')}\n');
    for (final kw in ['Abdicht', 'Manschette', 'Schlämme', 'Grundier', 'Montageelement', 'Duschrinne', 'Bodenablauf', 'Wandablauf', 'Dichtmanschette']) {
      final m = k.where((a) => a.name.contains(kw) || a.familie.contains(kw)).map((a) => a.name).toSet().toList();
      b.writeln('=$kw(${m.length}): ${m.take(8).join(' | ')}');
    }
    for (final t in ['Typ 22', 'Typ 33', 'Typ 10', 'Typ 11', 'Typ 21']) {
      b.writeln('#$t: ${k.where((a) => a.name.startsWith('Kompaktheizkörper $t')).length}');
    }
    fail(b.toString());
  });
}
