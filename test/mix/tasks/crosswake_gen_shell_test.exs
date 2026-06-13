defmodule Mix.Tasks.Crosswake.Gen.ShellTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  @task "crosswake.gen.shell"

  test "generates iOS scaffold" do
    target = tmp_dir!("crosswake-shell-ios")

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

    ios_crosswake_coordinator =
      Path.join(target, "native/ios/crosswake_shell/CrosswakeShell/CrosswakeCoordinator.swift")

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
    assert File.read!(ios_project) =~ "XCRemoteSwiftPackageReference"
    refute File.read!(ios_project) =~ "XCLocalSwiftPackageReference"

    assert File.read!(ios_app) =~ "CrosswakeCoordinator"
    assert File.read!(ios_app) =~ "onOpenURL"
    assert File.read!(ios_app) =~ "bootstrap"

    assert File.read!(ios_info) =~ "WKAppBoundDomains"
    refute File.read!(ios_info) =~ "NSCameraUsageDescription"
    assert File.read!(ios_info) =~ "https://docs.crosswake.dev/capabilities"

    assert File.read!(ios_scheme) =~ "xcscheme"

    assert File.exists?(ios_crosswake_coordinator)
    assert File.read!(ios_crosswake_coordinator) =~ "CrosswakeCoordinator"

    assert File.read!(ios_manifest) =~ "\"manifest_schema_version\""
    assert File.read!(ios_manifest) =~ "\"routes\""
    assert File.read!(ios_activation) =~ "\"declared_pack_requirements\""
    assert File.read!(ios_activation) =~ "\"manifest_source\": \"bundled\""
    assert File.read!(ios_denial) =~ "\"reason\": \"pack_incompatible\""
    assert File.read!(ios_declared_packs) =~ "\"shell.chrome\": \"1.0.0\""
    assert File.read!(ios_installed_packs) =~ "\"shell.chrome\": \"1.0.0\""
    assert File.read!(ios_pack_inventory) =~ "\"integrity_status\": \"verified\""
    assert File.read!(ios_pack_inventory) =~ "\"verified_at\""

    verify_script = Path.join(File.cwd!(), "script/verify_generated_ios_shell.sh")
    assert File.read!(verify_script) =~ "xcodebuild"
    assert File.read!(verify_script) =~ "-showdestinations"
    assert File.read!(verify_script) =~ "SCHEME=\"${CROSSWAKE_IOS_SCHEME:-CrosswakeShell}\""
  end

  test "generates Android scaffold" do
    target = tmp_dir!("crosswake-shell-android")

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

    android_crosswake_view_model =
      Path.join(
        target,
        "native/android/crosswake_shell/app/src/main/java/dev/crosswake/shell/CrosswakeViewModel.kt"
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
    assert File.read!(android_manifest) =~ "https://docs.crosswake.dev/capabilities"
    refute File.read!(android_manifest) =~ "CAMERA"

    assert File.exists?(android_main_activity)
    assert File.read!(android_main_activity) =~ "MainActivity"

    assert File.exists?(android_crosswake_view_model)
    assert File.read!(android_crosswake_view_model) =~ "CrosswakeViewModel"

    assert File.read!(android_manifest_fixture) =~ "\"manifest_schema_version\""
    assert File.read!(android_activation) =~ "\"declared_pack_requirements\""
    assert File.read!(android_denial) =~ "\"reason\": \"pack_incompatible\""
    assert File.read!(android_pack_inventory) =~ "\"integrity_status\": \"verified\""
    assert File.read!(android_pack_inventory) =~ "\"verified_at\""

    android_verify_script = Path.join(File.cwd!(), "script/verify_generated_android_shell.sh")
    assert File.read!(android_verify_script) =~ "sdkmanager"
    assert File.read!(android_verify_script) =~ "connectedDebugAndroidTest"
    assert File.read!(android_verify_script) =~ "commandlinetools-mac-14742923_latest.zip"
  end

  test "supports --local flag for SPM and Maven dependencies" do
    ios_local_target = tmp_dir!("crosswake-shell-local-ios")
    capture_io(fn ->
      Mix.Task.reenable(@task)
      Mix.Task.run(@task, ["ios", "--target", ios_local_target, "--local"])
    end)

    ios_project =
      Path.join(
        ios_local_target,
        "native/ios/crosswake_shell/CrosswakeShell.xcodeproj/project.pbxproj"
      )

    assert File.exists?(Path.join(ios_local_target, "native/ios/crosswake_shell/CrosswakeShell/CrosswakeCoordinator.swift"))
    assert File.read!(ios_project) =~ "XCLocalSwiftPackageReference"
    refute File.read!(ios_project) =~ "XCRemoteSwiftPackageReference"

    android_local_target = tmp_dir!("crosswake-shell-local-android")
    capture_io(fn ->
      Mix.Task.reenable(@task)
      Mix.Task.run(@task, ["android", "--target", android_local_target, "--local"])
    end)

    android_app_build = Path.join(android_local_target, "native/android/crosswake_shell/app/build.gradle")
    android_settings = Path.join(android_local_target, "native/android/crosswake_shell/settings.gradle")

    assert File.exists?(Path.join(android_local_target, "native/android/crosswake_shell/app/src/main/java/dev/crosswake/shell/CrosswakeViewModel.kt"))
    assert File.read!(android_settings) =~ "include ':crosswake-shell-core-android'"
    assert File.read!(android_settings) =~ "packages/crosswake-shell-core-android"
    assert File.read!(android_app_build) =~ "implementation project(':crosswake-shell-core-android')"
  end

  defp tmp_dir!(prefix) do
    path = Path.join(System.tmp_dir!(), "#{prefix}-#{System.unique_integer([:positive])}")
    File.rm_rf!(path)
    File.mkdir_p!(path)
    path
  end
end
