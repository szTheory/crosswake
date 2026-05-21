defmodule Crosswake.Bridge.Registry do
  @moduledoc """
  Manifest-backed Phase 3 bridge allowlist.
  """

  alias Crosswake.Manifest.Types.Capability
  alias Crosswake.Manifest.Types.Root
  alias Crosswake.Manifest.Types.RouteEntry
  alias Crosswake.Manifest.Types.TransferSeam

  @capability_commands %{
    "app.info.get" => "app.info.get",
    "haptics.impact" => "haptics.impact",
    "permissions.status" => "permissions.status",
    "notifications.token.get" => "notification_token",
    "files.pick" => "files.pick",
    "share.invoke" => "share.invoke"
  }

  @transfer_commands %{
    "transfer.import" => :import,
    "transfer.export" => :export,
    "transfer.download" => :download,
    "transfer.upload.prepare" => :upload
  }

  defmodule Entry do
    @moduledoc false

    @enforce_keys [:command, :capability, :version, :route_id]
    defstruct [:command, :capability, :version, :route_id, allowlisted_origins: []]

    @type t :: %__MODULE__{
            command: String.t(),
            capability: String.t(),
            version: String.t(),
            route_id: String.t(),
            allowlisted_origins: [String.t()]
          }
  end

  @spec allowed_commands() :: [String.t()]
  def allowed_commands do
    (@capability_commands |> Map.keys()) ++ (@transfer_commands |> Map.keys())
    |> Enum.sort()
  end

  @spec command_capability(String.t()) :: String.t() | nil
  def command_capability(command) do
    Map.get(@capability_commands, command) || if(Map.has_key?(@transfer_commands, command), do: command)
  end

  @spec command_supported?(String.t()) :: boolean()
  def command_supported?(command) do
    Map.has_key?(@capability_commands, command) or Map.has_key?(@transfer_commands, command)
  end

  @spec lookup(Root.t(), String.t(), String.t()) ::
          {:ok, Entry.t()}
          | {:error, :inactive_route | :unsupported_command | :undeclared_capability}
  def lookup(%Root{} = manifest, route_id, command)
      when is_binary(route_id) and is_binary(command) do
    with true <- command_supported?(command) || {:error, :unsupported_command},
         %RouteEntry{} = route <- Map.get(manifest.routes, route_id) || {:error, :inactive_route} do
      lookup_entry(manifest, route, command)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp lookup_entry(manifest, route, command) do
    cond do
      capability_id = Map.get(@capability_commands, command) ->
        capability_entry(manifest, route, command, capability_id)

      transfer_intent = Map.get(@transfer_commands, command) ->
        transfer_entry(route, command, transfer_intent)

      true ->
        {:error, :unsupported_command}
    end
  end

  defp capability_entry(manifest, route, command, capability_id) do
    with %Capability{} = capability <-
           lookup_capability(manifest, capability_id) || {:error, :undeclared_capability},
         true <- capability_declared_on_route?(route, capability) || {:error, :undeclared_capability} do
      {:ok,
       %Entry{
         command: command,
         capability: capability.family,
         version: capability.version,
         route_id: route.id,
         allowlisted_origins: route.allowlisted_origins
       }}
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :undeclared_capability}
      nil -> {:error, :undeclared_capability}
    end
  end

  defp capability_declared_on_route?(route, %Capability{id: capability_id, legacy_ids: legacy_ids}) do
    Enum.any?([capability_id | legacy_ids], &(&1 in route.capabilities))
  end

  defp lookup_capability(manifest, capability_id) do
    Map.get(manifest.capability_registry, capability_id) ||
      Enum.find_value(manifest.capability_registry, fn {_id, capability} ->
        if capability_id in capability.legacy_ids do
          capability
        end
      end)
  end

  defp transfer_entry(route, command, transfer_intent) do
    case Enum.find(route.transfers, &match_transfer_command?(&1, transfer_intent)) do
      %TransferSeam{} = transfer ->
        {:ok,
         %Entry{
           command: command,
           capability: command,
           version: transfer.version,
           route_id: route.id,
           allowlisted_origins: route.allowlisted_origins
         }}

      nil ->
        {:error, :undeclared_capability}
    end
  end

  defp match_transfer_command?(%TransferSeam{intent: intent}, transfer_intent), do: intent == transfer_intent
end
