defmodule Crosswake.Policy.Schema do
  @moduledoc """
  NimbleOptions schema for Phase 1 Crosswake route policy declarations.
  """

  alias Crosswake.Transfer.Contracts

  @runtime_values [:live_view, :offline_island, :native_screen]
  @offline_values [:unavailable, :cached_read_only, :local_first]
  @security_values [:standard, :sensitive]
  @pack_kind_values [:content, :media]

  @schema NimbleOptions.new!([
            id: [
              type: {:custom, __MODULE__, :validate_identifier, []},
              required: true,
              type_spec: quote(do: String.t())
            ],
            runtime: [
              type: {:custom, __MODULE__, :validate_runtime, []},
              required: true,
              type_spec: quote(do: :live_view | :offline_island | :native_screen)
            ],
            offline: [
              type: {:in, @offline_values},
              default: :unavailable,
              type_spec: quote(do: :unavailable | :cached_read_only | :local_first)
            ],
            cache_contract: [
              type: {:custom, __MODULE__, :validate_identifier, []},
              type_spec: quote(do: String.t() | nil)
            ],
            island_contract: [
              type: {:custom, __MODULE__, :validate_identifier, []},
              type_spec: quote(do: String.t() | nil)
            ],
            capabilities: [
              type: {:list, {:custom, __MODULE__, :validate_identifier, []}},
              default: [],
              type_spec: quote(do: [String.t()])
            ],
            packs: [
              type: {:custom, __MODULE__, :validate_pack_requirements, []},
              default: [],
              type_spec: quote(do: [pack_requirement()])
            ],
            sync: [
              type: {:list, {:custom, __MODULE__, :validate_identifier, []}},
              default: [],
              type_spec: quote(do: [String.t()])
            ],
            transfers: [
              type: {:custom, __MODULE__, :validate_transfer_declarations, []},
              default: [],
              type_spec: quote(do: [Crosswake.Transfer.Contracts.declaration()])
            ],
            security: [
              type: {:in, @security_values},
              type_spec: quote(do: :standard | :sensitive)
            ]
          ])

  @type runtime :: :live_view | :offline_island | :native_screen
  @type offline :: :unavailable | :cached_read_only | :local_first
  @type security :: :standard | :sensitive
  @type pack_kind :: :content | :media
  @type pack_integrity :: %{algorithm: String.t(), digest: String.t()}
  @type pack_requirement :: %{
          id: String.t(),
          version: String.t(),
          kind: pack_kind(),
          integrity: pack_integrity() | nil
        }
  @type validated_options :: [
          id: String.t(),
          runtime: runtime(),
          offline: offline(),
          cache_contract: String.t() | nil,
          island_contract: String.t() | nil,
          capabilities: [String.t()],
          packs: [pack_requirement()],
          sync: [String.t()],
          transfers: [Contracts.declaration()],
          security: security()
        ]

  @spec schema() :: NimbleOptions.t()
  def schema, do: @schema

  @spec validate(keyword()) :: {:ok, validated_options()} | {:error, NimbleOptions.ValidationError.t()}
  def validate(options) when is_list(options) do
    NimbleOptions.validate(options, @schema)
  end

  @spec validate!(keyword()) :: validated_options()
  def validate!(options) when is_list(options) do
    NimbleOptions.validate!(options, @schema)
  end

  @spec validate_identifier(term()) :: {:ok, String.t()} | {:error, String.t()}
  def validate_identifier(value) when is_binary(value) and byte_size(value) > 0, do: {:ok, value}
  def validate_identifier(value) when is_atom(value), do: {:ok, Atom.to_string(value)}
  def validate_identifier(_value), do: {:error, "expected a non-empty string or atom"}

  @spec validate_runtime(term()) :: {:ok, runtime()} | {:error, String.t()}
  def validate_runtime(:adapter), do: {:error, "runtime :adapter is a reserved future extension point"}
  def validate_runtime(value) when value in @runtime_values, do: {:ok, value}

  def validate_runtime(value) do
    {:error, "expected one of #{inspect(@runtime_values)}, got: #{inspect(value)}"}
  end

  @spec validate_pack_requirements(term()) :: {:ok, [pack_requirement()]} | {:error, String.t()}
  def validate_pack_requirements(requirements) when is_list(requirements) do
    requirements
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {requirement, index}, {:ok, acc} ->
      case validate_pack_requirement(requirement) do
        {:ok, normalized} -> {:cont, {:ok, acc ++ [normalized]}}
        {:error, reason} -> {:halt, {:error, "invalid pack declaration at position #{index}: #{reason}"}}
      end
    end)
  end

  def validate_pack_requirements(_value), do: {:error, "expected a list of pack declarations"}

  @spec validate_transfer_declarations(term()) ::
          {:ok, [Contracts.declaration()]} | {:error, String.t()}
  def validate_transfer_declarations(declarations) when is_list(declarations) do
    declarations
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {declaration, index}, {:ok, acc} ->
      case Contracts.normalize_declaration(declaration) do
        {:ok, normalized} -> {:cont, {:ok, acc ++ [normalized]}}
        {:error, reason} -> {:halt, {:error, "invalid transfer declaration at position #{index}: #{reason}"}}
      end
    end)
  end

  def validate_transfer_declarations(_value),
    do: {:error, "expected a list of transfer declarations"}

  defp validate_pack_requirement(requirement) when is_list(requirement) do
    requirement
    |> Enum.into(%{})
    |> validate_pack_requirement()
  end

  defp validate_pack_requirement(requirement) when is_map(requirement) do
    with {:ok, id} <- validate_identifier(Map.get(requirement, :id, Map.get(requirement, "id"))),
         {:ok, version} <- validate_pack_version(Map.get(requirement, :version, Map.get(requirement, "version"))),
         {:ok, kind} <- validate_pack_kind(Map.get(requirement, :kind, Map.get(requirement, "kind"))),
         {:ok, integrity} <-
           validate_pack_integrity(Map.get(requirement, :integrity, Map.get(requirement, "integrity"))) do
      {:ok, %{id: id, version: version, kind: kind, integrity: integrity}}
    end
  end

  defp validate_pack_requirement(_value), do: {:error, "expected a keyword list or map"}

  defp validate_pack_version(value) when is_binary(value) and byte_size(value) > 0, do: {:ok, value}
  defp validate_pack_version(_value), do: {:error, "pack version is required and must be a non-empty string"}

  defp validate_pack_kind(value) when value in @pack_kind_values, do: {:ok, value}

  defp validate_pack_kind(value) do
    {:error, "expected pack kind to be one of #{inspect(@pack_kind_values)}, got: #{inspect(value)}"}
  end

  defp validate_pack_integrity(nil), do: {:ok, nil}

  defp validate_pack_integrity(integrity) when is_list(integrity) do
    integrity
    |> Enum.into(%{})
    |> validate_pack_integrity()
  end

  defp validate_pack_integrity(integrity) when is_map(integrity) do
    with {:ok, algorithm} <-
           validate_identifier(Map.get(integrity, :algorithm, Map.get(integrity, "algorithm"))),
         {:ok, digest} <-
           validate_identifier(Map.get(integrity, :digest, Map.get(integrity, "digest"))) do
      {:ok, %{algorithm: algorithm, digest: digest}}
    end
  end

  defp validate_pack_integrity(_value),
    do: {:error, "pack integrity must be a map or keyword list with algorithm and digest"}
end
