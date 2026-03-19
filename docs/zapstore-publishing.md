# Zapstore Publishing

TubeStr now has a GitHub release that Zapstore can ingest directly:

- Release page: `https://github.com/Tubestr/tubestr-v2/releases/tag/v1.0.3`
- APK URL: `https://github.com/Tubestr/tubestr-v2/releases/download/v1.0.3/tubestr-v1.0.3-android.apk`
- Source repo: `https://github.com/Tubestr/tubestr-v2`

## Web publisher

Open `https://publisher.zapstore.dev/` with a NIP-07 compatible Nostr extension and fill in:

- APK URL: `https://github.com/Tubestr/tubestr-v2/releases/download/v1.0.3/tubestr-v1.0.3-android.apk`
- App Icon URL: `https://raw.githubusercontent.com/Tubestr/tubestr-v2/main/web/icons/Icon-512.png`
- Source Code Repository URL: `https://github.com/Tubestr/tubestr-v2`
- Description: `Private family video sharing for parents and kids.`
- License: optional for now

Then review the generated events and sign them with your Nostr extension.

Because this repo uses `metadata_sources: github` in `zapstore.yaml`, treat the GitHub-facing metadata as part of the listing:

- keep the repo description short and product-focused
- keep the opening README sections user-facing
- keep `CHANGELOG.md` current so release context is easy to ingest

## CLI prep

This repo now includes `zapstore.yaml` for the local CLI path:

```yaml
repository: https://github.com/Tubestr/tubestr-v2
release_source: build/app/outputs/flutter-apk/app-release.apk
changelog: CHANGELOG.md
```

That matches the shape used in Zapstore's own repository and points at the local release APK that `flutter build apk --release` produces.

## Recommended next step

Use the web publisher for the first submission so we can verify the app metadata and listing shape, then keep `zapstore.yaml` around for a more repeatable CLI flow afterward.
