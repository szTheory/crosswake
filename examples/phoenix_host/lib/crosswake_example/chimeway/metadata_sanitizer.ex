defmodule CrosswakeExample.Chimeway.MetadataSanitizer do
  @moduledoc """
  Allowlisted metadata persistence for Chimeway token binding and audit rows.

  Drops raw token material, provider payload bodies, notification content,
  route params, and PII from metadata before persistence. Both atom-keyed
  and string-keyed inputs are handled without calling `String.to_atom/1`.
  """

  @forbidden_atom_keys [
    :token,
    :raw_token,
    :device_token,
    :registration_token,
    :apns_token,
    :fcm_token,
    :provider_payload,
    :raw_payload,
    :notification_title,
    :notification_body,
    :route_params,
    :provider_response_body,
    :email,
    :ip,
    :user_agent,
    :device_id
  ]

  @forbidden_string_keys Enum.map(@forbidden_atom_keys, &Atom.to_string/1)

  @spec forbidden_keys() :: [atom()]
  def forbidden_keys, do: @forbidden_atom_keys

  @spec sanitize(map()) :: map()
  def sanitize(metadata) when is_map(metadata) do
    metadata
    |> Enum.reject(fn {key, _value} -> forbidden_key?(key) end)
    |> Map.new(fn {key, value} -> {key, sanitize_value(value)} end)
  end

  def sanitize(_metadata), do: %{}

  @doc """
  Projects untrusted notification-open metadata to the empty durable contract.

  Notification opens retain their explicit schema fields and host-authoritative
  lifecycle events only. Caller metadata is never retained, inspected, or
  traversed at this persistence boundary.
  """
  @spec sanitize_notification_open(term()) :: %{}
  def sanitize_notification_open(_metadata), do: %{}

  defp sanitize_value(value) when is_map(value), do: sanitize(value)

  defp sanitize_value(value) when is_list(value) do
    if Keyword.keyword?(value) do
      value
      |> Enum.reject(fn {key, _value} -> forbidden_key?(key) end)
      |> Enum.map(fn {key, nested_value} -> {key, sanitize_value(nested_value)} end)
    else
      Enum.map(value, &sanitize_value/1)
    end
  end

  defp sanitize_value(value), do: value

  defp forbidden_key?(key) do
    (is_atom(key) and key in @forbidden_atom_keys) or
      (is_binary(key) and key in @forbidden_string_keys)
  end
end
