# Phase 185: Checks that cannot pass empty - Pattern Map

**Mapped:** 2026-10-16
**Candidate:** `/private/tmp/crosswake-phase180-impl` @ `b898e110` (all paths below are relative to it; all analogs verified git-tracked)
**Files analyzed:** 20 (see classification)
**Analogs found:** 18 exact/role-match / 20 (2 partial/none)

## File Classification

| File (new/modified) | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `script/check_absence_is_not_success.exs` (mod) | script / checker | batch (file scan) | `script/check_exunit_ownership.exs:18-28` (floor) + `scripts/ci_monitor.cjs:310-321` (semantics) | role-match |
| `test/crosswake/proof/absence_is_not_success_test.exs` (mod) | test (subprocess self-test) | request-response | itself, lines 14-60 (`run/1`, `@tag :tmp_dir`) | exact |
| `.planning/seeds/SEED-023-*.md` (planning checkout, note only) | doc | n/a | n/a | none needed |
| `lib/crosswake/proof_lane/twin_runtime.ex` (mod) | service | event-driven (registry/Agent) | `lib/crosswake/proof_lane/twin_fault_boundary.ex:94-100` (`catch :exit`) | role-match |
| `lib/crosswake/proof_lane/twin_producers.ex` `lock_digests/2` ~1469, observe ~1598-1639 (mod) | service | transform | itself (`@lock_rels` 619) | exact |
| `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex` `lock_digests/1` 226 (mod) | mix task | request-response | `twin_producers.ex:1469` | role-match |
| `test/crosswake/proof_lane/twin_runtime_check_test.exs` (mod) | test | event-driven | same file :118-163 | exact |
| `test/crosswake/proof_lane/twin_producers_test.exs` (mod) | test | request-response | same file :364-370, `test/support/twin_git_fixtures.ex` | exact |
| `test/crosswake/proof_lane/twin_journey_test.exs` (mod) | test (source pin) | file-I/O | same file :154-160 | exact |
| `test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs` (mod) | test | request-response | same file :20-35 setup, :399-440 producers | exact |
| `test/crosswake/proof_lane/twin_receipt_test.exs` :110, :289 (mod) | test | transform | same file :280-292 | exact |
| `test/crosswake/doctor/doctor_origin_mode_test.exs` :360 (mod) | test | transform | `twin_producers_test.exs:364-370` (floor idiom) | role-match |
| `test/crosswake/proof/phase64_runtime_line_policy_test.exs` :416, :460 (mod) | test | transform | same file :190, :754 (`assert length(x) > 0`) | exact |
| `test/mix/tasks/crosswake_gen_shell_origin_mode_test.exs` :99, :336 (mod) | test | transform | same | role-match |
| `examples/phoenix_host/test/crosswake_example/phase180_twin_feasibility_test.exs` :47 (mod) | test | transform | same file :38-58 gate/control | exact |
| `185-LOOP-MEASUREMENT.md` + scanner + scan output (phase dir) | evidence / one-off script | batch | `script/inventory_collection_assertions.exs` (AST scan; read-only reuse of idea) | partial |
| `script/collection_assertion_ledger.json` (regenerate, display-only diff) | data | batch | `inventory_collection_assertions.exs --emit-snapshot/--check` | exact |
| `/private/tmp/crosswake-phase180-run/mutate-185.sh`, `mutation-185.log` (evidence) | harness | batch | `/private/tmp/crosswake-phase180-run/mutate-184-13.sh` | exact |

## Pattern Assignments

### `script/check_absence_is_not_success.exs` (checker, batch)

**Floor analog:** `script/check_exunit_ownership.exs:18-28`
```elixir
paths = root |> Path.join("test/**/*_test.exs") |> Path.wildcard() |> Enum.sort()
if paths == [] do
  fail([diagnostic("missing-test-tree", "test/**/*_test.exs",
        "no intended ExUnit files were found", "restore the test tree before evaluating execution ownership")])
else ...
```
**Semantics to copy** (`scripts/ci_monitor.cjs:310-321`, reasons verbatim): `expected scope is empty`, `actual scope is a proper subset of expected scope`. Elixir copy sketch is in RESEARCH Pattern 1 (`assert_full_scope/2` with `MapSet`; note the vacuous `Enum.all?` on empty `actual` is intentional, comment it).

**Entry point to replace** (end of file; today unrecognised args fall to cwd):
```elixir
root = case System.argv() do
  ["--root", path | _] -> path
  _ -> File.cwd!()
end
System.halt(Crosswake.AbsenceIsNotSuccess.run(root))
```
New: `OptionParser.parse(argv, strict: [root: :string, min_test_files: :integer])`; any invalid/rest -> exit 2; `File.exists?`/`File.dir?` -> exit 2 with `[crosswake] FAIL: root does not exist: <Path.expand>`; scope fail -> exit 1 and skip content checks.

**Walk gotchas (verified in RESEARCH):** `expected` for `test/**/*.exs` = `:filelib.fold_files(~c"root/test", ~c".*\\.exs$", true, ..., [])` (charlists; includes dot-dirs; excludes directories). For depth-1 `todos/*.md`, `seeds/*.md` use `File.ls` + `File.regular?`, NOT a recursive walk (GSD moves closed todos to `todos/pending|completed/`). `deferred-items.md`: recursive walk with basename equality. Keep OK sentences verbatim (grepped at test :25-26), append counts before the final period.

**Anti-pattern:** no `assert Enum.all?(`/`Enum.any?(` in added test lines (Phase 184 gate + ledger).

### `test/crosswake/proof/absence_is_not_success_test.exs` (subprocess self-test)

**Pattern to keep** (lines 14-27): `use ExUnit.Case, async: true`; `@repo_root Path.expand("../../..", __DIR__)`; `@script Path.join(@repo_root, "script/check_absence_is_not_success.exs")`; `@tag :tmp_dir`; `run/1` = `System.cmd("elixir", [@script, "--root", Path.expand(root)], stderr_to_stdout: true, cd: @repo_root)` (the `cd:` supplies `.tool-versions` to the asdf shim; without it exit 126).
```elixir
@tag :tmp_dir
test "...", %{tmp_dir: tmp} do
  write_test!(tmp, """ ... """)
  {output, code} = run(tmp)
  assert code == 1
  assert output =~ "absence.mutation_control_asserts_change"   # assert the specific id, not just nonzero
end
```
New: `baseline!(tmp)` (1 test file, 1 todo with a different name than `TODO-999-sample.md`, 1 seed, 1 `deferred-items.md`) and `run/2` passing `--min-test-files 1`; repo-itself test stays flagless. Each red case = one change from baseline; assert exit code and `scope <label>` text. Test names include scope + floor type.

### `lib/crosswake/proof_lane/twin_runtime.ex` (service, Agent registry)

**Current to replace** (:227-243): `if Process.alive?(registry), do: Agent.get(...), else: []` then `Enum.all?([])` -> `:ok`.

**Analog for catch idiom:** `lib/crosswake/proof_lane/twin_fault_boundary.ex:94-100`
```elixir
def stop(pid) do
  if Process.alive?(pid), do: GenServer.stop(pid, :normal, 5_000)
  :ok
catch
  :exit, _ -> :ok
end
```
Apply as `defp tracked_children(registry)` returning `{:ok, list}` / `:gone` (full sketch in RESEARCH "Recommended shape"). Same `catch :exit, _` for `first_failure/1` (-> nil), `record_failure/2` (-> :ok), `mark_exited/2`, and `Agent.stop` inside `stop_all/1`. `stop_all` always `:gen_tcp.close(origin_listener)` first, returns the registry error last. Update both `@spec`s.

### `twin_producers.ex` lock sites and `verify_twin.ex:226`

**Source gate, current** (:1469-1479): `for rel <- @lock_rels, match?({:ok, _}, File.stat(...)), do: digest.(...)`, blocks only on `results == []`. Fix: drop the stat filter; `{:ok, digests}` only if every digest is `{:ok, _}` else `{:blocked, :identity_unknown}`.

**Freeze side, current** (`verify_twin.ex:226-235`):
```elixir
digests = for rel <- ["mix.lock", "examples/phoenix_host/mix.lock"], path = Path.join(...),
              match?({:ok, %{type: :regular}}, File.lstat(path)), {:ok, bytes} <- [File.read(path)] do
            :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
          end
if digests == [], do: {:error, :lock_files_missing}, else: {:ok, digests}
```
Fix: require `length(digests) == 2` (iterate both rels, any missing/unreadable -> `{:error, :identity_unknown}` via the existing blocked-receipt path). Observation `locks != []` gates (~1609, ~1639) become `locks != nil` with `locks = nil` unless both present.

### Tests for stop/locks (`twin_runtime_check_test.exs`, `twin_producers_test.exs`, `verify_twin_test.exs`)

**Fixture:** `test/support/twin_git_fixtures.ex:30-31` already writes both `mix.lock` and `examples/phoenix_host/mix.lock`; registry is `Agent.start_link` (:57), so kill with `Agent.stop(registry)` never `Process.exit(:kill)`. Real source gate through `TwinProducers.source_gate` on a git fixture; to make a lockfile missing, `File.rm!` before `git add -A`.

**BIG FALLOUT:** `crosswake_proof_lane_verify_twin_test.exs:25-27` setup writes only root `mix.lock`; add `File.mkdir_p!` + `File.write!(Path.join(candidate, "examples/phoenix_host/mix.lock"), "%{}\n")` or ~20 tests go red via freeze. Git-fixture tests (`git add mix.lock` ~564, 606, 626) must also add the host lock (else dirty count 1 -> 2).

**Pinned-count model** (`twin_producers_test.exs:364-370`): `assert length(backend) == 13` before using the collection.

**D-14 source-pin** (`twin_journey_test.exs:154-160`):
```elixir
test "the journey observes identities only through the checked source gate" do
  source = File.read!("lib/crosswake/proof_lane/twin_journey.ex")
  assert source =~ "TwinProducers.checked_identities("
  refute source =~ "TwinProducers.observe_identities("
end
```
Copy for `stop_children` discard: assert `~r/^\s+TwinRuntime\.stop_children\(runtime\)\s*$/m`, refute `= TwinRuntime.stop_children(` / `case TwinRuntime.stop_children(`. Behavioural half: existing tests at `verify_twin_test.exs` ~425-440 already double-stop (producer `:ok = stop_all`, then command `after`).

### `twin_receipt_test.exs` :289, :110 (loop floors)

Current (:283-292): outer loop pinned (`length(decoded["groups"]) == 10`), inner `for e <- g["sub_observations"]` unpinned. Insert at head of outer body: `assert [_ | _] = g["sub_observations"]` and `assert length(g["sub_observations"]) == Map.fetch!(expected_counts, g["id"])`, where `expected_counts = Map.new(TwinReceipt.roster(), &{&1.id, length(&1.sub_observations)})` (counts 4,5,3,7,4,5,5,3,5,8). :110: `assert length(TwinReceipt.identity_joins()) == 7` before the loop.

### Other floor sites (idiom: floor before loop)

Copy the in-file idiom `assert length(x) > 0` / `assert is_list(m) and length(m) > 0` (phase64 :190, :238, :754) for phase64 :416/:460 (`assert [_ | _] = ios_entries`/`android_entries`), doctor_origin_mode :360 (`findings = ...; assert [_ | _] = findings` inside loop head), gen_shell_origin_mode :99 (`assert map_size(expected) > 0`) and :336 (bind `forbidden_ats_keys()`, `assert [_ | _]`), verify_twin_test :640 (`assert length(lines) == 4`, sibling pinned at ~574-579). Example host :47: add `assert map_size(manifest["routes"]) > 0` before the loop; keep the existing `phase180_gate`/`phase180_control` tag pairing (:38-58). `doctor_test.exs:859` is report-only waiver.

### Mutation harness (`mutate-185.sh`, evidence only)

**Analog:** `/private/tmp/crosswake-phase180-run/mutate-184-13.sh`. Copy: rsync `--exclude .git` to a throwaway dir, separate `MIX_BUILD_PATH`, `apply()` (sha256 before/after must differ, `perl -0pi`), `touch_file`/`restore_all`, `totals`, `has_header`, `finish()`:
```bash
if [ $rc -eq 0 ] || [ "$N" -lt 1 ] || [ "$MF" -lt 1 ]; then harness_fail ...
...
echo "control $n: $guard: failed as expected in $named (rc=$rc $N tests, $MF failures)" >> "$LOG"
```
Plus control 0 unmutated passing, and a paired negative control for :289 (mutate `TwinReceipt.project/2`, floor reverted must pass). Add controls (i) dead-registry catch returning `[]`, (ii) `results == []`/`digests == []`, (iii) `locks != []`. End with a sha256 manifest of the real candidate.

## Shared Patterns

- **Fail-closed floor idiom:** `[_ | _] =` or `length(x) == N` from an independent source, never `assert Enum.all?(`/`any?(` (Phase 184 gate rejects `^\+.*(assert|refute)[[:space:]]+Enum\.(all|any)\?\(`).
- **Tolerant dead-process calls:** `try/catch :exit, _` (`twin_fault_boundary.ex:94-100`), not `Process.alive?` then call.
- **Ledger drift:** line shifts in files with ledger rows (phase64 :596, twin_producers_test :80/:265, verify_twin_test :269/:294/:338) require `elixir script/inventory_collection_assertions.exs --emit-snapshot` then `--check`; verify diff is `display`-only. One final plan owns this.
- **Elixir invocations** must run from a dir with `.tool-versions` (asdf shim exit 126 otherwise).
- **File ownership:** `crosswake_proof_lane_verify_twin_test.exs` belongs to exactly one plan (twin plan), including the :640 floor.

## No Analog Found

| File | Role | Reason |
|---|---|---|
| loop scanner (phase dir) | one-off AST scan | RESEARCH has a prototype (`Code.string_to_quoted/2` + `Macro.prewalk/3`, scope reset at test/def/setup/describe, unwrap `|>`); no committed analog |
| `185-LOOP-MEASUREMENT.md` | evidence table | reuse ledger bucket vocabulary from `script/collection_assertion_ledger.json`; no prior report-mode table |

## Metadata

**Analog search scope:** `script/`, `scripts/`, `lib/crosswake/proof_lane/`, `lib/mix/tasks/`, `test/support/`, the twelve touched test files, `/private/tmp/crosswake-phase180-run/`
**Pattern extraction date:** 2026-10-16
