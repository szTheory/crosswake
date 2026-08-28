---
phase: 162-physical-iphone-adoption-proof
plan: "01"
subsystem: proof-lane
tags: [elixir, mix, ios, physical-iphone, preflight, privacy]
requires:
  - phase: 159-host-reusable-proof-lane
    provides: host-owned proof-lane configuration and closed proof outcomes
  - phase: 160-scoped-replay-and-auth-safety
    provides: scoped replay and backend-authority controls
  - phase: 161-ios-pronunciation-pack-seam
    provides: foreground iOS media-adapter prerequisite
provides:
  - closed physical-iPhone preflight gateway and JSON-only CLI result
  - versioned DEVICE assertion, owner, outcome, and runtime vocabulary
affects: [162-02, 162-03, 162-05, physical-device-evidence]
tech-stack:
  added: []
  patterns: [ordered callback preflight, non-echoing blocked output, owner-tagged assertion manifest]
key-files:
  created:
    - lib/crosswake/proof_lane/physical_iphone_contract.ex
    - lib/crosswake/proof_lane/physical_iphone_preflight.ex
    - lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex
    - test/crosswake/proof_lane/physical_iphone_preflight_test.exs
    - test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs
  modified: []
key-decisions:
  - "Physical proof starts with TODO-002 inventory admission and stops before any host/device callback when that gate is blocked."
  - "Only low-cardinality major.minor iOS runtime lines are accepted; device identifiers and build precision are rejected."
  - "DEVICE assertions have a fixed order and exactly one device-local or backend-authority owner."
patterns-established:
  - "Preflight callbacks return only closed values and collapse exceptions or malformed results to stable blocked rules."
  - "The runner receives only a sanitized contract, never route, device, endpoint, credential, or callback values."
requirements-completed: [DEVICE-01, DEVICE-02, DEVICE-03, DEVICE-04, DEVICE-05, DEVICE-06, DEVICE-07]
coverage:
  - id: D1
    description: Ordered physical-iPhone preflight blocks absent/untrusted prerequisites before runner execution.
    requirement: DEVICE-04
    verification:
      - kind: unit
        ref: test/crosswake/proof_lane/physical_iphone_preflight_test.exs
        status: pass
      - kind: other
        ref: mix crosswake.proof_lane.physical_iphone --preflight-only --json
        status: pass
    human_judgment: false
  - id: D2
    description: Closed physical-iPhone assertion owner, outcome, and runtime contract.
    requirement: DEVICE-05
    verification:
      - kind: unit
        ref: test/crosswake/proof_lane/physical_iphone_preflight_test.exs
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-08-04
status: complete
---

# Phase 162 Plan 01: Physical iPhone Preflight and Contract Summary

**A fail-closed physical-iPhone gateway with JSON-only blocked results and a fixed, privacy-safe DEVICE assertion contract.**

## Performance

- **Duration:** 8 min
- **Completed:** 2026-08-04T21:21:31Z
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Added `mix crosswake.proof_lane.physical_iphone --preflight-only --json`; missing route inventory produces exactly `{"outcome":"blocked","rule_id":"PI-PREFLIGHT-INVENTORY"}` and exits 2.
- Added ordered, side-effect-free readiness checks for inventory, normalized host config, generated lane, physical destination, signing, host, fixture/media adapter, replay, conflict, scope, feature controls, and destination parent.
- Added the versioned `physical_iphone` contract: one low-cardinality iOS runtime grammar and ten fixed owner-tagged DEVICE assertions.

## Task Commits

1. **Task 1: Trace one command through preflight to a gated runner** — `3d146155` (`feat`)
2. **Task 2: Freeze the physical DEVICE assertion and runtime contract** — `881ab5a4` (`feat`)

## Files Created/Modified

- `lib/crosswake/proof_lane/physical_iphone_preflight.ex` — ordered callback preflight with stable non-echoing blocks.
- `lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex` — sole JSON preflight entry point and injectable runner boundary.
- `lib/crosswake/proof_lane/physical_iphone_contract.ex` — closed device class, runtime line, assertion manifest, and report validator.
- `test/crosswake/proof_lane/physical_iphone_preflight_test.exs` — preflight ordering, fail-closed, and contract tests.
- `test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs` — command/runner gateway tests.

## Decisions Made

- Inventory validation is deliberately first: TODO-002 remains a deterministic fail-closed gate and no downstream device/host callback is invoked while it is absent.
- A runner receives only schema version, device class, and fixed assertion IDs; sensitive callback data cannot cross the preflight boundary.
- Simulator, ambiguous destination, callback exceptions, and malformed callback responses never qualify as physical proof.

## Verification

- PASS — focused ExUnit command: 8 tests, 0 failures.
- PASS — CLI machine contract: exact two-key blocked JSON and nonzero exit.
- PASS — `mix format --check-formatted` on all five Plan 162 sources/tests.
- FAIL (pre-existing/out of scope) — full `mix test` reports existing navigation-topology and native-evidence drift failures, then a compile error in `phase74_offline_draft_recovery_proof_test.exs`. None involve files changed by this plan.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The physical run remains intentionally blocked: sanitized TODO-002 route rows, a signed physical iPhone, and a runnable adopter host/backend are external prerequisites. The command records none of their values and does not treat simulator or unit-test injection as proof.
- The repository-wide suite is currently red for unrelated manifest/navigation and checked-in native-project drift; the focused Plan 162 verification is green.

## Known Stubs

None.

## Next Phase Readiness

Plans 162-02 and 162-03 can consume the stable preflight and assertion IDs. A real physical run must remain blocked until TODO-002 validates and the signed host/device/backend prerequisites are available.

## Self-Check: PASSED

- All five plan files exist.
- Task commits `3d146155` and `881ab5a4` exist in Git history.

---
*Phase: 162-physical-iphone-adoption-proof*
*Completed: 2026-08-04*
