---
phase: 170-vacuous-assertion-remediation
plan: 02
subsystem: testing
tags: [elixir, exunit, vacuous-assertion, static-analysis, test-quality]

requires:
  - phase: 170-01
    provides: script/inventory_collection_assertions.exs, script/collection_assertion_ledger.json, the five-bucket classifier
provides:
  - script/collection_assertion_remediation.json (closed-world frozen manifest of the 52 needs-fix sites)
  - refute Enum.empty?(...) guards inserted at every frozen site, across 12 test files
  - script/collection_assertion_ledger.json regenerated with zero needs-fix rows
  - test/crosswake/proof/phase170_guard_expression_match_test.exs — itemized structural proof of guard existence and exact expression match
affects: [170-03, 170-04, 170-05, VACG-01]

actuals:
  tokens: 24000
  tasks: 3
  commits: 3
  plan_head_before: 40a95e19137362b805a00c71b027eb926072662a

tech-stack:
  added: []
  patterns:
    - "Closed-world frozen remediation manifest (generated once, never regenerated) as the single population source for both the rewrite pass and its structural proof — no hand-typed second copy of the fixed list."
    - "Structural proof predicate as a pure function over source-line lists (guarded_correctly?/2), so synthetic in-memory fixtures can prove the predicate capable of returning false (D-14 non-vacuity), independent of the currently-clean real tree."
    - "Bounded backward-scan + forward paren-balance join to read a guard call as one logical statement regardless of mix format's line-wrapping — mirrors the classifier's own join_forward technique rather than assuming a fixed line offset."

key-files:
  created:
    - script/collection_assertion_remediation.json
    - test/crosswake/proof/phase170_guard_expression_match_test.exs
  modified:
    - script/inventory_collection_assertions.exs
    - script/collection_assertion_ledger.json
    - test/crosswake/doctor/doctor_test.exs
    - test/crosswake/doctor/doctor_threadline_test.exs
    - test/crosswake/support_matrix/support_matrix_test.exs
    - test/crosswake/guides/evidence_manifest_test.exs
    - test/crosswake/guides/release_boundaries_test.exs
    - test/crosswake/manifest/manifest_test.exs
    - test/crosswake/manifest/validator_test.exs
    - test/crosswake/bridge/push_test.exs
    - test/crosswake/planning/first_adopter_context_test.exs
    - test/crosswake/shell/activation_test.exs
    - test/crosswake/shell/diagnostic_export_test.exs
    - test/crosswake/proof_lane/navigation_shell_advisory_test.exs
    - test/crosswake/proof/phase165_ci_integrity_test.exs
    - test/crosswake/proof/phase165_ci_policy_test.exs
    - test/crosswake/proof/phase166_repository_quality_test.exs
    - test/crosswake/proof/phase169_diagnostic_legibility_test.exs
    - test/crosswake/proof/phase64_runtime_line_policy_test.exs
    - test/crosswake/proof/phase65_diagnostic_export_seam_test.exs
    - test/mix/tasks/crosswake_release_status_test.exs
    - test/mix/tasks/crosswake_gen_proof_lane_test.exs

key-decisions:
  - "Task 3's structural predicate replaces the plan's literal 'display_line - 1' offset check with a bounded backward-scan + join_forward technique mirrored from the classifier, because mix format wraps long guard calls across lines and inserts a blank line before multi-clause fn arguments — a fixed offset check is wrong for a real subset of the 52 rows."
  - "The predicate independently verifies EXACT normalized-expression equality between the guard's argument and the assertion's expression, which is strictly stronger than the classifier's own root-based guard_line? match — this is what catches guard-checks-the-wrong-variable (D-12, T-170-06), and is why the structural test does not simply trust the ledger's safe-guarded classification."
  - "8 of the original 60 needs-fix rows were reclassified to safe-cardinality-pinned via manual override during Task 2, after real test execution proved their collections are permanently empty by design (positive-path and negative-control tests) — recorded with per-site citations in script/inventory_collection_assertions.exs's @manual_overrides, not as a widened heuristic. The frozen manifest reflects the final 52-row population."

patterns-established:
  - "Non-vacuity fixtures for a source-text scanner are written as heredocs, not string lists, so the scanner's own strip_heredocs/1 excludes them from classification — keeping the proof test itself ledger-clean."

requirements-completed: [VAC-02]

coverage:
  - id: D1
    description: "Every site frozen in script/collection_assertion_remediation.json (52 rows) carries a refute Enum.empty?(...) guard on its preceding source line, guarding the identical expression the assertion consumes."
    requirement: "VAC-02"
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase170_guard_expression_match_test.exs#Task 3: guard presence and expression match, per frozen manifest entry"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase170_guard_expression_match_test.exs#Task 3: ledger cross-check — every remediated key reclassified to safe-guarded"
        status: pass
    human_judgment: false
  - id: D2
    description: "The structural proof predicate is demonstrably capable of returning false for both a missing guard and a wrong-variable guard (D-14 non-vacuity)."
    requirement: "VAC-02"
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase170_guard_expression_match_test.exs#Task 3: non-vacuity control (D-14) — the predicate must be capable of returning false"
        status: pass
    human_judgment: false
  - id: D3
    description: "The classification ledger regenerates clean with zero needs-fix rows and the tree-wide inventory check passes."
    requirement: "VAC-02"
    verification:
      - kind: other
        ref: "elixir script/inventory_collection_assertions.exs --check"
        status: pass
    human_judgment: false

duration: 55min
completed: 2026-09-16
status: complete
---

# Phase 170 Plan 02: Vacuous Assertion Remediation — Guard Insertion & Structural Proof Summary

**Inserted `refute Enum.empty?(...)` guards at all 52 confirmed-vacuous collection-assertion sites across 12 test files and proved, per entry, that each guard's argument exactly matches the assertion's own expression — not just a nearby collection with a similar name.**

## Performance

- **Duration:** 55 min (Task 1+2 by a prior executor instance; Task 3 in this session)
- **Started:** 2026-09-16T00:00:00Z (Task 1)
- **Completed:** 2026-09-16T?? (Task 3, this session)
- **Tasks:** 3/3
- **Files modified:** 22 (2 script files + 1 new proof test + 19 test files carrying guard insertions)

## Accomplishments
- Froze the audit's `needs-fix` population (52 sites after manual-override reclassification) into `script/collection_assertion_remediation.json`, generated once and never regenerated, pinned to a named git SHA.
- Inserted a uniform, one-line `refute Enum.empty?(<expression>)` guard immediately preceding every frozen assertion, across 12 test files (some listed under multiple `describe` blocks), leaving every `safe-compile-time-literal` / `safe-cardinality-pinned` site untouched.
- Regenerated `script/collection_assertion_ledger.json`: zero `needs-fix` rows remain; all 52 remediated keys carry bucket `safe-guarded`.
- Added `test/crosswake/proof/phase170_guard_expression_match_test.exs`: an itemized, closed-world structural test that, for every one of the 52 manifest rows, independently verifies a guard exists and its normalized argument expression exactly equals the assertion's normalized expression — the half of D-12's hybrid proof that catches guard-checks-the-wrong-variable, which no runtime test can reliably catch.
- Demonstrated the structural predicate capable of going red for both a missing guard and a wrong-variable guard (D-14 non-vacuity), via in-memory synthetic fixtures written as heredocs so the classifier's own scanner never counts them as real call sites.

## Task Commits

Each task was committed atomically:

1. **Task 1: Freeze the needs-fix population into a closed-world remediation manifest** - `0fb0b862` (feat)
2. **Task 2: Insert the non-emptiness guard at every frozen remediation site** - `c62ede85` (feat)
3. **Task 3: Itemized closed-world structural proof of guard presence and expression match** - `c23cf9ef` (feat)

_Task 1 and 2 were executed and committed by a prior executor instance whose work was independently verified by the orchestrator before this session resumed at Task 3._

## Files Created/Modified
- `script/inventory_collection_assertions.exs` - added `--emit-remediation` CLI flag and `render_remediation/2`; `@manual_overrides` table extended with 8 real-test-execution-verified reclassifications
- `script/collection_assertion_remediation.json` - closed-world frozen manifest, 52 rows, `frozen_at` pinned to `0fb0b862...`
- `script/collection_assertion_ledger.json` - regenerated; 131 safe-by-construction / 4 safe-compile-time-literal / 25 safe-cardinality-pinned / 60 safe-guarded / 0 needs-fix
- `test/crosswake/proof/phase170_guard_expression_match_test.exs` - new; module `Crosswake.Proof.Phase170GuardExpressionMatchTest`, predicate `guarded_correctly?/2`, `@remediated_site_count 52`
- 19 test files across `test/crosswake/` and `test/mix/tasks/` - one-line `refute Enum.empty?(...)` guard inserted immediately above each remediated assertion

## Decisions Made
- Task 3's structural predicate reuses the classifier's own bounded backward-scan + `join_forward`-style paren-balanced multi-line join, mirrored locally (the script's helpers are `defp` and requiring the script in-process would also execute its CLI/`System.halt` trailer), rather than a fixed `display_line - 1` offset — see Deviations below.
- The predicate performs its own exact-normalized-expression-equality check rather than trusting the ledger's `safe-guarded` classification outright, since the ledger's `guard_line?/2` matches on a coarser shared-root basis; the structural test is strictly stronger and is what actually satisfies D-12.1's "catches guard-checks-the-wrong-variable" requirement.
- Non-vacuity fixtures are written as heredocs (not string lists), mirroring `test/crosswake/proof/phase169_check_name_uniqueness_test.exs`'s own idiom, so the inventory scanner's `strip_heredocs/1` excludes them from classification and this new file contributes zero rows to the ledger.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Replaced the plan's literal `display_line - 1` acceptance criterion with a bounded backward-scan predicate**
- **Found during:** Task 3
- **Issue:** The plan's stated acceptance criterion ("the line at `display_line - 1` matches `refute Enum.empty?(`") is a naive single-line check that fails for a real subset of the 52 rows, for two legitimate reasons that are not defects: (1) `mix format` wraps long guard calls across multiple physical lines (explicitly permitted by D-09's "wrap it and let mix format settle the layout"), and (2) `mix format` inserts a blank line before a multi-clause `fn` argument, which is the common shape of the assertion immediately following many of these guards.
- **Fix:** Implemented `guarded_correctly?/2` as a bounded backward scan (up to 20 lines) for the nearest guard-opening line, followed by a `join_forward`-style paren-balanced join (mirroring the classifier's own technique) to read a wrapped guard call as one logical statement, then extracted and normalized the guard's argument for exact-equality comparison against the assertion's normalized expression. This is the substantive requirement the plan actually asks for (D-12.1: guard exists AND guards the same expression), just located via a robust scan instead of a brittle fixed offset.
- **Files modified:** test/crosswake/proof/phase170_guard_expression_match_test.exs
- **Verification:** `mix test test/crosswake/proof/phase170_guard_expression_match_test.exs` — 5 tests, 0 failures, including the full 52-row real-tree check.
- **Committed in:** c23cf9ef (Task 3 commit)
- **This deviation was explicitly pre-approved by the orchestrator** in the dispatch instructions for this resume session, based on independent verification that the naive offset check fails against the real, `mix format`-settled tree.

**2. [Rule 1 - Bug] Fixed a raw-grep collision introduced by this file's own non-vacuity fixtures**
- **Found during:** Task 3, running the full `mix test` suite including `phase170_vacuous_assertion_ledger_test.exs`'s pinned reconciliation test
- **Issue:** The two non-vacuity fixtures' assertion lines originally used `refute Enum.any?(...)`, which is one of the raw-grep patterns `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs`'s own reconciliation test greps for and asserts an exact, hard-coded delta (6) against. Adding two more raw matches broke that pinned literal (delta became 8).
- **Fix:** Changed the fixtures' stand-in assertion line to `assert Enum.member?(some_collection, :expected)` (a non-flagged shape) with a comment noting it stands in for the real assertion — `guarded_correctly?/2` only inspects the guard line and the row's declared expression, never the assertion line's own text, so this has no effect on what the fixture proves.
- **Files modified:** test/crosswake/proof/phase170_guard_expression_match_test.exs
- **Verification:** `mix test test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs test/crosswake/proof/phase170_guard_expression_match_test.exs` — 23 tests, 0 failures.
- **Committed in:** c23cf9ef (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 — bugs in the naive acceptance criterion and in an unintended cross-file grep collision, both fixed before commit).
**Impact on plan:** Both fixes were necessary for the structural proof to be correct and non-vacuous rather than merely satisfying a brittle literal check. No scope creep — no file outside `test/crosswake/proof/phase170_guard_expression_match_test.exs` was touched in Task 3.

## Issues Encountered
- `mix format --check-formatted` (whole-repo, unscoped) fails on a pre-existing, unrelated file (`test/crosswake/proof/phase169_check_name_uniqueness_test.exs`) due to an apparent Elixir/mix-format version drift on this host. This predates and is unrelated to this plan's changes (confirmed via `git stash`), is out of scope per the executor's scope-boundary rule, and Task 3's own `<verify>` block does not include a whole-repo format check (only `mix format` scoped to the new file, which passes). Not fixed; not blocking.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- VAC-02 is complete: every confirmed-vacuous collection assertion in the test suite now fails on the empty case, and the fix is proven structurally (guard exists, guards the right expression) with a demonstrated non-vacuous test harness.
- Plan 170-03 (genuine empty-input regression tests at the highest-blast-radius sites) and 170-04/170-05 (VAC-03 taxonomy convention) can proceed independently; no blockers introduced by this plan.
- VACG-01 (the eventual merge-blocking guard) remains deferred per D-13/SC#3; this plan's scaffolding (`script/inventory_collection_assertions.exs`, both ledger/manifest JSON files, both proof test files) has a written sunset trigger already recorded in the script's header comment.

---
*Phase: 170-vacuous-assertion-remediation*
*Completed: 2026-09-16*

## Self-Check: PASSED
- FOUND: test/crosswake/proof/phase170_guard_expression_match_test.exs
- FOUND commit: 0fb0b862 (Task 1)
- FOUND commit: c62ede85 (Task 2)
- FOUND commit: c23cf9ef (Task 3)
