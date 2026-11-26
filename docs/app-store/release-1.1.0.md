# Version 1.1.0 – „Marktplatz“

Build: **20261124.13** (Commit `6c08259`, gesichert als Branch `release/1.1`).

## Neuerungen (App Store, Deutsch) – max. 4.000 Zeichen, hier 659

```
Market Mate sieht neu aus – und du findest schneller, was du suchst.

• Die Karte ist jetzt der Markt: Suche, Kategorien und alle Stände auf einen Blick. Unten siehst du sofort, ob gerade geöffnet ist.
• Tipp auf einen Stand: Angebot, Aktionen und Beschreibung in einer Karte – mit Herz für deine Favoriten.
• Treffpunkt teilen: Kopier einen Stand und schick ihn deinen Freunden.
• Neue Startseite mit Marktsuche.
• Teams: Einladung mit Code kopieren und verschicken.
• Neue Profilbilder im winterlichen Marktlook.
• Kurze Einführung beim ersten Start.
• Der Lageplan des Veranstalters lässt sich wieder über die Karte legen, dazu viele kleine Verbesserungen.
```

## What’s New (App Store, English)

```
Market Mate has a fresh look – and finds what you’re after faster.

• The map is now the market: search, categories and every stall at a glance, plus whether it’s open right now.
• Tap a stall for its offer, specials and description – and a heart for your favourites.
• Share a meeting point: copy a stall and send it to your friends.
• New start page with market search.
• Teams: copy an invitation with the code and send it.
• New profile pictures with a winter market look.
• A short intro on first start.
• The organiser’s site plan can be shown on the map again, plus lots of small improvements.
```

## Werbetext (optional ändern, ohne Prüfung)

DE (136/170):
```
Neu in 1.1: Die Karte ist der Markt. Tipp auf einen Stand und sieh Angebot und Aktionen – und schick ihn deinen Freunden als Treffpunkt.
```

EN (126/170):
```
New in 1.1: the map is the market. Tap a stall to see its offer and specials – and send it to your friends as a meeting point.
```

## Screenshots

Neu gerendert (Workflow „App-Store-Screenshots“) in `docs/app-store/screenshots/<Format>/<de|en>/`:
01 Startseite, 03 Marktinfos, 04 Team (neue Seite und Avatare), 05 Saisons, **06 Stand-Details (neu)**.

**02 Karte** gibt es nur als echten iPhone-Screenshot – der alte zeigt noch die Tab-Leiste und sollte ersetzt
werden: Beispielmarkt öffnen, Suche „Crêpes“, Sheet unten eingeklappt. Ablage in
`tool/store_screenshots/raw/<de|en>/02_map.png`, siehe `docs/app-store/screenshots-nativ.md`.

Reihenfolge im Store: 01 · 02 · 06 · 03 · 04 · 05.

## Vor dem Einreichen

- [ ] Build 20261124.13 in App Store Connect der Version 1.1.0 zuordnen
- [ ] „Neuerungen“ DE/EN einfügen, Beschreibung aus `app-store-texte.md` aktualisieren
- [ ] Screenshots 01, 03–06 hochladen, 02 neu aufnehmen
- [ ] Review-Notizen aus `app-store-texte.md` übernehmen (Ablauf hat sich geändert)
- [ ] Beispielmarkt „Lichterdorf Musterstadt“ läuft (Admin → Beispielmarkt anlegen, Daten aktuell)
- [ ] App-Datenschutz: unverändert (Standlisten-Import ist nur für Admins, keine neuen Datentypen)

## Testen auf TestFlight (Checkliste)

Erledigt mit den Builds .9 bis .13.

- [ ] Erster Start nach dem Update zeigt die drei Einführungskarten; „Überspringen“ und „Los geht’s“ führen weiter
- [ ] Startseite: Begrüßung mit Vorname, Suche „Lichter“ findet den Beispielmarkt, Leeren-Knopf setzt zurück
- [ ] Markt öffnen → „Zur Marktkarte“ unten → Karte im Vollbild, Zurück-Pfeil oben links
- [ ] Unten: Marktname, Status („Geöffnet · bis …“), Knöpfe „Infos“ und „Team“
- [ ] Suche „Crêpes“ und Kategorie-Chips filtern Karte und Liste
- [ ] Stand antippen (Marker und Liste) → Detail-Sheet mit Angebot/Aktion, Herz, „Als Treffpunkt kopieren“
- [ ] Lageplan ein/aus und „Ganzer Markt“ funktionieren, liegen über dem Sheet
- [ ] Team gründen / mit Code beitreten (Sheet über der Tastatur), Einladung kopieren, Code erneuern (nur Gründer)
- [ ] Englisch in den Einstellungen umstellen und Stichproben prüfen
- [ ] iPhone SE / große Schrift: nichts abgeschnitten
