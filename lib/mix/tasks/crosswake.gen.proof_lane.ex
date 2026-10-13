defmodule Mix.Tasks.Crosswake.Gen.ProofLane do
  use Mix.Task

  alias Crosswake.ProofLane.{Config, Generator}
  alias Crosswake.Shell.IOSHostConfig

  @shortdoc "Generates an additive, host-owned iOS proof lane"
  @switches [
    check: :boolean,
    diff: :boolean,
    recover: :boolean,
    migrate_project_settings: :boolean,
    config: :string
  ]

  @impl Mix.Task
  def run(args) do
    {opts, argv, invalid} = OptionParser.parse(args, strict: @switches)

    actions =
      Enum.count(
        [opts[:check], opts[:diff], opts[:recover], opts[:migrate_project_settings]],
        &(&1 == true)
      )

    if invalid != [] or argv != ["ios"] or actions > 1,
      do:
        Mix.raise(
          "usage: mix crosswake.gen.proof_lane ios [--config PATH] [--check|--diff|--recover|--migrate-project-settings]"
        )

    with {:ok, config} <- load_config(opts),
         {:ok, host_config} <- load_host_config(opts) do
      cond do
        opts[:check] ->
          case Generator.check(config, host_config) do
            :ok when not is_nil(host_config) ->
              verify_effective_settings(config, host_config)

            result ->
              finish(result)
          end

        opts[:recover] ->
          case Generator.recover(config) do
            {:ok, :recovered} ->
              Mix.shell().info(
                "[crosswake] recovered proof settings; cause: interrupted update; repair: rerun --check"
              )

            result ->
              finish(result)
          end

        opts[:migrate_project_settings] ->
          case Generator.migrate_project_settings(config, apply: true) do
            {:ok, %{status: :migration_required}} ->
              Mix.shell().info(
                "[crosswake] migrated recognized proof Xcode settings; unrelated project edits preserved"
              )

            result ->
              finish(result)
          end

        opts[:diff] ->
          Generator.diff(config, host_config)
          |> Enum.each(fn %{path: path, status: status} ->
            Mix.shell().info("#{status} #{path}")
          end)

        true ->
          case Generator.generate(config, host_config) do
            {:ok, results} ->
              Enum.each(results, fn %{path: path, status: status} ->
                Mix.shell().info("#{status} #{path}")
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

  defp finish({:error, findings}) when is_list(findings) do
    Mix.raise(
      findings
      |> Enum.map_join("\n", fn %{rule_id: rule_id, path: path, remediation: remediation} ->
        "#{rule_id}: #{path}; #{remediation}"
      end)
    )
  end

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

  defp load_host_config(opts) do
    if opts[:config] do
      {:ok, nil}
    else
      case Application.get_env(:crosswake, :ios_host) do
        nil ->
          {:ok, nil}

        declaration ->
          case IOSHostConfig.normalize(declaration) do
            {:ok, host_config} -> {:ok, host_config}
            {:error, reason} -> Mix.raise("IOS-HOST-CONFIG: #{reason}")
          end
      end
    end
  end

  defp verify_effective_settings(config, host_config) do
    with {:ok, host_root} <- Config.host_root(config),
         node when is_binary(node) <- System.find_executable("node") do
      script =
        Path.join(to_string(:code.priv_dir(:crosswake)), "crosswake/verify_ios_host_settings.mjs")

      expected =
        Jason.encode!(%{
          appBundleId: host_config.app_bundle_id,
          proofAppBundleId: host_config.proof_app_bundle_id,
          deviceSigning: %{
            mode: Atom.to_string(host_config.device_signing.mode),
            teamId: host_config.device_signing.team_id
          }
        })

      port =
        Port.open({:spawn_executable, String.to_charlist(node)}, [
          :binary,
          :exit_status,
          :use_stdio,
          :in,
          :out,
          :eof,
          args: [String.to_charlist(script), ~c"--host-root", String.to_charlist(host_root)]
        ])

      true = Port.command(port, expected <> "\n")
      {status, output} = collect_output(port, "")

      case Jason.decode(output) do
        {:ok, %{"ok" => true, "observedCells" => 20}} when status == 0 ->
          Mix.shell().info(
            "[crosswake] checked iOS host settings: 20 cells; device settings only"
          )

        {:ok, %{"findings" => findings}} ->
          safe =
            Enum.map_join(findings, "; ", fn finding ->
              "#{finding["target"]}/#{finding["configuration"]}/#{finding["sdk"]}/#{finding["field"]}:#{finding["cause"]}"
            end)

          Mix.raise("IOS-HOST-SETTINGS: blocked; #{safe}")

        _ ->
          Mix.raise("IOS-HOST-SETTINGS: blocked; cause: invalid checker response")
      end
    else
      _ -> Mix.raise("IOS-HOST-SETTINGS: blocked; cause: checker unavailable")
    end
  end

  defp collect_output(port, output) do
    receive do
      {^port, {:data, bytes}} -> collect_output(port, output <> bytes)
      {^port, {:exit_status, status}} -> {status, output}
    after
      180_000 ->
        Port.close(port)
        Mix.raise("IOS-HOST-SETTINGS: blocked; cause: checker timed out")
    end
  end
end
