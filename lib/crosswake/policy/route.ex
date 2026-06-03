defmodule Crosswake.Policy.Route do
  @moduledoc """
  Normalized Phase 1 route policy contract.
  """

  alias Crosswake.Policy.Defaults
  alias Crosswake.Policy.Schema

  @commerce_role_values [:paywall_entry, :purchase_intent, :restore_intent, :account_management]
  @auth_return_required_validations %{
    oauth: [:state, :pkce, :redirect_uri, :expiry, :replay],
    passkey: [:challenge, :origin, :rp_id, :user_verification, :expiry, :replay],
    native_auth: [:callback_binding, :link_verification, :expiry, :replay]
  }
  @auth_return_provider_specific_terms [
    :google,
    :github,
    :apple,
    :microsoft,
    :okta,
    :auth0,
    :google_oauth,
    :apple_passkey
  ]

  @enforce_keys [:id, :runtime]
  defstruct [
    :id,
    :runtime,
    :security,
    :cache_contract,
    :island_contract,
    :commerce,
    :gated_by,
    :on_unavailable,
    :auth_min_level,
    :requires_recent_auth,
    :auth_posture,
    :auth_return,
    :notification_open,
    offline: :unavailable,
    entry: :internal_only,
    capabilities: [],
    packs: [],
    sync: [],
    transfers: []
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          runtime: Schema.runtime(),
          offline: Schema.offline(),
          entry: Schema.entry(),
          cache_contract: String.t() | nil,
          island_contract: String.t() | nil,
          commerce: Schema.commerce_declaration() | nil,
          capabilities: [String.t()],
          packs: [Schema.pack_requirement()],
          sync: [String.t()],
          transfers: [Crosswake.Transfer.Contracts.declaration()],
          security: Schema.security() | nil,
          gated_by: atom() | nil,
          on_unavailable: :deny | {:fallback_phoenix, atom()} | nil,
          auth_min_level: atom() | nil,
          requires_recent_auth: pos_integer() | nil,
          auth_posture: Schema.auth_posture() | nil,
          auth_return: Schema.auth_return_declaration() | nil,
          notification_open: Schema.notification_open_declaration() | nil
        }

  @spec new(keyword()) :: {:ok, t()} | {:error, NimbleOptions.ValidationError.t()}
  def new(options) when is_list(options) do
    options
    |> merged_options()
    |> Schema.validate()
    |> case do
      {:ok, validated} ->
        with {:ok, validated} <- validate_offline_contracts(validated),
             {:ok, validated} <- validate_gating_posture(validated),
             {:ok, validated} <- validate_entry_policy(validated),
             {:ok, validated} <- validate_commerce_declaration(validated),
             {:ok, validated} <- validate_auth_return_declaration(validated),
             {:ok, validated} <- validate_auth_posture(validated),
             {:ok, validated} <- validate_pack_requirements(validated),
             {:ok, validated} <- validate_transfer_declarations(validated) do
          {:ok, struct!(__MODULE__, validated)}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @spec new!(keyword()) :: t()
  def new!(options) when is_list(options) do
    options
    |> merged_options()
    |> Schema.validate!()
    |> validate_offline_contracts!()
    |> validate_gating_posture!()
    |> validate_entry_policy!()
    |> validate_commerce_declaration!()
    |> validate_auth_return_declaration!()
    |> validate_auth_posture!()
    |> validate_pack_requirements!()
    |> validate_transfer_declarations!()
    |> then(&struct!(__MODULE__, &1))
  end

  defp merged_options(options) do
    Defaults.route()
    |> Keyword.merge(options)
  end

  defp validate_offline_contracts(validated) do
    cond do
      validated[:cache_contract] && validated[:offline] != :cached_read_only ->
        {:error,
         validation_error(
           :cache_contract,
           validated[:cache_contract],
           "cache_contract requires offline :cached_read_only and does not belong on local-first routes"
         )}

      validated[:island_contract] &&
          (validated[:runtime] != :offline_island or validated[:offline] != :local_first) ->
        {:error,
         validation_error(
           :island_contract,
           validated[:island_contract],
           "island_contract requires runtime :offline_island with offline :local_first"
         )}

      true ->
        {:ok, validated}
    end
  end

  defp validate_offline_contracts!(validated) do
    case validate_offline_contracts(validated) do
      {:ok, validated} -> validated
      {:error, error} -> raise error
    end
  end

  defp validate_gating_posture(validated) do
    gated_by = validated[:gated_by]
    on_unavailable = validated[:on_unavailable]

    cond do
      on_unavailable != nil and is_nil(gated_by) ->
        {:error,
         validation_error(
           :on_unavailable,
           on_unavailable,
           "on_unavailable requires gated_by to be set"
         )}

      gated_by != nil and is_nil(on_unavailable) ->
        {:ok, Keyword.put(validated, :on_unavailable, :deny)}

      true ->
        {:ok, validated}
    end
  end

  defp validate_gating_posture!(validated) do
    case validate_gating_posture(validated) do
      {:ok, validated} -> validated
      {:error, error} -> raise error
    end
  end

  defp validate_pack_requirements(validated) do
    pack_ids = Enum.map(validated[:packs], & &1.id)

    if Enum.uniq(pack_ids) == pack_ids do
      {:ok, validated}
    else
      {:error,
       validation_error(
         :packs,
         validated[:packs],
         "pack ids must be unique within a route declaration"
       )}
    end
  end

  defp validate_pack_requirements!(validated) do
    case validate_pack_requirements(validated) do
      {:ok, validated} -> validated
      {:error, error} -> raise error
    end
  end

  defp validate_transfer_declarations(validated) do
    transfer_ids = Enum.map(validated[:transfers], & &1.id)

    cond do
      Enum.uniq(transfer_ids) != transfer_ids ->
        {:error,
         validation_error(
           :transfers,
           validated[:transfers],
           "transfer ids must be unique within a route declaration"
         )}

      true ->
        validate_transfer_runtime(validated)
    end
  end

  defp validate_transfer_runtime(validated) do
    case Enum.find(validated[:transfers], &invalid_transfer_for_runtime?(&1, validated[:runtime])) do
      nil ->
        {:ok, validated}

      transfer ->
        {:error,
         validation_error(
           :transfers,
           validated[:transfers],
           transfer_runtime_message(transfer)
         )}
    end
  end

  defp validate_transfer_declarations!(validated) do
    case validate_transfer_declarations(validated) do
      {:ok, validated} -> validated
      {:error, error} -> raise error
    end
  end

  defp validate_entry_policy(validated) do
    case {validated[:entry], validated[:runtime]} do
      {:external, :offline_island} ->
        {:error,
         validation_error(
           :entry,
           validated[:entry],
           "entry :external is not supported on offline_island routes"
         )}

      _other ->
        {:ok, validated}
    end
  end

  defp validate_entry_policy!(validated) do
    case validate_entry_policy(validated) do
      {:ok, validated} -> validated
      {:error, error} -> raise error
    end
  end

  defp validate_commerce_declaration(validated) do
    case validated[:commerce] do
      nil ->
        {:ok, validated}

      %{corridor: nil} = commerce ->
        {:error, validation_error(:commerce, commerce, "commerce declaration requires :corridor")}

      %{role: nil} = commerce ->
        {:error, validation_error(:commerce, commerce, "commerce declaration requires :role")}

      %{corridor: corridor, role: _role} = commerce when not is_binary(corridor) ->
        {:error,
         validation_error(
           :commerce,
           commerce,
           "commerce declaration corridor must be a non-empty string or atom"
         )}

      %{corridor: _corridor, role: role} = commerce when role not in @commerce_role_values ->
        {:error,
         validation_error(
           :commerce,
           commerce,
           "unsupported commerce role #{inspect(role)}; expected one of #{inspect(@commerce_role_values)}"
         )}

      %{corridor: _corridor, role: _role} ->
        {:ok, validated}
    end
  end

  defp validate_commerce_declaration!(validated) do
    case validate_commerce_declaration(validated) do
      {:ok, validated} -> validated
      {:error, error} -> raise error
    end
  end

  defp validate_auth_posture(validated) do
    resolved = resolved_auth_posture(validated)
    validated = Keyword.put(validated, :auth_posture, resolved)

    cond do
      validated[:requires_recent_auth] && resolved != :strict_recent ->
        {:error,
         validation_error(
           :auth_posture,
           resolved,
           "requires_recent_auth requires auth_posture :strict_recent"
         )}

      validated[:security] == :sensitive && resolved != :strict_recent ->
        {:error,
         validation_error(
           :auth_posture,
           resolved,
           "sensitive routes require auth_posture :strict_recent"
         )}

      resolved == :cached_read_only_ok && not cached_read_only_auth_allowed?(validated) ->
        {:error,
         validation_error(
           :auth_posture,
           resolved,
           "auth_posture :cached_read_only_ok requires a provably read-only/degraded cached route"
         )}

      true ->
        {:ok, validated}
    end
  end

  defp validate_auth_posture!(validated) do
    case validate_auth_posture(validated) do
      {:ok, validated} -> validated
      {:error, error} -> raise error
    end
  end

  defp validate_auth_return_declaration(validated) do
    case validated[:auth_return] do
      nil ->
        {:ok, validated}

      %{kind: nil} = auth_return ->
        {:error,
         validation_error(:auth_return, auth_return, "auth_return declaration requires :kind")}

      %{transport: nil} = auth_return ->
        {:error,
         validation_error(
           :auth_return,
           auth_return,
           "auth_return declaration requires :transport"
         )}

      %{return_route_id: nil} = auth_return ->
        {:error,
         validation_error(
           :auth_return,
           auth_return,
           "auth_return declaration requires manifest-known :return_route_id"
         )}

      %{kind: kind} = auth_return when kind in @auth_return_provider_specific_terms ->
        {:error,
         validation_error(
           :auth_return,
           auth_return,
           "provider-specific auth_return vocabulary is not supported in route policy"
         )}

      %{kind: kind, validates: validates} = auth_return ->
        missing = Map.fetch!(@auth_return_required_validations, kind) -- validates
        effective_security = validated[:security] || :sensitive

        cond do
          missing != [] ->
            {:error,
             validation_error(
               :auth_return,
               auth_return,
               "auth_return #{inspect(kind)} requires validations #{inspect(missing)}"
             )}

          effective_security == :sensitive and auth_return.transport == :custom_scheme ->
            {:error,
             validation_error(
               :auth_return,
               auth_return,
               "sensitive auth_return routes require verified_https_link or http_callback transport; custom_scheme is advisory only"
             )}

          true ->
            validated =
              validated
              |> Keyword.put(:security, validated[:security] || :sensitive)
              |> Keyword.put(:auth_posture, validated[:auth_posture] || :strict_recent)

            {:ok, validated}
        end
    end
  end

  defp validate_auth_return_declaration!(validated) do
    case validate_auth_return_declaration(validated) do
      {:ok, validated} -> validated
      {:error, error} -> raise error
    end
  end

  defp resolved_auth_posture(validated) do
    cond do
      not is_nil(validated[:auth_posture]) -> validated[:auth_posture]
      not is_nil(validated[:requires_recent_auth]) -> :strict_recent
      validated[:security] == :sensitive -> :strict_recent
      not is_nil(validated[:auth_min_level]) -> :strict_recent
      true -> nil
    end
  end

  defp cached_read_only_auth_allowed?(validated) do
    read_only_or_degraded? =
      validated[:runtime] == :live_view and
        validated[:offline] == :cached_read_only and
        (not is_nil(validated[:cache_contract]) or validated[:on_unavailable] == :deny)

    commerce_role = commerce_role(validated[:commerce])
    commerce_safe? = commerce_role not in [:purchase_intent, :restore_intent, :account_management]

    read_only_or_degraded? and validated[:security] != :sensitive and
      validated[:requires_recent_auth] == nil and
      commerce_safe?
  end

  defp commerce_role(%{role: role}), do: role
  defp commerce_role(_commerce), do: nil

  defp invalid_transfer_for_runtime?(transfer, runtime) do
    transfer.source == :native_capture and runtime != :native_screen
  end

  defp transfer_runtime_message(%{source: :native_capture, id: id}) do
    "transfer #{inspect(id)} native_capture source requires runtime :native_screen"
  end

  defp validation_error(key, value, message) do
    %NimbleOptions.ValidationError{
      key: key,
      value: value,
      message: message
    }
  end
end
