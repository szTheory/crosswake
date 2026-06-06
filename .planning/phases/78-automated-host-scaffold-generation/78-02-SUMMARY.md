---
phase: 78
plan: 02
subsystem: ios-generator
tags:
  - CLI
  - scaffolding
  - swift
  - ios
dependency_graph:
  requires: ["78-01"]
  provides:
    - ios-thin-scaffold
  affects:
    - crosswake.gen.shell
tech_stack:
  added: []
  patterns:
    - spm-dependency
    - state-object
key_files:
  created: []
  modified:
    - priv/templates/crosswake/shell/ios/CrosswakeCoordinator.swift.eex
    - priv/templates/crosswake/shell/ios/CrosswakeShellApp.swift.eex
    - priv/templates/crosswake/shell/ios/Info.plist.eex
    - priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex
    - test/mix/tasks/crosswake_gen_shell_test.exs
decisions:
  - Implement a thin iOS scaffold that relies entirely on `crosswake-shell-core-ios` via SPM.
  - Simplify `Info.plist.eex` to strictly essential permissions and documentation pointers.
metrics:
  duration: 10m
  completed_date: "2026-06-05"
---

# Phase 78 Plan 02: iOS Thin Scaffold Generator

Overhauled iOS EEx templates to output a thin scaffold that consumes `crosswake-shell-core-ios` via SPM and uses a dedicated glue layer, while maintaining green tests.

## Work Completed

- **Glue Layer**: Updated `CrosswakeCoordinator.swift.eex` to initialize `CrosswakeShell` and observe state changes using `@Published`.
- **Root App**: Replaced legacy routing logic in `CrosswakeShellApp.swift.eex` with a minimal view binding to `@StateObject var coordinator`.
- **Permissions**: Cleaned up `Info.plist.eex`, replacing bloated capabilities with a link to `docs.crosswake.dev`.
- **SPM Dependency**: Injected `crosswake-shell-core-ios` into the Xcode project, utilizing the `--local` flag to switch between remote and local resolution paths.
- **Validation**: Updated test assertions in `crosswake_gen_shell_test.exs` to enforce the new iOS template structure. Tests are green.

## Deviations from Plan

None.

## Self-Check: PASSED
- `CrosswakeCoordinator` interacts correctly with the core SDK.
- `Info.plist` is thin and secure.
- Tests pass.
- Commits recorded.
