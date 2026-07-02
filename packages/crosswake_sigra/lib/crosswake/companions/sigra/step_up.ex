defmodule Crosswake.Companions.Sigra.StepUp do
  @moduledoc """
  Pure Sigra step-up intent contracts.

  Step-up locators are bounded client-presented correlation artifacts. Host-owned
  server records and projected `SessionAuthorityLane` structs remain the source of
  truth for lifecycle, replay, expiry, route binding, and session renewal.
  """

  alias Crosswake.Companions.Sigra.Contracts
  alias Crosswake.Companions.Sigra.Contracts.SessionAuthorityLane

  defmodule StepUpIntentLocator do
    @moduledoc """
    Low-sensitivity locator payload after host transport verification.
    """
    @enforce_keys [
      :typ,
      :intent_ref,
      :version,
      :issuer,
      :audience,
      :issued_at,
      :expires_at,
      :source_route_id,
      :return_route_id,
      :challenge_kind
    ]
    defstruct [
      :typ,
      :intent_ref,
      :version,
      :issuer,
      :audience,
      :issued_at,
      :expires_at,
      :source_route_id,
      :return_route_id,
      :challenge_kind,
      :record_digest,
      :correlation_digest,
      :step_up_transport
    ]
  end

  defmodule StepUpIntentRecord do
    @moduledoc """
    Host-owned authoritative step-up intent record contract.
    """
    @enforce_keys [
      :intent_ref,
      :locator_digest,
      :state,
      :subject_ref,
      :org_id,
      :source_session_ref,
      :expected_session_version,
      :source_route_id,
      :return_route_id,
      :required_assurance_level,
      :required_auth_posture,
      :max_auth_age_seconds,
      :challenge_kind,
      :issued_at,
      :expires_at,
      :audit_correlation_ref,
      :projected_session_authority_lane
    ]
    defstruct [
      :intent_ref,
      :locator_digest,
      :state,
      :subject_ref,
      :org_id,
      :source_session_ref,
      :expected_session_version,
      :device_ref,
      :source_route_id,
      :return_route_id,
      :required_assurance_level,
      :required_auth_posture,
      :max_auth_age_seconds,
      :challenge_kind,
      :issued_at,
      :expires_at,
      :challenged_at,
      :consumed_at,
      :canceled_at,
      :revoked_at,
      :cancellation_reason,
      :revocation_reason,
      :audit_correlation_ref,
      :projected_session_authority_lane,
      return_params: %{}
    ]
  end

  defmodule StepUpChallenge do
    @moduledoc """
    Host-owned challenge descriptor for a server-backed step-up intent.
    """
    @enforce_keys [
      :challenge_ref,
      :intent_ref,
      :challenge_kind,
      :challenge_route_id,
      :return_route_id,
      :required_assurance_level,
      :max_auth_age_seconds,
      :issued_at,
      :expires_at
    ]
    defstruct [
      :challenge_ref,
      :intent_ref,
      :challenge_kind,
      :challenge_route_id,
      :return_route_id,
      :required_assurance_level,
      :max_auth_age_seconds,
      :issued_at,
      :expires_at,
      :message,
      :support_ref
    ]
  end

  defmodule StepUpConsumeRequest do
    @moduledoc """
    Host consume input after locator parsing and challenge evidence collection.
    """
    @enforce_keys [
      :locator,
      :expected_source_route_id,
      :expected_return_route_id,
      :expected_challenge_kind,
      :request_ref
    ]
    defstruct [
      :locator,
      :expected_source_route_id,
      :expected_return_route_id,
      :expected_challenge_kind,
      :source_session_ref,
      :expected_session_version,
      :challenge_evidence,
      :request_ref,
      :evaluated_at
    ]
  end

  defmodule SessionRenewalInstructions do
    @moduledoc """
    Host-owned session, CSRF, and LiveView invalidation instructions.
    """
    @enforce_keys [
      :renew_session?,
      :rotate_csrf?,
      :put_session,
      :delete_session,
      :projected_session_ref,
      :projected_session_version,
      :live_socket_invalidation
    ]
    defstruct [
      :renew_session?,
      :rotate_csrf?,
      :put_session,
      :delete_session,
      :projected_session_ref,
      :projected_session_version,
      :live_socket_invalidation
    ]
  end

  defmodule StepUpCompletion do
    @moduledoc """
    Successful backend step-up completion result.
    """
    @enforce_keys [
      :step_up_intent_ref,
      :consumed_at,
      :session_authority_lane,
      :session_renewal_instructions,
      :route_target
    ]
    defstruct [
      :step_up_intent_ref,
      :consumed_at,
      :session_authority_lane,
      :session_projection,
      :session_renewal_instructions,
      :route_target,
      :audit_event
    ]
  end

  defmodule StepUpAuditEvent do
    @moduledoc """
    Append-only step-up lifecycle evidence contract.
    """
    @enforce_keys [
      :event_id,
      :event_type,
      :step_up_intent_ref,
      :state_before,
      :state_after,
      :outcome,
      :occurred_at,
      :route_id,
      :challenge_kind,
      :request_ref,
      :actor_kind
    ]
    defstruct [
      :event_id,
      :event_type,
      :step_up_intent_ref,
      :intent_ref,
      :state_before,
      :state_after,
      :outcome,
      :denial_code,
      :occurred_at,
      :route_id,
      :challenge_kind,
      :source_session_ref,
      :projected_session_ref,
      :session_version_before,
      :session_version_after,
      :assurance_after,
      :authn_methods_after,
      :binding_result,
      :request_ref,
      :actor_kind,
      metadata: %{}
    ]
  end

  @lifecycle_states [:issued, :challenged, :consumed, :expired, :canceled, :revoked]
  @audit_event_types [:issue, :challenge, :consume, :cancel, :expire, :revoke, :deny]
  @audit_outcomes [:allowed, :denied]

  @locator_keys [
    :typ,
    :intent_ref,
    :jti,
    :version,
    :issuer,
    :iss,
    :audience,
    :aud,
    :issued_at,
    :iat,
    :expires_at,
    :exp,
    :source_route_id,
    :return_route_id,
    :challenge_kind,
    :record_digest,
    :correlation_digest,
    :step_up_transport
  ]

  @forbidden_locator_keys [
    :subject_ref,
    :actor_id,
    :org_id,
    :session_ref,
    :session_id,
    :device_ref,
    :credential_id,
    :passkey_credential_id,
    :oauth_artifact,
    :oauth_access_token,
    :provider_payload,
    :csrf_token,
    :nonce,
    :pkce_verifier,
    :authority_state,
    :assurance_level,
    :authn_methods,
    :authenticated_at,
    :session_authority_lane,
    :session_version,
    :revoked_at
  ]

  @spec lifecycle_states() :: [atom()]
  def lifecycle_states, do: @lifecycle_states

  @spec new_step_up_intent_locator(map() | keyword()) ::
          {:ok, StepUpIntentLocator.t()} | {:error, keyword()}
  def new_step_up_intent_locator(attrs) do
    attrs
    |> normalize_attrs()
    |> reject_locator_smuggling()
    |> case do
      {:ok, normalized} ->
        normalized
        |> normalize_locator_aliases()
        |> normalize_timestamps([:issued_at, :expires_at])
        |> build_and_validate(
          StepUpIntentLocator,
          &validate_step_up_intent_locator/1,
          :step_up_intent_locator
        )

      {:error, errors} ->
        {:error, errors}
    end
  end

  @spec new_step_up_intent_record(map() | keyword()) ::
          {:ok, StepUpIntentRecord.t()} | {:error, keyword()}
  def new_step_up_intent_record(attrs) do
    attrs
    |> normalize_attrs()
    |> normalize_timestamps([
      :issued_at,
      :expires_at,
      :challenged_at,
      :consumed_at,
      :canceled_at,
      :revoked_at
    ])
    |> build_and_validate(
      StepUpIntentRecord,
      &validate_step_up_intent_record/1,
      :step_up_intent_record
    )
  end

  @spec new_step_up_challenge(map() | keyword()) ::
          {:ok, StepUpChallenge.t()} | {:error, keyword()}
  def new_step_up_challenge(attrs) do
    attrs
    |> normalize_attrs()
    |> normalize_timestamps([:issued_at, :expires_at])
    |> build_and_validate(StepUpChallenge, &validate_step_up_challenge/1, :step_up_challenge)
  end

  @spec new_step_up_consume_request(map() | keyword()) ::
          {:ok, StepUpConsumeRequest.t()} | {:error, keyword()}
  def new_step_up_consume_request(attrs) do
    attrs
    |> normalize_attrs()
    |> normalize_timestamps([:evaluated_at])
    |> build_and_validate(
      StepUpConsumeRequest,
      &validate_step_up_consume_request/1,
      :step_up_consume_request
    )
  end

  @spec new_step_up_completion(map() | keyword()) ::
          {:ok, StepUpCompletion.t()} | {:error, keyword()}
  def new_step_up_completion(attrs) do
    attrs
    |> normalize_attrs()
    |> normalize_timestamps([:consumed_at])
    |> build_and_validate(
      StepUpCompletion,
      &validate_step_up_completion/1,
      :step_up_completion
    )
  end

  @spec new_step_up_audit_event(map() | keyword()) ::
          {:ok, StepUpAuditEvent.t()} | {:error, keyword()}
  def new_step_up_audit_event(attrs) do
    attrs
    |> normalize_attrs()
    |> normalize_timestamps([:occurred_at])
    |> build_and_validate(StepUpAuditEvent, &validate_step_up_audit_event/1, :step_up_audit_event)
  end

  @spec new_session_renewal_instructions(map() | keyword()) ::
          {:ok, SessionRenewalInstructions.t()} | {:error, keyword()}
  def new_session_renewal_instructions(attrs) do
    attrs
    |> normalize_attrs()
    |> build_and_validate(
      SessionRenewalInstructions,
      &validate_session_renewal_instructions/1,
      :session_renewal_instructions
    )
  end

  @spec validate_step_up_intent_locator(StepUpIntentLocator.t()) :: :ok | {:error, keyword()}
  def validate_step_up_intent_locator(%StepUpIntentLocator{} = locator) do
    []
    |> validate_required_string(:typ, locator.typ)
    |> validate_required_string(:intent_ref, locator.intent_ref)
    |> validate_required_string(:version, locator.version)
    |> validate_required_string(:issuer, locator.issuer)
    |> validate_required_string(:audience, locator.audience)
    |> validate_timestamp(:issued_at, locator.issued_at)
    |> validate_timestamp(:expires_at, locator.expires_at)
    |> validate_required_string(:source_route_id, locator.source_route_id)
    |> validate_required_string(:return_route_id, locator.return_route_id)
    |> validate_atom_or_string(:challenge_kind, locator.challenge_kind)
    |> validate_optional_string(:record_digest, locator.record_digest)
    |> validate_optional_string(:correlation_digest, locator.correlation_digest)
    |> validate_optional_string(:step_up_transport, locator.step_up_transport)
    |> to_validation_result()
  end

  def validate_step_up_intent_locator(_locator),
    do: {:error, [step_up_intent_locator: :invalid_contract]}

  @spec validate_step_up_intent_record(StepUpIntentRecord.t()) :: :ok | {:error, keyword()}
  def validate_step_up_intent_record(%StepUpIntentRecord{} = record) do
    []
    |> validate_required_string(:intent_ref, record.intent_ref)
    |> validate_required_string(:locator_digest, record.locator_digest)
    |> validate_enum(:state, record.state, @lifecycle_states)
    |> validate_required_string(:subject_ref, record.subject_ref)
    |> validate_required_string(:org_id, record.org_id)
    |> validate_required_string(:source_session_ref, record.source_session_ref)
    |> validate_non_negative_integer(:expected_session_version, record.expected_session_version)
    |> validate_optional_string(:device_ref, record.device_ref)
    |> validate_required_string(:source_route_id, record.source_route_id)
    |> validate_required_string(:return_route_id, record.return_route_id)
    |> validate_map(:return_params, record.return_params)
    |> validate_enum(
      :required_assurance_level,
      record.required_assurance_level,
      Contracts.assurance_level_vocabulary()
    )
    |> validate_atom_or_string(:required_auth_posture, record.required_auth_posture)
    |> validate_positive_integer(:max_auth_age_seconds, record.max_auth_age_seconds)
    |> validate_atom_or_string(:challenge_kind, record.challenge_kind)
    |> validate_timestamp(:issued_at, record.issued_at)
    |> validate_timestamp(:expires_at, record.expires_at)
    |> validate_optional_timestamp(:challenged_at, record.challenged_at)
    |> validate_optional_timestamp(:consumed_at, record.consumed_at)
    |> validate_optional_timestamp(:canceled_at, record.canceled_at)
    |> validate_optional_timestamp(:revoked_at, record.revoked_at)
    |> validate_optional_string(:cancellation_reason, record.cancellation_reason)
    |> validate_optional_string(:revocation_reason, record.revocation_reason)
    |> validate_required_string(:audit_correlation_ref, record.audit_correlation_ref)
    |> validate_session_authority_lane(record.projected_session_authority_lane)
    |> to_validation_result()
  end

  def validate_step_up_intent_record(_record),
    do: {:error, [step_up_intent_record: :invalid_contract]}

  @spec validate_step_up_challenge(StepUpChallenge.t()) :: :ok | {:error, keyword()}
  def validate_step_up_challenge(%StepUpChallenge{} = challenge) do
    []
    |> validate_required_string(:challenge_ref, challenge.challenge_ref)
    |> validate_required_string(:intent_ref, challenge.intent_ref)
    |> validate_atom_or_string(:challenge_kind, challenge.challenge_kind)
    |> validate_required_string(:challenge_route_id, challenge.challenge_route_id)
    |> validate_required_string(:return_route_id, challenge.return_route_id)
    |> validate_enum(
      :required_assurance_level,
      challenge.required_assurance_level,
      Contracts.assurance_level_vocabulary()
    )
    |> validate_positive_integer(:max_auth_age_seconds, challenge.max_auth_age_seconds)
    |> validate_timestamp(:issued_at, challenge.issued_at)
    |> validate_timestamp(:expires_at, challenge.expires_at)
    |> validate_optional_string(:message, challenge.message)
    |> validate_optional_string(:support_ref, challenge.support_ref)
    |> to_validation_result()
  end

  def validate_step_up_challenge(_challenge), do: {:error, [step_up_challenge: :invalid_contract]}

  @spec validate_step_up_consume_request(StepUpConsumeRequest.t()) :: :ok | {:error, keyword()}
  def validate_step_up_consume_request(%StepUpConsumeRequest{} = request) do
    []
    |> validate_locator_contract(request.locator)
    |> validate_required_string(:expected_source_route_id, request.expected_source_route_id)
    |> validate_required_string(:expected_return_route_id, request.expected_return_route_id)
    |> validate_atom_or_string(:expected_challenge_kind, request.expected_challenge_kind)
    |> validate_optional_string(:source_session_ref, request.source_session_ref)
    |> validate_optional_non_negative_integer(
      :expected_session_version,
      request.expected_session_version
    )
    |> validate_optional_map(:challenge_evidence, request.challenge_evidence)
    |> validate_required_string(:request_ref, request.request_ref)
    |> validate_optional_timestamp(:evaluated_at, request.evaluated_at)
    |> to_validation_result()
  end

  def validate_step_up_consume_request(_request),
    do: {:error, [step_up_consume_request: :invalid_contract]}

  @spec validate_step_up_completion(StepUpCompletion.t()) :: :ok | {:error, keyword()}
  def validate_step_up_completion(%StepUpCompletion{} = completion) do
    []
    |> validate_required_string(:step_up_intent_ref, completion.step_up_intent_ref)
    |> validate_timestamp(:consumed_at, completion.consumed_at)
    |> validate_session_authority_lane(completion.session_authority_lane)
    |> validate_session_renewal_contract(completion.session_renewal_instructions)
    |> validate_map(:route_target, completion.route_target)
    |> validate_optional_map(:session_projection, completion.session_projection)
    |> validate_optional_audit_event(completion.audit_event)
    |> to_validation_result()
  end

  def validate_step_up_completion(_completion),
    do: {:error, [step_up_completion: :invalid_contract]}

  @spec validate_step_up_audit_event(StepUpAuditEvent.t()) :: :ok | {:error, keyword()}
  def validate_step_up_audit_event(%StepUpAuditEvent{} = event) do
    []
    |> validate_required_string(:event_id, event.event_id)
    |> validate_enum(:event_type, event.event_type, @audit_event_types)
    |> validate_required_string(:step_up_intent_ref, event.step_up_intent_ref)
    |> validate_optional_string(:intent_ref, event.intent_ref)
    |> validate_optional_enum(:state_before, event.state_before, @lifecycle_states)
    |> validate_optional_enum(:state_after, event.state_after, @lifecycle_states)
    |> validate_enum(:outcome, event.outcome, @audit_outcomes)
    |> validate_optional_denial_code(event.denial_code)
    |> validate_timestamp(:occurred_at, event.occurred_at)
    |> validate_required_string(:route_id, event.route_id)
    |> validate_atom_or_string(:challenge_kind, event.challenge_kind)
    |> validate_optional_string(:source_session_ref, event.source_session_ref)
    |> validate_optional_string(:projected_session_ref, event.projected_session_ref)
    |> validate_optional_non_negative_integer(
      :session_version_before,
      event.session_version_before
    )
    |> validate_optional_non_negative_integer(:session_version_after, event.session_version_after)
    |> validate_optional_enum(
      :assurance_after,
      event.assurance_after,
      Contracts.assurance_level_vocabulary()
    )
    |> validate_optional_list(:authn_methods_after, event.authn_methods_after)
    |> validate_optional_string(:binding_result, event.binding_result)
    |> validate_required_string(:request_ref, event.request_ref)
    |> validate_atom_or_string(:actor_kind, event.actor_kind)
    |> validate_map(:metadata, event.metadata)
    |> to_validation_result()
  end

  def validate_step_up_audit_event(_event), do: {:error, [step_up_audit_event: :invalid_contract]}

  @spec validate_session_renewal_instructions(SessionRenewalInstructions.t()) ::
          :ok | {:error, keyword()}
  def validate_session_renewal_instructions(%SessionRenewalInstructions{} = instructions) do
    []
    |> validate_boolean(:renew_session?, instructions.renew_session?)
    |> validate_boolean(:rotate_csrf?, instructions.rotate_csrf?)
    |> validate_session_ops(:put_session, instructions.put_session)
    |> validate_delete_session(instructions.delete_session)
    |> validate_required_string(:projected_session_ref, instructions.projected_session_ref)
    |> validate_non_negative_integer(
      :projected_session_version,
      instructions.projected_session_version
    )
    |> validate_map(:live_socket_invalidation, instructions.live_socket_invalidation)
    |> to_validation_result()
  end

  def validate_session_renewal_instructions(_instructions),
    do: {:error, [session_renewal_instructions: :invalid_contract]}

  defp reject_locator_smuggling({:error, errors}), do: {:error, errors}

  defp reject_locator_smuggling({:ok, attrs}) do
    forbidden_errors =
      @forbidden_locator_keys
      |> Enum.filter(&Map.has_key?(attrs, &1))
      |> Enum.map(&{:step_up_intent_locator, {&1, :forbidden}})

    allowed = MapSet.new(@locator_keys)

    unknown_errors =
      attrs
      |> Map.keys()
      |> Enum.reject(&MapSet.member?(allowed, &1))
      |> Enum.map(&{:step_up_intent_locator, {&1, :unsupported_claim}})

    case forbidden_errors ++ unknown_errors do
      [] -> {:ok, attrs}
      errors -> {:error, errors}
    end
  end

  defp normalize_locator_aliases(attrs) do
    attrs
    |> put_new(:intent_ref, Map.get(attrs, :jti))
    |> put_new(:issuer, Map.get(attrs, :iss))
    |> put_new(:audience, Map.get(attrs, :aud))
    |> put_new(:issued_at, Map.get(attrs, :iat))
    |> put_new(:expires_at, Map.get(attrs, :exp))
  end

  defp normalize_attrs(attrs) when is_list(attrs), do: attrs |> Map.new() |> normalize_attrs()

  defp normalize_attrs(attrs) when is_map(attrs) do
    attrs =
      attrs
      |> Enum.map(fn {key, value} -> {normalize_key(key), value} end)
      |> Map.new()

    {:ok, attrs}
  end

  defp normalize_attrs(_attrs), do: {:error, [attrs: :invalid_attrs]}

  defp normalize_key(key) when is_atom(key), do: key
  defp normalize_key(key) when is_binary(key), do: String.to_atom(key)
  defp normalize_key(key), do: key

  defp normalize_timestamps({:error, errors}, _keys), do: {:error, errors}

  defp normalize_timestamps({:ok, attrs}, keys), do: {:ok, normalize_timestamps(attrs, keys)}

  defp normalize_timestamps(attrs, keys) when is_map(attrs) do
    Enum.reduce(keys, attrs, fn key, acc ->
      case Map.fetch(acc, key) do
        {:ok, nil} ->
          acc

        {:ok, value} ->
          case normalize_timestamp(value) do
            {:ok, normalized} -> Map.put(acc, key, normalized)
            {:error, _reason} -> acc
          end

        :error ->
          acc
      end
    end)
  end

  defp build_and_validate({:error, errors}, _module, _validator, _error_key), do: {:error, errors}

  defp build_and_validate({:ok, attrs}, module, validator, error_key),
    do: build_and_validate(attrs, module, validator, error_key)

  defp build_and_validate(attrs, module, validator, error_key) when is_map(attrs) do
    normalized_attrs = known_struct_attrs(attrs, module)

    with {:ok, contract} <- build_struct(module, normalized_attrs, error_key),
         :ok <- validator.(contract) do
      {:ok, contract}
    end
  end

  defp build_struct(module, attrs, error_key) do
    try do
      {:ok, struct!(module, attrs)}
    rescue
      error in [ArgumentError, KeyError] -> {:error, [{error_key, Exception.message(error)}]}
    end
  end

  defp known_struct_attrs(attrs, module) do
    allowed = module.__struct__() |> Map.keys() |> MapSet.new()

    attrs
    |> Enum.reject(fn {key, _value} -> key == :__struct__ or not MapSet.member?(allowed, key) end)
    |> Map.new()
  end

  defp validate_locator_contract(errors, %StepUpIntentLocator{} = locator) do
    merge_nested_validation(errors, validate_step_up_intent_locator(locator))
  end

  defp validate_locator_contract(errors, _locator), do: [{:locator, :invalid_contract} | errors]

  defp validate_session_renewal_contract(errors, %SessionRenewalInstructions{} = instructions) do
    merge_nested_validation(errors, validate_session_renewal_instructions(instructions))
  end

  defp validate_session_renewal_contract(errors, _instructions),
    do: [{:session_renewal_instructions, :invalid_contract} | errors]

  defp validate_optional_audit_event(errors, nil), do: errors

  defp validate_optional_audit_event(errors, %StepUpAuditEvent{} = event),
    do: merge_nested_validation(errors, validate_step_up_audit_event(event))

  defp validate_optional_audit_event(errors, _event),
    do: [{:audit_event, :invalid_contract} | errors]

  defp validate_session_authority_lane(errors, %SessionAuthorityLane{} = lane),
    do: merge_nested_validation(errors, Contracts.validate_session_authority_lane(lane))

  defp validate_session_authority_lane(errors, _lane),
    do: [{:session_authority_lane, :invalid_contract} | errors]

  defp validate_required_string(errors, field, value) do
    if present_string?(value), do: errors, else: [{field, :required} | errors]
  end

  defp validate_optional_string(errors, _field, nil), do: errors

  defp validate_optional_string(errors, field, value) do
    if present_string?(value), do: errors, else: [{field, {:invalid_string, value}} | errors]
  end

  defp validate_atom_or_string(errors, _field, value)
       when is_atom(value) and value not in [true, false, nil],
       do: errors

  defp validate_atom_or_string(errors, field, value) when is_binary(value) do
    if present_string?(value), do: errors, else: [{field, :required} | errors]
  end

  defp validate_atom_or_string(errors, field, value),
    do: [{field, {:invalid_value, value}} | errors]

  defp validate_enum(errors, field, value, allowed) do
    if value in allowed, do: errors, else: [{field, {:invalid_value, value}} | errors]
  end

  defp validate_optional_enum(errors, _field, nil, _allowed), do: errors

  defp validate_optional_enum(errors, field, value, allowed),
    do: validate_enum(errors, field, value, allowed)

  defp validate_non_negative_integer(errors, _field, value) when is_integer(value) and value >= 0,
    do: errors

  defp validate_non_negative_integer(errors, field, value),
    do: [{field, {:invalid_non_negative_integer, value}} | errors]

  defp validate_optional_non_negative_integer(errors, _field, nil), do: errors

  defp validate_optional_non_negative_integer(errors, field, value),
    do: validate_non_negative_integer(errors, field, value)

  defp validate_positive_integer(errors, _field, value) when is_integer(value) and value > 0,
    do: errors

  defp validate_positive_integer(errors, field, value),
    do: [{field, {:invalid_positive_integer, value}} | errors]

  defp validate_timestamp(errors, field, value) do
    case parse_datetime(value) do
      {:ok, _datetime} -> errors
      {:error, _reason} -> [{field, {:invalid_timestamp, value}} | errors]
    end
  end

  defp validate_optional_timestamp(errors, _field, nil), do: errors

  defp validate_optional_timestamp(errors, field, value),
    do: validate_timestamp(errors, field, value)

  defp validate_boolean(errors, _field, value) when is_boolean(value), do: errors
  defp validate_boolean(errors, field, value), do: [{field, {:invalid_boolean, value}} | errors]

  defp validate_map(errors, _field, value) when is_map(value), do: errors
  defp validate_map(errors, field, value), do: [{field, {:invalid_map, value}} | errors]

  defp validate_optional_map(errors, _field, nil), do: errors
  defp validate_optional_map(errors, field, value), do: validate_map(errors, field, value)

  defp validate_optional_list(errors, _field, nil), do: errors
  defp validate_optional_list(errors, _field, value) when is_list(value), do: errors

  defp validate_optional_list(errors, field, value),
    do: [{field, {:invalid_list, value}} | errors]

  defp validate_session_ops(errors, _field, value) when is_list(value) or is_map(value),
    do: errors

  defp validate_session_ops(errors, field, value),
    do: [{field, {:invalid_session_ops, value}} | errors]

  defp validate_delete_session(errors, value) when is_list(value), do: errors

  defp validate_delete_session(errors, value),
    do: [{:delete_session, {:invalid_session_ops, value}} | errors]

  defp validate_optional_denial_code(errors, nil), do: errors

  defp validate_optional_denial_code(errors, code) when is_binary(code) do
    if String.starts_with?(code, "auth.step_up_intent.") do
      errors
    else
      [{:denial_code, {:invalid_denial_code, code}} | errors]
    end
  end

  defp validate_optional_denial_code(errors, code),
    do: [{:denial_code, {:invalid_denial_code, code}} | errors]

  defp merge_nested_validation(errors, :ok), do: errors
  defp merge_nested_validation(errors, {:error, nested_errors}), do: nested_errors ++ errors

  defp put_new(attrs, _key, nil), do: attrs

  defp put_new(attrs, key, value) do
    if Map.has_key?(attrs, key), do: attrs, else: Map.put(attrs, key, value)
  end

  defp normalize_timestamp(%DateTime{} = datetime),
    do: {:ok, datetime |> DateTime.truncate(:second) |> DateTime.to_iso8601()}

  defp normalize_timestamp(value) when is_binary(value) do
    with {:ok, datetime, _offset} <- DateTime.from_iso8601(value) do
      {:ok, datetime |> DateTime.truncate(:second) |> DateTime.to_iso8601()}
    end
  end

  defp normalize_timestamp(value) when is_integer(value) do
    with {:ok, datetime} <- DateTime.from_unix(value) do
      {:ok, datetime |> DateTime.truncate(:second) |> DateTime.to_iso8601()}
    end
  end

  defp normalize_timestamp(_value), do: {:error, :invalid_datetime}

  defp parse_datetime(%DateTime{} = datetime), do: {:ok, DateTime.truncate(datetime, :second)}

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> {:ok, DateTime.truncate(datetime, :second)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_datetime(_value), do: {:error, :invalid_datetime}

  defp present_string?(value), do: is_binary(value) and String.trim(value) != ""

  defp to_validation_result([]), do: :ok
  defp to_validation_result(errors), do: {:error, Enum.reverse(errors)}
end
