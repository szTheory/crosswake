---
phase: 165-efficient-and-maintainable-ci
plan: 03
subsystem: ci
tags: [github-actions, cancellation, workflow-run, least-privilege, monotonic-policy]
requires:
  - phase: 165-efficient-and-maintainable-ci
    plan: 02
    provides: closed PR workflow identity, exact proof inventory, and repository-plus-PR concurrency
provides:
  - Pure strict-lower-run-ID cancellation policy with closed JSON dispositions
  - Deterministic adjacency, ambiguity, permutation, fork, pagination, and inversion fixtures
  - Default-branch requested-run controller with Actions-only write permission and no PR checkout
affects: [165-04, 165-09, 165-10]
actuals:
  tokens: 8303
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns:
    - Pure closed policy before privileged mutation
    - Immutable default-branch policy acquisition without PR checkout
    - Ordinary cancellation followed by bounded polling and force fallback
key-files:
  created:
    - script/select_obsolete_ci_runs.py
    - test/fixtures/ci/cancellation/cases.json
    - .github/workflows/cancel-obsolete-crosswake-ci.yml
    - test/crosswake/proof/phase165_ci_integrity_test.exs
  modified:
    - test/crosswake/proof/phase165_ci_policy_test.exs
key-decisions:
  - "Treat every malformed current run, candidate, identity, or incomplete page set as a closed invalid disposition with no selected IDs."
  - "Keep cancellation authority in a requested workflow_run controller with only actions: write; acquire selector bytes from the controller's immutable default-branch SHA and never check out PR code."
  - "Keep the controller non-authoritative until Plan 165-10 proves requested-event timing and live inversion behavior."
patterns-established:
  - "Cancellation boundary: only queued or in-progress runs with the same repository, workflow ID/name, event, and sole PR number and a strictly lower positive ID may be selected."
  - "Mutation boundary: ordinary cancel, bounded status polling, and force-cancel are unreachable unless the pure selector returns cancel_lower with a non-empty ID list."
requirements-completed: [CIP-02, CIP-04]
coverage:
  - id: D1
    description: Pure monotonic cancellation selection closes ambiguous inputs and concurrent inversion
    requirement: CIP-02
    verification:
      - kind: integration
        ref: python3 script/select_obsolete_ci_runs.py --self-test && mix test test/crosswake/proof/phase165_ci_policy_test.exs --only cancellation
        status: pass
    human_judgment: false
  - id: D2
    description: Trusted requested-run controller isolates Actions mutation from untrusted PR code
    requirement: CIP-04
    verification:
      - kind: integration
        ref: actionlint .github/workflows/cancel-obsolete-crosswake-ci.yml .github/workflows/crosswake-ci.yml && mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only cancellation_controller
        status: pass
    human_judgment: false
duration: 9 min
completed: 2026-09-07
status: complete
---

# Phase 165 Plan 03: Trusted Monotonic Obsolete-Run Cancellation Summary

**Strict-lower cancellation now runs through a pure closed selector and a least-privilege default-branch controller that never executes pull-request code.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-09-08T00:40:10Z
- **Completed:** 2026-09-08T00:49:08Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added a standard-library-only JSON selector that validates repository, workflow ID/name, event, sole PR number, positive bounded run IDs, candidate status, and complete pagination before selecting anything.
- Added sorted, duplicate-free fixtures for adjacency, empty input, fork collisions, identity mismatch, malformed/overflow IDs, missing or multiple PRs, incomplete pages, permutations, and two-controller inversion.
- Added a `workflow_run: requested` controller with only `actions: write`, immutable default-branch selector acquisition, no checkout, a hard selection gate, ordinary cancellation, bounded polling, and force-cancel only for a still-running selected lower ID.

## Task Commits

Each TDD task was committed with a failing contract before implementation:

1. **Task 1 RED: strict-lower cancellation policy contracts** - `c39a1462` (test)
2. **Task 1 GREEN: pure monotonic selector** - `40e59bca` (feat)
3. **Task 2 RED: trusted-controller structural contracts** - `de01408e` (test)
4. **Task 2 GREEN: requested-run cancellation controller** - `9c6ece85` (feat)
5. **Formatting: controller integrity proof** - `7d0e5679` (style)

## Files Created/Modified

- `script/select_obsolete_ci_runs.py` - Emits only `cancel_lower`, `no_op`, or `invalid` from fully validated JSON inputs.
- `test/fixtures/ci/cancellation/cases.json` - Stores deterministic negative, adjacency, ordering, and concurrent-inversion cases.
- `test/crosswake/proof/phase165_ci_policy_test.exs` - Executes the pure selector corpus through the Phase 165 policy gate.
- `.github/workflows/cancel-obsolete-crosswake-ci.yml` - Hosts the trusted requested-run controller and bounded mutation sequence.
- `test/crosswake/proof/phase165_ci_integrity_test.exs` - Rejects unsafe triggers, broader permissions, PR checkout, built-in cancellation, and mutation-before-selection.

## Decisions Made

- Repository, workflow ID and name, `pull_request` event, and exactly one PR number form the complete cancellation identity; branch names are never authority.
- Malformed or incomplete API state invalidates the entire selection instead of partially cancelling apparently valid rows.
- Completed matching runs are valid input but are not cancellable; only `queued` and `in_progress` strict-lower runs are selected.
- The controller remains explicitly non-authoritative until Plan 165-10 supplies the live requested-event timing and inversion evidence required by the flagged CIP-04 assumption.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test bug] Tightened cancellation endpoint ordering markers**
- **Found during:** Task 2 GREEN verification
- **Issue:** The structural test's broad `/cancel` marker matched the temporary `cancellation-selection.json` path before the mutation step.
- **Fix:** Matched the exact Actions run cancel and force-cancel endpoint fragments.
- **Files modified:** `test/crosswake/proof/phase165_ci_integrity_test.exs`
- **Verification:** The tagged controller test passed all four structural assertions.
- **Committed in:** `9c6ece85`

---

**Total deviations:** 1 auto-fixed Rule 1 test bug.
**Impact on plan:** The correction made the ordering proof precise without changing scope or production behavior.

## Issues Encountered

- The pre-existing `.tool-versions` edit names locally unavailable Erlang/Elixir builds. Mix verification used command-scoped installed versions (`Erlang 28.4.1`, `Elixir 1.19.5-otp-28`) without modifying or staging that user-owned file.

## Known Stubs

None. Empty ID arrays are deliberate closed-policy results, and the deferred authority statement is the required Plan 165-10 acceptance boundary rather than a production placeholder.

## User Setup Required

None - no credentials, remote mutations, package installation, or human verification were required.

## Next Phase Readiness

Plan 165-04 can add runner, cache, and timeout contracts without relying on built-in non-directional cancellation. Plan 165-10 must still run the live requested-event timing and inversion probe before this controller becomes authoritative.

## Self-Check: PASSED

- All four created artifacts and the modified policy proof exist.
- All five TDD/task commits resolve in Git.
- Selector self-tests, both tagged ExUnit gates, actionlint, formatting, diff checks, and the Release Please byte-contract check pass.

---
*Phase: 165-efficient-and-maintainable-ci*
*Completed: 2026-09-07*
