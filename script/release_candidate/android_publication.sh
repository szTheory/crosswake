#!/usr/bin/env bash
# Publish or observe the one approved Android core coordinate from an exact merge.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
VERSION=""
SOURCE_REF=""
APPROVED_HEAD=""
APPROVED_TREE=""
CANDIDATE_RECEIPT=""
EXECUTE=false

usage() {
  echo "usage: android_publication.sh --version 0.2.1 --ref <merge-sha> --approved-head <sha> --approved-tree <tree> --candidate-receipt <sha256> [--execute]" >&2
  exit 2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --version) [ "$#" -ge 2 ] || usage; VERSION="$2"; shift 2 ;;
    --ref) [ "$#" -ge 2 ] || usage; SOURCE_REF="$2"; shift 2 ;;
    --approved-head) [ "$#" -ge 2 ] || usage; APPROVED_HEAD="$2"; shift 2 ;;
    --approved-tree) [ "$#" -ge 2 ] || usage; APPROVED_TREE="$2"; shift 2 ;;
    --candidate-receipt) [ "$#" -ge 2 ] || usage; CANDIDATE_RECEIPT="$2"; shift 2 ;;
    --execute) EXECUTE=true; shift ;;
    *) usage ;;
  esac
done

[ "$VERSION" = "0.2.1" ] || usage
printf '%s' "$SOURCE_REF$APPROVED_HEAD$APPROVED_TREE" | grep -Eq '^[0-9a-f]{120}$' || usage
printf '%s' "$CANDIDATE_RECEIPT" | grep -Eq '^[0-9a-f]{64}$' || usage

cd "$REPO_ROOT"
[ "$(git rev-parse HEAD)" = "$SOURCE_REF" ]
parent_line=$(git rev-list --parents -n 1 "$SOURCE_REF")
[ "$(printf '%s\n' "$parent_line" | awk '{print NF}')" -eq 3 ]
[ "$(printf '%s\n' "$parent_line" | awk '{print $3}')" = "$APPROVED_HEAD" ]
[ "$(git rev-parse "${SOURCE_REF}^{tree}")" = "$APPROVED_TREE" ]
[ "$(git rev-parse "${APPROVED_HEAD}^{tree}")" = "$APPROVED_TREE" ]
grep -q 'version = "0.2.1"' packages/crosswake-shell-core-android/build.gradle.kts

if [ "$EXECUTE" != "true" ]; then
  echo '[crosswake] OK: Android publication identity is exact; external_state_changed=false.'
  exit 0
fi

cd packages/crosswake-shell-core-android
./gradlew publishToMavenCentral --no-daemon -PcrosswakeAutomaticRelease=true
echo '[crosswake] OK: Android core 0.2.1 publication command completed for the approved exact merge.'
