import 'dart:math' as math;

/// BTU/h pro kW.
const double kBtuPerKw = 3412.14163;

/// Millimeter pro Zoll.
const double kMmPerZoll = 25.4;

/// Referenz-Raumhöhe, auf die sich die W/m²-Richtwerte beziehen.
const double kReferenzRaumhoehe = 2.5;

/// Liest eine Zahl; akzeptiert Komma und Punkt als Dezimaltrenner.
/// Beispiele: "12,5" und "12.5" ergeben 12,5; "1.234,56" und "1,234.56" ergeben 1234,56.
double? parseNum(String input) {
  var t = input.trim().replaceAll(' ', '');
  if (t.isEmpty) return null;
  final lastComma = t.lastIndexOf(',');
  final lastDot = t.lastIndexOf('.');
  if (lastComma >= 0 && lastDot >= 0) {
    // Der zuletzt stehende Trenner ist das Dezimalzeichen.
    if (lastComma > lastDot) {
      t = t.replaceAll('.', '').replaceAll(',', '.');
    } else {
      t = t.replaceAll(',', '');
    }
  } else if (lastComma >= 0) {
    t = t.replaceAll(',', '.');
  }
  return double.tryParse(t);
}

/// Formatiert deutsch: 1.234,56
String fmt(double v, {int digits = 2}) {
  final s = v.abs().toStringAsFixed(digits);
  final parts = s.split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    final left = intPart.length - i;
    buf.write(intPart[i]);
    if (left > 1 && left % 3 == 1) buf.write('.');
  }
  final decimals = digits > 0 ? ',${parts[1]}' : '';
  final isZero = double.parse(s) == 0;
  return '${v < 0 && !isZero ? '-' : ''}$buf$decimals';
}

/// Datum deutsch: 03.10.2026
String formatDatum(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

/// Rohrinhalt in Litern aus Innendurchmesser (mm) und Länge (m).
double rohrInhaltLiter(double dMm, double laengeM) {
  final rDm = dMm / 200; // Radius in dm
  return math.pi * rDm * rDm * (laengeM * 10);
}

/// Rohrlänge in Metern aus Innendurchmesser (mm) und Volumen (Liter).
double rohrLaengeM(double dMm, double liter) {
  final rDm = dMm / 200;
  return liter / (math.pi * rDm * rDm) / 10;
}

/// Höhenunterschied in cm bei Gefälle in % über die Länge in m.
/// Beispiel: 10 m bei 2 % = 20 cm.
double gefaelleHoeheCm(double laengeM, double gefaelleProzent) =>
    laengeM * gefaelleProzent;

double mmToZoll(double mm) => mm / kMmPerZoll;
double zollToMm(double zoll) => zoll * kMmPerZoll;

double kwToBtuh(double kw) => kw * kBtuPerKw;
double btuhToKw(double btuh) => btuh / kBtuPerKw;

double literToM3(double liter) => liter / 1000;
double m3ToLiter(double m3) => m3 * 1000;

double nettoZuBrutto(double netto, double mwstProzent) =>
    netto * (1 + mwstProzent / 100);

double bruttoZuNetto(double brutto, double mwstProzent) =>
    brutto / (1 + mwstProzent / 100);

class Isolierung {
  const Isolierung({
    required this.aussenDurchmesserMm,
    required this.umfangM,
    required this.oberflaecheM2,
    required this.volumenM3,
  });

  final double aussenDurchmesserMm;
  final double umfangM;
  final double oberflaecheM2;
  final double volumenM3;
}

/// Dämmung um ein Rohr: Außendurchmesser, Umfang, Dämmoberfläche, Dämmvolumen.
Isolierung berechneIsolierung({
  required double rohrMm,
  required double daemmMm,
  required double laengeM,
}) {
  final da = rohrMm + 2 * daemmMm;
  final umfang = math.pi * da / 1000;
  final oberflaeche = umfang * laengeM;
  final volumen = math.pi / 4 * (da * da - rohrMm * rohrMm) / 1e6 * laengeM;
  return Isolierung(
    aussenDurchmesserMm: da,
    umfangM: umfang,
    oberflaecheM2: oberflaeche,
    volumenM3: volumen,
  );
}

/// Grober Richtwert für die Heizleistung in Watt.
/// Die W/m²-Werte gelten für ca. 2,5 m Raumhöhe; andere Höhen werden linear skaliert.
/// Ersetzt keine Heizlastberechnung nach DIN EN 12831.
double heizleistungW({
  required double flaecheM2,
  required double hoeheM,
  required double wattProM2,
}) =>
    flaecheM2 * wattProM2 * (hoeheM / kReferenzRaumhoehe);

// ---------------------------------------------------------------------------
// Druckverlust in geraden Rohren (Darcy-Weisbach) mit Wasser
// ---------------------------------------------------------------------------

/// Stoffwerte von Wasser bei 1 bar nach IAPWS-IF97, erzeugt mit
/// tools/verify_formulas.py --dart (0 .. 95 °C in 5-K-Schritten).
const List<double> kWasserTemperaturenC = [
  0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 45.0, 50.0, 55.0, 60.0, 65.0, 70.0, 75.0, 80.0, 85.0, 90.0, 95.0,
];

/// Dichte in kg/m³.
const List<double> kWasserDichte = [
  999.844, 999.966, 999.701, 999.100, 998.205, 997.047, 995.651, 994.038, 992.224, 990.223, 988.047, 985.706, 983.210, 980.565, 977.779, 974.856, 971.802, 968.622, 965.318, 961.894,
];

/// Kinematische Viskosität in m²/s.
const List<double> kWasserViskositaet = [
  1.792034e-06, 1.518225e-06, 1.306293e-06, 1.138594e-06, 1.003398e-06, 8.926582e-07, 8.007036e-07, 7.234395e-07, 6.578464e-07, 6.016557e-07, 5.531334e-07, 5.109345e-07, 4.740014e-07, 4.414917e-07, 4.127278e-07, 3.871584e-07, 3.643311e-07, 3.438717e-07, 3.254682e-07, 3.088585e-07,
];

class WasserEigenschaften {
  const WasserEigenschaften(this.dichte, this.viskositaet);

  /// kg/m³
  final double dichte;

  /// m²/s (kinematisch)
  final double viskositaet;
}

/// Lineare Interpolation in der Tabelle; außerhalb des Bereichs wird geklemmt.
WasserEigenschaften wasserEigenschaften(double temperaturC) {
  const t = kWasserTemperaturenC;
  if (temperaturC <= t.first) {
    return WasserEigenschaften(kWasserDichte.first, kWasserViskositaet.first);
  }
  if (temperaturC >= t.last) {
    return WasserEigenschaften(kWasserDichte.last, kWasserViskositaet.last);
  }
  var i = 0;
  while (temperaturC > t[i + 1]) {
    i++;
  }
  final f = (temperaturC - t[i]) / (t[i + 1] - t[i]);
  return WasserEigenschaften(
    kWasserDichte[i] + f * (kWasserDichte[i + 1] - kWasserDichte[i]),
    kWasserViskositaet[i] + f * (kWasserViskositaet[i + 1] - kWasserViskositaet[i]),
  );
}

double _log10(double v) => math.log(v) / math.ln10;

/// Rohrreibungszahl λ: laminar 64/Re, sonst Colebrook-White
/// (Startwert Swamee-Jain, dann Fixpunkt-Iteration).
double reibungsbeiwert(double re, double relRauheit) {
  if (re < 2300) return 64 / re;
  final lam0 = 0.25 /
      math.pow(_log10(relRauheit / 3.7 + 5.74 / math.pow(re, 0.9)), 2);
  var x = 1 / math.sqrt(lam0);
  for (var i = 0; i < 50; i++) {
    final xNeu = -2 * _log10(relRauheit / 3.7 + 2.51 * x / re);
    final fertig = (xNeu - x).abs() < 1e-12;
    x = xNeu;
    if (fertig) break;
  }
  return 1 / (x * x);
}

/// Volumenstrom in m³/s. Einheit: 1 = l/min, 2 = l/h, 3 = m³/h.
double volumenstromZuM3s(double wert, int einheit) {
  switch (einheit) {
    case 2:
      return wert / 3.6e6;
    case 3:
      return wert / 3600;
    default:
      return wert / 60000;
  }
}

class DruckverlustErgebnis {
  const DruckverlustErgebnis({
    required this.geschwindigkeit,
    required this.reynolds,
    required this.lambda,
    required this.rPaProM,
    required this.dpRohrPa,
    required this.dpEinzelPa,
  });

  /// m/s
  final double geschwindigkeit;
  final double reynolds;
  final double lambda;

  /// Rohrreibung in Pa/m.
  final double rPaProM;
  final double dpRohrPa;
  final double dpEinzelPa;

  double get dpGesamtPa => dpRohrPa + dpEinzelPa;

  /// Zwischen Re 2.300 und 4.000 ist die Strömung weder sicher laminar noch turbulent.
  bool get uebergangsbereich => reynolds >= 2300 && reynolds < 4000;
}

/// Druckverlust in einem geraden Rohr plus Einzelwiderstände (Σζ).
/// Δp = (λ·L/d + Σζ) · ρ·v²/2
DruckverlustErgebnis berechneDruckverlust({
  required double volumenstromM3s,
  required double durchmesserMm,
  required double laengeM,
  required double temperaturC,
  required double rauheitMm,
  double zetaSumme = 0,
}) {
  final w = wasserEigenschaften(temperaturC);
  final d = durchmesserMm / 1000;
  final flaeche = math.pi * d * d / 4;
  final v = volumenstromM3s / flaeche;
  final re = v * d / w.viskositaet;
  final lam = reibungsbeiwert(re, (rauheitMm / 1000) / d);
  final staudruck = w.dichte * v * v / 2;
  final r = lam / d * staudruck;
  return DruckverlustErgebnis(
    geschwindigkeit: v,
    reynolds: re,
    lambda: lam,
    rPaProM: r,
    dpRohrPa: r * laengeM,
    dpEinzelPa: zetaSumme * staudruck,
  );
}

// ---------------------------------------------------------------------------
// Angebot
// ---------------------------------------------------------------------------

class Angebot {
  const Angebot({
    required this.arbeit,
    required this.anfahrt,
    required this.material,
    required this.netto,
    required this.mwst,
    required this.brutto,
  });

  final double arbeit;
  final double anfahrt;
  final double material;
  final double netto;
  final double mwst;
  final double brutto;
}

int _cents(double euro) => (euro * 100).round();
double _euro(int cents) => cents / 100;

/// Kalkulation immer auf Netto-Basis: erst alle Netto-Positionen (auf Cent
/// gerundet) addieren, dann einmal MwSt. aufschlagen und auf Cent runden.
/// Nie MwSt. auf bereits brutto-Summen.
Angebot berechneAngebotAusBetraegen({
  required double arbeit,
  double anfahrt = 0,
  double material = 0,
  double mwstProzent = 19,
}) {
  final a = _cents(arbeit);
  final f = _cents(anfahrt);
  final m = _cents(material);
  final netto = a + f + m;
  final mwst = (netto * mwstProzent / 100).round();
  return Angebot(
    arbeit: _euro(a),
    anfahrt: _euro(f),
    material: _euro(m),
    netto: _euro(netto),
    mwst: _euro(mwst),
    brutto: _euro(netto + mwst),
  );
}

Angebot berechneAngebot({
  required double stunden,
  required double stundenlohn,
  double anfahrt = 0,
  double materialkosten = 0,
  double materialZuschlagProzent = 0,
  double mwstProzent = 19,
}) {
  return berechneAngebotAusBetraegen(
    arbeit: stunden * stundenlohn,
    anfahrt: anfahrt,
    material: materialkosten * (1 + materialZuschlagProzent / 100),
    mwstProzent: mwstProzent,
  );
}

/// Ein Artikel in der Materialliste (Preis netto).
class MaterialPosition {
  const MaterialPosition({
    required this.name,
    required this.menge,
    required this.einzelpreis,
  });

  final String name;
  final double menge;
  final double einzelpreis;

  /// Positionssumme netto, auf Cent gerundet.
  double get summe => (menge * einzelpreis * 100).round() / 100;

  Map<String, dynamic> toJson() => {'n': name, 'm': menge, 'p': einzelpreis};

  factory MaterialPosition.fromJson(Map<String, dynamic> j) => MaterialPosition(
        name: j['n'] as String,
        menge: (j['m'] as num).toDouble(),
        einzelpreis: (j['p'] as num).toDouble(),
      );
}

/// Summe aller Positionen (netto), Cent-genau.
double materialSumme(List<MaterialPosition> positionen) {
  var cents = 0;
  for (final p in positionen) {
    cents += (p.menge * p.einzelpreis * 100).round();
  }
  return cents / 100;
}

/// Angebotsnummer im Format AN-2026-001.
String formatAngebotsnummer(int jahr, int laufnummer) =>
    'AN-$jahr-${laufnummer.toString().padLeft(3, '0')}';
