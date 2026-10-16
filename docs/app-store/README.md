# App Store – Veröffentlichung

| Was | Wo |
|---|---|
| Alle Texte zum Kopieren (DE/EN), Review-Notizen, Datenschutz- und Altersfragebogen | [`app-store-texte.md`](app-store-texte.md) |
| Screenshots 1320 × 2868 (iPhone 6,9″) | [`screenshots/de/`](screenshots/de/), [`screenshots/en/`](screenshots/en/) |
| App-Icon 1024 × 1024 | steckt im Build (`ios/Runner/Assets.xcassets/AppIcon.appiconset/`) |

## Screenshots erzeugen

Die Screenshots werden aus den echten App-Widgets mit Beispieldaten gerendert
(`tool/store_screenshots/store_screenshots_test.dart`): Headline in Bebas Neue, darunter das Handy.

```bash
flutter test tool/store_screenshots --update-goldens
```

- **Karte (02_map)**: Google Maps lässt sich im Test nicht rendern. Mach auf dem iPhone einen
  Screenshot der Marktkarte (am besten mit der Suche „Crêpes“ und einem markierten Stand), lege ihn
  als `tool/store_screenshots/raw/de/02_map.png` bzw. `…/en/02_map.png` ab und starte den Befehl erneut.
- Headlines und Unterzeilen stehen oben in der Testdatei (`_copy`).
- Die Beispielmärkte sind erfunden (keine echten Märkte, keine fremden Fotos); die Bilder sind eigene
  Illustrationen in `tool/store_screenshots/images/`.
- Dabei entsteht auch `website-home.png`, die Startseite für die Website:
  `convert docs/app-store/website-home.png -quality 82 website/assets/app-home.webp`

## Checkliste vor dem Einreichen

- [ ] Apple Developer Program aktiv (99 $/Jahr) – als Einzelperson oder Organisation (D-U-N-S)
- [ ] EU-Händlerstatus angegeben (siehe unten)
- [ ] App in App Store Connect angelegt (Bundle-ID siehe Texte), nur iPhone
- [ ] Impressum und Datenschutzerklärung auf der Website fertig (aktuell noch Entwurf mit Platzhaltern)
- [ ] Firestore-Regeln deployed, mindestens ein Markt mit Ständen sichtbar
- [ ] Demo-Konto angelegt und in den Review-Notizen eingetragen
- [ ] Build per TestFlight-Workflow hochgeladen und auf einem iPhone getestet
- [ ] Karten-Screenshot ergänzt, Screenshots DE und EN hochgeladen
- [ ] Texte, Datenschutz- und Altersfragebogen ausgefüllt (siehe `app-store-texte.md`)

## EU-Händlerstatus (DSA)

„Händler“ heißt nicht „Unternehmen“. Nach EU-Recht ist Händler jede natürliche oder juristische Person,
die zu Zwecken ihrer gewerblichen, geschäftlichen, handwerklichen oder beruflichen Tätigkeit handelt –
also auch Einzelunternehmer und Freiberufler. Wer Händler ist, muss Adresse, Telefonnummer und E-Mail
angeben; Apple prüft sie und zeigt sie in der EU auf der App-Seite an.

Als Nicht-Händler gilt, wer die App privat ohne geschäftlichen Zweck anbietet (z. B. ein Hobbyprojekt
ohne Einnahmen). Sobald Veranstalter als zahlende Kunden angesprochen werden, spricht viel für
„Händler“. Im Zweifel steuerlich/rechtlich beraten lassen; viele Einzelpersonen nutzen eine
Geschäftsadresse statt der Privatadresse.
