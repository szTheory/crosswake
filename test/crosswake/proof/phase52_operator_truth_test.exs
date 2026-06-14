defmodule Crosswake.Proof.Phase52OperatorTruthTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Crosswake.TestSupport.ProofAssertions

  @inspect_task "crosswake.inspect"
  @inspect_fixture "test/fixtures/proof/phase52_operator_inspection.json"
  @readiness_fixture "test/fixtures/proof/phase52_publish_readiness.json"

  setup do
    target =
      Path.join(
        System.tmp_dir!(),
        "crosswake-phase52-proof-#{System.unique_integer([:positive])}"
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

    File.write!(
      install_manifest_path,
      Jason.encode!(%{
        schema_version: 1,
        crosswake_version: "0.1.0",
        router_path: Path.relative_to(router_path, target),
        web_module: "DemoWeb",
        policy_module: "DemoWeb.Crosswake.Policy",
        files: %{created_or_reused: [Path.relative_to(policy_path, target)]},
        markers: ["# crosswake:install:start", "# crosswake:install:end"]
      })
    )

    on_exit(fn -> File.rm_rf(target) end)

    %{install_manifest_path: install_manifest_path}
  end

  @tag :phase52_smoke
  test "stable proof id helper contract is present for operator drift checks" do
    message =
      ProofAssertions.stable_id_message(
        "proof.operator.inspect.schema_version",
        "operator inspection schema version",
        "Crosswake.OperatorInspection.Types.schema_version/0",
        "schema_version drift",
        "test/fixtures/proof/phase52_operator_inspection.json",
        "update canonical inspection output and fixture together",
        :merge_blocking
      )

    assert message =~ "proof.operator.inspect.schema_version"
    assert message =~ "merge_blocking"
  end

  test "normalized inspect json matches fixture and keeps schema stable" do
    output =
      capture_io(fn ->
        Mix.Task.reenable(@inspect_task)

        Mix.Task.run(@inspect_task, [
          "--router",
          "Elixir.Crosswake.TestSupport.RouterFixtures.ManagedRouter",
          "--format",
          "json"
        ])
      end)

    assert output =~ "\"schema_version\""

    ProofAssertions.assert_normalized_json_fixture(
      "proof.operator.inspect.json_contract",
      output,
      @inspect_fixture,
      source: "mix crosswake.inspect --format json",
      path: @inspect_fixture,
      hint: "normalize volatile fields and refresh fixture only for intended semantic changes",
      posture: :merge_blocking
    )
  end

  test "normalized publish-readiness json matches fixture and keeps readiness semantics stable",
       %{install_manifest_path: install_manifest_path} do
    output =
      capture_io(fn ->
        assert_raise Mix.Error, "Crosswake doctor found blocking issues", fn ->
          Mix.Tasks.Crosswake.Doctor.run([
            "--router",
            "Elixir.Crosswake.TestSupport.RouterFixtures.ManagedRouter",
            "--install-manifest",
            install_manifest_path,
            "--format",
            "json",
            "--check-publish"
          ])
        end
      end)

    decoded = Jason.decode!(output)
    assert decoded["publish_readiness"]["schema_version"] == "1.0.0"

    for check <- decoded["publish_readiness"]["checks"] do
      assert is_boolean(check["blocking"])
      assert is_boolean(check["rebuild_requirement"]["native_required"])
      assert is_boolean(check["rebuild_requirement"]["companion_required"])
    end

    provider = find_readiness_check!(decoded, "provider.adapter_readiness")
    assert provider["details"]["shipped_seams?"]
    assert provider["details"]["advisory_provider_proof?"]

    notification = find_readiness_check!(decoded, "notification.token_readiness")
    refute notification["details"]["delivery_supported?"]

    auth = find_readiness_check!(decoded, "auth.session_predicate_readiness")

    assert auth["details"]["demotion_trigger"] =~
             "handoff/step-up/auth-return server-record proof"

    ProofAssertions.assert_normalized_json_fixture(
      "proof.readiness.publish.json_contract",
      Jason.encode!(decoded["publish_readiness"]),
      @readiness_fixture,
      source: "mix crosswake.doctor --check-publish --format json",
      path: @readiness_fixture,
      hint:
        "preserve readiness category/code/proof-class/rebuild semantics when updating fixture",
      posture: :merge_blocking
    )
  end

  test "support matrix generated guide and authored docs keep non-claims in sync" do
    ProofAssertions.assert_file_exact(
      "proof.docs.support_matrix.byte_parity",
      "guides/support_matrix.md",
      Crosswake.SupportMatrix.Renderer.render(Crosswake.SupportMatrix.canonical()),
      source: "Crosswake.SupportMatrix.Renderer.render/1",
      hint: "regenerate support matrix guide from canonical renderer output",
      posture: :merge_blocking
    )

    ProofAssertions.assert_contains_exact(
      "proof.docs.non_claims.store_providers",
      "guides/support_matrix.md",
      "StoreKit and Play Billing provider adapter seams are shipped, but provider/storefront proof remains advisory until promotion criteria pass",
      source: "Crosswake.SupportMatrix.canonical/1",
      hint: "keep provider non-claims explicit in public docs",
      posture: :merge_blocking
    )

    ProofAssertions.assert_contains_exact(
      "proof.docs.non_claims.sigra_session_authority",
      "guides/companions.md",
      "Sigra now ships the backend-owned session-authority route evaluator, Phase 55 handoff ticket contract machinery, Phase 56 server-owned step-up intent plus shared Plug/LiveView ceremony, Phase 57 OAuth/passkey/native auth-return boundary contracts, Phase 58 auth telemetry plus security closeout, and Phase 73 auth-sensitive admin workflow proof.",
      source: "guides/companions.md and auth contract support truth",
      hint:
        "distinguish shipped Sigra contract machinery from provider/device and native auth non-claims",
      posture: :merge_blocking
    )

    ProofAssertions.assert_contains_exact(
      "proof.docs.non_claims.notification_snapshot",
      "guides/compatibility.md",
      "notification-token readiness is provider-snapshot only",
      source: "guides/compatibility.md and support truth notification posture",
      hint: "do not imply notification delivery support shipped",
      posture: :merge_blocking
    )

    ProofAssertions.assert_contains_exact(
      "proof.docs.non_claims.chimeway_deferred",
      "guides/companions.md",
      "Chimeway delivery implementation",
      source: "guides/companions.md and support truth notification posture",
      hint: "keep deferred push-delivery truth explicit",
      posture: :merge_blocking
    )

    ProofAssertions.assert_contains_exact(
      "proof.docs.non_claims.shell_core_packages",
      "guides/support_matrix.md",
      "Standalone native shell core packages are consumed by generated host-owned wrappers",
      source: "Crosswake.SupportMatrix.canonical/1 package surfaces",
      hint:
        "preserve published shell-core package claim scope without widening native runtime proof",
      posture: :merge_blocking
    )

    ProofAssertions.assert_contains_exact(
      "proof.docs.non_claims.compatibility_window_distinct",
      "guides/compatibility.md",
      "compatibility-window narrowing is distinct from a native rebuild",
      source: "guides/compatibility.md runtime line rules",
      hint: "keep compatibility-window narrowing distinct from rebuild claims",
      posture: :merge_blocking
    )
  end

  test "hermetic lane guard keeps module untagged at file level and env-independent" do
    source = File.read!(__ENV__.file)

    refute Regex.match?(~r/^\s*@moduletag\s+:/m, source)
    refute String.contains?(source, "Crosswake" <> "Example.")
    refute String.contains?(source, "MIX_INCLUDE_" <> "RULESTEAD")
    refute String.contains?(source, "MIX_INCLUDE_" <> "RINDLE")
  end

  test "denial, support-status, proof-class, action-class, and promotion-rule vocabularies stay canonical" do
    reasons = Crosswake.Shell.Denial.reasons()
    assert :step_up_required in reasons
    assert :gate_denied in reasons

    statuses = Crosswake.SupportMatrix.statuses()
    assert statuses == [:supported, :verification_required, :unsupported]

    assert Crosswake.SupportMatrix.proof_classes() == [
             :merge_blocking,
             :advisory,
             :not_applicable
           ]

    action_classes =
      Crosswake.SupportMatrix.action_classes()
      |> Enum.map(& &1.action_class)

    for required <- [
          "docs_only",
          "route_manifest",
          "compatibility",
          "native_shell",
          "companion_native",
          "provider_adapter"
        ] do
      assert required in action_classes
    end

    promotion_ids =
      Crosswake.SupportMatrix.promotion_rules()
      |> Enum.map(& &1.claim_id)

    for required <- [
          "notification_token.provider_snapshot",
          "auth.sigra.session_authority",
          "purchase_intent.provider.storekit",
          "purchase_intent.provider.play_billing"
        ] do
      assert required in promotion_ids
    end
  end

  defp find_readiness_check!(decoded, id) do
    Enum.find(decoded["publish_readiness"]["checks"], &(&1["id"] == id)) ||
      flunk("missing publish readiness check #{id}")
  end
end
