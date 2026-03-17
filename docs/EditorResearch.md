# MyTube Editor Research

Date: 2026-03-16

## Goal

Choose an editor path for Flutter that can support the old MyTube experience:

- tablet-first editor flow from `docs/UIReference.md`
- trim
- LUT filters and slider-driven effects
- draggable stickers
- text overlays
- music tracks with volume control
- export on Android and iOS

## Product Requirements From The Old App

Local references:

- `/home/lee/apps/tubestr-v2/docs/UIReference.md`
- `/home/lee/apps/tubestr-ios/Docs/EditorUXImprovements.md`
- `/home/lee/apps/tubestr-ios/MyTube/Domain/EditModels.swift`
- `/home/lee/apps/tubestr-ios/MyTube/Services/EditRenderer.swift`
- `/home/lee/apps/tubestr-ios/MyTube/Services/ResourceLibrary.swift`

The old app already gives us a strong architecture target:

- edit state should be stored as app models, not hidden inside a package controller
- sticker transforms should be normalized so they survive screen-size changes
- LUTs, stickers, and music tracks are asset-driven resources
- preview and export are separate concerns

That split matters in Flutter too.

## Current Flutter Option Review

### `video_editor_2`

Source: https://pub.dev/packages/video_editor_2

What it is good at:

- trim
- crop
- rotate
- cover selection
- customizable UI shell

Why it is not a fit as the core editor:

- package metadata only claims crop, trim, rotation, and cover selection
- no built-in path for stickers, text overlays, LUT filters, or audio mixing
- published 18 months ago at the time of review

Conclusion:

- useful reference for trim UI ideas
- not enough for MyTube as the primary editor foundation

### `easy_video_editor`

Source: https://pub.dev/packages/easy_video_editor

What it is good at:

- native trim
- merge
- speed
- crop
- rotate
- remove/extract audio

Why it is not a fit as the core editor:

- package feature list does not include stickers, text overlays, LUT filters, or mixed music tracks
- better as a utility wrapper than as a full kid-facing editor stack

Conclusion:

- not enough for the MyTube editor feature set

### `flutter_gpu_video_filters`

Source: https://pub.dev/packages/flutter_gpu_video_filters

What it is good at:

- native preview widgets
- GPU-driven filter previews
- export support

Why it is not a fit as the core editor:

- Android only
- not suitable for our required Android + iOS path

Conclusion:

- interesting reference for preview architecture
- not a cross-platform editor foundation

### `ffmpeg_kit_flutter_new_video`

Source: https://pub.dev/packages/ffmpeg_kit_flutter_new_video

What it gives us:

- current Flutter-compatible FFmpegKit fork
- Android, iOS, macOS support
- FFmpeg and FFprobe access
- LGPL package variant
- Android `MediaCodec` support
- iOS `VideoToolbox` and `AVFoundation` support

Why it is a strong export engine candidate:

- FFmpeg already supports the specific operations we need:
  - `lut3d` for `.cube` LUT files
  - `overlay` for stickers/text raster layers
  - `amix` for music + original audio mixing

Supporting docs:

- https://ffmpeg.org/ffmpeg-filters.html

Conclusion:

- best current candidate for the export spike
- prefer the `video` package variant over the full GPL package unless we prove we need GPL-only codecs

### `google_mlkit_selfie_segmentation`

Source: https://pub.dev/packages/google_mlkit_selfie_segmentation

What it gives us:

- Android + iOS subject/background separation
- mobile-only support, which is fine for us
- plugin explicitly uses platform channels to native ML Kit APIs

Conclusion:

- good Flutter-side path for selfie sticker extraction
- not a blocker for the base editor, but a strong fit for the sticker-capture flow

### `just_audio`

Source: https://pub.dev/packages/just_audio

What it gives us:

- strong audio preview support
- clipping
- seeking
- volume
- active maintenance and broad adoption

Conclusion:

- good choice for previewing and auditioning music tracks inside the editor
- not the export engine

## Recommendation

Build the editor as a hybrid:

1. Flutter owns the editor UI, tool state, gestures, and tablet layout.
2. `media_kit` continues to own video playback preview.
3. Flutter overlays own sticker/text interaction on top of the preview.
4. `just_audio` previews music selections.
5. `ffmpeg_kit_flutter_new_video` handles final export.
6. `google_mlkit_selfie_segmentation` powers selfie-sticker capture.

This is the best fit for MyTube because the Flutter ecosystem does not currently offer one strong cross-platform package that covers trim + filters + stickers + text + audio mix + export at the level we need.

## Recommended Architecture

### 1. Keep Edit State In Dart

Create explicit domain models for:

- trim range
- selected LUT/filter preset
- effect slider values
- sticker items with normalized transform
- text overlays
- selected music track and volume
- export status

This follows the old app's `EditComposition` approach and keeps the renderer replaceable.

### 2. Treat Preview And Export As Different Problems

Recommended behavior:

- live preview:
  - video playback through `media_kit`
  - stickers/text rendered as Flutter overlays
  - music preview through `just_audio`
  - filter chips rendered from generated preview thumbnails
- export:
  - build a deterministic FFmpeg filter graph from the edit state

This recommendation is an inference from the package landscape and the old app architecture. The reason is simple: Flutter has good building blocks for UI and interaction, but weak cross-platform support for a full real-time video-effects pipeline.

### 3. Use FFmpeg Only For Export, Not For The Whole UI

FFmpeg is a strong renderer, but a poor interaction framework.

Recommended export responsibilities:

- trim input clip
- apply LUT via `lut3d=file=...`
- apply brightness/contrast/saturation/vignette-style adjustments
- overlay sticker PNGs and rendered text PNGs with normalized positions transformed into output coordinates
- mix original audio with selected music via `amix`
- encode with platform-appropriate H.264 path where possible

Inference:

- on Android, first test `h264_mediacodec`
- on iOS, first test `h264_videotoolbox`

That inference comes from the package listing support for `MediaCodec` and `VideoToolbox`; it still needs spike validation on real app clips.

### 4. Render Text As Images For Export

Do not make text export depend on FFmpeg `drawtext` as the primary path.

Recommended path:

- render the chosen text style from Flutter into a transparent PNG
- pass it into FFmpeg as another overlay input

Why:

- matches the Flutter UI exactly
- avoids font/runtime drift between platforms
- keeps export logic aligned with sticker overlays

### 5. Reuse The Old App Assets

We should copy forward:

- LUT `.cube` files
- sticker PNGs
- bundled music tracks

From:

- `/home/lee/apps/tubestr-ios/MyTube/Resources/LUTs`
- `/home/lee/apps/tubestr-ios/MyTube/Resources/Stickers`
- `/home/lee/apps/tubestr-ios/MyTube/Resources/Music`

### 6. Keep A Native Renderer Escape Hatch

Flutter's official platform-channels guidance makes it reasonable to push work native when needed:

- https://docs.flutter.dev/platform-integration/platform-channels

If the FFmpeg export spike fails on render time, stability, or output quality, keep the Flutter editor UI and move only the renderer behind platform channels:

- iOS: AVFoundation + Core Image
- Android: native media pipeline, likely Media3 Transformer and/or GPU-backed composition path

That lets us preserve the product UX while swapping the renderer.

## What We Should Not Do

- Do not build the whole editor around `video_editor_2`
- Do not build the whole editor around `easy_video_editor`
- Do not rely on Android-only GPU filter packages for the core product path
- Do not tie edit state to a package-specific controller model

## Recommended Spike Scope

The spike should prove one honest vertical slice:

1. open a local captured clip
2. trim it
3. apply one old-app LUT from `Resources/LUTs`
4. add one sticker overlay
5. add one bundled music track with volume control
6. export to MP4
7. play the exported result in-app

Success criteria:

- works on Android first, then iOS
- render completes on a 30-second clip without crashing
- output audio/video stay in sync
- sticker position and scaling are stable
- LUT output is visually believable relative to the old app assets
- export progress and cancellation are observable

## Recommended Immediate Build Order

1. Add editor domain models and editor session state.
2. Copy LUT, sticker, and music assets from the old app.
3. Build the tablet-first editor detail shell from `docs/UIReference.md`.
4. Add trim UI and sticker/text overlay interaction.
5. Add `just_audio` track preview.
6. Add `ffmpeg_kit_flutter_new_video` export service.
7. Run the Android spike and record results in `docs/plan.md`.
8. If Android passes, repeat on iOS.

## Bottom Line

Best path for MyTube:

- custom Flutter editor UI
- custom Dart edit models
- FFmpegKit video package for export
- ML Kit for selfie sticker capture
- native renderer fallback only if the export spike fails

This gives us the best chance of matching the old app's UX without locking the product to a weak or overly narrow Flutter editor package.
