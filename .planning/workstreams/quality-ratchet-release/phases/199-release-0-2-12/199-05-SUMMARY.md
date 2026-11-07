---
phase: 199-release-0-2-12
plan: 05
subsystem: release
tags: [github-environments, release-gates, release-please, scanner, exunit, actionlint, runbook]

requires:
  - phase: 199-release-0-2-12
    provides: "199-04 publisher approval environments and the D-02 core order; 199-01 check_ios_mirror_release_tag.sh; D-01 and D-04 in 199-DECISIONS.md"
provides:
  - "release-tag-gate job (environment release-tags) and a release-please condition that keeps proposal pushes flowing"
  - "release-mirror-tag-check job: the SC3 mirror tag check as a read-only post-publish step of every iOS release run, paged through release-failure-alert"
  - "scanner checks release.gate.tag_gate and release.gate.mirror_tag_check (roster 104 to 106)"
  - "RELEASE-INCIDENT-RESPONSE.md Per-step approval gates section; COMPANION-PUBLISH-RUNBOOK.md section 7 naming the per-step gates"
  - "gates-wiring-199.txt tag_gate and mirror_tag_check blocks"
affects: [199-07, 199-10, 199-11, 199-12, 199-13, 199-14]

plan_head_before: ba210a354e7ef42e5496a0a67ab128eb80243738
plan_head_after: f159b15e78091243dadcccb5558076d078fb93bc

actuals:
  tokens: 8900
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "a job that must run after a possibly skipped gate starts its if with !cancelled() (never always()) and states which gate results it accepts for which context"
    - "scanner checks parse the if text term by term and name each missing term in the failure detail"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-05-SUMMARY.md
  modified:
    - .github/workflows/release-please.yml
    - script/check_release_workflow_integrity.exs
    - test/crosswake/proof/phase199_release_gates_test.exs
    - test/crosswake/proof/phase175_release_recovery_test.exs
    - test/crosswake/planning/release_please_config_test.exs
    - test/crosswake/guides/release_boundaries_test.exs
    - script/collection_assertion_ledger.json
    - docs/RELEASE-INCIDENT-RESPONSE.md
    - docs/COMPANION-PUBLISH-RUNBOOK.md
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/gates-wiring-199.txt

key-decisions:
  - "release-tag-gate runs only with a non-empty REL-17 context; release-please accepts its skipped result only for an empty context and requires its success otherwise, so an ordinary push still refreshes the release PRs"
  - "release-please uses !cancelled(), never always(): a cancelled run stays cancelled and cannot go on to create tags"
  - "the mirror tag check job is named in lowercase after the release: prefix, because an existing naming test requires it"

requirements-completed: []

coverage:
  - id: D1
    description: "Tag creation waits for the release-tags approval environment in linked and companion runs; proposal pushes still reach Release Please"
    requirement: REL-07
    verification:
      - kind: unit
        ref: "elixir script/check_release_workflow_integrity.exs -> DONE: 106 of 106 roster checks emitted; 0 failed. (release.gate.tag_gate OK)"
        status: pass
      - kind: unit
        ref: "bash script/mix_test_gate.sh --min 21 -- test/crosswake/proof/phase199_release_gates_test.exs (23 ran, 0 failures; five tag-gate mutations)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The iOS mirror tag check runs read-only after every mirror publish and pages through release-failure-alert"
    requirement: REL-07
    verification:
      - kind: unit
        ref: "phase199_release_gates_test.exs five mirror_tag_check mutations (script call, environment key, write permission, publish-ios-core need, alert need); scanner release.gate.mirror_tag_check OK"
        status: pass
      - kind: other
        ref: "actionlint .github/workflows/release-please.yml exit 0; grep -c 'environment:' prints 9"
        status: pass
    human_judgment: false
  - id: D3
    description: "Both runbooks describe the per-step gates and the old single-approval wording is refuted by test"
    requirement: REL-07
    verification:
      - kind: unit
        ref: "test/crosswake/guides/release_boundaries_test.exs (both rewritten tests pass); grep -c 'single approval boundary' docs/COMPANION-PUBLISH-RUNBOOK.md prints 0"
        status: pass
    human_judgment: false
  - id: D4
    description: "A real run pauses at release-tags, a proposal push still refreshes the release PRs, and a real iOS release run executes the mirror tag check"
    requirement: REL-07
    verification: []
    human_judgment: true
    rationale: "Only a real workflow run on GitHub shows the pause and the skipped-gate behavior; 199-07 observes a proposal run and 199-11 to 199-14 exercise the gated release. Nothing was dispatched here."

duration: "about 43 min (14:05Z to 14:49Z, 2026-11-07), most of it three 9-minute release-suite runs"
completed: 2026-11-07
status: complete
---

# Phase 199 Plan 05: Tag Gate, Per-Step Runbooks and Mirror Tag Check Summary

**Release Please now waits for a `release-tags` approval before creating tags (ordinary pushes still reach it through a `!cancelled()` condition), both runbooks describe the per-step gates, and every iOS mirror publish is followed by a read-only mirror tag check that pages through the failure alert.**

## What was checked

- Scanner: 104 of 104 before; 105 of 105 after Task 1; 106 of 106 after Task 3, 0 failed each time.
- phase199 mutation file: 23 tests, 0 failures (floor 21). Five tag-gate mutations (need on the gate dropped, gate-success dropped so a non-empty context accepts a skipped gate, `!cancelled()` dropped, `!cancelled()` swapped for `always()`, guard-success dropped) and five mirror-tag-check mutations (script call deleted, `environment: publish-ios-mirror` added, `contents: write`, `publish-ios-core` need dropped, alert need dropped) each turn the scanner red by check id.
- `actionlint` exit 0; `grep -c 'environment:'` prints 9 (the new job adds none).
- Region checks: `release-please` block has no `always()`; `release-tag-gate` has no `secrets.`, one `contents: read`, no `: write`; `release-mirror-tag-check` has the script call exactly once, no environment, no secret or write, one `contents: read`; the alert block mentions the new job twice.
- Release suites on the final tree: 1206 total, 1139 ran, 1 failure, a 60000 ms ExUnit timeout in `phase161_1_navigation_gate_integrity_test.exs` under full-suite load. The same file alone: 2 ran, 0 failures. It passed in the first full run and this plan does not touch it. Everything else passed, including the phase169 name test and the phase170 ledger tests.
- `elixir script/inventory_collection_assertions.exs --check` prints OK for 290 sites.

## What is unknown, and why

- Whether GitHub skips the gate on a proposal push and still runs Release Please exactly as the expression says, and whether the run pauses at `release-tags`. Static checks prove the wiring; only a real run shows it. 199-07 observes a proposal push; 199-11 to 199-14 exercise the gated release. Nothing was dispatched.
- Whether `release-mirror-tag-check` passes on a real hosted runner (the script was proven locally in 199-01 against the real 0.2.11 mirror; this job is its first CI exercise, in the first iOS release run).
- The one-off timeout above is attributed to load because it passes alone and earlier; I did not find a code cause.

## Task Commits

1. **Task 1: Tag gate, release-please condition, scanner check and mutations** - `941d115b` (ci)
2. **Task 2: Runbooks, per-step pins, ledger refresh and tag_gate record** - `465ec532` (docs)
3. **Task 3: Mirror tag check job, alert wiring, scanner check, mutations and record** - `f159b15e` (ci)

**Plan metadata:** committed after this file (docs: complete plan).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Three existing pins on release-please's old `if` rewritten to the new truth**
- **Found during:** Task 1
- **Issue:** the plan's required condition changes `if: ${{ github.event_name == 'push' }}`, which three existing checks pinned verbatim: scanner `maven_fire_drill_isolated` (exact equality), the phase175 "manual dispatch cannot run the Release Please proposal job" mutation (replace raises on a no-op), and `release_please_config_test.exs` (equality).
- **Fix:** none was removed or loosened to a weaker intent. The scanner now requires the condition to start with `!cancelled() && github.event_name == 'push' &&` and refutes `always(` and `workflow_dispatch`; the phase175 mutation now removes the whole push term and swaps in `always()`, which the scanner still catches; the config test asserts the same prefix and refutes `always(` and `workflow_dispatch`. The push-only guarantee is therefore still pinned, and `release.gate.tag_gate` pins the rest of the expression.
- **Files modified:** script/check_release_workflow_integrity.exs, test/crosswake/proof/phase175_release_recovery_test.exs, test/crosswake/planning/release_please_config_test.exs
- **Committed in:** `941d115b`

**2. [Rule 1 - Bug] Collection-assertion ledger display lines drifted**
- **Found during:** Task 2 (release-suite run: 5 failures in phase170 guard-match and ledger tests)
- **Issue:** the plan's edits to `release_boundaries_test.exs` moved three ledger-tracked rows (lines 129, 188, 700); the ledger and the guard test key off display lines.
- **Fix:** regenerated `script/collection_assertion_ledger.json` with `elixir script/inventory_collection_assertions.exs --emit-snapshot`. Only the display lines of those three rows changed (3 insertions, 3 deletions); `--check` prints OK for 290 sites. This follows the precedent of commits ec3a38b8 and e9f39321.
- **Files modified:** script/collection_assertion_ledger.json
- **Committed in:** `465ec532`

**3. [Rule 1 - Bug] The plan's job name violates an existing naming test**
- **Found during:** Task 3 (release-suite run: 1 failure, phase169 "every 'release: ' prefixed job display name is lowercase after the prefix")
- **Issue:** the plan specified `name: "release: iOS mirror tag check"`; the existing test requires lowercase after `release: `.
- **Fix:** the job is named `"release: ios mirror tag check"`. The test was not changed. The orchestrator may want to correct the plan text.
- **Files modified:** .github/workflows/release-please.yml
- **Committed in:** `f159b15e`

**4. [Plan variance] Counts**
- The phase199 file held 13 tests before this plan, not 12. This plan added 5 tag-gate tests (the plan listed four; I added the `always()` swap as a separate control, because the plan's prohibition on `always()` deserves its own negative control) and 5 mirror tests, giving 23. The floors (16, then 21) hold. Roster sizes 105 and 106 match.
- The three replacements in `release_boundaries_test.exs` are as the plan asked: (a) in "publish runbook keeps candidate evaluation reversible until exact-head approval", `assert runbook =~ "single approval boundary"` became `assert runbook =~ "first of several one-use approval gates"` plus `refute runbook =~ "single approval boundary"`; (b) the test "candidate runbook fixes the seven-step sequence and single approval boundary" was renamed "... and per-step approval gates"; (c) its count-of-one assertion on `approval boundary` became an exact count of one for the new gate sentence, plus assertions that section 7 names `release-tags` and `publish-hex` and that the old phrase is gone. These are pins on the new truth, not weakened checks.

---

**Total deviations:** 3 auto-fixed (Rule 1) and 1 count variance. **Impact:** no scope change. No existing check was removed or weakened; three pins were rewritten to the new truth with the same push-only strictness (item 1), one ledger was mechanically refreshed (item 2), and one name deviates from the plan text to satisfy an existing test (item 3).

## Issues Encountered

- The flaky timeout in `phase161_1_navigation_gate_integrity_test.exs` (see What was checked). Not fixed; out of scope, and it passes alone.

## Known Stubs

None.

## Threat Flags

None. The tag gate has no checkout and no secret; the mirror check job reads the public mirror anonymously with `contents: read` and `persist-credentials: false`. No new endpoint, credential path or write scope.

## User Setup Required

None.

## Next Phase Readiness

- Ready for 199-06. REL-07 is not complete (later plans finish it).
- `ci/199-release-gates` is not pushed; main is unchanged. Nothing was merged, tagged, published or dispatched.
- Note for 199-07: on a proposal push the gate is skipped and downstream jobs without a status-check function are skipped by design; observe that Release Please still runs.

## Self-Check: PASSED

- Files present: this file, gates-wiring-199.txt, and the modified files listed above.
- Commits `941d115b`, `465ec532`, `f159b15e` are on `ci/199-release-gates`; the measured count from the plan ledger is 3.
- `.planning/config.json` and `.review-diagnostics/` are in no plan commit.
