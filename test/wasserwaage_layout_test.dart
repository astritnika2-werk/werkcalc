// Layout-Test der kompakten Wasserwaage-Ansicht: kein Überlauf, kein Scrollen, alles sichtbar,
// in Hochformat, flachen/breiten Ansichten und in den gedrehten Seitenlagen.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/wasserwaage_logik.dart';
import 'package:werkcalc/wasserwaage_page.dart';

enum Zustand { gueltig, nichtInLage, keineWerte, kalibriert, langeMeldung, kalLaeuft, fehler }

Widget baue(Modus m, Zustand z, {required int drehung}) {
  final v = switch (m) {
    Modus.flaeche => (0.3, 0.2, 9.78),
    Modus.linieDisplay => (0.5, 9.78, 0.3),
    Modus.linieLinks => (9.78, 0.5, 0.3),
    Modus.linieRechts => (-9.78, 0.5, 0.3),
  };
  final hat = z != Zustand.keineWerte;
  final n = (hat && m.istFlaeche) ? berechneNeigung(v.$1, v.$2, v.$3, lage: m.lage) : null;
  final l = (hat && !m.istFlaeche) ? berechneLinie(m, v.$1, v.$2, v.$3) : null;
  return MaterialApp(
    home: Scaffold(
      body: SafeArea(
        child: RotatedBox(
          quarterTurns: drehung,
          child: WasserwaageAnsicht(
            modus: m,
            neigung: n,
            linie: l,
            lageOk: hat && z != Zustand.nichtInLage,
            hatWerte: hat,
            fehler: z == Zustand.fehler ? 'Beschleunigungssensor nicht verfügbar – dieses Handy liefert keine Messwerte.' : null,
            kalibriert: z == Zustand.kalibriert,
            kalLaeuft: z == Zustand.kalLaeuft,
            kalOk: z == Zustand.kalibriert ? m.name2 : null,
            kalMeldung: z == Zustand.langeMeldung
                ? 'Kalibrierung nicht möglich: Das Handy liegt nicht in der Lage dieser Betriebsart '
                    '(Linie – Linke Seite) oder es gibt keinen Sensorwert. Bitte wiederholen.'
                : null,
            onKalibrieren: z == Zustand.kalLaeuft ? null : () {},
            onZuruecksetzen: z == Zustand.kalibriert ? () {} : null,
            onEinstellungen: () {},
            onZurueck: () {},
          ),
        ),
      ),
    ),
  );
}

/// Umgebendes Rechteck eines Widgets in Bildschirmkoordinaten (berücksichtigt Drehung).
Rect bildschirmRect(WidgetTester t, Finder f) {
  final box = t.renderObject<RenderBox>(f);
  final pts = [
    box.localToGlobal(Offset.zero),
    box.localToGlobal(Offset(box.size.width, 0)),
    box.localToGlobal(Offset(0, box.size.height)),
    box.localToGlobal(Offset(box.size.width, box.size.height)),
  ];
  final xs = pts.map((p) => p.dx), ys = pts.map((p) => p.dy);
  return Rect.fromLTRB(xs.reduce(math.min), ys.reduce(math.min), xs.reduce(math.max), ys.reduce(math.max));
}

void main() {
  const groessen = <Size>[
    Size(360, 640),
    Size(320, 568),
    Size(412, 915),
    Size(800, 360),
    Size(640, 300),
    Size(360, 360),
  ];

  group('Kein Überlauf, kein Scrollen, Messung sichtbar', () {
    for (final g in groessen) {
      for (final m in Modus.values) {
        for (final z in Zustand.values) {
          testWidgets('${g.width.toInt()}x${g.height.toInt()} ${m.name} ${z.name}', (t) async {
            t.view.physicalSize = g;
            t.view.devicePixelRatio = 1.0;
            addTearDown(t.view.resetPhysicalSize);
            addTearDown(t.view.resetDevicePixelRatio);
            await t.pumpWidget(baue(m, z, drehung: 0));
            expect(t.takeException(), isNull, reason: 'Überlauf oder Layoutfehler');
            expect(find.byType(Scrollable), findsNothing, reason: 'es darf nichts scrollen');
            expect(find.byKey(const Key('modusLabel')), findsOneWidget);
            if (z == Zustand.fehler) return;
            final r = bildschirmRect(t, find.byKey(const Key('status')));
            expect(r.left, greaterThanOrEqualTo(0));
            expect(r.right, lessThanOrEqualTo(g.width));
            expect(r.bottom, lessThanOrEqualTo(g.height));
            if (!m.istFlaeche && g.width > g.height * 1.3 && z == Zustand.gueltig) {
              // Breite Ansicht: die Skala nutzt den größten Teil des Bildschirms.
              final skala = t.getSize(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is SkalaPainter));
              expect(skala.width, greaterThan(g.width * 0.7));
              expect(skala.height, greaterThan(g.height * 0.7));
            }
            if (!m.istFlaeche) {
              final w = bildschirmRect(t, find.byKey(const Key('winkel')));
              expect(w.left, greaterThanOrEqualTo(0));
              expect(w.right, lessThanOrEqualTo(g.width));
              expect(w.top, greaterThanOrEqualTo(0));
              expect(w.bottom, lessThanOrEqualTo(g.height));
            }
          });
        }
      }
    }
  });

  group('Seitenlagen: ganze Anzeige gedreht (Handy im Hochformat-Bildschirm)', () {
    for (final g in const [Size(360, 640), Size(320, 568), Size(412, 915)]) {
      for (final (m, z) in [
        for (final m in [Modus.linieLinks, Modus.linieRechts])
          for (final z in Zustand.values) (m, z),
      ]) {
        testWidgets('${g.width.toInt()}x${g.height.toInt()} ${m.name} ${z.name}', (t) async {
          t.view.physicalSize = g;
          t.view.devicePixelRatio = 1.0;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          await t.pumpWidget(baue(m, z, drehung: m.viertelDrehungen));
          expect(t.takeException(), isNull);
          expect(find.byType(Scrollable), findsNothing);
          if (z == Zustand.fehler) return;
          if (z == Zustand.gueltig) {
            final skala = t.getSize(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is SkalaPainter));
            expect(skala.width, greaterThan(g.height * 0.7), reason: 'Skala nutzt die lange Seite');
            expect(skala.height, greaterThan(g.width * 0.7), reason: 'Skala nutzt die kurze Seite');
          }
          // Statusfeld bleibt komplett auf dem Bildschirm.
          final r = bildschirmRect(t, find.byKey(const Key('status')));
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.right, lessThanOrEqualTo(g.width));
          expect(r.top, greaterThanOrEqualTo(0));
          expect(r.bottom, lessThanOrEqualTo(g.height));
          // Die Textrichtung (x-Achse des Textes) zeigt auf dem Bildschirm nach unten (linke Seite,
          // 1 Vierteldrehung im Uhrzeigersinn) bzw. nach oben (rechte Seite, 3 Vierteldrehungen).
          final box = t.renderObject<RenderBox>(find.byKey(const Key('modusLabel')));
          final a = box.localToGlobal(Offset.zero);
          final b = box.localToGlobal(Offset(box.size.width, 0));
          expect((b.dx - a.dx).abs(), lessThan(1e-6));
          if (m == Modus.linieLinks) {
            expect(b.dy - a.dy, greaterThan(0));
          } else {
            expect(b.dy - a.dy, lessThan(0));
          }
        });
      }
    }
  });

  group('Inhalt', () {
    testWidgets('1D gültig: Winkel mit Grad, Richtung, Gefälle', (t) async {
      t.view.physicalSize = const Size(360, 640);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(baue(Modus.linieDisplay, Zustand.gueltig, drehung: 0));
      expect((t.widget<Text>(find.byKey(const Key('winkel')))).data, contains('°'));
      expect(find.text('LINIE · DISPLAY VORNE'), findsOneWidget);
      expect(find.textContaining('mm/m'), findsOneWidget);
      expect(find.textContaining('%'), findsOneWidget);
      expect(find.text('Kalibrieren'), findsOneWidget);
      expect(find.text('Zurücksetzen'), findsNothing, reason: 'nur wenn kalibriert');
    });

    testWidgets('Zurücksetzen erscheint nur nach Kalibrierung', (t) async {
      await t.pumpWidget(baue(Modus.flaeche, Zustand.kalibriert, drehung: 0));
      expect(find.text('Zurücksetzen'), findsOneWidget);
    });

    testWidgets('nicht in Lage: Hinweis statt Werte', (t) async {
      t.view.physicalSize = const Size(360, 640);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(baue(Modus.linieLinks, Zustand.nichtInLage, drehung: 0));
      expect(find.text('NICHT IN LAGE'), findsOneWidget);
      expect(find.text('Handy auf die linke Seite stellen'), findsOneWidget);
      expect((t.widget<Text>(find.byKey(const Key('winkel')))).data, '–');
    });

    testWidgets('2D: X und Y sichtbar', (t) async {
      t.view.physicalSize = const Size(360, 640);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(baue(Modus.flaeche, Zustand.gueltig, drehung: 0));
      expect(find.text('FLÄCHE (2D)'), findsOneWidget);
      expect(find.textContaining('X (links/rechts)'), findsOneWidget);
      expect(find.textContaining('Y (vorne/hinten)'), findsOneWidget);
    });
  });

  group('Einstellungen', () {
    for (final g in const [Size(360, 640), Size(800, 360)]) {
      testWidgets('${g.width.toInt()}x${g.height.toInt()}: Hinweistext exakt, Wahl löst Callback aus', (t) async {
        t.view.physicalSize = g;
        t.view.devicePixelRatio = 1.0;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        Modus? gewaehlt;
        bool? auto;
        await t.pumpWidget(MaterialApp(
          home: Scaffold(
            body: EinstellungenInhalt(
              modus: Modus.flaeche,
              auto: true,
              onAuto: (v) => auto = v,
              onModus: (m) => gewaehlt = m,
              onSchliessen: () {},
            ),
          ),
        ));
        expect(t.takeException(), isNull);
        expect(find.text('Automatisch umschalten'), findsOneWidget);
        await t.tap(find.byType(Switch));
        expect(auto, false);
        await t.scrollUntilVisible(find.byKey(const Key('modus_linieRechts')), 100);
        await t.ensureVisible(find.byKey(const Key('modus_linieRechts')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('modus_linieRechts')));
        await t.scrollUntilVisible(find.text('Hinweis zur Messung'), 300);
        expect(
            find.text('Die Messung erfolgt mit den Bewegungssensoren des Smartphones. '
                'Die Genauigkeit hängt vom Gerät, der Positionierung und der Kalibrierung ab.'),
            findsOneWidget);
        expect(gewaehlt, Modus.linieRechts);
      });
    }
  });
}
