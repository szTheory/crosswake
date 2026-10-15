defmodule CrosswakeExample.E2E.TwinFaultController do
  @moduledoc """
  Test-only, run-owned fault preparation and observation for the bounded digital twin.

  Mounted only inside the single compile-time `/_e2e` guard in the router
  (`Mix.env() in [:test, :e2e]`), so none of these routes exist in a prod build.

  What it does, and what it deliberately does not do:

    * `POST /_e2e/twin/fault` only *prepares state* that the real owners consult:
      `CrosswakeExample.E2E.ReplayAuthority` asks `fault_active?/2` from its
      `feature_enabled?/2` and `domain_allows?/3` callbacks, and a prepared rejection
      or conflict is a persisted row that `Study.apply_one/3` meets on its normal
      idempotency path. It never returns a canned allow, never writes an accepted
      row for the learner's scope, and never grants replay authority.
    * `GET /_e2e/twin/media/:asset` serves the tracked public reference pronunciation
      fixture (or a missing / one-byte-corrupt variant when prepared).
    * `GET /_e2e/twin/observe` returns closed integer counters only. Mutation ids used
      for duplicate detection stay in the run-owned table and are never returned.
    * `GET /_e2e/twin/build` returns one SHA-256 over the sorted module MD5s of this
      application's loaded modules.

  Authority is labeled `synthetic_test_authority` whenever the configured replay
  authority is the E2E one. All state lives in one named ETS table that is created
  lazily by these endpoints, owned by a long-lived process, and scoped to this run's
  BEAM (and therefore to this run's own database). `observe_result/2` is a no-op until
  that table exists, so production and ordinary test paths record nothing.
  """

  use Phoenix.Controller, formats: [:json]

  alias CrosswakeExample.LocalFirst.ReviewEvent
  alias CrosswakeExample.Repo

  @table :crosswake_twin_run_state
  @synthetic_authority_label "synthetic_test_authority"
  @e2e_authority CrosswakeExample.E2E.ReplayAuthority
  @authority_key :offline_study_replay_authority

  @fault_kinds ~w(replay_reject replay_conflict entry_disable replay_disable media_missing media_corrupt)
  @kinds ["clear" | @fault_kinds]

  @media_assets %{
    "pronunciation" =>
      Path.expand(
        "../../../native/ios/CrosswakeProofLane/Resources/ReferenceLearningBundle/pronunciation.aiff",
        __DIR__
      )
  }

  @denial_counters ~w(invalid_envelope scope_mismatch feature_disabled sigra_denied authorization_denied authority_unavailable)a
  @outcome_counters ~w(admitted duplicate_delivery rejected scope_conflict transaction_failed)a
  @authority_counters ~w(synthetic_authority_admitted other_authority_admitted)a
  @counters @outcome_counters ++ @denial_counters ++ @authority_counters

  @other_scope "v1.scope_fixture_bravo_01"
  @primary_scope "v1.scope_fixture_alpha_01"

  def synthetic_authority_label, do: @synthetic_authority_label

  # ---------------------------------------------------------------------------
  # Endpoints
  # ---------------------------------------------------------------------------

  def create(conn, %{"kind" => kind} = params) when kind in @kinds do
    ensure_table()

    case kind do
      "clear" ->
        for fault <- @fault_kinds, do: :ets.delete(@table, {:fault, fault})

      fault ->
        :ets.insert(@table, {{:fault, fault}, card_filter(params)})
    end

    send_resp(conn, 204, "")
  end

  def create(conn, _params) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: %{class: "invalid_fault_kind"}})
  end

  def media(conn, %{"asset" => asset}) do
    with {:ok, path} <- Map.fetch(@media_assets, asset),
         {:ok, bytes} <- File.read(path) do
      serve_media(conn, bytes)
    else
      _ -> send_resp(conn, 404, "")
    end
  end

  def observe(conn, _params) do
    ensure_table()

    counters =
      Map.new(@counters, fn key ->
        {key, counter_value(key)}
      end)

    json(conn, %{data: counters})
  end

  def build(conn, _params) do
    json(conn, %{data: %{build_sha256: build_identity()}})
  end

  # ---------------------------------------------------------------------------
  # Consulted by the real owners
  # ---------------------------------------------------------------------------

  @doc """
  True when `kind` was prepared in this run. An optional card filter narrows the fault
  to events for that card; without an event the fault applies run-wide.
  """
  def fault_active?(kind, event \\ nil) when kind in @fault_kinds do
    with true <- table_exists?(),
         [{_, filter}] <- :ets.lookup(@table, {:fault, kind}) do
      filter == :all or (is_map(event) and Map.get(event, "card_id") == filter)
    else
      _ -> false
    end
  rescue
    ArgumentError -> false
  end

  @doc """
  Called from `ReplayAuthority.domain_allows?/3` before the real admission decision is
  returned. When a rejection or conflict is prepared for this event it persists the
  row the real `Study` path then meets: a `rejected` row in the session's own scope, or
  a `rejected` row owned by a different scope (which the real path reports as a scope
  conflict). It never persists an accepted row and never changes the allow decision.
  """
  def prepare_replay_outcome(event, session) when is_map(event) do
    cond do
      not table_exists?() ->
        :ok

      fault_active?("replay_reject", event) ->
        seed_row(event, Map.get(session, :scope_ref), "rejected")

      fault_active?("replay_conflict", event) ->
        scope = Map.get(session, :scope_ref)

        seed_row(
          event,
          if(scope == @other_scope, do: @primary_scope, else: @other_scope),
          "rejected"
        )

      true ->
        :ok
    end
  rescue
    _ -> :ok
  end

  def prepare_replay_outcome(_event, _session), do: :ok

  @doc """
  Records one closed decision outcome. A no-op returning `:ok` when the run-owned table
  does not exist, which is always the case in production and ordinary test paths.
  """
  def observe_result(event, outcome) do
    if table_exists?(), do: record(event, outcome), else: :ok
  rescue
    _ -> :ok
  end

  # ---------------------------------------------------------------------------
  # Internals
  # ---------------------------------------------------------------------------

  defp card_filter(%{"card_id" => card_id}) when is_integer(card_id) and card_id > 0, do: card_id
  defp card_filter(_), do: :all

  defp serve_media(conn, bytes) do
    {status, body} =
      cond do
        fault_active?("media_missing") -> {404, ""}
        fault_active?("media_corrupt") -> {200, flip_one_byte(bytes)}
        true -> {200, bytes}
      end

    conn
    |> put_resp_content_type("audio/aiff", nil)
    |> send_resp(status, body)
  end

  defp flip_one_byte(bytes) do
    index = div(byte_size(bytes), 2)
    <<head::binary-size(index), byte, tail::binary>> = bytes
    <<head::binary, Bitwise.bxor(byte, 0x01), tail::binary>>
  end

  defp seed_row(event, scope_ref, status) when is_binary(scope_ref) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Repo.insert_all(
      ReviewEvent,
      [
        %{
          scope_ref: scope_ref,
          client_mutation_id: Map.fetch!(event, "client_mutation_id"),
          card_id: Map.fetch!(event, "card_id"),
          rating: Map.fetch!(event, "rating"),
          status: status,
          inserted_at: now,
          updated_at: now
        }
      ],
      on_conflict: :nothing
    )

    :ok
  end

  defp seed_row(_event, _scope_ref, _status), do: :ok

  defp record(event, outcome) do
    id = if is_map(event), do: Map.get(event, "client_mutation_id"), else: nil

    case outcome do
      :accepted ->
        bump(:admitted)
        note_admission(id)

      :rejected ->
        bump(:rejected)
        note_admission(id)

      :scope_conflict ->
        bump(:scope_conflict)
        note_admission(id)

      :transaction_failed ->
        bump(:transaction_failed)
        note_admission(id)

      denial when denial in @denial_counters ->
        bump(denial)

      _other ->
        bump(:authority_unavailable)
    end

    :ok
  end

  # A delivery that passed admission: classify the authority and spot repeat ids.
  defp note_admission(id) do
    bump(
      if synthetic_authority?(),
        do: :synthetic_authority_admitted,
        else: :other_authority_admitted
    )

    if is_binary(id) and not :ets.insert_new(@table, {{:seen, id}, true}) do
      bump(:duplicate_delivery)
    end

    :ok
  end

  defp synthetic_authority?,
    do: Application.get_env(:crosswake_example, @authority_key) == @e2e_authority

  defp bump(key), do: :ets.update_counter(@table, {:counter, key}, 1, {{:counter, key}, 0})

  defp counter_value(key) do
    case :ets.lookup(@table, {:counter, key}) do
      [{_, value}] -> value
      _ -> 0
    end
  end

  defp build_identity do
    :crosswake_example
    |> Application.spec(:modules)
    |> List.wrap()
    |> Enum.map(fn module -> module.module_info(:md5) |> Base.encode16(case: :lower) end)
    |> Enum.sort()
    |> Enum.join("\n")
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp table_exists?, do: :ets.whereis(@table) != :undefined

  defp ensure_table do
    if table_exists?() do
      :ok
    else
      parent = self()
      ref = make_ref()

      # A long-lived owner keeps the table alive past this request process.
      spawn(fn ->
        result =
          try do
            :ets.new(@table, [:named_table, :public, :set, write_concurrency: true])
            :created
          rescue
            ArgumentError -> :exists
          end

        send(parent, {ref, result})
        if result == :created, do: Process.sleep(:infinity)
      end)

      receive do
        {^ref, _result} -> :ok
      after
        1_000 -> :ok
      end
    end
  end
end
