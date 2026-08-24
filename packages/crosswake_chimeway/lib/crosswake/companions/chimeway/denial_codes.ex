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

  @max_detail_string_bytes 128

  @spec notification_open_expired() :: String.t()
  def notification_open_expired, do: "notification.open.expired"

  @spec notification_open_queued() :: String.t()
  def notification_open_queued, do: "notification.open.queued"

  @spec notification_open_consumed() :: String.t()
  def notification_open_consumed, do: "notification.open.consumed"

  @spec notification_open_authorized() :: String.t()
  def notification_open_authorized, do: "notification.open.authorized"

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

  @spec notification_open_authorization_denied() :: String.t()
  def notification_open_authorization_denied, do: "notification.open.authorization_denied"

  @spec notification_open_default_policy_denied() :: String.t()
  def notification_open_default_policy_denied, do: "notification.open.default_policy_denied"

  @doc """
  Sanitizes details, explicitly dropping any keys not in the allowlist
  to prevent PII, tokens, or opaque raw payload data from leaking
  to telemetry or unverified clients.
  """
  @spec sanitize_details(map() | keyword()) :: map()
  def sanitize_details(details) when is_list(details) do
    if Keyword.keyword?(details), do: details |> Map.new() |> sanitize_details(), else: %{}
  end

  def sanitize_details(details) when is_map(details) do
    Enum.reduce(@allowed_detail_keys, %{}, fn key, sanitized ->
      case Map.fetch(details, key) do
        {:ok, value} ->
          if safe_detail_value?(value), do: Map.put(sanitized, key, value), else: sanitized

        _ ->
          sanitized
      end
    end)
  end

  def sanitize_details(_details), do: %{}

  defp safe_detail_value?(value)
       when is_binary(value) and byte_size(value) > 0 and
              byte_size(value) <= @max_detail_string_bytes,
       do: true

  defp safe_detail_value?(value) when is_atom(value), do: true
  defp safe_detail_value?(value) when is_integer(value) and value >= 0, do: true
  defp safe_detail_value?(_value), do: false
end
