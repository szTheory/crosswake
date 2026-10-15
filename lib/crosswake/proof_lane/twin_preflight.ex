defmodule Crosswake.ProofLane.TwinPreflight do
  @moduledoc """
  A read-only preflight for the reference twin: it asks whether a real run would be
  allowed, and nothing more.

  It runs the shared run checks (run root, record, origin port, owner check) and the
  source gate (head, tree, clean working tree, lock files, study script), then compares
  the prepared record's digests with the identity file and the candidate. It writes no
  receipt, creates no run root, consumes no run root and holds no port, so the same run
  root can be used for the real run afterwards.

  Nothing it returns is a token the real run trusts. The real run repeats every check,
  and the backend build and the live journey are checked only by the real run.

  The digest comparison covers the manifest, activation and study script digests (kept
  in the record's `resource_digests`) and the media digest (kept in `fixture_digests`).
  The real run still re-derives these digests from the identity file; enforcing the
  comparison in the real run is left to Phase 188's scripted check.

  Options: `:candidate` (record path), `:run_root`, `:identity` (identity file path),
  `:database_path`, `:git_cmd`, `:current_uid` (test seam) and `:checks` (test seam; an
  empty list is blocked, never allowed).
  """

  alias Crosswake.ProofLane.{TwinProducers, TwinReceipt, TwinRuntime}

  @default_checks [:run_root_given, :run_checks, :source_gate, :identity_digests]

  @allowed "Source and run root pass and the origin port is free at this moment; the backend build and the live journey are checked only by the real run."

  @mismatch_action "The prepared record's resource or fixture digests do not match the identity file and candidate; write a new prepared record and run the preflight again"

  @spec check(keyword()) :: {:allowed, String.t()} | {:blocked, atom(), String.t()}
  @doc """
  Runs the configured checks in order and stops at the first block. Returns
  `{:allowed, next_action}` or `{:blocked, first_cause, next_action}`; every text is
  fixed and carries no path.
  """
  def check(opts) when is_list(opts) do
    case Keyword.get(opts, :checks, @default_checks) do
      [] ->
        {:blocked, :prerequisite_missing,
         "No preflight checks were configured; nothing was checked."}

      checks when is_list(checks) ->
        run(checks, opts, %{})

      _ ->
        {:blocked, :prerequisite_missing,
         "No preflight checks were configured; nothing was checked."}
    end
  end

  defp run([], _opts, _acc), do: {:allowed, @allowed}

  defp run([name | rest], opts, acc) do
    case step(name, opts, acc) do
      {:ok, acc} -> run(rest, opts, acc)
      {:blocked, _cause, _action} = blocked -> blocked
    end
  end

  defp step(:run_root_given, opts, acc) do
    case opts[:run_root] do
      root when is_binary(root) and root != "" ->
        {:ok, acc}

      _ ->
        {:blocked, :prerequisite_missing, "Name the private run root you plan to use"}
    end
  end

  defp step(:run_checks, opts, acc) do
    case TwinRuntime.check(
           Keyword.take(opts, [:candidate, :run_root, :database_path, :current_uid])
         ) do
      {:ok, checked} -> {:ok, Map.put(acc, :checked, checked)}
      {:error, %{cause: cause, action: action}} -> {:blocked, cause, action}
    end
  end

  defp step(:source_gate, opts, %{checked: %{record: rec, root: root}} = acc) do
    target = %{
      candidate_path: rec.candidate_path,
      candidate_head: rec.head,
      candidate_tree: rec.tree,
      run_root: root.path
    }

    gate_result =
      if is_binary(opts[:identity]),
        do: TwinProducers.source_gate(target, opts[:identity], Keyword.take(opts, [:git_cmd])),
        else: {:blocked, :identity_unknown}

    case gate_result do
      {:ok, gate} ->
        {:ok, Map.put(acc, :gate, gate)}

      {:blocked, :source_dirty} ->
        probe_opts = Keyword.take(opts, [:git_cmd]) ++ [run_root: root.path]
        probe = TwinProducers.probe_source(rec.candidate_path, probe_opts)
        {:blocked, :source_dirty, TwinProducers.source_block_action(probe)}

      {:blocked, cause} ->
        {:blocked, cause, action_for(cause)}
    end
  end

  defp step(:identity_digests, _opts, %{checked: %{record: rec}, gate: gate} = acc) do
    %{identity: identity, study_js: study_js} = gate

    resources = [identity.manifest, identity.activation, study_js]
    fixtures = [identity.media]

    if valid_digests?(rec.resource_digests) and valid_digests?(rec.fixture_digests) and
         resources == rec.resource_digests and fixtures == rec.fixture_digests do
      {:ok, acc}
    else
      {:blocked, :identity_mismatch, @mismatch_action}
    end
  end

  # A check that needs the output of an earlier check that was not configured, or an
  # unknown check name, is never skipped.
  defp step(_unknown, _opts, _acc),
    do:
      {:blocked, :prerequisite_missing,
       "No preflight checks were configured; nothing was checked."}

  defp valid_digests?(list), do: is_list(list) and list != [] and Enum.all?(list, &is_binary/1)

  defp action_for(:identity_mismatch),
    do:
      "The prepared record does not match the candidate HEAD or tree; write a new prepared record and run the preflight again"

  defp action_for(:identity_unknown),
    do:
      "Pass a readable identity file with --identity and a candidate with both lockfiles and the study script, then run the preflight again"

  defp action_for(:prerequisite_missing),
    do:
      "Make git 2.41 or newer available and make the candidate a readable git work tree, then run the preflight again"

  defp action_for(cause),
    do:
      "#{TwinReceipt.safe_cause(cause)}: Fix the first cause named above, then run the preflight again"
end
