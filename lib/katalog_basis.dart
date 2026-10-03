// Grundlagen des Master-Katalogs: die 17 Hauptkategorien, Größenlisten und
// der Baukasten, mit dem Artikel erzeugt werden. Keine Preise, keine Hersteller.
//
// Erweitern ohne App-Änderung: zusätzliche Artikel können als JSON in
// assets/katalog/zusatz.json stehen (siehe docs/KATALOG.md).

import 'materialliste.dart';

// Die 17 Hauptkategorien in Anzeigereihenfolge.
const String kSanitaer = 'Sanitär / Wasser';
const String kHeizung = 'Heizung';
const String kWaermeerzeuger = 'Wärmeerzeuger';
const String kKlima = 'Klima';
const String kLueftung = 'Lüftung';
const String kAbwasser = 'Abwasser / Kanalisation';
const String kRohre = 'Rohre';
const String kFittings = 'Fittings';
const String kWassertechnik = 'Wassertechnik';
const String kMontage = 'Installation / Montage';
const String kIsolierung = 'Isolierung';
const String kWerkzeug = 'Werkzeug';
const String kVerbrauch = 'Verbrauchsmaterial';
const String kBad = 'Bad / Sanitär-Ausstattung';
const String kRegenerativ = 'Regenerative Energien';
const String kMessen = 'Messen / Prüfen';
const String kElektro = 'Elektro / Anschluss für SHK';

const List<String> kKategorieReihenfolge = [
  kSanitaer, kHeizung, kWaermeerzeuger, kKlima, kLueftung, kAbwasser,
  kRohre, kFittings, kWassertechnik, kMontage, kIsolierung, kWerkzeug,
  kVerbrauch, kBad, kRegenerativ, kMessen, kElektro,
];

/// Standardgrößen.
const List<int> kMm = [15, 18, 22, 28, 35, 42, 54];
const List<String> kZollListe = ['½"', '¾"', '1"', '1¼"', '1½"', '2"'];
const List<int> kDnListe = [15, 20, 25, 32, 40, 50, 65, 80, 100, 125, 150];

const Set<String> _verbrauchsFamilien = {
  'Hanf', 'Fittingband', 'Gewindedichtmittel', 'Dichtpaste', 'Silikon',
  'Acryl', 'Dichtband', 'Gleitmittel',
};

/// Ordnet die ursprünglichen (alten) Kategorien den 17 Hauptkategorien zu.
String _ziel(String kat, String unter, String familie) {
  if (kat == kSanitaer &&
      (unter == 'WC & Urinal' ||
          unter == 'Waschtische & Armaturen' ||
          unter == 'Duschen & Wannen')) {
    return kBad;
  }
  if (kKategorieReihenfolge.contains(kat)) return kat;
  switch (unter) {
    case 'Kupferrohre':
    case 'Edelstahlrohre':
    case 'Mehrschichtverbundrohre':
    case 'Kunststoffrohre':
    case 'Stahlrohre':
      return kRohre;
    case 'Kupferfittings (Löt)':
    case 'Pressfittings':
    case 'Gewindefittings':
    case 'Kunststofffittings':
      return kFittings;
    case 'WC & Urinal':
    case 'Waschtische & Armaturen':
    case 'Duschen & Wannen':
      return kBad;
    case 'Kondensatleitungen':
    case 'Klima-Zubehör':
      return kKlima;
    case 'Lüftung':
      return kLueftung;
    case 'Rohrisolierung':
    case 'Zubehör Isolierung':
      return kIsolierung;
    case 'Rohrschellen':
    case 'Befestigungsmaterial':
    case 'Schrauben':
    case 'Dübel':
      return kMontage;
    case 'Dichtungen':
      return _verbrauchsFamilien.contains(familie) ? kVerbrauch : kMontage;
    case 'Werkzeug & Verbrauch':
      return kVerbrauch;
    case 'Kabel & Leitungen':
    case 'Installationsmaterial':
      return kElektro;
  }
  switch (kat) {
    case 'Kanalisation / Entwässerung':
      return kAbwasser;
    case 'Heizung':
      return kHeizung;
    case 'Sanitär / Wasser':
      return kSanitaer;
  }
  return kat;
}

/// Zusätzliche Suchwörter für Artikel, deren Name das Suchwort nicht enthält
/// (z. B. „Spülkasten“ soll bei „wc“ erscheinen). Schlüssel: Teil des Namens.
const Map<String, String> _autoStichworte = {
  'Spülkasten': 'wc toilette tualet',
  'Vorwandelement': 'wc toilette',
  'Betätigungsplatte': 'drückerplatte wc',
  'Drückerplatte': 'betätigungsplatte wc',
  'Spülrohr': 'wc',
  'Mehrschichtverbundrohr': 'aluverbund alupex verbundrohr',
  'Umwälzpumpe': 'heizungspumpe zirkulation qarkullimi',
  'Zirkulationspumpe': 'umwälzpumpe qarkullimi',
  'Waschtisch ': 'waschbecken lavaman lavabo',
  'Bodenablauf': 'abfluss bodeneinlauf',
  'Warmwasserspeicher': 'boiler bojler',
  'Heizkörper': 'radiator',
  'Pufferspeicher': 'puffer speicher',
  'Pumpengruppe': 'umwälzpumpe zirkulation',
  'Kondensatpumpe': 'klima kondensat',
};

/// Einheitliche Familiennamen (damit z. B. alle WC-Anschlüsse zusammenstehen).
const Map<String, String> _familienAlias = {
  'Rohrisolierung PE': 'Rohrisolierung',
  'Rohrisolierung Mineralwolle': 'Rohrisolierung',
  'Isolierung': 'Rohrisolierung',
  'Isolierung Kälte': 'Kälteisolierung',
  'Multisplit-Außengerät': 'Multisplit',
  'Multisplit-Innengerät': 'Multisplit',
  'Verbindungskabel Klima': 'Verbindungskabel',
  'WC-Vorwandelement': 'Vorwandelement',
  'Betätigungsplatte': 'Drückerplatte',
  'WC-Anschlussgarnitur': 'WC-Anschluss',
  'WC-Anschlussbogen': 'WC-Anschluss',
  'WC-Anschlussstutzen': 'WC-Anschluss',
  'WC-Anschlussmanschette': 'WC-Anschluss',
  'WC-Befestigungsset': 'WC-Zubehör',
  'WC-Bürste': 'WC-Zubehör',
  'WC-Papierhalter': 'WC-Zubehör',
};

/// Baukasten zum Erzeugen der Katalogeinträge.
class KatalogBaukasten {
  final List<KatalogArtikel> liste = [];
  final Set<String> _namen = {};

  void add(
    String kat,
    String unter,
    String familie,
    String name,
    String einheit, {
    String typ = '',
    String stichworte = '',
  }) {
    if (!_namen.add(name)) return; // Namen sind eindeutig
    var u = unter;
    final fam = _familienAlias[familie] ?? familie;
    if (fam == 'PP-R Fitting') u = 'Kunststofffittings';
    final k = _ziel(kat, u, fam);
    if (k == kVerbrauch && u == 'Dichtungen') u = 'Dichtmittel & Kleber';
    if (k == kVerbrauch && u == 'Werkzeug & Verbrauch') u = 'Löten, Bohren, Reinigen';
    var sw = stichworte;
    _autoStichworte.forEach((teil, w) {
      if (name.contains(teil) && !sw.contains(w)) sw = '$sw $w'.trim();
    });
    if (k == kAbwasser) sw = '$sw abwasser kanalisation'.trim();
    liste.add(
      KatalogArtikel(
        name: name,
        einheit: einheit,
        kategorie: k,
        unter: u,
        familie: fam,
        typ: typ,
        stichworte: sw,
      ),
    );
  }

  /// Mehrere Namen auf einmal; Familie = erstes Wort, falls nicht angegeben.
  void liste_(
    String kat,
    String unter,
    List<String> namen,
    String einheit, {
    String typ = '',
    String? familie,
    String stichworte = '',
  }) {
    for (final n in namen) {
      add(kat, unter, familie ?? n.split(' ').first, n, einheit,
          typ: typ, stichworte: stichworte);
    }
  }
}
