import 'dart:math' as math;

/// Wasserwaage – Orientierungsberechnung, unabhängig von Bildschirmlage.
///
/// Grundlage ist der Schwerkraftvektor g = (x, y, z) im Gerätekoordinatensystem
/// (Android: x → rechte Kante, y → Oberkante, z → aus dem Display). Der Sensor
/// liefert die Gegenkraft zur Schwerkraft, also den Vektor „nach oben“. Eine
/// positive Komponente bedeutet daher: das positive Ende dieser Achse liegt höher.
///
/// Die Achse mit dem größten Betrag ist die Referenzachse (die Achse, die gerade
/// „senkrecht“ steht). Die beiden anderen Achsen sind die Neigungsachsen a und b:
///   Referenz z (Handy liegt flach):        a = x, b = y
///   Referenz y (Handy steht aufrecht):     a = x, b = z
///   Referenz x (Handy liegt auf der Seite): a = y, b = z
/// So funktioniert die Messung in jeder Lage; es wird nichts aus der
/// Bildschirmdrehung abgeleitet.

enum Achse { x, y, z }

double _grad(double rad) => rad * 180 / math.pi;
double _rad(double grad) => grad * math.pi / 180;

double komponente(Achse a, double x, double y, double z) => switch (a) {
      Achse.x => x,
      Achse.y => y,
      Achse.z => z,
    };

/// Lage des Handys: welche Achse steht senkrecht und in welche Richtung.
class Lage {
  const Lage(this.ref, this.plus);

  final Achse ref;

  /// true: das positive Ende der Referenzachse zeigt nach oben.
  final bool plus;

  Achse get a => switch (ref) {
        Achse.z => Achse.x,
        Achse.y => Achse.x,
        Achse.x => Achse.y,
      };

  Achse get b => switch (ref) {
        Achse.z => Achse.y,
        Achse.y => Achse.z,
        Achse.x => Achse.z,
      };

  String get schluessel => '${ref.name}${plus ? '+' : '-'}';

  String get beschreibung => switch ((ref, plus)) {
        (Achse.z, true) => 'Handy liegt flach (Display oben)',
        (Achse.z, false) => 'Handy liegt flach (Display unten)',
        (Achse.y, true) => 'Handy steht aufrecht (Oberkante oben)',
        (Achse.y, false) => 'Handy steht kopfüber (Unterkante oben)',
        (Achse.x, true) => 'Handy liegt auf der linken Seite',
        (Achse.x, false) => 'Handy liegt auf der rechten Seite',
      };

  /// Name der Handy-Seite am positiven bzw. negativen Ende der Achse [achse].
  String seite(Achse achse, bool positiv) => switch ((achse, positiv)) {
        (Achse.x, true) => 'Rechts',
        (Achse.x, false) => 'Links',
        (Achse.y, true) => ref == Achse.z ? 'Vorne' : 'Oberkante',
        (Achse.y, false) => ref == Achse.z ? 'Hinten' : 'Unterkante',
        (Achse.z, true) => 'Display',
        (Achse.z, false) => 'Rückseite',
      };

  /// Beschriftung der beiden Neigungsachsen.
  String get titelA => _titel(a);
  String get titelB => _titel(b);

  String _titel(Achse achse) => switch (achse) {
        Achse.x => 'X (links/rechts)',
        Achse.y => ref == Achse.z ? 'Y (vorne/hinten)' : 'Y (Ober-/Unterkante)',
        Achse.z => 'Z (Display/Rückseite)',
      };
}

/// Referenzachse = Achse mit dem größten Betrag (bei Gleichstand z, dann y, dann x).
Lage bestimmeLage(double x, double y, double z) {
  final ax = x.abs(), ay = y.abs(), az = z.abs();
  if (az >= ay && az >= ax) return Lage(Achse.z, z >= 0);
  if (ay >= ax) return Lage(Achse.y, y >= 0);
  return Lage(Achse.x, x >= 0);
}

class Neigung {
  const Neigung({
    required this.lage,
    required this.aGrad,
    required this.bGrad,
    required this.gesamtGrad,
    required this.prozent,
    required this.mmProM,
    required this.sx,
    required this.sy,
    required this.gueltig,
  });

  final Lage lage;

  /// Neigung um Achse a / b in Grad (positiv: das positive Ende der Achse liegt höher),
  /// nach Abzug der Kalibrierung.
  final double aGrad;
  final double bGrad;

  /// Winkel der Referenzachse gegen die Senkrechte (Gesamtneigung).
  final double gesamtGrad;
  final double prozent; // Gefälle in %
  final double mmProM; // Gefälle in mm/m

  /// Steigungsvektor (tan der Achswinkel). Aus ihm folgen Zahlen UND Blase.
  final double sx;
  final double sy;

  /// false, wenn kein sinnvoller Schwerkraftvektor vorliegt (Betrag 0).
  final bool gueltig;
}

Neigung berechneNeigung(
  double x,
  double y,
  double z, {
  Lage? lage,
  double a0 = 0,
  double b0 = 0,
}) {
  final l = lage ?? bestimmeLage(x, y, z);
  final ref = komponente(l.ref, x, y, z).abs();
  if (ref < 1e-9) {
    return Neigung(
        lage: l, aGrad: 0, bGrad: 0, gesamtGrad: 0, prozent: 0, mmProM: 0, sx: 0, sy: 0, gueltig: false);
  }
  final wa = _grad(math.atan2(komponente(l.a, x, y, z), ref)) - a0;
  final wb = _grad(math.atan2(komponente(l.b, x, y, z), ref)) - b0;
  final sx = math.tan(_rad(wa));
  final sy = math.tan(_rad(wb));
  final steigung = math.sqrt(sx * sx + sy * sy);
  return Neigung(
    lage: l,
    aGrad: wa,
    bGrad: wb,
    gesamtGrad: _grad(math.atan(steigung)),
    prozent: steigung * 100,
    mmProM: steigung * 1000,
    sx: sx,
    sy: sy,
    gueltig: true,
  );
}

class Kalibrierung {
  const Kalibrierung(this.lage, this.a0, this.b0, this.streuungGrad);
  final Lage lage;
  final double a0;
  final double b0;

  /// Streuung (Standardabweichung) der Winkel während der Kalibrierung, in Grad.
  final double streuungGrad;
}

/// Interner Richtwert: bewegt sich das Handy beim Kalibrieren stärker, wird
/// die Kalibrierung verworfen (keine Herstellervorgabe, keine Norm).
const double kKalibrierMaxStreuung = 0.3;

typedef Vek = ({double x, double y, double z});

/// Kalibrierung für die Lage, in der das Handy beim Kalibrieren liegt.
/// Mindestens 10 Proben mit Schwerkraftvektor.
Kalibrierung? kalibriere(List<Vek> proben, {Lage? lage}) {
  final gut = proben.where((p) => p.x * p.x + p.y * p.y + p.z * p.z > 1e-12).toList();
  if (gut.length < 10) return null;
  final mx = gut.map((p) => p.x).reduce((a, b) => a + b) / gut.length;
  final my = gut.map((p) => p.y).reduce((a, b) => a + b) / gut.length;
  final mz = gut.map((p) => p.z).reduce((a, b) => a + b) / gut.length;
  final l = lage ?? bestimmeLage(mx, my, mz);
  final aw = <double>[], bw = <double>[];
  for (final p in gut) {
    final n = berechneNeigung(p.x, p.y, p.z, lage: l);
    aw.add(n.aGrad);
    bw.add(n.bGrad);
  }
  double mw(List<double> l) => l.reduce((a, b) => a + b) / l.length;
  double sd(List<double> l) {
    final m = mw(l);
    return math.sqrt(l.map((v) => (v - m) * (v - m)).reduce((a, b) => a + b) / l.length);
  }

  return Kalibrierung(l, mw(aw), mw(bw), math.max(sd(aw), sd(bw)));
}

/// Größte Neigung einer Achse innerhalb einer Lage: atan(√2) ≈ 54,7°
/// (dann sind zwei Achsen gleich groß und die Lage wechselt).
final double kMaxGradImLage = _grad(math.atan(math.sqrt(2)));

/// Darstellung einer Neigung (Grad) auf einer Anzeigeachse, 0…1.
/// Rein geometrisch: 0° → 0, größte Neigung der Lage → 1; dazwischen
/// Wurzel-Skala, damit kleine Neigungen sichtbar sind und der ganze Bereich
/// durchgehend (ohne Anschlag) dargestellt wird. Verändert keinen Messwert.
double anzeigeSkala(double grad) => math.sqrt((grad.abs() / kMaxGradImLage).clamp(0.0, 1.0));

/// Lage der Blase im Kreis (−1…1; Display: x rechts, y nach unten).
/// Kommt aus derselben Rechnung wie die Zahlen (Steigungsvektor sx, sy):
/// Richtung = Richtung der höheren Seite (wie bei einer echten Libelle),
/// Abstand = anzeigeSkala(Gesamtneigung).
///  a-Seite höher → nach rechts, b-Seite höher → nach oben.
({double dx, double dy}) blasenPosition(Neigung n) {
  final len = math.sqrt(n.sx * n.sx + n.sy * n.sy);
  if (len == 0) return (dx: 0, dy: 0);
  final f = anzeigeSkala(n.gesamtGrad);
  return (dx: n.sx / len * f, dy: -n.sy / len * f);
}

/// Anzeige einer Achsen-Neigung (Grad) auf einer Leiste, −1…1 (Vorzeichen bleibt).
double leistenPosition(double grad) => grad.isNegative ? -anzeigeSkala(grad) : anzeigeSkala(grad);

/// Glättung des Schwerkraftvektors. Der Beschleunigungssensor misst auch Hand-
/// bewegungen und rauscht; deshalb wird er mit dem Gyroskop gestützt:
///  1. Vorhersage: der Vektor wird mit der gemessenen Drehrate mitgedreht
///     (dg/dt = −ω × g). Das folgt Drehungen ohne Verzögerung und ohne Rauschen.
///  2. Korrektur: langsam zum Beschleunigungsmesswert hin (Zeitkonstante tau),
///     damit Drift und Fehler verschwinden. Im Ruhezustand ist das Ergebnis
///     exakt der Messwert (kein Versatz).
/// Ohne Gyroskop wird nur der Beschleunigungsmesswert mit kürzerem tau geglättet.
class GravityFilter {
  GravityFilter({this.tauMitGyro = 0.5, this.tauOhneGyro = 0.15});

  final double tauMitGyro;
  final double tauOhneGyro;

  double x = 0, y = 0, z = 0;
  bool initialisiert = false;

  void reset() => initialisiert = false;

  /// [dt] in Sekunden seit dem letzten Aufruf. [gx..gz]: Drehrate in rad/s (oder null).
  void update({
    required double ax,
    required double ay,
    required double az,
    required double dt,
    double? gx,
    double? gy,
    double? gz,
  }) {
    if (!initialisiert) {
      x = ax;
      y = ay;
      z = az;
      initialisiert = true;
      return;
    }
    if (dt <= 0) return;
    final hatGyro = gx != null && gy != null && gz != null;
    var px = x, py = y, pz = z;
    if (hatGyro) {
      final d = math.min(dt, 0.1);
      px = x - (gy * z - gz * y) * d;
      py = y - (gz * x - gx * z) * d;
      pz = z - (gx * y - gy * x) * d;
    }
    final tau = hatGyro ? tauMitGyro : tauOhneGyro;
    final k = 1 - math.exp(-dt / tau);
    x = px + k * (ax - px);
    y = py + k * (ay - py);
    z = pz + k * (az - pz);
  }
}

/// Zahl mit Komma, ohne „−0,00“, mit typografischem Minus.
String zahl(double v, [int stellen = 2]) {
  var s = v.toStringAsFixed(stellen).replaceAll('.', ',');
  if (RegExp(r'^-0[,0]*$').hasMatch(s)) s = s.substring(1);
  return s.replaceFirst('-', '−');
}

/// Welche Seite höher liegt, aus denselben Werten wie die Anzeige
/// (Rundung auf 2 Stellen wie in der Zahlenanzeige). Beispiel: „Rechts höher, vorne höher“.
String richtungsText(Neigung n) {
  if (!n.gueltig) return '–';
  final teile = <String>[];
  if (zahl(n.aGrad) != '0,00') teile.add('${n.lage.seite(n.lage.a, n.aGrad > 0)} höher');
  if (zahl(n.bGrad) != '0,00') teile.add('${n.lage.seite(n.lage.b, n.bGrad > 0)} höher');
  if (teile.isEmpty) return 'Waagerecht';
  if (teile.length == 2) teile[1] = teile[1][0].toLowerCase() + teile[1].substring(1);
  return teile.join(', ');
}


// ───────────────────────── Betriebsarten ─────────────────────────
//
// Jede Betriebsart hat eine fest definierte Lage des Handys, eine fest
// definierte Sensorachse und eine fest definierte Blasenbewegung. Es wird
// nichts erraten: Der Nutzer wählt die Betriebsart, die App misst nur dort.

enum Modus {
  /// Handy flach auf der Rückseite (Display oben): Kreislibelle, zwei Achsen.
  flaeche,

  /// Handy aufrecht, Display zum Benutzer: Libelle links/rechts über die X-Achse (Breite).
  linieDisplay,

  /// Handy auf der linken Seitenkante (Display zum Benutzer, Oberkante zeigt nach links):
  /// Libelle links/rechts über die Y-Achse (Längskante).
  linieLinks,

  /// Handy auf der rechten Seitenkante (Display zum Benutzer, Oberkante zeigt nach rechts):
  /// Libelle links/rechts über die Y-Achse (Längskante).
  linieRechts,
}

extension ModusInfo on Modus {
  bool get istFlaeche => this == Modus.flaeche;

  /// Sensorachse, die senkrecht stehen muss, und ihre Richtung (true: + zeigt nach oben).
  Lage get lage => switch (this) {
        Modus.flaeche => const Lage(Achse.z, true),
        Modus.linieDisplay => const Lage(Achse.y, true),
        Modus.linieLinks => const Lage(Achse.x, true),
        Modus.linieRechts => const Lage(Achse.x, false),
      };

  /// Gemessene Achse der Linien-Betriebsarten.
  Achse get messAchse => switch (this) {
        Modus.linieDisplay => Achse.x,
        _ => Achse.y,
      };

  /// Vorzeichen: +1, wenn das positive Achsenende vom Benutzer aus rechts liegt, sonst −1.
  /// Display vorne: +X ist rechts. Linke Seite: Oberkante (+Y) zeigt nach links → −1.
  /// Rechte Seite: Oberkante (+Y) zeigt nach rechts → +1.
  int get rechtsVorzeichen => switch (this) {
        Modus.linieLinks => -1,
        _ => 1,
      };

  /// Anzahl Vierteldrehungen (im Uhrzeigersinn), mit der die Oberfläche gedreht wird,
  /// damit sie in der Lage des Handys aufrecht lesbar ist.
  int get viertelDrehungen => switch (this) {
        Modus.linieLinks => 1,
        Modus.linieRechts => 3,
        _ => 0,
      };

  String get name2 => switch (this) {
        Modus.flaeche => 'Fläche (2D)',
        Modus.linieDisplay => 'Display vorne',
        Modus.linieLinks => 'Linke Seite',
        Modus.linieRechts => 'Rechte Seite',
      };

  String get anleitung => switch (this) {
        Modus.flaeche => 'Handy flach auf die Rückseite legen (Display oben). Die Blase zeigt die Neigung in alle Richtungen.',
        Modus.linieDisplay =>
          'Handy aufrecht halten, Display zum Benutzer. Gemessen wird links/rechts über die Breite des Handys (X-Achse).',
        Modus.linieLinks =>
          'Handy auf die linke Seitenkante stellen, Display zum Benutzer (Oberkante zeigt nach links). Gemessen wird entlang der Längskante (Y-Achse).',
        Modus.linieRechts =>
          'Handy auf die rechte Seitenkante stellen, Display zum Benutzer (Oberkante zeigt nach rechts). Gemessen wird entlang der Längskante (Y-Achse).',
      };

  String get achseText => switch (this) {
        Modus.flaeche => 'X und Y',
        Modus.linieDisplay => 'X-Achse (Breite)',
        _ => 'Y-Achse (Längskante)',
      };
}

/// Ist das Handy in der Lage der Betriebsart? Die Referenzachse muss die größte
/// Komponente haben und in die richtige Richtung zeigen (rein geometrisch,
/// kein eigener Schwellenwert).
bool lageStimmt(Modus m, double x, double y, double z) {
  final l = m.lage;
  final c = komponente(l.ref, x, y, z);
  if (l.plus ? c <= 0 : c >= 0) return false;
  final ax = x.abs(), ay = y.abs(), az = z.abs();
  return c.abs() >= math.max(ax, math.max(ay, az)) - 1e-12;
}

/// Messung einer Linien-Betriebsart (1D).
class Linienmessung {
  const Linienmessung({
    required this.grad,
    required this.prozent,
    required this.mmProM,
    required this.steigung,
    required this.lageOk,
    required this.gueltig,
    required this.rohGrad,
  });

  /// Neigung der Messachse in Grad aus Sicht des Benutzers, nach Abzug der
  /// Kalibrierung. Positiv: rechts höher, negativ: links höher.
  final double grad;
  final double steigung; // tan(grad), mit Vorzeichen
  final double prozent; // Gefälle in % (Betrag, ohne Vorzeichen)
  final double mmProM; // Gefälle in mm/m (Betrag)
  final bool lageOk;
  final bool gueltig;

  /// Winkel ohne Kalibrierung (für die Kalibrierung selbst).
  final double rohGrad;
}

/// Neigung der Messachse = Höhenwinkel der Achse über der Waagerechten:
/// asin(Komponente / |g|). Unabhängig von einer Neigung quer dazu.
Linienmessung berechneLinie(Modus m, double x, double y, double z, {double a0 = 0}) {
  final betrag = math.sqrt(x * x + y * y + z * z);
  if (betrag < 1e-9) {
    return const Linienmessung(
        grad: 0, prozent: 0, mmProM: 0, steigung: 0, lageOk: false, gueltig: false, rohGrad: 0);
  }
  final c = komponente(m.messAchse, x, y, z);
  final roh = m.rechtsVorzeichen * _grad(math.asin((c / betrag).clamp(-1.0, 1.0)));
  final w = roh - a0;
  final st = math.tan(_rad(w));
  return Linienmessung(
    grad: w,
    steigung: st,
    prozent: st.abs() * 100,
    mmProM: st.abs() * 1000,
    lageOk: lageStimmt(m, x, y, z),
    gueltig: true,
    rohGrad: roh,
  );
}

/// Beschriftung einer Linien-Messung, aus denselben Werten wie die Anzeige.
String linienRichtung(Linienmessung l) {
  if (!l.gueltig) return '–';
  if (zahl(l.grad) == '0,00') return 'Waagerecht';
  return l.grad > 0 ? 'Rechts höher' : 'Links höher';
}

/// Kalibrierung einer Betriebsart (Nullpunkt-Versatz).
class ModusKalibrierung {
  const ModusKalibrierung(this.a0, this.b0, this.streuungGrad);
  final double a0;
  final double b0;
  final double streuungGrad;
}

/// Kalibriert eine Betriebsart aus den Schwerkraftvektoren der Ruhe-Messung.
/// null, wenn zu wenige Proben vorliegen oder das Handy nicht in der Lage der Betriebsart liegt.
ModusKalibrierung? kalibriereModus(Modus m, List<Vek> proben) {
  final gut = proben.where((p) => p.x * p.x + p.y * p.y + p.z * p.z > 1e-12).toList();
  if (gut.length < 10) return null;
  final mx = gut.map((p) => p.x).reduce((a, b) => a + b) / gut.length;
  final my = gut.map((p) => p.y).reduce((a, b) => a + b) / gut.length;
  final mz = gut.map((p) => p.z).reduce((a, b) => a + b) / gut.length;
  if (!lageStimmt(m, mx, my, mz)) return null;
  if (m.istFlaeche) {
    final k = kalibriere(gut, lage: m.lage);
    if (k == null) return null;
    return ModusKalibrierung(k.a0, k.b0, k.streuungGrad);
  }
  final w = [for (final p in gut) berechneLinie(m, p.x, p.y, p.z).rohGrad];
  final mw = w.reduce((a, b) => a + b) / w.length;
  final sd = math.sqrt(w.map((v) => (v - mw) * (v - mw)).reduce((a, b) => a + b) / w.length);
  return ModusKalibrierung(mw, 0, sd);
}
