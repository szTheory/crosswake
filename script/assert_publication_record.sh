#!/usr/bin/env bash
# assert_publication_record.sh — the record-presence decision for the shared
# exact-public proof.
#
# Usage:
#   bash script/assert_publication_record.sh \
#     --package crosswake \
#     --version 0.2.1 \
#     --approved-head <40 lowercase hex> \
#     --record <path to the downloaded publication record>
#
# The expected {package, version, approved_head} triple MUST come from the
# calling workflow's own trusted inputs — never from the record being checked.
# Deriving the expected values from the artifact under verification is the
# scope-selector defect recorded as SEED-019: a record naming the wrong version
# would then verify itself.
#
# All three fields are compared. Checking only presence, or only one field, is
# the column-scope defect recorded as SEED-020 — the check would run against a
# real, non-empty subject and still prove nothing about the fields that matter.
#
# "We could not read it" and "it was not there" are DIFFERENT results, because
# they call for different operator actions: the first means the emitter or the
# upload is broken, the second means no publish wrote a record at all.
#
# This script contains no construct that converts a failure into a success —
# no `|| true`, no default-on-error branch, no exit code swallowed by a pipe.
#
# Exit codes:
#   0  PUBLICATION_RECORD_VERIFIED
#   2  usage error (unknown flag, missing flag value, missing required field)
#   4  PUBLICATION_RECORD_MISSING     — no record file at the given path
#   5  PUBLICATION_RECORD_MISMATCH    — record present, triple disagrees
#   6  PUBLICATION_RECORD_UNREADABLE  — record present, unparseable or missing a key

set -euo pipefail

VERIFIED_TOKEN='PUBLICATION_RECORD_VERIFIED'
MISSING_TOKEN='PUBLICATION_RECORD_MISSING'
MISMATCH_TOKEN='PUBLICATION_RECORD_MISMATCH'
UNREADABLE_TOKEN='PUBLICATION_RECORD_UNREADABLE'

REQUIRED_KEYS="schema_version package version approved_head ref path run_id published_at"

EXPECTED_PACKAGE=""
EXPECTED_VERSION=""
EXPECTED_HEAD=""
RECORD=""

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
    --package) [ "$#" -ge 2 ] || usage_fail "--package requires a value." "Pass --package <hex package name>." ; EXPECTED_PACKAGE="$2"; shift 2 ;;
    --version) [ "$#" -ge 2 ] || usage_fail "--version requires a value." "Pass --version <approved semver>." ; EXPECTED_VERSION="$2"; shift 2 ;;
    --approved-head) [ "$#" -ge 2 ] || usage_fail "--approved-head requires a value." "Pass --approved-head <40 lowercase hex>." ; EXPECTED_HEAD="$2"; shift 2 ;;
    --record) [ "$#" -ge 2 ] || usage_fail "--record requires a value." "Pass --record <path to the downloaded publication record>." ; RECORD="$2"; shift 2 ;;
    *) usage_fail "unknown argument '$1'." "Pass only --package, --version, --approved-head and --record." ;;
  esac
done

[ -n "$EXPECTED_PACKAGE" ] || usage_fail "--package is required, but none was supplied." "Pass --package <hex package name>."
[ -n "$EXPECTED_VERSION" ] || usage_fail "--version is required, but none was supplied." "Pass --version <approved semver>."
[ -n "$EXPECTED_HEAD" ] || usage_fail "--approved-head is required, but none was supplied." "Pass --approved-head <40 lowercase hex>."
[ -n "$RECORD" ] || usage_fail "--record is required, but none was supplied." "Pass --record <path to the downloaded publication record>."

EXPECTED_TRIPLE="package '${EXPECTED_PACKAGE}', version '${EXPECTED_VERSION}', approved_head '${EXPECTED_HEAD}'"

if [ ! -f "$RECORD" ]; then
  echo "[crosswake] FAIL: ${MISSING_TOKEN}: no publication record at '${RECORD}' for ${EXPECTED_TRIPLE}."
  log "What to do next: confirm the publish job for that coordinate ran and uploaded its publication-record artifact; a publish that left no record is not provably a publish."
  exit 4
fi

if ! jq -e . "$RECORD" > /dev/null 2>&1; then
  echo "[crosswake] FAIL: ${UNREADABLE_TOKEN}: publication record '${RECORD}' is not valid JSON."
  log "What to do next: inspect the uploaded artifact and the emitter step's log; an unreadable record is a broken emitter or a truncated upload, NOT an absent publish."
  exit 6
fi

for key in $REQUIRED_KEYS; do
  if ! jq -e --arg k "$key" 'has($k) and (.[$k] != null)' "$RECORD" > /dev/null 2>&1; then
    echo "[crosswake] FAIL: ${UNREADABLE_TOKEN}: publication record '${RECORD}' is missing required key '${key}'."
    log "What to do next: the record was not written by script/write_publication_record.sh at its current schema; re-check the emitter step rather than re-running the publish."
    exit 6
  fi
done

FOUND_PACKAGE=$(jq -er '.package' "$RECORD")
FOUND_VERSION=$(jq -er '.version' "$RECORD")
FOUND_HEAD=$(jq -er '.approved_head' "$RECORD")

MISMATCHES=""

if [ "$FOUND_PACKAGE" != "$EXPECTED_PACKAGE" ]; then
  MISMATCHES="${MISMATCHES} package(expected '${EXPECTED_PACKAGE}', found '${FOUND_PACKAGE}')"
fi

if [ "$FOUND_VERSION" != "$EXPECTED_VERSION" ]; then
  MISMATCHES="${MISMATCHES} version(expected '${EXPECTED_VERSION}', found '${FOUND_VERSION}')"
fi

if [ "$FOUND_HEAD" != "$EXPECTED_HEAD" ]; then
  MISMATCHES="${MISMATCHES} approved_head(expected '${EXPECTED_HEAD}', found '${FOUND_HEAD}')"
fi

if [ -n "$MISMATCHES" ]; then
  echo "[crosswake] FAIL: ${MISMATCH_TOKEN}: publication record '${RECORD}' does not name the expected coordinate —${MISMATCHES}."
  log "What to do next: do not re-run the proof. The record describes a different publication than the one being proved; establish which publish wrote it before trusting either coordinate."
  exit 5
fi

echo "[crosswake] OK: ${VERIFIED_TOKEN}: publication record '${RECORD}' names ${EXPECTED_TRIPLE}."
