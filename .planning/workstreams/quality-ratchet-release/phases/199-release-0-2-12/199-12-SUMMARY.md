---
phase: 199-release-0-2-12
plan: 12
subsystem: release
tags: [rel-07, core-ios, ios-mirror, sc3, release-run, halted]

requires:
  - phase: 199-release-0-2-12
    provides: "199-11 Hex and Maven publishes; release run 42494651844 waiting at publish-ios-mirror"
provides:
  - "iOS mirror main and tag v0.2.12 at 095267ea23c94cf397b620ab5015a7bf19377660 under the core-ios allow"
  - "SC3 proven on live data both ways: pre-publish FAIL mirror_tag_missing, post-publish PASS 0.2.12, older 0.2.11 FAIL newer_mirror_tag, parity OK"
  - "The release run's own release-mirror-tag-check job passed for 0.2.12"
  - "Final run record as observed: PARTIAL (iOS public clean-room proof failed)"
affects: [199-13, 199-15, 199-18, 199-19]

plan_head_before: a26ec91e378853270601251998ec877d8e89ad1d
plan_head_after: 897eff9f071131f7fd30a23d3bf8dc2d00d963be
commits: 2

actuals:
  tokens: 50000
  tasks: 3
  commits: 2

tech-stack:
  added: []
  patterns:
    - "SC3 mirror-tag check runs as a recurring release-run job and also as a local live control in both directions"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/core-ios-199.json
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/mirror-tag-0.2.12-199.txt
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/core-run-final-199.json
  modified:
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/gates-199.txt

key-decisions:
  - "The run's non-COMPLETE final state is recorded as observed and nothing was re-run, per the plan's halt rule"

requirements-completed: []

coverage:
  - id: D1
    description: "iOS mirror main and tag v0.2.12 published only after the publish-ios-mirror step's own allow; all three core coordinates now public (SC2)"
    requirement: REL-07
    verification:
      - kind: integration
        ref: "gates-199.txt core-ios awk exits 0; core-ios-199.json; git ls-remote shows mirror main and refs/tags/v0.2.12 both at 095267ea23c9"
        status: pass
    human_judgment: false
  - id: D2
    description: "SC3: mirror tag equals the release version and tree, and the check fails on a mismatch, on live data"
    requirement: REL-07
    verification:
      - kind: integration
        ref: "mirror-tag-0.2.12-199.txt pre rc=1 mirror_tag_missing, post rc=0 PASS, post-older rc=1 newer_mirror_tag, parity rc=0; release-mirror-tag-check job passed with the same PASS line"
        status: pass
    human_judgment: false
  - id: D3
    description: "The whole core release run finishes COMPLETE (linked state COMPLETE, native_core complete, exact-public success)"
    requirement: REL-07
    verification:
      - kind: integration
        ref: "core-run-final-199.json: linked_rollup_state PARTIAL, native_core partial, exact_public skipped; Task 3 first jq verify exits 1"
        status: fail
    human_judgment: false

duration: "about 55 min of work; 49 min between the gate display and the reply"
completed: 2026-11-08
status: complete
halt_resolved: "2026-11-09: the designed stop (release run 42494651844 ended PARTIAL at the iOS clean-room proof) was recovered forward by Phase 200 (0.2.13) and Phase 201 (0.2.14, release run 42713010358, COMPLETE); plans 199-13 to 199-20 were revised for those facts"
---

# Phase 199 Plan 12: iOS mirror gate, SC3 on live data, and the run's final state (HALTED)

**The iOS mirror now carries main and tag `v0.2.12` at `095267ea23c9` under its own allow, and SC3 holds on live data in both directions; but the release run finished PARTIAL because the iOS clean-room proof failed on the public mirror, so the plan's "run COMPLETE" check fails and, by the plan's own rule, the phase halts with REL-07 Pending.**

## What was checked and what happened

- **Task 1 (tracer).** The live pre-publish check ran before the gate: `check_ios_mirror_release_tag.sh --version 0.2.12` printed `verdict=FAIL reason=mirror_tag_missing` and exited 1 (`pre: rc=1`). Precheck `core-ios` PASS at 2026-11-08T16:25:44Z (run 42494651844, environment `publish-ios-mirror` id 26568192607).
- **Task 2, gate `core-ios` attempt 1.** Displayed about 16:26Z; the user answered `allow` at 17:14:20Z, about 49 minutes later, with facts rechecked at reply time. Exactly environment 26568192607 was approved once at 17:14:20Z with the comment `199 core-ios attempt 1`. The job "Mirror iOS core to split repo" succeeded (17:14:23Z to 17:16:27Z). I re-read the mirror: `refs/heads/main` and `refs/tags/v0.2.12` are both `095267ea23c94cf397b620ab5015a7bf19377660`; mirror tree equals source tree `75dcd5039028`. I re-ran the checks myself: `--version 0.2.12` exits 0 PASS; `--version 0.2.11` exits 1 `newer_mirror_tag`; the parity script exits 0 (the mirror carries a `v*` tag for every released `ios-core-v*` tag, 0.2.12 included, so the parity check that was red on open PRs is now green). Task 2's awk verify, the 0.2.12 check and the older-version grep all exit 0, and the `post:`, `parity:` and `pre:` blocks end with `rc=0`, `rc=0` and `rc=1` as required.
- **Task 3, the run's final state (run 42494651844, ended `failure` at about 17:19Z).**
  - Success: approved-candidate merge guard, release approve tag creation, Release Please, Publish to Hex.pm, Publish Android core to Maven Central, Clean-room proof - Android gradle build (16:12:58Z to 16:25:18Z), Mirror iOS core to split repo, **release: ios mirror tag check**, and the failure alert job.
  - **Failure:** Clean-room proof - iOS swift build (job 128802980994), plus the two rollups that depend on it (Native release status rollup and release: linked release rollup).
  - Skipped: the lockstep check, all companion publish and proof jobs, release-as cleanup, and **release: exact-public artifact proof** (it needs the iOS clean-room job).
  - `mirror_tag_check` is `success` and `mirror_tag_check_line` is the real log line `mirror-tag: version 0.2.12 ... mirror_commit 095267ea23c9 mirror_tree 75dcd5039028 newest v0.2.12 verdict=PASS`, matching the local `post:` result. SC3 therefore also holds as the release run's own recurring step.
  - `linked-release-status` artifact: `state: PARTIAL`, `failed_step: ios_public_proof`, child states hex, android, ios_mirror and android_public_proof success, ios_public_proof failed, exact_public skipped, next action `retry_failed_step_from_exact_ref_or_publish_forward_fix`. `native-release-status`: `native_core: partial`, ios publish success, ios proof failure, android proven.
  - `mix crosswake.release.status --live` summary: `status: OK`, live checks enabled, hex, ios-core and android-core live probes ok, `release.live_registry_presence` and `release.candidate_public_truth` OK. It was read from the local branch checkout (cut before the release PR content), so it still reads manifest versions 0.2.11 and describes the 0.2.11 candidate as COMPLETE; it says nothing about the 0.2.12 run.
  - Ledger: no `chore/release-ledger-*` pull request exists, because the record-ledger job did not run (exact-public-proof was skipped). Recorded as `ledger_pr: null` with that reason.
  - The release-failure alert opened issue **#281**. A new open "chore: release main" PR **#280** appeared after the merge; I did not touch either.
- **Plan verifies.** Task 3 first jq verify (`COMPLETE` / `complete` / `success`): **exit 1, fails** (PARTIAL / partial / skipped). Second jq verify (mirror tag check job success with the 0.2.12 PASS line): **exit 0**.

## Cause of the failure (from the job log, not re-run)

In "Build generated iOS application against the public mirror", `xcodebuild` exited 65 with `error: Unable to open base configuration reference file '.../native/ios/crosswake_shell/CrosswakeHostSettings.xcconfig'`. Package resolution of `CrosswakeShellCore` at 0.2.12 from the public mirror succeeded; the failure is in the generated project. The Hex 0.2.12 consumer host generated the shell (`mix crosswake.gen.shell ios --target ...` via `verify_ios_release_host.sh`) without a `CrosswakeHostSettings.xcconfig`, while the project template always references it. From the repo, that file is written by the host-settings generation path (`lib/crosswake/shell/ios_host_generation.ex`), which this script does not appear to use. That reading is a hypothesis from a quick grep, not a diagnosis. The previous release run (0.2.11, run 38170038757) skipped this job, so this is the first time the job ran against a released version in this form.

## What is unknown, and why

- Whether the failure is a defect in the generated-project template, the release-host script, or the clean-room job's setup: only the log line and a grep were read; nothing was reproduced.
- Whether the published 0.2.12 artifacts are themselves wrong: Hex, Maven and the mirror all published and pass their own checks. Only the iOS public build proof failed.

## Deviations from Plan

### Plan variances

1. **Gated actions done by the orchestrator, not this agent.** A plan agent cannot see the user's reply, so the orchestrator displayed `core-ios`, took the user's `allow` after about 49 minutes (facts rechecked at reply time), and made the single approval call. Task 1 was also run by the orchestrator.
2. **Halt on a non-passing post-action verify.** The plan says a run not COMPLETE halts the phase. I recorded the observed state, re-ran nothing, approved nothing, and left REL-07 Pending. I did not treat 199-13 as unlocked in the handoff text (see STATE.md), although the SUMMARY exists and the plan counters advance.

**Total deviations:** 0 auto-fixed, 2 variances. **Impact:** all three core coordinates are public and SC3 holds, but SC2's "run finishes with linked state COMPLETE" does not, and the exact-public proof and release ledger line for 0.2.12 do not exist.

## Open items

- **iOS public clean-room proof failure (blocking REL-07).** Recovery needs a new plan; the runbook path for a failed public proof and the status artifact's next action (`retry_failed_step_from_exact_ref_or_publish_forward_fix`) are the starting points. No job was or may be re-run under a used allow.
- **Misleading next_action text.** `native-release-status` says "Fix MIRROR_DEPLOY_KEY or run the iOS mirror backfill workflow." although the mirror publish succeeded and the failing step is the iOS public proof; do not follow it.
- **Alert issue #281** and **PR 280** (new "chore: release main") are open and untouched. No ledger PR exists for 0.2.12.
- **199-15** (REL-06 clean-room against 0.2.12 with `deferred=none`) will hit the same `:ios_host` area; this finding bears on it.
- **199-19 privacy scope** (carried): 8 retained pre-merge raw source files carry the maintainer noreply email.

## Task Commits

1. **Tasks 1 and 2: pre-publish check, core-ios gate, mirror tag and live SC3 controls** - `c518c9d4`
2. **Task 3: final run record as observed** - `897eff9f`

Measured from the plan ledger (base `a26ec91e`, the parent of `c518c9d4`): 2 commits on `docs/199-release-0-2-12`. Local only; nothing pushed.

## Known Stubs

None.

## Threat Flags

None. One approval named exactly one environment id; no secret values were read or recorded.

## User Setup Required

None.

## Self-Check: FAILED (Task 3 first verify)

- Present: core-ios-199.json, mirror-tag-0.2.12-199.txt, core-run-final-199.json, gates-199.txt lines for core-ios.
- Commits `c518c9d4` and `897eff9f` are ancestors of HEAD; measured count 2.
- Task 1 and Task 2 verifies pass. Task 3 first verify fails because the run is PARTIAL (a true observation, not a recording error); the second verify passes.
- `.planning/config.json` and `.review-diagnostics/` are in no plan commit.

## Halt resolution (2026-11-09)

This plan stopped by design: 0.2.12 published and SC3 was proven live, but the release run ended PARTIAL.
The stop is resolved. Phase 200 shipped the forward fix as 0.2.13 and Phase 201 shipped 0.2.14, whose release run
ended COMPLETE with both clean-room proofs and the exact-public proof passing. Plans 199-13 to 199-20 were revised
for those facts (D-27 to D-30 in 199-DECISIONS.md). The frontmatter `status` changed from `halted` to `complete` so the
dependency graph unblocks them; everything above this section is the original record and is unchanged.
