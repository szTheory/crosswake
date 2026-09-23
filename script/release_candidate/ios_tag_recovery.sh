#!/usr/bin/env bash
# One-transaction repair for the approved 0.2.3 iOS mirror tag.
# This deliberately has no branch-write operation and no caller-supplied refs.
set -euo pipefail

MODE="${1:-}"
[ "$MODE" = "validate" ] || [ "$MODE" = "apply" ] || {
  echo "usage: ios_tag_recovery.sh <validate|apply>" >&2
  exit 2
}

VERSION="0.2.3"
SOURCE="4df029d3799d2db18003471019c42126878572f8"
SPLIT="424ab96ede1b92f2b751b54bce04c6e607f0f3c8"
RECEIPT="f5e91a9a10ead43306c5a55580bb07e54db199d12c6e0d629d6eb56f2766ca92"
if [ "$MODE" = "validate" ]; then
  DEFAULT_REMOTE="https://github.com/szTheory/crosswake-shell-core-ios.git"
else
  DEFAULT_REMOTE="git@github.com:szTheory/crosswake-shell-core-ios.git"
fi
REMOTE="${CROSSWAKE_IOS_TAG_RECOVERY_REMOTE:-$DEFAULT_REMOTE}"
TAG="refs/tags/v${VERSION}"
IOS_RELEASE_TAG="refs/tags/ios-core-v${VERSION}"

git cat-file -e "${SOURCE}^{commit}"
[ "$(git rev-parse "${SOURCE}^{commit}")" = "$SOURCE" ]
[ "$(git rev-parse "${IOS_RELEASE_TAG}^{commit}")" = "$SOURCE" ]
[ "$(git subtree split --prefix=packages/crosswake-shell-core-ios "$SOURCE" | tail -1)" = "$SPLIT" ]

read_refs() {
  git ls-remote "$REMOTE" refs/heads/main "$TAG"
}

refs="$(read_refs)"
main="$(printf '%s\n' "$refs" | awk '$2 == "refs/heads/main" {print $1}')"
tag="$(printf '%s\n' "$refs" | awk -v ref="$TAG" '$2 == ref {print $1}')"
[ "$main" = "$SPLIT" ] || {
  echo "[crosswake] FAIL: mirror main is not the approved 0.2.3 split; refusing tag recovery." >&2
  exit 1
}

if [ "$tag" = "$SPLIT" ]; then
  echo "[crosswake] OK: approved iOS tag already exists; mirror main remains unchanged."
  exit 0
fi

[ -z "$tag" ] || {
  echo "[crosswake] FAIL: immutable iOS v0.2.3 tag exists at a different object; refusing recovery." >&2
  exit 1
}

if [ "$MODE" = "validate" ]; then
  echo "[crosswake] RECOVERY_PENDING: v0.2.3 tag is absent; exact source, receipt, and mirror main are pinned."
  echo "[crosswake] Receipt digest: $RECEIPT"
  exit 0
fi

# Re-read immediately before the only write; lease main by requiring it remains
# exactly the approved split. The push refspec contains only the immutable tag.
before="$(read_refs)"
before_main="$(printf '%s\n' "$before" | awk '$2 == "refs/heads/main" {print $1}')"
before_tag="$(printf '%s\n' "$before" | awk -v ref="$TAG" '$2 == ref {print $1}')"
[ "$before_main" = "$SPLIT" ] && [ -z "$before_tag" ]
git push --porcelain "$REMOTE" "${SPLIT}:${TAG}"

after="$(read_refs)"
after_main="$(printf '%s\n' "$after" | awk '$2 == "refs/heads/main" {print $1}')"
after_tag="$(printf '%s\n' "$after" | awk -v ref="$TAG" '$2 == ref {print $1}')"
[ "$after_main" = "$SPLIT" ] && [ "$after_tag" = "$SPLIT" ]
echo "[crosswake] OK: repaired refs/tags/v${VERSION}; refs/heads/main stayed ${SPLIT}."
