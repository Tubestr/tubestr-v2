 Close the Trust & Safety Loop

 Context

 The child-facing report flow (FeelingReportSheet) promises three escalation levels — "Just Tell
 Them", "Hide Their Videos", "Block Them" — but only level 3's network publish actually works,
 and even that has no enforcement after the report is filed. The content scanner correctly gates
 sharing behind parent approval, but the approval UX has gaps (no preview, rejected = dead end).
 The backend Safety HQ receives reports but can't act on them — no takedown, no notification back
  to families.

 This plan closes the loop at every level so the child-facing actions match what actually
 happens, and gives the backend the ability to execute content takedowns.

 ---
 Level 1 — No changes

 Works as designed. Local note, stays on device. Honest UX.

 ---
 Level 2 — Make "Hide Their Videos" actually hide + notify parent

 Problem

 submitReport short-circuits at level < 3 — marks delivered immediately, no network publish, no
 video hiding. The LocalVideos.hidden column exists but is never written.

 Flutter changes

 lib/services/safety/report_coordinator.dart — replace the level < 3 early return (lines
 105-118):
 - Level 1: keep current behavior (local-only, mark delivered).
 - Level 2: after inserting the report:
   a. Call _database.setLocalVideoHidden(videoId, true) to hide the video from the child's feed.
 The feed query already filters hidden == false.
   b. Publish the report to the family MLS group via _publishReportToGroup with recipientType:
 'local_parent' — same as L3 family publish but without the Safety HQ leg. This requires looking
 up the family group ID (same logic as L3 at line 141-143).
   c. Mark delivered.
   d. For local videos (no blobHash), skip the group publish — just hide + mark delivered. Level
 2 on a local video is a sensible local action even without network.

 lib/core/storage/app_database.dart — add setLocalVideoHidden({required String videoId, required
 bool hidden}) method. Simple drift update on the hidden column.

 No UI changes needed. The feed already filters hidden videos. The parent already sees inbound
 reports in Activity. The FeelingReportSheet text ("Let your parent know privately") becomes
 truthful.

 ---
 Level 3 — Make "Block Them" actually enforce

 Problem

 Report publishes to family + Safety HQ but nothing happens after. Video stays visible, user
 stays in groups, no takedown mechanism exists.

 3a. Fix local video reports (pending_blob_hash dead end)

 lib/services/safety/report_coordinator.dart — lines 120-133.

 Local videos (no blobHash) can't be reported to Safety HQ because there's no blob to reference.
 Change: if blobHash is null, publish to the family group only (parents are notified), hide the
 video locally, mark delivered. Don't try to publish to Safety HQ — there's nothing for the
 backend to take down.

 3b. Immediate client-side enforcement after L3 submit

 lib/features/player/presentation/player_page.dart — in the onSubmit callback (lines 685-741),
 after a successful L3 submit:

 1. If this is a remote share: call ModerationCoordinator.deleteSharedVideo() to publish
 mytube/video_delete to the family group and purge local cache. This uses the existing
 VideoLifecycleCoordinator.publishDelete under the hood — both families' clients will receive it
 and purge the video.
 2. Call ModerationCoordinator.removeMember() to remove the offending parent from the family MLS
 group.
 3. Navigate back / close the player (the video is gone).
 4. Wrap in try/catch — enforcement is best-effort after report delivery.

 This requires moderationCoordinatorProvider to be accessible from PlayerPage. Check DI wiring.
 The remoteShare projection is already in scope (line 669 area). The senderParentKey and
 mlsGroupId come from the RemoteShareProjection.

 For local videos at L3: hide locally + notify family group (from 3a). No member removal (the
 subject is the same family).

 3c. Backend takedown capability (Rust)

 rust/config.rs — add blossom_admin_password: Option<String> to AppConfig, read from
 BLOSSOM_ADMIN_PASSWORD env var.

 rust/blossom.rs — add admin_delete_blob(server_url, sha256, admin_password) using reqwest.
 DELETE to {blossom_server_url}/api/blobs/{sha256} with HTTP Basic Auth. Treat 404 as success
 (already deleted).

 Cargo.toml — add reqwest = { version = "0.12", features = ["json"] } and base64.

 rust/safety_hq.rs — add takedown_case(report_id, changed_by):
 1. Load the moderation case.
 2. Delete the blob from Blossom via admin_delete_blob (best-effort, log failures).
 3. Publish a mytube/video_delete MLS application message into the enrolled Safety HQ group. The
 backend already has the MDK instance, nostr client, and keys to do this — follow the same
 pattern as handle_group_event but in reverse (create message instead of process message).
 4. Update case status to closed with note "takedown_executed".

 rust/app.rs — add route POST /v1/safety-hq/cases/{report_id}/takedown behind NIP-98 auth. Calls
 takedown_case.

 docker-compose.yml — pass BLOSSOM_ADMIN_PASSWORD to the tubestr service environment.

 3d. Client receives backend takedown (no changes needed)

 SyncCoordinator already handles MarmotKinds.videoDelete — purges cache, marks share deleted,
 player shows placeholder. The existing lifecycle message pipeline handles this end-to-end.

 ---
 Content Scanning — Close approval gaps

 Problem

 Parent can't preview flagged videos. Rejected videos vanish with no undo. These aren't
 safety-critical but undermine the parent's ability to make good moderation decisions.

 Video preview from approval card

 lib/features/parent_zone/presentation/widgets/parent_zone_children_section.dart — add a
 "Preview" TextButton to _ApprovalCard. On tap, navigate to PlayerPage(videoId: video.id). The
 player already handles local video playback.

 Make rejection recoverable

 lib/features/parent_zone/presentation/widgets/parent_zone_children_section.dart — add a
 "Rejected" section below the pending approval list. Query watchRejectedVideos (new DB method
 filtering approvalStatus == 'rejected'). Show each with a "Restore to pending" button that
 resets approvalStatus = 'pending'.

 lib/core/storage/app_database.dart — add watchRejectedVideos stream query and
 resetVideoToPending(videoId) method.

 ---
 Global npub blacklist

 Skip it. The app uses closed MLS groups — no public feed, no discovery. A bad actor inside a
 group is handled by member removal + blob takedown. A blacklist adds sync/storage/revocation
 infrastructure with near-zero marginal safety benefit for this architecture.

 ---
 Implementation sequence

 1. Level 2 fix (Flutter only) — report_coordinator.dart + app_database.dart
 2. Level 3 pending_blob_hash fix (Flutter only) — report_coordinator.dart
 3. Level 3 immediate enforcement (Flutter) — player_page.dart
 4. Backend takedown pipeline (Rust) — blossom.rs, safety_hq.rs, app.rs, config.rs, Cargo.toml,
 docker-compose.yml
 5. Approval UX (Flutter) — parent_zone_children_section.dart, app_database.dart

 Steps 1-3 are independent of the backend work (step 4). Steps 1-3 can ship first.

 ---
 Verification

 - Level 1: file a L1 report → confirm local DB row, no network, video still visible. No behavior
  change.
 - Level 2: file a L2 report → confirm video disappears from child feed (hidden = true), report
 appears in other family's Activity section via MLS.
 - Level 3 (remote share): file a L3 report → confirm report published to family + Safety HQ,
 video deleted from both families' caches, offending parent removed from group, player navigates
 back.
 - Level 3 (local video): file a L3 report → confirm video hidden locally, report published to
 family group, no pending_blob_hash status.
 - Backend takedown: call POST /v1/safety-hq/cases/{id}/takedown → confirm blob deleted from
 Blossom, video_delete message published to group, syncing clients purge the video.
 - Approval preview: tap Preview on a pending video → player opens with the local video.
 - Rejection recovery: reject a video → confirm it appears in Rejected section → tap Restore →
 confirm it reappears in pending queue.
 - Run existing tests: flutter test test/services/safety/

 ---
 Key files

 ┌───────────────────────────────────────────────────────────────┬───────────────────────────┐
 │                             File                              │          Changes          │
 ├───────────────────────────────────────────────────────────────┼───────────────────────────┤
 │                                                               │ L1/L2 branching, L2       │
 │ lib/services/safety/report_coordinator.dart                   │ family publish, L3        │
 │                                                               │ local-video fix           │
 ├───────────────────────────────────────────────────────────────┼───────────────────────────┤
 │                                                               │ L3 post-submit            │
 │ lib/features/player/presentation/player_page.dart             │ enforcement (delete       │
 │                                                               │ video, remove member)     │
 ├───────────────────────────────────────────────────────────────┼───────────────────────────┤
 │                                                               │ setLocalVideoHidden,      │
 │ lib/core/storage/app_database.dart                            │ watchRejectedVideos,      │
 │                                                               │ resetVideoToPending       │
 ├───────────────────────────────────────────────────────────────┼───────────────────────────┤
 │ lib/features/parent_zone/presentation/widgets/parent_zone_chi │ Preview button, rejected  │
 │ ldren_section.dart                                            │ section                   │
 ├───────────────────────────────────────────────────────────────┼───────────────────────────┤
 │ rust/blossom.rs                                               │ admin_delete_blob         │
 ├───────────────────────────────────────────────────────────────┼───────────────────────────┤
 │ rust/safety_hq.rs                                             │ takedown_case, publish_vi │
 │                                                               │ deo_delete_to_group       │
 ├───────────────────────────────────────────────────────────────┼───────────────────────────┤
 │ rust/app.rs                                                   │ POST /v1/safety-hq/cases/ │
 │                                                               │ {id}/takedown route       │
 ├───────────────────────────────────────────────────────────────┼───────────────────────────┤
 │ rust/config.rs                                                │ blossom_admin_password    │
 ├───────────────────────────────────────────────────────────────┼───────────────────────────┤
 │                                                               │ Pass                      │
 │ docker-compose.yml                                            │ BLOSSOM_ADMIN_PASSWORD to │
 │                                                               │  tubestr service          │
 └───────────────────────────────────────────────────────────────┴───────────────────────────┘
