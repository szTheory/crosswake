---
phase: 121-canonical-contract-source
plan: "03"
subsystem: android-shell-core
tags: [kotlin, android, manifest-parsing, fail-closed, canon-05]
dependency_graph:
  requires: []
  provides: [CANON-05]
  affects: [ActivationFixtures.loadManifest, ShellManifest.nativeRuntimeVersion]
tech_stack:
  added: []
  patterns: [fail-closed-error, kotlin-elvis-throw]
key_files:
  created: []
  modified:
    - packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/ActivationCoordinator.kt
decisions:
  - "CANON-05 / D-08: Replace ?: \"1.0.0\" silent default with kotlin error() at line 594; keeps ShellManifest.nativeRuntimeVersion non-nullable String"
metrics:
  duration: "~1 minute"
  completed: "2026-06-20"
  tasks_completed: 1
  files_modified: 1
status: complete
---

# Phase 121 Plan 03: Remove Native Runtime Silent Fallback Summary

Silent `?: "1.0.0"` fallback removed from `ActivationFixtures.loadManifest`; native now reads `native_runtime_version` from the manifest and fails closed with `error(...)` when the compatibility block is absent.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Remove the silent native-runtime fallback; fail closed | a05bb62 | ActivationCoordinator.kt |

## What Was Built

Single-line edit in `ActivationFixtures.loadManifest` at `ActivationCoordinator.kt:594`:

**Before:**
```kotlin
val nativeRuntimeVersion = compatibilityJson?.getString("native_runtime_version") ?: "1.0.0"
```

**After:**
```kotlin
val nativeRuntimeVersion = compatibilityJson?.getString("native_runtime_version")
    ?: error("crosswake_manifest.json is missing native_runtime_version in the compatibility block")
```

The fail-closed error message is: `"crosswake_manifest.json is missing native_runtime_version in the compatibility block"`

`ShellManifest.nativeRuntimeVersion` remains `val nativeRuntimeVersion: String` (non-nullable) at line 98 — type contract unchanged. The `ShellManifest(nativeRuntimeVersion = nativeRuntimeVersion)` assignment at line 614 still type-checks because `error(...)` returns `Nothing` in Kotlin, satisfying the non-null `String` type constraint at the use site.

## Verification Results

- `grep -n '?: "1.0.0"' ActivationCoordinator.kt` — empty (CANON-05 satisfied)
- `native_runtime_version` is read from `compatibilityJson?.getString(...)` at line 594-595
- `val nativeRuntimeVersion: String` still present at lines 51, 98, 138 (ShellManifest and related types)
- Diff is scoped to lines 594-595 only; no other lines changed

## Deviations from Plan

None — plan executed exactly as written. The diff is one statement at line 594 expanded to two lines (the expression plus its `?: error(...)` branch). No other changes.

## Threat Mitigations Applied

| Threat ID | Mitigation |
|-----------|------------|
| T-121-05 | Silent `1.0.0` assumption removed; absent compatibility block now throws, preventing a malformed/missing manifest from masquerading as a valid 1.0.0 runtime (CANON-05 / D-08) |

## Self-Check: PASSED

- File exists: FOUND `/Users/jon/projects/crosswake/packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/ActivationCoordinator.kt`
- Commit exists: FOUND `a05bb62`
- No `?: "1.0.0"` in file: CONFIRMED
- `error(...)` fail-closed present: CONFIRMED at line 595
- `ShellManifest.nativeRuntimeVersion` still non-nullable `String`: CONFIRMED
