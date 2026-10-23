---
phase: 191-integration-branch-and-local-suite
verified: 2026-10-23T00:00:00Z
status: passed
score: 4/4 must-haves verified
covered_files:
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-01-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-01-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-02-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-02-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-03-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-03-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-04-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-04-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-05-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-05-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-06-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-06-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-07-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-07-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-08-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-08-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-09-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-09-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-10-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-10-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-11-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-11-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-12-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-12-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-EVIDENCE/exclusions-191.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-EVIDENCE/land02-dispositions-191.md
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-EVIDENCE/phase-gate-191.txt
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-EVIDENCE/scan-191.txt
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-EVIDENCE/suite-ALL.txt
covered_digest: "v3:sha256:527170348e5fe431d36d185bd53fc90f923025af51f7624461454a0fad380aa5"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 191: Integration branch and local suite Verification Report

**Phase Goal:** One integration branch, cut from current GitHub `main` in a separate durable clone, holds everything that should land and passes the full local suite with no silent exclusions.
**Status:** passed (initial verification)
**Requirements:** LAND-01, LAND-02 (both claimed by the plans; both mapped to Phase 191 in REQUIREMENTS.md; no orphans)

## Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence checked directly |
|---|-------|--------|---------------------------|
| 1 | Branch starts at current GitHub `main` and holds candidate commits (history preserved), FIX commits, v24-v27 planning records | VERIFIED | In `<integration-clone>`: branch `land/v25-v27`, HEAD 98e0d390; `merge-base HEAD origin/main` equals origin/main d0dbdf7b; the clone's origin still reports main at d0dbdf7b (so "current"). 112 commits over main, 0 merges. 112 = 94 candidate commits (unchanged SHAs, first-parent linear, phase-gate-191.txt) + 11 code/FIX commits (FORMAT, LOCALE, G1, PRIVACY, HOST-G2G6, SWIFT-G4, WR-05, WR-01-06, WR-03, ADOPTION-EXT, RESOLVER) + 5 per-milestone planning carries (v23-v27) + FIXTURE + SYNC. Every labelled commit in heads-191.txt appears in `git log` in that order. Carry and SYNC commits touch only `.planning/` (checked: 0 non-planning paths between FIXTURE and SYNC; phase-gate `carry_commits_nonplanning 0`, `code_commits_planning 0`). |
| 2 | Privacy scan of the full change against `main` finds no home paths, usernames, secrets or adopter identity | VERIFIED, with a user-chosen scope reduction (below) | scan-191.txt is bound to head 98e0d390, `blocking_final 0`, gitleaks 8.30.1 / 222 rules / 0 findings, `result clean`. Independent check I ran: added lines in `git diff -U0 origin/main HEAD` containing the local account name, a home-folder path, or the account email: 0. Two historic residues (1 home-path class, 1 username class) sit in preserved candidate commit history only (value no longer in the tree after the PRIVACY commit), each accepted by blob hash and recorded as such. Further main-resident username files (364) are pre-existing on `main`, outside the change, and routed to a hygiene seed. |
| 3 | Full local suite passes; known failures (Swift G4, example-host G2/G6) fixed or listed; nothing skipped unlisted | VERIFIED | suite-ALL.txt (head 7075a441): all nine stages status 0, every lane failures 0 / invalid 0, orchestrator_exit 0, result pass; lane totals equal their floors (main 2657/2657, companions 11/55/139/53/98, phase41 3). Swift 89 tests, 2 skipped. suite-SWIFT-EXPORT-FINAL: 89 tests, 0 skipped, 0 failures (the two skips are justified and exercised with the example-host export). suite-HOST-FINAL: 167 tests, 0 failures. At the SYNC head, suite-root-SYNC (2660 tests, 0 failures, floor met) and suite-SYNC subset (951 tests, 0 failures) re-ran; SYNC differs from FIXTURE by planning files only, so the full run still applies. land02-dispositions-191.md fixes all 9 baseline failures (G1, 5 ledger/locale, G2, G6, Swift G4) with named commits; one extra failure found at run time (doctor router fixture) was fixed by FIXTURE with red-before/green-after evidence (A-15). exclusions-191.md lists every exclusion (advisory_only, collateral_binaries, engine_present, requires_example_host, phase41_nested_process, two Swift G3 skips) with reason and where each runs instead; the root skip-tag count is 0 with the two fixture-text lines explained. |
| 4 | Built in a separate durable clone; recovery checkout shows no git change | VERIFIED | Branch exists only in the durable clone (not the recovery checkout). recovery-before-191.txt and recovery-after-191.txt are identical on every recorded field (HEAD file, packed refs, loose refs, stash log of 4 lines, 2 worktrees, config, index content, HEAD reflog, object-file count). The recovery checkout's HEAD is still d0f3e2f1, the same commit as at the start of the phase. recovery-tree-check shows only the planned planning-record files edited in the working tree (no git state), "rest unchanged", compare pass. Nothing pushed (`pushed no`). Durable clone is clean (empty status, 0 stashes). |

**Score:** 4/4

## Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| LAND-01 | SATISFIED | Truths 1, 2, 4 |
| LAND-02 | SATISFIED | Truth 3 |

REQUIREMENTS.md still shows LAND-01/02 as unchecked/"Pending"; that bookkeeping should be flipped when the orchestrator closes the phase (not a code gap).

## Scope reduction chosen by the user (state plainly)

Amendment A-14 (2026-10-22, user decision) dropped the private adopter-term denylist. Adopter-identity screening is therefore NOT performed (scan-191.txt records `terms 0` and `adopter_check skipped_by_user_decision A-14`). The privacy scan covers emails, usernames, home/temp paths and secrets only. This was judged as amended and is not counted as a gap; the claim "no adopter identity" in criterion 2 is unproven by tooling and rests on the user's decision.

## Amendments / history records

A-15 (FIXTURE commit) is present and evidenced. `191-10-BLOCKED.run1.md` and `191-11-BLOCKED.run1.md` are history of first runs; both plans have SUMMARYs and the second runs passed (carry commits and suite evidence exist).

## Anti-patterns / notes

- Suite was not re-run by the verifier (per instruction); evidence files are bound to the correct heads.
- Non-blocking: the Phase 190-origin residue (1 home-path, 1 username in candidate history; 364 main files) is accepted/deferred to a hygiene seed, explicitly dispositioned in phase-gate-191.txt.

## Human verification

None required.

_Verifier: Claude (gsd-verifier)_
