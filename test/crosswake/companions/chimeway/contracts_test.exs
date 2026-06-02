defmodule Crosswake.Companions.Chimeway.ContractsTest do
  use ExUnit.Case, async: true

  alias Crosswake.Companions.Chimeway.Contracts
  alias Crosswake.Companions.Chimeway.Contracts.BindingEvent
  alias Crosswake.Companions.Chimeway.Contracts.BindingResult
  alias Crosswake.Companions.Chimeway.Contracts.ProviderFeedback
  alias Crosswake.Companions.Chimeway.Contracts.TokenBinding
  alias Crosswake.Companions.Chimeway.Contracts.TokenEvidence

  @observed_at "2026-06-02T18:00:00Z"

  test "exports exact closed vocabularies" do
    assert Contracts.providers() == [:apns, :fcm]
    assert Contracts.platforms() == [:ios, :android]
    assert Contracts.environments() == [:sandbox, :production, :development, :unknown]
    assert Contracts.notification_statuses() == [:granted, :denied, :restricted]
    assert Contracts.binding_states() == [:active, :superseded, :revoked, :stale, :invalid]

    assert Contracts.binding_reasons() == [
             :initial_bind,
             :token_rotated,
             :logout_revoked,
             :session_revoked,
             :permission_denied,
             :provider_unregistered,
             :provider_invalid_token,
             :environment_mismatch,
             :app_identity_mismatch,
             :staleness_pruned,
             :manual_revocation
           ]

    assert Contracts.provider_feedback_events() == [
             :token_unregistered,
             :token_invalid,
             :environment_mismatch,
             :app_identity_mismatch,
             :credentials_invalid,
             :provider_throttled,
             :provider_unavailable,
             :delivery_accepted,
             :delivery_failed
           ]

    assert Contracts.app_identity_postures() == [:matched, :mismatched, :unknown]

    assert Contracts.binding_event_types() == [
             :observed,
             :bound,
             :rotated,
             :revoked,
             :stale,
             :invalidated,
             :feedback
           ]

    assert Contracts.binding_result_statuses() == [
             :bound,
             :rotated,
             :revoked,
             :stale,
             :invalidated,
             :rejected
           ]
  end

  test "builds token evidence without public raw token fields" do
    assert {:ok, %TokenEvidence{} = evidence} =
             Contracts.new_token_evidence(%{
               provider: :apns,
               platform: :ios,
               environment: :sandbox,
               installation_ref: "install_123",
               token_ref: "tokref_123",
               token_fingerprint: "hmac-sha256:abc",
               notification_status: :granted,
               observed_at: @observed_at,
               app_identity_posture: :matched,
               metadata: %{safe: :yes}
             })

    refute Map.has_key?(Map.from_struct(evidence), :token)
    assert evidence.token_ref == "tokref_123"
  end

  test "builds backend-owned token binding with lifecycle state and reason" do
    assert {:ok, %TokenBinding{} = binding} =
             Contracts.new_token_binding(%{
               binding_ref: "bind_123",
               installation_ref: "install_123",
               provider: :fcm,
               platform: :android,
               environment: :production,
               token_ref: "tokref_123",
               token_fingerprint: "hmac-sha256:def",
               state: :superseded,
               reason: :token_rotated,
               bound_at: @observed_at,
               last_seen_at: @observed_at,
               subject_scope: :user,
               session_version: 3
             })

    assert binding.state == :superseded
    assert binding.reason == :token_rotated
    refute Map.has_key?(Map.from_struct(binding), :token)
  end

  test "builds provider feedback event as evidence separate from binding authority" do
    assert {:ok, %ProviderFeedback{} = feedback} =
             Contracts.new_provider_feedback(%{
               provider: :apns,
               platform: :ios,
               environment: :production,
               feedback_event: :delivery_accepted,
               occurred_at: @observed_at,
               token_ref: "tokref_123"
             })

    assert feedback.feedback_event == :delivery_accepted
    assert Contracts.provider_handoff_event() == :delivery_accepted
  end

  test "builds binding event and binding result contracts" do
    assert {:ok, %BindingEvent{} = event} =
             Contracts.new_binding_event(%{
               event_ref: "evt_123",
               event_type: :feedback,
               occurred_at: @observed_at,
               state_before: :active,
               state_after: :invalid,
               reason: :provider_invalid_token,
               feedback_event: :token_invalid,
               proof_class: :hermetic
             })

    assert event.event_type == :feedback

    assert {:ok, %BindingResult{} = result} =
             Contracts.new_binding_result(%{
               status: :invalidated,
               binding_ref: "bind_123",
               state: :invalid,
               reason: :provider_invalid_token
             })

    assert result.status == :invalidated
  end

  test "rejects public raw token aliases in constructor attrs" do
    base = token_evidence_attrs()

    for forbidden_key <- Contracts.forbidden_public_token_keys() do
      assert {:error, [{^forbidden_key, :raw_token_field_forbidden}]} =
               Contracts.new_token_evidence(Map.put(base, forbidden_key, "raw-secret"))
    end
  end

  test "TOKN-02 lifecycle semantics are explicit state plus reason mappings" do
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

  test "to_map stringifies atom keys and values and omits nils for all contract structs" do
    structs = [
      Contracts.new_token_evidence!(token_evidence_attrs()),
      Contracts.new_token_binding!(token_binding_attrs()),
      Contracts.new_provider_feedback!(provider_feedback_attrs()),
      Contracts.new_binding_event!(binding_event_attrs()),
      Contracts.new_binding_result!(binding_result_attrs())
    ]

    for struct <- structs do
      map = Contracts.to_map(struct)
      assert Enum.all?(Map.keys(map), &is_binary/1)
      refute Enum.any?(map, fn {_key, value} -> is_nil(value) end)
    end

    assert Contracts.to_map(Contracts.new_token_binding!(token_binding_attrs()))["state"] ==
             "active"
  end

  defp token_evidence_attrs do
    %{
      provider: :apns,
      platform: :ios,
      environment: :sandbox,
      installation_ref: "install_123",
      token_ref: "tokref_123",
      token_fingerprint: "hmac-sha256:abc",
      notification_status: :granted,
      observed_at: @observed_at
    }
  end

  defp token_binding_attrs do
    %{
      binding_ref: "bind_123",
      installation_ref: "install_123",
      provider: :apns,
      platform: :ios,
      environment: :sandbox,
      token_ref: "tokref_123",
      token_fingerprint: "hmac-sha256:abc",
      state: :active,
      reason: :initial_bind,
      bound_at: @observed_at,
      last_seen_at: @observed_at
    }
  end

  defp provider_feedback_attrs do
    %{
      provider: :apns,
      platform: :ios,
      environment: :sandbox,
      feedback_event: :delivery_accepted,
      occurred_at: @observed_at
    }
  end

  defp binding_event_attrs do
    %{
      event_ref: "evt_123",
      event_type: :observed,
      occurred_at: @observed_at
    }
  end

  defp binding_result_attrs do
    %{
      status: :bound,
      binding_ref: "bind_123"
    }
  end
end
