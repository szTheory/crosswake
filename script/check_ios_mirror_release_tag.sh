#!/usr/bin/env bash
# check_ios_mirror_release_tag.sh - post-publish SwiftPM mirror tag equality check (Phase 199 SC3).
#
# THE INVARIANT, in one sentence:
#   After release V is published, the SwiftPM mirror tag v<V> exists, its root tree is exactly the
#   released iOS package tree (packages/crosswake-shell-core-ios at refs/tags/ios-core-v<V>), and
#   v<V> is the newest vX.Y.Z tag on the mirror.
#
# WHY TREE EQUALITY: the mirror is a subtree split, so commit SHAs differ by design. The root tree
#   id of the mirror tag equals the tree id of the package directory in the source tag exactly when
#   the file bytes and modes match. Tag existence alone, or a commit SHA, proves nothing about what
#   adopters resolve (parity with check_ios_mirror_parity.sh stops at tag existence).
#
# WHY THE NEWEST-TAG RULE: this is a post-publish check for the release just published. Asking it
#   about an older version fails by design (reason=newer_mirror_tag), which is also its negative control.
#
# Usage:
#   script/check_ios_mirror_release_tag.sh --version X.Y.Z
#
# Verdict line (always the LAST line printed):
#   exit 0  verdict=PASS
#   exit 1  verdict=FAIL reason=<source_tag_missing|linked_tag_mismatch|manifest_version_mismatch|
#                                source_tree_missing|mirror_tag_missing|tree_mismatch|newer_mirror_tag>
#   exit 2  verdict=ERROR reason=<usage|tool_unavailable>
#   exit 3  verdict=UNVERIFIED reason=<mirror_unreachable|mirror_fetch_failed>
# An unreachable mirror is an UNKNOWN, never a missing tag and never a pass.
#
# Test seams (environment only):
#   CROSSWAKE_MIRROR_TAG_REMOTE         mirror remote (path or URL); default the public mirror
#   CROSSWAKE_MIRROR_TAG_RELEASE_REPO   repository whose hex-v/ios-core-v tags are read; default repo root
#   CROSSWAKE_MIRROR_TAG_RETRY_SLEEP    seconds between ls-remote attempts (default 2)
#
# TRANSPORT: unauthenticated read-only git (ls-remote, then one shallow tag fetch into a throwaway
#   bare repository). No credential is used and no remote write of any kind exists in this file.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DEFAULT_MIRROR_REMOTE="https://github.com/szTheory/crosswake-shell-core-ios.git"
MIRROR_REMOTE="${CROSSWAKE_MIRROR_TAG_REMOTE:-$DEFAULT_MIRROR_REMOTE}"
RELEASE_REPO="${CROSSWAKE_MIRROR_TAG_RELEASE_REPO:-$REPO_ROOT}"
RETRY_SLEEP="${CROSSWAKE_MIRROR_TAG_RETRY_SLEEP:-2}"
IOS_PACKAGE_PATH="packages/crosswake-shell-core-ios"

export GIT_TERMINAL_PROMPT=0

VERSION=""
FIELDS=""

usage() {
  echo "usage: check_ios_mirror_release_tag.sh --version X.Y.Z"
  echo "mirror-tag: verdict=ERROR reason=usage"
  exit 2
}

if [ "$#" -ne 2 ] || [ "$1" != "--version" ]; then
  usage
fi
printf '%s' "$2" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || usage
VERSION="$2"

# Printed remote never carries userinfo (token or password in a URL).
display_remote() {
  printf '%s' "$MIRROR_REMOTE" | sed 's#^\([A-Za-z][A-Za-z0-9+.-]*://\)[^/@]*@#\1#'
}

add_field() {
  FIELDS="${FIELDS} $*"
}

# stop <exit> <verdict> <reason> <next action>
# Prints one next-action line, then the verdict line (last) carrying every field known so far.
stop() {
  local code="$1" verdict="$2" reason="$3" next="$4"
  echo "[crosswake] What to do next: ${next}"
  echo "mirror-tag: version ${VERSION}${FIELDS} verdict=${verdict} reason=${reason}"
  exit "$code"
}

if ! command -v git >/dev/null 2>&1; then
  stop 2 ERROR tool_unavailable "Install git and re-run script/check_ios_mirror_release_tag.sh."
fi

echo "mirror-tag: remote $(display_remote)"

SOURCE_TAG="ios-core-v${VERSION}"
HEX_TAG="hex-v${VERSION}"
MIRROR_TAG="v${VERSION}"

# ---- 1. Release side (local reads only) ------------------------------------------------------

IOS_COMMIT=""
HEX_COMMIT=""
if ! IOS_COMMIT="$(git -C "$RELEASE_REPO" rev-parse -q --verify "refs/tags/${SOURCE_TAG}^{commit}" 2>/dev/null)"; then
  stop 1 FAIL source_tag_missing "refs/tags/${SOURCE_TAG} is not in the release repository; run git fetch --tags origin and re-run."
fi
if ! HEX_COMMIT="$(git -C "$RELEASE_REPO" rev-parse -q --verify "refs/tags/${HEX_TAG}^{commit}" 2>/dev/null)"; then
  stop 1 FAIL source_tag_missing "refs/tags/${HEX_TAG} is not in the release repository; run git fetch --tags origin and re-run."
fi
if [ "$IOS_COMMIT" != "$HEX_COMMIT" ]; then
  stop 1 FAIL linked_tag_mismatch "${HEX_TAG} and ${SOURCE_TAG} peel to different commits; the linked source tags must name one release commit. Inspect both tags before anything else."
fi

MANIFEST=""
MANIFEST="$(git -C "$RELEASE_REPO" show "${IOS_COMMIT}:.release-please-manifest.json" 2>/dev/null)" || MANIFEST=""
MANIFEST_ROOT="$(printf '%s\n' "$MANIFEST" | sed -n 's/^[[:space:]]*"\.":[[:space:]]*"\([^"]*\)".*$/\1/p' | head -n 1)"
MANIFEST_IOS="$(printf '%s\n' "$MANIFEST" | sed -n 's#^[[:space:]]*"packages/crosswake-shell-core-ios":[[:space:]]*"\([^"]*\)".*$#\1#p' | head -n 1)"
if [ "$MANIFEST_ROOT" != "$VERSION" ] || [ "$MANIFEST_IOS" != "$VERSION" ]; then
  stop 1 FAIL manifest_version_mismatch "the release manifest at ${SOURCE_TAG} reads root=${MANIFEST_ROOT:-none} ios=${MANIFEST_IOS:-none}, not ${VERSION}; inspect .release-please-manifest.json at that tag."
fi

SOURCE_TREE=""
if ! SOURCE_TREE="$(git -C "$RELEASE_REPO" rev-parse -q --verify "refs/tags/${SOURCE_TAG}:${IOS_PACKAGE_PATH}" 2>/dev/null)"; then
  stop 1 FAIL source_tree_missing "${IOS_PACKAGE_PATH} does not exist at ${SOURCE_TAG}; inspect the released tag."
fi
add_field "source_tag ${SOURCE_TAG} source_tree ${SOURCE_TREE:0:12}"

# ---- 2. Mirror side (unauthenticated) --------------------------------------------------------

# The result lands in a global so exhaustion can stop in the main shell (a $(...) capture would
# only exit the subshell and swallow the verdict).
MIRROR_TAGS_OUTPUT=""
read_mirror_tags() {
  local attempt output=""
  for attempt in 1 2 3; do
    if output="$(git -c core.askPass= ls-remote --tags "$MIRROR_REMOTE" 2>&1)"; then
      MIRROR_TAGS_OUTPUT="$output"
      return 0
    fi
    echo "[crosswake] attempt ${attempt}/3: could not reach the mirror at $(display_remote)"
    if [ "$attempt" -eq 3 ]; then
      stop 3 UNVERIFIED mirror_unreachable "This is an UNKNOWN, not a missing tag. Check network access and re-run script/check_ios_mirror_release_tag.sh --version ${VERSION}."
    fi
    sleep "$RETRY_SLEEP"
  done
}
read_mirror_tags

# Fixed-prefix parsing of `<sha><TAB>refs/tags/<name>`; no eval, no remote text in a command.
MIRROR_TAG_SHA="$(printf '%s\n' "$MIRROR_TAGS_OUTPUT" | awk -v ref="refs/tags/${MIRROR_TAG}" '$2 == ref {print $1; exit}')"
if [ -z "$MIRROR_TAG_SHA" ]; then
  stop 1 FAIL mirror_tag_missing "the mirror has no refs/tags/${MIRROR_TAG}; the iOS mirror publish did not create it. Read the publish run before anything else."
fi

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/crosswake-mirror-tag.XXXXXX")"
trap 'rm -rf -- "$WORK_DIR"' EXIT

git init -q --bare "$WORK_DIR/mirror.git"
if ! git -C "$WORK_DIR/mirror.git" -c core.askPass= fetch -q --depth 1 --no-tags "$MIRROR_REMOTE" \
  "refs/tags/${MIRROR_TAG}:refs/tags/${MIRROR_TAG}" >"$WORK_DIR/fetch.log" 2>&1; then
  stop 3 UNVERIFIED mirror_fetch_failed "the mirror lists ${MIRROR_TAG} but it could not be fetched; this is an UNKNOWN. Re-run the check later."
fi

MIRROR_COMMIT="$(git -C "$WORK_DIR/mirror.git" rev-parse -q --verify "refs/tags/${MIRROR_TAG}^{commit}" 2>/dev/null)" || MIRROR_COMMIT=""
MIRROR_TREE="$(git -C "$WORK_DIR/mirror.git" rev-parse -q --verify "refs/tags/${MIRROR_TAG}^{tree}" 2>/dev/null)" || MIRROR_TREE=""
if [ -z "$MIRROR_COMMIT" ] || [ -z "$MIRROR_TREE" ]; then
  stop 3 UNVERIFIED mirror_fetch_failed "the fetched ${MIRROR_TAG} has no readable commit or tree; this is an UNKNOWN."
fi
add_field "mirror_tag ${MIRROR_TAG} mirror_commit ${MIRROR_COMMIT:0:12} mirror_tree ${MIRROR_TREE:0:12}"

if [ "$MIRROR_TREE" != "$SOURCE_TREE" ]; then
  stop 1 FAIL tree_mismatch "the mirror ${MIRROR_TAG} tree differs from ${IOS_PACKAGE_PATH} at ${SOURCE_TAG}; adopters would resolve different files than were released."
fi

# ---- 3. Newest-tag rule ----------------------------------------------------------------------

NEWEST="$(printf '%s\n' "$MIRROR_TAGS_OUTPUT" \
  | sed -n 's#^.*[[:space:]]refs/tags/v##p' \
  | sed 's#\^{}$##' \
  | awk '/^[0-9]+\.[0-9]+\.[0-9]+$/' \
  | sort -t. -k1,1n -k2,2n -k3,3n -u \
  | tail -n 1)"
add_field "newest v${NEWEST}"

if [ "$NEWEST" != "$VERSION" ]; then
  stop 1 FAIL newer_mirror_tag "the mirror already carries v${NEWEST}, newer than ${MIRROR_TAG}; this check is for the release just published."
fi

echo "mirror-tag: version ${VERSION}${FIELDS} verdict=PASS"
exit 0
