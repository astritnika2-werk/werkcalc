import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'logic.dart' show parseNum;
import 'pumpen_logik.dart';
import 'pumpen_store.dart';

String _zahl(double v, [int d = 2]) => v.toStringAsFixed(d).replaceAll('.', ',');

/// Pumpe prüfen: Betriebspunkt (Q, H) gegen die Kennlinie einer konkreten
/// Pumpe. Es gibt keine eingebauten Pumpendaten – ohne Kennlinie ist keine
/// Prüfung möglich.
class PumpenPruefungPage extends StatefulWidget {
  const PumpenPruefungPage({super.key, this.q, this.h});

  /// Vorbelegung aus „Pumpe wählen“ (m³/h und m).
  final double? q;
  final double? h;

  @override
  State<PumpenPruefungPage> createState() => _PumpenPruefungPageState();
}

class _PumpenPruefungPageState extends State<PumpenPruefungPage> {
  late final TextEditingController _q;
  late final TextEditingController _h;
  List<PumpenDaten> _pumpen = [];
  String? _pumpeId;
  int _kurveIdx = 0;

  @override
  void initState() {
    super.initState();
    _q = TextEditingController(text: widget.q == null ? '' : _zahl(widget.q!));
    _h = TextEditingController(text: widget.h == null ? '' : _zahl(widget.h!));
    _lade();
  }

  @override
  void dispose() {
    _q.dispose();
    _h.dispose();
    super.dispose();
  }

  Future<void> _lade({String? waehle}) async {
    final liste = await PumpenStore.ladeAlle();
    if (!mounted) return;
    setState(() {
      _pumpen = liste;
      if (waehle != null && liste.any((p) => p.id == waehle)) {
        _pumpeId = waehle;
        _kurveIdx = 0;
      } else if (_pumpeId == null || !liste.any((p) => p.id == _pumpeId)) {
        _pumpeId = liste.isEmpty ? null : liste.first.id;
        _kurveIdx = 0;
      }
    });
  }

  PumpenDaten? get _pumpe {
    for (final p in _pumpen) {
      if (p.id == _pumpeId) return p;
    }
    return null;
  }

  Future<void> _bearbeiten(PumpenDaten? vorhanden) async {
    final neu = await Navigator.of(context).push<PumpenDaten>(
      MaterialPageRoute(builder: (_) => PumpeEditPage(vorhanden: vorhanden)),
    );
    if (neu != null) await _lade(waehle: neu.id);
  }

  Future<void> _loeschen(PumpenDaten p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Pumpe löschen?'),
        content: Text('${p.titel} wird von diesem Gerät entfernt.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (ok == true) {
      await PumpenStore.loesche(p.id);
      await _lade();
    }
  }

  InputDecoration _dec(String label, String unit) => InputDecoration(
        labelText: label,
        suffixText: unit,
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      );

  Widget _zahlFeld(TextEditingController c, String label, String unit) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        style: const TextStyle(fontSize: 22),
        decoration: _dec(label, unit),
        onChanged: (_) => setState(() {}),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final q = parseNum(_q.text);
    final h = parseNum(_h.text);
    final pumpe = _pumpe;
    final kurve = (pumpe != null && pumpe.kurven.isNotEmpty)
        ? pumpe.kurven[_kurveIdx.clamp(0, pumpe.kurven.length - 1).toInt()]
        : null;
    final bereit = q != null && h != null && q > 0 && h > 0;
    final pr = bereit ? pruefePumpe(q: q, h: h, kurve: kurve) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Pumpe prüfen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Der Betriebspunkt (Q, H) wird mit der Q/H-Kennlinie der gewählten Pumpe '
            'verglichen. WerkCalc gibt keine Pumpendaten vor: Die Kennlinie kommt '
            'aus dem Datenblatt des Herstellers.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _zahlFeld(_q, 'Volumenstrom Q', 'm³/h'),
          const SizedBox(height: 14),
          _zahlFeld(_h, 'Erforderliche Förderhöhe H', 'm'),
          const SizedBox(height: 20),
          Text('Pumpe', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_pumpen.isEmpty)
            Text(
              'Noch keine Pumpe gespeichert. Mit „Pumpe eingeben“ Hersteller, Modell '
              'und Kennlinie aus dem Datenblatt erfassen.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16),
            )
          else
            InputDecorator(
              decoration: _dec('Gewählte Pumpe', ''),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _pumpeId,
                  isExpanded: true,
                  items: [
                    for (final p in _pumpen)
                      DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(
                          '${p.titel}${p.verifiziert ? '  ✓ Herstellerdaten' : '  (eigene Eingabe)'}',
                          style: const TextStyle(fontSize: 17),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() {
                    _pumpeId = v;
                    _kurveIdx = 0;
                  }),
                ),
              ),
            ),
          if (pumpe != null && pumpe.kurven.length > 1) ...[
            const SizedBox(height: 12),
            InputDecorator(
              decoration: _dec('Kennlinie', ''),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _kurveIdx.clamp(0, pumpe.kurven.length - 1).toInt(),
                  isExpanded: true,
                  items: [
                    for (var i = 0; i < pumpe.kurven.length; i++)
                      DropdownMenuItem<int>(
                        value: i,
                        child: Text(pumpe.kurven[i].name, style: const TextStyle(fontSize: 17)),
                      ),
                  ],
                  onChanged: (v) => setState(() => _kurveIdx = v ?? 0),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _bearbeiten(null),
                icon: const Icon(Icons.add),
                label: const Text('Pumpe eingeben'),
              ),
              if (pumpe != null && !pumpe.verifiziert)
                OutlinedButton.icon(
                  onPressed: () => _bearbeiten(pumpe),
                  icon: const Icon(Icons.edit),
                  label: const Text('Bearbeiten'),
                ),
              if (pumpe != null && !pumpe.verifiziert)
                OutlinedButton.icon(
                  onPressed: () => _loeschen(pumpe),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Löschen'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (pr == null)
            Text(
              'Bitte Q und H eingeben.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16),
            )
          else ...[
            _Ergebnis(pr: pr),
            if (kurve != null && pruefeKurve(kurve.normiert) == null) ...[
              const SizedBox(height: 12),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 12, 8),
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 1.25,
                        child: CustomPaint(
                          painter: _QhPainter(
                            kurve: kurve.normiert,
                            q: q,
                            h: h,
                            schnittQ: pr.schnittQ,
                            schnittH: pr.schnittH,
                            textFarbe: scheme.onSurface,
                            kurvenFarbe: scheme.primary,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: const [
                          _Legende(Color(0xFF0B4A9F), 'Pumpenkennlinie'),
                          _Legende(Color(0xFFFF8A00), 'Anlagenkennlinie (H ∝ Q²)'),
                          _Legende(Color(0xFFD32F2F), 'Betriebspunkt'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
          if (pumpe != null) ...[
            const SizedBox(height: 12),
            _PumpenInfo(pumpe: pumpe),
          ],
          const SizedBox(height: 12),
          Text(
            'Bewertungsregel (Richtwert): geeignet, wenn die Kennlinie beim geforderten Q '
            'mindestens das ${_zahl(kPumpeReserveGeeignet, 1)}-fache der benötigten '
            'Förderhöhe liefert und Q nicht im letzten ${_zahl((1 - kPumpeQNahEnde) * 100, 0)} % '
            'der Kennlinie liegt. Maßgeblich bleiben Herstellerangaben und geltende '
            'technische Regeln. Die Richtigkeit eigener Eingaben liegt beim Nutzer.',
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _Ergebnis extends StatelessWidget {
  const _Ergebnis({required this.pr});

  final PumpenPruefung pr;

  @override
  Widget build(BuildContext context) {
    final Color farbe;
    switch (pr.eignung) {
      case Eignung.geeignet:
        farbe = const Color(0xFF2E7D32);
        break;
      case Eignung.grenzbereich:
        farbe = const Color(0xFFEF6C00);
        break;
      case Eignung.nichtGeeignet:
        farbe = const Color(0xFFC62828);
        break;
      case Eignung.nichtPruefbar:
        farbe = const Color(0xFF546E7A);
        break;
    }
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: farbe, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eignungText(pr.eignung),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: farbe),
            ),
            const SizedBox(height: 10),
            for (final g in pr.gruende)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(child: Text(g, style: const TextStyle(fontSize: 16))),
                  ],
                ),
              ),
            if (pr.hKurveAmBetriebspunkt != null) ...[
              const Divider(height: 24),
              _Zeile('Kennlinie bei Q', '${_zahl(pr.hKurveAmBetriebspunkt!)} m'),
              if (pr.reserveH != null)
                _Zeile('Reserve Förderhöhe', '${_zahl(pr.reserveH! * 100, 0)} %'),
              if (pr.reserveQ != null)
                _Zeile('Reserve Volumenstrom', '${_zahl(pr.reserveQ! * 100, 0)} %'),
              if (pr.qMax != null) _Zeile('Kurvenende Q', '${_zahl(pr.qMax!)} m³/h'),
            ],
          ],
        ),
      ),
    );
  }
}

class _Zeile extends StatelessWidget {
  const _Zeile(this.label, this.wert);

  final String label;
  final String wert;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
            Text(wert, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _Legende extends StatelessWidget {
  const _Legende(this.farbe, this.text);

  final Color farbe;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 14, height: 14, decoration: BoxDecoration(color: farbe, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      );
}

class _PumpenInfo extends StatelessWidget {
  const _PumpenInfo({required this.pumpe});

  final PumpenDaten pumpe;

  @override
  Widget build(BuildContext context) {
    Widget zeile(String l, String v) => v.trim().isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 120, child: Text(l, style: const TextStyle(fontSize: 14, color: Colors.black54))),
                Expanded(child: Text(v, style: const TextStyle(fontSize: 15))),
              ],
            ),
          );
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pumpe.titel, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            zeile('Hersteller', pumpe.hersteller),
            zeile('Modell', pumpe.modell),
            zeile('Artikelnummer', pumpe.artikelnummer),
            zeile('Anschluss', pumpe.anschluss),
            zeile('Baulänge', pumpe.baulaenge),
            zeile('Quelle Kennlinie', pumpe.quelle),
            zeile(
              'Datenstatus',
              pumpe.verifiziert
                  ? 'Herstellerdaten (geprüft)'
                  : 'Eigene Eingabe – nicht von WerkCalc geprüft',
            ),
          ],
        ),
      ),
    );
  }
}

/// Q/H-Diagramm: Pumpenkennlinie, Anlagenkennlinie durch den Betriebspunkt
/// (H ∝ Q²), Betriebspunkt und – falls vorhanden – Schnittpunkt.
class _QhPainter extends CustomPainter {
  _QhPainter({
    required this.kurve,
    required this.q,
    required this.h,
    required this.schnittQ,
    required this.schnittH,
    required this.textFarbe,
    required this.kurvenFarbe,
  });

  final List<QH> kurve;
  final double q;
  final double h;
  final double? schnittQ;
  final double? schnittH;
  final Color textFarbe;
  final Color kurvenFarbe;

  static (double, double) _achse(double maxWert) {
    final roh = maxWert / 5;
    final mag = math.pow(10, (math.log(roh) / math.ln10).floor()).toDouble();
    final norm = roh / mag;
    final schritt = (norm <= 1 ? 1 : (norm <= 2 ? 2 : (norm <= 5 ? 5 : 10))) * mag;
    return (schritt, schritt * (maxWert / schritt).ceil());
  }

  static String _tick(double v) =>
      (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1)).replaceAll('.', ',');

  void _text(Canvas c, String s, Offset o, {bool mitte = false, bool rechts = false, double size = 11}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: size, color: textFarbe)),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = o.dx;
    if (mitte) dx -= tp.width / 2;
    if (rechts) dx -= tp.width;
    tp.paint(c, Offset(dx, o.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const links = 40.0, rechts = 12.0, oben = 10.0, unten = 34.0;
    final w = size.width - links - rechts;
    final hoehe = size.height - oben - unten;
    if (w <= 0 || hoehe <= 0) return;
    final qMaxK = kurve.last.q;
    final hMaxK = kurve.map((p) => p.h).reduce(math.max);
    final (xs, xMax) = _achse(math.max(qMaxK, q) * 1.1);
    final (ys, yMax) = _achse(math.max(hMaxK, h) * 1.1);

    Offset pt(double qq, double hh) =>
        Offset(links + qq / xMax * w, oben + hoehe - hh / yMax * hoehe);

    final gitter = Paint()
      ..color = const Color(0xFFD5DCE6)
      ..strokeWidth = 1;
    final achse = Paint()
      ..color = const Color(0xFF455A64)
      ..strokeWidth = 1.5;

    for (var x = 0.0; x <= xMax + 1e-9; x += xs) {
      final p = pt(x, 0);
      canvas.drawLine(Offset(p.dx, oben), Offset(p.dx, oben + hoehe), gitter);
      _text(canvas, _tick(x), Offset(p.dx, oben + hoehe + 4), mitte: true);
    }
    for (var y = 0.0; y <= yMax + 1e-9; y += ys) {
      final p = pt(0, y);
      canvas.drawLine(Offset(links, p.dy), Offset(links + w, p.dy), gitter);
      _text(canvas, _tick(y), Offset(links - 5, p.dy - 7), rechts: true);
    }
    canvas.drawLine(Offset(links, oben + hoehe), Offset(links + w, oben + hoehe), achse);
    canvas.drawLine(Offset(links, oben), Offset(links, oben + hoehe), achse);
    _text(canvas, 'Q (m³/h)', Offset(links + w / 2, oben + hoehe + 18), mitte: true, size: 12);
    _text(canvas, 'H (m)', const Offset(2, 0), size: 12);

    // Anlagenkennlinie (gestrichelt)
    final sys = Paint()
      ..color = const Color(0xFFFF8A00)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const n = 60;
    for (var i = 0; i < n; i += 2) {
      final q1 = xMax * i / n;
      final q2 = xMax * (i + 1) / n;
      final h1 = h * (q1 / q) * (q1 / q);
      final h2 = h * (q2 / q) * (q2 / q);
      if (h1 > yMax || h2 > yMax) break;
      canvas.drawLine(pt(q1, h1), pt(q2, h2), sys);
    }

    // Pumpenkennlinie
    final linie = Paint()
      ..color = kurvenFarbe
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final pfad = Path()..moveTo(pt(kurve.first.q, kurve.first.h).dx, pt(kurve.first.q, kurve.first.h).dy);
    for (var i = 1; i < kurve.length; i++) {
      final p = pt(kurve[i].q, kurve[i].h);
      pfad.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(pfad, linie);
    final punkt = Paint()..color = kurvenFarbe;
    for (final k in kurve) {
      canvas.drawCircle(pt(k.q, k.h), 3, punkt);
    }

    // Schnittpunkt
    if (schnittQ != null && schnittH != null) {
      canvas.drawCircle(
        pt(schnittQ!, schnittH!),
        6,
        Paint()
          ..color = const Color(0xFFE65100)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Betriebspunkt
    final bp = pt(q, h);
    canvas.drawCircle(bp, 8, Paint()..color = Colors.white);
    canvas.drawCircle(bp, 6, Paint()..color = const Color(0xFFD32F2F));
  }

  @override
  bool shouldRepaint(covariant _QhPainter old) => true;
}

/// Eine Kennlinie im Bearbeiten-Formular.
class _KurveEdit {
  _KurveEdit({String name = 'Max. Kennlinie', String punkte = '', this.qEinheit = 'm3h', this.hEinheit = 'm'})
      : name = TextEditingController(text: name),
        punkte = TextEditingController(text: punkte);

  final TextEditingController name;
  final TextEditingController punkte;
  String qEinheit;
  String hEinheit;

  void dispose() {
    name.dispose();
    punkte.dispose();
  }
}

/// Pumpe mit Daten aus dem Datenblatt erfassen oder bearbeiten.
class PumpeEditPage extends StatefulWidget {
  const PumpeEditPage({super.key, this.vorhanden});

  final PumpenDaten? vorhanden;

  @override
  State<PumpeEditPage> createState() => _PumpeEditPageState();
}

class _PumpeEditPageState extends State<PumpeEditPage> {
  late final TextEditingController _hersteller;
  late final TextEditingController _modell;
  late final TextEditingController _art;
  late final TextEditingController _anschluss;
  late final TextEditingController _baulaenge;
  late final TextEditingController _quelle;
  final List<_KurveEdit> _kurven = [];
  String? _fehler;

  @override
  void initState() {
    super.initState();
    final v = widget.vorhanden;
    _hersteller = TextEditingController(text: v?.hersteller ?? '');
    _modell = TextEditingController(text: v?.modell ?? '');
    _art = TextEditingController(text: v?.artikelnummer ?? '');
    _anschluss = TextEditingController(text: v?.anschluss ?? '');
    _baulaenge = TextEditingController(text: v?.baulaenge ?? '');
    _quelle = TextEditingController(text: v?.quelle ?? '');
    if (v != null && v.kurven.isNotEmpty) {
      for (final k in v.kurven) {
        _kurven.add(_KurveEdit(
          name: k.name,
          punkte: punkteAlsText(k.punkte),
          qEinheit: k.qEinheit,
          hEinheit: k.hEinheit,
        ));
      }
    } else {
      _kurven.add(_KurveEdit());
    }
  }

  @override
  void dispose() {
    for (final c in [_hersteller, _modell, _art, _anschluss, _baulaenge, _quelle]) {
      c.dispose();
    }
    for (final k in _kurven) {
      k.dispose();
    }
    super.dispose();
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(),
      );

  Widget _feld(TextEditingController c, String label, {String? hint, int lines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          minLines: lines,
          maxLines: lines == 1 ? 1 : 12,
          style: const TextStyle(fontSize: 18),
          decoration: _dec(label, hint: hint),
          onChanged: (_) => setState(() {}),
        ),
      );

  /// Ergebnis der Prüfung einer Kennlinie als Text (grün/rot).
  Widget _kurvenStatus(_KurveEdit k) {
    final r = parsePunkte(k.punkte.text);
    if (k.punkte.text.trim().isEmpty) {
      return const Text('Noch keine Punkte.', style: TextStyle(color: Colors.black54));
    }
    if (r.fehler.isNotEmpty) {
      return Text(r.fehler.first, style: const TextStyle(color: Color(0xFFC62828)));
    }
    final norm = PumpenKurve(
      name: '',
      punkte: r.punkte,
      qEinheit: k.qEinheit,
      hEinheit: k.hEinheit,
    ).normiert;
    final f = pruefeKurve(norm);
    if (f != null) return Text(f, style: const TextStyle(color: Color(0xFFC62828)));
    return Text(
      '✓ ${norm.length} Punkte · Q bis ${_zahl(norm.last.q)} m³/h · H bis ${_zahl(norm.first.h)} m',
      style: const TextStyle(color: Color(0xFF2E7D32)),
    );
  }

  Widget _kurvenKarte(int i) {
    final k = _kurven[i];
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: k.name,
                    decoration: _dec('Name der Kennlinie', hint: 'z. B. Max. Kennlinie oder Stufe 3'),
                  ),
                ),
                if (_kurven.length > 1)
                  IconButton(
                    tooltip: 'Kennlinie entfernen',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() {
                      _kurven.removeAt(i).dispose();
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: _dec('Einheit Q'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: k.qEinheit,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'm3h', child: Text('m³/h')),
                          DropdownMenuItem(value: 'lmin', child: Text('l/min')),
                          DropdownMenuItem(value: 'ls', child: Text('l/s')),
                        ],
                        onChanged: (v) => setState(() => k.qEinheit = v ?? 'm3h'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InputDecorator(
                    decoration: _dec('Einheit H'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: k.hEinheit,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'm', child: Text('m')),
                          DropdownMenuItem(value: 'kpa', child: Text('kPa')),
                        ],
                        onChanged: (v) => setState(() => k.hEinheit = v ?? 'm'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: k.punkte,
              minLines: 5,
              maxLines: 14,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(fontSize: 18),
              decoration: _dec(
                'Punkte (je Zeile: Q H)',
                hint: 'Aus dem Datenblatt abgelesen, Q aufsteigend:\nQ1 H1\nQ2 H2\nQ3 H3 …',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 6),
            _kurvenStatus(k),
          ],
        ),
      ),
    );
  }

  Future<void> _speichern() async {
    String? fehler;
    if (_hersteller.text.trim().isEmpty || _modell.text.trim().isEmpty) {
      fehler = 'Hersteller und Modell angeben.';
    } else if (_quelle.text.trim().isEmpty) {
      fehler = 'Quelle der Kennlinie angeben (z. B. Datenblatt, Seite, Datum).';
    }
    final kurven = <PumpenKurve>[];
    if (fehler == null) {
      for (final k in _kurven) {
        final r = parsePunkte(k.punkte.text);
        if (r.fehler.isNotEmpty) {
          fehler = '${k.name.text}: ${r.fehler.first}';
          break;
        }
        final kurve = PumpenKurve(
          name: k.name.text.trim().isEmpty ? 'Kennlinie' : k.name.text.trim(),
          punkte: r.punkte,
          qEinheit: k.qEinheit,
          hEinheit: k.hEinheit,
        );
        final f = pruefeKurve(kurve.normiert);
        if (f != null) {
          fehler = '${kurve.name}: $f';
          break;
        }
        kurven.add(kurve);
      }
    }
    if (fehler != null) {
      setState(() => _fehler = fehler);
      return;
    }
    final pumpe = PumpenDaten(
      id: widget.vorhanden?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      hersteller: _hersteller.text.trim(),
      modell: _modell.text.trim(),
      artikelnummer: _art.text.trim(),
      anschluss: _anschluss.text.trim(),
      baulaenge: _baulaenge.text.trim(),
      quelle: _quelle.text.trim(),
      kurven: kurven,
    );
    await PumpenStore.speichere(pumpe);
    if (mounted) Navigator.of(context).pop(pumpe);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.vorhanden == null ? 'Pumpe eingeben' : 'Pumpe bearbeiten')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Nur Werte aus dem Datenblatt des Herstellers eingeben – keine geschätzten '
            'Werte. Die Daten bleiben auf diesem Gerät.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          _feld(_hersteller, 'Hersteller *', hint: 'z. B. Grundfos, Wilo, KSB'),
          _feld(_modell, 'Modell *'),
          _feld(_art, 'Artikelnummer'),
          _feld(_anschluss, 'Anschluss / DN / Gewinde'),
          _feld(_baulaenge, 'Baulänge', hint: 'in mm'),
          _feld(_quelle, 'Quelle der Kennlinie *', hint: 'Datenblatt, Seite, Datum oder Link', lines: 2),
          const SizedBox(height: 4),
          Text('Q/H-Kennlinie', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (var i = 0; i < _kurven.length; i++) _kurvenKarte(i),
          OutlinedButton.icon(
            onPressed: () => setState(() => _kurven.add(_KurveEdit(name: 'Kennlinie ${_kurven.length + 1}'))),
            icon: const Icon(Icons.add),
            label: const Text('Weitere Kennlinie (z. B. Stufe)'),
          ),
          if (_fehler != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_fehler!, style: const TextStyle(color: Color(0xFFC62828), fontSize: 16)),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: _speichern,
            icon: const Icon(Icons.save),
            label: const Text('Speichern', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}
