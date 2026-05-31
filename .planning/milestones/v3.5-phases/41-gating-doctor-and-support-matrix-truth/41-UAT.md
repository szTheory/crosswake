---
status: complete
phase: 41-gating-doctor-and-support-matrix-truth
source: [41-01-SUMMARY.md, 41-02-SUMMARY.md]
started: 2026-05-30T10:31:00Z
updated: 2026-05-30T10:45:00Z
---

## Current Test

[testing complete]

## Tests

### 1. SC#1 Gating Doctor Proof (6 hermetic tests)
expected: mix test --only sc1 runs 6 SC#1 tests covering per-route advisory finding, flag reference error, fallback route warning, nil-manifest nil guard, and empty companions error — all pass.
result: pass
verified_by: cli_auto
command: "mix test test/crosswake/proof/phase41_gating_doctor_test.exs --only sc1"
output: "6 tests, 0 failures"

### 2. SC#2 Support Matrix Gating Truth Proof (5 hermetic tests)
expected: mix test --only sc2 runs 5 SC#2 tests covering gated/rolling_out/killed display strings, kill-switch precedence, and runtime-distinct label — all pass.
result: pass
verified_by: cli_auto
command: "mix test test/crosswake/proof/phase41_gating_doctor_test.exs --only sc2"
output: "5 tests, 0 failures"

### 3. Full Test Suite Green
expected: mix test --exclude requires_example_host runs 368 tests with 0 failures — gating doctor and support matrix additions did not regress any existing tests.
result: pass
verified_by: cli_auto
command: "mix test --exclude requires_example_host"
output: "368 tests, 0 failures (38 excluded)"

### 4. Doctor CLI Gating Category Output
expected: Doctor.run with a gated-route manifest surfaces gating finding codes (gating.route_gated, gating.flag_reference_unknown) in both human and JSON formatted output.
result: pass
verified_by: cli_auto
command: "mix test test/crosswake/doctor/doctor_test.exs"
output: "18 tests, 0 failures — new GatingIntegrationRouter test asserts finding codes in Formatter.render and JSONFormatter.render output"

## Summary

total: 4
passed: 4
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none]
