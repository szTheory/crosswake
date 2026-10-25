#!/bin/bash
# Phase 194 one-time capture of real gh/git output for test/fixtures/bearings (D-10).
# usage: capture-bearings-fixtures-194.sh   (run from anywhere; needs an authenticated gh)
# Each fixture is the stdout of the exact command bearings-report runs; MANIFEST.txt lists `<file> <command>`.
# Exit: 0 captured and privacy clean, 1 capture or privacy failure. Labels only: no output text is echoed.
set -u
umask 077
export LC_ALL=C

HERE=$(cd "$(dirname "$0")" && pwd -P) || { echo "capture: locate failed"; exit 1; }
ROOT=$(git -C "$HERE" rev-parse --show-toplevel) || { echo "capture: locate failed"; exit 1; }
OUT="$ROOT/test/fixtures/bearings"
mkdir -p "$OUT"
: > "$OUT/MANIFEST.txt"
FILES=()

# cap FILE CMD ARGS...: run, refuse to write on a non-zero rc, record in MANIFEST.
cap() {
  f=$1; shift
  out=$("$@"); rc=$?
  if [ "$rc" -ne 0 ]; then echo "capture: failed $f"; exit 1; fi
  printf '%s\n' "$out" > "$OUT/$f"
  printf '%s %s\n' "$f" "$*" >> "$OUT/MANIFEST.txt"
  FILES+=("$OUT/$f")
}

cd "$ROOT" || exit 1
JQ='[.[] | {number: .number, merged_at: .merged_at, head_sha: .head.sha}]'

cap git-rev-parse-origin-main.txt git rev-parse origin/main
cap git-rev-parse-head.txt git rev-parse HEAD
cap gh-repo-view.json gh repo view --json nameWithOwner
SLUG=$(jq -r .nameWithOwner "$OUT/gh-repo-view.json"); rc=$?
[ "$rc" -eq 0 ] && [ -n "$SLUG" ] || { echo "capture: failed slug"; exit 1; }
MAIN=$(cat "$OUT/git-rev-parse-origin-main.txt")
cap gh-commit-pulls.json gh api "repos/$SLUG/commits/$MAIN/pulls" --jq "$JQ"
PRHEAD=$(jq -r '.[] | select(.merged_at != null) | .head_sha' "$OUT/gh-commit-pulls.json"); rc=$?
[ "$rc" -eq 0 ] && [ -n "$PRHEAD" ] || { echo "capture: failed pr head"; exit 1; }
cap gh-run-list-pr-head.json gh run list --workflow "Crosswake CI" --commit "$PRHEAD" --limit 20 --json databaseId,headSha,status,conclusion,event

# Plan 07 appends further `cap` lines above this point.
bash "$HERE/../../193-cleanup-and-new-working-rules/scripts/privacy-193.sh" "${FILES[@]}" "$OUT/MANIFEST.txt"; rc=$?
[ "$rc" -eq 0 ] || { echo "capture: privacy hit"; exit 1; }
echo "capture: privacy clean files $((${#FILES[@]} + 1))"
