# Market Mate auf Android – mit wenig Mehraufwand

Stand: November 2026 (Version 1.1.0). Jira: MM-19.

## Ausgangslage

Die App ist Flutter, also ist Android im Code schon fast da: `android/` existiert,
`google-services.json` liegt bereit, `lib/firebase_options.dart` enthält Android- und Web-Konfiguration.
Die Hürden liegen nicht im Code, sondern bei Verteilung und Kontoformalitäten.

## Option A – Web-App (PWA) unter `marketmate.cellarworks.dev/app`

Flutter baut dieselbe App für den Browser (`flutter build web`). Auf Android lässt sie sich über
„Zum Startbildschirm hinzufügen“ wie eine App installieren (Vollbild, eigenes Icon). Gehostet wird
sie auf Cloudflare Workers neben der Website – kein neuer Dienst, keine Gebühr.

**Nötige Arbeiten (ca. 1–2 Tage):**

1. `main.dart`: `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` –
   ohne Optionen startet Firebase im Browser nicht.
2. `web/index.html`: Google-Maps-JavaScript-API laden, eigener Schlüssel nur für die Domain
   `marketmate.cellarworks.dev` freigegeben.
3. Plattformweichen für das, was es im Browser nicht gibt: `permission_handler`, Datei-Upload mit
   `dart:io` (`image_upload_service.dart`, nur Admin/Avatar) – im Web den Admin-Bereich ausblenden.
4. Anmeldung: E-Mail geht sofort. „Mit Apple anmelden“ braucht im Web eine Services-ID und
   Rücksprung-URL bei Apple; für den Start reicht E-Mail.
5. Firebase Auth: Domain als „autorisierte Domain“ eintragen.
6. Neuer CI-Schritt: `flutter build web --release --base-href /app/` → `website/app/`, Deploy wie die
   Website (Push auf `main`).
7. `web/manifest.json` mit Markenfarben und Icons aus `brand/logo/`.

**Vorteile:** Sofort für alle Android-Nutzer (und Desktop), keine Prüfung, keine Testpflicht.
Ein Team-Code lässt sich als Link teilen, der direkt im Browser öffnet – auch für Freunde ohne App.
Jede Änderung auf `main` ist sofort live.

**Grenzen:** Karte im Browser etwas weniger flüssig; der „Mein Standort“-Punkt war im Web-Plugin lange
nicht verfügbar (vor dem Start prüfen). Kein Push. Keine Sichtbarkeit im Play Store.

## Option B – Nativ im Google Play Store

Technisch gering: `flutter build appbundle`, Android-Maps-Schlüssel, Signierschlüssel als
GitHub-Secret, ein Workflow analog zu `testflight.yml`. Einmalig 25 $ für das Play-Konto.

**Die eigentliche Hürde:** Neue *private* Entwicklerkonten (angelegt nach dem 13.11.2023) müssen
vor der Veröffentlichung einen geschlossenen Test mit mindestens 12 Testern durchführen, die
14 Tage am Stück dabei sind. Konten als Organisation sind davon ausgenommen, brauchen aber eine
D-U-N-S-Nummer (kann bis zu 30 Tage dauern).

## Umsetzung

Option A ist umgesetzt (PR #21), Einrichtung und Secrets: `docs/web-app.md`.

## Empfehlung

1. **Jetzt: Web-App (Option A)** als schneller Android-Weg. Gleicher Code, kein Store, und der
   Team-Einladungslink wird damit für alle nutzbar.
2. **Parallel: Play-Konto anlegen und den 14-Tage-Test starten**, sobald 1.1.0 stabil ist – die Uhr
   läuft ohnehin, und die Tester (Freunde, Familie, LAN-Runde) gibt es. Danach die native App
   nachziehen; die Web-App bleibt als Link-Ziel bestehen.

Entscheidung bei Timo: privates Konto mit Testphase oder Organisationskonto für cellarworks.

## Quellen

- [Play Console Help – App testing requirements for new personal developer accounts](https://support.google.com/googleplay/android-developer/answer/14151465)
- [google_maps_flutter_web – Einrichtung und Einschränkungen](https://pub.dev/documentation/google_maps_flutter_web/latest/)
