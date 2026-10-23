---
phase: 175-rehearsal-and-publish
plan: 116
subsystem: release-evidence
tags: [bounded-reader, diagnostics, privacy, operation-counts]
requires:
  - phase: 175-rehearsal-and-publish
    provides: Plan105 bounded reader and Plan113 authenticated permission contract
provides:
  - Closed, sanitized collector diagnostics for bounded stages
  - Independent exact-or-UNKNOWN API and Git operation counts
  - Digest-bound receipt and offline-inspector support for new and legacy diagnostics
affects: [REL-17, plan106-eligibility, Phase175 release hold]
actuals:
  tasks: 3
  commits: 2
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-116-SUMMARY.md
  modified:
    - script/release_candidate/plan105_mirror_tag_collector.mjs
    - script/release_candidate/plan105_mirror_tag_collector.test.mjs
    - lib/crosswake/release_candidate/plan105_mirror_tag.ex
    - test/crosswake/release_candidate/plan105_mirror_tag_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-116-PLAN.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-106-PLAN.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/.continue-here.md
    - .planning/workstreams/quality-ratchet-release/STATE.md
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md
key-decisions:
  - "Collector failures are mapped from fixed execution stages and structured outcomes; exception text and raw process fields are never recorded."
  - "API request and Git operation uncertainty are independent, and valid known counts survive diagnostic receipts."
  - "A local diagnostic repair cannot explain or authorize reuse of Plan115's terminal attempt."
requirements-completed: []
coverage:
  - id: D1
    description: "Fake bounded failures produce closed stage diagnostics, separate counts, and no credential, route, process-output, or path canaries."
    requirement: REL-17
    verification:
      - kind: unit
        ref: "Focused Node collector tests"
        status: pass
    human_judgment: false
  - id: D2
    description: "Elixir persists and inspects a fail-closed stage diagnostic with its validated counts, rejects malformed diagnostics, and still accepts a legacy v1 receipt."
    requirement: REL-17
    verification:
      - kind: integration
        ref: "Focused Plan105 ExUnit tests"
        status: pass
    human_judgment: false
duration: not measured
completed: 2026-10-09
status: complete
---

# Phase 175 Plan 116: Safe Diagnostics and Separate Counts

**Plan105 now says which bounded step failed while keeping API and Git counts independent.**

## Accomplishments

- Added closed stage/class/code diagnostics for the Plan105 helper, process, shape, policy,
  operation-limit, and orchestration outcomes. Raw errors, credentials, routes, argv, environment,
  process output, and local paths stay out of diagnostic receipts.
- Kept API request and Git operation uncertainty independent. Completed counts remain exact; a
  count becomes `UNKNOWN` only when that side's start or completion cannot be established.
- Preserved validated counts in UNKNOWN receipts, kept facts fail-closed, retained the older route
  diagnostic form, and proved that legacy v1 receipts remain inspectable.
- Used only injected fakes and temporary evidence roots for tests. No live provider, host
  credential helper, remote Git, CI, tag, merge, registry, or publication operation occurred.

## Checks Performed

- The new fake Git-stage regression failed first because the collector returned no diagnostic; the
  GSD RED evidence checker accepted that expected failure.
- Node syntax check passed; the focused collector suite passed 54 tests with 0 failures.
- The focused Plan105 ExUnit suite passed 20 tests with 0 failures.
- Elixir formatting and scoped diff checks passed.
- The required offline Plan115 inspection returned `UNKNOWN / INCOMPLETE_CANDIDATE_FACTS`,
  `diagnostic: null`, unknown public-request and Git counts, zero dry runs and tag attempts, and
  `read_intent: true`. It contacted no provider or remote.

## Plan115 Immutability

This repair does not identify which step failed in Plan115. The attempt remains terminal UNKNOWN;
its ALLOW was not reused. SHA-256 hashes of the receipt, spent read authorization, scope, and
lifecycle matched before and after the offline inspection:

| Plan115 artifact | SHA-256 before and after |
|---|---|
| Preflight receipt | `7622d5762f7a974c50d7da81f5398d44a2c884f989a197bb069362120f23a31e` |
| Spent read authorization | `bdceade95a754a9914f271a52ede2de816ac6b112c704ddf1be76d9c1627f7df` |
| Read scope | `f3bf08676d3fe9b0f70c3cd8b664a362a8733a873145bd1ac6c2ce34a9d08854` |
| Lifecycle | `25d737360e5956bc9507ea17f39ca5e88342d5a920723798126aca460c923503` |

## Task Commits

1. RED regression: `42125cb1`.
2. Collector and receipt repair: `0773bb48`.

Planning-document commits remain disabled by the workstream configuration.

## Release State and Next Action

Plan106 remains HELD in DAG-computed Wave21 because Plan115 did not produce the fresh
`PREFLIGHT_READY` receipt it requires. This local repair does not satisfy that precondition.
REL-13/14/15/17 remain OPEN; readiness remains BLOCKED; write permission and merge policy remain
UNKNOWN; tag authority remains NONE; the release hold remains ACTIVE. Phase175 remains IN
PROGRESS/INCOMPLETE, and Phase174 is still the last completed phase.

The local proof supports planning a separate bounded fresh-read path. The exact next GSD command is
`$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research`. Any read needs a fresh scope and
decision. Do not resume Plan106 until its fresh preflight and separate tag-decision preconditions
are satisfied.

---
*Phase: 175-rehearsal-and-publish*
*Plan: 116*
*Completed: 2026-10-09*

## Self-Check: PASSED

Verified: the listed files exist; both task commits are present; required tests, formatting, and scoped diff checks passed; the offline inspection completed; and Plan115 artifact hashes matched before and after inspection.
