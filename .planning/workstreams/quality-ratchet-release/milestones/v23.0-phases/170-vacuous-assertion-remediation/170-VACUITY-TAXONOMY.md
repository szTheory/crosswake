---
phase: 170-vacuous-assertion-remediation
addendum_to: 170-VERIFICATION.md
convention: ../../VERIFICATION-CONVENTIONS.md
vacuity_taxonomy:
  - check_id: "Crosswake.Proof.Phase170GuardExpressionMatchTest"
    shape: "matches none of A-F, because it is an itemized, closed-world structural test over the
      fixed 52-row remediation manifest that verifies, per entry, that a guard line exists AND its
      normalized argument expression exactly equals the assertion's normalized expression — not a
      predicate over an open-world possibly-empty runtime collection (Shape A), nor any
      workflow-graph condition (Shapes B-E), nor a shell exit-code idiom (Shape F)."
    non_vacuity_evidence: "170-02-SUMMARY.md: the 52-row frozen manifest (`script/collection_assertion_remediation.json`)
      is fully covered — every row's guard existence and exact expression match verified, 5 tests
      total, 0 failures on the real tree. Demonstrated capable of going red for BOTH failure modes
      the plan requires: a synthetic missing-guard fixture and a synthetic wrong-variable-guard
      fixture (D-14 non-vacuity control), both built as in-memory heredoc fixtures excluded from
      the ledger's own scanner by `strip_heredocs/1`."
  - check_id: "Crosswake.Proof.Phase170VacuityTaxonomyConventionTest"
    shape: A
    non_vacuity_evidence: "170-05-SUMMARY.md (this plan): the predicate `taxonomy_recorded?/2` is a
      boolean check over a `Path.wildcard`-derived, possibly-empty collection of phase directories
      — structurally identical to Shape A's defect if left unguarded. Mitigated by a dedicated
      findings-floor test asserting the examined-directory count is at least 1 (measured: 1 phase
      directory examined on this tree today, `169-diagnostic-legibility`, the only phase carrying a
      `*-VERIFICATION.md` so far), plus a synthetic non-compliant fixture proven to turn the
      predicate false and a synthetic addendum-only fixture proven to turn it true (5+ tests total,
      0 failures)."
  - check_id: "Crosswake.Proof.Phase170VacuousAssertionLedgerTest"
    shape: "matches none of A-F, because it is a regenerate-and-diff-exact completeness check over
      the emitted classification rows (mirroring Phase 169's D-04 `release.scanner.roster_exact`
      pattern one level down, at call sites instead of check IDs) — it asserts the LEDGER IS
      COMPLETE (no site missing a row, no orphan row), never that every site is guarded, so it is
      not a bare-boolean predicate over an assumed-nonempty collection, nor a workflow-graph
      condition, nor a shell exit idiom."
    non_vacuity_evidence: "170-01-SUMMARY.md: 220 audited rows measured on the live tree (42
      assert_all + 131 assert_any + 47 refute_any + 0 refute_all), 18 tests total, 0 failures,
      including two real-subprocess non-vacuity controls (a removed row and an added orphan, both
      proven to turn `--check` RED and name the affected site) plus the four VAC-01 edge-case
      guards (adjacency, empty tree, encoding stability, total ordering)."
  - check_id: "phase 170: an empty"
    shape: A
    non_vacuity_evidence: "170-03-SUMMARY.md: 5 genuine, executing empty-input regression tests
      (doctor_test.exs, support_matrix_test.exs, evidence_manifest_test.exs,
      release_boundaries_test.exs, mirror_test.exs), each driving a real production call path to an
      empty collection and proving the plan 170-02 guard raises `ExUnit.AssertionError`. 2 further
      named sites (`coordinate_test.exs`'s `companions`, and 4 flagged refutation sites in
      `crosswake_release_status_test.exs`) are covered ONLY structurally by
      `Crosswake.Proof.Phase170GuardExpressionMatchTest`, recorded with a stated `lib/`-change
      reason each rather than a fabricated bypass, per 170-03-SUMMARY.md's D-12.2 disposition
      table."
---

# Phase 170 Vacuous Assertion Remediation — Vacuity Taxonomy Addendum

This file is Phase 170's own record under the VAC-03 `vacuity_taxonomy` convention (see
[`VERIFICATION-CONVENTIONS.md`](../../VERIFICATION-CONVENTIONS.md)). The six shapes referenced
below (A-F) are defined at
[`../../../../research/v23/PITFALLS.md`](../../../../research/v23/PITFALLS.md) §"Pitfall 4" and are
not restated here. As of this plan, Phase 170 has not itself closed with its own `170-VERIFICATION.md`
sealed artifact, so this record is produced directly by plan 170-05 as `170-VACUITY-TAXONOMY.md`,
following `169-VACUITY-TAXONOMY.md`'s sibling-addendum shape (see "Claude's Discretion" in
`170-CONTEXT.md`: the addendum "is its own file or a section appended to a phase-170 artifact" —
this plan resolves that discretion as its own file, matching the retroactive-Phase-169 precedent).

## Vacuity Taxonomy

Entries below are listed in check-ID lexical order, per the convention. Every `check_id` was
confirmed present in its emitter source before being recorded here (module names grep-match their
own defining file; the `phase 170: an empty` prefix grep-matches all 5 regression test names), and
every check listed is one Phase 170 actually landed — derived from the `170-01-SUMMARY.md`,
`170-02-SUMMARY.md` and `170-03-SUMMARY.md` files, not from memory or from planning prose.

| Check ID | Shape | Non-vacuity evidence (measured) |
|---|---|---|
| `Crosswake.Proof.Phase170GuardExpressionMatchTest` | matches none of A-F, because it is an itemized closed-world structural test verifying guard presence AND exact expression match over a fixed 52-row manifest, not a possibly-empty runtime collection predicate or a workflow-graph condition | 52/52 manifest rows verified (170-02-SUMMARY.md); demonstrated red for both a missing-guard and a wrong-variable-guard synthetic fixture. |
| `Crosswake.Proof.Phase170VacuityTaxonomyConventionTest` | A | Predicate over a `Path.wildcard`-derived possibly-empty directory collection; mitigated by a findings-floor test (1 phase directory examined today) plus proven-false and proven-true synthetic fixtures (170-05-SUMMARY.md). |
| `Crosswake.Proof.Phase170VacuousAssertionLedgerTest` | matches none of A-F, because it is a regenerate-and-diff-exact ledger-completeness check (Phase 169's `roster_exact` pattern one level down), asserting the ledger is complete, never that every site is guarded | 220 audited rows measured (170-01-SUMMARY.md); two real-subprocess non-vacuity controls (removed row, added orphan) both proven to turn `--check` RED. |
| `phase 170: an empty` (empty-input regression set) | A | 5 executing regressions driving real production call paths to `[]` and proving the guard raises (170-03-SUMMARY.md); 2 further sites covered structurally-only with a named `lib/`-change reason each. |

## On the taxonomy's applicability to meta-checks

Two of the four entries above (`Phase170GuardExpressionMatchTest`, `Phase170VacuousAssertionLedgerTest`)
are checks Phase 170 built ABOUT the test suite's own collection assertions, not collection
assertions themselves — the same structural situation Phase 169's `release.scanner.roster_exact`
and `release.workflow_integrity` were in, which is why both use the convention's explicit escape
form rather than a forced nearest-fit letter. The other two entries
(`Phase170VacuityTaxonomyConventionTest`, the empty-input regression set) are the taxonomy applied
straightforwardly: the convention check is itself a Shape A risk mitigated by its own findings
floor, and the empty-input regressions are runtime proofs of Shape A fixes landed by plan 170-02.
Recording an inaccurate nearest-fit letter for either structural check would misrepresent what was
actually checked; the convention's escape form exists precisely for this case, per D-15/D-18.

## VACG-01 narrowing rule

Per D-21, when `absence.collection_assertion_non_empty` (VACG-01) eventually lands as a
merge-blocking guard, it mechanically supersedes **Shape A only** — the two Shape-A entries in this
table (`Phase170VacuityTaxonomyConventionTest`, the empty-input regression set) are the entries
VACG-01 would eventually absorb detection for. Shapes B through F, and the two escape-form entries
above, have no proposed automated guard at all as of this writing and are unaffected. The field
narrows to the five remaining shapes at that point; it is not retired.
