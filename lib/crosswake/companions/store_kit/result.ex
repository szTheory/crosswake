defmodule Crosswake.Companions.StoreKit.Result do
  @moduledoc false

  alias Crosswake.Commerce.ProviderEvidence

  @enforce_keys [:status]
  defstruct [:status, :lifecycle_hint, :message, metadata: %{}]

  @type status ::
          :submitted
          | :user_canceled
          | :pending
          | :provider_error
          | :prerequisite_missing
          | :reconcile_required

  @type t :: %__MODULE__{
          status: status(),
          lifecycle_hint: atom() | nil,
          message: String.t() | nil,
          metadata: map()
        }

  @spec new(map() | keyword()) :: {:ok, t()} | {:error, keyword()}
  def new(attrs) when is_list(attrs), do: attrs |> Map.new() |> new()

  def new(attrs) when is_map(attrs) do
    with {:ok, result} <- build_result(attrs),
         :ok <- validate(result) do
      {:ok, result}
    end
  end

  def new(_attrs), do: {:error, [result: :invalid_attrs]}

  defp build_result(attrs) do
    try do
      {:ok, struct!(__MODULE__, attrs)}
    rescue
      error in [ArgumentError, KeyError] -> {:error, [result: Exception.message(error)]}
    end
  end

  defp validate(%__MODULE__{} = result) do
    errors = []
    errors = if result.status in ProviderEvidence.result_status_vocabulary(), do: errors, else: [{:status, {:invalid_status, result.status}} | errors]

    errors =
      if is_nil(result.lifecycle_hint) or result.lifecycle_hint in ProviderEvidence.lifecycle_hint_vocabulary() do
        errors
      else
        [{:lifecycle_hint, {:invalid_lifecycle_hint, result.lifecycle_hint}} | errors]
      end

    if errors == [], do: :ok, else: {:error, Enum.reverse(errors)}
  end
end
