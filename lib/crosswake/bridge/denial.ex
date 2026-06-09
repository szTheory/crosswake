defmodule Crosswake.Bridge.Denial do
  @moduledoc """
  Typed denial reply payload for bounded bridge requests.
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
