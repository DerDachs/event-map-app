#!/usr/bin/env python3
"""Strips the alpha channel from the store screenshots (RGBA -> RGB).

App Store Connect rejects screenshots with alpha channels or transparency
(Apple, Screenshot specifications). Flutter's golden files are RGBA, so run
this after `flutter test tool/store_screenshots --update-goldens`:

    python3 tool/store_screenshots/flatten.py docs/app-store/screenshots

Transparent pixels (there should be none) are flattened onto white.
Needs Pillow: pip install pillow
"""
import sys
from pathlib import Path

from PIL import Image


def flatten(path: Path) -> bool:
    image = Image.open(path)
    if image.mode == "RGB":
        return False
    rgba = image.convert("RGBA")
    background = Image.new("RGB", rgba.size, (255, 255, 255))
    background.paste(rgba, mask=rgba.getchannel("A"))
    background.save(path, "PNG", optimize=True)
    return True


def main() -> int:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else "docs/app-store/screenshots")
    files = sorted(root.rglob("*.png"))
    if not files:
        print(f"No PNG files under {root}")
        return 1
    for file in files:
        size = Image.open(file).size
        changed = flatten(file)
        print(f"{'flattened' if changed else 'already RGB'}  {size[0]}x{size[1]}  {file}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
