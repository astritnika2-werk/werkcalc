// Aus Text (Foto-Scan oder Sprache) werden Positionen mit Menge und
// passendem KATALOG-Artikel. Es wird nie ein neuer Artikel erfunden: Was nicht
// eindeutig gefunden wird, bleibt für den Nutzer sichtbar zum Prüfen.

import 'materialliste.dart';

enum Sicherheit {
  /// Genau ein passender Katalogartikel.
  sicher,

  /// Mehrere mögliche Artikel – Nutzer soll wählen.
  mehrere,

  /// Kein Artikel gefunden.
  keiner,
}

class ErkanntePosition {
  ErkanntePosition({
    required this.roh,
    required this.menge,
    required this.mengeAngegeben,
    required this.suche,
    required this.treffer,
    required this.sicherheit,
  }) : gewaehlt = sicherheit == Sicherheit.keiner ? null : treffer.first,
       einheit = treffer.isEmpty ? 'Stk.' : treffer.first.einheit,
       aktiv = sicherheit == Sicherheit.sicher;

  /// Ursprünglicher Textabschnitt.
  final String roh;
  double menge;

  /// false: im Text stand keine Menge, 1 wurde angenommen.
  final bool mengeAngegeben;

  /// Suchbegriff, der aus dem Text gebildet wurde.
  final String suche;

  /// Mögliche Katalogartikel (beste zuerst, höchstens 8).
  final List<KatalogArtikel> treffer;
  final Sicherheit sicherheit;
  KatalogArtikel? gewaehlt;
  String einheit;
  bool aktiv;
}

const _mengenEinheiten = {
  'm', 'meter', 'mtr', 'lfm', 'stk', 'stuck', 'st', 'x', 'mal', 'rolle',
  'rollen', 'sack', 'sacke', 'pack', 'packung', 'packungen', 'set', 'sets',
  'karton', 'eimer', 'dose', 'dosen', 'paar', 'kg', 'stange', 'stangen',
  'bund', 'beutel', 'flasche', 'flaschen', 'kanister', 'tube', 'tuben',
  'platte', 'platten', 'satz',
};

/// Folgt eine dieser Angaben auf eine Zahl, ist es ein Maß, keine Menge.
const _masswoerter = {
  'grad', 'mm', 'cm', 'zoll', 'dn', 'bar', 'kw', 'l', 'liter', 'kwh',
  'volt', 'watt', 'ampere', 'prozent', 'pn', 'i/i', 'i/a', 'a/i', 'a/a',
  'ig', 'ag', 'ig/ig', 'ig/ag', 'ag/ig', 'ag/ag',
};

const _zahlWoerter = {
  'ein': 1, 'eine': 1, 'einen': 1, 'einer': 1, 'zwei': 2, 'drei': 3,
  'vier': 4, 'funf': 5, 'sechs': 6, 'sieben': 7, 'acht': 8, 'neun': 9,
  'zehn': 10, 'elf': 11, 'zwolf': 12, 'dreizehn': 13, 'vierzehn': 14,
  'funfzehn': 15, 'sechzehn': 16, 'siebzehn': 17, 'achtzehn': 18,
  'neunzehn': 19, 'zwanzig': 20, 'dreissig': 30, 'vierzig': 40,
  'funfzig': 50, 'sechzig': 60, 'siebzig': 70, 'achtzig': 80, 'neunzig': 90,
  'hundert': 100,
};

/// Füllwörter, die die Suche nur stören.
const _fuellWoerter = {
  'grad', 'mm', 'durchmesser', 'von', 'aus', 'fur', 'und', 'der', 'die',
  'das', 'den', 'dem', 'ein', 'eine', 'einen', 'bitte', 'noch', 'dann',
  'brauche', 'brauchen', 'ca', 'circa', 'etwa', 'o', 'cm',
};

final _zifferRe = RegExp(r'^\d+(\.\d+)?$');

String _tokenNorm(String t) => normalisiereSuche(t)
    .replaceAll('°', '')
    .replaceAll(RegExp(r'[^a-z0-9./\-]'), '')
    .replaceAll(RegExp(r'^[./\-]+|[./\-]+$'), '');

double? _zahlWert(String norm) {
  if (_zifferRe.hasMatch(norm)) return double.tryParse(norm);
  return _zahlWoerter[norm]?.toDouble();
}

/// Zerlegt Text in Abschnitte (Zeilen, Kommas, „und“, Mengen-Grenzen).
List<String> teileAbschnitte(String text) {
  var t = text.replaceAll('\r', '\n');
  // Dezimalkomma bleibt erhalten: 2,5 → 2.5
  t = t.replaceAllMapped(
    RegExp(r'(\d),(\d)'),
    (m) => '${m[1]}.${m[2]}',
  );
  // Aufzählungszeichen und Spiegelstriche am Zeilenanfang entfernen.
  t = t.replaceAll(RegExp(r'^[\s•·*\-–—•●]+', multiLine: true), '');
  final grob = t
      .split(RegExp(r'[\n;,+]|\bund\b', caseSensitive: false))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty);
  final out = <String>[];
  for (final teil in grob) {
    out.addAll(_trenneBeiMengen(teil));
  }
  return out;
}

/// Ohne Kommas (Spracheingabe): Eine Zahl, auf die ein Wort folgt (kein Maß),
/// beginnt eine neue Position.
List<String> _trenneBeiMengen(String teil) {
  final tokens = teil.split(RegExp(r'\s+'));
  if (tokens.length < 3) return [teil];
  final norm = [for (final t in tokens) _tokenNorm(t)];
  final ergebnis = <List<String>>[];
  var aktuell = <String>[];
  var aktuellHatWort = false;
  for (var i = 0; i < tokens.length; i++) {
    final istZahl = _zahlWert(norm[i]) != null;
    final naechster = i + 1 < tokens.length ? norm[i + 1] : '';
    final beginnt = istZahl &&
        aktuellHatWort &&
        naechster.isNotEmpty &&
        _zahlWert(naechster) == null &&
        !_masswoerter.contains(naechster);
    if (beginnt) {
      ergebnis.add(aktuell);
      aktuell = <String>[];
      aktuellHatWort = false;
    }
    aktuell.add(tokens[i]);
    if (!istZahl && norm[i].isNotEmpty && !_mengenEinheiten.contains(norm[i])) {
      aktuellHatWort = true;
    }
  }
  ergebnis.add(aktuell);
  // „Kupferrohr 22 20 Meter“: Abschnitt ohne Produktwort gehört zum vorigen.
  final fertig = <String>[];
  for (final teile in ergebnis) {
    final text = teile.join(' ');
    final hatWort = teile.any((t) {
      final n = _tokenNorm(t);
      return n.isNotEmpty &&
          _zahlWert(n) == null &&
          !_mengenEinheiten.contains(n);
    });
    if (!hatWort && fertig.isNotEmpty) {
      fertig[fertig.length - 1] = '${fertig.last} $text';
    } else {
      fertig.add(text);
    }
  }
  return fertig;
}

class _Mengenteil {
  _Mengenteil(this.menge, this.angegeben, this.rest);

  final double menge;
  final bool angegeben;
  final List<String> rest;
}

_Mengenteil _trenneMenge(List<String> tokens) {
  final norm = [for (final t in tokens) _tokenNorm(t)];
  // Menge vorne: „20 m Kupferrohr“, „12 Bogen“
  if (tokens.length > 1) {
    final w = _zahlWert(norm[0]);
    if (w != null && w > 0 && !_masswoerter.contains(norm[1])) {
      var ab = 1;
      if (_mengenEinheiten.contains(norm[1])) ab = 2;
      if (ab < tokens.length) {
        return _Mengenteil(w, true, tokens.sublist(ab));
      }
    }
  }
  // „Kupferrohr 22 – 20 m“, „Muffen 22 x 8“, Menge hinten mit Einheit
  for (var i = tokens.length - 2; i >= 1; i--) {
    final w = _zahlWert(norm[i]);
    if (w != null &&
        w > 0 &&
        i + 1 == tokens.length - 1 &&
        const {'m', 'meter', 'mtr', 'lfm', 'stk', 'stuck', 'st', 'x', 'mal'}
            .contains(norm[i + 1])) {
      return _Mengenteil(w, true, tokens.sublist(0, i));
    }
  }
  if (tokens.length >= 3 && norm[tokens.length - 2] == 'x') {
    final w = _zahlWert(norm.last);
    if (w != null && w > 0) {
      return _Mengenteil(w, true, tokens.sublist(0, tokens.length - 2));
    }
  }
  return _Mengenteil(1, false, tokens);
}

/// Wandelt Text in Positionen um. Es werden nur Artikel aus [katalog] verwendet.
List<ErkanntePosition> erkenneText(String text, List<KatalogArtikel> katalog) {
  final out = <ErkanntePosition>[];
  for (final abschnitt in teileAbschnitte(text)) {
    final tokens = abschnitt.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) continue;
    final m = _trenneMenge(tokens);
    final begriffe = <String>[];
    for (final t in m.rest) {
      var n = normalisiereSuche(t).replaceAll('°', '');
      n = n.replaceAll(RegExp(r'[^a-z0-9./\-]'), '');
      n = n.replaceAll(RegExp(r'^[./\-]+|[./\-]+$'), '');
      if (n.isEmpty || _fuellWoerter.contains(n) || _mengenEinheiten.contains(n)) {
        continue;
      }
      final z = _zahlWoerter[n];
      begriffe.add(z != null ? '$z' : n);
    }
    if (begriffe.isEmpty) continue;
    final suche = begriffe.join(' ');
    final r = sucheKatalog(suche, katalog, limit: 40);
    final treffer = r.artikel;
    Sicherheit s;
    if (treffer.isEmpty) {
      s = Sicherheit.keiner;
    } else if (treffer.length == 1 ||
        normalisiereSuche(treffer.first.name) == normalisiereSuche(suche) ||
        treffer.skip(1).every((a) => a.name.length > treffer.first.name.length)) {
      // Eindeutig, wenn es nur einen Treffer gibt oder der erste Treffer der
      // schlichteste (kürzeste) Name ist.
      s = Sicherheit.sicher;
    } else {
      s = Sicherheit.mehrere;
    }
    out.add(
      ErkanntePosition(
        roh: abschnitt,
        menge: m.menge,
        mengeAngegeben: m.angegeben,
        suche: suche,
        treffer: treffer.take(8).toList(),
        sicherheit: s,
      ),
    );
  }
  return out;
}
