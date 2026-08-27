---
phase: 162-physical-iphone-adoption-proof
plan: "13"
subsystem: physical-iphone-proof
tags: [ios, swift, elixir, proof-lane, serialization, privacy]
requires:
  - phase: 162-12
    provides: value-carrying reference-host free-form replay seam
provides:
  - Generated value-forwarding physical host adapter contracts with owner-free reports
  - Serialization-only simulator envelope validation through the production Elixir parser
  - Owner-disjoint production parser/join integration coverage for passed physical fixtures
affects: [physical-iphone-proof, device-requirements, host-reusable-proof-lane]
tech-stack:
  added: []
  patterns: [contract-only Swift forwarding value, unavailable simulator serialization gate, production parser/join integration]
key-files:
  created: []
  modified:
    - priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex
    - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex
    - script/verify_physical_iphone_report_contract.sh
    - test/crosswake/proof_lane/physical_iphone_report_contract_script_test.exs
key-decisions:
  - "Generated contract tests forward one fixed nonempty value only in Swift process memory; reports remain the three-key owner-free envelope."
  - "The simulator CLI validates only an exact unavailable device-local envelope and cannot join, promote, or publish physical evidence."
  - "All-passed physical joining is covered separately by real production Elixir parser and join functions using owner-disjoint synthetic fixtures."
requirements-completed: [DEVICE-02, DEVICE-06]
coverage:
  - id: D1
    description: Generated physical proof contracts forward the contract-only value once while preserving an owner-free unavailable simulator report.
    requirement: DEVICE-02
    verification:
      - kind: unit
        ref: mix test test/crosswake/proof_lane/template_contract_test.exs --max-failures 1
        status: pass
    human_judgment: false
  - id: D2
    description: The advisory simulator verifier parses only unavailable device-local assertions and never joins or promotes them; production parser/join semantics are separately exercised.
    requirement: DEVICE-06
    verification:
      - kind: integration
        ref: mix test test/crosswake/proof_lane/physical_iphone_report_contract_script_test.exs test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs --max-failures 1
        status: pass
      - kind: integration
        ref: script/verify_physical_iphone_report_contract.sh
        status: pass
    human_judgment: false
metrics:
  duration: 10m
  completed: 2026-08-27
status: complete
---

# Phase 162 Plan 13: Honest Physical Report Serialization Summary

**Generated iOS proof contracts now forward a test-only free-form value without exporting it, while simulator envelopes are verified as unavailable serialization evidence rather than physical success.**

## Accomplishments

- Propagated Plan 12's value-carrying free-form seam through generated `PhysicalIphoneHostAdapter` contracts and recording tests, keeping the fixed contract-only value in Swift test memory and out of reports.
- Made contract-mode output explicitly assert the exact schema, physical class, ordered device-local IDs, and all-unavailable outcomes before it is emitted.
- Replaced the advisory CLI's producer and physical join path with production parsing of the exact unavailable simulator envelope; the result remains `PI-CONTRACT-SERIALIZATION` only.
- Added integration coverage that runs the real parser and owner-disjoint join with synthetic passed fixtures, and confirms wrong ownership, unavailable entries, malformed bytes, and partial records cannot join.

## Task Commits

1. **Task 1: Propagate value-carrying generated contracts and label simulator output honestly** — `9205d3e0` (RED) and `13ac17cf` (GREEN).
2. **Task 2: Execute the real serialization parser and owner-disjoint join in integration proof** — `ae47c1da` (RED) and `14ddf0fb` (GREEN).

## Files Created/Modified

- `priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex` — value-carrying host adapter contract and fixed private contract-only argument.
- `priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex` — recording-adapter forwarding, report exclusion, and explicit unavailable contract-mode assertions.
- `script/verify_physical_iphone_report_contract.sh` — real production parser validation for the unavailable simulator envelope, with no producer, join, promotion, or evidence destination.
- `test/crosswake/proof_lane/physical_iphone_report_contract_script_test.exs` — real-Mix script coverage plus production parser/join integration regressions.
- `test/crosswake/proof_lane/template_contract_test.exs` — source-level generated contract regression.

## Decisions Made

- A fixed contract-only value is sufficient to prove generated argument forwarding without adding payload-bearing report fields or retaining sensitive data.
- Simulator success is explicitly advisory serialization validation, never a physical-device result or a support/evidence promotion input.
- The all-passed join keeps its production physical semantics and is tested independently from simulator output.

## TDD Gate Compliance

- RED commit `9205d3e0` precedes GREEN commit `13ac17cf` for generated value forwarding.
- RED commit `ae47c1da` precedes GREEN commit `14ddf0fb` for the real parser serialization path.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Reconciled the stale planning-state frontmatter counter.**
- **Found during:** Plan closeout.
- **Issue:** The canonical state advance command updated the rendered current-position plan to 14 but preserved frontmatter `current_plan` as 13.
- **Fix:** Updated the frontmatter counter and activity description to match the completed plan and canonical rendered state.
- **Files modified:** `.planning/STATE.md`.
- **Verification:** State and roadmap both report Plan 14 / 13 of 15 completed.

**Total deviations:** 1 (Rule 1 planning-state metadata repair).

## Known Stubs

None.

## Verification Evidence

- `mix test test/crosswake/proof_lane/template_contract_test.exs --max-failures 1` — 18 tests passed, 0 failures.
- `mix test test/crosswake/proof_lane/physical_iphone_report_contract_script_test.exs test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs --max-failures 1` — 9 tests passed, 0 failures.
- `script/verify_physical_iphone_report_contract.sh` — passed with its generated simulator lane and emitted only the serialization-scoped result; no physical device was run.

## Next Phase Readiness

CR-02's advisory serializer path is executable and non-promoting. The narrow physical-iPhone boundary, Android freeze, host ownership, and privacy exclusions remain unchanged.

## Self-Check: PASSED

- All five modified source/test artifacts and this summary exist.
- RED/GREEN commits `9205d3e0`, `13ac17cf`, `ae47c1da`, and `14ddf0fb` exist in history.

*Phase: 162-physical-iphone-adoption-proof*
*Completed: 2026-08-27*
