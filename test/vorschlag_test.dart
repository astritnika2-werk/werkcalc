import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/katalog.dart';
import 'package:werkcalc/logic.dart';

void main() {
  final namen = baueKatalog().map((a) => a.name).toSet();

  test('feste Rechner-Vorschläge: jeder Name ist ein echter Katalogartikel', () {
    final fehlt = <String>[];
    void pruefe(String n) {
      if (!namen.contains(n)) fehlt.add(n);
    }

    for (final t in ['25-40', '25-60', '25-80', '32-60', '32-80']) {
      pruefe('Umwälzpumpe Hocheffizienz $t');
    }
    for (final g in kPumpenGewinde.values) {
      pruefe('Pumpenverschraubung $g');
      pruefe('Kugelhahn $g IG/IG');
      pruefe('Flachdichtung Fiber $g');
    }
    pruefe('Pumpenisolierschale Heizung');
    for (final n in [
      'Thermostatkopf',
      'Thermostatventil gerade ½"',
      'Rücklaufverschraubung gerade ½"',
      'Heizkörper-Entlüfter ½"',
    ]) {
      pruefe(n);
    }
    if (fehlt.isNotEmpty) fail('nicht im Katalog: ${fehlt.join(' | ')}');
  });
}
