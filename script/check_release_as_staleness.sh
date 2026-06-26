#!/usr/bin/env bash
# check_release_as_staleness.sh — Fail-closed guard against stale release-please `release-as` pins.
#
# Usage: ./script/check_release_as_staleness.sh [release-please-config.json]
#   CONFIG defaults to release-please-config.json at the repo root.
#
# WHY THIS EXISTS (PROOF-03 / recipe Step 12f / Pitfall 6):
#   release-please uses `"release-as": "X"` as a ONE-SHOT bootstrap override to force the first
#   release of a component to land at exactly X. After that first Release PR merges, the pin MUST
#   be removed — otherwise every subsequent run keeps re-targeting X and the component's version is
#   silently frozen (it never proposes X+1). Core hit this exact footgun (manual cleanup commit
#   1ee082c); companions (crosswake_rulestead, crosswake_rindle) carry the same pin during bootstrap.
#
# THE CHECK (parametric across ALL packages — core + every crosswake_* companion):
#   For each package whose block sets a non-empty `release-as: X`, FAIL if a release at X already
#   exists, detected by the release-please git tag `{component}-v{X}` (e.g. crosswake_rindle-v0.1.0,
#   hex-v0.1.2). A live tag means X is already published, so the pin is stale and MUST be removed.
#
#   The git tag — not the manifest baseline — is the authoritative "already released" signal:
#   the manifest baseline is set to the bootstrap version BEFORE the first release (rindle's
#   baseline is 0.1.0 while unreleased), so keying on the manifest would false-positive at bootstrap.
#
# REMEDIATION when RED: remove `"release-as"` (and any adjacent `_TODO_release_as`) from the named
#   component in release-please-config.json. The release-please cleanup-PR job opens this PR
#   automatically on release; this guard stays RED until it merges, so the fix cannot be forgotten.
#
# Failure messages lead with [crosswake] per project conventions (BRAND-SPEC §6):
#   name what happened + what to do next.
set -euo pipefail

CONFIG="${1:-release-please-config.json}"

if [ ! -f "$CONFIG" ]; then
  echo "[crosswake] FAIL: release-please config not found at $CONFIG"
  exit 1
fi

command -v jq >/dev/null 2>&1 || { echo "[crosswake] FAIL: jq is required but not installed"; exit 1; }

echo "[crosswake] check_release_as_staleness: scanning $CONFIG for stale release-as pins"

# Emit "component<TAB>release-as" for every package block that sets a non-empty release-as.
PINS="$(jq -r '
  .packages
  | to_entries[]
  | select((.value["release-as"] // "") != "")
  | "\(.value.component)\t\(.value["release-as"])"
' "$CONFIG")"

if [ -z "$PINS" ]; then
  echo "[crosswake] OK: no release-as pins set — nothing to check."
  exit 0
fi

stale_found=0
while IFS=$'\t' read -r component version; do
  [ -z "$component" ] && continue
  tag="${component}-v${version}"
  if git rev-parse -q --verify "refs/tags/${tag}" >/dev/null 2>&1; then
    stale_found=1
    echo "[crosswake] STALE: '${component}' pins release-as '${version}', but tag '${tag}' already exists."
    echo "[crosswake]   What happened: '${version}' is already released, so this one-shot bootstrap pin is now stuck —"
    echo "[crosswake]   release-please will keep re-targeting ${version} instead of proposing the next SemVer."
    echo "[crosswake]   What to do next: remove \"release-as\" (and any \"_TODO_release_as\") from the"
    echo "[crosswake]   '${component}' block in ${CONFIG}. (The release-please cleanup-PR job opens this PR automatically.)"
  else
    echo "[crosswake] OK: '${component}' pins release-as '${version}' (bootstrap) — no '${tag}' tag yet, not released."
  fi
done <<< "$PINS"

if [ "$stale_found" -ne 0 ]; then
  echo "[crosswake] FAIL: one or more stale release-as pins found (see above)."
  exit 1
fi

echo "[crosswake] check_release_as_staleness: OK — no stale release-as pins."
