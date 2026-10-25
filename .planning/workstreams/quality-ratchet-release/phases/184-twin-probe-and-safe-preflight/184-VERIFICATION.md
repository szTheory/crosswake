---
phase: 184-twin-probe-and-safe-preflight
verified: 2026-10-16T06:00:00Z
status: passed
score: 4/4 must-haves verified
covered_files:
  - .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-01-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-01-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-02-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-02-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-03-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-03-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-04-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-04-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-05-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-05-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-06-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-06-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-07-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-07-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-08-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-08-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-09-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-09-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-10-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-10-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-11-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-11-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-12-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-12-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-13-BLOCKED-run1.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-13-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-13-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-14-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-14-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-15-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-15-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-CONTEXT.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-REVIEW-DISPOSITION.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-REVIEW-GAPS-2.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-REVIEW-GAPS-3.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-REVIEW-GAPS-4.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-REVIEW-GAPS.md
  - .planning/workstreams/quality-ratchet-release/phases/184-twin-probe-and-safe-preflight/184-REVIEW.md
covered_digest: "v3:sha256:3070d74524ecc3a5ba1827a9bb915a2e0eb9463a3bcf2dca366c053470caf74b"
behavior_unverified: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/4
  gaps_closed:
    - "GAP3-CR-01 (unreadable folder hides untracked source)"
    - "GAP3-CR-02 (non-ASCII blank before # in info/attributes)"
    - "GAP3-WR-01 (core.ignorecase=true widens a committed ignore rule)"
  gaps_remaining: []
  regressions: []
advisory:
  - finding: "GAP4-WR-01: a FIFO at .git/info/attributes makes the probe wait forever (reproduced). It never reports allowed, so it is a robustness defect, not a way to pass a dirty candidate."
    category: other
    reason: "Untimed File.read before any timed git call. Recommended follow-up: stat first and read only a bounded regular file."
    evidence_status: "reproduced by this verifier (no result in 15 s)"
  - finding: "GAP4-WR-02: untracked files inside a gitlink folder that has no repository probe clean (reproduced)."
    category: other
    reason: "Inside the recorded D-36 (b) deferral. The candidate HEAD holds zero mode-160000 entries and no .gitmodules, so the reopen trigger is unmet. Disclose or refuse gitlinks when the trigger is met."
    evidence_status: "reproduced by this verifier in a scratch repo and through probe_source"
---

# Phase 184: Twin probe and safe preflight Verification Report

**Phase Goal:** The twin refuses any candidate whose tracked files differ from HEAD, however git is configured to hide the difference, and a maintainer can ask whether a run would be allowed without spending a run root.
**Verified:** 2026-10-16
**Status:** passed
**Re-verification:** Yes, after gap round 4 (plans 184-13, 184-15, 184-14; candidate HEAD b898e1104b0feafdb569d1ae42972cb4e1c46629)

## What was checked and what happened

I confirmed the candidate is at b898e110 with an empty `git status`. I copied it to a scratch directory and ran the four main phase test files there (probe, producers, preflight task, guide): 165 tests, 0 failures. I did not touch the candidate.

- The re-pointed stale test ("every git invocation captures stderr in a pipe the probe tests for emptiness") really asserts the D-39 contract: a fake git records whether its stderr is a pipe, the test requires every recorded line to be `pipe` (with at least 8 calls), and it requires nothing to leak to the BEAM's stderr. Mutation control 19 puts the old discard text back and the log shows this test among the seven failures, together with the three unreadable-folder tests and the stderr-stub test. The log has 27 control lines, control 0 passes, and the history manifest shows 87 OK lines and no other line.
- The script text in the code matches D-39: git's stderr goes to a shell variable, any non-empty text exits 125. The `core.ignorecase=false` pin is in the shared pin list. The evidence files agree: gitlink count 0, real-candidate probe all zero, case check `insensitive` (so the case tests are meaningful on this machine), tripwire showed only the five changed paths.
- GAP4-WR-01: I made a FIFO at `.git/info/attributes` in a scratch repo and called `probe_source`. No result came back in 15 seconds. Reproduced.
- GAP4-WR-02: I committed a mode-160000 entry, then created `vendor/sub/hidden.ex` in a plain folder. Raw git status and `ls-files --others` list nothing, and `probe_source` returned all zeros. Reproduced.

## Weighing the two warnings against the goal

- WR-01 is a hang, not a pass. The preflight never says "allowed" and the twin never starts, so a dirty candidate is not accepted. It is a real defect of the "bounded and never raises" kind, worth a small follow-up, but it does not defeat PROBE-01..04.
- WR-02 needs HEAD itself to contain a gitlink. Phase 184 judges a candidate whose recorded head has zero gitlinks and no `.gitmodules` (re-counted at b898e110: zero). D-36 (b) deferred exactly this with a stated reopen trigger, and the trigger is unmet. The untracked files are not "tracked files that differ from HEAD", and the hiding is by git's submodule rule, not by configuration. This is a disclosed or deferred limit. The guide does not claim gitlink coverage; its "hidden by index flags or by git settings" sentence is about those two mechanisms. A one-sentence limit note would be tidier and is listed as advisory.

Neither finding is a reproduced way for the actual candidate to be allowed while dirty. No gap is raised.

## Observable Truths

| # | Truth | Status | Evidence |
| - | ----- | ------ | -------- |
| 1 | PROBE-01: tracked files that differ in content or mode block with source_dirty despite assume-unchanged, skip-worktree, ignoreStat, checkStat=minimal, trustctime=false, filemode=false, attributes ident, and letter-case tricks | VERIFIED | Earlier rounds plus 184-13/15 (NBSP and other non-ASCII blanks, case-only rename, core.ignorecase pin). Probe suite green in scratch copy. Controls 21, 23, 25, 26 fail on the old code. |
| 2 | PROBE-02: every git call uses one shared configuration and fails closed when git cannot read the tree | VERIFIED | `@git_script` and `@stdin_script` capture stderr and exit 125; pins include `core.ignorecase=false`; pipe-capture test passes and fails under control 19. |
| 3 | PROBE-03: real-git fixtures cover each hiding mechanism, untracked and exclude-rule cases, unreadable folders, with a clean control | VERIFIED | Unreadable folder fixtures (0111, 0311, ignored 0111), stderr stubs, NBSP, CR CR LF, config spellings, case-only rename; controls 19-26 each fail on named tests; a full HEAD copy probes clean. |
| 4 | PROBE-04: read-only preflight reports allowed or refused and never writes a receipt or spends a run root | VERIFIED | Preflight tests pass, including the unreadable-folder case that prints blocked with the missing-prerequisite next action. |

**Score:** 4/4 truths verified (0 behavior-unverified)

### Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
| ----------- | ------------ | ------ | -------- |
| PROBE-01 | 01-15 | SATISFIED | Truth 1 |
| PROBE-02 | 01-15 | SATISFIED | Truth 2 |
| PROBE-03 | 01-15 | SATISFIED | Truth 3 |
| PROBE-04 | 04-15 | SATISFIED | Truth 4 |

All four IDs appear in plan frontmatter and REQUIREMENTS.md; no orphans.

### Anti-Patterns / Other Findings

Not blocking: GAP4-IN-01 (untracked FIFOs and sockets are not listed by git; they hold no source text; disclose in the guide), GAP4-IN-02 (some safe config spellings are refused, which fails closed; the "read as git spells them" wording overstates), GAP4-IN-03 (any stderr byte blocks, so a future git advisory would block every candidate; unlistable-folder tests need a non-root user; an NFD name committed under precomposeunicode=false false-blocks on macOS defaults). Plan 184-13 first ran blocked (184-13-BLOCKED-run1.md) and was resumed after the orchestrator amendment; the final state is complete.

### Human Verification Required

None.

### Gaps Summary

No gaps. The goal holds for the real candidate: tracked changes cannot be hidden by git configuration, unreadable folders, odd attribute or exclude layouts, or letter case, and the preflight is read-only. Two advisory follow-ups are recommended: bound the `info/attributes` read (GAP4-WR-01), and add a gitlink limit sentence or refusal when D-36 (b) reopens (GAP4-WR-02).

---

_Verified: 2026-10-16_
_Verifier: Claude (gsd-verifier)_
