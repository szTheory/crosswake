defmodule Mix.Tasks.Closeout.Verify do
  use Mix.Task

  alias Crosswake.Planning.CloseoutVerifier

  @shortdoc "Verify milestone closeout planning truth"

  @moduledoc """
  Runs deterministic closeout checks over planning artifacts and release truth.
  """

  @switches [cwd: :string]

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end

    report = CloseoutVerifier.run(cwd: opts[:cwd] || File.cwd!())
    Mix.shell().info(CloseoutVerifier.render(report))

    if report.status == :failed do
      Mix.raise("closeout verification found blocking issues")
    end
  end
end
