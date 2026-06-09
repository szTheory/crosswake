---
phase: "93"
plan: "02"
subsystem: "Android Shell"
tags:
  - native
  - shell
  - telemetry
  - android
dependency_graph:
  requires: ["PROP-01", "PROP-03"]
  provides: ["PROP-05"]
  affects: ["Android LiveViewSession", "ActivationCoordinator"]
tech_stack:
  added: ["WebViewCompat"]
  patterns: ["Document-start JS injection"]
key_files:
  created: []
  modified:
    - "packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/ActivationCoordinator.kt"
    - "examples/android_shell_host/app/src/main/java/dev/crosswake/shell/LiveViewFragment.kt"
    - "examples/android_shell_host/app/src/test/java/dev/crosswake/shell/BridgeChannelTest.kt"
metrics:
  duration_minutes: 5
  completed_tasks: 2
  total_tasks: 2
  completion_date: "2026-06-09"
---

# Phase 93 Plan 02: Android shell threadId propagation

The Android native shell propagates the `thread_id` via HTTP headers on initial page load and via `addDocumentStartJavaScript` to the WebView, ensuring end-to-end telemetry and audit correlation.

## Key Decisions
- **Mint on Cold Start:** `ActivationCoordinator` mints a UUIDv4 `currentThreadId` upon start.
- **Scope to Shell:** Thread ID is kept in memory.
- **Deep Link Override:** Inbound `thread_id` from activation URL replaces the active `thread_id`.
- **Deterministic Injection:** Android race conditions were mitigated by using `WebViewCompat.addDocumentStartJavaScript` instead of `onPageStarted`.

## Deviations from Plan
- None - plan executed exactly as written.

## Self-Check: PASSED
- `ActivationCoordinator.kt` updated to propagate threadId
- `LiveViewFragment.kt` injects `X-Crosswake-Thread-Id` header and document-start JS