defmodule Crosswake.Bridge.Registry do
  @moduledoc """
  Manifest-backed Phase 3 bridge allowlist.
  """

  alias Crosswake.Manifest.Types.Capability
  alias Crosswake.Manifest.Types.Root
  alias Crosswake.Manifest.Types.RouteEntry

  @phase_3_commands %{
    "app.info.get" => "app.info.get",
    "haptics.impact" => "haptics.impact",
    "files.pick" => "files.pick"
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
    @phase_3_commands
    |> Map.keys()
    |> Enum.sort()
  end

  @spec command_capability(String.t()) :: String.t() | nil
  def command_capability(command), do: Map.get(@phase_3_commands, command)

  @spec command_supported?(String.t()) :: boolean()
  def command_supported?(command), do: Map.has_key?(@phase_3_commands, command)

  @spec lookup(Root.t(), String.t(), String.t()) ::
          {:ok, Entry.t()}
          | {:error, :inactive_route | :unsupported_command | :undeclared_capability}
  def lookup(%Root{} = manifest, route_id, command)
      when is_binary(route_id) and is_binary(command) do
    with true <- command_supported?(command) || {:error, :unsupported_command},
         %RouteEntry{} = route <- Map.get(manifest.routes, route_id) || {:error, :inactive_route},
         capability_id when is_binary(capability_id) <- command_capability(command),
         true <- capability_id in route.capabilities || {:error, :undeclared_capability},
         %Capability{} = capability <-
           Map.get(manifest.capability_registry, capability_id) ||
             {:error, :undeclared_capability} do
      {:ok,
       %Entry{
         command: command,
         capability: capability_id,
         version: capability.version,
         route_id: route_id,
         allowlisted_origins: route.allowlisted_origins
       }}
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :undeclared_capability}
      nil -> {:error, :undeclared_capability}
    end
  end
end
