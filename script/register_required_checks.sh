#!/usr/bin/env bash
# register_required_checks.sh — parametric, idempotent registration of ALL merge-blocking CI
# lanes as required status checks on the protected branch. Supersedes the per-gate
# register-*-gate.sh scripts (contract / e2e / native): adding a new merge-blocking lane now
# needs ZERO new registration code — this discovers it automatically (PROOF-03 follow-on).
#
# Registration changes branch protection and is therefore an admin-only, harness-blocked action
# (the legitimate human gate — like merging a Release PR). This script removes the *recurring
# toil* (one parametric command instead of N hand-written gh api one-liners) but keeps the
# privileged apply behind the maintainer's own admin-scoped gh auth.
#
# Usage (maintainer, from a shell with gh CLI authenticated at repo-admin scope):
#   script/register_required_checks.sh                 # DRY-RUN, ALL green declared lanes
#   DRY_RUN=0 script/register_required_checks.sh       # apply (ALL green declared lanes)
#   DRY_RUN=0 script/register_required_checks.sh "merge-blocking-contract-drift" "..."  # subset
#
# Optional positional args = an ALLOWLIST: only these exact contexts (intersected with the
# discovered merge-blocking lanes) are considered. Use this to require just the lanes you trust
# as hard gates and leave known-flaky lanes advisory — blanket-requiring every lane can let a
# flaky proof block all PRs. With no args, all discovered merge-blocking lanes are candidates.
#
# Safety properties:
#   - Green-first preflight per check (mirrors register-contract-gate.sh): only registers a lane
#     that has ALREADY gone green on the branch at least once, avoiding the "Expected — Waiting
#     for status" deadlock that freezes every open PR when a never-seen check is required.
#   - Granular required_status_checks endpoint (not full PUT .../protection): enforce_admins and
#     review requirements are left untouched.
#   - Preserves strict + ALL existing required checks; appends; unique_by(.context) → idempotent.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

REPO="${REPO:-szTheory/crosswake}"
BRANCH="${BRANCH:-main}"
ACTIONS_APP_ID="${ACTIONS_APP_ID:-15368}"
DRY_RUN="${DRY_RUN:-1}"
EP="repos/${REPO}/branches/${BRANCH}/protection/required_status_checks"

# NOT `mapfile` — that is bash 4.0+, and macOS ships bash 3.2.57. See the same note in
# check_required_checks_registered.sh: this is run by maintainers on Macs, where `mapfile` fails
# with "command not found" and the script exits 127 before registering anything.
ALL_DECLARED=()
while IFS= read -r _line; do
  [ -n "$_line" ] && ALL_DECLARED+=("$_line")
done < <(python3 script/list_merge_blocking_checks.py)
if [ "${#ALL_DECLARED[@]}" -eq 0 ]; then
  echo "[crosswake] No merge-blocking checks declared in .github/workflows — nothing to register."
  exit 0
fi

# Optional allowlist (positional args): intersect with discovered lanes. Unknown args are an error
# (typo guard — never silently register nothing / something unintended).
if [ "$#" -gt 0 ]; then
  DECLARED=()
  for want in "$@"; do
    if printf '%s\n' "${ALL_DECLARED[@]}" | grep -qxF "$want"; then
      DECLARED+=("$want")
    else
      echo "[crosswake] FAIL: '$want' is not a discovered merge-blocking lane. Run script/list_merge_blocking_checks.py to see valid names." >&2
      exit 1
    fi
  done
else
  DECLARED=("${ALL_DECLARED[@]}")
fi

echo "[crosswake] Candidate merge-blocking lanes (${#DECLARED[@]} of ${#ALL_DECLARED[@]} declared):"
printf '  - %s\n' "${DECLARED[@]}"

echo ""
echo "[crosswake] Fetching live required_status_checks for ${REPO}@${BRANCH} ..."
current="$(gh api "${EP}")"

# Names of all currently-successful check-runs on the branch HEAD. MUST paginate: this repo
# has ~70 lanes and re-runs push the total over the 100/page cap, so a single page silently
# drops green lanes onto page 2 → they'd be wrongly skipped. --paginate applies the --jq filter
# per page and concatenates, so this collects successes across every page.
green_names="$(gh api --paginate "repos/${REPO}/commits/${BRANCH}/check-runs?per_page=100" \
                 --jq '.check_runs[] | select(.conclusion=="success") | .name' | sort -u)"

green=()
for c in "${DECLARED[@]}"; do
  if printf '%s\n' "$green_names" | grep -qxF "$c"; then
    green+=("$c")
  else
    echo "[crosswake] SKIP (no green run on ${BRANCH} yet — register after it passes once): $c"
  fi
done

if [ "${#green[@]}" -eq 0 ]; then
  echo "[crosswake] None of the declared lanes are green on ${BRANCH} yet — nothing to register."
  exit 0
fi

add="$(printf '%s\n' "${green[@]}" | jq -R . | jq -s --argjson app "$ACTIONS_APP_ID" \
        'map({context: ., app_id: $app})')"
desired="$(jq -n --argjson cur "$current" --argjson add "$add" \
  '{ strict: $cur.strict,
     checks: (($cur.checks // []) + $add | unique_by(.context)) }')"

echo ""
echo "[crosswake] Desired required_status_checks:"
printf '%s' "$desired" | jq .

if [ "$DRY_RUN" = "1" ]; then
  echo ""
  echo "[crosswake] DRY_RUN=1 (default) — not writing. Re-run with DRY_RUN=0 to apply."
  exit 0
fi

echo ""
echo "[crosswake] Applying PATCH ..."
gh api -X PATCH "${EP}" --input <(printf '%s' "$desired")
echo ""
echo "[crosswake] Resulting required_status_checks:"
gh api "${EP}" | jq '{strict, checks}'
echo "[crosswake] Done — ${#green[@]} merge-blocking lane(s) ensured required on ${BRANCH}."
