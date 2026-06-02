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
    Enum.reject(metadata, fn {key, _value} ->
      (is_atom(key) and key in @forbidden_atom_keys) or
        (is_binary(key) and key in @forbidden_string_keys)
    end)
    |> Map.new()
  end

  def sanitize(_metadata), do: %{}
end
