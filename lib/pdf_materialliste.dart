import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'logic.dart';
import 'materialliste.dart';

const _blau = PdfColor(0.043, 0.290, 0.624);
const _grau = PdfColor(0.33, 0.33, 0.33);
const _linie = PdfColor(0.8, 0.8, 0.8);

/// Erzeugt die Materialliste als PDF (lokal, ohne Übertragung).
/// Jede Zeile hat ein leeres Kästchen zum Abhaken auf der Baustelle.
Future<Uint8List> buildMaterialListePdf(
  Baustelle b, {
  required ByteData regular,
  required ByteData bold,
  Uint8List? logo,
  bool markenHinweis = true,
  DateTime? datum,
}) async {
  final logoBild = (logo != null && markenHinweis) ? pw.MemoryImage(logo) : null;
  final doc = pw.Document(
    title: 'Materialliste ${b.name}',
    theme: pw.ThemeData.withFont(
      base: pw.Font.ttf(regular),
      bold: pw.Font.ttf(bold),
    ),
  );

  pw.Widget zeile(ListenArtikel a) {
    final style = pw.TextStyle(
      fontSize: 12,
      color: a.erledigt ? _grau : PdfColors.black,
      decoration: a.erledigt ? pw.TextDecoration.lineThrough : null,
    );
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 7),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _linie, width: 0.5),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 12,
            height: 12,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _grau, width: 1),
            ),
            child: a.erledigt
                ? pw.Center(
                    child: pw.Text('x', style: const pw.TextStyle(fontSize: 10)),
                  )
                : null,
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(child: pw.Text(a.name, style: style)),
          pw.SizedBox(width: 12),
          pw.Text(
            '${formatMenge(a.menge)} ${a.einheit}',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(44, 40, 44, 40),
      header: (context) => context.pageNumber == 1
          ? pw.SizedBox()
          : pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Text(
                'Materialliste: ${b.name}',
                style: const pw.TextStyle(fontSize: 9, color: _grau),
              ),
            ),
      footer: (context) => pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              'Seite ${context.pageNumber} von ${context.pagesCount}',
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
      build: (context) => [
        pw.Text(
          'Materialliste',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: _blau,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Baustelle: ${b.name}',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          'Datum: ${formatDatum(datum ?? DateTime.now())}   '
          'Positionen: ${b.anzahl}',
          style: const pw.TextStyle(fontSize: 10, color: _grau),
        ),
        pw.SizedBox(height: 18),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: _blau, width: 1.2),
            ),
          ),
          child: pw.Row(
            children: [
              pw.SizedBox(width: 24),
              pw.Expanded(
                child: pw.Text(
                  'Material',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Text(
                'Menge',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
        if (b.artikel.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 14),
            child: pw.Text('Noch keine Positionen.'),
          )
        else
          for (final a in b.artikel) zeile(a),
      ],
    ),
  );

  return doc.save();
}

/// Lädt Schrift und Logo aus den App-Assets und erzeugt das PDF.
Future<Uint8List> erzeugeMaterialListePdf(
  Baustelle b, {
  bool markenHinweis = true,
}) async {
  final regular = await rootBundle.load('assets/fonts/DejaVuSans.ttf');
  final bold = await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf');
  final logoData = await rootBundle.load('assets/brand/logo_mark_color.png');
  final logo = logoData.buffer.asUint8List(
    logoData.offsetInBytes,
    logoData.lengthInBytes,
  );
  return buildMaterialListePdf(
    b,
    regular: regular,
    bold: bold,
    logo: logo,
    markenHinweis: markenHinweis,
  );
}
