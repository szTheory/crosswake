---
phase: 43-rulestead-hermetic-advisory-proof-and-guide
plan: "01"
subsystem: proof-posture
tags: [ci, hermetic, advisory, rulestead, companions, docs-contract]
requirements-completed: [PROOF-01]

dependency_graph:
  requires:
    - phase42_rulestead_companion_test.exs (hermetic proof suite, unchanged)
    - lib/crosswake/companions/rulestead.ex (validate_dependency/0 impl)
    - lib/crosswake/companions/rulestead/mock_flag_source.ex (MockFlagSource)
  provides:
    - mix.exs conditional rulestead dep (MIX_INCLUDE_RULESTEAD)
    - test/crosswake/proof/phase43_rulestead_advisory_test.exs (advisory proof)
    - guides/companions.md (companion pattern intro + rulestead section)
    - test/crosswake/guides/companions_test.exs (docs-contract test)
    - .github/workflows/phase43-proof.yml (two-job CI workflow)
  affects:
    - CI merge gate (hermetic job added as new required check candidate)
    - mix.exs deps/0 structure (base ++ conditional pattern)
    - ExDoc extras list (companions.md added)

tech_stack:
  added: []
  patterns:
    - env-var conditional dep isolation (MIX_INCLUDE_RULESTEAD in deps/0)
    - hermetic+advisory CI split (phase34-proof.yml template applied to rulestead)
    - docs-contract test (File.read! + setup_all + assert content =~ + function_exported?)
    - @moduletag :advisory_only to exclude advisory tests from hermetic lane

key_files:
  created:
    - mix.exs (modified: deps/0 restructured, companions.md added to extras)
    - test/crosswake/proof/phase43_rulestead_advisory_test.exs
    - guides/companions.md
    - test/crosswake/guides/companions_test.exs
    - .github/workflows/phase43-proof.yml
  modified: []

decisions:
  - env-var conditional (MIX_INCLUDE_RULESTEAD) chosen over optional: true flag for dep isolation
  - Separate advisory test file (phase43_rulestead_advisory_test.exs) chosen over modifying phase42 test
  - @moduletag :advisory_only for exclusion contract (hermetic lane uses --exclude advisory_only)
  - Code.ensure_loaded! called before function_exported? in docs-contract test (module loading timing fix)
  - guides/companions.md created alongside advisory test (required by HexPageTest extras validation)

metrics:
  duration_minutes: 7
  completed_date: "2026-05-30"
  tasks_completed: 3
  files_modified: 5
---

# Phase 43 Plan 01: Rulestead Hermetic+Advisory Proof And Guide Summary

Hermetic+advisory CI proof posture for the rulestead companion: `mix.exs` conditional dep gated by `MIX_INCLUDE_RULESTEAD`, advisory `validate_dependency/0 == :ok` proof, `guides/companions.md` with docs-contract test, and a two-job `phase43-proof.yml` CI workflow with documented `Rulestead.Snapshot` promotion path.

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Add MIX_INCLUDE_RULESTEAD conditional dep to mix.exs | d3e2086 | mix.exs |
| 2 (RED) | Add failing advisory test (hermetic context fails) | e75d79f | test/crosswake/proof/phase43_rulestead_advisory_test.exs |
| 2 (GREEN) | Advisory test passes with rulestead present + guides/companions.md | a83b817 | guides/companions.md |
| 3 | Create phase43-proof.yml CI workflow + companions_test.exs | ada90f0 | .github/workflows/phase43-proof.yml, test/crosswake/guides/companions_test.exs |

## Verification Results

- Hermetic lane: `mix test --exclude requires_example_host --exclude advisory_only` = **391 tests, 0 failures**
- Advisory lane (local): `MIX_INCLUDE_RULESTEAD=1 mix test test/crosswake/proof/phase43_rulestead_advisory_test.exs` = **1 test, 0 failures**
- mix.lock hermetic: `grep -c rulestead mix.lock` = **0**
- Workflow YAML valid: two jobs, advisory continue-on-error, schedule cron present, `Rulestead.Snapshot` named in promotion path

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] guides/companions.md created alongside Task 2 (not a separate Task 3 sub-task)**
- **Found during:** Task 2 GREEN phase
- **Issue:** Adding `guides/companions.md` to mix.exs `docs/extras` in Task 1 caused `HexPageTest` to fail (file missing on disk), blocking the hermetic suite from passing — a Task 2 acceptance criterion.
- **Fix:** Created `guides/companions.md` with full content (companion pattern intro + rulestead section) as part of the Task 2 GREEN commit. The file satisfies both the HexPageTest and all companions_test.exs anchor assertions.
- **Files modified:** guides/companions.md (created)
- **Commit:** a83b817

**2. [Rule 1 - Bug] Code.ensure_loaded! added before function_exported? in companions_test.exs**
- **Found during:** Task 3 (companions_test.exs creation and verification)
- **Issue:** `function_exported?(Crosswake.Companions.Rulestead, :validate_dependency, 0)` returned `false` in ExUnit test process even though the function is exported. Root cause: module not yet loaded in the test process at assertion time (module loading is lazy in non-started applications).
- **Fix:** Added `Code.ensure_loaded!/1` calls before each `function_exported?` assertion — standard pattern when asserting exports without `Code.require_file` or application start.
- **Files modified:** test/crosswake/guides/companions_test.exs
- **Commit:** ada90f0

**3. [Rule 3 - Blocking] mix.lock rulestead contamination during advisory local verification**
- **Found during:** Task 2 GREEN phase (local advisory verify with MIX_INCLUDE_RULESTEAD=1)
- **Issue:** Running `MIX_INCLUDE_RULESTEAD=1 mix deps.get` locally added rulestead + transitive deps (ecto_sql, ecto, postgrex, redix, db_connection, decimal) to `mix.lock` and compiled them into `_build`. Subsequent hermetic `mix test` failed: `Could not start application rulestead: could not find application file: rulestead.app`.
- **Fix:** `git checkout -- mix.lock` to restore hermetic lock; cleaned `_build` rulestead artifacts; recompiled hermetically with `MIX_INCLUDE_RULESTEAD= mix compile` to regenerate clean `.app` file. All advisory verification in CI will not persist lock changes (CI doesn't commit).
- **Files modified:** mix.lock (restored to hermetic state, not committed)

## Requirements Satisfied

- **PROOF-01 (hermetic):** Phase 42 rulestead proof suite passes with rulestead absent; hermetic job is merge-blocking (PR/push). Phase42 test `validate_dependency/0 == {:error, [:"Elixir.Rulestead"]}` still passes.
- **PROOF-01 (advisory):** Advisory job runs phase43_rulestead_advisory_test.exs with rulestead present; asserts `validate_dependency/0 == :ok`; `continue-on-error: true`; 4-condition promotion path documented naming `Rulestead.Snapshot`.

## Known Stubs

None — all files are complete and functional. `MockFlagSource` is the documented mock swap target; `Rulestead.Snapshot` is the documented production swap target (deferred per plan, correctly scoped).

## Self-Check: PASSED

All created files verified on disk. All task commits verified in git log.

| File | Status |
|------|--------|
| mix.exs | FOUND |
| test/crosswake/proof/phase43_rulestead_advisory_test.exs | FOUND |
| guides/companions.md | FOUND |
| test/crosswake/guides/companions_test.exs | FOUND |
| .github/workflows/phase43-proof.yml | FOUND |

| Commit | Status |
|--------|--------|
| d3e2086 | FOUND |
| e75d79f | FOUND |
| a83b817 | FOUND |
| ada90f0 | FOUND |
