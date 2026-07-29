defmodule Crosswake.Bridge.Registry do
  @moduledoc """
  Manifest-backed Phase 3 bridge allowlist.
  """

  alias Crosswake.Transfer.Contracts
  alias Crosswake.Manifest.Types.Capability
  alias Crosswake.Manifest.Types.Root
  alias Crosswake.Manifest.Types.RouteEntry
  alias Crosswake.Manifest.Types.TransferSeam

  @capability_commands %{
    "app.info.get" => "app_info",
    "haptics.impact" => "haptics",
    "permissions.status" => "permissions.status",
    "notifications.token.get" => "notification_token",
    "files.pick" => "file_picker",
    "share.invoke" => "share"
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

  @doc """
  Resolves the wire command for a declared capability family (the reverse of
  `command_capability/1`). `@capability_commands` is a bijection today (every
  capability family has exactly one command), so this reverse lookup is
  well-defined. Returns `nil` when the family is not part of the bounded bridge
  command vocabulary at all — the caller (`Crosswake.Bridge.push/3`) treats that
  as an undeclared-capability preflight failure (D-04), not a new authorization
  path.
  """
  @spec capability_command(String.t()) :: String.t() | nil
  def capability_command(capability_family) when is_binary(capability_family) do
    Enum.find_value(@capability_commands, fn {command, capability} ->
      if capability == capability_family, do: command
    end)
  end

  @spec lookup(Root.t(), String.t(), String.t()) ::
          {:ok, Entry.t()}
          | {:error, :inactive_route | :unsupported_command | :undeclared_capability}
  def lookup(%Root{} = manifest, route_id, command)
      when is_binary(route_id) and is_binary(command) do
    lookup(manifest, route_id, command, %{})
  end

  @spec lookup(Root.t(), String.t(), String.t(), map()) ::
          {:ok, Entry.t()}
          | {:error, :inactive_route | :unsupported_command | :undeclared_capability}
  def lookup(%Root{} = manifest, route_id, command, payload)
      when is_binary(route_id) and is_binary(command) and is_map(payload) do
    with true <- command_supported?(command) || {:error, :unsupported_command},
         %RouteEntry{} = route <- Map.get(manifest.routes, route_id) || {:error, :inactive_route} do
      lookup_entry(manifest, route, command, payload)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp lookup_entry(manifest, route, command, payload) do
    cond do
      command == "files.pick" ->
        file_picker_entry(route, command, payload)

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

  defp file_picker_entry(route, command, payload) do
    transfer_id = payload_transfer_id(payload)

    case Enum.find(route.transfers, &(&1.id == transfer_id)) do
      %TransferSeam{} = transfer ->
        case Contracts.validate_picker_declaration(transfer_declaration(transfer)) do
          :ok ->
            {:ok,
             %Entry{
               command: command,
               capability: "file_picker",
               version: transfer.version,
               route_id: route.id,
               allowlisted_origins: route.allowlisted_origins
             }}

          {:error, _reason} ->
            {:error, :undeclared_capability}
        end

      nil ->
        {:error, :undeclared_capability}
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

  defp payload_transfer_id(payload) do
    Map.get(payload, "transfer_id") || Map.get(payload, :transfer_id)
  end

  defp transfer_declaration(%TransferSeam{} = transfer) do
    Contracts.new_declaration(
      id: transfer.id,
      intent: transfer.intent,
      source: transfer.source,
      destination: transfer.destination,
      verification: transfer.verification,
      media_types: transfer.media_types
    )
  end
end
