---
phase: 185-checks-that-cannot-pass-empty
plan: 01
subsystem: testing
tags: [elixir, guard, absence-is-not-success, scope-floor]
requires: []
provides:
  - strict invocation (exit 2) and pinned, doubly-derived scopes for script/check_absence_is_not_success.exs
affects: [185-05]
actuals:
  tokens: 9000
  tasks: 3
  commits: 0
plan_head_before: b898e1104b0feafdb569d1ae42972cb4e1c46629
plan_head_after: b898e1104b0feafdb569d1ae42972cb4e1c46629
key-files:
  modified:
    - script/check_absence_is_not_success.exs (candidate, uncommitted)
    - test/crosswake/proof/absence_is_not_success_test.exs (candidate, uncommitted)
    - .planning/seeds/SEED-023-extend-scope-cardinality-gate.md (planning checkout, uncommitted)
key-decisions:
  - "Test-files pin is 249 and must be re-confirmed by 185-05 at the final commit."
requirements-completed: [GUARD-01]
duration: 20min
completed: 2026-10-16
status: complete
---

# Phase 185 Plan 01: Absence checker cannot pass empty

**The absence checker now exits 2 for an unusable root or argument, exits 1 when any scope is empty, narrower than an independent walk, or below its pin, and prints counts in its OK lines.**

## What was checked and what happened

- Pin guard and preconditions passed (candidate at b898e110, push URL `no-push-phase180`, clean tree).
- Scope counts measured before any edit: test-files=249, todos=12, seeds=23, deferred-items=11 (`scopes-185-01.counts`).
- Red first: I wrote all new tests up front and ran them against the unchanged script: 13 failures of 23 (`red-185-01-t1.out`, exit 2). That covers all four root-floor tests and all nine scope tests.
- After the strict entry point only (Task 1 script), the four root floors went green and the nine scope tests stayed red: 9 failures of 23 (`red-185-01-t2.out`). The Task 1 green evidence (`t1-185-01.out`, exit 0) is the 14 non-scope tests (`--exclude describe:"scope floors"`).
- After the scope work: 23 tests, 0 failures (`green-185-01.out`, exit 0). `mix format --check-formatted` passes on both files.
- Direct runs (`direct-185-01.out`):
  - no argument: exit 0, "scanned 249 test files, pin 249" and "todos 12, seeds 23, deferred-items 11"
  - `--root /nonexistent-185-root`: exit 2, "root does not exist: /nonexistent-185-root"
  - `--root <candidate>/test`: exit 1, four scope failures plus "content checks were skipped"

## Exact @scopes literals

```
{"test-files", "test/**/*.exs", 249}
{"todos", ".planning/todos/*.md", 1}
{"seeds", ".planning/seeds/*.md", 1}
{"deferred-items", ".planning/**/deferred-items.md", 1}
```

The test-files pin is 249. No new test file was added, so 185-05 must re-confirm it at the final commit.

## Implementation notes

- Strict `OptionParser.parse(strict: [root: :string, min_test_files: :integer])`; any invalid or leftover argument halts 2; root existence and directory checks run before derivation.
- actual = `Path.wildcard` + `File.regular?`; expected = `:filelib.fold_files` (recursive scopes, dot-directories included) or a depth-1 `File.ls`; compared by `assert_full_scope/2`, an Elixir copy of `assertFullScope` with the same two reason strings. Content checks run over the already-derived lists.
- SEED-023 now records the Elixir copy as a deliberate second caller; `scripts/ci_monitor.cjs` is unmodified.

## Deviations from Plan

**1. [Process] Scope tests written together with root tests**
Tests for both tasks were written before the script changes, so the Task 1 red run covered all 13 new tests and the "red on Task 1 script" evidence was captured by a second run after the Task 1 script (`red-185-01-t2.out`). The Task 1 green run excludes the "scope floors" describe. All required red headers are present in the respective files. Impact: none.

Otherwise none; plan executed as written. No commits made (per checkout rules; 185-05 commits).

## Known Stubs

None.

## Self-Check: PASSED

Candidate `git status --porcelain` lists only the two plan files; nothing staged in the planning checkout; ci_monitor.cjs untouched.
