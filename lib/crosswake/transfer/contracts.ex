defmodule Crosswake.Transfer.Contracts do
  @moduledoc """
  Typed, versioned route-local transfer declarations for upload, download, import,
  and export seams.
  """

  @protocol "crosswake.transfer"
  @version "1.0.0"
  @intents [:upload, :download, :import, :export]
  @states [:queued, :preparing, :transferring, :awaiting_network, :verifying, :complete, :failed, :canceled]
  @sources [:native_picker, :native_capture, :app_sandbox]
  @destinations [:app_sandbox, :user_visible_files, :phoenix_origin]
  @verifications [:required, :none]
  @inbound_intents [:upload, :import]
  @outbound_intents [:download, :export]
  @picker_intents [:upload, :import]

  defmodule Declaration do
    @moduledoc false

    @enforce_keys [
      :protocol,
      :version,
      :id,
      :intent,
      :direction,
      :verification
    ]
    defstruct [
      :protocol,
      :version,
      :id,
      :intent,
      :direction,
      :source,
      :destination,
      :verification,
      media_types: []
    ]

    @type t :: %__MODULE__{
            protocol: String.t(),
            version: String.t(),
            id: String.t(),
            intent: Crosswake.Transfer.Contracts.intent(),
            direction: Crosswake.Transfer.Contracts.direction(),
            source: Crosswake.Transfer.Contracts.source() | nil,
            destination: Crosswake.Transfer.Contracts.destination() | nil,
            verification: Crosswake.Transfer.Contracts.verification(),
            media_types: [String.t()]
          }
  end

  defmodule Result do
    @moduledoc false

    @enforce_keys [:protocol, :version, :route_id, :transfer_id, :state]
    defstruct [
      :protocol,
      :version,
      :route_id,
      :transfer_id,
      :state,
      :detail,
      metadata: %{}
    ]

    @type t :: %__MODULE__{
            protocol: String.t(),
            version: String.t(),
            route_id: String.t(),
            transfer_id: String.t(),
            state: Crosswake.Transfer.Contracts.state(),
            detail: String.t() | nil,
            metadata: map()
          }
  end

  @type intent :: :upload | :download | :import | :export
  @type direction :: :inbound | :outbound
  @type source :: :native_picker | :native_capture | :app_sandbox
  @type destination :: :app_sandbox | :user_visible_files | :phoenix_origin
  @type verification :: :required | :none
  @type state ::
          :queued
          | :preparing
          | :transferring
          | :awaiting_network
          | :verifying
          | :complete
          | :failed
          | :canceled
  @type declaration :: Declaration.t()

  @spec protocol() :: String.t()
  def protocol, do: @protocol

  @spec version() :: String.t()
  def version, do: @version

  @spec transfer_states() :: [state()]
  def transfer_states, do: @states

  @spec intents() :: [intent()]
  def intents, do: @intents

  @spec new_declaration(keyword()) :: declaration()
  def new_declaration(attrs) when is_list(attrs) do
    struct!(Declaration, %{
      protocol: Keyword.get(attrs, :protocol, @protocol),
      version: Keyword.get(attrs, :version, @version),
      id: Keyword.fetch!(attrs, :id),
      intent: Keyword.fetch!(attrs, :intent),
      direction:
        attrs
        |> Keyword.fetch!(:intent)
        |> direction_for_intent(),
      source: Keyword.get(attrs, :source),
      destination: Keyword.get(attrs, :destination),
      verification: Keyword.fetch!(attrs, :verification),
      media_types: Keyword.get(attrs, :media_types, [])
    })
  end

  @spec normalize_declaration(term()) :: {:ok, declaration()} | {:error, String.t()}
  def normalize_declaration(declaration) when is_list(declaration) do
    declaration
    |> Enum.into(%{})
    |> normalize_declaration()
  end

  def normalize_declaration(%{} = declaration) do
    with {:ok, id} <- validate_identifier(Map.get(declaration, :id, Map.get(declaration, "id")), "id"),
         {:ok, intent} <- validate_intent(Map.get(declaration, :intent, Map.get(declaration, "intent"))),
         {:ok, verification} <-
           validate_verification(Map.get(declaration, :verification, Map.get(declaration, "verification"))),
         {:ok, source} <- validate_source(intent, Map.get(declaration, :source, Map.get(declaration, "source"))),
         {:ok, destination} <-
           validate_destination(intent, Map.get(declaration, :destination, Map.get(declaration, "destination"))),
         {:ok, media_types} <-
           validate_media_types(Map.get(declaration, :media_types, Map.get(declaration, "media_types"))) do
      {:ok,
       new_declaration(
         id: id,
         intent: intent,
         source: source,
         destination: destination,
         verification: verification,
         media_types: media_types
       )}
    end
  end

  def normalize_declaration(_value), do: {:error, "expected a keyword list or map"}

  @spec new_result(keyword()) :: Result.t()
  def new_result(attrs) when is_list(attrs) do
    struct!(Result, %{
      protocol: Keyword.get(attrs, :protocol, @protocol),
      version: Keyword.get(attrs, :version, @version),
      route_id: Keyword.fetch!(attrs, :route_id),
      transfer_id: Keyword.fetch!(attrs, :transfer_id),
      state: Keyword.fetch!(attrs, :state),
      detail: Keyword.get(attrs, :detail),
      metadata: Keyword.get(attrs, :metadata, %{})
    })
  end

  @spec validate_picker_declaration(declaration()) ::
          :ok | {:error, :invalid_picker_direction | :invalid_picker_intent | :invalid_picker_source}
  def validate_picker_declaration(%Declaration{} = declaration) do
    cond do
      declaration.intent not in @picker_intents ->
        {:error, :invalid_picker_intent}

      declaration.direction != :inbound ->
        {:error, :invalid_picker_direction}

      declaration.source != :native_picker ->
        {:error, :invalid_picker_source}

      true ->
        :ok
    end
  end

  defp direction_for_intent(intent) when intent in @inbound_intents, do: :inbound
  defp direction_for_intent(intent) when intent in @outbound_intents, do: :outbound

  defp validate_identifier(value, _field) when is_binary(value) and byte_size(value) > 0, do: {:ok, value}
  defp validate_identifier(value, _field) when is_atom(value), do: {:ok, Atom.to_string(value)}
  defp validate_identifier(_value, field), do: {:error, "#{field} is required and must be a non-empty string or atom"}

  defp validate_intent(value) when value in @intents, do: {:ok, value}
  defp validate_intent(value), do: {:error, "intent must be one of #{inspect(@intents)}, got: #{inspect(value)}"}

  defp validate_verification(value) when value in @verifications, do: {:ok, value}

  defp validate_verification(value) do
    {:error, "verification must be one of #{inspect(@verifications)}, got: #{inspect(value)}"}
  end

  defp validate_source(intent, nil) when intent in @inbound_intents,
    do: {:error, "source is required for #{intent} transfers"}

  defp validate_source(intent, value) when intent in @outbound_intents and not is_nil(value),
    do: {:error, "#{intent} transfers must not declare source"}

  defp validate_source(_intent, nil), do: {:ok, nil}
  defp validate_source(_intent, value) when value in @sources, do: {:ok, value}
  defp validate_source(_intent, value), do: {:error, "source must be one of #{inspect(@sources)}, got: #{inspect(value)}"}

  defp validate_destination(intent, nil) when intent in @outbound_intents,
    do: {:error, "destination is required for #{intent} transfers"}

  defp validate_destination(intent, value) when intent in @inbound_intents and not is_nil(value),
    do: {:error, "#{intent} transfers must not declare destination"}

  defp validate_destination(_intent, nil), do: {:ok, nil}

  defp validate_destination(_intent, value) when value in @destinations,
    do: {:ok, value}

  defp validate_destination(_intent, value) do
    {:error, "destination must be one of #{inspect(@destinations)}, got: #{inspect(value)}"}
  end

  defp validate_media_types(nil), do: {:ok, []}

  defp validate_media_types(media_types) when is_list(media_types) do
    media_types
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {media_type, index}, {:ok, acc} ->
      case validate_identifier(media_type, "media_types[#{index}]") do
        {:ok, normalized} -> {:cont, {:ok, acc ++ [normalized]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp validate_media_types(_value), do: {:error, "media_types must be a list of strings"}
end
