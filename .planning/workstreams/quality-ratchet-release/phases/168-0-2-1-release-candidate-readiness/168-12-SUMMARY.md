---
phase: 168-0-2-1-release-candidate-readiness
plan: "12"
subsystem: release-readiness
gap_closure: true
tags: [cr-01, authorization-gate, mirror-recovery, gate-before-credentials, tdd]
requires:
  - phase: 168-13
    provides: The canonical receipt whose digest this gate compares against
provides:
  - Exact-identity authorization on the only job able to force-push the public iOS mirror
  - Gate-before-credentials and gate-before-checkout ordering, enforced structurally
  - A scanner check that fails closed if the gate is removed or reordered
  - Documented single-transaction scope of the mirror recovery mode
affects: [ios-mirror-backfill, release-workflow-integrity-scanner, companion-publish-runbook]
actuals:
  tasks: 2
  commits: 2
plan_head_before: 862dcada
tech-stack:
  added: []
  patterns: [gate-before-credentials, pin-everything-shape-check-the-lease, structural-ordering-check]
key-files:
  created: []
  modified:
    - script/check_release_workflow_integrity.exs
    - .github/workflows/ios-mirror-backfill.yml
    - docs/COMPANION-PUBLISH-RUNBOOK.md
key-decisions:
  - "Shape-check the lease rather than pin it. Recovery exists because mirror `main` has diverged to a commit not knowable in advance; pinning `expected_old_ref` would make the recovery path unusable. It is constrained to a 40-hex lowercase id distinct from the new ref, and the scanner explicitly asserts it is NOT pinned to PHASE168_MIRROR_MAIN — so a later 'tighten it' edit that breaks recovery fails the check."
  - "Enforce ordering by byte offset within the job body rather than by asserting the gate is textually first. Offsets survive formatting changes and express the real requirement: the gate must precede both the checkout and the credential load."
  - "Add `permissions: contents: read` to the recovery job, which was missing it while its publication sibling had it. Small, in the same blast radius, and closes a least-privilege asymmetry alongside the authorization one."
patterns-established:
  - "An irreversible job's authorization gate runs before any checkout of a supplied ref and before any credential load, so an unauthorized dispatch reaches neither attacker-chosen code nor secrets."
requirements-completed: [REL-02, REL-04]
requirements-addressed: [REL-02, REL-04]
---

# Plan 168-12 Summary — Exact-identity gate on iOS mirror recovery

## Accomplishments

Closed 168-REVIEW CR-01 and verification gap 1. `recover-ios-mirror` is the only mode
able to replace the public iOS mirror's `main` with a leased force push, and it was the
only irreversible job in the Phase 168 authority chain with no hardcoded identity
validation at all.

The shape of the hole mattered more than its existence. The job's **first** step checked
out a dispatch-supplied `release_ref`, then loaded `MIRROR_DEPLOY_KEY` — so an
unauthorized dispatch reached attacker-chosen code *and* the mirror credential before
anything was validated. Its three sibling irreversible jobs all validate first.

Forensics confirm the job has never run non-skipped (skipped in all 15 recent runs), so
this was a latent hole, not the path the live publication took. Closed on its merits.

## Task Commits

| Task | Commit |
|---|---|
| 1 (RED) | `54cc1eb2` test(168-12): require exact identity authorization on mirror recovery |
| 2 (GREEN) | `f16aa470` fix(168-12): gate iOS mirror recovery on exact approved identity |

## Evidence and Verification

- RED: scanner exited 1 with **exactly one** FAIL (`recovery.ios.exact_identity_gate`);
  no previously passing check changed verdict
- GREEN: scanner exits 0, **67 OK / 0 FAIL**
- `actionlint .github/workflows/ios-mirror-backfill.yml` → clean
- `mix test test/crosswake/release_candidate/` → 44 tests, 0 failures
- `mix crosswake.release.status` → all 8 governance checks OK, no lockstep failure
- `elixir script/check_release_version_truth.exs` → OK on all three components

The gate's constants were copied out of the `publish-ios-mirror` job, not retyped, and
the scanner asserts each `NAME: value` pair individually inside the recovery job body —
scoped via `job_blocks/1`, so a matching constant elsewhere in the file cannot satisfy it.

Ordering is asserted by comparing byte offsets of the gate, the checkout, and the
ssh-agent step within that job body, so the gate cannot be reordered behind either.

**Nothing was dispatched.** No ref, tag, package, mirror, or credential was exercised.

## Decisions Made

See `key-decisions` frontmatter. The load-bearing one is the asymmetry between publication
and recovery: publication pins `expected_old_ref` because it knows the pre-publication
mirror state; recovery cannot, by definition. Everything else about the transaction is
knowable and is pinned.

## Deviations from Plan

### Deviation 1 — the check count was 66 → 67, not 20 → 21

The plan stated "the scanner currently reports 20 checks" and expected a full pass at 21.
The scanner actually reported **66** OK before this plan and **67** after. The delta —
exactly one new check, no verdict changes — is what the plan intended; its absolute
figure was wrong. The new id was added as a standalone check and not inserted into any
existing required-id list, so `Crosswake.ReleaseStatus` is unaffected, as the plan required.

### Deviation 2 — added a missing `permissions` block

`recover-ios-mirror` had no `permissions:` block while `publish-ios-mirror` restricts
itself to `contents: read`. Added the same restriction. This is slightly beyond the
plan's literal file scope but inside the same job and the same security finding; leaving
a force-push-capable job on default permissions while adding its authorization gate would
have been a half fix.

### Deviation 3 — delivered by pull request

`main` is protected (`GH006`). Delivered on branch
`gsd/phase-168-version-truth-changelog` via **PR #163**.

**Total deviations:** 3 — one plan miscount, one in-scope hardening, one structural.

## Issues Encountered

None.

## Known Stubs

None.

## User Setup Required

None. PR #163 needs review and merge.

## Next Phase Readiness

All three verification gaps are now closed:

| Gap | Owner | Status |
|---|---|---|
| 1 — CR-01 mirror recovery ungated | 168-12 | closed |
| 2 — canonical receipt stranded | 168-13 | closed |
| 3 — repository version truth behind published | 168-09, 168-10, 168-11 | closed |

Phase 168 is ready for re-verification once PR #163 merges. The exact-public
post-publication clean-room run remains an open human-verification item from the
verification report, not a gap.

---
*Phase: 168-0-2-1-release-candidate-readiness*
*Completed: 2026-09-15*
