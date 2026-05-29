---
phase: 36-hermetic-proof-lane
plan: 01
subsystem: proof
tags: [proof, hermetic, exunit, entitlement, paywall, commerce]
dependency_graph:
  requires:
    - "examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex (Code.require_file)"
    - "examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex (Code.require_file)"
    - "examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex (Code.require_file)"
    - "examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex (Code.require_file)"
    - "lib/crosswake/commerce/reconciliation.ex (compilation path)"
    - "lib/crosswake/commerce/contracts.ex (compilation path)"
  provides:
    - "Merge-blocking hermetic proof of Phase 34 paywall corridor (PROOF-01, PROOF-03)"
  affects:
    - ".github/workflows/phase34-proof.yml (auto-discovered via glob — no change)"
tech_stack:
  added: []
  patterns:
    - "Code.require_file hermetic idiom (phase21/34 precedent)"
    - "phase34_-prefixed defp fixture helpers (phase21 precedent)"
    - "Self-scan hermeticity guard using File.read!(__ENV__.file) (phase23/33 precedent)"
    - "Token concatenation to prevent self-scan false positives (phase34 precedent)"
key_files:
  created:
    - test/crosswake/proof/phase34_paywall_corridor_proof_test.exs
  modified: []
decisions:
  - "reconciliation_keys.ex IS a real dependency (ReconciliationInbox aliases ReconciliationKeys at line 10); require_file load order reconciliation_keys -> reconciliation_inbox -> entitlement_projection -> mock_backend is confirmed correct"
  - "Private defp phase34_-prefixed helpers chosen over nested defmodule (matches phase21 precedent; cleaner, no cross-module collision risk)"
  - "Self-scan untagged check uses line-start regex filter for @moduletag directives to avoid matching moduledoc prose mentioning the tag"
  - "Token splits: process-server tokens built via concatenation (e.g. 'start' <> '_supervised') prevent guard false positives"
  - "phase34-proof.yml confirmed to auto-discover the new file via glob — no workflow change required (D-09)"
metrics:
  duration: "~18 min"
  completed_date: "2026-05-29"
---

# Phase 36 Plan 01: Hermetic Paywall Corridor Proof Summary

**One-liner:** ExUnit merge-blocking proof exercising the full Phase 34 paywall corridor (evidence -> ingest_evidence/2 -> project_snapshot/2 -> derived_state/1) with four-state coverage, :pending->:granted transition, mock-boundary fence, and self-scan hermeticity guard.

## What Was Built

A single new test file `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` (286 lines, 14 tests, 0 failures) satisfying PROOF-01 and PROOF-03. No product code was modified.

### Task Completions

| Task | Name | Commit | Status |
|------|------|--------|--------|
| 1 | require_file header + moduledoc + async:false skeleton + phase34_-prefixed builders | 9aebfcb | Done |
| 2 | Four-state coverage (SC#1) + :pending->:granted transition (SC#2) | 9aebfcb | Done |
| 3 | Mock-boundary fence (SC#3 / PROOF-03, D-06 three real truths) | 9aebfcb | Done |
| 4 | Self-scan hermeticity guard (SC#4) + CI flag verification | 9aebfcb | Done |

All four tasks were implemented in a single file in one atomic commit (the file forms an indivisible unit; partial commits would leave the test file in a non-compiling state between task boundaries).

## Confirmed: require_file Load Order

The four `Code.require_file` lines in confirmed dependency order:

1. `reconciliation_keys.ex` — **IS a real dependency**: `ReconciliationInbox` aliases `CrosswakeExample.Commerce.ReconciliationKeys` at line 10. Dropping it would cause `ReconciliationInbox` to fail to load.
2. `reconciliation_inbox.ex` — depends on `reconciliation_keys.ex`
3. `entitlement_projection.ex` — independent of the above; must precede `mock_backend.ex`
4. `mock_backend.ex` — aliases `EntitlementProjection` (line 38); requires it to be loaded first

No concern about silently dropping `reconciliation_keys.ex` — it is a genuine dependency, confirmed by reading the source.

## Anti-Vacuity Self-Check Result

Flipping the `:stale` assertion (`assert EntitlementProjection.derived_state(snap) == :stale`) to `:pending` produces **1 failure** as expected — the `:stale` snapshot (freshness.state :stale) correctly returns `:stale` from the cond's first branch, NOT `:pending`. This confirms the snapshot distinguishes the state branch correctly. The other three state assertions are similarly routed by distinct snapshot configurations:

- `:stale` — `phase34_freshness_lane(:stale)` override; cond first branch fires
- `:pending` — `phase34_reconciliation_lane(:awaiting_verification)` override; cond second branch fires
- `:denied` — base defaults (access :denied, reconciliation :projection_refreshed, fresh); `granted_snapshot?` returns false -> cond fallthrough
- `:granted` — SHIPPED `MockBackend.build_verified_snapshot/2` -> `project_snapshot(nil, verified)` -> cond third branch fires (anti-vacuity per SC#2)

## phase34-proof.yml Auto-Discovery Confirmation

`.github/workflows/phase34-proof.yml` line 83 runs:
```
mix test --exclude requires_example_host
```

The workflow comment on lines 78-82 **explicitly names Phase 36** and states: *"The Phase 36 proof file is untagged and uses Code.require_file to reach example-host modules — so it is picked up automatically here without a per-file path list."* The new file at `test/crosswake/proof/` is untagged, so it is auto-discovered. **No workflow change was made** (D-09 confirmed).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Self-scan `@moduletag :requires_example_host` guard tripped on moduledoc prose**

- **Found during:** Task 4 implementation
- **Issue:** The initial attempt used `refute String.contains?(source, "@module" <> "tag :requires_example_host")`. The moduledoc explicitly mentions "no @moduletag :requires_example_host" in its hermeticity contract description — the substring is present in the doc text, causing a false positive.
- **Fix:** Changed to a line-by-line scan that filters only lines matching `~r/^\s*@moduletag\s/` (actual directive lines at line start) and checks those for the forbidden tag name `"requires" <> "_example_host"`. Prose embedded mid-line in the moduledoc is not matched.
- **Files modified:** `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs`
- **Commit:** 9aebfcb (same commit — pre-commit iteration)

### SC#3 / D-06 Reinterpretation (planned, not a deviation)

As documented in 36-CONTEXT.md D-06, SC#3's literal wording ("project_snapshot rejects non-:projection_refreshed states") is factually wrong — the function accepts four verified states. The proof asserts the three real truths (D-06.1/D-06.2/D-06.3) instead. This is a pre-planned reinterpretation, not a deviation.

### SC#4 / D-02 Reinterpretation (planned, not a deviation)

As documented in 36-CONTEXT.md D-02, SC#4's literal wording ("no Code.require_file on example-host paths") is reinterpreted as "no require_file on runtime/server paths." Loading the four pure commerce modules IS the hermetic idiom. This is a pre-planned reinterpretation, not a deviation.

## Known Stubs

None — all assertions drive real shipped code paths. No hardcoded empty values or placeholder data.

## Threat Flags

None — test-only addition with no runtime trust boundaries (as specified in the plan threat model T-36-NA).

## Self-Check: PASSED

- [x] `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` exists
- [x] Commit 9aebfcb exists: `feat(36-01): add hermetic merge-blocking paywall corridor proof`
- [x] `mix compile --warnings-as-errors` clean (exit 0)
- [x] `mix test test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` — 14 tests, 0 failures (exit 0)
- [x] `mix test --exclude requires_example_host` — 308 tests, 0 failures, 38 excluded (exit 0)
- [x] Four distinct derived_state assertions (SC#1)
- [x] :pending->:granted transition via real pipeline (SC#2)
- [x] Mock-boundary fence — three D-06 truths (SC#3)
- [x] Self-scan hermeticity guard (SC#4)
- [x] No changes to lib/crosswake/commerce/* or example-host modules
- [x] phase34-proof.yml auto-discovers file (no workflow change)
- [x] Anti-vacuity confirmed: flipping :stale to :pending produces 1 failure
