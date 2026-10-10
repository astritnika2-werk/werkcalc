import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:werkcalc/datensicherung.dart';
import 'package:werkcalc/materialliste.dart';
import 'package:werkcalc/materialliste_store.dart';

const kListen = 'materiallisten_v1';
const kAuto = 'werkcalc_sicherung_auto';
const kVor = 'werkcalc_sicherung_vor_aenderung';

Baustelle baustelle(String id, String name, {int n = 2}) => Baustelle(
      id: id,
      name: name,
      erstellt: DateTime.fromMillisecondsSinceEpoch(1760000000000),
      artikel: [
        for (var i = 0; i < n; i++) ListenArtikel(id: '$id-$i', name: 'Muffe Kupfer Ø22', menge: 1.0 + i, einheit: 'Stk.'),
      ],
    );

String altesFormat(List<Baustelle> l) => jsonEncode([for (final b in l) b.toJson()]);

String snapshot(List<Baustelle> l) => sicherungAlsJson(Sicherung(erstellt: DateTime(2026, 10, 9), listen: l));

Future<MaterialListenStore> lade(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final s = MaterialListenStore.fuerTest();
  await s.laden();
  return s;
}

Future<String?> roh(String key) async => (await SharedPreferences.getInstance()).getString(key);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('keine Daten: kein Problem, nichts geschrieben', () async {
    final s = await lade({});
    expect(s.problem, isNull);
    expect(s.listen, isEmpty);
    expect(await roh(kAuto), isNull, reason: 'leere Liste erzeugt keine Sicherung');
  });

  test('Update-Kompatibilität: bisherige Daten werden gelesen, Format beim Speichern gleich', () async {
    final alt = [baustelle('a', 'Müllerstraße'), baustelle('b', 'Bahnhof')];
    final s = await lade({kListen: altesFormat(alt), 'absender_name': 'Test', 'zaehler_2026': 3});
    expect(s.problem, isNull);
    expect(s.listen.map((b) => b.name), ['Müllerstraße', 'Bahnhof']);
    await s.umbenennen('b', 'Bahnhof 2');
    final gespeichert = jsonDecode((await roh(kListen))!) as List;
    expect(gespeichert.length, 2);
    expect((gespeichert[0] as Map).keys.toSet(), {'id', 'name', 'erstellt', 'artikel'});
    final p = await SharedPreferences.getInstance();
    expect(p.getString('absender_name'), 'Test', reason: 'fremde Schlüssel bleiben unberührt');
    expect(p.getInt('zaehler_2026'), 3);
  });

  test('beim Start wird der lesbare Stand als lokale Sicherung festgehalten', () async {
    await lade({kListen: altesFormat([baustelle('a', 'A')])});
    final r = pruefeSicherung((await roh(kAuto))!);
    expect(r.ok, isTrue);
    expect(r.sicherung!.listen.single.name, 'A');
  });

  test('beschädigte Daten: kein Überschreiben, Kopie gesichert, Problem gemeldet', () async {
    final s = await lade({kListen: '{kaputt'});
    expect(s.problem, isNotNull);
    expect(s.datenBeschaedigt, isTrue);
    expect(s.listen, isEmpty);
    await s.neueBaustelle('Neu');
    await s.hinzufuegen(s.listen.first.id, name: 'Rohr', menge: 1, einheit: 'm');
    expect(await roh(kListen), '{kaputt', reason: 'Originaldaten bleiben unverändert');
    expect(await roh('werkcalc_defekt_$kListen'), '{kaputt');
    expect(await s.defekteDatenText(), contains('kaputt'));
  });

  test('teilweise beschädigt: lesbarer Rest bleibt sichtbar, Original bleibt erhalten', () async {
    final gut = jsonEncode(baustelle('a', 'Gut').toJson());
    final original = '[$gut, 5]';
    final s = await lade({kListen: original});
    expect(s.listen.single.name, 'Gut');
    expect(s.datenBeschaedigt, isTrue);
    await s.neueBaustelle('Zusatz');
    expect(await roh(kListen), original);
  });

  test('beschädigt, aber lokale Sicherung vorhanden: Wiederherstellen klappt', () async {
    final s = await lade({
      kListen: 'xx',
      kAuto: snapshot([baustelle('a', 'A'), baustelle('b', 'B')]),
    });
    expect(s.datenBeschaedigt, isTrue);
    final fehler = await s.ausLokalerSicherung(vorAenderung: false);
    expect(fehler, isNull);
    expect(s.datenBeschaedigt, isFalse);
    expect(s.problem, isNull);
    expect(s.listen.length, 2);
    expect(jsonDecode((await roh(kListen))!), isA<List>());
    expect(await roh('werkcalc_defekt_$kListen'), 'xx', reason: 'Kopie der defekten Daten bleibt');
  });

  test('beschädigt, keine Sicherung: klare Meldung, Daten unverändert', () async {
    final s = await lade({kListen: 'xx'});
    final fehler = await s.ausLokalerSicherung(vorAenderung: false);
    expect(fehler, contains('keine lokale Sicherung'));
    expect(await roh(kListen), 'xx');
    expect(s.datenBeschaedigt, isTrue);
  });

  test('lokale Sicherung selbst beschädigt: Meldung, nichts verändert', () async {
    final s = await lade({kListen: altesFormat([baustelle('a', 'A')]), kVor: '{kaputt'});
    final fehler = await s.ausLokalerSicherung(vorAenderung: true);
    expect(fehler, contains('nicht lesbar'));
    expect(s.listen.single.name, 'A');
  });

  test('Neu beginnen nach Defekt: Kopie bleibt, danach wird gespeichert', () async {
    final s = await lade({kListen: '{kaputt'});
    await s.neuBeginnen();
    expect(s.problem, isNull);
    await s.neueBaustelle('Neu');
    expect((jsonDecode((await roh(kListen))!) as List).length, 1);
    expect(await roh('werkcalc_defekt_$kListen'), '{kaputt');
  });

  test('Wiederherstellen mit ungültiger Datei: Meldung, vorhandene Daten bleiben', () async {
    final vorher = altesFormat([baustelle('a', 'A')]);
    final s = await lade({kListen: vorher});
    for (final text in ['', 'quatsch', '{"format":"x"}', '{"format":"$kSicherungFormat","version":7,"listen":[]}']) {
      final fehler = await s.wiederherstellen(text);
      expect(fehler, isNotNull, reason: text);
      expect(s.listen.single.name, 'A');
      expect(await roh(kListen), vorher);
    }
  });

  test('Wiederherstellen: Daten ersetzt, Stand davor als lokale Sicherung', () async {
    final s = await lade({kListen: altesFormat([baustelle('a', 'Alt1'), baustelle('b', 'Alt2')])});
    final neu = sicherungAlsJson(Sicherung(erstellt: DateTime(2026, 10, 1), listen: [baustelle('z', 'Neu')]));
    expect(await s.wiederherstellen(neu), isNull);
    expect(s.listen.map((b) => b.name), ['Neu']);
    expect((jsonDecode((await roh(kListen))!) as List).length, 1);
    final vor = pruefeSicherung((await roh(kVor))!).sicherung!;
    expect(vor.listen.map((b) => b.name), ['Alt1', 'Alt2']);
    // und zurück
    expect(await s.ausLokalerSicherung(vorAenderung: true), isNull);
    expect(s.listen.map((b) => b.name), ['Alt1', 'Alt2']);
  });

  test('Löschen einer Baustelle legt vorher eine lokale Sicherung an', () async {
    final s = await lade({kListen: altesFormat([baustelle('a', 'A'), baustelle('b', 'B')])});
    await s.loeschen('a');
    expect(s.listen.map((b) => b.name), ['B']);
    final vor = pruefeSicherung((await roh(kVor))!).sicherung!;
    expect(vor.listen.map((b) => b.name), ['A', 'B']);
  });

  test('Export → Import in frischer Instanz ergibt dieselben Daten', () async {
    final s = await lade({kListen: altesFormat([baustelle('a', 'A'), baustelle('b', 'B', n: 3)])});
    await s.hinzufuegen('a', name: 'Eigenes Sonderteil', menge: 2, einheit: 'Stk.');
    final text = await s.sicherungText();
    final s2 = await lade({});
    expect(await s2.wiederherstellen(text), isNull);
    expect(s2.listen.length, 2);
    expect(s2.listen[0].artikel.length, s.listen[0].artikel.length);
    expect(s2.listen[1].artikel.length, 3);
    expect(altesFormat(s2.listen), altesFormat(s.listen));
  });

  test('Materialkosten-Liste mit kaputtem Inhalt: Kopie gesichert, App startet', () async {
    SharedPreferences.setMockInitialValues({'material_liste': '{kaputt'});
    final s = MaterialListenStore.fuerTest();
    await s.laden();
    final text = await s.sicherungText();
    expect(pruefeSicherung(text).ok, isTrue);
    expect(await roh('werkcalc_defekt_material_liste'), '{kaputt');
  });
}
