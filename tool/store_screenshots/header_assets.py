#!/usr/bin/env python3
"""Draws the App Store creative assets (universal 16:9 asset, 5244 x 2950 px).

Apple crops the universal asset for the product page header (21:9) and for
search results (3:2); key artwork must stay inside the art safe area
(1402 x 962 px at x 1921, y 660). Output is RGB without alpha.

Usage: python3 tool/store_screenshots/header_assets.py docs/app-store/header
Needs Pillow and rsvg-convert. Colours come from brand/tokens (BrandColors).
"""
import io
import math
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

W, H = 5244, 2950
SAFE = (1921, 660, 1921 + 1402, 660 + 962)  # x0, y0, x1, y1

RED = "#C62828"
WHITE = "#FFFFFF"
GOLD = "#F9A825"
BG = "#1E1C1B"  # darkBg
SURFACE = "#2B2B2B"  # darkSurface
LINE = "#5C5C5C"  # inkSoft

ROOT = Path(__file__).resolve().parents[2]


def svg(name, width=None, height=None):
    cmd = ["rsvg-convert", "-f", "png"]
    if width:
        cmd += ["-w", str(width)]
    if height:
        cmd += ["-h", str(height)]
    cmd.append(str(ROOT / "brand/logo" / name))
    return Image.open(io.BytesIO(subprocess.run(cmd, check=True, capture_output=True).stdout)).convert("RGBA")


def awning(draw, x0, x1, top, stripe, band):
    count = round((x1 - x0) / stripe)
    w = (x1 - x0) / count
    for i in range(count):
        c = RED if i % 2 == 0 else WHITE
        a = x0 + i * w
        draw.rectangle([a, top, a + w + 1, top + band], fill=c)
        draw.pieslice([a, top + band - w / 2, a + w + 1, top + band + w / 2], 0, 180, fill=c)


def lights(img, y_edge, sag, count, seed):
    """A string of lights hanging between two points, with a soft glow."""
    glow = Image.new("RGB", (W, H), (0, 0, 0))
    gd = ImageDraw.Draw(glow)
    d = ImageDraw.Draw(img)
    pts = [(x, y_edge + sag * math.sin(math.pi * x / W) ** 2) for x in range(0, W + 1, 12)]
    d.line(pts, fill=LINE, width=5)
    for i in range(1, count):
        x = W * i / count
        y = y_edge + sag * math.sin(math.pi * x / W) ** 2
        r = 21 if (i + seed) % 3 else 15
        gd.ellipse([x - r * 3, y + 20 - r * 3, x + r * 3, y + 20 + r * 3], fill=(120, 80, 10))
        d.line([(x, y), (x, y + 14)], fill=LINE, width=5)
        d.ellipse([x - r, y + 14, x + r, y + 14 + 2 * r], fill=GOLD)
    glow = glow.filter(ImageFilter.GaussianBlur(38))
    return Image.composite(img, img, Image.new("L", (W, H), 255)), glow


def add_glow(img, glow):
    px, gx = img.load(), glow.load()
    out = Image.new("RGB", img.size)
    ox = out.load()
    for y in range(H):
        for x in range(W):
            r, g, b = px[x, y]
            gr, gg, gb = gx[x, y]
            ox[x, y] = (min(255, r + gr), min(255, g + gg), min(255, b + gb))
    return out


def stall(draw, x, ground, w, h, lit):
    draw.rectangle([x, ground - h, x + w, ground], fill=SURFACE)
    awning(draw, x - 14, x + w + 14, ground - h - 40, (w + 28) / 5, 70)
    pad = w * 0.12
    draw.rectangle([x + pad, ground - h * 0.62, x + w - pad, ground - h * 0.28], fill=GOLD if lit else LINE)
    draw.rectangle([x, ground - h * 0.2, x + w, ground - h * 0.2 + 18], fill=BG)


def paste_center(img, logo, cx, cy):
    img.paste(logo, (round(cx - logo.width / 2), round(cy - logo.height / 2)), logo)


def compose(variant):
    # The header is cropped to 21:9 (y 351 to 2599), search results to 3:2
    # (x 409 to 4835): keep everything that matters inside the respective crop.
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)
    if variant == "header":
        awning_top, lights_y, ground = 380, 700, 2490
        logo = svg("market-mate-logo-on-dark.svg", width=1340)
        cy = (SAFE[1] + SAFE[3]) / 2 + 40
    else:
        awning_top, lights_y, ground = 0, 330, H - 90
        logo = svg("market-mate-logo-stacked-on-dark.svg", height=860)
        cy = (SAFE[1] + SAFE[3]) / 2 + 40
    awning(d, 0, W, awning_top, W / 20, 100)
    img_l, glow = lights(img, lights_y, 150, 36, 0 if variant == "header" else 1)
    d = ImageDraw.Draw(img_l)
    sizes = [(520, 560), (460, 480), (560, 600), (480, 520), (520, 560)]
    gap = 150
    total = sum(s[0] for s in sizes) + gap * (len(sizes) - 1)
    x = (W - total) / 2
    for i, (w, h) in enumerate(sizes):
        stall(d, x, ground, w, h, lit=i % 2 == 0)
        x += w + gap
    d.rectangle([0, ground, W, H if variant == "search" else ground + 110], fill=SURFACE)
    paste_center(img_l, logo, (SAFE[0] + SAFE[2]) / 2, cy)
    out = add_glow(img_l, glow)
    # the logo must stay inside the art safe area
    assert logo.width <= SAFE[2] - SAFE[0] and logo.height <= SAFE[3] - SAFE[1], "logo exceeds safe area"
    return out


def guide(img, name):
    g = img.copy()
    d = ImageDraw.Draw(g)
    d.rectangle(SAFE, outline="#00FFFF", width=8)
    top = (H - W * 1646 // 3840) // 2  # centre crop 21:9
    d.rectangle([0, top, W, H - top], outline="#FF00FF", width=8)
    left = (W - H * 3 // 2) // 2  # centre crop 3:2
    d.rectangle([left, 0, W - left, H], outline="#FFFF00", width=8)
    g.resize((W // 4, H // 4)).save(name)


def main():
    out = Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    for variant, file in (("header", "kopfzeile-5244x2950.png"), ("search", "suchergebnisse-5244x2950.png")):
        img = compose(variant)
        assert img.size == (W, H) and img.mode == "RGB"
        img.save(out / file, optimize=True)
        guide(img, f"/tmp/guide-{variant}.png")
        print(file, img.size, img.mode)


if __name__ == "__main__":
    main()
