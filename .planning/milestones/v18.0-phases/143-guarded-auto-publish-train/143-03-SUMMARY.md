---
phase: 143-guarded-auto-publish-train
plan: 03
subsystem: release-proof
tags: [exunit, scanner, github-actions, hex, release-please, docs]
requires:
  - phase: 143-guarded-auto-publish-train
    provides: guarded automatic publish helper and exact-ref recovery workflow from plans 01 and 02
provides:
  - Phase 143 semantic scanner IDs for guarded publish and recovery behavior
  - adversarial ExUnit fixtures for auto publish, recovery, and version graph regressions
  - operator docs aligned to guarded CI publish and exact-ref recovery
affects: [release-integrity, companion-publishing, release-docs, phase-144]
tech-stack:
  added: []
  patterns: [semantic workflow scanner, adversarial temp fixtures, docs-as-contract grep]
key-files:
  created: []
  modified:
    - script/check_release_workflow_integrity.exs
    - test/crosswake/proof/phase142_release_integrity_test.exs
    - docs/COMPANION-PUBLISH-RUNBOOK.md
    - guides/companion_compatibility.md
key-decisions:
  - "Extended the existing Phase 142 scanner instead of adding a YAML parser dependency."
  - "Used temp-file fixtures so ExUnit tests mutate real workflow/helper/config text while keeping source files untouched."
  - "Replaced outdated human publish-loop runbook copy with the current CI-owned release operating model."
patterns-established:
  - "Stable scanner IDs now cover guarded Hex publish, exact-ref recovery, package map completeness, and version/floor graph truth."
  - "Phase 143 docs name Phase 144/145/146 boundaries without claiming downstream completion."
requirements-completed: [AUTO-01, AUTO-02, AUTO-03]
duration: 6 min
completed: 2026-07-07
status: complete
---

# Phase 143 Plan 03: Semantic Proof and Docs Summary

**Semantic release proof for guarded Hex publishing, exact-ref recovery, companion version graph, and operator docs**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-07T21:58:00Z
- **Completed:** 2026-07-07T22:03:41Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added Phase 143 scanner IDs for guarded automatic Hex publish, no routine replacement syntax, shared helper usage, component-aware recovery input, exact-ref-only recovery, package map completeness, already-live proof continuation, core/native lockstep, independent companions, and honest companion floors.
- Added adversarial ExUnit fixtures for direct publish regression, missing already-live preflight, root-only recovery, mutable/bare recovery refs, missing helper package entry, routine replacement syntax, linked-version companion creep, and floor flattening.
- Reconciled `docs/COMPANION-PUBLISH-RUNBOOK.md` to the CI-owned publish train, exact-ref manual recovery, already-live OK/FAIL states, required-check boundary, mixed floors, and Phase 144/145/146 scope boundaries.
- Added a compatibility-guide boundary note while preserving `~> 0.1` floors for rulestead/rindle and `~> 0.2` floors for sigra/chimeway/threadline.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend release workflow scanner with Phase 143 check IDs** - `7a8faf74` (test)
2. **Task 2: Add adversarial ExUnit proof for auto publish, recovery, and version graph** - `1c801b87` (test)
3. **Task 3: Reconcile runbook and floor docs to guarded auto-publish train** - `3afec203` (docs)

**Plan metadata:** this summary commit.

## Files Created/Modified

- `script/check_release_workflow_integrity.exs` - Added Phase 143 semantic checks and path/env fixture support.
- `test/crosswake/proof/phase142_release_integrity_test.exs` - Added tagged positive and negative fixtures for Phase 143 invariants.
- `docs/COMPANION-PUBLISH-RUNBOOK.md` - Rewritten around guarded CI publish and exact-ref Hex recovery.
- `guides/companion_compatibility.md` - Added release-integrity phase boundary guidance while preserving mixed floors.

## Decisions Made

- Used Elixir's built-in `JSON` module in the scanner for `release-please-config.json` and manifest checks instead of introducing a parser dependency.
- Kept scanner checks semantic and stable-ID based; tests assert scanner output rather than duplicating workflow parsing logic.
- Removed obsolete human-driven per-companion publish-loop instructions from the runbook to avoid contradictory operator guidance.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

- One negative fixture initially removed only the first occurrence of a forbidden recovery ref sample, leaving the sample elsewhere in workflow text. The fixture was corrected to remove all occurrences before committing; targeted and full tests then passed.

## Verification

- `elixir script/check_release_workflow_integrity.exs`
- `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase143_auto_publish`
- `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase143_recovery`
- `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase143_version_graph`
- `mix test test/crosswake/proof/phase142_release_integrity_test.exs`
- Docs grep for Release Please approval boundary, manual recovery, `[crosswake] OK`, `[crosswake] FAIL`, `MUST NOT`, mixed floors, and Phase 144/145/146 boundaries.

All checks passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 143 implementation is ready for phase-level verification. Phase 144 can now focus on published-core clean-room exactness without reworking the guarded Hex publish/recovery train.

---
*Phase: 143-guarded-auto-publish-train*
*Completed: 2026-07-07*
