---
phase: 159-host-reusable-proof-lane
plan: "05"
subsystem: proof-lane filesystem confinement
tags: [elixir, phoenix, generator, filesystem-safety, tdd]
requires: [159-02]
provides: [canonical-ios-shell-root, checked-host-root-derivation, direct-config-confinement]
affects: [PROOF-01, PROOF-02, phase-160, phase-162]
tech-stack:
  added: []
  patterns: [normalized-path-contract, fail-closed-direct-struct-validation, missing-only-generation]
key-files:
  created: []
  modified:
    - lib/crosswake/proof_lane/config.ex
    - lib/crosswake/proof_lane/generator.ex
    - test/crosswake/proof_lane/config_test.exs
    - test/mix/tasks/crosswake_gen_proof_lane_test.exs
key-decisions:
  - The sole valid iOS shell-root layout is a normalized absolute host/native/ios path whose derived host root is not filesystem root.
  - Generator actions revalidate direct Config structs through Config.host_root/1 before deriving or inspecting destinations.
requirements-completed: [PROOF-01, PROOF-02]
coverage:
  - id: D1
    description: Canonical non-root native/ios configuration validation with non-echoing errors.
    requirement: PROOF-02
    verification:
      - kind: unit
        ref: test/crosswake/proof_lane/config_test.exs#accepts only a normalized non-root native/ios shell root
        status: pass
    human_judgment: false
  - id: D2
    description: Direct-struct confinement and preserved rerun, interruption, and parallel generation behavior.
    requirement: PROOF-01
    verification:
      - kind: integration
        ref: test/mix/tasks/crosswake_gen_proof_lane_test.exs#direct unsafe configs fail closed before generator actions inspect destinations
        status: pass
    human_judgment: false
metrics:
  duration: 14m
  completed: 2026-07-31
  tasks_completed: 2
  files_changed: 4
status: complete
---

# Phase 159 Plan 05: Proof-Lane Root Confinement Summary

Proof-lane generation now accepts only normalized, non-root `<host>/native/ios` shell roots and rejects unsafe direct config structs before any filesystem destination is derived.

## Completed Work

- Added the checked `Config.host_root/1` interface, enforcing the exact `native/ios` suffix and rejecting arbitrary, non-normalized, descendant, lookalike, relative, and root-derived paths with stable non-echoing config errors.
- Routed `Generator.generate/1`, `check/1`, and `diff/1` through that checked derivation before desired-state rendering or filesystem inspection.
- Preserved existing missing-only reruns, host-byte preservation, interrupted manifest protection, and concurrent generation guarantees while adding unsafe direct-struct regression coverage.

## Task Commits

1. Task 1 RED — `6250c65b` test(159-05): add unsafe iOS shell root coverage
2. Task 1 GREEN — `5c3cee45` feat(159-05): validate canonical iOS shell roots
3. Task 2 RED — `50e1f20b` test(159-05): add direct config confinement regression
4. Task 2 GREEN — `37ec67bf` feat(159-05): confine proof lane generator roots

## Verification

- `mix test test/crosswake/proof_lane/config_test.exs test/mix/tasks/crosswake_gen_proof_lane_test.exs` — passed (12 tests).
- `mix format --check-formatted lib/crosswake/proof_lane/config.ex lib/crosswake/proof_lane/generator.ex test/crosswake/proof_lane/config_test.exs test/mix/tasks/crosswake_gen_proof_lane_test.exs` — passed.
- Stub scan over all four touched files — passed; no placeholders or unconnected data surfaces found.

## Decisions Made

- The generator never accepts a derived host root from unchecked parent traversal; `Config.host_root/1` is the single authority for this boundary.
- Direct `%Config{}` construction is treated as untrusted at every generator action boundary, retaining the same stable error contract as Phoenix configuration normalization.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None.

## Next Phase Readiness

The proof lane has a shared fail-closed root derivation for all generation actions. Browser proof and device/evidence gaps remain bounded to their separately planned work; no Android, generic storage, or broader orchestration surface was added.

## Self-Check: PASSED

- All four modified source/test artifacts exist in the final tree.
- All four TDD gate commits exist in git history.
