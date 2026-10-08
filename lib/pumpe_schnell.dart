import 'dart:math' as math;

import 'pumpe_direkt.dart' show PumpeAnzeige;

/// Schnelle, schwellenfreie Pumpenerkennung (Beschleunigungssensor, Handy am Pumpengehäuse).
///
/// Es gibt keine absolute Amplitudenschwelle. Erkannt werden schmale, stabile Spektrallinien,
/// die deutlich aus ihrer direkten Umgebung herausragen (relativer Kontrast). Je weiter das Handy
/// von der Pumpe entfernt ist, desto kleiner wird dieser Kontrast – das Signal verschwindet von selbst.
/// „Läuft“ braucht dieselbe Linie (±1 Hz) in mindestens 2 der letzten 3 Auswertungen (alle 0,5 s,
/// Fenster 2 s) und zwei Auswertungen in Folge. „Steht“ braucht mehrere Sekunden ohne Linie.
///
/// Die Parameter sind interne Richtwerte, an den drei echten Aufnahmen (Grundfos UPS 32-80,
/// ALPHA2 32-60, MAGNA3 50-60 F) und an simulierten Signalen geprüft. Keine Herstellervorgabe,
/// keine Norm. Es wird kein Volumenstrom gemessen.
class SchnellAuswertung {
  static const double fensterSek = 2.0;
  static const double schrittSek = 0.5;
  static const double bandUntenHz = 12.0;
  static const double bandObenFaktor = 0.45;
  static const double bandObenMaxHz = 250.0;
  static const double rasterHz = 0.5;
  static const double kontrast = 12.0; // Linie ≥ 12 × Median der Nachbarbins (±3 Hz, ohne ±1 Hz)
  static const int ausschlussBins = 2;
  static const int nachbarBins = 6;
  static const double linienTolHz = 1.0;
  static const int histN = 3, histK = 2;
  static const int einFolge = 2; // aufeinanderfolgende Auswertungen mit Linie → „läuft“
  static const double verlustSek = 3.0; // ohne Linie: „läuft“ → Signal verloren (gelb)
  static const double verlorenGelbSek = 1.5; // ohne Linie: gelbe Meldung „Signal verloren“
  static const double stehtNachSek = 6.0; // so lange ohne Linie (nach „läuft“) → „steht“
  static const double stehtStartSek = 8.0; // so lange ohne Linie seit Start → „steht“
  static const double unklarNachSek = 14.0;
  static const double handMaxMs2 = 0.5; // Handbewegung 1,5–8 Hz: darüber zählt „keine Linie“ nicht
  static const double fsMinSteht = 140.0; // darunter ist das Band zu schmal für „steht“

  final List<double> _t = [], _x = [], _y = [], _z = [];
  final List<List<double>> _hist = [];
  double? _start;
  double _naechste = 0;
  double? _letzteLinie;
  double _absenzAnker = 0;
  int _folge = 0;
  bool _warLaeuft = false;
  double _entscheidung = 0; // Messzeit der letzten bestätigten Anzeige „läuft“/„steht“ (bzw. Start)

  PumpeAnzeige anzeige = PumpeAnzeige.analyse;
  bool signalVerloren = false;
  double fensterDauer = 0;
  double fs = 0;
  int n = 0;
  double? linieHz;
  double? linieRms;
  double? linieKontrast;
  double lfRms = 0;
  double bandMedianRms = 0;

  double get laufzeit => _t.isEmpty ? 0 : _t.last - (_start ?? _t.first);

  void add(double t, double x, double y, double z) {
    _start ??= t;
    _t.add(t);
    _x.add(x);
    _y.add(y);
    _z.add(z);
    final grenze = t - fensterSek;
    var cut = 0;
    while (cut < _t.length - 1 && _t[cut] < grenze) {
      cut++;
    }
    if (cut > 0) {
      _t.removeRange(0, cut);
      _x.removeRange(0, cut);
      _y.removeRange(0, cut);
      _z.removeRange(0, cut);
    }
  }

  void neu() {
    _t.clear();
    _x.clear();
    _y.clear();
    _z.clear();
    _hist.clear();
    _start = null;
    _naechste = 0;
    _letzteLinie = null;
    _absenzAnker = 0;
    _folge = 0;
    _warLaeuft = false;
    _entscheidung = 0;
    anzeige = PumpeAnzeige.analyse;
    signalVerloren = false;
    fensterDauer = 0;
    fs = 0;
    n = 0;
    linieHz = linieRms = linieKontrast = null;
    lfRms = 0;
    bandMedianRms = 0;
  }

  /// Regelmäßig aufrufen (z. B. alle 250–500 ms); rechnet nur alle [schrittSek] Messzeit.
  PumpeAnzeige auswerten() {
    if (_t.length < 64) return anzeige;
    fensterDauer = _t.last - _t.first;
    if (fensterDauer < fensterSek - 0.1) return anzeige;
    final jetzt = laufzeit;
    if (jetzt < _naechste) return anzeige;
    _naechste = jetzt + schrittSek - 1e-9;
    _rechne(jetzt);
    return anzeige;
  }

  void _rechne(double jetzt) {
    n = _t.length;
    fs = (n - 1) / (_t.last - _t.first);
    final fmax = math.min(fs * bandObenFaktor, bandObenMaxHz);
    final nf = ((fmax - bandUntenHz) / rasterHz).floor() + 1;
    if (nf < 2 * nachbarBins + 2) return;
    final t0 = _t.first;
    final len = _t.last - t0;
    final w = List<double>.generate(n, (i) => 0.5 - 0.5 * math.cos(2 * math.pi * (_t[i] - t0) / len));
    var wsum = 0.0;
    var mx = 0.0, my = 0.0, mz = 0.0;
    for (var i = 0; i < n; i++) {
      wsum += w[i];
      mx += _x[i];
      my += _y[i];
      mz += _z[i];
    }
    mx /= n;
    my /= n;
    mz /= n;
    final xs = List<double>.generate(n, (i) => (_x[i] - mx) * w[i]);
    final ys = List<double>.generate(n, (i) => (_y[i] - my) * w[i]);
    final zs = List<double>.generate(n, (i) => (_z[i] - mz) * w[i]);
    final tt = List<double>.generate(n, (i) => _t[i] - t0);
    final f = List<double>.generate(nf, (k) => bandUntenHz + k * rasterHz);
    final p = List<double>.filled(nf, 0);
    final norm = 2.0 / (wsum * wsum); // Sinus der Amplitude A → p = A²/2
    for (var k = 0; k < nf; k++) {
      final om = 2 * math.pi * f[k];
      var cx = 0.0, sx = 0.0, cy = 0.0, sy = 0.0, cz = 0.0, sz = 0.0;
      for (var i = 0; i < n; i++) {
        final c = math.cos(om * tt[i]), s = math.sin(om * tt[i]);
        cx += xs[i] * c;
        sx += xs[i] * s;
        cy += ys[i] * c;
        sy += ys[i] * s;
        cz += zs[i] * c;
        sz += zs[i] * s;
      }
      p[k] = norm * 0.5 * (cx * cx + sx * sx + cy * cy + sy * sy + cz * cz + sz * sz);
    }
    // Handbewegung 1,5 … 8 Hz: stärkste Frequenz (rms)
    var lf = 0.0;
    for (var fl = 1.5; fl <= 8.0; fl += 0.5) {
      final om = 2 * math.pi * fl;
      var a = 0.0, b = 0.0;
      for (var ax = 0; ax < 3; ax++) {
        final s = ax == 0 ? xs : (ax == 1 ? ys : zs);
        var c = 0.0, sn = 0.0;
        for (var i = 0; i < n; i++) {
          c += s[i] * math.cos(om * tt[i]);
          sn += s[i] * math.sin(om * tt[i]);
        }
        a += c * c;
        b += sn * sn;
      }
      lf = math.max(lf, math.sqrt(norm * 0.5 * (a + b)));
    }
    lfRms = lf;

    // Linien: lokales Maximum (±2 Bins) und ≥ Kontrast × Median der Nachbarn
    final linien = <double>[];
    var besteK = -1;
    var besteKon = 0.0;
    final alle = List<double>.of(p)..sort();
    bandMedianRms = math.sqrt(alle[alle.length ~/ 2]);
    for (var k = 0; k < nf; k++) {
      final nb = <double>[];
      for (var j = math.max(0, k - nachbarBins); j <= math.min(nf - 1, k + nachbarBins); j++) {
        if ((j - k).abs() > ausschlussBins) nb.add(p[j]);
      }
      if (nb.length < 6) continue;
      nb.sort();
      final med = nb.length.isOdd ? nb[nb.length ~/ 2] : (nb[nb.length ~/ 2 - 1] + nb[nb.length ~/ 2]) / 2;
      var istMax = true;
      for (var j = math.max(0, k - 2); j <= math.min(nf - 1, k + 2); j++) {
        if (p[j] > p[k]) istMax = false;
      }
      if (!istMax || med <= 0) continue;
      final kon = p[k] / med;
      if (kon > kontrast) {
        linien.add(f[k]);
        if (kon > besteKon) {
          besteKon = kon;
          besteK = k;
        }
      }
    }
    _hist.add(linien);
    if (_hist.length > histN) _hist.removeAt(0);
    final stabil = <double>[
      for (final fr in linien)
        if (_hist.where((h) => h.any((g) => (g - fr).abs() <= linienTolHz)).length >= histK) fr
    ];
    if (besteK >= 0) {
      linieHz = f[besteK];
      linieRms = math.sqrt(p[besteK]);
      linieKontrast = besteKon;
    } else {
      linieHz = linieRms = linieKontrast = null;
    }
    _zustand(jetzt, stabil.isNotEmpty);
  }

  void _zustand(double jetzt, bool linie) {
    if (linie) {
      _folge++;
      _letzteLinie = jetzt;
    } else {
      _folge = 0;
    }
    final handUnruhig = lfRms > handMaxMs2;
    if (anzeige == PumpeAnzeige.laeuft) {
      if (linie) {
        signalVerloren = false;
        return;
      }
      if (handUnruhig) _absenzAnker = jetzt; // Bewegung: Verlust zählt nicht
      final ohne = jetzt - math.max(_letzteLinie ?? 0, _absenzAnker);
      if (ohne >= verlustSek) {
        anzeige = PumpeAnzeige.analyse;
        signalVerloren = true;
        _warLaeuft = true;
      }
      return;
    }
    if (_folge >= einFolge) {
      anzeige = PumpeAnzeige.laeuft;
      signalVerloren = false;
      _entscheidung = jetzt;
      return;
    }
    if (handUnruhig) _absenzAnker = jetzt;
    final basis = math.max(_letzteLinie ?? 0, _absenzAnker);
    final ohne = jetzt - basis;
    final steht = _warLaeuft || _letzteLinie != null ? stehtNachSek : stehtStartSek;
    if (ohne >= steht) {
      anzeige = fs >= fsMinSteht ? PumpeAnzeige.steht : PumpeAnzeige.unklar;
      signalVerloren = false;
      if (anzeige == PumpeAnzeige.steht) _entscheidung = jetzt;
    } else if (anzeige == PumpeAnzeige.steht) {
      // bleibt rot, bis eine stabile Linie erscheint
    } else if (jetzt - _entscheidung >= unklarNachSek) {
      anzeige = PumpeAnzeige.unklar;
    } else if (_warLaeuft || _letzteLinie != null) {
      signalVerloren = ohne >= verlorenGelbSek;
    }
  }
}
