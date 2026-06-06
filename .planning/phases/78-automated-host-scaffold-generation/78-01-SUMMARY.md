---
phase: 78
plan: 01
subsystem: generator
tags:
  - CLI
  - scaffolding
  - cleanup
dependency_graph:
  requires: []
  provides:
    - thin-scaffold-generator
  affects:
    - crosswake.gen.shell
tech_stack:
  added: []
  patterns:
    - strict-option-parsing
    - placeholder-files
key_files:
  created:
    - priv/templates/crosswake/shell/ios/CrosswakeCoordinator.swift.eex
    - priv/templates/crosswake/shell/android/app/src/main/java/dev/crosswake/shell/CrosswakeViewModel.kt.eex
  modified:
    - lib/mix/tasks/crosswake.gen.shell.ex
    - test/mix/tasks/crosswake_gen_shell_test.exs
decisions:
  - Use `strict` OptionParser to ensure `--local` is correctly validated as a safe boolean.
  - Retain `CrosswakeShellApp.swift.eex` and `MainActivity.kt.eex` while removing legacy thick implementations to prepare for external dependencies.
metrics:
  duration: 15m
  completed_date: "2026-06-05"
---

# Phase 78 Plan 01: Generator CLI Task & Template Purge Summary

Updated the `crosswake.gen.shell` Elixir task to support generating thin dependency-driven host projects and purged legacy fat template files.

## Work Completed

- **CLI Options**: Added a `--local` flag to `crosswake.gen.shell` to support local dependency testing, enforcing type safety using strict `OptionParser` boolean mapping (Threat T-78-01 mitigated).
- **Template Purge**: Removed 27 legacy "fat" boilerplate templates (`ActivationCoordinator`, `BridgeChannel`, `PackStore`, etc.) from both iOS and Android scaffold fixtures to eliminate the "eject trap".
- **Placeholder Creation**: Added thin placeholders for `CrosswakeCoordinator.swift.eex` and `CrosswakeViewModel.kt.eex` as the foundational integration points for external SDK dependencies.
- **Test Alignment**: Cleaned up the generator test suite to no longer assert on the presence and content of the deleted files, and introduced validations for the `--local` flag and the new placeholder locations. The test suite passes.

## Known Stubs

- `priv/templates/crosswake/shell/ios/CrosswakeCoordinator.swift.eex` at line 1 - Placeholder for iOS glue layer (planned for future tasks)
- `priv/templates/crosswake/shell/android/app/src/main/java/dev/crosswake/shell/CrosswakeViewModel.kt.eex` at line 1 - Placeholder for Android glue layer (planned for future tasks)

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED
- `lib/mix/tasks/crosswake.gen.shell.ex` contains `--local` and the purged lists.
- 27 legacy `.eex` files removed.
- Tests pass (`mix test test/mix/tasks/crosswake_gen_shell_test.exs`).
- All 3 commits present.
