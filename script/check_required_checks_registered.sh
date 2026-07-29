#!/usr/bin/env bash
# check_required_checks_registered.sh — fail-closed detector for the "declared merge-blocking but
# not actually registered" gap. A lane named "...merge-blocking..." that is NOT in the branch's
# required_status_checks is advisory in practice (a green PR can merge while it is red) — a silent
# downgrade of a lane that calls itself merge-blocking. This surfaces that gap loudly (PROOF-03
# follow-on); pairs with register_required_checks.sh which closes it.
#
# Exit codes:
#   0  every declared merge-blocking lane is registered as a required check
#   1  GAP — one or more declared lanes are NOT registered (fail-closed)
#   3  UNVERIFIED — branch protection could not be read (needs repo-admin gh auth). NOT a pass.
#
# Usage:
#   script/check_required_checks_registered.sh
# Run by a maintainer (admin gh auth), or in a scheduled job with an admin-scoped PAT. It is NOT
# wired as a required PR check itself: a required check that audits required checks is circular,
# and PR-scoped tokens cannot read branch protection. exit 3 keeps it honest where it can't see.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

REPO="${REPO:-szTheory/crosswake}"
BRANCH="${BRANCH:-main}"
EP="repos/${REPO}/branches/${BRANCH}/protection/required_status_checks"

mapfile -t DECLARED < <(python3 script/list_merge_blocking_checks.py)
if [ "${#DECLARED[@]}" -eq 0 ]; then
  echo "[crosswake] No merge-blocking checks declared — nothing to verify."
  exit 0
fi

# --- Uniqueness (GATE-01) -----------------------------------------------------------------
# Asserting only that a name is REGISTERED is not enough. Branch protection matches required
# contexts by STRING, so if two jobs emit the same name, GitHub cannot tell them apart and a red
# run can be masked by a green one — the gate fails open while looking fully registered. Three
# such collisions survived in this repo precisely because this script checked presence, not
# uniqueness.
#
# This runs BEFORE the branch-protection read on purpose: it is a pure local check on the
# workflow files, so it stays meaningful in CI where no repo-admin token exists and the
# registration half exits 3 UNVERIFIED.
dupes="$(python3 script/list_merge_blocking_checks.py --emitters \
           | awk -F'\t' '{c[$1]++; src[$1]=src[$1]"\n      - "$2" ("$3")"} END{for(n in c) if(c[n]>1) printf "%s%s\n", n, src[n]}')"

if [ -n "$dupes" ]; then
  echo "[crosswake] FAIL: duplicate-merge-blocking-name - one check name is emitted by more than one job."
  echo "$dupes" | sed 's/^\([^ ]\)/  - \1/'
  echo "[crosswake]   Branch protection matches required contexts by string, so these are"
  echo "[crosswake]   indistinguishable: a red run can be masked by a green one and the gate"
  echo "[crosswake]   fails open while still reporting as registered."
  echo "[crosswake]   What to do next: rename the later-phase emitter, keeping the"
  echo "[crosswake]   'merge-blocking' substring so auto-discovery still finds it."
  exit 1
fi

if ! current="$(gh api "${EP}" 2>/dev/null)"; then
  echo "[crosswake] UNVERIFIED (exit 3): cannot read branch protection for ${REPO}@${BRANCH}."
  echo "[crosswake]   Needs gh CLI authenticated with repo-admin scope. This is NOT a pass —"
  echo "[crosswake]   re-run with admin credentials (or from a scheduled job with an admin PAT)."
  exit 3
fi

registered="$(printf '%s' "$current" | jq -r '.checks[]?.context')"
missing=()
for c in "${DECLARED[@]}"; do
  printf '%s\n' "$registered" | grep -qxF "$c" || missing+=("$c")
done

if [ "${#missing[@]}" -ne 0 ]; then
  echo "[crosswake] GAP: declared merge-blocking lane(s) NOT registered as required on ${BRANCH}:"
  printf '  - %s\n' "${missing[@]}"
  echo "[crosswake]   These are advisory in practice (a red one does not block merge)."
  echo "[crosswake]   What to do next: DRY_RUN=0 script/register_required_checks.sh"
  exit 1
fi

echo "[crosswake] OK: all ${#DECLARED[@]} declared merge-blocking lane(s) are registered as required on ${BRANCH}."
