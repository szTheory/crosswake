defmodule Mix.Tasks.Crosswake.Release.Status do
  use Mix.Task

  @shortdoc "Report read-only package-family and exact-candidate release truth"

  @moduledoc """
  Reports the local release graph, version drift, release-as staleness, and
  workflow guard posture for Crosswake's Hex/native package family. By default
  this task only reads checked-in files.

      mix crosswake.release.status
      mix crosswake.release.status --json
      mix crosswake.release.status --live

  `--live` adds best-effort public registry probes for Hex, Maven Central, and
  the iOS SwiftPM mirror. The default is local-only so the task is fast and
  deterministic in CI.

  The exact candidate projection uses the shared `BLOCKED`, `STALE`,
  `READY FOR APPROVAL`, `PARTIAL`, and `COMPLETE` vocabulary. This command only
  observes state; it never captures, approves, publishes, or recovers a candidate.

  ## Exit codes

  See `Crosswake.ReleaseStatus.exit_code/1` for the canonical `0`/`1`/`3` table.
  """

  # exit contract: 0 clean / 1 defect found / 3 could not verify
  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} =
      OptionParser.parse(args,
        strict: [
          json: :boolean,
          live: :boolean
        ]
      )

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end

    status = Crosswake.ReleaseStatus.build(live?: opts[:live] == true)

    output =
      if opts[:json] == true do
        Jason.encode!(status, pretty: true)
      else
        Crosswake.ReleaseStatus.render(status)
      end

    # Printed BEFORE the exit-code branch, on every path, so the UNVERIFIED/FAIL
    # microcopy is never swallowed by exit({:shutdown, 3}) — this ordering must
    # not move.
    Mix.shell().info(output)

    case Crosswake.ReleaseStatus.exit_code(status) do
      0 ->
        :ok

      1 ->
        Mix.raise("Crosswake release status found blocking release issues")

      3 ->
        # Mix.raise always exits 1 and cannot express 3. exit({:shutdown, 3})
        # matches the idiom already documented at
        # lib/mix/tasks/crosswake.demo.ex:24-25 — never System.halt/1, which
        # skips at_exit hooks and can truncate buffered stdout under a pipe.
        exit({:shutdown, 3})
    end
  end
end
