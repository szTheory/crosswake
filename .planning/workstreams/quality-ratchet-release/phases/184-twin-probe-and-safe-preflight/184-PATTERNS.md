# Phase 184: Twin probe and safe preflight - Pattern Map

**Mapped:** 2026-10-15
**Files analyzed:** 11 (4 modified lib, 2 new lib, 1 new task, 3 new tests, 1 guide, plus optional test support)
**Analogs found:** 10 / 11

All code paths are in the candidate `/private/tmp/crosswake-phase180-impl` (HEAD 50fcd57), which is the tracked source. The tracked-source gate was checked there with `git ls-files --error-unmatch` for twin_producers.ex, twin_runtime.ex, verify_twin.ex and both existing test files. Line numbers below are from that checkout.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/proof_lane/twin_producers.ex` (modify: builder, `probe_source`, `dirty_counts`, `source_gate/3`, `observe_identities/3`) | service/utility | request-response (git subprocess) | itself: `run_git/2`, `git/3`, `probe/2` (`:686-830`) | exact (in-place refactor) |
| `lib/crosswake/proof_lane/twin_runtime.ex` (modify: `check/1`, `commit/1`, `prepare/1`) | service | request-response | itself: `prepare/1` `:58-86` | exact (in-place split) |
| `lib/crosswake/proof_lane/twin_preflight.ex` (new) | service | request-response | `TwinRuntime.prepare/1` `with` chain + `TwinProducers.freeze/3` | role-match |
| `lib/mix/tasks/crosswake.proof_lane.twin_preflight.ex` (new) | mix task | request-response | `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex` | exact |
| `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex` (modify: `blocked_receipt`, `source_dirty_action`) | mix task | request-response | itself `:146-193`, `:291-299` | exact |
| `test/crosswake/proof_lane/twin_source_probe_test.exs` (new) | test | real git repos | `twin_producers_test.exs` `repo_fixture/1`, `git/2`, `env_restore/1` | exact |
| `test/crosswake/proof_lane/twin_runtime_check_test.exs` (new) | test | request-response | `crosswake_proof_lane_verify_twin_test.exs` setup, `free_port/0`, `record/3` | role-match |
| `test/mix/tasks/crosswake_proof_lane_twin_preflight_test.exs` (new) | test | request-response | `crosswake_proof_lane_verify_twin_test.exs` | exact |
| `test/support/twin_git_fixtures.ex` (optional) | test support | n/a | `repo_fixture/1` + `git/2` + `git_env/1` | role-match |
| `guides/see_it_run.md` (modify) | docs | n/a | existing section "Run the Reference Twin (Simulator)" (~160-185) | exact |
| Mutation-control harness (outside git, `/private/tmp/crosswake-phase180-run/`) | script | batch | 183 `mutation-183.log` pattern (RESEARCH "Mutation-control pattern") | No source analog (see below) |

## Pattern Assignments

### `twin_producers.ex` shared builder (service, request-response)

**Analog:** current `run_git/2`, `git/3`, `@git_scrub_env` in the same file.

**Env scrub base to extend** (`twin_producers.ex:688-710`):
```elixir
@git_scrub_env [ "GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", ... "GIT_CONFIG_COUNT",
                 "GIT_CONFIG_PARAMETERS", "GIT_PREFIX" ]
                 |> Enum.map(&{&1, nil})
                 |> Kernel.++([{"GIT_OPTIONAL_LOCKS", "0"}, {"GIT_CONFIG_NOSYSTEM", "1"},
                               {"GIT_TERMINAL_PROMPT", "0"}, {"LC_ALL", "C"}])
```
Add `GIT_ATTR_SOURCE`, `GIT_EXTERNAL_DIFF`, `GIT_EXEC_PATH` as nil; add `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_NO_REPLACE_OBJECTS=1`, `GIT_ATTR_NOSYSTEM=1`. Build through a `Map` (RESEARCH Pattern 1), per-call `GIT_INDEX_FILE` only for the fresh-index pair.

**Single spawn site to turn into the builder's only caller** (`:716-723`):
```elixir
defp run_git(args, git_cmd) do
  git_cmd.("sh", ["-c", "exec \"$@\" 2>/dev/null", "sh", "git" | args],
    env: @git_scrub_env, stderr_to_stdout: false)
rescue
  ErlangError -> :unavailable
end
```
Changes: also rescue `ArgumentError` (D-29), refuse NUL in the path before spawning, put the pins (D-05 + `core.attributesFile=/dev/null` per D-23) before `-C path`.

**`git/3` wrapper** (`:725-730`) already maps non-zero to `{:blocked, :prerequisite_missing}`; keep, and make every caller (`freeze` `:632-633`, `observe_identities` `:922,923,925,926`) pass `:git_cmd` through (closes IN-01).

**Probe to replace** (`probe/2` `:759-783`), including the `with` shape that returns `:unavailable` on any failure:
```elixir
with {out, 0} <- run_git(status, git_cmd),
     {:ok, excludes} <- exclude_rules(path, git_cmd) do
  {:ok, count_records(String.split(out, <<0>>, trim: true), 0), excludes}
else
  _ -> :unavailable
end
```
Keep `exclude_rules/2` `:794-802`, `read_exclude/1` `:804-810` and `active_rule?/1` `:812-815` unchanged for X and for the info/attributes active-line test (reuse `active_rule?/1`). `count_records/2` `:786-792` rename branch becomes unreachable (D-27).

**Thin-view pattern** (`clean_tree/2` `:739-745`, `dirty_count/2` `:752-757`): keep the signatures, delegate to a new `probe_source/2` (RESEARCH Pattern 2). Existing return values `:ok | {:blocked, :source_dirty | :prerequisite_missing}` must not change.

**Bound constant** `@max_dirty_count 1_000_000` `:712`; D-32 requires a test pinning it to `TwinReceipt`'s `@max_measure` (`twin_receipt.ex:56`).

**`freeze/3` split target** (`:628-671`): order is `read_identity`, `rev-parse HEAD`, `rev-parse HEAD^{tree}`, `same` x2, `clean_tree(path, Keyword.take(opts, [:git_cmd]))`, `lock_digests`, `file_digest(study_js)`, then `backend_digest`. Move everything before `backend_digest` into `source_gate/3` (RESEARCH "Split designs", first arg is a plain map pattern so `%TwinRuntime{}` and a preflight map both match). Keep the failure mapping `{:blocked, _} = b -> b; _ -> {:blocked, :identity_unknown}`.

**`observe_identities/2` `:915-930` and `checked_identities/3` `:988-994`**: add `opts \\ []`, pass `Keyword.take(opts, [:git_cmd])` to all four `git/3` calls and to `clean_tree` at `:924`.

---

### `twin_runtime.ex` `check/1` / `commit/1` / `prepare/1` (service, request-response)

**Analog:** current `prepare/1` (`twin_runtime.ex:58-86`) — copy the `with` chain order verbatim into `check/1`:
```elixir
with {:ok, root} <- run_root(opts[:run_root]),
     :ok <- not_reused(root),
     {:ok, record} <- candidate_record(opts[:candidate]),
     :ok <- outside_candidate(root, record.candidate_path),
     {:ok, db} <- database_path(root, opts[:database_path]),
     {:ok, port} <- origin_port(record.origin),
     {:ok, listener} <- acquire_origin(port) do
  {:ok, registry} = Agent.start(fn -> %{children: %{}, first_failure: nil} end)
  ...struct build...
```
`check/1` ends at `origin_port`, then a bind-and-release; `commit/1` takes the `acquire_origin` + `Agent.start` + struct build tail.

**Run-root check to extend with owner uid** (`:283-318`): path branch uses `File.lstat` with `%{type: :directory, mode: mode}` and `(mode &&& 0o077) == 0`; failure text "Create a private run root directory (mode 0700) and run again with it". Add `uid` match against `id -u` via an opts seam (D-31). The `nil` branch (`run_root(nil)` `:283-298`, the only `File.mkdir`) moves to `commit/1`; `check/1` only computes a prospective path.

**Dev/inode ancestor walk to reuse for toplevel/temp-index containment** (`outside_candidate/2` `:335-355`, `inside?/2` `:357-366`, currently private):
```elixir
defp inside?(path, identity) do
  same = case File.stat(path) do
    {:ok, %{major_device: dev, inode: ino}} -> {dev, ino} == identity
    _ -> false
  end
  parent = Path.dirname(path)
  same or (parent != path and inside?(parent, identity))
end
```
Make it `@doc false def` for `TwinProducers` (D-25/D-28) or duplicate the 8 lines.

**Bind-and-release analog** (`acquire_origin/1` `:471-492`): same listen options and error mapping; copy options and the `:eaddrinuse` -> `:origin_port_occupied` failure text, but `:gen_tcp.close(l)` immediately:
```elixir
:gen_tcp.listen(port, [:binary, ip: {127, 0, 0, 1}, reuseaddr: false, active: false, packet: :raw])
{:error, :eaddrinuse} -> {:error, failure(:origin_port_occupied, "Free 127.0.0.1:#{port} ...")}
{:error, _} -> {:error, failure(:prerequisite_missing, "Make 127.0.0.1:#{port} bindable and run again")}
```
`commit/1` must keep the `acquire_origin` mapping (port can be taken between check and commit).

Error shape everywhere: `{:error, failure(cause, action)}` with `defp failure(cause, action), do: %{cause: cause, action: action}` (`:495`). Keep using `:prerequisite_missing` for run-root faults (`:run_root_rejected` is unused).

---

### `lib/mix/tasks/crosswake.proof_lane.twin_preflight.ex` (mix task, request-response)

**Analog:** `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex`.

**Skeleton to copy** (`:1-35`, `:44-50`):
```elixir
use Mix.Task
@switches [candidate: :string, run_root: :string, identity: :string]

@impl Mix.Task
def run(args) do
  {status, lines} = execute(args, [])
  Enum.each(lines, fn line -> Mix.shell().info(line) end)
  if status != 0, do: System.halt(status), else: :ok
end

def execute(args, opts) when is_list(args) do
  {parsed, positional, invalid} = OptionParser.parse(args, strict: @switches)
```
Deviation (D-14): do NOT `Mix.raise` on `positional != ["ios"] or invalid != []` (`:48-50`) or missing identity (`:54-56`); return `{2, four_lines}` blocked instead. Never exit 1.

**Four-line summarizer to copy then change** (`summarize/4` `:301-312`):
```elixir
"result: #{result} (exit #{code})",
"first cause: #{cause}",
"report: #{report || "none written"}",
"next action: #{action}"
```
Preflight lines become exactly `result: allowed|blocked` (no `(exit N)`, D-31), `first cause: none|<atom>`, `report: none written; no run root was created or consumed`, `next action: ...`.

Error-to-line mapping to copy: `{:error, %{cause: cause, action: action}} -> summarize(:blocked, Atom.to_string(cause), nil, action)` (`:73-75`). The preflight must never call `blocked_receipt/2`, `write_and_verify/3`, `write_private/2`, `TwinRuntime.commit/1` or `TwinProducers.write_expectations/2`.

---

### `lib/crosswake/proof_lane/twin_preflight.ex` (service, request-response)

**Analog:** `prepare/1` + `freeze/3` chains. `check/1` = `TwinRuntime.check/1` then `TwinProducers.source_gate(%{candidate_path:, candidate_head:, candidate_tree:}, identity, opts)` then the D-18 digest comparison (record `resource_digests`/`fixture_digests` vs identity `manifest`, `activation`, `media`; `read_identity/1` `:673-684` returns `%{media:, size:, manifest:, activation:}`). Mismatch -> `identity_mismatch` (already in `@causes`, `twin_receipt.ex:23-43`). Empty check list must return an error (D-20). Reuse `same/2` (`twin_producers.ex:686`) style: `if a == b, do: :ok, else: {:blocked, :identity_mismatch}`.

---

### `verify_twin.ex` `blocked_receipt/2` and `source_dirty_action` (modify)

**Current code** (`:146-193`): `count = if cause == :source_dirty, do: TwinProducers.dirty_count(runtime.candidate_path)`, observation attrs `measure: count, cause: cause`, then
```elixir
action = if cause == :source_dirty, do: source_dirty_action(count), else: next_action(receipt, cause)
```
Replace with `dirty_counts` / `probe_source`: `measure = M+F+X` (nil when refused, unavailable or over bound), line 4 from one shared message composer (put in `TwinProducers` or a small module so both tasks use it). Also update `next_action(%{overall_status: :blocked}, :source_dirty)` `:284` and `source_dirty_action/1` `:291-299`; current text to replace: "The candidate has #{n} uncommitted or untracked files. Commit or remove ... Run git status in the candidate to see them."

Existing assertions that will need review (append-only edits to avoid ledger line shifts): `crosswake_proof_lane_verify_twin_test.exs:562` (`action =~ "next action: The candidate has 1 uncommitted or untracked files. Commit or remove"`) and `:590`.

---

### New tests

**`twin_source_probe_test.exs`** — analog `twin_producers_test.exs`:

Fixture repo (`repo_fixture/1` `:418-491`): git init in `System.tmp_dir!()/twin-freeze-<hex>`, files committed, identity/run root in a sibling `dir <> "-side"`, `on_exit(fn -> File.rm_rf(dir) end)`. Note `:478-490` duplicates a dead `{:ok, ...}` (IN-02); do not copy it.

Isolated git env (`git_env/1` `:494-506`) and helper (`git/2` `:508-529`):
```elixir
[{"HOME", home}, {"XDG_CONFIG_HOME", Path.join(home, ".config")}, {"GIT_CONFIG_NOSYSTEM", "1"},
 {"GIT_CONFIG_GLOBAL", "/dev/null"}, {"GIT_AUTHOR_DATE", "2026-01-01T00:00:00Z"}, ...]
System.cmd("git", ["-c","user.name=t","-c","user.email=t@example.test","-c","commit.gpgsign=false","-c","core.autocrlf=false","-C", dir | args], env: git_env(dir), stderr_to_stdout: true)
```
`git/2` asserts exit 0 (`{out, 0} =`), so use raw `System.cmd` for expected-failure commands.

Env restore helper (`:626-632`): `old = System.get_env(name); on_exit(fn -> if old, do: System.put_env(name, old), else: System.delete_env(name) end)`. Use for `GIT_CONFIG_GLOBAL`, `HOME`, `XDG_CONFIG_HOME`, `TMPDIR` (absolute path only).

Stderr-fd test to rewrite (`:755-789`): fake `git` on PATH logs `/dev/fd/2 -ef /dev/null`; change its `case` to `exec "$REAL_GIT" "$@"` (resolve `System.find_executable("git")` before editing PATH) and raise the `length(lines) >= 4` floor.

Ledger rule: place tests in NEW files and never use `assert|refute Enum.all?/any?(` (ledger hard-codes row displays and counts; RESEARCH "Vacuous-assertion ledger"). Use `assert length(x) == n`, `assert x == []`, `for ... do assert ... end`.

**`twin_runtime_check_test.exs`** — analog `crosswake_proof_lane_verify_twin_test.exs` setup (`:12-61`):
```elixir
use ExUnit.Case, async: false
setup do base = Path.join(System.tmp_dir!(), "twin-test-" <> Base.encode16(:crypto.strong_rand_bytes(6), case: :lower))
  File.mkdir_p!(base); File.chmod!(base, 0o700); on_exit(fn -> File.rm_rf(base) end)
  ... run_root 0700 ...
defp free_port do {:ok, l} = :gen_tcp.listen(0, ip: {127,0,0,1}, reuseaddr: false); {:ok, port} = :inet.port(l); :gen_tcp.close(l); port end
defp record(ctx, port \\ nil, mode \\ 0o600)   # writes 0600 candidate JSON
```
Same-causes table: assert `TwinRuntime.check(opts)` and `TwinRuntime.prepare(opts)` give the same `{:error, %{cause: c}}`. Held-origin precedent: `verify_twin_test.exs:152-167`.

**`crosswake_proof_lane_twin_preflight_test.exs`** — analog `crosswake_proof_lane_verify_twin_test.exs`: call `TwinPreflight`/task `execute(args, opts)` with `args(ctx, record) = ["ios", "--candidate", record, "--run-root", ctx.run_root]` (`:61`), assert exact four-element list match like `assert {2, [first, "first cause: source_dirty", report, action] = lines}` (`:565-566`), privacy scan like the marker-leak loop (`:575-582`), and `git_in/2` (`:523-541`) for real repos. Leaves-nothing tests list the run root, candidate and `candidate/.git` before/after with `TMPDIR` sandboxed.

---

## Shared Patterns

### Fail-closed result and path-free failure
**Source:** `twin_producers.ex:725-730` (`git/3`) and `:716-723` (`run_git/2` rescue); `twin_runtime.ex:495` (`failure/2`).
**Apply to:** every new twin git call, preflight, `check/1`. Any non-zero, spawn error, truncated `-z` output -> `{:blocked, :prerequisite_missing}` / `:unavailable`; action text never contains candidate path, `$HOME` or user name.

### Four-line output with exit mapping
**Source:** `verify_twin.ex:301-312` + `execute/2` seam `:44-82` + `run/1` `:31-35` (halt only in `run/1`).
**Apply to:** `twin_preflight` task (with the D-14 variations above).

### Dev/inode path comparison (never realpath strings)
**Source:** `twin_runtime.ex:335-366`.
**Apply to:** toplevel check (D-25), temp-index containment (D-28), prospective run root.

### Private-file/dir permission style
**Source:** `twin_runtime.ex:283-298` (`File.mkdir` then `File.chmod(..., 0o700)`), `verify_twin.ex:~268-275` `write_private` uses `[:write, :exclusive, :binary]` then chmod 0600.
**Apply to:** private temp-index directory (random name, `File.mkdir` so it fails if present).

### `:git_cmd` injection seam
**Source:** `clean_tree(path, opts)` `:739-745` (`Keyword.get(opts, :git_cmd, &System.cmd/3)`), used with `Keyword.take(opts, [:git_cmd])`.
**Apply to:** all new public probe/gate functions and tests for unknown tag, rc 128/129, truncated output, raising stub.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| Mutation harness (outside git) | script | batch | 183 used an ad hoc script outside git (log only at `/private/tmp/crosswake-phase180-run/mutation-183.log`); the sha-before/after, N>=1 tests, named-failure checks in D-22 are new. Write it from RESEARCH "Mutation-control pattern". Never pipe `mix test` into `tail` (exit-code masking). |
| uid lookup (`id -u`) | utility | request-response | No stdlib `getuid`, no existing precedent; use `System.cmd` on `id` with an option seam (RESEARCH Split designs, Owner check). |

## Metadata

**Analog search scope:** `lib/crosswake/proof_lane/`, `lib/mix/tasks/`, `test/crosswake/proof_lane/`, `test/mix/tasks/` in `/private/tmp/crosswake-phase180-impl`
**Files read:** twin_producers.ex (targeted ranges), twin_runtime.ex (targeted ranges), crosswake.proof_lane.verify_twin.ex (full), twin_producers_test.exs and crosswake_proof_lane_verify_twin_test.exs (targeted ranges)
**Pattern extraction date:** 2026-10-15
