#!/usr/bin/env bash
# write_publication_record.sh — the single post-publish publication-record emitter.
#
# Usage:
#   bash script/write_publication_record.sh \
#     --package crosswake \
#     --version 0.2.1 \
#     --approved-head <40 lowercase hex> \
#     --ref <exact tag ref or 40-hex SHA that was published> \
#     --lane ordinary|recovery \
#     --run-id <github.run_id> \
#     --output <path to write>
#
# BOTH publish lanes call THIS script: `publish-hex` in release-please.yml
# (lane `ordinary`) and the `operation: recovery` `publish` job in
# hex-publish.yml (lane `recovery`). There is exactly one emitter on purpose —
# two similar YAML steps can drift apart silently, while a drift here is a
# change to this one file and shows up in this file's diff.
#
# The lane name is a closed list, never free text: the lane is what makes the
# two lanes' records distinguishable afterwards, and an unconstrained lane
# field would make that distinction unprovable.
#
# Exit codes (distinct on purpose — the caller's log must name WHICH field was
# rejected, not merely that something was):
#   0  record written
#   2  usage error (unknown flag, missing flag value, missing required field)
#   3  --approved-head is not 40 lowercase hex characters
#   4  --version is not a semver version
#   5  --lane is not one of the declared lane names

set -euo pipefail

FULL_SHA_PATTERN='^[0-9a-f]{40}$'
VERSION_PATTERN='^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$'
SCHEMA_VERSION='1.0.0'

# The two — and only two — publication lanes this repository has.
ORDINARY_LANE='ordinary'
RECOVERY_LANE='recovery'

PACKAGE=""
VERSION=""
APPROVED_HEAD=""
REF=""
LANE=""
RUN_ID=""
OUTPUT=""

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
    --output) [ "$#" -ge 2 ] || fail 2 "--output requires a value." "Pass --output <path to write the record to>." ; OUTPUT="$2"; shift 2 ;;
    *) fail 2 "unknown argument '$1'." "Pass only --package, --version, --approved-head, --ref, --lane, --run-id and --output." ;;
  esac
done

[ -n "$PACKAGE" ] || fail 2 "--package is required, but none was supplied." "Pass --package <hex package name>."
[ -n "$REF" ] || fail 2 "--ref is required, but none was supplied." "Pass --ref <published tag ref or 40-hex SHA>."
[ -n "$RUN_ID" ] || fail 2 "--run-id is required, but none was supplied." "Pass --run-id \${{ github.run_id }}."
[ -n "$OUTPUT" ] || fail 2 "--output is required, but none was supplied." "Pass --output <path to write the record to>."

# Validate every field BEFORE writing anything, so a rejected record never
# leaves a half-written file behind for a later step to read as authoritative.
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
      "Pass --lane ${ORDINARY_LANE} (release-please.yml publish-hex) or --lane ${RECOVERY_LANE} (hex-publish.yml recovery publish)."
    ;;
esac

PUBLISHED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)

jq -n \
  --arg schema_version "$SCHEMA_VERSION" \
  --arg package "$PACKAGE" \
  --arg version "$VERSION" \
  --arg approved_head "$APPROVED_HEAD" \
  --arg ref "$REF" \
  --arg path "$LANE" \
  --arg run_id "$RUN_ID" \
  --arg published_at "$PUBLISHED_AT" \
  '{
    schema_version: $schema_version,
    package: $package,
    version: $version,
    approved_head: $approved_head,
    ref: $ref,
    path: $path,
    run_id: $run_id,
    published_at: $published_at
  }' > "$OUTPUT"

echo "[crosswake] OK: wrote publication record for ${PACKAGE}@${VERSION} (lane ${LANE}, head ${APPROVED_HEAD}) to ${OUTPUT}"
