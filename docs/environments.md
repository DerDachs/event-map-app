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

## Dev-Umgebung

| | Produktion | Dev |
|---|---|---|
| Firebase-Projekt | `event-map-app-aab7b` | Repo-Variable `FIREBASE_DEV_PROJECT_ID` |
| iOS-Flavor / Schema | `Production` | `Staging` |
| Bundle-ID | `com.tdwdevelopments.event-map` | `com.tdwdevelopments.event-map.dev` |
| Name auf dem iPhone | Market Mate | Market Mate Dev (mit „DEV“-Band oben rechts) |
| Firebase-Konfiguration | `ios/Runner/GoogleService-Info.plist` | `ios/config/staging/GoogleService-Info.plist` |
| TestFlight | Workflow „iOS → TestFlight“, Flavor `Production` | derselbe Workflow, Flavor `Staging` |
| Regeln & Functions | „Firebase deploy“, environment `prod` | „Firebase deploy“, environment `dev` |

Die Build-Phase „Select Firebase config“ im Xcode-Projekt tauscht bei Staging-Builds die
Firebase-Datei aus. Beide Apps können nebeneinander auf dem iPhone liegen.

### Einmalige Einrichtung

1. **Firebase (Dev-Projekt):** Authentication (E-Mail, Apple), Firestore (Region wie Prod),
   Storage aktivieren. Für Cloud Functions braucht es den Blaze-Tarif.
2. **iOS-App im Dev-Projekt registrieren** mit Bundle-ID `com.tdwdevelopments.event-map.dev`,
   `GoogleService-Info.plist` herunterladen und nach `ios/config/staging/` legen (oder Claude geben).
3. **Apple Developer:** App-ID `com.tdwdevelopments.event-map.dev` mit „Sign in with Apple“ und
   Push; ein App-Store-Provisioning-Profil dafür. In **App Store Connect** eine App
   „Market Mate Dev“ mit dieser Bundle-ID anlegen – nur für TestFlight, wird nie eingereicht.
4. **GitHub:** Variable `FIREBASE_DEV_PROJECT_ID`, Secret `FIREBASE_SERVICE_ACCOUNT_DEV`
   (Dienstkonto-JSON des Dev-Projekts, Rolle „Firebase Admin“).
5. **„Firebase deploy“** mit environment `dev` starten (beim ersten Mal „update_api_keys“ anhaken,
   damit die Lageplan-Analyse ihre Schlüssel auch im Dev-Projekt hat).
6. **„iOS → TestFlight“** mit Flavor `Staging` starten.
7. In der Dev-App registrieren, in der Firestore-Konsole des Dev-Projekts beim eigenen Profil
   `role` auf `admin` setzen, dann im Admin-Bereich den Beispielmarkt „Lichterdorf Musterstadt“ anlegen.

Offen: Web-App-Vorschauen gegen Dev (braucht die Web-Konfiguration des Dev-Projekts).
