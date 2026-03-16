# MyTube v2

Flutter rewrite of MyTube with:

- parent-only Nostr identity
- Drift-backed local app state
- NDK adapter boundary for general Nostr plumbing
- MDK bridge scaffold for MLS and MIP-04
- Blossom client scaffold for immutable blob upload

## Current State

The app is bootstrapped and runnable. The first vertical slice is in place:

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

Rebuild the Flutter Rust bridge, Android Rust `.so` files, debug APK, and reinstall on a USB device:

```bash
scripts/rebuild_android_bridge.sh
```

Target a specific device:

```bash
scripts/rebuild_android_bridge.sh 58281JEBF12262
```

## Notes

- `docs/plan.md` is the source of truth for live progress and implementation notes.
- Riverpod is pinned to the 2.x line for now because current Flutter SDK package pinning conflicted with `drift_dev` when using Riverpod 3.x.
- The generated Drift file lives at `lib/core/storage/app_database.g.dart`.
- `flutter build apk --debug` currently succeeds in this environment.
- If FRB or Rust bridge code changes, use `scripts/rebuild_android_bridge.sh` instead of `flutter run` alone.
