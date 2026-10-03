#!/usr/bin/env python3
"""WerkCalc: erzeugt Logo, App-Icon und Store-Grafiken aus einer gemeinsamen Geometrie.

Symbol: eine Schraubenmutter (Sechskant mit Loch) mit einem Gleichheitszeichen im Loch:
Werkzeug + Rechnen. Farben: Blau #0B4A9F, Orange #FF8A00.

Aufruf:  pip install pillow && python3 tools/make_brand.py
Ausgabe: assets/icon/icon.png, assets/icon/icon_foreground.png,
         assets/brand/logo_mark_white.png, assets/brand/logo_mark_color.png,
         docs/brand/werkcalc_mark.svg, docs/brand/werkcalc_logo_*.png,
         docs/store/icon_512.png, docs/store/feature_graphic_1024x500.png
Schrift: DejaVu Sans Bold aus assets/fonts (Lizenz liegt dort bei).
"""
import math
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BLUE = (11, 74, 159)
DARK = (6, 42, 92)
ORANGE = (255, 138, 0)
WHITE = (255, 255, 255)
SS = 4  # Supersampling für glatte Kanten

# Geometrie relativ zum Umkreisradius R des Sechsecks
CORNER = 0.11      # Eckenrundung
HOLE = 0.50        # Lochradius
BAR_W = 0.60       # Breite der "="-Balken
BAR_H = 0.115      # Höhe eines Balkens
BAR_GAP = 0.125    # halber Abstand der Balkenmitten


def hex_points(cx, cy, r):
    return [(cx + r * math.cos(math.radians(a)), cy + r * math.sin(math.radians(a)))
            for a in range(0, 360, 60)]


def nut_mask(size, cx, cy, R):
    """Maske (L) der Mutter mit abgerundeten Ecken und Loch."""
    s = size * SS
    m = Image.new("L", (s, s), 0)
    d = ImageDraw.Draw(m)
    rr = CORNER * R * SS
    r1 = (R * SS) - rr / math.cos(math.radians(30))
    pts = hex_points(cx * SS, cy * SS, r1)
    d.polygon(pts, fill=255)
    d.line(pts + [pts[0]], fill=255, width=int(2 * rr), joint="curve")
    for p in pts:
        d.ellipse([p[0] - rr, p[1] - rr, p[0] + rr, p[1] + rr], fill=255)
    h = HOLE * R * SS
    d.ellipse([cx * SS - h, cy * SS - h, cx * SS + h, cy * SS + h], fill=0)
    return m.resize((size, size), Image.LANCZOS)


def bars_mask(size, cx, cy, R):
    s = size * SS
    m = Image.new("L", (s, s), 0)
    d = ImageDraw.Draw(m)
    w, h, gap = BAR_W * R * SS, BAR_H * R * SS, BAR_GAP * R * SS
    for dy in (-gap, gap):
        d.rounded_rectangle(
            [cx * SS - w / 2, cy * SS + dy - h / 2, cx * SS + w / 2, cy * SS + dy + h / 2],
            radius=h / 2, fill=255)
    return m.resize((size, size), Image.LANCZOS)


def mark(size, R, nut_color, bg=None, cx=None, cy=None):
    """Logo-Symbol als RGBA-Bild. bg=None ergibt transparenten Hintergrund."""
    cx = size / 2 if cx is None else cx
    cy = size / 2 if cy is None else cy
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0) if bg is None else bg + (255,))
    img.paste(Image.new("RGBA", (size, size), nut_color + (255,)), (0, 0), nut_mask(size, cx, cy, R))
    img.paste(Image.new("RGBA", (size, size), ORANGE + (255,)), (0, 0), bars_mask(size, cx, cy, R))
    return img


def font(size):
    return ImageFont.truetype(os.path.join(ROOT, "assets", "fonts", "DejaVuSans-Bold.ttf"), size)


def font_regular(size):
    return ImageFont.truetype(os.path.join(ROOT, "assets", "fonts", "DejaVuSans.ttf"), size)


def wordmark(d, x, y, size, werk_color, calc_color=ORANGE):
    """'Werk' + 'Calc' nebeneinander; gibt die rechte Kante zurück."""
    f = font(size)
    d.text((x, y), "Werk", font=f, fill=werk_color)
    w = d.textlength("Werk", font=f)
    d.text((x + w, y), "Calc", font=f, fill=calc_color)
    return x + w + d.textlength("Calc", font=f)


def svg_mark():
    R, cx, cy = 220, 256, 256
    rr = CORNER * R
    r1 = R - rr / math.cos(math.radians(30))
    pts = " ".join(f"{x:.2f},{y:.2f}" for x, y in hex_points(cx, cy, r1))
    h = HOLE * R
    bw, bh, gap = BAR_W * R, BAR_H * R, BAR_GAP * R
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <title>WerkCalc</title>
  <rect width="512" height="512" fill="#0B4A9F"/>
  <path fill="#FFFFFF" fill-rule="evenodd" stroke="#FFFFFF" stroke-width="{2 * rr:.2f}" stroke-linejoin="round"
        d="M{pts.replace(' ', ' L')} Z M{cx - h:.2f},{cy} a{h:.2f},{h:.2f} 0 1,0 {2 * h:.2f},0 a{h:.2f},{h:.2f} 0 1,0 {-2 * h:.2f},0 Z"/>
  <circle cx="{cx}" cy="{cy}" r="{h:.2f}" fill="#0B4A9F"/>
  <rect x="{cx - bw / 2:.2f}" y="{cy - gap - bh / 2:.2f}" width="{bw:.2f}" height="{bh:.2f}" rx="{bh / 2:.2f}" fill="#FF8A00"/>
  <rect x="{cx - bw / 2:.2f}" y="{cy + gap - bh / 2:.2f}" width="{bw:.2f}" height="{bh:.2f}" rx="{bh / 2:.2f}" fill="#FF8A00"/>
</svg>
"""


def main():
    for p in ("assets/icon", "assets/brand", "docs/brand", "docs/store"):
        os.makedirs(os.path.join(ROOT, p), exist_ok=True)

    # App-Icon (vollflächig) und adaptive Vordergrundebene (sichere Zone ca. 60 %)
    icon = mark(1024, 330, WHITE, bg=BLUE)
    icon.convert("RGB").save(os.path.join(ROOT, "assets/icon/icon.png"))
    mark(1024, 285, WHITE).save(os.path.join(ROOT, "assets/icon/icon_foreground.png"))

    # Logo-Symbole für die App (Blau-Hintergrund) und das PDF (weißes Papier)
    mark(512, 220, WHITE).save(os.path.join(ROOT, "assets/brand/logo_mark_white.png"))
    mark(512, 220, BLUE).save(os.path.join(ROOT, "assets/brand/logo_mark_color.png"))

    # SVG-Symbol (für Design-Vorschau, Website)
    with open(os.path.join(ROOT, "docs/brand/werkcalc_mark.svg"), "w", encoding="utf-8") as f:
        f.write(svg_mark())

    # Play-Store-Icon 512
    icon.resize((512, 512), Image.LANCZOS).convert("RGB").save(
        os.path.join(ROOT, "docs/store/icon_512.png"))

    # Logo mit Schriftzug: hell auf Blau und dunkel auf Weiß
    for name, bg, werk, nut in (("on_blue", BLUE, WHITE, WHITE), ("on_white", WHITE, BLUE, BLUE)):
        im = Image.new("RGB", (1200, 400), bg)
        im.paste(mark(300, 120, nut), (60, 50), mark(300, 120, nut))
        d = ImageDraw.Draw(im)
        right = wordmark(d, 400, 100, 130, werk)
        d.text((404, 250), "Handwerker Rechner", font=font_regular(54), fill=(190, 205, 230) if bg == BLUE else (90, 100, 120))
        im.save(os.path.join(ROOT, f"docs/brand/werkcalc_logo_{name}.png"))

    # Feature Graphic 1024 x 500
    fg = Image.new("RGB", (1024, 500), BLUE)
    dd = ImageDraw.Draw(fg)
    for y in range(500):
        t = y / 499
        dd.line([(0, y), (1024, y)], fill=tuple(int(BLUE[i] + (DARK[i] - BLUE[i]) * t) for i in range(3)))
    m = mark(360, 150, WHITE)
    fg.paste(m, (40, 70), m)
    wordmark(dd, 400, 140, 100, WHITE)
    dd.text((406, 262), "Handwerker Rechner", font=font_regular(42), fill=(220, 230, 245))
    dd.text((406, 330), "Rechner und PDF-Angebot für Heizung,", font=font_regular(26), fill=(190, 205, 230))
    dd.text((406, 366), "Sanitär, Klima, Elektro und Bau", font=font_regular(26), fill=(190, 205, 230))
    fg.save(os.path.join(ROOT, "docs/store/feature_graphic_1024x500.png"))
    print("WerkCalc-Branding erzeugt.")


if __name__ == "__main__":
    main()
