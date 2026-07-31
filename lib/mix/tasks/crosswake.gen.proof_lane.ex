defmodule Mix.Tasks.Crosswake.Gen.ProofLane do
  use Mix.Task

  alias Crosswake.ProofLane.{Config, Generator}

  @shortdoc "Generates an additive, host-owned iOS proof lane"
  @switches [check: :boolean, diff: :boolean]

  @impl Mix.Task
  def run(args) do
    {opts, argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] or argv != ["ios"],
      do: Mix.raise("usage: mix crosswake.gen.proof_lane ios [--check|--diff]")

    with {:ok, config} <- Config.normalize(Application.get_env(:crosswake, :proof_lane)) do
      cond do
        opts[:check] ->
          finish(Generator.check(config))

        opts[:diff] ->
          Generator.diff(config) |> Enum.each(&Mix.shell().info("missing #{&1}"))

        true ->
          case Generator.generate(config) do
            {:ok, results} ->
              Enum.each(results, fn {state, path} ->
                Mix.shell().info("#{state} #{Path.basename(path)}")
              end)

            error ->
              finish(error)
          end
      end
    else
      {:error, error} -> Mix.raise("#{error.rule_id}: #{error.key}; #{error.remediation}")
    end
  end

  defp finish(:ok), do: :ok
  defp finish({:error, {rule_id, key}}), do: Mix.raise("#{rule_id}: #{key}")
end
