---
phase: 199-release-0-2-12
plan: 03
subsystem: release
tags: [github-environments, release-gates, preflight, release-please, scanner, bash, exunit]

requires:
  - phase: 199-release-0-2-12
    provides: "199-01 decision D-01 A (four protected environments) and the gate protocol; 199-02 stable main"
provides:
  - "script/release_candidate/check_release_environments.sh, a credential-free preflight for the four approval environments"
  - "four live GitHub environments (release-tags, publish-hex, publish-maven, publish-ios-mirror), each with a required-reviewer rule and protected-branches-only deployment"
  - "approved-release-guard runs the preflight on every push; blocks a linked or companion release when it fails"
  - "scanner check release.gate.environments_preflight (roster 98 to 99) and test/crosswake/proof/phase199_release_gates_test.exs"
affects: [199-04, 199-05, 199-07, 199-10]

plan_head_before: f9cee919da12907ae73d5cea606941e90e64357d
plan_head_after: 8bbfac4c4634f6db21afcca2d17c292a7734625d

actuals:
  tokens: 7960
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "anonymous (credential-free) API read so the local proof and the hosted-runner proof use the same credential class"
    - "fail-closed reads: absent protection_rules is FAIL, 403/429 beyond a bounded wait and 5xx are exit 3 UNVERIFIED, never a pass"
    - "ordinary push warns, release push blocks, both from one preflight status captured without tripping set -e"

key-files:
  created:
    - script/release_candidate/check_release_environments.sh
    - test/crosswake/release_candidate/release_environments_test.exs
    - test/crosswake/proof/phase199_release_gates_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/environments-199.txt
  modified:
    - .github/workflows/release-please.yml
    - script/check_release_workflow_integrity.exs
    - test/crosswake/proof/phase175_rel17_publish_paths_test.exs

key-decisions:
  - "Anonymous read of an environment includes protection_rules, the required_reviewers entry and its reviewers array, so no token-backed read is needed and the plan's re-plan branch did not fire"
  - "The guard captures the preflight status at the top of the step and uses it at three points: advisory on each early exit 0, BLOCKED before the two-parent merge checks"

requirements-completed: []

coverage:
  - id: D1
    description: "Preflight script with a fixture test per reason, rate-limit bound and selftest-seam refusal"
    requirement: REL-07
    verification:
      - kind: unit
        ref: "bash script/mix_test_gate.sh --min 9 -- test/crosswake/release_candidate/release_environments_test.exs (10 ran, 0 failures)"
        status: pass
      - kind: other
        ref: "shellcheck script/release_candidate/check_release_environments.sh (clean)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Real negative control then real positive: live FAIL environment_missing before creation, live PASS after"
    requirement: REL-07
    verification:
      - kind: other
        ref: "199-EVIDENCE/environments-199.txt: 'before: rc=1 ... reason=environment_missing', 'after: rc=0 ... verdict=PASS'"
        status: pass
    human_judgment: false
  - id: D3
    description: "Four environments exist, protected, and read back without credentials"
    requirement: REL-07
    verification:
      - kind: other
        ref: "gh api repos/szTheory/crosswake/environments -> publish-hex,publish-ios-mirror,publish-maven,release-tags; four 'created: <name> http=200' lines; four unauthenticated readback lines"
        status: pass
    human_judgment: false
  - id: D4
    description: "Guard calls the preflight before any early exit, warns on ordinary pushes, blocks releases; scanner check with seeded mutations"
    requirement: REL-07
    verification:
      - kind: unit
        ref: "elixir script/check_release_workflow_integrity.exs -> DONE: 99 of 99 roster checks emitted; 0 failed."
        status: pass
      - kind: unit
        ref: "bash script/mix_test_gate.sh --min 3 -- test/crosswake/proof/phase199_release_gates_test.exs (4 ran, 0 failures)"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase175_rel17_publish_paths_test.exs warn and block tests run the real guard text (30 ran with phase199 and env tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The hosted-runner anonymous read works within GitHub's anonymous rate limit"
    requirement: REL-07
    verification: []
    human_judgment: true
    rationale: "Only a real push to main on a hosted runner can show it; plan 199-07 records the first proposal-run result and 199-10 re-reads the latest main guard line before the merge gate"

duration: "about 10 min (13:32Z to 13:42Z, 2026-11-07)"
completed: 2026-11-07
status: complete
---

# Phase 199 Plan 03: Approval Environments and Fail-Closed Preflight Summary

**Four protected GitHub environments now exist and a credential-free preflight, called from the release guard on every push, blocks any linked or companion release if one is missing or unprotected; it failed for real before creation and passes after.**

## What was checked

- Before writing field checks: an unauthenticated read of the environments list returned 200 with none; each named environment returned 404. Recorded as `api_shape:`.
- Real negative control: the live preflight against the repository with no environments exited 1 with four `environment_missing` lines (`before: rc=1 ... reason=environment_missing`).
- Created the four environments with the maintainer as required reviewer, `prevent_self_review` false, `wait_timer` 0 and protected-branches-only deployment, each answering HTTP 200. The reviewer id was read live into a scratch file outside the repo and used only in request bodies; it is not in any file (grep of the evidence for it prints 0).
- Unauthenticated read-back: every environment shows `reviewer_rule=present branch_policy=protected`, and the anonymous body includes `protection_rules`, a `required_reviewers` entry and its `reviewers` array. So the plan's re-plan branch ("anonymous read omits the reviewer rule") did not apply.
- Live preflight after creation: `rc=0`, four PASS lines. `gh api .../environments` lists exactly `publish-hex,publish-ios-mirror,publish-maven,release-tags`.
- Scanner `99 of 99 roster checks emitted; 0 failed`; actionlint and shellcheck clean; `grep -c 'environment:'` on the workflow still 0 (no job points at an environment yet).

## What is unknown, and why

- Whether the hosted-runner anonymous read stays inside GitHub's rate limit on a real push to main. Runners share outbound addresses; locally the limit seen was 60 per hour (14 used during this plan). The preflight waits at most 60 s each and 120 s in total and otherwise exits 3, and the guard blocks a release on that. Plan 199-07 records the first proposal-run result and 199-10 re-reads the latest main guard line before the merge gate is shown. Until then this is unproven.

## Key finding

GitHub answers environment reads with `cache-control: public, max-age=60`. Right after creation, the first read of `release-tags` still returned the earlier cached 404 and then 200 a moment later. A preflight run within a minute of creating or editing an environment can therefore see stale data; recorded in the evidence as a `known_limit:`. For the guard this matters only on the first minute after a settings change.

## Task Commits

1. **Task 1: Tracer, preflight script with fixture tests, live FAIL** - `bf222afc` (feat)
2. **Task 2: Create and read back four environments, live PASS** - `3c73d68f` (docs)
3. **Task 3: Guard call, scanner check, seeded mutations** - `8bbfac4c` (ci)

**Plan metadata:** committed after this file (docs: complete plan).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Existing classifier tests broke when the guard gained a script call**
- **Found during:** Task 3 (broader run of every test that touches the release workflow)
- **Issue:** `phase175_rel17_publish_paths_test.exs` extracts the real guard text and runs it in a temporary repository that has no `script/release_candidate/check_release_environments.sh`, so the new BLOCKED branch fired and two tests failed.
- **Fix:** the fixture now writes a stand-in preflight script with a chosen exit status (the real script reads live GitHub, which a classifier fixture must not do). Two new tests run the real guard text: an unprotected environment only warns on an ordinary push, and blocks a linked release before any output.
- **Files modified:** test/crosswake/proof/phase175_rel17_publish_paths_test.exs
- **Commit:** `8bbfac4c`

**2. [Plan variance] 10 preflight tests instead of 9.** An extra case covers a 403 with no usable rate-limit header (exit 3 at once). The plan floor of 9 holds.

**3. [Plan variance] 4 phase199 tests instead of 3.** The extra one is the real workflow passing the new check; the three mutations are: call deleted, call moved after the outputs, BLOCKED reason removed.

**4. [Formatting] `mix format` re-wrapped one line of release_environments_test.exs** (committed in Task 1); the change is in the Task 3 commit.

**Total deviations:** 1 auto-fixed bug, 3 small variances. **Impact:** none on scope.

## Authorization

The GitHub write (creating the four environments, reversible, edit or delete) was authorized by the user's D-01 A choice in 199-DECISIONS.md; it was the only repository-setting write. The permission system allowed it. Nothing was pushed, merged, tagged, published or dispatched.

## Issues Encountered

An initial wider test run showed four failures: two are deviation 1; two (`phase175_linked_authorization_test.exs`) failed only because my file selection omitted `evidence_live_test.exs`, which defines the module they call. Run together, those 28 tests pass.

## Known Stubs

None.

## Threat Flags

None beyond the plan's threat model. The guard now makes an anonymous GitHub API call on every push to main (T-199-51 covers the rate-limit risk). No token, key or reviewer id is stored in any file.

## User Setup Required

None.

## Next Phase Readiness

- Ready for 199-04 (point the publisher jobs at the environments); the preflight now exists and passes, so the `environment:` key may be added there.
- REL-07 is not complete (later plans finish it).
- `ci/199-release-gates` is not pushed; main is unchanged.

## Self-Check: PASSED

- Files present: check_release_environments.sh, release_environments_test.exs, phase199_release_gates_test.exs, environments-199.txt, this file.
- Commits `bf222afc`, `3c73d68f`, `8bbfac4c` are on `ci/199-release-gates`; measured commit count from the plan ledger is 3.
- Re-ran at close: preflight live rc=0, scanner 99 of 99, actionlint 0, shellcheck 0, `grep -cE 'GH_TOKEN|GITHUB_TOKEN|Bearer'` on the script prints 0, `grep -c 'environment:'` on the workflow prints 0, `.planning/config.json` in no plan commit.

---
*Phase: 199-release-0-2-12*
*Completed: 2026-11-07*
