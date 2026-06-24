---
phase: 116-proof-debt-and-release-truth
plan: "02"
subsystem: docs
tags: [release-truth, changelog, manifests, support-matrix, quick-start, adoption]
requires:
  - phase: 116-proof-debt-and-release-truth
    provides: TODO-001 proof debt resolved by plan 01
provides:
  - Public release truth reconciled to Crosswake 0.1.2
  - Example manifests aligned to current package-version truth
  - Stale standalone-shell deferral wording removed from public guide surfaces
  - Quick-start and adoption front doors protected from known-bad commands and fictional offline authority
affects: [phase-117-guides, phase-118-quick-start, phase-119-native-evidence, phase-120-collateral]
tech-stack:
  added: []
  patterns:
    - Public release prose states exact current facts where adopter trust depends on them.
    - Reusable generator/support prose uses Crosswake package-version wording.
key-files:
  created: []
  modified:
    - README.md
    - CHANGELOG.md
    - examples/phoenix_host/mix.exs
    - guides/install.md
    - guides/native_shell.md
    - guides/compatibility.md
    - guides/support_matrix.md
    - examples/QUICK_START.md
    - guides/adoption.md
    - examples/phoenix_host/priv/crosswake/install_manifest.json
    - examples/ios_shell_host/Fixtures/crosswake_manifest.json
    - examples/android_shell_host/app/src/main/assets/crosswake_manifest.json
key-decisions:
  - "Kept checked-in native hosts labeled as public proof artifacts pending Phase 119 evidence classification."
  - "Used exact 0.1.2 release truth in README/CHANGELOG/manifests and package-version wording in reusable shell prose."
patterns-established:
  - "Changelog [Unreleased] is future-oriented; released package entries carry dated release truth."
  - "Front-door docs may carry temporary safety labels without taking over Phase 118 or Phase 119 scope."
requirements-completed: [REL-TRUTH-01]
duration: 9 min
completed: 2026-06-18
status: complete
---

# Phase 116 Plan 02: Release Truth Summary

**Crosswake 0.1.2 release truth is now reflected in public docs, example metadata, manifests, and first-read proof-path labels**

## Performance

- **Duration:** 9 min
- **Started:** 2026-06-18T20:11:00Z
- **Completed:** 2026-06-18T20:20:00Z
- **Tasks:** 3
- **Files modified:** 12

## Accomplishments

- Updated README, CHANGELOG, example metadata, and three example manifests to current `crosswake 0.1.2` package truth.
- Replaced stale standalone-shell deferral prose with SwiftPM/Maven Central shell-core package wording tied to the Crosswake package version.
- Preserved native evidence honesty by labeling checked-in native hosts as pending Phase 119 classification rather than published-coordinate proof.
- Removed stale `mix setup`, `localhost:4000`, stale iOS project path, `Crosswake.mutate`, and bridge-owned offline mutation guidance from front-door docs.

## Task Commits

1. **Task 1: Correct README, CHANGELOG, example metadata, and manifest version truth** - `27542c1` (`docs`)
2. **Task 2: Replace stale standalone-shell deferral in install, native, compatibility, and support surfaces** - `1ed670a` (`docs`)
3. **Task 3: Add Phase 116 safety labels to quick-start and adoption front doors** - `f1c2820` (`docs`)

## Files Created/Modified

- `README.md` - Current baseline names Crosswake `0.1.2` and package-version native coordinates.
- `CHANGELOG.md` - `[Unreleased]` is future-oriented and `[0.1.2]` is a dated released entry.
- `examples/phoenix_host/mix.exs` - Example host metadata no longer reads as stale `0.1.0` proof truth.
- `examples/phoenix_host/priv/crosswake/install_manifest.json` - Top-level `crosswake_version` is current.
- `examples/ios_shell_host/Fixtures/crosswake_manifest.json` - Top-level package version and embedded shell-core package wording are current.
- `examples/android_shell_host/app/src/main/assets/crosswake_manifest.json` - Top-level package version and embedded shell-core package wording are current.
- `guides/install.md` - Standalone shell-core package prose reflects shipped SwiftPM/Maven Central path.
- `guides/native_shell.md` - Native shell release truth reflects shipped shell-core packages without widening support claims.
- `guides/compatibility.md` - Compatibility guide no longer defers standalone shell packages.
- `guides/support_matrix.md` - Package-version wording and native evidence labels are candid.
- `examples/QUICK_START.md` - Narrow safety labels replace stale setup, port, and iOS path claims.
- `guides/adoption.md` - Offline authority label now names app-owned IndexedDB outbox proof instead of bridge-owned mutation.

## Verification

- `mix test test/crosswake/doctor/publish_readiness_test.exs` - passed, 9 tests, 0 failures.
- `elixir -e 'checks = [{"README.md", "0.1.2"}, {"CHANGELOG.md", "## [0.1.2]"}, {"guides/support_matrix.md", "Crosswake package version"}]; ...'` - passed.
- `mix run -e 'current = Application.spec(:crosswake, :vsn) |> to_string(); manifests = ...'` - passed.
- Stale-claim grep for pending `0.1.2`, latest-Hex `0.1.0`, deferred standalone shell packages, stale quick-start commands, stale iOS path, `Crosswake.mutate`, and stale manifest package versions returned no matches.

## Decisions Made

- Used `"Crosswake package version"` in embedded native manifest shell artifact version fields so future releases do not require stale literal churn.
- Left full quick-start command verification and full adoption rewrite to Phase 118.
- Left checked-in native host evidence classification to Phase 119.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 116-03 can now add a deterministic release-truth drift guard against the corrected public baseline.

---
*Phase: 116-proof-debt-and-release-truth*
*Completed: 2026-06-18*
