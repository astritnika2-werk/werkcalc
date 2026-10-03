import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'logic.dart';

class Absender {
  const Absender({this.name = '', this.adresse = '', this.ustId = ''});

  final String name;
  final String adresse;
  final String ustId;

  bool get isEmpty => name.isEmpty && adresse.isEmpty && ustId.isEmpty;
}

class AngebotDaten {
  const AngebotDaten({
    required this.nummer,
    required this.datum,
    required this.kundenname,
    required this.adresse,
    required this.projekt,
    required this.betraege,
    required this.mwstProzent,
    this.kleinunternehmer = false,
    this.markenHinweis = true,
    this.absender = const Absender(),
  });

  final String nummer;
  final DateTime datum;
  final String kundenname;
  final String adresse;
  final String projekt;
  final Angebot betraege;
  final double mwstProzent;

  /// Kleinunternehmer nach § 19 UStG: keine Umsatzsteuer, Hinweis im PDF.
  final bool kleinunternehmer;

  /// Kleiner Hinweis "Erstellt mit WerkCalc" mit Logo am Seitenende.
  final bool markenHinweis;
  final Absender absender;
}

const PdfColor _blau = PdfColor(0.043, 0.290, 0.624);
const PdfColor _grau = PdfColor(0.333, 0.333, 0.333);
const PdfColor _linie = PdfColor(0.8, 0.8, 0.8);

String _eur(double v) => '${fmt(v)} €';

/// Erzeugt das PDF komplett auf dem Gerät (kein Server, keine Übertragung).
Future<Uint8List> buildAngebotPdf(
  AngebotDaten d, {
  required ByteData regular,
  required ByteData bold,
  Uint8List? logo,
}) async {
  final logoBild = (logo != null && d.markenHinweis) ? pw.MemoryImage(logo) : null;
  final doc = pw.Document(
    title: 'Angebot ${d.nummer}',
    theme: pw.ThemeData.withFont(
      base: pw.Font.ttf(regular),
      bold: pw.Font.ttf(bold),
    ),
  );

  pw.Widget zeile(String label, String betrag, {bool fett = false, bool oben = false}) {
    final style = pw.TextStyle(
      fontSize: fett ? 13 : 11,
      fontWeight: fett ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 7),
      decoration: oben
          ? const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: _blau, width: 1.2),
                bottom: pw.BorderSide(color: _linie, width: 0.5),
              ),
            )
          : const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: _linie, width: 0.5),
              ),
            ),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label, style: style)),
          pw.Text(betrag, style: style),
        ],
      ),
    );
  }

  final b = d.betraege;
  final mwstText = d.mwstProzent % 1 == 0
      ? fmt(d.mwstProzent, digits: 0)
      : fmt(d.mwstProzent, digits: 1);

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(44, 40, 44, 40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Absender (oben)
          if (!d.absender.isEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (d.absender.name.isNotEmpty)
                  pw.Text(d.absender.name,
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                if (d.absender.adresse.isNotEmpty)
                  pw.Text(d.absender.adresse,
                      style: const pw.TextStyle(fontSize: 10, color: _grau)),
                if (d.absender.ustId.isNotEmpty)
                  pw.Text(d.absender.ustId,
                      style: const pw.TextStyle(fontSize: 10, color: _grau)),
              ],
            ),
          pw.SizedBox(height: 28),
          // Empfänger und Angebotsdaten
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Kunde',
                        style: const pw.TextStyle(fontSize: 9, color: _grau)),
                    pw.SizedBox(height: 3),
                    if (d.kundenname.isNotEmpty)
                      pw.Text(d.kundenname,
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    if (d.adresse.isNotEmpty)
                      pw.Text(d.adresse, style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Angebotsnummer',
                      style: const pw.TextStyle(fontSize: 9, color: _grau)),
                  pw.Text(d.nummer, style: const pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 8),
                  pw.Text('Datum',
                      style: const pw.TextStyle(fontSize: 9, color: _grau)),
                  pw.Text(formatDatum(d.datum), style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 36),
          pw.Text('Angebot',
              style: pw.TextStyle(
                  fontSize: 26, fontWeight: pw.FontWeight.bold, color: _blau)),
          if (d.projekt.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text('Projekt: ${d.projekt}', style: const pw.TextStyle(fontSize: 12)),
          ],
          pw.SizedBox(height: 24),
          // Positionen (netto)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: _blau, width: 1.2)),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text('Position',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Text('Betrag (netto)',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          zeile('Arbeitskosten', _eur(b.arbeit)),
          zeile('Anfahrt', _eur(b.anfahrt)),
          zeile('Materialkosten', _eur(b.material)),
          pw.SizedBox(height: 14),
          // Summen
          zeile('Zwischensumme (netto)', _eur(b.netto)),
          if (d.kleinunternehmer)
            zeile('Umsatzsteuer', _eur(0))
          else
            zeile('MwSt. $mwstText %', _eur(b.mwst)),
          zeile('Gesamtpreis (brutto)', _eur(b.brutto), fett: true, oben: true),
          if (d.kleinunternehmer) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              'Gemäß § 19 UStG wird keine Umsatzsteuer berechnet.',
              style: const pw.TextStyle(fontSize: 10, color: _grau),
            ),
          ],
          pw.Spacer(),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Alle Beträge in Euro.',
                  style: const pw.TextStyle(fontSize: 9, color: _grau),
                ),
              ),
              if (logoBild != null) ...[
                pw.Image(logoBild, width: 14, height: 14),
                pw.SizedBox(width: 5),
                pw.Text(
                  'Erstellt mit WerkCalc',
                  style: const pw.TextStyle(fontSize: 9, color: _grau),
                ),
              ],
            ],
          ),
        ],
      ),
    ),
  );

  return doc.save();
}
