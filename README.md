# TubeStr

Private family video sharing for parents and kids.

TubeStr is a local-first family video app built with Flutter. Parents create the account, manage child profiles, review content, and share clips across trusted family spaces with Nostr-based sync.

## What TubeStr Does

- Parent-managed accounts and child profiles
- Private family spaces for sharing videos with trusted people
- Parent review flows for approvals, reports, and moderation actions
- Local-first storage with offline queueing and sync recovery
- Camera, playback, and editing foundations for kid-friendly creation

## Current State

The app is bootstrapped and runnable. The current vertical slice includes:

- onboarding creates and securely stores a parent identity
- child profiles are persisted in Drift
- home feed reads from Drift and supports profile switching
- parent zone supports child CRUD, relay list editing, and simple PIN setup
- camera page initializes device cameras and shows preview
- player route and shell are wired for local files
- local ranking and a basic report action are wired into the UI
- service boundaries exist for NDK, MDK, sync, sharing, safety, and Blossom

Not finished yet:

- MDK bridge and encrypted media flow
- real sharing/sync across relays
- recording pipeline, thumbnails, editor, and moderation end-to-end
- deep links, subscriptions, offline queue, and full Safety HQ flow

## Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

For Android debug builds and Rust bridge rebuilds, install the local toolchain first:

```bash
flutter doctor
rustup --version
cargo install cargo-ndk flutter_rust_bridge_codegen
```

The rebuild script expects the Android NDK at `ANDROID_NDK_HOME` or `NDK_HOME`.
If neither is set, it falls back to `/opt/android-sdk/ndk/28.2.13676358`.

Rebuild the Flutter Rust bridge, Android Rust `.so` files, debug APK, and reinstall on a USB device:

```bash
scripts/rebuild_android_bridge.sh
```

Target a specific device:

```bash
scripts/rebuild_android_bridge.sh 58281JEBF12262
```

Set a release version in `pubspec.yaml`:

```bash
scripts/set_app_version.sh 1.0.3+20
```

Create the Android upload keystore:

```bash
scripts/create_android_keystore.sh
```

Create and publish the Android GitHub release from the current app version:

```bash
scripts/release_android.sh --publish
```

If you prefer the GitHub web UI, use:

```bash
scripts/release_android.sh --push
```

## Notes

- `docs/plan.md` is the source of truth for live progress and implementation notes.
- Riverpod is pinned to the 2.x line for now because current Flutter SDK package pinning conflicted with `drift_dev` when using Riverpod 3.x.
- The generated Drift file lives at `lib/core/storage/app_database.g.dart`.
- `flutter build apk --debug` is part of the expected local validation path once Flutter, Rust, `cargo-ndk`, `flutter_rust_bridge_codegen`, and the Android NDK are installed.
- If FRB or Rust bridge code changes, use `scripts/rebuild_android_bridge.sh` instead of `flutter run` alone.
- Android release setup lives in `docs/android-github-releases.md`.
- Zapstore notes live in `docs/zapstore-publishing.md`.
