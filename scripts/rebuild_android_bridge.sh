#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_ID="app.tubestr.mytube"
DEFAULT_NDK_HOME="/opt/android-sdk/ndk/28.2.13676358"
DEVICE_ID="${1:-${ANDROID_DEVICE_ID:-}}"
FRB_CODEGEN_BIN="${FRB_CODEGEN_BIN:-$HOME/.cargo/bin/flutter_rust_bridge_codegen}"
ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-${NDK_HOME:-$DEFAULT_NDK_HOME}}"
APK_PATH="$ROOT_DIR/build/app/outputs/flutter-apk/app-debug.apk"

usage() {
  cat <<'EOF'
Rebuild the Flutter Rust bridge, Android Rust libraries, and debug APK, then reinstall on a USB device.

Usage:
  scripts/rebuild_android_bridge.sh [device_id]

Options:
  device_id              Optional adb device serial. If omitted, the script uses
                         ANDROID_DEVICE_ID or auto-selects the single connected
                         Android device.

Environment:
  ANDROID_DEVICE_ID      Default adb device serial when no positional arg is given
  ANDROID_NDK_HOME       Android NDK path
  NDK_HOME               Fallback Android NDK path
  FRB_CODEGEN_BIN        flutter_rust_bridge_codegen binary path
  SKIP_FLUTTER_CLEAN=1   Skip "flutter clean"
  SKIP_UNINSTALL=1       Skip adb uninstall before reinstall
EOF
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

log_step() {
  printf '\n==> %s\n' "$1"
}

resolve_device_id() {
  if [[ -n "$DEVICE_ID" ]]; then
    return
  fi

  mapfile -t devices < <(adb devices | awk 'NR > 1 && $2 == "device" { print $1 }')

  if [[ "${#devices[@]}" -eq 1 ]]; then
    DEVICE_ID="${devices[0]}"
    return
  fi

  if [[ "${#devices[@]}" -eq 0 ]]; then
    echo "No connected Android devices found via adb." >&2
  else
    echo "Multiple Android devices found. Pass a device id explicitly." >&2
    printf 'Detected devices:\n' >&2
    printf '  %s\n' "${devices[@]}" >&2
  fi

  exit 1
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

export PATH="$HOME/.cargo/bin:$PATH"

require_command flutter
require_command cargo
require_command adb
require_command bash
require_command "$FRB_CODEGEN_BIN"

if [[ ! -d "$ANDROID_NDK_HOME" ]]; then
  echo "Android NDK not found at: $ANDROID_NDK_HOME" >&2
  exit 1
fi

export ANDROID_NDK_HOME
export NDK_HOME="$ANDROID_NDK_HOME"

resolve_device_id

log_step "Using Android device $DEVICE_ID"

cd "$ROOT_DIR"

log_step "Generating flutter_rust_bridge bindings"
"$FRB_CODEGEN_BIN" generate --config-file flutter_rust_bridge.yaml

log_step "Checking Rust bridge crate"
cargo check --manifest-path native/mdk_bridge/Cargo.toml

log_step "Building Android Rust libraries"
(
  cd native/mdk_bridge
  cargo ndk \
    -t arm64-v8a \
    -t armeabi-v7a \
    -t x86_64 \
    -o ../../android/app/src/main/jniLibs \
    build --release
)

if [[ "${SKIP_FLUTTER_CLEAN:-0}" != "1" ]]; then
  log_step "Cleaning Flutter build artifacts"
  flutter clean
fi

log_step "Fetching Flutter packages"
  flutter pub get

if [[ "${SKIP_UNINSTALL:-0}" != "1" ]]; then
  log_step "Removing existing app from device"
  adb -s "$DEVICE_ID" uninstall "$APP_ID" >/dev/null 2>&1 || true
fi

log_step "Building debug APK"
flutter build apk --debug

if [[ ! -f "$APK_PATH" ]]; then
  echo "APK not found at: $APK_PATH" >&2
  exit 1
fi

log_step "Installing APK on device"
adb -s "$DEVICE_ID" install -r "$APK_PATH"

log_step "Launching app"
adb -s "$DEVICE_ID" shell am start -n "$APP_ID/.MainActivity"

printf '\nDone. Flutter and Rust bridge artifacts are back in sync on %s.\n' "$DEVICE_ID"
