// Vorlagen für typische Arbeiten. Orientierende Beispiele, KEINE vollständigen
// oder technisch garantierten Listen. Es gibt keine Mengen und keine Preise:
// der Nutzer trägt jede Menge selbst ein. Alle Namen sind exakte Namen aus dem
// WerkCalc-Katalog (per Test geprüft). Eine Vorlage erzeugt immer eine NEUE
// Baustelle und ändert keine bestehenden Baustellen oder Materiallisten.

import 'materialliste.dart';
import 'materialliste_store.dart';

enum VorlagenStatus {
  standard('Standard'),
  optional('Optional'),
  situativ('Situativ');

  const VorlagenStatus(this.text);
  final String text;
}

/// Ein Eintrag: der Nutzer wählt genau eine der [varianten] (exakte Katalognamen)
/// und trägt die Menge ein. [heizkoerper]: Auswahl nach Typ, Höhe und Länge.
class VorlagenPosten {
  const VorlagenPosten(
    this.label,
    this.varianten,
    this.status, {
    this.hinweis,
    this.heizkoerper = false,
  });

  final String label;
  final List<String> varianten;
  final VorlagenStatus status;
  final String? hinweis;
  final bool heizkoerper;
}

/// Alternative innerhalb einer Zone (z. B. Dusche ODER Wanne).
class VorlagenModus {
  const VorlagenModus(this.label, this.posten);

  final String label;
  final List<VorlagenPosten> posten;
}

class VorlagenZone {
  const VorlagenZone(
    this.name, {
    this.posten = const [],
    this.modi = const [],
    this.modusFrage,
    this.nichtVerfuegbar = const [],
    this.hinweis,
  });

  final String name;
  final List<VorlagenPosten> posten;

  /// Alternativen: der Nutzer wählt eine (oder keine). Ohne Wahl wird nichts angezeigt.
  final List<VorlagenModus> modi;
  final String? modusFrage;

  /// Im Katalog nicht vorhanden – wird nur angezeigt, nie ersetzt.
  final List<String> nichtVerfuegbar;
  final String? hinweis;
}

class VorlagenParameter {
  const VorlagenParameter(this.schluessel, this.label, this.optionen);

  final String schluessel;
  final String label;

  /// Optionen können von bereits gewählten Parametern abhängen.
  final List<String> Function(Map<String, String> gewaehlt) optionen;
}

class Vorlage {
  const Vorlage(
    this.name,
    this.beschreibung, {
    this.zonen = const [],
    this.parameter = const [],
    this.zonenFuer,
    this.hinweis,
  });

  final String name;
  final String beschreibung;
  final List<VorlagenZone> zonen;
  final List<VorlagenParameter> parameter;
  final List<VorlagenZone> Function(Map<String, String> p)? zonenFuer;
  final String? hinweis;

  List<VorlagenZone> zonenMit(Map<String, String> p) => zonenFuer != null ? zonenFuer!(p) : zonen;
}

const String kVorlagenHinweis =
    'Die Vorlage ist ein orientierendes Beispiel – keine vollständige oder technisch garantierte Liste. '
    'Mengen trägst du selbst ein. Du kannst Artikel weglassen oder danach weitere aus dem Katalog hinzufügen.';

const _s = VorlagenStatus.standard;
const _o = VorlagenStatus.optional;
const _x = VorlagenStatus.situativ;

// ─────────────────────────── gemeinsame Varianten ───────────────────────────

const _waschtisch = [
  'Waschtisch 40 cm', 'Waschtisch 45 cm', 'Waschtisch 50 cm', 'Waschtisch 55 cm', 'Waschtisch 60 cm',
  'Waschtisch 65 cm', 'Waschtisch 70 cm', 'Waschtisch 80 cm', 'Waschtisch 90 cm', 'Waschtisch 100 cm',
  'Waschtisch 120 cm', 'Waschtisch Aufsatz rund', 'Waschtisch Aufsatz eckig',
];
const _waschtischArmatur = [
  'Waschtischarmatur Einhebelmischer', 'Waschtischarmatur Hoch', 'Waschtischarmatur Wandmontage',
  'Waschtischarmatur Zweigriff', 'Waschtischarmatur Unterputz Set',
];
const _ablauf = [
  'Ablaufgarnitur Waschtisch mit Überlauf', 'Ablaufgarnitur Waschtisch ohne Überlauf',
  'Ablaufgarnitur Waschtisch Push-Open',
];
const _siphon = ['Flaschensiphon', 'Röhrensiphon', 'Raumsparsiphon'];
const _eckventil = [
  'Eckventil chrom ½"×⅜"', 'Eckventil mit Filter ½"×⅜"', 'Eckventil Kombi Doppel ½"×⅜"',
  'Eckventil Durchgang ½"', 'Eckventil Aufputz ½"', 'Eckventil Unterputz ½"',
];
const _schlauch = ['Anschlussschlauch ⅜" 300 mm', 'Anschlussschlauch ⅜" 500 mm'];
const _silikon = ['Silikon Sanitär weiß', 'Silikon Sanitär transparent', 'Silikon Sanitär grau'];
const _wc = [
  'WC wandhängend Tiefspüler', 'WC wandhängend spülrandlos', 'WC wandhängend barrierefrei',
  'WC stehend Tiefspüler', 'WC Stand Flachspüler', 'WC Stand spülrandlos',
  'WC Kombination Stand mit Spülkasten',
];
const _wcSitz = ['WC-Sitz Standard', 'WC-Sitz mit Absenkautomatik', 'WC-Sitz Soft-Close abnehmbar', 'WC-Sitz Duroplast'];
const _vorwand = [
  'Vorwandelement WC Höhe 1120 mm', 'Vorwandelement WC Höhe 820 mm', 'Vorwandelement WC barrierefrei',
  'Vorwandelement Eckmontage',
];
const _druecker = [
  'Drückerplatte Dual weiß', 'Drückerplatte Dual chrom', 'Drückerplatte Dual schwarz',
  'Drückerplatte Dual Edelstahl', 'Drückerplatte berührungslos',
];
const _spuelkasten = [
  'Spülkasten Unterputz 6/3 l', 'Spülkasten Unterputz 4,5/3 l', 'Spülkasten Unterputz',
  'Spülkasten Aufputz', 'Spülkasten Halbhoch',
];
const _anschlussbogen = ['WC-Anschlussbogen DN 100', 'WC-Anschlussbogen DN 90'];
const _thermostatkopf = ['Thermostatkopf', 'Thermostatkopf Fernfühler', 'Thermostatkopf Fernversteller'];
const _thermostatventil = [
  'Thermostatventil gerade ½"', 'Thermostatventil Eck ½"', 'Thermostatventil Unterteil gerade',
  'Thermostatventil Unterteil Eck', 'Thermostatventil Axial', 'Thermostatventil Durchgang ¾"',
];
const _ruecklauf = [
  'Rücklaufverschraubung gerade ½"', 'Rücklaufverschraubung Eck ½"', 'Rücklaufverschraubung Eck ¾"',
  'Rücklaufverschraubung Durchgang ¾"', 'Rücklaufverschraubung Axial',
];
const _hanf = ['Hanf Zopf 100 g', 'Hanf Zopf 200 g', 'Hanf Zopf 500 g'];
const _duebel = ['Dübel 6 mm', 'Dübel 8 mm', 'Dübel 10 mm', 'Dübel 12 mm', 'Dübel 14 mm'];
const _koerperschall = ['Körperschalldämmung WC', 'Körperschalldämmung Waschtisch', 'Körperschalldämmung Dusche'];

// ─────────────────────────── Vorlagen 1–3 ───────────────────────────

const _heizkoerperAustauschen = Vorlage(
  'Heizkörper austauschen',
  'Heizkörper, Thermostat, Anschlüsse – Typ, Höhe und Länge wählst du selbst.',
  zonen: [
    VorlagenZone('Heizkörper', posten: [
      VorlagenPosten('Kompaktheizkörper', [], _s, heizkoerper: true),
    ]),
    VorlagenZone('Thermostat und Zubehör', posten: [
      VorlagenPosten('Thermostatkopf', _thermostatkopf, _s),
      VorlagenPosten('Heizkörper-Rosette', ['Heizkörper-Rosette Ø15', 'Heizkörper-Rosette Ø18'], _s,
          hinweis: 'Passend zum Rohrdurchmesser wählen.'),
      VorlagenPosten('Halterung', ['Heizkörper-Wandhalter Set', 'Heizkörperkonsole'], _s),
      VorlagenPosten('Heizkörper-Entlüfter ½"', ['Heizkörper-Entlüfter ½"'], _s),
      VorlagenPosten('Heizkörper-Blindstopfen ½"', ['Heizkörper-Blindstopfen ½"'], _o),
      VorlagenPosten('Heizkörper-Entlüftungsschlüssel', ['Heizkörper-Entlüftungsschlüssel'], _o),
      VorlagenPosten('Dichtung Heizkörper Set', ['Dichtung Heizkörper Set'], _x),
      VorlagenPosten('Hanf Zopf', _hanf, _x, hinweis: 'Nur bei Gewindeverbindungen.'),
    ]),
    VorlagenZone(
      'Anschluss',
      modusFrage: 'Anschluss: entweder Einzelteile oder ein Set – so werden Materialien nicht doppelt aufgenommen.',
      modi: [
        VorlagenModus('Einzelteile', [
          VorlagenPosten('Thermostatventil', _thermostatventil, _s),
          VorlagenPosten('Rücklaufverschraubung', _ruecklauf, _s),
          VorlagenPosten('Heizkörper-Verschraubung', ['Heizkörper-Verschraubung ½"', 'Heizkörper-Verschraubung ¾"'], _x),
        ]),
        VorlagenModus('Set', [
          VorlagenPosten('Heizkörper-Anschlussset', ['Heizkörper-Anschlussset'], _x),
        ]),
      ],
    ),
  ],
);

const _waschbeckenMontieren = Vorlage(
  'Waschbecken montieren',
  'Waschtisch, Armatur, Ablauf und Anschlüsse.',
  zonen: [
    VorlagenZone('Waschtisch', hinweis: 'Die Ablaufgarnitur muss zum Waschtisch passen (mit/ohne Überlauf).', posten: [
      VorlagenPosten('Waschtisch', _waschtisch, _s),
      VorlagenPosten('Waschtischarmatur', _waschtischArmatur, _s),
      VorlagenPosten('Ablaufgarnitur Waschtisch', _ablauf, _s),
      VorlagenPosten('Siphon', _siphon, _s),
      VorlagenPosten('Dichtung Siphon Set', ['Dichtung Siphon Set'], _o),
    ]),
    VorlagenZone('Anschlüsse', posten: [
      VorlagenPosten('Eckventil', _eckventil, _s),
      VorlagenPosten('Anschlussschlauch', _schlauch, _s),
    ]),
    VorlagenZone('Montage und Fugen', posten: [
      VorlagenPosten('Körperschalldämmung Waschtisch', ['Körperschalldämmung Waschtisch'], _o),
      VorlagenPosten('Silikon Sanitär', _silikon, _s),
    ]),
  ],
);

const _wcMontieren = Vorlage(
  'WC montieren',
  'WC, Sitz, Anschlussbogen – Vorwand und Spülkasten nur, wenn es der Einbau erfordert.',
  zonen: [
    VorlagenZone('WC', posten: [
      VorlagenPosten('WC', _wc, _s),
      VorlagenPosten('WC-Sitz', _wcSitz, _s),
      VorlagenPosten('WC-Anschlussbogen', _anschlussbogen, _s),
      VorlagenPosten('Dichtung WC-Anschluss', ['Dichtung WC-Anschluss'], _s),
      VorlagenPosten('Körperschalldämmung WC', ['Körperschalldämmung WC'], _o),
    ]),
    VorlagenZone('Je nach Einbau', hinweis: 'Nur wählen, wenn es der konkrete Einbau verlangt.', posten: [
      VorlagenPosten('Vorwandelement WC', _vorwand, _x),
      VorlagenPosten('Drückerplatte', _druecker, _x),
      VorlagenPosten('Spülkasten', _spuelkasten, _x),
      VorlagenPosten('Eckventil', _eckventil, _x),
      VorlagenPosten('Anschlussschlauch', _schlauch, _x),
    ]),
  ],
);

// ─────────────────────────── Vorlage 4: Wasserleitung ───────────────────────────

const kWerkstoffKupfer = 'Kupfer';
const kWerkstoffEdelstahl = 'Edelstahl';
const kKupferDurchmesser = [12, 15, 18, 22, 28, 35, 42, 54];
const kEdelstahlDurchmesser = [15, 18, 22, 28, 35, 42, 54];

/// Kugelhahn Press gibt es im Katalog nur für diese Durchmesser; das Material
/// ist im Katalog nicht angegeben.
const kKugelhahnPressDurchmesser = [15, 18, 22, 28, 35];

List<VorlagenZone> wasserleitungZonen(Map<String, String> p) {
  final werkstoff = p['werkstoff'];
  final d = int.tryParse(p['durchmesser'] ?? '');
  final kupfer = werkstoff == kWerkstoffKupfer;
  final edelstahl = werkstoff == kWerkstoffEdelstahl;
  if (d == null || !(kupfer || edelstahl)) return const [];
  final erlaubt = kupfer ? kKupferDurchmesser : kEdelstahlDurchmesser;
  if (!erlaubt.contains(d)) return const [];
  final m = kupfer ? '(Kupfer)' : '(Edelstahl)';
  final kugelhahnDa = kKugelhahnPressDurchmesser.contains(d);
  return [
    VorlagenZone(
      '$werkstoff Ø$d mm',
      hinweis: 'Ob Rohr, Fitting und Dichtung für Trinkwasser geeignet sind, richtet sich nach den Angaben des Herstellers – '
          'bitte dort prüfen. Reduzierte T-Stücke und Reduzierungen gibt es nur in bestimmten Kombinationen; '
          'bitte bei Bedarf selbst im Katalog suchen.',
      posten: [
        VorlagenPosten(
          kupfer ? 'Kupferrohr' : 'Edelstahlrohr',
          kupfer ? ['Kupferrohr Ø$d mm'] : ['Edelstahlrohr Ø$d mm', 'Edelstahlrohr Ø$d mm 1,4301'],
          _s,
        ),
        VorlagenPosten('Pressfitting Bogen 90°', ['Pressfitting Bogen 90° Ø$d $m'], _s),
        VorlagenPosten('Pressfitting Bogen 45°', ['Pressfitting Bogen 45° Ø$d $m'], _x),
        VorlagenPosten('Pressfitting T-Stück', ['Pressfitting T-Stück Ø$d $m'], _s),
        VorlagenPosten('Pressfitting Muffe', ['Pressfitting Muffe Ø$d $m'], _s),
        VorlagenPosten('Pressfitting Kappe', ['Pressfitting Kappe Ø$d $m'], _o),
        VorlagenPosten('Pressfitting Endkappe', ['Pressfitting Endkappe Ø$d $m'], _o),
        const VorlagenPosten('Kugelhahn Press', [], _s), // unten je nach Durchmesser ersetzt
        VorlagenPosten(
          'Rohrschelle',
          kupfer
              ? [
                  'Rohrschelle Ø$d mit Gummieinlage', 'Rohrschelle Ø$d verzinkt', 'Rohrschelle Ø$d Edelstahl',
                  'Rohrschelle Ø$d mit Schnellverschluss', 'Rohrschelle Ø$d mit Gewindestange',
                ]
              : ['Rohrschelle Ø$d Edelstahl', 'Rohrschelle Ø$d mit Gummieinlage'],
          _s,
        ),
        VorlagenPosten('Isolierung', ['Isolierung Ø$d'], _x),
        VorlagenPosten('Dübel', _duebel, _x, hinweis: 'Je nach Untergrund.'),
        VorlagenPosten('Hanf Zopf', _hanf, _x, hinweis: 'Nur bei Gewindeverbindungen.'),
      ].map((e) {
        if (e.label != 'Kugelhahn Press') return e;
        return kugelhahnDa
            ? VorlagenPosten('Kugelhahn Press', ['Kugelhahn Press Ø$d'], _s,
                hinweis: 'Im Katalog ohne Werkstoffangabe – Eignung für das System laut Hersteller prüfen.')
            : const VorlagenPosten('Kugelhahn Press', [], _s,
                hinweis: 'Für diesen Durchmesser im Katalog nicht vorhanden.');
      }).toList(),
    ),
  ];
}

final _wasserleitung = Vorlage(
  'Wasserleitung verlegen',
  'Zuerst Werkstoff und Durchmesser wählen (V1: Kupfer und Edelstahl).',
  hinweis: 'Für Mehrschichtverbund- und PE-X-Rohr gibt es keine Vorschläge. '
      'Diese Rohre und passende Fittings fügst du selbst aus dem Katalog hinzu.',
  parameter: [
    VorlagenParameter('werkstoff', 'Werkstoff', (_) => const [kWerkstoffKupfer, kWerkstoffEdelstahl]),
    VorlagenParameter('durchmesser', 'Durchmesser (mm)', (g) {
      final l = g['werkstoff'] == kWerkstoffKupfer
          ? kKupferDurchmesser
          : (g['werkstoff'] == kWerkstoffEdelstahl ? kEdelstahlDurchmesser : <int>[]);
      return [for (final d in l) '$d'];
    }),
  ],
  zonenFuer: wasserleitungZonen,
);

// ─────────────────────────── Vorlage 5: Badsanierung ───────────────────────────

const _badsanierung = Vorlage(
  'Badsanierung',
  'Sammelvorlage in 8 Zonen. Zonen oder Artikel einfach leer lassen, wenn sie nicht gebraucht werden.',
  zonen: [
    VorlagenZone('WC', posten: [
      VorlagenPosten('WC', _wc, _s),
      VorlagenPosten('WC-Sitz', _wcSitz, _o),
      VorlagenPosten('Vorwandelement WC', _vorwand, _x),
      VorlagenPosten('Drückerplatte', _druecker, _x),
      VorlagenPosten('WC-Anschlussbogen', _anschlussbogen, _s),
      VorlagenPosten('Dichtung WC-Anschluss', ['Dichtung WC-Anschluss'], _s),
    ]),
    VorlagenZone('Waschtisch', posten: [
      VorlagenPosten('Waschtisch', _waschtisch, _s),
      VorlagenPosten('Waschtischarmatur', _waschtischArmatur, _s),
      VorlagenPosten('Ablaufgarnitur Waschtisch', _ablauf, _s),
      VorlagenPosten('Siphon', _siphon, _s),
    ]),
    VorlagenZone(
      'Dusche oder Wanne',
      modusFrage: 'Dusche ODER Wanne wählen (oder keins von beiden).',
      modi: [
        VorlagenModus('Dusche', [
          VorlagenPosten('Duschwanne', [
            'Duschwanne 70×70', 'Duschwanne 75×75', 'Duschwanne 80×80', 'Duschwanne 90×90',
            'Duschwanne 100×100', 'Duschwanne 100×80', 'Duschwanne 120×80', 'Duschwanne 90×120',
            'Duschwanne 90×140', 'Duschwanne 90×160', 'Duschwanne 80×160', 'Duschwanne 100×140',
          ], _s, hinweis: 'Alternative: Duschrinne.'),
          VorlagenPosten('Duschrinne', [
            'Duschrinne 80 cm', 'Duschrinne 90 cm', 'Duschrinne 100 cm',
            'Duschrinne Edelstahl 70 cm', 'Duschrinne Edelstahl 90 cm', 'Duschrinne Edelstahl 120 cm',
          ], _x),
          VorlagenPosten('Duscharmatur', ['Duscharmatur Unterputz Set', 'Duscharmatur Aufputz'], _s),
          VorlagenPosten('Duschsiphon', ['Duschsiphon'], _s),
          VorlagenPosten('Duschtür Schiebetür', ['Duschtür Schiebetür'], _o),
        ]),
        VorlagenModus('Wanne', [
          VorlagenPosten('Badewanne', [
            'Badewanne 170×75', 'Badewanne 180×80', 'Badewanne rechteck 160×70', 'Badewanne rechteck 170×70',
            'Badewanne rechteck 170×80', 'Badewanne rechteck 180×80', 'Badewanne rechteck 180×90',
            'Badewanne rechteck 190×90',
          ], _s),
          VorlagenPosten('Badewannensiphon', ['Badewannensiphon'], _s),
        ]),
      ],
    ),
    VorlagenZone('Heizung', posten: [
      VorlagenPosten('Badheizkörper', [
        'Badheizkörper 800×500', 'Badheizkörper 800×600', 'Badheizkörper 1200×500',
        'Badheizkörper 1200×600', 'Badheizkörper 1800×500', 'Badheizkörper 1800×600',
      ], _o),
      VorlagenPosten('Thermostatkopf', _thermostatkopf, _o),
      VorlagenPosten('Thermostatventil', _thermostatventil, _o),
      VorlagenPosten('Rücklaufverschraubung', _ruecklauf, _o),
    ]),
    VorlagenZone(
      'Abdichtung',
      hinweis: 'Es sind nur die Artikel aufgeführt, die im Katalog vorhanden sind.',
      posten: [
        VorlagenPosten('Verbundabdichtung Dusche', ['Verbundabdichtung Dusche'], _x),
        VorlagenPosten('Dichtband Wand/Boden', ['Dichtband Wand/Boden'], _s),
        VorlagenPosten('Dichtband selbstklebend', ['Dichtband selbstklebend'], _s),
        VorlagenPosten('Dichtmanschette Bodenablauf', ['Dichtmanschette Bodenablauf'], _x,
            hinweis: 'Nur mit Bodenablauf.'),
      ],
      nichtVerfuegbar: [
        'Abdichtungsgrundierung',
        'Dichtschlämme',
        'Abdichtmanschetten für Wand/Rohr',
      ],
    ),
    VorlagenZone('Montage', posten: [
      VorlagenPosten('Körperschalldämmung', _koerperschall, _o),
      VorlagenPosten('Montagekleber', ['Montagekleber Polymer', 'Montagekleber transparent', 'Montagekleber Kartusche'], _o),
      VorlagenPosten('Dübel', _duebel, _x),
      VorlagenPosten('Wandwinkel verzinkt', ['Wandwinkel verzinkt'], _x),
    ]),
    VorlagenZone('Anschlüsse', posten: [
      VorlagenPosten('Eckventil', _eckventil, _x),
      VorlagenPosten('Anschlussschlauch', _schlauch, _x),
      VorlagenPosten('Spülkasten Anschlussschlauch', ['Spülkasten Anschlussschlauch'], _x),
    ]),
    VorlagenZone('Fugen', posten: [
      VorlagenPosten('Silikon Sanitär', _silikon, _s),
    ]),
  ],
);

final List<Vorlage> kVorlagen = [
  _heizkoerperAustauschen,
  _waschbeckenMontieren,
  _wcMontieren,
  _wasserleitung,
  _badsanierung,
];

// ─────────────────────────── Heizkörper: Typ / Höhe / Länge ───────────────────────────

final RegExp _kompaktMuster = RegExp(r'^Kompaktheizkörper Typ (\d+) (\d+)×(\d+)$');

/// Aus den Katalognamen: Typ → Höhe → Längen (nur Kombinationen, die es gibt).
Map<String, Map<int, List<int>>> kompaktheizkoerperKombinationen(Iterable<String> katalogNamen) {
  final m = <String, Map<int, List<int>>>{};
  for (final n in katalogNamen) {
    final x = _kompaktMuster.firstMatch(n);
    if (x == null) continue;
    ((m[x.group(1)!] ??= {})[int.parse(x.group(2)!)] ??= []).add(int.parse(x.group(3)!));
  }
  for (final h in m.values) {
    for (final l in h.values) {
      l.sort();
    }
  }
  return m;
}

String kompaktheizkoerperName(String typ, int hoehe, int laenge) => 'Kompaktheizkörper Typ $typ $hoehe×$laenge';

// ─────────────────────────── Auswahl → neue Baustelle ───────────────────────────

class VorlagenAuswahl {
  const VorlagenAuswahl(this.name, this.menge);

  final String name;
  final double menge;
}

/// Nur Einträge mit Menge > 0 und einem Namen aus dem Katalog.
/// Gibt die gültige Auswahl zurück; ungültige Zeilen werden NICHT stillschweigend
/// ersetzt, sondern in [fehler] gemeldet.
({List<VorlagenAuswahl> auswahl, List<String> fehler}) pruefeAuswahl(
  Iterable<({String name, double? menge})> zeilen,
  Set<String> katalogNamen,
) {
  final ok = <VorlagenAuswahl>[];
  final fehler = <String>[];
  for (final z in zeilen) {
    if (z.menge == null) continue; // keine Menge = nicht ausgewählt
    if (z.menge! <= 0) {
      fehler.add('${z.name}: Die Menge muss größer als 0 sein.');
    } else if (!katalogNamen.contains(z.name)) {
      fehler.add('${z.name}: nicht im Katalog.');
    } else {
      ok.add(VorlagenAuswahl(z.name, z.menge!));
    }
  }
  return (auswahl: ok, fehler: fehler);
}

/// Legt IMMER eine neue Baustelle an. Bestehende Baustellen und Listen bleiben unverändert.
Future<Baustelle> vorlageAlsNeueBaustelle(
  MaterialListenStore store,
  String baustellenName,
  List<VorlagenAuswahl> auswahl,
) async {
  final einheiten = {for (final a in store.katalog) a.name: a.einheit};
  final b = await store.neueBaustelle(baustellenName);
  for (final a in auswahl) {
    await store.hinzufuegen(b.id, name: a.name, menge: a.menge, einheit: einheiten[a.name] ?? 'Stk.');
  }
  return b;
}
