defmodule Crosswake.Companions.Chimeway.Redaction do
  @moduledoc """
  Raw-token boundary helpers for Chimeway notification evidence.

  Helpers in this module may accept raw bridge/provider token material, but
  returned Chimeway contracts carry only `token_ref` and `token_fingerprint`.
  """

  alias Crosswake.Bridge.Commands.NotificationToken
  alias Crosswake.Companions.Chimeway.Contracts
  alias Crosswake.Companions.Chimeway.Contracts.ProviderFeedback
  alias Crosswake.Companions.Chimeway.Contracts.TokenEvidence

  @forbidden_public_token_keys [
    :token,
    :raw_token,
    :device_token,
    :registration_token,
    :apns_token,
    :fcm_token
  ]
  @safe_metadata_keys [:safe_detail]
  @max_metadata_string_bytes 128

  @apns_feedback %{
    "BadDeviceToken" => :environment_mismatch,
    "DeviceTokenNotForTopic" => :app_identity_mismatch,
    "Unregistered" => :token_unregistered
  }

  @fcm_feedback %{
    "UNREGISTERED" => :token_unregistered,
    "INVALID_ARGUMENT" => :token_invalid,
    "SENDER_ID_MISMATCH" => :app_identity_mismatch,
    "UNAVAILABLE" => :provider_unavailable,
    "QUOTA_EXCEEDED" => :provider_throttled
  }
  @canonical_feedback_events [
    :token_unregistered,
    :token_invalid,
    :environment_mismatch,
    :app_identity_mismatch,
    :credentials_invalid,
    :provider_throttled,
    :provider_unavailable,
    :delivery_accepted,
    :delivery_failed
  ]

  @spec forbidden_public_token_keys() :: [atom()]
  def forbidden_public_token_keys, do: @forbidden_public_token_keys

  @spec fingerprint_token(String.t(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def fingerprint_token(raw_token, opts) when is_binary(raw_token) and byte_size(raw_token) > 0 do
    cond do
      is_binary(opts[:fingerprint_secret]) and byte_size(opts[:fingerprint_secret]) > 0 ->
        digest = :crypto.mac(:hmac, :sha256, opts[:fingerprint_secret], raw_token)
        {:ok, "hmac-sha256:" <> Base.encode16(digest, case: :lower)}

      is_function(opts[:fingerprint_fun], 1) ->
        case opts[:fingerprint_fun].(raw_token) do
          fingerprint when is_binary(fingerprint) and byte_size(fingerprint) > 0 ->
            {:ok, fingerprint}

          _invalid ->
            {:error, :invalid_fingerprint}
        end

      true ->
        {:error, :missing_fingerprint_strategy}
    end
  end

  def fingerprint_token(_raw_token, _opts), do: {:error, :invalid_token}

  @spec redact_notification_token_response(NotificationToken.Response.t(), keyword()) ::
          {:ok, TokenEvidence.t()} | {:error, term()}
  def redact_notification_token_response(%NotificationToken.Response{} = response, opts)
      when is_list(opts) do
    with {:ok, token_ref} <- required_opt(opts, :token_ref),
         {:ok, installation_ref} <- required_opt(opts, :installation_ref),
         {:ok, platform} <- required_opt(opts, :platform),
         {:ok, environment} <- required_opt(opts, :environment),
         {:ok, token_fingerprint} <- fingerprint_token(response.token, opts),
         provider <- normalize_provider(response.provider),
         attrs = %{
           provider: provider,
           platform: platform,
           environment: environment,
           installation_ref: installation_ref,
           token_ref: token_ref,
           token_fingerprint: token_fingerprint,
           notification_status: response.notification_status,
           observed_at: Keyword.get(opts, :observed_at, now_iso8601()),
           app_identity_posture: Keyword.get(opts, :app_identity_posture, :unknown),
           correlation_id: Keyword.get(opts, :correlation_id),
           metadata: safe_metadata(response.detail)
         } do
      Contracts.new_token_evidence(attrs)
    end
  end

  def redact_notification_token_response(_response, _opts), do: {:error, :invalid_response}

  @spec feedback_from_provider_attrs(map() | keyword()) ::
          {:ok, ProviderFeedback.t()} | {:error, term()}
  def feedback_from_provider_attrs(attrs) when is_list(attrs),
    do: attrs |> Map.new() |> feedback_from_provider_attrs()

  def feedback_from_provider_attrs(attrs) when is_map(attrs) do
    provider = attrs |> get_any(:provider) |> normalize_provider()
    raw_code = get_any(attrs, :reason) || get_any(attrs, :code) || get_any(attrs, :error_code)

    with {:ok, feedback_event} <- normalize_feedback_event(provider, raw_code) do
      Contracts.new_provider_feedback(%{
        provider: provider,
        platform: normalize_platform(get_any(attrs, :platform)),
        environment: normalize_environment(get_any(attrs, :environment)),
        feedback_event: feedback_event,
        occurred_at: get_any(attrs, :occurred_at) || now_iso8601(),
        token_ref: get_any(attrs, :token_ref),
        token_fingerprint: get_any(attrs, :token_fingerprint),
        provider_evidence_ref: get_any(attrs, :provider_evidence_ref),
        app_identity_posture: get_any(attrs, :app_identity_posture) || :unknown,
        correlation_id: get_any(attrs, :correlation_id),
        metadata: safe_metadata(get_any(attrs, :metadata) || %{})
      })
    end
  end

  def feedback_from_provider_attrs(_attrs), do: {:error, :invalid_feedback_attrs}

  defp required_opt(opts, key) do
    case Keyword.get(opts, key) do
      value when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      nil -> {:error, {key, :required}}
      value when is_atom(value) -> {:ok, value}
      _missing -> {:error, {key, :required}}
    end
  end

  defp normalize_feedback_event(:apns, code) when is_binary(code),
    do: Map.fetch(@apns_feedback, code)

  defp normalize_feedback_event(:fcm, code) when is_binary(code),
    do: Map.fetch(@fcm_feedback, code)

  defp normalize_feedback_event(_provider, :delivery_accepted), do: {:ok, :delivery_accepted}
  defp normalize_feedback_event(_provider, :delivery_failed), do: {:ok, :delivery_failed}

  defp normalize_feedback_event(_provider, code) when code in @canonical_feedback_events,
    do: {:ok, code}

  defp normalize_feedback_event(_provider, _code), do: {:error, :unsupported_provider_feedback}

  defp get_any(attrs, key) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
  end

  defp normalize_provider("apns"), do: :apns
  defp normalize_provider("fcm"), do: :fcm
  defp normalize_provider(provider), do: provider

  defp normalize_platform("ios"), do: :ios
  defp normalize_platform("android"), do: :android
  defp normalize_platform(nil), do: :ios
  defp normalize_platform(platform), do: platform

  defp normalize_environment("sandbox"), do: :sandbox
  defp normalize_environment("production"), do: :production
  defp normalize_environment("development"), do: :development
  defp normalize_environment("unknown"), do: :unknown
  defp normalize_environment(nil), do: :unknown
  defp normalize_environment(environment), do: environment

  defp safe_metadata(metadata) when is_map(metadata) do
    metadata
    |> Enum.reduce(%{}, fn {key, value}, safe ->
      key = normalize_key(key)

      if key in @safe_metadata_keys and safe_metadata_value?(value) do
        Map.put(safe, key, value)
      else
        safe
      end
    end)
  end

  defp safe_metadata(_metadata), do: %{}

  defp safe_metadata_value?(value) when is_atom(value), do: true
  defp safe_metadata_value?(value) when is_integer(value) and value >= 0, do: true

  defp safe_metadata_value?(value)
       when is_binary(value) and byte_size(value) > 0 and
              byte_size(value) <= @max_metadata_string_bytes,
       do: true

  defp safe_metadata_value?(_value), do: false

  defp normalize_key(key) when is_atom(key), do: key

  defp normalize_key(key) when is_binary(key) do
    try do
      String.to_existing_atom(key)
    rescue
      ArgumentError -> key
    end
  end

  defp now_iso8601, do: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
end
