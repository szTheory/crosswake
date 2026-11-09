---
phase: 200-forward-fix-and-release-0-2-13-default-ios-generation-builds
plan: 04
subsystem: release-train
tags: [release-candidate, rehearsal, fire-drill, receipt, core-maven-drill, gate, release-0.2.13]

requires:
  - phase: 200-forward-fix-and-release-0-2-13-default-ios-generation-builds
    provides: 200-03 fix PR 282 merged to main as e8d44c6c with the pre-release build gate
provides:
  - release PR 280 (0.2.13) pinned at head 5a6a7521 on base e8d44c6c, CI 39 of 39 green with the build gate PASS line, predicate PASS, targets absent
  - Hex and iOS mirror candidate rehearsals on that head, no external state change
  - one Maven fire drill behind its own core-maven-drill allow, validated then dropped, 0.2.13 POM still 404
  - one READY FOR APPROVAL receipt, publication NONE, 13 of 13 checks, bound to the head and the three rehearsal runs
affects: [200-05, 200-06]

actuals:
  tokens: 52000
  tasks: 3
  commits: 4
# commits: MEASURED from the ledger (git rev-list --count ab550fe4..HEAD, taken before this summary commit):
# 2742310a, 93310efd, 288f523f, a28b1514, all on the local docs branch. This summary and tracking commits follow.
plan_head_before: ab550fe451d8c9aea0cc4d629c87a6210d98e00a
plan_head_after: a28b1514391690fce14ad5d1e16d1cfaf2394709
pr: 280
candidate_head: 5a6a752185cc557af30b0f87244b8088ac83ff93
candidate_base: e8d44c6c907a5f16d333c62df6b8d6dcd4d32e3c
candidate_tree: 4605bb05edf60b04f7330058a6c38675c064e746
ci_run_id: 42556235341
ci_ran_on: ccb950d5c481a238b5dace9167fd71e0e28e4800
hex_rehearsal_run: 42558226150
ios_rehearsal_run: 42558247628
maven_drill_run: 42632645093
attestation_run_id: 42633255271
receipt_artifact_id: 13681238151
receipt_sha256: 8c905dea15a8ea285db0205d218f1d0a5d332474a28404b94b4027a2552f4507

tech-stack:
  added: []
  patterns:
    - "declared-input rule read against origin/main workflow files (the docs branch predates the fix PR) before each of the four dispatches"
    - "dispatch intent and prior max run id recorded before each gh workflow run; runs listed above that id afterwards"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-EVIDENCE/core-candidate-200.json
    - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-EVIDENCE/core-candidate-capture-200.json
    - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-EVIDENCE/core-rehearsals-200.json
    - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-EVIDENCE/core-receipt-200.json
    - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-EVIDENCE/gates-200.txt
    - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-EVIDENCE/gate-order-controls-200.txt
  modified: []

key-decisions:
  - "The fire drill uploads a disposable 0.2.13-firedrill-<run id> coordinate, not 0.2.13 itself; the plan's gate wording ('a signed 0.2.13 bundle') was corrected at display"
  - "The capture is written once and the stale first candidate (head 9ce07d20 on base 1dcdaad8, red CI) is recorded only as a note; the candidate was taken only after Release Please refreshed PR 280 onto the fix merge"

requirements-completed: [REL-08, REL-09]

coverage:
  - id: D1
    description: "0.2.13 candidate pinned: head, base containing the fix merge, tree, CI green with the build-gate PASS line, predicate PASS, absences, ten secret names"
    requirement: REL-08
    verification:
      - kind: other
        ref: "core-candidate-200.json: three Task 1 verifies exit 0; CI run 42556235341 39 of 39 success; phase79-ios-proof line control=detected verdict=PASS"
        status: pass
    human_judgment: false
  - id: D2
    description: "Hex and iOS rehearsals on the exact head changed no external state"
    requirement: REL-09
    verification:
      - kind: integration
        ref: "core-rehearsals-200.json: runs 42558226150 and 42558247628 success, external_state_changed false, exact input maps"
        status: pass
    human_judgment: false
  - id: D3
    description: "Maven fire drill ran once behind the displayed core-maven-drill allow for this head, validated then dropped"
    requirement: REL-09
    verification:
      - kind: integration
        ref: "gate-order-200.awk exit 0 for core-maven-drill; run 42632645093 success; state VALIDATED, dropped true; POM 404"
        status: pass
    human_judgment: false
  - id: D4
    description: "Hosted attestation produced one unexpired READY FOR APPROVAL receipt, publication NONE, bound to the head and rehearsal runs"
    requirement: REL-09
    verification:
      - kind: integration
        ref: "core-receipt-200.json: run 42633255271, artifact 13681238151, 13 of 13 checks, identity bound equals observed"
        status: pass
    human_judgment: false

duration: "about 1 h 10 min of agent work on 2026-11-09 (03:21Z to 03:51Z, then 14:16Z to 14:25Z); wall clock spans a 10-hour wait for the user's reply"
completed: 2026-11-09
status: complete
---

# Phase 200 Plan 04: 0.2.13 core candidate captured, rehearsed and receipted Summary

**Release PR 280 (0.2.13, head `5a6a7521`, base `e8d44c6c` = the fix merge) was pinned after Crosswake CI passed on that exact head including the new default-iOS build gate; Hex and iOS rehearsals changed nothing, one Maven fire drill ran behind the user's `core-maven-drill` allow and was dropped with the real 0.2.13 POM still 404, and the hosted attestation produced one READY FOR APPROVAL receipt (13 of 13 checks, publication NONE, expires 2026-11-23).**

## What was checked and what happened

- **Candidate (Task 1).** At the start PR 280 was on a stale base (`1dcdaad8`, head `9ce07d20`, red CI). I did not capture that. After the Release Please run on the fix merge finished (run 42555894094, success 03:24:38Z) PR 280 was refreshed at 03:24:27Z onto head `5a6a752185cc557af30b0f87244b8088ac83ff93` with base `e8d44c6c` (equal to origin/main). I only polled `gh run view` and `gh pr view`; nothing was written to the release-please branch. The head contains the fix (`git merge-base --is-ancestor e8d44c6c <head>` true). Crosswake CI run 42556235341 passed 39 of 39 jobs on that exact head (created 03:24:30Z, done by 03:44:43Z, about 20 minutes). **CI checked out the synthetic merge commit `ccb950d5c481a238b5dace9167fd71e0e28e4800`, not the head.** Its `phase79-ios-proof` log carries `default-ios-build: mode=local project=generated generator=ccb950d5... generator_dirty=no ... build_rc=0 build_seconds=23 control_rc=65 control=detected verdict=PASS first_error=none`. The release-PR-head predicate exited 0 (`commits=1 paths=10 managed=13 verdict=PASS`; author logged as a value only). Hex 0.2.13, the mirror tag `v0.2.13`, the Maven 0.2.13 POM and the three source tags are absent; the ten secret names match exactly (names only); `deleteBranchOnMerge` is false; the environment preflight returned 0. Capture digest `eeed64ca...` is the sha256 of the capture file, written once.
- **Controls and rehearsals (Task 2).** The gate-order checker's controls passed 53 of 53 (twice: at record time and at verify time). Hex `candidate-rehearsal` run 42558226150 and iOS `candidate-rehearsal` run 42558247628 were each dispatched once on `release-please--branches--main` with exactly the plan's input maps, after recording the prior max run id and applying the declared-input rule. Both succeeded on the captured head, the head did not move, both artifacts report `external_state_changed:false`, and every publish and recovery job was skipped.
- **Fire drill (Task 3, gated).** The user answered `allow` for `core-maven-drill` attempt 1 to the orchestrator; `gates-200.txt` has, in protocol order: display-time PASS precheck 03:51:09Z, `gate:` displayed 03:51:18Z, reply-time PASS precheck 14:13:54Z, `decision: ... allow` 14:13:56Z, then `applied: ... result=validated_then_dropped` after I read the run. The gate-order awk check for the captured head exits 0. The drill is run 42632645093: success, `head_sha` equals the captured head, the log ends "SUCCESS: disposable Maven deployment reached VALIDATED and DROP completed", the artifact says state VALIDATED and `dropped:true`, the disposable coordinate is `0.2.13-firedrill-42632645093`, and the real 0.2.13 POM (and Hex 0.2.13) are still 404. Only one drill run exists above the recorded prior max 42450991698. The PR head did not move.
- **Receipt.** Attestation run 42633255271 (one dispatch, prior max run id 42558247628, one run above it) produced exactly one unexpired artifact `phase168-candidate-receipt-5a6a752185cc557af30b0f87244b8088ac83ff93` (id 13681238151, expires 2026-11-23T14:19:07Z, about 14 days). State READY FOR APPROVAL, 13 of 13 checks PASS, `identity.bound == identity.observed`, publication NONE, credentials exercised and PROVEN for mirror write authority. Receipt sha256 `8c905dea15a8ea285db0205d218f1d0a5d332474a28404b94b4027a2552f4507`. The receipt's proof hashes for the Hex, iOS and Maven rehearsals equal the sha256 of the three rehearsal artifacts this plan recorded.
- All Task 1, 2 and 3 automated verifies exit 0 (checked: candidate, secret-shape, digest; controls, rehearsals, precheck; gate-order awk, Maven entry, receipt, full-field attestation check, four-record declared-input loop, no 0.2.12 head in gates-200.txt). Acceptance: `ci_ran_on` differs from `head_oid`; no fire-drill run was dispatched in Task 2; `expires_at` is far more than 24 hours after the task; the Maven entry has dispatch ref `release-please--branches--main` and `head_before == head_after ==` the captured head.

## What is unknown, and why

- **Central Portal deployment id.** The drill script does not print it and the artifact does not carry it, so it is recorded as `not_exposed_by_run`. DROPPED is evidenced by the script's DELETE call succeeding under `curl -f`, the success line and the artifact, not by a separate Central Portal read.
- Whether the receipt would still read the same on a moved head is untested by design; a moved head restarts this plan.
- The 40-character head, base and tree are in the receipt, but the receipt expiry (2026-11-23) must outlast the later merge, tag and publish gates.

## How the gated step was performed (relayed allow)

- A plan agent cannot see the user's reply. I stopped at the gate with the structured checkpoint after the pre-work and did not dispatch. The user's `allow` reached the orchestrator directly, and **the orchestrator, not the plan agent, performed the one gated dispatch** at 14:13:56Z (record first, declared-input rule, one `gh workflow run`). I verified the run read-only, completed the Maven entry, wrote `applied:`, then dispatched the attestation (not gated; it only reads and attests, and publishes nothing).
- **Display-to-reply gap: about 10 hours** (display 03:51:18Z, reply 14:13:56Z). The head did not move across it; the orchestrator rechecked all facts at reply time (reply-time precheck PASS 14:13:54Z, after the `gate:` line) and I rechecked head, POM and Hex afterwards.
- **Wording correction.** The plan's gate context says the drill "uploads a signed 0.2.13 bundle". It actually uploads the disposable coordinate `io.github.sztheory:crosswake-shell-core-android:0.2.13-firedrill-<run id>` as a USER_MANAGED deployment and drops it in the same step. The real 0.2.13 coordinate was never touched. The display said so.

## Task Commits

1. **Task 1 (tracer): candidate capture** - `2742310a`
2. **Task 2: controls, rehearsals, drill precheck** - `93310efd`
3. **Task 3: fresh display precheck** - `288f523f`; **gate lines, drill entry, receipt** - `a28b1514`

Measured from the plan ledger: 4 commits on `docs/199-release-0-2-12`, base `ab550fe4`. The branch is local only; nothing was pushed.

## Deviations from Plan

### Auto-fixed Issues

None.

### Plan variances

- The gated dispatch was run by the orchestrator on the user's direct allow (see above); the plan assumed the plan agent would run it.
- The declared-input rule read the dispatch workflows from `origin/main` (via `git show`), because the docs branch's `crosswake-ci.yml` predates the fix PR and so the working tree differs from origin/main; the three dispatch workflows are byte-identical to origin/main and to the release head.
- A third `precheck:` line (03:49:34Z, 03:50:12Z, 03:51:09Z) exists before the gate: two by me, one by the orchestrator at display time. The checker accepts this.
- `core-candidate-200.json` carries an extra informational `notes` object (including the superseded stale candidate `9ce07d20`).

**Total deviations:** 0 auto-fixed, 4 variances. **Impact:** none on scope or gates; no gate loosened.

## Issues Encountered

- PR 280 was on a stale base when the plan started; the candidate was taken only after Release Please refreshed it (about 4 minutes after the fix merge). My first stale-directory scratch download hashes matched Phase 199's files because the session scratchpad already held Phase 199 download directories; I re-downloaded into fresh directories and recorded only the fresh hashes.

## Known Stubs

None.

## Threat Flags

None. All four dispatches used only declared inputs and read-only or self-dropping operations; downloads stayed in the session scratch directory outside the repo; no secret values were read or recorded (names only; the secret-shape scan of the evidence was clean).

## User Setup Required

None.

## Next Phase Readiness

- Ready for 200-05 (candidate docs rehearsal and the pre-merge capture; the no-flag remote-form rehearsal uses the newest mirror tag as `--remote-version`, 0.2.12 until 0.2.13 is public). Receipt facts for the later trailer: `receipt_sha256` 8c905dea15a8ea285db0205d218f1d0a5d332474a28404b94b4027a2552f4507, `attestation_run_id` 42633255271, `artifact_id` 13681238151, CI run 42556235341, Hex rehearsal run 42558226150.
- Receipt expires 2026-11-23T14:19:07Z; PR 280 head `5a6a7521` must still be the head at merge time, or this plan restarts from Task 1 with a new `core-maven-drill` display and allow.
- Nothing was merged, tagged, published or approved. PRs 280, 262 and 279 and all release branches were only read; no remote branch was deleted; the docs branch is local.

## Self-Check: PASSED

- Files present: core-candidate-200.json, core-candidate-capture-200.json, core-rehearsals-200.json, core-receipt-200.json, gates-200.txt, gate-order-controls-200.txt.
- Commits `2742310a`, `93310efd`, `288f523f` and `a28b1514` are ancestors of HEAD; the measured count from the plan ledger is 4.
- `.planning/config.json`, `.review-diagnostics/` and the phase `.gitkeep` are in no plan commit.
