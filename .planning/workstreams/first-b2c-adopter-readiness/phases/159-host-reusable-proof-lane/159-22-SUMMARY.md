---
phase: 159-host-reusable-proof-lane
plan: "22"
subsystem: proof-lane-evidence
tags: [elixir, c, native-port, sha256, privacy]
requires: [159-21]
provides: [digest-bound-retained-evidence]
affects: [PROOF-04, phase-159-final-gate]
tech-stack:
  added: []
  patterns: [bounded-private-native-frame, atomic-digest-marker, complete-only-readers]
key-files:
  created: []
  modified:
    - lib/crosswake/proof_lane/evidence.ex
    - lib/crosswake/proof_lane/native_promotion.ex
    - priv/native/crosswake_evidence_promote.c
    - test/crosswake/proof_lane/evidence_test.exs
decisions:
  - Retained evidence is accepted only when its exact artifact bytes hash to the lowercase SHA-256 in a regular 64-byte .complete marker.
  - Evidence bytes and digest cross to the native publisher only through a bounded stdio frame.
metrics:
  duration: 14m
  completed: 2026-08-01
status: complete
---

# Phase 159 Plan 22: Digest-Bound Evidence Acceptance Summary

Retained proof evidence now has a content-bound SHA-256 completion marker, so changed artifacts cannot remain passing after publication.

## Completed Work

- Added red/green coverage for exact marker contents, malformed markers, and retained-artifact mutation.
- Replaced staging-directory rename publication with a bounded native stdio publisher that reserves the final directory and writes the approved bytes plus atomic marker.
- Made `scan_stage/1`, `check/1`, and `check/2` accept only the artifact and a regular exact-shape marker, recomputing the artifact digest on every read.
- Preserved the twelve-field JSON schema and non-echoing failure surface.

## Verification

- `mix test test/crosswake/proof_lane/evidence_test.exs` — passed (17 tests)
- `cc -std=c11 -O2 -Wall -Wextra -Werror -o /tmp/crosswake-evidence-promote-159-22 priv/native/crosswake_evidence_promote.c` — passed
- `mix test` — passed; existing unrelated compiler warnings remain outside this plan’s files.

## Commits

- `38327da5` — `test(159-22): add failing digest marker regressions`
- `273823ac` — `feat(159-22): bind retained evidence to canonical bytes`

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Guarded constant-time digest comparison by exact marker length.
   - **Found during:** Task 1
   - **Issue:** OTP raises when `:crypto.hash_equals/2` receives differently sized marker and expected digest values.
   - **Fix:** Validate the marker as exactly 64 lowercase hexadecimal bytes before the constant-time comparison.
   - **Files modified:** `lib/crosswake/proof_lane/evidence.ex`
   - **Commit:** `273823ac`

## Known Stubs

None.

## Self-Check: PASSED

- All four planned code/test files exist.
- Both task commits are present in Git history.
