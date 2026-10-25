---
phase: 175-rehearsal-and-publish
plan: 18
subsystem: release-evidence
tags: [partial-release, maven-recovery, registry-verification, candidate-preflight]
requires:
  - phase: 175-14
    provides: "Immutable 0.2.3 partial-release record and consumed Gate 2 authorization"
provides:
  - "Fresh independently observed 0.2.3 Hex/iOS/Maven state and non-reusable authorization record"
  - "Exact Maven recovery guard disposition and PR #201 full-preflight candidacy facts"
affects: [175-19, release-recovery]
actuals:
  tokens: 4264
  tasks: 2
  commits: 2
plan_head_before: 28bb72d7168bee8981fa4831982fcdf950c5b0d8
commits: 2
tech-stack:
  added: []
  patterns: [read-only-registry-reconciliation, exact-identity-candidate-classification]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-RECOVERY-TRIAGE.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-recovery-triage.json
  modified: []
key-decisions:
  - "Keep core 0.2.3 PARTIAL: Hex and iOS are present, Maven Central returns 404, and internal Portal state remains UNKNOWN."
  - "The Phase 168-only Maven recovery identity does not authorize 0.2.3; do not dispatch recovery or retry."
  - "PR #201 is CANDIDATE_FOR_FULL_PREFLIGHT only; it does not provide Gate 2 or publish authority."
requirements-completed: []
coverage:
  - id: D1
    description: "0.2.3 workflow, recovery, and independent registry facts remain distinct and identity-bound."
    verification:
      - kind: other
        ref: "jq -e 175-recovery-triage.json task-1 predicate"
        status: pass
      - kind: other
        ref: "Read-only GitHub, Hex, iOS mirror, and Maven Central queries"
        status: pass
    human_judgment: false
  - id: D2
    description: "Maven authority, REL-12, and PR #201 exact candidate eligibility are recorded without granting authorization."
    verification:
      - kind: other
        ref: "jq -e 175-recovery-triage.json task-2 predicate"
        status: pass
      - kind: other
        ref: "elixir script/check_release_workflow_integrity.exs (76/76 checks)"
        status: pass
      - kind: other
        ref: "script/check_release_runbook_ancestry.sh against exact remote base and head OIDs"
        status: pass
    human_judgment: false
duration: 15m
completed: 2026-09-24
status: complete
---

# Phase 175 Plan 18: Read-Only Recovery Triage Summary

The 0.2.3 release remains an honest partial, its old one-way authorization is spent, and PR #201 is only eligible to begin a separate fresh preflight.

## Performance

- **Duration:** 15m (from first timestamped external observation)
- **Started:** 2026-09-24T01:50:15Z
- **Completed:** 2026-09-24T02:05:29Z
- **Tasks:** 2
- **Files modified:** 3 (two triage outputs and this summary)

## Accomplishments

- Re-queried ordinary Release Please run `35898407350`, separate iOS recovery run `35926844126`, and Hex/iOS/Maven independently. Hex `crosswake@0.2.3` and the matching iOS tag are present; the exact Maven POM remains HTTP `404`.
- Recorded Central's internal deployment state as `UNKNOWN`: there was no local Portal credential or deployment ID for a read-only lookup. The public `404` was not used to infer Portal state.
- Confirmed the exact Maven recovery path remains pinned to a different Phase 168 transaction. Re-verified REL-12 and classified PR #201 / `0.2.4` as `CANDIDATE_FOR_FULL_PREFLIGHT` only, with no Gate 2 preparation or publish authority.
- Preserved REL-10 as historically `BREACHED` and the `publish fresh core 35809832762` authorization as consumed by PR #196's one ordinary graph.

## Task Commits

1. **Task 1: Reconcile 0.2.3 run, recovery, and all three public coordinates** — `343f062b` (docs)
2. **Task 2: Check whether Maven 0.2.3 has an exact authorized recovery route** — `8b32c436` (docs)

## Files Created/Modified

- [175-RECOVERY-TRIAGE.md](<home>/projects/crosswake/.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-RECOVERY-TRIAGE.md) — human-readable partial-release and successor-candidate disposition.
- [175-recovery-triage.json](<home>/projects/crosswake/.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-recovery-triage.json) — normalized run, registry, recovery-authority, REL-12, and PR #201 facts.

## Decisions Made

- Public absence and Central's internal deployment state are separate facts; internal state remains `UNKNOWN`.
- No 0.2.3 recovery, job retry, tag movement, merge, or publish is authorized by this plan.
- PR #201 may proceed only to its own fresh Plan 175-19 full preflight and rehearsal; this record is not approval to merge or publish.

## Deviations from Plan

None. The conditional Portal-status query was unavailable because no local Portal credentials or deployment ID were present, so the plan's fail-closed `UNKNOWN` disposition was recorded.

## Issues Encountered

- The sandbox denied writes to `.git` metadata on the initial commit attempt. A narrowly scoped escalation allowed the two normal task commits; only Plan 175-18 outputs were staged.
- The pre-existing dirty `STATE.md`, `ROADMAP.md`, requirements file, and other planning artifacts were left untouched. The active state already records the Plan 175-18 → 175-19 sequence; no project-position change was made by this evidence-only plan.

## User Setup Required

None.

## Next Phase Readiness

Plan 175-19 can begin its own fresh full preflight and rehearsal for PR #201 while the exact observations remain current. Re-query candidate OIDs, CI, policy, runbook ancestry, and all registry absences during that plan; this candidate label is not Gate 2 readiness. The unresolved 0.2.3 Maven partial remains separate and requires its own reviewed exact authority before any mutation.

## Self-Check: PASSED

- Both declared triage output files exist and parse.
- Task commits `343f062b` and `8b32c436` exist in repository history.
- Task 1 and Task 2 verification predicates passed; the workflow-integrity scanner emitted 76/76 passing checks; exact base/head ancestry checks passed; `git diff --check` passed.

---
*Phase: 175-rehearsal-and-publish*  
*Status: complete*
