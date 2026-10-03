import 'package:flutter/material.dart';

import 'brand.dart';

/// Hoher Kontrast, große Schrift und große Touch-Flächen:
/// gedacht für die Baustelle (Sonnenlicht, Handschuhe, schnelle Eingabe).
ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kBrandBlue,
    brightness: Brightness.light,
  ).copyWith(
    primary: kBrandBlue,
    onPrimary: Colors.white,
    secondary: kBrandOrange,
    onSecondary: Colors.black,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFEFF3F8),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      titleTextStyle: TextStyle(
        color: scheme.onPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
