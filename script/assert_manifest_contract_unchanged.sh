#!/usr/bin/env bash
# assert_manifest_contract_unchanged.sh — decides, mechanically, whether doctor's
# `manifest_contract` check source is byte-identical to its pre-Phase-174 state
# (ROADMAP Success Criterion 6, ROOM-06).
#
# Usage:
#   bash script/assert_manifest_contract_unchanged.sh \
#     [--source lib/crosswake/doctor/doctor.ex] \
#     [--baseline test/support/fixtures/phase174/manifest_contract_baseline.txt]
#
# Two regions of `--source` are compared byte-for-byte against the committed baseline:
#
#   Region DEF  — the full source of `manifest_compile_check/1`, the only function that
#                 emits the `manifest_contract` finding.
#   Region CALL — the single line containing the function capture that reaches it.
#
# Guarding both regions separately means the check cannot be neutralised either by editing
# the function body OR by disconnecting it (deleting the call site while leaving the
# function intact) without this guard catching it.
#
# Extraction runs FIRST, and its result is asserted non-empty and exactly-one-occurrence
# BEFORE any comparison. Comparing two empty extractions (e.g. because the guarded function
# was renamed or deleted) would otherwise compare equal and pass silently — the exact
# empty-collection vacuity shape this milestone exists to remove.
#
# This script contains no construct that converts a failure into a success — no `|| true`,
# no default-on-error branch, and no comparison whose status is taken from the tail of a
# pipeline.
#
# If this guard fails, the correct response is to REVERT the change to `--source`. The
# baseline is pinned to git commit 8bc77c35157e78da0a6a8b06301cfac48f5dc301 and updating it
# to match a changed implementation would make the guard self-confirming.
#
# Exit codes:
#   0  MANIFEST_CONTRACT_UNCHANGED_VERIFIED
#   2  usage error (unknown flag, missing flag value, missing file)
#   3  MANIFEST_CONTRACT_EXTRACTION_EMPTY — extraction found nothing, or found more than one
#      occurrence, for Region DEF or Region CALL
#   4  MANIFEST_CONTRACT_DEF_DRIFT  — Region DEF differs from the baseline
#   5  MANIFEST_CONTRACT_CALL_DRIFT — Region CALL differs from the baseline

set -euo pipefail

VERIFIED_TOKEN='MANIFEST_CONTRACT_UNCHANGED_VERIFIED'
EXTRACTION_EMPTY_TOKEN='MANIFEST_CONTRACT_EXTRACTION_EMPTY'
DEF_DRIFT_TOKEN='MANIFEST_CONTRACT_DEF_DRIFT'
CALL_DRIFT_TOKEN='MANIFEST_CONTRACT_CALL_DRIFT'

SOURCE="lib/crosswake/doctor/doctor.ex"
BASELINE="test/support/fixtures/phase174/manifest_contract_baseline.txt"

log() {
  echo "[crosswake] $*"
}

usage_fail() {
  echo "[crosswake] FAIL: $1"
  log "What to do next: $2"
  exit 2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --source) [ "$#" -ge 2 ] || usage_fail "--source requires a value." "Pass --source <path to doctor.ex>."; SOURCE="$2"; shift 2 ;;
    --baseline) [ "$#" -ge 2 ] || usage_fail "--baseline requires a value." "Pass --baseline <path to the baseline fixture>."; BASELINE="$2"; shift 2 ;;
    *) usage_fail "unknown argument '$1'." "Pass only --source and --baseline." ;;
  esac
done

[ -f "$SOURCE" ] || usage_fail "no source file at '${SOURCE}'." "Pass --source <path to doctor.ex>."
[ -f "$BASELINE" ] || usage_fail "no baseline fixture at '${BASELINE}'." "Pass --baseline <path to the committed baseline fixture>."

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

SOURCE_DEF="${WORK_DIR}/source_def.txt"
SOURCE_CALL="${WORK_DIR}/source_call.txt"
BASELINE_DEF="${WORK_DIR}/baseline_def.txt"
BASELINE_CALL="${WORK_DIR}/baseline_call.txt"

# --- 1. Extraction -----------------------------------------------------------------------

DEF_FUNCTION_PATTERN='^  defp manifest_compile_check\(error\) do$'
CALL_PATTERN='&manifest_compile_check/1'

# awk's `-v name=value` interprets C-style backslash escapes in `value`, which silently
# strips the `\(` `\)` escapes this ERE pattern needs to match literal parentheses. Exporting
# the pattern and reading it back through ENVIRON avoids that escape processing entirely, so
# the same pattern text reaches both grep -E (below) and awk unmodified.
export DEF_FUNCTION_PATTERN CALL_PATTERN

awk '
  $0 ~ ENVIRON["DEF_FUNCTION_PATTERN"] { capture = 1 }
  capture { print }
  capture && /^  end$/ { exit }
' "$SOURCE" > "$SOURCE_DEF"

awk '$0 ~ ENVIRON["CALL_PATTERN"]' "$SOURCE" > "$SOURCE_CALL"

awk '/^===REGION_DEF===$/ { f = 1; next } /^===REGION_CALL===$/ { f = 0 } f' "$BASELINE" > "$BASELINE_DEF"
awk '/^===REGION_CALL===$/ { f = 1; next } f' "$BASELINE" > "$BASELINE_CALL"

DEF_DEFINITION_COUNT="$(grep -Ec -- "$DEF_FUNCTION_PATTERN" "$SOURCE" || true)"
CALL_SITE_COUNT="$(grep -Ec -- "$CALL_PATTERN" "$SOURCE" || true)"

# --- 2. Assertion 1: extraction non-empty, exactly one occurrence each -------------------
# This assertion runs BEFORE any byte comparison. A renamed or deleted
# `manifest_compile_check/1` produces an empty SOURCE_DEF; comparing that against the
# (non-empty) baseline would already fail below, but a renamed AND baseline-matching-empty
# scenario must never be reachable, so occurrence count is asserted directly here rather
# than inferred from file emptiness alone.

if [ ! -s "$SOURCE_DEF" ] || [ "$DEF_DEFINITION_COUNT" -ne 1 ]; then
  echo "[crosswake] FAIL: ${EXTRACTION_EMPTY_TOKEN}: expected exactly 1 definition of manifest_compile_check/1 in '${SOURCE}' matching '${DEF_FUNCTION_PATTERN}', found ${DEF_DEFINITION_COUNT}."
  log "What to do next: the guarded function was renamed, deleted, or duplicated. Revert the change to '${SOURCE}'; do not edit the baseline."
  exit 3
fi

if [ ! -s "$SOURCE_CALL" ] || [ "$CALL_SITE_COUNT" -ne 1 ]; then
  echo "[crosswake] FAIL: ${EXTRACTION_EMPTY_TOKEN}: expected exactly 1 call site matching '${CALL_PATTERN}' in '${SOURCE}', found ${CALL_SITE_COUNT}."
  log "What to do next: the call site that reaches manifest_compile_check/1 was renamed, deleted, or duplicated. Revert the change to '${SOURCE}'; do not edit the baseline."
  exit 3
fi

# --- 3. Assertion 2: Region DEF byte identity --------------------------------------------

if ! diff -q "$BASELINE_DEF" "$SOURCE_DEF" > /dev/null 2>&1; then
  FIRST_DIFF_LINE="$(diff "$BASELINE_DEF" "$SOURCE_DEF" | head -1 || true)"
  echo "[crosswake] FAIL: ${DEF_DRIFT_TOKEN}: manifest_compile_check/1's source in '${SOURCE}' differs from the baseline pinned to commit 8bc77c35157e78da0a6a8b06301cfac48f5dc301."
  log "First differing line: ${FIRST_DIFF_LINE}"
  log "What to do next: revert the change to '${SOURCE}'. Do not update the baseline to match a changed implementation — it is pinned to a commit and updating it would make this guard self-confirming."
  exit 4
fi

# --- 4. Assertion 3: Region CALL byte identity -------------------------------------------
# Guarded separately so that disconnecting the check (deleting the call while leaving the
# function body intact) is caught as its own named result rather than silently passing
# because Region DEF alone still matched.

if ! diff -q "$BASELINE_CALL" "$SOURCE_CALL" > /dev/null 2>&1; then
  FIRST_DIFF_LINE="$(diff "$BASELINE_CALL" "$SOURCE_CALL" | head -1 || true)"
  echo "[crosswake] FAIL: ${CALL_DRIFT_TOKEN}: the call site reaching manifest_compile_check/1 in '${SOURCE}' differs from the baseline pinned to commit 8bc77c35157e78da0a6a8b06301cfac48f5dc301."
  log "First differing line: ${FIRST_DIFF_LINE}"
  log "What to do next: revert the change to '${SOURCE}'. Do not update the baseline to match a changed implementation — it is pinned to a commit and updating it would make this guard self-confirming."
  exit 5
fi

echo "[crosswake] OK: ${VERIFIED_TOKEN}: manifest_compile_check/1 and its call site in '${SOURCE}' are byte-identical to the baseline pinned to commit 8bc77c35157e78da0a6a8b06301cfac48f5dc301."
