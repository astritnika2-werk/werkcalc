import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'katalog.dart';
import 'materialliste.dart';

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

  static final MaterialListenStore instance = MaterialListenStore._();

  static const _kListen = 'materiallisten_v1';
  static const _kEigene = 'material_eigene_artikel_v1';
  static const _kZuletzt = 'material_zuletzt_v1';

  List<Baustelle> _listen = [];
  List<KatalogArtikel> _eigene = [];
  List<KatalogArtikel> _zuletzt = [];
  bool _geladen = false;
  int _zaehler = 0;

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
      _listen = _leseListe(p.getString(_kListen), (m) => Baustelle.fromJson(m));
      _eigene = _leseListe(p.getString(_kEigene), (m) {
        final a = KatalogArtikel.fromJson(m);
        return KatalogArtikel(
          name: a.name,
          einheit: a.einheit,
          kategorie: 'Eigene Artikel',
          unter: 'Eigene',
        );
      });
      _zuletzt = _leseListe(p.getString(_kZuletzt), (m) {
        final a = KatalogArtikel.fromJson(m);
        return _imKatalog(a.name) ?? a;
      });
    } catch (_) {
      // Beschädigte Daten: leer starten.
    }
    notifyListeners();
  }

  List<T> _leseListe<T>(String? raw, T Function(Map<String, dynamic>) bauen) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final liste = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in liste) bauen(Map<String, dynamic>.from(e as Map)),
      ];
    } catch (_) {
      return [];
    }
  }

  KatalogArtikel? _imKatalog(String name) {
    for (final a in katalog) {
      if (a.name == name) return a;
    }
    return null;
  }

  Future<void> _speichern() async {
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _kListen,
        jsonEncode([for (final b in _listen) b.toJson()]),
      );
      await p.setString(
        _kEigene,
        jsonEncode([for (final a in _eigene) a.toJson()]),
      );
      await p.setString(
        _kZuletzt,
        jsonEncode([for (final a in _zuletzt) a.toJson()]),
      );
    } catch (_) {
      // Speichern ist best effort; die Liste bleibt im Speicher erhalten.
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
    _setzeArtikel(
      baustelleId,
      (l) => [for (final a in l) if (!a.erledigt) a],
    );
    await _speichern();
  }
}
