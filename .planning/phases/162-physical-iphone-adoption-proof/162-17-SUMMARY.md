---
phase: 162-physical-iphone-adoption-proof
plan: "17"
subsystem: physical-proof
tags: [evidence, provenance, transaction, recovery]
requires:
  - phase: 162-16
    provides: immutable corrected-provenance ledger and cleaned retained pair
provides:
  - committed evidence pair with immutable physical code provenance
  - isolated-Git wrapper regression and deterministic recovery coverage
  - reconciled narrow support truth pending independent verification
affects: [requirements, roadmap, state, independent-verification]
tech-stack:
  added: []
  patterns: [promoted-artifact provenance validation, bounded evidence topology]
key-files:
  created: [162-16-SUMMARY.md, 162-17-SUMMARY.md]
  modified: [retain_physical_iphone_evidence_transaction.sh, physical_iphone_evidence_transaction_test.exs, support_matrix.md, REQUIREMENTS.md, ROADMAP.md, STATE.md, 162-VALIDATION.md]
key-decisions:
  - "Post-promotion provenance is read only from the promoted canonical evidence record."
  - "The exact evidence pair follows the RED/GREEN repair chain while `e649e6ed` remains physical authority."
requirements-completed: [DEVICE-01, DEVICE-02, DEVICE-03, DEVICE-04, DEVICE-05, DEVICE-06, DEVICE-07]
coverage:
  - id: D1
    description: Retained corrected-provenance evidence is admitted through exact topology and privacy gates.
    requirement: DEVICE-06
    verification:
      - kind: unit
        ref: transaction and evidence deterministic test suite
        status: pass
    human_judgment: false
  - id: D2
    description: Narrow one-flow support truth is rendered only after retained evidence admission.
    requirement: DEVICE-07
    verification:
      - kind: integration
        ref: renderer, Phoenix authority, and browser recovery suite
        status: pass
    human_judgment: false
duration: 15min
completed: 2026-08-27
status: complete
---

# Phase 162 Plan 17: Corrected-Provenance Recovery Summary

**The existing corrected physical record was retained through a bounded RED/GREEN/evidence chain without another device attempt.**

## Accomplishments

- Added an isolated-Git regression proving passed run JSON can omit optional nested evidence provenance.
- Corrected the wrapper to validate commit provenance from the promoted canonical record and to gate staging on exact artifact topology, marker, and scan checks.
- Admitted and committed exactly the evidence pair in `e429a8f9`, preserving `e649e6ed` as physical code authority.
- Restored narrow device-evidence truth after 132 core tests, 21 Phoenix-host tests, and one browser test passed.

## Task Commits

1. **Task 1 RED:** `b5a540c1` — isolated regression.
2. **Task 1 GREEN:** `7c1f34d7` — promoted-artifact provenance validation.
3. **Task 2:** `e429a8f9` — exact evidence pair.

## Decisions Made

- The wrapper remains non-physical retention logic; it cannot rewrite the completed run's code provenance.
- Independent Phase 162 verification is the remaining completion authority.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed fixture-detected Git blob lookup with an absolute evidence path**
- **Found during:** Task 1
- **Fix:** Used the repository-relative evidence path for committed-blob equality.
- **Verification:** Isolated-Git transaction regression and focused deterministic suites passed.
- **Committed in:** `7c1f34d7`

## Known Stubs

None.

## Next Phase Readiness

Fresh independent verification must evaluate the committed recovery topology and current truth. A non-passing verdict requires scoped truth withdrawal and never another physical attempt.

## Self-Check: PASSED

- RED, GREEN, and exact evidence commits exist with the required parent chain.
- Retained leaves and both Plan 16 and Plan 17 summaries exist.
