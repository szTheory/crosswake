#!/usr/bin/env bash
# Evaluate one explicit iOS mirror mode from freshly observed Git state.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
if command -v asdf >/dev/null 2>&1; then
  RUNTIME=(asdf exec)
else
  RUNTIME=()
fi
BASELINE_SPLIT_SHA="658d60253c58b7e0aedb576f16f40766fa677f23"
PUBLIC_REMOTE="${CROSSWAKE_IOS_MIRROR_PUBLIC_REMOTE:-https://github.com/szTheory/crosswake-shell-core-ios.git}"
WRITE_REMOTE="${CROSSWAKE_IOS_MIRROR_WRITE_REMOTE:-git@github.com:szTheory/crosswake-shell-core-ios.git}"
RELEASE_REPO="${CROSSWAKE_IOS_MIRROR_RELEASE_REPO:-$REPO_ROOT}"
MODE=""
VERSION=""
SOURCE_REF=""
APPROVAL_RECEIPT=""
EXPECTED_OLD_REF=""
EXPECTED_NEW_REF=""

usage() {
  echo "usage: ios_mirror.sh <baseline|candidate|publish|recovery> --version <version> --ref <exact-ref> [approval bindings]" >&2
  exit 2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    baseline|candidate|publish|recovery) [ -z "$MODE" ] || usage; MODE="$1"; shift ;;
    --version) [ "$#" -ge 2 ] || usage; VERSION="$2"; shift 2 ;;
    --ref) [ "$#" -ge 2 ] || usage; SOURCE_REF="$2"; shift 2 ;;
    --approval-receipt) [ "$#" -ge 2 ] || usage; APPROVAL_RECEIPT="$2"; shift 2 ;;
    --expected-old-ref) [ "$#" -ge 2 ] || usage; EXPECTED_OLD_REF="$2"; shift 2 ;;
    --expected-new-ref) [ "$#" -ge 2 ] || usage; EXPECTED_NEW_REF="$2"; shift 2 ;;
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
  candidate|publish|recovery)
    [ "$VERSION" = "0.2.1" ] || usage
    printf '%s' "$SOURCE_REF" | grep -Eq '^[0-9a-f]{40}$' || usage
    REMOTE="$PUBLIC_REMOTE"
    RECORDED_SPLIT_SHA=""
    ;;
esac

if [ "$MODE" = "publish" ] || [ "$MODE" = "recovery" ]; then
  printf '%s' "$APPROVAL_RECEIPT" | grep -Eq '^[0-9a-f]{64}$' || usage
  printf '%s' "$EXPECTED_OLD_REF" | grep -Eq '^[0-9a-f]{40}$' || usage
  printf '%s' "$EXPECTED_NEW_REF" | grep -Eq '^[0-9a-f]{40}$' || usage
fi

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

ANCESTRY="NOT CHECKED"
APPROVAL_STATUS="-"

if [ "$MODE" != "baseline" ]; then
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

    if [ "$MODE" = "recovery" ]; then
      APPROVAL_STATUS="RECOVERY APPROVED"
      DRY_RUN_COMMAND=(git -C "$RELEASE_REPO" push --dry-run --porcelain \
        "--force-with-lease=refs/heads/main:${EXPECTED_OLD_REF}" "$REMOTE" \
        "${EXPECTED_NEW_REF}:refs/heads/main")
    else
      [ "$MODE" != "publish" ] || APPROVAL_STATUS="APPROVED"
      DRY_RUN_COMMAND=(git -C "$RELEASE_REPO" push --dry-run --porcelain --atomic "$REMOTE" \
        "$SPLIT_SHA:refs/heads/main" "$SPLIT_SHA:refs/tags/v${VERSION}")
    fi

    if "${DRY_RUN_COMMAND[@]}" >"$PORCELAIN_FILE" 2>/dev/null &&
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

if [ "$MODE" = "publish" ]; then
  if [ "$REMOTE_MAIN" = "$SPLIT_SHA" ]; then
    ANCESTRY="EQUAL"
  elif git -C "$RELEASE_REPO" cat-file -e "${REMOTE_MAIN}^{commit}" 2>/dev/null &&
    git -C "$RELEASE_REPO" merge-base --is-ancestor "$REMOTE_MAIN" "$SPLIT_SHA" 2>/dev/null; then
    ANCESTRY="ANCESTOR"
  else
    ANCESTRY="DIVERGED"
  fi
elif [ "$MODE" = "recovery" ]; then
  ANCESTRY="DIVERGED"
fi

dash_if_empty() { if [ -n "$1" ]; then printf '%s' "$1"; else printf '%s' '-'; fi; }

evaluate() {
  local dry_status="$1"
  local after_main="$2"
  local after_tag="$3"
  local changed="$4"

  cd "$REPO_ROOT" && "${RUNTIME[@]}" mix run --no-start -e \
  'Crosswake.ReleaseCandidate.Mirror.evaluate_cli!(System.argv())' -- \
  "$MODE" "$VERSION" "$SOURCE_REF" "$(dash_if_empty "$SPLIT_SHA")" \
  "$(dash_if_empty "$RECORDED_SPLIT_SHA")" "$REMOTE_STATUS" \
  "$(dash_if_empty "$REMOTE_MAIN")" "$(dash_if_empty "$REMOTE_TAG")" \
  "$ATOMIC_SUPPORTED" "$AUTHORIZATION_CHECKED" "$AUTHORIZATION_RESULT" "$dry_status" \
  "$(dash_if_empty "$BEFORE_MAIN")" "$(dash_if_empty "$BEFORE_TAG")" \
  "$(dash_if_empty "$after_main")" "$(dash_if_empty "$after_tag")" "$changed" \
  "$ANCESTRY" "$(dash_if_empty "$APPROVAL_STATUS")" "$(dash_if_empty "$APPROVAL_RECEIPT")" \
  "$(dash_if_empty "$EXPECTED_OLD_REF")" "$(dash_if_empty "$EXPECTED_NEW_REF")"
}

RESULT=$(evaluate "$DRY_RUN_STATUS" "$AFTER_MAIN" "$AFTER_TAG" false)

CORRECTION=$(printf '%s' "$RESULT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["correction"])')
STATE=$(printf '%s' "$RESULT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["state"])')

if [ "$STATE" = "PASS" ] && { [ "$MODE" = "publish" ] || [ "$MODE" = "recovery" ]; } &&
  [ "${CROSSWAKE_IOS_MIRROR_EXECUTE:-false}" = "true" ]; then
  CURRENT_REFS=$(git ls-remote "$REMOTE" refs/heads/main "refs/tags/v${VERSION}" 2>/dev/null) || exit 1
  CURRENT_MAIN=$(printf '%s\n' "$CURRENT_REFS" | awk '$2 == "refs/heads/main" {print $1}' | head -1)
  CURRENT_TAG=$(printf '%s\n' "$CURRENT_REFS" | awk -v ref="refs/tags/v${VERSION}" '$2 == ref {print $1}' | head -1)
  [ "$CURRENT_MAIN" = "$EXPECTED_OLD_REF" ] || exit 1
  [ "$CURRENT_TAG" = "$REMOTE_TAG" ] || exit 1

  if [ "$MODE" = "publish" ]; then
    git -C "$RELEASE_REPO" push --porcelain --atomic "$REMOTE" \
      "$SPLIT_SHA:refs/heads/main" "$SPLIT_SHA:refs/tags/v${VERSION}" >/dev/null
  else
    git -C "$RELEASE_REPO" push --porcelain \
      "--force-with-lease=refs/heads/main:${EXPECTED_OLD_REF}" "$REMOTE" \
      "${EXPECTED_NEW_REF}:refs/heads/main" >/dev/null
  fi

  FINAL_REFS=$(git ls-remote "$REMOTE" refs/heads/main "refs/tags/v${VERSION}" 2>/dev/null) || exit 1
  FINAL_MAIN=$(printf '%s\n' "$FINAL_REFS" | awk '$2 == "refs/heads/main" {print $1}' | head -1)
  FINAL_TAG=$(printf '%s\n' "$FINAL_REFS" | awk -v ref="refs/tags/v${VERSION}" '$2 == ref {print $1}' | head -1)
  RESULT=$(evaluate "APPLIED" "$FINAL_MAIN" "$FINAL_TAG" true)
  STATE=$(printf '%s' "$RESULT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["state"])')
fi

printf '%s\n' "$RESULT"
if [ "$CORRECTION" = "WRITE AUTHORITY NOT CHECKED" ]; then
  echo "WRITE AUTHORITY NOT CHECKED"
fi
[ "$STATE" = "PASS" ]
