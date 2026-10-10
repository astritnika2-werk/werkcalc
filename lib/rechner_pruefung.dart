/// Eingabeprüfung der Rechner: liefert eine konkrete Meldung statt eines
/// allgemeinen „Bitte gültige Werte eingeben“. Reine Logik, ohne UI.
/// Es werden keine fachlichen Grenzwerte erfunden – geprüft wird nur, was
/// rechnerisch oder physikalisch unmöglich ist (null, negativ, leer).
library;

String? _positiv(double? v, String name, {bool pflicht = true}) {
  if (v == null) return pflicht ? 'Bitte $name eingeben.' : null;
  if (v <= 0) return '$name muss größer als 0 sein.';
  return null;
}

String? pruefeRohrinhalt(List<double?> v) =>
    _positiv(v[0], 'Der Durchmesser') ?? _positiv(v[2], 'Die Länge');

String? pruefeGefaelle(List<double?> v) {
  if (v[0] != null && v[0]! <= 0) return 'Der Durchmesser muss größer als 0 sein.';
  if (v[1] != null && v[0] == null) {
    return 'Für die Rohrlänge aus dem Wasservolumen bitte auch den Durchmesser eingeben.';
  }
  if (v[2] != null && v[2]! <= 0) return 'Die Rohrlänge muss größer als 0 sein.';
  if (v[2] == null && v[1] == null) {
    return 'Bitte die Rohrlänge eingeben – oder Durchmesser und Wasservolumen.';
  }
  if (v[3] == null) return 'Bitte das Gefälle in % eingeben.';
  return null;
}

String? pruefeIsolierung(List<double?> v) =>
    _positiv(v[0], 'Der Rohrdurchmesser') ?? _positiv(v[2], 'Die Rohrlänge');

String? pruefeHeizkoerper(List<double?> v) =>
    _positiv(v[0], 'Die Raumgröße') ?? _positiv(v[1], 'Die Raumhöhe');

String? pruefeDruckverlust(List<double?> v) {
  final q = _positiv(v[0], 'Der Volumenstrom');
  if (q != null) return q;
  return _positiv(v[2], 'Der Innendurchmesser') ??
      (v[3] == null ? 'Bitte die Rohrlänge eingeben.' : null);
}

String? prueferPumpe(List<double?> v) {
  final hatQ = v[0] != null && v[0]! > 0;
  final hatP = v[1] != null && v[1]! > 0 && v[2] != null && v[2]! > 0;
  if (v[0] != null && v[0]! <= 0 && !hatP) {
    return 'Der Volumenstrom muss größer als 0 sein – oder Heizleistung und Spreizung eingeben.';
  }
  if (!hatQ && !hatP) {
    if (v[1] != null && v[1]! <= 0) return 'Die Heizleistung muss größer als 0 sein.';
    if (v[2] != null && v[2]! <= 0) return 'Die Spreizung (ΔT) muss größer als 0 sein.';
    return 'Bitte Volumenstrom eingeben – oder Heizleistung und Spreizung (ΔT).';
  }
  return _positiv(v[3], 'Der Rohr-Innendurchmesser') ??
      (v[4] == null ? 'Bitte die Rohrlänge (Vorlauf + Rücklauf) eingeben.' : null);
}

String? pruefeMwst(List<double?> v) {
  if (v[0] == null && v[1] == null) return 'Bitte Netto- oder Bruttobetrag eingeben.';
  return null;
}

String? pruefeArbeitszeit(List<double?> v) {
  if (v[0] == null) return 'Bitte die Stunden eingeben.';
  if (v[1] == null) return 'Bitte den Stundenlohn eingeben.';
  return null;
}

String? pruefeEinFeld(List<double?> v) =>
    v.every((e) => e == null) ? 'Bitte einen Wert eingeben.' : null;
