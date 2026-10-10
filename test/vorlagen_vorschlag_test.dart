import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/katalog.dart';
import 'package:werkcalc/materialliste.dart';

/// Vorschläge für Vorlagen: nur Artikel, die es im Katalog gibt. Ohne Mengen.
const Map<String, List<String>> kVorschlag = {
  'Heizkörper austauschen': [
    'Thermostatkopf', 'Thermostatventil gerade ½"', 'Rücklaufverschraubung gerade ½"',
    'Heizkörper-Entlüfter ½"', 'Heizkörper-Blindstopfen ½"', 'Heizkörper-Wandhalter Set',
    'Heizkörper-Rosette Ø15', 'Heizkörper-Anschlussset', 'Heizkörper-Verschraubung ½"',
    'Hanf Zopf 100 g', 'Dichtung Heizkörper Set', 'Heizkörper-Entlüftungsschlüssel',
  ],
  'Waschbecken montieren': [
    'Waschtisch 60 cm', 'Waschtischarmatur Einhebelmischer', 'Ablaufgarnitur Waschtisch mit Überlauf',
    'Eckventil chrom ½"×⅜"', 'Anschlussschlauch ⅜" 500 mm', 'Flaschensiphon',
    'Dichtung Siphon Set', 'Körperschalldämmung Waschtisch', 'Silikon sanitär',
  ],
  'WC montieren': [
    'WC wandhängend Tiefspüler', 'WC-Sitz', 'Spülkasten Unterputz', 'Vorwandelement WC',
    'Drückerplatte Dual weiß', 'Dichtung WC-Anschluss', 'Körperschalldämmung WC',
    'WC-Anschlussbogen', 'Eckventil chrom ½"×⅜"', 'Anschlussschlauch ⅜" 300 mm',
  ],
  'Wasserleitung verlegen': [
    'Kupferrohr Ø22 mm', 'Pressfitting Bogen 90° Ø22 (Kupfer)', 'Pressfitting Bogen 45° Ø22 (Kupfer)',
    'Pressfitting T-Stück Ø22 (Kupfer)', 'Pressfitting Muffe Ø22 (Kupfer)',
    'Pressfitting Endkappe Ø22 (Kupfer)', 'Rohrschelle Ø22 mit Gummieinlage', 'Isolierung Ø22',
    'Kugelhahn 3/4', 'Dübel', 'Hanf Zopf 100 g',
  ],
  'Badsanierung': [
    'WC wandhängend Tiefspüler', 'Waschtisch 60 cm', 'Waschtischarmatur Einhebelmischer',
    'Duscharmatur Unterputz Set', 'Duschsiphon', 'Badewannensiphon', 'Badheizkörper',
    'Dichtband Wand/Boden', 'Vorwandelement WC', 'Drückerplatte Dual weiß',
  ],
};

void main() {
  final katalog = baueKatalog();
  final namen = {for (final a in katalog) a.name};
  test('Vorschläge prüfen (Bericht)', () {
    final b = StringBuffer();
    kVorschlag.forEach((v, l) {
      for (final n in l) {
        if (namen.contains(n)) continue;
        final r = sucheKatalog(n, katalog, limit: 4).artikel.map((a) => a.name).toList();
        b.writeln('FEHLT [$v] $n -> $r');
      }
    });
    // ignore: avoid_print
    print(b.isEmpty ? 'ALLE VORHANDEN' : b.toString());
  });
}
