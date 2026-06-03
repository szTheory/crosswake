# Phase 42: Rulestead In-Tree Companion And Mock Example - Pattern Map

**Mapped:** 2026-05-30
**Files analyzed:** 7 new/modified files
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/crosswake/companions/rulestead.ex` | service | request-response | `test/support/stub_companion.ex` + `test/crosswake/proof/phase40_gate_evaluation_test.exs` (GateDenyCompanion + KillSwitchCompanion) | exact (behaviour implementation pattern) |
| `lib/crosswake/companions/rulestead/mock_flag_source.ex` | service | event-driven | no existing Agent process — stdlib `Agent` pattern; closest structural analog is `CrosswakeExample.Repo` (named process in supervisor) | partial |
| `examples/phoenix_host/lib/crosswake_example/gating/beta_feature_live.ex` | component | request-response | `examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex` (minimal LiveView shell) | role-match |
| `examples/phoenix_host/lib/crosswake_example/application.ex` (MODIFIED) | config | — | itself — adding one child to existing supervisor children list | exact |
| `examples/phoenix_host/lib/crosswake_example/router.ex` (MODIFIED) | route | request-response | itself — adding `/gating` scope sibling to `/commerce` scope | exact |
| `examples/phoenix_host/config/config.exs` (MODIFIED) | config | — | itself — adding `config :crosswake, :companions, [...]` block | exact |
| `test/crosswake/proof/phase42_rulestead_companion_test.exs` | test | request-response | `test/crosswake/proof/phase38_companion_contract_test.exs` + `test/crosswake/proof/phase40_gate_evaluation_test.exs` + `test/crosswake/proof/phase41_gating_doctor_test.exs` | exact |

## Pattern Assignments

### `lib/crosswake/companions/rulestead.ex` (service, request-response)

**Analog:** `test/support/stub_companion.ex` (lines 1–31) for module skeleton; `test/crosswake/proof/phase40_gate_evaluation_test.exs` (lines 46–85) for the GateDenyCompanion pattern with real logic; `test/crosswake/proof/phase40_gate_evaluation_test.exs` (lines 87–125) for KillSwitchCompanion pattern.

**Module declaration + behaviour pattern** (`test/support/stub_companion.ex` lines 1–8):
```elixir
defmodule Crosswake.TestSupport.StubCompanion do
  @moduledoc false
  @behaviour Crosswake.Companion
```

**companion_id/0 pattern** (`test/support/stub_companion.ex` line 9):
```elixir
  @impl true
  def companion_id, do: :stub_companion
```
For rulestead, use `:rulestead`.

**enabled?/1 pattern — config-map guard** (RESEARCH.md Anti-Patterns + Doctor verified line):
```elixir
  @impl true
  def enabled?(config), do: Map.get(config, :enabled, false)
```
Default `false` is correct — safe fail-closed default. The host sets `config :crosswake, :rulestead, %{enabled: true}` explicitly.

**route_gated?/2 pattern with pattern matching** (`test/crosswake/proof/phase40_gate_evaluation_test.exs` lines 56–67):
```elixir
  @impl true
  def route_gated?(%RouteEntry{gated_by: :test_flag} = route, _target) do
    {:deny,
     %Finding{
       axis: :gate_denied,
       route_id: route.id,
       message: "test_flag is disabled",
       subject: "DISABLED"
     }}
  end

  def route_gated?(_route, _target), do: :pass
```
For rulestead, replace pattern match with a `case MockFlagSource.get_flag(route.gated_by)` call (since the flag key is the companion_id atom `:rulestead` per the verified anti-pattern note in RESEARCH.md). Return values:
- `:gated` or `{:rolling_out, _}` → `{:deny, %Finding{axis: :gate_denied, route_id: route.id, message: "...", subject: "DISABLED"}}`
- `nil` / other → `:pass`

**kill_switch_active?/1 pattern** (`test/crosswake/proof/phase40_gate_evaluation_test.exs` lines 106–110):
```elixir
  @impl true
  def kill_switch_active?(_target) do
    Process.put(:kill_switch_active_called, true)
    true
  end
```
For rulestead, replace the Process spy with a nil-guarded Agent scan:
```elixir
  @impl true
  def kill_switch_active?(_target) do
    case Process.whereis(MockFlagSource) do
      nil -> false
      _pid ->
        MockFlagSource
        |> Agent.get(&Map.values/1)
        |> Enum.any?(&(&1 == :killed))
    end
  end
```

**validate_dependency/0 pattern** (`test/support/stub_companion.ex` lines 18–19 for :ok path; `test/support/stub_companion.ex` lines 49–50 for error path):
```elixir
  # :ok path (StubCompanion)
  @impl true
  def validate_dependency, do: :ok

  # {:error, [module()]} path (BrokenCompanion)
  @impl true
  def validate_dependency, do: {:error, [Crosswake.TestSupport.DeliberatelyAbsentLib]}
```
For rulestead:
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

**report_state/0 pattern** (`test/support/stub_companion.ex` lines 21–30 + `test/crosswake/proof/phase41_gating_doctor_test.exs` lines 92–102 for :active pairing):
```elixir
  # Base struct shape from stub_companion.ex lines 21–30:
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
```
For rulestead, `report_state/0` must read from MockFlagSource and map to the canonical pairings from RESEARCH.md Pitfall 3:
- `nil` / unknown → `gate_status: :unconfigured, kill_switch_status: :unconfigured`
- `:gated` stored → `gate_status: :active, kill_switch_status: :inactive`
- `{:rolling_out, n}` stored → `gate_status: {:rolling_out, n}, kill_switch_status: :inactive`
- `:killed` stored → `gate_status: :inactive, kill_switch_status: :active`

**Imports block for rulestead.ex:**
```elixir
  alias Crosswake.Companion.State
  alias Crosswake.Compatibility.Finding
  alias Crosswake.Compatibility.Target
  alias Crosswake.Companions.Rulestead.MockFlagSource
  alias Crosswake.Manifest.Types.RouteEntry
```
(RouteEntry and Target needed to satisfy callback typespecs from `lib/crosswake/companion.ex` lines 43–46.)

---

### `lib/crosswake/companions/rulestead/mock_flag_source.ex` (service, event-driven)

**Analog:** No existing Agent process in the codebase. The pattern comes directly from Elixir stdlib `Agent` convention. Closest structural reference is `CrosswakeExample.Application` supervisor children (named processes).

**Full Agent module pattern** (from RESEARCH.md Pattern 2, confirmed against D-01/D-03 locked decisions):
```elixir
defmodule Crosswake.Companions.Rulestead.MockFlagSource do
  @moduledoc """
  Named Agent storing flag state for local dev and hermetic proof tests.
  Production code uses Rulestead.Snapshot; this module is mock-only (Phase 42).
  """
  use Agent

  @name __MODULE__

  def start_link(_opts \\ []) do
    Agent.start_link(fn -> %{} end, name: @name)
  end

  def set_flag(flag_key, gate_state) when is_atom(flag_key) do
    Agent.update(@name, &Map.put(&1, flag_key, gate_state))
  end

  def get_flag(flag_key) when is_atom(flag_key) do
    Agent.get(@name, &Map.get(&1, flag_key))
  end

  def reset do
    Agent.update(@name, fn _ -> %{} end)
  end
end
```

`@name __MODULE__` gives the registered process name `Crosswake.Companions.Rulestead.MockFlagSource` — the same atom used in `Process.whereis(MockFlagSource)` calls from within the companion module (when aliased).

Child spec for supervisor: `Crosswake.Companions.Rulestead.MockFlagSource` (bare module reference works when `use Agent` generates a `child_spec/1`). Alternatively `{MockFlagSource, []}`.

---

### `examples/phoenix_host/lib/crosswake_example/gating/beta_feature_live.ex` (component, request-response)

**Analog:** `examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex` lines 1–10 (minimal LiveView shell). The gating LiveView is far simpler — no commerce/PubSub needed.

**Minimal LiveView pattern** (`paywall_entry_live.ex` lines 1–10):
```elixir
defmodule CrosswakeExample.PaywallEntryLive do
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, ...)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    ...
    """
  end
end
```

For `BetaFeatureLive`, a minimal implementation:
```elixir
defmodule CrosswakeExample.Gating.BetaFeatureLive do
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :flag_key, :rulestead)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="gating-beta-feature">
      <h2>Beta Feature</h2>
      <p>You have access to the beta feature.</p>
    </div>
    """
  end
end
```

No `handle_event`, no PubSub — this route is only reached when the gate passes. The gate denial is handled entirely by RouteGate before the LiveView mounts.

---

### `examples/phoenix_host/lib/crosswake_example/application.ex` (MODIFIED)

**Analog:** itself — `examples/phoenix_host/lib/crosswake_example/application.ex` (lines 1–15).

**Existing pattern** (application.ex lines 6–14):
```elixir
  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: CrosswakeExample.PubSub},
      CrosswakeExample.Repo
    ]

    opts = [strategy: :one_for_one, name: CrosswakeExample.Supervisor]
    Supervisor.start_link(children, opts)
  end
```

**Modified pattern — add MockFlagSource as FIRST child** (RESEARCH.md Pitfall 2 — must start before any child that triggers gate evaluation):
```elixir
    children = [
      Crosswake.Companions.Rulestead.MockFlagSource,   # NEW — first child
      {Phoenix.PubSub, name: CrosswakeExample.PubSub},
      CrosswakeExample.Repo
    ]
```

---

### `examples/phoenix_host/lib/crosswake_example/router.ex` (MODIFIED)

**Analog:** itself — `router.ex` lines 219–244 (`/commerce` scope) is the closest structural match for the new `/gating` scope.

**Existing `/commerce` scope pattern** (router.ex lines 219–244):
```elixir
  scope "/commerce", CrosswakeExample do
    pipe_through [:browser]

    crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
      live "/paywall", PaywallEntryLive, :index,
        crosswake: [
          id: "commerce-paywall-entry",
          runtime: :live_view,
          commerce: [corridor: :subscription_default, role: :paywall_entry]
        ]
      ...
    end
  end
```

**New `/gating` scope pattern to add** (D-07, D-08, D-09 from CONTEXT.md + RESEARCH.md verified anti-pattern: `gated_by` must equal `companion_id/0`, which is `:rulestead`):
```elixir
  scope "/gating", CrosswakeExample.Gating do
    pipe_through [:browser]

    crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
      live "/beta-feature", BetaFeatureLive,
        crosswake: [
          id: "gating-beta-feature",
          gated_by: :rulestead,
          on_unavailable: :deny
        ]
    end
  end
```

**Critical:** `gated_by: :rulestead` (not `:my_flag`) — the atom must match `companion_id/0` returning `:rulestead` or the doctor will emit `gating.flag_reference_unknown :error` (RESEARCH.md verified lines 499–514).

---

### `examples/phoenix_host/config/config.exs` (MODIFIED)

**Analog:** itself — `config/config.exs` lines 1–16.

**Existing pattern** (config.exs lines 1–4):
```elixir
import Config

config :phoenix, :json_library, Jason

config :crosswake_example, ...
```

**Additions to append:**
```elixir
# Register Rulestead companion
config :crosswake, :companions, [Crosswake.Companions.Rulestead]

# Enable the Rulestead companion for this host
config :crosswake, :rulestead, %{enabled: true}
```

These two blocks must both be present: `:companions` registers the module in the doctor/RouteGate dispatch loop; `:rulestead` is the config map passed to `enabled?/1` (verified in doctor.ex: `config_map = Application.get_env(:crosswake, companion_id, %{})`).

---

### `test/crosswake/proof/phase42_rulestead_companion_test.exs` (test, request-response)

**Analog:** `test/crosswake/proof/phase38_companion_contract_test.exs` (setup + hermeticity pattern), `test/crosswake/proof/phase40_gate_evaluation_test.exs` (companion registration + RouteGate assertion pattern), `test/crosswake/proof/phase41_gating_doctor_test.exs` (Doctor.run + SC structure).

**Module declaration + async constraint** (`phase38_companion_contract_test.exs` lines 22–29):
```elixir
  # async: false — SC#2 and SC#4 both write the shared global
  # Application.put_env(:crosswake, :companions, ...) key; running them
  # concurrently lets one test observe another's companion list (CR-01).
  use ExUnit.Case, async: false
```

**setup pattern — start_supervised + Application.put_env + on_exit** (RESEARCH.md Pattern 4):
```elixir
  setup do
    start_supervised!(Crosswake.Companions.Rulestead.MockFlagSource)
    Application.put_env(:crosswake, :companions, [Crosswake.Companions.Rulestead])
    Application.put_env(:crosswake, :rulestead, %{enabled: true})

    on_exit(fn ->
      Application.delete_env(:crosswake, :companions)
      Application.delete_env(:crosswake, :rulestead)
    end)

    :ok
  end
```

`start_supervised!/1` is the correct form (not `start_supervised/1` — RESEARCH.md Pitfall 4) to ensure fresh Agent state per test via ExUnit's test supervisor automatic teardown. MockFlagSource is stateless at start (empty map `%{}`), so no explicit `reset/0` call needed in setup when using `start_supervised!`.

**SC#3 doctor setup — needs temp dir install manifest** (`phase38_companion_contract_test.exs` lines 47–89, `phase41_gating_doctor_test.exs` lines 227–269):
```elixir
  setup do
    target =
      Path.join(
        System.tmp_dir!(),
        "crosswake-phase42-proof-#{System.unique_integer([:positive])}"
      )

    router_path = Path.join(target, "lib/demo_web/router.ex")
    policy_path = Path.join(target, "lib/demo_web/crosswake/policy.ex")
    install_manifest_path = Path.join(target, "priv/crosswake/install_manifest.json")

    File.mkdir_p!(Path.dirname(router_path))
    File.mkdir_p!(Path.dirname(policy_path))
    File.mkdir_p!(Path.dirname(install_manifest_path))

    # ... File.write! router_path, policy_path, install_manifest as in phase38/41 tests ...

    %{target: target, install_manifest_path: install_manifest_path}
  end
```

**Hermeticity self-assertion pattern** (`phase38_companion_contract_test.exs` lines 95–103):
```elixir
  test "phase 42 rulestead companion proof stays hermetic — no example-host or Code.require_file dependency" do
    source = File.read!(__ENV__.file) |> String.downcase()

    refute String.contains?(source, "crosswake" <> "example.router"),
           "phase 42 proof must not depend on the example host router; keep the merge-blocking lane hermetic"

    refute Regex.match?(~r/code\.require_file\s*\(/, source),
           "phase 42 proof must not Code.require_file example-host modules; keep the lane hermetic"
  end
```

**SC#1 gate state assertion pattern** (`phase40_gate_evaluation_test.exs` lines 197–248 for :gate_denied; lines 255–276 for kill-switch short-circuit):

SC#1a (:gated → denial):
```elixir
  test "SC#1a: :gated flag state produces :gate_denied denial" do
    MockFlagSource.set_flag(:rulestead, :gated)

    assert {:ok, %{manifest: manifest}} = Manifest.compile(GatingRouter)
    target = %Target{}
    decision = RouteGate.evaluate(manifest, "gating-beta-feature", target)

    assert decision.status == :deny
    assert decision.denial.reason == :gate_denied
    assert decision.transition == :halt
  end
```

SC#1c (:killed → kill_switch_active denial, route_gated?/2 skipped):
```elixir
  test "SC#1c: :killed flag state produces :kill_switch_active denial; route_gated?/2 never reached" do
    MockFlagSource.set_flag(:rulestead, :killed)

    assert {:ok, %{manifest: manifest}} = Manifest.compile(GatingRouter)
    target = %Target{}
    decision = RouteGate.evaluate(manifest, "gating-beta-feature", target)

    assert decision.status == :deny
    assert decision.denial.reason == :kill_switch_active
  end
```

**SC#3 doctor assertion pattern** (`phase38_companion_contract_test.exs` lines 144–180):

SC#3a (enabled + library absent → :error):
```elixir
  test "SC#3a: doctor emits companion.dependency_missing :error when rulestead enabled and Rulestead library absent",
       %{target: target, install_manifest_path: install_manifest_path} do
    Application.put_env(:crosswake, :companions, [Crosswake.Companions.Rulestead])
    on_exit(fn -> Application.delete_env(:crosswake, :companions) end)

    report =
      Doctor.run(
        route_source: GatingRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    finding = Enum.find(report.findings, &(&1.code == "companion.dependency_missing"))
    assert finding != nil
    assert finding.severity == :error
    assert %{missing_modules: [Rulestead]} = finding.details
  end
```

SC#3b (disabled + library absent → no error — "clean"):
```elixir
  test "SC#3b: doctor emits no dependency_missing error when companion disabled (enabled: false) and library absent",
       %{target: target, install_manifest_path: install_manifest_path} do
    Application.put_env(:crosswake, :companions, [Crosswake.Companions.Rulestead])
    Application.put_env(:crosswake, :rulestead, %{enabled: false})
    on_exit(fn ->
      Application.delete_env(:crosswake, :companions)
      Application.delete_env(:crosswake, :rulestead)
    end)

    report =
      Doctor.run(
        route_source: GatingRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    dep_error = Enum.find(report.findings, &(&1.code == "companion.dependency_missing"))
    assert dep_error == nil,
           "disabled + missing dep must emit no dependency_missing error; got: #{inspect(dep_error)}"
  end
```

The SC#3b clean case works because `doctor.ex` line 534's catch-all `{false, {:error, mods}} -> []` returns no findings for disabled+missing companions (verified in RESEARCH.md Pitfall 5).

**Inline hermetic router for proof tests** (`phase40_gate_evaluation_test.exs` lines 131–140, `phase41_gating_doctor_test.exs` lines 181–210):
```elixir
  defmodule GatingRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live "/gating/beta-feature", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "gating-beta-feature",
            gated_by: :rulestead,
            on_unavailable: :deny
          ]
      end
    end
  end
```

Uses `Crosswake.TestSupport.StudySessionLive` as the view module (existing test support stub — avoids importing phoenix_host modules, keeping the lane hermetic).

---

## Shared Patterns

### Companion behaviour declaration
**Source:** `test/support/stub_companion.ex` lines 1–3
**Apply to:** `lib/crosswake/companions/rulestead.ex`
```elixir
defmodule Crosswake.Companions.Rulestead do
  @moduledoc false
  @behaviour Crosswake.Companion
```

### `@impl true` annotation on every callback
**Source:** `test/support/stub_companion.ex` lines 7, 10, 13, 17, 20, 22 (all six callbacks)
**Apply to:** `lib/crosswake/companions/rulestead.ex` — all six `@impl true` annotations are mandatory; the compiler enforces the behaviour at compile time.

### `async: false` + `Application.put_env` + `on_exit` cleanup
**Source:** `test/crosswake/proof/phase38_companion_contract_test.exs` lines 22–30 and lines 148–151
**Apply to:** `test/crosswake/proof/phase42_rulestead_companion_test.exs` — every test that sets `:companions` must clean up with `on_exit(fn -> Application.delete_env(:crosswake, :companions) end)`.

### `start_supervised!` for Agent-based processes in tests
**Source:** RESEARCH.md Pitfall 2 and Pitfall 4; ExUnit convention
**Apply to:** `test/crosswake/proof/phase42_rulestead_companion_test.exs` setup — always `start_supervised!(MockFlagSource)`, never `MockFlagSource.start_link()`.

### No untagged `@moduletag` — picked up by `phase34-proof.yml` automatically
**Source:** `test/crosswake/proof/phase38_companion_contract_test.exs` (no @moduletag), `test/crosswake/proof/phase40_gate_evaluation_test.exs` (no @moduletag), `test/crosswake/proof/phase41_gating_doctor_test.exs` (uses @tag per-test, not @moduletag)
**Apply to:** `test/crosswake/proof/phase42_rulestead_companion_test.exs` — do not add `@moduletag :requires_example_host` or any module-level tag. The file runs automatically under `mix test --exclude requires_example_host`.

### Companion.State struct construction
**Source:** `lib/crosswake/companion/state.ex` lines 4–5 (`@enforce_keys` — all 6 fields required)
**Apply to:** `lib/crosswake/companions/rulestead.ex` `report_state/0` — must supply all 6 enforce_keys: `companion_id`, `enabled`, `dependency_status`, `gate_status`, `kill_switch_status`, `checked_at`. Missing any enforce_key raises `ArgumentError` at runtime.

### `pipe_through [:browser]` for LiveView scopes
**Source:** `examples/phoenix_host/lib/crosswake_example/router.ex` lines 220 (`/commerce` scope)
**Apply to:** New `/gating` scope in `router.ex` — must include `pipe_through [:browser]` before `crosswake_defaults`.

---

## No Analog Found

All files have analogs. No entries in this section.

---

## Metadata

**Analog search scope:** `lib/crosswake/`, `test/crosswake/proof/`, `test/support/`, `examples/phoenix_host/`
**Files scanned:** 11
**Pattern extraction date:** 2026-05-30
