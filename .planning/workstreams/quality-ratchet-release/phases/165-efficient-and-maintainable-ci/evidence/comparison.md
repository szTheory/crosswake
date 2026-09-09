# Phase 165 descriptive CI comparison

Before source: `e8efdb474af802b9ee1daf3450615eabbf9e1419`
After source: `cec20fbd71ca3319c7d7dfbeb439d1f74545e9c8`

Results are descriptive. Unmatched cohorts remain not measured; exact per-job queue time is not exposed.
No causal conclusion is supported by these observations, and no timing value is a merge threshold.

## Source commands

- Before source command: `gh api repos/szTheory/crosswake/actions/runs?branch=main&per_page=20`
- Before source command: `gh api repos/szTheory/crosswake/actions/runs/{run_id}/jobs?per_page=100`
- After source command: `gh api repos/szTheory/crosswake/actions/runs?branch=main&per_page=20`
- After source command: `gh api repos/szTheory/crosswake/actions/runs/{run_id}/jobs?per_page=100`

## documentation_only_pr

Comparison status: **not measured (`not_measured`: cohort_unavailable)**.

Before criteria: pull_request run at the captured source SHA whose validated diff is documentation_only

After criteria: pull_request run at the captured source SHA whose validated diff is documentation_only

Sample count: before 0; after 0.

### Workflow/job/check counts

- Before workflows: 0 (not measured)
- After workflows: 0 (not measured)
- Before jobs: not measured (cohort_unavailable)
- After jobs: not measured (cohort_unavailable)
- Before checks: not measured (cohort_unavailable)
- After checks: not measured (cohort_unavailable)

### Runner classes

- Before: not measured (cohort_unavailable)
- After: not measured (cohort_unavailable)

### Timing

| Metric | Before | After |
| --- | --- | --- |
| Workflow delay | not measured (cohort_unavailable) | not measured (cohort_unavailable) |
| Job execution | not measured (cohort_unavailable) | not measured (cohort_unavailable) |
| Critical path | not measured (cohort_unavailable) | not measured (cohort_unavailable) |
| Runner time | not measured (cohort_unavailable) | not measured (cohort_unavailable) |

### Cache outcomes

- Before: not measured (cohort_unavailable)
- After: not measured (cohort_unavailable)

## full_proof_executable_pr

Comparison status: **not measured (`not_measured`: cohort_unavailable)**.

Before criteria: pull_request run at the captured source SHA whose validated diff includes executable content

After criteria: pull_request run at the captured source SHA whose validated diff includes executable content

Sample count: before 0; after 0.

### Workflow/job/check counts

- Before workflows: 0 (not measured)
- After workflows: 0 (not measured)
- Before jobs: not measured (cohort_unavailable)
- After jobs: not measured (cohort_unavailable)
- Before checks: not measured (cohort_unavailable)
- After checks: not measured (cohort_unavailable)

### Runner classes

- Before: not measured (cohort_unavailable)
- After: not measured (cohort_unavailable)

### Timing

| Metric | Before | After |
| --- | --- | --- |
| Workflow delay | not measured (cohort_unavailable) | not measured (cohort_unavailable) |
| Job execution | not measured (cohort_unavailable) | not measured (cohort_unavailable) |
| Critical path | not measured (cohort_unavailable) | not measured (cohort_unavailable) |
| Runner time | not measured (cohort_unavailable) | not measured (cohort_unavailable) |

### Cache outcomes

- Before: not measured (cohort_unavailable)
- After: not measured (cohort_unavailable)

## main_bound_automation

Comparison status: **not measured (`not_measured`: criteria_mismatch)**.

Before criteria: push, schedule, or workflow_dispatch run on the captured default-branch source SHA before Phase 165 topology mutation

After criteria: push, schedule, or workflow_dispatch run on the captured default-branch source SHA after Phase 165 topology mutation

Sample count: before 10; after 1.

### Workflow/job/check counts

- Before workflows: 10 (Phase 130 Proof, Phase 132 Proof, Phase 23 Proof, Phase 34 Proof, Phase 43 Proof, Phase 45 Proof, Phase 52 Proof, Phase 71 Proof, Required Checks Audit, See It Run Collateral)
- After workflows: 1 (Release Please)
- Before jobs: observed; sample count 10; median 2 jobs; range 1-3 jobs
- After jobs: observed; sample count 1; median 21 jobs; range 21-21 jobs
- Before checks: observed; sample count 10; median 2 checks; range 1-3 checks
- After checks: observed; sample count 1; median 21 checks; range 21-21 checks

### Runner classes

- Before: linux_hosted, mixed
- After: mixed

### Timing

| Metric | Before | After |
| --- | --- | --- |
| Workflow delay | observed; sample count 10; median 0 ms; range 0-0 ms | observed; sample count 1; median 0 ms; range 0-0 ms |
| Job execution | observed; sample count 10; median 63000 ms; range 5000-2475000 ms | observed; sample count 1; median 171000 ms; range 171000-171000 ms |
| Critical path | observed; sample count 10; median 66000 ms; range 8000-2151000 ms | observed; sample count 1; median 217000 ms; range 217000-217000 ms |
| Runner time | observed; sample count 10; median 63 s; range 5-2475 s | observed; sample count 1; median 171 s; range 171-171 s |

### Cache outcomes

- Before: not_measured (cache_outcome_unavailable)
- After: not_measured (cache_outcome_unavailable)
