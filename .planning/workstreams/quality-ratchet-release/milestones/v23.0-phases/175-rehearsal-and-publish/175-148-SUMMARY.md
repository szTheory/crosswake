---
phase: 175-rehearsal-and-publish
plan: 148
status: complete
wave: 9
requirements-completed: [REL-13, REL-14, REL-15, REL-17]
completed: "2026-10-11T19:58:54.127798+00:00"
commits: []
---

# Plan 148 — Release Delivery and Reconciliation

## What finished

- Final installer proof repair PR #237 promoted the existing local-only matrix behavior on approved source while preserving newer release fixes. Local 2,069/0, four focused tests with zero failures, all 49 CI and ten actual hosted installer/doctor pairs passed; one protected squash and proposal-only run 38170038757 skipped all eight publishers. No new core release was required.

- One v0.2.6 mirror-tag repair passed independent readback, unblocking exact candidate CI.
- Demonstrated release/consumer defects were grouped into protected repair PRs #221, #224, #227, #229, #230 and #233; each merged only after its required CI passed. Local and hosted failure records remain preserved.
- Core PR 232/core 0.2.11 ordinary run 38155320492 is COMPLETE: all three guarded publishers, generated iOS Xcode app build, generated Android full build/debug lint and same-run exact-public passed. Direct exact Hex/iOS/Maven observations succeeded. Exact-public verified six packages/five profiles/two installs each; rollup validated COMPLETE.
- Original Chimeway PR #115/0.1.1 merged once but stopped before Hex on shallow-history ancestry. Its tag is not package publication. Full-history repair #233 passed 2,065 local tests/100 focused/230 inventory sites/all 49 CI. It also merged the single core ledger row and main iOS guide correction.
- Fresh successor Chimeway PR 235/0.1.2 passed 49 CI, independently matching six-row safe Hex rehearsal, actual hosted companion receipt, all six pre/final/postmerge conditions and one protected normal two-parent merge. Ordinary run 38167555514 passed publisher/public clean-room doctor; direct Hex returned HTTP 200 and parsed 0.1.2. The old PR #115 gate was not reused and no failed ordinary release was rerun.
- Requirements, roadmap, state, verification, validation, security and forward blocker disposition agree. Old snapshot bytes/hashes are preserved. Standing authorization remains recorded, and future communication lessons name checks/results/next actions plainly.

## Measured limits

The first-publish runbook timing requirement REL-10/SC-1 is BREACHED and cannot be repaired retroactively. Phase 175 remains OPEN_HISTORICAL_BREACH, score 8/9, STATE active with its required legacy RELEASE HELD line. All actionable forward release requirements are satisfied. The historical label does not call for another release attempt. Six accepted historical high and 12 open lower findings remain visible; current blocking high count is zero. No physical-device, adopter-readiness, release-lint or overwrite of already-published HexDocs is claimed.

## Verification

Approved-source workflow controls: 98/98; independent tracked guard suite: 94 tests, zero failures; repair #233 tracked full suite: 2,065 tests, zero failures (78 excluded), focused: 100 tests, zero failures, exact 230 inventory; original shallow-history guards and old iOS wording failed measured negative checks. Actual new candidate CI, receipts, gates, merges, ordinary jobs and direct registries were inspected separately. See 175-VERIFICATION.md and its artifact links.

## Operation accounting

Remote source updates used exact Git objects, normal fast-forward refs and protected merges; no root staging, local commits, branch switches or worktrees. Each release has its own consumed exact operation binding. Historical partial attempts 0.2.3–0.2.10 and stopped PR #115 remain unchanged. No admin/force/delete, uncertain-delivery retry or recovery publication. One diagnosed screenshot CI-only rerun succeeded; unneeded future core PR #236 CI was cancelled once and PR #236 was not merged/published.

## Workflow continuation

Last completed phase 174. Phase 175 delivery Plan 148 completed; phase 175 remains active solely for its immutable historical criterion. The milestone audit is complete: 42 of 43 requirements are satisfied; REL-10 remains breached. Exact next command: `$gsd-complete-milestone v23.0 --ws quality-ratchet-release`. Archive must preserve that failure. Do not replay completed execution, discuss/plan again, request another allow or start core 0.2.12/adopter work.
