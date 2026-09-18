#!/usr/bin/env bash
# append_release_ledger.sh — the durable, git-committed record of every
# exact-public proof verdict (XPUB-06).
#
# Usage:
#   bash script/append_release_ledger.sh \
#     --package crosswake \
#     --version 0.2.1 \
#     --approved-head <40 lowercase hex> \
#     --ref <exact tag ref or 40-hex SHA that was published> \
#     --lane ordinary|recovery \
#     --run-id <github.run_id> \
#     --outcome success|failure|cancelled|skipped \
#     [--ledger docs/release-ledger/RELEASE-LEDGER.jsonl]
#
# WHY A COMMITTED FILE AND NOT A LONGER ARTIFACT RETENTION.
# This repository is public, so the uploaded-artifact retention ceiling is far
# below the horizon over which a release record has to stay readable. No
# retention value satisfies the criterion; a file in git does, because git has
# no expiry and the file's own history is the audit trail. The proof artifact
# stays exactly as it is — a useful fast-path signal, not the copy of record.
# Nothing in this script or its caller tunes `retention-days`.
#
# APPEND-ONLY, DELIBERATELY. This script only ever adds a line to the end of the
# ledger. It never rewrites, reorders or removes an existing line, so the file's
# git history is the record: an entry that was once written cannot be quietly
# restated later without that restatement showing up as a diff.
#
# IDEMPOTENT ON (package, version, approved_head, run_id). A rerun of the same
# workflow run is the NORMAL recovery motion in this pipeline — a maintainer
# re-runs failed jobs rather than cutting a new release — so the same run
# reaching this script twice must leave one line, not two. The duplicate check
# below is what makes a rerun safe; without it every rerun would inflate the
# ledger with rows that look like distinct release events and were not.
#
# FAILURE IS RECORDED AS FAITHFULLY AS SUCCESS. The outcome field carries the
# proof's real verdict, including `failure`, `cancelled` and `skipped`. A ledger
# that recorded only passes could not distinguish "the proof failed" from "the
# proof never ran" — absence scored as success, which is the exact equivalence
# this milestone exists to break.
#
# Exit codes (distinct on purpose — the caller's log must name WHICH field was
# rejected, not merely that something was):
#   0  line appended, or an identical line for this run already existed
#   2  usage error (unknown flag, missing flag value, missing required field)
#   3  --approved-head is not 40 lowercase hex characters
#   4  --version is not a semver version
#   5  --lane is not one of the declared lane names
#   6  --outcome is not one of the declared proof outcomes
#   7  --run-id is not a positive integer

set -euo pipefail

# The same patterns the publication-record emitter validates with
# (script/write_publication_record.sh). Two record writers disagreeing about
# what a valid approved head looks like is how one lane's record silently stops
# matching the other's.
FULL_SHA_PATTERN='^[0-9a-f]{40}$'
VERSION_PATTERN='^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$'
RUN_ID_PATTERN='^[1-9][0-9]*$'
SCHEMA_VERSION='1.0.0'

# The two — and only two — publication lanes this repository has.
ORDINARY_LANE='ordinary'
RECOVERY_LANE='recovery'

# The closed set of outcomes a GitHub Actions job can report. Free text here
# would make "the proof failed" and "the proof never ran" indistinguishable
# again, one layer down.
SUCCESS_OUTCOME='success'
FAILURE_OUTCOME='failure'
CANCELLED_OUTCOME='cancelled'
SKIPPED_OUTCOME='skipped'

DEFAULT_LEDGER='docs/release-ledger/RELEASE-LEDGER.jsonl'

PACKAGE=""
VERSION=""
APPROVED_HEAD=""
REF=""
LANE=""
RUN_ID=""
OUTCOME=""
LEDGER="$DEFAULT_LEDGER"

log() {
  echo "[crosswake] $*"
}

fail() {
  local code="$1"
  local message="$2"
  local next_action="$3"

  echo "[crosswake] FAIL: ${message}"
  log "What to do next: ${next_action}"
  exit "$code"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --package) [ "$#" -ge 2 ] || fail 2 "--package requires a value." "Pass --package <hex package name>." ; PACKAGE="$2"; shift 2 ;;
    --version) [ "$#" -ge 2 ] || fail 2 "--version requires a value." "Pass --version <semver>." ; VERSION="$2"; shift 2 ;;
    --approved-head) [ "$#" -ge 2 ] || fail 2 "--approved-head requires a value." "Pass --approved-head <40 lowercase hex>." ; APPROVED_HEAD="$2"; shift 2 ;;
    --ref) [ "$#" -ge 2 ] || fail 2 "--ref requires a value." "Pass --ref <published tag ref or 40-hex SHA>." ; REF="$2"; shift 2 ;;
    --lane) [ "$#" -ge 2 ] || fail 2 "--lane requires a value." "Pass --lane ${ORDINARY_LANE} or --lane ${RECOVERY_LANE}." ; LANE="$2"; shift 2 ;;
    --run-id) [ "$#" -ge 2 ] || fail 2 "--run-id requires a value." "Pass --run-id \${{ github.run_id }}." ; RUN_ID="$2"; shift 2 ;;
    --outcome) [ "$#" -ge 2 ] || fail 2 "--outcome requires a value." "Pass --outcome ${SUCCESS_OUTCOME}, ${FAILURE_OUTCOME}, ${CANCELLED_OUTCOME} or ${SKIPPED_OUTCOME}." ; OUTCOME="$2"; shift 2 ;;
    --ledger) [ "$#" -ge 2 ] || fail 2 "--ledger requires a value." "Pass --ledger <path to the jsonl ledger>." ; LEDGER="$2"; shift 2 ;;
    *) fail 2 "unknown argument '$1'." "Pass only --package, --version, --approved-head, --ref, --lane, --run-id, --outcome and --ledger." ;;
  esac
done

[ -n "$PACKAGE" ] || fail 2 "--package is required, but none was supplied." "Pass --package <hex package name>."
[ -n "$REF" ] || fail 2 "--ref is required, but none was supplied." "Pass --ref <published tag ref or 40-hex SHA>."
[ -n "$RUN_ID" ] || fail 2 "--run-id is required, but none was supplied." "Pass --run-id \${{ github.run_id }}."
[ -n "$OUTCOME" ] || fail 2 "--outcome is required, but none was supplied." "Pass --outcome ${SUCCESS_OUTCOME}, ${FAILURE_OUTCOME}, ${CANCELLED_OUTCOME} or ${SKIPPED_OUTCOME}."

# Validate every field BEFORE touching the ledger, so a rejected entry never
# leaves a half-written line behind for a later reader to trust.
if ! printf '%s' "$APPROVED_HEAD" | grep -Eq "$FULL_SHA_PATTERN"; then
  fail 3 "approved_head '${APPROVED_HEAD}' is not 40 lowercase hex characters." \
    "Pass the exact approved candidate head the release was gated on, matching ${FULL_SHA_PATTERN}."
fi

if ! printf '%s' "$VERSION" | grep -Eq "$VERSION_PATTERN"; then
  fail 4 "version '${VERSION}' is not a semver version." \
    "Pass the approved release version, matching ${VERSION_PATTERN}."
fi

case "$LANE" in
  "$ORDINARY_LANE"|"$RECOVERY_LANE") ;;
  *)
    fail 5 "lane '${LANE}' is not a declared publication lane." \
      "Pass --lane ${ORDINARY_LANE} (release-please.yml exact-public-proof) or --lane ${RECOVERY_LANE} (hex-publish.yml recovery-exact-public-proof)."
    ;;
esac

case "$OUTCOME" in
  "$SUCCESS_OUTCOME"|"$FAILURE_OUTCOME"|"$CANCELLED_OUTCOME"|"$SKIPPED_OUTCOME") ;;
  *)
    fail 6 "outcome '${OUTCOME}' is not a declared proof outcome." \
      "Pass --outcome ${SUCCESS_OUTCOME}, ${FAILURE_OUTCOME}, ${CANCELLED_OUTCOME} or ${SKIPPED_OUTCOME} — the literal result of the proof job."
    ;;
esac

if ! printf '%s' "$RUN_ID" | grep -Eq "$RUN_ID_PATTERN"; then
  fail 7 "run_id '${RUN_ID}' is not a positive integer." \
    "Pass --run-id \${{ github.run_id }}, matching ${RUN_ID_PATTERN}."
fi

mkdir -p "$(dirname "$LEDGER")"
touch "$LEDGER"

# Idempotency on (package, version, approved_head, run_id). Comment lines are
# skipped by the `select(.run_id ...)` filter only because jq never sees them:
# they are stripped here rather than fed to jq, so a malformed data line still
# fails loudly instead of being mistaken for a comment.
# `grep` exits 1 on no match, so each filter is guarded: a ledger holding only
# the header comment is an empty data set, not an error.
data=$( { grep -v '^[[:space:]]*#' "$LEDGER" || true; } | { grep -v '^[[:space:]]*$' || true; } )
existing=$(printf '%s' "$data" | jq -s \
  --arg package "$PACKAGE" \
  --arg version "$VERSION" \
  --arg approved_head "$APPROVED_HEAD" \
  --arg run_id "$RUN_ID" \
  '[.[] | select(.package == $package and .version == $version and .approved_head == $approved_head and .run_id == $run_id)] | length')

if [ "$existing" -gt 0 ]; then
  log "OK: ledger already records ${PACKAGE}@${VERSION} (head ${APPROVED_HEAD}) for run ${RUN_ID} — not appending a duplicate."
  exit 0
fi

RECORDED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# -c: exactly one line per entry, which is what makes this file a JSON Lines
# ledger a reader can bisect through git history line by line.
line=$(jq -c -n \
  --arg schema_version "$SCHEMA_VERSION" \
  --arg package "$PACKAGE" \
  --arg version "$VERSION" \
  --arg approved_head "$APPROVED_HEAD" \
  --arg ref "$REF" \
  --arg lane "$LANE" \
  --arg run_id "$RUN_ID" \
  --arg outcome "$OUTCOME" \
  --arg recorded_at "$RECORDED_AT" \
  '{
    schema_version: $schema_version,
    package: $package,
    version: $version,
    approved_head: $approved_head,
    ref: $ref,
    lane: $lane,
    run_id: $run_id,
    outcome: $outcome,
    recorded_at: $recorded_at
  }')

printf '%s\n' "$line" >> "$LEDGER"

echo "[crosswake] OK: recorded exact-public proof outcome '${OUTCOME}' for ${PACKAGE}@${VERSION} (lane ${LANE}, head ${APPROVED_HEAD}, run ${RUN_ID}) in ${LEDGER}"
