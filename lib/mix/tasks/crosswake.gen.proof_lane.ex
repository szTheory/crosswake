defmodule Mix.Tasks.Crosswake.Gen.ProofLane do
  use Mix.Task

  alias Crosswake.ProofLane.{Config, Generator}

  @shortdoc "Generates an additive, host-owned iOS proof lane"
  @switches [check: :boolean, diff: :boolean, config: :string]

  @impl Mix.Task
  def run(args) do
    {opts, argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] or argv != ["ios"] or (opts[:check] && opts[:diff]),
      do: Mix.raise("usage: mix crosswake.gen.proof_lane ios [--config PATH] [--check|--diff]")

    with {:ok, config} <- load_config(opts) do
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
      {:error, error} -> Mix.raise(Exception.message(error))
    end
  end

  defp finish(:ok), do: :ok
  defp finish({:error, {rule_id, key}}), do: Mix.raise("#{rule_id}: #{key}")

  defp load_config(opts) do
    config =
      case opts[:config] do
        nil ->
          Application.get_env(:crosswake, :proof_lane)

        path ->
          {config, _imports} = Elixir.Config.Reader.read_imports!(path)

          config
          |> Keyword.fetch!(:crosswake)
          |> Keyword.get(:proof_lane)
      end

    Config.normalize(config)
  rescue
    _ ->
      {:error,
       %Config.Error{
         rule_id: "PL-CONFIG-READ",
         key: "config",
         remediation: "use a readable Phoenix config file"
       }}
  end
end
