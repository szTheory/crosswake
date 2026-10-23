---
phase: 175-rehearsal-and-publish
plan: 78
subsystem: release-evidence
tags: [rel-17, exunit, shell, release-proof]

requires:
  - phase: 175-77
    provides: Prior local post-merge gate and evidence fixture coverage
provides:
  - A sealed fake-provider process harness for real shell-to-Mix evidence gates across the publisher roster
  - A sanitized REL-17 path matrix that preserves unsupported cells as UNKNOWN
affects: [quality-ratchet-release, REL-17, Phase175 verification]

actuals:
  tokens: 15891
  tasks: 3
  commits: 6
  plan_head_before: 0c05008483a18bf5d3ec431087b6b5efb81df5ef
  plan_head_after: e2edc95ad5c5d557e260506a3ee1640fc6b9b5ed

tech-stack:
  added: []
  patterns:
    - Sealed fake-provider executables drive the production shell, Mix live task, capture, and validator chain
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-78-REL17-PATH-MATRIX.md
    - test/crosswake/proof/phase175_rel17_condition_paths_test.exs
  modified:
    - test/support/phase175_rel17_fixtures.ex
    - .planning/WINDOWS.md
key-decisions:
  - "Keep response-row, incomplete material-binding, final-guard execution, and workflow presence/order cells UNKNOWN where the local process proof did not establish them."
  - "Do not edit workflow YAML or final publication guards without a named failing mutation; the workflow scanner could not reach its checks."
requirements-completed: [REL-17]

coverage:
  - id: D1
    description: "Real shell-to-Mix process evidence covers 13 named publisher rows with fake-provider controls, changed condition cases, and isolated fake sinks."
    requirement: REL-17
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix test test/crosswake/release_candidate/evidence_live_test.exs test/crosswake/release_candidate/evidence_gate_test.exs test/crosswake/proof/phase175_rel17_condition_paths_test.exs --exclude matrix --max-cases 1"
        status: pass
    human_judgment: false
  - id: D2
    description: "A sanitized 13-row/six-condition matrix records proven and unknown boundaries while retaining all release holds."
    requirement: REL-17
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix test test/crosswake/proof/phase175_rel17_condition_paths_test.exs --only matrix --max-cases 1"
        status: pass
      - kind: other
        ref: "mix format --check-formatted test/crosswake/proof/phase175_rel17_condition_paths_test.exs test/support/phase175_rel17_fixtures.ex"
        status: pass
    human_judgment: false

duration: 170min
completed: 2026-10-04
status: halted
---

# Phase 175 Plan 78: Rehearsal and Publish Summary

**Real shell-to-Mix evidence tests cover 13 publisher rows, while a sanitized matrix keeps unverified workflow and identity bindings UNKNOWN.**

## Performance

- **Duration:** 170 min
- **Started:** 2026-10-04T15:45:00Z
- **Completed:** 2026-10-04T18:35:43Z
- **Tasks:** 3
- **Files modified or created:** 4, excluding this summary

## Accomplishments

- Added a strict fake-provider process harness that runs the production shell gate, real Mix live task, capture adapter, and validator. Valid controls reach only their row-specific fake sink; tested invalid or absent facts produce zero sinks.
- Recorded the exact 13 publisher rows and six REL-17 condition columns in one sanitized matrix. Response-row independence, some per-row material bindings, final publication-guard execution, and workflow presence/order remain UNKNOWN.
- Preserved the release hold and required dispositions. Logged the unavailable workflow verification as open ledger entry 36; no publication workflow or final guard was changed.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED:** `42b2325d` — `test(175-78): require process fixture writer`
2. **Task 1 GREEN:** `d62abfc4` — `feat(175-78): add real live-gate process harness`
3. **Task 1 fixture correction:** `45a60272` — `fix(175-78): complete isolated runner contract`
4. **Task 2 RED:** `40ebb36a` — `test(175-78): require complete publisher roster`
5. **Task 2 GREEN:** `c771c6e0` — `feat(175-78): exercise publisher path mutations`
6. **Task 3:** `e2edc95a` — `test(175-78): record REL-17 path matrix`

The plan metadata commit contains this summary.

## Files Created/Modified

- `test/crosswake/proof/phase175_rel17_condition_paths_test.exs` — process-path and matrix contract assertions.
- `test/support/phase175_rel17_fixtures.ex` — strict process fixtures and isolated fake sinks.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-78-REL17-PATH-MATRIX.md` — per-row proof status, limitations, and required dispositions.
- `.planning/WINDOWS.md` — open unrun-verification entry for the missing scanner input.

## Decisions Made

- Kept response-row independence, incomplete identity bindings, final guard execution, and workflow presence/order UNKNOWN where no exact local assertion established them.
- Left workflow YAML, final guards, and the scanner unchanged. The plan limits repairs to named defects in its declared files, and the scanner failed before reaching its named checks.

## Deviations from Plan

**[Out-of-scope blocker] Workflow scanner input is absent**

- **Found during:** Task 3
- **Issue:** `script/check_release_workflow_integrity.exs` reads `script/release_candidate/assert_candidate_receipt_artifact.sh` at line 2004, but that file is absent and not tracked in this checkout. The scanner and its dependent mutation tests stop before the REL-17 assertions.
- **Disposition:** Kept every publisher's workflow presence/order cell UNKNOWN, recorded the failure in `.planning/WINDOWS.md` entry 36, and made no out-of-scope source or workflow change.
- **Verification:** Direct scanner invocation failed at the missing input. The combined Task 3 suite ran 40 tests and reported 14 scanner-dependent failures; the focused matrix test passed.
- **Commit:** `e2edc95a`

**Total deviations:** 1 unresolved pre-existing verification blocker.  
**Impact:** Local process-gate evidence and the sanitized matrix are committed. Workflow structure and several identity/runtime boundaries remain unproven, so REL-17 stays OPEN and the release hold stays ACTIVE.

## Verification Results

- Task 1 and Task 2 focused process/evidence suite: **22 tests, 0 failures**.
- Task 3 focused matrix contract: **1 test, 0 failures**.
- Elixir formatter check: **passed**.
- Shell syntax checks for the three named publication guards: **passed**.
- Workflow integrity scanner: **failed before REL-17 checks** because its required script input is absent.
- Combined Task 3 proof command: **40 tests, 14 failures**, all reported at the missing scanner input before named workflow assertions could run.

## Issues Encountered

The matrix proves the local process path for the conditions and bindings listed as PROVEN. It does not prove every final publisher wrapper, independent response-row mutation, all authorization/material bindings per row, or workflow ordering. Those cells remain UNKNOWN and require a fresh scoped discussion/plan. No release, CI, registry, or publication action was run.

## User Setup Required

None.

## Next Phase Readiness

Plan 78 is halted after its local evidence tasks because the required workflow scanner verification cannot reach its named checks. Restore the missing scanner input in a fresh scoped discussion/plan, then rerun the blocked verification before marking Plan 78 complete. Phase 175 remains incomplete. Preserve Plan55/Plan70 UNKNOWN, Plan76 terminal UNKNOWN_UNVERIFIABLE with authorization CONSUMED, REL-13 and REL-17 OPEN, candidate readiness BLOCKED, merge policy UNKNOWN, release hold ACTIVE, and Plans175-45–175-48 HELD. STATE.md and ROADMAP.md were left untouched as requested.

## Self-Check: PASSED

- Summary, matrix, process test, and fixture files exist.
- All six task commit hashes are present in git history.
- Broken-windows ledger entry 36 is present.
