# Phase 80 Validation

## Phase Goal
The iOS and Android host projects (demo apps) integrate the Crosswake standalone dependencies via SPM/Maven, removing all generated `ActivationCoordinator` or `BridgeChannel` source code, and leverage modern native UI stacks (SwiftUI, Jetpack Compose).

## Validation Steps

1. **Android Maven Consumption (SETUP-01, D-01, D-02):**
   - Verify `examples/android_shell_host/app/build.gradle` contains `dev.crosswake:shell-core-android:0.1.0`.

2. **iOS SPM Consumption (SETUP-01, D-01, D-02):**
   - Verify `examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj` links the `crosswake-shell-core-ios` remote package.

3. **Zero Generated Sources (SETUP-02, D-03):**
   - Verify `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt` is deleted.
   - Verify `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt` is deleted.
   - Verify `examples/ios_shell_host/CrosswakeShell/ActivationCoordinator.swift` is deleted.
   - Verify `examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift` is deleted.

4. **Modern UI Stacks (D-04):**
   - Verify `MainActivity.kt` uses Jetpack Compose (`setContent`).
   - Verify `CrosswakeShellApp.swift` uses SwiftUI.

## Execution
Run automated checks:
```bash
grep "shell-core-android" examples/android_shell_host/app/build.gradle
grep -i "crosswake-shell-core-ios" examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj
test ! -f examples/android_shell_host/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt
test ! -f examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt
test ! -f examples/ios_shell_host/CrosswakeShell/ActivationCoordinator.swift
test ! -f examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift
grep "setContent" examples/android_shell_host/app/src/main/java/dev/crosswake/shell/MainActivity.kt
grep -i "SwiftUI" examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift
xcodebuild -project examples/ios_shell_host/CrosswakeShell.xcodeproj build
```