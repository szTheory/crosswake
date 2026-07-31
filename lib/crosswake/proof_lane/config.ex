defmodule Crosswake.ProofLane.Config do
  @moduledoc "Closed, non-echoing configuration for a host-owned proof lane."

  @enforce_keys [
    :route_id,
    :route_path,
    :indexed_db_database,
    :indexed_db_store,
    :mutation_id_path,
    :sync_path,
    :evidence_path,
    :router,
    :ios_shell_root
  ]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          route_id: String.t(),
          route_path: String.t(),
          indexed_db_database: String.t(),
          indexed_db_store: String.t(),
          mutation_id_path: String.t(),
          sync_path: String.t(),
          evidence_path: String.t(),
          router: module(),
          ios_shell_root: Path.t()
        }

  defmodule Error do
    @enforce_keys [:rule_id, :key, :remediation]
    defstruct @enforce_keys
    @type t :: %__MODULE__{rule_id: String.t(), key: String.t(), remediation: String.t()}
  end

  @keys [
    :route_id,
    :route_path,
    :indexed_db_database,
    :indexed_db_store,
    :mutation_id_path,
    :sync_path,
    :evidence_path,
    :router,
    :ios_shell_root
  ]

  @spec normalize(keyword() | map()) :: {:ok, t()} | {:error, Error.t()}
  def normalize(input) when is_list(input), do: normalize(Map.new(input))

  def normalize(input) when is_map(input) do
    normalized = Map.new(input, fn {key, value} -> {normalize_key(key), value} end)

    with :ok <- exact_keys(normalized),
         :ok <- validate(normalized) do
      {:ok, struct!(__MODULE__, normalized)}
    end
  end

  def normalize(_),
    do: error("proof_lane.invalid_config", "config", "use config :crosswake, :proof_lane")

  defp normalize_key(key) when is_atom(key), do: key

  defp normalize_key(key) when is_binary(key),
    do: Enum.find(@keys, &(Atom.to_string(&1) == key)) || :unknown

  defp normalize_key(_), do: :unknown

  defp exact_keys(config) do
    keys = Map.keys(config) |> MapSet.new()
    expected = MapSet.new(@keys)

    cond do
      MapSet.equal?(keys, expected) ->
        :ok

      MapSet.member?(keys, :unknown) ->
        error("proof_lane.unknown_key", "config", "remove unsupported keys")

      true ->
        error("proof_lane.missing_key", "config", "supply every proof_lane key")
    end
  end

  defp validate(config) do
    validators = [
      {:route_id, &valid_route_id?/1},
      {:route_path, &valid_route_path?/1},
      {:indexed_db_database, &simple_name?/1},
      {:indexed_db_store, &simple_name?/1},
      {:mutation_id_path, &valid_field_path?/1},
      {:sync_path, &local_path?/1},
      {:evidence_path, &local_path?/1},
      {:router, &is_atom/1},
      {:ios_shell_root, &safe_absolute_path?/1}
    ]

    case Enum.find(validators, fn {key, validator} -> not validator.(Map.fetch!(config, key)) end) do
      nil ->
        :ok

      {key, _} ->
        error(
          "proof_lane.invalid_value",
          Atom.to_string(key),
          "use the documented local proof-lane shape"
        )
    end
  end

  defp valid_route_id?(value),
    do: is_binary(value) and String.match?(value, ~r/^route-[0-9a-f]{16}$/)

  defp valid_route_path?(value),
    do:
      local_path?(value) and
        Regex.match?(~r/^\/(?:[a-z0-9_-]+|:id)(?:\/(?:[a-z0-9_-]+|:id))*$/, value)

  defp simple_name?(value),
    do: is_binary(value) and String.match?(value, ~r/^[A-Za-z][A-Za-z0-9_-]*$/)

  defp valid_field_path?(value),
    do: is_binary(value) and String.match?(value, ~r/^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$/)

  defp local_path?(value),
    do:
      is_binary(value) and String.starts_with?(value, "/") and
        not String.contains?(value, ["//", "..", "://", "?"])

  defp safe_absolute_path?(value), do: local_path?(value) and Path.type(value) == :absolute

  defp error(rule_id, key, remediation),
    do: {:error, %Error{rule_id: rule_id, key: key, remediation: remediation}}
end
