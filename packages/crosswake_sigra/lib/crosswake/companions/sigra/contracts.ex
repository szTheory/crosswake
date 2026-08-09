defmodule Crosswake.Companions.Sigra.Contracts do
  @moduledoc """
  Typed auth contracts for the Sigra backend seam.

  Backend-projected authority and client/device evidence are separated by design.
  Evidence may inform projection later, but cannot set route activation authority.
  """

  defmodule AuthContext do
    @moduledoc """
    Backend-projected auth context used for route-level auth checks.
    """
    @enforce_keys [:actor_id, :mfa_level, :auth_age]
    defstruct [:actor_id, :org_id, :mfa_level, :auth_age, :session_authority_lane, :as_of]

    @type t :: %__MODULE__{
            actor_id: String.t(),
            org_id: String.t() | nil,
            mfa_level: atom(),
            auth_age: non_neg_integer(),
            session_authority_lane:
              Crosswake.Companions.Sigra.Contracts.SessionAuthorityLane.t() | nil,
            as_of: String.t() | nil
          }
  end

  defmodule SessionAuthorityLane do
    @moduledoc """
    Backend-owned session authority facts.
    """
    @enforce_keys [
      :session_ref,
      :subject_ref,
      :state,
      :assurance_level,
      :authn_methods,
      :authenticated_at,
      :last_seen_at,
      :idle_expires_at,
      :absolute_expires_at,
      :session_version,
      :as_of
    ]
    defstruct [
      :session_ref,
      :subject_ref,
      :org_id,
      :state,
      :assurance_level,
      :authn_methods,
      :authenticated_at,
      :last_seen_at,
      :idle_expires_at,
      :absolute_expires_at,
      :renew_after,
      :session_version,
      :revoked_at,
      :as_of,
      :authority_state,
      :mfa_level,
      :auth_age_seconds,
      :session_id,
      remembered: false,
      cached: false
    ]

    @type authority_state :: :active | :step_up_required | :suspended | :expired | :revoked

    @type t :: %__MODULE__{
            session_ref: String.t(),
            subject_ref: String.t(),
            org_id: String.t() | nil,
            state: authority_state(),
            assurance_level: atom(),
            authn_methods: [atom()],
            authenticated_at: String.t(),
            last_seen_at: String.t(),
            idle_expires_at: String.t(),
            absolute_expires_at: String.t(),
            renew_after: String.t() | nil,
            remembered: boolean(),
            cached: boolean(),
            session_version: non_neg_integer(),
            revoked_at: String.t() | nil,
            as_of: String.t(),
            authority_state: authority_state() | nil,
            mfa_level: atom() | nil,
            auth_age_seconds: non_neg_integer() | nil,
            session_id: String.t() | nil
          }
  end

  defmodule StepUpChallenge do
    @moduledoc """
    Reference-only step-up requirement state.
    """
    @enforce_keys [:challenge_id, :required_mfa_level, :max_auth_age_seconds, :reason]
    defstruct [
      :challenge_id,
      :required_mfa_level,
      :max_auth_age_seconds,
      :reason,
      :issued_at,
      :expires_at
    ]

    @type t :: %__MODULE__{
            challenge_id: String.t(),
            required_mfa_level: atom(),
            max_auth_age_seconds: pos_integer(),
            reason: atom() | String.t(),
            issued_at: String.t() | nil,
            expires_at: String.t() | nil
          }
  end

  @mfa_level_vocabulary [:none, :password, :mfa, :phishing_resistant]
  @mfa_level_indexes @mfa_level_vocabulary |> Enum.with_index() |> Map.new()
  @authority_state_vocabulary [:active, :step_up_required, :suspended, :expired, :revoked]
  @forbidden_evidence_authority_keys [
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
    :revocation,
    :access_granted,
    :grant_access,
    :entitlement_granted
  ]

  @spec mfa_level_vocabulary() :: [atom()]
  def mfa_level_vocabulary, do: @mfa_level_vocabulary

  @spec authority_state_vocabulary() :: [atom()]
  def authority_state_vocabulary, do: @authority_state_vocabulary

  @spec assurance_level_vocabulary() :: [atom()]
  def assurance_level_vocabulary, do: @mfa_level_vocabulary

  @spec mfa_level_meets?(atom(), atom()) :: boolean()
  def mfa_level_meets?(current, required), do: assurance_level_meets?(current, required)

  @spec assurance_level_meets?(atom(), atom()) :: boolean()
  def assurance_level_meets?(current, required) do
    with {:ok, current_index} <- mfa_level_index(current),
         {:ok, required_index} <- mfa_level_index(required) do
      current_index >= required_index
    else
      _ -> false
    end
  end

  @spec auth_age_seconds(AuthContext.t()) :: non_neg_integer()
  def auth_age_seconds(%AuthContext{
        session_authority_lane: %SessionAuthorityLane{} = lane,
        as_of: as_of
      }) do
    lane_auth_age_seconds(lane, as_of)
  end

  def auth_age_seconds(%AuthContext{auth_age: auth_age})
      when is_integer(auth_age) and auth_age >= 0,
      do: auth_age

  def auth_age_seconds(%AuthContext{auth_age: auth_age}) when is_binary(auth_age) do
    case Integer.parse(auth_age) do
      {seconds, ""} when seconds >= 0 -> seconds
      _ -> 0
    end
  end

  def auth_age_seconds(%AuthContext{}), do: 0

  @spec new_auth_context(map() | keyword()) :: {:ok, AuthContext.t()} | {:error, keyword()}
  def new_auth_context(attrs) when is_list(attrs), do: attrs |> Map.new() |> new_auth_context()

  def new_auth_context(attrs) when is_map(attrs) do
    attrs
    |> normalize_auth_context_attrs()
    |> build_and_validate(AuthContext, &validate_auth_context/1, :auth_context)
  end

  def new_auth_context(attrs),
    do: build_and_validate(attrs, AuthContext, &validate_auth_context/1, :auth_context)

  @spec new_session_authority_lane(map() | keyword()) ::
          {:ok, SessionAuthorityLane.t()} | {:error, keyword()}
  def new_session_authority_lane(attrs),
    do:
      build_and_validate(
        attrs,
        SessionAuthorityLane,
        &validate_session_authority_lane/1,
        :session_authority_lane
      )

  @spec new_step_up_challenge(map() | keyword()) ::
          {:ok, StepUpChallenge.t()} | {:error, keyword()}
  def new_step_up_challenge(attrs),
    do:
      build_and_validate(
        attrs,
        StepUpChallenge,
        &validate_step_up_challenge/1,
        :step_up_challenge
      )

  @spec validate_auth_context(AuthContext.t()) :: :ok | {:error, keyword()}
  def validate_auth_context(%AuthContext{} = auth_context) do
    errors =
      []
      |> validate_required_string(:actor_id, auth_context.actor_id)
      |> validate_optional_string(:org_id, auth_context.org_id)
      |> validate_mfa_level(:mfa_level, auth_context.mfa_level)
      |> validate_non_negative_integer(:auth_age, auth_age_seconds(auth_context))

    case auth_context.session_authority_lane do
      nil ->
        to_validation_result(errors)

      %SessionAuthorityLane{} = lane ->
        errors
        |> merge_nested_validation(validate_session_authority_lane(lane))
        |> to_validation_result()

      _other ->
        {:error, [{:session_authority_lane, :invalid_contract} | errors] |> Enum.reverse()}
    end
  end

  def validate_auth_context(_auth_context), do: {:error, [auth_context: :invalid_contract]}

  @spec validate_session_authority_lane(SessionAuthorityLane.t()) :: :ok | {:error, keyword()}
  def validate_session_authority_lane(%SessionAuthorityLane{} = lane) do
    []
    |> validate_required_string(:session_ref, lane.session_ref)
    |> validate_required_string(:subject_ref, lane.subject_ref)
    |> validate_optional_string(:org_id, lane.org_id)
    |> validate_authority_state(lane.state)
    |> validate_mfa_level(:assurance_level, lane.assurance_level)
    |> validate_authn_methods(lane.authn_methods)
    |> validate_timestamp(:authenticated_at, lane.authenticated_at)
    |> validate_timestamp(:last_seen_at, lane.last_seen_at)
    |> validate_timestamp(:idle_expires_at, lane.idle_expires_at)
    |> validate_timestamp(:absolute_expires_at, lane.absolute_expires_at)
    |> validate_optional_timestamp(:renew_after, lane.renew_after)
    |> validate_optional_timestamp(:revoked_at, lane.revoked_at)
    |> validate_timestamp(:as_of, lane.as_of)
    |> validate_non_negative_integer(:session_version, lane.session_version)
    |> validate_boolean(:remembered, lane.remembered)
    |> validate_boolean(:cached, lane.cached)
    |> to_validation_result()
  end

  def validate_session_authority_lane(_lane),
    do: {:error, [session_authority_lane: :invalid_contract]}

  @spec validate_step_up_challenge(StepUpChallenge.t()) :: :ok | {:error, keyword()}
  def validate_step_up_challenge(%StepUpChallenge{} = challenge) do
    []
    |> validate_required_string(:challenge_id, challenge.challenge_id)
    |> validate_mfa_level(:required_mfa_level, challenge.required_mfa_level)
    |> validate_positive_integer(:max_auth_age_seconds, challenge.max_auth_age_seconds)
    |> validate_reason(challenge.reason)
    |> to_validation_result()
  end

  def validate_step_up_challenge(_challenge), do: {:error, [step_up_challenge: :invalid_contract]}

  @spec validate_evidence_lane(map() | keyword()) :: :ok | {:error, keyword()}
  def validate_evidence_lane(evidence) when is_list(evidence),
    do: evidence |> Map.new() |> validate_evidence_lane()

  def validate_evidence_lane(evidence) when is_map(evidence) do
    []
    |> reject_evidence_authority_lane(evidence)
    |> to_validation_result()
  end

  def validate_evidence_lane(_evidence), do: {:error, [evidence: :invalid_contract]}

  @spec lane_auth_age_seconds(SessionAuthorityLane.t(), String.t() | DateTime.t() | nil) ::
          non_neg_integer()
  def lane_auth_age_seconds(%SessionAuthorityLane{auth_age_seconds: seconds}, _as_of)
      when is_integer(seconds) and seconds >= 0,
      do: seconds

  def lane_auth_age_seconds(%SessionAuthorityLane{} = lane, as_of) do
    with {:ok, authenticated_at} <- parse_datetime(lane.authenticated_at),
         {:ok, effective_as_of} <- parse_datetime(as_of || lane.as_of) do
      max(DateTime.diff(effective_as_of, authenticated_at, :second), 0)
    else
      _ -> 0
    end
  end

  @spec timestamp_before_or_equal?(
          String.t() | DateTime.t() | nil,
          String.t() | DateTime.t() | nil
        ) :: boolean()
  def timestamp_before_or_equal?(left, right) do
    with {:ok, left_dt} <- parse_datetime(left),
         {:ok, right_dt} <- parse_datetime(right) do
      DateTime.compare(left_dt, right_dt) in [:lt, :eq]
    else
      _ -> false
    end
  end

  @spec normalize_timestamp(String.t() | DateTime.t()) :: {:ok, String.t()} | {:error, term()}
  def normalize_timestamp(value) do
    with {:ok, datetime} <- parse_datetime(value) do
      {:ok, DateTime.truncate(datetime, :second) |> DateTime.to_iso8601()}
    end
  end

  defp build_and_validate(attrs, module, validator, error_key) when is_list(attrs) do
    attrs
    |> Map.new()
    |> build_and_validate(module, validator, error_key)
  end

  defp build_and_validate(attrs, module, validator, error_key) when is_map(attrs) do
    normalized_attrs =
      attrs
      |> normalize_attrs_for(module)
      |> known_struct_attrs(module)

    with {:ok, contract} <-
           build_struct(module, normalized_attrs, error_key),
         :ok <- validator.(contract) do
      {:ok, contract}
    end
  end

  defp build_and_validate(_attrs, _module, _validator, error_key),
    do: {:error, [{error_key, :invalid_attrs}]}

  defp build_struct(module, attrs, error_key) do
    try do
      {:ok, struct!(module, attrs)}
    rescue
      error in [ArgumentError, KeyError] -> {:error, [{error_key, Exception.message(error)}]}
    end
  end

  defp normalize_auth_context_attrs(attrs) do
    case Map.get(attrs, :session_authority_lane, Map.get(attrs, "session_authority_lane")) do
      %SessionAuthorityLane{} = lane ->
        attrs
        |> put_new_alias(:actor_id, lane.subject_ref)
        |> put_new_alias(:org_id, lane.org_id)
        |> put_new_alias(:mfa_level, lane.assurance_level)
        |> put_new_alias(
          :auth_age,
          lane_auth_age_seconds(lane, Map.get(attrs, :as_of, Map.get(attrs, "as_of")))
        )
        |> put_new_alias(:as_of, lane.as_of)

      _other ->
        attrs
    end
  end

  defp normalize_attrs_for(attrs, SessionAuthorityLane) do
    attrs =
      attrs
      |> put_new_alias(:session_ref, Map.get(attrs, :session_id, Map.get(attrs, "session_id")))
      |> put_new_alias(:subject_ref, Map.get(attrs, :actor_id, Map.get(attrs, "actor_id")))
      |> put_new_alias(
        :state,
        Map.get(attrs, :authority_state, Map.get(attrs, "authority_state"))
      )
      |> put_new_alias(:assurance_level, Map.get(attrs, :mfa_level, Map.get(attrs, "mfa_level")))

    attrs
    |> normalize_timestamp_attr(:authenticated_at)
    |> normalize_timestamp_attr(:last_seen_at)
    |> normalize_timestamp_attr(:idle_expires_at)
    |> normalize_timestamp_attr(:absolute_expires_at)
    |> normalize_timestamp_attr(:renew_after)
    |> normalize_timestamp_attr(:revoked_at)
    |> normalize_timestamp_attr(:as_of)
  end

  defp normalize_attrs_for(attrs, _module), do: attrs

  defp known_struct_attrs(attrs, module) do
    allowed = module.__struct__() |> Map.keys() |> MapSet.new()

    attrs
    |> Enum.reject(fn {key, _value} -> key == :__struct__ or not MapSet.member?(allowed, key) end)
    |> Map.new()
  end

  defp put_new_alias(attrs, _key, nil), do: attrs

  defp put_new_alias(attrs, key, value) do
    if Map.has_key?(attrs, key) or Map.has_key?(attrs, Atom.to_string(key)) do
      attrs
    else
      Map.put(attrs, key, value)
    end
  end

  defp normalize_timestamp_attr(attrs, key) do
    value = Map.get(attrs, key, Map.get(attrs, Atom.to_string(key)))

    case value do
      nil ->
        attrs

      _ ->
        case normalize_timestamp(value) do
          {:ok, normalized} -> Map.put(attrs, key, normalized)
          {:error, _reason} -> attrs
        end
    end
  end

  defp validate_required_string(errors, field, value) do
    if present_string?(value), do: errors, else: [{field, :required} | errors]
  end

  # A nil organization is an explicit personal-account scope for a B2C host.
  # Empty strings remain invalid so callers cannot accidentally erase a real
  # organization boundary while still passing validation.
  defp validate_optional_string(errors, _field, nil), do: errors

  defp validate_optional_string(errors, field, value) do
    if present_string?(value), do: errors, else: [{field, :invalid_optional_string} | errors]
  end

  defp validate_non_negative_integer(errors, _field, value) when is_integer(value) and value >= 0,
    do: errors

  defp validate_non_negative_integer(errors, field, value),
    do: [{field, {:invalid_non_negative_integer, value}} | errors]

  defp validate_positive_integer(errors, _field, value) when is_integer(value) and value > 0,
    do: errors

  defp validate_positive_integer(errors, field, value),
    do: [{field, {:invalid_positive_integer, value}} | errors]

  defp validate_mfa_level(errors, field, value) do
    if value in @mfa_level_vocabulary do
      errors
    else
      [{field, {:invalid_mfa_level, value}} | errors]
    end
  end

  defp validate_authority_state(errors, value) do
    if value in @authority_state_vocabulary do
      errors
    else
      [{:authority_state, {:invalid_authority_state, value}} | errors]
    end
  end

  defp validate_authn_methods(errors, methods) when is_list(methods) do
    if Enum.all?(methods, &valid_authn_method?/1) do
      errors
    else
      [{:authn_methods, {:invalid_authn_methods, methods}} | errors]
    end
  end

  defp validate_authn_methods(errors, methods),
    do: [{:authn_methods, {:invalid_authn_methods, methods}} | errors]

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

  defp merge_nested_validation(errors, :ok), do: errors
  defp merge_nested_validation(errors, {:error, nested_errors}), do: nested_errors ++ errors

  defp valid_authn_method?(method) when is_atom(method), do: method not in [true, false, nil]
  defp valid_authn_method?(method) when is_binary(method), do: String.trim(method) != ""
  defp valid_authn_method?(_method), do: false

  defp parse_datetime(%DateTime{} = datetime), do: {:ok, DateTime.truncate(datetime, :second)}

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> {:ok, DateTime.truncate(datetime, :second)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_datetime(_value), do: {:error, :invalid_datetime}

  defp validate_reason(errors, reason) when is_atom(reason), do: errors

  defp validate_reason(errors, reason) when is_binary(reason) do
    if present_string?(reason), do: errors, else: [{:reason, :required} | errors]
  end

  defp validate_reason(errors, _reason), do: [{:reason, :required} | errors]

  defp reject_evidence_authority_lane(errors, evidence) do
    Enum.reduce(@forbidden_evidence_authority_keys, errors, fn key, acc ->
      if Map.has_key?(evidence, key) or Map.has_key?(evidence, Atom.to_string(key)) do
        [{:evidence, {key, :forbidden}} | acc]
      else
        acc
      end
    end)
  end

  defp mfa_level_index(level) do
    case Map.fetch(@mfa_level_indexes, level) do
      {:ok, index} -> {:ok, index}
      :error -> {:error, {:invalid_mfa_level, level}}
    end
  end

  defp present_string?(value), do: is_binary(value) and String.trim(value) != ""

  defp to_validation_result([]), do: :ok
  defp to_validation_result(errors), do: {:error, Enum.reverse(errors)}
end
