# Phase 184: Twin probe and safe preflight - Research

**Researched:** 2026-10-15
**Domain:** Fail-closed git source probing and a read-only preflight, in Elixir (OTP 27), against the candidate checkout `/private/tmp/crosswake-phase180-impl` (HEAD `50fcd57`)
**Confidence:** HIGH for the git mechanics and the current code shapes (read in full and exercised in scratch repos this session). MEDIUM for the Linux-CI behaviour of stat-based fixtures (only macOS was exercised).

<user_constraints>
## User Constraints (from CONTEXT.md)

Copied from `184-CONTEXT.md` (content verbatim; only the section order is regrouped into the three required headings).

### Locked Decisions

**Domain / phase boundary.** This phase makes two guarantees and is limited to them:

1. **The twin refuses source that differs from HEAD.** Any candidate whose tracked files differ from HEAD in content or mode is refused, however git is set up to hide the difference.
2. **A maintainer can ask before running.** They can find out whether a twin run would be allowed without creating, consuming or leaving behind a run root.

**Requirements:** PROBE-01, PROBE-02, PROBE-03, PROBE-04.

**Where the work happens:** product code changes only in the candidate `/private/tmp/crosswake-phase180-impl`, starting from `50fcd57`.

**Not in this phase:**
- Phase 185: the absence checker, `stop_children` and `lock_digests`.
- Phase 186: the doctor and seam work.
- Phase 188: the freeze and twin-05 run. Phase 188 uses this phase's preflight.

#### Probe semantics (PROBE-01)

- **D-01: Primary signal.** Compare the worktree with a fresh index built from HEAD.
  - Set `GIT_INDEX_FILE` to a file in a private temp directory. That directory must be outside the candidate, outside its `.git`, and outside the run root.
  - Run `git read-tree HEAD`, then `git status --porcelain=v1 -z --untracked-files=all --ignore-submodules=none` against that index.
  - Delete the temp directory in an `after` block.
  - If the temp directory cannot be created or removed, the result is `prerequisite_missing`, never clean.
  - A fresh index has no stat cache. This defeats assume-unchanged, skip-worktree, `core.ignoreStat`, `core.checkStat=minimal` and `core.trustctime=false` all at once.
- **D-02: Flagged signal (second signal).** Run `git ls-files -v -z` on the **real** index.
  - Every entry whose tag is not `H` counts as flagged. This includes `h`, `S`, `s` and `M` (unmerged). It settles a conflict between researchers in favour of PROBE-01's rule; the reviewer showed unmerged stages can survive in the index.
  - Count unique paths. An unmerged path appears once per stage, so remove duplicates.
  - A tag outside git's documented alphabet `[HhSsMmRrCcKk?]` fails closed as `prerequisite_missing`.
  - Zero tracked entries fails closed. So does a failed `read-tree HEAD`, as in an empty repo.
  - In the fresh index, every entry must be `H`; anything else fails closed.
- **D-03: Exclude-rule signal.** Keep the existing count of active rules in `.git/info/exclude`.
  - The reviewer confirmed the fresh-index status shows nothing for an exclude rule. This count is the only thing that catches it.
- **D-04: Configuration that can hide changes is refused.** When any of these is found, the result is `source_dirty` with `measure: nil` and its own next action. Pins cannot neutralize them:
  - `realpath(git rev-parse --show-toplevel)` is not equal to `realpath(candidate)`. A `core.worktree` redirect makes status completely clean and `-c core.worktree=` cannot undo it. A subdirectory candidate is also refused, which is correct.
  - Any key starting with `filter.` (case-insensitive) in `git config --list --local --includes --name-only`.
    - `--includes` is required; without it, filters in `include.path` files are missed.
    - Refuse the whole prefix rather than listing clean/smudge/process.
  - A non-empty `.git/info/attributes`. Together with a config filter, it fools even the fresh index, and `--attr-source` does not help.
  - `extensions.worktreeConfig`, `core.bare=true` or `core.symlinks=false` in local config.
  - Accepted side effect: repos that use LFS or eol filters fail closed. This is noted, not fixed.

#### One git configuration (PROBE-02)

- **D-05: One shared builder.** A single private function in `TwinProducers` builds the argv and env for **every** twin git call, so nothing has a second path (183 IN-01). It covers `freeze/3`, `checked_identities/3`, `observe_identities/2`, the probe, `dirty_count(s)` and the toplevel and config reads.
  - **Top-level argv, before the subcommand:**
    - `--no-optional-locks` (top-level only; `status --no-optional-locks` is an error)
    - `--no-replace-objects`
    - `--attr-source=4b825dc642cb6eb9a060e54bf8d69288fbee4904` (the empty tree). This neutralizes in-tree `.gitattributes` filters.
    - `-c core.fsmonitor=false`. Verified: a repo-local fsmonitor script really runs during status without this pin.
    - `-c core.filemode=true`. The fresh index alone does not catch `filemode=false`.
    - `-c core.excludesFile=/dev/null`
    - `-c core.quotePath=false`
    - `-c core.ignoreStat=false`
    - `-c status.showUntrackedFiles=all`
    - `-c core.autocrlf=false`
    - `-C <candidate>`
  - **Env:**
    - The existing scrub list, plus `GIT_ATTR_SOURCE`, `GIT_EXTERNAL_DIFF` and `GIT_EXEC_PATH` set to nil.
    - `GIT_CONFIG_COUNT` set to nil, which disables `GIT_CONFIG_KEY_*`. There is no glob unset.
    - `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`, `GIT_NO_REPLACE_OBJECTS=1`, `GIT_ATTR_NOSYSTEM=1`.
    - Keep `GIT_OPTIONAL_LOCKS=0`, `GIT_TERMINAL_PROMPT=0` and `LC_ALL=C`.
    - Only `GIT_INDEX_FILE` is set per call, and only for the fresh-index pair.
  - **Cut after the adversarial pass** as unnecessary: `core.hooksPath`, `core.splitIndex`, `core.sparseCheckout`, `core.untrackedCache`, `core.checkStat`, `core.trustctime`, `HOME`, `XDG_CONFIG_HOME` and `GIT_CONFIG_SYSTEM`. These were verified harmless but redundant.
  - Keep stderr discarded at the fd level, and keep the candidate path an argv element only.
- **D-06: Git version floor.** Require at least 2.41, the newest version tested here.
  - Check it with one major.minor compare of `git --version`. Anything unparseable or lower is `prerequisite_missing`.
  - Never retry without a flag; a retry is a silent downgrade.
  - A rejected argv (rc 128/129) maps to the same cause.
- **D-07: Path-free failures (183 IN-04).** Any non-zero exit, spawn failure, timeout, truncated or unparseable `-z` output, or rejected argv yields `prerequisite_missing`, the existing "unavailable" cause.
  - The message must not contain the candidate path, `$HOME` or a username.
  - No new cause atoms. The receipt schema version is unchanged; `:source_dirty` and `:prerequisite_missing` are already in `@causes`.
- **D-08: A reason channel.** `clean_tree` currently returns only an atom. Return a reason alongside the cause so the task can write a distinct line 4 for modified, flagged, exclude-rule, hiding-config and unknown cases.
  - Example shape: probe returns `%{modified: m, flagged: f, excludes: x}`, or `{:refused, :hiding_config}`, or `:unavailable`.
  - Add `dirty_counts/2` that returns the map or nil.
  - `dirty_count/2` stays as a function returning the sum or nil.

#### Dirty message and counts (PROBE-03, 183 WR-03/WR-04)

- **D-09: Line 2 stays the stable token.** The `first cause:` line stays `source_dirty`, and all prose goes on line 4. The four-line contract is unchanged: one line, no newlines.
- **D-10: Line 4 clauses.** Each non-zero count gets its own clause, joined with "; and" in the order M, F, X. A zero count drops its clause. Singular and plural forms are both handled.
  - **M:** "N changed or untracked files"
  - **F:** "N tracked files marked unchanged in git's index (assume-unchanged or skip-worktree flags), so edits to them would go unseen". This clause names the exact commands: `git update-index --no-assume-unchanged` / `--no-skip-worktree`, and `git ls-files -v` (look for entries not marked H).
  - **X:** "N local ignore rules in .git/info/exclude". Never the word "files".
  - **Hiding config:** "the candidate's git configuration can hide changes (a worktree redirect, a filter, or .git/info/attributes); remove it".
  - **Unknown:** "changes git could not count". This text contains no digit.
  - **Shared tail:** "…, then write a new prepared record and run into a new run root."
  - **Overlap:** a path can be both modified and flagged. Clauses count findings, not distinct files, and the documentation says so.
- **D-11: Receipt `measure`.** `measure` is `M+F+X` as an integer of findings, or nil.
  - Bound the sum, not each part, by the existing 1_000_000 (`@max_measure`). Above the bound, `measure` is nil and the message uses the unknown text.
  - nil means unknown, never clean, and the `dirty_count` doc says so.
  - The breakdown appears only in line 4. The schema is unchanged.

#### Preflight entry point (PROBE-04)

- **D-12: A separate task and module.**
  - Command: `mix crosswake.proof_lane.twin_preflight ios --candidate <record> --run-root <dir> --identity <IDENTITY.json>`.
  - Module: `Crosswake.ProofLane.TwinPreflight` with `check/1`.
  - Use this, not a `--preflight` flag on `verify_twin`. Being read-only is structural: the task never calls `TwinRuntime.prepare/1`'s effectful tail, `blocked_receipt`, `write_and_verify` or `write_expectations`.
  - Use strict `OptionParser`; the only positional is `ios`.
  - Provide an `execute/2` seam returning `{status, four_lines}`. `System.halt` is called only in `run/1`.
- **D-13: `--run-root` is required.** A missing root is blocked with `prerequisite_missing` and next action "Name the private run root you plan to use".
  - Preflight never calls the branch that creates a root.
  - This was a conflict between researchers. It was resolved because the 188 go/no-go depends on the root checks.
- **D-14: Output and exit codes.**
  - Four lines:
    - `result: allowed|blocked`
    - `first cause: none|<atom>`
    - `report: none written; no run root was created or consumed`
    - `next action: <plain text>`
  - When the result is `allowed`, line 4 says: "Source and run root pass and the origin port is free at this moment; the backend build and the live journey are checked only by the real run."
  - Exit 0 means allowed. Exit 2 means blocked, for every cause, including bad options and an unreadable identity.
  - Never exit 1, which means an observed failure, and never `Mix.raise`.
  - No `--format json`.
  - Docs call it "preflight", never "go/no-go".

#### Preflight depth: one shared set of checks (PROBE-04)

- **D-15: Split `TwinRuntime.prepare/1`.**
  - A pure `check/1`, in the existing order:
    1. run root: exists, is a directory not a symlink, mode 0700, **owned by the current user** (new)
    2. `not_reused`
    3. candidate record
    4. outside candidate
    5. database path
    6. origin parse
    7. origin port bindable
  - An effectful `commit/1`: create the root when nil (the run only), acquire and hold the listener, start the Agent.
  - `prepare/1 = check |> commit`.
  - The owner check is a new behaviour in the real run and gets its own test.
- **D-16: Split `TwinProducers.freeze/3`.**
  - `source_gate/3`: `read_identity`, HEAD/tree `same`, `clean_tree`, `lock_digests`, file digests.
  - The tail: `backend_digest` compile, then `write_expectations`.
  - `freeze/3` calls `source_gate/3` as its single entry, in the same order. Preflight runs `check/1` and `source_gate/3` only.
- **D-17: Origin port.** Do a bind-and-release probe, with the release in `after`.
  - The output says "free at this moment".
  - Keep it, because an occupied port is the most likely way twin-05 gets blocked.
  - A probe error is blocked, never allowed.
- **D-18: Identity check.** Compare the identity file's manifest, activation and media digests with the candidate record's `resource_digests`/`fixture_digests`.
  - If the planner finds the shapes cannot be compared, the output must say this check was not made. It must never be silently skipped.
- **D-19: Out of preflight.** These are excluded and named as unchecked in line 4 (see D-14):
  - the backend compile, which writes `_build`;
  - any write, including receipt, `twin-result.json` and `expectations.json`.
- **D-20: Preflight is never a token.**
  - The real run re-runs every check, and nothing records "preflight passed".
  - An empty check list returns an error, never ok.

#### Tests (PROBE-03, acceptance boundaries)

- **D-21: Real temporary git repos.**
  - **Fixtures:** one per mechanism. Each asserts a `source_dirty` block, and an untouched control passes.
    - assume-unchanged, skip-worktree, `core.ignoreStat`
    - `checkStat=minimal` and `trustctime=false`. These must be **same-size, same-mtime edits** to be load-bearing; ordinary status caught naive edits.
    - `filemode=false`, set locally and globally. The global case writes a config file and points `GIT_CONFIG_GLOBAL` at it in the test, asserting that unpinned git is fooled and the pinned run is not.
    - untracked file, exclude rule
    - `core.worktree` redirect, config filter with `info/attributes`, tracked `.gitattributes` filter
    - `submodule.<n>.ignore=all` (only if cheap), unmerged entry
    - zero tracked entries, unknown tag (through an injected `git_cmd`), git failure and truncated output, temp-dir failure
  - **Builder test:** fails if any twin git call site bypasses the shared builder.
  - **Exact strings:** exact-string assertions for each line-4 case (only M, only F, only X, mixed, hiding config, unknown), plus a no-digit check on the unknown text and a "no 'files' in the X clause" check.
  - **Privacy:** a scan proving no output contains the candidate path or `$HOME`.
  - **Four lines:** an exact four-line assertion for both tasks.
  - **Preflight leaves nothing behind:** directory listings before and after of the given root, the candidate and the candidate's `.git`, for each of these cases:
    - allowed
    - dirty
    - reused root
    - missing root
    - bad record
  - **Same causes:** a table test asserting `prepare/1` and `check/1` give the same first cause on the same inputs.
  - Existing `verify_twin` tests still pass.
- **D-22: Mutation controls.** For each guard, a recorded mutation control: revert it and name the test that fails. Guards: fresh index, filemode pin, flagged count, exclude count, toplevel check, filter refusal, attr-source, builder use.
  - A cited test that runs 0 tests counts as a failure.

### Claude's Discretion

These are left to the planner and executor:
- module and function names beyond the ones fixed above;
- the exact Elixir shape of the reason channel;
- how the git-version compare is written;
- test file layout;
- whether `submodule.*.ignore` gets a fixture or only the argv pin.

### Deferred Ideas (OUT OF SCOPE)

- **Ignored untracked files** (through a tracked `.gitignore`) are not detected. This is a disclosed fidelity limit, already listed for TWIN-08 and stated as a non-goal.
- **Edit-and-revert during a run** is not detected (resolved decision C16, fidelity limit 5).
- **LFS and eol-filter repos** fail closed under the attr-source and filter refusals. Reopen if a real candidate needs filters.
- **A git floor below 2.41** is unverified. Reopen if a maintainer's git is older.
- **`lock_digests` accepting one lockfile** is Phase 185 (GUARD-03).
- **A `--format json` output for preflight.** Reopen if a consumer needs more than line 1 and the exit code.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROBE-01 | Clean-tree check blocks `source_dirty` whenever a tracked file differs from HEAD in content or mode, even when hidden by assume-unchanged, skip-worktree, `core.ignoreStat`, `core.checkStat=minimal`, `core.trustctime=false`, `core.filemode=false` (repo or global) | Fresh-index + `ls-files -v` method verified on git 2.41.0 and Apple git 2.50.1 (section "Git mechanics, verified"); working prototype probe run against 14 scratch fixtures; deterministic same-size same-mtime fixture recipe verified in Elixir |
| PROBE-02 | One shared git configuration for `freeze`, `checked_identities`, `observe_identities`; path-free `unavailable` cause on any git failure | Exact current call sites with line numbers; builder design; behavioural builder test via recording `git_cmd`; the user-level attributes-file gap (L1) and the NUL-in-argv finding (L10) |
| PROBE-03 | Real-repo fixture per mechanism + untracked + exclude; exact separate flagged/modified counts; recorded mutation controls | Fixture recipes with preconditions; discriminating fixtures for each guard (L5); ledger-safe test layout; mutation harness pattern from 183 with the 0-test check |
| PROBE-04 | Read-only preflight: allowed/blocked with cause, no `receipt.json`, no run root created/consumed, refused root leaves nothing | `check/1` + `commit/1` split design, `source_gate/3` split, bind-and-release, TMPDIR sandbox for listing tests, D-18 shapes proven comparable |
</phase_requirements>

## Summary

The 183 probe (`status` on the real index plus an `info/exclude` rule count) trusts git's stat cache. This phase replaces the primary signal with a status run against a throwaway index rebuilt from HEAD, adds a second signal (non-`H` tags from `git ls-files -v`), refuses configurations that hide changes outright, and puts every twin git call behind one builder. I built and ran a ~100-line prototype of the whole probe against 14 scratch repos (git 2.41.0; key cases repeated on Apple git 2.50.1); every hiding mechanism in PROBE-01 produced a block, clean clones passed, and a clone of the real candidate (3257 tracked files) probed clean in about 0.16 s. The probe is strictly read-only on the candidate, including `.git` (before/after `stat` listing identical).

Four things in CONTEXT.md do not work as written and need a planner decision before tasks are cut (details in "Landmines"): **(L1)** a user-level attributes file (`~/.config/git/attributes`) fools the D-05-pinned fresh-index probe, because neither `--attr-source` nor `GIT_CONFIG_GLOBAL=/dev/null` touches it; one extra pin, `-c core.attributesFile=/dev/null`, fixes it (verified). **(L2)** `config --list --name-only` cannot show values, so `core.symlinks=false`, `core.bare=true` and `extensions.worktreeConfig` cannot be evaluated from it; use `--list -z` instead (verified). **(L3)** comparing `realpath` strings breaks on macOS (`System.tmp_dir!()` is `/var/folders/...`, git reports `/private/var/...`); Elixir has no `realpath`, so compare device+inode like `outside_candidate/2` already does. **(L5)** the D-21 "tracked `.gitattributes` filter" fixture cannot show `--attr-source` is load-bearing, because the filter refusal fires first; use a tracked `text eol=lf` (or `ident`) attribute with a CRLF edit, which needs no filter config (verified).

Phase-185/186 work lands on the same candidate afterwards, so this phase's product change should be one candidate commit on top of `50fcd57` (the 183 pattern), with mutation controls run in a throwaway copy and logged outside the candidate.

**Primary recommendation:** Implement in this order: (1) the builder + new probe + reason channel + message composer in `twin_producers.ex`, with new tests in a NEW test file; (2) `TwinRuntime.check/1`/`commit/1`; (3) `source_gate/3` and `TwinPreflight` + task; (4) `verify_twin` integration and guide text; (5) gates, mutation controls, single commit. Add `-c core.attributesFile=/dev/null` to the D-05 pins.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Git argv/env construction, probe, counts | Library (`TwinProducers`) | — | D-05 fixes one private builder there; only module that spawns git |
| Run-root / candidate-record / port checks | Library (`TwinRuntime.check/1`) | — | Pure validation; shared by the real run and the preflight |
| Run-root creation, listener hold, registry Agent | Library (`TwinRuntime.commit/1`) | — | The only effectful tail; never reached by preflight |
| Preflight orchestration + four-line output | Mix task (`twin_preflight`) | Library (`TwinPreflight.check/1`) | Read-only structurally: calls only `check/1`, `source_gate/3`, comparisons |
| Receipt measure / cause atoms | Library (`TwinReceipt`) | — | Unchanged; `measure` is M+F+X |
| Blocked-receipt prose | Mix task (`verify_twin`) | Library (message composer) | One composer feeds both tasks so wording cannot drift |
| User-facing documentation | Guide (`guides/see_it_run.md`) | — | One subsection + one sentence |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir stdlib (`System.cmd/3`, `File`, `OptionParser`, `:gen_tcp`) | Elixir 1.19.5 / OTP 27 [VERIFIED: `elixir --version` this session] | All code in this phase | CONTEXT: no new dependencies |
| git | 2.41.0 (`/opt/homebrew/bin/git`) and 2.50.1 Apple Git-155 (`/usr/bin/git`) [VERIFIED: `git --version`, `/usr/bin/git --version`] | The probe subject | D-06 floor 2.41 |
| ExUnit | bundled | Tests (existing twin suites are `async: false`) | Existing |
| Jason | already a dependency | Record/identity JSON (already used by `read_identity`, `candidate_record`) | Existing |

### Supporting
None. No package is added.

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Fresh index via `GIT_INDEX_FILE` + `read-tree` | `git diff --no-index` or `git diff-files` with `--ignore-stat` | Not verified; `read-tree` + `status` is the locked, verified method |
| `id -u` for the owner check | A uid from `File.stat` of a directory the code just created | Equivalent; `id -u` is simpler and has a test seam (see below) |

**Installation:** none.

**Version verification:** no package versions to verify; tool versions are in the table above.

## Package Legitimacy Audit

No external package is installed or recommended in this phase. `gsd-tools query package-legitimacy check` was not needed.

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
 mix crosswake.proof_lane.twin_preflight ios --candidate R --run-root D --identity I
        |  (strict OptionParser; any bad option => blocked, exit 2, never Mix.raise)
        v
 TwinPreflight.check/1 ------------------------------------------------------------+
   1. TwinRuntime.check/1   (pure; NO mkdir, NO Agent, NO listener kept)             |
        run root: lstat dir, not symlink, mode 0700, owner == current uid (new)      |
        -> not_reused (no receipt.json)                                              |
        -> candidate record (0600 JSON) -> outside candidate (dev/inode walk)        |
        -> database path -> origin parse -> origin port: bind then close (after)     |
   2. TwinProducers.source_gate/3   (reads only)                                     |
        read_identity -> rev-parse HEAD / HEAD^{tree} == record -> clean_tree        |
        -> lock_digests -> file_digest(study js)                                     |
          clean_tree = probe (all calls via ONE builder):                            |
            git --version >= 2.41                                                    |
            config --list --local --includes -z   -> refuse filter.*, bare, symlinks |
            info/attributes active line?          -> refuse                          |
            rev-parse --show-toplevel  ~ candidate (dev/inode)  -> else refuse       |
            ls-files -v -z (REAL index)  -> flagged F = unique non-H paths           |
            mkdir private tmp (outside candidate/.git/run root)                      |
              GIT_INDEX_FILE=tmp/index: read-tree HEAD; ls-files -v (all H?);        |
              status --porcelain=v1 -z --untracked-files=all --ignore-submodules=none|
              -> modified M ;  rm tmp                                                |
            info/exclude active rules -> X                                           |
   3. compare identity manifest/activation/study_js/media with record digests (D-18) |
        v                                                                            |
 four lines + exit 0 (allowed) / 2 (blocked)  <--------------------------------------+
 (nothing written anywhere except a transient private temp dir that is removed)

 Real run:  VerifyTwin.execute -> TwinRuntime.prepare = check |> commit
            (commit: mkdir root if nil, hold listener, start Agent) -> freeze = source_gate + tail
```

### Recommended Project Structure
```
lib/crosswake/proof_lane/
├── twin_producers.ex      # builder, probe_source/2, clean_tree/2, dirty_counts/2, source_gate/3, freeze/3
├── twin_runtime.ex        # check/1, commit/1, prepare/1
├── twin_preflight.ex      # NEW: check/1 (read-only orchestration + D-18 comparison)
lib/mix/tasks/
├── crosswake.proof_lane.twin_preflight.ex   # NEW: run/1 + execute/2
├── crosswake.proof_lane.verify_twin.ex      # blocked_receipt uses dirty detail + shared message composer
test/crosswake/proof_lane/
├── twin_source_probe_test.exs        # NEW (fixtures, builder, strings, privacy, mutation targets)
├── twin_runtime_check_test.exs       # NEW (check/commit split, owner seam, same-causes table, no-leftovers)
test/mix/tasks/
├── crosswake_proof_lane_twin_preflight_test.exs   # NEW
test/support/
├── twin_git_fixtures.ex   # OPTIONAL shared repo builder (test/support compiles in :test; outside the vacuity-ledger scope)
```

### Pattern 1: One builder, every call
**What:** A single private function turns `(path, subcommand_args, per_call_env)` into the full `sh -c 'exec "$@" 2>/dev/null' sh git <pins> -C <path> <args>` invocation. `run_git/2` (today the only spawn site, `twin_producers.ex:716-723`) becomes its only caller.
**When to use:** Every git read in the twin: `rev-parse` (HEAD, tree, toplevel, git-path), `config`, `ls-files`, `read-tree`, `status`, and `--version`.
**Example (prototype, run this session against 14 fixtures):**
```elixir
# Source: scratchpad prototype proto.exs, verified against git 2.41.0 on macOS
@empty_tree "4b825dc642cb6eb9a060e54bf8d69288fbee4904"
@scrub ~w(GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES
          GIT_COMMON_DIR GIT_NAMESPACE GIT_CEILING_DIRECTORIES GIT_CONFIG GIT_CONFIG_COUNT
          GIT_CONFIG_PARAMETERS GIT_PREFIX GIT_ATTR_SOURCE GIT_EXTERNAL_DIFF GIT_EXEC_PATH)
@fixed_env %{"GIT_CONFIG_GLOBAL" => "/dev/null", "GIT_CONFIG_NOSYSTEM" => "1",
             "GIT_NO_REPLACE_OBJECTS" => "1", "GIT_ATTR_NOSYSTEM" => "1",
             "GIT_OPTIONAL_LOCKS" => "0", "GIT_TERMINAL_PROMPT" => "0", "LC_ALL" => "C"}
@pins ["--no-optional-locks", "--no-replace-objects", "--attr-source=" <> @empty_tree,
       "-c", "core.fsmonitor=false", "-c", "core.filemode=true", "-c", "core.excludesFile=/dev/null",
       "-c", "core.attributesFile=/dev/null",            # NOT in CONTEXT D-05: see Landmine L1
       "-c", "core.quotePath=false", "-c", "core.ignoreStat=false",
       "-c", "status.showUntrackedFiles=all", "-c", "core.autocrlf=false"]

defp git_invocation(path, args, per_call_env) do
  env = Map.new(@scrub, &{&1, nil}) |> Map.merge(@fixed_env) |> Map.merge(Map.new(per_call_env))
  {"sh", ["-c", "exec \"$@\" 2>/dev/null", "sh", "git" | @pins ++ ["-C", path | args]],
   [env: Map.to_list(env), stderr_to_stdout: false]}
end
```
Build the env through a `Map` (as above), not by appending `{"GIT_INDEX_FILE", idx}` after a `{"GIT_INDEX_FILE", nil}` entry: the append worked in the prototype but leaves duplicate keys whose precedence is an implementation detail.

### Pattern 2: Probe result as data, `clean_tree` as a thin view
**What:** One internal function returns the reason; the existing public functions are views of it, so the 15+ existing assertions (`clean_tree == :ok | {:blocked, :source_dirty}`, `freeze == {:blocked, :source_dirty}`) stay valid.
```elixir
@type probe :: {:ok, %{modified: n, flagged: n, excludes: n}} | {:refused, :hiding_config} | :unavailable

def probe_source(path, opts \\ [])   # public (documented); returns @type probe
def clean_tree(path, opts \\ []) do
  case probe_source(path, opts) do
    {:ok, %{modified: 0, flagged: 0, excludes: 0}} -> :ok
    {:ok, _} -> {:blocked, :source_dirty}
    {:refused, _} -> {:blocked, :source_dirty}
    :unavailable -> {:blocked, :prerequisite_missing}
  end
end
def dirty_counts(path, opts \\ []) # -> %{modified:, flagged:, excludes:} | nil   (nil for refused/unavailable/out of bound)
def dirty_count(path, opts \\ [])  # -> sum | nil  (nil = unknown, never clean)
```
Callers that need the prose (`verify_twin.blocked_receipt`, `TwinPreflight`) re-probe once after a `{:blocked, :source_dirty}`, exactly as `blocked_receipt` already does today with `dirty_count` (`verify_twin.ex:148`). If the re-probe disagrees with the first (a race), the "changes git could not count" text is used.

### Pattern 3: Probe skeleton with guaranteed temp-dir cleanup (D-01)
```elixir
# private temp dir: absolute path, mode 0700, created with File.mkdir (fails if it exists), outside candidate
defp with_private_index(path, fun) do
  dir = Path.join(System.tmp_dir!(), "crosswake-twin-probe-" <> Base.encode16(:crypto.strong_rand_bytes(8), case: :lower))
  with :ok <- File.mkdir(dir), :ok <- File.chmod(dir, 0o700),
       false <- TwinRuntime.inside?(dir, identity_of(path)) do        # reuse the dev/inode ancestor walk
    result =
      try do
        fun.(Path.join(dir, "index"))                                  # MUST be absolute: see L9
      catch
        kind, reason -> File.rm_rf(dir); :erlang.raise(kind, reason, __STACKTRACE__)
      end
    case File.rm_rf(dir) do                                            # removal failure => unavailable, never clean
      {:ok, _} -> if File.exists?(dir), do: :unavailable, else: result
      _ -> :unavailable
    end
  else
    _ -> :unavailable
  end
end
```
(`try ... after` alone cannot turn a failed removal into `prerequisite_missing`, so removal is checked after the `try`. `inside?/2` is currently private in `twin_runtime.ex:357`; make it `@doc false def` or duplicate the 8-line walk.)

### Pattern 4: `-z` parsing that fails closed
```elixir
# ls-files -v -z => "H path\0H path2\0". Truncated output (no trailing NUL) and unknown tags => :unavailable.
defp parse_ls_files(""), do: :unavailable                    # zero tracked entries (D-02)
defp parse_ls_files(out) do
  if String.ends_with?(out, <<0>>) do
    entries = String.split(out, <<0>>, trim: true)
    parsed = for <<tag, ?\s, path::binary>> <- entries, tag in ~c"HhSsMmRrCcKk?", do: {tag, path}
    if length(parsed) == length(entries), do: {:ok, parsed}, else: :unavailable
  else
    :unavailable
  end
end
# flagged F = parsed |> reject(tag == ?H) |> map(path) |> uniq |> length   (unmerged: 'M' once per stage)
# status -z must also end with NUL when non-empty; empty output is the clean case.
```

### Pattern 5: Config refusals from `--list -z` (values, not just names)
```elixir
# "key\nvalue\0"; a valueless boolean is "key\0" (value nil == true). Git lowercases section/variable
# names but keeps subsection case ("filter.Foo.clean").
pairs = for e <- String.split(out, <<0>>, trim: true), do: (case String.split(e, "\n", parts: 2) do
  [k, v] -> {String.downcase(k), v}; [k] -> {String.downcase(k), nil} end)
refuse? = Enum.any?(pairs, fn {k, v} ->
  String.starts_with?(k, "filter.") or (k == "core.bare" and truthy?(v)) or
  (k == "core.symlinks" and falsy?(v)) or (k == "extensions.worktreeconfig" and truthy?(v)) end)
```
Order in the probe: version check -> **config list** -> attributes file -> toplevel -> real `ls-files` -> fresh-index trio -> exclude count. The config read must precede the toplevel read because `core.bare=true` makes `rev-parse --show-toplevel` fail (rc 128), which would otherwise surface as `prerequisite_missing` instead of the intended `hiding_config`.

### Pattern 6: Toplevel comparison without `realpath`
```elixir
defp same_dir?(a, b) do
  with {:ok, sa} <- File.stat(a), {:ok, sb} <- File.stat(b),
       do: {sa.major_device, sa.inode} == {sb.major_device, sb.inode}, else: (_ -> false)
end
# toplevel = String.trim_trailing(out, "\n"); same_dir?(toplevel, candidate) or {:refused, :hiding_config}
```
This is the same device+inode technique `TwinRuntime.outside_candidate/2` already uses (`twin_runtime.ex:335-366`), and it is what makes `/tmp` vs `/private/tmp` and `/var/folders` vs `/private/var/folders` irrelevant. [VERIFIED: `File.stat("/tmp")` and `File.stat("/private/tmp")` have identical `{major_device, inode}`]

### Pattern 7: Bind-and-release (D-17)
```elixir
defp origin_bindable(port) do
  case :gen_tcp.listen(port, [:binary, ip: {127, 0, 0, 1}, reuseaddr: false, active: false, packet: :raw]) do
    {:ok, l} -> :gen_tcp.close(l); :ok
    {:error, :eaddrinuse} -> {:error, failure(:origin_port_occupied, "...")}   # same text as acquire_origin today
    {:error, _} -> {:error, failure(:prerequisite_missing, "Make 127.0.0.1:#{port} bindable and run again")}
  end
end
```
Verified in OTP 27: a second `listen` while one is held returns `{:error, :eaddrinuse}`, and re-binding right after `close` succeeds. The existing runtime uses exactly these listen options (`acquire_origin/1`, `twin_runtime.ex:471-492`). `commit/1` must keep mapping `:eaddrinuse` to the same cause: the port can be taken between `check` and `commit` in the real run.

### Anti-Patterns to Avoid
- **String-comparing `show-toplevel` to the candidate path.** Breaks every existing macOS test (L3).
- **A relative `GIT_INDEX_FILE`.** With `-C <candidate>` it resolves inside the candidate and writes `rel-index` into the working tree (verified, L9).
- **Reading config names only.** `--name-only` cannot see `core.symlinks=false` (L2).
- **Putting the D-18 digest comparison inside `source_gate/3`.** Existing `freeze` tests build a runtime whose `resource_digests` is `nil`; keep the comparison in `TwinPreflight` (L16).
- **Creating anything under the run root, the candidate or `.git` from preflight.** The only filesystem write is the private temp dir, which is outside all three and removed.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| "Is the tree clean?" | Own diff/hash walk of the worktree | git against a fresh index (`read-tree` + `status`) | Respects git's own content/mode/untracked semantics; verified against every mechanism |
| Path equality across symlinks | A `realpath` clone | device+inode via `File.stat` | Already the repo's technique; handles `/tmp` and `/var` aliases |
| Option parsing | Manual argv matching | `OptionParser.parse(args, strict: [...])` | Existing task pattern; returns `invalid` for the exit-2 mapping |
| Free-port check | Scanning `lsof`/`netstat` | `:gen_tcp.listen/2` then `close` | Same primitive the real run holds; no occupant is touched |
| Current uid | Parsing `/etc/passwd` | `System.cmd("id", ["-u"])` (with a test seam) | Erlang/Elixir stdlib has no `getuid`; see Open Question 3 |
| Temp dir | `System.tmp_dir!() <> "/x"` with a predictable name | `File.mkdir` of a random name (fails if it exists) + `chmod 0700` | Avoids pre-created symlink/dir attacks in a shared tmp |

**Key insight:** every "clean" shortcut that reuses the real index or reads the user's git environment is the exact hole being closed; the only trustworthy comparison is HEAD's tree vs the worktree under pinned config.

## Exact current shapes (item 1)

All paths are in `/private/tmp/crosswake-phase180-impl`. [VERIFIED: files read this session]

### Git call sites today
There is exactly **one** spawn point: `run_git/2` at `twin_producers.ex:716-723`:
```elixir
defp run_git(args, git_cmd) do
  git_cmd.("sh", ["-c", "exec \"$@\" 2>/dev/null", "sh", "git" | args],
    env: @git_scrub_env,
    stderr_to_stdout: false
  )
rescue
  ErlangError -> :unavailable
end
```
`@git_scrub_env` (`:690-710`) is the 12 `GIT_*` variables set to `nil` plus `{"GIT_OPTIONAL_LOCKS","0"}, {"GIT_CONFIG_NOSYSTEM","1"}, {"GIT_TERMINAL_PROMPT","0"}, {"LC_ALL","C"}`. `@max_dirty_count 1_000_000` is `:712`.

Callers of `run_git`:
| Function | Lines | Git argv (after `-C path`) | `git_cmd` injectable? |
|---|---|---|---|
| `git/3` | 725-730 | caller-supplied; `{out,0}` -> `{:ok, String.trim(out)}`, else `{:blocked, :prerequisite_missing}` | 3rd arg, default `&System.cmd/3`; **no caller passes it** |
| `freeze/3` | 632-633 | `rev-parse HEAD`, `rev-parse HEAD^{tree}` via `git/2` | no (IN-01) |
| `observe_identities/2` | 922, 923, 925, 926 | `rev-parse HEAD`, `rev-parse HEAD^{tree}` twice, via `git/2`; `clean_tree(path)` at 924 with no opts | **no** (IN-01) |
| `probe/2` | 759-783 | `status --porcelain=v1 -z --untracked-files=all --ignore-submodules=none` with its own `-C` and 3 `-c` pins | yes (`:git_cmd`) |
| `exclude_rules/2` | 794-802 | `rev-parse --git-path info/exclude` (relative to `-C`; absolute for linked worktrees) | yes |
| `checked_identities/3` | 988-994 | calls `clean_tree` with `Keyword.take(opts, [:git_cmd])`, then `observe_identities/2` (which re-probes without it) | partly |

Non-git `System.cmd` in the twin (out of scope for the builder): `twin_runtime.ex:255,267` (`kill`), `twin_journey.ex:787-788` (`xcrun simctl`), `twin_fault_boundary.ex:749` (`ps`).

Other pieces: `clean_tree/2` `:739-745`; `dirty_count/2` `:752-757` (sum, nil when out of bound or unavailable); `probe/2` returns `{:ok, records, excludes} | :unavailable`; `count_records/2` `:786-792` (rename counted once; **unreachable under a fresh index**, see L6); `read_exclude/1` `:804-810`; `active_rule?/1` `:812-815`; `lock_digests/1` `:817-825` (**Phase 185 owns changing it**; here it is only called); `file_digest/1` `:829-852`; `backend_digest/3` `:854-863` (compiles the example host: writes `_build`); `write_expectations/2` `:895-909`; `freeze/3` `:628-671`; `read_identity/1` `:673-684` (returns `%{media:, size:, manifest:, activation:}`); `same/2` `:686`.

### `freeze/3` today (`:628-671`), in order
`read_identity` -> `git rev-parse HEAD` -> `git rev-parse HEAD^{tree}` -> `same(head, runtime.candidate_head)` -> `same(tree, runtime.candidate_tree)` -> `clean_tree(path, take git_cmd)` -> `lock_digests(path)` -> `file_digest(study_js)` -> `backend_digest` -> (`TwinReceipt.freeze_expectations` with `resources = [identity.manifest, identity.activation, study_js]`, `fixture_digests: [identity.media]`) -> `write_expectations`. Failure mapping: `{:blocked, _} = blocked -> blocked`; anything else -> `{:blocked, :identity_unknown}`.

### `TwinRuntime.prepare/1` today (`twin_runtime.ex:58-86`), in order
1. `run_root(opts[:run_root])` (`:283-318`): `nil` => **creates** `System.tmp_dir!()/crosswake-twin-<12 hex>` with `File.mkdir` + `chmod 0700` (this is IN-03: a later refusal leaves it behind); a path => `Path.expand`, `File.lstat` must be `type: :directory` with `(mode &&& 0o077) == 0`, else `prerequisite_missing` / "Create a private run root directory (mode 0700) and run again with it"; any other value => "Pass a private run root directory and run again". **No owner check today.**
2. `not_reused(root)` `:320-329` (`receipt.json` lstat not `:enoent` => `run_root_reused`)
3. `candidate_record(opts[:candidate])` `:368-389` (0600 regular file, JSON, `candidate_fields/1` `:391-417`: 40-hex head/tree, `File.dir?(candidate_path)`)
4. `outside_candidate(root, record.candidate_path)` `:335-355` (dev/inode walk over root and ancestors; `inside?/2` `:357-366` private)
5. `database_path(root, opts[:database_path])` `:419-439` (default `root/twin.sqlite3`; explicit must start with `root <> "/"`, not exist, and `Path.dirname` must be a directory)
6. `origin_port(record.origin)` `:448-469`
7. `acquire_origin(port)` `:471-492` (listen `reuseaddr: false`; `:eaddrinuse` => `origin_port_occupied`, other error => `prerequisite_missing`)
8. `Agent.start` registry, `run_deadline_at`, build `%TwinRuntime{}` with a random `run_id`.

`stop_children/1` `:184-191` and `stop_all/1` `:194-200` are Phase 185's; unchanged here. `@enforce_keys [:run_id, :run_root, :database_path, :origin, :origin_port, :registry]` (`:27`) means a `%TwinRuntime{}` cannot be built without a registry; `source_gate/3` must therefore accept a plain map (see split design).

### `verify_twin` task (`lib/mix/tasks/crosswake.proof_lane.verify_twin.ex`)
- `run/1` `:31-35`: `execute(args, [])`, print lines, `System.halt(status)` only when non-zero.
- `execute/2` `:44-82`: strict `OptionParser`; `positional != ["ios"] or invalid != []` => `Mix.raise("verify_twin.invalid_options")`; no producers and no `--identity` => `Mix.raise("verify_twin.identity_required")`; passes `DATABASE_PATH` env as `database_path:`; `TwinRuntime.prepare` error => `summarize(:blocked, Atom.to_string(cause), nil, action)`; else `conduct` inside `try ... after TwinRuntime.stop_all`.
- Four lines (`summarize/4` `:301-312`), quoted:
  `"result: #{result} (exit #{code})"`, `"first cause: #{cause}"`, `"report: #{report || "none written"}"`, `"next action: #{action}"`.
- `blocked_receipt/2` `:146-193`: for `:source_dirty` calls `TwinProducers.dirty_count(runtime.candidate_path)` (`:148`), writes a receipt with every roster id except `TW-T10-02` `blocked` with `measure: count`, `cause: cause`, then `source_dirty_action(count)` for line 4.
- `source_dirty_action/1` `:291-299`, quoted: `"The candidate has #{n} uncommitted or untracked files. "` / `"The candidate has uncommitted or untracked files. "` + `"Commit or remove the uncommitted changes in the candidate, write a new prepared record, and run into a new run root. Run git status in the candidate to see them."`
- `exit_status_for/1` is `defdelegate` to `TwinReceipt`; 0 passed, 1 failed, 2 blocked/unknown.

### Receipt (`twin_receipt.ex`)
`@causes` `:23-43` (quoted): `observation_missing, contradiction_observed, identity_mismatch, identity_unknown, prerequisite_missing, origin_port_occupied, run_root_reused, run_root_rejected, database_path_rejected, child_timeout, host_denied, backend_denied, unavailable_observation, backend_listener_not_owned, capture_not_prevented, attachment_check_unavailable, session_control_unavailable, source_dirty, cause_not_retained`. `@max_measure 1_000_000` `:56`. `safe_cause/1` `:195-196` (non-member => `:cause_not_retained`). `measure_ok/1` `:703`: integer `0..@max_measure`. `@fidelity_limits` `:58-64` has 5 entries, last: `"source edit made and reverted during a run not detected"`. `:run_root_rejected` is defined but unused anywhere in lib; keep using `prerequisite_missing` for run-root faults so existing tests (which assert that atom) stay valid.

## Split designs (item 2)

### `TwinRuntime.check/1` + `commit/1` + `prepare/1`
```elixir
@spec check(keyword()) :: {:ok, checked()} | {:error, failure()}
def check(opts) do
  with {:ok, root} <- run_root_check(opts[:run_root]),        # %{path:, create?: bool}; nil => prospective path, NOTHING created
       :ok <- not_reused(root),                               # skipped when create?
       {:ok, record} <- candidate_record(opts[:candidate]),
       :ok <- outside_candidate(root.path, record.candidate_path),   # works on a not-yet-existing path: inside?/2 walks to existing ancestors
       {:ok, db} <- database_path(root, opts[:database_path]),
       {:ok, port} <- origin_port(record.origin),
       :ok <- origin_bindable(port) do
    {:ok, %{root: root, record: record, db: db, port: port, run_deadline_ms: opts[:run_deadline_ms]}}
  end
end

@spec commit(checked()) :: {:ok, t()} | {:error, failure()}
def commit(%{root: root} = checked) do
  with :ok <- maybe_create_root(root),                    # File.mkdir + chmod 0700, the ONLY place that creates
       {:ok, listener} <- acquire_origin(checked.port) do # keeps eaddrinuse mapping (race window)
    {:ok, registry} = Agent.start(fn -> %{children: %{}, first_failure: nil} end)
    {:ok, %__MODULE__{...same fields as prepare today...}}
  end
end

def prepare(opts) when is_list(opts), do: with({:ok, c} <- check(opts), do: commit(c))
```
Details the planner must carry:
- **Nil root in `check/1`:** pick the prospective path (`System.tmp_dir!()/crosswake-twin-<12 hex>`) without touching disk; skip `not_reused` and the "dirname must be a directory" test in `database_path/2` for it (the directory does not exist yet); an explicit `database_path` with a nil root is rejected (`db_failure()`), since it cannot be inside a root that does not exist. This preserves every existing error cause/text and fixes IN-03 (a refused `prepare` no longer leaves a root behind). Preflight never reaches this branch because D-13 rejects a missing root first.
- **Owner check:** add to `run_root_check` after the mode test: `lstat.uid == current_uid`. No stdlib `getuid` exists; use `System.cmd(System.find_executable("id") || "/usr/bin/id", ["-u"])` and fail closed (`prerequisite_missing`, same text as the mode failure) if it cannot be read. Add an option seam (e.g. `check(opts ++ [current_uid: 0])`) so a test can prove a root owned by "someone else" is refused; a test cannot `chown` to another user. [VERIFIED: `File.lstat!` returns `uid`; `id -u` returned 501 and matched the directory uid.]
- **`database_path/2` takes the root map** now (it needs `create?`); `outside_candidate/2` keeps taking a path.
- **Tests that call `TwinRuntime.prepare` directly** keep working unchanged (`crosswake_proof_lane_verify_twin_test.exs:155,187,193,198,212,219,242,254`; they use `System.tmp_dir!()`-based roots owned by the test user). `twin_fault_boundary.ex` only mentions `prepare/1` in a moduledoc (`:5`); `twin_journey.ex` does not call `prepare`.
- **Same-causes table test (D-21):** for each failing input (missing root, 0755 root, symlink root, reused root, bad record, loose record, root inside candidate, bad db, bad origin, occupied port) assert `check(opts)` and `prepare(opts)` return the same `{:error, %{cause: c}}`.

### `TwinProducers.source_gate/3` + `freeze/3`
```elixir
@spec source_gate(map(), Path.t(), keyword()) ::
        {:ok, %{identity: map(), head: String.t(), tree: String.t(), locks: [String.t()], study_js: String.t()}}
        | {:blocked, atom()}
def source_gate(%{candidate_path: path, candidate_head: want_head, candidate_tree: want_tree}, identity_path, opts \\ []) do
  cmd = Keyword.take(opts, [:git_cmd])
  with {:ok, identity} <- read_identity(identity_path),
       {:ok, head} <- git(path, ["rev-parse", "HEAD"], cmd),
       {:ok, tree} <- git(path, ["rev-parse", "HEAD^{tree}"], cmd),
       :ok <- same(head, want_head), :ok <- same(tree, want_tree),
       :ok <- clean_tree(path, cmd),
       {:ok, locks} <- lock_digests(path),
       {:ok, study_js} <- file_digest(Path.join(path, @study_js_rel)) do
    {:ok, %{identity: identity, head: head, tree: tree, locks: locks, study_js: study_js}}
  else
    {:blocked, _} = blocked -> blocked
    _ -> {:blocked, :identity_unknown}
  end
end
```
`freeze/3` then does `with {:ok, gate} <- source_gate(runtime, identity_path, opts), {:ok, backend} <- backend_digest(runtime, path, opts)` and the existing expectations/`write_expectations` tail, keeping the `{:blocked, :identity_unknown}` mapping. The first argument is a plain map pattern so a `%TwinRuntime{}` satisfies it **and** `TwinPreflight` can pass `%{candidate_path:, candidate_head:, candidate_tree:}` built from the checked record without starting a registry Agent. Pass `:git_cmd` to every `git/3` call (today none do).

Existing tests touching these functions (all in the candidate):
- `test/crosswake/proof_lane/twin_producers_test.exs`: `freeze` at lines 554-563, 574, 589, 607, 639, 645, 733, 784, 802, 817, 834, 848, 859, 867; `observe_identities` 568, 579, 594, 612, 837, 853, 869; `checked_identities` 844, 861; `clean_tree`/`dirty_count` at 637-752, 782-783.
- `test/crosswake/proof_lane/twin_journey_test.exs:159-160` asserts the journey source contains `TwinProducers.checked_identities(` and not `TwinProducers.observe_identities(` (a source grep; leave it).
- `test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs`: `prepare` call sites above; dirty-output tests at `:562` and `:590`.
- Journey production caller: `twin_journey.ex:711` `TwinProducers.checked_identities(ctx.frozen, live)` (arity 2; default opts keep working).

### Callers that must change
1. `observe_identities/2` -> add an `opts \\ []` third parameter, pass `:git_cmd` to all four `git/3` calls and to `clean_tree`; `checked_identities/3` passes its opts through (closes IN-01).
2. `verify_twin.ex:blocked_receipt/2` -> use the probe detail: `measure = M+F+X` (nil when refused/unavailable/over bound) and the new message composer instead of `source_dirty_action/1`; `next_action(%{overall_status: :blocked}, :source_dirty)` (`:284`) likewise.
3. `verify_twin.ex:execute/2` -> unchanged calls (`TwinRuntime.prepare`, `TwinProducers.freeze`).
4. `guides/see_it_run.md` (see Docs).

## Git mechanics, verified (item 3)

Environment: git 2.41.0 (`/opt/homebrew/bin/git`, first on PATH) and git 2.50.1 (Apple Git-155, `/usr/bin/git`). [VERIFIED: both run this session] Experiments ran in scratch repos only; both gits were used for the hiding fixtures and the full pinned probe, with identical results.

| Claim (CONTEXT ref) | Result | Evidence |
|---|---|---|
| Fresh index reports ` M` for an edit hidden by assume-unchanged / skip-worktree (D-01) | **Confirmed** | ordinary status empty; fresh ` M a.txt`; `ls-files -v` shows `h` / `S` |
| `core.ignoreStat=true` | **Confirmed, with a subtlety** | The "assume-unchanged" bit is only set when git *updates the index* while the config is set. Fixture: `git config core.ignoreStat true` **before** `git add`. Setting it after the commit hides nothing. The entry then shows tag `h`, so the flagged count also catches it |
| `core.trustctime=false` / `core.checkStat=minimal` (D-21 "same-size, same-mtime") | **Confirmed**; see fixture recipe below | in-place edit hides under `trustctime=false`; `checkStat=minimal` also ignores ctime, uid, gid, inode and nanoseconds |
| `core.filemode=false` local / global | **Confirmed**, but the global fixture needs local `core.filemode` unset (L4) | |
| Pinned `-c core.filemode=true` defeats local `false`; fresh index alone does not | **Confirmed** | fresh index unpinned empty; pinned ` M run.sh` |
| `info/exclude` rule invisible to ordinary and fresh status (D-03) | **Confirmed** | both empty with `secret.txt` excluded; the X count is the only signal |
| `core.worktree` redirect makes status clean; `-c core.worktree=` cannot undo (D-04) | **Confirmed** | `show-toplevel` printed the redirect target even with `-c core.worktree=`; fresh status empty |
| `--includes` needed for filters in `include.path` files (D-04) | **Confirmed** | `filter.y.clean` visible only with `--includes` |
| Config filter + `.git/info/attributes` fools the fresh index even with `--attr-source` (D-04) | **Confirmed** | fresh+attr-source output empty |
| `--attr-source=<empty tree>` defeats tracked `.gitattributes` (D-05) | **Confirmed** for filters and for `text eol=lf` / `ident` with no filter | see L5 |
| `--attr-source` / `GIT_ATTR_SOURCE` availability | Accepted by 2.41.0 and 2.50.1 [VERIFIED]. First release with the option: 2.40.0 [ASSUMED: training data; not testable here] | |
| Empty tree hash resolves without being written | **Confirmed** (`cat-file -t 4b825dc…` => `tree` in a repo that never wrote it). SHA-256 object-format repos would reject the 40-hex value: out of scope, candidate is SHA-1 | |
| `--no-optional-locks` is top-level only | **Confirmed**: `status --no-optional-locks` => rc 129 | |
| Rejected argv exit codes | Unknown top-level or subcommand option => **129**; bad `-C`, non-repo, bare repo "must be run in a work tree" => **128** | all map to `prerequisite_missing` |
| `ls-files -v -z` format and tags | `<tag><space><path>\0`. Seen: `H`, `h`, `S`, `M` (one line per stage: 3 lines for a conflicted path), intent-to-add (`add -N`) shows `H` and the fresh index reports it as `?? path` | |
| Empty repo / zero tracked entries | `read-tree HEAD` => "Not a valid object name HEAD" for a repo with no commits; an empty-tree commit reads fine and `ls-files -v -z` is empty => fail closed | |
| Staged rename | fresh-index status shows ` D old` + `?? new` => **2** findings (was 1). L6 | |
| `--ignore-submodules=none` beats `submodule.<n>.ignore=all` | **Confirmed** (ordinary empty; fresh ` M libsub`) | |
| fsmonitor pin | **Confirmed**: a repo-local `core.fsmonitor` hook ran without the pin and did not run with it | |
| Read-only on the candidate | **Confirmed**: `find . -exec stat` listing of the whole scratch repo including `.git` byte-identical before/after the full probe sequence (both gits) | |
| Realpath | `git rev-parse --show-toplevel` returns the physical path. Compare by device+inode (L3) | |
| `GIT_CONFIG_GLOBAL=/dev/null` also disables `$HOME/.gitconfig` and `$XDG_CONFIG_HOME/git/config` | **Confirmed** (`config --get` returned nothing with it set, `false` without) | so CONTEXT's cut of `HOME`/`XDG_CONFIG_HOME` is fine **for config**, but not for the attributes file (L1) |
| Sparse checkout config | Not a hiding vector for the probe: `read-tree HEAD` without `-u` leaves every tag `H` | the fresh-index "all H" check is still correct as a guard |

### Deterministic same-size, same-mtime fixtures (D-21)
Verified in **Elixir** (not just Python), no sleeps:
```elixir
old = 978_307_200                               # whole-second mtime (nanoseconds = 0)
File.write!(f, "aaaa\n"); File.touch!(f, old)   # BEFORE git add, so the index records mtime=old, ns=0
# git add; git commit; git update-index --refresh
File.write!(f, "bbbb\n"); File.touch!(f, old)   # same size, same inode, same mtime; only ctime moves
```
- `core.trustctime=false`: edit in place (as above). `git -c core.trustctime=false status` is empty. Asserted as the fixture's **precondition**.
- `core.checkStat=minimal`: replace by rename of a new file (new inode) whose mtime was set to `old`: `minimal` still hides it, while `trustctime=false` alone does not (inode differs). This makes the two fixtures distinguish their own mechanism.
- Do **not** assert that default git sees the edit: on this macOS git, sub-second times are not compared, so with the edit in the same second as `git add` plain default status is also blind. Only the *hidden under the mechanism* precondition is deterministic.
- Race safety: `old` (2001) is earlier than the index file, so the entry is never "racily clean".
- Every fixture should assert its precondition with raw git (blindness proven) and then assert the probe's result with exact counts, e.g. `{:ok, %{modified: 1, flagged: 0, excludes: 0}}` for the stat-only mechanisms and `modified: 1, flagged: 1` for assume-unchanged/skip-worktree/ignoreStat. A flag-only fixture (assume-unchanged, **no** edit) yields `modified: 0, flagged: 1` and is the discriminating case for the flagged-count guard.

### Prototype probe outputs (14 fixtures, 2.41.0)
`clean clone of real candidate {0,0}`; `assume-unchanged edit {1,1}`; `skip-worktree {1,1}`; `trustctime in-place {1,0}`; `checkStat swap {1,0}`; `eol attribute {1,0}`; `config filter + info/attributes refused:hiding_config`; `core.worktree refused:hiding_config`; `unmerged {1,1}`; `flag-only {0,1}`; `untracked {1,0}`; `staged rename {2,0}`; `local filemode=false {1,0}`; `empty-tree commit unavailable`. (`{modified, flagged}`)

## Test mechanics (item 4)

- **Building repos today:** `repo_fixture/1` `twin_producers_test.exs:418-491` (git init in `System.tmp_dir!()/twin-freeze-<hex>`, commit, `side` dir for identity files/run root; note the duplicated dead `{:ok,...}` at 478-490 is IN-02); `git_env/1` `:494-506` (`HOME`, `XDG_CONFIG_HOME` under `<dir>-side/home`, `GIT_CONFIG_NOSYSTEM`, `GIT_CONFIG_GLOBAL=/dev/null`, fixed dates); `git/2` `:508-529` (adds `-c user.name/email`, `commit.gpgsign=false`, `core.autocrlf=false`; returns `{trimmed, 0}`; **asserts exit 0**, so a test cannot use it for expected-failure commands). The mix-task test has its own `git_in/2` `:523-541` and `record/3` `:42-59`.
- **Env patterns:** all twin test modules are `use ExUnit.Case, async: false`. Env mutation uses the local helper `env_restore/1` (`twin_producers_test.exs:626-632`: capture old value, `on_exit` restore or delete) then `System.put_env`. Example precedent: global-ignore test `:689-704` sets `HOME` and `XDG_CONFIG_HOME`.
- **`GIT_CONFIG_GLOBAL` in a test:** the production builder forces `GIT_CONFIG_GLOBAL=/dev/null` per call, so the process env cannot leak in. Therefore (a) prove the fixture is hiding with a *raw* `System.cmd("git", ..., env: [{"GIT_CONFIG_GLOBAL", file}])` (env passed to that one command, no global mutation), (b) `env_restore("GIT_CONFIG_GLOBAL")` + `System.put_env` while calling the probe to show the process env is ignored. Remember the global fixture needs `git config --local --unset core.filemode` (L4).
- **User-level attributes fixture (L1):** set `HOME` and `XDG_CONFIG_HOME` via `env_restore` to a dir holding `.config/git/attributes` = `* text eol=lf`, CRLF-edit a tracked file; assert raw fresh-index git is fooled and the probe blocks. With `core.attributesFile=/dev/null` pinned the probe sees ` M`.
- **Same-size/same-mtime edits:** `File.touch!(path, secs)` takes whole POSIX seconds and sets nanoseconds to 0 [VERIFIED: `stat -f %Fm` => `978307200.000000000`]. Set the old mtime before `git add`, then `File.write!` the same length and `File.touch!` back (recipe above).
- **Sandboxing `System.tmp_dir!()`:** it re-reads `TMPDIR` on every call [VERIFIED]. For "refused root leaves nothing behind" and "no stray probe dir" tests, `env_restore("TMPDIR")`, `System.put_env("TMPDIR", <absolute private dir>)`, list before/after. **A relative `TMPDIR` is honoured literally** (an earlier run of mine created a stray relative directory in the repo that I had to delete): always pass an absolute path.
- **Injecting `git_cmd`:** the injected function has the shape `fn cmd, args, opts -> {out, status} | raise end` and receives `["-c", ~s(exec "$@" 2>/dev/null), "sh", "git" | argv]`; a stub should match on the subcommand after `"git"`/pins. For unknown-tag and truncated-output tests return `{"X f\0", 0}` / `{"H f", 0}` (no trailing NUL) for `ls-files`. For rejected-argv tests return `{"", 129}` and `{"", 128}`. For the NUL/ArgumentError path, a stub that `raise ArgumentError, "invalid path /secret/place"` and an assertion the output has no `/secret/place` (see L10).
- **Builder test (behavioural):** a recording `git_cmd` that delegates to `System.cmd/3`, driven through `source_gate`, `freeze`, `observe_identities`, `checked_identities`, `probe_source`, `dirty_counts`; assert every recorded call (a) has `"git"` followed by the exact pin list, (b) env contains the scrub (`GIT_CONFIG_GLOBAL=/dev/null`, `GIT_DIR` nil, ...), (c) the call count is above a floor (so an entry point that stops spawning git cannot pass vacuously). Mutation: bypass the builder in one site => this test names the failure.
- **fd-level stderr test (`twin_producers_test.exs:755-789`) must be rewritten.** It puts a fake `git` earlier on `PATH` that answers `status`, `--git-path`, `rev-parse` only; the new probe also runs `--version`, `config --list`, `rev-parse --show-toplevel`, `ls-files -v -z`, `read-tree` and needs a non-empty real-index listing. Make the wrapper delegate to the real git (`exec "$REAL_GIT" "$@"`, with `REAL_GIT = System.find_executable("git")` resolved **before** the PATH edit) after logging whether fd 2 is `/dev/null`; raise the `length(lines) >= 4` floor to the new call count. Mutation 8 (remove the `sh` wrapper) must still read "leak".
- **Fake `sh`-less environments:** the existing code requires `sh` and `git` on PATH; unchanged.

## Port (item 5)

Today's runtime holds the origin: `acquire_origin/1` (`twin_runtime.ex:471-492`) listens with `[:binary, ip: {127,0,0,1}, reuseaddr: false, active: false, packet: :raw]`, stores the listener in `%TwinRuntime{origin_listener: ...}` (`:34`, set at `:76`), and `stop_all/1` closes it (`:197`). `twin_fault_boundary.ex` takes it over. Test precedent: `verify_twin_test.exs:35-40` (`free_port/0`: listen on 0, read the port, close) and `:152-167` ("origin stays held between prepare and stop_all": second listen => `{:error, :eaddrinuse}`, rebind after `stop_all` works). The preflight's bind-and-release mirrors this (Pattern 7) and must say "free at this moment" (inherently racy; `commit/1` re-binds and re-maps `eaddrinuse`).

## Vacuous-assertion ledger (item 6)

- Mechanism: `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs` runs `script/inventory_collection_assertions.exs --check` against `script/collection_assertion_ledger.json` (scope `test/**/*.exs`). The scanner flags four literal shapes: `assert Enum.all?(`, `assert Enum.any?(`, `refute Enum.any?(`, `refute Enum.all?(` (regex at `inventory_collection_assertions.exs:70-75`).
- The ledger test asserts **full-row equality** including `display` (`file:line`), and hard-codes `@audited_site_count 243`, `@shape_counts` (`assert_all 57, assert_any 135, refute_any 51, refute_all 0`) and `@bucket_counts` (`:30-46`).
- Consequences:
  1. **Any new use of those four shapes** in a `*.exs` test adds a row and changes the hard-coded counts (and may need `@manual_overrides`; phase 180 had to do this for one site, commit `736a7d7`).
  2. **Any line shift** above an existing row in the same file changes `display` and fails the suite. Rows exist in the twin tests at: `twin_producers_test.exs:80, :265`; `twin_fault_boundary_test.exs:219`; `twin_receipt_test.exs:54`; `crosswake_proof_lane_verify_twin_test.exs:269, :294, :338`. Edits **below** the last row of each file (after line 265 / 338) do not shift anything.
- How 183 handled it: its first placement of new mix-task tests shifted rows and failed the ledger suite; it moved the new tests to the end of the file, and the ledger stayed unregenerated (183-03 SUMMARY, deviation 1).
- **Recommendation:** put all new tests in new files (no existing rows), append-only edits otherwise, and write collection assertions as `assert length(x) == n` / `assert x == []` / `for ... do assert ... end` with a count, never the four shapes. Gate: `git diff -U0 | grep -E '(assert|refute)[[:space:]]+Enum\.(all|any)\?\('` must be empty, plus `elixir script/inventory_collection_assertions.exs --check` and the phase170 test.
- New test code also must not use `assert Enum.any?` (counted under `assert_any`, 135 sites) even though it is "safe by construction".

## Mutation-control pattern (item 7)

183's pattern (183-03 plan, Task 3; `/private/tmp/crosswake-phase180-run/mutation-183.log`):
1. `rsync -a --exclude .git <candidate>/ /private/tmp/crosswake-184-mutation` (including `_build` and `deps` to avoid a cold compile).
2. For each control: apply one edit with `perl -0pi`, run the named test file with `mix test`, require a non-zero exit **and** at least one failure, log `control N: <name>: failed as expected (rc=… N tests, M failures)`, restore the file from the candidate.
3. One unmutated run must pass (clean case).
4. Delete the copy; nothing committed; no permanent CI lane.

183's gaps that D-22 closes: failing test **names** were not retained, and a mutation that silently did nothing would have passed (research v26 PITFALLS #3: `perl` `\1` followed by a digit reads as group 10; `mix test file:LINE` of a moved test prints `0 tests, 0 failures`, exit 0). So the harness for 184 must, per control:
- assert `sha256(before) != sha256(after)` for the mutated file before running anything;
- redirect `mix test` output to a file and take its exit status from the command itself (never `cmd | tail`; the pipe masks the status);
- parse `N tests, M failures` and require `N >= 1` **and** `M >= 1`;
- parse failing names (`^\s+\d+\) test <name> \(<Module>\)`) and require the **named** expected test among them;
- log `control N: <guard>: failed as expected in "<test name>" (N tests, M failures)`; also log the unmutated pass with `N >= expected_count`.

Proposed controls (each fixture is chosen so *only* that guard catches it; see L5):
| # | Guard | Mutation | Discriminating test |
|---|---|---|---|
| 1 | fresh index | probe runs `status` on the real index (drop `GIT_INDEX_FILE`/`read-tree`) | `trustctime=false` and `checkStat=minimal` fixtures (no flag bit, so the flagged count cannot rescue them) |
| 2 | filemode pin | remove `-c core.filemode=true` | local `core.filemode=false` + `chmod` fixture |
| 3 | flagged count | force F = 0 | assume-unchanged **without an edit** (`modified: 0, flagged: 1`) and the unmerged fixture |
| 4 | exclude count | force X = 0 | `info/exclude` rule fixture |
| 5 | toplevel check | always accept | `core.worktree` redirect fixture |
| 6 | filter refusal | drop the `filter.` rule | `filter.x.clean` in local config with **no attribute and no edit** => must still be blocked |
| 7 | info/attributes refusal | drop it | non-empty `.git/info/attributes` with no filter, no edit |
| 8 | attr-source | remove the `--attr-source` pin | tracked `.gitattributes` `text eol=lf` + CRLF-only edit |
| 9 | attributesFile pin (if adopted) | remove `-c core.attributesFile=/dev/null` | user-level attributes fixture |
| 10 | builder use | route one call site around the builder | builder test |
| 11 | preflight empty check list | treat `[]` as ok | `checks: []` => blocked |
| 12 | owner check | always ok | owner-seam test |

## Commit discipline (item 8)

From 183 (SUMMARY 183-03, VERIFICATION, plans):
- One candidate commit on top of the previous product commit, subject style `fix(183-03): fail closed on an uncommitted twin candidate` (earlier: `feat(180-0N): …`, `test(182-0N): …`). Staged paths are checked to equal an exact expected list. Co-author trailer per the session attribution. Candidate push URL stays `no-push-phase180` (`git remote -v` shows `origin no-push-phase180 (push)`).
- Recorded outside git in `/private/tmp/crosswake-phase180-run/` (listing verified): `baseline-183.failures` + `baseline-183.full.out` (taken **before** edits: `mix test --exclude requires_example_host` with output redirected to a file), `fix-183.failures`, `fix-183.full.out`, `fix-183.commit` (SHA), `mutation-183.log`, `history-183.before.sha256` (54 lines; `shasum -a 256 -c` currently reports all OK), `prepare-record.sh`, `preflight-04.sh`, `gate.sh`.
- The only expected full-suite failure is `test/crosswake/proof/phase180_twin_feasibility_test.exs:30` (known G1 gate failure, identical in baseline and post-fix; `cmp` of the two failure files).
- Planning-doc commits were skipped (isolation none; recovery checkout is planning-only; no staging/commits there). SUMMARY is a plain uncommitted file. A blocked plan leaves `NN-BLOCKED.md`, not `NN-SUMMARY.md`.
- **For 184:** snapshot `baseline-184.*` and a fresh `history-184.before.sha256` (include twin-04) before the first edit; edit uncommitted; run gates and mutations in the last plan; commit once (suggest `feat(184-0N): harden the twin source probe and add a read-only preflight`; this adds a task, so `feat`, not `fix`); write `fix-184.commit`-equivalent (`feat-184.commit`); verify `shasum -c` on the history manifest and porcelain empty. Phases 185/186 stack on this commit, and Phase 188's freeze commit must be the *last* candidate change touching attested source.

## Docs / guide touchpoints (item 9)

- `guides/see_it_run.md`, section "## Run the Reference Twin (Simulator)" (lines ~160-185): add the preflight command and what "allowed" does and does not cover; reword the sentence at `:176` ("The candidate tree must be clean at the recorded head; a dirty tree is refused.") to mention flags/config; keep it free of "go/no-go". Tests that read this guide are generic (`test/crosswake/guides/see_it_run_test.exs`, `readme_see_it_run_test.exs`, `quick_start_adoption_drift_test.exs`, `architecture_code_walkthrough_test.exs`); none assert twin text (grep for `twin` in `test/crosswake/guides` returned nothing). Gates to run after the edit: `mix test test/crosswake/guides test/crosswake/proof/phase69_docs_contract_parity_test.exs`, `mix crosswake.docs.sync --check`, `mix crosswake.adoption_context.scan` (CI job at `.github/workflows/crosswake-ci.yml:121`). `crosswake.docs.sync` projects only the support/capability guides, not `see_it_run.md`, and `mix.exs` has no module-group list to update for new modules. The 183 SUMMARY recorded a guide SHA for the STATE "Guide pending reconciliation" line; if the project still tracks that, record the new SHA-256 in the 184 SUMMARY.
- The new task's `@moduledoc` and `@shortdoc` are the only other documentation; state "preflight, not go/no-go", the four-line contract, exit codes 0/2, and that "findings, not distinct files" are counted.
- Public text must not include the adopter's identity (AGENTS.md privacy rules); none is needed here.

## Common Pitfalls and Landmines (item 11)

**CONTEXT.md items that do not work as written (not silently changed; planner decision required):**

### L1: A user-level attributes file fools the D-05-pinned probe (HIGH, verified)
**What goes wrong:** with `$XDG_CONFIG_HOME/git/attributes` (or `~/.config/git/attributes`) containing `* text eol=lf`, a CRLF-only edit leaves the fresh-index status empty even with `--attr-source=<empty tree>` and `GIT_CONFIG_GLOBAL=/dev/null` (output empty). `--attr-source` replaces only the tree's `.gitattributes`; the attributes-file location is independent of config.
**Fix verified:** adding `-c core.attributesFile=/dev/null` restores ` M a.txt`; so does `HOME=/nonexistent XDG_CONFIG_HOME=/nonexistent` (but CONTEXT cut `HOME`/`XDG_CONFIG_HOME`).
**Recommendation:** adopt the single extra pin and add a fixture. Needs the user's nod because D-05 lists the pins explicitly; a deviation should be recorded in the plan.

### L2: `config --list --name-only` cannot evaluate D-04's value tests (HIGH, verified)
`core.symlinks=false`, `core.bare=true` and `extensions.worktreeConfig` need values. Use `git config --list --local --includes -z` (`key\nvalue\0`; valueless boolean = `key\0`). Git lowercases section/variable names but keeps subsection case, so downcase before the `filter.` prefix match.

### L3: String-comparing the toplevel breaks on macOS (HIGH, verified)
`System.tmp_dir!()` is `<tmp>/`; git prints `/private/var/folders/...`; `/tmp` is also an alias of `/private/tmp`. Every existing `repo_fixture` lives under that tmp dir. Compare device+inode (Pattern 6); there is no `File.realpath` in Elixir.

### L4: The global `filemode=false` fixture must unset the local value (HIGH, verified)
`git init` writes `core.filemode = true` into the repo config, and local beats global, so a global `filemode=false` hides nothing by default (ordinary status still showed ` M`). The fixture must run `git config --local --unset core.filemode` before the chmod. Without it, "unpinned git is fooled" (D-21) fails.

### L5: The "tracked `.gitattributes` filter" fixture cannot make attr-source load-bearing (HIGH, verified)
A `filter=` attribute needs a `filter.<n>.*` config key, which the D-04 filter refusal blocks first; removing `--attr-source` would not fail that test. Use a tracked `text eol=lf` (or `ident`) attribute with no filter config and a CRLF-only (or `$Id: x $`) edit: the fresh index is fooled without the pin and sees ` M` with it. Likewise the filter-refusal and info/attributes-refusal guards each need a fixture only they catch (a `filter.*` key or a non-empty `info/attributes` with nothing modified, asserted blocked) or removing one guard leaves the other masking it.

### L6: Staged renames now count as 2 findings (MEDIUM, verified)
Under a fresh index a `git mv` appears as ` D old` + `?? new`. The existing test "a staged rename blocks and counts once" (`twin_producers_test.exs:669-673`, asserts `dirty_count == 1`) must change to 2 and be renamed; `count_records/2`'s rename branch becomes unreachable (keep as defensive or delete with its test). Update the documentation sentence about counting findings.

### L7: Existing fake-git stderr test needs a rewrite (MEDIUM)
See "Test mechanics".

### L8: Ledger line drift / new collection shapes (MEDIUM)
See item 6. New files only; append-only edits.

### L9: Relative `GIT_INDEX_FILE` writes into the candidate (HIGH, verified)
`GIT_INDEX_FILE=rel-index git -C <cand> read-tree HEAD` created `rel-index` inside the candidate. The temp path must be absolute and outside candidate, `.git` and run root; check containment with the dev/inode walk, and add a test with `TMPDIR` pointing inside the candidate (expected: `prerequisite_missing`, nothing created in the candidate).

### L10: NUL in argv is truncated, not rejected, on OTP 27 (MEDIUM, verified)
`System.cmd("git", ["-C", "a\0b", "status"])` ran git with `-C a` (rc 128, no exception). An `ArgumentError` ("invalid option in list") occurs for NUL in an **env value**; NUL in `cd:` yields a spawn error string with the path. 183's IN-04 premise (an `ArgumentError` whose message may contain a path) is only partly accurate on this OTP. Rescue `ArgumentError` as well as `ErlangError` in the single spawn site, reject any candidate path containing `<<0>>` before spawning, and test with an injected raising stub whose message carries a distinctive path. [Behaviour on other OTP versions: ASSUMED]

### L11: Version compare must be numeric (MEDIUM)
Compare `{major, minor}` integer tuples from `~r/\Agit version (\d+)\.(\d+)/` (Apple's string is `git version 2.50.1 (Apple Git-155)`); a string compare would rank 2.9 above 2.41. Run the version call through the builder with an empty pin list (`:bare`) because on git < 2.40 the pinned argv itself is rejected (rc 129) and would hide the real reason.

### L12: Config must be read before the toplevel (MEDIUM, verified)
`core.bare=true` => `rev-parse --show-toplevel` fails with 128 ("must be run in a work tree"); read config first so the cause is `hiding_config`, not `prerequisite_missing`.

### L13: D-18 comparability (resolved: comparable)
Record shape (from `twin-04-candidate.json` and `prepare-record.sh`): `resource_digests: [manifest, activation, study_js]`, `fixture_digests: [media]`; `freeze/3` builds `resources = [identity.manifest, identity.activation, study_js]` and `fixture_digests: [identity.media]` (`twin_producers.ex:640,649`). So `TwinPreflight` can compare `[gate.identity.manifest, gate.identity.activation, gate.study_js] == record.resource_digests` and `[gate.identity.media] == record.fixture_digests`. Note the **real run does not do this comparison today**; only the out-of-band `preflight-04.sh` does. Keep it preflight-only in this phase (adding it to `source_gate/3` would break the `freeze` tests whose runtime has `resource_digests: nil`); flag in the plan that the real run still re-derives from the identity file. On mismatch return `identity_mismatch`.

### L14: Two bound constants (LOW)
`@max_dirty_count` (`twin_producers.ex:712`) and `@max_measure` (`twin_receipt.ex:56`) are both 1_000_000. Add a test pinning them equal, or read one from the other.

### L15: Safe.directory behaviour change (LOW)
Because global config is now `/dev/null`, `safe.directory` entries are ignored; a candidate owned by another uid is refused (rc 128 => `prerequisite_missing`). Acceptable (candidate is owned by the runner); note in the doc.

### L16: Windows / non-POSIX filesystems (LOW, disclosure)
`core.filemode=true` on a filesystem that reports all files 0755 yields false `source_dirty`. Not a concern for the macOS/Linux runner; the refusal of `core.symlinks=false` already encodes the same stance.

### L17: Extra git spawns (LOW)
About 10 git processes per probe; `observe_identities` and `checked_identities` each probe (and `checked_identities` then calls `observe_identities`, probing again). Measured whole-sequence cost on a 3257-file clone: ~0.16 s. No caching.

### L18: Preflight and the registry/`record_failure` (LOW)
`blocked_receipt` calls `TwinRuntime.record_failure/2` which needs an Agent. Preflight starts no Agent, so none of that code may be reused; the message composer and probe are the shared parts.

### L19: Existing tests unaffected by the owner check
Roots in existing tests are created by the test user (`File.mkdir_p!` + `chmod 0700`).

## Code Examples

### Message composer (shared by `verify_twin` and `twin_preflight`; wording to be finalised by the planner, exact strings asserted in tests)
```elixir
# counts: %{modified: m, flagged: f, excludes: x}; clauses joined in order M, F, X with "; and "
# singular/plural handled per clause; zero counts dropped; X never says "files".
def source_block_action({:ok, %{modified: m, flagged: f, excludes: x}} = _probe) when m + f + x > 0 do
  clauses =
    [
      m > 0 && "#{m} changed or untracked #{pluralize(m, "file")}",
      f > 0 && "#{f} tracked #{pluralize(f, "file")} marked unchanged in git's index (assume-unchanged or skip-worktree flags), so edits to them would go unseen",
      x > 0 && "#{x} local ignore #{pluralize(x, "rule")} in .git/info/exclude"
    ]
    |> Enum.filter(& &1)
    |> Enum.join("; and ")
  "The candidate has #{clauses}. " <> remedy(m, f, x) <> ", then write a new prepared record and run into a new run root."
end
def source_block_action({:refused, :hiding_config}), do: "The candidate's git configuration can hide changes (a worktree redirect, a filter, or .git/info/attributes); remove it, then write a new prepared record and run into a new run root."
def source_block_action(_unknown), do: "The candidate has changes git could not count. ..."   # contains no digit
```
(`remedy/3` names `git update-index --no-assume-unchanged` / `--no-skip-worktree` and `git ls-files -v` (entries not marked H) for F, "Remove the rules from .git/info/exclude" for X, "Commit or remove them" for M. A previously shipped sentence told users to run `git status`, which shows nothing when only a flag or an exclude rule triggered the block: that is WR-03.)

### Preflight skeleton
```elixir
defmodule Crosswake.ProofLane.TwinPreflight do
  def check(opts) do
    checks = Keyword.get(opts, :checks, default_checks())        # test seam; [] must NOT be ok (D-20)
    if checks == [], do: {:blocked, :prerequisite_missing, "No preflight checks were configured."}, else: run(checks, opts)
  end
  # default_checks: root_required -> TwinRuntime.check -> source_gate (+ re-probe detail on source_dirty) -> D-18 comparison
end
```
Task `execute/2` returns `{0 | 2, [line1..line4]}`; fixed lines: `result: allowed` / `result: blocked`; `first cause: none` / `first cause: <atom>`; `report: none written; no run root was created or consumed`; `next action: …` (allowed text from D-14). `OptionParser` invalid => `{2, ...}` with a path-free usage line, never `Mix.raise`. Read `DATABASE_PATH` like `verify_twin` does so a bad value yields the same first cause in both.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Trust `git status` on the real index (Go `vcs.modified`, cargo dirty check, per researcher memory in CONTEXT; **not verified**) | Fresh index from HEAD + flagged-tag count + refusal of hiding config | this phase | Closes assume-unchanged, skip-worktree, ignoreStat, checkStat, trustctime, filemode |
| One-off `sh` wrapper pinned in one function | One builder for all calls | this phase | Closes 183 IN-01 |

**Deprecated/outdated:** the 183 sentence "Run git status in the candidate to see them." (misleading when only flags/rules triggered).

## Runtime State Inventory

Not a rename/refactor/migration phase: omitted.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| git | probe, fixtures | yes | 2.41.0 (`/opt/homebrew/bin/git`), 2.50.1 Apple (`/usr/bin/git`) | none (floor 2.41) |
| Elixir / OTP / mix | tests | yes | 1.19.5 / OTP 27 | none |
| `sh`, `id`, `perl`, `rsync`, `shasum` | wrapper, owner check, mutation harness, history manifest | yes (standard macOS; `id -u` => 501) | — | owner check fails closed if `id` missing |
| candidate checkout | all code | yes, HEAD `50fcd57`, clean (`git status --short` empty), 3257 tracked entries all tag `H`, no `filter.*`, no `info/attributes`, `info/exclude` has comments only, push URL `no-push-phase180` | — | — |
| `_build`/`deps` in candidate | `mix test` | present (`_build/{dev,test}`, 23 deps) | — | rsync copy for mutations |

The real candidate would pass the new refusals (no filter keys, no attributes file, no `core.worktree`, toplevel equals path); the 183 disposition recorded the same facts.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.5 / OTP 27), run in the candidate `/private/tmp/crosswake-phase180-impl` |
| Config file | `test/test_helper.exs` (no change); `elixirc_paths(:test)` includes `test/support` |
| Quick run command | `cd /private/tmp/crosswake-phase180-impl && mix test test/crosswake/proof_lane/twin_source_probe_test.exs test/crosswake/proof_lane/twin_runtime_check_test.exs test/mix/tasks/crosswake_proof_lane_twin_preflight_test.exs test/crosswake/proof_lane/twin_producers_test.exs test/crosswake/proof_lane/twin_receipt_test.exs test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs` |
| Full suite command | `cd /private/tmp/crosswake-phase180-impl && mix test --exclude requires_example_host > /private/tmp/crosswake-phase180-run/<name>.full.out 2>&1; echo $?` (redirect, no pipe; only the known G1 failure `test/crosswake/proof/phase180_twin_feasibility_test.exs:30` may fail) |

(New test file names are proposals; the planner may rename.)

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROBE-01 | Each hiding mechanism (assume-unchanged, skip-worktree, ignoreStat, checkStat=minimal, trustctime=false, filemode=false local and global) blocks `source_dirty`; untracked, exclude, hidden-config, unmerged, user-level attributes, eol-attribute fixtures; untouched control passes; zero tracked / unknown tag / truncated output / git failure / temp-dir failure fail closed | integration (real temp repos) | `mix test test/crosswake/proof_lane/twin_source_probe_test.exs` | Wave 0 (new) |
| PROBE-01 | Updated existing cases (staged rename = 2, clean control, gitignored file allowed, GIT_DIR scrub, global ignore) | integration | `mix test test/crosswake/proof_lane/twin_producers_test.exs` | exists (edit) |
| PROBE-02 | Every entry point (`source_gate`, `freeze`, `observe_identities`, `checked_identities`, probe, `dirty_counts`) spawns git only through the builder with full pins/env; rejected argv (rc 128/129) and a raising spawn give `prerequisite_missing` with a path-free message; fd-level stderr discard | unit with recording `git_cmd`; integration | `mix test test/crosswake/proof_lane/twin_source_probe_test.exs test/crosswake/proof_lane/twin_producers_test.exs` | Wave 0 (new) + edit |
| PROBE-03 | Exact line-4 strings for M-only, F-only, X-only, mixed, hiding config, unknown; unknown text has no digit; X clause has no "files"; privacy scan (no candidate path / `$HOME` in any output or receipt); `measure == M+F+X`, nil above bound | unit + task-level | `mix test test/crosswake/proof_lane/twin_source_probe_test.exs test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs` | Wave 0 + edit |
| PROBE-03 | Recorded mutation controls (12 in the table above) each fail their named test; each run parses `N >= 1` tests and the named failure | scripted, throwaway copy, not committed | `/private/tmp/crosswake-phase180-run/mutate-184.sh` -> `mutation-184.log` | Wave 0 (ephemeral) |
| PROBE-04 | `check/1` and `prepare/1` agree on first cause for a table of inputs; `commit/1` is the only creator; owner check refuses a foreign-owned root (seam); nil-root refusal leaves the sandboxed `TMPDIR` empty (IN-03) | integration | `mix test test/crosswake/proof_lane/twin_runtime_check_test.exs test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs` | Wave 0 (new) + exists |
| PROBE-04 | Preflight: exact four lines for allowed and each blocked cause; exit 0/2 only; bad options and unreadable identity => exit 2; `--run-root` required; D-18 mismatch => `identity_mismatch`; `checks: []` => blocked; before/after listings of root, candidate and candidate `.git` unchanged for allowed, dirty, reused root, missing root, bad record; no `receipt.json`, no `expectations.json`, no `twin-result.json`; occupied port blocked | integration | `mix test test/mix/tasks/crosswake_proof_lane_twin_preflight_test.exs` | Wave 0 (new) |

### Sampling Rate
- **Per task commit (here: per task, since the candidate is uncommitted until the last plan):** the quick run command above.
- **Per wave merge:** full suite (redirected) compared to `baseline-184.failures` with `cmp`; plus `mix test test/crosswake/guides test/crosswake/proof/phase69_docs_contract_parity_test.exs test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs`, `elixir script/inventory_collection_assertions.exs --check`, `mix crosswake.docs.sync --check`, `mix crosswake.adoption_context.scan`, `mix compile --warnings-as-errors`, `mix format --check-formatted` on touched files.
- **Phase gate:** all of the above green; mutation log has every control "failed as expected" with a named test and `N >= 1`; unmutated run passes; `shasum -a 256 -c history-184.before.sha256` all OK; candidate porcelain empty after the single commit; push URL unchanged; recovery checkout index empty.

### Wave 0 Gaps
- [ ] `test/crosswake/proof_lane/twin_source_probe_test.exs` -- PROBE-01/02/03 fixtures, builder test, strings, privacy
- [ ] `test/crosswake/proof_lane/twin_runtime_check_test.exs` -- PROBE-04 check/commit split, owner seam, same-causes table, leftovers
- [ ] `test/mix/tasks/crosswake_proof_lane_twin_preflight_test.exs` -- PROBE-04 task
- [ ] optional `test/support/twin_git_fixtures.ex` -- shared repo/hiding-mechanism builders (outside the ledger scan scope `test/**/*.exs`)
- [ ] `/private/tmp/crosswake-phase180-run/mutate-184.sh` (ephemeral) and `baseline-184.*`, `history-184.before.sha256`
- Framework install: none.

## Security Domain

`security_enforcement` is absent in `.planning/config.json`, so treated as enabled.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | yes (local) | Run root must be a real directory, mode 0700, owned by the current uid |
| V5 Input Validation | yes | Strict `OptionParser`; candidate record JSON field/format validation (existing); candidate path reaches git only as an argv element (never in script text); reject NUL-bearing paths |
| V6 Cryptography | no | SHA-256 digests via `:crypto` (existing) |
| V12 Files and Resources | yes | Private temp dir (`File.mkdir` + 0700, random name, outside candidate/.git/run root, removed, removal failure fails closed); preflight writes nothing else |
| V14 Configuration | yes | Pinned git config + scrubbed env so caller/user/system config cannot alter the verdict |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Hidden modification via index flags / stat cache / filemode | Tampering | Fresh index from HEAD + flagged count + filemode pin |
| Redirected worktree (`core.worktree`), filters, attributes (info, user-level, tracked) | Tampering / Spoofing | Toplevel inode check, filter/attributes/bare/symlinks refusal, `--attr-source`, `core.attributesFile=/dev/null` |
| Caller `GIT_*` env injection (`GIT_DIR`, `GIT_CONFIG_COUNT`, `GIT_INDEX_FILE`, `GIT_ATTR_SOURCE`, `GIT_EXEC_PATH`) | Tampering | Explicit scrub through one builder; a test sets hostile process env |
| Repo-local `core.fsmonitor` running code during status | Elevation / Tampering | `-c core.fsmonitor=false` (verified: hook ran without the pin) |
| Disclosure of candidate path / `$HOME` / username in messages | Information disclosure | stderr to `/dev/null` at fd level; output only counts and fixed text; rescue exceptions without echoing `Exception.message`; privacy-scan test |
| Writing into the candidate via a relative `GIT_INDEX_FILE` | Tampering | Absolute temp path + containment check (verified failure mode, L9) |
| Temp-dir pre-creation / symlink race in shared tmp | Tampering | `File.mkdir` (fails if exists), unpredictable name, 0700, lstat checks |
| Preflight consuming or creating the run root | Repudiation / DoS (burns twin-05) | Structural: check/commit split; before/after listing tests |
| TOCTOU on origin port | — | Documented as "free at this moment"; `commit/1` re-maps `eaddrinuse` |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `--attr-source` / `GIT_ATTR_SOURCE` first appeared in git 2.40.0 | Git mechanics | Floor of 2.41 (D-06) is already above it; only matters if the floor is lowered |
| A2 | Linux git (CI) behaves like macOS git for the stat-based fixtures (sub-second compare may be ON there: USE_NSEC); fixtures are built with ns=0 mtimes so should hold | Test mechanics | A Linux-only fixture flake; confirm on first CI run, or gate with a precondition assertion that already exists |
| A3 | `id -u` exists on every runner that runs the twin | Don't hand-roll | Owner check fails closed (`prerequisite_missing`) rather than passing |
| A4 | OTP versions other than 27 may raise (rather than truncate) on NUL in argv | L10 | Rescuing `ArgumentError` handles both; only the test's expectation differs |
| A5 | Go's `vcs.modified` and cargo trust the stat cache (CONTEXT precedent) | State of the Art | None for implementation; explanatory only |
| A6 | `extensions.worktreeConfig` should be refused when it is true (CONTEXT says "found"; value semantics unspecified) | Pattern 5 | Refusing on mere presence would also be safe but over-blocks `=false` |
| A7 | A non-empty `.git/info/attributes` means any active (non-comment, non-blank) line | Open Q4 | Refusing a comment-only file would be over-strict but safe |

## Open Questions (RESOLVED)

All five were resolved during plan-phase on 2026-10-15 under the user's standing instruction to follow the synthesized recommendations; see 184-CONTEXT.md D-23..D-33.

1. **Adopt `-c core.attributesFile=/dev/null`? (L1)**
   - What we know: the D-05 pin set is fooled by a user-level attributes file; the extra pin is verified, one argv pair, no downside observed.
   - What's unclear: whether the user wants the locked pin list amended or prefers scrubbing `HOME`/`XDG_CONFIG_HOME` (also verified, but touches the "cut" list).
   - Recommendation: add the pin; record the amendment in the plan and mutation table.
   - RESOLVED: adopted as D-23.

2. **Line 1 text of the preflight:** D-14 says `result: allowed|blocked`; `verify_twin` prints `result: blocked (exit 2)`. Recommendation: follow D-14 literally (no `(exit N)` suffix) and lock it with an exact-string test; the exit code is the process status. RESOLVED: adopted as D-31.

3. **Owner check source of uid:** `id -u` plus an options seam (recommended) vs a different mechanism. Recommendation: `id -u`, fail closed. RESOLVED: adopted as D-31.

4. **Active-lines vs any-bytes for `info/attributes` and `extensions.worktreeConfig` semantics (A6, A7):** recommend active lines only and truthy value, to avoid false refusals while still catching every hiding case found. RESOLVED: adopted as D-24.

5. **Should the real run also enforce the D-18 record-vs-identity comparison?** Today it does not (L13). Recommendation: preflight-only in 184; raise it for Phase 188's go/no-go script, which can call the preflight. RESOLVED: adopted as D-31.

## Sources

### Primary (HIGH confidence)
- Candidate source read in full this session: `lib/crosswake/proof_lane/twin_producers.ex` (lines 600-1079 and header), `twin_runtime.ex`, `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex`; `twin_receipt.ex` (causes, measure, limits); tests `twin_producers_test.exs`, `crosswake_proof_lane_verify_twin_test.exs`; `phase170_vacuous_assertion_ledger_test.exs`; `script/inventory_collection_assertions.exs`; `guides/see_it_run.md`.
- Scratch-repo experiments with git 2.41.0 and 2.50.1; Elixir/OTP 27 experiments (NUL argv, `File.touch`, dev/inode, `:gen_tcp`, `TMPDIR`); working probe prototype (`proto.exs`) in the session scratchpad.
- Planning artifacts: 184-CONTEXT.md, REQUIREMENTS.md, 183 SUMMARY/VERIFICATION/REVIEW-DISPOSITION/03-PLAN, v26 PITFALLS.md, run directory `/private/tmp/crosswake-phase180-run/`.

### Secondary (MEDIUM confidence)
- git behaviour inferred from experiments rather than source reading (e.g. `checkStat=minimal` ignoring ctime/ns/uid/inode matches observed outcomes).

### Tertiary (LOW confidence)
- Precedent claims about Go/cargo (CONTEXT) and the 2.40 introduction of `--attr-source` (training knowledge; tagged `[ASSUMED]`).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no new dependencies; toolchain versions verified.
- Architecture (split designs): HIGH -- derived from the code read in full, with callers/tests enumerated; the `check/1` nil-root handling is the one design choice to confirm in review.
- Git mechanics: HIGH on macOS (two git versions); MEDIUM for Linux CI.
- Pitfalls: HIGH -- most landmines were reproduced.

**Research date:** 2026-10-15
**Valid until:** 2026-11-15 (stable; re-check if the git floor or candidate HEAD changes)
