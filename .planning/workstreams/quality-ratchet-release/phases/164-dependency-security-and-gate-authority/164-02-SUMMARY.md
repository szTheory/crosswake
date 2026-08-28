---
phase: 164-dependency-security-and-gate-authority
plan: "02"
subsystem: infra
tags: [github-actions, branch-protection, exunit, ast, fail-closed]

requires:
  - phase: 164-01
    provides: Patched lock authorities and the dependency-security producer
  - phase: 164-03
    provides: Example-host lifecycle and six-run isolation matrix
  - phase: 164-04
    provides: Exact aggregator parity and closed result semantics
provides:
  - Strict full-producer and merge-blocking candidate inventory with exact workflow/job provenance
  - Bidirectional required-context audit with credential-free local authority and explicit UNVERIFIED remote reads
  - Executable-syntax ExUnit file ownership across default/hermetic and requires-example-host classes
  - One credential-free aggregate command for every Phase 164 security and gate-authority contract
affects: [165-ci-efficiency, required-check-governance, exunit-ownership]

actuals:
  tokens: 11658
  tasks: 3
  commits: 6

tech-stack:
  added: []
  patterns:
    - Local workflow authority completes before credentialed branch-policy reads
    - Full literal producers and merge-blocking registration candidates remain distinct inventory views
    - ExUnit ownership derives from parsed executable tag scope rather than lexical matches or counts

key-files:
  created:
    - script/check_exunit_ownership.exs
    - test/crosswake/proof/phase164_exunit_ownership_test.exs
    - script/check_phase164_dependency_security_and_gate_authority.sh
  modified:
    - script/list_merge_blocking_checks.py
    - script/check_required_checks_registered.sh
    - test/crosswake/proof/phase153_1_gate_integrity_test.exs

key-decisions:
  - "Treat an omitted workflow display name as GitHub's literal job-id fallback, while explicit empty and expression-bearing names fail closed."
  - "Keep established advisory/collateral/engine-only files outside the intended merge-blocking set; a skipped or otherwise unowned intended file still fails with remediation."
  - "Keep live governance unavailable as exit 3 UNVERIFIED after local proof; the aggregate invokes local-only mode and never requires credentials."

patterns-established:
  - "Bidirectional authority: registered contexts map to one full producer, and every local merge-blocking candidate maps to registration."
  - "Dependency-safe aggregate: both lock checks precede audits and proof, followed by inventory, ownership, isolation, and aggregation."

requirements-completed: [SEC-01, SEC-02, CIG-01, CIG-02]

coverage:
  - id: D1
    description: "Every merge-blocking context has one strict literal producer, and live required policy compares bidirectionally without treating unavailable authority as success."
    requirement: CIG-01
    verification:
      - kind: unit
        ref: "mix test test/crosswake/proof/phase153_1_gate_integrity_test.exs"
        status: pass
      - kind: integration
        ref: "python3 script/list_merge_blocking_checks.py --emitters && script/check_required_checks_registered.sh --local-only"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every intended ExUnit file has executable-tag evidence of default/hermetic or requires-example-host merge-blocking ownership."
    requirement: CIG-02
    verification:
      - kind: unit
        ref: "mix test test/crosswake/proof/phase164_exunit_ownership_test.exs"
        status: pass
      - kind: integration
        ref: "elixir script/check_exunit_ownership.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "One credential-free command proves lock coherence, both audits, all focused negative controls, isolation, and aggregator semantics in dependency-safe order."
    verification:
      - kind: integration
        ref: "script/check_phase164_dependency_security_and_gate_authority.sh"
        status: pass
    human_judgment: false

duration: 17 min
completed: 2026-08-28
status: complete
---

# Phase 164 Plan 02: Gate Authority and ExUnit Ownership Summary

**Strict workflow and executable-test ownership now compose every Phase 164 contract into one credential-free, fail-closed aggregate.**

## Performance

- **Duration:** 17 min
- **Started:** 2026-08-28T19:52:27Z
- **Completed:** 2026-08-28T20:09:26Z
- **Tasks:** 3
- **Files modified:** 6 implementation files, plus summary and validation metadata

## Accomplishments

- Replaced silent workflow parser recovery with deterministic malformed/type/name/cardinality failures and exact producer provenance across the final Wave 1/2 tree.
- Added bidirectional registered-policy comparison while preserving a fully credential-free local mode and exit 3 UNVERIFIED for unavailable live authority.
- Added an AST-based ExUnit ownership detector with module, describe, per-test, generated-test, comment/string, malformed, empty, and missing-lane controls.
- Added one phase aggregate that awaits both locked dependency checks before both audits, then runs every focused inventory, ownership, isolation, and aggregator proof.

## Task Commits

1. **Task 1 RED:** `2f01028b` — failing producer-authority and remote-boundary controls
2. **Task 1 GREEN:** `86ac31bc` — strict full-producer inventory and bidirectional audit
3. **Task 2 RED:** `637bc76c` — failing executable-syntax ownership controls
4. **Task 2 GREEN:** `f6219bcb` — AST ownership detector and live-tree proof
5. **Task 3:** `73e717bb` — credential-free aggregate Phase 164 command

## Files Created/Modified

- `script/list_merge_blocking_checks.py` — strict full/candidate producer inventory and diagnostics.
- `script/check_required_checks_registered.sh` — local-first bidirectional policy audit.
- `test/crosswake/proof/phase153_1_gate_integrity_test.exs` — malformed, duplicate, missing, local-only, and UNVERIFIED controls.
- `script/check_exunit_ownership.exs` — executable AST ownership classification.
- `test/crosswake/proof/phase164_exunit_ownership_test.exs` — live and synthetic ownership proof.
- `script/check_phase164_dependency_security_and_gate_authority.sh` — dependency-safe aggregate entry point.

## Decisions Made

- GitHub's omitted-name job-id fallback is itself literal authority; an explicitly empty or dynamic name is not.
- Local producer truth remains independent from registration policy, so the full producer map is broader than the merge-blocking registration candidate list.
- Advisory-only, collateral-only, and engine-present-only files retain their intentionally non-blocking posture; intended default/example-host files must be owned without skips or lexical inference.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The local Hex client reported an expired optional session during locked dependency resolution, then continued credential-free as designed; both projects resolved unchanged and both audits returned zero advisories.
- One collateral test file generates tests through a module-level `for`. The AST detector was extended on GREEN to recognize executable generated-test bodies without scanning comments or strings.

## TDD Gate Compliance

- Task 1 RED `2f01028b` failed 7 new authority controls before GREEN `86ac31bc` passed 12/12.
- Task 2 RED `637bc76c` failed all 7 ownership controls before GREEN `f6219bcb` passed 7/7 and the live inventory.

## Verification Evidence

- Final producer inventory: 88 literal producers and 27 unique merge-blocking candidates.
- Dependency-security proof: both lock checks unchanged, both audits at zero advisories, 7/7 negative-control tests green.
- Required-context proof: 12/12 tests green; local-only audit completed without `gh`.
- ExUnit ownership proof: live tree green; 7/7 syntax/scope/negative controls green.
- Isolation proof: tagged and complete classes passed at seeds 17, 101, and 1009 with no scoped residue.
- Aggregator proof: 10/10 structural tests and all 11 closed result classes plus missing/inverted controls green.

## Known Stubs

None.

## Threat Review

- T-164-01 and T-164-03 are mitigated by strict parsed inputs, literal provenance, cardinality checks, and hermetic malformed/dynamic negative controls.
- T-164-08 is mitigated by completing local proof before a remote read and retaining explicit exit 3 UNVERIFIED.
- No endpoint, authentication path, schema boundary, Android surface, adopter data, or branch-protection writer was introduced.

## User Setup Required

None. Live branch-policy registration remains the existing green-first post-main governance action and is not required for repository-local completion.

## Next Phase Readiness

- SEC-01..03 and CIG-01..04 now have one credential-free aggregate authority.
- Phase 165 can optimize CI topology only while preserving the stable producer names, ownership classes, and negative controls established here.

## Self-Check: PASSED

- All six implementation artifacts and this summary exist on disk; both new scripts are executable.
- RED/GREEN/task commits `2f01028b`, `86ac31bc`, `637bc76c`, `f6219bcb`, and `73e717bb` exist in repository history.
- The final aggregate passed every dependency, inventory, ownership, isolation, and aggregator section with no phase-scoped residue.

---
*Phase: 164-dependency-security-and-gate-authority*
*Completed: 2026-08-28*
