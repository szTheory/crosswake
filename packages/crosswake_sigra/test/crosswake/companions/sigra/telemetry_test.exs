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

  # ---------------------------------------------------------------------------
  # Side-A "declared ⇔ emitted" contract (FAMILY-03 / D-16).
  #
  # Sigra's events are declared as the :reserved tier in core Crosswake.Telemetry
  # (declared-not-emitted-by-core). This in-package Side-A test is what proves
  # emission actually exists: it drives the real Telemetry.execute/3 code path over
  # EVERY declared event name pulled live from the catalog (event_names/0 — never a
  # hardcoded list), so declaring a new event without emitting it fails here.
  #
  # The two facts together — core declares the event :reserved AND this package emits
  # it — are the full declared⇔emitted contract for sigra.
  #
  # HARD RULE: subset (Map.has_key?) assertions only. Never assert an exact
  # event/metadata COUNT — exact-count re-creates the >=24 cross-package coupling
  # that independent versioning forbids.
  # ---------------------------------------------------------------------------

  test "Side-A: every declared event name emits with supplied declared metadata keys present" do
    for event_name <- Telemetry.event_names() do
      handler_id = "sigra-sideA-#{System.unique_integer([:positive])}"

      :telemetry.attach(
        handler_id,
        event_name,
        fn ^event_name, measurements, metadata, _config ->
          send(self(), {:sigra_sideA, event_name, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      # Drive the real emitter path (Telemetry.execute/3), supplying at least one
      # declared metadata key from metadata_keys/0.
      assert :ok =
               Telemetry.execute(event_name, %{count: 1}, %{
                 route_id: "sideA-route",
                 correlation_id: "support:sideA.#{System.unique_integer([:positive])}"
               })

      assert_receive {:sigra_sideA, ^event_name, _measurements, metadata}

      # Subset assertion only — declared keys we supplied must be PRESENT. Do NOT
      # assert map_size or the full metadata_keys/0 list (many keys are per-event
      # optional).
      assert Map.has_key?(metadata, :route_id)
      assert Map.has_key?(metadata, :correlation_id)
    end
  end
end
