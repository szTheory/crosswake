defmodule Mix.Tasks.Crosswake.ProofLane.TwinPreflight do
  @shortdoc "Read-only preflight: would a reference twin run be allowed?"

  @moduledoc """
  A read-only preflight, not a run. It reports whether a reference twin run would be
  allowed. No receipt or report is written and no run root is created or consumed. To read
  the candidate's git state it creates a private temporary index outside the candidate and
  the run root and removes it before returning, and it binds the origin port for an
  instant to test it and releases it.

      mix crosswake.proof_lane.twin_preflight ios --candidate <record> --run-root <dir> \\
        --identity <identity file>

  It prints exactly four lines: `result: allowed` or `result: blocked`, `first cause:`
  (`none` or the cause), `report: none written; no run root was created or consumed`
  and one `next action:`.

  The command exits with status 0 when allowed and 2 when blocked, for every cause
  including bad options and an unreadable identity file. It never exits with status 1
  and never raises: a check that raises, throws or exits is reported as a blocked result
  with a fixed message. Allowed means the source, the identity digests and the run root
  pass and the origin port is free at that moment; the backend build and the live
  journey are checked only by the real run, which repeats every check.
  """

  use Mix.Task

  alias Crosswake.ProofLane.TwinPreflight

  @switches [candidate: :string, run_root: :string, identity: :string]
  @report "report: none written; no run root was created or consumed"
  @stopped "The preflight stopped before finishing its checks, so the run is not known to be allowed; nothing was written. Run the preflight again"
  @usage "Run mix crosswake.proof_lane.twin_preflight ios --candidate <record> --run-root <dir> --identity <identity file>"

  @impl Mix.Task
  def run(args) do
    {status, lines} = execute(args, [])
    Enum.each(lines, fn line -> Mix.shell().info(line) end)
    if status == 2, do: System.halt(2), else: :ok
  end

  @doc """
  Runs the preflight and returns `{exit_status, four_lines}` without halting. The status
  is 0 (allowed) or 2 (blocked). Test options: `:checks`, `:git_cmd`, `:current_uid`, `:check`
  (a one-arity function replacing `TwinPreflight.check/1`).
  """
  @spec execute([String.t()], keyword()) :: {0 | 2, [String.t()]}
  def execute(args, opts) when is_list(args) do
    {parsed, positional, invalid} = OptionParser.parse(args, strict: @switches)

    if positional != ["ios"] or invalid != [] do
      summarize({:blocked, :prerequisite_missing, @usage})
    else
      database =
        case System.get_env("DATABASE_PATH") do
          nil -> []
          path -> [database_path: path]
        end

      check_opts =
        [candidate: parsed[:candidate], run_root: parsed[:run_root], identity: parsed[:identity]] ++
          database ++ Keyword.take(opts, [:checks, :git_cmd, :current_uid])

      check = Keyword.get(opts, :check, &TwinPreflight.check/1)

      result =
        try do
          check.(check_opts)
        rescue
          _ -> {:blocked, :prerequisite_missing, @stopped}
        catch
          _, _ -> {:blocked, :prerequisite_missing, @stopped}
        end

      summarize(result)
    end
  end

  defp summarize({:allowed, action}),
    do: {0, ["result: allowed", "first cause: none", @report, "next action: " <> action]}

  defp summarize({:blocked, cause, action}),
    do:
      {2,
       [
         "result: blocked",
         "first cause: " <> Atom.to_string(cause),
         @report,
         "next action: " <> action
       ]}
end
