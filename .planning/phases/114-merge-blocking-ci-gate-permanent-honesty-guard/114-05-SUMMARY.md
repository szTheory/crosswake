---
phase: 114-merge-blocking-ci-gate-permanent-honesty-guard
plan: "05"
subsystem: ci
tags: [ci, branch-protection, gate, registration, bash, shell]
dependency_graph:
  requires:
    - ".github/workflows/offline-sync-e2e-gate.yml (four-job aggregator topology from plan 114-01)"
  provides:
    - "script/register-e2e-gate.sh (GATE-01 registration deliverable D-06)"
    - "gh api PATCH one-liner + ordering runbook in workflow header"
  affects:
    - "Branch protection required-check registration (maintainer runs out-of-band)"
    - "Workflow header documentation"
tech_stack:
  added: []
  patterns: ["GET-then-replace branch protection mutation", "green-first preflight (exit 2 guard)", "DRY_RUN idempotent script"]
key_files:
  created:
    - "script/register-e2e-gate.sh"
  modified:
    - ".github/workflows/offline-sync-e2e-gate.yml (replaced placeholder comment with PATCH runbook)"
decisions:
  - "GET-then-replace: script GETs live required_status_checks before building payload — never hardcodes checks array, so checks added later are always preserved"
  - "Green-first preflight exits 2 before PATCH: refuses to register until merge-blocking-offline-sync-e2e has a successful run on main, avoiding the Expected-Waiting deadlock"
  - "DRY_RUN=1 path exits 0 after printing desired JSON, before any PATCH or preflight, enabling safe local preview"
  - "Granular required_status_checks endpoint (not full PUT .../protection) leaves enforce_admins and reviews untouched"
  - "unique_by(.context) makes repeated registration runs idempotent"
metrics:
  duration: "~2 minutes"
  completed: "2026-06-18T06:59:20Z"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 2
status: complete
---

# Phase 114 Plan 05: GATE-01 Registration Script + Workflow Runbook Summary

**One-liner:** Idempotent register-e2e-gate.sh with GET-then-replace + green-first preflight (exit 2) + DRY_RUN support, plus gh api PATCH one-liner and ordering runbook as a workflow comment.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Author register-e2e-gate.sh (GET-then-replace + green-first preflight) | b2496e5 | script/register-e2e-gate.sh |
| 2 | Add gh api PATCH comment + ordering runbook to workflow header | fb4c379 | .github/workflows/offline-sync-e2e-gate.yml |

## What Was Built

### Task 1: register-e2e-gate.sh

`script/register-e2e-gate.sh` is a parameterized, idempotent bash script for GATE-01 registration (D-06). Key behaviors:

**Parameters** (all overridable via env): `REPO` (default `szTheory/crosswake`), `BRANCH` (default `main`), `NEW_CHECK` (default `merge-blocking-offline-sync-e2e`), `ACTIONS_APP_ID` (default `15368`), `OLD_CHECK` (default `e2e-offline-sync`), `DRY_RUN` (default `0`).

**GET-then-replace**: GETs `repos/${REPO}/branches/${BRANCH}/protection/required_status_checks` then builds the desired payload with jq: keeps `strict` from the live value; maps current checks dropping OLD_CHECK; appends `{context: NEW_CHECK, app_id: ACTIONS_APP_ID}`; applies `unique_by(.context)` for idempotency. Never hardcodes the checks array — the two existing required checks ("merge-blocking rulestead proof (hermetic)" and "brand-structural") are preserved from live state.

**DRY_RUN path**: If `DRY_RUN=1`, prints the desired JSON and exits 0 before any preflight or PATCH. Enables safe local preview.

**Green-first preflight** (T-114-12 mitigation): Probes `repos/${REPO}/commits/${BRANCH}/check-runs` with `jq -e` for any check-run where `name==NEW_CHECK and conclusion=="success"`. If none found, prints a REFUSING message with ordering instructions and exits 2 — never proceeds to the PATCH. This prevents the "Expected — Waiting for status" deadlock that would freeze every open PR.

**PATCH**: Uses `gh api -X PATCH` against the granular `required_status_checks` endpoint (not the full `PUT .../protection`), leaving `enforce_admins` and review requirements untouched (T-114-14 mitigation). Prints the resulting `{strict, checks}` after success.

### Task 2: Workflow Header Comment

Replaced the `[placeholder: plan 114-05 will paste ...]` comment in `.github/workflows/offline-sync-e2e-gate.yml` with:
- The three-step ordering runbook: merge PR → green on main → run `script/register-e2e-gate.sh`
- The equivalent gh api PATCH one-liner (for audit/reference)
- A note that the two existing required checks and `strict: true` are preserved
- An explanation of why the granular endpoint is used

No new jobs or steps were added — the four-job topology from plan 114-01 is unchanged.

## Threat Mitigations Applied

| Threat | Mitigation | Evidence |
|--------|------------|---------|
| T-114-12: premature required-check deadlock | Green-first preflight exits 2 before PATCH | Lines 50-61 of register-e2e-gate.sh: jq -e check-runs probe + exit 2 |
| T-114-13: hardcoded checks array drops existing checks | GET-then-replace with unique_by(.context) | Lines 15-28: gh api GET + jq map(select)+append+unique_by |
| T-114-14: full PUT clobbers enforce_admins/reviews | Granular required_status_checks endpoint only | Line 8: EP uses /protection/required_status_checks (not /protection) |

## Deviations from Plan

None — plan executed exactly as written. The script lifted from RESEARCH-SYNTHESIS §4 and matches all acceptance criteria: `bash -n` passes, executable bit set, GET-then-replace, unique_by(.context), DRY_RUN exits 0 before PATCH, green-first preflight exits 2. The workflow comment replaces the placeholder with the exact one-liner and ordering runbook.

## Known Stubs

None. The registration script is complete and correct. The branch-protection mutation itself is intentionally left for the maintainer to run out-of-band after the aggregator goes green on main (harness-blocked by design — GATE-01 acceptance is "script + preflight + workflow comment exist and are correct," not "branch protection is mutated").

## Threat Flags

None. This plan adds a shell script and a YAML comment; no new network endpoints, auth paths, file access patterns, or schema changes introduced.

## Self-Check: PASSED

- `script/register-e2e-gate.sh` exists: FOUND
- `bash -n script/register-e2e-gate.sh` parses clean: CONFIRMED
- Script is executable (`test -x`): CONFIRMED
- `required_status_checks` in script: FOUND
- `unique_by(.context)` in script: FOUND
- `exit 2` in script: FOUND
- `DRY_RUN` in script: FOUND
- `e2e-offline-sync` (OLD_CHECK) in script: FOUND
- `merge-blocking-offline-sync-e2e` (NEW_CHECK) in script: FOUND
- `15368` (app_id) in script: FOUND
- Workflow references `register-e2e-gate.sh`: FOUND
- Workflow references `required_status_checks`: FOUND
- Four jobs in workflow (unchanged): CONFIRMED (guard-01-e2e-honesty, guard-02-prod-route-absence, e2e-proof, merge-blocking-offline-sync-e2e)
- Commit b2496e5 exists: CONFIRMED (Task 1)
- Commit fb4c379 exists: CONFIRMED (Task 2)
