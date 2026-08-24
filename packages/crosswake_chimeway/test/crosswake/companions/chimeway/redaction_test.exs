defmodule Crosswake.Companions.Chimeway.RedactionTest do
  use ExUnit.Case, async: true

  alias Crosswake.Bridge.Commands.NotificationToken
  alias Crosswake.Companions.Chimeway.Contracts
  alias Crosswake.Companions.Chimeway.Contracts.ProviderFeedback
  alias Crosswake.Companions.Chimeway.Contracts.TokenEvidence
  alias Crosswake.Companions.Chimeway.Redaction

  @raw_token "raw_apns_token_should_not_leak_123"

  test "fingerprints token with HMAC-SHA256 secret" do
    assert {:ok, "hmac-sha256:" <> digest} =
             Redaction.fingerprint_token(@raw_token, fingerprint_secret: "secret")

    assert byte_size(digest) == 64
    refute digest =~ @raw_token
  end

  test "redacts bridge token response into safe token evidence" do
    response =
      NotificationToken.new_response(
        provider: :apns,
        token: @raw_token,
        notification_status: :granted,
        detail: %{token: @raw_token, safe_detail: :kept}
      )

    assert {:ok, %TokenEvidence{} = evidence} =
             Redaction.redact_notification_token_response(response,
               token_ref: "tokref_123",
               installation_ref: "install_123",
               platform: :ios,
               environment: :sandbox,
               fingerprint_secret: "secret",
               observed_at: "2026-06-02T18:00:00Z"
             )

    assert evidence.provider == :apns
    assert evidence.token_ref == "tokref_123"
    assert evidence.token_fingerprint =~ "hmac-sha256:"
    assert evidence.metadata == %{safe_detail: :kept}

    refute inspect(evidence) =~ @raw_token
    refute inspect(Contracts.to_map(evidence)) =~ @raw_token
    refute Map.has_key?(Map.from_struct(evidence), :token)
  end

  test "requires token ref installation ref platform environment and fingerprint strategy" do
    response =
      NotificationToken.new_response(
        provider: :fcm,
        token: @raw_token,
        notification_status: :denied
      )

    assert {:error, {:token_ref, :required}} =
             Redaction.redact_notification_token_response(response,
               installation_ref: "install_123",
               platform: :android,
               environment: :production,
               fingerprint_secret: "secret"
             )

    assert {:error, :missing_fingerprint_strategy} =
             Redaction.redact_notification_token_response(response,
               token_ref: "tokref_123",
               installation_ref: "install_123",
               platform: :android,
               environment: :production
             )
  end

  test "normalizes exact APNs and FCM provider feedback mappings" do
    assert_feedback(:apns, "BadDeviceToken", :environment_mismatch)
    assert_feedback(:apns, "DeviceTokenNotForTopic", :app_identity_mismatch)
    assert_feedback(:apns, "Unregistered", :token_unregistered)
    assert_feedback(:fcm, "UNREGISTERED", :token_unregistered)
    assert_feedback(:fcm, "INVALID_ARGUMENT", :token_invalid)
    assert_feedback(:fcm, "SENDER_ID_MISMATCH", :app_identity_mismatch)
    assert_feedback(:fcm, "UNAVAILABLE", :provider_unavailable)
    assert_feedback(:fcm, "QUOTA_EXCEEDED", :provider_throttled)
  end

  test "keeps delivery accepted as provider handoff evidence only" do
    assert {:ok, %ProviderFeedback{} = feedback} =
             Redaction.feedback_from_provider_attrs(%{
               provider: :apns,
               platform: :ios,
               environment: :production,
               reason: :delivery_accepted,
               occurred_at: "2026-06-02T18:00:00Z"
             })

    assert feedback.feedback_event == :delivery_accepted
    refute Map.has_key?(Contracts.to_map(feedback), "delivered")
    refute Map.has_key?(Contracts.to_map(feedback), "opened")
    refute Map.has_key?(Contracts.to_map(feedback), "route_activated")
  end

  test "redaction errors and returned contracts never include seeded raw token" do
    assert {:error, error} = Redaction.fingerprint_token(@raw_token, [])

    refute inspect(error) =~ @raw_token
  end

  test "recursively drops forbidden nested metadata from provider evidence" do
    raw_token = "raw_token_must_never_escape"
    provider_body = "provider_body_must_never_escape"

    assert {:ok, %ProviderFeedback{} = feedback} =
             Redaction.feedback_from_provider_attrs(%{
               provider: :apns,
               platform: :ios,
               environment: :production,
               reason: :delivery_failed,
               occurred_at: "2026-08-24T12:00:00Z",
               metadata: %{
                 safe_detail: :kept,
                 nested: %{token: raw_token, provider_payload: %{body: provider_body}},
                 url: "https://private.example.test/path",
                 session: [session_ref: "session-secret"]
               }
             })

    assert feedback.metadata == %{safe_detail: :kept}
    refute inspect(Contracts.to_map(feedback)) =~ raw_token
    refute inspect(Contracts.to_map(feedback)) =~ provider_body
  end

  defp assert_feedback(provider, code, expected_event) do
    assert {:ok, %ProviderFeedback{} = feedback} =
             Redaction.feedback_from_provider_attrs(%{
               provider: provider,
               platform: if(provider == :apns, do: :ios, else: :android),
               environment: :production,
               reason: code,
               occurred_at: "2026-06-02T18:00:00Z"
             })

    assert feedback.feedback_event == expected_event
  end
end
