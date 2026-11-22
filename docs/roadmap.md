# Roadmap: Market Mate marktreif machen

Stand: 15. November 2026. Ziel: App-Store-Release (iPhone) mit sauberem Datenschutz, einem
Beispielmarkt zum Ausprobieren und einem Design, das Spaß macht.

**Leitlinie Ressourcen:** eine Phase = ein Pull Request, keine neuen Dienste, nur Firebase-Free-/Blaze-Basis
und vorhandene CI. Claude-API-Aufrufe nur im Admin-Weg (Lageplan-Analyse), nie pro Besucher.
Screenshots entstehen aus dem vorhandenen Test (`tool/store_screenshots`), nicht von Hand.

| Phase | Inhalt | Aufwand | Status |
|---|---|---|---|
| 0 | Rechtliches & Blocker | 1–2 Tage | offen |
| 1 | Daten-Einwilligung & Beispielmarkt | 1 Tag | im PR |
| 2 | Design-Refresh | 2–3 Tage | 1.1.0 (offen: dunkler Modus) |
| 3 | Funktionen ausreifen | 3–4 Tage | 1.1.0 größtenteils |
| 4 | Prod-Readiness | 2 Tage | offen |
| 5 | Store-Paket & Einreichung | 1–2 Tage | erledigt (App im Store) |

## Phase 0 – Rechtliches & Blocker (ohne Code-Risiko, zuerst)

- [ ] Impressum und Datenschutzerklärung finalisieren (Website hat noch Platzhalter)
- [ ] EU-Händlerstatus (DSA) entscheiden und in App Store Connect eintragen
- [ ] Apple Developer Program aktiv, App in App Store Connect angelegt
- [ ] Demo-Konto für die Prüfung anlegen (Review-Notizen in `docs/app-store/app-store-texte.md`)
- [x] Datenschutz-Text um „Lagepläne von Veranstaltern“, Beispielmarkt und Löschung ergänzt (Entwurf, rechtlich prüfen)
- [x] Konto löschen entfernt jetzt auch die Teilnahme an Märkten (`events.participants`)
- [ ] **Von Timo nötig:** Name, Anschrift und Telefon für Impressum und Datenschutz (siehe DSA-Abschnitt in `docs/app-store/README.md`). Diese Angaben erfinde ich nicht.

## Phase 1 – Daten-Einwilligung & Beispielmarkt

- [x] **Einwilligungs-Flag** beim Lageplan-Upload: ohne Haken kein Upload, keine Analyse, kein Speichern.
      Gespeichert wird `planConsent` (granted, version, at, by) am Markt. Firestore-Regeln lehnen Märkte mit
      Plan ohne Einwilligung ab; die Cloud Function lehnt die Analyse ohne Einwilligung ab.
- [x] **Beispielmarkt „Lichterdorf Musterstadt“**: komplett erfunden (Name, Stände, Speisen, Texte, Titelbild),
      keine Daten Dritter. Wird im Admin-Bereich mit einem Tippen angelegt oder aktualisiert und trägt
      `isDemo: true`. Zeigt das Prinzip: Karte, Kategorien, Suche, Team.
- [ ] Einwilligungstext vom Anwalt/Datenschutzbeauftragten gegenlesen lassen (Version im Code hochzählen, wenn er sich ändert)
- [ ] Optional später: Veranstalter-Selbstbedienung (dann Einwilligung pro Veranstalter statt pro Admin)

## Phase 2 – Design-Refresh

Konzept: **Marktstand statt Standard-App.** Die Markise (rot-weiße Streifen mit Girlandenkante) ist das eine
wiedererkennbare Element; alles andere bleibt ruhig. Marke bleibt: Marktrot, Kohle, Papier, Bebas Neue, Figtree.

- [x] Schriften in die App bündeln (bisher fiel die App auf die Systemschrift zurück)
- [x] Theme: Typo-Skala, größere Tippflächen, Navigation als echte Material-3-Leiste mit Gold-Indikator
- [x] Markisen-Kante als Widget (`AwningEdge`), Marktkarten mit Datums-Schild und Herz mit Feder-Effekt
- [x] Leere Zustände mit klarer Handlung („Noch keine Favoriten. Tippe das Herz an einem Markt.“)
- [x] Startseite: großer Kopf mit Begrüßung und Marktsuche (1.1.0); Kategorie-Schnellzugriff entfällt – Kategorien gibt es je Markt auf der Karte
- [x] Karte ist der Markt: Vollbild, Sheet mit Status, Infos/Team, Standliste; Stand-Details als Bottom Sheet (1.1.0)
- [x] Onboarding in drei Karten (Karte, Stände finden, Freunde einladen), nur beim ersten Start (1.1.0)
- [ ] Dunkler Modus „Abendmarkt“ (Tokens existieren schon)
- [ ] Alle Texte in `app_de.arb` / `app_en.arb`, Prüfung auf 390 px und große Schrift

## Phase 3 – Funktionen ausreifen

- [x] Stand-Details (Name, Angebot, Aktion, Bild, „Als Treffpunkt kopieren“) als Sheet (1.1.0)
- [x] Suche über alle Stände eines Marktes (auch im Angebot), mit Kategorie-Chips (1.1.0)
- [x] Teams: Mitglieder, verlassen, Einladung kopieren, Code erneuern (1.1.0); Regeln einschränken bleibt Phase 4
- [x] `isMarketOpen` vergleicht Wochentage jetzt sprachunabhängig (`weekdayOf`, `isOpenAt`, getestet)
- [ ] Fehler-, Lade- und Offline-Zustände für Karte und Listen vereinheitlichen (Startseite ist mit `EmptyState` erledigt)
- [ ] Standort mit dem Team teilen (nur wenn gewollt; dann App-Privacy „Genauer Standort“ ergänzen)
- [ ] Automatische Übersetzung der Marktbeschreibung (einmalig beim Speichern, nicht pro Aufruf)

## Phase 4 – Prod-Readiness

- [ ] **Firestore-Regeln härten:** `teams` ist heute für jeden Angemeldeten les- und schreibbar. Auf Mitglieder beschränken
      und mit dem Emulator testen (`@firebase/rules-unit-testing`, läuft in der CI ohne Kosten)
- [ ] Firebase App Check (App Attest) für Firestore, Storage und Functions
- [ ] Crashlytics einbinden, Release-Build ohne Debug-Ausgaben
- [ ] Cloud Function: Aufrufbegrenzung pro Admin und Tag (schützt das Claude-Budget)
- [x] Konto löschen räumt Teams, Favoriten und Marktteilnahme auf (hochgeladene Pläne gehören dem Markt, nicht dem Konto)
- [x] CI: `flutter analyze` und `flutter test` laufen in jedem PR (`flutter-check.yml`, 1.1.0); `functions`-Tests noch offen
- [ ] iOS: Privacy Manifest, Versionsnummer, Build-Nummer aus der CI
- [ ] Backups: tägliche Firestore-Exports (günstig, Bucket mit Ablauf nach 30 Tagen)

## Phase 5 – Store-Paket & Einreichung

- [ ] Screenshots neu rendern (`flutter test tool/store_screenshots --update-goldens`) mit dem Beispielmarkt-Look
- [ ] Karten-Screenshot vom echten iPhone mit dem Beispielmarkt (Suche „Crêpes“)
- [ ] Texte DE/EN final, Altersfreigabe, Datenschutzfragebogen
- [ ] TestFlight-Build auf zwei echten iPhones testen (Checkliste in `docs/app-store/README.md`)
- [ ] Einreichen, Review-Notizen mit Demo-Konto und Hinweis auf den Beispielmarkt

## Nicht geprüft in diesem Stand

Flutter und das Functions-Paket sind in der Arbeitsumgebung nicht installiert. Vor dem Merge laufen lassen:
`flutter analyze`, `flutter test`, `cd functions && npm ci && npm test`, danach
`flutter test tool/store_screenshots --update-goldens` (Theme und Karten haben sich geändert, die Screenshots
müssen neu gerendert werden). Geprüft wurde nur die Einwilligungs-Logik der Function in Node und die Klammerstruktur der Dart-Dateien.

## Entscheidungen, die noch bei Timo liegen

1. Einwilligungstext: Der Entwurf steht in `plan_consent.dart`. Rechtlich prüfen lassen.
2. Gilt die Einwilligung des Admins stellvertretend für den Veranstalter, oder holen wir sie schriftlich?
   Der Entwurf geht vom zweiten Fall aus („Ich bin berechtigt …“).
3. Android: Konzept in `docs/android.md` (Web-App jetzt, Play-Test parallel) – Kontoart entscheiden.
