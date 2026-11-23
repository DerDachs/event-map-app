# Dev-Firebase-Konfiguration (Flavor `Staging`)

Hier gehört die `GoogleService-Info.plist` der iOS-App **com.tdwdevelopments.event-map.dev**
aus dem Dev-Firebase-Projekt hin. Die Build-Phase „Select Firebase config“ kopiert sie bei
Staging-Builds über die Produktions-Datei. Fehlt sie, bricht ein Staging-Build mit einer
klaren Meldung ab; Production-Builds sind nicht betroffen.

Die Datei enthält keine Geheimnisse (wie die Produktions-Datei in `ios/Runner/`) und darf
eingecheckt werden. Zugriff schützen Firestore-Regeln und App Check, nicht die Datei.
