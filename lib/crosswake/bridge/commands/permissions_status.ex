defmodule Crosswake.Bridge.Commands.PermissionsStatus do
  @moduledoc """
  Typed payload structs for the read-only permissions.status bridge command.
  """

  @supported_aliases ["notifications"]
  @supported_statuses [:granted, :denied, :restricted]

  defmodule Request do
    @moduledoc false

    @enforce_keys [:alias]
    defstruct [:alias]

    @type t :: %__MODULE__{
            alias: String.t()
          }
  end

  defmodule Response do
    @moduledoc false

    @enforce_keys [:alias, :status]
    defstruct [:alias, :status, detail: %{}]

    @type status :: :granted | :denied | :restricted

    @type t :: %__MODULE__{
            alias: String.t(),
            status: status(),
            detail: map()
          }
  end

  @spec supported_aliases() :: [String.t()]
  def supported_aliases, do: @supported_aliases

  @spec supported_statuses() :: [Response.status()]
  def supported_statuses, do: @supported_statuses

  @spec supported_alias?(String.t()) :: boolean()
  def supported_alias?(permission_alias) when is_binary(permission_alias),
    do: permission_alias in @supported_aliases

  @spec new_request(keyword()) :: {:ok, Request.t()} | {:error, :unsupported_alias}
  def new_request(attrs) when is_list(attrs) do
    permission_alias = attrs |> Keyword.fetch!(:alias) |> normalize_alias()

    if supported_alias?(permission_alias) do
      {:ok, %Request{alias: permission_alias}}
    else
      {:error, :unsupported_alias}
    end
  end

  @spec new_response(keyword()) :: Response.t()
  def new_response(attrs) when is_list(attrs) do
    permission_alias = attrs |> Keyword.fetch!(:alias) |> normalize_alias()
    status = Keyword.fetch!(attrs, :status)

    unless supported_alias?(permission_alias) do
      raise ArgumentError, "unsupported permissions.status alias #{inspect(permission_alias)}"
    end

    unless status in @supported_statuses do
      raise ArgumentError,
            "unsupported permissions.status status #{inspect(status)}; expected one of #{inspect(@supported_statuses)}"
    end

    %Response{
      alias: permission_alias,
      status: status,
      detail: Keyword.get(attrs, :detail, %{})
    }
  end

  defp normalize_alias(permission_alias) when is_atom(permission_alias), do: Atom.to_string(permission_alias)
  defp normalize_alias(permission_alias) when is_binary(permission_alias), do: permission_alias
end
