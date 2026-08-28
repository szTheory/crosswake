---
phase: 164-dependency-security-and-gate-authority
plan: "03"
subsystem: testing
tags: [exunit, phoenix, lifecycle, isolation, github-actions]

requires:
  - phase: 164-01
    provides: Patched example-host dependency authority and the phase security tracer
provides:
  - Exact ownership-token cleanup for example-host Application state, BEAM paths, processes, and SQLite files
  - Deterministic three-seed tagged/full-suite isolation evidence with scoped residue detection
  - Parallel requires-example-host required lane with live-derived tagged-file reporting
affects: [164-gate-authority, 165-ci-efficiency, example-host-proof]

actuals:
  tokens: 5353
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns:
    - Idempotent ownership tokens register exact ExUnit cleanup at each mutation boundary
    - Already-started processes and pre-existing code paths remain explicitly unowned
    - Fixed-seed evidence compares scoped temp-resource and tracked-path snapshots per run

key-files:
  created:
    - test/crosswake/proof/phase164_example_host_isolation_test.exs
    - script/check_example_host_isolation.sh
  modified:
    - test/support/example_host.ex
    - .github/workflows/requires-example-host-gate.yml

key-decisions:
  - "Represent cleanup as an idempotent token so explicit proof cleanup and registered on_exit cleanup cannot act twice."
  - "Treat an already-started PID or pre-existing BEAM path as unowned and never stop or delete it."
  - "Keep the workflow's existing dev/test compile split and use the script's matrix-only mode for the same six non-serial runs."

patterns-established:
  - "Exact lifecycle restoration: snapshot presence with Application.fetch_env/2, register cleanup, then mutate."
  - "Evidence before deserialization: three fixed seeds exercise both the tagged class and complete suite with residue checks."

requirements-completed: [CIG-03]

coverage:
  - id: D1
    description: "Example-host helpers restore exact prior Application/path/process/file state while preserving unowned resources."
    requirement: CIG-03
    verification:
      - kind: unit
        ref: "mix test test/crosswake/proof/phase164_example_host_isolation_test.exs"
        status: pass
      - kind: integration
        ref: "mix test test/crosswake/proof/phase7_saas_lane_test.exs --only requires_example_host --seed 17"
        status: pass
    human_judgment: false
  - id: D2
    description: "Seeds 17, 101, and 1009 pass both the tagged and complete suites without scoped residue or serial max-cases."
    requirement: CIG-03
    verification:
      - kind: integration
        ref: "script/check_example_host_isolation.sh"
        status: pass
      - kind: unit
        ref: "script/check_example_host_isolation.sh --self-test-residue"
        status: pass
    human_judgment: false

duration: 14 min
completed: 2026-08-28
status: complete
---

# Phase 164 Plan 03: Example-Host Isolation Summary

**Exact example-host resource ownership now supports a residue-checked parallel matrix across three tagged and complete-suite seeds.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-08-28T19:35:00Z
- **Completed:** 2026-08-28T19:49:00Z
- **Tasks:** 2
- **Files modified:** 4 implementation files, plus summary and validation metadata

## Accomplishments

- Replaced detached global process lifetime with exact, idempotent ownership tokens for Application values, BEAM code paths, successful process starts, and unique SQLite paths.
- Added adversarial lifecycle proof for present/absent configuration, later-boundary failure, pre-existing paths and PIDs, concurrent unique files, and repeated cleanup.
- Added one canonical command that compiles the example host in dev, compiles the root in test, and runs all six required seed/class combinations with per-run scoped residue checks.
- Removed the serial `--max-cases 1` stopgap while preserving the required job identity, runner, triggers, and explicit dev/test compile split.

## Task Commits

1. **Task 1 RED:** `6c1ba3fb` — failing exact lifecycle proof
2. **Task 1 GREEN:** `6fcb3c0b` — owned example-host resource lifecycle
3. **Task 2 RED:** `892e5988` — failing six-run matrix and workflow contract
4. **Task 2 GREEN:** `fd2f2ae4` — residue-checked parallel evidence and lane update

## Files Created/Modified

- `test/support/example_host.ex` — exact prior-state snapshots, ownership tokens, and scoped cleanup.
- `test/crosswake/proof/phase164_example_host_isolation_test.exs` — lifecycle, negative-control, script, and workflow contract proof.
- `script/check_example_host_isolation.sh` — canonical dev/test compile plus six-run seed/class matrix.
- `.github/workflows/requires-example-host-gate.yml` — non-serial matrix invocation and live-derived tagged-file summary.

## Decisions Made

- Cleanup tokens use one atomic claimed bit so manual proof cleanup and ExUnit `on_exit` are jointly idempotent.
- A dedicated owner process keeps successfully started children alive across `setup_all` boundaries and stops only the child it started; `{:already_started, pid}` remains unowned.
- Residue comparison is deliberately limited to the helper's temp prefix and Plan 164-03 tracked paths, avoiding unrelated concurrent work while still detecting phase-scoped mutation.

## Deviations from Plan

None - plan executed exactly as written.

## TDD Gate Compliance

- Task 1 RED `6c1ba3fb` precedes GREEN `6fcb3c0b`.
- Task 2 RED `892e5988` precedes GREEN `fd2f2ae4`.
- Both RED runs failed on the intended missing lifecycle/matrix contracts; both GREEN checks passed.

## Verification Evidence

- Focused lifecycle proof: 7 tests, 0 failures.
- Real example-host SaaS setup: 10 tests, 0 failures at seed 17.
- Canonical matrix: tagged and complete classes passed at seeds 17, 101, and 1009.
- Each of the six runs retained identical before/after owned-temp and Plan 164-03 tracked-path snapshots.
- Matrix negative control returned nonzero with seed, class, residue kind, exact owned path, and remediation.

## Known Stubs

None.

## Threat Review

- T-164-06 is mitigated by exact state snapshots, owned-only cleanup, adversarial pre-existing resources, and idempotence proof.
- T-164-09 is mitigated by the retained fixed seed/class matrix and fail-fast residue diagnostics.
- No new product endpoint, auth path, schema trust boundary, Android surface, or adopter data was introduced.

## User Setup Required

None.

## Next Phase Readiness

- CIG-03 is executable and green without permanent serialization.
- Plan 164-02 can consume the canonical isolation command in the phase aggregate entry point.
- Phase 165 may optimize workflow topology only while preserving this named evidence and fail-closed behavior.

## Self-Check: PASSED

- Both created artifacts and both modified implementation artifacts exist on disk.
- RED/GREEN commits `6c1ba3fb`, `6fcb3c0b`, `892e5988`, and `fd2f2ae4` exist in repository history.
- The focused lifecycle proof and the complete six-run canonical matrix passed in this execution.

---
*Phase: 164-dependency-security-and-gate-authority*
*Completed: 2026-08-28*
