defmodule Mix.Tasks.Crosswake.Release.Candidate do
  use Mix.Task

  @shortdoc "Evaluate an exact Crosswake release candidate"

  @moduledoc """
  Evaluates one exact Crosswake candidate and writes its authoritative receipt.

      mix crosswake.release.candidate --version <semver> --ref <40sha> --output-dir <dir>

  The command is evaluation-only. External observation adapters are owned separately and supply
  normalized facts to `Crosswake.ReleaseCandidate.run!/1`.
  """

  @sha_pattern ~r/\A[0-9a-f]{40}\z/
  @version_pattern ~r/\A\d+\.\d+\.\d+\z/
  @required_options ~w(version ref output_dir)a

  @impl Mix.Task
  def run(args), do: run(args, [])

  @doc false
  def run(args, task_opts) do
    parsed = parse!(args)

    candidate_opts =
      task_opts
      |> Keyword.get(:candidate_opts, [])
      |> Keyword.merge(parsed)

    result = Crosswake.ReleaseCandidate.run!(candidate_opts)
    Mix.shell().info(result.terminal)

    if Crosswake.ReleaseCandidate.exit_code(result.receipt) != 0 do
      Mix.raise("release candidate is #{result.receipt.state}")
    end

    result
  end

  defp parse!(args) when is_list(args) do
    {opts, argv, invalid} =
      OptionParser.parse(args,
        strict: [version: :string, ref: :string, output_dir: :string]
      )

    keys = Keyword.keys(opts)

    valid? =
      invalid == [] and argv == [] and Enum.sort(keys) == Enum.sort(@required_options) and
        Enum.uniq(keys) == keys and exact_option_counts?(args) and
        is_binary(opts[:version]) and Regex.match?(@version_pattern, opts[:version]) and
        is_binary(opts[:ref]) and Regex.match?(@sha_pattern, opts[:ref]) and
        is_binary(opts[:output_dir]) and opts[:output_dir] != "" and
        not String.contains?(opts[:output_dir], <<0>>)

    if valid? do
      [version: opts[:version], ref: opts[:ref], output_dir: opts[:output_dir]]
    else
      Mix.raise("invalid release candidate command")
    end
  end

  defp parse!(_args), do: Mix.raise("invalid release candidate command")

  defp exact_option_counts?(args) do
    Enum.all?(~w(--version --ref --output-dir), fn option ->
      Enum.count(args, &(&1 == option)) == 1
    end)
  end
end
