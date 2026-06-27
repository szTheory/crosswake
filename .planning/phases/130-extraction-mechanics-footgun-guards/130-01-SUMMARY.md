---
phase: 130-extraction-mechanics-footgun-guards
plan: "01"
subsystem: companion-extraction
tags: [proof-scaffold, tdd-red, companion-guard, package-skeleton]
dependency_graph:
  requires: []
  provides: [CompanionGuard stub API, phase130 RED proof targets, crosswake_rulestead skeleton, verify_companion_package.sh]
  affects: [Plans 02-05 (all depend on the RED test targets this plan creates)]
tech_stack:
  added: [packages/crosswake_rulestead]
  patterns: [frozen-MapSet guard, RED proof scaffold, poncho path-dep skeleton, parameterized verify script]
key_files:
  created:
    - lib/crosswake/companion_guard.ex
    - test/crosswake/proof/phase130_extraction_guards_test.exs
    - test/crosswake/proof/phase130_fail_closed_contract_test.exs
    - packages/crosswake_rulestead/mix.exs
    - packages/crosswake_rulestead/README.md
    - packages/crosswake_rulestead/lib/.gitkeep
    - script/verify_companion_package.sh
  modified: []
decisions:
  - "D-13: @extracted_companions is hardcoded frozen MapSet (not derived from path: deps — core names no companion)"
  - "D-17: CompanionGuard lives in lib/ (not test/support) so the guard travels with the code post-publish"
  - "D-18: Both proof files are untagged (no @moduletag) and async: true / async: false as specified"
  - "D-19: packages/crosswake_rulestead mix.exs declares {:crosswake, path: ../..} with no runtime: false"
  - "D-20: StubDepMissingCompanion is a plain module, NOT an alias to Crosswake.Companions.Rulestead"
  - "D-22: @version 0.1.0 with x-release-please-version marker; separate from core 0.1.2"
  - "D-24: package files: allowlist excludes test/, priv, guides"
  - "D-28: {:rulestead, ~> 0.1, optional: true} in companion mix.exs"
  - "CompanionGuard check_source/1 stub uses tagged tuple dispatch pattern to avoid Elixir type-checker unreachable-branch warning on placeholder :ok return"
  - "ProofAssertions.stable_id_message/7 is test/support-only; CompanionGuard raise messages use plain string interpolation instead"
  - "Self-match-avoidance in hermetic guards: @moduletag regex only (not string contains) to avoid false positives from comment/doc strings in test files"
metrics:
  duration: "28 minutes"
  completed: "2026-06-25"
  tasks_completed: 3
  files_created: 7
  files_modified: 0
status: complete
---

# Phase 130 Plan 01: Wave 0 Scaffolding Summary

Wave 0 scaffold complete: RED proof targets exist for all 5 success criteria; CompanionGuard API present (logic stubbed for Plan 03); package skeleton + verify script in place. Feedback sampling can run from task 1.

**One-liner:** RED proof test scaffold (15 tests, 7 failing by assertion) + CompanionGuard frozen MapSet stub + `packages/crosswake_rulestead/` poncho skeleton + parameterized `verify_companion_package.sh`

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Crosswake.CompanionGuard module (frozen MapSet + stubbed public API) | befb26b | lib/crosswake/companion_guard.ex |
| 2 | phase130_extraction_guards_test.exs + phase130_fail_closed_contract_test.exs (RED) | aca8f6b | test/crosswake/proof/phase130_extraction_guards_test.exs, test/crosswake/proof/phase130_fail_closed_contract_test.exs |
| 3 | packages/crosswake_rulestead/ skeleton + script/verify_companion_package.sh | fc15010 | packages/crosswake_rulestead/mix.exs, README.md, lib/.gitkeep, script/verify_companion_package.sh |

## Test Status at Plan Completion

**15 tests total, 8 passing, 7 RED (failing by assertion — expected)**

### Passing (8):
- `assert_no_static_refs!/0` finds no violations in lib/ (placeholder passes until Plan 03)
- `assert_ensure_loaded_in_function_bodies!/0` finds no violations in lib/ (placeholder passes until Plan 03)
- Non-vacuity: MIX_INCLUDE_RULESTEAD is detectable in synthetic source
- `check_source/1` does NOT detect Crosswake.Companions.Sigra alias (D-14 in-tree companion)
- `check_ensure_loaded_placement/1` does NOT flag ensure_loaded? inside def body (valid usage)
- D-27: packages/crosswake_rulestead/mix.exs created without runtime: false — passes now
- Hermetic lane guard (extraction guards file): no @moduletag present
- Hermetic lane guard (fail-closed file): no @moduletag present

### RED (7 — failing by assertion, not load errors):
- EXTRACT-01 (2 tests): mix.exs still has MIX_INCLUDE_* blocks — Plan 02 removes them
- EXTRACT-03 non-vacuity: `check_source/1` stub returns :ok for violating input — Plan 03 implements AST walk
- EXTRACT-04 non-vacuity: `check_ensure_loaded_placement/1` stub returns :ok for violating input — Plan 03 implements AST prune-walk
- COMPAT-01 SC#5: RouteGate returns :origin_denied (not :dependency_missing) — Plan 02 wires check_dependencies/2
- D-02 precedence: RouteGate produces :kill_switch_active instead of :dependency_missing — Plan 02 wires dep check before kill-switch
- D-08: validate_dependency/0 raise doesn't produce :dependency_missing — Plan 02 adds try/rescue

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Elixir type-checker warning on unreachable pattern in check_source/1 and check_ensure_loaded_placement/1**
- **Found during:** Task 1 verification (`mix compile --warnings-as-errors`)
- **Issue:** Stub functions returned `:ok` unconditionally, causing the Elixir type checker to flag the `{:violation, nodes}` match arm as unreachable (`dynamic(:ok)` pattern mismatch)
- **Fix:** Changed stub bodies to use a tagged tuple dispatch `{:ok_placeholder, []} |> case do` pattern that preserves the return type polymorphism without triggering the type-checker's unreachability analysis
- **Files modified:** lib/crosswake/companion_guard.ex
- **Commit:** befb26b

**2. [Rule 1 - Bug] ProofAssertions.stable_id_message/7 unavailable in lib/ context**
- **Found during:** Task 1 verification (`mix compile --warnings-as-errors`)
- **Issue:** `Crosswake.TestSupport.ProofAssertions` is a test/support module only compiled in `:test` env; `lib/crosswake/companion_guard.ex` cannot alias it
- **Fix:** Replaced ProofAssertions call with plain string interpolation in the raise messages (same `stable_id_message` format, no functional difference)
- **Files modified:** lib/crosswake/companion_guard.ex
- **Commit:** befb26b

**3. [Rule 1 - Bug] Nested defmodule with full qualified atom name fails inside test module**
- **Found during:** Task 2 verification (`mix test ...`)
- **Issue:** Defining `defmodule Crosswake.TestSupport.StubDepMissingCompanion` inside `defmodule Crosswake.Proof.Phase130FailClosedContractTest` causes the stub's fully-qualified name to be resolved as nested under the test module, making struct references unresolvable
- **Fix:** Moved all stub companion module definitions to the TOP of the file, OUTSIDE the test module (standard Elixir pattern for inline test helpers)
- **Files modified:** test/crosswake/proof/phase130_fail_closed_contract_test.exs
- **Commit:** aca8f6b

**4. [Rule 1 - Bug] Hermetic lane guard self-assertion false positives**
- **Found during:** Task 2 verification (`mix test ...`)
- **Issue:** The hermetic self-check used `String.contains?(source, ":requires_example_host")` but the file's own comments and error message strings contain that substring, causing the guard to fail against its own source
- **Fix:** Changed self-assertions to only check for `@moduletag` regex pattern (the actual dangerous case), removing the string contains checks that were tripping on comments
- **Files modified:** test/crosswake/proof/phase130_extraction_guards_test.exs, test/crosswake/proof/phase130_fail_closed_contract_test.exs
- **Commit:** aca8f6b

**5. [Rule 1 - Bug] D-27 guard false positive from comment string in package mix.exs**
- **Found during:** Task 3 verification (`mix test ...`)
- **Issue:** The comment `# D-19: NO runtime: false — core is a RUNTIME dep` in packages/crosswake_rulestead/mix.exs contained the literal string `runtime: false`, causing the D-27 guard test to trigger on the comment
- **Fix:** Rewrote the comment to `# D-19: core is a RUNTIME dep of the companion (no :runtime option needed)` — same intent, no false trigger
- **Files modified:** packages/crosswake_rulestead/mix.exs
- **Commit:** fc15010

## Verification Results

- `Crosswake.CompanionGuard` compiles clean under `--warnings-as-errors` ✓
- `@extracted_companions` is a frozen MapSet containing exactly `Crosswake.Companions.Rulestead` ✓
- Public functions exported: `check_source/1`, `check_ensure_loaded_placement/1`, `assert_no_static_refs!/0`, `assert_ensure_loaded_in_function_bodies!/0`, `extracted_companions/0` ✓
- No AST logic implemented yet (placeholder bodies); moduledoc notes Plan 03 fills it in ✓
- Both proof files compile and load without `UndefinedFunctionError` / missing-module errors ✓
- Tests are RED via assertion failures, not load errors ✓
- Extraction-guards test is `async: true`, untagged ✓
- Fail-closed test is `async: false`, defines `StubDepMissingCompanion` implementing all 6 `@behaviour Crosswake.Companion` callbacks ✓
- D-02 precedence + D-08 raise assertions present ✓
- Non-vacuity pairs present (Sigra alias NOT detected = passing) ✓
- `packages/crosswake_rulestead/mix.exs` declares `{:crosswake, path: "../.."}` with NO `runtime: false` ✓
- `@version "0.1.0"` with `# x-release-please-version` marker; release-please config NOT touched ✓
- `files:` allowlist excludes `test/`, `priv`, `guides` ✓
- `cd packages/crosswake_rulestead && mix compile` succeeds with empty lib/ skeleton ✓
- `script/verify_companion_package.sh` is executable, `bash -n` clean, parameterized on `$1` ✓

## Known Stubs

| Stub | File | Line | Reason |
|------|------|------|--------|
| `check_source/1` returns `:ok` unconditionally | lib/crosswake/companion_guard.ex | ~55 | Plan 03 implements AST walk (EXTRACT-03) |
| `check_ensure_loaded_placement/1` returns `:ok` unconditionally | lib/crosswake/companion_guard.ex | ~75 | Plan 03 implements AST prune-walk (EXTRACT-04) |

These stubs are intentional Wave 0 placeholders. They cause 4 of the 7 RED tests to fail (the non-vacuity pairs). The guards still function correctly for the "no violations found" case (lib/ is clean — those tests pass). Plans 02-03 turn the stubs green.

## Threat Flags

None. No new network endpoints, auth paths, file access patterns beyond what the plan specified. The only new trust boundaries are the guard module (pure lib/ AST analysis, no I/O except `File.read!`) and the proof test stubs (test-only, no runtime exposure).

## Self-Check: PASSED

- lib/crosswake/companion_guard.ex: FOUND
- test/crosswake/proof/phase130_extraction_guards_test.exs: FOUND
- test/crosswake/proof/phase130_fail_closed_contract_test.exs: FOUND
- packages/crosswake_rulestead/mix.exs: FOUND
- packages/crosswake_rulestead/README.md: FOUND
- packages/crosswake_rulestead/lib/.gitkeep: FOUND
- script/verify_companion_package.sh: FOUND
- Commits: befb26b (CompanionGuard), aca8f6b (RED tests), fc15010 (skeleton+script)
- `mix compile --warnings-as-errors`: CLEAN
- 15 tests, 8 passing, 7 RED by assertion (not load error)
