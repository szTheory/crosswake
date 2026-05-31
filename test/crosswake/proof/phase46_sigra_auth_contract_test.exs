defmodule Crosswake.Proof.Phase46SigraAuthContractTest do
  use ExUnit.Case, async: false

  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Compatibility.Target
  alias Crosswake.Companions.Sigra.Contracts
  alias Crosswake.Companions.Sigra.Contracts.AuthContext
  alias Crosswake.Doctor
  alias Crosswake.Manifest
  alias Crosswake.Manifest.Types.RouteEntry
  alias Crosswake.SupportMatrix

  defmodule AuthPredicatedRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live "/secure", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "secure",
            runtime: :live_view,
            auth_min_level: :mfa,
            requires_recent_auth: 600
          ]
      end
    end
  end

  defmodule NonAuthRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live "/plain", Crosswake.TestSupport.StudySessionLive,
          crosswake: [id: "plain", runtime: :live_view]
      end
    end
  end

  defmodule KillSwitchCompanion do
    @behaviour Crosswake.Companion

    @impl true
    def companion_id, do: :phase46_kill_switch

    @impl true
    def enabled?(_config), do: true

    @impl true
    def route_gated?(_route, _target), do: :pass

    @impl true
    def kill_switch_active?(_target), do: true

    @impl true
    def validate_dependency, do: :ok

    @impl true
    def report_state do
      %Crosswake.Companion.State{
        companion_id: :phase46_kill_switch,
        enabled: true,
        dependency_status: :present,
        gate_status: :unconfigured,
        kill_switch_status: :active,
        checked_at: System.monotonic_time(:millisecond)
      }
    end
  end

  defmodule GateDenyCompanion do
    @behaviour Crosswake.Companion

    @impl true
    def companion_id, do: :phase46_gate_deny

    @impl true
    def enabled?(_config), do: true

    @impl true
    def route_gated?(%RouteEntry{gated_by: :test_flag}, _target), do: {:deny, :disabled}
    def route_gated?(_route, _target), do: :pass

    @impl true
    def kill_switch_active?(_target), do: false

    @impl true
    def validate_dependency, do: :ok

    @impl true
    def report_state do
      %Crosswake.Companion.State{
        companion_id: :phase46_gate_deny,
        enabled: true,
        dependency_status: :present,
        gate_status: :gated,
        kill_switch_status: :inactive,
        checked_at: System.monotonic_time(:millisecond)
      }
    end
  end

  defmodule GatedAndAuthRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live "/gated-auth", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "gated-auth",
            runtime: :live_view,
            gated_by: :test_flag,
            auth_min_level: :mfa,
            requires_recent_auth: 600
          ]
      end
    end
  end

  setup do
    Application.delete_env(:crosswake, :companions)
    :ok
  end

  test "manifest route entries carry auth predicates when declared" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(AuthPredicatedRouter)
    route = manifest.routes["secure"]
    route_map = Crosswake.Manifest.Types.to_map(route)

    assert route_map["auth_min_level"] == "mfa"
    assert route_map["requires_recent_auth"] == 600
  end

  test "manifest route entries omit auth predicates when undeclared" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(NonAuthRouter)
    route = manifest.routes["plain"]
    route_map = Crosswake.Manifest.Types.to_map(route)

    refute Map.has_key?(route_map, "auth_min_level")
    refute Map.has_key?(route_map, "requires_recent_auth")
  end

  test "phase 46 auth contract proof stays hermetic" do
    source = File.read!(__ENV__.file) |> String.downcase()

    refute String.contains?(source, "crosswake" <> "example.router")
    refute Regex.match?(~r/code\.require_file\s*\(/, source)
  end

  test "missing auth context fails closed with :step_up_required" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(AuthPredicatedRouter)
    target = %Target{origin: manifest.host.origin}

    decision = RouteGate.evaluate(manifest, "secure", target, [])

    assert decision.status == :deny
    assert decision.denial.reason == :step_up_required
    assert Map.keys(decision.denial.details) |> Enum.sort() == ["evaluated_at"]
  end

  test "weaker mfa and stale auth age deny with minimal typed details" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(AuthPredicatedRouter)
    target = %Target{origin: manifest.host.origin}

    auth_context =
      struct!(AuthContext,
        actor_id: "actor_123",
        org_id: "org_123",
        mfa_level: :password,
        auth_age: 1200
      )

    decision = RouteGate.evaluate(manifest, "secure", target, auth_context: auth_context)
    details = decision.denial.details

    assert decision.status == :deny
    assert decision.denial.reason == :step_up_required
    assert details["required_mfa_level"] == "mfa"
    assert details["current_mfa_level"] == "password"
    assert details["max_auth_age_seconds"] == 600
    assert details["auth_age_seconds"] == 1200
    assert is_binary(details["evaluated_at"])
    assert Enum.sort(Map.keys(details)) == [
             "auth_age_seconds",
             "current_mfa_level",
             "evaluated_at",
             "max_auth_age_seconds",
             "required_mfa_level"
           ]
  end

  test "kill-switch and gate denials short-circuit before auth checks" do
    assert {:ok, %{manifest: kill_manifest}} = Manifest.compile(GatedAndAuthRouter)
    assert {:ok, auth_context} = Contracts.new_auth_context(actor_id: "actor", org_id: "org", mfa_level: :none, auth_age: 9999)
    target = %Target{origin: kill_manifest.host.origin}

    Application.put_env(:crosswake, :companions, [KillSwitchCompanion])
    kill_decision = RouteGate.evaluate(kill_manifest, "gated-auth", target, auth_context: auth_context)
    assert kill_decision.denial.reason == :kill_switch_active

    Application.put_env(:crosswake, :companions, [GateDenyCompanion])
    gate_decision = RouteGate.evaluate(kill_manifest, "gated-auth", target, auth_context: auth_context)
    assert gate_decision.denial.reason == :gate_denied
  end

  test "doctor emits auth route and contract-only findings with stable codes" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(AuthPredicatedRouter)

    report =
      Doctor.run(
        route_source: AuthPredicatedRouter,
        install_manifest_path: "priv/crosswake/install_manifest.json",
        cwd: File.cwd!()
      )

    assert manifest.routes["secure"].auth_min_level == :mfa
    assert manifest.routes["secure"].requires_recent_auth == 600

    assert Enum.any?(report.findings, fn finding ->
             finding.code == "auth.route_predicated" and
               finding.details[:route_id] == "secure" and
               finding.details[:auth_min_level] == :mfa and
               finding.details[:requires_recent_auth] == 600
           end)

    assert Enum.any?(report.findings, &(&1.code == "auth.step_up_required_contract"))
  end

  test "support truth and denial vocabulary align with phase 46 stable auth terms" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(AuthPredicatedRouter)
    target = %Target{origin: manifest.host.origin}

    decision = RouteGate.evaluate(manifest, "secure", target, [])
    auth_truth = SupportMatrix.auth_contract_truth()

    assert [%{} = row] = auth_truth
    assert row.owner == :backend_seam
    assert row.package_class == :companion
    assert row.proof_class == :merge_blocking
    assert row.route_predicates == [:auth_min_level, :requires_recent_auth]
    assert row.denial_vocabulary == :step_up_required
    assert row.fallback == :step_up_required
    assert row.surface =~ "AuthContext"
    assert row.surface =~ "SessionAuthorityLane"

    assert manifest.routes["secure"].auth_min_level == :mfa
    assert manifest.routes["secure"].requires_recent_auth == 600
    assert decision.denial.reason == :step_up_required
  end

end
