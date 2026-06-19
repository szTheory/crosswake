---
phase: 120-collateral-artifact-ci-and-troubleshooting
plan: "01"
subsystem: testing
tags: [playwright, github-actions, phoenix, offline-sync, route-policy]

requires:
  - phase: 112-115
    provides: honest offline-sync IndexedDB outbox/reconnect/Ecto proof and guard pattern
  - phase: 119
    provides: native evidence labels and checked-in public-coordinate proof posture
provides:
  - Browser route-tour proof for LiveView, bounded bridge, offline island, and native-screen fallback route ownership
  - Required `route-tour-proof` CI job with route-tour screenshot artifact upload
  - Extended E2E honesty guard coverage for route-tour offline proof files
affects: [COLL-01, offline-sync-e2e-gate, phoenix-host-e2e]

tech-stack:
  added: []
  patterns:
    - Semantic Playwright assertions before collateral screenshots
    - Test-only E2E fixture routes compile-gated out of prod
    - Shared offline proof helpers restricted to observation and server polling

key-files:
  created:
    - examples/phoenix_host/e2e/route_tour.spec.ts
    - examples/phoenix_host/e2e/support/offline_route_proof.ts
    - examples/phoenix_host/lib/crosswake_example/e2e/native_claim_controller.ex
  modified:
    - .github/workflows/offline-sync-e2e-gate.yml
    - examples/phoenix_host/e2e/offline_sync.spec.ts
    - examples/phoenix_host/lib/crosswake_example/bridge_proof_live.ex
    - examples/phoenix_host/lib/crosswake_example/router.ex
    - script/check-e2e-honesty.mjs

key-decisions:
  - "Route-tour correctness is semantic; screenshots are captured only after route-owner assertions pass."
  - "Bridge payload semantics are exposed through browser-observable example-host contract markup instead of requiring native share-sheet execution."
  - "Native-screen route coverage uses a test-only claim fixture and the real browser fallback for selective-native-claim-capture."

patterns-established:
  - "Route-tour screenshots live under examples/phoenix_host/playwright-artifacts/route-tour for CI artifact upload, not source control."
  - "Offline proof sharing keeps state mutation in app UI/code and moves only IndexedDB observation and Ecto polling into helpers."

requirements-completed: [COLL-01]

duration: 1h
completed: 2026-06-19
status: complete
---

# Phase 120 Plan 01: Browser Route-Tour Proof Summary

**Merge-blocking browser route-tour proof now verifies route ownership semantically before uploading collateral screenshots.**

## Performance

- **Duration:** ~1h
- **Started:** 2026-06-19T20:23:00Z
- **Completed:** 2026-06-19T20:41:00Z
- **Tasks:** 3
- **Files modified:** 8 implementation files plus this summary

## Accomplishments

- Added `route_tour.spec.ts` covering `/library`, `/bridge-proof`, `/offline`, and `/native/claims/:id/capture` with route-id/owner-specific assertion messages.
- Extracted shared offline proof helpers while preserving the app-owned UI -> IndexedDB -> reconnect -> `/study/sync` -> Ecto path.
- Added `route-tour-proof` to `.github/workflows/offline-sync-e2e-gate.yml`, including screenshot upload with `if-no-files-found: error` and aggregator inclusion.
- Extended `script/check-e2e-honesty.mjs` to scan the new route-tour spec and helper for fabricated offline proof shapes.

## Task Commits

1. **Tasks 1-3: Route-tour proof, CI wiring, honesty guard** - `1028557` (`feat`)

## Files Created/Modified

- `examples/phoenix_host/e2e/route_tour.spec.ts` - Semantic browser route-owner tour and collateral screenshot capture.
- `examples/phoenix_host/e2e/support/offline_route_proof.ts` - Shared observation/polling helpers for app-owned offline replay proof.
- `examples/phoenix_host/e2e/offline_sync.spec.ts` - Reused the helper without changing the real UI mutation path.
- `examples/phoenix_host/lib/crosswake_example/bridge_proof_live.ex` - Exposed browser-observable bridge payload contract for route-tour assertions.
- `examples/phoenix_host/lib/crosswake_example/e2e/native_claim_controller.ex` - Test-only fixture route for deterministic native-screen fallback coverage.
- `examples/phoenix_host/lib/crosswake_example/router.ex` - Added the compile-gated `/_e2e/native-claim` route.
- `.github/workflows/offline-sync-e2e-gate.yml` - Added `route-tour-proof`, artifact upload, summary copy, and aggregator dependency.
- `script/check-e2e-honesty.mjs` - Scans offline sync, route tour, and helper files.

## Decisions Made

- Kept route-tour screenshots as CI artifacts only. Local generated `playwright-artifacts/route-tour` output was removed before commit.
- Used `/usr/bin/ruby` for YAML parsing because the shell Ruby shim required a Ruby version not present in this repo's `.tool-versions`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added browser-observable bridge payload contract**
- **Found during:** Task 1
- **Issue:** The minimal Phoenix host did not load LiveView client assets, so clicking the Share button could not produce an observable browser payload from `phx-click`.
- **Fix:** Added hidden JSON payload contract markup and a plain browser click reveal while preserving the existing LiveView server event.
- **Files modified:** `examples/phoenix_host/lib/crosswake_example/bridge_proof_live.ex`
- **Verification:** `npx playwright test e2e/route_tour.spec.ts`; targeted bridge LiveView test.
- **Committed in:** `1028557`

**2. [Rule 2 - Missing Critical] Added deterministic test-only native claim fixture**
- **Found during:** Task 1
- **Issue:** Creating a claim via `mix run` during Playwright conflicted with the running Phoenix endpoint, and the route needs a real claim id for deterministic native fallback coverage.
- **Fix:** Added `/_e2e/native-claim`, compile-gated with the existing test-only E2E routes, to create a claim through app code.
- **Files modified:** `examples/phoenix_host/lib/crosswake_example/e2e/native_claim_controller.ex`, `examples/phoenix_host/lib/crosswake_example/router.ex`
- **Verification:** `npx playwright test e2e/route_tour.spec.ts`; targeted router/controller test slice.
- **Committed in:** `1028557`

**3. [Rule 3 - Blocking] Fixed workflow YAML scalar parsing**
- **Found during:** Task 2 verification
- **Issue:** Existing `run: echo "label: ..."` scalars failed the required Ruby YAML parse.
- **Fix:** Converted those `run` entries to block scalars.
- **Files modified:** `.github/workflows/offline-sync-e2e-gate.yml`
- **Verification:** `/usr/bin/ruby -e 'require "yaml"; YAML.load_file(".github/workflows/offline-sync-e2e-gate.yml"); puts "workflow yaml ok"'`
- **Committed in:** `1028557`

**Total deviations:** 3 auto-fixed (2 missing critical, 1 blocking)

## Verification

- `cd examples/phoenix_host && npm ci && npx playwright install chromium && npx playwright test e2e/route_tour.spec.ts` - PASS
- `node script/check-e2e-honesty.mjs` - PASS
- `/usr/bin/ruby -e 'require "yaml"; YAML.load_file(".github/workflows/offline-sync-e2e-gate.yml"); puts "workflow yaml ok"'` - PASS
- `cd examples/phoenix_host && PORT=4003 MIX_ENV=test mix test test/crosswake_example/bridge_proof_live_test.exs test/crosswake_example/router_test.exs test/crosswake_example/e2e/sync_state_controller_test.exs` - PASS
- `cd examples/phoenix_host && npx playwright test e2e/offline_sync.spec.ts` - PASS

## Issues Encountered

- Combined Playwright run of `offline_sync.spec.ts route_tour.spec.ts` timed out once in the first offline spec and caused the server to exit before route tour started. Both specs passed in isolation afterward; required plan verification is green.
- Local `ruby` shim is unusable without a Ruby version in `.tool-versions`; system Ruby parsed the workflow successfully.

## Known Stubs

None.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: test-only-fixture-route | `examples/phoenix_host/lib/crosswake_example/e2e/native_claim_controller.ex` | New `/_e2e/native-claim` fixture route is compile-gated to `Mix.env() in [:test, :e2e]` through `router.ex`. |

## User Setup Required

None.

## Next Phase Readiness

COLL-01 is ready for follow-on evidence manifest/artifact packaging work. The route-tour proof produces the screenshot directory expected by later manifest packaging and CI upload.

## Self-Check: PASSED

- Created files exist.
- Commit `1028557` exists.
- No tracked files were deleted by the implementation commit.

---
*Phase: 120-collateral-artifact-ci-and-troubleshooting*
*Completed: 2026-06-19*
