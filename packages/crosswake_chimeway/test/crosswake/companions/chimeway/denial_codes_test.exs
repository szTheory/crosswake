defmodule Crosswake.Companions.Chimeway.DenialCodesTest do
  use ExUnit.Case, async: true

  alias Crosswake.Companions.Chimeway.DenialCodes

  describe "subcodes" do
    test "exports canonical subcodes" do
      assert DenialCodes.notification_open_expired() == "notification.open.expired"
      assert DenialCodes.notification_open_replayed() == "notification.open.replayed"
      assert DenialCodes.notification_open_binding_revoked() == "notification.open.binding_revoked"
      assert DenialCodes.notification_open_route_mismatch() == "notification.open.route_mismatch"
      assert DenialCodes.notification_open_binding_mismatch() == "notification.open.binding_mismatch"
      assert DenialCodes.notification_open_action_mismatch() == "notification.open.action_mismatch"
      assert DenialCodes.notification_open_unsupported_action() == "notification.open.unsupported_action"
      assert DenialCodes.notification_open_policy_denied() == "notification.open.policy_denied"
    end
  end

  describe "sanitize_details/1" do
    test "allows safe diagnostic identifiers" do
      details = %{
        open_ref: "open_123",
        binding_ref: "bind_123",
        action_kind: "navigate",
        evaluated_at: "2026-06-02T18:00:00Z"
      }

      assert DenialCodes.sanitize_details(details) == details
    end

    test "removes PII, raw tokens, and unknown keys" do
      details = %{
        open_ref: "open_123",
        raw_token: "secret123",
        device_token: "secret456",
        pii_email: "user@example.com",
        title: "Hello",
        body: "World",
        unknown_key: "value"
      }

      sanitized = DenialCodes.sanitize_details(details)

      assert sanitized.open_ref == "open_123"
      refute Map.has_key?(sanitized, :raw_token)
      refute Map.has_key?(sanitized, :device_token)
      refute Map.has_key?(sanitized, :pii_email)
      refute Map.has_key?(sanitized, :title)
      refute Map.has_key?(sanitized, :body)
      refute Map.has_key?(sanitized, :unknown_key)
    end
  end
end
