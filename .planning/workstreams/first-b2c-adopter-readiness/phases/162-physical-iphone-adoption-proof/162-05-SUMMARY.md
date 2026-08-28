---
phase: 162-physical-iphone-adoption-proof
plan: "05"
subsystem: proof-lane-evidence
tags: [ios, physical-iphone, evidence, privacy, atomic-publication]
requires:
  - phase: 162-03
    provides: closed physical-iPhone report contract and fail-closed preflight
  - phase: 162-04
    provides: closed learner recovery surface and accessibility backstops
provides:
  - physical-only canonical evidence validation with sanitized run-contract hashing
  - a documented fail-closed physical promotion gate pending actual external prerequisites
affects: [physical-device-evidence, support-matrix, first-adopter-release]
tech-stack:
  added: []
  patterns: [physical evidence allowlist, sanitized canonical source hashing, destination-specific promotion denial]
key-files:
  created: []
  modified:
    - lib/crosswake/proof_lane/evidence.ex
    - test/crosswake/proof_lane/evidence_test.exs
key-decisions:
  - "Only a complete passed physical_iphone record with one bounded iOS runtime line and one sanitized physical run-contract hash may publish into the physical evidence destination."
  - "Absent external prerequisites remain a closed blocked state; they do not create a retained artifact or widen support truth."
requirements-completed: []
coverage:
  - id: D1
    description: "Physical evidence accepts only the fixed complete passed assertion manifest, a bounded runtime line, and an approved sanitized run-contract hash."
    requirement: DEVICE-06
    verification:
      - kind: unit
        ref: "mix test test/crosswake/proof_lane/evidence_test.exs --max-failures 1"
        status: pass
      - kind: unit
        ref: "mix test test/crosswake/proof_lane --exclude physical_device --max-failures 1"
        status: pass
    human_judgment: false
  - id: D2
    description: "A dated retained record and narrow support claim are published only after an actual fresh signed physical-iPhone run."
    requirement: DEVICE-07
    verification:
      - kind: other
        ref: "mix crosswake.proof_lane.physical_iphone --preflight-only --json"
        status: fail
    human_judgment: true
    rationale: "The external route, signed host/backend, media controls, and selected physical device are unavailable; no simulated or advisory run may substitute."
metrics:
  duration: 24min
  completed: 2026-08-04
status: blocked
---

# Phase 162 Plan 05: Physical iPhone Promotion Gate Summary

**Closed physical-iPhone evidence validation is shipped; promotion and support publication remain blocked until one fresh signed device run satisfies the external preflight.**

## Performance

- **Completed work:** Task 1 of 2
- **Blocked task:** Task 2, external physical-run precondition
- **Files modified:** 2

## Accomplishments

- Added a physical-only evidence variant that requires the exact ordered PI assertion manifest, all-passed outcome, bounded iOS runtime line, and a canonical sanitized physical run-contract hash.
- Preserved legacy evidence behavior while rejecting nonphysical evidence at the fixed `physical_iphone` destination.
- Verified the deterministic evidence and proof-lane regression suites without claiming a device result.

## Task Commits

1. **Task 1: Extend canonical evidence and promotion for physical_iphone** — `4067c782` (`test` RED), `0a37e4ef` (`feat`)
2. **Task 2: Run, promote, seal, and publish the narrow support truth** — not run; external precondition blocked.

## Verification

- PASS — `mix test test/crosswake/proof_lane/evidence_test.exs --max-failures 1` (27 tests)
- PASS — `mix test test/crosswake/proof_lane --exclude physical_device --max-failures 1` (65 tests)
- BLOCKED (expected) — `mix crosswake.proof_lane.physical_iphone --preflight-only --json` returned only `{"outcome":"blocked","rule_id":"PI-PREFLIGHT-INVENTORY"}` with exit status 2.
- CONFIRMED — the fixed physical artifact and completion marker are absent; no support renderer, generated guide, coverage declaration, or validation ledger was altered.

## Deviations from Plan

None - Task 1 executed as specified. Task 2 was not started because its explicit precondition is unmet.

## Issues Encountered

Task 2 requires an eligible sanitized TODO-002 route row, a current generated lane, runnable signed adopter host/backend with fixture, media, replay, recovery, scoped-session, and feature-control authority, plus a selected physical iPhone. The read-only preflight fails at the first unavailable prerequisite. Per D-04 through D-06, no artifact, completion marker, promotion, support claim, API seal, or validation result was fabricated.

## Known Stubs

None. The missing host/device integration is an intentional fail-closed external prerequisite, not a stub or passing proof.

## Next Phase Readiness

After all external prerequisites are genuinely available, rerun the signed physical command once, verify the promoted directory using `Evidence.check/2`, then and only then update support truth, the generated guide, coverage seal, and validation ledger from the fresh result.

## Self-Check: PASSED

- `lib/crosswake/proof_lane/evidence.ex` and `test/crosswake/proof_lane/evidence_test.exs` exist.
- Commits `4067c782` and `0a37e4ef` exist in Git history.
- The physical evidence JSON and `.complete` marker are absent, as required while preflight is blocked.

---
*Phase: 162-physical-iphone-adoption-proof*
*Completed: 2026-08-04*
