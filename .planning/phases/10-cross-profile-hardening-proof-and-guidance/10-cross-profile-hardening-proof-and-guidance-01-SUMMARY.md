---
phase: 10-cross-profile-hardening-proof-and-guidance
plan: 01
subsystem: doctor
tags:
  - hardening
  - diagnostic
  - validation
dependency_graph:
  requires:
    - "Phase 7, 8, 9 boundary definitions"
  provides:
    - "Explicit v1 capability boundary enforcement in Doctor"
  affects:
    - "lib/crosswake/doctor/doctor.ex"
    - "lib/crosswake/policy/validator.ex"
tech_stack:
  added: []
  patterns:
    - "ExUnit Boundary Testing"
key_files:
  created: []
  modified:
    - "lib/crosswake/doctor/doctor.ex"
    - "lib/crosswake/policy/validator.ex"
    - "test/crosswake/doctor/doctor_test.exs"
decisions_made:
  - "Added specific capabilities to `Validator` known_capabilities so `Doctor` can explicitly trap them and emit localized hint documentation rather than generic `unknown capability` errors."
requirements-completed: [HARD-01]
metrics:
  duration: 4m
  completed_tasks: 1
  total_tasks: 1
---

# Phase 10 Plan 01: Enforce Exemplar Boundaries Summary

Upgraded `mix crosswake.doctor` to enforce boundary constraints surfaced by the exemplars without expanding the Elixir API.

## Deviations from Plan

None - plan executed exactly as written, with the necessary addition of `background_sync` and `generic_plugin_bus` to `Validator` known capabilities to allow `Doctor` to properly format the specific boundary hints.

## Pre-existing Deferred Issues

Several ExUnit tests fail due to modifications by previous agents in the `10-cross-profile-hardening-proof-and-guidance` or earlier phases. These include `Crosswake.RouterTest` and `Crosswake.Offline.ProofLaneTest`. They are out-of-scope for this plan's objective and should be addressed separately.

## Self-Check: PASSED
- `lib/crosswake/doctor/doctor.ex` modified and tested.
- Commit `153f00a` created.
