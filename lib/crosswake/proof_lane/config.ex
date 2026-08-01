defmodule Crosswake.ProofLane.Config do
  @moduledoc "Closed, non-echoing configuration for a host-owned proof lane."

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

  @enforce_keys @keys
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
    @moduledoc false
    defexception [:rule_id, :key, :remediation]

    @type t :: %__MODULE__{rule_id: String.t(), key: String.t(), remediation: String.t()}

    @impl true
    def message(%__MODULE__{rule_id: rule_id, key: key, remediation: remediation}) do
      "#{rule_id}: #{key}; #{remediation}"
    end
  end

  @spec normalize(keyword() | map()) :: {:ok, t()} | {:error, Error.t()}
  def normalize(input) when is_list(input) do
    with :ok <- atom_keys(input),
         :ok <- no_duplicates(input) do
      normalize(Map.new(input))
    end
  end

  def normalize(input) when is_map(input) do
    with :ok <- atom_keys(Map.to_list(input)),
         :ok <- exact_keys(input),
         :ok <- validate(input) do
      {:ok, struct!(__MODULE__, input)}
    end
  end

  def normalize(_), do: error("PL-CONFIG-TYPE", "config", "use config :crosswake, :proof_lane")

  @spec host_root(t()) :: {:ok, String.t()} | {:error, Error.t()}
  def host_root(%__MODULE__{ios_shell_root: ios_shell_root}) do
    case derive_host_root(ios_shell_root) do
      {:ok, host_root} ->
        {:ok, host_root}

      :error ->
        error("PL-CONFIG-VALUE", "ios_shell_root", "use the documented local proof-lane shape")
    end
  end

  defp atom_keys(entries) do
    if Enum.all?(entries, fn {key, _} -> key in @keys end) do
      :ok
    else
      error("PL-CONFIG-KEY", "config", "use only documented atom keys")
    end
  end

  defp no_duplicates(entries) do
    if entries |> Enum.map(&elem(&1, 0)) |> Enum.uniq() |> length() == length(entries) do
      :ok
    else
      error("PL-CONFIG-DUPLICATE", "config", "declare each proof_lane key once")
    end
  end

  defp exact_keys(config) do
    keys = config |> Map.keys() |> MapSet.new()
    expected = MapSet.new(@keys)

    cond do
      MapSet.equal?(keys, expected) ->
        :ok

      not MapSet.subset?(keys, expected) ->
        error("PL-CONFIG-KEY", "config", "remove unsupported keys")

      true ->
        error("PL-CONFIG-MISSING", "config", "supply every documented proof_lane key")
    end
  end

  defp validate(config) do
    validators = [
      {:route_id, &valid_route_id?/1},
      {:route_path, &valid_route_path?/1},
      {:indexed_db_database, &simple_name?/1},
      {:indexed_db_store, &simple_name?/1},
      {:mutation_id_path, &valid_field_path?/1},
      {:sync_path, &host_local_path?/1},
      {:evidence_path, &host_local_path?/1},
      {:router, &valid_router?/1},
      {:ios_shell_root, &valid_ios_shell_root?/1}
    ]

    case Enum.find(validators, fn {key, validator} -> not validator.(Map.fetch!(config, key)) end) do
      nil ->
        :ok

      {key, _} ->
        error("PL-CONFIG-VALUE", Atom.to_string(key), "use the documented local proof-lane shape")
    end
  end

  defp valid_route_id?(value),
    do: is_binary(value) and String.match?(value, ~r/^route-[0-9a-f]{16}$/)

  defp valid_route_path?(value) do
    host_local_path?(value) and
      Regex.match?(~r/^\/(?:[a-z0-9_-]+|:id)(?:\/(?:[a-z0-9_-]+|:id))*$/, value)
  end

  defp simple_name?(value),
    do: is_binary(value) and String.match?(value, ~r/^[A-Za-z][A-Za-z0-9_-]*$/)

  defp valid_field_path?(value) do
    is_binary(value) and String.match?(value, ~r/^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$/)
  end

  defp host_local_path?(value) do
    is_binary(value) and String.starts_with?(value, "/") and
      not String.contains?(value, [
        "//",
        "..",
        "://",
        "?",
        "#",
        "@",
        "\"",
        "\\\\",
        "\0",
        "\r",
        "\n"
      ])
  end

  defp valid_router?(value), do: is_atom(value) and value not in [nil, true, false]

  defp valid_ios_shell_root?(value), do: match?({:ok, _}, derive_host_root(value))

  defp derive_host_root(value) do
    with true <- is_binary(value),
         true <- Path.type(value) == :absolute,
         true <- host_local_path?(value),
         true <- Path.expand(value) == value,
         components <- Path.split(value),
         ["native", "ios"] <- Enum.take(components, -2),
         host_components <- Enum.drop(components, -2),
         host_root <- Path.join(host_components),
         true <- host_root not in ["", "/"] do
      {:ok, host_root}
    else
      _ -> :error
    end
  end

  defp error(rule_id, key, remediation),
    do: {:error, %Error{rule_id: rule_id, key: key, remediation: remediation}}
end
