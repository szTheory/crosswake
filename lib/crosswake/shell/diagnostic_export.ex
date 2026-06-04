defmodule Crosswake.Shell.DiagnosticExport do
  @moduledoc """
  Behaviour-only transport seam for the diagnostic export contract.

  `Crosswake.Shell.DiagnosticExport` defines a fire-and-forget POST contract
  for shipping typed, versioned diagnostic envelopes to a host-owned endpoint.

  ## Transport semantics (documented — not implemented here)

  - Method: POST
  - Content-Type: application/json
  - Endpoint: host-owned and host-configured (Crosswake does not own it)
  - No response awaited (fire-and-forget)
  - No Elixir HTTP-sending code ships in this module (D-01/D-03)

  The actual HTTP sender is implemented by the native shell (iOS MetricKit /
  Android `ApplicationExitInfo`) in Phase 67. This module ships the typed
  envelope contract and the `@callback export/1` the native shell implements.

  ## Allowlist-by-construction redaction (D-11..D-14)

  The typed `Envelope` and `NativeDiagnostic` structs are the allowlist:
  they cannot represent forbidden data (raw tokens, payloads, PII). The
  `sanitize/1` function is fail-closed: it rejects any input that contains
  a forbidden key, an unexpected key, or an out-of-enum value.

  ## Phase 65 proof anchors

  - `behaviour_info(:callbacks)` must include `{:export, 1}`
  - `forbidden_keys/0` ⟂ `allowed_keys/0` (disjoint; 19 forbidden keys)
  - `sanitize/1` returns `{:error, :redaction_failed}` on invalid input
  - No `diagnostics.*` added to `Bridge.Contract.commands/0`
  - No HTTP client dependency in the published lib
  """

  @protocol "crosswake.diagnostic"
  @schema_version "1"

  # ---------------------------------------------------------------------------
  # Closed-enum module attributes
  # ---------------------------------------------------------------------------

  @layers [:native, :web, :bridge]
  @platforms [:ios, :android, :web]
  @kinds [:crash, :termination, :hang, :cpu, :bridge_fault, :web_fault]
  @sources [:metrickit, :app_exit_info]
  @exit_reasons [
    :crash,
    :anr,
    :low_memory,
    :user_requested,
    :hang,
    :cpu_resource_limit,
    :abnormal_exit,
    :other
  ]

  # ---------------------------------------------------------------------------
  # Canonical 19-key forbidden set — verbatim from Chimeway.Telemetry (D-15)
  # ---------------------------------------------------------------------------

  @forbidden_keys [
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

  # Allowed keys = all declared envelope fields + native_diagnostic sub-struct fields.
  # This is the explicit allowlist that sanitize/1 validates against.
  @envelope_fields [
    :schema_version,
    :layer,
    :platform,
    :native_runtime_version,
    :kind,
    :correlation_id,
    :observed_at,
    :native_diagnostic
  ]

  @native_diagnostic_fields [
    :source,
    :exit_reason
  ]

  @allowed_keys @envelope_fields ++ @native_diagnostic_fields

  # ---------------------------------------------------------------------------
  # Inner struct: NativeDiagnostic
  # ---------------------------------------------------------------------------

  defmodule NativeDiagnostic do
    @moduledoc """
    Typed diagnostic codes for native-layer (iOS/Android) diagnostic events.

    Models iOS MetricKit and Android `ApplicationExitInfo` diagnostics via
    closed typed codes. No `raw_payload`, no open map field (D-09/D-13).
    """

    @enforce_keys [:source, :exit_reason]
    defstruct [:source, :exit_reason]

    @type source :: :metrickit | :app_exit_info

    @type exit_reason ::
            :crash
            | :anr
            | :low_memory
            | :user_requested
            | :hang
            | :cpu_resource_limit
            | :abnormal_exit
            | :other

    @type t :: %__MODULE__{
            source: source(),
            exit_reason: exit_reason()
          }
  end

  # ---------------------------------------------------------------------------
  # Inner struct: Envelope
  # ---------------------------------------------------------------------------

  defmodule Envelope do
    @moduledoc """
    Typed, versioned diagnostic envelope with layer attribution (D-06).

    All 7 fields are `@enforce_keys`. The optional `native_diagnostic` field
    holds a `%NativeDiagnostic{}` for `:native`-layer envelopes; nil otherwise.
    """

    @enforce_keys [
      :schema_version,
      :layer,
      :platform,
      :native_runtime_version,
      :kind,
      :correlation_id,
      :observed_at
    ]
    defstruct [
      :schema_version,
      :layer,
      :platform,
      :native_runtime_version,
      :kind,
      :correlation_id,
      :observed_at,
      native_diagnostic: nil
    ]

    @type layer :: :native | :web | :bridge
    @type platform :: :ios | :android | :web

    @type kind ::
            :crash
            | :termination
            | :hang
            | :cpu
            | :bridge_fault
            | :web_fault

    @type t :: %__MODULE__{
            schema_version: String.t(),
            layer: layer(),
            platform: platform(),
            native_runtime_version: String.t(),
            kind: kind(),
            correlation_id: String.t(),
            observed_at: String.t(),
            native_diagnostic:
              Crosswake.Shell.DiagnosticExport.NativeDiagnostic.t() | nil
          }
  end

  # ---------------------------------------------------------------------------
  # Behaviour callback (D-01/D-02)
  # ---------------------------------------------------------------------------

  @doc """
  Export a typed diagnostic envelope to the host-owned endpoint.

  This is a fire-and-forget POST contract. No response is awaited.
  The host/native shell implements this callback; Crosswake ships no
  Elixir HTTP-sending code.
  """
  @callback export(Envelope.t()) :: :ok | {:error, term()}

  # ---------------------------------------------------------------------------
  # Public accessors (closed-enum lists)
  # ---------------------------------------------------------------------------

  @doc "Returns the canonical protocol identifier."
  @spec protocol() :: String.t()
  def protocol, do: @protocol

  @doc "Returns the schema version string."
  @spec schema_version() :: String.t()
  def schema_version, do: @schema_version

  @doc "Returns the closed layer enum: [:native, :web, :bridge]."
  @spec layers() :: [atom()]
  def layers, do: @layers

  @doc "Returns the closed platform enum: [:ios, :android, :web]."
  @spec platforms() :: [atom()]
  def platforms, do: @platforms

  @doc "Returns the closed kind enum."
  @spec kinds() :: [atom()]
  def kinds, do: @kinds

  @doc "Returns the closed source enum: [:metrickit, :app_exit_info]."
  @spec sources() :: [atom()]
  def sources, do: @sources

  @doc "Returns the closed exit_reason enum."
  @spec exit_reasons() :: [atom()]
  def exit_reasons, do: @exit_reasons

  @doc "Returns the canonical 19-key forbidden set (verbatim from Chimeway.Telemetry)."
  @spec forbidden_keys() :: [atom()]
  def forbidden_keys, do: @forbidden_keys

  @doc """
  Returns the declared allowed key set (envelope fields + native_diagnostic fields).
  Shares no key with `forbidden_keys/0`.
  """
  @spec allowed_keys() :: [atom()]
  def allowed_keys, do: @allowed_keys

  # ---------------------------------------------------------------------------
  # Constructors
  # ---------------------------------------------------------------------------

  @doc """
  Constructs an `Envelope` from a map or keyword list.

  Returns `{:ok, %Envelope{}}` on success, `{:error, keyword()}` on failure.
  """
  @spec new_envelope(map() | keyword()) :: {:ok, Envelope.t()} | {:error, keyword()}
  def new_envelope(attrs) do
    attrs
    |> normalize_attrs()
    |> build_envelope()
  end

  @doc """
  Constructs an `Envelope`, raising on failure. Used for fixture generation.
  """
  @spec new_envelope!(map() | keyword()) :: Envelope.t()
  def new_envelope!(attrs) do
    case new_envelope(attrs) do
      {:ok, envelope} -> envelope
      {:error, errors} -> raise ArgumentError, "invalid DiagnosticExport envelope: #{inspect(errors)}"
    end
  end

  @doc """
  Constructs a `NativeDiagnostic` from a map or keyword list.
  """
  @spec new_native_diagnostic(map() | keyword()) ::
          {:ok, NativeDiagnostic.t()} | {:error, keyword()}
  def new_native_diagnostic(attrs) do
    attrs
    |> normalize_attrs()
    |> build_native_diagnostic()
  end

  # ---------------------------------------------------------------------------
  # sanitize/1 — fail-closed (D-14)
  # ---------------------------------------------------------------------------

  @doc """
  Maps an untrusted input map to a typed `Envelope.t()` or rejects it.

  Fail-closed (D-14): returns `{:error, :redaction_failed}` when:
  - input is not a map
  - any key normalizes to a key in `forbidden_keys/0`
  - any key is outside `allowed_keys/0` (unexpected key)
  - any enum field has an out-of-range value
  - any required field is missing or invalid

  Does NOT drop-and-continue. A rejected payload is better than a silently
  truncated partial record.
  """
  @spec sanitize(map()) :: {:ok, Envelope.t()} | {:error, :redaction_failed}
  def sanitize(input) when is_map(input) do
    normalized_keys =
      input
      |> Map.keys()
      |> Enum.map(&normalize_key/1)

    cond do
      Enum.any?(normalized_keys, &(&1 in @forbidden_keys)) ->
        {:error, :redaction_failed}

      Enum.any?(normalized_keys, &(&1 not in @envelope_fields)) ->
        {:error, :redaction_failed}

      true ->
        case new_envelope(input) do
          {:ok, envelope} -> {:ok, envelope}
          {:error, _} -> {:error, :redaction_failed}
        end
    end
  end

  def sanitize(_input), do: {:error, :redaction_failed}

  # ---------------------------------------------------------------------------
  # to_map/1 — manual stringify, nil-reject, no @derive Jason.Encoder (D-05)
  # ---------------------------------------------------------------------------

  @doc """
  Converts an `Envelope` or `NativeDiagnostic` struct to a string-keyed map.

  Stringifies all atom values (`:native` → `"native"`), rejects nil values
  and empty maps, and recurses into nested `%NativeDiagnostic{}` structs.
  No `@derive Jason.Encoder` is used.
  """
  @spec to_map(Envelope.t() | NativeDiagnostic.t()) :: map()
  def to_map(%Envelope{} = envelope) do
    envelope
    |> Map.from_struct()
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == %{} end)
    |> Enum.map(fn {key, value} -> {Atom.to_string(key), to_map_value(value)} end)
    |> Map.new()
  end

  def to_map(%NativeDiagnostic{} = nd) do
    nd
    |> Map.from_struct()
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == %{} end)
    |> Enum.map(fn {key, value} -> {Atom.to_string(key), stringify(value)} end)
    |> Map.new()
  end

  # ---------------------------------------------------------------------------
  # Private — constructor pipeline (mirrors Chimeway.Contracts pattern)
  # ---------------------------------------------------------------------------

  defp build_envelope(:invalid_attrs), do: {:error, [attrs: :invalid]}

  defp build_envelope(attrs) do
    with :ok <- reject_forbidden_attrs(attrs),
         {:ok, struct} <- struct_from_attrs(Envelope, attrs),
         :ok <- validate_envelope(struct) do
      {:ok, struct}
    end
  end

  defp build_native_diagnostic(:invalid_attrs), do: {:error, [attrs: :invalid]}

  defp build_native_diagnostic(attrs) do
    with {:ok, struct} <- struct_from_attrs(NativeDiagnostic, attrs),
         :ok <- validate_native_diagnostic(struct) do
      {:ok, struct}
    end
  end

  defp validate_envelope(%Envelope{} = envelope) do
    []
    |> validate_closed(:layer, envelope.layer, @layers)
    |> validate_closed(:platform, envelope.platform, @platforms)
    |> validate_closed(:kind, envelope.kind, @kinds)
    |> validate_required_string(:schema_version, envelope.schema_version)
    |> validate_required_string(:native_runtime_version, envelope.native_runtime_version)
    |> validate_required_string(:correlation_id, envelope.correlation_id)
    |> validate_required_string(:observed_at, envelope.observed_at)
    |> to_result()
  end

  defp validate_envelope(_envelope), do: {:error, [envelope: :invalid_contract]}

  defp validate_native_diagnostic(%NativeDiagnostic{} = nd) do
    []
    |> validate_closed(:source, nd.source, @sources)
    |> validate_closed(:exit_reason, nd.exit_reason, @exit_reasons)
    |> to_result()
  end

  defp validate_native_diagnostic(_nd), do: {:error, [native_diagnostic: :invalid_contract]}

  defp reject_forbidden_attrs(attrs) do
    case Enum.find(@forbidden_keys, &Map.has_key?(attrs, &1)) do
      nil -> :ok
      key -> {:error, [{key, :forbidden_key}]}
    end
  end

  defp struct_from_attrs(module, attrs) do
    {:ok, struct!(module, attrs)}
  rescue
    error in [ArgumentError, KeyError] -> {:error, [attrs: Exception.message(error)]}
  end

  defp validate_required_string(errors, key, value) when is_binary(value) do
    if byte_size(String.trim(value)) > 0, do: errors, else: [{key, :required} | errors]
  end

  defp validate_required_string(errors, key, _value), do: [{key, :required} | errors]

  defp validate_closed(errors, key, value, allowed) do
    if value in allowed, do: errors, else: [{key, {:unsupported, value, allowed}} | errors]
  end

  defp to_result([]), do: :ok
  defp to_result(errors), do: {:error, Enum.reverse(errors)}

  defp normalize_attrs(attrs) when is_list(attrs), do: attrs |> Map.new() |> normalize_attrs()

  defp normalize_attrs(attrs) when is_map(attrs) do
    attrs
    |> Enum.map(fn {key, value} -> {normalize_key(key), value} end)
    |> Map.new()
  end

  defp normalize_attrs(_attrs), do: :invalid_attrs

  defp normalize_key(key) when is_atom(key), do: key

  defp normalize_key(key) when is_binary(key) do
    try do
      String.to_existing_atom(key)
    rescue
      ArgumentError -> key
    end
  end

  defp normalize_key(key), do: key

  # to_map_value handles the nested NativeDiagnostic case
  defp to_map_value(%NativeDiagnostic{} = nd), do: to_map(nd)
  defp to_map_value(value), do: stringify(value)

  defp stringify(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify(value) when is_list(value), do: Enum.map(value, &stringify/1)

  defp stringify(value) when is_map(value),
    do: Map.new(value, fn {key, val} -> {to_string(key), stringify(val)} end)

  defp stringify(value), do: value
end
