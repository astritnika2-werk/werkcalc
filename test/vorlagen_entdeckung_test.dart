import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/katalog.dart';

void main() {
  test('Varianten im Katalog (Bericht)', () {
    final k = baueKatalog();
    final praefixe = [
      'Thermostatkopf', 'Thermostatventil', 'Rücklaufverschraubung', 'Heizkörper-Anschlussset', 'Heizkörper-Rosette',
      'Heizkörper-Wandhalter', 'Heizkörper-Entlüfter', 'Heizkörper-Blindstopfen', 'Kompaktheizkörper', 'Hanf Zopf',
      'Waschtisch ', 'Waschtischarmatur', 'Ablaufgarnitur Waschtisch', 'Flaschensiphon', 'Röhrensiphon', 'Eckventil',
      'Anschlussschlauch', 'Silikon Sanitär', 'WC ', 'WC-Sitz', 'Vorwandelement', 'Drückerplatte', 'WC-Anschlussbogen',
      'Spülkasten', 'Kupferrohr', 'Mehrschichtverbundrohr', 'Edelstahlrohr', 'PE-X', 'Kugelhahn', 'Rohrschelle Ø22',
      'Isolierung Ø22', 'Dübel ', 'Duscharmatur', 'Duschsiphon', 'Badewannensiphon', 'Badheizkörper', 'Dichtband',
      'Pressfitting Bogen 90°', 'Pressfitting Muffe', 'Pressfitting T-Stück', 'Pressfitting Endkappe', 'Schraubfitting',
      'Dichtung WC', 'Körperschalldämmung', 'Wandwinkel', 'Montagekleber', 'Duschwanne', 'Badewanne', 'Duschtür',
    ];
    final b = StringBuffer();
    for (final p in praefixe) {
      final n = k.where((a) => a.name.startsWith(p)).map((a) => a.name).toSet().toList();
      b.writeln('## $p (${n.length}): ${n.take(30).join(' | ')}');
    }
    expect(b.toString(), isEmpty, reason: 'Bericht');
  });
}
