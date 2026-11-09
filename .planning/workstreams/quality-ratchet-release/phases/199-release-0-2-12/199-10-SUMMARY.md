---
phase: 199-release-0-2-12
plan: 10
subsystem: release
tags: [rel-07, core-merge, core-tags, release-please, gates]

requires:
  - phase: 199-release-0-2-12
    provides: "199-09 checked REL17-AUTHORIZATION trailer and staged merge command pinned to PR 236 head efbc7912"
provides:
  - "Release PR 236 (Crosswake 0.2.12) merged under its own one-use allow as merge commit 1dcdaad8, parents [a9c4ff74, efbc7912], approved tree, one REL17-AUTHORIZATION line"
  - "Tags hex-v0.2.12, ios-core-v0.2.12 and android-core-v0.2.12 and their three GitHub Releases created under one shared allow, all at the merge commit"
  - "Release run 42494651844 waiting at publish-hex only; no publisher started"
affects: [199-11]

plan_head_before: 523df797bbd75295b838d89eb43920b20832fd41
plan_head_after: 3fdcd6a8e9c1bb6e6498559645c1a5031452897e
commits: 5

actuals:
  tokens: 60000
  tasks: 3
  commits: 5

tech-stack:
  added: []
  patterns:
    - "gate evidence in gates-199.txt: precheck, gate, decision, applied per attempt; verified by awk"
    - "deployment approval passes exactly one environment id with the comment '199 <id> attempt <n>'"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/core-merge-199.json
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/core-tags-199.json
  modified:
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/gates-199.txt

key-decisions:
  - "The environment-read precheck treats 'guard run no older than the PR head CI run' as satisfied by the latest main run on the current main head, because that run created PR 236 and no newer run can exist"
  - "core-merge-199.json also carries the merge commit under the name merge_oid, because the plan's tag verify reads that name"

requirements-completed: []

coverage:
  - id: D1
    description: "PR 236 merged only after its own allow, as a two-parent merge of the approved head and tree with exactly one trailer (SC1)"
    requirement: REL-07
    verification:
      - kind: integration
        ref: "gates-199.txt core-merge awk exits 0; core-merge-199.json jq exits 0; GitHub: PR 236 MERGED, commit 1dcdaad8 has parents [a9c4ff74, efbc7912], tree 5cce613d, one trailer"
        status: pass
    human_judgment: false
  - id: D2
    description: "Three linked source tags and GitHub Releases created at the merge commit under one shared allow; run waits at publish-hex (SC2 as amended by D-04)"
    requirement: REL-07
    verification:
      - kind: integration
        ref: "gates-199.txt core-tags awk exits 0; core-tags-199.json jq exits 0; git ls-remote shows three tags at 1dcdaad8; pending deployments: one, publish-hex"
        status: pass
    human_judgment: false

duration: "about 10 h wall clock, of which about 9.5 h was waiting for the user's reply"
completed: 2026-11-08
status: complete
---

# Phase 199 Plan 10: Core merge and source tags Summary

**Release PR 236 (Crosswake 0.2.12) is merged as `1dcdaad8dea087ddebd62bf7ca0515988d2d3f9c` under its own allow, the three source tags and GitHub Releases exist at that commit under one shared allow, and the release run now waits at the Hex gate with nothing published.**

## What was checked and what happened

- **Task 1 (tracer, `a555da26`).** Before any display, every fact was re-read: PR 236 open and clean at head `efbc7912`, base equal to main `a9c4ff74`, CI run 42388086844 green on it, one unexpired receipt (expires 2026-11-22T05:35:11Z), Hex, Maven and mirror tag absent, the three source tags absent, local environment preflight rc 0, latest main guard log `verdict=PASS`, and the REL-17 pre-merge capture re-run to a byte-identical envelope. Precheck written at 2026-11-08T05:47:35Z.
- **Task 2, gate `core-merge` attempt 1.** Displayed about 05:49Z; the user replied `allow` at 2026-11-08T15:24:23Z; PR 236 merged once at 15:24:25Z through the staged `gh pr merge --merge --match-head-commit` command. Verified again from GitHub when closing this plan: state MERGED, merge commit `1dcdaad8dea087ddebd62bf7ca0515988d2d3f9c`, parents `[a9c4ff74cfd92b6ab3fa7da32dae2f346335e7b9, efbc79124e99f5e60f8b85cbad1a507d4763e476]`, tree `5cce613d376760ae16c5c6c7809845d88e3de660` (equal to the approved tree), exactly one `REL17-AUTHORIZATION:` line. The approved-candidate merge guard then passed on the hosted runner.
- **Task 3, gate `core-tags` attempt 1.** Precheck PASS at 15:26:14Z (run 42494651844, environment `release-tags` id 26568191383, guard success, one pending entry, Hex 404). Displayed about 15:27Z; the user replied `allow`; exactly that one environment id was approved once at 2026-11-08T15:38:47Z with the comment `199 core-tags attempt 1`. Release Please then succeeded. Verified from GitHub: `hex-v0.2.12`, `ios-core-v0.2.12` and `android-core-v0.2.12` all resolve to `1dcdaad8`; the three GitHub Releases exist; run 42494651844 has one pending deployment, `publish-hex` (id 26568191797), and no publisher job has started; Hex 0.2.12 still returns 404; the mirror tag `v0.2.12` is still absent.
- Both plan verifies (the two awk gate-order checks and the two jq record checks) exit 0 when I re-ran them, and `core-merge-199.json` `.parents[1]` equals `core-candidate-199.json` `.head_oid`.

## What is unknown, and why

- Nothing is published yet, so nothing about Hex, Maven or the mirror for 0.2.12 is established beyond "still absent".
- Both tag and release names were read from GitHub, not from the release job log; the tag objects are lightweight pointing directly at the merge commit (the refs list shows the merge commit itself).

## Deviations from Plan

### Plan variances

1. **The gated actions were performed by the orchestrator, not by this plan agent.** A plan agent cannot see the user's reply, so the orchestrator displayed both gates, received the user's plain-language `allow` for each, re-read facts at reply time, and ran the merge and the single environment approval once each. This plan agent stopped after Task 1 and verified and recorded the outcome afterwards.
2. **Long gap between display and reply.** The `core-merge` gate was shown at about 05:49Z and answered at 15:24:23Z, about 9.5 hours later. The drift recheck at reply time found the PR head, base, CI and absences unchanged; the decision line records the exact reply time.
3. **Guard-run age wording.** The plan says the latest main Release Please run must be no older than the PR head's CI run. That cannot hold literally: run 42387805006 created PR 236 (its Release Please job ended 15:47:36Z, the CI run started 15:47:35Z) and no push to main happened since. It was treated as satisfied on the current-main-head basis and noted in `gates-199.txt`. The hosted guard of the merge run itself then passed, so the environment read held.
4. **`merge_oid` field.** `core-merge-199.json` first recorded the merge commit as `merge_commit`; the plan's tag verify reads `merge_oid`, so commit `92e14d30` added that name beside it. A placeholder `merged_at_utc` (`15:24:2xZ`) was replaced with GitHub's `mergedAt` (`15:24:25Z`) in `3fdcd6a8`.

**Total deviations:** 0 auto-fixed, 4 variances. **Impact:** none on scope or order; one merge, one approval, no other external action.

## Expected red check

The iOS mirror parity check on open PRs (for example PR 262) is expected to be red now: the source tags exist and the mirror tag `v0.2.12` does not, until the iOS gate (`core-ios`) is done. This was announced in the `core-tags` display (D-04 note).

## Items for later plans

- **199-19 privacy scope.** 8 retained pre-merge raw source files (`core-premerge-199-sources/live/request-{1,2,4,7,9}.source`, `raw/candidate_readiness.source`, `raw/leg_run.source`, `raw/response_row.source`) contain the maintainer's public noreply commit email, and 4 places contain `git@github.com` (also present in the 0.2.11 precedent). The scoped privacy scan counts email-shaped text as a hit, so the 199-19 scan must either cover these files in its scope decision or drop the raw sources before push. The envelope pins their hashes, so they were not edited.
- **199-11** is the `core-hex` gate; the run waits at `publish-hex`.

## Task Commits

1. **Task 1 (tracer): core-merge precheck** - `a555da26`
2. **Task 2: core-merge gate record and merge** - `89f21982`, then `92e14d30` (merge_oid), `3fdcd6a8` (exact merge time)
3. **Task 3: core-tags gate record and tags** - `e1ad4b53`

Measured from the plan ledger: 5 commits on `docs/199-release-0-2-12`, base `523df797`. Local only; nothing pushed.

## Known Stubs

None.

## Threat Flags

None. Approvals were limited to one merge and one deployment environment id; no secret values were read or recorded.

## User Setup Required

None.

## Self-Check: PASSED

- Files present: gates-199.txt, core-merge-199.json, core-tags-199.json.
- Commits `a555da26`, `89f21982`, `92e14d30`, `e1ad4b53` and `3fdcd6a8` are ancestors of HEAD; measured count from the plan ledger is 5.
- GitHub re-read: PR 236 MERGED at `1dcdaad8`; three tags and three Releases at that commit; run 42494651844 waiting at `publish-hex` only; Hex 0.2.12 404; mirror tag absent.
- `.planning/config.json` and `.review-diagnostics/` are in no plan commit.
