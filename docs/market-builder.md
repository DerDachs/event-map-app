# Markt aus Lageplan erstellen

Admins laden einen Lageplan hoch – als Bild (PNG/JPG/WebP) oder PDF. Claude erkennt alle Stände mit
Kategorie und Position sowie Orientierungspunkte (Kirchen, Plätze, Kreuzungen).
Die Orientierungspunkte werden über die Google Geocoding API verortet, daraus
berechnet die App, wo der Plan auf der echten Karte liegt. Danach zeigt die
Besucherkarte jeden Stand als Icon.

## Ablauf in der App

Admin-Menü → **Markt aus Lageplan erstellen**

1. **Lageplan** – optional zuerst die **Webadresse des Marktes** eintragen und *Infos laden*: Beschreibung, Zeitraum, Öffnungszeiten, Eintritt, Veranstalter und passende Bilder werden übernommen (Bilder werden in den eigenen Storage kopiert). Dann Name, Ort (z. B. „Marienplatz, München“), Zeitraum, Bild wählen → *Mit KI analysieren* (1–3 Minuten).
2. **Stände prüfen**: Punkte auf dem Plan antippen = bearbeiten (Name, Kategorie, Beschreibung, Angebot, Aktion – alles, was Besucher sehen), gedrückt halten und ziehen = verschieben, freie Stelle antippen = Stand hinzufügen. Gelber Rand = unsicher erkannt.
   - *Standliste importieren*: Namen, Beschreibungen, Angebote und Aktionen aus einer Aussteller-/Standliste übernehmen – als eingefügter Text, Foto/PDF oder Webseite. Die Cloud Function `parseStandList` liest die Liste mit Claude, die App ordnet über Standnummer, dann Namen zu; nicht zugeordnete Einträge lassen sich von Hand einem Stand zuweisen. Gibt es auch in „Markt bearbeiten“.
3. **Auf Karte ausrichten**: Der Plan liegt halbtransparent über dem Satellitenbild.
   - *Punkt zuordnen*: Stelle auf dem Plan antippen, dann dieselbe Stelle auf der Karte. Zwei eigene Punkte ersetzen die automatischen. Der Plan wird dabei nur verschoben, gedreht und gleichmäßig skaliert – nie gestaucht oder geschert. Erst ab **vier gut verteilten** Punkten darf er leicht entzerrt werden (höchstens 1,6-fach gestreckt, höchstens 15° schief), sonst bleibt es bei der unverzerrten Lösung.
   - *Feinjustieren*: Plan als Ganzes in 1-m-, 1°- und 2-%-Schritten verschieben, drehen, vergrößern.
   - *Rückgängig* nimmt jeden Schritt zurück, *Zurücksetzen* kehrt zur automatischen Platzierung zurück.
   - Stände lassen sich auch hier antippen (bearbeiten) und auf der Karte ziehen; ihre Position auf dem Plan wandert mit.
   - Falsch erkannte Orientierungspunkte lassen sich per ✕ abwählen.
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

### PDF-Pläne

Die App rendert die gewählte PDF-Seite zu einem Bild (Grundlage für Positionen, Prüfansicht und
Karten-Overlay) und lädt zusätzlich das Original-PDF hoch. Claude bekommt beides: aus dem PDF liest
es Beschriftungen und Legende exakt (auch von anderen Seiten), die Koordinaten kommen aus dem Bild.
Lokal: `PLAN_PDF=./plan.pdf PLAN_PDF_PAGE=1 npm run try-plan -- ./plan-seite1.jpg "Ort"`.

**Interaktive Pläne** (Web-Karten): Screenshot machen und als Bild hochladen.

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
| Umrechnung Plan → GPS (Ähnlichkeitstransformation, Affin nur bei ≥ 4 plausiblen Punkten, Ausreißer-Filter, Feinjustierung; gespeichert als `plan.transform`) | `lib/features/market_builder/services/georeference.dart` |
| Assistent (3 Schritte) | `lib/features/market_builder/screens/market_builder_screen.dart` |
| Speichern in Firestore | `lib/features/market_builder/services/market_builder_service.dart` |

Gespeichert wird im bestehenden Format: `stands/{id}`, `events/{id}.stands[]`
mit `location` und `category`, Kategorien in `category/{key}`. Zusätzlich hält
`events/{id}.plan` Bild, Passpunkte und Overlay-Lage, damit der Plan später
erneut bearbeitet oder in der Besucherkarte eingeblendet werden kann.
