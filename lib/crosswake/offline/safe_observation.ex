defmodule Crosswake.Offline.SafeObservation do
  @moduledoc """
  Closed, transport-independent observation vocabulary for scoped replay.

  This is deliberately not a redactor.  Replay and authority values cannot be
  passed here: callers construct the small observation from declared values.
  """

  @replay_keys [:route_id, :runtime, :lifecycle, :outcome, :denial, :measurements]
  @doctor_keys [:configuration, :adapter_readiness]
  @runtimes [:offline_island]
  @lifecycles [:started, :replayed, :stopped, :blocked]
  @outcomes [:accepted, :rejected, :conflict, :blocked]
  @denials [:none, :scope_inactive, :sigra_denied, :route_denied, :feature_denied]
  @measurements [:attempt_count, :event_count, :duration_ms]

  @enforce_keys @replay_keys ++ @doctor_keys
  defstruct @enforce_keys

  defmodule Error do
    @enforce_keys [:rule_id, :path]
    defstruct [:rule_id, :path]
  end

  @type t :: %__MODULE__{}

  @spec new(map()) :: {:ok, t()} | {:error, Error.t()}
  def new(attrs) when is_map(attrs) and not is_struct(attrs) do
    with :ok <- exact_atom_keys(attrs),
         :ok <- route(attrs.route_id),
         :ok <- enum(attrs.runtime, @runtimes, :runtime),
         :ok <- enum(attrs.lifecycle, @lifecycles, :lifecycle),
         :ok <- enum(attrs.outcome, @outcomes, :outcome),
         :ok <- enum(attrs.denial, @denials, :denial),
         :ok <- measurements(attrs.measurements),
         :ok <- readiness(attrs.configuration, :configuration),
         :ok <- readiness(attrs.adapter_readiness, :adapter_readiness) do
      {:ok, struct!(__MODULE__, attrs)}
    end
  end

  def new(_), do: error("CW-SAFE-OBSERVATION-INPUT", :input)

  @spec to_telemetry(t()) :: %{required(atom()) => atom() | non_neg_integer() | String.t()}
  def to_telemetry(%__MODULE__{} = observation) do
    %{route_id: observation.route_id, runtime: observation.runtime, lifecycle: observation.lifecycle,
      outcome: observation.outcome, denial: observation.denial}
    |> Map.merge(observation.measurements)
  end

  @spec to_logger(t()) :: map()
  def to_logger(observation), do: to_telemetry(observation)

  @spec to_doctor(t()) :: %{configuration: atom(), adapter_readiness: atom()}
  def to_doctor(%__MODULE__{} = observation),
    do: %{configuration: observation.configuration, adapter_readiness: observation.adapter_readiness}

  defp exact_atom_keys(attrs) do
    if Map.keys(attrs) |> MapSet.new() == MapSet.new(@replay_keys ++ @doctor_keys),
      do: :ok,
      else: error("CW-SAFE-OBSERVATION-KEY", :input)
  end

  defp route(value) when is_binary(value) do
    if value =~ ~r/^route-[0-9a-f]{16}$/, do: :ok, else: error("CW-SAFE-OBSERVATION-ROUTE", :route_id)
  end
  defp route(_), do: error("CW-SAFE-OBSERVATION-ROUTE", :route_id)

  defp enum(value, allowed, path) do
    if value in allowed, do: :ok, else: error("CW-SAFE-OBSERVATION-VALUE", path)
  end

  defp measurements(values) when is_map(values) and not is_struct(values) do
    valid? =
      Map.keys(values) |> Enum.all?(&(&1 in @measurements)) and
        Enum.all?(values, fn {_key, value} -> is_integer(value) and value >= 0 and value <= 1_000_000 end)

    if valid?, do: :ok, else: error("CW-SAFE-OBSERVATION-MEASUREMENT", :measurements)
  end
  defp measurements(_), do: error("CW-SAFE-OBSERVATION-MEASUREMENT", :measurements)

  defp readiness(value, path) when value in [:configured, :unconfigured, :ready, :blocked, :unavailable], do: :ok
  defp readiness(_, path), do: error("CW-SAFE-OBSERVATION-READINESS", path)

  defp error(rule_id, path), do: {:error, %Error{rule_id: rule_id, path: path}}
end
