import re

with open("test/mix/tasks/crosswake_gen_shell_test.exs", "r") as f:
    content = f.read()

# Replace ios_app assertions
old_app_assertions = """    assert File.read!(ios_app) =~ "ActivationCoordinator.bundled"
    assert File.read!(ios_app) =~ "onOpenURL"
    assert File.read!(ios_app) =~ "onContinueUserActivity"
    assert File.read!(ios_app) =~ "LiveViewContainerView"
    assert File.read!(ios_app) =~ "NativeCaptureView\""""

new_app_assertions = """    assert File.read!(ios_app) =~ "CrosswakeCoordinator"
    assert File.read!(ios_app) =~ "onOpenURL"
    assert File.read!(ios_app) =~ "bootstrap"
"""
content = content.replace(old_app_assertions, new_app_assertions)

# Replace Info.plist assertions
old_info_assertions = """    assert File.read!(ios_info) =~ "WKAppBoundDomains\""""
new_info_assertions = """    assert File.read!(ios_info) =~ "WKAppBoundDomains"
    refute File.read!(ios_info) =~ "NSCameraUsageDescription"
    assert File.read!(ios_info) =~ "https://docs.crosswake.dev/capabilities"
"""
content = content.replace(old_info_assertions, new_info_assertions)

# Replace project assertions
old_project_assertions = """    assert File.read!(ios_project) =~ "PBXNativeTarget"
    assert File.read!(ios_project) =~ "CrosswakeShellTests\""""
new_project_assertions = """    assert File.read!(ios_project) =~ "PBXNativeTarget"
    assert File.read!(ios_project) =~ "CrosswakeShellTests"
    assert File.read!(ios_project) =~ "XCRemoteSwiftPackageReference"
    refute File.read!(ios_project) =~ "XCLocalSwiftPackageReference\""""
content = content.replace(old_project_assertions, new_project_assertions)

# Replace coordinator assertions
old_coordinator_assertions = """    assert File.exists?(ios_crosswake_coordinator)
    assert File.read!(ios_manifest) =~ "\\\"manifest_schema_version\\\"\"
    assert File.exists?(ios_crosswake_coordinator)\""""
new_coordinator_assertions = """    assert File.exists?(ios_crosswake_coordinator)
    assert File.read!(ios_crosswake_coordinator) =~ "CrosswakeShell(config:"
    assert File.read!(ios_crosswake_coordinator) =~ "bootstrap()"
    assert File.read!(ios_manifest) =~ "\\\"manifest_schema_version\\\"\""""
content = content.replace(old_coordinator_assertions, new_coordinator_assertions)

# Update local assertions
old_local_assertions = """    capture_io(fn ->
      Mix.Task.reenable(@task)
      Mix.Task.run(@task, ["ios", "--target", local_target, "--local"])
    end)
    assert File.exists?(Path.join(local_target, "native/ios/crosswake_shell/CrosswakeShell/CrosswakeCoordinator.swift"))\""""

new_local_assertions = """    capture_io(fn ->
      Mix.Task.reenable(@task)
      Mix.Task.run(@task, ["ios", "--target", local_target, "--local"])
    end)
    assert File.exists?(Path.join(local_target, "native/ios/crosswake_shell/CrosswakeShell/CrosswakeCoordinator.swift"))
    local_project = Path.join(local_target, "native/ios/crosswake_shell/CrosswakeShell.xcodeproj/project.pbxproj")
    assert File.read!(local_project) =~ "XCLocalSwiftPackageReference"
    assert File.read!(local_project) =~ "../../../packages/crosswake-shell-core-ios"
    refute File.read!(local_project) =~ "XCRemoteSwiftPackageReference"
"""
content = content.replace(old_local_assertions, new_local_assertions)

with open("test/mix/tasks/crosswake_gen_shell_test.exs", "w") as f:
    f.write(content)

print("Done updating test")
