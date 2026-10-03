import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logic.dart';
import 'pdf_angebot.dart';

/// Wird von der Materialliste gesetzt, wenn die Netto-Summe ins Angebot
/// übernommen werden soll. Das Angebot liest den Wert und setzt ihn zurück.
final ValueNotifier<double?> materialUebernahme = ValueNotifier<double?>(null);

/// Lokale Ablage auf dem Gerät (nichts verlässt das Telefon).
/// Gespeichert werden nur: eigene Firmendaten (optional), der Angebotszähler,
/// die eigene Materialliste und die Favoriten. Keine Kundendaten.
class AngebotStorage {
  static const _kName = 'absender_name';
  static const _kAdresse = 'absender_adresse';
  static const _kUstId = 'absender_ust_id';
  static const _kMaterial = 'material_liste';

  static Future<Absender> ladeAbsender() async {
    final p = await SharedPreferences.getInstance();
    return Absender(
      name: p.getString(_kName) ?? '',
      adresse: p.getString(_kAdresse) ?? '',
      ustId: p.getString(_kUstId) ?? '',
    );
  }

  static Future<void> speichereAbsender(Absender a) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kName, a.name);
    await p.setString(_kAdresse, a.adresse);
    await p.setString(_kUstId, a.ustId);
  }

  /// Nächste freie Laufnummer für das Jahr (ohne sie zu verbrauchen).
  static Future<int> naechsteLaufnummer(int jahr) async {
    final p = await SharedPreferences.getInstance();
    return (p.getInt('zaehler_$jahr') ?? 0) + 1;
  }

  /// Markiert die Laufnummer als vergeben.
  static Future<void> laufnummerVergeben(int jahr, int nummer) async {
    final p = await SharedPreferences.getInstance();
    final aktuell = p.getInt('zaehler_$jahr') ?? 0;
    if (nummer > aktuell) await p.setInt('zaehler_$jahr', nummer);
  }

  static Future<List<MaterialPosition>> ladeMaterial() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kMaterial);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list)
          MaterialPosition.fromJson(Map<String, dynamic>.from(e as Map)),
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<void> speichereMaterial(List<MaterialPosition> liste) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _kMaterial,
      jsonEncode([for (final m in liste) m.toJson()]),
    );
  }
}
