import 'dart:math' as math;

import 'pumpe_lauf_logik.dart' show LaufStatus;

/// Pumpe läuft prüfen – Schwingungsanalyse (reine Rechenlogik, ohne Sensor-Zugriff).
///
/// Idee: Eine laufende Umwälzpumpe schüttelt ihr Gehäuse mit einer gleichbleibenden,
/// schmalbandigen Schwingung (Drehfrequenz des Motors, meist im Bereich einiger 10 Hz).
/// Rauschen, Handzittern und Bewegungen sind dagegen breitbandig bzw. langsam. Deshalb
/// wird das Beschleunigungssignal (alle drei Achsen) über mehrere Sekunden in Abschnitten von
/// einer Sekunde spektral zerlegt (nicht-uniforme DFT mit Hann-Fenster, genutzt werden die
/// echten Zeitstempel der Sensorwerte). Entscheidend ist nicht ein einzelner Wert, sondern:
///  • Tonalität: Ragt eine Frequenz deutlich aus dem Rauschboden heraus?
///  • Überhöhung: Ist sie an der Pumpe deutlich stärker als in der Referenz (gleiche Frequenz)?
///  • Persistenz: Steht dieselbe Frequenz in der Mehrzahl der Abschnitte?
///  • Breitband: Ist das Rauschen an der Pumpe gegenüber der Referenz erhöht?
///
/// Wichtig: Das Verfahren misst Vibration. Es misst NICHT den Wasser-Volumenstrom und kann eine
/// Pumpe von einer anderen Maschine mit gleichbleibender Schwingung nicht sicher unterscheiden.
///
/// Alle Schwellen sind interne Richtwerte, an simulierten Signalen geprüft (Tests). Sie sind
/// keine Herstellervorgabe und keine Norm. Echte Messreihen mit laufenden und stehenden
/// Pumpen stehen noch aus.

const double kBandUntenHz = 15.0; // unter 15 Hz: Handzittern/Bewegung
const double kBandObenFaktor = 0.45; // obere Grenze = 0,45 × Abtastrate
const double kBandObenMaxHz = 120.0;
const double kLfUntenHz = 1.5; // Handbewegung: 1,5 … 8 Hz
const double kLfObenHz = 8.0;
const double kSegSek = 1.0;
const double kRasterHz = 0.5;
const int kMinProbenAnalyse = 64;
const double kMinDauerSek = 3.0;

const double kFsMinLaeuft = 80.0; // Hz: darunter keine Aussage
const double kFsMinSteht = 140.0; // Hz: „steht“ nur, wenn das Frequenzband breit genug abgedeckt ist
const double kRefLfMax = 0.08; // m/s², Referenz muss ruhig liegen
const double kProbeLfMax = 0.5; // m/s², Handbewegung an der Pumpe
const double kTonLaeuft = 5.0; // Spitze ≥ 5 × Median des Rauschbodens (≈ 7 dB)
const double kUeberLaeuft = 4.0; // Spitze ≥ 4 × Referenz (≈ 6 dB)
const double kPersistLaeuft = 0.6; // in ≥ 60 % der Abschnitte vorhanden
const double kAmpMin = 0.004; // m/s² (rms) absolute Mindeststärke der Spitze
const double kUeberSteht = 2.0; // alle auffälligen Töne < 2 × Referenz
const double kBreitSteht = 1.8; // Rauschen an der Pumpe < 1,8 × Referenz
const double kNachweisGrenze = 0.03; // m/s² (rms): größer → „steht“ nicht belastbar

/// Sensorsignal aus drei Achsen mit Zeitstempeln (Sekunden, aufsteigend).
class PumpeSignal {
  PumpeSignal({required this.t, required this.x, required this.y, required this.z});
  final List<double> t;
  final List<double> x;
  final List<double> y;
  final List<double> z;
  int get n => t.length;

  /// Prüft die Zeitstempel; sind sie unbrauchbar (nicht aufsteigend, Dauer weicht stark von der
  /// gestoppten Dauer ab), werden gleichmäßige Zeitstempel über die gestoppte Dauer angenommen.
  PumpeSignal bereinigt(int dauerMs) {
    final n = t.length;
    if (n < 2) return this;
    final stopp = dauerMs / 1000.0;
    var ok = true;
    for (var i = 1; i < n; i++) {
      if (t[i] < t[i - 1]) {
        ok = false;
        break;
      }
    }
    final span = t.last - t.first;
    if (span <= 0) ok = false;
    if (ok && stopp > 0 && (span < stopp * 0.6 || span > stopp * 1.4)) ok = false;
    if (ok) return this;
    final dauer = stopp > 0 ? stopp : n / 100.0;
    return PumpeSignal(
      t: [for (var i = 0; i < n; i++) dauer * i / (n - 1)],
      x: x,
      y: y,
      z: z,
    );
  }
}

/// Ergebnis der Spektralanalyse einer Messung.
class Spektrum {
  const Spektrum({
    required this.gueltig,
    required this.n,
    required this.dauer,
    required this.fs,
    required this.nSeg,
    this.f = const [],
    this.p = const [],
    this.pSeg = const [],
    this.lfRms = 0,
    this.median = 0,
    this.mittel = 0,
  });

  final bool gueltig;
  final int n;
  final double dauer; // s
  final double fs; // Hz (mittlere Abtastrate)
  final int nSeg;

  /// Frequenzraster des Pumpenbands (Hz).
  final List<double> f;

  /// Mittlere Leistung je Frequenz (m/s²)², Summe über die drei Achsen (Sinus: Amplitude²/2).
  final List<double> p;

  /// Leistung je Abschnitt und Frequenz.
  final List<List<double>> pSeg;

  /// Handbewegungs-Anteil (1,5 … 8 Hz) in m/s² (rms der stärksten Frequenz).
  final double lfRms;

  /// Median der Bandleistung = Rauschboden je Frequenzpunkt.
  final double median;

  /// Mittlere Bandleistung (Breitbandmaß).
  final double mittel;

  /// Stärkste Frequenz im Band.
  int get spitzeIndex {
    var k = 0;
    for (var i = 1; i < p.length; i++) {
      if (p[i] > p[k]) k = i;
    }
    return k;
  }

  double get spitzeHz => p.isEmpty ? 0 : f[spitzeIndex];
  double get spitzeRms => p.isEmpty ? 0 : math.sqrt(p[spitzeIndex]);

  /// Kleinste Spitze (rms), die sich noch vom Rauschboden abhebt (Tonalität = [kTonLaeuft]).
  double get nachweisGrenze => math.sqrt(kTonLaeuft * median);

  /// Breitband-Schwankung im Pumpenband (rms, m/s²), grobe Kenngröße für die Anzeige.
  double get bandRms => math.sqrt(mittel * p.length * kRasterHz / (1.0 / kSegSek) / 1.5);
}

double _median(List<double> x) {
  final s = List<double>.of(x)..sort();
  final n = s.length;
  if (n == 0) return 0;
  return n.isOdd ? s[n ~/ 2] : (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2;
}

/// Spektralanalyse (nicht-uniforme DFT, 1-s-Abschnitte mit 50 % Überlappung, Hann-Fenster).
Spektrum analysiere(PumpeSignal s) {
  final n = s.n;
  if (n < 2) return Spektrum(gueltig: false, n: n, dauer: 0, fs: 0, nSeg: 0);
  final t = s.t;
  final dur = t.last - t.first;
  if (n < kMinProbenAnalyse || dur < kMinDauerSek) {
    return Spektrum(gueltig: false, n: n, dauer: dur, fs: dur <= 0 ? 0 : (n - 1) / dur, nSeg: 0);
  }
  final fs = (n - 1) / dur;
  final hi = math.min(kBandObenFaktor * fs, kBandObenMaxHz);

  final fl = <double>[for (var f = kLfUntenHz; f <= kLfObenHz + 1e-9; f += kRasterHz) f];
  final fb = <double>[for (var f = kBandUntenHz; f <= hi + 1e-9; f += kRasterHz) f];
  final fall = <double>[...fl, ...fb];

  final nSegMax = ((dur - kSegSek) / (kSegSek / 2)).floor() + 1;
  final segs = <List<double>>[];
  final t0 = t.first;
  for (var sg = 0; sg < nSegMax; sg++) {
    final a = t0 + sg * kSegSek / 2;
    final b = a + kSegSek;
    // Indizes der Werte im Zeitfenster [a, b)
    var i0 = 0;
    while (i0 < n && t[i0] < a) {
      i0++;
    }
    var i1 = i0;
    while (i1 < n && t[i1] < b) {
      i1++;
    }
    final cnt = i1 - i0;
    if (cnt < 0.6 * fs * kSegSek || cnt < 8) continue;
    final tt = List<double>.generate(cnt, (i) => t[i0 + i] - a);
    final w = List<double>.generate(cnt, (i) => 0.5 - 0.5 * math.cos(2 * math.pi * tt[i] / kSegSek));
    var s1 = 0.0;
    for (final v in w) {
      s1 += v;
    }
    if (s1 <= 0) continue;
    // Gewichteten Mittelwert (Schwerkraft/Gleichanteil) je Achse entfernen.
    List<double> zentriert(List<double> v) {
      var m = 0.0;
      for (var i = 0; i < cnt; i++) {
        m += w[i] * v[i0 + i];
      }
      m /= s1;
      return List<double>.generate(cnt, (i) => w[i] * (v[i0 + i] - m));
    }

    final wx = zentriert(s.x), wy = zentriert(s.y), wz = zentriert(s.z);
    final leistung = List<double>.filled(fall.length, 0);
    for (var k = 0; k < fall.length; k++) {
      final om = 2 * math.pi * fall[k];
      var rx = 0.0, ix = 0.0, ry = 0.0, iy = 0.0, rz = 0.0, iz = 0.0;
      for (var i = 0; i < cnt; i++) {
        final ang = om * tt[i];
        final c = math.cos(ang), sn = math.sin(ang);
        rx += wx[i] * c;
        ix += wx[i] * sn;
        ry += wy[i] * c;
        iy += wy[i] * sn;
        rz += wz[i] * c;
        iz += wz[i] * sn;
      }
      // Sinus-Amplitude A = 2|X|/ΣW, Leistung A²/2 = 2|X|²/ΣW².
      final q = 2.0 / (s1 * s1);
      leistung[k] = q * (rx * rx + ix * ix + ry * ry + iy * iy + rz * rz + iz * iz);
    }
    segs.add(leistung);
  }
  if (segs.length < 3) {
    return Spektrum(gueltig: false, n: n, dauer: dur, fs: fs, nSeg: segs.length);
  }

  final nl = fl.length;
  final nb = fb.length;
  // Handbewegung: stärkste Frequenz im LF-Band (Mittel über die Abschnitte).
  var lfMax = 0.0;
  for (var k = 0; k < nl; k++) {
    var m = 0.0;
    for (final sg in segs) {
      m += sg[k];
    }
    m /= segs.length;
    if (m > lfMax) lfMax = m;
  }
  final pSeg = <List<double>>[
    for (final sg in segs) sg.sublist(nl),
  ];
  final avg = List<double>.filled(nb, 0);
  for (final sg in pSeg) {
    for (var k = 0; k < nb; k++) {
      avg[k] += sg[k];
    }
  }
  var summe = 0.0;
  for (var k = 0; k < nb; k++) {
    avg[k] /= pSeg.length;
    summe += avg[k];
  }
  return Spektrum(
    gueltig: true,
    n: n,
    dauer: dur,
    fs: fs,
    nSeg: segs.length,
    f: fb,
    p: avg,
    pSeg: pSeg,
    lfRms: math.sqrt(lfMax),
    median: _median(avg),
    mittel: summe / nb,
  );
}

/// Warum eine Messung nicht eindeutig ist.
enum PumpeGrund { ok, zuWenigDaten, abtastrate, refUnruhig, bewegt, empfindlichkeit, schwach }

/// Auffällige Spitze im Spektrum der Messung an der Pumpe.
class Spitze {
  const Spitze(this.index, this.hz, this.tonalitaet, this.ueberhoehung, this.rms);
  final int index;
  final double hz;
  final double tonalitaet; // × Rauschboden
  final double ueberhoehung; // × Referenz (gleiche Frequenz)
  final double rms; // m/s²
}

/// Größte Leistung der Referenz im Umkreis von ±[tol] Hz um [hz] (0, wenn außerhalb des Bands).
double referenzNahe(Spektrum ref, double hz, [double tol = 1.0]) {
  var m = 0.0;
  for (var i = 0; i < ref.f.length; i++) {
    if ((ref.f[i] - hz).abs() <= tol && ref.p[i] > m) m = ref.p[i];
  }
  return m;
}

/// Alle lokalen Spitzen der Probe mit Tonalität ≥ 3 (gegenüber dem Rauschboden).
List<Spitze> findeSpitzen(Spektrum ref, Spektrum probe) {
  final b = probe.p;
  final med = math.max(probe.median, 1e-18);
  final out = <Spitze>[];
  for (var k = 1; k < b.length - 1; k++) {
    if (!(b[k] >= b[k - 1] && b[k] >= b[k + 1])) continue;
    final ton = b[k] / med;
    if (ton < 3.0) continue;
    final denom = math.max(math.max(referenzNahe(ref, probe.f[k]), ref.median), math.max(med, 1e-18));
    out.add(Spitze(k, probe.f[k], ton, b[k] / denom, math.sqrt(b[k])));
  }
  return out;
}

/// Anteil der Abschnitte, in denen um die Frequenz [k] (±1 Hz) eine Spitze ≥ 3 × Median des Abschnitts liegt.
double persistenz(Spektrum probe, int k) {
  if (probe.pSeg.isEmpty) return 0;
  var cnt = 0;
  for (final row in probe.pSeg) {
    final med = _median(row);
    var m = 0.0;
    for (var i = 0; i < row.length; i++) {
      if ((probe.f[i] - probe.f[k]).abs() <= 1.0 && row[i] > m) m = row[i];
    }
    if (m >= 3.0 * med) cnt++;
  }
  return cnt / probe.pSeg.length;
}

class PumpeBefund {
  const PumpeBefund({
    required this.status,
    required this.grund,
    required this.text,
    this.spitzeHz,
    this.spitzeRms,
    this.tonalitaet,
    this.ueberhoehung,
    this.persistenzAnteil,
    this.breitband,
    this.nachweisGrenze,
  });

  final LaufStatus status;
  final PumpeGrund grund;
  final String text;
  final double? spitzeHz;
  final double? spitzeRms; // m/s²
  final double? tonalitaet;
  final double? ueberhoehung;
  final double? persistenzAnteil;
  final double? breitband; // Rauschen Pumpe / Referenz
  final double? nachweisGrenze; // m/s²
}

const String kTextTonErkannt =
    'An der Pumpe wurde eine gleichbleibende Schwingung gefunden, die in der Referenz nicht vorhanden '
    'ist. Das ist ein Hinweis auf einen laufenden Motor. Der Wasser-Volumenstrom wird dabei nicht gemessen.';
const String kTextKeinTon =
    'An der Pumpe wurde keine gleichbleibende Schwingung gefunden, die über der Referenz liegt. '
    'Voraussetzung: festes Anlegen des Handys am Pumpenmotor. Eine sehr schwach vibrierende Pumpe '
    'lässt sich so nicht ausschließen.';
const String kTextZuWenig =
    'Zu wenige Messwerte – Messung wiederholen (der Sensor des Handys liefert zu wenig Daten).';
const String kTextRate =
    'Der Sensor dieses Handys liefert zu wenig Messwerte pro Sekunde, um das Frequenzband der Pumpe '
    'vollständig abzudecken. „Pumpe steht“ kann deshalb nicht belastbar gemeldet werden.';
const String kTextRefUnruhig =
    'Die Referenzmessung weist Bewegungen auf. Bitte das Handy ruhig auf einen festen Untergrund legen '
    'und die Referenz wiederholen.';
const String kTextBewegt =
    'Das Handy wurde an der Pumpe stark bewegt. Bitte fest an das Gehäuse drücken, ruhig halten und '
    'die Messung wiederholen.';
const String kTextEmpfindlichkeit =
    'Das Sensorrauschen ist zu hoch, um eine schwache Pumpenvibration sicher auszuschließen. '
    'Bitte Handy fester an den Motor drücken und erneut messen.';
const String kTextSchwach =
    'Das Signal ist nicht eindeutig (schwache oder wechselnde Schwingung). Bitte fester an den Motor '
    'drücken und erneut messen.';

/// Stufe 1: Referenzmessung ausreichend ruhig?
({bool ok, PumpeGrund grund, String text}) bewerteReferenzSpektrum(Spektrum ref) {
  if (!ref.gueltig) {
    return (ok: false, grund: PumpeGrund.zuWenigDaten, text: kTextZuWenig);
  }
  if (ref.lfRms > kRefLfMax) {
    return (ok: false, grund: PumpeGrund.refUnruhig, text: kTextRefUnruhig);
  }
  return (ok: true, grund: PumpeGrund.ok, text: '');
}

/// Gesamtbewertung: Referenz gegen Messung an der Pumpe.
PumpeBefund bewertePumpe(Spektrum ref, Spektrum probe) {
  PumpeBefund unklar(PumpeGrund g, String text, {Spitze? sp, double? breit}) => PumpeBefund(
        status: LaufStatus.unklar,
        grund: g,
        text: text,
        spitzeHz: sp?.hz,
        spitzeRms: sp?.rms,
        tonalitaet: sp?.tonalitaet,
        ueberhoehung: sp?.ueberhoehung,
        breitband: breit,
        nachweisGrenze: probe.gueltig ? probe.nachweisGrenze : null,
      );

  final r = bewerteReferenzSpektrum(ref);
  if (!r.ok) return unklar(r.grund, r.text);
  if (!probe.gueltig) return unklar(PumpeGrund.zuWenigDaten, kTextZuWenig);
  if (ref.fs < kFsMinLaeuft || probe.fs < kFsMinLaeuft) return unklar(PumpeGrund.abtastrate, kTextRate);
  if (probe.lfRms > kProbeLfMax) return unklar(PumpeGrund.bewegt, kTextBewegt);

  final spitzen = findeSpitzen(ref, probe)..sort((a, b) => b.ueberhoehung.compareTo(a.ueberhoehung));
  final breit = probe.mittel / math.max(ref.mittel, 1e-18);

  for (final c in spitzen) {
    if (c.tonalitaet >= kTonLaeuft && c.ueberhoehung >= kUeberLaeuft && c.rms >= kAmpMin) {
      final pers = persistenz(probe, c.index);
      if (pers >= kPersistLaeuft) {
        return PumpeBefund(
          status: LaufStatus.laeuft,
          grund: PumpeGrund.ok,
          text: kTextTonErkannt,
          spitzeHz: c.hz,
          spitzeRms: c.rms,
          tonalitaet: c.tonalitaet,
          ueberhoehung: c.ueberhoehung,
          persistenzAnteil: pers,
          breitband: breit,
          nachweisGrenze: probe.nachweisGrenze,
        );
      }
    }
  }

  final besteSpitze = spitzen.isEmpty ? null : spitzen.first;
  final keinNeuerTon = spitzen.every((c) => c.ueberhoehung < kUeberSteht);
  if (keinNeuerTon && breit <= kBreitSteht) {
    if (math.min(ref.fs, probe.fs) < kFsMinSteht) return unklar(PumpeGrund.abtastrate, kTextRate, sp: besteSpitze, breit: breit);
    if (probe.nachweisGrenze > kNachweisGrenze) {
      return unklar(PumpeGrund.empfindlichkeit, kTextEmpfindlichkeit, sp: besteSpitze, breit: breit);
    }
    return PumpeBefund(
      status: LaufStatus.steht,
      grund: PumpeGrund.ok,
      text: kTextKeinTon,
      spitzeHz: probe.spitzeHz,
      spitzeRms: probe.spitzeRms,
      breitband: breit,
      nachweisGrenze: probe.nachweisGrenze,
    );
  }
  return unklar(PumpeGrund.schwach, kTextSchwach, sp: besteSpitze, breit: breit);
}

// ───────────────────── Direkte Erkennung (ohne Referenzmessung) ─────────────────────

const double kTonSteht = 4.0; // Direktmodus: alle Spitzen < 4 × Rauschboden → keine Pumpenvibration
const String kTextDirektLaeuft = 'Zirkulation erkannt';
const String kTextDirektSteht = 'Keine typische Pumpenvibration erkannt';
const String kTextDirektNaeher = 'Bitte Smartphone näher an die Pumpe halten';
const String kTextDirektRuhig = 'Bitte Smartphone ruhig und fest an die Pumpe halten';

/// Bewertung eines einzelnen Messfensters ohne Referenz. Statt einer Referenz dient der eigene
/// Rauschboden (Median des Spektrums) als Maßstab. Gleichbleibende Fremdvibration (andere Maschine,
/// Untergrund) lässt sich so nicht von der Pumpe trennen – das ist eine Grenze des Verfahrens.
PumpeBefund bewertePumpeDirekt(Spektrum probe) {
  PumpeBefund unklar(PumpeGrund g, String text, {Spitze? sp}) => PumpeBefund(
        status: LaufStatus.unklar,
        grund: g,
        text: text,
        spitzeHz: sp?.hz,
        spitzeRms: sp?.rms,
        tonalitaet: sp?.tonalitaet,
        ueberhoehung: sp?.ueberhoehung,
        nachweisGrenze: probe.gueltig ? probe.nachweisGrenze : null,
      );
  if (!probe.gueltig) return unklar(PumpeGrund.zuWenigDaten, kTextZuWenig);
  if (probe.fs < kFsMinLaeuft) return unklar(PumpeGrund.abtastrate, kTextRate);
  if (probe.lfRms > kProbeLfMax) return unklar(PumpeGrund.bewegt, kTextDirektRuhig);

  final med = math.max(probe.median, 1e-18);
  final b = probe.p;
  final spitzen = <Spitze>[];
  for (var k = 1; k < b.length - 1; k++) {
    if (!(b[k] >= b[k - 1] && b[k] >= b[k + 1])) continue;
    final ton = b[k] / med;
    if (ton < 3.0) continue;
    spitzen.add(Spitze(k, probe.f[k], ton, ton, math.sqrt(b[k])));
  }
  spitzen.sort((a, c) => c.tonalitaet.compareTo(a.tonalitaet));

  for (final c in spitzen) {
    if (c.tonalitaet >= kTonLaeuft && c.rms >= kAmpMin) {
      final pers = persistenz(probe, c.index);
      if (pers >= kPersistLaeuft) {
        return PumpeBefund(
          status: LaufStatus.laeuft,
          grund: PumpeGrund.ok,
          text: kTextDirektLaeuft,
          spitzeHz: c.hz,
          spitzeRms: c.rms,
          tonalitaet: c.tonalitaet,
          ueberhoehung: c.ueberhoehung,
          persistenzAnteil: pers,
          nachweisGrenze: probe.nachweisGrenze,
        );
      }
    }
  }
  if (spitzen.every((c) => c.tonalitaet < kTonSteht)) {
    if (probe.fs < kFsMinSteht) return unklar(PumpeGrund.abtastrate, kTextRate);
    if (probe.nachweisGrenze > kNachweisGrenze) {
      return unklar(PumpeGrund.empfindlichkeit, kTextDirektNaeher);
    }
    return PumpeBefund(
      status: LaufStatus.steht,
      grund: PumpeGrund.ok,
      text: kTextDirektSteht,
      spitzeHz: probe.spitzeHz,
      spitzeRms: probe.spitzeRms,
      nachweisGrenze: probe.nachweisGrenze,
    );
  }
  return unklar(PumpeGrund.schwach, kTextDirektNaeher, sp: spitzen.first);
}
