---
phase: 159-host-reusable-proof-lane
plan: "10"
subsystem: Phoenix-host browser proof
tags: [playwright, phoenix, typescript, offline-island, privacy]
requires:
  - phase: 159-06
    provides: additive repository and generated browser proof helpers
provides:
  - One-command Phoenix-host offline-island proof
  - Closed lowercase opaque mutation-ID validation before proof callbacks
affects: [proof-lane, PROOF-02, PROOF-03, PROOF-04]
tech-stack:
  added: []
  patterns: [host-owned Playwright lifecycle, stable non-echoing boundary failures]
key-files:
  created:
    - script/verify_phoenix_host_proof_lane.sh
  modified:
    - examples/phoenix_host/package.json
    - examples/phoenix_host/e2e/support/offline_route_proof.ts
    - examples/phoenix_host/e2e/crosswake_proof_lane/browser_online_restore.spec.ts
    - examples/phoenix_host/e2e/crosswake_proof_lane/support/proof_lane.ts
    - priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex
    - test/crosswake/proof_lane/template_contract_test.exs
key-decisions:
  - "The existing Playwright webServer remains the sole owner of Phoenix test-database setup and server lifecycle."
  - "Browser proof accepts only anchored lowercase UUID-shaped opaque mutation references and emits PL-BROWSER-MUTATION-ID without echoing input."
metrics:
  duration: 14m
  completed: 2026-08-01
  tasks_completed: 2
  files_changed: 7
status: complete
---

# Phase 159 Plan 10: Phoenix-Host Browser Gate Summary

The primary offline-island corpus now runs against its Phoenix host through one additive command, while repository and generated proof helpers reject non-opaque mutation references before any backend or idempotency callback.

## Completed Work

- Added `proof:offline-island` to run the existing `offline_sync.spec.ts` and cleanup regression without replacing the host's unfiltered test command, fixtures, or Playwright configuration.
- Added `script/verify_phoenix_host_proof_lane.sh`, which checks existing Node tools, typechecks the helper, and delegates the Phoenix lifecycle to Playwright's existing `webServer`.
- Replaced permissive mutation-ID checks with one anchored lowercase UUID shape and a stable `PL-BROWSER-MUTATION-ID` failure that does not include the rejected value.
- Added browser regressions for valid, empty, arbitrary, uppercase, malformed, path-like, and identity-like values, including an assertion that invalid records never reach downstream proof callbacks.
- Kept the rendered generated helper byte-identical to its template and added contract coverage for the anchored boundary and non-interpolated error.

## Task Commits

1. Task 1 — `78741e22` chore(159-10): add Phoenix host offline proof command
2. Task 2 RED — `d72e4626` test(159-10): add opaque mutation ID regressions
3. Task 2 GREEN — `ffc8d98e` feat(159-10): validate opaque browser mutation IDs

## Verification

- `bash script/verify_phoenix_host_proof_lane.sh` — passed; typecheck plus five Playwright tests, including the real Phoenix offline mutation/replay flow.
- `npm --prefix examples/phoenix_host run typecheck:offline-route-proof` — passed.
- `npm --prefix examples/phoenix_host test -- e2e/crosswake_proof_lane/browser_online_restore.spec.ts` — passed (4 tests).
- `mix test test/crosswake/proof_lane/template_contract_test.exs` — passed (5 tests).
- `git diff --check` — passed.

## Decisions Made

- The wrapper remains a local runnable control and does not create a CI, report-upload, or evidence-retention lane.
- The mutation ID is a bounded correlation reference, not a host payload schema or account/device identifier.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Empty invalid-value assertion treated every string as an error-message substring**
- **Found during:** Task 2 GREEN verification
- **Issue:** The regression's non-echo assertion fails trivially for an empty rejected value because every string contains the empty substring.
- **Fix:** Retained exact stable-error validation and applied the non-echo substring assertion only to non-empty canaries.
- **Files modified:** `examples/phoenix_host/e2e/crosswake_proof_lane/browser_online_restore.spec.ts`
- **Commit:** `ffc8d98e`

## Known Stubs

None.

## Self-Check: PASSED

- All seven changed production, test, template, and wrapper artifacts exist.
- All three task commits exist in git history.
- The one-command host proof, focused browser/typecheck control, and template contract suite pass from the final tree.
