#!/usr/bin/env bash
# check_ios_mirror_parity.sh - merge-blocking SwiftPM mirror parity gate (D-16).
#
# THE INVARIANT, in one sentence:
#   For every `refs/tags/ios-core-vX` released in THIS repo, `refs/tags/vX` must
#   exist on szTheory/crosswake-shell-core-ios.
#
# WHY THIS EXISTS:
#   `publish-ios-core` hard-failed for three months and nobody saw it, because a
#   post-merge Actions run has no persistence and no inbox. Redness was never the
#   variable; where red LANDS is. This lane compares the mirror's ACTUAL remote
#   state against locally-computable output on EVERY PR, so drift turns the merge
#   button red instead of scrolling past in a run log. It also catches drift a
#   release-time guard structurally cannot see: a manual force-push, a tag
#   deletion, a half-finished backfill.
#
# ⚠️ DEADLOCK TRAP - this gate keys on RELEASED `ios-core-v*` GIT TAGS, never on
#   the release-please version manifest. That manifest bumps to X inside the
#   Release PR, BEFORE the tag and the publish exist - so a manifest-keyed gate
#   would ask "does the mirror have vX?" on the Release PR's own commit, before X
#   is released anywhere, and block that PR forever. Keying on released tags is
#   deadlock-free: on the Release PR commit no new ios-core-v* tag exists yet, so
#   this re-validates the PREVIOUS release's parity (already green), and the new
#   tag only appears after merge - exactly when publish-ios-core pushes the
#   matching mirror tag. The absence of the manifest filename anywhere in this
#   file is asserted by the phase153 proof test - structural, not aspirational.
#
# ONE-DIRECTIONAL: a mirror tag this repo never released is NOT a violation. The
#   invariant says nothing about the reverse direction.
#
# TAG-EXISTENCE ONLY: no splitsh-SHA-identity comparison. A `--deep` mode would
#   require running the subtree split on every PR, destroying the sub-second
#   hermetic property that makes this lane safely merge-blocking. Left as a
#   documented future flag.
#
# TRANSPORT: one UNAUTHENTICATED `git ls-remote` against a public repo. No
#   credential is needed and none is used, so this lane stays hermetic and
#   runnable by any contributor - and no secret can leak from it.
#
# Usage:
#   script/check_ios_mirror_parity.sh
#
# Test seams (mirroring the CROSSWAKE_IOS_BACKFILL_* pattern):
#   CROSSWAKE_IOS_PARITY_MIRROR_REMOTE  override the mirror remote (path or URL)
#   CROSSWAKE_IOS_PARITY_RELEASE_REPO   override the repo whose ios-core-v* tags are read
#   CROSSWAKE_IOS_PARITY_RETRY_SLEEP    seconds between retry attempts (default 2)
#
# REGISTRATION (out-of-band, by a maintainer, AFTER this lane goes green on main):
#   1. Merge the PR that introduces this lane.
#   2. Let merge-blocking-ios-mirror-parity go GREEN on main at least once.
#   3. DRY_RUN=0 script/register_required_checks.sh
#   Until then this lane is advisory - and advisory red is exactly what went
#   unnoticed for three months.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# The check id `release.ios_mirror_parity` is written LITERALLY into every OK/FAIL
# line below rather than interpolated from a variable, so a plain grep over this
# file proves the parser-compatible `<id> - <detail>` contract is present.
MIRROR_REPO="szTheory/crosswake-shell-core-ios"
DEFAULT_MIRROR_REMOTE="https://github.com/${MIRROR_REPO}.git"
MIRROR_REMOTE="${CROSSWAKE_IOS_PARITY_MIRROR_REMOTE:-$DEFAULT_MIRROR_REMOTE}"
RELEASE_REPO="${CROSSWAKE_IOS_PARITY_RELEASE_REPO:-$REPO_ROOT}"
RETRY_SLEEP="${CROSSWAKE_IOS_PARITY_RETRY_SLEEP:-2}"

log() {
  echo "[crosswake] $*"
}

ok() {
  echo "[crosswake] OK: $*"
}

fail() {
  local message="$1"
  # No apostrophes in this default: bash still parses quoting inside a
  # ${var:-word} default even within double quotes, so a lone ' would open a
  # single-quoted string and break the whole file at parse time.
  local next_action="${2:-Inspect the ios-core-v* tags in this repo and the ${MIRROR_REPO} tag list before retrying.}"

  echo "[crosswake] FAIL: ${message}"
  log "What to do next: ${next_action}"
  exit 1
}

# D-19: the 2am-maintainer failure block. States the stakes in ADOPTER language,
# not internal job names, and gives ONE command. The first line matches the
# `[crosswake] FAIL: <id> - <detail>` parser shape so this script is
# machine-consumable by `mix crosswake.release.status` for free.
fail_parity() {
  local versions="$1"
  local version

  for version in $versions; do
    echo "[crosswake] FAIL: release.ios_mirror_parity - SwiftPM mirror is missing refs/tags/v${version}."
    log "  released here:  refs/tags/ios-core-v${version}"
    log "  mirror state:   ${MIRROR_REPO} has no refs/tags/v${version}"
    log "  adopter impact: .package(url: \"…/crosswake-shell-core-ios\", from: \"${version}\")"
    log "                  CANNOT RESOLVE. Every iOS adopter of ${version} is broken right now."
    log "What to do next:"
    log "  gh workflow run ios-mirror-backfill.yml -f version=${version} \\"
    log "    -f release_ref=refs/tags/ios-core-v${version} -f apply=true"
  done

  log "This gate stays RED and merges stay BLOCKED until the mirror tag exists."
  exit 1
}

# Read the mirror's tags with an unauthenticated probe, retrying up to 3 times.
#
# Result lands in the global MIRROR_TAGS_OUTPUT rather than on stdout, so the
# exhaustion path can `fail` (which exits) in the MAIN shell. Capturing this via
# `$(...)` would run it in a subshell, where `exit 1` only kills the subshell and
# the failure text would be silently swallowed into the caller's variable.
#
# T-153-09: a network failure must NEVER masquerade as a missing tag. Exhaustion
# names UNREACHABILITY explicitly and says nothing about adopters being broken -
# an unknown is not a definite negative. (Same class of lie the Elixir path's
# release.live_registry_presence vs release.live_registry_unverifiable split
# fixes on the `mix crosswake.release.status --live` side.)
MIRROR_TAGS_OUTPUT=""

read_mirror_tags() {
  local attempt
  local output=""

  for attempt in 1 2 3; do
    if output="$(git -c core.askPass= ls-remote --tags "$MIRROR_REMOTE" 2>&1)"; then
      MIRROR_TAGS_OUTPUT="$output"
      return 0
    fi

    log "attempt ${attempt}/3: could not reach ${MIRROR_REPO} at ${MIRROR_REMOTE}"

    if [ "$attempt" -eq 3 ]; then
      fail "release.ios_mirror_parity - could not reach the SwiftPM mirror ${MIRROR_REPO} after 3 attempts: $(printf '%s' "$output" | head -1)" \
        "This is an UNKNOWN, not a confirmed missing tag. Check network access to github.com and re-run script/check_ios_mirror_parity.sh."
    fi

    sleep "$RETRY_SLEEP"
  done
}

# Local side: released iOS component tags, prefix-stripped. `git tag --list` is
# a fixed-format local read; nothing remote-controlled reaches a command here.
local_versions() {
  git -C "$RELEASE_REPO" tag --list 'ios-core-v*' | sed -n 's#^ios-core-v##p' | sort -u
}

# Mirror side: parse `<sha><TAB>refs/tags/<name>` lines with a fixed prefix split
# (T-153-10: no eval, no unquoted expansion of remote content into a command).
# `^{}` peel lines for annotated tags collapse onto the same version.
mirror_versions() {
  printf '%s\n' "$1" \
    | sed -n 's#^.*[[:space:]]refs/tags/v##p' \
    | sed 's#\^{}$##' \
    | sort -u
}

main() {
  local local_list
  local mirror_list
  local missing

  local_list="$(local_versions)"

  if [ -z "$local_list" ]; then
    ok "release.ios_mirror_parity - no ios-core-v* release tags in this repo; nothing to mirror."
    exit 0
  fi

  read_mirror_tags
  mirror_list="$(mirror_versions "$MIRROR_TAGS_OUTPUT")"

  missing="$(comm -23 <(printf '%s\n' "$local_list") <(printf '%s\n' "$mirror_list") | sed '/^$/d')"

  if [ -n "$missing" ]; then
    fail_parity "$missing"
  fi

  ok "release.ios_mirror_parity - ${MIRROR_REPO} carries a refs/tags/v* for every released ios-core-v* tag ($(printf '%s\n' "$local_list" | tr '\n' ' '))."
}

main "$@"
