#!/usr/bin/env bash
# DEPRECATED (Phase 135 / PROOF-03): superseded by the parametric
#   script/register_required_checks.sh  (discovers + registers ALL merge-blocking lanes; idempotent)
#   script/check_required_checks_registered.sh  (fail-closed gap detector)
# Kept for reference; prefer the parametric pair so a new gate needs no new registration script.
#
# register-e2e-gate.sh — GET-then-replace required_status_checks for GATE-01
#
# Registers merge-blocking-offline-sync-e2e as a required check on main, dropping
# the old e2e-offline-sync context. Preserves ALL currently required checks and
# strict: true by reading live state first (never hardens the checks array).
#
# Usage:
#   script/register-e2e-gate.sh
#   DRY_RUN=1 script/register-e2e-gate.sh    # print desired JSON, exit 0 without writing
#
# Ordering (run by maintainer out-of-band — harness-blocked):
#   1. Merge the workflow rename PR (offline-sync-e2e-gate.yml with aggregator job).
#   2. Let merge-blocking-offline-sync-e2e go GREEN on main at least once.
#   3. Run this script  (the preflight will refuse to PATCH until step 2 is done).
#
# Prerequisites: gh CLI authenticated with repo admin scope.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

# --- Parameters (all overridable via env) ---
REPO="${REPO:-szTheory/crosswake}"
BRANCH="${BRANCH:-main}"
NEW_CHECK="${NEW_CHECK:-merge-blocking-offline-sync-e2e}"
ACTIONS_APP_ID="${ACTIONS_APP_ID:-15368}"
OLD_CHECK="${OLD_CHECK:-e2e-offline-sync}"
DRY_RUN="${DRY_RUN:-0}"

EP="repos/${REPO}/branches/${BRANCH}/protection/required_status_checks"

echo "==> Fetching live required_status_checks for ${REPO}@${BRANCH} ..."
current="$(gh api "${EP}")"

# Build the desired payload via jq: keep strict from live value; drop OLD_CHECK;
# append NEW_CHECK with app_id; unique_by(.context) makes it idempotent.
desired="$(jq -n \
  --argjson cur    "$current" \
  --arg     new    "$NEW_CHECK" \
  --arg     old    "$OLD_CHECK" \
  --argjson app    "$ACTIONS_APP_ID" \
  '{
    strict: $cur.strict,
    checks: (
      ($cur.checks // [])
        | map(select(.context != $old))
        | . + [{context: $new, app_id: $app}]
        | unique_by(.context)
    )
  }')"

echo ""
echo "==> Desired payload:"
echo "$desired" | jq .

if [ "$DRY_RUN" = "1" ]; then
  echo ""
  echo "DRY_RUN=1 — not writing. Set DRY_RUN=0 and re-run after the preflight passes."
  exit 0
fi

# --- Green-first preflight ---
# Refuse to register until merge-blocking-offline-sync-e2e has gone green on BRANCH
# at least once. This avoids the "Expected — Waiting for status" deadlock that freezes
# every open PR when a never-seen required check is registered before CI runs it.
echo ""
echo "==> Preflight: checking for a successful '${NEW_CHECK}' run on ${BRANCH} ..."
if ! gh api "repos/${REPO}/commits/${BRANCH}/check-runs" \
     | jq -e --arg n "$NEW_CHECK" \
       '.check_runs | any(.name==$n and .conclusion=="success")' >/dev/null 2>&1; then
  echo ""
  echo "REFUSING (exit 2): '${NEW_CHECK}' has no successful run on ${BRANCH} yet."
  echo ""
  echo "To resolve:"
  echo "  1. Make sure the workflow rename PR is merged (offline-sync-e2e-gate.yml)."
  echo "  2. Wait for merge-blocking-offline-sync-e2e to go GREEN on main."
  echo "  3. Re-run this script."
  exit 2
fi
echo "Preflight passed — '${NEW_CHECK}' has gone green on ${BRANCH}."

# --- Apply PATCH ---
echo ""
echo "==> Applying PATCH to required_status_checks ..."
gh api -X PATCH "${EP}" --input <(echo "$desired")

echo ""
echo "==> Resulting required_status_checks:"
gh api "${EP}" | jq '{strict, checks}'

echo ""
echo "Done. merge-blocking-offline-sync-e2e is now a required check on ${BRANCH}."
