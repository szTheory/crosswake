---
phase: 97-fix-guide-accuracy-conn-assigns-claim-record-in-multi-arity
plan: 01
subsystem: testing
tags: [elixir, phoenix, threadline, documentation, parity-test, regression-prevention]

# Dependency graph
requires:
  - phase: 96-docs-contract-proof
    provides: guides/threadline.md hermetic parity test (phase96_threadline_docs_contract_test.exs) that guards the doc contract
provides:
  - Corrected Propagation Contract wording: Logger.metadata()[:crosswake_thread_id] read-path (WR-03)
  - Corrected record_in_multi arity: /3 not /2 in Operations > Scaffolding the ledger (WR-02)
  - Two regression-prevention assertions in phase96 parity test guarding WR-03 and WR-02
affects: [guides, threadline, docs-contract, phase96-parity-test]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Regression guard assertions use the most-specific substring (Logger.metadata()[:crosswake_thread_id]) rather than a shared substring (Logger.metadata) that already exists in unrelated prose"

key-files:
  created: []
  modified:
    - guides/threadline.md
    - test/crosswake/proof/phase96_threadline_docs_contract_test.exs

key-decisions:
  - "Use exact read-path string Logger.metadata()[:crosswake_thread_id] in both the guide and the regression assertion — bare 'Logger.metadata' already appears at lines 7/15 of the guide and cannot detect the bug"
  - "Add regression assertions to the existing phase96 test file rather than creating a new file — keeps the hermetic lane unified with zero new test infrastructure"

patterns-established:
  - "Regression guard pattern: assert the most-specific distinguishing substring absent before the fix, not a generic substring that pre-exists in unrelated prose"

requirements-completed: [WR-03, WR-02, D-03]

# Metrics
duration: 13min
completed: 2026-06-10
---

# Phase 97 Plan 01: Fix Guide Accuracy (conn.assigns + record_in_multi arity) Summary

**Corrected two adoption footguns in guides/threadline.md: replaced the incorrect conn.assigns claim with the Logger.metadata()[:crosswake_thread_id] read-path (WR-03) and fixed record_in_multi arity from /2 to /3 (WR-02), with two regression-prevention assertions keeping all 23 parity tests green**

## Performance

- **Duration:** ~13 min
- **Started:** 2026-06-10T19:53:57Z
- **Completed:** 2026-06-10T20:06:56Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- Removed the `conn.assigns[:thread_id]` claim from the Propagation Contract section — `Crosswake.Plug.Threadline` never calls `Conn.assign/3`; the thread id is stored in `Logger.metadata` under `:crosswake_thread_id` and echoed via `Conn.put_resp_header`
- Added the explicit downstream read-path `Logger.metadata()[:crosswake_thread_id]` to the guide (matches the verbatim string already exercised in `threadline_test.exs`)
- Fixed `record_in_multi/2` to `record_in_multi/3` to match the generated template signature `record_in_multi(multi, name, attrs)` — adopters following the old guide would get a `FunctionClauseError`
- Added two targeted regression assertions to `phase96_threadline_docs_contract_test.exs`; all 23 tests (21 original + 2 new) pass green

## Task Commits

1. **Task 1: Fix WR-03 + WR-02 guide lines and add two regression-prevention assertions** - `e1d30f3` (fix)

**Plan metadata:** (SUMMARY commit — see final commit below)

## Files Created/Modified

- `guides/threadline.md` — Corrected Propagation Contract line 22 (conn.assigns -> Logger.metadata read-path) and Operations line 128 (record_in_multi/2 -> /3)
- `test/crosswake/proof/phase96_threadline_docs_contract_test.exs` — Added WR-03 and WR-02 regression guard assertions before the module-closing end

## Decisions Made

- Used the exact read-path string `Logger.metadata()[:crosswake_thread_id]` in both the guide text and the regression assertion. Bare `Logger.metadata` already appears in unrelated prose at lines 7 and 15 of the guide and would not detect the bug.
- Added the two new assertions to the existing phase96 test file (not a new file) per D-03, to keep the `merge-blocking-threadline-docs-contract-proof` CI lane unified.

## Deviations from Plan

None - plan executed exactly as written. The guide edits, source file confirmations, and test assertions all matched the plan specifications.

## Issues Encountered

`mix deps.get` was needed before running tests in the worktree (dependencies not yet fetched in the worktree). This is expected worktree initialization behavior, not a code issue.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- WR-02 and WR-03 are closed. The phase-96 hermetic parity lane now guards both regressions.
- v7.0 Threadline Audit Capstone: all known open review items addressed. Ready for `/gsd:new-milestone` to begin v8.0 planning.

---
*Phase: 97-fix-guide-accuracy-conn-assigns-claim-record-in-multi-arity*
*Completed: 2026-06-10*

## Self-Check: PASSED

- `guides/threadline.md` exists and contains `Logger.metadata()[:crosswake_thread_id]`
- `test/crosswake/proof/phase96_threadline_docs_contract_test.exs` exists and contains both regression assertions
- Commit `e1d30f3` exists in git log
- 23 parity tests pass green
