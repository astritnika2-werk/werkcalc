// Datensicherung (Backup/Restore) für Baustellen und Materiallisten.
// Reine Dart-Logik ohne Flutter: Format, Prüfung und Umwandlung. Nichts hier
// schreibt auf das Gerät. Das Format ändert die bestehende Ablage nicht.

import 'dart:convert';

import 'logic.dart' show MaterialPosition;
import 'materialliste.dart';

const String kSicherungFormat = 'werkcalc-datensicherung';
const int kSicherungVersion = 1;
const int kSicherungMaxZeichen = 5 * 1000 * 1000;
const int kSicherungMaxBaustellen = 2000;
const int kSicherungMaxArtikel = 5000;

/// Inhalt einer Sicherung.
class Sicherung {
  Sicherung({
    required this.erstellt,
    required this.listen,
    this.eigene = const [],
    this.zuletzt = const [],
    this.materialkosten,
  });

  final DateTime erstellt;
  final List<Baustelle> listen;
  final List<KatalogArtikel> eigene;
  final List<KatalogArtikel> zuletzt;

  /// Liste der Materialkosten-Seite (mit Preisen des Nutzers). null: nicht enthalten.
  final List<MaterialPosition>? materialkosten;

  int get anzahlPositionen => listen.fold(0, (s, b) => s + b.artikel.length);
}

/// Baut den Sicherungstext (JSON).
String sicherungAlsJson(Sicherung s) => jsonEncode({
      'format': kSicherungFormat,
      'version': kSicherungVersion,
      'app': 'WerkCalc',
      'erstellt': s.erstellt.toIso8601String(),
      'listen': [for (final b in s.listen) b.toJson()],
      'eigeneArtikel': [for (final a in s.eigene) a.toJson()],
      'zuletzt': [for (final a in s.zuletzt) a.toJson()],
      if (s.materialkosten != null) 'materialkosten': [for (final m in s.materialkosten!) m.toJson()],
    });

/// Ergebnis der Prüfung: entweder eine brauchbare [sicherung] oder eine
/// verständliche [fehler]-Meldung. Bei einem Fehler wurde nichts verändert.
class SicherungPruefung {
  const SicherungPruefung.ok(Sicherung this.sicherung) : fehler = null;
  const SicherungPruefung.fehler(String this.fehler) : sicherung = null;

  final Sicherung? sicherung;
  final String? fehler;
  bool get ok => sicherung != null;
}

SicherungPruefung _f(String m) => SicherungPruefung.fehler(m);

bool _istText(Object? v) => v is String;
bool _istZahl(Object? v) => v is num && v.isFinite;

/// Prüft den Text einer Sicherung streng, bevor irgendetwas übernommen wird.
SicherungPruefung pruefeSicherung(String text) {
  if (text.trim().isEmpty) return _f('Die Datei ist leer.');
  if (text.length > kSicherungMaxZeichen) {
    return _f('Die Datei ist zu groß für eine WerkCalc-Sicherung.');
  }
  Object? roh;
  try {
    roh = jsonDecode(text);
  } catch (_) {
    return _f('Die Datei ist keine lesbare WerkCalc-Sicherung (kein gültiges JSON).');
  }
  if (roh is! Map) return _f('Die Datei ist keine WerkCalc-Sicherung.');
  final Map r0 = roh;
  if (r0['format'] != kSicherungFormat) {
    return _f('Das ist keine WerkCalc-Sicherung (falsches Format).');
  }
  final version = r0['version'];
  if (version is! int || version < 1) return _f('Die Version der Sicherung ist nicht lesbar.');
  if (version > kSicherungVersion) {
    return _f('Die Sicherung stammt aus einer neueren WerkCalc-Version (Version $version). '
        'Bitte WerkCalc aktualisieren.');
  }
  final listenRoh = r0['listen'];
  if (listenRoh is! List) return _f('In der Sicherung fehlen die Baustellen („listen“).');
  if (listenRoh.length > kSicherungMaxBaustellen) {
    return _f('Die Sicherung enthält unplausibel viele Baustellen (${listenRoh.length}).');
  }

  final listen = <Baustelle>[];
  final ids = <String>{};
  for (var i = 0; i < listenRoh.length; i++) {
    final e = listenRoh[i];
    final pos = 'Baustelle ${i + 1}';
    if (e is! Map) return _f('$pos ist nicht lesbar.');
    if (!_istText(e['id']) || (e['id'] as String).isEmpty) return _f('$pos hat keine Kennung.');
    if (!_istText(e['name'])) return _f('$pos hat keinen Namen.');
    if (e['erstellt'] != null && !_istZahl(e['erstellt'])) return _f('$pos hat ein ungültiges Datum.');
    if (!ids.add(e['id'] as String)) return _f('$pos kommt doppelt vor.');
    final artikelRoh = e['artikel'];
    if (artikelRoh != null && artikelRoh is! List) return _f('Die Positionen von „${e['name']}“ sind nicht lesbar.');
    final al = (artikelRoh as List?) ?? const [];
    if (al.length > kSicherungMaxArtikel) {
      return _f('„${e['name']}“ enthält unplausibel viele Positionen (${al.length}).');
    }
    final aIds = <String>{};
    for (var k = 0; k < al.length; k++) {
      final a = al[k];
      final ap = 'Position ${k + 1} in „${e['name']}“';
      if (a is! Map) return _f('$ap ist nicht lesbar.');
      if (!_istText(a['id']) || (a['id'] as String).isEmpty) return _f('$ap hat keine Kennung.');
      if (!aIds.add(a['id'] as String)) return _f('$ap kommt doppelt vor.');
      if (!_istText(a['name']) || (a['name'] as String).trim().isEmpty) return _f('$ap hat keinen Namen.');
      if (!_istZahl(a['menge']) || (a['menge'] as num) <= 0) return _f('$ap hat keine gültige Menge.');
      if (a['einheit'] != null && !_istText(a['einheit'])) return _f('$ap hat keine gültige Einheit.');
    }
    try {
      listen.add(Baustelle.fromJson(Map<String, dynamic>.from(e)));
    } catch (_) {
      return _f('$pos ist nicht lesbar.');
    }
  }

  List<KatalogArtikel> katalogListe(String schluessel, String bez) {
    final r = r0[schluessel];
    if (r == null) return [];
    if (r is! List) throw FormatException(bez);
    return [
      for (final a in r)
        if (a is Map && _istText(a['name']) && (a['name'] as String).trim().isNotEmpty)
          KatalogArtikel.fromJson(Map<String, dynamic>.from(a))
        else
          throw FormatException(bez),
    ];
  }

  List<KatalogArtikel> eigene, zuletzt;
  try {
    eigene = [
      for (final a in katalogListe('eigeneArtikel', 'eigenen Artikel'))
        KatalogArtikel(name: a.name, einheit: a.einheit, kategorie: 'Eigene Artikel', unter: 'Eigene'),
    ];
    zuletzt = katalogListe('zuletzt', 'zuletzt verwendete Artikel');
  } on FormatException catch (e) {
    return _f('Die ${e.message} in der Sicherung sind nicht lesbar.');
  }

  List<MaterialPosition>? kosten;
  final k = r0['materialkosten'];
  if (k != null) {
    if (k is! List) return _f('Die Materialkosten in der Sicherung sind nicht lesbar.');
    try {
      kosten = [
        for (final m in k)
          if (m is Map &&
              _istText(m['n']) &&
              _istZahl(m['m']) &&
              _istZahl(m['p']))
            MaterialPosition.fromJson(Map<String, dynamic>.from(m))
          else
            throw const FormatException('x'),
      ];
    } catch (_) {
      return _f('Die Materialkosten in der Sicherung sind nicht lesbar.');
    }
  }

  DateTime erstellt = DateTime.fromMillisecondsSinceEpoch(0);
  final er = r0['erstellt'];
  if (er is String) erstellt = DateTime.tryParse(er) ?? erstellt;

  return SicherungPruefung.ok(Sicherung(
    erstellt: erstellt,
    listen: listen,
    eigene: eigene,
    zuletzt: zuletzt,
    materialkosten: kosten,
  ));
}

/// Dateiname für den Export: werkcalc-sicherung-2026-10-10.json
String sicherungDateiname(DateTime t) {
  String z(int v) => v.toString().padLeft(2, '0');
  return 'werkcalc-sicherung-${t.year}-${z(t.month)}-${z(t.day)}.json';
}

/// Streng gelesene Liste aus der lokalen Ablage (JSON-Text). [defekt] ist true,
/// wenn der Text nicht oder nur teilweise gelesen werden konnte; die lesbaren
/// Einträge bleiben in [daten] erhalten.
class LeseErgebnis<T> {
  const LeseErgebnis(this.daten, this.defekt);
  final List<T> daten;
  final bool defekt;
}

LeseErgebnis<T> leseListeStreng<T>(String? raw, T Function(Map<String, dynamic>) bauen) {
  if (raw == null || raw.trim().isEmpty) return LeseErgebnis<T>(const [], false);
  Object? liste;
  try {
    liste = jsonDecode(raw);
  } catch (_) {
    return LeseErgebnis<T>(const [], true);
  }
  if (liste is! List) return LeseErgebnis<T>(const [], true);
  final out = <T>[];
  var defekt = false;
  for (final e in liste) {
    try {
      out.add(bauen(Map<String, dynamic>.from(e as Map)));
    } catch (_) {
      defekt = true;
    }
  }
  return LeseErgebnis<T>(out, defekt);
}
