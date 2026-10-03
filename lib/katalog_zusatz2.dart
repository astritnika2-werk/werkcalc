// Ergänzungen des Master-Katalogs, Teil 2: Rohre, Fittings, Wassertechnik,
// Installation/Montage, Isolierung, Werkzeug, Verbrauchsmaterial,
// Regenerative Energien, Messen/Prüfen, Elektro.

import 'katalog_basis.dart';

String _g(int mm) => const {
      15: '½"', 18: '½"', 22: '¾"', 28: '1"', 35: '1¼"', 42: '1½"', 54: '2"',
    }[mm]!;

void ergaenzeKatalogTeil2(KatalogBaukasten b) {
  _rohre(b);
  _fittings(b);
  _wassertechnik(b);
  _montage(b);
  _isolierung(b);
  _werkzeug(b);
  _verbrauch(b);
  _regenerativ(b);
  _messen(b);
  _elektro(b);
}

// ───────────────────────── Rohre ─────────────────────────
void _rohre(KatalogBaukasten b) {
  const k = kRohre;
  for (final d in const [6, 8, 10]) {
    b.add(k, 'Kupferrohre', 'Kupferrohr', 'Kupferrohr Ø$d mm', 'm', typ: 'Rohr');
  }
  for (final d in const [6, 8, 10, 12, 15, 18]) {
    b.add(k, 'Kupferrohre', 'Kupferrohr Rolle', 'Kupferrohr weich Rolle Ø$d mm', 'Rolle', typ: 'Rohr', stichworte: 'ringbund');
  }
  for (final d in const [12, 15, 18, 22, 28, 35, 42, 54]) {
    b.add(k, 'Kupferrohre', 'Kupferrohr verchromt', 'Kupferrohr verchromt Ø$d mm', 'm', typ: 'Rohr');
  }
  for (final d in const [15, 18, 22, 28, 35, 42, 54, 64, 76, 88, 108]) {
    b.add(k, 'Edelstahlrohre', 'Edelstahlrohr', 'Edelstahlrohr Ø$d mm 1,4301', 'm', typ: 'Rohr', stichworte: 'inox');
  }
  for (final d in const [15, 18, 22, 28, 35, 42, 54]) {
    b.add(k, 'Edelstahlrohre', 'Edelstahlrohr', 'Edelstahlrohr Ø$d mm 1,4401', 'm', typ: 'Rohr', stichworte: 'inox');
  }
  for (final dn in const [15, 20, 25]) {
    b.add(k, 'Edelstahlrohre', 'Edelstahl-Wellrohr', 'Edelstahl-Wellrohr DN $dn', 'm', typ: 'Rohr', stichworte: 'inox');
  }
  for (final d in const [14, 16, 18, 20, 25, 26, 32, 40, 50, 63, 75]) {
    b.add(k, 'Mehrschichtverbundrohre', 'Mehrschichtverbundrohr', 'Mehrschichtverbundrohr Ø$d mm (Rolle)', 'Rolle', typ: 'Rohr');
  }
  for (final d in const [16, 20, 26, 32]) {
    b.add(k, 'Mehrschichtverbundrohre', 'Mehrschichtverbundrohr', 'Mehrschichtverbundrohr Ø$d mm isoliert', 'm', typ: 'Rohr');
    b.add(k, 'Mehrschichtverbundrohre', 'Mehrschichtverbundrohr', 'Mehrschichtverbundrohr Ø$d mm im Schutzrohr', 'm', typ: 'Rohr');
  }
  for (final d in const [16, 20, 25, 32, 40, 50, 63, 75, 90, 110, 125, 160]) {
    b.add(k, 'Kunststoffrohre', 'PE-Rohr', 'PE-Rohr Ø$d mm', 'm', typ: 'Rohr');
    b.add(k, 'Kunststoffrohre', 'PVC-Rohr', 'PVC-U Druckrohr Ø$d mm', 'm', typ: 'Rohr', stichworte: 'pvc');
  }
  for (final d in const [16, 20, 25, 32, 40, 50, 63]) {
    b.add(k, 'Kunststoffrohre', 'PE-X Rohr', 'PE-X Rohr Ø$d mm', 'm', typ: 'Rohr', stichworte: 'pex');
    b.add(k, 'Kunststoffrohre', 'PP-Rohr', 'PP-H Rohr Ø$d mm', 'm', typ: 'Rohr', stichworte: 'pp');
  }
  for (final d in const [16, 20, 25, 32]) {
    b.add(k, 'Kunststoffrohre', 'PE-X Rohr', 'PE-X Rohr Ø$d mm mit Sauerstoffsperre', 'm', typ: 'Rohr', stichworte: 'pex');
    b.add(k, 'Kunststoffrohre', 'PE-X Rohr', 'PE-X Rohr Ø$d mm im Schutzrohr', 'm', typ: 'Rohr', stichworte: 'pex');
  }
  for (final z in kZollListe) {
    b.add(k, 'Stahlrohre', 'Stahlrohr', 'Gewinderohr verzinkt $z', 'm', typ: 'Rohr', stichworte: 'stahlrohr');
    b.add(k, 'Stahlrohre', 'Stahlrohr', 'Gewinderohr schwarz $z', 'm', typ: 'Rohr', stichworte: 'stahlrohr');
  }
  for (final dn in const [20, 25, 32, 40, 50, 65, 80, 100, 125, 150]) {
    b.add(k, 'Stahlrohre', 'Stahlrohr', 'Stahlrohr nahtlos DN $dn', 'm', typ: 'Rohr');
    b.add(k, 'Stahlrohre', 'Stahlrohr', 'Stahlrohr verzinkt DN $dn', 'm', typ: 'Rohr');
  }
  for (final d in kMm) {
    b.add(k, 'Stahlrohre', 'Stahlrohr', 'Stahlrohr C-Stahl verzinkt Ø$d mm', 'm', typ: 'Rohr');
  }
  b.liste_(k, 'Rohrzubehör', [
    'Rohrabdeckung Kunststoff',
    'Schutzrohr Ø20',
    'Schutzrohr Ø25',
    'Schutzrohr Ø32',
    'Wellrohr Kabelschutz',
  ], 'Stk.', typ: 'Zubehör');
}

// ───────────────────────── Fittings ─────────────────────────
void _fittings(KatalogBaukasten b) {
  const k = kFittings;
  for (final d in kMm) {
    b.add(k, 'Kupferfittings (Löt)', 'Kupfer-Kreuzstück', 'Kupfer-Kreuzstück Ø$d', 'Stk.', typ: 'Kreuzstück', stichworte: 'kreuz');
    b.add(k, 'Kupferfittings (Löt)', 'Kupferbogen', 'Kupferbogen 90° A/A Ø$d', 'Stk.', typ: 'Bogen');
    b.add(k, 'Kupferfittings (Löt)', 'Kupfer-Wandwinkel', 'Kupfer-Wandwinkel Ø$d auf ${_g(d)}', 'Stk.', typ: 'Bogen', stichworte: 'wandscheibe');
    b.add(k, 'Kupferfittings (Löt)', 'Kupfer-Überschiebmuffe', 'Kupfer-Überschiebmuffe Ø$d', 'Stk.', typ: 'Muffe');
    b.add(k, 'Kupferfittings (Löt)', 'Lötfitting', 'Lötfitting Verschraubung Ø$d', 'Stk.', typ: 'Zubehör', stichworte: 'kupfer');
    b.add(k, 'Kupferfittings (Löt)', 'Lötfitting', 'Lötfitting Rotguss Bogen 90° Ø$d', 'Stk.', typ: 'Bogen', stichworte: 'kupfer');
  }
  for (final d in kMm) {
    const u = 'Pressfittings';
    b.add(k, u, 'Pressfitting', 'Pressfitting Kreuz Ø$d (Kupfer)', 'Stk.', typ: 'Kreuzstück');
    b.add(k, u, 'Pressfitting', 'Pressfitting Bogen 90° A/I Ø$d (Kupfer)', 'Stk.', typ: 'Bogen');
    b.add(k, u, 'Pressfitting', 'Pressfitting Wandscheibe Ø$d (Kupfer)', 'Stk.', typ: 'Zubehör');
    b.add(k, u, 'Pressfitting', 'Pressfitting Überschiebmuffe Ø$d (Kupfer)', 'Stk.', typ: 'Muffe');
    b.add(k, u, 'Pressfitting', 'Pressfitting Verschraubung Ø$d (Kupfer)', 'Stk.', typ: 'Zubehör');
    b.add(k, u, 'Pressfitting', 'Pressfitting Bogen 90° A/I Ø$d (Edelstahl)', 'Stk.', typ: 'Bogen');
    b.add(k, u, 'Pressfitting', 'Pressfitting Wandscheibe Ø$d (Edelstahl)', 'Stk.', typ: 'Zubehör');
    b.add(k, u, 'Pressfitting', 'Pressfitting Überschiebmuffe Ø$d (Edelstahl)', 'Stk.', typ: 'Muffe');
    b.add(k, u, 'Pressfitting', 'Pressfitting Bogen 90° A/I Ø$d (C-Stahl)', 'Stk.', typ: 'Bogen');
  }
  for (final d in const [16, 20, 26, 32]) {
    b.add(k, 'Pressfittings', 'Pressfitting', 'Pressfitting Kreuz Ø$d (Mehrschicht)', 'Stk.', typ: 'Kreuzstück');
    b.add(k, 'Pressfittings', 'Pressfitting', 'Pressfitting Wandscheibe Ø$d (Mehrschicht)', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Pressfittings', 'Pressfitting', 'Pressfitting Bogen 90° A/I Ø$d (Mehrschicht)', 'Stk.', typ: 'Bogen');
  }
  for (final d in const [14, 16, 17, 20, 25]) {
    b.add(k, 'Klemmverschraubungen', 'Klemmverschraubung', 'Klemmverschraubung Ø$d', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Klemmverschraubungen', 'Klemmring', 'Klemmring Ø$d', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Klemmverschraubungen', 'Klemmverschraubung', 'Klemmverschraubung Eurokonus Ø$d', 'Stk.', typ: 'Zubehör');
  }
  for (final z in kZollListe) {
    const u = 'Gewindefittings';
    b.add(k, u, 'Gewindefitting', 'Gewindefitting Kreuzstück IG $z', 'Stk.', typ: 'Kreuzstück');
    b.add(k, u, 'Gewindefitting', 'Gewindefitting Bogen 90° AG/AG $z', 'Stk.', typ: 'Bogen');
    b.add(k, u, 'Gewindefitting', 'Gewindefitting Bogen 45° AG/AG $z', 'Stk.', typ: 'Bogen');
    b.add(k, u, 'Gewindefitting', 'Gewindefitting Langnippel $z 80 mm', 'Stk.', typ: 'Nippel');
    b.add(k, u, 'Gewindefitting', 'Gewindefitting Kappe AG $z', 'Stk.', typ: 'Zubehör');
    b.add(k, u, 'Gewindefitting', 'Gewindefitting Stopfen IG $z', 'Stk.', typ: 'Zubehör');
    b.add(k, u, 'Gewindefitting', 'Gewindefitting Nippel Messing $z', 'Stk.', typ: 'Nippel');
    b.add(k, u, 'Gewindefitting', 'Gewindefitting Muffe AG/AG $z', 'Stk.', typ: 'Muffe');
    b.add(k, u, 'Gewindefitting', 'Gewindefitting Rohrverschraubung flach dichtend $z', 'Stk.', typ: 'Zubehör');
    b.add(k, u, 'Gewindefitting', 'Gewindefitting Rohrverschraubung konisch $z', 'Stk.', typ: 'Zubehör');
    b.add(k, u, 'Gewindefitting', 'Gewindefitting Winkel verzinkt 90° $z', 'Stk.', typ: 'Bogen');
    b.add(k, u, 'Gewindefitting', 'Gewindefitting T-Stück verzinkt $z', 'Stk.', typ: 'T-Stück');
    b.add(k, u, 'Gewindefitting', 'Gewindefitting Muffe verzinkt $z', 'Stk.', typ: 'Muffe');
    b.add(k, u, 'Gewindefitting', 'Gewindefitting Doppelnippel Edelstahl $z', 'Stk.', typ: 'Nippel');
    b.add(k, u, 'Gewindefitting', 'Gewindefitting Doppelnippel verzinkt $z', 'Stk.', typ: 'Nippel');
  }
  for (final x in const ['⅜"', '¼"', '⅛"']) {
    b.add(k, 'Gewindefittings', 'Gewindefitting', 'Gewindefitting Nippel $x', 'Stk.', typ: 'Nippel');
    b.add(k, 'Gewindefittings', 'Gewindefitting', 'Gewindefitting Muffe $x', 'Stk.', typ: 'Muffe');
    b.add(k, 'Gewindefittings', 'Gewindefitting', 'Gewindefitting Bogen 90° IG/IG $x', 'Stk.', typ: 'Bogen');
  }
  for (final dn in const [20, 25, 32, 40, 50, 65, 80, 100, 125, 150]) {
    b.add(k, 'Flansche', 'Flansch', 'Flansch PN16 DN $dn', 'Stk.', typ: 'Flansch');
    b.add(k, 'Flansche', 'Flansch', 'Gegenflansch PN16 DN $dn', 'Stk.', typ: 'Flansch');
    b.add(k, 'Flansche', 'Flansch', 'Vorschweißflansch PN16 DN $dn', 'Stk.', typ: 'Flansch');
    b.add(k, 'Flansche', 'Flansch', 'Blindflansch PN16 DN $dn', 'Stk.', typ: 'Flansch');
    b.add(k, 'Flansche', 'Flansch', 'Flanschdichtung DN $dn', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Flansche', 'Flansch', 'Flanschschraubensatz DN $dn', 'Set', typ: 'Zubehör');
  }
  for (final z in kZollListe) {
    b.add(k, 'Flansche', 'Flansch', 'Gewindeflansch $z', 'Stk.', typ: 'Flansch');
    b.add(k, 'Verschraubungen, Nippel, Stopfen', 'Verschraubung', 'Verschraubung flachdichtend $z', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Verschraubungen, Nippel, Stopfen', 'Verschraubung', 'Verschraubung konisch $z', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Verschraubungen, Nippel, Stopfen', 'Nippel', 'Nippel $z 40 mm', 'Stk.', typ: 'Nippel');
    b.add(k, 'Verschraubungen, Nippel, Stopfen', 'Nippel', 'Nippel $z 60 mm', 'Stk.', typ: 'Nippel');
    b.add(k, 'Verschraubungen, Nippel, Stopfen', 'Stopfen', 'Stopfen Messing $z', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Verschraubungen, Nippel, Stopfen', 'Stopfen', 'Stopfen Stahl $z', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Verschraubungen, Nippel, Stopfen', 'Kappe', 'Kappe Messing $z', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Verschraubungen, Nippel, Stopfen', 'Kappe', 'Kappe Stahl $z', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Rotgussfittings', 'Rotguss', 'Rotguss Winkel 90° $z', 'Stk.', typ: 'Bogen');
    b.add(k, 'Rotgussfittings', 'Rotguss', 'Rotguss T-Stück $z', 'Stk.', typ: 'T-Stück');
    b.add(k, 'Rotgussfittings', 'Rotguss', 'Rotguss Verschraubung $z', 'Stk.', typ: 'Zubehör');
  }
  for (final d in const [16, 20, 25, 32, 40, 50, 63]) {
    b.add(k, 'Kunststofffittings', 'PVC-Fitting', 'PVC-U Winkel 90° Ø$d', 'Stk.', typ: 'Bogen', stichworte: 'pvc');
    b.add(k, 'Kunststofffittings', 'PVC-Fitting', 'PVC-U T-Stück Ø$d', 'Stk.', typ: 'T-Stück', stichworte: 'pvc');
    b.add(k, 'Kunststofffittings', 'PVC-Fitting', 'PVC-U Muffe Ø$d', 'Stk.', typ: 'Muffe', stichworte: 'pvc');
    b.add(k, 'Kunststofffittings', 'PVC-Fitting', 'PVC-U Kappe Ø$d', 'Stk.', typ: 'Zubehör', stichworte: 'pvc');
    b.add(k, 'Kunststofffittings', 'PE-Fitting', 'PE-Klemmverbinder Ø$d', 'Stk.', typ: 'Muffe');
    b.add(k, 'Kunststofffittings', 'PE-Fitting', 'PE-Winkel Ø$d', 'Stk.', typ: 'Bogen');
    b.add(k, 'Kunststofffittings', 'PP-R Fitting', 'PP-R Übergang auf AG Ø$d', 'Stk.', typ: 'Übergang');
    b.add(k, 'Kunststofffittings', 'PP-R Fitting', 'PP-R Übergang auf IG Ø$d', 'Stk.', typ: 'Übergang');
    b.add(k, 'Kunststofffittings', 'PP-R Fitting', 'PP-R Kappe Ø$d', 'Stk.', typ: 'Zubehör');
  }
}

// ───────────────────────── Wassertechnik ─────────────────────────
void _wassertechnik(KatalogBaukasten b) {
  const k = kWassertechnik;
  for (final w in const [600, 800, 1000, 1200]) {
    b.add(k, 'Hauswasserwerke', 'Hauswasserwerk', 'Hauswasserwerk $w W', 'Stk.', typ: 'Pumpe', stichworte: 'pumpe');
    b.add(k, 'Hauswasserwerke', 'Hauswasserautomat', 'Hauswasserautomat $w W', 'Stk.', typ: 'Pumpe', stichworte: 'pumpe');
    b.add(k, 'Pumpen', 'Gartenpumpe', 'Gartenpumpe $w W', 'Stk.', typ: 'Pumpe');
  }
  for (final w in const [400, 550, 750, 1000]) {
    b.add(k, 'Pumpen', 'Tauchpumpe', 'Tauchpumpe Schmutzwasser $w W', 'Stk.', typ: 'Pumpe');
    b.add(k, 'Pumpen', 'Tauchpumpe', 'Tauchpumpe Klarwasser $w W', 'Stk.', typ: 'Pumpe');
  }
  b.liste_(k, 'Pumpen', [
    'Druckpumpe Hauswasser',
    'Brunnenpumpe Tiefbrunnen',
    'Regenwasserpumpe',
    'Saugschlauch 1"',
    'Saugschlauch 1¼"',
    'Fußventil mit Sieb ¾"',
    'Fußventil mit Sieb 1"',
    'Fußventil mit Sieb 1¼"',
    'Pumpenschalter Schwimmer',
    'Trockenlaufschutz',
    'Druckschalter Pumpe',
  ], 'Stk.', typ: 'Pumpe');
  for (final n in const [1, 2, 3]) {
    b.add(k, 'Druckerhöhungsanlagen', 'Druckerhöhungsanlage', 'Druckerhöhungsanlage $n Pumpen', 'Stk.', typ: 'Pumpe', stichworte: 'pumpe');
  }
  for (final l in const [8, 18, 24, 50, 80, 100, 200, 300, 500]) {
    b.add(k, 'Druckerhöhungsanlagen', 'Druckbehälter', 'Membrandruckbehälter $l l', 'Stk.', typ: 'Zubehör', stichworte: 'druckkessel');
  }
  b.liste_(k, 'Druckerhöhungsanlagen', [
    'Druckbehälter-Anschlussset',
    'Druckbehälter-Wandhalter',
    'Druckregler',
    'Steuergerät Druckerhöhung',
    'Frequenzumrichter Pumpe',
  ], 'Stk.', typ: 'Zubehör');
  for (final z in const ['¾"', '1"', '1¼"', '1½"', '2"']) {
    b.add(k, 'Wasserfilter', 'Rückspülfilter', 'Rückspülfilter automatisch $z', 'Stk.', typ: 'Filter');
    b.add(k, 'Wasserfilter', 'Wasserfilter', 'Wasserfilter Feinfilter $z', 'Stk.', typ: 'Filter');
    b.add(k, 'Armaturen Wassertechnik', 'Rückflussverhinderer', 'Rückflussverhinderer Wassertechnik $z', 'Stk.', typ: 'Ventil');
    b.add(k, 'Armaturen Wassertechnik', 'Kugelhahn', 'Kugelhahn Wassertechnik $z', 'Stk.', typ: 'Ventil');
  }
  for (final x in const ['10" Standard', '10" Big Blue', '20" Standard', '20" Big Blue']) {
    b.add(k, 'Wasserfilter', 'Filtergehäuse', 'Filtergehäuse $x', 'Stk.', typ: 'Filter');
  }
  for (final mu in const [1, 5, 20, 50, 90, 100]) {
    b.add(k, 'Wasserfilter', 'Filterkartusche', 'Filterkartusche $mu µm', 'Stk.', typ: 'Filter');
  }
  b.liste_(k, 'Wasserfilter', [
    'Aktivkohlefilter',
    'Filterschlüssel',
    'Filterglas Ersatz',
  ], 'Stk.', typ: 'Filter');
  b.liste_(k, 'Wasseraufbereitung', [
    'Enthärtungsanlage 1 Säule',
    'Enthärtungsanlage 2 Säulen',
    'Regeneriersalz 25 kg',
    'Regeneriersalz Tabletten 25 kg',
    'Kalkschutzgerät',
    'Kalkschutz Dosierung Phosphat',
    'Ionenaustauscher',
    'Umkehrosmoseanlage',
    'UV-Anlage Trinkwasser',
    'Verschneideventil',
    'Vollentsalzung Heizung Kartusche',
  ], 'Stk.', typ: 'Zubehör');
  b.liste_(k, 'Dosieranlagen', [
    'Dosierpumpe Membran',
    'Dosierpumpe Kolben',
    'Dosiergerät Wasserzähler',
    'Dosierbehälter 25 l',
    'Dosierbehälter 60 l',
    'Impfventil ½"',
    'Dosierschlauch Ø4/6 mm',
    'Dosiermittel Phosphat',
    'Dosiermittel Silikat',
    'Dosiersteuerung',
  ], 'Stk.', typ: 'Zubehör');
  for (final q in const ['2,5', '4', '6,3', '10', '16']) {
    b.add(k, 'Armaturen Wassertechnik', 'Wasserzähler', 'Wasserzähler Q3 $q', 'Stk.', typ: 'Zähler');
  }
  for (final dn in const [15, 20, 25, 32, 40, 50, 65, 80, 100]) {
    b.add(k, 'Armaturen Wassertechnik', 'Absperrklappe', 'Absperrklappe DN $dn', 'Stk.', typ: 'Ventil');
    b.add(k, 'Armaturen Wassertechnik', 'Schieber', 'Schieber DN $dn', 'Stk.', typ: 'Ventil');
    b.add(k, 'Armaturen Wassertechnik', 'Flansch-Kugelhahn', 'Flansch-Kugelhahn DN $dn', 'Stk.', typ: 'Ventil');
  }
}

// ───────────────────────── Installation / Montage ─────────────────────────
void _montage(KatalogBaukasten b) {
  const k = kMontage;
  for (final d in const [10, 12, 15, 16, 18, 20, 22, 25, 26, 28, 32, 35, 40, 42, 50, 54, 63, 75, 90, 110, 125, 160]) {
    b.add(k, 'Rohrschellen', 'Rohrschelle', 'Rohrschelle Ø$d mit Gummieinlage', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Rohrschellen', 'Rohrschelle', 'Rohrschelle Ø$d verzinkt', 'Stk.', typ: 'Zubehör');
  }
  for (final d in const [15, 18, 22, 28, 35, 42, 54, 76, 88, 108]) {
    b.add(k, 'Rohrschellen', 'Rohrschelle', 'Rohrschelle Ø$d Edelstahl', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Rohrschellen', 'Rohrschelle', 'Rohrschelle Ø$d mit Schnellverschluss', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Rohrschellen', 'Rohrschelle', 'Rohrschelle Ø$d mit Gewindestange', 'Stk.', typ: 'Zubehör');
  }
  for (final l in const [1, 2, 3, 6]) {
    b.add(k, 'Schienen', 'Montageschiene', 'Montageschiene 41×21 $l m', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Schienen', 'Montageschiene', 'Montageschiene 41×41 $l m', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Schienen', 'Montageschiene', 'Montageschiene 41×62 $l m', 'Stk.', typ: 'Zubehör');
  }
  for (final x in const ['M6', 'M8', 'M10', 'M12']) {
    b.add(k, 'Schienen', 'Gleitmutter', 'Gleitmutter $x', 'Pack', typ: 'Zubehör');
    b.add(k, 'Schienen', 'Federmutter', 'Federmutter $x', 'Pack', typ: 'Zubehör');
    b.add(k, 'Gewindestangen', 'Gewindestange', 'Gewindestange $x 1 m', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Gewindestangen', 'Gewindestange', 'Gewindestange $x 2 m', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Gewindestangen', 'Gewindestange', 'Gewindestange $x 3 m', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Gewindestangen', 'Gewindestange', 'Gewindestange Edelstahl $x 1 m', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Gewindestangen', 'Gewindemuffe', 'Gewindemuffe $x', 'Stk.', typ: 'Zubehör');
    b.add(k, 'Schrauben', 'Sicherungsmutter', 'Sicherungsmutter $x', 'Pack', typ: 'Schraube');
    b.add(k, 'Schrauben', 'Hutmutter', 'Hutmutter $x', 'Pack', typ: 'Schraube');
    b.add(k, 'Dübel', 'Schwerlastanker', 'Schwerlastanker $x verzinkt', 'Pack', typ: 'Dübel');
    b.add(k, 'Dübel', 'Metall-Hohlraumdübel', 'Metall-Hohlraumdübel $x', 'Pack', typ: 'Dübel');
  }
  b.liste_(k, 'Schienen', [
    'Schienenverbinder',
    'Fußplatte Schiene',
    'Winkelverbinder Schiene',
    'Konsolenhalter 300 mm',
    'Konsolenhalter 400 mm',
    'Konsolenhalter 500 mm',
    'Konsolenhalter 600 mm',
    'Wandkonsole Waschtisch',
    'Wandkonsole WC',
    'Deckenanker',
  ], 'Stk.', typ: 'Zubehör');
  b.liste_(k, 'Brandschutz', [
    'Brandschutzmanschette DN 50',
    'Brandschutzmanschette DN 75',
    'Brandschutzmanschette DN 90',
    'Brandschutzmanschette DN 110',
    'Brandschutzmanschette DN 125',
    'Brandschutzmanschette DN 160',
    'Brandschutzkissen',
    'Brandschutzmörtel',
    'Brandschutzschaum',
    'Brandschutzband',
    'Brandschutzkitt',
    'Brandschutzplatte',
    'Rohrabschottung Set',
    'Kabelabschottung Set',
  ], 'Stk.', typ: 'Brandschutz');
  b.liste_(k, 'Schallschutz', [
    'Schallschutzband selbstklebend',
    'Schallschutzband 5 mm',
    'Schallschutzband 10 mm',
    'Schalldämmung Abwasserrohr',
    'Entkopplungsmatte',
    'Entkopplungsstreifen',
    'Randdämmstreifen Schallschutz',
    'Körperschalldämmung Waschtisch',
    'Körperschalldämmung WC',
    'Körperschalldämmung Dusche',
    'Gummilager',
    'Schwingungsdämpfer Pumpe',
    'Schwingungsdämpfer Rohr',
  ], 'Stk.', typ: 'Schallschutz');
  b.liste_(k, 'Montagezubehör', [
    'Montageband gelocht 12 mm',
    'Montageband gelocht 17 mm',
    'Montageklammer',
    'Montagewinkel',
    'Montagekleber Kartusche',
    'Montageplatte Holz',
    'Montagerahmen',
    'Wandhalter Ausdehnungsgefäß',
    'Wandhalter Speicher',
    'Kabelschelle',
    'Befestigungsband',
    'Rohrbügel',
    'Distanzhülse',
    'Abstandshalter Wand',
    'Tellerkopfschraube',
    'Wandwinkel verzinkt',
  ], 'Pack', typ: 'Zubehör');
  for (final x in const ['4×30', '4×35', '4×40', '4,5×60', '5×30', '5×40', '5×70', '5×90', '6×60', '6×70', '6×90', '6×120', '6×140', '8×80']) {
    b.add(k, 'Schrauben', 'Holzschraube', 'Holzschraube Senkkopf $x', 'Pack', typ: 'Schraube');
  }
  for (final x in const ['3,5×25', '3,5×35', '3,5×45', '3,9×25', '3,9×35', '3,9×45']) {
    b.add(k, 'Schrauben', 'Schnellbauschraube', 'Schnellbauschraube $x', 'Pack', typ: 'Schraube', stichworte: 'trockenbau');
  }
  for (final x in const ['M4×20', 'M5×20', 'M5×30', 'M6×30', 'M6×40', 'M8×20', 'M8×30', 'M8×50', 'M10×30', 'M10×50', 'M10×80']) {
    b.add(k, 'Schrauben', 'Maschinenschraube', 'Maschinenschraube $x', 'Pack', typ: 'Schraube');
    b.add(k, 'Schrauben', 'Sechskantschraube', 'Sechskantschraube verzinkt $x', 'Pack', typ: 'Schraube');
  }
  for (final x in const ['M4', 'M5', 'M12']) {
    b.add(k, 'Schrauben', 'Unterlegscheibe', 'Unterlegscheibe $x', 'Pack', typ: 'Schraube');
    b.add(k, 'Schrauben', 'Mutter', 'Mutter $x', 'Pack', typ: 'Schraube');
  }
  for (final mm in const [5, 12, 16]) {
    b.add(k, 'Dübel', 'Dübel', 'Nylondübel $mm mm', 'Pack', typ: 'Dübel');
  }
  for (final mm in const [6, 8, 10, 14]) {
    b.add(k, 'Dübel', 'Dübel', 'Nylondübel $mm mm', 'Pack', typ: 'Dübel');
    b.add(k, 'Dübel', 'Dübel', 'Rahmendübel $mm mm', 'Pack', typ: 'Dübel');
  }
  b.liste_(k, 'Dübel', [
    'Kippdübel M4',
    'Kippdübel M5',
    'Federklappdübel M5',
    'Federklappdübel M6',
    'Porenbetondübel',
    'Fassadendübel',
    'Betonschraube 6×60',
    'Betonschraube 6×80',
    'Betonschraube 7,5×100',
    'Betonschraube 7,5×140',
    'Mörtelkartusche Verbundanker',
    'Injektionsmörtel Beton',
    'Injektionsmörtel Mauerwerk',
    'Siebhülse',
  ], 'Pack', typ: 'Dübel');
  for (final z in kZollListe) {
    b.add(k, 'Dichtungen', 'Flachdichtung', 'Flachdichtung Fiber $z', 'Pack', typ: 'Dichtung');
    b.add(k, 'Dichtungen', 'Flachdichtung', 'Flachdichtung EPDM $z', 'Pack', typ: 'Dichtung');
    b.add(k, 'Dichtungen', 'Flachdichtung', 'Flachdichtung PTFE $z', 'Pack', typ: 'Dichtung');
    b.add(k, 'Dichtungen', 'Flachdichtung', 'Dichtring Kupfer $z', 'Pack', typ: 'Dichtung');
  }
  b.liste_(k, 'Dichtungen', [
    'O-Ring EPDM Sortiment',
    'O-Ring FKM Sortiment',
    'Pressfitting O-Ring Ø15',
    'Pressfitting O-Ring Ø22',
    'Pressfitting O-Ring Ø28',
    'Pressfitting O-Ring Ø35',
    'Pressfitting O-Ring Ø42',
    'Pressfitting O-Ring Ø54',
    'Pumpendichtung Set',
    'Dichtungssatz Armatur',
    'Dichtungssatz Thermostat',
    'Dichtung Spülkasten Set',
    'Dichtung WC-Anschluss',
    'Dichtung Siphon Set',
    'Dichtung Wasserzähler',
    'Dichtung Heizkörper Set',
    'Rohrdichtung Kernbohrung',
    'Stopfbuchspackung',
  ], 'Pack', typ: 'Dichtung');
}

// ───────────────────────── Isolierung ─────────────────────────
void _isolierung(KatalogBaukasten b) {
  const k = kIsolierung;
  for (final d in const [6, 8, 10, 12, 15, 18, 22, 28, 35, 42, 54, 60, 76, 88, 108, 133]) {
    b.add(k, 'Rohrisolierung', 'Rohrisolierung PE', 'Rohrisolierung PE Ø$d 9 mm', 'm', typ: 'Isolierung');
    b.add(k, 'Rohrisolierung', 'Rohrisolierung PE', 'Rohrisolierung PE Ø$d 13 mm', 'm', typ: 'Isolierung');
    b.add(k, 'Rohrisolierung', 'Rohrisolierung PE', 'Rohrisolierung PE Ø$d 20 mm', 'm', typ: 'Isolierung');
    b.add(k, 'Rohrisolierung', 'Rohrisolierung PE', 'Rohrisolierung PE Ø$d 30 mm', 'm', typ: 'Isolierung');
  }
  for (final d in const [15, 18, 22, 28, 35, 42, 54, 60, 76, 88, 108]) {
    b.add(k, 'Heizungsisolierung', 'Heizungsisolierung', 'Heizungsisolierung Ø$d 20 mm', 'm', typ: 'Isolierung', stichworte: 'heizung');
    b.add(k, 'Heizungsisolierung', 'Heizungsisolierung', 'Heizungsisolierung Ø$d 30 mm', 'm', typ: 'Isolierung', stichworte: 'heizung');
    b.add(k, 'Heizungsisolierung', 'Heizungsisolierung', 'Heizungsisolierung Ø$d 40 mm', 'm', typ: 'Isolierung', stichworte: 'heizung');
    b.add(k, 'Sanitärisolierung', 'Sanitärisolierung', 'Sanitärisolierung Ø$d 9 mm', 'm', typ: 'Isolierung', stichworte: 'sanitär');
    b.add(k, 'Sanitärisolierung', 'Sanitärisolierung', 'Sanitärisolierung Ø$d 13 mm', 'm', typ: 'Isolierung', stichworte: 'sanitär');
    b.add(k, 'Kälteisolierung', 'Kälteisolierung', 'Kälteisolierung Kautschuk Ø$d 13 mm', 'm', typ: 'Isolierung', stichworte: 'klima');
    b.add(k, 'Kälteisolierung', 'Kälteisolierung', 'Kälteisolierung Kautschuk Ø$d 19 mm', 'm', typ: 'Isolierung', stichworte: 'klima');
    b.add(k, 'Kälteisolierung', 'Kälteisolierung', 'Kälteisolierung Kautschuk Ø$d 25 mm', 'm', typ: 'Isolierung', stichworte: 'klima');
    b.add(k, 'Brandschutzisolierung', 'Brandschutzisolierung', 'Brandschutz-Rohrschale Mineralwolle Ø$d', 'm', typ: 'Isolierung', stichworte: 'brandschutz isolierung');
  }
  for (final z in kZollListe) {
    b.add(k, 'Rohrisolierung', 'Rohrisolierung PE', 'Rohrisolierung PE $z', 'm', typ: 'Isolierung');
  }
  for (final mm in const [20, 30, 40, 50, 60, 80, 100]) {
    b.add(k, 'Dämmplatten', 'Dämmplatte', 'Dämmplatte Mineralwolle $mm mm', 'm²', typ: 'Platte', stichworte: 'dämmung');
    b.add(k, 'Dämmplatten', 'Dämmplatte', 'Dämmplatte XPS $mm mm', 'm²', typ: 'Platte', stichworte: 'dämmung');
    b.add(k, 'Dämmplatten', 'Dämmplatte', 'Dämmplatte PIR $mm mm', 'm²', typ: 'Platte', stichworte: 'dämmung');
    b.add(k, 'Dämmplatten', 'Dämmplatte', 'Dämmplatte EPS $mm mm', 'm²', typ: 'Platte', stichworte: 'dämmung');
  }
  for (final mm in const [10, 13, 19, 25, 32]) {
    b.add(k, 'Dämmplatten', 'Kautschukplatte', 'Kautschukplatte selbstklebend $mm mm', 'm²', typ: 'Platte', stichworte: 'dämmung');
  }
  b.liste_(k, 'Klebeband & Zubehör', [
    'Isolierband PVC grau',
    'Isolierband PVC weiß',
    'Isolierband PVC schwarz',
    'Alu-Klebeband 50 mm',
    'Alu-Klebeband 75 mm',
    'Kautschuk-Klebeband',
    'Isolierkleber 1 l',
    'Isolierkleber Kartusche',
    'Isolierung Bogen Ø22',
    'Isolierung Bogen Ø28',
    'Isolierung Pumpe',
    'Isolierung Speicher Mantel',
    'Ummantelung Alu',
    'Ummantelung PVC',
    'Ummantelung Edelstahl',
    'Verschlussclip Isolierung',
    'Mineralwolle Matte',
    'Mineralwolle Lamellenmatte',
    'Glaswolle Matte',
  ], 'Stk.', typ: 'Zubehör');
}

// ───────────────────────── Werkzeug ─────────────────────────
void _werkzeug(KatalogBaukasten b) {
  const k = kWerkzeug;
  b.liste_(k, 'Pressmaschinen & Pressbacken', [
    'Pressmaschine Akku',
    'Pressmaschine Netz',
    'Pressmaschine Kompakt',
    'Pressbacke Ø12',
    'Pressbacke Ø15',
    'Pressbacke Ø18',
    'Pressbacke Ø22',
    'Pressbacke Ø28',
    'Pressbacke Ø35',
    'Pressbacke Ø16 (MV)',
    'Pressbacke Ø20 (MV)',
    'Pressbacke Ø26 (MV)',
    'Pressbacke Ø32 (MV)',
    'Pressbacke U-Kontur',
    'Pressbacke V-Kontur',
    'Pressring Ø42',
    'Pressring Ø54',
    'Pressring Ø64',
    'Pressring Ø76',
    'Pressring Ø88',
    'Pressring Ø108',
    'Pressringadapter',
    'Ladegerät Pressmaschine',
  ], 'Stk.', typ: 'Werkzeug', stichworte: 'presswerkzeug');
  b.liste_(k, 'Rohrbearbeitung', [
    'Rohrschneider 3–35 mm',
    'Rohrschneider 6–67 mm',
    'Rohrschneider 3–16 mm',
    'Rohrschneider Edelstahl',
    'Rohrschneider Kunststoff',
    'Rohrschneiderrad Kupfer',
    'Rohrschneiderrad Edelstahl',
    'Kunststoffrohrschere',
    'Entgrater innen/außen',
    'Entgrater Kupfer',
    'Rohrfeile',
    'Rohrbiegefeder 15',
    'Rohrbiegefeder 18',
    'Rohrbiegefeder 22',
    'Rohrbiegegerät Handhebel 15–22',
    'Rohrbiegegerät Handhebel 12–28',
    'Rohrbiegegerät hydraulisch',
    'Rohraufweiter Kupfer',
    'Rohrkalibrierer',
    'Bördelgerät Klima',
    'Gewindeschneidkluppe Set',
    'Gewindeschneidmaschine',
    'Gewindebohrer M6',
    'Gewindebohrer M8',
    'Gewindebohrer M10',
    'Rohrzange 1"',
    'Rohrzange 1½"',
    'Rohrzange 2"',
    'Kettenrohrzange',
    'Eckrohrzange',
    'Wasserpumpenzange 250 mm',
    'Wasserpumpenzange 300 mm',
  ], 'Stk.', typ: 'Werkzeug');
  b.liste_(k, 'Handwerkzeug', [
    'Schraubenschlüssel-Satz',
    'Ringschlüssel-Satz',
    'Steckschlüssel-Satz',
    'Maulschlüssel 10×13',
    'Maulschlüssel 17×19',
    'Maulschlüssel 22×24',
    'Rollgabelschlüssel 250 mm',
    'Rollgabelschlüssel 300 mm',
    'Rollgabelschlüssel 375 mm',
    'Inbus-Satz',
    'Torx-Satz',
    'Schraubendreher-Satz',
    'Schraubendreher isoliert',
    'Kombizange',
    'Seitenschneider',
    'Spitzzange',
    'Abisolierzange',
    'Crimpzange',
    'Hammer 300 g',
    'Hammer 500 g',
    'Fäustel 1 kg',
    'Meißel',
    'Cuttermesser',
    'Bügelsäge',
    'Feilen-Satz',
    'Wasserwaage 60 cm',
    'Wasserwaage 100 cm',
    'Zollstock 2 m',
    'Maßband 5 m',
    'Maßband 8 m',
    'Lötlampe Kartusche',
    'Lötbrenner Propan',
    'Lötmatte',
    'Lötschutz Wand',
    'Heißluftgebläse',
    'Polyfusionsschweißgerät PP-R',
    'Schweißeinsatz Ø20',
    'Schweißeinsatz Ø25',
    'Schweißeinsatz Ø32',
    'Schweißeinsatz Ø40',
    'Schweißeinsatz Ø50',
    'Schweißeinsatz Ø63',
    'Spachtel',
  ], 'Stk.', typ: 'Werkzeug');
  b.liste_(k, 'Bohr- & Akkugeräte', [
    'Akkuschrauber 18 V',
    'Akku-Bohrschrauber 18 V',
    'Schlagbohrmaschine',
    'Bohrhammer SDS-plus',
    'Bohrhammer SDS-max',
    'Winkelschleifer 125 mm',
    'Winkelschleifer 230 mm',
    'Akku-Winkelschleifer',
    'Akku-Säbelsäge',
    'Akku-Stichsäge',
    'Akku 18 V 2 Ah',
    'Akku 18 V 4 Ah',
    'Akku 18 V 5 Ah',
    'Akku 18 V 8 Ah',
    'Ladegerät 18 V',
    'Kernbohrmaschine',
    'Kernbohrkrone Ø68',
    'Kernbohrkrone Ø82',
    'Kernbohrkrone Ø102',
    'Kernbohrkrone Ø125',
    'Kernbohrkrone Ø152',
    'Kernbohrkrone Ø202',
    'Mauernutfräse',
    'Staubsauger Baustelle',
    'Rohrreinigungsmaschine Elektro',
    'Rohrreinigungsspirale 7,5 m',
    'Rohrreinigungsspirale 15 m',
    'Rohrreinigungsspirale 25 m',
    'Saugglocke',
    'Rohrkamera Inspektion',
  ], 'Stk.', typ: 'Werkzeug');
  b.liste_(k, 'Prüfgeräte', [
    'Druckprüfpumpe Hand',
    'Druckprüfpumpe Elektro',
    'Druckprüfgerät digital',
    'Prüfstopfen Ø15',
    'Prüfstopfen Ø18',
    'Prüfstopfen Ø22',
    'Prüfstopfen Ø28',
    'Prüfstopfen Ø35',
    'Prüfstopfen Ø42',
    'Prüfstopfen Ø54',
    'Prüfstopfen ½"',
    'Prüfstopfen ¾"',
    'Prüfstopfen 1"',
    'Prüfstopfen Kanal DN 100',
    'Prüfstopfen Kanal DN 125',
    'Prüfstopfen Kanal DN 150',
    'Prüfblase DN 100',
    'Prüfblase DN 150',
    'Prüfblase DN 200',
    'Gaslecksucher',
    'Abgasmessgerät',
    'Multimeter',
    'Spannungsprüfer',
    'Infrarot-Thermometer',
    'Wärmebildkamera',
    'Laser-Entfernungsmesser',
    'Kreuzlinienlaser',
    'Vakuumpumpe 2-stufig',
    'Vakuummeter',
    'Monteurhilfe 4-Wege',
    'Waage Kältemittel',
  ], 'Stk.', typ: 'Werkzeug');
  b.liste_(k, 'Werkzeugkoffer & Schutz', [
    'Werkzeugkoffer leer',
    'Werkzeugkoffer bestückt',
    'Werkzeugtasche',
    'Werkzeugrucksack',
    'Systemkoffer Klein',
    'Systemkoffer Mittel',
    'Systemkoffer Groß',
    'Schutzbrille',
    'Gehörschutz',
    'Atemschutzmaske FFP2',
    'Atemschutzmaske FFP3',
    'Knieschoner',
    'Arbeitsschuhe S3',
    'Arbeitsleuchte LED',
    'Stirnlampe',
    'Verlängerungskabel 10 m',
    'Kabeltrommel 25 m',
    'Baustellenverteiler',
    'Leiter 3 m',
    'Leiter 5 m',
  ], 'Stk.', typ: 'Zubehör');
}

// ───────────────────────── Verbrauchsmaterial ─────────────────────────
void _verbrauch(KatalogBaukasten b) {
  const k = kVerbrauch;
  b.liste_(k, 'Dichtmittel & Kleber', [
    'Hanf Zopf 100 g',
    'Hanf Zopf 200 g',
    'Hanf Zopf 500 g',
    'Gewindedichtpaste 250 g',
    'Gewindedichtpaste Trinkwasser',
    'Gewindedichtpaste Gas',
    'PTFE-Band 12 mm',
    'PTFE-Band 19 mm',
    'Gewindedichtfaden 160 m',
    'Gewindedichtmittel anaerob',
    'Silikon Sanitär weiß',
    'Silikon Sanitär transparent',
    'Silikon Sanitär grau',
    'Silikon neutral',
    'Silikon Hochtemperatur',
    'Acryl überstreichbar',
    'Acryl grau',
    'Dichtband selbstklebend',
    'Montagekleber transparent',
    'Montagekleber Polymer',
    'Kleber PVC',
    'Kleber PE',
    'Reparaturband',
    'Kupferpaste',
    'Montagepaste',
    'Gleitmittel Kunststoffrohr',
    'Gleitmittel Gummidichtung',
  ], 'Stk.', typ: 'Verbrauch');
  b.liste_(k, 'Löten, Bohren, Reinigen', [
    'Lötzinn bleifrei 2 mm',
    'Lötzinn bleifrei 3 mm',
    'Hartlot Stab',
    'Silberlot Stab',
    'Flussmittel Weichlot',
    'Flussmittel Hartlot',
    'Lötpaste Weichlot',
    'Propangas Kartusche 400 g',
    'Propangas Kartusche 600 g',
    'Propangasflasche 5 kg',
    'Mapp-Gas Kartusche',
    'Trennscheibe Metall 115 mm',
    'Trennscheibe Metall 230 mm',
    'Trennscheibe Edelstahl 125 mm',
    'Trennscheibe Stein 125 mm',
    'Schleifpapier 80',
    'Schleifpapier 120',
    'Schleifpapier 240',
    'Schleifvlies grün',
    'Schleifvlies rot',
    'Fittingbürste Ø15',
    'Fittingbürste Ø22',
    'Fittingbürste Ø28',
    'Bohrer Metall 3 mm',
    'Bohrer Metall 4 mm',
    'Bohrer Metall 5 mm',
    'Bohrer Metall 6 mm',
    'Bohrer Metall 8 mm',
    'Bohrer Metall 10 mm',
    'Bohrer Stein 5 mm',
    'Bohrer Stein 6 mm',
    'Bohrer Stein 8 mm',
    'Bohrer Stein 10 mm',
    'Bohrer Stein 12 mm',
    'Bohrer SDS-plus 6×160',
    'Bohrer SDS-plus 8×160',
    'Bohrer SDS-plus 10×160',
    'Bohrer SDS-plus 12×200',
    'Bohrer SDS-plus 14×200',
    'Bohrer SDS-plus 16×200',
    'Stufenbohrer 4–20 mm',
    'Lochsäge 35 mm',
    'Lochsäge 68 mm',
    'Sägeblatt Säbelsäge Metall',
    'Sägeblatt Bügelsäge',
    'Rostlöser Spray',
    'Kriechöl',
    'Armaturenfett',
    'Silikonfett Sanitär',
    'Montagefett',
    'Rohrreiniger Granulat',
    'Rohrreiniger Spirale',
    'Entkalker',
    'Heizungsreiniger Spülmittel',
    'Universalreiniger',
    'Putztuch Rolle',
    'Putzlappen',
    'Handreiniger',
    'Handschuhe Nitril',
    'Handschuhe Einweg',
    'Handschuhe Montage',
    'Kabelbinder 100 mm schwarz',
    'Kabelbinder 200 mm schwarz',
    'Kabelbinder 300 mm schwarz',
    'Kabelbinder 400 mm schwarz',
    'Kabelbinder 200 mm weiß',
    'Gewebeband Silber',
    'Klebeband doppelseitig',
    'Malerkrepp 50 mm',
    'Abdeckfolie 4×5 m',
    'Abdeckvlies',
    'Bauschaum 1K',
    'Bauschaum 2K',
    'Bauschaum Brandschutz',
    'Müllsack 120 l',
    'Bauschuttsack',
  ], 'Stk.', typ: 'Verbrauch');
}

// ───────────────────────── Regenerative Energien ─────────────────────────
void _regenerativ(KatalogBaukasten b) {
  const k = kRegenerativ;
  for (final m in const ['2,0', '2,5', '4,0', '6,0', '8,0', '10,0']) {
    b.add(k, 'Solarthermie', 'Flachkollektor', 'Flachkollektor $m m²', 'Stk.', typ: 'Kollektor', stichworte: 'solar');
  }
  for (final n in const [10, 20, 30]) {
    b.add(k, 'Solarthermie', 'Röhrenkollektor', 'Röhrenkollektor $n Röhren', 'Stk.', typ: 'Kollektor', stichworte: 'solar');
  }
  for (final dn in const [16, 20, 25]) {
    b.add(k, 'Solarthermie', 'Solarrohr', 'Solar-Wellrohr DN $dn', 'm', typ: 'Rohr', stichworte: 'solar edelstahl');
    b.add(k, 'Solarthermie', 'Solarrohr', 'Solar-Wellrohr DN $dn isoliert', 'm', typ: 'Rohr', stichworte: 'solar edelstahl');
    b.add(k, 'Solarthermie', 'Solarrohr', 'Solar-Doppelrohr DN $dn', 'm', typ: 'Rohr', stichworte: 'solar');
    b.add(k, 'Solarthermie', 'Solarrohr', 'Solar-Verschraubung DN $dn', 'Stk.', typ: 'Zubehör', stichworte: 'solar');
  }
  b.liste_(k, 'Solarthermie', [
    'Solarstation 1-strängig',
    'Solarstation 2-strängig Pumpe',
    'Solarregler',
    'Solarpumpe',
    'Solarflüssigkeit 10 l',
    'Solarflüssigkeit 20 l',
    'Solarflüssigkeit 25 l',
    'Solar-Ausdehnungsgefäß 18 l',
    'Solar-Ausdehnungsgefäß 25 l',
    'Solar-Ausdehnungsgefäß 35 l',
    'Solar-Vorschaltgefäß',
    'Solar-Sicherheitsventil 6 bar',
    'Solar-Entlüfter',
    'Solar-Kollektorfühler',
    'Solar-Speicherfühler',
    'Solar-Dachhaken',
    'Solar-Montagegestell Flachdach',
    'Solar-Montagegestell Aufdach',
    'Solar-Anschlussset',
    'Solar-Wärmemengenzähler',
    'Solarspeicher 300 l',
    'Solarspeicher 400 l',
    'Solarspeicher 500 l',
    'Solarspeicher 800 l',
    'Solarspeicher 1000 l',
  ], 'Stk.', typ: 'Solar', stichworte: 'solar');
  for (final l in const [200, 300, 500, 800, 1000, 1500, 2000]) {
    b.add(k, 'Speicher', 'Heizungs-Pufferspeicher', 'Heizungs-Pufferspeicher $l l', 'Stk.', typ: 'Speicher', stichworte: 'puffer');
  }
  b.liste_(k, 'Hydraulik & Regelung', [
    'Wärmepumpen-Pufferspeicher-Anschlussset',
    'Wärmepumpen-Regler',
    'Wärmepumpen-Raumbediengerät',
    'Wärmepumpen-Wärmemengenzähler',
    'Wärmepumpen-Stromzähler',
    'Wärmepumpen-Sicherheitsgruppe',
    'Wärmepumpen-Schmutzfänger',
    'PV-Heizstab',
    'PV-Überschussregler',
    'Smart-Grid-Steuerung',
    'Hybrid-Heizungsregler',
  ], 'Stk.', typ: 'Regelung');
  b.liste_(k, 'Montagekomponenten', [
    'Wärmepumpe Außeneinheit Konsole',
    'Wärmepumpe Außeneinheit Gummifüße',
    'Wärmepumpe Kondensatheizband',
    'Erdwärmesonden-Anschlussset',
    'Erdkollektor-Verteiler',
    'Sole-Verteiler',
    'Sole-Pumpe',
    'Solekonzentrat 25 l',
    'Sole-Ausdehnungsgefäß',
    'Sole-Füllgruppe',
    'Erdverlegtes Doppelrohr DN 20',
    'Erdverlegtes Doppelrohr DN 25',
    'Erdverlegtes Doppelrohr DN 32',
    'Erdverlegtes Einzelrohr DN 25',
    'Erdverlegtes Einzelrohr DN 32',
    'Erdverlegtes Einzelrohr DN 40',
    'Erdverlegtes Einzelrohr DN 50',
    'Hauseinführung',
  ], 'Stk.', typ: 'Zubehör');
}

// ───────────────────────── Messen / Prüfen ─────────────────────────
void _messen(KatalogBaukasten b) {
  const k = kMessen;
  for (final bar in const ['0–1,6', '0–2,5', '0–4', '0–6', '0–10', '0–16']) {
    b.add(k, 'Manometer', 'Manometer', 'Manometer $bar bar ¼"', 'Stk.', typ: 'Messgerät');
    b.add(k, 'Manometer', 'Manometer', 'Manometer $bar bar ½"', 'Stk.', typ: 'Messgerät');
  }
  for (final x in const ['0–60 °C', '0–100 °C', '0–120 °C', '0–160 °C']) {
    b.add(k, 'Thermometer', 'Thermometer', 'Thermometer $x', 'Stk.', typ: 'Messgerät');
    b.add(k, 'Thermometer', 'Thermometer', 'Tauchhülsen-Thermometer $x', 'Stk.', typ: 'Messgerät');
  }
  b.liste_(k, 'Manometer', [
    'Thermomanometer ¼"',
    'Thermomanometer ½"',
    'Manometer-Absperrhahn',
    'Manometer Digital',
    'Differenzdruckmanometer Pumpe',
  ], 'Stk.', typ: 'Messgerät');
  b.liste_(k, 'Druckprüfung', [
    'Druckprüfset Wasser',
    'Druckprüfset Gas',
    'Prüfnippel ½"',
    'Prüfmanometer 0–6 bar',
    'Prüfmanometer 0–10 bar',
    'Prüfmanometer 0–16 bar',
    'Prüfmanometer 0–25 bar',
    'Hochdruck-Prüfschlauch',
  ], 'Stk.', typ: 'Messgerät');
  b.liste_(k, 'Leck- & Wasseranalyse', [
    'Lecksuchgerät Wasser',
    'Lecksuchspray 400 ml',
    'Lecksuchgel',
    'Leckage-Sensor Wasser',
    'Wasseralarm',
    'Ortungsgerät Rohr',
    'Feuchtemessgerät',
    'Wasserhärte-Test',
    'pH-Messgerät',
    'pH-Teststreifen',
    'Leitwert-Messgerät',
    'Legionellen-Probenahme-Set',
    'Heizungswasser-Prüfset',
  ], 'Stk.', typ: 'Messgerät');
  b.liste_(k, 'Temperaturfühler', [
    'Temperaturfühler Anlegefühler',
    'Temperaturfühler Tauchfühler',
    'Temperaturfühler Außenfühler',
    'Temperaturfühler Raumfühler',
    'Temperaturfühler NTC',
    'Temperaturfühler PT100',
    'Temperaturfühler PT1000',
    'Temperaturfühler Kabel 2 m',
    'Temperaturfühler Kabel 5 m',
    'Temperaturfühler Kabel 10 m',
    'Temperaturfühler Speicher',
    'Temperaturfühler Solar',
    'Temperaturfühler Tauchhülse Messing',
    'Temperaturfühler Tauchhülse Edelstahl',
    'Kontaktthermometer',
    'Digitalthermometer Einstich',
  ], 'Stk.', typ: 'Messgerät');
  b.liste_(k, 'Messgeräte', [
    'Durchflussmesser Wasser',
    'Wärmemengenzähler DN 15',
    'Wärmemengenzähler DN 20',
    'Wärmemengenzähler DN 25',
    'Kältemengenzähler',
    'Wasserzähler Kaltwasser',
    'Wasserzähler Warmwasser',
    'Gaszähler',
    'Betriebsstundenzähler',
    'Rauchgasanalysegerät',
    'Zugmessgerät',
    'Luftgeschwindigkeitsmesser',
    'Datenlogger Temperatur',
  ], 'Stk.', typ: 'Messgerät');
}

// ─────────────── Elektro / Anschluss für SHK ───────────────
void _elektro(KatalogBaukasten b) {
  const k = kElektro;
  for (final q in const ['3×1,5', '3×2,5', '5×1,5', '5×2,5', '5×4', '5×6', '5×10', '5×16']) {
    b.add(k, 'Kabel & Leitungen', 'Erdkabel', 'Erdkabel NYY-J $q', 'm', typ: 'Kabel', stichworte: 'kabel');
  }
  for (final q in const ['3×0,75', '3×1', '3×1,5', '3×2,5']) {
    b.add(k, 'Kabel & Leitungen', 'Schlauchleitung', 'Schlauchleitung H05VV-F $q', 'm', typ: 'Kabel', stichworte: 'kabel leitung');
    b.add(k, 'Kabel & Leitungen', 'Gummischlauchleitung', 'Gummischlauchleitung H07RN-F $q', 'm', typ: 'Kabel', stichworte: 'kabel leitung');
  }
  for (final q in const ['2×0,75', '2×1,5', '4×0,75', '5×0,75']) {
    b.add(k, 'Kabel & Leitungen', 'Steuerleitung', 'Steuerleitung $q', 'm', typ: 'Kabel', stichworte: 'kabel leitung');
  }
  for (final q in const ['2×0,5', '2×0,75', '4×0,5']) {
    b.add(k, 'Kabel & Leitungen', 'Fühlerleitung', 'Fühlerleitung $q', 'm', typ: 'Kabel', stichworte: 'kabel leitung sensor');
  }
  b.liste_(k, 'Kabel & Leitungen', [
    'Aderendhülsen 0,75',
    'Aderendhülsen 1,5',
    'Aderendhülsen 2,5',
    'Kabelschuh Ring',
    'Kabelschuh Gabel',
    'Schrumpfschlauch Set',
    'Kabelkanal 15×15',
    'Kabelkanal 40×60',
    'Kabelrohr flexibel M20',
    'Kabelrohr flexibel M25',
    'Kabelverschraubung M20',
    'Kabelverschraubung M25',
    'Zugentlastung',
  ], 'Pack', typ: 'Zubehör', stichworte: 'kabel');
  b.liste_(k, 'Stecker & Steckdosen', [
    'Schuko-Stecker',
    'Schuko-Kupplung',
    'CEE-Stecker 16 A',
    'CEE-Kupplung 16 A',
    'CEE-Stecker 32 A',
    'Steckdose Aufputz',
    'Steckdose Unterputz',
    'Steckdose Feuchtraum',
    'Geräteanschlussdose',
    'Herdanschlussdose',
    'Gerätestecker 3-polig',
    'Gerätestecker 5-polig',
    'Wago-Klemme 221-412',
    'Wago-Klemme 221-413',
    'Wago-Klemme 221-415',
    'Wago-Klemme 221-612',
    'Wago-Klemme 221-613',
    'Wago-Klemme 221-615',
  ], 'Stk.', typ: 'Zubehör');
  b.liste_(k, 'Sicherungen & Schalter', [
    'Sicherungsautomat B10',
    'Sicherungsautomat B20',
    'Sicherungsautomat B25',
    'Sicherungsautomat C16',
    'Sicherungsautomat 3-polig B16',
    'Sicherungsautomat 3-polig B25',
    'FI-Schalter 25 A',
    'FI-Schalter 63 A',
    'Schmelzsicherung NH',
    'Feinsicherung 5×20',
    'Hauptschalter 3-polig 63 A',
    'Heizungsnotschalter',
    'Wartungsschalter',
    'Ausschalter Aufputz',
    'Ausschalter Unterputz',
    'Wechselschalter',
    'Taster Aufputz',
    'Zeitschaltuhr Digital',
    'Relais 230 V',
    'Relais 24 V',
    'Schütz 230 V',
    'Hutschienen-Netzteil 24 V',
    'Transformator 230/24 V',
    'Transformator 230/12 V',
  ], 'Stk.', typ: 'Zubehör');
  b.liste_(k, 'Klemmen & Steuerungen', [
    'Hutschienenklemme 2,5 mm²',
    'Hutschienenklemme 4 mm²',
    'Hutschienenklemme 6 mm²',
    'Hutschiene 35 mm 1 m',
    'Klemmleiste 12-polig',
    'Verteilerdose Aufputz',
    'Verteilerdose Unterputz',
    'Abzweigkasten IP65',
    'Steuerung Heizungspumpe',
    'Steuerung Zirkulation',
    'Steuerung Lüftung',
    'Thermostat Heizungsregelung 230 V',
    'Thermostat Kessel',
    'Thermostat Speicher',
    'Raumregler 230 V',
    'Raumregler 24 V',
    'Raumregler Funk',
    'Funkempfänger',
    'Sensor Außentemperatur',
    'Sensor Raumtemperatur',
    'Sensor Feuchte',
    'Sensor Leckage',
    'Sensor Druck',
    'Sensor Durchfluss',
  ], 'Stk.', typ: 'Steuerung');
}
