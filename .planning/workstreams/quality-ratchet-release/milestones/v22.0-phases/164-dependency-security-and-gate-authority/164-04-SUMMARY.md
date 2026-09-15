---
phase: 164-dependency-security-and-gate-authority
plan: "04"
subsystem: infra
tags: [github-actions, aggregation, fail-closed, exunit, python]

requires:
  - phase: 164-01
    provides: Patched dependency authority and the first stable Phase 164 merge-gate producer
provides:
  - Exact named-aggregator leaf parity with deterministic missing and unexpected diagnostics
  - Credential-free closed result policy spanning success, explicit irrelevance, and every fail-closed class
  - One retained action-backed CI matrix whose complete outcome map is awaited by the local policy harness
affects: [164-gate-authority, 165-ci-efficiency, required-aggregators]

actuals:
  tokens: 5961
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns:
    - Exact expected-versus-declared leaf set equality before runtime result evaluation
    - Standard-library policy self-test shared with one final GitHub Actions outcome assertion

key-files:
  created:
    - script/check_aggregator_result_semantics.py
  modified:
    - test/crosswake/proof/phase134_native_gate_blocking_proof_test.exs
    - .github/workflows/aggregator-negative-control.yml
    - .planning/workstreams/quality-ratchet-release/phases/164-dependency-security-and-gate-authority/164-VALIDATION.md

key-decisions:
  - "Aggregator membership is proven as exact set equality before alls-green evaluates any result; ordering alone is normalized."
  - "The local evaluator owns the exhaustive result vocabulary, while the retained CI action supplies one exact named outcome record for every class."
  - "Only the specifically named irrelevant skipped leaf is neutral; every other skipped, non-success, unknown, empty, or missing value fails closed."

patterns-established:
  - "Structural-before-semantic aggregation: exact needs parity prevents omitted work from disappearing before result evaluation."
  - "Awaited outcome matrix: intentional action failures are step-local and one final harness invocation validates every captured outcome."

requirements-completed: [CIG-04]

coverage:
  - id: D1
    description: "Every named required aggregator declares exactly its expected leaves, with missing and unexpected additions rejected deterministically."
    requirement: CIG-04
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase134_native_gate_blocking_proof_test.exs#exact aggregator leaf parity"
        status: pass
    human_judgment: false
  - id: D2
    description: "The complete result vocabulary passes only success and one explicit irrelevant skip, while CI awaits the same exact outcome contract."
    requirement: CIG-04
    verification:
      - kind: integration
        ref: "python3 script/check_aggregator_result_semantics.py --self-test"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase134_native_gate_blocking_proof_test.exs#aggregator negative control awaits every closed-policy action outcome"
        status: pass
    human_judgment: false

duration: 6 min
completed: 2026-08-28
status: complete
---

# Phase 164 Plan 04: Fail-Closed Aggregator Semantics Summary

**Exact aggregator leaf parity and an 11-class credential-free result matrix now prevent omitted, unknown, cancelled, or otherwise non-success work from becoming green.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-08-28T19:38:39Z
- **Completed:** 2026-08-28T19:44:39Z
- **Tasks:** 2
- **Files modified:** 3 implementation files, plus summary and validation metadata

## Accomplishments

- Replaced subset-only aggregator wiring proof with exact normalized set equality and direct reorder, missing-leaf, and unexpected-leaf fixtures carrying workflow and job provenance.
- Added one Python-standard-library evaluator that executes success, failure, cancelled, disallowed skipped, explicit-irrelevant skipped, timed out, action required, stale, unknown, empty, and missing exactly once.
- Expanded the existing negative-control job in place so every intentional action failure is step-local and one final harness invocation awaits the complete named outcome map.
- Preserved all sibling aggregator identities and topology: workflow count stayed 41, sibling workflow diffs stayed empty, and no failure exemption input exists.

## Task Commits

1. **Task 1 RED:** `ead90076` — failing missing/unexpected exact-parity fixtures
2. **Task 1 GREEN:** `a1680f1e` — exact named-aggregator leaf set equality
3. **Task 2 RED:** `21d449d5` — failing complete result matrix and outcome-record controls
4. **Task 2 GREEN:** `5344d7cf` — closed evaluator and awaited action-backed workflow matrix

## Files Created/Modified

- `test/crosswake/proof/phase134_native_gate_blocking_proof_test.exs` — exact parity fixtures, provenance diagnostics, and complete workflow-outcome structural assertions.
- `script/check_aggregator_result_semantics.py` — credential-free closed evaluator, canonical self-test, and exact `--assert-outcomes` mode.
- `.github/workflows/aggregator-negative-control.yml` — retained single producer with all 11 action arms and one awaited harness assertion.
- `.planning/workstreams/quality-ratchet-release/phases/164-dependency-security-and-gate-authority/164-VALIDATION.md` — Plan 164-04 rows and Wave 0 artifacts marked green.

## Decisions Made

- Kept membership and value authority separate: exact `needs` parity runs structurally because a missing dependency can never reach `toJSON(needs)`.
- Kept GitHub-needs values and API/reporting-boundary values in one closed local evaluator; statuses GitHub does not emit through `needs` still fail closed when observed at another boundary.
- Allowed visible neutral behavior only for the exact synthetic leaf named by `allowed-skips`; no named required aggregator gained a skip or failure exemption.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first structural assertion compared `Regex.scan/2` against a flat string list instead of its list-of-captures return shape. The focused test exposed it immediately; the assertion shape was corrected before the Task 2 GREEN commit.
- The shared branch advanced with concurrent Plan 164-03 commits during execution. Only the four owned 164-04 paths were staged, and unrelated worktree files were preserved.

## TDD Gate Compliance

- Task 1 RED `ead90076` failed on both missing diagnostic provenance and the previously accepted unexpected leaf; GREEN `a1680f1e` passed 9/9 focused tests.
- Task 2 RED `21d449d5` failed across all unimplemented vocabulary and outcome-record cases; GREEN `5344d7cf` passed the five-test Python self-test and 10/10 focused ExUnit tests.

## Known Stubs

None.

## Threat Flags

None. The plan changed no endpoint, authentication path, schema, product file-access boundary, action dependency, or mobile proof surface.

## User Setup Required

None - all verification is credential-free and automated.

## Next Phase Readiness

- CIG-04 has executable membership and value authority ready for the Phase 164 aggregate gate.
- Phase 165 may optimize workflow topology only after the remaining Phase 164 plans complete, while preserving these stable leaf identities and fail-closed outcome assertions.

## Self-Check: PASSED

- All three implementation artifacts and the 164-04 summary exist on disk.
- All four TDD commits are present in repository history.
- Both 164-04 validation rows are green, and the summary carries `status: complete`.
- Final evidence passed the 11-class matrix, missing/inverted controls, 10/10 exact-parity tests, workflow YAML parse, sole-producer check, and scope-diff assertions.

---
*Phase: 164-dependency-security-and-gate-authority*
*Completed: 2026-08-28*
