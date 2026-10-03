// Technische Skizzen für Katalogartikel. Keine Fotos und keine Herstellerbilder:
// Die Skizze zeigt die Bauform und die Enden des Teils (Winkel, Innen/Außen,
// Gewinde, Muffe), also genau die Angaben, nach denen man auswählt.

import 'dart:io';
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
  wc,
  wcSitz,
  waschtisch,
  armatur,
  dusche,
  wanne,
  siphon,
  spuelkasten,
  vorwand,
  drueckerplatte,
  heizkoerper,
  thermostat,
  ausdehnung,
  waermetauscher,
  speicher,
  waermepumpe,
  klimageraet,
  lueftungsgeraet,
  isolierung,
  schelle,
  schraube,
  werkzeug,
  filter,
  manometer,
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
  bool hat(List<String> w) => w.any(l.contains);
  final istWerkzeug = kat == 'Werkzeug';
  final istMontage = kat == 'Installation / Montage';

  if (hat(['isolier', 'rohrschale', 'dämm', 'flex-schlauch'])) return mk(BildArt.isolierung);
  if (hat(['siphon', 'geruchverschluss', 'ablaufgarnitur'])) return mk(BildArt.siphon);
  if (hat(['armatur', 'mischer', 'wasserhahn', 'wandauslauf'])) return mk(BildArt.armatur);
  if (hat(['ventil', 'kugelhahn', 'hahn', 'absperrklappe', 'rückschlag'])) return mk(BildArt.ventil);
  if (hat(['thermostat'])) return mk(BildArt.thermostat);
  if (hat(['wc-sitz'])) return mk(BildArt.wcSitz);
  if (hat(['spülkasten'])) return mk(BildArt.spuelkasten);
  if (hat(['vorwandelement'])) return mk(BildArt.vorwand);
  if (hat(['drückerplatte', 'betätigungsplatte'])) return mk(BildArt.drueckerplatte);
  if (l.startsWith('wc ') || l == 'wc' || hat(['urinal', 'stand-wc', 'wand-wc', 'dusch-wc'])) {
    return mk(BildArt.wc);
  }
  if (hat(['waschtisch', 'waschbecken', 'handwaschbecken'])) return mk(BildArt.waschtisch);
  if (hat(['badewanne', 'duschwanne', 'wanne'])) return mk(BildArt.wanne);
  if (hat(['dusch', 'brause'])) return mk(BildArt.dusche);
  if (hat(['wärmepumpe'])) return mk(BildArt.waermepumpe);
  if (hat(['pumpe'])) return mk(BildArt.pumpe);
  if (hat(['heizkörper', 'radiator'])) return mk(BildArt.heizkoerper);
  if (hat(['ausdehnungsgefäß', 'ausdehnungsgefäss', 'druckausdehnung'])) {
    return mk(BildArt.ausdehnung);
  }
  if (hat(['wärmetauscher', 'wärmeübertrager'])) return mk(BildArt.waermetauscher);
  if (hat(['speicher', 'boiler'])) return mk(BildArt.speicher);
  if (hat(['klimagerät', 'split', 'außengerät', 'innengerät'])) return mk(BildArt.klimageraet);
  if (hat(['lüftungsgerät', 'wohnraumlüftung', 'ventilator', 'lüfter'])) {
    return mk(BildArt.lueftungsgeraet);
  }
  if (hat(['manometer', 'thermometer', 'wasserzähler'])) return mk(BildArt.manometer);
  if (hat(['filter', 'druckminderer', 'enthärt'])) return mk(BildArt.filter);
  if (hat(['schelle'])) return mk(BildArt.schelle);
  if (istMontage && hat(['schraube', 'dübel', 'gewindestange', 'mutter', 'haken'])) {
    return mk(BildArt.schraube);
  }
  if (istWerkzeug) return mk(BildArt.werkzeug);
  return mk(BildArt.sonst);
}

/// Farbe der Skizze: nach Bauteil (Keramik, Chrom …) oder nach Werkstoff.
Color skizzenFarbe(BildInfo info, String werkstoff) {
  switch (info.art) {
    case BildArt.wc:
    case BildArt.wcSitz:
    case BildArt.waschtisch:
    case BildArt.wanne:
    case BildArt.dusche:
    case BildArt.heizkoerper:
    case BildArt.klimageraet:
    case BildArt.waermepumpe:
    case BildArt.lueftungsgeraet:
    case BildArt.spuelkasten:
    case BildArt.drueckerplatte:
      return const Color(0xFFEEF1F5);
    case BildArt.armatur:
    case BildArt.thermostat:
    case BildArt.manometer:
    case BildArt.filter:
      return const Color(0xFFB8C2CC);
    case BildArt.ausdehnung:
      return const Color(0xFFD64545);
    case BildArt.speicher:
    case BildArt.waermetauscher:
      return const Color(0xFF8FA6BC);
    case BildArt.isolierung:
      return const Color(0xFF424B54);
    case BildArt.werkzeug:
      return const Color(0xFFC0392B);
    case BildArt.schraube:
    case BildArt.schelle:
      return const Color(0xFFA9B3BC);
    case BildArt.vorwand:
    case BildArt.siphon:
      return werkstoff.isEmpty ? const Color(0xFF7F8FA9) : werkstoffFarbe(werkstoff);
    default:
      return werkstoffFarbe(werkstoff);
  }
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
    this.foto,
  });

  final KatalogArtikel artikel;
  final IconData fallback;
  final double groesse;

  /// Pfad eines echten Produktfotos (Asset oder Datei). Fehlt es oder lässt es
  /// sich nicht laden, zeigt die Karte die Skizze – gleiche Größe, gleiches Layout.
  final String? foto;

  Widget _skizze(BuildContext context, BoxDecoration rahmen) {
    final info = bildInfo(artikel);
    final scheme = Theme.of(context).colorScheme;
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
      padding: EdgeInsets.all(groesse * 0.055),
      child: CustomPaint(
        painter: _SkizzenMaler(
          info,
          skizzenFarbe(info, artikel.werkstoffAnzeige),
          scheme.onSurface.withValues(alpha: 0.75),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rahmen = BoxDecoration(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: scheme.outlineVariant),
    );
    final f = foto;
    if (f != null && f.isNotEmpty) {
      Widget fehler(BuildContext c, Object e, StackTrace? st) => _skizze(c, rahmen);
      final bild = f.startsWith('assets/')
          ? Image.asset(f, fit: BoxFit.contain, errorBuilder: fehler)
          : Image.file(File(f), fit: BoxFit.contain, errorBuilder: fehler);
      return Container(
        width: groesse,
        height: groesse,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(3),
        child: bild,
      );
    }
    return _skizze(context, rahmen);
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
      default:
        _geraete(canvas);
        break;
    }
    canvas.restore();
  }

  Paint get _fuell => Paint()..color = farbe;
  Paint get _rand => Paint()
    ..color = kontur
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  void _form(Canvas c, Path p, {Color? farbeX}) {
    c.drawPath(p, Paint()..color = farbeX ?? farbe);
    c.drawPath(p, _rand);
  }

  void _rr(Canvas c, double l, double t, double r, double b, double rad, {Color? farbeX}) {
    final p = Path()..addRRect(RRect.fromLTRBR(l, t, r, b, Radius.circular(rad)));
    _form(c, p, farbeX: farbeX);
  }

  void _oval(Canvas c, double l, double t, double r, double b, {Color? farbeX}) {
    final p = Path()..addOval(Rect.fromLTRB(l, t, r, b));
    _form(c, p, farbeX: farbeX);
  }

  void _linie(Canvas c, double x1, double y1, double x2, double y2, {double w = 1.6}) {
    c.drawLine(Offset(x1, y1), Offset(x2, y2), _rand..strokeWidth = w);
  }

  static const Color _dunkel = Color(0xFF8A96A3);

  void _geraete(Canvas c) {
    switch (info.art) {
      case BildArt.wc:
        _rr(c, 20, 6, 44, 26, 3);
        _rr(c, 26, 3, 38, 8, 2, farbeX: _dunkel);
        _oval(c, 12, 26, 52, 50);
        _oval(c, 20, 31, 44, 44, farbeX: Colors.white);
        _rr(c, 22, 48, 42, 58, 3);
        break;
      case BildArt.wcSitz:
        _oval(c, 10, 14, 54, 52);
        _oval(c, 19, 22, 45, 44, farbeX: Colors.white);
        _rr(c, 22, 8, 42, 15, 2, farbeX: _dunkel);
        break;
      case BildArt.waschtisch:
        {
          final p = Path()
            ..moveTo(6, 26)
            ..lineTo(58, 26)
            ..lineTo(52, 48)
            ..quadraticBezierTo(32, 58, 12, 48)
            ..close();
          _form(c, p);
          _oval(c, 14, 29, 50, 42, farbeX: Colors.white);
          _linie(c, 32, 26, 32, 14, w: 3);
          _linie(c, 32, 14, 42, 14, w: 3);
          _linie(c, 42, 14, 42, 19, w: 2.4);
        }
        break;
      case BildArt.armatur:
        _rr(c, 24, 40, 40, 58, 3);
        _rr(c, 28, 20, 36, 42, 2);
        {
          final p = Path()
            ..moveTo(32, 24)
            ..quadraticBezierTo(32, 8, 46, 10)
            ..lineTo(52, 10)
            ..lineTo(52, 17)
            ..lineTo(47, 17)
            ..quadraticBezierTo(40, 17, 40, 26)
            ..close();
          _form(c, p);
        }
        _rr(c, 14, 14, 30, 20, 2, farbeX: _dunkel);
        break;
      case BildArt.dusche:
        _oval(c, 10, 8, 44, 26);
        _linie(c, 44, 17, 56, 17, w: 3);
        _linie(c, 56, 17, 56, 56, w: 3);
        for (var i = 0; i < 4; i++) {
          final x = 16.0 + i * 8;
          _linie(c, x, 32, x - 2, 42, w: 1.4);
          _linie(c, x + 3, 40, x + 1, 50, w: 1.4);
        }
        break;
      case BildArt.wanne:
        {
          final p = Path()
            ..moveTo(4, 24)
            ..lineTo(60, 24)
            ..lineTo(56, 46)
            ..quadraticBezierTo(54, 52, 46, 52)
            ..lineTo(18, 52)
            ..quadraticBezierTo(10, 52, 8, 46)
            ..close();
          _form(c, p);
          _linie(c, 12, 30, 52, 30, w: 1.2);
          _rr(c, 10, 52, 18, 58, 1);
          _rr(c, 46, 52, 54, 58, 1);
          _linie(c, 48, 10, 48, 22, w: 3);
          _linie(c, 48, 10, 38, 10, w: 3);
        }
        break;
      case BildArt.siphon:
        {
          final p = Path()
            ..moveTo(14, 6)
            ..lineTo(14, 34)
            ..cubicTo(14, 58, 42, 58, 42, 34)
            ..lineTo(42, 26)
            ..lineTo(58, 26);
          c.drawPath(p, Paint()
            ..color = kontur
            ..style = PaintingStyle.stroke
            ..strokeWidth = _t + 2);
          c.drawPath(p, Paint()
            ..color = farbe
            ..style = PaintingStyle.stroke
            ..strokeWidth = _t);
          _rr(c, 8, 4, 20, 12, 2, farbeX: _dunkel);
        }
        break;
      case BildArt.spuelkasten:
        _rr(c, 8, 14, 56, 54, 5);
        _rr(c, 8, 8, 56, 16, 3, farbeX: _dunkel);
        _oval(c, 25, 28, 39, 40, farbeX: Colors.white);
        break;
      case BildArt.vorwand:
        _rr(c, 8, 4, 56, 60, 2, farbeX: Colors.white);
        _linie(c, 14, 4, 14, 60, w: 3);
        _linie(c, 50, 4, 50, 60, w: 3);
        _rr(c, 20, 10, 44, 30, 3);
        _rr(c, 28, 34, 36, 54, 2, farbeX: _dunkel);
        break;
      case BildArt.drueckerplatte:
        _rr(c, 8, 12, 56, 52, 5);
        _oval(c, 17, 22, 31, 36, farbeX: Colors.white);
        _oval(c, 37, 22, 51, 36, farbeX: Colors.white);
        break;
      case BildArt.heizkoerper:
        _rr(c, 6, 10, 58, 52, 3);
        for (var i = 0; i < 7; i++) {
          _linie(c, 13.0 + i * 6.3, 14, 13.0 + i * 6.3, 48, w: 1.3);
        }
        _rr(c, 9, 52, 15, 58, 1, farbeX: _dunkel);
        _rr(c, 49, 52, 55, 58, 1, farbeX: _dunkel);
        break;
      case BildArt.thermostat:
        _rr(c, 8, 22, 22, 42, 2, farbeX: _dunkel);
        _rr(c, 22, 14, 52, 50, 6);
        _oval(c, 28, 24, 46, 40, farbeX: Colors.white);
        _linie(c, 37, 32, 41, 27, w: 1.8);
        break;
      case BildArt.ausdehnung:
        _oval(c, 10, 6, 54, 50);
        _linie(c, 12, 28, 52, 28, w: 1.2);
        _rr(c, 28, 50, 36, 60, 1, farbeX: _dunkel);
        break;
      case BildArt.waermetauscher:
        _rr(c, 14, 6, 50, 58, 2);
        for (var i = 0; i < 6; i++) {
          _linie(c, 14, 14.0 + i * 8, 50, 14.0 + i * 8, w: 1.2);
        }
        _oval(c, 6, 8, 14, 16, farbeX: _dunkel);
        _oval(c, 50, 8, 58, 16, farbeX: _dunkel);
        _oval(c, 6, 48, 14, 56, farbeX: _dunkel);
        _oval(c, 50, 48, 58, 56, farbeX: _dunkel);
        break;
      case BildArt.speicher:
        _rr(c, 16, 8, 48, 56, 5);
        _linie(c, 16, 14, 48, 14, w: 1.2);
        _linie(c, 16, 50, 48, 50, w: 1.2);
        _rr(c, 8, 18, 16, 24, 1, farbeX: _dunkel);
        _rr(c, 8, 42, 16, 48, 1, farbeX: _dunkel);
        _rr(c, 48, 18, 56, 24, 1, farbeX: _dunkel);
        break;
      case BildArt.waermepumpe:
        _rr(c, 6, 10, 58, 56, 4);
        _oval(c, 14, 16, 50, 50, farbeX: Colors.white);
        for (var i = 0; i < 3; i++) {
          final a = i * 2 * math.pi / 3;
          c.drawLine(
            const Offset(32, 33),
            Offset(32 + 15 * math.cos(a), 33 + 15 * math.sin(a)),
            _rand..strokeWidth = 3.2,
          );
        }
        break;
      case BildArt.klimageraet:
        _rr(c, 4, 14, 60, 40, 5);
        _linie(c, 10, 34, 54, 34, w: 1.6);
        _linie(c, 14, 46, 14, 56, w: 1.4);
        _linie(c, 32, 46, 32, 58, w: 1.4);
        _linie(c, 50, 46, 50, 56, w: 1.4);
        break;
      case BildArt.lueftungsgeraet:
        _rr(c, 6, 20, 58, 56, 3);
        _oval(c, 12, 6, 28, 22, farbeX: _dunkel);
        _oval(c, 36, 6, 52, 22, farbeX: _dunkel);
        _rr(c, 14, 30, 50, 46, 2, farbeX: Colors.white);
        break;
      case BildArt.isolierung:
        {
          final aussen = Path()
            ..moveTo(4, 32)
            ..lineTo(60, 32);
          c.drawPath(aussen, Paint()
            ..color = farbe
            ..style = PaintingStyle.stroke
            ..strokeWidth = 30);
          c.drawPath(aussen, Paint()
            ..color = kontur
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4);
          _linie(c, 4, 17, 60, 17, w: 1.4);
          _linie(c, 4, 47, 60, 47, w: 1.4);
          c.drawPath(aussen, Paint()
            ..color = const Color(0xFFB87333)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 9);
        }
        break;
      case BildArt.schelle:
        {
          final ring = Path()..addOval(const Rect.fromLTRB(14, 14, 50, 50));
          c.drawPath(ring, Paint()
            ..color = farbe
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5);
          c.drawPath(ring, _rand);
          _rr(c, 28, 4, 36, 16, 2, farbeX: _dunkel);
          _linie(c, 32, 0, 32, 6, w: 2.4);
        }
        break;
      case BildArt.schraube:
        _rr(c, 8, 24, 20, 40, 3);
        _rr(c, 20, 28, 56, 36, 1);
        for (var x = 24.0; x < 56; x += 4) {
          _linie(c, x, 28, x + 2, 36, w: 1.1);
        }
        break;
      case BildArt.werkzeug:
        {
          c.save();
          c.translate(32, 32);
          c.rotate(-math.pi / 4);
          _rr(c, -5, -4, 5, 28, 3);
          _oval(c, -11, -22, 11, -2);
          _rr(c, -4, -24, 4, -10, 1, farbeX: Colors.white);
          c.restore();
        }
        break;
      case BildArt.filter:
        _rr(c, 22, 6, 42, 20, 3, farbeX: _dunkel);
        _rr(c, 16, 20, 48, 56, 6);
        _linie(c, 4, 12, 22, 12, w: 5);
        _linie(c, 42, 12, 60, 12, w: 5);
        _linie(c, 24, 32, 40, 32, w: 1.2);
        break;
      case BildArt.manometer:
        _oval(c, 8, 8, 56, 56);
        _oval(c, 13, 13, 51, 51, farbeX: Colors.white);
        _linie(c, 32, 34, 42, 22, w: 2.4);
        for (var i = 0; i < 7; i++) {
          final a = math.pi * (0.75 + i * 0.25 * 1.0);
          _linie(
            c,
            32 + 16 * math.cos(a), 34 + 16 * math.sin(a),
            32 + 19 * math.cos(a), 34 + 19 * math.sin(a),
            w: 1.2,
          );
        }
        break;
      default:
        break;
    }
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
