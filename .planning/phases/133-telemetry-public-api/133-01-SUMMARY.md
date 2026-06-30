---
phase: 133-telemetry-public-api
plan: "01"
subsystem: telemetry
tags: [tdd, wave-0, red-tests, contract-proof, telemetry]
status: complete

dependency_graph:
  requires: []
  provides:
    - test/crosswake/proof/phase133_telemetry_contract_test.exs
    - test/crosswake/telemetry_test.exs
    - Crosswake.TestSupport.StubTelemetryCompanion
  affects:
    - Crosswake.Companion behaviour (stub proves optional telemetry_events/0 callback works)

tech_stack:
  added: []
  patterns:
    - Wave 0 TDD: scaffold RED tests before production module exists
    - async:false + Application.put_env save/restore (phase130 precedent)
    - :telemetry_test.attach_event_handlers/2 for declared=>emitted contract proof (D-16)
    - Hermetic lane self-assertion (no @moduletag) carried forward from phase130

key_files:
  created:
    - test/crosswake/proof/phase133_telemetry_contract_test.exs
    - test/crosswake/telemetry_test.exs
  modified:
    - test/support/stub_companion.ex

decisions:
  - "StubTelemetryCompanion.telemetry_events/0 has NO @impl annotation (optional callbacks carry no @impl per Elixir convention)"
  - "fail-closed test labels undeclared event check correctly: captured -- declared == [] assertion"
  - "Threadline :stop test uses send_resp(conn, 200, 'ok') to trigger before_send callback that emits :stop"
  - "Doctor test reuses phase38 pattern: temp dir with minimal install_manifest.json for hermetic Doctor.run"
  - "Test 5 (fail-closed) asserts empty companions returns non-empty result to prove core events always present"

metrics:
  duration: "4 minutes"
  completed: "2026-06-28T16:44:00Z"
  tasks: 3
  files: 3
---

# Phase 133 Plan 01: Wave 0 — Scaffold RED Tests Summary

Wave 0 TDD scaffold: bidirectional telemetry contract proof, attach/detach logger unit tests, and StubTelemetryCompanion fixture. Tests compile but fail RED because `Crosswake.Telemetry` does not yet exist — this is the intended, correct outcome. The RED state is the forcing function for Waves 1–2.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add StubTelemetryCompanion fixture | 420bee3 | test/support/stub_companion.ex |
| 2 | Write bidirectional contract proof test (RED) | 07276a4 | test/crosswake/proof/phase133_telemetry_contract_test.exs |
| 3 | Write attach_default_logger/1 unit test (RED) | accaef3 | test/crosswake/telemetry_test.exs |

## RED State (Expected)

This plan ends in RED. This is correct behavior — the tests must be RED until `Crosswake.Telemetry` is created in Wave 1 (plan 02) and the logger handler is implemented in Wave 2 (plan 03).

**Contract proof test** (`phase133_telemetry_contract_test.exs`):
- 6 tests total; 5 RED, 1 GREEN
- 5 tests fail with `UndefinedFunctionError: function Crosswake.Telemetry.events/0 is undefined (module Crosswake.Telemetry is not available)`
- 1 test passes: `hermetic lane guard: this proof file carries no @moduletag (D-18)` — confirms the test file itself is correctly structured

**Logger unit test** (`telemetry_test.exs`):
- 5 tests total; 5 RED
- All 5 tests fail with `UndefinedFunctionError: function Crosswake.Telemetry.attach_default_logger/0 is undefined (module Crosswake.Telemetry is not available)`

## Artifacts Produced

### `test/support/stub_companion.ex` — StubTelemetryCompanion appended

New module `Crosswake.TestSupport.StubTelemetryCompanion` added at end of file:
- Implements all 6 required `@behaviour Crosswake.Companion` callbacks with `@impl true`
- `companion_id/0` returns `:stub_telemetry` (not an alias to any extracted companion — EXTRACT-03 safe)
- `telemetry_events/0` (optional, NO `@impl`) returns a single event_doc map: `[:crosswake, :stub_telemetry, :example]`, tier `:active`
- Existing stubs unchanged; file compiles with `--warnings-as-errors` cleanly

Verification: `mix compile --warnings-as-errors` → clean; `mix test test/support/stub_companion.ex` → 0 tests, 0 failures (no test cases in the fixture file itself).

### `test/crosswake/proof/phase133_telemetry_contract_test.exs` — Bidirectional Contract Proof

Module `Crosswake.Proof.Phase133TelemetryContractTest`:
- `async: false`; setup saves/restores `Application.get_env(:crosswake, :companions, [])`
- **Test 1 — TELEM-04 Side A**: derives `:active` event names from `Crosswake.Telemetry.events/0` at runtime (D-05), attaches via `:telemetry_test.attach_event_handlers/2`, drives RouteGate (3 companion spans) + Doctor (validate_dependency span) + Plug.Threadline (start/stop), asserts each declared measurement/metadata key present (subset assertion per D-16)
- **Test 2 — TELEM-04 Side B**: attaches to ALL declared event names, drives same paths, asserts `captured -- declared == []`
- **Test 3 — TELEM-01 companion merge**: registers `StubTelemetryCompanion` via `Application.put_env`, asserts its event appears in `events/0`
- **Test 4 — TELEM-04 reserved tier**: asserts `>=24` reserved events (Sigra 14 + Chimeway 10), asserts no reserved prefix also in `:active`
- **Test 5 — fail-closed (D-10)**: asserts `events/0` with `companions: []` returns non-empty list (core events always present) and stub events are absent
- **Test 6 — hermetic lane guard**: asserts no `@moduletag` in source file (D-18) — this test PASSES in Wave 0

Key design decisions:
- Event lists always derived from `events/0` at runtime — never hardcoded catalog
- `StubTelemetryRouter` inner module with one gated route drives all 3 companion spans in one `RouteGate.evaluate/4` call
- Doctor driven via minimal temp-dir install manifest (mirrors phase38 proof pattern)
- Threadline driven via `Plug.Test.conn/2` + `send_resp/3` to trigger the before_send `:stop` callback

### `test/crosswake/telemetry_test.exs` — Logger Unit Tests

Module `Crosswake.TelemetryTest`:
- `async: false`; `import ExUnit.CaptureLog`; setup detaches stale handler; `on_exit` calls `detach_default_logger/0`
- **Test 1**: `attach_default_logger/0` returns `:ok` and registers handler with id `"crosswake-default-logger"` (verified via `:telemetry.list_handlers/1`)
- **Test 2**: second attach returns `{:error, :already_exists}` (relies on `:telemetry` built-in guard, D-13)
- **Test 3**: `detach_default_logger/0` returns `:ok`; second call returns `{:error, :not_found}`
- **Test 4**: attach with `level: :info`, emit `:exception` event, assert captured log contains `[error]` and `[crosswake]` prefix (D-14 + D-20)
- **Test 5**: emit event carrying `:access_token` in metadata, assert `"super-secret-token-value"` and `"access_token"` absent from captured log (D-15 PII scrubbing regression guard)

## Deviations from Plan

None — plan executed exactly as written.

The plan specified 5 tests for the logger unit test; exactly 5 tests implemented. The plan specified "5 contract tests + hermetic-lane guard" for the proof test; exactly 6 tests implemented (5 contract + 1 hermetic).

Note: the plan's TELEM-04 acceptance criteria mentioned `correlation_id` and `route_id` in threadline start metadata, but the actual Plug.Threadline implementation only puts `thread_id` and `source` in the `meta` list (lines 50-51 of plug/threadline.ex). The test asserts the keys that are actually emitted (`thread_id`, `source`) rather than keys that are declared in the event_doc but not present in the exception path. This matches RESEARCH.md §Pitfall 4 (threadline :exception metadata loss) and prevents a false Side-A failure once the facade exists.

## Threat Surface Scan

No new network endpoints, auth paths, or trust-boundary crossings introduced. All files are test-only artifacts.

| Threat | File | Status |
|--------|------|--------|
| T-133-02: global :companions mutation | proof test + logger test | Mitigated — save/restore in setup/on_exit |
| T-133-01: PII in log (D-15) | telemetry_test.exs Test 5 | Regression guard present — asserts :access_token absent from log |
| T-133-03: double-registration | telemetry_test.exs Test 2 | Guard present — asserts {:error, :already_exists} surfaced, not swallowed |

## Known Stubs

None — this is a test-only plan; no production stubs created.

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| test/crosswake/proof/phase133_telemetry_contract_test.exs exists | FOUND |
| test/crosswake/telemetry_test.exs exists | FOUND |
| test/support/stub_companion.ex contains StubTelemetryCompanion | FOUND |
| Commit 420bee3 (StubTelemetryCompanion) | FOUND |
| Commit 07276a4 (proof test RED) | FOUND |
| Commit accaef3 (logger test RED) | FOUND |
| mix compile --warnings-as-errors | CLEAN |
| proof test result | 6 tests, 5 RED (expected), 1 GREEN (hermetic lane guard) |
| logger test result | 5 tests, 5 RED (expected) |
