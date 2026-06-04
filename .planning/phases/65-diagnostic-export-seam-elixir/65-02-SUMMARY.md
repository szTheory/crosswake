---
phase: 65-diagnostic-export-seam-elixir
plan: "02"
subsystem: support-matrix-doctor
tags:
  - diagnostic-export
  - support-matrix
  - doctor
  - advisory-finding
  - readiness-truth
  - tdd
dependency-graph:
  requires:
    - "Phase 65-01 — Crosswake.Shell.DiagnosticExport (allowed_keys/0 + forbidden_keys/0)"
    - "lib/crosswake/companions/chimeway/telemetry.ex — canonical forbidden-key pattern"
    - "lib/crosswake/support_matrix/support_matrix.ex — @notification_support_truth shape"
    - "lib/crosswake/doctor/doctor.ex — phase_62_notification_findings structural model"
  provides:
    - "SupportMatrix.diagnostic_export_support_truth/0 — readiness truth accessor (D-16/D-17)"
    - "Doctor phase_65_diagnostic_export_findings/0 — unconditional :advisory finding (D-18)"
    - "finding code diagnostic_export.contract_shipped wired into Doctor.run/1 pipeline"
  affects:
    - "Phase 65-03 — proof lane asserts support-truth + doctor finding present + non-overclaiming"
    - "Phase 67 — readiness truth will be promoted when native transport ships"
    - "Phase 69 — docs-contract parity gate references diagnostic_export_support_truth/0"
tech-stack:
  added: []
  patterns:
    - "@diagnostic_export_support_truth mirrors @notification_support_truth shape exactly (D-16)"
    - "posture string three-way separation: shipped-contract / deferred-transport / host-not-a-service (D-17)"
    - "phase_65_diagnostic_export_findings/0 unconditional (no manifest arg) — mirrors phase_62 structure without conditional gate (D-18)"
    - "TDD: RED commit (test file) then GREEN commit (implementation) for both tasks"
key-files:
  created: []
  modified:
    - lib/crosswake/support_matrix/support_matrix.ex
    - lib/crosswake/doctor/doctor.ex
    - test/crosswake/support_matrix/support_matrix_test.exs
    - test/crosswake/doctor/doctor_test.exs
decisions:
  - "D-16: @diagnostic_export_support_truth mirrors @notification_support_truth; proof_class: :merge_blocking; authority_source: :host_configured_endpoint; delivery_supported: false"
  - "D-17: posture string separates shipped-contract / deferred-native-transport / host-owns-data-not-a-service (exact locked wording)"
  - "D-18: One :advisory finding code diagnostic_export.contract_shipped fires unconditionally; message excludes crash-reporting-service (seam language stays in SupportMatrix posture)"
metrics:
  duration: "196 seconds (~3 minutes)"
  completed_date: "2026-06-04"
  tasks_completed: 2
  files_created: 0
  files_modified: 4
requirements-completed:
  - DIAG-04
---

# Phase 65 Plan 02: SupportMatrix Truth + Doctor Advisory Finding Summary

## One-liner

`@diagnostic_export_support_truth` readiness truth + unconditional `:advisory` doctor finding `"diagnostic_export.contract_shipped"` with non-overclaiming message and host-owned-endpoint detail.

## What Was Built

### Task 1: `@diagnostic_export_support_truth` + accessor (SupportMatrix)

Added `@diagnostic_export_support_truth` module attribute immediately after `@notification_support_truth`, mirroring its shape exactly (D-16):

- `surface: "diagnostic export envelope contract"`
- `proof_class: :merge_blocking` (allowlist proof is merge-blocking, not just advisory)
- `action_class: "shell_native"`
- `docs_anchor: "guides/capabilities.md#diagnostic-export"`
- `delivery_supported: false`
- `telemetry` sub-map: `status: :shipped`, `event_names: []`, `metadata_keys: DiagnosticExport.allowed_keys()`, `forbidden_metadata_keys: DiagnosticExport.forbidden_keys()`, `authority_source: :host_configured_endpoint`, `proof_class: :merge_blocking`
- `deferred: [:native_diagnostic_export, :metrickit_capture, :application_exit_info_capture]`
- `posture:` — exact D-17 three-way separation string: "Diagnostics-export envelope and sanitize contract are shipped and merge-blocking allowlist proof is enforced; native MetricKit/ApplicationExitInfo transport is not shipped until Phase 67; the host owns the endpoint and the data — Crosswake is not a crash-reporting service."

Added `@spec diagnostic_export_support_truth() :: [map()]` + `def diagnostic_export_support_truth, do: @diagnostic_export_support_truth` immediately after `notification_support_truth/0` (same `@spec` + single-expression style).

The accessor is NOT wired into `canonical/1` — it is a standalone projection for doctor + proof.

### Task 2: `phase_65_diagnostic_export_findings/0` + run/1 wiring (Doctor)

Added private `phase_65_diagnostic_export_findings/0` after `phase_62_notification_findings`:

- No manifest argument, no conditional gate — fires unconditionally (contract is core, D-18)
- Reads truth via `SupportMatrix.diagnostic_export_support_truth() |> List.first(%{})`
- Emits one `check/6` call: `check(:advisory, "diagnostic_export.contract_shipped", "diagnostic_export_posture", message, hint, details)`
- Message: describes shipped envelope + merge-blocking allowlist proof — DOES NOT contain "crash-reporting service" (seam language stays in SupportMatrix posture per D-18)
- Hint: directs operator to host-owned endpoint responsibility and Phase 67 native-transport deferral
- Details: `delivery_supported: false`, `deferred:` (3-atom list), `authority_source: :host_configured_endpoint`, `proof_class: :merge_blocking`, `forbidden_metadata_keys:` from telemetry sub-map

Wired into `run/1`: `phase_65_findings = phase_65_diagnostic_export_findings()` after `phase_62_findings` line; `phase_65_findings` appended to accumulation list before `publish_findings`.

## Test Coverage

### Task 1 — `test/crosswake/support_matrix/support_matrix_test.exs` (12 new tests)

- `diagnostic_export_support_truth/0` returns non-empty list
- `delivery_supported: false`
- deferred list contains all three atoms + exactly those three atoms
- `telemetry.authority_source == :host_configured_endpoint`
- `telemetry.proof_class == :merge_blocking`
- `proof_class == :merge_blocking`
- posture contains "not a crash-reporting service"
- posture contains "Phase 67"
- posture contains "host"
- `telemetry.forbidden_metadata_keys == DiagnosticExport.forbidden_keys()`
- `telemetry.metadata_keys == DiagnosticExport.allowed_keys()`

### Task 2 — `test/crosswake/doctor/doctor_test.exs` (6 new tests)

- Exactly one finding with code `diagnostic_export.contract_shipped`
- Finding has severity `:advisory`
- Finding fires unconditionally (no notification routes present)
- Finding message does NOT contain "crash-reporting service"
- Finding details carry `delivery_supported: false`
- Finding details carry 3-atom deferred list + `authority_source: :host_configured_endpoint`

## Verification Results

```
mix compile --warnings-as-errors  → clean (0 warnings)
mix test test/crosswake/support_matrix/  → 52 tests, 0 failures
mix test test/crosswake/doctor/  → 45 tests, 0 failures
diagnostic_export_support_truth/0 returns [{...}] with delivery_supported: false
entry.posture =~ "not a crash-reporting service" → true
Doctor.run/1 includes :advisory finding code "diagnostic_export.contract_shipped" → true
finding.message =~ "crash-reporting service" → false (non-overclaim)
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test for unconditional firing adjusted**

- **Found during:** Task 2 GREEN
- **Issue:** Test `"the finding fires unconditionally even with empty opts (no manifest path)"` called `Doctor.run(cwd: target)` without `route_source`, which triggers `nil.__routes__/0` crash in `router_and_policy_findings/2` before reaching the finding accumulation.
- **Fix:** Replaced the "empty opts" invocation with a valid `route_source: RouterFixtures.ManagedRouter` invocation that has no notification routes. The test still verifies the unconditional nature (finding is present even with no notification-related routes) while using a code path that doesn't crash.
- **Files modified:** `test/crosswake/doctor/doctor_test.exs`
- **Commit:** d16eae7

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced at trust boundaries.

T-65-05 (Spoofing/misrepresentation via SupportMatrix): Mitigated — `delivery_supported: false`, `authority_source: :host_configured_endpoint`, all 3 deferred atoms present, posture contains "not a crash-reporting service" clause.

T-65-06 (Spoofing/misrepresentation via Doctor finding): Mitigated — severity `:advisory` (informational), message excludes "crash-reporting service" (seam language stays in SupportMatrix posture).

T-65-SC (HTTP dep tamper): Not applicable — no dependencies added in this plan.

## Known Stubs

None — all functionality is fully implemented. The `delivery_supported: false` and `deferred:` list are intentional posture declarations (not stubs); they reflect the Phase 65 shipped-contract-not-yet-native-transport state per D-16/D-17.

## Self-Check: PASSED

- `lib/crosswake/support_matrix/support_matrix.ex` modified with `@diagnostic_export_support_truth`: FOUND
- `lib/crosswake/doctor/doctor.ex` modified with `phase_65_diagnostic_export_findings/0`: FOUND
- RED commit Task 1 `acd1536` exists: FOUND
- GREEN commit Task 1 `9e6a9f1` exists: FOUND
- RED commit Task 2 `65432ef` exists: FOUND
- GREEN commit Task 2 `d16eae7` exists: FOUND
- `mix compile --warnings-as-errors` clean: PASSED
- 52 support_matrix tests, 0 failures: PASSED
- 45 doctor tests, 0 failures: PASSED
- `diagnostic_export_support_truth/0` returns non-empty list with `delivery_supported: false`: PASSED
- posture contains "not a crash-reporting service": PASSED
- Doctor finding `"diagnostic_export.contract_shipped"` with `:advisory` severity fires unconditionally: PASSED
- Finding message free of "crash-reporting service": PASSED
