---
phase: 162-physical-iphone-adoption-proof
plan: "12"
subsystem: physical-iphone-proof
tags: [ios, phoenix, scoped-replay, privacy, physical-proof]
requires:
  - phase: 162-11
    provides: prior physical-evidence reconciliation and narrow support truth
provides:
  - Host-private, scope-partitioned free-form persistence and recovery in the reference iOS study lane
  - Foreground Phoenix replay with duplicate idempotency, exactly-one effect confirmation, and accepted-only drain
  - A passing signed physical-iPhone regression with closed aggregate-only output
affects: [physical-iphone-proof, scoped-replay, device-requirements]
tech-stack:
  added: []
  patterns: [host-private scoped journal, session-fenced replay, closed physical-report envelope]
key-files:
  created:
    - examples/phoenix_host/priv/repo/migrations/20260826190000_add_reference_free_form_answer_to_review_events.exs
  modified:
    - examples/phoenix_host/native/ios/CrosswakeProofLane/ProofLaneDriver.swift
    - examples/phoenix_host/native/ios/CrosswakeProofLane/ProofLaneApp.swift
    - examples/phoenix_host/native/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift
    - examples/phoenix_host/lib/crosswake_example/physical_iphone_proof_host.ex
    - examples/phoenix_host/lib/crosswake_example/local_first/physical_iphone_authority.ex
key-decisions:
  - "The reference host owns the sensitive journal, opaque scope lifecycle, and foreground replay transport; Crosswake core remains outside the stored payload boundary."
  - "A queued record drains only after accepted replay, same-ID duplicate confirmation, and exactly one scoped Phoenix domain effect."
  - "Physical output remains a closed aggregate envelope; this summary records no submitted value, scope, mutation, account, network, signing-team, or stable device identifier."
requirements-completed: [DEVICE-02, DEVICE-04, DEVICE-06]
coverage:
  - id: D1
    description: Scoped free-form persistence, relaunch recovery, replay, duplicate idempotency, and accepted-only drain in the reference physical study lane.
    requirement: DEVICE-02
    verification:
      - kind: integration
        ref: "examples/phoenix_host: MIX_ENV=test mix test test/crosswake_example/physical_iphone_proof_host_test.exs test/crosswake_example/local_first/physical_iphone_authority_test.exs --max-failures 1"
        status: pass
      - kind: automated_ui
        ref: "signed physical-iPhone regression, closed aggregate report"
        status: pass
    human_judgment: false
  - id: D2
    description: Host-selected scope partitions remain retained but fenced across unavailable, logout, and account-switch transitions.
    requirement: DEVICE-04
    verification:
      - kind: unit
        ref: examples/phoenix_host/native/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift
        status: pass
      - kind: integration
        ref: "focused Phoenix physical proof and authority tests"
        status: pass
    human_judgment: false
  - id: D3
    description: Physical report and retained proof output expose only closed assertion outcomes, with sensitive replay material kept process-local.
    requirement: DEVICE-06
    verification:
      - kind: integration
        ref: "focused Phoenix physical proof and authority tests"
        status: pass
      - kind: automated_ui
        ref: "signed physical-iPhone regression, closed aggregate report"
        status: pass
    human_judgment: false
metrics:
  duration: closeout continuation
  completed: 2026-08-27
status: complete
---

# Phase 162 Plan 12: Scoped Free-Form Physical Replay Summary

**The reference iOS study lane now preserves one host-scoped free-form value through relaunch and foreground Phoenix replay, with duplicate-safe accepted-only draining and privacy-closed physical proof.**

## Accomplishments

- Replaced the Boolean free-form substitute with a host-private, scope-partitioned journal and recovery path; unavailable, logout, and account-switch states fence retained records rather than exposing or replaying them.
- Connected the recovered value to the existing authorized Phoenix replay path, requiring an accepted receipt, same-ID duplicate handling, and one scoped domain effect before removing the local outbox record.
- Added deterministic Swift/Phoenix contracts and corrected the physical lane's compile, launch-environment, local-network, and cookie-handling defects.
- Confirmed the current signed physical-iPhone callback passed with five assertions, zero failures, and a passing privacy verdict. The host used the test environment, a device-reachable non-loopback URL, and private ephemeral logs; no sensitive runtime values are recorded here.

## Task Commits

1. **Task 1: Carry one free-form value through host scope, relaunch, Phoenix replay, and drain** — `f3ca5a8b` (RED contract), `757ced52` (scoped journal and launch inputs), `e3f87173` (Phoenix replay/effect binding), `60a41313` (recovery contracts), `24490d9b` (Swift test compilation repair), `3b87a2e1` (launch input forwarding), `119e3ad7` (physical local networking), `3e6b8b2d` (session cookie retention).

## Files Created/Modified

- `examples/phoenix_host/native/ios/CrosswakeProofLane/ProofLaneDriver.swift` — host-private journal, scope fencing, and replay transport.
- `examples/phoenix_host/native/ios/CrosswakeProofLane/ProofLaneApp.swift` — value-carrying submission and relaunch recovery wiring.
- `examples/phoenix_host/native/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift` — signed physical-flow assertions using the closed report envelope.
- `examples/phoenix_host/lib/crosswake_example/physical_iphone_proof_host.ex` — validated ephemeral launch configuration and physical host setup.
- `examples/phoenix_host/lib/crosswake_example/e2e/replay_authority.ex` — host-owned physical fixture/session lifecycle source.
- `examples/phoenix_host/lib/crosswake_example/local_first/physical_iphone_authority.ex` — verifies the device-created scoped effect and duplicate idempotency.
- `examples/phoenix_host/priv/repo/migrations/20260826190000_add_reference_free_form_answer_to_review_events.exs` — bounded reference-host answer field for the authorized replay path.

## Decisions Made

- Kept sensitive payload persistence, scope selection, and replay transport within the reference host rather than widening Crosswake into generic native storage or sync.
- Used the existing session-authorized replay endpoint and domain authority; no bypass endpoint or client-manufactured backend proof was added.
- Preserved the existing closed physical report shape, so proof output contains assertion IDs and outcomes only.

## TDD Gate Compliance

- RED commit `f3ca5a8b` introduced the focused value-forwarding contract.
- GREEN commits `757ced52` and `e3f87173` implemented persistence and replay.
- Follow-up contract coverage landed in `60a41313`; subsequent repairs corrected the real signed-device path.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Repaired the Swift contract-test compile failure.**
- **Found during:** Task 1 physical-lane verification.
- **Issue:** A fileprivate helper boundary and an `await` in an XCTest assertion autoclosure prevented the focused Swift tests from compiling.
- **Fix:** Restructured the test interaction across the helper boundary.
- **Files modified:** `ProofLaneContractTests.swift`.
- **Committed in:** `24490d9b`.

**2. [Rule 1 - Bug] Forwarded validated physical launch inputs into the app process.**
- **Found during:** Task 1 signed physical-flow verification.
- **Issue:** The UI test omitted the validated host scope and replay configuration when launching the app.
- **Fix:** Forwarded the ephemeral host-owned inputs through the UI-test launch environment.
- **Files modified:** `ProofLaneUITests.swift`, `physical_iphone_proof_host.ex`, and its focused test.
- **Committed in:** `3b87a2e1`.

**3. [Rule 2 - Missing critical functionality] Configured physical local-network transport.**
- **Found during:** Task 1 signed physical-flow verification.
- **Issue:** The device lane needed the Xcode environment injection and local-network transport declaration required for its already-authorized test-host connection.
- **Fix:** Added the narrow physical-proof networking configuration and regression coverage.
- **Files modified:** `physical_iphone_proof_host.ex`, `PhysicalProofInfo.plist`, and its focused test.
- **Committed in:** `119e3ad7`.

**4. [Rule 1 - Bug] Retained the Phoenix replay session cookie.**
- **Found during:** Task 1 signed physical-flow verification.
- **Issue:** The native foreground transport did not explicitly accept the session cookie issued by the existing replay-session route.
- **Fix:** Retained the cookie for the bounded replay sequence and added contract coverage.
- **Files modified:** `ProofLaneDriver.swift`, `ProofLaneContractTests.swift`.
- **Committed in:** `3e6b8b2d`.

**Total deviations:** 4 (3 Rule 1 bug fixes, 1 Rule 2 critical configuration fix).

## Verification Evidence

- `MIX_ENV=test mix test test/crosswake_example/physical_iphone_proof_host_test.exs test/crosswake_example/local_first/physical_iphone_authority_test.exs --max-failures 1` — 10 tests passed, 0 failures (current closeout run).
- Signed physical-iPhone callback after `3e6b8b2d` — passed; 5 assertions, 0 failures, privacy pass. This was host-owned, test-environment evidence with a device-reachable non-loopback URL and private ephemeral logs; it was not rerun for closeout.
- Commit inspection confirmed the full Plan 12 lineage and dedicated Swift/Phoenix/physical test coverage. No Android, background replay, generic storage/sync, or new UI breadth was introduced.

## Issues Encountered

- The pre-existing STATE.md frontmatter already identified Plan 12 while its rendered current-position line still said Plan 1. The canonical advance command therefore advanced the stale rendered value. Closeout repaired that internal planning-record inconsistency to Plan 13 and left requirements unchanged because DEVICE-02, DEVICE-04, and DEVICE-06 were already checked by Plan 162-11.

## Known Stubs

None.

## Next Phase Readiness

Plan 162-13 may use the repaired, passing physical lane as its narrow input. This closeout does not widen the proof beyond one first-adopter iOS study flow or change the Android-frozen and non-generic-sync boundaries.

## Self-Check: PASSED

- All eight Plan 12 production commits exist in history.
- The summary and every key source/test artifact listed above exist.
- The current focused Phoenix verification passed; the supplied current-turn physical callback is recorded only as privacy-safe aggregate evidence.
