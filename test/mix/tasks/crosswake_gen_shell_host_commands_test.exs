defmodule Mix.Tasks.Crosswake.Gen.ShellHostCommandsTest do
  use ExUnit.Case, async: false

  @source Path.expand("../../../lib/mix/tasks/crosswake.gen.shell.ex", __DIR__)

  setup do
    previous = Application.get_env(:crosswake, :ios_host)

    on_exit(fn ->
      if previous,
        do: Application.put_env(:crosswake, :ios_host, previous),
        else: Application.delete_env(:crosswake, :ios_host)

      Mix.Task.reenable("crosswake.gen.shell")
    end)

    :ok
  end

  test "the task always passes a shell_package context to render/2" do
    source = File.read!(@source)
    assert source =~ "shell_package: shell_package_context("
    refute source =~ "IOSHostGeneration.render(host_config, generated_at: generated_at)"
  end

  test "a declaring router with no resolvable seam-carrying shell raises the gate message" do
    target = Path.join(System.tmp_dir!(), "gen-shell-gate-#{System.unique_integer([:positive])}")
    File.mkdir_p!(target)
    on_exit(fn -> File.rm_rf!(target) end)

    Application.put_env(:crosswake, :ios_host,
      router: Crosswake.TestSupport.HostCommandFixtures.DeclaringRouter,
      origin: "https://study.crosswake.test",
      entry_route_id: "lesson",
      app_bundle_id: "org.crosswake.host",
      proof_app_bundle_id: "org.crosswake.host.proof",
      device_signing: [mode: :automatic, team_id: "ABCDE12345"]
    )

    # Outside the monorepo there is no local shell package, so the remote reference (which
    # carries no seam release) is the only candidate and the gate must block.
    cwd = File.cwd!()
    File.cd!(target)
    on_exit(fn -> File.cd!(cwd) end)

    error =
      assert_raise Mix.Error, fn ->
        ExUnit.CaptureIO.capture_io(fn ->
          Mix.Tasks.Crosswake.Gen.Shell.run(["ios", "--target", target])
        end)
      end

    File.cd!(cwd)

    assert error.message =~ "route lesson"
    assert error.message =~ "host.lesson.audio.play"
    assert error.message =~ "crosswake-shell-core-ios"
    assert error.message =~ "Fix:"
    refute File.exists?(Path.join(target, "native/ios/crosswake_shell/Fixtures"))
  end
end
