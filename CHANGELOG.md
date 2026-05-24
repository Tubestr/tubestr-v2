# Changelog

## 1.0.4 - 2026-04-15

- (Build 33) Added playback speed control inside the editor Effects tool — pick 0.5×, 1×, 1.5×, or 2×; preview scrubs at the selected rate and the exported video carries the same speed for both video and audio.
- (Build 33) Added drawing tools to the editor — pencil, marker, and eraser with a shared six-color palette, 2–24 px width, undo, and clear. Eraser only affects your strokes; the underlying video is left untouched. Drawings burn into the exported MP4 above stickers and text.
- (Build 33) Internal: refactored the ~4,100-line editor page into eleven focused widget files and added a widget-level test harness (58 passing tests) so future editor work has a safety net.
- Added Light, Dark, and System appearance modes in the profile/theme menu.
- Added dark variants for every child theme so Campfire, Treehouse, Blanket Fort, and Starlight adapt consistently.
- Fixed dark-mode onboarding text so headings like "Welcome to Tubestr" inherit the correct themed text color.
- Updated primary themed surfaces, cards, pills, and parent-zone chrome to avoid hardcoded light backgrounds in dark mode.
- Improved Family Spaces compatibility with White Noise by publishing upgraded MLS KeyPackages in both newer `30443` and legacy-compatible `443` formats.
- Added KeyPackage relay-list publishing so compatible clients know where to fetch invite material.
- Made invite QR codes identity-based instead of pinning one KeyPackage event, improving old/new client compatibility.
- Automatically republishes current invite keys when entering Family Spaces or creating an invite, helping replace stale incompatible keys from older builds.
- Made relay publishing more resilient so one bad relay does not fail the whole invite flow when another relay accepts the required event.
- Deduped Family Spaces invites and pending welcomes so repeated scans from old builds do not create or show duplicate group invites.
- Fixed first-group sharing so capture/share no longer says "join a group first" after a successful family-space join.
- Fixed the record view getting stuck on a black "Opening camera" screen when camera permission was allowed but microphone permission was denied; recording now falls back to silent clips and shows a mic-off notice.
- Fixed Sign out & reset app so it fully clears local parent identity before routing back to onboarding.
- Fixed the child setup Complete Onboarding button so it creates the typed child profile and continues directly.
- Made the onboarding age-confirmation text toggle its checkbox when tapped.
- Made support, privacy, and terms links open in the system browser and removed the unused in-app WebView fallback.
- Added app version and build number to Parent Zone diagnostics.
- Avoided MediaKit's Android executable-memory probe so playback can start on GrapheneOS when DCL via memory is restricted.
- Made family-share reactions visible in the player controls and kept them available when playback finishes.
- Removed the inactive Parent tab outline while preserving the active bottom-nav selection border.
- Fixed the video editor Export button alignment on phones and tightened the compact landscape toolbar layout.
- Added 168 bundled Microsoft Fluent Emoji stickers to the editor, with MIT license notes and a reproducible import script.
- Replaced the editor's sticker strip with a searchable, categorized grid picker for easier browsing across larger sticker packs.
- Added a 100-track FOSS audio overlay library for the editor, with searchable names and categories.
- Added on-demand Blossom downloads for editor audio tracks from `https://blossom.tubestr.app`, with local caching and hash verification.
- Added in-editor audio preview controls so tracks can be heard before exporting a video.
- Fixed audio-overlay exports that could hang by bounding looped music to the edited video duration before mixing.
- Fixed Blossom uploads for edited videos by signing the exact encrypted blob bytes and keeping overlay exports within upload-friendly bitrate bounds.
- Backdated short-lived Blossom auth events to tolerate device clock skew and report upload auth failures without mislabeling them as missing family spaces.
- Hid the user's own shared videos from the Home and Editor Hub "Shared" rows so the family feed only surfaces videos from others.
- Added like and emoji-reaction pills to "My videos" on the Home feed so creators can see how family members are reacting to their clips.
- Reworked editor text overlays: multiple text layers per clip, drag/rotate/pinch-to-scale, and a per-overlay delete badge that matches the sticker workflow.
- Replaced the sticker toolbar's Remove button with a tap-to-delete badge on the selected sticker or text overlay, and added an Add text button that places a new draggable text layer.
- Fixed edited-video exports so text overlays render at the exact position, rotation, and scale shown in the editor preview.
- Auto-capitalized parent display name and child name fields during onboarding.
- Fixed the Editor Hub shared-video tile so it fills the column width on narrow screens instead of shrinking around its thumbnail.
- Bundled Nunito and Fredoka fonts as assets and disabled runtime fetching so offline launches no longer throw font-download exceptions or fall back to the system font.
- Refreshed parent display names from relays on app launch and resume, with a 6-hour cache TTL, so names published after a second device first connected no longer stay stuck on the raw npub.
- Showed a clearer message when Safety HQ setup fails because the moderation-service key package is temporarily stale, instead of exposing the underlying MLS error.
- Added a "Leave family space" action to Parent Zone Family Spaces. Leaving publishes a SelfRemove proposal (self-demoting first if admin), hides the space from Home, Editor Hub, capture, and share pickers, and leaves past clips on-device untouched. Solo spaces (just you) abandon locally without MLS ceremony.
- Added Make admin in the family-space management sheet to promote another member, backed by a new MDK bridge binding (`update_group_admins`). Required before a sole admin can leave a multi-member space; admin status shows as a badge on each member tile.
- Gated Remove on admin status so non-admin members no longer see a Remove button that would have failed against MDK's access rules.
- Fixed Parent Zone "Active Family Spaces" still listing a family space immediately after leaving it; the panel now filters out left spaces like the rest of the app.
- Fixed "Connection already sent" blocking reconnects with a family after leaving: the pending-connection marker is cleared when leaving, and any stale marker whose group is no longer tracked locally is auto-cleaned on the next scan.
- Moved the leave-family-space error message inline inside the management sheet — it was previously rendered as a snackbar behind the sheet and couldn't be seen.
- Parent Zone dashboard now prompts "Join or create a family space" as the first Start Here action when the parent has no family spaces yet (Safety HQ doesn't count), with an Open Family Spaces button that jumps to that section.
- Split the Parent Zone dashboard hero so Start Here is its own card above Control Room, making the actionable prompts the first thing a parent sees instead of being tucked beside the metrics.
- Added NIP-65 relay list (kind 10002) publish and fetch so relay settings sync across devices and interoperate with other Nostr clients (Damus, Primal, Amethyst). Read/write markers on imported relay lists are preserved on round-trip.
- Synced the kind-10063 Blossom server list across devices: edits auto-publish (the separate "Publish server list" button is gone), and the list is fetched on app launch/resume so another device's changes roll in.
- Onboarding "restore from backup key" now imports the user's existing relay and Blossom server lists from relays instead of overwriting them with the app's defaults; new parents still publish sensible defaults automatically.
- Relay and Blossom publishes that fail while offline are queued and retried via the existing offline action processor, so edits made airplane-mode propagate once the device reconnects.
- Sped up sharing for parents in multiple family spaces by fanning out per-group encrypt/upload/publish in parallel (bounded concurrency) instead of one-at-a-time, and by loading relay and Blossom server lists once per share instead of per group. Offline action retries also flush in parallel now.
- Made the share action feel instant regardless of how many family spaces you're in: tapping share now enqueues per-group deliveries and drains them in the background via the offline action processor, so the confirmation toast appears right away instead of after every upload completes.
- Fixed the Scan Invite and Scan Backup Key camera previews on Android, which rendered stretched like a landscape feed squeezed into a portrait window on some devices. Replaced `mobile_scanner` (whose Android rotation handshake with Flutter's SurfaceProducer misbehaved on certain Flutter/Android combos) with `package:camera` + Google MLKit barcode scanning, reusing the same preview pipeline the capture view already uses — QR scan now looks the same on Android as it did on iOS.
- Reworked the family-invite QR as a bottom sheet matching the Scan and Paste sheets, with full-width Share link and Copy code actions, and auto-dismisses the moment the other parent's welcome arrives so the user can go straight to accepting it.

## 1.0.3 - 2026-03-19

- Reworked Parent Zone into clearer dashboard, activity, children, family spaces, network, account, and diagnostics sections.
- Added sync diagnostics, refresh trigger tracking, subscription history, and safer offline recovery tooling.
- Polished profile display name syncing, invite handling, haptics, and Android release prep for GitHub and Zapstore distribution.

## 1.0.1 - 2026-03-18

- Published the first signed Android GitHub release with APK and AAB artifacts.

## 1.0.0 - 2026-03-18

- Shipped the initial Android production release.
