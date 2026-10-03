# WerkCalc – Handwerker Rechner

Der private Rechner für Handwerker (Heizung, Sanitär, Klima, Elektro, Bau).
Kein Login, kein GPS, keine Kontakte. Kundendaten werden nicht gespeichert. Keine Werbung in dieser Version.

## Festgelegte Kennungen (nach der Veröffentlichung nie ändern)

| Was | Wert |
|---|---|
| Anzeigename | WerkCalc |
| Untertitel | Handwerker Rechner |
| Package name / applicationId (Android, später auch iOS Bundle ID) | `de.werkcalc.werkcalc` |
| Dart-Paket / Projektname | `werkcalc` |

Details zur Marke: `docs/BRANDING.md`.

## Funktionen

Rechner: Rohrinhalt (mm oder Zoll), Rohrlänge & Gefälle, Isolierung, Heizkörper-Leistung, Druckverlust,
kW ↔ BTU/h, Liter ↔ m³, mm ↔ Zoll, Arbeitszeit & Lohn, MwSt.-Rechner, Materialkosten.

PDF-Angebot (Tab "PDF"): Kundenname, Adresse, Projekt, Angebotsnummer (automatischer Zähler),
Datum, Arbeitskosten, Anfahrt, Materialkosten, MwSt. (oder Kleinunternehmer § 19 UStG),
Gesamtpreis. Optional: eigene Firmendaten und kleiner Hinweis "Erstellt mit WerkCalc" mit Logo.
Das PDF wird lokal erzeugt und kann geteilt, gespeichert oder angezeigt werden.

Materialkosten: eigene Artikelliste (Menge × Einzelpreis, netto), Summe mit MwSt. und Übernahme
der Netto-Summe ins PDF-Angebot. Favoriten: Stern bei einem Rechner, erscheint im Tab "Favoriten".
Liste und Favoriten bleiben lokal auf dem Gerät.

## Rechenregeln

- Angebote immer auf Netto-Basis: Positionen (auf Cent gerundet) addieren, einmal MwSt. aufschlagen.
- Druckverlust: Δp = (λ·L/d + Σζ)·ρ·v²/2, λ = 64/Re (laminar) bzw. Colebrook-White;
  Wasser-Stoffwerte nach IAPWS-IF97 (Tabelle in `lib/logic.dart`). Zwischen Re 2.300 und 4.000 weist die App auf Unsicherheit hin.
- Heizkörper-Leistung ist ein Richtwert (W/m², skaliert mit der Raumhöhe), keine Heizlastberechnung (DIN EN 12831).

## Formeln prüfen

```bash
pip install fluids iapws
python3 tools/verify_formulas.py           # unabhängige Prüfung gegen fluids/iapws
python3 tools/verify_formulas.py --dart    # erzeugt die Wasser-Tabelle als Dart-Code
flutter test                               # Dart-Tests (Referenzwerte aus dem Python-Skript)
```

## Starten und APK bauen

Voraussetzung: Flutter SDK (stable) und Android Studio.

```bash
bash tools/setup_android.sh      # erzeugt android/, setzt Name "WerkCalc" und das App-Icon
flutter test
flutter run                      # auf Gerät oder Emulator
flutter build apk --release      # APK zum Testen
flutter build appbundle --release  # AAB für Google Play
```

Ohne lokale Installation: `.github/workflows/build-apk.yml` baut APK und AAB in GitHub Actions.
Weitere Schritte: `docs/GOOGLE_PLAY.md`.

## Marke neu erzeugen

```bash
pip install pillow
python3 tools/make_brand.py      # Icon, Logo (PNG/SVG), Store-Grafiken
```

## Struktur

- `lib/brand.dart`: Name, Farben, Logo-Widgets
- `lib/logic.dart`: Rechenfunktionen, Wasser-Tabelle, Formatierung
- `lib/calc_page.dart`, `lib/calculators.dart`: Rechner-Seiten
- `lib/angebot_page.dart`, `lib/pdf_angebot.dart`, `lib/storage.dart`: PDF-Angebot
- `lib/materialkosten_page.dart`, `lib/favoriten.dart`: Materialliste und Favoriten
- `lib/home_screen.dart`, `lib/welcome_screen.dart`, `lib/theme.dart`: Oberfläche
- `lib/legal_pages.dart`: Datenschutz/Impressum (Entwurf, Platzhalter ausfüllen)
- `tools/`: `verify_formulas.py`, `make_brand.py`, `setup_android.sh`
- `assets/fonts/`: DejaVu Sans für das PDF (€, ä, ö, ü, ß); Lizenz liegt bei
- `docs/`: Marke, Google Play, Datenschutz-Entwurf, Store-Grafiken

## Noch offen

- Impressum und Datenschutz mit echten Angaben füllen (Platzhalter)
- Echte Screenshots für Google Play (nach dem ersten Test auf dem Telefon)
- Signierung und Store-Listing (siehe `docs/GOOGLE_PLAY.md`)
- iOS / App Store, danach AdMob mit Einwilligungsdialog (Google UMP) und Premium
