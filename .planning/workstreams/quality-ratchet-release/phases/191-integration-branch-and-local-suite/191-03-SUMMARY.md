---
phase: 191-integration-branch-and-local-suite
plan: 03
status: complete
requirements: [LAND-02]
commits: 0
key-files:
  created:
    - scripts/suite-gate-191.sh
    - scripts/selftest-suite-191.sh
    - 191-EVIDENCE/selftest-suite-191.out
---

# Phase 191 Plan 03: Suite gate Summary

The new suite gate refuses to report a pass for an empty, crashed, partly blocked, skipped or moving test run. Its self-test ran 30 controls against fake repositories and every one behaved as expected (`selftest-suite: controls 30 of 30 as expected`). The old export of the C locale to child test processes is gone: children now get `C.UTF-8`, and the C locale is used only by sort, comm and the pinned git helper.

## What it does

- Five modes: `root`, `all`, `host`, `swift`, `subset`. There is no baseline mode; the old name exits 2 with `suite-gate: unknown mode`.
- Every mode needs a floor above 0; a missing or zero floor exits 2 with `suite-gate: floor required`.
- Totals lines are matched with the strict regex; a malformed line exits 2, and the number of totals lines must match the mode (1, or 7 for the root-proof log in mode `all`).
- Mode `all` needs exactly nine stage logs that each start `status=0`. A missing, failed or BLOCKED stage is a failure, never a skip. Lane floors and the main lane's excluded count are checked.
- Mode `subset` passes only if the failing names equal the expected-red file exactly (A-1).
- Before and after a run: the pinned git status (untracked files included) must be empty and HEAD must equal the argument. Exit codes go to files. Evidence is written to a temp file and renamed only after validation, and holds only parsed numbers, stage statuses and test names.

## Verification

- Task 1 verify (tracer S01-S03, syntax, old mode name): passed.
- Task 2 verify: 30 of 30 controls, a fresh run is identical to `191-EVIDENCE/selftest-suite-191.out`, all five modes have case branches.
- Two mutation checks (child given the C locale; head check removed) made the self-test fail, so the controls do bite.

## Deviations from Plan

None that change behavior. Choices where the plan was open:
- Mode `all` and `swift` do not force `MIX_ENV=test` (the orchestrator and Swift decide their own environment); `root`, `host` and `subset` do.
- Lane names in evidence are `companion-1`..`companion-5`, `phase41`, `main`. The floors file is seven lines `lane N`.
- Added controls S25-S30 (fake mix rejects the C locale, empty expected-red file, host pass, listed Swift skip, expected-red missing, old mode name), so 30 controls instead of 24.
- Test hooks `SUITE191_EV` and `SUITE191_R` let the self-test redirect evidence and run folders; they are used only by the self-test.
- Assumption A1 (seven totals lines) is still unmeasured against a real run; the first real `all` run will confirm it.

## Known Stubs

None.

## Commits

None, per the recovery-checkout rule; files are plain uncommitted files.

## Self-Check: PASSED
