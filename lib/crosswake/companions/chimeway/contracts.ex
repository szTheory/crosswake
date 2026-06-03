defmodule Crosswake.Companions.Chimeway.Contracts do
  @moduledoc """
  Provider-neutral Chimeway token evidence and binding contracts.

  Token evidence is diagnostic/provider evidence only. Backend-owned token
  bindings decide lifecycle state; neither evidence nor provider feedback grants
  auth, session, route, notification-open, or delivery authority.
  """

  alias Crosswake.Bridge.Commands.PermissionsStatus

  @providers [:apns, :fcm]
  @platforms [:ios, :android]
  @environments [:sandbox, :production, :development, :unknown]
  @notification_statuses PermissionsStatus.supported_statuses()
  @binding_states [:active, :superseded, :revoked, :stale, :invalid]
  @binding_reasons [
    :initial_bind,
    :token_rotated,
    :logout_revoked,
    :session_revoked,
    :permission_denied,
    :provider_unregistered,
    :provider_invalid_token,
    :environment_mismatch,
    :app_identity_mismatch,
    :staleness_pruned,
    :manual_revocation
  ]
  @provider_feedback_events [
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
  @app_identity_postures [:matched, :mismatched, :unknown]
  @binding_event_types [:observed, :bound, :rotated, :revoked, :stale, :invalidated, :feedback]
  @binding_result_statuses [:bound, :rotated, :revoked, :stale, :invalidated, :rejected]
  @proof_classes [:hermetic, :advisory, :not_applicable]
  @forbidden_public_token_keys [
    :token,
    :raw_token,
    :device_token,
    :registration_token,
    :apns_token,
    :fcm_token
  ]

  defmodule TokenEvidence do
    @moduledoc false

    @enforce_keys [
      :provider,
      :platform,
      :environment,
      :installation_ref,
      :token_ref,
      :token_fingerprint,
      :notification_status,
      :observed_at
    ]
    defstruct [
      :provider,
      :platform,
      :environment,
      :installation_ref,
      :token_ref,
      :token_fingerprint,
      :notification_status,
      :observed_at,
      :app_identity_posture,
      :correlation_id,
      metadata: %{}
    ]

    @type t :: %__MODULE__{
            provider: atom(),
            platform: atom(),
            environment: atom(),
            installation_ref: String.t(),
            token_ref: String.t(),
            token_fingerprint: String.t(),
            notification_status: atom(),
            observed_at: String.t(),
            app_identity_posture: atom() | nil,
            correlation_id: String.t() | nil,
            metadata: map()
          }
  end

  defmodule TokenBinding do
    @moduledoc false

    @enforce_keys [
      :binding_ref,
      :installation_ref,
      :provider,
      :platform,
      :environment,
      :token_ref,
      :token_fingerprint,
      :state,
      :reason,
      :bound_at,
      :last_seen_at
    ]
    defstruct [
      :binding_ref,
      :installation_ref,
      :provider,
      :platform,
      :environment,
      :token_ref,
      :token_fingerprint,
      :state,
      :reason,
      :bound_at,
      :last_seen_at,
      :subject_scope,
      :subject_ref,
      :org_ref,
      :session_ref,
      :session_version,
      :app_identity_posture,
      :superseded_at,
      :revoked_at,
      :stale_at,
      :invalidated_at,
      :audit_ref,
      metadata: %{}
    ]

    @type t :: %__MODULE__{
            binding_ref: String.t(),
            installation_ref: String.t(),
            provider: atom(),
            platform: atom(),
            environment: atom(),
            token_ref: String.t(),
            token_fingerprint: String.t(),
            state: atom(),
            reason: atom(),
            bound_at: String.t(),
            last_seen_at: String.t(),
            subject_scope: atom() | String.t() | nil,
            subject_ref: String.t() | nil,
            org_ref: String.t() | nil,
            session_ref: String.t() | nil,
            session_version: non_neg_integer() | nil,
            app_identity_posture: atom() | nil,
            superseded_at: String.t() | nil,
            revoked_at: String.t() | nil,
            stale_at: String.t() | nil,
            invalidated_at: String.t() | nil,
            audit_ref: String.t() | nil,
            metadata: map()
          }
  end

  defmodule ProviderFeedback do
    @moduledoc false

    @enforce_keys [:provider, :platform, :environment, :feedback_event, :occurred_at]
    defstruct [
      :provider,
      :platform,
      :environment,
      :feedback_event,
      :occurred_at,
      :token_ref,
      :token_fingerprint,
      :provider_evidence_ref,
      :app_identity_posture,
      :correlation_id,
      metadata: %{}
    ]

    @type t :: %__MODULE__{
            provider: atom(),
            platform: atom(),
            environment: atom(),
            feedback_event: atom(),
            occurred_at: String.t(),
            token_ref: String.t() | nil,
            token_fingerprint: String.t() | nil,
            provider_evidence_ref: String.t() | nil,
            app_identity_posture: atom() | nil,
            correlation_id: String.t() | nil,
            metadata: map()
          }
  end

  defmodule BindingEvent do
    @moduledoc false

    @enforce_keys [:event_ref, :event_type, :occurred_at]
    defstruct [
      :event_ref,
      :event_type,
      :binding_ref,
      :token_ref,
      :token_fingerprint,
      :provider,
      :platform,
      :environment,
      :installation_ref,
      :state_before,
      :state_after,
      :reason,
      :feedback_event,
      :app_identity_posture,
      :notification_status,
      :occurred_at,
      :correlation_id,
      :proof_class,
      metadata: %{}
    ]

    @type t :: %__MODULE__{event_ref: String.t(), event_type: atom(), occurred_at: String.t()}
  end

  defmodule BindingResult do
    @moduledoc false

    @enforce_keys [:status, :binding_ref]
    defstruct [
      :status,
      :binding_ref,
      :token_ref,
      :token_fingerprint,
      :state,
      :reason,
      :event_ref,
      :correlation_id,
      metadata: %{}
    ]

    @type t :: %__MODULE__{status: atom(), binding_ref: String.t()}
  end

  defmodule NotificationOpenEvidence do
    @moduledoc false

    @enforce_keys [
      :route_id,
      :open_ref,
      :binding_ref,
      :provider,
      :action_ref,
      :auth_context
    ]
    defstruct [
      :route_id,
      :open_ref,
      :binding_ref,
      :provider,
      :action_ref,
      :auth_context,
      :action_kind,
      :evaluated_at,
      metadata: %{}
    ]

    @type t :: %__MODULE__{
            route_id: String.t(),
            open_ref: String.t(),
            binding_ref: String.t(),
            provider: atom(),
            action_ref: String.t(),
            auth_context: map(),
            action_kind: atom() | nil,
            evaluated_at: String.t() | nil,
            metadata: map()
          }
  end

  defmodule OpenResolution do
    @moduledoc false

    @enforce_keys [:open_ref, :state]
    defstruct [
      :open_ref,
      :state,
      :reason,
      :resolved_at,
      metadata: %{}
    ]

    @type t :: %__MODULE__{
            open_ref: String.t(),
            state: atom(),
            reason: atom() | nil,
            resolved_at: String.t() | nil,
            metadata: map()
          }
  end

  @spec providers() :: [atom()]
  def providers, do: @providers

  @spec platforms() :: [atom()]
  def platforms, do: @platforms

  @spec environments() :: [atom()]
  def environments, do: @environments

  @spec notification_statuses() :: [atom()]
  def notification_statuses, do: @notification_statuses

  @spec binding_states() :: [atom()]
  def binding_states, do: @binding_states

  @spec binding_reasons() :: [atom()]
  def binding_reasons, do: @binding_reasons

  @spec provider_feedback_events() :: [atom()]
  def provider_feedback_events, do: @provider_feedback_events

  @spec app_identity_postures() :: [atom()]
  def app_identity_postures, do: @app_identity_postures

  @spec binding_event_types() :: [atom()]
  def binding_event_types, do: @binding_event_types

  @spec binding_result_statuses() :: [atom()]
  def binding_result_statuses, do: @binding_result_statuses

  @spec forbidden_public_token_keys() :: [atom()]
  def forbidden_public_token_keys, do: @forbidden_public_token_keys

  @spec new_token_evidence(map() | keyword()) :: {:ok, TokenEvidence.t()} | {:error, keyword()}
  def new_token_evidence(attrs),
    do:
      attrs
      |> normalize_attrs()
      |> build(TokenEvidence, &validate_token_evidence/1)

  @spec new_token_evidence!(map() | keyword()) :: TokenEvidence.t()
  def new_token_evidence!(attrs), do: unwrap!(new_token_evidence(attrs))

  @spec new_token_binding(map() | keyword()) :: {:ok, TokenBinding.t()} | {:error, keyword()}
  def new_token_binding(attrs),
    do:
      attrs
      |> normalize_attrs()
      |> build(TokenBinding, &validate_token_binding/1)

  @spec new_token_binding!(map() | keyword()) :: TokenBinding.t()
  def new_token_binding!(attrs), do: unwrap!(new_token_binding(attrs))

  @spec new_provider_feedback(map() | keyword()) ::
          {:ok, ProviderFeedback.t()} | {:error, keyword()}
  def new_provider_feedback(attrs),
    do:
      attrs
      |> normalize_attrs()
      |> build(ProviderFeedback, &validate_provider_feedback/1)

  @spec new_provider_feedback!(map() | keyword()) :: ProviderFeedback.t()
  def new_provider_feedback!(attrs), do: unwrap!(new_provider_feedback(attrs))

  @spec new_binding_event(map() | keyword()) :: {:ok, BindingEvent.t()} | {:error, keyword()}
  def new_binding_event(attrs),
    do:
      attrs
      |> normalize_attrs()
      |> build(BindingEvent, &validate_binding_event/1)

  @spec new_binding_event!(map() | keyword()) :: BindingEvent.t()
  def new_binding_event!(attrs), do: unwrap!(new_binding_event(attrs))

  @spec new_binding_result(map() | keyword()) :: {:ok, BindingResult.t()} | {:error, keyword()}
  def new_binding_result(attrs),
    do:
      attrs
      |> normalize_attrs()
      |> build(BindingResult, &validate_binding_result/1)

  @spec new_binding_result!(map() | keyword()) :: BindingResult.t()
  def new_binding_result!(attrs), do: unwrap!(new_binding_result(attrs))

  @spec new_notification_open_evidence(map() | keyword()) :: {:ok, NotificationOpenEvidence.t()} | {:error, keyword()}
  def new_notification_open_evidence(attrs),
    do:
      attrs
      |> normalize_attrs()
      |> build(NotificationOpenEvidence, &validate_notification_open_evidence/1)

  @spec new_notification_open_evidence!(map() | keyword()) :: NotificationOpenEvidence.t()
  def new_notification_open_evidence!(attrs), do: unwrap!(new_notification_open_evidence(attrs))

  @spec new_open_resolution(map() | keyword()) :: {:ok, OpenResolution.t()} | {:error, keyword()}
  def new_open_resolution(attrs),
    do:
      attrs
      |> normalize_attrs()
      |> build(OpenResolution, &validate_open_resolution/1)

  @spec new_open_resolution!(map() | keyword()) :: OpenResolution.t()
  def new_open_resolution!(attrs), do: unwrap!(new_open_resolution(attrs))

  @spec validate_token_evidence(TokenEvidence.t()) :: :ok | {:error, keyword()}
  def validate_token_evidence(%TokenEvidence{} = evidence) do
    []
    |> validate_closed(:provider, evidence.provider, @providers)
    |> validate_closed(:platform, evidence.platform, @platforms)
    |> validate_closed(:environment, evidence.environment, @environments)
    |> validate_required_string(:installation_ref, evidence.installation_ref)
    |> validate_required_string(:token_ref, evidence.token_ref)
    |> validate_required_string(:token_fingerprint, evidence.token_fingerprint)
    |> validate_closed(:notification_status, evidence.notification_status, @notification_statuses)
    |> validate_required_string(:observed_at, evidence.observed_at)
    |> validate_optional_closed(
      :app_identity_posture,
      evidence.app_identity_posture,
      @app_identity_postures
    )
    |> to_result()
  end

  def validate_token_evidence(_evidence), do: {:error, [token_evidence: :invalid_contract]}

  @spec validate_token_binding(TokenBinding.t()) :: :ok | {:error, keyword()}
  def validate_token_binding(%TokenBinding{} = binding) do
    []
    |> validate_required_string(:binding_ref, binding.binding_ref)
    |> validate_required_string(:installation_ref, binding.installation_ref)
    |> validate_closed(:provider, binding.provider, @providers)
    |> validate_closed(:platform, binding.platform, @platforms)
    |> validate_closed(:environment, binding.environment, @environments)
    |> validate_required_string(:token_ref, binding.token_ref)
    |> validate_required_string(:token_fingerprint, binding.token_fingerprint)
    |> validate_closed(:state, binding.state, @binding_states)
    |> validate_closed(:reason, binding.reason, @binding_reasons)
    |> validate_required_string(:bound_at, binding.bound_at)
    |> validate_required_string(:last_seen_at, binding.last_seen_at)
    |> validate_optional_closed(
      :app_identity_posture,
      binding.app_identity_posture,
      @app_identity_postures
    )
    |> to_result()
  end

  def validate_token_binding(_binding), do: {:error, [token_binding: :invalid_contract]}

  @spec validate_provider_feedback(ProviderFeedback.t()) :: :ok | {:error, keyword()}
  def validate_provider_feedback(%ProviderFeedback{} = feedback) do
    []
    |> validate_closed(:provider, feedback.provider, @providers)
    |> validate_closed(:platform, feedback.platform, @platforms)
    |> validate_closed(:environment, feedback.environment, @environments)
    |> validate_closed(:feedback_event, feedback.feedback_event, @provider_feedback_events)
    |> validate_required_string(:occurred_at, feedback.occurred_at)
    |> validate_optional_closed(
      :app_identity_posture,
      feedback.app_identity_posture,
      @app_identity_postures
    )
    |> to_result()
  end

  def validate_provider_feedback(_feedback), do: {:error, [provider_feedback: :invalid_contract]}

  @spec validate_binding_event(BindingEvent.t()) :: :ok | {:error, keyword()}
  def validate_binding_event(%BindingEvent{} = event) do
    []
    |> validate_required_string(:event_ref, event.event_ref)
    |> validate_closed(:event_type, event.event_type, @binding_event_types)
    |> validate_optional_closed(:provider, event.provider, @providers)
    |> validate_optional_closed(:platform, event.platform, @platforms)
    |> validate_optional_closed(:environment, event.environment, @environments)
    |> validate_optional_closed(:state_before, event.state_before, @binding_states)
    |> validate_optional_closed(:state_after, event.state_after, @binding_states)
    |> validate_optional_closed(:reason, event.reason, @binding_reasons)
    |> validate_optional_closed(:feedback_event, event.feedback_event, @provider_feedback_events)
    |> validate_optional_closed(
      :app_identity_posture,
      event.app_identity_posture,
      @app_identity_postures
    )
    |> validate_optional_closed(
      :notification_status,
      event.notification_status,
      @notification_statuses
    )
    |> validate_required_string(:occurred_at, event.occurred_at)
    |> validate_optional_closed(:proof_class, event.proof_class, @proof_classes)
    |> to_result()
  end

  def validate_binding_event(_event), do: {:error, [binding_event: :invalid_contract]}

  @spec validate_binding_result(BindingResult.t()) :: :ok | {:error, keyword()}
  def validate_binding_result(%BindingResult{} = result) do
    []
    |> validate_closed(:status, result.status, @binding_result_statuses)
    |> validate_required_string(:binding_ref, result.binding_ref)
    |> validate_optional_closed(:state, result.state, @binding_states)
    |> validate_optional_closed(:reason, result.reason, @binding_reasons)
    |> to_result()
  end

  def validate_binding_result(_result), do: {:error, [binding_result: :invalid_contract]}

  @spec validate_notification_open_evidence(NotificationOpenEvidence.t()) :: :ok | {:error, keyword()}
  def validate_notification_open_evidence(%NotificationOpenEvidence{} = evidence) do
    []
    |> validate_required_string(:route_id, evidence.route_id)
    |> validate_required_string(:open_ref, evidence.open_ref)
    |> validate_required_string(:binding_ref, evidence.binding_ref)
    |> validate_closed(:provider, evidence.provider, @providers)
    |> validate_required_string(:action_ref, evidence.action_ref)
    |> to_result()
  end

  def validate_notification_open_evidence(_evidence), do: {:error, [notification_open_evidence: :invalid_contract]}

  @spec validate_open_resolution(OpenResolution.t()) :: :ok | {:error, keyword()}
  def validate_open_resolution(%OpenResolution{} = resolution) do
    []
    |> validate_required_string(:open_ref, resolution.open_ref)
    |> to_result()
  end

  def validate_open_resolution(_resolution), do: {:error, [open_resolution: :invalid_contract]}

  @spec lifecycle_mapping() :: map()
  def lifecycle_mapping do
    %{
      active: %{state: :active, reason: :initial_bind},
      rotated: %{state: :superseded, reason: :token_rotated},
      revoked: %{state: :revoked, reason: :manual_revocation},
      stale: %{state: :stale, reason: :staleness_pruned},
      invalid: %{state: :invalid, reason: :provider_invalid_token},
      permission_denied: %{state: :revoked, reason: :permission_denied},
      environment_mismatched: %{state: :invalid, reason: :environment_mismatch},
      app_identity_mismatched: %{state: :invalid, reason: :app_identity_mismatch}
    }
  end

  @spec provider_handoff_event() :: :delivery_accepted
  def provider_handoff_event, do: :delivery_accepted

  @spec to_map(struct()) :: map()
  def to_map(%module{} = struct)
      when module in [
             TokenEvidence,
             TokenBinding,
             ProviderFeedback,
             BindingEvent,
             BindingResult,
             NotificationOpenEvidence,
             OpenResolution
           ] do
    struct
    |> Map.from_struct()
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Enum.map(fn {key, value} -> {Atom.to_string(key), stringify(value)} end)
    |> Map.new()
  end

  defp normalize_attrs(attrs) when is_list(attrs), do: attrs |> Map.new() |> normalize_attrs()

  defp normalize_attrs(attrs) when is_map(attrs) do
    attrs
    |> Enum.map(fn {key, value} -> {normalize_key(key), normalize_value(value)} end)
    |> Map.new()
  end

  defp normalize_attrs(_attrs), do: :invalid_attrs

  defp build(:invalid_attrs, _module, _validator), do: {:error, [attrs: :invalid]}

  defp build(attrs, module, validator) do
    with :ok <- reject_forbidden_token_attrs(attrs),
         {:ok, struct} <- struct_from_attrs(module, attrs),
         :ok <- validator.(struct) do
      {:ok, struct}
    end
  end

  defp struct_from_attrs(module, attrs) do
    {:ok, struct!(module, attrs)}
  rescue
    error in [ArgumentError, KeyError] -> {:error, [attrs: Exception.message(error)]}
  end

  defp reject_forbidden_token_attrs(attrs) do
    case Enum.find(@forbidden_public_token_keys, &Map.has_key?(attrs, &1)) do
      nil -> :ok
      key -> {:error, [{key, :raw_token_field_forbidden}]}
    end
  end

  defp unwrap!({:ok, struct}), do: struct

  defp unwrap!({:error, errors}),
    do: raise(ArgumentError, "invalid Chimeway contract: #{inspect(errors)}")

  defp validate_required_string(errors, key, value) when is_binary(value) do
    if byte_size(String.trim(value)) > 0, do: errors, else: [{key, :required} | errors]
  end

  defp validate_required_string(errors, key, _value), do: [{key, :required} | errors]

  defp validate_closed(errors, key, value, allowed) do
    if value in allowed, do: errors, else: [{key, {:unsupported, value, allowed}} | errors]
  end

  defp validate_optional_closed(errors, _key, nil, _allowed), do: errors

  defp validate_optional_closed(errors, key, value, allowed),
    do: validate_closed(errors, key, value, allowed)

  defp to_result([]), do: :ok
  defp to_result(errors), do: {:error, Enum.reverse(errors)}

  defp normalize_key(key) when is_atom(key), do: key

  defp normalize_key(key) when is_binary(key) do
    try do
      String.to_existing_atom(key)
    rescue
      ArgumentError -> key
    end
  end

  defp normalize_key(key), do: key

  defp normalize_value(value) when is_binary(value) do
    case value do
      "apns" -> :apns
      "fcm" -> :fcm
      "ios" -> :ios
      "android" -> :android
      "sandbox" -> :sandbox
      "production" -> :production
      "development" -> :development
      "unknown" -> :unknown
      "granted" -> :granted
      "denied" -> :denied
      "restricted" -> :restricted
      _ -> value
    end
  end

  defp normalize_value(value), do: value

  defp stringify(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify(value) when is_list(value), do: Enum.map(value, &stringify/1)

  defp stringify(value) when is_map(value),
    do: Map.new(value, fn {key, value} -> {to_string(key), stringify(value)} end)

  defp stringify(value), do: value
end
