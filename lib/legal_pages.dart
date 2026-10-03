import 'package:flutter/material.dart';

/// ENTWURF. Muss vor der Veröffentlichung mit den eigenen Angaben ausgefüllt
/// und (am besten) rechtlich geprüft werden. Platzhalter stehen in [ECKIGEN KLAMMERN].
const String kDatenschutzText = '''
Datenschutzerklärung (Entwurf)

Verantwortlicher
[NAME UND ANSCHRIFT DES ANBIETERS EINTRAGEN]
E-Mail: [E-MAIL EINTRAGEN]

Kurzfassung
Diese App benötigt kein Benutzerkonto und fragt keinen Standort, keine Kontakte und keine anderen personenbezogenen Daten ab. Alle Berechnungen finden ausschließlich auf Ihrem Gerät statt. Die App sendet keine Daten an den Anbieter.

Was auf dem Gerät gespeichert wird
• Ihre eigenen Firmendaten (Firmenname, Adresse, USt-IdNr.), nur wenn Sie diese im Angebot eintragen, und ein Zähler für Angebotsnummern. Diese Daten bleiben lokal auf Ihrem Gerät und können durch Löschen der App-Daten oder Deinstallation entfernt werden.
• Angaben zu Ihren Kunden (Name, Adresse, Projekt, Beträge) werden nur zur Erstellung des PDF verwendet und nicht gespeichert.

PDF-Angebote
Das PDF wird lokal auf Ihrem Gerät erzeugt. Wenn Sie ein PDF teilen oder speichern, entscheiden Sie selbst, mit welcher App oder an wen es gesendet wird. Für diese Übertragung gelten die Bestimmungen der von Ihnen gewählten App.

Foto-Scan und Spracheingabe (optional)
• Foto-Scan: Das Foto wird von Ihnen aufgenommen oder gewählt und direkt auf Ihrem Gerät in Text umgewandelt (ML Kit, ohne Internet). Das Foto wird nicht gespeichert und nicht übertragen.
• Spracheingabe: Die App nutzt die Spracherkennung Ihres Android-Geräts (Google). Je nach Geräteeinstellung wird die Aufnahme dabei zur Erkennung an Google gesendet; die App selbst speichert keine Aufnahmen. Die Mikrofon-Erlaubnis wird erst bei der ersten Nutzung abgefragt.

Werbung und Tracking
Diese Version enthält keine Werbung und keine Analyse- oder Tracking-Dienste.

Ihre Rechte
Da der Anbieter keine personenbezogenen Daten von Ihnen erhält, kann er Auskunft, Berichtigung oder Löschung nur für Daten leisten, die ihm vorliegen. Bei Fragen wenden Sie sich an die oben genannte Adresse.

Stand: [DATUM EINTRAGEN]
''';

const String kImpressumText = '''
Impressum (Entwurf)

Angaben gemäß § 5 DDG

[VOLLSTÄNDIGER NAME / FIRMA]
[STRASSE UND HAUSNUMMER]
[PLZ UND ORT]

Kontakt
E-Mail: [E-MAIL EINTRAGEN]
Telefon: [OPTIONAL]

Umsatzsteuer-ID (falls vorhanden)
[USt-IdNr. EINTRAGEN]

Haftungshinweis
Alle Berechnungen in dieser App sind Richtwerte ohne Gewähr. Für Planung, Auslegung und Ausführung bleibt die Fachkraft verantwortlich. Maßgeblich sind die geltenden Normen, Herstellerangaben und Vorschriften.
''';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(text, style: const TextStyle(fontSize: 16, height: 1.4)),
      ),
    );
  }
}
