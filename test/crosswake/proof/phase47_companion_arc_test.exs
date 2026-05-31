defmodule Crosswake.Proof.Phase47CompanionArcTest do
  use ExUnit.Case, async: false

  alias Crosswake.Companions.Rindle
  alias Crosswake.Companions.Rulestead
  alias Crosswake.Companions.Sigra.Contracts.AuthContext
  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Compatibility.Target
  alias Crosswake.Doctor
  alias Crosswake.Manifest
  alias Crosswake.Shell.Denial
  alias Crosswake.SupportMatrix

  defmodule CompanionRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live "/companion/proof", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "companion-proof-route"
          ]
      end
    end
  end

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

  setup do
    Application.put_env(:crosswake, :companions, [Rulestead, Rindle])
    Application.put_env(:crosswake, :rulestead, %{enabled: true})
    Application.put_env(:crosswake, :rindle, %{enabled: true})

    target =
      Path.join(
        System.tmp_dir!(),
        "crosswake-phase47-proof-#{System.unique_integer([:positive])}"
      )

    on_exit(fn ->
      File.rm_rf(target)
      Application.delete_env(:crosswake, :companions)
      Application.delete_env(:crosswake, :rulestead)
      Application.delete_env(:crosswake, :rindle)
    end)

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

  test "enabled missing optional dependencies emit separate companion.dependency_missing errors",
       %{target: target, install_manifest_path: install_manifest_path} do
    report =
      Doctor.run(
        route_source: CompanionRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    findings =
      Enum.filter(report.findings, &(&1.code == "companion.dependency_missing"))

    assert Enum.any?(findings, &(&1.check == "companion.rulestead"))
    assert Enum.any?(findings, &(&1.check == "companion.rindle"))
    assert Enum.all?(findings, &(&1.severity == :error))

    rulestead_finding = Enum.find(findings, &(&1.check == "companion.rulestead"))
    rindle_finding = Enum.find(findings, &(&1.check == "companion.rindle"))

    assert :"Elixir.Rulestead" in rulestead_finding.details.missing_modules
    assert :"Elixir.Rindle" in rindle_finding.details.missing_modules
  end

  test "disabled companions suppress dependency_missing findings",
       %{target: target, install_manifest_path: install_manifest_path} do
    Application.put_env(:crosswake, :rulestead, %{enabled: false})
    Application.put_env(:crosswake, :rindle, %{enabled: false})

    report =
      Doctor.run(
        route_source: CompanionRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    assert Enum.filter(report.findings, &(&1.code == "companion.dependency_missing")) == []
  end

  test "sigra auth contract truth stays contract-only with step_up_required posture" do
    assert [%{} = row] = SupportMatrix.auth_contract_truth()

    assert row.route_predicates == [:auth_min_level, :requires_recent_auth]
    assert row.denial_vocabulary == :step_up_required
    assert row.fallback == :step_up_required
    assert row.surface =~ "AuthContext"
    assert row.posture =~ "Contract-only in Phase 46"
  end

  test "auth-predicated route denies with step_up_required when context is missing or weak" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(AuthPredicatedRouter)
    target = %Target{origin: manifest.host.origin}

    missing_context_decision = RouteGate.evaluate(manifest, "secure", target, [])

    assert missing_context_decision.status == :deny
    assert missing_context_decision.denial.reason == :step_up_required
    assert Map.has_key?(missing_context_decision.denial.details, "evaluated_at")

    weak_auth_context =
      struct!(AuthContext,
        actor_id: "actor_123",
        org_id: "org_123",
        mfa_level: :password,
        auth_age: 1200
      )

    weak_context_decision =
      RouteGate.evaluate(manifest, "secure", target,
        auth_context: weak_auth_context
      )

    assert weak_context_decision.status == :deny
    assert weak_context_decision.denial.reason == :step_up_required
    assert weak_context_decision.denial.details["required_mfa_level"] == "mfa"
    assert weak_context_decision.denial.details["current_mfa_level"] == "password"
    assert weak_context_decision.denial.details["max_auth_age_seconds"] == 600
    assert weak_context_decision.denial.details["auth_age_seconds"] == 1200
  end

  test "hermetic lane guard: proof file remains untagged and env-independent" do
    source = File.read!(__ENV__.file)

    refute Regex.match?(~r/^\s*@moduletag\s+:advisory_only\b/m, source)
    refute String.contains?(source, "Crosswake" <> "Example."),
           "phase 47 proof must not depend on example host modules"
    refute Regex.match?(~r/code\.require_file\s*\(/, source)
    refute String.contains?(source, "MIX_INCLUDE_" <> "RULESTEAD")
    refute String.contains?(source, "MIX_INCLUDE_" <> "RINDLE")
  end

  test "hermetic lane guard: denial vocabulary keeps step_up_required reason" do
    assert :step_up_required in Denial.reasons()
  end
end
