---
phase: 180-bounded-digital-twin-demonstration
plan: 06
subsystem: twin run machinery (fault boundary, producers, journey, UI test target)
status: complete
requirements: [TWIN-01, TWIN-02, TWIN-03, TWIN-04, TWIN-05, TWIN-06]
requirements_completed: []
tags: [twin, fault-boundary, producers, xcuitest, capture-prevention]
key-files:
  created:
    - lib/crosswake/proof_lane/twin_fault_boundary.ex
    - lib/crosswake/proof_lane/twin_producers.ex
    - lib/crosswake/proof_lane/twin_journey.ex
    - test/crosswake/proof_lane/twin_fault_boundary_test.exs
    - test/crosswake/proof_lane/twin_producers_test.exs
    - test/crosswake/proof_lane/twin_journey_test.exs
    - examples/phoenix_host/native/ios/crosswake_shell/CrosswakeShell/TwinHostDriver.swift
    - examples/phoenix_host/native/ios/crosswake_shell/CrosswakeShellUITests/TwinJourneyUITests.swift
    - examples/phoenix_host/native/ios/crosswake_shell/CrosswakeShellUITests/TwinCaptureCanaryUITests.swift
    - examples/phoenix_host/native/ios/crosswake_shell/TwinJourney.xctestplan
    - examples/phoenix_host/native/ios/crosswake_shell/CrosswakeShellUnit.xctestplan
  modified:
    - lib/mix/tasks/crosswake.proof_lane.verify_twin.ex
    - lib/crosswake/proof_lane/twin_receipt.ex
    - test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs
    - examples/phoenix_host/native/ios/crosswake_shell/CrosswakeShell/StudyWebViewController.swift
    - examples/phoenix_host/native/ios/crosswake_shell/CrosswakeShell/CrosswakeShellApp.swift
    - examples/phoenix_host/native/ios/crosswake_shell/CrosswakeShell.xcodeproj/project.pbxproj
    - examples/phoenix_host/native/ios/crosswake_shell/CrosswakeShell.xcodeproj/xcshareddata/xcschemes/CrosswakeShell.xcscheme
plan_head_before: da53c54db06e54be5a80fb4be144a70d3fed36a5
plan_head_after: da53c54db06e54be5a80fb4be144a70d3fed36a5
actuals:
  tokens: 90000
  tasks: 3
  commits: 0
---

# Phase 180 Plan 06: Twin run machinery Summary

Everything the single twin run needs now exists and was exercised in pieces: a loopback fault boundary that holds the origin, six owner producers that cover exactly the 49 roster ids, the identity freeze and in-run negative controls, the journey orchestration wired into `verify_twin`, and an XCUITest journey with a capture canary under a keepNever test plan. The full twin was not run as a whole; 180-07 does that once.

## What was checked and what happened

- Gate check passed before the first edit and again at the end.
- **Task 1 (boundary):** 12 tests, 0 failures. The boundary takes over the held origin socket, relays real HTTP unchanged, refuses at the transport (request line read, connection closed, no response), counts passed and refused per path class and epoch, drops the first replay response after upstream handled it, accepts only the closed control commands (others get 422), calls the snapshot exactly once per epoch change, and exposes only the SHA-256 of the served `offline_study.js`. `verify_upstream_owner` is a read-only `lsof` check and signals nothing. `mix.exs`/`mix.lock` unchanged.
- **Task 2 (producers, freeze, journey):** the five Elixir test files together run 66 tests, 0 failures (producers 21, journey 6, boundary 12, receipt 11, verify_twin 16). Union of producer ids is the 49-id roster, once each. Totals per owner: host_adapter 8, webview 18, app_process 2, fault_boundary 3, phoenix_ecto 10, runner 8 (the runner also emits the derived TW-T10-02 so the union is complete; `derive/3` still computes it itself). Nine non-comment `TwinReceipt.observation` call sites. `freeze/3` was also run against the real candidate (da53c54): it reproduced the identity values and a backend build digest (`1e8ac067...`) equal to what the running backend reported live.
- **Task 3 (UI tests):** `mix crosswake.gen.shell ios --check` current (under `MIX_ENV=test`); test plan sets all three lifetimes to keepNever; scheme references it; no attachment or screenshot code in the UI test sources; `build-for-testing` exit 0. The 23 existing unit tests still pass (via the new `CrosswakeShellUnit` plan).

## Live checks done during development (not the official run)

I ran each case method once against a hand-started Phoenix and boundary in a throwaway simulator, then deleted everything. All five methods passed and the app's own channel files and the backend counters showed what the roster expects:

- c1: install T01 all passed; offline saves of one rating and one free-form answer (outbox 2); playback from installed bytes; relaunch with the first process gone; replay with the first response dropped, then a duplicate delivery (admitted 4, duplicates 2, accepted rows exactly 2); outbox 0 and "saved to your account" after.
- c2: refused install, play denied `media_missing`; after clearing and preparing `media_corrupt`, a fresh launch rejects the download (T01-02 failed, T04-05 passed).
- c3: rejection and conflict both held for review; retry offered, then withheld while replay was disabled, then offered again. c4: switch produced one `scope_mismatch` denial, no new rows, island fenced, retained work unchanged. c5: entry disabled, then replay disabled, retained work unchanged.
- **Capture canary:** with keepNever the canary fails with zero exported attachments. A control run with the plan's lifetimes removed exported one screen recording, so the check can detect capture. Plan file restored and re-verified.
- The `WKAppBoundDomains = example.com` placeholder did not block the page probes or the bridge on 127.0.0.1, so no generator change was needed.

## Deviations from Plan

1. **[Rule 3] Plan verify uses `mix crosswake.gen.shell ios --check`; run under `MIX_ENV=test`.** The plain dev run reports stale (180-05 finding). Under test it is current.
2. **[Rule 2/3] Host driver added (host-owned, not in the file list):** `TwinHostDriver.swift`, plus edits to `StudyWebViewController.swift` and `CrosswakeShellApp.swift`. Without it nothing in the app establishes the synthetic session, activates the island scope, signals connectivity back, or fences on denial, so the journey could not complete. It is gated by `CROSSWAKE_TWIN_OBSERVE=1`, uses a real WebView request as its reachability probe, reads only the boundary's integer epoch from the control port, and writes no observation. The scope-fence session switch is triggered by the `scope_fence` epoch (so the boundary's closed command set did not grow). A one-bit `twin-ready` accessibility marker tells the UI test when the document is open and activated. The failed-load retry exists so a launch under refusal recovers when traffic passes.
3. **[Rule 1] Probe order.** Outbox counts are now recorded before the island state, and only for an activated document, so "saved to your account" can never be sampled ahead of the drained count and the first outbox sample of a launch is not a pre-activation zero.
4. **[Rule 2] Receipt causes added** (`backend_listener_not_owned`, `capture_not_prevented`, `attachment_check_unavailable`, `session_control_unavailable`) in `twin_receipt.ex`; the plan names them but the closed list lacked them.
5. **`verify_twin` shape:** `--identity` is required unless a test injects producers (existing tests pass an explicit empty producer instead of relying on the old default). A preflight block now derives and writes an all-blocked receipt.
6. **`CrosswakeShellUnit.xctestplan`** added so the scheme (now plan-driven) can still run the 23 unit tests.
7. **Identity join construction.** The receipt's join formulas are fixed, so observed joins are built from the same part lists (`observe_identities/2`); installed build compares the executable before and after c1 for stability rather than against a pre-frozen binary hash.
8. **`TEST_RUNNER_` port** is passed both as an argument (per plan) and as an environment entry, which is what xcodebuild actually reads.
9. A simulator keyboard hang appeared once in c3 (typing never completed); it did not recur after rebooting the simulator. The official run creates a fresh simulator.

## Unknowns and risks for 180-07

- The Elixir journey glue (`TwinJourney.run`: backend start, boundary hand-off, simulator create/delete, canary and per-case attachment export, cleanup) is covered by unit tests of its pure parts and by the manual live runs above, but was not executed end to end.
- c1 asserts T05-01 needs the first pid absent via `/bin/ps`; only `TwinJourney` computes it.
- Cases use fixed sleeps in places; a slow machine could need a rerun with a new run root.
- Run with `MIX_ENV=test` generation facts from 180-05; origin must be free on 127.0.0.1:4790.
- Coverage-probe rows for TWIN-05/06 remain flagged for gsd-verifier. Open note kept: `OfflineController.index` uses island route id `study-session` while the bridge uses `offline-study`; not renamed.

## Known Stubs

None.

## Threat Flags

None beyond the plan's register; the boundary stores counters and one public digest only, and binds only 127.0.0.1.

## Self-Check: PASSED

- All listed files exist in the candidate; staged files in the recovery checkout: 0; no simulator named crosswake-phase180 remains; ports 4790/4801 free; derived data and result bundles removed.
