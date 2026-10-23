---
phase: 175-rehearsal-and-publish
plan: 87
subsystem: release-evidence
tags: [mix, elixir, node, github-rest, mirror-tag]
requires:
  - phase: 175-rehearsal-and-publish
    provides: Held release posture and immutable Plans84-86 evidence.
provides:
  - Isolated Plan87 mirror-tag coordinator, evidence schemas, and bounded transport.
  - Local fake coverage for exact authorization, one create, independent readback, and fail-closed outcomes.
affects: [175-88, 175-89]
actuals:
  tokens: 19999
  tasks: 2
  commits: 2
commits: 2
plan_head_before: a937623e156d4782541b7bd1eb25ecab0030b6bf
plan_head_after: ba2b48357b17afc2dda1800997225db72323bb97
tech-stack:
  added: []
  patterns: [Plan-scoped immutable evidence, bounded explicit-argv Node transport, fake-only local adapter tests]
key-files:
  created:
    - lib/crosswake/release_candidate/plan87_mirror_tag.ex
    - lib/crosswake/release_candidate/plan87_mirror_tag_evidence.ex
    - script/release_candidate/plan87_mirror_ref.mjs
    - script/release_candidate/plan87_mirror_ref.test.mjs
    - test/crosswake/release_candidate/plan87_mirror_tag_test.exs
  modified:
    - lib/mix/tasks/crosswake.release.mirror_tag_026.ex
key-decisions:
  - "Production transport is wired behind the fixed Mix/Port/Node seam; this wave exercised only fake adapters and local fixtures."
  - "A potentially dispatched create consumes the attempt; one independent exact-ref readback can establish parity, never release readiness."
patterns-established:
  - "Plan87 owns fresh isolated attempt identities, evidence paths, and closed sanitized schemas."
requirements-completed: []
coverage:
  - id: D1
    description: "Fake-only coordinator proves exact authorization, a single create callback, and independent exact-ref readback."
    verification:
      - kind: integration
        ref: "test/crosswake/release_candidate/plan87_mirror_tag_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Fixed-route transport and terminal ambiguous-failure behavior are bounded and sanitized."
    verification:
      - kind: unit
        ref: "script/release_candidate/plan87_mirror_ref.test.mjs"
        status: pass
      - kind: unit
        ref: "test/crosswake/release_candidate/plan87_mirror_tag_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Plan84-86 regression evidence remains byte-preserved and release posture remains held."
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix test test/crosswake/release_candidate/plan84_mirror_tag_test.exs test/crosswake/release_candidate/plan85_local_twin_test.exs test/crosswake/release_candidate/plan86_production_diagnostic_test.exs --max-cases 1"
        status: pass
    human_judgment: false
duration: 11min
completed: 2026-10-06
status: complete
---

# Phase 175 Plan 87: Rehearsal and Publish Summary

**A local-only Plan87 mirror-tag contract now enforces exact authorization, one bounded create attempt, and independent readback while preserving the release hold.**

## Performance

- **Duration:** 11 minutes (between the first and final task commits)
- **Started:** 2026-10-06T19:43:33-04:00
- **Completed:** 2026-10-06T19:54:12-04:00
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added Plan87-only coordination, evidence schemas, strict Mix modes, and exclusive fresh attempt evidence.
- Wired the fixed-origin GitHub REST adapter through a bounded Node collector with one exact Create Reference shape, no retry/update/delete/force route, and sanitized terminal errors.
- Verified that local fake and temporary-repository tests cover the positive parity path and fail-closed drift, missing credential, ambiguous dispatch, and incomplete policy cases.
- Kept all release requirements open and held; no live preflight or apply mode ran.

## Task Commits

1. **Task 1: Prove one complete Plan87 repair path with synthetic facts** - `db277473` (`feat`)
2. **Task 2: Constrain production transport and terminal failure handling** - `ba2b4835` (`feat`)

**Plan metadata:** Documentation commits are disabled for Phase175; no metadata commit was made.

## Files Created/Modified

- `lib/crosswake/release_candidate/plan87_mirror_tag.ex` - Plan87 coordinator and bounded production adapter selection.
- `lib/crosswake/release_candidate/plan87_mirror_tag_evidence.ex` - Closed schemas, digest, lifecycle, and sanitized projections.
- `lib/mix/tasks/crosswake.release.mirror_tag_026.ex` - Strict Plan87 mode integration.
- `script/release_candidate/plan87_mirror_ref.mjs` - Fixed-origin bounded read/Create Reference transport and evidence collector.
- `script/release_candidate/plan87_mirror_ref.test.mjs` - Local Node transport and no-credential tests.
- `test/crosswake/release_candidate/plan87_mirror_tag_test.exs` - Fake adapter, evidence, negative matrix, local subtree, and regression isolation tests.

## Verification

- `mix format --check-formatted` on the four named Elixir files: passed.
- `MIX_ENV=test mix test test/crosswake/release_candidate/plan87_mirror_tag_test.exs --max-cases 1`: 11 tests, 0 failures.
- `node --check script/release_candidate/plan87_mirror_ref.mjs`: passed.
- `node --test script/release_candidate/plan87_mirror_ref.test.mjs`: 10 tests, 0 failures.
- Plan84/85/86 regression command: 81 tests, 0 failures.
- `git diff --check` on Plan87-owned files: passed.

## Decisions Made

- Keep production adapter wiring available only behind the fixed Mix/Port/Node boundary; do not invoke it in this local-only wave.
- Treat any potentially dispatched create as consumed; only one independent exact-ref readback may prove parity.
- Preserve the release hold and the open status of REL-13 and REL-17; parity is a prerequisite, not a release authorization.

## Deviations from Plan

None. The production adapter was wired as required by Task 2 and remained unused during all verification.

## Issues Encountered

The shared repository has unrelated pre-existing edits. Only the Plan87 files listed above were staged and committed; no unrelated working-tree changes were modified.

## User Setup Required

None for this plan. No credential or external service configuration was accessed or requested.

## Next Phase Readiness

Plan87's local contract is ready for the separately gated next plan. This execution performed no provider request, credential lookup, CI operation, dry-run, public ref mutation, merge, registry action, or publication. REL-13/14/15/17 remain open, candidate readiness remains BLOCKED, merge policy remains UNKNOWN, and the release hold remains ACTIVE.

The plan output names `$gsd-execute-phase 175 --ws quality-ratchet-release --wave 1` as the next command; confirm the active workstream `STATE.md`/`ROADMAP.md` handoff because Plan87 itself is already complete and Plan88/89 were intentionally not run here.

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-10-06*

## Self-Check: PASSED

- Summary file exists.
- Task commits `db277473` and `ba2b4835` are ancestors of HEAD.
- All six Plan87 implementation/test paths are clean after the scoped commits.
