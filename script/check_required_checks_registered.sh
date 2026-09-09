#!/usr/bin/env bash
# Fail-closed comparison between literal workflow producers and exact branch-protection policy.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
REPO="${REPO:-szTheory/crosswake}"
BRANCH="${BRANCH:-main}"
EP="repos/${REPO}/branches/${BRANCH}/protection/required_status_checks"
POLICY=""; STATE=""; LIVE=0; LOCAL_ONLY=0

usage() {
  echo "usage: script/check_required_checks_registered.sh [--local-only] [--policy <file> --state dual|target --live]" >&2
  exit 2
}
while [ "$#" -gt 0 ]; do
  case "$1" in
    --local-only) LOCAL_ONLY=1; shift ;;
    --policy) [ "$#" -ge 2 ] || usage; POLICY="$2"; shift 2 ;;
    --state) [ "$#" -ge 2 ] || usage; STATE="$2"; shift 2 ;;
    --live) LIVE=1; shift ;;
    *) usage ;;
  esac
done
if [ -n "$POLICY" ]; then
  [ -f "$POLICY" ] || usage
  case "$STATE" in dual|target) ;; *) usage ;; esac
  [ "$LIVE" -eq 1 ] || usage
elif [ -n "$STATE" ] || [ "$LIVE" -eq 1 ]; then
  usage
fi

PRODUCERS_FILE="$(mktemp "${TMPDIR:-/tmp}/crosswake-producers.XXXXXX")"
CANDIDATES_FILE="$(mktemp "${TMPDIR:-/tmp}/crosswake-candidates.XXXXXX")"
trap 'rm -f "$PRODUCERS_FILE" "$CANDIDATES_FILE"' EXIT
python3 script/list_merge_blocking_checks.py --producers >"$PRODUCERS_FILE" || {
  echo "[crosswake] FAIL: local producer inventory failed." >&2; exit 1;
}
python3 script/list_merge_blocking_checks.py --emitters >"$CANDIDATES_FILE" || {
  echo "[crosswake] FAIL: local merge-blocking inventory failed." >&2; exit 1;
}
[ -s "$PRODUCERS_FILE" ] && [ -s "$CANDIDATES_FILE" ] || {
  echo "[crosswake] FAIL: local producer authority is empty." >&2; exit 1;
}
echo "[crosswake] OK: local producer authority verified ($(wc -l <"$PRODUCERS_FILE" | tr -d ' ') literal producers)."
[ "$LOCAL_ONLY" -eq 0 ] || exit 0

if [ -n "${CROSSWAKE_REQUIRED_CHECKS_JSON:-}" ]; then
  current="$CROSSWAKE_REQUIRED_CHECKS_JSON"
elif ! current="$(gh api "$EP" 2>/dev/null)"; then
  echo "[crosswake] UNVERIFIED (exit 3): cannot read branch protection for ${REPO}@${BRANCH}." >&2
  exit 3
fi
if ! normalized="$(printf '%s' "$current" | python3 script/normalize_required_checks.py --input -)"; then
  echo "[crosswake] FAIL: malformed, non-strict, or ambiguous required-check response." >&2
  exit 1
fi
registered_checks="$(printf '%s' "$normalized" | jq -cS '.checks')"
registered="$(printf '%s' "$normalized" | jq -r '.checks[].context')"

if [ -n "$POLICY" ]; then
  expected="$(jq -r --arg state "$STATE" 'if $state == "dual" then .dual_contexts[] else .target_contexts[] end' "$POLICY")"
  strict_expected="$(jq -r '.strict' "$POLICY")"
  target_check="$(jq -cS '.target_check' "$POLICY")"
  target_matches="$(printf '%s' "$normalized" | jq -cS --argjson target "$target_check" '[.checks[] | select(. == $target)] | length')"
  record_matches=true
  if [ "$STATE" = "target" ] && [ "$registered_checks" != "[$target_check]" ]; then
    record_matches=false
  elif [ "$STATE" = "dual" ] && [ "$target_matches" -ne 1 ]; then
    record_matches=false
  fi
  if [ "$(printf '%s' "$normalized" | jq -r '.strict')" != "$strict_expected" ] || [ "$registered" != "$expected" ] || [ "$record_matches" != true ]; then
    echo "[crosswake] FAIL: live branch protection does not equal exact ${STATE} policy state." >&2
    exit 1
  fi
else
  expected="$registered"
fi

errors=0
while IFS= read -r context; do
  [ -n "$context" ] || continue
  count="$(awk -F '\t' -v wanted="$context" '$1 == wanted {n++} END {print n+0}' "$PRODUCERS_FILE")"
  if [ "$count" -ne 1 ]; then
    echo "[crosswake] FAIL: required context '${context}' has ${count} literal producers." >&2
    errors=1
  fi
done <<EOF
$expected
EOF

if [ -z "$POLICY" ]; then
  while IFS=$'\t' read -r context workflow job_id; do
    [ -n "$context" ] || continue
    if ! printf '%s\n' "$registered" | grep -qxF "$context"; then
      echo "[crosswake] FAIL: '${context}' from ${workflow} (${job_id}) is not required on ${BRANCH}." >&2
      errors=1
    fi
  done <"$CANDIDATES_FILE"
fi
[ "$errors" -eq 0 ] || exit 1
echo "[crosswake] OK: strict ${STATE:-registered} authority is exact and every required context has one producer."
