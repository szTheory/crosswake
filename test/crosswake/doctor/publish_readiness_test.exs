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

    assert Enum.any?(codes, &String.starts_with?(&1, "diag.publish."))
    assert Enum.any?(codes, &String.starts_with?(&1, "diag.companion."))
    assert Enum.any?(codes, &String.starts_with?(&1, "diag.provider."))
    assert Enum.any?(codes, &String.starts_with?(&1, "diag.notification."))
    assert Enum.any?(codes, &String.starts_with?(&1, "diag.auth."))
    assert Enum.any?(codes, &String.starts_with?(&1, "diag.shell."))
    assert Enum.any?(codes, &String.starts_with?(&1, "diag.docs."))
  end

  test "deferred support claims stay explicit and do not read as shipped support" do
    report = readiness_report()

    provider = find_check!(report, :provider_adapter_readiness)
    assert provider.result == :verification_required
    assert provider.blocking == false
    assert provider.message =~ "StoreKit"
    assert provider.message =~ "Play Billing"
    assert provider.message =~ "not shipped"
    assert provider.details.shipped? == false
    assert "purchase_intent.provider.storekit" in provider.details.promotion_rule_ids
    assert "purchase_intent.provider.play_billing" in provider.details.promotion_rule_ids

    assert provider.details.required_docs_anchors == [
             "guides/support_matrix.md",
             "guides/commerce.md"
           ]

    assert is_binary(provider.details.demotion_trigger)
    assert "provider_adapter" in provider.rebuild_requirement.action_classes

    auth = find_check!(report, :auth_session_predicate_readiness)
    assert auth.message =~ "Sigra"
    assert auth.message =~ "contract-only"
    assert :handoff in auth.details.deferred
    assert auth.details.promotion_rule_ids == ["auth.sigra.contract_only"]
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

  test "publish parity rejects empty or malformed source URLs" do
    for source_url <- ["", "github.com/szTheory/crosswake", "ftp://github.com/szTheory/crosswake"] do
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
      assert "source_url must be a non-empty http(s) URL" in publish.details.errors
    end
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
end
