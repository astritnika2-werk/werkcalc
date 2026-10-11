# Rohrrauheit in WerkCalc (Druckverlust, Pumpe wählen)

Die Rechner verwenden den Wert als **absolute Rauheit k in mm**: relative Rauheit = k / Innendurchmesser,
Rohrreibungszahl nach Colebrook-White (laminar 64/Re). Siehe `reibungsbeiwert` in `lib/logic.dart`.

| Auswahl in der App | Wert | Quelle | Einschränkung |
|---|---|---|---|
| Edelstahl – Oberflächenrauheit 1,5 μm laut Herstellerangabe | 0,0015 mm | Pipelife, Technisches Handbuch C-Press Edelstahl & C-Stahl (Ausgabe 4/2023), Abschnitt 5.1, Tabelle technische Daten: „Oberflächenrauheit 1,5 μm“ | Herstellerangabe für dieses System. Das Dokument bezeichnet den Wert nicht als „k“. **Kein allgemeingültiger Wert für jedes Edelstahlrohr.** WerkCalc verwendet ihn als k. |
| Mehrschichtverbund / PE-RT – k = 0,007 mm laut Herstellerangabe | 0,007 mm | Pipetec, Technisches Handbuch (Produktkatalog 2026), Tabelle „Rohrwandrauhigkeitswerte“: Pipetec/Kunststoff 0,007 mm | Herstellerangabe für Pipetec-Verbundrohr / PE-RT. |

Kupfer: Dieselbe Pipetec-Tabelle nennt 0,0015 mm (neu) für Kupfer; Kupfer ist in der App nicht separat wählbar.

Alle Rechenergebnisse sind Richtwerte; maßgeblich sind die Unterlagen des jeweiligen Herstellers und die technischen Regeln.
Die Formel wurde nicht verändert; Vergleichstests siehe `test/rechner_pruefung_test.dart` (Colebrook-Gegenrechnung).
