---
name: brand
description: Market Mate / cellarworks corporate identity. Use whenever creating or changing anything public-facing or visual for Market Mate or cellarworks — website pages (website/), marketing copy, App Store texts and screenshots, social posts, flyers, emails, slides, app theming/colors/icons, logos, favicons or OG images — and whenever someone asks about brand colors, fonts, logo usage or tone of voice.
---

# Market Mate brand

The full guide is `brand/README.md` (German). Read the sections you need before producing anything
public. Visual overview: `brand/index.html`.

## Non-negotiables

- **Architecture:** Market Mate is the product brand in front. cellarworks (always lowercase) is the
  studio behind it — only as endorsement ("ein Projekt von cellarworks"), footer, imprint, store publisher.
- **Contact & domains:** public contact is `info@cellarworks.dev`; the product site is
  `https://marketmate.cellarworks.dev`, the studio site `https://cellarworks.dev`. Don't invent other
  addresses.
- **Logo:** use the files in `brand/logo/` as they are (pin with market-stall awning + "MARKET MATE"
  in Bebas Neue). Never redraw, recolor, stretch or re-typeset it. Light background →
  `market-mate-logo.svg`; dark/photo → `-on-dark`; tight space → `market-mate-mark.svg`;
  one colour → `-mono-*`. The old network-of-people logo in `assets/logos/` is retired.
- **Colors:** take them from `brand/tokens/tokens.json` (CSS: `website/tokens.css` vars like
  `var(--red)`; Flutter: `BrandColors.red` from `lib/theme/brand_tokens.dart`). No new hex values.
  Marktrot `#C62828` is primary, Kohle `#2B2B2B` text, Papier `#FBFAF8`/Sand `#F3EFE8` backgrounds,
  Lichtergold `#F9A825` only as a small accent and never with white text. Seasonal accents (`season-*`, e.g. `BrandColors.seasonSpring`) only for season banners, pills and icons. Category colors are for
  stand markers only.
- **Type:** headlines Bebas Neue, uppercase, weight 400 (never faux-bold, never body text); everything
  else Figtree. Fonts are self-hosted from `website/assets/fonts/` — never link Google Fonts or other
  third-party font/CDN hosts on the public website (GDPR, no cookie banner).
- **Voice:** German first. Visitors are addressed with **du** (warm, short, concrete: "Wo gibt's hier
  Crêpes?"). Organisers with **Sie** (friendly, benefit-led). No buzzwords like "smart" or
  "KI-gestützt" towards visitors. Proper typography: „…“, –, ’.
- **Shapes:** pill buttons (primary red fill, secondary 2px ink outline), white cards with 1px
  `--line` border and 14px radius, flat illustrations (paper ground, white streets, colored dots with
  white ring). No gradients, no heavy shadows.

## Changing the brand itself

Generated files must not be edited by hand. Edit the source, then regenerate:

```bash
pip install fonttools brotli
python3 brand/tools/build_tokens.py                         # tokens.json → tokens.css (brand + website) + brand_tokens.dart
python3 brand/tools/build_logos.py brand/fonts brand/logo   # logo SVGs
node brand/tools/export_png.js                              # PNGs, favicons, og-image (needs playwright)
```

Copy changed logos into `website/assets/` (see section 10 of the guide) and update `brand/README.md`
in the same change.

## Checklist before finishing public-facing work

- [ ] Logo file from `brand/logo/`, correct variant for the background, clear space respected
- [ ] Only token colors; text contrast ≥ 4.5:1 (no white on gold)
- [ ] Bebas Neue only for uppercase headlines; Figtree for the rest; fonts self-hosted
- [ ] du/Sie matches the audience; German typography
- [ ] Footer/imprint carries "ein Projekt von cellarworks" where appropriate
- [ ] Works at 390px width (header shows the mark only below 420px)
