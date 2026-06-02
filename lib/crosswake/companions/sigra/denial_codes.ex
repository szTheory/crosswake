defmodule Crosswake.Companions.Sigra.DenialCodes do
  @moduledoc """
  Canonical Sigra auth denial subcodes and shell-safe detail sanitization.

  Phase 54 keeps `:step_up_required` as the public shell reason. These subcodes
  give operators stable, low-cardinality auth facts without exposing secret or
  identity-bearing values.
  """

  @codes [
    "auth.step_up.missing_context",
    "auth.step_up.invalid_context",
    "auth.step_up.non_active",
    "auth.step_up.idle_expired",
    "auth.step_up.absolute_expired",
    "auth.step_up.revoked",
    "auth.step_up.version_mismatch",
    "auth.step_up.insufficient_assurance",
    "auth.step_up.stale_auth",
    "auth.step_up.remembered_not_allowed",
    "auth.step_up.cached_not_allowed",
    "auth.handoff.missing_ticket",
    "auth.handoff.invalid_ticket",
    "auth.handoff.expired_ticket",
    "auth.handoff.replayed_ticket",
    "auth.handoff.revoked_ticket",
    "auth.handoff.binding_mismatch",
    "auth.handoff.intent_mismatch",
    "auth.handoff.route_mismatch",
    "auth.handoff.projection_failed"
  ]

  @allowed_detail_keys [
    "required_assurance_level",
    "current_assurance_level",
    "required_mfa_level",
    "current_mfa_level",
    "max_auth_age_seconds",
    "auth_age_seconds",
    "auth_posture",
    "authority_state",
    "evaluated_at",
    "challenge_ref",
    "step_up_token_ref",
    "expected_session_version",
    "current_session_version",
    "handoff_ref",
    "handoff_state",
    "handoff_kind",
    "handoff_version",
    "handoff_transport",
    "binding_kind",
    "intent_kind",
    "route_binding",
    "ticket_expires_at",
    "ticket_age_seconds"
  ]

  @safe_ref ~r/^[A-Za-z0-9._:-]{1,128}$/

  @spec codes() :: [String.t()]
  def codes, do: @codes

  @spec valid_code?(term()) :: boolean()
  def valid_code?(code), do: code in @codes

  @spec allowed_detail_keys() :: [String.t()]
  def allowed_detail_keys, do: @allowed_detail_keys

  @spec sanitize_details(map() | keyword()) :: map()
  def sanitize_details(details) when is_list(details),
    do: details |> Map.new() |> sanitize_details()

  def sanitize_details(details) when is_map(details) do
    details
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      string_key = stringify_key(key)

      if string_key in @allowed_detail_keys and safe_value?(string_key, value) do
        Map.put(acc, string_key, normalize_value(value))
      else
        acc
      end
    end)
  end

  def sanitize_details(_details), do: %{}

  defp stringify_key(key) when is_atom(key), do: Atom.to_string(key)
  defp stringify_key(key) when is_binary(key), do: key
  defp stringify_key(key), do: inspect(key)

  defp safe_value?(key, value)
       when key in ["challenge_ref", "step_up_token_ref", "handoff_ref"] and is_binary(value),
       do: Regex.match?(@safe_ref, value)

  defp safe_value?(key, _value) when key in ["challenge_ref", "step_up_token_ref", "handoff_ref"],
    do: false

  defp safe_value?(_key, value) when is_atom(value) and value not in [true, false, nil], do: true
  defp safe_value?(_key, value) when is_binary(value), do: String.length(value) <= 128
  defp safe_value?(_key, value) when is_integer(value) and value >= 0, do: true
  defp safe_value?(_key, nil), do: false
  defp safe_value?(_key, _value), do: false

  defp normalize_value(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_value(value), do: value
end
