import 'package:flutter/material.dart';

import 'calc_page.dart';
import 'logic.dart';
import 'materialkosten_page.dart';

/// Ein Eintrag in der Startseite. [builder] == null bedeutet "bald verfügbar".
class CalcDef {
  const CalcDef(this.label, this.icon, this.builder);

  final String label;
  final IconData icon;
  final Widget Function()? builder;
}

String _mm(double v) => '${fmt(v, digits: v % 1 == 0 ? 0 : 1)} mm';

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
          '(DIN EN 12831). Die W/m²-Werte gelten für ca. 2,5 m Raumhöhe.',
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
          'ersetzt keine Rohrnetzberechnung.',
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
            CalcOption('Kupfer, Edelstahl (k = 0,0015 mm)', '0.0015'),
            CalcOption('Kunststoff, Mehrschicht (k = 0,007 mm)', '0.007'),
            CalcOption('Stahl neu (k = 0,045 mm)', '0.045'),
            CalcOption('Stahl verzinkt (k = 0,15 mm)', '0.15'),
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
