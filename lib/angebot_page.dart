import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import 'logic.dart';
import 'pdf_angebot.dart';
import 'storage.dart';

/// PDF-Angebot: Formular, Live-Summen, PDF lokal erzeugen, teilen oder anzeigen.
/// Kundendaten werden NICHT gespeichert; nur Firmendaten (optional) und der
/// Angebotszähler bleiben lokal auf dem Gerät.
class AngebotPage extends StatefulWidget {
  const AngebotPage({super.key});

  @override
  State<AngebotPage> createState() => _AngebotPageState();
}

class _AngebotPageState extends State<AngebotPage> {
  final _kunde = TextEditingController();
  final _adresse = TextEditingController();
  final _projekt = TextEditingController();
  final _nummer = TextEditingController();
  final _arbeit = TextEditingController();
  final _anfahrt = TextEditingController();
  final _material = TextEditingController();
  final _mwst = TextEditingController(text: '19');
  final _firma = TextEditingController();
  final _firmaAdresse = TextEditingController();
  final _ustId = TextEditingController();

  DateTime _datum = DateTime.now();
  bool _klein = false;
  bool _marke = true;
  bool _busy = false;
  int _laufnummer = 1;

  @override
  void initState() {
    super.initState();
    materialUebernahme.addListener(_aufMaterial);
    _laden();
  }

  /// Netto-Summe aus der Materialliste übernehmen.
  void _aufMaterial() {
    final wert = materialUebernahme.value;
    if (wert == null) return;
    materialUebernahme.value = null;
    if (!mounted) return;
    setState(() => _material.text = wert.toStringAsFixed(2).replaceAll('.', ','));
  }

  @override
  void dispose() {
    materialUebernahme.removeListener(_aufMaterial);
    for (final c in [
      _kunde, _adresse, _projekt, _nummer, _arbeit, _anfahrt, _material,
      _mwst, _firma, _firmaAdresse, _ustId,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _laden() async {
    final absender = await AngebotStorage.ladeAbsender();
    final nr = await AngebotStorage.naechsteLaufnummer(_datum.year);
    if (!mounted) return;
    setState(() {
      _firma.text = absender.name;
      _firmaAdresse.text = absender.adresse;
      _ustId.text = absender.ustId;
      _laufnummer = nr;
      if (_nummer.text.isEmpty) {
        _nummer.text = formatAngebotsnummer(_datum.year, nr);
      }
    });
  }

  Future<void> _neuesAngebot() async {
    final nr = await AngebotStorage.naechsteLaufnummer(DateTime.now().year);
    if (!mounted) return;
    setState(() {
      for (final c in [_kunde, _adresse, _projekt, _arbeit, _anfahrt, _material]) {
        c.clear();
      }
      _mwst.text = '19';
      _klein = false;
      _datum = DateTime.now();
      _laufnummer = nr;
      _nummer.text = formatAngebotsnummer(_datum.year, nr);
    });
  }

  double _zahl(TextEditingController c) => parseNum(c.text) ?? 0;

  Angebot get _betraege => berechneAngebotAusBetraegen(
        arbeit: _zahl(_arbeit),
        anfahrt: _zahl(_anfahrt),
        material: _zahl(_material),
        mwstProzent: _klein ? 0 : (parseNum(_mwst.text) ?? 19),
      );

  Absender get _absender => Absender(
        name: _firma.text.trim(),
        adresse: _firmaAdresse.text.trim(),
        ustId: _ustId.text.trim(),
      );

  String _dateiname() {
    final n = _nummer.text.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return n.isEmpty ? 'Angebot.pdf' : 'Angebot_$n.pdf';
  }

  Future<Uint8List> _erzeugePdf() async {
    final regular = await rootBundle.load('assets/fonts/DejaVuSans.ttf');
    final bold = await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf');
    final logoData = await rootBundle.load('assets/brand/logo_mark_color.png');
    final logo = logoData.buffer.asUint8List(
      logoData.offsetInBytes,
      logoData.lengthInBytes,
    );
    final daten = AngebotDaten(
      nummer: _nummer.text.trim(),
      datum: _datum,
      kundenname: _kunde.text.trim(),
      adresse: _adresse.text.trim(),
      projekt: _projekt.text.trim(),
      betraege: _betraege,
      mwstProzent: _klein ? 0 : (parseNum(_mwst.text) ?? 19),
      kleinunternehmer: _klein,
      markenHinweis: _marke,
      absender: _absender,
    );
    final bytes = await buildAngebotPdf(
      daten,
      regular: regular,
      bold: bold,
      logo: logo,
    );
    await AngebotStorage.speichereAbsender(_absender);
    if (_nummer.text.trim() == formatAngebotsnummer(_datum.year, _laufnummer)) {
      await AngebotStorage.laufnummerVergeben(_datum.year, _laufnummer);
    }
    return bytes;
  }

  Future<void> _ausfuehren(Future<void> Function() aktion) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await aktion();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF konnte nicht erstellt werden.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _teilen() => _ausfuehren(() async {
        final bytes = await _erzeugePdf();
        await Printing.sharePdf(bytes: bytes, filename: _dateiname());
      });

  Future<void> _anzeigen() => _ausfuehren(() async {
        final bytes = await _erzeugePdf();
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: _dateiname(),
        );
      });

  Future<void> _datumWaehlen() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _datum,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _datum = d);
  }

  Widget _feld(
    TextEditingController c,
    String label, {
    String? suffix,
    bool zahl = false,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: zahl
            ? const TextInputType.numberWithOptions(decimal: true)
            : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
        textCapitalization:
            zahl ? TextCapitalization.none : TextCapitalization.sentences,
        inputFormatters:
            zahl ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))] : null,
        style: const TextStyle(fontSize: 20),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          filled: true,
          fillColor: Colors.white,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _abschnitt(String text) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );

  Widget _summe(String label, String wert, {bool gross = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: gross ? 18 : 16,
                  fontWeight: gross ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            Text(
              wert,
              style: TextStyle(
                fontSize: gross ? 22 : 17,
                fontWeight: gross ? FontWeight.w800 : FontWeight.w600,
                color: gross ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final b = _betraege;
    final satz = _klein ? 0.0 : (parseNum(_mwst.text) ?? 19);
    final bereit = b.netto > 0 && !_busy;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Angebot erstellen'),
        actions: [
          IconButton(
            tooltip: 'Neues Angebot',
            icon: const Icon(Icons.note_add),
            onPressed: _neuesAngebot,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _abschnitt('Kunde'),
          _feld(_kunde, 'Kundenname'),
          _feld(_adresse, 'Adresse', maxLines: 2),
          _feld(_projekt, 'Projekt'),
          _abschnitt('Angebot'),
          _feld(_nummer, 'Angebotsnummer'),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: InkWell(
              onTap: _datumWaehlen,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Datum',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                child: Text(formatDatum(_datum), style: const TextStyle(fontSize: 20)),
              ),
            ),
          ),
          _abschnitt('Beträge (netto)'),
          _feld(_arbeit, 'Arbeitskosten', suffix: '€', zahl: true),
          _feld(_anfahrt, 'Anfahrt', suffix: '€', zahl: true),
          _feld(_material, 'Materialkosten', suffix: '€', zahl: true),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Kleinunternehmer (§ 19 UStG)'),
            subtitle: const Text('Keine MwSt., Hinweis im PDF'),
            value: _klein,
            onChanged: (v) => setState(() => _klein = v),
          ),
          _feld(_mwst, 'MwSt.-Satz', suffix: '%', zahl: true, enabled: !_klein),
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _summe('Zwischensumme (netto)', '${fmt(b.netto)} €'),
                  _summe(
                    'MwSt. (${fmt(satz, digits: satz % 1 == 0 ? 0 : 1)} %)',
                    '${fmt(b.mwst)} €',
                  ),
                  const Divider(),
                  _summe('Gesamtpreis (brutto)', '${fmt(b.brutto)} €', gross: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hinweis „Erstellt mit WerkCalc“ im PDF'),
            subtitle: const Text('Kleines Logo am Seitenende'),
            value: _marke,
            onChanged: (v) => setState(() => _marke = v),
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Meine Firmendaten (optional)'),
            subtitle: const Text('Nur auf diesem Gerät gespeichert'),
            childrenPadding: const EdgeInsets.only(top: 8),
            children: [
              _feld(_firma, 'Firmenname'),
              _feld(_firmaAdresse, 'Firmenadresse', maxLines: 2),
              _feld(_ustId, 'USt-IdNr. / Steuernummer'),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  onPressed: bereit ? _teilen : null,
                  icon: const Icon(Icons.ios_share),
                  label: const Text('PDF teilen / speichern'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 17),
                  ),
                  onPressed: bereit ? _anzeigen : null,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF anzeigen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
