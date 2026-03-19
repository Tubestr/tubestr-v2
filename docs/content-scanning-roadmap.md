# Content Scanning Roadmap

Last updated: 2026-03-19

## Purpose

This document tracks what the app currently does for on-device content scanning,
what value it provides today, and what remains if we want stronger parity with
the old app's safety posture.

The intended role of scanning in Tubestr v2 is:

- Triage clips for parent review before sharing.
- Prevent unscanned clips from bypassing the approval flow.
- Give parents understandable review reasons.

It is not currently intended to be a standalone, high-recall harmful-content
moderation system.

## What We Have Now

### End-to-end scan enforcement

- Capture scans newly saved clips before they are treated as ready.
- Editor export scans remixes before they enter the library/share flow.
- Share preflight backfills missing scans before upload, so older or remixed
  clips cannot bypass scanning.

Key files:

- `lib/features/capture/presentation/capture_page.dart`
- `lib/services/editor/editor_export_service.dart`
- `lib/services/share/video_share_coordinator.dart`
- `lib/services/approval/video_approval_service.dart`

### Real media signal extraction

Milestone 1 is implemented.

The app now extracts:

- duration
- loudness
- face count from sampled frames

Implementation:

- `lib/services/approval/media_signal_extraction_service.dart`

Current extraction behavior:

- Loudness uses FFmpeg `volumedetect`.
- Face count uses sampled JPEG frames plus ML Kit face detection on Android/iOS.
- Sampled frames are temporary and cleaned up after extraction.

### Richer scan metadata

Milestone 2 is implemented.

The app now persists:

- `scanVersion`
- `highestRiskCategory`
- `scanConfidence`
- `reviewReasons`
- `scanResults`
- `scanCompletedAt`

Schema and model files:

- `lib/core/storage/app_database.dart`
- `lib/domain/models/content_scan_summary.dart`

### Retuned classifier

Milestone 3 is implemented.

The classifier now leans more on real media signals and less on title-only
matching.

Current signals in use:

- high-risk title/tag/label matches
- review title/tag/label matches
- loudness
- face count
- runtime
- attention-seeking title cues only when paired with other review signals

Implementation:

- `lib/services/approval/content_scan_service.dart`

### Parent safety value today

Even without image labeling or keyframe hashing, the app already provides useful
trust-and-safety value:

- flagged clips remain pending for parent review
- safe clips can auto-approve when parent approval is disabled
- scan-before-share is enforced
- parents see clearer review reasons than before
- reporting and moderation flows remain available after sharing

This means the product already has meaningful moderation support as a
parent-gated triage system.

## What Is Still Missing

### 1. `cvLabels` are still not populated

The schema and classifier support `cvLabels`, but the extraction pipeline does
not currently generate them.

Impact:

- the scan still lacks semantic frame labeling
- visual harmful-content detection remains limited

### 2. Keyframe hashes are not stored

We are already sampling frames for face detection, but we do not persist hashes
for those samples.

Potential future value:

- detecting re-imports of previously reviewed/flagged content
- debugging rescans and scan drift

### 3. No backfill/rescan job for old clips

Older clips only get upgraded metadata when they flow back through
`scanAndClassifyVideo`.

Impact:

- mixed-quality scan coverage across old and new library items

### 4. Parent UI does not fully expose richer scan metadata

The richer metadata is persisted, but most parent-facing UI still focuses on:

- `riskLevel`
- `flags`
- `summary`

Potential improvements:

- show top category explicitly
- show confidence carefully for diagnostics only
- show review reasons directly in approval cards

### 5. No dedicated image safety classifier

This is intentionally deferred.

We have not yet shipped:

- nudity classifier
- violence classifier
- generic harmful-image classifier

This avoids premature model shipping and false-positive UX risk, but it also
means scan quality still depends on coarse signals rather than deep semantic
understanding.

### 6. Real-device validation is still needed

The code path is implemented, but we still need to verify on target devices:

- capture-to-scan latency
- battery/thermal impact
- ML Kit face-detection reliability
- behavior on low-end Android hardware
- iOS plugin/runtime behavior

## Recommended Next Steps

If we continue this work, the next order should be:

1. Add `cvLabels` generation from one image-labeling provider.
2. Add keyframe hashes for sampled frames.
3. Add a rescan/backfill path for old local videos.
4. Expose richer scan metadata more clearly in Parent Zone.
5. Run real-device validation and tune thresholds for low false positives.

## What We Should Not Do Yet

These are intentionally deferred unless the current triage system proves
insufficient:

- OCR on sampled frames
- speech analysis
- multi-model "fusion" work
- shipping an image safety classifier without a validated candidate and device
  benchmark

## Risk Notes

Finishing `cvLabels` and keyframe hashing is moderate engineering risk.

Main risks:

- false positives from image labeling
- slower post-capture scan time
- more battery/device variance
- unclear "parity to v1" target unless we define the old app's actual scan
  behavior more precisely

For now, the parent approval gate remains the primary safety control. Scanning
should continue to optimize for useful triage and low false positives rather
than trying to behave like a standalone moderation service.

## Verification Status

Focused scan-related tests currently cover:

- signal extraction wiring
- classifier behavior
- approval persistence
- share-path backfill behavior
- scan metadata persistence in storage

Recent focused test command:

```sh
flutter test \
  test/services/approval/content_scan_service_test.dart \
  test/services/approval/media_signal_extraction_service_test.dart \
  test/services/approval/video_approval_service_test.dart \
  test/services/share/video_share_coordinator_test.dart \
  test/core/storage/app_database_test.dart
```

Known note:

- there is still an unrelated failing test in
  `test/services/offline/offline_action_processor_test.dart` that does not
  block this scan roadmap directly
