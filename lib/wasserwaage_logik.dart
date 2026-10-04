import 'dart:math' as math;

/// Wasserwaage – reine Berechnung aus dem Beschleunigungssensor (mit
/// Schwerkraft). Handy liegt mit dem Display nach oben:
///  x → rechte Kante, y → obere Kante („Vorne“), z → aus dem Display.
/// Ein positiver Wert bedeutet, dass die jeweilige Kante höher liegt.
class Neigung {
  const Neigung({
    required this.rollGrad,
    required this.pitchGrad,
    required this.gesamtGrad,
    required this.prozent,
    required this.mmProM,
    required this.flach,
    this.sx = 0,
    this.sy = 0,
  });

  /// Steigungs-Vektor der Ebene (tan der kalibrierten Winkel): sx positiv =
  /// rechts höher, sy positiv = vorne höher. Aus ihm folgen Zahlen UND Blase.
  final double sx;
  final double sy;

  /// Links/Rechts in Grad (positiv: rechts höher), nach Abzug der Kalibrierung.
  final double rollGrad;

  /// Vorne/Hinten in Grad (positiv: vorne höher), nach Abzug der Kalibrierung.
  final double pitchGrad;

  /// Gesamtneigung (Winkel der Ebene gegen die Waagerechte).
  final double gesamtGrad;
  final double prozent; // Gefälle in %
  final double mmProM; // Gefälle in mm/m

  /// false, wenn das Display nach unten zeigt (z ≤ 0): dann gibt es keine Neigung.
  final bool flach;
}

double _grad(double rad) => rad * 180 / math.pi;

/// Neigungswinkel der Projektion in der x–z- bzw. y–z-Ebene (Rohwerte, Grad).
({double roll, double pitch}) rohWinkel(double x, double y, double z) =>
    (roll: _grad(math.atan2(x, z)), pitch: _grad(math.atan2(y, z)));

Neigung berechneNeigung(double x, double y, double z, {double roll0 = 0, double pitch0 = 0}) {
  if (z <= 0) {
    return const Neigung(rollGrad: 0, pitchGrad: 0, gesamtGrad: 0, prozent: 0, mmProM: 0, flach: false);
  }
  final w = rohWinkel(x, y, z);
  final r = w.roll - roll0;
  final p = w.pitch - pitch0;
  final sx = math.tan(r * math.pi / 180);
  final sy = math.tan(p * math.pi / 180);
  final steigung = math.sqrt(sx * sx + sy * sy);
  final gesamt = _grad(math.atan(steigung));
  return Neigung(
    rollGrad: r,
    pitchGrad: p,
    gesamtGrad: gesamt,
    prozent: steigung * 100,
    mmProM: steigung * 1000,
    flach: true,
    sx: sx,
    sy: sy,
  );
}

class Kalibrierung {
  const Kalibrierung(this.roll0, this.pitch0, this.streuungGrad);
  final double roll0;
  final double pitch0;

  /// Streuung (Standardabweichung) der Winkel während der Kalibrierung, in Grad.
  final double streuungGrad;
}

/// Interner Richtwert: bewegt sich das Handy beim Kalibrieren stärker, wird
/// die Kalibrierung verworfen (keine Aussage über Installationen).
const double kKalibrierMaxStreuung = 0.3;

Kalibrierung? kalibriere(List<({double x, double y, double z})> proben) {
  final gut = proben.where((p) => p.z > 0).toList();
  if (gut.length < 10) return null;
  final rolls = <double>[], pitches = <double>[];
  for (final p in gut) {
    final w = rohWinkel(p.x, p.y, p.z);
    rolls.add(w.roll);
    pitches.add(w.pitch);
  }
  double mw(List<double> l) => l.reduce((a, b) => a + b) / l.length;
  double sd(List<double> l) {
    final m = mw(l);
    return math.sqrt(l.map((v) => (v - m) * (v - m)).reduce((a, b) => a + b) / l.length);
  }

  return Kalibrierung(mw(rolls), mw(pitches), math.max(sd(rolls), sd(pitches)));
}

/// Darstellung einer Neigung (Grad) auf einer Anzeigeachse, 0…1.
/// Rein geometrisch: 0° → 0, 90° (senkrecht) → 1, dazwischen Wurzel-Skala,
/// damit kleine Neigungen sichtbar sind und der ganze Bereich 0…90°
/// durchgehend (ohne Anschlag) dargestellt wird. Keine Schwelle, kein Anschlag.
double anzeigeSkala(double grad) => math.sqrt((grad.abs() / 90).clamp(0.0, 1.0));

/// Lage der Blase im Kreis (−1…1; Display: x rechts, y nach unten).
/// Kommt aus derselben Rechnung wie die Zahlen (Steigungsvektor sx, sy):
/// Richtung = Richtung der höheren Seite (wie bei einer echten Libelle),
/// Abstand = anzeigeSkala(Gesamtneigung).
///  rechts höher → dx > 0, vorne höher → dy < 0 (oben).
({double dx, double dy}) blasenPosition(Neigung n) {
  final len = math.sqrt(n.sx * n.sx + n.sy * n.sy);
  if (len == 0) return (dx: 0, dy: 0);
  final f = anzeigeSkala(n.gesamtGrad);
  return (dx: n.sx / len * f, dy: -n.sy / len * f);
}

/// Anzeige einer Achsen-Neigung (Grad) auf einer Leiste, −1…1 (Vorzeichen bleibt).
double leistenPosition(double grad) => grad.isNegative ? -anzeigeSkala(grad) : anzeigeSkala(grad);
