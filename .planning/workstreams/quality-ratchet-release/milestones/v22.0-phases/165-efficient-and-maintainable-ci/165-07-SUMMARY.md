---
phase: 165-efficient-and-maintainable-ci
plan: 07
subsystem: ci
tags: [github-actions, classification, manifest, compatibility, privacy]
requires:
  - phase: 165-efficient-and-maintainable-ci
    plan: 06
    provides: centrally classified domain proof leaves and frozen-context compatibility jobs
provides:
  - Four literal notification, auth-sensitive, offline-recovery, and closeout PR proof leaves
  - Removal of the last phase-local documentation relevance classifier
  - Exact 24-leaf, one-control, and 22-compatibility domain authority graph
affects: [165-08, 165-09, 165-10, 165-11, 165-12]
actuals:
  tokens: 8077
  tasks: 2
  commits: 6
tech-stack:
  added: []
  patterns:
    - Central fail-closed classification with literal full-proof leaves
    - Checkout-free legacy compatibility conclusions outside umbrella authority
    - Scheduled advisory workflows without PR or generic-push product proof
key-files:
  created: []
  modified:
    - .github/workflows/crosswake-ci.yml
    - .github/workflows/phase71-proof.yml
    - .github/workflows/phase73-proof.yml
    - .github/workflows/phase74-proof.yml
    - .github/workflows/phase75-closeout-gate.yml
    - script/ci_leaf_manifest.json
    - script/check_ci_leaf_manifest.py
    - script/list_merge_blocking_checks.py
    - test/crosswake/proof/phase165_ci_integrity_test.exs
    - test/crosswake/proof/phase165_ci_policy_test.exs
key-decisions:
  - "Retain Phase 71, 73, and 74 scheduled/manual work only as explicitly non-promoting advisory authority; Phase 75 has no distinct advisory boundary and is deleted."
  - "Accept executable-leaf irrelevance only for the classifier's exact all_changed_paths_allowlisted reason while documentation-contracts remains the planning privacy owner."
patterns-established:
  - "Domain migration: each source command becomes one literal full-proof leaf and each frozen required context becomes one checkout-free umbrella-dependent compatibility job."
  - "Advisory separation: retained phase workflows expose schedule/workflow_dispatch only and cannot duplicate PR or generic-push product proof."
requirements-completed: [CIP-02, CIP-05, CIP-07]
coverage:
  - id: D1
    description: Notification, auth-sensitive admin, offline draft recovery, and closeout proof run as literal centrally classified PR leaves
    requirement: CIP-07
    verification:
      - kind: integration
        ref: actionlint workflows plus phase165_ci_integrity_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Documentation-only planning changes retain first-adopter privacy proof while malformed or executable changes run full proof
    requirement: CIP-05
    verification:
      - kind: integration
        ref: classify_ci_change.py --self-test plus phase165_ci_policy_test.exs
        status: pass
    human_judgment: false
  - id: D3
    description: Plans 05 through 07 have exact leaf, control, compatibility, producer, and trigger authority without live branch-protection mutation
    requirement: CIP-02
    verification:
      - kind: integration
        ref: check_ci_leaf_manifest.py --self-test plus list_merge_blocking_checks.py --emitters and check_required_checks_registered.sh --local-only
        status: pass
    human_judgment: false
duration: 14 min
completed: 2026-09-08
status: complete
---

# Phase 165 Plan 07: Remaining Phase-Era Domain CI Migration Summary

**Four named domain proof leaves now run once through the central classifier, with privacy-safe documentation scheduling and exact frozen-context compatibility preserved.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-09-08T16:58:21Z
- **Completed:** 2026-09-08T17:11:41Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Moved Phase 71 notification, Phase 73 auth-sensitive admin, Phase 74 offline-draft recovery, and Phase 75 closeout proof into four literal Linux leaves gated by the central `full_proof` classification.
- Removed Phase 75's inline diff/grep classifier while keeping `documentation-contracts` responsible for the first-adopter planning privacy scan and defaulting malformed classification inputs to visible full proof.
- Reconciled 24 proof leaves, `classify-change`, 22 checkout-free compatibility jobs, static umbrella needs, exact remediation strings, and source trigger authority without changing live required checks.

## Task Commits

Both TDD tasks were committed with failing contracts before implementation:

1. **Task 1 RED: domain migration contracts** - `571d43b0` (test)
2. **Task 1 GREEN: retire source authority and Phase 75 classifier** - `cd912e46` (feat)
3. **Task 1 GREEN: add central leaves and compatibility conclusions** - `e48cfc3b` (feat)
4. **Task 2 RED: final domain manifest contracts** - `45e06ecf` (test)
5. **Task 2 GREEN: exact domain manifest and producer authority** - `d97e1377` (feat)
6. **Rule 2: keep the Plan 01 documentation policy gate current** - `f1e23f65` (test)

## Files Created/Modified

- `.github/workflows/crosswake-ci.yml` - Adds four literal full-proof leaves, four frozen-context compatibility conclusions, and exact umbrella closure.
- `.github/workflows/phase71-proof.yml` and `.github/workflows/phase73-proof.yml` - Retain only scheduled/manual non-promoting advisory jobs.
- `.github/workflows/phase74-proof.yml` - Converts the retained scheduled/manual recovery lane into an explicitly advisory sibling.
- `.github/workflows/phase75-closeout-gate.yml` - Deleted after moving its proof and removing its phase-local classifier.
- `script/ci_leaf_manifest.json` - Declares the complete 24-leaf and 22-compatibility Plan 05-07 graph.
- `script/check_ci_leaf_manifest.py` - Requires the exact classifier-issued irrelevance reason and tests its rejection path.
- `script/list_merge_blocking_checks.py` - Audits every Plan 05-07 source workflow and migrated job ID for duplicate trigger authority.
- `test/crosswake/proof/phase165_ci_integrity_test.exs` - Proves literal leaves, exact contexts, retained advisory boundaries, and static manifest parity.
- `test/crosswake/proof/phase165_ci_policy_test.exs` - Keeps the original documentation/privacy policy gate valid against the expanded graph.

## Decisions Made

- Phase 71 and Phase 73 retain their existing non-delivery/non-promoting advisory jobs; their merge-blocking jobs moved completely into Crosswake CI.
- Phase 74 retains schedule/manual proof only as an explicitly named `continue-on-error` advisory sibling outside all manifest authority sets.
- Phase 75 is deleted because its only job was recurring product proof and its inline classifier was superseded by the central closed classifier.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Updated the original documentation policy gate for the expanded graph**

- **Found during:** Plan-level verification
- **Issue:** The Plan 01 policy test still asserted the one-leaf tracer cardinality and inline two-item `needs` form, so the required docs-only gate no longer described the intentionally migrated graph.
- **Fix:** Replaced tracer cardinality assumptions with durable privacy-owner, exact-irrelevance, static-needs, and fail-closed umbrella invariants.
- **Files modified:** `test/crosswake/proof/phase165_ci_policy_test.exs`
- **Verification:** All 9 policy tests pass together with classifier and manifest self-tests.
- **Committed in:** `f1e23f65`

---

**Total deviations:** 1 auto-fixed (1 missing critical recurring contract)
**Impact on plan:** The fix restores the explicitly required Plan 01 policy gate without changing production behavior or widening scope.

## Issues Encountered

- Task 1's GREEN changes landed in two commits after an explicit staging command rejected one mistyped path before staging. Both commits are plan-owned, hooks ran normally, and the combined task verification passed.
- The user-owned `.tool-versions` edit names locally unavailable Erlang/Elixir builds. Mix verification used command-scoped installed versions (`Erlang 28.4.1`, `Elixir 1.19.5-otp-28`) without modifying or staging that file.

## Known Stubs

None.

## Authentication Gates

None. The read-only live required-context snapshot verification succeeded without an authentication interruption.

## User Setup Required

None - no remote mutation, credential change, or external service configuration was required.

## Next Phase Readiness

Plan 165-08 can migrate native, browser, package, and cross-runtime proof against a 24-leaf centrally classified graph. The live strict 27-context registration remains unchanged and valid.

## Self-Check: PASSED

- All nine retained modified files exist and the intentional Phase 75 workflow deletion is present.
- All six Plan 165-07 production/TDD commits resolve in Git.
- Actionlint, classifier and manifest self-tests, 20 integrity tests, 9 policy tests, local producer authority, and live required-context snapshot verification pass.

---
*Phase: 165-efficient-and-maintainable-ci*
*Completed: 2026-09-08*
