---
phase: 99-real-network-toggling-e2e-tests
plan: 01
subsystem: e2e
tags:
  - playwright
  - e2e
  - offline-sync
dependency_graph:
  requires: []
  provides:
    - playwright-config
    - sync-verifier-api
  affects:
    - examples/phoenix_host/router.ex
tech_stack:
  added: []
  patterns:
    - MIX_ENV-gated routes
    - playwright-webserver
key_files:
  created:
    - examples/phoenix_host/playwright.config.ts
    - examples/phoenix_host/lib/crosswake_example/e2e/sync_state_controller.ex
  modified:
    - examples/phoenix_host/lib/crosswake_example/router.ex
metrics:
  duration: 10
  completed_at: "2026-06-11T15:37:27Z"
---

# Phase 99 Plan 01: Setup E2E harness and backend verification API

**Goal:** Setup E2E harness and backend verification API for network-toggling tests.

## Key Decisions Made

- Playwright configuration isolates the test execution state, starts the Phoenix server through `webServer` block, and disables service worker caching to ensure correct offline test resolution.
- Added `/_e2e` router scope gated to `[:test, :e2e]` environments, providing secure data verification capabilities without cross-process coupling.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED
