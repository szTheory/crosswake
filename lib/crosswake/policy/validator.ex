defmodule Crosswake.Policy.Validator do
  @moduledoc """
  Semantic invariant checks for normalized Crosswake route policy.
  """

  alias Crosswake.Policy.Error
  alias Crosswake.Policy.Route

  @known_capabilities MapSet.new(
                        Crosswake.Manifest.Builder.public_route_capability_ids() ++
                          Crosswake.Manifest.Builder.compatibility_route_capability_ids() ++
                          ~w(
                            audio
                            background_audio
                            background_sync
                            document_preview
                            generic_plugin_bus
                            lock_screen_controls
                            microphone
                            webrtc
                          )
                      )
  @commerce_role_values Crosswake.Policy.Schema.commerce_role_values()
  @provider_specific_commerce_terms MapSet.new(["storekit", "play_billing", "revenuecat"])

  @spec validate([Route.t()], [map()]) :: [Error.t()]
  def validate(routes, managed_routes) do
    routes
    |> Enum.zip(managed_routes)
    |> Enum.flat_map(fn {route, managed_route} ->
      route
      |> route_errors()
      |> Enum.map(&build_error(managed_route, route, &1))
    end)
  end

  defp route_errors(route) do
    []
    |> validate_runtime_offline(route)
    |> validate_entry(route)
    |> validate_sync(route)
    |> validate_security(route)
    |> validate_capabilities(route)
    |> validate_commerce(route)
    |> validate_unique_list(route, :capabilities, route.capabilities)
    |> validate_unique_pack_ids(route)
    |> validate_unique_list(route, :sync, route.sync)
    |> validate_unique_transfer_ids(route)
  end

  defp validate_runtime_offline(errors, %Route{runtime: :live_view, offline: :local_first}) do
    [
      %{
        key: :offline,
        message: "live_view routes cannot declare offline :local_first",
        hint: "use runtime: :offline_island for local-first ownership, or change offline to :unavailable or :cached_read_only"
      }
      | errors
    ]
  end

  defp validate_runtime_offline(errors, %Route{runtime: :offline_island, offline: :unavailable}) do
    [
      %{
        key: :offline,
        message: "offline_island routes cannot declare offline :unavailable",
        hint: "set offline: :cached_read_only or :local_first for offline_island routes"
      }
      | errors
    ]
  end

  defp validate_runtime_offline(errors, _route), do: errors

  defp validate_entry(errors, %Route{entry: :external, runtime: :offline_island}) do
    [
      %{
        key: :entry,
        message: "entry :external is not supported on offline_island routes",
        hint: "keep offline_island routes internal_only until external activation semantics are explicitly proven"
      }
      | errors
    ]
  end

  defp validate_entry(errors, _route), do: errors

  defp validate_sync(errors, %Route{sync: sync, offline: :unavailable}) when sync != [] do
    [
      %{
        key: :sync,
        message: "sync declarations require offline support",
        hint: "set offline: :cached_read_only or :local_first, or remove sync entries from the route policy"
      }
      | errors
    ]
  end

  defp validate_sync(errors, _route), do: errors

  defp validate_security(errors, %Route{} = route) do
    if security_required?(route) and is_nil(route.security) do
      [
        %{
          key: :security,
          message: "security must be declared when offline, capability, pack, or sync policy is enabled",
          hint: "add security: :standard or security: :sensitive to the route policy"
        }
        | errors
      ]
    else
      errors
    end
  end

  defp validate_capabilities(errors, %Route{capabilities: capabilities}) do
    Enum.reduce(capabilities, errors, fn capability, acc ->
      if MapSet.member?(@known_capabilities, capability) do
        acc
      else
        [
          %{
            key: :capabilities,
            message: "unknown capability #{inspect(capability)}",
            hint:
              "declare semantic Crosswake capability families such as app_info, haptics, share, permissions.status, notification_token, or file_picker"
          }
          | acc
        ]
      end
    end)
  end

  defp validate_commerce(errors, %Route{commerce: nil}), do: errors

  defp validate_commerce(errors, %Route{} = route) do
    errors
    |> validate_commerce_role(route)
    |> validate_commerce_corridor(route)
  end

  defp validate_commerce_role(errors, %Route{commerce: %{role: role}} = route) do
    cond do
      role in @commerce_role_values ->
        errors

      is_binary(role) and MapSet.member?(@provider_specific_commerce_terms, role) ->
        [
          %{
            key: :commerce,
            message:
              "route #{inspect(route.id)} uses provider-specific commerce role #{inspect(role)}",
            hint: "use provider-neutral route roles such as :paywall_entry or :purchase_intent"
          }
          | errors
        ]

      true ->
        [
          %{
            key: :commerce,
            message:
              "route #{inspect(route.id)} uses unsupported commerce role #{inspect(role)}",
            hint: "use one of #{inspect(@commerce_role_values)}"
          }
          | errors
        ]
    end
  end

  defp validate_commerce_corridor(errors, %Route{commerce: %{corridor: corridor}} = route) do
    if MapSet.member?(@provider_specific_commerce_terms, corridor) do
      [
        %{
          key: :commerce,
          message:
            "route #{inspect(route.id)} uses provider-specific corridor vocabulary #{inspect(corridor)}",
          hint:
            "use provider-neutral corridor names and map storefront/provider terms outside Crosswake core"
        }
        | errors
      ]
    else
      errors
    end
  end

  defp validate_unique_list(errors, _route, _key, []), do: errors

  defp validate_unique_list(errors, route, key, values) do
    if Enum.uniq(values) == values do
      errors
    else
      [
        %{
          key: key,
          message: "#{key} entries must be unique for route #{inspect(route.id)}",
          hint: "remove duplicate #{key} entries from the route policy"
        }
        | errors
      ]
    end
  end

  defp validate_unique_pack_ids(errors, %Route{packs: []}), do: errors

  defp validate_unique_pack_ids(errors, %Route{} = route) do
    pack_ids = Enum.map(route.packs, & &1.id)

    if Enum.uniq(pack_ids) == pack_ids do
      errors
    else
      [
        %{
          key: :packs,
          message: "pack ids must be unique for route #{inspect(route.id)}",
          hint: "remove duplicate pack ids so the route points at one immutable version per pack"
        }
        | errors
      ]
    end
  end

  defp validate_unique_transfer_ids(errors, %Route{transfers: []}), do: errors

  defp validate_unique_transfer_ids(errors, %Route{} = route) do
    transfer_ids = Enum.map(route.transfers, & &1.id)

    if Enum.uniq(transfer_ids) == transfer_ids do
      errors
    else
      [
        %{
          key: :transfers,
          message: "transfer ids must be unique for route #{inspect(route.id)}",
          hint: "remove duplicate transfer ids so the route exposes one semantic seam per transfer declaration"
        }
        | errors
      ]
    end
  end

  defp build_error(managed_route, route, attrs) do
    source = Map.get(managed_route, :source, %{})

    struct!(Error, %{
      key: attrs.key,
      route_id: route.id,
      message: attrs.message,
      hint: attrs.hint,
      path: Map.get(managed_route, :path),
      helper: Map.get(managed_route, :helper),
      verb: Map.get(managed_route, :verb),
      file: Map.get(source, :file),
      line: Map.get(source, :line)
    })
  end

  defp security_required?(%Route{} = route) do
    route.offline != :unavailable or route.capabilities != [] or route.packs != [] or
      route.sync != [] or route.transfers != [] or route.entry != :internal_only
  end
end
