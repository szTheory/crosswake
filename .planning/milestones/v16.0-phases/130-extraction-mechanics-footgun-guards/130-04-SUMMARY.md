---
phase: 130-extraction-mechanics-footgun-guards
plan: "04"
subsystem: companion-extraction
tags: [extraction, rulestead, companion, dress-rehearsal, elixir]
dependency_graph:
  requires: ["130-02", "130-03"]
  provides: ["EXTRACT-01", "EXTRACT-02"]
  affects: [mix.exs, packages/crosswake_rulestead, script/extract_companion.md]
tech_stack:
  added: [crosswake_rulestead companion package, mix.lock]
  patterns:
    - poncho-style Elixir companion extraction (path: dep dress rehearsal)
    - "@compile {:no_warn_undefined, Rulestead} + Application.get_env config-indirection"
    - engine-absent default / engine-present advisory via conditional elixirc_paths
    - StubRulesteadAbsentCompanion pattern for core doctor/parity tests
key_files:
  created:
    - packages/crosswake_rulestead/lib/crosswake/companions/rulestead.ex
    - packages/crosswake_rulestead/test/support/mock_flag_source.ex
    - packages/crosswake_rulestead/test/support/study_session_live.ex
    - packages/crosswake_rulestead/test/crosswake/proof/phase42_rulestead_companion_test.exs
    - packages/crosswake_rulestead/test/crosswake/proof/phase43_rulestead_advisory_test.exs
    - packages/crosswake_rulestead/test/engine_present/rulestead.ex
    - packages/crosswake_rulestead/config/config.exs
    - packages/crosswake_rulestead/mix.lock
    - packages/crosswake_rulestead/LICENSE
    - packages/crosswake_rulestead/CHANGELOG.md
    - script/extract_companion.md
  modified:
    - mix.exs (deleted MIX_INCLUDE_* blocks, added aliases)
    - test/crosswake/proof/phase42_rulestead_companion_test.exs (stub migration)
    - test/crosswake/proof/phase47_companion_arc_test.exs (stub migration)
    - test/crosswake/guides/companions_test.exs (stub migration)
    - test/support/stub_companion.ex (added StubRulesteadAbsentCompanion)
    - script/verify_companion_package.sh (dress-rehearsal path: dep mode)
  deleted:
    - lib/crosswake/companions/rulestead.ex (moved to companion package)
    - lib/crosswake/companions/rulestead/mock_flag_source.ex (moved to companion test/support)
decisions:
  - "D-20 test split enforced: SC#1 adapter-behavior tests in companion lane, SC#3a/SC#3b doctor tests stay in core using StubRulesteadAbsentCompanion"
  - "D-31 config-indirection: Application.get_env(:crosswake, :rulestead_flag_source, nil) — runtime, not compile_env; dedicated key avoids clash with :rulestead companion config map"
  - "D-33 engine-present advisory lane: test/engine_present/rulestead.ex compiled only when ENGINE_PRESENT_LANE=1 via conditional elixirc_paths"
  - "D-29 @compile {:no_warn_undefined, Rulestead}: required in addition to optional: true to silence engine-absent undefined-module warnings with --warnings-as-errors"
  - "D-24 dress-rehearsal: hex.build --unpack skipped (path: dep fails it); verify script falls back to files: allowlist inspection in mix.exs"
  - "D-25 extraction recipe: script/extract_companion.md parameterized checklist proven on rulestead, reusable for rindle (Phase 132)"
  - "Core test migration: StubRulesteadAbsentCompanion added to test/support/stub_companion.ex; replaces Crosswake.Companions.Rulestead alias in phase42/phase47/companions guide tests"
metrics:
  completed: "2026-06-26"
  tasks: 3
  commits: 3
status: complete
---

# Phase 130 Plan 04: Rulestead Companion Extraction Summary

**One-liner:** Rulestead adapter extracted to standalone `crosswake_rulestead` Hex package with poncho path: dep, `@compile {:no_warn_undefined}`, config-indirection flag_source, engine-absent/engine-present advisory lanes, and parameterized extraction recipe for Phase 132 reuse.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Move Rulestead adapter + MockFlagSource into companion package | `884b470` | packages/crosswake_rulestead/lib/, test/support/ |
| 2 | Delete MIX_INCLUDE_* from core, add aliases, split tests, engine-present stub | `92a5d85` | mix.exs, companion test/, config/ |
| 3 | Finalize package — lock, verify script, recipe, core test migration | `e6df8bd` | mix.lock, script/extract_companion.md, test/ stubs |

## What Was Built

### Companion Package (packages/crosswake_rulestead/)

A self-contained Hex project:
- `lib/crosswake/companions/rulestead.ex` — module name `Crosswake.Companions.Rulestead` PRESERVED (non-breaking)
  - `@compile {:no_warn_undefined, Rulestead}` — silences undefined-module warning in engine-absent builds (D-29)
  - `defp flag_source` uses `Application.get_env(:crosswake, :rulestead_flag_source, nil)` — runtime config-indirection (D-31)
  - `Code.ensure_loaded?(Rulestead)` kept inside function bodies (EXTRACT-04-clean)
- `test/support/mock_flag_source.ex` — Named Agent for test flag storage
- `test/support/study_session_live.ex` — 3-line Phoenix.LiveView stub (D-23)
- `test/crosswake/proof/phase42_rulestead_companion_test.exs` — SC#1 gate/kill-switch tests (engine-present context)
- `test/crosswake/proof/phase43_rulestead_advisory_test.exs` — `@moduletag :engine_present` advisory test
- `test/engine_present/rulestead.ex` — fake Rulestead stub compiled only when ENGINE_PRESENT_LANE=1 (D-33)
- `config/config.exs` — wires `:rulestead_flag_source` to MockFlagSource in :test env (D-31)
- `mix.lock` — deps locked after `mix deps.get` (D-24)

### Core (mix.exs) Changes

- Deleted `MIX_INCLUDE_RULESTEAD` and `MIX_INCLUDE_RINDLE` conditional dep blocks (D-21)
- `deps/0` now returns just `base` — no companion deps in any env (EXTRACT-01)
- Added `aliases: aliases()` to `project/0`
- Added `defp aliases/0` with:
  - `"companions.test"` — runs companion lane: `cmd --cd packages/crosswake_rulestead mix test`
  - `"verify"` — chains companions.test + core test excluding advisory tags (D-26)

### Verify Script + Extraction Recipe

- `script/verify_companion_package.sh` — updated for dress-rehearsal mode (path: dep makes hex.build fail):
  - Step 1: files: allowlist inspection in mix.exs (test/ absent, lib/ present)
  - Step 2: skipped with note (Phase 131 pivots to Hex dep)
  - Step 3: `mix compile --warnings-as-errors` — always runs
- `script/extract_companion.md` — parameterized 12-step extraction recipe (D-25):
  - Documents all decisions (D-19/D-20/D-21/D-22/D-23/D-24/D-25/D-26/D-28/D-29/D-31/D-33)
  - Reusable for rindle (Phase 132) with parameter substitution

### Core Test Migration

After extraction, 17 core tests failed because they referenced `Crosswake.Companions.Rulestead` which is no longer in core's compile path. Resolution:

- Added `StubRulesteadAbsentCompanion` to `test/support/stub_companion.ex`:
  - `companion_id: :rulestead` — preserves doctor finding.check == "companion.rulestead"
  - `validate_dependency/0` returns `{:error, [:"Elixir.Rulestead"]}` — correct engine-absent behavior
- Updated `test/crosswake/proof/phase42_rulestead_companion_test.exs`:
  - SC#1 gate/kill-switch tests removed from core (now in companion package)
  - SC#3a/SC#3b doctor tests rewritten using `StubRulesteadAbsentCompanion` (not the extracted adapter)
  - 3 tests, 0 failures
- Updated `test/crosswake/proof/phase47_companion_arc_test.exs`:
  - `alias Crosswake.Companions.Rulestead` replaced with `alias StubRulesteadAbsentCompanion, as: Rulestead`
  - 6 tests, 0 failures
- Updated `test/crosswake/guides/companions_test.exs`:
  - "live code guard" test: removed `Crosswake.Companions.Rulestead` and `MockFlagSource` ensure_loaded! assertions (guarded in companion package now)
  - "parity" + "doctor finding codes" tests: use `StubRulesteadAbsentCompanion` for companions registration
  - 7 tests, 0 failures

## Verification Results

```
mix companions.test:  11 tests, 0 failures (1 excluded)
bash script/verify_companion_package.sh crosswake_rulestead: OK (Steps 1+3)
mix test phase130_extraction_guards_test.exs phase130_fail_closed_contract_test.exs: 15 tests, 0 failures
mix test --exclude requires_example_host --exclude advisory_only: 1159 tests, 2 failures (pre-existing), 1 skipped
```

Pre-existing failures (not caused by this plan):
- `MilestoneTransitionResetTest` — REQUIREMENTS.md header milestone string mismatch
- `Phase52OperatorTruthTest` — JSON fixture drift

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Application.compile_env cannot be called inside defp flag_source/0**
- **Found during:** Task 1 (compile error)
- **Issue:** `Application.compile_env(:crosswake, [:rulestead, :flag_source], nil)` inside a function body is rejected by the Elixir macro at compile time
- **Fix:** Switched to `Application.get_env(:crosswake, :rulestead_flag_source, nil)` (runtime); used dedicated config key `:rulestead_flag_source` to avoid clash with `:rulestead` companion config map
- **Files modified:** `packages/crosswake_rulestead/lib/crosswake/companions/rulestead.ex`, `packages/crosswake_rulestead/config/config.exs`
- **Commit:** `884b470` → `e6df8bd` (refined in Task 3)

**2. [Rule 1 - Bug] Engine-present stub compiled in default test run**
- **Found during:** Task 2 (warning: redefining module Rulestead)
- **Issue:** Fake Rulestead stub at `test/support/engine_present/rulestead.ex` was inside `test/support/` which is always in `elixirc_paths(:test)`. Since rulestead is in mix.lock (optional but locked), the real module loads first then stub redefined it.
- **Fix:** Moved stub to `test/engine_present/rulestead.ex` (outside test/support); updated `elixirc_paths(:test)` to conditionally include `test/engine_present` only when `ENGINE_PRESENT_LANE=1`
- **Files modified:** Companion mix.exs, test/engine_present/rulestead.ex path
- **Commit:** `92a5d85`

**3. [Rule 1 - Bug] hex.build --unpack fails with path: dep**
- **Found during:** Task 3 (verify script with set -euo pipefail)
- **Issue:** `mix hex.build --unpack` exits non-zero when `{:crosswake, path: "../.."}` is in deps — path: deps are not publishable
- **Fix:** Updated verify_companion_package.sh — when path: dep detected, Step 1 inspects files: allowlist directly in mix.exs; Step 2 skipped with Phase 131 note
- **Files modified:** `script/verify_companion_package.sh`
- **Commit:** `e6df8bd`

**4. [Rule 1 - Bug] Missing test/test_helper.exs in companion package**
- **Found during:** Task 3 (`mix companions.test` run)
- **Issue:** `mix test` in companion package failed with "Cannot run tests because test helper file does not exist"
- **Fix:** Created `packages/crosswake_rulestead/test/test_helper.exs` with `ExUnit.start(exclude: [:engine_present, :collateral_binaries, :advisory_only])`
- **Commit:** `92a5d85`

**5. [Rule 2 - Missing critical functionality] Core tests referencing extracted module**
- **Found during:** Task 3 (full core test suite run — 17 failures)
- **Issue:** After extraction, `Crosswake.Companions.Rulestead` is not in core's compile path. Core phase42, phase47, and companions guide tests that registered/aliased it broke at runtime.
- **Fix:** Added `StubRulesteadAbsentCompanion` to `test/support/stub_companion.ex`; migrated 3 core test files to use stub. D-20 test split enforced: SC#1 tests stay in companion lane, SC#3a/SC#3b doctor tests stay in core via stub.
- **Files modified:** test/support/stub_companion.ex, test/crosswake/proof/phase42_rulestead_companion_test.exs, test/crosswake/proof/phase47_companion_arc_test.exs, test/crosswake/guides/companions_test.exs
- **Commit:** `e6df8bd`

**6. [Rule 1 - Bug] Comment in core mix.exs deps/0 contained MIX_INCLUDE_RULESTEAD string**
- **Found during:** Task 2 (EXTRACT-01 guard string check returned true)
- **Issue:** The comment "# MIX_INCLUDE_RULESTEAD and MIX_INCLUDE_RINDLE blocks DELETED" caused `String.contains?(src, "MIX_INCLUDE_RULESTEAD")` to match
- **Fix:** Rewrote comment to not mention the env var names
- **Files modified:** `mix.exs`
- **Commit:** `92a5d85`

## Must-Haves Verification

| Requirement | Status |
|---|---|
| Core mix.exs has no MIX_INCLUDE_RULESTEAD / MIX_INCLUDE_RINDLE / companion-conditional dep block (EXTRACT-01) | PASS |
| packages/crosswake_rulestead/ is self-contained Hex project; module name preserved; tests pass as path: dep (EXTRACT-02) | PASS (11 tests) |
| Companion compiles --warnings-as-errors in engine-ABSENT state with @compile no_warn_undefined (D-29) | PASS |
| lib/ references flag-source config-indirection symbol, never MockFlagSource directly (D-31) | PASS |
| mix companions.test and mix verify root aliases run the companion lane (D-26) | PASS |

## Phase 131 Handoff

The following is deferred to Phase 131 (first real publish):
1. Change `{:crosswake, path: "../.."}` → `{:crosswake, "~> 0.1"}` in companion mix.exs
2. Run `mix deps.get` to re-lock with Hex dep
3. Re-run `bash script/verify_companion_package.sh crosswake_rulestead` — all 3 steps active
4. Register component in release-please-config.json + .release-please-manifest.json
5. `mix hex.publish` (first real publish)

## Self-Check: PASSED

Files exist:
- FOUND: packages/crosswake_rulestead/lib/crosswake/companions/rulestead.ex
- FOUND: packages/crosswake_rulestead/test/support/mock_flag_source.ex
- FOUND: packages/crosswake_rulestead/test/engine_present/rulestead.ex
- FOUND: packages/crosswake_rulestead/config/config.exs
- FOUND: packages/crosswake_rulestead/mix.lock
- FOUND: script/extract_companion.md
- FOUND: test/support/stub_companion.ex (StubRulesteadAbsentCompanion added)
- NOT FOUND in core lib/: lib/crosswake/companions/rulestead.ex (correctly deleted)

Commits exist:
- FOUND: 884b470 (Task 1)
- FOUND: 92a5d85 (Task 2)
- FOUND: e6df8bd (Task 3)
