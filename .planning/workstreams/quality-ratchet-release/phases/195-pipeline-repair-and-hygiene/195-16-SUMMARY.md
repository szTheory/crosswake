---
phase: 195-pipeline-repair-and-hygiene
plan: 16
subsystem: infra
tags: [ci, secret-masking, gap-closure, add-mask-guard]
requires:
  - phase: 195-15
    provides: maskSecretShapes on origin/main (merge commit 5862a3d)
provides:
  - "Local branch fix/secret-mask-key-forms (6 commits, not pushed) changing only script/verify_repository.mjs and test/js/ci_secret_masking.test.mjs"
  - "maskSecretShapes masks escaped-JSON, Elixir tuple, quoted-Bearer, next-line, CLI-flag, curl-user and double-equals credential forms"
  - "Named value capture groups (GR-10) and a stricter add-mask guard matcher (GR-02)"
  - "Evidence: mask-gr-crit-red-195.txt, mask-gr-crit-control-195.txt (committed on docs/195-closeout)"
affects: [195-17, 195-18]
requirements-completed: [REL-03]
actuals:
  tokens: 110000
  tasks: 3
  commits: 6
  plan_head_before: 5862a3dc234f81dfc0ca580bfd6cce8c60608eae
  plan_head_after: c867af26c88c3f3f93f1638be9ab6f7799545356
completed: 2026-10-26
status: complete
---

# Phase 195 Plan 16: Critical round-2 secret-mask forms Summary

**maskSecretShapes now masks credential keys written as escaped JSON, Elixir tuples, quoted Bearer values, next-line values, CLI flags, curl `-u` and `==` comparisons, and the add-mask guard rejects single-quoted or unterminated masks; every new test was recorded red first and replayed from its red commit.**

## What was checked and what happened

- Branch `fix/secret-mask-key-forms` was cut from origin/main (5862a3d). Three `test(ci):` red commits each precede their `fix(ci):` commit. Nothing was pushed; the fix branch commits only the two source files.
- Task 1 (tracer): `escaped_json_multiword` was red, then fixed. `SECRET_VALUE_SOURCE` now has named groups (`escOpen`, `escBody`, `escClose`, `dqBody`, `dqClose`, `sqBody`, `sqClose`, `bare`); `maskValue` reads them from the replacer groups object. A shared `KEY_QUOTE` lets rules a, b, d and the generic rule accept a backslash-escaped key quote. With the mask removed, the spawned-child test reported `leaked: 26 of 26`.
- Task 2: 17 tests were red (13 gap rows, the spawned-child test, 3 accepted over-mask pins); `escaped_json_authorization` was already masked by rule a and is recorded as `already_masked`. New rules: next-line pass (first, one forward pass, ExUnit `N) test` and `Finished in` lines never masked), tuple, CLI flag, curl user, reworked Bearer, `authorization` (left-bounded) and `[:=]{1,3}` in the generic rule. The former prose row `code: assert token == "expected-value"` is now pinned in `ACCEPTED_OVERMASK`. Eight new LINEAR_INPUTS rows of 200,000+ characters all ran in 11 ms or less (budget 1500 ms).
- Task 3: the single-quoted, unterminated and derivationScript fixtures were red; the test-local `isMaskLine` now accepts only an unquoted mask or a double-quoted one closing right after the name. Live workflow tree still has at least 1 derived assignment and 0 violations. Criticals control with the mask removed: `leaked: 43 of 43`.
- Full JS suite on the fix branch: 220 pass, 0 fail. `repository_verification` 41 pass. Source privacy scan: clean, 2 files. Evidence privacy scan: clean, 2 files; all log scans record `seed hits 0`.
- Red replay: for each task the recorded red commit was exported with `git archive` outside the repository and its tests failed again with the expected names and 0 seed hits.

## Heads

- Fix branch `fix/secret-mask-key-forms`: c867af26c88c3f3f93f1638be9ab6f7799545356 (6 commits ahead of origin/main).
- Red commits: 7741f0b (task 1), 093a9dd (task 2), 23a5dd8 (task 3).

## Deviations from Plan

**1. [Rule 3 - Blocking] Committed the orchestrator's STATE.md edit before branching**
- **Found during:** precondition check. `git status --untracked-files=no` was not empty because `state.begin-phase` had modified STATE.md, and the task 3 gate requires an empty status after the switch back.
- **Fix:** committed STATE.md alone on docs/195-closeout (44f37cd6) before `git switch -c fix/secret-mask-key-forms origin/main`.

**2. [Rule 3 - Blocking] Privacy script needs bash**
- The script reads `BASH_SOURCE`; running it under zsh exited 2. Ran it with `bash`; rc 0.

**Total deviations:** 2 auto-fixed. **Impact:** none on scope or results.

## Known Stubs

None.

## Threat Flags

None.

## Residual risk (carried from the plan)

The masker is an enumerated list of shapes; shapes nobody listed are not covered. The next-line pass over-masks plain text after a key line ending in a separator; this is pinned in `ACCEPTED_OVERMASK`. Rule a (authorization) does not yet carry the left boundary; plan 17 adds it.

## Next

Ready for 195-17 (continues on `fix/secret-mask-key-forms`); 195-18 ships the branch.

## Self-Check: PASSED

- Fix branch head c867af26 exists and changes exactly script/verify_repository.mjs and test/js/ci_secret_masking.test.mjs.
- Both evidence files are tracked on docs/195-closeout; all three task verify blocks passed.
