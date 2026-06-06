---
phase: 78
plan: 03
subsystem: android-generator
tags:
  - CLI
  - scaffolding
  - kotlin
  - android
dependency_graph:
  requires: ["78-01", "78-02"]
  provides:
    - android-thin-scaffold
  affects:
    - crosswake.gen.shell
tech_stack:
  added: []
  patterns:
    - maven-dependency
    - view-model
key_files:
  created: []
  modified:
    - priv/templates/crosswake/shell/android/app/src/main/java/dev/crosswake/shell/CrosswakeViewModel.kt.eex
    - priv/templates/crosswake/shell/android/app/src/main/java/dev/crosswake/shell/MainActivity.kt.eex
    - priv/templates/crosswake/shell/android/app/src/main/AndroidManifest.xml.eex
    - priv/templates/crosswake/shell/android/app/build.gradle.eex
    - priv/templates/crosswake/shell/android/settings.gradle.eex
    - test/mix/tasks/crosswake_gen_shell_test.exs
decisions:
  - Implement a thin Android scaffold that relies entirely on `crosswake-shell-core-android` via Maven or local project.
  - Simplify `AndroidManifest.xml.eex` to strictly essential permissions and documentation pointers.
metrics:
  duration: 15m
  completed_date: "2026-06-05"
---

# Phase 78 Plan 03: Android Thin Scaffold Generator

Overhauled Android EEx templates to output a thin scaffold that consumes `crosswake-shell-core-android` via Gradle dependencies and uses a dedicated glue layer, while maintaining green tests.

## Work Completed

- **Glue Layer**: Updated `CrosswakeViewModel.kt.eex` to initialize `CrosswakeShell` and observe state changes using `StateFlow`.
- **Root Activity**: Replaced legacy routing logic in `MainActivity.kt.eex` with a minimal view collecting from `CrosswakeViewModel`.
- **Permissions**: Cleaned up `AndroidManifest.xml.eex`, replacing bloated capabilities with a link to `docs.crosswake.dev`.
- **Maven Dependency**: Injected `crosswake-shell-core-android` into the Android project via `build.gradle.eex` and `settings.gradle.eex`, utilizing the `--local` flag to switch between remote Maven artifacts and a local workspace project inclusion.
- **Validation**: Updated test assertions in `crosswake_gen_shell_test.exs` to enforce the new Android template structure. Tests are green.

## Deviations from Plan

Removed the unused `@app_module_name_lower` template assign from `CrosswakeViewModel.kt.eex` and `MainActivity.kt.eex` to prevent warnings during EEx evaluation.

## Self-Check: PASSED
- `CrosswakeViewModel` interacts correctly with the core SDK.
- `AndroidManifest.xml` is thin and secure.
- Tests pass.
- Commits recorded.
