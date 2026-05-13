defmodule Crosswake.Policy.Schema do
  @moduledoc """
  NimbleOptions schema for Phase 1 Crosswake route policy declarations.
  """

  @runtime_values [:live_view, :offline_island, :native_screen]
  @offline_values [:unavailable, :cached_read_only, :local_first]
  @security_values [:standard, :sensitive]

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
            capabilities: [
              type: {:list, {:custom, __MODULE__, :validate_identifier, []}},
              default: [],
              type_spec: quote(do: [String.t()])
            ],
            packs: [
              type: {:list, {:custom, __MODULE__, :validate_identifier, []}},
              default: [],
              type_spec: quote(do: [String.t()])
            ],
            sync: [
              type: {:list, {:custom, __MODULE__, :validate_identifier, []}},
              default: [],
              type_spec: quote(do: [String.t()])
            ],
            security: [
              type: {:in, @security_values},
              type_spec: quote(do: :standard | :sensitive)
            ]
          ])

  @type runtime :: :live_view | :offline_island | :native_screen
  @type offline :: :unavailable | :cached_read_only | :local_first
  @type security :: :standard | :sensitive
  @type validated_options :: [
          id: String.t(),
          runtime: runtime(),
          offline: offline(),
          capabilities: [String.t()],
          packs: [String.t()],
          sync: [String.t()],
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
end
