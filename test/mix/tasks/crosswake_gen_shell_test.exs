defmodule Mix.Tasks.Crosswake.Gen.ShellTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  @task "crosswake.gen.shell"

  test "generates host-owned ios and android shell baselines with canonical fixtures" do
    target = tmp_dir!("crosswake-shell")

    ios_output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["ios", "--target", target])
      end)

    assert ios_output =~ "Crosswake ios shell scaffold complete"
    assert ios_output =~ "host-owned"
    assert ios_output =~ "scaffold once"
    assert ios_output =~ "not safely regeneratable"

    ios_readme = Path.join(target, "native/ios/crosswake_shell/README.md")

    ios_project =
      Path.join(target, "native/ios/crosswake_shell/CrosswakeShell.xcodeproj/project.pbxproj")

    ios_app =
      Path.join(target, "native/ios/crosswake_shell/CrosswakeShell/CrosswakeShellApp.swift")

    ios_info = Path.join(target, "native/ios/crosswake_shell/CrosswakeShell/Info.plist")

    ios_scheme =
      Path.join(
        target,
        "native/ios/crosswake_shell/CrosswakeShell.xcodeproj/xcshareddata/xcschemes/CrosswakeShell.xcscheme"
      )

    ios_activation_coordinator =
      Path.join(target, "native/ios/crosswake_shell/CrosswakeShell/ActivationCoordinator.swift")

    ios_bridge_channel =
      Path.join(target, "native/ios/crosswake_shell/CrosswakeShell/BridgeChannel.swift")

    ios_route_unavailable =
      Path.join(target, "native/ios/crosswake_shell/CrosswakeShell/RouteUnavailableView.swift")

    ios_live_view =
      Path.join(
        target,
        "native/ios/crosswake_shell/CrosswakeShell/LiveViewContainerViewController.swift"
      )

    ios_pack_store =
      Path.join(target, "native/ios/crosswake_shell/CrosswakeShell/PackStore.swift")

    ios_required_pack_view =
      Path.join(target, "native/ios/crosswake_shell/CrosswakeShell/RequiredPackView.swift")

    ios_tests =
      Path.join(
        target,
        "native/ios/crosswake_shell/CrosswakeShellTests/ActivationCoordinatorTests.swift"
      )

    ios_manifest =
      Path.join(target, "native/ios/crosswake_shell/Fixtures/crosswake_manifest.json")

    ios_activation =
      Path.join(target, "native/ios/crosswake_shell/Fixtures/route_activation.json")

    ios_denial = Path.join(target, "native/ios/crosswake_shell/Fixtures/route_denial.json")

    ios_declared_packs =
      Path.join(target, "native/ios/crosswake_shell/Fixtures/declared_pack_requirements.json")

    ios_installed_packs =
      Path.join(target, "native/ios/crosswake_shell/Fixtures/installed_packs.json")

    ios_pack_inventory =
      Path.join(target, "native/ios/crosswake_shell/Fixtures/pack_inventory.json")

    assert File.read!(ios_readme) =~ "host-owned"
    assert File.read!(ios_readme) =~ "scaffold once"
    refute File.read!(ios_readme) =~ "Phase 1"
    assert File.read!(ios_project) =~ "PBXNativeTarget"
    assert File.read!(ios_project) =~ "CrosswakeShellTests"
    assert File.read!(ios_app) =~ "ActivationCoordinator.bundled"
    assert File.read!(ios_app) =~ "onOpenURL"
    assert File.read!(ios_app) =~ "onContinueUserActivity"
    assert File.read!(ios_app) =~ "LiveViewContainerView"
    assert File.read!(ios_bridge_channel) =~ "app.info.get"
    assert File.read!(ios_bridge_channel) =~ "haptics.impact"
    assert File.read!(ios_bridge_channel) =~ "files.pick"
    assert File.read!(ios_info) =~ "WKAppBoundDomains"
    assert File.read!(ios_scheme) =~ "xcscheme"
    assert File.read!(ios_activation_coordinator) =~ "packIncompatible"
    assert File.read!(ios_activation_coordinator) =~ "inactiveRoute"
    assert File.read!(ios_route_unavailable) =~ "Update app"
    assert File.read!(ios_route_unavailable) =~ "Open safe fallback"
    assert File.read!(ios_live_view) =~ "WKWebView"
    assert File.read!(ios_live_view) =~ "WKNavigationDelegate"
    assert File.read!(ios_live_view) =~ "same-origin"
    assert File.read!(ios_live_view) =~ "App-Bound Domains"
    assert File.read!(ios_pack_store) =~ "enum PackState"
    assert File.read!(ios_pack_store) =~ "case invalidating"
    assert File.read!(ios_pack_store) =~ "func installRequiredPack"
    assert File.read!(ios_pack_store) =~ "func invalidatePack"
    assert File.read!(ios_required_pack_view) =~ "Install Required Pack"
    assert File.read!(ios_required_pack_view) =~ "Update Pack"
    assert File.read!(ios_required_pack_view) =~ "PackStore"
    assert File.read!(ios_tests) =~ "testPackIncompatibleDenialSurfacesUpdateAppAction"
    assert File.read!(ios_tests) =~ "testInAppNavigationDeniesDisallowedOrigin"
    assert File.read!(ios_tests) =~ "testLiveViewContainerDeniesDisallowedOriginNavigation"
    assert File.read!(ios_manifest) =~ "\"manifest_schema_version\""
    assert File.read!(ios_manifest) =~ "\"routes\""
    assert File.read!(ios_activation) =~ "\"declared_pack_requirements\""
    assert File.read!(ios_activation) =~ "\"manifest_source\": \"bundled\""
    assert File.read!(ios_denial) =~ "\"reason\": \"pack_incompatible\""
    assert File.read!(ios_declared_packs) =~ "\"shell.chrome\": \"1.0.0\""
    assert File.read!(ios_installed_packs) =~ "\"shell.chrome\": \"1.0.0\""
    assert File.read!(ios_pack_inventory) =~ "\"integrity_status\": \"verified\""
    assert File.read!(ios_pack_inventory) =~ "\"verified_at\""

    android_output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["android", "--target", target])
      end)

    assert android_output =~ "Crosswake android shell scaffold complete"
    assert android_output =~ "host-owned"
    assert android_output =~ "scaffold once"
    assert android_output =~ "not safely regeneratable"

    android_readme = Path.join(target, "native/android/crosswake_shell/README.md")
    android_settings = Path.join(target, "native/android/crosswake_shell/settings.gradle")
    android_build = Path.join(target, "native/android/crosswake_shell/build.gradle")
    android_props = Path.join(target, "native/android/crosswake_shell/gradle.properties")
    android_wrapper = Path.join(target, "native/android/crosswake_shell/gradlew")

    android_wrapper_props =
      Path.join(
        target,
        "native/android/crosswake_shell/gradle/wrapper/gradle-wrapper.properties"
      )

    android_app_build = Path.join(target, "native/android/crosswake_shell/app/build.gradle")

    android_manifest =
      Path.join(
        target,
        "native/android/crosswake_shell/app/src/main/AndroidManifest.xml"
      )

    android_main_activity =
      Path.join(
        target,
        "native/android/crosswake_shell/app/src/main/java/dev/crosswake/shell/MainActivity.kt"
      )

    android_activation_coordinator =
      Path.join(
        target,
        "native/android/crosswake_shell/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt"
      )

    android_bridge_channel =
      Path.join(
        target,
        "native/android/crosswake_shell/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt"
      )

    android_live_view_fragment =
      Path.join(
        target,
        "native/android/crosswake_shell/app/src/main/java/dev/crosswake/shell/LiveViewFragment.kt"
      )

    android_pack_store =
      Path.join(
        target,
        "native/android/crosswake_shell/app/src/main/java/dev/crosswake/shell/packs/PackStore.kt"
      )

    android_required_pack_activity =
      Path.join(
        target,
        "native/android/crosswake_shell/app/src/main/java/dev/crosswake/shell/packs/RequiredPackActivity.kt"
      )

    android_required_pack_layout =
      Path.join(
        target,
        "native/android/crosswake_shell/app/src/main/res/layout/activity_required_pack.xml"
      )

    android_route_unavailable =
      Path.join(
        target,
        "native/android/crosswake_shell/app/src/main/res/layout/activity_route_unavailable.xml"
      )

    android_unit_tests =
      Path.join(
        target,
        "native/android/crosswake_shell/app/src/test/java/dev/crosswake/shell/ActivationCoordinatorTest.kt"
      )

    android_instrumented_tests =
      Path.join(
        target,
        "native/android/crosswake_shell/app/src/androidTest/java/dev/crosswake/shell/LiveViewBootInstrumentedTest.kt"
      )

    android_activation =
      Path.join(
        target,
        "native/android/crosswake_shell/app/src/main/assets/route_activation.json"
      )

    android_denial =
      Path.join(target, "native/android/crosswake_shell/app/src/main/assets/route_denial.json")

    android_manifest_fixture =
      Path.join(
        target,
        "native/android/crosswake_shell/app/src/main/assets/crosswake_manifest.json"
      )

    android_pack_inventory =
      Path.join(
        target,
        "native/android/crosswake_shell/app/src/main/assets/pack_inventory.json"
      )

    assert File.read!(android_readme) =~ "host-owned"
    assert File.read!(android_readme) =~ "scaffold once"
    refute File.read!(android_readme) =~ "Phase 1"
    assert File.read!(android_settings) =~ "include ':app'"
    assert File.read!(android_build) =~ "com.android.application"
    assert File.read!(android_props) =~ "org.gradle.jvmargs"
    assert File.read!(android_wrapper) =~ "Gradle start up script"
    assert File.read!(android_wrapper_props) =~ "gradle-8.7-bin.zip"
    assert File.read!(android_app_build) =~ "applicationId \"dev.crosswake.shell\""
    assert File.read!(android_app_build) =~ "ManagedVirtualDevice"
    assert File.read!(android_app_build) =~ "androidx.webkit:webkit:1.15.0"
    assert File.read!(android_manifest) =~ "usesCleartextTraffic"
    assert File.read!(android_manifest) =~ "android.intent.category.BROWSABLE"
    assert File.read!(android_manifest) =~ "android.intent.action.VIEW"
    assert File.read!(android_manifest) =~ "RequiredPackActivity"
    assert File.read!(android_main_activity) =~ "ActivationCoordinator.bundled"
    assert File.read!(android_activation_coordinator) =~ "pack_incompatible"
    assert File.read!(android_activation_coordinator) =~ "inactive_route"
    assert File.read!(android_bridge_channel) =~ "app.info.get"
    assert File.read!(android_bridge_channel) =~ "haptics.impact"
    assert File.read!(android_bridge_channel) =~ "files.pick"
    assert File.read!(android_live_view_fragment) =~ "WebView"
    assert File.read!(android_live_view_fragment) =~ "Allowlisted"
    assert File.read!(android_pack_store) =~ "enum class PackState"
    assert File.read!(android_pack_store) =~ "INVALIDATING"
    assert File.read!(android_pack_store) =~ "suspend fun installRequiredPack"
    assert File.read!(android_pack_store) =~ "suspend fun invalidatePack"
    assert File.read!(android_required_pack_activity) =~ "Install Required Pack"
    assert File.read!(android_required_pack_activity) =~ "Update Pack"
    assert File.read!(android_required_pack_activity) =~ "PackStore"
    assert File.read!(android_required_pack_layout) =~ "required_pack_title"
    assert File.read!(android_required_pack_layout) =~ "required_pack_primary"
    assert File.read!(android_route_unavailable) =~ "Update app"
    assert File.read!(android_route_unavailable) =~ "Open safe fallback"
    assert File.read!(android_unit_tests) =~ "packIncompatibleDenialSurfacesUpdateAppAction"
    assert File.read!(android_unit_tests) =~ "inAppNavigationDeniesDisallowedOriginAndKeepsCurrentRouteStable"
    assert File.read!(android_instrumented_tests) =~ "appLinkLaunchMountsBoundedWebView"
    assert File.read!(android_manifest_fixture) =~ "\"manifest_schema_version\""
    assert File.read!(android_activation) =~ "\"declared_pack_requirements\""
    assert File.read!(android_denial) =~ "\"reason\": \"pack_incompatible\""
    assert File.read!(android_pack_inventory) =~ "\"integrity_status\": \"verified\""
    assert File.read!(android_pack_inventory) =~ "\"verified_at\""

    verify_script = Path.join(File.cwd!(), "script/verify_generated_ios_shell.sh")
    assert File.read!(verify_script) =~ "xcodebuild"
    assert File.read!(verify_script) =~ "-showdestinations"
    assert File.read!(verify_script) =~ "scheme=\"CrosswakeShell\""

    android_verify_script = Path.join(File.cwd!(), "script/verify_generated_android_shell.sh")
    assert File.read!(android_verify_script) =~ "sdkmanager"
    assert File.read!(android_verify_script) =~ "connectedDebugAndroidTest"
    assert File.read!(android_verify_script) =~ "commandlinetools-mac-14742923_latest.zip"
  end

  defp tmp_dir!(prefix) do
    path = Path.join(System.tmp_dir!(), "#{prefix}-#{System.unique_integer([:positive])}")
    File.rm_rf!(path)
    File.mkdir_p!(path)
    path
  end
end
