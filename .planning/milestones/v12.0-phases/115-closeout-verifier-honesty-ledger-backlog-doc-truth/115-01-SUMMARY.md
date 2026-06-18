---
phase: 115-closeout-verifier-honesty-ledger-backlog-doc-truth
plan: "01"
subsystem: planning
tags: [closeout-verifier, validation-ledger, tdd, gate-02]

requires:
  - phase: 115-closeout-verifier-honesty-ledger-backlog-doc-truth
    provides: Phase 115 context, research, and GATE-02 contract
provides:
  - closeout.expected_phases stable verifier check
  - strict expected_phases inline-array parser with no fallback phase set
  - validation ledger evidence validation for tested_by and structured evidence
  - accepted validation-ledger exception recognition for historical zero-ledger phases
affects: [phase-115, closeout.verify, validation-ledger-finalization]

tech-stack:
  added: []
  patterns:
    - report-first fail-closed verifier checks
    - strict local parsing for known planning-artifact contracts
    - TDD RED/GREEN task commits

key-files:
  created:
    - .planning/phases/115-closeout-verifier-honesty-ledger-backlog-doc-truth/115-01-SUMMARY.md
  modified:
    - lib/crosswake/planning/closeout_verifier.ex
    - test/crosswake/planning/closeout_verifier_test.exs
    - test/mix/tasks/closeout_verify_test.exs

key-decisions:
  - "No YAML dependency: expected_phases is parsed only as a strict non-empty inline array."
  - "Invalid expected_phases is reported through closeout.expected_phases and dependent phase checks skip without guessed phase scans."
  - "Real validation ledgers now require nyquist_compliant: true plus tested_by and structured concrete evidence."
  - "Inactive closeouts relax all current-closeout artifact checks, including closeout.expected_phases."

patterns-established:
  - "Report-first failure: verifier emits stable Check entries; Mix task prints the report before raising."
  - "Evidence validation: local test_file refs must exist under cwd; command refs are limited to mix test, mix compile, or mix closeout.verify; ci_run/artifact refs must be non-empty."

requirements-completed: [GATE-02]

duration: 7 min
completed: 2026-06-18
status: complete
---

# Phase 115 Plan 01: GATE-02 Verifier Hardening Summary

**Closeout verifier contracts now fail closed on malformed phase lists and bare validation ledgers while preserving report-first Mix diagnostics.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-06-18T15:13:24Z
- **Completed:** 2026-06-18T15:20:48Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added RED coverage for strict `expected_phases`, invalid-contract skip behavior, ledger evidence validation, accepted exceptions, and Mix task report-first failure.
- Added `closeout.expected_phases` as a stable verifier check and removed the hardcoded fallback phase-set behavior.
- Made `validation_ledger_check/2` and prior-debt validation require concrete ledger evidence, while allowing first-class accepted exceptions for historical zero-ledger phases.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add failing verifier and Mix task coverage for strict closeout contracts** - `e030963` (test)
2. **Task 2: Implement report-first fail-closed expected phases and evidence validation** - `6579810` (feat)

**Plan metadata:** committed separately after this summary.

_Note: Task 1 intentionally left the focused suite red before implementation._

## Files Created/Modified

- `lib/crosswake/planning/closeout_verifier.ex` - Adds strict expected-phase parsing, the `closeout.expected_phases` check, invalid-contract skips, ledger evidence validation, and accepted-exception validation.
- `test/crosswake/planning/closeout_verifier_test.exs` - Covers strict expected-phase behavior, no-active relaxation, ledger evidence acceptance/rejection, zero-ledger blocking, and accepted exception behavior.
- `test/mix/tasks/closeout_verify_test.exs` - Covers rendered `closeout.expected_phases` output before `Mix.Error` on malformed expected phases.
- `.planning/phases/115-closeout-verifier-honesty-ledger-backlog-doc-truth/115-01-SUMMARY.md` - Captures this plan outcome.

## Decisions Made

- Kept parsing intentionally narrow: only non-empty inline `expected_phases: ["..."]` arrays are accepted.
- Preserved `Mix.Tasks.Closeout.Verify` behavior; the Mix task still renders the full report before raising.
- Relaxed every current-closeout artifact check in no-active-closeout state so mid-milestone planning edits stay non-blocking.

## Verification

- `mix test test/crosswake/planning/closeout_verifier_test.exs test/mix/tasks/closeout_verify_test.exs` - passed, `27 tests, 0 failures`.
- `mix closeout.verify` - passed, `0 blocking`.
- RED proof: the same focused test command failed before Task 2 with 9 failures covering missing `closeout.expected_phases`, malformed expected phases, bare/invalid ledger evidence, accepted exception handling, and Mix task report-first failure.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope expansion; implementation stayed inside the planned verifier and test surfaces.

## Issues Encountered

The first GREEN run showed no-active closeouts were non-blocking but dependent skipped checks still displayed `invalid expected_phases` observations. The implementation was adjusted so inactive closeout relaxation rewrites all current-closeout artifact checks to the existing no-active-closeout observation.

## Known Stubs

None. Stub scan found only ordinary parser empty-value checks in verifier logic, not placeholders or unwired data.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for 115-02. The verifier now has the GATE-02 behavior needed before DEBT-01 ledger normalization: strict closeout phase contracts, concrete ledger evidence requirements, and accepted exception handling for historically non-reconstructable ledgers.

## Self-Check: PASSED

- Found: `lib/crosswake/planning/closeout_verifier.ex`
- Found: `test/crosswake/planning/closeout_verifier_test.exs`
- Found: `test/mix/tasks/closeout_verify_test.exs`
- Found: `.planning/phases/115-closeout-verifier-honesty-ledger-backlog-doc-truth/115-01-SUMMARY.md`
- Found commits: `e030963`, `6579810`

---
*Phase: 115-closeout-verifier-honesty-ledger-backlog-doc-truth*
*Completed: 2026-06-18*
