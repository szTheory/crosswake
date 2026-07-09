---
phase: 146-release-status-dx-docs-truth
plan: 03
subsystem: release-ops
tags: [release-status, live-probes, docs, registry-truth]

requires:
  - phase: 146-release-status-dx-docs-truth
    provides: scanner-backed local status checks and JSON contract from plans 01-02
provides:
  - optional live registry probe taxonomy
  - release-status runbook documentation
  - corrected package-family changelog truth
affects: [phase-146, release-status, public-docs, package-family-release-ops]

tech-stack:
  added: []
  patterns:
    - advisory live registry probes
    - docs truth boundary between status, floors, and mutation

key-files:
  created:
    - .planning/phases/146-release-status-dx-docs-truth/146-03-SUMMARY.md
  modified:
    - lib/crosswake/release_status.ex
    - test/mix/tasks/crosswake_release_status_test.exs
    - docs/COMPANION-PUBLISH-RUNBOOK.md
    - guides/companion_compatibility.md
    - CHANGELOG.md
    - README.md

key-decisions:
  - "Live registry probes distinguish `ok`, `missing`, and `unavailable`, and warnings remain advisory by default."
  - "Changelog package-family truth follows live registry evidence: `crosswake_rulestead` and `crosswake_rindle` are tracked in the local graph but currently missing from Hex public release endpoints."

patterns-established:
  - "Release docs name `mix crosswake.release.status [--json] [--live]` as the read-only operator surface."
  - "Compatibility floors remain in `guides/companion_compatibility.md`; registry presence belongs to release status."

requirements-completed: [STAT-01, STAT-02, STAT-03]

duration: 5 min
completed: 2026-07-09
status: complete
---

# Phase 146 Plan 03: Live Probe Taxonomy and Docs Truth Summary

**Release status now has optional advisory live probes, and public docs separate local graph truth, registry presence, compatibility floors, and guarded mutation paths.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-07-09T13:31:15Z
- **Completed:** 2026-07-09T13:36:01Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Implemented and verified `ok` / `missing` / `unavailable` live probe semantics for Hex, Maven Central, and the iOS SwiftPM mirror.
- Documented the release-status command, JSON mode, live mode, and no-mutation boundary in the companion publish runbook and README.
- Reconciled compatibility and changelog docs so registry presence is owned by release status while compatibility floors remain in the compatibility guide.

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement live registry taxonomy without changing local default behavior** - `698d0d44` (feat)
2. **Task 2: Reconcile release docs and add stale-doc guard** - `305e8d10` (docs)

**Plan metadata:** recorded in the current docs commit.

## Files Created/Modified

- `lib/crosswake/release_status.ex` - Provides structured live probe maps and advisory live registry checks.
- `test/mix/tasks/crosswake_release_status_test.exs` - Covers injected live `ok`, `missing`, and `unavailable` states plus stale wording guards.
- `docs/COMPANION-PUBLISH-RUNBOOK.md` - Documents release status as the current read-only operator surface and mutation boundary.
- `guides/companion_compatibility.md` - Keeps `requires_crosswake` floors separate from registry presence.
- `CHANGELOG.md` - Corrects package-family publication truth using live registry evidence.
- `README.md` - Adds maintainer entry point for `mix crosswake.release.status [--json] [--live]`.

## Decisions Made

- Treated live registry output as stronger evidence than planning copy for public publication claims.
- Kept `crosswake_rulestead` and `crosswake_rindle` as local release-graph entries, but did not claim them as live Hex packages after direct Hex release endpoints returned 404.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected planned changelog copy that over-claimed live companion packages**
- **Found during:** Task 2 (docs reconciliation)
- **Issue:** The plan text said `crosswake_rulestead 0.1.0` and `crosswake_rindle 0.1.0` were live Hex packages, but `mix crosswake.release.status --live` and direct Hex release endpoint checks returned `missing` / HTTP 404 for both.
- **Fix:** Updated `CHANGELOG.md` to list only the currently live public Hex packages and state that rulestead/rindle are local release-graph entries whose registry presence is reported by `--live`.
- **Files modified:** `CHANGELOG.md`
- **Verification:** `mix crosswake.release.status --live`; direct `curl` checks against the Hex release endpoints; stale-doc grep guard.
- **Committed in:** `305e8d10`

---

**Total deviations:** 1 auto-fixed (bug).
**Impact on plan:** Improves release truth. The docs now avoid a false public registry claim while still removing stale "not yet published" wording.

## Issues Encountered

- Live probe output currently warns that iOS `v0.2.0`, `crosswake_rulestead 0.1.0`, and `crosswake_rindle 0.1.0` are missing from public registry endpoints. This is advisory live state, not a local graph error.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

All Phase 146 plans now have summaries. The phase is ready for full verification and completion.

---
*Phase: 146-release-status-dx-docs-truth*
*Completed: 2026-07-09*
