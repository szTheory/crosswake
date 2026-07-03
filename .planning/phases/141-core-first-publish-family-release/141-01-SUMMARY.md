---
phase: 141-core-first-publish-family-release
plan: 01
subsystem: infra
tags: [release-please, hex, publish, elixir, config, runbook]

# Dependency graph
requires:
  - phase: 140-companion-publish-readiness
    provides: COMPANION-PUBLISH-RUNBOOK.md (readiness runbook, pre-core-first)
provides:
  - "release-please-config.json '.' component pinned to release-as 0.2.0 (one-shot)"
  - "COMPANION-PUBLISH-RUNBOOK.md Step 0 mandatory core-first publish procedure"
affects: [141-02, 141-03, 141-04, core-publish, companion-publish]

# Tech tracking
tech-stack:
  added: []
  patterns: ["one-shot release-as pin + _TODO_release_as removal note (existing companion pattern, now applied to root component)"]

key-files:
  created: []
  modified:
    - release-please-config.json
    - docs/COMPANION-PUBLISH-RUNBOOK.md

key-decisions:
  - "Used release-as: '0.2.0' pin on the '.' component rather than a synthetic feat! commit — auditable, reversible, does not fabricate a breaking-change commit (D-141-A)."
  - "Left bump-minor-pre-major/bump-patch-for-minor-pre-major untouched so the repo stays pre-major for future auto-computes once this one-shot pin is removed."
  - "Placed the new Step 0 section BEFORE Preconditions and the per-companion loop so core-first is unmissable in reading order."

patterns-established:
  - "Root '.' component now follows the same one-shot release-as + _TODO_release_as removal-note convention already used by the four companion blocks — the release-as-cleanup automation (PROOF-03b) already generically targets stale pins, so no new automation was needed."

requirements-completed: [FAMILY-05]

coverage:
  - id: D1
    description: "release-please-config.json '.' component carries release-as: 0.2.0 plus a _TODO_release_as one-shot removal note; all five companion release-as: 0.1.0 pins remain untouched"
    requirement: "FAMILY-05"
    verification:
      - kind: other
        ref: "node -e verification script embedded in 141-01-PLAN.md Task 1 <verify><automated>"
        status: pass
    human_judgment: false
  - id: D2
    description: "COMPANION-PUBLISH-RUNBOOK.md gains a mandatory 'Step 0 — Publish core FIRST' section naming version 0.2.0, the publish-hex vehicle (root Release PR #25), and the hex.info/hexdocs gate before any companion Release PR merges; Preconditions section cross-references it"
    requirement: "FAMILY-05"
    verification:
      - kind: other
        ref: "grep-based verification script embedded in 141-01-PLAN.md Task 2 <verify><automated>"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-07-03
status: complete
---

# Phase 141 Plan 01: Core-First Publish Config & Runbook Prep Summary

**Pinned root release-please component to `release-as: "0.2.0"` and added a mandatory "Step 0 — Publish core FIRST" section to the companion publish runbook, closing the gap that caused the 2026-07-03 sigra publish failure.**

## Performance

- **Duration:** ~12 min
- **Tasks:** 2 completed
- **Files modified:** 2

## Accomplishments

- `release-please-config.json` `.` (hex) component now carries `release-as: "0.2.0"` with a one-shot `_TODO_release_as` removal note, so the root Release PR (#25) will recompute to core `0.2.0` instead of the pre-major patch (`0.1.3`) it would otherwise cut from the 53 `feat(...)` commits since 0.1.2.
- `docs/COMPANION-PUBLISH-RUNBOOK.md` now has a top-level "Step 0 — Publish core FIRST (the load-bearing prerequisite, D-141-B)" section, placed before the Preconditions and the per-companion publish loop, explaining why (unpublished `Finding.code`/`:auth` API), how (merge root Release PR #25, `publish-hex` job), and the hard gate (`mix hex.info crosswake` shows `0.2.0` AND `hexdocs.pm/crosswake/0.2.0` resolves before any companion Release PR merges).
- Preconditions section amended with a new "Core 0.2.0 is live on Hex" precondition cross-referencing Step 0.
- Per-companion loop's hexdocs-confirm step (step 3) now notes the `clean-room-proof-<name>` job is what actually proves resolution against core `0.2.0`, not just the companion's own docs page.

## Task Commits

Each task was committed atomically:

1. **Task 1: Pin core '.' component to release-as 0.2.0 with one-shot removal note** - `67783725` (chore)
2. **Task 2: Extend COMPANION-PUBLISH-RUNBOOK.md with the mandatory core-first step** - `cca4221e` (docs)

**Plan metadata:** pending (this SUMMARY + STATE/ROADMAP update commit is owned by the orchestrator, not this plan)

## Files Created/Modified

- `release-please-config.json` - Added `release-as: "0.2.0"` + `_TODO_release_as` note to the `.` (hex) package block; companion blocks (`crosswake_rulestead`, `crosswake_rindle`, `crosswake_sigra`, `crosswake_chimeway`, `crosswake_threadline`) untouched.
- `docs/COMPANION-PUBLISH-RUNBOOK.md` - Added "Step 0 — Publish core FIRST" section; amended Preconditions with a core-0.2.0-live precondition; amended the per-companion loop's hexdocs-confirm step language.

## Decisions Made

- Chose an explicit `release-as` pin over a synthetic `feat!` commit to force the minor bump — matches plan guidance: auditable, reversible, doesn't fabricate a breaking-change commit in history.
- Did not touch `bump-minor-pre-major` / `bump-patch-for-minor-pre-major` — those govern future auto-computes once this one-shot pin is removed post-merge, and changing them was explicitly out of scope.
- Did not hand-edit the core CHANGELOG `[Unreleased]` section — release-please owns and rewrites it on PR recompute.

## Deviations from Plan

None - plan executed exactly as written. Both `<verify><automated>` blocks were run and printed `OK` before each task was committed.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required. This plan only edits config and documentation; the actual core publish (merging Release PR #25) is a separate human-gated step in a later plan of this phase (141-03/141-04), per D-141-E.

## Next Phase Readiness

- `release-please-config.json` is ready for release-please's next scheduled run to recompute the root Release PR (#25) to `0.2.0`.
- The runbook now has a written, unmissable core-first procedure that the operator (human, via the `autonomous: false` publish plans) will follow in Wave 2/3 of this phase.
- No workflow YAML or `mix.exs` was touched by this plan — those remain scoped to 141-02 (companion dep floor bump, D-141-C) and the publish execution plans (141-03/141-04), as intended.
- Blocker for those downstream plans: none introduced by this plan; the sigra publish failure that motivated this phase is unblocked by Step 0 once it is actually executed (merge #25, confirm hex.info + hexdocs), which remains a human action outside this autonomous wave.

---
*Phase: 141-core-first-publish-family-release*
*Completed: 2026-07-03*

## Self-Check: PASSED

- FOUND: release-please-config.json
- FOUND: docs/COMPANION-PUBLISH-RUNBOOK.md
- FOUND: .planning/phases/141-core-first-publish-family-release/141-01-SUMMARY.md
- FOUND commit: 67783725
- FOUND commit: cca4221e
