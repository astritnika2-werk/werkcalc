// Materiallisten: reine Dart-Logik (ohne Flutter), damit sie sich testen lässt.
// Keine Preise, keine Großhändler: nur Artikel, Mengen und Einheiten.

import 'dart:convert';

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
    this.stichworte = '',
    this.material = '',
    this.dimension = '',
    this.hersteller = '',
    this.artikelnummer = '',
    this.ean = '',
    this.foto = '',
    this.preis,
    this.grosshaendler = '',
    this.lagerbestand,
    this.details = const {},
  }) : _familie = familie;

  final String name;
  final String einheit;
  final String kategorie;
  final String unter;
  final String typ;

  /// Werkstoff und Maß, soweit beim Anlegen bekannt (sonst aus dem Namen
  /// abgeleitet, siehe [werkstoffAnzeige] und [massAnzeige]).
  final String material;
  final String dimension;

  // Optionale Handelsdaten. Alle leer, solange sie nicht gepflegt sind; sie
  // werden später über assets/katalog/zusatz.json ergänzt (kein App-Umbau).
  final String hersteller;
  final String artikelnummer;
  final String ean;

  /// Pfad zu einem echten Produktfoto (Asset „assets/produkte/…“ oder
  /// Dateipfad). Leer = die App zeigt die Skizze.
  final String foto;
  final double? preis;
  final String grosshaendler;
  final int? lagerbestand;

  /// Weitere Datenblatt-Zeilen (Name → Wert), z. B. „Nennweite“: „DN 25“.
  final Map<String, String> details;

  /// Zusätzliche Suchwörter (nur für die Suche, nicht sichtbar).
  final String stichworte;
  final String? _familie;

  /// Produktfamilie ohne Größe, z. B. „Kupferrohr“.
  String get familie => _familie ?? name;

  Map<String, dynamic> toJson() => {'name': name, 'einheit': einheit};

  factory KatalogArtikel.fromJson(Map<String, dynamic> j) => KatalogArtikel(
        name: (j['name'] ?? '').toString(),
        einheit: (j['einheit'] ?? 'Stk.').toString(),
        kategorie: (j['kategorie'] ?? 'Eigene Artikel').toString(),
        unter: (j['unter'] ?? 'Eigene').toString(),
        familie: j['familie']?.toString(),
        typ: (j['typ'] ?? '').toString(),
        stichworte: (j['stichworte'] ?? '').toString(),
        material: (j['material'] ?? '').toString(),
        dimension: (j['dimension'] ?? '').toString(),
        hersteller: (j['hersteller'] ?? '').toString(),
        artikelnummer: (j['artikelnummer'] ?? '').toString(),
        ean: (j['ean'] ?? '').toString(),
        foto: (j['foto'] ?? '').toString(),
        preis: (j['preis'] as num?)?.toDouble(),
        grosshaendler: (j['grosshaendler'] ?? '').toString(),
        lagerbestand: (j['lagerbestand'] as num?)?.toInt(),
        details: j['details'] is Map
            ? {
                for (final e in (j['details'] as Map).entries)
                  e.key.toString(): e.value.toString(),
              }
            : const {},
      );

  /// Übernimmt Handelsdaten aus [o] (nur befüllte Felder); Name, Kategorie
  /// und Suche bleiben unverändert.
  KatalogArtikel angereichertMit(KatalogArtikel o) => KatalogArtikel(
        name: name,
        einheit: o.einheit.isNotEmpty && o.einheit != 'Stk.' ? o.einheit : einheit,
        kategorie: kategorie,
        unter: unter,
        familie: familie,
        typ: typ,
        stichworte: o.stichworte.isEmpty ? stichworte : '$stichworte ${o.stichworte}'.trim(),
        material: o.material.isEmpty ? material : o.material,
        dimension: o.dimension.isEmpty ? dimension : o.dimension,
        hersteller: o.hersteller.isEmpty ? hersteller : o.hersteller,
        artikelnummer: o.artikelnummer.isEmpty ? artikelnummer : o.artikelnummer,
        ean: o.ean.isEmpty ? ean : o.ean,
        foto: o.foto.isEmpty ? foto : o.foto,
        preis: o.preis ?? preis,
        grosshaendler: o.grosshaendler.isEmpty ? grosshaendler : o.grosshaendler,
        lagerbestand: o.lagerbestand ?? lagerbestand,
        details: {...details, ...o.details},
      );

  /// Dateiname-Schlüssel für automatisch zugeordnete Fotos
  /// (assets/produkte/<schlüssel>.jpg|png|webp): EAN, Artikelnummer, Name.
  List<String> get fotoSchluessel => [
        if (ean.isNotEmpty) ean,
        if (artikelnummer.isNotEmpty) fotoSlug(artikelnummer),
        fotoSlug(name),
      ];

  /// Werkstoff für die Anzeige.
  String get werkstoffAnzeige =>
      material.isNotEmpty ? material : _werkstoffAusName(name);

  /// Maß für die Anzeige.
  String get massAnzeige =>
      dimension.isNotEmpty ? dimension : _massAusName(name);

  /// Art/Ausführung: der Name ohne Werkstoff und Maß, z. B. „Bogen 90° I/A“.
  String get artAnzeige => _artAusName(name, werkstoffAnzeige, massAnzeige, familie);

  /// Eine Zeile mit den wichtigsten Angaben: Werkstoff · Maß · Art.
  String get kurzInfo => [
        werkstoffAnzeige,
        massAnzeige,
        artAnzeige,
      ].where((e) => e.isNotEmpty).join(' · ');
}

const List<List<String>> _werkstoffe = [
  ['Edelstahl', 'Edelstahl'], ['C-Stahl', 'C-Stahl'], ['Kupfer', 'Kupfer'],
  ['Mehrschicht', 'Mehrschichtverbund'], ['Verbundrohr', 'Mehrschichtverbund'],
  ['PP-R', 'PP-R'], ['PE-X', 'PE-X'], ['PE-RT', 'PE-RT'], ['PE-HD', 'PE-HD'],
  ['PVC', 'PVC'], ['HT-', 'HT (PP)'], ['KG', 'KG (PVC-U)'],
  ['Rotguss', 'Rotguss'], ['Messing', 'Messing'], ['verzinkt', 'verzinkt'],
  ['Stahl', 'Stahl'], ['Aluminium', 'Aluminium'], ['Gummi', 'Gummi'],
  ['Mineralwolle', 'Mineralwolle'], ['Kunststoff', 'Kunststoff'],
];

String _werkstoffAusName(String name) {
  for (final w in _werkstoffe) {
    if (name.contains(w[0])) return w[1];
  }
  return '';
}

final RegExp _massRegex = RegExp(
  r'(Ø\s?\d+(?:[,.]\d+)?(?:\s?[×x]\s?[0-9¼½¾⅜⅛]+[¼½¾⅜⅛]?"?)?(?:\s?mm)?|DN\s?\d+|\d+(?:[,.]\d+)?\s?(?:cm|mm|kW|l|m²|m³)\b|[0-9]?[¼½¾⅜⅛]"|\d+"|\d+\s?[×x]\s?\d+(?:\s?mm)?)',
);

String _massAusName(String name) {
  final m = _massRegex.firstMatch(name);
  return m == null ? '' : m.group(0)!.trim();
}

String _artAusName(String name, String werkstoff, String mass, String familie) {
  var t = name;
  t = t.replaceAll(RegExp(r'\s*\([^)]*\)'), '');
  if (mass.isNotEmpty) t = t.replaceFirst(mass, '');
  t = t.replaceAll(RegExp(r'Ø\s?\d+(?:[,.]\d+)?(?:\s?[×x]\s?[0-9¼½¾⅜⅛]+[¼½¾⅜⅛]?"?)*'), '');
  t = t.replaceAll(RegExp(r'DN\s?\d+(?:\s?[×x/]\s?(?:DN\s?)?\d+)*'), '');
  t = t.replaceAll(RegExp(r'\b\d+\s?[×x]\s?\d+(?:\s?[×x]\s?\d+)*\b'), '');
  t = t.replaceAll(RegExp(r'[0-9]?[¼½¾⅜⅛]"'), '');
  for (final w in const ['Kupfer', 'Edelstahl', 'C-Stahl', 'verzinkt', 'Messing']) {
    t = t.replaceAll(w, '');
  }
  t = t.replaceAll(RegExp(r'\s+'), ' ').replaceAll(RegExp(r'[-–/ ]+$'), '').trim();
  t = t.replaceAll(RegExp(r'^[-–]+'), '').trim();
  if (t.isEmpty) return familie;
  return t[0].toUpperCase() + t.substring(1);
}

/// Liest Katalog-Erweiterungen aus JSON (Liste oder {"artikel": [...]}).
/// Ungültige Einträge werden übersprungen. Doppelte Namen (auch zum
/// bestehenden Katalog) werden nicht übernommen.
List<KatalogArtikel> katalogAusJson(
  String roh, {
  Set<String> vorhandeneNamen = const {},
}) {
  try {
    var daten = jsonDecode(roh);
    if (daten is Map) daten = daten['artikel'];
    if (daten is! List) return const [];
    final gesehen = {...vorhandeneNamen};
    final out = <KatalogArtikel>[];
    for (final e in daten) {
      if (e is! Map) continue;
      final a = KatalogArtikel.fromJson(Map<String, dynamic>.from(e));
      if (a.name.trim().isEmpty || !gesehen.add(a.name)) continue;
      out.add(a);
    }
    return out;
  } catch (_) {
    return const [];
  }
}

/// Dateiname-tauglicher Schlüssel: Kleinbuchstaben, nur a–z, 0–9, „_“.
String fotoSlug(String s) => normalisiereSuche(s)
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '');

/// Ergänzt bestehende Katalogartikel (gleicher Name) um Handelsdaten aus JSON.
/// Artikel, die es nicht gibt, werden hier nicht angelegt (siehe [katalogAusJson]).
List<KatalogArtikel> katalogAnreichern(List<KatalogArtikel> basis, String roh) {
  try {
    var daten = jsonDecode(roh);
    if (daten is Map) daten = daten['artikel'];
    if (daten is! List) return basis;
    final nachName = <String, KatalogArtikel>{};
    for (final e in daten) {
      if (e is! Map) continue;
      final a = KatalogArtikel.fromJson(Map<String, dynamic>.from(e));
      if (a.name.trim().isNotEmpty) nachName[a.name] = a;
    }
    if (nachName.isEmpty) return basis;
    return [
      for (final a in basis)
        nachName.containsKey(a.name) ? a.angereichertMit(nachName[a.name]!) : a,
    ];
  } catch (_) {
    return basis;
  }
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
  'boiler': ['speicher', 'boiler'], 'rubinet': ['armatur', 'wasserhahn'],
  'vida': ['schraube'], 'vidha': ['schraube'], 'shraf': ['schraube'],
  'schr': ['schraube'], 'dubel': ['dubel'], 'diibel': ['dubel'],
  'dubl': ['dubel'], 'teflon': ['fittingband'], 'kanal': ['abwasser', 'kg-', 'ht-'],
  'kanaliz': ['abwasser'], 'kondens': ['kondensat'], 'klima': ['klima'],
  'lemer': ['lotzinn'], 'sheshe': ['schelle'], 'skele': ['schelle'],
  'schelle': ['schelle'], 'press': ['pressfitting'], 'gewinde': ['gewinde'],
  'kupfer': ['kupfer'], 'bakri': ['kupfer'], 'inox': ['edelstahl'],
  'edelstahl': ['edelstahl'], 'plastik': ['kunststoff'], 'plast': ['kunststoff'],
  'pvc': ['kunststoff', 'pvc', 'pp-r'], 'ppr': ['pp-r'], 'pex': ['pe-x'],
  'verbund': ['mehrschicht'], 'mv': ['mehrschicht'], 'alupex': ['mehrschicht'],
  'lufte': ['luftung'], 'ventilator': ['ventilator', 'luftung'],
  'tape': ['band', 'stopfen', 'kappe'], 'ngjit': ['kleb'], 'silikon': ['silikon'],
  // Handwerkersprache (albanisch) → Fachbegriff
  'baker': ['kupfer'], 'celik': ['stahl'], 'hekur': ['stahl'],
  'qarkullim': ['umwalz', 'zirkulation'], 'ngroh': ['heiz'],
  'kaldaj': ['kessel'], 'kazan': ['kessel'],
  'flans': ['flansch'], 'kryq': ['kreuz'], 'kapak': ['kappe'],
  'cezme': ['armatur', 'hahn'], 'vaske': ['badewanne'], 'kade': ['badewanne'],
  'diell': ['solar'], 'solar': ['solar'], 'ajrim': ['luftung'],
  'ajros': ['luftung'], 'filter': ['filter'], 'filtr': ['filter'],
  'manometer': ['manometer'], 'termometer': ['thermometer'],
  'kabell': ['kabel'], 'kabel': ['kabel'], 'sigur': ['sicherung'],
  'prize': ['steckdose'], 'celes': ['schalter', 'schlussel'],
  'trapan': ['bohrmaschine', 'bohrer'], 'turjel': ['bohrer', 'bohrmaschine'],
  'pense': ['zange'], 'kacavid': ['schraubendreher'],
  'metar': ['massband', 'zollstock'], 'dorez': ['handschuh'],
  'mbajtes': ['halter', 'konsole'], 'konsol': ['konsole'],
  'toilet': ['wc'], 'toilette': ['wc'], 'mikser': ['mischer'],
  'puf': ['puffer'], 'nxehtes': ['warme'], 'abwasser': ['abwasser', 'kg-', 'ht-'],
  'flansch': ['flansch'], 'wasserhahn': ['armatur', 'hahn'],
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

/// Reihenfolge wichtiger Produktfamilien in den Ergebnissen (vorne = zuerst).
/// Nicht genannte Familien kommen danach. Die Reihenfolge ordnet nur,
/// sie entfernt nichts.
const List<String> kFamilienReihenfolge = [
  // Kupfer, Pressfittings, Rohre
  'Kupferrohr', 'Kupferbogen', 'Muffe Kupfer', 'T-Stück Kupfer',
  'Reduzierung Kupfer', 'Übergang Kupfer', 'Verschraubung Kupfer',
  'Pressfitting', 'Pressbogen', 'Press-T-Stück', 'Pressmuffe',
  'Press-Reduzierung', 'Press-Übergang', 'Edelstahlrohr', 'Stahlrohr',
  'Mehrschichtverbundrohr', 'Kunststoffrohr', 'PE-Rohr', 'PE-X Rohr',
  'PVC-Rohr', 'PP-Rohr', 'HT-Rohr', 'KG-Rohr', 'KG2000-Rohr',
  'Gewindefitting', 'PP-R Fitting', 'HT-Bogen', 'KG-Bogen', 'KG2000-Bogen',
  'HT-Muffe', 'KG-Muffe', 'KG2000-Muffe', 'HT-Abzweig', 'KG-Abzweig',
  // Pumpen
  'Umwälzpumpe', 'Zirkulationspumpe', 'Heizkreispumpe', 'Pumpengruppe',
  // Klima
  'Klimagerät', 'Split-Klimagerät', 'Außengerät', 'Innengerät', 'Multisplit',
  'Kondensatpumpe', 'Kältemittelleitung', 'Verbindungskabel',
  'Tauchpumpe', 'Gartenpumpe', 'Hauswasserwerk', 'Hauswasserautomat',
  // Ventile
  'Absperrventil', 'Eckventil', 'Thermostatventil', 'Sicherheitsventil',
  'Rückschlagventil', 'Schrägsitzventil', 'Freistromventil', 'Zonenventil',
  'Strangregulierventil', 'Kugelhahn', 'Rückflussverhinderer', 'Druckminderer',
  // Isolierung
  'Rohrisolierung', 'Heizungsisolierung', 'Kälteisolierung',
  'Sanitärisolierung', 'Brandschutzisolierung', 'Pumpenisolierschale',
  // WC, Waschtisch
  'WC', 'WC-Sitz', 'Spülkasten', 'Vorwandelement', 'Drückerplatte',
  'WC-Anschluss', 'Waschtisch', 'Waschbecken', 'Doppelwaschtisch',
  'Waschtischarmatur', 'Waschtisch-Siphon',
  // Speicher
  'Warmwasserspeicher', 'Untertischspeicher', 'Pufferspeicher',
  'Hygienespeicher', 'Kombispeicher',
];

final Map<String, int> _familienRang = {
  for (var i = 0; i < kFamilienReihenfolge.length; i++) kFamilienReihenfolge[i]: i,
};

int _rang(String familie) => _familienRang[familie] ?? 100000;

/// Für einzelne Suchwörter gilt eine eigene Reihenfolge der Familien
/// (zuerst das, was Handwerker meinen). Schlüssel = Wortanfang.
const Map<String, List<String>> kBevorzugt = {
  'izolim': [
    'Rohrisolierung', 'Heizungsisolierung', 'Kälteisolierung',
    'Sanitärisolierung', 'Brandschutzisolierung', 'Pumpenisolierschale',
  ],
  'lavaman': [
    'Waschtisch', 'Waschbecken', 'Doppelwaschtisch', 'Waschtischarmatur',
    'Waschtisch-Siphon',
  ],
  'bojler': [
    'Warmwasserspeicher', 'Untertischspeicher', 'Pufferspeicher',
    'Hygienespeicher', 'Kombispeicher',
  ],
  'rubinet': [
    'Waschtischarmatur', 'Küchenarmatur', 'Duscharmatur', 'Thermostatarmatur',
    'Außenwandarmatur',
  ],
};

int _rangFuer(String familie, List<String> woerter) {
  for (final w in woerter) {
    for (final e in kBevorzugt.entries) {
      if (w.startsWith(e.key)) {
        final i = e.value.indexOf(familie);
        if (i >= 0) return i - 1000;
      }
    }
  }
  return _rang(familie);
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
  int familienLimit = 16,
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
    final n = _normCache[a] ??= _Norm(
      normalisiereSuche(
        '${a.name} ${a.stichworte} ${a.hersteller} ${a.artikelnummer} ${a.ean}'.trim(),
      ),
      normalisiereSuche(a.familie),
    );
    final p = _bewerte(n.text, n.familie, woerter, synonyme);
    if (p > 0) treffer.add(_Bewertet(a, p, i));
  }
  treffer.sort((x, y) {
    final r = _rangFuer(x.artikel.familie, woerter).compareTo(_rangFuer(y.artikel.familie, woerter));
    if (r != 0) return r;
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
    // Familien, die auf das Suchwort enden („…rohr“ bei „gyp“), zuerst; dann
    // nach Anzahl der Treffer.
    final kws = <String>{
      for (final w in woerter)
        if (w.length >= 3) w,
      for (final l in synonyme)
        for (final kw in l)
          if (kw.length >= 3) kw,
    };
    bool endet(String f) {
      final n = normalisiereSuche(f);
      return kws.any(n.endsWith);
    }

    final kandidaten = [
      for (var i = 0; i < reihenfolge.length; i++)
        if (zaehler[reihenfolge[i]]! >= 2) i,
    ];
    kandidaten.sort((a, b) {
      final ra = _rangFuer(reihenfolge[a], woerter).compareTo(_rangFuer(reihenfolge[b], woerter));
      if (ra != 0) return ra;
      final ea = endet(reihenfolge[a]) ? 0 : 1;
      final eb = endet(reihenfolge[b]) ? 0 : 1;
      if (ea != eb) return ea.compareTo(eb);
      final c = zaehler[reihenfolge[b]]!.compareTo(zaehler[reihenfolge[a]]!);
      return c != 0 ? c : a.compareTo(b);
    });
    familien = [
      for (final i in kandidaten)
        FamilienTreffer(reihenfolge[i], zaehler[reihenfolge[i]]!),
    ].take(familienLimit).toList();
  }
  return SuchErgebnis(
    familien,
    [for (final t in treffer.take(limit)) t.artikel],
  );
}

/// Vorberechnete, normalisierte Suchtexte (macht jeden Tastendruck schnell).
class _Norm {
  _Norm(this.text, this.familie);

  final String text;
  final String familie;
}

final Expando<_Norm> _normCache = Expando<_Norm>();

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
