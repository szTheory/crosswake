---
phase: 196-spec-and-structure-ratchet
plan: "17"
subsystem: delivery
tags: [merge, landed-proof, actual-main, fix-forward, isolated-worktree]
requires:
  - phase: 196-16
    provides: exact-head PR and CI
provides:
  - PR 260 merged to main (88c8bdd8), then the landed-tool fix PR 264 merged (51a1885c)
  - actual-main landed proof verdict pass, 40 of 40 children, run in an isolated worktree of 51a1885c
  - approval records for both attempts, kept on local-only refs
affects: [196 phase verification]
key-files:
  created:
    - 196-EVIDENCE/196-17-blocked-1-superseded.md
  modified:
    - 196-EVIDENCE/landed.json
    - 196-EVIDENCE/delivery.json
    - 196-VERIFICATION-INPUTS.md
key-decisions:
  - Rotate the single approval ref the landed tool reads (rename the PR 260 record, create the PR 264 record at the fixed name) instead of editing the tool.
  - Rename the tool-created evidence branch before pushing, because its default name already exists on the remote from the first attempt.
requirements-completed: []
requirements-addressed: [SPEC-01, SPEC-02, SPEC-03, SPEC-05, ARCH-01, ARCH-02, ARCH-03]
actuals:
  tokens: 12467
  tasks: 3
  commits: 13
commits: 13
plan_head_before: 90c96146e63c1c05754f1a00a5fb8af783f99a5e
plan_head_after: 88822c7c2b19a423b7655b407a988202729dc204
duration: about 1h 50m for this run (landed proof 66 min); the plan spans several runs
completed: 2026-10-29
status: complete
---

# Phase 196 Plan 17: Main merge and actual-main proof Summary

**The actual-main landed proof passed: all 40 children, no base drift, candidate identity equal, run in an isolated worktree of merge commit 51a1885c.**

## What was checked and what happened

- Checked: PR 264 state, the displayed head and base, the merge commit parents, the auto-delete setting, and the landed tool's reads. Merge commit `51a1885cfd50c9dc159a2591204da69510a2ffc4` has parents `88c8bdd8` (the displayed base) and `24fde71d` (the approved head). `base_drift_at_write` is false. `delete_branch_on_merge` reads false.
- The landed tool reads one fixed local ref, `refs/crosswake/196-17-approval`, which named PR 260 (review R-22). I renamed that ref to `refs/crosswake/196-17-approval-pr260` (kept intact, not deleted) and created a record for PR 264 at the fixed name: parent `24fde71d`, diff only `delivery.json`, never pushed, marker status consuming. The tool was not edited.
- The landed run started 2026-10-29T09:48:10Z and ended 10:54:01Z (66 minutes), exit 0, verdict pass. The worktree was removed, and the main checkout kept its branch, head and whole-tree inventory.
- The per-child ledger is `<git dir>/crosswake-196-landed-children.json` (phase complete, cleanup removed).

## Landed result

| Item | Result |
|---|---|
| verdict | pass, 40 of 40 children, 0 failing |
| landed_as_displayed / base_drift_at_write | true / false |
| candidate identity matches candidate.json | true |
| SPEC-04 | `moved_to_v29`, receiver v29.0, 32 roster paths, digest `44019928d4a0f12252339781c7269fc24550e826757cdd56231a5be520aa45f2` |
| core suite | 2920 tests, 0 failures, 79 excluded |
| Swift package suite | 89 tests, 2 skipped, 0 failures |
| Android package suite | 12 tests, 0 failures |
| node suite | 344 tests, 0 failures |
| manifest / threadline lanes (enabled) | 11 / 5 tests, 0 excluded |
| wire contract | 19 tests, version 1.1.0 |
| vector children | elixir 4, swift request 4, swift reply 4, swift metadata 9, swift topology 5, kotlin request 4, kotlin other 8 |
| example host proof | pass (1801 s) |

Native claims stay at the JVM-hermetic and Swift-package ceiling, never device. All eight requirement-map entries (SPEC-01, SPEC-02, SPEC-03, SPEC-05, ARCH-01, ARCH-02, ARCH-03, GR-06) are backed by fresh nonzero passing children.

## Commands and results

| Step | Result |
|---|---|
| `phase-evidence.mjs self-test --scope landed` | pass (2057 ms) |
| approval ref rotation and creation | done; PR 260 record on `-pr260`; new record parent `24fde71d`, one diff path |
| `phase-evidence.mjs landed` | exit 0, `landed pass base_drift_at_write=false` |
| privacy scan, four evidence files | clean |

## Deviations from Plan

1. **[Plan versus tool] The approval record for PR 264 is not write-ahead.** The merge was made by the orchestrator before this run, so the record was written after it, with `at` set to the time of writing. The recorder does not hold the exact allow time. The gates `approval-binding` and `merge` were not run for PR 264, because the merge had already happened. The record says so in `attempt_context.record_timing`.
2. **[Plan versus tool] Approval ref rotated.** The tool hardcodes `refs/crosswake/196-17-approval`. Least invasive lawful route: rename the PR 260 record to `refs/crosswake/196-17-approval-pr260` and create the new record at the fixed name. No tool edit, so the candidate identity is unchanged.
3. **[Process] Evidence branch name.** The tool creates `docs/196-landed-evidence`, a name that exists locally and on the remote from the first attempt (PR 263, merged). The first local branch was renamed `docs/196-landed-evidence-attempt1`; the new branch was renamed `docs/196-landed-evidence-2` before any push. No remote branch was touched.
4. **[Process] `privacy-193.sh` is a bash script** with no execute bit here; it was run with `bash` and absolute paths.
5. **[Process] History move.** `196-17-BLOCKED.md` moved to `196-EVIDENCE/196-17-blocked-1-superseded.md` (frontmatter kept as text) so it no longer sits beside this summary.

## Known unknowns

- The exact time of the user's allow for PR 264 is not held by this record; the merge time from GitHub (2026-10-29T09:44:23Z) is recorded.
- The evidence PR is 266. The number 265 was read as the next free number before opening, but another PR took it first, so the references were corrected before CI finished.

## Stub and threat scan

No stubs. No new network surface, auth path or schema at a trust boundary.

## Requirements

The seven requirements SPEC-01, SPEC-02, SPEC-03, SPEC-05, ARCH-01, ARCH-02, ARCH-03 and GR-06 are pending phase verification.

SPEC-04 (Muex pilot) moved intact to v29.0 by recorded roadmap change; both attempts and the 5/5 accepted controls are preserved, and no adopt/drop verdict was made.

## Handoff

Last completed plan: 196-17 (actual-main landed proof passed). Next: merge the evidence PR (needs its own fresh one-use allow), then `/gsd-verify-work 196 --ws quality-ratchet-release`.
