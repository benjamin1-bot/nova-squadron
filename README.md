# Prismwing

3D-Weltraum-Railshooter als Android-App (läuft offline, Vollbild, Querformat).

## APK herunterladen
Unter **Releases** (rechts auf der Repo-Startseite) die neueste `Prismwing.apk` antippen und installieren.
Beim ersten Mal muss „Installation aus unbekannten Quellen“ für den Browser erlaubt werden.

## Wie die APK entsteht
Bei jeder Änderung auf `main` baut GitHub Actions (`.github/workflows/build-apk.yml`) die APK automatisch
und hängt sie als Release an. Manuell starten: Reiter **Actions → APK bauen → Run workflow**.

Das Spiel selbst liegt in `app/src/main/assets/index.html`.
