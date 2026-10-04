# Ideen für spätere Versionen (nicht geplant für 0.9)

## 📡 Pumpe prüfen / Pumpen-Diagnose (Idee des Nutzers)
Ziel: Per Telefon Hersteller, Modell, Artikelnummer, Status (läuft/steht/Störung),
Drehzahl, Leistung, Temperatur, Förder­strom/-höhe, Fehler anzeigen; ohne
Verbindung: 📷 Typenschild scannen → OCR → Katalog.

Erste Einschätzung (zu prüfen, vorläufig – Stand eigenes Wissen, nicht verifiziert):
- Hersteller-Apps (z. B. Grundfos GO, Wilo-Assistent) nutzen herstellereigene
  Verbindungen (Bluetooth-/Funk-/IR-Module). Öffentliche Schnittstellen
  (Protokoll-Dokumentation, SDK) sind mir nicht bekannt.
- Protokolle nachbauen/auslesen (Reverse Engineering) ist rechtlich und
  technisch riskant und kommt nicht in Frage. Mögliche Wege nur über offizielle,
  dokumentierte Schnittstellen oder Kooperation/Lizenz des Herstellers.
- Offene Standards (z. B. Modbus, BACnet) gibt es meist bei größeren Pumpen über
  kabelgebundene Module/Gateways – kein direkter Handy-Zugriff.
- Machbar ohne Hersteller-Protokoll: **Typenschild scannen** (Foto → Texterkennung
  → Hersteller/Modell/Artikelnummer → Treffer im WerkCalc-Katalog, Nutzer
  bestätigt). Die Texterkennung gibt es schon (Scan-Funktion), es fehlen nur
  Pumpen-Katalogdaten mit nachweisbarer Quelle.
Vorgehen später: 1) Herstellerdokumentation/Lizenzbedingungen prüfen,
2) Typenschild-Erkennung als erster Schritt, 3) Live-Daten nur bei offiziell
freigegebener Schnittstelle.
