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
  });

  /// Links/Rechts in Grad (positiv: rechts höher), nach Abzug der Kalibrierung.
  final double rollGrad;

  /// Vorne/Hinten in Grad (positiv: vorne höher), nach Abzug der Kalibrierung.
  final double pitchGrad;

  /// Gesamtneigung (Winkel der Ebene gegen die Waagerechte).
  final double gesamtGrad;
  final double prozent; // Gefälle in %
  final double mmProM; // Gefälle in mm/m

  /// false, wenn das Handy nicht flach liegt (Display nach unten oder stark gekippt).
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
    flach: gesamt < 60,
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

/// Lage der Blase im Anzeigekreis als Einheitsvektor-Anteil (−1…1).
/// Die Blase wandert wie bei einer echten Libelle zur HÖHEREN Seite:
///  roll > 0 (rechts höher)  → dx > 0 (nach rechts auf dem Display)
///  pitch > 0 (vorne höher)  → dy < 0 (nach oben auf dem Display, y zeigt nach unten)
/// [skalaGrad] ist nur der Darstellungsbereich (Vollausschlag), keine Bewertung.
({double dx, double dy}) blasenPosition(double rollGrad, double pitchGrad, {double skalaGrad = 5}) {
  double lim(double v) => (v / skalaGrad).clamp(-1.0, 1.0);
  var dx = lim(rollGrad);
  var dy = -lim(pitchGrad);
  final len = math.sqrt(dx * dx + dy * dy);
  if (len > 1) {
    dx /= len;
    dy /= len;
  }
  return (dx: dx, dy: dy);
}
