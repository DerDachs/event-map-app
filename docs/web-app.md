# Web-App (app.marketmate.cellarworks.dev)

Die Flutter-App läuft auch im Browser und lässt sich auf Android über „Zum Startbildschirm
hinzufügen“ installieren. Hintergrund und Abwägung: `docs/android.md`.

## Aufbau

| Teil | Wo |
|---|---|
| Worker | `marketmate-app`, Konfiguration `web-app/wrangler.jsonc`, liefert `build/web` aus |
| Domain | `app.marketmate.cellarworks.dev` (Custom Domain des Workers) |
| Website | unverändert: Worker `marketmate-website`, `wrangler.jsonc` im Repo-Root, Ordner `website/` |
| CI | `.github/workflows/web-app.yml`: PR = Build + Smoke-Test in Chrome, Push auf `main` = Deploy |

Im Browser: Anmeldung nur per E-Mail (Apple bräuchte eine Services-ID), Admin-Funktionen mit
Datei-Upload sind für die App gedacht. CanvasKit wird mit ausgeliefert, nicht von Googles CDN geladen.

## Einmalige Einrichtung

1. **Cloudflare-API-Token** (My Profile → API Tokens → Vorlage „Edit Cloudflare Workers“, Zone
   `cellarworks.dev` einschließen, damit die Custom Domain angelegt werden kann).
   GitHub-Secrets: `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`.
2. **Google-Maps-Browser-Schlüssel** im Google-Cloud-Projekt `event-map-app-aab7b`: „Maps JavaScript
   API“ aktivieren, neuen Schlüssel anlegen, beschränkt auf Websites
   `https://app.marketmate.cellarworks.dev/*` und die Maps JavaScript API.
   GitHub-Secret: `GOOGLE_MAPS_WEB_KEY`.
3. **Firebase Authentication** → Einstellungen → Autorisierte Domains: `app.marketmate.cellarworks.dev`.
4. Workflow „Web App“ auf `main` manuell starten (oder nächster Push).
5. **Datenschutzerklärung** um die Web-App ergänzen (Hosting bei Cloudflare, Google Maps JavaScript API).

## Lokal testen

```bash
flutter run -d chrome          # Karte bleibt ohne Schlüssel grau, Rest funktioniert
```
