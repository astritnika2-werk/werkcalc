# Produktfotos und Foto-Erkennung (Konzept)

## Grundsatz
Die App zeigt **nur Fotos mit nachweisbarem Nutzungsrecht**. Sonst zeigt sie die
technische Skizze. Karte, Suche und Liste funktionieren in beiden Fällen gleich.

## Was schon vorbereitet ist (ab 0.9)
- Jeder Artikel kann `foto`, `fotoLizenz`, `fotoQuelle`, `fotoUrheber` tragen
  (`assets/katalog/zusatz.json`) oder eine Bilddatei in `assets/produkte/`
  (Dateiname = EAN, Artikelnummer oder Namens-Schlüssel) mit Eintrag in
  `assets/produkte/fotos.json`.
- **Ohne Lizenz-Eintrag wird kein Foto angezeigt** (hart im Code, `fotoRecht`).
- Die große Ansicht zeigt unter dem Bild „Foto · © Urheber · Lizenz · Quelle“.
- `findeNachKennung(code, katalog)` identifiziert einen Artikel über EAN oder
  Artikelnummer – Basis für spätere Barcode-Erkennung.
- Kein Umbau des Katalogs nötig: Fotos und Handelsdaten kommen später nur als Daten dazu.

## Erlaubte Fotoquellen
1. Eigene Aufnahmen (Foto des Produkts durch uns).
2. Herstellerfotos **mit schriftlicher Freigabe** (z. B. Pressebereich/Medienportal
   des Herstellers, Händlervereinbarung). Freigabe in `fotos.json` vermerken.
3. Bilder mit freier Lizenz (z. B. CC0), Lizenz und Quelle eintragen.
4. Eigene Illustrationen/Skizzen (wie jetzt).

**Nicht erlaubt:** Fotos oder Texte von OBI, Hornbach, Bauhaus oder anderen Shops
kopieren oder automatisch einlesen.

## OBI / Hornbach / Bauhaus als Referenz
Nur zum **Prüfen, ob ein Produkt oder eine Variante existiert** (von Hand, als
Nachschlagewerk). Es werden keine Bilder, Beschreibungen oder Preise übernommen.
EAN und technische Eckdaten (Maße, Werkstoff) sind Fakten und dürfen in den
eigenen Katalog – in eigener Formulierung.

## Foto-Erkennung (spätere, eigene Funktion – noch NICHT gebaut)
Stufen, jede für sich nutzbar:
1. **Barcode/EAN scannen** (Kamera, offline, ML Kit Barcode) → `findeNachKennung`.
   Genaueste Methode, sobald Katalogartikel EANs tragen.
2. **Artikelnummer/Typenschild per Text-Erkennung** (wie der Foto-Scan der Liste) → `findeNachKennung`.
3. **Produktfoto → Möglicher Treffer**: braucht ein Erkennungsmodell und
   Referenzbilder mit Lizenz; erst nach 1 und 2 sinnvoll. Immer mit „Mögliche
   Treffer“ (2–3 Artikel) und Auswahl durch den Nutzer, nie automatisch.
Ergebnis in allen Stufen: Karte mit Foto/Skizze, Name, Kategorie, Hersteller,
Artikelnummer, EAN, Maß/Ausführung und „Zur Materialliste hinzufügen“.
Voraussetzung: Katalog mit gepflegten Herstellerdaten (EAN, Artikelnummer).
