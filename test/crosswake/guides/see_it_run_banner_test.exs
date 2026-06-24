defmodule Crosswake.Guides.SeeItRunBannerTest do
  use ExUnit.Case, async: true

  # The canonical launch script whose banner text this test guards.
  @banner_script_path "bin/see-it-run.sh"

  # The source from which the demo port is derived — never hardcoded here (D-21).
  @phoenix_config_path "examples/phoenix_host/config/runtime.exs"

  # ---------------------------------------------------------------------------
  # Readability / source-derived sanity
  # ---------------------------------------------------------------------------

  test "source-derived facts are readable" do
    assert File.exists?(@banner_script_path),
           "expected #{@banner_script_path} to exist (produced by plan 127-01)"

    assert phoenix_host_port() =~ ~r/^\d+$/,
           "expected a numeric port from #{@phoenix_config_path}"
  end

  # ---------------------------------------------------------------------------
  # Main drift guard — the load-bearing validation for LAUNCH-01 (D-21)
  # ---------------------------------------------------------------------------

  test "bin/see-it-run.sh banner contains source-derived facts (port, routes, commands, posture)" do
    banner = File.read!(@banner_script_path)

    assert_no_drift_failures(scan_banner({@banner_script_path, banner}))
  end

  # ---------------------------------------------------------------------------
  # Anti-vacuity cases (D-21 house idiom)
  # Each synthetic mutation MUST trigger a specific failure category,
  # proving the guard is not a no-op.
  # ---------------------------------------------------------------------------

  test "scanner rejects wrong port" do
    banner = File.read!(@banner_script_path)
    port = phoenix_host_port()

    mutated = String.replace(banner, "localhost:#{port}", "localhost:4000")

    assert_failure_category(
      scan_banner({"synthetic/banner_wrong_port.sh", mutated}),
      :wrong_port
    )
  end

  test "scanner rejects missing route" do
    banner = File.read!(@banner_script_path)

    mutated = String.replace(banner, "/bridge-proof", "/nope")

    assert_failure_category(
      scan_banner({"synthetic/banner_missing_route.sh", mutated}),
      :missing_route
    )
  end

  test "scanner rejects missing native posture label" do
    banner = File.read!(@banner_script_path)

    mutated =
      banner
      |> String.replace(~r/advisory/i, "optional")

    assert_failure_category(
      scan_banner({"synthetic/banner_missing_posture.sh", mutated}),
      :missing_native_label
    )
  end

  # ---------------------------------------------------------------------------
  # Banner scan — returns a list of failures (empty = green)
  # ---------------------------------------------------------------------------

  defp scan_banner({path, contents}) do
    port = phoenix_host_port()
    url = "http://localhost:#{port}"

    [
      # Derived URL
      require_contains(path, contents, url, :wrong_port, "banner must contain derived URL #{url}"),

      # Route list — home, offline, bridge-proof
      require_contains(
        path,
        contents,
        "    /              ",
        :missing_route,
        "banner must contain the '/' home route line"
      ),
      require_contains(
        path,
        contents,
        "/offline",
        :missing_route,
        "banner must contain the /offline route"
      ),
      require_contains(
        path,
        contents,
        "/bridge-proof",
        :missing_route,
        "banner must contain the /bridge-proof route"
      ),

      # iOS command literals
      require_contains(
        path,
        contents,
        "-scheme Dev",
        :missing_command,
        "banner must contain iOS -scheme Dev literal"
      ),
      require_contains(
        path,
        contents,
        "Debug-Dev",
        :missing_command,
        "banner must contain iOS Debug-Dev configuration literal"
      ),

      # Android command literals
      require_contains(
        path,
        contents,
        "installDevDebug",
        :missing_command,
        "banner must contain Android installDevDebug gradle task"
      ),
      require_contains(
        path,
        contents,
        "adb shell am start -n dev.crosswake.shell.dev/.MainActivity",
        :missing_command,
        "banner must contain Android adb am start command"
      ),
      require_contains(
        path,
        contents,
        "JAVA_HOME=/opt/homebrew/opt/openjdk@17",
        :missing_command,
        "banner must contain JAVA_HOME=/opt/homebrew/opt/openjdk@17"
      ),

      # Native posture words (D-21 scope: advisory, simulator, emulator, proven native build)
      require_contains(
        path,
        contents,
        "advisory",
        :missing_native_label,
        "banner must carry the 'advisory' posture word"
      ),
      require_contains(
        path,
        contents,
        "simulator",
        :missing_native_label,
        "banner must carry the 'simulator' posture word"
      ),
      require_contains(
        path,
        contents,
        "emulator",
        :missing_native_label,
        "banner must carry the 'emulator' posture word"
      ),
      require_contains(
        path,
        contents,
        "proven native build",
        :missing_native_label,
        "banner must carry a 'proven native build' phrase"
      )
    ]
    |> List.flatten()
  end

  # ---------------------------------------------------------------------------
  # Source derivation
  # ---------------------------------------------------------------------------

  defp phoenix_host_port do
    @phoenix_config_path
    |> File.read!()
    |> source_port!(
      ~r/System\.get_env\("PORT"\)\s*\|\|\s*"(\d+)"/,
      @phoenix_config_path
    )
  end

  # ---------------------------------------------------------------------------
  # Shared helpers (mirrored from quick_start_adoption_drift_test.exs)
  # ---------------------------------------------------------------------------

  defp source_port!(contents, regex, path) do
    case Regex.run(regex, contents) do
      [_match, port] -> port
      _ -> raise "could not derive port from #{path}"
    end
  end

  defp require_contains(path, contents, needle, category, detail) do
    if String.contains?(contents, needle) do
      []
    else
      [failure(path, category, detail: detail)]
    end
  end

  defp failure(path, category, opts) do
    %{
      path: path,
      category: category,
      detail: Keyword.fetch!(opts, :detail)
    }
  end

  defp format_failures(failures) do
    Enum.map_join(failures, "\n", fn f ->
      "- #{f.path} [#{f.category}] #{f.detail}"
    end)
  end

  defp assert_no_drift_failures(failures) do
    assert failures == [],
           "see-it-run.sh banner drift found:\n" <> format_failures(failures)
  end

  defp assert_failure_category(failures, category) do
    assert Enum.any?(failures, &(&1.category == category)),
           "expected #{inspect(category)} failure in synthetic case, got:\n" <>
             format_failures(failures)
  end
end
