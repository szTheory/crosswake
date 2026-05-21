defmodule Crosswake.Bridge.Commands.NotificationToken do
  @moduledoc """
  Typed payload structs for the prompt-free notifications.token.get bridge command.
  """

  alias Crosswake.Bridge.Commands.PermissionsStatus

  @supported_providers ["apns", "fcm"]

  defmodule Request do
    @moduledoc false

    defstruct []

    @type t :: %__MODULE__{}
  end

  defmodule Response do
    @moduledoc false

    @enforce_keys [:provider, :token, :notification_status]
    defstruct [:provider, :token, :notification_status, detail: %{}]

    @type provider :: String.t()
    @type status :: PermissionsStatus.Response.status()

    @type t :: %__MODULE__{
            provider: provider(),
            token: String.t(),
            notification_status: status(),
            detail: map()
          }
  end

  @spec supported_providers() :: [String.t()]
  def supported_providers, do: @supported_providers

  @spec supported_statuses() :: [Response.status()]
  def supported_statuses, do: PermissionsStatus.supported_statuses()

  @spec new_request(keyword()) :: {:ok, Request.t()} | {:error, :unsupported_option}
  def new_request(attrs) when is_list(attrs) do
    case Keyword.keys(attrs) do
      [] -> {:ok, %Request{}}
      _unsupported -> {:error, :unsupported_option}
    end
  end

  @spec new_response(keyword()) :: Response.t()
  def new_response(attrs) when is_list(attrs) do
    provider = attrs |> Keyword.fetch!(:provider) |> normalize_provider()
    token = Keyword.fetch!(attrs, :token)
    notification_status = Keyword.fetch!(attrs, :notification_status)

    unless provider in @supported_providers do
      raise ArgumentError,
            "unsupported notifications.token.get provider #{inspect(provider)}; expected one of #{inspect(@supported_providers)}"
    end

    unless is_binary(token) and byte_size(token) > 0 do
      raise ArgumentError, "notifications.token.get token must be a non-empty binary"
    end

    unless notification_status in supported_statuses() do
      raise ArgumentError,
            "unsupported notifications.token.get status #{inspect(notification_status)}; expected one of #{inspect(supported_statuses())}"
    end

    %Response{
      provider: provider,
      token: token,
      notification_status: notification_status,
      detail: Keyword.get(attrs, :detail, %{})
    }
  end

  defp normalize_provider(provider) when is_atom(provider), do: Atom.to_string(provider)
  defp normalize_provider(provider) when is_binary(provider), do: provider
end
