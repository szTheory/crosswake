---
phase: 162-physical-iphone-adoption-proof
plan: "06"
subsystem: proof-lane
tags: [elixir, phoenix, swift, evidence, physical-iphone]
requires:
  - phase: 162-05
    provides: descriptor-safe physical evidence publication
provides:
  - closed host configuration for physical proof execution
  - exact owner-free cross-language report parsing and joining
  - evidence-owned promotion assertion and separate entry/replay gate proof
affects: [physical-device-promotion, first-adopter-proof]
tech-stack:
  added: []
  patterns: [trusted producer slots, contract-derived assertion ownership, no-replace evidence checks]
key-files:
  created: [lib/crosswake/proof_lane/physical_iphone_host.ex, script/verify_physical_iphone_report_contract.sh]
  modified: [lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex, lib/crosswake/proof_lane/evidence.ex, examples/phoenix_host/test/crosswake_example/local_first/physical_iphone_authority_test.exs]
key-decisions:
  - "Serialized reports never carry owner authority; trusted callback slots derive it from PhysicalIphoneContract."
  - "PI-REDACTED-PROMOTION is evidence-owned and is unavailable to both producer reports."
  - "TODO-002 and physical-host prerequisites remain a non-passing external gate."
requirements-completed: [DEVICE-01, DEVICE-02, DEVICE-03, DEVICE-04, DEVICE-05, DEVICE-06, DEVICE-07]
coverage:
  - id: D1
    description: Closed canonical physical report parsing, joining, and checked evidence orchestration.
    requirement: DEVICE-06
    verification:
      - kind: integration
        ref: bash script/verify_physical_iphone_report_contract.sh
        status: pass
      - kind: unit
        ref: test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Independent route-entry and replay-disablement authority checks retain queued work.
    requirement: DEVICE-05
    verification:
      - kind: integration
        ref: examples/phoenix_host/test/crosswake_example/local_first/physical_iphone_authority_test.exs
        status: pass
    human_judgment: false
status: complete
---

# Phase 162 Plan 06: Physical Proof Production Wiring Summary

**Closed host-driven physical-proof orchestration now parses owner-free Swift/Phoenix reports, promotes only through checked evidence publication, and keeps physical completion explicitly blocked pending real prerequisites.**

## Performance

- **Tasks:** 3/3
- **Files modified:** 12

## Accomplishments

- Added exact canonical report-envelope parsing with trusted producer slots and a complete pre-promotion join.
- Added closed application-configured host callbacks and `--run --promote --json` evidence orchestration.
- Moved redacted-promotion authority to the evidence boundary and exercised route-entry separately from replay admission.

## Task Commits

1. **Task 1: Execute generated Swift and Phoenix envelopes through the public parser and join** — `0652d62b`
2. **Task 2: Orchestrate closed host reports through checked no-replace promotion** — `79f57ef9`
3. **Task 3: Remove fabricated backend promotion and prove entry/replay disablement independently** — `506ec378`

## Verification

- Core focused suite passed (51 tests).
- `bash script/verify_physical_iphone_report_contract.sh` passed; generated serialization remains advisory and non-promoting.
- Phoenix authority gate passed (8 tests).
- `mix crosswake.proof_lane.physical_iphone --run --promote --json` remains correctly blocked with `PI-PREFLIGHT-INVENTORY`; no physical evidence artifact exists.

## Decisions Made

- Owner identity is contract-derived from the trusted callback slot rather than serialized producer bytes.
- Evidence alone inserts `PI-REDACTED-PROMOTION` after publication and post-publication checking.
- External physical proof is not claimed: TODO-002, eligible host configuration, and a selected physical iPhone remain required.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated evidence decoding for the evidence-owned assertion role**
- **Found during:** Task 2
- **Issue:** Existing physical-evidence decoding accepted only device/backend owners after promotion moved to the evidence boundary.
- **Fix:** Added `:evidence_promotion` to the closed decoder owner set.
- **Files modified:** `lib/crosswake/proof_lane/evidence.ex`
- **Verification:** Focused evidence corpus passed.
- **Committed in:** `79f57ef9`

**Total deviations:** 1 auto-fixed (Rule 1).

## Known Stubs

None. The absent real physical artifact is an explicit external precondition, not a product stub.

## Next Phase Readiness

The production path is ready for an eligible configured host. Physical evidence and support promotion remain blocked until TODO-002, signed host/backend adapters, and a physical iPhone are available.

## Self-Check: PASSED

- All key implementation files exist.
- Task commits `0652d62b`, `79f57ef9`, and `506ec378` exist.
