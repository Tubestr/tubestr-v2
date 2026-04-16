#!/usr/bin/env python3
"""Import a curated set of libre editor music tracks.

The editor bundles short music overlays as Flutter assets. This script downloads
curated CC0 source files, normalizes them to compact MP3 assets, regenerates the
Dart catalog, and writes attribution/notice files beside the music.
"""

from __future__ import annotations

import json
import html
import os
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.parse
import urllib.request
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
MUSIC_DIR = REPO_ROOT / "assets" / "editor" / "music"
BUILD_MUSIC_DIR = REPO_ROOT / "build" / "editor_music"
BUILD_TRACK_DIR = BUILD_MUSIC_DIR / "tracks"
CATALOG_PATH = REPO_ROOT / "lib" / "services" / "editor" / "generated_music_catalog.dart"
NOTICE_PATH = MUSIC_DIR / "EDITOR_MUSIC_NOTICE.md"
ATTRIBUTIONS_PATH = MUSIC_DIR / "EDITOR_MUSIC_ATTRIBUTIONS.json"
PUBLISH_MANIFEST_PATH = BUILD_MUSIC_DIR / "publish_manifest.json"
CC0_LICENSE_URL = "https://creativecommons.org/publicdomain/zero/1.0/"
DEFAULT_BLOSSOM_SERVER = "https://blossom.tubestr.app"
TARGET_TRACK_COUNT = int(os.environ.get("EDITOR_AUDIO_IMPORT_LIMIT", "100"))
MAX_SOURCE_BYTES = 25 * 1024 * 1024
DEFAULT_MAX_DURATION_SECONDS = 45
AUDIO_EXTENSION_PRIORITY = (".ogg", ".mp3", ".wav", ".flac")
DISCOVERY_COLLECTION_URLS = [
    "https://opengameart.org/content/cc0-music-0",
]

TRACKS = [
    {
        "id": "foss_flowerbed_fields",
        "label": "Flowerbed Fields",
        "creator": "Zane Little Music",
        "source_url": "https://opengameart.org/content/flowerbed-fields-loop",
        "download_url": "https://opengameart.org/sites/default/files/flowerbed_fields.ogg",
        "license": "CC0",
        "license_url": CC0_LICENSE_URL,
        "categories": ["happy", "chiptune", "game", "loops"],
        "attribution": "Flowerbed Fields by Zane Little Music, CC0 via OpenGameArt.",
        "max_duration_seconds": DEFAULT_MAX_DURATION_SECONDS,
    },
    {
        "id": "foss_invincibility",
        "label": "Invincibility",
        "creator": "Zane Little Music",
        "source_url": "https://opengameart.org/content/invincibility-loop",
        "download_url": "https://opengameart.org/sites/default/files/invincible.ogg",
        "license": "CC0",
        "license_url": CC0_LICENSE_URL,
        "categories": ["energy", "chiptune", "game", "loops"],
        "attribution": "Invincibility by Zane Little Music, CC0 via OpenGameArt.",
        "max_duration_seconds": DEFAULT_MAX_DURATION_SECONDS,
    },
    {
        "id": "foss_icy_heights",
        "label": "Icy Heights",
        "creator": "Ecrivain",
        "source_url": "https://opengameart.org/content/icy-heights",
        "download_url": "https://opengameart.org/sites/default/files/theme-loop.ogg",
        "license": "CC0",
        "license_url": CC0_LICENSE_URL,
        "categories": ["chill", "game", "loops"],
        "attribution": "Icy Heights by Ecrivain, CC0 via OpenGameArt.",
        "max_duration_seconds": DEFAULT_MAX_DURATION_SECONDS,
    },
    {
        "id": "foss_background_loop",
        "label": "Background Loop",
        "creator": "Pro Sensory",
        "source_url": "https://opengameart.org/content/background-music-loop",
        "download_url": "https://opengameart.org/sites/default/files/background_music_loop.mp3",
        "license": "CC0",
        "license_url": CC0_LICENSE_URL,
        "categories": ["energy", "game", "loops"],
        "attribution": "Background Music Loop by Pro Sensory, CC0 via OpenGameArt.",
        "max_duration_seconds": DEFAULT_MAX_DURATION_SECONDS,
    },
    {
        "id": "foss_fast_background",
        "label": "Fast Background",
        "creator": "yd",
        "source_url": "https://opengameart.org/content/music-loops",
        "download_url": "https://opengameart.org/sites/default/files/fast_background.mp3",
        "license": "CC0",
        "license_url": CC0_LICENSE_URL,
        "categories": ["energy", "game", "loops"],
        "attribution": "Fast Background Music by yd, CC0 via OpenGameArt.",
        "max_duration_seconds": DEFAULT_MAX_DURATION_SECONDS,
    },
    {
        "id": "foss_chiptune_battle",
        "label": "Chiptune Battle",
        "creator": "subspaceaudio",
        "source_url": "https://opengameart.org/content/5-chiptunes-action",
        "download_url": "https://opengameart.org/sites/default/files/battle_music_01-loop.ogg",
        "license": "CC0",
        "license_url": CC0_LICENSE_URL,
        "categories": ["energy", "chiptune", "game", "dramatic", "loops"],
        "attribution": "Chiptune Battle by subspaceaudio, CC0 via OpenGameArt.",
        "max_duration_seconds": DEFAULT_MAX_DURATION_SECONDS,
    },
    {
        "id": "foss_happy_synths",
        "label": "Happy Synths",
        "creator": "3xBlast",
        "source_url": "https://opengameart.org/content/happy-synths-loop-with-slight-christmas-feeling",
        "download_url": "https://opengameart.org/sites/default/files/Christmas%20synths.ogg",
        "license": "CC0",
        "license_url": CC0_LICENSE_URL,
        "categories": ["happy", "chill", "loops"],
        "attribution": "Happy Synths by 3xBlast, CC0 via OpenGameArt.",
        "max_duration_seconds": DEFAULT_MAX_DURATION_SECONDS,
    },
    {
        "id": "foss_loop_town",
        "label": "Loop Town",
        "creator": "Fupi",
        "source_url": "https://opengameart.org/content/loop-town",
        "download_url": "https://opengameart.org/sites/default/files/loopcity_0.ogg",
        "license": "CC0",
        "license_url": CC0_LICENSE_URL,
        "categories": ["happy", "chill", "loops"],
        "attribution": "Loop Town by Fupi, CC0 via OpenGameArt.",
        "max_duration_seconds": DEFAULT_MAX_DURATION_SECONDS,
    },
    {
        "id": "foss_title_theme",
        "label": "Title Theme",
        "creator": "yd",
        "source_url": "https://opengameart.org/content/title-theme",
        "download_url": "https://opengameart.org/sites/default/files/Title%20Theme.mp3",
        "license": "CC0",
        "license_url": CC0_LICENSE_URL,
        "categories": ["happy", "game", "loops"],
        "attribution": "Title Theme by yd, CC0 via OpenGameArt.",
        "max_duration_seconds": DEFAULT_MAX_DURATION_SECONDS,
    },
    {
        "id": "foss_bards_tale",
        "label": "Bard's Tale",
        "creator": "RandomMind",
        "source_url": "https://opengameart.org/content/chiptune-medieval-the-bards-tale",
        "download_url": "https://opengameart.org/sites/default/files/CHIPTUNE_The_Bards_Tale.mp3",
        "license": "CC0",
        "license_url": CC0_LICENSE_URL,
        "categories": ["chill", "chiptune", "game", "loops"],
        "attribution": "CHIPTUNE - The Bard's Tale by RandomMind, CC0 via OpenGameArt.",
        "max_duration_seconds": DEFAULT_MAX_DURATION_SECONDS,
    },
]


def dart_string(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'"


def fetch_text(url: str) -> str:
    request = urllib.request.Request(url, headers={"User-Agent": "Tubestr editor music importer"})
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read().decode("utf-8", errors="replace")


def slugify(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", value.lower()).strip("_")


def download_file(url: str, destination: Path) -> None:
    request = urllib.request.Request(url, headers={"User-Agent": "Tubestr editor music importer"})
    with urllib.request.urlopen(request, timeout=60) as response:
        destination.write_bytes(response.read())


def content_length(url: str) -> int | None:
    request = urllib.request.Request(
        url,
        method="HEAD",
        headers={"User-Agent": "Tubestr editor music importer"},
    )
    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            header = response.headers.get("Content-Length")
            return int(header) if header else None
    except Exception:
        return None


def convert_to_mp3(source_path: Path, output_path: Path, max_seconds: int) -> None:
    subprocess.run(
        [
            "ffmpeg",
            "-y",
            "-i",
            str(source_path),
            "-t",
            str(max_seconds),
            "-vn",
            "-ac",
            "2",
            "-ar",
            "44100",
            "-b:a",
            "96k",
            "-af",
            "loudnorm=I=-16:TP=-1.5:LRA=11",
            str(output_path),
        ],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def discover_collection_pages(base_url: str, max_pages: int = 5) -> list[str]:
    urls = [base_url]
    for page in range(1, max_pages):
        urls.append(f"{base_url}?page={page}")
    return urls


def extract_content_urls(collection_html: str) -> list[str]:
    matches = re.findall(r'href="(/content/[^"#?]+)"', collection_html)
    urls = []
    seen = set()
    for match in matches:
        if match == "/content/faq":
            continue
        url = urllib.parse.urljoin("https://opengameart.org", match)
        if url in seen:
            continue
        seen.add(url)
        urls.append(url)
    return urls


def meta_value(page_html: str, name: str) -> str | None:
    match = re.search(
        rf'<meta name="{re.escape(name)}" content="([^"]*)"',
        page_html,
    )
    if not match:
        return None
    return html.unescape(match.group(1)).strip()


def extract_tags(page_html: str) -> list[str]:
    tags = re.findall(r'field_art_tags_tid=[^>]*>([^<]+)</a>', page_html)
    return [html.unescape(tag).strip().lower() for tag in tags if tag.strip()]


def extract_audio_file_urls(page_html: str) -> list[str]:
    matches = re.findall(
        r'href="(https://opengameart\.org/sites/default/files/[^"]+)"',
        page_html,
    )
    urls = []
    seen = set()
    for raw_url in matches:
        url = html.unescape(raw_url)
        parsed_path = urllib.parse.unquote(urllib.parse.urlparse(url).path).lower()
        if "audio_preview" in parsed_path or "/styles/" in parsed_path:
            continue
        if not parsed_path.endswith(AUDIO_EXTENSION_PRIORITY):
            continue
        if url in seen:
            continue
        seen.add(url)
        urls.append(url)

    def priority(url: str) -> tuple[int, int]:
        path = urllib.parse.unquote(urllib.parse.urlparse(url).path).lower()
        extension_index = next(
            (
                index
                for index, extension in enumerate(AUDIO_EXTENSION_PRIORITY)
                if path.endswith(extension)
            ),
            len(AUDIO_EXTENSION_PRIORITY),
        )
        loop_score = 0 if "loop" in path else 1
        return (loop_score, extension_index)

    return sorted(urls, key=priority)


def categories_for(title: str, tags: list[str], file_url: str) -> list[str]:
    haystack = " ".join([title, file_url, *tags]).lower()
    categories = []
    if any(term in haystack for term in ("happy", "cheer", "cute", "fun", "tropic", "adventure")):
        categories.append("happy")
    if any(term in haystack for term in ("action", "battle", "boss", "fight", "fast", "shooter", "rock", "run")):
        categories.append("energy")
    if any(term in haystack for term in ("ambient", "relax", "calm", "sad", "piano", "space", "forest", "rain", "snow", "dream")):
        categories.append("chill")
    if any(term in haystack for term in ("8-bit", "8bit", "chiptune", "chip", "nes", "retro")):
        categories.append("chiptune")
    if any(term in haystack for term in ("dark", "creepy", "epic", "dungeon", "menace", "tragic", "horror")):
        categories.append("dramatic")
    categories.append("game")
    if "loop" in haystack:
        categories.append("loops")
    return list(dict.fromkeys(categories))


def discovered_track_from_page(
    source_url: str,
    used_ids: set[str],
    used_download_urls: set[str],
) -> dict[str, object] | None:
    try:
        page_html = fetch_text(source_url)
    except Exception as error:
        print(f"Skipping {source_url}: {error}", file=sys.stderr)
        return None
    if CC0_LICENSE_URL not in page_html and "license-name'>CC0" not in page_html:
        return None

    title = meta_value(page_html, "dcterms.title")
    creator = meta_value(page_html, "dcterms.creator")
    if not title or not creator:
        return None

    for file_url in extract_audio_file_urls(page_html):
        if file_url in used_download_urls:
            continue
        base_id = f"foss_{slugify(title)}"
        track_id = base_id
        suffix = 2
        while track_id in used_ids:
            track_id = f"{base_id}_{suffix}"
            suffix += 1
        tags = extract_tags(page_html)
        label = title[:36].strip()
        attribution = f"{title} by {creator}, CC0 via OpenGameArt."
        return {
            "id": track_id,
            "label": label,
            "creator": creator,
            "source_url": source_url,
            "download_url": file_url,
            "license": "CC0",
            "license_url": CC0_LICENSE_URL,
            "categories": categories_for(title, tags, file_url),
            "attribution": attribution,
            "max_duration_seconds": DEFAULT_MAX_DURATION_SECONDS,
        }
    return None


def build_track_manifest() -> list[dict[str, object]]:
    tracks: list[dict[str, object]] = [dict(track) for track in TRACKS]
    if len(tracks) >= TARGET_TRACK_COUNT:
        return tracks[:TARGET_TRACK_COUNT]
    used_ids = {str(track["id"]) for track in tracks}
    used_download_urls = {str(track["download_url"]) for track in tracks}
    source_urls = []
    seen_source_urls = {str(track["source_url"]) for track in tracks}

    for collection_url in DISCOVERY_COLLECTION_URLS:
        for page_url in discover_collection_pages(collection_url):
            print(f"Scanning {page_url}", flush=True)
            try:
                page_html = fetch_text(page_url)
            except Exception as error:
                print(f"Skipping collection page {page_url}: {error}", file=sys.stderr)
                continue
            for source_url in extract_content_urls(page_html):
                if source_url in seen_source_urls:
                    continue
                seen_source_urls.add(source_url)
                source_urls.append(source_url)

    for source_url in source_urls:
        if len(tracks) >= TARGET_TRACK_COUNT:
            break
        track = discovered_track_from_page(
            source_url,
            used_ids=used_ids,
            used_download_urls=used_download_urls,
        )
        if track is None:
            continue
        tracks.append(track)
        print(
            f"Discovered {len(tracks)}/{TARGET_TRACK_COUNT}: {track['label']}",
            flush=True,
        )
        used_ids.add(str(track["id"]))
        used_download_urls.add(str(track["download_url"]))

    if len(tracks) < TARGET_TRACK_COUNT:
        print(
            f"Only found {len(tracks)} CC0 music tracks; target is {TARGET_TRACK_COUNT}.",
            file=sys.stderr,
        )
    return tracks[:TARGET_TRACK_COUNT]


def sha256_hex(path: Path) -> str:
    import hashlib

    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_catalog(tracks: list[dict[str, object]]) -> None:
    lines = [
        "// Generated by scripts/import_editor_music.py. Do not edit by hand.",
        "",
        "import '../../domain/models/editor_resources.dart';",
        "",
        "class GeneratedMusicCatalog {",
        "  const GeneratedMusicCatalog._();",
        "",
        "  static const communityMusicTracks = <EditorMusicTrackAsset>[",
    ]
    for track in tracks:
        categories = ", ".join(dart_string(category) for category in track["categories"])
        servers = ", ".join(
            dart_string(server)
            for server in track.get("blossom_servers", [DEFAULT_BLOSSOM_SERVER])
        )
        lines.extend(
            [
                "    EditorMusicTrackAsset(",
                f"      id: {dart_string(track['id'])},",
                f"      label: {dart_string(track['label'])},",
                f"      creator: {dart_string(track['creator'])},",
                f"      license: {dart_string(track['license'])},",
                f"      licenseUrl: {dart_string(track['license_url'])},",
                f"      sourceUrl: {dart_string(track['source_url'])},",
                f"      categories: <String>[{categories}],",
                f"      attribution: {dart_string(track['attribution'])},",
                f"      blossomHash: {dart_string(track['blossom_hash'])},",
                f"      byteLength: {track['byte_length']},",
                "      mimeType: 'audio/mpeg',",
                f"      blossomServers: <String>[{servers}],",
                "    ),",
            ]
        )
    lines.extend(["  ];", "}", ""])
    CATALOG_PATH.write_text("\n".join(lines))


def write_notices(tracks: list[dict[str, object]]) -> None:
    public_tracks = [
        {key: value for key, value in track.items() if key != "staged_path"}
        for track in tracks
    ]
    ATTRIBUTIONS_PATH.write_text(
        json.dumps(public_tracks, indent=2, ensure_ascii=False) + "\n"
    )
    PUBLISH_MANIFEST_PATH.write_text(
        json.dumps(tracks, indent=2, ensure_ascii=False) + "\n"
    )
    NOTICE_PATH.write_text(
        "\n".join(
            [
                "# Editor music",
                "",
                "These bundled editor music overlays are curated from OpenGameArt.",
                "",
                "- License policy: bundled community imports must be CC0 unless reviewed otherwise.",
                "- Imported format: source audio normalized to 44.1 kHz stereo 96 kbps MP3 blobs.",
                "- Regenerate: `python3 scripts/import_editor_music.py`",
                "- Publish staged blobs: `EDITOR_AUDIO_PUBLISH_NSEC=nsec1... dart run scripts/publish_editor_music_to_blossom.dart`",
                "",
                "Per-track source URLs, creators, licenses, and attribution notes are stored in EDITOR_MUSIC_ATTRIBUTIONS.json.",
                "",
            ]
        )
    )


def main() -> int:
    if shutil.which("ffmpeg") is None:
        print("ffmpeg is required to normalize editor music assets.", file=sys.stderr)
        return 1

    MUSIC_DIR.mkdir(parents=True, exist_ok=True)
    BUILD_TRACK_DIR.mkdir(parents=True, exist_ok=True)
    for previous in BUILD_TRACK_DIR.glob("*.mp3"):
        previous.unlink()

    tracks = build_track_manifest()
    with tempfile.TemporaryDirectory() as tmp_dir_name:
        tmp_dir = Path(tmp_dir_name)
        for index, track in enumerate(tracks, start=1):
            source_name = slugify(track["id"])
            source_path = tmp_dir / source_name
            output_path = BUILD_TRACK_DIR / f"{track['id']}.mp3"
            print(f"[{index}/{len(tracks)}] {track['label']}")
            download_file(track["download_url"], source_path)
            convert_to_mp3(
                source_path,
                output_path,
                int(track.get("max_duration_seconds", 60)),
            )
            track["staged_path"] = str(output_path.relative_to(REPO_ROOT))
            track["blossom_hash"] = sha256_hex(output_path)
            track["byte_length"] = output_path.stat().st_size
            track["mime_type"] = "audio/mpeg"
            track["blossom_servers"] = [DEFAULT_BLOSSOM_SERVER]

    write_catalog(tracks)
    write_notices(tracks)
    print(f"Imported {len(tracks)} editor music tracks.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
