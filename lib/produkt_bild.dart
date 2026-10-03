// Technische Skizzen für Katalogartikel. Keine Fotos und keine Herstellerbilder:
// Die Skizze zeigt die Bauform und die Enden des Teils (Winkel, Innen/Außen,
// Gewinde, Muffe), also genau die Angaben, nach denen man auswählt.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'materialliste.dart';

enum BildArt {
  bogen,
  abzweig,
  tstueck,
  muffe,
  reduzierung,
  uebergang,
  verschraubung,
  kappe,
  nippel,
  flansch,
  rohr,
  ventil,
  pumpe,
  sonst,
}

/// Art des Rohrendes in der Skizze.
enum EndeArt { glatt, innen, aussen, innengewinde, aussengewinde }

/// Was die Skizze zeigt (rein berechnet, damit es testbar ist).
class BildInfo {
  const BildInfo({
    required this.art,
    this.winkel = 90,
    this.ende1 = EndeArt.innen,
    this.ende2 = EndeArt.innen,
    this.radius = 1,
  });

  final BildArt art;
  final int winkel;
  final EndeArt ende1;
  final EndeArt ende2;

  /// 0 = kurze Ausführung, 1 = normal, 2 = lange Ausführung.
  final int radius;

  @override
  String toString() => 'BildInfo($art, $winkel°, $ende1/$ende2, r$radius)';
}

EndeArt _endeAusKuerzel(String k) {
  switch (k) {
    case 'IG':
      return EndeArt.innengewinde;
    case 'AG':
      return EndeArt.aussengewinde;
    case 'A':
      return EndeArt.aussen;
    default:
      return EndeArt.innen;
  }
}

/// Bestimmt aus dem Artikel, welche Skizze gezeichnet wird.
BildInfo bildInfo(KatalogArtikel a) {
  final n = a.name;
  final l = n.toLowerCase();
  final kat = a.kategorie;
  final istFitting = kat == 'Fittings' ||
      kat == 'Abwasser / Kanalisation' ||
      kat == 'Rohre' ||
      kat == 'Lüftung';

  int radius = 1;
  if (l.contains('kurze ausführung')) radius = 0;
  if (l.contains('lange ausführung')) radius = 2;

  var winkel = 90;
  final w = RegExp(r'(\d{2})°').firstMatch(n);
  if (w != null) winkel = int.parse(w.group(1)!);

  var e1 = EndeArt.innen;
  var e2 = EndeArt.innen;
  final e = RegExp(r'\b(IG|AG|I|A)/(IG|AG|I|A)\b').firstMatch(n);
  if (e != null) {
    e1 = _endeAusKuerzel(e.group(1)!);
    e2 = _endeAusKuerzel(e.group(2)!);
  } else if (l.contains('mit innengewinde') || l.contains('innengewinde')) {
    e2 = EndeArt.innengewinde;
  } else if (l.contains('mit außengewinde') || l.contains('außengewinde')) {
    e2 = EndeArt.aussengewinde;
  }

  BildInfo mk(BildArt art) => BildInfo(
        art: art,
        winkel: winkel,
        ende1: e1,
        ende2: e2,
        radius: radius,
      );

  if (istFitting) {
    if (l.contains('abzweig')) return mk(BildArt.abzweig);
    if (l.contains('t-stück') || l.contains('kreuz')) return mk(BildArt.tstueck);
    if (l.contains('bogen') || l.contains('winkel')) return mk(BildArt.bogen);
    if (l.contains('reduzierung')) return mk(BildArt.reduzierung);
    if (l.contains('übergang')) {
      return BildInfo(
        art: BildArt.uebergang,
        ende1: EndeArt.innen,
        ende2: l.contains('innengewinde')
            ? EndeArt.innengewinde
            : EndeArt.aussengewinde,
      );
    }
    if (l.contains('verschraubung')) return mk(BildArt.verschraubung);
    if (l.contains('kappe') || l.contains('stopfen')) return mk(BildArt.kappe);
    if (l.contains('nippel')) return mk(BildArt.nippel);
    if (l.contains('muffe')) return mk(BildArt.muffe);
    if (l.contains('flansch')) return mk(BildArt.flansch);
    if (kat == 'Rohre' || l.contains('rohr')) return mk(BildArt.rohr);
  }
  if (l.contains('ventil') || l.contains('kugelhahn') || l.contains('hahn')) {
    return mk(BildArt.ventil);
  }
  if (l.contains('pumpe')) return mk(BildArt.pumpe);
  return mk(BildArt.sonst);
}

/// Farbe nach Werkstoff.
Color werkstoffFarbe(String werkstoff) {
  final w = werkstoff.toLowerCase();
  if (w.contains('kupfer')) return const Color(0xFFB87333);
  if (w.contains('edelstahl')) return const Color(0xFF9AA5B1);
  if (w.contains('verzinkt')) return const Color(0xFF8FA3B5);
  if (w.contains('stahl')) return const Color(0xFF5F6B78);
  if (w.contains('messing') || w.contains('rotguss')) return const Color(0xFFC9A227);
  if (w.contains('pp-r')) return const Color(0xFF3E8E5A);
  if (w.contains('pvc')) return const Color(0xFF7F8FA9);
  if (w.contains('ht')) return const Color(0xFFE0762B);
  if (w.contains('kg')) return const Color(0xFFC0603A);
  if (w.contains('mehrschicht')) return const Color(0xFF4A6FA5);
  return const Color(0xFF607D8B);
}

class ProduktBild extends StatelessWidget {
  const ProduktBild({
    super.key,
    required this.artikel,
    required this.fallback,
    this.groesse = 72,
  });

  final KatalogArtikel artikel;
  final IconData fallback;
  final double groesse;

  @override
  Widget build(BuildContext context) {
    final info = bildInfo(artikel);
    final scheme = Theme.of(context).colorScheme;
    final rahmen = BoxDecoration(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: scheme.outlineVariant),
    );
    if (info.art == BildArt.sonst) {
      return Container(
        width: groesse,
        height: groesse,
        decoration: rahmen,
        child: Icon(fallback, size: groesse * 0.5, color: scheme.primary),
      );
    }
    return Container(
      width: groesse,
      height: groesse,
      decoration: rahmen,
      padding: const EdgeInsets.all(4),
      child: CustomPaint(
        painter: _SkizzenMaler(
          info,
          werkstoffFarbe(artikel.werkstoffAnzeige),
          scheme.onSurface.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

class _SkizzenMaler extends CustomPainter {
  _SkizzenMaler(this.info, this.farbe, this.kontur);

  final BildInfo info;
  final Color farbe;
  final Color kontur;

  // Zeichenfläche 64 × 64, wird auf die Widgetgröße skaliert.
  static const double _t = 9; // Rohrstärke

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 64);
    final koerper = Paint()
      ..color = farbe
      ..style = PaintingStyle.stroke
      ..strokeWidth = _t
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round;
    final umriss = Paint()
      ..color = kontur
      ..style = PaintingStyle.stroke
      ..strokeWidth = _t + 2
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round;

    void rohr(Path p) {
      canvas.drawPath(p, umriss);
      canvas.drawPath(p, koerper);
    }

    switch (info.art) {
      case BildArt.bogen:
        _bogen(canvas, rohr);
        break;
      case BildArt.abzweig:
      case BildArt.tstueck:
        {
        final haupt = Path()
          ..moveTo(6, 40)
          ..lineTo(58, 40);
        final ast = Path()..moveTo(32, 40);
        if (info.art == BildArt.abzweig && info.winkel < 80) {
          ast.lineTo(52, 12);
        } else {
          ast.lineTo(32, 8);
        }
        rohr(haupt);
        rohr(ast);
        _ende(canvas, const Offset(6, 40), const Offset(-1, 0), EndeArt.innen);
        _ende(canvas, const Offset(58, 40), const Offset(1, 0), EndeArt.innen);
        if (info.art == BildArt.abzweig && info.winkel < 80) {
          _ende(canvas, const Offset(52, 12), const Offset(0.58, -0.81), EndeArt.innen);
        } else {
          _ende(canvas, const Offset(32, 8), const Offset(0, -1), EndeArt.innen);
        }
        break;
        }
      case BildArt.muffe:
        rohr(Path()
          ..moveTo(6, 32)
          ..lineTo(58, 32));
        _ende(canvas, const Offset(24, 32), const Offset(1, 0), EndeArt.glatt, laenge: 16, breite: _t + 8);
        break;
      case BildArt.reduzierung:
        {
        final p = Path()
          ..moveTo(6, 22)
          ..lineTo(32, 26)
          ..lineTo(32, 38)
          ..lineTo(6, 42)
          ..close();
        final q = Path()
          ..moveTo(32, 26)
          ..lineTo(58, 28)
          ..lineTo(58, 36)
          ..lineTo(32, 38)
          ..close();
        final f = Paint()..color = farbe;
        final o = Paint()
          ..color = kontur
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawPath(p, f);
        canvas.drawPath(q, f);
        canvas.drawPath(p, o);
        canvas.drawPath(q, o);
        break;
        }
      case BildArt.uebergang:
        rohr(Path()
          ..moveTo(8, 32)
          ..lineTo(56, 32));
        _ende(canvas, const Offset(8, 32), const Offset(-1, 0), EndeArt.aussen);
        _ende(canvas, const Offset(56, 32), const Offset(1, 0), info.ende2);
        break;
      case BildArt.verschraubung:
        rohr(Path()
          ..moveTo(6, 32)
          ..lineTo(58, 32));
        _sechskant(canvas, const Offset(32, 32), 13);
        break;
      case BildArt.kappe:
        {
        rohr(Path()
          ..moveTo(10, 32)
          ..lineTo(40, 32));
        _ende(canvas, const Offset(10, 32), const Offset(-1, 0), EndeArt.innen);
        final k = Paint()..color = kontur;
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(40, 22, 10, 20), const Radius.circular(5)),
          k,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(41, 23, 8, 18), const Radius.circular(4)),
          Paint()..color = farbe,
        );
        break;
        }
      case BildArt.nippel:
        rohr(Path()
          ..moveTo(10, 32)
          ..lineTo(54, 32));
        _ende(canvas, const Offset(10, 32), const Offset(-1, 0), EndeArt.aussengewinde);
        _ende(canvas, const Offset(54, 32), const Offset(1, 0), EndeArt.aussengewinde);
        break;
      case BildArt.flansch:
        {
        final c = Paint()..color = kontur;
        canvas.drawCircle(const Offset(32, 32), 24, c);
        canvas.drawCircle(const Offset(32, 32), 22.5, Paint()..color = farbe);
        canvas.drawCircle(const Offset(32, 32), 8, c);
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          canvas.drawCircle(Offset(32 + 16 * math.cos(a), 32 + 16 * math.sin(a)), 2.4, c);
        }
        break;
        }
      case BildArt.rohr:
        rohr(Path()
          ..moveTo(4, 32)
          ..lineTo(60, 32));
        break;
      case BildArt.ventil:
        {
        final f = Paint()..color = farbe;
        final o = Paint()
          ..color = kontur
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        final v = Path()
          ..moveTo(8, 38)
          ..lineTo(32, 50)
          ..lineTo(32, 26)
          ..close();
        final v2 = Path()
          ..moveTo(56, 38)
          ..lineTo(32, 50)
          ..lineTo(32, 26)
          ..close();
        canvas.drawPath(v, f);
        canvas.drawPath(v2, f);
        canvas.drawPath(v, o);
        canvas.drawPath(v2, o);
        canvas.drawLine(const Offset(32, 38), const Offset(32, 14), o..strokeWidth = 3);
        canvas.drawLine(const Offset(22, 14), const Offset(42, 14), o);
        break;
        }
      case BildArt.pumpe:
        {
        final f = Paint()..color = farbe;
        final o = Paint()
          ..color = kontur
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(const Offset(32, 32), 20, f);
        canvas.drawCircle(const Offset(32, 32), 20, o);
        final d = Path()
          ..moveTo(26, 22)
          ..lineTo(44, 32)
          ..lineTo(26, 42)
          ..close();
        canvas.drawPath(d, Paint()..color = Colors.white);
        canvas.drawPath(d, o..strokeWidth = 1.5);
        break;
        }
      case BildArt.sonst:
        break;
    }
    canvas.restore();
  }

  void _bogen(Canvas canvas, void Function(Path) rohr) {
    final r = info.radius == 0 ? 8.0 : (info.radius == 2 ? 22.0 : 14.0);
    final flach = info.winkel <= 50;
    final p = Path();
    Offset a;
    Offset b;
    Offset ra;
    Offset rb;
    if (!flach) {
      // 90°: von unten nach rechts
      p.moveTo(14, 58);
      p.lineTo(14, 6 + r + 4);
      p.quadraticBezierTo(14, 10, 14 + r + 4, 10);
      p.lineTo(58, 10);
      a = const Offset(14, 58);
      ra = const Offset(0, 1);
      b = const Offset(58, 10);
      rb = const Offset(1, 0);
    } else {
      // 45°: von unten schräg nach rechts oben
      p.moveTo(14, 58);
      p.lineTo(14, 44);
      p.quadraticBezierTo(14, 30 - r / 2, 26, 22);
      p.lineTo(50, 6);
      a = const Offset(14, 58);
      ra = const Offset(0, 1);
      b = const Offset(50, 6);
      rb = const Offset(0.83, -0.55);
    }
    rohr(p);
    _ende(canvas, a, ra, info.ende1);
    _ende(canvas, b, rb, info.ende2);
  }

  /// Zeichnet ein Rohrende am Punkt [p]; [r] zeigt vom Teil weg.
  void _ende(
    Canvas canvas,
    Offset p,
    Offset r,
    EndeArt art, {
    double laenge = 9,
    double? breite,
  }) {
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(math.atan2(r.dy, r.dx));
    final f = Paint()..color = farbe;
    final o = Paint()
      ..color = kontur
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    switch (art) {
      case EndeArt.innen:
      case EndeArt.innengewinde:
        final bw = breite ?? (_t + 7);
        final rect = Rect.fromLTRB(-laenge, -bw / 2, 0, bw / 2);
        canvas.drawRect(rect, f);
        canvas.drawRect(rect, o);
        if (art == EndeArt.innengewinde) {
          for (var x = -laenge + 2; x < 0; x += 2.6) {
            canvas.drawLine(Offset(x, -bw / 2), Offset(x, bw / 2), o..strokeWidth = 0.9);
          }
        }
        break;
      case EndeArt.aussen:
        canvas.drawLine(const Offset(-2, -_t / 2 - 1), const Offset(-2, _t / 2 + 1), o..strokeWidth = 2);
        break;
      case EndeArt.aussengewinde:
        final rect = Rect.fromLTRB(-laenge, -_t / 2, 0, _t / 2);
        canvas.drawRect(rect, f);
        for (var x = -laenge + 1; x < 0; x += 2.4) {
          canvas.drawLine(Offset(x, -_t / 2 - 1), Offset(x + 1.2, _t / 2 + 1), o..strokeWidth = 1.1);
        }
        break;
      case EndeArt.glatt:
        final bw = breite ?? (_t + 4);
        final rect = Rect.fromLTRB(-laenge, -bw / 2, 0, bw / 2);
        canvas.drawRect(rect, f);
        canvas.drawRect(rect, o);
        break;
    }
    canvas.restore();
  }

  void _sechskant(Canvas canvas, Offset c, double r) {
    final p = Path();
    for (var i = 0; i < 6; i++) {
      final a = math.pi / 6 + i * math.pi / 3;
      final x = c.dx + r * math.cos(a);
      final y = c.dy + r * math.sin(a);
      if (i == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    p.close();
    canvas.drawPath(p, Paint()..color = farbe);
    canvas.drawPath(
      p,
      Paint()
        ..color = kontur
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      c,
      4,
      Paint()
        ..color = kontur
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _SkizzenMaler old) =>
      old.info.toString() != info.toString() || old.farbe != farbe || old.kontur != kontur;
}
