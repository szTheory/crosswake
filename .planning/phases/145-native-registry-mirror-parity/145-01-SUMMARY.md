---
phase: 145-native-registry-mirror-parity
plan: 01
subsystem: release-infra
tags: [github-actions, swiftpm, mirror, scanner, release-integrity]
requires:
  - phase: 144-published-core-compatibility-clean-room-proof
    provides: release workflow integrity scanner and clean-room proof guardrails
provides:
  - iOS mirror write-authority dry-run before real mirror mutation
  - MIRR-01 scanner ID and adversarial fixtures
  - exact-tag idempotency and mismatched-tag fail-closed copy
affects: [release-please, ios-mirror, swiftpm, phase-146-status]
tech-stack:
  added: []
  patterns: [semantic workflow scanner, idempotent registry recovery, non-mutating write preflight]
key-files:
  created:
    - .planning/phases/145-native-registry-mirror-parity/145-USER-SETUP.md
  modified:
    - .github/workflows/release-please.yml
    - script/check_release_workflow_integrity.exs
    - test/crosswake/proof/phase142_release_integrity_test.exs
key-decisions:
  - "Dry-run push authority is required in addition to MIRROR_PUSH_TOKEN presence and read access."
  - "An existing SwiftPM mirror tag is success only when it points at the expected split SHA."
  - "Mismatched public mirror tags fail closed without automatic delete or move."
patterns-established:
  - "Release workflow write authority is enforced by stable scanner IDs and negative fixtures."
requirements-completed: [MIRR-01]
duration: 8 min
completed: 2026-07-08
status: complete
---

# Phase 145 Plan 01: iOS Mirror Write-Authority Preflight Summary

**iOS SwiftPM mirror publishing now proves write authority with a non-mutating dry-run and scanner-backed MIRR-01 fixtures**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-08T18:37:57Z
- **Completed:** 2026-07-08T18:45:40Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added an authenticated read check, exact-tag identity check, and `git push --dry-run --porcelain mirror` probe before the real iOS mirror push.
- Added `release.mirror_token.write_preflight` to the release integrity scanner.
- Added Phase 145 MIRR-01 positive and negative fixtures for read-only and comment-only dry-run regressions.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add iOS mirror push-authority dry-run preflight** - `64d1a842` (feat)
2. **Task 2: Add MIRR-01 scanner ID and negative fixture coverage** - `e62dff1d` (test)

**Plan metadata:** pending in this commit

## Files Created/Modified

- `.github/workflows/release-please.yml` - Adds mirror read failure copy, exact-tag no-op success, mismatched-tag fail-closed behavior, and the dry-run push probe.
- `script/check_release_workflow_integrity.exs` - Adds `release.mirror_token.write_preflight`.
- `test/crosswake/proof/phase142_release_integrity_test.exs` - Adds `:phase145_mirror` tests and adversarial fixtures.
- `.planning/phases/145-native-registry-mirror-parity/145-USER-SETUP.md` - Captures the required mirror repository write token setup.

## Decisions Made

- Kept normal release preflight non-mutating; no scratch refs are created or deleted.
- Treated `git ls-remote mirror HEAD` as a read check only, not as proof of write authority.
- Pointed failed write-authority recovery copy at the Phase 145 iOS mirror backfill route.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

- Initial adversarial fixture replacement did not remove the dry-run block because the fixture string was too exact. Fixed the test fixture to mutate the invariant command token directly, then re-ran the focused MIRR-01 gate.

## Verification

- `elixir script/check_release_workflow_integrity.exs` - passed
- `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase145_mirror` - passed

## User Setup Required

External secret provisioning is required before live apply-mode mirror mutation. See `145-USER-SETUP.md`.

## Next Phase Readiness

MIRR-01 is guarded. Wave 2 can build the native release rollup on top of the hardened iOS mirror path.

## Self-Check: PASSED

- Key files exist on disk.
- Plan commits exist for `145-01`.
- Focused scanner and ExUnit verification passed.

---
*Phase: 145-native-registry-mirror-parity*
*Completed: 2026-07-08*
