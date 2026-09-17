---
phase: 170-vacuous-assertion-remediation
plan: 05
subsystem: testing
tags: [vacuity-taxonomy, elixir, exunit, verification-convention, vac-03, absence-is-not-success]

# Dependency graph
requires:
  - phase: 170-04
    provides: "VERIFICATION-CONVENTIONS.md's vacuity_taxonomy field spec and body-section shape; 169-VACUITY-TAXONOMY.md's sibling-addendum precedent"
  - phase: 170-01
    provides: "the measured ledger-completeness counts (220 audited rows) this record cites"
  - phase: 170-02
    provides: "the measured guard-expression-match counts (52-row manifest) this record cites"
  - phase: 170-03
    provides: "the measured empty-input regression counts (5 executing, 2 structural-only) this record cites"
provides:
  - "170-VACUITY-TAXONOMY.md — Phase 170's own record against the six-shape taxonomy, with a measured non-vacuity fact per check"
  - "test/crosswake/proof/phase170_vacuity_taxonomy_convention_test.exs — the vacuity_taxonomy convention turned into a decidable, executing, proven-red check"
affects: [171, 172, 173, 174, 175]

actuals:
  tokens: 3900
  tasks: 2
  commits: 2
  plan_head_before: 44ed0d8c

tech-stack:
  added: []
  patterns:
    - "Pure-predicate extraction over a directory listing plus file contents (taxonomy_recorded?/2), mirroring test/crosswake/proof/phase169_check_name_uniqueness_test.exs's non-vacuity-fixture idiom, so a synthetic tmp_dir fixture can prove the predicate capable of returning both false and true independently of the real, currently-compliant tree."
    - "Findings-floor test as a standing D-14 guard against a Path.wildcard glob silently matching zero directories and turning a presence check into a green no-op."

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/170-vacuous-assertion-remediation/170-VACUITY-TAXONOMY.md
    - test/crosswake/proof/phase170_vacuity_taxonomy_convention_test.exs
  modified: []

key-decisions:
  - "Used the Elixir test module's own name (e.g. Crosswake.Proof.Phase170GuardExpressionMatchTest) as the check_id for the two meta-check entries, rather than a registered [crosswake] check code, since these checks have no such code — grep -rn against the module name resolves to its defining file, satisfying the acceptance criterion's greppability requirement without inventing a code these checks don't emit."
  - "Used the shared test-name prefix 'phase 170: an empty' as the check_id for the empty-input regression set (one entry covering all 5 executing regressions plus the 2 named structural-only dispositions), since the regression set is one D-12 mechanism applied at 7 named sites, not 7 independent registered checks — grep -rn 'phase 170: an empty' test matches all 5 regression test names."
  - "The ledger-completeness check and the guard-expression-match check both use the convention's explicit escape form ('matches none of A-F, because ___') rather than a forced Shape A letter, since both are meta-checks that verify properties OF the test suite's own collection-assertion population (completeness of classification; guard-presence-and-expression-match), not bare-boolean predicates over an open-world possibly-empty collection themselves — this directly mirrors Phase 169's D-15 precedent for release.scanner.roster_exact and release.workflow_integrity."
  - "The convention-presence check (this plan's own Task 2) and the empty-input regression set both classify as Shape A: the convention check's own Path.wildcard-derived directory collection is exactly the shape-A risk (possibly-empty at runtime), mitigated by the D-14 findings-floor test in the same file the taxonomy entry cites; the regression set is Shape A's fix (refute Enum.empty? guards) demonstrated raising on genuinely-forced-empty production collections."
  - "170-VACUITY-TAXONOMY.md is produced as its own sibling file rather than a section appended to a not-yet-existing 170-VERIFICATION.md, resolving the 'Claude's Discretion' item left open in 170-CONTEXT.md by following the 169 precedent (retroactive addendum, own file) rather than inventing a new shape for the one phase that authors its own record inline."

patterns-established:
  - "A phase-close vacuity_taxonomy record classifying its OWN new checks (as opposed to Phase 169's retroactive record classifying checks landed before the convention existed) is produced directly by the closing plan rather than waiting for a subsequent VERIFICATION.md edit — matching D-17's 'applied by the phase-close verifier, not the executor at plan time' rule while the phase's own artifacts (170-01/02/03-SUMMARY.md) are still fresh inputs."

requirements-completed: [VAC-03]

coverage:
  - id: D1
    description: "170-VACUITY-TAXONOMY.md records all four checks Phase 170 landed against the six-shape taxonomy, each with check_id, shape (or the explicit escape form), and a non_vacuity_evidence value tracing at least one numeral to a named 170-0{1,2,3}-SUMMARY.md — no bare yes/no/true/false/checked/n/a tick anywhere."
    requirement: "VAC-03"
    verification:
      - kind: other
        ref: "grep -c non_vacuity_evidence 170-VACUITY-TAXONOMY.md == 4; grep -c PITFALLS.md == 1; grep -nE '[0-9]+' non-empty; grep -rn per check_id in test returns >=1 match each"
        status: pass
    human_judgment: false
  - id: D2
    description: "The vacuity_taxonomy convention is turned into a decidable, executing check (Crosswake.Proof.Phase170VacuityTaxonomyConventionTest) with a pure predicate proven capable of returning both false (non-compliant synthetic fixture) and true (addendum-only and section-only synthetic fixtures), plus a findings-floor test asserting the examined phase-directory count is non-zero."
    requirement: "VAC-03"
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase170_vacuity_taxonomy_convention_test.exs (7 tests, all passing, including the proven-false and two proven-true fixtures and the findings-floor test)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The new convention check is not wired into any merge-blocking scanner or required-check registry, contributes no new rows to the collection-assertion ledger, and no lib/ or .github/ file was touched anywhere in this phase."
    requirement: "VAC-03"
    verification:
      - kind: other
        ref: "grep -c 'check_absence_is_not_success\\|required_check_policy' phase170_vacuity_taxonomy_convention_test.exs == 0; elixir script/inventory_collection_assertions.exs --emit-snapshot | diff - script/collection_assertion_ledger.json (empty); git diff --name-only 817102b0744080d12338c26d9c488e90f6cc3dc2..HEAD -- lib .github (empty)"
        status: pass
    human_judgment: false

duration: 30min
completed: 2026-09-16
status: complete
---

# Phase 170 Plan 05: Vacuity Taxonomy Self-Record and Decidable Convention Check Summary

**Phase 170's own four landed checks are classified against the six-shape taxonomy with measured non-vacuity facts traced to the plans that produced them, and the VAC-03 convention is now an executing, proven-red `mix test` check rather than a review-checklist prose item.**

## Performance

- **Duration:** 30 min
- **Started:** 2026-09-16T19:20:00Z
- **Completed:** 2026-09-16T19:52:00Z
- **Tasks:** 2/2
- **Files modified:** 2 (both created)

## Accomplishments

- Created `170-VACUITY-TAXONOMY.md`, classifying all four checks Phase 170 landed: `Crosswake.Proof.Phase170GuardExpressionMatchTest` and `Crosswake.Proof.Phase170VacuousAssertionLedgerTest` recorded via the explicit "matches none of A-F" escape form (both are meta-checks over the test suite's own collection-assertion population, mirroring Phase 169's `roster_exact`/`workflow_integrity` precedent), and `Crosswake.Proof.Phase170VacuityTaxonomyConventionTest` plus the `phase 170: an empty` regression set recorded as Shape A. Every entry's `non_vacuity_evidence` is a measured fact traced to a named `170-01`/`170-02`/`170-03-SUMMARY.md`.
- Created `test/crosswake/proof/phase170_vacuity_taxonomy_convention_test.exs`, extracting `taxonomy_recorded?/2` as a pure predicate over a directory listing plus a `*-VERIFICATION.md` source string. Seven tests: the convention document's single-sourcing (contains `vacuity_taxonomy`, the verbatim null statement, and a `PITFALLS.md` link), the real-tree compliance walk, a findings-floor test (D-14: examined count must be >= 1), a real-fixture positive control (169's own addendum), and three synthetic `tmp_dir` fixtures proving the predicate capable of returning false (no section, no addendum), true via the addendum branch, and true via the direct-heading branch.
- Confirmed the examined phase-directory count today is **1** (`169-diagnostic-legibility`, the only phase carrying a `*-VERIFICATION.md` so far) — recorded per the plan's requirement to state the real observed count, not an estimate.
- Confirmed all three phase170 proof test files run together at 30 tests, 0 failures; the ledger regenerates byte-identically; the pinned `lib`/`.github` diff over the phase-170 baseline is empty.

## Task Commits

1. **Task 1: Record Phase 170's own checks against the six-shape taxonomy** - `2176afcf` (docs)
2. **Task 2: Make the convention decidable with an executing, proven-red presence check** - `3d208139` (test)

## Files Created/Modified

- `.planning/workstreams/quality-ratchet-release/phases/170-vacuous-assertion-remediation/170-VACUITY-TAXONOMY.md` - Phase 170's own vacuity-taxonomy record, 4 entries, check-ID lexical order
- `test/crosswake/proof/phase170_vacuity_taxonomy_convention_test.exs` - `Crosswake.Proof.Phase170VacuityTaxonomyConventionTest`; predicate `taxonomy_recorded?/2`; 7 tests

## Decisions Made

See `key-decisions` in frontmatter above:
- Module names used as `check_id` for the two meta-checks (no registered `[crosswake]` check code exists for either); the shared test-name prefix `phase 170: an empty` used as `check_id` for the 5-site regression set.
- Both meta-checks (`GuardExpressionMatchTest`, `VacuousAssertionLedgerTest`) recorded via the explicit escape form, mirroring Phase 169's `roster_exact`/`workflow_integrity` precedent.
- The convention-presence check and the regression set both classify as Shape A — the former because it is a `Path.wildcard`-derived possibly-empty-collection predicate (mitigated by its own findings-floor test), the latter because it is Shape A's runtime fix demonstrated raising.
- `170-VACUITY-TAXONOMY.md` produced as its own sibling file, resolving the "Claude's Discretion" item left open in `170-CONTEXT.md`, following the Phase 169 retroactive-addendum precedent.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed a literal reference to the forbidden-scanner filenames from the test module's own moduledoc**
- **Found during:** Task 2, running the acceptance-criteria grep
- **Issue:** The moduledoc's prose describing what the check is NOT wired into originally named `script/check_absence_is_not_success.exs` literally, which made `grep -c 'check_absence_is_not_success\|required_check_policy' phase170_vacuity_taxonomy_convention_test.exs` return 1 instead of the required 0 — the acceptance criterion checks for the literal substring regardless of context, since its purpose is to prove the file makes no reference at all to the merge-blocking registry's implementation.
- **Fix:** Reworded the sentence to state the same fact ("deliberately absent from every merge-blocking scanner and required-check registry in this repository") without naming either file literally.
- **Files modified:** test/crosswake/proof/phase170_vacuity_taxonomy_convention_test.exs
- **Verification:** `grep -c 'check_absence_is_not_success\|required_check_policy' test/crosswake/proof/phase170_vacuity_taxonomy_convention_test.exs` → 0; `mix test` for the file still passes 7/7 after the edit.
- **Committed in:** `3d208139` (Task 2 commit; caught before commit, so the committed file already reflects the fix)

---

**Total deviations:** 1 auto-fixed (1 blocking — Rule 3).
**Impact on plan:** Wording-only fix inside the module's own doc comment; no test logic changed. No scope creep.

## Issues Encountered

`mix format` reformatted several lines in the new test file on first pass (line-wrapping long `test "..."`/`assert`/pipe expressions past the configured line length) — expected `mix format` behavior, not a deviation; `mix format --check-formatted` passes cleanly on the committed file.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 170 is now fully closed: VAC-01 (170-01), VAC-02 (170-02, 170-03) and VAC-03 (170-04, 170-05) are all complete, with the ledger clean (0 needs-fix, 220 rows), the two structural/regression proof tests green, and the convention now enforced by a proven-red executing check.
- Phases 171-175 close per the `vacuity_taxonomy` convention `VERIFICATION-CONVENTIONS.md` defines; the convention's own presence check will re-examine each of their `*-VERIFICATION.md` files as they land, since `phase_dirs_with_verification/0` is a live `Path.wildcard` over the workstream's phase directories, not a fixed list.
- No merge-blocking guard or required-check registration was added anywhere in this phase (D-13, D-20, D-21, ROADMAP SC#3) — confirmed by the empty pinned `lib`/`.github` diff and the explicit grep asserting no reference to the merge-blocking registry.
- No blockers.

## Self-Check: PASSED

- FOUND: .planning/workstreams/quality-ratchet-release/phases/170-vacuous-assertion-remediation/170-VACUITY-TAXONOMY.md
- FOUND: test/crosswake/proof/phase170_vacuity_taxonomy_convention_test.exs
- FOUND commit: 2176afcf (Task 1)
- FOUND commit: 3d208139 (Task 2)
- Re-ran all acceptance criteria for both tasks: PASS (non_vacuity_evidence count 4, PITFALLS.md count 1, numeral lines present, no bare-tick evidence values, all check_ids grep-resolve; convention test 7/7 passing; ledger regenerates byte-identically; combined 3-file phase170 proof run is 30 tests/0 failures; pinned `lib`/`.github` diff empty; forbidden-registry grep is 0).

---
*Phase: 170-vacuous-assertion-remediation*
*Plan: 05*
*Completed: 2026-09-16*
