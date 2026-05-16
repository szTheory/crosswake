defmodule Crosswake.Transfer.Runtime do
  @moduledoc """
  Route-local transfer runtime status helpers.
  """

  alias Crosswake.Transfer.Contracts

  defmodule Status do
    @moduledoc false

    @enforce_keys [:route_id, :active_route_id, :transfer_id, :state]
    defstruct [:route_id, :active_route_id, :transfer_id, :state, detail: nil, metadata: %{}]

    @type t :: %__MODULE__{
            route_id: String.t(),
            active_route_id: String.t(),
            transfer_id: String.t(),
            state: Contracts.state(),
            detail: String.t() | nil,
            metadata: map()
          }
  end

  @spec new_status(keyword()) :: Status.t()
  def new_status(attrs) when is_list(attrs) do
    struct!(Status, %{
      route_id: Keyword.fetch!(attrs, :route_id),
      active_route_id: Keyword.fetch!(attrs, :active_route_id),
      transfer_id: Keyword.fetch!(attrs, :transfer_id),
      state: Keyword.fetch!(attrs, :state),
      detail: Keyword.get(attrs, :detail),
      metadata: Keyword.get(attrs, :metadata, %{})
    })
  end

  @spec route_local?(Status.t()) :: boolean()
  def route_local?(%Status{} = status), do: status.route_id == status.active_route_id
end
