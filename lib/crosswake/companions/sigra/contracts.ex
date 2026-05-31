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
    @enforce_keys [:actor_id, :org_id, :mfa_level, :auth_age]
    defstruct [:actor_id, :org_id, :mfa_level, :auth_age, :session_authority_lane, :as_of]

    @type t :: %__MODULE__{
            actor_id: String.t(),
            org_id: String.t(),
            mfa_level: atom(),
            auth_age: non_neg_integer(),
            session_authority_lane: Crosswake.Companions.Sigra.Contracts.SessionAuthorityLane.t() | nil,
            as_of: String.t() | nil
          }
  end

  defmodule SessionAuthorityLane do
    @moduledoc """
    Backend-owned session authority facts.
    """
    @enforce_keys [:authority_state, :mfa_level, :auth_age_seconds]
    defstruct [:authority_state, :mfa_level, :auth_age_seconds, :authenticated_at, :session_id]

    @type authority_state :: :active | :step_up_required | :suspended | :expired

    @type t :: %__MODULE__{
            authority_state: authority_state(),
            mfa_level: atom(),
            auth_age_seconds: non_neg_integer(),
            authenticated_at: String.t() | nil,
            session_id: String.t() | nil
          }
  end

  defmodule StepUpChallenge do
    @moduledoc """
    Reference-only step-up requirement state.
    """
    @enforce_keys [:challenge_id, :required_mfa_level, :max_auth_age_seconds, :reason]
    defstruct [:challenge_id, :required_mfa_level, :max_auth_age_seconds, :reason, :issued_at, :expires_at]

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
  @authority_state_vocabulary [:active, :step_up_required, :suspended, :expired]
  @forbidden_evidence_authority_keys [:authority_state, :mfa_level, :auth_level, :session_authority, :access_granted]

  @spec mfa_level_vocabulary() :: [atom()]
  def mfa_level_vocabulary, do: @mfa_level_vocabulary

  @spec mfa_level_meets?(atom(), atom()) :: boolean()
  def mfa_level_meets?(current, required) do
    with {:ok, current_index} <- mfa_level_index(current),
         {:ok, required_index} <- mfa_level_index(required) do
      current_index >= required_index
    else
      _ -> false
    end
  end

  @spec auth_age_seconds(AuthContext.t()) :: non_neg_integer()
  def auth_age_seconds(%AuthContext{auth_age: auth_age}) when is_integer(auth_age) and auth_age >= 0,
    do: auth_age

  def auth_age_seconds(%AuthContext{auth_age: auth_age}) when is_binary(auth_age) do
    case Integer.parse(auth_age) do
      {seconds, ""} when seconds >= 0 -> seconds
      _ -> 0
    end
  end

  def auth_age_seconds(%AuthContext{}), do: 0

  @spec new_auth_context(map() | keyword()) :: {:ok, AuthContext.t()} | {:error, keyword()}
  def new_auth_context(attrs), do: build_and_validate(attrs, AuthContext, &validate_auth_context/1, :auth_context)

  @spec new_session_authority_lane(map() | keyword()) :: {:ok, SessionAuthorityLane.t()} | {:error, keyword()}
  def new_session_authority_lane(attrs), do: build_and_validate(attrs, SessionAuthorityLane, &validate_session_authority_lane/1, :session_authority_lane)

  @spec new_step_up_challenge(map() | keyword()) :: {:ok, StepUpChallenge.t()} | {:error, keyword()}
  def new_step_up_challenge(attrs), do: build_and_validate(attrs, StepUpChallenge, &validate_step_up_challenge/1, :step_up_challenge)

  @spec validate_auth_context(AuthContext.t()) :: :ok | {:error, keyword()}
  def validate_auth_context(%AuthContext{} = auth_context) do
    []
    |> validate_required_string(:actor_id, auth_context.actor_id)
    |> validate_required_string(:org_id, auth_context.org_id)
    |> validate_mfa_level(:mfa_level, auth_context.mfa_level)
    |> validate_non_negative_integer(:auth_age, auth_age_seconds(auth_context))
    |> to_validation_result()
  end

  def validate_auth_context(_auth_context), do: {:error, [auth_context: :invalid_contract]}

  @spec validate_session_authority_lane(SessionAuthorityLane.t()) :: :ok | {:error, keyword()}
  def validate_session_authority_lane(%SessionAuthorityLane{} = lane) do
    []
    |> validate_authority_state(lane.authority_state)
    |> validate_mfa_level(:mfa_level, lane.mfa_level)
    |> validate_non_negative_integer(:auth_age_seconds, lane.auth_age_seconds)
    |> to_validation_result()
  end

  def validate_session_authority_lane(_lane), do: {:error, [session_authority_lane: :invalid_contract]}

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
  def validate_evidence_lane(evidence) when is_list(evidence), do: evidence |> Map.new() |> validate_evidence_lane()

  def validate_evidence_lane(evidence) when is_map(evidence) do
    []
    |> reject_evidence_authority_lane(evidence)
    |> to_validation_result()
  end

  def validate_evidence_lane(_evidence), do: {:error, [evidence: :invalid_contract]}

  defp build_and_validate(attrs, module, validator, error_key) when is_list(attrs) do
    attrs
    |> Map.new()
    |> build_and_validate(module, validator, error_key)
  end

  defp build_and_validate(attrs, module, validator, error_key) when is_map(attrs) do
    with {:ok, contract} <- build_struct(module, attrs, error_key),
         :ok <- validator.(contract) do
      {:ok, contract}
    end
  end

  defp build_and_validate(_attrs, _module, _validator, error_key), do: {:error, [{error_key, :invalid_attrs}]}

  defp build_struct(module, attrs, error_key) do
    try do
      {:ok, struct!(module, attrs)}
    rescue
      error in [ArgumentError, KeyError] -> {:error, [{error_key, Exception.message(error)}]}
    end
  end

  defp validate_required_string(errors, field, value) do
    if present_string?(value), do: errors, else: [{field, :required} | errors]
  end

  defp validate_non_negative_integer(errors, _field, value) when is_integer(value) and value >= 0, do: errors
  defp validate_non_negative_integer(errors, field, value), do: [{field, {:invalid_non_negative_integer, value}} | errors]

  defp validate_positive_integer(errors, _field, value) when is_integer(value) and value > 0, do: errors
  defp validate_positive_integer(errors, field, value), do: [{field, {:invalid_positive_integer, value}} | errors]

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
