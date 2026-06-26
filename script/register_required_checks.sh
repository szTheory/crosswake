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
#   script/register_required_checks.sh                 # DRY-RUN by default: print the plan
#   DRY_RUN=0 script/register_required_checks.sh       # apply the PATCH
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

mapfile -t DECLARED < <(python3 script/list_merge_blocking_checks.py)
if [ "${#DECLARED[@]}" -eq 0 ]; then
  echo "[crosswake] No merge-blocking checks declared in .github/workflows — nothing to register."
  exit 0
fi
echo "[crosswake] Declared merge-blocking lanes (${#DECLARED[@]}):"
printf '  - %s\n' "${DECLARED[@]}"

echo ""
echo "[crosswake] Fetching live required_status_checks for ${REPO}@${BRANCH} ..."
current="$(gh api "${EP}")"

# Up to 100 check-runs for the branch HEAD (the repo has ~70 lanes; default page size is 30).
checkruns="$(gh api "repos/${REPO}/commits/${BRANCH}/check-runs?per_page=100")"

green=()
for c in "${DECLARED[@]}"; do
  if printf '%s' "$checkruns" | jq -e --arg n "$c" \
       '.check_runs | any(.name==$n and .conclusion=="success")' >/dev/null 2>&1; then
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
