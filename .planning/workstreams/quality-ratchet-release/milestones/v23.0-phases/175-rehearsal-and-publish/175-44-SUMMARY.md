---
phase: 175-rehearsal-and-publish
plan: 44
subsystem: release
tags: [rel17, repair-lineage, protected-main, release-please]
requires:
  - phase: 175-43
    provides: Live merge authorization trailer validation
provides:
  - Exact protected-main repair PR and same-head passing CI evidence
  - Explicit scanner guards for both current-main release contracts
  - A verified protected repair merge and matching no-publication Release Please run
affects: [175-45, quality-ratchet-release]
actuals:
  tokens: 15200
  tasks: 1
  commits: 2
tech-stack:
  added: []
  patterns: [main-based repair reconciliation, exact release authorization selectors]
key-files:
  created:
    - evidence/175-rel17-repair-gate.json
    - script/release_candidate/linked_release_authorization.sh
    - test/crosswake/proof/phase175_linked_authorization_test.exs
  modified:
    - script/check_release_workflow_integrity.exs
    - lib/crosswake/release_candidate/evidence_live.ex
    - test/crosswake/proof/phase175_release_recovery_test.exs
    - test/crosswake/release_candidate/evidence_live_test.exs
    - docs/COMPANION-PUBLISH-RUNBOOK.md
key-decisions:
  - Keep current-main release classification and dispatch behavior; scope scanner checks to the Release Please proposal job and Maven drill.
  - Keep the fresh 0.2.7 candidate blocked because required iOS mirror parity CI found the prior v0.2.6 tag missing.
patterns-established:
  - "Release dispatch isolation: verify job-scoped push/manual predicates instead of banning unrelated workflow_dispatch triggers."
requirements-completed: []
coverage:
  - id: D1
    description: Exact main-based repair PR #218 merged normally with complete policy, repair-only diff, and passing same-head CI; its matching ordinary run published nothing.
    requirement: REL-17
    verification:
      - kind: integration
        ref: "Crosswake CI run 36422502986: 49/49 jobs passed on head 63b278ee27355ef7cf40cdf2a23e67de8879d02b"
        status: pass
      - kind: unit
        ref: "MIX_ENV=test mix test test/crosswake/release_candidate/evidence_live_test.exs test/crosswake/proof/phase175_linked_authorization_test.exs test/crosswake/proof/phase175_release_recovery_test.exs --max-cases 1: 43 tests, 0 failures"
        status: pass
      - kind: other
        ref: "elixir script/check_release_workflow_integrity.exs: 98/98 checks; repair-gate JSON predicates and seven-file PR diff inspection passed"
        status: pass
    human_judgment: false
duration: "about 210min across the initial halt and resumed PR validation"
completed: 2026-09-28
status: halted
---

# Phase 175 Plan 44: Repair Lineage and Successor Candidate

**PR #218's protected merge and no-publication run are verified; fresh candidate PR #219 is blocked by a failed required iOS mirror parity check for v0.2.6.**

## Performance

- **Duration:** About 210 minutes across the initial halt and resumed PR validation.
- **Completed:** 2026-09-28
- **Tasks completed:** Task 1; Task 2 stopped at candidate CI failure; Task 3 was not run.
- **Repair PR files:** 7.

## Accomplishments

- Opened [PR #218](https://github.com/szTheory/crosswake/pull/218) from `fix/rel17-linked-auth-repair-2026-09-28` against protected `main` at `998742856a37a97ae7247f6c532f9c154ea20885`. The reviewed PR contains exactly seven repair files and no workflow-file changes.
- Preserved the value-based release classifier and added an exact linked Hex authorization selector check before the shared evidence gate and REL-17 context handoff.
- Corrected Maven isolation at the job boundary: the Release Please proposal job must be push-only, its lockstep assertion remains manual-only, and the separate Maven fire drill remains manual-only. The separate iOS mirror authority path remains intact.
- Recorded exact PR/base/head/tree, the complete branch-protection and ruleset policy, all 49 successful same-head CI jobs, and the repair-only diff in `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-rel17-repair-gate.json`.
- Focused local validation passed: 43 tests, 0 failures; the release workflow integrity scanner emitted 98/98 checks with 0 failures.
- PR #218 merged normally at `e51698528dc667ef89beb951e4eb1ec91da74981`. Matching push run `36437860644` succeeded on that exact merge; all eight publishers were skipped, the approved-candidate guard and linked rollup succeeded, and linked publication was absent.
- Release Please created fresh core candidate PR #219 for `0.2.7`. Its exact-head required CI run `36438452825` completed FAILURE because `ios-mirror-parity-proof` found source tag `ios-core-v0.2.6` but no `v0.2.6` tag on the SwiftPM mirror. The aggregate `Crosswake CI` check failed. Hex/iOS/Maven `0.2.7` coordinates remain absent.

## Task Commits

- `49bdafeb` — linked release authorization repair and focused proofs.
- `63b278ee` — push-only Release Please scanner predicate and dispatch mutation proof.

## Files Created/Modified

- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-rel17-repair-gate.json` — exact protected merge, current policy, repair-only file list, and matching no-publication run.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-rel17-successor-candidate.json` — exact candidate PR #219 identity, completed CI failure, tag gap, policy, runbook ancestry, and 0.2.7 target absence.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-REL17-SUCCESSOR-CANDIDATE.md` — readable candidate blocker and next-step boundary.
- PR #218 — linked trailer capture validation, exact Hex leg authorization helper, runbook instructions, scanner checks, and regression tests.

## Decisions Made

- Keep unrelated manual dispatches available. The scanner checks the Release Please proposal job and the lockstep job directly rather than rejecting every `workflow_dispatch` in the Release Please file.
- Advanced `repair.state` to `LANDED_VERIFIED` only after fetching the exact normal merge parents/tree, current strict protection, runbook ancestry, and complete matching run/job graph.
- Do not bypass the missing `v0.2.6` mirror tag or start rehearsals on a candidate without successful required CI. The consumed 0.2.6 authorization cannot cover a new tag action.

## Deviations from Plan

The resumed repair added the explicit push-only Release Please proposal check and a seeded mutation test after comparing the scanner against Task 1's exact acceptance criteria. This completes the Maven-dispatch correction while preserving the protected-main workflow behavior.

## Issues Encountered

- The first PR head passed local checks, but acceptance review showed that the scanner needed to assert the Release Please proposal job's push-only guard, not only Maven workflow separation. Added that assertion and mutation proof, pushed a second commit, and waited for fresh CI on the updated head. The superseded run was cancelled; the final head's run passed 49/49 jobs.

## User Setup Required

User decision required: keep the successor release held, or scope a distinct, fresh authorization path for the exact missing 0.2.6 iOS mirror tag. The old Gate 2 token is consumed and cannot authorize a tag push.

## Next Phase Readiness

Plan 175-44 is halted at the fresh successor candidate's failed required CI. The repair merge gate
is clear, but candidate PR #219 cannot proceed because source tag `ios-core-v0.2.6` points at
`998742856a37a97ae7247f6c532f9c154ea20885` while the SwiftPM mirror lacks `v0.2.6`. The CI run
`36438452825` and exact cause are recorded in `evidence/175-rel17-successor-candidate.json`.
Task 3 was not run; Plans 175-45 through 175-48 remain blocked. The 0.2.6 Gate 2 token remains
consumed. No retry, recovery, tag push, Gate 2 decision, or publication occurred in this continuation.

Keep this canonical halted summary in place. Do not rename it to hide the current blocker or rerun
`$gsd-execute-phase 175 --ws quality-ratchet-release` before a separately scoped remedy is decided
and the exact candidate has successful required CI. After the user chooses a route, plan any fresh
tag-remediation authority with `$gsd-plan-phase 175 --ws quality-ratchet-release`.

## Self-Check: PASSED

- The repair evidence matches PR #218's exact base, head, tree, current required-check policy, seven-file diff, protected merge OID, and exact matching no-publication run.
- Both scanner corrections have focused regression coverage, and the release workflow scanner passes all 98 declared checks.
- The successor evidence records exact PR #219 identity, completed failed required CI, prior missing mirror tag, and absence of 0.2.7 targets; no Gate 2 or tag-push authority was created.

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-09-28 (halted at candidate CI; separate iOS tag decision required)*
