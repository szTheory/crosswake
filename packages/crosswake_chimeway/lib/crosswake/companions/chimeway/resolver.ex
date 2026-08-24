defmodule Crosswake.Companions.Chimeway.Resolver do
  @moduledoc """
  Resolves notification open evidence against the Crosswake manifest and 
  backend intent state, and delegates to RouteGate.
  """

  alias Crosswake.Companions.Chimeway.Contracts.NotificationOpenEvidence
  alias Crosswake.Companions.Chimeway.Contracts.OpenResolution
  alias Crosswake.Companions.Chimeway.DenialCodes
  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Manifest.Types.Root
  alias Crosswake.Manifest.Types.RouteEntry
  alias Crosswake.Shell.Denial

  @generic_message "notification open resolution failed"
  @notification_open_actions ["tap", "reply", "approve"]

  @doc """
  Resolves notification open evidence.
  """
  def resolve(%Root{} = manifest, %NotificationOpenEvidence{} = evidence, intent_consumer) do
    case intent_consumer.consume_intent(evidence) do
      {:ok, %OpenResolution{state: :valid, route_id: route_id, action_ref: action_ref}}
      when is_binary(route_id) and is_binary(action_ref) ->
        route = Map.get(manifest.routes, route_id)

        cond do
          is_nil(route) ->
            deny_no_route(route_id, "notification.open.route_mismatch", %{})

          true ->
            resolve_current_policy(manifest, route, route_id, action_ref, evidence.auth_context)
        end

      {:ok, %OpenResolution{state: :valid}} ->
        deny_no_route("unknown", DenialCodes.notification_open_policy_denied(), %{})

      {:ok, %OpenResolution{state: state}} ->
        deny_no_route("unknown", denial_code_for_intent_state(state), %{intent_state: state})

      {:error, state} ->
        deny_no_route("unknown", denial_code_for_intent_state(state), %{intent_state: state})

      _unexpected ->
        deny_no_route("unknown", DenialCodes.notification_open_policy_denied(), %{})
    end
  end

  defp resolve_current_policy(manifest, route, route_id, action_ref, auth_context) do
    case notification_open_actions(route) do
      {:ok, actions} ->
        if action_ref in actions do
          target = %Crosswake.Compatibility.Target{
            manifest_schema_version:
              manifest.compatibility && manifest.compatibility.manifest_schema_version,
            bridge_protocol_version:
              manifest.compatibility && manifest.compatibility.bridge_protocol_version,
            native_runtime_version:
              manifest.compatibility && manifest.compatibility.native_runtime_version,
            origin: manifest.host && manifest.host.origin
          }

          decision =
            RouteGate.evaluate(manifest, route_id, target,
              activation_source: :notification,
              auth_context: auth_context
            )

          if decision.status == :allow, do: {:allow, decision}, else: {:deny, decision.denial}
        else
          deny(route, "notification.open.unsupported_action", %{action_ref: action_ref})
        end

      :error ->
        deny(route, "notification.open.policy_denied", %{})
    end
  end

  defp notification_open_actions(%RouteEntry{notification_open: %{actions: actions} = policy})
       when is_list(actions) and map_size(policy) == 1 do
    if actions != [] and Enum.all?(actions, &valid_notification_open_action?/1) and
         Enum.uniq(actions) == actions do
      {:ok, actions}
    else
      :error
    end
  end

  defp notification_open_actions(%RouteEntry{}), do: :error

  defp valid_notification_open_action?(action) when is_binary(action), do: action in @notification_open_actions
  defp valid_notification_open_action?(_action), do: false

  defp denial_code_for_intent_state(:expired), do: DenialCodes.notification_open_expired()
  defp denial_code_for_intent_state(:replayed), do: DenialCodes.notification_open_replayed()

  defp denial_code_for_intent_state(state) when state in [:revoked, :binding_revoked],
    do: DenialCodes.notification_open_binding_revoked()

  defp denial_code_for_intent_state(:binding_mismatch),
    do: DenialCodes.notification_open_binding_mismatch()

  defp denial_code_for_intent_state(:route_mismatch),
    do: DenialCodes.notification_open_route_mismatch()

  defp denial_code_for_intent_state(:action_mismatch),
    do: DenialCodes.notification_open_action_mismatch()

  defp denial_code_for_intent_state(_state), do: DenialCodes.notification_open_policy_denied()

  defp deny_no_route(route_id, code, details) do
    sanitized =
      details
      |> Map.put_new(
        :evaluated_at,
        DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
      )
      |> DenialCodes.sanitize_details()

    {:deny,
     Denial.new(
       reason: :notification_open_denied,
       code: code,
       message: @generic_message,
       route_id: route_id || "unknown",
       details: sanitized
     )}
  end

  defp deny(%RouteEntry{} = route, code, details) do
    deny_no_route(route.id, code, details)
  end
end
