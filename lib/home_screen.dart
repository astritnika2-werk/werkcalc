import 'package:flutter/material.dart';

import 'angebot_page.dart';
import 'brand.dart';
import 'calculators.dart';
import 'favoriten.dart';
import 'legal_pages.dart';
import 'materialliste_pages.dart';

/// Rahmen mit Navigation unten: Start, Listen, Favoriten, PDF, Mehr.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    FavoritenStore.instance.laden();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomeTab(),
      const MaterialListenTab(),
      const FavoritenTab(),
      const AngebotPage(),
      const MoreTab(),
    ];
    return Scaffold(
      // IndexedStack erhält die Eingaben im Angebot beim Tab-Wechsel.
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Start'),
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Listen'),
          NavigationDestination(icon: Icon(Icons.star), label: 'Favoriten'),
          NavigationDestination(icon: Icon(Icons.description), label: 'PDF'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Mehr'),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: scheme.primary,
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + 16,
            20,
            20,
          ),
          child: Row(
            children: [
              const WerkCalcMark(size: 44),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const WerkCalcWordmark(fontSize: 26),
                  Text(
                    kAppSubtitle,
                    style: TextStyle(color: scheme.onPrimary, fontSize: 15),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(16),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [for (final c in calculators) CalcTile(def: c)],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Alle Berechnungen sind Richtwerte ohne Gewähr. '
            'Die App speichert keine Kundendaten und benötigt kein Konto.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

/// Kachel eines Rechners, mit Stern zum Merken als Favorit.
class CalcTile extends StatelessWidget {
  const CalcTile({super.key, required this.def});

  final CalcDef def;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final builder = def.builder;
    final enabled = builder != null;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Positioned.fill(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (builder == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${def.label}: kommt bald')),
                  );
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => builder()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      def.icon,
                      size: 44,
                      color: enabled ? scheme.primary : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      def.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: enabled ? null : Colors.grey,
                      ),
                    ),
                    if (!enabled)
                      const Text(
                        'bald',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (enabled)
            Positioned(
              top: 0,
              right: 0,
              child: ListenableBuilder(
                listenable: FavoritenStore.instance,
                builder: (context, _) {
                  final fav = FavoritenStore.instance.istFavorit(def.label);
                  return IconButton(
                    tooltip: fav ? 'Aus Favoriten entfernen' : 'Zu Favoriten',
                    icon: Icon(
                      fav ? Icons.star : Icons.star_border,
                      color: fav ? Colors.amber.shade700 : Colors.grey,
                    ),
                    onPressed: () => FavoritenStore.instance.umschalten(def.label),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class FavoritenTab extends StatelessWidget {
  const FavoritenTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoriten')),
      body: ListenableBuilder(
        listenable: FavoritenStore.instance,
        builder: (context, _) {
          final favoriten = [
            for (final c in calculators)
              if (c.builder != null && FavoritenStore.instance.istFavorit(c.label)) c,
          ];
          if (favoriten.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Tippe bei einem Rechner auf den Stern, '
                  'um ihn hier zu speichern.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ),
            );
          }
          return GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(16),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [for (final c in favoriten) CalcTile(def: c)],
          );
        },
      ),
    );
  }
}

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    void oeffne(String titel, String text) => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LegalPage(title: titel, text: text),
          ),
        );
    void bald(String was) => ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$was: kommt bald')));

    return Scaffold(
      appBar: AppBar(title: const Text('Mehr')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.shield),
            title: const Text('Datenschutz'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => oeffne('Datenschutz', kDatenschutzText),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Impressum'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => oeffne('Impressum', kImpressumText),
          ),
          ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: const Text('Werbung entfernen (Premium)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => bald('Premium'),
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('App bewerten'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => bald('Bewertung'),
          ),
        ],
      ),
    );
  }
}
