---
phase: 91-identity-telemetry-contract
plan: "01"
subsystem: threadline-telemetry
tags: [telemetry, allowlist, pii-guard, prop-02, tdd]
dependency_graph:
  requires: []
  provides:
    - Crosswake.Threadline.Telemetry allowlist contract module
  affects:
    - Phase 92 Plug.Threadline (will call Threadline.Telemetry.execute/3)
    - Phase 94 audit ledger (actor_ref in @forbidden_metadata_keys)
tech_stack:
  added: []
  patterns:
    - TDD red/green cycle for contract modules
    - Reduce-filter allowlist guard (mirroring Sigra.Telemetry shape)
    - :telemetry.execute/3 wrapper with metadata sanitization
key_files:
  created:
    - lib/crosswake/threadline/telemetry.ex
    - test/crosswake/threadline/telemetry_test.exs
  modified: []
decisions:
  - "Mirrored Sigra.Telemetry shape verbatim for consistency with established companion pattern"
  - ":source key earns its PROP-02 allowlist slot as thread-provenance-at-boundary (D-09, D-10); value set by Phase 92 Plug"
  - "@forbidden_metadata_keys is Sigra's 19-key list plus :actor_ref (20 total) — Phase 94 PII-adjacent field must never appear in telemetry (RESEARCH A1)"
  - "Event inner struct included for consistency with Sigra/Chimeway pattern (D-11/A2)"
  - "No new dependencies — only :telemetry (already a project dep)"
metrics:
  duration: "3 minutes"
  completed: "2026-06-09T16:13:34Z"
  tasks_completed: 2
  files_created: 2
  files_modified: 0
---

# Phase 91 Plan 01: Threadline Telemetry Contract Summary

**One-liner:** PROP-02 compliant `:telemetry` allowlist contract with 4-key allowlist, 20-key PII denylist, and safe_value?/1 cardinality bound — mirrors Sigra shape, zero new deps.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Write failing hermetic unit tests for Threadline.Telemetry (RED) | 944f63c | test/crosswake/threadline/telemetry_test.exs |
| 2 | Implement Crosswake.Threadline.Telemetry mirroring Sigra (GREEN) | 8606255 | lib/crosswake/threadline/telemetry.ex |

## What Was Built

`Crosswake.Threadline.Telemetry` — the low-cardinality `:telemetry` event-name and metadata allowlist guard for request-span telemetry, establishing the PII-free telemetry contract before any emitter exists.

**Published contract:**
- `event_names/0` — exactly three request-span names: `[:crosswake, :threadline, :request, :start]`, `:stop`, `:exception` (D-07; no bridge/activation events — D-08)
- `metadata_keys/0` — exactly `[:thread_id, :correlation_id, :route_id, :source]` (PROP-02 fixed set; D-11)
- `forbidden_metadata_keys/0` — 20-key PII denylist: Sigra's 19 keys plus `:actor_ref` (RESEARCH A1)
- `metadata/1` — reduce-filter that drops forbidden keys silently, keeps allowlisted safe-valued keys, drops nil values and oversized binaries (>128 chars)
- `execute/3` — routes metadata through `metadata/1` before calling `:telemetry.execute/3`
- `safe_value?/1` — nil→false, atom→true, non-neg int→true, binary→`length ≤ 128`, else→false

**Inner struct:** `Event` with `@enforce_keys [:name]` and `defstruct [:name | @metadata_keys]` for consistency with the established Sigra/Chimeway pattern.

## Test Coverage

12 hermetic unit tests, all GREEN:
- Exact-list equality for `event_names/0` (published contract, not membership-only)
- Exact-list equality for `metadata_keys/0` (PROP-02 four-key contract)
- Forbidden keys include all 7 required PII fields; forbidden and allowed are disjoint (MapSet assertion)
- `metadata/1` keeps only allowlisted safe keys, drops `:access_token`, `:actor_ref`, `:email`, `:user_agent`, `:session_ref`, `:subject_ref`, and unknown high-cardinality keys — asserted via map equality, no raise
- `metadata/1` drops nil-valued allowlisted keys
- `metadata/1` drops a 129-char binary (cardinality bound), keeps a 128-char binary
- `valid_event_name?/1` returns true for declared names, false for undeclared
- `execute/3` with forbidden metadata attaches a `:telemetry` handler, asserts `:ok` return, and asserts forbidden keys are absent from received metadata

## Deviations from Plan

None — plan executed exactly as written.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. The two new files create an in-process telemetry allowlist contract with no I/O surface. STRIDE mitigations from the plan are fully implemented:

| Threat | Mitigation Verified |
|--------|---------------------|
| T-91-PII | `@forbidden_metadata_keys` denylist (20 keys incl. `:actor_ref`) confirmed by drop-secrets map-equality test and execute/3 handler-absence test |
| T-91-CARD | Binary values bounded to ≤128 chars confirmed by 129-char rejection test |
| T-91-UNK | All-or-nothing allowlist: only `@metadata_keys` with safe values pass; confirmed by unknown-key drop assertion |
| T-91-SC | Zero new packages; only `:telemetry` dep used; confirmed by no-OTel grep returning 0 |

## Known Stubs

None — all contract functions are fully implemented and verified.

## Self-Check

## Self-Check: PASSED

- FOUND: lib/crosswake/threadline/telemetry.ex
- FOUND: test/crosswake/threadline/telemetry_test.exs
- FOUND: 944f63c (Task 1 RED commit)
- FOUND: 8606255 (Task 2 GREEN commit)
