---
phase: 03-native-shell-boot-and-bounded-bridge
plan: 01
subsystem: shell
tags: [activation, denial, compatibility, route-gate, tdd]
requires:
  - phase: 02-manifest-truth-and-compatibility
    provides: versioned manifest truth, route compatibility findings, support matrix baselines
provides:
  - typed native activation requests for all app entry paths
  - shared denial envelopes for shell and bridge fail-closed decisions
  - route-gate denial mapping with pack compatibility checks and navigation-safe recovery metadata
affects: [03-02 generator-fixtures, 03-03 ios-shell, 03-04 android-shell, 03-05 bounded-bridge]
tech-stack:
  added: []
  patterns: [manifest-first activation, shared typed denial vocabulary, fail-closed route gating]
key-files:
  created:
    - lib/crosswake/shell/activation.ex
    - lib/crosswake/shell/denial.ex
    - test/crosswake/shell/activation_test.exs
    - test/crosswake/compatibility/compatibility_test.exs
  modified:
    - lib/crosswake/compatibility/compatibility.ex
    - lib/crosswake/compatibility/route_gate.ex
key-decisions:
  - "Activation resolves manifest-first through RouteGate and returns explicit allow or deny decisions before any runtime mount."
  - "Compatibility findings map into shared Crosswake.Shell.Denial envelopes so shell denial UI and later bridge denials reuse one vocabulary."
  - "Declared pack requirements use route pack strings with optional @version requirements against shell-installed pack inventory for MANI-03 fail-closed checks."
patterns-established:
  - "App launch, deep link, notification, and in-app navigation normalize into Crosswake.Shell.Activation.Request."
  - "RouteGate emits typed denials plus transition intent (:halt or :stay_put) instead of formatted strings."
requirements-completed: [MANI-03, SHELL-03, BRDG-03]
duration: 5min
completed: 2026-05-15
---

# Phase 3 Plan 1: Native Shell Boot And Bounded Bridge Summary

**Typed activation requests and shared denial envelopes now gate manifest-first route activation, including pack compatibility and navigation-safe failure handling.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-14T22:14:44Z
- **Completed:** 2026-05-14T22:19:25Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added `Crosswake.Shell.Activation` with one normalized request shape, explicit allow/deny decisions, and route resolution before any runtime mount.
- Added `Crosswake.Shell.Denial` as the shared stable denial vocabulary for route activation and future bridge replies.
- Rewired compatibility and route gating to emit typed denials, deny missing or incompatible packs, and distinguish deep-link halts from in-app stay-put failures.

## Task Commits

1. **Task 1 RED: activation contract spec** - `dfe568b` (`test`)
2. **Task 1 GREEN: activation and denial modules** - `b6ec620` (`feat`)
3. **Task 2 RED: route-gate denial spec** - `35f1347` (`test`)
4. **Task 2 GREEN: typed compatibility denial mapping** - `769f6ab` (`feat`)

## Files Created/Modified

- `lib/crosswake/shell/activation.ex` - typed activation request and explicit allow/deny resolution through route gating
- `lib/crosswake/shell/denial.ex` - stable denial envelope with `to_map/1` serialization
- `lib/crosswake/compatibility/compatibility.ex` - pack inventory checks and finding-to-denial mapping
- `lib/crosswake/compatibility/route_gate.ex` - fail-closed denial decisions with transition intent
- `test/crosswake/shell/activation_test.exs` - TDD coverage for request normalization and denial vocabulary
- `test/crosswake/compatibility/compatibility_test.exs` - TDD coverage for typed denials, deep-link recovery, and in-app stay-put behavior

## Decisions Made

- Used the existing route `packs` list as the Phase 3 declared-pack contract, with optional `pack_id@version` parsing, instead of inventing a broader Phase 5 pack registry early.
- Kept route-gate output machine-readable by returning `denial`, `denials`, and `transition` fields rather than preserving human-formatted reason strings.
- Limited deep-link recovery metadata to safe actions (`:retry`, `:open_safe_fallback`, `:update_app`) and kept in-app denials on the current route.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- A first pass used `Keyword.get/2` in a guard within `RouteGate`; this caused a compile error and was corrected inline before verification.
- The initial in-app pack denial carried more detail than the test contract allowed; the denial payload was tightened to keep only the current route reference for that case.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Later shell plans can consume `Crosswake.Shell.Activation.Request` and `Crosswake.Shell.Denial` directly instead of inventing platform-specific entry contracts.
- Bridge work in Plan 03-05 can reuse the shared denial vocabulary and capability mismatch mapping without reopening route-activation semantics.

## Self-Check: PASSED

- Verified summary target file exists at `.planning/phases/03-native-shell-boot-and-bounded-bridge/03-native-shell-boot-and-bounded-bridge-01-SUMMARY.md`.
- Verified required files exist: `lib/crosswake/shell/activation.ex`, `lib/crosswake/shell/denial.ex`, `lib/crosswake/compatibility/compatibility.ex`, `lib/crosswake/compatibility/route_gate.ex`, `test/crosswake/shell/activation_test.exs`, `test/crosswake/compatibility/compatibility_test.exs`.
- Verified commit hashes exist in git history: `dfe568b`, `b6ec620`, `35f1347`, `769f6ab`.
