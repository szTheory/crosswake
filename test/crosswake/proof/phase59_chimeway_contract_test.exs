defmodule Crosswake.Proof.Phase59ChimewayContractTest do
  use ExUnit.Case, async: true

  alias Crosswake.Bridge.Commands.NotificationToken
  alias Crosswake.Companions.Chimeway
  alias Crosswake.Companions.Chimeway.Contracts
  alias Crosswake.Companions.Chimeway.Contracts.BindingEvent
  alias Crosswake.Companions.Chimeway.Contracts.BindingResult
  alias Crosswake.Companions.Chimeway.Contracts.ProviderFeedback
  alias Crosswake.Companions.Chimeway.Contracts.TokenBinding
  alias Crosswake.Companions.Chimeway.Contracts.TokenEvidence
  alias Crosswake.Companions.Chimeway.Redaction
  alias Crosswake.Companions.Chimeway.Telemetry
  alias Crosswake.SupportMatrix

  @raw_token "raw_apns_token_should_not_leak_123"
  @occurred_at "2026-06-02T18:00:00Z"
  @forbidden_token_aliases [
    :token,
    :raw_token,
    :device_token,
    :registration_token,
    :apns_token,
    :fcm_token
  ]

  test "TOKN-02 lifecycle semantics stay explicit for every required case" do
    assert Contracts.lifecycle_mapping().active == %{state: :active, reason: :initial_bind}
    assert Contracts.lifecycle_mapping().rotated == %{state: :superseded, reason: :token_rotated}
    assert Contracts.lifecycle_mapping().revoked == %{state: :revoked, reason: :manual_revocation}
    assert Contracts.lifecycle_mapping().stale == %{state: :stale, reason: :staleness_pruned}

    assert Contracts.lifecycle_mapping().invalid == %{
             state: :invalid,
             reason: :provider_invalid_token
           }

    assert Contracts.lifecycle_mapping().permission_denied == %{
             state: :revoked,
             reason: :permission_denied
           }

    assert Contracts.lifecycle_mapping().environment_mismatched == %{
             state: :invalid,
             reason: :environment_mismatch
           }

    assert Contracts.lifecycle_mapping().app_identity_mismatched == %{
             state: :invalid,
             reason: :app_identity_mismatch
           }
  end

  test "seeded raw token is absent from inspected serialized and telemetry-sanitized output" do
    response =
      NotificationToken.new_response(
        provider: :apns,
        token: @raw_token,
        notification_status: :granted
      )

    assert {:ok, evidence} =
             Redaction.redact_notification_token_response(response,
               token_ref: "tokref_123",
               installation_ref: "install_123",
               platform: :ios,
               environment: :sandbox,
               fingerprint_secret: "secret",
               observed_at: @occurred_at
             )

    telemetry =
      Telemetry.metadata(%{
        provider: :apns,
        token: @raw_token,
        raw_token: @raw_token,
        provider_payload: %{token: @raw_token}
      })

    refute inspect(evidence) =~ @raw_token
    refute inspect(Contracts.to_map(evidence)) =~ @raw_token
    refute inspect(telemetry) =~ @raw_token
  end

  test "companion state and support matrix do not promote delivery or notification-open support" do
    assert %{
             delivery_support: :not_shipped,
             open_routing: :not_shipped,
             mode: :token_binding_contract
           } = Chimeway.report_state().details

    assert [notification_truth] = SupportMatrix.notification_support_truth()
    assert notification_truth.surface == "notification_token provider snapshot"
    assert notification_truth.proof_class == :advisory
    assert notification_truth.delivery_supported == false
    assert :chimeway_delivery in notification_truth.deferred
    assert :notification_open_routing in notification_truth.deferred
  end

  test "public Chimeway structs never define raw token aliases" do
    for module <- [TokenEvidence, TokenBinding, ProviderFeedback, BindingEvent, BindingResult] do
      fields = module.__struct__() |> Map.from_struct() |> Map.keys()

      for alias <- @forbidden_token_aliases do
        refute alias in fields, "#{inspect(module)} unexpectedly exposes #{inspect(alias)}"
      end
    end
  end

  test "delivery_accepted remains provider handoff evidence only" do
    assert {:ok, feedback} =
             Contracts.new_provider_feedback(%{
               provider: :apns,
               platform: :ios,
               environment: :production,
               feedback_event: :delivery_accepted,
               occurred_at: @occurred_at
             })

    map = Contracts.to_map(feedback)
    assert map["feedback_event"] == "delivery_accepted"
    refute Map.has_key?(map, "delivered")
    refute Map.has_key?(map, "opened")
    refute Map.has_key?(map, "route_activated")
  end
end
