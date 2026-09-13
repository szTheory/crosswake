---
phase: 168-0-2-1-release-candidate-readiness
plan: "01"
subsystem: release-candidate-readiness
tags: [github, exact-blob-landing, runtime-authority, graphql-pagination, release-safety]
requires:
  - phase: 167-08
    provides: Exact Phase 167 closeout receipt and five-path Phase 168 handoff
provides:
  - Exact five-blob protected-default landing with independent candidate, CI, merge, and tree receipt
  - Tracked immutable Phase 167 runtime fixture and runnable repository-pinned BEAM toolchain
  - Cursor-complete, privacy-safe live deferral-marker authority
affects: [168-release-candidate-readiness, release-candidate-identity, pull-request-governance]
actuals:
  tokens: 10784
  tasks: 3
  commits: 6
plan_head_before: d35d020326b92e82e29095abd957f630ae21eca1
tech-stack:
  added: []
  patterns: [exact-blob-landing-receipt, tracked-runtime-authority, bounded-backward-cursor-pagination]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/phase168-entry-landing.json
    - .planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/168-01-task1-red.json
    - .planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/168-01-task2-red.json
    - .planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/168-01-task3-red.json
    - test/fixtures/phase167_runtime_authority/milestone.lock
  modified:
    - script/check_phase167_pr_dispositions.py
    - test/js/phase167_pr_dispositions.test.mjs
key-decisions:
  - "Bind the first Phase 168 landing to exactly five retained path/mode/blob records, exact-head Crosswake CI, and a tree-identical two-parent merge."
  - "Use a tracked historical lock fixture for positive reconciliation while current, missing, changed, and additional runtime state remains non-passing."
  - "Treat release-only PR head/base/check refreshes as mutable observations while preserving strict open, unmerged, cursor-complete marker authority."
patterns-established:
  - "A protected-default landing receipt must independently bind before/after default, candidate, exact CI run, merge parents, tree, and every allowed blob."
  - "Backward GitHub pagination is authoritative only after cursor progress, unique comment IDs, stable totalCount, and exact observed-total reconciliation all pass."
requirements-completed: []
requirements-addressed: [REL-04, REL-05]
coverage:
  - id: D-01
    description: The first reversible landing contains exactly the five retained Phase 167 blobs and no unrelated paths.
    requirement: REL-04
    verification:
      - kind: integration
        ref: "PR 151, Crosswake CI run 34730772214, merge 6e9ea2853b67a118242292d6f3fe2ab71d3ac558, and live entry-receipt validation"
        status: pass
    human_judgment: false
  - id: D-02
    description: Release-deferral marker authority traverses every comment page or returns a bounded blocked result.
    requirement: REL-05
    verification:
      - kind: integration
        ref: "66-test Node suite plus live Phase 167 closeout observation"
        status: pass
    human_judgment: false
  - id: runtime-prerequisite
    description: Positive reconciliation uses tracked historical runtime bytes and the exact repository BEAM versions are runnable.
    requirement: REL-05
    verification:
      - kind: integration
        ref: "asdf Erlang 27.3, Elixir 1.19.5-otp-27, Mix 1.19.5, and runtime mutation tests"
        status: pass
    human_judgment: false
duration: 38m
completed: 2026-09-12
status: complete
---

# Phase 168 Plan 01: Release Candidate Entry Authority Summary

**An exact five-blob protected-default landing, tracked historical runtime authority, and cursor-complete live deferral-marker proof establish trustworthy inputs for the 0.2.1 candidate.**

## Performance

- **Duration:** 38m
- **Started:** 2026-09-13T01:25:09Z
- **Completed:** 2026-09-13T02:02:33Z
- **Tasks:** 3
- **Commits:** 6 measured from `d35d020326b92e82e29095abd957f630ae21eca1`

## Accomplishments

- Constructed candidate `8f113ccaf5a6f0d5d38b6e3ebd9c693baab1c0f7` from the five fixed Phase 167 blobs over protected default `30ca31ed3f4be23ae6e4d115d8d0f6273aae220a`, with no extra diff path.
- Merged PR 151 only after exact-head Crosswake CI run `34730772214` completed successfully. Merge `6e9ea2853b67a118242292d6f3fe2ab71d3ac558` preserves the expected two parents and tree `dcd8e4c24b28dc30b933bd373cc938c24e5f4f7b`.
- Added a closed-schema entry receipt and hostile mutation coverage for every path/blob/head/tree/run/default boundary.
- Replaced dependence on the gitignored runtime lock with a tracked fixture whose SHA-256 is the retained `fd4c22c0f07449f02acc487c3100eed7a10edb1382d63807dd4003a54bfd2943`; positive and missing/changed/additional/current-drift cases discriminate correctly.
- Materialized exact Erlang 27.3 and verified Elixir 1.19.5-otp-27 plus Mix 1.19.5 through the unchanged repository `.tool-versions`.
- Traversed GitHub comments backward through bounded cursor pages, requiring unique comment IDs, advancing cursors, stable totals, and complete cardinality before marker absence or count is authoritative.

## Task Commits

1. **Task 1 RED: exact landing contract** — `c57397af`
2. **Task 1 GREEN: entry validator and landing receipt** — `e959407e`
3. **Task 2 RED: tracked runtime fixture contract** — `787e9916`
4. **Task 2 GREEN: immutable runtime fixture and discrimination** — `4e9df455`
5. **Task 3 RED: cursor-complete pagination contract** — `f2343aa9`
6. **Task 3 GREEN: bounded live comment pagination** — `9f94c16c`

## Evidence and Verification

- `node --test test/js/phase167_pr_dispositions.test.mjs` passed 66 tests with zero failures, skips, or todos on all three required executions.
- `--verify-phase168-entry-landing ... --live` passed with five paths and `external_state_changed=true`.
- `--verify-closeout-resolution ... --live` passed with seven ordinary rows, four recovery rows, five handoff paths, and cursor-complete live marker observations.
- `asdf current` selected Erlang 27.3 and Elixir 1.19.5-otp-27; `asdf exec mix --version` reported Mix 1.19.5 compiled with Erlang/OTP 27.
- The entry receipt has exactly its ten allowlisted top-level keys. A fresh protected-default fetch remained merge `6e9ea2853b67a118242292d6f3fe2ab71d3ac558`, and all five recorded `100644` blobs matched its tree exactly.
- `git diff --check` passed. No package, registry, tag, release, mirror, Android, or parked-adopter mutation occurred.

## Decisions Made

- The Phase 168 entry landing is acceptable only when its exact candidate, named CI run, merge ancestry/tree, protected-default transition, and all five path/mode/blob records agree.
- Historical runtime evidence is fixture data, not current mutable workstream state; current runtime drift remains an expected closed failure.
- Deferred release PRs may refresh head/base/check data after protected default advances, but their authority remains strict about being open, unmerged, and carrying exactly the cursor-complete marker count.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Authorized post-landing drift made the retained closeout observation stale**
- **Found during:** Task 3 live verification
- **Issue:** Task 1 necessarily advanced protected default and refreshed the four release-only PR heads, bases, and checks, so byte-for-byte comparison with the dated Phase 167 observation could not pass even though the Task 3-owned marker facts were correct.
- **Fix:** The live loader now authorizes the changed default through the independently validated Phase 168 entry receipt, normalizes only mutable deferred head/base/check fields, and continues to require each deferred PR to be open, unmerged, and cursor-complete with the exact retained marker count/digest.
- **Files modified:** `script/check_phase167_pr_dispositions.py`
- **Commit:** `9f94c16c`

No other deviations occurred.

### AGENTS.md-driven adjustments

- `REL-04` and `REL-05` remain pending in `REQUIREMENTS.md`: this entry plan establishes prerequisites and automation foundations, but the full candidate audit and all reversible release work are delivered by later Phase 168 plans. Marking either requirement complete here would violate the project's honest-release-claims rule.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

Plan 168-02 can consume a trustworthy protected-default baseline, exact landing receipt, runnable repository-pinned BEAM toolchain, and complete live marker authority. Immutable publication remains prohibited and untouched.

## Self-Check: PASSED

All declared artifacts exist, all six task commits are reachable, and the tracked runtime fixture retains its exact recorded SHA-256.

---
*Phase: 168-0-2-1-release-candidate-readiness*
*Completed: 2026-09-12*
