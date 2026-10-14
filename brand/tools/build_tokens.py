"""Generates brand/tokens/tokens.css, website/tokens.css and lib/theme/brand_tokens.dart from brand/tokens/tokens.json.

    python3 brand/tools/build_tokens.py
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
tokens = json.loads((ROOT / "brand/tokens/tokens.json").read_text())


def leaves(node, path=()):
    for key, value in node.items():
        if key.startswith("$"):
            continue
        if "$value" in value:
            yield path + (key,), value
        else:
            yield from leaves(value, path + (key,))


def css_value(value):
    v = value["$value"]
    if isinstance(v, list):
        return ", ".join(f'"{f}"' if " " in f else f for f in v)
    return v


# ---- CSS custom properties ----
css = ["/* Generated from brand/tokens/tokens.json by brand/tools/build_tokens.py. Do not edit. */", ":root {"]
for section in ("color", "font", "radius", "space"):
    for path, value in leaves(tokens[section]):
        name = "-".join(path).replace("_", "-")
        prefix = "" if section == "color" else f"{section}-"
        if section == "color" and path[0] in ("brand", "neutral"):
            name = "-".join(path[1:])          # --red, --ink, --paper …
        css.append(f"  --{prefix}{name}: {css_value(value)};")
css.append("}")
for target in ("brand/tokens/tokens.css", "website/tokens.css"):
    (ROOT / target).write_text("\n".join(css) + "\n")


# ---- Flutter ----
def camel(parts):
    words = "-".join(parts).replace("_", "-").split("-")
    return words[0] + "".join(w.capitalize() for w in words[1:])


dart = [
    "// Generated from brand/tokens/tokens.json by brand/tools/build_tokens.py. Do not edit.",
    "import 'package:flutter/material.dart';",
    "",
    "/// Market Mate brand colours. See brand/README.md for when to use which.",
    "abstract final class BrandColors {",
]
for group in ("brand", "neutral", "dark", "season"):
    for path, value in leaves(tokens["color"][group]):
        name = camel(path if group in ("brand", "neutral") else (group,) + path)
        hexv = value["$value"].lstrip("#").upper()
        dart.append(f"  /// {value.get('$description', '')}".rstrip())
        dart.append(f"  static const {name} = Color(0xFF{hexv});")
dart.append("}")
out = ROOT / "lib/theme/brand_tokens.dart"
out.parent.mkdir(exist_ok=True)
out.write_text("\n".join(dart) + "\n")
print("wrote brand/tokens/tokens.css, website/tokens.css and", out.relative_to(ROOT))
