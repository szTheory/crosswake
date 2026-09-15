---
phase: 166
fixed_at: 2026-09-10T07:56:51Z
review_path: .planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/166-REVIEW.md
iteration: 3
findings_in_scope: 8
fixed: 8
skipped: 0
status: all_fixed
---

# Phase 166: Code Review Fix Report

**Fixed at:** 2026-09-10T07:56:51Z
**Source review:** `.planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/166-REVIEW.md`
**Iteration:** 3

**Summary:**

- Findings in scope: 8 cumulative across three review iterations
- Fixed: 8
- Skipped: 0

## Fixed Issues

### Iteration 1 / CR-01: The root formatter contract excludes every Elixir source file

**Files modified:** `.formatter.exs`, `test/crosswake/proof/phase166_repository_quality_test.exs`, `mix.exs`, the bounded `lib/**/*.ex` and `test/**/*.exs` formatter inputs that carried pre-existing drift, and three formatter-sensitive source-contract regressions
**Commits:** `bede7896`, `429c3826`, `f118b997`
**Applied fix:** Expanded the default formatter input set to the root Mix/config/lib/test Elixir surface, added a negative unformatted-source fixture, mechanically formatted the newly governed surface, and made source-contract assertions compatible with canonical formatting.

### Iteration 1 / CR-02: `repository-cleanliness` declares `git diff --check` but never executes it

**Files modified:** `script/verify_repository.mjs`, `test/js/repository_verification.test.mjs`
**Commit:** `58909029`
**Applied fix:** Runs the stage's declared fixed argv before artifact and generated-contract checks and rejects a trailing-whitespace negative control.

### Iteration 1 / WR-01: The installer advertises a nonstandard-router escape hatch that cannot work

**Files modified:** `lib/mix/tasks/crosswake.install.ex`, `test/mix/tasks/crosswake_install_test.exs`
**Commit:** `561b49d1`
**Applied fix:** Generalized router-module inference to the declared module while keeping web-module derivation explicit and fail-closed for nonstandard names; added a non-`.Router` regression using `--web-module`.

### Iteration 1 / WR-02: Archive validation checks names but permits link entries and link targets

**Files modified:** `script/run_repository_evidence_environment.sh`, `test/js/repository_verification.test.mjs`
**Commit:** `f77f3683`
**Applied fix:** Rejects tar symlink/hardlink entries and zip symlink entries before extraction, with safe-named negative controls including an escaping link target.

### Iteration 1 / WR-03: Sorted ownership edges can reject valid multi-level expansions

**Files modified:** `script/check_phase166_ownership_ledger.py`
**Commit:** `8e1731bf`
**Applied fix:** Computes graph reachability to a fixed point independently of sorted presentation order and adds a reverse-lexical multi-hop fixture.

### Iteration 2 / WR-01: Generalized router inference accepts commented and quoted decoy modules

**Files modified:** `lib/mix/tasks/crosswake.install.ex`, `test/mix/tasks/crosswake_install_test.exs`
**Commit:** `23f53625`
**Status:** fixed: requires human verification
**Applied fix:** Parses router source with `Code.string_to_quoted/1`, accepts exactly one statically named top-level `defmodule`, and fails closed for invalid, absent, or ambiguous declarations. Added a regression with leading comment, moduledoc, and string decoys before the real nonstandard router declaration.

### Iteration 2 / WR-02: The reformatted hermeticity guard no longer detects dynamic file loads

**Files modified:** `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs`
**Commit:** `192aa6f2`
**Status:** fixed: requires human verification
**Applied fix:** Replaced literal-only regex scanning with a full AST walk over every `Code.require_file` call, requiring exactly the four approved literal paths. Added a negative fixture proving a computed fifth load is counted and rejected.

### Iteration 3 / WR-01: Hermeticity AST guard misses fully qualified Code loads

**Files modified:** `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs`
**Commit:** `f426d6db`
**Status:** fixed: requires human verification
**Applied fix:** Canonicalized remote-call alias receivers with `Module.concat/1` so both `Code.require_file/2` and `Elixir.Code.require_file/2` contribute their first argument to the exact four-path contract. Added a RED/GREEN regression proving a fully qualified computed fifth load is rejected while comment and string decoys remain ignored by the AST walk.

## Verification

Iteration-2 syntax/format checks first ran in the isolated review-fix worktree. Dependency-backed focused and aggregate gates ran in the main checkout after the transactional fast-forward.

- Elixir parser checks for all three iteration-2 source/test files: passed.
- `mix format --check-formatted` for all three iteration-2 files: passed.
- `mix test test/mix/tasks/crosswake_install_test.exs test/crosswake/proof/phase34_paywall_corridor_proof_test.exs`: 26 tests, 0 failures.
- Main-checkout aggregate `mix test`: 1,600 tests, 0 failures (74 excluded).

Iteration-3 RED/GREEN and focused verification ran in the isolated review-fix worktree. The recurring contract gate and final aggregate ran in the main checkout after the transactional fast-forward, where the required dependency trees are available.

- RED regression: focused Phase 34 proof produced the expected failure because the fully qualified computed call was not counted (`16 tests, 1 failure`).
- GREEN focused Phase 34 proof: 16 tests, 0 failures.
- `mix format --check-formatted test/crosswake/proof/phase34_paywall_corridor_proof_test.exs`: passed.
- Focused Phase 34 plus Phase 166 aggregate: 29 tests, 0 failures.
- Main-checkout `script/check_phase166_clean_checkout_engineering_quality.sh`: passed every section.
- Main-checkout aggregate `mix test`: 1,601 tests, 0 failures (74 excluded).
- The first isolated recurring-gate attempt reached its browser section but could not resolve `@playwright/test` because isolated review-fix worktrees intentionally have no `node_modules`; the same gate passed in the main checkout after fast-forward.

Iteration-1 verification remains recorded by its commits and prior report state: repository JavaScript checks, focused installer/Phase 166 tests, formatter-sensitive regressions, formatter validation, evidence-environment self-tests, ownership-ledger self-tests, and the then-current 1,598-test aggregate all passed.

---

_Fixed: 2026-09-10T07:56:51Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 3_
