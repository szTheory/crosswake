---
phase: 169-diagnostic-legibility
plan: 04
subsystem: ci-diagnostics
tags: [elixir, exunit, ci-diagnostics, release-status, exit-codes, guard-test, docs]

# Dependency graph
requires:
  - phase: 169-02
    provides: "the `:unverifiable`/exit-3 vocabulary, `exit_code/1`'s @doc table, and the
      exit-contract header comments this plan's guard test pins"
  - phase: 169-03
    provides: "the shell exit-contract header comment on
      script/check_required_checks_registered.sh this plan's guard test asserts"
provides:
  - "A merge-blocking guard test (`test/crosswake/proof/phase169_exit_contract_guard_test.exs`)
    that reads each of 6 verification entry points' source and asserts its literal exit values
    against a declared per-entry-point table, so the shipped codes cannot drift from the
    documented contract without turning the test red (FID-02, D-24)."
  - "A measured non-vacuity floor: the guard reports how many entry points it actually located
    (6 of 6) and fails loudly if that count drops below 4, instead of passing vacuously."
  - "A runbook link from docs/COMPANION-PUBLISH-RUNBOOK.md to
    Crosswake.ReleaseStatus.exit_code/1's @doc as the single canonical exit-code source (D-16),
    plus a disambiguating sentence for check_release_version_truth.exs's separate, unchanged
    exit-2 BLOCKED vocabulary."
affects: [170, 171, release-status, ci-diagnostics]

# Actuals (#2632)
actuals:
  tokens: 2981
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Declared @entry_points table as the contract, file source as the implementation:
       per-entry-point expected exit-value set, extraction kind, and header-comment
       requirement, with equality asserted in both directions (missing/extra) rather than
       mere containment."
    - "File-kind-appropriate literal-exit extraction: bash `exit <n>`, `System.halt(<n>)`,
       literal case-arm heads for a `case exit_code(status) do 0 -> ... end` construct, and
       literal `do:`/`else:` branch integers for an `if ..., do: 0, else: 1` idiom — chosen per
       file rather than one generic regex, since each entry point expresses its exit values in
       a different Elixir/shell idiom."
    - "Non-vacuity floor reported even on success (D-24): the located-entry-point count is
       asserted and surfaced in the failure/success message, not silently assumed."

key-files:
  created:
    - test/crosswake/proof/phase169_exit_contract_guard_test.exs
  modified:
    - docs/COMPANION-PUBLISH-RUNBOOK.md

key-decisions:
  - "Added a 6th entry-point record for `Crosswake.ReleaseStatus.exit_code/1`'s own source
     clauses (extracting the literal `do: <n>` from each `def exit_code(...)` head, skipping the
     delegating `def exit_code(%{status: status}), do: exit_code(status)` clause) alongside the
     5 file-based checks the plan's behavior table names. This pins the function's own return
     values against drift, distinct from and in addition to the separate `@doc`-content
     assertion (read via `Code.fetch_docs/1`) the plan also requires — satisfying the acceptance
     criterion of at least 6 declared records each carrying an explicit expected exit-value set."
  - "Chose `script/check_release_version_truth.exs` as the mutation-test target (mutating the
     unique `System.halt(1)` literal to `System.halt(9)`) since it has a single unambiguous
     `System.halt(<n>)` idiom per exit value, making the mutation's effect on the extracted set
     easy to state precisely (loses 1, gains 9)."
  - "Marked `header_required: false` for `script/verify_generated_ios_shell.sh` and
     `script/check_release_version_truth.exs` — D-16 scopes the one-line header comment to
     'shell and .exs verifiers' Phase 169 actually touches (the mix task and
     check_release_workflow_integrity.exs from 169-02, check_required_checks_registered.sh from
     169-03); these two pre-existing, ratified-not-renumbered scripts were never required to
     carry it and, confirmed by reading their sources, do not."

requirements-completed: [FID-02]

coverage:
  - id: D1
    description: "A guard test reads each verification entry point's source and asserts its
      literal exit values against a declared per-entry-point table, so the shipped codes cannot
      drift from the documented contract (FID-02, D-24)."
    requirement: FID-02
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase169_exit_contract_guard_test.exs#every entry point's extracted literal exit values equal the declared set exactly, in both directions"
        status: pass
    human_judgment: false
  - id: D2
    description: "The guard test reports how many entry points it actually located, and that
      number is at least 4; a run that located zero entry points fails loudly instead of passing
      vacuously (D-24)."
    requirement: FID-02
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase169_exit_contract_guard_test.exs#every entry point's extracted literal exit values equal the declared set exactly, in both directions (located_count assertion, measured 6 of 6)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Neither entry point in D-15's scope — mix crosswake.release.status and
      script/check_release_workflow_integrity.exs — uses exit code 2; 2 remains reserved to its
      three existing in-repo meanings (D-11, D-12)."
    requirement: FID-02
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase169_exit_contract_guard_test.exs#every entry point's extracted literal exit values equal the declared set exactly, in both directions (declared expected sets exclude 2 for both entries)"
        status: pass
    human_judgment: false
  - id: D4
    description: "docs/COMPANION-PUBLISH-RUNBOOK.md links to Crosswake.ReleaseStatus.exit_code/1
      as the canonical exit-code contract rather than copying the table, and no exit-code legend
      is printed on any run (D-16)."
    requirement: FID-02
    verification:
      - kind: integration
        ref: "grep -c 'Crosswake.ReleaseStatus.exit_code/1' docs/COMPANION-PUBLISH-RUNBOOK.md (non-zero, no reproduced release-status table); mix crosswake.release.status stdout contains no 'legend' string"
        status: pass
    human_judgment: false
  - id: D5
    description: "script/check_release_version_truth.exs still exits 2 for BLOCKED and its
      runbook row is unchanged — the optional D-15 sweep is explicitly NOT taken this phase."
    verification:
      - kind: unit
        ref: "git diff eb55e01a..HEAD -- docs/COMPANION-PUBLISH-RUNBOOK.md (the BLOCKED | 2 | Published truth... row is byte-identical); script/check_release_version_truth.exs untouched by this plan"
        status: pass
    human_judgment: false

# Metrics
duration: 24min
completed: 2026-09-16
status: complete
---

# Phase 169 Plan 04: Exit-Code Contract Guard and Runbook Link Summary

**A drift-catching ExUnit guard pins the literal exit values of 6 verification entry points
(the mix task, three shell/`.exs` scanners, and `exit_code/1`'s own source clauses) against a
declared table with a measured 6-of-6 non-vacuity floor, and the runbook now links to
`Crosswake.ReleaseStatus.exit_code/1`'s `@doc` instead of carrying a second copy of the table.**

## Performance

- **Duration:** 24 min
- **Started:** 2026-09-16T15:45:00Z
- **Completed:** 2026-09-16T16:09:00Z
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments

- `test/crosswake/proof/phase169_exit_contract_guard_test.exs`
  (`Crosswake.Proof.Phase169ExitContractGuardTest`) declares a 6-record `@entry_points` table —
  `lib/crosswake/release_status.ex` (`exit_code/1`'s own clauses, `{0,1,3}`), `lib/mix/tasks/
  crosswake.release.status.ex` (`{0,1,3}`), `script/check_release_workflow_integrity.exs`
  (`{0,1}`, and asserted to contain no `System.halt(` call per D-14), `script/
  check_required_checks_registered.sh` (`{0,1,2,3}`), `script/verify_generated_ios_shell.sh`
  (`{0,1,2,3}`), and `script/check_release_version_truth.exs` (`{0,1,2}`) — and asserts each
  file's extracted literal exit values equal the declared set exactly, in both directions
  (reporting missing and extra values by name on failure).
- **Measured located-entry-point count: 6 of 6** (floor asserted at ≥4, per D-24) — reported in
  the test's own assertion message even on success, so a regex that silently stopped matching a
  file's changed style cannot reduce this guard to asserting nothing.
- Three D-16 header-comment carriers (`lib/mix/tasks/crosswake.release.status.ex`, `script/
  check_release_workflow_integrity.exs`, `script/check_required_checks_registered.sh`) are
  asserted to carry `# exit contract: 0 clean / 1 defect found / 3 could not verify` byte-for-byte.
  `Crosswake.ReleaseStatus.exit_code/1`'s `@doc`, read via `Code.fetch_docs/1` (not by grepping
  the source), is asserted to name `0`, `1`, `3`, and a sentence reserving `2`.
- A mutation test proves the guard has teeth: mutating the unique `System.halt(1)` literal in
  `script/check_release_version_truth.exs` to `System.halt(9)` in a `tmp_dir` copy makes the
  extraction-and-compare helper report a mismatch against the declared `{0,1,2}` set; a sibling
  test proves the mutation helper raises when its target literal is absent from the source.
- `docs/COMPANION-PUBLISH-RUNBOOK.md` gained a new "`mix crosswake.release.status` exit-code
  contract" section naming `Crosswake.ReleaseStatus.exit_code/1` (reachable via `h`, ExDoc,
  hexdocs) as the single source of truth, stating the three-code summary in one sentence without
  reproducing a table, and the sentence "Do not read exit 3 as a pass." The pre-existing
  `check_release_version_truth.exs` exit-code table is untouched (its `BLOCKED | 2 | Published
  truth could not be established.` row is byte-identical to its pre-phase form); one adjacent
  sentence was added disambiguating its separate, unchanged exit-2 vocabulary from
  `mix crosswake.release.status`'s exit-3 vocabulary. No exit-code legend was added to any
  command's runtime output.

## Task Commits

Each task was committed atomically:

1. **Task 1: Guard the exit-code contract against drift, with a measured non-vacuity floor** -
   `ce6ff6c1` (test)
2. **Task 2: Point the runbook at the canonical contract — a link, not a copy** - `b222a977`
   (docs)

## Files Created/Modified

- `test/crosswake/proof/phase169_exit_contract_guard_test.exs` - New: 7 tests declaring and
  proving the 6-entry-point exit-code contract table, the D-16 header-comment requirement, the
  `@doc` content assertion, and a mutation test with its raise-on-absent-pattern helper test
- `docs/COMPANION-PUBLISH-RUNBOOK.md` - New "`mix crosswake.release.status` exit-code contract"
  section linking to `Crosswake.ReleaseStatus.exit_code/1`'s `@doc`; one adjacent disambiguating
  sentence added to the existing `check_release_version_truth.exs` exit-code table (row itself
  unchanged)

## Decisions Made

See key-decisions in frontmatter: the 6th `release_status.ex` entry-point record for
`exit_code/1`'s own source clauses; `check_release_version_truth.exs` chosen as the mutation
target for its single unambiguous `System.halt(<n>)` idiom per value; `header_required: false`
for the two pre-existing, ratified-not-renumbered scripts D-16 does not scope to this phase.

## Deviations from Plan

None - plan executed exactly as written. The optional D-15 `check_release_version_truth.exs`
2→3 sweep was correctly NOT taken, per the plan's own recorded decision.

## Issues Encountered

None beyond the two unrelated pre-existing full-suite failures already logged in
`deferred-items.md` by 169-02 (`REQUIREMENTS.md`'s milestone header not naming v23.0), reconfirmed
present and unrelated by this plan's own full-suite verification run (1758 tests, 2 failures,
identical failure set to 169-02/169-03's baseline).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The exit-code contract (FID-02) is now fully documented in exactly one place (`exit_code/1`'s
  `@doc`), linked from the runbook, and pinned by a guard test that has been watched to go red on
  a mutation and measured to actually inspect 6 of its 6 declared entry points.
- This is the last plan in Phase 169 (Diagnostic Legibility). All four plans (01-04) are now
  complete; Phase 169's diagnostic-legibility groundwork (ROSTER/DONE protocol, `:unverifiable`
  exit-3 vocabulary, duplicate/version-literal display-name hygiene, and this exit-code drift
  guard) is ready for Phase 170 (Vacuous Assertion Remediation) and Phase 171 (Version/Authority
  Split) to build on.
- Deferred: the `REQUIREMENTS.md` milestone-header failures logged in `deferred-items.md` are not
  blocking for this plan but should be addressed before milestone completion.

## Self-Check: PASSED

- FOUND: test/crosswake/proof/phase169_exit_contract_guard_test.exs
- FOUND: docs/COMPANION-PUBLISH-RUNBOOK.md (modified)
- FOUND commit: ce6ff6c1 (Task 1)
- FOUND commit: b222a977 (Task 2)
- Re-ran all `<acceptance_criteria>` across both tasks: all pass (6 declared entry-point records
  ≥ 6; equality asserted in both directions; located-entry-point count measured at 6, floor ≥4;
  mutation test demonstrates a mismatch and the mutation helper raises on an absent pattern;
  `@doc` assertion reads via `Code.fetch_docs/1`; `test/crosswake/proof/phase135_ci_ops_proof_test.exs`
  and `test/crosswake/proof_lane/ios_verifier_test.exs` pass with no edits beyond the two
  pre-existing unrelated failures; runbook contains `Crosswake.ReleaseStatus.exit_code/1` and
  `Do not read exit 3 as a pass`; runbook does not reproduce a release-status exit-code table;
  the `BLOCKED | 2 | ...` row is byte-identical; `test/crosswake/proof/phase168_version_truth_test.exs`
  passes with no edits; a clean `mix crosswake.release.status` run prints no exit-code legend).
- Re-ran the plan-level `<verification>`: `mix test test/crosswake/proof/phase169_exit_contract_guard_test.exs`
  — 7 tests, 0 failures, located-entry-point count 6 (floor ≥4). `mix test` (full suite) — 1758
  tests, 2 failures (both pre-existing/unrelated, see Issues Encountered — identical to 169-02/
  169-03's baseline). `elixir script/check_release_workflow_integrity.exs` — exit 0, ROSTER/DONE
  69 of 69, 0 failed. `bash script/check_required_checks_registered.sh --local-only` — exit 0,
  103 literal producers. `python3 script/list_merge_blocking_checks.py --producers` — exit 0, 103
  records, no diagnostic.

---
*Phase: 169-diagnostic-legibility*
*Completed: 2026-09-16*
