defmodule Mix.Tasks.Closeout.Verify do
  use Mix.Task

  alias Crosswake.Planning.CloseoutVerifier

  @shortdoc "Verify milestone closeout planning truth"

  @moduledoc """
  Runs deterministic closeout checks over planning artifacts and release truth.
  """

  @switches [cwd: :string, security_closeout: :string, security_only: :boolean]

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("closeout.verify invalid options: #{inspect(invalid)}")
    end

    if opts[:security_only] == true and is_nil(opts[:security_closeout]) do
      Mix.raise("closeout.verify --security-only requires --security-closeout PATH")
    end

    report =
      CloseoutVerifier.run(
        cwd: opts[:cwd] || File.cwd!(),
        security_closeout_path: opts[:security_closeout],
        security_only?: opts[:security_only] == true
      )

    Mix.shell().info(CloseoutVerifier.render(report))

    if report.status == :failed do
      Mix.raise("closeout verification found blocking issues")
    end
  end
end
