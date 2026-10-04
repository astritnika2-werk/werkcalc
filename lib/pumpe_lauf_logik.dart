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
/// Alle Schwellen sind interne experimentelle Richtwerte (noch keine echten
/// Messreihen mit laufenden/stehenden Pumpen) – keine Herstellervorgabe, keine Norm.

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

/// Kennwerte einer Messreihe (Rohwerte, ohne Filterung).
class Kennwerte {
  const Kennwerte(this.n, this.mittel, this.rms, this.min, this.max, this.streuung);
  final int n;
  final double mittel;
  final double rms; // Effektivwert der Rohwerte
  final double min;
  final double max;
  final double streuung; // Standardabweichung
}

Kennwerte kennwerte(List<double> x) {
  if (x.isEmpty) return const Kennwerte(0, 0, 0, 0, 0, 0);
  final m = mittelwert(x);
  var q = 0.0, d = 0.0;
  for (final v in x) {
    q += v * v;
    d += (v - m) * (v - m);
  }
  return Kennwerte(x.length, m, math.sqrt(q / x.length), x.reduce(math.min),
      x.reduce(math.max), math.sqrt(d / x.length));
}

class LaufMessung {
  const LaufMessung({required this.acc, required this.mag, this.dauerMs = 0});

  /// Tatsächliche Messdauer in Millisekunden (für die Abtastrate).
  final int dauerMs;

  /// Betrag der Beschleunigung ohne Schwerkraft (m/s²).
  final List<double> acc;

  /// Betrag des Magnetfelds (µT).
  final List<double> mag;

  double get accRms => schwankungRms(acc);
  double get magRms => schwankungRms(mag);
  double get accMittel => mittelwert(acc);
  Kennwerte get accKennwerte => kennwerte(acc);
  Kennwerte get magKennwerte => kennwerte(mag);
  double get accSpitze =>
      acc.isEmpty ? 0 : acc.reduce(math.max) - acc.reduce(math.min);

  /// Abtastrate in Hz (0, wenn Dauer unbekannt).
  double get rateAcc => dauerMs <= 0 ? 0 : acc.length * 1000 / dauerMs;
  double get rateMag => dauerMs <= 0 ? 0 : mag.length * 1000 / dauerMs;
}

/// Signalqualität nach Abtastrate (interne Richtwerte).
enum SignalGuete { gut, mittel, schwach }

SignalGuete signalGuete(double rateHz) =>
    rateHz >= 80 ? SignalGuete.gut : (rateHz >= 40 ? SignalGuete.mittel : SignalGuete.schwach);

/// Warum eine Messung nicht eindeutig ist.
enum LaufGrund { ok, zuWenigDaten, refUnruhig, handBewegt, nichtVergleichbar, schwach }

const kTextRefUnruhig =
    'Die Referenzmessung weist starke Schwankungen auf. Bitte Handy ruhig auf einen '
    'vibrationsarmen Untergrund legen und die Referenz wiederholen.';

/// Messstabilität der Referenz (Stufe 2 der Messqualität).
class StabilitaetsErgebnis {
  const StabilitaetsErgebnis(this.stabil, this.grund, [this.text = '']);
  final bool stabil;
  final LaufGrund grund;
  final String text;
}

StabilitaetsErgebnis bewerteReferenz(LaufMessung ref) {
  if (ref.acc.length < kLaufMinProben || ref.mag.length < kLaufMinProben) {
    return const StabilitaetsErgebnis(false, LaufGrund.zuWenigDaten,
        'Zu wenige Messwerte – Messung wiederholen (Sensoren des Handys liefern zu wenig Daten).');
  }
  if (ref.accRms > kLaufRefMaxAcc ||
      ref.magRms > kLaufRefMaxMag ||
      ref.accMittel > kLaufHandMaxAcc) {
    return const StabilitaetsErgebnis(false, LaufGrund.refUnruhig, kTextRefUnruhig);
  }
  return const StabilitaetsErgebnis(true, LaufGrund.ok);
}

/// Messstabilität an der Pumpe: nur Handbewegung (Mittelwert der Beschleunigung);
/// Vibration selbst ist hier erwünscht und wird nicht als Störung gewertet.
bool probeRuhigGehalten(LaufMessung p) => p.accMittel <= kLaufHandMaxAcc;

/// Vergleichbarkeit Referenz ↔ Pumpe: ähnliche Abtastrate beider Messungen.
bool vergleichbar(LaufMessung ref, LaufMessung p) {
  if (ref.dauerMs <= 0 || p.dauerMs <= 0) return true; // unbekannt
  double v(double a, double b) => b <= 0 ? 0 : a / b;
  final ra = v(ref.rateAcc, p.rateAcc), rm = v(ref.rateMag, p.rateMag);
  return ra >= 0.5 && ra <= 2 && rm >= 0.5 && rm <= 2;
}

class LaufErgebnis {
  const LaufErgebnis(this.status, this.grund,
      {this.verhaeltnisAcc, this.verhaeltnisMag, this.grundTyp = LaufGrund.ok});
  final LaufStatus status;
  final String grund;
  final LaufGrund grundTyp;
  final double? verhaeltnisAcc;
  final double? verhaeltnisMag;
}

LaufErgebnis bewerteLauf(LaufMessung ref, LaufMessung probe) {
  final st = bewerteReferenz(ref);
  if (!st.stabil) {
    return LaufErgebnis(LaufStatus.unklar, st.text, grundTyp: st.grund);
  }
  if (probe.acc.length < kLaufMinProben || probe.mag.length < kLaufMinProben) {
    return const LaufErgebnis(LaufStatus.unklar,
        'Zu wenige Messwerte – Messung wiederholen (Sensoren des Handys liefern zu wenig Daten).',
        grundTyp: LaufGrund.zuWenigDaten);
  }
  if (!probeRuhigGehalten(probe)) {
    return const LaufErgebnis(LaufStatus.unklar,
        'Handy wurde bewegt – fest an die Pumpe halten und Messung wiederholen.',
        grundTyp: LaufGrund.handBewegt);
  }
  if (!vergleichbar(ref, probe)) {
    return const LaufErgebnis(LaufStatus.unklar,
        'Referenz und Pumpenmessung sind nicht vergleichbar (stark unterschiedliche Abtastrate) – beide Messungen wiederholen.',
        grundTyp: LaufGrund.nichtVergleichbar);
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
      verhaeltnisAcc: ra, verhaeltnisMag: rm, grundTyp: LaufGrund.schwach);
}
