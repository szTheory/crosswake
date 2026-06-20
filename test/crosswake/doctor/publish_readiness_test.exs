defmodule Crosswake.Doctor.PublishReadinessTest do
  use ExUnit.Case, async: false

  alias Crosswake.Doctor.PublishReadiness
  alias Crosswake.TestSupport.StubCompanion

  defmodule PageController do
    def init(opts), do: opts
    def call(conn, _opts), do: conn
  end

  defmodule ReadinessRouter do
    use Crosswake.Router

    pipeline :browser do
      plug(:accepts, ["html"])
    end

    scope "/" do
      pipe_through(:browser)

      get("/billing", Elixir.Crosswake.Doctor.PublishReadinessTest.PageController, :billing,
        crosswake: [
          id: "billing",
          runtime: :live_view,
          security: :sensitive,
          commerce: [corridor: :subscription_default, role: :purchase_intent]
        ]
      )

      get(
        "/notifications",
        Elixir.Crosswake.Doctor.PublishReadinessTest.PageController,
        :notifications,
        crosswake: [
          id: "notifications",
          runtime: :live_view,
          security: :standard,
          capabilities: ["notification_token"]
        ]
      )

      get("/secure", Elixir.Crosswake.Doctor.PublishReadinessTest.PageController, :secure,
        crosswake: [
          id: "secure",
          runtime: :live_view,
          security: :sensitive,
          auth_min_level: :mfa,
          requires_recent_auth: 600
        ]
      )

      get("/gated", Elixir.Crosswake.Doctor.PublishReadinessTest.PageController, :gated,
        crosswake: [
          id: "gated",
          runtime: :live_view,
          security: :standard,
          gated_by: :stub_companion
        ]
      )
    end
  end

  setup do
    previous = Application.get_env(:crosswake, :companions)
    Application.put_env(:crosswake, :companions, [StubCompanion])

    on_exit(fn ->
      if is_nil(previous) do
        Application.delete_env(:crosswake, :companions)
      else
        Application.put_env(:crosswake, :companions, previous)
      end
    end)
  end

  test "report includes the stable publish-readiness check contract" do
    report = readiness_report()

    assert report.schema_version == "1.0.0"
    assert report.status in [:ready, :not_ready]
    assert is_map(report.summary)
    assert is_list(report.checks)
    assert length(report.checks) > 0

    for check <- report.checks do
      assert is_binary(check.id)
      assert is_binary(check.code)
      assert check.severity in [:error, :warning, :advisory]
      assert check.result in [:pass, :fail, :verification_required, :advisory]
      assert is_boolean(check.blocking)
      assert is_binary(check.message)
      assert is_binary(check.hint)

      assert check.docs_reference in [
               "guides/support_matrix.md",
               "guides/compatibility.md",
               "guides/companions.md",
               "guides/commerce.md",
               "guides/native_shell.md",
               "guides/capabilities.md",
               "guides/install.md",
               "CHANGELOG.md"
             ]

      assert check.proof_class in [:merge_blocking, :advisory, :not_applicable]
      assert is_map(check.rebuild_requirement)
      assert is_binary(check.claim_scope)
      assert is_map(check.details)
    end
  end

  test "all required categories and stable diagnostic code prefixes are present" do
    report = readiness_report()

    categories = Enum.map(report.checks, & &1.category)
    codes = Enum.map(report.checks, & &1.code)

    assert :publish_parity in categories
    assert :companion_dependency_health in categories
    assert :provider_adapter_readiness in categories
    assert :notification_token_readiness in categories
    assert :auth_session_predicate_readiness in categories
    assert :native_shell_verification_gap in categories
    assert :docs_support_parity in categories
    assert :proof_posture in categories
    assert :generator_coordinate_parity in categories
    assert :contract_version_parity in categories

    assert Enum.any?(codes, &String.starts_with?(&1, "diag.publish."))
    assert Enum.any?(codes, &String.starts_with?(&1, "diag.companion."))
    assert Enum.any?(codes, &String.starts_with?(&1, "diag.provider."))
    assert Enum.any?(codes, &String.starts_with?(&1, "diag.notification."))
    assert Enum.any?(codes, &String.starts_with?(&1, "diag.auth."))
    assert Enum.any?(codes, &String.starts_with?(&1, "diag.shell."))
    assert Enum.any?(codes, &String.starts_with?(&1, "diag.docs."))
    assert Enum.any?(codes, &String.starts_with?(&1, "diag.generator."))
    assert Enum.any?(codes, &String.starts_with?(&1, "diag.contract."))
  end

  test "generator coordinate parity blocks stale or local native dependency coordinates" do
    target = tmp_dir!("crosswake-publish-readiness")

    ios_template_relative =
      "priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex"

    android_template_relative = "priv/templates/crosswake/shell/android/app/build.gradle.eex"
    ios_template = Path.join(target, ios_template_relative)
    android_template = Path.join(target, android_template_relative)

    File.mkdir_p!(Path.dirname(ios_template))
    File.mkdir_p!(Path.dirname(android_template))

    File.write!(ios_template, """
    XCLocalSwiftPackageReference
    https://github.com/crosswake/crosswake-shell-core-ios.git
    kind = exactVersion;
    """)

    File.write!(android_template, """
    implementation 'dev.crosswake:shell-core-android:0.1.0'
    implementation project(':crosswake-shell-core-android')
    """)

    report =
      readiness_report(
        cwd: target,
        changelog_contents: File.read!("CHANGELOG.md")
      )

    parity = find_check!(report, :generator_coordinate_parity)
    expected_version = Application.spec(:crosswake, :vsn) |> to_string()

    assert parity.blocking
    assert parity.result == :fail
    assert parity.severity == :error
    assert parity.proof_class == :merge_blocking
    assert parity.docs_reference == "guides/install.md"
    assert parity.details.version == expected_version
    assert parity.details.ios_template == ios_template_relative
    assert parity.details.android_template == android_template_relative

    assert "iOS URL missing szTheory org" in parity.details.errors
    assert "iOS template missing version #{parity.details.version}" in parity.details.errors

    assert "iOS non-local branch must not emit XCLocalSwiftPackageReference" in parity.details.errors

    assert "iOS template must not reference old crosswake/ org" in parity.details.errors
    assert "Android GAV missing io.github.sztheory" in parity.details.errors

    assert "Android template must not reference dev.crosswake:shell-core-android" in parity.details.errors

    assert "Android non-local branch must not reference local project" in parity.details.errors
  end

  test "deferred support claims stay explicit and do not read as shipped support" do
    report = readiness_report()

    provider = find_check!(report, :provider_adapter_readiness)
    assert provider.result == :verification_required
    assert provider.blocking == false
    assert provider.message =~ "StoreKit"
    assert provider.message =~ "Play Billing"
    assert provider.message =~ "seams are shipped"
    assert provider.details.shipped_seams? == true
    assert provider.details.advisory_provider_proof? == true
    assert provider.details.storekit_check_id == "diag.provider.storekit.advisory_proof"
    assert provider.details.play_billing_check_id == "diag.provider.play_billing.advisory_proof"
    assert provider.details.native_rebuild_required? == true
    assert "purchase_intent.provider.storekit" in provider.details.promotion_rule_ids
    assert "purchase_intent.provider.play_billing" in provider.details.promotion_rule_ids
    assert "storekit_sandbox_account" in provider.details.setup_required
    assert "play_billing_license_tester" in provider.details.setup_required

    assert provider.details.required_docs_anchors == [
             "guides/support_matrix.md",
             "guides/commerce.md"
           ]

    assert is_binary(provider.details.demotion_trigger)
    assert "provider_adapter" in provider.rebuild_requirement.action_classes

    auth = find_check!(report, :auth_session_predicate_readiness)
    assert auth.message =~ "Sigra"
    assert auth.message =~ "session-authority"
    assert auth.message =~ "handoff ticket/server-record contract machinery"
    assert auth.message =~ "step-up intent plus Plug/LiveView ceremony"
    assert auth.message =~ "auth-return boundary contracts are shipped"
    refute :handoff in auth.details.deferred
    refute :ceremony in auth.details.deferred
    refute :auth_return_boundaries in auth.details.deferred

    assert auth.details.shipped_contracts == [
             :session_authority,
             :handoff_ticket,
             :server_record_redemption,
             :step_up_intent,
             :plug_liveview_ceremony,
             :auth_return_boundary,
             :auth_return_attempt
           ]

    assert auth.details.handoff.authority_source == :server_record
    assert auth.details.step_up.status == :shipped
    assert auth.code == "diag.auth.sigra_session_authority"
    assert auth.details.posture == :session_authority
    assert :auth_posture in auth.details.route_predicates
    assert "auth.step_up.missing_context" in auth.details.denial_codes
    assert "auth.handoff.invalid_ticket" in auth.details.denial_codes
    assert "auth.step_up_intent.invalid_intent" in auth.details.denial_codes
    assert "handoff_ref" in auth.details.safe_detail_keys
    assert "step_up_intent_ref" in auth.details.safe_detail_keys
    assert auth.details.promotion_rule_ids == ["auth.sigra.session_authority"]
    assert "companion_native" in auth.rebuild_requirement.action_classes

    notifications = find_check!(report, :notification_token_readiness)
    assert notifications.message =~ "delivery is not supported"
    assert notifications.details.delivery_supported? == false
    assert notifications.details.promotion_rule_ids == ["notification_token.provider_snapshot"]

    assert notifications.details.required_docs_anchors == [
             "guides/support_matrix.md",
             "guides/capabilities.md"
           ]

    assert is_binary(notifications.details.demotion_trigger)
    assert "companion_native" in notifications.rebuild_requirement.action_classes

    shell = find_check!(report, :native_shell_verification_gap)
    assert shell.result == :verification_required
    assert shell.message =~ "verification-required"
    refute shell.message =~ "fully supported"
    assert "shell.android.generated_project" in shell.details.promotion_rule_ids
    assert "guides/native_shell.md" in shell.details.required_docs_anchors
    assert is_binary(shell.details.demotion_trigger)
    assert "native_shell" in shell.rebuild_requirement.action_classes
  end

  test "blocking status is driven by deterministic local publish errors only" do
    report =
      readiness_report(
        changelog_contents: """
        # Changelog

        ## [0.1.0]
        """
      )

    assert report.status == :not_ready

    assert Enum.any?(report.checks, fn check ->
             check.category == :publish_parity and check.blocking and check.severity == :error and
               check.code == "diag.publish.changelog_missing_unreleased"
           end)

    assert report.summary.blocking_count >= 1
    assert report.summary.warning_count >= 1
  end

  test "publish parity requires the v3.6 unreleased support-truth split" do
    report =
      readiness_report(
        changelog_contents: """
        # Changelog

        ## Planning milestones vs Hex releases

        planning milestones and published Hex release truth are distinct.

        ## [Unreleased]

        ### Unpublished support claims

        ### Deferred non-shipped claims

        ## [0.1.0]
        """
      )

    publish = find_check!(report, :publish_parity)

    assert publish.blocking

    assert publish.code in [
             "diag.publish.local_truth_failed",
             "diag.publish.changelog_missing_unreleased"
           ]

    assert Enum.any?(publish.details.errors, fn error ->
             error =~ "[Unreleased] must split unpublished support claims"
           end)
  end

  test "publish parity rejects false shipped language for deferred surfaces" do
    report =
      readiness_report(
        changelog_contents: """
        # Changelog

        ## Planning milestones vs Hex releases

        planning milestones and published Hex release truth are distinct.

        ## [Unreleased]

        ### Unpublished support claims

        ### Verification-required and advisory surfaces

        ### Deferred non-shipped claims

        StoreKit provider adapter shipped.

        ### Published Hex truth

        Latest published Hex release is 0.1.0.

        ## [0.1.0]
        """
      )

    publish = find_check!(report, :publish_parity)

    assert publish.blocking

    assert "CHANGELOG.md must not describe deferred provider, auth, notification, or shell work as shipped" in publish.details.errors
  end

  test "publish parity rejects empty, malformed, or non-HTTPS source URLs" do
    for source_url <- [
          "",
          "github.com/szTheory/crosswake",
          "ftp://github.com/szTheory/crosswake",
          "http://github.com/szTheory/crosswake"
        ] do
      report =
        readiness_report(
          project_config: [
            version: "0.1.0",
            source_url: source_url,
            package: [name: "crosswake"]
          ]
        )

      publish = find_check!(report, :publish_parity)

      assert publish.blocking
      assert publish.severity == :error
      assert publish.code == "diag.publish.local_truth_failed"
      assert "source_url must be a non-empty https URL" in publish.details.errors
    end
  end

  test "publish parity derives the required changelog section from the current project version" do
    report =
      readiness_report(
        project_config: [
          version: "0.2.0",
          source_url: "https://github.com/szTheory/crosswake",
          package: [name: "crosswake"]
        ]
      )

    publish = find_check!(report, :publish_parity)

    assert publish.blocking
    assert publish.code == "diag.publish.local_truth_failed"
    assert "CHANGELOG.md must include the current [0.2.0] release" in publish.details.errors
  end

  defp readiness_report(opts \\ []) do
    PublishReadiness.run(
      Keyword.merge(
        [
          route_source: ReadinessRouter,
          generated_at: "2026-05-31T00:00:00Z",
          cwd: File.cwd!()
        ],
        opts
      )
    )
  end

  defp find_check!(report, category) do
    Enum.find(report.checks, &(&1.category == category)) ||
      flunk(
        "expected #{inspect(category)} check in #{inspect(Enum.map(report.checks, & &1.category))}"
      )
  end

  defp tmp_dir!(prefix) do
    path = Path.join(System.tmp_dir!(), "#{prefix}-#{System.unique_integer([:positive])}")
    File.rm_rf!(path)
    File.mkdir_p!(path)
    path
  end
end
