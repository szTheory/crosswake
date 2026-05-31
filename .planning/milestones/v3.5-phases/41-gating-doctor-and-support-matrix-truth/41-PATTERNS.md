# Phase 41: Gating Doctor And Support-Matrix Truth - Pattern Map

**Mapped:** 2026-05-30
**Files analyzed:** 4 new/modified files
**Analogs found:** 4 / 4

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/crosswake/doctor/doctor.ex` | service (diagnostic) | batch/transform | `lib/crosswake/doctor/doctor.ex` phase_38 and phase_19 functions (self) | exact |
| `lib/crosswake/companion/state.ex` | model (typespec) | — | `lib/crosswake/manifest/types.ex` RouteEntry on_unavailable typespec | role-match |
| `lib/crosswake/support_matrix/support_matrix.ex` | service (data table) | request-response | `lib/crosswake/support_matrix/support_matrix.ex` commerce_corridors/0 (self) | exact |
| `test/crosswake/proof/phase41_gating_doctor_test.exs` | test (hermetic proof) | batch | `test/crosswake/proof/phase38_companion_contract_test.exs` + `phase40_gate_evaluation_test.exs` | exact |

---

## Pattern Assignments

### `lib/crosswake/doctor/doctor.ex` — add `phase_41_gating_findings/1`

**Analog:** Same file — `phase_19_commerce_corridor_posture/1` (lines 486-501) and `phase_38_companion_seam_findings/0` (lines 514-568)

**Nil-guard pattern** (lines 486-487 — every manifest-receiving phase function follows this):
```elixir
defp phase_19_commerce_corridor_posture(nil), do: []

defp phase_19_commerce_corridor_posture(manifest) do
  ...
end
```
Phase 41 must replicate exactly:
```elixir
defp phase_41_gating_findings(nil), do: []
defp phase_41_gating_findings(manifest) do ... end
```

**Per-route flat_map iteration pattern** (lines 488-501):
```elixir
defp phase_19_commerce_corridor_posture(manifest) do
  manifest.routes
  |> Map.values()
  |> Enum.filter(&(not is_nil(&1.commerce)))
  |> Enum.flat_map(fn route ->
    # ... per-route findings
  end)
end
```
Phase 41 mirrors this, filtering on `gated_by != nil`:
```elixir
defp phase_41_gating_findings(manifest) do
  companion_ids =
    Application.get_env(:crosswake, :companions, [])
    |> Enum.map(& &1.companion_id())
    |> MapSet.new()

  manifest.routes
  |> Map.values()
  |> Enum.filter(&(not is_nil(&1.gated_by)))
  |> Enum.flat_map(fn route ->
    # ... per-route findings (see Check struct pattern below)
  end)
end
```

**Companion list iteration pattern** (lines 514-518 — for building the known companion_ids set):
```elixir
defp phase_38_companion_seam_findings do
  companions = Application.get_env(:crosswake, :companions, [])

  Enum.flat_map(companions, fn companion ->
    companion_id = companion.companion_id()
    ...
  end)
end
```
Phase 41 uses `Application.get_env(:crosswake, :companions, [])` only to build the MapSet of known companion_ids; it does NOT call `validate_dependency/0` or `report_state/0` from within this function (see Pitfall 2 in RESEARCH.md — Phase 38 calls `validate_dependency/0`, not `report_state/0`; `report_state/0` is called only by `SupportMatrix.gating_truth/0`).

**check/6 helper pattern** (line 1408):
```elixir
defp check(severity, code, check_name, message, hint, details \\ %{}) do
  %Check{
    severity: severity,
    code: code,
    check: check_name,
    message: message,
    hint: hint,
    details: details
  }
end
```
All findings are constructed via this private helper. Phase 41 calls it with:
- `:advisory` severity for gated-route info findings (see RESEARCH.md Pitfall 1 — `:info` is not in `Check.severity()` typespec; use `:advisory` unless the planner extends the type)
- `:error` for `"gating.flag_reference_unknown"`
- `:warning` for `"gating.fallback_route_unknown"`

**Finding code naming convention** (lines 539, 552 and existing strings in doctor.ex):
```elixir
"companion.dependency_missing"
"companion.disabled_dependency_present"
"commerce.corridor.undeclared"
"commerce.corridor.prerequisite_missing"
```
Pattern: `"<category>.<specific_problem>"`. Phase 41 uses:
- `"gating.route_registered"` (or `"gating.route_gated"`) — `:advisory` per-route info
- `"gating.flag_reference_unknown"` — `:error` unresolvable flag ref
- `"gating.fallback_route_unknown"` — `:warning` fallback target not in manifest

**check_name field convention** (lines 540, 553, 558):
```elixir
# Phase 38 uses "companion.<companion_id>":
"companion.#{companion_id}"
```
Phase 41 should use `"gating.#{route.id}"` as the check name for consistency with the per-entity naming pattern.

**Findings accumulation wiring in `run/1`** (lines 130-136):
```elixir
phase_38_findings = phase_38_companion_seam_findings()

findings =
  findings ++
    phase_3_findings ++
    phase_4_findings ++
    phase_10_findings ++ phase_19_findings ++ phase_23_findings ++ phase_38_findings
```
Phase 41 must add:
```elixir
phase_41_findings = phase_41_gating_findings(manifest)

findings =
  findings ++
    phase_3_findings ++
    phase_4_findings ++
    phase_10_findings ++ phase_19_findings ++ phase_23_findings ++ phase_38_findings ++
    phase_41_findings
```
Call site should come after Phase 38 (reads same Application env, conceptually follows dependency check).

---

### `lib/crosswake/companion/state.ex` — extend `gate_status` typespec

**Analog:** `lib/crosswake/manifest/types.ex` — `RouteEntry.on_unavailable` tagged-tuple typespec (lines 230-231)

**Existing typespec to extend** (lines 8-9 of state.ex):
```elixir
@type gate_status :: :active | :inactive | :unconfigured
@type kill_switch_status :: :inactive | :active | :unconfigured
```

**Tagged-tuple analog from RouteEntry** (`lib/crosswake/manifest/types.ex` line 231):
```elixir
on_unavailable: :deny | {:fallback_phoenix, atom()} | nil
```
This confirms the project's convention: tagged tuples with a discriminant atom + typed payload. The `{:rolling_out, non_neg_integer()}` arm follows this exact pattern.

**Extended typespec** (additive, no struct field changes):
```elixir
@type gate_status :: :active | :inactive | :unconfigured | {:rolling_out, non_neg_integer()}
```
The `t()` struct references `gate_status()` by name — it automatically inherits the extended union. `kill_switch_status` is unchanged (D-07).

---

### `lib/crosswake/support_matrix/support_matrix.ex` — add `gating_truth/0`

**Analog:** Same file — `commerce_corridors/0` (lines 232-233) and `commerce_corridor_proof_classes/0` (lines 265-273)

**Module-level accessor pattern** (lines 232-233):
```elixir
@spec commerce_corridors() :: [map()]
def commerce_corridors, do: @commerce_corridor_entries
```

**Derived-computation accessor pattern** (lines 265-273):
```elixir
@spec commerce_corridor_proof_classes() :: %{...}
def commerce_corridor_proof_classes do
  Map.new(@commerce_corridor_entries, fn entry ->
    {entry.corridor_role,
     %{
       proof_class: entry.proof_class,
       advisory_provider_proof: entry.advisory_provider_proof
     }}
  end)
end
```

**Phase 41 gating_truth/0 should follow the derived-computation pattern** (reads Application env at call time, not a module attribute, because companion list is runtime-registered):
```elixir
@spec gating_truth() :: [map()]
def gating_truth do
  Application.get_env(:crosswake, :companions, [])
  |> Enum.map(fn companion ->
    state = companion.report_state()
    %{
      companion_id: state.companion_id,
      gate_state: gate_state_display(state)
    }
  end)
end

defp gate_state_display(%Crosswake.Companion.State{kill_switch_status: :active}), do: "killed"
defp gate_state_display(%Crosswake.Companion.State{gate_status: :active}), do: "gated"
defp gate_state_display(%Crosswake.Companion.State{gate_status: {:rolling_out, n}}), do: "rolling_out (#{n}%)"
defp gate_state_display(%Crosswake.Companion.State{gate_status: :inactive}), do: nil
defp gate_state_display(%Crosswake.Companion.State{gate_status: :unconfigured}), do: nil
```
The D-08 kill-switch precedence is enforced by clause ordering — the `:active` kill switch clause must come first.

---

### `test/crosswake/proof/phase41_gating_doctor_test.exs` — new hermetic proof file

**Analog:** `test/crosswake/proof/phase38_companion_contract_test.exs` (module header, setup block, Application.put_env/on_exit pattern) and `test/crosswake/proof/phase40_gate_evaluation_test.exs` (inline defmodule companion fixtures, GatedRouteRouter pattern)

**Module header and async declaration** (phase38 lines 1-26):
```elixir
defmodule Crosswake.Proof.Phase41GatingDoctorTest do
  @moduledoc """
  Hermetic merge-blocking proof lane for Phase 41 gating doctor and support-matrix truth.
  ...
  """

  # async: false — shared Application.put_env(:crosswake, :companions, ...) key
  use ExUnit.Case, async: false

  alias Crosswake.Doctor
  alias Crosswake.SupportMatrix
end
```

**Temp-dir setup block** (phase38 lines 47-89 — copy this entire block):
```elixir
setup do
  target =
    Path.join(
      System.tmp_dir!(),
      "crosswake-phase41-proof-#{System.unique_integer([:positive])}"
    )

  router_path = Path.join(target, "lib/demo_web/router.ex")
  policy_path = Path.join(target, "lib/demo_web/crosswake/policy.ex")
  install_manifest_path = Path.join(target, "priv/crosswake/install_manifest.json")

  File.mkdir_p!(Path.dirname(router_path))
  File.mkdir_p!(Path.dirname(policy_path))
  File.mkdir_p!(Path.dirname(install_manifest_path))

  # Write router, policy, install_manifest (same as phase38 lines 62-87)
  ...

  %{target: target, install_manifest_path: install_manifest_path}
end
```

**Inline companion fixture pattern** (phase40 lines 46-125):
```elixir
defmodule GatingActiveCompanion do
  @behaviour Crosswake.Companion
  @impl true; def companion_id, do: :test_gating_companion
  @impl true; def enabled?(_config), do: true
  @impl true; def route_gated?(_route, _target), do: :pass
  @impl true; def kill_switch_active?(_target), do: false
  @impl true; def validate_dependency, do: :ok
  @impl true
  def report_state do
    %Crosswake.Companion.State{
      companion_id: :test_gating_companion,
      enabled: true,
      dependency_status: :present,
      gate_status: :active,
      kill_switch_status: :inactive,
      checked_at: System.monotonic_time(:millisecond)
    }
  end
end
```
Phase 41 needs at minimum: one companion with `gate_status: :active`, one with `gate_status: {:rolling_out, 10}`, and one with `kill_switch_status: :active` (to test the "killed" override).

**Application.put_env + on_exit pattern** (phase38 lines 148-151):
```elixir
Application.put_env(:crosswake, :companions, [SomeFixtureCompanion])

on_exit(fn ->
  Application.delete_env(:crosswake, :companions)
end)
```
Every test that writes `:companions` must pair with this cleanup. Multiple companions: `[CompanionA, CompanionB]`.

**Gated router with inline DSL** (phase40 lines 131-156 — copy and adapt):
```elixir
defmodule GatedRouteRouter do
  use Crosswake.Router

  scope "/" do
    crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
      live "/gated", Crosswake.TestSupport.StudySessionLive,
        crosswake: [id: "gated", runtime: :live_view, gated_by: :test_gating_companion]
    end
  end
end
```
For fallback validation tests, use `on_unavailable: {:fallback_phoenix, :home}` and ensure the manifest either has or lacks a `:home` route to exercise both the hint and the `:warning` path.

**Hermeticity self-assertion** (phase38 lines 95-103, phase40 lines 183-191 — copy pattern verbatim):
```elixir
test "phase 41 gating doctor proof stays hermetic — no example-host or Code.require_file dependency" do
  source = File.read!(__ENV__.file) |> String.downcase()

  refute String.contains?(source, "crosswake" <> "example.router"),
         "phase 41 gating proof must not depend on the example host router"

  refute Regex.match?(~r/code\.require_file\s*\(/, source),
         "phase 41 gating proof must not Code.require_file example-host modules"
end
```

---

## Shared Patterns

### Check struct construction
**Source:** `lib/crosswake/doctor/doctor.ex` lines 1408-1417
**Apply to:** All three finding types in `phase_41_gating_findings/1`
```elixir
defp check(severity, code, check_name, message, hint, details \\ %{}) do
  %Check{
    severity: severity,
    code: code,
    check: check_name,
    message: message,
    hint: hint,
    details: details
  }
end
```
The `hint` field (not `details`) carries the `{:fallback_phoenix, route_id}` posture note per D-09.

### Application.get_env companion registry access
**Source:** `lib/crosswake/doctor/doctor.ex` line 515, `test/crosswake/proof/phase38_companion_contract_test.exs` line 148
**Apply to:** `phase_41_gating_findings/1`, `SupportMatrix.gating_truth/0`, and proof test setup
```elixir
Application.get_env(:crosswake, :companions, [])
```
Never `Application.compile_env` — must be runtime-readable so tests can register fixture companions via `put_env`.

### RouteEntry gated_by and on_unavailable field shapes
**Source:** `lib/crosswake/manifest/types.ex` lines 206-231
```elixir
# RouteEntry struct fields:
:gated_by,           # atom() | nil
:on_unavailable,     # :deny | {:fallback_phoenix, atom()} | nil

@type t :: %__MODULE__{
  ...
  gated_by: atom() | nil,
  on_unavailable: :deny | {:fallback_phoenix, atom()} | nil
}
```
- Filter gated routes: `Enum.filter(&(not is_nil(&1.gated_by)))`
- Extract fallback id: pattern match `{:fallback_phoenix, fallback_id} = route.on_unavailable`
- Check fallback route exists: `Map.has_key?(manifest.routes, to_string(fallback_id))` (routes map is keyed by string route id)

### Inline companion behaviour implementation
**Source:** `test/support/stub_companion.ex` lines 1-31, `test/crosswake/proof/phase40_gate_evaluation_test.exs` lines 46-85
**Apply to:** All inline fixture companion modules in phase41 proof test
```elixir
defmodule FixtureCompanion do
  @behaviour Crosswake.Companion
  @impl true; def companion_id, do: :some_atom
  @impl true; def enabled?(_config), do: true
  @impl true; def route_gated?(_route, _target), do: :pass
  @impl true; def kill_switch_active?(_target), do: false
  @impl true; def validate_dependency, do: :ok
  @impl true
  def report_state do
    %Crosswake.Companion.State{
      companion_id: :some_atom,
      enabled: true,
      dependency_status: :present,
      gate_status: :unconfigured,          # override for each fixture
      kill_switch_status: :unconfigured,   # override for each fixture
      checked_at: System.monotonic_time(:millisecond)
    }
  end
end
```

---

## Critical Pitfalls (from RESEARCH.md)

### :info severity not in Check.severity() type
**Source:** `lib/crosswake/doctor/check.ex` line 9
```elixir
@type severity :: :error | :warning | :advisory
```
`:info` is absent. D-03 uses `:info` language but `:advisory` is the closest existing atom and shares the same semantics ("without implying a problem"). **Planner must choose: extend `Check.severity()` to add `:info` and update the formatter's `severity_order/1`, or use `:advisory` directly.** Using `:advisory` requires no formatter changes.

### kill-switch display clause ordering
In `gate_state_display/1`, the `kill_switch_status: :active` clause must appear BEFORE the `gate_status` clauses to enforce D-08 kill-switch precedence. Elixir pattern matches in declaration order.

### on_unavailable nil vs :deny display
`nil` means "not set" (implicit fail-closed); `:deny` means explicitly declared. Finding message should distinguish these to avoid misrepresenting the route's actual posture.

---

## No Analog Found

All files have close analogs in the codebase. No new infrastructure is required.

---

## Metadata

**Analog search scope:** `lib/crosswake/doctor/`, `lib/crosswake/companion/`, `lib/crosswake/support_matrix/`, `lib/crosswake/manifest/`, `test/crosswake/proof/`, `test/support/`
**Files scanned:** 8 source files read directly
**Pattern extraction date:** 2026-05-30
