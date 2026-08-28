---
phase: 159-host-reusable-proof-lane
plan: "19"
subsystem: testing
tags: [elixir, phoenix, typescript, proof-lane, input-validation]
requires:
  - phase: 159-17
    provides: "Closed proof-lane configuration and generator lifecycle"
provides:
  - "Canonical rejection of every backslash byte in rendered proof endpoint paths"
  - "Direct, application, and selected-config regressions proving failure precedes generator authority"
affects: [proof-lane-generator, phase-159-verification, phoenix-host-e2e]
tech-stack:
  added: []
  patterns:
    - "Construct byte-sensitive validation canaries at runtime with <<92>>."
key-files:
  created: []
  modified:
    - lib/crosswake/proof_lane/config.ex
    - test/crosswake/proof_lane/config_test.exs
    - test/mix/tasks/crosswake_gen_proof_lane_test.exs
key-decisions:
  - "Keep endpoint rendering safe through the existing closed Config grammar rather than adding renderer escaping."
requirements-completed: [PROOF-01, PROOF-02]
coverage:
  - id: D1
    description: "Proof-lane sync and evidence endpoints reject exactly one backslash byte without echoing its value."
    requirement: PROOF-02
    verification:
      - kind: unit
        ref: "test/crosswake/proof_lane/config_test.exs#rejects TypeScript-unsafe endpoint characters without echoing them"
        status: pass
    human_judgment: false
  - id: D2
    description: "Direct structs, application configuration, and selected config fail before proof-lane rendering or filesystem changes, while valid output retains its TypeScript contract."
    requirement: PROOF-01
    verification:
      - kind: integration
        ref: "test/mix/tasks/crosswake_gen_proof_lane_test.exs#direct unsafe configs fail closed before generator actions inspect destinations"
        status: pass
      - kind: integration
        ref: "test/mix/tasks/crosswake_gen_proof_lane_test.exs#application and selected config reject unsafe endpoints before output-root creation"
        status: pass
      - kind: other
        ref: "npm --prefix examples/phoenix_host run typecheck:offline-route-proof"
        status: pass
    human_judgment: false
duration: 7m
completed: 2026-08-01
status: complete
---

# Phase 159 Plan 19: Single-Backslash Endpoint Boundary Summary

**Proof-lane endpoint paths now reject every backslash byte at canonical normalization, before raw EEx rendering or generator filesystem authority.**

## Performance

- **Duration:** 7m
- **Tasks:** 1/1
- **Files modified:** 3

## Accomplishments

- Added runtime-constructed one-byte backslash regressions for both endpoint keys, avoiding accidental double-backslash coverage.
- Rejected byte 92 through the sole endpoint predicate, keeping `PL-CONFIG-VALUE` key/remediation errors non-echoing.
- Preserved valid TypeScript generation plus existing missing-only rerun and concurrent-generator behavior.

## Task Commits

1. **Task 1: Reject one backslash through every configuration and generation seam** — `83f5f287` (test), `4ef78b53` (fix)

## Files Created/Modified

- `lib/crosswake/proof_lane/config.ex` — closes the host-local endpoint grammar over a single backslash character.
- `test/crosswake/proof_lane/config_test.exs` — asserts direct normalization rejects a runtime-created byte-92 value for each endpoint.
- `test/mix/tasks/crosswake_gen_proof_lane_test.exs` — asserts direct, application, and selected-config generator seams fail without filesystem changes.

## Decisions Made

- Preserve the raw EEx template and make it safe through the already canonical closed input grammar; no encoder, alternate config format, or endpoint mode was introduced.

## Deviations from Plan

None - plan executed exactly as written.

## Verification

- `mix test test/crosswake/proof_lane/config_test.exs test/mix/tasks/crosswake_gen_proof_lane_test.exs` — passed (focused endpoint, generator lifecycle, rerun, and concurrency regressions).
- `npm --prefix examples/phoenix_host run typecheck:offline-route-proof` — passed.

## Known Stubs

None.

## Next Phase Readiness

The endpoint rendering boundary is closed across all configured entry paths. Phase 159 can continue with its final bounded plan.

## Self-Check: PASSED

- Modified files exist and TDD commits `83f5f287` and `4ef78b53` are present.
