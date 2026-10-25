---
phase: 184-twin-probe-and-safe-preflight
plan: 02
subsystem: twin-proof-lane
tags: [git, source-probe, refusals, fail-closed]
requires: [184-01]
provides:
  - probe_source/2 refusals {:refused, :hiding_config} and {:refused, :not_toplevel}
  - verified fail-closed parse, version, timeout, raise and NUL branches
affects: [184-03]
key-files:
  modified:
    - /private/tmp/crosswake-phase180-impl/lib/crosswake/proof_lane/twin_producers.ex
    - /private/tmp/crosswake-phase180-impl/test/support/twin_git_fixtures.ex
    - /private/tmp/crosswake-phase180-impl/test/crosswake/proof_lane/twin_source_probe_test.exs
status: complete
commits: 0
plan_head_before: 50fcd5743243c0b20275a7e2bd9338bf25468687
plan_head_after: 50fcd5743243c0b20275a7e2bd9338bf25468687
actuals:
  tasks: 2
  commits: 0
---

# Phase 184 Plan 02: Configuration refusals and fail-closed git paths Summary

The twin source probe now refuses a candidate whose git configuration can hide changes before it counts anything, and every malformed, failing, hung or raising git path ends as unavailable with no path in the returned value. Nothing is committed; the candidate stays uncommitted until 184-06, and no commit, staging or planning-doc commit was made in the recovery checkout.

## Refusal order in probe_source/2

NUL check -> version gate (bare call) -> `git config --list --local --includes -z` (keys downcased) -> `info/attributes` active lines -> `rev-parse --show-toplevel` compared with the candidate by {major_device, inode} -> absolute git dir -> real `ls-files -v -z` -> containment check -> private temp index (read-tree, fresh ls-files, status) -> removal -> `info/exclude` count.

- `{:refused, :hiding_config}`: any `filter.*` key (local or from an include file), `core.bare` truthy, `core.symlinks` falsy, `extensions.worktreeconfig` truthy, or an active `info/attributes` line. Valueless key counts as true.
- `{:refused, :not_toplevel}`: toplevel and candidate differ by device and inode (subdirectory or `core.worktree` redirect). A probe reason only, not a receipt cause; `clean_tree` and `freeze` map both refusals to `source_dirty`, `dirty_count` returns nil. No receipt cause atom or schema version was added.
- The `with` else clause now passes `{:refused, _}` through instead of collapsing it to `:unavailable`.
- An empty or non-NUL-terminated config listing is `:unavailable`.

## Tests (probe file: 17 -> 35, all passing under --trace)

Task 1 (8): redirect refused as not top-level (through freeze, no expectations.json), local filter key (including mixed-case subsection), included filter key, active info/attributes line, comment-only info/attributes not refused, bare/symlinks=false/worktreeConfig refused (with the false/true control not refused), subdirectory candidate refused, symlink alias not refused.

Task 2 (10): zero tracked entries, repository without commits, unknown ls-files tag, truncated -z output (ls-files, fresh status and config), non-H entry in the fresh index, rejected argv (rc 128 and 129), version floor (2.40.9, 2.9.0, unparseable fail with exactly one call and no retry; 2.41.0 and Apple Git accepted), raising spawn (ArgumentError and ErlangError at version, ls-files and config calls; marker path absent), NUL path (zero spawns), hung call (50 ms timeout).

Fixture helpers added: `worktree_redirect!/1`, `include_config!/3`.

## Results

- Probe file: 35 tests, 0 failures (`trace-184-02-t1.out`, `trace-184-02-t2.out`). Producers plus verify_twin suites: 65 tests, 0 failures.
- All 18 named tests appear in the trace. Inventory ledger check OK; compile warnings-as-errors clean; format check clean; no `assert/refute Enum.all?/any?(` added; `twin_runtime.ex` untouched; one non-comment `git_cmd.(` site.
- Candidate HEAD unchanged (50fcd57); recovery index empty.

## Deviations from Plan

None. No fix to probe behaviour was needed beyond the planned refusal code: every new test passed on its first run. The 184-01 note about describe-wrapped trace names did not apply because all 18 new tests are top-level.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

Files exist in the candidate; trace gates matched all 18 names; candidate HEAD and recovery index verified.
