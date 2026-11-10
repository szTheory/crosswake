---
phase: 199-release-0-2-12
plan: 09
subsystem: release
tags: [rel-06, rel-17, cleanroom, premerge, trailer, rel-07]

requires:
  - phase: 199-release-0-2-12
    provides: "199-08 candidate (PR 236 head efbc7912), rehearsals, READY FOR APPROVAL receipt"
provides:
  - "Candidate docs (README.md, guides/install.md at head efbc7912) rehearsed against published 0.2.11 with deferred=ios_host: PASS on all four legs"
  - "REL-17 pre_merge gate PASS for linked_release crosswake 0.2.12 with retained sources"
  - "Rendered and checked REL17-AUTHORIZATION trailer and a staged, unrun merge command pinned to the head"
affects: [199-10]

plan_head_before: 47cc2e75ae51cff944ea58b8204c698cb50113be
plan_head_after: 62580e2ad2975e23b421b7132e232a3bfc1c5987
commits: 2

actuals:
  tokens: 45000
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "pre-merge capture reuses the 0.2.11 expected policy digest; a match proves the required-check policy is unchanged"
    - "trailer check run against a scratch AUTHORIZED copy of the gate record; the committed gate record stays PENDING"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/cleanroom-candidate-docs-199.txt
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/core-premerge-199.json
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/core-premerge-result-199.json
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/core-premerge-gate-199.json
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/core-premerge-trailer-199.json
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/core-premerge-authorization-199.json
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/core-premerge-199-sources/
  modified: []

key-decisions:
  - "Supporting pre_merge files (result, gate record, trailer record, authorization input, sources dir) are committed beside core-premerge-199.json because render and check read them from one evidence directory"
  - "The staged merge uses GitHub's default merge subject and a body that is exactly the one trailer line"

requirements-completed: []

coverage:
  - id: D1
    description: "Candidate README.md and guides/install.md pass REL-06 against published 0.2.11 with deferred=ios_host, read from the captured head"
    requirement: REL-07
    verification:
      - kind: integration
        ref: "cleanroom-candidate-docs-199.txt: both Task 1 automated verifies exit 0; result PASS legs hex,maven,ios,docs; rc 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "Pre-merge REL-17 capture passes on the captured head and the trailer is rendered and checked locally; nothing merged"
    requirement: REL-07
    verification:
      - kind: integration
        ref: "core-premerge-199.json: Task 2 jq verify exit 0; render prints 'publish successor core 42390193460'; check PASS; PR 236 still OPEN at the captured head"
        status: pass
    human_judgment: false

duration: "about 25 min"
completed: 2026-11-08
status: complete
---

# Phase 199 Plan 09: Candidate Docs Rehearsed, Pre-Merge Evidence and Trailer Recorded Summary

**The docs that will ship in 0.2.12 (read from PR 236 head efbc7912) pass the REL-06 clean-room against published 0.2.11 on all four legs with `deferred=ios_host`; the REL-17 pre-merge gate passes on that head and the `publish successor core 42390193460` trailer is rendered, checked, and staged in an unrun merge command.**

## What was checked

- **Head unchanged.** Before the capture and again after it, `gh pr view 236` read state OPEN and head `efbc79124e99f5e60f8b85cbad1a507d4763e476`, equal to `core-candidate-199.json`. The head never moved, so no restart.
- **Docs rehearsal (Task 1).** `CLEANROOM_DOCS_REF=<head>` with the toolchain selectors, no pipe. Hex (checksum `2f25d0270963`), Maven (aar `ce617279241c`), iOS (tag commit `424ab96ede1b`) and docs legs all PASS for 0.2.11. The docs line reads `executed=18 not_applicable=2 deferred=ios_host clone=4 shown=4 source=commit:efbc7912...`, preceded by `docs source commit efbc7912...`. Result line `PASS legs hex,maven,ios,docs version 0.2.11`, `cleanroom: rc 0`. Both Task 1 automated verifies exit 0.
- **Pre-merge capture (Task 2).** `mix crosswake.release.gate --capture-live` for `linked_release`, package `crosswake`, version 0.2.12, PR 236, leg run id 42390193460 (the Hex rehearsal run), CI run 42388086844, receipt run 42451279582, artifact 13605577821, receipt digest `a77cb446...`. Output: `REL-17 PASS stage=pre_merge operation=linked_release next=request_exact_gate`. The `expected_policy_sha256` was the 0.2.11 value and matched the live branch-protection and ruleset digest, so that policy has not changed since 0.2.11.
- **Receipt digest.** I downloaded the receipt artifact into the session scratch directory and confirmed `sha256(candidate-receipt.json)` equals the recorded `receipt_sha256` and `identity.bound.run.id` equals 42388086844, which is what the post-merge guard compares.
- **Trailer.** `linked_release_authorization.sh render` printed exactly `publish successor core 42390193460`. `check` passed with the trailer record. Negative controls: a trailer with a changed head and the real (PENDING) gate record were each rejected with rc 1. The jq predicate copied from `release-please.yml` also passed on the trailer line with the live receipt facts.
- **Staged merge command** names `--match-head-commit efbc79124e99f5e60f8b85cbad1a507d4763e476`, `--merge`, no `--admin`, no `--auto`; the body is the one trailer line (one `REL17-AUTHORIZATION: ` line). It was not run: `merge_executed` is false and PR 236 is still OPEN.

## What is unknown, and why

- The `check` result comes from a scratch copy of the gate record marked AUTHORIZED, because `check` only accepts an authorized record. That proves the binding of trailer to evidence, not that anyone authorized a merge. The committed gate record stays PENDING; `core-merge` has no allow.
- The trailer's `policy_sha256` equals the live policy only as of this capture; 199-10 must recheck PR 236's head and CI before displaying the gate.

## Task Commits

1. **Task 1 (tracer): docs rehearsal** - `f73e345c`
2. **Task 2: pre-merge capture and trailer** - `62580e2a`

Measured from the plan ledger: 2 commits on `docs/199-release-0-2-12`, base `47cc2e75`. Local only; nothing pushed.

## Deviations from Plan

### Auto-fixed Issues

None.

### Plan variances

- The plan lists only two files; the gate, render and check tools read a result file, a gate record, a trailer record and a retained sources directory from one evidence directory, so those were committed too (`core-premerge-result-199.json`, `-gate-199.json`, `-trailer-199.json`, `-authorization-199.json`, `core-premerge-199-sources/`).
- `check` was run against a scratch AUTHORIZED copy of the gate record (see above).

**Total deviations:** 0 auto-fixed, 2 variances. **Impact:** none on scope or gates; nothing merged, tagged, published, dispatched or approved.

## Issues Encountered

None blocking. One item for 199-19: the retained pre-merge sources are raw GitHub API payloads, and 8 of them (`live/request-{1,2,4,7,9}.source`, `raw/candidate_readiness.source`, `raw/leg_run.source`, `raw/response_row.source`) contain the maintainer's public commit identity `szTheory@users.noreply.github.com` (18 occurrences), plus `git@github.com` in 4 places (the same `git@github.com` appears in the 0.2.11 precedent sources). The scoped privacy scan treats email-shaped text as a hit, so the 199-19 scan must include these files in its scope decision or the raw sources must be dropped before push. The envelope pins their hashes, so they were not edited.

## Known Stubs

None.

## Threat Flags

None. Reads were unauthenticated or read-only `gh api`; downloads (the receipt artifact) went to the session scratch directory outside the repo; no secret values were read or recorded.

## User Setup Required

None.

## Next Phase Readiness

- Ready for 199-10 (the `core-merge` gate). Facts it needs: PR 236 head `efbc79124e99f5e60f8b85cbad1a507d4763e476`, trailer and staged merge command in `core-premerge-199.json`, receipt expiry 2026-11-22T05:35:11Z.
- 199-10 must re-read the head and CI right before display. If the head moved, restart from 199-08.
- Nothing was merged, tagged, published, dispatched or approved.

## Self-Check: PASSED

- Files present: cleanroom-candidate-docs-199.txt, core-premerge-199.json, core-premerge-result-199.json, core-premerge-gate-199.json, core-premerge-trailer-199.json, core-premerge-authorization-199.json, core-premerge-199-sources/envelope.json.
- Commits `f73e345c` and `62580e2a` are ancestors of HEAD; the measured count from the plan ledger is 2.
- `.planning/config.json` and `.review-diagnostics/` are in no plan commit.
