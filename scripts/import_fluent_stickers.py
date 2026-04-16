#!/usr/bin/env python3
"""Import a curated Microsoft Fluent Emoji sticker pack.

The editor currently renders bundled stickers as PNG assets. Fluent Emoji ships
SVG source art, so this script downloads the selected flat SVGs, converts them
to transparent PNGs, and regenerates the Dart catalog entries.
"""

from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.parse
import urllib.request
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
STICKER_DIR = REPO_ROOT / "assets" / "editor" / "stickers"
CATALOG_PATH = REPO_ROOT / "lib" / "services" / "editor" / "generated_sticker_catalog.dart"
LICENSE_PATH = STICKER_DIR / "FLUENT_EMOJI_LICENSE.txt"
NOTICE_PATH = STICKER_DIR / "FLUENT_EMOJI_NOTICE.md"

TREE_URL = "https://api.github.com/repos/microsoft/fluentui-emoji/git/trees/main?recursive=1"
RAW_BASE_URL = "https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/"
LICENSE_URL = "https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/LICENSE"

STICKER_LABELS = [
    "Grinning face",
    "Grinning face with big eyes",
    "Grinning face with smiling eyes",
    "Beaming face with smiling eyes",
    "Grinning squinting face",
    "Rolling on the floor laughing",
    "Face with tears of joy",
    "Slightly smiling face",
    "Upside-down face",
    "Winking face",
    "Smiling face with smiling eyes",
    "Smiling face with halo",
    "Smiling face with hearts",
    "Smiling face with heart-eyes",
    "Star-struck",
    "Face blowing a kiss",
    "Kissing face with closed eyes",
    "Smiling face with tear",
    "Face savoring food",
    "Face with tongue",
    "Zany face",
    "Squinting face with tongue",
    "Money-mouth face",
    "Smiling face with sunglasses",
    "Nerd face",
    "Face with monocle",
    "Partying face",
    "Cowboy hat face",
    "Clown face",
    "Ghost",
    "Alien",
    "Robot",
    "Thinking face",
    "Shushing face",
    "Face with hand over mouth",
    "Saluting face",
    "Melting face",
    "Exploding head",
    "Flushed face",
    "Pleading face",
    "Face screaming in fear",
    "Red heart",
    "Orange heart",
    "Yellow heart",
    "Green heart",
    "Blue heart",
    "Purple heart",
    "White heart",
    "Sparkling heart",
    "Heart with arrow",
    "Heart with ribbon",
    "Growing heart",
    "Beating heart",
    "Revolving hearts",
    "Two hearts",
    "Heart on fire",
    "Hundred points",
    "Collision",
    "Dizzy",
    "Dashing away",
    "Party popper",
    "Confetti ball",
    "Balloon",
    "Wrapped gift",
    "Birthday cake",
    "Sparkles",
    "Glowing star",
    "Star",
    "Rainbow",
    "Fire",
    "High voltage",
    "Trophy",
    "Sports medal",
    "1st place medal",
    "2nd place medal",
    "3rd place medal",
    "Soccer ball",
    "Basketball",
    "Baseball",
    "Softball",
    "Tennis",
    "Volleyball",
    "Flying disc",
    "Kite",
    "Yo-yo",
    "Magic wand",
    "Video game",
    "Joystick",
    "Artist palette",
    "Musical notes",
    "Microphone",
    "Headphone",
    "Guitar",
    "Drum",
    "Trumpet",
    "Violin",
    "Dog face",
    "Cat face",
    "Mouse face",
    "Hamster",
    "Rabbit face",
    "Fox",
    "Bear",
    "Panda",
    "Koala",
    "Tiger face",
    "Lion",
    "Cow face",
    "Pig face",
    "Frog",
    "Monkey face",
    "Chicken",
    "Penguin",
    "Bird",
    "Unicorn",
    "Butterfly",
    "Lady beetle",
    "Turtle",
    "Octopus",
    "Dolphin",
    "Whale",
    "Blowfish",
    "Tropical fish",
    "Fish",
    "Shark",
    "Snail",
    "Blossom",
    "Sunflower",
    "Four leaf clover",
    "Cactus",
    "Mushroom",
    "Pizza",
    "Hamburger",
    "French fries",
    "Hot dog",
    "Taco",
    "Burrito",
    "Popcorn",
    "Doughnut",
    "Cookie",
    "Candy",
    "Lollipop",
    "Ice cream",
    "Soft ice cream",
    "Cupcake",
    "Watermelon",
    "Strawberry",
    "Banana",
    "Red apple",
    "Grapes",
    "Cherries",
    "Rocket",
    "Flying saucer",
    "Airplane",
    "Bicycle",
    "Roller skate",
    "Skateboard",
    "Camera",
    "Movie camera",
    "Clapper board",
    "Television",
    "Laptop",
    "Light bulb",
    "Magnet",
    "Gem stone",
    "Crown",
    "Ring",
    "Sunglasses",
]


def fetch_text(url: str) -> str:
    with urllib.request.urlopen(url) as response:
        return response.read().decode("utf-8")


def download_file(url: str, destination: Path) -> None:
    with urllib.request.urlopen(url) as response:
        destination.write_bytes(response.read())


def slugify(label: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "_", label.lower()).strip("_")
    return slug


def build_flat_asset_map() -> dict[str, str]:
    payload = json.loads(fetch_text(TREE_URL))
    paths = [
        item["path"]
        for item in payload["tree"]
        if item["path"].startswith("assets/")
        and "/Flat/" in item["path"]
        and item["path"].endswith("_flat.svg")
    ]
    return {path.split("/")[1]: path for path in paths}


def convert_svg_to_png(svg_path: Path, png_path: Path) -> None:
    subprocess.run(
        [
            "magick",
            "-background",
            "none",
            "-density",
            "384",
            str(svg_path),
            "-resize",
            "256x256",
            str(png_path),
        ],
        check=True,
    )


def write_catalog(entries: list[tuple[str, str, str]]) -> None:
    lines = [
        "// Generated by scripts/import_fluent_stickers.py. Do not edit by hand.",
        "",
        "import '../../domain/models/editor_resources.dart';",
        "",
        "class GeneratedStickerCatalog {",
        "  const GeneratedStickerCatalog._();",
        "",
        "  static const fluentEmojiStickerAssets = <EditorStickerAsset>[",
    ]
    for sticker_id, asset_path, label in entries:
        lines.extend(
            [
                "    EditorStickerAsset(",
                f"      id: '{sticker_id}',",
                f"      assetPath: '{asset_path}',",
                f"      label: '{label}',",
                "    ),",
            ]
        )
    lines.extend(["  ];", "}", ""])
    CATALOG_PATH.write_text("\n".join(lines))


def write_notices() -> None:
    license_text = fetch_text(LICENSE_URL)
    LICENSE_PATH.write_text(license_text)
    NOTICE_PATH.write_text(
        "\n".join(
            [
                "# Fluent Emoji stickers",
                "",
                "These bundled editor stickers are generated from Microsoft Fluent Emoji.",
                "",
                "- Source: https://github.com/microsoft/fluentui-emoji",
                "- License: MIT",
                "- Imported style: Flat SVG artwork converted to 256px transparent PNG assets",
                "- Regenerate: `python3 scripts/import_fluent_stickers.py`",
                "",
                "The full upstream MIT license is included in FLUENT_EMOJI_LICENSE.txt.",
                "",
            ]
        )
    )


def main() -> int:
    if shutil.which("magick") is None:
        print("ImageMagick `magick` is required to convert SVGs to PNGs.", file=sys.stderr)
        return 1

    flat_assets = build_flat_asset_map()
    missing = [label for label in STICKER_LABELS if label not in flat_assets]
    if missing:
        print("Missing Fluent Emoji assets:", file=sys.stderr)
        for label in missing:
            print(f"  - {label}", file=sys.stderr)
        return 1

    STICKER_DIR.mkdir(parents=True, exist_ok=True)
    for previous in STICKER_DIR.glob("fluent_emoji_*.png"):
        previous.unlink()

    entries: list[tuple[str, str, str]] = []
    with tempfile.TemporaryDirectory() as tmp_dir_name:
        tmp_dir = Path(tmp_dir_name)
        for label in STICKER_LABELS:
            slug = slugify(label)
            sticker_id = f"fluent_emoji_{slug}"
            output_name = f"{sticker_id}.png"
            output_path = STICKER_DIR / output_name
            svg_path = tmp_dir / f"{sticker_id}.svg"
            source_path = flat_assets[label]
            url = RAW_BASE_URL + urllib.parse.quote(source_path, safe="/")

            download_file(url, svg_path)
            convert_svg_to_png(svg_path, output_path)
            entries.append(
                (
                    sticker_id,
                    f"assets/editor/stickers/{output_name}",
                    label,
                )
            )

    write_catalog(entries)
    write_notices()
    print(f"Imported {len(entries)} Fluent Emoji stickers.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
