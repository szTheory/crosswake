---
phase: 200-forward-fix-and-release-0-2-13-default-ios-generation-builds
plan: 05
subsystem: release-train
tags: [rel-06, rel-17, cleanroom, premerge, trailer, remote-form-build, privacy-carry, release-0.2.13]

requires:
  - phase: 200-forward-fix-and-release-0-2-13-default-ios-generation-builds
    provides: 200-04 candidate (PR 280 head 5a6a7521), rehearsals, READY FOR APPROVAL receipt
provides:
  - candidate README.md and guides/install.md (read from head 5a6a7521) rehearsed against published 0.2.12 with deferred=none, PASS on all four legs
  - no-flag remote-form default iOS build of the exact candidate head against the public mirror 0.2.12, PASS with negative control detected
  - REL-17 pre_merge PASS for linked_release crosswake 0.2.13, rendered and checked trailer, staged unrun merge command pinned to the head
  - privacy-carry list of the 23 retained raw pre-merge source files for the Phase 199 closeout scope decision
affects: [200-06]

plan_head_before: 28c868bd7b8a6b8a8b08b3d076d31a70afa5ab7d
plan_head_after: e769072b33fd231d0738b2c7b3760e6a1188582c
commits: 3

actuals:
  tokens: 157000
  tasks: 3
  commits: 3
# tokens: chars/4 over `git diff 28c868bd..e769072b` (628051 bytes), dominated by the 23 retained raw source files.

pr: 280
candidate_head: 5a6a752185cc557af30b0f87244b8088ac83ff93
leg_run_id: 42558226150
trailer_authorization: "publish successor core 42558226150"

tech-stack:
  added: []
  patterns:
    - "docs read from the candidate commit via CLEANROOM_DOCS_REF, published legs from the latest public version 0.2.12"
    - "remote form: generator = candidate head in the worktree, pin 0.2.13 rewritten to the public 0.2.12 in a scratch copy only"
    - "trailer check run against a scratch AUTHORIZED copy of the gate record; committed gate record stays PENDING"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-EVIDENCE/cleanroom-candidate-docs-200.txt
    - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-EVIDENCE/candidate-remote-200.txt
    - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-EVIDENCE/core-premerge-200.json
    - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-EVIDENCE/core-premerge-result-200.json
    - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-EVIDENCE/core-premerge-gate-200.json
    - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-EVIDENCE/core-premerge-trailer-200.json
    - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-EVIDENCE/core-premerge-authorization-200.json
    - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-EVIDENCE/core-premerge-200-sources/
    - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-EVIDENCE/privacy-carry-200.txt
  modified: []

key-decisions:
  - "The remote-form rehearsal ran in the fix worktree detached at the captured head (clean before and after), so the generator is exactly the release PR head; nothing in the candidate was modified"
  - "The result, gate, trailer and authorization-input files the tools read are committed beside core-premerge-200.json (the 199-09 set), built with jq from the retained envelope and facts; evidence paths are repo-relative"
  - "The expected policy digest 0f851ff0... was reused from 199-09 and matched the live branch-protection and ruleset digest again"

requirements-completed: [REL-08, REL-09]

coverage:
  - id: D1
    description: "Candidate docs pass REL-06 against published 0.2.12 on all four legs with deferred=none, read from the captured head"
    requirement: REL-08
    verification:
      - kind: integration
        ref: "cleanroom-candidate-docs-200.txt: three Task 1 verifies exit 0; result PASS legs hex,maven,ios,docs version 0.2.12; rc 0; executed=20"
        status: pass
    human_judgment: false
  - id: D2
    description: "No-flag remote form of the exact candidate head builds against the public mirror 0.2.12 and its negative control detects the removed settings file"
    requirement: REL-08
    verification:
      - kind: integration
        ref: "candidate-remote-200.txt: source equals head_oid and worktree HEAD; rc=0; remote_from=0.2.13 resolved=0.2.12 build_rc=0 control=detected verdict=PASS; worktree status empty after"
        status: pass
    human_judgment: false
  - id: D3
    description: "Pre-merge REL-17 gate passes on the captured head, trailer rendered and checked, merge staged and unrun"
    requirement: REL-09
    verification:
      - kind: integration
        ref: "core-premerge-200.json: Task 3 jq verify exit 0; render prints 'publish successor core 42558226150'; check PASS with scratch AUTHORIZED record; tampered and PENDING controls rc 1; guard predicate rc 0; PR 280 OPEN at head"
        status: pass
    human_judgment: false
  - id: D4
    description: "Retained raw pre-merge sources listed with privacy-scan hit classes"
    requirement: REL-09
    verification:
      - kind: other
        ref: "privacy-carry-200.txt: carry: total files=23 with_hits=13"
        status: pass
    human_judgment: false

duration: "about 10 min of agent work on 2026-11-09 (14:21Z to 14:29Z)"
completed: 2026-11-09
status: complete
---

# Phase 200 Plan 05: Candidate docs, remote-form build and pre-merge evidence Summary

**The docs that will ship in 0.2.13 (read from PR 280 head `5a6a7521`) pass the REL-06 clean-room against published 0.2.12 on all four legs with `deferred=none` and `executed=20`; the exact candidate head's no-flag remote form builds against the public mirror at 0.2.12 with its negative control detected; the REL-17 pre-merge gate passes on that head and the `publish successor core 42558226150` trailer is rendered, checked and staged in an unrun merge command.**

## What was checked and what happened

- **Head unchanged.** I read PR 280 (`gh pr view`, read only) before each of the three capture steps, again after the docs run, after the remote build and after the capture: every read said OPEN at `5a6a752185cc557af30b0f87244b8088ac83ff93`, equal to `core-candidate-200.json`. No restart.
- **Docs rehearsal (Task 1, tracer).** `CLEANROOM_DOCS_REF=<head>`, toolchain `1.19.5-otp-27` / `27.3`, no pipe, against `0.2.12`. Hex (checksum `1ae48fe3f2e8`), Maven (aar `76adb1341a57`), iOS (tag commit `095267ea23c9`) and docs legs all PASS. The docs line reads `executed=20 not_applicable=0 deferred=none clone=4 shown=4 source=commit:5a6a7521... phx_new=1.8.13`, preceded by `docs source commit 5a6a7521...`. Result `PASS legs hex,maven,ios,docs version 0.2.12`, `cleanroom: rc 0`. All three Task 1 verifies exit 0 and no `docs deferred` line exists: the `:ios_host` step now executes against 0.2.12. **`executed=20` against 199-09's `executed=18` (greater than 18, as the acceptance criterion requires).** This is the first REL-06 docs run against a version with no deferral.
- **Remote-form build (Task 2).** In `~/projects/crosswake-200-wt` (clean): `git fetch origin release-please--branches--main`, `FETCH_HEAD` equal to the head, `git switch --detach <head>`, `mix deps.get`. Source recorded right before the run, then `bash script/verify_default_ios_generation_build.sh --remote-version 0.2.12`, status read directly (no pipe): `rc=0`, `mode=remote project=generated generator=5a6a7521... generator_dirty=no remote_from=0.2.13 remote_min=0.2.12 resolved=0.2.12 build_rc=0 build_seconds=14 control_rc=65 control=detected verdict=PASS first_error=none`. The candidate generates the 0.2.13 pin; only the scratch copy was pointed at the public 0.2.12 core, resolved from the mirror. Both Task 2 verifies exit 0; `git status --porcelain` in the worktree was empty after the run. The generator tree differed from the fix branch only by being the release head; no compile error against the 0.2.12 core, so the `hex-v0.2.12` generated-sources diff was not needed.
- **Pre-merge capture (Task 3).** `mix crosswake.release.gate --capture-live` for `linked_release`, package `crosswake`, version 0.2.13, PR 280, leg run id 42558226150 (the Hex rehearsal run), CI run 42556235341, receipt run 42633255271, receipt artifact 13681238151, receipt digest `8c905dea...`, base `e8d44c6c`, head `5a6a7521`, tree `4605bb05`, runbook commit `d3401e51` (still the `RUNBOOK_SHA` in the candidate's `release-please.yml`), expected policy digest `0f851ff0...` reused from 199-09. Output `REL-17 PASS stage=pre_merge operation=linked_release next=request_exact_gate`, so branch protection and rulesets have not changed since 0.2.11. The envelope sha256 is `9bb83bfa...`.
- **Trailer.** `linked_release_authorization.sh render` printed exactly `publish successor core 42558226150`. `check` passed against a scratch AUTHORIZED copy of the gate record (`Gate 2 authorization binding PASS`); a trailer with a changed head and the committed (PENDING) gate record were each rejected with rc 1; the `release-please.yml` guard's jq predicate also passed on the trailer line with the live receipt facts. The staged merge command is `gh pr merge 280 --repo szTheory/crosswake --merge --match-head-commit 5a6a7521... --subject 'Merge pull request #280 from szTheory/release-please--branches--main' --body 'REL17-AUTHORIZATION: {...}'`, no `--admin`, `--squash`, `--rebase` or `--auto`, body exactly one trailer line. `merge_executed` is false.
- **Privacy carry list.** `core-premerge-200-sources/` holds 23 files. I scanned each with `privacy-193.sh` one file per invocation (absolute paths, loop over a scratch file list): 13 files have hits, 10 are clean. Class `home_path` in all 13: the scanner's case-insensitive match of the public path segment `users/<name>` in `api.github.com/users/<name>` and `hex.pm/api/users/<name>` URLs (no local home directory appears). Class `email` in 2 files (`live/request-1.source`, `raw/candidate_readiness.source`): `git@github.com`, an SSH clone-URL form. The maintainer's public noreply commit address (`users.noreply.github.com`, 8 files) is a scanner-allowed address and is not a hit this time. `privacy-carry-200.txt` ends `carry: total files=23 with_hits=13`. The files were not edited.

## What is unknown, and why

- The `check` result comes from a scratch copy of the gate record marked AUTHORIZED because `check` only accepts an authorized record. That proves the binding of trailer to evidence, not that anyone authorized a merge. The committed gate record stays PENDING; `core-merge` has no allow.
- The trailer's `policy_sha256` equals the live policy only as of this capture. 200-06 must recheck PR 280's head, state and CI right before displaying the gate; a moved head restarts from 200-04.
- The docs leg's stderr carries one line `script/verify_published_cleanroom.sh: child setpgid (...): Operation not permitted`, recorded in the evidence file as observed. It did not change the verdict (PASS, rc 0) and the 199-09 evidence file has no such line; I did not investigate or re-run.
- The remote-form rehearsal proves the generated project builds from the public 0.2.12 mirror with the settings file present. It cannot prove the build against the 0.2.13 mirror tag, which exists only after publication (the post-publish iOS clean-room is that proof).
- The receipt artifact digest was not re-downloaded in this plan; 200-04 recorded `sha256(receipt)` equal to `8c905dea...` and the capture's `receipt_artifact_live` read true.

## Task Commits

1. **Task 1 (tracer): docs rehearsal against 0.2.12** - `81f86b9c`
2. **Task 2: remote-form build of the candidate** - `0b1bf8bc`
3. **Task 3: pre-merge capture, trailer, privacy carry list** - `e769072b`

Measured from the plan ledger: 3 commits on `docs/199-release-0-2-12`, base `28c868bd`. Local only; nothing pushed.

## Deviations from Plan

### Auto-fixed Issues

None.

### Plan variances

- The plan lists two Task 3 files; the gate, render and check tools read a result file, a gate record, a trailer record, an authorization input and a retained sources directory from one evidence directory, so those were committed too (same set as 199-09). The result, gate and trailer files were assembled with `jq` from the retained envelope and facts (the 199 files were checked to match that derivation: result `.sources` equals the `facts/` files, `envelope_sha256` equals the envelope file hash); evidence paths are repo-relative.
- `jq` 1.7.1 mangled an escaped single quote while composing the staged merge command in the first pass; I rebuilt `merge_command` with the quote passed as an argument and re-ran the verify. The committed file is the corrected one.
- The privacy scan flagged `home_path` (public API URLs) in 13 files where 199-09 noted only email-shaped text; recorded as observed in the carry list.

**Total deviations:** 0 auto-fixed, 3 variances. **Impact:** none on scope or gates; nothing merged, tagged, published, dispatched or approved.

## Issues Encountered

None blocking. For the Phase 199 closeout: the retained pre-merge raw sources are GitHub and Hex API payloads; 13 of 23 files trip the scanner (class list in `privacy-carry-200.txt`), so the closeout scope decision must either scope them out or drop them before any push of the docs branch. Phase 200 pushes nothing.

## Known Stubs

None.

## Threat Flags

None. Reads were unauthenticated or read-only `gh` calls; the only network effect beyond reads was `git fetch` of the release branch into the worktree and the clean-room downloads, all inside scratch or the worktree's own work root; no secret values were read or recorded (a token-shape grep over the committed evidence returned no matches).

## User Setup Required

None.

## Next Phase Readiness

- Ready for 200-06 (the `core-merge` gate). Facts it needs: PR 280 head `5a6a752185cc557af30b0f87244b8088ac83ff93`, trailer and staged merge command in `core-premerge-200.json`, remote-form PASS for the same head in `candidate-remote-200.txt` (the merge precheck requires it), receipt expiry 2026-11-23T14:19:07Z.
- 200-06 must re-read the head and CI right before display. If the head moved, 200-04 restarts with a new `core-maven-drill` display and allow.
- Nothing was merged, tagged, published, dispatched or approved. PRs 280, 262 and 279 were only read; the remote fix branch is untouched; the worktree is left detached at the candidate head, clean (the fix branch is checked out nowhere; switch back before any worktree commit).

## Self-Check: PASSED

- Files present: cleanroom-candidate-docs-200.txt, candidate-remote-200.txt, core-premerge-200.json, core-premerge-result-200.json, core-premerge-gate-200.json, core-premerge-trailer-200.json, core-premerge-authorization-200.json, core-premerge-200-sources/envelope.json, privacy-carry-200.txt.
- Commits `81f86b9c`, `0b1bf8bc` and `e769072b` are ancestors of HEAD; the measured count from the plan ledger is 3.
- `.planning/config.json`, `.review-diagnostics/` and the phase `.gitkeep` are in no plan commit.
