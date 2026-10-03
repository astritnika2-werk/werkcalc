# WerkCalc Master-Katalog SHK

Generische Fachartikel (keine Marken, keine Artikelnummern, keine Preise).
Der Name ist immer die deutsche Fachbezeichnung, z. B. `Kupferrohr Ø22 mm`.

## 17 Hauptkategorien (feste Reihenfolge)

Sanitär / Wasser · Heizung · Wärmeerzeuger · Klima · Lüftung ·
Abwasser / Kanalisation · Rohre · Fittings · Wassertechnik ·
Installation / Montage · Isolierung · Werkzeug · Verbrauchsmaterial ·
Bad / Sanitär-Ausstattung · Regenerative Energien · Messen / Prüfen ·
Elektro / Anschluss für SHK

Jeder Artikel hat: `name`, `einheit`, `kategorie`, `unter` (Unterkategorie),
`familie` (z. B. „Kupferbogen“), `typ` (Filter wie Bogen/T-Stück/Muffe) und
optional `stichworte` (nur für die Suche, z. B. „wc toilette“).

## Erweitern ohne App-Änderung im Code

Neue Artikel können in `assets/katalog/zusatz.json` stehen (Liste oder
`{"artikel": [...]}`). Beim Start werden sie dem Katalog hinzugefügt;
doppelte Namen und ungültige Einträge werden übersprungen.

```json
[
  {"name": "Pressfitting Bogen 90° Ø76 (Edelstahl)", "einheit": "Stk.",
   "kategorie": "Fittings", "unter": "Pressfittings",
   "familie": "Pressfitting", "typ": "Bogen"}
]
```

Später können hier Hersteller, Artikelnummern, Preise und Großhändler
ergänzt werden, ohne die Suche oder die Listen zu ändern.

## Suche

- Jedes Wort muss passen, Reihenfolge egal: `kup 22`, `bogen 22`, `press 22`.
- Zahlen passen nur als ganze Zahl (22 trifft nicht 122).
- Albanisch/Umgangssprache → Fachbegriff (`kSynonyme` in `materialliste.dart`),
  z. B. gyp→Rohr, kthesë→Bogen, mufë→Muffe, lavaman→Waschtisch.
- `stichworte` machen Artikel auch über andere Wörter auffindbar
  (z. B. „wc“ → Spülkasten, Vorwandelement, Drückerplatte).

## Foto oder Skizze, Handelsdaten (ab 0.8)

Jede Katalogkarte zeigt ein **echtes Foto**, wenn eines vorhanden ist, sonst eine
**technische Skizze** (Bauform, Winkel, Enden I/A, Gewinde …). Layout und Funktion der
Karte sind in beiden Fällen gleich; Tippen auf die Karte öffnet die große Ansicht
mit allen Angaben.

Fotos nur mit Nutzungsrecht verwenden – **ohne Lizenz-Eintrag wird kein Foto gezeigt** (siehe `docs/FOTOS.md`). Zuordnung:

1. Feld `foto` im JSON-Eintrag (`assets/produkte/…` oder Dateipfad), oder
2. Datei in `assets/produkte/` mit dem Namen `<EAN>.jpg`, `<artikelnummer>.jpg`
   oder `<artikelname-als-schlüssel>.jpg` (siehe `assets/produkte/LIESMICH.txt`).

Optionale Felder pro Artikel in `assets/katalog/zusatz.json` (alle leer erlaubt):
`hersteller`, `artikelnummer`, `ean`, `foto`, `preis`, `grosshaendler`,
`lagerbestand`, `einheit`, `material`, `dimension`, `details` (Name → Wert).
Ein Eintrag mit dem **Namen eines bestehenden Artikels** ergänzt diesen um die
Handelsdaten; ein neuer Name legt einen neuen Artikel an. Hersteller,
Artikelnummer und EAN sind auch durchsuchbar.

Regel für neue Artikel: nur Varianten aufnehmen, die es im Handel wirklich gibt.
