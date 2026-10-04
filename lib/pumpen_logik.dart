// Pumpenprüfung: Vergleich des Betriebspunkts (Q, H) mit der Q/H-Kennlinie
// einer KONKRETEN Pumpe. Es werden keine Pumpendaten vorgegeben oder geschätzt:
// Die Kennlinie kommt aus dem Datenblatt des Herstellers (vom Nutzer eingegeben
// oder als geprüfte Herstellerdaten in assets/pumpen/pumpen.json).
// Reine Dart-Logik ohne Flutter, damit sie testbar bleibt.

import 'logic.dart' show parseNum;

/// Ein Punkt der Kennlinie: Volumenstrom q (m³/h) und Förderhöhe h (m).
class QH {
  const QH(this.q, this.h);

  final double q;
  final double h;
}

/// Interne Richtwerte – keine Herstellervorgabe und keine Norm
/// (in der App so gekennzeichnet). Bewertungsregeln:
/// - Reserve Förderhöhe: Die Kennlinie soll beim geforderten Q mindestens das
///   1,2-fache der benötigten Förderhöhe liefern.
/// - Q-Reserve: Der Betriebspunkt soll nicht im letzten Teil der Kennlinie liegen.
/// - Überdimensionierung: ab dem 3-fachen der benötigten Förderhöhe Hinweis.
const double kPumpeReserveGeeignet = 1.2;
const double kPumpeQNahEnde = 0.85;
const double kPumpeUeberdimensioniert = 3.0;

/// 1 m Wassersäule ≈ 9,80665 kPa (Wasser, 1000 kg/m³).
const double _kKpaProM = 9.80665;

/// Eine Kennlinie (z. B. „Max. Drehzahl“ oder „Stufe 3“) in den Einheiten des
/// Datenblatts. [normiert] liefert m³/h und m.
class PumpenKurve {
  PumpenKurve({
    required this.name,
    required this.punkte,
    this.qEinheit = 'm3h',
    this.hEinheit = 'm',
  });

  String name;

  /// Punkte in den Einheiten [qEinheit] / [hEinheit].
  List<QH> punkte;

  /// 'm3h' (m³/h), 'lmin' (l/min) oder 'ls' (l/s).
  String qEinheit;

  /// 'm' (Meter) oder 'kpa' (kPa).
  String hEinheit;

  double get qFaktor => qEinheit == 'lmin' ? 0.06 : (qEinheit == 'ls' ? 3.6 : 1.0);
  double get hFaktor => hEinheit == 'kpa' ? 1 / _kKpaProM : 1.0;

  List<QH> get normiert => [for (final p in punkte) QH(p.q * qFaktor, p.h * hFaktor)];

  Map<String, dynamic> toJson() => {
        'name': name,
        'qEinheit': qEinheit,
        'hEinheit': hEinheit,
        'punkte': [
          for (final p in punkte) [p.q, p.h],
        ],
      };

  factory PumpenKurve.fromJson(Map<String, dynamic> j) {
    final pts = <QH>[];
    for (final e in (j['punkte'] as List<dynamic>? ?? const [])) {
      final l = e as List<dynamic>;
      if (l.length >= 2) {
        pts.add(QH((l[0] as num).toDouble(), (l[1] as num).toDouble()));
      }
    }
    return PumpenKurve(
      name: (j['name'] as String?) ?? 'Kennlinie',
      punkte: pts,
      qEinheit: (j['qEinheit'] as String?) ?? 'm3h',
      hEinheit: (j['hEinheit'] as String?) ?? 'm',
    );
  }
}

/// Eine konkrete Pumpe mit Herkunftsangabe. [verifiziert] ist nur für Daten aus
/// den mitgelieferten Herstellerdaten true; Eingaben des Nutzers sind es nie.
class PumpenDaten {
  PumpenDaten({
    required this.id,
    required this.hersteller,
    required this.modell,
    required this.quelle,
    required this.kurven,
    this.artikelnummer = '',
    this.anschluss = '',
    this.baulaenge = '',
    this.verifiziert = false,
  });

  final String id;
  String hersteller;
  String modell;

  /// Woher die Kennlinie stammt (Datenblatt, Seite, Link). Pflichtangabe.
  String quelle;
  String artikelnummer;
  String anschluss;
  String baulaenge;
  bool verifiziert;
  List<PumpenKurve> kurven;

  String get titel => '$hersteller $modell'.trim();

  Map<String, dynamic> toJson() => {
        'id': id,
        'hersteller': hersteller,
        'modell': modell,
        'artikelnummer': artikelnummer,
        'anschluss': anschluss,
        'baulaenge': baulaenge,
        'quelle': quelle,
        'kurven': [for (final k in kurven) k.toJson()],
      };

  factory PumpenDaten.fromJson(Map<String, dynamic> j, {bool verifiziert = false}) {
    return PumpenDaten(
      id: (j['id'] as String?) ?? DateTime.now().microsecondsSinceEpoch.toString(),
      hersteller: (j['hersteller'] as String?) ?? '',
      modell: (j['modell'] as String?) ?? '',
      artikelnummer: (j['artikelnummer'] as String?) ?? '',
      anschluss: (j['anschluss'] as String?) ?? '',
      baulaenge: (j['baulaenge'] as String?) ?? '',
      quelle: (j['quelle'] as String?) ?? '',
      verifiziert: verifiziert,
      kurven: [
        for (final k in (j['kurven'] as List<dynamic>? ?? const []))
          PumpenKurve.fromJson(Map<String, dynamic>.from(k as Map)),
      ],
    );
  }
}

/// Liest Kennlinienpunkte aus Text: je Zeile „Q H“ (Leerzeichen, Tab oder
/// Semikolon; Komma oder Punkt als Dezimaltrenner). Leere Zeilen werden
/// ignoriert. [fehler] enthält die Zeilen, die nicht gelesen werden konnten.
({List<QH> punkte, List<String> fehler}) parsePunkte(String text) {
  final punkte = <QH>[];
  final fehler = <String>[];
  var nr = 0;
  for (final zeile in text.split(RegExp(r'[\r\n]+'))) {
    nr++;
    final z = zeile.trim();
    if (z.isEmpty) continue;
    final teile = z.split(RegExp(r'[\s;]+')).where((t) => t.isNotEmpty).toList();
    final q = teile.length == 2 ? parseNum(teile[0]) : null;
    final h = teile.length == 2 ? parseNum(teile[1]) : null;
    if (q == null || h == null) {
      fehler.add('Zeile $nr: „$z“ nicht lesbar (erwartet: Q und H, z. B. 2,5 3,1)');
    } else {
      punkte.add(QH(q, h));
    }
  }
  return (punkte: punkte, fehler: fehler);
}

/// Formatiert Punkte wieder als Text (zum Bearbeiten).
String punkteAlsText(List<QH> punkte) {
  String z(double v) => (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString())
      .replaceAll('.', ',');
  return [for (final p in punkte) '${z(p.q)} ${z(p.h)}'].join('\n');
}

/// Prüft eine normierte Kennlinie (m³/h, m). Gibt eine Fehlermeldung zurück
/// oder null, wenn sie brauchbar ist.
String? pruefeKurve(List<QH> k) {
  if (k.length < 3) return 'Mindestens 3 Punkte nötig (besser 5 oder mehr).';
  for (final p in k) {
    if (p.q < 0 || p.h < 0) return 'Negative Werte sind nicht erlaubt.';
  }
  for (var i = 1; i < k.length; i++) {
    if (k[i].q <= k[i - 1].q) {
      return 'Q muss von Zeile zu Zeile größer werden (aufsteigend sortieren).';
    }
    if (k[i].h > k[i - 1].h + 1e-9) {
      return 'H darf mit steigendem Q nicht steigen – Kennlinie prüfen.';
    }
  }
  return null;
}

/// Förderhöhe der Kennlinie bei Volumenstrom [q] (lineare Interpolation).
/// Unterhalb des ersten Punkts gilt dessen Wert; oberhalb des letzten null.
double? hBeiQ(List<QH> k, double q) {
  if (k.isEmpty) return null;
  if (q <= k.first.q) return k.first.h;
  if (q > k.last.q) return null;
  for (var i = 1; i < k.length; i++) {
    if (q <= k[i].q) {
      final a = k[i - 1];
      final b = k[i];
      final t = (q - a.q) / (b.q - a.q);
      return a.h + (b.h - a.h) * t;
    }
  }
  return k.last.h;
}

enum Eignung { geeignet, grenzbereich, nichtGeeignet, nichtPruefbar }

String eignungText(Eignung e) {
  switch (e) {
    case Eignung.geeignet:
      return '✅ Pumpe geeignet';
    case Eignung.grenzbereich:
      return '⚠️ Grenzbereich';
    case Eignung.nichtGeeignet:
      return '❌ Pumpe nicht geeignet';
    case Eignung.nichtPruefbar:
      return 'Prüfung nicht möglich';
  }
}

class PumpenPruefung {
  const PumpenPruefung({
    required this.eignung,
    required this.gruende,
    this.hKurveAmBetriebspunkt,
    this.reserveH,
    this.reserveQ,
    this.qMax,
    this.schnittQ,
    this.schnittH,
  });

  final Eignung eignung;

  /// Begründung in Klartext (warum geeignet / Grenzbereich / ungeeignet).
  final List<String> gruende;

  /// Förderhöhe der Kennlinie beim geforderten Q (m).
  final double? hKurveAmBetriebspunkt;

  /// Reserve Förderhöhe: (H_Kennlinie − H_benötigt) / H_benötigt.
  final double? reserveH;

  /// Reserve Volumenstrom bis zum Kurvenende: (Q_max − Q) / Q_max.
  final double? reserveQ;
  final double? qMax;

  /// Schnittpunkt der Kennlinie mit der Anlagenkennlinie H ∝ Q² durch den
  /// Betriebspunkt (geschlossener Heizkreis, ohne statischen Anteil).
  final double? schnittQ;
  final double? schnittH;
}

String _z(double v, [int d = 2]) => v.toStringAsFixed(d).replaceAll('.', ',');

/// Vergleicht den Betriebspunkt ([q] m³/h, [h] m) mit der Kennlinie [kurve].
/// Ohne Kennlinie wird nichts geschätzt: Ergebnis ist dann „nicht prüfbar“.
PumpenPruefung pruefePumpe({
  required double q,
  required double h,
  PumpenKurve? kurve,
}) {
  if (kurve == null) {
    return const PumpenPruefung(
      eignung: Eignung.nichtPruefbar,
      gruende: [
        'Prüfung nicht möglich – keine verifizierte Pumpenkennlinie vorhanden.',
        'Kennlinie aus dem Datenblatt des Herstellers eingeben (Pumpe eingeben).',
      ],
    );
  }
  if (q <= 0 || h <= 0) {
    return const PumpenPruefung(
      eignung: Eignung.nichtPruefbar,
      gruende: ['Betriebspunkt fehlt: Volumenstrom Q und Förderhöhe H eingeben.'],
    );
  }
  final k = kurve.normiert;
  final fehler = pruefeKurve(k);
  if (fehler != null) {
    return PumpenPruefung(
      eignung: Eignung.nichtPruefbar,
      gruende: ['Prüfung nicht möglich – Kennlinie nicht brauchbar: $fehler'],
    );
  }
  final qMax = k.last.q;
  final hMax = k.first.h;
  final hP = hBeiQ(k, q);

  // Schnittpunkt mit Anlagenkennlinie H = h·(Q/q)².
  double? sq;
  double? sh;
  double f(double qq) => (hBeiQ(k, qq) ?? 0) - h * (qq / q) * (qq / q);
  if (f(0) > 0 && f(qMax) <= 0) {
    var lo = 0.0;
    var hi = qMax;
    for (var i = 0; i < 60; i++) {
      final mid = (lo + hi) / 2;
      if (f(mid) > 0) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    sq = (lo + hi) / 2;
    sh = hBeiQ(k, sq);
  }

  if (hP == null) {
    return PumpenPruefung(
      eignung: Eignung.nichtGeeignet,
      gruende: [
        'Der geforderte Volumenstrom ${_z(q)} m³/h liegt über dem Ende der '
            'Kennlinie (${_z(qMax)} m³/h).',
      ],
      qMax: qMax,
      reserveQ: (qMax - q) / qMax,
      schnittQ: sq,
      schnittH: sh,
    );
  }

  final ratio = hP / h;
  final reserveH = ratio - 1;
  final reserveQ = (qMax - q) / qMax;
  final gruende = <String>[];
  var hart = false;
  var weich = false;

  if (ratio < 1.0) {
    hart = true;
    gruende.add('Bei Q = ${_z(q)} m³/h liefert die Kennlinie nur ${_z(hP)} m, '
        'benötigt werden ${_z(h)} m (Fehlbetrag ${_z(-reserveH * 100, 0)} %).');
  } else if (ratio < kPumpeReserveGeeignet) {
    weich = true;
    gruende.add('Bei Q = ${_z(q)} m³/h liefert die Kennlinie ${_z(hP)} m, benötigt '
        'werden ${_z(h)} m: Reserve nur ${_z(reserveH * 100, 0)} % '
        '(interner Richtwert ≥ ${_z((kPumpeReserveGeeignet - 1) * 100, 0)} %).');
  } else {
    gruende.add('Bei Q = ${_z(q)} m³/h liefert die Kennlinie ${_z(hP)} m, benötigt '
        'werden ${_z(h)} m: Reserve ${_z(reserveH * 100, 0)} %.');
  }

  if (q / qMax > kPumpeQNahEnde) {
    if (!hart) weich = true;
    gruende.add('Der Betriebspunkt liegt bei ${_z(q / qMax * 100, 0)} % des '
        'Kurvenendes (${_z(qMax)} m³/h): kaum Reserve beim Volumenstrom.');
  } else {
    gruende.add('Volumenstrom-Reserve bis Kurvenende: ${_z(reserveQ * 100, 0)} %.');
  }

  if (!hart && ratio > kPumpeUeberdimensioniert) {
    weich = true;
    gruende.add('Die Pumpe ist stark überdimensioniert (Kennlinie ${_z(ratio, 1)}× '
        'der benötigten Förderhöhe, Maximum ${_z(hMax)} m). Kleinere Pumpe oder '
        'niedrigere Stufe prüfen.');
  }

  if (sq != null && sh != null && !hart) {
    gruende.add('Ungeregelt (volle Drehzahl) stellt sich Q = ${_z(sq)} m³/h bei '
        'H = ${_z(sh)} m ein; mit Regelung/Stufe wird auf den Betriebspunkt reduziert.');
  }

  return PumpenPruefung(
    eignung: hart
        ? Eignung.nichtGeeignet
        : (weich ? Eignung.grenzbereich : Eignung.geeignet),
    gruende: gruende,
    hKurveAmBetriebspunkt: hP,
    reserveH: reserveH,
    reserveQ: reserveQ,
    qMax: qMax,
    schnittQ: sq,
    schnittH: sh,
  );
}
