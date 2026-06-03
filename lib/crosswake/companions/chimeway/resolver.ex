defmodule Crosswake.Companions.Chimeway.Resolver do
  @moduledoc """
  Resolves notification open evidence against the Crosswake manifest and 
  backend intent state, and delegates to RouteGate.
  """

  alias Crosswake.Companions.Chimeway.Contracts.NotificationOpenEvidence
  alias Crosswake.Companions.Chimeway.Contracts.OpenResolution
  alias Crosswake.Companions.Sigra.DenialCodes
  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Manifest.Types.Root
  alias Crosswake.Manifest.Types.RouteEntry
  alias Crosswake.Shell.Denial

  @generic_message "notification open resolution failed"

  @doc """
  Resolves notification open evidence.
  """
  def resolve(%Root{} = manifest, %NotificationOpenEvidence{} = evidence, intent_consumer) do
    route = Map.get(manifest.routes, evidence.route_id)

    cond do
      is_nil(route) ->
        deny_no_route(evidence.route_id, "notification.open.route_mismatch", %{})

      not notification_open_allowed?(route) ->
        deny(route, "notification.open.policy_denied", %{})

      not action_allowed?(route, evidence.action_ref) ->
        deny(route, "notification.open.unsupported_action", %{action_ref: evidence.action_ref})

      true ->
        case intent_consumer.consume_intent(evidence) do
          {:ok, %OpenResolution{state: :valid}} ->
            target = %Crosswake.Compatibility.Target{
              manifest_schema_version: manifest.compatibility && manifest.compatibility.manifest_schema_version,
              bridge_protocol_version: manifest.compatibility && manifest.compatibility.bridge_protocol_version,
              native_runtime_version: manifest.compatibility && manifest.compatibility.native_runtime_version,
              origin: manifest.host && manifest.host.origin
            }

            # Delegate to RouteGate
            decision = RouteGate.evaluate(manifest, evidence.route_id, target, 
              activation_source: :notification, 
              auth_context: evidence.auth_context
            )
            
            if decision.status == :allow do
              {:allow, decision}
            else
              {:deny, decision.denial}
            end

          {:ok, %OpenResolution{state: state}} ->
            deny(route, "notification.open.#{state}", %{intent_state: state})

          {:error, state} ->
            deny(route, "notification.open.#{state}", %{intent_state: state})
        end
    end
  end

  defp notification_open_allowed?(%RouteEntry{notification_open: false}), do: false
  defp notification_open_allowed?(%RouteEntry{notification_open: nil}), do: false
  defp notification_open_allowed?(%RouteEntry{notification_open: _}), do: true

  defp action_allowed?(%RouteEntry{notification_open: [actions: actions]}, action_ref) when is_list(actions) do
    action_ref in actions
  end
  defp action_allowed?(%RouteEntry{}, _action_ref), do: true

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
