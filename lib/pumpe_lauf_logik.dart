import 'dart:math' as math;

/// Pumpe läuft prüfen – reine Entscheidungslogik (ohne Sensor-Zugriff).
///
/// Prinzip: Zuerst wird eine Referenz fern von der Pumpe gemessen, dann direkt
/// an der Pumpe. Verglichen werden die Schwankungen (nach Abzug des
/// langsamen Anteils) von Vibration (Beschleunigung ohne Schwerkraft) und
/// Magnetfeldbetrag. „läuft“ wird nur gemeldet, wenn die Sensoren eindeutig
/// über der Referenz und über dem Sensorrauschen liegen. Alles andere ist
/// „nicht eindeutig“.
///
/// Alle Schwellen sind interne Richtwerte – keine Herstellervorgabe, keine Norm.

const double kLaufRauschAcc = 0.005; // m/s², Sensorrauschen (Richtwert)
const double kLaufRauschMag = 0.15; // µT, Sensorrauschen (Richtwert)
const double kLaufVerhaeltnisStark = 3.0;
const double kLaufVerhaeltnisSehrStark = 8.0;
const double kLaufVerhaeltnisKeins = 1.5;
const double kLaufRefMaxAcc = 0.03; // Referenz darf nicht selbst unruhig sein
const double kLaufRefMaxMag = 1.0;
const double kLaufHandMaxAcc = 0.5; // Mittelwert der Beschleunigung = Handbewegung
const int kLaufMinProben = 100;

enum LaufStatus { laeuft, steht, unklar }

/// Schwankungsanteil: Effektivwert nach Abzug des gleitenden Mittelwerts.
double schwankungRms(List<double> x, {int fenster = 9}) {
  if (x.length < fenster * 2) return 0;
  var sum = 0.0;
  for (var i = 0; i < x.length; i++) {
    final a = math.max(0, i - fenster ~/ 2);
    final b = math.min(x.length - 1, i + fenster ~/ 2);
    var m = 0.0;
    for (var j = a; j <= b; j++) {
      m += x[j];
    }
    m /= (b - a + 1);
    final d = x[i] - m;
    sum += d * d;
  }
  return math.sqrt(sum / x.length);
}

double mittelwert(List<double> x) =>
    x.isEmpty ? 0 : x.reduce((a, b) => a + b) / x.length;

class LaufMessung {
  const LaufMessung({required this.acc, required this.mag});

  /// Betrag der Beschleunigung ohne Schwerkraft (m/s²).
  final List<double> acc;

  /// Betrag des Magnetfelds (µT).
  final List<double> mag;

  double get accRms => schwankungRms(acc);
  double get magRms => schwankungRms(mag);
  double get accMittel => mittelwert(acc);
}

class LaufErgebnis {
  const LaufErgebnis(this.status, this.grund,
      {this.verhaeltnisAcc, this.verhaeltnisMag});
  final LaufStatus status;
  final String grund;
  final double? verhaeltnisAcc;
  final double? verhaeltnisMag;
}

LaufErgebnis bewerteLauf(LaufMessung ref, LaufMessung probe) {
  if (ref.acc.length < kLaufMinProben ||
      ref.mag.length < kLaufMinProben ||
      probe.acc.length < kLaufMinProben ||
      probe.mag.length < kLaufMinProben) {
    return const LaufErgebnis(LaufStatus.unklar,
        'Zu wenige Messwerte – Messung wiederholen (Sensoren des Handys liefern zu wenig Daten).');
  }
  if (ref.accRms > kLaufRefMaxAcc || ref.magRms > kLaufRefMaxMag) {
    return const LaufErgebnis(LaufStatus.unklar,
        'Referenz zu unruhig – weiter weg von der Pumpe und ruhig halten, dann wiederholen.');
  }
  if (probe.accMittel > kLaufHandMaxAcc || ref.accMittel > kLaufHandMaxAcc) {
    return const LaufErgebnis(LaufStatus.unklar,
        'Handy wurde bewegt – fest an die Pumpe halten und Messung wiederholen.');
  }
  final ra = probe.accRms / math.max(ref.accRms, kLaufRauschAcc);
  final rm = probe.magRms / math.max(ref.magRms, kLaufRauschMag);

  final stark = ra >= kLaufVerhaeltnisStark && rm >= kLaufVerhaeltnisStark;
  final einsSehrStark = (ra >= kLaufVerhaeltnisSehrStark && rm >= 2.0) ||
      (rm >= kLaufVerhaeltnisSehrStark && ra >= 2.0);
  if (stark || einsSehrStark) {
    return LaufErgebnis(LaufStatus.laeuft,
        'Vibration und Magnetfeld zeigen deutlich mehr Schwankung als die Referenz.',
        verhaeltnisAcc: ra, verhaeltnisMag: rm);
  }
  if (ra <= kLaufVerhaeltnisKeins && rm <= kLaufVerhaeltnisKeins) {
    return LaufErgebnis(LaufStatus.steht,
        'Weder Vibration noch Magnetfeld liegen über der Referenz. Voraussetzung: Handy hatte festen Kontakt zur Pumpe.',
        verhaeltnisAcc: ra, verhaeltnisMag: rm);
  }
  return LaufErgebnis(LaufStatus.unklar,
      'Signal nicht stark genug für eine sichere Aussage – Messung wiederholen.',
      verhaeltnisAcc: ra, verhaeltnisMag: rm);
}
