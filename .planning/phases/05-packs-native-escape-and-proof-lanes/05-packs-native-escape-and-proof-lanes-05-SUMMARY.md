---
phase: 05-packs-native-escape-and-proof-lanes
plan: 05
subsystem: bridge
tags:
  - bridge
  - transfer
  - manifest
dependency_graph:
  requires:
    - 05-04
  provides:
    - Explicit transfer bridge command vocabulary
    - Manifest-backed transfer command allowlist
  affects:
    - lib/crosswake/bridge/contract.ex
    - lib/crosswake/bridge/registry.ex
    - test/crosswake/bridge/contract_test.exs
    - test/crosswake/bridge/registry_test.exs
    - test/crosswake/doctor/doctor_test.exs
    - test/mix/tasks/crosswake_doctor_test.exs
tech_stack:
  added: []
  patterns:
    - Typed request/reply bridge contract
    - Route-local manifest transfer seam allowlisting
key_files:
  created: []
  modified:
    - lib/crosswake/bridge/contract.ex
    - lib/crosswake/bridge/registry.ex
    - test/crosswake/bridge/contract_test.exs
    - test/crosswake/bridge/registry_test.exs
    - test/crosswake/doctor/doctor_test.exs
    - test/mix/tasks/crosswake_doctor_test.exs
decisions:
  - Transfer bridge commands stay explicit and semantic: `transfer.import`, `transfer.export`, `transfer.download`, and `transfer.upload.prepare`.
  - Transfer command exposure is derived from manifest-declared route transfer seams, not from generic capability or container authority.
metrics:
  completed_at: 2026-05-16T23:16:02Z
  duration: n/a
---

# Phase 5 Plan 05: Bound The Bridge Allowlist To Explicit Manifest-Backed Transfer Commands Summary

Bridge command exposure now covers the Phase 5 transfer seam vocabulary without widening into generic file, browser, or share-sheet authority. The contract remains typed, versioned, and request/reply-only.

## Completed Tasks

| Task | Result | Commit |
|------|--------|--------|
| 1 | Extended `Crosswake.Bridge.Contract` with explicit transfer commands and contract tests | `f80fd7b` |
| 2 | Taught `Crosswake.Bridge.Registry` to allowlist transfer commands from manifest route transfer seams only; updated affected doctor tests | `d0c875d` |

## Verification

- `mix test test/crosswake/bridge/contract_test.exs` — PASS
- `mix test test/crosswake/bridge/registry_test.exs` — PASS
- `mix test test/crosswake/compatibility/compatibility_test.exs` — PASS
- `mix test test/crosswake/doctor/doctor_test.exs test/mix/tasks/crosswake_doctor_test.exs` — PASS
- `mix test test/crosswake/bridge/contract_test.exs test/crosswake/bridge/registry_test.exs` — PASS

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test Drift] Update doctor bridge posture expectations**
- **Found during:** Task 2 verification
- **Issue:** Doctor tests hard-coded the old three-command bridge list and failed once transfer commands became part of the bounded public bridge vocabulary.
- **Fix:** Updated doctor and mix-task doctor tests to assert the expanded explicit command list.
- **Files modified:** `test/crosswake/doctor/doctor_test.exs`, `test/mix/tasks/crosswake_doctor_test.exs`
- **Verification:** `mix test test/crosswake/doctor/doctor_test.exs test/mix/tasks/crosswake_doctor_test.exs`
- **Commit:** `d0c875d`

**Total deviations:** 1 auto-fixed.  
**Impact:** Kept public bridge posture checks aligned with the new bounded transfer command surface.

## Known Stubs

None.

## Self-Check: PASSED
