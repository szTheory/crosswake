---
phase: 164-dependency-security-and-gate-authority
plan: "05"
subsystem: testing
tags: [exunit, sqlite, wal, github-actions, fail-closed]

requires:
  - phase: 164-03
    provides: Owned example-host lifecycle tokens and the six-run isolation matrix
  - phase: 164-02
    provides: AST ExUnit execution-class inventory and the Phase 164 aggregate
provides:
  - Exact owned SQLite primary, WAL, and SHM cleanup after owned Repo shutdown
  - Behavioral WAL-mode regression preserving unrelated files and unowned processes
  - Explicit default/hermetic workflow lane authority with a missing-lane negative control
affects: [165-ci-efficiency, exunit-ownership, example-host-proof]

actuals:
  tokens: 3368
  tasks: 2
  commits: 5

tech-stack:
  added: []
  patterns:
    - Closed path-derived SQLite ownership sets without temp-directory globbing
    - Independent conditional manifests for default/hermetic and example-host execution classes

key-files:
  created: []
  modified:
    - test/support/example_host.ex
    - test/crosswake/proof/phase164_example_host_isolation_test.exs
    - script/check_exunit_ownership.exs
    - test/crosswake/proof/phase164_exunit_ownership_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/164-dependency-security-and-gate-authority/164-VALIDATION.md

key-decisions:
  - "Derive the owned SQLite resource set once as the primary path plus exact -wal and -shm companions; never scan or glob the temp directory."
  - "Keep default/hermetic and requires-example-host lane manifests conditional and independent so neither lane can confer ownership on the other class."

patterns-established:
  - "Safe SQLite teardown: register file ownership before Repo ownership so reverse on_exit order stops the Repo before removing its closed resource set."
  - "Non-vacuous execution ownership: an AST-classified test is owned only while its exact workflow, job, literal name, and selector manifest resolves."

requirements-completed: [CIG-02, CIG-03]

coverage:
  - id: D1
    description: "A real owned WAL-mode example-host Repo exposes and then removes its primary, WAL, and SHM paths while unrelated resources survive byte-for-byte."
    requirement: CIG-03
    verification:
      - kind: unit
        ref: "mix test test/crosswake/proof/phase164_example_host_isolation_test.exs"
        status: pass
      - kind: integration
        ref: "script/check_example_host_isolation.sh"
        status: pass
      - kind: integration
        ref: "script/check_phase164_dependency_security_and_gate_authority.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "Ordinary ExUnit ownership requires the exact existing broad hermetic lane and fails closed when that lane is absent."
    requirement: CIG-02
    verification:
      - kind: unit
        ref: "mix test test/crosswake/proof/phase164_exunit_ownership_test.exs"
        status: pass
      - kind: integration
        ref: "elixir script/check_exunit_ownership.exs"
        status: pass
    human_judgment: false

duration: 15 min
completed: 2026-08-28
status: complete
---

# Phase 164 Plan 05: SQLite Sidecar and ExUnit Lane Authority Summary

**Owned WAL/SHM teardown and explicit broad-lane authority close the Phase 164 isolation gap without changing workflow topology.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-08-28T20:33:54Z
- **Completed:** 2026-08-28T20:48:57Z
- **Tasks:** 2
- **Files modified:** 5 implementation/validation files, plus this summary

## Accomplishments

- Extended the idempotent owned-file token to remove exactly the owned SQLite primary path and its `-wal` and `-shm` companions after the Repo stops.
- Added a real WAL-mode behavioral regression that observes all three resources while live, proves all three absent after cleanup, and preserves adversarial neighboring files byte-for-byte.
- Bound ordinary ExUnit ownership to the existing Phase 130 broad hermetic job, literal merge-blocking name, and selector, with an independent missing-lane negative control.
- Restored the authoritative six-run isolation matrix and complete Phase 164 aggregate to green with no `crosswake-example-host-*` residue.

## Task Commits

1. **Task 1 RED:** `c5222950` — expose the owned SQLite sidecar leak with a real WAL-mode Repo.
2. **Task 1 GREEN:** `01e6b872` — remove the exact owned primary/WAL/SHM resource set.
3. **Task 2 RED:** `e476d3b3` — require broad default/hermetic lane authority.
4. **Task 2 GREEN:** `32b9761c` — validate the exact Phase 130 workflow job, name, and selector.
5. **Task 2 evidence:** `5bf65b9d` — record focused, matrix, and aggregate validation results.

## Files Created/Modified

- `test/support/example_host.ex` — closed, path-derived primary/WAL/SHM cleanup.
- `test/crosswake/proof/phase164_example_host_isolation_test.exs` — real WAL lifecycle, safe-order cleanup, idempotence, and unowned-resource proof.
- `script/check_exunit_ownership.exs` — separate explicit manifests for default/hermetic and example-host execution classes.
- `test/crosswake/proof/phase164_exunit_ownership_test.exs` — synthetic default-lane fixture and missing-lane negative control.
- `.planning/workstreams/quality-ratchet-release/phases/164-dependency-security-and-gate-authority/164-VALIDATION.md` — only the two Plan 164-05 rows changed from pending to exact green evidence.

## Decisions Made

- Cleanup owns a closed three-path set derived from the unique primary database path. It does not glob, reconcile, or inspect unrelated temp resources.
- Default/hermetic authority is conditional on ordinary runnable tests being present, just as the dedicated manifest remains conditional on effective `requires_example_host` tests.
- The two lane results remain separate inputs to ownership classification; one valid lane cannot mask a missing authority for the other class.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Raw Ecto SQL against the dynamically loaded example Repo attempted to stringify an `Exqlite.Query` in the root proof harness. The regression disables Logger only for its own test process around the three raw WAL setup statements; database behavior and aggregate output remain deterministic and bounded.
- The local Hex session was expired, but all dependency resolution and audits continued credential-free as designed; both audits remained advisory-free.

## TDD Gate Compliance

- Task 1 RED `c5222950` failed because the exact WAL path remained after cleanup; GREEN `01e6b872` passed 8/8 lifecycle tests.
- Task 2 RED `e476d3b3` failed because an ordinary test without the broad lane still exited zero; GREEN `32b9761c` passed the live detector and 8/8 negative controls.
- No refactor commit was needed after either GREEN gate.

## Verification Evidence

- Focused lifecycle proof: 8 tests, 0 failures.
- Live ownership detector: all intended ExUnit files owned; focused proof: 8 tests, 0 failures.
- Isolation matrix: tagged and complete classes passed at seeds 17, 101, and 1009 (6/6).
- Phase 164 aggregate: both audits, 88 literal producers, 27 merge-blocking candidates, 12 producer controls, 8 ownership controls, 8 lifecycle tests, 6 isolation runs, 10 aggregator structural tests, and 5 semantic self-tests all passed.
- Owned-temp snapshot: empty before the matrix; empty after the matrix and aggregate. Final `find "${TMPDIR:-/tmp}" -maxdepth 1 -name 'crosswake-example-host-*' -print` emitted nothing.

## Known Stubs

None.

## Threat Review

- T-164-06 is mitigated by safe Repo-first teardown, a closed exact path set, idempotence, and byte-equal adversarial preservation.
- T-164-11 is mitigated by observing the real primary/WAL/SHM resources before cleanup and retaining the six-run plus aggregate authorities.
- T-164-03 is mitigated by exact default-lane workflow/job/name/selector validation and an independent missing-lane control.
- No endpoint, authentication path, schema trust boundary, Android surface, adopter data, workflow topology, or package dependency was introduced.

## User Setup Required

None.

## Next Phase Readiness

- CIG-03, D-09, and D-10 are green against the observed WAL/SHM failure mode and the complete retained evidence matrix.
- CIG-02 ownership is now non-vacuous for both execution classes without a workflow edit.
- Phase 164 is ready for re-verification; Phase 165 may optimize CI only while preserving these explicit lane and isolation authorities.

## Self-Check: PASSED

- All five modified plan artifacts and this summary exist on disk.
- Task commits `c5222950`, `01e6b872`, `e476d3b3`, `32b9761c`, and `5bf65b9d` exist in repository history.
- Focused checks, all six matrix combinations, the complete Phase 164 aggregate, and the final residue scan passed in this execution.

---
*Phase: 164-dependency-security-and-gate-authority*
*Completed: 2026-08-28*
