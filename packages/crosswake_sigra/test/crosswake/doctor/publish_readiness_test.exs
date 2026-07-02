defmodule Crosswake.Doctor.PublishReadinessTest do
  # D-137-03: Moved from core test suite. PublishReadiness.run/1 calls
  # Crosswake.Companions.Sigra.companion_id/0 at runtime (via SupportMatrix); moving
  # to crosswake_sigra package ensures the module is available in the load path.
  # Path adjustments: File.read!("../../CHANGELOG.md"), cwd: Path.expand("../../", File.cwd!())
  use ExUnit.Case, async: false

  alias Crosswake.Doctor.PublishReadiness

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
    previous = Application.get_env(:crosswake, :companions, [])
    # D-137-03: Register Sigra as the auth-authority companion so the publish-readiness
    # auth check sees the Sigra contract. StubCompanion (core test support) is not
    # available in the package load path.
    Application.put_env(:crosswake, :companions, [Crosswake.Companions.Sigra])

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
    assert :compatibility_rebuild_guidance in categories

    assert Enum.any?(codes, &String.starts_with?(&1, "diag.publish."))
    assert Enum.any?(codes, &String.starts_with?(&1, "diag.companion."))
    assert Enum.any?(codes, &String.starts_with?(&1, "diag.provider."))
    assert Enum.any?(codes, &String.starts_with?(&1, "diag.notification."))
    assert Enum.any?(codes, &String.starts_with?(&1, "diag.auth."))
    assert Enum.any?(codes, &String.starts_with?(&1, "diag.shell."))
    assert Enum.any?(codes, &String.starts_with?(&1, "diag.docs."))
    assert Enum.any?(codes, &String.starts_with?(&1, "diag.generator."))
    assert Enum.any?(codes, &String.starts_with?(&1, "diag.contract."))
    assert Enum.any?(codes, &String.starts_with?(&1, "diag.compat."))
  end

  test "contract version parity check passes on the real committed tree" do
    report = readiness_report()

    check = find_check!(report, :contract_version_parity)

    refute check.blocking,
           "contract_version_parity should not be blocking on the real tree (all surfaces should carry #{Crosswake.Bridge.Contract.version()})"

    assert check.result == :pass
    assert check.severity == :advisory
    assert check.proof_class == :merge_blocking
    assert check.details.version == Crosswake.Bridge.Contract.version()
    assert check.details.errors == []
  end

  test "contract version parity blocks when an ios manifest carries wrong bridge_protocol_version" do
    target = tmp_dir!("crosswake-contract-version-parity")
    expected = Crosswake.Bridge.Contract.version()

    # Seed the iOS manifest with a wrong bridge_protocol_version under the
    # "compatibility" key — this mirrors how the real manifests store the field
    # (nested, not at the JSON document root).
    ios_manifest_rel = "examples/ios_shell_host/Fixtures/crosswake_manifest.json"
    android_manifest_rel = "examples/android_shell_host/app/src/main/assets/crosswake_manifest.json"
    ios_activation_rel = "examples/ios_shell_host/Fixtures/route_activation.json"
    android_activation_rel = "examples/android_shell_host/app/src/main/assets/route_activation.json"
    vectors_rel = "test/fixtures/bridge_contract_vectors.json"

    ios_manifest = Path.join(target, ios_manifest_rel)
    android_manifest = Path.join(target, android_manifest_rel)
    ios_activation = Path.join(target, ios_activation_rel)
    android_activation = Path.join(target, android_activation_rel)
    vectors = Path.join(target, vectors_rel)

    File.mkdir_p!(Path.dirname(ios_manifest))
    File.mkdir_p!(Path.dirname(android_manifest))
    File.mkdir_p!(Path.dirname(ios_activation))
    File.mkdir_p!(Path.dirname(android_activation))
    File.mkdir_p!(Path.dirname(vectors))

    # Seed ios manifest with WRONG version (nested under "compatibility")
    File.write!(ios_manifest, Jason.encode!(%{
      "compatibility" => %{"bridge_protocol_version" => "0.9.0"}
    }))

    # Seed the remaining four surfaces with the CORRECT version so only the
    # iOS manifest drifts — proving the check names the exact drifted surface.
    File.write!(android_manifest, Jason.encode!(%{
      "compatibility" => %{"bridge_protocol_version" => expected}
    }))

    # Generated JSONs carry bridge_protocol_version at the document root.
    File.write!(ios_activation, Jason.encode!(%{"bridge_protocol_version" => expected}))
    File.write!(android_activation, Jason.encode!(%{"bridge_protocol_version" => expected}))
    File.write!(vectors, Jason.encode!(%{"bridge_protocol_version" => expected}))

    report =
      readiness_report(
        cwd: target,
        changelog_contents: File.read!("../../CHANGELOG.md")
      )

    check = find_check!(report, :contract_version_parity)

    assert check.blocking, "contract_version_parity must block on drift"
    assert check.result == :fail
    assert check.severity == :error
    assert check.proof_class == :merge_blocking
    assert check.details.version == expected

    assert Enum.any?(check.details.errors, &String.contains?(&1, ios_manifest_rel)),
           "errors must name the drifted iOS manifest; got: #{inspect(check.details.errors)}"
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
        changelog_contents: File.read!("../../CHANGELOG.md")
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

  test "compatibility_rebuild_guidance check is present and advisory in baseline (no drift)" do
    report = readiness_report()

    check = find_check!(report, :compatibility_rebuild_guidance)

    assert check.severity == :advisory,
           "compatibility_rebuild_guidance must be :advisory at baseline, got: #{inspect(check.severity)}"

    assert check.result == :pass,
           "compatibility_rebuild_guidance must :pass at baseline, got: #{inspect(check.result)}"

    refute check.blocking,
           "compatibility_rebuild_guidance must never be blocking"

    assert check.docs_reference == "guides/compatibility.md"
    assert check.proof_class == :advisory
    assert is_map(check.details)
  end

  test "compatibility_rebuild_guidance check is never :error, never blocking" do
    # Test both baseline (no drift) and a fabricated drift scenario
    report_baseline = readiness_report()
    check_baseline = find_check!(report_baseline, :compatibility_rebuild_guidance)

    refute check_baseline.severity == :error,
           "compatibility_rebuild_guidance must never emit :error (baseline)"

    refute check_baseline.blocking,
           "compatibility_rebuild_guidance must never be blocking (baseline)"

    # Fabricate drift by using a temp dir with wrong bridge_protocol_version
    target = tmp_dir!("crosswake-compat-guidance-drift")
    expected = Crosswake.Bridge.Contract.version()

    ios_manifest_rel = "examples/ios_shell_host/Fixtures/crosswake_manifest.json"
    android_manifest_rel = "examples/android_shell_host/app/src/main/assets/crosswake_manifest.json"
    ios_activation_rel = "examples/ios_shell_host/Fixtures/route_activation.json"
    android_activation_rel = "examples/android_shell_host/app/src/main/assets/route_activation.json"
    vectors_rel = "test/fixtures/bridge_contract_vectors.json"

    for rel <- [ios_manifest_rel, android_manifest_rel] do
      File.mkdir_p!(Path.dirname(Path.join(target, rel)))
      File.write!(Path.join(target, rel), Jason.encode!(%{"compatibility" => %{"bridge_protocol_version" => "0.9.0"}}))
    end

    for rel <- [ios_activation_rel, android_activation_rel, vectors_rel] do
      File.mkdir_p!(Path.dirname(Path.join(target, rel)))
      File.write!(Path.join(target, rel), Jason.encode!(%{"bridge_protocol_version" => expected}))
    end

    report_drift =
      readiness_report(
        cwd: target,
        changelog_contents: File.read!("../../CHANGELOG.md")
      )

    check_drift = find_check!(report_drift, :compatibility_rebuild_guidance)

    refute check_drift.severity == :error,
           "compatibility_rebuild_guidance must never emit :error (drift case)"

    refute check_drift.blocking,
           "compatibility_rebuild_guidance must never be blocking (drift case)"
  end

  test "compatibility_rebuild_guidance elevates to :warning on detected committed-surface drift" do
    target = tmp_dir!("crosswake-compat-guidance-warn")
    expected = Crosswake.Bridge.Contract.version()

    ios_manifest_rel = "examples/ios_shell_host/Fixtures/crosswake_manifest.json"
    android_manifest_rel = "examples/android_shell_host/app/src/main/assets/crosswake_manifest.json"
    ios_activation_rel = "examples/ios_shell_host/Fixtures/route_activation.json"
    android_activation_rel = "examples/android_shell_host/app/src/main/assets/route_activation.json"
    vectors_rel = "test/fixtures/bridge_contract_vectors.json"

    # All manifests carry wrong version — simulates committed-surface drift
    for rel <- [ios_manifest_rel, android_manifest_rel] do
      File.mkdir_p!(Path.dirname(Path.join(target, rel)))
      File.write!(Path.join(target, rel), Jason.encode!(%{"compatibility" => %{"bridge_protocol_version" => "0.9.0"}}))
    end

    for rel <- [ios_activation_rel, android_activation_rel, vectors_rel] do
      File.mkdir_p!(Path.dirname(Path.join(target, rel)))
      File.write!(Path.join(target, rel), Jason.encode!(%{"bridge_protocol_version" => expected}))
    end

    report =
      readiness_report(
        cwd: target,
        changelog_contents: File.read!("../../CHANGELOG.md")
      )

    check = find_check!(report, :compatibility_rebuild_guidance)

    assert check.severity == :warning,
           "compatibility_rebuild_guidance must be :warning on detected drift, got: #{inspect(check.severity)}"

    assert check.result == :fail,
           "compatibility_rebuild_guidance must :fail on detected drift, got: #{inspect(check.result)}"

    refute check.blocking,
           "compatibility_rebuild_guidance must never be blocking even on drift"

    # Verify it names the detected class
    assert check.message =~ "native or companion rebuild required",
           "drift message must name the detected class"
  end

  test "compatibility_rebuild_guidance details contain active_action_sequence, change_class_guidance, docs_reference" do
    report = readiness_report()
    check = find_check!(report, :compatibility_rebuild_guidance)

    assert is_list(check.details.active_action_sequence),
           "active_action_sequence must be a list"

    assert length(check.details.active_action_sequence) > 0,
           "active_action_sequence must be non-empty"

    assert is_map(check.details.change_class_guidance),
           "change_class_guidance must be a map"

    assert check.details.docs_reference == "guides/compatibility.md",
           "docs_reference in details must be guides/compatibility.md"
  end

  test "compatibility_rebuild_guidance native-rebuild action sequence is exactly 4 ordered steps" do
    report = readiness_report()
    check = find_check!(report, :compatibility_rebuild_guidance)

    # The baseline also uses native-rebuild sequence for active_action_sequence
    sequence = check.details.active_action_sequence

    assert length(sequence) == 4,
           "native-rebuild sequence must have exactly 4 steps, got: #{inspect(sequence)}"

    assert Enum.at(sequence, 0) =~ "Regenerate shell",
           "Step 1 must be regenerate shell, got: #{inspect(Enum.at(sequence, 0))}"

    assert Enum.at(sequence, 1) =~ "Rebuild native app",
           "Step 2 must be rebuild native app, got: #{inspect(Enum.at(sequence, 1))}"

    assert Enum.at(sequence, 2) =~ ~r/App Store|Play Store/,
           "Step 3 must mention App Store / Play Store, got: #{inspect(Enum.at(sequence, 2))}"

    assert Enum.at(sequence, 3) =~ "deploy",
           "Step 4 must be coordinated deploy, got: #{inspect(Enum.at(sequence, 3))}"
  end

  test "compatibility_rebuild_guidance denial vocabulary is present in advisory" do
    report = readiness_report()
    check = find_check!(report, :compatibility_rebuild_guidance)

    denial_vocab = check.details.denial_vocabulary
    assert is_list(denial_vocab), "denial_vocabulary must be a list"
    assert "compatibility_mismatch" in denial_vocab, "must include compatibility_mismatch"
    assert "inactive_route" in denial_vocab, "must include inactive_route"
    assert "undeclared_capability" in denial_vocab, "must include undeclared_capability"
    assert "pack_incompatible" in denial_vocab, "must include pack_incompatible"
  end

  test "compatibility_rebuild_guidance message and hint contain microcopy disclaimer and mix command" do
    report = readiness_report()
    check = find_check!(report, :compatibility_rebuild_guidance)

    # Microcopy: must state it is guidance, not a detected failure
    assert check.message =~ "cannot observe",
           "message must contain disclaimer about not observing live denial"

    assert check.message =~ "guidance",
           "message must contain word 'guidance'"

    # Must include the literal command
    assert check.message =~ "mix crosswake.contract.gen",
           "message must include the literal next command"

    # Must include numbered steps
    assert check.message =~ "1)",
           "message must include numbered step 1)"

    # Hint also carries the disclaimer
    assert check.hint =~ "cannot observe",
           "hint must contain disclaimer"

    assert check.hint =~ "guidance",
           "hint must contain word 'guidance'"
  end

  test "compatibility_rebuild_guidance check guide link is present in details" do
    report = readiness_report()
    check = find_check!(report, :compatibility_rebuild_guidance)

    assert check.details.docs_reference == "guides/compatibility.md",
           "docs_reference in details must link to guides/compatibility.md"

    assert check.docs_reference == "guides/compatibility.md",
           "top-level docs_reference must be guides/compatibility.md"
  end

  defp readiness_report(opts \\ []) do
    PublishReadiness.run(
      Keyword.merge(
        [
          route_source: ReadinessRouter,
          generated_at: "2026-05-31T00:00:00Z",
          # D-137-03: cwd must point to the repo root (not the package dir) so
          # PublishReadiness.run/1 can find CHANGELOG.md, guides/, priv/, examples/.
          cwd: Path.expand("../../", File.cwd!())
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
