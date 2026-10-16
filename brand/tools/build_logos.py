"""Generates the Market Mate and cellarworks logo SVGs into brand/logo/.

Text is converted to outlines, so the SVGs need no fonts. Edit the shapes
here, never the generated files by hand.

    pip install fonttools brotli
    python3 brand/tools/build_logos.py brand/fonts brand/logo
    node brand/tools/export_png.js          # PNG exports + website icons
"""
import os, sys
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.boundsPen import BoundsPen

FONTS = sys.argv[1]; OUT = sys.argv[2]
os.makedirs(OUT, exist_ok=True)
BEBAS = f"{FONTS}/bebas-neue-latin-400-normal.woff2"
FIGTREE = f"{FONTS}/figtree-latin-wght-normal.woff2"

RED, RED_DARK, GOLD, INK, PAPER, WHITE = "#C62828", "#9E1F1F", "#F9A825", "#2B2B2B", "#FBFAF8", "#FFFFFF"

def num(v):
    s = f"{v:.2f}".rstrip("0").rstrip(".")
    return "0" if s == "-0" else s

_cache = {}
def font(path, wght=None):
    key = (path, wght)
    if key not in _cache:
        f = TTFont(path)
        if wght is not None and "fvar" in f:
            from fontTools.varLib.instancer import instantiateVariableFont
            f = instantiateVariableFont(f, {"wght": wght})
        _cache[key] = f
    return _cache[key]

def text_path(path, text, size, x0=0, y0=0, tracking=0.0, wght=None):
    """Returns (svg path d, advance width) for text with baseline at y0."""
    f = font(path, wght)
    s = size / f["head"].unitsPerEm
    cmap, gs, hmtx = f.getBestCmap(), f.getGlyphSet(), f["hmtx"]
    x = x0; parts = []
    for ch in text:
        g = cmap[ord(ch)]
        pen = SVGPathPen(gs, ntos=num)
        gs[g].draw(TransformPen(pen, (s, 0, 0, -s, x, y0)))
        if pen.getCommands():
            parts.append(pen.getCommands())
        x += hmtx[g][0] * s + tracking * size
    return " ".join(parts), x - x0 - tracking * size

def ink_bounds(path, text, size, tracking=0.0, wght=None):
    f = font(path, wght)
    s = size / f["head"].unitsPerEm
    cmap, gs, hmtx = f.getBestCmap(), f.getGlyphSet(), f["hmtx"]
    x = 0; xmin = None; xmax = None
    for ch in text:
        g = cmap[ord(ch)]
        bp = BoundsPen(gs); gs[g].draw(bp)
        if bp.bounds:
            a, _, b, _ = bp.bounds
            xmin = x + a * s if xmin is None else xmin
            xmax = x + b * s
        x += hmtx[g][0] * s + tracking * size
    return xmin, xmax

# ---- The mark: a map pin with a market-stall awning (64 x 64 grid) ----
PIN = "M33.6 60.1Q32 62 30.4 60.1L14.31 40.7A23 23 0 1 1 49.69 40.7Z"
AWNING = ("M22 13H42L46 23" + "a2.8 2.8 0 0 1-5.6 0" * 5 + "Z")
STRIPES = "M26 13h4l-1.2 10h-5.6zM34 13h4l2.4 10h-5.6z"
COUNTER = "M22.5 29h19a2.5 2.5 0 0 1 0 5h-19a2.5 2.5 0 0 1 0-5z"

def mark(pin=RED, cut=WHITE, stripes=GOLD, dx=0, dy=0, s=1.0):
    t = f' transform="translate({num(dx)} {num(dy)}) scale({num(s)})"' if (dx or dy or s != 1) else ""
    g = [f'<path fill="{pin}" d="{PIN}"/>', f'<path fill="{cut}" d="{AWNING}"/>']
    if stripes:
        g.append(f'<path fill="{stripes}" d="{STRIPES}"/>')
    g.append(f'<path fill="{cut}" d="{COUNTER}"/>')
    return f'<g{t}>' + "".join(g) + "</g>"

def mark_mono(color, dx=0, dy=0, s=1.0):
    t = f' transform="translate({num(dx)} {num(dy)}) scale({num(s)})"' if (dx or dy or s != 1) else ""
    return f'<path{t} fill="{color}" fill-rule="evenodd" d="{PIN}{AWNING}{COUNTER}"/>'

def svg(w, h, body, title):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {num(w)} {num(h)}" '
            f'width="{num(w)}" height="{num(h)}" role="img" aria-label="{title}"><title>{title}</title>{body}</svg>\n')

def write(name, content):
    with open(f"{OUT}/{name}", "w") as fh:
        fh.write(content)

# Mark extents in the 64 grid: x 9..55, y 3..62
MX0, MX1, MY0, MY1 = 9, 55, 3, 62

# ---- Mark only ----
write("market-mate-mark.svg", svg(64, 64, mark(), "Market Mate"))   # works on light and dark
write("market-mate-mark-mono-ink.svg", svg(64, 64, mark_mono(INK), "Market Mate"))
write("market-mate-mark-mono-white.svg", svg(64, 64, mark_mono(WHITE), "Market Mate"))

# ---- Horizontal lockup: mark + MARKET MATE on one line ----
WM = "MARKET MATE"; TRACK = 0.02
def horizontal(text_color, mono=None):
    H = 64; size = 40; cap = 0.7 * size              # Bebas cap height = 0.7 em
    baseline = 26 + cap / 2                          # centre caps on the pin head
    gap = 10
    xmin, _ = ink_bounds(BEBAS, WM, size, TRACK)
    x0 = MX1 + gap - xmin
    d, w = text_path(BEBAS, WM, size, x0, baseline, TRACK)
    _, xmax = ink_bounds(BEBAS, WM, size, TRACK)
    W = x0 + xmax + MX0                              # right padding = left padding of the pin
    m = mark_mono(mono) if mono else mark()
    return svg(W, H, m + f'<path fill="{text_color}" d="{d}"/>', "Market Mate")

write("market-mate-logo.svg", horizontal(INK))
write("market-mate-logo-on-dark.svg", horizontal(PAPER))
write("market-mate-logo-mono-ink.svg", horizontal(INK, INK))
write("market-mate-logo-mono-white.svg", horizontal(WHITE, WHITE))

# ---- Stacked lockup: mark above wordmark ----
def stacked(text_color):
    size = 30; cap = 0.7 * size
    xmin, xmax = ink_bounds(BEBAS, WM, size, TRACK)
    tw = xmax - xmin
    W = max(tw, 46) + 16
    mark_s = 1.0
    mdx = (W - 64) / 2
    baseline = 62 + 10 + cap
    d, _ = text_path(BEBAS, WM, size, (W - tw) / 2 - xmin, baseline, TRACK)
    H = baseline + 6
    return svg(W, H, mark(dx=mdx) + f'<path fill="{text_color}" d="{d}"/>', "Market Mate")

write("market-mate-logo-stacked.svg", stacked(INK))
write("market-mate-logo-stacked-on-dark.svg", stacked(PAPER))

# ---- App icon (1024 master on a 64 grid): red tile, white pin ----
def app_icon(rounded):
    rx = ' rx="14"' if rounded else ""
    body = (f'<rect width="64" height="64"{rx} fill="{RED}"/>'
            + mark(pin=WHITE, cut=RED, stripes=GOLD, dx=32 - 32 * 0.78, dy=32 - 32.5 * 0.78, s=0.78))
    return svg(64, 64, body, "Market Mate")
write("market-mate-app-icon.svg", app_icon(False))      # stores apply their own mask
write("market-mate-app-icon-rounded.svg", app_icon(True))

# Android adaptive icon foreground: the white pin on transparent. The
# launcher icon generator adds the safe-zone inset, the red background is
# set in flutter_launcher_icons.yaml.
write("market-mate-app-icon-foreground.svg",
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">'
      + mark(pin=WHITE, cut=RED, stripes=GOLD, dx=32 - 32 * 0.78, dy=32 - 32.5 * 0.78, s=0.78) + '</svg>\n')

# ---- Favicon: mark tuned for tiny sizes (no stripes, slightly bolder cut-outs) ----
write("favicon.svg", svg(64, 64, mark(stripes=None), "Market Mate"))

# ---- cellarworks: the studio behind Market Mate ----
# Mark: a vaulted cellar door with warm light inside.
ARCH = "M6 58V32A26 26 0 0 1 58 32V58Z"
LIGHT = "M23 58V41a9 9 0 0 1 18 0V58Z"
def cw_mark(c=INK, light=GOLD, dx=0, dy=0, s=1.0):
    t = f' transform="translate({num(dx)} {num(dy)}) scale({num(s)})"' if (dx or dy or s != 1) else ""
    return f'<g{t}><path fill="{c}" d="{ARCH}"/><path fill="{light}" d="{LIGHT}"/></g>'
write("cellarworks-mark.svg", svg(64, 64, cw_mark(), "cellarworks"))
write("cellarworks-mark-on-dark.svg", svg(64, 64, cw_mark(c=PAPER), "cellarworks"))

def cw_logo(c, light=GOLD):
    size = 34; W8 = 650
    x_height = 0.5 * size
    xmin, xmax = ink_bounds(FIGTREE, "cellarworks", size, -0.01, W8)
    x0 = 58 + 12 - xmin
    d, _ = text_path(FIGTREE, "cellarworks", size, x0, 58, -0.01, W8)
    W = x0 + xmax + 6
    return svg(W, 64, cw_mark(c, light) + f'<path fill="{c}" d="{d}"/>', "cellarworks")
write("cellarworks-logo.svg", cw_logo(INK))
write("cellarworks-logo-on-dark.svg", cw_logo(PAPER))
print("ok")
