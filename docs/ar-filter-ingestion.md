# AR Filter Ingestion

The AR filter catalog is generated from reviewed source manifests, then
published to Blossom.

## Quality-First Flow

Use the studio pack when you want a tighter Snapchat/TikTok-style baseline
instead of a broad public-clipart scrape:

1. Generate the reviewed first-party source pack:

   ```bash
   python3 scripts/generate_ar_filter_studio_pack.py \
     --out build/ar_filters/studio_source_manifest.json \
     --asset-dir build/ar_filters/studio_sources
   ```

2. Stage the publish manifest:

   ```bash
   python3 scripts/import_ar_filter_assets.py \
     --manifest build/ar_filters/studio_source_manifest.json \
     --out build/ar_filters/studio_publish_manifest.json \
     --asset-dir build/ar_filters/studio_assets \
     --attribution-out build/ar_filters/STUDIO_ATTRIBUTION.md
   ```

3. Optional quick visual review:

   ```bash
   python3 scripts/verify_ar_filter_assets.py \
     --asset-dir build/ar_filters/studio_assets

   tmpdir=$(mktemp -d)
   for f in build/ar_filters/studio_assets/*.png; do
     magick -size 160x160 canvas:'#111827' "$f" \
       -thumbnail 128x128 \
       -gravity center \
       -composite "$tmpdir/$(basename "$f")"
   done
   magick montage "$tmpdir"/*.png \
     -background '#111827' \
     -tile 6x \
     -geometry 160x160+8+8 \
     build/ar_filters/studio_contact_sheet.png
   rm -rf "$tmpdir"
   ```

4. Publish to Blossom and regenerate the app catalog:

   ```bash
   AR_FILTER_PUBLISH_NSEC=... dart run scripts/publish_ar_filters_to_blossom.dart \
     --manifest build/ar_filters/studio_publish_manifest.json \
     --out lib/services/editor/generated_ar_filter_catalog.dart
   ```

## Web Candidate Flow

1. Discover a broad candidate list:

   ```bash
   python3 scripts/discover_ar_filter_sources.py \
     --target 100 \
     --out build/ar_filters/source_candidates.json
   ```

2. Review `build/ar_filters/source_candidates.json`. Delete weak, irrelevant,
   duplicate, or poorly cropped entries.
3. Curate source assets in `scripts/ar_filter_sources.sample.json` or a reviewed
   candidate manifest.
   Each filter must include source, license, and attribution metadata.
4. Stage the publish manifest:

   ```bash
   python3 scripts/import_ar_filter_assets.py \
     --manifest build/ar_filters/source_candidates.json \
     --out build/ar_filters/publish_manifest.json
   ```

5. Review `build/ar_filters/ATTRIBUTION.md` and the staged PNGs in
   `build/ar_filters/assets/`.
6. Publish to Blossom and regenerate the app catalog:

   ```bash
   AR_FILTER_PUBLISH_NSEC=... dart run scripts/publish_ar_filters_to_blossom.dart \
     --manifest build/ar_filters/publish_manifest.json \
     --out lib/services/editor/generated_ar_filter_catalog.dart
   ```

For a syntax-only check without uploading, use `--generate-only` and write to a
temporary file. Do not ship generated catalogs whose blobs were not uploaded.

## Source Rules

- Prefer CC0/Public Domain or MIT assets.
- Attribution-required sources are allowed only when reviewed and imported with
  `--allow-attribution-required`.
- Flaticon free-tier assets must include attribution text and should stay behind
  the attribution-required flag.
- OpenGameArt licenses vary per asset. Do not import from OpenGameArt unless the
  specific asset page license has been checked.
- Kenney asset pages are CC0, but still keep source URLs and optional credit.
- Prefer the studio pack for the default catalog, then mix in hand-reviewed web
  candidates as featured/community additions.
