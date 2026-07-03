defmodule Crosswake.Companions.Chimeway.DenialCodes do
  @moduledoc """
  Canonical denial subcodes and sanitization for Chimeway notification open intents.
  """

  @allowed_detail_keys [
    :open_ref,
    :binding_ref,
    :action_kind,
    :evaluated_at,
    :route_id,
    :action_ref
  ]

  @spec notification_open_expired() :: String.t()
  def notification_open_expired, do: "notification.open.expired"

  @spec notification_open_replayed() :: String.t()
  def notification_open_replayed, do: "notification.open.replayed"

  @spec notification_open_binding_revoked() :: String.t()
  def notification_open_binding_revoked, do: "notification.open.binding_revoked"

  @spec notification_open_route_mismatch() :: String.t()
  def notification_open_route_mismatch, do: "notification.open.route_mismatch"

  @spec notification_open_binding_mismatch() :: String.t()
  def notification_open_binding_mismatch, do: "notification.open.binding_mismatch"

  @spec notification_open_action_mismatch() :: String.t()
  def notification_open_action_mismatch, do: "notification.open.action_mismatch"

  @spec notification_open_unsupported_action() :: String.t()
  def notification_open_unsupported_action, do: "notification.open.unsupported_action"

  @spec notification_open_policy_denied() :: String.t()
  def notification_open_policy_denied, do: "notification.open.policy_denied"

  @doc """
  Sanitizes details, explicitly dropping any keys not in the allowlist
  to prevent PII, tokens, or opaque raw payload data from leaking
  to telemetry or unverified clients.
  """
  @spec sanitize_details(map()) :: map()
  def sanitize_details(details) when is_map(details) do
    Map.take(details, @allowed_detail_keys)
  end
end
