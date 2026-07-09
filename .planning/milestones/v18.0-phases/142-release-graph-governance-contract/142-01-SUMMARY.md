---
phase: 142-release-graph-governance-contract
plan: 01
subsystem: ci-release-governance
tags: [github-actions, release-please, release-graph, elixir-proof]

requires:
  - phase: 141-core-first-publish-family-release
    provides: core-first package-family release context and companion publish/proof posture
provides:
  - Release workflow concurrency with cancel-in-progress false and queue max
  - Exact root/native path identity gates through Release Please paths_released
  - release-as cleanup gated on released companion publish and clean-room proof success
  - Android fire-drill basename quote hygiene
affects: [phase-142, release-please, companion-publishing, clean-room-proof]

tech-stack:
  added: []
  patterns:
    - GitHub Actions release DAG guarded by exact Release Please path/component identity
    - Cleanup uses per-component implications so unreleased companions may skip

key-files:
  created:
    - .planning/phases/142-release-graph-governance-contract/142-01-SUMMARY.md
  modified:
    - .github/workflows/release-please.yml

key-decisions:
  - "Kept Release Please aggregate releases_created available only for summaries, alerts, and logging while behavioral jobs use exact path/component identity."
  - "Implemented release-as cleanup as PR-only cleanup after released component publish and proof success."
  - "Kept actionlint additive; local actionlint 1.7.12 rejects required queue:max syntax, so Plan 01 structural proof remains the authoritative check until tooling catches up."

patterns-established:
  - "Workflow-level release concurrency must include cancel-in-progress:false plus queue:max."
  - "Released companion cleanup must require both publish-hex-* and clean-room-proof-* success; skipped unreleased companions are allowed."

requirements-completed: [RELG-01, RELG-02, RELG-03]

duration: 5 min
completed: 2026-07-07
status: complete
---

# Phase 142 Plan 01: Release Graph Governance Workflow Summary

**Release Please workflow governance now uses exact release identity, non-replacing concurrency, proof-gated cleanup, and quoted Android artifact handling.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-07-07T15:04:13Z
- **Completed:** 2026-07-07T15:09:00Z
- **Tasks:** 3
- **Files modified:** 1

## Accomplishments

- Added `queue: max` beside `cancel-in-progress: false` in the workflow-level release concurrency block.
- Preserved exact `paths_released` membership gates for root/native behavioral jobs and per-component `*_release_created` gates for companion jobs.
- Reworked `release-as-cleanup` so released companions require both `publish-hex-*` and `clean-room-proof-*` success while unreleased companions may skip.
- Preserved PR-only cleanup behavior through branch creation, `git push origin "$branch"`, and `gh pr create`.
- Fixed the Android fire-drill artifact assertion to use `basename "$ARTIFACT"`.

## Task Commits

The workflow tasks landed together because `.github/workflows/release-please.yml` already contained same-file v18 spillover and the final release DAG contract is coupled across the three tasks.

1. **Tasks 1-3: Release workflow governance contract** - `a65bf6b0` (`fix`)

## Files Created/Modified

- `.github/workflows/release-please.yml` - Release graph gates, concurrency, cleanup dependencies/condition, and Android fire-drill quote hygiene.
- `.planning/phases/142-release-graph-governance-contract/142-01-SUMMARY.md` - Plan execution record.

## Decisions Made

- Kept `releases_created` exposed for non-behavioral summaries/logging only; publish/proof/cleanup behavior is driven by exact path/component identity.
- Kept cleanup PR-only and did not add protected-main mutation.
- Did not edit Plan 02 scanner/test files when they lagged the new cleanup contract; recorded the expected sequencing limitation instead.

## Deviations from Plan

### Auto-fixed Issues

None - plan executed within the allowed file scope.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** None. Verification limitations below are sequencing issues in downstream Plan 02 proof files, not workflow-contract failures.

## Verification

- **PASS:** Task 1 Elixir structural assertion for `queue: max`, `cancel-in-progress: false`, and exact root/native path gates.
- **PASS:** Task 2 Elixir structural assertion for all five companion publish jobs, all five clean-room proof jobs, per-component success implications, no broad `needs.*.result` guard, no direct `git push origin main`, and `gh pr create`.
- **PASS:** Task 3 grep for `basename "$ARTIFACT"`.
- **FAIL (expected Plan 02 sequencing):** `elixir script/check_release_workflow_integrity.exs` still checks the pre-Plan-01 broad cleanup guard via `release.cleanup.after_publish`, so it fails after the workflow is corrected to proof-gated cleanup.
- **FAIL (expected Plan 02 sequencing):** `mix test test/crosswake/proof/phase142_release_integrity_test.exs` fails only through the same scanner wrapper assertion.
- **FAIL (tooling limitation):** local `actionlint` 1.7.12 rejects required `concurrency.queue: max` as an unexpected key. The workflow keeps `queue: max` because it is a critical Plan 142 acceptance requirement.

## Issues Encountered

The existing Plan 02 scanner and ExUnit wrapper are not yet upgraded for the new cleanup-after-proof contract. Per the execution prompt, those files were not edited in Plan 01.

## Known Stubs

None. The `_TODO_release_as` string in the cleanup PR body is intentional release-config cleanup text, not an unwired stub.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Plan 142-02 to upgrade `script/check_release_workflow_integrity.exs` and `test/crosswake/proof/phase142_release_integrity_test.exs` so the semantic proof matches the corrected workflow contract.

## Self-Check: PASSED

- `FOUND_SUMMARY`: `.planning/phases/142-release-graph-governance-contract/142-01-SUMMARY.md`
- `FOUND_COMMIT`: `a65bf6b0 fix(142-01): reconcile release workflow governance`

---
*Phase: 142-release-graph-governance-contract*
*Completed: 2026-07-07*
