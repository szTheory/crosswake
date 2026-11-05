#!/usr/bin/env bash
# Derived promotion readiness for the Android foreign-host proof job (Phase 198, AND-03, D-20).
#
# "Required only after two clean runs" is computed here from Crosswake CI run history and the
# foreign-host evidence artifacts. It is never a hand-stamped value. This script only reports:
# promotion itself is a later reviewed PR that edits FINAL_PROOF_LEAVES and the umbrella needs.
#
# usage: script/android_foreign_promotion.sh
#
# Runs locally only: downloading an artifact needs an authenticated `gh`, and Crosswake CI is
# pull-request only, so no scheduled or workflow run could read the same history.
# Needs gh, jq, git and unzip.
#
# Output, exactly one line:
#   android_foreign: clean_runs=N/2 eligible=yes|no head=<40-hex sha or none> ci_ran_on=synthetic_merge
#   android_foreign: UNVERIFIED <reason>
# `head` is the PR head SHA of the newest counted run. `ci_ran_on=synthetic_merge` says that CI ran
# on the synthetic merge commit GitHub builds for a pull request, which is not the PR head.
#
# Exit codes: 0 a derived line was printed (eligibility never fails the command),
#             2 UNVERIFIED (any read failure; never treated as zero clean runs).
# UNVERIFIED reasons are fixed strings: tool_unavailable, repo_unreadable, runs_unreadable,
# jobs_unreadable, artifact_unreadable, evidence_unparseable. gh stderr text is never printed.
#
# Counting rules, runs read newest first (pull_request runs of crosswake-ci.yml, first 50):
#   - a run that is not completed, or whose job `android-foreign-host` is absent or skipped, is
#     neither clean nor a reset;
#   - a head SHA already counted is skipped, so a re-run of the same head counts once;
#   - a job that ran and did not succeed (failure, cancelled, timed_out) stops the count;
#   - a job that succeeded counts only if its `android-foreign-host-evidence` artifact holds a JSON
#     file (top level of the zip) with tests >= 1, control_reason "could_not_find",
#     script_blob equal to the current git blob of script/verify_android_foreign_host.sh, and
#     result "PASS". A success with no artifact or a different blob, reason or result stops the count;
#   - reading stops once the count reaches 2. No CI run is re-run or re-counted.
#
# One read of the GitHub API is attempted twice (gh_get below): GitHub answers an occasional HTTP 502
# on a perfectly readable run, and scanning 50 runs would otherwise report UNVERIFIED by chance. A
# read that fails twice is UNVERIFIED, never zero clean runs.
set -uo pipefail

WORKFLOW_FILE="crosswake-ci.yml"
JOB_NAME="android-foreign-host"
ARTIFACT_NAME="android-foreign-host-evidence"
PROOF_SCRIPT="script/verify_android_foreign_host.sh"
NEEDED=2

unverified() { # reason
  echo "android_foreign: UNVERIFIED $1"
  exit 2
}

# The tool check runs before any other command so a reduced PATH fails here, closed.
for tool in gh jq git unzip; do
  command -v "$tool" >/dev/null 2>&1 || unverified tool_unavailable
done

work=$(mktemp -d 2>/dev/null) || unverified tool_unavailable
trap 'rm -rf "$work"' EXIT

# gh_get OUT ARGS...: write one gh read to OUT; a failed read is attempted once more (see header).
gh_get() {
  local out="$1"
  shift
  gh "$@" >"$out" 2>/dev/null </dev/null && return 0
  sleep 1
  gh "$@" >"$out" 2>/dev/null </dev/null
}

HERE="${BASH_SOURCE[0]%/*}"
[ "$HERE" = "${BASH_SOURCE[0]}" ] && HERE="."
cd "$HERE/.." 2>/dev/null || unverified repo_unreadable

current_blob=$(git hash-object "$PROOF_SCRIPT" 2>/dev/null </dev/null) || unverified repo_unreadable
[ -n "$current_blob" ] || unverified repo_unreadable

gh_get "$work/repo.json" repo view --json nameWithOwner || unverified repo_unreadable
repo=$(jq -r '.nameWithOwner // empty' "$work/repo.json" 2>/dev/null) || unverified repo_unreadable
[ -n "$repo" ] || unverified repo_unreadable

gh_get "$work/runs.json" api "repos/${repo}/actions/workflows/${WORKFLOW_FILE}/runs?event=pull_request&per_page=50" \
  || unverified runs_unreadable
runs=$(jq -r 'if (.workflow_runs | type) == "array"
              then .workflow_runs[] | "\(.id)\t\(.head_sha)\t\(.status)"
              else error("no runs array") end' "$work/runs.json" 2>/dev/null) || unverified runs_unreadable

count=0
first_head="none"
counted=" "

while IFS=$'\t' read -r run_id run_sha run_status; do
  [ -n "$run_id" ] || continue
  [[ "$run_id" =~ ^[0-9]+$ ]] || unverified runs_unreadable
  [[ "$run_sha" =~ ^[0-9a-f]{40}$ ]] || unverified runs_unreadable
  [ "$run_status" = "completed" ] || continue

  gh_get "$work/jobs.json" api --paginate "repos/${repo}/actions/runs/${run_id}/jobs?per_page=100" \
    || unverified jobs_unreadable
  job_state=$(jq -s -r --arg name "$JOB_NAME" '
    if ([.[] | select(type == "object" and ((.jobs | type) == "array"))] | length) == 0
    then error("no jobs array")
    else ([.[] | select(type == "object") | .jobs[]? | select(.name == $name)] | first
          | if . == null then "absent" else (.conclusion // "pending") end)
    end' "$work/jobs.json" 2>/dev/null) || unverified jobs_unreadable

  case "$job_state" in
    absent | skipped | pending) continue ;;
    success) ;;
    *) break ;; # ran and did not succeed: the count stops
  esac

  case "$counted" in *" $run_sha "*) continue ;; esac

  gh_get "$work/artifacts.json" api "repos/${repo}/actions/runs/${run_id}/artifacts?per_page=100" \
    || unverified artifact_unreadable
  artifact_id=$(jq -r --arg name "$ARTIFACT_NAME" '
    if (.artifacts | type) == "array"
    then ([.artifacts[] | select(.name == $name and ((.expired // false) | not))] | first | .id // empty)
    else error("no artifacts array") end' "$work/artifacts.json" 2>/dev/null) || unverified artifact_unreadable
  [ -n "$artifact_id" ] || break # a success with no evidence artifact stops the count
  [[ "$artifact_id" =~ ^[0-9]+$ ]] || unverified artifact_unreadable

  zip_path="$work/${run_id}.zip"
  extract_dir="$work/${run_id}"
  gh_get "$zip_path" api "repos/${repo}/actions/artifacts/${artifact_id}/zip" || unverified artifact_unreadable
  mkdir -p "$extract_dir" || unverified artifact_unreadable
  unzip -qq -o "$zip_path" -d "$extract_dir" >/dev/null 2>&1 </dev/null || unverified artifact_unreadable

  evidence_file=""
  for candidate in "$extract_dir"/*.json; do
    [ -f "$candidate" ] && { evidence_file="$candidate"; break; }
  done
  [ -n "$evidence_file" ] || unverified evidence_unparseable

  clean=$(jq -r --arg blob "$current_blob" '
    if type != "object" then error("not an object")
    elif ((.tests | type) == "number") and .tests >= 1
         and .control_reason == "could_not_find"
         and .script_blob == $blob
         and .result == "PASS"
    then "yes" else "no" end' "$evidence_file" 2>/dev/null) || unverified evidence_unparseable
  [ "$clean" = "yes" ] || break

  count=$((count + 1))
  counted="${counted}${run_sha} "
  [ "$first_head" = "none" ] && first_head="$run_sha"
  [ "$count" -ge "$NEEDED" ] && break
done <<<"$runs"

eligible=no
[ "$count" -ge "$NEEDED" ] && eligible=yes
echo "android_foreign: clean_runs=${count}/${NEEDED} eligible=${eligible} head=${first_head} ci_ran_on=synthetic_merge"
exit 0
