---
phase: 168-0-2-1-release-candidate-readiness
plan: "06"
subsystem: release-workflow
tags: [github-actions, release-please, hex, swiftpm, maven-central, tdd]
requires:
  - phase: 168-05
    provides: Four-mode iOS mirror policy with credential-free baseline, trusted rehearsal, ordinary publication, and exact-ref recovery
provides:
  - Trusted exact-candidate Hex and real-mirror rehearsal in existing workflow families without external mutation
  - One-approval merge-parent and identical-tree guard before Release Please tags or linked publication
  - Fixed independent Hex, iOS mirror, and Android publication graph with dependency-gated public proofs
  - Schema-versioned COMPLETE/PARTIAL/BLOCKED rollup retaining exact public coordinates and exact-ref recovery identity
affects: [168-exact-candidate-capture, 168-release-dossier, linked-0.2.1-release]
actuals:
  tokens: 21841
  tasks: 3
  commits: 6
plan_head_before: 37c7ec72ac9d46b1d96a409abfa0826ec0065d9e
tech-stack:
  added: []
  patterns: [trusted-no-mutation-rehearsal, approved-merge-tree-guard, independent-publication-children, immutable-partial-rollup, exact-ref-idempotent-recovery]
key-files:
  created:
    - lib/crosswake/release_candidate/workflow.ex
    - script/release_candidate/android_publication.sh
    - test/crosswake/release_candidate/workflow_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/168-06-task1-red.json
    - .planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/168-06-task2-red.json
    - .planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/168-06-task3-red.json
  modified:
    - .github/workflows/release-please.yml
    - .github/workflows/hex-publish.yml
    - .github/workflows/ios-mirror-backfill.yml
    - script/guarded_hex_publish.sh
    - script/check_release_workflow_integrity.exs
    - lib/crosswake/release_candidate/receipt.ex
key-decisions:
  - "Run exact-head package and real-mirror rehearsal inside the existing trusted Hex and iOS workflow families, keeping all rehearsal paths unable to publish."
  - "Require the approved candidate as the merge commit's second parent and require identical candidate/merge trees before Release Please can create tags or any linked child can publish."
  - "Schedule Hex, iOS mirror, and Android publication independently after the shared guard; stop only their dependent proofs so sibling failure cannot hide completed public work."
  - "Persist partial release truth through one executable Elixir policy and allow ordinary recovery only from exact immutable identity or a forward-fix release."
patterns-established:
  - "One-way release jobs share exact approved head/tree/merge/receipt identity and have no second environment approval."
  - "Rollups normalize GitHub child results, validate dependency-success claims, retain immutable successful coordinates, and fail the job only after writing the status artifact."
requirements-completed: []
requirements-addressed: [REL-02, REL-03, REL-04, REL-05]
coverage:
  - id: trusted-existing-workflow-rehearsal
    description: Existing Hex and iOS workflow families rehearse the exact candidate with bound run/workflow identity and no external mutation.
    requirement: REL-04
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/workflow_test.exs#trusted rehearsal contracts"
        status: pass
      - kind: integration
        ref: "actionlint .github/workflows/hex-publish.yml .github/workflows/ios-mirror-backfill.yml"
        status: pass
    human_judgment: false
  - id: guarded-linked-publication-graph
    description: The one approved merge must contain the approved head and identical tree before the fixed Hex/iOS/Android 0.2.1 graph can tag or publish.
    requirement: REL-05
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/workflow_test.exs#approved merge and fixed graph contracts"
        status: pass
      - kind: integration
        ref: "elixir script/check_release_workflow_integrity.exs"
        status: pass
    human_judgment: false
  - id: immutable-partial-truth-and-recovery
    description: Every child-failure position retains exact prior public coordinates and one exact-ref or forward-fix recovery action; COMPLETE requires all six children.
    requirement: REL-05
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/workflow_test.exs#failure-at-every-child and hostile recovery fixtures"
        status: pass
      - kind: integration
        ref: "manual CLI projection through Crosswake.ReleaseCandidate.Workflow.evaluate_cli!/0"
        status: pass
    human_judgment: false
duration: 60m
completed: 2026-09-13
status: complete
---

# Phase 168 Plan 06: Trusted Rehearsal and Guarded Release Graph Summary

**Existing trusted workflows now rehearse an exact candidate without mutation, then require one approved merge with an identical tree before an honest, independently observable Hex/iOS/Android 0.2.1 release graph can run.**

## Performance

- **Duration:** 60m
- **Started:** 2026-09-13T04:28:26Z
- **Completed:** 2026-09-13T05:28:01Z
- **Tasks:** 3
- **Files modified:** 12
- **Commits:** 6 measured from `37c7ec72ac9d46b1d96a409abfa0826ec0065d9e`

## Accomplishments

- Extended the existing trusted Hex and iOS workflows with exact-head candidate rehearsal, workflow/run/digest binding, scoped mirror authority, bounded evidence, and `external_state_changed=false`.
- Added an approval guard before Release Please itself: linked 0.2.1 release requires a two-parent merge whose second parent is the approved head and whose tree is byte-identical to the approved candidate tree and READY receipt.
- Wired exactly the root Hex, iOS mirror, and Android core coordinates as independent publication children, with platform proofs and exact-public proof stopped by their actual dependencies.
- Replaced shell-only rollup inference with a schema-versioned executable policy that proves every failure position, retains irreversible successes, and emits exact failed identity plus one safe recovery action.
- Added exact-identity Hex recovery and idempotent Android recovery without mutable refs, package replacement, tag movement, routine force, new workflow families, companion publication, or release credentials during this plan.

## Task Commits

1. **Task 1 RED: trusted rehearsal workflow contract** — `b4f98b68`
2. **Task 1 GREEN: trusted exact-candidate rehearsal** — `0635c9ca`
3. **Task 2 RED: approved release graph contract** — `b9e0ef50`
4. **Task 2 GREEN: merge/tree-guarded linked graph** — `376239bf`
5. **Task 3 RED: immutable partial/recovery contract** — `88bc7c2b`
6. **Task 3 GREEN: partial truth and exact-ref recovery** — `c62471a3`

## Evidence and Verification

- All three plan verification commands passed from committed HEAD.
- `test/crosswake/release_candidate/workflow_test.exs` passed 8 tests with zero failures, including a failure at each of the six linked child positions.
- The complete release-candidate directory passed 40 tests serially with zero failures.
- `script/check_release_workflow_integrity.exs` passed every release, approval, rehearsal, graph, immutable-publication, and recovery check.
- `actionlint` passed all three changed workflows; `mix compile --warnings-as-errors`, shell syntax checks, formatting, and `git diff --check` passed.
- A direct PARTIAL CLI projection exited non-zero only after persisting valid JSON with the exact Hex/Android successes, failed iOS step/ref, and exact-ref-or-forward-fix action.
- No workflow was dispatched, no release credential was loaded, and no ref, tag, mirror, or package registry was mutated.

## TDD Gate Compliance

| Task | RED | GREEN | REFACTOR | Status |
|------|-----|-------|----------|--------|
| Trusted existing-workflow rehearsal | `b4f98b68` | `0635c9ca` | included in GREEN | Pass |
| Approved merge/tree release graph | `b9e0ef50` | `376239bf` | included in GREEN | Pass |
| Partial truth and exact-ref recovery | `88bc7c2b` | `c62471a3` | included in GREEN | Pass |

All three intentional RED records were validated with `gsd_run check tdd-red-evidence` before implementation. The committed GREEN implementation passes the focused suite and the complete release-candidate suite.

## Decisions Made

- Rehearsal remains in existing trusted workflow families: Hex rehearsal never receives registry credentials, while the mirror key exists only in the candidate rehearsal job that proves a no-change porcelain push.
- The approved merge/tree guard is a dependency of Release Please, not merely publication jobs, so changed-tree or stale-identity merges stop before semantic tags.
- Registry and mirror publications are independent siblings after the common guard; clean-room and exact-public proofs retain narrow dependency edges.
- Partial truth is executable domain policy rather than duplicated workflow shell. GitHub `failure`/`cancelled` observations normalize to `failed`, while dependency-impossible successes and mutable identities are rejected.
- Root 0.2.1 recovery rechecks approved head/tree/merge/receipt identity. Android recovery treats an already-live exact Maven coordinate as success and publishes only after an unambiguous 404.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added a reusable executable linked-release workflow policy**
- **Found during:** Task 3 (partial public truth and exact-ref recovery)
- **Issue:** The plan required failure-at-each-child fixtures and retained D-19 state, but its file list named only workflow shell and tests; leaving the policy inline would make hostile state validation and loss-of-success detection non-executable.
- **Fix:** Added `Crosswake.ReleaseCandidate.Workflow` with closed child/status sets, dependency validation, deterministic public coordinates, canonical validation, receipt external-state projection, and workflow CLI persistence.
- **Files modified:** `lib/crosswake/release_candidate/workflow.ex`, `.github/workflows/release-please.yml`
- **Verification:** Six failure-position fixtures, COMPLETE and hostile resume fixtures, direct PARTIAL CLI projection, and the integrity scanner all pass.
- **Committed in:** `c62471a3`

**2. [Rule 1 - Bug] Allowed the fixed Maven group/artifact coordinate in candidate receipts**
- **Found during:** Task 3 (receipt integration)
- **Issue:** The existing receipt coordinate validator allowed only one namespace separator, so the required `maven:io.crosswake:crosswake-shell-core@0.2.1` coordinate could not flow into D-19 receipt state.
- **Fix:** Kept the bounded lowercase coordinate grammar while allowing a colon inside the ecosystem-specific coordinate body.
- **Files modified:** `lib/crosswake/release_candidate/receipt.ex`
- **Verification:** Release-candidate suite passes 40 tests and the policy emits all three fixed coordinates in COMPLETE state.
- **Committed in:** `c62471a3`

**Total deviations:** 2 auto-fixed (1 Rule 2 critical functionality, 1 Rule 1 correctness fix).
**Impact on plan:** Both fixes are confined to the planned release graph and make its required partial-state contract executable and receipt-compatible; no package, platform, credential, or approval scope widened.

### AGENTS.md-driven adjustments

- `REL-02`, `REL-03`, `REL-04`, and `REL-05` remain pending in `REQUIREMENTS.md`. This plan wires and proves the workflow layer, while Plans 168-07 and 168-08 still own trusted candidate capture, dossier/CI integration, and final release evidence.
- No workflow was triggered and no publication, tag, push, companion mutation, or credentialed external action was performed.

## Issues Encountered

- One parallel full-directory test run hit a shared mirror fixture JSON read race. The exact failing case passed immediately in isolation, and the complete release-candidate suite passed all 40 tests with `--max-cases 1`; no production or fixture change was required.

## Known Stubs

None. Workflow jobs are intentionally event/approval gated and fail closed; they are not placeholder success paths.

## Threat Review

- T-168-16 is mitigated before Release Please tags and repeated inside Hex/Android publication helpers by exact approved-head parentage, identical approved/merge trees, exact merge checkout, and candidate receipt digest.
- T-168-17 is mitigated by read-only workflow permissions, step/job-scoped secrets, a credential-free public baseline, a no-registry-credential Hex rehearsal, bounded allowlisted evidence, and no credential serialization.
- T-168-18 is mitigated by persisted exact child states, deterministic successful coordinates, dependency-impossible state rejection, PARTIAL classification, and immutable exact-ref/forward-fix recovery.
- All new release mutation surfaces were named in the plan threat model; no unplanned network endpoint, application auth route, file trust boundary, or schema change was introduced.

## User Setup Required

None. Future trusted execution uses existing repository secrets; this plan did not access or modify them.

## Next Phase Readiness

Plan 168-07 can bind the final refreshed candidate receipt to the exact trusted CI and rehearsal artifacts consumed by the approval guard. The graph is structurally ready but remains intentionally dormant until the later one explicit merge approval.

## Self-Check: PASSED

All declared workflow, policy, adapter, test, and summary artifacts exist; all six measured task commits are reachable; and the final focused, structural, syntax, formatting, and serial release-candidate verification commands pass.

---
*Phase: 168-0-2-1-release-candidate-readiness*
*Completed: 2026-09-13*
