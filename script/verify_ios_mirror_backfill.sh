#!/usr/bin/env bash
# Compatibility entry point for explicit release-candidate iOS mirror modes.
#
# Usage:
#   script/verify_ios_mirror_backfill.sh --version 0.2.0 --ref refs/tags/ios-core-v0.2.0
#   script/verify_ios_mirror_backfill.sh --mode candidate --version 0.2.1 --ref <40sha>
#
# Verification is the default and uses the credential-free immutable baseline.
# Candidate rehearsal accepts a full source SHA and never mutates a remote. Publish and
# recovery require explicit approval bindings; recovery additionally requires --update-main.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VERSION=""
SOURCE_REF=""
MODE="baseline"
APPLY=0
UPDATE_MAIN=0
APPROVAL_RECEIPT=""
EXPECTED_OLD_REF=""
EXPECTED_NEW_REF=""

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
Usage: $0 [--mode baseline|candidate|publish|recovery] --version VERSION --ref REF
          [--apply] [--update-main] [--approval-receipt SHA256]
          [--expected-old-ref SHA] [--expected-new-ref SHA]

Default mode verifies the credential-free 0.2.0 baseline. Candidate mode
requires exact 0.2.1 and a full 40-SHA and performs only a porcelain dry-run.
Publish performs only an approved ordinary atomic update. Recovery is the sole
mode that permits exact-ref force-with-lease semantics.
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
    --approval-receipt)
      APPROVAL_RECEIPT="${2:-}"
      shift 2
      ;;
    --expected-old-ref)
      EXPECTED_OLD_REF="${2:-}"
      shift 2
      ;;
    --expected-new-ref)
      EXPECTED_NEW_REF="${2:-}"
      shift 2
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

case "$MODE" in
  baseline|candidate)
    if [ "$APPLY" -eq 1 ] || [ "$UPDATE_MAIN" -eq 1 ]; then
      fail "baseline and candidate modes are read-only." "Choose the explicit publish or recovery mode with its exact approval bindings."
    fi
    exec "$SCRIPT_DIR/release_candidate/ios_mirror.sh" "$MODE" --version "$VERSION" --ref "$SOURCE_REF"
    ;;
  publish|recovery)
    [ "$APPLY" -eq 1 ] || fail "${MODE} mode requires --apply." "Review the exact approval receipt and rerun with --apply."
    if [ "$MODE" = "recovery" ] && [ "$UPDATE_MAIN" -ne 1 ]; then
      fail "recovery mode requires --update-main." "Recovery may update only exact approved mirror main refs."
    fi
    CROSSWAKE_IOS_MIRROR_EXECUTE=true exec "$SCRIPT_DIR/release_candidate/ios_mirror.sh" \
      "$MODE" --version "$VERSION" --ref "$SOURCE_REF" \
      --approval-receipt "$APPROVAL_RECEIPT" \
      --expected-old-ref "$EXPECTED_OLD_REF" \
      --expected-new-ref "$EXPECTED_NEW_REF"
    ;;
  *)
    fail "unknown mirror mode." "Use baseline, candidate, publish, or recovery explicitly."
    ;;
esac
