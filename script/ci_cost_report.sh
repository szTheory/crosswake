#!/usr/bin/env bash
# Advisory CI cost report for one Crosswake CI run. Needs only `gh` and `jq`.
# It never gates a merge: run it after CI finishes on a PR and compare with the baseline below.
#
# usage: script/ci_cost_report.sh [run-id]
#   run-id   defaults to the latest "Crosswake CI" run on the current branch.
#
# Prints per-job duration and runner, billable minutes (each job rounded up to a whole minute;
# macOS x10, Windows x2, Linux x1), wall clock, the critical-path job, and how many jobs ran a
# full core-suite step. The full-suite count is a step-name heuristic (FULL_SUITE_STEP_RE); update
# the pattern when a lane that runs the whole suite is added or renamed.
#
# BASELINE, measured over 9 green PR runs before "run the core suite once per PR" (for example
# run 40842819911): about 250 billable minutes per PR, 20-44 min wall clock, critical path
# proof-requires-example-host (median 32 min), full core suite (2,922 tests) about 10 times per PR
# (the step-name heuristic below sees 7 of those 10 on run 40842819911; it undercounts by design).
# Flag a PR that goes back up: a new duplicated full-suite run, or a job with no dependency cache.
set -euo pipefail

BASELINE_BILLABLE_MIN=250
BASELINE_WALL_MAX_MIN=44
BASELINE_FULL_SUITE_JOBS=10
FULL_SUITE_STEP_RE='root and companion proof|broad (hermetic|commerce)|library test suite|isolation matrix|hermetic (Rulestead|Rindle) proof'

for tool in gh jq; do
  command -v "$tool" >/dev/null 2>&1 || { echo "ci_cost_report: $tool is required" >&2; exit 2; }
done

run_id="${1:-}"
repo="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
if [ -z "$run_id" ]; then
  branch="$(git rev-parse --abbrev-ref HEAD)"
  run_id="$(gh run list --workflow "Crosswake CI" --branch "$branch" --limit 1 --json databaseId --jq '.[0].databaseId // empty')"
  [ -n "$run_id" ] || { echo "ci_cost_report: no Crosswake CI run found for branch $branch" >&2; exit 1; }
fi

run_json="$(gh api "repos/${repo}/actions/runs/${run_id}")"
jobs_json="$(gh api --paginate "repos/${repo}/actions/runs/${run_id}/jobs?per_page=100" --jq '.jobs[]' | jq -s '.')"

# One jq program: annotate each executed job, then print the table and the summary.
jq -r --argjson run "$run_json" --arg re "$FULL_SUITE_STEP_RE" \
  --argjson base_bill "$BASELINE_BILLABLE_MIN" --argjson base_wall "$BASELINE_WALL_MAX_MIN" \
  --argjson base_full "$BASELINE_FULL_SUITE_JOBS" '
  def tenths: . * 10 | round / 10;
  def mult: if any(.labels[]?; test("macos"; "i")) then 10
            elif any(.labels[]?; test("windows"; "i")) then 2 else 1 end;
  [ .[] | select(.started_at != null and .completed_at != null and .conclusion != "skipped")
    | ((.completed_at | fromdateiso8601) - (.started_at | fromdateiso8601)) as $secs
    | { name, minutes: ($secs / 60), runner: ((.labels // []) | join(",")),
        billable: (($secs / 60 | ceil) * mult),
        full: ([.steps[]? | select(.name | test($re; "i")) | select(.conclusion == "success" or .conclusion == "failure")] | length > 0) } ]
  | sort_by(-.minutes) as $jobs
  | "Crosswake CI run \($run.id): \($run.status)/\($run.conclusion // "n/a") head \($run.head_sha[0:8]) attempt \($run.run_attempt)",
    "",
    "minutes\tbillable\trunner\tjob",
    ($jobs[] | "\(.minutes | tenths)\t\(.billable)\t\(.runner)\t\(.name)"),
    "",
    ($jobs | map(.billable) | add // 0) as $bill
    | ($jobs | map(select(.full)) | length) as $full
    | (($run.updated_at | fromdateiso8601) - ($run.run_started_at | fromdateiso8601)) as $wall
    | "total billable minutes   : \($bill)  (baseline about \($base_bill))",
      "wall clock               : \($wall / 60 | tenths) min  (baseline 20-\($base_wall) min)",
      "critical-path job        : \($jobs[0].name) \($jobs[0].minutes | tenths) min",
      "jobs with a full-suite step: \($full)  (baseline about \($base_full); step-name heuristic)",
      "advisory only: flag new duplicated full-suite runs or jobs with no dependency cache; never a merge gate."
' <<<"$jobs_json" | awk -F'\t' 'NF > 1 { printf "%-8s %-9s %-15s %s\n", $1, $2, $3, $4; next } { print }'
