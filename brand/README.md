# Markenleitfaden – Market Mate & cellarworks

Diese Datei ist die verbindliche Referenz für alle öffentlichen Auftritte: Website, App, App Store,
Social Media, Flyer, E-Mails. Visuelle Übersicht zum Anschauen: [`brand/index.html`](index.html) im
Browser öffnen.

| Was | Wo |
|---|---|
| Logos (SVG, Quelle) | [`brand/logo/`](logo/) |
| Logos (PNG) | [`brand/logo/png/`](logo/png/) |
| Farben, Schriften, Radien (Quelle) | [`brand/tokens/tokens.json`](tokens/tokens.json) |
| … als CSS | [`brand/tokens/tokens.css`](tokens/tokens.css), Kopie in `website/tokens.css` |
| … als Flutter | [`lib/theme/brand_tokens.dart`](../lib/theme/brand_tokens.dart) |
| Schriften (woff2, OFL-Lizenz) | [`brand/fonts/`](fonts/) |
| Generatoren | [`brand/tools/`](tools/) |
| Claude-Skill | [`.claude/skills/brand/SKILL.md`](../.claude/skills/brand/SKILL.md) |

---

## 1. Markenarchitektur

```
cellarworks            ← Studio / Absender (cellarworks.dev)
└── Market Mate        ← Produkt, steht im Vordergrund
```

- **Market Mate** ist die Marke, die Besucher und Veranstalter sehen. Sie trägt Logo, Farben und Ton.
- **cellarworks** ist der Absender dahinter („ein Projekt von cellarworks“). Es tritt zurück: Footer,
  Impressum, App-Store-Anbieter, E-Mail-Signatur, die Studio-Seite auf cellarworks.dev.
  Künftige Produkte hängen sich genauso darunter und bekommen eigene Produktmarken.
- Schreibweise: **Market Mate** (zwei Wörter, beide groß). **cellarworks** immer klein, auch am Satzanfang.

**Domains:** `cellarworks.dev` = Studio-Seite, `marketmate.cellarworks.dev` = Produktseite
(der `website/`-Ordner, Firebase Hosting).

**E-Mail:** öffentliche Kontaktadresse ist `info@cellarworks.dev` (Website, Impressum, App Store,
Veranstalter-Anfragen). Wird später eine Trennung nötig, bekommt Market Mate eigene Adressen unter
`@marketmate.cellarworks.dev` (z. B. `support@` für App-Nutzer, `maerkte@` für Veranstalter).
Bis dahin keine weiteren Adressen veröffentlichen, damit nichts ins Leere läuft.

## 2. Markenkern

**Idee:** Der Markt fühlt sich klein an, wenn man weiß, wo alles ist – und wo die Freunde sind.

**Versprechen:** *Weniger suchen, mehr genießen.*

**Claims** (je nach Platz):
- „Dein Markt in der Hosentasche“ – Hauptclaim
- „Alle Stände auf einer Karte. Freunde inklusive.“ – Unterzeile
- „Vom Lageplan zur digitalen Marktkarte“ – für Veranstalter

**Werte**

| Wert | Heißt konkret |
|---|---|
| **Gesellig** | Es geht um den Abend mit Freunden, nicht um Technik. |
| **Orientierung** | Klar, schnell, auf einen Blick. Keine Fummelei mit Faltplänen. |
| **Warm** | Lichter, Holzhütten, Glühwein – Wärme in Farbe und Sprache. |
| **Unkompliziert** | Für Veranstalter: Lageplan hochladen, fertig. |

## 3. Sprache & Tonalität

- **Besucher: du.** Locker, warm, kurz. Konkrete Dinge statt Abstraktion („Crêpes“, „Kinderpunsch“,
  „Hütte 14“), nicht „gastronomische Angebote“.
- **Veranstalter: Sie.** Freundlich-professionell, nutzenorientiert (Zeit sparen, Besucher lenken).
- Deutsch zuerst. Typografische Zeichen: „…“, –, ’ (z. B. „gibt’s“).
- Headlines kurz und aktiv, maximal ~6 Wörter.
- Keine Technik-Buzzwords („KI-gestützt“, „smart“) in der Besucher-Ansprache. Für Veranstalter darf
  die automatische Erkennung erwähnt werden – als Nutzen, nicht als Feature.
- Emojis: in Social Media sparsam okay (🎄☕📍), auf Website und App nicht.

| ✅ So | ❌ Nicht so |
|---|---|
| Wo gibt’s hier Crêpes? | Finden Sie gastronomische Angebote in Ihrer Nähe. |
| Gründe ein Team und teile den Code. | Nutzen Sie unsere innovative Social-Funktion. |
| Laden Sie Ihren Lageplan hoch – den Rest erledigen wir. | Unsere KI-Lösung digitalisiert Ihr Event-Management. |

## 4. Logo

Das Zeichen ist ein **Karten-Pin mit Marktstand-Markise**: Hütte + Karte in einer Form. Die
goldenen Streifen stehen für Lichterketten und Wärme. Die Wortmarke ist die **Bebas Neue** in
Versalien – sie greift das bisherige Market-Mate-Logo auf.

| Datei | Einsatz |
|---|---|
| `market-mate-logo.svg` | **Standard**, horizontal, auf hellem Grund |
| `market-mate-logo-on-dark.svg` | horizontal, auf dunklem Grund oder Fotos |
| `market-mate-logo-stacked.svg` / `-on-dark` | gestapelt, für quadratische Flächen (Social, Flyer) |
| `market-mate-mark.svg` | nur Zeichen: wenig Platz, Karten-Marker, Avatar |
| `market-mate-app-icon.svg` / `-rounded` | App-Icon (eckig – die Stores maskieren selbst) |
| `favicon.svg` | Browser-Tab; ohne Streifen, bleibt bei 16 px lesbar |
| `*-mono-ink.svg` / `*-mono-white.svg` | einfarbig: Stempel, Gravur, Druck in einer Farbe |
| `cellarworks-logo.svg` / `-on-dark`, `cellarworks-mark.svg` | Studio-Absender |

**Schutzzone:** rundum mindestens die Breite der Markise (≈ ¼ der Zeichenhöhe) frei lassen.

**Mindestgrößen:** Logo horizontal 24 px Höhe (Druck 8 mm), Zeichen 16 px (Druck 5 mm).

**Nicht erlaubt:** Farben tauschen (z. B. goldener Pin), verzerren, drehen, Schatten/Verläufe/Outline
hinzufügen, Wortmarke in anderer Schrift setzen, das Rot-Zeichen auf rotem oder unruhigem Grund
platzieren (dann `mono-white` verwenden).

Das alte Netzwerk-Logo (`assets/logos/`) wird nicht mehr für öffentliche Auftritte verwendet.

## 5. Farben

**Markenfarben** – Verteilung ungefähr 60 % Papier/Sand · 30 % Kohle · 10 % Rot · Gold nur als Funke.

| Token | Hex | Name | Rolle | Kontrast |
|---|---|---|---|---|
| `red` | `#C62828` | Marktrot | Primär: Logo, Haupt-Buttons, Akzente | Weiß darauf 5,6 : 1 ✅ |
| `red-dark` | `#9E1F1F` | Marktrot dunkel | Hover, Links im Fließtext | auf Papier 7,5 : 1 ✅ |
| `gold` | `#F9A825` | Lichtergold | Akzent, Highlights, Markise | Kohle darauf 7,2 : 1 ✅ · **Weiß darauf ❌** |
| `green` | `#2E7D32` | Tannengrün | unterstützend (Erfolg, Handwerk) | Weiß darauf 5,1 : 1 ✅ |
| `ink` | `#2B2B2B` | Kohle | Text, dunkle Flächen | auf Papier 13,6 : 1 ✅ |
| `ink-soft` | `#5C5C5C` | Kohle hell | Sekundärtext | auf Papier 6,4 : 1 ✅ |
| `paper` | `#FBFAF8` | Papier | Seitenhintergrund | |
| `sand` | `#F3EFE8` | Sand | abgesetzte Sektionen | |
| `line` | `#E7E3DD` | Linie | Rahmen, Trennlinien | |
| `gold-soft` / `gold-ink` | `#FFF3D6` / `#8A5A00` | | Hinweise, „bald“-Badges | 5,4 : 1 ✅ |

**Dunkle Flächen** („Abendmarkt“): Hintergrund `dark-bg #1E1C1B`, Karten `dark-surface #2B2B2B`,
Text `dark-text #F3EFE8`, Sekundär `dark-text-soft #BDB7AE`, Links `dark-link #FF8A80`
(Marktrot ist als Textfarbe auf Dunkel zu schwach; als Fläche, z. B. Button, bleibt es Marktrot).

**Kategoriefarben** sind funktional (Kartenmarker in der App) und kein Teil der Markenpalette. Sie
gelten überall, wo Stände dargestellt werden – Website-Mockups eingeschlossen:

| Kategorie | Hex | | Kategorie | Hex |
|---|---|---|---|---|
| Glühwein & Heißgetränke | `#C62828` | | Für Kinder | `#6A1B9A` |
| Herzhaftes | `#EF6C00` | | Bühne & Programm | `#1565C0` |
| Süßes & Gebäck | `#AD1457` | | Service | `#455A64` |
| Handwerk & Geschenke | `#2E7D32` | | Sonstiges | `#6D4C41` |
| Weihnachtsdeko | `#F9A825` | | | |

Quelle in der App: `lib/features/market_builder/models/stand_categories.dart` – bei Änderungen beide
Stellen anpassen.

## 6. Typografie

| Rolle | Schrift | Einsatz |
|---|---|---|
| Display | **Bebas Neue** (400) | Headlines, Zahlen, Wortmarke. Immer VERSALIEN. Nie für Fließtext oder unter 20 px. |
| Text | **Figtree** (variabel 300–900) | Fließtext 400, Hervorhebung 600–700, Buttons 700, Eyebrows 700 mit 0,12 em Sperrung |

Beide unter SIL Open Font License, kostenlos auch kommerziell. **Immer selbst hosten**
(`website/assets/fonts/`), nie über Google Fonts einbinden – so fließen keine Daten an Dritte und
es braucht keinen Cookie-Banner. In Office/Canva: Bebas Neue und Figtree installieren, sonst
Fallback Arial Narrow / Arial.

**Skala Website:** H1 `clamp(2rem, 5.5vw, 3.8rem)`, H2 `clamp(1.8rem, 3.6vw, 2.5rem)`,
H3 1,25 rem Figtree 700, Lead 1,15 rem, Text 1 rem / Zeilenhöhe 1,6.

**App:** bleibt bei der Systemschrift (SF Pro / Roboto) – schneller, barrierefrei skalierend. Marke
kommt dort über Farbe und Icon. Bebas Neue optional für große Überschriften (Splash, Onboarding).

## 7. Formen & Elemente

- **Radien:** 8 px klein · 14 px Karten · 24 px große Flächen · Pill (999 px) für Buttons, Chips, Navigation.
- **Buttons:** Pill-Form, Figtree 700. Primär = Marktrot gefüllt; sekundär = Kohle-Outline 2 px;
  auf dunklem Grund weiß gefüllt mit Gold-Hover.
- **Karten:** weiß, 1 px `line`-Rahmen, 14 px Radius, keine oder nur sehr weiche Schatten.
- **Icons:** gefüllt bzw. 2,4 px Strich, abgerundete Enden, weiß auf farbiger 44-px-Kachel
  (Radius 12 px). In der App Material Icons (gleicher Stil).
- **Illustration:** flache Kartenansicht – Papier-Grund, weiße Straßen, farbige Punkte mit weißem
  Rand in Kategoriefarben, der Market-Mate-Pin als Highlight. Keine 3D-Effekte, keine Verläufe.

## 8. Bildsprache

- Echte Märkte am Abend: warmes Licht, Lichterketten, Holzhütten, Menschen in kleinen Gruppen.
- Unscharfer Vordergrund/Bokeh ist willkommen; Gesichter dürfen, müssen aber nicht erkennbar sein
  (Bildrechte!).
- Keine kühlen Stockfotos, keine Business-Situationen, keine übertriebenen Filter.
- Text auf Fotos nur mit dunkler Fläche darunter (`dark-bg` mit 60–80 % Deckkraft).

## 9. Anwendungen

| Kanal | Vorgaben |
|---|---|
| **Website** | `website/style.css` nutzt die Tokens. Header = Logo horizontal (unter 420 px nur Zeichen), Footer = „ein Projekt von cellarworks“. Social-Vorschau: `website/assets/og-image.png` (1200 × 630). |
| **App** | Seed-Farbe `BrandColors.red` (`lib/theme/brand_tokens.dart`). App-Icon aus `brand/logo/png/market-mate-app-icon-1024.png`. |
| **App Store** | Icon wie App. Screenshots auf Papier/Sand mit Bebas-Headline (max. 4 Wörter) über dem Gerät. Anbieter: cellarworks. |
| **Social Media** | Profilbild: App-Icon. Posts: Papier oder `dark-bg`, eine Headline in Bebas, ein Rot-Akzent. Logo gestapelt unten. |
| **E-Mail-Signatur** | Name · Market Mate · ein Projekt von cellarworks · info@cellarworks.dev · marketmate.cellarworks.dev – reiner Text, kein Bild. |
| **Druck** | Rot ≈ Pantone 1795 C, Gold ≈ Pantone 130 C – Näherungen, vor dem ersten Druck mit Proof abstimmen. |

## 10. Pflege

Alles Markenrelevante wird aus einer Quelle erzeugt – Dateien in `brand/logo/`,
`brand/tokens/tokens.css`, `website/tokens.css` und `lib/theme/brand_tokens.dart` nie von Hand ändern.

```bash
pip install fonttools brotli
python3 brand/tools/build_tokens.py                       # Farben/Schriften → CSS + Dart
python3 brand/tools/build_logos.py brand/fonts brand/logo # Logo-SVGs (Text in Pfade)
node brand/tools/export_png.js                            # PNGs, Website-Icons, og-image
cp brand/logo/{market-mate-logo,favicon,cellarworks-logo}.svg website/assets/ # bei Logo-Änderungen
cp brand/logo/market-mate-mark.svg website/assets/mark.svg
```

## 11. Offene Punkte

- `marketmate.cellarworks.dev` in Firebase Hosting als Custom Domain verbinden (sonst greifen
  `og:image` und Canonical-URLs noch nicht).
- App-Icon in der App austauschen: `flutter_launcher_icons.yaml` auf
  `brand/logo/png/market-mate-app-icon-1024.png` zeigen lassen und
  `dart run flutter_launcher_icons` ausführen.
- Studio-Seite für cellarworks.dev (nutzt dieselben Tokens, Logo `cellarworks-logo.svg`).
