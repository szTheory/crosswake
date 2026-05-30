defmodule Crosswake.Proof.Phase40GateEvaluationTest do
  @moduledoc """
  Hermetic merge-blocking proof lane for Phase 40 runtime gate evaluation and
  fail-closed denial.

  Proves SC#1 (GATE-03): RouteGate.evaluate/4 with a fixture companion that returns
  {:deny, finding} produces a :gate_denied denial with OpenFeature-shaped details
  (flag_key, reason, variant, evaluated_at all present and non-nil).

  Proves SC#2 (GATE-04): When a companion's kill_switch_active?/1 returns true,
  RouteGate produces :kill_switch_active denial and route_gated?/2 is never called
  (kill-switch short-circuits). Verified via Process spy keys.

  Proves SC#3a/SC#3b (GATE-04): on_unavailable: :deny -> transition :halt;
  on_unavailable: {:fallback_phoenix, :home} -> transition {:redirect, :home}.
  SC#3c: Non-gated route skips gate/kill-switch logic entirely.

  Proves SC#4: RouteGate.evaluate/4 is pure over manifest + registered companion
  modules — no network dependency. Hermeticity self-assertion included.

  This test is fully hermetic by design: it never depends on the compiled example
  host (CrosswakeExample.*), never hits the network, never launches a simulator,
  and never calls Code.require_file. It runs UNtagged so the existing
  phase34-proof.yml `mix test --exclude requires_example_host` lane picks it up
  with no new CI file (D-12).

  async: false — :companions is a shared global Application key (D-13);
  concurrent tests would observe each other's companion registrations.
  """

  # async: false — shared Application.put_env(:crosswake, :companions, ...) key (D-13)
  use ExUnit.Case, async: false

  alias Crosswake.Compatibility.Finding
  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Compatibility.Target
  alias Crosswake.Manifest
  alias Crosswake.Manifest.Types
  alias Crosswake.Manifest.Types.RouteEntry

  # ---------------------------------------------------------------------------
  # Inline fixture companions
  # ---------------------------------------------------------------------------

  # GateDenyCompanion: returns {:deny, finding} for the route gated by :test_flag,
  # :pass otherwise. kill_switch_active?/1 returns false.
  defmodule GateDenyCompanion do
    @behaviour Crosswake.Companion

    @impl true
    def companion_id, do: :gate_deny_companion

    @impl true
    def enabled?(_config), do: true

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

    @impl true
    def kill_switch_active?(_target), do: false

    @impl true
    def validate_dependency, do: :ok

    @impl true
    def report_state do
      %Crosswake.Companion.State{
        companion_id: :gate_deny_companion,
        enabled: true,
        dependency_status: :present,
        gate_status: :unconfigured,
        kill_switch_status: :unconfigured,
        checked_at: System.monotonic_time(:millisecond)
      }
    end
  end

  # KillSwitchCompanion: kill_switch_active?/1 records the call via Process.put
  # and returns true. route_gated?/2 also records a call (should never be reached
  # when kill switch fires).
  defmodule KillSwitchCompanion do
    @behaviour Crosswake.Companion

    @impl true
    def companion_id, do: :kill_switch_companion

    @impl true
    def enabled?(_config), do: true

    @impl true
    def route_gated?(_route, _target) do
      Process.put(:route_gated_called, true)
      :pass
    end

    @impl true
    def kill_switch_active?(_target) do
      Process.put(:kill_switch_active_called, true)
      true
    end

    @impl true
    def validate_dependency, do: :ok

    @impl true
    def report_state do
      %Crosswake.Companion.State{
        companion_id: :kill_switch_companion,
        enabled: true,
        dependency_status: :present,
        gate_status: :unconfigured,
        kill_switch_status: :unconfigured,
        checked_at: System.monotonic_time(:millisecond)
      }
    end
  end

  # ---------------------------------------------------------------------------
  # Minimal hermetic router for building a manifest with gated routes
  # ---------------------------------------------------------------------------

  defmodule GatedRouteRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live "/gated", Crosswake.TestSupport.StudySessionLive,
          crosswake: [id: "gated", runtime: :live_view, gated_by: :test_flag]
      end
    end
  end

  defmodule FallbackRouteRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live "/premium", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "premium",
            runtime: :live_view,
            gated_by: :test_flag,
            on_unavailable: {:fallback_phoenix, :home}
          ]
      end
    end
  end

  defmodule NonGatedRouteRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live "/home", Crosswake.TestSupport.StudySessionLive,
          crosswake: [id: "home", runtime: :live_view]
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Setup: clear Process spy keys before each test
  # ---------------------------------------------------------------------------

  setup do
    Process.delete(:route_gated_called)
    Process.delete(:kill_switch_active_called)
    :ok
  end

  # ---------------------------------------------------------------------------
  # Hermeticity self-assertion (SC#4 — mirrors phase38 lines 95-103)
  # ---------------------------------------------------------------------------

  test "phase 40 gate evaluation proof stays hermetic — no example-host or Code.require_file dependency" do
    source = File.read!(__ENV__.file) |> String.downcase()

    refute String.contains?(source, "crosswake" <> "example.router"),
           "phase 40 gate proof must not depend on the example host router; keep the merge-blocking lane hermetic"

    refute Regex.match?(~r/code\.require_file\s*\(/, source),
           "phase 40 gate proof must not Code.require_file example-host modules; keep the lane hermetic"
  end

  # ---------------------------------------------------------------------------
  # SC#1 (GATE-03): :gate_denied denial carries OpenFeature-shaped details
  # ---------------------------------------------------------------------------

  test "SC#1: gate companion returning {:deny, finding} produces :gate_denied denial with flag_key, reason, variant, evaluated_at" do
    Application.put_env(:crosswake, :companions, [GateDenyCompanion])

    on_exit(fn ->
      Application.delete_env(:crosswake, :companions)
    end)

    test_pid = self()
    handler_id = "phase40-gate-test-handler-#{System.unique_integer([:positive])}"

    :telemetry.attach(
      handler_id,
      [:crosswake, :companion, :route_gate, :stop],
      fn _event, _measurements, metadata, _config ->
        send(test_pid, {:telemetry_stop, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    assert {:ok, %{manifest: manifest}} = Manifest.compile(GatedRouteRouter)
    target = %Target{}
    decision = RouteGate.evaluate(manifest, "gated", target)

    assert decision.status == :deny
    assert decision.denial.reason == :gate_denied

    details = decision.denial.details
    assert Map.has_key?(details, "flag_key"), "details must include flag_key"
    assert Map.has_key?(details, "reason"), "details must include reason"
    assert Map.has_key?(details, "variant"), "details must include variant"
    assert Map.has_key?(details, "evaluated_at"), "details must include evaluated_at"

    assert details["flag_key"] != nil
    assert details["reason"] != nil
    assert details["variant"] != nil
    assert details["evaluated_at"] != nil

    # ISO8601 timestamp pattern
    assert String.match?(
             details["evaluated_at"],
             ~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/
           ),
           "evaluated_at must be an ISO8601 string, got: #{inspect(details["evaluated_at"])}"

    assert details["flag_key"] == "test_flag"
    assert details["reason"] == "DISABLED"
    assert details["variant"] == "off"

    # Telemetry assertion: route_gate span should have fired
    assert_receive {:telemetry_stop, %{companion_id: :gate_deny_companion}}, 1000
  end

  # ---------------------------------------------------------------------------
  # SC#2 (GATE-04): kill-switch short-circuits — route_gated?/2 never called
  # ---------------------------------------------------------------------------

  test "SC#2: kill-switch companion produces :kill_switch_active denial; route_gated?/2 never called" do
    Application.put_env(:crosswake, :companions, [KillSwitchCompanion])

    on_exit(fn ->
      Application.delete_env(:crosswake, :companions)
    end)

    assert {:ok, %{manifest: manifest}} = Manifest.compile(GatedRouteRouter)
    target = %Target{}
    decision = RouteGate.evaluate(manifest, "gated", target)

    assert decision.status == :deny
    assert decision.denial.reason == :kill_switch_active

    # Kill switch was called
    assert Process.get(:kill_switch_active_called) == true,
           "kill_switch_active?/1 must have been called"

    # route_gated?/2 must NOT have been called — kill switch short-circuits
    assert Process.get(:route_gated_called) == nil,
           "route_gated?/2 must NOT be called when kill switch fires (short-circuit)"
  end

  # ---------------------------------------------------------------------------
  # SC#3a: on_unavailable: :deny -> transition :halt
  # ---------------------------------------------------------------------------

  test "SC#3a: gate-denied route with on_unavailable: :deny yields transition :halt" do
    Application.put_env(:crosswake, :companions, [GateDenyCompanion])

    on_exit(fn ->
      Application.delete_env(:crosswake, :companions)
    end)

    # GatedRouteRouter has default on_unavailable: :deny for "gated" route
    assert {:ok, %{manifest: manifest}} = Manifest.compile(GatedRouteRouter)
    target = %Target{}
    decision = RouteGate.evaluate(manifest, "gated", target)

    assert decision.status == :deny
    assert decision.transition == :halt
  end

  # ---------------------------------------------------------------------------
  # SC#3b: on_unavailable: {:fallback_phoenix, :home} -> transition {:redirect, :home}
  # ---------------------------------------------------------------------------

  test "SC#3b: gate-denied route with on_unavailable: {:fallback_phoenix, :home} yields transition {:redirect, :home}" do
    Application.put_env(:crosswake, :companions, [GateDenyCompanion])

    on_exit(fn ->
      Application.delete_env(:crosswake, :companions)
    end)

    assert {:ok, %{manifest: manifest}} = Manifest.compile(FallbackRouteRouter)
    target = %Target{}
    decision = RouteGate.evaluate(manifest, "premium", target)

    assert decision.status == :deny
    assert decision.transition == {:redirect, :home}
  end

  # ---------------------------------------------------------------------------
  # SC#3c: Non-gated route with kill-switch+gate companion — gate logic not invoked
  # ---------------------------------------------------------------------------

  test "SC#3c: non-gated route with registered companion skips gate/kill-switch logic" do
    Application.put_env(:crosswake, :companions, [KillSwitchCompanion])

    on_exit(fn ->
      Application.delete_env(:crosswake, :companions)
    end)

    assert {:ok, %{manifest: manifest}} = Manifest.compile(NonGatedRouteRouter)
    target = %Target{}
    _decision = RouteGate.evaluate(manifest, "home", target)

    # Neither kill_switch_active?/1 nor route_gated?/2 should have been called
    assert Process.get(:kill_switch_active_called) == nil,
           "kill_switch_active?/1 must NOT be called for non-gated routes (D-11)"

    assert Process.get(:route_gated_called) == nil,
           "route_gated?/2 must NOT be called for non-gated routes (D-11)"
  end
end
