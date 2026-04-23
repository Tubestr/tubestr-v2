#!/usr/bin/env python3
"""Generate a polished first-party AR filter source manifest.

The web discovery path is useful for finding CC0 candidates, but public clipart
search results are noisy. This script creates a controlled, transparent SVG
starter pack in the same source-manifest format consumed by
`import_ar_filter_assets.py`, so publishing still goes through the normal
Blossom/review pipeline.
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = REPO_ROOT / "build" / "ar_filters" / "studio_source_manifest.json"
DEFAULT_ASSET_DIR = REPO_ROOT / "build" / "ar_filters" / "studio_sources"
LICENSE = "MIT"
LICENSE_URL = "https://opensource.org/license/mit"
SOURCE_NAME = "Tubestr Studio AR Filter Pack"


@dataclass(frozen=True)
class Asset:
    key: str
    svg: str


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate a curated, first-party AR filter source manifest.",
    )
    parser.add_argument("--out", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--asset-dir", default=str(DEFAULT_ASSET_DIR))
    args = parser.parse_args()

    output = resolve_repo_path(args.out)
    asset_dir = resolve_repo_path(args.asset_dir)
    asset_dir.mkdir(parents=True, exist_ok=True)

    assets = build_assets()
    for asset in assets.values():
        (asset_dir / f"{asset.key}.svg").write_text(asset.svg)

    filters = build_filters(asset_dir, output.parent)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(filters, indent=2) + "\n")

    print(f"Generated {len(filters)} studio AR filter(s).")
    print(f"Wrote {output.relative_to(REPO_ROOT)}")
    print(f"Wrote {len(assets)} source asset(s) in {asset_dir.relative_to(REPO_ROOT)}")
    return 0


def build_filters(asset_dir: Path, manifest_dir: Path) -> list[dict[str, Any]]:
    specs = [
        face_filter(
            "studio-pup-pop",
            "Pup Pop",
            "Animal",
            "Warm puppy ears, nose, and tongue.",
            [
                p(asset_dir, manifest_dir, "dog-ear-left", "forehead", 0.36, -0.34, -0.54, -12),
                p(asset_dir, manifest_dir, "dog-ear-right", "forehead", 0.36, 0.34, -0.54, 12),
                p(asset_dir, manifest_dir, "pup-nose", "noseTip", 0.24, 0, 0.03),
                p(asset_dir, manifest_dir, "tongue", "mouthCenter", 0.22, 0, 0.22),
            ],
        ),
        face_filter(
            "studio-pup-cream",
            "Cream Pup",
            "Animal",
            "Soft cream ears with a glossy nose.",
            [
                p(asset_dir, manifest_dir, "cream-ear-left", "forehead", 0.38, -0.35, -0.56, -11),
                p(asset_dir, manifest_dir, "cream-ear-right", "forehead", 0.38, 0.35, -0.56, 11),
                p(asset_dir, manifest_dir, "pup-nose", "noseTip", 0.22, 0, 0.02),
            ],
        ),
        face_filter(
            "studio-cat-noir",
            "Cat Noir",
            "Animal",
            "Black cat ears, nose, and crisp whiskers.",
            [
                p(asset_dir, manifest_dir, "cat-ear-left", "forehead", 0.34, -0.34, -0.58, -9),
                p(asset_dir, manifest_dir, "cat-ear-right", "forehead", 0.34, 0.34, -0.58, 9),
                p(asset_dir, manifest_dir, "cat-nose", "noseTip", 0.16, 0, 0.03),
                p(asset_dir, manifest_dir, "whiskers", "noseTip", 0.74, 0, 0.08),
            ],
        ),
        face_filter(
            "studio-cat-pink",
            "Pink Cat",
            "Animal",
            "Pink-lined ears and soft whiskers.",
            [
                p(asset_dir, manifest_dir, "pink-cat-ear-left", "forehead", 0.34, -0.34, -0.58, -9),
                p(asset_dir, manifest_dir, "pink-cat-ear-right", "forehead", 0.34, 0.34, -0.58, 9),
                p(asset_dir, manifest_dir, "pink-cat-nose", "noseTip", 0.16, 0, 0.03),
                p(asset_dir, manifest_dir, "soft-whiskers", "noseTip", 0.74, 0, 0.08),
            ],
        ),
        face_filter(
            "studio-fox-flare",
            "Fox Flare",
            "Animal",
            "Orange fox ears with a tiny nose.",
            [
                p(asset_dir, manifest_dir, "fox-ear-left", "forehead", 0.38, -0.36, -0.57, -10),
                p(asset_dir, manifest_dir, "fox-ear-right", "forehead", 0.38, 0.36, -0.57, 10),
                p(asset_dir, manifest_dir, "fox-nose", "noseTip", 0.18, 0, 0.03),
            ],
        ),
        face_filter(
            "studio-bunny-cloud",
            "Bunny Cloud",
            "Animal",
            "Tall plush ears and a soft nose.",
            [
                p(asset_dir, manifest_dir, "bunny-ear-left", "forehead", 0.32, -0.27, -0.72, -7),
                p(asset_dir, manifest_dir, "bunny-ear-right", "forehead", 0.32, 0.27, -0.72, 7),
                p(asset_dir, manifest_dir, "bunny-nose", "noseTip", 0.13, 0, 0.03),
            ],
        ),
        face_filter(
            "studio-bear-plush",
            "Bear Plush",
            "Animal",
            "Rounded plush ears and nose.",
            [
                p(asset_dir, manifest_dir, "bear-ear-left", "forehead", 0.26, -0.34, -0.48, -4),
                p(asset_dir, manifest_dir, "bear-ear-right", "forehead", 0.26, 0.34, -0.48, 4),
                p(asset_dir, manifest_dir, "bear-nose", "noseTip", 0.2, 0, 0.04),
            ],
        ),
        face_filter(
            "studio-antler-glow",
            "Antler Glow",
            "Headwear",
            "Light antlers with tiny shine accents.",
            [p(asset_dir, manifest_dir, "antlers", "forehead", 1.08, 0, -0.57)],
        ),
        face_filter(
            "studio-devil-gloss",
            "Gloss Horns",
            "Headwear",
            "Glossy red horns with a subtle highlight.",
            [
                p(asset_dir, manifest_dir, "horn-left", "forehead", 0.3, -0.34, -0.5, -5),
                p(asset_dir, manifest_dir, "horn-right", "forehead", 0.3, 0.34, -0.5, 5),
            ],
        ),
        face_filter(
            "studio-halo",
            "Halo",
            "Headwear",
            "Soft golden halo.",
            [p(asset_dir, manifest_dir, "halo", "forehead", 0.72, 0, -0.64)],
        ),
        face_filter(
            "studio-flower-crown",
            "Flower Crown",
            "Headwear",
            "Layered flowers and leaves.",
            [p(asset_dir, manifest_dir, "flower-crown", "forehead", 1.02, 0, -0.5)],
        ),
        face_filter(
            "studio-tropical-crown",
            "Tropical Crown",
            "Headwear",
            "Bright flowers with green leaves.",
            [p(asset_dir, manifest_dir, "tropical-crown", "forehead", 1.02, 0, -0.5)],
        ),
        face_filter(
            "studio-gold-crown",
            "Gold Crown",
            "Headwear",
            "Polished crown with jewel accents.",
            [p(asset_dir, manifest_dir, "gold-crown", "forehead", 0.84, 0, -0.55)],
        ),
        face_filter(
            "studio-crystal-tiara",
            "Crystal Tiara",
            "Headwear",
            "Clean crystal tiara.",
            [p(asset_dir, manifest_dir, "crystal-tiara", "forehead", 0.8, 0, -0.48)],
        ),
        face_filter(
            "studio-cowboy",
            "Cowboy",
            "Headwear",
            "Clean western hat silhouette.",
            [p(asset_dir, manifest_dir, "cowboy-hat", "forehead", 0.98, 0, -0.52)],
        ),
        face_filter(
            "studio-witch",
            "Witch",
            "Headwear",
            "Tall purple hat with a moon pin.",
            [p(asset_dir, manifest_dir, "witch-hat", "forehead", 0.86, 0, -0.67, -5)],
        ),
        face_filter(
            "studio-wizard",
            "Wizard",
            "Headwear",
            "Blue starry wizard hat.",
            [p(asset_dir, manifest_dir, "wizard-hat", "forehead", 0.86, 0, -0.68, 5)],
        ),
        face_filter(
            "studio-star-shades",
            "Star Shades",
            "Eyewear",
            "Bold star sunglasses.",
            [p(asset_dir, manifest_dir, "star-shades", "eyesBridge", 1.02, 0, 0.0)],
        ),
        face_filter(
            "studio-heart-shades",
            "Heart Shades",
            "Eyewear",
            "Pink heart sunglasses.",
            [p(asset_dir, manifest_dir, "heart-shades", "eyesBridge", 1.02, 0, 0.0)],
        ),
        face_filter(
            "studio-chrome-shades",
            "Chrome Shades",
            "Eyewear",
            "Reflective visor-style shades.",
            [p(asset_dir, manifest_dir, "chrome-shades", "eyesBridge", 1.08, 0, 0.0)],
        ),
        face_filter(
            "studio-neon-visor",
            "Neon Visor",
            "Eyewear",
            "Cyber visor with cyan and magenta accents.",
            [p(asset_dir, manifest_dir, "neon-visor", "eyesBridge", 1.12, 0, 0.0)],
        ),
        face_filter(
            "studio-retro-glasses",
            "Retro Glasses",
            "Eyewear",
            "Chunky retro frames.",
            [p(asset_dir, manifest_dir, "retro-glasses", "eyesBridge", 1.02, 0, 0.0)],
        ),
        face_filter(
            "studio-round-glasses",
            "Round Glasses",
            "Eyewear",
            "Wire round glasses with sparkle.",
            [
                p(asset_dir, manifest_dir, "round-glasses", "eyesBridge", 0.92, 0, 0.0),
                p(asset_dir, manifest_dir, "sparkle-small", "forehead", 0.22, 0.42, -0.36, 15),
            ],
        ),
        face_filter(
            "studio-butterfly-mask",
            "Butterfly Mask",
            "Masks",
            "Butterfly mask with layered color.",
            [p(asset_dir, manifest_dir, "butterfly-mask", "eyesBridge", 1.16, 0, 0.02)],
        ),
        face_filter(
            "studio-gold-mask",
            "Gold Mask",
            "Masks",
            "Masquerade mask with gold trim.",
            [p(asset_dir, manifest_dir, "gold-mask", "eyesBridge", 1.12, 0, 0.02)],
        ),
        face_filter(
            "studio-cyber-mask",
            "Cyber Mask",
            "Masks",
            "Angular chrome half mask.",
            [p(asset_dir, manifest_dir, "cyber-mask", "eyesBridge", 1.08, 0, 0.04)],
        ),
        face_filter(
            "studio-glitter-freckles",
            "Glitter Freckles",
            "Effects",
            "Tiny stars around the cheeks.",
            [
                p(asset_dir, manifest_dir, "freckles-left", "leftEye", 0.32, -0.06, 0.28, -8),
                p(asset_dir, manifest_dir, "freckles-right", "rightEye", 0.32, 0.06, 0.28, 8),
            ],
        ),
        face_filter(
            "studio-heart-blush",
            "Heart Blush",
            "Effects",
            "Small heart blush marks.",
            [
                p(asset_dir, manifest_dir, "heart-blush-left", "leftEye", 0.25, -0.1, 0.32, -8),
                p(asset_dir, manifest_dir, "heart-blush-right", "rightEye", 0.25, 0.1, 0.32, 8),
            ],
        ),
        face_filter(
            "studio-creator-spark",
            "Creator Spark",
            "Effects",
            "Asymmetric sparkle accents.",
            [
                p(asset_dir, manifest_dir, "spark-cluster", "forehead", 0.42, -0.42, -0.42, -12),
                p(asset_dir, manifest_dir, "sparkle-small", "forehead", 0.24, 0.42, -0.32, 18),
            ],
        ),
        face_filter(
            "studio-star-dust",
            "Star Dust",
            "Effects",
            "Soft star accents across the forehead.",
            [p(asset_dir, manifest_dir, "star-dust", "forehead", 0.96, 0, -0.46)],
        ),
        face_filter(
            "studio-lightning",
            "Lightning",
            "Effects",
            "Graphic lightning cheek marks.",
            [
                p(asset_dir, manifest_dir, "lightning-left", "leftEye", 0.28, -0.1, 0.32, -8),
                p(asset_dir, manifest_dir, "lightning-right", "rightEye", 0.28, 0.1, 0.32, 8),
            ],
        ),
        face_filter(
            "studio-headphones",
            "Headphones",
            "Creator",
            "Bright streamer headphones.",
            [p(asset_dir, manifest_dir, "headphones", "eyesBridge", 1.16, 0, -0.21)],
        ),
        face_filter(
            "studio-monocle-stache",
            "Monocle Stache",
            "Creator",
            "Monocle and curled mustache.",
            [
                p(asset_dir, manifest_dir, "monocle", "rightEye", 0.36, 0, 0.02),
                p(asset_dir, manifest_dir, "curly-stache", "mouthCenter", 0.58, 0, -0.12),
            ],
        ),
        face_filter(
            "studio-comic-stache",
            "Comic Stache",
            "Creator",
            "Big curled mustache and bow tie.",
            [
                p(asset_dir, manifest_dir, "curly-stache", "mouthCenter", 0.64, 0, -0.12),
                p(asset_dir, manifest_dir, "bow-tie", "mouthCenter", 0.52, 0, 0.5),
            ],
        ),
        face_filter(
            "studio-bow-shades",
            "Bow Shades",
            "Creator",
            "Dark shades and a bright bow tie.",
            [
                p(asset_dir, manifest_dir, "chrome-shades", "eyesBridge", 1.02, 0, 0),
                p(asset_dir, manifest_dir, "bow-tie", "mouthCenter", 0.52, 0, 0.5),
            ],
        ),
        face_filter(
            "studio-laurel",
            "Laurel",
            "Headwear",
            "Clean laurel crown.",
            [p(asset_dir, manifest_dir, "laurel", "forehead", 0.9, 0, -0.48)],
        ),
    ]
    return specs


def build_assets() -> dict[str, Asset]:
    asset_svgs = {
        "dog-ear-left": ear("#8b5a3c", "#d69a70", "#fff0d7", flip=False),
        "dog-ear-right": ear("#8b5a3c", "#d69a70", "#fff0d7", flip=True),
        "cream-ear-left": ear("#e9c69a", "#f5dfbf", "#fff5e4", flip=False),
        "cream-ear-right": ear("#e9c69a", "#f5dfbf", "#fff5e4", flip=True),
        "cat-ear-left": cat_ear("#111827", "#374151", "#f7a6c8", flip=False),
        "cat-ear-right": cat_ear("#111827", "#374151", "#f7a6c8", flip=True),
        "pink-cat-ear-left": cat_ear("#d44b86", "#f59ac1", "#ffe0ee", flip=False),
        "pink-cat-ear-right": cat_ear("#d44b86", "#f59ac1", "#ffe0ee", flip=True),
        "fox-ear-left": cat_ear("#d85b20", "#f4983a", "#fff1da", flip=False),
        "fox-ear-right": cat_ear("#d85b20", "#f4983a", "#fff1da", flip=True),
        "bunny-ear-left": bunny_ear(flip=False),
        "bunny-ear-right": bunny_ear(flip=True),
        "bear-ear-left": round_ear("#7a4b2d", "#b87648", "#e5b17f"),
        "bear-ear-right": round_ear("#7a4b2d", "#b87648", "#e5b17f"),
        "pup-nose": nose("#211827", "#40313f"),
        "cat-nose": nose("#111827", "#374151", heart=True),
        "pink-cat-nose": nose("#ec6aa6", "#ffafd0", heart=True),
        "fox-nose": nose("#24150f", "#513326"),
        "bunny-nose": nose("#e979a2", "#ffbfd6", heart=True),
        "bear-nose": nose("#3b251b", "#6b4635"),
        "tongue": tongue(),
        "whiskers": whiskers("#111827"),
        "soft-whiskers": whiskers("#4b5563"),
        "antlers": antlers(),
        "horn-left": horn(flip=False),
        "horn-right": horn(flip=True),
        "halo": halo(),
        "flower-crown": flower_crown("#f472b6", "#fbbf24", "#34d399"),
        "tropical-crown": flower_crown("#fb7185", "#22d3ee", "#65a30d"),
        "gold-crown": crown(),
        "crystal-tiara": tiara(),
        "cowboy-hat": cowboy_hat(),
        "witch-hat": witch_hat(),
        "wizard-hat": wizard_hat(),
        "star-shades": star_shades(),
        "heart-shades": heart_shades(),
        "chrome-shades": chrome_shades(),
        "neon-visor": neon_visor(),
        "retro-glasses": retro_glasses(),
        "round-glasses": round_glasses(),
        "butterfly-mask": butterfly_mask(),
        "gold-mask": gold_mask(),
        "cyber-mask": cyber_mask(),
        "freckles-left": freckles("#fbbf24"),
        "freckles-right": freckles("#f472b6"),
        "heart-blush-left": heart_blush("#fb7185"),
        "heart-blush-right": heart_blush("#fb7185"),
        "spark-cluster": spark_cluster("#facc15", "#22d3ee"),
        "sparkle-small": spark_cluster("#f472b6", "#facc15"),
        "star-dust": star_dust(),
        "lightning-left": lightning("#fde047", "#f97316"),
        "lightning-right": lightning("#fde047", "#f97316", flip=True),
        "headphones": headphones(),
        "monocle": monocle(),
        "curly-stache": curly_stache(),
        "bow-tie": bow_tie(),
        "laurel": laurel(),
    }
    return {key: Asset(key, value) for key, value in asset_svgs.items()}


def p(
    asset_dir: Path,
    manifest_dir: Path,
    key: str,
    anchor: str,
    width_scale: float,
    offset_x: float,
    offset_y: float,
    rotation: float = 0,
    opacity: float = 1,
) -> dict[str, Any]:
    source = asset_dir / f"{key}.svg"
    return {
        "localPath": relative_path(source, manifest_dir),
        "anchor": anchor,
        "widthScale": width_scale,
        "offsetX": offset_x,
        "offsetY": offset_y,
        "rotationDegrees": rotation,
        "opacity": opacity,
    }


def relative_path(path: Path, root: Path) -> str:
    try:
        return str(path.relative_to(root))
    except ValueError:
        return str(path)


def face_filter(
    filter_id: str,
    label: str,
    category: str,
    description: str,
    parts: list[dict[str, Any]],
) -> dict[str, Any]:
    return {
        "id": filter_id,
        "label": label,
        "category": category,
        "description": description,
        "sourceName": SOURCE_NAME,
        "sourceUrl": "scripts/generate_ar_filter_studio_pack.py",
        "license": LICENSE,
        "licenseUrl": LICENSE_URL,
        "attribution": "Tubestr original vector AR assets.",
        "parts": parts,
    }


def resolve_repo_path(value: str) -> Path:
    path = Path(value)
    return path if path.is_absolute() else REPO_ROOT / path


def svg(body: str, defs: str = "", view_box: str = "0 0 512 512") -> str:
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{view_box}">\n'
        f"  <defs>{defs}</defs>\n"
        f"{body}\n"
        "</svg>\n"
    )


def ear(outer: str, mid: str, inner: str, *, flip: bool) -> str:
    transform = ' transform="translate(512 0) scale(-1 1)"' if flip else ""
    return svg(
        f'<g{transform}>'
        f'<path d="M122 448 C76 330 86 160 222 42 C273 185 263 342 122 448Z" fill="{outer}"/>'
        f'<path d="M151 392 C124 292 137 176 219 91 C242 211 228 320 151 392Z" fill="{mid}"/>'
        f'<path d="M178 330 C162 255 172 190 211 142 C222 230 208 294 178 330Z" fill="{inner}" opacity=".92"/>'
        '</g>'
    )


def cat_ear(outer: str, mid: str, inner: str, *, flip: bool) -> str:
    transform = ' transform="translate(512 0) scale(-1 1)"' if flip else ""
    return svg(
        f'<g{transform}>'
        f'<path d="M98 446 L210 42 L324 446 Z" fill="{outer}"/>'
        f'<path d="M138 402 L211 120 L286 402 Z" fill="{mid}"/>'
        f'<path d="M176 358 L213 188 L252 358 Z" fill="{inner}"/>'
        '<path d="M120 424 C182 456 245 456 304 424" fill="none" stroke="#ffffff" stroke-opacity=".2" stroke-width="18" stroke-linecap="round"/>'
        '</g>'
    )


def bunny_ear(*, flip: bool) -> str:
    transform = ' transform="translate(512 0) scale(-1 1)"' if flip else ""
    return svg(
        f'<g{transform}>'
        '<path d="M180 470 C103 342 103 112 223 34 C309 170 310 376 180 470Z" fill="#f8fafc"/>'
        '<path d="M192 402 C149 298 157 150 224 82 C269 203 264 330 192 402Z" fill="#f9a8d4"/>'
        '<path d="M167 464 C236 473 290 432 308 365" fill="none" stroke="#d1d5db" stroke-width="18" stroke-linecap="round"/>'
        '</g>'
    )


def round_ear(outer: str, mid: str, inner: str) -> str:
    return svg(
        f'<circle cx="256" cy="256" r="184" fill="{outer}"/>'
        f'<circle cx="256" cy="256" r="132" fill="{mid}"/>'
        f'<circle cx="256" cy="256" r="74" fill="{inner}" opacity=".82"/>'
    )


def nose(color: str, shine: str, *, heart: bool = False) -> str:
    shape = (
        'M256 364 C188 300 130 252 154 190 C174 139 235 151 256 196 '
        'C277 151 338 139 358 190 C382 252 324 300 256 364Z'
        if heart
        else 'M256 354 C169 354 116 305 137 237 C154 180 214 158 256 176 C298 158 358 180 375 237 C396 305 343 354 256 354Z'
    )
    return svg(
        f'<path d="{shape}" fill="{color}"/>'
        f'<ellipse cx="224" cy="226" rx="34" ry="21" fill="{shine}" opacity=".78"/>'
        '<ellipse cx="214" cy="212" rx="14" ry="8" fill="#ffffff" opacity=".38"/>'
    )


def tongue() -> str:
    return svg(
        '<path d="M162 122 C214 170 297 170 350 122 C362 262 335 424 256 458 C177 424 150 262 162 122Z" fill="#fb7185"/>'
        '<path d="M256 174 C250 260 250 342 256 430" fill="none" stroke="#e11d48" stroke-width="14" stroke-linecap="round" opacity=".55"/>'
        '<ellipse cx="220" cy="216" rx="38" ry="20" fill="#fecdd3" opacity=".7"/>'
    )


def whiskers(color: str) -> str:
    lines = []
    for y, rot in [(202, -10), (256, 0), (310, 10)]:
        lines.append(
            f'<path d="M44 {y} C142 {y - 20} 190 {y - 18} 236 {y}" fill="none" stroke="{color}" stroke-width="18" stroke-linecap="round" transform="rotate({rot} 256 256)"/>'
        )
        lines.append(
            f'<path d="M276 {y} C322 {y - 18} 370 {y - 20} 468 {y}" fill="none" stroke="{color}" stroke-width="18" stroke-linecap="round" transform="rotate({-rot} 256 256)"/>'
        )
    return svg("".join(lines))


def antlers() -> str:
    return svg(
        '<g fill="none" stroke="#e8d5a5" stroke-width="28" stroke-linecap="round" stroke-linejoin="round">'
        '<path d="M208 430 C172 312 156 218 116 92"/>'
        '<path d="M150 250 L82 180"/><path d="M166 190 L196 112"/><path d="M130 134 L76 82"/>'
        '<path d="M304 430 C340 312 356 218 396 92"/>'
        '<path d="M362 250 L430 180"/><path d="M346 190 L316 112"/><path d="M382 134 L436 82"/>'
        '</g>'
        '<g fill="#fff7ed" opacity=".9"><circle cx="92" cy="180" r="12"/><circle cx="420" cy="180" r="12"/><circle cx="196" cy="112" r="10"/><circle cx="316" cy="112" r="10"/></g>'
    )


def horn(*, flip: bool) -> str:
    transform = ' transform="translate(512 0) scale(-1 1)"' if flip else ""
    return svg(
        f'<g{transform}>'
        '<path d="M154 430 C130 260 172 122 294 50 C312 220 270 362 154 430Z" fill="#dc2626"/>'
        '<path d="M185 354 C170 244 201 154 276 96 C280 224 248 314 185 354Z" fill="#fb7185" opacity=".88"/>'
        '<path d="M173 416 C224 408 265 370 292 318" fill="none" stroke="#7f1d1d" stroke-width="18" stroke-linecap="round" opacity=".5"/>'
        '</g>'
    )


def halo() -> str:
    return svg(
        '<ellipse cx="256" cy="256" rx="202" ry="78" fill="none" stroke="#fde68a" stroke-width="42"/>'
        '<ellipse cx="256" cy="256" rx="202" ry="78" fill="none" stroke="#facc15" stroke-width="18"/>'
        '<ellipse cx="256" cy="232" rx="176" ry="54" fill="none" stroke="#fff7ad" stroke-width="14" opacity=".78"/>'
    )


def flower_crown(a: str, b: str, leaf: str) -> str:
    flowers = []
    for x, y, scale, color in [
        (86, 278, 0.85, a),
        (154, 218, 1.0, b),
        (244, 196, 1.08, a),
        (336, 218, 1.0, b),
        (424, 278, 0.85, a),
    ]:
        flowers.append(flower(x, y, scale, color))
    return svg(
        '<path d="M54 320 C154 210 356 210 458 320" fill="none" stroke="#14532d" stroke-width="28" stroke-linecap="round"/>'
        f'<g fill="{leaf}" opacity=".9"><ellipse cx="112" cy="258" rx="28" ry="56" transform="rotate(-48 112 258)"/><ellipse cx="398" cy="258" rx="28" ry="56" transform="rotate(48 398 258)"/><ellipse cx="257" cy="190" rx="24" ry="48" transform="rotate(4 257 190)"/></g>'
        + "".join(flowers)
    )


def flower(x: int, y: int, scale: float, color: str) -> str:
    petals = []
    for angle in range(0, 360, 60):
        petals.append(
            f'<ellipse cx="{x}" cy="{y - int(34 * scale)}" rx="{int(25 * scale)}" ry="{int(40 * scale)}" fill="{color}" transform="rotate({angle} {x} {y})"/>'
        )
    return f'<g>{ "".join(petals) }<circle cx="{x}" cy="{y}" r="{int(24 * scale)}" fill="#fef3c7"/></g>'


def crown() -> str:
    return svg(
        '<path d="M54 384 L88 152 L174 292 L256 104 L338 292 L424 152 L458 384 Z" fill="#f59e0b"/>'
        '<path d="M82 384 H430 V430 H82 Z" fill="#b45309"/>'
        '<circle cx="256" cy="104" r="28" fill="#ef4444"/><circle cx="88" cy="152" r="22" fill="#22d3ee"/><circle cx="424" cy="152" r="22" fill="#22d3ee"/>'
        '<path d="M116 354 H396" stroke="#fde68a" stroke-width="18" stroke-linecap="round"/>'
    )


def tiara() -> str:
    return svg(
        '<path d="M78 366 C170 312 342 312 434 366" fill="none" stroke="#c4b5fd" stroke-width="32" stroke-linecap="round"/>'
        '<path d="M112 344 L168 216 L224 328 L256 150 L288 328 L344 216 L400 344" fill="none" stroke="#f8fafc" stroke-width="24" stroke-linejoin="round"/>'
        '<g fill="#67e8f9"><circle cx="168" cy="216" r="20"/><circle cx="256" cy="150" r="24"/><circle cx="344" cy="216" r="20"/></g>'
    )


def cowboy_hat() -> str:
    return svg(
        '<path d="M86 322 C126 144 190 102 256 164 C322 102 386 144 426 322 C318 280 194 280 86 322Z" fill="#8b5e34"/>'
        '<path d="M32 348 C124 292 388 292 480 348 C444 402 68 402 32 348Z" fill="#6b3f22"/>'
        '<path d="M155 244 C206 276 306 276 357 244" fill="none" stroke="#facc15" stroke-width="18" stroke-linecap="round"/>'
    )


def witch_hat() -> str:
    return svg(
        '<path d="M178 378 L274 48 L370 378 Z" fill="#4c1d95"/>'
        '<path d="M36 378 C132 324 380 324 476 378 C420 438 92 438 36 378Z" fill="#312e81"/>'
        '<path d="M146 338 H366" stroke="#f59e0b" stroke-width="26" stroke-linecap="round"/>'
        '<path d="M334 132 A42 42 0 1 0 374 196 A34 34 0 1 1 334 132Z" fill="#fde68a"/>'
    )


def wizard_hat() -> str:
    return svg(
        '<path d="M160 388 L248 44 C290 130 340 230 386 388 Z" fill="#1d4ed8"/>'
        '<path d="M40 382 C140 326 372 326 472 382 C420 438 92 438 40 382Z" fill="#1e3a8a"/>'
        '<g fill="#fde68a"><path d="M244 156 L260 192 L300 196 L270 222 L280 260 L244 240 L208 260 L218 222 L188 196 L228 192Z"/><circle cx="306" cy="292" r="16"/><circle cx="222" cy="332" r="12"/></g>'
    )


def star_shades() -> str:
    return svg(
        '<path d="M130 154 L166 224 L244 236 L188 292 L202 370 L130 334 L58 370 L72 292 L16 236 L94 224 Z" fill="#111827"/>'
        '<path d="M382 154 L418 224 L496 236 L440 292 L454 370 L382 334 L310 370 L324 292 L268 236 L346 224 Z" fill="#111827"/>'
        '<path d="M222 258 C244 246 268 246 290 258" fill="none" stroke="#111827" stroke-width="26" stroke-linecap="round"/>'
        '<path d="M91 246 H172 M343 246 H424" stroke="#facc15" stroke-width="16" stroke-linecap="round" opacity=".9"/>'
    )


def heart_shades() -> str:
    return svg(
        '<path d="M132 356 C42 276 26 196 84 152 C126 120 178 140 204 184 C230 140 282 120 324 152 C382 196 366 276 276 356 L204 422Z" fill="#111827" transform="translate(-42 0) scale(.86)"/>'
        '<path d="M132 356 C42 276 26 196 84 152 C126 120 178 140 204 184 C230 140 282 120 324 152 C382 196 366 276 276 356 L204 422Z" fill="#111827" transform="translate(202 0) scale(.86)"/>'
        '<path d="M216 255 C244 238 268 238 296 255" fill="none" stroke="#111827" stroke-width="24" stroke-linecap="round"/>'
        '<path d="M90 220 C126 184 170 184 196 224 M334 220 C370 184 414 184 440 224" stroke="#fb7185" stroke-width="14" stroke-linecap="round" fill="none"/>'
    )


def chrome_shades() -> str:
    return svg(
        '<path d="M58 184 C130 150 210 152 254 194 C302 152 382 150 454 184 C438 278 396 332 314 324 C282 320 266 296 256 264 C246 296 230 320 198 324 C116 332 74 278 58 184Z" fill="#0f172a"/>'
        '<path d="M86 202 C152 182 202 188 232 214 C220 260 186 288 122 282 C104 258 92 232 86 202Z" fill="#67e8f9" opacity=".75"/>'
        '<path d="M426 202 C360 182 310 188 280 214 C292 260 326 288 390 282 C408 258 420 232 426 202Z" fill="#f472b6" opacity=".75"/>'
        '<path d="M96 214 H224 M288 214 H416" stroke="#ffffff" stroke-width="12" opacity=".55" stroke-linecap="round"/>'
    )


def neon_visor() -> str:
    return svg(
        '<path d="M58 210 C154 152 358 152 454 210 L420 310 C316 344 196 344 92 310Z" fill="#111827"/>'
        '<path d="M92 226 C174 190 338 190 420 226 L398 276 C306 300 206 300 114 276Z" fill="#0e7490" opacity=".75"/>'
        '<path d="M96 226 C186 182 326 182 416 226" fill="none" stroke="#22d3ee" stroke-width="16" stroke-linecap="round"/>'
        '<path d="M122 294 C218 322 294 322 390 294" fill="none" stroke="#f472b6" stroke-width="12" stroke-linecap="round"/>'
    )


def retro_glasses() -> str:
    return svg(
        '<rect x="42" y="174" width="184" height="146" rx="52" fill="#111827"/>'
        '<rect x="286" y="174" width="184" height="146" rx="52" fill="#111827"/>'
        '<path d="M224 242 C246 230 266 230 288 242" fill="none" stroke="#111827" stroke-width="28" stroke-linecap="round"/>'
        '<rect x="76" y="202" width="116" height="84" rx="30" fill="#fbbf24" opacity=".75"/>'
        '<rect x="320" y="202" width="116" height="84" rx="30" fill="#fbbf24" opacity=".75"/>'
    )


def round_glasses() -> str:
    return svg(
        '<circle cx="158" cy="250" r="82" fill="none" stroke="#111827" stroke-width="24"/>'
        '<circle cx="354" cy="250" r="82" fill="none" stroke="#111827" stroke-width="24"/>'
        '<path d="M240 250 C250 240 262 240 272 250" fill="none" stroke="#111827" stroke-width="18" stroke-linecap="round"/>'
        '<path d="M120 220 L188 286 M316 220 L386 286" stroke="#93c5fd" stroke-width="14" stroke-linecap="round" opacity=".7"/>'
    )


def butterfly_mask() -> str:
    return svg(
        '<path d="M254 256 C178 122 54 116 36 256 C64 390 178 374 254 256Z" fill="#7c3aed"/>'
        '<path d="M258 256 C334 122 458 116 476 256 C448 390 334 374 258 256Z" fill="#ec4899"/>'
        '<path d="M106 246 C146 210 188 212 224 250 C176 278 140 276 106 246Z" fill="#111827"/>'
        '<path d="M406 246 C366 210 324 212 288 250 C336 278 372 276 406 246Z" fill="#111827"/>'
        '<path d="M256 156 C240 218 240 294 256 356 C272 294 272 218 256 156Z" fill="#f8fafc" opacity=".6"/>'
    )


def gold_mask() -> str:
    return svg(
        '<path d="M48 244 C124 156 200 164 256 226 C312 164 388 156 464 244 C410 342 322 344 256 282 C190 344 102 342 48 244Z" fill="#b45309"/>'
        '<path d="M82 246 C132 202 180 204 222 242 C176 276 128 276 82 246Z" fill="#111827"/>'
        '<path d="M430 246 C380 202 332 204 290 242 C336 276 384 276 430 246Z" fill="#111827"/>'
        '<path d="M62 242 C132 176 202 178 256 232 C310 178 380 176 450 242" fill="none" stroke="#facc15" stroke-width="18" stroke-linecap="round"/>'
    )


def cyber_mask() -> str:
    return svg(
        '<path d="M56 220 L158 158 H230 L256 206 L282 158 H354 L456 220 L408 318 H300 L256 282 L212 318 H104Z" fill="#0f172a"/>'
        '<path d="M92 232 L168 192 H220 L198 260 H116Z" fill="#22d3ee" opacity=".65"/>'
        '<path d="M420 232 L344 192 H292 L314 260 H396Z" fill="#f472b6" opacity=".65"/>'
        '<path d="M104 314 H204 M308 314 H408" stroke="#94a3b8" stroke-width="12" stroke-linecap="round"/>'
    )


def freckles(color: str) -> str:
    return svg(
        f'<g fill="{color}">'
        '<circle cx="140" cy="224" r="14"/><circle cx="224" cy="196" r="10"/><circle cx="304" cy="230" r="12"/><circle cx="198" cy="292" r="9"/><circle cx="334" cy="306" r="8"/>'
        '<path d="M378 160 L392 194 L428 198 L400 220 L410 256 L378 236 L346 256 L356 220 L328 198 L364 194Z"/>'
        '</g>'
    )


def heart_blush(color: str) -> str:
    return svg(
        f'<path d="M256 364 C170 286 112 234 138 170 C160 118 226 130 256 184 C286 130 352 118 374 170 C400 234 342 286 256 364Z" fill="{color}" opacity=".9"/>'
        '<path d="M188 190 C216 164 250 170 270 204" fill="none" stroke="#fff1f2" stroke-width="16" stroke-linecap="round" opacity=".72"/>'
    )


def spark_cluster(a: str, b: str) -> str:
    return svg(
        f'<path d="M248 58 L286 190 L420 228 L286 268 L248 402 L208 268 L74 228 L208 190Z" fill="{a}"/>'
        f'<path d="M390 76 L410 140 L476 160 L410 180 L390 244 L370 180 L304 160 L370 140Z" fill="{b}"/>'
        '<circle cx="126" cy="112" r="28" fill="#ffffff" opacity=".78"/>'
    )


def star_dust() -> str:
    return svg(
        '<g fill="#fde68a">'
        '<path d="M92 300 L112 352 L166 360 L124 394 L138 448 L92 418 L46 448 L60 394 L18 360 L72 352Z"/>'
        '<path d="M256 132 L282 202 L356 212 L300 258 L318 332 L256 292 L194 332 L212 258 L156 212 L230 202Z"/>'
        '<path d="M420 300 L440 352 L494 360 L452 394 L466 448 L420 418 L374 448 L388 394 L346 360 L400 352Z"/>'
        '</g>'
        '<g fill="#f472b6"><circle cx="144" cy="164" r="18"/><circle cx="368" cy="164" r="18"/></g>'
    )


def lightning(a: str, b: str, *, flip: bool = False) -> str:
    transform = ' transform="translate(512 0) scale(-1 1)"' if flip else ""
    return svg(
        f'<g{transform}>'
        f'<path d="M300 48 L134 270 H242 L190 464 L384 214 H270Z" fill="{a}"/>'
        f'<path d="M292 86 L178 246 H282 L236 386 L344 236 H238Z" fill="{b}" opacity=".58"/>'
        '</g>'
    )


def headphones() -> str:
    return svg(
        '<path d="M94 302 C92 150 160 70 256 70 C352 70 420 150 418 302" fill="none" stroke="#111827" stroke-width="42" stroke-linecap="round"/>'
        '<rect x="44" y="248" width="100" height="154" rx="38" fill="#22d3ee"/>'
        '<rect x="368" y="248" width="100" height="154" rx="38" fill="#f472b6"/>'
        '<path d="M128 292 C208 336 304 336 384 292" fill="none" stroke="#facc15" stroke-width="16" stroke-linecap="round"/>'
    )


def monocle() -> str:
    return svg(
        '<circle cx="240" cy="226" r="122" fill="none" stroke="#facc15" stroke-width="28"/>'
        '<circle cx="240" cy="226" r="84" fill="#bfdbfe" opacity=".35"/>'
        '<path d="M320 326 C370 382 404 428 424 476" fill="none" stroke="#facc15" stroke-width="18" stroke-linecap="round"/>'
        '<path d="M180 178 L272 274" stroke="#ffffff" stroke-width="16" stroke-linecap="round" opacity=".72"/>'
    )


def curly_stache() -> str:
    return svg(
        '<path d="M256 246 C198 168 94 174 58 246 C30 304 88 358 148 316 C176 296 188 266 208 256 C226 246 242 250 256 270 C270 250 286 246 304 256 C324 266 336 296 364 316 C424 358 482 304 454 246 C418 174 314 168 256 246Z" fill="#111827"/>'
        '<path d="M142 246 C110 258 98 286 126 292 M370 246 C402 258 414 286 386 292" fill="none" stroke="#374151" stroke-width="14" stroke-linecap="round"/>'
    )


def bow_tie() -> str:
    return svg(
        '<path d="M244 256 C178 182 88 150 54 206 C20 262 88 330 244 256Z" fill="#ef4444"/>'
        '<path d="M268 256 C334 182 424 150 458 206 C492 262 424 330 268 256Z" fill="#ef4444"/>'
        '<rect x="222" y="218" width="68" height="76" rx="18" fill="#991b1b"/>'
        '<path d="M86 218 C128 232 170 246 214 256 M426 218 C384 232 342 246 298 256" stroke="#fecaca" stroke-width="12" stroke-linecap="round" opacity=".65"/>'
    )


def laurel() -> str:
    leaves = []
    for i in range(7):
        y = 360 - i * 34
        x = 102 + i * 22
        leaves.append(f'<ellipse cx="{x}" cy="{y}" rx="22" ry="44" fill="#16a34a" transform="rotate(-42 {x} {y})"/>')
        xr = 512 - x
        leaves.append(f'<ellipse cx="{xr}" cy="{y}" rx="22" ry="44" fill="#16a34a" transform="rotate(42 {xr} {y})"/>')
    return svg(
        '<path d="M84 398 C126 276 182 198 236 128" fill="none" stroke="#166534" stroke-width="18" stroke-linecap="round"/>'
        '<path d="M428 398 C386 276 330 198 276 128" fill="none" stroke="#166534" stroke-width="18" stroke-linecap="round"/>'
        + "".join(leaves)
    )


if __name__ == "__main__":
    raise SystemExit(main())
