defmodule Mix.Tasks.Crosswake.Demo do
  use Mix.Task

  @shortdoc "Boot the shared demo backend and print the See It Run banner"

  @moduledoc """
  Thin alias that shells out to `bin/see-it-run.sh` and streams its live output
  (the readiness progress dots + plain-ASCII banner) to the user's terminal.

  # logic lives in bin/see-it-run.sh

  This task carries no banner string, no boot logic, no Docker orchestration,
  no toolchain checks, and no curl calls. All of that lives in the canonical
  `bin/see-it-run.sh` script (D-01). This module is a pure pass-through alias.

  ## Usage

      mix crosswake.demo [--web-only] [--ios] [--android] [--all] [--build] [--no-open] [--help]

  All flags are forwarded verbatim to `bin/see-it-run.sh`; no parsing is done here.

  ## Exit behaviour

  A non-zero exit from the script (e.g. Docker absent / daemon down) is propagated
  via `exit({:shutdown, status})` so callers see the real failure code.
  """

  @impl Mix.Task
  def run(args) do
    # Resolve bin/see-it-run.sh relative to the repo root.
    # __DIR__ is lib/mix/tasks/ at compile time, so we walk up three levels.
    script_path =
      __DIR__
      |> Path.join("../../..")
      |> Path.expand()
      |> Path.join("bin/see-it-run.sh")

    {_output, status} =
      System.cmd(script_path, args, into: IO.stream(:stdio, :line))

    if status != 0 do
      exit({:shutdown, status})
    end
  end
end
