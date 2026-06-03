---
phase: 62-diagnostics-support-truth-and-docs
plan: 04
subsystem: docs
tags:
  - docs
  - support-matrix
  - notification
dependency_graph:
  requires:
    - 62-03
  provides:
    - public_support_truth
  affects:
    - guides/support_matrix.md
tech_stack:
  added: []
  patterns:
    - Documentation generated from canonical SupportMatrix definitions
key_files:
  created: []
  modified:
    - guides/support_matrix.md
    - lib/crosswake/support_matrix/renderer.ex
    - test/crosswake/proof/phase59_chimeway_contract_test.exs
    - test/crosswake/support_matrix/renderer_test.exs
    - test/fixtures/proof/phase52_operator_inspection.json
metrics:
  duration: 10m
  tasks_completed: 1
  total_files_changed: 5
requirements-completed: [DIAG-01, DIAG-02]
---

# Phase 62 Plan 04: Public Notification Support Truth

Document the notification support surface constraints and telemetry contracts.

## High-Level Summary
Completed the public documentation for Crosswake's v3.9 notification support. Ensure exact parity between programmatic `SupportMatrix` truths and public `guides/support_matrix.md`. Updated the Markdown generation renderer to include explicit notification support sections, indicating that token binding and notification-open routing are supported, but push delivery guarantees and raw telemetry payloads are strictly deferred or prohibited. Refreshed tests and operator fixtures to align with this updated phrasing.

## Key Decisions
- Extended `Crosswake.SupportMatrix.Renderer` to dynamically embed the notification surface details into `guides/support_matrix.md` instead of making a one-off manual edit that would drift from canonical programmatic output.
- Replaced the outdated v3.6 phrase inside the `Public Non-Claims And Rough Edges` section with the new v3.9 explicit telemetry and token routing stance.

## Deviations from Plan
None. Tests failed initially due to the manual edit of `guides/support_matrix.md` circumventing the canonical generator; this was automatically fixed by moving the text into the `Renderer` logic and updating operator fixtures.

## Threat Flags
None. All actions align exactly with mitigating spoofing threats by making strict telemetry policies public.
