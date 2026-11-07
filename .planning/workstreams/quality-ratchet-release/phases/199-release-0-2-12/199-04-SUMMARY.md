---
phase: 199-release-0-2-12
plan: 04
subsystem: release
tags: [github-environments, release-gates, release-please, scanner, exunit, actionlint]

requires:
  - phase: 199-release-0-2-12
    provides: "199-03 four live approval environments and the fail-closed preflight; D-01 and D-02 in 199-DECISIONS.md"
provides:
  - "environment keys on all eight publishers: publish-hex x6 (core Hex plus five companions), publish-maven, publish-ios-mirror"
  - "core run chained Hex, then Maven, then the iOS mirror, each link a needs edge plus an explicit success condition"
  - "five scanner checks release.gate.publish_hex_environment, publish_maven_environment, publish_ios_mirror_environment, companion_environments, core_order (roster 99 to 104)"
  - "199-EVIDENCE/gates-wiring-199.txt publishers block (199-05 appends the tag gate)"
affects: [199-05, 199-07, 199-10, 199-11, 199-12, 199-13, 199-14]

plan_head_before: f97da47407ff76095c467d396c3ec74798acd209
plan_head_after: 1e4f6adea261de7672c1f6f53b3b98ad9d0eb88c

actuals:
  tokens: 5600
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "environment value read as a plain string or a map with name, so either YAML form is pinned"
    - "no status-check function (always, success, failure, cancelled) on any publisher if:, scanner-enforced"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/gates-wiring-199.txt
  modified:
    - .github/workflows/release-please.yml
    - script/check_release_workflow_integrity.exs
    - test/crosswake/proof/phase199_release_gates_test.exs
    - test/crosswake/release_candidate/workflow_test.exs

key-decisions:
  - "The iOS mirror waits only on publish-android-core (not on publish-hex directly); the scanner pins that, so the chain is Hex, Maven, iOS and a held gate leaves every later job skipped"
  - "Two existing scanner pins whose old posture D-01 and D-02 supersede were rewritten to the new truth with the same strictness, not removed"

requirements-completed: []

coverage:
  - id: D1
    description: "Every publisher job waits for its own approval environment (publish-hex x6, publish-maven, publish-ios-mirror)"
    requirement: REL-07
    verification:
      - kind: unit
        ref: "elixir script/check_release_workflow_integrity.exs -> DONE: 104 of 104 roster checks emitted; 0 failed."
        status: pass
      - kind: other
        ref: "grep -c 'environment:' .github/workflows/release-please.yml -> 8; grep -c 'environment: publish-hex' -> 6; actionlint exit 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "Core publishers are chained Hex, then Maven, then the iOS mirror with success conditions and no status-check function"
    requirement: REL-07
    verification:
      - kind: unit
        ref: "bash script/mix_test_gate.sh --min 12 -- test/crosswake/proof/phase199_release_gates_test.exs (13 ran, 0 failures; two core_order mutations)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every release-related suite passes on the gated workflow"
    requirement: REL-07
    verification:
      - kind: unit
        ref: "bash script/mix_test_gate.sh --min 100 -- test/crosswake/proof test/crosswake/release_candidate test/crosswake/planning/release_please_config_test.exs test/mix/tasks/crosswake_release_status_test.exs (1113 ran, 0 failures)"
        status: pass
    human_judgment: false
  - id: D4
    description: "A real release run pauses at each publisher environment on a hosted runner"
    requirement: REL-07
    verification: []
    human_judgment: true
    rationale: "Only a real workflow run on GitHub shows the pause and the reviewer approval; plans 199-07 (proposal run) and 199-11 to 199-14 (gated publishes) exercise it. Nothing here dispatched a run."

duration: "about 19 min (13:44Z to 14:03Z, 2026-11-07), most of it two 5-minute release-suite runs"
completed: 2026-11-07
status: complete
---

# Phase 199 Plan 04: Publisher Approval Environments and Core Order Summary

**All eight publisher jobs now wait for an approval environment, and the core run is chained Hex, then Maven, then the iOS mirror; five scanner checks and nine new tests keep each gate from being removed silently.**

## What was checked

- Before the edit: scanner at 99 of 99 (the 199-03 baseline).
- After each task: scanner 100, then 104 of 104 with 0 failed; `actionlint` exit 0; `grep -c 'environment:'` prints 8 and `grep -c 'environment: publish-hex'` prints 6.
- `git diff f97da474 -- .github/workflows/release-please.yml` shows only `environment:`, `needs:` and `if:` lines on eight publisher jobs. No `run:` line, REL-17 evidence call, receipt check or guard text changed. No `if:` gained `always()` or any status-check function; the new conditions are `needs.<job>.result == 'success'`.
- phase199 mutation file: 13 tests, 0 failures (floor 12). Each new check has a seeded mutation that turns the scanner red by check id.
- Release suites (proof, release_candidate, release-please config, release status): 1113 ran, 0 failures, after the one fix below.

## What is unknown, and why

- Whether GitHub pauses each publisher at its environment exactly as intended on a hosted runner. Static checks and the scanner prove the wiring is present; only a real run shows the pause. Plan 199-07 records the first proposal-run result; the gated publishes in 199-11 to 199-14 are the first real exercise. Nothing was dispatched here.
- One behavior to know when reading a held run: a job whose `needs` result is skipped does not run. Because the iOS mirror now needs Maven, which needs Hex, a held or failed Hex or Maven publish leaves the iOS mirror skipped; the rollups record the partial state. That is the intended D-02 outcome and is stated in the plan.

## Task Commits

1. **Task 1: Tracer, publish-hex behind its environment with scanner check and mutations** - `8e8746d2` (ci)
2. **Task 2: Maven and iOS gates in the D-02 order, and the companion gates** - `89a74346` (ci)
3. **Task 3: Release-suite fix and the publisher wiring record** - `1e4f6ade` (docs)

**Plan metadata:** committed after this file (docs: complete plan).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `release.approval.linked_graph` pinned the old "no environment key" posture**
- **Found during:** Task 1 (first scanner run after adding `environment: publish-hex`)
- **Issue:** the check required `not includes?(block, "environment:")` on the three core publishers, which is the opposite of D-01.
- **Fix:** replaced that conjunct with an exact per-job environment (`publish-hex`, `publish-ios-mirror`, `publish-maven`) via the new `job_environment/2` helper. It is stricter than before, not weaker: a missing or wrong environment now fails it. In the Task 1 commit the iOS and Maven entries still expected "" because only Hex was gated yet; Task 2 flipped them.
- **Files modified:** script/check_release_workflow_integrity.exs
- **Committed in:** `8e8746d2`, `89a74346`

**2. [Rule 1 - Bug] `release.ios.independent_publication` forbade the D-02 chain**
- **Found during:** Task 2
- **Issue:** the check required `publish-ios-core` NOT to need `publish-android-core`, so the planned order made it fail.
- **Fix:** it now requires `publish-ios-core` to need `publish-android-core` and still forbids a direct need on `publish-hex`; the detail text names D-02. The plan's rule is "adjust only the new wiring, never weaken an existing check". This pin directly contradicted the behavior table, so the wiring could not be adjusted around it; I kept the check and changed its truth value, and flag it here so the orchestrator can review.
- **Files modified:** script/check_release_workflow_integrity.exs
- **Committed in:** `89a74346`

**3. [Rule 1 - Bug] `workflow_test.exs` refuted `environment:` on the three core publishers**
- **Found during:** Task 3 (release-suite run: 1 failure in 1113)
- **Fix:** the assertion is now an exact `environment: <name>` per core publisher.
- **Files modified:** test/crosswake/release_candidate/workflow_test.exs
- **Committed in:** `1e4f6ade`

**4. [Plan variance] 13 tests in the phase199 file, not 12.** The file already held 4 tests from 199-03 (the plan counted 3), and this plan added 9. Floor 12 holds.

---

**Total deviations:** 3 auto-fixed pins (Rule 1), 1 count variance. **Impact:** none on scope; two of the three were forced by D-01 and D-02 themselves.

## Issues Encountered

None beyond the deviations above.

## Known Stubs

None.

## Threat Flags

None. The edit adds `environment:` and `needs:` keys only; no new endpoint, credential path or file access.

## User Setup Required

None.

## Next Phase Readiness

- Ready for 199-05 (tag gate); it appends its block to `gates-wiring-199.txt`.
- REL-07 is not complete (later plans finish it).
- `ci/199-release-gates` is not pushed; main is unchanged. Nothing was merged, tagged, published or dispatched.

## Self-Check: PASSED

- Files present: gates-wiring-199.txt, this file, and the four modified files listed above.
- Commits `8e8746d2`, `89a74346`, `1e4f6ade` are on `ci/199-release-gates`; the measured count from the plan ledger is 3.
- Re-ran at close: scanner 104 of 104, phase199 gate 13 ran 0 failures, actionlint 0, `environment:` count 8, `.planning/config.json` in no plan commit.
