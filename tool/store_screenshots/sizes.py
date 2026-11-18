#!/usr/bin/env python3
"""Scales the 1320 x 2868 screenshots to the other iPhone sizes App Store Connect accepts.

The aspect ratios differ by less than 0.5 %, so scaling does not visibly distort.
Usage: python3 tool/store_screenshots/sizes.py docs/app-store/screenshots
Output: <dir>/<width>x<height>/<lang>/<name>.png (RGB, no alpha)
"""
import sys
from pathlib import Path

from PIL import Image

SIZES = [(1290, 2796), (1284, 2778), (1206, 2622), (1179, 2556)]


def main():
    root = Path(sys.argv[1])
    for src in sorted(root.glob("*/*.png")):
        if "x" in src.parent.parent.name:
            continue
        lang = src.parent.name
        im = Image.open(src).convert("RGB")
        assert im.size == (1320, 2868), f"{src}: {im.size}"
        for w, h in SIZES:
            out = root / f"{w}x{h}" / lang / src.name
            out.parent.mkdir(parents=True, exist_ok=True)
            im.resize((w, h), Image.LANCZOS).save(out, optimize=True)
    print("done")


if __name__ == "__main__":
    main()
