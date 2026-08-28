---
phase: 153-ios-mirror-unblock
plan: 02
subsystem: infra
tags: [github-actions, swiftpm, git, mirror, deploy-key, release-infra]

# Dependency graph
requires:
  - phase: 153-01
    provides: "Backfill lane SSH transport, verify-only dry-run write probe, explicit-lease update-main path, and unknown-object ancestry advisory"
provides:
  - "MIRROR_DEPLOY_KEY exists on szTheory/crosswake, with a read-write SSH deploy key titled 'crosswake monorepo split (write)' on szTheory/crosswake-shell-core-ios"
  - "CI verify-only fire-drill run 30316715897 proved MIRROR_DEPLOY_KEY WRITE scope without mutating the mirror and recorded split SHA 658d60253c58b7e0aedb576f16f40766fa677f23"
  - "Separate tag-push dispatch run 30316962777 pushed refs/tags/v0.2.0 to 658d60253c58b7e0aedb576f16f40766fa677f23"
  - "Corrected separate re-baseline dispatch run 30578674382 force-with-lease updated mirror refs/heads/main to 658d60253c58b7e0aedb576f16f40766fa677f23 while preserving refs/tags/v0.1.2 at 6417ae6543219f1c35be120766827503eaa8ceea"
  - "MIRROR-01 is satisfied: iOS adopters can resolve crosswake-shell-core-ios v0.2.0 and v0.1.2 remains resolvable"
affects: [153-03, 153-04, 156-native-menu-action-button-control]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Human-gated external mutations reconciled from read-only evidence rather than re-dispatched"
    - "Workflow run IDs plus remote ref SHAs are the durable evidence for one-way mirror operations"
    - "Tag push and mirror-main re-baseline remain separate dispatches; the irreversible tag push was not bundled with the reversible branch re-baseline"

key-files:
  created:
    - .planning/phases/153-ios-mirror-unblock/153-02-SUMMARY.md
  modified: []

key-decisions:
  - "No external mutation was performed during this reconciliation; all GitHub and mirror checks were read-only."
  - "The 2026-07-28 update_main=true run 30317622546 is recorded as a separate approved but pre-fix no-op for main; the actual re-baseline evidence is corrected run 30578674382 on 2026-07-30."
  - "mix crosswake.release.status --live was accepted for this plan because the iOS mirror probe is OK; the command still reports unrelated bootstrap companion warnings outside MIRROR-01."

requirements-completed: [MIRROR-01]

coverage:
  - id: D1
    description: "A read-write deploy key titled 'crosswake monorepo split (write)' exists on the mirror repo, and MIRROR_DEPLOY_KEY exists on szTheory/crosswake."
    requirement: MIRROR-01
    verification:
      - kind: manual_procedural
        ref: "gh repo deploy-key list -R szTheory/crosswake-shell-core-ios; gh secret list -R szTheory/crosswake"
        status: pass
    human_judgment: false
  - id: D2
    description: "The apply=false fire-drill ran in CI and proved WRITE scope with a dry-run push probe, recording split SHA 658d60253c58b7e0aedb576f16f40766fa677f23."
    requirement: MIRROR-01
    verification:
      - kind: other
        ref: "gh run view 30316715897 --repo szTheory/crosswake --log"
        status: pass
    human_judgment: false
  - id: D3
    description: "refs/tags/v0.2.0 exists on the mirror and equals the recorded split SHA."
    requirement: MIRROR-01
    verification:
      - kind: other
        ref: "git ls-remote https://github.com/szTheory/crosswake-shell-core-ios refs/tags/v0.2.0"
        status: pass
    human_judgment: false
  - id: D4
    description: "refs/tags/v0.1.2 remains unchanged at 6417ae6543219f1c35be120766827503eaa8ceea."
    requirement: MIRROR-01
    verification:
      - kind: other
        ref: "git ls-remote https://github.com/szTheory/crosswake-shell-core-ios refs/tags/v0.1.2"
        status: pass
    human_judgment: false
  - id: D5
    description: "Mirror refs/heads/main is re-baselined to the splitsh-lite lineage at the same SHA as v0.2.0 after a separate corrected dispatch."
    requirement: MIRROR-01
    verification:
      - kind: other
        ref: "gh run view 30578674382 --repo szTheory/crosswake --log; git ls-remote https://github.com/szTheory/crosswake-shell-core-ios refs/heads/main"
        status: pass
    human_judgment: false
  - id: D6
    description: "The tag push and corrected main re-baseline were distinct workflow_dispatch runs, preserving D-21's separate-approval boundary."
    requirement: MIRROR-01
    verification:
      - kind: other
        ref: "gh run view 30316962777; gh run view 30578674382"
        status: pass
    human_judgment: false

duration: reconciled
completed: 2026-07-30
status: complete
---

# Phase 153 Plan 02: Human-Gated iOS Mirror Backfill Summary

**The human-gated iOS mirror repair is complete: CI proved the deploy key write path, the mirror now carries `v0.2.0` at the recorded split SHA, `v0.1.2` remains untouched, and mirror `main` has been re-baselined onto the reproducible splitsh-lite lineage.**

## Performance

- **Duration:** Reconciled from prior external actions already completed before this execute-phase invocation
- **Started:** 2026-07-30T20:47:56Z
- **Completed:** 2026-07-30
- **Tasks:** 3 completed
- **Files modified:** 1 created, 0 source files modified

## Accomplishments

- Verified the one-time credential setup with read-only commands: `gh repo deploy-key list -R szTheory/crosswake-shell-core-ios` shows `crosswake monorepo split (write)` as `read-write`, and `gh secret list -R szTheory/crosswake` shows `MIRROR_DEPLOY_KEY`.
- Verified run `30316715897` (`workflow_dispatch`, 2026-07-28) completed successfully in `apply=false` mode and logged all required go/no-go facts: three-way release-ref agreement, manifest lockstep, Hex/Maven live checks, computed split SHA `658d60253c58b7e0aedb576f16f40766fa677f23`, dry-run push probe WRITE scope, and mirror `v0.2.0` absence before mutation.
- Verified run `30316962777` (`workflow_dispatch`, 2026-07-28) separately pushed `refs/tags/v0.2.0` at `658d60253c58b7e0aedb576f16f40766fa677f23`.
- Verified the first `update_main=true` run, `30317622546`, was a separate approved dispatch but pre-fix no-opped after the tag already existed.
- Verified corrected run `30578674382` (`workflow_dispatch`, 2026-07-30, head `932b4f32`) separately re-baselined mirror `main` to `658d60253c58b7e0aedb576f16f40766fa677f23` with `--force-with-lease`, logging the expected D-08 unknown-object advisory first.
- Verified the mirror directly: `refs/heads/main` and `refs/tags/v0.2.0` both resolve to `658d60253c58b7e0aedb576f16f40766fa677f23`; `refs/tags/v0.1.2` still resolves to `6417ae6543219f1c35be120766827503eaa8ceea`.

## Task Commits

This plan's external tasks were human-gated GitHub/mirror operations, not local source edits. They were completed before this reconciliation agent ran and are represented by workflow runs rather than task commits:

1. **Task 1: Mint the SSH deploy key** - GitHub deploy key id `157678622`, title `crosswake monorepo split (write)`, `read-write`; secret `MIRROR_DEPLOY_KEY` created 2026-07-18T20:51:36Z.
2. **Task 2: Fire-drill the CI push credential** - run `30316715897` succeeded; dry-run push probe proved WRITE scope and recorded split SHA `658d60253c58b7e0aedb576f16f40766fa677f23`.
3. **Task 3: Push tag, then separately re-baseline main** - run `30316962777` pushed `v0.2.0`; corrected run `30578674382` re-baselined `main`; run `30317622546` remains historical evidence of a separate pre-fix no-op re-baseline attempt.

## Files Created/Modified

- `.planning/phases/153-ios-mirror-unblock/153-02-SUMMARY.md` - records the completed human-gated mirror operations and read-only verification evidence.

## Decisions Made

- No external state was mutated by this reconciliation agent. It used only read-only commands: `gh repo deploy-key list`, `gh secret list`, `gh run view`, `git ls-remote`, and `mix crosswake.release.status --live`.
- The authoritative MIRROR-01 split SHA is `658d60253c58b7e0aedb576f16f40766fa677f23`, taken from the successful verify-only run log and matched against the mirror refs.
- The D-21 separation boundary is preserved in the record: verify-only (`30316715897`), tag push (`30316962777`), initial separate main attempt (`30317622546`), and corrected main re-baseline (`30578674382`) are distinct workflow_dispatch runs.

## Deviations from Plan

### Auto-fixed Issues

None - no implementation work was performed. This run reconciled already-completed human-gated external actions.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** The plan's live operations had already happened; this closeout avoided any duplicate one-way-door mutation and documented the verified outcome.

## Issues Encountered

- The 2026-07-28 `update_main=true` dispatch (`30317622546`) succeeded as a workflow but did not re-baseline `main` because it ran before the corrected tag-already-present path reached `origin/main`. This was later corrected by run `30578674382` on 2026-07-30, which logged the expected D-08 unknown-object advisory and updated `main` with `--force-with-lease`.
- `mix crosswake.release.status --live` exits 0 with `ios-core live_ios_mirror=ok`, but the aggregate command still reports unrelated bootstrap warnings for `crosswake_rindle` and `crosswake_rulestead`. Those warnings are outside MIRROR-01 and were already handled by the Phase 153 Plan 04 release-truth carve-out.

## User Setup Required

None. The one-time deploy key ritual is already complete, and deploy keys do not expire.

## Next Phase Readiness

MIRROR-01 is complete. Phase 156 is unblocked from the iOS mirror side because SwiftPM can resolve `crosswake-shell-core-ios` `v0.2.0`. The remaining Phase 153 MIRROR-02 durability work is covered by the existing 153-03 and 153-04 summaries; no additional live mirror mutation is required.

## Threat Flags

None. This reconciliation introduced no new network endpoints, auth paths, file access patterns, schema changes, or external mutations.

## Self-Check: PASSED

- Created summary file exists: `.planning/phases/153-ios-mirror-unblock/153-02-SUMMARY.md`.
- Read-only remote refs verified:
  - `658d60253c58b7e0aedb576f16f40766fa677f23 refs/heads/main`
  - `6417ae6543219f1c35be120766827503eaa8ceea refs/tags/v0.1.2`
  - `658d60253c58b7e0aedb576f16f40766fa677f23 refs/tags/v0.2.0`
- Read-only workflow evidence verified: runs `30316715897`, `30316962777`, `30317622546`, and `30578674382` are successful `workflow_dispatch` runs.
- No local source files were modified for this plan.

---
*Phase: 153-ios-mirror-unblock*
*Completed: 2026-07-30*
