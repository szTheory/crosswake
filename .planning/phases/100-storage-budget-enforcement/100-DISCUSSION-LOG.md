# Phase 100: Storage Budget Enforcement - Discussion Log

**Date:** 2026-06-11

## User Intent
- Update existing phase context with deep research into offline constraints and idiomatic handling of browser quota limitations.

## Discussion Notes
- **Eviction Trigger:** The user directed an investigation to determine whether to auto-evict oldest sessions or require manual clearing. Research concluded that silent eviction violates trust. A hybrid, policy-driven approach was selected: optional media is evicted, but required data must be cleared manually.
- **Quota Check Timing:** Decided to block upfront on download. Delaying checks until mutation save is a UX footgun leading to data loss.
- **UI Blocking Level:** Established a hard block if the reserved storage budget for the sync journal is exhausted. No dismissible warnings for volatile study.

## Claude's Discretion Items
- API shape for the Elixir manifest constraints (`reserve_for_journal` and `eviction` blocks).

## Deferred Ideas
None.