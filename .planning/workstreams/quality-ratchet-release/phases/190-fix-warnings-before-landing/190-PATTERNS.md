# Phase 190: Fix warnings before landing - Pattern Map

**Mapped:** 2026-10-19
**Files analyzed:** 14 (7 Elixir/guard files modified, 7 script/test files created or extended)
**Analogs found:** 14 / 14

Placeholders: `<durable-candidate>` (HEAD `a53fbef7`), `<recovery-checkout>`, `<phases>` = `.planning/workstreams/quality-ratchet-release/phases`, `<tmp>`. Line numbers for Elixir files are at `a53fbef7` in `<durable-candidate>`. Script analogs are tracked in the recovery checkout under `<phases>/188-freeze-and-twin-05/scripts/` and `<phases>/189-inventory-and-backup/scripts/` (read-only; 188 must stay byte-identical, verify with `shasum -a 256 -c 188-SCRIPTS.sha256`).

Tracked-source note: the 188/189 script paths sit in the planning tree (not a capability mirror). The `<durable-candidate>` files are tracked on `refs/heads/candidate`.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `<phases>/190-.../scripts/scan-privacy-190.sh` (FIX-01) | utility (scan) | batch / file-I/O | `189-.../scripts/scan-privacy-189.sh` (lines 40-57) + `188-.../scan-privacy-188.sh` | exact |
| `<phases>/190-.../scripts/selftest-190.sh` (FIX-01/02) | test | batch | `188-.../scripts/selftest-188.sh` | exact |
| `<phases>/190-.../scripts/run-once-05-190.sh` (FIX-02/03 gate copy, selftest-only) | utility (gate) | request-response | `188-.../scripts/run-once-05.sh` | exact |
| `<phases>/190-.../scripts/git-pinned-190.sh` (FIX-03 shared `g()`) | utility | transform | `g()` in `run-once-05.sh:80-82`; reference `twin_producers.ex:745-798` | role-match |
| `<phases>/190-.../scripts/freeze-check-190.sh`, `make-identity-190.sh` (FIX-03) | utility | batch | `188-.../freeze-check-188.sh:14-16`, `make-identity-188.sh:17-19` | exact |

> **Planning decision (2026-10-19):** `freeze-check-190.sh` and `make-identity-190.sh` were dropped and will not be written. The orchestrator decided that the four non-gate 188 `g()` copies (`freeze-check-188.sh`, `make-identity-188.sh`, `prepare-record.sh`, `refresh-handoffs-188.sh`) get no successor: they are one-time twin-05 records that nothing reruns, and AGENTS.md keeps one-time commands as evidence, not tooling. Plan 190-10 records one out-of-scope line for each in `188-REVIEW-DISPOSITION.md`; any future rerun must use `scripts/git-pinned-190.sh`.

| `<phases>/190-.../scripts/gitpin-compare-190.sh` (FIX-03) | test | request-response | `selftest-188.sh` (control style) + `run-once-05.sh` `s_elixir` probe | partial |
| `lib/crosswake/proof_lane/twin_runtime.ex` (FIX-04) | service | request-response | itself, lines 222-266 | exact |
| `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex` (FIX-04) | controller (mix task) | request-response | itself, lines 75-81 | exact |
| `lib/crosswake/proof_lane/git_pins.ex` (new, optional, FIX-05/03) | utility | transform | `twin_producers.ex:745-798` | exact (extraction) |
| `lib/crosswake/proof_lane/provenance.ex` (FIX-05) | service | request-response | `twin_producers.ex` `toplevel_refusal/2` (1138-1148) | role-match |
| `lib/crosswake/proof_lane/physical_iphone_preflight.ex` (FIX-07) | service | request-response | itself, `origin_refusal_for` (144-156) | exact |
| `script/check_absence_is_not_success.exs` (FIX-06) | config (pin) | batch | itself, `@scopes` | exact |
| Tests extended: `twin_runtime_check_test.exs`, `crosswake_proof_lane_verify_twin_test.exs`, `provenance_test.exs`, `crosswake.proof_lane.physical_iphone_test.exs` | test | request-response | same files | exact |

## Pattern Assignments

### FIX-01 `scan-privacy-190.sh` (utility, batch)

**Analog:** `189-inventory-and-backup/scripts/scan-privacy-189.sh:40-57` (already refuses empty directories) layered on `scan-privacy-188.sh` (the buggy original).

**Gap in 188** (`scan-privacy-188.sh:28-41`): `find "$line" -type f >> "$ENT"` succeeds with no output, and `n_ent` counts list lines, not files, so `files 0 / hits 0` exits 0.

**Directory expansion to copy** (189, lines 44-50):
```sh
  if [ -d "$line" ]; then
    DF="$SCR/dirfiles"
    find "$line" -type f > "$DF" 2>/dev/null || { echo "scan: directory unreadable"; exit 2; }
    [ -s "$DF" ] || { echo "scan: empty directory"; exit 2; }
    cat "$DF" >> "$ENT"
```
**Add for D-03** (not in 189): before the `-d` test, `[ -L "$line" ] && { echo "scan: symlink refused"; exit 2; }`; inside the directory branch, `find "$line" -type l` non-empty -> `echo "scan: symlink refused"; exit 2`; after the copy loop (188 line ~70 `files=$i`), `[ "$files" -gt 0 ] || { echo "scan: no files scanned"; exit 2; }`.

**Header/exit contract to keep** (188 lines 1-14): `set -u`, `umask 077`, `exit 0 = zero hits, 1 = hit, 2 = scope error`, scratch via `mktemp -d` + `trap 'rm -rf "$SCR"' EXIT`, patterns assembled from fragments (`"/Us""ers/..."`) so the file does not match itself. Output uses fixed labels only, never a path. Final lines to keep: `echo "scan: files $files"; echo "scan: hits $hits"; ... exit 1/0`.

**Self-test cases** (in `selftest-190.sh`): empty dir ->2, dir holding only a symlink ->2, list with missing entry ->2, empty list ->2, one clean file ->0 (positive control), planted hit ->1.

---

### FIX-02 `selftest-190.sh` + `run-once-05-190.sh` (test, batch)

**Analog:** `188-.../scripts/selftest-188.sh`, `run-once-05.sh`.

**Guard / throwaway-root pattern** (`selftest-188.sh:7-8, 30-35`): use a 190-specific prefix so runs never collide.
```sh
PREFIX=/private/tmp/crosswake-selftest-188-01      # -> crosswake-selftest-190-01
guard() {
  case "$S" in "$PREFIX".*) : ;; *) echo "selftest: guard failed"; exit 1 ;; esac
  case "$S" in "$HOME/projects/crosswake"*) echo "selftest: guard failed"; exit 1 ;; esac
  rp=$(cd "$S/runs" && pwd -P); cp=$(cd "$S/cand" && pwd -P)
  if [ "$rp" = "$REAL_RUNS" ] || [ "$cp" = "$REAL_CAND" ]; then echo "selftest: guard failed"; exit 1; fi
}
```
`SCRIPT` must point at the 190 gate copy, never `<tmp>/crosswake-phase180-run/run-once-05.sh` (line 7).

**Stub wiring to extend** (`selftest-188.sh:49-95`, `write_stubs`): stubs `bin/mix`, `bin/lsof`, `bin/xcrun` under `$S/bin`, prepended to `PATH`; `mix` stub uses `rcf name default` reading `$S/stub/<name>` for return codes (`outer_compile.rc`, `gen_shell.rc`, `preflight.rc`, `verify.rc`, `preflight.extra`). Current `lsof` stub is `exit 1` (empty) and `xcrun` prints only the runtimes JSON; new controls need a second mode keyed on a `$S/stub/` file:
- `port_4790_free`: lsof stub prints a LISTEN line, exit 0.
- `no_leftover_simulator`: xcrun `simctl list devices` prints a line with `crosswake-phase180-`.
- `simulator_runtime_available`: xcrun returns `{"runtimes":[],"devicetypes":[...]}`.
- `head_equals_record` / `tree_equals_record`: `jqedit "$S/runs/twin-05-candidate.json" '.expected_head="000..."'` / `.expected_tree` (see C12/C13 style, line 247-248).
- `history_manifest_87_ok`: manifest of 86 `OK` lines (C20 at line 279 only alters a byte).
- `run_env_unsets_build_and_db`, `mode_resolved` (real-mode branch, needs an env seam inert outside the selftest root guard), `root_outside_candidate`, `example_host_warm_compile`, `shell_probe_clean_after_preflight`: see RESEARCH FIX-02 for seams.

**Control helper pattern to copy** (`selftest-188.sh:155-162`, `c05`-`c20` e.g. 228, 245-249):
```sh
st_of() { jq -r --arg l "$1" '.checks[]|select(.label==$l)|.status' "$(gfile "${2:-1}")" 2>/dev/null; }
nogo() { ... [ "$(st_of "$1")" = fail ]; }
c10() { : > "$S/runs/twin-05.exit"; runit; nogo no_started_or_exit_sibling; }
```
Extend `nogo` to append the label to a `$COVERED` file only when status is `fail` (Pitfall 4).

**Label derivation (replaces the hand-kept `LABELS=` string at `selftest-188.sh:11`)** from gate source (`run-once-05.sh:243-276` holds the `chk`/`mixchk` lines):
```sh
{ grep -E '^(chk|mixchk) ' "$GATE" | awk '{print $2}'
  grep -E '^[[:space:]]*rec [a-z_0-9]+ ' "$GATE" | awk '{print $2}'; } | sort -u
```
Then `comm -23 derived covered` must be empty. Add a meta-control: gate copy plus an extra `chk bogus_label l_x` line must be reported missing. Note `root_outside_candidate` also has no control today.

---

### FIX-03 `git-pinned-190.sh`, `freeze-check-190.sh`, `make-identity-190.sh`, `gitpin-compare-190.sh`

**Analog (the thing being fixed):** identical `g()` in `run-once-05.sh:80-82`, `freeze-check-188.sh:14-16`, `make-identity-188.sh:17-19`:
```sh
g() {
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u GIT_OBJECT_DIRECTORY -u GIT_ALTERNATE_OBJECT_DIRECTORIES -u GIT_COMMON_DIR -u GIT_NAMESPACE -u GIT_CEILING_DIRECTORIES -u GIT_CONFIG -u GIT_CONFIG_COUNT -u GIT_CONFIG_PARAMETERS -u GIT_PREFIX GIT_OPTIONAL_LOCKS=0 GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 LC_ALL=C git --no-optional-locks -c core.excludesFile=/dev/null -c core.quotePath=false -c core.fsmonitor=false -C "$CAND" "$@"
}
```
Keep the `env -u ... VAR=val cmd` ordering (options before assignments). `gc()` in `selftest-188.sh:23-25` is a fixture builder and may stay different.

**Reference to mirror** (`<durable-candidate>/lib/crosswake/proof_lane/twin_producers.ex:745-798`):
```elixir
  @git_scrub_names ~w(GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY
                      GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_COMMON_DIR GIT_NAMESPACE
                      GIT_CEILING_DIRECTORIES GIT_CONFIG GIT_CONFIG_COUNT GIT_CONFIG_PARAMETERS
                      GIT_PREFIX GIT_ATTR_SOURCE GIT_EXTERNAL_DIFF GIT_EXEC_PATH)
  @git_fixed_env %{"GIT_CONFIG_GLOBAL" => "/dev/null", "GIT_CONFIG_NOSYSTEM" => "1",
    "GIT_NO_REPLACE_OBJECTS" => "1", "GIT_ATTR_NOSYSTEM" => "1", "GIT_OPTIONAL_LOCKS" => "0",
    "GIT_TERMINAL_PROMPT" => "0", "LC_ALL" => "C"}
  @git_pins ["--no-optional-locks", "--no-replace-objects", "--attr-source=" <> @empty_tree,
    "-c", "core.fsmonitor=false", "-c", "core.filemode=true", "-c", "core.excludesFile=/dev/null",
    "-c", "core.attributesFile=/dev/null", "-c", "core.quotePath=false", "-c", "core.ignoreStat=false",
    "-c", "status.showUntrackedFiles=all", "-c", "core.autocrlf=false", "-c", "core.hooksPath=/dev/null",
    "-c", "core.ignorecase=false"]
```
(`@empty_tree "4b825dc642cb6eb9a060e54bf8d69288fbee4904"`.) Also copy `git_invocation/5` (lines 824-856): it additionally unsets every inherited `GIT_*` name (`for {"GIT_" <> _ = name, _} <- System.get_env()`). In sh: loop over `env | sed -n 's/^\(GIT_[A-Za-z0-9_]*\)=.*/\1/p'` and add `-u` for each.

**Comparison test (`gitpin-compare-190.sh`):** fixture repo with `git config --local --unset core.filemode`, a tracked file `chmod +x`, temp `HOME/.gitconfig` with `[core] fileMode = false`. Old `g()` reports 0 bytes of porcelain; pinned reports 5. Elixir side: `mix run --no-start -e` in a throwaway clone with deps (pattern: `s_elixir` in `run-once-05.sh`); do NOT run in `<durable-candidate>` unless `MIX_BUILD_PATH`/`MIX_DEPS_PATH` point outside it. Mandatory negative control: run with the verbatim 188 `g()` text and assert it disagrees. Drift check: parse the three attribute blocks (or `git_pins.ex` if extracted) and compare with the helper variables; control edits one pin in a temp copy of the helper and expects failure.

---

### `lib/crosswake/proof_lane/twin_runtime.ex` (service, request-response) FIX-04

**Analog:** itself. Current code, lines 222-266:
```elixir
  @spec stop_children(t()) :: :ok | {:error, :child_still_alive | :registry_gone}
  def stop_children(%__MODULE__{registry: registry} = runtime) do
    case tracked_children(registry) do
      {:ok, children} -> ...
      :gone -> {:error, :registry_gone}
    end
  end

  defp tracked_children(registry) do
    {:ok, Agent.get(registry, &Map.values(&1.children))}
  catch
    :exit, _ -> :gone
  end

  @spec stop_all(t()) :: :ok | {:error, :child_still_alive | :registry_gone}
  def stop_all(%__MODULE__{registry: registry} = runtime) do
    result = stop_children(runtime)
    if runtime.origin_listener, do: :gen_tcp.close(runtime.origin_listener)
    try do Agent.stop(registry) catch :exit, _ -> :ok end
    result
  end
```
**Change:** add `:exit, {:timeout, _} -> :timeout` before the catch-all `:gone`; `stop_children` maps `:timeout` to `{:error, :registry_timeout}` without terminating children; `stop_all` skips `Agent.stop/1` when `result == {:error, :registry_timeout}` (still closes the origin listener); both `@spec`s gain `:registry_timeout`; fix the comment that says a timeout "is accepted" as gone. Optional test seam: struct field `:registry_timeout_ms` (default 5_000) threaded like `run_deadline_ms` through `check/1`/`commit/1`.

**Test analog** (`twin_runtime_check_test.exs:260-317`, async false): copy the shape of "stop_all still closes the origin listener and returns registry_gone" (free_port, `:gen_tcp.listen(port, ip: {127,0,0,1}, reuseaddr: false, active: false)` before/after) and the child-kill `on_exit`:
```elixir
{:ok, child} = TwinRuntime.start_child(runtime, :orphan, %{path: sleep, args: ["30"]})
on_exit(fn -> System.cmd("kill", ["-s", "KILL", "--", "-" <> Integer.to_string(child.os_pid)], stderr_to_stdout: true) end)
```
Slow registry via `:sys.suspend(runtime.registry)` plus a 50 ms timeout; assert `{:error, :registry_timeout}`, registry still alive, port freed, then `:sys.resume` and a second `stop_all` returns `:ok` with the child gone. Existing registry_gone tests must stay green. Constraint: `twin_journey_test.exs:168-172` regex-asserts the call site `TwinRuntime.stop_children(runtime)` in `twin_journey.ex:745` is a bare statement; do not touch it.

---

### `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex` (mix task) FIX-04

**Analog:** itself, lines 75-81:
```elixir
      {:ok, runtime} ->
        try do
          conduct(runtime, plan)
        after
          TwinRuntime.stop_all(runtime)
        end
```
`after` discards the stop result and cannot change the verdict. Use `try ... catch kind, reason -> stop_all; :erlang.raise(kind, reason, __STACKTRACE__) else result -> annotate_stop(result, TwinRuntime.stop_all(runtime)) end` with a public `@doc false annotate_stop/2` so it can be unit-tested without a 5 s wait. Only `{:error, :registry_timeout}` changes the four result lines (cause `none` -> `registry_timeout`, extra next-action sentence); every other stop result returns `result` unchanged.

**Test that must stay green** (`crosswake_proof_lane_verify_twin_test.exs:322-338`):
```elixir
assert {0, lines} = VerifyTwin.execute(args(ctx, record(ctx)), producers: gone)
assert ["result: passed (exit 0)", "first cause: none", "report: " <> report, "next action: " <> _] = lines
```
Open question A1: exit code on timeout (research recommends unchanged, receipt is write-once). Confirm in plan-check.

---

### `lib/crosswake/proof_lane/provenance.ex` (service) FIX-05

**Analog:** `twin_producers.ex` `toplevel_refusal/2` (1138-1148) and `stat_identity/1` (1422-1427).

**Current** (`provenance.ex:58-90`): two `System.cmd(git, [...], cd: cwd, stderr_to_stdout: true, env: git_env())` calls (`rev-parse HEAD`; `--no-optional-locks status --porcelain --untracked-files=no`) inside a `with`, `rescue _ in [ErlangError, File.Error] -> "git-unknown"`, and:
```elixir
  defp git_env, do: [{"GIT_DIR", nil}, {"GIT_WORK_TREE", nil}, {"GIT_INDEX_FILE", nil}]
```
**Identity compare to copy** (`twin_producers.ex:1138-1148`):
```elixir
    with {out, 0} <- run_git(path, ["rev-parse", "--show-toplevel"], opts),
         top = String.replace_suffix(out, "\n", ""),
         true <- top != "",
         {:ok, top_id} <- identity_of(top),
         {:ok, path_id} <- identity_of(path) do
      if top_id == path_id, do: :ok, else: {:refused, :not_toplevel}
    else
      _ -> :unavailable
    end
```
and `stat_identity/1`: `File.stat(path)` -> `{major_device, inode}`. Do NOT string-compare to `Path.expand(cwd)` (macOS `/var` vs `/private/var` symlink would break the existing "clean repository" test). Alternative: `git rev-parse --show-prefix` must print empty.

**Env/pins:** extract `Crosswake.ProofLane.GitPins` (`env/0`, `pins/0`, `empty_tree/0`, `spawn_env/0` = inherited `GIT_*` unset merged with `env/0`), set `@git_env GitPins.env()` in `TwinProducers`, and use `GitPins.pins() ++ args` and `env: GitPins.spawn_env()` in `commit_ref/1`. Keep `--untracked-files=no` on the status call (explicit flag beats the pinned `status.showUntrackedFiles=all`). Requires git >= 2.41 (local is exactly 2.41.0).

**Test analog** (`provenance_test.exs`): setup creates `dir` under `System.tmp_dir!()`; helpers `git!/2`, `clean_repo!/1` (returns HEAD hex), `restore_env/1`.
```elixir
  test "a directory with no .git yields git-unknown", %{dir: dir} do
    refute File.exists?(Path.join(dir, ".git"))
    assert Provenance.commit_ref(dir) == "git-unknown"
```
New test: `head = clean_repo!(dir); host = Path.join(dir, "examples/phoenix_host"); File.mkdir_p!(host)`; assert `commit_ref(host) == "git-unknown"` and `commit_ref(dir) == "git-" <> head` (macOS canary). Add a hostile-`HOME`/`.gitconfig` pin test using `restore_env/1` (pattern at test "an inherited GIT_DIR does not redirect..." line 106). Check `verify_navigation_shell.ex:104` (`Provenance.read(File.cwd!())`) and grep `commit_ref` in `test/` and `guides/` for nested-cwd assertions.

---

### `lib/crosswake/proof_lane/physical_iphone_preflight.ex` (service) FIX-07

**Analog:** itself, lines 117-156:
```elixir
  defp config(options) do
    case Config.normalize(Keyword.get(options, :config)) do
      {:ok, config} ->
        if origin_refusal_for(config, options),
          do: {:config_error, :local_loopback},
          else: {:ok, config}
      {:error, _} -> {:config_error, :invalid}
    end
  end

  @doc false
  # Returns the generator's local-mode refusal text when ... any signal (or a failed observation)
  # refuses rather than passes.
  @spec origin_refusal(keyword()) :: String.t() | nil
  ...
  defp origin_refusal_for(config, options) do
    declaration = Keyword.get_lazy(options, :ios_host, fn -> Application.get_env(:crosswake, :ios_host) end)
    root = Path.join(config.ios_shell_root, "crosswake_shell")
    case IOSHostOriginMode.observe(root, declaration) do
      :none -> nil
      _signal -> Generator.local_mode_refusal()
    end
  rescue
    _ -> Generator.local_mode_refusal()
  end
```
Rule: `@config_rule "PI-PREFLIGHT-CONFIG"` (line 24), mapped at line 65. The return string flows to users via `physical_iphone.ex:205-217`. **Change:** before `observe/2`, if `File.dir?(root)` (nonexistent root must keep passing; ready fixtures use a missing `ios_shell_root`), require `File.lstat(root/CrosswakeShell/Info.plist)` to be `:regular` and readable; `Fixtures/route_activation.json` absent (`:enoent`) passes, present-but-unreadable or non-JSON-object refuses. Use fixed reason text naming only relative file names, not `Generator.local_mode_refusal()` (false claim, WR-02 mislabel). `observe/2` (`ios_host_origin_mode.ex:124-175`) stays unchanged. Reword the doc comment. Leave the `rescue` branch alone.

**Test analog** (`test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs:210-227, 281-352`): reuse `generate_shell/1`, `production_declaration/0`, `host_options/2`, `run_all_modes/2`, `assert_all_blocked_by_config/1`:
```elixir
    project = generate_shell(local_declaration())
    on_exit(fn -> File.rm_rf!(project) end)
    results = run_all_modes(host_options(project, production_declaration()), parent)
    assert Enum.map(results, &elem(&1, 0)) == [:preflight_only, :readiness, :run]
    assert_all_blocked_by_config(results)
    refute_received :device_report_called
```
New tests: (1) `generate_shell(production_declaration())`, replace `native/ios/crosswake_shell/CrosswakeShell/Info.plist` with a directory -> blocked; (2) overwrite `Fixtures/route_activation.json` with `"{not json"` -> blocked; (3) delete `route_activation.json` under a production plist -> not blocked by config. The existing loopback-cause test at line 229 must keep passing.

---

### `script/check_absence_is_not_success.exs` (config pin) FIX-06

**Analog:** itself, lines 58-68:
```elixir
  # ... Raising the pin is a Phase 188 freeze-checklist item.
  @scopes [
    {"test-files", "test/**/*.exs", 249},
```
Raise 249 only in the last FIX commit, to the output of a separate `find test -name '*.exs' | wc -l` (253 at `a53fbef`, plus any added test files; research plans 0 new files, 254 if `GitPins` gets its own). Reword the comment. Verification pair: compare the `find` count to the pin extracted by `sed`, and run `elixir script/check_absence_is_not_success.exs` (prints `scanned N test files, pin M`); the ExUnit wrapper is `test/crosswake/proof/absence_is_not_success_test.exs` ("is clean" test, `@repo_root` + `run(@repo_root)`). Add no test files after the pin commit.

## Shared Patterns

### Absence must not score as success (all script and test work)
**Source:** `AGENTS.md`, `test/crosswake/proof/absence_is_not_success_test.exs` moduledoc
Every new check ships a negative control that asserts the specific label or rule id, not just a non-zero exit. Never gate on a pipe's exit status (`feedback_pipe_masks_exit_code`).

### Pinned git environment (FIX-03, FIX-05)
**Source:** `twin_producers.ex:745-798, 824-856`
One definition (`GitPins` or the existing attributes); shell helper and `Provenance` follow it; a drift check or shared module prevents copies diverging.

### Placeholder discipline / privacy
**Source:** `scan-privacy-189.sh`, Phase 189 context
Outputs use fixed labels and relative names only; no absolute paths, home dirs, user names, tokens in script output, refusal text, or PATTERNS/plan files. Scratch via `mktemp -d` and `umask 077`.

### D-10 gate (code FIXes)
One commit per FIX in `<durable-candidate>`. Full `mix test --no-color` compared to a measured `baseline-failures.txt` (research measured exactly one failure, `Phase180TwinFeasibilityTest` "G1 gate", 2622 tests, 78 excluded; CONTEXT's G2/G6 and Swift G4 are outside the root suite). Pass = no new failure name and test count not below baseline plus new tests. Per-FIX: `mix format --check-formatted`, `mix compile --warnings-as-errors`. `mix deps.get` needed in a fresh clone; use a `git clone` (not `git archive`, which gives 7 spurious failures).

### Recommended order
FIX-07, FIX-05, FIX-04, then FIX-06 last. Script successors (FIX-01..03) are independent and parallel.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `gitpin-compare-190.sh` comparison half | test | cross-language compare | No existing test drives the Elixir funnel from shell and compares outputs; combine `selftest-188.sh` control style with the `s_elixir` probe in `run-once-05.sh`. |
| Label-coverage derivation (`comm -23` over derived vs covered) | test | batch | The 188 self-test uses a hand-kept list; the derivation command and `$COVERED` mechanism come from RESEARCH, not an existing file. |
| Symlink refusal in the scan | utility | file-I/O | Neither 188 nor 189 scan handles symlinks; write new per D-03. |

## Metadata

**Analog search scope:** `<durable-candidate>` `lib/crosswake/proof_lane/`, `lib/mix/tasks/`, `test/crosswake/proof_lane/`, `test/mix/tasks/`, `script/`; recovery checkout phases 188 and 189 `scripts/`.
**Files scanned:** about 20 (excerpts taken from 14).
**Pattern extraction date:** 2026-10-19
