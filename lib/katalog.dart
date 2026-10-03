// Eingebauter Artikelkatalog von WerkCalc (ohne Preise, ohne Großhändler).
// Namen sind die fachlichen deutschen Bezeichnungen. Größen werden erzeugt,
// damit der Katalog groß und einheitlich bleibt.

import 'katalog_basis.dart';
import 'katalog_zusatz.dart';
import 'materialliste.dart';

export 'katalog_basis.dart';

const String kKatRohr = 'Rohrsysteme';
const String kKatHeizung = 'Heizung';
const String kKatSanitaer = 'Sanitär / Wasser';
const String kKatKanal = 'Kanalisation / Entwässerung';
const String kKatKlima = 'Klima / Lüftung';
const String kKatIso = 'Isolierungen';
const String kKatBefest = 'Befestigung, Schrauben, Dübel';
const String kKatDicht = 'Dichtungen';
const String kKatWerkzeug = 'Werkzeug / Verbrauchsmaterial';
const String kKatElektro = 'Elektro';

/// Kupferrohr-Durchmesser in mm.
const List<int> _kupfer = [12, 15, 18, 22, 28, 35, 42, 54];
const List<int> _edelstahl = [15, 18, 22, 28, 35, 42, 54];
const List<int> _mv = [16, 20, 26, 32, 40, 50, 63];
const List<String> _zoll = ['½"', '¾"', '1"', '1¼"', '1½"', '2"'];

/// Passendes Gewinde zum Rohrdurchmesser (für Übergänge).
const Map<int, String> _gewinde = {
  12: '⅜"', 15: '½"', 16: '½"', 18: '½"', 20: '¾"', 22: '¾"', 26: '1"',
  28: '1"', 32: '1¼"', 35: '1¼"', 40: '1½"', 42: '1½"', 50: '2"', 54: '2"',
  63: '2½"',
};

/// Reduzierungen als Paare (groß/klein) aus einer Größenliste.
List<List<int>> _paare(List<int> groessen) {
  final p = <List<int>>[];
  for (var i = groessen.length - 1; i > 0; i--) {
    p.add([groessen[i], groessen[i - 1]]);
    if (i > 1) p.add([groessen[i], groessen[i - 2]]);
  }
  return p;
}

void _pressfittings(
  KatalogBaukasten b,
  String werkstoff,
  List<int> groessen,
) {
  const u = 'Pressfittings';
  for (final d in groessen) {
    b.add(kKatRohr, u, 'Pressfitting', 'Pressfitting Bogen 90° Ø$d ($werkstoff)', 'Stk.', typ: 'Bogen');
    b.add(kKatRohr, u, 'Pressfitting', 'Pressfitting Bogen 45° Ø$d ($werkstoff)', 'Stk.', typ: 'Bogen');
    b.add(kKatRohr, u, 'Pressfitting', 'Pressfitting T-Stück Ø$d ($werkstoff)', 'Stk.', typ: 'T-Stück');
    b.add(kKatRohr, u, 'Pressfitting', 'Pressfitting Muffe Ø$d ($werkstoff)', 'Stk.', typ: 'Muffe');
    b.add(kKatRohr, u, 'Pressfitting', 'Pressfitting Endkappe Ø$d ($werkstoff)', 'Stk.', typ: 'Zubehör');
    final g = _gewinde[d];
    if (g != null) {
      b.add(kKatRohr, u, 'Pressfitting', 'Pressfitting Übergang Ø$d auf $g AG ($werkstoff)', 'Stk.', typ: 'Übergang');
      b.add(kKatRohr, u, 'Pressfitting', 'Pressfitting Übergang Ø$d auf $g IG ($werkstoff)', 'Stk.', typ: 'Übergang');
    }
  }
  for (final p in _paare(groessen)) {
    b.add(kKatRohr, u, 'Pressfitting', 'Pressfitting Reduzierung Ø${p[0]}/${p[1]} ($werkstoff)', 'Stk.', typ: 'Reduzierung');
  }
}

/// Erzeugt den vollständigen Katalog.
List<KatalogArtikel> baueKatalog() {
  final b = KatalogBaukasten();

  // ───────────── Rohrsysteme ─────────────
  for (final d in _kupfer) {
    b.add(kKatRohr, 'Kupferrohre', 'Kupferrohr', 'Kupferrohr Ø$d mm', 'm', typ: 'Rohr');
  }
  for (final d in _kupfer) {
    const u = 'Kupferfittings (Löt)';
    b.add(kKatRohr, u, 'Kupferbogen', 'Kupferbogen 90° I/I Ø$d', 'Stk.', typ: 'Bogen');
    b.add(kKatRohr, u, 'Kupferbogen', 'Kupferbogen 90° I/A Ø$d', 'Stk.', typ: 'Bogen');
    b.add(kKatRohr, u, 'Kupferbogen', 'Kupferbogen 45° Ø$d', 'Stk.', typ: 'Bogen');
    b.add(kKatRohr, u, 'T-Stück Kupfer', 'T-Stück Kupfer Ø$d', 'Stk.', typ: 'T-Stück');
    b.add(kKatRohr, u, 'Muffe Kupfer', 'Muffe Kupfer Ø$d', 'Stk.', typ: 'Muffe');
    b.add(kKatRohr, u, 'Endkappe Kupfer', 'Endkappe Kupfer Ø$d', 'Stk.', typ: 'Zubehör');
    final g = _gewinde[d];
    if (g != null) {
      b.add(kKatRohr, u, 'Übergang Kupfer', 'Übergang Kupfer Ø$d auf $g AG', 'Stk.', typ: 'Übergang');
      b.add(kKatRohr, u, 'Übergang Kupfer', 'Übergang Kupfer Ø$d auf $g IG', 'Stk.', typ: 'Übergang');
    }
  }
  for (final p in _paare(_kupfer)) {
    b.add(kKatRohr, 'Kupferfittings (Löt)', 'Reduzierung Kupfer', 'Reduzierung Kupfer Ø${p[0]}/${p[1]}', 'Stk.', typ: 'Reduzierung');
  }

  for (final d in _edelstahl) {
    b.add(kKatRohr, 'Edelstahlrohre', 'Edelstahlrohr', 'Edelstahlrohr Ø$d mm', 'm', typ: 'Rohr');
  }
  for (final d in _mv) {
    b.add(kKatRohr, 'Mehrschichtverbundrohre', 'Mehrschichtverbundrohr', 'Mehrschichtverbundrohr Ø$d mm', 'm', typ: 'Rohr');
  }

  for (final d in const [20, 25, 32, 40, 50, 63, 75, 90, 110]) {
    b.add(kKatRohr, 'Kunststoffrohre', 'Kunststoffrohr', 'Kunststoffrohr PP-R Ø$d mm', 'm', typ: 'Rohr');
  }
  for (final d in const [16, 20, 25, 32]) {
    b.add(kKatRohr, 'Kunststoffrohre', 'Kunststoffrohr', 'Kunststoffrohr PE-Xa Ø$d mm', 'm', typ: 'Rohr');
  }
  for (final d in const [25, 32, 40, 50, 63]) {
    b.add(kKatRohr, 'Kunststoffrohre', 'Kunststoffrohr', 'Kunststoffrohr PE-HD Ø$d mm', 'm', typ: 'Rohr');
  }
  for (final d in const [20, 25, 32, 40, 50, 63]) {
    b.add(kKatRohr, 'Kunststoffrohre', 'PP-R Fitting', 'PP-R Bogen 90° Ø$d', 'Stk.', typ: 'Bogen');
    b.add(kKatRohr, 'Kunststoffrohre', 'PP-R Fitting', 'PP-R Bogen 45° Ø$d', 'Stk.', typ: 'Bogen');
    b.add(kKatRohr, 'Kunststoffrohre', 'PP-R Fitting', 'PP-R T-Stück Ø$d', 'Stk.', typ: 'T-Stück');
    b.add(kKatRohr, 'Kunststoffrohre', 'PP-R Fitting', 'PP-R Muffe Ø$d', 'Stk.', typ: 'Muffe');
  }
  for (final p in _paare(const [20, 25, 32, 40, 50, 63])) {
    b.add(kKatRohr, 'Kunststoffrohre', 'PP-R Fitting', 'PP-R Reduzierung Ø${p[0]}/${p[1]}', 'Stk.', typ: 'Reduzierung');
  }

  for (final z in _zoll) {
    b.add(kKatRohr, 'Stahlrohre', 'Stahlrohr', 'Stahlrohr verzinkt $z', 'm', typ: 'Rohr');
  }
  for (final z in _zoll) {
    b.add(kKatRohr, 'Stahlrohre', 'Stahlrohr', 'Stahlrohr schwarz $z', 'm', typ: 'Rohr');
  }
  for (final d in const [15, 18, 22, 28, 35, 42, 54]) {
    b.add(kKatRohr, 'Stahlrohre', 'Stahlrohr', 'Stahlrohr C-Stahl Press Ø$d mm', 'm', typ: 'Rohr');
  }

  _pressfittings(b, 'Kupfer', _kupfer);
  _pressfittings(b, 'Edelstahl', _edelstahl);
  _pressfittings(b, 'C-Stahl', const [15, 18, 22, 28, 35, 42, 54]);
  _pressfittings(b, 'Mehrschicht', _mv);

  for (final z in _zoll) {
    const u = 'Gewindefittings';
    b.add(kKatRohr, u, 'Gewindefitting', 'Gewindefitting Winkel 90° IG/IG $z', 'Stk.', typ: 'Bogen');
    b.add(kKatRohr, u, 'Gewindefitting', 'Gewindefitting Winkel 90° AG/IG $z', 'Stk.', typ: 'Bogen');
    b.add(kKatRohr, u, 'Gewindefitting', 'Gewindefitting Winkel 45° IG/IG $z', 'Stk.', typ: 'Bogen');
    b.add(kKatRohr, u, 'Gewindefitting', 'Gewindefitting T-Stück IG $z', 'Stk.', typ: 'T-Stück');
    b.add(kKatRohr, u, 'Gewindefitting', 'Gewindefitting Muffe IG/IG $z', 'Stk.', typ: 'Muffe');
    b.add(kKatRohr, u, 'Gewindefitting', 'Gewindefitting Doppelnippel $z', 'Stk.', typ: 'Nippel');
    b.add(kKatRohr, u, 'Gewindefitting', 'Gewindefitting Kappe IG $z', 'Stk.', typ: 'Zubehör');
    b.add(kKatRohr, u, 'Gewindefitting', 'Gewindefitting Stopfen AG $z', 'Stk.', typ: 'Zubehör');
    b.add(kKatRohr, u, 'Gewindefitting', 'Gewindefitting Verschraubung $z', 'Stk.', typ: 'Zubehör');
  }
  for (var i = _zoll.length - 1; i > 0; i--) {
    b.add(kKatRohr, 'Gewindefittings', 'Gewindefitting', 'Gewindefitting Reduziernippel ${_zoll[i]} auf ${_zoll[i - 1]}', 'Stk.', typ: 'Reduzierung');
    b.add(kKatRohr, 'Gewindefittings', 'Gewindefitting', 'Gewindefitting Reduzierstück IG/AG ${_zoll[i]} auf ${_zoll[i - 1]}', 'Stk.', typ: 'Reduzierung');
  }

  // ───────────── Heizung ─────────────
  for (final typ in const [11, 21, 22, 33]) {
    for (final h in const [300, 500, 600]) {
      for (final l in const [400, 600, 800, 1000, 1200, 1600]) {
        b.add(kKatHeizung, 'Heizkörper', 'Kompaktheizkörper', 'Kompaktheizkörper Typ $typ $h×$l', 'Stk.', typ: 'Heizkörper');
      }
    }
  }
  for (final h in const [800, 1200, 1800]) {
    for (final w in const [500, 600]) {
      b.add(kKatHeizung, 'Heizkörper', 'Badheizkörper', 'Badheizkörper $h×$w', 'Stk.', typ: 'Heizkörper');
    }
  }
  for (final x in const [
    'Heizkörperkonsole|Paar',
    'Heizkörper-Wandhalter Set|Set',
    'Heizkörper-Anschlussset|Set',
    'Heizkörper-Entlüfter ½"|Stk.',
    'Blindstopfen ½"|Stk.',
  ]) {
    final t = x.split('|');
    b.add(kKatHeizung, 'Heizkörper', 'Heizkörperzubehör', t[0], t[1], typ: 'Zubehör');
  }
  for (final x in const [
    'Thermostatkopf|Stk.',
    'Funk-Thermostatkopf|Stk.',
    'Thermostatventil gerade ½"|Stk.',
    'Thermostatventil Eck ½"|Stk.',
    'Rücklaufverschraubung gerade ½"|Stk.',
    'Rücklaufverschraubung Eck ½"|Stk.',
    'Raumthermostat|Stk.',
    'Stellantrieb 230 V|Stk.',
  ]) {
    final t = x.split('|');
    b.add(kKatHeizung, 'Thermostate & Heizkörperarmaturen', t[0].split(' ').first, t[0], t[1], typ: 'Ventil');
  }
  for (final x in const [
    'Sicherheitsventil ½" 3 bar',
    'Dreiwegemischer ¾"',
    'Dreiwegemischer 1"',
    'Dreiwegemischer 1¼"',
    'Strangregulierventil DN 15',
    'Strangregulierventil DN 20',
    'Strangregulierventil DN 25',
    'Strangregulierventil DN 32',
    'Schmutzfänger ¾"',
    'Schmutzfänger 1"',
    'Schmutzfänger 1¼"',
    'Füll- und Entleerhahn ½"',
    'Schnellentlüfter ½"',
    'Manometer',
    'Thermometer',
  ]) {
    b.add(kKatHeizung, 'Armaturen Heizung', x.split(' ').first, x, 'Stk.', typ: 'Ventil');
  }
  for (final x in const [
    'Umwälzpumpe Hocheffizienz 25-40',
    'Umwälzpumpe Hocheffizienz 25-60',
    'Umwälzpumpe Hocheffizienz 25-80',
    'Umwälzpumpe Hocheffizienz 32-60',
    'Umwälzpumpe Hocheffizienz 32-80',
    'Zirkulationspumpe Trinkwasser',
    'Kondensatpumpe',
    'Hebeanlage',
    'Tauchpumpe',
  ]) {
    b.add(kKatHeizung, 'Pumpen', x.split(' ').first, x, 'Stk.', typ: 'Pumpe');
  }
  for (final l in const [8, 12, 18, 25, 33, 50, 80]) {
    b.add(kKatHeizung, 'Ausdehnungsgefäße', 'Ausdehnungsgefäß', 'Ausdehnungsgefäß $l l', 'Stk.', typ: 'Zubehör');
  }
  for (final n in const [2, 3, 4, 5, 6, 8, 10, 12]) {
    b.add(kKatHeizung, 'Fußbodenheizung', 'Heizkreisverteiler', 'Heizkreisverteiler $n Kreise', 'Stk.', typ: 'Zubehör');
  }
  b.add(kKatHeizung, 'Fußbodenheizung', 'Fußbodenheizungsrohr', 'Fußbodenheizungsrohr PE-RT Ø16×2', 'm', typ: 'Rohr');
  b.add(kKatHeizung, 'Fußbodenheizung', 'Randdämmstreifen', 'Randdämmstreifen', 'm', typ: 'Zubehör');
  b.add(kKatHeizung, 'Fußbodenheizung', 'Noppenplatte', 'Noppenplatte', 'm²', typ: 'Zubehör');

  // ───────────── Sanitär / Wasser ─────────────
  for (final z in _zoll) {
    const u = 'Kugelhähne & Ventile';
    b.add(kKatSanitaer, u, 'Kugelhahn', 'Kugelhahn $z IG/IG', 'Stk.', typ: 'Ventil');
    b.add(kKatSanitaer, u, 'Rückflussverhinderer', 'Rückflussverhinderer $z', 'Stk.', typ: 'Ventil');
    b.add(kKatSanitaer, u, 'Absperrventil', 'Absperrventil $z', 'Stk.', typ: 'Ventil');
  }
  for (final d in const [15, 18, 22, 28, 35]) {
    b.add(kKatSanitaer, 'Kugelhähne & Ventile', 'Kugelhahn', 'Kugelhahn Press Ø$d', 'Stk.', typ: 'Ventil');
  }
  for (final x in const [
    'Eckventil chrom ½"×⅜"',
    'Druckminderer ¾"',
    'Druckminderer 1"',
    'Sicherheitsgruppe Boiler ¾"',
    'Schlauchanschlusshahn ½"',
    'Waschmaschinenhahn ½"',
    'Thermostatischer Mischer ¾"',
  ]) {
    b.add(kKatSanitaer, 'Kugelhähne & Ventile', x.split(' ').first, x, 'Stk.', typ: 'Ventil');
  }
  for (final x in const [
    'WC wandhängend Tiefspüler',
    'WC stehend Tiefspüler',
    'WC-Sitz mit Absenkautomatik',
    'Spülkasten Unterputz',
    'WC-Vorwandelement',
    'Betätigungsplatte Dual',
    'WC-Anschlussgarnitur',
    'Spülrohr DN 50',
    'Urinal',
  ]) {
    b.add(kKatSanitaer, 'WC & Urinal', x.split(' ').first, x, 'Stk.', typ: 'Sanitärobjekt');
  }
  for (final cm in const [50, 60, 80, 100]) {
    b.add(kKatSanitaer, 'Waschtische & Armaturen', 'Waschtisch', 'Waschtisch $cm cm', 'Stk.', typ: 'Sanitärobjekt');
  }
  for (final x in const [
    'Waschtischarmatur Einhebelmischer',
    'Küchenarmatur Einhebelmischer',
    'Wannenarmatur Aufputz',
    'Duscharmatur Aufputz',
    'Duscharmatur Unterputz Set',
    'Brausegarnitur',
    'Handbrause',
    'Brauseschlauch 1,5 m',
    'Brauseschlauch 2 m',
    'Anschlussschlauch ⅜" 300 mm',
    'Anschlussschlauch ⅜" 500 mm',
  ]) {
    b.add(kKatSanitaer, 'Waschtische & Armaturen', x.split(' ').first, x, 'Stk.', typ: 'Armatur');
  }
  for (final x in const ['170×75', '180×80']) {
    b.add(kKatSanitaer, 'Duschen & Wannen', 'Badewanne', 'Badewanne $x', 'Stk.', typ: 'Sanitärobjekt');
  }
  for (final x in const ['80×80', '90×90', '100×80', '120×80']) {
    b.add(kKatSanitaer, 'Duschen & Wannen', 'Duschwanne', 'Duschwanne $x', 'Stk.', typ: 'Sanitärobjekt');
  }
  for (final cm in const [80, 90, 100]) {
    b.add(kKatSanitaer, 'Duschen & Wannen', 'Duschrinne', 'Duschrinne $cm cm', 'Stk.', typ: 'Sanitärobjekt');
  }
  for (final l in const [80, 100, 120, 150, 200, 300, 400, 500]) {
    b.add(kKatSanitaer, 'Warmwasser & Speicher', 'Warmwasserspeicher', 'Warmwasserspeicher $l l', 'Stk.', typ: 'Speicher');
  }
  for (final l in const [5, 10]) {
    b.add(kKatSanitaer, 'Warmwasser & Speicher', 'Untertischspeicher', 'Untertischspeicher $l l', 'Stk.', typ: 'Speicher');
  }
  for (final kw in const [18, 21, 24]) {
    b.add(kKatSanitaer, 'Warmwasser & Speicher', 'Durchlauferhitzer', 'Durchlauferhitzer $kw kW', 'Stk.', typ: 'Speicher');
  }
  for (final x in const [
    'Waschtischsiphon',
    'Flaschensiphon',
    'Röhrensiphon',
    'Spülensiphon',
    'Doppelspülensiphon',
    'Duschsiphon',
    'Badewannensiphon',
    'Waschmaschinensiphon',
    'Raumsparsiphon',
    'Geruchverschluss',
  ]) {
    b.add(kKatSanitaer, 'Siphons', 'Siphon', x, 'Stk.', typ: 'Siphon');
  }
  for (final dn in const [50, 70, 100]) {
    b.add(kKatSanitaer, 'Abflüsse', 'Bodenablauf', 'Bodenablauf DN $dn', 'Stk.', typ: 'Ablauf');
  }
  for (final x in const [
    'Ablaufgarnitur Waschbecken',
    'Ablaufgarnitur Dusche',
    'Ablaufgarnitur Badewanne',
    'Duschablauf',
    'Rückstauverschluss DN 100',
    'Dachablauf DN 70',
    'Dachablauf DN 100',
    'Hofablauf',
  ]) {
    b.add(kKatSanitaer, 'Abflüsse', x.split(' ').first, x, 'Stk.', typ: 'Ablauf');
  }

  // ───────────── Kanalisation / Entwässerung ─────────────
  const htDn = [32, 40, 50, 70, 100, 125, 150];
  for (final dn in htDn) {
    b.add(kKatKanal, 'HT-Rohre', 'HT-Rohr', 'HT-Rohr DN $dn', 'm', typ: 'Rohr');
    b.add(kKatKanal, 'HT-Rohre', 'HT-Muffe', 'HT-Muffe DN $dn', 'Stk.', typ: 'Muffe');
    b.add(kKatKanal, 'HT-Rohre', 'HT-Endkappe', 'HT-Endkappe DN $dn', 'Stk.', typ: 'Zubehör');
  }
  for (final dn in const [50, 70, 100]) {
    b.add(kKatKanal, 'HT-Rohre', 'HT-Reinigungsrohr', 'HT-Reinigungsrohr DN $dn', 'Stk.', typ: 'Zubehör');
    b.add(kKatKanal, 'HT-Rohre', 'HT-Rohrschelle', 'HT-Rohrschelle DN $dn mit Gummieinlage', 'Stk.', typ: 'Zubehör');
    b.add(kKatKanal, 'HT-Rohre', 'Rohrbelüfter', 'Rohrbelüfter DN $dn', 'Stk.', typ: 'Zubehör');
  }
  for (final x in const ['100/50', '100/70', '125/100', '150/100', '70/50']) {
    b.add(kKatKanal, 'HT-Rohre', 'HT-Reduzierung', 'HT-Reduzierung DN $x', 'Stk.', typ: 'Reduzierung');
  }
  b.add(kKatKanal, 'HT-Rohre', 'HT-Übergang', 'HT-Übergang auf KG DN 100/110', 'Stk.', typ: 'Übergang');
  for (final dn in const [110, 125, 160, 200, 250, 315]) {
    b.add(kKatKanal, 'KG-Rohre', 'KG-Rohr', 'KG-Rohr DN $dn', 'm', typ: 'Rohr');
    b.add(kKatKanal, 'KG-Rohre', 'KG-Muffe', 'KG-Muffe DN $dn', 'Stk.', typ: 'Muffe');
    b.add(kKatKanal, 'KG-Rohre', 'KG-Kappe', 'KG-Kappe DN $dn', 'Stk.', typ: 'Zubehör');
  }
  for (final dn in const [110, 160]) {
    b.add(kKatKanal, 'KG-Rohre', 'KG-Reinigungsrohr', 'KG-Reinigungsrohr DN $dn', 'Stk.', typ: 'Zubehör');
    b.add(kKatKanal, 'KG-Rohre', 'KG-Schieber', 'KG-Schieber DN $dn', 'Stk.', typ: 'Zubehör');
  }
  for (final x in const ['125/110', '160/110', '160/125', '200/160']) {
    b.add(kKatKanal, 'KG-Rohre', 'KG-Reduzierung', 'KG-Reduzierung DN $x', 'Stk.', typ: 'Reduzierung');
  }
  for (final grad in const [15, 30, 45, 67, 87]) {
    for (final dn in htDn) {
      if (dn == 150 && grad == 67) continue; // 160 mm: kein 67°
      b.add(kKatKanal, 'Kanal-Bögen & Abzweige', 'HT-Bogen', 'HT-Bogen $grad° DN $dn', 'Stk.', typ: 'Bogen');
    }
  }
  for (final x in const ['50/50', '70/70', '100/50', '100/70', '100/100', '125/100', '150/100']) {
    b.add(kKatKanal, 'Kanal-Bögen & Abzweige', 'HT-Abzweig', 'HT-Abzweig 45° DN $x', 'Stk.', typ: 'Abzweig');
    b.add(kKatKanal, 'Kanal-Bögen & Abzweige', 'HT-Abzweig', 'HT-Abzweig 87° DN $x', 'Stk.', typ: 'Abzweig');
  }
  for (final grad in const [15, 30, 45, 67, 87]) {
    for (final dn in const [110, 125, 160, 200]) {
      b.add(kKatKanal, 'Kanal-Bögen & Abzweige', 'KG-Bogen', 'KG-Bogen $grad° DN $dn', 'Stk.', typ: 'Bogen');
    }
  }
  for (final x in const ['110/110', '125/110', '160/110', '160/160', '200/160', '200/200']) {
    b.add(kKatKanal, 'Kanal-Bögen & Abzweige', 'KG-Abzweig', 'KG-Abzweig 45° DN $x', 'Stk.', typ: 'Abzweig');
    b.add(kKatKanal, 'Kanal-Bögen & Abzweige', 'KG-Abzweig', 'KG-Abzweig 87° DN $x', 'Stk.', typ: 'Abzweig');
  }

  // ───────────── Klima / Lüftung ─────────────
  for (final x in const ['¼"/⅜"', '¼"/½"', '¼"/⅝"', '⅜"/½"', '⅜"/⅝"', '½"/¾"']) {
    for (final m in const [5, 10, 15, 20]) {
      b.add(kKatKlima, 'Klima-Zubehör', 'Klimaleitung', 'Klimaleitung Kupfer isoliert $x $m m', 'Rolle', typ: 'Rohr');
    }
  }
  for (final x in const [
    'Wandkonsole Außengerät',
    'Bodenkonsole Außengerät',
    'Schwingungsdämpfer Gummi',
    'Mauerdurchführung Ø80',
    'Kabelkanal 60×60',
    'Steuerleitung 4×1,5',
    'Bördelmutter ¼"',
    'Bördelmutter ⅜"',
    'Bördelmutter ½"',
    'Bördelmutter ⅝"',
    'Isolierband Klima',
  ]) {
    b.add(kKatKlima, 'Klima-Zubehör', x.split(' ').first, x, 'Stk.', typ: 'Zubehör');
  }
  for (final x in const [
    'Kondensatschlauch Ø16 mm|m',
    'Kondensatschlauch Ø20 mm|m',
    'Kondensatrohr PVC Ø20 mm|m',
    'Kondensatpumpe Mini|Stk.',
    'Kondensat-Siphon|Stk.',
    'Kondensatablauf-Set|Set',
    'Schlauchschelle Kondensat|Stk.',
    'Neutralisationsbox|Stk.',
  ]) {
    final t = x.split('|');
    b.add(kKatKlima, 'Kondensatleitungen', t[0].split(' ').first, t[0], t[1], typ: 'Zubehör');
  }
  for (final d in const [100, 125, 160, 200, 250]) {
    b.add(kKatKlima, 'Lüftung', 'Lüftungsrohr', 'Lüftungsrohr Wickelfalz Ø$d mm', 'm', typ: 'Rohr');
    b.add(kKatKlima, 'Lüftung', 'Lüftungsbogen', 'Lüftungsbogen 90° Ø$d', 'Stk.', typ: 'Bogen');
    b.add(kKatKlima, 'Lüftung', 'Lüftungs-T-Stück', 'Lüftungs-T-Stück Ø$d', 'Stk.', typ: 'T-Stück');
    b.add(kKatKlima, 'Lüftung', 'Flexrohr', 'Flexrohr Aluflex Ø$d mm', 'm', typ: 'Rohr');
    b.add(kKatKlima, 'Lüftung', 'Lüftungsschelle', 'Lüftungsschelle Ø$d', 'Stk.', typ: 'Zubehör');
  }
  for (final x in const ['125/100', '160/125', '200/160']) {
    b.add(kKatKlima, 'Lüftung', 'Lüftungsreduzierung', 'Lüftungsreduzierung Ø$x', 'Stk.', typ: 'Reduzierung');
  }
  for (final x in const [
    'Lüftungsgitter',
    'Badlüfter Ø100',
    'Rohrventilator Ø125',
    'Rückstauklappe Lüftung Ø100',
    'Schalldämpfer Ø125',
  ]) {
    b.add(kKatKlima, 'Lüftung', x.split(' ').first, x, 'Stk.', typ: 'Zubehör');
  }

  // ───────────── Isolierungen ─────────────
  for (final d in _kupfer) {
    b.add(kKatIso, 'Rohrisolierung', 'Isolierung', 'Isolierung Ø$d', 'm', typ: 'Isolierung');
  }
  for (final d in const [22, 28, 35, 42, 54]) {
    b.add(kKatIso, 'Rohrisolierung', 'Rohrisolierung Mineralwolle', 'Rohrisolierung Mineralwolle Ø$d', 'm', typ: 'Isolierung');
  }
  for (final x in const [
    'Isolierband PVC',
    'Alu-Klebeband',
    'Isolierkleber',
    'Isolierung Armatur Kugelhahn',
    'Isolierschlauch Klima 10 mm',
  ]) {
    b.add(kKatIso, 'Zubehör Isolierung', x.split(' ').first, x, 'Stk.', typ: 'Zubehör');
  }

  // ───────────── Befestigung, Schrauben, Dübel ─────────────
  for (final d in const [12, 15, 18, 22, 28, 35, 42, 54, 60, 76, 88, 108]) {
    b.add(kKatBefest, 'Rohrschellen', 'Rohrschelle', 'Rohrschelle Ø$d', 'Stk.', typ: 'Zubehör');
  }
  for (final d in const [15, 18, 22, 28, 35, 42, 54]) {
    b.add(kKatBefest, 'Rohrschellen', 'Schallschutz-Rohrschelle', 'Schallschutz-Rohrschelle Ø$d', 'Stk.', typ: 'Zubehör');
  }
  for (final x in const [
    'Gewindestange M8 1 m|Stk.',
    'Gewindestange M10 1 m|Stk.',
    'Gewindemuffe M8|Stk.',
    'Hammerkopfschraube M8|Pack',
    'Montageschiene 41×41|m',
    'Winkelverbinder|Stk.',
    'Deckenhalter|Stk.',
    'Stockschraube M8|Stk.',
    'Befestigungsbügel|Stk.',
  ]) {
    final t = x.split('|');
    b.add(kKatBefest, 'Befestigungsmaterial', t[0].split(' ').first, t[0], t[1], typ: 'Zubehör');
  }
  for (final x in const [
    'Holzschraube 4×40 Torx',
    'Holzschraube 4×50 Torx',
    'Holzschraube 5×50 Torx',
    'Holzschraube 5×60 Torx',
    'Holzschraube 5×80 Torx',
    'Holzschraube 6×80 Torx',
    'Holzschraube 6×100 Torx',
    'Spanplattenschraube 4×40',
    'Spanplattenschraube 5×60',
    'Blechschraube 4,2×16',
    'Gewindeschraube M6×20',
    'Sechskantschraube M8×40',
    'Sechskantschraube M8×60',
    'Schlossschraube M8×60',
    'Unterlegscheibe M6',
    'Unterlegscheibe M8',
    'Unterlegscheibe M10',
    'Mutter M6',
    'Mutter M8',
    'Mutter M10',
    'Federring M8',
    'Blindniete 4×10',
    'Kabelbinder 200 mm',
    'Kabelbinder 300 mm',
  ]) {
    b.add(kKatBefest, 'Schrauben', x.split(' ').first, x, 'Pack', typ: 'Schraube');
  }
  for (final mm in const [6, 8, 10, 12, 14]) {
    b.add(kKatBefest, 'Dübel', 'Dübel', 'Dübel $mm mm', 'Pack', typ: 'Dübel');
  }
  for (final x in const [
    'Hohlraumdübel M5',
    'Hohlraumdübel M6',
    'Schwerlastanker M8',
    'Schwerlastanker M10',
    'Schwerlastanker M12',
    'Nageldübel 6×60',
    'Gipskartondübel',
    'Injektionsmörtel Kartusche',
  ]) {
    b.add(kKatBefest, 'Dübel', x.split(' ').first, x, 'Pack', typ: 'Dübel');
  }

  // ───────────── Dichtungen ─────────────
  for (final z in _zoll) {
    b.add(kKatDicht, 'Dichtungen', 'Flachdichtung', 'Flachdichtung $z', 'Pack', typ: 'Dichtung');
  }
  for (final x in const [
    'O-Ring Sortiment|Set',
    'Hanf|Pack',
    'Fittingband PTFE|Rolle',
    'Gewindedichtmittel|Stk.',
    'Dichtpaste|Stk.',
    'Silikon sanitär weiß|Stk.',
    'Silikon transparent|Stk.',
    'Acryl weiß|Stk.',
    'Dichtband Wand/Boden|Rolle',
    'Gummimanschette DN 50|Stk.',
    'Gummimanschette DN 100|Stk.',
    'Lippendichtring DN 100|Stk.',
    'Gleitmittel Rohr|Stk.',
    'Dichtungsset Eckventil|Set',
  ]) {
    final t = x.split('|');
    b.add(kKatDicht, 'Dichtungen', t[0].split(' ').first, t[0], t[1], typ: 'Dichtung');
  }

  // ───────────── Werkzeug / Verbrauchsmaterial ─────────────
  for (final x in const [
    'Lötzinn bleifrei|Rolle',
    'Flussmittel|Stk.',
    'Lötpaste|Stk.',
    'Propan-Kartusche|Stk.',
    'Trennscheibe 125 mm|Stk.',
    'Schleifvlies|Pack',
    'Schmirgelleinen|Pack',
    'Putztuch|Pack',
    'Arbeitshandschuhe|Paar',
    'Gewebeklebeband|Rolle',
    'Malerkrepp|Rolle',
    'Abdeckfolie|Rolle',
    'Müllsäcke|Rolle',
    'Bohrer 6 mm|Stk.',
    'Bohrer 8 mm|Stk.',
    'Bohrer 10 mm|Stk.',
    'Bohrer 12 mm|Stk.',
    'Sägeblatt Metall|Pack',
    'Rohrschneiderrad|Stk.',
    'Entgrater|Stk.',
    'Rostlöser|Stk.',
    'Silikonspray|Stk.',
    'Bauschaum|Stk.',
    'Reinigungsspray|Stk.',
  ]) {
    final t = x.split('|');
    b.add(kKatWerkzeug, 'Werkzeug & Verbrauch', t[0].split(' ').first, t[0], t[1], typ: 'Verbrauch');
  }

  // ───────────── Elektro ─────────────
  for (final x in const ['3×1,5', '3×2,5', '5×1,5', '5×2,5', '5×4', '5×6']) {
    b.add(kKatElektro, 'Kabel & Leitungen', 'NYM-J', 'NYM-J $x', 'm', typ: 'Rohr');
  }
  for (final x in const ['M20', 'M25', 'M32']) {
    b.add(kKatElektro, 'Kabel & Leitungen', 'Leerrohr', 'Leerrohr $x', 'm', typ: 'Rohr');
  }
  for (final x in const [
    'Steckdose|Stk.',
    'Schalter|Stk.',
    'Abzweigdose|Stk.',
    'Verbindungsklemme 221 2-fach|Pack',
    'Verbindungsklemme 221 3-fach|Pack',
    'Verbindungsklemme 221 5-fach|Pack',
    'Sicherungsautomat B16|Stk.',
    'FI-Schutzschalter 40 A|Stk.',
    'Aderendhülsen Set|Set',
    'Isolierband|Rolle',
  ]) {
    final t = x.split('|');
    b.add(kKatElektro, 'Installationsmaterial', t[0].split(' ').first, t[0], t[1], typ: 'Zubehör');
  }

  ergaenzeKatalog(b);

  // Feste Reihenfolge der 17 Hauptkategorien; innerhalb bleibt die Reihenfolge.
  final mitIndex = [
    for (var i = 0; i < b.liste.length; i++) MapEntry(i, b.liste[i]),
  ];
  mitIndex.sort((x, y) {
    final kx = kKategorieReihenfolge.indexOf(x.value.kategorie);
    final ky = kKategorieReihenfolge.indexOf(y.value.kategorie);
    final c = (kx < 0 ? 99 : kx).compareTo(ky < 0 ? 99 : ky);
    return c != 0 ? c : x.key.compareTo(y.key);
  });
  return [for (final e in mitIndex) e.value];
}
