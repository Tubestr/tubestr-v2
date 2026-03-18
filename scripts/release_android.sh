#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PUBSPEC_PATH="$ROOT_DIR/pubspec.yaml"

PUSH_TAG=0
ALLOW_DIRTY=0
DRY_RUN=0
RELEASE_MODE="none"
SKIP_BUILD=0
NOTES_FILE=""
TITLE=""

usage() {
  cat <<'EOF'
Build signed Android artifacts locally, tag the current version, and optionally publish a GitHub release.

Usage:
  scripts/release_android.sh --push
  scripts/release_android.sh --draft
  scripts/release_android.sh --publish
  scripts/release_android.sh --publish --notes-file docs/release-notes/v1.0.1.md
  scripts/release_android.sh --publish --skip-build
  scripts/release_android.sh --dry-run

Options:
  --push             Push the derived tag to origin without creating a release.
  --draft            Build locally, push the tag, and create a draft GitHub release with assets.
  --publish          Build locally, push the tag, and create a published GitHub release with assets.
  --skip-build       Reuse existing release build outputs instead of rebuilding locally.
  --notes-file FILE  Use a specific release notes file instead of generated notes.
  --title TITLE      Override the GitHub release title.
  --allow-dirty      Skip the clean worktree check.
  --dry-run          Print the steps without changing git or GitHub state.
  --help, -h         Show this help text.
EOF
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

run_cmd() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] %q' "$1"
    shift
    for arg in "$@"; do
      printf ' %q' "$arg"
    done
    printf '\n'
    return
  fi

  "$@"
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --push)
      PUSH_TAG=1
      shift
      ;;
    --draft)
      RELEASE_MODE="draft"
      PUSH_TAG=1
      shift
      ;;
    --publish)
      RELEASE_MODE="publish"
      PUSH_TAG=1
      shift
      ;;
    --notes-file)
      NOTES_FILE="${2:-}"
      if [[ -z "$NOTES_FILE" ]]; then
        echo "--notes-file requires a path" >&2
        exit 1
      fi
      shift 2
      ;;
    --skip-build)
      SKIP_BUILD=1
      shift
      ;;
    --title)
      TITLE="${2:-}"
      if [[ -z "$TITLE" ]]; then
        echo "--title requires a value" >&2
        exit 1
      fi
      shift 2
      ;;
    --allow-dirty)
      ALLOW_DIRTY=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

require_command git
require_command awk

if [[ ! -f "$PUBSPEC_PATH" ]]; then
  echo "Missing pubspec.yaml at $PUBSPEC_PATH" >&2
  exit 1
fi

cd "$ROOT_DIR"

VERSION_STRING="$(awk '/^version:/{print $2; exit}' "$PUBSPEC_PATH")"

if [[ -z "$VERSION_STRING" ]]; then
  echo "Could not find a version in $PUBSPEC_PATH" >&2
  exit 1
fi

SEMVER="${VERSION_STRING%%+*}"
BUILD_NUMBER="${VERSION_STRING##*+}"
TAG_NAME="v$SEMVER"
HEAD_COMMIT="$(git rev-parse HEAD)"
APK_PATH="$ROOT_DIR/build/app/outputs/flutter-apk/app-release.apk"
AAB_PATH="$ROOT_DIR/build/app/outputs/bundle/release/app-release.aab"
NAMED_APK_PATH="$ROOT_DIR/build/app/outputs/flutter-apk/tubestr-${TAG_NAME}-android.apk"
NAMED_AAB_PATH="$ROOT_DIR/build/app/outputs/bundle/release/tubestr-${TAG_NAME}-android.aab"

if [[ "$ALLOW_DIRTY" != "1" ]] && [[ -n "$(git status --short)" ]]; then
  echo "Worktree is not clean. Commit or stash changes first, or re-run with --allow-dirty." >&2
  exit 1
fi

if [[ "$RELEASE_MODE" != "none" && "$DRY_RUN" != "1" ]]; then
  require_command flutter
  require_command gh

  if [[ ! -f "$ROOT_DIR/android/key.properties" ]]; then
    echo "Missing android/key.properties. Configure local release signing before building a release." >&2
    exit 1
  fi
fi

if git rev-parse --verify "refs/tags/$TAG_NAME" >/dev/null 2>&1; then
  TAG_COMMIT="$(git rev-list -n 1 "$TAG_NAME")"
  if [[ "$TAG_COMMIT" != "$HEAD_COMMIT" ]]; then
    echo "Local tag $TAG_NAME already exists on a different commit." >&2
    exit 1
  fi
else
  run_cmd git tag -a "$TAG_NAME" -m "Android release $TAG_NAME"
fi

if git remote get-url origin >/dev/null 2>&1; then
  if git ls-remote --exit-code --tags origin "refs/tags/$TAG_NAME" >/dev/null 2>&1; then
    REMOTE_TAG_EXISTS=1
  else
    REMOTE_TAG_EXISTS=0
  fi
else
  REMOTE_TAG_EXISTS=0
fi

if [[ "$PUSH_TAG" == "1" && "$REMOTE_TAG_EXISTS" == "0" && "$RELEASE_MODE" == "none" ]]; then
  run_cmd git push origin "$TAG_NAME"
fi

if [[ "$RELEASE_MODE" != "none" ]]; then
  if [[ "$SKIP_BUILD" != "1" ]]; then
    run_cmd flutter pub get
    run_cmd flutter build apk --release
    run_cmd flutter build appbundle --release
  fi

  if [[ "$DRY_RUN" != "1" ]]; then
    if [[ ! -f "$APK_PATH" ]]; then
      echo "Missing APK build output: $APK_PATH" >&2
      exit 1
    fi
    if [[ ! -f "$AAB_PATH" ]]; then
      echo "Missing app bundle build output: $AAB_PATH" >&2
      exit 1
    fi
  fi

  run_cmd cp "$APK_PATH" "$NAMED_APK_PATH"
  run_cmd cp "$AAB_PATH" "$NAMED_AAB_PATH"

  if [[ "$PUSH_TAG" == "1" && "$REMOTE_TAG_EXISTS" == "0" ]]; then
    run_cmd git push origin "$TAG_NAME"
  fi

  if [[ -n "$NOTES_FILE" && ! -f "$NOTES_FILE" ]]; then
    echo "Release notes file not found: $NOTES_FILE" >&2
    exit 1
  fi

  if [[ -z "$TITLE" ]]; then
    TITLE="TubeStr Android $TAG_NAME (build $BUILD_NUMBER)"
  fi

  RELEASE_EXISTS=0
  if [[ "$DRY_RUN" != "1" ]] && gh release view "$TAG_NAME" >/dev/null 2>&1; then
    RELEASE_EXISTS=1
  fi

  if [[ "$RELEASE_EXISTS" == "1" ]]; then
    EDIT_ARGS=(release edit "$TAG_NAME" --title "$TITLE")
    if [[ "$RELEASE_MODE" == "draft" ]]; then
      EDIT_ARGS+=(--draft)
    else
      EDIT_ARGS+=(--draft=false)
    fi
    if [[ -n "$NOTES_FILE" ]]; then
      EDIT_ARGS+=(--notes-file "$NOTES_FILE")
    fi

    run_cmd gh "${EDIT_ARGS[@]}"
    run_cmd gh release upload "$TAG_NAME" "$NAMED_APK_PATH" "$NAMED_AAB_PATH" --clobber
  else
    GH_ARGS=(release create "$TAG_NAME" --title "$TITLE")
    if [[ "$RELEASE_MODE" == "draft" ]]; then
      GH_ARGS+=(--draft)
    fi
    if [[ -n "$NOTES_FILE" ]]; then
      GH_ARGS+=(--notes-file "$NOTES_FILE")
    else
      GH_ARGS+=(--generate-notes)
    fi
    GH_ARGS+=("$NAMED_APK_PATH" "$NAMED_AAB_PATH")

    run_cmd gh "${GH_ARGS[@]}"
  fi
fi

printf 'Version: %s\n' "$VERSION_STRING"
printf 'Tag: %s\n' "$TAG_NAME"
printf 'Commit: %s\n' "$HEAD_COMMIT"

if [[ "$RELEASE_MODE" == "none" ]]; then
  if [[ "$PUSH_TAG" == "1" ]]; then
    printf 'Tag pushed. Next: create a GitHub release for %s and upload your Android artifacts.\n' "$TAG_NAME"
  else
    printf 'Local tag is ready. Next: git push origin %s\n' "$TAG_NAME"
    printf 'Then create a GitHub release for %s.\n' "$TAG_NAME"
  fi
else
  printf 'GitHub release created for %s with local build artifacts:\n' "$TAG_NAME"
  printf '  %s\n' "$NAMED_APK_PATH"
  printf '  %s\n' "$NAMED_AAB_PATH"
fi
