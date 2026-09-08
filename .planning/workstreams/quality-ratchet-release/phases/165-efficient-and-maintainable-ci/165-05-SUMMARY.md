---
phase: 165-efficient-and-maintainable-ci
plan: 05
subsystem: ci
tags: [github-actions, migration, branch-protection, hermetic-proof, compatibility]
requires:
  - phase: 165-efficient-and-maintainable-ci
    plan: 02
    provides: closed classifier, exact leaf manifest, and maximum-shape proof
  - phase: 165-efficient-and-maintainable-ci
    plan: 04
    provides: portable runner, exact cache identity, and timeout contracts
provides:
  - Twelve literal Crosswake CI proof leaves with exact static umbrella authority
  - Ten checkout-free legacy compatibility contexts backed by the closed umbrella
  - Scheduled and manual engine/commerce advisories isolated from PR concurrency
affects: [165-06, 165-07, 165-08, 165-09, 165-10, 165-11, 165-12]
actuals:
  tokens: 23450
  tasks: 3
  commits: 6
tech-stack:
  added: []
  patterns:
    - Purpose-named PR leaves behind one checkout-free closed umbrella
    - Migration-only compatibility contexts depend on the umbrella and never join its authority set
    - Scheduled and manual advisories remain non-cancelling in source-qualified workflows
key-files:
  created: []
  modified:
    - .github/workflows/crosswake-ci.yml
    - .github/workflows/phase130-proof.yml
    - .github/workflows/phase132-proof.yml
    - .github/workflows/phase23-proof.yml
    - .github/workflows/phase34-proof.yml
    - script/ci_leaf_manifest.json
    - script/check_ci_leaf_manifest.py
    - script/list_merge_blocking_checks.py
    - test/crosswake/proof/phase165_ci_integrity_test.exs
key-decisions:
  - "Bind migration-only legacy contexts to the checkout-free Crosswake CI umbrella so explicitly irrelevant documentation-only leaves remain compatible while every unexplained non-success stays closed."
  - "Retain weekly/manual engine and commerce advisories as non-cancelling source-qualified workflows with no pull-request or generic push trigger."
patterns-established:
  - "Authority boundary: proof_leaves union required_control_nodes equals umbrella static needs exactly; compatibility conclusions remain outside both sets."
  - "Trigger boundary: Crosswake CI owns recurring PR product proof, while retained advisory workflows own only schedule and workflow_dispatch."
requirements-completed: [CIP-02, CIP-05, CIP-07]
coverage:
  - id: D1
    description: Core gate-integrity, security, contract, and example-host proof runs as literal Crosswake CI leaves with closed legacy compatibility contexts.
    requirement: CIP-07
    verification:
      - kind: integration
        ref: actionlint .github/workflows/crosswake-ci.yml && python3 script/check_aggregator_result_semantics.py --self-test && mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only triggers
        status: pass
    human_judgment: false
  - id: D2
    description: Hermetic engine and commerce PR proof is consolidated while scheduled/manual advisories retain separate non-cancelling authority.
    requirement: CIP-02
    verification:
      - kind: integration
        ref: actionlint .github/workflows/phase130-proof.yml .github/workflows/phase132-proof.yml .github/workflows/phase23-proof.yml .github/workflows/phase34-proof.yml && python3 script/list_merge_blocking_checks.py --emitters
        status: pass
    human_judgment: false
  - id: D3
    description: The first migrated cohort has exact manifest, static-needs, compatibility, trigger, timeout, runner, and producer parity.
    requirement: CIP-05
    verification:
      - kind: integration
        ref: python3 script/check_ci_leaf_manifest.py --self-test && mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only triggers --only manifest
        status: pass
      - kind: other
        ref: script/check_required_checks_registered.sh --local-only
        status: pass
    human_judgment: false
duration: 15h 9m
completed: 2026-09-08
status: complete
---

# Phase 165 Plan 05: Core and Hermetic CI Migration Summary

**Core, security, example-host, hermetic-engine, and commerce PR proof now runs once as twelve literal Crosswake CI leaves while ten frozen legacy contexts and scheduled advisories retain their distinct authority.**

## Performance

- **Duration:** 15h 9m wall time
- **Started:** 2026-09-08T01:20:24Z
- **Completed:** 2026-09-08T16:29:54Z
- **Tasks:** 3
- **Files modified:** 13

## Accomplishments

- Moved aggregator semantics, contract drift, dependency security, and example-host isolation into purpose-named Crosswake CI leaves, deleting their four duplicate PR/push workflow producers only after the live strict 27-context snapshot matched.
- Moved distinct Phase 130/132 hermetic and engine-absent proof plus Phase 23/34 commerce proof into six literal PR leaves while retaining weekly/manual advisory jobs outside PR concurrency.
- Expanded the manifest and structural audits to prove twelve leaves plus `classify-change` exactly equal umbrella needs, ten compatibility conclusions stay outside that set, documentation-only skips require the manifest-authorized reason, and no generic push duplicate remains.

## Task Commits

Each TDD task was committed with a failing contract before implementation:

1. **Task 1 RED: core migration contracts** - `26c9d553` (test)
2. **Task 1 GREEN: core integrity leaves and compatibility contexts** - `ea405cf0` (feat)
3. **Task 2 RED: hermetic migration contracts** - `0fd19cd2` (test)
4. **Task 2 GREEN: engine and commerce PR consolidation** - `7cd5f01b` (feat)
5. **Task 3 RED: migrated-cohort parity contracts** - `97fb6942` (test)
6. **Task 3 GREEN: exact manifest and trigger authority** - `cccd61c4` (feat)

## Files Created/Modified

- `.github/workflows/crosswake-ci.yml` - Owns twelve governed proof leaves, one classifier control, the closed umbrella, and ten migration-only compatibility conclusions.
- `.github/workflows/phase130-proof.yml` and `.github/workflows/phase132-proof.yml` - Retain only weekly/manual non-cancelling engine-present advisories.
- `.github/workflows/phase23-proof.yml` and `.github/workflows/phase34-proof.yml` - Retain only weekly/manual non-cancelling commerce advisories.
- `script/ci_leaf_manifest.json` - Records exact display names, families, remediation commands, irrelevance reasons, and compatibility targets.
- `script/check_ci_leaf_manifest.py` - Enforces compatibility schema, closed setup boundaries, remediation parity, executable conditions, and direct negative controls.
- `script/list_merge_blocking_checks.py` - Rejects migrated source triggers/jobs and any Crosswake CI event beyond `pull_request`.
- `test/crosswake/proof/phase165_ci_integrity_test.exs` - Proves trigger separation, literal evidence, source advisory posture, and exact manifest graph parity.
- `.github/workflows/aggregator-negative-control.yml`, `.github/workflows/contract-drift-gate.yml`, `.github/workflows/dependency-security.yml`, and `.github/workflows/requires-example-host-gate.yml` - Deleted after their proof and legacy contexts moved atomically.

## Decisions Made

- Compatibility contexts depend on `merge-blocking-crosswake-ci`, not directly on a conditional executable leaf. This preserves frozen required names on documentation-only PRs while inheriting the umbrella's fail-closed handling of failure, cancellation, missing, timed-out, stale, action-required, unknown, and unexplained skipped results.
- Source-qualified engine and commerce workflows retain only `schedule` and `workflow_dispatch`, use run-scoped non-cancelling groups, and do not enter Crosswake CI PR concurrency.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The user-owned `.tool-versions` edit names locally unavailable toolchains. Mix verification used command-scoped installed Erlang 28.4.1 and Elixir 1.19.5-otp-28 without changing or staging that file.
- Wall time includes an overnight/session pause; every automated gate was rerun against the final tree.

## Known Stubs

None. The retained advisory messages explicitly state the existing no-provider non-claim; they are not product implementations or merge authority.

## User Setup Required

None - no credential, remote mutation, package installation, branch-protection write, or human verification was required.

## Next Phase Readiness

Plan 165-06 can migrate the first domain-proof cohort against the same static manifest/compatibility pattern. The live strict required-context snapshot remains byte-consistent with the Plan 01 authority artifact, and Plan 165-12 still exclusively owns legacy-context retirement.

## Self-Check: PASSED

- All nine retained owned files exist and the four planned source workflow deletions are present in Git.
- All six TDD task commits resolve.
- Actionlint, aggregator semantics, manifest direct negatives, maximum-shape, producer/trigger audit, all 17 Phase 165 integrity tests, the live snapshot verifier, and the local required-check audit passed on the final tree.

---
*Phase: 165-efficient-and-maintainable-ci*
*Completed: 2026-09-08*
