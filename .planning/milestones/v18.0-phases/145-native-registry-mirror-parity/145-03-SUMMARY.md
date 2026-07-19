---
phase: 145-native-registry-mirror-parity
plan: 03
subsystem: release-infra
tags: [github-actions, swiftpm, mirror, backfill, release-integrity]
requires:
  - phase: 145-native-registry-mirror-parity
    provides: MIRR-01 mirror preflight and MIRR-02 native release rollup
provides:
  - verify-first iOS v0.2.0 mirror backfill script
  - thin workflow_dispatch wrapper for operator use
  - MIRR-03 scanner IDs, fixture coverage, and runbook/support truth
affects: [ios-mirror, swiftpm, release-runbook, support-matrix, phase-146-status]
tech-stack:
  added: []
  patterns: [verify-first registry recovery, script-owned workflow wrapper, fail-closed tag reconciliation]
key-files:
  created:
    - script/verify_ios_mirror_backfill.sh
    - test/crosswake/proof/phase145_ios_backfill_script_test.exs
    - .github/workflows/ios-mirror-backfill.yml
  modified:
    - script/check_release_workflow_integrity.exs
    - test/crosswake/proof/phase142_release_integrity_test.exs
    - docs/COMPANION-PUBLISH-RUNBOOK.md
    - guides/support_matrix.md
    - guides/companion_compatibility.md
key-decisions:
  - "The iOS mirror backfill path is verify-first; mutation requires explicit --apply and MIRROR_PUSH_TOKEN."
  - "Release Please component tags, manifest versions, and live Hex/Maven evidence must agree before mirror mutation."
  - "Existing exact mirror tags are success, absent tags are verify-only next actions, and mismatched mirror tags fail closed."
patterns-established:
  - "Manual release recovery lives in scripts with thin GitHub workflow wrappers and scanner-backed invariants."
requirements-completed: [MIRR-03]
duration: 8 min
completed: 2026-07-08
status: complete
---

# Phase 145 Plan 03: iOS Mirror Backfill Summary

**Maintainers now have a guarded verify-first path for the missing iOS SwiftPM `v0.2.0` mirror tag**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-08T18:48:53Z
- **Completed:** 2026-07-08T18:56:44Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Added `script/verify_ios_mirror_backfill.sh`, a strict Bash verifier/backfill tool with explicit `--apply` and guarded optional `--update-main`.
- Added local Git fixture coverage for verify-only/no-token, apply-without-token, exact-tag no-op, and mismatched-tag fail-closed branches.
- Added `iOS mirror backfill`, a thin manual workflow that validates inputs, installs pinned splitsh-lite, and delegates all recovery logic to the script.
- Added MIRR-03 scanner IDs and adversarial workflow/script fixtures.
- Updated operator docs and support guides so SwiftPM mirror recovery is registry evidence, not native device proof or companion floor normalization.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create verify-first iOS mirror backfill script** - `a3a0ec7f` (feat)
2. **Task 2: Add thin dispatch wrapper and MIRR-03 scanner fixtures** - `470e1efc` (test)
3. **Task 3: Reconcile native backfill runbook and support truth** - `50af7233` (docs)
4. **Review fix: Tighten workflow input default fixtures** - `3ff2c5c5` (test)

**Plan metadata:** `ef9984f8` (docs)

## Files Created/Modified

- `script/verify_ios_mirror_backfill.sh` - Verifies release tag lockstep, live root/Android registry state, split SHA, and mirror tag state before any optional mutation.
- `test/crosswake/proof/phase145_ios_backfill_script_test.exs` - Covers the key script branches against local temp Git fixtures only.
- `.github/workflows/ios-mirror-backfill.yml` - Adds the manual `workflow_dispatch` wrapper for verification/apply mode.
- `script/check_release_workflow_integrity.exs` - Adds `release.ios_backfill.*` scanner IDs.
- `test/crosswake/proof/phase142_release_integrity_test.exs` - Adds `:phase145_ios_backfill` positive and negative fixtures.
- `docs/COMPANION-PUBLISH-RUNBOOK.md` - Documents verify/apply commands and exact/missing/mismatch outcomes.
- `guides/support_matrix.md` - Keeps mirror backfill scoped to release-registry evidence.
- `guides/companion_compatibility.md` - Keeps Phase 145 registry status separate from companion compatibility floors.

## Decisions Made

- Kept the workflow wrapper intentionally thin; all registry, tag, split, and mutation behavior stays in the script.
- Rejected current-branch/current-HEAD source refs for backfill; the canonical v0.2.0 source is `refs/tags/ios-core-v0.2.0`.
- Required Hex root and Android Maven evidence before iOS mirror mutation so recovery does not re-enter immutable publish paths.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

- Local code-review fallback found a scanner false positive: `release.ios_backfill.verify_first` and `release.ios_backfill.no_default_main_force` accepted any `default: false` in the workflow, so an `apply` or `update_main` input could regress to `default: true` while another boolean input kept the scanner green. Fixed by binding scanner checks to named workflow input blocks and adding negative fixtures.

## Verification

- `bash -n script/verify_ios_mirror_backfill.sh` - passed
- `mix test test/crosswake/proof/phase145_ios_backfill_script_test.exs` - passed
- `elixir script/check_release_workflow_integrity.exs` - passed
- `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase145_ios_backfill` - passed
- Documentation grep checks for the runbook, support matrix, and companion compatibility guide - passed

## User Setup Required

External secret provisioning is required before live apply-mode mirror mutation. See `145-USER-SETUP.md`.

## Next Phase Readiness

MIRR-03 is guarded. Phase 146 can consume native release status/backfill truth without widening native proof or compatibility-floor claims.

## Self-Check: PASSED

- Key files exist on disk.
- Plan commits exist for `145-03`.
- Focused script, scanner, ExUnit, and docs verification passed.

---
*Phase: 145-native-registry-mirror-parity*
*Completed: 2026-07-08*
