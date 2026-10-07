import 'pumpe_analyse.dart';
import 'pumpe_lauf_logik.dart' show LaufStatus;

/// Angezeigter Zustand der direkten Pumpenerkennung.
enum PumpeAnzeige { analyse, laeuft, steht, unklar }

/// Laufende Auswertung ohne Referenzmessung: Sensorwerte kommen fortlaufend herein, jede Sekunde
/// wird das jüngste Fenster (bis 6 s) analysiert. Ein Ergebnis wird erst angezeigt, wenn zwei
/// aufeinanderfolgende Fenster dasselbe sagen – ein einzelnes Fenster entscheidet nie.
class DirektAuswertung {
  static const double fensterSek = 6.0;
  static const double minSek = 3.0; // vorher nie ein Ergebnis
  static const double stehtMinSek = 5.5; // „steht“ erst mit (fast) vollem Fenster
  static const double unklarNachSek = 14.0; // so lange ohne klares Ergebnis → „nicht eindeutig“

  final List<double> _t = [], _x = [], _y = [], _z = [];
  double? _start;
  double _letzterStabil = 0;
  LaufStatus? _kandidat;
  int _gleich = 0;
  static const int laeuftGleich = 3; // „läuft“ erst nach drei übereinstimmenden Auswertungen
  static const int stehtGleich = 2;

  PumpeAnzeige anzeige = PumpeAnzeige.analyse;
  PumpeBefund? befund;
  Spektrum? spektrum;
  double fensterDauer = 0;

  /// Sekunden seit Beginn der Messung (Zeit des letzten Messwerts).
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
    _start = null;
    _letzterStabil = 0;
    _kandidat = null;
    _gleich = 0;
    anzeige = PumpeAnzeige.analyse;
    befund = null;
    spektrum = null;
    fensterDauer = 0;
  }

  /// Einmal pro Sekunde aufrufen.
  PumpeAnzeige auswerten() {
    if (_t.length < 2) return anzeige;
    fensterDauer = _t.last - _t.first;
    if (fensterDauer < minSek) return anzeige;
    final sig = PumpeSignal(t: List.of(_t), x: List.of(_x), y: List.of(_y), z: List.of(_z))
        .bereinigt((fensterDauer * 1000).round());
    final sp = analysiere(sig);
    final b = bewertePumpeDirekt(sp);
    spektrum = sp;
    befund = b;
    var kand = b.status;
    if (kand == LaufStatus.steht && fensterDauer < stehtMinSek) kand = LaufStatus.unklar;
    _gleich = kand == _kandidat ? _gleich + 1 : 1;
    _kandidat = kand;
    final noetig = kand == LaufStatus.laeuft ? laeuftGleich : stehtGleich;
    if (_gleich >= noetig) {
      switch (kand) {
        case LaufStatus.laeuft:
          anzeige = PumpeAnzeige.laeuft;
          _letzterStabil = laufzeit;
        case LaufStatus.steht:
          anzeige = PumpeAnzeige.steht;
          _letzterStabil = laufzeit;
        case LaufStatus.unklar:
          anzeige = laufzeit - _letzterStabil > unklarNachSek ? PumpeAnzeige.unklar : PumpeAnzeige.analyse;
      }
    } else if (anzeige == PumpeAnzeige.analyse && laufzeit - _letzterStabil > unklarNachSek) {
      anzeige = PumpeAnzeige.unklar;
    }
    return anzeige;
  }
}
