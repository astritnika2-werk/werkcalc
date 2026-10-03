// Materiallisten: reine Dart-Logik (ohne Flutter), damit sie sich testen lässt.
// Keine Preise, keine Großhändler: nur Artikel, Mengen und Einheiten.

import 'logic.dart';

/// Einheiten zur Auswahl beim Hinzufügen.
const List<String> kMaterialEinheiten = [
  'Stk.',
  'm',
  'Set',
  'Pack',
  'Rolle',
  'Paar',
  'kg',
  'l',
  'm²',
];

/// Ein Eintrag in einer Materialliste.
class ListenArtikel {
  const ListenArtikel({
    required this.id,
    required this.name,
    required this.menge,
    required this.einheit,
    this.erledigt = false,
  });

  final String id;
  final String name;
  final double menge;
  final String einheit;
  final bool erledigt;

  ListenArtikel copyWith({
    String? name,
    double? menge,
    String? einheit,
    bool? erledigt,
  }) =>
      ListenArtikel(
        id: id,
        name: name ?? this.name,
        menge: menge ?? this.menge,
        einheit: einheit ?? this.einheit,
        erledigt: erledigt ?? this.erledigt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'menge': menge,
        'einheit': einheit,
        'erledigt': erledigt,
      };

  factory ListenArtikel.fromJson(Map<String, dynamic> j) => ListenArtikel(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        menge: (j['menge'] as num?)?.toDouble() ?? 1,
        einheit: (j['einheit'] ?? 'Stk.').toString(),
        erledigt: j['erledigt'] == true,
      );
}

/// Eine Materialliste für eine Baustelle.
class Baustelle {
  const Baustelle({
    required this.id,
    required this.name,
    this.artikel = const [],
    required this.erstellt,
  });

  final String id;
  final String name;
  final List<ListenArtikel> artikel;
  final DateTime erstellt;

  int get anzahl => artikel.length;
  int get anzahlErledigt => artikel.where((a) => a.erledigt).length;
  bool get alleErledigt => artikel.isNotEmpty && anzahlErledigt == anzahl;

  Baustelle copyWith({String? name, List<ListenArtikel>? artikel}) => Baustelle(
        id: id,
        name: name ?? this.name,
        artikel: artikel ?? this.artikel,
        erstellt: erstellt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'erstellt': erstellt.millisecondsSinceEpoch,
        'artikel': [for (final a in artikel) a.toJson()],
      };

  factory Baustelle.fromJson(Map<String, dynamic> j) => Baustelle(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        erstellt: DateTime.fromMillisecondsSinceEpoch(
          (j['erstellt'] as num?)?.toInt() ?? 0,
        ),
        artikel: [
          for (final e in (j['artikel'] as List<dynamic>? ?? const []))
            ListenArtikel.fromJson(Map<String, dynamic>.from(e as Map)),
        ],
      );
}

/// Ein Artikel aus dem Katalog. Der Name ist immer die fachliche deutsche
/// Bezeichnung; sie wird so in die Liste übernommen.
class KatalogArtikel {
  const KatalogArtikel({
    required this.name,
    required this.einheit,
    this.kategorie = 'Eigene Artikel',
    this.unter = 'Eigene',
    String? familie,
    this.typ = '',
  }) : _familie = familie;

  final String name;
  final String einheit;
  final String kategorie;
  final String unter;
  final String typ;
  final String? _familie;

  /// Produktfamilie ohne Größe, z. B. „Kupferrohr“.
  String get familie => _familie ?? name;

  Map<String, dynamic> toJson() => {'name': name, 'einheit': einheit};

  factory KatalogArtikel.fromJson(Map<String, dynamic> j) => KatalogArtikel(
        name: (j['name'] ?? '').toString(),
        einheit: (j['einheit'] ?? 'Stk.').toString(),
      );
}

/// Vereinfacht Text für die Suche: Kleinbuchstaben, ohne Umlaute und
/// Sonderzeichen, mit einheitlichen Brüchen und Durchmesserzeichen.
/// „ue“, „ae“, „oe“ werden wie ü, ä, ö behandelt (beide Schreibweisen finden sich).
String normalisiereSuche(String s) {
  const ersatz = {
    'ä': 'a', 'ö': 'o', 'ü': 'u', 'ß': 'ss', 'ë': 'e', 'ç': 'c',
    'ø': 'o', '⌀': 'o', '¼': '1/4', '½': '1/2', '¾': '3/4',
    '⅜': '3/8', '⅝': '5/8', '"': '', '”': '', '“': '', '″': '',
  };
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    b.write(ersatz[ch] ?? ch);
  }
  return b
      .toString()
      .replaceAll('ue', 'u')
      .replaceAll('ae', 'a')
      .replaceAll('oe', 'o');
}

/// Kurzwörter und Handwerkersprache (auch albanisch/balkanisch) → deutsche
/// Suchbegriffe (normalisiert). Gespeichert wird immer der deutsche Name.
const Map<String, List<String>> kSynonyme = {
  'gyp': ['rohr'], 'tub': ['rohr'], 'cev': ['rohr'], 'cijev': ['rohr'],
  'rur': ['rohr'], 'pipe': ['rohr'], 'leitung': ['rohr', 'leitung'],
  'kthes': ['bogen'], 'kthim': ['bogen'], 'bog': ['bogen'],
  'koleno': ['bogen'], 'kolen': ['bogen'], 'knie': ['bogen'],
  'winkel': ['bogen', 'winkel'], 'krumm': ['bogen'],
  't': ['t-stuck'], 'te': ['t-stuck'], 'tee': ['t-stuck'],
  'abzweig': ['abzweig', 't-stuck'], 'degez': ['abzweig'], 'degim': ['abzweig'],
  'muf': ['muffe'], 'spojnica': ['muffe'], 'kupplung': ['muffe'],
  'reduk': ['reduzier'], 'redukcija': ['reduzier'], 'reduz': ['reduzier'],
  'ubergang': ['ubergang'], 'kalim': ['ubergang'], 'nippel': ['nippel'],
  'ventil': ['ventil'], 'vent': ['ventil'], 'kugelhahn': ['kugelhahn'],
  'kugel': ['kugelhahn'], 'hahn': ['hahn'], 'kran': ['hahn', 'armatur'],
  'izol': ['isolier'], 'izolim': ['isolier'], 'izolacion': ['isolier'],
  'izolacija': ['isolier'], 'dam': ['isolier'], 'daem': ['isolier'],
  'pomp': ['pumpe'], 'pumpe': ['pumpe'], 'pompa': ['pumpe'],
  'radiator': ['heizkorper'], 'kalorifer': ['heizkorper'],
  'heiz': ['heizkorper', 'heiz'], 'termostat': ['thermostat'],
  'lavaman': ['waschtisch', 'waschbecken'], 'lavabo': ['waschtisch', 'waschbecken'],
  'waschbecken': ['waschtisch', 'waschbecken'], 'tualet': ['wc'],
  'sifon': ['siphon'], 'siphon': ['siphon'], 'dush': ['dusche', 'brause'],
  'tus': ['dusche', 'brause'], 'bojler': ['speicher', 'boiler'],
  'boiler': ['speicher', 'boiler'], 'rubinet': ['armatur'],
  'vida': ['schraube'], 'vidha': ['schraube'], 'shraf': ['schraube'],
  'schr': ['schraube'], 'dubel': ['dubel'], 'diibel': ['dubel'],
  'dubl': ['dubel'], 'teflon': ['fittingband'], 'kanal': ['kg-', 'ht-'],
  'kanaliz': ['kg-', 'ht-'], 'kondens': ['kondensat'], 'klima': ['klima'],
  'lemer': ['lotzinn'], 'sheshe': ['schelle'], 'skele': ['schelle'],
  'schelle': ['schelle'], 'press': ['pressfitting'], 'gewinde': ['gewinde'],
  'kupfer': ['kupfer'], 'bakri': ['kupfer'], 'inox': ['edelstahl'],
  'edelstahl': ['edelstahl'], 'plastik': ['kunststoff'], 'plast': ['kunststoff'],
  'pvc': ['kunststoff', 'pvc', 'pp-r'], 'ppr': ['pp-r'], 'pex': ['pe-x'],
  'verbund': ['mehrschicht'], 'mv': ['mehrschicht'], 'alupex': ['mehrschicht'],
  'lufte': ['luftung'], 'ventilator': ['ventilator', 'luftung'],
  'tape': ['band'], 'ngjit': ['kleb'], 'silikon': ['silikon'],
};

final RegExp _zahlToken = RegExp(r'^[0-9][0-9,./]*$');

bool _wortAnfang(String text, int index) {
  if (index == 0) return true;
  final c = text[index - 1];
  return c == ' ' || c == '-' || c == '/' || c == '(' || c == ',';
}

List<String> _synonymeFuer(String token) {
  final out = <String>{};
  kSynonyme.forEach((key, werte) {
    final passt = key == token ||
        (token.length >= 3 &&
            (key.startsWith(token) || (key.length >= 3 && token.startsWith(key))));
    if (passt) out.addAll(werte);
  });
  return out.toList();
}

bool _zahlPasst(String text, String zahl) =>
    RegExp('(?<![0-9])${RegExp.escape(zahl)}(?![0-9])').hasMatch(text);

/// Bewertet einen Artikel für die Eingabe. 0 heißt: kein Treffer.
int _bewerte(
  String name,
  String familie,
  List<String> woerter,
  List<List<String>> synonyme,
) {
  var punkte = 0;
  for (var i = 0; i < woerter.length; i++) {
    final t = woerter[i];
    if (_zahlToken.hasMatch(t)) {
      if (!_zahlPasst(name, t)) return 0;
      punkte += 2;
      continue;
    }
    var treffer = 0;
    final idx = name.indexOf(t);
    if (idx >= 0) {
      final anfang = _wortAnfang(name, idx);
      if (t.length >= 3) {
        treffer = anfang ? 4 : 2;
      } else if (t.length == 2 && anfang) {
        treffer = 4;
      } else if (t.length == 1 && anfang && synonyme[i].isEmpty) {
        treffer = 3;
      }
    }
    if (treffer > 0 && i == 0 && idx == 0) treffer += 2; // beginnt mit dem Suchwort
    if (treffer == 0) {
      for (final kw in synonyme[i]) {
        if (name.contains(kw)) {
          treffer = 2;
          if (familie.endsWith(kw)) treffer += 3;
          break;
        }
      }
    } else if (familie.endsWith(t)) {
      treffer += 3;
    }
    if (treffer == 0) return 0;
    punkte += treffer;
  }
  return punkte;
}

/// Ergebnis der Schnellsuche: Produktfamilien (zum Eingrenzen) und Artikel.
class SuchErgebnis {
  const SuchErgebnis(this.familien, this.artikel);

  final List<FamilienTreffer> familien;
  final List<KatalogArtikel> artikel;
}

class FamilienTreffer {
  const FamilienTreffer(this.name, this.anzahl);

  final String name;
  final int anzahl;
}

/// Schnellsuche mit Vorschlägen. Jedes Wort der Eingabe muss passen
/// (Reihenfolge egal, Teilwörter reichen, Kurzwörter und Handwerkersprache
/// werden verstanden). Beispiele: „kup 22“ → Kupferrohr Ø22 mm,
/// „bogen 22“ → Bögen Ø22, „gyp“ → alle Rohr-Familien.
SuchErgebnis sucheKatalog(
  String eingabe,
  List<KatalogArtikel> katalog, {
  int limit = 60,
  int familienLimit = 10,
}) {
  final woerter = normalisiereSuche(eingabe)
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (woerter.isEmpty) {
    return SuchErgebnis(const [], katalog.take(limit).toList());
  }
  final synonyme = [for (final w in woerter) _synonymeFuer(w)];
  final hatZahl = woerter.any(_zahlToken.hasMatch);

  final treffer = <_Bewertet>[];
  for (var i = 0; i < katalog.length; i++) {
    final a = katalog[i];
    final p = _bewerte(
      normalisiereSuche(a.name),
      normalisiereSuche(a.familie),
      woerter,
      synonyme,
    );
    if (p > 0) treffer.add(_Bewertet(a, p, i));
  }
  treffer.sort((x, y) {
    final c = y.punkte.compareTo(x.punkte);
    return c != 0 ? c : x.index.compareTo(y.index);
  });

  var familien = <FamilienTreffer>[];
  if (!hatZahl) {
    final zaehler = <String, int>{};
    final reihenfolge = <String>[];
    for (final t in treffer) {
      final f = t.artikel.familie;
      if (!zaehler.containsKey(f)) reihenfolge.add(f);
      zaehler[f] = (zaehler[f] ?? 0) + 1;
    }
    familien = [
      for (final f in reihenfolge)
        if (zaehler[f]! >= 2) FamilienTreffer(f, zaehler[f]!),
    ].take(familienLimit).toList();
  }
  return SuchErgebnis(
    familien,
    [for (final t in treffer.take(limit)) t.artikel],
  );
}

class _Bewertet {
  _Bewertet(this.artikel, this.punkte, this.index);

  final KatalogArtikel artikel;
  final int punkte;
  final int index;
}

/// Kategorien mit ihren Unterkategorien in Katalogreihenfolge.
Map<String, List<String>> kategorienBaum(List<KatalogArtikel> katalog) {
  final baum = <String, List<String>>{};
  for (final a in katalog) {
    final liste = baum.putIfAbsent(a.kategorie, () => <String>[]);
    if (!liste.contains(a.unter)) liste.add(a.unter);
  }
  return baum;
}

/// Menge ohne überflüssige Nullen: 20 → „20“, 2.5 → „2,5“.
String formatMenge(double m) {
  if (m == m.roundToDouble()) return m.round().toString();
  var s = m.toStringAsFixed(2);
  if (s.endsWith('0')) s = s.substring(0, s.length - 1);
  return s.replaceAll('.', ',');
}

/// Fügt einen Artikel hinzu. Gibt es ihn schon (gleicher Name und gleiche
/// Einheit), wird die Menge addiert.
List<ListenArtikel> artikelHinzufuegen(
  List<ListenArtikel> liste, {
  required String id,
  required String name,
  required double menge,
  required String einheit,
}) {
  final n = normalisiereSuche(name.trim());
  final i = liste.indexWhere(
    (a) => normalisiereSuche(a.name.trim()) == n && a.einheit == einheit,
  );
  if (i < 0) {
    return [
      ...liste,
      ListenArtikel(id: id, name: name.trim(), menge: menge, einheit: einheit),
    ];
  }
  final neu = [...liste];
  neu[i] = neu[i].copyWith(menge: neu[i].menge + menge, erledigt: false);
  return neu;
}

/// Kopie einer Liste mit neuen IDs; alles wieder offen (nicht abgehakt).
Baustelle kopiereBaustelle(
  Baustelle b, {
  required String neueId,
  required String neuerName,
  required DateTime jetzt,
  required String Function(int index) idFuerArtikel,
}) {
  final artikel = <ListenArtikel>[];
  for (var i = 0; i < b.artikel.length; i++) {
    artikel.add(
      ListenArtikel(
        id: idFuerArtikel(i),
        name: b.artikel[i].name,
        menge: b.artikel[i].menge,
        einheit: b.artikel[i].einheit,
      ),
    );
  }
  return Baustelle(id: neueId, name: neuerName, artikel: artikel, erstellt: jetzt);
}

/// Text zum Teilen per WhatsApp oder E-Mail.
String listeAlsText(Baustelle b, {DateTime? datum}) {
  final buf = StringBuffer()
    ..writeln('Materialliste: ${b.name}')
    ..writeln(formatDatum(datum ?? DateTime.now()))
    ..writeln();
  for (final a in b.artikel) {
    final haken = a.erledigt ? '☑' : '☐';
    buf.writeln('$haken ${a.name} — ${formatMenge(a.menge)} ${a.einheit}');
  }
  buf
    ..writeln()
    ..write('Erstellt mit WerkCalc');
  return buf.toString();
}
