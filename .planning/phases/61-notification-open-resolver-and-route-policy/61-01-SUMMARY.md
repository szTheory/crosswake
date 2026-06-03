---
phase: 61-notification-open-resolver-and-route-policy
plan: 1
subsystem: Chimeway
tags:
  - contracts
  - denial
  - chimeway
dependency_graph:
  requires: []
  provides:
    - NotificationOpenEvidence
    - OpenResolution
    - Denial subcodes
  affects:
    - Crosswake.Shell.Denial
tech_stack:
  added: []
  patterns:
    - Strict struct definitions without public raw tokens
key_files:
  created:
    - lib/crosswake/companions/chimeway/denial_codes.ex
    - lib/crosswake/companions/chimeway/intent_consumer.ex
    - test/crosswake/shell/denial_test.exs
    - test/crosswake/companions/chimeway/denial_codes_test.exs
  modified:
    - lib/crosswake/shell/denial.ex
    - lib/crosswake/companions/chimeway/contracts.ex
    - test/crosswake/companions/chimeway/contracts_test.exs
decisions: []
metrics:
  duration: 5
  completed_at: 2024-05-18T10:00:00Z
---

# Phase 61 Plan 1: Chimeway Notification Open Evidence Contracts Summary

Defined the notification open evidence contracts and core denial boundaries for Chimeway. Added the `:notification_open_denied` reason to the core `Shell.Denial` reasons. Introduced `NotificationOpenEvidence` and `OpenResolution` structs. Created `Chimeway.DenialCodes` with specific subcodes and detail sanitization to ensure no PII leaks. Defined the `IntentConsumer` behaviour.

## Deviations from Plan
None - plan executed exactly as written.
