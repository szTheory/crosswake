defmodule CrosswakeExample.LocalFirst.PhysicalIphoneAuthority do
  @moduledoc false

  use Phoenix.Controller, formats: [:json]

  alias Crosswake.ProofLane.PhysicalIphoneContract
  alias CrosswakeExample.LocalFirst.{PhysicalIphoneRunProvenance, ReviewEvent}
  alias CrosswakeExample.Repo

  @backend_ids [
    "PI-RECOVERY-REJECTION-AUTHORITY",
    "PI-RECOVERY-CONFLICT-AUTHORITY",
    "PI-LOGOUT-FENCE-AUTHORITY",
    "PI-ACCOUNT-SWITCH-FENCE-AUTHORITY",
    "PI-ENTRY-DISABLEMENT-AUTHORITY",
    "PI-REPLAY-DISABLEMENT-AUTHORITY",
    "PI-EXACTLY-ONCE-EMPTY-OUTBOX"
  ]
  @case_refs [
    :rejection,
    :conflict,
    :logout,
    :account_switch,
    :entry_disablement,
    :replay_disablement
  ]
  @case_table __MODULE__.Cases

  @spec prepare_case(map(), atom()) :: {:ok, :prepared} | {:error, :unavailable}
  def prepare_case(%{nonce: nonce, mutation_id: mutation_id}, case_ref)
      when is_binary(nonce) and is_binary(mutation_id) and case_ref in @case_refs do
    with true <- PhysicalIphoneRunProvenance.active?(nonce, mutation_id),
         true <-
           :ets.insert_new(
             case_table(),
             {{nonce, case_ref}, %{mutation_id: mutation_id, case_ref: case_ref}}
           ) do
      {:ok, :prepared}
    else
      _ -> {:error, :unavailable}
    end
  rescue
    _ -> {:error, :unavailable}
  end

  def prepare_case(_, _), do: {:error, :unavailable}

  @spec verify_case(map(), atom()) :: {:ok, :passed} | {:error, :unavailable}
  def verify_case(%{nonce: nonce, mutation_id: mutation_id}, case_ref)
      when is_binary(nonce) and is_binary(mutation_id) and case_ref in @case_refs do
    key = {nonce, case_ref}

    case :ets.take(case_table(), key) do
      [{^key, %{mutation_id: ^mutation_id, case_ref: ^case_ref, outcome: outcome}}] ->
        if outcome in expected_outcomes(case_ref),
          do: {:ok, :passed},
          else: {:error, :unavailable}

      [{^key, entry}] ->
        true = :ets.insert(case_table(), {key, entry})
        {:error, :unavailable}

      [] ->
        {:error, :unavailable}
    end
  rescue
    _ -> {:error, :unavailable}
  end

  def verify_case(_, _), do: {:error, :unavailable}

  # Called only by SyncController after a request has passed through normal
  # Phoenix replay admission. A fixture route cannot call this recorder.
  @doc false
  def observe_device_result(
        %{"physical_proof_nonce" => nonce, "client_mutation_id" => mutation_id},
        outcome
      )
      when is_binary(nonce) and is_binary(mutation_id) do
    Enum.each(@case_refs, fn case_ref ->
      key = {nonce, case_ref}

      case :ets.take(case_table(), key) do
        [{^key, %{mutation_id: ^mutation_id} = entry}] ->
          true = :ets.insert(case_table(), {key, Map.put(entry, :outcome, outcome)})

        [{^key, entry}] ->
          true = :ets.insert(case_table(), {key, entry})

        [] ->
          :ok
      end
    end)

    :ok
  rescue
    _ -> :ok
  end

  def observe_device_result(_, _), do: :ok

  # Test-only controls provide setup and independent verification but return
  # closed output; tickets, mutation IDs, scopes, and rows never leave here.
  def prepare(conn, params) do
    case fixture_case(params, &prepare_case/2) do
      {:ok, :prepared} -> json(conn, %{outcome: "prepared"})
      _ -> send_resp(conn, :forbidden, "")
    end
  end

  def verify(conn, params) do
    case fixture_case(params, &verify_case/2) do
      {:ok, :passed} -> json(conn, %{outcome: "passed"})
      _ -> send_resp(conn, :forbidden, "")
    end
  end

  @spec ready?() :: :ok | :blocked
  def ready? do
    with true <- Process.whereis(Repo) != nil,
         true <- Process.whereis(CrosswakeExample.RulesteadFlagSource) != nil do
      :ok
    else
      _ -> :blocked
    end
  end

  defp fixture_case(
         %{"nonce" => nonce, "mutation_id" => mutation_id, "case_ref" => case_ref},
         fun
       )
       when is_binary(nonce) and is_binary(mutation_id) do
    with {:ok, case_ref} <- case_ref(case_ref) do
      fun.(%{nonce: nonce, mutation_id: mutation_id}, case_ref)
    end
  end

  defp fixture_case(_, _), do: {:error, :unavailable}

  defp case_ref("rejection"), do: {:ok, :rejection}
  defp case_ref("conflict"), do: {:ok, :conflict}
  defp case_ref("logout"), do: {:ok, :logout}
  defp case_ref("account_switch"), do: {:ok, :account_switch}
  defp case_ref("entry_disablement"), do: {:ok, :entry_disablement}
  defp case_ref("replay_disablement"), do: {:ok, :replay_disablement}
  defp case_ref(_), do: {:error, :unavailable}

  defp expected_outcomes(:rejection), do: [:rejected]
  defp expected_outcomes(:conflict), do: [:transaction_failed]
  defp expected_outcomes(:logout), do: [:authority_unavailable]
  defp expected_outcomes(:account_switch), do: [:scope_mismatch]
  defp expected_outcomes(:entry_disablement), do: [:entry_disabled]
  defp expected_outcomes(:replay_disablement), do: [:feature_disabled]

  defp case_table do
    case :ets.whereis(@case_table) do
      :undefined ->
        try do
          :ets.new(@case_table, [:named_table, :public, :set, read_concurrency: true])
        rescue
          ArgumentError -> @case_table
        end

      _ ->
        @case_table
    end
  end

  @spec report(map()) :: binary() | {:error, :unavailable}
  def report(%{schema_version: schema_version, device_class: :physical_iphone}, %{
        nonce: nonce,
        mutation_id: mutation_id
      })
      when is_binary(nonce) and is_binary(mutation_id) do
    # Ecto debug output can contain the opaque mutation/scope values exercised
    # below. Keep the producer silent and return only its closed report.
    Logger.disable(self())

    with true <- schema_version == PhysicalIphoneContract.schema_version(),
         true <- PhysicalIphoneRunProvenance.active?(nonce, mutation_id),
         true <-
           Enum.all?(
             @case_refs,
             &(verify_case(%{nonce: nonce, mutation_id: mutation_id}, &1) == {:ok, :passed})
           ) do
      Jason.encode!(%{
        "schema_version" => schema_version,
        "device_class" => "physical_iphone",
        "assertions" => Enum.map(@backend_ids, &%{"id" => &1, "outcome" => "passed"})
      })
    else
      _ -> {:error, :unavailable}
    end
  rescue
    _ -> {:error, :unavailable}
  after
    CrosswakeExample.RulesteadFlagSource.delete_flag(:rulestead)
    safe_reset_fixture()
    Logger.enable(self())
  end

  def report(_contract, _run), do: {:error, :unavailable}

  # Kept for the ordinary fixture tests; a physical proof must use report/2.
  def report(%{schema_version: _schema_version, device_class: :physical_iphone}),
    do: {:error, :unavailable}

  def report(_), do: {:error, :unavailable}

  def reset_fixture do
    Repo.delete_all(ReviewEvent)
    :ok
  end

  defp safe_reset_fixture do
    reset_fixture()
  rescue
    _ -> :ok
  end
end
