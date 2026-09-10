---
phase: 167-documentation-and-pull-request-reconciliation
plan: 05
subsystem: ci
tags: [github-actions, supply-chain, setup-java, pull-request, optimistic-concurrency]

requires:
  - phase: 167-documentation-and-pull-request-reconciliation
    plan: 04
    provides: committed documentation and CI authority preserved outside the dependency PR
provides:
  - reusable closed-schema exact-SHA pull-request resolution validator
  - seven coherent immutable actions/setup-java v6 uses and repository-wide regression
  - merged PR 121 with same-head Crosswake CI and fresh-default reachability receipt
affects: [167-06-package-reconciliation, 167-07-packstore-cleanup, 167-08-pr-disposition-evidence]

actuals:
  tokens: 5705
  tasks: 3
  commits: 8

tech-stack:
  added: []
  patterns: [closed structured GitHub reads, exact-SHA optimistic concurrency, immutable action pins]

key-files:
  created:
    - script/check_phase167_pr_dispositions.py
    - .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/pr-121-resolution.json
  modified:
    - .github/actions/setup-android-jvm/action.yml
    - .github/workflows/crosswake-ci.yml
    - .github/workflows/phase68-proof.yml
    - .github/workflows/release-please.yml
    - test/crosswake/proof/phase165_ci_integrity_test.exs

key-decisions:
  - "Resolve setup-java v6 from the official v6 tag immediately before editing and pin its full commit de7274f081f381c8f8158605e0321c36c376e2e6 everywhere."
  - "Update the original Dependabot branch as one five-path intent commit because it accepted the coherent transaction; no replacement PR was needed."
  - "Bind merge authority to exact head, base, named-check, scope, commit-count, and fresh-default facts before and after mutation."

patterns-established:
  - "PR resolution receipts carry only closed low-cardinality fields and full commit OIDs."
  - "Remote writes use immediate structured refresh plus force-with-lease or match-head-commit guards."

requirements-completed: [DOC-03]

coverage:
  - id: D1
    description: One reusable validator rejects stale heads, bases, checks, reachability, scopes, commit counts, and unauthorized replacements.
    requirement: DOC-03
    verification:
      - kind: integration
        ref: "python3 script/check_phase167_pr_dispositions.py --self-test-resolution"
        status: pass
    human_judgment: false
  - id: D2
    description: Exactly seven live setup-java uses share the execution-time official immutable v6 commit.
    requirement: DOC-03
    verification:
      - kind: integration
        ref: "actionlint .github/workflows/crosswake-ci.yml .github/workflows/phase68-proof.yml .github/workflows/release-please.yml && mix test test/crosswake/proof/phase165_ci_integrity_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: PR 121 merged from the exact tested candidate after successful same-head Crosswake CI and is reachable from fresh default authority.
    requirement: DOC-03
    verification:
      - kind: other
        ref: "python3 script/check_phase167_pr_dispositions.py --verify-resolution .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/pr-121-resolution.json --live"
        status: pass
    human_judgment: false

duration: 20min
completed: 2026-09-10
status: complete
---

# Phase 167 Plan 05: setup-java v6 Pull-Request Reconciliation Summary

**All seven setup-java uses now share the official immutable v6 commit, and PR #121 merged only after exact-head Crosswake CI and fresh-default reachability proof.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-09-10T21:20:52Z
- **Completed:** 2026-09-10T21:40:22Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Added a dependency-free closed receipt validator with 22 positive/negative synthetic cases across all three Phase 167 PR scope profiles.
- Resolved the official setup-java v6 tag to full commit `de7274f081f381c8f8158605e0321c36c376e2e6` and pinned all seven live uses with one exact count/value regression.
- Rewrote the original Dependabot branch as one authorized five-path intent commit, passed current `Crosswake CI` on that exact head, merged PR #121, and validated the final bounded receipt live.

## Task Commits

Each task was committed atomically, with RED/GREEN history for behavior changes:

1. **Task 1: Introduce the reusable exact-SHA PR resolution gate** — `dfd51e4e` (RED), `44cb62e6` (GREEN)
2. **Task 2: Rebase and complete all seven immutable setup-java v6 uses** — `23b009b3` (RED), `8c4acbfc` (GREEN), remote candidate `0e96dbfd`
3. **Task 3: Require current CI and close PR #121 with one final disposition** — remote merge `159eebd7`, local authority merge `0ac58cc7`, receipt `665c6ea8`

## Files Created/Modified

- `script/check_phase167_pr_dispositions.py` — Validates closed receipts against fresh structured PR, check, default, scope, and reachability authority.
- `evidence/pr-121-resolution.json` — Retains only the tested/full OIDs, successful named check, exact scope profile, commit count, and merged disposition.
- `.github/actions/setup-android-jvm/action.yml` — Uses the same immutable setup-java v6 commit without changing Android behavior.
- `.github/workflows/crosswake-ci.yml`, `.github/workflows/phase68-proof.yml`, and `.github/workflows/release-please.yml` — Carry the remaining six coherent v6 pins.
- `test/crosswake/proof/phase165_ci_integrity_test.exs` — Requires exactly seven full-SHA v6 uses with one official value.

## Decisions Made

- Kept PR #121 as the candidate because its branch accepted the complete five-path transaction cleanly; the authorized supersession fallback was not used.
- Amended the Dependabot branch to one intent commit based on the exact observed default SHA, then used force-with-lease for the branch update and `--match-head-commit` for merge.
- Merged remote default into local main after the PR landed so later sequential plans inherit both prior Phase 167 commits and the authoritative PR ancestry.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Used an invocation-owned clone after worktree isolation was downgraded**
- **Found during:** Task 2
- **Issue:** The orchestrator explicitly required sole sequential execution on main, superseding the plan's linked-worktree assumption, while the PR candidate still had to exclude Plans 01-04.
- **Fix:** Prepared the original Dependabot head in an invocation-owned temporary clone and changed only the exact five authorized paths; local main retained all prior commits and later merged the authoritative PR ancestry.
- **Files modified:** No additional repository files.
- **Verification:** PR changed-path scope was exactly five paths, its parent equaled the refreshed default SHA, and all prior Plan 01-04 commits remain in local history.
- **Committed in:** `0e96dbfd` (remote candidate) and `0ac58cc7` (local authority merge)

---

**Total deviations:** 1 auto-fixed blocking issue
**Impact on plan:** Isolation changed only in mechanics. Candidate scope, optimistic-concurrency guards, CI authority, and preserved prior work all remained exact.

## Issues Encountered

- The temporary clone did not contain fetched Mix dependencies, so its focused ExUnit invocation could not start. The byte-equivalent changed files passed 28 focused tests on local main before the guarded push, and the exact remote candidate then passed the complete current Crosswake CI run.
- One initial read-only structured PR inspection selected commit metadata more broadly than necessary. No prose was interpolated into commands or retained in repository evidence; every mutation and final verification used narrowed `--jq` projections containing only the closed fields.

## Authentication Gates

- Existing GitHub CLI authentication had repository and workflow authority, so no human-action checkpoint was required.

## User Setup Required

None - the required GitHub CLI credential was already configured and verified.

## TDD Gate Compliance

- Task 1 RED `dfd51e4e` precedes GREEN `44cb62e6`.
- Task 2 RED `23b009b3` precedes GREEN `8c4acbfc`.

## Verification

- Validator self-test — 22 cases passed.
- Actionlint — all three edited workflow files passed.
- Focused CI integrity suite — 28 tests, 0 failures.
- Repository scan — exactly seven setup-java uses, all pinned to the same official full v6 commit.
- Remote `Crosswake CI` run `34532364310` — successful on tested head `0e96dbfda96eb3f8193dc23df281d4e070f9d080`.
- Final live receipt verification — passed for merged PR #121 and default commit `159eebd7f68572ad5ab19f598ce1fb068e7b03b2`.

## Known Stubs

None. Mechanical empty/null matches are closed validation state, explicit negative assertions, or pre-existing workflow control values; no runtime or UI placeholder was added.

## Next Phase Readiness

- Plan 167-06 can reconcile PR #110 against remote default containing the verified setup-java transaction.
- PRs #115 and #57 received no mutation and remain Phase 168 approval surfaces.

## Self-Check: PASSED

- All seven created or modified plan files exist.
- All eight local/remote task and integration commits resolve in repository history after the authority merge.
- Task-level, plan-level, same-head CI, final PR state, and fresh-default reachability checks passed.
- No skipped test, unrun required verification, unknown stub, or uncovered threat surface remains.

---
*Phase: 167-documentation-and-pull-request-reconciliation*
*Completed: 2026-09-10*
