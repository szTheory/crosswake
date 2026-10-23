---
phase: 184-twin-probe-and-safe-preflight
plan: 07
status: complete
gap_closure: true
requirements: [PROBE-01, PROBE-02, PROBE-03, PROBE-04]
commits: 0
plan_head_before: 1f5d18ee1c637560f7a5b62472dd83db43da7e92
plan_head_after: 1f5d18ee1c637560f7a5b62472dd83db43da7e92
actuals:
  tasks: 4
  commits: 0
---

# Phase 184 Plan 07: Review-gap closure (CR-01, WR-01..05, IN-01, IN-02) Summary

Candidate git hooks no longer run in the twin probe, an uncommitted ignore-all .gitignore now blocks, the source gate and preflight task can no longer raise, and the effectful-path source test can no longer pass vacuously. All edits are uncommitted in /private/tmp/crosswake-phase180-impl; 184-08 makes the single commit. `commits: 0` is correct: this plan commits nothing by design (execution_boundary).

## Changed paths (candidate-relative, all uncommitted, exactly the nine allowed)

- guides/see_it_run.md
- lib/crosswake/proof_lane/twin_preflight.ex
- lib/crosswake/proof_lane/twin_producers.ex
- lib/crosswake/proof_lane/twin_runtime.ex
- lib/mix/tasks/crosswake.proof_lane.twin_preflight.ex
- test/crosswake/proof_lane/twin_runtime_check_test.exs
- test/crosswake/proof_lane/twin_source_probe_test.exs
- test/mix/tasks/crosswake_proof_lane_twin_preflight_test.exs
- test/support/twin_git_fixtures.ex

Candidate HEAD still 1f5d18ee1c637560f7a5b62472dd83db43da7e92; nothing staged in the recovery checkout.

## Gate results (real exit codes, RUNS files with -184-07 suffix)

| Task | Command scope | Exit | Result |
|---|---|---|---|
| 1 | probe + preflight task tests | 0 | 71 tests, 0 failures |
| 2 | probe + producers + verify_twin | 0 | 120 tests, 0 failures |
| 3 | probe + runtime_check + producers + verify_twin | 0 | 128 tests, 0 failures |
| 4 | preflight + runtime_check | 0 | 26 tests, 0 failures |
| 4 | test/crosswake/guides | 0 | 196 tests, 0 failures (7 excluded) |
| 4 | mix crosswake.docs.sync --check | 0 | passed |

## The 17 named tests (all exist, all pass)

1. a candidate post-index-change hook never runs during the probe
2. a hook under a local core.hooksPath never runs and the probe stays clean
3. a candidate hook never runs during the source gate
4. a candidate hook never runs during the preflight
5. an untracked .gitignore that ignores everything blocks
6. an untracked directory whose own .gitignore ignores everything blocks
7. files ignored by a committed .gitignore are not counted
8. an unreadable lock file blocks the source gate instead of raising
9. file_digest of a directory returns an error
10. a read error mid-stream makes file_digest return an error
11. an inherited GIT_TRACE variable is scrubbed
12. a git_cmd raising an unexpected exception is unavailable and the caller survives
13. commit/1 never removes a run root path it did not create
14. a raising check is blocked with exit 2 and no message text
15. the probe's temporary index is created under TMPDIR, which the listings snapshot
16. the preflight never calls the effectful run path (rewritten: __DIR__-anchored, positive anchors, non-empty, word-bounded bare-call/atom/capture matcher)
17. the effectful-path matcher catches calls, atoms and capture references

Tests 1-4 each include an unpinned positive control proving the planted hook does run for plain git.

## WR-01 final git call shape and observed counts

Inside the fresh-index callback, after the status count, under the same pinned builder and `GIT_INDEX_FILE`:

- `git <pins> -C <path> ls-files --others --ignored --exclude-standard --directory -z` (NUL framing strict; empty output is zero; missing final NUL is unavailable; bounded by @max_dirty_count)
- `git <pins> -C <path> check-ignore --verbose --non-matching -- <entries...>` in batches of 200; exit 0 or 1 accepted, anything else is unavailable. Output is `source:line:pattern<TAB>path`, one line per entry; line count must equal entry count.

Deviation from plan text: `check-ignore -z` is only valid with `--stdin` (git 2.41 prints "-z only makes sense with --stdin"), and `run_git` has no stdin, so records are parsed by newline/tab instead of NUL. Quoted paths stay on one line, so framing holds.

Counting rule: an entry counts as one modified finding if its deciding rule source is not a `.gitignore` tracked in the fresh (HEAD) index and not `.git/info/exclude` (skipped; the excludes count covers it). An ignored directory entry with no deciding rule of its own (`::`) is skipped because it is listed only for its fully ignored members, which are listed and judged separately. `--directory` was kept: it did not hide the nested `.gitignore` (git lists the members as well).

Observed exact counts: untracked root `.gitignore` containing `*` plus `evil.ex` gives modified 2; untracked directory `hidden/` holding its own `.gitignore` (`*`) plus `evil.ex` gives modified 3 (the directory, its .gitignore, evil.ex); a file ignored by a committed `.gitignore` gives modified 0.

## Gap decisions as applied

- CR-01 (amends D-05; to be recorded as D-34 by 184-08): `-c core.hooksPath=/dev/null` added to @git_pins, pin-only, no refusal. Version call stays bare (D-30). A local `core.hooksPath` does not cause a refusal or a hook run.
- WR-02: `lock_digests/2` uses a digest function and returns `{:blocked, :identity_unknown}` on any error; `file_digest/2` gained a `:read_chunk` seam and returns `{:error, reason}` on a mid-stream read error (never a prefix digest); `source_gate/3` forwards a `:file_digest` option; the preflight task wraps the check in rescue/catch and maps to exit 2, cause prerequisite_missing, a fixed path-free action, via a `:check` seam.
- WR-03: moduledocs of TwinPreflight and the task, the source_gate and probe docs, and the guide now state: no report or run root written, a private temporary index created and removed outside the candidate and run root, origin port bound and released for an instant. Line 3 of the output is unchanged. The TMPDIR-location test proves the leaves-nothing snapshot covers the temp index.
- WR-04: `maybe_create_root/1` removes only a root whose own `mkdir` succeeded and whose later `chmod` failed; an existing path is left untouched.
- WR-05 (D-31): no behavior change. TwinPreflight moduledoc and the guide state that the real run does not repeat the record-to-identity digest comparison and that Phase 188's scripted pre-run check ("matching digests", TWIN-07) is where it gates the real run. Orchestrator should keep this as an explicit open item for Phase 188.
- IN-01: source test rewritten as described above.
- IN-02: (a) every inherited `GIT_*` variable is unset at spawn time via a merged map (inherited names nil, then the static scrub and fixed values, then the per-call `GIT_INDEX_FILE`); builder-conformance helper in the probe test now requires every fixed value and allows only nil-valued extras; (b) the spawn task body rescues any exception and catches throw/exit, returning `:unavailable`. Deferred (recorded in a code comment): an orphaned OS git child after a timeout. Reopen trigger: a hung or leftover git process observed during a preflight or twin run.

## New guide SHA-256 (for the orchestrator's STATE reconciliation line)

guides/see_it_run.md: 603976aedda6c4fc0879252a8b05a9db3d20e00fe1acc6bb230783504e65e0f3 (candidate, uncommitted; docs sync and guide tests pass).

## Deviations from Plan

**1. [Rule 3 - Blocking] check-ignore without -z.** Described above; same strict parsing guarantees, no new cause or schema field.

**2. Mutation controls not run here.** The plan assigns them to 184-08; only the positive controls and the named tests were run in this plan.

Otherwise the plan was executed as written. Tests for Tasks 2-3 were written before the implementation in the same pass, but the red phase was not separately executed; the 184-08 mutation controls are the check that each new test fails without its fix.

## Known Stubs

None.

## Threat Flags

None. No new network endpoint or trust-boundary surface was added; the new git calls (`ls-files --others --ignored`, `check-ignore`) use the same pinned, hook-disabled, scrubbed-env builder.

## Self-Check: PASSED

Nine candidate paths changed and no others; all 17 named tests found by exact name; all gate exit files are 0; candidate HEAD unchanged; recovery index empty.
