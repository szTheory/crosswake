defmodule Mix.Tasks.Crosswake.Gen.Shell.HostTest do
  use ExUnit.Case, async: false

  @candidate_root Path.expand("../../..", __DIR__)
  @task "crosswake.gen.shell"

  test "generates the declared Phoenix host route and resolves its configured shell identity" do
    host =
      Path.join(
        @candidate_root,
        "examples/phoenix_host_host_test_#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(host)
    on_exit(fn -> File.rm_rf!(host) end)

    File.cp_r!(Path.join(@candidate_root, "examples/phoenix_host"), host,
      on_conflict: fn _source, _destination -> :ok end
    )

    config = Path.join(host, "config/config.exs")
    declared_origin = "https://crosswake-host.test"
    declared_entry_route = "learnloop-study-session"
    expected_app_bundle_id = "dev.crosswake.hostapp"
    expected_proof_bundle_id = "dev.crosswake.hostapp.proof"

    File.write!(
      config,
      "\nconfig :crosswake, :ios_host,\n" <>
        "  router: CrosswakeExample.Router,\n" <>
        "  origin: #{inspect(declared_origin)},\n" <>
        "  entry_route_id: #{inspect(declared_entry_route)},\n" <>
        "  app_bundle_id: #{inspect(expected_app_bundle_id)},\n" <>
        "  proof_app_bundle_id: #{inspect(expected_proof_bundle_id)},\n" <>
        "  device_signing: [mode: :automatic, team_id: \"ABCDE12345\"]\n",
      [:append]
    )

    runtime = Path.join(host, "config/runtime.exs")
    File.write!(runtime, "raise \"runtime configuration must not be evaluated\"\n", [:append])

    probe = Path.join(host, "lib/mix/tasks/crosswake_host_probe.ex")
    File.mkdir_p!(Path.dirname(probe))

    File.write!(probe, """
    defmodule Mix.Tasks.Crosswake.HostProbe do
      use Mix.Task
      @requirements ["compile"]

      def run(args) do
        Mix.Task.run("crosswake.gen.shell", args)
        host_started = Enum.any?(Application.started_applications(), fn {app, _, _} -> app == :crosswake_example end)
        endpoint_started = Process.whereis(CrosswakeExample.Endpoint) != nil
        repo_started = Process.whereis(CrosswakeExample.Repo) != nil
        if host_started or endpoint_started or repo_started, do: Mix.raise("host runtime unexpectedly started")
        Mix.shell().info("host_runtime_stopped=true")
      end
    end
    """)

    output_root = Path.join(host, "generated")

    command_env = [
      {"MIX_ENV", "prod"},
      {"HEX_HOME", "/private/tmp/crosswake-phase179-hex"},
      {"DATABASE_URL", nil},
      {"SECRET_KEY_BASE", nil},
      {"PHX_SERVER", nil}
    ]

    {deps_output, deps_status} =
      System.cmd("mix", ["deps.get"], cd: host, env: command_env, stderr_to_stdout: true)

    assert deps_status == 0,
           "host dependency preparation failed with status #{deps_status}: #{deps_output}"

    {output, status} =
      System.cmd("mix", ["crosswake.host_probe", "ios", "--target", output_root],
        cd: host,
        env: command_env,
        stderr_to_stdout: true
      )

    assert status == 0, "host subprocess failed with status #{status}: #{output}"
    assert output =~ "host_runtime_stopped=true"
    refute output =~ "runtime configuration must not be evaluated"

    manifest_path =
      Path.join(output_root, "native/ios/crosswake_shell/Fixtures/crosswake_manifest.json")

    manifest = manifest_path |> File.read!() |> Jason.decode!()
    assert manifest["host"]["origin"] == declared_origin
    assert Map.has_key?(manifest["routes"], declared_entry_route)

    activation =
      Path.join(output_root, "native/ios/crosswake_shell/Fixtures/route_activation.json")
      |> File.read!()
      |> Jason.decode!()

    assert activation["route_id"] == declared_entry_route
    refute Map.has_key?(activation, "scope_ref")
    refute Map.has_key?(activation, "session")
    refute Map.has_key?(activation, "replay_authority")

    project = Path.join(output_root, "native/ios/crosswake_shell/CrosswakeShell.xcodeproj")
    xcode_cache = Path.join(host, "xcode-cache")

    {settings, xcode_status} =
      System.cmd(
        "xcodebuild",
        [
          "-project",
          project,
          "-scheme",
          "CrosswakeShell",
          "-sdk",
          "iphonesimulator",
          "-showBuildSettings",
          "-json",
          "-derivedDataPath",
          Path.join(xcode_cache, "derived"),
          "-clonedSourcePackagesDirPath",
          Path.join(xcode_cache, "packages"),
          "-packageCachePath",
          Path.join(xcode_cache, "cache"),
          "-disablePackageRepositoryCache"
        ],
        stderr_to_stdout: false
      )

    assert xcode_status == 0, "xcodebuild failed with status #{xcode_status}"
    decoded = Jason.decode!(settings)

    shell_settings = Enum.find(decoded, &(&1["target"] == "CrosswakeShell"))

    assert shell_settings["buildSettings"]["PRODUCT_BUNDLE_IDENTIFIER"] == expected_app_bundle_id,
           "xcodebuild target metadata did not include the expected identity; targets=#{inspect(Enum.map(decoded, & &1["target"]))}, setting_keys=#{inspect(Map.keys(shell_settings["buildSettings"] || %{}) |> Enum.filter(&String.contains?(&1, "PRODUCT")))}"
  end

  test "invalid production host input and legacy overrides fail before creating output" do
    base = %{
      router: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
      origin: "https://crosswake-host.test",
      entry_route_id: "study-session",
      app_bundle_id: "dev.crosswake.hostapp",
      proof_app_bundle_id: "dev.crosswake.hostapp.proof",
      device_signing: [mode: :automatic, team_id: "ABCDE12345"]
    }

    previous = Application.get_env(:crosswake, :ios_host)

    try do
      invalid_cases = [
        {Map.put(base, :unknown, "private canary"), [], "declaration keys"},
        {%{base | router: Crosswake.TestSupport.PageController}, [], "router"},
        {%{base | origin: "https://example.com"}, [], "placeholder host"},
        {%{base | entry_route_id: "not-a-route"}, [], "entry_route_id"},
        {base, ["--router", "Crosswake.TestSupport.RouterFixtures.ManagedRouter"], "overrides"},
        {base, ["--local"], "overrides"}
      ]

      Enum.each(invalid_cases, fn {config, options, expected_error} ->
        target =
          Path.join(
            System.tmp_dir!(),
            "crosswake-invalid-host-#{System.unique_integer([:positive])}"
          )

        Application.put_env(:crosswake, :ios_host, config)
        Mix.Task.reenable(@task)

        error =
          assert_raise Mix.Error, fn ->
            Mix.Task.run(@task, ["ios", "--target", target] ++ options)
          end

        assert error.message =~ expected_error
        refute error.message =~ "private canary"
        refute File.exists?(target)
      end)
    after
      if is_nil(previous),
        do: Application.delete_env(:crosswake, :ios_host),
        else: Application.put_env(:crosswake, :ios_host, previous)
    end
  end
end
