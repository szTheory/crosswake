defmodule Crosswake.Companions.Sigra.AuthReturn do
  @moduledoc """
  Pure Sigra auth-return boundary contracts.

  OAuth callbacks, passkey assertions, native deep links, and shell bridge
  events are evidence only. Host-owned return attempt records and projected
  `SessionAuthorityLane` structs remain the authority source of truth for replay,
  expiry, route binding, and session promotion.
  """

  alias Crosswake.Companions.Sigra.Contracts
  alias Crosswake.Companions.Sigra.Contracts.SessionAuthorityLane
  alias Crosswake.Companions.Sigra.Handoff.SessionRenewalInstructions

  defmodule OAuthEvidence do
    @moduledoc "Provider-neutral OAuth/OIDC return evidence posture."
    @enforce_keys [:provider_kind, :state, :pkce, :redirect, :replay]
    defstruct [
      :provider_kind,
      :issuer,
      :state,
      :nonce,
      :pkce,
      :redirect,
      :replay,
      :authorization_code_ref,
      :id_token_ref,
      :acr,
      :auth_time
    ]
  end

  defmodule PasskeyEvidence do
    @moduledoc "Provider-neutral passkey/WebAuthn assertion evidence posture."
    @enforce_keys [:challenge, :origin, :rp_id, :user_verification, :replay]
    defstruct [
      :challenge,
      :origin,
      :rp_id,
      :user_verification,
      :replay,
      :sign_count_posture,
      :credential_ref
    ]
  end

  defmodule NativeEvidence do
    @moduledoc "Native auth-return evidence posture after transport parsing."
    @enforce_keys [:transport, :platform, :link_verification, :callback_binding, :replay]
    defstruct [
      :transport,
      :platform,
      :link_verification,
      :callback_binding,
      :replay,
      :native_assertion_ref
    ]
  end

  defmodule Envelope do
    @moduledoc """
    Shared outer auth-return envelope.

    The envelope carries route-local binding and validation posture. Nested
    evidence carries protocol-specific facts. Neither can grant authority.
    """
    @enforce_keys [
      :typ,
      :return_ref,
      :version,
      :issuer,
      :audience,
      :kind,
      :route_id,
      :return_route_id,
      :transport,
      :issued_at,
      :expires_at,
      :replay_posture,
      :link_verification,
      :validation_posture,
      :evidence
    ]
    defstruct [
      :typ,
      :return_ref,
      :version,
      :issuer,
      :audience,
      :kind,
      :route_id,
      :source_route_id,
      :return_route_id,
      :transport,
      :expected_callback,
      :received_callback,
      :issued_at,
      :expires_at,
      :replay_posture,
      :link_verification,
      :validation_posture,
      :state_ref,
      :record_digest,
      :correlation_digest,
      :evidence
    ]
  end

  defmodule AttemptRecord do
    @moduledoc "Host-owned authoritative auth-return attempt record contract."
    @enforce_keys [
      :attempt_ref,
      :attempt_digest,
      :kind,
      :state,
      :subject_ref,
      :org_id,
      :source_session_ref,
      :expected_session_version,
      :route_id,
      :return_route_id,
      :transport,
      :link_verification,
      :issued_at,
      :expires_at,
      :audit_correlation_ref,
      :projected_session_authority_lane
    ]
    defstruct [
      :attempt_ref,
      :attempt_digest,
      :kind,
      :state,
      :subject_ref,
      :org_id,
      :source_session_ref,
      :expected_session_version,
      :device_ref,
      :route_id,
      :return_route_id,
      :transport,
      :link_verification,
      :state_digest,
      :nonce_digest,
      :pkce_challenge_digest,
      :pkce_method,
      :expected_callback,
      :provider_audience,
      :issued_at,
      :expires_at,
      :consumed_at,
      :revoked_at,
      :revocation_reason,
      :audit_correlation_ref,
      :projected_session_authority_lane,
      return_params: %{}
    ]
  end

  defmodule ValidationRequest do
    @moduledoc "Host validation input after transport-specific parsing."
    @enforce_keys [
      :envelope,
      :expected_route_id,
      :expected_return_route_id,
      :expected_kind,
      :request_ref
    ]
    defstruct [
      :envelope,
      :expected_route_id,
      :expected_return_route_id,
      :expected_kind,
      :source_session_ref,
      :expected_session_version,
      :request_ref,
      :evaluated_at
    ]
  end

  defmodule Completion do
    @moduledoc "Successful backend auth-return validation result."
    @enforce_keys [
      :auth_return_ref,
      :consumed_at,
      :session_authority_lane,
      :session_renewal_instructions,
      :route_target
    ]
    defstruct [
      :auth_return_ref,
      :consumed_at,
      :session_authority_lane,
      :session_projection,
      :session_renewal_instructions,
      :route_target,
      :audit_event
    ]
  end

  defmodule AuditEvent do
    @moduledoc "Append-only auth-return lifecycle evidence contract."
    @enforce_keys [
      :event_id,
      :event_type,
      :auth_return_ref,
      :state_before,
      :state_after,
      :outcome,
      :occurred_at,
      :route_id,
      :kind,
      :request_ref,
      :actor_kind
    ]
    defstruct [
      :event_id,
      :event_type,
      :auth_return_ref,
      :attempt_ref,
      :state_before,
      :state_after,
      :outcome,
      :denial_code,
      :occurred_at,
      :route_id,
      :kind,
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

  @kinds [:oauth, :passkey, :native_auth]
  @transports [:http_callback, :verified_https_link, :custom_scheme, :bridge_event]
  @link_verification [:verified, :unverified, :missing, :stale, :unknown, :not_applicable]
  @validation_states [:matched, :present, :verified, :fresh, :not_seen, :unavailable]
  @replay_postures [:server_record_required, :not_seen, :seen, :unknown]
  @lifecycle_states [:issued, :consumed, :expired, :revoked]
  @audit_event_types [:issue, :validate, :consume, :expire, :revoke, :deny]
  @audit_outcomes [:allowed, :denied]

  @envelope_keys [
    :typ,
    :return_ref,
    :jti,
    :version,
    :issuer,
    :iss,
    :audience,
    :aud,
    :kind,
    :route_id,
    :source_route_id,
    :return_route_id,
    :transport,
    :expected_callback,
    :received_callback,
    :issued_at,
    :iat,
    :expires_at,
    :exp,
    :replay_posture,
    :link_verification,
    :validation_posture,
    :state_ref,
    :record_digest,
    :correlation_digest,
    :evidence
  ]

  @forbidden_envelope_keys [
    :authorization_code,
    :access_token,
    :refresh_token,
    :id_token,
    :provider_payload,
    :credential_id,
    :passkey_credential_id,
    :authenticator_data,
    :client_data_json,
    :pkce_verifier,
    :nonce,
    :csrf_token,
    :return_to,
    :session_ref,
    :session_id,
    :subject_ref,
    :actor_id,
    :org_id,
    :device_ref,
    :authority_state,
    :assurance_level,
    :authn_methods,
    :authenticated_at,
    :session_authority_lane,
    :session_version,
    :access_granted,
    :grant_access
  ]

  @spec kinds() :: [atom()]
  def kinds, do: @kinds

  @spec transports() :: [atom()]
  def transports, do: @transports

  @spec link_verification_values() :: [atom()]
  def link_verification_values, do: @link_verification

  @spec lifecycle_states() :: [atom()]
  def lifecycle_states, do: @lifecycle_states

  @spec new_oauth_evidence(map() | keyword()) :: {:ok, OAuthEvidence.t()} | {:error, keyword()}
  def new_oauth_evidence(attrs),
    do:
      attrs
      |> normalize_attrs()
      |> build_and_validate(OAuthEvidence, &validate_oauth_evidence/1, :oauth_evidence)

  @spec new_passkey_evidence(map() | keyword()) ::
          {:ok, PasskeyEvidence.t()} | {:error, keyword()}
  def new_passkey_evidence(attrs),
    do:
      attrs
      |> normalize_attrs()
      |> build_and_validate(PasskeyEvidence, &validate_passkey_evidence/1, :passkey_evidence)

  @spec new_native_evidence(map() | keyword()) :: {:ok, NativeEvidence.t()} | {:error, keyword()}
  def new_native_evidence(attrs),
    do:
      attrs
      |> normalize_attrs()
      |> build_and_validate(NativeEvidence, &validate_native_evidence/1, :native_evidence)

  @spec new_envelope(map() | keyword()) :: {:ok, Envelope.t()} | {:error, keyword()}
  def new_envelope(attrs) do
    attrs
    |> normalize_attrs()
    |> reject_envelope_smuggling()
    |> case do
      {:ok, normalized} ->
        normalized
        |> normalize_envelope_aliases()
        |> normalize_timestamps([:issued_at, :expires_at])
        |> normalize_evidence()
        |> build_and_validate(Envelope, &validate_envelope/1, :auth_return_envelope)

      {:error, errors} ->
        {:error, errors}
    end
  end

  @spec new_attempt_record(map() | keyword()) :: {:ok, AttemptRecord.t()} | {:error, keyword()}
  def new_attempt_record(attrs) do
    attrs
    |> normalize_attrs()
    |> normalize_timestamps([:issued_at, :expires_at, :consumed_at, :revoked_at])
    |> build_and_validate(AttemptRecord, &validate_attempt_record/1, :auth_return_attempt_record)
  end

  @spec new_validation_request(map() | keyword()) ::
          {:ok, ValidationRequest.t()} | {:error, keyword()}
  def new_validation_request(attrs) do
    attrs
    |> normalize_attrs()
    |> normalize_timestamps([:evaluated_at])
    |> build_and_validate(
      ValidationRequest,
      &validate_validation_request/1,
      :auth_return_validation_request
    )
  end

  @spec new_completion(map() | keyword()) :: {:ok, Completion.t()} | {:error, keyword()}
  def new_completion(attrs) do
    attrs
    |> normalize_attrs()
    |> normalize_timestamps([:consumed_at])
    |> build_and_validate(Completion, &validate_completion/1, :auth_return_completion)
  end

  @spec new_audit_event(map() | keyword()) :: {:ok, AuditEvent.t()} | {:error, keyword()}
  def new_audit_event(attrs) do
    attrs
    |> normalize_attrs()
    |> normalize_timestamps([:occurred_at])
    |> build_and_validate(AuditEvent, &validate_audit_event/1, :auth_return_audit_event)
  end

  @spec validate_oauth_evidence(OAuthEvidence.t()) :: :ok | {:error, keyword()}
  def validate_oauth_evidence(%OAuthEvidence{} = evidence) do
    []
    |> validate_atom_or_string(:provider_kind, evidence.provider_kind)
    |> validate_optional_string(:issuer, evidence.issuer)
    |> validate_enum(:state, evidence.state, @validation_states)
    |> validate_optional_enum(:nonce, evidence.nonce, @validation_states)
    |> validate_enum(:pkce, evidence.pkce, @validation_states)
    |> validate_enum(:redirect, evidence.redirect, @validation_states)
    |> validate_enum(:replay, evidence.replay, @replay_postures ++ @validation_states)
    |> validate_optional_string(:authorization_code_ref, evidence.authorization_code_ref)
    |> validate_optional_string(:id_token_ref, evidence.id_token_ref)
    |> validate_optional_string(:acr, evidence.acr)
    |> validate_optional_timestamp(:auth_time, evidence.auth_time)
    |> to_validation_result()
  end

  def validate_oauth_evidence(_evidence), do: {:error, [oauth_evidence: :invalid_contract]}

  @spec validate_passkey_evidence(PasskeyEvidence.t()) :: :ok | {:error, keyword()}
  def validate_passkey_evidence(%PasskeyEvidence{} = evidence) do
    []
    |> validate_enum(:challenge, evidence.challenge, @validation_states)
    |> validate_enum(:origin, evidence.origin, @validation_states)
    |> validate_enum(:rp_id, evidence.rp_id, @validation_states)
    |> validate_enum(:user_verification, evidence.user_verification, @validation_states)
    |> validate_enum(:replay, evidence.replay, @replay_postures ++ @validation_states)
    |> validate_optional_atom_or_string(:sign_count_posture, evidence.sign_count_posture)
    |> validate_optional_string(:credential_ref, evidence.credential_ref)
    |> to_validation_result()
  end

  def validate_passkey_evidence(_evidence), do: {:error, [passkey_evidence: :invalid_contract]}

  @spec validate_native_evidence(NativeEvidence.t()) :: :ok | {:error, keyword()}
  def validate_native_evidence(%NativeEvidence{} = evidence) do
    []
    |> validate_enum(:transport, evidence.transport, @transports)
    |> validate_atom_or_string(:platform, evidence.platform)
    |> validate_enum(:link_verification, evidence.link_verification, @link_verification)
    |> validate_enum(:callback_binding, evidence.callback_binding, @validation_states)
    |> validate_enum(:replay, evidence.replay, @replay_postures ++ @validation_states)
    |> validate_optional_string(:native_assertion_ref, evidence.native_assertion_ref)
    |> to_validation_result()
  end

  def validate_native_evidence(_evidence), do: {:error, [native_evidence: :invalid_contract]}

  @spec validate_envelope(Envelope.t()) :: :ok | {:error, keyword()}
  def validate_envelope(%Envelope{} = envelope) do
    []
    |> validate_required_string(:typ, envelope.typ)
    |> validate_required_string(:return_ref, envelope.return_ref)
    |> validate_required_string(:version, envelope.version)
    |> validate_required_string(:issuer, envelope.issuer)
    |> validate_required_string(:audience, envelope.audience)
    |> validate_enum(:kind, envelope.kind, @kinds)
    |> validate_required_string(:route_id, envelope.route_id)
    |> validate_optional_string(:source_route_id, envelope.source_route_id)
    |> validate_required_string(:return_route_id, envelope.return_route_id)
    |> validate_enum(:transport, envelope.transport, @transports)
    |> validate_optional_string(:expected_callback, envelope.expected_callback)
    |> validate_optional_string(:received_callback, envelope.received_callback)
    |> validate_timestamp(:issued_at, envelope.issued_at)
    |> validate_timestamp(:expires_at, envelope.expires_at)
    |> validate_enum(:replay_posture, envelope.replay_posture, @replay_postures)
    |> validate_enum(:link_verification, envelope.link_verification, @link_verification)
    |> validate_map(:validation_posture, envelope.validation_posture)
    |> validate_optional_string(:state_ref, envelope.state_ref)
    |> validate_optional_string(:record_digest, envelope.record_digest)
    |> validate_optional_string(:correlation_digest, envelope.correlation_digest)
    |> validate_evidence_for_kind(envelope.kind, envelope.evidence)
    |> validate_sensitive_transport(envelope)
    |> to_validation_result()
  end

  def validate_envelope(_envelope), do: {:error, [auth_return_envelope: :invalid_contract]}

  @spec validate_attempt_record(AttemptRecord.t()) :: :ok | {:error, keyword()}
  def validate_attempt_record(%AttemptRecord{} = record) do
    []
    |> validate_required_string(:attempt_ref, record.attempt_ref)
    |> validate_required_string(:attempt_digest, record.attempt_digest)
    |> validate_enum(:kind, record.kind, @kinds)
    |> validate_enum(:state, record.state, @lifecycle_states)
    |> validate_required_string(:subject_ref, record.subject_ref)
    |> validate_optional_string(:org_id, record.org_id)
    |> validate_required_string(:source_session_ref, record.source_session_ref)
    |> validate_non_negative_integer(:expected_session_version, record.expected_session_version)
    |> validate_optional_string(:device_ref, record.device_ref)
    |> validate_required_string(:route_id, record.route_id)
    |> validate_required_string(:return_route_id, record.return_route_id)
    |> validate_enum(:transport, record.transport, @transports)
    |> validate_enum(:link_verification, record.link_verification, @link_verification)
    |> validate_optional_string(:state_digest, record.state_digest)
    |> validate_optional_string(:nonce_digest, record.nonce_digest)
    |> validate_optional_string(:pkce_challenge_digest, record.pkce_challenge_digest)
    |> validate_optional_atom_or_string(:pkce_method, record.pkce_method)
    |> validate_optional_string(:expected_callback, record.expected_callback)
    |> validate_optional_string(:provider_audience, record.provider_audience)
    |> validate_timestamp(:issued_at, record.issued_at)
    |> validate_timestamp(:expires_at, record.expires_at)
    |> validate_optional_timestamp(:consumed_at, record.consumed_at)
    |> validate_optional_timestamp(:revoked_at, record.revoked_at)
    |> validate_optional_string(:revocation_reason, record.revocation_reason)
    |> validate_required_string(:audit_correlation_ref, record.audit_correlation_ref)
    |> validate_session_authority_lane(record.projected_session_authority_lane)
    |> validate_map(:return_params, record.return_params)
    |> to_validation_result()
  end

  def validate_attempt_record(_record),
    do: {:error, [auth_return_attempt_record: :invalid_contract]}

  @spec validate_validation_request(ValidationRequest.t()) :: :ok | {:error, keyword()}
  def validate_validation_request(%ValidationRequest{} = request) do
    []
    |> validate_envelope_contract(request.envelope)
    |> validate_required_string(:expected_route_id, request.expected_route_id)
    |> validate_required_string(:expected_return_route_id, request.expected_return_route_id)
    |> validate_enum(:expected_kind, request.expected_kind, @kinds)
    |> validate_optional_string(:source_session_ref, request.source_session_ref)
    |> validate_optional_non_negative_integer(
      :expected_session_version,
      request.expected_session_version
    )
    |> validate_required_string(:request_ref, request.request_ref)
    |> validate_optional_timestamp(:evaluated_at, request.evaluated_at)
    |> to_validation_result()
  end

  def validate_validation_request(_request),
    do: {:error, [auth_return_validation_request: :invalid_contract]}

  @spec validate_completion(Completion.t()) :: :ok | {:error, keyword()}
  def validate_completion(%Completion{} = completion) do
    []
    |> validate_required_string(:auth_return_ref, completion.auth_return_ref)
    |> validate_timestamp(:consumed_at, completion.consumed_at)
    |> validate_session_authority_lane(completion.session_authority_lane)
    |> validate_session_renewal_contract(completion.session_renewal_instructions)
    |> validate_map(:route_target, completion.route_target)
    |> validate_optional_map(:session_projection, completion.session_projection)
    |> validate_optional_audit_event(completion.audit_event)
    |> to_validation_result()
  end

  def validate_completion(_completion), do: {:error, [auth_return_completion: :invalid_contract]}

  @spec validate_audit_event(AuditEvent.t()) :: :ok | {:error, keyword()}
  def validate_audit_event(%AuditEvent{} = event) do
    []
    |> validate_required_string(:event_id, event.event_id)
    |> validate_enum(:event_type, event.event_type, @audit_event_types)
    |> validate_required_string(:auth_return_ref, event.auth_return_ref)
    |> validate_optional_string(:attempt_ref, event.attempt_ref)
    |> validate_optional_enum(:state_before, event.state_before, @lifecycle_states)
    |> validate_optional_enum(:state_after, event.state_after, @lifecycle_states)
    |> validate_enum(:outcome, event.outcome, @audit_outcomes)
    |> validate_optional_denial_code(event.denial_code)
    |> validate_timestamp(:occurred_at, event.occurred_at)
    |> validate_required_string(:route_id, event.route_id)
    |> validate_enum(:kind, event.kind, @kinds)
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

  def validate_audit_event(_event), do: {:error, [auth_return_audit_event: :invalid_contract]}

  defp normalize_evidence({:error, errors}), do: {:error, errors}

  defp normalize_evidence(%{} = attrs), do: normalize_evidence({:ok, attrs})

  defp normalize_evidence({:ok, %{kind: :oauth, evidence: evidence} = attrs}) do
    with {:ok, evidence} <- ensure_evidence(evidence, OAuthEvidence, &new_oauth_evidence/1) do
      {:ok, Map.put(attrs, :evidence, evidence)}
    end
  end

  defp normalize_evidence({:ok, %{kind: :passkey, evidence: evidence} = attrs}) do
    with {:ok, evidence} <- ensure_evidence(evidence, PasskeyEvidence, &new_passkey_evidence/1) do
      {:ok, Map.put(attrs, :evidence, evidence)}
    end
  end

  defp normalize_evidence({:ok, %{kind: :native_auth, evidence: evidence} = attrs}) do
    with {:ok, evidence} <- ensure_evidence(evidence, NativeEvidence, &new_native_evidence/1) do
      {:ok, Map.put(attrs, :evidence, evidence)}
    end
  end

  defp normalize_evidence({:ok, attrs}), do: {:ok, attrs}

  defp ensure_evidence(%module{} = evidence, module, _builder), do: {:ok, evidence}

  defp ensure_evidence(evidence, _module, builder) when is_map(evidence) or is_list(evidence),
    do: builder.(evidence)

  defp ensure_evidence(_evidence, _module, _builder), do: {:error, [evidence: :invalid_contract]}

  defp reject_envelope_smuggling({:error, errors}), do: {:error, errors}

  defp reject_envelope_smuggling({:ok, attrs}) do
    forbidden_errors =
      @forbidden_envelope_keys
      |> Enum.filter(&Map.has_key?(attrs, &1))
      |> Enum.map(&{:auth_return_envelope, {&1, :forbidden}})

    allowed = MapSet.new(@envelope_keys)

    unknown_errors =
      attrs
      |> Map.keys()
      |> Enum.reject(&MapSet.member?(allowed, &1))
      |> Enum.map(&{:auth_return_envelope, {&1, :unsupported_claim}})

    case forbidden_errors ++ unknown_errors do
      [] -> {:ok, attrs}
      errors -> {:error, errors}
    end
  end

  defp normalize_envelope_aliases(attrs) do
    attrs
    |> put_new(:return_ref, Map.get(attrs, :jti))
    |> put_new(:issuer, Map.get(attrs, :iss))
    |> put_new(:audience, Map.get(attrs, :aud))
    |> put_new(:issued_at, Map.get(attrs, :iat))
    |> put_new(:expires_at, Map.get(attrs, :exp))
  end

  defp validate_evidence_for_kind(errors, :oauth, %OAuthEvidence{} = evidence),
    do: merge_nested_validation(errors, validate_oauth_evidence(evidence))

  defp validate_evidence_for_kind(errors, :passkey, %PasskeyEvidence{} = evidence),
    do: merge_nested_validation(errors, validate_passkey_evidence(evidence))

  defp validate_evidence_for_kind(errors, :native_auth, %NativeEvidence{} = evidence),
    do: merge_nested_validation(errors, validate_native_evidence(evidence))

  defp validate_evidence_for_kind(errors, _kind, _evidence),
    do: [{:evidence, :invalid_contract} | errors]

  defp validate_sensitive_transport(errors, %Envelope{
         link_verification: link_verification,
         transport: transport
       }) do
    cond do
      transport == :verified_https_link and link_verification != :verified ->
        [{:link_verification, :verified_required_for_verified_https_link} | errors]

      transport == :custom_scheme and link_verification == :verified ->
        [{:link_verification, :custom_scheme_cannot_be_verified_link} | errors]

      true ->
        errors
    end
  end

  defp validate_envelope_contract(errors, %Envelope{} = envelope),
    do: merge_nested_validation(errors, validate_envelope(envelope))

  defp validate_envelope_contract(errors, _envelope),
    do: [{:envelope, :invalid_contract} | errors]

  defp validate_session_renewal_contract(errors, %SessionRenewalInstructions{} = instructions),
    do:
      merge_nested_validation(
        errors,
        Crosswake.Companions.Sigra.Handoff.validate_session_renewal_instructions(instructions)
      )

  defp validate_session_renewal_contract(errors, _instructions),
    do: [{:session_renewal_instructions, :invalid_contract} | errors]

  defp validate_optional_audit_event(errors, nil), do: errors

  defp validate_optional_audit_event(errors, %AuditEvent{} = event),
    do: merge_nested_validation(errors, validate_audit_event(event))

  defp validate_optional_audit_event(errors, _event),
    do: [{:audit_event, :invalid_contract} | errors]

  defp validate_session_authority_lane(errors, %SessionAuthorityLane{} = lane),
    do: merge_nested_validation(errors, Contracts.validate_session_authority_lane(lane))

  defp validate_session_authority_lane(errors, _lane),
    do: [{:session_authority_lane, :invalid_contract} | errors]

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

  defp validate_optional_atom_or_string(errors, _field, nil), do: errors

  defp validate_optional_atom_or_string(errors, field, value),
    do: validate_atom_or_string(errors, field, value)

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

  defp validate_timestamp(errors, field, value) do
    case parse_datetime(value) do
      {:ok, _datetime} -> errors
      {:error, _reason} -> [{field, {:invalid_timestamp, value}} | errors]
    end
  end

  defp validate_optional_timestamp(errors, _field, nil), do: errors

  defp validate_optional_timestamp(errors, field, value),
    do: validate_timestamp(errors, field, value)

  defp validate_map(errors, _field, value) when is_map(value), do: errors
  defp validate_map(errors, field, value), do: [{field, {:invalid_map, value}} | errors]

  defp validate_optional_map(errors, _field, nil), do: errors
  defp validate_optional_map(errors, field, value), do: validate_map(errors, field, value)

  defp validate_optional_list(errors, _field, nil), do: errors
  defp validate_optional_list(errors, _field, value) when is_list(value), do: errors

  defp validate_optional_list(errors, field, value),
    do: [{field, {:invalid_list, value}} | errors]

  defp validate_optional_denial_code(errors, nil), do: errors

  defp validate_optional_denial_code(errors, code) when is_binary(code) do
    if String.starts_with?(code, "auth.return.") do
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
