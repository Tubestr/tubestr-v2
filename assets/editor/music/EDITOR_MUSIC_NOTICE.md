# Editor music

These bundled editor music overlays are curated from OpenGameArt.

- License policy: bundled community imports must be CC0 unless reviewed otherwise.
- Imported format: source audio normalized to 44.1 kHz stereo 96 kbps MP3 blobs.
- Regenerate: `python3 scripts/import_editor_music.py`
- Publish staged blobs: `EDITOR_AUDIO_PUBLISH_NSEC=nsec1... dart run scripts/publish_editor_music_to_blossom.dart`

Per-track source URLs, creators, licenses, and attribution notes are stored in EDITOR_MUSIC_ATTRIBUTIONS.json.
