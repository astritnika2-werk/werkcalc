import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:werkcalc/messdaten_logik.dart';

Uint8List pcm(List<double> v) {
  final b = ByteData(v.length * 2);
  for (var i = 0; i < v.length; i++) {
    b.setInt16(i * 2, (v[i] * 32767).round(), Endian.little);
  }
  return b.buffer.asUint8List();
}

void main() {
  test('FFT: Sinus 100 Hz liegt im richtigen Bin, Pegel stimmt (−6 dBFS bei Amplitude 0,5)', () {
    final m = MikroAnalysator();
    final sig = [for (var i = 0; i < 16000 * 2; i++) 0.5 * math.sin(2 * math.pi * 100 * i / 16000)];
    // in Stücken einspeisen wie ein Audio-Stream
    for (var i = 0; i < sig.length; i += 1600) {
      m.addPcm16(pcm(sig.sublist(i, math.min(i + 1600, sig.length))));
    }
    expect(m.zeiten.length, greaterThanOrEqualTo(6));
    final f = m.spekDb[2];
    var k = 0;
    for (var i = 1; i < f.length; i++) {
      if (f[i] > f[k]) k = i;
    }
    expect(k * m.binHz, closeTo(100, m.binHz));
    expect(f[k], closeTo(-6.0, 1.0));
    expect(m.spekDb[0].length, m.feinBins + 1);
    expect(m.baenderDb[0].length, 64);
    expect(m.rmsDbfs[2], closeTo(-9.0, 0.5)); // 0,5/√2 = 0,354 → −9 dBFS
  });

  test('Stille ergibt sehr niedrige Pegel, keine Fehler', () {
    final m = MikroAnalysator();
    m.addPcm16(pcm(List.filled(16000, 0.0)));
    expect(m.zeiten, isNotEmpty);
    expect(m.rmsDbfs.first, lessThan(-100));
  });

  test('Messdatei: gültiges JSON, enthält Zeitstempel und Spektren, kein Audio', () {
    final acc = AccAufnahme();
    for (var i = 0; i < 500; i++) {
      acc.add(i * 0.005, 0.1, 0.2, 9.81);
    }
    final m = MikroAnalysator();
    m.addPcm16(pcm([for (var i = 0; i < 16000 * 3; i++) 0.1 * math.sin(2 * math.pi * 50 * i / 16000)]));
    final txt = messdatenJson(
      szenario: kMessSzenarien.first,
      notiz: 'Test',
      zeit: DateTime(2026, 10, 7, 23, 0, 0),
      dauerSek: 2.5,
      acc: acc,
      mikro: m,
      mikroStatus: 'ok',
      app: 'test',
    );
    final j = jsonDecode(txt) as Map<String, dynamic>;
    expect(j['format'], 'werkcalc-pumpenmessung-v1');
    expect((j['acc']['t'] as List).length, 500);
    expect(j['acc']['fsMittelHz'], closeTo(200, 1));
    expect((j['mikrofon']['spekDb'] as List).length, m.zeiten.length);
    expect(j['mikrofon'].containsKey('pcm'), isFalse);
    expect(txt.length, lessThan(400000));
  });

  test('Dateiname enthält Szenario-Nummer und Zeit', () {
    expect(messDateiname(kMessSzenarien[1], DateTime(2026, 10, 7, 23, 5, 9)), 'werkcalc-messung-2-20261007-230509.json');
  });

  test('Zehn Sekunden Mikrofon: Dateigröße bleibt moderat', () {
    final acc = AccAufnahme();
    for (var i = 0; i < 2000; i++) {
      acc.add(i * 0.005, 0.1, 0.2, 9.81);
    }
    final m = MikroAnalysator();
    final r = math.Random(1);
    m.addPcm16(pcm([for (var i = 0; i < 16000 * 10; i++) (r.nextDouble() - 0.5) * 0.05]));
    final txt = messdatenJson(
        szenario: 'x', notiz: '', zeit: DateTime(2026), dauerSek: 10, acc: acc, mikro: m, mikroStatus: 'ok', app: 't');
    expect(txt.length, lessThan(600000));
    expect(m.zeiten.length, inInclusiveRange(18, 22));
  });
}
