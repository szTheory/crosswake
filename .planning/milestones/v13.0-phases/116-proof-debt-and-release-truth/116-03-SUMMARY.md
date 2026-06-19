---
phase: 116-proof-debt-and-release-truth
plan: "03"
subsystem: tests
tags: [release-truth, docs-contract, manifests, drift-guard]
requires:
  - phase: 116-proof-debt-and-release-truth
    provides: Public release truth reconciled by plan 02
provides:
  - Deterministic ExUnit release-truth drift guard
  - Real-doc scan for stale current-version and standalone-shell claims
  - Example-manifest scan for top-level and embedded shell/package release truth
  - Synthetic stale-claim regressions for DRIFT-01 categories
affects: [phase-117-guides, phase-118-quick-start, phase-119-native-evidence]
tech-stack:
  added: []
  patterns:
    - ExUnit docs-contract scanner derives current package version from application metadata.
    - Manifest checks stay focused on package/shell release truth and avoid compatibility-axis version fields.
key-files:
  created: []
  modified:
    - test/crosswake/guides/release_boundaries_test.exs
key-decisions:
  - "Kept the guard in the normal Mix test surface instead of adding a standalone script."
  - "Derived stale package versions from CHANGELOG release headings while deriving current truth from Application.spec(:crosswake, :vsn)."
requirements-completed: [DRIFT-01]
duration: 8 min
completed: 2026-06-18
status: complete
---

# Phase 116 Plan 03: Drift Guard Summary

**Release-truth drift is now guarded by deterministic ExUnit coverage over public docs and example manifests**

## Accomplishments

- Reoriented `Crosswake.Guides.ReleaseBoundariesTest` away from asserting stale standalone-shell deferral prose.
- Added a public-doc scanner for stale latest-Hex, current-version pending/unreleased, unlabelled old-baseline, and standalone-shell deferred/unavailable claims.
- Added manifest checks for top-level `crosswake_version`, embedded `support_matrix.package_surfaces` standalone-shell deferral prose, and embedded `support_matrix.shells` old package-version claims.
- Added synthetic regression samples for each DRIFT-01 stale-claim class without mutating real docs or manifests.

## Task Commits

1. **Task 1: Reorient release-boundary tests from stale assertion to current release-truth scan** - `e6db169` (`test`)
2. **Task 2: Add synthetic stale-claim regression cases and run the release-truth gate** - `4af0775` (`test`)

## Verification

- `mix test test/crosswake/guides/release_boundaries_test.exs` - passed, 3 tests, 0 failures for Task 1.
- `mix test test/crosswake/guides/release_boundaries_test.exs test/crosswake/doctor/publish_readiness_test.exs` - passed, 14 tests, 0 failures for Task 2.

## Deviations from Plan

None.

## Next Phase Readiness

Phase 116 is ready for phase-level verification and closeout. Phase 117 can build guide and support-truth foundations on top of current release truth and the new drift guard.

---
*Phase: 116-proof-debt-and-release-truth*
*Completed: 2026-06-18*
