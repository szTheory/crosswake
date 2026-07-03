---
phase: 140-family-discipline-close
plan: 04
subsystem: infra
tags: [release-please, hex, publishing, runbook, ci, companions]

# Dependency graph
requires:
  - phase: 137-crosswake-sigra-extraction
    provides: sigra release-please component + publish-hex-sigra + clean-room-proof-sigra jobs
  - phase: 138-crosswake-chimeway-extraction
    provides: chimeway release-please component + publish-hex-chimeway + clean-room-proof-chimeway jobs
  - phase: 139-crosswake-threadline-extraction
    provides: threadline release-please component + publish-hex-threadline + clean-room-proof-threadline jobs
provides:
  - "docs/COMPANION-PUBLISH-RUNBOOK.md — human-facing publish-readiness runbook for the batched sigra → chimeway → threadline hex publish"
  - "Verified inventory of publish pipeline primitives with on-disk locations"
  - "Ship-gate ordering doc (register_required_checks.sh green-first + required-check exclusion)"
affects: [140-05, family-batch-publish, register_required_checks]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Runbook-as-safety-rail: irreversible hex publishes sequenced by human discipline, not cross-run CI needs: edges"
    - "Readiness-vs-execution split: readiness doc = autonomous phase deliverable; execution = separate autonomous:false human trigger"

key-files:
  created:
    - docs/COMPANION-PUBLISH-RUNBOOK.md
  modified: []

key-decisions:
  - "D-01: Phase-140 deliverable is the runbook (readiness); the hex publish + register_required_checks.sh DRY_RUN=0 is a separate human trigger (plan 140-05, autonomous:false)."
  - "D-02: Cross-companion sequencing is runbook discipline, NOT GitHub Actions needs: edges (needs cannot span workflow runs — separate-pull-requests:true means each companion merges in its own run)."
  - "D-03: Per-companion loop — merge ONE Release PR → wait publish-hex + clean-room-proof green → confirm hexdocs resolves → merge release-as-cleanup PR → next; fixed order sigra → chimeway → threadline (observer last)."
  - "D-04: register_required_checks.sh runs green-first (DRY_RUN=1 then DRY_RUN=0) after new lanes go green on main; publish-hex-*/clean-room-proof-* MUST NOT be registered as required checks (permanent PR deadlock)."

patterns-established:
  - "Pipeline-primitives-verified-present section: every primitive cited with confirmed on-disk file+line before the runbook wraps it."

requirements-completed: [FAMILY-04]

# Coverage metadata (#1602)
coverage:
  - id: D1
    description: "Pipeline primitives (verified present) section citing per-companion release-please-config blocks, manifest baselines, publish-hex + clean-room-proof jobs, and release-failure-alert coverage — with on-disk file/line references"
    requirement: "FAMILY-04"
    verification:
      - kind: automated
        ref: "grep -c 'publish-hex-sigra|publish-hex-chimeway|publish-hex-threadline' .github/workflows/release-please.yml == 15"
        status: pass
      - kind: automated
        ref: "grep 'Pipeline primitives (verified present)' docs/COMPANION-PUBLISH-RUNBOOK.md == 1"
        status: pass
    human_judgment: false
  - id: D2
    description: "Sequential per-companion publish loop (5 steps) + Hex ~60-min revert window (mix hex.retire) + STOP-on-release-failure-alert, in fixed order sigra → chimeway → threadline"
    requirement: "FAMILY-04"
    verification:
      - kind: automated
        ref: "grep -c 'sigra → chimeway → threadline' docs/COMPANION-PUBLISH-RUNBOOK.md == 2"
        status: pass
      - kind: automated
        ref: "grep -c 'mix hex.retire' docs/COMPANION-PUBLISH-RUNBOOK.md == 2"
        status: pass
    human_judgment: true
    rationale: "Operator-facing procedural correctness (is the loop safe and unambiguous enough to drive an irreversible publish?) is a judgment call the grep cannot make; the human executing plan 140-05 is the real verifier."
  - id: D3
    description: "Ship-gate ordering: register_required_checks.sh DRY_RUN=1→0 green-first + hard rule excluding publish-hex-*/clean-room-proof-* from required checks"
    requirement: "FAMILY-04"
    verification:
      - kind: automated
        ref: "grep DRY_RUN=1 and DRY_RUN=0 + 'never register the publish' present in docs/COMPANION-PUBLISH-RUNBOOK.md"
        status: pass
    human_judgment: false
  - id: D4
    description: "Scope-reconciliation note: readiness = complete Phase-140 FAMILY-04 deliverable; execution deferred to autonomous:false plan 140-05"
    requirement: "FAMILY-04"
    verification:
      - kind: automated
        ref: "grep 'readiness delivered, execution deferred by design' docs/COMPANION-PUBLISH-RUNBOOK.md == 1"
        status: pass
    human_judgment: false

# Metrics
duration: 2min
completed: 2026-07-03
status: complete
---

# Phase 140 Plan 04: Companion Publish Runbook Summary

**Human-facing publish-readiness runbook (`docs/COMPANION-PUBLISH-RUNBOOK.md`) that wraps the already-present release-please primitives with the safe one-Release-PR-at-a-time discipline for the irreversible sigra → chimeway → threadline hex publish.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-07-03T01:07:20Z
- **Completed:** 2026-07-03T01:09:22Z
- **Tasks:** 2
- **Files modified:** 1 (created)

## Accomplishments
- Verified every publish pipeline primitive is present on disk (per-companion release-please-config blocks with `separate-pull-requests:true` + `release-as:"0.1.0"` + `_TODO_release_as`, manifest `0.1.0` baselines, `publish-hex-<name>` jobs gated on per-component `*_release_created`, within-run `clean-room-proof-<name>: needs:[release-please, publish-hex-<name>]`, and `release-failure-alert` on `if: failure()` covering all companion publish + proof jobs) and recorded each with file+line citations. **No BLOCKER** — all primitives present.
- Authored the sequential per-companion publish loop (D-03): merge ONE Release PR → wait for `publish-hex` + `clean-room-proof` green on main → confirm `hexdocs.pm/crosswake_<name>/0.1.0` resolves → merge the auto-opened `release-as-cleanup` PR → only then next, in fixed order sigra → chimeway → threadline (observer last, belt-and-suspenders).
- Documented the ~60-min Hex revert window (`mix hex.retire`, never re-push) and the hard "if `release-failure-alert` fires, STOP" rule.
- Documented the ship-gate ordering (D-04): `register_required_checks.sh` green-first `DRY_RUN=1` → `DRY_RUN=0` after new lanes go green on main, with the hard rule that post-merge `publish-hex-*`/`clean-room-proof-*` jobs MUST NOT be registered as required checks (permanent PR deadlock).
- Made the readiness-vs-execution boundary explicit (D-01/D-02): sequencing is runbook discipline (cross-run `needs:` cannot work), and readiness IS the complete Phase-140 FAMILY-04 deliverable while execution is deferred to the `autonomous:false` plan 140-05.

## Task Commits

Each task was committed atomically:

1. **Task 1: Verify + record pipeline primitives** - `a4051cfd` (docs)
2. **Task 2: Sequential publish loop + ship-gate ordering** - `ebbab36e` (docs)

## Files Created/Modified
- `docs/COMPANION-PUBLISH-RUNBOOK.md` (created) - The publish-readiness runbook: verified-present pipeline primitives with citations, batched-publish preconditions, per-companion publish loop, Hex revert-window + failure-alert stop rules, green-first ship-gate ordering with the required-check exclusion, and the readiness-vs-execution scope reconciliation.

## Decisions Made
None beyond the plan's locked decisions (D-01..D-04) — followed the plan as specified. Line-number citations in the runbook are current-as-of-writing and paired with grep-able anchor names so they survive future line drift.

## Deviations from Plan

None - plan executed exactly as written.

The `read_first` files (`release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release-please.yml`, `script/register_required_checks.sh`, `docs/MILESTONE-BOUNDARY-HYGIENE.md`, `140-CONTEXT.md`, `.github/workflows/release-as-staleness-gate.yml` / `release-as-cleanup` job) were all read before authoring. All expected primitives were confirmed present — no missing/malformed primitive, so no BLOCKER was recorded (the plan's expected outcome).

---

**Total deviations:** 0
**Impact on plan:** None. Documentation-only plan; no hex publish, no `register_required_checks.sh` run, no Release PR merge, and no CI/config/script edit — verified via `git status --short` showing only the runbook (plus this SUMMARY) changed by this plan.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required by this plan. (The runbook itself documents the future human-triggered publish; that is plan 140-05's execution, not a setup step for this plan.)

## Next Phase Readiness
- FAMILY-04 readiness satisfied: the human-facing publish runbook + ship-gate ordering are authored and grounded in the verified-present pipeline primitives.
- Plan 140-05 (`autonomous:false`) can consume this runbook directly to execute the batched family publish once preconditions land (origin-sync + 137/138/139 execution-verified).
- No blockers.

## Self-Check: PASSED
- `docs/COMPANION-PUBLISH-RUNBOOK.md` — FOUND on disk.
- Task 1 commit `a4051cfd` — FOUND in git log.
- Task 2 commit `ebbab36e` — FOUND in git log.
- No CI/config/script file modified by this plan (`git status --short` shows only the runbook + SUMMARY).

---
*Phase: 140-family-discipline-close*
*Completed: 2026-07-03*
