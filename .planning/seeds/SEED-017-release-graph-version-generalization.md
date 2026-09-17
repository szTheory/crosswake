---
id: SEED-017
status: harvested
planted: 2026-09-15
planted_during: quality-ratchet-release Phase 168 (re-verification follow-up)
trigger_when: "No longer a trigger — closed by Phase 171. Retained as the record of why the weld existed and what removing it exposed."
scope: medium
severity: "was high (the next release would have published nothing); now resolved"
blocks: none — closed by Phase 171
resolved_on: 2026-09-17
resolved_by: "quality-ratchet-release Phase 171 (Version/Authority Split), merged as 501e4410 via PR #178"
---

# SEED-017: Generalize the linked release graph past 0.2.1 without loosening its authority

## RESOLVED — Phase 171, 2026-09-17

This seed is closed. Phase 171 split the version from the authority: the release graph now
derives its version from `needs.approved-release-guard.outputs.approved_version` at all four
publish gates, while the approval-identity gate stays exact. Verified retroactively in
`.planning/workstreams/quality-ratchet-release/phases/171-version-authority-split/171-VERIFICATION.md`
(7/7 success criteria, each re-executed against the merged tree).

Two latent failures that no plan predicted were found and fixed on the way through:

- `script/guarded_hex_publish.sh`'s `verify_approved_identity()` early-returned for any
  crosswake version other than `0.2.1`, so the entire approved-identity verification was
  inert for every future release. It now requires `--expected-version` and fails closed.
- Two `run:` blocks in `release-please.yml` (lines 568 and 603) still passed a literal
  `--version 0.2.1` to the publish scripts even after their `if:` gates were parameterized —
  the gate would have opened for the right version and then published the wrong one.

Version literals went from 18 files to 4 (5 occurrences), all non-executable: two explanatory
comments in `check_release_workflow_integrity.exs`, one comment in `release-please.yml`, one
historical PR narrative in `check_release_version_truth.exs`, and one generated ledger display
string. Zero live gates carry a bare version literal, enforced going forward by the
`release.publish_gate.no_bare_version_literal` scanner check.

**Consequence for release triage:** PR #164 (`0.2.2`) is no longer blocked by this seed. The
remaining holds on the companion PRs (#147, #115) are the separate `TODO-011`/`TODO-012`
proof-lane concerns, which Phases 173-175 address.


## Why This Matters

Phase 168 built a release pipeline that can publish exactly one transaction: `0.2.1`. That was the
correct shape for the problem it solved — an exact, approval-gated, one-way-door release — and its
authority model is genuinely good. But the version is welded in alongside the authority, and the
weld is load-bearing in both directions.

The practical consequence is sharp: **the next release tags and then publishes nothing.**
`publish-hex`, `publish-ios-core`, `publish-android-core`, and `exact-public-proof` each gate on
`needs.release-please.outputs.version == '0.2.1'`. For `0.2.2` every one of them skips. The rollup
then reports `PARTIAL` — correctly, and only because everything downstream was skipped. A release
that quietly no-ops is worse than one that fails loudly.

Full detail, including what must be *preserved*, is in `TODO-009`.

## The design tension (read before planning)

"Only version 0.2.1 may publish" and "only the approved merge may publish" are currently the same
literal. Generalizing the first must not generalize the second.

The target is: the graph accepts any version, while each release stays bound to its own approved
head, tree, base, and candidate receipt digest. The identity gate stays exact; the version stops
being a constant. Deleting the `== '0.2.1'` comparisons without replacing that binding would leave
publication gated on `linked_release` alone — strictly worse than today.

Two properties to preserve explicitly:

- `Crosswake.ReleaseCandidate.Workflow.rollup!/1` treats `skipped` as not-success, so a proof that
  does not run yields `PARTIAL`/`BLOCKED`, never `COMPLETE`. Silence is never read as success.
- The `PHASE168_*` pinned-identity gates on the irreversible jobs are a safety property, not debt.
  A generalized graph needs the per-release equivalent, not their removal.

## Also in scope

**Recovery publications currently skip the post-publication proof.** `exact-public-proof`
`needs:` the ordinary `publish-*` jobs, so a release completing through exact-ref recovery — which
is how 0.2.1 actually shipped — never runs it. The releases that took the unusual path are exactly
the ones most worth proving. Both paths should converge on the same proof.

This is the concrete reason Phase 168 closed at `human_needed` rather than `passed`: the
exact-public proof is wired and fail-closed but has never once executed.

## When to Surface

**Trigger:** blocking before any non-0.2.1 release. Surface at `$gsd-new-milestone` scoping for the
milestone that follows v22.0 even if the milestone theme does not obviously match — the cost of
discovering this during a release attempt is a silent no-op publish.

## Scope Estimate

**Medium.** Touches `.github/workflows/release-please.yml` (15 version literals, 5 of them job
gates), `lib/crosswake/release_candidate/workflow.ex` (`@coordinates`), the candidate-receipt
artifact naming convention, and wants a new `check_release_workflow_integrity.exs` check asserting
no publish job is gated on a bare version literal. Needs tests; the existing Phase 168 proof tests
are the pattern to follow.

## Interim guard already in place

A tripwire landed 2026-09-15: `release.version_weld.gates_match_declared_version` fails CI when
the declared manifest version and the publish gates' literal diverge. It buys safety, not
progress — the generalization below is still required, and closing it includes retiring the
tripwire rather than loosening it.

## Breadcrumbs

- `.planning/todos/TODO-009-release-graph-welded-to-0-2-1.md` — the full finding, with the line
  table and the "what is NOT wrong" section
- `.github/workflows/release-please.yml:718-763` — `exact-public-proof`
- `lib/crosswake/release_candidate/workflow.ex:4-19` — `@children`, `@coordinates`, `@dependencies`
- `script/check_release_workflow_integrity.exs` — home for the regression check
- `docs/COMPANION-PUBLISH-RUNBOOK.md` — operator contract; carries the pre-release warning
- `.planning/seeds/SEED-012-post-0-2-1-repository-operational-hygiene-closeout.md` — adjacent
  post-0.2.1 closeout seed; related but hygiene-scoped, not a release blocker
