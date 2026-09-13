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
MODE="observe"
PHASE168_MERGE_OID="b780a19863936619394087f1ffd384f1dca17c93"
PHASE168_APPROVED_HEAD="1051ab90cf75e918c6f596f84578ac77eadf45af"
PHASE168_APPROVED_TREE="ecf63228243bfe7c2d6a377be996aa374b31d91f"
PHASE168_CANDIDATE_RECEIPT="359ef8a5257b54e472a2328ce3ae722222506527312b3805467d643bb8666c78"
PUBLIC_POM="https://repo1.maven.org/maven2/io/github/sztheory/crosswake-shell-core-android/0.2.1/crosswake-shell-core-android-0.2.1.pom"

usage() {
  echo "usage: android_publication.sh --version 0.2.1 --ref <merge-sha> --approved-head <sha> --approved-tree <tree> --candidate-receipt <sha256> [--execute|--recover]" >&2
  exit 2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --version) [ "$#" -ge 2 ] || usage; VERSION="$2"; shift 2 ;;
    --ref) [ "$#" -ge 2 ] || usage; SOURCE_REF="$2"; shift 2 ;;
    --approved-head) [ "$#" -ge 2 ] || usage; APPROVED_HEAD="$2"; shift 2 ;;
    --approved-tree) [ "$#" -ge 2 ] || usage; APPROVED_TREE="$2"; shift 2 ;;
    --candidate-receipt) [ "$#" -ge 2 ] || usage; CANDIDATE_RECEIPT="$2"; shift 2 ;;
    --execute) [ "$MODE" = "observe" ] || usage; MODE="publish"; shift ;;
    --recover) [ "$MODE" = "observe" ] || usage; MODE="recovery"; shift ;;
    *) usage ;;
  esac
done

[ "$VERSION" = "0.2.1" ] || usage
printf '%s' "$SOURCE_REF$APPROVED_HEAD$APPROVED_TREE" | grep -Eq '^[0-9a-f]{120}$' || usage
printf '%s' "$CANDIDATE_RECEIPT" | grep -Eq '^[0-9a-f]{64}$' || usage
[ "$SOURCE_REF" = "$PHASE168_MERGE_OID" ]
[ "$APPROVED_HEAD" = "$PHASE168_APPROVED_HEAD" ]
[ "$APPROVED_TREE" = "$PHASE168_APPROVED_TREE" ]
[ "$CANDIDATE_RECEIPT" = "$PHASE168_CANDIDATE_RECEIPT" ]

cd "$REPO_ROOT"
[ "$(git rev-parse HEAD)" = "$SOURCE_REF" ]
parent_line=$(git rev-list --parents -n 1 "$SOURCE_REF")
[ "$(printf '%s\n' "$parent_line" | awk '{print NF}')" -eq 3 ]
[ "$(printf '%s\n' "$parent_line" | awk '{print $3}')" = "$APPROVED_HEAD" ]
[ "$(git rev-parse "${SOURCE_REF}^{tree}")" = "$APPROVED_TREE" ]
[ "$(git rev-parse "${APPROVED_HEAD}^{tree}")" = "$APPROVED_TREE" ]
grep -q 'version = "0.2.1"' packages/crosswake-shell-core-android/build.gradle.kts

if [ "$MODE" = "observe" ]; then
  echo '[crosswake] OK: Android publication identity is exact; external_state_changed=false.'
  exit 0
fi

if [ "$MODE" = "recovery" ]; then
  public_status=$(curl -sS -o /dev/null -w '%{http_code}' "$PUBLIC_POM" || true)

  case "$public_status" in
    200)
      echo '[crosswake] OK: Android core 0.2.1 is already public; exact-ref recovery is complete.'
      exit 0
      ;;
    404) ;;
    *)
      echo "[crosswake] FAIL: Maven Central returned unexpected status ${public_status}; publication was not attempted." >&2
      exit 1
      ;;
  esac
fi

cd packages/crosswake-shell-core-android
./gradlew publishToMavenCentral --no-daemon -PcrosswakeAutomaticRelease=true

if [ "$MODE" = "recovery" ]; then
  public_status=""
  for _attempt in $(seq 1 60); do
    public_status=$(curl -sS -o /dev/null -w '%{http_code}' "$PUBLIC_POM" || true)
    case "$public_status" in
      200) break ;;
      404) sleep 15 ;;
      *)
        echo "[crosswake] FAIL: Maven Central returned unexpected status ${public_status} after recovery." >&2
        exit 1
        ;;
    esac
  done
  [ "$public_status" = "200" ] || {
    echo '[crosswake] FAIL: exact Android core 0.2.1 POM did not become public within the bounded recovery window.' >&2
    exit 1
  }
fi

echo "[crosswake] OK: Android core 0.2.1 ${MODE} command completed for the approved exact merge."
