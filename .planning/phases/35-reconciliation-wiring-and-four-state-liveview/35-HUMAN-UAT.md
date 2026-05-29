---
status: partial
phase: 35-reconciliation-wiring-and-four-state-liveview
source: [35-VERIFICATION.md]
started: "2026-05-29T00:00:00Z"
updated: "2026-05-29T00:00:00Z"
---

## Current Test

[awaiting human testing]

## Tests

### 1. Subscribe flow async transition
expected: With the example host running, visiting `/paywall` and clicking "Subscribe" drives `:stale` → `:pending` (processing state shown) → `:granted` (access granted), observable as a live async transition via the PubSub `{:entitlement_update, derived_state}` path.
result: [pending]

### 2. `:denied` component renders pricing + actions
expected: The `:denied` state renders the single subscription `PaywallEntry` with `price_display` and a working "Subscribe" action (and Restore affordance), with zero provider-SDK UI.
result: [pending]

### 3. `:stale` vs `:denied` structural distinction
expected: The `:stale` state ("can't verify access right now", no price/Subscribe action) is visually distinct from `:denied` (pricing + Subscribe) and from `:pending` (processing).
result: [pending]

### 4. Restore flow async transition
expected: Triggering the restore-intent flow produces the same async `:pending` → `:granted` transition as the subscribe flow.
result: [pending]

## Summary

total: 4
passed: 0
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps
