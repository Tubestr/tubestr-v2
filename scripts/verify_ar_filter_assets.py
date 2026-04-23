#!/usr/bin/env python3
"""Verify staged AR filter PNGs keep transparent background pixels."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_ASSET_DIR = REPO_ROOT / "build" / "ar_filters" / "studio_assets"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Check that staged AR filter PNGs have transparent corners.",
    )
    parser.add_argument("--asset-dir", default=str(DEFAULT_ASSET_DIR))
    args = parser.parse_args()

    asset_dir = Path(args.asset_dir)
    if not asset_dir.is_absolute():
        asset_dir = REPO_ROOT / asset_dir
    if not asset_dir.exists():
        print(f"Missing AR asset directory: {asset_dir}", file=sys.stderr)
        return 66

    files = sorted(asset_dir.glob("*.png"))
    if not files:
        print(f"No PNG assets found in {asset_dir}", file=sys.stderr)
        return 66

    failures: list[str] = []
    for path in files:
        if not has_transparent_corners(path):
            failures.append(str(path.relative_to(REPO_ROOT)))

    if failures:
        print("Opaque AR asset backgrounds found:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        return 65

    print(f"Verified transparent AR backgrounds for {len(files)} PNG asset(s).")
    return 0


def has_transparent_corners(path: Path) -> bool:
    command = [
        "magick",
        str(path),
        "-format",
        "%[pixel:p{0,0}] %[pixel:p{511,0}] %[pixel:p{0,511}] %[pixel:p{511,511}]",
        "info:",
    ]
    output = subprocess.check_output(command, text=True).strip()
    pixels = output.split()
    return len(pixels) == 4 and all(pixel.endswith(",0)") for pixel in pixels)


if __name__ == "__main__":
    raise SystemExit(main())
