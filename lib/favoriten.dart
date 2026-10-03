import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Favoriten-Rechner, nur lokal auf dem Gerät gespeichert.
class FavoritenStore extends ChangeNotifier {
  FavoritenStore._();

  static final FavoritenStore instance = FavoritenStore._();
  static const _key = 'favoriten';

  final Set<String> _labels = {};
  bool _geladen = false;

  bool istFavorit(String label) => _labels.contains(label);

  Future<void> laden() async {
    if (_geladen) return;
    final p = await SharedPreferences.getInstance();
    _labels
      ..clear()
      ..addAll(p.getStringList(_key) ?? const <String>[]);
    _geladen = true;
    notifyListeners();
  }

  Future<void> umschalten(String label) async {
    if (!_labels.add(label)) _labels.remove(label);
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_key, _labels.toList());
  }
}
