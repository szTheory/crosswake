---
phase: 165-efficient-and-maintainable-ci
plan: 09
subsystem: ci
tags: [github-actions, branch-protection, manifest, actionlint, exunit]
requires:
  - phase: 165-efficient-and-maintainable-ci
    plan: 08
    provides: Forty required proof leaves, one classifier control node, and twenty-six compatibility contexts
provides:
  - One pull-request-only Crosswake CI owner for all recurring product proof
  - Exact forty-four-leaf, one-control, twenty-seven-compatibility authority graph
  - Visible non-authoritative brand visual evidence
  - One credential-free recurring Phase 165 structural gate
affects: [165-10, 165-11, 165-12, branch-protection, release-readiness]
actuals:
  tokens: 9660
  tasks: 3
  commits: 6
tech-stack:
  added: []
  patterns:
    - Literal required proof jobs with an exact manifest-to-static-needs contract
    - Visibly red advisory evidence with no compatibility or umbrella authority
    - Credential-free aggregate gates limited to recurring stable contracts
key-files:
  created:
    - script/check_phase165_efficient_ci.sh
  modified:
    - .github/workflows/crosswake-ci.yml
    - script/ci_leaf_manifest.json
    - script/check_ci_leaf_manifest.py
    - script/list_merge_blocking_checks.py
    - test/crosswake/proof/phase165_ci_integrity_test.exs
    - test/crosswake/proof/phase165_ci_policy_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/165-VALIDATION.md
key-decisions:
  - "Keep brand-visual visibly red but outside proof_leaves, required_control_nodes, umbrella needs, and compatibility projections."
  - "Schedule public-documentation brand, collateral, and Hex-page proof through the central classifier while keeping release-as staleness full-proof only."
  - "Keep live timing and branch-protection mutation outside the recurring Phase 165 gate."
patterns-established:
  - "Authority graph: proof_leaves union required_control_nodes equals umbrella static needs exactly; advisory and compatibility jobs remain outside that union."
  - "Recurring gate: compose stable local contracts with actionable section-specific remediation and no credentials or hosted timing thresholds."
requirements-completed: [CIP-02, CIP-04, CIP-05, CIP-07]
coverage:
  - id: D1
    description: Final recurring PR proof cohort has one Crosswake CI owner while release and advisory boundaries stay separate
    requirement: CIP-02
    verification:
      - kind: integration
        ref: mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only triggers --only release_trust
        status: pass
    human_judgment: false
  - id: D2
    description: Complete manifest, static needs, producers, compatibility contexts, and advisory exclusions are exact
    requirement: CIP-05
    verification:
      - kind: integration
        ref: python3 script/check_ci_leaf_manifest.py --self-test && python3 script/list_merge_blocking_checks.py --emitters
        status: pass
    human_judgment: false
  - id: D3
    description: One recurring command protects stable Phase 165 classification, cancellation, cache, runner, timeout, permission, trigger, and evidence contracts
    requirement: CIP-07
    verification:
      - kind: integration
        ref: script/check_phase165_efficient_ci.sh
        status: pass
    human_judgment: false
duration: 34 min
completed: 2026-09-08
status: complete
---

# Phase 165 Plan 09: Final PR Orchestration and Recurring Gate Summary

**One pull-request-only Crosswake CI graph now owns forty-four required proof leaves while preserving a visibly red, non-authoritative brand visual sibling and all twenty-seven frozen compatibility contexts.**

## Performance

- **Duration:** 34 min
- **Started:** 2026-09-08T17:57:00Z
- **Completed:** 2026-09-08T18:31:29Z
- **Tasks:** 3
- **Files modified:** 12

## Accomplishments

- Moved brand structural, collateral binary, Hex-page, and release-as staleness proof into the literal Crosswake CI PR graph after the live strict required-context snapshot passed.
- Sealed exact parity across forty-four required leaves, the success-only classifier control, static umbrella needs, all twenty-seven frozen compatibility contexts, and local producers.
- Added a credential-free recurring gate that composes stable classifier, cancellation, aggregator, manifest, producer, local-authority, evidence, ExUnit, and changed-workflow syntax checks.

## Task Commits

1. **Task 1 RED: final cohort migration contracts** - `886f4dff` (test)
2. **Task 1 GREEN: consolidate final PR proof cohort** - `bebcbcf8` (feat)
3. **Task 2 RED: complete final authority parity** - `a4e14aa2` (test)
4. **Task 2 GREEN: seal complete authority graph** - `5b64d5f3` (feat)
5. **Task 3 RED: recurring aggregate contract** - `a45eae75` (test)
6. **Task 3 GREEN: publish recurring efficient-CI gate** - `f31be61d` (feat)

## Files Created/Modified

- `script/check_phase165_efficient_ci.sh` - Runs the stable recurring Phase 165 contract suite with fail-fast remediation.
- `.github/workflows/crosswake-ci.yml` - Owns the final literal PR proof graph, advisory brand sibling, compatibility projection, and checkout-free umbrella.
- `script/ci_leaf_manifest.json` - Enumerates forty-four required leaves, one required control, and twenty-seven exact legacy contexts.
- `script/check_ci_leaf_manifest.py` - Enforces required authority parity and brand-visual isolation.
- `script/list_merge_blocking_checks.py` - Inventories the final migrated cohort and remains compatible with supported Python runtimes.
- `test/crosswake/proof/phase165_ci_integrity_test.exs` - Proves final trigger, release trust, workflow, and advisory topology.
- `test/crosswake/proof/phase165_ci_policy_test.exs` - Proves final cardinality, summary voice, and aggregate composition.
- `165-VALIDATION.md` - Records Nyquist-compliant CIP-01 through CIP-07 commands and observed local feedback latency.
- `.github/workflows/brandbook-verify.yml`, `.github/workflows/collateral-guard.yml`, `.github/workflows/hex-page-proof.yml`, `.github/workflows/release-as-staleness-gate.yml` - Deleted after live snapshot and replacement parity passed.

## Decisions Made

- `brand-visual` stays a literal job whose failure remains red; it has no `continue-on-error`, success wrapper, manifest authority, umbrella dependency, or compatibility projection.
- Public-documentation changes schedule focused documentation, brand, collateral, Hex-page, and Threadline proof; planning-only documentation keeps unrelated executable proof explicitly irrelevant.
- The recurring gate measures local structural feedback in count/time units but does not establish hosted-runner thresholds or mutate branch protection.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Restored Python 3.9-compatible producer inventory imports**
- **Found during:** Task 2 RED verification
- **Issue:** Importing `list_merge_blocking_checks.py` under the system Python evaluated the `str | None` annotation eagerly and failed before producer inventory.
- **Fix:** Added `from __future__ import annotations` without changing inventory behavior.
- **Files modified:** `script/list_merge_blocking_checks.py`
- **Verification:** Manifest self-tests and producer emission pass under the aggregate gate.
- **Committed in:** `5b64d5f3`

---

**Total deviations:** 1 auto-fixed (1 Rule 3)
**Impact on plan:** The compatibility repair was required for the planned structural gate and introduced no new authority or dependency.

## Issues Encountered

- Repository-wide `actionlint .github/workflows/*.yml` still reports two pre-existing diagnostics in untouched workflows: the Release Please `concurrency.queue` extension and an SC2016 warning in required-check audit. The changed Crosswake CI workflow passes actionlint, and the recurring aggregate gate is green. The broader non-passing command is recorded in `.planning/WINDOWS.md` rather than changing protected release authority in this plan.

## Known Stubs

None.

## Threat Flags

None. The consolidated PR workflow remains read-only, the umbrella remains checkout-free, and release/recovery permissions and secrets remain outside Crosswake CI.

## User Setup Required

None - no external service configuration or branch-protection mutation was performed.

## Next Phase Readiness

Plan 165-10 can run live PR and cancellation probes against the complete local graph. Required-check retirement remains exclusively owned by the later explicit approval gate.

## Self-Check: PASSED

- All created/modified plan files exist in the expected final state; the four retired duplicate source workflows are absent.
- All six TDD task commits exist.
- `script/check_phase165_efficient_ci.sh` passes with 44 required leaves, one control, 27 compatibility contexts, and local producer authority intact.
- The live required-context snapshot remained exact before source removal.

---
*Phase: 165-efficient-and-maintainable-ci*
*Completed: 2026-09-08*
