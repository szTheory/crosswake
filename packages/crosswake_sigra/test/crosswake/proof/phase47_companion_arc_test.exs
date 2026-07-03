defmodule Crosswake.Proof.Phase47CompanionArcTest do
  use ExUnit.Case, async: false

  # D-137-03: StubRulesteadAbsentCompanion and StubRindleAbsentCompanion are core
  # test support modules not available in the package load path. Inline stubs mirror
  # the absent-engine pattern (validate_dependency returns {:error, [missing_module]}).
  defmodule StubRulesteadAbsent do
    @behaviour Crosswake.Companion
    def companion_id, do: :rulestead
    def enabled?(%{enabled: false}), do: false
    def enabled?(_), do: true
    def validate_dependency, do: {:error, [Rulestead.Engine]}
    def report_state, do: %{status: :dependency_missing}
    def route_gated?(_route_id, _companion_id), do: false
    def kill_switch_active?(_config), do: false
  end

  defmodule StubRindleAbsent do
    @behaviour Crosswake.Companion
    def companion_id, do: :rindle
    def enabled?(%{enabled: false}), do: false
    def enabled?(_), do: true
    def validate_dependency, do: {:error, [Rindle.Engine]}
    def report_state, do: %{status: :dependency_missing}
    def route_gated?(_route_id, _companion_id), do: false
    def kill_switch_active?(_config), do: false
  end

  alias Crosswake.Proof.Phase47CompanionArcTest.StubRulesteadAbsent, as: Rulestead
  alias Crosswake.Proof.Phase47CompanionArcTest.StubRindleAbsent, as: Rindle
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
        live("/companion/proof", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "companion-proof-route"
          ]
        )
      end
    end
  end

  defmodule AuthPredicatedRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live("/secure", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "secure",
            runtime: :live_view,
            auth_min_level: :mfa,
            requires_recent_auth: 600
          ]
        )
      end
    end
  end

  setup do
    original_companions = Application.get_env(:crosswake, :companions, [])
    original_rulestead = Application.get_env(:crosswake, :rulestead)
    original_rindle = Application.get_env(:crosswake, :rindle)

    # Post-inversion fix: include Sigra (the in-tree auth authority facade) so
    # auth-predicated routes get :step_up_required instead of :dependency_missing,
    # and SupportMatrix.auth_contract_truth/0 populates denial_codes from the
    # registered auth-authority companion. Pre-inversion, Sigra.Evaluator was called
    # directly regardless of the registry; now it must be registered.
    Application.put_env(:crosswake, :companions, [Crosswake.Companions.Sigra, Rulestead, Rindle])
    Application.put_env(:crosswake, :rulestead, %{enabled: true})
    Application.put_env(:crosswake, :rindle, %{enabled: true})

    target =
      Path.join(
        System.tmp_dir!(),
        "crosswake-phase47-proof-#{System.unique_integer([:positive])}"
      )

    on_exit(fn ->
      File.rm_rf(target)
      restore_env(:companions, original_companions)
      restore_env(:rulestead, original_rulestead)
      restore_env(:rindle, original_rindle)
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

  test "enabled optional dependency findings track live companion validation outcomes",
       %{target: target, install_manifest_path: install_manifest_path} do
    report =
      Doctor.run(
        route_source: CompanionRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    findings_by_check =
      report.findings
      |> Enum.filter(&(&1.code == "companion.dependency_missing"))
      |> Map.new(&{&1.check, &1})

    for companion <- [Rulestead, Rindle] do
      check = "companion.#{companion.companion_id()}"

      case companion.validate_dependency() do
        :ok ->
          refute Map.has_key?(findings_by_check, check)

        {:error, missing_modules} ->
          finding = Map.fetch!(findings_by_check, check)

          assert finding.severity == :error

          for missing_module <- missing_modules do
            assert missing_module in finding.details.missing_modules
          end
      end
    end
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

  test "sigra auth truth reflects session-authority posture with step_up_required fallback" do
    assert [%{} = row] = SupportMatrix.auth_contract_truth()

    assert row.route_predicates == [:auth_min_level, :requires_recent_auth, :auth_posture]
    assert row.denial_vocabulary == :step_up_required
    assert "auth.step_up.missing_context" in row.denial_codes
    assert row.fallback == :step_up_required
    assert row.surface =~ "SessionAuthorityLane"
    assert row.posture =~ "SessionAuthorityLane"
    assert row.posture =~ "handoff ticket/server-record redemption"
    assert "auth.handoff.invalid_ticket" in row.denial_codes
    refute :ceremony in row.deferred
    refute :handoff in row.deferred
    assert row.posture =~ "passkey"
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
      RouteGate.evaluate(manifest, "secure", target, auth_context: weak_auth_context)

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

  defp restore_env(key, nil), do: Application.delete_env(:crosswake, key)
  defp restore_env(key, value), do: Application.put_env(:crosswake, key, value)
end
