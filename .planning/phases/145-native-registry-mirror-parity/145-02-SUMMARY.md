---
phase: 145-native-registry-mirror-parity
plan: 02
subsystem: release-infra
tags: [github-actions, native-release, rollup, json-artifact, release-integrity]
requires:
  - phase: 145-native-registry-mirror-parity
    provides: MIRR-01 iOS mirror write-authority preflight
provides:
  - always-running native release rollup
  - native-release-status JSON artifact
  - MIRR-02 scanner IDs and partial-state fixtures
affects: [release-please, native-proof, phase-146-status]
tech-stack:
  added: []
  patterns: [always-running release rollup, needs-result status aggregation, narrow CI evidence artifact]
key-files:
  created: []
  modified:
    - .github/workflows/release-please.yml
    - script/check_release_workflow_integrity.exs
    - test/crosswake/proof/phase142_release_integrity_test.exs
key-decisions:
  - "Native clean-room proofs remain platform-specific; neither proof depends on the sibling native publish job."
  - "Native release state is reported after the fact through a rollup instead of coupling proof DAGs."
  - "Partial native state is explicit and machine-readable through native-release-status.json."
patterns-established:
  - "Release rollups use always(), needs.*.result, GitHub summaries, and small JSON artifacts."
requirements-completed: [MIRR-02]
duration: 3 min
completed: 2026-07-08
status: complete
---

# Phase 145 Plan 02: Native Release Rollup Summary

**Native release jobs now preserve independent iOS/Android proofs while emitting honest partial-state text and JSON evidence**

## Performance

- **Duration:** 3 min
- **Started:** 2026-07-08T18:45:41Z
- **Completed:** 2026-07-08T18:48:52Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `native-release-rollup`, an `always()` job that depends on native publish/proof jobs only after they settle.
- Preserved iOS and Android proof DAGs so a sibling native publish failure cannot block the unaffected platform proof.
- Added scanner IDs and fixtures for rollup summary output, JSON artifact upload, sibling proof dependency regressions, and false native-complete copy.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add native release rollup without coupling platform proofs** - `cdfe7662` (feat)
2. **Task 2: Add MIRR-02 scanner IDs and partial-state fixtures** - `643987fe` (test)

**Plan metadata:** pending in this commit

## Files Created/Modified

- `.github/workflows/release-please.yml` - Adds `native-release-rollup`, summary output, and `native-release-status` artifact upload.
- `script/check_release_workflow_integrity.exs` - Adds `release.workflow.native_rollup_summary` and `release.workflow.native_status_artifact`.
- `test/crosswake/proof/phase142_release_integrity_test.exs` - Adds `:phase145_native_rollup` positive and negative fixtures.

## Decisions Made

- Kept the rollup as CI evidence for Phase 146 rather than implementing the full local status command in this phase.
- Modeled aggregate native state as `none`, `partial`, or `complete`; a single proven platform cannot claim native completion.
- Kept all status output free of raw secret or registry payload details.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

- The first missing-artifact fixture mutated the JSON filename in the script body while the upload step still satisfied the scanner. Adjusted the fixture to remove the `actions/upload-artifact@v4` behavior directly and re-ran the focused gate.

## Verification

- `elixir script/check_release_workflow_integrity.exs` - passed
- `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase145_native_rollup` - passed

## User Setup Required

None beyond the existing Phase 145 mirror-token setup captured in `145-USER-SETUP.md`.

## Next Phase Readiness

MIRR-02 is guarded. Wave 3 can add the verify-first iOS `v0.2.0` mirror backfill path and operator docs.

## Self-Check: PASSED

- Key files exist on disk.
- Plan commits exist for `145-02`.
- Focused scanner and ExUnit verification passed.

---
*Phase: 145-native-registry-mirror-parity*
*Completed: 2026-07-08*
