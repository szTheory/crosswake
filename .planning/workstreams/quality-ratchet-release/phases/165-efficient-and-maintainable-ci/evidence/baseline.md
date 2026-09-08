# Phase 165 pre-change CI evidence

Captured source: `e8efdb474af802b9ee1daf3450615eabbf9e1419`

SEED-007 is historical context only. Timing is descriptive and is not a merge threshold.

Exact per-job queue time: **not exposed** by the retained API fields.

## Source commands

- Source command: `gh api repos/szTheory/crosswake/actions/runs?branch=main&per_page=20`
- Source command: `gh api repos/szTheory/crosswake/actions/runs/{run_id}/jobs?per_page=100`

## documentation_only_pr

Criteria: pull_request run at the captured source SHA whose validated diff is documentation_only

Sample count: 0

Status: not measured (cohort_unavailable).

| Metric | Result |
| --- | --- |
| Workflow start delay | not measured (cohort_unavailable) |
| Job execution | not measured (cohort_unavailable) |
| Critical path | not measured (cohort_unavailable) |
| Aggregate runner time | not measured (cohort_unavailable) |

## full_proof_executable_pr

Criteria: pull_request run at the captured source SHA whose validated diff includes executable content

Sample count: 0

Status: not measured (cohort_unavailable).

| Metric | Result |
| --- | --- |
| Workflow start delay | not measured (cohort_unavailable) |
| Job execution | not measured (cohort_unavailable) |
| Critical path | not measured (cohort_unavailable) |
| Aggregate runner time | not measured (cohort_unavailable) |

## main_bound_automation

Criteria: push, schedule, or workflow_dispatch run on the captured default-branch source SHA before Phase 165 topology mutation

Sample count: 10

| Metric | Result |
| --- | --- |
| Workflow start delay | observed; sample count 10; median 0 ms; range 0-0 ms |
| Job execution | observed; sample count 10; median 63000 ms; range 5000-2475000 ms |
| Critical path | observed; sample count 10; median 66000 ms; range 8000-2151000 ms |
| Aggregate runner time | observed; sample count 10; median 63 s; range 5-2475 s |
