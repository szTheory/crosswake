---
phase: 62-diagnostics-support-truth-and-docs
plan: 01
subsystem: diagnostics
tags: [telemetry, support-truth, notification]
dependency_graph:
  requires: ["DIAG-02"]
  provides: ["Chimeway telemetry open events and missing metadata", "Notification Support Truth enhancements"]
  affects: ["lib/crosswake/support_matrix/support_matrix.ex", "lib/crosswake/companions/chimeway/telemetry.ex"]
tech_stack:
  added: []
  patterns: ["telemetry-evidence", "support-matrix"]
key_files:
  created: []
  modified:
    - lib/crosswake/support_matrix/support_matrix.ex
    - lib/crosswake/companions/chimeway/telemetry.ex
    - test/crosswake/companions/chimeway/telemetry_test.exs
decisions:
  - "Chimeway telemetry strictly defines notification.open.* events and restricted metadata keys."
  - "SupportMatrix exports Chimeway telemetry constraints and declares token/open routing as fully supported while push delivery is deferred."
metrics:
  duration: 1m
  completed_date: "2026-06-03"
---

# Phase 62 Plan 01: Diagnostics, Support Truth, And Docs Summary

Update `Chimeway.Telemetry` to include strict open-routing events/metadata and update `SupportMatrix` to broadcast these contracts along with the accurate support posture.

## Key Changes

1.  **Added Notification Open Telemetry Events**: Updated `Chimeway.Telemetry` to expose `[:crosswake, :notification, :open, :received]`, `[:crosswake, :notification, :open, :resolved]`, and `[:crosswake, :notification, :open, :denied]`. Also added `:route_id`, `:action_ref`, and `:denial_code` to `@metadata_keys`.
2.  **Updated SupportMatrix Notification Truth**: Exported `Chimeway.Telemetry` event names and metadata constraints in the `SupportMatrix.notification_support_truth/0`. Clarified in the `posture` that token binding and open routing are fully supported/resolvable, but APNs/FCM delivery execution remains deferred.

## Deviations from Plan

None - plan executed exactly as written.

## Threat Flags

None.

## Known Stubs

None.

## Self-Check: PASSED
- `lib/crosswake/companions/chimeway/telemetry.ex` was updated.
- `lib/crosswake/support_matrix/support_matrix.ex` was updated.
- Commits track `feat(62-01)`.
