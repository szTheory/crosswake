---
phase: 175-rehearsal-and-publish
plan: 122
subsystem: release-candidate
tags: [git-subtree, process-boundaries, release-hold, fake-tests]
requires:
  - phase: 175-rehearsal-and-publish
    provides: Plan121 immutable terminal evidence and sanitized local reproduction facts
provides:
  - Bounded stage-scoped classifier for complete Git subtree progress streams
  - Exact split stdout validation and pinned split/package tree assertions
  - Fake-only regressions for malformed, incomplete, over-limit, and uncertain outcomes
affects: [175-rehearsal-and-publish, Plan105 collector]
actuals:
  tokens: 4600
  tasks: 2
  commits: 0
tech-stack:
  added: []
  patterns: [bounded streaming classification, stage-scoped stderr exception]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-122-SUMMARY.md
  modified:
    - script/release_candidate/plan105_mirror_tag_collector.mjs
    - script/release_candidate/plan105_mirror_tag_collector.test.mjs
    - .planning/workstreams/quality-ratchet-release/STATE.md
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md
key-decisions:
  - "Only complete bounded sequential progress from a zero-exit SUBTREE_SPLIT may pass the stderr gate."
  - "Plan121 artifacts remain immutable; no read, scope, or release authority is created."
patterns-established:
  - "Process progress is classified while chunks arrive and only numeric parser state survives."
  - "A split requires the exact pinned object ID and both pinned tree identities."
requirements-completed: []
coverage:
  - id: D1
    description: "Accept valid complete subtree progress while preserving exact split and tree identity gates."
    requirement: REL-13
    verification:
      - kind: unit
        ref: "node --test script/release_candidate/plan105_mirror_tag_collector.test.mjs"
        status: pass
    human_judgment: false
duration: 18min
completed: 2026-10-09
status: complete
---

# Phase 175 Plan 122: Bounded subtree progress classifier

**A successful subtree split now accepts only a complete bounded sequential progress stream while retaining exact split and tree identity checks.**

## Performance

- **Duration:** about 18 minutes
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added a transient classifier limited to `SUBTREE_SPLIT`, with byte, record, and record-length bounds and strict counter transitions.
- Tightened split stdout to one lowercase 40-character object ID, optionally followed by one LF; kept the pinned split commit and both pinned tree checks.
- Added fake-only regressions covering chunk boundaries, recursive and top-level transitions, `N < M`, malformed and uncertain process outcomes, identity mismatches, sanitization, and immutable Plan121 evidence.
- Updated the active handoff and plan index. Plan121 remains unchanged; Plan106 remains held; REL-13/14/15/17 remain OPEN; readiness remains BLOCKED; write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE.

## Verification

- `node --test script/release_candidate/plan105_mirror_tag_collector.test.mjs` — passed, 90 tests.
- `git diff --check -- .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-122-SUMMARY.md .planning/workstreams/quality-ratchet-release/STATE.md .planning/workstreams/quality-ratchet-release/ROADMAP.md` — passed.
- `node --test --test-name-pattern="Plan121 immutable artifact hashes and active release holds match sanitized baselines" script/release_candidate/plan105_mirror_tag_collector.test.mjs` — passed.

## Task Commits

No commits were created. The workspace git metadata is read-only and the active workstream requires planning artifacts to remain uncommitted.

## Decisions Made

- The stderr exception applies only to a complete, bounded classifier result from a zero-exit `SUBTREE_SPLIT` process.
- This local repair does not establish candidate readiness or authorize a new read or release action.

## Deviations from Plan

None. The standalone fake split helper now also checks the pinned package-prefix tree so both split paths enforce the required identity contract.

## Issues Encountered

The existing standalone fake split helper did not check the package-prefix tree. Added that missing assertion as part of the plan's required two-tree identity gate.

## Next Phase Readiness

Phase175 remains incomplete and release-blocked. No GSD command is eligible now. Any future public read requires a distinct plan, a fresh scope, and an exact ALLOW supported by materially distinct evidence. No provider, credential, CI, remote-Git, dry-run, tag, merge, registry, or publication action occurred.

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-10-09*

## Self-Check: PASSED

- Plan122 summary, collector, test, active STATE, and active ROADMAP exist.
- The named Plan121 hash and active release-hold assertion passed after the STATE and ROADMAP updates.
- No commits were created, as instructed for this read-only git workspace.
