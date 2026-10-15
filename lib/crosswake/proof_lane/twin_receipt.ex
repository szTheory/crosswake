defmodule Crosswake.ProofLane.TwinReceipt do
  @moduledoc """
  Closed, twin-only receipt for the bounded reference twin demonstration.

  The receipt fixes exactly ten groups (T01..T10) and a closed roster of
  sub-observations, each owned by exactly one producer. Status derives as
  `failed` over `blocked` over `passed`. Observations are built as closed
  maps at the source (exact atom keys, closed enums, bounded integers), the
  serialized receipt is re-validated after writing, and nothing here imports
  or extends the physical-device evidence contract. A twin receipt is
  `virtual_twin` evidence only; it never stands for a physical device or a
  real first adopter.
  """

  @schema "crosswake.twin_receipt/1"
  @result_schema "crosswake.twin_result/1"
  @schema_version 1
  @evidence_class "virtual_twin"

  @owners [:app_process, :webview, :host_adapter, :fault_boundary, :phoenix_ecto, :runner]
  @outcomes [:passed, :failed, :blocked]

  @causes [
    :observation_missing,
    :contradiction_observed,
    :identity_mismatch,
    :identity_unknown,
    :prerequisite_missing,
    :origin_port_occupied,
    :run_root_reused,
    :run_root_rejected,
    :database_path_rejected,
    :child_timeout,
    :host_denied,
    :backend_denied,
    :unavailable_observation,
    :backend_listener_not_owned,
    :capture_not_prevented,
    :attachment_check_unavailable,
    :session_control_unavailable,
    :cause_not_retained
  ]

  @identity_joins [
    :source,
    :dependency_lock,
    :generated_resources,
    :served_static,
    :installed_media,
    :installed_build,
    :backend_build
  ]

  @identity_join_roster_id "TW-T10-02"
  @max_measure 1_000_000

  @fidelity_limits [
    "simulator not physical speaker",
    "simulator not signed device",
    "synthetic_test_authority not real adopter",
    "trusted local runner not cryptographic certification"
  ]

  @residual_external_gates [
    "physical iPhone signed-device run",
    "first adopter sanitized route handoff"
  ]

  @observation_keys [:id, :owner, :run_id, :outcome, :measure, :cause]
  @sensitive ~r/answer|transcript|token|credential|account|scope_ref|device_id|media_bytes|payload|secret|password|cookie|body/i
  @relabel ~r/physical|adopter|promot/i

  # Closed roster: {group id, title, [{sub-observation id, owner}]}.
  @roster [
    {"T01", "install pack online",
     [
       {"TW-T01-01", :host_adapter},
       {"TW-T01-02", :host_adapter},
       {"TW-T01-03", :host_adapter},
       {"TW-T01-04", :host_adapter}
     ]},
    {"T02", "enter authorized study and go offline",
     [
       {"TW-T02-01", :webview},
       {"TW-T02-02", :webview},
       {"TW-T02-03", :phoenix_ecto},
       {"TW-T02-04", :fault_boundary},
       {"TW-T02-05", :fault_boundary}
     ]},
    {"T03", "save selected and free-form answers offline",
     [{"TW-T03-01", :webview}, {"TW-T03-02", :webview}, {"TW-T03-03", :webview}]},
    {"T04", "play installed audio and deny bad media",
     [
       {"TW-T04-01", :webview},
       {"TW-T04-02", :host_adapter},
       {"TW-T04-03", :host_adapter},
       {"TW-T04-04", :host_adapter},
       {"TW-T04-05", :host_adapter},
       {"TW-T04-06", :webview},
       {"TW-T04-07", :fault_boundary}
     ]},
    {"T05", "terminate and relaunch without reset",
     [
       {"TW-T05-01", :app_process},
       {"TW-T05-02", :app_process},
       {"TW-T05-03", :webview},
       {"TW-T05-04", :webview}
     ]},
    {"T06", "reconnect and replay",
     [
       {"TW-T06-01", :phoenix_ecto},
       {"TW-T06-02", :phoenix_ecto},
       {"TW-T06-03", :phoenix_ecto},
       {"TW-T06-04", :webview},
       {"TW-T06-05", :webview}
     ]},
    {"T07", "recover rejection and conflict",
     [
       {"TW-T07-01", :phoenix_ecto},
       {"TW-T07-02", :phoenix_ecto},
       {"TW-T07-03", :webview},
       {"TW-T07-04", :webview},
       {"TW-T07-05", :webview}
     ]},
    {"T08", "logout and account switch",
     [{"TW-T08-01", :webview}, {"TW-T08-02", :phoenix_ecto}, {"TW-T08-03", :phoenix_ecto}]},
    {"T09", "disable entry and replay",
     [
       {"TW-T09-01", :webview},
       {"TW-T09-02", :phoenix_ecto},
       {"TW-T09-03", :webview},
       {"TW-T09-04", :phoenix_ecto},
       {"TW-T09-05", :webview}
     ]},
    {"T10", "inspect safe source-bound results",
     [
       {"TW-T10-01", :runner},
       {"TW-T10-02", :runner},
       {"TW-T10-03", :runner},
       {"TW-T10-04", :runner},
       {"TW-T10-05", :runner},
       {"TW-T10-06", :runner},
       {"TW-T10-07", :runner},
       {"TW-T10-08", :runner}
     ]}
  ]

  @roster_ids for {_g, _t, subs} <- @roster, {id, _o} <- subs, do: id
  @roster_owner Map.new(for {_g, _t, subs} <- @roster, {id, o} <- subs, do: {id, o})

  @type error :: %{rule_id: String.t(), path: term()}

  # ---------------------------------------------------------------- public data

  @doc "Ordered closed roster: groups T01..T10 with owned sub-observation ids."
  @spec roster() :: [%{id: String.t(), title: String.t(), sub_observations: [map()]}]
  def roster do
    for {group, title, subs} <- @roster do
      %{
        id: group,
        title: title,
        sub_observations: for({id, owner} <- subs, do: %{id: id, owner: owner})
      }
    end
  end

  @spec roster_ids() :: [String.t()]
  def roster_ids, do: @roster_ids

  @spec owners() :: [atom()]
  def owners, do: @owners

  @spec causes() :: [atom()]
  def causes, do: @causes

  @spec identity_joins() :: [atom()]
  def identity_joins, do: @identity_joins

  @spec fidelity_limits() :: [String.t()]
  def fidelity_limits, do: @fidelity_limits

  @spec residual_external_gates() :: [String.t()]
  def residual_external_gates, do: @residual_external_gates

  @doc "Digest of a list of strings (sorted, joined by newline), lowercase hex SHA-256."
  @spec identity_digest([String.t()]) :: String.t()
  def identity_digest(parts) when is_list(parts) do
    parts |> Enum.sort() |> Enum.join("\n") |> sha256()
  end

  @doc "Maps any cause term to a closed cause id; unknown terms become `cause_not_retained`."
  @spec safe_cause(term()) :: atom()
  def safe_cause(cause) when cause in @causes, do: cause
  def safe_cause(_), do: :cause_not_retained

  # --------------------------------------------------------------- expectations

  @doc """
  Freezes the expected identities before launch.

  Takes `:run_id`, `:candidate_head`, `:candidate_tree`, `:lock_digests`,
  `:resource_digests`, `:fixture_digests` and optional `:consumed_run_ids`.
  Returns a closed map keyed by the seven identity joins plus the run binding.
  """
  @spec freeze_expectations(map()) :: {:ok, map()} | {:error, error()}
  def freeze_expectations(attrs) when is_map(attrs) and not is_struct(attrs) do
    with :ok <- reject_forbidden_keys(Map.keys(attrs)),
         :ok <- allowed_keys(attrs, ~w(run_id candidate_head candidate_tree lock_digests
                      resource_digests fixture_digests consumed_run_ids)a, ~w(run_id
                      candidate_head candidate_tree lock_digests resource_digests
                      fixture_digests)a),
         :ok <- run_id_ok(attrs.run_id),
         :ok <- git_sha(attrs.candidate_head, :candidate_head),
         :ok <- git_sha(attrs.candidate_tree, :candidate_tree),
         :ok <- digest_list(attrs.lock_digests, :lock_digests),
         :ok <- digest_list(attrs.resource_digests, :resource_digests),
         :ok <- digest_list(attrs.fixture_digests, :fixture_digests),
         consumed = Map.get(attrs, :consumed_run_ids, []),
         :ok <- consumed_ok(consumed) do
      head = attrs.candidate_head
      tree = attrs.candidate_tree

      {:ok,
       %{
         run_id: attrs.run_id,
         consumed_run_ids: consumed,
         joins: %{
           source: identity_digest([head, tree]),
           dependency_lock: identity_digest(attrs.lock_digests),
           generated_resources: identity_digest(attrs.resource_digests),
           served_static: identity_digest(attrs.resource_digests),
           installed_media: identity_digest(attrs.fixture_digests),
           installed_build: identity_digest([head, tree | attrs.resource_digests]),
           backend_build: identity_digest([head, tree | attrs.lock_digests])
         }
       }}
    end
  end

  def freeze_expectations(_), do: error("TW-EXP-INPUT", :input)

  # --------------------------------------------------------------- observations

  @doc """
  Builds one closed observation from declared values only.

  Keys are exactly `#{inspect(@observation_keys)}`. `measure` is an integer in
  `0..1_000_000` or nil; `cause` is a closed cause id (required unless passed).
  """
  @spec observation(map()) :: {:ok, map()} | {:error, error()}
  def observation(attrs) when is_map(attrs) and not is_struct(attrs) do
    keys = Map.keys(attrs)

    with :ok <- reject_forbidden_keys(keys),
         :ok <- exact_keys(attrs, @observation_keys, "TW-OBS-KEY"),
         :ok <- known_id(attrs.id),
         :ok <- owner_ok(attrs.id, attrs.owner),
         :ok <- run_id_ok(attrs.run_id),
         :ok <- enum(attrs.outcome, @outcomes, "TW-OBS-OUTCOME", :outcome),
         :ok <- measure_ok(attrs.measure),
         :ok <- cause_ok(attrs.outcome, attrs.cause) do
      {:ok, Map.take(attrs, @observation_keys)}
    end
  end

  def observation(_), do: error("TW-OBS-INPUT", :input)

  # ------------------------------------------------------------------ derivation

  @doc """
  Derives the receipt from frozen expectations, observed identities and
  observations.

  `observed` maps identity join ids to lowercase hex digests (nil or absent is
  unknown and blocks). TW-T10-02 is derived here from the identity joins.
  """
  @spec derive(map(), map(), [map()]) :: {:ok, map()} | {:error, error()}
  def derive(expectations, observed, observations)
      when is_map(expectations) and is_map(observed) and is_list(observations) do
    with :ok <- check_expectations(expectations),
         {:ok, by_id} <- index_observations(expectations, observations),
         {:ok, joins} <- evaluate_joins(expectations, observed) do
      join_obs = identity_observation(expectations.run_id, joins)

      by_id = Map.put(by_id, @identity_join_roster_id, join_obs)

      groups =
        for {group, _title, subs} <- @roster do
          entries = for {id, owner} <- subs, do: entry(Map.get(by_id, id), id, owner)
          %{id: group, status: fold(Enum.map(entries, & &1.outcome)), sub_observations: entries}
        end

      receipt = %{
        schema: @schema,
        schema_version: @schema_version,
        evidence_class: @evidence_class,
        run_id: expectations.run_id,
        overall_status: fold(Enum.map(groups, & &1.status)),
        groups: groups,
        identity_joins: joins,
        fidelity_limits: @fidelity_limits,
        residual_external_gates: @residual_external_gates
      }

      validate(receipt)
    end
  end

  def derive(_, _, _), do: error("TW-DERIVE-INPUT", :input)

  @spec status(map()) :: :passed | :failed | :blocked
  def status(%{overall_status: status}) when status in @outcomes, do: status
  def status(_), do: :blocked

  @doc "Maps a status (or an unknown rule id) to the command exit status."
  @spec exit_status_for(term()) :: 0 | 1 | 2
  def exit_status_for(:passed), do: 0
  def exit_status_for(:failed), do: 1
  def exit_status_for(:blocked), do: 2
  def exit_status_for(_unknown), do: 2

  # ------------------------------------------------------------------ validation

  @doc "Validates a receipt structurally and re-derives every status."
  @spec validate(term()) :: {:ok, map()} | {:error, error()}
  def validate(%{} = receipt) when not is_struct(receipt) do
    with :ok <- reject_forbidden_keys(Map.keys(receipt), :relabel),
         :ok <-
           exact_keys(
             receipt,
             ~w(schema schema_version evidence_class run_id overall_status groups
                identity_joins fidelity_limits residual_external_gates)a,
             "TW-RCPT-KEY"
           ),
         :ok <- literal(receipt.schema, @schema, "TW-RCPT-SCHEMA", :schema),
         :ok <- literal(receipt.schema_version, @schema_version, "TW-RCPT-SCHEMA", :version),
         :ok <- literal(receipt.evidence_class, @evidence_class, "TW-RCPT-RELABEL", :class),
         :ok <- run_id_ok(receipt.run_id),
         :ok <- groups_ok(receipt.groups),
         :ok <- joins_ok(receipt.identity_joins),
         :ok <- literal(receipt.fidelity_limits, @fidelity_limits, "TW-RCPT-LIMITS", :limits),
         :ok <-
           literal(
             receipt.residual_external_gates,
             @residual_external_gates,
             "TW-RCPT-GATES",
             :gates
           ),
         :ok <-
           literal(receipt.overall_status, overall(receipt.groups), "TW-RCPT-STATUS", :overall) do
      {:ok, receipt}
    end
  end

  def validate(_), do: error("TW-RCPT-INPUT", :input)

  # --------------------------------------------------------------- serialization

  @spec encode!(map()) :: binary()
  def encode!(receipt) do
    {:ok, receipt} = validate(receipt)
    Jason.encode!(to_json(receipt))
  end

  @doc "Decodes serialized receipt bytes back into the atom-keyed receipt and validates it."
  @spec decode(binary()) :: {:ok, map()} | {:error, error()}
  def decode(bytes) when is_binary(bytes) do
    with {:ok, %{} = raw} <- Jason.decode(bytes),
         {:ok, receipt} <- from_json(raw) do
      validate(receipt)
    else
      {:error, %{rule_id: _} = e} -> {:error, e}
      _ -> error("TW-RCPT-DECODE", :input)
    end
  end

  def decode(_), do: error("TW-RCPT-DECODE", :input)

  @doc "Lowercase hex SHA-256 of the serialized receipt bytes."
  @spec receipt_sha256(map()) :: String.t()
  def receipt_sha256(receipt), do: receipt |> encode!() |> sha256()

  @doc """
  Closed safe projection (`crosswake.twin_result/1`) for planning artifacts.
  """
  @spec project(map(), 0 | 1 | 2) :: {:ok, map()} | {:error, error()}
  def project(receipt, exit_status) when exit_status in [0, 1, 2] do
    with {:ok, receipt} <- validate(receipt),
         :ok <-
           literal(exit_status, exit_status_for(receipt.overall_status), "TW-PROJ-EXIT", :exit) do
      {:ok,
       %{
         "schema" => @result_schema,
         "run_id" => receipt.run_id,
         "exit_status" => exit_status,
         "overall_status" => Atom.to_string(receipt.overall_status),
         "groups" =>
           for g <- receipt.groups do
             %{
               "id" => g.id,
               "status" => Atom.to_string(g.status),
               "sub_observations" =>
                 for e <- g.sub_observations do
                   %{
                     "id" => e.id,
                     "owner" => Atom.to_string(e.owner),
                     "outcome" => Atom.to_string(e.outcome),
                     "cause" => cause_string(e.cause)
                   }
                 end
             }
           end,
         "identity_joins" =>
           for j <- receipt.identity_joins do
             %{
               "id" => Atom.to_string(j.id),
               "outcome" => Atom.to_string(j.outcome),
               "cause" => cause_string(j.cause)
             }
           end,
         "fidelity_limits" => receipt.fidelity_limits,
         "residual_external_gates" => receipt.residual_external_gates,
         "receipt_sha256" => receipt_sha256(receipt)
       }}
    end
  end

  def project(_, _), do: error("TW-PROJ-INPUT", :input)

  @doc "First non-passed sub-observation (concrete cause) or nil."
  @spec first_cause(map()) :: %{id: String.t(), cause: atom(), outcome: atom()} | nil
  def first_cause(%{groups: groups}) do
    groups
    |> Enum.flat_map(& &1.sub_observations)
    |> Enum.sort_by(&if(&1.outcome == :failed, do: 0, else: 1))
    |> Enum.find(&(&1.outcome != :passed))
    |> case do
      nil -> nil
      e -> %{id: e.id, cause: e.cause, outcome: e.outcome}
    end
  end

  # ---------------------------------------------------------------- internals

  defp fold(outcomes) do
    cond do
      Enum.any?(outcomes, &(&1 == :failed)) -> :failed
      Enum.any?(outcomes, &(&1 == :blocked)) -> :blocked
      true -> :passed
    end
  end

  defp overall(groups) when is_list(groups) do
    groups |> Enum.map(&Map.get(&1, :status)) |> fold()
  end

  defp overall(_), do: nil

  defp entry(nil, id, owner),
    do: %{id: id, owner: owner, outcome: :blocked, measure: nil, cause: :observation_missing}

  defp entry(obs, id, owner),
    do: %{id: id, owner: owner, outcome: obs.outcome, measure: obs.measure, cause: obs.cause}

  defp index_observations(expectations, observations) do
    Enum.reduce_while(observations, {:ok, %{}}, fn obs, {:ok, acc} ->
      case check_observation(expectations, obs, acc) do
        :ok -> {:cont, {:ok, Map.put(acc, obs.id, obs)}}
        {:error, _} = e -> {:halt, e}
      end
    end)
  end

  defp check_observation(expectations, obs, acc) do
    with {:ok, _} <- observation(obs),
         :ok <- not_consumed(expectations, obs.run_id),
         :ok <- same_run(expectations, obs.run_id),
         :ok <- not_duplicate(acc, obs.id) do
      :ok
    else
      {:error, _} = e -> e
    end
  end

  defp not_consumed(%{consumed_run_ids: consumed}, run_id) do
    if run_id in consumed, do: error("TW-OBS-REUSED", :run_id), else: :ok
  end

  defp same_run(%{run_id: current}, run_id) do
    if run_id == current, do: :ok, else: error("TW-OBS-STALE", :run_id)
  end

  defp not_duplicate(acc, id) do
    if Map.has_key?(acc, id), do: error("TW-OBS-DUPLICATE", id), else: :ok
  end

  defp evaluate_joins(%{joins: joins}, observed) do
    with :ok <- reject_forbidden_keys(Map.keys(observed)),
         true <- Enum.all?(Map.keys(observed), &(&1 in @identity_joins)) do
      list =
        for id <- @identity_joins do
          case Map.get(observed, id) do
            nil -> %{id: id, outcome: :blocked, cause: :identity_unknown}
            value when is_binary(value) -> compare_join(id, Map.fetch!(joins, id), value)
            _ -> %{id: id, outcome: :blocked, cause: :identity_unknown}
          end
        end

      {:ok, list}
    else
      _ -> error("TW-IDENT-KEY", :observed)
    end
  end

  defp compare_join(id, expected, observed) do
    cond do
      not Regex.match?(~r/\A[0-9a-f]{64}\z/, observed) ->
        %{id: id, outcome: :blocked, cause: :identity_unknown}

      secure_equal?(expected, observed) ->
        %{id: id, outcome: :passed, cause: nil}

      true ->
        %{id: id, outcome: :failed, cause: :identity_mismatch}
    end
  end

  defp identity_observation(run_id, joins) do
    outcome = fold(Enum.map(joins, & &1.outcome))

    cause =
      case outcome do
        :passed -> nil
        :failed -> :identity_mismatch
        :blocked -> :identity_unknown
      end

    %{
      id: @identity_join_roster_id,
      owner: :runner,
      run_id: run_id,
      outcome: outcome,
      measure: nil,
      cause: cause
    }
  end

  defp check_expectations(%{run_id: run_id, consumed_run_ids: consumed, joins: joins})
       when is_list(consumed) and is_map(joins) do
    with :ok <- run_id_ok(run_id),
         true <- Map.keys(joins) |> Enum.sort() == Enum.sort(@identity_joins),
         true <- Enum.all?(Map.values(joins), &digest?/1) do
      :ok
    else
      _ -> error("TW-EXP-INPUT", :expectations)
    end
  end

  defp check_expectations(_), do: error("TW-EXP-INPUT", :expectations)

  # receipt validation

  defp groups_ok(groups) when is_list(groups) do
    if length(groups) == length(@roster) do
      @roster
      |> Enum.zip(groups)
      |> Enum.reduce_while(:ok, fn {{gid, _t, subs}, group}, :ok ->
        case group_ok(gid, subs, group) do
          :ok -> {:cont, :ok}
          e -> {:halt, e}
        end
      end)
    else
      error("TW-RCPT-GROUPS", :groups)
    end
  end

  defp groups_ok(_), do: error("TW-RCPT-GROUPS", :groups)

  defp group_ok(gid, subs, %{} = group) when not is_struct(group) do
    with :ok <- exact_keys(group, [:id, :status, :sub_observations], "TW-RCPT-KEY"),
         :ok <- literal(group.id, gid, "TW-RCPT-GROUPS", gid),
         true <- is_list(group.sub_observations),
         true <- length(group.sub_observations) == length(subs),
         :ok <- entries_ok(subs, group.sub_observations),
         :ok <-
           literal(
             group.status,
             fold(Enum.map(group.sub_observations, & &1.outcome)),
             "TW-RCPT-STATUS",
             gid
           ) do
      :ok
    else
      {:error, _} = e -> e
      _ -> error("TW-RCPT-SUBS", gid)
    end
  end

  defp group_ok(gid, _, _), do: error("TW-RCPT-GROUPS", gid)

  defp entries_ok(subs, entries) do
    subs
    |> Enum.zip(entries)
    |> Enum.reduce_while(:ok, fn {{id, owner}, e}, :ok ->
      with true <- is_map(e) and not is_struct(e),
           :ok <- exact_keys(e, [:id, :owner, :outcome, :measure, :cause], "TW-RCPT-KEY"),
           :ok <- literal(e.id, id, "TW-RCPT-SUBS", id),
           :ok <- literal(e.owner, owner, "TW-RCPT-OWNER", id),
           :ok <- enum(e.outcome, @outcomes, "TW-RCPT-OUTCOME", id),
           :ok <- measure_ok(e.measure),
           :ok <- cause_ok(e.outcome, e.cause) do
        {:cont, :ok}
      else
        {:error, _} = err -> {:halt, err}
        _ -> {:halt, error("TW-RCPT-SUBS", id)}
      end
    end)
  end

  defp joins_ok(joins) when is_list(joins) do
    ids = Enum.map(joins, &(is_map(&1) && Map.get(&1, :id)))

    with true <- ids == @identity_joins,
         true <-
           Enum.all?(joins, fn j ->
             Map.keys(j) |> Enum.sort() == [:cause, :id, :outcome] and
               j.outcome in @outcomes and match?(:ok, cause_ok(j.outcome, j.cause))
           end) do
      :ok
    else
      _ -> error("TW-RCPT-JOINS", :identity_joins)
    end
  end

  defp joins_ok(_), do: error("TW-RCPT-JOINS", :identity_joins)

  # field checks

  # `mode: :sensitive` (observations, expectations) also refuses an evidence_class key;
  # `mode: :relabel` (a whole receipt) allows it because the receipt carries the fixed class.
  defp reject_forbidden_keys(keys, mode \\ :sensitive) do
    Enum.reduce_while(keys, :ok, fn key, :ok ->
      name = key_name(key)

      cond do
        Regex.match?(@sensitive, name) -> {:halt, error("TW-OBS-SENSITIVE", :key)}
        Regex.match?(@relabel, name) -> {:halt, error("TW-OBS-RELABEL", :key)}
        mode == :sensitive and name == "evidence_class" -> {:halt, error("TW-OBS-RELABEL", :key)}
        true -> {:cont, :ok}
      end
    end)
  end

  defp key_name(key) when is_atom(key), do: Atom.to_string(key)
  defp key_name(key) when is_binary(key), do: key
  defp key_name(_), do: "unknown"

  defp exact_keys(map, keys, rule) do
    if Enum.sort(Map.keys(map)) == Enum.sort(keys), do: :ok, else: error(rule, :keys)
  end

  defp allowed_keys(map, allowed, required) do
    keys = Map.keys(map)

    if Enum.all?(keys, &(&1 in allowed)) and Enum.all?(required, &(&1 in keys)),
      do: :ok,
      else: error("TW-EXP-KEY", :keys)
  end

  defp known_id(id) when is_binary(id) do
    if id in @roster_ids, do: :ok, else: error("TW-OBS-ID", :id)
  end

  defp known_id(_), do: error("TW-OBS-ID", :id)

  defp owner_ok(id, owner) do
    if Map.get(@roster_owner, id) == owner and owner in @owners,
      do: :ok,
      else: error("TW-OBS-OWNER", :owner)
  end

  defp run_id_ok(run_id) when is_binary(run_id) do
    if Regex.match?(~r/\Atwin-[0-9a-f]{16}\z/, run_id),
      do: :ok,
      else: error("TW-OBS-RUN", :run_id)
  end

  defp run_id_ok(_), do: error("TW-OBS-RUN", :run_id)

  defp enum(value, allowed, rule, path) do
    if value in allowed, do: :ok, else: error(rule, path)
  end

  defp literal(value, expected, rule, path) do
    if value == expected, do: :ok, else: error(rule, path)
  end

  defp measure_ok(nil), do: :ok

  defp measure_ok(v) when is_integer(v) and v >= 0 and v <= @max_measure, do: :ok
  defp measure_ok(_), do: error("TW-OBS-MEASURE", :measure)

  defp cause_ok(:passed, nil), do: :ok
  defp cause_ok(:passed, _), do: error("TW-OBS-CAUSE", :cause)
  defp cause_ok(outcome, cause) when outcome in [:failed, :blocked] and cause in @causes, do: :ok
  defp cause_ok(_, _), do: error("TW-OBS-CAUSE", :cause)

  defp git_sha(value, path) when is_binary(value) do
    if Regex.match?(~r/\A[0-9a-f]{40}\z/, value), do: :ok, else: error("TW-EXP-VALUE", path)
  end

  defp git_sha(_, path), do: error("TW-EXP-VALUE", path)

  defp digest_list([_ | _] = list, path) do
    if Enum.all?(list, &digest?/1), do: :ok, else: error("TW-EXP-VALUE", path)
  end

  defp digest_list(_, path), do: error("TW-EXP-VALUE", path)

  defp consumed_ok(list) when is_list(list) do
    if Enum.all?(list, &(run_id_ok(&1) == :ok)), do: :ok, else: error("TW-EXP-VALUE", :consumed)
  end

  defp consumed_ok(_), do: error("TW-EXP-VALUE", :consumed)

  defp digest?(value), do: is_binary(value) and Regex.match?(~r/\A[0-9a-f]{64}\z/, value)

  defp secure_equal?(a, b) when byte_size(a) == byte_size(b), do: :crypto.hash_equals(a, b)
  defp secure_equal?(_, _), do: false

  defp sha256(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)

  defp cause_string(nil), do: nil
  defp cause_string(cause), do: Atom.to_string(cause)

  # json

  defp to_json(r) do
    %{
      "schema" => r.schema,
      "schema_version" => r.schema_version,
      "evidence_class" => r.evidence_class,
      "run_id" => r.run_id,
      "overall_status" => Atom.to_string(r.overall_status),
      "groups" =>
        for g <- r.groups do
          %{
            "id" => g.id,
            "status" => Atom.to_string(g.status),
            "sub_observations" =>
              for e <- g.sub_observations do
                %{
                  "id" => e.id,
                  "owner" => Atom.to_string(e.owner),
                  "outcome" => Atom.to_string(e.outcome),
                  "measure" => e.measure,
                  "cause" => cause_string(e.cause)
                }
              end
          }
        end,
      "identity_joins" =>
        for j <- r.identity_joins do
          %{
            "id" => Atom.to_string(j.id),
            "outcome" => Atom.to_string(j.outcome),
            "cause" => cause_string(j.cause)
          }
        end,
      "fidelity_limits" => r.fidelity_limits,
      "residual_external_gates" => r.residual_external_gates
    }
  end

  defp from_json(raw) do
    with :ok <- reject_forbidden_keys(Map.keys(raw), :relabel),
         :ok <-
           exact_keys(
             raw,
             ~w(schema schema_version evidence_class run_id overall_status groups
                identity_joins fidelity_limits residual_external_gates),
             "TW-RCPT-KEY"
           ),
         {:ok, status} <- atom_of(raw["overall_status"], @outcomes),
         {:ok, groups} <- map_all(raw["groups"], &group_from_json/1),
         {:ok, joins} <- map_all(raw["identity_joins"], &join_from_json/1) do
      {:ok,
       %{
         schema: raw["schema"],
         schema_version: raw["schema_version"],
         evidence_class: raw["evidence_class"],
         run_id: raw["run_id"],
         overall_status: status,
         groups: groups,
         identity_joins: joins,
         fidelity_limits: raw["fidelity_limits"],
         residual_external_gates: raw["residual_external_gates"]
       }}
    end
  end

  defp group_from_json(%{"id" => id, "status" => status, "sub_observations" => subs} = g)
       when map_size(g) == 3 do
    with {:ok, status} <- atom_of(status, @outcomes),
         {:ok, subs} <- map_all(subs, &entry_from_json/1) do
      {:ok, %{id: id, status: status, sub_observations: subs}}
    end
  end

  defp group_from_json(_), do: error("TW-RCPT-GROUPS", :groups)

  defp entry_from_json(
         %{"id" => id, "owner" => owner, "outcome" => outcome, "measure" => m, "cause" => c} = e
       )
       when map_size(e) == 5 do
    with {:ok, owner} <- atom_of(owner, @owners),
         {:ok, outcome} <- atom_of(outcome, @outcomes),
         {:ok, cause} <- cause_from_json(c) do
      {:ok, %{id: id, owner: owner, outcome: outcome, measure: m, cause: cause}}
    end
  end

  defp entry_from_json(_), do: error("TW-RCPT-SUBS", :entry)

  defp join_from_json(%{"id" => id, "outcome" => outcome, "cause" => c} = e)
       when map_size(e) == 3 do
    with {:ok, id} <- atom_of(id, @identity_joins),
         {:ok, outcome} <- atom_of(outcome, @outcomes),
         {:ok, cause} <- cause_from_json(c) do
      {:ok, %{id: id, outcome: outcome, cause: cause}}
    end
  end

  defp join_from_json(_), do: error("TW-RCPT-JOINS", :identity_joins)

  defp cause_from_json(nil), do: {:ok, nil}
  defp cause_from_json(c), do: atom_of(c, @causes)

  defp atom_of(value, allowed) when is_binary(value) do
    case Enum.find(allowed, &(Atom.to_string(&1) == value)) do
      nil -> error("TW-RCPT-VALUE", :enum)
      atom -> {:ok, atom}
    end
  end

  defp atom_of(_, _), do: error("TW-RCPT-VALUE", :enum)

  defp map_all(list, fun) when is_list(list) do
    Enum.reduce_while(list, {:ok, []}, fn item, {:ok, acc} ->
      case fun.(item) do
        {:ok, v} -> {:cont, {:ok, [v | acc]}}
        {:error, _} = e -> {:halt, e}
      end
    end)
    |> case do
      {:ok, acc} -> {:ok, Enum.reverse(acc)}
      e -> e
    end
  end

  defp map_all(_, _), do: error("TW-RCPT-GROUPS", :list)

  defp error(rule_id, path), do: {:error, %{rule_id: rule_id, path: path}}
end
