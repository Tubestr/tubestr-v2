# Zapstore Publishing

TubeStr now has a GitHub release that Zapstore can ingest directly:

- Release page: `https://github.com/Tubestr/tubestr-v2/releases/tag/v1.0.0`
- APK URL: `https://github.com/Tubestr/tubestr-v2/releases/download/v1.0.0/tubestr-v1.0.0-android.apk`
- Source repo: `https://github.com/Tubestr/tubestr-v2`

## Web publisher

Open `https://publisher.zapstore.dev/` with a NIP-07 compatible Nostr extension and fill in:

- APK URL: `https://github.com/Tubestr/tubestr-v2/releases/download/v1.0.0/tubestr-v1.0.0-android.apk`
- App Icon URL: your hosted app icon URL
- Source Code Repository URL: `https://github.com/Tubestr/tubestr-v2`
- Description: short TubeStr app description
- License: optional for now

Then review the generated events and sign them with your Nostr extension.

## CLI prep

This repo now includes `zapstore.yaml` for the local CLI path:

```yaml
repository: https://github.com/Tubestr/tubestr-v2
release_source: build/app/outputs/flutter-apk/app-release.apk
```

That matches the shape used in Zapstore's own repository and points at the local release APK that `flutter build apk --release` produces.

## Recommended next step

Use the web publisher for the first submission so we can verify the app metadata and listing shape, then keep `zapstore.yaml` around for a more repeatable CLI flow afterward.
