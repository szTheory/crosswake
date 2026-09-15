---
phase: 166-clean-checkout-engineering-quality
plan: 02
subsystem: testing
tags: [node-test, dependency-scheduler, git-porcelain, cleanup, deterministic-output]
requires:
  - phase: 166-clean-checkout-engineering-quality
    provides: fixed nine-stage repository verification inventory and exact preflight contracts
provides:
  - dependency-aware hybrid execution with recursive BLOCKED propagation
  - bounded-timeout child execution with private invocation logs
  - NUL-preserving Git snapshots and exact invocation-owned cleanup
  - deterministic bounded PASS, FAIL, and BLOCKED terminal summaries
affects: [166-clean-checkout-engineering-quality, repository-quality, clean-checkout-proof]
actuals:
  tokens: 8039
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns: [manifest-order topological scheduling, absent-at-start output ledger, byte-preserving Git snapshots]
key-files:
  created: []
  modified:
    - script/verify_repository.mjs
    - script/repository_verification_stages.json
    - test/js/repository_verification.test.mjs
    - test/fixtures/repository_quality/stage-cases.json
key-decisions:
  - "Propagate every non-pass result through dependency edges while preserving manifest-order execution for independent stages."
  - "Treat only exact declared outputs absent at invocation start as cleanup-owned, and refuse symlink or repository-prefix escapes."
  - "Keep Git porcelain bytes in private NUL-delimited snapshot files and expose only bounded purpose-level results and remediations."
patterns-established:
  - "Every selected stage has a fixed timeout and a private per-purpose stdout/stderr log beneath the invocation root."
  - "Complete mode requires an empty initial Git snapshot; focused mode accepts existing changes only when the final snapshot is byte-identical."
requirements-completed: [ENG-01, ENG-03, ENG-04]
coverage:
  - id: D1
    description: "Dependency failures recursively block descendants while independent proof families continue in deterministic order."
    requirement: ENG-01
    verification:
      - kind: integration
        ref: "node --test test/js/repository_verification.test.mjs --test-name-pattern='dependency|blocked|independent|timeout'"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every exit path uses byte-preserving Git inspection, exact cleanup ownership, and bounded non-disclosing remediation output."
    requirement: ENG-03
    verification:
      - kind: integration
        ref: "node --test test/js/repository_verification.test.mjs --test-name-pattern='git|cleanup|summary|remediation|secret'"
        status: pass
      - kind: integration
        ref: "script/verify_repository.sh --self-test"
        status: pass
    human_judgment: false
duration: 11min
completed: 2026-09-09
status: complete
---

# Phase 166 Plan 02: Dependency-Aware Repository Runner Summary

**A dependency-aware repository runner now continues independent proof, blocks invalid chains, restores invocation-owned state, and reports deterministic non-disclosing results.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-09-09T16:49:48Z
- **Completed:** 2026-09-09T17:00:28Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added manifest-ordered scheduling that recursively labels failed dependency chains `BLOCKED` while continuing unrelated proof families.
- Added fixed per-stage timeouts, closed handling for spawn errors, signals, nonzero exits, and malformed results, plus private complete child logs.
- Added NUL-delimited pre/final Git snapshots, dirty-complete rejection, byte-identical focused baselines, and exact absent-at-start output cleanup with symlink/prefix refusal.
- Added a bounded terminal contract with one remediation per non-pass purpose and no child-output or secret disclosure.

## Task Commits

1. **Task 1 RED: scheduler execution contracts** — `8f088223` (test)
2. **Task 1 GREEN: dependency-aware proof stages** — `06d24707` (feat)
3. **Task 2 RED: finalization safety contracts** — `220d7738` (test)
4. **Task 2 GREEN: safe repository finalization** — `90076883` (feat)

## Files Created/Modified

- `script/verify_repository.mjs` — Runs the dependency graph, captures logs, snapshots Git bytes, cleans exact outputs, and renders final results.
- `script/repository_verification_stages.json` — Declares bounded timeouts for all nine fixed stages.
- `test/js/repository_verification.test.mjs` — Proves dependency, process-failure, Git-state, cleanup, and output semantics in temporary repositories.
- `test/fixtures/repository_quality/stage-cases.json` — Supplies dependency, process-outcome, and exact tool-version negative controls.

## Decisions Made

- A stage is runnable only when every selected dependency passed; `FAIL` and `BLOCKED` both propagate as non-pass state.
- Cleanup authority is derived from exact manifest paths that did not exist at invocation start; pre-existing paths are never claimed or removed.
- Focused runs make no clean-baseline claim: they pass cleanliness only when their final porcelain bytes exactly match their initial bytes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected incomplete exact-version fixtures**
- **Found during:** Task 1 (dependency scheduler tests)
- **Issue:** The Java fixture omitted the quotes required by its production version regex, and no Xcode fixture existed, causing unrelated false preflight failures.
- **Fix:** Corrected the Java version string and added the exact synthetic Xcode version output.
- **Files modified:** `test/fixtures/repository_quality/stage-cases.json`
- **Verification:** The full Node suite passes all 17 tests, including complete-run independent-stage behavior.
- **Committed in:** `06d24707`

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug)
**Impact on plan:** The fixture correction removed false negatives without changing production tool authority or scope.

## Issues Encountered

- Complete-mode tests initially used the intentionally dirty developer checkout; they were moved to isolated temporary Git repositories so the new clean-baseline rule is exercised honestly.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Later Phase 166 plans can add artifact-policy and CI-parity layers over the closed runner without changing its execution result vocabulary.
- Canonical complete proof still belongs in the later isolated exact-commit evidence plans because the shared developer checkout intentionally contains unrelated work.

## Known Stubs

None.

## Threat Flags

None - process execution, filesystem cleanup, and Git-diagnostic trust boundaries were all covered by the plan threat model and focused negative controls.

## Self-Check: PASSED

- All four implementation files and this summary exist.
- All four TDD task commits exist in Git history.
- Focused scheduler, finalization, and public self-test commands passed after the final code change.

---
*Phase: 166-clean-checkout-engineering-quality*
*Completed: 2026-09-09*
