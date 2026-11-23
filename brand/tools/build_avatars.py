#!/usr/bin/env python3
"""Renders the profile avatars (assets/avatars/avatar_<n>.png) in the Market Mate style:
flat shapes, brand colours from tokens.json, a market accessory per person.

    python3 brand/tools/build_avatars.py [out_dir]

Needs Pillow. Each avatar is a 512 px square (the app crops it to a circle), drawn at
4x and scaled down for clean edges. Keep the file names: profiles store the asset path,
so existing users get the new picture with the same number.
"""
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SIZE = 512
S = 4  # supersampling
W = SIZE * S


def tokens():
    data = json.loads((ROOT / 'brand/tokens/tokens.json').read_text())['color']
    flat = {}

    def walk(d, prefix=''):
        for k, v in d.items():
            if isinstance(v, dict) and '$value' in v:
                flat[prefix + k] = v['$value']
            elif isinstance(v, dict):
                walk(v, prefix + k + '.')

    walk(data)
    return flat


T = tokens()
WHITE = T['neutral.white']
INK = T['neutral.ink']

# Skin and hair tones are illustration colours, not UI colours.
SKIN = ['#F6D3B3', '#E9B98F', '#C98D62', '#9C6644', '#6E4630', '#F1C7A0']
HAIR = {'dark': '#2B2B2B', 'brown': '#5A3A22', 'blond': '#D9A441', 'red': '#A0461C', 'grey': '#BDB7AE'}


def u(v):
    """Design units (0–100) to pixels."""
    return v * W / 100


def ell(d, cx, cy, rx, ry, fill):
    d.ellipse([u(cx - rx), u(cy - ry), u(cx + rx), u(cy + ry)], fill=fill)


def rect(d, x0, y0, x1, y1, fill, r=0):
    d.rounded_rectangle([u(x0), u(y0), u(x1), u(y1)], radius=u(r), fill=fill)


def poly(d, pts, fill):
    d.polygon([(u(x), u(y)) for x, y in pts], fill=fill)


def face(d, skin, smile=True, glasses=False, blush=True):
    # neck and ears
    rect(d, 43, 62, 57, 80, skin, 3)
    ell(d, 29, 50, 4.5, 6, skin)
    ell(d, 71, 50, 4.5, 6, skin)
    ell(d, 50, 48, 21, 23, skin)
    # eyes
    ell(d, 42, 49, 2.3, 2.8, INK)
    ell(d, 58, 49, 2.3, 2.8, INK)
    if blush:
        ell(d, 37, 57, 3.5, 2, '#F28B82')
        ell(d, 63, 57, 3.5, 2, '#F28B82')
    if smile:
        d.arc([u(42), u(52), u(58), u(63)], 20, 160, fill=INK, width=int(u(1.6)))
    if glasses:
        for cx in (42, 58):
            d.ellipse([u(cx - 6), u(49 - 5.5), u(cx + 6), u(49 + 5.5)], outline=INK, width=int(u(1.4)))
        d.line([u(48), u(48.5), u(52), u(48.5)], fill=INK, width=int(u(1.4)))


def body(d, color):
    ell(d, 50, 104, 36, 30, color)


def scarf(d, color, stripe):
    rect(d, 33, 68, 67, 78, color, 5)
    rect(d, 56, 72, 64, 96, color, 3)
    for y in (77, 84, 91):
        rect(d, 56, y, 64, y + 2.5, stripe)


def hair_short(d, c):
    d.chord([u(28), u(23), u(72), u(63)], 180, 360, fill=c)
    ell(d, 40, 30, 12, 6, c)


def hair_long(d, c):
    rect(d, 26, 38, 74, 74, c, 10)
    d.chord([u(27), u(23), u(73), u(65)], 180, 360, fill=c)


def hair_bun(d, c):
    ell(d, 50, 21, 8, 7, c)
    d.chord([u(28), u(25), u(72), u(63)], 180, 360, fill=c)


def hair_curly(d, c):
    for cx, cy in [(32, 38), (38, 29), (47, 25), (56, 26), (64, 31), (69, 39), (30, 47), (70, 47)]:
        ell(d, cx, cy, 8, 8, c)


def beanie(d, color, cuff, pom):
    d.chord([u(27), u(16), u(73), u(62)], 180, 360, fill=color)
    rect(d, 26, 33, 74, 41, cuff, 3)
    ell(d, 50, 15, 6, 6, pom)


def earmuffs(d, color):
    d.arc([u(27), u(24), u(73), u(70)], 180, 360, fill=color, width=int(u(3)))
    ell(d, 28, 50, 6, 7.5, color)
    ell(d, 72, 50, 6, 7.5, color)


def sunhat(d, color, band):
    ell(d, 50, 33, 34, 7, color)
    d.chord([u(34), u(14), u(66), u(46)], 180, 360, fill=color)
    rect(d, 34.5, 27, 65.5, 31, band)


def beard(d, c):
    d.chord([u(30), u(40), u(70), u(72)], 0, 180, fill=c)
    # moustache
    ell(d, 45, 55.5, 5, 2.2, c)
    ell(d, 55, 55.5, 5, 2.2, c)


# number → (background, skin, draw fn)
def avatar(n):
    bg = {
        1: T['brand.red'], 2: T['season.spring'], 3: T['brand.gold'], 4: T['category.stage'],
        5: T['category.food_sweet'], 6: T['season.summer'], 7: T['category.food_savory'], 8: T['category.kids'],
        9: T['season.autumn'], 10: T['brand.green'], 11: T['category.service'], 12: T['brand.red'],
    }[n]
    img = Image.new('RGB', (W, W), bg)
    d = ImageDraw.Draw(img)
    # light disc behind the person, like the stand markers' white ring
    ell(d, 50, 50, 44, 44, WHITE)
    ell(d, 50, 50, 41, 41, bg)

    def person(skin, hair_fn, hair_c, top, extra=None, **face_kw):
        if hair_fn is hair_long:
            hair_fn(d, hair_c)
        body(d, top)
        face(d, skin, **face_kw)
        if hair_fn is not hair_long and hair_fn is not None:
            hair_fn(d, hair_c)
        elif hair_fn is hair_long:
            d.chord([u(27), u(23), u(73), u(65)], 180, 360, fill=hair_c)
        if extra:
            extra()

    if n == 1:
        person(SKIN[0], hair_long, HAIR['blond'], INK,
               lambda: (beanie(d, WHITE, T['brand.red-dark'], WHITE), scarf(d, T['brand.gold'], WHITE)))
    elif n == 2:
        person(SKIN[3], hair_short, HAIR['dark'], T['brand.red'], lambda: scarf(d, WHITE, T['brand.red']))
    elif n == 3:
        person(SKIN[1], hair_bun, HAIR['brown'], T['category.stage'], glasses=True)
    elif n == 4:
        person(SKIN[4], hair_curly, HAIR['dark'], T['brand.gold'], lambda: earmuffs(d, T['brand.red']))
    elif n == 5:
        person(SKIN[2], hair_long, HAIR['dark'], T['season.summer'],
               lambda: sunhat(d, T['brand.gold-soft'], T['brand.red']))
    elif n == 6:
        person(SKIN[0], hair_short, HAIR['red'], T['brand.gold'], lambda: (beard(d, HAIR['red']), face_fix(d, SKIN[0])))
    elif n == 7:
        person(SKIN[5], None, None, T['brand.green'],
               lambda: (beanie(d, T['brand.red'], WHITE, WHITE), scarf(d, T['brand.green'], WHITE)), glasses=True)
    elif n == 8:
        person(SKIN[3], hair_bun, HAIR['dark'], T['brand.red'], lambda: scarf(d, T['brand.gold'], T['brand.red']))
    elif n == 9:
        person(SKIN[1], hair_short, HAIR['grey'], T['season.spring'],
               lambda: (beard(d, HAIR['grey']), face_fix(d, SKIN[1])), glasses=True)
    elif n == 10:
        person(SKIN[2], hair_curly, HAIR['brown'], T['category.kids'],
               lambda: beanie(d, T['brand.gold'], T['brand.red'], T['brand.red']))
    elif n == 11:
        person(SKIN[4], hair_long, HAIR['dark'], T['brand.red'], lambda: earmuffs(d, WHITE))
    elif n == 12:
        person(SKIN[0], hair_short, HAIR['brown'], T['season.autumn'],
               lambda: (beanie(d, T['brand.green'], WHITE, T['brand.red']), scarf(d, T['brand.red'], WHITE)))
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def face_fix(d, skin):
    """Keeps the smile visible on top of a beard."""
    d.arc([u(43), u(52), u(57), u(62)], 20, 160, fill=INK, width=int(u(1.8)))


if __name__ == '__main__':
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'assets/avatars'
    out.mkdir(parents=True, exist_ok=True)
    for n in range(1, 13):
        avatar(n).save(out / f'avatar_{n}.png', optimize=True)
    print(f'wrote 12 avatars to {out}')
