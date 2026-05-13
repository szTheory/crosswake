defmodule Crosswake.Policy.Route do
  @moduledoc """
  Normalized Phase 1 route policy contract.
  """

  alias Crosswake.Policy.Defaults
  alias Crosswake.Policy.Schema

  @enforce_keys [:id, :runtime]
  defstruct [:id, :runtime, :security, offline: :unavailable, capabilities: [], packs: [], sync: []]

  @type t :: %__MODULE__{
          id: String.t(),
          runtime: Schema.runtime(),
          offline: Schema.offline(),
          capabilities: [String.t()],
          packs: [String.t()],
          sync: [String.t()],
          security: Schema.security() | nil
        }

  @spec new(keyword()) :: {:ok, t()} | {:error, NimbleOptions.ValidationError.t()}
  def new(options) when is_list(options) do
    options
    |> merged_options()
    |> Schema.validate()
    |> case do
      {:ok, validated} -> {:ok, struct!(__MODULE__, validated)}
      {:error, error} -> {:error, error}
    end
  end

  @spec new!(keyword()) :: t()
  def new!(options) when is_list(options) do
    options
    |> merged_options()
    |> Schema.validate!()
    |> then(&struct!(__MODULE__, &1))
  end

  defp merged_options(options) do
    Defaults.route()
    |> Keyword.merge(options)
  end
end
