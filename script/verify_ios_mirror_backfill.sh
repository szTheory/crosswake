#!/usr/bin/env bash
# verify_ios_mirror_backfill.sh - verify or backfill the SwiftPM mirror tag.
#
# Usage:
#   script/verify_ios_mirror_backfill.sh --version 0.2.0 --ref refs/tags/ios-core-v0.2.0
#   script/verify_ios_mirror_backfill.sh --version 0.2.0 --ref refs/tags/ios-core-v0.2.0 --apply
#
# Verification is the default. Public mirror mutation requires --apply. This
# script authenticates over SSH using a deploy key (MIRROR_DEPLOY_KEY) with
# write access to szTheory/crosswake-shell-core-ios; the calling workflow
# loads the key into an ssh-agent before this script runs, so auth is
# transparent here - this script never handles key material directly.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

VERSION=""
SOURCE_REF=""
APPLY=0
UPDATE_MAIN=0
IOS_PATH="packages/crosswake-shell-core-ios"
ANDROID_PATH="packages/crosswake-shell-core-android"
MIRROR_REPO="szTheory/crosswake-shell-core-ios"
DEFAULT_MIRROR_REMOTE="git@github.com:szTheory/crosswake-shell-core-ios.git"
MIRROR_REMOTE="${CROSSWAKE_IOS_BACKFILL_MIRROR_REMOTE:-$DEFAULT_MIRROR_REMOTE}"
RELEASE_REPO="${CROSSWAKE_IOS_BACKFILL_RELEASE_REPO:-$REPO_ROOT}"
SPLIT_SHA="${CROSSWAKE_IOS_BACKFILL_SPLIT_SHA:-}"
WORKTREE_DIR=""

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

cleanup() {
  if [ -n "$WORKTREE_DIR" ] && [ -d "$WORKTREE_DIR" ]; then
    git -C "$RELEASE_REPO" worktree remove "$WORKTREE_DIR" --force >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

usage() {
  cat <<EOF
Usage: $0 --version VERSION --ref refs/tags/ios-core-vVERSION [--apply] [--update-main]

Default mode verifies and reports only. --apply is required before pushing
refs/tags/vVERSION to ${MIRROR_REPO}.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
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

validate_inputs() {
  if ! printf "%s" "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z._-]+)?$'; then
    fail "VERSION '${VERSION:-<empty>}' is not a valid semver string." "Pass the exact Release Please version, for example --version 0.2.0."
  fi

  case "$SOURCE_REF" in
    ""|main|master|HEAD|heads/*|refs/heads/*|v*|[0-9]*)
      fail "source ref '${SOURCE_REF:-<empty>}' is mutable, current-HEAD-shaped, or bare-version-shaped." "Use the Release Please component ref: refs/tags/ios-core-v${VERSION}."
      ;;
  esac

  expected_ref="refs/tags/ios-core-v${VERSION}"
  if [ "$SOURCE_REF" != "$expected_ref" ]; then
    fail "source ref '${SOURCE_REF}' is not the expected iOS Release Please component ref." "Use --ref ${expected_ref}; do not backfill from main, HEAD, or a bare v${VERSION} tag."
  fi
}

rev_parse_ref() {
  local ref="$1"
  git -C "$RELEASE_REPO" rev-parse "${ref}^{commit}" 2>/dev/null
}

verify_release_refs() {
  release_sha="$(rev_parse_ref "$SOURCE_REF")" || fail "release ref '${SOURCE_REF}' is not present in ${RELEASE_REPO}." "Fetch tags and retry with refs/tags/ios-core-v${VERSION}."
  hex_sha="$(rev_parse_ref "refs/tags/hex-v${VERSION}")" || fail "missing refs/tags/hex-v${VERSION}." "Fetch Release Please component tags before backfill."
  android_sha="$(rev_parse_ref "refs/tags/android-core-v${VERSION}")" || fail "missing refs/tags/android-core-v${VERSION}." "Fetch Release Please component tags before backfill."

  if [ "$hex_sha" != "$release_sha" ] || [ "$android_sha" != "$release_sha" ]; then
    fail "Release Please component tags do not point to the same release commit." "Confirm refs/tags/hex-v${VERSION}, refs/tags/ios-core-v${VERSION}, and refs/tags/android-core-v${VERSION} before touching the SwiftPM mirror."
  fi

  ok "release refs hex-v${VERSION}, ios-core-v${VERSION}, and android-core-v${VERSION} agree at ${release_sha}."
}

verify_manifest_versions() {
  manifest_path="${RELEASE_REPO}/.release-please-manifest.json"
  if [ ! -f "$manifest_path" ]; then
    fail ".release-please-manifest.json is missing." "Check out the release repository before running mirror backfill."
  fi

  python3 - "$manifest_path" "$VERSION" <<'PYEOF' || fail ".release-please-manifest.json does not declare lockstep root/iOS/Android versions." "Confirm ., packages/crosswake-shell-core-ios, and packages/crosswake-shell-core-android all equal the requested version."
import json
import sys

manifest_path, version = sys.argv[1], sys.argv[2]
with open(manifest_path, "r", encoding="utf-8") as handle:
    manifest = json.load(handle)

required = [".", "packages/crosswake-shell-core-ios", "packages/crosswake-shell-core-android"]
missing = [path for path in required if manifest.get(path) != version]
if missing:
    print(",".join(missing), file=sys.stderr)
    sys.exit(1)
PYEOF

  ok "manifest declares root, iOS core, and Android core at ${VERSION}."
}

probe_override() {
  local value="$1"
  case "$value" in
    1|true|TRUE|yes|YES) return 0 ;;
    0|false|FALSE|no|NO) return 1 ;;
    *) return 2 ;;
  esac
}

verify_live_registries() {
  if [ -n "${CROSSWAKE_IOS_BACKFILL_HEX_LIVE:-}" ]; then
    probe_override "$CROSSWAKE_IOS_BACKFILL_HEX_LIVE" || fail "Hex crosswake ${VERSION} is not proven live." "Do not backfill SwiftPM until root Hex is live."
  else
    code="$(curl -sS -o /dev/null -w "%{http_code}" "https://hex.pm/api/packages/crosswake/releases/${VERSION}" || true)"
    [ "$code" = "200" ] || fail "Hex crosswake ${VERSION} is not live (HTTP ${code})." "Do not backfill SwiftPM until root Hex is live."
  fi

  if [ -n "${CROSSWAKE_IOS_BACKFILL_MAVEN_LIVE:-}" ]; then
    probe_override "$CROSSWAKE_IOS_BACKFILL_MAVEN_LIVE" || fail "Android Maven ${VERSION} is not proven live." "Do not backfill SwiftPM until Android Maven lockstep state is live."
  else
    maven_url="https://repo1.maven.org/maven2/io/github/sztheory/crosswake-shell-core-android/${VERSION}/crosswake-shell-core-android-${VERSION}.pom"
    code="$(curl -sS -o /dev/null -w "%{http_code}" "$maven_url" || true)"
    [ "$code" = "200" ] || fail "Android Maven ${VERSION} is not live (HTTP ${code})." "Do not backfill SwiftPM until Android Maven lockstep state is live."
  fi

  ok "root Hex and Android Maven live-state checks passed for ${VERSION}."
}

compute_split_sha() {
  if [ -n "$SPLIT_SHA" ]; then
    ok "using provided iOS split SHA ${SPLIT_SHA}."
    return
  fi

  if ! command -v splitsh-lite >/dev/null 2>&1; then
    fail "splitsh-lite v1.0.1 is required to compute the iOS split SHA." "Install https://github.com/splitsh/lite/releases/download/v1.0.1/lite_linux_amd64.tar.gz, then retry."
  fi

  WORKTREE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/crosswake-ios-backfill.XXXXXX")"
  git -C "$RELEASE_REPO" worktree add --detach "$WORKTREE_DIR" "$SOURCE_REF" >/dev/null
  SPLIT_SHA="$(cd "$WORKTREE_DIR" && splitsh-lite --prefix="$IOS_PATH")"
  ok "computed ${IOS_PATH} split with splitsh-lite v1.0.1: ${SPLIT_SHA}."
}

mirror_push_remote() {
  printf "%s" "$MIRROR_REMOTE"
}

mirror_tag_sha() {
  git ls-remote "$(mirror_push_remote)" "refs/tags/v${VERSION}" 2>/dev/null | awk '{print $1}' | head -1 || true
}

verify_or_apply_mirror() {
  local push_remote
  local tag_sha

  push_remote="$(mirror_push_remote)"
  tag_sha="$(mirror_tag_sha)"

  log "package=ios-core version=${VERSION} release_ref=${SOURCE_REF} expected_split_sha=${SPLIT_SHA}"

  if [ -n "$tag_sha" ]; then
    if [ "$tag_sha" = "$SPLIT_SHA" ]; then
      ok "SwiftPM mirror refs/tags/v${VERSION} already points at ${SPLIT_SHA}; no push needed."
      return
    fi

    fail "SwiftPM mirror refs/tags/v${VERSION} points at ${tag_sha}, expected ${SPLIT_SHA}." "Do not delete or move the public SwiftPM tag automatically. Inspect ${MIRROR_REPO} and decide deliberately."
  fi

  if ! git -C "$RELEASE_REPO" push --dry-run --porcelain "$push_remote" "${SPLIT_SHA}:refs/tags/v${VERSION}" >/dev/null 2>&1; then
    fail "dry-run push to ${MIRROR_REPO} failed; MIRROR_DEPLOY_KEY may be missing, unauthorized, or lack write access to ${MIRROR_REPO}." "Confirm the MIRROR_DEPLOY_KEY secret is set and registered as a write deploy key on ${MIRROR_REPO}, then retry."
  fi
  ok "dry-run push to ${MIRROR_REPO} succeeded; MIRROR_DEPLOY_KEY has WRITE scope."

  if [ "$APPLY" -ne 1 ]; then
    ok "SwiftPM mirror refs/tags/v${VERSION} is absent; verification-only mode made no changes."
    log "Next action: run $0 --version ${VERSION} --ref ${SOURCE_REF} --apply to push the tag using MIRROR_DEPLOY_KEY."
    return
  fi

  git -C "$RELEASE_REPO" push --dry-run --porcelain "$push_remote" "${SPLIT_SHA}:refs/tags/v${VERSION}" >/dev/null
  git -C "$RELEASE_REPO" push --porcelain "$push_remote" "${SPLIT_SHA}:refs/tags/v${VERSION}"
  ok "pushed SwiftPM mirror refs/tags/v${VERSION} at ${SPLIT_SHA}."

  if [ "$UPDATE_MAIN" -eq 1 ]; then
    current_main="$(git ls-remote "$push_remote" "refs/heads/main" | awk '{print $1}' | head -1 || true)"
    if [ -n "$current_main" ]; then
      if ! git -C "$RELEASE_REPO" cat-file -e "${current_main}^{commit}" 2>/dev/null; then
        log "mirror main (${current_main}) is not a known object in this repository - cannot prove ancestry either way."
        log "This is expected exactly once, for the one-time re-baseline (D-08). If this is not that operation, stop and investigate."
      elif ! git -C "$RELEASE_REPO" merge-base --is-ancestor "$current_main" "$SPLIT_SHA" 2>/dev/null; then
        fail "mirror main has commits not reachable from expected split SHA (both objects are known locally)." "Do not realign main until mirror-only commit evidence is reviewed."
      fi
    fi

    git -C "$RELEASE_REPO" push --porcelain \
      --force-with-lease="refs/heads/main:${current_main}" \
      "$push_remote" "${SPLIT_SHA}:refs/heads/main"
    ok "updated mirror main to ${SPLIT_SHA} with --force-with-lease."
  fi
}

validate_inputs
verify_release_refs
verify_manifest_versions
verify_live_registries
compute_split_sha
verify_or_apply_mirror
