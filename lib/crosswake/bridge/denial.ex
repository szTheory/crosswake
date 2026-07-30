defmodule Crosswake.Bridge.Denial do
  @moduledoc """
  Internal wire-decode envelope for bounded bridge deny replies (demoted, Phase 154,
  D-28).

  This struct exists only to model the doubly-nested shape shipped natives already
  put on the wire (`reply["denial"]["denial"]["reason"]`) — every shell binary
  already in the field emits it, and the wire is frozen until a
  `Crosswake.Bridge.Contract.@version` major, so this module is NOT "cleaned up" here.
  Adopters should never match on this struct directly: `Crosswake.Bridge.push/3`
  flattens it into a plain `Crosswake.Shell.Denial` before delivering
  `{:crosswake_bridge, ref, %Crosswake.Bridge.Reply{}}` to `handle_info/2` — match on
  `Crosswake.Shell.Denial` instead.
  """

  alias Crosswake.Bridge.Contract
  alias Crosswake.Manifest.Types
  alias Crosswake.Shell.Denial, as: ShellDenial

  @enforce_keys [:command, :route_id, :correlation_id, :denial]
  defstruct [:command, :route_id, :correlation_id, :denial, thread_id: nil]

  @type t :: %__MODULE__{
          command: String.t(),
          route_id: String.t(),
          correlation_id: String.t(),
          denial: ShellDenial.t(),
          thread_id: String.t() | nil
        }

  @spec new(keyword()) :: t()
  def new(attrs) when is_list(attrs) do
    struct!(__MODULE__, %{
      command: Keyword.fetch!(attrs, :command),
      route_id: Keyword.fetch!(attrs, :route_id),
      correlation_id: Keyword.fetch!(attrs, :correlation_id),
      denial: Keyword.fetch!(attrs, :denial),
      thread_id: Keyword.get(attrs, :thread_id)
    })
  end

  @spec from_request(Contract.Request.t(), ShellDenial.t()) :: t()
  def from_request(%Contract.Request{} = request, %ShellDenial{} = denial) do
    new(
      command: request.command,
      route_id: request.route_id,
      correlation_id: request.correlation_id,
      thread_id: request.thread_id,
      denial: denial
    )
  end

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = denial) do
    %{
      "command" => denial.command,
      "route_id" => denial.route_id,
      "correlation_id" => denial.correlation_id,
      "thread_id" => denial.thread_id,
      "denial" => ShellDenial.to_map(denial.denial)
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
    |> Types.to_map()
  end
end
