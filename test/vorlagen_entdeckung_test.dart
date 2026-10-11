import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/katalog.dart';

const praefixe = [
    'Thermostatkopf', 'Thermostatventil', 'Rücklaufverschraubung', 'Heizkörper-Anschlussset', 'Heizkörper-Rosette',
    'Heizkörper-Wandhalter', 'Heizkörper-Entlüfter', 'Heizkörper-Blindstopfen', 'Kompaktheizkörper', 'Hanf Zopf',
    'Waschtisch ', 'Waschtischarmatur', 'Ablaufgarnitur Waschtisch', 'Flaschensiphon', 'Röhrensiphon', 'Eckventil',
    'Anschlussschlauch', 'Silikon Sanitär', 'WC ', 'WC-Sitz', 'Vorwandelement', 'Drückerplatte', 'WC-Anschlussbogen',
    'Spülkasten', 'Kupferrohr', 'Mehrschichtverbundrohr', 'Edelstahlrohr', 'PE-X', 'Kugelhahn', 'Rohrschelle Ø22',
    'Isolierung Ø22', 'Dübel ', 'Duscharmatur', 'Duschsiphon', 'Badewannensiphon', 'Badheizkörper', 'Dichtband',
    'Pressfitting Bogen 90°', 'Pressfitting Muffe', 'Pressfitting T-Stück', 'Pressfitting Endkappe', 'Schraubfitting',
    'Dichtung WC', 'Körperschalldämmung', 'Wandwinkel', 'Montagekleber', 'Duschwanne', 'Badewanne', 'Duschtür',
  ];


void main() {
  final k = baueKatalog();
  for (final p in praefixe.skip(11)) {
    test('V $p', () {
      final n = k.where((a) => a.name.startsWith(p)).map((a) => a.name).toSet().toList();
      expect('## $p (${n.length}): ${n.take(18).join(' | ')}', isEmpty);
    });
  }
}
