---
phase: 195-pipeline-repair-and-hygiene
plan: 08
subsystem: infra
tags: [ci, github-actions, dependabot, see-it-run]
requires:
  - phase: 195-07
    provides: Cancel Obsolete controller retired
provides:
  - "See It Run web-and-gif independent of native; native capture in manual see-it-run-native.yml"
  - "Dependabot actions grouped monthly, version-updates only"
affects: [195-09]
requirements-completed: [REL-04, REL-05]
actuals:
  tokens: 14000
  tasks: 2
  commits: 2
  plan_head_before: 8407daf26b624b9c3ae5f1f49cca70609d5d5ba2
  plan_head_after: 84318cb0bc80e4ebeda8996f19a0487a4e901de0
completed: 2026-10-26
status: complete
---

# Phase 195 Plan 08: Split See It Run native, group Dependabot Summary

**The macOS native capture is a dispatch-only, read-only workflow; the collateral run no longer waits on it; Dependabot actions update monthly in one version-updates group.**

Branch `ci/recurring-lanes-and-secret-masking`, local only, not pushed.

## Commits

- c1602538 ci: split See It Run native capture into a manual workflow
- 84318cb0 ci: group Dependabot actions monthly

## Evidence

- Targeted tests (recurring lanes, phase134 native gate, collateral guard): rc 0, 24 tests, 0 failures. With CROSSWAKE_INCLUDE_COLLATERAL=1 the collateral guard: rc 0, 4 tests.
- Full `mix test`: rc 0, 2770 tests, 0 failures (75 excluded). `node --test test/js/*.mjs`: rc 0, pass 148, fail 0.
- `elixir script/inventory_collection_assertions.exs --check`: rc 0, 243 sites.
- Blocking-check hash before and after: `f1dd556db36ba0e28c4ace016c957e7a457c5c5b14f1179e4d6612ca90b23e2a`, unchanged yes; four per-plan lines (05-08) plus `lane: blocking_checks unchanged yes` are in lanes-195.txt.
- Privacy scan on all changed files: rc 0.
- Working tree clean after the final commit (tracked files).

## Deviations from Plan

**1. [Rule 3 - Blocking] montage step adapted for macOS** - the moved montage step could not be copied as-is: the native job runs on macOS (no `apt-get`/`sudo`), and `web-home.png` is not available in that workflow. The step now uses `brew install imagemagick` and `magick ios-simulator.png android-emulator.png +append native-montage.png`, uploaded as artifact `see-it-run-montage`. The native job's own steps are unchanged. The three-runtime montage is no longer produced anywhere.

**2. [Scope] collateral-mode test expectation** - `see_it_run_collateral_test.exs` required ios-simulator.png, android-emulator.png and three-runtime-montage.png; reduced to the web PNGs plus see-it-run.gif (the assemble-pr guard would otherwise fail without native artifacts). Recorded in lanes-195.txt.

**3. [Cleanup] collateral workflow header and PR body** - removed claims about the iOS/Android and montage assets from the header comment and auto-PR body so they match what the run produces.

**4. Substitution** - none needed; full `mix test` was run instead of the proof directory alone.

## Known Stubs

None.

## Threat Flags

None. T-195-43 mitigated (dispatch-only, `contents: read`, SHA-pinned actions retained; pinned by test). T-195-18 mitigated (`applies-to: version-updates`; repository setting is plan 09).

## Notes

`see-it-run-native.yml` still carries the known pre-existing native capture gaps documented in its step comment (unchanged).

## Self-Check: PASSED

Commits c1602538 and 84318cb0 are ancestors of HEAD; see-it-run-native.yml, dependabot.yml and lanes-195.txt exist.
