#!/usr/bin/env bash

set -euo pipefail

RUNBOOK_SHA="${1:-}"
TARGET_SHA="${2:-}"
RUNBOOK_PATH="${3:-docs/RELEASE-INCIDENT-RESPONSE.md}"
RELEASE_REPO="${CROSSWAKE_RELEASE_REPO:-}"

fail() {
  local status="$1"
  local code="$2"
  local detail="$3"

  printf 'release-runbook-ancestry status=fail code=%s %s\n' "$code" "$detail" >&2
  exit "$status"
}

if [[ ! "$RUNBOOK_SHA" =~ ^[0-9a-f]{40}$ ]]; then
  fail 2 RUNBOOK_OID_INVALID "runbook=${RUNBOOK_SHA:--}"
fi

if [[ ! "$TARGET_SHA" =~ ^[0-9a-f]{40}$ ]]; then
  fail 2 TARGET_OID_INVALID "target=${TARGET_SHA:--}"
fi

if [[ -z "$RELEASE_REPO" ]]; then
  if ! RELEASE_REPO="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    fail 2 REPOSITORY_UNAVAILABLE "target=$TARGET_SHA"
  fi
fi

if ! git -C "$RELEASE_REPO" cat-file -e "${RUNBOOK_SHA}^{commit}" 2>/dev/null; then
  fail 2 RUNBOOK_COMMIT_UNAVAILABLE "runbook=$RUNBOOK_SHA"
fi

if ! git -C "$RELEASE_REPO" cat-file -e "${TARGET_SHA}^{commit}" 2>/dev/null; then
  fail 2 TARGET_COMMIT_UNAVAILABLE "target=$TARGET_SHA"
fi

RUNBOOK_TOUCHES=$(git -C "$RELEASE_REPO" diff-tree --root --no-commit-id --name-only -r \
  "$RUNBOOK_SHA" -- "$RUNBOOK_PATH")

if [[ "$RUNBOOK_TOUCHES" != "$RUNBOOK_PATH" ]]; then
  fail 2 RUNBOOK_PATH_NOT_TOUCHED "runbook=$RUNBOOK_SHA path=$RUNBOOK_PATH"
fi

if ! git -C "$RELEASE_REPO" merge-base --is-ancestor "$RUNBOOK_SHA" "$TARGET_SHA"; then
  fail 1 RUNBOOK_NOT_ANCESTOR "runbook=$RUNBOOK_SHA target=$TARGET_SHA"
fi

if ! git -C "$RELEASE_REPO" cat-file -e "${TARGET_SHA}:${RUNBOOK_PATH}" 2>/dev/null; then
  fail 1 RUNBOOK_PATH_MISSING_FROM_TARGET "target=$TARGET_SHA path=$RUNBOOK_PATH"
fi

printf 'release-runbook-ancestry status=pass runbook=%s target=%s path=%s\n' \
  "$RUNBOOK_SHA" "$TARGET_SHA" "$RUNBOOK_PATH"
