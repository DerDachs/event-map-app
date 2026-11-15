# Market Mate – Projektkontext

Kurzfassung für Claude (Claude Code lädt diese Datei automatisch; für ein Claude-Projekt auf
claude.ai als Projektwissen hochladen). Stand: November 2026.

## Ziel

**Market Mate** ist eine Flutter-App (iPhone zuerst, Android vorbereitet), die Besuchern alle Stände
eines Marktes auf einer Karte zeigt – vom Weihnachtsmarkt bis zum Weinfest – und Freunde über Teams
verbindet. Versprechen: *Weniger suchen, mehr genießen.*

- **Besucher** (geduzt): Märkte entdecken, Stände suchen/filtern, Favoriten, Teams mit Code,
  saisonale Startseite mit Countdown und Neuigkeiten.
- **Veranstalter** (gesiezt): Lageplan (Bild/PDF) hochladen → Claude erkennt Stände → digitale
  Marktkarte. Geschäftsmodell später: Veranstalter als zahlende Kunden.
- **cellarworks** (immer klein) ist das Studio dahinter (cellarworks.dev), Market Mate die
  Produktmarke vorne. Kontakt: `info@cellarworks.dev`, Produktseite `marketmate.cellarworks.dev`.

## Aktueller Stand

Fertig und auf `main`:
- Login (E-Mail, Apple), Profil mit Avatar, Konto löschen
- Märkte, Detailseite, Marktkarte (Google Maps, Kategorie-Marker, Suche, Filter, Lageplan-Overlay)
- Teams (gründen, per Code beitreten), Favoriten
- Startseite als Feed (`feed`) mit Saisons (`seasons`): Banner, Countdown, Meilensteine, Marktstatus
- Admin: Markt aus Lageplan erstellen (`docs/market-builder.md`, Cloud Function `analyzeMarketPlan`
  mit Claude + Google Geocoding, Import von Marktinfos per Webadresse), Märkte bearbeiten,
  Beiträge und Saisons pflegen
- Zweisprachig DE/EN mit Umschalter in den Einstellungen (Admin-Oberfläche bleibt deutsch)
- Corporate Design (`brand/`), Website auf Cloudflare Workers, App-Store-Texte und Screenshots
  (`docs/app-store/`), nur iPhone

Offen vor dem App-Store-Release (Checkliste in `docs/app-store/README.md`):
EU-Händlerstatus (DSA), Impressum/Datenschutz finalisieren (Website noch mit Platzhaltern),
Demo-Konto für die Prüfung, Karten-Screenshot vom echten iPhone, TestFlight-Test.

Ideen / nicht begonnen: Standort mit dem Team teilen (dann App-Privacy „Genauer Standort“
ergänzen), automatische Übersetzung von Marktinhalten (Beschreibungen sind meist nur deutsch),
Veranstalter-Selbstbedienung.

## Architektur

| Bereich | Technik |
|---|---|
| App | Flutter (Dart ^3.5), Riverpod 2 (`StateNotifier`, `StreamProvider`), Material 3 mit eigenem Theme |
| Backend | Firebase: Auth, Firestore, Storage, Cloud Functions (TypeScript, Node 22, `functions/`), Projekt `event-map-app-aab7b` |
| KI | Claude API in der Cloud Function (Lageplan-Analyse, Webseiten-Import); Keys nur in Secret Manager |
| Karte | `google_maps_flutter` + Clustering |
| Website | statisch in `website/`, Cloudflare Workers (`wrangler.jsonc`), Push auf `main` = live, PRs bekommen Preview-URLs |
| CI | GitHub Actions (Flutter auf 3.47.7 festgelegt): `ios-build` (PRs auf `main`), `testflight` (manuell / Tag `testflight-*`), `firebase-deploy` (manuell) |

Ordner in `lib/`:
- `features/<feature>/{models,providers,services,screens,widgets,logic}` – neuer Code gehört hierher
  (auth, events, stands, teams, favorites, feed, seasons, market_builder, market_editor, admin)
- `data/models/` – ältere gemeinsame Modelle (Event, Stand, Team, Profile, Category)
- `screens/`, `widgets/`, `utils/`, `services/`, `providers/` – älterer, allgemeiner Code
- `theme/` – `brand_tokens.dart` (generiert) und `app_theme.dart`
- `l10n/` – ARB-Dateien und generierte `AppLocalizations`

Firestore-Collections: `profiles` (Rolle `user`/`admin`), `events`, `stands`, `categories`,
`teams`, `feed`, `seasons`. Regeln in `firestore.rules`: Lesen öffentlich bzw. für Angemeldete,
Schreiben von Inhalten nur `isAdmin()`; Nutzer dürfen ihre Rolle nicht selbst ändern.

Muster:
- Reine Logik getrennt von Widgets und testbar (z. B. `features/feed/logic/home_feed.dart` mit
  injizierbarer Uhr `now`, `features/market_builder/services/georeference.dart`).
- Modelle mit `fromFirestore`/`fromMap`/`toFirestore`; englische Texte im Unterobjekt `en`,
  `localized(languageCode)` fällt auf Deutsch zurück.
- Datumswerte ohne Uhrzeit (Saisons, Meilensteine) um 12:00 speichern, damit keine Zeitzone den Tag
  verschiebt.

## Coding-Richtlinien

- **Sprache:** Code, Bezeichner, Kommentare und Commit-Messages auf Englisch; UI-Texte, Doku und
  Markenmaterial auf Deutsch (Englisch als Übersetzung).
- **Texte in der App** nie hart codieren: Schlüssel in `lib/l10n/app_de.arb` (Vorlage) und
  `app_en.arb` anlegen, im Widget `context.l10n.key`. Daten und Zeiten über
  `lib/utils/formatters.dart` (sprachabhängig). Admin-Screens dürfen deutsch bleiben.
- **Farben, Schriften, Radien** nur aus den Brand-Tokens (`BrandColors.*`, CSS-Variablen in
  `website/tokens.css`); keine neuen Hex-Werte. Quelle ist `brand/tokens/tokens.json`, danach
  `python3 brand/tools/build_tokens.py`. Alles Sichtbare folgt dem Skill `.claude/skills/brand/`.
- Stil wie der umliegende Code: kleine Widgets, `const` wo möglich, kurze Doc-Kommentare (`///`)
  für das Warum, keine Kommentar-Romane. `flutter_lints` gilt.
- Neue Logik mit Tests in `test/<feature>/`; Screens, die Firebase brauchen, bleiben ohne
  Widget-Test, ihre Logik wird herausgezogen.
- Keine Secrets im Repo (API-Keys liegen in GitHub-Secrets bzw. Google Secret Manager).
- Website: keine externen Fonts/CDNs/Tracker (DSGVO, kein Cookie-Banner).

## Befehle

```bash
flutter pub get
flutter analyze
flutter test                                      # Unit- und Logiktests
flutter gen-l10n                                  # nach ARB-Änderungen (läuft auch bei pub get)
flutter test tool/store_screenshots --update-goldens   # App-Store-Screenshots neu rendern
flutter run --flavor Production
cd functions && npm ci && npm test                 # baut und testet die Cloud Functions
```

Hinweis: `flutter pub get` verändert eventuell `analysis_options.yaml` und erzeugt `pubspec.lock` –
beides nicht committen (`git checkout analysis_options.yaml`, `pubspec.lock` ist nicht getrackt).

## Arbeitsweise

- Branch → Pull Request auf `main`; `ios-build` und der Cloudflare-Preview müssen grün sein.
- Commit-Messages: englisch, Imperativ, beschreiben das Ergebnis
  („Add seasons: themed start page per time of year“).
- Antworten an Timo auf Deutsch, knapp; Zwischenstände nur bei Ergebnissen oder wenn eine
  Entscheidung gebraucht wird.

## Weiterführend

- `brand/README.md` – Markenleitfaden (Logo, Farben, Typo, Ton)
- `docs/market-builder.md` – Lageplan-Import und Einrichtung der Cloud Function
- `docs/app-store/` – Store-Texte, Screenshots, Release-Checkliste, DSA-Händlerstatus
- `README.md` – allgemeine Projektbeschreibung (teilweise veraltet: Azure-Repo, GitFlow)
