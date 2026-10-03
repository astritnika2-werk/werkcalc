# WerkCalc – Brand (Branding)

## Emri dhe pozicionimi

- **Emri kryesor:** WerkCalc (shkruhet "WerkCalc", "Werk" i bardhë/blu dhe "Calc" portokalli në logo)
- **Subtitle:** Handwerker Rechner
- **Premtimi:** rechner praktikë për Handwerker, PDF-Angebot profesional, privat dhe offline (pa login, pa GPS, pa kontakte)
- **Toni:** i drejtpërdrejtë, i qartë, teknik por pa zhargon të panevojshëm; gjermanisht si gjuhë kryesore

## Çfarë është e fiksuar teknikisht

| Çfarë | Vlera |
|---|---|
| Emri i shfaqur | WerkCalc |
| Package name / applicationId (Android) dhe më vonë Bundle ID (iOS) | `de.werkcalc.werkcalc` |
| Dart package | `werkcalc` |

Të njëjtën kod e përdorim për iOS (`flutter create --org de.werkcalc --project-name werkcalc --platforms=ios .`),
kështu që nuk duhet ndryshuar asgjë më vonë. `tools/setup_android.sh` e zbaton këtë automatikisht.
Prefiksi `de.werkcalc` ndjek konventën e domain-it të kundërt, ndaj regjistro `werkcalc.de` (nevojitet edhe për faqen
e privatësisë dhe adresën e kontaktit).

## Logoja

Simboli është një **Schraubenmutter** (Sechskant me vrimë) me shenjën **"="** në mes: vegël + llogaritje.
Funksionon edhe në madhësi të vogla (ikona e telefonit).

- Blu: `#0B4A9F` (kryesore), blu e errët `#062A5C` (gradient)
- Portokalli: `#FF8A00` (theksi, "Calc", butonat kryesorë)
- Bardhë për sipërfaqe dhe tekst mbi blu
- Shkronjat: në app sistemi i Material; në materiale DejaVu Sans Bold (licencë e lirë)

Skedarët: `docs/brand/werkcalc_mark.svg`, `docs/brand/werkcalc_logo_on_blue.png`, `docs/brand/werkcalc_logo_on_white.png`,
`docs/store/icon_512.png`, `docs/store/feature_graphic_1024x500.png`. Gjenerohen me `python3 tools/make_brand.py`.

## Tekste për Google Play (draft, gjermanisht)

- **Titulli:** `WerkCalc: Handwerker Rechner`
- **Përshkrimi i shkurtër:** `Rechner, Druckverlust und PDF-Angebot für Heizung, Sanitär, Klima. Offline.`
- **Përshkrimi i plotë:**
  WerkCalc ist der Rechner für Handwerker in Heizung, Sanitär, Klima, Elektro und Bau. Rohrinhalt, Gefälle, Isolierung,
  Heizkörper-Leistung, Druckverlust, Einheiten und Kosten: schnell, mit großen Tasten und einhändig bedienbar.
  Erstelle ein PDF-Angebot mit Kundendaten, Arbeit, Anfahrt, Material und MwSt. und teile es direkt per WhatsApp oder E-Mail.
  Privat und offline: kein Konto, kein Standort, keine Kontakte. Kundendaten werden nicht gespeichert.
  Alle Berechnungen sind Richtwerte ohne Gewähr.

## Para se ta konsiderojmë emrin të përfunduar (kontrolle që duhen bërë)

Kërkimi im në web nuk gjeti një app ose markë me emrin saktë "WerkCalc", por ky nuk është kontroll ligjor. Bëj vetë:

1. **Domain:** kontrollo dhe regjistro `werkcalc.de` (DENIC), opsionalisht edhe `.com`/`.app`.
2. **Marka:** kërko "WerkCalc" dhe variantet (Werk Calc, WerkKalk) në [DPMAregister](https://register.dpma.de/) dhe
   [TMview](https://www.tmdn.org/tmview/) (EUIPO), sidomos në klasat 9 (softuer) dhe 42. Nëse dëshiron mbrojtje, regjistro markën.
3. **Dyqanet:** kërko emrin në Google Play dhe në Apple App Store për ngjashmëri.
4. **Rrjete sociale:** rezervo emrin e përdoruesit nëse planifikon marketing.
