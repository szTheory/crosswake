# Phase 130: Extraction Mechanics & Footgun Guards — Pattern Map

**Mapped:** 2026-06-25
**Files analyzed:** 11 new/modified artifacts
**Analogs found:** 11 / 11

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/companion_guard.ex` | utility | transform (AST walk) | `test/crosswake/proof/phase129_companion_contract_freeze_test.exs` (AST idiom) | role-match |
| `test/crosswake/proof/phase130_extraction_guards_test.exs` | test | request-response | `test/crosswake/proof/phase129_companion_contract_freeze_test.exs` | exact |
| `test/crosswake/proof/phase130_fail_closed_contract_test.exs` | test | request-response | `test/crosswake/proof/phase42_rulestead_companion_test.exs` | exact |
| `packages/crosswake_rulestead/mix.exs` | config | — | `mix.exs` (core) | role-match |
| `packages/crosswake_rulestead/lib/crosswake/companions/rulestead.ex` | service | request-response | `lib/crosswake/companions/rulestead.ex` | exact (move) |
| `packages/crosswake_rulestead/test/support/mock_flag_source.ex` | utility | — | `lib/crosswake/companions/rulestead/mock_flag_source.ex` | exact (move) |
| `packages/crosswake_rulestead/test/support/study_session_live.ex` | utility | — | `test/support/router_fixtures.ex` lines 40-46 | exact (copy) |
| `script/verify_companion_package.sh` | utility | batch | `.github/workflows/phase43-proof.yml` (CI shell) | partial |
| `lib/crosswake/compatibility/route_gate.ex` (modify) | service | request-response | `lib/crosswake/compatibility/route_gate.ex` lines 121-147 | self (inline Denial pattern) |
| `lib/crosswake/shell/denial.ex` (modify) | model | — | `lib/crosswake/shell/denial.ex` lines 14-44 | self (enum extension) |
| `lib/crosswake/doctor/doctor.ex` (modify) | service | batch | `lib/crosswake/doctor/doctor.ex` lines 564-618 | self (branching extension) |
| `mix.exs` (modify — delete MIX_INCLUDE_* blocks + add aliases) | config | — | `mix.exs` lines 38-63 | self |

---

## Pattern Assignments

### `lib/crosswake/companion_guard.ex` (utility, AST walk)

**Analog:** `test/crosswake/proof/phase129_companion_contract_freeze_test.exs` — the `@expected_callbacks MapSet` + `Macro.prewalk/3` idiom

**Role:** Pure support module. Exports `assert_no_static_refs!/0` and `check_source/1`; used by the guard test and (post-publish) by the companion package's own test. No `use ExUnit.Case` — plain module callable from tests.

**Frozen MapSet pattern** (mirror of `@expected_callbacks` at phase129 test line 21-28):
```elixir
# Hardcoded frozen set — one entry per extraction phase.
# DO NOT derive from path: deps (core names no companion; D-13).
@extracted_companions MapSet.new([
  # Phase 130: rulestead adapter extracted
  Crosswake.Companions.Rulestead
])
```

**AST walk pattern** (mirror of phase129's `behaviour_info(:callbacks)` shape check; use `Code.string_to_quoted/2` + `Macro.prewalk/3`):
```elixir
# EXTRACT-03: detect {:__aliases__, _, [:Crosswake, :Companions, :Rulestead]} nodes
# NOT a string/text search — string literals in moduledocs are not alias AST nodes (D-12)
def check_source(source_string) do
  {:ok, ast} = Code.string_to_quoted(source_string, [])
  violations =
    Macro.prewalk(ast, [], fn
      {:__aliases__, _meta, parts} = node, acc
      when parts in [[:Crosswake, :Companions, :Rulestead]] ->
        {node, [node | acc]}
      node, acc ->
        {node, acc}
    end)
    |> elem(1)
  if violations == [], do: :ok, else: {:violation, violations}
end
```

**EXTRACT-04 AST prune-then-walk pattern** (D-16; no analog exists yet — stdlib-only):
```elixir
# Collect def/defp/defmacro body subtrees, then walk for Code.ensure_loaded? nodes.
# A Code.ensure_loaded? node OUTSIDE a function body = violation.
# Belt: raw regex for non-indented occurrence as escalation signal.
def check_ensure_loaded_placement(source_string) do
  {:ok, ast} = Code.string_to_quoted(source_string, [])
  # Step 1: collect all function body ASTs
  # Step 2: find ensure_loaded? nodes in the FULL ast
  # Step 3: assert every ensure_loaded? node is reachable inside a body
  # Belt:
  _belt_matches = Regex.scan(~r/^[^#\n]*Code\.ensure_loaded\?/m, source_string)
end
```

**Failure message pattern** (copy `ProofAssertions.stable_id_message/7` from `test/support/proof_assertions.ex` lines 8-13):
```elixir
alias Crosswake.TestSupport.ProofAssertions

ProofAssertions.stable_id_message(
  "proof.extract_03.static_ref.<file>",   # stable id slug (Claude's Discretion)
  "lib/ must not statically reference an extracted companion",
  "CompanionGuard.assert_no_static_refs!/0",
  "found alias #{inspect(mod)} in #{path}",
  path,
  "remove the static reference — use the :companions registry seam instead (EXTRACT-03)",
  :merge_blocking
)
```

---

### `test/crosswake/proof/phase130_extraction_guards_test.exs` (test, SC#1/SC#3/SC#4)

**Analog:** `test/crosswake/proof/phase129_companion_contract_freeze_test.exs`

**Module/header pattern** (lines 1-14 of phase129 test):
```elixir
defmodule Crosswake.Proof.Phase130ExtractionGuardsTest do
  @moduledoc """
  Merge-blocking proof lane for Phase 130 EXTRACT-01/03/04.
  ...
  Runs UNTAGGED. async: true (read-only source/config). Must NOT carry
  :requires_example_host or :engine_present tags (D-18).
  """

  use ExUnit.Case, async: true

  alias Crosswake.TestSupport.ProofAssertions
  alias Crosswake.CompanionGuard
```

**SC#1 — source assertion pattern** (mirror of phase65 `File.read!(mix_exs_path)` text check at phase65 test lines 36-53):
```elixir
test "core mix.exs contains no MIX_INCLUDE_RULESTEAD block (EXTRACT-01)" do
  source = File.read!(Path.join(File.cwd!(), "mix.exs"))
  refute String.contains?(source, "MIX_INCLUDE_RULESTEAD"),
         ProofAssertions.stable_id_message(...)
  refute String.contains?(source, "MIX_INCLUDE_RINDLE"),
         ProofAssertions.stable_id_message(...)
end
```

**Non-vacuity (positive-control) pattern** (see phase129's inline negative/positive assertion pairs):
```elixir
# Non-vacuity: prove the guard CAN detect a violation
test "CompanionGuard.check_source/1 detects Crosswake.Companions.Rulestead alias — non-vacuity" do
  violating = "alias Crosswake.Companions.Rulestead"
  assert {:violation, _} = CompanionGuard.check_source(violating)
end

test "CompanionGuard.check_source/1 does NOT detect Crosswake.Companions.Sigra alias (legitimate in-tree)" do
  legitimate = "alias Crosswake.Companions.Sigra.Evaluator"
  assert :ok = CompanionGuard.check_source(legitimate)
end
```

**Self-match-avoidance pattern** (phase65 test line 826-837 — the hermetic lane guard at the bottom):
```elixir
# The guard test file itself must not carry @moduletag, must not reference MIX_INCLUDE_*
test "hermetic lane guard: this proof file carries no @moduletag and no env-flag refs" do
  source = File.read!(__ENV__.file)
  refute Regex.match?(~r/^\s*@moduletag\s+:/m, source), "..."
  refute String.contains?(source, "MIX_" <> "INCLUDE_"), "..."
end
```

---

### `test/crosswake/proof/phase130_fail_closed_contract_test.exs` (test, SC#5/COMPAT-01)

**Analog:** `test/crosswake/proof/phase42_rulestead_companion_test.exs` — `Application.put_env` + `RouteGate.evaluate` + `Doctor.run` pattern

**Module/header pattern** (phase42 test lines 1-25):
```elixir
defmodule Crosswake.Proof.Phase130FailClosedContractTest do
  # async: false — Application.put_env(:crosswake, :companions, ...) is a shared global key (D-07, no cache)
  use ExUnit.Case, async: false

  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Compatibility.Target
  alias Crosswake.TestSupport.ProofAssertions
```

**Stub companion pattern** (NOT an alias to the moved source — avoids tripping EXTRACT-03; D-20):
```elixir
# In this test file or test/support/ — plain module implementing @behaviour Crosswake.Companion
defmodule Crosswake.TestSupport.StubDepMissingCompanion do
  @behaviour Crosswake.Companion

  def companion_id, do: :stub_dep_missing
  def enabled?(_config), do: true
  def validate_dependency, do: {:error, [SomeAbsentModule]}
  def route_gated?(_route, _target), do: :pass
  def kill_switch_active?(_target), do: false
  def report_state, do: %Crosswake.Companion.State{
    companion_id: :stub_dep_missing,
    enabled: true,
    dependency_status: {:missing, [SomeAbsentModule]},
    gate_status: :unconfigured,
    kill_switch_status: :unconfigured,
    checked_at: 0
  }
end
```

**`Application.put_env` setup pattern** (phase42 test lines 58-80 — the `setup` block):
```elixir
setup do
  original_companions = Application.get_env(:crosswake, :companions, [])
  original_config = Application.get_env(:crosswake, :stub_dep_missing, %{})

  Application.put_env(:crosswake, :companions, [Crosswake.TestSupport.StubDepMissingCompanion])
  Application.put_env(:crosswake, :stub_dep_missing, %{enabled: true})

  on_exit(fn ->
    Application.put_env(:crosswake, :companions, original_companions)
    Application.put_env(:crosswake, :stub_dep_missing, original_config)
  end)

  :ok
end
```

**RouteGate assertion pattern** (SC#5 + D-02 precedence check):
```elixir
test "RouteGate denies with :dependency_missing when companion dep absent (COMPAT-01 SC#5)" do
  # Build a minimal manifest with a route gated_by :stub_dep_missing
  # ... manifest setup ...
  decision = RouteGate.evaluate(manifest, "gating-route", target)
  assert decision.status == :deny
  assert decision.denial.reason == :dependency_missing
  assert decision.denial.details["missing_kind"] == "engine_unvalidated"
end

test "dependency_missing precedes kill_switch_active (D-02 precedence)" do
  # Same setup but stub also returns kill_switch_active?: true
  # Denial must still be :dependency_missing, not :kill_switch_active
  decision = RouteGate.evaluate(manifest, "gating-route", target)
  assert decision.denial.reason == :dependency_missing
end

test "validate_dependency/0 raising an exception still produces :dependency_missing (D-08)" do
  # Stub whose validate_dependency raises — RouteGate try/rescue fires
  decision = RouteGate.evaluate(manifest, "gating-route", target)
  assert decision.denial.reason == :dependency_missing
end
```

---

### `packages/crosswake_rulestead/mix.exs` (config, package skeleton)

**Analog:** Core `mix.exs` lines 1-82 — structure, `elixirc_paths`, `files:` allowlist, `package/0`, `deps/0`

**Critical differences from core (D-19, D-21, D-22, D-28, D-29):**

```elixir
defmodule CrosswakeRulestead.MixProject do
  use Mix.Project

  @version "0.1.0"  # x-release-please-version — D-22: separate from core 0.1.2

  def project do
    [
      app: :crosswake_rulestead,
      version: @version,
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      ...
    ]
  end

  # Mirror core's pattern (mix.exs lines 35-36):
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # D-19: NO runtime: false — core is a RUNTIME dep of the companion
      {:crosswake, path: "../.."},
      # D-28: optional: true — Swoosh gold-standard optional-dep idiom
      {:rulestead, "~> 0.1", optional: true}
    ]
  end

  defp package do
    [
      name: "crosswake_rulestead",
      licenses: ["Apache-2.0"],
      links: %{...},
      # D-24: test/ EXCLUDED from files: allowlist (verify with mix hex.build --unpack)
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end
end
```

**D-27 guard — no `runtime: false` on core dep:** assert in the phase130 guard test:
```elixir
test "crosswake_rulestead mix.exs: {:crosswake, path:} dep carries no runtime: false (D-27)" do
  source = File.read!(Path.join(File.cwd!(), "packages/crosswake_rulestead/mix.exs"))
  refute String.contains?(source, "runtime: false"),
         ProofAssertions.stable_id_message(...)
end
```

---

### `packages/crosswake_rulestead/lib/crosswake/companions/rulestead.ex` (service, moved)

**Analog:** `lib/crosswake/companions/rulestead.ex` — the file being moved verbatim with two required modifications.

**`@compile` directive** — REQUIRED at top of module (D-29; not in the original because the engine was pulled via MIX_INCLUDE_RULESTEAD):
```elixir
# Required: optional: true alone does NOT silence undefined-module warning (D-29)
@compile {:no_warn_undefined, Rulestead}
```

**Config-indirection for MockFlagSource** (D-31) — replace direct `alias MockFlagSource` with config read:
```elixir
# Replace: alias Crosswake.Companions.Rulestead.MockFlagSource
# With: read from Application config (lib/ never references test module)
defp flag_source do
  Application.compile_env(:crosswake, [:rulestead, :flag_source], nil)
end
```

**`validate_dependency/0`** (rulestead.ex lines 99-108 — copy verbatim, already EXTRACT-04-clean):
```elixir
@impl true
def validate_dependency do
  if Code.ensure_loaded?(Rulestead) do
    :ok
  else
    {:error, [Rulestead]}
  end
end
```

---

### `packages/crosswake_rulestead/test/support/study_session_live.ex` (utility, copy)

**Analog:** `test/support/router_fixtures.ex` lines 40-46 — copy verbatim (D-23):
```elixir
defmodule Crosswake.TestSupport.StudySessionLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"<div>study session</div>"
  end
end
```

---

### `script/verify_companion_package.sh` (utility, batch)

**Analog:** `.github/workflows/phase43-proof.yml` for shell structure; D-24 specifies the three assertions.

**Pattern** (parameterized for rindle reuse in Phase 132):
```bash
#!/usr/bin/env bash
# Usage: ./script/verify_companion_package.sh crosswake_rulestead
set -euo pipefail
PACKAGE="${1:-crosswake_rulestead}"
PKG_DIR="packages/$PACKAGE"
UNPACK_DIR="/tmp/${PACKAGE}_unpack"

cd "$PKG_DIR"

# 1. Build and unpack — verify files: allowlist excludes test/
mix hex.build --unpack -o "$UNPACK_DIR"
if [ -d "$UNPACK_DIR/test" ]; then
  echo "[crosswake] FAIL: test/ directory found in unpacked tarball — exclude from files: allowlist"
  exit 1
fi
if [ ! -f "$UNPACK_DIR/lib/crosswake/companions/rulestead.ex" ]; then
  echo "[crosswake] FAIL: lib/ source not found in unpacked tarball"
  exit 1
fi

# 2. Dry-run publish — catch "works locally but breaks on Hex" errors
mix hex.publish --dry-run

# 3. Compile in engine-ABSENT state (hermetic; requires @compile {:no_warn_undefined, Rulestead})
mix compile --warnings-as-errors

echo "[crosswake] verify_companion_package: $PACKAGE OK"
```

---

### `lib/crosswake/compatibility/route_gate.ex` (modify — COMPAT-01 enforcement)

**Analog:** Self — `route_gate.ex` lines 121-147 (`check_kill_switches/3` inline Denial synthesis). Mirror this pattern for the dependency-missing denial in `prepend_gate_evaluation_findings/3`.

**Injection site** (lines 100-119, gated-route clause):
```elixir
# Current gated-route clause (lines 100-119):
defp prepend_gate_evaluation_findings(acc, %RouteEntry{} = route, %Target{} = target) do
  companions =
    Application.get_env(:crosswake, :companions, [])
    |> Enum.filter(fn companion ->
      config = Application.get_env(:crosswake, companion.companion_id(), %{})
      companion.enabled?(config)
    end)

  case check_kill_switches(companions, route, target) do
    {:kill_switch, denial} ->
      [denial | acc]
    :pass ->
      case check_gate(companions, route, target) do
        {:gate_denied, denial} -> [denial | acc]
        :pass -> acc
      end
  end
end
```

**New dep check — insert BEFORE `check_kill_switches`** (D-02 precedence: `dependency_missing → kill_switch_active → gate_denied`):
```elixir
# New check_dependencies/2 — inline Denial synthesis mirroring check_kill_switches (lines 134-142)
defp check_dependencies(companions, route) do
  Enum.reduce_while(companions, :pass, fn companion, _acc ->
    {result, missing_kind} =
      try do
        case companion.validate_dependency() do
          :ok -> {:ok, nil}
          {:error, _mods} -> {{:error, nil}, :engine_unvalidated}
        end
      rescue
        _ -> {{:error, nil}, :adapter_unloadable}
      catch
        _ -> {{:error, nil}, :adapter_unloadable}
      end

    case result do
      {:error, _} ->
        denial =
          Denial.new(
            reason: :dependency_missing,
            message:
              "[crosswake] companion #{companion.companion_id()} is registered and enabled " <>
              "but its dependency is not loaded. The gate fails closed.",
            route_id: route.id,
            details: %{
              "companion_id" => Atom.to_string(companion.companion_id()),
              "missing_kind" => Atom.to_string(missing_kind)
            }
          )
        {:halt, {:dependency_missing, denial}}
      :ok ->
        {:cont, :pass}
    end
  end)
end
```

**Updated flow** in `prepend_gate_evaluation_findings/3`:
```elixir
# D-02 precedence: dependency_missing → kill_switch_active → gate_denied
case check_dependencies(companions, route) do
  {:dependency_missing, denial} -> [denial | acc]
  :pass ->
    case check_kill_switches(companions, route, target) do
      {:kill_switch, denial} -> [denial | acc]
      :pass ->
        case check_gate(companions, route, target) do
          {:gate_denied, denial} -> [denial | acc]
          :pass -> acc
        end
    end
end
```

**Telemetry span** — wrap `check_dependencies` in `:telemetry.span` as `[:crosswake, :companion, :dependency_check]` (mirror the `:validate_dependency` span in doctor.ex lines 572-580, which uses the same event name; carry `:exception` metadata on rescue per D-08).

---

### `lib/crosswake/shell/denial.ex` (modify — add `:dependency_missing`)

**Analog:** Self — `denial.ex` lines 14-44. Extend two locations:

**`@reasons` list** (lines 14-27 — add as 13th entry):
```elixir
@reasons [
  :compatibility_mismatch,
  :undeclared_capability,
  :unavailable_capability,
  :commerce_corridor,
  :origin_denied,
  :inactive_route,
  :external_entry_denied,
  :pack_incompatible,
  :gate_denied,
  :kill_switch_active,
  :step_up_required,
  :notification_open_denied,
  :dependency_missing          # Phase 130: COMPAT-01 RouteGate fail-closed
]
```

**`@type reason`** (lines 32-44 — add union branch):
```elixir
@type reason ::
        :compatibility_mismatch
        | :undeclared_capability
        | ...
        | :notification_open_denied
        | :dependency_missing
```

**After this change, run `mix crosswake.contract.gen`** to regenerate:
- `test/fixtures/bridge_contract_vectors.json`
- `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json`
- `packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json`

**Also update** `test/crosswake/doctor/doctor_test.exs` lines 107-121 — add `"dependency_missing"` to the hardcoded `Enum.sort([...])` list.

---

### `lib/crosswake/doctor/doctor.ex` (modify — branch on `missing_kind`)

**Analog:** Self — `doctor.ex` lines 564-618 (`phase_38_companion_seam_findings/0`). The existing `{true, {:error, mods}}` branch already emits `"companion.dependency_missing"` and `%{missing_modules: mods}` in details. New work: add `missing_kind` branching per D-06.

**Existing branch** (lines 582-597 — extend, do not replace):
```elixir
{true, {:error, mods}} ->
  mod_names = Enum.map_join(mods, ", ", &inspect/1)
  # D-06: infer missing_kind from the failure context
  # :engine_unvalidated = validate_dependency/0 returned {:error, _}
  # The doctor always calls validate_dependency/0 directly, so this branch
  # is always :engine_unvalidated at the cold path.
  [
    check(
      :error,
      "companion.dependency_missing",
      "companion.#{companion_id}",
      "[crosswake] Companion #{inspect(companion_id)} is enabled but its dependency " <>
        "is not loaded: #{mod_names}. Companion dependencies are not pulled transitively; " <>
        "the host app must declare them explicitly.",
      "Add #{mod_names} to your application's deps in mix.exs.",
      %{missing_modules: mods, missing_kind: :engine_unvalidated}
    )
  ]
```

**D-05 confirmed:** Code string `"companion.dependency_missing"` is the same string used by both the doctor (cold) and RouteGate (hot). No translation table — grep for this string to find both surfaces.

---

### `mix.exs` (modify — delete MIX_INCLUDE_* + add aliases)

**Analog:** Self — `mix.exs` lines 38-63 (the blocks to delete) and the `aliases/0` pattern.

**Delete** (lines 48-62):
```elixir
# DELETE both of these blocks entirely (D-21):
rulestead =
  if System.get_env("MIX_INCLUDE_RULESTEAD") == "1" do
    [{:rulestead, "~> 0.1.6"}]
  else
    []
  end

rindle =
  if System.get_env("MIX_INCLUDE_RINDLE") == "1" do
    [{:rindle, "~> 0.1"}]
  else
    []
  end

base ++ rulestead ++ rindle
# Replace with just:
base
```

**Add aliases** (D-26 — `mix companions.test` + `mix verify` umbrella):
```elixir
defp aliases do
  [
    "companions.test": ["cmd --cd packages/crosswake_rulestead mix test"],
    "verify": [
      "companions.test",
      "test --exclude requires_example_host --exclude advisory_only"
    ]
  ]
end
```

---

## Shared Patterns

### ProofAssertions.stable_id_message/7
**Source:** `test/support/proof_assertions.ex` lines 8-13
**Apply to:** Both guard test files, all assertion failure messages
```elixir
def stable_id_message(id, subject, source, observed, path, hint, posture) do
  "[#{id}] subject=#{subject} source=#{source} observed=#{observed} path=#{path} hint=#{hint} posture=#{posture}"
  |> String.trim()
end
```

### Inline Denial Synthesis
**Source:** `lib/crosswake/compatibility/route_gate.ex` lines 134-142 (`check_kill_switches` Denial.new call)
**Apply to:** New `check_dependencies/2` function in `route_gate.ex`
```elixir
denial =
  Denial.new(
    reason: :kill_switch_active,   # replace with :dependency_missing
    message: "kill switch active for companion #{companion.companion_id()}",
    route_id: route.id,
    details: %{"companion_id" => Atom.to_string(companion.companion_id())}
  )
```

### AST Source Assertion Pattern
**Source:** `test/crosswake/proof/phase129_companion_contract_freeze_test.exs` + `phase65_diagnostic_export_seam_test.exs` (File.read! + String.contains? + Regex.match?)
**Apply to:** `phase130_extraction_guards_test.exs` (SC#1 mix.exs text assertion), `CompanionGuard.check_source/1` (SC#3 AST walk)

### Application.put_env / on_exit Cleanup Pattern
**Source:** `test/crosswake/proof/phase42_rulestead_companion_test.exs` setup block (lines 58-80)
**Apply to:** `phase130_fail_closed_contract_test.exs` — save/restore `:companions` and companion config keys

### Hermetic Lane Guard (self-assertion at bottom of file)
**Source:** `test/crosswake/proof/phase65_diagnostic_export_seam_test.exs` lines 826-837
**Apply to:** Both phase130 proof test files — assert no @moduletag, no MIX_INCLUDE_*, no :requires_example_host

### `elixirc_paths(:test)` + `files:` allowlist
**Source:** `mix.exs` lines 35-36 + 78
**Apply to:** `packages/crosswake_rulestead/mix.exs` — same structure; `files:` must exclude `test/`

---

## No Analog Found

None. All artifacts have close analogs in the existing codebase or are direct moves/modifications of existing files.

---

## Planner Checklist Notes

1. **D-10 resolved:** No changes to `transition_for_non_notification_denial/2`. Dep-missing Denial synthesized in `prepend_gate_evaluation_findings/3` only.
2. **D-04 exhaustive sites:** After modifying `denial.ex` — manually update `doctor_test.exs:107-121` list + run `mix crosswake.contract.gen` for 3 JSON fixtures.
3. **D-32:** `validate_dependency/0` at `rulestead.ex:99-108` already exists and is EXTRACT-04-clean. No reimplementation needed.
4. **Missing `@compile {:no_warn_undefined, Rulestead}` is a footgun:** Required in `packages/crosswake_rulestead/lib/crosswake/companions/rulestead.ex` for `mix compile --warnings-as-errors` to pass in the engine-ABSENT state.
5. **`runtime: false` on `{:crosswake, path:}` dep is WRONG:** The D-27 guard test asserts its absence.

## Metadata

**Analog search scope:** `lib/`, `test/crosswake/proof/`, `test/support/`, `mix.exs`, `lib/crosswake/doctor/doctor.ex`
**Files scanned:** 10
**Pattern extraction date:** 2026-06-25
