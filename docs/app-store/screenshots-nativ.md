# Screenshots vom echten iPhone

Die Pipeline rahmt Geräte-Screenshots mit der Headline, genau wie die gerenderten. Du brauchst nur die
Rohbilder. Sobald eine Datei in `tool/store_screenshots/raw/<de|en>/` liegt, nimmt der Test sie anstelle des
nachgebauten Bildschirms.

## Vorbereitung (einmal)

1. Build mit dem aktuellen `main` (enthält Beispielmarkt und neues Design) per TestFlight oder Xcode installieren.
2. Als Admin einloggen: **Admin → Beispielmarkt anlegen**. Danach mit dem Demo-Konto (kein Admin) einloggen.
3. Gerät: ein Pro-Max-iPhone liefert 1320 × 2868 (iPhone 16 und 17 Pro Max) bzw. 1290 × 2796 (15 Pro Max). Beides ist erlaubt.
   Im Simulator: iPhone 17 Pro Max.

Für den Simulator (saubere Statusleiste und Standort auf dem Markt):

```bash
xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
xcrun simctl location booted set 51.3127,9.4797
xcrun simctl io booted screenshot --type=png ~/Desktop/01_home.png
```

Am iPhone: Seitentaste und Lauter gleichzeitig drücken, Bilder per AirDrop an den Mac.

## Bilder aufnehmen (Reihenfolge wie im Store)

| Datei | Was auf dem Bild sein soll |
|---|---|
| `01_home.png` | Startseite, Beispielmarkt „Lichterdorf Musterstadt“ als Hervorhebung, Saison-Banner mit Countdown |
| `02_map.png` | Marktkarte des Beispielmarkts, Suche „Crêpes“, Stand „Zuckerhäuschen“ markiert |
| `03_info.png` | Tab „Info“ des Beispielmarkts (Öffnungszeiten, Eintritt, Veranstalter, Tipp) |
| `04_team.png` | Tab „Team“ mit einem Team und zwei, drei Mitgliedern |
| `05_seasons.png` | Startseite zu einer anderen Saison (Gerätedatum oder Beispielsaison), zeigt den Wechsel der Themen |

Je einmal auf Deutsch und einmal auf Englisch. Die Sprache stellst du in der App unter **Einstellungen** um.
Die Bilder in `tool/store_screenshots/raw/de/` und `…/en/` ablegen.

## Einrahmen und prüfen

```bash
flutter test tool/store_screenshots --update-goldens
python3 tool/store_screenshots/flatten.py docs/app-store/screenshots
```

Der zweite Schritt entfernt den Alphakanal. Apple lehnt Screenshots damit ab (Quelle in
`app-store-texte.md`). Das Skript meldet die Größe jeder Datei; erwartet sind 1320 × 2868.

Hinweis: Die Bilder unter `docs/app-store/screenshots/` zeigen noch das alte Design. Sie werden erst beim nächsten
Lauf des Befehls oben neu gerendert.
