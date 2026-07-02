defmodule Crosswake.Companions.Sigra.TelemetryTest do
  use ExUnit.Case, async: true

  alias Crosswake.Companions.Sigra.Telemetry

  test "auth telemetry exposes stable event names and low-cardinality metadata keys" do
    assert [:crosswake, :auth, :session, :evaluate, :start] in Telemetry.event_names()
    assert [:crosswake, :auth, :denial] in Telemetry.event_names()
    assert [:crosswake, :auth, :handoff, :redeem] in Telemetry.event_names()
    assert [:crosswake, :auth, :step_up, :consume] in Telemetry.event_names()
    assert [:crosswake, :auth, :return, :validate] in Telemetry.event_names()

    assert :denial_code in Telemetry.metadata_keys()
    assert :shell_reason in Telemetry.metadata_keys()
    assert :return_kind in Telemetry.metadata_keys()
    assert :proof_class in Telemetry.metadata_keys()
    assert :correlation_id in Telemetry.metadata_keys()
  end

  test "auth telemetry metadata drops secrets identity fields and unknown high-cardinality data" do
    metadata =
      Telemetry.metadata(%{
        route_id: "billing-settings",
        flow: :auth_return,
        return_kind: :oauth,
        outcome: :deny,
        denial_code: "auth.return.oauth.state_mismatch",
        shell_reason: :step_up_required,
        correlation_id: "support:ret.safe",
        access_token: "secret",
        authorization_code: "secret",
        passkey_credential_id: "secret",
        session_ref: "sess_secret",
        actor_id: "actor_secret",
        provider_payload: "raw",
        user_agent: "raw",
        unbounded_detail: "do not include"
      })

    assert metadata == %{
             route_id: "billing-settings",
             flow: :auth_return,
             return_kind: :oauth,
             outcome: :deny,
             denial_code: "auth.return.oauth.state_mismatch",
             shell_reason: :step_up_required,
             correlation_id: "support:ret.safe"
           }
  end

  test "auth telemetry event maps serialize without nils or forbidden fields" do
    event =
      Telemetry.new_event(
        name: [:crosswake, :auth, :denial],
        route_id: "admin",
        flow: :session,
        outcome: :deny,
        denial_code: "auth.step_up.stale_auth",
        shell_reason: :step_up_required,
        proof_class: :hermetic
      )

    assert Telemetry.to_map(event) == %{
             "name" => "crosswake.auth.denial",
             "route_id" => "admin",
             "flow" => :session,
             "outcome" => :deny,
             "denial_code" => "auth.step_up.stale_auth",
             "shell_reason" => :step_up_required,
             "proof_class" => :hermetic
           }
  end
end
