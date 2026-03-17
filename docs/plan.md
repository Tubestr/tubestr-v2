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
- `/home/lee/apps/tubestr-v2/docs/EditorResearch.md`
- `/home/lee/apps/tubestr-ios/MyTube/Domain/Models.swift`
- `/home/lee/apps/tubestr-ios/MyTube/Domain/ReportModels.swift`
- `/home/lee/apps/tubestr-ios/MyTube/Domain/RankingEngine.swift`
- `/home/lee/apps/tubestr-ios/MyTube/SharedUI/Theme/KidTheme.swift`
- `/home/lee/apps/tubestr-ios/MyTube/Services/Marmot/MarmotMessageModels.swift`

## Status Snapshot

- Date: 2026-03-17
- Workspace state: Flutter app bootstrapped, Drift code generated, analysis green
- iOS app available for reference at `/home/lee/apps/tubestr-ios`
- Current focus: launch triage around parent-key recovery/export UX, iOS/device validation, end-to-end verification for share/report flows, and the calmer Parent Zone / capture-first redesign pass
- Design critique pass complete: FrostCard addiction fixed, per-theme animations, differentiated tab personalities, ghost grid empty state, parent tab boundary

## Execution Rules

- Keep this file updated as tasks move.
- Use `[ ]` for pending, `[-]` for in progress, `[x]` for complete.
- Record key implementation notes and deviations under the phase they affect.
- Prefer vertical slices that leave the app runnable after each major checkpoint.
- Treat `docs/UIReference.md` as the required source of truth for screen structure, tablet-first layout, onboarding flow, and shared component behavior whenever UI work is in scope.

## Launch Triage (2026-03-17)

### Must Have Before Launch

- [-] Complete parent key import/export/recovery UX
- [x] Wire onboarding restore flow instead of leaving `onRestore` null
- [x] Expose full parent private-key reveal / hide / copy / share flow in Parent Zone per `docs/UIReference.md`
- [x] Add intentional backup/recovery messaging for the parent `nsec`
- [ ] Build iOS debug successfully and validate on real iOS hardware
- [-] Verify share -> relay -> receive -> decrypt -> play flow end to end on real devices
- [-] Verify report routing to family group, Safety HQ, and BUD-09 where applicable
- [ ] Make final editor ship/no-ship decision after device validation

### Strongly Recommended

- [x] Add a fuller likes UX (for example a dedicated likes section/list) beyond the current count-only/player entry point
- [ ] Decide whether remote unlike semantics are required for launch or explicitly defer them
- [ ] Improve remote download / retry / error / approval states and friend-family activity visibility
- [ ] Add safety explainer/help copy that clearly tells parents how moderation and sharing protections work
- [ ] Add logging/error reporting hooks for launch diagnostics
- [ ] Harden retry/background behavior beyond the current startup/resume/manual reconnect paths

### Can Slip Post-Launch

- [ ] View counts, unless we later decide they are required for ranking or trust
- [x] Emoji or richer reactions beyond likes
- [ ] Subscription/paywall work
- [ ] Deeper background orchestration

### Notes

- Parent/child identity scope changed in v2: child-key backup/recovery is not an MVP gap because children no longer have independent Nostr keys. The remaining identity blocker is the parent key story.
- The secure-storage foundation already exists for launch-critical identity work: `IdentityService` persists the parent identity via `flutter_secure_storage`, and `ParentAuthService` hashes/stores the Parent Zone PIN there as well.
- Current code evidence now covers most of the parent-key UX: onboarding can restore from pasted/scanned backup keys, the parent flow shows explicit backup messaging, and both onboarding + Parent Zone expose reveal/hide/copy/share key export cards. This line stays in progress until we validate the full recovery story on real Apple devices and decide whether sign-out/reset should also clear synced identity copies.
- Engagement now has a fuller UX surface: the player shows a likes summary, feed cards surface engagement at a glance, playback metrics are visible, and reactions publish/project alongside likes. The remaining product decision is whether remote unlike semantics matter for launch.
- View counts appear absent from both projection/state and UI. They should not block MVP unless product/ranking needs change.
- Automated verification is stronger than the checklist originally implied: the in-memory two-family harness already covers invite -> welcome -> share -> sync -> download/decrypt -> like -> report -> delete propagation, and dedicated report-coordinator tests cover family-group plus Safety HQ routing. The remaining verification gap is real-device proof, especially on iOS.
- User-facing retry/error handling is partially present today through feed status badges, player/capture-specific share/download messaging, and Parent Zone offline-queue surfaces. The remaining work is consistency and polish, not a complete lack of states.
- Logging/diagnostics are still thin overall. The one notable exception is editor export, which already writes a diagnostics log when FFmpeg plans fail.
- A broad redesign pass is now in progress for launch polish: Home is being made more capture/edit-led for kids, and Parent Zone is being split into a calmer control-room mode with quieter typography, clearer status triage, and less decorative overlap with the child-facing app.
- Onboarding, Capture, and Player now have a parallel hardening/polish pass underway as part of that redesign work: friendlier bootstrap/recovery states, less technical error copy, overflow-safe parent-backup layout, calmer player download fallbacks, and tighter width handling on tablet-sized surfaces.

### Design Critique Pass (2026-03-17)

A holistic UI critique identified several AI-slop anti-patterns and design hierarchy issues. All have been addressed:

**FrostCard addiction — resolved.** `FrostCard` was wrapping heroes, empty states, CTAs, and video cards indiscriminately. Removed from: home feed hero, home empty state, home add-friends CTA, home error state, editor hub hero, editor hub continue strip, editor hub empty state, editor hub video cards, editor hub error state. Cards now reserved for discrete data objects (profile list items in onboarding, permission rows).

**Identical hero patterns — resolved.** Home feed and Editor Hub both had the same card-with-heading-description-buttons structure. Home now shows a hero only for new users (no videos); returning users see their content immediately. Editor Hub leads with a large latest-clip preview when clips exist, not a text-based hero.

**Generic animated blobs — resolved.** `NookAppBackground` replaced with per-theme animation personalities:
- Campfire: fast flicker (6s), two-frequency sine for choppiness, asymmetric placement
- Treehouse: gentle horizontal sway (10s), counter-swinging blobs, leaf rotation
- Blanket Fort: very slow breathe (18s), large soft blobs, low opacity
- Starlight: 6 scattered blobs with staggered rapid opacity pulses (4s), purple/gold alternating

**Home feed empty state — resolved.** Full-area ghost grid showing 4 placeholder tiles at 9:16 aspect ratio, with one accent-colored CTA tile. Single primary action. No competing hero + empty state pattern.

**Parent tab boundary — resolved.** Visual separator (1px vertical line) between kid tabs and parent tab. Parent tab has distinct outline border when inactive (vs transparent for other tabs). Smaller icon size (21 vs 23) reinforces the different weight.

**Minor fixes applied:**
- Onboarding intro slide scale: 0.96 → 0.88 inactive (visible depth)
- Onboarding intro slide opacity: 0.72 → 0.55 inactive (stronger contrast)
- Video tile aspect ratio: 0.8 → 9/16 to match capture
- Confetti: 48 → 120 particles, 1.5s → 2.5s, shape variety (circles/squares/rectangles)
- Profile switcher: larger avatar (radius 16), accent border ring, bolder label text
- KidScaffold: removed static decorative blobs (NookAppBackground handles bg)
- Editor side toolbar: already had labels — no change needed
- PIN keypad: already meets 44px touch targets — no change needed

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
- Capture now uses a fill-and-crop camera preview instead of stretching `CameraPreview`, which should make portrait and front-camera shots look correct while recording.
- The main media surfaces now favor aspect-preserving presentation over hard crop: home-feed cards, shared-video tiles, editor-hub cards, player download placeholders, and the editor timeline all use letterboxed thumbnail framing so portrait media stops looking wrong before playback even starts.
- Thumbnail generation is wired for captured local clips and displayed in the feed.
- Editor handoff is still pending.
- Player route exists; real playback works only once captured/imported files are stored with valid paths.
- Player playback now uses the actual media dimensions when available instead of forcing every clip into `16:9`, and Android debug builds prefer software video rendering to reduce emulator black-screen decode issues while we keep hardening remote playback.
- Capture now keeps users inside one flow after recording: save -> process -> on-device scan -> next-step card with Watch, Edit, and Share actions instead of dumping them back into the tab with no guidance.
- `nook://` deep-link handling is now wired through `app_links` into the app shell and opens Parent Zone, with Android intent-filter support. Additional custom schemes are out of scope for this launch.
- Home now keeps the creation loop visible whether or not the child already has videos: the empty state and the first viewport both point toward Capture and Edit instead of leaving creation as a hidden secondary action.
- Editor Hub now leans further into a studio entrance: it exposes a clearer “capture first / continue editing” path and a more instructional empty state rather than another generic card grid intro.
- The remaining high-traffic support states are also being normalized toward the same design language: onboarding bootstrap/recovery, capture setup/share failures, and player download/report/like feedback now aim for calm, parent-readable language instead of raw technical output.

## Phase 2.5: Editor Spike

- [-] Prototype trim + LUT filter + audio overlay with `ffmpeg_kit`
- [ ] Test on Android and iOS targets where possible
- [ ] Record render time, memory observations, and output quality
- [ ] Decide whether to keep `ffmpeg_kit` or fall back to native platform channels

### Notes

- Editing is required for MVP. The spike decides implementation path, not whether the feature ships.
- Research conclusion is now captured in `docs/EditorResearch.md`.
- Current recommendation: build the editor as custom Flutter UI plus Dart edit-state models, keep `media_kit` for preview, use `just_audio` for music preview, and use `ffmpeg_kit_flutter_new_video` as the export engine.
- We should not center the editor around `video_editor_2` or `easy_video_editor`; both are too narrow for MyTube's trim + filters + stickers + text + audio requirements.
- `google_mlkit_selfie_segmentation` is the best current fit for the selfie-sticker flow once the base editor loop is working.
- If the FFmpeg export spike fails on performance, quality, or stability, we should preserve the Flutter UI and swap only the renderer behind platform channels.
- The old iOS LUTs, sticker PNGs, and bundled music tracks are now copied into Flutter assets under `assets/editor/`.
- Initial editor foundation models now exist for trim state, overlays, audio selection, effect sliders, and catalogued built-in resources.
- The Editor tab now opens a real full-screen editor detail page for local videos, with trim/effects/overlays/audio/text tool panels overlaid on the video itself and local edit-session state.
- The first interactive editor preview supports live sticker placement with drag, scale, and rotation on top of `media_kit` playback; export is still the next step.
- `ffmpeg_kit_flutter_new_video` and `just_audio` are now added to the app so the next slice can wire real export and soundtrack preview instead of changing package strategy again.
- User feedback changed the design direction from a side-by-side tablet workspace to a more immersive TikTok-style editor. We should continue honoring that preference for future editor UI work while still keeping tablet ergonomics in spacing and sizing.
- Trim normalization utilities now guard against zero or bad clip duration metadata so the editor does not crash when the slider initializes.
- The audio tool now previews built-in soundtrack assets through `just_audio`, and the editor can stop or switch previews cleanly while editing.
- The first export path now exists: trim + LUT/effect adjustments + soundtrack export via `ffmpeg_kit_flutter_new_video`, saving a new local remix and thumbnail back into Drift.
- Sticker and text overlays are now rasterized into a transparent compositor image and burned into exported remixes, which closes the biggest preview/export mismatch in the editor.
- Export now mixes original clip audio with the selected soundtrack when the source clip has audio, and falls back cleanly to soundtrack-only export when it does not.
- Selfie sticker capture is now wired as a full-screen front-camera flow using `google_mlkit_selfie_segmentation`, with generated transparent PNG stickers stored per child profile under app support storage and immediately reusable in the editor.
- The immersive preview now applies an approximate live look stack for the selected filter/effect settings, which brings the on-screen preview much closer to the exported result even though FFmpeg LUT output remains the source of truth for final renders.
- The preview player now loops within the selected trim range and exposes an over-video play/pause affordance, so trim changes affect the editing experience immediately instead of only affecting export.
- Sticker behavior now supports stacking multiple stickers instead of a single replacement sticker slot, and the overlay tool removes the selected sticker rather than wiping all stickers at once.
- FFmpeg export now normalizes render size down to an even, capped output resolution before applying filters and overlays, which should make filter-heavy exports more stable on Android devices and emulators.
- The export filter graph now uses named `eq=` parameters and more defensive overlay staging, which fixes a real failure mode where effect-heavy exports could throw `EditorExportException` or destabilize the app.
- Editor export now pauses the live preview player first and retries through simpler compatibility plans if the full FFmpeg stack fails, so the editor can still save a remix instead of hard-failing on the first unsupported filter/effect combination.
- Editor export now reads rotation metadata from FFprobe and applies orientation-aware sizing/transpose filters, which should stop portrait captures from exporting as stretched landscape remixes.
- Compatibility export now writes a diagnostics log when every FFmpeg plan fails, which gives us a concrete device-specific trail instead of a generic export exception.
- Editor preview now preserves the actual media aspect ratio inside the immersive canvas instead of stretching every clip to fill the viewport, which should make portrait and landscape edits line up better with capture/playback/export.
- Selfie sticker capture now uses the same fill-and-crop camera-preview treatment as the main capture screen, which should stop the front-camera preview from looking stretched.
- Sticker placement is now truly multi-sticker in the editor again, and removing a sticker removes the selected sticker instead of wiping all sticker overlays.
- Editor export fallback no longer "succeeds" by dropping stickers, text, and effects. All retry paths now preserve the requested visual edit and only trade off render size / codec; if that still fails, export fails loudly with diagnostics.
- Editor export now passes `-noautorotate` into FFmpeg before the input is opened, so our manual rotation handling is the single source of truth instead of fighting FFmpeg's own autorotation logic on portrait captures.
- Exported remixes now go through the same on-device scan pipeline as captured clips and save as pending-then-classified instead of bypassing the safety flow.
- Current editor gaps: selfie subject lifting still needs more on-device validation for edge quality/performance, and preview LUT rendering remains an approximation rather than pixel-exact parity with FFmpeg export.

## Phase 3: Sharing, Sync, and Safety HQ

- [x] Implement MIP-04 media encrypt/decrypt bridge
- [-] Implement Blossom upload flow with hash-first asset handling
- [-] Implement publish/share coordinator
- [x] Implement sync coordinator from NDK subscriptions through MDK into Drift projections
- [-] Implement remote/shared feed
- [x] Implement asset download, decrypt, and local cache pipeline
- [-] Implement QR-based group invite flow
- [x] Publish and resolve parent NIP-01 metadata for parent names, group labels, and shared-video attribution
- [x] Publish/fetch `kind:10063` Blossom server lists
- [x] Queue and complete Safety HQ joining asynchronously

### Notes

- Share payloads must include encrypted Blossom server snapshots as well as hashes.
- No public NIP-94 events for shared media.
- Safety HQ is currently provisioned as an app-managed moderator group named `Safety HQ` on first app start after onboarding. This is a deliberate pre-launch bootstrap decision while there are no real moderators or live users yet; later we can swap the provisioner to a network-delivered welcome without changing the report flow.
- The current family invite flow is intentionally pre-launch only: compact invite link/QR -> relay-discovered key package -> welcome returned over Nostr -> inviter approves in Parent Zone. We do not need or plan legacy invite/welcome fallback packets while the app has no live users.
- Parent NIP-01 metadata now has a real service layer for local save, publish, cache, and resolve; the remaining gap is broader usage in connection/group labeling beyond remote-share attribution.
- Child identities remain local-only by product decision. Cross-family attribution should come from the share payload and the sending parent's metadata, not from child npubs or child-level NIP-01 profiles.
- Video share events should continue carrying child-level display data for UX, and we should tighten that contract so remote feed/player surfaces can show both the child's name and the sending parent's resolved display name together.
- Joining a family should stay a parent-to-parent relationship at the MLS/group layer. The per-child linkage remains an app-local profile-to-primary-group mapping, not a network-visible child identity binding.
- The MDK bridge can now create signed application-message wrapper events and process them back into structured application-message results for Dart-side projection.
- `SyncCoordinator` now projects processed `kind:4543` video share payloads into Drift `remote_assets` and `share_records`, which gives the remote feed a real data pipeline once relay subscriptions are connected.
- Home Feed now renders grouped "From Friends & Family" tiles from joined remote share projections, and the player can open remote entries once local media paths exist while showing a graceful not-downloaded state in the meantime.
- The player's like action is now real: local videos toggle `liked` state for ranking/feed behavior, remote videos publish `kind:4546` to the family group, and incoming like events project into Drift-backed counts.
- Home Feed local tiles now surface the liked-heart badge from the iOS reference, and Parent Zone overview now surfaces Safety HQ + pending report status so the new moderation plumbing is visible in the app shell.
- Parent Zone visual language now diverges more intentionally from the kid-facing app for launch polish: quieter shell, calmer sidebar, triaged overview, more readable settings/connections/family sections, softer PIN entry/setup, and less raw/technical parent backup presentation.
- Parent Zone overview now includes an initial outbound report activity list so queued/delivered moderation traffic can be verified without leaving the app.
- The player now uses a child-friendly, feeling-based report sheet aligned to the old app's flow instead of immediately firing a hard-coded report action.
- Sync now projects inbound `kind:4547` messages into the local report store, and Parent Zone overview surfaces a basic “Let’s Talk” section for incoming family feedback.
- Video lifecycle messages now work end to end in app logic: incoming `kind:4544/4545` events mark shared content deleted and purge cached remote files.
- The share payload now carries the MIP-04 reference fields needed by `mdk-core` decryption (`orig_hash`, `nonce`, `filename`, `scheme`) as optional blob/thumb properties. This is an implementation extension beyond the original simplified payload sketch so real encrypted media can round-trip through Blossom and MDK today.
- Remote thumbnail prefetch now runs after `video_share` projection, and full remote downloads decrypt into `ApplicationSupport/remote_cache/{thumbs,videos}` with Drift tracking `available/downloading/downloaded/failed`.
- Remote media cache now validates basic file signatures before trusting downloaded video/thumb files, clears stale invalid cache entries, and lets the player repair bad remote downloads instead of silently reusing broken local files.
- Local Blossom server preferences are now stored in app settings, publishable as `kind:10063`, fetchable by author pubkey over NDK, and used as a runtime fallback when the sender's encrypted snapshot server list is stale.
- Sync subscriptions now refresh when local group membership changes in Parent Zone, which closes the gap where a newly created or newly accepted family group existed locally but had no active `kind:445` relay subscription yet.
- Test coverage now includes relay-delivered `kind:445` events flowing through `SyncCoordinator.start()` subscriptions into Drift projections without manual event paste.
- Family invites now encode as `nook://family-invite?...` deep links, and Parent Zone exposes them via QR, copy, and native share-sheet actions for SMS/WhatsApp-style handoff.
- The player now exposes a real local-video share action that uses `VideoShareCoordinator` to encrypt, upload, create a group message, and publish to the mapped primary family group for that child profile.
- Sharing now refuses local videos that are still pending approval, which ties the local parental-control flow into the network share path instead of leaving approval as a cosmetic state.
- Child profiles now inherit a primary family group when one exists, and new/joined groups seed missing profile-group mappings so local sharing does not depend on a blind "first group" fallback.
- App startup now provisions Safety HQ in the background, stores its group id/status in app settings, refreshes sync subscriptions when created, and flushes queued Safety HQ reports once the moderator group exists.
- `ReportCoordinator` now publishes real `kind:4547` MDK messages to the child's family group when possible, mirrors level-2+ reports into Safety HQ when provisioned, and otherwise keeps them queued locally with explicit statuses like `queued_safety` and `pending_blob_hash`.
- Remote feed headers and the player subtitle now resolve cached/query-backed parent display names so cross-family shares can show the sending parent and child together.
- Parent Zone Settings now includes real relay management controls for add/remove/reset/reconnect, which makes local relay experimentation and recovery possible without leaving the app.
- Parent Zone Overview now includes recent outbound share history, and local share attempts now record `sent` vs `queued` entries so retry behavior is visible without digging through logs.
- App startup and app resume now both flush the offline action queue, and a manual relay reconnect in Parent Zone also retries queued work immediately so recovery is less dependent on one specific app launch moment.
- Share uploads now mirror encrypted media and thumbnails across all configured Blossom servers on a best-effort basis, and only successfully uploaded servers are written into the encrypted payload snapshot for receivers.
- Blossom uploads now use the public-server-compatible `PUT /upload` endpoint with signed Nostr authorization and only fall back to legacy `PUT /<hash>` behavior if a server explicitly returns `404`.
- Blossom upload auth now matches current BUD-11/BUD-02 expectations more closely: base64url `Authorization: Nostr ...`, `server` scoping tags, and `X-SHA-256` / `X-Content-*` headers on `PUT /upload`.
- Blossom upload auth uses the bare hostname in the `server` tag (for example `blossom.tubestr.app`) and also carries `u=https://.../upload` plus `method=PUT` for server implementations that validate the exact upload endpoint as part of auth.
- Family connections and recent share history now surface stronger parent/group labels, and new family groups try to inherit the inviter's published parent profile name instead of generic "Family Space" naming.
- Parent Zone now actively polls for pending welcomes immediately after generating an invite, so approvals surface without needing a manual section refresh if the other parent scans right away.
- Connection and moderation member surfaces now prefer resolved parent display names and fall back to `npub` formatting instead of raw hex pubkeys.
- Family invites now carry the inviter's local display name directly, best-effort republish parent NIP-01 metadata during invite/connect, and compose group names from both parents' names so the happy path is `Parent 1 & Parent 2` instead of `Family Space`.
- Dev-only sample-share/debug-import controls have been removed from Parent Zone now that the real invite/share/download flow is working on-device.
- Capture preview, selfie capture, thumbnail framing, and editor playback now all preserve media aspect ratios instead of stretching portrait media to fill generic landscape surfaces.
- Editor export now disables FFmpeg autorotate, clears output `rotate` metadata, and forces square-pixel output (`setsar=1`) so portrait remixes stay portrait through export and playback.
- Player share no longer relies on one stale child-primary group mapping; it now targets every active non-Safety family group with more than one member, which avoids accidentally publishing only into an old solo group.

## Phase 4: Safety, Moderation, and Editor

- [ ] Ship video editor on the selected path
- [x] Add parental controls and approval flow
- [x] Implement three-level reporting UX
- [x] Implement report coordinator
- [x] Separate delete-video and remove-member moderation actions in UI and logic
- [x] Add BUD-09 blob reporting for moderation path only
- [x] Add moderation audit trail

### Notes

- Owner delete, moderation delete, and member removal must remain independent actions.
- Parent Zone Family now exposes a real pending-approval queue for local clips, content scan summaries, and approve/reject actions. Capture writes new clips as pending first, scans them immediately, and auto-approval only happens when the parent has explicitly disabled approval requirements.
- Parent approval is now enforced in the actual share path, not only shown in UI: pending or rejected clips cannot be shared until a parent approves them.
- Content scanning now incorporates title keywords alongside existing media metadata and produces more specific review reasons, which are surfaced as risk/reason chips in the parent approval queue instead of only a generic summary line.
- Parent approval is now disabled by default, but on-device scanning still always runs before share. Safe clips auto-approve unless the parent opts back into mandatory review, while flagged clips still remain pending.
- Share preflight now backfills a missing scan before upload, which closes the gap where remixes or older library items could otherwise miss the scan-before-share rule.
- The child-facing report sheet now exposes the three escalation levels clearly in-product, with explicit destination messaging for family feedback, parent help, and Safety HQ alerts.
- Parent Zone Active Connections now opens a management sheet per family group with separate actions for deleting shared videos and removing members.
- Moderation actions are recorded locally in `moderation_audit_logs` and surfaced in Parent Zone Overview.
- The current moderation delete path publishes the app-level lifecycle delete, sends a signed `kind:1984` blob report to the shared Blossom servers as a best-effort BUD-09-style abuse signal, and purges local cache immediately.
- Editor research is complete. The chosen build path is a hybrid architecture: Flutter editor UI + Dart edit models + `ffmpeg_kit_flutter_new_video` export spike, with native renderer fallback only if the spike fails.

## Phase 5: Polish and Paid Features

- [ ] Add subscription/paywall support for cloud features
- [x] Add relay management UI
- [x] Add share history
- [-] Add offline action queue + retry
- [x] Add multi-server Blossom mirroring
- [-] Add haptics, confetti, and motion polish
- [x] Add integration tests for critical end-to-end flows

### Notes

- Offline queue persistence and manual/startup retry are now real for parent-profile publish, share, like, and report actions, but this line stays in progress until retry reacts more broadly to reconnect events and more critical flows are covered by end-to-end tests.
- End-to-end coverage now includes queued family actions replaying after relay recovery: parent-profile publish, share, like, and report all queue while the loopback relay is offline and flush successfully once connectivity is restored.
- Relay management and share history are now complete enough for MVP: settings can add/remove/reset/reconnect relays, and Parent Zone Overview shows recent outbound shares with sent/queued states.
- Multi-server Blossom mirroring is now live in the share path: each encrypted asset attempts uploads to every configured server, the payload snapshot only keeps successful servers, and download fallback still works against that ordered list plus fetched `kind:10063` servers.
- The in-memory two-family harness now covers the core family lifecycle well enough to count as critical end-to-end coverage for development: invite/welcome, share, relay sync, download/decrypt, like, report, delete propagation, offline replay, and delete-vs-remove moderation independence.
- Haptics/confetti/motion polish is in progress: onboarding now celebrates completion with a lightweight confetti overlay, and key success flows like sharing, joining, downloading, moderation, and report submission now trigger tactile feedback.

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

### Notes

- Recovery/export hardening should stay framed around the parent key only. Do not reintroduce child-key recovery requirements unless the product model changes again.

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
- [-] Finish parent key import/export/recovery UX and backup messaging
- [ ] Build and validate on iOS hardware
- [-] Verify share/report flows end to end on real devices
- [ ] Make editor ship/no-ship call from device-validation results
- [ ] Extend the ranking engine and richer local video model behavior into the feed/player UX
- [-] Replace NDK/MDK placeholders with verified transport and bridge flows

## Launch Gap Checklist

### Blockers

- [-] Finish parent key import/export/recovery UX, including explicit `nsec` reveal/copy/share and backup messaging
- [x] Add sign out / reset app flow that clears identity, local app state, queued actions, and cached media cleanly
- [-] Keep the new dedicated onboarding permissions step and verify camera/microphone prompts no longer appear from unrelated screens
- [x] Relock Parent Zone immediately on tab exit and keep 4-digit PIN entry auto-submitting without an extra confirmation tap
- [ ] Build and validate on iOS devices, especially capture, playback, editor export, and permission prompts
- [ ] Verify `share -> relay -> receive -> decrypt -> play` on real devices
- [-] Verify report routing to family group, Safety HQ, and BUD-09 on real devices
- [-] Add clearer user-facing retry/error states for queued shares, failed downloads, blocked approvals, and queued reports

### Strongly Recommended For MVP

- [x] Add the onboarding restore path instead of leaving restore as a stub
- [x] Add key export surfaces in Parent Zone that match `docs/UIReference.md`
- [ ] Add a lightweight “How Nook protects your child” / safety disclosure screen or section
- [x] Improve likes UX beyond the current bare count so families can understand engagement more clearly
- [ ] Add logging and diagnostics hooks for relay failures, export failures, download failures, and share failures
- [ ] Polish remote download, approval, and empty/error states across Home Feed, Player, and Parent Zone

### Later / Nice To Have

- [x] Add view counts that surface local playback metrics in Player and Home Feed
- [x] Add richer reactions beyond likes
- [ ] Ship subscription/paywall support for cloud features
- [ ] Add broader background retry orchestration beyond the current startup/resume/manual reconnect flushes

## Implementation Log

### 2026-03-17

- Added a launch-triage section that separates must-have blockers from strongly recommended and post-launch items.
- Documented the parent-only identity nuance explicitly so MVP work stays focused on parent `nsec` export/recovery rather than the retired child-key model.
- Captured the current evidence-based launch gaps around onboarding restore, parent key export UX, iOS validation, end-to-end share/report verification, likes UX, and observability/retry hardening.
- Landed the next engagement pass: remote reactions now publish/project with offline retry, the player shows a real likes summary plus reaction chips, and playback metrics now surface as view/completion/replay counts for local and remote playback.
- Added a destructive Parent Zone reset flow that clears the parent identity and PIN, wipes Drift app state plus local media/cache folders, resets MDK local state, and drops the app back to onboarding.

### 2026-03-15 to 2026-03-16

- Started by validating the workspace state and confirming `tubestr-v2` was empty.
- Confirmed Flutter, Dart, Rust, and Cargo are available in the environment.
- Reviewed protocol, theme, domain model, report model, ranking, and message references from the iOS app.
- Reviewed the old editor architecture and current Flutter package landscape, then documented the editor recommendation in `docs/EditorResearch.md`.
- Copied the old app's LUT, sticker, and music assets into the Flutter project and added initial editor session/resource models.
- Wired the Editor Hub into a real full-screen Editor Detail screen with local trim/effects/overlay/audio/text state and sticker gesture interaction.
- Fixed the trim slider crash path by normalizing zero-duration and out-of-range trim metadata before building `RangeSlider` values.
- Added the first editor runtime dependencies (`ffmpeg_kit_flutter_new_video`, `just_audio`) and re-verified Android debug builds after the package change.
- Added `EditorAudioPreviewService` for soundtrack preview and `EditorExportService` for the first real FFmpeg-backed remix export path.
- Extended `EditorExportService` to probe source dimensions, rasterize preview overlays into a staged PNG, and include that overlay in FFmpeg export.
- Extended `EditorExportService` again to probe source audio presence and build a true original-audio + soundtrack `amix` graph when possible.
- Added export-plan tests to lock trim/LUT/soundtrack/overlay/audio-mix FFmpeg argument generation.
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
- Fixed Parent Zone's live connection refresh path so sync-driven welcome updates no longer throw an async `setState` error, and added targeted pending-welcome polling right after invite creation to make approvals surface automatically on the inviter device.
- Switched visible parent-key fallbacks from raw hex to `npub` formatting and used resolved NIP-01 names more aggressively in pending-invite, active-connection, and family moderation member views.
- Hardened the editor export pipeline by capping render size, fixing malformed FFmpeg `eq` filter syntax, and making overlay staging more defensive for sticker-heavy/filter-heavy edits.
- Tightened the family naming path so invite packets include the inviter's local display name, connect flow composes the family group name from both parents' names, and invite/create now best-effort republish parent metadata to relays for faster NIP-01 resolution on the other device.
- Added compatibility fallback behavior to the editor export service: if the full export path fails, it now retries without risky visual effects and then with a safer codec, while surfacing a warning instead of only throwing a raw FFmpeg error.
- Updated the Blossom upload client toward public-server compatibility: uploads now target `PUT /upload`, include Nostr auth headers, and only fall back to the legacy hash path if a server returns `404`.
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
- Extended the MDK Rust bridge and Dart wrapper with real MIP-04 media encryption/decryption APIs backed by `mdk-core` encrypted media manager.
- Updated the share coordinator to encrypt the latest local clip + thumbnail, upload ciphertext to Blossom, attach IMETA-style tags to the outbound rumor event, and include the required decryption reference fields in the payload.
- Added `RemoteMediaService` to prefetch shared thumbnails and download/decrypt remote videos into local cache files, plus Drift helpers to persist remote asset paths and share status transitions.
- Wired the player to let parents download a shared remote video on demand and let `SyncCoordinator` trigger thumbnail prefetch after projecting a `video_share` message.
- Re-ran FRB codegen, `cargo check`, Android Rust `jniLibs` release build, `flutter analyze`, `flutter test`, and `flutter build apk --debug` after the media pipeline pass.
- Added `kind:10063` Blossom server list load/save/publish/fetch support to the NDK adapter, surfaced Blossom server management in Parent Zone Settings, and used fetched server lists as a remote-download fallback path.
- Added a focused `RemoteMediaService` test that proves remote downloads fall back from stale snapshot servers to fetched Blossom servers and still cache both media and thumbnails locally.
- Re-verified `flutter analyze`, `flutter test`, and `flutter build apk --debug` after the Blossom server list and fallback pass.
- Added a real parent-approval/content-scan loop: new captures save as pending, scan results persist in Drift, Parent Zone Family exposes approve/reject actions, and the share path now refuses clips until they are approved.
- Added parent-profile metadata save/publish/cache/resolve behavior, surfaced parent display-name editing in onboarding and Parent Zone, and used resolved parent names in remote feed/player attribution.
- Added persistent offline action storage and retry for parent-profile publish, share, like, and report actions, along with Parent Zone visibility into queued work and recent outbound share history.
- Added relay management controls for add/remove/reset/reconnect in Parent Zone Settings, and wired reconnect to refresh subscriptions and retry the offline queue immediately.
- Added app-shell retry hardening so startup and app resume both flush queued actions and refresh queue/share-history-backed UI state.
- Extended the two-family end-to-end harness to cover relay-recovery replay for queued parent-profile publish, share, like, and report actions once connectivity returns.
- Extended Blossom uploads to mirror encrypted media and thumbnails across all configured servers, keeping only successful upload endpoints in the encrypted share payload and adding share-coordinator coverage for full and partial mirror success.
- Extended the two-family harness again to prove the locked moderation rule that deleting a video does not remove a family member, and removing a member does not retroactively delete already-shared content.
- Tightened the feeling-based report sheet so the three escalation levels are explicit in the confirm step, and added direct tests for family vs parent-helper vs Safety HQ routing labels.
- Added a lightweight confetti overlay component and started using it for onboarding completion, plus broader success haptics across share/join/download/report/moderation flows.
- Improved parent/group identity polish by deriving new family names from published parent metadata when available and surfacing better family labels in active connections and recent share history.
- Improved approval/scanning quality by incorporating title keywords into scan signals, generating clearer review summaries, and surfacing risk/reason chips directly in Parent Zone's approval queue.

## Open Risks / Unknowns

- Exact MDK v0.7.1 Flutter/Rust bridge setup may require iteration depending on crate bindings and generated code shape.
- NDK package maturity means all direct usage should stay behind an adapter.
- Video editor package choice still needs spike validation.
- Android/iOS target-specific setup may require native dependencies not visible until first build attempt.
- Linux desktop build is currently blocked by missing `ninja` / C++ toolchain packages in the environment, not by Flutter source errors.
- The FRB codegen binary is installed under `~/.cargo/bin`, but that directory is not in the current shell `PATH`, so codegen commands need either a full path or a shell profile update.
- Capture runtime behavior still needs on-device validation for permissions, saved file playback, and per-device camera quirks.
