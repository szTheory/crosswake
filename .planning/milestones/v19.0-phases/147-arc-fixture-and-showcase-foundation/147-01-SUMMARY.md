---
phase: 147-arc-fixture-and-showcase-foundation
plan: 01
subsystem: planning
tags: [roadmap, requirements, seed-classification, v19, v20]

requires: []
provides:
  - Phase 147 planning arc and seed-classification guardrails
  - Active v19/v20 sequence wording for implementation executors
affects: [phase-147, phase-151, v20-native-controls]

tech-stack:
  added: []
  patterns:
    - Active milestone seed classifications stay in PROJECT/STATE/MILESTONE-ARC, not only historical notes

key-files:
  created:
    - .planning/phases/147-arc-fixture-and-showcase-foundation/147-01-SUMMARY.md
  modified:
    - .planning/PROJECT.md
    - .planning/STATE.md
    - .planning/MILESTONE-ARC.md
    - .planning/ROADMAP.md

key-decisions:
  - "SEED-002 remains strategic capability-breadth input for the v19 capability map and v20 Native Controls Pack 1 prioritization."
  - "SEED-003 and SEED-004 remain release-infrastructure carryovers, not v19 showcase feature scope."
  - "The v19 showcase -> v20 controls -> later follow-ons sequence stays explicit before implementation work proceeds."

patterns-established:
  - "Active arc summaries name seed classification directly so future implementation plans do not infer broad v19 native-control scope."

requirements-completed:
  - ARC-01
  - ARC-02
  - ARC-03

duration: 6 min
completed: 2026-07-09
status: complete
---

# Phase 147 Plan 01: Preserve v19/v20 Arc Summary

**Planning docs now pin the showcase-first, controls-next product arc with SEED-002 as strategic input and SEED-003/004 as release-infrastructure carryovers.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-09T19:41:00Z
- **Completed:** 2026-07-09T19:46:56Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added active v19 wording in `.planning/PROJECT.md` that classifies SEED-002, SEED-003, and SEED-004 together.
- Added `.planning/MILESTONE-ARC.md` guard language keeping SEED-003/004 visible as release-integrity carryovers without making them v19 showcase scope.
- Expanded `.planning/ROADMAP.md` Phase 147 success criteria and `.planning/STATE.md` roadmap decisions to name the v19 showcase -> v20 Native Controls Pack 1 -> later follow-ons sequence.

## Arc Truth

- **ARC-01:** `.planning/MILESTONE-ARC.md`, `.planning/PROJECT.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` preserve the v19 showcase evidence -> v20 Native Controls Pack 1 -> later capture/device, commerce/paywall, operator dashboard, and offline-sync/native-storage sequence.
- **ARC-02:** `.planning/PROJECT.md` and `.planning/STATE.md` state that **SEED-002** informs capability breadth and v20 prioritization, not broad v19 native-control implementation.
- **ARC-03:** `.planning/PROJECT.md`, `.planning/STATE.md`, and `.planning/MILESTONE-ARC.md` classify **SEED-003** and **SEED-004** as release-infrastructure carryovers.
- **D-18:** Full capability-map classification remains Phase 151 scope; Phase 147 only makes support truth and seed classification visible.
- **D-21:** Expanded route-tour proof remains Phase 151 scope; Phase 147 must keep route-tour work narrow.

Verification command passed:

```bash
rg "Native Controls Pack 1|SEED-002|SEED-003|SEED-004|showcase first|controls next" .planning/PROJECT.md .planning/STATE.md .planning/MILESTONE-ARC.md .planning/REQUIREMENTS.md .planning/ROADMAP.md
```

The scope-fence scan also found native-control, dashboard, commerce, and sync terms only in future-scope, deferred, or anti-scope language.

## Task Commits

1. **Task 1: Reconcile v19/v20 planning arc and seed classifications** - `fd1a6793` (docs)
2. **Task 2: Add arc guard notes to phase summary inputs** - included in this summary metadata commit

## Files Created/Modified

- `.planning/PROJECT.md` - Added active seed-classification bullet and SEED-003/004 carryover item.
- `.planning/STATE.md` - Recorded Phase 147 execution start and added the product arc sequence to locked v19 decisions.
- `.planning/MILESTONE-ARC.md` - Added active v19 note keeping SEED-003/004 as release-infrastructure carryovers.
- `.planning/ROADMAP.md` - Expanded Phase 147 success criterion with the full arc and seed classification.
- `.planning/phases/147-arc-fixture-and-showcase-foundation/147-01-SUMMARY.md` - Records plan close-out and arc truth.

## Decisions Made

- Keep SEED-003/004 in active arc wording because historical v17/v18 mentions alone are too easy for future implementation agents to miss.
- Keep all new wording as scope guards rather than implementation instructions.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope creep; planning docs were narrowed to the requested arc and seed-truth guardrails.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Wave 1 implementation plans can build the showcase catalog and reset foundation against explicit scope fences: support truth is visible in Phase 147, full capability-map derivation remains Phase 151, and native-control breadth remains v20+.

---
*Phase: 147-arc-fixture-and-showcase-foundation*
*Completed: 2026-07-09*
