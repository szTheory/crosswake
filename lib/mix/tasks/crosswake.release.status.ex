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
  """

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

    Mix.shell().info(output)

    if Crosswake.ReleaseStatus.exit_code(status) != 0 do
      Mix.raise("Crosswake release status found blocking release issues")
    end
  end
end
