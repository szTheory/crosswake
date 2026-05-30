---
phase: 41-gating-doctor-and-support-matrix-truth
fixed_at: 2026-05-30T00:00:00Z
fix_scope: critical_warning
findings_in_scope: 3
fixed: 3
skipped: 0
iteration: 1
status: all_fixed
---

# Phase 41: Code Review Fix Report

**Fixed:** 2026-05-30T00:00:00Z
**Scope:** critical_warning (Critical + Warning)
**Findings in scope:** 3
**Fixed:** 3
**Skipped:** 0
**Status:** all_fixed

## Applied Fixes

### CR-01 — Fixed (`lib/crosswake/doctor/doctor.ex`)

**Commit:** `98f1e53`

Serialized `route.on_unavailable` to a JSON-safe string representation in `gating_advisory_finding/1`. Raw Elixir tuples like `{:fallback_phoenix, :some_route}` are no longer stored verbatim in `check.details`, eliminating the `Protocol.UndefinedError` crash that occurred when `mix crosswake.doctor --json` (or any caller of `JSONFormatter.render/1`) processed a manifest with a fallback-phoenix route.

### WR-01 — Fixed (`lib/crosswake/support_matrix/support_matrix.ex`)

**Commit:** `52b91e0`

Added a catch-all `gate_state_display/1` clause that returns `"unknown(gate_status=...,kill_switch=...)"` for any `Companion.State` pattern not covered by the existing typed clauses. This prevents `FunctionClauseError` crashes when a companion introduces a new `gate_status` or `kill_switch_status` variant before the core package is updated.

### WR-02 — Fixed (`test/crosswake/proof/phase41_gating_doctor_test.exs`)

**Commit:** `88bb2dc`

Added `assert report.manifest != nil` with a descriptive failure message before the gating findings filter in SC#1f. This prevents the test from passing vacuously when `MinimalRouter` fails to compile — previously a compilation failure returned `manifest: nil` and an empty findings list, causing the assertion to pass while no gating logic was actually exercised.

## Out of Scope

### IN-01 — Skipped (info, outside fix_scope)

`Application.get_env(:crosswake, :companions)` read twice per `Doctor.run/1` call. Low-priority cleanup; does not affect correctness. Excluded by `fix_scope: critical_warning`.

---

_Fixed: 2026-05-30T00:00:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Scope: critical_warning_
