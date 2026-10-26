---
phase: 195-pipeline-repair-and-hygiene
plan: 03
subsystem: infra
tags: [github-actions, dependabot, pr-queue, supply-chain]
requires:
  - phase: 195-02
    provides: PR1 merged, main current
provides:
  - "PR queue drained: #241, #240, #239, #211, #210, #238 all MERGED, one approval each"
  - "pr-queue-195.txt ledger (untracked; plan 04 commits it)"
affects: [195-04]
actuals:
  tokens: 0
  tasks: 3
  commits: 0
  plan_head_before: n/a
  plan_head_after: n/a
requirements-completed: [REL-02, REL-05]
duration: multi-session
completed: 2026-10-26
status: complete
---

# Phase 195 Plan 03: PR queue drain Summary

**All six pre-existing queue PRs merged by merge commit, each behind its own one-use allow bound to head, with pin provenance verified; release PR #236 untouched.**

## Merges (merge commit, head)

| PR | Merge SHA | Head |
|----|-----------|------|
| #241 | 7541b0be85529087bbaa0009b7b121f7ce4d6c1b | 208ab78 |
| #240 | d9f1ba269a6d7b37ba99395d08da360c1f9b2c52 | a858292 |
| #239 | f6e1fa3364f08d93845889db543d124dc2dab9b5 | 8f98ecd |
| #211 | 552d0c4b9aa91f37e540e99b57a6bbd6375f0a90 | af87aa3 |
| #210 | c17c9e09bc0c93086b0d6f6b5a450688ef790604 | 5ec47d6 |
| #238 | 7bd8daf09fe44ae7d5804aa9a7f6f6ff1e1396a4 | 4b0d11d |

CI note: Crosswake CI on each head was a pull_request run, which tests a synthetic merge commit and reports the head SHA (for #238, run 40258550502, head 4b0d11d). No `--admin` used.

## Deviations from Plan

**1. [Amendment] #241 recreate** - Dependabot did not honor `@dependabot rebase` within 15 minutes on #241 (stale head 0e79427), which per plan stops the queue. User decision 2026-10-25: recreate once; on silence extend stale_refresh_timeout to #239/#240/#241. `@dependabot recreate` produced head 208ab78; provenance and CI re-verified; queue resumed. No PR was closed.

**2. Pause/resume** - The plan ran across several continuation sessions at per-PR gates; 195-03-BLOCKED.md was used as a pause marker and is deleted now.

**3. #238 CI/test note** - companion_receipt_test switched to async: false because it uses CaptureIO (docs/tests/ledger-only diff, reviewed by orchestrator).

## Verification

- #238, #239, #240, #241, #210, #211: MERGED; #236: OPEN; open PR list is [236].
- rel236: head 64bd89e, human_commits 0 (live compare).
- pin_provenance ok recorded for all five Dependabot PRs.
- Remote tag count 94 after drain (no tags created/pushed here). Push-event CI on origin/main 7bd8daf was not yet listed at read time; unknown, recheck in plan 04.

## Known Stubs

None.

## Self-Check: PASSED
