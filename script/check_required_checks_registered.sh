#!/usr/bin/env bash
# Fail-closed comparison between literal workflow producers and required branch contexts.
# Local syntax/type/name/cardinality proof always precedes the optional governance read.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

REPO="${REPO:-szTheory/crosswake}"
BRANCH="${BRANCH:-main}"
EP="repos/${REPO}/branches/${BRANCH}/protection/required_status_checks"
LOCAL_ONLY=0

if [ "$#" -gt 1 ] || { [ "$#" -eq 1 ] && [ "$1" != "--local-only" ]; }; then
  echo "usage: script/check_required_checks_registered.sh [--local-only]" >&2
  exit 2
fi
[ "$#" -eq 1 ] && LOCAL_ONLY=1

PRODUCERS_FILE="$(mktemp "${TMPDIR:-/tmp}/crosswake-producers.XXXXXX")"
CANDIDATES_FILE="$(mktemp "${TMPDIR:-/tmp}/crosswake-candidates.XXXXXX")"
trap 'rm -f "$PRODUCERS_FILE" "$CANDIDATES_FILE"' EXIT

# The detector itself owns parse/type/name and merge-blocking cardinality. Capture its exit status
# directly: set -e does not reliably propagate a failed process substitution on Bash 3.2.
if ! python3 script/list_merge_blocking_checks.py --producers >"$PRODUCERS_FILE"; then
  echo "[crosswake] FAIL: local-producer-inventory - strict workflow inventory failed."
  echo "[crosswake]   What to do next: run python3 script/list_merge_blocking_checks.py --producers and repair every reported source."
  exit 1
fi

if ! python3 script/list_merge_blocking_checks.py --emitters >"$CANDIDATES_FILE"; then
  echo "[crosswake] FAIL: local-candidate-inventory - merge-blocking inventory failed."
  echo "[crosswake]   What to do next: run python3 script/list_merge_blocking_checks.py --emitters and repair every reported source."
  exit 1
fi

if [ ! -s "$PRODUCERS_FILE" ]; then
  echo "[crosswake] FAIL: missing-producer - no literal workflow producers were discovered."
  echo "[crosswake]   What to do next: restore literal jobs under .github/workflows before auditing branch policy."
  exit 1
fi

if [ ! -s "$CANDIDATES_FILE" ]; then
  echo "[crosswake] FAIL: missing-merge-blocking-producer - no merge-blocking candidates were discovered."
  echo "[crosswake]   What to do next: restore the stable merge-blocking workflow producers."
  exit 1
fi

producer_count="$(wc -l <"$PRODUCERS_FILE" | tr -d ' ')"
candidate_count="$(wc -l <"$CANDIDATES_FILE" | tr -d ' ')"
echo "[crosswake] OK: local producer authority verified (${producer_count} literal producers; ${candidate_count} merge-blocking candidates)."

if [ "$LOCAL_ONLY" -eq 1 ]; then
  exit 0
fi

if [ -n "${CROSSWAKE_REQUIRED_CHECKS_JSON:-}" ]; then
  current="${CROSSWAKE_REQUIRED_CHECKS_JSON}"
elif ! current="$(gh api "${EP}" 2>/dev/null)"; then
  echo "[crosswake] UNVERIFIED (exit 3): cannot read branch protection for ${REPO}@${BRANCH}."
  echo "[crosswake]   Needs gh CLI authenticated with repo-admin scope. This is NOT a pass —"
  echo "[crosswake]   re-run with admin credentials (or from a scheduled job with an admin PAT)."
  exit 3
fi

if ! printf '%s' "$current" | jq -e 'type == "object"' >/dev/null 2>&1; then
  echo "[crosswake] FAIL: malformed-registered-context-input - required-check JSON is not an object."
  echo "[crosswake]   What to do next: provide the unmodified required_status_checks response."
  exit 1
fi

registered="$(printf '%s' "$current" | jq -r '[.checks[]?.context, .contexts[]?] | .[]?' | sort -u)"
authority_errors=0

while IFS= read -r context; do
  [ -z "$context" ] && continue
  count="$(awk -F '\t' -v wanted="$context" '$1 == wanted {n++} END {print n+0}' "$PRODUCERS_FILE")"
  if [ "$count" -ne 1 ]; then
    echo "[crosswake] FAIL: registered-without-producer - required context '${context}' has ${count} literal local producers."
    echo "[crosswake]   What to do next: restore exactly one literal workflow job named '${context}', or remove the stale context through the approved governance path."
    authority_errors=1
  fi
done <<EOF
$registered
EOF

while IFS=$'\t' read -r context workflow job_id; do
  [ -z "$context" ] && continue
  if ! printf '%s\n' "$registered" | grep -qxF "$context"; then
    echo "[crosswake] FAIL: candidate-without-registration - '${context}' from ${workflow} (${job_id}) is not required on ${BRANCH}."
    echo "[crosswake]   What to do next: after it is green on main, run DRY_RUN=0 script/register_required_checks.sh"
    authority_errors=1
  fi
done <"$CANDIDATES_FILE"

if [ "$authority_errors" -ne 0 ]; then
  exit 1
fi

registered_count="$(printf '%s\n' "$registered" | sed '/^$/d' | wc -l | tr -d ' ')"
echo "[crosswake] OK: ${registered_count} registered context(s) each have one producer, and every merge-blocking candidate is registered on ${BRANCH}."
