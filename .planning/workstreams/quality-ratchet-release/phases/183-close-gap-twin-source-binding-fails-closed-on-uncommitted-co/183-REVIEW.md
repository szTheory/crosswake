---
phase: 183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co
reviewed: 2026-10-15T00:00:00Z
depth: standard
scope: commit 50fcd574 (fix(183-03)) vs da214c59 in /private/tmp/crosswake-phase180-impl
files_reviewed: 10
files_reviewed_list:
  - guides/see_it_run.md
  - lib/crosswake/proof_lane/twin_journey.ex
  - lib/crosswake/proof_lane/twin_producers.ex
  - lib/crosswake/proof_lane/twin_receipt.ex
  - lib/crosswake/proof_lane/twin_runtime.ex
  - lib/mix/tasks/crosswake.proof_lane.verify_twin.ex
  - test/crosswake/proof_lane/twin_journey_test.exs
  - test/crosswake/proof_lane/twin_producers_test.exs
  - test/crosswake/proof_lane/twin_receipt_test.exs
  - test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs
findings:
  critical: 0
  warning: 4
  info: 4
  total: 8
status: issues_found
---

# Phase 183: Code Review Report (plan 183-03)

The two touched test files (twin_producers, verify_twin) pass locally: 65 tests, 0 failures.
The guard is well built for the cases it names: stderr is discarded by `sh -c 'exec "$@" 2>/dev/null'`
(verified: a missing git yields rc 127 and prints nothing on this macOS sh), the candidate path is
only ever an argv element, missing sh/git maps to `prerequisite_missing`, and no path reaches the
output. The remaining problems are bypasses of the "clean tree" definition itself, one misleading
operator message, and weak tests.

## Warnings

### WR-01: Tracked-file edits hidden by `assume-unchanged` / `skip-worktree` are reported as clean (fail-open)

**File:** `lib/crosswake/proof_lane/twin_producers.ex:759-785` (`probe/2`)
**Issue:** Reproduced in a scratch repo. After `git update-index --assume-unchanged f` and
`git update-index --skip-worktree g`, with both files then modified, the exact status invocation
used by `probe/2` (`core.excludesFile=/dev/null`, `-z --untracked-files=all
--ignore-submodules=none`) prints nothing. `clean_tree/2` therefore returns `:ok` and the run
proceeds with a modified source (the same class of failure as the original gap, just hidden by
index flags rather than by excludes). `git ls-files -v` shows these as `h` / `S`.
**Fix:** In `probe`, also run `git ls-files -v -z` (via `run_git`) and count any record whose tag
is not `H` (lowercase = assume-unchanged, `S`/`s` = skip-worktree, `M`/`R`/`K`/`C` cases too), and
add them to the count. Add a test that sets both flags and edits the files.

### WR-02: The "user's config out of the picture" claim is only partly true (global config still read)

**File:** `lib/crosswake/proof_lane/twin_producers.ex:688-709, 759-770`
**Issue:** The comment says the user's config is out of the picture, but only
`GIT_CONFIG_NOSYSTEM` is set. `~/.gitconfig` is still read (`GIT_CONFIG_GLOBAL` and `HOME` are not
scrubbed, and `GIT_CONFIG_SYSTEM`, `GIT_CONFIG_KEY_*`/`VALUE_*`, `GIT_ATTR_SOURCE`, `GIT_EXEC_PATH`
are not either). Settings such as `core.filemode=false`, `core.trustctime`, `core.checkStat`, or a
global clean `filter.*`/`core.attributesFile` change what `status` considers modified. A
mode-only change (e.g. an executable bit on a script the run uses) is invisible on a machine whose
global config sets `core.filemode=false`. Repo-local config has the same effect and is not
overridden either (`-c` only pins excludesFile, quotePath, fsmonitor).
**Fix:** Add `{"GIT_CONFIG_GLOBAL", "/dev/null"}` (git >= 2.32) and `{"GIT_CONFIG_SYSTEM",
"/dev/null"}`, and pass `-c core.filemode=true -c core.ignoreStat=false -c core.autocrlf=false
-c core.sparseCheckout=false` on the probe. Correct the comment if any gap is accepted.

### WR-03: Operator message and count are wrong when only `.git/info/exclude` rules trigger the block

**File:** `lib/crosswake/proof_lane/twin_producers.ex:749-755`, `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex:291-299`
**Issue:** `dirty_count/2` adds active exclude rules to the path count, but the text printed is
"The candidate has N uncommitted or untracked files ... Run git status in the candidate to see
them." For a tree whose only offence is one exclude rule, `git status` shows nothing and the
message claims a file. The advice cannot lead the operator to the cause. A race (tree cleaned
between the gate and the count) can also print "has 0 uncommitted ... files" with cause
`source_dirty`.
**Fix:** Return `{paths, rules}` and word the message accordingly ("N changed paths and M local
exclude rules; edit or empty .git/info/exclude"). When the recount is 0, fall back to the
count-less text.

### WR-04: Test vacuity in the journey gate and the CLI dirty path

**File:** `test/crosswake/proof_lane/twin_journey_test.exs:157-161`, `test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs:483-597`
**Issue:** (a) The journey test only greps the source for the string
`TwinProducers.checked_identities(`; it passes if the call were dead code or the `{:blocked, _}`
branch of the new `with` were broken. Nothing runs `assemble` with a dirty tree and asserts the
run returns `{:blocked, :source_dirty}`. (b) The CLI "leaks no path" test injects a producers fn
that returns `{:blocked, :source_dirty}` itself, so the real freeze/assemble gate is never part of
the CLI test; the privacy assertion covers only the blocked_receipt rendering, not stderr from the
real git calls (that is covered separately and only at the producers level). (c) There is no
test for assume-unchanged/skip-worktree (see WR-01), nor for a `git_cmd` failure inside
`observe_identities` (which ignores the injected `git_cmd`).
**Fix:** Add a behavioural test that drives `TwinJourney` assembly (or `checked_identities`
through the journey seam) with a dirtied candidate; keep the source grep only as a secondary
guard.

## Info

### IN-01: `observe_identities/2` ignores the injected `git_cmd`; `checked_identities/3` only passes it to the first probe

**File:** `lib/crosswake/proof_lane/twin_producers.ex:917-933, 984-994`
**Issue:** `checked_identities(frozen, live, git_cmd: ...)` takes the option but the inner
`observe_identities` re-probes with the default `System.cmd/3`, so the "unavailable git" model
cannot be exercised through the second check, and the git work is done twice per call (gate plus
the `clean_tree` inside `observe_identities`).
**Fix:** Thread opts into `observe_identities/3`, or drop the gate's own probe and let the
function return a blocked tuple when `clean` is false.

### IN-02: Dead duplicated return in the test fixture

**File:** `test/crosswake/proof_lane/twin_producers_test.exs` (`repo_fixture/1`, the two identical `{:ok, dir: dir, side: ..., media: ...}` blocks)
**Issue:** The first `{:ok, ...}` expression is evaluated and discarded; the second is the real
return. Copy/paste residue that hides intent.
**Fix:** Delete the first block.

### IN-03: `outside_candidate/2` leaves an auto-created temp run root behind on refusal; `run_root(nil)` is created before the check

**File:** `lib/crosswake/proof_lane/twin_runtime.ex:59-63, 283-298`
**Issue:** With no `--run-root`, the 0700 temp dir is created, then refused if `TMPDIR` resolves
inside the candidate, and is not removed. Harmless but leaves an empty directory in (and thus
dirties, if not ignored) the candidate. Also a failed `File.stat` of the candidate yields a
message about the candidate directory from a run-root check, which is correct but surprising.
**Fix:** Remove the freshly created root on refusal, or run the containment check before
`mkdir`.

### IN-04: Narrow rescue and documented residual

**File:** `lib/crosswake/proof_lane/twin_producers.ex:714-722`
**Issue:** `run_git` rescues only `ErlangError`. A candidate path containing a NUL byte or other
invalid argv raises `ArgumentError`, which would propagate as a crash whose message can contain
the path. The record is host-prepared, so likelihood is low. The edit-then-revert window is
acknowledged in `fidelity_limits` and is not a defect.
**Fix:** `rescue e in [ErlangError, ArgumentError] -> :unavailable` (do not log `e`).
