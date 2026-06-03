defmodule CrosswakeExample.SaaSPortal.StepUpOnMount do
  @moduledoc """
  Thin LiveView on_mount adapter over the shared Sigra step-up ceremony core.
  """

  alias Crosswake.Companions.Sigra.Contracts
  alias Crosswake.Companions.Sigra.StepUp, as: SigraStepUp
  alias Crosswake.Companions.Sigra.StepUpCeremony
  alias Crosswake.Shell.Denial
  alias CrosswakeExample.SaaSPortal.StepUp
  alias Phoenix.LiveView

  def on_mount({:require_step_up, opts}, _params, _session, socket) do
    case decision(Keyword.fetch!(opts, :route), Keyword.get(opts, :auth_context), opts) do
      {:allow, _facts} ->
        {:cont, socket}

      {:challenge, _intent, challenge} ->
        redirected = LiveView.redirect(socket, to: challenge_path(challenge))
        {:halt, redirected}

      {:deny, %Denial{} = denial} ->
        redirected = LiveView.redirect(socket, to: denied_path(denial))
        {:halt, redirected}
    end
  end

  def decision(route, auth_context, opts) do
    StepUpCeremony.evaluate_or_issue(route, auth_context,
      expected_session_version: Keyword.get(opts, :expected_session_version),
      issue_intent: &issue_intent/1
    )
  end

  defp issue_intent(attrs) do
    with {:ok, issued} <- StepUp.issue(attrs),
         {:ok, challenge} <-
           StepUp.challenge(issued.signed_locator, %{request_ref: attrs.request_ref}),
         {:ok, intent} <- to_contract_intent(issued.intent) do
      {:ok, %{intent: intent, challenge: challenge}}
    end
  end

  defp to_contract_intent(intent) do
    with {:ok, lane} <-
           Contracts.new_session_authority_lane(
             atomize_known_authority(intent.projected_authority)
           ) do
      SigraStepUp.new_step_up_intent_record(%{
        intent_ref: intent.intent_ref,
        locator_digest: intent.locator_digest,
        state: String.to_existing_atom(intent.state),
        subject_ref: intent.subject_ref,
        org_id: intent.org_id,
        source_session_ref: intent.source_session_ref,
        expected_session_version: intent.expected_session_version,
        device_ref: intent.device_ref,
        source_route_id: intent.source_route_id,
        return_route_id: intent.return_route_id,
        return_params: intent.return_params,
        required_assurance_level: String.to_existing_atom(intent.required_assurance_level),
        required_auth_posture: String.to_existing_atom(intent.required_auth_posture),
        max_auth_age_seconds: intent.max_auth_age_seconds,
        challenge_kind: String.to_atom(intent.challenge_kind),
        issued_at: intent.issued_at,
        expires_at: intent.expires_at,
        challenged_at: intent.challenged_at,
        consumed_at: intent.consumed_at,
        canceled_at: intent.canceled_at,
        revoked_at: intent.revoked_at,
        cancellation_reason: intent.cancellation_reason,
        revocation_reason: intent.revocation_reason,
        audit_correlation_ref: intent.audit_correlation_ref,
        projected_session_authority_lane: lane
      })
    end
  end

  defp atomize_known_authority(authority) when is_map(authority) do
    authority
    |> Map.new(fn {key, value} -> {normalize_key(key), value} end)
    |> update_atom(:state)
    |> update_atom(:assurance_level)
    |> update_authn_methods()
  end

  defp normalize_key(key) when is_atom(key), do: key
  defp normalize_key(key) when is_binary(key), do: String.to_atom(key)
  defp normalize_key(key), do: key

  defp update_atom(map, key) do
    case Map.get(map, key) do
      value when is_binary(value) -> Map.put(map, key, String.to_existing_atom(value))
      _other -> map
    end
  rescue
    ArgumentError -> map
  end

  defp update_authn_methods(map) do
    case Map.get(map, :authn_methods) do
      methods when is_list(methods) ->
        Map.put(map, :authn_methods, Enum.map(methods, &string_to_existing_atom/1))

      _other ->
        map
    end
  end

  defp string_to_existing_atom(value) when is_binary(value) do
    String.to_existing_atom(value)
  rescue
    ArgumentError -> value
  end

  defp string_to_existing_atom(value), do: value

  defp challenge_path(challenge) do
    "/sigra/step-up?challenge_ref=#{URI.encode_www_form(challenge.support_ref || challenge.challenge_ref)}"
  end

  defp denied_path(%Denial{} = denial) do
    "/sigra/step-up/denied?code=#{URI.encode_www_form(denial.code)}"
  end
end
