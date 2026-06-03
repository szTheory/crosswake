defmodule Crosswake.Companions.Sigra.Handoff do
  @moduledoc """
  Pure Sigra session handoff contracts.

  Handoff envelopes are bounded client-presented locators. Server-side ticket
  records and projected `SessionAuthorityLane` structs remain the authority
  source of truth for replay, revocation, expiry, binding, and session renewal.
  """

  alias Crosswake.Companions.Sigra.Contracts
  alias Crosswake.Companions.Sigra.Contracts.SessionAuthorityLane

  defmodule HandoffEnvelope do
    @moduledoc """
    Signed-envelope payload after host verification.

    The envelope intentionally carries only low-sensitivity locator and
    correlation claims. It cannot carry identity, credential, session, or
    authority-setting values.
    """
    @enforce_keys [
      :typ,
      :ticket_ref,
      :version,
      :issuer,
      :audience,
      :issued_at,
      :expires_at,
      :intent_kind,
      :route_id,
      :binding_kind
    ]
    defstruct [
      :typ,
      :ticket_ref,
      :version,
      :issuer,
      :audience,
      :issued_at,
      :expires_at,
      :intent_kind,
      :route_id,
      :binding_kind,
      :record_digest,
      :correlation_digest,
      :handoff_transport
    ]
  end

  defmodule HandoffTicketRecord do
    @moduledoc """
    Host-owned server ticket record contract.
    """
    @enforce_keys [
      :ticket_ref,
      :ticket_digest,
      :state,
      :subject_ref,
      :org_id,
      :source_session_ref,
      :expected_session_version,
      :binding_kind,
      :intent_kind,
      :target_route_id,
      :required_assurance_level,
      :required_auth_posture,
      :issued_at,
      :expires_at,
      :audit_correlation_ref,
      :projected_session_authority_lane
    ]
    defstruct [
      :ticket_ref,
      :ticket_digest,
      :state,
      :subject_ref,
      :org_id,
      :source_session_ref,
      :expected_session_version,
      :device_ref,
      :binding_kind,
      :intent_kind,
      :intent_ref,
      :source_route_id,
      :target_route_id,
      :required_assurance_level,
      :required_auth_posture,
      :issued_at,
      :expires_at,
      :consumed_at,
      :revoked_at,
      :revocation_reason,
      :audit_correlation_ref,
      :projected_session_authority_lane
    ]
  end

  defmodule HandoffRedemptionRequest do
    @moduledoc """
    Host redemption input after transport-specific parsing.
    """
    @enforce_keys [:envelope, :expected_route_id, :expected_intent_kind, :request_ref]
    defstruct [
      :envelope,
      :expected_route_id,
      :expected_intent_kind,
      :source_session_ref,
      :expected_session_version,
      :binding_kind,
      :request_ref,
      :handoff_transport,
      :evaluated_at
    ]
  end

  defmodule SessionRenewalInstructions do
    @moduledoc """
    Host-owned Phoenix session renewal instructions.

    Crosswake does not mutate host connections; hosts apply these instructions after
    backend redemption succeeds.
    """
    @enforce_keys [
      :renew_session?,
      :put_session,
      :delete_session,
      :projected_session_ref,
      :projected_session_version
    ]
    defstruct [
      :renew_session?,
      :put_session,
      :delete_session,
      :projected_session_ref,
      :projected_session_version,
      :live_socket_invalidation
    ]
  end

  defmodule HandoffRedemption do
    @moduledoc """
    Successful backend redemption result.
    """
    @enforce_keys [
      :handoff_ref,
      :consumed_at,
      :session_authority_lane,
      :session_renewal_instructions,
      :route_target
    ]
    defstruct [
      :handoff_ref,
      :consumed_at,
      :session_authority_lane,
      :session_projection,
      :session_renewal_instructions,
      :route_target,
      :audit_event
    ]
  end

  defmodule HandoffAuditEvent do
    @moduledoc """
    Append-only handoff lifecycle evidence contract.
    """
    @enforce_keys [
      :event_id,
      :event_type,
      :handoff_ref,
      :state_before,
      :state_after,
      :outcome,
      :occurred_at,
      :route_id,
      :intent_kind,
      :request_ref,
      :actor_kind
    ]
    defstruct [
      :event_id,
      :event_type,
      :handoff_ref,
      :ticket_ref,
      :state_before,
      :state_after,
      :outcome,
      :denial_code,
      :occurred_at,
      :route_id,
      :intent_kind,
      :intent_ref,
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

  @lifecycle_states [:issued, :redeemed, :expired, :revoked]
  @audit_event_types [:issue, :redeem, :revoke, :expire, :deny]
  @audit_outcomes [:allowed, :denied]
  @binding_kinds [:session_route_intent, :session_route_intent_device]

  @envelope_keys [
    :typ,
    :ticket_ref,
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
    :intent_kind,
    :intent,
    :route_id,
    :binding_kind,
    :binding_mode,
    :record_digest,
    :correlation_digest,
    :handoff_transport
  ]

  @forbidden_envelope_keys [
    :subject_ref,
    :actor_id,
    :subject_id,
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
    :state,
    :mfa_level,
    :assurance_level,
    :auth_level,
    :authn_methods,
    :authenticated_at,
    :last_seen_at,
    :idle_expires_at,
    :absolute_expires_at,
    :renew_after,
    :session_authority,
    :session_authority_lane,
    :session_version,
    :revoked_at,
    :access_granted,
    :grant_access
  ]

  @spec lifecycle_states() :: [atom()]
  def lifecycle_states, do: @lifecycle_states

  @spec new_handoff_envelope(map() | keyword()) ::
          {:ok, HandoffEnvelope.t()} | {:error, keyword()}
  def new_handoff_envelope(attrs) do
    attrs
    |> normalize_attrs()
    |> reject_envelope_smuggling()
    |> case do
      {:ok, normalized} ->
        normalized
        |> normalize_envelope_aliases()
        |> normalize_timestamps([:issued_at, :expires_at])
        |> build_and_validate(HandoffEnvelope, &validate_handoff_envelope/1, :handoff_envelope)

      {:error, errors} ->
        {:error, errors}
    end
  end

  @spec new_handoff_ticket_record(map() | keyword()) ::
          {:ok, HandoffTicketRecord.t()} | {:error, keyword()}
  def new_handoff_ticket_record(attrs) do
    attrs
    |> normalize_attrs()
    |> normalize_timestamps([:issued_at, :expires_at, :consumed_at, :revoked_at])
    |> build_and_validate(
      HandoffTicketRecord,
      &validate_handoff_ticket_record/1,
      :handoff_ticket_record
    )
  end

  @spec new_handoff_redemption_request(map() | keyword()) ::
          {:ok, HandoffRedemptionRequest.t()} | {:error, keyword()}
  def new_handoff_redemption_request(attrs) do
    attrs
    |> normalize_attrs()
    |> normalize_timestamps([:evaluated_at])
    |> build_and_validate(
      HandoffRedemptionRequest,
      &validate_handoff_redemption_request/1,
      :handoff_redemption_request
    )
  end

  @spec new_handoff_redemption(map() | keyword()) ::
          {:ok, HandoffRedemption.t()} | {:error, keyword()}
  def new_handoff_redemption(attrs) do
    attrs
    |> normalize_attrs()
    |> normalize_timestamps([:consumed_at])
    |> build_and_validate(
      HandoffRedemption,
      &validate_handoff_redemption/1,
      :handoff_redemption
    )
  end

  @spec new_handoff_audit_event(map() | keyword()) ::
          {:ok, HandoffAuditEvent.t()} | {:error, keyword()}
  def new_handoff_audit_event(attrs) do
    attrs
    |> normalize_attrs()
    |> normalize_timestamps([:occurred_at])
    |> build_and_validate(
      HandoffAuditEvent,
      &validate_handoff_audit_event/1,
      :handoff_audit_event
    )
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

  @spec validate_handoff_envelope(HandoffEnvelope.t()) :: :ok | {:error, keyword()}
  def validate_handoff_envelope(%HandoffEnvelope{} = envelope) do
    []
    |> validate_required_string(:typ, envelope.typ)
    |> validate_required_string(:ticket_ref, envelope.ticket_ref)
    |> validate_required_string(:version, envelope.version)
    |> validate_required_string(:issuer, envelope.issuer)
    |> validate_required_string(:audience, envelope.audience)
    |> validate_timestamp(:issued_at, envelope.issued_at)
    |> validate_timestamp(:expires_at, envelope.expires_at)
    |> validate_atom_or_string(:intent_kind, envelope.intent_kind)
    |> validate_required_string(:route_id, envelope.route_id)
    |> validate_enum(:binding_kind, envelope.binding_kind, @binding_kinds)
    |> validate_optional_string(:record_digest, envelope.record_digest)
    |> validate_optional_string(:correlation_digest, envelope.correlation_digest)
    |> validate_optional_string(:handoff_transport, envelope.handoff_transport)
    |> to_validation_result()
  end

  def validate_handoff_envelope(_envelope), do: {:error, [handoff_envelope: :invalid_contract]}

  @spec validate_handoff_ticket_record(HandoffTicketRecord.t()) :: :ok | {:error, keyword()}
  def validate_handoff_ticket_record(%HandoffTicketRecord{} = record) do
    []
    |> validate_required_string(:ticket_ref, record.ticket_ref)
    |> validate_required_string(:ticket_digest, record.ticket_digest)
    |> validate_enum(:state, record.state, @lifecycle_states)
    |> validate_required_string(:subject_ref, record.subject_ref)
    |> validate_required_string(:org_id, record.org_id)
    |> validate_required_string(:source_session_ref, record.source_session_ref)
    |> validate_non_negative_integer(:expected_session_version, record.expected_session_version)
    |> validate_optional_string(:device_ref, record.device_ref)
    |> validate_enum(:binding_kind, record.binding_kind, @binding_kinds)
    |> validate_atom_or_string(:intent_kind, record.intent_kind)
    |> validate_optional_string(:intent_ref, record.intent_ref)
    |> validate_optional_string(:source_route_id, record.source_route_id)
    |> validate_required_string(:target_route_id, record.target_route_id)
    |> validate_enum(
      :required_assurance_level,
      record.required_assurance_level,
      Contracts.assurance_level_vocabulary()
    )
    |> validate_atom_or_string(:required_auth_posture, record.required_auth_posture)
    |> validate_timestamp(:issued_at, record.issued_at)
    |> validate_timestamp(:expires_at, record.expires_at)
    |> validate_optional_timestamp(:consumed_at, record.consumed_at)
    |> validate_optional_timestamp(:revoked_at, record.revoked_at)
    |> validate_optional_string(:revocation_reason, record.revocation_reason)
    |> validate_required_string(:audit_correlation_ref, record.audit_correlation_ref)
    |> validate_session_authority_lane(record.projected_session_authority_lane)
    |> to_validation_result()
  end

  def validate_handoff_ticket_record(_record),
    do: {:error, [handoff_ticket_record: :invalid_contract]}

  @spec validate_handoff_redemption_request(HandoffRedemptionRequest.t()) ::
          :ok | {:error, keyword()}
  def validate_handoff_redemption_request(%HandoffRedemptionRequest{} = request) do
    []
    |> validate_handoff_envelope_contract(request.envelope)
    |> validate_required_string(:expected_route_id, request.expected_route_id)
    |> validate_atom_or_string(:expected_intent_kind, request.expected_intent_kind)
    |> validate_optional_string(:source_session_ref, request.source_session_ref)
    |> validate_optional_non_negative_integer(
      :expected_session_version,
      request.expected_session_version
    )
    |> validate_optional_enum(:binding_kind, request.binding_kind, @binding_kinds)
    |> validate_required_string(:request_ref, request.request_ref)
    |> validate_optional_string(:handoff_transport, request.handoff_transport)
    |> validate_optional_timestamp(:evaluated_at, request.evaluated_at)
    |> to_validation_result()
  end

  def validate_handoff_redemption_request(_request),
    do: {:error, [handoff_redemption_request: :invalid_contract]}

  @spec validate_handoff_redemption(HandoffRedemption.t()) :: :ok | {:error, keyword()}
  def validate_handoff_redemption(%HandoffRedemption{} = redemption) do
    []
    |> validate_required_string(:handoff_ref, redemption.handoff_ref)
    |> validate_timestamp(:consumed_at, redemption.consumed_at)
    |> validate_session_authority_lane(redemption.session_authority_lane)
    |> validate_session_renewal_contract(redemption.session_renewal_instructions)
    |> validate_map(:route_target, redemption.route_target)
    |> validate_optional_map(:session_projection, redemption.session_projection)
    |> validate_optional_audit_event(redemption.audit_event)
    |> to_validation_result()
  end

  def validate_handoff_redemption(_redemption),
    do: {:error, [handoff_redemption: :invalid_contract]}

  @spec validate_handoff_audit_event(HandoffAuditEvent.t()) :: :ok | {:error, keyword()}
  def validate_handoff_audit_event(%HandoffAuditEvent{} = event) do
    []
    |> validate_required_string(:event_id, event.event_id)
    |> validate_enum(:event_type, event.event_type, @audit_event_types)
    |> validate_required_string(:handoff_ref, event.handoff_ref)
    |> validate_optional_string(:ticket_ref, event.ticket_ref)
    |> validate_optional_enum(:state_before, event.state_before, @lifecycle_states)
    |> validate_optional_enum(:state_after, event.state_after, @lifecycle_states)
    |> validate_enum(:outcome, event.outcome, @audit_outcomes)
    |> validate_optional_denial_code(event.denial_code)
    |> validate_timestamp(:occurred_at, event.occurred_at)
    |> validate_required_string(:route_id, event.route_id)
    |> validate_atom_or_string(:intent_kind, event.intent_kind)
    |> validate_optional_string(:intent_ref, event.intent_ref)
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

  def validate_handoff_audit_event(_event),
    do: {:error, [handoff_audit_event: :invalid_contract]}

  @spec validate_session_renewal_instructions(SessionRenewalInstructions.t()) ::
          :ok | {:error, keyword()}
  def validate_session_renewal_instructions(%SessionRenewalInstructions{} = instructions) do
    []
    |> validate_boolean(:renew_session?, instructions.renew_session?)
    |> validate_session_ops(:put_session, instructions.put_session)
    |> validate_delete_session(instructions.delete_session)
    |> validate_required_string(:projected_session_ref, instructions.projected_session_ref)
    |> validate_non_negative_integer(
      :projected_session_version,
      instructions.projected_session_version
    )
    |> validate_optional_map(:live_socket_invalidation, instructions.live_socket_invalidation)
    |> to_validation_result()
  end

  def validate_session_renewal_instructions(_instructions),
    do: {:error, [session_renewal_instructions: :invalid_contract]}

  defp reject_envelope_smuggling({:error, errors}), do: {:error, errors}

  defp reject_envelope_smuggling({:ok, attrs}) do
    forbidden_errors =
      @forbidden_envelope_keys
      |> Enum.filter(&Map.has_key?(attrs, &1))
      |> Enum.map(&{:handoff_envelope, {&1, :forbidden}})

    allowed = MapSet.new(@envelope_keys)

    unknown_errors =
      attrs
      |> Map.keys()
      |> Enum.reject(&MapSet.member?(allowed, &1))
      |> Enum.map(&{:handoff_envelope, {&1, :unsupported_claim}})

    case forbidden_errors ++ unknown_errors do
      [] -> {:ok, attrs}
      errors -> {:error, errors}
    end
  end

  defp normalize_envelope_aliases(attrs) do
    attrs
    |> put_new(:ticket_ref, Map.get(attrs, :jti))
    |> put_new(:issuer, Map.get(attrs, :iss))
    |> put_new(:audience, Map.get(attrs, :aud))
    |> put_new(:issued_at, Map.get(attrs, :iat))
    |> put_new(:expires_at, Map.get(attrs, :exp))
    |> put_new(:intent_kind, Map.get(attrs, :intent))
    |> put_new(:binding_kind, Map.get(attrs, :binding_mode))
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

  defp normalize_timestamps({:ok, attrs}, keys) do
    {:ok, normalize_timestamps(attrs, keys)}
  end

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

  defp validate_handoff_envelope_contract(errors, %HandoffEnvelope{} = envelope) do
    merge_nested_validation(errors, validate_handoff_envelope(envelope))
  end

  defp validate_handoff_envelope_contract(errors, _envelope),
    do: [{:envelope, :invalid_contract} | errors]

  defp validate_session_renewal_contract(errors, %SessionRenewalInstructions{} = instructions) do
    merge_nested_validation(errors, validate_session_renewal_instructions(instructions))
  end

  defp validate_session_renewal_contract(errors, _instructions),
    do: [{:session_renewal_instructions, :invalid_contract} | errors]

  defp validate_optional_audit_event(errors, nil), do: errors

  defp validate_optional_audit_event(errors, %HandoffAuditEvent{} = event),
    do: merge_nested_validation(errors, validate_handoff_audit_event(event))

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
    if value in allowed do
      errors
    else
      [{field, {:invalid_value, value}} | errors]
    end
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
    if String.starts_with?(code, "auth.handoff.") do
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
