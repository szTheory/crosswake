---
status: resolved
phase: 35-reconciliation-wiring-and-four-state-liveview
source: [35-VERIFICATION.md]
started: "2026-05-29T00:00:00Z"
updated: "2026-05-29T00:00:00Z"
resolved_by: test/crosswake/proof/phase35_paywall_live_test.exs
---

## Current Test

All items automated — zero human verification required.

These four items were converted from manual UAT into deterministic automated tests in
`test/crosswake/proof/phase35_paywall_live_test.exs`, run merge-blocking on every PR + push
via `script/verify_phase5_example_hosts.sh` (`.github/workflows/phase5-proof.yml`). The test
uses the repo's no-Endpoint LiveView pattern (bare socket + direct callbacks) and a
`start_supervised!` `Phoenix.PubSub`, so it needs no HTTP server and no new dependencies.

## Tests

### 1. Subscribe flow async transition
expected: `/paywall` Subscribe drives `:stale` → `:pending` → `:granted` via the PubSub `{:entitlement_update, derived_state}` path.
result: resolved — covered by "subscribe drives :stale -> :pending -> :granted through the message path" (asserts immediate `:pending` broadcast then `:granted` within 3s, and that each message re-renders the matching state).

### 2. `:denied` component renders pricing + actions
expected: `:denied` renders the single subscription `PaywallEntry` with `price_display` and a working "Subscribe" action (+ Restore), zero provider-SDK UI.
result: resolved — covered by ":denied renders the single subscription PaywallEntry with pricing and both actions" + the provider-vocabulary fence test.

### 3. `:stale` vs `:denied` structural distinction
expected: `:stale` ("can't verify access", no price/Subscribe) is visually distinct from `:denied` and `:pending`.
result: resolved — covered by ":stale is structurally distinct from :denied" (asserts stale markup; refutes price + `phx-click="subscribe"`) plus the `:pending`/`:granted` render tests.

### 4. Restore flow async transition
expected: Restore produces the same async `:pending` → `:granted` transition.
result: resolved — covered by "restore drives the same :pending -> :granted transition".

## Summary

total: 4
passed: 4
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps
