---
phase: 199-release-0-2-12
plan: 11
subsystem: release
tags: [rel-07, core-hex, core-maven, hex, maven-central, gates]

requires:
  - phase: 199-release-0-2-12
    provides: "199-10 merge commit 1dcdaad8, three source tags, release run 42494651844 waiting at publish-hex"
provides:
  - "crosswake 0.2.12 published to Hex (with docs) under its own allow, with publication record artifact publication-record-crosswake-efbc79124e99f5e60f8b85cbad1a507d4763e476"
  - "io.github.sztheory:crosswake-shell-core-android:0.2.12 published to Maven Central under its own allow, POM and AAR visible"
  - "Release run 42494651844 waiting at publish-ios-mirror only"
affects: [199-12]

plan_head_before: a3ebd40f8b9c65d345865e29198131c0f0f62d23
plan_head_after: c45b612c8783ead2d4e63fa1e9cebc784cfd8450
commits: 2

actuals:
  tokens: 55000
  tasks: 3
  commits: 2

tech-stack:
  added: []
  patterns:
    - "one deployment approval per gate: exactly one environment id with the comment '199 <id> attempt <n>'"
    - "Maven visibility polled once a minute against a 120 minute budget; poll count and first visible time recorded"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/core-hex-199.json
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/core-maven-199.json
  modified:
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/gates-199.txt

key-decisions:
  - "The Hex then Maven order held by the pipeline: Maven's pending approval appeared only after the Hex job succeeded"

requirements-completed: []

coverage:
  - id: D1
    description: "crosswake 0.2.12 is on Hex only after the publish-hex step's own allow, with docs and the publication record artifact (SC2)"
    requirement: REL-07
    verification:
      - kind: integration
        ref: "gates-199.txt core-hex awk exits 0; curl https://hex.pm/api/packages/crosswake/releases/0.2.12 returns version 0.2.12 with has_docs true; artifact publication-record-crosswake-efbc7912... present and unexpired on run 42494651844"
        status: pass
    human_judgment: false
  - id: D2
    description: "Android core 0.2.12 is on Maven Central after Hex and only after the publish-maven step's own allow, POM and AAR visible (SC2, D-02 order)"
    requirement: REL-07
    verification:
      - kind: integration
        ref: "gates-199.txt core-maven awk exits 0; POM and AAR at repo1.maven.org return 200; first visible on poll 11 at 2026-11-08T16:23:26Z"
        status: pass
    human_judgment: false
  - id: D3
    description: "The iOS mirror step is waiting at its own gate when the plan ends"
    requirement: REL-07
    verification:
      - kind: integration
        ref: "pending_deployments of run 42494651844: exactly one, publish-ios-mirror id 26568192607, approvable; mirror tag v0.2.12 absent"
        status: pass
    human_judgment: false

duration: "about 40 min of gate and publish time (15:46Z to 16:24Z)"
completed: 2026-11-08
status: complete
---

# Phase 199 Plan 11: Core Hex and Maven publishes Summary

**crosswake 0.2.12 is live on Hex with docs and io.github.sztheory:crosswake-shell-core-android:0.2.12 is live on Maven Central, each published only after its own one-use allow and in Hex-then-Maven order; the release run now waits at the iOS mirror gate with nothing else started.**

## What was checked and what happened

- **Task 1 (tracer).** Precheck `core-hex` PASS at 2026-11-08T15:46:26Z: run 42494651844, environment `publish-hex` id 26568191797 pending and approvable, Hex 0.2.12 returned 404.
- **Task 2, gate `core-hex` attempt 1.** Displayed about 15:47Z; the user answered `allow`; exactly environment 26568191797 was approved once at 15:48:32Z with the comment `199 core-hex attempt 1`. The job "Publish to Hex.pm" succeeded (15:48:34Z to 16:03:33Z, about 15 minutes against a 30 minute job limit). I re-read hex.pm: crosswake 0.2.12 is listed with docs (inserted 16:03:26Z), and the artifact `publication-record-crosswake-efbc79124e99f5e60f8b85cbad1a507d4763e476` exists and is unexpired.
- **Task 3, gate `core-maven` attempt 1.** Precheck PASS at 16:04:13Z (Hex 200, POM 404, one pending, `publish-maven` id 26568192162). Displayed about 16:05Z; the user answered `allow`; exactly environment 26568192162 was approved once at 16:10:01Z with the comment `199 core-maven attempt 1`. The job "Publish Android core to Maven Central" succeeded (16:10:04Z to 16:12:55Z). The POM and AAR first appeared on poll 11 at 16:23:26Z (one poll a minute, 120 minute budget). I re-read both URLs: POM 200 and AAR 200.
- **Run state now.** Run 42494651844 is `waiting`. The only pending deployment is `publish-ios-mirror` (id 26568192607, approvable). The "Clean-room proof - Android gradle build" job was still in progress when I last read it, so its result is not part of this plan's claims. The mirror tag `v0.2.12` does not exist yet.
- **Plan verifies, re-run by me.** Task 1 grep exits 0; the `core-hex` and `core-maven` gate-order awk checks each exit 0; the Hex curl plus `jq` check exits 0; the Maven POM check exits 0.

## What is unknown, and why

- Whether the Android clean-room proof job passes: it was still running at the last read, and the plan does not depend on it.
- Maven Central propagation was observed as visible, but this plan does not verify the published artifact contents; later plans (REL-06 against 0.2.12, and the post-publish checks) do that.

## Deviations from Plan

### Plan variances

1. **The gated actions were done by the orchestrator, not this plan agent.** A plan agent cannot see the user's replies, so the orchestrator displayed each gate, received the user's `allow`, rechecked facts at reply time and made each approval call once. The user's `allow` answers went only to the orchestrator.
2. **Bare `allow` while Hex was running.** The user once typed a plain `allow` while the Hex job was already running. The orchestrator did not treat it as approval for the not-yet-displayed Maven gate; Maven was displayed on its own precheck and answered separately.
3. **Hex publish took 15 minutes in the single guarded step** (the job limit is 30), inside the limit; no retry or re-approval was needed.

**Total deviations:** 0 auto-fixed, 3 variances. **Impact:** none on scope or order. One approval per gate, no re-run, no re-approval.

## Order held

The pipeline enforced Hex, then Maven: Maven's pending approval appeared only after the Hex job succeeded (`pending_after` in `core-hex-199.json` lists `publish-maven` only), and the iOS mirror's approval appeared only after Maven succeeded (`pending_after` in `core-maven-199.json` lists `publish-ios-mirror` only).

## Expected red check

The mirror parity check on open PRs (for example PR 262) stays red until the iOS gate (`core-ios`) creates the mirror tag `v0.2.12`.

## Task Commits

1. **Task 1 (tracer) and Task 2: core-hex precheck, gate and publication** - `470e5fd6`
2. **Task 3: core-maven precheck, gate and publication** - `c45b612c`

Measured from the plan ledger (base `a3ebd40f`, the parent of `470e5fd6`): 2 commits on `docs/199-release-0-2-12`. Local only; nothing pushed.

## Known Stubs

None.

## Threat Flags

None. Each approval named exactly one environment id; no secret values were read or recorded.

## User Setup Required

None.

## Next Phase Readiness

- Ready for 199-12, the `core-ios` gate. The run waits at `publish-ios-mirror` (id 26568192607). The gate must re-read the run, the pending deployment and that mirror tag `v0.2.12` is absent before display, and should note the Android clean-room job result.
- REL-07 stays Pending: the iOS mirror, companions and closeout remain.

## Self-Check: PASSED

- Files present: gates-199.txt, core-hex-199.json, core-maven-199.json.
- Commits `470e5fd6` and `c45b612c` are ancestors of HEAD; the measured count from the ledger base is 2.
- Live re-read: Hex 0.2.12 200 with docs; Maven POM and AAR 200; one pending deployment (`publish-ios-mirror`); mirror tag `v0.2.12` absent.
- `.planning/config.json` and `.review-diagnostics/` are in no plan commit.
