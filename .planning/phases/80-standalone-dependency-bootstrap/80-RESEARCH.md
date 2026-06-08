<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Update the existing `examples/ios_shell_host` and `examples/android_shell_host` demo projects.
- **D-02:** Use the most recent published standalone packages for SPM/Maven instead of local file paths or bleeding-edge branches, ensuring the demos prove the released artifacts.
- **D-03:** The native hosts should not contain any generated `ActivationCoordinator` or `BridgeChannel` source code. They must rely on the standalone dependencies.
- **D-04:** Leverage modern native UI stacks (SwiftUI, Jetpack Compose) within the demo apps where possible to demonstrate modern consumption.

### the agent's Discretion
None explicitly specified in CONTEXT.md. (Will use conventions for package definitions).

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SETUP-01 | Demo apps (iOS and Android) must consume Crosswake via standalone SPM and Maven Central dependencies (no local project references). | Android dependency coordinate identified (`dev.crosswake:shell-core-android:0.1.0`). iOS SPM repository URL identified (`https://github.com/crosswake/crosswake-shell-core-ios.git`). |
| SETUP-02 | Demo apps must implement a thin host project structure with zero generated `ActivationCoordinator` or `BridgeChannel` source files. | Files to delete identified in `examples/*_shell_host`. Modifying `build.gradle` and `project.pbxproj` is required to transition to dependencies. |
</phase_requirements>

# Phase 80: Standalone Dependency Bootstrap - Research

**Researched:** 2026-06-08
**Domain:** iOS/Android Dependency Management & Build Systems
**Confidence:** HIGH

## Summary

The objective is to upgrade the Android and iOS demo apps (`examples/android_shell_host` and `examples/ios_shell_host`) to act as "adoption evidence" for the Crosswake v5.0 standalone distribution. This involves removing all locally generated infrastructure code (`ActivationCoordinator`, `BridgeChannel`, etc.) and instead wiring up standard dependency managers (Gradle/Maven for Android, SPM for iOS) to fetch the published core libraries.

**Primary recommendation:** Delete local source files for `ActivationCoordinator` and `BridgeChannel` from both native demo apps. Update Android `build.gradle` to pull `dev.crosswake:shell-core-android:0.1.0` and iOS `project.pbxproj` to resolve the SPM package at `https://github.com/crosswake/crosswake-shell-core-ios.git`. 

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Crosswake Core Logic | Native App | API / Backend | Native app fetches published binary (AAR / SPM Package), rather than maintaining the code itself. |
| Dependency Resolution | Native App | — | Android uses Gradle fetching from Maven Central. iOS uses `xcodebuild` / Xcode resolving via Swift Package Manager. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `shell-core-android` | `0.1.0` | Crosswake Android Core | Official standalone release replacing generated source code. |
| `crosswake-shell-core-ios` | `0.1.0` | Crosswake iOS Core | Official SPM package replacing generated source code. |

**Installation (Android):**
```gradle
dependencies {
  implementation 'dev.crosswake:shell-core-android:0.1.0'
}
```

**Installation (iOS):**
Add SPM remote package to `CrosswakeShell.xcodeproj/project.pbxproj`:
- URL: `https://github.com/crosswake/crosswake-shell-core-ios.git`
- Requirement: Exact Version `0.1.0`
- Target Product: `CrosswakeShellCore`

## Package Legitimacy Audit

> **Required** whenever this phase installs external packages.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `dev.crosswake:shell-core-android` | Maven Central | [ASSUMED] | [ASSUMED] | [ASSUMED] | [ASSUMED] | Approved |
| `crosswake-shell-core-ios` | SwiftPM | [ASSUMED] | [ASSUMED] | `github.com/crosswake/crosswake-shell-core-ios` | [ASSUMED] | Approved |

*If slopcheck was unavailable at research time, all packages above are tagged `[ASSUMED]` and the planner must gate each install behind a `checkpoint:human-verify` task.*

## Architecture Patterns

### Recommended Project Structure (Post-Migration)
```
examples/
├── android_shell_host/
│   ├── app/build.gradle      # Updated to include Maven dependency
│   └── app/src/.../shell/    # (ActivationCoordinator/BridgeChannel removed)
└── ios_shell_host/
    ├── CrosswakeShell.xcodeproj/project.pbxproj  # Updated to link SPM remote pkg
    └── CrosswakeShell/       # (ActivationCoordinator.swift/BridgeChannel.swift removed)
```

### Pattern 1: Standalone Maven Consumption
**What:** Replacing local source files with a remote Maven artifact in Android Gradle projects.
**When to use:** To prove production adoption paths.
**Example:**
```groovy
dependencies {
    // Other dependencies
    implementation 'dev.crosswake:shell-core-android:0.1.0'
}
```

### Pattern 2: Xcode SPM Consumption via Script
**What:** Updating Xcode project using standard Apple mechanisms (or `pbxproj` patches) instead of generating the source into the project tree.
**When to use:** Migrating iOS hosts to standalone.
**Example:**
There is a utility script `fix_pbxproj.py` in the root repository that shows exactly how to cleanly inject the SPM package into a `pbxproj` file. It can be adapted to manipulate the actual demo host `project.pbxproj`.

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None | None |
| Live service config | None | None |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts | Xcode DerivedData, Gradle build caches / daemon | Trigger clean builds (`xcodebuild clean`, `./gradlew clean`) after removing files to ensure old sources are completely flushed. |

## Common Pitfalls

### Pitfall 1: Leaving Stale References in `project.pbxproj`
**What goes wrong:** The iOS project fails to build because `ActivationCoordinator.swift` is deleted from the filesystem but still referenced in the Xcode project's `PBXBuildFile` section.
**Why it happens:** Deleting files via `rm` doesn't remove them from the Xcode project registry.
**How to avoid:** Ensure the `project.pbxproj` is fully scrubbed of old file references.
**Warning signs:** Build errors indicating "Missing file: ActivationCoordinator.swift".

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `xcodebuild` | iOS compilation | ✓ | Xcode 26.5 | — |
| `java` / JRE | Android Gradle build | ✗ | — | Skip compilation, do human check |
| `gradle` | Android compilation | ✗ | — | Skip compilation, do human check |

**Missing dependencies with fallback:**
- Java and Gradle are missing on the system. The planner should structure tasks to modify the project correctly, but compilation verification might need to be gracefully degraded to a manual check or skipped if the system cannot run `./gradlew`.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Mix / ExUnit |
| Config file | `mix.exs` |
| Quick run command | `mix test test/crosswake/doctor/doctor_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SETUP-01 | Maven & SPM dependency presence in configuration files | unit/regex | `grep "shell-core-android" examples/android_shell_host/app/build.gradle` | ✅ Wave 0 |
| SETUP-02 | Generated source files are removed from project trees | unit | `[ ! -f examples/ios_shell_host/CrosswakeShell/ActivationCoordinator.swift ]` | ✅ Wave 0 |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/80-standalone-dependency-bootstrap/80-CONTEXT.md` - Phase bounds
- `priv/templates/crosswake/shell/android/app/build.gradle.eex` - Reference template for Gradle dependencies
- `fix_pbxproj.py` - Reference pattern for how Crosswake manipulates SPM settings

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Extracted directly from existing templating structure
- Architecture: HIGH - Dictated by `REQUIREMENTS.md` SETUP-01 and SETUP-02
- Pitfalls: HIGH - Known iOS compilation gotcha

**Research date:** 2026-06-08
**Valid until:** 2026-07-08