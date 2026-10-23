---
phase: 187-doctor-and-proof-fidelity
plan: 03
subsystem: proof-lane
tags: [provenance, git, sentinel, navigation-shell]
requires: [187-01, 187-02]
provides:
  - Crosswake.ProofLane.Provenance.read/1, commit_ref/1, template_version/1, crosswake_version/0
  - verify_navigation_shell records real crosswake version, template version and host commit
affects: [187-06, 187-07]
actuals:
  tasks: 2
  commits: 0
  note: "uncommitted by design; the single phase commit belongs to 187-07"
key-files:
  created: [lib/crosswake/proof_lane/provenance.ex, test/crosswake/proof_lane/provenance_test.exs]
  modified: [lib/mix/tasks/crosswake.proof_lane.verify_navigation_shell.ex, test/mix/tasks/crosswake_proof_lane_verify_navigation_shell_test.exs, CHANGELOG.md]
requirements-completed: [DOCTOR-03]
status: complete
completed: 2026-10-16
---

# Phase 187 Plan 03: Real Navigation-Shell Provenance Summary

**verify_navigation_shell now writes the real crosswake version, the host template version and the host commit, with exact sentinels ("unknown" / "git-unknown") where a value cannot be known; the "0.1.0", "161" and all-zero placeholders are gone.**

Edits are uncommitted in the candidate; nothing was staged or committed. Preconditions held (HEAD bd294007, push URL no-push-phase180, 187-01 and 187-02 summaries present, no BLOCKED file, tree equal to RUNS/status-187-02.txt before starting).

## Red and green evidence (RUNS = /private/tmp/crosswake-phase180-run)

| Step | Result |
|------|--------|
| Task 1 red (red-187-03-t1.out, exit 2, 6 tests, 5 failures) | P_CLEAN, P_NOGIT, N_INV, N_SRC failed as required; the fifth failure was the existing positive task test, broken since 187-02 by the all-zero placeholder |
| Task 1 green (t1-187-03.out, exit 0) | 6 tests, 0 failures |
| Task 2 red (red-187-03-t2.out, exit 2, 11 tests, 2 failures) | P_DIRTY and P_MAN failed; controls P_ENV, P_UNTR, P_EMPTY, P_MISSING, P_PATH, P_MANBAD, P_VSN passed |
| Green (green-187-03.out, exit 0) | proof_lane + task test + guides: 510 tests, 0 failures (7 excluded) |
| compile --force --warnings-as-errors, docs.sync --check, format --check | all exit 0 |

All test runs used a fresh MIX_ENV=test build path (`_build_187_03_test`), so the 187-02 "TwinGitFixtures not available" artifact did not recur.

## What changed

- `provenance.ex` (new): `read/1` returns the three keys. `commit_ref/1` uses `System.find_executable("git")` and `System.cmd/3` with fixed argv, `cd:` the host dir and the GIT_DIR/GIT_WORK_TREE/GIT_INDEX_FILE scrub. It runs `rev-parse HEAD`, requires a hex match, then `--no-optional-locks status --porcelain --untracked-files=no` must be exactly `{"", 0}`; every other outcome, including rescued `ErlangError`/`File.Error`, is `"git-unknown"`. No shell, logging or `.git` parsing. `template_version/1` reads the iOS manifest `template_version` when an integer in 1..99_999_999, else the generator constant, else `"unknown"`. `crosswake_version/0` loads the app and maps a nil vsn to `"unknown"`.
- `verify_navigation_shell.ex`: `evidence_input/1` merges `Provenance.read(File.cwd!())`; all other keys unchanged and `device_class: :unknown` is kept.
- Tests: `provenance_test.exs` (11 tests, names exact); N_INV and N_SRC added to the task test.
- `CHANGELOG.md` [Unreleased]: one bullet added after 187-01's lines (none removed).

## Observations

- **A1 (System.cmd env `{key, nil}` unsets the variable for the child):** confirmed. P_ENV sets GIT_DIR to a second repo with a different HEAD and the read still returns the host repo's HEAD. The test helper also relies on the scrub.
- **P_ENV passed as a control on Task 1's code**, as the plan expects, because the scrub landed in Task 1. Its load-bearing evidence is 187-06 mutation control 19 (remove the scrub; P_ENV must fail). No scratch mutations were run here.
- **commit_ref the task wrote in the dirty candidate:** expected `git-unknown` (tracked files differ from HEAD). I did not print the retained value; N_INV asserts only the invariant regex, which accepts either form.

## Deviations from Plan

**1. [Test fix] P_ENV first failed because both temp repos produced identical commits** (same content, same second), so the `refute head == other` guard tripped. Fixed in the test by giving the second repo a different second commit. No code change.

**2. [Process] The first template_version edit silently did not apply** (the formatter had rewritten the one-line `do:` form I was matching), so the first Task 2 green run showed P_MAN failing. Reapplied; green afterwards. No scope change.

Otherwise the plan was executed as written.

## Known Stubs

None.

## Threat Flags

None. T-187-09 to T-187-13 mitigations are implemented and covered by tests; the tracked-file race between rev-parse and status is the accepted advisory-lane window.

## Self-Check: PASSED

provenance.ex and provenance_test.exs exist; the placeholders are absent from the task source; provenance.ex has no shell, `:os.cmd`, Logger or IO output; mix.exs and mix.lock unchanged; status-187-03.txt lists only the cumulative allowlist plus this plan's four files and CHANGELOG; no RUNS output of this plan contains the home path; no commits or staged files; HEAD unchanged.
