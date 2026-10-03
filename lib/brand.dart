import 'package:flutter/material.dart';

/// Markenwerte von WerkCalc an einer Stelle.
const String kAppName = 'WerkCalc';
const String kAppSubtitle = 'Handwerker Rechner';
const String kAppTagline =
    'Rechner und PDF-Angebote für Heizung, Sanitär, Klima, Elektro und Bau.';

const Color kBrandBlue = Color(0xFF0B4A9F);
const Color kBrandBlueDark = Color(0xFF062A5C);
const Color kBrandOrange = Color(0xFFFF8A00);

/// Logo-Symbol (Schraubenmutter mit "="). [aufDunkel] = weiße Mutter für
/// blaue Flächen, sonst blaue Mutter für helle Flächen.
class WerkCalcMark extends StatelessWidget {
  const WerkCalcMark({super.key, this.size = 40, this.aufDunkel = true});

  final double size;
  final bool aufDunkel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      aufDunkel
          ? 'assets/brand/logo_mark_white.png'
          : 'assets/brand/logo_mark_color.png',
      width: size,
      height: size,
      semanticLabel: kAppName,
    );
  }
}

/// Schriftzug "Werk" + "Calc" (Calc in Orange).
class WerkCalcWordmark extends StatelessWidget {
  const WerkCalcWordmark({super.key, this.fontSize = 24, this.aufDunkel = true});

  final double fontSize;
  final bool aufDunkel;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        children: [
          TextSpan(
            text: 'Werk',
            style: TextStyle(color: aufDunkel ? Colors.white : kBrandBlue),
          ),
          const TextSpan(text: 'Calc', style: TextStyle(color: kBrandOrange)),
        ],
      ),
    );
  }
}
