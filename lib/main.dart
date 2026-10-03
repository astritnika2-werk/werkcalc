import 'package:flutter/material.dart';

import 'brand.dart';
import 'theme.dart';
import 'welcome_screen.dart';

void main() {
  runApp(const WerkCalcApp());
}

class WerkCalcApp extends StatelessWidget {
  const WerkCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const WelcomeScreen(),
    );
  }
}
