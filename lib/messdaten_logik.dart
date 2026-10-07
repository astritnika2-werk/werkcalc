import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

/// Messdaten-Aufzeichnung (Test-Werkzeug, keine Erkennung): speichert Beschleunigungs-Rohwerte mit
/// Zeitstempeln und Mikrofon-SPEKTREN. Es wird KEIN Audio gespeichert – aus den Spektren lässt sich
/// kein Ton und keine Sprache rekonstruieren (nur Betragsspektren, keine Phase).

/// Radix-2-FFT (in place, Länge muss Zweierpotenz sein).
void fft(Float64List re, Float64List im) {
  final n = re.length;
  var j = 0;
  for (var i = 1; i < n; i++) {
    var bit = n >> 1;
    for (; j & bit != 0; bit >>= 1) {
      j ^= bit;
    }
    j ^= bit;
    if (i < j) {
      final tr = re[i];
      re[i] = re[j];
      re[j] = tr;
      final ti = im[i];
      im[i] = im[j];
      im[j] = ti;
    }
  }
  for (var len = 2; len <= n; len <<= 1) {
    final ang = -2 * math.pi / len;
    final wr = math.cos(ang), wi = math.sin(ang);
    for (var i = 0; i < n; i += len) {
      var cr = 1.0, ci = 0.0;
      for (var k = 0; k < len ~/ 2; k++) {
        final a = i + k, b = i + k + len ~/ 2;
        final tr = re[b] * cr - im[b] * ci;
        final ti = re[b] * ci + im[b] * cr;
        re[b] = re[a] - tr;
        im[b] = im[a] - ti;
        re[a] += tr;
        im[a] += ti;
        final ncr = cr * wr - ci * wi;
        ci = cr * wi + ci * wr;
        cr = ncr;
      }
    }
  }
}

double _db(double x) => 20 * math.log(math.max(x, 1e-9)) / math.ln10;
double _r(double v, int d) {
  final f = math.pow(10, d).toDouble();
  return (v * f).roundToDouble() / f;
}

/// Wandelt PCM16-Audio fortlaufend in Betragsspektren um (dBFS).
class MikroAnalysator {
  MikroAnalysator({this.sampleRate = 16000, this.n = 8192, this.hop = 4096, this.feinBisHz = 2000, this.baender = 64})
      : _fenster = Float64List.fromList([for (var i = 0; i < n; i++) 0.5 - 0.5 * math.cos(2 * math.pi * i / (n - 1))]) {
    var s = 0.0;
    for (final w in _fenster) {
      s += w;
    }
    _fensterSumme = s;
  }

  final int sampleRate;
  final int n;
  final int hop;
  final double feinBisHz;
  final int baender;
  final Float64List _fenster;
  late final double _fensterSumme;
  final List<double> _puffer = [];
  int _verarbeitet = 0; // Anzahl Samples, die als Fenster-Anfang schon durch sind

  double get binHz => sampleRate / n;
  int get feinBins => (feinBisHz / binHz).floor();

  /// Mittenfrequenzen der groben Bänder oberhalb [feinBisHz] bis zur Nyquist-Frequenz (Hz, untere Kante).
  List<double> get baenderUntenHz {
    final breite = (sampleRate / 2 - feinBisHz) / baender;
    return [for (var i = 0; i < baender; i++) _r(feinBisHz + i * breite, 1)];
  }

  final List<double> zeiten = []; // Ende des Fensters, Sekunden seit Start
  final List<double> rmsDbfs = [];
  final List<List<double>> spekDb = [];
  final List<List<double>> baenderDb = [];

  /// Rohes PCM16 (little endian, mono) hinzufügen.
  void addPcm16(Uint8List bytes) {
    final bd = ByteData.sublistView(bytes);
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      _puffer.add(bd.getInt16(i, Endian.little) / 32768.0);
    }
    while (_puffer.length >= n) {
      _fensterAuswerten();
      _puffer.removeRange(0, hop);
      _verarbeitet += hop;
    }
  }

  void _fensterAuswerten() {
    final re = Float64List(n), im = Float64List(n);
    var quad = 0.0;
    for (var i = 0; i < n; i++) {
      final v = _puffer[i];
      quad += v * v;
      re[i] = v * _fenster[i];
    }
    fft(re, im);
    final fein = <double>[];
    for (var k = 0; k <= feinBins; k++) {
      final a = 2 * math.sqrt(re[k] * re[k] + im[k] * im[k]) / _fensterSumme;
      fein.add(_r(_db(a), 1));
    }
    final grob = <double>[];
    final k0 = feinBins + 1, k1 = n ~/ 2;
    final proBand = (k1 - k0) / baender;
    for (var b = 0; b < baender; b++) {
      final von = k0 + (b * proBand).floor();
      final bis = math.max(von + 1, k0 + ((b + 1) * proBand).floor());
      var p = 0.0;
      var c = 0;
      for (var k = von; k < bis && k < k1; k++) {
        final a = 2 * math.sqrt(re[k] * re[k] + im[k] * im[k]) / _fensterSumme;
        p += a * a;
        c++;
      }
      grob.add(_r(_db(math.sqrt(p / math.max(c, 1))), 1));
    }
    zeiten.add(_r((_verarbeitet + n) / sampleRate, 3));
    rmsDbfs.add(_r(_db(math.sqrt(quad / n)), 1));
    spekDb.add(fein);
    baenderDb.add(grob);
  }
}

/// Beschleunigungs-Rohwerte (Zeit in Sekunden seit Start der Aufnahme).
class AccAufnahme {
  final List<double> t = [], x = [], y = [], z = [];
  void add(double ts, double ax, double ay, double az) {
    t.add(ts);
    x.add(ax);
    y.add(ay);
    z.add(az);
  }

  double get fsMittel => t.length < 2 ? 0 : (t.length - 1) / (t.last - t.first);
}

const kMessSzenarien = <String>[
  '1 Pumpe EIN, Handy am Gehäuse',
  '2 Pumpe AUS, Handy am Gehäuse (gleiche Stelle)',
  '3 Keine Pumpe, Handy ruhig auf dem Tisch',
  '4 Pumpe läuft in der Nähe, Handy nicht an der Pumpe',
  '5 Fremdgeräusch: Pumpe AUS, Brenner/Lüfter läuft',
  '6 Sonstiges (siehe Notiz)',
];

/// Dateiname aus Szenario und Zeit.
String messDateiname(String szenario, DateTime zeit) {
  final nr = szenario.isNotEmpty ? szenario[0] : 'x';
  String z2(int v) => v.toString().padLeft(2, '0');
  return 'werkcalc-messung-$nr-${zeit.year}${z2(zeit.month)}${z2(zeit.day)}-${z2(zeit.hour)}${z2(zeit.minute)}${z2(zeit.second)}.json';
}

/// Baut die Messdatei (JSON-Text).
String messdatenJson({
  required String szenario,
  required String notiz,
  required DateTime zeit,
  required double dauerSek,
  required AccAufnahme acc,
  required MikroAnalysator? mikro,
  required String mikroStatus,
  required String app,
}) {
  List<double> rr(List<double> l, int d) => [for (final v in l) _r(v, d)];
  final m = <String, Object?>{
    'format': 'werkcalc-pumpenmessung-v1',
    'hinweis': 'Nur Rohwerte des Beschleunigungssensors und Mikrofon-Betragsspektren (dBFS). Kein Audio gespeichert.',
    'app': app,
    'erstellt': zeit.toIso8601String(),
    'szenario': szenario,
    'notiz': notiz,
    'dauerSek': _r(dauerSek, 2),
    'acc': {
      'einheit': 'm/s² inkl. Schwerkraft',
      'fsMittelHz': _r(acc.fsMittel, 1),
      'n': acc.t.length,
      't': rr(acc.t, 4),
      'x': rr(acc.x, 4),
      'y': rr(acc.y, 4),
      'z': rr(acc.z, 4),
    },
    'mikrofon': {
      'status': mikroStatus,
      if (mikro != null) ...{
        'sampleRate': mikro.sampleRate,
        'fftN': mikro.n,
        'hopSamples': mikro.hop,
        'binHz': _r(mikro.binHz, 4),
        'feinBisHz': mikro.feinBisHz,
        'baenderUntenHz': mikro.baenderUntenHz,
        'frames': mikro.zeiten.length,
        't': mikro.zeiten,
        'rmsDbfs': mikro.rmsDbfs,
        'spekDb': mikro.spekDb,
        'baenderDb': mikro.baenderDb,
      },
    },
  };
  return const JsonEncoder().convert(m);
}
