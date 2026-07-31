---
phase: 159-host-reusable-proof-lane
plan: "01"
subsystem: proof-lane-generator
tags: [elixir, mix, ios, playwright, evidence]
requires: []
provides: [closed-proof-lane-config, host-owned-ios-proof-scaffold, opaque-evidence-seam]
affects: [phase-159-plans-02-04]
tech-stack:
  added: []
  patterns: [missing-only-generation, closed-config, staged-evidence-promotion]
key-files:
  created:
    - lib/crosswake/proof_lane/config.ex
    - lib/crosswake/proof_lane/generator.ex
    - lib/crosswake/proof_lane/evidence.ex
    - lib/mix/tasks/crosswake.gen.proof_lane.ex
  modified:
    - test/mix/tasks/crosswake_gen_proof_lane_test.exs
decisions:
  - The proof-lane generator reads only the closed Phoenix configuration and creates missing host-owned files without merging edits.
  - The generated Swift driver reports only passed, blocked, or unavailable, leaving replay and pack capability explicitly non-passing.
metrics:
  duration: 11m
  completed_date: 2026-07-31
  tasks_completed: 1
  files_changed: 9
status: complete
---

# Phase 159 Plan 01: Host-Reusable Proof Lane Summary

An iOS-only Mix generator creates an isolated, host-owned ExUnit, Playwright, Swift, and Xcode proof scaffold from one validated Phoenix configuration.

## Completed Work

- Added a closed `Crosswake.ProofLane.Config` boundary that accepts exactly the route, browser-storage, endpoint, router, and iOS-root contract without echoing rejected values.
- Added missing-only desired-state generation, a versioned manifest, and read-only `--check`/`--diff` actions.
- Added generated browser and Swift contracts with explicit non-passing prerequisites, plus distinct XCTest and XCUITest target declarations.
- Added a narrow typed evidence builder with staged promotion and an end-to-end Mix task test proving no-clobber reruns.

## Verification

- `mix test test/mix/tasks/crosswake_gen_proof_lane_test.exs` — passed.
- `mix format --check-formatted lib/crosswake/proof_lane/config.ex lib/crosswake/proof_lane/generator.ex lib/crosswake/proof_lane/evidence.ex lib/mix/tasks/crosswake.gen.proof_lane.ex test/mix/tasks/crosswake_gen_proof_lane_test.exs` — passed.
- `xcodebuild -version` — available (Xcode 26.6); device/simulator execution remains advisory and was not promoted as device proof.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

The proof-owned project declares the XCTest and XCUITest target boundary but deliberately leaves focused native test sources to Plan 159-03. This is an intentional phased scaffold, not a passing device claim.

## Self-Check: PASSED

- Required generator modules, templates, and tracer test exist in the final tree.
- TDD commits `24a5a6e8` and `30510729` exist in git history.
