---
phase: 175-rehearsal-and-publish
plan: 124
subsystem: release-candidate
tags: [plan105, bounded-read, exact-scope, release-hold]
requires:
  - phase: 175-rehearsal-and-publish
    provides: Plan123's callback-free local scope path and Plan122's bounded subtree-progress classifier
provides:
  - A distinct exact-decision-gated current-facts read scope and collector route
  - Fake-only coverage for rejected scopes, exact ALLOW, HOLD, bounds, and terminal UNKNOWN
  - One locally prepared and inspected PENDING current-read card for Plan125
affects: [175-rehearsal-and-publish, Plan105 current-facts observation]
actuals:
  tokens: 35000
  tasks: 3
  commits: 0
plan_head_before: 0773bb4843302f562d48438922f4b88898b7a6b2
plan_head_after: 0773bb4843302f562d48438922f4b88898b7a6b2
tech-stack:
  added: []
  patterns: [separate versioned read scope, exact-decision-before-callback, bounded fixed collector]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-124-SUMMARY.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan124-0625d6afa47cef001f1241a2aa9787b8-read-scope.json
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan124-0625d6afa47cef001f1241a2aa9787b8-read-card.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan124-0625d6afa47cef001f1241a2aa9787b8-lifecycle.jsonl
  modified:
    - lib/crosswake/release_candidate/plan105_mirror_tag.ex
    - lib/mix/tasks/crosswake.release.mirror_tag_026.ex
    - script/release_candidate/plan105_mirror_tag_collector.mjs
    - script/release_candidate/plan105_mirror_tag_collector.test.mjs
    - test/crosswake/release_candidate/plan105_mirror_tag_test.exs
    - .planning/workstreams/quality-ratchet-release/STATE.md
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/.continue-here.md
key-decisions:
  - Keep the new current-facts read under its own versioned scope and exact one-use ALLOW/HOLD gate.
  - Plan124 prepares only a PENDING card; Plan125 owns the decision before any external read.
  - Preserve all release holds and do not retry an incomplete or ambiguous read.
metrics:
  duration: 15min
  completed: 2026-10-10
  tasks: 3
  commits: 0
status: complete
---

# Phase 175 Plan 124: Separate bounded current-facts read scope

**The collector now has a separately versioned, bounded read path, and one fresh PENDING scope is ready for Plan125's exact ALLOW/HOLD decision.**

## Accomplishments

- Added a strict `crosswake-plan105-current-facts-read-scope/v1` contract alongside the existing Plan123 local-only schema and legacy preflight schema. The new route has fixed API and Git read allowlists, bounded request/process limits, and zero dry-run, tag, CI, merge, or publication operations.
- Added coordinator and Mix task modes for local prepare, inspect, decision recording, and the separately gated read entry point. Exact attempt, scope digest, collector digest, authorization path, and decision must match before a read adapter can run. HOLD records a local zero-call terminal result; ambiguous reads become terminal UNKNOWN without retry.
- Added fake-only Node and ExUnit coverage for malformed/legacy/local-only scopes, mismatched decisions, HOLD, one-call ALLOW behavior, read bounds, redaction, and no-retry UNKNOWN handling. Plan123's callback-free prepare/inspect path remains separate.
- Prepared attempt `0625d6afa47cef001f1241a2aa9787b8` and ran its local inspector once. The inspector returned `PENDING`, validated the exact allowlist, reported zero counts for every operation, no authorization path, no read intent, no current facts, and labeled the old OIDs/PR tuple as comparison pins only.

The scope digest is `cd09cb599c98757511b125f054042b2965057d7c67bb3944476bd1993ade4984`. The card file SHA-256 is `f966fd4017d818ce4e1d241a166874d05fdb77ddf7463caa4391f97beea50c2d`; the scope file SHA-256 is `e0f64bf3762cd4b341cf14af1082d384feed6b8b59f6450519af69df21b59db2`; the reservation lifecycle SHA-256 is `f239851337c13d3a593f7dbdbf307ad520d241a87d893d1639f532fa60a29958`. The collector file SHA-256 bound into the scope is `556eea88a1ed988099d97bb29a937f1468ec95229463718456683e3286e6aa70`.

## Verification

- `node --test script/release_candidate/plan105_mirror_tag_collector.test.mjs` — passed, 95 tests.
- `MIX_ENV=test mix test test/crosswake/release_candidate/plan105_mirror_tag_test.exs --max-cases 1` — passed, 28 tests.
- Scoped `git diff --check` for the five implementation and test files — passed.
- One local prepare and one inspection passed the Plan124 assertions. No provider/API request, credential/helper lookup, remote Git command, dry run, CI request, tag write, or release action occurred.

## Deviations from Plan

None. The Node fake fixture initially constructed a temporary directory with a duplicated `/tmp` prefix; the fixture and production default were corrected, and the focused plus full suites passed afterward. The fake subtree progress fixture was adjusted to use the existing classifier's valid sequential progress format.

## Next GSD Action

Last completed phase: 174. Phase175 remains IN PROGRESS and INCOMPLETE. The scope and card are local approval material only; no candidate, access, or policy facts were fetched, so those facts remain unknown. The exact next command is `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research` to plan Plan125 against this card. Plan125 must place the exact-scope ALLOW/HOLD decision immediately before any provider, credential/helper, or remote-Git operation. HOLD means zero access. ALLOW permits one bounded read; any failure or ambiguity ends as UNKNOWN without retry. Plan106 remains HELD; REL-13/14/15/17 remain OPEN; readiness remains BLOCKED; write permission remains UNKNOWN; tag authority remains NONE; merge policy remains UNKNOWN; and the release hold remains ACTIVE.

## Self-Check: PASSED

- The attempt-derived scope, card, and one-entry reservation lifecycle exist at the listed paths.
- The single inspector output matched the prepared attempt and scope digest and reported PENDING with zero operation counts and no authorization, read intent, or current facts.
- Both fake suites and the scoped whitespace check passed. The Plan121/122 evidence and all release holds were preserved.
- No commit was created because Phase175 has `phase_commit_docs.175=false` and `.git` is read-only.
