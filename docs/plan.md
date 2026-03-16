# MyTube v2 Implementation Plan

## Goal

Ship a fully working Flutter rewrite of MyTube using:

- Flutter for app/UI
- Drift for app-local state
- Riverpod for state management
- `go_router` for navigation
- MDK v0.7.1 over `flutter_rust_bridge` for MLS, MIP-04 media, and safety-critical group flows
- NDK for general Nostr relay/event plumbing
- Blossom for immutable blob storage

This workspace started empty on 2026-03-15, so the implementation plan covers both project bootstrapping and full product delivery.

## Locked Product Decisions

- Parent-only Nostr identity. Children are local metadata only.
- One primary share group per child in v1, with schema ready for multi-group later.
- Safety HQ ships from day 1 and is queued during onboarding without blocking app use.
- Blossom is immutable blob storage, not the source of truth.
- Delete video and remove member are separate moderation actions.

## Source References

- `/home/lee/apps/tubestr-ios/Docs/MyTubeProtocolSpec.md`
- `/home/lee/apps/tubestr-v2/docs/UIReference.md`
- `/home/lee/apps/tubestr-ios/MyTube/Domain/Models.swift`
- `/home/lee/apps/tubestr-ios/MyTube/Domain/ReportModels.swift`
- `/home/lee/apps/tubestr-ios/MyTube/Domain/RankingEngine.swift`
- `/home/lee/apps/tubestr-ios/MyTube/SharedUI/Theme/KidTheme.swift`
- `/home/lee/apps/tubestr-ios/MyTube/Services/Marmot/MarmotMessageModels.swift`

## Status Snapshot

- Date: 2026-03-15
- Workspace state: Flutter app bootstrapped, Drift code generated, analysis green
- iOS app available for reference at `/home/lee/apps/tubestr-ios`
- Current focus: tighten the Phase 3 media/share loop so shared events can carry real encrypted Blossom assets, remote thumbnails can prefetch automatically, and downloaded shares can decrypt into playable local cache files

## Execution Rules

- Keep this file updated as tasks move.
- Use `[ ]` for pending, `[-]` for in progress, `[x]` for complete.
- Record key implementation notes and deviations under the phase they affect.
- Prefer vertical slices that leave the app runnable after each major checkpoint.
- Treat `docs/UIReference.md` as the required source of truth for screen structure, tablet-first layout, onboarding flow, and shared component behavior whenever UI work is in scope.

## Phase 0: Bootstrap

- [x] Create Flutter application scaffold in this repo
- [x] Add baseline package set and linting
- [x] Establish app folder structure from the architecture brief
- [x] Configure Android, iOS, Linux, macOS, web support as reasonable defaults
- [x] Create initial `README.md` with run/build/test notes

### Notes

- The repo is greenfield. Bootstrap needs to be done before any feature implementation.
- Riverpod 3.x conflicted with `drift_dev` under the current Flutter SDK's pinned test dependencies, so the app is temporarily on `flutter_riverpod` 2.6.1.

## Phase 1: Foundation

- [x] Build app shell: `main.dart`, `app.dart`, theme, router, provider scope
- [x] Implement kid theme system with at least 4 palettes adapted from iOS reference
- [x] Add Drift and create the full initial schema
- [x] Implement secure parent identity storage service
- [x] Add child profile CRUD over Drift
- [x] Add NDK adapter boundary and placeholder relay client integration
- [x] Add MDK service boundary and Rust bridge scaffold
- [x] Add Blossom client scaffold with auth/signing hooks
- [-] Validate MDK/NDK event ownership assumptions for kinds 443/444/445 and MIP-04 flow
- [-] Add automated tests for models, theme mapping, and local DB basics

### Notes

- MDK owns private/group/safety flows and its own SQLite state.
- Flutter app owns all UI projections and app-specific state.
- NDK should stay behind an adapter so it can be swapped or hardened later.
- `native/mdk_bridge` now has a real `flutter_rust_bridge` + `mdk-core` smoke-test bridge.
- Parent Zone can now generate and publish MDK key package payloads and create local MDK groups, which helps validate kind:443 and local MLS lifecycle assumptions from inside the app.
- Drift schema and generated code are present in `lib/core/storage/app_database.dart` and `lib/core/storage/app_database.g.dart`.

## Phase 2: Core App Loop

- [x] Onboarding flow: parent key, child profiles, relay preferences, Safety HQ queue intent
- [x] Home feed backed by Drift streams
- [x] Profile switching
- [x] Camera capture
- [x] Thumbnail generation
- [-] Video player with playback controls
- [x] Parent Zone scaffold with PIN auth and settings
- [-] Deep link handling for all required schemes

### Notes

- The app should feel functional locally before network sharing is added.
- UI work should follow `docs/UIReference.md` and preserve the old app's tablet-first structure.
- Camera preview, recording, and local file persistence are wired into the Drift feed.
- Thumbnail generation is wired for captured local clips and displayed in the feed.
- Editor handoff is still pending.
- Player route exists; real playback works only once captured/imported files are stored with valid paths.
- `nook://` deep-link handling is now wired through `app_links` into the app shell and opens Parent Zone, with Android intent-filter support. `tubestr://` and `mytube://` are still pending by choice after narrowing the current scope.

## Phase 2.5: Editor Spike

- [ ] Prototype trim + LUT filter + audio overlay with `ffmpeg_kit`
- [ ] Test on Android and iOS targets where possible
- [ ] Record render time, memory observations, and output quality
- [ ] Decide whether to keep `ffmpeg_kit` or fall back to native platform channels

### Notes

- Editing is required for MVP. The spike decides implementation path, not whether the feature ships.

## Phase 3: Sharing, Sync, and Safety HQ

- [x] Implement MIP-04 media encrypt/decrypt bridge
- [-] Implement Blossom upload flow with hash-first asset handling
- [-] Implement publish/share coordinator
- [x] Implement sync coordinator from NDK subscriptions through MDK into Drift projections
- [-] Implement remote/shared feed
- [x] Implement asset download, decrypt, and local cache pipeline
- [-] Implement QR-based group invite flow
- [-] Publish and resolve parent NIP-01 metadata for parent names, group labels, and shared-video attribution
- [x] Publish/fetch `kind:10063` Blossom server lists
- [x] Queue and complete Safety HQ joining asynchronously

### Notes

- Share payloads must include encrypted Blossom server snapshots as well as hashes.
- No public NIP-94 events for shared media.
- Safety HQ is currently provisioned as an app-managed moderator group named `Safety HQ` on first app start after onboarding. This is a deliberate pre-launch bootstrap decision while there are no real moderators or live users yet; later we can swap the provisioner to a network-delivered welcome without changing the report flow.
- The current family invite flow is intentionally pre-launch only: compact invite link/QR -> relay-discovered key package -> welcome returned over Nostr -> inviter approves in Parent Zone. We do not need or plan legacy invite/welcome fallback packets while the app has no live users.
- Parent NIP-01 metadata is only partially wired today: publishing support exists in the Nostr adapter, but onboarding/settings still need to capture a parent display name, publish it reliably, resolve other parents' profiles, and use those names for family group labeling and shared-video attribution.
- Child identities remain local-only by product decision. Cross-family attribution should come from the share payload and the sending parent's metadata, not from child npubs or child-level NIP-01 profiles.
- Video share events should continue carrying child-level display data for UX, and we should tighten that contract so remote feed/player surfaces can show both the child's name and the sending parent's resolved display name together.
- Joining a family should stay a parent-to-parent relationship at the MLS/group layer. The per-child linkage remains an app-local profile-to-primary-group mapping, not a network-visible child identity binding.
- The MDK bridge can now create signed application-message wrapper events and process them back into structured application-message results for Dart-side projection.
- `SyncCoordinator` now projects processed `kind:4543` video share payloads into Drift `remote_assets` and `share_records`, which gives the remote feed a real data pipeline once relay subscriptions are connected.
- Home Feed now renders grouped "From Friends & Family" tiles from joined remote share projections, and the player can open remote entries once local media paths exist while showing a graceful not-downloaded state in the meantime.
- The player's like action is now real: local videos toggle `liked` state for ranking/feed behavior, remote videos publish `kind:4546` to the family group, and incoming like events project into Drift-backed counts.
- Home Feed local tiles now surface the liked-heart badge from the iOS reference, and Parent Zone overview now surfaces Safety HQ + pending report status so the new moderation plumbing is visible in the app shell.
- Parent Zone overview now includes an initial outbound report activity list so queued/delivered moderation traffic can be verified without leaving the app.
- The player now uses a child-friendly, feeling-based report sheet aligned to the old app's flow instead of immediately firing a hard-coded report action.
- Sync now projects inbound `kind:4547` messages into the local report store, and Parent Zone overview surfaces a basic “Let’s Talk” section for incoming family feedback.
- Video lifecycle messages now work end to end in app logic: incoming `kind:4544/4545` events mark shared content deleted and purge cached remote files.
- Parent Zone now includes a manual transport-debug loop for sample share events: create a `kind:4543` wrapper event from the latest local clip, optionally publish it, and import pasted signed event JSON through `SyncCoordinator`.
- The share payload now carries the MIP-04 reference fields needed by `mdk-core` decryption (`orig_hash`, `nonce`, `filename`, `scheme`) as optional blob/thumb properties. This is an implementation extension beyond the original simplified payload sketch so real encrypted media can round-trip through Blossom and MDK today.
- Remote thumbnail prefetch now runs after `video_share` projection, and full remote downloads decrypt into `ApplicationSupport/remote_cache/{thumbs,videos}` with Drift tracking `available/downloading/downloaded/failed`.
- Local Blossom server preferences are now stored in app settings, publishable as `kind:10063`, fetchable by author pubkey over NDK, and used as a runtime fallback when the sender's encrypted snapshot server list is stale.
- Sync subscriptions now refresh when local group membership changes in Parent Zone, which closes the gap where a newly created or newly accepted family group existed locally but had no active `kind:445` relay subscription yet.
- Test coverage now includes relay-delivered `kind:445` events flowing through `SyncCoordinator.start()` subscriptions into Drift projections without manual event paste.
- Family invites now encode as `nook://family-invite?...` deep links, and Parent Zone exposes them via QR, copy, and native share-sheet actions for SMS/WhatsApp-style handoff.
- The player now exposes a real local-video share action that uses `VideoShareCoordinator` to encrypt, upload, create a group message, and publish to the mapped primary family group for that child profile.
- Child profiles now inherit a primary family group when one exists, and new/joined groups seed missing profile-group mappings so local sharing does not depend on a blind "first group" fallback.
- App startup now provisions Safety HQ in the background, stores its group id/status in app settings, refreshes sync subscriptions when created, and flushes queued Safety HQ reports once the moderator group exists.
- `ReportCoordinator` now publishes real `kind:4547` MDK messages to the child's family group when possible, mirrors level-2+ reports into Safety HQ when provisioned, and otherwise keeps them queued locally with explicit statuses like `queued_safety` and `pending_blob_hash`.

## Phase 4: Safety, Moderation, and Editor

- [ ] Ship video editor on the selected path
- [ ] Add parental controls and approval flow
- [ ] Implement three-level reporting UX
- [x] Implement report coordinator
- [x] Separate delete-video and remove-member moderation actions in UI and logic
- [x] Add BUD-09 blob reporting for moderation path only
- [x] Add moderation audit trail

### Notes

- Owner delete, moderation delete, and member removal must remain independent actions.
- Parent Zone Active Connections now opens a management sheet per family group with separate actions for deleting shared videos and removing members.
- Moderation actions are recorded locally in `moderation_audit_logs` and surfaced in Parent Zone Overview.
- The current moderation delete path publishes the app-level lifecycle delete, sends a signed `kind:1984` blob report to the shared Blossom servers as a best-effort BUD-09-style abuse signal, and purges local cache immediately.

## Phase 5: Polish and Paid Features

- [ ] Add subscription/paywall support for cloud features
- [ ] Add relay management UI
- [ ] Add share history
- [ ] Add offline action queue + retry
- [ ] Add multi-server Blossom mirroring
- [ ] Add haptics, confetti, and motion polish
- [ ] Add integration tests for critical end-to-end flows

## Cross-Cutting Workstreams

### Data and Domain

- [-] Define Dart domain models for profiles, videos, reports, ranking, messages
- [x] Port ranking logic from iOS reference
- [-] Define v2 message payload serializers and validators

### Infrastructure

- [x] Decide code generation setup for Drift, Riverpod, Freezed/json if used
- [x] Settle local directory layout for video/media cache files
- [x] Split Riverpod provider definitions into grouped modules behind a stable barrel
- [ ] Add logging and error reporting hooks
- [ ] Add background job / retry orchestration layer

### Security

- [x] Securely store parent secret
- [ ] Document follow-up hardening for hardware-backed storage and recovery
- [x] Ensure child profiles never create or require Nostr keys
- [x] Keep MDK SQLite isolated from app DB access

### QA and Verification

- [x] `flutter analyze`
- [x] `flutter test`
- [x] Build Android debug successfully
- [ ] Build iOS debug successfully
- [-] Verify local record -> feed -> play flow
- [-] Verify share -> relay -> receive -> decrypt -> play flow
- [ ] Verify report routing to family group, Safety HQ, and BUD-09 as applicable

## Immediate Next Steps

- [x] Inspect iOS references and derive initial Flutter plan structure
- [x] Bootstrap Flutter project in `tubestr-v2`
- [x] Implement Phase 1 skeleton before deeper feature work
- [x] Finish capture recording and local file pipeline
- [x] Add thumbnail generation for recorded/imported clips
- [ ] Extend the ranking engine and richer local video model behavior into the feed/player UX
- [-] Replace NDK/MDK placeholders with verified transport and bridge flows

## Implementation Log

### 2026-03-15 to 2026-03-16

- Started by validating the workspace state and confirming `tubestr-v2` was empty.
- Confirmed Flutter, Dart, Rust, and Cargo are available in the environment.
- Reviewed protocol, theme, domain model, report model, ranking, and message references from the iOS app.
- Created this tracked implementation plan.
- Bootstrapped the Flutter project and added the primary app dependencies.
- Resolved a `drift_dev`/Riverpod toolchain conflict by pinning Riverpod to the 2.x line for now.
- Added the initial app architecture: router, providers, theme system, Drift schema, identity storage, NDK boundary, MDK scaffold, Blossom scaffold, safety/share/sync coordinators.
- Implemented a first runnable UI slice: onboarding, home feed, parent zone, camera preview, and player shell.
- Ported the local ranking engine, added a simple player report action, and added PIN setup in Parent Zone.
- Generated Drift code and verified `flutter analyze` + `flutter test`.
- Refactored provider organization into grouped files under `lib/core/di/providers/` while preserving the existing `providers.dart` barrel for callers.
- Broke Parent Zone into dedicated presentation widgets for PIN flows, sidebar, overview, family, connections, and settings sections so the screen is no longer one large god-widget.
- Consolidated repeated MDK/NDK/Blossom test doubles into shared fixtures under `test/test_support/service_fakes.dart`.
- Verified the current `PlayerPage` already disposes `media_kit`'s `Player`; no leak fix was needed there beyond documenting the check.
- Wired the local group create/join actions in Parent Zone to refresh sync subscriptions immediately, so new families can receive relay traffic without restarting the app.
- Added sync tests that verify both subscription refresh after a local join and automatic projection of relay-delivered `kind:445` share events into Drift.
- Added `nook://` deep-link parsing and app-shell handling, plus Android manifest support and focused deep-link tests.
- Switched family invites to shareable `nook://family-invite` links and added a native share action alongside QR/copy in Parent Zone.
- Added primary profile-group mapping helpers in Drift, inherited those mappings for new child profiles, and used them in the player's new secure local-video share action.
- Added an app-managed Safety HQ bootstrap service that provisions a dedicated moderator group locally while the product is still pre-launch and there is no real moderator provisioning backend yet.
- Extended report submission from local-only persistence to real `kind:4547` publication over MDK/NDK, with family-group routing, Safety HQ mirroring/queueing, startup retry flushes, Parent Zone diagnostics, and new service tests.
- Implemented the like flow end to end: a dedicated `LikeCoordinator`, actionable player likes, Drift like projections/counts, and `SyncCoordinator` handling for incoming `kind:4546` events.
- Added a small UI alignment pass from `docs/UIReference.md`: liked video hearts on the local home grid and operational status summaries for Safety HQ/report outbox in Parent Zone Overview.
- Added a first parent-facing moderation outbox view in Parent Zone Overview with recent outbound report statuses.
- Replaced the player’s one-tap report shortcut with a multi-step `FeelingReportSheet` that maps feelings/actions into report levels and routes through the real report coordinator.
- Added inbound report projection in `SyncCoordinator` plus a simple parent-facing incoming feedback list so moderation traffic is visible both outbound and inbound.
- Added a full two-family automated lifecycle test harness with an in-memory relay/Blossom world covering invite -> welcome -> share -> relay sync -> download/decrypt -> like -> report, plus delete propagation that purges the receiver's cached copy.
- Added lifecycle-message handling for `video_revoke` / `video_delete` so remote shares transition to deleted state and local cached files are removed.
- Fixed a real-device invite/join regression by making the inviter refresh sync subscriptions before creating an invite and by making the Rust bridge resolve accepted groups by Nostr group id when the welcome's MLS group id is not directly retrievable after `accept_welcome()`.
- Added MDK bridge support for group member queries and `remove_members`, then used it to wire Parent Zone family moderation actions: remove member, delete shared video, and record both actions in the moderation audit log with new service tests and overview visibility.
- Added a generic Nostr event-signing helper plus Blossom `/report` support so moderation deletes now also send a signed blob abuse report (`kind:1984`) to the relevant Blossom servers alongside the app-level lifecycle delete.
- Fixed the Parent Zone connection screen so pending MDK groups no longer crash the bridge summary path with `group not found`; pending welcomes now remain approval-only while active connection summaries only enumerate active groups.
- Verified `flutter build apk --debug` succeeds.
- Installed local Rust mobile targets, generated `flutter_rust_bridge` bindings, compiled `native/mdk_bridge`, and replaced the MDK placeholder with a working smoke-test bridge (`bridgeVersion`, `initMdkUnencrypted`, group inspection).
- Extended the MDK bridge to return structured group summaries, generate key package event payloads, and create local MDK groups for smoke testing.
- Added Parent Zone MDK diagnostics and a local “Create test group” action so bridge state is visible from the app.
- Added a Parent Zone key package preview action so kind:443 payload generation can be exercised from the app UI.
- Added NDK-backed publishing for MDK key package events so kind:443 payloads can be sent to configured relays from the app.
- Fixed the report coordinator to persist `blobHash` when available and adjusted the player so rebuilds no longer re-open media every frame.
- Implemented local video recording save flow in Capture: select camera, record, persist to app documents, and insert the clip into the selected child profile feed.
- Replaced loose Marmot payload maps with typed v2 message models, parsing/validation helpers, and protocol tests.
- Added local video thumbnail generation and feed thumbnail rendering, plus a Drift database test for saved local video metadata.
- Added manual invite/welcome transport models plus a Parent Zone flow for generating signed key package packets, creating groups with welcome rumors, importing welcome packets, and accepting pending welcomes.
- Added QR scanning for invite and welcome packets inside Parent Zone so the manual two-device group flow no longer depends on copy/paste alone.
- Rebuilt Android Rust `jniLibs` for all configured targets and verified `flutter analyze`, `flutter test`, and `flutter build apk --debug` after the bridge expansion.
- The first thumbnail-enabled Android build also installed missing local Android SDK Platform 33 components during Gradle setup.
- Added `scripts/rebuild_android_bridge.sh` so FRB regeneration, Android Rust library rebuilds, APK rebuilds, and USB reinstall use one repeatable command when Flutter/Rust bridge code changes.
- Added `docs/UIReference.md` as an explicit planning reference so future UI work stays aligned with the old iOS app's tablet-first shells, flows, and component behavior.
- Extended the MDK Rust bridge with application-message creation and processing APIs, plus Dart wrappers for outbound wrapper-event creation and inbound message processing.
- Added generic signed-event publishing to the NDK adapter so MDK-created wrapper events can be broadcast without re-signing.
- Implemented initial share/sync plumbing: `VideoShareCoordinator` can now create MDK application-message events for `kind:4543`, and `SyncCoordinator` projects processed video share payloads into Drift remote asset/share tables.
- Added a Drift helper for remote share projections and a `SyncCoordinator` test covering `video_share` message projection.
- Re-ran FRB codegen, `cargo check`, `flutter analyze`, `flutter test`, Android Rust `jniLibs` rebuild, and `flutter build apk --debug` after the transport bridge changes.
- Added joined remote share projection models/providers, surfaced shared content in the Home Feed as grouped horizontal tiles, and taught the player to fall back to remote-share metadata/local cached media paths when opening a shared video.
- Verified `flutter analyze`, `flutter test`, and `flutter build apk --debug` after the remote feed/player pass.
- Added a Parent Zone transport-debug card that can generate a sample share wrapper event from the latest local video, publish it through NDK, or import a pasted signed group event into `SyncCoordinator` for manual cross-device testing.
- Verified `flutter analyze`, `flutter test`, and `flutter build apk --debug` after the transport-debug additions.
- Extended the MDK Rust bridge and Dart wrapper with real MIP-04 media encryption/decryption APIs backed by `mdk-core` encrypted media manager.
- Updated the share coordinator to encrypt the latest local clip + thumbnail, upload ciphertext to Blossom, attach IMETA-style tags to the outbound rumor event, and include the required decryption reference fields in the payload.
- Added `RemoteMediaService` to prefetch shared thumbnails and download/decrypt remote videos into local cache files, plus Drift helpers to persist remote asset paths and share status transitions.
- Wired the player to let parents download a shared remote video on demand and let `SyncCoordinator` trigger thumbnail prefetch after projecting a `video_share` message.
- Re-ran FRB codegen, `cargo check`, Android Rust `jniLibs` release build, `flutter analyze`, `flutter test`, and `flutter build apk --debug` after the media pipeline pass.
- Added `kind:10063` Blossom server list load/save/publish/fetch support to the NDK adapter, surfaced Blossom server management in Parent Zone Settings, and used fetched server lists as a remote-download fallback path.
- Added a focused `RemoteMediaService` test that proves remote downloads fall back from stale snapshot servers to fetched Blossom servers and still cache both media and thumbnails locally.
- Re-verified `flutter analyze`, `flutter test`, and `flutter build apk --debug` after the Blossom server list and fallback pass.

## Open Risks / Unknowns

- Exact MDK v0.7.1 Flutter/Rust bridge setup may require iteration depending on crate bindings and generated code shape.
- NDK package maturity means all direct usage should stay behind an adapter.
- Video editor package choice still needs spike validation.
- Android/iOS target-specific setup may require native dependencies not visible until first build attempt.
- Linux desktop build is currently blocked by missing `ninja` / C++ toolchain packages in the environment, not by Flutter source errors.
- The FRB codegen binary is installed under `~/.cargo/bin`, but that directory is not in the current shell `PATH`, so codegen commands need either a full path or a shell profile update.
- Capture runtime behavior still needs on-device validation for permissions, saved file playback, and per-device camera quirks.
