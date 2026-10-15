defmodule Crosswake.ProofLane.TwinProducers do
  @moduledoc """
  The six owner producers for the bounded twin receipt, the D-19 identity freeze and the
  in-run negative controls.

  Every roster id has exactly one producer. A producer emits only ids whose roster owner is
  its own, and only through `TwinReceipt.observation/1`:

    * `host_adapter/2`, `webview/2`, `app_process/2` read the tested app's own closed channel
      files (the app's self-report, labelled with those owners and never presented as an
      independent boundary or backend observation);
    * `fault_boundary/2` reads the loopback boundary's per-epoch counters;
    * `phoenix_ecto/2` reads the run's backend snapshots (closed integer counters and fixed
      read-only `COUNT` queries);
    * `runner/3` evaluates identity completeness and the six in-run negative controls against
      this run's own observations and expectations.

  A missing channel file, snapshot or sample yields `blocked` with cause
  `observation_missing`; a contradicting value yields `failed`. Nothing here stores answers,
  media bytes, URLs, scope values, tokens or device identifiers.

  Producer inputs (`inputs`) are plain maps built by the journey:

      %{
        cases: %{c1: %{host_adapter: [record] | nil, webview: [...], app_process: [...]}, ...},
        boundary: %{counters: %{epoch => %{class => %{passed: n, refused: n}}}, epochs: [name]} | nil,
        backend: %{"baseline" => snap, epoch_name => snap} | nil,
        process: %{first_pid_absent: bool | nil, exec_after_install: hex | nil,
                   exec_after_c1: hex | nil, installs_before_c1: integer | nil} | nil
      }

  where `snap` is `%{observe: %{counter => integer}, rows: %{total:, accepted:, rejected:,
  distinct:, multi_scope:}}` taken at the end of that epoch.
  """

  alias Crosswake.ProofLane.{TwinFaultBoundary, TwinReceipt, TwinRuntime}

  @host_kinds ~w(TW-T01-01 TW-T01-02 TW-T01-03 TW-T01-04 TW-T04-02 TW-T04-03 TW-T04-04 TW-T04-05)
  @verdicts ~w(passed failed blocked)
  @causes ~w(media_missing media_corrupt install_failed playback_failed probe_invalid timeout)
  @islands ~w(saved_local waiting sending saved_account needs_review unavailable
              audio_unavailable fenced entry_disabled)
  @routes ~w(study review other)
  @count_kinds ~w(main_frame_origin_match bridge_forwarded frame_identity_rejected host_reply_ok
                  host_reply_denied outbox_selected outbox_free_form outbox_active
                  outbox_retained data_store_persistent retry_offered)
  @max_count 1_000_000
  @epoch_order ~w(online_install offline playback relaunch replay offline_install media_faults
                  recovery scope_fence disablement)
  @denials ~w(scope_mismatch authorization_denied sigra_denied invalid_envelope)a

  # The backend's closed counter names (TwinFaultController @counters), mapped explicitly.
  @observe_keys Map.new(
                  ~w(admitted rejected duplicate_delivery synthetic_authority_admitted
                     other_authority_admitted authority_unavailable authorization_denied
                     feature_disabled invalid_envelope scope_conflict scope_mismatch
                     sigra_denied transaction_failed)a,
                  &{Atom.to_string(&1), &1}
                )

  @channel_files %{
    host_adapter: "twin-host-adapter.jsonl",
    webview: "twin-webview.jsonl",
    app_process: "twin-app-process.jsonl"
  }

  @record_keys ~w(cause kind launch seq value)

  def epoch_order, do: @epoch_order
  def channel_files, do: @channel_files

  # ------------------------------------------------------------------ channel records

  @doc """
  Parses one channel's jsonl text into validated records. Records must have exactly the keys
  kind, launch, seq, value and cause, a kind from the channel's closed vocabulary, a value of
  the kind's closed shape and a closed cause.
  """
  @spec parse_channel(atom(), binary()) :: {:ok, [map()]} | {:error, :invalid_channel}
  def parse_channel(channel, text) when channel in [:host_adapter, :webview, :app_process] do
    text
    |> String.split("\n", trim: true)
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {line, index}, {:ok, acc} ->
      with {:ok, %{} = raw} <- Jason.decode(line),
           true <- Enum.sort(Map.keys(raw)) == @record_keys,
           {:ok, record} <- record(channel, raw, index) do
        {:cont, {:ok, [record | acc]}}
      else
        _ -> {:halt, {:error, :invalid_channel}}
      end
    end)
    |> case do
      {:ok, records} -> {:ok, Enum.reverse(records)}
      error -> error
    end
  end

  defp record(
         channel,
         %{"kind" => kind, "launch" => launch, "seq" => seq, "value" => value, "cause" => cause},
         index
       )
       when is_binary(kind) and is_integer(launch) and launch >= 1 and is_integer(seq) and
              seq >= 1 do
    if value_ok?(channel, kind, value) and (is_nil(cause) or cause in @causes) do
      {:ok, %{kind: kind, launch: launch, seq: seq, value: value, cause: cause, i: index}}
    else
      :error
    end
  end

  defp record(_, _, _), do: :error

  defp value_ok?(:host_adapter, kind, value), do: kind in @host_kinds and value in @verdicts
  defp value_ok?(:app_process, "launch", value), do: count?(value)
  defp value_ok?(:app_process, _, _), do: false
  defp value_ok?(:webview, "route_path", value), do: value in @routes
  defp value_ok?(:webview, "island_state", value), do: value in @islands
  defp value_ok?(:webview, kind, value) when kind in @count_kinds, do: count?(value)
  defp value_ok?(:webview, _, _), do: false

  defp count?(value), do: is_integer(value) and value >= 0 and value <= @max_count

  @doc "Reads and parses the three channel files of one case directory (nil when absent or invalid)."
  @spec read_case(Path.t()) :: map()
  def read_case(dir) do
    Map.new(@channel_files, fn {channel, file} ->
      records =
        with {:ok, text} <- File.read(Path.join(dir, file)),
             {:ok, records} <- parse_channel(channel, text) do
          records
        else
          _ -> nil
        end

      {channel, records}
    end)
  end

  # ------------------------------------------------------------------ host_adapter/2

  @host_ids %{
    "TW-T01-01" => :c1,
    "TW-T01-02" => :c1,
    "TW-T01-03" => :c1,
    "TW-T01-04" => :c1,
    "TW-T04-02" => :c1,
    "TW-T04-03" => :c1,
    "TW-T04-04" => :c2,
    "TW-T04-05" => :c2
  }

  @spec host_adapter(map(), String.t()) :: [map()]
  def host_adapter(inputs, run_id) do
    for {id, case_id} <- Enum.sort(@host_ids) do
      result =
        case channel(inputs, case_id, :host_adapter) do
          nil ->
            :missing

          records ->
            case last(records, id) do
              nil -> :missing
              %{value: "passed"} -> :pass
              %{value: "failed"} -> :fail
              %{value: "blocked"} -> {:blocked, :unavailable_observation}
            end
        end

      emit_host_adapter(run_id, id, result)
    end
  end

  # ------------------------------------------------------------------ webview/2

  @webview_ids ~w(TW-T02-01 TW-T02-02 TW-T03-01 TW-T03-02 TW-T03-03 TW-T04-01 TW-T04-06
                  TW-T05-03 TW-T05-04 TW-T06-04 TW-T06-05 TW-T07-03 TW-T07-04 TW-T07-05
                  TW-T08-01 TW-T09-01 TW-T09-03 TW-T09-05)

  @spec webview(map(), String.t()) :: [map()]
  def webview(inputs, run_id) do
    for id <- @webview_ids do
      emit_webview(run_id, id, webview_result(id, inputs))
    end
  end

  defp webview_result(id, inputs) do
    case_id = webview_case(id)

    case channel(inputs, case_id, :webview) do
      nil -> :missing
      records -> webview_rule(id, records)
    end
  end

  defp webview_case(id) when id in ~w(TW-T04-06), do: :c2
  defp webview_case(id) when id in ~w(TW-T07-03 TW-T07-04 TW-T07-05), do: :c3
  defp webview_case("TW-T08-01"), do: :c4
  defp webview_case(id) when id in ~w(TW-T09-01 TW-T09-03 TW-T09-05), do: :c5
  defp webview_case(_), do: :c1

  defp webview_rule("TW-T02-01", records) do
    l1 = launch(records, 1)

    cond do
      l1 == [] -> :missing
      has?(l1, "main_frame_origin_match", 1) and has?(l1, "route_path", "study") -> :pass
      true -> :fail
    end
  end

  defp webview_rule("TW-T02-02", records) do
    l1 = launch(records, 1)

    case {max_of(l1, "bridge_forwarded"), max_of(l1, "frame_identity_rejected")} do
      {nil, _} -> :missing
      {forwarded, rejected} -> verdict(forwarded >= 1 and (rejected || 0) == 0)
    end
  end

  defp webview_rule("TW-T03-01", records),
    do: threshold(max_of(launch(records, 1), "outbox_selected"), 1)

  defp webview_rule("TW-T03-02", records),
    do: threshold(max_of(launch(records, 1), "outbox_free_form"), 1)

  defp webview_rule("TW-T03-03", records) do
    case last(launch(records, 1), "outbox_active") do
      nil -> :missing
      %{value: value} -> verdict(value == 2)
    end
  end

  defp webview_rule("TW-T04-01", records), do: threshold(max_of(records, "host_reply_ok"), 1)

  defp webview_rule("TW-T04-06", records) do
    verdict(has?(records, "island_state", "audio_unavailable"))
  end

  defp webview_rule("TW-T05-03", records) do
    l1 = launch(records, 1)
    l2 = launch(records, 2)

    cond do
      l1 == [] or l2 == [] ->
        :missing

      has?(records, "data_store_persistent", 0) ->
        :fail

      true ->
        verdict(
          Enum.all?([l1, l2], fn l ->
            has?(l, "data_store_persistent", 1) and has?(l, "main_frame_origin_match", 1)
          end)
        )
    end
  end

  defp webview_rule("TW-T05-04", records) do
    last_l1 = last(launch(records, 1), "outbox_active")
    first_l2 = first(launch(records, 2), "outbox_active")

    case {last_l1, first_l2} do
      {nil, _} -> :missing
      {_, nil} -> :missing
      {a, b} -> verdict(a.value == b.value)
    end
  end

  defp webview_rule("TW-T06-04", records) do
    case last(records, "outbox_active") do
      nil -> :missing
      %{value: value} -> verdict(value == 0)
    end
  end

  defp webview_rule("TW-T06-05", records) do
    active = of_kind(records, "outbox_active")
    busy = active |> Enum.filter(&(&1.value > 0)) |> List.last()

    cond do
      active == [] ->
        :missing

      busy == nil ->
        :fail

      true ->
        drain = Enum.find(active, &(&1.value == 0 and &1.i > busy.i))
        saved = Enum.filter(of_kind(records, "island_state"), &(&1.value == "saved_account"))

        cond do
          drain == nil -> :fail
          Enum.any?(saved, &(&1.i > busy.i and &1.i < drain.i)) -> :fail
          true -> verdict(Enum.any?(saved, &(&1.i > drain.i)))
        end
    end
  end

  defp webview_rule("TW-T07-03", records) do
    review = Enum.find(of_kind(records, "island_state"), &(&1.value == "needs_review"))

    if review == nil do
      :fail
    else
      before_state =
        records |> of_kind("outbox_retained") |> Enum.filter(&(&1.i < review.i)) |> List.last()

      after_state = records |> of_kind("outbox_retained") |> Enum.find(&(&1.i > review.i))
      retained = before_state || after_state
      verdict(retained != nil and retained.value >= 1)
    end
  end

  defp webview_rule("TW-T07-04", records),
    do: verdict(has?(records, "island_state", "needs_review"))

  defp webview_rule("TW-T07-05", records) do
    review = of_kind(records, "route_path") |> Enum.find(&(&1.value == "review"))
    retry = of_kind(records, "retry_offered")
    zero = Enum.find(retry, &(&1.value == 0))

    cond do
      retry == [] -> :missing
      review == nil or zero == nil -> :fail
      true -> verdict(Enum.any?(retry, &(&1.value == 1 and &1.i > zero.i)))
    end
  end

  defp webview_rule("TW-T08-01", records) do
    active = of_kind(records, "outbox_active")
    busy = active |> Enum.filter(&(&1.value > 0)) |> List.last()

    cond do
      active == [] ->
        :missing

      busy == nil ->
        :fail

      true ->
        fenced? =
          Enum.any?(of_kind(records, "island_state"), &(&1.value == "fenced" and &1.i > busy.i))

        drained? = List.last(active).value == 0 and List.last(active).i > busy.i
        verdict(fenced? and drained? and retained_unchanged?(records))
    end
  end

  defp webview_rule("TW-T09-01", records),
    do: verdict(has?(records, "island_state", "entry_disabled"))

  defp webview_rule("TW-T09-05", records),
    do: verdict(has?(records, "island_state", "unavailable"))

  defp webview_rule("TW-T09-03", records) do
    if of_kind(records, "outbox_retained") == [],
      do: :missing,
      else: verdict(retained_unchanged?(records))
  end

  # From the first retained sample of at least 1 on, retained never changes and never drops below 1.
  defp retained_unchanged?(records) do
    case records |> of_kind("outbox_retained") |> Enum.drop_while(&(&1.value < 1)) do
      [] -> false
      [first | rest] -> Enum.all?(rest, &(&1.value == first.value))
    end
  end

  # ------------------------------------------------------------------ app_process/2

  @spec app_process(map(), String.t()) :: [map()]
  def app_process(inputs, run_id) do
    process = Map.get(inputs, :process) || %{}
    launches = channel(inputs, :c1, :app_process)

    one =
      cond do
        launches == nil or Map.get(process, :first_pid_absent) == nil ->
          :missing

        true ->
          samples = Enum.filter(launches, &(&1.kind == "launch"))
          values = Enum.map(samples, & &1.value)

          verdict(
            length(samples) == 2 and Enum.uniq(values) == values and
              Map.get(process, :first_pid_absent) == true
          )
      end

    two =
      case {Map.get(process, :exec_after_install), Map.get(process, :exec_after_c1),
            Map.get(process, :installs_before_c1)} do
        {a, b, n} when is_binary(a) and is_binary(b) and is_integer(n) ->
          verdict(a == b and n == 1)

        _ ->
          :missing
      end

    [emit_app_process(run_id, "TW-T05-01", one), emit_app_process(run_id, "TW-T05-02", two)]
  end

  # ------------------------------------------------------------------ fault_boundary/2

  @spec fault_boundary(map(), String.t()) :: [map()]
  def fault_boundary(inputs, run_id) do
    boundary = Map.get(inputs, :boundary)

    results = %{
      "TW-T02-04" =>
        boundary_rule(boundary, "offline", fn c ->
          refused(c, :webview_document) + refused(c, :webview_static) > 0
        end),
      "TW-T02-05" =>
        boundary_rule(boundary, "offline_install", fn c -> refused(c, :native_media) > 0 end),
      "TW-T04-07" =>
        boundary_rule(boundary, "playback", fn c ->
          passed(c, :native_media) + refused(c, :native_media) == 0
        end)
    }

    for {id, result} <- Enum.sort(results), do: emit_fault_boundary(run_id, id, result)
  end

  defp boundary_rule(nil, _epoch, _fun), do: :missing

  defp boundary_rule(%{counters: counters, epochs: epochs}, epoch, fun) do
    if epoch in epochs, do: verdict(fun.(Map.get(counters, epoch, %{}))), else: :missing
  end

  defp refused(counts, class), do: get_in(counts, [class, :refused]) || 0
  defp passed(counts, class), do: get_in(counts, [class, :passed]) || 0

  # ------------------------------------------------------------------ phoenix_ecto/2

  @spec phoenix_ecto(map(), String.t()) :: [map()]
  def phoenix_ecto(inputs, run_id) do
    backend = Map.get(inputs, :backend)

    rules = [
      {"TW-T02-03",
       fn b ->
         with {:ok, s} <- snap(b, "replay") do
           verdict(
             obs(s, :synthetic_authority_admitted) >= 1 and obs(s, :other_authority_admitted) == 0
           )
         end
       end},
      {"TW-T06-01",
       fn b ->
         with {:ok, d} <- delta(b, "replay") do
           verdict(d.observe.admitted >= 1 and d.rows.total == 2)
         end
       end},
      {"TW-T06-02",
       fn b ->
         with {:ok, d} <- delta(b, "replay"), do: verdict(d.observe.duplicate_delivery >= 1)
       end},
      {"TW-T06-03",
       fn b ->
         with {:ok, s} <- snap(b, "replay"), {:ok, base} <- snap(b, "baseline") do
           verdict(s.rows.total == s.rows.distinct and s.rows.accepted - base.rows.accepted == 2)
         end
       end},
      {"TW-T07-01",
       fn b ->
         with {:ok, d} <- delta(b, "recovery"),
              do: verdict(d.observe.rejected >= 1 and d.rows.rejected >= 1)
       end},
      {"TW-T07-02",
       fn b ->
         with {:ok, d} <- delta(b, "recovery"), do: verdict(d.observe.scope_conflict >= 1)
       end},
      {"TW-T08-02",
       fn b ->
         with {:ok, d} <- delta(b, "scope_fence"),
              do: verdict(Enum.sum(for key <- @denials, do: Map.get(d.observe, key, 0)) >= 1)
       end},
      {"TW-T08-03",
       fn b ->
         with {:ok, d} <- delta(b, "scope_fence"), {:ok, s} <- snap(b, "scope_fence") do
           verdict(d.rows.total == 0 and s.rows.multi_scope == 0)
         end
       end},
      {"TW-T09-02",
       fn b ->
         with {:ok, d} <- delta(b, "disablement"),
              do: verdict(d.observe.authorization_denied >= 1)
       end},
      {"TW-T09-04",
       fn b ->
         with {:ok, d} <- delta(b, "disablement"), do: verdict(d.rows.total == 0)
       end}
    ]

    for {id, fun} <- rules do
      result = if backend == nil, do: :missing, else: fun.(backend)
      emit_phoenix_ecto(run_id, id, normalize(result))
    end
  end

  defp normalize(:missing), do: :missing
  defp normalize(:error), do: :missing
  defp normalize(other), do: other

  defp snap(backend, name) do
    case Map.get(backend, name) do
      %{observe: %{}, rows: %{}} = snapshot -> {:ok, snapshot}
      _ -> :missing
    end
  end

  # End-of-epoch snapshot minus the nearest earlier snapshot (or the run baseline).
  defp delta(backend, epoch) do
    index = Enum.find_index(@epoch_order, &(&1 == epoch))

    previous =
      @epoch_order
      |> Enum.take(index)
      |> Enum.reverse()
      |> Enum.find_value(fn name -> if match?({:ok, _}, snap(backend, name)), do: name end)

    with {:ok, current} <- snap(backend, epoch),
         {:ok, before_snapshot} <- snap(backend, previous || "baseline") do
      {:ok,
       %{
         observe:
           Map.new(current.observe, fn {k, v} ->
             {k, v - Map.get(before_snapshot.observe, k, 0)}
           end),
         rows:
           Map.new(current.rows, fn {k, v} -> {k, v - Map.get(before_snapshot.rows, k, 0)} end)
       }}
    end
  end

  defp obs(snapshot, key), do: Map.get(snapshot.observe, key, 0)

  @doc """
  Fixed read-only `COUNT` queries against the run's database through `sqlite3 -readonly`.
  Returns integers only.
  """
  @spec read_rows(TwinRuntime.t(), Path.t()) :: {:ok, map()} | {:error, term()}
  def read_rows(runtime, database_path) do
    sql =
      "SELECT COUNT(*) FROM review_events; " <>
        "SELECT COUNT(*) FROM review_events WHERE status = 'accepted'; " <>
        "SELECT COUNT(*) FROM review_events WHERE status = 'rejected'; " <>
        "SELECT COUNT(DISTINCT client_mutation_id) FROM review_events; " <>
        "SELECT COUNT(*) FROM (SELECT client_mutation_id FROM review_events " <>
        "GROUP BY client_mutation_id HAVING COUNT(DISTINCT scope_ref) > 1);"

    with sqlite when is_binary(sqlite) <- System.find_executable("sqlite3"),
         {:ok, output, 0} <-
           capture(runtime, unique_name(:sqlite), sqlite, [
             "-readonly",
             "-batch",
             "-noheader",
             database_path,
             sql
           ]),
         [total, accepted, rejected, distinct, multi] <- parse_ints(output) do
      {:ok,
       %{
         total: total,
         accepted: accepted,
         rejected: rejected,
         distinct: distinct,
         multi_scope: multi
       }}
    else
      _ -> {:error, :rows_unavailable}
    end
  end

  defp parse_ints(output) do
    values = output |> String.split("\n", trim: true) |> Enum.map(&Integer.parse/1)
    if Enum.all?(values, &match?({_, ""}, &1)), do: Enum.map(values, &elem(&1, 0)), else: :error
  end

  @doc "Closed integer counters from the backend's `/_e2e/twin/observe` endpoint."
  @spec read_observe(pos_integer()) :: {:ok, map()} | {:error, term()}
  def read_observe(upstream_port) do
    case TwinFaultBoundary.upstream_request(upstream_port, "GET", "/_e2e/twin/observe") do
      {:ok, 200, body} -> decode_observe(body)
      _ -> {:error, :observe_unavailable}
    end
  end

  @doc """
  Decodes the backend's closed counter body. The key set must equal the backend's counter
  list exactly and every value must be a non-negative integer; keys map through a fixed
  table, never through atom lookup, so a counter the runner does not otherwise mention
  still decodes.
  """
  @spec decode_observe(binary()) :: {:ok, map()} | {:error, :observe_unavailable}
  def decode_observe(body) when is_binary(body) do
    with {:ok, %{"data" => %{} = data}} <- Jason.decode(body),
         true <- Enum.sort(Map.keys(data)) == Enum.sort(Map.keys(@observe_keys)),
         true <- Enum.all?(data, fn {_k, v} -> is_integer(v) and v >= 0 end) do
      {:ok, Map.new(data, fn {k, v} -> {Map.fetch!(@observe_keys, k), v} end)}
    else
      _ -> {:error, :observe_unavailable}
    end
  end

  def decode_observe(_), do: {:error, :observe_unavailable}

  # ------------------------------------------------------------------ freeze (D-19)

  @media_rel "examples/phoenix_host/native/ios/CrosswakeProofLane/Resources/ReferenceLearningBundle/pronunciation.aiff"
  @manifest_rel "examples/phoenix_host/native/ios/crosswake_shell/Fixtures/crosswake_manifest.json"
  @activation_rel "examples/phoenix_host/native/ios/crosswake_shell/Fixtures/route_activation.json"
  @study_js_rel "examples/phoenix_host/priv/static/offline_study.js"
  @lock_rels ["mix.lock", "examples/phoenix_host/mix.lock"]

  @doc """
  Computes the expected identities before the simulator launches and writes them to
  `expectations.json` in the run root. Options: `:backend_digest` (a zero-arity function
  returning `{:ok, hex}`; the default compiles the example host in `MIX_ENV=test` through a
  bounded child and hashes the compiled beams).
  """
  @spec freeze(TwinRuntime.t(), Path.t(), keyword()) :: {:ok, map()} | {:blocked, atom()}
  def freeze(runtime, identity_path, opts \\ []) do
    path = runtime.candidate_path

    with {:ok, gate} <- source_gate(runtime, identity_path, opts),
         {:ok, backend} <- backend_digest(runtime, path, opts) do
      %{identity: identity, head: head, tree: tree, locks: locks, study_js: study_js} = gate
      resources = [identity.manifest, identity.activation, study_js]

      with {:ok, expectations} <-
             TwinReceipt.freeze_expectations(%{
               run_id: runtime.run_id,
               candidate_head: head,
               candidate_tree: tree,
               lock_digests: locks,
               resource_digests: resources,
               fixture_digests: [identity.media]
             }) do
        frozen = %{
          expectations: expectations,
          candidate_path: path,
          head: head,
          tree: tree,
          lock_digests: locks,
          identity: identity,
          study_js: study_js,
          backend_build: backend
        }

        write_expectations(runtime.run_root, frozen)
        {:ok, frozen}
      else
        _ -> {:blocked, :identity_unknown}
      end
    else
      {:blocked, _} = blocked -> blocked
      _ -> {:blocked, :identity_unknown}
    end
  end

  @doc """
  The read-only prefix of `freeze/3`: reads the identity file, checks that `HEAD` and its
  tree equal the target's `candidate_head` and `candidate_tree` (read twice, so a move
  between reads is a mismatch), that the working tree is clean, and digests the lock files
  and the served study script. The target is a plain map with `:candidate_path`,
  `:candidate_head`, `:candidate_tree` and an optional `:run_root`. It never writes a file.
  Options: `:git_cmd`, `:git_timeout_ms`, `:tmp_dir`, `:remove_dir`.
  """
  @spec source_gate(map(), Path.t(), keyword()) ::
          {:ok,
           %{
             identity: map(),
             head: String.t(),
             tree: String.t(),
             locks: [String.t()],
             study_js: String.t()
           }}
          | {:blocked, atom()}
  def source_gate(
        %{candidate_path: path, candidate_head: want_head, candidate_tree: want_tree} = target,
        identity_path,
        opts \\ []
      ) do
    probe_opts =
      opts
      |> Keyword.take([:git_cmd, :git_timeout_ms, :tmp_dir, :remove_dir])
      |> Keyword.put(:run_root, Map.get(target, :run_root))

    with {:ok, identity} <- read_identity(identity_path),
         {:ok, head} <- git(path, ["rev-parse", "HEAD"], probe_opts),
         {:ok, tree} <- git(path, ["rev-parse", "HEAD^{tree}"], probe_opts),
         :ok <- same(head, want_head),
         :ok <- same(tree, want_tree),
         :ok <- clean_tree(path, probe_opts),
         {:ok, locks} <- lock_digests(path),
         {:ok, study_js} <- file_digest(Path.join(path, @study_js_rel)) do
      {:ok, %{identity: identity, head: head, tree: tree, locks: locks, study_js: study_js}}
    else
      {:blocked, _} = blocked -> blocked
      _ -> {:blocked, :identity_unknown}
    end
  end

  defp read_identity(path) do
    with {:ok, bytes} <- File.read(path),
         {:ok, %{"media" => %{"sha256" => media, "size" => size}, "generated" => generated}} <-
           Jason.decode(bytes),
         %{"manifest_sha256" => manifest, "activation_sha256" => activation} <- generated,
         true <- Enum.all?([media, manifest, activation], &digest?/1),
         true <- is_integer(size) do
      {:ok, %{media: media, size: size, manifest: manifest, activation: activation}}
    else
      _ -> {:blocked, :identity_unknown}
    end
  end

  defp same(a, b), do: if(a == b, do: :ok, else: {:blocked, :identity_mismatch})

  # ---------------------------------------------------------------- git invocation (D-05, D-23)
  #
  # Every git spawn is built by `git_invocation/3` and made by `run_git/4`. The user's and
  # the system's config, replacement objects, attribute sources, an external diff, an
  # fsmonitor and the repository-redirecting variables are all out of the picture, so the
  # candidate path alone decides which tree is read. Only GIT_INDEX_FILE varies per call.
  @empty_tree "4b825dc642cb6eb9a060e54bf8d69288fbee4904"

  @git_scrub_names ~w(GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY
                      GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_COMMON_DIR GIT_NAMESPACE
                      GIT_CEILING_DIRECTORIES GIT_CONFIG GIT_CONFIG_COUNT GIT_CONFIG_PARAMETERS
                      GIT_PREFIX GIT_ATTR_SOURCE GIT_EXTERNAL_DIFF GIT_EXEC_PATH)

  @git_fixed_env %{
    "GIT_CONFIG_GLOBAL" => "/dev/null",
    "GIT_CONFIG_NOSYSTEM" => "1",
    "GIT_NO_REPLACE_OBJECTS" => "1",
    "GIT_ATTR_NOSYSTEM" => "1",
    "GIT_OPTIONAL_LOCKS" => "0",
    "GIT_TERMINAL_PROMPT" => "0",
    "LC_ALL" => "C"
  }

  @git_env @git_scrub_names
           |> Map.new(&{&1, nil})
           |> Map.merge(@git_fixed_env)
           |> Enum.sort()

  @git_pins [
    "--no-optional-locks",
    "--no-replace-objects",
    "--attr-source=" <> @empty_tree,
    "-c",
    "core.fsmonitor=false",
    "-c",
    "core.filemode=true",
    "-c",
    "core.excludesFile=/dev/null",
    "-c",
    "core.attributesFile=/dev/null",
    "-c",
    "core.quotePath=false",
    "-c",
    "core.ignoreStat=false",
    "-c",
    "status.showUntrackedFiles=all",
    "-c",
    "core.autocrlf=false"
  ]

  @max_dirty_count 1_000_000
  @min_git_version {2, 41}
  @flag_tags ~c"HhSsMmRrCcKk?"
  @git_timeout_ms 60_000

  # stderr is discarded by the shell at the file-descriptor level; the candidate path
  # is only ever an argv element, never part of the script text. `mode` is `:pinned`
  # (the pins plus `-C path`) or `:bare` (the version call only, no pins, no `-C`);
  # `extra_env` may only add GIT_INDEX_FILE.
  defp git_invocation(path, args, {mode, extra_env}) do
    argv =
      case mode do
        :pinned -> @git_pins ++ ["-C", path | args]
        :bare -> args
      end

    env =
      extra_env
      |> Map.take(["GIT_INDEX_FILE"])
      |> Enum.reduce(@git_env, fn {name, value}, acc ->
        List.keystore(acc, name, 0, {name, value})
      end)

    {"sh", ["-c", "exec \"$@\" 2>/dev/null", "sh", "git" | argv],
     [env: env, stderr_to_stdout: false]}
  end

  # The only place git is spawned. A NUL-bearing path or argument is refused before any
  # spawn; a spawn failure is `:unavailable` and its message is never read (it can carry
  # a path); a hung git is shut down at the timeout.
  defp run_git(path, args, opts, mode_env \\ {:pinned, %{}}) do
    if Enum.any?([path | args], &nul?/1) do
      :unavailable
    else
      {cmd, argv, cmd_opts} = git_invocation(path, args, mode_env)
      git_cmd = Keyword.get(opts, :git_cmd, &System.cmd/3)
      timeout = Keyword.get(opts, :git_timeout_ms, @git_timeout_ms)

      task =
        Task.async(fn ->
          try do
            git_cmd.(cmd, argv, cmd_opts)
          rescue
            ArgumentError -> :unavailable
            ErlangError -> :unavailable
          end
        end)

      case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
        {:ok, result} -> result
        _ -> :unavailable
      end
    end
  end

  defp nul?(value), do: not is_binary(value) or String.contains?(value, <<0>>)

  defp git(path, args, opts) do
    case run_git(path, args, opts) do
      {out, 0} -> {:ok, String.trim(out)}
      _ -> {:blocked, :prerequisite_missing}
    end
  end

  # ---------------------------------------------------------------- source probe (D-01..D-03)

  @doc """
  Fails closed unless the candidate working tree matches its commit: any tracked file
  that differs from `HEAD` in content or mode however git is set up to hide it, any
  hidden-flag index entry, any untracked non-ignored path, or any active rule in
  `.git/info/exclude`, is `:source_dirty`. Output is only counted, never returned.
  Option `:git_cmd` replaces `System.cmd/3` (used to model an unavailable git). This is
  a view over `probe_source/2`.
  """
  @spec clean_tree(Path.t(), keyword()) :: :ok | {:blocked, :source_dirty | :prerequisite_missing}
  def clean_tree(path, opts \\ []) do
    case probe_source(path, opts) do
      {:ok, %{modified: 0, flagged: 0, excludes: 0}} -> :ok
      {:ok, _} -> {:blocked, :source_dirty}
      {:refused, _} -> {:blocked, :source_dirty}
      :unavailable -> {:blocked, :prerequisite_missing}
    end
  end

  @doc """
  Separate counts for a countable probe: `%{modified:, flagged:, excludes:}` when the probe
  answers `{:ok, counts}` and the sum is within the receipt measure bound, else `nil`
  (refused, unavailable or out of bounds; `nil` means unknown, never clean). Counts are
  findings, not distinct files: a path can count once as modified and once as flagged, and
  a staged rename is two findings.
  """
  @spec dirty_counts(Path.t(), keyword()) ::
          %{modified: non_neg_integer(), flagged: non_neg_integer(), excludes: non_neg_integer()}
          | nil
  def dirty_counts(path, opts \\ []) do
    case probe_source(path, opts) do
      {:ok, %{modified: m, flagged: f, excludes: x} = counts}
      when m + f + x <= @max_dirty_count ->
        counts

      _ ->
        nil
    end
  end

  @doc """
  Sum of `dirty_counts/2` (modified + flagged + excludes), or `nil` when unknown. Counts
  are findings, not distinct files: a staged rename counts twice.
  """
  @spec dirty_count(Path.t(), keyword()) :: non_neg_integer() | nil
  def dirty_count(path, opts \\ []) do
    case dirty_counts(path, opts) do
      %{modified: m, flagged: f, excludes: x} -> m + f + x
      nil -> nil
    end
  end

  @doc false
  def max_dirty_count, do: @max_dirty_count

  @block_tail ", then write a new prepared record and run into a new run root."

  @doc """
  The one-line next action for a blocked source, built from the probe result. Clauses for
  changed or untracked files (M), hidden-flag index entries (F) and local ignore rules (X)
  come in that order, zero counts are dropped, and only counts are ever shown, never a
  path, file name or porcelain text. A refused configuration, an unavailable probe, a sum
  above the receipt bound and an all-zero map each get a fixed text without a digit.
  Counts are findings, not distinct files: a path can be both changed and flagged, and a
  staged rename is two findings.
  """
  @spec source_block_action(term()) :: String.t()
  def source_block_action({:ok, %{modified: m, flagged: f, excludes: x}})
      when is_integer(m) and is_integer(f) and is_integer(x) and m >= 0 and f >= 0 and x >= 0 and
             m + f + x >= 1 and m + f + x <= @max_dirty_count do
    clauses =
      [
        {m, "#{m} changed or untracked #{plural(m, "file", "files")}",
         "commit or remove the changes"},
        {f,
         "#{f} tracked #{plural(f, "file", "files")} marked unchanged in git's index " <>
           "(assume-unchanged or skip-worktree flags), so edits to " <>
           "#{plural(f, "it", "them")} would go unseen",
         "clear the flags with git update-index --no-assume-unchanged or " <>
           "git update-index --no-skip-worktree (git ls-files -v shows them as entries not marked H)"},
        {x, "#{x} local ignore #{plural(x, "rule", "rules")} in .git/info/exclude",
         "remove the ignore rules from .git/info/exclude"}
      ]
      |> Enum.reject(fn {n, _, _} -> n == 0 end)

    found = clauses |> Enum.map(&elem(&1, 1)) |> Enum.join("; and ")
    remedy = clauses |> Enum.map(&elem(&1, 2)) |> Enum.join("; ") |> capitalize_first()

    "The candidate has #{found}. #{remedy}#{@block_tail}"
  end

  def source_block_action({:refused, :hiding_config}),
    do:
      "The candidate's git configuration can hide changes (a worktree redirect, a filter, " <>
        "or .git/info/attributes); remove it" <> @block_tail

  def source_block_action({:refused, :not_toplevel}),
    do:
      "The candidate is not the top-level directory of its git work tree (a subdirectory " <>
        "was given, or a core.worktree setting points git at another directory). Use the " <>
        "repository's top-level directory as the candidate, and if git config --local --get " <>
        "core.worktree prints a value, remove that setting" <> @block_tail

  def source_block_action(_unknown),
    do:
      "The candidate has changes git could not count. Run git ls-files -v in the candidate " <>
        "(entries not marked H are flagged) and read the local exclude file " <>
        ".git/info/exclude to find them, and commit or remove them" <> @block_tail

  defp plural(1, one, _many), do: one
  defp plural(_n, _one, many), do: many

  defp capitalize_first(<<first::utf8, rest::binary>>), do: String.upcase(<<first::utf8>>) <> rest

  @doc """
  Probes the candidate's source against its commit and returns counts only, never a path,
  porcelain text or exception message.

  The working tree is compared with a fresh index built from `HEAD` in a private,
  contained temporary directory (so index flags and stat caches cannot hide a change);
  `modified` counts the status records of that comparison, `flagged` counts the unique
  paths whose entry in the real index carries a tag other than `H` (assume-unchanged,
  skip-worktree, unmerged and the rest), and `excludes` counts active rules in
  `.git/info/exclude`.

  Returns `{:ok, %{modified:, flagged:, excludes:}}`, `{:refused, :hiding_config |
  :not_toplevel}` for a configuration that can redirect or blind git, or `:unavailable`
  when git, its version, the temporary directory or any output cannot be trusted.

  Limits, stated plainly: global git config is ignored, so `safe.directory` entries do
  not apply and a candidate owned by another user is `:unavailable`; a filesystem
  without file modes yields a false `source_dirty` because `core.filemode=true` is
  pinned; a probe spawns about ten git processes and nothing is cached.

  Options: `:git_cmd`, `:git_timeout_ms`, `:tmp_dir` (absolute base for the temporary
  index), `:remove_dir` (replaces the directory removal), `:run_root` (a directory the
  temporary index must not lie inside).
  """
  @spec probe_source(Path.t(), keyword()) ::
          {:ok,
           %{modified: non_neg_integer(), flagged: non_neg_integer(), excludes: non_neg_integer()}}
          | {:refused, :hiding_config | :not_toplevel}
          | :unavailable
  def probe_source(path, opts \\ []) do
    with false <- nul?(path),
         :ok <- git_version_ok(path, opts),
         :ok <- config_refusal(path, opts),
         :ok <- attributes_refusal(path, opts),
         :ok <- toplevel_refusal(path, opts),
         {:ok, git_dir} <- absolute_git_dir(path, opts),
         {:ok, real_entries} <- list_index(path, %{}, opts),
         {:ok, modified} <-
           with_private_index(path, git_dir, opts, fn index ->
             fresh_modified(path, index, opts)
           end),
         {:ok, excludes} <- exclude_rules(path, opts) do
      flagged =
        real_entries
        |> Enum.reject(fn {tag, _} -> tag == ?H end)
        |> Enum.uniq_by(fn {_, entry} -> entry end)
        |> length()

      {:ok, %{modified: modified, flagged: flagged, excludes: excludes}}
    else
      {:refused, _} = refused -> refused
      _ -> :unavailable
    end
  end

  # D-04, D-24: configuration that the pins cannot neutralize. Read before the toplevel
  # (L12) so a bare repository is refused here rather than being unavailable. The `-z`
  # listing is `key\nvalue\0` per entry (a valueless key means true); keys are downcased.
  defp config_refusal(path, opts) do
    with {out, 0} <-
           run_git(path, ["config", "--list", "--local", "--includes", "-z"], opts),
         true <- out != "" and String.ends_with?(out, <<0>>) do
      entries =
        out
        |> String.split(<<0>>)
        |> Enum.drop(-1)
        |> Enum.map(fn record ->
          case String.split(record, "\n", parts: 2) do
            [key] -> {String.downcase(key), nil}
            [key, value] -> {String.downcase(key), String.downcase(String.trim(value))}
          end
        end)

      if Enum.any?(entries, &hiding_entry?/1), do: {:refused, :hiding_config}, else: :ok
    else
      _ -> :unavailable
    end
  end

  defp hiding_entry?({"filter." <> _, _}), do: true
  defp hiding_entry?({"core.bare", value}), do: truthy?(value)
  defp hiding_entry?({"core.symlinks", value}), do: falsy?(value)
  defp hiding_entry?({"extensions.worktreeconfig", value}), do: truthy?(value)
  defp hiding_entry?(_), do: false

  defp truthy?(value), do: value in [nil, "true", "yes", "on", "1"]
  defp falsy?(value), do: value in ["false", "no", "off", "0"]

  # D-04: an active line in info/attributes can hide or rewrite content for every command.
  defp attributes_refusal(path, opts) do
    with {out, 0} <- run_git(path, ["rev-parse", "--git-path", "info/attributes"], opts),
         file = Path.expand(String.trim(out), path),
         {:ok, lines} <- read_exclude(file) do
      if Enum.any?(lines, &active_rule?/1), do: {:refused, :hiding_config}, else: :ok
    else
      _ -> :unavailable
    end
  end

  # D-25: the candidate must itself be the top-level directory of its work tree; compared
  # by {major_device, inode}, never by path text. A subdirectory or a core.worktree
  # redirect is its own refusal reason.
  defp toplevel_refusal(path, opts) do
    with {out, 0} <- run_git(path, ["rev-parse", "--show-toplevel"], opts),
         top = String.replace_suffix(out, "\n", ""),
         true <- top != "",
         {:ok, top_id} <- identity_of(top),
         {:ok, path_id} <- identity_of(path) do
      if top_id == path_id, do: :ok, else: {:refused, :not_toplevel}
    else
      _ -> :unavailable
    end
  end

  defp identity_of(path) do
    case stat_identity(path) do
      :error -> :error
      id -> {:ok, id}
    end
  end

  # D-06, D-30: numeric {major, minor}; the call carries no pins because older gits
  # reject the pinned argv and would hide the real reason.
  defp git_version_ok(path, opts) do
    with {out, 0} <- run_git(path, ["--version"], opts, {:bare, %{}}),
         [_, major, minor] <- Regex.run(~r/\Agit version (\d+)\.(\d+)/, out),
         true <- {String.to_integer(major), String.to_integer(minor)} >= @min_git_version do
      :ok
    else
      _ -> :unavailable
    end
  end

  defp absolute_git_dir(path, opts) do
    case run_git(path, ["rev-parse", "--absolute-git-dir"], opts) do
      {out, 0} ->
        dir = String.trim(out)
        if dir != "" and Path.type(dir) == :absolute, do: {:ok, dir}, else: :unavailable

      _ ->
        :unavailable
    end
  end

  # D-02: `ls-files -v -z` is `<tag><space><path>\0` per entry; anything else, an empty
  # listing or a missing final NUL cannot be trusted.
  defp list_index(path, env, opts) do
    with {out, 0} <- run_git(path, ["ls-files", "-v", "-z"], opts, {:pinned, env}),
         true <- out != "" and String.ends_with?(out, <<0>>),
         records = out |> String.split(<<0>>) |> Enum.drop(-1),
         {:ok, entries} <- parse_index_records(records, []) do
      {:ok, entries}
    else
      _ -> :unavailable
    end
  end

  defp parse_index_records([], acc), do: {:ok, Enum.reverse(acc)}

  defp parse_index_records([<<tag, ?\s, entry::binary>> | rest], acc)
       when tag in @flag_tags and entry != "",
       do: parse_index_records(rest, [{tag, entry} | acc])

  defp parse_index_records(_, _), do: :error

  # D-01: build an index from HEAD alone, then compare the working tree with it.
  defp fresh_modified(path, index, opts) do
    env = %{"GIT_INDEX_FILE" => index}

    with {_, 0} <- run_git(path, ["read-tree", "HEAD"], opts, {:pinned, env}),
         {:ok, entries} <- list_index(path, env, opts),
         [] <- Enum.reject(entries, fn {tag, _} -> tag == ?H end),
         {out, 0} <-
           run_git(
             path,
             [
               "status",
               "--porcelain=v1",
               "-z",
               "--untracked-files=all",
               "--ignore-submodules=none"
             ],
             opts,
             {:pinned, env}
           ) do
      count_status(out)
    else
      _ -> :unavailable
    end
  end

  # Fresh-index status has no staged side, so a record is `<X> <Y> <space> <path>` with
  # X a space or `?`; a rename or copy record cannot occur and is not trusted.
  defp count_status(""), do: {:ok, 0}

  defp count_status(out) do
    if String.ends_with?(out, <<0>>) do
      records = out |> String.split(<<0>>) |> Enum.drop(-1)

      if Enum.all?(records, &status_record?/1), do: {:ok, length(records)}, else: :unavailable
    else
      :unavailable
    end
  end

  defp status_record?(<<x, _y, ?\s, entry::binary>>) when x not in [?R, ?C] and entry != "",
    do: true

  defp status_record?(_), do: false

  # D-28: the temporary index is absolute, created only after its base is shown to lie
  # outside the candidate, its git dir and the run root, and always removed.
  defp with_private_index(path, git_dir, opts, fun) do
    base = Keyword.get(opts, :tmp_dir) || System.tmp_dir()
    remove = Keyword.get(opts, :remove_dir, &File.rm_rf/1)
    roots = [path, git_dir, Keyword.get(opts, :run_root)]
    name = "crosswake-twin-probe-" <> Base.encode16(:crypto.strong_rand_bytes(8), case: :lower)

    with true <- is_binary(base) and Path.type(base) == :absolute,
         true <- outside?(base, roots),
         dir = Path.join(base, name),
         :ok <- File.mkdir(dir) do
      result =
        try do
          with :ok <- File.chmod(dir, 0o700),
               true <- outside?(dir, roots) do
            fun.(Path.join(dir, "index"))
          else
            _ -> :unavailable
          end
        rescue
          _ -> :unavailable
        end

      removal = remove.(dir)
      removed? = (removal == :ok or match?({:ok, _}, removal)) and not File.exists?(dir)
      if not removed?, do: File.rm_rf(dir)

      if removed?, do: result, else: :unavailable
    else
      _ -> :unavailable
    end
  end

  # True when `dir` is not inside any listed directory. Compared by device and inode while
  # walking real parents (`..`), so a symlink alias cannot hide containment and a sibling
  # sharing only a name prefix is not mistaken for it.
  defp outside?(dir, roots) do
    [path, git_dir | optional] = roots
    required = [stat_identity(path), stat_identity(git_dir)]
    extra = for root <- optional, is_binary(root), id = stat_identity(root), id != :error, do: id

    :error not in required and not contained_in?(dir, required ++ extra)
  end

  defp contained_in?(path, identities), do: walk_up(path, identities, 0)

  defp walk_up(_path, _identities, depth) when depth > 255, do: true

  defp walk_up(path, identities, depth) do
    case stat_identity(path) do
      :error ->
        # a path that does not exist yet cannot hold the roots; its parent decides
        parent = Path.dirname(path)
        parent != path and walk_up(parent, identities, depth + 1)

      identity ->
        if identity in identities do
          true
        else
          up = Path.join(path, "..")

          case stat_identity(up) do
            ^identity -> false
            :error -> true
            _ -> walk_up(up, identities, depth + 1)
          end
        end
    end
  end

  defp stat_identity(path) do
    case File.stat(path) do
      {:ok, %{major_device: dev, inode: ino}} -> {dev, ino}
      _ -> :error
    end
  end

  # D-03: active rules in `.git/info/exclude` hide untracked paths from every status, so
  # their count is its own signal.
  defp exclude_rules(path, opts) do
    with {out, 0} <- run_git(path, ["rev-parse", "--git-path", "info/exclude"], opts),
         file = Path.expand(String.trim(out), path),
         {:ok, lines} <- read_exclude(file) do
      {:ok, Enum.count(lines, &active_rule?/1)}
    else
      _ -> :error
    end
  end

  defp read_exclude(file) do
    case File.read(file) do
      {:ok, text} -> {:ok, String.split(text, ["\r\n", "\n"])}
      {:error, :enoent} -> {:ok, []}
      {:error, _} -> :error
    end
  end

  defp active_rule?(line) do
    trimmed = String.trim(line)
    trimmed != "" and not String.starts_with?(trimmed, "#")
  end

  defp lock_digests(path) do
    digests =
      for rel <- @lock_rels, match?({:ok, _}, File.stat(Path.join(path, rel))) do
        {:ok, digest} = file_digest(Path.join(path, rel))
        digest
      end

    if digests == [], do: {:blocked, :identity_unknown}, else: {:ok, digests}
  end

  @doc "Streaming SHA-256 of a file, hashed in place."
  @spec file_digest(Path.t()) :: {:ok, String.t()} | {:error, term()}
  def file_digest(path) do
    case File.open(path, [:read, :binary]) do
      {:ok, io} ->
        try do
          digest =
            Enum.reduce_while(
              Stream.repeatedly(fn -> IO.binread(io, 65_536) end),
              :crypto.hash_init(:sha256),
              fn
                :eof, ctx -> {:halt, ctx}
                {:error, _}, ctx -> {:halt, ctx}
                data, ctx -> {:cont, :crypto.hash_update(ctx, data)}
              end
            )

          {:ok, digest |> :crypto.hash_final() |> Base.encode16(case: :lower)}
        after
          File.close(io)
        end

      error ->
        error
    end
  end

  defp backend_digest(runtime, path, opts) do
    case Keyword.get(opts, :backend_digest) do
      fun when is_function(fun, 0) -> fun.()
      _ -> compile_and_hash(runtime, path)
    end
    |> case do
      {:ok, digest} -> {:ok, digest}
      _ -> {:blocked, :prerequisite_missing}
    end
  end

  defp compile_and_hash(runtime, path) do
    host = Path.join(path, "examples/phoenix_host")
    mix = System.find_executable("mix")

    with true <- is_binary(mix),
         {:ok, _out, 0} <-
           capture(runtime, unique_name(:compile), mix, ["compile"],
             cd: host,
             env: [{"MIX_ENV", "test"}],
             deadline_ms: 900_000
           ) do
      beam_digest(Path.join(host, "_build/test/lib/crosswake_example/ebin"))
    else
      _ -> {:error, :compile_failed}
    end
  end

  @doc "SHA-256 over the sorted hex `:beam_lib.md5` values of every beam in a directory."
  @spec beam_digest(Path.t()) :: {:ok, String.t()} | {:error, :no_beams}
  def beam_digest(ebin) do
    md5s =
      for file <- Path.wildcard(Path.join(ebin, "*.beam")),
          {:ok, {_module, md5}} <- [:beam_lib.md5(String.to_charlist(file))],
          do: Base.encode16(md5, case: :lower)

    if md5s == [],
      do: {:error, :no_beams},
      else: {:ok, md5s |> Enum.sort() |> Enum.join("\n") |> sha256()}
  end

  defp write_expectations(root, frozen) do
    body =
      Jason.encode!(%{
        head: frozen.head,
        tree: frozen.tree,
        lock_digests: frozen.lock_digests,
        manifest_sha256: frozen.identity.manifest,
        activation_sha256: frozen.identity.activation,
        media_sha256: frozen.identity.media,
        served_static_sha256: frozen.study_js,
        backend_build_sha256: frozen.backend_build
      })

    File.write(Path.join(root, "expectations.json"), body)
  end

  @doc """
  Builds the observed identity joins. The live map carries what the run observed
  independently: `:installed_manifest`, `:installed_activation`, `:installed_media`,
  `:executable_stable` (boolean), `:served_js` and `:backend_build`. Source, locks and
  tracked fixtures are re-read now. An unknown part leaves its join absent (blocked).
  """
  @spec observe_identities(map(), map(), keyword()) :: map()
  def observe_identities(frozen, live, opts \\ []) do
    path = frozen.candidate_path
    probe_opts = Keyword.take(opts, [:git_cmd, :git_timeout_ms, :tmp_dir, :remove_dir])
    # HEAD and tree are read on both sides of the cleanliness probe; the source joins
    # exist only when the tree is clean and neither read differs from the frozen commit.
    head1 = ok_or_nil(git(path, ["rev-parse", "HEAD"], probe_opts))
    tree1 = ok_or_nil(git(path, ["rev-parse", "HEAD^{tree}"], probe_opts))
    clean = clean_tree(path, probe_opts) == :ok
    head2 = ok_or_nil(git(path, ["rev-parse", "HEAD"], probe_opts))
    tree2 = ok_or_nil(git(path, ["rev-parse", "HEAD^{tree}"], probe_opts))
    steady = clean and head1 == head2 and head1 == frozen.head
    steady = steady and tree1 == tree2 and tree1 == frozen.tree
    head = if(steady, do: head1)
    tree = if(steady, do: tree1)
    locks = for rel <- @lock_rels, d = digest_or_nil(Path.join(path, rel)), do: d
    tracked_manifest = digest_or_nil(Path.join(path, @manifest_rel))
    tracked_activation = digest_or_nil(Path.join(path, @activation_rel))
    tracked_media = digest_or_nil(Path.join(path, @media_rel))
    tracked_js = digest_or_nil(Path.join(path, @study_js_rel))

    installed = [live[:installed_manifest], live[:installed_activation]]
    served = live[:served_js]

    %{
      source: if(head && tree, do: TwinReceipt.identity_digest([head, tree])),
      dependency_lock: if(locks != [], do: TwinReceipt.identity_digest(locks)),
      generated_resources:
        if(Enum.all?(installed, & &1) && tracked_js,
          do: TwinReceipt.identity_digest(installed ++ [tracked_js])
        ),
      served_static:
        if(served && tracked_manifest && tracked_activation,
          do: TwinReceipt.identity_digest([tracked_manifest, tracked_activation, served])
        ),
      installed_media:
        if(live[:installed_media],
          do:
            TwinReceipt.identity_digest(
              if(tracked_media == live[:installed_media],
                do: [live[:installed_media]],
                else: [live[:installed_media], tracked_media || "absent"]
              )
            )
        ),
      installed_build:
        if(
          Enum.all?(installed, & &1) && served && head && tree &&
            is_boolean(live[:executable_stable]),
          do:
            TwinReceipt.identity_digest(
              [head, tree] ++
                installed ++ [served] ++ if(live[:executable_stable], do: [], else: ["unstable"])
            )
        ),
      backend_build:
        if(live[:backend_build] && head && tree && locks != [],
          do:
            if(live[:backend_build] == frozen.backend_build,
              do: TwinReceipt.identity_digest([head, tree | locks]),
              else: TwinReceipt.identity_digest([live[:backend_build]])
            )
        )
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  @doc """
  Gate in front of `observe_identities/2`: a candidate that is no longer clean at the
  frozen commit blocks the whole run with `:source_dirty` instead of yielding joins.
  """
  @spec checked_identities(map(), map(), keyword()) :: {:ok, map()} | {:blocked, atom()}
  def checked_identities(frozen, live, opts \\ []) do
    probe_opts = Keyword.take(opts, [:git_cmd, :git_timeout_ms, :tmp_dir, :remove_dir])

    case clean_tree(frozen.candidate_path, probe_opts) do
      :ok -> {:ok, observe_identities(frozen, live, probe_opts)}
      {:blocked, _} = blocked -> blocked
    end
  end

  defp ok_or_nil({:ok, value}), do: value
  defp ok_or_nil(_), do: nil

  defp digest_or_nil(path), do: ok_or_nil(file_digest(path))

  # ------------------------------------------------------------------ runner/3 (D-20)

  @doc """
  Emits `TW-T10-01`, `TW-T10-02` and the six in-run negative controls `TW-T10-03..08`
  against this run's own expectations and observations, through the real `TwinReceipt`
  functions. The supplied observations (and therefore the real receipt) are never altered:
  every control works on a passing copy.
  """
  @spec runner(map(), map(), [map()]) :: [map()]
  def runner(expectations, observed, observations) do
    run_id = expectations.run_id
    baseline = baseline(run_id)

    controls = [
      {"TW-T10-03", control_relabel(baseline)},
      {"TW-T10-04", control_missing(expectations, baseline)},
      {"TW-T10-05", control_identity(expectations, baseline)},
      {"TW-T10-06", control_foreign_and_replay(expectations, baseline)},
      {"TW-T10-07", control_sensitive(run_id)},
      {"TW-T10-08", control_receipt_relabel(expectations, baseline)}
    ]

    control_obs = for {id, ok?} <- controls, do: emit_runner(run_id, id, verdict(ok?))

    all = observations ++ control_obs
    complete = completeness(all)

    [
      emit_runner(run_id, "TW-T10-01", verdict(complete)),
      emit_runner(run_id, "TW-T10-02", identity_result(expectations, observed))
    ] ++ control_obs
  end

  defp identity_result(expectations, observed) do
    joins = expectations.joins

    results =
      for {join, expected} <- joins do
        case Map.get(observed, join) do
          nil -> :missing
          value when value == expected -> :pass
          _ -> :fail
        end
      end

    cond do
      Enum.any?(results, &(&1 == :fail)) -> :fail
      Enum.any?(results, &(&1 == :missing)) -> :missing
      true -> :pass
    end
  end

  # Every roster id except the runner-owned completeness id itself and the derived join id has
  # exactly one observation, from its roster owner.
  defp completeness(observations) do
    expected =
      for %{sub_observations: subs} <- TwinReceipt.roster(),
          %{id: id, owner: owner} <- subs,
          id not in ["TW-T10-01", "TW-T10-02"],
          do: {id, owner}

    actual = Enum.map(observations, &{&1.id, &1.owner})
    Enum.sort(expected) == Enum.sort(actual)
  end

  defp baseline(run_id) do
    for %{sub_observations: subs} <- TwinReceipt.roster(),
        %{id: id, owner: owner} <- subs,
        id != "TW-T10-02" do
      %{id: id, owner: owner, run_id: run_id, outcome: :passed, measure: nil, cause: nil}
    end
  end

  defp derive_status(expectations, observed, observations) do
    case TwinReceipt.derive(expectations, observed, observations) do
      {:ok, receipt} -> {:ok, receipt}
      {:error, %{rule_id: rule}} -> {:error, rule}
    end
  end

  defp control_relabel(baseline) do
    victim = Enum.find(baseline, &(&1.id == "TW-T02-01"))

    match?(
      {:error, %{rule_id: "TW-OBS-OWNER"}},
      TwinReceipt.observation(%{victim | owner: :fault_boundary})
    )
  end

  defp control_missing(expectations, baseline) do
    reduced = Enum.reject(baseline, &(&1.id == "TW-T03-01"))

    with {:ok, full} <- derive_status(expectations, expectations.joins, baseline),
         {:ok, partial} <- derive_status(expectations, expectations.joins, reduced) do
      full.overall_status == :passed and partial.overall_status == :blocked
    else
      _ -> false
    end
  end

  defp control_identity(expectations, baseline) do
    altered = Map.put(expectations.joins, :source, String.duplicate("0", 64))

    case derive_status(expectations, altered, baseline) do
      {:ok, receipt} -> receipt.overall_status == :failed
      _ -> false
    end
  end

  defp control_foreign_and_replay(expectations, baseline) do
    foreign = Enum.map(baseline, &%{&1 | run_id: "twin-ffffffffffffffff"})
    consumed = %{expectations | consumed_run_ids: [expectations.run_id]}

    derive_status(expectations, expectations.joins, foreign) == {:error, "TW-OBS-STALE"} and
      derive_status(consumed, consumed.joins, baseline) == {:error, "TW-OBS-REUSED"}
  end

  defp control_sensitive(run_id) do
    attrs = %{
      id: "TW-T02-01",
      owner: :webview,
      run_id: run_id,
      outcome: :passed,
      measure: nil,
      cause: nil,
      answer: 1
    }

    match?({:error, %{rule_id: "TW-OBS-SENSITIVE"}}, TwinReceipt.observation(attrs))
  end

  defp control_receipt_relabel(expectations, baseline) do
    case derive_status(expectations, expectations.joins, baseline) do
      {:ok, receipt} ->
        match?(
          {:error, %{rule_id: "TW-RCPT-RELABEL"}},
          TwinReceipt.validate(%{receipt | evidence_class: "physical_iphone"})
        )

      _ ->
        false
    end
  end

  # ------------------------------------------------------------------ child capture

  @doc """
  Runs one bounded child through `TwinRuntime` and returns its combined output in memory.
  Options: `:cd`, `:env`, `:deadline_ms`. Returns `{:ok, output, exit_status}` or
  `{:error, :timeout | term}`.
  """
  @spec capture(TwinRuntime.t(), atom() | String.t(), String.t(), [String.t()], keyword()) ::
          {:ok, binary(), integer()} | {:error, term()}
  def capture(runtime, name, path, args, opts \\ []) do
    spec =
      %{
        path: path,
        args: args,
        env: Keyword.get(opts, :env, []),
        deadline_ms: Keyword.get(opts, :deadline_ms, 60_000)
      }
      |> then(fn spec -> if opts[:cd], do: Map.put(spec, :cd, opts[:cd]), else: spec end)

    case TwinRuntime.start_child(runtime, name, spec) do
      {:ok, child} -> collect(runtime, child, <<>>)
      {:error, _} = error -> error
    end
  end

  defp collect(runtime, %{port: port, deadline_at: deadline} = child, acc) do
    wait = max(deadline - System.monotonic_time(:millisecond), 0)

    receive do
      {^port, {:data, data}} ->
        collect(runtime, child, if(byte_size(acc) < 16_777_216, do: acc <> data, else: acc))

      {^port, {:exit_status, status}} ->
        {:ok, acc, status}
    after
      wait ->
        TwinRuntime.await_exit(runtime, %{
          child
          | deadline_at: System.monotonic_time(:millisecond)
        })

        {:error, :timeout}
    end
  end

  defp unique_name(prefix), do: :"#{prefix}_#{System.unique_integer([:positive])}"

  # ------------------------------------------------------------------ helpers

  defp channel(inputs, case_id, channel) do
    inputs |> Map.get(:cases, %{}) |> Map.get(case_id, %{}) |> Map.get(channel)
  end

  defp launch(records, n), do: Enum.filter(records, &(&1.launch == n))
  defp of_kind(records, kind), do: Enum.filter(records, &(&1.kind == kind))
  defp first(records, kind), do: records |> of_kind(kind) |> List.first()
  defp last(records, kind), do: records |> of_kind(kind) |> List.last()

  defp has?(records, kind, value),
    do: Enum.any?(records, &(&1.kind == kind and &1.value == value))

  defp max_of(records, kind) do
    case of_kind(records, kind) do
      [] -> nil
      list -> list |> Enum.map(& &1.value) |> Enum.max()
    end
  end

  defp threshold(nil, _min), do: :missing
  defp threshold(value, min), do: verdict(value >= min)

  defp verdict(true), do: :pass
  defp verdict(false), do: :fail
  defp verdict(other) when other in [:pass, :fail, :missing], do: other

  defp digest?(value), do: is_binary(value) and Regex.match?(~r/\A[0-9a-f]{64}\z/, value)
  defp sha256(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)

  # One emit helper per producer: each emits only its own owner's ids through the receipt.

  defp emit_host_adapter(run_id, id, result),
    do: unwrap(TwinReceipt.observation(attrs(run_id, id, :host_adapter, result)))

  defp emit_webview(run_id, id, result),
    do: unwrap(TwinReceipt.observation(attrs(run_id, id, :webview, result)))

  defp emit_app_process(run_id, id, result),
    do: unwrap(TwinReceipt.observation(attrs(run_id, id, :app_process, result)))

  defp emit_fault_boundary(run_id, id, result),
    do: unwrap(TwinReceipt.observation(attrs(run_id, id, :fault_boundary, result)))

  defp emit_phoenix_ecto(run_id, id, result),
    do: unwrap(TwinReceipt.observation(attrs(run_id, id, :phoenix_ecto, result)))

  defp emit_runner(run_id, id, result),
    do: unwrap(TwinReceipt.observation(attrs(run_id, id, :runner, result)))

  defp unwrap({:ok, observation}), do: observation

  defp attrs(run_id, id, owner, result) do
    {outcome, cause} =
      case result do
        :pass -> {:passed, nil}
        :fail -> {:failed, :contradiction_observed}
        :missing -> {:blocked, :observation_missing}
        {:blocked, cause} -> {:blocked, cause}
      end

    %{id: id, owner: owner, run_id: run_id, outcome: outcome, measure: nil, cause: cause}
  end
end
