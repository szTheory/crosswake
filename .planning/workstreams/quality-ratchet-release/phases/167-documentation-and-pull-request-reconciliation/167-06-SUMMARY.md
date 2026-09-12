---
phase: 167-documentation-and-pull-request-reconciliation
plan: 06
subsystem: ci-governance
tags: [mix, exunit, github-actions, pr-reconciliation, evidence]
requires:
  - phase: 166-clean-checkout-engineering-quality
    provides: repository-wide nine-stage verification and recurring CI proof ownership
provides:
  - exact companion dependency-floor and documentation reconciliation
  - root Mix verification partitioned into dedicated Phase41 and broad selections
  - ancestry-preserving PR 149 merge with 47-of-47 exact-head CI
  - unmerged supersession receipts for PRs 110 and 148
affects: [167-07, 167-08, phase-168-release-readiness]
actuals:
  tokens: 112115
  tasks: 2
  commits: 52
plan_head_before: 398d47b3d649d7846ee370ddee9f7e5102ebee80
tech-stack:
  added: []
  patterns: [isolated repeated Mix test tasks, manifest-only candidate freeze, exact-head CI merge gate]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/default-branch-reconciliation-resolution.json
    - .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/pr-110-resolution.json
  modified:
    - mix.exs
    - test/crosswake/proof/phase161_1_navigation_gate_integrity_test.exs
    - script/check_phase167_default_reconciliation.py
    - .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/default-branch-dependency-closure.json
    - .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/fix-forward-failure-ledger.json
key-decisions:
  - "Run the two exact root test partitions through isolated `cmd mix` invocations because Mix tasks and ExUnit registrations are single-run within one VM."
  - "Keep the destroyed-log e5 root observation nondeterministic and unreproduced; no leaf, category, or retry policy was inferred."
  - "Consume the sole replacement-final update only after two independent nine-stage local proofs, then require the first hosted run to be 47-of-47 green."
patterns-established:
  - "Partition parity: hosted and root verification use the same Phase41 tag, seed, max-cases, and dedicated-before-broad ordering."
  - "Merge authority: freeze a manifest-only candidate, bind exact-head CI, and prove merge-parent and tree identity before supersession."
requirements-completed: [DOC-01, DOC-03]
coverage:
  - id: D1
    description: Root verification preserves all companion lanes and executes exactly three Phase41 tests before the remaining 1622 root tests.
    requirement: DOC-01
    verification:
      - kind: integration
        ref: "mix verify plus phase161_1_navigation_gate_integrity_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: PR 149 landed the exact tested tree after 47-of-47 hosted checks, then PRs 110 and 148 closed unmerged with fixed receipts.
    requirement: DOC-03
    verification:
      - kind: other
        ref: "run 34662225432 and check_phase167_default_reconciliation.py live/local validators"
        status: pass
    human_judgment: false
duration: 1h 2m
completed: 2026-09-11
status: complete
---

# Phase 167 Plan 06: Dependency and Default-Branch Reconciliation Summary

**Exact package-floor truth and Phase41-partitioned root verification landed through an ancestry-preserving, 47-of-47-green PR transaction.**

## Performance

- **Duration:** 1h 2m for the final 3K/3L recovery execution
- **Started:** 2026-09-11T23:48:54Z
- **Completed:** 2026-09-12T00:50:55Z
- **Tasks:** 2
- **Files modified:** 22 across the full plan ledger
- **Commits:** 52 measured from `398d47b3d649d7846ee370ddee9f7e5102ebee80`

## Accomplishments

- Preserved completed Task 1 package-floor parity commits `cc14f636`, `c6b02e38`, `eba0f21b`, and `c06b6109` and all accepted recovery ancestry through `e5f75d26`.
- Added a deterministic RED/GREEN contract for root `mix verify`: five companion lanes remain byte-ordered, the three tagged Phase41 tests run in isolation, and the other 1622 root tests run with 77 exclusions (74 host plus three Phase41).
- Passed the invocation-owned nine-stage repository proof at source `f4ab5118`, then independently validated manifest-only candidate `b489905d` with the same clean-checkout gate.
- Advanced PR #149 exactly once from failed head `072250e3` to `b489905d`; first hosted run `34662225432` completed 47/47 green without rerun.
- Merged PR #149 as merge commit `e0959e8c`, proving parents `74fc15cc` and `b489905d` and exact tested-tree identity, then closed #110 and #148 unmerged with one fixed marker each.
- Fast-forwarded local `main` to the fresh protected-default authority without checking it out or committing on it; live and local reconciliation validators passed.

## Task Commits

The plan's original task and recovery commits remain atomic. Key commits include:

1. **Task 1: Align companion manifests, READMEs, and package truth** — `cc14f636`, `c6b02e38`, `eba0f21b`, `c06b6109`
2. **Recovery 3K RED: Prove the root alias partition gap** — `17d5de8a`
3. **Recovery 3K GREEN: Partition root verification** — `f4ab5118`
4. **Recovery 3L candidate: Freeze exact source scope** — `b489905d`
5. **Recovery 3L receipt: Record merge and supersessions** — `c01a7f7b`

All earlier 3A-3I recovery commits are retained as immutable ancestry. Failed diagnostic/final heads remain history and were not merged.

## Files Created/Modified

- `mix.exs` — runs the exact dedicated and broad root test commands in isolated Mix processes.
- `test/crosswake/proof/phase161_1_navigation_gate_integrity_test.exs` — enforces companion bytes/order, partition parity, union counts, and missing/duplicate/reordered negative controls.
- `script/check_phase167_default_reconciliation.py` — validates final budget, live default authority, merge identity, and supersession receipts.
- `evidence/default-branch-dependency-closure.json` — binds the protected-default-to-candidate path/mode/blob inventory.
- `evidence/default-branch-reconciliation-resolution.json` — records tested head/tree, exact-head CI, merge, default, and supersession identity.
- `evidence/pr-110-resolution.json` — records PR #110's closed-unmerged supersession.
- `evidence/fix-forward-failure-ledger.json` — preserves the failed 072 attempt and records replacement-final usage 1/1.

## Decisions Made

- Used `cmd mix` for the two exact root commands so Mix's single-run task registry and ExUnit's consumed registrations cannot silently skip the broad partition.
- Preserved the first e5 root failure only as an unknown nondeterministic observation; the proven alias bypass was repaired without claiming it caused the destroyed-log failure.
- Kept all executor and receipt commits on `agent-phase167-fixforward`; protected `main` received only the GitHub merge commit and the local ref moved by fast-forward fetch.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Isolated repeated Mix test tasks**
- **Found during:** Recovery 3K aggregate verification
- **Issue:** Two literal `test` alias entries share Mix/ExUnit single-run state; the second selection was silently skipped or had zero registered tests.
- **Fix:** Executed each exact inner test command through automatically re-enabled `cmd mix` subprocesses and strengthened the static regression.
- **Files modified:** `mix.exs`, `test/crosswake/proof/phase161_1_navigation_gate_integrity_test.exs`
- **Verification:** Eight dedicated runs reported 3/0; two broad runs reported 1622/0 with 77 exclusions; five companions reported 11/55/139/53/98 green.
- **Committed in:** `f4ab5118`

**2. [Rule 3 - Blocking] Used the harness-required repository-local proof directory**
- **Found during:** Recovery 3L nine-stage invocation
- **Issue:** macOS `TMPDIR` resolves outside the source repository, which the evidence harness rejects before running stages.
- **Fix:** Used an invocation-owned `.planning` temporary directory and removed it on exit.
- **Verification:** Repository evidence capture passed at `f4ab5118` with no residue and unchanged runtime hashes.
- **Committed in:** No file change

**3. [Rule 1 - Bug] Preserved JSON shape for live default lookup**
- **Found during:** Recovery 3L live receipt validation
- **Issue:** The validator passed a raw SHA through `json.loads`, causing a closed JSON decode failure.
- **Fix:** Wrapped the GitHub jq result as `{oid: ...}` and extracted the field after JSON parsing.
- **Files modified:** `script/check_phase167_default_reconciliation.py`
- **Verification:** Self-test, live resolution, and local reconciliation validators all passed.
- **Committed in:** `c01a7f7b`

---

**Total deviations:** 3 auto-fixed (2 Rule 1, 1 Rule 3)
**Impact on plan:** Each change was required to execute the locked proof contract correctly; product scope, workflow topology, timeouts, toolchain, Android posture, and privacy boundaries did not change.

## Issues Encountered

- `mix verify` requires the repository's canonical `MIX_ENV=test` invocation. The final direct, aggregate, clean-checkout, and hosted proofs all used the pinned test environment.
- Pinned dependencies emitted advisory vulnerability notices during local dependency resolution; the accepted recurring security proof remained green and no dependency change was authorized in this plan.

## Known Stubs

None.

## Authentication Gates

None. Existing GitHub credentials authorized the guarded update, merge, comments, and closures.

## User Setup Required

None.

## Next Phase Readiness

- Plan 167-07 may start from protected default `e0959e8cb503eae7352c21a5d6693ef99d0d5a9b` and local receipt head `c01a7f7bc45df055557b1e9d308402067e3496ed`.
- PRs #115 and #57 remain untouched release-approval surfaces for the later locked plan.
- The First B2C Adopter lane remains parked; Android scope and release publication remain frozen.

## Self-Check: PASSED

- All created and modified contract files exist.
- All named task, candidate, receipt, and merge commits resolve.
- PR #149 still reports 47/47 green and the live resolution validator passes.
- No stub marker was introduced in the changed implementation or evidence files.

---
*Phase: 167-documentation-and-pull-request-reconciliation*
*Completed: 2026-09-11*
