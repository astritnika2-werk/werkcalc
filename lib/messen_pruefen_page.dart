import 'package:flutter/material.dart';

import 'pumpe_lauf_page.dart';
import 'vibration_page.dart';
import 'wasserwaage_page.dart';

/// Bereich „Messen & Prüfen“. Es sind nur die Funktionen aktiv, die fertig
/// gebaut sind; die übrigen sind als „Bald verfügbar“ vorgemerkt.
class MessenPruefenPage extends StatelessWidget {
  const MessenPruefenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final gruppen = <(String, List<_Eintrag>)>[
      (
        'PUMPEN & ANTRIEBE',
        [
          _Eintrag('Pumpe läuft prüfen', Icons.vibration, () => const PumpeLaufPage()),
          _Eintrag('Vibration prüfen', Icons.stacked_line_chart, () => const VibrationPage()),
          _Eintrag('Akustik prüfen', Icons.mic_none, null),
        ]
      ),
      (
        'MONTAGE & ROHRLEITUNGEN',
        [
          _Eintrag('Wasserwaage', Icons.straighten, () => const WasserwaagePage()),
          _Eintrag('Neigung / Gefälle', Icons.architecture, null),
          _Eintrag('Bewegung prüfen', Icons.open_with, null),
        ]
      ),
      (
        'PRODUKT & MATERIAL',
        [
          _Eintrag('Typenschild erkennen', Icons.document_scanner, null),
          _Eintrag('QR-/Barcode scannen', Icons.qr_code_scanner, null),
        ]
      ),
      (
        'EXTERNE SENSOREN',
        [
          _Eintrag('Temperatur', Icons.thermostat, null),
          _Eintrag('Druck', Icons.speed, null),
          _Eintrag('Durchfluss', Icons.water, null),
        ]
      ),
    ];
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Messen & Prüfen')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          for (final g in gruppen) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
              child: Text(g.$1,
                  style: TextStyle(
                      color: scheme.primary, fontWeight: FontWeight.w800, letterSpacing: 0.6, fontSize: 13)),
            ),
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: scheme.outlineVariant),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < g.$2.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      enabled: g.$2[i].builder != null,
                      leading: Icon(g.$2[i].icon),
                      title: Text(g.$2[i].label),
                      subtitle: g.$2[i].builder == null ? const Text('Bald verfügbar') : null,
                      trailing: g.$2[i].builder == null ? null : const Icon(Icons.chevron_right),
                      onTap: g.$2[i].builder == null
                          ? null
                          : () => Navigator.of(context)
                              .push(MaterialPageRoute<void>(builder: (_) => g.$2[i].builder!())),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Eintrag {
  const _Eintrag(this.label, this.icon, this.builder);
  final String label;
  final IconData icon;
  final Widget Function()? builder;
}
