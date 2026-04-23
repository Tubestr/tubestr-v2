#!/usr/bin/env python3
"""Import curated AR face-filter assets into a Blossom publish manifest.

This script is intentionally source-manifest driven. It does not scrape random
search results into the product; each filter must name its source, license, and
asset URL/archive path so review stays explicit.
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import tempfile
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE_MANIFEST = REPO_ROOT / "scripts" / "ar_filter_sources.sample.json"
DEFAULT_OUTPUT = REPO_ROOT / "build" / "ar_filters" / "publish_manifest.json"
DEFAULT_ASSET_DIR = REPO_ROOT / "build" / "ar_filters" / "assets"
DEFAULT_ATTRIBUTION = REPO_ROOT / "build" / "ar_filters" / "ATTRIBUTION.md"
DEFAULT_CACHE_DIR = REPO_ROOT / "build" / "ar_filters" / "source_cache"

NO_ATTRIBUTION_LICENSES = {
    "cc0",
    "cc0-1.0",
    "public domain",
    "mit",
}


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Stage curated open-source AR filter assets for Blossom.",
    )
    parser.add_argument("--manifest", default=str(DEFAULT_SOURCE_MANIFEST))
    parser.add_argument("--out", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--asset-dir", default=str(DEFAULT_ASSET_DIR))
    parser.add_argument("--attribution-out", default=str(DEFAULT_ATTRIBUTION))
    parser.add_argument("--cache-dir", default=str(DEFAULT_CACHE_DIR))
    parser.add_argument("--size", type=int, default=512)
    parser.add_argument(
        "--allow-attribution-required",
        action="store_true",
        help="Allow licenses that require attribution when attribution text exists.",
    )
    args = parser.parse_args()

    manifest_path = Path(args.manifest)
    if not manifest_path.is_absolute():
        manifest_path = REPO_ROOT / manifest_path
    if not manifest_path.exists():
        print(f"Missing AR filter source manifest: {manifest_path}", file=sys.stderr)
        print(f"Start with: {DEFAULT_SOURCE_MANIFEST.relative_to(REPO_ROOT)}", file=sys.stderr)
        return 66

    output_path = Path(args.out)
    if not output_path.is_absolute():
        output_path = REPO_ROOT / output_path
    asset_dir = Path(args.asset_dir)
    if not asset_dir.is_absolute():
        asset_dir = REPO_ROOT / asset_dir
    attribution_path = Path(args.attribution_out)
    if not attribution_path.is_absolute():
        attribution_path = REPO_ROOT / attribution_path
    cache_dir = Path(args.cache_dir)
    if not cache_dir.is_absolute():
        cache_dir = REPO_ROOT / cache_dir

    filters = json.loads(manifest_path.read_text())
    if not isinstance(filters, list):
        raise ValueError("Source manifest root must be a list of filters.")

    asset_dir.mkdir(parents=True, exist_ok=True)
    cache_dir.mkdir(parents=True, exist_ok=True)
    staged_filters: list[dict[str, Any]] = []

    with tempfile.TemporaryDirectory(prefix="ar-filter-import-") as temp:
        temp_dir = Path(temp)
        for raw_filter in filters:
            staged_filters.append(
                stage_filter(
                    raw_filter,
                    manifest_dir=manifest_path.parent,
                    temp_dir=temp_dir,
                    asset_dir=asset_dir,
                    cache_dir=cache_dir,
                    output_dir=output_path.parent,
                    size=args.size,
                    allow_attribution_required=args.allow_attribution_required,
                )
            )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(staged_filters, indent=2) + "\n")
    write_attribution(staged_filters, attribution_path)
    print(f"Imported {len(staged_filters)} AR filter(s).")
    print(f"Wrote {output_path.relative_to(REPO_ROOT)}")
    print(f"Wrote {attribution_path.relative_to(REPO_ROOT)}")
    return 0


def stage_filter(
    raw_filter: dict[str, Any],
    *,
    manifest_dir: Path,
    temp_dir: Path,
    asset_dir: Path,
    cache_dir: Path,
    output_dir: Path,
    size: int,
    allow_attribution_required: bool,
) -> dict[str, Any]:
    filter_id = required_str(raw_filter, "id")
    label = required_str(raw_filter, "label")
    license_name = required_str(raw_filter, "license")
    attribution = str(raw_filter.get("attribution") or "").strip()
    normalized_license = normalize_license(license_name)
    if normalized_license not in NO_ATTRIBUTION_LICENSES:
        if not allow_attribution_required:
            raise ValueError(
                f"{filter_id} uses attribution-required license {license_name!r}. "
                "Pass --allow-attribution-required after review."
            )
        if not attribution:
            raise ValueError(f"{filter_id} must include attribution text.")

    staged = {
        "id": filter_id,
        "label": label,
        "category": str(raw_filter.get("category") or "featured"),
        "description": str(raw_filter.get("description") or ""),
        "sourceName": str(raw_filter.get("sourceName") or ""),
        "sourceUrl": str(raw_filter.get("sourceUrl") or ""),
        "license": license_name,
        "licenseUrl": str(raw_filter.get("licenseUrl") or ""),
        "attribution": attribution,
        "parts": [],
    }

    parts = raw_filter.get("parts")
    if not isinstance(parts, list) or not parts:
        raise ValueError(f"{filter_id} must include at least one part.")

    for index, part in enumerate(parts, start=1):
        if not isinstance(part, dict):
            raise ValueError(f"{filter_id} part {index} must be an object.")
        source_path = resolve_part_source(
            part,
            manifest_dir=manifest_dir,
            temp_dir=temp_dir,
            cache_dir=cache_dir,
        )
        target_name = f"{filter_id}_{index:02d}.png"
        target_path = asset_dir / target_name
        normalize_asset(source_path, target_path, size=size)
        staged_part = {
            "path": relative_to(target_path, output_dir),
            "anchor": str(part.get("anchor") or "forehead"),
            "widthScale": float(part.get("widthScale", 1.0)),
            "offsetX": float(part.get("offsetX", 0)),
            "offsetY": float(part.get("offsetY", 0)),
            "rotationDegrees": float(part.get("rotationDegrees", 0)),
            "opacity": float(part.get("opacity", 1)),
        }
        staged["parts"].append(staged_part)

    return staged


def resolve_part_source(
    part: dict[str, Any],
    *,
    manifest_dir: Path,
    temp_dir: Path,
    cache_dir: Path,
) -> Path:
    if "localPath" in part:
        path = Path(required_str(part, "localPath"))
        return path if path.is_absolute() else manifest_dir / path

    if "archiveUrl" in part:
        archive_url = required_str(part, "archiveUrl")
        archive_path = required_str(part, "archivePath")
        archive_file = download_cached(archive_url, cache_dir)
        extract_dir = temp_dir / archive_file.stem
        extract_dir.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(archive_file) as archive:
            archive.extract(archive_path, extract_dir)
        return extract_dir / archive_path

    if "url" in part:
        return download_cached(required_str(part, "url"), cache_dir)

    raise ValueError("Part must include one of localPath, url, or archiveUrl/archivePath.")


def download_cached(url: str, cache_dir: Path) -> Path:
    parsed = urllib.parse.urlparse(url)
    name = Path(urllib.parse.unquote(parsed.path)).name or "download"
    target = cache_dir / safe_filename(name)
    if target.exists() and target.stat().st_size > 0:
        return target
    print(f"download {url}")
    request = urllib.request.Request(url, headers={"User-Agent": "Tubestr AR importer"})
    with urllib.request.urlopen(request) as response:
        target.write_bytes(response.read())
    return target


def normalize_asset(source: Path, target: Path, *, size: int) -> None:
    if not source.exists():
        raise FileNotFoundError(source)
    if shutil.which("magick"):
        subprocess.run(
            [
                "magick",
                "-background",
                "none",
                str(source),
                "-alpha",
                "on",
                "-trim",
                "+repage",
                "-resize",
                f"{size}x{size}>",
                "-gravity",
                "center",
                "-background",
                "none",
                "-extent",
                f"{size}x{size}",
                "-alpha",
                "set",
                "-strip",
                "-define",
                "png:color-type=6",
                "-define",
                "png:exclude-chunk=bKGD",
                f"PNG32:{target}",
            ],
            check=True,
        )
        return

    if source.suffix.lower() != ".png":
        raise RuntimeError("ImageMagick `magick` is required for non-PNG AR assets.")
    shutil.copyfile(source, target)


def write_attribution(filters: list[dict[str, Any]], path: Path) -> None:
    lines = ["# AR Filter Asset Attribution", ""]
    for item in filters:
        lines.append(f"## {item['label']}")
        if item.get("sourceName"):
            lines.append(f"- Source: {item['sourceName']}")
        if item.get("sourceUrl"):
            lines.append(f"- URL: {item['sourceUrl']}")
        lines.append(f"- License: {item['license']}")
        if item.get("licenseUrl"):
            lines.append(f"- License URL: {item['licenseUrl']}")
        if item.get("attribution"):
            lines.append(f"- Attribution: {item['attribution']}")
        lines.append("")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines))


def relative_to(path: Path, root: Path) -> str:
    try:
        return str(path.relative_to(root))
    except ValueError:
        return str(path)


def required_str(mapping: dict[str, Any], key: str) -> str:
    value = mapping.get(key)
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"Missing required string field: {key}")
    return value.strip()


def normalize_license(value: str) -> str:
    return value.strip().lower().replace(" ", "-")


def safe_filename(value: str) -> str:
    return "".join(ch if ch.isalnum() or ch in "._-" else "_" for ch in value)


if __name__ == "__main__":
    raise SystemExit(main())
