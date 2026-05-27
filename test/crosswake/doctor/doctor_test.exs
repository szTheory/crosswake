Code.require_file("../../support/router_fixtures.ex", __DIR__)

defmodule Crosswake.DoctorTest do
  use ExUnit.Case, async: true

  alias Crosswake.Doctor

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
  alias Crosswake.Doctor.Check
  alias Crosswake.Doctor.Formatter
  alias Crosswake.Doctor.JSONFormatter
  alias Crosswake.Offline.Status
  alias Crosswake.Offline.Telemetry
  alias Crosswake.SupportMatrix

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
    assert report.bridge.allowed_commands == @allowed_bridge_commands
    assert report.offline.status == :supported
    assert report.support.release_policy.crosswake_version == "0.1.0"
    assert report.support.release_policy.manifest_schema_version == "1.0.0"
    assert report.support.release_policy.bridge_protocol_version == "1.0.0"
    assert report.support.release_policy.native_runtime_version == "1.0.0"
    assert report.support.release_policy.package_version_truth =~ "Package versions alone"
    assert report.offline.states == Enum.map(Status.states(), &Atom.to_string/1)
    assert report.offline.telemetry.metadata_keys ==
             Enum.map(Telemetry.metadata_keys(), &Atom.to_string/1)
    assert report.offline.routes["library"]["offline"] == "cached_read_only"
    assert report.offline.routes["study-session"]["sync_seam"] == "study_reviews"
    assert report.bridge.denial_reasons |> Enum.sort() ==
             Enum.sort([
               "commerce_corridor",
               "compatibility_mismatch",
               "external_entry_denied",
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
    assert human =~ "release policy:"
    assert human =~ "manifest_schema_version=1.0.0"
    assert human =~ "bridge_protocol_version=1.0.0"
    assert human =~ "native_runtime_version=1.0.0"
    assert human =~ "Package versions alone do not determine support truth"
    assert human =~ "route unavailable=yes"
    assert human =~ "bridge posture: crosswake.bridge@1.0.0"
    assert human =~ "offline posture: supported"
    assert human =~ "queued_for_replay"
    assert human =~ "proof=supported"

    assert decoded["status"] == "ok"
    assert decoded["support"]["status"] == "supported"
    assert decoded["support"]["release_policy"]["manifest_schema_version"] == "1.0.0"
    assert decoded["support"]["release_policy"]["bridge_protocol_version"] == "1.0.0"
    assert decoded["support"]["release_policy"]["native_runtime_version"] == "1.0.0"
    assert decoded["support"]["release_policy"]["package_version_truth"] =~ "Package versions alone"
    assert decoded["shells"]["ios"]["proof"]["status"] == "supported"
    assert decoded["shells"]["android"]["proof"]["status"] == "supported"
    assert decoded["bridge"]["allowed_commands"] == @allowed_bridge_commands
    assert decoded["offline"]["status"] == "supported"
    assert decoded["offline"]["routes"]["study-session"]["sync_seam"] == "study_reviews"
    assert "conflict_requires_attention" in decoded["offline"]["states"]
    assert Enum.any?(decoded["findings"], &(&1["severity"] == "advisory"))
  end

  defmodule CommerceCorridorRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :sensitive do
        live "/billing", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "billing",
            runtime: :live_view,
            capabilities: ["purchase_intent"],
            commerce: [corridor: :subscription_default, role: :purchase_intent]
          ]
      end
    end
  end

  defmodule UndeclaredCommerceCorridorRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :sensitive do
        live "/billing", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "billing",
            runtime: :live_view,
            capabilities: ["purchase_intent"],
            commerce: [corridor: :missing_subscription_profile, role: :purchase_intent]
          ]
      end
    end
  end

  test "doctor emits canonical commerce corridor findings and keeps taxonomy parity with support matrix", %{
    target: target,
    install_manifest_path: install_manifest_path
  } do
    report =
      Doctor.run(
        route_source: CommerceCorridorRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    corridor_findings =
      report.findings
      |> Enum.filter(&String.starts_with?(&1.code, "commerce.corridor."))

    emitted_codes =
      corridor_findings
      |> Enum.map(& &1.code)
      |> Enum.uniq()
      |> Enum.sort()

    assert "commerce.corridor.runtime_incompatible" in emitted_codes
    assert "commerce.corridor.prerequisite_missing" in emitted_codes

    assert MapSet.subset?(
             MapSet.new(emitted_codes),
             MapSet.new(SupportMatrix.commerce_corridor_denial_codes())
           )

    assert Enum.any?(corridor_findings, fn finding ->
             finding.details[:corridor_ref] == "subscription_default" and
               finding.details[:role] == :purchase_intent and
               finding.details[:denial_code] == finding.code and
               finding.details[:fallback_hint] == "return_to_phoenix_guidance"
           end)

    human = Formatter.render(report)
    decoded = JSONFormatter.render(report) |> Jason.decode!()

    assert human =~ "commerce.corridor.runtime_incompatible"
    assert human =~ "corridor_ref=subscription_default"
    assert human =~ "denial_code=commerce.corridor.prerequisite_missing"
    assert human =~ "fallback_hint=return_to_phoenix_guidance"

    assert Enum.any?(decoded["findings"], fn finding ->
             finding["code"] == "commerce.corridor.runtime_incompatible" and
               finding["corridor_ref"] == "subscription_default" and
               finding["role"] == "purchase_intent" and
               finding["denial_code"] == "commerce.corridor.runtime_incompatible" and
               finding["fallback_hint"] == "return_to_phoenix_guidance"
           end)
  end

  test "doctor maps undeclared corridor compile failures onto canonical commerce denial IDs", %{
    target: target,
    install_manifest_path: install_manifest_path
  } do
    report =
      Doctor.run(
        route_source: UndeclaredCommerceCorridorRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    assert Enum.any?(report.findings, fn finding ->
             finding.code == "commerce.corridor.undeclared" and
               finding.check == "commerce_corridor" and
               finding.details[:denial_code] == "commerce.corridor.undeclared"
           end)
  end

  defmodule BoundaryViolationRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :offline_island, offline: :local_first, security: :standard do
        live "/violator", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "violator",
            island_contract: :violator_v1,
            capabilities: ["background_sync", "generic_plugin_bus"]
          ]
      end
    end
  end

  test "doctor catches explicit v1 boundaries like background_sync on offline_island", %{
    target: target,
    install_manifest_path: install_manifest_path
  } do
    report =
      Doctor.run(
        route_source: BoundaryViolationRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    assert report.status == :error
    
    sync_finding = Enum.find(report.findings, &(&1.code == "unsupported_capability" and &1.details.capability == "background_sync"))
    assert sync_finding
    assert sync_finding.severity == :error
    assert sync_finding.message =~ "requests background_sync which is an explicit v1 boundary"

    plugin_finding = Enum.find(report.findings, &(&1.code == "unsupported_capability" and &1.details.capability == "generic_plugin_bus"))
    assert plugin_finding
    assert plugin_finding.severity == :error
    assert plugin_finding.message =~ "requests generic_plugin_bus which is an explicit v1 boundary"
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
      "packIncompatible\ninactiveRoute\nexternalEntryDenied\n"
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
      "android.intent.category.BROWSABLE\nandroid.intent.action.VIEW\n"
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
