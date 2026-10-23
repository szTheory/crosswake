---
phase: 175-rehearsal-and-publish
plan: 01
subsystem: infra
tags: [node, cjs, ci-hygiene, scope-cardinality, wave-0]

# Dependency graph
requires:
  - phase: 174-clean-room-host-realism-adopter-fidelity
    provides: closed clean-room findings, no open blockers before Wave 0 triage
provides:
  - "check-actions default scope derived from .github/workflows/*.yml + .github/actions/**/action.yml, discovered at run time"
  - "reusable assertFullScope(actual, expected) scope-cardinality guard, callable by future checks"
  - "test-check-actions-scope self-test proving the guard fails on a narrowed scope and passes on an equal-scope control"
  - "files=<N> field on the check-actions summary line"
affects: [175-02, ci_monitor.cjs]

actuals:
  tokens: 3200
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Scope-cardinality guard as a standalone module-level function (assertFullScope), not inlined into its first caller, so a future check inherits it by construction (D-25)."
    - "Derive-at-read-time default scope for a CLI audit, re-derived immediately before use so a shrink between derivation and read fails closed rather than reporting a smaller green."

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-scope-gate-regression.log
  modified:
    - scripts/ci_monitor.cjs

key-decisions:
  - "assertFullScope only gates the no-argument default-scope path; explicit file arguments (e.g. a single workflow file) bypass the scope assertion entirely, per the plan's explicit-arguments-unaffected acceptance criteria."
  - "The narrowed regression case in test-check-actions-scope uses the first N-1 (capped at 3) discovered files rather than reintroducing the historical literal three-file list, keeping grep -c 'setup-android-jvm' at 0 per the plan's anti-recurrence check."

patterns-established:
  - "assertFullScope(actual, expected) — fails on proper-subset or empty-expected; available to any future ci_monitor.cjs check without copying."

requirements-completed: [VAC-03]

coverage:
  - id: D1
    description: "check-actions with no arguments discovers its scan scope from .github/workflows/*.yml and .github/actions/**/action.yml at run time instead of a hardcoded 3-file default, and refuses to report success on a scope that shrank between derivation and read."
    requirement: "VAC-03"
    verification:
      - kind: other
        ref: "node scripts/ci_monitor.cjs check-actions | tail -1 -> files=27 actions=252 mutable_refs=31 (matches ls .github/workflows/*.yml + find .github/actions -name action.yml == 27)"
        status: pass
      - kind: other
        ref: "node scripts/ci_monitor.cjs check-actions .github/workflows/crosswake-ci.yml | tail -1 -> files=1 (explicit args unaffected)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The scope-cardinality assertion (assertFullScope) has itself been driven red against a deliberately narrowed scope and green against an equal-scope control, with the demonstration recorded to evidence/175-scope-gate-regression.log."
    requirement: "VAC-03"
    verification:
      - kind: other
        ref: "node scripts/ci_monitor.cjs test-check-actions-scope -> case=narrowed expected=27 actual=3 outcome=red; case=control expected=27 actual=27 outcome=green; exit 0"
        status: pass
    human_judgment: false

duration: 4min
completed: 2026-09-18
status: complete
---

# Phase 175 Plan 01: Scope the pin audit to what it claims to audit Summary

**`check-actions` now discovers its 27-file scan scope from `.github/workflows/*.yml` and `.github/actions/**/action.yml` at run time instead of a hardcoded 3-file list, prints `files=<N>` on its summary line, and carries a reusable `assertFullScope` guard proven red against a narrowed scope and green against an equal-scope control.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-09-18T18:59:00Z
- **Completed:** 2026-09-18T19:03:00Z
- **Tasks:** 2
- **Files modified:** 2 (`scripts/ci_monitor.cjs`, one new evidence log)

## Accomplishments
- Replaced `checkActions()`'s hardcoded three-path default with `discoverActionSources()`, a zero-dependency `fs.readdirSync`-based tree walk, sorted for stable ordering.
- Added a standalone, reusable `assertFullScope(actual, expected)` guard (module-level, not inlined) that fails when the scanned scope is a proper subset of a freshly re-derived expectation, or when the expectation is empty.
- Extended the two-line stdout contract to `files=<N> actions=<N> mutable_refs=<N>`, keeping the existing per-line `file:lineno:line` output and the existing stderr/exit-code behavior on mutable refs unchanged (`script/check_phase165_efficient_ci.sh` still greps it correctly).
- Added `test-check-actions-scope`, a self-test subcommand (dispatched and documented alongside `test-evidence`) that exercises `assertFullScope` against a narrowed case (must go red) and an equal-scope control (must stay green), and recorded a real run's stdout/stderr plus exit status to `evidence/175-scope-gate-regression.log`.
- Confirmed the un-repaired real-world audit now correctly reports the true state: `files=27 actions=252 mutable_refs=31` (the 31 mutable refs are 175-02's job to pin, not this plan's).

## Task Commits

Each task was committed atomically:

1. **Task 1: Derive the check-actions scan scope from the tree, and assert it** - `2b8e3025` (fix)
2. **Task 2: Drive the scope assertion red against a deliberately narrowed scope** - `d368b945` (test)

**Plan metadata:** pending (this commit)

## Files Created/Modified
- `scripts/ci_monitor.cjs` - added `discoverActionSources`, `assertFullScope`, `testCheckActionsScope`; rewired `checkActions()` to use the derived default and print `files=<N>`; added `test-check-actions-scope` dispatch + help text
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-scope-gate-regression.log` - captured stdout/stderr + exit status of `test-check-actions-scope`

## Decisions Made
- `assertFullScope` is only invoked on the no-argument default-scope path inside `checkActions()`. Explicit file arguments (the plan's acceptance criterion for `check-actions .github/workflows/crosswake-ci.yml` reporting `files=1`) bypass the scope assertion entirely, since a caller who names one file is not claiming to audit the whole tree.
- The narrowed regression fixture in `test-check-actions-scope` is derived from the live discovered list (`expected.slice(0, min(3, expected.length-1))`) rather than reusing the historical literal three-file default, so `grep -c 'setup-android-jvm' scripts/ci_monitor.cjs` stays at 0 (per Task 1's anti-recurrence acceptance check) in both the fix and its own regression test.

## Deviations from Plan

None — plan executed exactly as written. One minor sequencing note: Task 2's new functions (`testCheckActionsScope`, its dispatch entry, and help text) were written in the same editing pass as Task 1's `discoverActionSources`/`assertFullScope`/`checkActions` changes and landed together in the Task 1 (`fix`) commit, since they are all in the same file and were drafted before the first commit point. Task 2's own commit (`test`) captures the evidence-log artifact that is Task 2's distinguishing deliverable. All of Task 2's acceptance criteria (subcommand present in dispatch + help, evidence log non-empty with exit status 0, both cardinalities named) are satisfied; this is a commit-boundary note, not a missing deliverable.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `scripts/ci_monitor.cjs check-actions` now truthfully reports 31 mutable refs across the full tree scope. Plan 175-02 (SHA-pinning those 31 refs across the ten affected workflow files) can proceed against a scope that is no longer vacuous.
- No blockers. This plan touched exactly `scripts/ci_monitor.cjs` and the new evidence log, per the plan's scope boundary — no workflow file was edited and none of the four already-pinned publish workflows were touched.

## Self-Check: PASSED

- FOUND: scripts/ci_monitor.cjs
- FOUND: evidence/175-scope-gate-regression.log
- FOUND commit: 2b8e3025
- FOUND commit: d368b945

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-09-18*
