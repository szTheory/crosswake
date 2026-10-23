defmodule Mix.Tasks.Crosswake.ProofLane.VerifyTwin do
  @shortdoc "Runs the bounded reference twin and writes a twin-only receipt"

  @moduledoc """
  Runs the bounded reference twin against a prepared candidate and writes a
  twin-only receipt (`virtual_twin` evidence, never physical-device or first
  adopter evidence).

      mix crosswake.proof_lane.verify_twin ios --candidate <record> --run-root <private dir> \\
        --identity <180-IDENTITY.json>

  The command consumes a prepared candidate and configuration; it never
  generates or repairs source. It prints exactly four lines: result, first
  cause, local report path and one next action.

  Exit status: 0 complete pass, 1 observed failure, 2 missing prerequisite or
  missing observation (an unknown rule id also maps to 2). A run root that
  already holds a receipt is refused, so a first result is never overwritten;
  every repair uses a new run root.
  """

  use Mix.Task

  alias Crosswake.ProofLane.{TwinJourney, TwinProducers, TwinReceipt, TwinRuntime}

  @switches [candidate: :string, run_root: :string, identity: :string]
  @receipt "receipt.json"
  @projection "twin-result.json"

  @impl Mix.Task
  def run(args) do
    {status, lines} = execute(args, [])
    Enum.each(lines, fn line -> Mix.shell().info(line) end)
    if status != 0, do: System.halt(status), else: :ok
  end

  @doc """
  Runs the command and returns `{exit_status, four_lines}` without halting.

  Option `:producers` is a function `(runtime, expectations) ->
  {:ok, observed_identities, observations}` used by tests. Without it the command runs the
  real journey (`TwinJourney.run/3`) and `--identity` is required.
  """
  @spec execute([String.t()], keyword()) :: {0 | 1 | 2, [String.t()]}
  def execute(args, opts) when is_list(args) do
    {parsed, positional, invalid} = OptionParser.parse(args, strict: @switches)

    if positional != ["ios"] or invalid != [] do
      Mix.raise("verify_twin.invalid_options")
    end

    injected = Keyword.get(opts, :producers)

    if injected == nil and parsed[:identity] == nil do
      Mix.raise("verify_twin.identity_required")
    end

    plan =
      case injected do
        nil -> journey_plan(parsed[:identity], Keyword.take(opts, [:backend_digest]))
        producers -> injected_plan(producers)
      end

    prepare_opts =
      [candidate: parsed[:candidate], run_root: parsed[:run_root]] ++
        case System.get_env("DATABASE_PATH") do
          nil -> []
          path -> [database_path: path]
        end ++ Keyword.take(opts, [:run_deadline_ms])

    case TwinRuntime.prepare(prepare_opts) do
      {:error, %{cause: cause, action: action}} ->
        summarize(:blocked, Atom.to_string(cause), nil, action)

      {:ok, runtime} ->
        # The receipt is write-once, so a registry timeout, a gone registry or a surviving child at stop changes only the cause and
        # next-action text of the verdict, never the exit code or the written receipt.
        try do
          conduct(runtime, plan)
        catch
          kind, reason ->
            stacktrace = __STACKTRACE__
            TwinRuntime.stop_all(runtime)
            :erlang.raise(kind, reason, stacktrace)
        else
          result -> annotate_stop(result, TwinRuntime.stop_all(runtime))
        end
    end
  end

  @registry_timeout_note "Also check for leftover child processes: the run registry did not answer before the stop timeout, so a child may still be running."

  @child_still_alive_note "Also check for leftover child processes: a child of this run was still alive when the run stopped, so stop it before the next run."
  @registry_gone_note "Also check for leftover child processes: the run registry was already gone when the run stopped, so the children could not be listed and one may still be running."

  @doc false
  @spec annotate_stop({0 | 1 | 2, [String.t()]}, term()) :: {0 | 1 | 2, [String.t()]}
  def annotate_stop({code, [result, cause, report, next]}, {:error, :registry_timeout}) do
    cause = if cause == "first cause: none", do: "first cause: registry_timeout", else: cause
    {code, [result, cause, report, next <> " " <> @registry_timeout_note]}
  end

  def annotate_stop({code, [result, cause, report, next]}, {:error, :child_still_alive}) do
    cause = if cause == "first cause: none", do: "first cause: child_still_alive", else: cause
    {code, [result, cause, report, next <> " " <> @child_still_alive_note]}
  end

  def annotate_stop({code, [result, cause, report, next]}, {:error, :registry_gone}) do
    cause = if cause == "first cause: none", do: "first cause: registry_gone", else: cause
    {code, [result, cause, report, next <> " " <> @registry_gone_note]}
  end

  def annotate_stop(verdict, _stop_result), do: verdict

  @doc "Maps a status or unknown rule id to the exit status (0, 1 or 2)."
  @spec exit_status_for(term()) :: 0 | 1 | 2
  defdelegate exit_status_for(status_or_rule), to: TwinReceipt

  # A plan freezes the expectations and returns the function that produces observations.
  defp injected_plan(producers) do
    fn runtime ->
      with {:ok, expectations} <- freeze(runtime) do
        {:ok, expectations, fn -> producers.(runtime, expectations) end}
      end
    end
  end

  defp journey_plan(identity, freeze_opts) do
    fn runtime ->
      case TwinProducers.freeze(runtime, identity, freeze_opts) do
        {:ok, frozen} ->
          {:ok, frozen.expectations,
           fn ->
             case TwinJourney.run(runtime, frozen) do
               {:ok, observed, observations} -> {:ok, observed, observations}
               {:blocked, cause} -> {:blocked, cause}
             end
           end}

        {:blocked, cause} ->
          {:blocked, cause}
      end
    end
  end

  defp conduct(runtime, plan) do
    case plan.(runtime) do
      {:ok, expectations, produce} ->
        case produce.() do
          {:ok, observed, observations} -> finish(runtime, expectations, observed, observations)
          {:blocked, cause} -> blocked_receipt(runtime, cause)
          _ -> failure({:error, %{rule_id: "TW-PRODUCERS-RESULT", path: :producers}})
        end

      {:blocked, cause} ->
        blocked_receipt(runtime, cause)

      other ->
        failure(other)
    end
  end

  defp finish(runtime, expectations, observed, observations) do
    with {:ok, receipt} <- TwinReceipt.derive(expectations, observed, observations),
         status = exit_status_for(TwinReceipt.status(receipt)),
         {:ok, report} <- write_and_verify(runtime.run_root, receipt, status) do
      first = TwinRuntime.first_failure(runtime)
      cause = first_cause_text(first, receipt)
      summarize(receipt.overall_status, cause, report, next_action(receipt, first))
    else
      other -> failure(other)
    end
  end

  # A preflight block still derives and writes a receipt: every roster id blocked with the
  # first cause, so each accepted run root ends with receipt.json and twin-result.json.
  defp blocked_receipt(runtime, cause) do
    cause = TwinReceipt.safe_cause(cause)

    probe =
      if cause == :source_dirty,
        do: TwinProducers.probe_source(runtime.candidate_path, run_root: runtime.run_root)

    count = measure_of(probe)
    zero = String.duplicate("0", 64)

    with {:ok, expectations} <-
           TwinReceipt.freeze_expectations(%{
             run_id: runtime.run_id,
             candidate_head: runtime.candidate_head,
             candidate_tree: runtime.candidate_tree,
             lock_digests: [zero],
             resource_digests: [zero],
             fixture_digests: [zero]
           }),
         observations =
           for(
             %{sub_observations: subs} <- TwinReceipt.roster(),
             %{id: id, owner: owner} <- subs,
             id != "TW-T10-02",
             do:
               (
                 {:ok, o} =
                   TwinReceipt.observation(%{
                     id: id,
                     owner: owner,
                     run_id: runtime.run_id,
                     outcome: :blocked,
                     measure: count,
                     cause: cause
                   })

                 o
               )
           ),
         {:ok, receipt} <- TwinReceipt.derive(expectations, %{}, observations),
         {:ok, report} <- write_and_verify(runtime.run_root, receipt, 2) do
      TwinRuntime.record_failure(runtime, cause)

      action =
        if cause == :source_dirty,
          do: TwinProducers.source_block_action(probe),
          else: next_action(receipt, cause)

      summarize(:blocked, Atom.to_string(cause), report, action)
    else
      other -> failure(other)
    end
  end

  defp failure({:error, %{rule_id: rule}}) do
    summarize(:blocked, rule, nil, "Fix the named rule input and run again with a new run root")
  end

  defp failure(other) do
    summarize(
      :blocked,
      to_string(inspect_safe(other)),
      nil,
      "Fix the missing prerequisite and run again with a new run root"
    )
  end

  defp freeze(runtime) do
    with {:ok, locks} <- lock_digests(runtime.candidate_path) do
      TwinReceipt.freeze_expectations(%{
        run_id: runtime.run_id,
        candidate_head: runtime.candidate_head,
        candidate_tree: runtime.candidate_tree,
        lock_digests: locks,
        resource_digests: runtime.resource_digests,
        fixture_digests: runtime.fixture_digests
      })
    end
  end

  # Both lockfiles are part of the identity. A lockfile missing at freeze and at
  # observation used to give the same narrowed digest list on both sides, so the
  # join passed while comparing only half of the identity. Every lockfile must now
  # be a regular file (lstat) that can be read, or the freeze blocks closed.
  defp lock_digests(candidate_path) do
    results =
      for rel <- ["mix.lock", "examples/phoenix_host/mix.lock"] do
        path = Path.join(candidate_path, rel)

        with {:ok, %{type: :regular}} <- File.lstat(path),
             {:ok, bytes} <- File.read(path) do
          {:ok, :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)}
        else
          _ -> :error
        end
      end

    if Enum.all?(results, &match?({:ok, _}, &1)) do
      {:ok, for({:ok, digest} <- results, do: digest)}
    else
      {:blocked, :identity_unknown}
    end
  end

  defp write_and_verify(root, receipt, status) do
    receipt_path = Path.join(root, @receipt)
    projection_path = Path.join(root, @projection)
    bytes = TwinReceipt.encode!(receipt)

    with :ok <- write_private(receipt_path, bytes),
         {:ok, written} <- File.read(receipt_path),
         true <- written == bytes,
         {:ok, reread} <- TwinReceipt.decode(written),
         true <- reread == receipt,
         {:ok, projection} <- TwinReceipt.project(reread, status),
         projection_bytes = Jason.encode!(projection),
         :ok <- write_private(projection_path, projection_bytes),
         {:ok, projection_written} <- File.read(projection_path),
         true <- Jason.decode!(projection_written) == Jason.decode!(projection_bytes),
         true <- projection["receipt_sha256"] == sha256(written) do
      {:ok, receipt_path}
    else
      {:error, %{rule_id: _} = e} -> {:error, e}
      _ -> {:error, %{rule_id: "TW-WRITE-VERIFY", path: :report}}
    end
  end

  defp write_private(path, bytes) do
    with {:ok, io} <- File.open(path, [:write, :exclusive, :binary]),
         :ok <- IO.binwrite(io, bytes),
         :ok <- File.close(io) do
      File.chmod(path, 0o600)
    end
  end

  defp first_cause_text(first, receipt) when is_atom(first) and not is_nil(first) do
    case TwinReceipt.first_cause(receipt) do
      nil -> Atom.to_string(first)
      %{id: id} -> "#{id} #{first}"
    end
  end

  defp first_cause_text(_none, receipt) do
    case TwinReceipt.first_cause(receipt) do
      nil -> "none"
      %{id: id, cause: cause} -> "#{id} #{cause}"
    end
  end

  defp next_action(%{overall_status: :passed}, _),
    do: "Copy twin-result.json byte for byte into the planning artifact"

  defp next_action(%{overall_status: :failed}, _),
    do: "Fix the first observed failure named above, then run again with a new run root"

  # Chosen mechanism: keep the unknown text plus a reachability note and grep gate. The probe
  # result is not available in finish/4, and routing it there would add a second probe call
  # on the passing path. A counted source_dirty block reaches line 4 through blocked_receipt/2
  # and source_block_action(probe); only blocked_receipt/2 and the :child_timeout call in
  # twin_runtime.ex call record_failure/2, so this clause is a defensive fallback.
  defp next_action(%{overall_status: :blocked}, :source_dirty),
    do: TwinProducers.source_block_action(:unavailable)

  defp next_action(%{overall_status: :blocked}, _),
    do:
      "Supply the first missing observation or prerequisite named above, then run again with a new run root"

  # M+F+X of a countable probe within the receipt bound; nil is unknown, never clean.
  defp measure_of({:ok, %{modified: m, flagged: f, excludes: x}}) do
    sum = m + f + x
    if sum <= TwinProducers.max_dirty_count(), do: sum
  end

  defp measure_of(_), do: nil

  defp summarize(status, cause, report, action) do
    code = exit_status_for(status)
    result = if status == :blocked, do: "blocked", else: Atom.to_string(status)

    {code,
     [
       "result: #{result} (exit #{code})",
       "first cause: #{cause}",
       "report: #{report || "none written"}",
       "next action: #{action}"
     ]}
  end

  defp sha256(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)

  defp inspect_safe(atom) when is_atom(atom), do: atom
  defp inspect_safe(_), do: :unknown
end
