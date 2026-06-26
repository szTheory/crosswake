defmodule Crosswake.Proof.Phase42RulesteadCompanionTest do
  @moduledoc """
  Adapter-behavior proof lane for the Phase 42 Rulestead companion.
  Runs inside the crosswake_rulestead companion package as a path: dep (D-20 test split).

  Proves SC#1: Crosswake.Companions.Rulestead translates MockFlagSource gate states
  into the correct RouteGate outcomes for all three flag states (:gated, :killed,
  {:rolling_out, n}) and the unset (nil) case.

  This test runs with the rulestead engine installed (optional: true dep is included in
  the companion's own mix.lock so Code.ensure_loaded?(Rulestead) returns true). This is
  the engine-PRESENT context for adapter-behavior testing.

  The engine-ABSENT behavior (validate_dependency/0 returning {:error, [Rulestead]}) and
  the Doctor dependency_missing finding (SC#3a/SC#3b) are proved in the core hermetic lane
  (test/crosswake/proof/phase42_rulestead_companion_test.exs in the monorepo root) where
  rulestead is not in deps. D-20 test split preserves both lanes.

  async: false — :companions is a shared global Application key; concurrent tests
  would observe each other's companion registrations. MockFlagSource is a named
  Agent (shared global process) — isolated per test via start_supervised!/1.
  """

  # async: false — shared Application.put_env(:crosswake, :companions, ...) key
  use ExUnit.Case, async: false

  alias Crosswake.Companions.Rulestead
  alias Crosswake.Companions.Rulestead.MockFlagSource
  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Compatibility.Target
  alias Crosswake.Manifest

  # ---------------------------------------------------------------------------
  # Inline hermetic GatingRouter
  # Uses StudySessionLive (test/support stub) — no phoenix_host dependency (D-23)
  # ---------------------------------------------------------------------------

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

  # ---------------------------------------------------------------------------
  # Setup: fresh MockFlagSource Agent per test; companion + config env vars
  # ---------------------------------------------------------------------------

  setup do
    # start_supervised! ensures ExUnit tears down the Agent after each test,
    # preventing flag-state leakage between tests (T-42-04 / Pitfall 4).
    start_supervised!(MockFlagSource)

    Application.put_env(:crosswake, :companions, [Rulestead])
    Application.put_env(:crosswake, :rulestead, %{enabled: true})

    on_exit(fn ->
      Application.delete_env(:crosswake, :companions)
      Application.delete_env(:crosswake, :rulestead)
    end)

    :ok
  end

  # ---------------------------------------------------------------------------
  # Engine-PRESENT assertions (rulestead is in the companion's deps lock)
  # These tests exercise the full gate path: validate_dependency/0 returns :ok,
  # so check_dependencies/2 passes and gate/kill-switch logic runs (D-02).
  # ---------------------------------------------------------------------------

  test "validate_dependency/0 returns :ok when rulestead engine is loaded" do
    # In the companion package, rulestead is in the optional dep lock — engine is present.
    # The bare atom :"Elixir.Rulestead" is the Hex package root module.
    assert Crosswake.Companions.Rulestead.validate_dependency() == :ok
  end

  # ---------------------------------------------------------------------------
  # SC#1a: :gated flag -> :gate_denied deny with transition :halt
  # Engine is present (rulestead in lock), so check_dependencies/2 passes and
  # gate logic runs. (D-02, D-33)
  # ---------------------------------------------------------------------------

  test "SC#1a: :gated flag state drives :gate_denied denial with transition :halt" do
    MockFlagSource.set_flag(:rulestead, :gated)

    assert {:ok, %{manifest: manifest}} = Manifest.compile(GatingRouter)
    target = %Target{}
    decision = RouteGate.evaluate(manifest, "gating-beta-feature", target)

    assert decision.status == :deny,
           "expected :deny for :gated flag; got #{inspect(decision.status)}"

    assert decision.denial.reason == :gate_denied,
           "expected :gate_denied denial reason; got #{inspect(decision.denial.reason)}"

    assert decision.transition == :halt,
           "expected :halt transition for on_unavailable: :deny; got #{inspect(decision.transition)}"
  end

  # ---------------------------------------------------------------------------
  # SC#1b: {:rolling_out, 50} -> :gate_denied deny; report_state gate_status is {:rolling_out, 50}
  # ---------------------------------------------------------------------------

  test "SC#1b: {:rolling_out, 50} flag state drives :gate_denied denial; report_state reflects rolling_out" do
    MockFlagSource.set_flag(:rulestead, {:rolling_out, 50})

    assert {:ok, %{manifest: manifest}} = Manifest.compile(GatingRouter)
    target = %Target{}
    decision = RouteGate.evaluate(manifest, "gating-beta-feature", target)

    assert decision.status == :deny,
           "expected :deny for {:rolling_out, 50}; got #{inspect(decision.status)}"

    assert decision.denial.reason == :gate_denied,
           "expected :gate_denied denial reason for rolling_out; got #{inspect(decision.denial.reason)}"

    # report_state gate_status must reflect the stored rolling_out value
    state = Rulestead.report_state()

    assert state.gate_status == {:rolling_out, 50},
           "expected gate_status {:rolling_out, 50}; got #{inspect(state.gate_status)}"

    assert state.kill_switch_status == :inactive,
           "expected kill_switch_status :inactive for rolling_out; got #{inspect(state.kill_switch_status)}"
  end

  # ---------------------------------------------------------------------------
  # SC#1c: :killed flag -> :kill_switch_active denial (short-circuits route_gated?/2)
  # ---------------------------------------------------------------------------

  test "SC#1c: :killed flag state drives :kill_switch_active denial" do
    MockFlagSource.set_flag(:rulestead, :killed)

    assert {:ok, %{manifest: manifest}} = Manifest.compile(GatingRouter)
    target = %Target{}
    decision = RouteGate.evaluate(manifest, "gating-beta-feature", target)

    assert decision.status == :deny,
           "expected :deny for :killed flag; got #{inspect(decision.status)}"

    assert decision.denial.reason == :kill_switch_active,
           "expected :kill_switch_active denial reason; got #{inspect(decision.denial.reason)}"
  end

  # ---------------------------------------------------------------------------
  # SC#1d: no flag set (nil) -> :allow decision
  # Engine is present; validate_dependency/0 returns :ok; gate sees no flag → :pass.
  # ---------------------------------------------------------------------------

  test "SC#1d: unset flag (nil) yields a non-deny (allow) decision for the route" do
    # MockFlagSource started fresh in setup — no flag set for :rulestead

    assert {:ok, %{manifest: manifest}} = Manifest.compile(GatingRouter)
    target = %Target{}
    decision = RouteGate.evaluate(manifest, "gating-beta-feature", target)

    # validate_dependency/0 returns :ok (engine present) -> check_dependencies passes
    # route_gated?/2 returns :pass (no flag set) -> no gate denial
    gate_denials =
      Enum.filter(decision.denials, fn d ->
        d.reason in [:gate_denied, :kill_switch_active, :dependency_missing]
      end)

    assert gate_denials == [],
           "expected no gate/dependency denials for unset flag with engine present; got #{inspect(gate_denials)}"
  end

  # ---------------------------------------------------------------------------
  # SC#1 companion callback unit assertions
  # ---------------------------------------------------------------------------

  test "route_gated?/2 returns :pass for nil (unset) flag" do
    # No flag set — MockFlagSource returns nil
    route = %Crosswake.Manifest.Types.RouteEntry{
      id: "test-route",
      path: "/test",
      runtime: :live_view,
      gated_by: :rulestead
    }

    assert Rulestead.route_gated?(route, %Target{}) == :pass
  end

  test "kill_switch_active?/1 returns false when MockFlagSource is running with no :killed flags" do
    # MockFlagSource running from setup, no flags set
    assert Rulestead.kill_switch_active?(%Target{}) == false
  end

  test "kill_switch_active?/1 returns true when :killed flag is stored" do
    MockFlagSource.set_flag(:rulestead, :killed)
    assert Rulestead.kill_switch_active?(%Target{}) == true
  end

  test "kill_switch_active?/1 is nil-guarded — returns false when MockFlagSource not running" do
    # Stop the supervised Agent to simulate an absent process
    stop_supervised!(MockFlagSource)
    assert Rulestead.kill_switch_active?(%Target{}) == false
  end

  test "report_state/0 returns a fully-populated Crosswake.Companion.State struct" do
    state = Crosswake.Companions.Rulestead.report_state()
    assert match?(%Crosswake.Companion.State{}, state)
    assert state.companion_id == :rulestead
    assert state.enabled == true  # setup sets %{enabled: true} via Application.put_env
    assert is_integer(state.checked_at)
    # Rulestead engine is present in the companion's deps lock
    assert state.dependency_status == :present
    assert state.gate_status in [:active, :inactive, :unconfigured] or
             match?({:rolling_out, _}, state.gate_status)

    assert state.kill_switch_status in [:active, :inactive, :unconfigured]
  end

  # ---------------------------------------------------------------------------
  # Hermeticity self-assertion
  # ---------------------------------------------------------------------------

  test "phase 42 companion proof stays hermetic — no example-host or Code.require_file dependency" do
    source = File.read!(__ENV__.file) |> String.downcase()

    refute String.contains?(source, "crosswake" <> "example.router"),
           "phase 42 companion proof must not depend on the example host router; keep the merge-blocking lane hermetic"

    refute Regex.match?(~r/code\.require_file\s*\(/, source),
           "phase 42 companion proof must not Code.require_file example-host modules; keep the lane hermetic"
  end
end
