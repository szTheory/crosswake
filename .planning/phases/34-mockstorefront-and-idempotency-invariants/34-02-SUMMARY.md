---
phase: 34-mockstorefront-and-idempotency-invariants
plan: "02"
subsystem: proof-tests
tags: [commerce, proof, replay-invariant, idempotency, wire-03, mock-storefront]
dependency_graph:
  requires: ["34-01"]
  provides: ["WIRE-03 proof", "MOCK-01 proof", "MOCK-02 proof", "MOCK-03 proof", "D-06 proof"]
  affects: ["merge-blocking lane via phase34-proof.yml"]
tech_stack:
  added: []
  patterns:
    - "Code.require_file at module scope before defmodule (hermetic test pattern)"
    - "<> concatenation for forbidden-token fence (phase21/phase23 convention)"
    - "ingest_evidence/2 replay invariant proof via seen_event_keys"
key_files:
  modified:
    - test/crosswake/proof/phase34_mock_storefront_test.exs
decisions:
  - "MOCK-03 asserts function names without arity (simulate_purchase / simulate_restore) because @moduledoc names them as /2; asserting /1 would fail"
  - "Fence converted from inline regex to <> concatenation to match established phase21/phase23 convention and satisfy grep acceptance criterion"
  - "ReconciliationKeys alias added at module scope even though tests do not call it directly — it is loaded via Code.require_file and mirrors phase21 alias ordering"
  - "moduledoc prose mentions requires_example_host twice (in negative + --exclude context) but no @moduletag directive exists; tests run correctly in merge-blocking lane"
metrics:
  duration: "~5 minutes"
  completed: "2026-05-29"
  tasks_completed: 2
  files_modified: 1
---

# Phase 34 Plan 02: MockStorefront Idempotency Proof Augmentation Summary

Augmented `test/crosswake/proof/phase34_mock_storefront_test.exs` (created in Plan 34-01) with the replay-invariant proof through `ReconciliationInbox.ingest_evidence/2`, provider-vocabulary fence in `<>` concatenation convention, swap-target documentation assertion (MOCK-03), and restore-shares-subject_key proof (D-06).

## What Was Built

The existing 13-test file was augmented to 16 tests by:

1. Adding `Code.require_file` calls for `reconciliation_keys.ex` and `reconciliation_inbox.ex` at module scope (before the existing `mock_storefront.ex` require), mirroring the phase21 ordering.
2. Adding aliases `ReconciliationInbox` and `ReconciliationKeys`.
3. Converting the existing source fence from inline regex (`~r/storekit/i` etc.) to the `<>` concatenation convention matching phase21/phase23.
4. Adding `describe "swap-target documentation (MOCK-03)"` — asserts source contains `"simulate_purchase"` and `"simulate_restore"` by name (function arity omitted per deviation correction).
5. Adding `describe "replay invariant via ingest_evidence (WIRE-03)"` with three tests:
   - **Positive:** same `entry_id: "sub_pro_monthly"` with `correlation_id: "c1"` vs `"c2"` → `replay?: true` and `event_key` identical after `ingest_evidence/2`.
   - **Negative:** `entry_id: "entry_a"` vs `entry_id: "entry_b"` → `replay?: false` and distinct `event_key`.
   - **D-06:** purchase `sub_pro_monthly` + restore → `p.subject_key == r.subject_key`.

## Deviations from Plan

### Auto-applied Corrections (Pre-authorized by CRITICAL_DEVIATION_CONTEXT)

**1. [Correction - MOCK-03 arity] Assert function names without arity suffix**
- **Why:** `mock_storefront.ex` @moduledoc names functions as `simulate_purchase/2` and `simulate_restore/2` (arity-2 with `opts \\ []`). Plan task 1 said to assert `/1` which would fail.
- **Applied:** Assert source contains `"simulate_purchase"` and `"simulate_restore"` (no arity). Success Criterion #3 requires "names the two functions" — arity is incidental.
- **Files modified:** test/crosswake/proof/phase34_mock_storefront_test.exs

**2. [Correction - Fence convention] <> concatenation replacing inline regex**
- **Why:** Plan task 2 required this conversion. The existing fence used `~r/storekit/i` etc. which didn't match the project convention or the grep acceptance criterion `grep -E '"store" <> "kit"'`.
- **Applied:** Fence rebuilt as list of `<>` concatenated tokens, bare `File.read!` path, `refute String.contains?` for each token.
- **Files modified:** test/crosswake/proof/phase34_mock_storefront_test.exs

## Verification Results

- `mix test test/crosswake/proof/phase34_mock_storefront_test.exs`: **16 tests, 0 failures**
- `mix test --exclude requires_example_host`: **290 tests, 0 failures (29 excluded)**
- `grep -c 'requires_example_host' test/crosswake/proof/phase34_mock_storefront_test.exs`: 2 (prose-only in moduledoc; no `@moduletag` directive)
- `grep -n '"store" <> "kit"' ...` (worktree file): line 36 confirmed
- No changes to `mock_storefront.ex`, `lib/crosswake/`, or any other example-host commerce module

## Threat Flags

None — this is a pure test file with no network I/O, persistence, or new security surface.

## Known Stubs

None — all assertions resolve to concrete values from the loaded modules.

## Self-Check: PASSED

- [x] `test/crosswake/proof/phase34_mock_storefront_test.exs` exists and is augmented (247 lines)
- [x] Commit ec2f994 exists in worktree-agent-ade78ea6d1f54ad7b branch
- [x] 3 Code.require_file calls at module scope before defmodule
- [x] No @moduletag :requires_example_host directive
- [x] Fence uses <> concatenation (lines 36-39)
- [x] replay invariant describe block present with 3 tests
- [x] swap-target documentation describe block present
- [x] All 16 tests pass
