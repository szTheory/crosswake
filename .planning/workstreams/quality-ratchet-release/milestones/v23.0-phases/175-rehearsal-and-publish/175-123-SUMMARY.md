---
phase: 175-rehearsal-and-publish
plan: 123
subsystem: release-candidate
tags: [plan105, local-scope, release-hold, fake-tests]
requires:
  - phase: 175-rehearsal-and-publish
    provides: Plan122's bounded subtree-progress repair and Plan121's immutable terminal result
provides:
  - Local-only Plan105 observation scope prepare and inspect modes
  - Zero-read and zero-dry-run scope schema with strict validation
  - Collector preflight guard that rejects local observation scopes before adapters
affects: [175-rehearsal-and-publish, Plan105 fresh-read planning]
actuals:
  tokens: 6100
  tasks: 2
  commits: 0
commits: 0
plan_head_before: 0773bb4843302f562d48438922f4b88898b7a6b2
plan_head_after: 0773bb4843302f562d48438922f4b88898b7a6b2
tech-stack:
  added: []
  patterns: [pending-only local scope, pre-adapter rejection]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-123-SUMMARY.md
  modified:
    - lib/crosswake/release_candidate/plan105_mirror_tag.ex
    - lib/mix/tasks/crosswake.release.mirror_tag_026.ex
    - script/release_candidate/plan105_mirror_tag_collector.mjs
    - test/crosswake/release_candidate/plan105_mirror_tag_test.exs
    - script/release_candidate/plan105_mirror_tag_collector.test.mjs
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/.continue-here.md
    - .planning/workstreams/quality-ratchet-release/STATE.md
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md
key-decisions:
  - "Keep local scope preparation separate from the existing read-capable v2 preflight."
  - "A later plan owns the fresh scope and current-facts read, with its exact ALLOW/HOLD before access."
patterns-established:
  - "Local pending scopes bind the current collector digest but have no operation, authorization, or read-intent fields."
  - "The collector rejects the local-only schema at its preflight boundary before invoking any adapter."
requirements-completed: []
coverage:
  - id: D1
    description: "Local prepare/inspect modes enforce zero operation budgets and cannot reach collector adapters."
    requirement: REL-13
    verification:
      - kind: unit
        ref: "script/release_candidate/plan105_mirror_tag_collector.test.mjs"
        status: pass
      - kind: unit
        ref: "test/crosswake/release_candidate/plan105_mirror_tag_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Plan123 preserves the independent release hold and prior Plan121/122 evidence."
    requirement: REL-17
    verification:
      - kind: other
        ref: "Plan121 immutable fingerprint and release-hold assertions in the Node suite"
        status: pass
    human_judgment: false
metrics:
  duration: 12min
  completed: 2026-10-10
status: complete
---

# Phase 175 Plan 123: Local-only observation scopes

**The release checker now has a file-only scope preparation path that cannot make a read or attempt a test push.**

## Performance

- **Duration:** about 12 minutes
- **Tasks:** 2
- **Files changed:** 9 planned files, including the summary
- **Commits:** 0; `.git` is read-only in this workspace and Phase175 planning artifacts remain uncommitted

## Accomplishments

- Added `plan105-observation-prepare` and `plan105-observation-inspect` modes. They create and inspect only a local `PENDING` scope, bind it to the collector's current SHA-256, use confined paths and exclusive synced creation, and verify the written scope by reading it back.
- The new scope requires an empty operation list and zero public request, Git, helper, permission, dry-run, tag, and CI counts and limits. Its exact key allowlist rejects legacy shapes, ALLOW/HOLD fields, read intent, and unknown operation fields. The API has no adapter argument or authorization/read function.
- Added a preflight firewall for this new schema. The collector returns a safe blocked result before fetch, credential, helper, process, or temporary-directory adapters can run. Existing valid v2 scopes continue through their established behavior.
- Added temporary-root ExUnit coverage for prepare, inspect, zero counts, digest binding, collision and path rejection, malformed/legacy/decision/read-intent/operation mutations, and strict Mix option parsing. Added fake-only Node sentinel counters to prove every adapter remains at zero for the local schema and its decision/read-intent variants.
- Preserved the Plan121 and Plan122 artifacts byte-for-byte. The existing Node regression also confirms the active release-hold markers remain present.

## Verification

- TDD RED: the targeted Node test failed on the missing explicit local-scope rejection; `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK`. The report is retained in `.planning/tmp/175-123-node-red.json`.
- `node --test script/release_candidate/plan105_mirror_tag_collector.test.mjs` — passed, 91 tests.
- `MIX_ENV=test mix test test/crosswake/release_candidate/plan105_mirror_tag_test.exs --max-cases 1` — passed, 23 tests.
- Scoped `git diff --check` for the five implementation and test files — passed.
- Tracer feedback gate: reran all three planned checks after Task1; they passed again.

## Decisions Made

- Plan123 adds only the local scope-preparation prerequisite. It does not create a phase evidence scope, approval card, or current facts.
- The later fresh-read plan must create and display a new exact scope, then stop for that scope's ALLOW/HOLD before any provider, credential/helper, or remote-Git access.

## Deviations from Plan

None. No provider, credential/helper, remote-Git, dry-run, CI, tag, write, or release operation occurred. Unit-test Git fixtures used temporary local repositories only.

## Next Phase Readiness

Last completed phase: 174. Phase175 remains INCOMPLETE and release-blocked. Plan123 is complete, but it establishes no current source, mirror, PR, access, or policy facts. Plan106 remains HELD; REL-13/14/15/17 remain OPEN; readiness remains BLOCKED; write permission remains UNKNOWN; tag authority remains NONE; merge policy remains UNKNOWN; and the release hold remains ACTIVE.

The exact next GSD command is `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research`. That separate plan prepares one fresh scope/card and plans the current-facts read, with an exact-scope ALLOW/HOLD checkpoint before any access. The old v2 preflight's test-push path is not used by the new local modes.

## Self-Check: PASSED

- The summary exists at the planned path.
- Both named suites and scoped diff check passed, including the post-tracer rerun.
- The scoped Node regression confirms the Plan121/122 fingerprints and release-hold markers remain unchanged.
- No commits or external operations were performed.
