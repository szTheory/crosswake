---
phase: 05-packs-native-escape-and-proof-lanes
plan: 06
subsystem: native-shell
tags:
  - native-screen
  - media-capture
  - ios
  - android
  - transfer
dependency_graph:
  requires:
    - 05-03
    - 05-04
  provides:
    - Single typed native media-capture escape contract
    - Generated iOS native capture SwiftUI surface
    - Generated Android native capture activity surface
    - Fail-closed native_screen activation routing with no bounded-web fallback
  affects:
    - lib/crosswake/native_escape/contract.ex
    - lib/crosswake/native_escape/runtime.ex
    - lib/mix/tasks/crosswake.gen.shell.ex
    - test/crosswake/native_escape/contract_test.exs
    - test/mix/tasks/crosswake_gen_shell_test.exs
tech_stack:
  added: []
  patterns:
    - Typed local-capture result plus explicit transfer handoff
    - Manifest-first native_screen activation routing
    - Generated native capture UI with explicit local staging copy
key_files:
  created:
    - lib/crosswake/native_escape/contract.ex
    - lib/crosswake/native_escape/runtime.ex
    - test/crosswake/native_escape/contract_test.exs
    - priv/templates/crosswake/shell/ios/NativeCaptureView.swift.eex
    - priv/templates/crosswake/shell/android/app/src/main/java/dev/crosswake/shell/NativeCaptureActivity.kt.eex
  modified:
    - lib/mix/tasks/crosswake.gen.shell.ex
    - priv/templates/crosswake/shell/ios/CrosswakeShellApp.swift.eex
    - priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex
    - priv/templates/crosswake/shell/ios/ActivationCoordinator.swift.eex
    - priv/templates/crosswake/shell/android/app/build.gradle.eex
    - priv/templates/crosswake/shell/android/app/src/main/AndroidManifest.xml.eex
    - priv/templates/crosswake/shell/android/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt.eex
    - priv/templates/crosswake/shell/android/app/src/main/java/dev/crosswake/shell/MainActivity.kt.eex
    - test/mix/tasks/crosswake_gen_shell_test.exs
decisions:
  - Crosswake exposes one public native escape hatch only in v1: `:native_screen` media capture with explicit local staging and explicit transfer handoff metadata.
  - Generated shells open declared native capture routes directly and deny any bounded-web fallback for those routes.
  - Actual transfer execution remains deferred to 05-07, so 05-06 stops at typed handoff truth and generated native capture surfaces.
metrics:
  completed_at: 2026-05-17T03:16:07Z
  duration: n/a
requirements-completed:
  - PACK-03
---

# Phase 5 Plan 06: Native Media Capture Escape Hatch Summary

Crosswake now ships one typed native media-capture escape hatch and generates owned iOS and Android capture surfaces that stage media locally before explicit transfer handoff.

## Completed Tasks

| Task | Result | Commit |
|------|--------|--------|
| 1 | Added the typed native escape contract and runtime helpers for local capture and explicit transfer completion | `85bb53e`, `c21eadf` |
| 2 | Generated native capture surfaces and native_screen activation routing in iOS and Android shells with fail-closed fallback behavior | `c040d12`, `31ac0c6` |

## Verification

- `mix test test/crosswake/native_escape/contract_test.exs` — PASS
- `mix test test/mix/tasks/crosswake_gen_shell_test.exs` — PASS
- `mix test test/crosswake/native_escape/contract_test.exs test/mix/tasks/crosswake_gen_shell_test.exs` — PASS

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Template Bug] Fix duplicate named argument while wiring Android denial handling**
- **Found during:** Task 2 verification
- **Issue:** The Android activation template picked up a duplicated `manifest = ...` named argument while adding native capture routing, which would have produced invalid generated Kotlin.
- **Fix:** Removed the duplicate and kept the native capture routing change isolated to the declared `native_screen` path.
- **Files modified:** `priv/templates/crosswake/shell/android/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt.eex`
- **Verification:** `mix test test/crosswake/native_escape/contract_test.exs test/mix/tasks/crosswake_gen_shell_test.exs`
- **Commit:** `31ac0c6`

**Total deviations:** 1 auto-fixed.  
**Impact:** Kept the generated Android shell source valid without broadening the plan beyond the single native capture route.

## Known Stubs

- `priv/templates/crosswake/shell/ios/NativeCaptureView.swift.eex`: the `Stage For Transfer` button only marks media as locally staged in UI state. Actual transfer execution remains deferred to Plan 05-07 by design.
- `priv/templates/crosswake/shell/android/app/src/main/java/dev/crosswake/shell/NativeCaptureActivity.kt.eex`: the capture surface stages local state and surfaces the declared transfer handoff copy, but does not execute transfer commands yet. That handoff remains deferred to Plan 05-07.

## Self-Check: PASSED
