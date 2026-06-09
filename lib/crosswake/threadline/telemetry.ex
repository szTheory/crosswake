defmodule Crosswake.Threadline.Telemetry do
  @moduledoc """
  Telemetry contract for Crosswake Threadline correlation diagnostics.

  This module defines the low-cardinality `:telemetry` event-name allowlist
  and metadata allowlist guard for request-span events emitted by the
  `Crosswake.Plug.Threadline` Plug (Phase 92).

  **Diagnostic-only.** Threadline telemetry is PII-free correlation evidence:
  it propagates a session-spanning `thread_id` above the per-command
  `correlation_id` for operator observability. It is NOT an APM replacement,
  NOT a distributed tracing framework, and NOT a generic event bus. It coexists
  with any host-side telemetry or tracing pipeline without interfering with them.

  All metadata passes through `metadata/1` before emission, which:
    - Keeps only the four PROP-02 allowlisted keys (`@metadata_keys`)
    - Drops any key in `@forbidden_metadata_keys` (PII denylist) silently
    - Drops allowlisted keys whose values are unsafe (nil, oversized binaries, etc.)
    - Drops all other unknown keys

  Zero new dependencies — only `:telemetry`, already a project dependency.
  """

  # PROP-02 fixed allowlist — exactly four keys; :source carries thread provenance
  # at the boundary (value domain: :inbound | :minted) and is set by the Phase 92
  # Plug emitter. It earns an allowlist slot as the one key not reconstructable from
  # the others (D-09, D-10). The value itself is NOT set by this module.
  @metadata_keys [:thread_id, :correlation_id, :route_id, :source]

  # Three request-span event names only (D-07). Bridge and activation events are NOT
  # pre-declared here — that would widen scope beyond PROP-02 (D-08).
  @event_names [
    [:crosswake, :threadline, :request, :start],
    [:crosswake, :threadline, :request, :stop],
    [:crosswake, :threadline, :request, :exception]
  ]

  # Sigra's verified 19-key PII denylist plus :actor_ref (RESEARCH A1 — Phase 94's
  # PII-adjacent field must never appear in telemetry, even though :actor_ref is not
  # in Sigra's list). Total: 20 forbidden keys.
  @forbidden_metadata_keys [
    :access_token,
    :actor_id,
    :actor_ref,
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

  defmodule Event do
    @moduledoc false

    @enforce_keys [:name]
    defstruct [:name, :thread_id, :correlation_id, :route_id, :source]

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
      raise ArgumentError, "unknown Threadline telemetry event name: #{inspect(name)}"
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
