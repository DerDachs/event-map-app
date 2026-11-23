# Umgebungen: Produktion, Release-Branch, Dev-Datenbank

## Release-Branches

Jede Version im App Store bekommt einen Branch `release/<major.minor>` auf genau dem Commit,
aus dem der eingereichte Build stammt.

| Branch | Commit | Build | Inhalt |
|---|---|---|---|
| `release/1.0` | `8482654` | 20261117.7 | Version 1.0.0 im App Store |

Hotfix für die Store-Version: Branch von `release/1.0` abzweigen, Fix, PR auf `release/1.0`,
TestFlight-Workflow mit `ref=release/1.0` starten, danach den Fix nach `main` übernehmen.
Neue Release-Branches entstehen, wenn eine Version zur Prüfung eingereicht wird (z. B. `release/1.1`).

## Dev-Datenbank (Vorschlag)

Heute arbeiten App, TestFlight-Builds und Admin-Tests gegen dieselbe Firebase-Instanz
(`event-map-app-aab7b`). Eine zweite Instanz lohnt sich, sobald echte Nutzer da sind –
also jetzt:

- **Firebase-Projekt `market-mate-dev`** mit Firestore, Auth, Storage, Functions; Regeln und
  Functions werden in beide Projekte deployt (`.firebaserc` mit Aliasen `prod` / `dev`).
- **Flavors nutzen, die es schon gibt:** `Staging` (Schema existiert) → Dev-Projekt,
  `Production` → Prod. Je Flavor eine eigene `GoogleService-Info.plist` und eigene Bundle-ID
  (z. B. `….dev`), damit beide Apps nebeneinander auf dem iPhone liegen.
- **Web-App-Vorschau** für PRs gegen Dev, `main` gegen Prod.
- **Testdaten:** Beispielmarkt „Lichterdorf Musterstadt“ und Testkonten nur in Dev; ein kleines
  Seed-Skript legt sie neu an.
- Was bewusst geteilt bleibt: nichts – getrennte Nutzerkonten, getrennte Claude-Aufrufe.

Aufwand: ca. ½–1 Tag, sobald das Firebase-Projekt angelegt ist (das muss Timo in der Firebase-Konsole tun).
