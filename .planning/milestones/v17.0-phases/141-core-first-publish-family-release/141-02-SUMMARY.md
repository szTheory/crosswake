---
phase: 141-core-first-publish-family-release
plan: 02
subsystem: infra
tags: [hex, mix, release-please, compat-matrix, semver]

# Dependency graph
requires:
  - phase: 141-core-first-publish-family-release (plan 01)
    provides: core release-as 0.2.0 pinned + core-first Step 0 in the publish runbook
provides:
  - "sigra/chimeway/threadline crosswake_dep/0 publish-seam Hex requirement raised ~> 0.1 -> ~> 0.2"
  - "compat matrix Requires-crosswake cells + prose reconciled to the two coexisting floors, drift test green"
affects: [141-core-first-publish-family-release (plans 03/04, family publish waves)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Publish-seam version bump: only the CROSSWAKE_RELEASE=1 do: branch of crosswake_dep/0 changes; path-dep else: branch and @version stay untouched, so the bump is a pure Hex-requirement edit with no local-dev/CI-fidelity impact."

key-files:
  created: []
  modified:
    - packages/crosswake_sigra/mix.exs
    - packages/crosswake_chimeway/mix.exs
    - packages/crosswake_threadline/mix.exs
    - guides/companion_compatibility.md

key-decisions:
  - "Bumped the three v17.0 companions' crosswake_dep/0 do: branch to {:crosswake, \"~> 0.2\"} (D-141-C); left rulestead/rindle at ~> 0.1 (D-141-D, out of scope — 0.1.2-era Finding fields only)."
  - "Did not bump any companion @version — that stays release-please's job via manifest/release-as, not a manual edit."
  - "Reconciled compat-matrix prose (Independent Versioning + Reading the Requirement Syntax) to state both ~> 0.1 and ~> 0.2 are live forms, rather than leaving ~> 0.2 described as hypothetical."

patterns-established:
  - "When raising a companion's core floor, edit only the do: branch of crosswake_dep/0 and the doc's Requires-crosswake cell; the AST-parsing drift test (phase132_compat_matrix_drift_test.exs) is the merge-blocking proof that mix.exs and doc agree."

requirements-completed: [FAMILY-05]

coverage:
  - id: D1
    description: "sigra/chimeway/threadline crosswake_dep/0 publish branch reads {:crosswake, \"~> 0.2\"}; rulestead/rindle remain {:crosswake, \"~> 0.1\"}"
    requirement: "FAMILY-05"
    verification:
      - kind: other
        ref: "grep 'do: {:crosswake, \"~> 0.2\"}' packages/crosswake_{sigra,chimeway,threadline}/mix.exs (3 hits) + grep 'crosswake, \"~> 0.1\"' packages/crosswake_{rulestead,rindle}/mix.exs (2 hits)"
        status: pass
    human_judgment: false
  - id: D2
    description: "compat matrix Requires-crosswake cells for sigra/chimeway/threadline read ~> 0.2, rulestead/rindle read ~> 0.1, prose reconciled, merge-blocking drift test green"
    requirement: "FAMILY-05"
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase132_compat_matrix_drift_test.exs (6 tests, 0 failures)"
        status: pass
    human_judgment: false

duration: 6min
completed: 2026-07-03
status: complete
---

# Phase 141 Plan 02: Bump Companion Publish-Seam Floors to ~> 0.2 Summary

**Raised the crosswake_dep/0 publish-seam Hex requirement in sigra/chimeway/threadline from `~> 0.1` to `~> 0.2` and reconciled the compat matrix + prose to match, keeping the merge-blocking AST drift test green (6 tests, 0 failures).**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-03T08:51:00Z (approx)
- **Completed:** 2026-07-03T08:57:35Z
- **Tasks:** 2/2 completed
- **Files modified:** 4

## Accomplishments
- `crosswake_sigra`, `crosswake_chimeway`, `crosswake_threadline` now declare `{:crosswake, "~> 0.2"}` in the `CROSSWAKE_RELEASE=1` publish branch of `crosswake_dep/0`, honestly floor-locking them to unpublished core 0.2.0+ so a clean-room resolve can never compile them against 0.1.2.
- `crosswake_rulestead` and `crosswake_rindle` verified untouched at `~> 0.1` (D-141-D — out of scope, 0.1.2-era `Finding` fields only).
- `guides/companion_compatibility.md` "Requires crosswake" cells updated for the three v17.0 rows; "Independent Versioning" and "Reading the Requirement Syntax" prose rewritten to describe both `~> 0.1` and `~> 0.2` as live, coexisting floors instead of treating `~> 0.2` as hypothetical.
- `phase132_compat_matrix_drift_test.exs` (merge-blocking, bidirectional AST-vs-doc drift proof) passes with 0 failures after both edits.

## Task Commits

Each task was committed atomically:

1. **Task 1: Bump the three companion crosswake_dep() seams to ~> 0.2** - `4285a85d` (feat)
2. **Task 2: Update compat matrix cells + reconcile the requirement-syntax prose** - `f6abe6fe` (docs)

**Plan metadata:** pending final commit (orchestrator-owned STATE.md/ROADMAP.md not updated by this executor per objective)

_Note: this plan has no TDD tasks; both commits are single-shot feat/docs commits._

## Files Created/Modified
- `packages/crosswake_sigra/mix.exs` - `crosswake_dep/0` publish branch bumped to `{:crosswake, "~> 0.2"}`
- `packages/crosswake_chimeway/mix.exs` - `crosswake_dep/0` publish branch bumped to `{:crosswake, "~> 0.2"}`
- `packages/crosswake_threadline/mix.exs` - `crosswake_dep/0` publish branch bumped to `{:crosswake, "~> 0.2"}`
- `guides/companion_compatibility.md` - Requires-crosswake cells for sigra/chimeway/threadline set to `~> 0.2`; Independent Versioning + Reading the Requirement Syntax sections rewritten to describe two coexisting floors

## Decisions Made
- Bumped only the `do:` (`CROSSWAKE_RELEASE=1`) branch of `crosswake_dep/0` in each of the three v17.0 companions; the `else:` path-dep branch used by local dev/in-tree CI was left untouched, per D-11/D-13.
- Left `@version` unchanged in all three companion `mix.exs` files — version bumps are release-please's responsibility via its manifest/release-as config, not a manual source edit.
- Rewrote the compat-matrix prose (not just the table cells) so the guide accurately states two requirement floors now coexist (`~> 0.1` for rulestead/rindle, `~> 0.2` for sigra/chimeway/threadline), including making explicit that `~> 0.2` excludes the entire `0.1.x` core line.

## Deviations from Plan

None - plan executed exactly as written. Both tasks' automated verifications passed on the first attempt (grep checks for Task 1; the merge-blocking drift test with 0 failures for Task 2).

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required. This plan is a source-code/doc change only; it does not publish anything to Hex.

## Next Phase Readiness

- The publish seam and compat matrix now both honestly declare `>= 0.2.0` for the three v17.0 companions, which is exactly what downstream waves (companion release-please re-cut, clean-room resolve, family publish) need to compile against core 0.2.0 rather than the already-failed 0.1.2 attempt.
- The mix.exs source changes on each companion package also force release-please to open fresh companion Release PRs — this is the mechanism Wave 2's later plans rely on to re-cut publishable tags after the earlier failed 0.1.0 sigra publish attempt.
- No blockers. Ready for the next plan/wave in phase 141 (core publish itself, then the companion re-cut and family batch publish).

---
*Phase: 141-core-first-publish-family-release*
*Completed: 2026-07-03*

## Self-Check: PASSED

All modified files confirmed present on disk (packages/crosswake_sigra/mix.exs, packages/crosswake_chimeway/mix.exs, packages/crosswake_threadline/mix.exs, guides/companion_compatibility.md, this SUMMARY.md). Both task commits (4285a85d, f6abe6fe) confirmed present in git log.
