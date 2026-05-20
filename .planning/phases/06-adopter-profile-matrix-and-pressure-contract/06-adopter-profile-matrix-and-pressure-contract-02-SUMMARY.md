---
phase: 06-adopter-profile-matrix-and-pressure-contract
plan: 02
subsystem: example-host-contract
tags: [docs, examples, proof, verification]
requires:
  - phase: 06-01
    provides: locked public adopter-profile guide
  - phase: 05-08
    provides: checked-in example-host proof posture
provides:
  - shared example-host lane contract
  - profile-contract verification scaffold
  - proof test for phase 6 boundary drift
requirements-completed: [PROF-02]
completed: 2026-05-17
---

# Phase 6 Plan 02: Shared Host And Proof Scaffold Summary

Phase 6 now defines how later exemplar phases extend one shared example host plus the paired native proof hosts, instead of drifting into multiple sample apps. The new verification scaffold checks doc and lane-boundary drift without trying to implement the Phase 7-10 exemplar routes early.

## Accomplishments

- Added `examples/phoenix_host/README.md` to lock the shared-host lane contract, route budgets, route-class boundaries, failure vocabulary focus, and proof-extension rules.
- Added `script/verify_adopter_profile_contract.sh` to verify locked profile names, shared-host posture, failure vocabulary, route budgets, and reuse of the Phase 5 example-host proof entrypoint.
- Added `test/crosswake/proof/adopter_profile_contract_test.exs` as the ExUnit wrapper for the new verification scaffold.

## Verification

- `bash script/verify_adopter_profile_contract.sh`
- `mix test test/crosswake/proof/adopter_profile_contract_test.exs`
