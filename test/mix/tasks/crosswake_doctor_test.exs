defmodule Mix.Tasks.Crosswake.DoctorTest do
  # async: false — this test changes the global process working directory via
  # File.cd!/2 while exercising the mix task. Under async:true it raced with
  # other async tests doing relative-path reads (e.g. File.read!("guides/...")),
  # failing intermittently under CI's lower concurrency.
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @allowed_bridge_commands [
    "app.info.get",
    "files.pick",
    "haptics.impact",
    "notifications.token.get",
    "permissions.status",
    "share.invoke",
    "transfer.download",
    "transfer.export",
    "transfer.import",
    "transfer.upload.prepare"
  ]

  defmodule CommerceCorridorRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :sensitive do
        live("/billing", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "billing",
            runtime: :live_view,
            capabilities: ["purchase_intent"],
            commerce: [corridor: :subscription_default, role: :purchase_intent]
          ]
        )
      end
    end
  end

  setup do
    target =
      Path.join(System.tmp_dir!(), "crosswake-doctor-task-#{System.unique_integer([:positive])}")

    router_path = Path.join(target, "lib/demo_web/router.ex")
    policy_path = Path.join(target, "lib/demo_web/crosswake/policy.ex")
    install_manifest_path = Path.join(target, "priv/crosswake/install_manifest.json")

    File.mkdir_p!(Path.dirname(router_path))
    File.mkdir_p!(Path.dirname(policy_path))
    File.mkdir_p!(Path.dirname(install_manifest_path))

    File.write!(
      router_path,
      """
      defmodule DemoWeb.Router do
        # crosswake:install:start
        import Crosswake.Router
        # crosswake:install:end
      end
      """
    )

    File.write!(policy_path, "defmodule DemoWeb.Crosswake.Policy do\nend\n")

    File.write!(
      install_manifest_path,
      Jason.encode!(%{
        schema_version: 1,
        crosswake_version: "0.1.0",
        router_path: Path.relative_to(router_path, target),
        web_module: "DemoWeb",
        policy_module: "DemoWeb.Crosswake.Policy",
        files: %{created_or_reused: [Path.relative_to(policy_path, target)]},
        markers: ["# crosswake:install:start", "# crosswake:install:end"]
      })
    )

    write_shell_artifacts!(target)
    write_proof_hook!(target, "ios", 0, "ios proof passed")
    write_proof_hook!(target, "android", 0, "android proof passed")

    %{target: target, install_manifest_path: install_manifest_path}
  end

  test "mix crosswake.doctor emits human-readable output with verification required proof posture",
       %{
         target: target,
         install_manifest_path: install_manifest_path
       } do
    output =
      capture_io(fn ->
        try do
          File.cd!(target, fn ->
            Mix.Tasks.Crosswake.Doctor.run([
              "--router",
              "Elixir.Crosswake.TestSupport.RouterFixtures.ManagedRouter",
              "--install-manifest",
              install_manifest_path
            ])
          end)
        rescue
          Mix.Error -> :ok
        end
      end)

    assert output =~ "Crosswake doctor report"
    assert output =~ "support posture: verification_required"
    assert output =~ "manifest_schema_version=1.0.0"
    assert output =~ "bridge_protocol_version=1.0.0"
    assert output =~ "native_runtime_version=1.0.0"
    assert output =~ "Package versions alone do not determine support truth"
    assert output =~ "route unavailable=yes"
    assert output =~ "offline posture: supported"
    assert output =~ "proof=verification required"
  end

  test "mix crosswake.doctor emits json output with supported shell proof after hooks pass", %{
    target: target,
    install_manifest_path: install_manifest_path
  } do
    ios_proof = write_proof_hook!(target, "ios", 0, "ios proof passed")
    android_proof = write_proof_hook!(target, "android", 0, "android proof passed")

    output =
      capture_io(fn ->
        File.cd!(target, fn ->
          Mix.Tasks.Crosswake.Doctor.run([
            "--router",
            "Elixir.Crosswake.TestSupport.RouterFixtures.ManagedRouter",
            "--install-manifest",
            install_manifest_path,
            "--format",
            "json",
            "--native-checks"
          ])
        end)
      end)

    decoded = Jason.decode!(output)

    assert decoded["status"] == "ok"
    assert decoded["support"]["status"] == "supported"
    assert decoded["support"]["release_policy"]["manifest_schema_version"] == "1.0.0"
    assert decoded["support"]["release_policy"]["bridge_protocol_version"] == "1.0.0"
    assert decoded["support"]["release_policy"]["native_runtime_version"] == "1.0.0"
    assert decoded["shells"]["ios"]["proof"]["status"] == "supported"
    assert decoded["shells"]["android"]["proof"]["status"] == "supported"
    assert decoded["bridge"]["allowed_commands"] == @allowed_bridge_commands
    assert decoded["offline"]["status"] == "supported"
    assert decoded["offline"]["routes"]["study-session"]["sync_seam"] == "study_reviews"
    refute Map.has_key?(decoded, "publish_readiness")

    assert File.read!(ios_proof) =~ "ios proof passed"
    assert File.read!(android_proof) =~ "android proof passed"
  end

  test "mix crosswake.doctor --check-publish emits conditional json readiness and raises on blocking readiness",
       %{target: target, install_manifest_path: install_manifest_path} do
    output =
      capture_io(fn ->
        try do
          File.cd!(target, fn ->
            Mix.Tasks.Crosswake.Doctor.run([
              "--router",
              "Elixir.Mix.Tasks.Crosswake.DoctorTest.CommerceCorridorRouter",
              "--install-manifest",
              install_manifest_path,
              "--format",
              "json",
              "--check-publish"
            ])
          end)
        rescue
          Mix.Error -> :ok
        end
      end)

    decoded = Jason.decode!(output)

    assert decoded["publish_readiness"]["schema_version"] == "1.0.0"
    assert decoded["publish_readiness"]["status"] == "not_ready"

    assert Enum.any?(decoded["publish_readiness"]["checks"], fn check ->
             check["code"] == "diag.provider.adapter_shipped_seams" and
               check["blocking"] == false
           end)

    assert Enum.any?(decoded["findings"], fn finding ->
             finding["code"] == "diag.provider.adapter_shipped_seams" and
               finding["check"] == "provider_adapter_readiness"
           end)
  end

  test "mix crosswake.doctor --check-publish human output includes publish readiness sidecar",
       %{target: target, install_manifest_path: install_manifest_path} do
    output =
      capture_io(fn ->
        try do
          File.cd!(target, fn ->
            Mix.Tasks.Crosswake.Doctor.run([
              "--router",
              "Elixir.Mix.Tasks.Crosswake.DoctorTest.CommerceCorridorRouter",
              "--install-manifest",
              install_manifest_path,
              "--check-publish"
            ])
          end)
        rescue
          Mix.Error -> :ok
        end
      end)

    assert output =~ "Publish readiness"
    assert output =~ "diag.publish."
    assert output =~ "diag.provider.adapter_shipped_seams"
    assert output =~ "claim_scope=Commerce provider adapter readiness"
  end

  test "blocking failures raise instead of hiding behind warnings" do
    assert_raise Mix.Error, fn ->
      File.cd!(System.tmp_dir!(), fn ->
        Mix.Tasks.Crosswake.Doctor.run([
          "--router",
          "Elixir.Crosswake.TestSupport.RouterFixtures.ManagedRouter",
          "--install-manifest",
          "does-not-exist.json"
        ])
      end)
    end
  end

  test "mix crosswake.doctor human output includes canonical commerce corridor diagnostics", %{
    target: target,
    install_manifest_path: install_manifest_path
  } do
    output =
      capture_io(fn ->
        try do
          File.cd!(target, fn ->
            Mix.Tasks.Crosswake.Doctor.run([
              "--router",
              "Elixir.Mix.Tasks.Crosswake.DoctorTest.CommerceCorridorRouter",
              "--install-manifest",
              install_manifest_path
            ])
          end)
        rescue
          Mix.Error -> :ok
        end
      end)

    assert output =~ "commerce.corridor.runtime_incompatible"
    assert output =~ "commerce.corridor.prerequisite_missing"
    assert output =~ "corridor_ref=subscription_default"
    assert output =~ "role=purchase_intent"
    assert output =~ "fallback_hint=return_to_phoenix_guidance"
  end

  test "mix crosswake.doctor json output serializes commerce corridor fields", %{
    target: target,
    install_manifest_path: install_manifest_path
  } do
    output =
      capture_io(fn ->
        try do
          File.cd!(target, fn ->
            Mix.Tasks.Crosswake.Doctor.run([
              "--router",
              "Elixir.Mix.Tasks.Crosswake.DoctorTest.CommerceCorridorRouter",
              "--install-manifest",
              install_manifest_path,
              "--format",
              "json"
            ])
          end)
        rescue
          Mix.Error -> :ok
        end
      end)

    decoded = Jason.decode!(output)

    corridor_findings =
      decoded["findings"]
      |> Enum.filter(fn finding ->
        String.starts_with?(finding["code"], "commerce.corridor.") and
          finding["check"] == "commerce_corridor"
      end)

    assert corridor_findings != []

    assert Enum.all?(corridor_findings, fn finding ->
             Map.has_key?(finding, "corridor_ref") and
               Map.has_key?(finding, "role") and
               Map.has_key?(finding, "denial_code") and
               Map.has_key?(finding, "fallback_hint")
           end)

    assert Enum.any?(corridor_findings, fn finding ->
             finding["corridor_ref"] == "subscription_default" and
               finding["role"] == "purchase_intent" and
               finding["denial_code"] == finding["code"] and
               finding["fallback_hint"] == "return_to_phoenix_guidance"
           end)
  end

  defp write_shell_artifacts!(target) do
    ios_root = Path.join(target, "native/ios/crosswake_shell")
    android_root = Path.join(target, "native/android/crosswake_shell")

    write_file!(Path.join(ios_root, "README.md"), "host-owned scaffold once\n")

    write_file!(
      Path.join(ios_root, "CrosswakeShell.xcodeproj/project.pbxproj"),
      "PBXNativeTarget\n"
    )

    write_file!(
      Path.join(ios_root, "CrosswakeShell/CrosswakeShellApp.swift"),
      "ActivationCoordinator.bundled\nonOpenURL\nonContinueUserActivity\n"
    )

    write_file!(
      Path.join(ios_root, "CrosswakeShell/ActivationCoordinator.swift"),
      "packIncompatible\ninactiveRoute\nexternalEntryDenied\n"
    )

    write_file!(
      Path.join(ios_root, "CrosswakeShell/LiveViewContainerViewController.swift"),
      "WKWebView\nWKNavigationDelegate\nsame-origin\n"
    )

    write_file!(Path.join(ios_root, "CrosswakeShell/Info.plist"), "WKAppBoundDomains\nNSCameraUsageDescription\nNSPhotoLibraryUsageDescription\naps-environment\nNSPrivacyCollectedDataTypeDeviceID\ncom.apple.developer.associated-domains\n")

    write_file!(
      Path.join(ios_root, "CrosswakeShell/RouteUnavailableView.swift"),
      "Update app\nOpen safe fallback\n"
    )

    write_file!(
      Path.join(ios_root, "CrosswakeShell/BridgeChannel.swift"),
      "app.info.get\nfiles.pick\nhaptics.impact\npermissions.status\ntransfer.download\ntransfer.export\ntransfer.import\ntransfer.upload.prepare\nrequest\nreply\n"
    )

    write_file!(
      Path.join(ios_root, "Fixtures/crosswake_manifest.json"),
      ~s({"manifest_schema_version":"1.0.0"})
    )

    write_file!(
      Path.join(ios_root, "Fixtures/route_denial.json"),
      ~s({"reason":"pack_incompatible"})
    )

    write_file!(Path.join(android_root, "README.md"), "host-owned scaffold once\n")

    write_file!(
      Path.join(android_root, "app/build.gradle"),
      "applicationId \"dev.crosswake.shell\"\n"
    )

    write_file!(
      Path.join(android_root, "app/src/main/java/dev/crosswake/shell/MainActivity.kt"),
      "ActivationCoordinator.bundled\n"
    )

    write_file!(
      Path.join(android_root, "app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt"),
      "pack_incompatible\ninactive_route\nexternal_entry_denied\n"
    )

    write_file!(
      Path.join(android_root, "app/src/main/java/dev/crosswake/shell/LiveViewFragment.kt"),
      "WebView\nAllowlisted\n"
    )

    write_file!(
      Path.join(android_root, "app/src/main/AndroidManifest.xml"),
      "android.intent.category.BROWSABLE\nandroid.intent.action.VIEW\nPOST_NOTIFICATIONS\nandroid.permission.CAMERA\nandroid.permission.VIBRATE\n"
    )

    write_file!(
      Path.join(android_root, "app/src/main/res/layout/activity_route_unavailable.xml"),
      "Update app\nOpen safe fallback\n"
    )

    write_file!(
      Path.join(android_root, "app/src/main/java/dev/crosswake/shell/BridgeChannel.kt"),
      "app.info.get\nfiles.pick\nhaptics.impact\npermissions.status\ntransfer.download\ntransfer.export\ntransfer.import\ntransfer.upload.prepare\nrequest\nreply\n"
    )

    write_file!(
      Path.join(android_root, "app/src/main/assets/crosswake_manifest.json"),
      ~s({"manifest_schema_version":"1.0.0"})
    )

    write_file!(
      Path.join(android_root, "app/src/main/assets/route_denial.json"),
      ~s({"reason":"pack_incompatible"})
    )
  end

  defp write_proof_hook!(target, platform, exit_status, output) do
    path =
      case platform do
        "ios" -> Path.join(target, "script/verify_generated_ios_shell.sh")
        "android" -> Path.join(target, "script/verify_generated_android_shell.sh")
      end

    write_file!(
      path,
      """
      #!/usr/bin/env bash
      echo #{inspect(output)}
      exit #{exit_status}
      """
    )

    File.chmod!(path, 0o755)
    path
  end

  defp write_file!(path, contents) do
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, contents)
  end
end
