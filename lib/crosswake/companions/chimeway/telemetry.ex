defmodule Crosswake.Companions.Chimeway.Telemetry do
  @moduledoc """
  Stable telemetry contract for Chimeway notification diagnostics.

  Chimeway telemetry is diagnostic evidence only. It is not auth, session,
  route, delivery, or notification-open authority, and it never carries raw
  token material or provider payload bodies.
  """

  @event_names [
    [:crosswake, :notification, :token, :observed],
    [:crosswake, :notification, :token, :bound],
    [:crosswake, :notification, :token, :rotated],
    [:crosswake, :notification, :token, :revoked],
    [:crosswake, :notification, :token, :stale],
    [:crosswake, :notification, :token, :invalidated],
    [:crosswake, :notification, :provider, :feedback],
    [:crosswake, :notification, :open, :received],
    [:crosswake, :notification, :open, :resolved],
    [:crosswake, :notification, :open, :denied]
  ]

  @metadata_keys [
    :provider,
    :platform,
    :environment,
    :state,
    :reason,
    :feedback_event,
    :notification_status,
    :app_identity_posture,
    :subject_scope,
    :proof_class,
    :correlation_id,
    :route_id,
    :action_ref,
    :denial_code
  ]

  @forbidden_metadata_keys [
    :token,
    :raw_token,
    :device_token,
    :registration_token,
    :apns_token,
    :fcm_token,
    :provider_payload,
    :raw_payload,
    :notification_title,
    :notification_body,
    :route_params,
    :actor_id,
    :subject_ref,
    :session_ref,
    :device_id,
    :ip,
    :user_agent,
    :email,
    :provider_response_body
  ]

  defmodule Event do
    @moduledoc false

    @enforce_keys [:name]
    defstruct [
      :name,
      :provider,
      :platform,
      :environment,
      :state,
      :reason,
      :feedback_event,
      :notification_status,
      :app_identity_posture,
      :subject_scope,
      :proof_class,
      :correlation_id,
      :route_id,
      :action_ref,
      :denial_code
    ]

    @type t :: %__MODULE__{name: [atom()]}
  end

  @spec event_names() :: [[atom()]]
  def event_names, do: @event_names

  @spec metadata_keys() :: [atom()]
  def metadata_keys, do: @metadata_keys

  @spec forbidden_metadata_keys() :: [atom()]
  def forbidden_metadata_keys, do: @forbidden_metadata_keys

  @spec valid_event_name?(term()) :: boolean()
  def valid_event_name?(name), do: name in @event_names

  @spec new_event(keyword()) :: Event.t()
  def new_event(attrs) when is_list(attrs) do
    name = Keyword.fetch!(attrs, :name)

    unless valid_event_name?(name) do
      raise ArgumentError, "unknown Chimeway notification telemetry event name: #{inspect(name)}"
    end

    attrs
    |> Keyword.take([:name | @metadata_keys])
    |> Map.new()
    |> then(&struct!(Event, &1))
  end

  @spec metadata(Event.t() | map() | keyword()) :: map()
  def metadata(%Event{} = event),
    do: event |> Map.from_struct() |> Map.delete(:name) |> metadata()

  def metadata(attrs) when is_list(attrs), do: attrs |> Map.new() |> metadata()

  def metadata(attrs) when is_map(attrs) do
    attrs
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      key = normalize_key(key)

      cond do
        key in @forbidden_metadata_keys ->
          acc

        key in @metadata_keys and safe_value?(value) ->
          Map.put(acc, key, normalize_value(value))

        true ->
          acc
      end
    end)
  end

  @spec to_map(Event.t()) :: map()
  def to_map(%Event{name: name} = event) do
    event
    |> metadata()
    |> Map.put(:name, Enum.map_join(name, ".", &Atom.to_string/1))
    |> Enum.map(fn {key, value} -> {Atom.to_string(key), value} end)
    |> Map.new()
  end

  @spec execute([atom()], map(), map() | keyword()) :: :ok
  def execute(name, measurements \\ %{}, metadata \\ %{}) do
    :telemetry.execute(name, measurements, metadata(metadata))
  end

  defp normalize_key(key) when is_atom(key), do: key

  defp normalize_key(key) when is_binary(key) do
    if key in Enum.map(@metadata_keys ++ @forbidden_metadata_keys, &Atom.to_string/1) do
      String.to_existing_atom(key)
    else
      key
    end
  end

  defp normalize_key(key), do: key

  defp safe_value?(nil), do: false
  defp safe_value?(value) when is_atom(value), do: true
  defp safe_value?(value) when is_integer(value) and value >= 0, do: true
  defp safe_value?(value) when is_binary(value), do: String.length(value) <= 128
  defp safe_value?(_value), do: false

  defp normalize_value(value) when is_atom(value), do: value
  defp normalize_value(value), do: value
end
