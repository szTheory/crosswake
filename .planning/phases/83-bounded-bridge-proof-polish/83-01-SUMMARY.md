---
phase: 83-bounded-bridge-proof-polish
plan: 01
type: execute
wave: 1
has_summary: true
key-files:
  created:
    - examples/phoenix_host/lib/crosswake_example/bridge_proof_live.ex
    - examples/phoenix_host/test/crosswake_example/bridge_proof_live_test.exs
  modified:
    - examples/phoenix_host/lib/crosswake_example/router.ex
---

## Summary
Created `CrosswakeExample.BridgeProofLive` to demonstrate bounded bridge capability integration. The LiveView module renders a "Share" button which, upon clicking, evaluates an inline script that issues a `crosswake.bridge` protocol `share.invoke` command to the native shell. The route `/bridge-proof` was registered in the router with the `share` capability, enabling native interception of the payload.

## Tasks Completed
- Created `BridgeProofLive` module and verified script payload mapping logic.
- Updated `router.ex` to expose `/bridge-proof` with `capabilities: ["share"]`.
- Wrote and passed standard ExUnit tests for `BridgeProofLive` verifying conditional script rendering upon event invocation.

## Next Steps
This provides the backend component necessary to execute the Quick Start e2e verification in Wave 2.