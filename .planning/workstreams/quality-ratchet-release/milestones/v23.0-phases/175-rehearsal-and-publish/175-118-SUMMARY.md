---
phase: 175-rehearsal-and-publish
plan: 118
subsystem: release-evidence
tags: [bounded-reader, git-subtree, diagnostics, fake-tests]
requires:
  - phase: 175-rehearsal-and-publish
    provides: Plan117's inspected terminal split failure and the existing bounded Plan105 collector.
provides:
  - Exact detached checkout before both Plan105 subtree splits.
  - Closed SOURCE_CHECKOUT diagnostics accepted by the Elixir receipt boundary.
affects: [REL-13, REL-17, plan119-read-scope]
actuals:
  tokens: 1600
  tasks: 2
  commits: 0
tech-stack:
  added: []
  patterns:
    - Fake process runners prove exact pinned checkout order without external access.
    - Apply recheck rejects a changed source commit before checkout or subtree split.
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-118-SUMMARY.md
  modified:
    - script/release_candidate/plan105_mirror_tag_collector.mjs
    - script/release_candidate/plan105_mirror_tag_collector.test.mjs
    - lib/crosswake/release_candidate/plan105_mirror_tag.ex
    - test/crosswake/release_candidate/plan105_mirror_tag_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/.continue-here.md
    - .planning/workstreams/quality-ratchet-release/STATE.md
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md
key-decisions:
  - "Plan118 is local-only; it creates no candidate, permission, or policy facts and grants no read or tag authority."
  - "Plan117's attempt, ALLOW, receipt, scope, authorization, lifecycle, card, and summary remain unchanged."
requirements-completed: []
coverage:
  - id: D1
    description: "Both Plan105 split paths check out the pinned source commit before subtree split, with the complete fake preflight below the 24-operation cap."
    requirement: REL-13
    verification:
      - kind: unit
        ref: "node --check and node --test script/release_candidate/plan105_mirror_tag_collector.test.mjs (57 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "SOURCE_CHECKOUT is digest-bound through Elixir persistence and offline inspection; unlisted stages and extra diagnostic fields fail closed."
    requirement: REL-17
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix test test/crosswake/release_candidate/plan105_mirror_tag_test.exs --max-cases 1 (20 tests)"
        status: pass
      - kind: other
        ref: "MIX_ENV=test mix crosswake.release.mirror_tag_026 --mode plan105-inspect --attempt-id 17f1791ecb4c181146e35250a2e5bc93 --expect ready-or-held --json"
        status: pass
    human_judgment: false
duration: not measured
completed: 2026-10-09
status: complete
---

# Phase 175 Plan 118: Rehearsal and Publish Summary

**Both Plan105 split paths now check out the exact source commit before splitting, with sanitized failure reporting.**

## Accomplishments

- Preflight now checks out the resolved peeled source commit in detached mode before reading the source tree and running `git subtree split`.
- Apply recheck now requires the resolved commit to equal the pinned source OID, checks out that exact OID, then runs the split.
- Fake tests assert the exact checkout arguments and ordering in both paths, reject a changed source commit before checkout or split, and verify checkout failures expose only the closed `SOURCE_CHECKOUT` / `PROCESS` / `PROCESS_EXIT_NONZERO` diagnostic.
- Node and Elixir accept only the closed diagnostic tuple. The Elixir test verifies digest-bound persistence and offline inspection, and rejects extra fields and an unlisted stage.
- The full fake preflight records 18 Git operations, below the 24-operation limit. Existing source, package-tree, split-tree, mirror, policy, and permission validations remain in place.

## Verification

- `node --check script/release_candidate/plan105_mirror_tag_collector.mjs` — passed.
- `node --test script/release_candidate/plan105_mirror_tag_collector.test.mjs` — 57 passed, 0 failed.
- `MIX_ENV=test mix test test/crosswake/release_candidate/plan105_mirror_tag_test.exs --max-cases 1` — 20 passed, 0 failed.
- `mix format --check-formatted lib/crosswake/release_candidate/plan105_mirror_tag.ex test/crosswake/release_candidate/plan105_mirror_tag_test.exs` — passed.
- Plan117 offline inspection — passed; status remains UNKNOWN / OBSERVATION_UNAVAILABLE at SUBTREE_SPLIT, with 7 requests, 11 Git operations, no dry run, and no tag attempt.
- Scoped `git diff --check` — passed.

## Plan117 Evidence Preservation

The Plan117 receipt, authorization, scope, lifecycle, read card, and summary SHA-256 values were recorded before the handoff update and matched after execution. Its attempt and ALLOW remain spent and must not be reused.

## Task Commits

No commits were made. The workspace exposes `.git` as read-only, so the implementation and documentation changes remain in the worktree. Phase175 planning-document commits are also disabled by the workstream configuration.

## Deviations from Plan

- GSD task commits could not be created because `.git` is read-only in this execution environment. The files were edited and verified in place; no unrelated worktree changes were staged or committed.

## Issues Encountered

- The formatter check initially found two formatting differences in the new ExUnit test. The file was formatted, then the focused ExUnit suite and formatter check both passed.

## Next Phase Readiness

Phase174 remains the last completed phase. Phase175 remains IN PROGRESS and INCOMPLETE. Plan118 is complete; Plan119 is next in Wave23 and requires a new bounded scope/card and its own exact ALLOW/HOLD before at most one read. No read occurred in Plan118. Plan106 remains in Wave24 and held unless Plan119 produces a complete, independently inspected `PREFLIGHT_READY` receipt; Plan106 still requires a separate exact tag ALLOW. REL-13/14/15/17 remain OPEN; readiness is BLOCKED; write permission and merge policy are UNKNOWN; tag authority is NONE; the release hold is ACTIVE; Plans45–48 and 89 remain held.

The next GSD command is `$gsd-execute-phase 175 --ws quality-ratchet-release --wave 23`.

---
*Phase: 175-rehearsal-and-publish*
*Plan: 118*
*Completed: 2026-10-09*

## Self-Check: PASSED

Both production paths contain the pinned detached checkout before split; fake Node tests prove order, exact OID, failure sanitization, and the operation cap; focused ExUnit tests prove closed digest-bound receipt handling; formatter, syntax, scoped diff, and Plan117 offline-inspection checks pass. No provider, credential helper, remote Git, tag, CI, merge, registry, or publication operation was invoked.
