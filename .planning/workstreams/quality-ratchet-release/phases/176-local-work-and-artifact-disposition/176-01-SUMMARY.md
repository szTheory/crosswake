---
phase: 176-local-work-and-artifact-disposition
plan: "01"
subsystem: testing
tags: [node, git, evidence, recovery, audit]
requires: []
provides:
  - Phase-local Git capture, verification, rendering, and scoped artifact audit CLI
  - Isolated Git fixture suite for staged/worktree recovery and writer-delta checks
affects: [176-02-live-recovery, quality-ratchet-release]
actuals:
  tokens: null # Execution token usage was not metered.
  tasks: 3
  commits: 0
tech-stack:
  added: []
  patterns: [Buffer-based NUL-delimited Git parsing, immutable private capture plus sanitized public inventory, exact named writer-span audit]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-evidence.mjs
    - .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-evidence.test.mjs
    - .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-01-SUMMARY.md
  modified:
    - .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-VALIDATION.md
key-decisions:
  - "Keep this a standard-library, phase-local evidence routine and use independent temporary Git repositories for fixtures."
  - "Treat captured path bytes and staged/worktree partitions as immutable evidence; unsupported host cases remain explicit limitations."
patterns-established:
  - "Sanitize public records while keeping raw path identity and captured payloads only in owner-protected private storage."
  - "Audit later GSD output against exact named owners and spans, preserving all bytes outside their allowed deltas."
requirements-completed: []
coverage:
  - id: D1
    description: "Git fixture capture, restore, and safe disposition preserve separate index and worktree bytes."
    verification:
      - kind: integration
        ref: "176-evidence.test.mjs#tracer capture restore"
        status: pass
    human_judgment: false
  - id: D2
    description: "Capture and verification handle supported Git state units and fail closed on malformed, changed, or unsupported state."
    verification:
      - kind: integration
        ref: "node --test .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-evidence.test.mjs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Scoped artifact audit rejects changes outside named GSD writers and their allowed deltas."
    verification:
      - kind: integration
        ref: "176-evidence.test.mjs#final audit accepts only the named STATE handoff span"
        status: pass
    human_judgment: false
duration: unknown
completed: 2026-10-11
status: complete
---

# Phase 176 Plan 01: Local Evidence CLI and Fixture Summary

**Phase-local Git evidence CLI preserves staged/worktree units, restores them in scratch, and enforces scoped Phase 176 writer audits.**

## Performance

- **Duration:** Unknown; executor start time and duration were not retained.
- **Started:** Unknown.
- **Completed:** 2026-10-11 (local time).
- **Tasks:** 3/3.
- **Files changed:** 4, including this summary.

## Accomplishments

- Added a Node standard-library CLI that captures raw Git status and index records, separates index and worktree payloads, verifies a scratch restore, and emits sanitized inventory and rendering output.
- Added a private immutable capture and audit flow that validates scoped STATE/ROADMAP/REQUIREMENTS/VALIDATION changes, the installed GSD state projection, conditional artifacts, UAT assertions, and final writer ownership.
- Added actual Git and subprocess fixtures covering real base commit fetch into scratch, restored staged/worktree state, status and index-stage equality, adverse records, races, archive-root protections, path collisions, privacy boundaries, and the installed publisher's real output shape.

## Task Commits

No task or plan-metadata commits were made. The recovery-checkout instruction prohibits all Git writes; HEAD, branch, and the index remain at their starting values. This is intentional and does not indicate uncommitted work was accidentally omitted from a commit.

## Files Created/Modified

- `176-evidence.mjs` — phase-local capture, verification, audit, and render commands plus narrowly scoped helpers.
- `176-evidence.test.mjs` — 25 actual Git/subprocess tests for restore fidelity, edge cases, fail-closed policy, publisher shape, and privacy-safe output.
- `176-VALIDATION.md` — Plan 01 execution evidence and remaining Phase 176 validation status.
- `176-01-SUMMARY.md` — this execution record.

## Decisions Made

- Kept the routine phase-local and dependency-free; all Git integration tests create independent scratch repositories.
- Preserved unsupported or host-limited cases as explicit limitations rather than silently claiming full coverage.
- Kept the live durable archive gate for Plan 02. Fixture temporary storage is test scratch only and is not evidence of durable live recovery.

## Deviations from Plan

### Auto-fixed correctness issues

- Tightened manifest validation to reject duplicate path identities before restore.
- Made required UAT assertion schema errors, pending/failing assertions, and unmet human-only assertions fail closed.
- Hardened capture against symlink-parent traversal and retained gitlink identity as an explicit limitation.
- Replaced path-derived row IDs with fresh random opaque IDs, and enforced existing owner-only roots, private manifest/capture ownership, and rejection of temporary, shared, exposed, symlinked, or nested-checkout roots without chmod.
- Added final byte/type/mode/fingerprint rechecks to catch same-status worktree races; raced captures remain partial and unverified.
- Rebuilt the captured base in an independent scratch Git repository, restored supported worktree files and index stages (including unmerged and intent-to-add records), then compared raw status and index records. Unsupported rows are reported and excluded from restored-unit counts.
- Added path-collision and no-follow checks before restore writes, preserving symlink target bytes with Buffer APIs.

These fixes were verified with focused tests and the complete suite. No package, CI, app, or live recovery changes were introduced.

## TDD Gate Compliance

- Task 1's tracer test produced a valid failing RED run, then passed after implementation.
- Task 2's duplicate private path identity test produced a valid RED run; the `gsd_run check tdd-red-evidence` classifier returned `RED_EVIDENCE_OK`, and its focused GREEN test passed.
- Task 3's malformed required UAT assertion test produced a valid RED run; the same classifier returned `RED_EVIDENCE_OK`, and its focused GREEN test passed.
- No RED commits were made because Git writes are prohibited in this recovery checkout.

## Verification

- `node --check` passed for both helper and test files.
- The exact tracer command passed **1/1** test.
- The full focused suite passed **25/25**, with no failures, skips, or todos.
- Tests invoked the same CLI entry points intended for live use, and ran the installed GSD publisher against temporary canonical STATE/ROADMAP fixtures.
- A raw Git status parser retained an invalid UTF-8 path byte losslessly and kept it opaque; macOS refused creating such a filename (`EPERM`), so a filesystem-level invalid-UTF-8 round trip remains a host limitation.
- No live checkout capture or durable archive was created. Plan 02 must use an authorized persistent `CROSSWAKE_RECOVERY_ROOT`; its final orchestration audit remains pending.
- Scratch restoration fetches the captured public base commit from the source repository. The scratch `.git` directory may therefore contain committed base objects already present in the source; it never imports excluded modified secret payloads.

## Issues Encountered

- The host filesystem would not create an invalid UTF-8 filename. The raw Git parser case passed; the unavailable filesystem fixture is explicitly recorded in `176-VALIDATION.md`.
- Baseline-preservation checks confirmed no changes to the initial Git HEAD, branch, index, or unrelated starting paths. Only this plan's helper/test additions and permitted validation update differ from the executor-start snapshot.

## Next Phase Readiness

Plan 02 can use the implemented CLI for live inventory, restore proof, and provisional audit. It still needs a verified durable owner-only archive root, and the final audit must run after the named GSD writers complete. Fixture archives are not a substitute for either gate.

## Self-Check: PASSED

- Helper, test, validation, and summary files exist.
- The tracer test and full 25-test suite pass on installed Node and Git.
- The starting HEAD (`d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377`), branch (`recovery/phase-175-orchestrator-2026-09-27`), and index digest remain unchanged.
- Commit ancestry checks were intentionally skipped because the recovery checkout prohibits Git writes.

---
*Phase: 176-local-work-and-artifact-disposition*
*Completed: 2026-10-11*
