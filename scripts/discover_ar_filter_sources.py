#!/usr/bin/env python3
"""Build a varied, reviewable AR filter source manifest.

The output is intentionally a *candidate* manifest. Run it, review/delete weak
entries, then pass the curated result to `import_ar_filter_assets.py`.
"""

from __future__ import annotations

import argparse
import json
import re
import time
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = REPO_ROOT / "build" / "ar_filters" / "source_candidates.json"
OPENCLIPART_SEARCH_URL = "https://openclipart.org/search/?query={query}"

QUERY_GROUPS = [
    {
        "query": "sunglasses",
        "category": "face",
        "anchor": "eyesBridge",
        "widthScale": 1.16,
        "offsetY": 0.0,
    },
    {
        "query": "glasses",
        "category": "face",
        "anchor": "eyesBridge",
        "widthScale": 1.12,
        "offsetY": 0.0,
    },
    {
        "query": "masquerade mask",
        "category": "face",
        "anchor": "eyesBridge",
        "widthScale": 1.2,
        "offsetY": 0.02,
    },
    {
        "query": "moustache",
        "category": "face",
        "anchor": "mouthCenter",
        "widthScale": 0.62,
        "offsetY": -0.16,
    },
    {
        "query": "mustache",
        "category": "face",
        "anchor": "mouthCenter",
        "widthScale": 0.62,
        "offsetY": -0.16,
    },
    {
        "query": "beard",
        "category": "face",
        "anchor": "mouthCenter",
        "widthScale": 0.86,
        "offsetY": 0.16,
    },
    {
        "query": "crown",
        "category": "headwear",
        "anchor": "forehead",
        "widthScale": 0.82,
        "offsetY": -0.56,
    },
    {
        "query": "tiara",
        "category": "headwear",
        "anchor": "forehead",
        "widthScale": 0.82,
        "offsetY": -0.54,
    },
    {
        "query": "party hat",
        "category": "headwear",
        "anchor": "forehead",
        "widthScale": 0.72,
        "offsetY": -0.58,
    },
    {
        "query": "wizard hat",
        "category": "headwear",
        "anchor": "forehead",
        "widthScale": 0.78,
        "offsetY": -0.62,
    },
    {
        "query": "pirate hat",
        "category": "headwear",
        "anchor": "forehead",
        "widthScale": 0.86,
        "offsetY": -0.52,
    },
    {
        "query": "helmet",
        "category": "headwear",
        "anchor": "forehead",
        "widthScale": 0.76,
        "offsetY": -0.5,
    },
    {
        "query": "cat ears",
        "category": "headwear",
        "anchor": "forehead",
        "widthScale": 1.05,
        "offsetY": -0.58,
    },
    {
        "query": "bunny ears",
        "category": "headwear",
        "anchor": "forehead",
        "widthScale": 1.0,
        "offsetY": -0.68,
    },
    {
        "query": "antlers",
        "category": "headwear",
        "anchor": "forehead",
        "widthScale": 1.12,
        "offsetY": -0.62,
    },
    {
        "query": "horns",
        "category": "headwear",
        "anchor": "forehead",
        "widthScale": 1.0,
        "offsetY": -0.58,
    },
    {
        "query": "headphones",
        "category": "headwear",
        "anchor": "eyesBridge",
        "widthScale": 1.22,
        "offsetY": -0.22,
    },
    {
        "query": "bow tie",
        "category": "face",
        "anchor": "mouthCenter",
        "widthScale": 0.64,
        "offsetY": 0.5,
    },
    {
        "query": "sparkle",
        "category": "effects",
        "anchor": "forehead",
        "widthScale": 0.36,
        "offsetX": -0.42,
        "offsetY": -0.52,
    },
    {
        "query": "star",
        "category": "effects",
        "anchor": "forehead",
        "widthScale": 0.34,
        "offsetX": 0.42,
        "offsetY": -0.48,
    },
]

STATIC_SEEDS = [
    {
        "id": "oga-pixel-helmet",
        "label": "Pixel Helmet",
        "category": "headwear",
        "description": "A CC0 OpenGameArt helmet accessory, normalized for face tracking.",
        "sourceName": "OpenGameArt: helmet",
        "sourceUrl": "https://opengameart.org/content/helmet-0",
        "license": "CC0",
        "licenseUrl": "https://creativecommons.org/publicdomain/zero/1.0/",
        "attribution": "Xevin on OpenGameArt.",
        "parts": [
            {
                "url": "https://opengameart.org/sites/default/files/helmet_v03_0.png",
                "anchor": "forehead",
                "widthScale": 0.72,
                "offsetX": 0,
                "offsetY": -0.5,
                "rotationDegrees": 0,
                "opacity": 1,
            }
        ],
    },
    {
        "id": "kenney-generic-spark",
        "label": "Kenney Spark",
        "category": "effects",
        "description": "Example of importing a named file from a Kenney CC0 zip pack.",
        "sourceName": "Kenney Generic Items",
        "sourceUrl": "https://kenney.nl/assets/generic-items",
        "license": "CC0",
        "licenseUrl": "https://creativecommons.org/publicdomain/zero/1.0/",
        "attribution": "Kenney",
        "parts": [
            {
                "archiveUrl": "https://kenney.nl/media/pages/assets/generic-items/5ae90c9fdc-1677667000/kenney_generic-items.zip",
                "archivePath": "PNG/Colored/genericItem_color_102.png",
                "anchor": "forehead",
                "widthScale": 0.32,
                "offsetX": 0.42,
                "offsetY": -0.5,
                "rotationDegrees": 12,
                "opacity": 1,
            }
        ],
    },
]

SKIP_SLUG_TERMS = {
    "arms",
    "ballerina",
    "batteries",
    "bookworm",
    "bridesmaids",
    "cake",
    "candles",
    "card",
    "cartoon",
    "christmas",
    "clowny",
    "coffee",
    "contract",
    "cups",
    "dancing",
    "deer",
    "devil",
    "drinks",
    "egg",
    "face",
    "father",
    "fidel",
    "flapper",
    "gesture",
    "guy",
    "girl",
    "head",
    "holding",
    "man",
    "menu",
    "monster",
    "people",
    "penguin",
    "person",
    "portrait",
    "pumpkin",
    "skeleton",
    "skull",
    "smiley",
    "student",
    "logo",
    "sign",
    "sun",
    "text",
    "thief",
    "thorns",
    "toast",
    "tube",
    "woman",
    "word",
}

ACCESSORY_SLUG_TERMS = {
    "antlers",
    "beard",
    "bow",
    "crown",
    "ears",
    "eyeglasses",
    "glasses",
    "halo",
    "hat",
    "headphones",
    "helmet",
    "horns",
    "mask",
    "masquerade",
    "monocle",
    "moustache",
    "mustache",
    "shades",
    "sparkle",
    "star",
    "sunglasses",
    "tiara",
    "tie",
    "visor",
    "wizard",
    "witch",
}

SKIP_SLUG_FRAGMENTS = {
    "word-cloud",
    "with-bg",
    "holding-a-blank",
    "wearing-sunglasses",
    "wearing-a-mask",
    "in-sunglasses",
    "in-a-mask",
    "in-face-mask",
    "with-sunglasses",
    "with-cat-ears",
    "with-beard",
    "with-moustache",
    "with-mustache",
    "with-headphones",
    "photo",
}


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Discover varied CC0 AR filter source candidates.",
    )
    parser.add_argument("--out", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--target", type=int, default=100)
    parser.add_argument("--per-query", type=int, default=8)
    parser.add_argument("--include-noisy", action="store_true")
    args = parser.parse_args()

    output = Path(args.out)
    if not output.is_absolute():
        output = REPO_ROOT / output

    candidates: list[dict[str, Any]] = []
    seen_ids: set[str] = set()
    for seed in STATIC_SEEDS:
        candidates.append(seed)
        seen_ids.add(seed["id"])

    for group in QUERY_GROUPS:
        if len(candidates) >= args.target:
            break
        links = fetch_openclipart_links(group["query"])
        added_for_query = 0
        for clip_id, slug in links:
            if len(candidates) >= args.target or added_for_query >= args.per_query:
                break
            if not args.include_noisy and is_noisy_slug(slug):
                continue
            candidate_id = unique_id(f"oc-{slug}", seen_ids)
            seen_ids.add(candidate_id)
            candidates.append(openclipart_candidate(candidate_id, clip_id, slug, group))
            added_for_query += 1
        time.sleep(0.2)

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(candidates[: args.target], indent=2) + "\n")
    print(f"Wrote {min(len(candidates), args.target)} candidate filter(s) to {output}")
    print("Review this file before importing; delete weak or irrelevant entries.")
    return 0


def fetch_openclipart_links(query: str) -> list[tuple[str, str]]:
    url = OPENCLIPART_SEARCH_URL.format(query=urllib.parse.quote(query))
    request = urllib.request.Request(url, headers={"User-Agent": "Tubestr AR discovery"})
    html = urllib.request.urlopen(request, timeout=20).read().decode("utf-8", "ignore")
    found: list[tuple[str, str]] = []
    seen: set[str] = set()
    for href in re.findall(r'href=["\']([^"\']*/detail/[^"\']+)["\']', html):
        match = re.search(r"/detail/(\d+)/([^\"'#?]+)", href)
        if not match:
            continue
        clip_id, slug = match.group(1), normalize_slug(match.group(2))
        if clip_id in seen:
            continue
        seen.add(clip_id)
        found.append((clip_id, slug))
    return found


def openclipart_candidate(
    candidate_id: str,
    clip_id: str,
    slug: str,
    group: dict[str, Any],
) -> dict[str, Any]:
    label = title_from_slug(slug)
    source_url = f"https://openclipart.org/detail/{clip_id}/{slug}"
    return {
        "id": candidate_id,
        "label": label,
        "category": group["category"],
        "description": f"CC0 Openclipart candidate discovered from search: {group['query']}.",
        "sourceName": f"Openclipart: {label}",
        "sourceUrl": source_url,
        "license": "CC0",
        "licenseUrl": "https://openclipart.org/share",
        "attribution": "Openclipart public domain clipart.",
        "parts": [
            {
                "url": f"https://openclipart.org/image/2000px/{clip_id}",
                "anchor": group["anchor"],
                "widthScale": group["widthScale"],
                "offsetX": group.get("offsetX", 0),
                "offsetY": group.get("offsetY", 0),
                "rotationDegrees": 0,
                "opacity": 1,
            }
        ],
    }


def normalize_slug(value: str) -> str:
    decoded = urllib.parse.unquote(value)
    return re.sub(r"[^a-z0-9-]+", "-", decoded.lower()).strip("-")


def title_from_slug(slug: str) -> str:
    words = [word for word in slug.replace("-", " ").split() if not word.isdigit()]
    return " ".join(word.capitalize() for word in words)[:48] or "AR Filter"


def unique_id(base: str, seen: set[str]) -> str:
    candidate = base[:48].strip("-")
    if candidate not in seen:
        return candidate
    index = 2
    while f"{candidate}-{index}" in seen:
        index += 1
    return f"{candidate}-{index}"


def is_noisy_slug(slug: str) -> bool:
    words = set(slug.split("-"))
    if words & SKIP_SLUG_TERMS:
        return True
    if any(fragment in slug for fragment in SKIP_SLUG_FRAGMENTS):
        return True
    return not bool(words & ACCESSORY_SLUG_TERMS)


if __name__ == "__main__":
    raise SystemExit(main())
