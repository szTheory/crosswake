---
phase: "18-operational-diagnostics-and-enforcement"
plan: "02"
title: "Doctor severity policy and explicit proof posture rendering"
executed_at: "2026-05-21T20:20:00Z"
commits: []
files_changed:
  - "lib/crosswake/doctor/finding_policy.ex"
  - "lib/crosswake/doctor/doctor.ex"
  - "test/crosswake/doctor/doctor_test.exs"
  - "test/mix/tasks/crosswake_doctor_test.exs"
---

# Phase 18 Plan 02 Summary

Doctor findings now route through a dedicated Phase 18 finding policy for shell proof posture and support-claim severity, while keeping the unresolved Android lane visible as `verification_required`.

## Completed Work

- Added `Crosswake.Doctor.FindingPolicy` as a central taxonomy for shell proof findings and overall support-claim severity.
- Updated `Crosswake.Doctor` to use the shared policy when rendering proof-hook and support-posture findings.
- Preserved the distinction between blocking contract dishonesty and environment-sensitive verification gaps.
- Kept doctor output aligned with the new family-first registry posture and the Android proof blocker.

## Verification

- `mix test test/crosswake/doctor/doctor_test.exs test/mix/tasks/crosswake_doctor_test.exs`
  - Result: passed

## Constraints Observed

- The current workstation still has no Java runtime, so doctor continues to report Android shell proof as verification-required outside Java-enabled environments.

## Self-Check

PASSED
