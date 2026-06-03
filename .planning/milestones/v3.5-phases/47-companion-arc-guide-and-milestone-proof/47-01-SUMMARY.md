---
phase: 47-companion-arc-guide-and-milestone-proof
plan: 01
subsystem: companions
tags: [companions, docs-contract, support-matrix, doctor, proof]
requires: []
provides:
  - canonical v3.5 companion guide with contract-first structure
  - docs-contract semantic parity against live support, denial, and doctor truth
affects: [phase-47-02, PROOF-02]
tech-stack:
  added: []
  patterns: [anchor-plus-semantic-parity docs testing, fail-closed companion guidance]
key-files:
  created: [.planning/phases/47-companion-arc-guide-and-milestone-proof/47-01-SUMMARY.md]
  modified:
    - guides/companions.md
    - test/crosswake/guides/companions_test.exs
key-decisions:
  - "Keep one canonical companion guide and anchor it to exported truth surfaces instead of prose-only checks."
  - "Use live Doctor.run/1 outputs for finding-code parity instead of hardcoded snapshots."
patterns-established:
  - "Docs-contract tests verify both required vocabulary and runtime semantic parity."
requirements-completed: [PROOF-02]
duration: 7min
completed: 2026-05-31
---

# Phase 47 Plan 01: Companion Arc Guide And Milestone Proof Summary

**Completed the documentation half of PROOF-02 by shipping a single contract-first companions guide and live semantic docs-contract parity tests.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-05-31T17:23:00Z
- **Completed:** 2026-05-31T17:30:02Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Rewrote `guides/companions.md` into one canonical v3.5 guide with clear contract-first structure.
- Documented `Crosswake.Companion` callback contract, in-tree module convention, telemetry span, and fail-closed dependency posture.
- Added explicit Rulestead, Rindle, and Sigra anchors plus deferred non-goals (chimeway delivery, full Sigra machinery, threadline, package extraction).
- Strengthened `companions_test.exs` with live code export guards and semantic parity checks against support matrix, denial vocabulary, and doctor findings.

## Task Commits

1. **Task 1: Rewrite canonical companion guide** - `4406db2` (docs)
2. **Task 2: Strengthen companion docs-contract semantic parity** - `d1f48b0` (test)

## Files Created/Modified

- `guides/companions.md` - single canonical companion guide with contract, truth surfaces, proof posture, and non-goals.
- `test/crosswake/guides/companions_test.exs` - anchor assertions + live parity checks for callbacks, support truth, denial reasons, and doctor finding codes.

## Decisions Made

- Prefer exported truth (`SupportMatrix`, `Shell.Denial`, `Doctor`) over static text snapshots for docs lock behavior.
- Keep Sigra wording contract-only and avoid implying deferred delivery.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Missing lowercase runtime companion id in guide parity text**
- **Found during:** Task 2 verification
- **Issue:** Guide lacked `:rindle` id token required by runtime parity assertion.
- **Fix:** Added explicit `Companion id: :rindle` in the Rindle section.
- **Files modified:** `guides/companions.md`
- **Verification:** `mix test test/crosswake/guides/companions_test.exs`
- **Commit:** `4406db2`

## Issues Encountered

None.

## Next Phase Readiness

- Plan 47-02 can consume this canonical guide/test baseline for milestone-level proof closure.

## Self-Check: PASSED

- Summary file exists: `.planning/phases/47-companion-arc-guide-and-milestone-proof/47-01-SUMMARY.md`
- Task commits exist in git history: `4406db2`, `d1f48b0`

---
*Phase: 47-companion-arc-guide-and-milestone-proof*
*Completed: 2026-05-31*
