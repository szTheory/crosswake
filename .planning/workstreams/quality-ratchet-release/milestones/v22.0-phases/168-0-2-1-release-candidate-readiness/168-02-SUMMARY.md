---
phase: 168-0-2-1-release-candidate-readiness
plan: "02"
subsystem: release-candidate-readiness
tags: [elixir, mix-task, deterministic-receipt, release-safety, tdd]
requires:
  - phase: 168-01
    provides: Exact protected-default landing, runnable pinned BEAM toolchain, and complete entry authority
provides:
  - Closed drift-sensitive candidate identity and five-state receipt authority
  - Deterministic JSON, Markdown, GitHub Summary, and terminal projections
  - Exact evaluation-only `mix crosswake.release.candidate` command boundary
affects: [168-package-proof, 168-mirror-authority, 168-release-workflow, release-candidate-capture]
actuals:
  tokens: 10304
  tasks: 2
  commits: 4
plan_head_before: 97ac839d860cb8d70e01e236b3fe588f25bb7634
tech-stack:
  added: []
  patterns: [functional-core-imperative-shell, closed-schema-receipt, red-green-task-commits]
key-files:
  created:
    - lib/crosswake/release_candidate.ex
    - lib/crosswake/release_candidate/identity.ex
    - lib/crosswake/release_candidate/receipt.ex
    - lib/crosswake/release_candidate/projection.ex
    - lib/mix/tasks/crosswake.release.candidate.ex
    - test/crosswake/release_candidate/receipt_test.exs
    - test/mix/tasks/crosswake_release_candidate_test.exs
  modified: []
key-decisions:
  - "Represent receipt identity as separately validated bound and observed tuples so drift remains reproducible and a STALE receipt can validate itself."
  - "Keep the Mix task evaluation-only: fixed flags delegate to the pure evaluator, while later plans supply normalized external observations through the narrow adapter seam."
  - "Write one canonical JSON receipt and derive every human projection from the same validated receipt map without color or raw adapter diagnostics."
patterns-established:
  - "Candidate state precedence is STALE, PARTIAL, COMPLETE, READY FOR APPROVAL, then BLOCKED; unknown or contradictory input is rejected before projection."
  - "Candidate output uses fixed filenames beneath one validated non-symlink output directory and atomic per-file replacement."
requirements-completed: []
requirements-addressed: [REL-04, REL-05]
coverage:
  - id: candidate-receipt-authority
    description: Exact identity mutations, proof ambiguity, credentials, and publication state derive only the closed five-state receipt vocabulary.
    requirement: REL-04
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/receipt_test.exs"
        status: pass
    human_judgment: false
  - id: candidate-projections
    description: Canonical JSON and calm Markdown, GitHub Summary, and NO_COLOR terminal projections agree on state and one next action without leaking private input.
    requirement: REL-05
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/receipt_test.exs#canonical JSON and all projections are deterministic and privacy-safe"
        status: pass
    human_judgment: false
  - id: candidate-command
    description: The exact 0.2.1 full-SHA command validates before evaluation, writes only fixed receipt artifacts, and contains no remote or database mutation authority.
    requirement: REL-05
    verification:
      - kind: integration
        ref: "test/mix/tasks/crosswake_release_candidate_test.exs"
        status: pass
    human_judgment: false
duration: 16m
completed: 2026-09-12
status: complete
---

# Phase 168 Plan 02: Candidate Identity, Receipt, Projections, and CLI Summary

**A closed Elixir authority now binds exact candidate observations, derives five fail-closed states, and emits one canonical JSON receipt with deterministic human projections through the fixed 0.2.1 Mix command.**

## Performance

- **Duration:** 16m
- **Started:** 2026-09-13T02:08:22Z
- **Completed:** 2026-09-13T02:24:33Z
- **Tasks:** 2
- **Files modified:** 9
- **Commits:** 4 measured from `97ac839d860cb8d70e01e236b3fe588f25bb7634`

## Accomplishments

- Added exact validation for candidate ref/head/tree/base, linked coordinates, configuration and workflow digests, package digests, proof results, mirror plan, and CI run identity; every independent observation mutation yields `STALE`.
- Added closed receipt validation and precedence for `READY FOR APPROVAL`, `BLOCKED`, `STALE`, `PARTIAL`, and `COMPLETE`, with explicit credential/external-state facts and exactly one next action.
- Added byte-deterministic JSON plus answer-first Markdown, GitHub Summary, and terminal projections that remain text-only under `NO_COLOR` and never retain raw observations.
- Added the exact `mix crosswake.release.candidate --version 0.2.1 --ref <40sha> --output-dir <dir>` boundary with duplicate/unknown/malformed argument rejection, bound-ref validation, atomic output files, and no merge/publish/tag/push/database authority.

## Task Commits

1. **Task 1 RED: candidate receipt contract** — `1f2bdf67`
2. **Task 1 GREEN: candidate receipt authority** — `a7a4094f`
3. **Task 2 RED: exact candidate command contract** — `16edeeb7`
4. **Task 2 GREEN: exact candidate command** — `4a3e4426`

## Evidence and Verification

- The receipt test command passed 6 tests with zero failures.
- The combined release-candidate test command passed 11 tests with zero failures.
- The repository formatter check passed.
- The full root test suite passed 1,638 tests with zero failures and 74 expected exclusions.
- Both RED records passed the TDD evidence gate with `RED_EVIDENCE_OK` before their corresponding GREEN edits.

## TDD Gate Compliance

| Task | RED | GREEN | REFACTOR | Status |
|------|-----|-------|----------|--------|
| Candidate identity and receipt | `1f2bdf67` | `a7a4094f` | — | Pass |
| Exact candidate command | `16edeeb7` | `4a3e4426` | — | Pass |

No separate refactor commit was needed; both GREEN implementations were formatted and remained focused behind the planned public interfaces.

## Decisions Made

- A receipt retains both the bound tuple and the normalized observed tuple. This makes `STALE` independently auditable rather than storing only an unexplained state label.
- The pure evaluator owns validation, state derivation, serialization, and projection. The Mix task owns only exact argument parsing, delegation, output, and exit behavior.
- Missing live adapters fail closed as unavailable; Plans 168-03 through 168-06 can extend the input seam without changing the durable command spelling or moving policy into shell code.

## Deviations from Plan

None - plan executed exactly as written.

### AGENTS.md-driven adjustments

- `REL-04` and `REL-05` remain pending in `REQUIREMENTS.md`. This plan supplies their candidate-authority and operator-surface foundations, while later Phase 168 plans still own package, clean-room, mirror, workflow, and exact-candidate proof. Marking either requirement complete here would overclaim release readiness.

## Known Stubs

None. The unconfigured external-observation adapter is an intentional fail-closed integration boundary for later Phase 168 plans, not a success placeholder; it cannot produce a ready receipt without explicit normalized evidence.

## Threat Review

- T-168-04 is mitigated by full-SHA and digest validation plus 21 independent identity mutations that all leave readiness.
- T-168-05 is mitigated by nested allowlists, fixed non-echoing validation errors, privacy canaries, bounded projection fields, and no raw adapter payload retention.
- T-168-06 is mitigated by the thin-task source guard forbidding process, Git, registry, GitHub, and database mutation seams.
- No unplanned trust-boundary surface was introduced.

## User Setup Required

None.

## Next Phase Readiness

Plan 168-03 can populate the established package-coordinate and digest families from six candidate distributables without changing state semantics, receipt serialization, or the exact CLI. Immutable publication remains prohibited and untouched.

## Self-Check: PASSED

All seven declared code/test artifacts and the summary exist, and all four task commits are reachable from the current phase branch.

---
*Phase: 168-0-2-1-release-candidate-readiness*
*Completed: 2026-09-12*
