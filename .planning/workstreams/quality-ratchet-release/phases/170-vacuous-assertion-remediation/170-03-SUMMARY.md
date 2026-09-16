---
phase: 170-vacuous-assertion-remediation
plan: 03
subsystem: testing
tags: [elixir, exunit, vacuous-assertion, test-quality, release-graph]

requires:
  - phase: 170-02
    provides: refute Enum.empty?(...) guards at all 52 frozen needs-fix sites; the itemized structural proof (phase170_guard_expression_match_test.exs); a regenerated, clean ledger
provides:
  - Genuine, executing empty-input regression tests at four filtered/file-derived D-12.2 sites (doctor, support_matrix, evidence_manifest, release_boundaries)
  - A genuine, executing empty-input regression test at the mirror publish NOOP release-graph site
  - A named, reasoned disposition for the two release-graph refutation sites (coordinate, crosswake_release_status) that cannot be forced empty without a lib/ change
  - A regenerated, byte-identical, zero-needs-fix ledger reflecting the tree after these additions
affects: [170-04, VACG-01]

actuals:
  tokens: 13150
  tasks: 3
  commits: 3
  plan_head_before: c93ea7b1

tech-stack:
  added: []
  patterns:
    - "Symlink-the-whole-repo-and-mutate-one-file cwd override (test/crosswake/proof/phase169_diagnostic_legibility_test.exs's own idiom), reused here to drive Crosswake.ReleaseStatus.build/1's real companion_components computation to an empty list via its existing :cwd keyword option, without touching lib/ or fabricating a bypass."
    - "Two-part empty-input regression shape: assert the driven collection is genuinely == [] (so a raise cannot be mistaken for an unrelated failure), then assert_raise ExUnit.AssertionError on the exact guard expression (refute Enum.empty?(collection))."
    - "Reachability-first disposition: before writing a regression, trace whether the guarded collection is derived from test input at all, or from a compile-time-fixed source (Artifact.packages/0) or a check-only-emitted-when-nonempty computation (ReleaseStatus's presence_check/unverifiable_check) — and record 'not reachable without lib/' explicitly rather than fabricate a bypass."

key-files:
  created: []
  modified:
    - test/crosswake/doctor/doctor_test.exs
    - test/crosswake/support_matrix/support_matrix_test.exs
    - test/crosswake/guides/evidence_manifest_test.exs
    - test/crosswake/guides/release_boundaries_test.exs
    - test/crosswake/release_candidate/mirror_test.exs
    - script/collection_assertion_ledger.json
    - script/inventory_collection_assertions.exs

key-decisions:
  - "coordinate_test.exs's companions collection is recorded as structural-test-only: Coordinate.validate!/1 derives `companions` from the compile-time-fixed `Artifact.packages() |> tl()`, never from the test's input map, and rejects (invalid!/0) any artifact list that does not exactly equal Artifact.packages() — no test-constructible input can drive it to []."
  - "crosswake_release_status_test.exs's four flagged refutation sites are recorded as structural-test-only: lib/crosswake/release_status.ex only ever emits the release.live_registry_presence / _unverifiable error checks when their evidence list is already non-empty (the `if missing == [] do [] else [...]` / `if unavailable == [] do [] else [...]` pattern), and status.checks overall always includes a fixed base_checks list — no probe fixture can produce a check that exists with empty evidence, or an empty overall checks list."
  - "release_boundaries_test.exs's independent_companions IS reachable: Crosswake.ReleaseStatus.build/1 already accepts a :cwd keyword override (used elsewhere in the codebase for exactly this kind of synthetic-environment test), so a symlink-the-repo-and-mutate-the-manifest helper drives companion_components to [] via the real production computation without any lib/ change."
  - "Two pre-existing @manual_overrides entries in script/inventory_collection_assertions.exs (mirror_test.exs:204, doctor_test.exs:1770) were keyed to exact line numbers that shifted when this plan's tests were inserted above them. Left unrenumbered, the classifier's heuristic scan would have reported both as needs-fix on regeneration. Updated both override keys to their current lines (227, 1790) with the same citations, plus an inline note explaining the renumbering."

patterns-established:
  - "When a D-12.2 site's collection is derived from a compile-time-fixed source or a conditionally-emitted computation, the correct outcome is a named, reasoned disposition in the plan SUMMARY — never a fabricated bypass or a silently dropped site."

requirements-completed: [VAC-02]

coverage:
  - id: D1
    description: "Four filtered/file-derived D-12.2 sites (doctor, support_matrix, evidence_manifest, release_boundaries) each have an executing empty-input regression test that drives the real production call path to an empty collection and proves the plan 170-02 guard raises ExUnit.AssertionError."
    requirement: "VAC-02"
    verification:
      - kind: unit
        ref: "test/crosswake/doctor/doctor_test.exs#phase 170: an empty commerce-corridor findings list now fails instead of passing vacuously"
        status: pass
      - kind: unit
        ref: "test/crosswake/support_matrix/support_matrix_test.exs#phase 170: an empty release-boundary target filter now fails instead of passing vacuously"
        status: pass
      - kind: unit
        ref: "test/crosswake/guides/evidence_manifest_test.exs#phase 170: an empty manifest_values list now fails instead of passing vacuously"
        status: pass
      - kind: unit
        ref: "test/crosswake/guides/release_boundaries_test.exs#phase 170: an empty independent-companion list now fails instead of passing vacuously"
        status: pass
    human_judgment: false
  - id: D2
    description: "The mirror publish NOOP release-graph site has an executing empty-input regression test that drives Mirror.evaluate!/1's real computation to push_arguments: [] and proves the guard raises."
    requirement: "VAC-02"
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/mirror_test.exs#phase 170: an empty push_arguments list now fails instead of passing vacuously"
        status: pass
    human_judgment: false
  - id: D3
    description: "The two release-graph refutation sites that cannot be forced empty without a lib/ change (coordinate_test.exs's companions, crosswake_release_status_test.exs's four flagged sites) are named with a stated reason in this SUMMARY, not silently dropped."
    verification: []
    human_judgment: true
    rationale: "A named disposition is a documentation/reasoning artifact, not something a test can auto-verify as sufficient; the reasoning is recorded in key-decisions above and the Deviations section below for human review."
  - id: D4
    description: "Regenerating the ledger after all additions produces zero needs-fix rows and reproduces byte-identically via --emit-snapshot; no merge-blocking guard or required-check registration was touched by this phase."
    requirement: "VAC-02"
    verification:
      - kind: other
        ref: "elixir script/inventory_collection_assertions.exs --check"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs and test/crosswake/proof/phase170_guard_expression_match_test.exs (23 tests together)"
        status: pass
    human_judgment: false

duration: 65min
completed: 2026-09-16
status: complete
---

# Phase 170 Plan 03: Vacuous Assertion Remediation — Empty-Input Runtime Regressions Summary

**Added five genuine, executing empty-input regression tests at the runtime-derived, highest-blast-radius D-12.2 sites (doctor, support_matrix, evidence_manifest, release_boundaries, and the mirror publish NOOP path), and recorded the two release-graph refutation sites that cannot be forced empty without a `lib/` change as named, reasoned dispositions rather than silent omissions.**

## Performance

- **Duration:** 65 min
- **Started:** 2026-09-16
- **Completed:** 2026-09-16
- **Tasks:** 3/3
- **Files modified:** 7 (5 test files + 2 script files)

## Accomplishments
- `test/crosswake/doctor/doctor_test.exs`: reused the file's own zero-commerce-route `ManagedRouter` fixture to drive `Doctor.run/1`'s real commerce-corridor findings filter to `[]`, then proved the plan 170-02 guard raises.
- `test/crosswake/support_matrix/support_matrix_test.exs`: filtered `SupportMatrix.canonical/0`'s real `release_boundaries` on a target string matched by zero entries, then proved the guard raises.
- `test/crosswake/guides/evidence_manifest_test.exs`: called `manifest_values/2` against an in-test manifest map with an empty `"routes"` list (never the committed, guaranteed-nonvacuous fixture), then proved the guard raises.
- `test/crosswake/guides/release_boundaries_test.exs`: drove `Crosswake.ReleaseStatus.build/1`'s real `companion_components` computation to `[]` via its existing `:cwd` override — a temp root symlinking the entire repository except `.release-please-manifest.json`, which is rewritten to drop every `packages/crosswake_*` companion entry — then proved the guard raises.
- `test/crosswake/release_candidate/mirror_test.exs`: reused the file's own `ancestry: "EQUAL"` fixture (already proven elsewhere in the file to produce `push_arguments: []`, the real NOOP publish outcome) to prove the guard raises.
- Recorded, by name and reason, why `test/crosswake/release_candidate/coordinate_test.exs`'s `companions` and all four flagged sites in `test/mix/tasks/crosswake_release_status_test.exs` cannot be forced empty by any test-constructible input without a `lib/` change (see Deviations below).
- Regenerated `script/collection_assertion_ledger.json` after updating two `@manual_overrides` keys whose line numbers shifted from this plan's insertions; ledger reproduces byte-identically via `--emit-snapshot`, 220 rows, 0 `needs-fix`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Empty-input regressions at the four filtered/file-derived sites** - `ea8e4c7f` (feat)
2. **Task 2: Empty-input regression at the mirror release-graph site (+ named dispositions for coordinate/release_status)** - `21dd505f` (feat)
3. **Task 3: Reconcile the ledger and record the measured empty-now-fails facts** - `11668acc` (docs)

## Files Created/Modified
- `test/crosswake/doctor/doctor_test.exs` - added `phase 170: an empty commerce-corridor findings list now fails instead of passing vacuously`
- `test/crosswake/support_matrix/support_matrix_test.exs` - added `phase 170: an empty release-boundary target filter now fails instead of passing vacuously`
- `test/crosswake/guides/evidence_manifest_test.exs` - added `phase 170: an empty manifest_values list now fails instead of passing vacuously`
- `test/crosswake/guides/release_boundaries_test.exs` - added `phase 170: an empty independent-companion list now fails instead of passing vacuously` plus the `with_manifest_without_companions_cwd/1` helper
- `test/crosswake/release_candidate/mirror_test.exs` - added `phase 170: an empty push_arguments list now fails instead of passing vacuously`
- `script/collection_assertion_ledger.json` - regenerated; 220 rows, 0 needs-fix
- `script/inventory_collection_assertions.exs` - renumbered two `@manual_overrides` keys (mirror_test.exs 204→227, doctor_test.exs 1770→1790) after line drift from the new tests

## Decisions Made
See `key-decisions` in frontmatter above:
- coordinate_test.exs and crosswake_release_status_test.exs sites recorded as structural-test-only, with the specific `lib/` mechanism cited for each.
- release_boundaries_test.exs's site IS reachable via the existing `:cwd` override, using the symlink-and-mutate idiom already established in `test/crosswake/proof/phase169_diagnostic_legibility_test.exs`.
- Manual-override line-number drift was corrected rather than left to regress into `needs-fix`.

## D-14 Measured Facts (this plan)

**Regressions added, per file:**

| File | New `phase 170:` tests |
|---|---|
| `test/crosswake/doctor/doctor_test.exs` | 1 |
| `test/crosswake/support_matrix/support_matrix_test.exs` | 1 |
| `test/crosswake/guides/evidence_manifest_test.exs` | 1 |
| `test/crosswake/guides/release_boundaries_test.exs` | 1 |
| `test/crosswake/release_candidate/mirror_test.exs` | 1 |
| `test/crosswake/release_candidate/coordinate_test.exs` | 0 (structural-only, see below) |
| `test/mix/tasks/crosswake_release_status_test.exs` | 0 (structural-only, see below) |
| **Total** | **5** |

**D-12.2-named sites covered by an executing regression vs. structural-only:**

- **5 sites** covered by an executing empty-input regression (the 5 files above).
- **2 sites** covered ONLY by plan 170-02's itemized structural test (`test/crosswake/proof/phase170_guard_expression_match_test.exs`), each named with its reason:
  - `test/crosswake/release_candidate/coordinate_test.exs` (`companions`, line 33 in the ledger) — `Crosswake.ReleaseCandidate.Coordinate.validate!/1` derives `companions` from the compile-time-fixed `Artifact.packages() |> tl()` list, not from any field of the test's input map, and `validate_artifacts!/1` rejects (`invalid!/0`) any artifact list whose package set does not exactly equal `Artifact.packages()`. No test-constructible input can drive `companions` to `[]` without changing `Artifact.packages/0` itself — a `lib/` change forbidden by this phase's boundary.
  - `test/mix/tasks/crosswake_release_status_test.exs` (4 flagged sites at lines 236, 279, 413, 451) — every flagged refutation guards either `status.checks` overall (which always includes a fixed `base_checks` list regardless of input) or the `evidence` list of the `release.live_registry_presence` / `release.live_registry_unverifiable` error checks. `lib/crosswake/release_status.ex`'s `presence_check`/`unverifiable_check` builders are `if missing == [] do [] else [...]` / `if unavailable == [] do [] else [...]` — the check itself is only ever emitted when its `evidence` list is already non-empty. No probe fixture can produce a check that exists with an empty `evidence` list, and no fixture can empty `status.checks` overall, without changing `lib/crosswake/release_status.ex`.

**Ledger row total and per-bucket composition, before and after this plan:**

| Bucket | End of 170-01 | End of 170-02 | End of 170-03 (this plan) |
|---|---|---|---|
| `safe-by-construction` | 131 | 131 | 131 |
| `safe-compile-time-literal` | 4 | 4 | 4 |
| `safe-cardinality-pinned` | 17 | 25 | 25 |
| `safe-guarded` | 8 | 60 | 60 |
| `needs-fix` | 60 | 0 | 0 |
| **Total** | **220** | **220** | **220** |

No delta between 170-02's end state and 170-03's end state: this plan's 5 new tests use `assert_raise` / `Enum.empty?` / explicit `==` comparisons, deliberately avoiding the four audited collection-assertion shapes (`assert Enum.all?/any?`, `refute Enum.all?/any?`), so they contribute zero new ledger rows. The only ledger change was the line-number renumbering of two pre-existing `@manual_overrides` entries (see Deviations below) — content and bucket unchanged, confirmed by `elixir script/inventory_collection_assertions.exs --check` reporting 0 `needs-fix` both before and after the correction (the transient `needs-fix: 2` state that appeared mid-task before the override keys were updated is documented in Deviations, not present in any committed state).

**Confirmation that the regenerated ledger contains zero rows with bucket `needs-fix`:** confirmed — `Counter({'safe-by-construction': 131, 'safe-guarded': 60, 'safe-cardinality-pinned': 25, 'safe-compile-time-literal': 4})`, 0 `needs-fix` rows, measured directly from the committed `script/collection_assertion_ledger.json`.

**No merge-blocking guard or required-check registration was added by this phase (D-13, ROADMAP success criterion #3):**

```
git diff --stat 817102b0744080d12338c26d9c488e90f6cc3dc2..HEAD -- script/check_absence_is_not_success.exs script/required_check_policy.json .github lib
```

produces empty output (confirmed at Task 3 and re-confirmed for this SUMMARY) — neither `script/check_absence_is_not_success.exs` nor `script/required_check_policy.json` nor any file under `.github/workflows/` nor `lib/` was touched anywhere in this phase (plans 170-01 through 170-03).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected two `@manual_overrides` line-number keys that drifted out of sync with the classifier**
- **Found during:** Task 3 (ledger reconciliation)
- **Issue:** `script/inventory_collection_assertions.exs`'s `@manual_overrides` map keys sites by exact `(file, line)` pairs. This plan's Task 1 inserted 23 new lines above `test/crosswake/doctor/doctor_test.exs`'s existing manual-override site (204→227 for mirror_test.exs was caused by Task 2's insertion above it), which shifted the override lookup key out of alignment with the actual assertion line. Regenerating the ledger with the stale keys produced 2 `needs-fix` rows (`test/crosswake/doctor/doctor_test.exs:1790` and `test/crosswake/release_candidate/mirror_test.exs:227`) where the classifier's heuristic scan, lacking the manual override, could not find a preceding cardinality-pin or guard for these two known-safe, already-reasoned sites.
- **Fix:** Updated the two `@manual_overrides` map keys to their current line numbers (mirror_test.exs 204→227, doctor_test.exs 1770→1790), refreshed the doctor_test.exs citation's confirmation-run line reference (1751→1774), and added an inline note that the line shift is from this plan's own insertions, not a content change. Regenerated the ledger: 0 `needs-fix` rows, byte-identical `--emit-snapshot` reproduction confirmed.
- **Files modified:** `script/inventory_collection_assertions.exs`, `script/collection_assertion_ledger.json`
- **Verification:** `elixir script/inventory_collection_assertions.exs --check` exits 0; `--emit-snapshot | diff - script/collection_assertion_ledger.json` prints nothing.
- **Committed in:** `11668acc` (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (1 bug — Rule 1)
**Impact on plan:** Necessary correctness fix to keep the ledger's manual-override mechanism aligned with the tree after this plan's own additions. No scope creep; no `lib/` change.

## Issues Encountered
None beyond the deviation above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All D-12.2 runtime-derived, highest-blast-radius sites this plan targeted are either covered by an executing empty-input regression or recorded with a named, reasoned disposition.
- The ledger is current, clean (0 `needs-fix`), and reproduces byte-identically.
- No `lib/` or `.github/` file was modified anywhere across plans 170-01 through 170-03.
- Ready for plan 170-04's already-completed vacuity-taxonomy convention work to close out the phase (170-04 was executed and summarized ahead of this plan per the git history; no further sequencing action needed here).

---
*Phase: 170-vacuous-assertion-remediation*
*Completed: 2026-09-16*
