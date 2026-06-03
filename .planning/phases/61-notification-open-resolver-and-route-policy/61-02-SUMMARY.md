---
phase: 61-notification-open-resolver-and-route-policy
plan: 2
subsystem: routing
tags:
  - dsl
  - manifest
  - compatibility
  - notifications
requires:
  - OPEN-01
  - OPEN-03
provides:
  - 61-02-notification-open-opt-in
affects:
  - lib/crosswake/policy/schema.ex
  - lib/crosswake/policy/route.ex
  - lib/crosswake/manifest/types.ex
  - lib/crosswake/manifest/builder.ex
  - lib/crosswake/compatibility/compatibility.ex
tech-stack:
  added: []
  patterns: []
key-files:
  created: []
  modified:
    - lib/crosswake/policy/schema.ex
    - lib/crosswake/policy/route.ex
    - lib/crosswake/manifest/types.ex
    - lib/crosswake/manifest/builder.ex
    - lib/crosswake/compatibility/compatibility.ex
decisions:
  - D-14: Implement notification_open to safely opt-in to push entry.
  - D-15: Default notification_open to nil/false for fail-closed security.
  - D-17: RouteGate will return `notification_open_denied` when notification source hits a non-opt-in route.
metrics:
  duration: 1m
  tasks-completed: 3
  tasks-total: 3
  files-modified: 5
  completed-date: 2024-05-18T00:00:00Z
---

# Phase 61 Plan 2: Notification Open Opt-In Summary

## Overview
Implemented explicit route opt-in for notification opens via the `notification_open` attribute in the policy DSL, embedding this attribute in the manifest, and enforcing it in the compatibility pipeline.

## Implementation Details
- Extended `Crosswake.Policy.Schema` to validate `notification_open` accepting `true` or a keyword list `[actions: [atom()]]`, and failing otherwise.
- Modified `Crosswake.Policy.Route` struct and `Crosswake.Manifest.Types` to accommodate this new field.
- Updated `Crosswake.Manifest.Builder` to correctly transfer `notification_open` settings to materialized route entries.
- Added a `validate_notification_open` step to `Crosswake.Compatibility`, returning `notification_open_denied` for routes missing opt-in when activation source is a notification.

## Deviations from Plan
None - plan executed exactly as written.

## Security Posture
Defaults are correctly fail-closed. Explicit validation prevents unexpected elevation of privilege when navigating via external deep links.

## Self-Check: PASSED
All required commits and file modifications correspond properly to the plan objectives.