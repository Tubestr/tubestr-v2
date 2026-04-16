# Changelog

## 1.0.4 - 2026-04-15

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

## 1.0.3 - 2026-03-19

- Reworked Parent Zone into clearer dashboard, activity, children, family spaces, network, account, and diagnostics sections.
- Added sync diagnostics, refresh trigger tracking, subscription history, and safer offline recovery tooling.
- Polished profile display name syncing, invite handling, haptics, and Android release prep for GitHub and Zapstore distribution.

## 1.0.1 - 2026-03-18

- Published the first signed Android GitHub release with APK and AAB artifacts.

## 1.0.0 - 2026-03-18

- Shipped the initial Android production release.
