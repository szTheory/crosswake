defmodule Mix.Tasks.Crosswake.AdoptionContext.Scan do
  use Mix.Task

  alias Crosswake.Planning.FirstAdopterContext

  @shortdoc "Enforces first-adopter privacy checks over approved repository artifacts"

  @switches [root: :string]

  @impl Mix.Task
  def run(args) do
    {options, _arguments, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("privacy.invalid_options options")
    end

    root = options[:root] || File.cwd!()
    violations = FirstAdopterContext.scan_filesystem(root, [])

    case violations do
      [] -> Mix.shell().info("adoption context scan passed")
      violations -> Mix.raise(format_violations(violations))
    end
  end

  defp format_violations(violations) do
    violations
    |> Enum.sort_by(&{&1.rule_id, &1.path})
    |> Enum.map_join("\n", &"#{&1.rule_id} #{&1.path}")
  end
end
