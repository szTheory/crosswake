defmodule Crosswake.Companions.Sigra.Telemetry do
  @moduledoc """
  Stable telemetry contract for Sigra auth diagnostics.

  Sigra telemetry is diagnostic evidence only. Session authority, replay,
  revocation, expiry, audit, and route authority remain owned by backend
  session lanes plus host-owned handoff, step-up, and auth-return records.
  """

  @event_names [
    [:crosswake, :auth, :session, :evaluate, :start],
    [:crosswake, :auth, :session, :evaluate, :stop],
    [:crosswake, :auth, :session, :evaluate, :exception],
    [:crosswake, :auth, :denial],
    [:crosswake, :auth, :handoff, :issue],
    [:crosswake, :auth, :handoff, :redeem],
    [:crosswake, :auth, :handoff, :deny],
    [:crosswake, :auth, :step_up, :issue],
    [:crosswake, :auth, :step_up, :challenge],
    [:crosswake, :auth, :step_up, :consume],
    [:crosswake, :auth, :step_up, :deny],
    [:crosswake, :auth, :return, :validate],
    [:crosswake, :auth, :return, :consume],
    [:crosswake, :auth, :return, :deny]
  ]

  @metadata_keys [
    :route_id,
    :flow,
    :return_kind,
    :transport,
    :outcome,
    :denial_code,
    :shell_reason,
    :authority_state,
    :auth_posture,
    :required_assurance_level,
    :current_assurance_level,
    :freshness_bucket,
    :lifecycle_state,
    :binding_result,
    :link_verification,
    :validation_posture,
    :proof_class,
    :correlation_id
  ]

  @forbidden_metadata_keys [
    :access_token,
    :actor_id,
    :authorization_code,
    :credential_id,
    :device_id,
    :email,
    :id_token,
    :ip,
    :nonce,
    :org_id,
    :passkey_credential_id,
    :pkce_verifier,
    :provider_payload,
    :raw_return_to,
    :refresh_token,
    :return_to,
    :session_ref,
    :subject_ref,
    :user_agent
  ]

  @flows [:session, :denial, :handoff, :step_up, :auth_return]
  @return_kinds [:oauth, :passkey, :native_auth]
  @outcomes [:allow, :deny, :challenge, :consume, :issue, :redeem, :validate]
  @freshness_buckets [:fresh, :stale, :expired, :unknown]
  @proof_classes [:hermetic, :advisory, :not_applicable]

  defmodule Event do
    @moduledoc false

    @enforce_keys [:name]
    defstruct [
      :name,
      :route_id,
      :flow,
      :return_kind,
      :transport,
      :outcome,
      :denial_code,
      :shell_reason,
      :authority_state,
      :auth_posture,
      :required_assurance_level,
      :current_assurance_level,
      :freshness_bucket,
      :lifecycle_state,
      :binding_result,
      :link_verification,
      :validation_posture,
      :proof_class,
      :correlation_id
    ]

    @type t :: %__MODULE__{name: [atom()]}
  end

  @spec event_names() :: [[atom()]]
  def event_names, do: @event_names

  @spec metadata_keys() :: [atom()]
  def metadata_keys, do: @metadata_keys

  @spec forbidden_metadata_keys() :: [atom()]
  def forbidden_metadata_keys, do: @forbidden_metadata_keys

  @spec flows() :: [atom()]
  def flows, do: @flows

  @spec return_kinds() :: [atom()]
  def return_kinds, do: @return_kinds

  @spec outcomes() :: [atom()]
  def outcomes, do: @outcomes

  @spec freshness_buckets() :: [atom()]
  def freshness_buckets, do: @freshness_buckets

  @spec proof_classes() :: [atom()]
  def proof_classes, do: @proof_classes

  @spec valid_event_name?(term()) :: boolean()
  def valid_event_name?(name), do: name in @event_names

  @spec new_event(keyword()) :: Event.t()
  def new_event(attrs) when is_list(attrs) do
    name = Keyword.fetch!(attrs, :name)

    unless valid_event_name?(name) do
      raise ArgumentError, "unknown Sigra auth telemetry event name: #{inspect(name)}"
    end

    attrs
    |> Keyword.take([:name | @metadata_keys])
    |> Map.new()
    |> then(&struct!(Event, &1))
  end

  @spec metadata(Event.t() | map() | keyword()) :: map()
  def metadata(%Event{} = event), do: event |> Map.from_struct() |> Map.delete(:name) |> metadata()
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
