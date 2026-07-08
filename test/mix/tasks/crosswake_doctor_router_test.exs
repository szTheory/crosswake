defmodule Mix.Tasks.Crosswake.DoctorRouterTest do
  use ExUnit.Case, async: false

  @moduletag timeout: 120_000

  @repo_root Path.expand("../../..", __DIR__)

  setup_all do
    target =
      Path.join(
        System.tmp_dir!(),
        "crosswake-doctor-router-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(Path.join(target, "lib/clean_room_host"))
    write_mix_project!(target)

    {output, exit_code} = run_mix(target, ["deps.get"])
    assert exit_code == 0, output

    on_exit(fn -> File.rm_rf(target) end)

    {:ok, target: target}
  end

  test "accepts a freshly written Phoenix router without external preloading", %{target: target} do
    write_source!(
      target,
      "lib/clean_room_host/router.ex",
      """
      defmodule CleanRoomHost.Router do
        use Phoenix.Router
      end
      """
    )

    {output, _exit_code} =
      run_mix(target, ["crosswake.doctor", "--router", "CleanRoomHost.Router"])

    assert output =~ "Crosswake doctor report"
    refute output =~ "router module CleanRoomHost.Router"
  end

  test "reports a missing router as unavailable after app config and compile", %{target: target} do
    {output, exit_code} =
      run_mix(target, ["crosswake.doctor", "--router", "CleanRoomHost.MissingRouter"])

    assert exit_code != 0

    assert output =~
             "router module CleanRoomHost.MissingRouter is not available after app.config and compile"
  end

  test "reports a loaded module without Phoenix router shape distinctly", %{target: target} do
    write_source!(
      target,
      "lib/clean_room_host/not_router.ex",
      """
      defmodule CleanRoomHost.NotRouter do
        def ping, do: :pong
      end
      """
    )

    {output, exit_code} =
      run_mix(target, ["crosswake.doctor", "--router", "CleanRoomHost.NotRouter"])

    assert exit_code != 0

    assert output =~
             "router module CleanRoomHost.NotRouter loaded but is not a Phoenix router (__routes__/0 missing)"
  end

  defp write_mix_project!(target) do
    write_source!(
      target,
      "mix.exs",
      """
      defmodule CleanRoomHost.MixProject do
        use Mix.Project

        def project do
          [
            app: :clean_room_host,
            version: "0.1.0",
            elixir: "~> 1.19",
            start_permanent: Mix.env() == :prod,
            deps: deps()
          ]
        end

        def application do
          [
            extra_applications: [:logger]
          ]
        end

        defp deps do
          [
            {:crosswake, path: #{inspect(@repo_root)}}
          ]
        end
      end
      """
    )
  end

  defp write_source!(target, relative_path, contents) do
    path = Path.join(target, relative_path)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, contents)
  end

  defp run_mix(target, args) do
    System.cmd("mix", args,
      cd: target,
      env: [{"MIX_ENV", "test"}],
      stderr_to_stdout: true
    )
  end
end
