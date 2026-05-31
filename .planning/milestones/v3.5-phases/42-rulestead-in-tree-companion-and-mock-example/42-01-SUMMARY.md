---
phase: 42-rulestead-in-tree-companion-and-mock-example
plan: 01
subsystem: companions
tags: [elixir, companion, feature-flags, rulestead, agent, route-gate, doctor, hermetic-proof]

# Dependency graph
requires:
  - phase: 38-companion-seam-contract
    provides: Crosswake.Companion behaviour (6 callbacks), Doctor companion seam, telemetry spans
  - phase: 40-runtime-gate-evaluation-and-fail-closed-denial
    provides: RouteGate.evaluate dispatch loop, kill-switch short-circuit, gate_denied denial
  - phase: 41-gating-doctor-and-support-matrix-truth
    provides: Doctor gating findings, SupportMatrix.gating_truth/0, gate_status typespec with {:rolling_out, n}
provides:
  - "Crosswake.Companions.Rulestead — first concrete companion satisfying all 6 Crosswake.Companion callbacks"
  - "Crosswake.Companions.Rulestead.MockFlagSource — named Agent flag-state store (mock-only, no network)"
  - "Hermetic proof test proving SC#1 (all gate states) and SC#3 (doctor fail-closed coverage)"
  - "lib/crosswake/companions/ directory convention established for in-tree companions"
affects:
  - phase: 43-rulestead-advisory-lane
  - phase: 44-rindle-media-companion

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "In-tree companion layout: lib/crosswake/companions/<name>.ex + lib/crosswake/companions/<name>/ subdirectory"
    - "Named Agent mock flag source: start_supervised! in ExUnit setup for hermetic per-test isolation"
    - "D-02 state mapping table: :gated/:rolling_out -> route_gated? deny, :killed -> kill_switch_active? true"
    - "Process.whereis nil-guard on MockFlagSource for fail-safe kill_switch_active?/1"
    - "report_state/0 most-restrictive scan: :killed > :gated/:rolling_out > unconfigured"

key-files:
  created:
    - lib/crosswake/companions/rulestead.ex
    - lib/crosswake/companions/rulestead/mock_flag_source.ex
    - test/crosswake/proof/phase42_rulestead_companion_test.exs
  modified: []

key-decisions:
  - "Scan all MockFlagSource values for :killed in kill_switch_active?/1 (Phase 42 single-flag simplification; documented with code comment)"
  - "Canonical state pairing for report_state/0: :killed -> gate_status: :inactive, kill_switch_status: :active (Pitfall 3 avoidance)"
  - "Test assertions use :"Elixir.Rulestead" atom for Hex package module (alias conflict with Crosswake.Companions.Rulestead in test file)"
  - "Symlink deps/_build from main repo to worktree to enable mix test from worktree context"

patterns-established:
  - "In-tree companion convention: lib/crosswake/companions/<name>.ex (companion) + lib/crosswake/companions/<name>/ (submodules)"
  - "Mock flag source pattern: named Agent with start_link/1 accepting ignored opts (supervisor child spec compatible)"
  - "Proof test uses start_supervised!(MockFlagSource) for fresh per-test Agent state (T-42-04 mitigation)"
  - "SC#3 doctor clean = disabled companion + absent dep -> no finding (doctor.ex catch-all returns [])"

requirements-completed: [COMP-01, COMP-02, COMP-03, GATE-02, GATE-03, GATE-04, GATE-05]

# Metrics
duration: 8min
completed: 2026-05-30
---

# Phase 42 Plan 01: Rulestead In-Tree Companion And Mock Example Summary

**`Crosswake.Companions.Rulestead` with named Agent MockFlagSource proves all three gate states (:gated/:rolling_out/:killed) and SC#3 doctor fail-closed coverage — 381 tests, 0 failures**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-30T17:45:52Z
- **Completed:** 2026-05-30T17:54:20Z
- **Tasks:** 3
- **Files created:** 3

## Accomplishments

- Implemented `Crosswake.Companions.Rulestead` satisfying all six `Crosswake.Companion` callbacks with `@impl true`, `companion_id: :rulestead`, fail-closed `enabled?/1` (defaults false), and the locked D-02 state mapping
- Implemented `Crosswake.Companions.Rulestead.MockFlagSource` as a named Agent with `start_link/1`, `set_flag/2`, `get_flag/1`, `reset/0` — no network calls, supervisor-child-spec compatible
- Established `lib/crosswake/companions/` in-tree companion convention (rulestead is the first; rindle and sigra will follow the same `<name>.ex` + `<name>/` layout)
- Proven SC#1 (all three gate states + unset) and SC#3 (enabled+absent -> error; disabled+absent -> clean) with 13 hermetic tests — picked up by `phase34-proof.yml` automatically

## Task Commits

1. **Task 1: MockFlagSource named Agent** - `d944aec` (feat)
2. **Task 2: Rulestead companion** - `5b0c95a` (feat)
3. **Task 3: Hermetic proof test** - `999af1c` (test)

## Files Created/Modified

- `lib/crosswake/companions/rulestead/mock_flag_source.ex` — Named Agent storing `%{flag_atom => gate_state}`; `@type gate_state :: :gated | {:rolling_out, non_neg_integer()} | :killed`
- `lib/crosswake/companions/rulestead.ex` — All six callbacks with `@impl true`; D-02 mapping; `kill_switch_active?/1` nil-guarded; `report_state/0` uses most-restrictive scan
- `test/crosswake/proof/phase42_rulestead_companion_test.exs` — 13 tests: SC#1a/b/c/d, SC#3a/b, unit callbacks, hermeticity self-assertion

## Decisions Made

- **Scan all MockFlagSource values for `:killed` in `kill_switch_active?/1`** (Pattern 3 / Assumption A2): since `kill_switch_active?/1` receives only `Target.t()` (not a route), scanning all stored flag values for `:killed` is correct for a single-flag Phase 42 demo. Documented in a code comment as a Phase-42-only simplification.
- **Canonical state pairing for `:killed`**: `gate_status: :inactive, kill_switch_status: :active` (Pitfall 3 avoidance — prevents `gate_state_display/1` from returning nil for a killed companion).
- **Test assertion uses `:"Elixir.Rulestead"` atom**: The test file aliases `Crosswake.Companions.Rulestead` as `Rulestead`, which would shadow the bare `Rulestead` Hex package atom in assertions. Used `:"Elixir.Rulestead"` directly for `validate_dependency/0` and `report_state/0` assertions.

## Deviations from Plan

None — plan executed exactly as written. All three tasks completed in sequence with zero warnings-as-errors violations and no architectural changes needed.

The only implementation clarification was the test assertion module atom disambiguation (see Decisions Made above) — this was a test authoring detail, not a deviation from the implementation plan.

## Issues Encountered

**Worktree deps/build isolation:** The git worktree at `.claude/worktrees/agent-af47e89a0b6957a2a/` had no `deps/` or `_build/` directory, so `mix test` failed with "dependency is not available". Resolved by symlinking `deps` and `_build` from the main project to the worktree directory. The symlinks are gitignored (`/deps/` and `/_build/` in `.gitignore`). This is the standard worktree build isolation pattern.

## Known Stubs

None — all three artifacts are fully implemented with live behavior. MockFlagSource is intentionally a mock (documented in `@moduledoc`), but it is a functional in-memory Agent with a defined production replacement path (`Rulestead.Snapshot` in Phase 43).

## Threat Flags

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced by this plan. The companion adds an in-process Agent (MockFlagSource) and a new Elixir module path through the existing RouteGate dispatch loop — both already guarded by the companion `enabled?/1` filter.

## Self-Check

**Files exist:**
- `lib/crosswake/companions/rulestead.ex` — FOUND
- `lib/crosswake/companions/rulestead/mock_flag_source.ex` — FOUND
- `test/crosswake/proof/phase42_rulestead_companion_test.exs` — FOUND

**Commits exist:**
- `d944aec` feat(42-01): implement MockFlagSource named Agent — FOUND
- `5b0c95a` feat(42-01): implement Crosswake.Companions.Rulestead companion — FOUND
- `999af1c` test(42-01): hermetic proof for SC#1 gate states and SC#3 doctor coverage — FOUND

**Test suite:** 381 tests, 0 failures — PASSED

## Self-Check: PASSED

## Next Phase Readiness

- `Crosswake.Companions.Rulestead` is ready for Phase 43 (advisory lane with real `rulestead` Hex dep)
- The `lib/crosswake/companions/<name>/` convention is established for rindle (Phase 44) and sigra
- The MockFlagSource pattern (named Agent, `start_supervised!` in tests) is reusable for other companion mocks
- No blockers; all COMP-01/02/03 and GATE-02/03/04/05 requirements exercised

---
*Phase: 42-rulestead-in-tree-companion-and-mock-example*
*Completed: 2026-05-30*
