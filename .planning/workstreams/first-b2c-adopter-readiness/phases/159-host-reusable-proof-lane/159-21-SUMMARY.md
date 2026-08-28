---
phase: 159-host-reusable-proof-lane
plan: 21
subsystem: proof-lane browser verification
tags: [phoenix, playwright, typescript, generator, fail-closed]
requires:
  - phase: 159-20
    provides: same-tree proof gate and preserved proof-lane contracts
provides:
  - executable version-2 generated Playwright proof
  - typed fail-closed host adapter seam
  - isolated Phoenix rendered-output browser gate
affects: [proof-lane, generator, Phoenix browser corpus]
tech-stack:
  added: []
  patterns: [missing-only host adapters, isolated generated-output selection, provenance-gated templates]
key-files:
  created:
    - priv/templates/crosswake/proof_lane/e2e/support/proof_lane_host_adapter.ts.eex
    - test/fixtures/crosswake/proof_lane/phoenix_host/proof_lane_host_adapter.ts
  modified:
    - lib/crosswake/proof_lane/generator.ex
    - priv/templates/crosswake/proof_lane/e2e/proof_lane.spec.ts.eex
    - script/verify_phoenix_host_proof_lane.sh
    - test/crosswake/proof_lane/template_contract_test.exs
    - test/mix/tasks/crosswake_gen_proof_lane_test.exs
key-decisions:
  - Generated browser specs import exactly one host-owned adapter that defaults to a stable runtime denial.
  - Phoenix verification pre-seeds that adapter, then runs only freshly generated output through the existing browser lifecycle.
requirements-completed: [PROOF-01, PROOF-02, PROOF-03, PROOF-04]
coverage:
  - id: D1
    description: Version-2 executable generated Playwright proof with fail-closed host adapter.
    requirement: PROOF-01
    verification:
      - kind: unit
        ref: mix test test/crosswake/proof_lane/template_contract_test.exs test/mix/tasks/crosswake_gen_proof_lane_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Isolated Phoenix host executes only the freshly generated proof with backend, outbox, and duplicate assertions.
    requirement: PROOF-03
    verification:
      - kind: e2e
        ref: bash script/verify_phoenix_host_proof_lane.sh
        status: pass
    human_judgment: false
metrics:
  duration: 20m
  completed: 2026-08-01
status: complete
---

# Phase 159 Plan 21: Executable Generated Browser Proof Summary

Version-2 proof-lane generation now emits a real Playwright test that can run only through a typed host adapter, with Phoenix verification selecting isolated rendered output rather than the checked-in surrogate.

## Accomplishments

- Advanced generator provenance to template version 2 and added a missing-only, typed `proofLaneHostAdapter` file whose defaults reject with `PL-BROWSER-HOST-ADAPTER`.
- Replaced the inert generated browser template with an exact `runOfflineIslandProof(page, context, proofLaneHostAdapter, proofLaneConfig)` Playwright invocation.
- Added version-1 manifest/no-overwrite regression coverage and Phoenix-only adapter callbacks for the real browser, IndexedDB, backend, empty-outbox, and idempotency path.
- Rebuilt the Phoenix proof wrapper around a trap-cleaned isolated host that excludes the hand-maintained spec/support files, pre-supplies and hash-checks the host adapter, generates fresh output, typechecks it, and selects its exact spec.

## Verification

Passed:

- `mix test test/mix/tasks/crosswake_gen_proof_lane_test.exs test/crosswake/proof_lane/config_test.exs test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs test/crosswake/proof_lane/evidence_test.exs`
- `npm --prefix examples/phoenix_host run typecheck:offline-route-proof`
- `bash script/verify_phoenix_host_proof_lane.sh` — one isolated generated Playwright test passed.
- `bash -n script/verify_phoenix_host_proof_lane.sh`
- `mix format --check-formatted lib/crosswake/proof_lane/*.ex test/crosswake/proof_lane/*.exs test/mix/tasks/crosswake_gen_proof_lane_test.exs`

## Task Commits

1. Task 1 (TDD RED): `a3e5df37` — failing generated browser-proof contracts.
2. Task 1 (GREEN): `45dfc33f` — executable generated browser proof and adapter seam.
3. Task 2: `ca79aeda` — isolated Phoenix generated-output proof.
4. Task 2 correction: `0ecdf42d` — retained the wrapper executable bit.

## Decisions Made

- Version-1 manifests remain host-owned and fail read-only provenance checks; generation adds only newly missing files.
- The generated adapter is structurally complete but has no host authority until a host-owned implementation is supplied.
- The existing Phoenix Playwright configuration and webServer remain the only browser lifecycle authority; the generated spec is an additive member.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Recreated the temporary workspace layout required by Phoenix path dependencies.**
- **Found during:** Task 2
- **Issue:** A shallow temporary host copy could not resolve the existing Phoenix application's local dependency paths when its unchanged Playwright webServer started.
- **Fix:** The wrapper now creates an erased-on-exit workspace-shaped copy with existing dependencies linked only for execution.
- **Files modified:** `script/verify_phoenix_host_proof_lane.sh`
- **Verification:** The isolated typecheck and exact generated-spec Playwright command pass.
- **Committed in:** `ca79aeda`

**2. [Rule 1 - Bug] Restored the verification script executable bit.**
- **Found during:** Task 2
- **Issue:** Replacing the script content changed its tracked file mode.
- **Fix:** Restored mode `100755`.
- **Files modified:** `script/verify_phoenix_host_proof_lane.sh`
- **Verification:** Shell syntax and execution pass.
- **Committed in:** `0ecdf42d`

## Known Stubs

None. The generated default adapter intentionally rejects until a host supplies callbacks; this is the required fail-closed boundary, not an incomplete data path.

## Next Phase Readiness

The Phase 159 generated browser-proof gap is closed with automated evidence. TODO-002 and adopter-instance completeness remain `unknown_blocking`; Android and Phase 160–162 scopes remain unchanged.

## Self-Check: PASSED

- All generated template, fixture, wrapper, and regression-test files exist.
- Task commits `a3e5df37`, `45dfc33f`, `ca79aeda`, and `0ecdf42d` exist.
