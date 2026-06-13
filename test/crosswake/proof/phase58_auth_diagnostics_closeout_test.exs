defmodule Crosswake.Proof.Phase58AuthDiagnosticsCloseoutTest do
  use ExUnit.Case, async: false

  alias Crosswake.Companions.Sigra.DenialCodes
  alias Crosswake.Companions.Sigra.Telemetry
  alias Crosswake.Doctor
  alias Crosswake.OperatorInspection
  alias Crosswake.SupportMatrix

  defmodule PageController do
    def init(opts), do: opts
    def call(conn, _opts), do: conn
  end

  defmodule AuthRouter do
    use Crosswake.Router

    pipeline :browser do
      plug(:accepts, ["html"])
    end

    scope "/" do
      pipe_through(:browser)

      get(
        "/secure",
        Elixir.Crosswake.Proof.Phase58AuthDiagnosticsCloseoutTest.PageController,
        :secure,
        crosswake: [
          id: "secure",
          runtime: :live_view,
          security: :sensitive,
          auth_min_level: :mfa,
          requires_recent_auth: 600
        ]
      )
    end
  end

  test "phase 58 locks stable auth telemetry names metadata and secret exclusions" do
    assert Telemetry.event_names() == [
             [:crosswake, :auth, :session, :evaluate, :start],
             [:crosswake, :auth, :session, :evaluate, :stop],
             [:crosswake, :auth, :session, :evaluate, :exception],
             [:crosswake, :auth, :denial],
             [:crosswake, :auth, :handoff, :issue],
             [:crosswake, :auth, :handoff, :redeem],
             [:crosswake, :auth, :handoff, :deny],
             [:crosswake, :auth, :step_up, :issue],
             [:crosswake, :auth, :step_up, :challenge],
             [:crosswake, :auth, :step_up, :consume],
             [:crosswake, :auth, :step_up, :deny],
             [:crosswake, :auth, :return, :validate],
             [:crosswake, :auth, :return, :consume],
             [:crosswake, :auth, :return, :deny]
           ]

    assert :denial_code in Telemetry.metadata_keys()
    assert :access_token in Telemetry.forbidden_metadata_keys()
    assert :provider_payload in Telemetry.forbidden_metadata_keys()
    assert :raw_return_to in Telemetry.forbidden_metadata_keys()
    refute :access_token in Telemetry.metadata_keys()
    refute :session_ref in Telemetry.metadata_keys()
  end

  test "support truth distinguishes shipped Sigra contracts host readiness and advisory provider proof" do
    assert [%{} = row] = SupportMatrix.auth_contract_truth()

    assert row.contract_surface == :full_sigra_machinery
    assert row.contract_proof_class == :merge_blocking
    assert row.route_authority_source == :session_authority_lane
    assert row.host_readiness == :verification_required
    assert row.provider_device_proof == :advisory
    assert row.telemetry.status == :shipped
    assert row.telemetry.event_names == Telemetry.event_names()
    assert row.telemetry.metadata_keys == Telemetry.metadata_keys()
    assert row.telemetry.forbidden_metadata_keys == Telemetry.forbidden_metadata_keys()
    assert row.security_closeout.status == :shipped
    assert row.security_closeout.review_model == :stride
    assert row.security_closeout.unresolved_high_or_critical_findings == 0

    for {_surface, authority?} <- row.evidence_authority do
      assert authority? == false
    end

    assert :refresh_tokens in row.deferred
    assert :provider_device_proof in row.deferred
    assert :native_auth_ui in row.deferred
    refute :telemetry_security_closeout in row.deferred
  end

  test "doctor and operator inspection expose Phase 58 auth closeout truth" do
    report =
      Doctor.run(
        route_source: AuthRouter,
        install_manifest_path: "priv/crosswake/install_manifest.json",
        cwd: File.cwd!()
      )

    finding = Enum.find(report.findings, &(&1.code == "auth.step_up_required_contract"))
    assert finding.message =~ "stable Phase 58 auth telemetry"
    assert finding.message =~ "Phase 58 security closeout"
    assert finding.details.telemetry.status == :shipped
    assert finding.details.security_closeout.status == :shipped
    assert finding.details.provider_device_proof == :advisory

    document =
      OperatorInspection.inspect(
        route_source: AuthRouter,
        generated_at: "2026-06-02T00:00:00Z"
      )

    secure = document.routes["secure"]
    assert secure.auth.contract_surface == :full_sigra_machinery
    assert secure.auth.contract_proof_class == :merge_blocking
    assert secure.auth.telemetry.event_names == Telemetry.event_names()
    assert secure.auth.security_closeout.status == :shipped

    auth_condition = Enum.find(secure.conditions, &(&1.type == :auth_contract))
    assert auth_condition.message =~ "host verification required"
    refute auth_condition.message =~ "contract-only"
  end

  test "guides and security closeout preserve provider device non-claims and secret bans" do
    companions = File.read!("guides/companions.md")
    support = File.read!("guides/support_matrix.md")

    security =
      File.read!(
        ".planning/milestones/v3.8-phases/58-auth-diagnostics-proof-and-security-closeout/58-SECURITY.md"
      )

    assert companions =~ "Crosswake.Companions.Sigra.Telemetry"
    assert companions =~ "low-cardinality telemetry metadata"
    assert companions =~ "Phase 58 stable auth telemetry plus STRIDE-style security closeout"
    refute companions =~ "Phase 58 telemetry/security closeout, direct shell"

    assert support =~ "Phase 58 auth telemetry/security closeout"
    assert support =~ "Phase 73 auth-sensitive admin workflow proof"
    assert support =~ "provider/device proof"
    assert support =~ "direct shell/WebView token authority"

    for section <- [
          "## Token And Locator Handling",
          "## Handoff Tickets",
          "## Step-Up Ceremony",
          "## Auth Return Boundaries",
          "## Telemetry And Diagnostics",
          "## Denial Sanitization",
          "## Session Renewal And LiveView Invalidation",
          "## Doctor Support Operator And Docs Truth",
          "## Proof And Non-Claims",
          "## Findings Disposition"
        ] do
      assert security =~ section
    end

    for key <- ["access_token", "refresh_token", "passkey_credential_id", "pkce_verifier"] do
      refute key in DenialCodes.allowed_detail_keys()
    end
  end
end
