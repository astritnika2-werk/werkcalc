import 'package:flutter/material.dart';

import 'calc_page.dart';
import 'logic.dart';
import 'materialkosten_page.dart';
import 'pumpen_pruefung_page.dart';
import 'rechner_pruefung.dart';
import 'messen_pruefen_page.dart';
import 'vorschlag.dart';

/// Ein Eintrag in der Startseite. [builder] == null bedeutet "bald verfügbar".
class CalcDef {
  const CalcDef(this.label, this.icon, this.builder);

  final String label;
  final IconData icon;
  final Widget Function()? builder;
}

String _mm(double v) => '${fmt(v, digits: v % 1 == 0 ? 0 : 1)} mm';

Widget _pumpePage({
  String? volumenstrom,
  String? durchmesser,
  String? laenge,
  double? rauheit,
  String? zeta,
  double? temperatur,
}) {
  String temp = '60';
  for (final o in const ['40', '50', '60', '70']) {
    if (temperatur != null && (double.parse(o) - temperatur).abs() < 1e-9) temp = o;
  }
  String rau = '0.0015';
  for (final o in const ['0.0015', '0.007']) {
    if (rauheit != null && (double.parse(o) - rauheit).abs() < 1e-9) rau = o;
  }
  return CalcPage(
    title: 'Pumpe wählen',
    note: 'Umwälzpumpe Heizung: entweder Volumenstrom eingeben oder Heizleistung '
        'und Spreizung (ΔT). Rohrlänge = Vorlauf + Rücklauf. Wenn nur eine Strecke gemessen wurde, diese × 2 rechnen. ζ-Werte '
        'und Widerstände von Wärmeerzeuger, Ventilen und Mischern laut Herstellerangabe.',
    requireAll: false,
    richtwert: true,
    pruefung: prueferPumpe,
    weiter: CalcWeiter('Weiter: Pumpe prüfen (Kennlinie)', (v) {
      final a = _pumpeAus(v);
      return PumpenPruefungPage(q: a?.volumenstromM3h, h: a?.foerderhoeheM);
    }),
    fields: [
      CalcField('Volumenstrom (optional)', 'm³/h', initial: volumenstrom),
      const CalcField('Heizleistung', 'kW'),
      const CalcField('Spreizung ΔT (Vor-/Rücklauf)', 'K', initial: '20'),
      CalcField('Rohr-Innendurchmesser', 'mm', initial: durchmesser),
      CalcField('Rohrlänge Vorlauf + Rücklauf zusammen', 'm', initial: laenge),
      CalcField('Einzelwiderstände (Σζ)', '', initial: zeta ?? '0'),
      const CalcField('Weitere Widerstände (Kessel, Ventile, Mischer)', 'mbar', initial: '0'),
      CalcField(
        'Rohrmaterial',
        '',
        options: const [
          CalcOption('Edelstahl', '0.0015'),
          CalcOption('Mehrschichtverbund / PE-RT (k = 0,007 mm)', '0.007'),
        ],
        initial: rau,
      ),
      CalcField(
        'Mittlere Wassertemperatur',
        '',
        options: const [
          CalcOption('40 °C (Fußbodenheizung)', '40'),
          CalcOption('50 °C', '50'),
          CalcOption('60 °C', '60'),
          CalcOption('70 °C', '70'),
        ],
        initial: temp,
      ),
    ],
    compute: (v) {
      final a = _pumpeAus(v);
      if (a == null) return [];
      final rows = <ResultRow>[
        ResultRow('Volumenstrom', '${fmt(a.volumenstromM3h, digits: 2)} m³/h',
            highlight: true),
        ResultRow('in l/min', fmt(a.volumenstromM3h * 1000 / 60, digits: 1)),
        ResultRow('Strömungsgeschwindigkeit', '${fmt(a.geschwindigkeit)} m/s'),
        if (a.geschwindigkeit > 1.0)
          const ResultRow('Hinweis', 'über 1 m/s: größeres Rohr prüfen'),
        ResultRow('Druckverlust Rohrnetz', '${fmt(a.dpRohrnetzPa / 100, digits: 0)} mbar'),
        ResultRow('Erforderliche Förderhöhe', '${fmt(a.foerderhoeheM, digits: 2)} m',
            highlight: true),
        ResultRow('Auslegungsreserve (${fmt(kPumpenReserve, digits: 1)}×)',
            '${fmt(a.foerderhoeheM * kPumpenReserve, digits: 2)} m'),
        if (a.typ != null && a.typMin != null && a.typMax != null)
          ResultRow(
            'Empfohlener Bereich (Richtwert)',
            a.typMin == a.typMax
                ? 'Typ ${a.typ}'
                : (a.typMin == a.typ
                    ? 'Typ ${a.typ} bis ${a.typMax}'
                    : 'Typ ${a.typMin} bis ${a.typMax}'),
            highlight: true,
          ),
        if (a.typ != null)
          ResultRow('Beste Wahl (Richtwert)', 'Typ ${a.typ}'),
        if (a.typ != null)
          ResultRow(
            'Warum (Richtwert): Betriebspunkt Q = ${fmt(a.volumenstromM3h, digits: 2)} m³/h, '
            'H = ${fmt(a.foerderhoeheM, digits: 2)} m. Mit Auslegungsreserve '
            '${fmt(kPumpenReserveMin, digits: 1)}× bis ${fmt(kPumpenReserve, digits: 1)}× '
            '(${fmt(a.foerderhoeheM * kPumpenReserveMin, digits: 2)}–'
            '${fmt(a.foerderhoeheM * kPumpenReserve, digits: 2)} m) passt nach der '
            'üblichen Typbezeichnung (z. B. 25-40 ≈ max. 4 m) dieser Bereich. '
            'Die größere Pumpe gibt Reserve bei späterem Umbau, regelt aber im '
            'Teillastbereich weniger genau.',
            '',
          ),
        if (a.typ != null)
          const ResultRow(
            'Richtwert, keine exakte Pumpenwahl. Für die echte Prüfung Q und H mit der '
            'Q/H-Kennlinie der konkreten Pumpe vergleichen: „Weiter: Pumpe prüfen“.',
            '',
          ),
        if (a.dn != null)
          ResultRow('Anschluss (üblich)', 'DN ${a.dn} · G ${kPumpenGewinde[a.dn]}'),
        if (a.hinweis != null) ResultRow(a.hinweis!, ''),
      ];
      return rows;
    },
    vorschlaege: (v) {
      final a = _pumpeAus(v);
      if (a == null || a.typ == null || a.dn == null) return const [];
      final g = kPumpenGewinde[a.dn]!;
      return [
        Vorschlag('Umwälzpumpe Hocheffizienz ${a.typ}', 1,
            'Richtwert: DN ${a.dn}, Auslegungsreserve ${fmt(a.foerderhoeheM * kPumpenReserve, digits: 2)} m; Kennlinie des Herstellers prüfen'),
        if (a.typMax != null && a.typMax != a.typ)
          Vorschlag('Umwälzpumpe Hocheffizienz ${a.typMax}', 1,
              'Alternative mit mehr Reserve (statt, nicht zusätzlich)'),
        Vorschlag('Pumpenverschraubung $g', 2, 'üblicher Anschluss G $g – am Typenschild/Datenblatt der gewählten Pumpe prüfen'),
        Vorschlag('Kugelhahn $g IG/IG', 2, 'Absperrventil vor und hinter der Pumpe (Größe zum Pumpenanschluss prüfen)'),
        Vorschlag('Pumpenisolierschale Heizung', 1, 'Wärmedämmung der Pumpe'),
        Vorschlag('Flachdichtung Fiber $g', 1, 'Dichtungen (falls nicht in der Verschraubung)'),
      ];
    },
  );
}

PumpenAuslegung? _pumpeAus(List<double?> v) {
  if (v[3] == null || v[4] == null) return null;
  return berechnePumpe(
    volumenstromM3h: v[0],
    heizleistungKw: v[1],
    deltaTK: v[2],
    durchmesserMm: v[3]!,
    laengeM: v[4]!,
    zetaSumme: v[5] ?? 0,
    zusatzMbar: v[6] ?? 0,
    rauheitMm: v[7] ?? 0.0015,
    temperaturC: v[8] ?? 60,
  );
}

final List<CalcDef> calculators = [
  CalcDef(
    'Rohrinhalt',
    Icons.plumbing,
    () => CalcPage(
      title: 'Rohrinhalt berechnen',
      note: 'Innendurchmesser (mm oder Zoll) und Länge des Rohrs eingeben.',
      fields: const [
        CalcField('Durchmesser (innen)', ''),
        CalcField(
          'Einheit',
          '',
          options: [CalcOption('mm', '1'), CalcOption('Zoll', '2')],
          initial: '1',
        ),
        CalcField('Länge', 'm'),
      ],
      pruefung: pruefeRohrinhalt,
      compute: (v) {
        final dMm = (v[1] ?? 1) == 2 ? zollToMm(v[0]!) : v[0]!;
        if (dMm <= 0 || v[2]! <= 0) return [];
        final liter = rohrInhaltLiter(dMm, v[2]!);
        return [
          ResultRow('Inhalt', '${fmt(liter)} Liter', highlight: true),
          ResultRow('Inhalt in m³', '${fmt(literToM3(liter), digits: 3)} m³'),
        ];
      },
    ),
  ),
  CalcDef(
    'Rohrlänge & Gefälle',
    Icons.trending_down,
    () => CalcPage(
      title: 'Rohrlänge & Gefälle',
      note: 'Rohrlänge aus Durchmesser und Wasservolumen, und/oder '
          'Höhenunterschied aus Länge und Gefälle (z. B. 2 % = 2 cm pro Meter).',
      requireAll: false,
      fields: const [
        CalcField('Durchmesser (innen)', 'mm'),
        CalcField('Wasservolumen', 'Liter'),
        CalcField('Rohrlänge', 'm'),
        CalcField('Gefälle', '%', initial: '2'),
      ],
      pruefung: pruefeGefaelle,
      compute: (v) {
        final rows = <ResultRow>[];
        double? laenge = v[2];
        if (v[0] != null && v[0]! > 0 && v[1] != null) {
          final l = rohrLaengeM(v[0]!, v[1]!);
          rows.add(ResultRow('Rohrlänge aus Volumen', '${fmt(l)} m',
              highlight: laenge == null));
          laenge ??= l;
        }
        if (laenge != null && v[3] != null) {
          rows.add(ResultRow(
            'Höhenunterschied',
            '${fmt(gefaelleHoeheCm(laenge, v[3]!), digits: 1)} cm',
            highlight: true,
          ));
        }
        return rows;
      },
    ),
  ),
  CalcDef(
    'Isolierung',
    Icons.layers,
    () => CalcPage(
      title: 'Isolierung berechnen',
      note: 'Dämmung um ein Rohr: Maße des Rohrs und Dämmstärke eingeben.',
      fields: const [
        CalcField('Rohrdurchmesser', 'mm'),
        CalcField('Dämmstärke', 'mm'),
        CalcField('Rohrlänge', 'm'),
      ],
      vorschlaege: (v) {
        final d = v[0];
        final l = v[2];
        if (d == null || l == null || d <= 0 || l <= 0) return const [];
        return [
          Vorschlag('Isolierung Ø${d.round()}', l, 'Rohr Ø ${fmt(d, digits: 0)} mm, ${fmt(l)} m'),
        ];
      },
      pruefung: pruefeIsolierung,
      compute: (v) {
        if (v[0]! <= 0 || v[1]! < 0 || v[2]! <= 0) return [];
        final i = berechneIsolierung(
          rohrMm: v[0]!,
          daemmMm: v[1]!,
          laengeM: v[2]!,
        );
        return [
          ResultRow('Außendurchmesser', _mm(i.aussenDurchmesserMm), highlight: true),
          ResultRow('Umfang', '${fmt(i.umfangM)} m'),
          ResultRow('Oberfläche', '${fmt(i.oberflaecheM2)} m²'),
          ResultRow('Dämmvolumen', '${fmt(i.volumenM3, digits: 3)} m³'),
        ];
      },
    ),
  ),
  CalcDef(
    'Heizkörper-Leistung',
    Icons.view_week,
    () => CalcPage(
      title: 'Heizkörper-Leistung',
      note: 'Grober Richtwert. Ersetzt keine Heizlastberechnung '
          '(DIN EN 12831). Die W/m²-Werte gelten für ca. 2,5 m Raumhöhe. '
          'Den Heizkörper selbst nach der Normwärmeleistung des Herstellers wählen.',
      fields: const [
        CalcField('Raumgröße', 'm²'),
        CalcField('Raumhöhe', 'm', initial: '2,5'),
        CalcField(
          'Wärmebedarf',
          '',
          options: [
            CalcOption('Neubau (50 W/m²)', '50'),
            CalcOption('Teilsaniert (80 W/m²)', '80'),
            CalcOption('Altbau (100 W/m²)', '100'),
            CalcOption('Unsaniert (130 W/m²)', '130'),
          ],
          initial: '100',
        ),
      ],
      richtwert: true,
      vorschlaege: (v) => const [
        Vorschlag('Thermostatkopf', 1, 'je Heizkörper'),
        Vorschlag('Thermostatventil gerade ½"', 1, 'je Heizkörper'),
        Vorschlag('Rücklaufverschraubung gerade ½"', 1, 'je Heizkörper'),
        Vorschlag('Heizkörper-Entlüfter ½"', 1, 'je Heizkörper'),
      ],
      pruefung: pruefeHeizkoerper,
      compute: (v) {
        if (v[0]! <= 0 || v[1]! <= 0 || v[2]! <= 0) return [];
        final w = heizleistungW(
          flaecheM2: v[0]!,
          hoeheM: v[1]!,
          wattProM2: v[2]!,
        );
        return [
          ResultRow('Erforderliche Heizleistung', '${fmt(w, digits: 0)} W',
              highlight: true),
          ResultRow('in Kilowatt', '≈ ${fmt(w / 1000, digits: 1)} kW'),
        ];
      },
    ),
  ),
  CalcDef(
    'kW / BTU',
    Icons.local_fire_department,
    () => CalcPage(
      title: 'kW ↔ BTU/h',
      note: 'Fülle ein Feld aus. 1 kW = 3.412,14 BTU/h.',
      requireAll: false,
      fields: const [
        CalcField('Leistung', 'kW'),
        CalcField('Leistung', 'BTU/h'),
      ],
      pruefung: pruefeEinFeld,
      compute: (v) {
        final rows = <ResultRow>[];
        if (v[0] != null) {
          rows.add(ResultRow('BTU/h', fmt(kwToBtuh(v[0]!), digits: 0),
              highlight: true));
        }
        if (v[1] != null) {
          rows.add(ResultRow('kW', fmt(btuhToKw(v[1]!)), highlight: true));
        }
        return rows;
      },
    ),
  ),
  CalcDef(
    'Druckverlust',
    Icons.speed,
    () => CalcPage(
      title: 'Druckverlust Rohrleitung',
      note: 'Gerades Rohr mit Wasser (Darcy-Weisbach, Colebrook-White). '
          'Bögen, Ventile usw. als Summe der ζ-Werte angeben. Richtwert, '
          'ersetzt keine Rohrnetzberechnung. Die Rohrlänge gilt für genau die '
          'Strecke, die du eingibst: bei einem Heizkreis Vorlauf + Rücklauf '
          'zusammen (nicht doppelt rechnen). „Weiter: Pumpe wählen“ übernimmt '
          'diese Länge unverändert.',
      requireAll: false,
      fields: const [
        CalcField('Volumenstrom', ''),
        CalcField(
          'Einheit',
          '',
          options: [
            CalcOption('l/min', '1'),
            CalcOption('l/h', '2'),
            CalcOption('m³/h', '3'),
          ],
          initial: '1',
        ),
        CalcField('Innendurchmesser', 'mm'),
        CalcField('Rohrlänge', 'm'),
        CalcField(
          'Rohrmaterial',
          '',
          options: [
            CalcOption('Edelstahl (k = 0,0015 mm)', '0.0015'),
            CalcOption('Mehrschichtverbund / PE-RT (k = 0,007 mm)', '0.007'),
          ],
          initial: '0.0015',
        ),
        CalcField(
          'Wassertemperatur',
          '',
          options: [
            CalcOption('10 °C (Trinkwasser kalt)', '10'),
            CalcOption('20 °C', '20'),
            CalcOption('45 °C', '45'),
            CalcOption('60 °C (Warmwasser, Heizung)', '60'),
            CalcOption('70 °C (Heizung)', '70'),
            CalcOption('80 °C', '80'),
          ],
          initial: '60',
        ),
        CalcField('Einzelwiderstände (Σζ)', '', initial: '0'),
      ],
      richtwert: true,
      weiter: CalcWeiter(
        'Weiter: Pumpe wählen',
        (v) => _pumpePage(
          volumenstrom: v[0] == null
              ? null
              : fmt(volumenstromZuM3s(v[0]!, (v[1] ?? 1).round()) * 3600, digits: 3),
          durchmesser: v[2] == null ? null : fmt(v[2]!, digits: 2),
          laenge: v[3] == null ? null : fmt(v[3]!, digits: 2),
          rauheit: v[4],
          zeta: v[6] == null ? null : fmt(v[6]!, digits: 2),
          temperatur: v[5],
        ),
      ),
      pruefung: pruefeDruckverlust,
      compute: (v) {
        final q = v[0];
        final d = v[2];
        final l = v[3];
        if (q == null || d == null || l == null) return [];
        if (q <= 0 || d <= 0 || l < 0) return [];
        final r = berechneDruckverlust(
          volumenstromM3s: volumenstromZuM3s(q, (v[1] ?? 1).round()),
          durchmesserMm: d,
          laengeM: l,
          temperaturC: v[5] ?? 60,
          rauheitMm: v[4] ?? 0.0015,
          zetaSumme: v[6] ?? 0,
        );
        return [
          ResultRow('Druckverlust gesamt', '${fmt(r.dpGesamtPa / 100)} mbar',
              highlight: true),
          ResultRow('in Pascal', '${fmt(r.dpGesamtPa, digits: 0)} Pa'),
          ResultRow('Gerades Rohr', '${fmt(r.dpRohrPa / 100)} mbar'),
          ResultRow('Einzelwiderstände', '${fmt(r.dpEinzelPa / 100)} mbar'),
          ResultRow('Rohrreibung R', '${fmt(r.rPaProM, digits: 1)} Pa/m'),
          ResultRow('Strömungsgeschwindigkeit',
              '${fmt(r.geschwindigkeit)} m/s'),
          ResultRow('Reynolds-Zahl', fmt(r.reynolds, digits: 0)),
          if (r.uebergangsbereich)
            const ResultRow('Hinweis', 'Übergangsbereich, unsicher'),
        ];
      },
    ),
  ),
  CalcDef(
    'Pumpe wählen',
    Icons.autorenew,
    () => _pumpePage(),
  ),
  CalcDef(
    'Pumpe prüfen',
    Icons.fact_check,
    () => const PumpenPruefungPage(),
  ),
  CalcDef(
    'Messen & Prüfen',
    Icons.sensors,
    () => const MessenPruefenPage(),
  ),
  CalcDef(
    'Liter / m³',
    Icons.water_drop,
    () => CalcPage(
      title: 'Liter ↔ m³',
      note: 'Fülle ein Feld aus. 1 m³ = 1.000 Liter.',
      requireAll: false,
      fields: const [
        CalcField('Volumen', 'Liter'),
        CalcField('Volumen', 'm³'),
      ],
      pruefung: pruefeEinFeld,
      compute: (v) {
        final rows = <ResultRow>[];
        if (v[0] != null) {
          rows.add(ResultRow('m³', fmt(literToM3(v[0]!), digits: 3), highlight: true));
        }
        if (v[1] != null) {
          rows.add(ResultRow('Liter', fmt(m3ToLiter(v[1]!)), highlight: true));
        }
        return rows;
      },
    ),
  ),
  CalcDef(
    'mm ↔ Zoll',
    Icons.straighten,
    () => CalcPage(
      title: 'Einheiten umrechnen',
      note: 'Fülle ein Feld aus. 1 Zoll = 25,4 mm.',
      requireAll: false,
      fields: const [
        CalcField('Millimeter', 'mm'),
        CalcField('Zoll', '"'),
      ],
      pruefung: pruefeEinFeld,
      compute: (v) {
        final rows = <ResultRow>[];
        if (v[0] != null) {
          rows.add(ResultRow('Zoll', '${fmt(mmToZoll(v[0]!), digits: 2)} "',
              highlight: true));
          rows.add(ResultRow('cm', '${fmt(v[0]! / 10)} cm'));
          rows.add(ResultRow('m', '${fmt(v[0]! / 1000, digits: 3)} m'));
        }
        if (v[1] != null) {
          rows.add(ResultRow('Millimeter', '${fmt(zollToMm(v[1]!))} mm',
              highlight: true));
        }
        return rows;
      },
    ),
  ),
  CalcDef(
    'Arbeitszeit & Lohn',
    Icons.schedule,
    () => CalcPage(
      title: 'Arbeitszeit & Lohn',
      note: 'Alle Beträge netto eingeben. Die MwSt. wird einmal auf die '
          'Netto-Summe aufgeschlagen.',
      requireAll: false,
      fields: const [
        CalcField('Stunden', 'h'),
        CalcField('Stundenlohn (netto)', '€'),
        CalcField('Anfahrt (netto)', '€', initial: '0'),
        CalcField('MwSt.-Satz', '%', initial: '19'),
      ],
      pruefung: pruefeArbeitszeit,
      compute: (v) {
        if (v[0] == null || v[1] == null) return [];
        final rate = v[3] ?? 19;
        final a = berechneAngebot(
          stunden: v[0]!,
          stundenlohn: v[1]!,
          anfahrt: v[2] ?? 0,
          mwstProzent: rate,
        );
        return [
          ResultRow('Arbeitskosten', '${fmt(a.arbeit)} €'),
          ResultRow('Anfahrt', '${fmt(a.anfahrt)} €'),
          ResultRow('Gesamt (netto)', '${fmt(a.netto)} €'),
          ResultRow('MwSt. (${fmt(rate, digits: rate % 1 == 0 ? 0 : 1)} %)',
              '${fmt(a.mwst)} €'),
          ResultRow('Gesamt (brutto)', '${fmt(a.brutto)} €', highlight: true),
        ];
      },
    ),
  ),
  CalcDef(
    'Materialkosten',
    Icons.inventory_2,
    () => const MaterialkostenPage(),
  ),
  CalcDef(
    'MwSt.-Rechner',
    Icons.percent,
    () => CalcPage(
      title: 'MwSt.-Rechner',
      note: 'Netto oder Brutto eingeben. Der Satz ist änderbar (z. B. 7 %).',
      requireAll: false,
      fields: const [
        CalcField('Nettobetrag', '€'),
        CalcField('Bruttobetrag', '€'),
        CalcField('MwSt.-Satz', '%', initial: '19'),
      ],
      pruefung: pruefeMwst,
      compute: (v) {
        final satz = v[2] ?? 19;
        final rows = <ResultRow>[];
        if (v[0] != null) {
          final brutto = nettoZuBrutto(v[0]!, satz);
          rows.add(ResultRow('MwSt.-Betrag', '${fmt(brutto - v[0]!)} €'));
          rows.add(ResultRow('Brutto', '${fmt(brutto)} €', highlight: true));
        }
        if (v[1] != null) {
          final netto = bruttoZuNetto(v[1]!, satz);
          rows.add(ResultRow('MwSt.-Betrag', '${fmt(v[1]! - netto)} €'));
          rows.add(ResultRow('Netto', '${fmt(netto)} €', highlight: true));
        }
        return rows;
      },
    ),
  ),
];
