---
phase: 05-packs-native-escape-and-proof-lanes
plan: 08
subsystem: proof-lanes
tags: [proof, ci, example-hosts, ios, android, phoenix]
requires:
  - phase: 05-03
    provides: generated required-pack runtime surfaces
  - phase: 05-06
    provides: native capture shell generation
  - phase: 05-07
    provides: transfer execution and native capture handoff
provides:
  - checked-in Phoenix, iOS, and Android example hosts
  - passing example-host proof entrypoint
  - passing generated iOS and Android verification hooks
  - deterministic Phase 5 CI workflow
affects: [05-09, 05-10, support-matrix, install-guide]
completed: 2026-05-17
---

# Phase 5 Plan 8: Proof Lanes Summary

Phase 5 proof is now real instead of blocked. The repo carries checked-in Phoenix, iOS, and Android example hosts, `script/verify_phase5_example_hosts.sh` passes, the generated Android verification hook passes, and the generated iOS hook now verifies the install path through build/install/launch instead of depending on the broken simulator XCTest launcher path.

## Accomplishments

- Added the checked-in example-host artifact class and wired it into `.github/workflows/phase5-proof.yml`.
- Kept the proof lane order explicit: example hosts first, generated hosts second.
- Reworked `script/verify_generated_ios_shell.sh` to prove the public iOS install path via `build-for-testing` plus simulator install/launch.
- Verified the Android generated-host lane still passes with connected tests on the booted emulator.

## Verification

- `bash script/verify_phase5_example_hosts.sh`
- `bash script/verify_generated_ios_shell.sh`
- `bash script/verify_generated_android_shell.sh`
- `mix test test/crosswake/proof/phase5_proof_lane_test.exs`

## Key Decision

The checked-in example hosts are the public proof artifact class. Generated-host verification remains required secondary proof, but iOS install proof is now anchored on build/install/launch rather than the host-dependent XCTest launcher path.
