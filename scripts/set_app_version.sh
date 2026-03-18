#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PUBSPEC_PATH="$ROOT_DIR/pubspec.yaml"

usage() {
  cat <<'EOF'
Update the Flutter app version in pubspec.yaml.

Usage:
  scripts/set_app_version.sh <version+build>
  scripts/set_app_version.sh <semver> <build>

Examples:
  scripts/set_app_version.sh 1.0.1+18
  scripts/set_app_version.sh 1.0.1 18
EOF
}

require_file() {
  if [[ ! -f "$1" ]]; then
    echo "Missing required file: $1" >&2
    exit 1
  fi
}

parse_target_version() {
  local semver_regex='^[0-9]+\.[0-9]+\.[0-9]+$'
  local full_regex='^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$'

  if [[ "$#" -eq 1 ]]; then
    if [[ "$1" =~ $full_regex ]]; then
      printf '%s\n' "$1"
      return
    fi
  elif [[ "$#" -eq 2 ]]; then
    if [[ "$1" =~ $semver_regex && "$2" =~ ^[0-9]+$ ]]; then
      printf '%s+%s\n' "$1" "$2"
      return
    fi
  fi

  usage >&2
  exit 1
}

require_file "$PUBSPEC_PATH"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

TARGET_VERSION="$(parse_target_version "$@")"
CURRENT_VERSION="$(awk '/^version:/{print $2; exit}' "$PUBSPEC_PATH")"

if [[ -z "$CURRENT_VERSION" ]]; then
  echo "Could not find a version line in $PUBSPEC_PATH" >&2
  exit 1
fi

if [[ "$CURRENT_VERSION" == "$TARGET_VERSION" ]]; then
  printf 'pubspec.yaml is already set to %s\n' "$TARGET_VERSION"
  exit 0
fi

perl -0pi -e "s/^version:\\s*.*/version: $TARGET_VERSION/m" "$PUBSPEC_PATH"

TAG_NAME="v${TARGET_VERSION%%+*}"

printf 'Updated pubspec.yaml: %s -> %s\n' "$CURRENT_VERSION" "$TARGET_VERSION"
printf 'Suggested next steps:\n'
printf '  git add pubspec.yaml\n'
printf '  git commit -m "Bump version to %s"\n' "$TARGET_VERSION"
printf '  scripts/release_android.sh --publish\n'
printf 'Derived tag: %s\n' "$TAG_NAME"
