Code.require_file("../../support/router_fixtures.ex", __DIR__)

defmodule Crosswake.DoctorTest do
  use ExUnit.Case, async: true

  alias Crosswake.Doctor
  alias Crosswake.Doctor.Check
  alias Crosswake.Doctor.Formatter
  alias Crosswake.Doctor.JSONFormatter
  alias Crosswake.Offline.Status
  alias Crosswake.Offline.Telemetry

  setup do
    target =
      Path.join(System.tmp_dir!(), "crosswake-doctor-#{System.unique_integer([:positive])}")

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

    install_manifest =
      Jason.encode!(%{
        schema_version: 1,
        crosswake_version: "0.1.0",
        router_path: Path.relative_to(router_path, target),
        web_module: "DemoWeb",
        policy_module: "DemoWeb.Crosswake.Policy",
        files: %{created_or_reused: [Path.relative_to(policy_path, target)]},
        markers: ["# crosswake:install:start", "# crosswake:install:end"]
      })

    File.write!(install_manifest_path, install_manifest)
    write_shell_artifacts!(target)
    write_proof_hook!(target, "ios", 0, "ios proof passed")
    write_proof_hook!(target, "android", 0, "android proof passed")

    %{
      target: target,
      install_manifest_path: install_manifest_path
    }
  end

  test "doctor reports shell, bridge, route unavailable, pack posture, and proof verification requirements",
       %{target: target, install_manifest_path: install_manifest_path} do
    report =
      Doctor.run(
        route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    assert report.status == :error
    assert report.manifest != nil
    assert report.support.status == :verification_required
    assert report.shells.ios.generated.ok?
    assert report.shells.android.route_unavailable.ok?
    assert report.shells.ios.proof.status == :verification_required
    assert report.shells.android.proof.status == :verification_required
    assert report.bridge.allowed_commands == ["app.info.get", "files.pick", "haptics.impact"]
    assert report.offline.status == :supported
    assert report.offline.states == Enum.map(Status.states(), &Atom.to_string/1)
    assert report.offline.telemetry.metadata_keys ==
             Enum.map(Telemetry.metadata_keys(), &Atom.to_string/1)
    assert report.offline.routes["library"]["offline"] == "cached_read_only"
    assert report.offline.routes["study-session"]["sync_seam"] == "study_reviews"
    assert report.bridge.denial_reasons |> Enum.sort() ==
             Enum.sort([
               "compatibility_mismatch",
               "inactive_route",
               "origin_denied",
               "pack_incompatible",
               "undeclared_capability",
               "unavailable_capability"
             ])

    assert Enum.any?(report.findings, &(&1.check == "shell_activation" and &1.severity == :advisory))
    assert Enum.any?(report.findings, &(&1.check == "bridge_posture" and &1.severity == :warning))

    assert Enum.any?(
             report.findings,
             &(&1.check == "proof_posture" and &1.code == "proof_hook_verification_required")
           )

    assert Enum.any?(
             report.findings,
             &(&1.check == "support_posture" and &1.code == "support_claim_verification_required")
           )
  end

  test "doctor findings are structured and formatter output stays stable when proof hooks pass", %{
    target: target,
    install_manifest_path: install_manifest_path
  } do
    ios_proof = write_proof_hook!(target, "ios", 0, "ios proof passed")
    android_proof = write_proof_hook!(target, "android", 0, "android proof passed")

    report =
      Doctor.run(
        route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
        install_manifest_path: install_manifest_path,
        cwd: target,
        check_native_tools?: true,
        ios_proof_hook_path: ios_proof,
        android_proof_hook_path: android_proof
      )

    assert report.status == :ok
    assert report.support.status == :supported
    assert Enum.all?(report.findings, &match?(%Check{}, &1))

    human = Formatter.render(report)
    json = JSONFormatter.render(report)
    decoded = Jason.decode!(json)

    assert human =~ "support posture: supported"
    assert human =~ "route unavailable=yes"
    assert human =~ "bridge posture: crosswake.bridge@1.0.0"
    assert human =~ "offline posture: supported"
    assert human =~ "queued_for_replay"
    assert human =~ "proof=supported"

    assert decoded["status"] == "ok"
    assert decoded["support"]["status"] == "supported"
    assert decoded["shells"]["ios"]["proof"]["status"] == "supported"
    assert decoded["shells"]["android"]["proof"]["status"] == "supported"
    assert decoded["bridge"]["allowed_commands"] == ["app.info.get", "files.pick", "haptics.impact"]
    assert decoded["offline"]["status"] == "supported"
    assert decoded["offline"]["routes"]["study-session"]["sync_seam"] == "study_reviews"
    assert "conflict_requires_attention" in decoded["offline"]["states"]
    assert Enum.any?(decoded["findings"], &(&1["severity"] == "advisory"))
  end

  defp write_shell_artifacts!(target) do
    ios_root = Path.join(target, "native/ios/crosswake_shell")
    android_root = Path.join(target, "native/android/crosswake_shell")

    write_file!(Path.join(ios_root, "README.md"), "host-owned scaffold once\n")
    write_file!(Path.join(ios_root, "CrosswakeShell.xcodeproj/project.pbxproj"), "PBXNativeTarget\n")

    write_file!(
      Path.join(ios_root, "CrosswakeShell/CrosswakeShellApp.swift"),
      "ActivationCoordinator.bundled\nonOpenURL\nonContinueUserActivity\n"
    )

    write_file!(
      Path.join(ios_root, "CrosswakeShell/ActivationCoordinator.swift"),
      "packIncompatible\ninactiveRoute\n"
    )

    write_file!(
      Path.join(ios_root, "CrosswakeShell/LiveViewContainerViewController.swift"),
      "WKWebView\nWKNavigationDelegate\nsame-origin\n"
    )

    write_file!(Path.join(ios_root, "CrosswakeShell/Info.plist"), "WKAppBoundDomains\n")

    write_file!(
      Path.join(ios_root, "CrosswakeShell/RouteUnavailableView.swift"),
      "Update app\nOpen safe fallback\n"
    )

    write_file!(
      Path.join(ios_root, "CrosswakeShell/BridgeChannel.swift"),
      "app.info.get\nhaptics.impact\nfiles.pick\nrequest\nreply\n"
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
      "pack_incompatible\ninactive_route\n"
    )

    write_file!(
      Path.join(android_root, "app/src/main/java/dev/crosswake/shell/LiveViewFragment.kt"),
      "WebView\nAllowlisted\n"
    )

    write_file!(
      Path.join(android_root, "app/src/main/AndroidManifest.xml"),
      "android.intent.category.BROWSABLE\nandroid.intent.action.VIEW\n"
    )

    write_file!(
      Path.join(android_root, "app/src/main/res/layout/activity_route_unavailable.xml"),
      "Update app\nOpen safe fallback\n"
    )

    write_file!(
      Path.join(android_root, "app/src/main/java/dev/crosswake/shell/BridgeChannel.kt"),
      "app.info.get\nhaptics.impact\nfiles.pick\nrequest\nreply\n"
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
