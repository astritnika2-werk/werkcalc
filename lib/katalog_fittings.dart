// Fittings-Katalog nach System, Material, Dimension und Ausführung.
// Jeder Eintrag trägt Material und Dimension, damit die Karte sie anzeigen
// kann. Namen bleiben eindeutig (doppelte Namen werden vom Baukasten ignoriert).
//
// Nur Varianten, die es im SHK-Handel tatsächlich gibt. Im Zweifel nicht
// aufnehmen: Lieber fehlt ein Teil (es gibt „Eigenen Artikel anlegen“), als dass
// ein Teil im Katalog steht, das es nicht gibt.
//
// Schreibweise der Enden: I = Innen (Muffe/Steckende innen), A = Außen
// (Einsteckende). Bei Gewinde: IG = Innengewinde, AG = Außengewinde.

import 'katalog_basis.dart';

const List<String> _enden = ['I/I', 'I/A', 'A/A'];
const List<String> _gewEnden = ['IG/IG', 'IG/AG', 'AG/AG'];

/// Zoll-Anschluss passend zu einem Rohr-Außendurchmesser.
String _zollZu(int mm) {
  const m = {
    10: '⅜"', 12: '⅜"', 14: '⅜"', 15: '½"', 16: '½"', 18: '½"', 20: '½"',
    22: '¾"', 25: '¾"', 26: '¾"', 28: '1"', 32: '1"', 35: '1¼"', 40: '1¼"',
    42: '1½"', 50: '1½"', 54: '2"', 63: '2"', 64: '2"', 76: '2½"',
    88: '3"', 108: '4"',
  };
  return m[mm] ?? '½"';
}

/// Benachbarte Größenpaare (groß, klein) für Reduzierungen, bis zu 3 Stufen.
List<List<int>> _paare(List<int> groessen, {int stufen = 2}) {
  final out = <List<int>>[];
  for (var i = 1; i < groessen.length; i++) {
    for (var j = 1; j <= stufen && i - j >= 0; j++) {
      out.add([groessen[i], groessen[i - j]]);
    }
  }
  return out;
}

List<List<String>> _zollPaare(List<String> z) {
  final out = <List<String>>[];
  for (var i = 1; i < z.length; i++) {
    for (var j = 1; j <= 2 && i - j >= 0; j++) {
      out.add([z[i], z[i - j]]);
    }
  }
  return out;
}

void ergaenzeFittings(KatalogBaukasten b) {
  _kupferLoet(b);
  _press(b);
  _gewinde(b);
  _schweiss(b);
  _ppr(b);
  _pvc(b);
  _abwasserFittings(b);
}

// ───────────────────────── Kupfer (Löt) ─────────────────────────
void _kupferLoet(KatalogBaukasten b) {
  const k = kFittings;
  const u = 'Kupferfittings (Löt)';
  const mat = 'Kupfer';
  const groessen = [12, 15, 18, 22, 28, 35, 42, 54];
  for (final d in groessen) {
    final dim = '$d mm';
    // Kupfer-Lötbogen 90° und 45°: I/I und I/A (A/A gibt es nicht).
    for (final e in const ['I/I', 'I/A']) {
      b.add(k, u, 'Kupferbogen', 'Kupferbogen 90° $e Ø$d', 'Stk.',
          typ: 'Bogen', material: mat, dim: dim);
    }
    for (final e in const ['I/I', 'I/A']) {
      b.add(k, u, 'Kupferbogen', 'Kupferbogen 45° $e Ø$d', 'Stk.',
          typ: 'Bogen', material: mat, dim: dim);
    }
    b.add(k, u, 'T-Stück Kupfer', 'T-Stück Kupfer Ø$d', 'Stk.',
        typ: 'T-Stück', material: mat, dim: dim);
    b.add(k, u, 'Muffe Kupfer', 'Muffe Kupfer Ø$d', 'Stk.',
        typ: 'Muffe', material: mat, dim: dim);
    b.add(k, u, 'Muffe Kupfer', 'Muffe Kupfer ohne Anschlag Ø$d', 'Stk.',
        typ: 'Muffe', material: mat, dim: dim);
    b.add(k, u, 'Übergang Kupfer', 'Übergang Kupfer Ø$d × ${_zollZu(d)} Innengewinde', 'Stk.',
        typ: 'Übergang', material: mat, dim: '$d mm × ${_zollZu(d)}');
    b.add(k, u, 'Übergang Kupfer', 'Übergang Kupfer Ø$d × ${_zollZu(d)} Außengewinde', 'Stk.',
        typ: 'Übergang', material: mat, dim: '$d mm × ${_zollZu(d)}');
    b.add(k, u, 'Verschraubung Kupfer', 'Verschraubung Kupfer Ø$d', 'Stk.',
        typ: 'Verschraubung', material: mat, dim: dim);
    b.add(k, u, 'Endkappe Kupfer', 'Endkappe Kupfer Ø$d', 'Stk.',
        typ: 'Zubehör', material: mat, dim: dim);
    // Bogen mit Gewinde und Wandwinkel gibt es nur in den kleinen Größen.
    if (d >= 15 && d <= 28) {
      b.add(k, u, 'Kupferbogen', 'Rotguss-Lötbogen 90° mit Innengewinde Ø$d × ${_zollZu(d)}', 'Stk.',
          typ: 'Bogen', material: 'Rotguss', dim: '$d mm × ${_zollZu(d)}');
      b.add(k, u, 'Kupferbogen', 'Rotguss-Lötbogen 90° mit Außengewinde Ø$d × ${_zollZu(d)}', 'Stk.',
          typ: 'Bogen', material: 'Rotguss', dim: '$d mm × ${_zollZu(d)}');
    }
    if (d == 15 || d == 18 || d == 22) {
      b.add(k, u, 'Wandscheibe Kupfer', 'Wandscheibe Kupfer Ø$d × ${_zollZu(d)} Innengewinde', 'Stk.',
          typ: 'Zubehör', material: mat, dim: '$d mm × ${_zollZu(d)}');
    }
  }
  for (final p in _paare(groessen, stufen: 2)) {
    b.add(k, u, 'Reduzierung Kupfer', 'Reduzierung Kupfer ${p[0]} × ${p[1]}', 'Stk.',
        typ: 'Reduzierung', material: mat, dim: '${p[0]} × ${p[1]} mm');
  }
  for (final p in _paare(groessen, stufen: 2).where((p) => p[0] <= 35)) {
    b.add(k, u, 'T-Stück Kupfer', 'T-Stück Kupfer Ø${p[0]} × ${p[0]} × ${p[1]}', 'Stk.',
        typ: 'T-Stück', material: mat, dim: '${p[0]} × ${p[0]} × ${p[1]} mm');
  }
}

// ───────────────────────── Pressfittings ─────────────────────────
void _press(KatalogBaukasten b) {
  const k = kFittings;
  const u = 'Pressfittings';
  const systeme = <String, List<int>>{
    'Kupfer': [12, 15, 18, 22, 28, 35, 42, 54],
    'Edelstahl': [15, 18, 22, 28, 35, 42, 54, 64, 76, 88, 108],
    'C-Stahl': [12, 15, 18, 22, 28, 35, 42, 54],
    'Mehrschicht': [16, 20, 26, 32, 40, 50, 63],
  };
  systeme.forEach((mat, groessen) {
    // Gewinde-Anschlüsse gibt es nur in den kleinen Größen.
    final maxGewinde = mat == 'Mehrschicht' ? 32 : 54;
    for (final d in groessen) {
      final dim = '$d mm';
      final z = _zollZu(d);
      // Pressbogen: 45° und 90° mit zwei Pressenden (I/I) oder einem Einsteckende (I/A).
      for (final w in const [45, 90]) {
        for (final e in const ['I/I', 'I/A']) {
          b.add(k, u, 'Pressbogen', 'Pressfitting Bogen $w° $e Ø$d ($mat)', 'Stk.',
              typ: 'Bogen', material: mat, dim: dim);
        }
      }
      b.add(k, u, 'Press-T-Stück', 'Pressfitting T-Stück Ø$d ($mat)', 'Stk.',
          typ: 'T-Stück', material: mat, dim: dim);
      b.add(k, u, 'Pressmuffe', 'Pressfitting Muffe Ø$d ($mat)', 'Stk.',
          typ: 'Muffe', material: mat, dim: dim);
      b.add(k, u, 'Presskappe', 'Pressfitting Kappe Ø$d ($mat)', 'Stk.',
          typ: 'Zubehör', material: mat, dim: dim);
      if (d <= maxGewinde) {
        b.add(k, u, 'Press-Übergang', 'Pressfitting Übergang Ø$d × $z Innengewinde ($mat)', 'Stk.',
            typ: 'Übergang', material: mat, dim: '$d mm × $z');
        b.add(k, u, 'Press-Übergang', 'Pressfitting Übergang Ø$d × $z Außengewinde ($mat)', 'Stk.',
            typ: 'Übergang', material: mat, dim: '$d mm × $z');
      }
      if (d >= 15 && d <= 28 && mat != 'Mehrschicht') {
        b.add(k, u, 'Pressbogen', 'Pressfitting Bogen 90° mit Innengewinde Ø$d × $z ($mat)', 'Stk.',
            typ: 'Bogen', material: mat, dim: '$d mm × $z');
        b.add(k, u, 'Pressbogen', 'Pressfitting Bogen 90° mit Außengewinde Ø$d × $z ($mat)', 'Stk.',
            typ: 'Bogen', material: mat, dim: '$d mm × $z');
        b.add(k, u, 'Press-T-Stück', 'Pressfitting T-Stück mit Innengewinde Ø$d × $z ($mat)', 'Stk.',
            typ: 'T-Stück', material: mat, dim: '$d mm × $z');
        b.add(k, u, 'Presskappe', 'Pressfitting Wandwinkel Ø$d × $z Innengewinde ($mat)', 'Stk.',
            typ: 'Zubehör', material: mat, dim: '$d mm × $z');
      }
    }
    for (final p in _paare(groessen, stufen: 2)) {
      b.add(k, u, 'Press-Reduzierung', 'Pressfitting Reduzierung ${p[0]} × ${p[1]} ($mat)', 'Stk.',
          typ: 'Reduzierung', material: mat, dim: '${p[0]} × ${p[1]} mm');
    }
    for (final p in _paare(groessen, stufen: 2).where((p) => p[0] <= 54)) {
      b.add(k, u, 'Press-T-Stück', 'Pressfitting T-Stück Ø${p[0]} × ${p[0]} × ${p[1]} ($mat)', 'Stk.',
          typ: 'T-Stück', material: mat, dim: '${p[0]} × ${p[0]} × ${p[1]} mm');
    }
  });
}

// ───────────────────────── Gewindefittings ─────────────────────────
void _gewinde(KatalogBaukasten b) {
  const k = kFittings;
  const u = 'Gewindefittings';
  const zoll = ['⅛"', '¼"', '⅜"', '½"', '¾"', '1"', '1¼"', '1½"', '2"', '2½"', '3"', '4"'];
  // Temperguss verzinkt und Edelstahl: ⅛" bis 4"; Messing: bis 2".
  const werkstoffe = <String, int>{'verzinkt': 12, 'Edelstahl': 12, 'Messing': 9};
  werkstoffe.forEach((mat, anzahl) {
    final liste = zoll.take(anzahl).toList();
    for (final z in liste) {
      // Winkel 90°: IG/IG, IG/AG, AG/AG. Winkel 45°: IG/IG und IG/AG.
      for (final e in _gewEnden) {
        b.add(k, u, 'Gewinde-Winkel', 'Gewindefitting Winkel 90° $e $z ($mat)', 'Stk.',
            typ: 'Bogen', material: mat, dim: z);
      }
      for (final e in const ['IG/IG', 'IG/AG']) {
        b.add(k, u, 'Gewinde-Winkel', 'Gewindefitting Winkel 45° $e $z ($mat)', 'Stk.',
            typ: 'Bogen', material: mat, dim: z);
      }
      b.add(k, u, 'Gewinde-T-Stück', 'Gewindefitting T-Stück IG $z ($mat)', 'Stk.',
          typ: 'T-Stück', material: mat, dim: z);
      b.add(k, u, 'Gewinde-Muffe', 'Gewindefitting Muffe IG/IG $z ($mat)', 'Stk.',
          typ: 'Muffe', material: mat, dim: z);
      b.add(k, u, 'Gewinde-Nippel', 'Gewindefitting Doppelnippel AG/AG $z ($mat)', 'Stk.',
          typ: 'Nippel', material: mat, dim: z);
      b.add(k, u, 'Gewinde-Verschraubung', 'Gewindefitting Verschraubung IG/IG $z ($mat)', 'Stk.',
          typ: 'Verschraubung', material: mat, dim: z);
      b.add(k, u, 'Gewinde-Kappe', 'Gewindefitting Kappe IG $z ($mat)', 'Stk.',
          typ: 'Zubehör', material: mat, dim: z);
      b.add(k, u, 'Gewinde-Kappe', 'Gewindefitting Stopfen AG $z ($mat)', 'Stk.',
          typ: 'Zubehör', material: mat, dim: z);
    }
    for (final p in _zollPaare(liste)) {
      b.add(k, u, 'Gewinde-Reduzierung', 'Gewindefitting Reduzierung IG/AG ${p[0]} × ${p[1]} ($mat)', 'Stk.',
          typ: 'Reduzierung', material: mat, dim: '${p[0]} × ${p[1]}');
      b.add(k, u, 'Gewinde-Reduzierung', 'Gewindefitting Reduzierung AG/AG ${p[0]} × ${p[1]} ($mat)', 'Stk.',
          typ: 'Reduzierung', material: mat, dim: '${p[0]} × ${p[1]}');
      b.add(k, u, 'Gewinde-T-Stück', 'Gewindefitting T-Stück IG ${p[0]} × ${p[0]} × ${p[1]} ($mat)', 'Stk.',
          typ: 'T-Stück', material: mat, dim: '${p[0]} × ${p[1]}');
    }
  });
}

// ───────────────────────── Schweißfittings (Stahl, Edelstahl) ─────────────────────────
void _schweiss(KatalogBaukasten b) {
  const k = kFittings;
  const u = 'Schweißfittings';
  const dns = [15, 20, 25, 32, 40, 50, 65, 80, 100, 125, 150, 200];
  for (final mat in const ['Stahl', 'Edelstahl']) {
    for (final dn in dns) {
      final dim = 'DN $dn';
      b.add(k, u, 'Schweißbogen', 'Schweißbogen 90° kurze Ausführung DN $dn ($mat)', 'Stk.',
          typ: 'Bogen', material: mat, dim: dim);
      b.add(k, u, 'Schweißbogen', 'Schweißbogen 90° lange Ausführung DN $dn ($mat)', 'Stk.',
          typ: 'Bogen', material: mat, dim: dim);
      b.add(k, u, 'Schweißbogen', 'Schweißbogen 45° DN $dn ($mat)', 'Stk.',
          typ: 'Bogen', material: mat, dim: dim);
      b.add(k, u, 'Schweiß-T-Stück', 'Schweiß-T-Stück DN $dn ($mat)', 'Stk.',
          typ: 'T-Stück', material: mat, dim: dim);
      b.add(k, u, 'Schweißkappe', 'Schweißkappe DN $dn ($mat)', 'Stk.',
          typ: 'Zubehör', material: mat, dim: dim);
    }
    for (final p in _paare(dns, stufen: 2)) {
      b.add(k, u, 'Schweiß-Reduzierung', 'Schweiß-Reduzierung konzentrisch DN ${p[0]} × DN ${p[1]} ($mat)', 'Stk.',
          typ: 'Reduzierung', material: mat, dim: 'DN ${p[0]} × DN ${p[1]}');
      b.add(k, u, 'Schweiß-Reduzierung', 'Schweiß-Reduzierung exzentrisch DN ${p[0]} × DN ${p[1]} ($mat)', 'Stk.',
          typ: 'Reduzierung', material: mat, dim: 'DN ${p[0]} × DN ${p[1]}');
    }
  }
}

// ───────────────────────── PP-R ─────────────────────────
void _ppr(KatalogBaukasten b) {
  const k = kFittings;
  const u = 'Kunststofffittings';
  const mat = 'PP-R';
  const groessen = [20, 25, 32, 40, 50, 63, 75, 90, 110];
  for (final d in groessen) {
    final dim = '$d mm';
    final z = _zollZu(d);
    for (final w in const [45, 90]) {
      b.add(k, u, 'PP-R Winkel', 'PP-R Winkel $w° Ø$d', 'Stk.',
          typ: 'Bogen', material: mat, dim: dim);
    }
    b.add(k, u, 'PP-R T-Stück', 'PP-R T-Stück Ø$d', 'Stk.',
        typ: 'T-Stück', material: mat, dim: dim);
    b.add(k, u, 'PP-R Muffe', 'PP-R Muffe Ø$d', 'Stk.',
        typ: 'Muffe', material: mat, dim: dim);
    b.add(k, u, 'PP-R Muffe', 'PP-R Überschiebmuffe Ø$d', 'Stk.',
        typ: 'Muffe', material: mat, dim: dim);
    b.add(k, u, 'PP-R Kappe', 'PP-R Endkappe Ø$d', 'Stk.',
        typ: 'Zubehör', material: mat, dim: dim);
    // Gewindeteile und Wandwinkel nur in den Haus-Installationsgrößen.
    if (d <= 63) {
      b.add(k, u, 'PP-R Übergang', 'PP-R Übergang Ø$d × $z Innengewinde', 'Stk.',
          typ: 'Übergang', material: mat, dim: '$d mm × $z');
      b.add(k, u, 'PP-R Übergang', 'PP-R Übergang Ø$d × $z Außengewinde', 'Stk.',
          typ: 'Übergang', material: mat, dim: '$d mm × $z');
      b.add(k, u, 'PP-R Übergang', 'PP-R Verschraubung Ø$d × $z', 'Stk.',
          typ: 'Verschraubung', material: mat, dim: '$d mm × $z');
    }
    if (d <= 32) {
      b.add(k, u, 'PP-R Winkel', 'PP-R Winkel 90° mit Innengewinde Ø$d × $z', 'Stk.',
          typ: 'Bogen', material: mat, dim: '$d mm × $z');
      b.add(k, u, 'PP-R Winkel', 'PP-R Winkel 90° mit Außengewinde Ø$d × $z', 'Stk.',
          typ: 'Bogen', material: mat, dim: '$d mm × $z');
      b.add(k, u, 'PP-R T-Stück', 'PP-R T-Stück mit Innengewinde Ø$d × $z', 'Stk.',
          typ: 'T-Stück', material: mat, dim: '$d mm × $z');
    }
    if (d == 20 || d == 25) {
      b.add(k, u, 'PP-R Winkel', 'PP-R Wandwinkel Ø$d × $z Innengewinde', 'Stk.',
          typ: 'Bogen', material: mat, dim: '$d mm × $z');
    }
  }
  for (final p in _paare(groessen, stufen: 2)) {
    b.add(k, u, 'PP-R Reduzierung', 'PP-R Reduzierung ${p[0]} × ${p[1]}', 'Stk.',
        typ: 'Reduzierung', material: mat, dim: '${p[0]} × ${p[1]} mm');
  }
}

// ───────────────────────── PVC-U (Klebefittings) ─────────────────────────
void _pvc(KatalogBaukasten b) {
  const k = kFittings;
  const u = 'Kunststofffittings';
  const mat = 'PVC-U';
  const groessen = [16, 20, 25, 32, 40, 50, 63, 75, 90, 110];
  for (final d in groessen) {
    final dim = '$d mm';
    final z = _zollZu(d);
    for (final w in const [45, 90]) {
      b.add(k, u, 'PVC-Winkel', 'PVC-U Winkel $w° Ø$d', 'Stk.',
          typ: 'Bogen', material: mat, dim: dim, stichworte: 'pvc');
    }
    b.add(k, u, 'PVC-T-Stück', 'PVC-U T-Stück Ø$d', 'Stk.',
        typ: 'T-Stück', material: mat, dim: dim, stichworte: 'pvc');
    b.add(k, u, 'PVC-Muffe', 'PVC-U Muffe Ø$d', 'Stk.',
        typ: 'Muffe', material: mat, dim: dim, stichworte: 'pvc');
    if (d <= 63) {
      b.add(k, u, 'PVC-Übergang', 'PVC-U Übergang Ø$d × $z Innengewinde', 'Stk.',
          typ: 'Übergang', material: mat, dim: '$d mm × $z', stichworte: 'pvc');
      b.add(k, u, 'PVC-Übergang', 'PVC-U Übergang Ø$d × $z Außengewinde', 'Stk.',
          typ: 'Übergang', material: mat, dim: '$d mm × $z', stichworte: 'pvc');
      b.add(k, u, 'PVC-Übergang', 'PVC-U Verschraubung Ø$d', 'Stk.',
          typ: 'Verschraubung', material: mat, dim: dim, stichworte: 'pvc');
    }
  }
  for (final p in _paare(groessen, stufen: 2)) {
    b.add(k, u, 'PVC-Reduzierung', 'PVC-U Reduzierung ${p[0]} × ${p[1]}', 'Stk.',
        typ: 'Reduzierung', material: mat, dim: '${p[0]} × ${p[1]} mm', stichworte: 'pvc');
  }
}

// ───────────────────────── HT / KG (Abwasser) ─────────────────────────
void _abwasserFittings(KatalogBaukasten b) {
  const k = kAbwasser;
  const u = 'Kanal-Bögen & Abzweige';
  const htDn = [32, 40, 50, 70, 100, 125, 150];
  const kgDn = [110, 125, 160, 200, 250, 315];
  for (final dn in htDn) {
    final dim = 'DN $dn';
    final winkel = dn == 150 ? const [15, 30, 45, 87] : const [15, 30, 45, 67, 87];
    for (final w in winkel) {
      b.add(k, u, 'HT-Bogen', 'HT-Bogen $w° DN $dn', 'Stk.',
          typ: 'Bogen', material: 'HT (PP)', dim: dim);
    }
    b.add(k, u, 'HT-Muffe', 'HT-Muffe DN $dn', 'Stk.',
        typ: 'Muffe', material: 'HT (PP)', dim: dim);
    b.add(k, u, 'HT-Muffe', 'HT-Überschiebmuffe DN $dn', 'Stk.',
        typ: 'Muffe', material: 'HT (PP)', dim: dim);
    b.add(k, u, 'HT-Muffe', 'HT-Muffenstopfen DN $dn', 'Stk.',
        typ: 'Zubehör', material: 'HT (PP)', dim: dim);
    if (dn >= 50) {
      for (final w in const [45, 67, 87]) {
        b.add(k, u, 'HT-Abzweig', 'HT-Abzweig $w° DN $dn/$dn', 'Stk.',
            typ: 'Abzweig', material: 'HT (PP)', dim: 'DN $dn/$dn');
      }
      b.add(k, u, 'HT-Reinigungsrohr', 'HT-Reinigungsrohr DN $dn', 'Stk.',
          typ: 'Zubehör', material: 'HT (PP)', dim: dim);
    }
  }
  for (final p in _paare(htDn, stufen: 2)) {
    b.add(k, u, 'HT-Reduzierung', 'HT-Reduzierung DN ${p[0]}/${p[1]}', 'Stk.',
        typ: 'Reduzierung', material: 'HT (PP)', dim: 'DN ${p[0]}/${p[1]}');
  }
  for (final p in const [[100, 50], [100, 70], [125, 100], [150, 100]]) {
    for (final w in const [45, 87]) {
      b.add(k, u, 'HT-Abzweig', 'HT-Abzweig $w° DN ${p[0]}/${p[1]}', 'Stk.',
          typ: 'Abzweig', material: 'HT (PP)', dim: 'DN ${p[0]}/${p[1]}');
    }
  }
  for (final dn in kgDn) {
    final dim = 'DN $dn';
    for (final w in const [15, 30, 45, 67, 87]) {
      b.add(k, u, 'KG-Bogen', 'KG-Bogen $w° DN $dn', 'Stk.',
          typ: 'Bogen', material: 'KG (PVC-U)', dim: dim);
    }
    b.add(k, u, 'KG-Muffe', 'KG-Muffe DN $dn', 'Stk.',
        typ: 'Muffe', material: 'KG (PVC-U)', dim: dim);
    b.add(k, u, 'KG-Muffe', 'KG-Überschiebmuffe DN $dn', 'Stk.',
        typ: 'Muffe', material: 'KG (PVC-U)', dim: dim);
    b.add(k, u, 'KG-Muffe', 'KG-Muffenstopfen DN $dn', 'Stk.',
        typ: 'Zubehör', material: 'KG (PVC-U)', dim: dim);
    for (final w in const [45, 87]) {
      b.add(k, u, 'KG-Abzweig', 'KG-Abzweig $w° DN $dn/$dn', 'Stk.',
          typ: 'Abzweig', material: 'KG (PVC-U)', dim: 'DN $dn/$dn');
    }
    if (dn <= 200) {
      b.add(k, u, 'KG-Reinigungsrohr', 'KG-Reinigungsrohr DN $dn', 'Stk.',
          typ: 'Zubehör', material: 'KG (PVC-U)', dim: dim);
    }
  }
  for (final p in _paare(kgDn, stufen: 2)) {
    b.add(k, u, 'KG-Reduzierung', 'KG-Reduzierung DN ${p[0]}/${p[1]}', 'Stk.',
        typ: 'Reduzierung', material: 'KG (PVC-U)', dim: 'DN ${p[0]}/${p[1]}');
  }
  for (final p in const [[160, 110], [200, 160]]) {
    for (final w in const [45, 87]) {
      b.add(k, u, 'KG-Abzweig', 'KG-Abzweig $w° DN ${p[0]}/${p[1]}', 'Stk.',
          typ: 'Abzweig', material: 'KG (PVC-U)', dim: 'DN ${p[0]}/${p[1]}');
    }
  }
}
