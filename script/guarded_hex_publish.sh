#!/usr/bin/env bash
# guarded_hex_publish.sh — guarded Hex publish helper for release automation.
#
# Usage:
#   bash script/guarded_hex_publish.sh PACKAGE VERSION [RELEASE_REF]
#
# The helper is shared by automatic Release Please publish jobs and the manual
# exact-ref Hex recovery workflow. It verifies package/version identity before
# doing any irreversible registry mutation, treats an exact already-live Hex
# release as success, otherwise runs the package-specific mix bar, dry-run,
# publish, and exact release poll.

set -euo pipefail

PACKAGE="${1:-}"
VERSION="${2:-}"
RELEASE_REF="${3:-unknown-ref}"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
CHECKED_SHA=$(git -C "$REPO_ROOT" rev-parse HEAD)

WORKDIR=""
VERSION_FILE=""
RELEASE_ENV=""
TEST_CMD=""
PUBLISH_CMD=""
TEMP_FILES=()

log() {
  echo "[crosswake] $*"
}

ok() {
  echo "[crosswake] OK: $*"
}

emit_outputs() {
  local state="$1"
  local url="$2"

  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    {
      echo "package=${PACKAGE}"
      echo "version=${VERSION}"
      echo "publish_state=${state}"
      echo "hex_release_url=${url}"
      echo "checked_sha=${CHECKED_SHA}"
    } >> "$GITHUB_OUTPUT"
  fi
}

fail() {
  local message="$1"
  local next_action="${2:-Stop and inspect the package, version, release ref, and registry state before retrying.}"
  local url="https://hex.pm/packages/${PACKAGE:-unknown}/versions/${VERSION:-unknown}"

  echo "[crosswake] FAIL: ${message}"
  log "What to do next: ${next_action}"
  emit_outputs "failed" "$url"
  exit 1
}

package_config() {
  case "$PACKAGE" in
    crosswake)
      WORKDIR="."
      VERSION_FILE="mix.exs"
      RELEASE_ENV=""
      TEST_CMD="mix test --exclude requires_example_host"
      PUBLISH_CMD="mix hex.publish --yes"
      ;;
    crosswake_rulestead)
      WORKDIR="packages/crosswake_rulestead"
      VERSION_FILE="packages/crosswake_rulestead/mix.exs"
      RELEASE_ENV="CROSSWAKE_RELEASE=1"
      TEST_CMD="mix test"
      PUBLISH_CMD="mix hex.publish --yes"
      ;;
    crosswake_rindle)
      WORKDIR="packages/crosswake_rindle"
      VERSION_FILE="packages/crosswake_rindle/mix.exs"
      RELEASE_ENV="CROSSWAKE_RELEASE=1"
      TEST_CMD="mix test"
      PUBLISH_CMD="mix hex.publish --yes"
      ;;
    crosswake_sigra)
      WORKDIR="packages/crosswake_sigra"
      VERSION_FILE="packages/crosswake_sigra/mix.exs"
      RELEASE_ENV="CROSSWAKE_RELEASE=1"
      TEST_CMD="mix test"
      PUBLISH_CMD="mix hex.publish --yes"
      ;;
    crosswake_chimeway)
      WORKDIR="packages/crosswake_chimeway"
      VERSION_FILE="packages/crosswake_chimeway/mix.exs"
      RELEASE_ENV="CROSSWAKE_RELEASE=1"
      TEST_CMD="mix test"
      PUBLISH_CMD="mix hex.publish --yes"
      ;;
    crosswake_threadline)
      WORKDIR="packages/crosswake_threadline"
      VERSION_FILE="packages/crosswake_threadline/mix.exs"
      RELEASE_ENV="CROSSWAKE_RELEASE=1"
      TEST_CMD="mix test"
      PUBLISH_CMD="mix hex.publish --yes"
      ;;
    *)
      fail "unknown Hex package '${PACKAGE:-<empty>}'." "Choose one of: crosswake, crosswake_rulestead, crosswake_rindle, crosswake_sigra, crosswake_chimeway, crosswake_threadline."
      ;;
  esac
}

validate_inputs() {
  if [ -z "$PACKAGE" ]; then
    fail "PACKAGE is required as argument 1."
  fi

  if ! printf "%s" "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z._-]+)?$'; then
    fail "VERSION '${VERSION:-<empty>}' does not look like a valid semver string." "Pass the exact Release Please version output for ${PACKAGE}."
  fi
}

verify_expected_version() {
  local absolute_version_file="$REPO_ROOT/$VERSION_FILE"

  if [ ! -f "$absolute_version_file" ]; then
    fail "version file not found for ${PACKAGE}: ${VERSION_FILE}."
  fi

  if ! grep -q "@version \"${VERSION}\"" "$absolute_version_file"; then
    fail "${PACKAGE} expected version ${VERSION}, but ${VERSION_FILE} does not declare that @version." "Check out the exact release ref and retry recovery with the matching version."
  fi

  ok "${PACKAGE} version file ${VERSION_FILE} declares ${VERSION}."
}

hex_release_state() {
  local body_file="$1"
  local code_file="$2"
  local url="https://hex.pm/api/packages/${PACKAGE}/releases/${VERSION}"
  local code

  code=$(curl -sS -o "$body_file" -w "%{http_code}" "$url" || true)
  printf "%s" "$code" > "$code_file"
}

live_release_version() {
  local body_file="$1"

  python3 - "$body_file" <<'PYEOF'
import json
import sys

try:
    with open(sys.argv[1], "r", encoding="utf-8") as handle:
        payload = json.load(handle)
except Exception:
    sys.exit(2)

version = payload.get("version")
if not isinstance(version, str):
    sys.exit(3)

print(version)
PYEOF
}

run_with_release_env() {
  if [ -n "$RELEASE_ENV" ]; then
    export "$RELEASE_ENV"
  fi
  "$@"
}

run_without_release_env() {
  env -u CROSSWAKE_RELEASE "$@"
}

cleanup_temp_files() {
  if [ "${#TEMP_FILES[@]}" -gt 0 ]; then
    rm -f "${TEMP_FILES[@]}"
  fi
}

trap cleanup_temp_files EXIT

run_mix_bar() {
  log "package=${PACKAGE} version=${VERSION} ref=${RELEASE_REF} checked_sha=${CHECKED_SHA}"
  log "registry=hex.pm state=publish-required proof=run package mix bar"

  (
    cd "$REPO_ROOT/$WORKDIR"
    # Companion proof tests exercise in-tree integration contracts, including
    # test-only core support. They must use the local path dependency. The
    # release resolver is still compiled below and used by the dry-run/publish
    # steps, so the emitted tarball remains honest about its public Hex floor.
    run_without_release_env mix deps.get
    run_without_release_env mix compile --warnings-as-errors
    run_without_release_env bash -lc "$TEST_CMD"

    run_with_release_env mix deps.get
    run_with_release_env mix compile --warnings-as-errors
  )
}

dry_run_publish() {
  if [ -z "${HEX_API_KEY:-}" ]; then
    fail "HEX_API_KEY is required because ${PACKAGE} ${VERSION} is not live on Hex.pm." "Configure the HEX_API_KEY repository secret or run recovery from an environment with publish rights."
  fi

  log "registry=hex.pm state=dry-run package=${PACKAGE} version=${VERSION}"
  (
    cd "$REPO_ROOT/$WORKDIR"
    run_with_release_env bash -lc "HEX_API_KEY=\"${HEX_API_KEY}\" mix hex.publish --dry-run --yes"
  )
}

publish_package() {
  log "registry=hex.pm state=publishing package=${PACKAGE} version=${VERSION}"
  (
    cd "$REPO_ROOT/$WORKDIR"
    run_with_release_env bash -lc "HEX_API_KEY=\"${HEX_API_KEY}\" ${PUBLISH_CMD}"
  )
}

poll_hex_release() {
  local max_attempts="${MAX_ATTEMPTS:-36}"
  local delay="${DELAY:-10}"
  local body_file
  local code_file
  local code
  local seen_version
  local url="https://hex.pm/packages/${PACKAGE}/versions/${VERSION}"

  body_file=$(mktemp "${TMPDIR:-/tmp}/crosswake-hex-release-XXXXXX.json")
  code_file=$(mktemp "${TMPDIR:-/tmp}/crosswake-hex-code-XXXXXX")
  TEMP_FILES+=("$body_file" "$code_file")

  for i in $(seq 1 "$max_attempts"); do
    hex_release_state "$body_file" "$code_file"
    code=$(cat "$code_file")

    if [ "$code" = "200" ]; then
      if seen_version=$(live_release_version "$body_file"); then
        if [ "$seen_version" = "$VERSION" ]; then
          ok "${PACKAGE} ${VERSION} is live on Hex.pm after publish. Proof may continue."
          emit_outputs "published" "$url"
          return 0
        fi
      fi
    fi

    log "waiting for Hex propagation for ${PACKAGE} ${VERSION}... (${i}/${max_attempts})"
    sleep "$delay"
  done

  fail "timed out waiting for ${PACKAGE} ${VERSION} to appear on Hex.pm." "Check Hex.pm status and this run's publish logs before retrying exact-ref recovery."
}

main() {
  validate_inputs
  package_config
  verify_expected_version

  local body_file
  local code_file
  local code
  local seen_version
  local url="https://hex.pm/packages/${PACKAGE}/versions/${VERSION}"

  body_file=$(mktemp "${TMPDIR:-/tmp}/crosswake-hex-preflight-XXXXXX.json")
  code_file=$(mktemp "${TMPDIR:-/tmp}/crosswake-hex-code-XXXXXX")
  TEMP_FILES+=("$body_file" "$code_file")

  hex_release_state "$body_file" "$code_file"
  code=$(cat "$code_file")

  case "$code" in
    200)
      if ! seen_version=$(live_release_version "$body_file"); then
        fail "Hex.pm returned 200 for ${PACKAGE} ${VERSION}, but JSON identity could not be parsed." "Inspect https://hex.pm/api/packages/${PACKAGE}/releases/${VERSION} before retrying."
      fi

      if [ "$seen_version" != "$VERSION" ]; then
        fail "Hex.pm returned ${seen_version} for ${PACKAGE}, not expected ${VERSION}." "Stop and inspect the package/version identity before continuing."
      fi

      ok "${PACKAGE} ${VERSION} is already live on Hex.pm; no publish attempted. Continuing to proof."
      log "package=${PACKAGE} version=${VERSION} ref=${RELEASE_REF} checked_sha=${CHECKED_SHA} registry=hex.pm live_artifact=${url} proof=continue"
      emit_outputs "already_live" "$url"
      ;;
    404)
      ok "${PACKAGE} ${VERSION} is not live on Hex.pm yet; publish is required for this released package."
      run_mix_bar
      dry_run_publish
      publish_package
      poll_hex_release
      ;;
    *)
      fail "Hex.pm release preflight returned HTTP ${code} for ${PACKAGE} ${VERSION}." "Retry after confirming Hex.pm status; do not publish until registry identity can be checked."
      ;;
  esac
}

main "$@"
