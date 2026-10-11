# Markt aus Lageplan erstellen

Admins laden einen Lageplan (PNG/JPG/WebP) hoch. Claude erkennt alle Stände mit
Kategorie und Position sowie Orientierungspunkte (Kirchen, Plätze, Kreuzungen).
Die Orientierungspunkte werden über die Google Geocoding API verortet, daraus
berechnet die App, wo der Plan auf der echten Karte liegt. Danach zeigt die
Besucherkarte jeden Stand als Icon.

## Ablauf in der App

Admin-Menü → **Markt aus Lageplan erstellen**

1. **Lageplan** – optional zuerst die **Webadresse des Marktes** eintragen und *Infos laden*: Beschreibung, Zeitraum, Öffnungszeiten, Eintritt, Veranstalter und passende Bilder werden übernommen (Bilder werden in den eigenen Storage kopiert). Dann Name, Ort (z. B. „Marienplatz, München“), Zeitraum, Bild wählen → *Mit KI analysieren* (1–3 Minuten).
2. **Stände prüfen**: Punkte auf dem Plan antippen = bearbeiten, gedrückt halten und ziehen = verschieben, freie Stelle antippen = Stand hinzufügen. Gelber Rand = unsicher erkannt.
3. **Auf Karte ausrichten**: Der Plan liegt halbtransparent über dem Satellitenbild. Passt es nicht, *Punkt zuordnen*: Stelle auf dem Plan antippen, dann dieselbe Stelle auf der Karte. Zwei eigene Punkte ersetzen die automatischen, ab drei Punkten werden auch verzerrte, nicht maßstabsgetreue Pläne korrekt umgerechnet. Falsch erkannte Orientierungspunkte lassen sich per ✕ abwählen.
4. **Speichern**: legt Event, Stände und Kategorien in Firestore an.

## Einmalige Einrichtung

Voraussetzung: Firebase-Projekt im **Blaze-Tarif** (für Cloud Functions).

```bash
# Secrets für die Cloud Function
firebase functions:secrets:set ANTHROPIC_API_KEY          # Claude API Key
firebase functions:secrets:set GOOGLE_GEOCODING_API_KEY   # Google Cloud Key mit Geocoding API

cd functions && npm install && cd ..
firebase deploy --only functions,firestore:rules,storage
```

- Die Storage-Regeln lesen die Admin-Rolle aus Firestore. Beim ersten Deploy fragt Firebase, ob Storage auf Firestore zugreifen darf → bestätigen.
- Admin wird man über das Feld `role: "admin"` im eigenen Dokument in `profiles/{uid}` (in der Firebase-Konsole setzen).

## Plan lokal testen (ohne Firebase)

```bash
cd functions
ANTHROPIC_API_KEY=... GOOGLE_GEOCODING_API_KEY=... \
  npm run try-plan -- ./mein-plan.jpg "Marienplatz, München"
```

Gibt das erkannte JSON und die verorteten Orientierungspunkte aus.

## Webseite lokal testen

```bash
cd functions
ANTHROPIC_API_KEY=... npm run try-import -- https://www.example.org/weihnachtsmarkt
```

Seiten, die ihre Inhalte erst per JavaScript im Browser laden, liefern zu wenig Text – dann eine andere Unterseite des Marktes versuchen.

## Kosten

Eine Analyse ist ein einzelner Claude-Aufruf mit einem Bild (Claude Opus 5.5,
`effort: high`), je nach Plangröße grob 0,15–0,70 US-$ (überwiegend Ausgabe- und Denk-Tokens). Dazu kommen bis zu 13
Geocoding-Anfragen. Fällt nur beim Anlegen eines Marktes an.

## Technik

| Teil | Datei |
|---|---|
| Cloud Function `analyzeMarketPlan` (europe-west3) | `functions/src/index.ts` |
| Claude-Aufruf, Prompt, Ausgabe-Schema | `functions/src/analyze.ts`, `prompt.ts`, `schema.ts` |
| Geocoding der Orientierungspunkte | `functions/src/geocode.ts` |
| Import von der Webseite (`importEventFromUrl`) | `functions/src/importEventFunction.ts`, `eventImport.ts`, `webpage.ts` |
| Umrechnung Plan → GPS (Ähnlichkeits-/Affintransformation, Ausreißer-Filter) | `lib/features/market_builder/services/georeference.dart` |
| Assistent (3 Schritte) | `lib/features/market_builder/screens/market_builder_screen.dart` |
| Speichern in Firestore | `lib/features/market_builder/services/market_builder_service.dart` |

Gespeichert wird im bestehenden Format: `stands/{id}`, `events/{id}.stands[]`
mit `location` und `category`, Kategorien in `category/{key}`. Zusätzlich hält
`events/{id}.plan` Bild, Passpunkte und Overlay-Lage, damit der Plan später
erneut bearbeitet oder in der Besucherkarte eingeblendet werden kann.
