---
phase: 99-real-network-toggling-e2e-tests
plan: 02
subsystem: e2e
tags:
  - playwright
  - e2e
  - offline-sync
dependency_graph:
  requires:
    - 99-01
  provides:
    - offline-sync-test
  affects:
    - examples/phoenix_host/e2e/offline_sync.spec.ts
tech_stack:
  added: []
  patterns:
    - Playwright offline toggle
    - expect.poll API verification
key_files:
  created: []
  modified:
    - examples/phoenix_host/e2e/offline_sync.spec.ts
metrics:
  duration: 15
  completed_at: "2026-06-11T15:45:00Z"
---

# Phase 99 Plan 02: Implement real network-toggling E2E tests

**Goal:** Implement real network-toggling E2E tests using Playwright.

## Key Decisions Made

- Use `context.setOffline(true)` to natively simulate a disconnected environment.
- Use `page.evaluate` to simulate offline writes, intercept sync requests when online, and verify against the `/_e2e/sync-state` API using Playwright's `expect.poll` utility.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED