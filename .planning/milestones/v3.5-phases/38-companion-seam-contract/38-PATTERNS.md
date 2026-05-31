# Phase 38: Companion Seam Contract - Pattern Map

**Mapped:** 2026-05-29
**Files analyzed:** 6 (3 create, 2 modify, 1 test-support fixture + 1 proof test)
**Analogs found:** 6 / 6

## Line Number Verification (CONTEXT.md claims vs. actual)

All line numbers cited in CONTEXT.md verified correct against the codebase:

| CONTEXT.md claim | Actual location | Status |
|---|---|---|
| `doctor.ex` `run/1` at ~line 113 | line 113 | CORRECT |
| `Report.status` derivation at ~line 137 | line 137 | CORRECT |
| `phase_19_commerce_corridor_posture` private fn | lines 484–499 | CORRECT |
| `Compatibility.Target` at ~line 14 | line 14 | CORRECT |
| `Compatibility.Finding` at ~line 40 | line 40 | CORRECT |
| `Manifest.Types.RouteEntry` at ~line 192 | line 192 | CORRECT |
| `support_matrix.ex` `:companion` package surface at ~line 375 | line 375 | CORRECT |
| `support_matrix.ex` `:companion` release boundary at ~line 414 | line 414 | CORRECT |

No discrepancies found.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/companion.ex` | behaviour | request-response | `lib/crosswake/commerce.ex` | exact-role |
| `lib/crosswake/companion/state.ex` | model (typed struct) | transform | `lib/crosswake/commerce/contracts.ex` (`@enforce_keys` + `@type t`) + `lib/crosswake/compatibility/compatibility.ex` (`Target`, `Finding`) | exact-role |
| `lib/crosswake/doctor/doctor.ex` (modify) | service | request-response | self — mirror `phase_19_commerce_corridor_posture` (lines 484–499) | exact |
| `mix.exs` (modify) | config | — | self — existing `deps/0` block (lines 38–46) | exact |
| `test/support/<name>_companion.ex` | test-support fixture | — | `test/support/router_fixtures.ex`, `test/support/compile_router_case.ex` | role-match |
| `test/crosswake/proof/phase38_companion_contract_test.exs` | test | request-response | `test/crosswake/proof/phase33_commerce_corridor_routes_test.exs`, `test/crosswake/proof/phase23_commerce_support_proof_test.exs` | exact-role |

---

## Pattern Assignments

### `lib/crosswake/companion.ex` (behaviour, request-response)

**Analog:** `lib/crosswake/commerce.ex`

**Imports pattern** (lines 1–6):
```elixir
defmodule Crosswake.Commerce do
  @moduledoc """
  Thin behaviour/orchestration seam for Phoenix-owned commerce intent and snapshot hooks.
  """

  alias Crosswake.Commerce.Contracts
```

**Core behaviour callback pattern** (lines 1–28, full file):
```elixir
# Each callback is preceded by a @doc string.
# Return types are closed atom-or-tagged-tuple — no bare `term()`.
# No `use` macro, no `__using__/1` — pure @behaviour + @callback declarations.

@callback submit_purchase_intent(Contracts.PurchaseIntent.t()) :: :ok | {:error, term()}

@callback ingest_reconciliation_evidence(Contracts.ReconciliationEvidence.t()) ::
            {:ok, Crosswake.Commerce.Reconciliation.EvidenceResult.t()} | {:error, term()}

@callback fetch_entitlement_snapshot(String.t()) :: {:ok, Contracts.EntitlementSnapshot.t()} | {:error, term()}
```

**Adaptation for `Crosswake.Companion`:** Six callbacks from D-05 replace the four commerce callbacks. The module alias block must add the three referenced namespaces:
```elixir
alias Crosswake.Companion.State
alias Crosswake.Compatibility.Finding
alias Crosswake.Compatibility.Target
alias Crosswake.Manifest.Types.RouteEntry
```

The locked callback typespecs from D-05 (verified module names exist in codebase):
```elixir
@callback companion_id() :: atom()
@callback enabled?(config :: map()) :: boolean()
@callback route_gated?(route :: RouteEntry.t(),
                       context :: Target.t()) ::
            {:deny, Finding.t()} | :pass
@callback kill_switch_active?(context :: Target.t()) :: boolean()
@callback validate_dependency() :: :ok | {:error, [module()]}
@callback report_state() :: State.t()
```

---

### `lib/crosswake/companion/state.ex` (model/typed struct, transform)

**Primary analog:** `lib/crosswake/commerce/contracts.ex` — `@enforce_keys` + `@type t` idiom.

**`@enforce_keys` + `defstruct` + `@type t` pattern** (contracts.ex lines 19–28, `PurchaseIntent` as minimal example):
```elixir
defmodule PurchaseIntent do
  @moduledoc false
  @enforce_keys [:entry_id, :correlation_id]
  defstruct [:entry_id, :correlation_id]

  @type t :: %__MODULE__{
          entry_id: String.t(),
          correlation_id: String.t()
        }
end
```

**Status-atom field pattern** (contracts.ex lines 44–60, `AuthorityLane.state` type):
```elixir
@type state ::
        :none
        | :active
        | :grace
        | :billing_retry
        | :canceled_scheduled_end
        | :revoked
        | :refunded
        | :expired
```

**Timestamp field pattern** (contracts.ex `FreshnessLane` lines 96–108):
```elixir
@enforce_keys [:state, :checked_at]
defstruct [:state, :checked_at, :stale_after]

@type t :: %__MODULE__{
        state: state(),
        checked_at: String.t(),
        stale_after: String.t() | nil
      }
```

**Adaptation for `Crosswake.Companion.State`:** The struct is a top-level module (not nested), uses `non_neg_integer()` for `checked_at` (monotonic ms), and has an optional `details: %{}` escape hatch matching the `Check` struct's own `details: %{}` field. From D-09:
```elixir
defmodule Crosswake.Companion.State do
  @moduledoc false
  @enforce_keys [:companion_id, :enabled, :dependency_status, :gate_status, :kill_switch_status, :checked_at]
  defstruct [:companion_id, :enabled, :dependency_status, :gate_status, :kill_switch_status, :checked_at, details: %{}]

  @type dependency_status :: :present | {:missing, [module()]}
  @type gate_status :: :active | :inactive | :unconfigured
  @type kill_switch_status :: :inactive | :active | :unconfigured

  @type t :: %__MODULE__{
          companion_id: atom(),
          enabled: boolean(),
          dependency_status: dependency_status(),
          gate_status: gate_status(),
          kill_switch_status: kill_switch_status(),
          checked_at: non_neg_integer(),
          details: map()
        }
end
```

**Secondary analog for `details: %{}` default field:** `lib/crosswake/doctor/check.ex` line 7:
```elixir
defstruct [:severity, :code, :message, :hint, :check, details: %{}]
```
This is the only other struct in the codebase with a `details: %{}` default — use the same default-in-defstruct idiom.

---

### `lib/crosswake/doctor/doctor.ex` — add `phase_38_companion_seam_findings/0` (modify)

**Analog (exact):** `phase_19_commerce_corridor_posture/1` in the same file, lines 484–499.

**Full shape of the analog function:**
```elixir
# line 484
defp phase_19_commerce_corridor_posture(nil), do: []

# line 486
defp phase_19_commerce_corridor_posture(manifest) do
  manifest.routes
  |> Map.values()
  |> Enum.filter(&(not is_nil(&1.commerce)))
  |> Enum.flat_map(fn route ->
    target = commerce_corridor_target(manifest, route.id)

    manifest
    |> RouteGate.evaluate(route.id, target)
    |> Map.get(:denials, [])
    |> Enum.filter(&commerce_doctor_denial?/1)
    |> Enum.map(&commerce_denial_check(route, &1))
  end)
end
```

**`run/1` integration pattern** (lines 113–146) — how a new finding function is threaded into `run/1`:
```elixir
# lines 124–134
phase_19_findings = phase_19_commerce_corridor_posture(manifest)
{commerce_summary, phase_23_findings} = phase_23_commerce_summary(manifest, opts)

findings =
  findings ++
    phase_3_findings ++
    phase_4_findings ++
    phase_10_findings ++ phase_19_findings ++ phase_23_findings
```

**Report.status derivation** (line 137) — why adding an `:error` finding is sufficient for fail-closed:
```elixir
status: if(Enum.any?(findings, &(&1.severity == :error)), do: :error, else: :ok),
```

**`check/6` private helper** (lines 1339–1348) — used throughout `doctor.ex` to build `Check` structs:
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

**`Check` struct fields** (`lib/crosswake/doctor/check.ex` lines 1–19):
```elixir
@enforce_keys [:severity, :code, :message, :check]
defstruct [:severity, :code, :message, :hint, :check, details: %{}]

@type severity :: :error | :warning | :advisory
```

**Adaptation for `phase_38_companion_seam_findings/0`:**
- Takes no argument (reads `Application.compile_env(:crosswake, :companions, [])` directly — D-02).
- For each companion module, calls `companion.validate_dependency/0`; if that returns `{:error, mods}` AND `companion.enabled?(config_map) == true`, emits one `check(:error, "companion.dependency_missing", "companion.#{companion_id}", message, hint, %{missing_modules: mods})`.
- The `[:crosswake, :companion, :validate_dependency]` telemetry span wraps the `validate_dependency/0` call (D-11b).
- Also emits an `:advisory` finding for `enabled: false && dependency_status: :present` (D-09 mapping note).
- Add the call to `run/1` as `phase_38_findings = phase_38_companion_seam_findings()` and append to `findings ++`.
- Add `alias Crosswake.Companion` at the top of the alias block.
- Add `companion_summary: %{}` to `Report` struct fields (mirrors `commerce_summary: %{}`).

---

### `mix.exs` — add `{:telemetry, "~> 1.0"}` (modify)

**Analog (exact):** existing `deps/0` block, lines 38–46.

**Current `deps/0`:**
```elixir
defp deps do
  [
    {:jason, "~> 1.4"},
    {:nimble_options, "~> 1.1"},
    {:phoenix, "~> 1.8"},
    {:phoenix_live_view, "~> 1.1"},
    {:ex_doc, "~> 0.38", only: :dev, runtime: false}
  ]
end
```

**Add one line** (D-11a — direct dep, not `only:` scoped, no `optional: true` here since this is the library declaring it directly):
```elixir
{:telemetry, "~> 1.0"},
```

Insert before `{:ex_doc, …}` to keep runtime deps grouped before dev-only deps. Note from D-11a: `:telemetry` 1.4.2 is already in `mix.lock` transitively, so this declares the constraint without a new download.

---

### `test/support/<name>_companion.ex` (test-support fixture, event-driven)

**Primary analogs:**
- `test/support/router_fixtures.ex` — namespaces under `Crosswake.TestSupport.*`, `@moduledoc false`, plain module (no `use`).
- `test/support/compile_router_case.ex` — imports `ExUnit.Assertions`, thin functional helper.
- `test/support/example_host.ex` — single-purpose module, `Crosswake.TestSupport.*` namespace.

**Fixture module pattern** (router_fixtures.ex lines 1–4, the bare controller pattern):
```elixir
defmodule Crosswake.TestSupport.PageController do
  def init(opts), do: opts
  def call(conn, _opts), do: conn
end
```

**Module naming convention:** All test-support modules live under `Crosswake.TestSupport.*`. The fixture companion should be `Crosswake.TestSupport.StubCompanion` (or similar) in `test/support/stub_companion.ex`.

**Adaptation — fixture companion must implement all 6 callbacks:**
```elixir
defmodule Crosswake.TestSupport.StubCompanion do
  @moduledoc false
  @behaviour Crosswake.Companion

  @impl true
  def companion_id, do: :stub_companion

  @impl true
  def enabled?(_config), do: true

  @impl true
  def route_gated?(_route, _context), do: :pass

  @impl true
  def kill_switch_active?(_context), do: false

  @impl true
  def validate_dependency, do: :ok   # or {:error, [MissingLib]} for the SC#2 test variant

  @impl true
  def report_state do
    %Crosswake.Companion.State{
      companion_id: :stub_companion,
      enabled: true,
      dependency_status: :present,
      gate_status: :unconfigured,
      kill_switch_status: :unconfigured,
      checked_at: System.monotonic_time(:millisecond)
    }
  end
end
```

For the SC#2 (fail-closed) proof path, a second fixture variant pointing `validate_dependency/0` at a deliberately-absent module is needed (e.g. `Crosswake.TestSupport.BrokenCompanion` or a parameterizable approach inside the test module itself).

**`elixirc_paths` convention** (mix.exs line 35 — already established):
```elixir
defp elixirc_paths(:test), do: ["lib", "test/support"]
```
Test-support files in `test/support/` are auto-compiled in test env. No `Code.require_file/2` needed.

---

### `test/crosswake/proof/phase38_companion_contract_test.exs` (test, request-response)

**Primary analogs:**
- `test/crosswake/proof/phase33_commerce_corridor_routes_test.exs` — hermetic, untagged, `use ExUnit.Case, async: true`, inline router fixture, proves contract shape.
- `test/crosswake/proof/phase23_commerce_support_proof_test.exs` — hermetic, `setup` block writing temp files, asserts doctor findings.

**Module header + hermeticity guard pattern** (phase33 lines 1–23):
```elixir
defmodule Crosswake.Proof.Phase33CommerceCorridorRoutesTest do
  @moduledoc """
  Hermetic merge-blocking proof lane for the Phase 33 paywall corridor route topology.
  ...
  This test is fully hermetic by design ... It never depends on the compiled
  example host ... never hits the network ...
  runs UNtagged inside the merge-blocking lane (phase34-proof.yml picks it up
  via the broad `mix test --exclude requires_example_host` run).
  """

  use ExUnit.Case, async: true
```

**Hermeticity assertion pattern** (phase33 lines 88–99):
```elixir
test "phase 33 corridor proof stays hermetic and does not depend on the example host" do
  source = File.read!(__ENV__.file) |> String.downcase()

  refute String.contains?(source, "crosswake" <> "example.router"),
         "phase 33 corridor proof must not depend on the example host router; keep the merge-blocking lane hermetic"

  refute Regex.match?(~r/code\.require_file\s*\(/, source),
         "phase 33 corridor proof must not Code.require_file example-host modules; keep the lane hermetic"
end
```

**`setup` block with temp-file install manifest** (phase23 lines 88–130):
```elixir
setup do
  target =
    Path.join(System.tmp_dir!(), "crosswake-phase23-proof-#{System.unique_integer([:positive])}")

  # ... File.mkdir_p!, File.write! for router, policy, install_manifest ...

  install_manifest =
    Jason.encode!(%{
      schema_version: 1,
      crosswake_version: "0.1.0",
      router_path: Path.relative_to(router_path, target),
      # ...
    })

  File.write!(install_manifest_path, install_manifest)
  %{target: target, install_manifest_path: install_manifest_path}
end
```

**Doctor assertion pattern** (phase23 lines 134–166):
```elixir
test "doctor commerce_summary exposes the canonical keys for the merge-blocking lane", %{
  target: target,
  install_manifest_path: install_manifest_path
} do
  report =
    Doctor.run(
      route_source: PaywallCorridorRouter,
      install_manifest_path: install_manifest_path,
      cwd: target
    )

  # ... assert on report fields ...
end
```

**Adaptation for `phase38_companion_contract_test.exs`** — three test groups from D-13:

SC#1 (behaviour compiles with all 6 callbacks):
```elixir
# No Doctor.run needed — behaviour satisfaction is a compile-time fact.
# Assert the fixture reports_state correctly and all callback return types hold.
test "StubCompanion satisfies all 6 Crosswake.Companion callbacks at compile time" do
  assert :stub_companion = Crosswake.TestSupport.StubCompanion.companion_id()
  assert true = Crosswake.TestSupport.StubCompanion.enabled?(%{})
  assert :pass = Crosswake.TestSupport.StubCompanion.route_gated?(route_entry, target)
  assert false = Crosswake.TestSupport.StubCompanion.kill_switch_active?(target)
  assert :ok = Crosswake.TestSupport.StubCompanion.validate_dependency()
  assert %Crosswake.Companion.State{} = Crosswake.TestSupport.StubCompanion.report_state()
end
```

SC#2 (fail-closed doctor finding when dep missing):
```elixir
# Register the broken fixture via Application.put_env, run Doctor, assert the :error finding.
test "doctor emits companion.dependency_missing :error when validate_dependency returns {:error, mods}", %{...} do
  Application.put_env(:crosswake, :companions, [Crosswake.TestSupport.BrokenCompanion])
  on_exit(fn -> Application.delete_env(:crosswake, :companions) end)
  report = Doctor.run(route_source: ..., install_manifest_path: install_manifest_path, cwd: target)
  finding = Enum.find(report.findings, &(&1.code == "companion.dependency_missing"))
  assert finding != nil
  assert finding.severity == :error
  assert %{missing_modules: [SomeAbsentModule]} = finding.details
end
```

SC#4 (telemetry span emits):
```elixir
test "validate_dependency emits [:crosswake, :companion, :validate_dependency] telemetry span" do
  :telemetry.attach(
    "phase38-test-handler",
    [:crosswake, :companion, :validate_dependency, :stop],
    fn _event, _measurements, metadata, _config ->
      send(self(), {:telemetry_stop, metadata})
    end,
    nil
  )
  on_exit(fn -> :telemetry.detach("phase38-test-handler") end)
  # Trigger via Doctor.run or direct companion call
  assert_receive {:telemetry_stop, %{companion_id: :stub_companion, result: :ok}}, 1000
end
```

---

## Shared Patterns

### `@enforce_keys` + `defstruct` + `@type t` struct idiom
**Source:** `lib/crosswake/commerce/contracts.ex` (throughout, e.g. `PurchaseIntent` lines 19–28)
**Apply to:** `lib/crosswake/companion/state.ex`
```elixir
@enforce_keys [...]
defstruct [..., details: %{}]   # optional fields with defaults go at the end

@type t :: %__MODULE__{
        # ... field :: type() entries ...
      }
```

### `defp check/6` helper
**Source:** `lib/crosswake/doctor/doctor.ex` lines 1339–1348
**Apply to:** `phase_38_companion_seam_findings/0` inside `doctor.ex`
```elixir
defp check(severity, code, check_name, message, hint, details \\ %{}) do
  %Check{severity: severity, code: code, check: check_name, message: message, hint: hint, details: details}
end
```
The existing `check/6` private helper is already present in `doctor.ex` — no new helper is needed.

### `Report.status` fail-closed derivation
**Source:** `lib/crosswake/doctor/doctor.ex` line 137
**Apply to:** doctor as a whole — adding an `:error` severity finding automatically escalates the report status; no additional logic required.
```elixir
status: if(Enum.any?(findings, &(&1.severity == :error)), do: :error, else: :ok),
```

### Hermetic proof test structure
**Source:** `test/crosswake/proof/phase33_commerce_corridor_routes_test.exs` (full file)
**Apply to:** `phase38_companion_contract_test.exs`
- `use ExUnit.Case, async: true`, no `@moduletag`
- Inline module fixtures in the test file (not referencing `CrosswakeExample.*`)
- Hermeticity self-assertion test
- `setup` with `System.tmp_dir!()` + `Jason.encode!` install manifest if `Doctor.run` is needed

### Telemetry span idiom (first in codebase)
**Source:** no existing `:telemetry.span/3` call sites in `lib/` (D-11a note: Phase 38 introduces the first). Use the standard `:telemetry.span/3` API directly:
```elixir
:telemetry.span(
  [:crosswake, :companion, :validate_dependency],
  %{companion_id: companion_id},
  fn ->
    result = companion_module.validate_dependency()
    {result, %{companion_id: companion_id, result: result}}
  end
)
```
This emits `:start`, `:stop`, and `:exception` events automatically. The `:stop` metadata includes both the base metadata and the return map from the inner function.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| (none) | — | — | All Phase 38 files have strong analogs in the codebase. |

---

## Metadata

**Analog search scope:** `lib/crosswake/commerce.ex`, `lib/crosswake/commerce/contracts.ex`, `lib/crosswake/commerce/reconciliation.ex`, `lib/crosswake/doctor/doctor.ex`, `lib/crosswake/doctor/check.ex`, `lib/crosswake/compatibility/compatibility.ex`, `lib/crosswake/compatibility/route_gate.ex`, `lib/crosswake/manifest/types.ex`, `lib/crosswake/support_matrix/support_matrix.ex`, `test/support/`, `test/crosswake/proof/`, `mix.exs`
**Files scanned:** 13
**Pattern extraction date:** 2026-05-29
