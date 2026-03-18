#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEYSTORE_PATH="${1:-$ROOT_DIR/android/upload-keystore.jks}"
KEY_ALIAS="${2:-tubestr}"

usage() {
  cat <<'EOF'
Create the Android upload keystore used for signed release builds.

Usage:
  scripts/create_android_keystore.sh
  scripts/create_android_keystore.sh android/upload-keystore.jks tubestr

Notes:
  - keytool will prompt for the keystore password and certificate details.
  - Keep the generated keystore backed up somewhere safe.
EOF
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

require_command keytool

if [[ -e "$KEYSTORE_PATH" ]]; then
  echo "Refusing to overwrite existing keystore: $KEYSTORE_PATH" >&2
  exit 1
fi

mkdir -p "$(dirname "$KEYSTORE_PATH")"

keytool -genkeypair -v \
  -keystore "$KEYSTORE_PATH" \
  -alias "$KEY_ALIAS" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000

printf '\nKeystore created at %s\n' "$KEYSTORE_PATH"
printf 'Alias: %s\n' "$KEY_ALIAS"
printf '\nNext steps:\n'
printf '  1. Back up this keystore somewhere safe.\n'
printf '  2. For local signed builds, create android/key.properties with:\n'
printf '     storePassword=...\n'
printf '     keyPassword=...\n'
printf '     keyAlias=%s\n' "$KEY_ALIAS"
printf '     storeFile=%s\n' "$(basename "$KEYSTORE_PATH")"
printf '  3. Publish a signed Android release with:\n'
printf '     scripts/release_android.sh --publish\n'
