---
phase: 34-mockstorefront-and-idempotency-invariants
plan: "01"
subsystem: example-host-commerce
tags: [commerce, mock, storefront, reconciliation, evidence, tdd]
requirements-completed: [MOCK-01, MOCK-02, MOCK-03]

dependency_graph:
  requires:
    - "lib/crosswake/commerce/contracts.ex (PurchaseIntent, RestoreIntent, ReconciliationEvidence)"
    - "examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex"
    - "examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex"
    - "examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex"
  provides:
    - "CrosswakeExample.Commerce.MockStorefront with simulate_purchase/2 and simulate_restore/2"
    - "Stable provider identity for ReconciliationKeys/ReconciliationInbox idempotency proof (Plan 02)"
  affects:
    - "test/crosswake/proof/phase34_mock_storefront_test.exs"

tech_stack:
  added: []
  patterns:
    - "TDD RED/GREEN cycle: failing tests committed before implementation"
    - "Code.require_file for example-host module loading in hermetic tests"
    - "Module constant @subscription_entry_id as single canonical product identifier"
    - "Clock seam via opts Keyword.get(opts, :captured_at, ...) for test determinism"
    - "Private helpers provider_reference/1 and evidence_ref/2 mirroring ReconciliationKeys style"

key_files:
  created:
    - examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex
    - test/crosswake/proof/phase34_mock_storefront_test.exs
  modified: []

decisions:
  - "provider_reference/evidence_ref derive from entry_id only, never correlation_id (D-01/D-02/D-03)"
  - "Restore anchored on @subscription_entry_id constant so subject_key matches purchase of same product (D-06/D-07)"
  - "@moduledoc swap-target prose avoids forbidden tokens by describing 'a real provider adapter (for example, one wrapping a native payment SDK)' rather than naming banned providers (T-34-01)"
  - "Both functions return raw structs (no {:ok, _} wrapper) per D-10"
  - "Code.require_file used in test (not elixirc_paths) matching Phase 21 pattern"

metrics:
  duration: "~8 minutes"
  completed_date: "2026-05-29T16:18:21Z"
  tasks_completed: 1
  files_changed: 2
---

# Phase 34 Plan 01: MockStorefront Evidence Emitter Summary

Pure-Elixir MockStorefront evidence emitter with `simulate_purchase/2` and `simulate_restore/2` returning correctly-shaped `ReconciliationEvidence` structs, identity derived from stable `entry_id`/`@subscription_entry_id` constants (never transient `correlation_id`), and a `captured_at` clock seam.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| RED | TDD: add failing tests for MockStorefront | 28bb98d | test/crosswake/proof/phase34_mock_storefront_test.exs |
| GREEN | Implement MockStorefront evidence emitter | ad4de72 | examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex, test/crosswake/proof/phase34_mock_storefront_test.exs |

## Acceptance Criteria Verification

- [x] File `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex` exists with `defmodule CrosswakeExample.Commerce.MockStorefront`
- [x] `mix compile --warnings-as-errors` succeeds — 0 warnings, 0 errors
- [x] `provider_reference` helper: `"mock_txn_" <> entry_id`; `evidence_ref` helper: `"mock_evt_" <> entry_id <> "_" <> event_kind`; neither references `correlation_id`
- [x] `simulate_purchase` struct: `source: :storefront`, `provider: "mock"`, `event_kind: "purchase"`
- [x] `simulate_restore` struct: `event_kind: "restore"` with `@subscription_entry_id` for both ref derivations
- [x] Both functions take `opts \\ []` with `Keyword.get(opts, :captured_at, DateTime.utc_now() |> DateTime.to_iso8601())`
- [x] Neither function wraps return in `{:ok, ...}` — bare `%Contracts.ReconciliationEvidence{}` struct returned
- [x] Fence: `grep -iE 'store ?kit|play[ _]billing|revenuecat'` returns nothing (exit 1 / empty)
- [x] `@moduledoc` names both `simulate_purchase/2` and `simulate_restore/2` as swap-target functions
- [x] File is 81 lines (min_lines: 40 satisfied)
- [x] 16 ExUnit tests pass covering all behavioral invariants

## Must-Have Truths Validated

- **MOCK-01**: `simulate_purchase/1` returns `ReconciliationEvidence{source: :storefront, provider: "mock", event_kind: "purchase"}` with no provider-SDK code
- **MOCK-02**: `simulate_restore/1` returns `ReconciliationEvidence{event_kind: "restore"}`
- **MOCK-03**: `@moduledoc` names both functions as the two a real provider adapter would replace
- **D-01/D-02/D-03**: `provider_reference` and `evidence_ref` derived from `entry_id` only, `correlation_id` never referenced in identity derivation
- **D-04/D-06**: Correct `event_kind` values ("purchase"/"restore")
- **D-08/D-09**: `captured_at` clock seam injectable via `opts`
- **D-10**: Raw struct returned, no `{:ok, _}` wrapper
- **D-11**: `@moduledoc` explicitly names the two swap-target functions
- **T-34-01**: No forbidden provider tokens (storekit/play_billing/revenuecat) in source

## Key Link Validated

`mock_storefront.ex` → `Crosswake.Commerce.Contracts.ReconciliationEvidence` via `%Contracts.ReconciliationEvidence{...}` struct literal with all six `@enforce_keys`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added Code.require_file to test file**

- **Found during:** Task 1 GREEN phase
- **Issue:** `mix.exs` elixirc_paths only includes `lib` and `test/support`, not `examples/`. The `MockStorefront` module was compiled into the example host but not available to the test suite without explicit loading.
- **Fix:** Added `Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex", __DIR__)` at the top of the test file, exactly matching the Phase 21 `reconciliation_inbox.ex` / `reconciliation_keys.ex` pattern.
- **Files modified:** test/crosswake/proof/phase34_mock_storefront_test.exs
- **Commit:** ad4de72 (folded into GREEN commit)

## TDD Gate Compliance

- RED gate: `test(34-01): add failing tests for MockStorefront (RED)` — commit 28bb98d — 16 tests, 16 failures
- GREEN gate: `feat(34-01): implement MockStorefront evidence emitter (GREEN)` — commit ad4de72 — 16 tests, 0 failures
- REFACTOR gate: Not needed — implementation was clean on first pass

## Known Stubs

None — this plan creates a complete evidence emitter with deterministic, stable output. No placeholder data, no mocked returns, no TODO markers.

## Threat Flags

None — the provider-vocabulary fence (T-34-01) was verified clean via grep. No new trust boundaries introduced. This module is pure in-process with no network I/O, no persistence, no user-string input, and no authority mutation.

## Self-Check: PASSED

- [x] `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex` exists
- [x] `test/crosswake/proof/phase34_mock_storefront_test.exs` exists
- [x] Commit 28bb98d exists (RED)
- [x] Commit ad4de72 exists (GREEN)
