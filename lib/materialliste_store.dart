import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'datensicherung.dart';
import 'katalog.dart';
import 'materialliste.dart';
import 'storage.dart';

/// Ein Foto mit seinem Nutzungsrecht.
class FotoRecht {
  const FotoRecht(this.pfad, this.lizenz, this.quelle, this.urheber);

  final String pfad;
  final String lizenz;
  final String quelle;
  final String urheber;

  String get hinweis => [
        if (urheber.isNotEmpty) '© $urheber',
        if (lizenz.isNotEmpty) lizenz,
        if (quelle.isNotEmpty) quelle,
      ].join(' · ');
}

/// Lokale Ablage der Materiallisten auf dem Gerät. Nichts wird übertragen.
class MaterialListenStore extends ChangeNotifier {
  MaterialListenStore._();

  /// Nur für Tests: frische Instanz mit eigenem Zustand.
  @visibleForTesting
  MaterialListenStore.fuerTest();

  static final MaterialListenStore instance = MaterialListenStore._();

  static const _kListen = 'materiallisten_v1';
  static const _kEigene = 'material_eigene_artikel_v1';
  static const _kZuletzt = 'material_zuletzt_v1';
  // Zusätzliche Schlüssel für Sicherungen. Die Schlüssel oben und ihr Format
  // bleiben unverändert, damit bestehende Daten nach einem Update lesbar bleiben.
  static const _kAutoSicherung = 'werkcalc_sicherung_auto';
  static const _kVorAenderung = 'werkcalc_sicherung_vor_aenderung';
  static const _kDefektPrefix = 'werkcalc_defekt_';

  List<Baustelle> _listen = [];
  List<KatalogArtikel> _eigene = [];
  List<KatalogArtikel> _zuletzt = [];
  bool _geladen = false;
  int _zaehler = 0;

  /// Meldung, wenn gespeicherte Daten nicht (vollständig) gelesen werden konnten.
  String? _problem;

  /// Solange gespeicherte Daten nicht lesbar waren, wird nichts auf das Gerät
  /// geschrieben, damit sie nicht überschrieben werden.
  bool _schreibschutz = false;
  bool _speicherFehler = false;

  /// Hinweis für die Oberfläche (null: alles in Ordnung).
  String? get problem =>
      _problem ??
      (_speicherFehler
          ? 'Speichern auf dem Gerät ist fehlgeschlagen. Die Daten sind nur im Arbeitsspeicher. '
              'Bitte unter „Datensicherung“ eine Sicherung exportieren.'
          : null);

  /// true: gespeicherte Daten waren beschädigt/unlesbar (es wird nichts überschrieben).
  bool get datenBeschaedigt => _schreibschutz;

  /// Eingebauter Katalog (einmal erzeugt).
  List<KatalogArtikel> _basis = baueKatalog();

  List<Baustelle> get listen => List.unmodifiable(_listen);
  List<KatalogArtikel> get zuletzt => List.unmodifiable(_zuletzt);

  /// Katalog für Suche und Auswahl: eigene Artikel zuerst, dann eingebaute.
  List<KatalogArtikel> get katalog => [..._eigene, ..._basis];

  Baustelle? finde(String id) {
    for (final b in _listen) {
      if (b.id == id) return b;
    }
    return null;
  }

  String _neueId() {
    _zaehler++;
    return '${DateTime.now().microsecondsSinceEpoch}_$_zaehler';
  }

  Set<String> _fotos = {};
  Map<String, FotoRecht> _fotoRechte = {};

  /// Pfad zum echten Foto des Artikels, falls vorhanden; sonst null (dann
  /// zeigt die Karte die Skizze). Reihenfolge: Feld „foto“, dann Datei
  /// assets/produkte/<EAN | Artikelnummer | Name>.jpg/.png/.webp.
  String? fotoFuer(KatalogArtikel a) => fotoRecht(a)?.pfad;

  /// Foto samt Nutzungsrecht – oder null. Ein Foto wird nur gezeigt, wenn die
  /// Lizenz eingetragen ist (Feld „fotoLizenz“ bzw. Eintrag in
  /// assets/produkte/fotos.json). Sonst bleibt die Skizze.
  FotoRecht? fotoRecht(KatalogArtikel a) {
    if (a.foto.isNotEmpty) {
      if (a.fotoLizenz.trim().isEmpty) return null;
      return FotoRecht(a.foto, a.fotoLizenz, a.fotoQuelle, a.fotoUrheber);
    }
    if (_fotos.isEmpty || _fotoRechte.isEmpty) return null;
    for (final k in a.fotoSchluessel) {
      final r = _fotoRechte[k];
      if (r == null || r.lizenz.trim().isEmpty) continue;
      for (final ext in const ['jpg', 'jpeg', 'png', 'webp']) {
        final pfad = 'assets/produkte/$k.$ext';
        if (_fotos.contains(pfad)) return FotoRecht(pfad, r.lizenz, r.quelle, r.urheber);
      }
    }
    return null;
  }

  Future<void> laden() async {
    if (_geladen) return;
    _geladen = true;
    try {
      // Katalog-Erweiterung (JSON im App-Paket), ohne Code-Änderung nutzbar.
      try {
        final roh = await rootBundle.loadString('assets/katalog/zusatz.json');
        final extra = katalogAusJson(
          roh,
          vorhandeneNamen: {for (final a in _basis) a.name},
        );
        _basis = katalogAnreichern(_basis, roh);
        if (extra.isNotEmpty) _basis = [..._basis, ...extra];
      } catch (_) {}
      // Echte Produktfotos: alle Dateien in assets/produkte/ merken.
      try {
        final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
        _fotos = {
          for (final pfad in manifest.listAssets())
            if (pfad.startsWith('assets/produkte/')) pfad,
        };
      } catch (_) {}
      // Nutzungsrechte der Fotos: assets/produkte/fotos.json
      //   { "<dateiname-ohne-endung>": {"lizenz": "...", "quelle": "...", "urheber": "..."} }
      try {
        final roh = await rootBundle.loadString('assets/produkte/fotos.json');
        final m = jsonDecode(roh) as Map<String, dynamic>;
        _fotoRechte = {
          for (final e in m.entries)
            e.key: FotoRecht(
              '',
              ((e.value as Map)['lizenz'] ?? '').toString(),
              ((e.value as Map)['quelle'] ?? '').toString(),
              ((e.value as Map)['urheber'] ?? '').toString(),
            ),
        };
      } catch (_) {}
      final p = await SharedPreferences.getInstance();
      final rohListen = p.getString(_kListen);
      final rohEigene = p.getString(_kEigene);
      final rohZuletzt = p.getString(_kZuletzt);
      final l = leseListeStreng<Baustelle>(rohListen, (m) => Baustelle.fromJson(m));
      final e = leseListeStreng<KatalogArtikel>(rohEigene, (m) {
        final a = KatalogArtikel.fromJson(m);
        return KatalogArtikel(
          name: a.name,
          einheit: a.einheit,
          kategorie: 'Eigene Artikel',
          unter: 'Eigene',
        );
      });
      final z = leseListeStreng<KatalogArtikel>(rohZuletzt, (m) {
        final a = KatalogArtikel.fromJson(m);
        return _imKatalog(a.name) ?? a;
      });
      _listen = l.daten;
      _eigene = e.daten;
      _zuletzt = z.daten;
      if (l.defekt || e.defekt || z.defekt) {
        // Nichts überschreiben: Rohdaten als Kopie sichern und Schreiben sperren.
        _schreibschutz = true;
        _problem = 'Gespeicherte Daten sind beschädigt oder nicht lesbar. '
            'Zum Schutz wird nichts überschrieben; die beschädigten Daten wurden als Kopie gesichert.';
        await _defekteKopieren(p, {
          if (l.defekt) _kListen: rohListen,
          if (e.defekt) _kEigene: rohEigene,
          if (z.defekt) _kZuletzt: rohZuletzt,
        });
      } else {
        await _autoSicherung(p);
      }
    } catch (_) {
      // Speicher nicht lesbar: nichts schreiben, damit vorhandene Daten bleiben.
      _schreibschutz = true;
      _problem = 'Der Gerätespeicher konnte nicht gelesen werden. '
          'Zum Schutz wird nichts überschrieben.';
    }
    notifyListeners();
  }

  KatalogArtikel? _imKatalog(String name) {
    for (final a in katalog) {
      if (a.name == name) return a;
    }
    return null;
  }

  Future<void> _speichern() async {
    notifyListeners();
    if (_schreibschutz) return; // beschädigte Daten nicht überschreiben
    try {
      final p = await SharedPreferences.getInstance();
      final ok1 = await p.setString(
        _kListen,
        jsonEncode([for (final b in _listen) b.toJson()]),
      );
      final ok2 = await p.setString(
        _kEigene,
        jsonEncode([for (final a in _eigene) a.toJson()]),
      );
      final ok3 = await p.setString(
        _kZuletzt,
        jsonEncode([for (final a in _zuletzt) a.toJson()]),
      );
      final ok = ok1 && ok2 && ok3;
      if (_speicherFehler == ok) {
        _speicherFehler = !ok;
        notifyListeners();
      }
    } catch (_) {
      // Die Liste bleibt im Speicher; die Oberfläche weist darauf hin.
      if (!_speicherFehler) {
        _speicherFehler = true;
        notifyListeners();
      }
    }
  }

  // ─────────── Sicherungen ───────────

  String _momentaufnahme() => sicherungAlsJson(Sicherung(
        erstellt: DateTime.now(),
        listen: _listen,
        eigene: _eigene,
        zuletzt: _zuletzt,
      ));

  /// Kopiert nicht lesbare Rohdaten, ohne eine frühere Kopie zu überschreiben.
  Future<void> _defekteKopieren(SharedPreferences p, Map<String, String?> roh) async {
    for (final e in roh.entries) {
      final r = e.value;
      if (r == null) continue;
      final ziel = '$_kDefektPrefix${e.key}';
      final vorhanden = p.getString(ziel);
      if (vorhanden == null) {
        await p.setString(ziel, r);
      } else if (vorhanden != r) {
        await p.setString('${ziel}_${DateTime.now().millisecondsSinceEpoch}', r);
      }
    }
  }

  /// Hält den zuletzt lesbaren Stand fest (beim Start). Eine leere Liste ersetzt
  /// eine vorhandene Sicherung nie.
  Future<void> _autoSicherung(SharedPreferences p) async {
    if (_listen.isEmpty) return;
    try {
      await p.setString(_kAutoSicherung, _momentaufnahme());
    } catch (_) {}
  }

  /// Stand vor einer größeren Änderung (Löschen, Wiederherstellen).
  Future<void> _sichereVorAenderung() async {
    if (_schreibschutz || _listen.isEmpty) return;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kVorAenderung, _momentaufnahme());
    } catch (_) {}
  }

  /// Sicherungstext für den Export (Baustellen, Materiallisten, eigene Artikel,
  /// zuletzt verwendete Artikel und die Materialkosten-Liste).
  Future<String> sicherungText() async {
    final kosten = await AngebotStorage.ladeMaterial();
    return sicherungAlsJson(Sicherung(
      erstellt: DateTime.now(),
      listen: _listen,
      eigene: _eigene,
      zuletzt: _zuletzt,
      materialkosten: kosten,
    ));
  }

  /// Stellt aus einem Sicherungstext wieder her. Gibt null bei Erfolg zurück,
  /// sonst eine verständliche Meldung. Bei einem Fehler bleiben die bisherigen
  /// Daten unverändert.
  Future<String?> wiederherstellen(String text) async {
    final pr = pruefeSicherung(text);
    if (!pr.ok) return pr.fehler;
    return _uebernehme(pr.sicherung!);
  }

  /// Stellt eine lokale Sicherung wieder her ([vorAenderung] false: automatische
  /// Sicherung vom letzten Start, true: Stand vor der letzten größeren Änderung).
  Future<String?> ausLokalerSicherung({required bool vorAenderung}) async {
    String? text;
    try {
      final p = await SharedPreferences.getInstance();
      text = p.getString(vorAenderung ? _kVorAenderung : _kAutoSicherung);
    } catch (_) {
      return 'Die lokale Sicherung konnte nicht gelesen werden.';
    }
    if (text == null || text.isEmpty) return 'Es ist keine lokale Sicherung vorhanden.';
    final pr = pruefeSicherung(text);
    if (!pr.ok) return 'Die lokale Sicherung ist nicht lesbar: ${pr.fehler}';
    return _uebernehme(pr.sicherung!);
  }

  Future<String?> _uebernehme(Sicherung s) async {
    await _sichereVorAenderung();
    final alt = (listen: _listen, eigene: _eigene, zuletzt: _zuletzt);
    SharedPreferences? prefs;
    final altRoh = <String, String?>{};
    try {
      prefs = await SharedPreferences.getInstance();
      for (final k in [_kListen, _kEigene, _kZuletzt]) {
        altRoh[k] = prefs.getString(k);
      }
    } catch (_) {
      return 'Wiederherstellen nicht möglich: Der Gerätespeicher ist nicht lesbar. '
          'Ihre bisherigen Daten wurden nicht verändert.';
    }
    final p = prefs;
    try {
      final r1 = await p.setString(_kListen, jsonEncode([for (final b in s.listen) b.toJson()]));
      final r2 = await p.setString(_kEigene, jsonEncode([for (final a in s.eigene) a.toJson()]));
      final r3 = await p.setString(_kZuletzt, jsonEncode([for (final a in s.zuletzt) a.toJson()]));
      if (!(r1 && r2 && r3)) throw StateError('Schreiben fehlgeschlagen');
      if (s.materialkosten != null) await AngebotStorage.speichereMaterial(s.materialkosten!);
    } catch (_) {
      // Zurück auf den Stand vor dem Versuch.
      try {
        for (final e in altRoh.entries) {
          final v = e.value;
          if (v == null) {
            await p.remove(e.key);
          } else {
            await p.setString(e.key, v);
          }
        }
      } catch (_) {}
      _listen = alt.listen;
      _eigene = alt.eigene;
      _zuletzt = alt.zuletzt;
      notifyListeners();
      return 'Wiederherstellen fehlgeschlagen (Speichern auf dem Gerät nicht möglich). '
          'Ihre bisherigen Daten wurden nicht verändert.';
    }
    _listen = s.listen;
    _eigene = s.eigene;
    _zuletzt = s.zuletzt;
    _schreibschutz = false;
    _problem = null;
    _speicherFehler = false;
    await _autoSicherung(p);
    notifyListeners();
    return null;
  }

  /// Nach beschädigten Daten: mit dem lesbaren Rest weiterarbeiten. Die
  /// beschädigten Rohdaten bleiben als Kopie erhalten.
  Future<void> neuBeginnen() async {
    _schreibschutz = false;
    _problem = null;
    await _speichern();
  }

  /// Rohdaten, die nicht gelesen werden konnten (zum Teilen/Support), oder null.
  Future<String?> defekteDatenText() async {
    try {
      final p = await SharedPreferences.getInstance();
      final keys = p.getKeys().where((k) => k.startsWith(_kDefektPrefix)).toList()..sort();
      if (keys.isEmpty) return null;
      return jsonEncode({for (final k in keys) k: p.getString(k)});
    } catch (_) {
      return null;
    }
  }

  /// Angaben zu den beiden lokalen Sicherungen (für die Anzeige).
  Future<({Sicherung? auto, Sicherung? vorAenderung})> lokaleSicherungen() async {
    try {
      final p = await SharedPreferences.getInstance();
      Sicherung? lies(String k) {
        final t = p.getString(k);
        if (t == null || t.isEmpty) return null;
        return pruefeSicherung(t).sicherung;
      }

      return (auto: lies(_kAutoSicherung), vorAenderung: lies(_kVorAenderung));
    } catch (_) {
      return (auto: null, vorAenderung: null);
    }
  }

  // ─────────── Baustellen ───────────

  Future<Baustelle> neueBaustelle(String name) async {
    final b = Baustelle(
      id: _neueId(),
      name: name.trim().isEmpty ? 'Neue Baustelle' : name.trim(),
      erstellt: DateTime.now(),
    );
    _listen = [b, ..._listen];
    await _speichern();
    return b;
  }

  Future<void> umbenennen(String id, String name) async {
    final n = name.trim();
    if (n.isEmpty) return;
    _listen = [
      for (final b in _listen) b.id == id ? b.copyWith(name: n) : b,
    ];
    await _speichern();
  }

  Future<void> loeschen(String id) async {
    await _sichereVorAenderung();
    _listen = [for (final b in _listen) if (b.id != id) b];
    await _speichern();
  }

  Future<Baustelle?> kopieren(String id) async {
    final q = finde(id);
    if (q == null) return null;
    final kopie = kopiereBaustelle(
      q,
      neueId: _neueId(),
      neuerName: '${q.name} (Kopie)',
      jetzt: DateTime.now(),
      idFuerArtikel: (_) => _neueId(),
    );
    _listen = [kopie, ..._listen];
    await _speichern();
    return kopie;
  }

  // ─────────── Artikel ───────────

  void _setzeArtikel(String id, List<ListenArtikel> Function(List<ListenArtikel>) f) {
    _listen = [
      for (final b in _listen) b.id == id ? b.copyWith(artikel: f(b.artikel)) : b,
    ];
  }

  Future<void> hinzufuegen(
    String baustelleId, {
    required String name,
    required double menge,
    required String einheit,
  }) async {
    _setzeArtikel(
      baustelleId,
      (l) => artikelHinzufuegen(
        l,
        id: _neueId(),
        name: name,
        menge: menge,
        einheit: einheit,
      ),
    );
    final bekannt = _imKatalog(name.trim());
    if (bekannt == null) {
      _eigene = [
        KatalogArtikel(name: name.trim(), einheit: einheit),
        ..._eigene,
      ];
    }
    final merk = bekannt ?? KatalogArtikel(name: name.trim(), einheit: einheit);
    _zuletzt = [
      merk,
      for (final a in _zuletzt) if (a.name != merk.name) a,
    ].take(15).toList();
    await _speichern();
  }

  Future<void> mengeSetzen(String baustelleId, String artikelId, double menge, String einheit) async {
    if (menge <= 0) return;
    _setzeArtikel(
      baustelleId,
      (l) => [
        for (final a in l)
          a.id == artikelId ? a.copyWith(menge: menge, einheit: einheit) : a,
      ],
    );
    await _speichern();
  }

  Future<void> abhaken(String baustelleId, String artikelId, bool erledigt) async {
    _setzeArtikel(
      baustelleId,
      (l) => [
        for (final a in l) a.id == artikelId ? a.copyWith(erledigt: erledigt) : a,
      ],
    );
    await _speichern();
  }

  Future<void> alleAbhaken(String baustelleId, bool erledigt) async {
    _setzeArtikel(
      baustelleId,
      (l) => [for (final a in l) a.copyWith(erledigt: erledigt)],
    );
    await _speichern();
  }

  Future<void> artikelLoeschen(String baustelleId, String artikelId) async {
    _setzeArtikel(
      baustelleId,
      (l) => [for (final a in l) if (a.id != artikelId) a],
    );
    await _speichern();
  }

  /// Fügt einen gelöschten Artikel wieder an seiner alten Stelle ein (Rückgängig).
  Future<void> artikelWiederherstellen(String baustelleId, ListenArtikel a, int index) async {
    _setzeArtikel(baustelleId, (l) {
      final neu = [...l];
      neu.insert(index.clamp(0, neu.length), a);
      return neu;
    });
    await _speichern();
  }

  Future<void> abgehakteEntfernen(String baustelleId) async {
    await _sichereVorAenderung();
    _setzeArtikel(
      baustelleId,
      (l) => [for (final a in l) if (!a.erledigt) a],
    );
    await _speichern();
  }
}
