---
phase: 184-twin-probe-and-safe-preflight
reviewed: 2026-10-15T00:00:00Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - lib/crosswake/proof_lane/twin_producers.ex
  - lib/crosswake/proof_lane/twin_runtime.ex
  - lib/crosswake/proof_lane/twin_preflight.ex
  - lib/mix/tasks/crosswake.proof_lane.twin_preflight.ex
  - lib/mix/tasks/crosswake.proof_lane.verify_twin.ex
  - guides/see_it_run.md
  - test/crosswake/proof_lane/twin_producers_test.exs
  - test/crosswake/proof_lane/twin_runtime_check_test.exs
  - test/crosswake/proof_lane/twin_source_probe_test.exs
  - test/mix/tasks/crosswake_proof_lane_twin_preflight_test.exs
  - test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs
  - test/support/twin_git_fixtures.ex
findings:
  critical: 1
  warning: 5
  info: 2
  total: 8
status: issues_found
---

# Phase 184: Code Review Report

**Reviewed:** 2026-10-15
**Depth:** standard (commit 1f5d18ee in /private/tmp/crosswake-phase180-impl)
**Status:** issues_found

## Summary

The fresh-index design closes the stat-cache and index-flag hiding routes well. Git
output parsing fails closed throughout, and the next-action texts carry no path. Two gaps
were reproduced against real git. Candidate-controlled hooks run during the probe, and an
untracked `.gitignore` can hide untracked source. There are also a few smaller fail-open
or "never raises" gaps.

## Critical Issues

### CR-01: The probe executes candidate hooks (post-index-change) and so is not read-only

**File:** `lib/crosswake/proof_lane/twin_producers.ex:1038` (`fresh_modified` `read-tree`), pins at 758-777
**Issue:** `git read-tree HEAD` writes an index, and git then runs the candidate's
`.git/hooks/post-index-change`. This was reproduced here: with `GIT_INDEX_FILE` set to an
external file, `git --no-optional-locks read-tree HEAD` ran the hook.

The git pins do not set `core.hooksPath`. `.git/hooks` and a local `core.hooksPath` are
therefore both honoured. The result is candidate-controlled code execution in the preflight
and in the real run's source gate.

This breaks the "truly read-only" claim (focus 3). A hook can also rewrite the working tree
or the real index mid-probe, so the probe reports clean on a tree that is no longer the
tree that was inspected.

**Fix:** Add `"-c", "core.hooksPath=/dev/null"` to `@git_pins`. Refuse the candidate if a
local `core.hooksPath` is set, or if any `.git/hooks/post-index-change` exists. Add a test
that plants a hook and asserts both that it does not run and that the probe result is
unchanged.

## Warnings

### WR-01: An untracked `.gitignore` containing `*` hides untracked files, and the probe returns clean

**File:** `lib/crosswake/proof_lane/twin_producers.ex:1040-1050`
**Issue:** An untracked `.gitignore` containing `*` ignores itself and every other
untracked file. This was reproduced here: `git status --porcelain=v1 -z
--untracked-files=all` printed nothing with an untracked `evil.ex` present.

`.git/info/exclude` is counted, but untracked `.gitignore` files are not. The guide's
"known limit" wording covers ignore rules in a committed `.gitignore`. It does not cover
an uncommitted one, which can hide untracked source from the backend build (the build
compiles untracked files) while the probe returns `{:ok, 0,0,0}`.

**Fix:** Run `git ls-files --others --ignored --exclude-standard -z`, or `status
--ignored=matching`, and count any ignored path that is outside the HEAD-tracked ignore
rules. At minimum, run `ls-files --others -i --exclude-standard` and flag any `.gitignore`
or `.ignore` file that is not in HEAD. Update the guide sentence.

### WR-02: A raise path in the preflight and source gate (`lock_digests`) breaks the "never raises, exit 0/2" contract

**File:** `lib/crosswake/proof_lane/twin_producers.ex:1297-1306`
**Issue:** The code runs `{:ok, digest} = file_digest(...)` after a successful `File.stat`.
A lock path that is a directory, or an unreadable file, makes `file_digest` return
`{:error, _}`. The result is a `MatchError`. Nothing in `twin_preflight.ex` or the mix
task rescues it. The task claims it "never exits with status 1 and never raises". The
preflight would exit 1 with a stack trace that includes the candidate path.

Separately, `file_digest` halts on `{:error, _}` mid-read and returns a digest of the
prefix, which is a silently wrong value (it fails closed only by chance, when the digests
then mismatch).

**Fix:** Make `lock_digests` use `with {:ok, d} <- file_digest(...)`, returning
`{:blocked, :identity_unknown}` on error. Make `file_digest` return `{:error, reason}` on a
read error. Wrap `TwinPreflight.check` in the mix task with a rescue or catch that maps to
a fixed blocked result with no message text.

### WR-03: The preflight is not strictly write-free, though the docs and the report line say it is

**File:** `lib/mix/tasks/crosswake.proof_lane.twin_preflight.ex:17-19` and `lib/crosswake/proof_lane/twin_producers.ex:1160-1195`
**Issue:** The probe creates and removes a temp directory and an index file under
`System.tmp_dir()` (`File.mkdir`, `read-tree`). It also binds and releases the origin
port. The tests snapshot only the candidate, the run root and the side dir. The
"creates nothing" and `report: none written` text overstates this.

If removal fails, the code fails closed but leaves the directory. It also falls back to
`File.rm_rf` on a directory that has already been checked.

**Fix:** Either state "creates and removes a private temporary index outside the
candidate and run root" in the docs. Or add a snapshot of `System.tmp_dir()` entries
matching `crosswake-twin-probe-*` to the preflight tests.

### WR-04: `maybe_create_root` removes a path it did not create

**File:** `lib/crosswake/proof_lane/twin_runtime.ex` (`maybe_create_root`, about line 384)
**Issue:** `with :ok <- File.mkdir(path) ... else _ -> File.rm_rf(path)` also runs when
`mkdir` returns `{:error, :eexist}`. A pre-existing path (a name collision or a
planted symlink or directory at the predictable `$TMPDIR/crosswake-twin-<12 hex>` path)
would then be recursively deleted. The 48-bit name makes this unlikely, but it is a
destructive unconditional cleanup.

**Fix:** Call `File.rm_rf` only when `mkdir` succeeded and a later step (chmod) failed. For
`:eexist`, return the failure without deleting.

### WR-05: The preflight enforces a digest comparison the real run does not, so "allowed" and "real run passes" can diverge

**File:** `lib/crosswake/proof_lane/twin_preflight.ex` (`:identity_digests`) and `TwinProducers.freeze/3`
**Issue:** The preflight blocks on a record/identity digest mismatch. `freeze` takes the
digests from the identity file and never compares them to the record. The moduledoc
admits "left to Phase 188", so the real run can start with a record whose digests the
preflight would refuse.

This is a fail-open gap in the real run, which is the authority. The preflight is
stricter than the thing it guards.

**Fix:** Do the comparison in `freeze/source_gate` (shared code) so both paths enforce it.
At minimum, record it as an explicit open item in the roadmap.

## Info

### IN-01: The "never calls the effectful path" test is a source-grep and could pass vacuously

**File:** `test/mix/tasks/crosswake_proof_lane_twin_preflight_test.exs:322-343`
**Issue:** The test reads the source with a cwd-relative path and refutes substrings. It
passes if a call is aliased, imported or moved into another module. The behavioural
`unchanged!` snapshots are the real guard, and the grep adds little. There is also no
test for hooks (CR-01) or for an untracked ignore-all `.gitignore` (WR-01).

**Fix:** Drop the grep or anchor it with `__DIR__`. Add the two missing negative tests.

### IN-02: Unscrubbed git environment variables and an unbounded orphan process on timeout

**File:** `lib/crosswake/proof_lane/twin_producers.ex:742-748, 810-823`
**Issue:** `GIT_TRACE*` (which can write a file), `GIT_DIFF_OPTS` and the `GIT_*PATHSPECS`
variables are inherited, since the scrub list is not exhaustive. On timeout,
`Task.shutdown(:brutal_kill)` kills the Elixir task but not necessarily the OS git
child. A `git_cmd` that raises something other than `ArgumentError` or `ErlangError`
crashes the linked task and takes down the caller.

**Fix:** Prefer an allowlist environment (`PATH`, `HOME` unset or empty, `LC_ALL`, plus the
fixed names). Use `Task.Supervisor.async_nolink`, and broaden the rescue to `catch _, _`.

---

_Reviewed: 2026-10-15_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
