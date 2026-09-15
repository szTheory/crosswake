---
phase: 168-0-2-1-release-candidate-readiness
plan: "07"
subsystem: release-readiness
tags: [github-actions, release-candidate, release-status, operator-runbook, tdd]
requires:
  - phase: 168-06
    provides: Trusted no-mutation rehearsal and merge/tree-guarded linked publication graph
provides:
  - Fast stable candidate fixtures on every pull request in the existing Crosswake CI family
  - Fail-open release-sensitive routing to exact-head six-artifact and five-profile proof
  - Credential-free exact CI receipt bound to head, tree, base, run, artifacts, and clean-room result
  - Read-only linked 0.2.1 candidate status with baseline/public mirror truth and bounded correction
  - Seven-step maintainer sequence with five states and one exact-head approval
affects: [168-exact-candidate-capture, 168-release-dossier, linked-0.2.1-release]
actuals:
  tokens: 16494
  tasks: 2
  commits: 4
plan_head_before: 82125a604c54e8dfd59d973b326358ae7ff4a337
tech-stack:
  added: []
  patterns: [fail-open-candidate-routing, exact-head-ci-receipt, read-only-linked-status, single-approval-runbook]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/168-07-task1-red.json
    - .planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/168-07-task2-red.json
  modified:
    - .github/workflows/crosswake-ci.yml
    - script/ci_leaf_manifest.json
    - script/check_ci_leaf_manifest.py
    - script/check_release_workflow_integrity.exs
    - lib/crosswake/release_status.ex
    - lib/mix/tasks/crosswake.release.status.ex
    - docs/COMPANION-PUBLISH-RUNBOOK.md
    - test/crosswake/proof/phase166_repository_quality_test.exs
    - test/crosswake/guides/release_boundaries_test.exs
    - test/mix/tasks/crosswake_release_status_test.exs
key-decisions:
  - "Keep stable candidate fixtures always-on, but run the generated six-package/five-profile matrix only for release-sensitive inputs, Release Please candidate branches, or ambiguous classification."
  - "Keep ordinary PR CI credential-free and leave real mirror authorization exclusively in the existing trusted release workflow."
  - "Treat live linked-coordinate state as BLOCKED, PARTIAL, or COMPLETE while reserving READY FOR APPROVAL and STALE for the exact candidate receipt authority."
  - "Keep one-time live reconciliation in phase evidence rather than creating another recurring workflow lane."
patterns-established:
  - "A separate candidate scope augments the existing docs/full classifier without weakening its fail-open full-proof default."
  - "Operator status reports one bounded state and one next action while retaining baseline and public candidate refs separately."
requirements-completed: []
requirements-addressed: [REL-01, REL-02, REL-03, REL-04, REL-05]
duration: 22m
completed: 2026-09-13
status: complete
---

# Phase 168 Plan 07: Candidate CI and Operator Boundary Summary

**The existing Crosswake CI now provides fast candidate feedback on ordinary PRs and exact-head full local proof at release boundaries, paired with read-only linked-coordinate status and one seven-step approval runbook.**

## Performance

- **Duration:** 22m
- **Started:** 2026-09-13T12:45:21Z
- **Completed:** 2026-09-13T13:07:31Z
- **Tasks:** 2
- **Files modified:** 14
- **Commits:** 4 measured from `82125a604c54e8dfd59d973b326358ae7ff4a337`

## Accomplishments

- Added two governed leaves to the existing `Crosswake CI`: stable candidate fixtures always run, while the expensive local matrix runs only for tracked release inputs, Release Please candidate branches, or ambiguous checkout/object/diff state.
- Bound the full lane to the exact pull-request head and retained a canonical credential-free receipt with head, tree, base, workflow run identity, six-package/five-profile/two-install counts, and artifact/result digests.
- Extended workflow integrity and leaf-manifest authorities so missing leaves, unknown reasons, stale identity, vacuous counts, absent receipts, or accidental credentials block success.
- Extended `mix crosswake.release.status` with a closed read-only `0.2.1` projection for linked Hex/iOS/Android coordinates, independent companions, `v0.2.0` baseline versus `v0.2.1` public mirror truth, and one correction.
- Replaced the Phase 167 stop note with the exact seven-step operator sequence, five-state interpretation, candidate-local versus exact-public proof, ordinary publication versus recovery, explicit exclusions, and one merge approval.

## Task Commits

1. **Task 1 RED: candidate CI proof boundary** — `c1aa95f7`
2. **Task 1 GREEN: candidate proof in Crosswake CI** — `d8f6cbcd`
3. **Task 2 RED: candidate status and operator boundary** — `7077c4dd`
4. **Task 2 GREEN: read-only status and seven-step runbook** — `a1f110e8`

## Evidence and Verification

- `actionlint .github/workflows/crosswake-ci.yml` passed.
- `python3 script/check_ci_leaf_manifest.py --self-test` passed all seven tests and all seven negative controls.
- The maximum-shape proof passed with 48 jobs and a 7,059-byte `needs` payload, below GitHub's governed limits.
- `script/check_release_workflow_integrity.exs` passed all release checks, including `release.ci.candidate_matrix`.
- The CI parity/generated-contract command passed 6 tests with zero failures.
- The release boundary guide suite passed 14 tests with zero failures, and `mix crosswake.docs.sync --check` passed.
- The complete release-candidate directory passed 40 tests serially with zero failures; the release-status task suite passed 17 tests with zero failures.
- Direct text and JSON status projections reported exactly three linked coordinates, five independent companions, `BLOCKED` local candidate state, and both mutation flags false.
- `git diff --check` passed. No workflow was dispatched, no credential was read, and no package, ref, tag, branch, pull request, or registry state was changed.

## TDD Gate Compliance

| Task | RED | GREEN | REFACTOR | Status |
|------|-----|-------|----------|--------|
| Candidate CI selection and authority | `c1aa95f7` | `d8f6cbcd` | included in GREEN | Pass |
| Read-only status and operator runbook | `7077c4dd` | `a1f110e8` | included in GREEN | Pass |

Both intentional RED records were persisted and accepted by `gsd_run check tdd-red-evidence` before production edits. Fresh GREEN verification covers both task commands and the complete candidate/status surfaces.

## Decisions Made

- Candidate selection is an additive scope output. It does not replace the existing `documentation_only`/`full_proof` authority, so ambiguity still runs the broader repository proof as well as the candidate full matrix.
- The always-on leaf is intentionally fixture-only and credential-free. Real mirror authorization remains a trusted-workflow rehearsal because fork PRs cannot safely or honestly exercise it.
- The full PR lane writes a CI proof receipt rather than impersonating the approval receipt: only the later normalized evaluator input, including the trusted credential rehearsal, can earn `READY FOR APPROVAL`.
- Local status remains successful when checked-in release governance is sound, while `--live` fails closed unless all linked `0.2.1` coordinates are public. Mixed public truth is retained as `PARTIAL` with coordinate-scoped recovery.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Extended the manifest's governed maximum-shape fixtures**
- **Found during:** Task 1
- **Issue:** Registering two new stable CI leaves without updating the authoritative maximum-shape workflow and `needs` fixtures would leave job-count, payload-budget, and closed-result tests unable to protect the new graph.
- **Fix:** Added both literal jobs to the maximum-shape workflow fixture and exact irrelevance records to its `needs` fixture.
- **Files modified:** `test/fixtures/ci/maximum-shape-crosswake-ci.yml`, `test/fixtures/ci/maximum-shape-needs.json`, `script/check_ci_leaf_manifest.py`
- **Commit:** `d8f6cbcd`

**2. [Rule 1 - Bug] Reconciled status's local workflow checks with Plan 06 guards**
- **Found during:** Task 2
- **Issue:** The local status duplicate still required a path gate to be the whole job expression and referenced the retired `release.ios.atomic_leased_push` scanner ID, so the read-only command reported false workflow drift after the approved-head guard landed.
- **Fix:** Required the exact path predicate within the stronger approved-head expression and consumed the current `release.ios.ordinary_atomic_push` scanner ID.
- **Files modified:** `lib/crosswake/release_status.ex`, `test/mix/tasks/crosswake_release_status_test.exs`
- **Commit:** `a1f110e8`

**Total deviations:** 2 auto-fixed (1 Rule 2 critical test authority, 1 Rule 1 correctness fix).
**Impact on plan:** Both changes close recurring verification gaps within the planned CI/status owners; no workflow family, release scope, credential authority, or publication path was added.

### AGENTS.md-driven adjustments

- Credentialed real-mirror rehearsal remains exclusively in the existing trusted workflow. Ordinary PR CI performs only credential-free reversible proof.
- Android remains at the existing linked Maven coordinate; no Android feature, template, generator, device, or parity work was introduced.
- Live reconciliation remains one-time evidence for Plan 08 rather than a permanent workflow lane.
- `REL-01` through `REL-05` remain pending until Plan 08 captures the trusted exact-candidate and final evidence required by their shared completion gate.

## Known Stubs

None. Conditional workflow leaves have executable commands, closed skip reasons, non-vacuity checks, exact receipt ownership, and explicit remediation.

## Threat Review

- T-168-19 is mitigated by full-matrix defaults before checkout validation, exact release path selection, a dedicated Release Please candidate reason, literal manifest ownership, and a closed umbrella evaluator.
- T-168-20 is mitigated by exact head/tree/base/run binding, six/five/two non-vacuity assertions, canonical SHA-256 bindings, required receipt upload, and missing-file failure.
- T-168-21 is mitigated by bounded status fields, false mutation/credential flags, public coordinate references only, privacy exclusions, and no raw probe or credential serialization.
- No unplanned application endpoint, auth path, schema trust boundary, or external mutation surface was introduced.

## User Setup Required

None. The later trusted rehearsal uses existing repository secrets; this plan did not inspect or modify them.

## Next Phase Readiness

Plan 168-08 can land the remaining reversible changes, refresh and capture the one Release Please candidate, run the trusted rehearsals, assemble the exact dossier, and stop at the explicit merge approval. The recurring graph and operator interpretation are now stable.

## Self-Check: PASSED

All declared workflow, manifest, status, guide, test, evidence, and summary files exist; all four measured task commits are reachable; and the final focused, structural, syntax, documentation, status, and serial release-candidate verification commands pass.

---
*Phase: 168-0-2-1-release-candidate-readiness*
*Completed: 2026-09-13*
