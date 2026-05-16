defmodule Crosswake.Offline.Status do
  @moduledoc """
  Stable route-local offline vocabulary for Crosswake support surfaces.
  """

  @statuses [
    :cached_read_only,
    :stale,
    :saved_locally,
    :queued_for_replay,
    :replay_failed,
    :conflict_requires_attention
  ]

  @enforce_keys [:state]
  defstruct [:state, :hint, details: %{}]

  @type state ::
          :cached_read_only
          | :stale
          | :saved_locally
          | :queued_for_replay
          | :replay_failed
          | :conflict_requires_attention

  @type t :: %__MODULE__{
          state: state(),
          hint: String.t() | nil,
          details: map()
        }

  @spec states() :: [state()]
  def states, do: @statuses

  @spec new(state(), keyword()) :: t()
  def new(state, attrs \\ []) when state in @statuses and is_list(attrs) do
    struct!(__MODULE__, %{
      state: state,
      hint: Keyword.get(attrs, :hint),
      details: Keyword.get(attrs, :details, %{})
    })
  end

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = status) do
    %{
      "state" => Atom.to_string(status.state),
      "hint" => status.hint,
      "details" => status.details
    }
    |> Enum.reject(fn {_key, value} -> value in [nil, %{}] end)
    |> Map.new()
  end
end
