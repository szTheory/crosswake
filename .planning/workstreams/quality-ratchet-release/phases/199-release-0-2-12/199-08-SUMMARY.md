---
phase: 199-release-0-2-12
plan: 08
subsystem: release
tags: [release-candidate, rehearsal, fire-drill, receipt, core-maven-drill, gate, rel-07]

requires:
  - phase: 199-release-0-2-12
    provides: "199-07 gate pipeline on main, release-PR-head predicate, PR 236 refreshed on base a9c4ff74"
provides:
  - "PR 236 (0.2.12) pinned at head efbc7912 with CI green, predicate PASS, three targets absent, ten secret names present"
  - "Hex and iOS candidate rehearsals on that head with no external state change"
  - "One Maven fire drill behind its own core-maven-drill allow, validated then dropped, POM still 404"
  - "One READY FOR APPROVAL receipt, publication NONE, 13 of 13 checks, bound to the head and the three rehearsal runs"
affects: [199-09, 199-10]

plan_head_before: a9c4ff74cfd92b6ab3fa7da32dae2f346335e7b9
plan_head_after: fb4a85caad6e1b6a6db62b619076c9f8e31fdf4f
commits: 5

actuals:
  tokens: 60000
  tasks: 3
  commits: 5

tech-stack:
  added: []
  patterns:
    - "declared-input rule: every dispatch record checked against the target workflow's workflow_dispatch.inputs before dispatch"
    - "dispatch intent and prior max run id recorded before each gh workflow run; runs listed above that id afterwards"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/core-candidate-199.json
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/core-candidate-capture-199.json
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/core-rehearsals-199.json
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/core-receipt-199.json
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/gates-199.txt
  modified: []

key-decisions:
  - "The fire drill uploads a disposable 0.2.12-firedrill-<run id> coordinate, not 0.2.12 itself; the gate text was corrected accordingly at display"
  - "Candidate capture omits runbook_ancestry and android_compatibility_repair_merge_oid from the precedent shape: no producer or consumer found, values were specific to 0.2.11"

requirements-completed: []

coverage:
  - id: D1
    description: "Exact release candidate pinned: head, base, tree, version, CI, predicate, absences, secret names, environment preflight"
    requirement: REL-07
    verification:
      - kind: other
        ref: "core-candidate-199.json: five Task 1 jq/shell verifies exit 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "Hex and iOS candidate rehearsals on the release branch head changed no external state"
    requirement: REL-07
    verification:
      - kind: integration
        ref: "core-rehearsals-199.json: runs 42390193460 and 42390232440 success, external_state_changed false, exact input maps"
        status: pass
    human_judgment: false
  - id: D3
    description: "Maven fire drill ran once behind the displayed core-maven-drill allow for this head, validated then dropped"
    requirement: REL-07
    verification:
      - kind: integration
        ref: "gates-199.txt awk verify exit 0; run 42450991698 success; central_final_state DROPPED; pom_status_after 404"
        status: pass
    human_judgment: false
  - id: D4
    description: "Hosted attestation produced one unexpired READY FOR APPROVAL receipt, publication NONE, bound to the head and rehearsal runs"
    requirement: REL-07
    verification:
      - kind: integration
        ref: "core-receipt-199.json: run 42451279582, artifact 13605577821, 13 of 13 checks, identity bound equals observed"
        status: pass
    human_judgment: false

duration: "about 40 min of agent work on 2026-11-07 (16:10Z to 16:17Z, then 2026-11-08 05:30Z to 05:40Z); wall clock spans a 13-hour wait for the user's reply"
completed: 2026-11-08
status: complete
---

# Phase 199 Plan 08: Core Candidate Captured, Rehearsed and Receipted Summary

**Release PR 236 (0.2.12, head efbc7912) was pinned and rehearsed: Hex and iOS rehearsals changed nothing, one Maven fire drill ran behind the user's `core-maven-drill` allow and was dropped with the real 0.2.12 POM still absent, and the hosted attestation produced one READY FOR APPROVAL receipt (13 of 13 checks, publication NONE, expires 2026-11-22).**

## What was checked

- **Candidate (Task 1).** PR 236 is open, not draft, MERGEABLE/CLEAN, version 0.2.12, base `a9c4ff74`, tree `5cce613d`. The shared predicate `release-pr-head-199.sh` exited 0 (`commits=1 paths=10 managed=13 verdict=PASS`; author `szTheory` logged as a value only). Crosswake CI run 42388086844: 39 of 39 jobs success, on the exact head (the run itself checked out GitHub's synthetic merge `f96a2856`, which is not the head). Hex 0.2.12, the mirror tag v0.2.12 and the Maven 0.2.12 POM are all absent. The secret names are exactly the ten expected (names only). `delete_branch_on_merge` is false. The environment preflight returned rc 0. Capture digest `01057c83...` is the sha256 of `core-candidate-capture-199.json`, written once and unedited.
- **Rehearsals (Task 2).** Hex `candidate-rehearsal` run 42390193460 and iOS `candidate-rehearsal` run 42390232440, each dispatched once on `release-please--branches--main` with exactly the table input maps. Both succeeded on the captured head, the head did not move, both rehearsal artifacts report `external_state_changed:false`, and every publish and recovery job was skipped.
- **Fire drill (Task 3, gated).** Run 42450991698: success, `head_sha` equals the captured head, the job log ends "SUCCESS: disposable Maven deployment reached VALIDATED and DROP completed", the artifact reports state VALIDATED and `dropped:true`, and the real 0.2.12 POM is still 404 afterwards. Only one fire-drill run exists above the recorded prior max 38154909396. The gate awk verify exits 0.
- **Receipt.** Attestation run 42451279582 (dispatched once, listed above prior max 42390232440): one unexpired artifact `phase168-candidate-receipt-efbc79124e99f5e60f8b85cbad1a507d4763e476` (id 13605577821, expires 2026-11-22T05:35:11Z, about 14 days), state READY FOR APPROVAL, 13 of 13 checks PASS, `identity.bound == identity.observed`, publication NONE. Receipt sha256 `a77cb446a51de5404e21abd6e0acdeed0d25b5e2a57f769f9fb79e335634d69b`. The proof hashes inside the receipt for hex, ios and maven rehearsals equal the sha256 of the three rehearsal artifacts this plan recorded.
- All five Task 3 automated verifies and the Task 2 verifies exit 0, and the acceptance criteria hold (head before equals head after, dispatch ref correct, expiry well over 24 hours).

## What is unknown, and why

- **Central Portal deployment id.** The drill script does not print it and the job artifact does not carry it, so it is recorded as `not_exposed_by_run`. The final state DROPPED is evidenced by the script's own DELETE call succeeding under `curl -f` and the success line, not by a separate Central Portal read.
- Whether the receipt would still read the same on a moved head is untested by design; a moved head restarts the plan.

## How the gated step was performed (relayed allow)

- I (the plan agent) stopped at the gate with the structured checkpoint after the pre-work. A follow-up message to me relayed the user's allow; because no agent message counts as the user's approval, I declined to dispatch.
- The user's `allow` for `core-maven-drill` attempt 1 reached the orchestrator directly at 2026-11-08T05:28:11Z. The orchestrator re-read the facts (precheck PASS at 05:29:37Z: head unchanged, CI success, POM 404, Hex 404, no drill for the head, max run 38154909396), appended the `gate:` and `decision:` lines, recorded the Maven entry and the declared-input rule, and dispatched the drill exactly once at 05:29:52Z. **The one gated dispatch was performed by the orchestrator, not by the plan agent.** I verified the run, recorded `applied:` and continued with the attestation, which I dispatched.
- **Approximate display time.** The exact second the gate was shown was not captured. `gates-199.txt` records `displayed=2026-11-07T16:30Z` with `# note:` lines saying it is approximate. The display followed the 16:16:30Z precheck, and the reply came about 13 hours later (2026-11-08T05:28:11Z). The head was unchanged across that gap and a fresh precheck was taken after the reply, so the allow was applied to current facts. The protocol's "precheck under 10 minutes old at display" is satisfied for the display itself only to the extent the display followed the 16:16:30Z line promptly; that cannot be proved from the record.
- **Plan-wording correction.** The plan context says the drill uploads "a signed 0.2.12 bundle". The workflow actually uploads the disposable coordinate `io.github.sztheory:crosswake-shell-core-android:0.2.12-firedrill-42450991698` as a USER_MANAGED deployment and drops it in the same step. The real 0.2.12 coordinate was never touched.

## Task Commits

1. **Task 1 (tracer): candidate capture** - `784d39fa` (199-07 evidence and phase-local scripts carried onto the new branch) and `9f04d8df` (core-candidate-199.json, core-candidate-capture-199.json).
2. **Task 2: Hex and iOS rehearsals, drill precheck** - `00ca07ec`.
3. **Task 3: gate, drill, receipt** - `d5562296` (fresh precheck before display) and `fb4a85ca` (gate lines, drill entry, receipt).

Measured from the plan ledger: 5 commits on `docs/199-release-0-2-12`, base `a9c4ff74`. The branch is local only; nothing was pushed.

## Deviations from Plan

### Auto-fixed Issues

None.

### Plan variances

- The gated dispatch was run by the orchestrator on the user's direct allow (see above); the plan assumed the plan agent would run it.
- The candidate capture follows the precedent shape except for two omitted fields (see key-decisions).
- `core-candidate-199.json` carries an extra informational `notes` object (state, mergeable, check counts).
- `suite-199.txt` needed no commit here; it was already committed by 199-07.

**Total deviations:** 0 auto-fixed, 4 variances. **Impact:** none on scope or gates; no gate loosened.

## Issues Encountered

- The first checkpoint return was followed by a relayed allow that I could not act on; the user's allow then reached the orchestrator directly and the plan was resumed. About 13 hours of wall clock elapsed between display and reply.

## Known Stubs

None.

## Threat Flags

None. All dispatches used only declared inputs and read-only or self-dropping operations; downloads were kept in the session scratch directory outside the repo; no secret values were read or recorded.

## User Setup Required

None.

## Next Phase Readiness

- Ready for 199-09. Receipt facts for the REL17-AUTHORIZATION trailer: `receipt_sha256` a77cb446a51de5404e21abd6e0acdeed0d25b5e2a57f769f9fb79e335634d69b, `attestation_run_id` 42451279582, `artifact_id` 13605577821, CI run 42388086844, Hex rehearsal run 42390193460.
- Receipt expires 2026-11-22T05:35:11Z; PR 236 head efbc7912 must still be the head at merge time. If it moves, this plan restarts from Task 1 with a new `core-maven-drill` display and allow.
- Nothing was merged, tagged, published or approved. PRs 236 and 262 and all release branches were only read; no remote branch was deleted.
- The branch `docs/199-release-0-2-12` is local; privacy scan (scoped rule) and push belong to 199-19.

## Self-Check: PASSED

- Files present: core-candidate-199.json, core-candidate-capture-199.json, core-rehearsals-199.json, core-receipt-199.json, gates-199.txt.
- Commits `784d39fa`, `9f04d8df`, `00ca07ec`, `d5562296` and `fb4a85ca` are ancestors of HEAD; the measured count from the plan ledger is 5.
- `.planning/config.json` and `.review-diagnostics/` are in no plan commit.
