#!/usr/bin/env bash
# Compatibility entry point for explicit release-candidate iOS mirror modes.
#
# Usage:
#   script/verify_ios_mirror_backfill.sh --version 0.2.0 --ref refs/tags/ios-core-v0.2.0
#   script/verify_ios_mirror_backfill.sh --version 0.2.0 --ref refs/tags/ios-core-v0.2.0 --apply
#
# Verification is the default and uses the credential-free immutable baseline.
# Candidate rehearsal accepts a full source SHA and never mutates a remote.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VERSION=""
SOURCE_REF=""
MODE="baseline"
APPLY=0
UPDATE_MAIN=0

log() {
  echo "[crosswake] $*"
}

ok() {
  echo "[crosswake] OK: $*"
}

fail() {
  local message="$1"
  local next_action="${2:-Inspect the version, release ref, mirror tag, and registry state before retrying.}"

  echo "[crosswake] FAIL: ${message}"
  log "What to do next: ${next_action}"
  exit 1
}

usage() {
  cat <<EOF
Usage: $0 [--mode baseline|candidate] --version VERSION --ref REF [--apply] [--update-main]

Default mode verifies the credential-free 0.2.0 baseline. Candidate mode
requires exact 0.2.1 and a full 40-SHA and performs only a porcelain dry-run.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    --version)
      VERSION="${2:-}"
      shift 2
      ;;
    --ref)
      SOURCE_REF="${2:-}"
      shift 2
      ;;
    --apply)
      APPLY=1
      shift
      ;;
    --update-main)
      UPDATE_MAIN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument '$1'." "Use --version VERSION --ref refs/tags/ios-core-vVERSION with optional --apply and --update-main."
      ;;
  esac
done

if [ "$APPLY" -eq 1 ] || [ "$UPDATE_MAIN" -eq 1 ]; then
  fail "publication and recovery require their explicit Phase 168 modes." "Use only baseline or candidate rehearsal until the separately approved mode is implemented."
fi

exec "$SCRIPT_DIR/release_candidate/ios_mirror.sh" "$MODE" --version "$VERSION" --ref "$SOURCE_REF"
