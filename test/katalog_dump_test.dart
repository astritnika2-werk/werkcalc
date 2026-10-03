import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/katalog.dart';

/// Schreibt eine kompakte Übersicht des Katalogs (Prüfung auf Lücken).
void main() {
  test('Katalog-Übersicht schreiben', () {
    final k = baueKatalog();
    final b = StringBuffer('Artikel: ${k.length}\n');
    final nachKat = <String, Map<String, Map<String, List<String>>>>{};
    for (final a in k) {
      nachKat
          .putIfAbsent(a.kategorie, () => {})
          .putIfAbsent(a.unter, () => {})
          .putIfAbsent(a.familie, () => [])
          .add(a.name);
    }
    nachKat.forEach((kat, unterMap) {
      final n = unterMap.values.fold<int>(0, (s, m) => s + m.values.fold<int>(0, (t, l) => t + l.length));
      b.writeln('\n## $kat ($n)');
      unterMap.forEach((u, famMap) {
        b.writeln('# $u');
        famMap.forEach((f, namen) {
          final rest = [
            for (final n in namen)
              n.startsWith(f) && n.length > f.length ? n.substring(f.length).trim() : n,
          ];
          if (rest.length <= 14) {
            b.writeln('$f [${rest.length}]: ${rest.join(' | ')}');
          } else {
            b.writeln('$f [${rest.length}]: ${rest.take(7).join(' | ')} … ${rest.skip(rest.length - 4).join(' | ')}');
          }
        });
      });
    });
    File('katalog_dump.txt').writeAsStringSync(b.toString());
  });
}
