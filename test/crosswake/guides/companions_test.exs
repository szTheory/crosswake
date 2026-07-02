defmodule Crosswake.Guides.CompanionsTest do
  use ExUnit.Case, async: false

  alias Crosswake.Doctor
  alias Crosswake.SupportMatrix
  alias Crosswake.TestSupport.StubRindleAbsentCompanion
  alias Crosswake.TestSupport.StubRulesteadAbsentCompanion

  @guide_path Path.join([File.cwd!(), "guides", "companions.md"])

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

  setup_all do
    content = File.read!(@guide_path)
    %{content: content}
  end

  test "includes required anchor vocabulary", %{content: content} do
    assert content =~ "Crosswake.Companion"
    assert content =~ "companion_id/0"
    assert content =~ "enabled?/1"
    assert content =~ "route_gated?/2"
    assert content =~ "kill_switch_active?/1"
    assert content =~ "validate_dependency/0"
    assert content =~ "report_state/0"
    assert content =~ "lib/crosswake/companions/<name>/"
    assert content =~ "[:crosswake, :companion, :validate_dependency]"
    assert content =~ "fail-closed"
    assert content =~ "gated_by"
    assert content =~ "on_unavailable"
    assert content =~ "MockFlagSource"
    assert content =~ "set_flag/2"
    assert content =~ ":gate_denied"
    assert content =~ ":kill_switch_active"
    assert content =~ "AuthContext"
    assert content =~ "SessionAuthorityLane"
    assert content =~ "Crosswake.Companions.Sigra.Handoff"
    assert content =~ "Crosswake.Companions.Sigra.StepUp"
    assert content =~ "Crosswake.Companions.Sigra.Telemetry"
    assert content =~ "Crosswake.Companions.Sigra.StepUpCeremony.evaluate_or_issue/3"
    assert content =~ "Crosswake.Companions.Chimeway"
    assert content =~ "TokenEvidence"
    assert content =~ "TokenBinding"
    assert content =~ "ProviderFeedback"
    assert content =~ "BindingEvent"
    assert content =~ "BindingResult"
    assert content =~ "token_ref"
    assert content =~ "token_fingerprint"
    assert content =~ "auth_min_level"
    assert content =~ "requires_recent_auth"
    assert content =~ "auth_posture"
    assert content =~ ":strict_recent"
    assert content =~ ":remembered_ok"
    assert content =~ ":cached_read_only_ok"
    assert content =~ ":step_up_required"
    assert content =~ "auth.step_up.missing_context"
    assert content =~ "auth.step_up.cached_not_allowed"
    assert content =~ "auth.handoff.invalid_ticket"
    assert content =~ "auth.step_up_intent.invalid_intent"
    assert content =~ "server-side ticket record"
    assert content =~ "companion.dependency_missing"
    assert content =~ "auth.route_predicated"
    assert content =~ "auth.step_up_required_contract"
    assert content =~ "diag.auth.sigra_session_authority"
    assert content =~ "low-cardinality telemetry metadata"
  end

  test "includes explicit deferred non-goals", %{content: content} do
    assert content =~ "Chimeway"
    assert content =~ "Later Sigra machinery"

    assert content =~
             "Phase 58 ships telemetry/security closeout for provider-neutral Sigra contracts"

    assert content =~ "provider/device auth proof"
    assert content =~ "Threadline"
    assert content =~ "Separate-package extraction"
  end

  test "Chimeway anchor locks token evidence and backend binding non-claims", %{content: content} do
    assert content =~ "`notifications.token.get` and provider feedback are evidence only"
    assert content =~ "Backend-owned binding records remain authoritative"
    assert content =~ "token_ref"
    assert content =~ "token_fingerprint"

    # Notification-open routing and RouteGate activation are now shipped Chimeway
    # surfaces (resolved through RouteGate + Sigra), so they are no longer
    # non-claims. The remaining provider/delivery facts stay outside the proof.
    for non_claim <- [
          "APNs/FCM delivery",
          "provider credentials",
          "push metrics",
          "read receipts",
          "tray behavior"
        ] do
      assert content =~ non_claim
    end

    refute content =~ "public `token` field"
  end

  test "live code guard — contract and support modules export expected functions" do
    # Phase 130: Crosswake.Companions.Rulestead extracted to packages/crosswake_rulestead/.
    # Phase 132: Crosswake.Companions.Rindle extracted to packages/crosswake_rindle/.
    # Phase 137: Crosswake.Companions.Sigra extracted to packages/crosswake_sigra/.
    # Their API guards now live in each companion's own test lane (phase42 / phase45 / phase46+
    # in packages/crosswake_*/test/). Core only guards the seam + remaining in-tree companions.
    Code.ensure_loaded!(Crosswake.Companion)
    Code.ensure_loaded!(Crosswake.Companion.State)
    Code.ensure_loaded!(Crosswake.Companions.Chimeway)
    Code.ensure_loaded!(Crosswake.Companions.Chimeway.Contracts)
    Code.ensure_loaded!(Crosswake.SupportMatrix)
    Code.ensure_loaded!(Crosswake.Shell.Denial)

    # Sigra API guards live in packages/crosswake_sigra/test/ (phase46, phase58, etc.)
    # after Phase 137 extraction — not checked here to avoid requiring the companion package
    # in core's test compilation path.
    assert function_exported?(Crosswake.Companions.Chimeway, :report_state, 0)
    assert function_exported?(Crosswake.Companions.Chimeway.Contracts, :new_token_evidence, 1)
    assert function_exported?(Crosswake.SupportMatrix, :gating_truth, 0)
    assert function_exported?(Crosswake.SupportMatrix, :auth_contract_truth, 0)
    assert function_exported?(Crosswake.Shell.Denial, :reasons, 0)
  end

  test "documented companion ids stay parity-locked with runtime gating truth", %{
    content: content
  } do
    original_companions = Application.get_env(:crosswake, :companions)

    # Phase 130: Crosswake.Companions.Rulestead extracted to companion package.
    # Use StubRulesteadAbsentCompanion (companion_id: :rulestead, validate_dependency: {:error, _})
    # to drive gating_truth iteration without the extracted module in core's compile path.
    Application.put_env(:crosswake, :companions, [
      StubRulesteadAbsentCompanion,
      StubRindleAbsentCompanion
    ])

    on_exit(fn ->
      if is_nil(original_companions) do
        Application.delete_env(:crosswake, :companions)
      else
        Application.put_env(:crosswake, :companions, original_companions)
      end
    end)

    runtime_ids =
      SupportMatrix.gating_truth()
      |> Enum.map(&Atom.to_string(&1.companion_id))
      |> Enum.sort()

    documented_ids =
      ~r/Companion id:\s+`:([a-z_]+)`/
      |> Regex.scan(content)
      |> Enum.map(fn [_, companion_id] -> companion_id end)
      |> Enum.sort()

    assert documented_ids == runtime_ids

    assert content =~
             "It intentionally has no runtime `Companion id:` marker yet because it is not a `Crosswake.Companion` optional dependency surface."
  end

  test "auth predicates and denial vocabulary stay parity-locked to support and shell truth", %{
    content: content
  } do
    rows = SupportMatrix.auth_contract_truth()

    assert [_ | _] = rows

    for %{route_predicates: predicates, denial_vocabulary: denial, denial_codes: codes} <- rows do
      for predicate <- predicates do
        assert content =~ Atom.to_string(predicate),
               "guide missing auth predicate #{inspect(predicate)} from SupportMatrix.auth_contract_truth/0"
      end

      assert %{
               handoff: %{authority_source: :server_record},
               step_up: %{status: :shipped},
               telemetry: %{status: :shipped},
               security_closeout: %{status: :shipped},
               deferred: deferred
             } =
               Enum.find(rows, &(:handoff_ticket in &1.shipped_contracts))

      refute :handoff in deferred
      refute :ceremony in deferred
      refute :auth_return_boundaries in deferred

      assert content =~ Atom.to_string(denial),
             "guide missing auth denial vocabulary #{inspect(denial)} from SupportMatrix.auth_contract_truth/0"

      for code <- codes do
        assert content =~ code, "guide missing auth denial code #{code}"
      end
    end

    denial_reasons = Crosswake.Shell.Denial.reasons()

    assert :gate_denied in denial_reasons
    assert :kill_switch_active in denial_reasons
    assert :step_up_required in denial_reasons
  end

  test "doctor finding codes are asserted from live Doctor.run/1 output", %{content: content} do
    original_companions = Application.get_env(:crosswake, :companions)
    original_rulestead = Application.get_env(:crosswake, :rulestead)
    original_rindle = Application.get_env(:crosswake, :rindle)

    # Phase 130/132: Crosswake.Companions.Rulestead + .Rindle extracted to companion packages.
    # Use StubRulesteadAbsentCompanion + StubRindleAbsentCompanion to drive the
    # companion.dependency_missing finding without aliasing the extracted adapters.
    Application.put_env(:crosswake, :companions, [
      StubRulesteadAbsentCompanion,
      StubRindleAbsentCompanion
    ])

    Application.put_env(:crosswake, :rulestead, %{enabled: true})
    Application.put_env(:crosswake, :rindle, %{enabled: true})

    on_exit(fn ->
      restore_env(:companions, original_companions)
      restore_env(:rulestead, original_rulestead)
      restore_env(:rindle, original_rindle)
    end)

    report =
      Doctor.run(
        route_source: AuthPredicatedRouter,
        install_manifest_path: "priv/crosswake/install_manifest.json",
        cwd: File.cwd!()
      )

    codes = report.findings |> Enum.map(& &1.code)

    assert "companion.dependency_missing" in codes
    assert "auth.route_predicated" in codes
    assert "auth.step_up_required_contract" in codes

    assert content =~ "companion.dependency_missing"
    assert content =~ "auth.route_predicated"
    assert content =~ "auth.step_up_required_contract"
    assert content =~ "diag.auth.sigra_session_authority"
  end

  defp restore_env(key, nil), do: Application.delete_env(:crosswake, key)
  defp restore_env(key, value), do: Application.put_env(:crosswake, key, value)
end
