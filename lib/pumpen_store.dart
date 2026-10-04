import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'pumpen_logik.dart';

/// Pumpen für die Prüfung: mitgelieferte, geprüfte Herstellerdaten
/// (assets/pumpen/pumpen.json, aktuell leer) und eigene Eingaben des Nutzers
/// (nur auf dem Gerät gespeichert).
class PumpenStore {
  static const _kEigene = 'pumpen_eigene';

  static Future<List<PumpenDaten>> ladeAlle() async {
    final out = <PumpenDaten>[];
    try {
      final raw = await rootBundle.loadString('assets/pumpen/pumpen.json');
      final j = jsonDecode(raw) as Map<String, dynamic>;
      for (final e in (j['pumpen'] as List<dynamic>? ?? const [])) {
        final p = PumpenDaten.fromJson(Map<String, dynamic>.from(e as Map), verifiziert: true);
        if (_brauchbar(p)) out.add(p);
      }
    } catch (_) {}
    out.addAll(await ladeEigene());
    return out;
  }

  static bool _brauchbar(PumpenDaten p) =>
      p.quelle.trim().isNotEmpty &&
      p.kurven.isNotEmpty &&
      p.kurven.every((k) => pruefeKurve(k.normiert) == null);

  static Future<List<PumpenDaten>> ladeEigene() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kEigene);
      if (raw == null || raw.isEmpty) return [];
      return [
        for (final e in jsonDecode(raw) as List<dynamic>)
          PumpenDaten.fromJson(Map<String, dynamic>.from(e as Map)),
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<void> _schreibe(List<PumpenDaten> liste) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kEigene, jsonEncode([for (final x in liste) x.toJson()]));
  }

  static Future<void> speichere(PumpenDaten pumpe) async {
    final liste = await ladeEigene();
    final i = liste.indexWhere((x) => x.id == pumpe.id);
    if (i >= 0) {
      liste[i] = pumpe;
    } else {
      liste.add(pumpe);
    }
    await _schreibe(liste);
  }

  static Future<void> loesche(String id) async {
    final liste = await ladeEigene();
    liste.removeWhere((x) => x.id == id);
    await _schreibe(liste);
  }
}
