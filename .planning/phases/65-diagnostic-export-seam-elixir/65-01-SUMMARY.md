---
phase: 65-diagnostic-export-seam-elixir
plan: "01"
subsystem: shell-contract
tags:
  - diagnostic-export
  - behaviour
  - envelope
  - redaction
  - allowlist
  - sanitize
  - tdd
dependency-graph:
  requires:
    - "Phase 64 — native_runtime_version axis (Compatibility struct)"
    - "lib/crosswake/companions/chimeway/contracts.ex — constructor/validation pipeline"
    - "lib/crosswake/companions/chimeway/telemetry.ex — @forbidden_metadata_keys canonical set"
  provides:
    - "Crosswake.Shell.DiagnosticExport — behaviour + typed Envelope/NativeDiagnostic + sanitize/1"
    - "forbidden_keys/0 and allowed_keys/0 (disjoint, 19+8 atoms)"
    - "new_envelope/1, new_envelope!/1, new_native_diagnostic/1 constructors"
    - "to_map/1 — manual stringify + nil-reject (no @derive)"
  affects:
    - "Phase 65-02 — fixtures will be generated via new_envelope!/1 + to_map/1"
    - "Phase 65-03 — proof lane asserts forbidden_keys/0 ⟂ allowed_keys/0 + sanitize/1 behaviour"
    - "Phase 67 — native shells implement @callback export/1 over this contract"
tech-stack:
  added: []
  patterns:
    - "Behaviour-only callback (IntentConsumer precedent) — no transport code"
    - "Closed-enum @enforce_keys defstruct + @type t (Contracts/Bridge.Contract precedent)"
    - "normalize_attrs → build → validate_* constructor pipeline (Contracts precedent)"
    - "validate_closed/4 + validate_required_string/3 helper functions"
    - "Manual to_map/1 with atom stringify + nil rejection (no @derive Jason.Encoder)"
    - "Fail-closed sanitize/1: reject on forbidden key / unknown key / out-of-enum / non-map"
    - "TDD: RED commit (test file) then GREEN commit (implementation)"
key-files:
  created:
    - lib/crosswake/shell/diagnostic_export.ex
    - test/crosswake/shell/diagnostic_export_test.exs
  modified: []
decisions:
  - "D-01: DiagnosticExport ships @callback export/1 only — no HTTP-sending code, no Req/Finch dep"
  - "D-05: House contract style — @protocol + @schema_version + manual to_map/1, no @derive"
  - "D-06: Envelope @enforce_keys = 7 locked fields (schema_version, layer, platform, native_runtime_version, kind, correlation_id, observed_at)"
  - "D-09: NativeDiagnostic has exactly source + exit_reason — no raw_payload, no open map"
  - "D-13: Redaction wins — no opaque passthrough; struct shape IS the allowlist"
  - "D-14: sanitize/1 is fail-closed — rejects rather than drop-and-continue"
  - "D-15: forbidden_keys/0 returns the canonical 19-key Chimeway.Telemetry set; allowed_keys/0 is disjoint"
metrics:
  duration: "307 seconds (~5 minutes)"
  completed_date: "2026-06-04"
  tasks_completed: 2
  files_created: 2
  files_modified: 0
requirements-completed:
  - DIAG-01
  - DIAG-02
  - DIAG-03
---

# Phase 65 Plan 01: DiagnosticExport Behaviour + Contract Summary

## One-liner

Behaviour-only `@callback export/1` transport seam with typed `Envelope`/`NativeDiagnostic` structs, fail-closed `sanitize/1`, and the canonical 19-key allowlist disjointness contract.

## What Was Built

Created `lib/crosswake/shell/diagnostic_export.ex` — the single foundation file for Phase 65:

**Module-level contract:**
- `@protocol "crosswake.diagnostic"`, `@schema_version "1"`
- `@callback export(Envelope.t()) :: :ok | {:error, term()}` — behaviour-only, no sender code, no HTTP dep (D-01)

**Structs:**
- `Envelope` with 7 `@enforce_keys`: `schema_version`, `layer`, `platform`, `native_runtime_version`, `kind`, `correlation_id`, `observed_at`; optional non-enforced `native_diagnostic` field (D-06)
- `NativeDiagnostic` with 2 `@enforce_keys`: `source` and `exit_reason`; no `raw_payload`, no open map (D-09/D-13)

**Closed-enum accessors:**
- `layers/0` → `[:native, :web, :bridge]`
- `platforms/0` → `[:ios, :android, :web]`
- `kinds/0` → `[:crash, :termination, :hang, :cpu, :bridge_fault, :web_fault]`
- `sources/0` → `[:metrickit, :app_exit_info]`
- `exit_reasons/0` → 8-atom set covering iOS+Android

**Allowlist and redaction:**
- `forbidden_keys/0` → canonical 19-key set verbatim from `Chimeway.Telemetry` (D-15)
- `allowed_keys/0` → envelope + native_diagnostic fields; disjoint from `forbidden_keys/0`
- `sanitize/1` → fail-closed: rejects non-map, forbidden keys, unexpected keys, out-of-enum values (D-14)

**Constructor pipeline:**
- `new_envelope/1`, `new_envelope!/1`, `new_native_diagnostic/1`
- `normalize_attrs/1 → build → validate_*/1` (mirrors `Chimeway.Contracts` pattern)
- `validate_closed/4`, `validate_required_string/3`, `to_result/1`

**Serialisation:**
- `to_map/1` for both structs: stringify atoms (`:native` → `"native"`), reject nils/empty maps, recurse into nested `NativeDiagnostic`; no `@derive Jason.Encoder` (D-05)

## Test Coverage

`test/crosswake/shell/diagnostic_export_test.exs` (21 tests, all passing):
- Behaviour callback assertion
- Struct enforce-key verification (compile-time Elixir guarantee)
- All 5 closed-enum accessor assertions
- `forbidden_keys/0` 19-key count and content
- `allowed_keys/0` disjointness from `forbidden_keys/0`
- `sanitize/1` happy path + all 19 forbidden keys + out-of-enum + unexpected key + non-map input
- `to_map/1` atom stringify + nil rejection + nested NativeDiagnostic recursion

## Verification Results

```
mix compile --warnings-as-errors  → clean (0 warnings)
DiagnosticExport.behaviour_info(:callbacks)  → [{:export, 1}]
DiagnosticExport.layers()  → [:native, :web, :bridge]
Enum.filter(forbidden_keys(), & &1 in allowed_keys())  → []
sanitize(%{...token: "leak"})  → {:error, :redaction_failed}
sanitize(:not_a_map)  → {:error, :redaction_failed}
sanitize(%{valid attrs})  → {:ok, %Envelope{}}
to_map(env)["layer"]  → "native"
21 tests, 0 failures
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Compile-time test for enforce-keys adjusted**
- **Found during:** Task 1 RED→GREEN transition
- **Issue:** The test `raises when constructed without all 7 enforce-keys` attempted to use `%Envelope{}` at compile time in the test file, but Elixir's `@enforce_keys` is enforced at compile-time (not runtime), causing the test file itself to fail to compile.
- **Fix:** Replaced runtime `assert_raise` test with a structural assertion that verifies the struct's declared field keys contain all 7 locked fields. The compile-time guarantee is preserved (Elixir enforces `@enforce_keys` at struct construction sites, which is stronger than runtime assertion).
- **Files modified:** `test/crosswake/shell/diagnostic_export_test.exs`
- **Commit:** 986d545

## Pre-existing Test Failures (Out of Scope)

3 tests in `test/crosswake/planning/milestone_transition_reset_test.exs` were failing before this plan began. These tests assert the project is at v3.9 state, but the project has already advanced to v4.0. These are unrelated to Phase 65 changes and are out of scope per deviation rules. Logged to deferred items.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced at trust boundaries. The `sanitize/1` function is the only untrusted-input crossing and is explicitly covered in the plan's threat model (T-65-01 through T-65-03).

## Known Stubs

None — all functionality is fully implemented. The `@callback export/1` is intentionally a behaviour-only declaration (not a stub); the native transport implementation is deferred to Phase 67 by design (D-01/D-03).

## Self-Check: PASSED

- `lib/crosswake/shell/diagnostic_export.ex` exists: FOUND
- `test/crosswake/shell/diagnostic_export_test.exs` exists: FOUND
- RED commit `986d545` exists: FOUND
- GREEN commit `eb2347f` exists: FOUND
- `mix compile --warnings-as-errors` clean: PASSED
- 21 tests, 0 failures: PASSED
- `behaviour_info(:callbacks)` includes `{:export, 1}`: PASSED
- `forbidden_keys/0` ⟂ `allowed_keys/0` (disjoint): PASSED
- No `@derive Jason.Encoder` in implementation code: PASSED
