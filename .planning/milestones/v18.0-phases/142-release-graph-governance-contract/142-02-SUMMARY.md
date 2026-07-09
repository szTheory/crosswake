---
phase: 142-release-graph-governance-contract
plan: 02
subsystem: ci-release-governance
tags: [github-actions, release-please, release-graph, elixir-proof, exunit]

requires:
  - phase: 142-01-release-graph-governance-workflow
    provides: corrected Release Please workflow DAG with queue max, exact gates, and proof-gated cleanup
provides:
  - Fixture-friendly release workflow integrity scanner with stable semantic check IDs
  - Non-comment workflow scanning so comments cannot satisfy or violate invariants
  - Adversarial ExUnit proof for queue, cancellation, aggregate gates, cleanup proof, comments, and PR-only cleanup
affects: [phase-142, release-please, companion-publishing, clean-room-proof]

tech-stack:
  added: []
  patterns:
    - Dependency-free Elixir scanner with explicit workflow path selection through argv or RELEASE_WORKFLOW_PATH
    - ExUnit fixture mutation for release governance negative controls

key-files:
  created:
    - script/check_release_workflow_integrity.exs
    - test/crosswake/proof/phase142_release_integrity_test.exs
    - .planning/phases/142-release-graph-governance-contract/142-02-SUMMARY.md
  modified: []

key-decisions:
  - "Kept the semantic scanner dependency-free and text-based per Phase 142 D-18/D-22."
  - "Treated full-line YAML comments as non-semantic input for both required and forbidden invariants."
  - "Kept actionlint additive because local actionlint 1.7.12 rejects the required queue:max key."

patterns-established:
  - "Release workflow proof checks emit stable release.* IDs with [crosswake] OK/FAIL output."
  - "Adversarial workflow fixtures run through the real scanner executable instead of duplicating scanner logic in tests."

requirements-completed: [RELG-01, RELG-02, RELG-03]

duration: 5 min
completed: 2026-07-07
status: complete
---

# Phase 142 Plan 02: Release Graph Governance Proof Summary

**Release governance proof now has named semantic checks and adversarial fixtures for path gates, non-replacing concurrency, proof-gated cleanup, and PR-only cleanup.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-07-07T15:13:09Z
- **Completed:** 2026-07-07T15:18:54Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- Replaced the workflow integrity scanner with a fixture-friendly Elixir proof that accepts an explicit path, `RELEASE_WORKFLOW_PATH`, or the default release workflow.
- Added stable check IDs for concurrency queueing, exact root/native path gates, aggregate behavioral-gate absence, native proof decoupling, mirror preflight, cleanup-after-proof, PR-only cleanup, and all five companion gates.
- Added ExUnit negative fixtures for missing `queue: max`, true cancellation, aggregate behavioral gates, comment-only false passes, cleanup ignoring proof, and direct `main` mutation.
- Preserved existing clean-room dependency floor assertions without claiming downstream PREF completion.

## Task Commits

1. **Task 2 RED: adversarial release governance fixtures** - `aae5bc20` (`test`)
2. **Task 1 GREEN: release workflow integrity scanner** - `758c4cd0` (`feat`)
3. **Task 3: focused release-governance proof loop** - verification-only, no file changes to commit

## Files Created/Modified

- `script/check_release_workflow_integrity.exs` - Dependency-free semantic scanner with argv/env/default path selection, non-comment job checks, and stable `[crosswake]` check output.
- `test/crosswake/proof/phase142_release_integrity_test.exs` - Merge-blocking ExUnit wrapper plus adversarial workflow fixtures.
- `.planning/phases/142-release-graph-governance-contract/142-02-SUMMARY.md` - Plan execution record.

## Decisions Made

- Kept scanner implementation local and dependency-free instead of adding a YAML parser.
- Kept `release-please` itself out of the behavioral aggregate-gate check because it legitimately exposes aggregate outputs for summaries/logging.
- Preserved `queue: max` despite actionlint lag because RELG-02 requires pending release runs not to be replaced.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** None.

## Verification

- **PASS:** `elixir script/check_release_workflow_integrity.exs`
- **PASS:** `RELEASE_WORKFLOW_PATH=.github/workflows/release-please.yml elixir script/check_release_workflow_integrity.exs`
- **PASS:** `mix test test/crosswake/proof/phase142_release_integrity_test.exs` (`9 tests, 0 failures`)
- **TOOLING LIMITATION:** `actionlint .github/workflows/release-please.yml` failed because actionlint 1.7.12 rejects `concurrency.queue: max` as an unexpected key. The queue key is retained per the Plan 142 acceptance contract.

## Issues Encountered

Local `actionlint` does not yet accept GitHub's `queue: max` concurrency key. The Crosswake semantic proof remains authoritative for this release governance policy.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Plan 142-03 to surface the same governance status through the release-status operator command without claiming downstream PREF, MIRR, or STAT requirements complete.

## Self-Check: PASSED

- `FOUND`: `script/check_release_workflow_integrity.exs`
- `FOUND`: `test/crosswake/proof/phase142_release_integrity_test.exs`
- `FOUND`: `.planning/phases/142-release-graph-governance-contract/142-02-SUMMARY.md`
- `FOUND_COMMIT`: `aae5bc20 test(142-02): add adversarial release governance fixtures`
- `FOUND_COMMIT`: `758c4cd0 feat(142-02): harden release workflow integrity scanner`

---
*Phase: 142-release-graph-governance-contract*
*Completed: 2026-07-07*
