import 'dart:math' as math;

import 'wasserwaage_logik.dart';

/// Automatische Umschaltung der Betriebsart. Sie ändert weder Messung, noch
/// Sensorachsen, noch Kalibrierung – sie wählt nur, welche der vier Betriebsarten
/// angezeigt wird.

/// Interner Richtwert (keine Herstellervorgabe, keine Norm): Die Lage gilt als eindeutig,
/// wenn die Referenzachse der Betriebsart höchstens so viele Grad von der Senkrechten
/// abweicht. Unter 54,7° kann sowieso nur eine Achse die größte sein; 30° hält Abstand
/// zu den Grenzlagen, in denen das Handy „dazwischen“ liegt.
const double kEindeutigGrad = 30.0;

/// Interner Richtwert: So lange (Sekunden) muss die neue Lage ununterbrochen eindeutig
/// erkannt sein, bevor umgeschaltet wird. Kleine Bewegungen lösen so keinen Wechsel aus.
const double kUmschaltSekunden = 0.8;

/// Welche Betriebsart passt zur Lage? null, wenn die Lage nicht eindeutig ist
/// (z. B. schräg dazwischen, Display unten, kopfüber).
Modus? erkenneLage(double x, double y, double z) {
  final betrag = math.sqrt(x * x + y * y + z * z);
  if (betrag < 1e-9) return null;
  for (final m in Modus.values) {
    final l = m.lage;
    final c = komponente(l.ref, x, y, z);
    if (l.plus ? c <= 0 : c >= 0) continue;
    final winkel = math.acos((c.abs() / betrag).clamp(0.0, 1.0)) * 180 / math.pi;
    if (winkel <= kEindeutigGrad) return m;
  }
  return null;
}

/// Entscheidet mit Verzögerung, ob umgeschaltet wird.
/// Es wird nur umgeschaltet, wenn eine ANDERE Betriebsart als die aktuelle
/// ununterbrochen [kUmschaltSekunden] lang eindeutig erkannt wird. Ist die Lage
/// uneindeutig oder passt sie zur aktuellen Betriebsart, bleibt alles wie es ist
/// (das ist zugleich die Hysterese).
class ModusUmschalter {
  ModusUmschalter(this.aktuell, {this.verzoegerung = kUmschaltSekunden});

  Modus aktuell;
  final double verzoegerung;
  Modus? _kandidat;
  double _t = 0;

  /// Neuer Messschritt. Liefert die neue Betriebsart, wenn jetzt umgeschaltet wird, sonst null.
  Modus? update(double x, double y, double z, double dt) {
    final erkannt = erkenneLage(x, y, z);
    if (erkannt == null || erkannt == aktuell) {
      _kandidat = null;
      _t = 0;
      return null;
    }
    if (erkannt != _kandidat) {
      _kandidat = erkannt;
      _t = 0;
      return null;
    }
    _t += dt;
    if (_t >= verzoegerung) {
      aktuell = erkannt;
      _kandidat = null;
      _t = 0;
      return erkannt;
    }
    return null;
  }

  /// Wird bei manueller Wahl oder während der Kalibrierung benutzt.
  void setze(Modus m) {
    aktuell = m;
    _kandidat = null;
    _t = 0;
  }

  void zuruecksetzen() {
    _kandidat = null;
    _t = 0;
  }
}
