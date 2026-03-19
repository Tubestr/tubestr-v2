# Android GitHub Releases

This repo now builds signed Android release artifacts locally and uploads them to a GitHub release.

## Quick start

```bash
scripts/create_android_keystore.sh
scripts/set_app_version.sh 1.0.3+20
git add pubspec.yaml
git commit -m "Bump version to 1.0.3+20"
scripts/release_android.sh --publish
```

`scripts/release_android.sh --publish` uses the GitHub CLI, so make sure `gh` is installed and authenticated first.

## What it uploads

- A signed `APK` for direct install and sideload testing.
- A signed `AAB` for a future Google Play upload.

## One-time setup

1. Generate an Android upload keystore:

```bash
scripts/create_android_keystore.sh
```

This creates `android/upload-keystore.jks` and will prompt you for:

- the keystore password
- the key password
- your name and organization details for the certificate

2. Create `android/key.properties` for local signed builds:

```properties
storePassword=...
keyPassword=...
keyAlias=tubestr
storeFile=upload-keystore.jks
```

3. Keep that keystore backed up somewhere safe.

You do not need to put the Android keystore into GitHub. GitHub only receives the finished APK and AAB files.

## Release flow

1. Update the app version:

```bash
scripts/set_app_version.sh 1.0.3+20
```

2. Commit that version bump:

```bash
git add pubspec.yaml
git commit -m "Bump version to 1.0.3+20"
```

3. Create and publish the GitHub release from the current `pubspec.yaml` version:

```bash
scripts/release_android.sh --publish
```

That command will:

- build the signed `apk` locally
- build the signed `aab` locally
- create or reuse the git tag from `pubspec.yaml`
- push the tag to `origin`
- create the GitHub release and upload both artifacts

If the GitHub release already exists, rerunning the same command will upload or replace the APK and AAB on that release.

If you do not want to use `gh`, run:

```bash
scripts/release_android.sh --push
```

Then create the GitHub release in the web UI or via the GitHub API and upload:

- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

## Release checklist

- Confirm the version in `pubspec.yaml` is the one you want to ship.
- Make sure the git worktree is clean before creating the release tag.
- Run `flutter test` and any device smoke tests you want before publishing.
- Verify `gh auth status` works before publishing from the CLI.
- Publish the GitHub release after the local build finishes.
- Download the attached APK once and install it on a real Android device as a smoke test.

## Local release builds

For local signed Android builds, create `android/key.properties`:

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=upload-keystore.jks
```

Then place the keystore at `android/upload-keystore.jks` and run:

```bash
flutter build apk --release
flutter build appbundle --release
```

If signing is missing, release builds now fail fast instead of silently using the debug keystore.

## Helper scripts

- `scripts/create_android_keystore.sh`
  Creates the upload keystore and prints the next local signing steps.
- `scripts/set_app_version.sh`
  Updates `pubspec.yaml` with the exact `version+build` you want to ship.
- `scripts/release_android.sh`
  Derives the tag from `pubspec.yaml`, builds the release locally, and can publish the GitHub release with `gh`.
