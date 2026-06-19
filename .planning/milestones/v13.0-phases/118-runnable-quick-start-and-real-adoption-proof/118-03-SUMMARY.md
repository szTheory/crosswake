---
phase: 118-runnable-quick-start-and-real-adoption-proof
plan: "03"
subsystem: testing
tags: [docs-contract, quick-start, adoption, drift-guard, offline-proof]
requires:
  - phase: 118-runnable-quick-start-and-real-adoption-proof
    provides: quick-start proof ladder from plan 01
  - phase: 118-runnable-quick-start-and-real-adoption-proof
    provides: app-owned offline adoption guide from plan 02
provides:
  - ExUnit docs-contract guard for quick-start and adoption drift
  - Source-derived Phoenix host port, Playwright port, setup alias, and path checks
  - Synthetic regression coverage for stale command, path, native label, and bridge-authority claims
affects: [phase-119-native-evidence, phase-120-troubleshooting, docs-drift]
tech-stack:
  added: []
  patterns:
    - Docs-contract tests derive structural facts from source files before accepting public guide claims.
    - Drift guards assert commands, paths, routes, labels, and proof terms without snapshotting whole paragraphs.
key-files:
  created:
    - test/crosswake/guides/quick_start_adoption_drift_test.exs
  modified:
    - examples/QUICK_START.md
key-decisions:
  - "Kept DRIFT-02 as an ExUnit source scanner, not an executable markdown runner or native tooling gate."
  - "Derived the Phoenix host and Playwright port from checked-in source files so docs follow source truth."
  - "Made synthetic tests assert failure categories so future failures tell maintainers what class of drift occurred."
patterns-established:
  - "Quick-start/adoption guide truth is guarded through failure maps with path, line, category, claim, and actionable detail."
  - "Forbidden offline-authority language catches exact stale phrases plus bridge-owned mutation queue wording."
requirements-completed: [QUICK-01, ADOPT-01, DRIFT-02]
duration: 8 min
completed: 2026-06-19
status: complete
---

# Phase 118 Plan 03: Drift Guard Summary

**Quick-start and adoption guide truth is now guarded by source-derived ExUnit docs-contract tests**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-19T15:47:11Z
- **Completed:** 2026-06-19T15:55:09Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `Crosswake.Guides.QuickStartAdoptionDriftTest` to scan the final Wave 1 quick-start and adoption docs.
- Derived current Crosswake version, Phoenix host port, Playwright port, setup aliases, and required repo paths from source files.
- Required quick-start commands, routes, proof scripts, stop-server Playwright caveat, and advisory/local-development native labels.
- Required adoption-guide IndexedDB, `flushOutbox`, `/study/sync`, Ecto idempotency, accepted/rejected/conflict semantics, outbox deletion, and current implementation names.
- Added synthetic regression cases for wrong port, missing `mix setup`, missing repo path, stale bridge/offline authority strings, missing native labels, and missing offline proof terms.

## Task Commits

1. **Task 1: Add source-derived real-doc quick-start/adoption scanner** - `4336bff` (`test`)
2. **Task 2: Add synthetic regression cases for stale commands, paths, labels, and offline authority** - `eb1fe6b` (`test`)

## Files Created/Modified

- `test/crosswake/guides/quick_start_adoption_drift_test.exs` - New DRIFT-02 docs-contract guard and synthetic regression suite.
- `examples/QUICK_START.md` - Removes the stale negative phrase `bridge-owned mutation queue` so the guard can ban that wording structurally.

## Decisions Made

- Kept the guard prose-loose and structural: it checks commands, identifiers, paths, labels, routes, and outcome terms instead of paragraph snapshots.
- Treated native host paths as valid only when nearby copy keeps them advisory/local-development.
- Used category assertions in synthetic tests so failures stay actionable.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Quick start still carried stale bridge-owned mutation queue wording**
- **Found during:** Task 1 (Add source-derived real-doc quick-start/adoption scanner)
- **Issue:** `examples/QUICK_START.md` contained a negative sentence with `bridge-owned mutation queue`; DRIFT-02 requires that conceptual wording to be forbidden.
- **Fix:** Reworded the sentence to say `/study/sync` is used by the browser island, not by the bridge.
- **Files modified:** `examples/QUICK_START.md`
- **Verification:** `mix test test/crosswake/guides/quick_start_adoption_drift_test.exs` passed.
- **Committed in:** `4336bff`

---

**Total deviations:** 1 auto-fixed (Rule 2 missing critical)
**Impact on plan:** Necessary to make the new forbidden-language guard meaningful. No scope expansion beyond removing stale public wording.

## Issues Encountered

None.

## Verification

- `mix test test/crosswake/guides/quick_start_adoption_drift_test.exs` - passed, 5 tests.
- `gsd-tools query verify.key-links .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-03-PLAN.md` - passed, 4/4 links verified.
- `git diff --check` - passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

DRIFT-02 is now in the normal Mix test surface. Phase 119 can classify native evidence without relying on quick-start/adoption prose for native proof status, and Phase 120 can build screenshots/troubleshooting docs on top of guarded command and proof truth.

---
*Phase: 118-runnable-quick-start-and-real-adoption-proof*
*Completed: 2026-06-19*
