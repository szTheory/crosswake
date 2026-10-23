# Phase 190: Fix warnings before landing - Research

**Researched:** 2026-10-19
**Domain:** Elixir proof-lane fixes (twin runtime, provenance, preflight, absence guard) plus POSIX-sh evidence-script successors
**Confidence:** HIGH for code facts (all source files were opened this session); MEDIUM for two design choices flagged in Open Questions

Placeholders used throughout: `<durable-candidate>` (clone at HEAD `a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4`, branch `candidate`), `<recovery-checkout>`, `<backup-root>`, `<tmp>`. No absolute home path appears in this file.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** The Phase 188 scripts in `phases/188-freeze-and-twin-05/scripts/` stay byte-for-byte unchanged. Fixed, self-tested successors go in `phases/190-fix-warnings-before-landing/scripts/` and land with the planning records in Phase 191. `188-REVIEW-DISPOSITION.md` gets a one-line pointer from WR-01, WR-08 and the `g()` integration item to these successors. The successors are not promoted into the candidate as permanent tooling.
- **D-02:** Roadmap success criterion 5 is reworded to match D-01 (done at discussion time).
- **D-03 (FIX-01):** The successor privacy scan counts the regular files it actually expands, not the lines in the list. It exits 2 (scope error) when the total is zero, or when any listed directory expands to zero files. Symlinks are refused explicitly with a scope error, never followed silently and never skipped silently. Self-tests: an empty directory, a directory holding only a symlink, and a list with a missing entry.
- **D-04 (FIX-02):** Every gate label has at least one negative control that makes it fail, including `port_4790_free`, `no_leftover_simulator`, `simulator_runtime_available`, `run_env_unsets_build_and_db`, `head_equals_record`, `tree_equals_record`, the 87-count branch of `history_manifest_87_ok`, and the real-mode branch of `mode_resolved`. Controls use stubs. The self-test also checks that every label the gate can emit has a failing control: label coverage is derived from the gate's source, not from a hand-kept list.
- **D-05 (FIX-03):** All successors share one `g()` helper that sets the same environment and pins as the Elixir funnel (`@git_env`, `@git_pins` in `twin_producers.ex`): full scrub list plus `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`, `GIT_NO_REPLACE_OBJECTS=1`, `GIT_ATTR_NOSYSTEM=1`, `GIT_OPTIONAL_LOCKS=0`, `GIT_TERMINAL_PROMPT=0`, `LC_ALL=C` and the same `-c` pins incl. `core.hooksPath=/dev/null` and `--attr-source=<empty tree>`. Proof: a comparison test with a misleading global config in a temp `HOME` asserting shell `g()` and the Elixir funnel agree; a second check compares the helper's environment/pin list with the funnel's source.
- **D-06 (FIX-04):** `tracked_children/1` treats `{:noproc, _}`, `{:normal, _}`, `{:shutdown, _}` exits as gone. `{:timeout, _}` is reported as a new `{:error, :registry_timeout}`. On a timeout `stop_all/1` does not call `Agent.stop/1` (registry and child list stay alive; origin listener still closed). `@spec` gains `:registry_timeout`. The caller at `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex:79` shows the timeout in the verdict instead of dropping it. Tests: slow registry reported as a timeout and stays alive; dead registry still `:registry_gone`.
- **D-07 (FIX-05):** `Provenance.commit_ref/1` uses the same pinned git environment as the shared funnel (reuse or extract `@git_env`, not copy). It also requires `git rev-parse --show-toplevel` to equal the canonicalized `cwd`, else `git-unknown`. New test: host folder nested inside a temp repo with no `.git` of its own gets `git-unknown`. The existing no-`.git` test stays.
- **D-08 (FIX-07, owner decision: refuse):** Refusal lives in the preflight's `origin_refusal_for`. `IosHostOriginMode.observe/2` keeps its shared meaning. Preflight refuses with `PI-PREFLIGHT-CONFIG` and a clear reason when the shell root exists and `Info.plist` cannot be read (missing, `eisdir`, permissions), or when `Fixtures/route_activation.json` exists but cannot be read or parsed. Absent `route_activation.json` with a readable production plist still passes. Doc comment reworded to describe this exactly. Tests: `Info.plist` replaced by a directory (blocked), malformed JSON (blocked), readable production with no activation file (passes).
- **D-09 (FIX-06):** Guard pin (`script/check_absence_is_not_success.exs:64`, `{"test-files", "test/**/*.exs", 249}`) is raised in the last FIX commit to the count measured by a separate command at that final commit, never derived from the guard's own glob at check time (185 D-03). Phase 191 counts again on the integration branch.
- **D-10:** One commit per FIX on `refs/heads/candidate`, each with its tests. Gate = full mix suite in `<durable-candidate>` compared against the known baseline failures. Pass means no new failure, not zero failures.

### Claude's Discretion
- Exact successor script names and layout in the 190 `scripts/` folder, how stubs are wired, how the comparison test drives the Elixir funnel (e.g. `mix run` in `<durable-candidate>`).
- Whether FIX-05 extracts a small shared git-env module or calls the existing one in `twin_producers.ex`.
- Wording of the refusal reasons, as long as they name the unreadable or malformed file in plain language and leak no paths or sensitive values.

### Deferred Ideas (OUT OF SCOPE)
- 184 GAP4-WR-01 (FIFO at `.git/info/attributes` hangs `probe_source/2`).
- Retained review findings (185 WR-03..05, 186 WR-02, 187 WR-03/04, 188 WR-03/05..07, doctor `Path.relative_to` fallbacks).
- Promoting the 190 successor scripts into permanent `script/` tooling.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FIX-01 | Privacy scan with no files in scope fails with a scope error | Section "FIX-01": exact gap in `scan-privacy-188.sh` (lines 28-41), 189 precedent for the empty-directory refusal, symlink handling recipe |
| FIX-02 | Every gate label has a failing self-test control | Section "FIX-02": the 30 labels, derivation command, the 8 labels with zero references plus 2 weak ones, stub wiring |
| FIX-03 | Run gate's shell git helper uses the funnel's pinned configuration | Section "FIX-03": exact funnel values, three vulnerable `g()` copies, verified misleading-config demonstration, comparison-test driver |
| FIX-04 | Registry timeout reported as timeout; stop_all never stops a live registry | Section "FIX-04": exact code, spec, caller, tests, `:sys.suspend` simulation, verdict design |
| FIX-05 | Nested host without `.git` never reports enclosing repo commit | Section "FIX-05": exact code, funnel, `stat_identity` precedent, macOS symlink trap |
| FIX-06 | Guard minimum equals real test-file count at landing | Section "FIX-06": pin location, measured 253, guard behaviour, how to measure |
| FIX-07 | Preflight refuses on unreadable Info.plist / malformed route_activation.json | Section "FIX-07": exact `observe/2` return paths, preflight code, test helpers |
</phase_requirements>

## Summary

All seven fixes are small and local. The code fixes touch four existing modules in `<durable-candidate>` (`twin_runtime.ex`, `verify_twin.ex`, `provenance.ex`, `physical_iphone_preflight.ex`) and one guard script; the script fixes are new files under the 190 `scripts/` folder. Every claim below about code was checked against files opened this session at HEAD `a53fbef`.

Four findings change how the planner should write tasks. (1) The caller at `verify_twin.ex:79` sits inside a `try ... after`, so it cannot change the return value; showing the timeout in the verdict needs a restructure, and an existing test ("a registry gone before the command's stop_all leaves a passing verdict unchanged") must keep passing for the `:registry_gone` case. (2) On macOS a naive "`--show-toplevel` equals `Path.expand(cwd)`" check fails for every legitimate repo in `System.tmp_dir!()` (`/var/folders/...` is a symlink to `/private/var/...`), so the existing "clean repository yields git- and its HEAD" test is the canary; the repo already has a symlink-proof precedent (`stat_identity/1` compare in `toplevel_refusal/2`). (3) A global `core.fileMode=false` does not fool the old `g()` unless the repo's local `core.fileMode` is unset (local config wins), so the FIX-03 comparison test must build its fixture that way and must include a negative control that runs the Phase 188 `g()` and shows it disagrees. (4) The real full-suite baseline at `a53fbef` is **1 failure**, `Phase180TwinFeasibilityTest` "G1 gate" (2622 tests, 78 excluded), not the example-host G2/G6 named in CONTEXT (those are in the example-host project, excluded from the root suite). A scratch copy made with `git archive` (no history) shows 7 failures that are copy artifacts; do not use that as a baseline.

**Primary recommendation:** Work in this order, one commit each in `<durable-candidate>`: FIX-07, FIX-05, FIX-04, then FIX-06 last (pin set from a separate `find test -name '*.exs' | wc -l` at that final commit). Build the three script successors in the 190 folder in parallel (they share no files with the code commits). Capture the baseline failure list in Wave 0 before any change.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Run-registry timeout/gone classification (FIX-04) | Elixir runtime (`TwinRuntime`) | Mix task (`VerifyTwin`) renders verdict | Runtime owns the registry; the task owns the 4-line verdict |
| Git environment pinning (FIX-03, FIX-05) | Elixir funnel (single source of truth) | Shell `g()` mirrors it, checked by comparison test | Two implementations must not drift (D-05) |
| Provenance commit read (FIX-05) | `Provenance` module | `verify_navigation_shell` task consumes | Nested-host rule is a property of the read |
| Origin refusal for unreadable inputs (FIX-07) | `PhysicalIphonePreflight` | `IOSHostOriginMode.observe/2` stays unchanged | Shared function keeps meaning (D-08) |
| Test-file count floor (FIX-06) | `script/check_absence_is_not_success.exs` pin | ExUnit test that runs the guard | Pin is data in the guard; a test already runs it |
| Privacy scan and gate self-tests (FIX-01/02) | POSIX sh successors in phase folder | none | One-time evidence tooling (D-01) |

## Standard Stack

No new external packages. Everything is stdlib plus tools already in use.

### Core
| Tool | Version (verified here) | Purpose | Why |
|------|-------------------------|---------|-----|
| Elixir / OTP | 1.19.5 / OTP 27 (`.tool-versions` `elixir 1.19.5-otp-27`) [VERIFIED: `elixir --version`, `.tool-versions:2`] | Code fixes and ExUnit tests | Project toolchain |
| ExUnit | bundled | Tests; `@tag :tmp_dir` available | Existing pattern |
| git | 2.41.0 [VERIFIED: `git --version`] | Funnel minimum is `@min_git_version {2, 41}` | The pins use `--attr-source`, so the local git is exactly at the minimum |
| POSIX `sh`, `jq` 1.7.1-apple, `shasum`, `mktemp` | system | Script successors | Same as the 188 scripts [VERIFIED: `command -v`] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| New module `Crosswake.ProofLane.GitPins` shared by funnel and Provenance | Make `TwinProducers` expose `@doc false git_env/0`, `git_pins/0` | Extraction keeps `Provenance` free of a dependency on the 1,800-line producers module and makes the shell comparison check read one small file. Cost: `TwinProducers` module attributes move (compile-time call). No test references `@git_env`/`@git_pins` today [VERIFIED: grep of `test/`, `lib/`, `script/`]. Recommended: extract. |

**Installation:** nothing to install. First test run in a fresh clone needs `mix deps.get` (network) because `<durable-candidate>` has no `deps/` or `_build/` [VERIFIED: `ls`]. Both directories are git-ignored [VERIFIED: `.gitignore` lines `/_build/`, `/deps/`], so creating them keeps `git status` clean.

## Package Legitimacy Audit

No external packages are installed in this phase. Packages removed due to SLOP: none. Packages flagged SUS: none.

## Architecture Patterns

### Data flow (FIX-04 verdict path)
```
VerifyTwin.execute
  -> TwinRuntime.prepare (starts Agent registry, holds origin listener)
  -> conduct(runtime, plan)  ----> writes receipt, builds {status, 4 lines}
  -> [now] after: TwinRuntime.stop_all(runtime)  (result discarded)
        stop_children -> tracked_children (Agent.get, 5 s default timeout)
              :gone -------> {:error, :registry_gone}
              timeout -----> {:error, :registry_timeout}   (new)
              ok ----------> terminate each child
        close origin listener   (always)
        Agent.stop(registry)    (NOT on :registry_timeout)
  -> [new] annotate({status, lines}, stop_result)
```

### Recommended file layout
```
<durable-candidate>/
  lib/crosswake/proof_lane/git_pins.ex            # new (FIX-05/03 shared source); optional per Discretion
  lib/crosswake/proof_lane/twin_producers.ex      # uses GitPins attrs
  lib/crosswake/proof_lane/provenance.ex          # FIX-05
  lib/crosswake/proof_lane/twin_runtime.ex        # FIX-04
  lib/mix/tasks/crosswake.proof_lane.verify_twin.ex
  lib/crosswake/proof_lane/physical_iphone_preflight.ex   # FIX-07
  script/check_absence_is_not_success.exs         # FIX-06 pin
phases/190-fix-warnings-before-landing/scripts/
  git-pinned-190.sh        # the one shared g() (sourced)
  scan-privacy-190.sh      # FIX-01
  run-once-05-190.sh       # copy of run-once-05.sh using the shared g() (never run in real mode)
  freeze-check-190.sh, make-identity-190.sh   # shared g()
  selftest-190.sh          # FIX-01/02 controls + label-coverage derivation
  gitpin-compare-190.sh    # FIX-03 comparison + drift check
```
Names are Discretion. Successors must not source or modify the 188 originals; verify the originals stay unchanged with `cd phases/188-freeze-and-twin-05 && shasum -a 256 -c 188-SCRIPTS.sha256` (all 10 listed files print `OK` today [VERIFIED: ran it]).

### Anti-Patterns to Avoid
- **Comparing `--show-toplevel` text to `Path.expand(cwd)`** on macOS: fails for real repos under `/var/folders` (see Pitfall 2).
- **Hand-kept label list in the new self-test:** the old `LABELS=` string at `selftest-188.sh:11` is exactly what D-04 forbids.
- **Deriving the guard pin from the guard's own glob:** violates 185 D-03.
- **`env VAR=val -u NAME git ...`:** `env` options must precede assignments (`env: -u: No such file or directory` reproduced here). The 188 `g()` has them in the right order; keep it.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Directory-identity compare | string-compare of resolved paths | `File.stat/1` `{major_device, inode}` as in `TwinProducers.stat_identity/1` (`twin_producers.ex:1422-1427`) | Symlink-proof; already the repo's chosen answer in `toplevel_refusal/2` (`:1138-1148`) |
| Git env/pins in `Provenance` | a second copy of the lists | one shared source (extracted module) | D-07 says reuse, not copy; copies are how the 188 `g()` drifted |
| Slow-process simulation | `Process.sleep` inside a custom server | `:sys.suspend(pid)` on the real Agent | Deterministic; no timing race |
| Label list for coverage | hand-kept string | `grep` of the gate source (command below) | D-04 |

## Runtime State Inventory

Not a rename/refactor/migration phase. Omitted.

## FIX-04: registry timeout (`twin_runtime.ex`)

**Current code** [VERIFIED: `lib/crosswake/proof_lane/twin_runtime.ex:222-266`], quoted verbatim:

```elixir
  @spec stop_children(t()) :: :ok | {:error, :child_still_alive | :registry_gone}
  def stop_children(%__MODULE__{registry: registry} = runtime) do
    case tracked_children(registry) do
      {:ok, children} ->
        results = Enum.map(children, &terminate(runtime, &1))
        if Enum.all?(results, &(&1 == :ok)), do: :ok, else: {:error, :child_still_alive}
      :gone ->
        {:error, :registry_gone}
    end
  end

  # Read inside try/catch rather than checking Process.alive? first, so a registry that
  # dies between the check and the read cannot raise. A call timeout is also reported as
  # gone, which is accepted.
  defp tracked_children(registry) do
    {:ok, Agent.get(registry, &Map.values(&1.children))}
  catch
    :exit, _ -> :gone
  end

  @spec stop_all(t()) :: :ok | {:error, :child_still_alive | :registry_gone}
  def stop_all(%__MODULE__{registry: registry} = runtime) do
    result = stop_children(runtime)
    if runtime.origin_listener, do: :gen_tcp.close(runtime.origin_listener)

    try do
      Agent.stop(registry)
    catch
      :exit, _ -> :ok
    end

    result
  end
```
(`stop_children`'s `@doc` and the `:gone` comment are elided here; keep them and update the comment, which currently says a timeout "is accepted" as gone.)

**Struct** [VERIFIED: `twin_runtime.ex:27-42`]: `defstruct [:run_id, :run_root, :database_path, :origin, :origin_port, :origin_listener, :candidate_path, :candidate_head, :candidate_tree, :resource_digests, :fixture_digests, :registry, :run_deadline_at]`. `@enforce_keys [:run_id, :run_root, :database_path, :origin, :origin_port, :registry]`.

**Exit shapes.** `Agent.get/3` on a slow server exits `{:timeout, {GenServer, :call, [pid, msg, 5000]}}`; on a dead pid `{:noproc, ...}`; on death mid-call `{reason, {GenServer, :call, ...}}`. Recommended implementation (a superset of D-06's three listed reasons, same intent, fail-closed as today):

```elixir
defp tracked_children(%{registry: registry} = runtime) do
  {:ok, Agent.get(registry, &Map.values(&1.children), registry_timeout_ms(runtime))}
catch
  :exit, {:timeout, _} -> :timeout
  :exit, _ -> :gone          # noproc, normal, shutdown, killed, crash: all "gone"
end
```
`stop_children` gains `:timeout -> {:error, :registry_timeout}` (children are NOT terminated: the registry still owns the only record of them). `stop_all` skips `Agent.stop/1` when `result == {:error, :registry_timeout}` but still closes the origin listener. Update both `@spec`s to `:ok | {:error, :child_still_alive | :registry_gone | :registry_timeout}`.

**Timeout seam for tests.** The default 5000 ms is real time, so a naive test takes 5 s. Add a struct field `:registry_timeout_ms` (default 5_000 via `registry_timeout_ms/1`) and thread an optional `:registry_timeout_ms` through `check/1` -> `commit/1` exactly like `run_deadline_ms` (`check` returns it in the `checked` map at `:70-77`; `commit` reads `checked.run_deadline_ms` at `:96`). Tests can also just do `%{runtime | registry_timeout_ms: 50}` on a prepared runtime. `@type checked` needs the new key.

**Simulating a slow registry** (deterministic, no sleep race): after `prepare`, `:sys.suspend(runtime.registry)`; with timeout 50 ms the call times out every time. Resume with `:sys.resume/1`. Clean up with `Process.exit(pid, :kill)` if a test fails while suspended (an `Agent.stop` on a suspended process blocks).

**Existing tests to extend** [VERIFIED: files opened]:
- `test/crosswake/proof_lane/twin_runtime_check_test.exs:260-317` (async: false): "stop_children reports registry_gone ...", "stop_all still closes the origin listener and returns registry_gone ...", "a tracked child whose registry is gone is reported by stop_all", helpers `record(ctx[, port])`, `free_port()`, `ctx.run_root`. These must stay green unchanged.
- `test/crosswake/proof_lane/twin_journey_test.exs:168-172` asserts by source regex that `TwinRuntime.stop_children(runtime)` is a bare statement (`~r/^\s+TwinRuntime\.stop_children\(runtime\)\s*$/m`, and `refute source =~ "= TwinRuntime.stop_children("`). Do not change the call site at `twin_journey.ex:745`. Also `:212` asserts `{:error, :registry_gone} = stop_children(dead)`.
- `test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs:322-338` "a registry gone before the command's stop_all leaves a passing verdict unchanged" expects exactly `["result: passed (exit 0)","first cause: none","report: " <> report,"next action: " <> _]` with exit 0. **This test fixes the `:registry_gone` behaviour: the caller must keep leaving that verdict unchanged.**

**New tests (TwinRuntime level, fast):**
1. Prepare, `start_child(runtime, :sleeper, %{path: sleep, args: ["30"]})` (as in `:292-307`), set `registry_timeout_ms: 50`, `:sys.suspend`, assert `{:error, :registry_timeout} = TwinRuntime.stop_children(runtime)`.
2. Same setup, assert `{:error, :registry_timeout} = TwinRuntime.stop_all(runtime)`, then `Process.alive?(registry)` is true, origin port is free again (`:gen_tcp.listen` succeeds, as at `:268-282`), `:sys.resume`, `Agent.get(registry, & &1.children)` still holds the child, and a second `stop_all` returns `:ok` and the child is gone (`TwinRuntime.alive?(os_pid)` false). Register an `on_exit` kill of the child's process group (pattern at `:296-299`).
3. Dead registry still `{:error, :registry_gone}` (existing tests cover it; add one assertion that it is not `:registry_timeout`).

**Caller / verdict (`verify_twin.ex:75-81`)** [VERIFIED]:
```elixir
      {:ok, runtime} ->
        try do
          conduct(runtime, plan)
        after
          TwinRuntime.stop_all(runtime)
        end
```
`after` discards the stop result and cannot change the return value. Recommended shape:

```elixir
{:ok, runtime} ->
  try do
    conduct(runtime, plan)
  catch
    kind, reason ->
      stacktrace = __STACKTRACE__
      TwinRuntime.stop_all(runtime)
      :erlang.raise(kind, reason, stacktrace)
  else
    result -> annotate_stop(result, TwinRuntime.stop_all(runtime))
  end
```
with `@doc false def annotate_stop(result, stop_result)` (public so a unit test can call it without a 5 s wait): `{:error, :registry_timeout}` changes the 4 lines; every other stop result returns `result` untouched (preserves the `:registry_gone` test). Recommended minimal change for a timeout: keep the exit code and the already-written receipt, replace `first cause: none` with `first cause: registry_timeout` (only when it is `none`), and append a fixed plain sentence to `next action:` saying a child process may still be running and must be checked. This is an Open Question (A1) because "shows the timeout in the verdict" does not say whether the exit status should change; the receipt is already written and immutable ("a first result is never overwritten"), so changing the exit code would contradict the receipt.

Because `finish/4` also calls `TwinRuntime.first_failure/1` (an `Agent.get` that waits the same 5 s on a suspended registry), do not try to cover the timeout through `execute/2` with a suspended registry; test `annotate_stop/2` directly plus the TwinRuntime tests above.

## FIX-05: provenance nested host (`provenance.ex`)

**Current `commit_ref/1`** [VERIFIED: `lib/crosswake/proof_lane/provenance.ex:57-88`]: runs `git rev-parse HEAD` then `git --no-optional-locks status --porcelain --untracked-files=no` with `cd: cwd`, `stderr_to_stdout: true`, `env: git_env()` where
```elixir
  defp git_env, do: [{"GIT_DIR", nil}, {"GIT_WORK_TREE", nil}, {"GIT_INDEX_FILE", nil}]
```
No pins, no `GIT_CONFIG_GLOBAL`, no toplevel check. A nested host with no `.git` makes `rev-parse HEAD` walk up and return the enclosing repo's HEAD.

**Funnel** [VERIFIED: `twin_producers.ex:745-798`; confirmed, the CONTEXT range 745-790 is right]:
```elixir
  @empty_tree "4b825dc642cb6eb9a060e54bf8d69288fbee4904"

  @git_scrub_names ~w(GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY
                      GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_COMMON_DIR GIT_NAMESPACE
                      GIT_CEILING_DIRECTORIES GIT_CONFIG GIT_CONFIG_COUNT GIT_CONFIG_PARAMETERS
                      GIT_PREFIX GIT_ATTR_SOURCE GIT_EXTERNAL_DIFF GIT_EXEC_PATH)

  @git_fixed_env %{
    "GIT_CONFIG_GLOBAL" => "/dev/null",
    "GIT_CONFIG_NOSYSTEM" => "1",
    "GIT_NO_REPLACE_OBJECTS" => "1",
    "GIT_ATTR_NOSYSTEM" => "1",
    "GIT_OPTIONAL_LOCKS" => "0",
    "GIT_TERMINAL_PROMPT" => "0",
    "LC_ALL" => "C"
  }

  @git_env @git_scrub_names |> Map.new(&{&1, nil}) |> Map.merge(@git_fixed_env) |> Enum.sort()

  @git_pins [
    "--no-optional-locks", "--no-replace-objects", "--attr-source=" <> @empty_tree,
    "-c", "core.fsmonitor=false", "-c", "core.filemode=true", "-c", "core.excludesFile=/dev/null",
    "-c", "core.attributesFile=/dev/null", "-c", "core.quotePath=false", "-c", "core.ignoreStat=false",
    "-c", "status.showUntrackedFiles=all", "-c", "core.autocrlf=false", "-c", "core.hooksPath=/dev/null",
    "-c", "core.ignorecase=false"
  ]
```
`git_invocation/5` (`:824-856`) additionally unsets **every inherited `GIT_*` name** (`for {"GIT_" <> _ = name, _} <- System.get_env()`) before applying `@git_env`, so a `GIT_TRACE` file is never written. A faithful reuse must do the same. `@min_git_version {2, 41}`; with the pins an older git rejects the argv and `commit_ref` would return `git-unknown` (fail-closed, but it would turn the existing positive test red on git < 2.41; local git is 2.41.0, exactly at the minimum).

**Recommended implementation.** Extract `Crosswake.ProofLane.GitPins` with `env/0` (the sorted list), `pins/0`, `empty_tree/0` and `spawn_env/0` (inherited `GIT_*` set to nil, merged with `env/0`). `TwinProducers` sets `@git_env GitPins.env()` / `@git_pins GitPins.pins()` (compile-time call is fine) so its behaviour is byte-identical. `Provenance.commit_ref/1`:
```elixir
args = fn rest -> GitPins.pins() ++ rest end
System.cmd(git, args.(["rev-parse", "--show-prefix"]), cd: cwd, stderr_to_stdout: true, env: GitPins.spawn_env())  # must print ""
```
Note the status call keeps `--untracked-files=no`; an explicit flag beats the pinned `status.showUntrackedFiles=all`, so the existing "an untracked file alone keeps the real commit" test still holds.

**Canonicalizing cwd vs toplevel (macOS).** Verified here: from a nested dir, `git rev-parse --show-toplevel` prints the physical path (`/private/...`) while `System.tmp_dir!()` returns `/var/folders/...` (`/tmp` is a symlink to `private/tmp` [VERIFIED: `ls -ld /tmp`]). Two safe options:
1. **Identity compare (matches the repo precedent and D-07's wording):** `File.stat(toplevel)` and `File.stat(cwd)` compare `{major_device, inode}` as in `stat_identity/1` (`twin_producers.ex:1422-1427`). Recommended.
2. `git rev-parse --show-prefix` is the empty string at the work-tree root and `host/` or `host/sub/` when nested [VERIFIED: ran it]; no path compare needed. Equivalent behaviour, fewer moving parts; acceptable if the planner prefers it, because D-07's intent (cwd must be the work-tree root) is identical.

**Fixture helpers.** `test/support/twin_git_fixtures.ex` builds a full twin candidate repo (heavy; `repo!/0` returns a runtime and identity). `provenance_test.exs` already has the light helpers `git!/2`, `clean_repo!/1` and `@tag`-free `setup` creating `dir` under `System.tmp_dir!()`; use those. New tests:
- nested: `clean_repo!(dir)`, `host = Path.join(dir, "examples/phoenix_host")`, `File.mkdir_p!(host)`, assert `Provenance.commit_ref(host) == "git-unknown"` while `Provenance.commit_ref(dir) == "git-" <> head` (the second assertion keeps the macOS canary).
- the existing "directory with no .git" test (`provenance_test.exs`) stays.
- a pin test: with a temp `HOME` whose `.gitconfig` sets something harmful (e.g. `[core] hooksPath`, or an `[alias]`-free setting), and `GIT_CONFIG_GLOBAL` unset, the answer is unchanged. Use `restore_env/1` (already defined) for env changes.

**Behaviour consequence to record:** `verify_navigation_shell.ex:104` calls `Provenance.read(File.cwd!())`. When that task runs from `examples/phoenix_host` inside the monorepo, `commit_ref` now becomes `git-unknown` instead of the monorepo HEAD. That is the requested behaviour, and the evidence validator accepts sentinels for advisory evidence only (provenance moduledoc), but any guide text or test asserting a real hex from a nested cwd must be checked (grep `commit_ref` in `test/` and `guides/` during planning).

## FIX-06: guard pin (`script/check_absence_is_not_success.exs`)

- Pin row [VERIFIED: `script/check_absence_is_not_success.exs:63-68`]: `{"test-files", "test/**/*.exs", 249},`. The comment above it (lines 58-62) says "Raising the pin is a Phase 188 freeze-checklist item"; reword to say the pin is raised at each landing from a separate measurement.
- The guard runs: `elixir script/check_absence_is_not_success.exs` (exit 0 today, 0.7 s) printing `[crosswake] OK: no mutation control asserts a change it never verified (scanned 253 test files, pin 249).` [VERIFIED: ran it in `<durable-candidate>`-equivalent export]. It is also exercised by `test/crosswake/proof/absence_is_not_success_test.exs` ("the repository itself ... is clean", runs the script against the repo root). It is not wired into a `.github` workflow or `mix.exs` alias [VERIFIED: grep]; CI coverage is through that ExUnit test.
- It fails when `length(actual) < min` ("below pinned minimum") and when the glob walk and an independent `fold` walk disagree (`derive_scope/3`, `:134-154`). It is a floor, so adding files never fails it; the pin only "equals the real count" at the commit where it is raised.
- **Measured count:** `find test -name '*.exs' | wc -l` = **253** at `a53fbef` in `<durable-candidate>` [VERIFIED]; the guard's own scan also reports 253, so `find` and the guard's glob agree today (they could diverge if a hidden directory appeared; `**` skips dotted dirs, `find` does not).
- **Files this phase adds:** plan for **0 new test files** by extending `twin_runtime_check_test.exs`, `crosswake_proof_lane_verify_twin_test.exs`, `provenance_test.exs` and `crosswake.proof_lane.physical_iphone_test.exs`. If the planner extracts `GitPins` and gives it its own test file, the count is 254. Either way the number written into the pin is whatever `find test -name '*.exs' | wc -l` prints at the last FIX commit; the task must run that command, paste its output, and then edit the pin, never compute it from the guard.
- Verification command pair for the last commit: `test "$(find test -name '*.exs' | wc -l | tr -d ' ')" -eq "$(sed -n 's/.*{"test-files", "test\/\*\*\/\*\.exs", \([0-9]*\)}.*/\1/p' script/check_absence_is_not_success.exs)"` and `elixir script/check_absence_is_not_success.exs`.

## FIX-07: preflight unreadable inputs (`physical_iphone_preflight.ex`)

**Current code** [VERIFIED: file read in full; the 186 review's line numbers 277-301 are stale, the function is now near the end of the file]:
```elixir
  defp origin_refusal_for(config, options) do
    declaration =
      Keyword.get_lazy(options, :ios_host, fn -> Application.get_env(:crosswake, :ios_host) end)

    root = Path.join(config.ios_shell_root, "crosswake_shell")

    case IOSHostOriginMode.observe(root, declaration) do
      :none -> nil
      _signal -> Generator.local_mode_refusal()
    end
  rescue
    _ -> Generator.local_mode_refusal()
  end
```
Module attrs: `@config_rule "PI-PREFLIGHT-CONFIG"`. `config/1` returns `{:config_error, :local_loopback}` when `origin_refusal_for` is truthy, which `check/1` maps to `{:blocked, "PI-PREFLIGHT-CONFIG"}`, and `readiness/1` marks the config entry blocked.

**`observe/2`** [VERIFIED: `lib/crosswake/shell/ios_host_origin_mode.ex:124-175`]: returns `:none`, `{:local, origin}` or `{:mismatch, origin_or_nil}`. `signal?/3` is true only for `plist in [:local_loopback, :conflict]`, an `{"http", _}` activation, a `{:local, _}` declaration, or `declared == :refused`.
- `observe_plist(root)` returns `:unreadable` for **any** failure of `ManagedOutputs.read_origin_plist(root)` (missing root, missing plist, plist is a directory, symlink, unsafe path, pending generation, > max bytes) and for a non-binary root. `:unreadable` is not a signal, so with a production or absent declaration `observe` returns `:none`. This is the WR-01 hole.
- `observe_activation(root)` returns `:none` for read failure, JSON parse failure, a missing/non-binary `"origin"` key, and an origin that fails `canonical_origin/1`. Absent, malformed and "valid JSON with no origin" are indistinguishable from outside.

**Which inputs yield which value** (so the preflight can classify without changing `observe/2`):
- shell root = `Path.join(config.ios_shell_root, "crosswake_shell")`; plist = `root/CrosswakeShell/Info.plist`; activation = `root/Fixtures/route_activation.json`.
- The existing "ready" tests use `ios_shell_root: "/tmp/crosswake/native/ios"`, which does not exist, so the root is absent and must **keep passing** (D-08 says refuse only when the shell root exists). This is also why `ready_options/0` in both test files needs no change.

**Recommended implementation (in the preflight only):** before calling `observe/2`:
1. `root_exists? = File.dir?(root)` (use `File.lstat` and treat a symlinked root as exists-and-unreadable if desired). If not, behave as today.
2. If it exists: `File.lstat(plist_path)` must be `{:ok, %{type: :regular}}` and `File.read/1` must succeed; otherwise refuse with a new plain reason such as "The generated iOS host files could not be read: CrosswakeShell/Info.plist is missing or unreadable, so the origin cannot be checked."
3. Activation: `File.lstat(activation_path)`; `{:error, :enoent}` -> fine (absent passes); present but not readable, or `Jason.decode/1` fails or is not a JSON object -> refuse with "Fixtures/route_activation.json exists but cannot be read or parsed."
4. Then run the existing `observe/2` branch.

Return strings are fixed text naming only the relative file (`CrosswakeShell/Info.plist`, `Fixtures/route_activation.json`), never an absolute path. The reasons flow to users through `origin_refusal/1` -> `physical_iphone.ex:205-217` (`blocked_result/2` copies a binary `cause` into the result), so the strings are user-visible; the existing mix-task test at `test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs:~225-262` asserts the loopback text is the cause for loopback cases and must keep passing (do not reuse `Generator.local_mode_refusal()` for the new reasons: it would claim "origin_mode :local_loopback", which is false here and is exactly the WR-02 mislabel).
Also reword the doc comment above `origin_refusal/1` (currently "any signal (or a failed observation) refuses rather than passes") to the exact new behaviour. The `rescue` branch (186 WR-02) stays out of scope (retained finding).

**Tests.** `physical_iphone_preflight_test.exs` has no shell-root fixtures; the mix-task test file already has `generate_shell/1`, `production_declaration/0`, `host_options/2`, `run_all_modes/2`, `assert_all_blocked_by_config/1`, `with_reports/2` (`:262-352`). Put the three new tests there (async: false, uses real `Mix.Tasks.Crosswake.Gen.Shell` output), each following the pattern at `:210-222`:
1. `generate_shell(production_declaration())`, then replace `.../CrosswakeShell/Info.plist` with a directory (`File.rm!` + `File.mkdir_p!`): all three modes blocked by `PI-PREFLIGHT-CONFIG`; assert the `cause` is the new text.
2. Overwrite `Fixtures/route_activation.json` with `"{not json"`: blocked.
3. Production shell + `File.rm!(route_activation.json)`: not blocked by config (passes, with `device_report` reached as in `:262`'s run).
Add a negative control for test 3's meaning: test 1 and 2 prove the check can fail, and the existing production-passes test proves it can pass.

## FIX-01/02/03: script successors

**Where the originals live** (read-only): `phases/188-freeze-and-twin-05/scripts/` (10 files, hashes in `188-SCRIPTS.sha256`, all OK).

### FIX-01 `scan-privacy-188.sh`
Gap [VERIFIED: lines 28-41, 91-95]: `n_ent` counts non-empty list lines; a directory entry runs `find "$line" -type f >> "$ENT"` and succeeds with no output; later `files=$i` can be 0 and the script prints `scan: files 0 / scan: hits 0` and exits 0. A symlink entry that points at a directory passes `[ -d ]` but `find "$link" -type f` does not descend (no `-H`), so it also yields nothing; symlinks inside a directory are skipped by `-type f`.
Successor recipe (D-03): per list line: `[ -L "$line" ]` -> `echo "scan: symlink refused"; exit 2`; directory: `find "$line" -type l` non-empty -> symlink refused (exit 2); `find "$line" -type f > $DF`; `[ -s "$DF" ] || { echo "scan: empty directory"; exit 2; }`; regular file as today; missing -> exit 2. After expansion `[ "$files" -gt 0 ] || { echo "scan: no files scanned"; exit 2; }`. The 189 precedent already does the per-directory zero check (`phases/189-inventory-and-backup/scripts/scan-privacy-189.sh:46-48`: `[ -s "$DF" ] || { echo "scan: empty directory"; exit 2; }`) and adds `--expect N`; the 190 successor does not need `--expect` but may borrow the wording. Keep the output free of paths (labels only). Reuse the existing pattern fragments so the script does not match itself.
Self-test cases (each runs the successor and checks exit code and label): empty directory -> 2; directory with only a symlink -> 2; list with a missing entry -> 2; empty list file -> 2; positive control: one file with no hits -> 0; file with a planted hit -> 1 (proves exit 1 path still works).

### FIX-02 `run-once-05.sh` labels and `selftest-188.sh`
**All labels the gate can emit** (30). Derive from source, do not hand-keep:
```
grep -E '^(chk|mixchk) ' run-once-05.sh | awk '{print $2}'      # 29 labels
grep -E '^[[:space:]]*rec [a-z_0-9]+ ' run-once-05.sh | awk '{print $2}'   # twin_preflight_allowed (not_run branch)
```
Union = 30 (`chk` 29 lines from `grep -cE '^(chk|mixchk) '` [VERIFIED: 29]; `twin_preflight_allowed` is both a `mixchk` and a `rec ... not_run`). The 188 self-test asserts the same 30 via `jq ... (.checks|length)==30` (C01) and a hand-kept `LABELS` string (`selftest-188.sh:11`).

Labels with **no reference at all** in controls C01-C31 [VERIFIED: grep of the control region]: `head_equals_record`, `mode_resolved`, `no_leftover_simulator`, `port_4790_free`, `root_outside_candidate`, `run_env_unsets_build_and_db`, `simulator_runtime_available`, `tree_equals_record`. Note `root_outside_candidate` is **not** in D-04's list but has no control either, so the derived-coverage check will (correctly) demand one. Also weakly covered: `example_host_warm_compile` (only ever seen as `not_run` in C28) and `shell_probe_clean_after_preflight` (C17 accepts `fail` or `not_run`; C22 only asserts `pass`). `history_manifest_87_ok` is covered by C20 (altered byte -> `shasum -c` non-zero) but not the 87-count branch (`l_history`: `[ "$hrc" -eq 0 ] && [ "$hok" -eq 87 ]`).

Mechanism for "every label has a failing control, derived from source": make the control helper record the label whenever it observes `status==fail` for it (e.g. extend `nogo`/`st_of` so a successful negative assertion appends the label to a `$COVERED` file), then at the end `comm -23 <(derive_labels | sort) <(sort -u $COVERED)` must be empty, else the self-test fails with the missing labels. Add an explicit meta-control: run the coverage check against a copy of the gate with one extra `chk bogus_label l_x` line and assert the self-test reports it missing (this is the "a new label without a control fails" requirement made testable).

Stub wiring (existing, in `write_stubs` `selftest-188.sh:49-95`): `bin/mix`, `bin/lsof` (currently `exit 1`, empty output), `bin/xcrun` (prints a runtime/devicetype JSON for `-j devicetypes runtimes`, nothing otherwise), prepended to `PATH`. Needed new behaviours, all just stub files read from `$S/stub/`:
- `port_4790_free`: `lsof` stub prints a listening line and exits 0 -> `l_port` sees non-empty -> fail.
- `no_leftover_simulator`: `xcrun` stub for `simctl list devices` prints a line containing `crosswake-phase180-` -> fail. Also the `xcrun` failure path (`|| return 1`).
- `simulator_runtime_available`: `xcrun` stub returns `{"runtimes":[],"devicetypes":[...]}` -> fail.
- `run_env_unsets_build_and_db`: `l_runenv` evaluates `MIX_BUILD_PATH=x DATABASE_PATH=y $RUNENV env`; control = make the gate's `RUNENV` not unset a variable. Simplest control: run the successor gate with a `T190_RUNENV` override seam, or a stub `env` earlier on `PATH` that re-adds `MIX_BUILD_PATH`. Planner decides; either must produce `run_env_unsets_build_and_db:fail`.
- `head_equals_record` / `tree_equals_record`: `jqedit "$S/runs/twin-05-candidate.json" '.expected_head="0000..."'` (note C12/C13 edit other fields and `mk_records` rewrites all) -> fail. Use `.expected_head` and `.expected_tree` respectively.
- `history_manifest_87_ok` 87-count branch: manifest with 86 entries, all `OK` (rewrite `history-184.before.sha256` with 86 lines) -> `hrc=0`, `hok=86` -> fail.
- `mode_resolved` real-mode branch: `l_mode` returns 1 in real mode when `command -v mix` is under `/private/tmp/*`, but `chk mode_resolved` is skipped in selftest (`[ "$MODE" = selftest ] && return 0`). Add a testable seam in the **successor** (not the original): e.g. `T190_FORCE_REAL_MODE_CHECK=1` makes `l_mode` evaluate the `command -v mix` case, then a control puts the stub `mix` (which lives under `<tmp>`) on `PATH` and expects `mode_resolved:fail`, plus a positive control with a mix outside `/private/tmp`. The seam must be inert unless the selftest root guard (`/private/tmp/crosswake-selftest-*`) passes, so it cannot weaken the real gate.
- `root_outside_candidate`: make `R` resolve inside `CAND` (e.g. root symlinked/located under `$S/cand`; careful with `l_rootpriv` which also checks) -> fail; assert only `root_outside_candidate` among labels depending on the order.
- `example_host_warm_compile`: add a stub switch (`stub/warm.rc`) keyed on `rel = cand/examples/phoenix_host` + `compile`; expect `fail` and downstream `not_run`.
- `shell_probe_clean_after_preflight`: a stub preflight that creates an untracked file in `cand` (preflight stub with `stub/preflight.dirty`) -> `fail` while `twin_preflight_allowed` is `pass`.
The successor selftest must point `SCRIPT` at the successor gate copy in the 190 folder (original points at `<tmp>/crosswake-phase180-run/run-once-05.sh`, a copied path `selftest-188.sh:7`), and its `guard()`/root rules (`/private/tmp/crosswake-selftest-188-01.*`) should use a 190-specific prefix so the two never collide. The successor gate must never be run in real mode (twin-05 sentinel exists; no twin run is allowed in this milestone).

### FIX-03 `g()` copies
Three copies are identical [VERIFIED]: `run-once-05.sh:80-82`, `freeze-check-188.sh:14-16`, `make-identity-188.sh:17-19`:
```sh
g() {
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u GIT_OBJECT_DIRECTORY -u GIT_ALTERNATE_OBJECT_DIRECTORIES -u GIT_COMMON_DIR -u GIT_NAMESPACE -u GIT_CEILING_DIRECTORIES -u GIT_CONFIG -u GIT_CONFIG_COUNT -u GIT_CONFIG_PARAMETERS -u GIT_PREFIX GIT_OPTIONAL_LOCKS=0 GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 LC_ALL=C git --no-optional-locks -c core.excludesFile=/dev/null -c core.quotePath=false -c core.fsmonitor=false -C "$CAND" "$@"
}
```
Missing versus the funnel: unset of `GIT_ATTR_SOURCE`, `GIT_EXTERNAL_DIFF`, `GIT_EXEC_PATH` (the old list also omits these three scrub names) and inherited `GIT_*` generally; `GIT_CONFIG_GLOBAL=/dev/null`; `GIT_NO_REPLACE_OBJECTS`, `GIT_ATTR_NOSYSTEM`; `--no-replace-objects`, `--attr-source=<empty tree>`; `core.filemode=true`, `core.attributesFile`, `core.ignoreStat=false`, `status.showUntrackedFiles=all`, `core.autocrlf=false`, `core.hooksPath=/dev/null`, `core.ignorecase=false`. (The funnel's scrub list has 15 names; the shell has 12.) A fourth, differently shaped copy `gc()` exists in `selftest-188.sh:23-25` (fixture builder, sets `GIT_CONFIG_GLOBAL=/dev/null` already); it builds fixtures and may stay different, but the selftest's *gate-facing* git must go through the shared helper.

**Shared helper** (`git-pinned-190.sh`, sourced by every successor): defines `g()` from one block of POSIX-sh variables holding exactly the names/values/pins above, and also unsets every inherited `GIT_*` name (loop over `env | sed -n 's/^\(GIT_[A-Za-z0-9_]*\)=.*/\1/p'`), mirroring `git_invocation/5`.

**Verified demonstration of a misleading config** (scratch repo, temp `HOME` with `~/.gitconfig` `[core] fileMode = false`, repo-local `core.filemode` **unset**, tracked file `chmod +x`): old `g()` status bytes = **0** (looks clean), pinned = **5** (` M f\0`). With the local `core.filemode=true` that `git init` writes by default, both print 5, so the fixture must `git config --local --unset core.filemode`. The other two candidate keys I tried (`core.autocrlf`, a global `core.attributesFile` with `f text eol=crlf`) did not differentiate in my quick run, so use `core.fileMode`. `status.showUntrackedFiles=no` and a global `excludesFile` (the examples in CONTEXT) do **not** fool the old `g()` (its `--untracked-files=all` flag and its `-c core.excludesFile=/dev/null` already neutralize them); use them only as extra non-differentiating cases.

**Comparison test (`gitpin-compare-190.sh`)**
1. `T=$(mktemp -d <tmp>/...)`, fixture repo via `git init`, commit, `git config --local --unset core.filemode`, `chmod +x` the tracked file; `$T/home/.gitconfig` with `[core] fileMode = false`.
2. Shell answer: `HOME=$T/home g status --porcelain=v1 -z --untracked-files=all | wc -c` using the **successor** `g()`, with `CAND=$T/repo`; expect 5.
3. Elixir answer: from a faithful working copy of the candidate with deps (see Environment), `HOME=$T/home mix run --no-start -e 'IO.inspect(Crosswake.ProofLane.TwinProducers.dirty_counts(System.get_env("P")))'` with `P=$T/repo`; expect `modified` >= 1 (the funnel's `probe_source/2` sums status-like findings; it refuses non-toplevel and bad config, and returns `nil` for `:unavailable`, so assert non-nil and `modified: 1`). Assert "shell reports dirty" and "Elixir reports dirty" agree; and with the repo made truly clean both report 0.
4. **Negative control (mandatory):** run the same check with the Phase 188 `g()` text (copied verbatim into the test as a string, or `sed -n` from the original) and assert it reports 0 (clean) while Elixir reports dirty, i.e. the comparison can fail. Without this the test passes vacuously when both sides ignore the config (the repo's recurring defect).
5. **Drift check (D-05 second check):** parse `lib/crosswake/proof_lane/twin_producers.ex` (or `git_pins.ex` if extracted) for the `@git_scrub_names ~w(...)` block, the `@git_fixed_env` map, and the `@git_pins` list, normalise, and compare to the helper's variables. Planner note: the funnel's pins appear as separate list elements (`"-c", "core.fsmonitor=false"`), so extract with `grep -o '"[^"]*"'` between the attribute lines; a control that edits one pin in a temp copy of the helper and expects the drift check to fail is required. If `GitPins` is extracted, parse that small file instead; it makes the drift check simpler.
**Driving Elixir from shell:** `mix run --no-start -e` is how `run-once-05.sh` already probes (`s_elixir`). It needs a built, dependency-complete working copy. Do not run it inside `<durable-candidate>` unless `MIX_BUILD_PATH`/`MIX_DEPS_PATH` point outside it (it has no `deps/` or `_build/`); the safest recipe, used for this research, is a throwaway export (`git archive HEAD | tar -x -C <tmp>/cand` or `git clone --no-hardlinks`), `mix deps.get`, then run there. Note a `git archive` export has no history and produces 7 spurious failures in the full suite; use `git clone` for any full-suite run.

## Baseline failures (FIX gate for D-10)

- **Measured here, faithful clone of `<durable-candidate>` at `a53fbef`, `mix test --no-color`:** `2622 tests, 1 failure (78 excluded)`, 406 s wall (130 s async, 276 s sync), exit 2. The one failure: `test G1 gate: validator rejects the host audio command as an unknown capability (Crosswake.Proof.Phase180TwinFeasibilityTest)` at `test/crosswake/proof/phase180_twin_feasibility_test.exs:30` (`assert [error] = errors` got `[]`) [VERIFIED: ran it]. This is the same cause family the milestone audit records (the router/validator now declares `host.study.audio.play`).
- **Recorded elsewhere (not run by the root suite):** example-host `phase180_twin_feasibility_test` G2/G6 (`milestones/v26.0-MILESTONE-AUDIT.md:36` "Excluded from the main suite"; `185-LOOP-MEASUREMENT.md:181`: 7 tests, 5 pass, G2 and G6 fail) and the Swift suite G4 (`v26.0-MILESTONE-AUDIT.md:42`, `debt-disposition.md:23`: 89 run, 1 failure). None of the seven FIXes touches Swift or the example host, so neither needs re-running for the D-10 gate; record that decision.
- **Discrepancy to flag (A2):** CONTEXT D-10 lists only G2/G6 and Swift G4 as the known baseline. The root suite also has the G1 failure. The gate must therefore compare against a **measured name list**, not the prose.
- **Mechanical gate:** Wave 0 runs the full suite once in `<durable-candidate>` (with `MIX_BUILD_PATH`/`MIX_DEPS_PATH` outside it or a faithful clone) and stores the sorted failing-test names: `grep -E '^[[:space:]]+[0-9]+\) test ' out | sed -E 's/^[[:space:]]+[0-9]+\) //' | sort > baseline-failures.txt` plus the totals line `^[0-9]+ tests, [0-9]+ failures`. After each FIX commit: same command; `comm -13 baseline-failures.txt after.txt` must be empty; and the test count must be >= baseline + the new tests (a drop means a test was deleted or silently excluded; the 78 excluded count must also stay 78). Do not use a pipe's exit status as the gate (`feedback_pipe_masks_exit_code`): capture `mix test` exit separately and treat "exit 2 with failure set equal to baseline" as pass.
- Run the suite serially per FIX only at the end of each commit's wave; per-FIX quick commands below give fast feedback.

## Common Pitfalls

### Pitfall 1: `after` cannot change the verdict
**What goes wrong:** Passing the `stop_all` result into the 4 lines while keeping `try ... after`. **Why:** `after` return is discarded. **Avoid:** `try ... catch ... else` (reraise with the saved stacktrace) as shown in FIX-04. **Signs:** the new timeout test passes at TwinRuntime level but the printed lines never mention it.

### Pitfall 2: macOS temp symlink breaks the toplevel compare
**What goes wrong:** `commit_ref` returns `git-unknown` for every real repo created under `System.tmp_dir!()`. **Why:** `System.tmp_dir!()` is `/var/folders/...`, git prints `/private/var/...`. **Avoid:** inode/device identity compare or `--show-prefix`. **Signs:** the existing "a clean repository yields git- and its HEAD" test fails on macOS only.

### Pitfall 3: a comparison test that cannot fail
**What goes wrong:** both `g()` and the funnel ignore the misleading config for unrelated reasons (explicit flags). **Avoid:** local key unset + global `core.fileMode=false`, plus the mandatory old-`g()` negative control.

### Pitfall 4: label coverage that counts mentions, not failures
**What goes wrong:** a label appears in a `nonpass` string as `not_run` and is counted as covered. **Avoid:** record coverage only when the label's status is `fail`.

### Pitfall 5: suspended registry makes unrelated calls wait too
`first_failure/1`, `record_failure/2`, `mark_exited/2` also call the registry (default 5 s each, rescued). A test that drives `execute/2` with a suspended registry will take 5+ s per call. Test `annotate_stop/2` and TwinRuntime directly.

### Pitfall 6: timeout leaves children running by design
After `{:error, :registry_timeout}` the registry and its children are alive and unreaped. The verdict wording must say a child process may still be running (D-06 chooses this over a false "stopped"). Tests must kill leftovers in `on_exit`.

### Pitfall 7: FIX-06 pin equals count only at the last commit
Adding any test file after the pin commit leaves pin < count (still green, but no longer "equal"). Raise the pin in the very last FIX commit and add no files after it; Phase 191 re-measures on the integration branch.

### Pitfall 8: preflight must still pass for a missing shell root
The ready fixtures use a non-existent `ios_shell_root`; the new "root exists" condition must be tested with `File.dir?` first or every ready test turns red.

## Code Examples

### FIX-04 simulating a slow registry
```elixir
# Source: OTP :sys docs; pattern verified against the registry at twin_runtime.ex:94
{:ok, runtime} = TwinRuntime.prepare(candidate: record(ctx), run_root: ctx.run_root)
runtime = %{runtime | registry_timeout_ms: 50}
:ok = :sys.suspend(runtime.registry)
on_exit(fn -> if Process.alive?(runtime.registry), do: Process.exit(runtime.registry, :kill) end)

assert {:error, :registry_timeout} = TwinRuntime.stop_all(runtime)
assert Process.alive?(runtime.registry)
:ok = :sys.resume(runtime.registry)
assert %{} = Agent.get(runtime.registry, & &1.children)
assert :ok = TwinRuntime.stop_all(runtime)
```

### FIX-05 identity compare
```elixir
# Source: mirrors twin_producers.ex:1138-1148 and :1422-1427
defp at_work_tree_root?(git, cwd) do
  with {top, 0} <- System.cmd(git, GitPins.pins() ++ ["rev-parse", "--show-toplevel"],
                     cd: cwd, stderr_to_stdout: true, env: GitPins.spawn_env()),
       top = String.trim_trailing(top, "\n"),
       {:ok, %{major_device: d, inode: i}} <- File.stat(top),
       {:ok, %{major_device: d2, inode: i2}} <- File.stat(cwd) do
    {d, i} == {d2, i2}
  else
    _ -> false
  end
end
```

### FIX-03 / FIX-02 label derivation
```sh
# Source: run-once-05.sh structure (verified); prints the 30 labels
{ grep -E '^(chk|mixchk) ' "$GATE" | awk '{print $2}'
  grep -E '^[[:space:]]*rec [a-z_0-9]+ ' "$GATE" | awk '{print $2}'; } | sort -u
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `g()` with 12 `-u` names and 3 `-c` pins | funnel with 15 scrub names, 7 fixed env vars, 14 pins, inherited `GIT_*` unset | Phase 183 preflight to 184 funnel | Shell helper has not followed |
| Hand-kept `LABELS` in selftest | label set derived from gate source | this phase | New label without control fails |
| `tracked_children` timeout read as gone | distinct `:registry_timeout` | this phase | No premature `Agent.stop` |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | On a registry timeout the verdict keeps its exit code and receipt; only `first cause` (when `none`) and `next action` change | FIX-04 | If the owner wants exit 2 on timeout, the planner must also decide how the already-written receipt and exit status relate; needs confirmation |
| A2 | CONTEXT's known-baseline wording (G2/G6, Swift G4) is incomplete; the root suite baseline is the single G1 failure measured here | Baseline | If the planner relies on the prose only, the first full run looks like a new failure |
| A3 | A catch-all `:exit, _ -> :gone` (superset of D-06's three reasons) is acceptable | FIX-04 | If D-06 must be literal, other exit reasons would crash `stop_all`; I recommend the superset because the alternative reintroduces an unhandled exit |
| A4 | `activation` JSON that parses but has no/invalid `"origin"` is treated as readable (passes), because D-08 says "cannot be read or parsed" | FIX-07 | If the owner wants refusal for a parseable file with no usable origin, add a branch; one-line change plus a test |
| A5 | Using inode/device identity (or `--show-prefix`) satisfies D-07's "equals the canonicalized cwd" | FIX-05 | Wording-level deviation; behaviour identical, noted for confirmation |
| A6 | `core.fileMode` is the best differentiating misleading key for FIX-03 (tested once on git 2.41.0; `autocrlf`/`attributesFile` attempts were inconclusive) | FIX-03 | If `Elixir dirty_counts` reports something different from the 5-byte shell answer for the fixture, adjust the key; the negative control exposes this immediately |
| A7 | Zero new test files are added (extend existing files); with `GitPins` having its own test file the pin would be 254 | FIX-06 | The measured number at the last commit is authoritative either way |

## Open Questions (RESOLVED)

1. **Verdict exit status on `:registry_timeout`.** What we know: receipt is write-once; the existing registry-gone test requires an unchanged verdict. What is unclear: whether a timeout after a passing run should still print `exit 0`. Recommendation: keep exit and receipt, change cause/next-action text (A1); confirm in plan-check.
   RESOLVED: adopted as A1 (orchestrator default, 2026-10-19) — exit code and write-once receipt unchanged; only first cause and next action change. Implemented in plan 190-07 Task 2.
2. **Whether the extracted module is worth a new test file.** Recommendation: extract `GitPins` but test it through `provenance_test.exs` and the existing probe tests; no new file, pin = 253.
   RESOLVED: `Crosswake.ProofLane.GitPins` is extracted with no new test file (tested via `provenance_test.exs` and probe tests), per plan 190-06; the FIX-06 pin is still taken from a separate `find` count at the last FIX commit (plan 190-09).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP | all code FIXes | yes | 1.19.5 / OTP 27 | none |
| git | funnel, comparison test | yes | 2.41.0 (exact minimum) | none; older git makes pinned calls fail |
| network (Hex) | `mix deps.get` in a fresh clone (`<durable-candidate>` has no `deps/`) | yes (worked here) | n/a | copy `deps/` from another checkout only if `mix.lock` matches (it did not for the recovery checkout: `lazy_html` lock mismatch) |
| jq, shasum, mktemp, lsof, xcrun | script successors / their stubs | yes (jq 1.7.1-apple) | system | stubs replace lsof/xcrun in tests |

**Missing with no fallback:** none. Full suite takes about 7 minutes.

## Validation Architecture

`workflow.nyquist_validation` is `true` in `.planning/config.json:12`.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.5) for FIX-04..07; POSIX sh self-test scripts for FIX-01..03 |
| Config file | `test/test_helper.exs`; excluded tags `requires_example_host`, `engine_present`, `collateral_binaries`, `advisory_only` (78 tests) |
| Quick run command | per-FIX list below (about 6 s each with warm build) |
| Full suite command | `mix test --no-color` in `<durable-candidate>` (2622 tests, ~7 min) with `MIX_BUILD_PATH`/`MIX_DEPS_PATH` outside the clone if it must stay untouched |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FIX-04 | slow registry -> `:registry_timeout`, registry alive after `stop_all`, retry reaps child | unit | `mix test test/crosswake/proof_lane/twin_runtime_check_test.exs test/crosswake/proof_lane/twin_journey_test.exs` | exists, extend |
| FIX-04 | dead registry still `:registry_gone`, passing verdict unchanged | unit | `mix test test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs` | exists, extend |
| FIX-05 | nested host without `.git` -> `git-unknown`; root still real HEAD; hostile global config ignored | unit | `mix test test/crosswake/proof_lane/provenance_test.exs test/crosswake/proof_lane/twin_source_probe_test.exs test/mix/tasks/crosswake_proof_lane_verify_navigation_shell_test.exs` | exists, extend |
| FIX-06 | pin equals `find` count; guard green | unit + script | `elixir script/check_absence_is_not_success.exs` and `mix test test/crosswake/proof/absence_is_not_success_test.exs` | exists |
| FIX-07 | Info.plist as directory blocked; malformed activation blocked; no activation + production passes | integration | `mix test test/crosswake/proof_lane/physical_iphone_preflight_test.exs test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs` | exists, extend |
| FIX-01 | empty dir / symlink-only dir / missing entry / empty list -> exit 2; clean -> 0; hit -> 1 | sh selftest | `sh <phase190>/scripts/selftest-190.sh` (scan section) | Wave 0 |
| FIX-02 | each derived label has a failing control; bogus label detected | sh selftest | `sh <phase190>/scripts/selftest-190.sh` | Wave 0 |
| FIX-03 | shell `g()` == Elixir funnel under hostile temp HOME; old `g()` differs; helper vs funnel source drift check | sh + mix run | `sh <phase190>/scripts/gitpin-compare-190.sh` | Wave 0 |
| All | originals unchanged | hash | `cd phases/188-freeze-and-twin-05 && shasum -a 256 -c 188-SCRIPTS.sha256` | exists |
| All | recovery checkout unchanged, no twin run | read-only git | `git --no-optional-locks status --porcelain` before/after in `<recovery-checkout>`; no `twin-06` root, no `*.started` | n/a |

### Negative controls (each must demonstrably fail)
- FIX-04: revert `:timeout` clause -> timeout test fails (reads `:registry_gone`); remove the `Agent.stop` guard -> "registry alive" assertion fails.
- FIX-05: restore the 3-name `git_env` -> nested test returns the enclosing HEAD and fails; naive string compare -> positive test fails on macOS.
- FIX-06: set the pin to 252 -> equality check fails; set it to 254 -> guard prints "below pinned minimum" and exits 1.
- FIX-07: revert the new branch -> the `eisdir` and malformed-JSON tests fail.
- FIX-01/02/03: each has its own planted-defect control as described (old `g()`, extra bogus label, edited pin in a helper copy).

### Sampling Rate
- Per task commit: that FIX's quick command plus `mix format --check-formatted` and `mix compile --warnings-as-errors` for touched Elixir files.
- Per wave merge: the quick commands of all merged FIXes.
- Phase gate: full suite compared to `baseline-failures.txt` (no new failure, same or higher test count, 78 excluded), originals hash check, recovery-checkout unchanged, and all three script self-tests green.

### Wave 0 Gaps
- [ ] `baseline-failures.txt` and totals from a faithful full run at `a53fbef` (expect exactly the G1 test).
- [ ] 190 `scripts/` folder with the shared `g()` helper and the three self-test scripts.
- [ ] Working copy with deps able to run `mix run --no-start -e` for the FIX-03 comparison.
- [ ] Pre-state record of `<recovery-checkout>` (`status`, `HEAD`, branch/stash/worktree counts) for the unchanged check.

## Security Domain

`security_enforcement` is not set to false in config (absent = enabled).

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication / V3 Session | no | none touched |
| V4 Access Control | no | none touched |
| V5 Input Validation | yes | NUL-byte refusal in git args (existing `nul?/1`), strict `File.lstat` type checks, JSON decode errors treated as refusal |
| V6 Cryptography | no | SHA-256 only through existing `shasum`/`:crypto` use |
| V12 Files | yes | refuse symlinks in the scan scope; `lstat` before read in the preflight; temp dirs via `mktemp -d`, `umask 077` |
| V7 Logging/Privacy | yes | outputs carry fixed labels and relative file names only; no absolute path, home directory, user name or token in logs, refusal reasons, or phase files (AGENTS.md sensitive-data rules) |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Hostile or ambient git config (`core.fsmonitor`, hooks, external diff) executing code or hiding changes | Tampering / EoP | the shared pinned env and `-c` pins, `GIT_CONFIG_GLOBAL=/dev/null` |
| Enclosing-repo commit reported as host provenance | Spoofing | work-tree-root identity check |
| Symlink swapped for a scanned directory | Tampering | refuse symlinks explicitly |
| Path disclosure in diagnostics | Information disclosure | fixed-text reasons, relative names only |
| False green from empty scope | Repudiation (silent) | exit-2 scope errors; coverage derived from source |

## Sources

### Primary (HIGH confidence, opened this session)
- `<durable-candidate>`: `lib/crosswake/proof_lane/twin_runtime.ex`, `twin_producers.ex` (745-900, 917-1086, 1138-1180, 1422-1427), `provenance.ex`, `physical_iphone_preflight.ex`, `lib/crosswake/shell/ios_host_origin_mode.ex` (124-175), `lib/crosswake/shell/managed_outputs.ex` (`read_origin_plist`, `safe_layout`, `safe_read`), `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex`, `crosswake.proof_lane.physical_iphone.ex` (199-218), `script/check_absence_is_not_success.exs`, the listed tests, `test/support/twin_git_fixtures.ex`, `.gitignore`, `.tool-versions`
- Phase 188 scripts (`scan-privacy-188.sh`, `run-once-05.sh`, `selftest-188.sh`, `freeze-check-188.sh`, `make-identity-188.sh`), Phase 189 `scan-privacy-189.sh` and `lib-189.sh`
- `186-REVIEW.md` WR-01, `188-REVIEW.md` WR-01/WR-08, `v26.0-MILESTONE-AUDIT.md`, `185-LOOP-MEASUREMENT.md`, `ROADMAP.md`, `REQUIREMENTS.md`, `190-CONTEXT.md`
- Commands run: full `mix test` in a faithful clone, `git --version`, `find test -name '*.exs' | wc -l`, guard run, sha256 check of 188 scripts, scratch-repo `g()` comparison

### Secondary / Tertiary
- None. No web sources were needed; OTP `:sys.suspend/1` behaviour is standard library knowledge [ASSUMED from training, but exercised by the pattern; the planner's first task should run the FIX-04 simulation once to confirm the 50 ms timeout fires].

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH, nothing new is added.
- Architecture / code facts: HIGH, all files opened; line numbers quoted from this session.
- Pitfalls: HIGH for 1, 2, 5, 8 (reproduced or read in source); MEDIUM for FIX-03's choice of differentiating key (A6).

**Research date:** 2026-10-19
**Valid until:** until HEAD of `<durable-candidate>` moves from `a53fbef` (re-check line numbers), otherwise 30 days.
