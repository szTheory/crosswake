---
phase: 201-fix-the-exact-public-companion-digest-proof-so-a-release-run
plan: 05
subsystem: release-candidate
tags: [release-candidate, rehearsal, fire-drill, receipt, core-maven-drill, gate, release-0.2.14, build_env]

requires:
  - phase: 201-fix-the-exact-public-companion-digest-proof-so-a-release-run
    provides: "201-04 companions-only fix merged as PR 287 (merge fdc218f9) and the 201-02 standing approvals (PR 284, merge 44e2f69b)"
provides:
  - "release PR 283 (0.2.14) pinned at head 407398160bb5 on base fdc218f9, containing both merges, CI 39 of 39 green with the default-iOS build-gate PASS line"
  - "Hex and iOS candidate rehearsals on that head, no external state change"
  - "one Maven fire drill behind its own core-maven-drill allow, validated then dropped, real 0.2.14 POM still 404"
  - "one READY FOR APPROVAL receipt (13 of 13 checks, publication NONE, expires 2026-11-23) and the core candidate's builder Hex (2.7.0)"
affects: [201-06, 201-07, 201-08]

actuals:
  tokens: 21000
  tasks: 3
  commits: 3

plan_head_before: 6fc69b3e466a8b509a7838c7b3a108fe6b9aebff
plan_head_after: 26cf54ec3cd6281939f35193a0c91a2f1e3fea36
# commits: MEASURED from the ledger (git rev-list --count 6fc69b3e..HEAD, taken before this summary commit):
# c92f2d73, de696f9e, 26cf54ec, all on the local docs branch docs/199-release-0-2-12. This summary and tracking commit follow.
pr: 283
candidate_head: 407398160bb5761d90ade7182676dd76691617be
candidate_base: fdc218f94851676b925c4e3042e3567baf5b8391
candidate_tree: 16aca5ebc43d52ed69e32feb55f683218540ad29
ci_run_id: 42703531929
ci_ran_on: a53bf4af8b42d9154f0b5838fd835e98e9ecfa61
fix_merge_oid: fdc218f94851676b925c4e3042e3567baf5b8391
approvals_merge_oid: 44e2f69b09afded59088e7b7a891b248a9a068a6
hex_latest: 2.7.0
hex_rehearsal_run: 42706539601
ios_rehearsal_run: 42706550754
maven_drill_run: 42707774197
attestation_run_id: 42708405663
receipt_artifact_id: 13715575685
receipt_sha256: aecf5b14bb3e1aa91705bee3b28eb10f263ca3c49eea2f89cae2e962b96ba5d8
receipt_expires_at: 2026-11-23T22:05:52Z

tech-stack:
  added: []
  patterns:
    - "bounded read-only poll (2 min, 30 reads) before capture; capture only after both merges are in the head's ancestry"
    - "declared-input rule read against origin/main workflow files before every dispatch; prior max run id recorded first"
    - "one wait: line per dispatched run under its named bound, written by a script that only reads"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/candidate-201.json
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/candidate-capture-201.json
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/candidate-poll-201.txt
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/rehearsals-201.json
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/receipt-201.json
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/gates-201.txt
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/gate-order-controls-201.txt
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/waits-201.txt
  modified: []

key-decisions:
  - "The core candidate's builder Hex is read from the Hex candidate-rehearsal run's six artifact-provenance lines (the run the receipt binds as hex_run_id), because the attestation run's own log carries none; recorded as a plan variance"
  - "receipt_sha256 is the sha256 of candidate-receipt.json inside the receipt artifact (the .md sibling is recorded separately as receipt_md_sha256)"

requirements-completed: [REL-08, REL-09]

coverage:
  - id: D1
    description: "0.2.14 candidate pinned after a bounded READY poll on a head that contains the build_env fix and the PR 284 approvals; CI green on that exact head including the default-iOS build gate; predicate PASS; targets absent"
    requirement: REL-08
    verification:
      - kind: other
        ref: "candidate-201.json: three Task 1 verifies exit 0; CI run 42703531929 39 of 39; phase79-ios-proof line control=detected verdict=PASS; poll READY reads=2 minutes=2"
        status: pass
    human_judgment: false
  - id: D2
    description: "Hex and iOS rehearsals on the exact head changed no external state, each dispatched once with the declared inputs and waited on under 45 minutes"
    requirement: REL-09
    verification:
      - kind: integration
        ref: "rehearsals-201.json: runs 42706539601 and 42706550754 success, external_state_changed false; waits-201.txt rehearsal-hex and rehearsal-ios DONE"
        status: pass
    human_judgment: false
  - id: D3
    description: "Maven fire drill ran once behind the user's core-maven-drill allow for this head, validated then dropped, real POM still 404"
    requirement: REL-09
    verification:
      - kind: integration
        ref: "gate-order-200.awk exit 0; run 42707774197 success, state VALIDATED, dropped true, one run above prior max 42632645093; pom 404"
        status: pass
    human_judgment: false
  - id: D4
    description: "One unexpired READY FOR APPROVAL receipt, publication NONE, bound to the head, tree, base, CI run and the three rehearsal runs, with the core candidate built by Hex 2.7.0 (equal to hex_latest at capture and at dispatch)"
    requirement: REL-09
    verification:
      - kind: integration
        ref: "receipt-201.json: run 42708405663, artifact 13715575685, 13 of 13 checks, identity bound equals observed, six provenance lines with only the core digesting build_env"
        status: pass
    human_judgment: false

duration: "about 45 min of agent work on 2026-11-09 (21:31Z to 22:08Z, plus waiting for the relayed allow)"
completed: 2026-11-09
status: complete
---

# Phase 201 Plan 05: 0.2.14 candidate captured, rehearsed and receipted Summary

**Release PR 283 (0.2.14, head `40739816`, base `fdc218f9` = the fix merge) was pinned after a two-read bounded poll showed it carried both the build_env fix and the standing approvals; Crosswake CI was green on that exact head including the default-iOS build gate, the Hex and iOS rehearsals changed nothing, one Maven fire drill ran behind the user's `core-maven-drill` allow and was dropped with the real 0.2.14 POM still 404, and the hosted attestation produced one READY FOR APPROVAL receipt (13 of 13 checks, publication NONE, expires 2026-11-23) for a core candidate built by Hex 2.7.0.**

## What was checked and what happened

- **Candidate (Task 1).** I polled PR 283 read-only every 2 minutes. At 21:32:38Z it was still on the stale head `1068230b` and base `0aa18470`, with neither merge in its ancestry. At 21:34:40Z Release Please had refreshed it to head `407398160bb5761d90ade7182676dd76691617be`, base `fdc218f94851676b925c4e3042e3567baf5b8391` (equal to origin/main), and both the fix merge (PR 287) and the approvals merge (PR 284, `44e2f69b`) were ancestors. READY after 2 reads and 2 minutes. Nothing was written to the release branch. Crosswake CI run 42703531929 passed 39 of 39 jobs on that exact head (created 21:32:57Z, done about 21:49Z). **CI checked out the synthetic merge commit `a53bf4af8b42d9154f0b5838fd835e98e9ecfa61`, not the head.** Its `phase79-ios-proof` log carries `default-ios-build: mode=local project=generated generator=a53bf4af... generator_dirty=no ... build_rc=0 build_seconds=20 control_rc=65 control=detected verdict=PASS first_error=none`. The release-PR-head predicate exited 0 (`commits=1 paths=10 managed=13 verdict=PASS`). Hex 0.2.14, the Maven 0.2.14 POM, mirror tag `v0.2.14` and the three source tags are absent; the ten secret names match exactly (names only); `deleteBranchOnMerge` is false; the environment preflight returned 0. `hex_latest` is 2.7.0, a measured version. The capture digest `d2827cd4...` is the sha256 of the capture file, written once.
- **Controls and rehearsals (Task 2).** The gate-order controls passed 53 of 53 before any gate. Hex `candidate-rehearsal` run 42706539601 and iOS `candidate-rehearsal` run 42706550754 were each dispatched once on `release-please--branches--main` with the declared inputs, after recording the prior max run ids. Both succeeded on the captured head, the head did not move, both artifacts report `external_state_changed:false`, and every publish and recovery job was skipped. Each wait took 2 reads, DONE, against the 45-minute bound.
- **Fire drill (Task 3, gated).** The user's `allow` for `core-maven-drill` attempt 1 reached the orchestrator, which wrote the `gate:`, the reply-time `precheck:` and the `decision:` lines and made the one dispatch (about 22:00Z). `gates-201.txt` holds, in protocol order: display-time PASS precheck 21:55:26Z, `gate:` displayed 21:56:16Z, reply-time PASS precheck 22:00:02Z, `decision: ... allow` 22:00:03Z, then my `applied: ... result=validated_then_dropped` at 22:03:27Z. The gate-order awk check exits 0. Drill run 42707774197: success, `head_sha` equals the captured head, the log ends "SUCCESS: disposable Maven deployment reached VALIDATED and DROP completed", the artifact says state VALIDATED and `dropped:true`, the disposable coordinate is `0.2.14-firedrill-42707774197`, and the real 0.2.14 POM (and Hex 0.2.14) are still 404. Exactly one drill run exists above the prior max 42632645093. The wait (`drill-maven`, 120-minute bound) took 2 reads.
- **Receipt and Hex binding.** Hex latest was re-read immediately before the attestation dispatch: v2.7.0, equal to the captured `hex_latest`. Attestation run 42708405663 (one successful dispatch, prior max 42706550754) produced exactly one unexpired artifact `phase168-candidate-receipt-407398160bb5...` (id 13715575685, expires 2026-11-23T22:05:52Z, about 335 hours ahead). State READY FOR APPROVAL, 13 of 13 checks PASS, `identity.bound == identity.observed`, publication NONE (`external_state.changed:false`). The receipt's rehearsal proof hashes equal the sha256 of the three rehearsal artifacts I recorded. The six `artifact-provenance:` lines show `build_env_hex=2.7.0` for all six packages and `build_env_digested=yes` only for `crosswake` (the core), `no` for the five companions: the fixed rule is what the Artifact ran on this head.
- All verifies exit 0: Task 1 (three), Task 2 (four), Task 3 (gate-order awk, Maven entry, receipt, waits, the four-record declared-input loop counting 4, attestation input map equal to the table). The acceptance checks hold: no drill run above the prior max at the end of Task 2; no line in `gates-201.txt` names the 0.2.13 head `5a6a7521...` (grep prints 0); `expires_at` is more than 48 hours ahead; the PR head still equals `head_oid`.

## What is unknown, and why

- **Central Portal deployment id.** The drill script does not print it, so it is recorded as `not_exposed_by_run` (same as 0.2.13). DROPPED is evidenced by the script's DELETE succeeding under `curl -f`, the success line and the artifact.
- **Whether the release run will still see Hex 2.7.0.** The core's `build_env` digest depends on the builder Hex. This plan recorded 2.7.0 at capture, at dispatch and in the candidate's provenance; Plan 07's core-merge and core-hex prechecks must re-read it and stop if it moved.
- **Whether the exact-public proof passes live.** The fixed rule is measured on the real 0.2.13 family (201-04) and its provenance now appears on this candidate, but the first live proof is the 0.2.14 release run itself (Plan 07).

## How the gated step was performed (relayed allow)

The plan agent cannot see the user's reply. I stopped at the gate after Task 2 with the structured checkpoint. The orchestrator relayed the user's plain-language `allow`, wrote the three gate lines and made the one drill dispatch; I verified the run read-only, wrote `applied:`, completed the Maven entry, then did the ungated attestation (it reads and attests; publication NONE). Display-to-reply gap about 4 minutes (21:56:16Z to 22:00:03Z). The head did not move.

## Task Commits

1. **Task 1 (tracer): candidate capture** - `c92f2d73`
2. **Task 2: controls, rehearsals, drill precheck** - `de696f9e`
3. **Task 3: gate lines, drill entry, receipt, core Hex binding** - `26cf54ec`

Measured from the plan ledger: 3 commits on `docs/199-release-0-2-12`, base `6fc69b3e`. Nothing was pushed.

## Deviations from Plan

### Auto-fixed Issues

None.

### Plan variances

- **Provenance lines source.** The plan says the attestation run log carries the six `artifact-provenance:` lines and that a missing line stops the plan. The attestation log (run 42708405663) contains none; the lines are printed by the Hex candidate-rehearsal run's log (42706539601), the run the receipt binds as `hex_run_id`, on the same head. I recorded those six lines and the core's `build_env_hex` from that log, with the source named in `receipt-201.json` (`candidate_provenance_source`). The substance of the check (the core candidate is built by `hex_latest`, 2.7.0, and only the core digests `build_env`) holds. I did not stop, because the attestation only reads and the binding is bound to this exact head and run; the orchestrator should decide whether the plan text needs correcting for Plan 07.
- **One rejected dispatch call.** My first `gh workflow run` for the attestation was rejected by GitHub with HTTP 422 (an input name with a leading space, from my own argument quoting). No run was created (the run list above the prior max was empty), so after a new prior-max read I dispatched once more; exactly one attestation run exists above the prior max. Recorded under `attestation_dispatch.first_attempt`.
- **Drill dispatched by the orchestrator**, on the user's relayed allow, not by the plan agent (same as 200-04).
- **Declared-input rule** read the three dispatch workflows from `origin/main` (the docs branch predates the fix, so its `crosswake-ci.yml` differs); the dispatch workflows are byte-identical to the head's.
- **Plan verify lines with `wc -l`** would fail on macOS space padding; I checked the controls file numerically (54 lines: 53 cases plus the verdict) and the plan's own `grep -qxF` line passes.
- `candidate-201.json` carries an extra informational `notes` object; `rehearsals-201.json` and `receipt-201.json` carry extra informational fields (`dispatched_by`, `receipt_sha256_file`, `candidate_provenance_source`).

**Total deviations:** 0 auto-fixed, 6 variances. **Impact:** none on scope or gates; no gate loosened.

## Issues Encountered

None blocking. PR 283 was stale when the plan started; the candidate was taken only after Release Please refreshed it (about 2 minutes later).

## Known Stubs

None.

## Threat Flags

None. All dispatches used only declared inputs and read-only or self-dropping operations; downloads stayed in the session scratch directory outside the repo; no secret values were read or recorded (names only; the secret-shape scan of the capture was clean). Nothing was pushed, merged, tagged or published.

## User Setup Required

None.

## Next Phase Readiness

- Ready for 201-06 / 201-07. Receipt facts for the release steps: `receipt_sha256` aecf5b14bb3e1aa91705bee3b28eb10f263ca3c49eea2f89cae2e962b96ba5d8, `attestation_run_id` 42708405663, `artifact_id` 13715575685, CI run 42703531929, Hex rehearsal run 42706539601, `candidate_core_build_env_hex` 2.7.0.
- The receipt expires 2026-11-23T22:05:52Z. PR 283's head must still be `407398160bb5` at merge time, or this plan restarts from Task 1 with a new `core-maven-drill` display and allow. `hex_latest` must still read 2.7.0 at the core-merge and core-hex prechecks.
- PRs 283, 284 (merged), 279, 262 and all release branches were only read; no remote branch was deleted.

## Self-Check: PASSED

- Files present: candidate-201.json, candidate-capture-201.json, candidate-poll-201.txt, rehearsals-201.json, receipt-201.json, gates-201.txt, gate-order-controls-201.txt, waits-201.txt.
- Commits `c92f2d73`, `de696f9e` and `26cf54ec` are ancestors of HEAD; the measured count from the plan ledger is 3.
- `.planning/config.json`, `.review-diagnostics/` and the phase `.gitkeep` are in no plan commit.
