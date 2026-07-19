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
    write_install_fixture!(target)
    write_shell_artifacts!(target)
    write_proof_hook!(target, "ios", 0, "ios proof passed")
    write_proof_hook!(target, "android", 0, "android proof passed")

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
      defmodule CleanRoomHost.PageController do
        def init(opts), do: opts
        def call(conn, _opts), do: conn
      end

      defmodule CleanRoomHost.Router do
        # crosswake:install:start
        use Crosswake.Router
        # crosswake:install:end

        scope "/" do
          crosswake_defaults runtime: :live_view, offline: :cached_read_only, security: :standard do
            get "/dashboard", CleanRoomHost.PageController, :index,
              crosswake: [
                id: "dashboard",
                capabilities: ["app_info"]
              ]
          end
        end
      end
      """
    )

    {output, exit_code} =
      run_mix(target, [
        "crosswake.doctor",
        "--router",
        "CleanRoomHost.Router",
        "--install-manifest",
        "priv/crosswake/install_manifest.json",
        "--native-checks"
      ])

    assert exit_code == 0, output
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

  defp write_install_fixture!(target) do
    router_path = Path.join(target, "lib/clean_room_host/router.ex")
    policy_path = Path.join(target, "lib/clean_room_host/crosswake/policy.ex")
    install_manifest_path = Path.join(target, "priv/crosswake/install_manifest.json")

    write_source!(
      target,
      "lib/clean_room_host/crosswake/policy.ex",
      "defmodule CleanRoomHost.Crosswake.Policy do\nend\n"
    )

    write_source!(
      target,
      "priv/crosswake/install_manifest.json",
      Jason.encode!(%{
        schema_version: 1,
        crosswake_version: "0.1.0",
        router_path: Path.relative_to(router_path, target),
        web_module: "CleanRoomHost",
        policy_module: "CleanRoomHost.Crosswake.Policy",
        files: %{created_or_reused: [Path.relative_to(policy_path, target)]},
        markers: ["# crosswake:install:start", "# crosswake:install:end"]
      })
    )

    install_manifest_path
  end

  defp write_shell_artifacts!(target) do
    ios_root = Path.join(target, "native/ios/crosswake_shell")
    android_root = Path.join(target, "native/android/crosswake_shell")

    write_source!(target, "native/ios/crosswake_shell/README.md", "host-owned scaffold once\n")

    write_source!(
      target,
      "native/ios/crosswake_shell/CrosswakeShell.xcodeproj/project.pbxproj",
      "PBXNativeTarget\n"
    )

    write_source!(
      target,
      "native/ios/crosswake_shell/CrosswakeShell/CrosswakeShellApp.swift",
      "ActivationCoordinator.bundled\nonOpenURL\nonContinueUserActivity\n"
    )

    write_source!(
      target,
      "native/ios/crosswake_shell/CrosswakeShell/ActivationCoordinator.swift",
      "packIncompatible\ninactiveRoute\nexternalEntryDenied\n"
    )

    write_source!(
      target,
      "native/ios/crosswake_shell/CrosswakeShell/LiveViewContainerViewController.swift",
      "WKWebView\nWKNavigationDelegate\nsame-origin\n"
    )

    write_source!(
      target,
      "native/ios/crosswake_shell/CrosswakeShell/Info.plist",
      "WKAppBoundDomains\nNSCameraUsageDescription\nNSPhotoLibraryUsageDescription\naps-environment\nNSPrivacyCollectedDataTypeDeviceID\ncom.apple.developer.associated-domains\n"
    )

    write_source!(
      target,
      "native/ios/crosswake_shell/CrosswakeShell/RouteUnavailableView.swift",
      "Update app\nOpen safe fallback\n"
    )

    write_source!(
      target,
      "native/ios/crosswake_shell/CrosswakeShell/BridgeChannel.swift",
      "app.info.get\nfiles.pick\nhaptics.impact\npermissions.status\nrequest\nreply\n"
    )

    write_source!(
      target,
      "native/ios/crosswake_shell/Fixtures/crosswake_manifest.json",
      ~s({"manifest_schema_version":"1.0.0"})
    )

    write_source!(
      target,
      "native/ios/crosswake_shell/Fixtures/route_denial.json",
      ~s({"reason":"pack_incompatible"})
    )

    write_source!(
      target,
      "native/android/crosswake_shell/README.md",
      "host-owned scaffold once\n"
    )

    write_source!(
      target,
      "native/android/crosswake_shell/app/build.gradle",
      "applicationId \"dev.crosswake.shell\"\n"
    )

    write_source!(
      target,
      "native/android/crosswake_shell/app/src/main/java/dev/crosswake/shell/MainActivity.kt",
      "ActivationCoordinator.bundled\n"
    )

    write_source!(
      target,
      "native/android/crosswake_shell/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt",
      "pack_incompatible\ninactive_route\nexternal_entry_denied\n"
    )

    write_source!(
      target,
      "native/android/crosswake_shell/app/src/main/java/dev/crosswake/shell/LiveViewFragment.kt",
      "WebView\nAllowlisted\n"
    )

    write_source!(
      target,
      "native/android/crosswake_shell/app/src/main/AndroidManifest.xml",
      "android.intent.category.BROWSABLE\nandroid.intent.action.VIEW\nPOST_NOTIFICATIONS\nandroid.permission.CAMERA\nandroid.permission.VIBRATE\n"
    )

    write_source!(
      target,
      "native/android/crosswake_shell/app/src/main/res/layout/activity_route_unavailable.xml",
      "Update app\nOpen safe fallback\n"
    )

    write_source!(
      target,
      "native/android/crosswake_shell/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt",
      "app.info.get\nfiles.pick\nhaptics.impact\npermissions.status\nrequest\nreply\n"
    )

    write_source!(
      target,
      "native/android/crosswake_shell/app/src/main/assets/crosswake_manifest.json",
      ~s({"manifest_schema_version":"1.0.0"})
    )

    write_source!(
      target,
      "native/android/crosswake_shell/app/src/main/assets/route_denial.json",
      ~s({"reason":"pack_incompatible"})
    )

    assert File.dir?(ios_root)
    assert File.dir?(android_root)
  end

  defp write_proof_hook!(target, platform, exit_status, output) do
    relative_path =
      case platform do
        "ios" -> "script/verify_generated_ios_shell.sh"
        "android" -> "script/verify_generated_android_shell.sh"
      end

    write_source!(
      target,
      relative_path,
      """
      #!/usr/bin/env bash
      echo #{inspect(output)}
      exit #{exit_status}
      """
    )

    path = Path.join(target, relative_path)
    File.chmod!(path, 0o755)
    path
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
