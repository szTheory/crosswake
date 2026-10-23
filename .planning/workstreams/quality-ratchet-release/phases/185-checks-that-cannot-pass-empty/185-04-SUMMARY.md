---
phase: 185-checks-that-cannot-pass-empty
plan: 04
status: complete
requirements: [GUARD-03, GUARD-02]
commits: 0
note: "Plan rules forbid committing; all product edits are uncommitted in the candidate."
actuals:
  tasks: 3
  commits: 0
---

# Phase 185 Plan 04: Both lockfiles or no identity Summary

Every place that digests the lockfiles now blocks with `identity_unknown` unless both `mix.lock` and `examples/phoenix_host/mix.lock` are digested, and the two verify_twin loops have length floors.

## What was checked and what happened

- Fixture first: the verify_twin test setup now writes the host lockfile and the three git-fixture tests add both lockfiles. On the unchanged lib this file passed (25 tests, 0 failures; `pre-185-04.out`), so the fixture change alone altered no verdict or count.
- Freeze side (`verify_twin.ex` `lock_digests/1`): three new tests were run before the fix (`red-185-04-freeze.out`, exit 2, 28 tests, 3 failures: host lock missing, root lock missing, unreadable). After the fix the file passes: 28 tests, 0 failures (`t1-185-04.out`). The old `{:error, :lock_files_missing}` is gone; both lockfiles must be regular (lstat) and readable, else `{:blocked, :identity_unknown}`, which `conduct/2` turns into a written blocked receipt with `first cause: identity_unknown` and exit 2.
- Source gate and observation (`twin_producers.ex`): `lock_digests/2` digests every `@lock_rels` entry with no `File.stat` pre-filter. `observe_identities` sets `locks` to nil unless both lockfiles digest, and the `dependency_lock` and `backend_build` joins test it for non-nil. Five tests were added; before the fix 4 failed (`red-185-04-producers.out`, exit 2, 48 tests, 4 failures). After the fix twin_producers and twin_source_probe pass: 135 tests, 0 failures (`t2-185-04.out`).
- Twin quick suite (eight files): 233 tests, 0 failures, exit 0 (`quick-185-04.out`). Formatting passes on all four edited files. No `assert/refute Enum.all?/any?(` line was added (`diff-185-04.out`). Both real candidate lockfiles are regular files, not symlinks (`locks-185-04.out`).
- Floors: `assert length(lines) == 4` added before the two loops, now at L647 and L709 of `crosswake_proof_lane_verify_twin_test.exs` (loops at L649 and L711). `185-LOOP-MEASUREMENT.md` rows updated to fixed.

## Tasks

1. Tracer (done): freeze side red then green; floors added.
2. Source gate and observation (done).
3. Quick suite and controls (done).

## Deviations from Plan

**1. [Rule 1 - plan assumption wrong] The unreadable-lockfile source-gate test does not use a real chmod 000.** The plan said the mode change is untracked so the tree stays clean. In practice git reports the tree dirty after chmod 000, so the gate blocks with `source_dirty` before reaching the lock check (seen in the red run: `left: {:blocked, :source_dirty}`). The test now injects an unreadable digest for the host lockfile through the existing `:file_digest` option on a clean committed tree, and explains this in a comment. That test is therefore a control and was not red on the old code (the old code already blocked when a stat-visible file failed to digest). The real-chmod unreadable test remains on the freeze side, where it was red. The other three producer tests (host never committed, root never committed, observation) were red on the old code.
- Also added a control test "both lockfiles present passes the source gate".
- The red run for producers was captured before the unreadable test was rewritten; the later green run replaces it, so `red-185-04-producers.out` lists that unreadable test failing as source_dirty rather than as a lock failure.
- The observation test deletes the host lockfile, which also makes the tree dirty and so drops the source join; it still proves the new rule because `dependency_lock` was present before the fix.

## Behaviour change

A symlinked lockfile used to be skipped on the freeze side (not a regular file); it now blocks with `identity_unknown`.

## Files

Candidate (uncommitted): `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex`, `lib/crosswake/proof_lane/twin_producers.ex`, `test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs`, `test/crosswake/proof_lane/twin_producers_test.exs`. `test/support/twin_git_fixtures.ex` did not change. No cause atom, `TwinReceipt` or schema version changed.

## Known Stubs

None.

## Self-Check: PASSED
