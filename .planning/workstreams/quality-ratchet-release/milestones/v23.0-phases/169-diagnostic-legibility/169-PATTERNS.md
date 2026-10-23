# Phase 169: Diagnostic Legibility - Pattern Map

**Mapped:** 2026-09-15
**Files analyzed:** 12 (all modified, no wholly-new files — this phase is a pure refactor of
existing modules/scripts/workflows per RESEARCH.md's "no new files/directories" note)
**Analogs found:** 12 / 12 (every file IS its own analog — modify-in-place; sibling functions
within the same file supply the pattern to extend)

All files in this phase are **modifications to existing tracked source**, not new files. There is
no "closest analog elsewhere in the codebase" question for most of them — the pattern to copy is
the sibling function/block *already in the same file*. This PATTERNS.md therefore maps each
changed file to (a) the in-file sibling pattern the new code must match, and (b) any cross-file
precedent for shapes that don't yet exist in that file (e.g. the `:unverifiable` exit code, which
has precedent in other scripts but not yet in `release_status.ex`).

## File Classification

| Modified File | Role | Data Flow | Pattern Source | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/release_status.ex` | service (report composer) | transform (parse→aggregate→render) | itself (`scanner_check/7`, `scanner_ids_result/2`, `render/1`, `exit_code/1`) + `script/check_required_checks_registered.sh` (exit-3 precedent) | exact (in-file) |
| `script/check_release_workflow_integrity.exs` | CLI script (scanner) | batch / event-driven (stdout emission) | itself (existing eager check-list + print loop) + `lib/mix/tasks/crosswake.demo.ex` (`exit({:shutdown,_})` idiom) | exact (in-file) |
| `lib/mix/tasks/crosswake.release.status.ex` | CLI task (Mix task) | request-response | itself + `lib/mix/tasks/crosswake.demo.ex` (exit-code branching idiom) | role-match |
| `.github/workflows/release-please.yml` | config (CI workflow) | event-driven (push trigger) | itself (sibling job `name:` keys already following no-version convention, e.g. `native-release-status`) | exact (in-file) |
| `.github/workflows/phase70-proof.yml` | config (CI workflow) | event-driven | `.github/workflows/phase48-proof.yml` (the colliding sibling) | exact |
| `script/list_merge_blocking_checks.py` | utility (static-analysis scanner) | batch (file inventory → assert) | itself (`--producers` traversal, `diagnostic/5` helper) | exact (in-file) |
| `script/check_required_checks_registered.sh` | utility / test (CI guard) | request-response (shell assertion) | itself (existing exit-3 branch at :50-52) | exact (in-file) |
| `script/check_release_version_truth.exs` (optional D-15 sweep) | CLI script | batch | `script/check_required_checks_registered.sh` (exit-3 convention) | role-match |
| `test/crosswake/proof/phase142_release_integrity_test.exs` | test | request-response (asserts CLI output) | itself (existing `assert output =~ "[crosswake] OK: #{id}"` shape) | exact (in-file) |
| `test/crosswake/proof/phase153_ios_mirror_unblock_test.exs` | test | request-response | `phase142_release_integrity_test.exs` (same assertion shape) | exact |
| `test/mix/tasks/crosswake_release_status_test.exs` | test | request-response | itself (existing exit-code/render assertions) | exact (in-file) |
| `test/crosswake/proof_lane/ios_verifier_test.exs` | test | request-response | itself (existing 2-vs-3 exit split assertions) | exact (in-file) |

## Pattern Assignments

### `lib/crosswake/release_status.ex` (service, transform)

**Analog:** itself — the file already contains every shape this phase extends. No external file
supplies a better pattern for the Elixir-side changes.

**Module header / constants pattern** (lines 1-24):
```elixir
defmodule Crosswake.ReleaseStatus do
  @moduledoc """
  Reads Crosswake's release graph and reports local package-family release readiness.
  ...
  """

  @schema_version "1.1.0"
  @candidate_version "0.2.1"
  ...
  @workflow_integrity_source "script/check_release_workflow_integrity.exs"
  @workflow_integrity_command "elixir script/check_release_workflow_integrity.exs"
```
D-10 bumps `@schema_version` `"1.1.0"` → `"1.2.0"` in place, same style as the existing bump
convention (a bare module attribute, no migration machinery).

**`scanner_check/7` — the pattern the 5 existing call sites use, and D-07 modifies** (lines
796-818):
```elixir
defp scanner_check(
       status_when_ok,
       code,
       ok_message,
       error_message,
       workflow_integrity,
       required_ids,
       local_ok? \\ true
     ) do
  {scanner_ok?, evidence, scanner_message} =
    scanner_ids_result(workflow_integrity, required_ids)

  ok? = local_ok? and scanner_ok?

  %{
    status: if(ok?, do: status_when_ok, else: :error),
    code: code,
    message: if(ok?, do: ok_message, else: "#{error_message}: #{scanner_message}"),
    next_action: if(ok?, do: nil, else: @workflow_integrity_command),
    source: @workflow_integrity_source,
    evidence: evidence
  }
end
```
D-07's "report only OWN failures with verbatim detail" change is scoped to `scanner_ids_result/2`'s
return value (below), not this wrapper's shape — the wrapper's `%{status:, code:, message:, ...}`
map shape is unchanged and is the template every one of the 5 call sites (`:382`, `:394`, `:414`,
`:423`, `:432`) already follows. Two representative call sites to copy the invocation shape from
(lines 382-390, 413-421):
```elixir
scanner_check(
  :ok,
  "release.workflow_path_gates",
  "root/native publish jobs use exact paths_released gates",
  "root/native publish jobs are not exact path-gated",
  workflow_integrity,
  @workflow_path_gate_ids,
  workflow =~ "paths_released:" and core_path_gates?(jobs)
),
```
```elixir
scanner_check(
  :ok,
  "release.governance_queue_max",
  "release workflow uses only supported concurrency keys and does not cancel in-progress runs",
  "release workflow must preserve pending release runs",
  workflow_integrity,
  @governance_queue_ids,
  governance_queue_max?(non_comment_workflow)
),
```
The new D-06 owner check (`release.workflow_integrity`) should follow this exact map-literal shape
but source its `evidence`/`message` from the FULL parsed set rather than `required_ids`-scoped —
per CONTEXT.md's own discretion note, either a new private builder alongside `scanner_check/7` or
an extension of it is acceptable; this map shape is what `render/1` (below) and `aggregate_status/1`
consume, so it must not diverge from it.

**`scanner_ids_result/2` — the exact function D-07/D-09 target** (lines 820-862, includes the
`cond` D-09 reorders):
```elixir
defp scanner_ids_result(%{status: :unavailable, message: message}, _required_ids),
  do: {false, [], message}

defp scanner_ids_result(%{status: :failed, checks: checks}, required_ids) do
  missing = Enum.reject(required_ids, &Map.has_key?(checks, &1))

  failing =
    checks
    |> Enum.filter(fn {_id, check} -> match?(%{status: :error}, check) end)
    |> Enum.map(fn {id, _check} -> id end)
    |> Enum.sort()

  evidence = Enum.uniq(missing ++ failing)

  cond do
    missing != [] ->
      {false, evidence, "missing scanner IDs: #{Enum.join(missing, ", ")}"}

    failing != [] ->
      {false, evidence, "failing scanner IDs: #{Enum.join(failing, ", ")}"}

    true ->
      {false, evidence, "scanner exited nonzero without parseable failing IDs"}
  end
end
```
D-09 swaps the order of the two `cond` clauses and composes both when non-empty
(`"2 failing (…); 1 never defined (…)"`) instead of one shadowing the other. D-07 additionally
changes what `failing`/the owning check surface: today only `id` is extracted
(`Enum.map(fn {id, _check} -> id end)`) — the `detail` field living in `checks[id].detail` (see
`parse_workflow_integrity_output/1` below) must be threaded through instead of discarded, for the
D-06 owner check specifically (the 5 scoped call sites keep reporting only their own-scope
membership test, per D-07's "under a complete run they report OK" rule).

**`workflow_integrity_evidence/1` + `parse_workflow_integrity_output/1` — D-05's target** (lines
894-937):
```elixir
defp workflow_integrity_evidence(cwd) do
  case System.cmd("elixir", [@workflow_integrity_source], cd: cwd, stderr_to_stdout: true) do
    {output, exit_code} ->
      checks = parse_workflow_integrity_output(output)

      cond do
        checks == %{} ->
          %{status: :unavailable, checks: %{}, message: "scanner output was empty or unparseable"}

        exit_code == 0 ->
          %{status: :ok, checks: checks, message: "scanner passed"}

        true ->
          %{status: :failed, checks: checks, message: "scanner reported release workflow drift"}
      end
  end
rescue
  error ->
    %{status: :unavailable, checks: %{}, message: Exception.message(error)}
end

defp parse_workflow_integrity_output(output) do
  output
  |> String.split("\n", trim: true)
  |> Enum.flat_map(fn line ->
    case Regex.run(~r/^\[crosswake\] (OK|FAIL): ([^\s]+) - (.*)$/, line, capture: :all_but_first) do
      [status, id, detail] -> [{id, %{status: scanner_status(status), detail: detail}}]
      _ -> []
    end
  end)
  |> Map.new()
end
```
D-05 requires this to stop ending in `Map.new/1` (which loses insertion order). Copy the same
`Enum.flat_map` regex-match structure but end in `Enum.with_index/1` (attaching `order:` to each
value) or simply return the list of `{id, check}` pairs directly instead of collapsing to a `Map`
— `checks == %{}` empty-check above becomes `checks == []`, and every downstream `Map.has_key?` /
`checks[id]` access becomes a lookup helper over the ordered list. This is also the function that
must grow the crash-before-roster vs crash-after-roster distinction (D-03): today `rescue` always
returns `:unavailable` regardless of whether any output was emitted — this needs to branch on
whether `output` contains a `ROSTER:` line to choose `:unavailable` (no roster) vs `:unverifiable`
(roster present, then crash), matching D-03's two literal message strings.

**`aggregate_status/1` + `exit_code/1` — the exact fail-open hazard D-13 fixes** (lines 865-874):
```elixir
def aggregate_status(checks) do
  cond do
    Enum.any?(checks, &(&1.status == :error)) -> :error
    Enum.any?(checks, &(&1.status == :warning)) -> :warning
    true -> :ok
  end
end

def exit_code(:error), do: 1
def exit_code(%{status: status}), do: exit_code(status)
def exit_code(_status), do: 0
```
Copy this exact `cond`/multi-clause-function shape. D-13 inserts one new `cond` branch (checking
for a status carrying `:unverifiable`, precedence between `:error` and `:warning`) and one new
`exit_code` clause `def exit_code(:unverifiable), do: 3` inserted BEFORE the catch-all
`def exit_code(_status), do: 0` — Elixir clause order matters here, so the new clause must be
textually above the wildcard, exactly mirroring how `def exit_code(:error), do: 1` is already
placed above it.

**`render/1` — the exact block D-10 extends** (lines 136-150):
```elixir
check_lines =
  [
    "",
    "Checks:"
  ] ++
    Enum.map(status.checks, fn check ->
      next_action =
        if check.status == :ok or is_nil(check.next_action) do
          ""
        else
          " next action: #{check.next_action}"
        end

      "- #{String.upcase(to_string(check.status))} #{check.code}: #{check.message}#{next_action}"
    end)
```
Every check today renders as exactly one line via `Enum.map`. D-10 needs the D-06 owner check
(identified by `check.code == "release.workflow_integrity"`, or an explicit new field) to instead
render as an indented multi-line block containing the full verbatim `detail` — branch inside this
same `Enum.map` (or a helper `render_check_line/1` extracted from it) rather than adding a second,
divergent render pass, so ordering (`status.checks` is already ordered per D-05) is preserved.

**Cross-file precedent for `:unverifiable`/exit 3 (not yet in this file)** — see
`script/check_required_checks_registered.sh` below.

---

### `script/check_release_workflow_integrity.exs` (CLI script, batch/event-driven)

**Analog:** itself (existing eager check-list + print loop) plus `lib/mix/tasks/crosswake.demo.ex`
for the `exit({:shutdown, _})` idiom D-14 imports into this file.

**Current print loop — the exact site D-02/D-04 extend and D-14 changes the tail of** (lines
166-178):
```elixir
failures = Enum.filter(checks, &match?({:error, _, _}, &1))

for {status, id, detail} <- checks do
  prefix = if status == :ok, do: "OK", else: "FAIL"
  IO.puts("[crosswake] #{prefix}: #{id} - #{detail}")
end

if failures == [] do
  System.halt(0)
else
  System.halt(1)
end
```
D-02 adds `IO.puts("[crosswake] ROSTER: #{length(checks)} #{Enum.map_join(checks, ",", fn {_,id,_} -> id end)}")`
BEFORE the `for` loop (i.e., right after `checks` — the eager list — is fully built, not before
line 166's loop starts printing OK/FAIL lines), and a `DONE` line after the loop:
`IO.puts("[crosswake] DONE: #{length(checks)} of #{length(checks)} roster checks emitted; #{length(failures)} failed.")`.
D-04's `roster_exact` self-check is a new entry appended to the SAME `checks` list before it's
printed (so it participates in ROSTER/DONE counts too), following whatever `{status, id, detail}`
3-tuple shape the other ~68 entries already use.

**`System.halt` → `System.stop` — the exact site D-14 changes**: same lines 169-177 above. Replace
`System.halt(0)` / `System.halt(1)` with `System.stop(code); Process.sleep(:infinity)` per D-14 —
copy the idiom's *reasoning* (buffered-stdout-under-pipe risk), not its exact call, from
`lib/mix/tasks/crosswake.demo.ex:24-25,42`:
```elixir
# A non-zero exit from the script (e.g. Docker absent / daemon down) is propagated
# via `exit({:shutdown, status})` so callers see the real failure code.
...
exit({:shutdown, status})
```
(That file's idiom is for an OS-process-in-a-Mix-context; this `.exs` script is a bare `elixir`
invocation so `System.stop/1` + `Process.sleep(:infinity)` is the correct analog per D-14's own
text, not `exit({:shutdown, _})` — that latter form is for the Mix task, below.)

**`path_from_env/2` — the fixture mechanism for BOTH new acceptance tests** (line 184-189, quoted
in RESEARCH.md):
```elixir
defp path_from_env(name, default) do
  case System.get_env(name) do
    value when is_binary(value) and value != "" -> value
    _ -> default
  end
end
```
Use this pattern (already applied to ~12 inputs) as-is; no new fixture plumbing needed. Point
`RELEASE_PLEASE_MANIFEST_PATH` at a drifted copy for a real FAIL; point a required path at a
missing file for a real crash.

---

### `lib/mix/tasks/crosswake.release.status.ex` (CLI task, request-response)

**Analog:** itself + `lib/mix/tasks/crosswake.demo.ex`'s exit-code idiom.

**Current exit-code call site — the exact function Pitfall 3 identifies as unable to express 3**
(full file relevant excerpt, lines 33-49):
```elixir
status = Crosswake.ReleaseStatus.build(live?: opts[:live] == true)

output =
  if opts[:json] == true do
    Jason.encode!(status, pretty: true)
  else
    Crosswake.ReleaseStatus.render(status)
  end

Mix.shell().info(output)

if Crosswake.ReleaseStatus.exit_code(status) != 0 do
  Mix.raise("Crosswake release status found blocking release issues")
end
```
D-14/D-16 require branching this into three cases instead of the current binary `!= 0` check:
```elixir
Mix.shell().info(output)

case Crosswake.ReleaseStatus.exit_code(status) do
  0 -> :ok
  1 -> Mix.raise("Crosswake release status found blocking release issues")
  3 -> exit({:shutdown, 3})
end
```
Keep `Mix.shell().info(output)` printed BEFORE the branch (unchanged) so the UNVERIFIED microcopy
(D-17) is visible before the process exits — this ordering is already correct in the current file
and must not move.

---

### `.github/workflows/release-please.yml` (config, event-driven) and `phase70-proof.yml`

**Analog:** sibling job/artifact names already in the same file that follow the no-version,
lowercase convention this phase's renames must match — e.g. `native-release-status` (line ~835,
cited in RESEARCH.md as "the already-neutral" precedent artifact name).

**Trigger block confirming no PR-context blast radius** (lines 13-17):
```yaml
on:
  push:
    branches:
      - main
  workflow_dispatch:
```

**Exact before/after rename table (D-22)** — copy these six literal changes verbatim, no
paraphrasing:

| file:line | before | after |
|---|---|---|
| `release-please.yml:30` | `Guard exact approved 0.2.1 merge` | `release: approved-candidate merge guard` |
| `release-please.yml:719` | `Prove exact public 0.2.1 artifacts` | `release: exact-public artifact proof` |
| `release-please.yml:767` | `Linked 0.2.1 release rollup` | `release: linked release rollup` |
| `release-please.yml:761` (artifact `with.name`) | `exact-public-proof-0.2.1` | `exact-public-proof` |
| `release-please.yml:829` (artifact `with.name`) | `linked-release-status-0.2.1` | `linked-release-status` |
| `phase70-proof.yml` job `advisory-provider-sandbox-device-proof`'s `name:` | `advisory provider sandbox/device proof (storekit + play billing)` | `advisory provider device proof (play billing)` |

**Confirmed duplicate this phase must break (D-19)** — `phase48-proof.yml:16-17` vs
`phase70-proof.yml:16-17`:
```yaml
advisory-provider-sandbox-proof:
  name: advisory provider sandbox/device proof (storekit + play billing)
```
```yaml
advisory-provider-sandbox-device-proof:
  name: advisory provider sandbox/device proof (storekit + play billing)
```
`phase48-proof.yml` is untouched (storekit is correct there); only `phase70-proof.yml`'s `name:`
changes, per the table above.

---

### `script/list_merge_blocking_checks.py` (utility, batch)

**Analog:** itself — the existing `"merge-blocking"`-substring dedup filter and its
`diagnostic/5` helper, both already present and just needing to be widened, not replaced.

**Current filter D-20 widens** (line ~260):
```python
if "merge-blocking" in record[0].lower():
    ...
        "duplicate-producer/duplicate-merge-blocking-name",
        ...
        "rename the later producer while retaining a stable merge-blocking name.",
```
D-20 removes the `if "merge-blocking" in record[0].lower():` guard so the SAME diagnostic body runs
unconditionally over every `(name, path, job_id)` record — copy the existing `diagnostic/5` call
shape and message wording style, do not invent a new diagnostic function. Additionally add a
version-literal reject: a regex `\d+\.\d+\.\d+` tested against any job `name:` or `upload-artifact`
`with.name` value, raising the same diagnostic-shape error with a distinct reason string (e.g.
`"version-literal-in-display-name"`).

---

### `script/check_required_checks_registered.sh` (utility/test, request-response)

**Analog:** itself — the file already contains the exit-3 convention D-11/D-24 ratify elsewhere.

**Exact exit-3 precedent to copy the SHAPE of, not the file itself** (lines 50-52):
```bash
elif ! current="$(gh api "$EP" 2>/dev/null)"; then
  echo "[crosswake] UNVERIFIED (exit 3): cannot read branch protection for ${REPO}@${BRANCH}." >&2
  exit 3
fi
```
This `echo … >&2; exit 3` two-line shape is the template for D-17's UNVERIFIED microcopy in the
Mix-task/library side, and the template for wherever D-24's guard test asserts a literal exit code.
D-24's new uniqueness assertion (consuming the widened Python scan) should append a new branch to
this same script following this exact `elif ! <condition>; then echo …; exit <code>; fi` chain
shape — not a separately structured function.

**Header-comment convention D-16 requires**: add the one-line
`# exit contract: 0 clean / 1 defect found / 3 could not verify` comment near the top of this file
and of `check_release_workflow_integrity.exs`, matching how this file already documents its
purpose in a leading comment block (read the first ~10 lines of the file at execution time to match
existing comment-block style exactly).

---

### Test files (`phase142_release_integrity_test.exs`, `phase153_ios_mirror_unblock_test.exs`, `crosswake_release_status_test.exs`, `ios_verifier_test.exs`)

**Analog:** `test/crosswake/proof/phase142_release_integrity_test.exs` is the primary template for
all new ExUnit assertions in this phase.

**Module header + module-attribute-as-fixture-path convention** (lines 1-19):
```elixir
defmodule Crosswake.Proof.Phase142ReleaseIntegrityTest do
  @moduledoc """
  Merge-blocking proof for v18 release-integrity guardrails.
  ...
  """

  use ExUnit.Case, async: true

  @workflow ".github/workflows/release-please.yml"
  @recovery_workflow ".github/workflows/hex-publish.yml"
  @scanner "script/check_release_workflow_integrity.exs"
  ...
```

**ID-list-as-module-attribute convention** (lines 21-39) — new required-ID groups for this phase's
new checks (e.g. `release.scanner.roster_exact`, `release.workflow_integrity`) should be declared
the same way:
```elixir
@phase143_ids ~w(
  release.hex_publish.already_live_preflight
  ...
)

@phase144_cleanroom_ids ~w(
  release.cleanroom.hex_metadata_floor
  ...
)
```

**Core assertion shape to preserve exactly (regression floor)** — repeats at lines 91, 125, 136,
147, 158, 209, 298 in this file, and at `phase153_ios_mirror_unblock_test.exs:134,202`:
```elixir
assert output =~ "[crosswake] OK: #{check_id}"
```
Every new test this phase adds for MSG-01/02/03/D-06/D-07 must NOT alter this assertion's truth
value for any check unaffected by the phase — this is the literal regression-floor citation from
RESEARCH.md's Validation Architecture section. New assertions for the owner check's verbatim
`detail` and the ROSTER/DONE lines should be added as NEW `assert` lines in the same file (or a new
`test/crosswake/proof/phase169_diagnostic_legibility_test.exs`, planner's discretion per CONTEXT.md)
using the identical `output =~ "..."` idiom, e.g.:
```elixir
assert output =~ "[crosswake] ROSTER: 68 "
assert output =~ "[crosswake] DONE: 68 of 68 roster checks emitted"
```

**Mix-task subprocess exit-code assertion pattern** — `test/mix/tasks/crosswake_release_status_test.exs`
already asserts exit-code/render behavior at lines 160, 241-243, 426, 458, 479 (per RESEARCH.md);
extend that file's existing assertion style rather than introducing a new test module for the
`:unverifiable`/exit-3 unit-level check. For the OS-level subprocess exit-code proof (the only way
to observe `Mix.raise` vs `exit({:shutdown, 3})` actually reaching the OS), follow the
`System.cmd("mix", ["crosswake.release.status"], ...)`-plus-`exit_status` pattern RESEARCH.md's
Validation Architecture table specifies — no existing subprocess-capturing test was found in this
file to copy verbatim; construct it from `System.cmd/3`'s standard `{output, exit_status}` return
shape (already used identically in `release_status.ex:895` for the scanner itself — reuse that same
call convention here for the test).

## Shared Patterns

### Additive stdout wire-protocol extension (TAP-plan-line precedent)
**Source:** `script/check_release_workflow_integrity.exs:166-178` (print loop) +
`lib/crosswake/release_status.ex:923` (consumer regex `~r/^\[crosswake\] (OK|FAIL): ([^\s]+) - (.*)$/`)
**Apply to:** D-02's ROSTER/DONE lines and D-04's `roster_exact` check.
The consumer regex only matches `OK|FAIL` lines; any new line KIND (`ROSTER:`, `DONE:`) is silently
ignored by the existing parser, which is what makes the extension purely additive. Do not touch the
regex.

### `[crosswake] … / What to do next:` microcopy house style
**Source:** `script/check_required_checks_registered.sh:51` (`[crosswake] UNVERIFIED (exit 3): …`)
and D-17's literal target strings.
**Apply to:** All new microcopy in `release_status.ex`'s `render/1` and the Mix task's UNVERIFIED
output. Format: `[crosswake] <VERB> (exit <n>): <one-sentence summary>` optionally followed by
indented `  - <detail>` bullet lines and a closing `[crosswake] What to do next: <action>.` line.

### Fail-open catch-all discipline
**Source:** `lib/crosswake/release_status.ex:873-875` (`exit_code/1`'s existing `:error`-then-
catch-all clause ordering).
**Apply to:** Any new status atom (`:unverifiable`) MUST get an explicit clause inserted above the
wildcard `def exit_code(_status), do: 0`, in the SAME commit as `aggregate_status/1`'s new branch
(D-13). Assert the exact code (`== 3`), never `!= 0`, in tests (Pitfall 1's warning sign).

### `exit({:shutdown, status})` / `System.stop` idiom for non-1 exit codes
**Source:** `lib/mix/tasks/crosswake.demo.ex:24-25,42` (documents and uses `exit({:shutdown, status})`);
`script/check_required_checks_registered.sh:52` (`exit 3` from a bare shell script).
**Apply to:** `lib/mix/tasks/crosswake.release.status.ex` (Mix-task boundary, use
`exit({:shutdown, 3})` since `Mix.raise` always exits 1) and
`script/check_release_workflow_integrity.exs` (bare `elixir` process, use
`System.stop(code); Process.sleep(:infinity)` instead of `System.halt/1` so piped stdout under CI
is not truncated).

### Env-var fixture injection (no mocking)
**Source:** `script/check_release_workflow_integrity.exs:184-189` (`path_from_env/2`).
**Apply to:** Every new acceptance test for MSG-01/MSG-02 — point `RELEASE_PLEASE_MANIFEST_PATH`
or another of the ~12 already-overridable env vars at a fixture file to produce a real FAIL or a
real crash; no `System.cmd` stubbing needed.

### `(name, path, job_id)` global inventory traversal
**Source:** `script/list_merge_blocking_checks.py`'s existing `--producers` traversal (already
inventories all 103 producers per RESEARCH.md).
**Apply to:** D-20's widened duplicate scan — widen the existing traversal's filter condition, do
not add a second traversal.

## No Analog Found

None. Every file in this phase's scope is an existing tracked file being modified in place; the
governing pattern for each is always a sibling block within that same file (or, for the
`:unverifiable`/exit-3 vocabulary which is new to `release_status.ex` specifically, the two
already-tested precedents in `script/check_required_checks_registered.sh` and
`script/verify_generated_ios_shell.sh`).

## Metadata

**Analog search scope:** `lib/crosswake/release_status.ex`, `script/check_release_workflow_integrity.exs`,
`lib/mix/tasks/crosswake.release.status.ex`, `lib/mix/tasks/crosswake.demo.ex`,
`.github/workflows/release-please.yml`, `.github/workflows/phase48-proof.yml`,
`.github/workflows/phase70-proof.yml`, `script/list_merge_blocking_checks.py`,
`script/check_required_checks_registered.sh`, `script/verify_generated_ios_shell.sh`,
`test/crosswake/proof/phase142_release_integrity_test.exs`,
`test/crosswake/proof/phase153_ios_mirror_unblock_test.exs`,
`test/mix/tasks/crosswake_release_status_test.exs`, `test/crosswake/proof_lane/ios_verifier_test.exs`
**Files scanned:** 14 (all read directly this session or in the immediately-preceding research
pass; all confirmed git-tracked via `git ls-files`)
**Pattern extraction date:** 2026-09-15
