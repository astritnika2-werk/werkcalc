// Ergänzungen des Master-Katalogs: alle SHK-Bereiche mit generischen
// Fachartikeln (keine Marken, keine Artikelnummern, keine Preise).
// Teil 1: Sanitär, Bad, Heizung, Wärmeerzeuger, Klima, Lüftung, Abwasser.
// Teil 2 steht in katalog_zusatz2.dart.

import 'katalog_basis.dart';
import 'katalog_zusatz2.dart';

void ergaenzeKatalog(KatalogBaukasten b) {
  _sanitaer(b);
  _bad(b);
  _heizung(b);
  _waermeerzeuger(b);
  _klima(b);
  _lueftung(b);
  _abwasser(b);
  ergaenzeKatalogTeil2(b);
}

// ───────────────────────── Sanitär / Wasser ─────────────────────────
void _sanitaer(KatalogBaukasten b) {
  const k = kSanitaer;
  b.liste_(k, 'Eckventile & Anschlüsse', [
    'Eckventil Durchgang ½"',
    'Eckventil mit Filter ½"×⅜"',
    'Eckventil Kombi Doppel ½"×⅜"',
    'Geräteanschlussventil ½"',
    'Geräteanschlussventil ¾"',
    'Eckventil Aufputz ½"',
    'Eckventil Unterputz ½"',
  ], 'Stk.', typ: 'Ventil', stichworte: 'absperrung');
  for (final l in const [200, 300, 400, 500, 600, 800]) {
    b.add(k, 'Eckventile & Anschlüsse', 'Flexschlauch', 'Flexschlauch ⅜" $l mm', 'Stk.', typ: 'Zubehör', stichworte: 'anschlussschlauch');
    b.add(k, 'Eckventile & Anschlüsse', 'Flexschlauch', 'Flexschlauch ½" $l mm', 'Stk.', typ: 'Zubehör', stichworte: 'anschlussschlauch');
  }
  for (final l in const [300, 500, 800, 1000]) {
    b.add(k, 'Eckventile & Anschlüsse', 'Flexschlauch', 'Flexschlauch ¾" $l mm', 'Stk.', typ: 'Zubehör', stichworte: 'anschlussschlauch');
    b.add(k, 'Eckventile & Anschlüsse', 'Flexschlauch', 'Flexschlauch 1" $l mm', 'Stk.', typ: 'Zubehör', stichworte: 'anschlussschlauch');
  }
  b.liste_(k, 'Spülkästen & Vorwandelemente', [
    'Spülkasten Aufputz',
    'Spülkasten Halbhoch',
    'Spülkasten Unterputz 6/3 l',
    'Spülkasten Unterputz 4,5/3 l',
    'Spülkasten Ersatz-Füllventil',
    'Spülkasten Ersatz-Ablaufventil',
    'Spülkasten Dichtungssatz',
    'Spülkasten Anschlussschlauch',
    'Vorwandelement Waschtisch',
    'Vorwandelement Bidet',
    'Vorwandelement Urinal',
    'Vorwandelement WC Höhe 1120 mm',
    'Vorwandelement WC Höhe 820 mm',
    'Vorwandelement WC barrierefrei',
    'Vorwandelement Dusche',
    'Vorwandelement Eckmontage',
    'Drückerplatte Dual weiß',
    'Drückerplatte Dual chrom',
    'Drückerplatte Dual schwarz',
    'Drückerplatte Dual Edelstahl',
    'Drückerplatte Urinal',
    'Drückerplatte berührungslos',
    'Schallschutzset Vorwandelement',
  ], 'Stk.', typ: 'WC-Technik', stichworte: 'wc toilette');
  b.liste_(k, 'Warmwasser-Zubehör', [
    'Zirkulationsset Warmwasser',
    'Zirkulationsregulierventil ½"',
    'Zirkulationsregulierventil ¾"',
    'Thermostatischer Zirkulationsregler ½"',
    'Thermostatischer Zirkulationsregler ¾"',
    'Verbrühschutz Thermostatmischer ½"',
    'Verbrühschutz Thermostatmischer ¾"',
    'Brauchwasser-Ausdehnungsgefäß 8 l',
    'Brauchwasser-Ausdehnungsgefäß 18 l',
    'Brauchwasser-Ausdehnungsgefäß 25 l',
    'Brauchwasser-Ausdehnungsgefäß 35 l',
    'Brauchwasser-Ausdehnungsgefäß 50 l',
    'Opferanode Magnesium',
    'Heizpatrone Speicher 2 kW',
  ], 'Stk.', typ: 'Zubehör', stichworte: 'warmwasser boiler');
  for (final d in const [15, 20, 25, 32, 40, 50]) {
    b.add(k, 'Trinkwasser-Installation', 'Systemtrenner', 'Systemtrenner BA DN $d', 'Stk.', typ: 'Ventil');
    b.add(k, 'Trinkwasser-Installation', 'Freistromventil', 'Freistromventil DN $d', 'Stk.', typ: 'Ventil');
    b.add(k, 'Trinkwasser-Installation', 'Wasserzähler', 'Wasserzähler-Anschlussbügel DN $d', 'Stk.', typ: 'Zubehör');
  }
  b.liste_(k, 'Trinkwasser-Installation', [
    'Hauswasseranschluss-Set',
    'Hausanschlussarmatur',
    'Probenahmeventil ½"',
    'Entleerventil ½"',
    'Spülstation Trinkwasser',
    'Absperrventil Wasserzähler ¾"',
    'Absperrventil Wasserzähler 1"',
    'Rückflussverhinderer mit Prüfstutzen ¾"',
    'Rückflussverhinderer mit Prüfstutzen 1"',
  ], 'Stk.', typ: 'Ventil');
  for (final z in const ['½"', '¾"', '1"']) {
    b.add(k, 'Wasserhähne & Auslauf', 'Auslaufventil', 'Auslaufventil $z', 'Stk.', typ: 'Armatur', stichworte: 'wasserhahn');
    b.add(k, 'Wasserhähne & Auslauf', 'Standventil', 'Standventil $z', 'Stk.', typ: 'Armatur', stichworte: 'wasserhahn');
    b.add(k, 'Wasserhähne & Auslauf', 'Schlauchverschraubung', 'Schlauchverschraubung $z', 'Stk.', typ: 'Zubehör');
  }
  for (final l in const [200, 300, 400, 500, 750, 1000]) {
    b.add(k, 'Wasserhähne & Auslauf', 'Außenwandarmatur', 'Außenwandarmatur frostsicher $l mm', 'Stk.', typ: 'Armatur', stichworte: 'wasserhahn gartenhahn');
  }
  b.liste_(k, 'Wasserhähne & Auslauf', [
    'Gartenhahn ¾"',
    'Waschmaschinen-Absperrventil ¾"',
    'Rohrunterbrecher ½"',
  ], 'Stk.', typ: 'Armatur', stichworte: 'wasserhahn');
  for (final z in kZollListe) {
    b.add(k, 'Kugelhähne & Ventile', 'Kugelhahn', 'Kugelhahn Mini $z AG/IG', 'Stk.', typ: 'Ventil');
    b.add(k, 'Kugelhähne & Ventile', 'Kugelhahn', 'Kugelhahn $z AG/AG', 'Stk.', typ: 'Ventil');
    b.add(k, 'Kugelhähne & Ventile', 'Kugelhahn', 'Kugelhahn $z mit Entleerung', 'Stk.', typ: 'Ventil');
    b.add(k, 'Kugelhähne & Ventile', 'Rückschlagventil', 'Rückschlagventil $z', 'Stk.', typ: 'Ventil');
    b.add(k, 'Kugelhähne & Ventile', 'Schrägsitzventil', 'Schrägsitzventil $z', 'Stk.', typ: 'Ventil');
  }
  for (final d in kMm) {
    b.add(k, 'Kugelhähne & Ventile', 'Absperrventil', 'Absperrventil Press Ø$d', 'Stk.', typ: 'Ventil');
  }
  b.liste_(k, 'Filter & Druckminderer', [
    'Druckminderer ½"',
    'Druckminderer 1¼"',
    'Druckminderer 1½"',
    'Druckminderer 2"',
    'Rückspülfilter ¾"',
    'Rückspülfilter 1"',
    'Rückspülfilter 1¼"',
    'Feinfilter ¾"',
    'Feinfilter 1"',
    'Filtereinsatz 90 µm',
    'Filtereinsatz 50 µm',
  ], 'Stk.', typ: 'Filter');
}

// ───────────────────────── Bad / Sanitär-Ausstattung ─────────────────────────
void _bad(KatalogBaukasten b) {
  const k = kBad;
  b.liste_(k, 'WC & Urinal', [
    'WC Stand Flachspüler',
    'WC wandhängend spülrandlos',
    'WC Stand spülrandlos',
    'WC Kombination Stand mit Spülkasten',
    'WC wandhängend barrierefrei',
    'WC-Sitz Standard',
    'WC-Sitz Soft-Close abnehmbar',
    'WC-Sitz Duroplast',
    'WC-Anschlussbogen DN 90',
    'WC-Anschlussbogen DN 100',
    'WC-Anschlussstutzen DN 110',
    'WC-Anschlussmanschette DN 100',
    'WC-Anschlussmanschette DN 110',
    'WC-Befestigungsset',
    'WC-Bürste mit Halter',
    'WC-Papierhalter',
    'Urinal Absaug',
    'Urinal Steuerung Sensor',
    'Dusch-WC Aufsatz',
    'Bidet wandhängend',
    'Bidet stehend',
  ], 'Stk.', typ: 'Sanitärobjekt', stichworte: 'toilette tualet');
  for (final cm in const [40, 45, 55, 65, 70, 90, 120]) {
    b.add(k, 'Waschtische & Armaturen', 'Waschtisch', 'Waschtisch $cm cm', 'Stk.', typ: 'Sanitärobjekt');
  }
  for (final cm in const [40, 45, 50, 60]) {
    b.add(k, 'Waschtische & Armaturen', 'Handwaschbecken', 'Handwaschbecken $cm cm', 'Stk.', typ: 'Sanitärobjekt', stichworte: 'waschbecken waschtisch lavaman');
  }
  for (final cm in const [60, 80, 100, 120, 140]) {
    b.add(k, 'Waschtische & Armaturen', 'Doppelwaschtisch', 'Doppelwaschtisch $cm cm', 'Stk.', typ: 'Sanitärobjekt', stichworte: 'waschbecken');
  }
  b.liste_(k, 'Waschtische & Armaturen', [
    'Waschtisch-Unterschrank 60 cm',
    'Waschtisch-Unterschrank 80 cm',
    'Waschtisch-Unterschrank 100 cm',
    'Waschtisch-Unterschrank 120 cm',
    'Waschtisch Aufsatz rund',
    'Waschtisch Aufsatz eckig',
    'Waschtisch-Konsolen Paar',
    'Waschtisch-Befestigung Set',
    'Waschtischarmatur Hoch',
    'Waschtischarmatur Wandmontage',
    'Waschtischarmatur Zweigriff',
    'Waschtischarmatur Unterputz Set',
    'Bidetarmatur Einhebelmischer',
    'Küchenarmatur Hochdruck',
    'Küchenarmatur Niederdruck',
    'Küchenarmatur mit Brause',
    'Spültischarmatur Wandmontage',
    'Thermostatarmatur Dusche Aufputz',
    'Thermostatarmatur Wanne Aufputz',
    'Thermostatarmatur Unterputz Set',
    'Unterputz-Grundkörper Einhebelmischer',
    'Unterputz-Grundkörper Thermostat',
    'Kopfbrause 250 mm',
    'Kopfbrause 300 mm',
    'Duschstange 900 mm',
    'Duschstange 700 mm',
    'Wandanschlussbogen ½"',
    'Seifenschale',
    'Handtuchhalter',
    'Badspiegel 60 cm',
    'Badspiegel 80 cm',
    'Badspiegel mit Beleuchtung',
    'Spiegelschrank 60 cm',
    'Spiegelschrank 80 cm',
    'Badmöbel Hochschrank',
    'Badmöbel Midischrank',
  ], 'Stk.', typ: 'Armatur');
  for (final x in const ['70×70', '75×75', '90×90', '100×100', '90×120', '90×140', '90×160', '80×160', '100×140']) {
    b.add(k, 'Duschen & Wannen', 'Duschwanne', 'Duschwanne $x', 'Stk.', typ: 'Sanitärobjekt');
  }
  for (final x in const ['160×70', '170×70', '170×80', '180×80', '180×90', '190×90']) {
    b.add(k, 'Duschen & Wannen', 'Badewanne', 'Badewanne rechteck $x', 'Stk.', typ: 'Sanitärobjekt');
  }
  b.liste_(k, 'Duschen & Wannen', [
    'Duschwannenträger',
    'Duschwannen-Ablauf DN 50',
    'Duschwannen-Ablauf DN 90',
    'Duschabtrennung Walk-In 90 cm',
    'Duschabtrennung Walk-In 120 cm',
    'Duschabtrennung Pendeltür',
    'Duschabtrennung Eckeinstieg',
    'Duschabtrennung Nische',
    'Duschtür Schiebetür',
    'Wannenträger',
    'Wannenfüße Set',
    'Wannenablauf Überlauf',
    'Wanneneinlauf',
    'Duschrinne Edelstahl 70 cm',
    'Duschrinne Edelstahl 90 cm',
    'Duschrinne Edelstahl 120 cm',
    'Verbundabdichtung Dusche',
    'Dichtmanschette Bodenablauf',
  ], 'Stk.', typ: 'Zubehör');
  b.liste_(k, 'Waschtische & Armaturen', [
    'Waschbecken 45 cm',
    'Waschbecken 50 cm',
    'Waschbecken 60 cm',
    'Waschbecken Eck',
  ], 'Stk.', typ: 'Sanitärobjekt', familie: 'Waschbecken', stichworte: 'waschtisch lavaman');
  b.liste_(k, 'Waschtische & Armaturen', [
    'Waschtisch-Siphon Flasche chrom',
    'Waschtisch-Siphon Raumspar',
    'Waschtisch-Siphon Röhre',
  ], 'Stk.', typ: 'Siphon', familie: 'Waschtisch-Siphon', stichworte: 'siphon');
  b.liste_(k, 'Ablaufgarnituren & Zubehör', [
    'Ablaufgarnitur Waschtisch Push-Open',
    'Ablaufgarnitur Waschtisch mit Überlauf',
    'Ablaufgarnitur Waschtisch ohne Überlauf',
    'Ablaufgarnitur Spüle 3½"',
    'Ablaufgarnitur Spüle 90 mm',
    'Ablaufgarnitur Doppelspüle',
    'Ablaufgarnitur Bidet',
    'Ablaufgarnitur Duschwanne',
    'Ablaufventil Badewanne',
    'Ablaufstopfen',
    'Stöpselkette',
    'Überlaufset',
    'Verlängerungsrohr Siphon 32 mm',
    'Verlängerungsrohr Siphon 40 mm',
  ], 'Stk.', typ: 'Zubehör');
}

// ───────────────────────── Heizung ─────────────────────────
void _heizung(KatalogBaukasten b) {
  const k = kHeizung;
  for (final typ in const [10, 11, 21, 22, 33]) {
    for (final h in const [400, 900]) {
      for (final l in const [600, 800, 1000, 1200, 1600]) {
        b.add(k, 'Heizkörper', 'Kompaktheizkörper', 'Kompaktheizkörper Typ $typ $h×$l', 'Stk.', typ: 'Heizkörper');
      }
    }
  }
  for (final h in const [1200, 1500, 1800, 2000]) {
    for (final l in const [400, 500, 600, 750]) {
      b.add(k, 'Heizkörper', 'Designheizkörper', 'Designheizkörper $h×$l', 'Stk.', typ: 'Heizkörper', stichworte: 'radiator');
    }
  }
  b.liste_(k, 'Heizkörper', [
    'Heizkörper-Verschraubung ½"',
    'Heizkörper-Verschraubung ¾"',
    'Heizkörper-Anschlussverschraubung Eck',
    'Heizkörper-Anschlussverschraubung gerade',
    'Heizkörper-Anschlussgarnitur Mittelanschluss',
    'Heizkörper-Befestigung Set',
    'Heizkörper-Blindstopfen ½"',
    'Heizkörper-Verschlussstopfen links',
    'Heizkörper-Verschlussstopfen rechts',
    'Heizkörper-Entlüftungsventil',
    'Heizkörper-Entlüftungsschlüssel',
    'Heizkörper-Rosette Ø15',
    'Heizkörper-Rosette Ø18',
    'Heizkörper-Anschlussrohr Kupfer verchromt Ø15',
    'Heizkörper-Anschlussrohr Kupfer verchromt Ø18',
    'Heizkörper-Reflexionsfolie',
  ], 'Stk.', typ: 'Zubehör');
  b.liste_(k, 'Thermostate & Heizkörperarmaturen', [
    'Thermostat Heizkörper Standard',
    'Thermostat Heizkörper programmierbar',
    'Thermostatkopf Fernfühler',
    'Thermostatkopf Fernversteller',
    'Thermostatventil Unterteil gerade',
    'Thermostatventil Unterteil Eck',
    'Thermostatventil Axial',
    'Thermostatventil Durchgang ¾"',
    'Rücklaufverschraubung Durchgang ¾"',
    'Rücklaufverschraubung Axial',
    'Rücklaufverschraubung Eck ¾"',
    'Raumthermostat Aufputz',
    'Raumthermostat Unterputz',
    'Raumthermostat Funk',
    'Fußbodenheizung Raumthermostat 230 V',
    'Fußbodenheizung Raumthermostat 24 V',
    'Stellantrieb 24 V stromlos geschlossen',
    'Stellantrieb 230 V stromlos geschlossen',
    'Stellantrieb Funk',
    'Frostschutzthermostat',
    'Adapter für Thermostatkopf',
  ], 'Stk.', typ: 'Ventil');
  for (final dn in const [20, 25, 32, 40, 50]) {
    b.add(k, 'Mischer & Stellmotoren', 'Heizkreismischer', 'Heizkreismischer 3-Wege DN $dn', 'Stk.', typ: 'Ventil', stichworte: 'mischer');
    b.add(k, 'Mischer & Stellmotoren', 'Heizkreismischer', 'Heizkreismischer 4-Wege DN $dn', 'Stk.', typ: 'Ventil', stichworte: 'mischer');
  }
  for (final z in const ['¾"', '1"', '1¼"', '1½"', '2"']) {
    b.add(k, 'Mischer & Stellmotoren', 'Mischer', 'Mischer 3-Wege Gewinde $z', 'Stk.', typ: 'Ventil');
    b.add(k, 'Mischer & Stellmotoren', 'Mischer', 'Mischer 4-Wege Gewinde $z', 'Stk.', typ: 'Ventil');
  }
  b.liste_(k, 'Mischer & Stellmotoren', [
    'Mischermotor 230 V',
    'Mischermotor 24 V',
    'Mischermotor stetig 0–10 V',
    'Stellmotor Umschaltventil',
    'Zonenventil 2-Wege ¾"',
    'Zonenventil 2-Wege 1"',
    'Zonenventil 3-Wege ¾"',
    'Zonenventil 3-Wege 1"',
    'Rücklaufanhebung',
    'Thermische Ablaufsicherung',
  ], 'Stk.', typ: 'Zubehör');
  for (final x in const ['25-40', '25-60', '25-80', '25-100', '30-60', '30-80', '32-40', '32-60', '32-80', '40-60', '40-80', '40-120', '50-80', '50-120']) {
    b.add(k, 'Pumpen', 'Heizkreispumpe', 'Heizkreispumpe $x', 'Stk.', typ: 'Pumpe', stichworte: 'umwälzpumpe heizungspumpe qarkullimi');
  }
  for (final x in const ['25-40 130 mm', '25-60 130 mm', '25-60 180 mm', '25-80 180 mm', '32-60 180 mm', '32-80 180 mm', '40-60 250 mm', '40-80 250 mm']) {
    b.add(k, 'Pumpen', 'Umwälzpumpe', 'Umwälzpumpe $x', 'Stk.', typ: 'Pumpe', stichworte: 'heizungspumpe qarkullimi');
  }
  for (final dn in const [15, 20, 25]) {
    b.add(k, 'Pumpen', 'Zirkulationspumpe', 'Zirkulationspumpe DN $dn', 'Stk.', typ: 'Pumpe', stichworte: 'umwälzpumpe qarkullimi');
  }
  b.liste_(k, 'Pumpen', [
    'Pumpenverschraubung ¾"',
    'Pumpenverschraubung 1"',
    'Pumpenverschraubung 1¼"',
    'Pumpenverschraubung 1½"',
    'Pumpenverschraubung 2"',
    'Pumpenisolierschale',
    'Pumpenisolierschale Heizung',
    'Pumpenisolierschale Zirkulation',
    'Pumpenstecker',
  ], 'Stk.', typ: 'Zubehör');
  for (final bar in const ['1,5', '2,5', '3', '4', '6']) {
    b.add(k, 'Sicherheit', 'Sicherheitsventil', 'Sicherheitsventil ½" $bar bar', 'Stk.', typ: 'Ventil');
    b.add(k, 'Sicherheit', 'Sicherheitsventil', 'Sicherheitsventil ¾" $bar bar', 'Stk.', typ: 'Ventil');
  }
  for (final l in const [8, 12, 18, 24, 35, 50, 80, 100, 150, 200, 300, 500]) {
    b.add(k, 'Ausdehnungsgefäße', 'Ausdehnungsgefäß', 'Ausdehnungsgefäß Heizung $l l', 'Stk.', typ: 'Zubehör');
  }
  b.liste_(k, 'Ausdehnungsgefäße', [
    'Ausdehnungsgefäß Montageset',
    'Ausdehnungsgefäß Absperrarmatur ¾"',
    'Ausdehnungsgefäß Wandhalter',
    'Kappenventil ¾"',
    'Kesselsicherheitsgruppe',
  ], 'Stk.', typ: 'Zubehör');
  b.liste_(k, 'Entlüfter & Abscheider', [
    'Automatischer Entlüfter ½"',
    'Automatischer Entlüfter ⅜"',
    'Automatischer Entlüfter ¾"',
    'Schnellentlüfter ⅜"',
    'Schnellentlüfter ¾"',
    'Entlüftungsventil Handentlüfter',
    'Luftabscheider DN 20',
    'Luftabscheider DN 25',
    'Luftabscheider DN 32',
    'Luftabscheider DN 40',
    'Luftabscheider DN 50',
    'Schlammabscheider DN 20',
    'Schlammabscheider DN 25',
    'Schlammabscheider DN 32',
    'Schlammabscheider DN 40',
    'Schlammabscheider DN 50',
    'Magnetit-Abscheider',
  ], 'Stk.', typ: 'Zubehör');
  for (final n in const [10, 20, 30, 40, 50]) {
    b.add(k, 'Wärmetauscher', 'Plattenwärmetauscher', 'Plattenwärmetauscher $n Platten', 'Stk.', typ: 'Zubehör', stichworte: 'wärmetauscher');
  }
  for (final kw in const [15, 30, 50, 80, 120]) {
    b.add(k, 'Wärmetauscher', 'Plattenwärmetauscher', 'Plattenwärmetauscher $kw kW', 'Stk.', typ: 'Zubehör', stichworte: 'wärmetauscher');
  }
  b.liste_(k, 'Wärmetauscher', [
    'Wärmetauscher-Dichtungssatz',
    'Frischwasserstation Wärmetauscher',
  ], 'Stk.', typ: 'Zubehör', stichworte: 'wärmetauscher');
  b.liste_(k, 'Heizungszubehör', [
    'Heizungswasser Inhibitor',
    'Heizungsreiniger',
    'Frostschutz Heizung Konzentrat',
    'Heizungs-Füllset',
    'Heizungs-Nachfülleinrichtung',
    'Kesselfüllhahn ½"',
    'Kesselfüll- und Entleerhahn ¾"',
    'Entleerhahn mit Schlauchanschluss',
    'Rosette Doppel',
    'Wandscheibe Ø15',
    'Wandscheibe Ø18',
    'Anschlussrohr Heizkörper Ø15 verchromt (m)',
    'Dehnungsbogen Kupfer',
    'Heizkreisverteiler-Kugelhahnset',
    'Hydraulischer Abgleich Set',
  ], 'Stk.', typ: 'Zubehör');
  for (final n in const [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]) {
    b.add(k, 'Fußbodenheizung', 'Heizkreisverteiler', 'Heizkreisverteiler Edelstahl $n Kreise', 'Stk.', typ: 'Zubehör');
  }
  b.liste_(k, 'Fußbodenheizung', [
    'Verteilerschrank Aufputz',
    'Verteilerschrank Unterputz',
    'Klemmverschraubung PE-RT Ø16',
    'Klemmverschraubung PE-RT Ø17',
    'Klemmverschraubung PE-RT Ø20',
    'Tackerplatte',
    'Tackernadel',
    'Rohrhalter Fußbodenheizung',
    'Wärmeleitblech',
    'Dehnungsfugenprofil',
    'Estrichzusatzmittel',
  ], 'Stk.', typ: 'Zubehör');
  for (final d in const [14, 16, 17, 20]) {
    b.add(k, 'Fußbodenheizung', 'Fußbodenheizungsrohr', 'Fußbodenheizungsrohr PE-Xa Ø$d mm', 'm', typ: 'Rohr');
    b.add(k, 'Fußbodenheizung', 'Fußbodenheizungsrohr', 'Fußbodenheizungsrohr PE-RT Ø$d mm', 'm', typ: 'Rohr');
  }
}

// ───────────────────────── Wärmeerzeuger ─────────────────────────
void _waermeerzeuger(KatalogBaukasten b) {
  const k = kWaermeerzeuger;
  for (final kw in const [11, 15, 19, 24, 28, 35, 45]) {
    b.add(k, 'Gasheizung', 'Gas-Brennwertkessel', 'Gas-Brennwertkessel wandhängend $kw kW', 'Stk.', typ: 'Kessel', stichworte: 'gasheizung kaldaja kessel');
  }
  for (final kw in const [24, 28, 35]) {
    b.add(k, 'Gasheizung', 'Gas-Brennwerttherme', 'Gas-Brennwerttherme Kombi $kw kW', 'Stk.', typ: 'Kessel', stichworte: 'gasheizung kombitherme');
  }
  for (final kw in const [20, 30, 45, 60, 80]) {
    b.add(k, 'Gasheizung', 'Gas-Brennwertkessel', 'Gas-Brennwertkessel Stand $kw kW', 'Stk.', typ: 'Kessel', stichworte: 'gasheizung kessel');
  }
  b.liste_(k, 'Gasheizung', [
    'Gasanschluss-Set',
    'Gasabsperrhahn ½"',
    'Gasabsperrhahn ¾"',
    'Gasabsperrhahn 1"',
    'Gashahn Eck ½"',
    'Gasströmungswächter',
    'Gasdruckregler',
    'Gasfilter',
    'Gasleitung Edelstahl Wellrohr DN 15',
    'Gasleitung Edelstahl Wellrohr DN 20',
    'Gasleitung Edelstahl Wellrohr DN 25',
  ], 'Stk.', typ: 'Zubehör', stichworte: 'gas');
  for (final kw in const [18, 24, 30, 40]) {
    b.add(k, 'Ölheizung', 'Öl-Brennwertkessel', 'Öl-Brennwertkessel $kw kW', 'Stk.', typ: 'Kessel', stichworte: 'ölheizung kessel');
  }
  b.liste_(k, 'Ölheizung', [
    'Ölbrenner 18–30 kW',
    'Ölbrenner 30–60 kW',
    'Ölbrennerdüse',
    'Öltank 1000 l',
    'Öltank 2000 l',
    'Öltank 5000 l',
    'Ölfilter',
    'Ölleitung Kupfer Ø8 mm',
    'Ölleitung Kupfer Ø10 mm',
    'Ölstandsanzeiger',
  ], 'Stk.', typ: 'Zubehör', stichworte: 'öl');
  for (final kw in const [4, 6, 8, 10, 12, 14, 16, 20]) {
    b.add(k, 'Wärmepumpe', 'Luft-Wasser-Wärmepumpe', 'Luft-Wasser-Wärmepumpe Monoblock $kw kW', 'Stk.', typ: 'Wärmepumpe', stichworte: 'wärmepumpe nxehtesie');
  }
  for (final kw in const [4, 6, 8, 10, 12, 16]) {
    b.add(k, 'Wärmepumpe', 'Luft-Wasser-Wärmepumpe', 'Luft-Wasser-Wärmepumpe Split $kw kW', 'Stk.', typ: 'Wärmepumpe', stichworte: 'wärmepumpe nxehtesie');
    b.add(k, 'Wärmepumpe', 'Sole-Wasser-Wärmepumpe', 'Sole-Wasser-Wärmepumpe $kw kW', 'Stk.', typ: 'Wärmepumpe', stichworte: 'wärmepumpe nxehtesie erdwärme');
  }
  b.liste_(k, 'Wärmepumpe', [
    'Warmwasser-Wärmepumpe 200 l',
    'Warmwasser-Wärmepumpe 300 l',
    'Wärmepumpe Innengerät Hydraulikmodul',
    'Wärmepumpe Außeneinheit Fundament',
    'Wärmepumpe Schwingungsdämpfer',
    'Wärmepumpe Kondensatablauf',
    'Wärmepumpe Anschlussleitung flexibel DN 25',
    'Wärmepumpe Anschlussleitung flexibel DN 32',
    'Wärmepumpe Leitungsdurchführung',
    'Wärmepumpe Elektro-Heizstab 6 kW',
    'Wärmepumpe Elektro-Heizstab 9 kW',
  ], 'Stk.', typ: 'Zubehör', stichworte: 'wärmepumpe nxehtesie');
  for (final kw in const [3, 6, 9, 12, 15, 18, 24]) {
    b.add(k, 'Elektroheizung', 'Elektro-Heizstab', 'Elektro-Heizstab $kw kW', 'Stk.', typ: 'Heizgerät');
  }
  for (final kw in const [6, 9, 12, 18, 24]) {
    b.add(k, 'Elektroheizung', 'Elektro-Durchlauferhitzer Heizung', 'Elektro-Durchlauferhitzer Heizung $kw kW', 'Stk.', typ: 'Heizgerät');
  }
  for (final w in const [300, 450, 600, 800, 1000]) {
    b.add(k, 'Elektroheizung', 'Infrarotheizung', 'Infrarotheizung $w W', 'Stk.', typ: 'Heizgerät');
  }
  b.liste_(k, 'Elektroheizung', [
    'Elektro-Heizkörper',
    'Elektro-Thermostat Heizkörper',
    'Elektro-Fußbodenheizmatte',
    'Elektro-Fußbodenheizkabel',
  ], 'Stk.', typ: 'Heizgerät');
  b.liste_(k, 'Brenner', [
    'Gasbrenner',
    'Brennerdüse',
    'Zündelektrode',
    'Ionisationselektrode',
    'Zündtransformator',
    'Brennerdichtung',
    'Brennerflansch-Dichtung',
    'Gasventil Brenner',
    'Gebläse Brenner',
    'Feuerungsautomat',
    'Magnetventil Brenner',
  ], 'Stk.', typ: 'Ersatzteil');
  b.liste_(k, 'Kessel', [
    'Brennwert-Wärmetauscher',
    'Kesselsiphon',
    'Kessel-Neutralisationsbox',
    'Kessel-Wartungshahn',
    'Kesselthermostat',
    'Kesseltemperaturbegrenzer',
    'Kesselpumpe',
    'Kesseldichtung Revisionsöffnung',
    'Kessel Umschaltventil Heizung/Warmwasser',
    'Kessel-Plattenwärmetauscher Warmwasser',
  ], 'Stk.', typ: 'Ersatzteil');
  b.liste_(k, 'Regelung & Sensoren', [
    'Witterungsgeführter Regler',
    'Raumbediengerät',
    'Raumbediengerät Funk',
    'Heizungsregelung Zweikreis',
    'Heizungsregelung Mischerkreis-Erweiterung',
    'Außenfühler',
    'Außenfühler Funk',
    'Vorlauffühler Tauchhülse',
    'Vorlauffühler Anlegefühler',
    'Rücklauffühler',
    'Speicherfühler',
    'Pufferfühler',
    'Raumfühler',
    'Abgasfühler',
    'Kollektorfühler',
    'Tauchhülse ½" 100 mm',
    'Tauchhülse ½" 150 mm',
    'Tauchhülse ½" 200 mm',
    'Busmodul Erweiterung',
    'Internetmodul Heizung',
    'Drucksensor Heizung',
    'Wassermangelsicherung',
    'Sicherheitstemperaturbegrenzer',
  ], 'Stk.', typ: 'Regelung');
  for (final dn in const [60, 80, 100, 125, 160]) {
    for (final l in const [250, 500, 1000, 2000]) {
      b.add(k, 'Abgas-Zubehör', 'Abgasrohr', 'Abgasrohr PP DN $dn $l mm', 'Stk.', typ: 'Rohr', stichworte: 'abgas kaminrohr');
    }
    b.add(k, 'Abgas-Zubehör', 'Abgasbogen', 'Abgasbogen 45° DN $dn', 'Stk.', typ: 'Bogen', stichworte: 'abgas');
    b.add(k, 'Abgas-Zubehör', 'Abgasbogen', 'Abgasbogen 87° DN $dn', 'Stk.', typ: 'Bogen', stichworte: 'abgas');
    b.add(k, 'Abgas-Zubehör', 'Abgas-Revisionsöffnung', 'Abgas-Revisionsöffnung DN $dn', 'Stk.', typ: 'Zubehör', stichworte: 'abgas');
    b.add(k, 'Abgas-Zubehör', 'Abgas-Muffe', 'Abgas-Muffe DN $dn', 'Stk.', typ: 'Muffe', stichworte: 'abgas');
    b.add(k, 'Abgas-Zubehör', 'Abgas-Halter', 'Abgas-Wandhalter DN $dn', 'Stk.', typ: 'Zubehör', stichworte: 'abgas schelle');
    b.add(k, 'Abgas-Zubehör', 'Abgas-Abstandhalter', 'Abgas-Abstandhalter DN $dn', 'Stk.', typ: 'Zubehör', stichworte: 'abgas spreizring');
  }
  for (final x in const ['60/100', '80/125', '110/160']) {
    for (final l in const [500, 1000, 2000]) {
      b.add(k, 'Abgas-Zubehör', 'LAS-Rohr', 'LAS-Rohr konzentrisch DN $x $l mm', 'Stk.', typ: 'Rohr', stichworte: 'abgas luft-abgas');
    }
    b.add(k, 'Abgas-Zubehör', 'LAS-Bogen', 'LAS-Bogen 87° konzentrisch DN $x', 'Stk.', typ: 'Bogen', stichworte: 'abgas luft-abgas');
    b.add(k, 'Abgas-Zubehör', 'LAS-Bogen', 'LAS-Bogen 45° konzentrisch DN $x', 'Stk.', typ: 'Bogen', stichworte: 'abgas luft-abgas');
    b.add(k, 'Abgas-Zubehör', 'LAS-Dachdurchführung', 'LAS-Dachdurchführung DN $x', 'Stk.', typ: 'Zubehör', stichworte: 'abgas luft-abgas');
    b.add(k, 'Abgas-Zubehör', 'LAS-Wanddurchführung', 'LAS-Wanddurchführung DN $x', 'Stk.', typ: 'Zubehör', stichworte: 'abgas luft-abgas');
  }
  b.liste_(k, 'Abgas-Zubehör', [
    'Abgas-Mündungsstück',
    'Abgas-Kondensatablauf',
    'Abgas-Kaminanschluss',
    'Abgas-Dichtung Lippe',
    'Abgas-Gleitmittel',
    'Abgas-Dachhaube',
    'Abgas-Rückschlagklappe',
    'Abgas-Nebenluftvorrichtung',
  ], 'Stk.', typ: 'Zubehör', stichworte: 'abgas');
  for (final l in const [100, 150, 200, 300, 400, 500, 750, 800, 1000, 1500, 2000]) {
    b.add(k, 'Speicher', 'Pufferspeicher', 'Pufferspeicher $l l', 'Stk.', typ: 'Speicher');
  }
  for (final l in const [300, 400, 500, 800, 1000]) {
    b.add(k, 'Speicher', 'Hygienespeicher', 'Hygienespeicher $l l', 'Stk.', typ: 'Speicher', stichworte: 'frischwasser puffer');
    b.add(k, 'Speicher', 'Kombispeicher', 'Kombispeicher $l l', 'Stk.', typ: 'Speicher', stichworte: 'solar puffer');
  }
  for (final l in const [120, 150, 200, 300, 400, 500, 750, 1000]) {
    b.add(k, 'Speicher', 'Warmwasserspeicher', 'Warmwasserspeicher stehend $l l', 'Stk.', typ: 'Speicher');
  }
  b.liste_(k, 'Speicher', [
    'Speicher-Isolierung',
    'Speicher-Tauchhülse',
    'Speicher-Anschlussset',
    'Speicher-Flanschdichtung',
    'Speicher-Ladepumpe Set',
  ], 'Stk.', typ: 'Zubehör');
  for (final dn in const [20, 25, 32]) {
    b.add(k, 'Hydraulikgruppen', 'Pumpengruppe', 'Pumpengruppe DN $dn gemischt', 'Stk.', typ: 'Hydraulik');
    b.add(k, 'Hydraulikgruppen', 'Pumpengruppe', 'Pumpengruppe DN $dn ungemischt', 'Stk.', typ: 'Hydraulik');
  }
  for (final dn in const [25, 32, 40, 50, 65, 80, 100]) {
    b.add(k, 'Hydraulikgruppen', 'Hydraulische Weiche', 'Hydraulische Weiche DN $dn', 'Stk.', typ: 'Hydraulik');
  }
  for (final n in const [2, 3, 4]) {
    b.add(k, 'Hydraulikgruppen', 'Verteilerbalken', 'Verteilerbalken $n Heizkreise', 'Stk.', typ: 'Hydraulik');
  }
  b.liste_(k, 'Hydraulikgruppen', [
    'Frischwasserstation 20 l/min',
    'Frischwasserstation 40 l/min',
    'Frischwasserstation 60 l/min',
    'Solarstation 2-strängig',
  ], 'Stk.', typ: 'Hydraulik');
}

// ───────────────────────── Klima ─────────────────────────
void _klima(KatalogBaukasten b) {
  const k = kKlima;
  for (final kw in const ['2,0', '2,5', '3,5', '5,0', '7,0']) {
    b.add(k, 'Split-Klimageräte', 'Split-Klimagerät', 'Split-Klimagerät Wandgerät $kw kW', 'Set', typ: 'Gerät', stichworte: 'klimaanlage');
    b.add(k, 'Außengeräte', 'Außengerät', 'Außengerät Split $kw kW', 'Stk.', typ: 'Gerät', stichworte: 'klimaanlage');
    b.add(k, 'Innengeräte', 'Innengerät', 'Innengerät Wandgerät $kw kW', 'Stk.', typ: 'Gerät', stichworte: 'klimaanlage');
  }
  for (final kw in const ['3,5', '5,0', '7,0', '10,0']) {
    b.add(k, 'Innengeräte', 'Kassettengerät', 'Kassettengerät $kw kW', 'Stk.', typ: 'Gerät', stichworte: 'klimaanlage innengerät');
    b.add(k, 'Innengeräte', 'Kanalgerät', 'Kanalgerät $kw kW', 'Stk.', typ: 'Gerät', stichworte: 'klimaanlage innengerät');
    b.add(k, 'Innengeräte', 'Truhengerät', 'Truhengerät $kw kW', 'Stk.', typ: 'Gerät', stichworte: 'klimaanlage innengerät');
  }
  for (final n in const [2, 3, 4, 5]) {
    b.add(k, 'Multisplit', 'Multisplit-Außengerät', 'Multisplit-Außengerät für $n Innengeräte', 'Stk.', typ: 'Gerät', stichworte: 'klimaanlage');
  }
  for (final kw in const ['2,0', '2,5', '3,5', '5,0']) {
    b.add(k, 'Multisplit', 'Multisplit-Innengerät', 'Multisplit-Innengerät Wandgerät $kw kW', 'Stk.', typ: 'Gerät', stichworte: 'klimaanlage innengerät');
  }
  for (final z in const ['¼"', '⅜"', '½"', '⅝"', '¾"']) {
    b.add(k, 'Kältemittelleitungen', 'Kältemittelleitung', 'Kältemittelleitung Kupfer $z Rolle 25 m', 'Rolle', typ: 'Rohr', stichworte: 'klimaleitung kupfer');
    b.add(k, 'Kältemittelleitungen', 'Kältemittelleitung', 'Kältemittelleitung Kupfer $z Rolle 50 m', 'Rolle', typ: 'Rohr', stichworte: 'klimaleitung kupfer');
    b.add(k, 'Kältemittelleitungen', 'Kupferrohr Kälte', 'Kupferrohr Kälte $z (m)', 'm', typ: 'Rohr', stichworte: 'klimaleitung kältemittel');
    b.add(k, 'Kältemittelleitungen', 'Isolierung Kälte', 'Isolierung Kälte Schlauch $z 9 mm', 'm', typ: 'Isolierung', stichworte: 'kälteisolierung klima');
    b.add(k, 'Kältemittelleitungen', 'Isolierung Kälte', 'Isolierung Kälte Schlauch $z 13 mm', 'm', typ: 'Isolierung', stichworte: 'kälteisolierung klima');
  }
  b.liste_(k, 'Kältemittelleitungen', [
    'Kältemittel R32',
    'Kältemittel R410A',
    'Kältemittel R290',
    'Füllschlauch Kältemittel',
    'Kälte-Absperrventil ¼"',
    'Kälte-Absperrventil ⅜"',
    'Kälte-Absperrventil ½"',
    'Kälte-Absperrventil ⅝"',
    'Kälte-Absperrventil ¾"',
  ], 'Stk.', typ: 'Zubehör', stichworte: 'kältemittel');
  b.liste_(k, 'Split-Klimageräte', [
    'Klimagerät mobil 2,6 kW',
    'Klimagerät mobil 3,5 kW',
    'Klimagerät Monoblock Fenster 2,0 kW',
    'Klimagerät Monoblock Wand 2,5 kW',
  ], 'Stk.', typ: 'Gerät', familie: 'Klimagerät', stichworte: 'klimaanlage');
  b.liste_(k, 'Kondensatleitungen', [
    'Kondensatpumpe Wandgerät',
    'Kondensatpumpe Kanalgerät',
    'Kondensatpumpe Kassettengerät',
    'Kondensatpumpe Brennwert',
    'Kondensatschlauch Ø10 mm',
    'Kondensatschlauch Ø12 mm',
    'Kondensatschlauch Ø25 mm',
    'Kondensat-Rückschlagventil',
    'Kondensat-Abzweig Ø16',
    'Kondensat-Abzweig Ø20',
    'Kondensat-Winkel Ø16',
    'Kondensat-Winkel Ø20',
    'Kondensat-Muffe Ø16',
    'Kondensat-Muffe Ø20',
  ], 'Stk.', typ: 'Zubehör', stichworte: 'kondensat');
  b.liste_(k, 'Halterungen & Konsolen', [
    'Wandkonsole 300 mm',
    'Wandkonsole 400 mm',
    'Wandkonsole 500 mm',
    'Wandkonsole 600 mm',
    'Wandkonsole 800 mm',
    'Wandkonsole klappbar',
    'Bodenkonsole Außengerät',
    'Bodenfuß Außengerät Gummi',
    'Dachkonsole Außengerät',
    'Schwingungsdämpfer Außengerät',
    'Außengeräte-Fundamentplatte',
    'Deckenhalterung Innengerät',
    'Montageplatte Innengerät',
    'Kabelkanal Klima 60×60',
    'Kabelkanal Klima 80×60',
    'Kabelkanal Klima 100×60',
    'Kabelkanal-Winkel',
    'Kabelkanal-Endstück',
    'Mauerdurchführung Ø70',
    'Mauerdurchführung Ø80',
    'Mauerdurchführung Ø90',
    'Wetterschutz Klima-Leitung',
    'Regenhaube Außengerät',
  ], 'Stk.', typ: 'Zubehör', stichworte: 'halterung konsole');
  for (final q in const ['3×1,5', '4×1,5', '4×2,5', '5×1,5', '5×2,5']) {
    b.add(k, 'Kabel & Steuerung', 'Verbindungskabel Klima', 'Verbindungskabel Klima $q', 'm', typ: 'Kabel', stichworte: 'kabel');
  }
  b.liste_(k, 'Kabel & Steuerung', [
    'Fernbedienung Klimagerät',
    'Kabelfernbedienung Klima',
    'Wandsteuerung Klima',
    'WLAN-Modul Klimagerät',
    'Zentralsteuerung Multisplit',
    'Zeitschaltuhr Klima',
    'Klima-Trennschalter',
    'Klima-Steckdose Außengerät',
  ], 'Stk.', typ: 'Steuerung');
}

// ───────────────────────── Lüftung ─────────────────────────
void _lueftung(KatalogBaukasten b) {
  const k = kLueftung;
  const dn = [80, 100, 125, 150, 160, 180, 200, 250, 315];
  for (final d in dn) {
    b.add(k, 'Lüftungsrohre', 'Lüftungsrohr', 'Lüftungsrohr Spiro Ø$d mm 1 m', 'Stk.', typ: 'Rohr');
    b.add(k, 'Lüftungsrohre', 'Lüftungsrohr', 'Lüftungsrohr Spiro Ø$d mm 3 m', 'Stk.', typ: 'Rohr');
    b.add(k, 'Lüftungsrohre', 'Flexrohr', 'Flexrohr PVC Ø$d mm', 'm', typ: 'Rohr');
    b.add(k, 'Lüftungsrohre', 'Flexrohr', 'Flexrohr isoliert Ø$d mm', 'm', typ: 'Rohr');
    b.add(k, 'Bögen, T-Stücke, Reduzierungen', 'Lüftungsbogen', 'Lüftungsbogen 45° Ø$d', 'Stk.', typ: 'Bogen');
    b.add(k, 'Bögen, T-Stücke, Reduzierungen', 'Lüftungsbogen', 'Lüftungsbogen 30° Ø$d', 'Stk.', typ: 'Bogen');
    b.add(k, 'Bögen, T-Stücke, Reduzierungen', 'Lüftungsbogen', 'Lüftungsbogen 90° Ø$d', 'Stk.', typ: 'Bogen');
    b.add(k, 'Bögen, T-Stücke, Reduzierungen', 'Lüftungs-T-Stück', 'Lüftungs-T-Stück Ø$d', 'Stk.', typ: 'T-Stück');
    b.add(k, 'Bögen, T-Stücke, Reduzierungen', 'Lüftungs-T-Stück', 'Lüftungs-Abzweig 45° Ø$d', 'Stk.', typ: 'Abzweig');
    b.add(k, 'Bögen, T-Stücke, Reduzierungen', 'Lüftungs-Muffe', 'Lüftungs-Muffe Ø$d', 'Stk.', typ: 'Muffe');
    b.add(k, 'Bögen, T-Stücke, Reduzierungen', 'Lüftungs-Endkappe', 'Lüftungs-Endkappe Ø$d', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Befestigung', 'Lüftungsschelle', 'Lüftungsschelle mit Gummi Ø$d', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Filter & Schalldämpfer', 'Schalldämpfer', 'Schalldämpfer Lüftung Ø$d', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Klappen', 'Rückschlagklappe', 'Rückschlagklappe Lüftung Ø$d', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Klappen', 'Brandschutzmanschette', 'Brandschutzmanschette Lüftung Ø$d', 'Stk.', typ: 'Zubehör', stichworte: 'brandschutzklappe');
  }
  for (final x in const ['100/80', '125/100', '150/125', '160/125', '160/150', '200/160', '250/200', '315/250']) {
    b.add(k, 'Bögen, T-Stücke, Reduzierungen', 'Lüftungsreduzierung', 'Lüftungs-Reduzierung Ø$x', 'Stk.', typ: 'Reduzierung');
  }
  for (final x in const ['100×50', '150×70', '220×90', '220×110', '300×150']) {
    b.add(k, 'Flachkanäle', 'Flachkanal', 'Flachkanal $x mm 1 m', 'Stk.', typ: 'Rohr', stichworte: 'kanal');
    b.add(k, 'Flachkanäle', 'Flachkanal', 'Flachkanal-Bogen horizontal $x', 'Stk.', typ: 'Bogen', stichworte: 'kanal');
    b.add(k, 'Flachkanäle', 'Flachkanal', 'Flachkanal-Bogen vertikal $x', 'Stk.', typ: 'Bogen', stichworte: 'kanal');
    b.add(k, 'Flachkanäle', 'Flachkanal', 'Flachkanal-Verbinder $x', 'Stk.', typ: 'Muffe', stichworte: 'kanal');
    b.add(k, 'Flachkanäle', 'Flachkanal', 'Flachkanal-Endkappe $x', 'Stk.', typ: 'Zubehör', stichworte: 'kanal');
  }
  for (final d in const [100, 125, 150]) {
    b.add(k, 'Flachkanäle', 'Flachkanal-Übergang', 'Flachkanal-Übergang auf Rohr Ø$d', 'Stk.', typ: 'Übergang');
    b.add(k, 'Ventile & Gitter', 'Tellerventil', 'Tellerventil Zuluft Ø$d', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Ventile & Gitter', 'Tellerventil', 'Tellerventil Abluft Ø$d', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Ventile & Gitter', 'Zuluftventil', 'Zuluftventil Ø$d', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Ventile & Gitter', 'Abluftventil', 'Abluftventil Ø$d', 'Stk.', typ: 'Zubehör');
  }
  for (final x in const ['100×100', '150×150', '200×100', '200×200', '300×150', '300×300']) {
    b.add(k, 'Ventile & Gitter', 'Lüftungsgitter', 'Lüftungsgitter $x mm', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Ventile & Gitter', 'Lüftungsgitter', 'Wetterschutzgitter $x mm', 'Stk.', typ: 'Zubehör');
  }
  for (final d in const [100, 125, 150, 160, 200]) {
    b.add(k, 'Ventilatoren', 'Rohrventilator', 'Rohrventilator Ø$d', 'Stk.', typ: 'Ventilator');
    b.add(k, 'Ventilatoren', 'Rohrventilator', 'Rohrventilator Ø$d mit Nachlauf', 'Stk.', typ: 'Ventilator');
  }
  b.liste_(k, 'Ventilatoren', [
    'Badlüfter Ø100 mit Nachlauf',
    'Badlüfter Ø100 mit Feuchtesensor',
    'Badlüfter Ø125',
    'Axialventilator Wand Ø100',
    'Axialventilator Wand Ø150',
    'Dachventilator Ø160',
    'Dachventilator Ø250',
    'Zentrales Lüftungsgerät 200 m³/h',
    'Zentrales Lüftungsgerät 300 m³/h',
    'Zentrales Lüftungsgerät 400 m³/h',
    'Dezentrales Lüftungsgerät',
  ], 'Stk.', typ: 'Ventilator');
  b.liste_(k, 'Filter & Schalldämpfer', [
    'Filtermatte G4',
    'Filterelement F7',
    'Filterwechselset G4',
    'Filterwechselset F7',
    'Pollenfilter',
    'Flex-Schalldämpfer Ø125',
    'Flex-Schalldämpfer Ø160',
  ], 'Stk.', typ: 'Zubehör');
  b.liste_(k, 'Klappen', [
    'Brandschutzklappe rund Ø100',
    'Brandschutzklappe rund Ø125',
    'Brandschutzklappe rund Ø160',
    'Brandschutzklappe rund Ø200',
    'Volumenstromregler Ø100',
    'Volumenstromregler Ø125',
    'Absperrklappe Lüftung Ø100',
    'Absperrklappe Lüftung Ø125',
    'Absperrklappe Lüftung Ø160',
  ], 'Stk.', typ: 'Zubehör');
  b.liste_(k, 'Befestigung', [
    'Lüftungs-Montageband',
    'Lüftungs-Dichtband',
    'Lüftungs-Alu-Klebeband',
    'Lüftungs-Wanddurchführung Ø100',
    'Lüftungs-Wanddurchführung Ø125',
    'Dachdurchführung Lüftung Ø125',
    'Dachdurchführung Lüftung Ø160',
    'Außenwandhaube Ø100',
    'Außenwandhaube Ø125',
    'Außenwandhaube Ø150',
  ], 'Stk.', typ: 'Zubehör');
}

// ───────────────────────── Abwasser / Kanalisation ─────────────────────────
void _abwasser(KatalogBaukasten b) {
  const k = kAbwasser;
  for (final dn in const [110, 125, 160, 200, 250, 315]) {
    b.add(k, 'KG2000', 'KG2000-Rohr', 'KG2000-Rohr DN $dn', 'm', typ: 'Rohr', stichworte: 'kanalrohr');
    b.add(k, 'KG2000', 'KG2000-Muffe', 'KG2000-Muffe DN $dn', 'Stk.', typ: 'Muffe');
    b.add(k, 'KG2000', 'KG2000-Muffe', 'KG2000-Schiebemuffe DN $dn', 'Stk.', typ: 'Muffe');
    for (final g in const [15, 30, 45, 67, 87]) {
      b.add(k, 'KG2000', 'KG2000-Bogen', 'KG2000-Bogen $g° DN $dn', 'Stk.', typ: 'Bogen');
    }
    b.add(k, 'KG2000', 'KG2000-Kappe', 'KG2000-Kappe DN $dn', 'Stk.', typ: 'Zubehör');
  }
  for (final x in const ['110/110', '160/110', '160/160', '200/160', '200/200', '250/160', '250/250']) {
    b.add(k, 'KG2000', 'KG2000-Abzweig', 'KG2000-Abzweig 45° DN $x', 'Stk.', typ: 'Abzweig');
    b.add(k, 'KG2000', 'KG2000-Abzweig', 'KG2000-Abzweig 87° DN $x', 'Stk.', typ: 'Abzweig');
  }
  for (final x in const ['125/110', '160/110', '160/125', '200/160', '250/200', '315/250']) {
    b.add(k, 'KG2000', 'KG2000-Reduzierung', 'KG2000-Reduzierung DN $x', 'Stk.', typ: 'Reduzierung');
  }
  for (final l in const [500, 1000, 2000, 3000]) {
    b.add(k, 'HT-Rohre', 'HT-Rohr', 'HT-Rohr DN 50 $l mm', 'Stk.', typ: 'Rohr');
    b.add(k, 'HT-Rohre', 'HT-Rohr', 'HT-Rohr DN 100 $l mm', 'Stk.', typ: 'Rohr');
    b.add(k, 'KG-Rohre', 'KG-Rohr', 'KG-Rohr DN 110 $l mm', 'Stk.', typ: 'Rohr');
    b.add(k, 'KG-Rohre', 'KG-Rohr', 'KG-Rohr DN 160 $l mm', 'Stk.', typ: 'Rohr');
  }
  for (final dn in const [32, 40, 50, 70, 100]) {
    b.add(k, 'Revision & Reinigung', 'Revisionsstück', 'HT-Revisionsstück DN $dn', 'Stk.', typ: 'Zubehör', stichworte: 'reinigung');
  }
  for (final dn in const [110, 125, 160, 200]) {
    b.add(k, 'Revision & Reinigung', 'Revisionsstück', 'KG-Revisionsstück DN $dn', 'Stk.', typ: 'Zubehör', stichworte: 'reinigung');
  }
  for (final dn in const [50, 70, 100, 125, 150]) {
    b.add(k, 'Bodenabläufe', 'Bodenablauf', 'Bodenablauf DN $dn senkrecht', 'Stk.', typ: 'Ablauf');
    b.add(k, 'Bodenabläufe', 'Bodenablauf', 'Bodenablauf DN $dn waagerecht', 'Stk.', typ: 'Ablauf');
    b.add(k, 'Bodenabläufe', 'Bodenablauf', 'Bodenablauf Rost Edelstahl DN $dn', 'Stk.', typ: 'Ablauf');
  }
  b.liste_(k, 'Bodenabläufe', [
    'Bodenablauf Kellerablauf DN 100',
    'Bodenablauf mit Rückstauklappe DN 100',
    'Bodenablauf Aufsatz 150×150',
    'Bodenablauf Aufsatz 200×200',
    'Balkonablauf DN 50',
    'Terrassenablauf DN 70',
    'Terrassenablauf DN 100',
    'Hofablauf mit Eimer DN 100',
    'Gully Kunststoff DN 100',
  ], 'Stk.', typ: 'Ablauf');
  for (final cm in const [50, 100, 150, 200]) {
    b.add(k, 'Rinnen', 'Entwässerungsrinne', 'Entwässerungsrinne Systemrinne $cm cm', 'Stk.', typ: 'Rinne', stichworte: 'rinne');
    b.add(k, 'Rinnen', 'Entwässerungsrinne', 'Entwässerungsrinne mit Gitterrost $cm cm', 'Stk.', typ: 'Rinne', stichworte: 'rinne');
  }
  b.liste_(k, 'Rinnen', [
    'Rinnen-Stirnwand',
    'Rinnen-Stirnwand mit Auslauf',
    'Rinnen-Sandfang',
    'Rinnen-Gitterrost verzinkt',
    'Rinnen-Gitterrost Edelstahl',
    'Rinnen-Abdeckung Klasse A',
    'Rinnen-Abdeckung Klasse B',
    'Rinnen-Abdeckung Klasse C',
    'Linienentwässerung Dusche 80 cm',
    'Linienentwässerung Dusche 100 cm',
    'Linienentwässerung Dusche 120 cm',
  ], 'Stk.', typ: 'Rinne', stichworte: 'rinne');
  for (final dn in const [100, 125, 150, 200]) {
    b.add(k, 'Rückstausicherung', 'Rückstauklappe', 'Rückstauklappe DN $dn', 'Stk.', typ: 'Zubehör', stichworte: 'rückstau');
    b.add(k, 'Rückstausicherung', 'Rückstauklappe', 'Rückstauklappe Kanal DN $dn doppelt', 'Stk.', typ: 'Zubehör', stichworte: 'rückstau');
  }
  b.liste_(k, 'Rückstausicherung', [
    'Rückstauverschluss DN 50',
    'Rückstauverschluss DN 70',
    'Rückstauverschluss DN 125',
    'Hebeanlage Fäkalien',
    'Hebeanlage Kleinhebeanlage WC',
    'Hebeanlage Grauwasser',
    'Doppelpumpenanlage',
  ], 'Stk.', typ: 'Zubehör', stichworte: 'rückstau');
  b.liste_(k, 'Geruchsverschlüsse', [
    'Geruchsverschluss Trockensiphon DN 50',
    'Geruchsverschluss Trockensiphon DN 70',
    'Geruchsverschluss Trockensiphon DN 100',
    'Geruchsverschluss Membran DN 40',
    'Geruchsverschluss Membran DN 50',
    'Geruchsverschluss Kondensat',
    'Rohrbelüfter DN 32',
    'Rohrbelüfter DN 125',
    'Dachentlüfter DN 100',
    'Dachentlüfter DN 125',
    'Dachdurchführung Entlüftung DN 100',
    'Dachdurchführung Entlüftung DN 125',
  ], 'Stk.', typ: 'Zubehör', stichworte: 'geruchsverschluss siphon');
  for (final dn in const [50, 70, 100, 125, 160, 200]) {
    b.add(k, 'Muffen, Übergänge, Dichtungen', 'Rohrmuffe', 'Überschiebmuffe DN $dn', 'Stk.', typ: 'Muffe');
    b.add(k, 'Muffen, Übergänge, Dichtungen', 'Dichtung', 'Lippendichtring DN $dn', 'Stk.', typ: 'Dichtung');
    b.add(k, 'Muffen, Übergänge, Dichtungen', 'Rohrmuffe', 'Doppelsteckmuffe DN $dn', 'Stk.', typ: 'Muffe');
  }
  b.liste_(k, 'Muffen, Übergänge, Dichtungen', [
    'Übergang HT auf KG DN 100/110',
    'Übergang HT auf KG DN 125/125',
    'Übergang KG auf Steinzeug DN 150',
    'Übergang KG auf Steinzeug DN 200',
    'Übergang Gusseisen auf HT DN 100',
    'Übergang Gusseisen auf HT DN 125',
    'Anschlussmanschette Rohr DN 50',
    'Anschlussmanschette Rohr DN 100',
    'Mauerdurchführung Kanal DN 100',
    'Mauerdurchführung Kanal DN 160',
    'Gleitmittel Kanalrohr',
  ], 'Stk.', typ: 'Zubehör');
  b.liste_(k, 'Schächte', [
    'Kontrollschacht DN 1000 Beton',
    'Kontrollschacht Kunststoff DN 315',
    'Kontrollschacht Kunststoff DN 400',
    'Kontrollschacht Kunststoff DN 600',
    'Schachtring DN 1000',
    'Schachtkonus DN 1000',
    'Schachtboden DN 1000',
    'Schachtabdeckung Klasse B 125',
    'Schachtabdeckung Klasse D 400',
    'Schachtabdeckung Kunststoff',
    'Steigbügel Schacht',
    'Kanaleinlauf',
    'Sinkkasten',
    'Sickerschacht',
    'Fettabscheider',
    'Leichtflüssigkeitsabscheider',
    'Revisionsschacht Kunststoff',
    'Regenwassertank 1500 l',
    'Regenwassertank 3000 l',
    'Regenwasserfilter',
    'Dränagerohr DN 100',
    'Dränagerohr DN 125',
    'Dränagerohr DN 160',
    'Dränagevlies',
    'Dränagekies',
  ], 'Stk.', typ: 'Zubehör', stichworte: 'schacht kanalzubehör');
}
