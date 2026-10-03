#!/usr/bin/env python3
"""Unabhängige Prüfung der Rechenformeln der App.

Vergleicht die in lib/logic.dart verwendeten Formeln mit etablierten
Bibliotheken:
  - iapws  (IAPWS-IF97): Dichte und Viskosität von Wasser
  - fluids (Reibungsbeiwert nach Colebrook, Konstanten)

Aufruf:
  pip install fluids iapws
  python3 tools/verify_formulas.py            # prüft und gibt Referenzwerte aus
  python3 tools/verify_formulas.py --dart     # gibt zusätzlich die Wasser-Tabelle als Dart-Code aus
"""
import math
import sys

from fluids import friction_factor
from fluids.constants import inch
from iapws import IAPWS97

P_MPA = 0.1  # Umgebungsdruck-Näherung (1 bar)
TEMPS = list(range(0, 100, 5))  # 0 .. 95 °C


def water(t_c):
    w = IAPWS97(T=t_c + 273.15, P=P_MPA)
    rho = w.rho  # kg/m3
    nu = w.mu / w.rho  # m2/s
    return rho, nu


def table():
    return [(t, *water(t)) for t in TEMPS]


def interp(t_c, tab):
    """Lineare Interpolation wie in logic.dart (außerhalb geklemmt)."""
    if t_c <= tab[0][0]:
        return tab[0][1], tab[0][2]
    if t_c >= tab[-1][0]:
        return tab[-1][1], tab[-1][2]
    for (t0, r0, n0), (t1, r1, n1) in zip(tab, tab[1:]):
        if t0 <= t_c <= t1:
            f = (t_c - t0) / (t1 - t0)
            return r0 + f * (r1 - r0), n0 + f * (n1 - n0)
    raise ValueError


def colebrook_iter(re, rel):
    """Gleiche Methode wie in logic.dart: Swamee-Jain als Startwert, dann Fixpunkt."""
    lam0 = 0.25 / (math.log10(rel / 3.7 + 5.74 / re**0.9)) ** 2
    x = 1 / math.sqrt(lam0)
    for _ in range(50):
        x_new = -2 * math.log10(rel / 3.7 + 2.51 * x / re)
        if abs(x_new - x) < 1e-12:
            x = x_new
            break
        x = x_new
    return 1 / (x * x)


def druckverlust(q_lmin, d_mm, l_m, t_c, k_mm, zeta, tab):
    rho, nu = interp(t_c, tab)
    d = d_mm / 1000
    q = q_lmin / 60000  # m3/s
    a = math.pi * d * d / 4
    v = q / a
    re = v * d / nu
    lam = 64 / re if re < 2300 else colebrook_iter(re, (k_mm / 1000) / d)
    dyn = rho * v * v / 2
    r = lam / d * dyn  # Pa/m
    dp_rohr = r * l_m
    dp_ein = zeta * dyn
    return dict(v=v, re=re, lam=lam, r=r, dp_rohr=dp_rohr, dp_ein=dp_ein,
                dp=dp_rohr + dp_ein)


def check(name, got, want, rel=1e-6, absol=1e-9):
    ok = abs(got - want) <= max(absol, rel * abs(want))
    print(f"  {'OK ' if ok else 'FEHLER'} {name}: {got:.6g} (Soll {want:.6g})")
    if not ok:
        global FAILED
        FAILED = True


FAILED = False


def main():
    tab = table()

    print("1) Colebrook-Iteration gegen fluids.friction_factor (Clamond)")
    for re in (4000, 10_000, 22_000, 50_000, 100_000, 500_000, 2_000_000):
        for rel in (1e-6, 7.5e-5, 2e-3, 8e-3):
            mine = colebrook_iter(re, rel)
            ref = friction_factor(Re=re, eD=rel, Method="Clamond")
            if abs(mine - ref) > 1e-4 * ref:
                print(f"  FEHLER Re={re} e/D={rel}: {mine} vs {ref}")
                globals()["FAILED"] = True
    print("  geprüft: 28 Kombinationen, Toleranz 0,01 %")

    print("2) Wasser-Tabelle gegen IAPWS-IF97 (Stützstellen, Interpolation dazwischen)")
    # Interpolationsfehler zwischen Stützstellen bei 5-K-Raster prüfen
    worst_rho = worst_nu = 0.0
    for t in [x / 2 for x in range(0, 190)]:
        rho_i, nu_i = interp(t, tab)
        rho_t, nu_t = water(t)
        worst_rho = max(worst_rho, abs(rho_i - rho_t) / rho_t)
        worst_nu = max(worst_nu, abs(nu_i - nu_t) / nu_t)
    print(f"  max. Interpolationsfehler Dichte {worst_rho:.4%}, Viskosität {worst_nu:.4%}")
    if worst_rho > 0.001 or worst_nu > 0.02:
        globals()["FAILED"] = True
        print("  FEHLER: Interpolationsfehler zu groß")

    print("3) Referenzfälle Druckverlust (Werte für die Dart-Tests)")
    cases = [
        # q l/min, d mm, L m, T °C, k mm, zeta
        (10, 20, 10, 60, 0.0015, 0),   # Kupfer 22x1, Heizung
        (10, 20, 10, 60, 0.0015, 5),   # mit Einzelwiderständen
        (5, 16, 25, 10, 0.007, 0),     # Kunststoff, Kaltwasser
        (30, 26, 12, 70, 0.045, 2),    # Stahlrohr
        (2, 12, 5, 20, 0.0015, 0),     # laminar/niedriger Re? (siehe Ausgabe)
    ]
    for c in cases:
        res = druckverlust(*c, tab)
        # Gegenprobe mit fluids (Clamond) auf denselben Eingaben
        d = c[1] / 1000
        lam_ref = friction_factor(Re=res["re"], eD=(c[4] / 1000) / d, Method="Clamond") \
            if res["re"] >= 2300 else 64 / res["re"]
        check(f"lambda{c}", res["lam"], lam_ref, rel=1e-4)
        print(f"    q={c[0]} l/min d={c[1]} mm L={c[2]} m T={c[3]} k={c[4]} zeta={c[5]}"
              f" -> v={res['v']:.4f} m/s, Re={res['re']:.0f}, lambda={res['lam']:.5f},"
              f" R={res['r']:.3f} Pa/m, dp_rohr={res['dp_rohr']:.3f} Pa,"
              f" dp_ein={res['dp_ein']:.3f} Pa, dp={res['dp']:.3f} Pa")

    print("4) Einheiten und einfache Formeln")
    check("1 Zoll in mm", inch * 1000, 25.4)
    btu = 1055.05585262  # J, Internationale Tafel-BTU
    check("kW -> BTU/h", 1000 / (btu / 3600), 3412.14163, rel=1e-6)
    check("Rohrinhalt 28 mm x 10 m [L]", math.pi * (0.028 / 2) ** 2 * 10 * 1000,
          6.1575216, rel=1e-6)
    da = 0.028 + 2 * 0.050
    check("Isolierung Dämmvolumen [m3]", math.pi / 4 * (da**2 - 0.028**2) * 10,
          0.12252211, rel=1e-6)
    check("Isolierung Oberfläche [m2]", math.pi * da * 10, 4.0212386, rel=1e-6)
    check("Heizleistung 20 m2 x 100 W/m2 [W]", 20 * 100 * (2.5 / 2.5), 2000)
    netto = 8 * 25 + 30 + 105
    check("Angebot netto", netto, 335)
    check("Angebot MwSt. 19 %", netto * 0.19, 63.65)
    check("Angebot brutto", netto * 1.19, 398.65)

    if "--dart" in sys.argv:
        print("\n// ---- Dart: Wasser-Tabelle (IAPWS-IF97, 1 bar) ----")
        print("const List<double> kWasserTemperaturenC = [")
        print("  " + ", ".join(f"{t:.1f}" for t, _, _ in tab) + ",")
        print("];")
        print("const List<double> kWasserDichte = [")
        print("  " + ", ".join(f"{r:.3f}" for _, r, _ in tab) + ",")
        print("];")
        print("const List<double> kWasserViskositaet = [")
        print("  " + ", ".join(f"{n:.6e}" for _, _, n in tab) + ",")
        print("];")

    print("\nERGEBNIS:", "FEHLER" if FAILED else "alle Prüfungen bestanden")
    sys.exit(1 if FAILED else 0)


if __name__ == "__main__":
    main()
