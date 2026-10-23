---
phase: 169-diagnostic-legibility
addendum_to: 169-VERIFICATION.md
convention: ../../VERIFICATION-CONVENTIONS.md
vacuity_taxonomy:
  - check_id: "duplicate-producer/duplicate-display-name"
    shape: A
    non_vacuity_evidence: "169-03-SUMMARY.md's Non-Vacuity Ledger: 1 real collision found on the
      pre-fix tree (`advisory provider sandbox/device proof (storekit + play billing)`, produced
      by both phase48-proof.yml and phase70-proof.yml), 0 after the fix. The check's own
      possibly-empty-collection edge is separately guarded: the same summary's coverage entry D3
      asserts `length(lines) > 100` on the real-tree run before trusting an absence of findings, so
      a zero-record inventory cannot read as clean. The reject additionally fires against a
      synthetic fixture (two jobs sharing a non-'merge-blocking' name) per the summary's Task 2
      test list."
  - check_id: "release.scanner.roster_exact"
    shape: "matches none of A-F, because it is a regenerate-and-diff-exact completeness check
      over a fixed, compile-time-literal 69-entry @roster_ids list, not a predicate over a
      runtime-derived possibly-empty collection, a needs:/continue-on-error/if:/matrix condition,
      or a shell exit-code idiom."
    non_vacuity_evidence: "169-01-SUMMARY.md, Task 3: a mutation test removes one ID token from
      @roster_ids in a temp copy of the scanner and confirms the scanner turns red at
      release.scanner.roster_exact (4 tests, all passing). The declared roster is 69 IDs; the live
      tree measured 69 of 69 emitted IDs matching exactly, 0 failed (169-01-SUMMARY.md Self-Check:
      `elixir script/check_release_workflow_integrity.exs` exit 0, ROSTER/DONE 69 of 69)."
  - check_id: "release.workflow_integrity"
    shape: "matches none of A-F, because it is an always-emitted message-passthrough check that
      re-surfaces whichever underlying scanner check is failing, rather than evaluating a
      predicate over a collection, a needs:/if:/matrix/continue-on-error condition, or a shell
      exit code itself. Its own non-vacuity is inherited from the scanner ID it is currently
      relaying (release.scanner.roster_exact, or any other roster member)."
    non_vacuity_evidence: "169-01-SUMMARY.md, Task 1: a real drifted-manifest fixture (the PR #164
      reproduction named in 169-VERIFICATION.md's Truth 1 row) makes release.workflow_integrity
      carry the failing scanner's verbatim detail through build/1 and render/1, asserted by
      `test/crosswake/proof/phase169_diagnostic_legibility_test.exs#a drifted manifest surfaces
      the failing check's verbatim detail through build/1 and render/1` (passing). A clean run
      reports release.workflow_integrity as :ok with no indented continuation line, confirmed by a
      second passing test in the same file."
  - check_id: "version-literal-in-display-name"
    shape: A
    non_vacuity_evidence: "169-03-SUMMARY.md's Non-Vacuity Ledger: pre-fix findings were 3 job-name
      offenders (`Guard exact approved 0.2.1 merge`, `Prove exact public 0.2.1 artifacts`, `Linked
      0.2.1 release rollup`) and 2 artifact-name offenders (`exact-public-proof-0.2.1`,
      `linked-release-status-0.2.1`), all in release-please.yml; 0 remain after the fix. Two
      distinct fixture tests each prove the reject fires: a synthetic job named `prove 1.2.3
      thing`, and a synthetic upload-artifact step named `proof-artifact-9.9.9`. The same D3
      possibly-empty-collection guard noted for duplicate-producer/duplicate-display-name applies
      here too, since both rejects share one traversal over the same job-record inventory."
---

# Phase 169 Diagnostic Legibility — Vacuity Taxonomy Addendum

This file is a retroactive record covering Phase 169 under the VAC-03 `vacuity_taxonomy`
convention (see [`VERIFICATION-CONVENTIONS.md`](../../VERIFICATION-CONVENTIONS.md)). The six
shapes referenced below (A-F) are defined at
[`.planning/research/v23/PITFALLS.md`](../../../../research/v23/PITFALLS.md) §"Pitfall 4" and are
not restated here. Phase 169
closed on 2026-09-16, before this convention existed, so this addendum lives beside its artifacts
as a separate file rather than as an edit to `169-VERIFICATION.md`. `169-VERIFICATION.md` is a
sealed artifact carrying its own `covered_digest`; editing it after the fact would invalidate that
digest and blur what was verified at close time versus what was added later. This addendum makes
`git diff` over `169-VERIFICATION.md` empty across the whole span of this addendum's own creation
— confirmed as a plan-level verify step.

## Vacuity Taxonomy

Entries below are listed in check-ID lexical order, per the convention. Every `check_id` was
confirmed present in its emitter source (`script/check_release_workflow_integrity.exs`,
`lib/crosswake/release_status.ex`, `script/list_merge_blocking_checks.py`) before being recorded
here, and every check listed is one Phase 169 actually landed — derived from the four
`169-0{1,2,3,4}-SUMMARY.md` files, not from memory or from planning prose.

| Check ID | Shape | Non-vacuity evidence (measured) |
|---|---|---|
| `duplicate-producer/duplicate-display-name` | A | 1 real collision found pre-fix, 0 post-fix (169-03-SUMMARY.md Non-Vacuity Ledger); possibly-empty-collection edge guarded by a `>100`-record floor; fires against a synthetic fixture. |
| `release.scanner.roster_exact` | matches none of A-F, because it diffs a fixed 69-entry compile-time literal roster against emission, not a possibly-empty runtime collection or a workflow-graph condition | Mutation test (remove one `@roster_ids` token) turns the scanner red; live tree measured 69/69 exact match, 0 failed. |
| `release.workflow_integrity` | matches none of A-F, because it is a message-passthrough owner check, not a predicate over a collection or workflow condition | Real drifted-manifest fixture (PR #164 reproduction) makes the check carry the failing scanner's verbatim detail end-to-end through `build/1`/`render/1`; a clean run reports `:ok` with no continuation line. |
| `version-literal-in-display-name` | A | 3 job-name offenders + 2 artifact-name offenders found pre-fix, 0 post-fix (169-03-SUMMARY.md Non-Vacuity Ledger); two distinct fixture tests each independently prove the reject fires. |

Two of the four checks Phase 169 landed do not map onto Shapes A-F at all, and each entry says so
explicitly with a reason rather than forcing a nearest-fit letter. `release.scanner.roster_exact`
and `release.workflow_integrity` are structurally an exact-match completeness check and a
message-relay check, respectively — neither is a bare-boolean predicate over a possibly-empty
collection (Shape A), nor a workflow-graph condition (Shapes B, C, D, E), nor a shell exit-code
idiom (Shape F). Recording an inaccurate nearest-fit letter for either would misrepresent what was
actually checked; the convention's escape form exists precisely for this case.

This phase did **not** land zero new checks — the four entries above are the complete, exhaustive
list of check IDs Phase 169 introduced, confirmed against all four of its plan SUMMARYs and against
each ID's emitter source. The null statement ("This phase landed no new checks.") does not apply
here and is intentionally omitted from this addendum for that reason.
