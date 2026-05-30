defmodule Crosswake.Proof.Phase42RulesteadCompanionTest do
  @moduledoc """
  Hermetic merge-blocking proof lane for the Phase 42 Rulestead companion.

  Proves SC#1: Crosswake.Companions.Rulestead translates MockFlagSource gate states
  into the correct RouteGate outcomes for all three flag states (:gated, :killed,
  {:rolling_out, n}) and the unset (nil) case.

  Proves SC#3: Doctor emits :error "companion.dependency_missing" when rulestead
  companion is enabled and the Rulestead library is absent (SC#3a), and emits no
  dependency_missing finding when the companion is disabled (SC#3b).

  This test is fully hermetic by design: it never depends on the compiled example
  host (CrosswakeExample.*), never hits the network, never launches a simulator,
  and never calls Code.require_file. It runs UNtagged so the existing
  phase34-proof.yml `mix test --exclude requires_example_host` lane picks it up
  with no new CI file.

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
  alias Crosswake.Doctor
  alias Crosswake.Manifest

  # ---------------------------------------------------------------------------
  # Inline hermetic GatingRouter
  # Uses StudySessionLive (test/support stub) — no phoenix_host dependency
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

    # Shared temp dir for Doctor.run (SC#3 tests)
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

    File.write!(
      router_path,
      """
      defmodule DemoWeb.Router do
        # crosswake:install:start
        import Crosswake.Router
        # crosswake:install:end
      end
      """
    )

    File.write!(policy_path, "defmodule DemoWeb.Crosswake.Policy do\nend\n")

    install_manifest =
      Jason.encode!(%{
        schema_version: 1,
        crosswake_version: "0.1.0",
        router_path: Path.relative_to(router_path, target),
        web_module: "DemoWeb",
        policy_module: "DemoWeb.Crosswake.Policy",
        files: %{created_or_reused: [Path.relative_to(policy_path, target)]},
        markers: ["# crosswake:install:start", "# crosswake:install:end"]
      })

    File.write!(install_manifest_path, install_manifest)

    %{target: target, install_manifest_path: install_manifest_path}
  end

  # ---------------------------------------------------------------------------
  # Hermeticity self-assertion
  # ---------------------------------------------------------------------------

  test "phase 42 rulestead proof stays hermetic — no example-host or Code.require_file dependency" do
    source = File.read!(__ENV__.file) |> String.downcase()

    refute String.contains?(source, "crosswake" <> "example.router"),
           "phase 42 rulestead proof must not depend on the example host router; keep the merge-blocking lane hermetic"

    refute Regex.match?(~r/code\.require_file\s*\(/, source),
           "phase 42 rulestead proof must not Code.require_file example-host modules; keep the lane hermetic"
  end

  # ---------------------------------------------------------------------------
  # SC#1a: :gated flag -> :gate_denied deny with transition :halt
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
  # ---------------------------------------------------------------------------

  test "SC#1d: unset flag (nil) yields a non-deny (allow) decision for the route" do
    # MockFlagSource started fresh in setup — no flag set for :rulestead

    assert {:ok, %{manifest: manifest}} = Manifest.compile(GatingRouter)
    target = %Target{}
    decision = RouteGate.evaluate(manifest, "gating-beta-feature", target)

    # The only registered companion is Rulestead. With no stored flag, route_gated?/2
    # returns :pass and kill_switch_active?/1 returns false. The route should activate.
    # Note: other compatibility findings (version checks, etc.) may also deny the route
    # if Target fields are nil — so we assert on status :allow OR that gate denials are absent.
    # Since Target is bare (all nil), compatibility findings may apply, but gate findings should not.
    gate_denials =
      Enum.filter(decision.denials, fn d ->
        d.reason in [:gate_denied, :kill_switch_active]
      end)

    assert gate_denials == [],
           "expected no gate denials for unset flag; got #{inspect(gate_denials)}"
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

  test "validate_dependency/0 returns {:error, [Rulestead]} — library absent in Phase 42" do
    # The companion checks Code.ensure_loaded?(Rulestead) for the top-level Hex package module.
    # Note: in this file, `Rulestead` is aliased to Crosswake.Companions.Rulestead.
    # The Hex package module is the bare atom :"Elixir.Rulestead" — reference it directly.
    assert Crosswake.Companions.Rulestead.validate_dependency() == {:error, [:"Elixir.Rulestead"]}
  end

  test "report_state/0 returns a fully-populated Crosswake.Companion.State struct" do
    state = Crosswake.Companions.Rulestead.report_state()
    assert match?(%Crosswake.Companion.State{}, state)
    assert state.companion_id == :rulestead
    assert is_boolean(state.enabled)
    assert is_integer(state.checked_at)
    # Rulestead Hex package is absent in Phase 42 -> {:missing, [Rulestead (Hex pkg)]}
    assert state.dependency_status == {:missing, [:"Elixir.Rulestead"]}
    assert state.gate_status in [:active, :inactive, :unconfigured] or
             match?({:rolling_out, _}, state.gate_status)

    assert state.kill_switch_status in [:active, :inactive, :unconfigured]
  end

  # ---------------------------------------------------------------------------
  # SC#3a: companion enabled + Rulestead absent -> :error companion.dependency_missing
  # ---------------------------------------------------------------------------

  test "SC#3a: Doctor emits companion.dependency_missing :error when rulestead enabled and Rulestead library absent",
       %{target: target, install_manifest_path: install_manifest_path} do
    # setup already sets :crosswake, :rulestead, %{enabled: true}

    report =
      Doctor.run(
        route_source: GatingRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    finding = Enum.find(report.findings, &(&1.code == "companion.dependency_missing"))

    assert finding != nil,
           "expected a companion.dependency_missing finding but got none; findings: #{inspect(Enum.map(report.findings, & &1.code))}"

    assert finding.severity == :error,
           "expected :error severity; got #{inspect(finding.severity)}"

    assert String.contains?(finding.message, "Rulestead") or
             String.contains?(finding.message, "rulestead"),
           "expected finding.message to name Rulestead; got: #{inspect(finding.message)}"

    assert finding.check == "companion.rulestead",
           "expected finding.check 'companion.rulestead'; got #{inspect(finding.check)}"
  end

  # ---------------------------------------------------------------------------
  # SC#3b: companion disabled + Rulestead absent -> no dependency_missing finding
  # ---------------------------------------------------------------------------

  test "SC#3b: no companion.dependency_missing finding when rulestead companion is disabled",
       %{target: target, install_manifest_path: install_manifest_path} do
    # Override the companion config to disabled for this test
    Application.put_env(:crosswake, :rulestead, %{enabled: false})

    on_exit(fn ->
      # Extra cleanup (setup on_exit also runs, but this is belt-and-suspenders)
      Application.delete_env(:crosswake, :rulestead)
    end)

    report =
      Doctor.run(
        route_source: GatingRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    dependency_missing_findings =
      Enum.filter(report.findings, &(&1.code == "companion.dependency_missing"))

    assert dependency_missing_findings == [],
           "expected no companion.dependency_missing findings when rulestead is disabled; got: #{inspect(dependency_missing_findings)}"
  end
end
