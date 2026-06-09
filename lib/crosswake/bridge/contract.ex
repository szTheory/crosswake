defmodule Crosswake.Bridge.Contract do
  @moduledoc """
  Typed, versioned, request/reply-only contract for the bounded Phase 3 bridge.
  """

  alias Crosswake.Bridge.Denial
  alias Crosswake.Manifest.Types

  @protocol "crosswake.bridge"
  @version "1.1.0"
  @commands ~w(
    app.info.get
    haptics.impact
    permissions.status
    notifications.token.get
    share.invoke
    files.pick
    transfer.download
    transfer.export
    transfer.import
    transfer.upload.prepare
  )

  defmodule Request do
    @moduledoc false

    @enforce_keys [
      :protocol,
      :version,
      :command,
      :capability,
      :route_id,
      :active_route_id,
      :origin,
      :native_runtime_version,
      :correlation_id
    ]
    defstruct [
      :protocol,
      :version,
      :command,
      :capability,
      :route_id,
      :active_route_id,
      :origin,
      :native_runtime_version,
      :correlation_id,
      thread_id: nil,
      capabilities: %{},
      installed_packs: %{},
      payload: %{}
    ]

    @type t :: %__MODULE__{
            protocol: String.t(),
            version: String.t(),
            command: String.t(),
            capability: String.t(),
            route_id: String.t(),
            active_route_id: String.t(),
            origin: String.t(),
            native_runtime_version: String.t(),
            correlation_id: String.t(),
            thread_id: String.t() | nil,
            capabilities: %{optional(String.t()) => String.t()},
            installed_packs: %{optional(String.t()) => String.t()},
            payload: map()
          }
  end

  defmodule Reply do
    @moduledoc false

    @enforce_keys [:protocol, :version, :command, :route_id, :correlation_id, :status]
    defstruct [
      :protocol,
      :version,
      :command,
      :route_id,
      :correlation_id,
      :status,
      thread_id: nil,
      payload: %{},
      denial: nil
    ]

    @type status :: :ok | :deny | :error

    @type t :: %__MODULE__{
            protocol: String.t(),
            version: String.t(),
            command: String.t(),
            route_id: String.t(),
            correlation_id: String.t(),
            status: status(),
            thread_id: String.t() | nil,
            payload: map(),
            denial: Denial.t() | nil
          }
  end

  @spec protocol() :: String.t()
  def protocol, do: @protocol

  @spec version() :: String.t()
  def version, do: @version

  @spec commands() :: [String.t()]
  def commands, do: @commands

  @spec command_supported?(String.t()) :: boolean()
  def command_supported?(command), do: command in @commands

  @spec new_request(keyword()) :: Request.t()
  def new_request(attrs) when is_list(attrs) do
    struct!(Request, %{
      protocol: Keyword.get(attrs, :protocol, @protocol),
      version: Keyword.get(attrs, :version, @version),
      command: Keyword.fetch!(attrs, :command),
      capability: Keyword.fetch!(attrs, :capability),
      route_id: Keyword.fetch!(attrs, :route_id),
      active_route_id: Keyword.fetch!(attrs, :active_route_id),
      origin: Keyword.fetch!(attrs, :origin),
      native_runtime_version: Keyword.fetch!(attrs, :native_runtime_version),
      correlation_id: Keyword.fetch!(attrs, :correlation_id),
      thread_id: Keyword.get(attrs, :thread_id),
      capabilities: Keyword.get(attrs, :capabilities, %{}),
      installed_packs: Keyword.get(attrs, :installed_packs, %{}),
      payload: Keyword.get(attrs, :payload, %{})
    })
  end

  @spec new_reply(keyword()) :: Reply.t()
  def new_reply(attrs) when is_list(attrs) do
    struct!(Reply, %{
      protocol: Keyword.get(attrs, :protocol, @protocol),
      version: Keyword.get(attrs, :version, @version),
      command: Keyword.fetch!(attrs, :command),
      route_id: Keyword.fetch!(attrs, :route_id),
      correlation_id: Keyword.fetch!(attrs, :correlation_id),
      status: Keyword.fetch!(attrs, :status),
      thread_id: Keyword.get(attrs, :thread_id),
      payload: Keyword.get(attrs, :payload, %{}),
      denial: Keyword.get(attrs, :denial)
    })
  end

  @spec ok_reply(Request.t(), map()) :: Reply.t()
  def ok_reply(%Request{} = request, payload \\ %{}) when is_map(payload) do
    new_reply(
      command: request.command,
      route_id: request.route_id,
      correlation_id: request.correlation_id,
      thread_id: request.thread_id,
      status: :ok,
      payload: payload
    )
  end

  @spec deny_reply(Request.t(), Denial.t()) :: Reply.t()
  def deny_reply(%Request{} = request, %Denial{} = denial) do
    new_reply(
      command: request.command,
      route_id: request.route_id,
      correlation_id: request.correlation_id,
      thread_id: request.thread_id,
      status: :deny,
      denial: denial
    )
  end

  @spec to_map(Request.t() | Reply.t()) :: map()
  def to_map(%Request{} = request) do
    %{
      "protocol" => request.protocol,
      "version" => request.version,
      "command" => request.command,
      "capability" => request.capability,
      "route_id" => request.route_id,
      "active_route_id" => request.active_route_id,
      "origin" => request.origin,
      "native_runtime_version" => request.native_runtime_version,
      "correlation_id" => request.correlation_id,
      "thread_id" => request.thread_id,
      "capabilities" => Types.to_map(request.capabilities),
      "installed_packs" => Types.to_map(request.installed_packs),
      "payload" => Types.to_map(request.payload)
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  def to_map(%Reply{} = reply) do
    %{
      "protocol" => reply.protocol,
      "version" => reply.version,
      "command" => reply.command,
      "route_id" => reply.route_id,
      "correlation_id" => reply.correlation_id,
      "status" => Atom.to_string(reply.status),
      "thread_id" => reply.thread_id,
      "payload" => Types.to_map(reply.payload),
      "denial" => reply.denial && Denial.to_map(reply.denial)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
