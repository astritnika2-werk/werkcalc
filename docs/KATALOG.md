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
