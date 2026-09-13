#!/usr/bin/env bash
# Evaluate one explicit iOS mirror mode from freshly observed Git state.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
BASELINE_SPLIT_SHA="658d60253c58b7e0aedb576f16f40766fa677f23"
PUBLIC_REMOTE="${CROSSWAKE_IOS_MIRROR_PUBLIC_REMOTE:-https://github.com/szTheory/crosswake-shell-core-ios.git}"
WRITE_REMOTE="${CROSSWAKE_IOS_MIRROR_WRITE_REMOTE:-git@github.com:szTheory/crosswake-shell-core-ios.git}"
RELEASE_REPO="${CROSSWAKE_IOS_MIRROR_RELEASE_REPO:-$REPO_ROOT}"
MODE=""
VERSION=""
SOURCE_REF=""

usage() {
  echo "usage: ios_mirror.sh <baseline|candidate> --version <version> --ref <exact-ref>" >&2
  exit 2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    baseline|candidate) [ -z "$MODE" ] || usage; MODE="$1"; shift ;;
    --version) [ "$#" -ge 2 ] || usage; VERSION="$2"; shift 2 ;;
    --ref) [ "$#" -ge 2 ] || usage; SOURCE_REF="$2"; shift 2 ;;
    *) usage ;;
  esac
done

[ -n "$MODE" ] && [ -n "$VERSION" ] && [ -n "$SOURCE_REF" ] || usage

case "$MODE" in
  baseline)
    [ "$VERSION" = "0.2.0" ] || usage
    [ "$SOURCE_REF" = "refs/tags/ios-core-v0.2.0" ] || usage
    REMOTE="$PUBLIC_REMOTE"
    RECORDED_SPLIT_SHA="$BASELINE_SPLIT_SHA"
    ;;
  candidate)
    [ "$VERSION" = "0.2.1" ] || usage
    printf '%s' "$SOURCE_REF" | grep -Eq '^[0-9a-f]{40}$' || usage
    REMOTE="$PUBLIC_REMOTE"
    RECORDED_SPLIT_SHA=""
    ;;
esac

SPLIT_SHA="${CROSSWAKE_IOS_MIRROR_SPLIT_SHA:-}"
if [ -z "$SPLIT_SHA" ]; then
  SPLIT_SHA=$(git -C "$RELEASE_REPO" subtree split \
    --prefix=packages/crosswake-shell-core-ios "$SOURCE_REF" 2>/dev/null | tail -1)
fi
printf '%s' "$SPLIT_SHA" | grep -Eq '^[0-9a-f]{40}$' || SPLIT_SHA=""
[ -n "$RECORDED_SPLIT_SHA" ] || RECORDED_SPLIT_SHA="$SPLIT_SHA"

REMOTE_STATUS="PASS"
REMOTE_REFS=""
if ! REMOTE_REFS=$(git ls-remote "$REMOTE" refs/heads/main "refs/tags/v${VERSION}" 2>/dev/null); then
  REMOTE_STATUS="UNREACHABLE"
fi
REMOTE_MAIN=$(printf '%s\n' "$REMOTE_REFS" | awk '$2 == "refs/heads/main" {print $1}' | head -1)
REMOTE_TAG=$(printf '%s\n' "$REMOTE_REFS" | awk -v ref="refs/tags/v${VERSION}" '$2 == ref {print $1}' | head -1)

AUTHORIZATION_CHECKED=false
AUTHORIZATION_RESULT="NOT CHECKED"
ATOMIC_SUPPORTED=false
DRY_RUN_STATUS="NOT RUN"
BEFORE_MAIN="$REMOTE_MAIN"
BEFORE_TAG="$REMOTE_TAG"
AFTER_MAIN="$REMOTE_MAIN"
AFTER_TAG="$REMOTE_TAG"

if [ "$MODE" = "candidate" ]; then
  if [ -n "${SSH_AUTH_SOCK:-}" ] || [ "${CROSSWAKE_IOS_MIRROR_AUTHORIZATION_CHECKED:-}" = "true" ]; then
    REMOTE="$WRITE_REMOTE"
    REMOTE_REFS=""
    if ! REMOTE_REFS=$(git ls-remote "$REMOTE" refs/heads/main "refs/tags/v${VERSION}" 2>/dev/null); then
      REMOTE_STATUS="UNREACHABLE"
    fi
    REMOTE_MAIN=$(printf '%s\n' "$REMOTE_REFS" | awk '$2 == "refs/heads/main" {print $1}' | head -1)
    REMOTE_TAG=$(printf '%s\n' "$REMOTE_REFS" | awk -v ref="refs/tags/v${VERSION}" '$2 == ref {print $1}' | head -1)
    BEFORE_MAIN="$REMOTE_MAIN"
    BEFORE_TAG="$REMOTE_TAG"
    AUTHORIZATION_CHECKED=true
    PORCELAIN_FILE=$(mktemp "${TMPDIR:-/tmp}/crosswake-ios-mirror-porcelain.XXXXXX")
    cleanup() { rm -f -- "$PORCELAIN_FILE"; }
    trap cleanup EXIT

    if git -C "$RELEASE_REPO" push --dry-run --porcelain --atomic "$REMOTE" \
      "$SPLIT_SHA:refs/heads/main" "$SPLIT_SHA:refs/tags/v${VERSION}" \
      >"$PORCELAIN_FILE" 2>/dev/null &&
      grep -Eq '^(To |[ =*+!-][[:space:]])' "$PORCELAIN_FILE"; then
      AUTHORIZATION_RESULT="PROVEN"
      ATOMIC_SUPPORTED=true
      DRY_RUN_STATUS="PASS"
    else
      AUTHORIZATION_RESULT="DENIED"
      DRY_RUN_STATUS="REJECTED"
    fi

    AFTER_REFS=""
    if ! AFTER_REFS=$(git ls-remote "$REMOTE" refs/heads/main "refs/tags/v${VERSION}" 2>/dev/null); then
      REMOTE_STATUS="UNREACHABLE"
    fi
    AFTER_MAIN=$(printf '%s\n' "$AFTER_REFS" | awk '$2 == "refs/heads/main" {print $1}' | head -1)
    AFTER_TAG=$(printf '%s\n' "$AFTER_REFS" | awk -v ref="refs/tags/v${VERSION}" '$2 == ref {print $1}' | head -1)
  fi
fi

dash_if_empty() { if [ -n "$1" ]; then printf '%s' "$1"; else printf '%s' '-'; fi; }

RESULT=$(cd "$REPO_ROOT" && asdf exec mix run --no-start -e \
  'Crosswake.ReleaseCandidate.Mirror.evaluate_cli!(System.argv())' -- \
  "$MODE" "$VERSION" "$SOURCE_REF" "$(dash_if_empty "$SPLIT_SHA")" \
  "$(dash_if_empty "$RECORDED_SPLIT_SHA")" "$REMOTE_STATUS" \
  "$(dash_if_empty "$REMOTE_MAIN")" "$(dash_if_empty "$REMOTE_TAG")" \
  "$ATOMIC_SUPPORTED" "$AUTHORIZATION_CHECKED" "$AUTHORIZATION_RESULT" "$DRY_RUN_STATUS" \
  "$(dash_if_empty "$BEFORE_MAIN")" "$(dash_if_empty "$BEFORE_TAG")" \
  "$(dash_if_empty "$AFTER_MAIN")" "$(dash_if_empty "$AFTER_TAG")")

printf '%s\n' "$RESULT"
CORRECTION=$(printf '%s' "$RESULT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["correction"])')
STATE=$(printf '%s' "$RESULT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["state"])')
if [ "$CORRECTION" = "WRITE AUTHORITY NOT CHECKED" ]; then
  echo "WRITE AUTHORITY NOT CHECKED"
fi
[ "$STATE" = "PASS" ]
