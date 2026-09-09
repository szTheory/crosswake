#!/usr/bin/env bash
# Exact green-first required-check migration. Add mode is the only Plan 165-10 write;
# retire mode defaults to a canonical dry-run and requires a later approved proposal to apply.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
REPO="${REPO:-szTheory/crosswake}"
BRANCH="${BRANCH:-main}"
EP="repos/${REPO}/branches/${BRANCH}/protection/required_status_checks"
BASELINE=".planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/required-context-baseline.json"
OBSERVATION=".planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/live-observation.json"

POLICY=""; MODE=""; ACTION="dry-run"; OUTPUT=""; VERIFY_OUTPUT=""; APPROVED_PROPOSAL=""
usage() {
  echo "usage: script/register_required_checks.sh --policy <file> --mode add|retire [--dry-run|--apply] [--output <file>] [--verify-output <file>] [--approved-proposal <file>]" >&2
  exit 2
}
while [ "$#" -gt 0 ]; do
  case "$1" in
    --policy) [ "$#" -ge 2 ] || usage; POLICY="$2"; shift 2 ;;
    --mode) [ "$#" -ge 2 ] || usage; MODE="$2"; shift 2 ;;
    --dry-run) [ "$ACTION" = "dry-run" ] || usage; ACTION="dry-run"; shift ;;
    --apply) [ "$ACTION" = "dry-run" ] || usage; ACTION="apply"; shift ;;
    --output) [ "$#" -ge 2 ] || usage; OUTPUT="$2"; shift 2 ;;
    --verify-output) [ "$#" -ge 2 ] || usage; VERIFY_OUTPUT="$2"; shift 2 ;;
    --approved-proposal) [ "$#" -ge 2 ] || usage; APPROVED_PROPOSAL="$2"; shift 2 ;;
    *) usage ;;
  esac
done
[ -n "$POLICY" ] && [ -f "$POLICY" ] || usage
case "$MODE" in add|retire) ;; *) usage ;; esac
[ -f "$BASELINE" ] && [ -f "$OBSERVATION" ] || { echo "[crosswake] FAIL: required migration evidence is missing." >&2; exit 1; }

if ! jq -e --slurpfile baseline "$BASELINE" '
  (keys | sort) == (["dual_contexts","legacy_contexts","schema_version","source_digest","strict","target_check","target_contexts","umbrella_context"] | sort) and
  .schema_version == 1 and .strict == true and .umbrella_context == "Crosswake CI" and
  (.legacy_contexts | type == "array" and length > 0 and . == (sort | unique)) and
  (.dual_contexts == ((.legacy_contexts + [.umbrella_context]) | sort | unique)) and
  (.target_contexts == [.umbrella_context]) and
  (.target_check == {context:.umbrella_context,app_id:15368}) and
  (.legacy_contexts == $baseline[0].required_contexts) and
  (.source_digest == $baseline[0].source_digest) and $baseline[0].strict == true
' "$POLICY" >/dev/null; then
  echo "[crosswake] FAIL: policy does not exactly match the frozen Plan 01 authority snapshot." >&2
  exit 1
fi
umbrella="$(jq -r '.umbrella_context' "$POLICY")"
if ! python3 script/list_merge_blocking_checks.py --require-display-name "$umbrella" >/dev/null; then
  echo "[crosswake] FAIL: umbrella must have exactly one literal local producer." >&2
  exit 1
fi
if ! jq -e --arg umbrella "$umbrella" '
  .schema_version == 2 and .umbrella_context == $umbrella and
  .full_probe.umbrella_result == "success" and
  .planning_probe.umbrella_result == "success" and
  .public_docs_probe.umbrella_result == "success" and
  .cleanup.pull_requests_closed == true and
  .cleanup.branches_deleted == true and .cancellation.lower_run_cancelled == true and
  .cancellation.newer_run_authoritative == true and
  (.cancellation.controller_run_id | type == "number") and
  .cancellation.controller_source_run_id == .cancellation.newer_run_id and
  (.cancellation.lower_run_id as $lower |
    (.cancellation.selected_lower_run_ids | index($lower)) != null) and
  .cancellation.requested_controller_observed == true and
  .cancellation.runner_consumption_observed == true and
  .cancellation.bounded_controller_action == true
' "$OBSERVATION" >/dev/null; then
  echo "[crosswake] FAIL: source-bound green umbrella observation is absent or incomplete." >&2
  exit 1
fi

current_file="$(mktemp "${TMPDIR:-/tmp}/crosswake-required-current.XXXXXX")"
desired_file="$(mktemp "${TMPDIR:-/tmp}/crosswake-required-desired.XXXXXX")"
after_file="$(mktemp "${TMPDIR:-/tmp}/crosswake-required-after.XXXXXX")"
proposal_file="$(mktemp "${TMPDIR:-/tmp}/crosswake-required-proposal.XXXXXX")"
trap 'rm -f "$current_file" "$desired_file" "$after_file" "$proposal_file"' EXIT
gh api "$EP" >"$current_file"
if ! jq -e '
  ((.contexts // []) | length == 0) and (.checks | type == "array") and
  all(.checks[]; (keys | sort) == ["app_id", "context"] and
    (.context | type == "string" and length > 0) and
    (.app_id | type == "number" and . > 0)) and
  ([.checks[].context] | length == (unique | length))
' "$current_file" >/dev/null; then
  echo "[crosswake] FAIL: live required checks must be unique app-bound records without legacy contexts entries." >&2
  exit 1
fi
current_contexts="$(jq -c '[.checks[].context] | sort | unique' "$current_file")"
current_strict="$(jq -r '.strict == true' "$current_file")"
legacy_contexts="$(jq -c '.legacy_contexts' "$POLICY")"
dual_contexts="$(jq -c '.dual_contexts' "$POLICY")"
target_check="$(jq -cS '.target_check' "$POLICY")"
target_matches="$(jq -cS --argjson target "$target_check" '[.checks[] | {context,app_id} | select(. == $target)] | length' "$current_file")"
source_state_matches=false
if [ "$MODE" = "add" ] && [ "$current_contexts" = "$legacy_contexts" ] && [ "$target_matches" -eq 0 ]; then
  source_state_matches=true
elif [ "$MODE" = "add" ] && [ "$current_contexts" = "$dual_contexts" ] && [ "$target_matches" -eq 1 ]; then
  source_state_matches=true
elif [ "$MODE" = "retire" ] && [ "$current_contexts" = "$dual_contexts" ] && [ "$target_matches" -eq 1 ]; then
  source_state_matches=true
fi
if [ "$current_strict" != "true" ] || [ "$source_state_matches" != "true" ]; then
  echo "[crosswake] FAIL: live required checks drifted from the policy source state for mode ${MODE}." >&2
  exit 1
fi

if [ "$MODE" = "add" ]; then
  jq --argjson target "$target_check" \
    '{strict:true,checks:((.checks + [$target]) | sort_by(.context))}' \
    "$current_file" >"$desired_file"
else
  jq --argjson target "$target_check" \
    '{strict:true,checks:[$target]}' \
    "$current_file" >"$desired_file"
fi
before_semantic="$(jq -cS '{strict:(.strict == true),checks:[.checks[]? | {context,app_id}]|sort_by(.context)}' "$current_file")"
after_semantic="$(jq -cS '{strict,checks:[.checks[]? | {context,app_id}]|sort_by(.context)}' "$desired_file")"
source_digest="$(printf '%s' "$before_semantic" | shasum -a 256 | awk '{print $1}')"

if [ "$MODE" = "retire" ]; then
  jq -nS --arg repository "$REPO" --arg branch "$BRANCH" --arg digest "$source_digest" \
    --arg observation "live-observation.json" --arg generated "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --arg command "script/register_required_checks.sh --policy script/required_check_policy.json --mode retire --apply --approved-proposal .planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/required-context-retirement.json" \
    --slurpfile policy "$POLICY" \
    '{schema_version:1,repository:$repository,default_branch:$branch,source_protection_digest:$digest,
      strict_before:true,strict_after:true,added_contexts:[],removed_contexts:$policy[0].legacy_contexts,
      retained_contexts:$policy[0].target_contexts,retained_checks:[$policy[0].target_check],producer_verification:"unique",
      live_observation_reference:$observation,generated_at:$generated,apply_command:$command}' >"$proposal_file"
  if [ -n "$OUTPUT" ]; then mkdir -p "$(dirname "$OUTPUT")"; cp "$proposal_file" "$OUTPUT"; fi
  if [ -n "$VERIFY_OUTPUT" ] && ! jq -e --slurpfile expected "$VERIFY_OUTPUT" \
      'del(.generated_at) == ($expected[0] | del(.generated_at))' "$proposal_file" >/dev/null; then
    echo "[crosswake] FAIL: retirement proposal differs from the approved canonical output." >&2
    exit 1
  fi
fi

if [ "$ACTION" = "dry-run" ]; then
  echo "[crosswake] DRY-RUN: mode=${MODE}; no branch-protection mutation applied."
  jq '{strict,checks}' "$desired_file"
  exit 0
fi
if [ "$MODE" = "retire" ]; then
  [ -n "$APPROVED_PROPOSAL" ] && [ -f "$APPROVED_PROPOSAL" ] || { echo "[crosswake] FAIL: retire apply requires --approved-proposal." >&2; exit 1; }
  if ! jq -e --slurpfile approved "$APPROVED_PROPOSAL" \
      'del(.generated_at) == ($approved[0] | del(.generated_at))' "$proposal_file" >/dev/null; then
    echo "[crosswake] FAIL: approved retirement proposal is stale." >&2
    exit 1
  fi
fi
gh api --method PATCH "$EP" --input "$desired_file" >/dev/null
gh api "$EP" >"$after_file"
actual_after="$(jq -cS '{strict:(.strict == true),checks:[.checks[]? | {context,app_id}]|sort_by(.context)}' "$after_file")"
if [ "$actual_after" != "$after_semantic" ]; then
  echo "[crosswake] FAIL: post-apply branch protection does not equal the exact desired state." >&2
  exit 1
fi
echo "[crosswake] OK: mode=${MODE} applied and exact post-write authority verified."
