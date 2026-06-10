---
phase: 95
plan: "01"
subsystem: operator-surface
tags:
  - support-matrix
  - doctor
  - threadline
  - audit-ledger
  - pii-safety
dependency_graph:
  requires:
    - "91-01: Crosswake.Threadline.Telemetry (event_names, metadata_keys, forbidden_metadata_keys)"
    - "94-01: Crosswake.Audit.Ledger struct and gen.audit contract"
  provides:
    - "Crosswake.SupportMatrix.audit_ledger_support_truth/0 — threadline posture truth"
    - "Crosswake.Doctor phase_95_threadline_findings — plug/ledger/PII/schema-drift checks"
  affects:
    - "lib/crosswake/support_matrix/support_matrix.ex"
    - "lib/crosswake/doctor/doctor.ex"
tech_stack:
  added: []
  patterns:
    - "@module_attribute compile-time truth map (mirrors @notification_support_truth pattern)"
    - "Application.get_env(:crosswake, :audit_ledger) for runtime-testable schema config"
    - "Ecto schema reflection via schema.__schema__(:fields)"
key_files:
  created: []
  modified:
    - "lib/crosswake/support_matrix/support_matrix.ex"
    - "test/crosswake/support_matrix/support_matrix_test.exs"
    - "lib/crosswake/doctor/doctor.ex"
    - "test/crosswake/doctor/doctor_test.exs"
decisions:
  - "Used @module_attribute pattern (mirrors @notification_support_truth) for audit_ledger_support_truth — compile-time truth, accessor function"
  - "phase_95_threadline_findings/2 accepts nil install_manifest guard (mirrors phase_62 pattern)"
  - "PII check intersects schema fields with forbidden_metadata_keys from SupportMatrix truth (not hardcoded list) — keeps parity with telemetry contract"
  - "Ledger schema check uses @canonical_ledger_columns module attribute matching LEDG-02 15-column spec"
  - "Audit ledger schema config read as Application.get_env(:crosswake, :audit_ledger) at runtime so test fixtures can use put_env"
metrics:
  duration: "~6 minutes"
  completed: "2026-06-10"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 4
---

# Phase 95 Plan 01: Support Matrix Truth and Doctor Findings Summary

**One-liner:** Threadline audit ledger support truth (`@audit_ledger_support_truth`) and four doctor findings (plug missing, unconfigured, PII forbidden field, schema drift) exposing honest ephemeral/durable posture for operator inspection.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Add Support Matrix Truth for Audit Ledger | 865ca1e | lib/crosswake/support_matrix/support_matrix.ex, test/crosswake/support_matrix/support_matrix_test.exs |
| 2 | Implement Doctor Findings for Threadline | 932e77f | lib/crosswake/doctor/doctor.ex, test/crosswake/doctor/doctor_test.exs |

## What Was Built

### Task 1: @audit_ledger_support_truth (OPER-02)

Added `@audit_ledger_support_truth` module attribute to `Crosswake.SupportMatrix` following the `@notification_support_truth` pattern. The truth map contains:

- `surface`: `"threadline audit ledger"`
- `proof_class`: `:advisory`
- `action_class`: `"operator_surface"`
- `docs_anchor`: `"guides/threadline.md"`
- `ephemeral_posture`: `:supported`, `durable_posture`: `:supported`
- `telemetry`: References `Crosswake.Threadline.Telemetry.event_names/0`, `metadata_keys/0`, and `forbidden_metadata_keys/0` (compile-time resolution ensures parity)
- `deferred`: `[:crosswake_dashboard, :hash_chain_verify_task]`
- `posture`: Honest non-APM, non-replay posture statement

Exported via `def audit_ledger_support_truth, do: @audit_ledger_support_truth`. 10 tests added covering surface, proof_class, telemetry parity, deferred items, and posture content.

### Task 2: phase_95_threadline_findings/2 (OPER-03)

Added `phase_95_threadline_findings/2` to `Crosswake.Doctor.run/1` (invoked after phase_62, before phase_65 in the findings pipeline). Emits four findings:

1. **`threadline.plug_missing` (:advisory)** — Reads the router file from `install_manifest.router_path`. If `"plug Crosswake.Plug.Threadline"` is absent, advises the operator to add it.

2. **`threadline.ledger_not_configured` (:advisory)** — Reads `Application.get_env(:crosswake, :audit_ledger)`. If `nil`, signals ephemeral-only posture and points to `mix crosswake.gen.audit`.

3. **`threadline.pii_forbidden_field_present` (:error)** — When audit_ledger is configured with a loaded schema module, reflects on `schema.__schema__(:fields)` and intersects with `SupportMatrix.audit_ledger_support_truth() |> hd() |> get_in([:telemetry, :forbidden_metadata_keys])`. Reports exact offending keys and schema module name (D-03).

4. **`threadline.ledger_schema_drift` (:warning)** — Checks all 15 canonical LEDG-02 columns (`[:thread_id, :correlation_id, :route_id, :actor_ref, :actor_kind, :event_class, :event_type, :outcome, :provenance, :occurred_at, :recorded_at, :idempotency_key, :metadata, :row_hash, :prev_hash]`). Reports missing columns by name.

5 tests added: plug_missing advisory fires without plug, does not fire with plug, ledger_not_configured advisory fires with no config, pii_forbidden_field_present error fires with email field in schema, ledger_schema_drift warning fires when 3 columns missing.

## Test Results

- **Support matrix tests:** 52 pass, 0 fail (includes 10 new tests for audit_ledger_support_truth)
- **Doctor tests:** 34 pass, 2 fail (2 pre-existing failures unrelated to this plan: `crosswake_version == "0.1.0"` hardcoded against "0.1.2" and a bridge posture format assertion — both failures existed before this plan)

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. All data flows from compile-time constants in `Crosswake.Threadline.Telemetry` and runtime `Application.get_env`.

## Threat Flags

None. No new network endpoints, auth paths, or external interfaces introduced. The doctor findings are read-only introspection over existing module attributes and Ecto schema reflection.

## Self-Check: PASSED
