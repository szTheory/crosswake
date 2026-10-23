---
phase: rehearsal-and-publish
plan: 75
subsystem: infra/testing
tags: [release-evidence, github-rulesets, bounded-read, elixir, node]
requires:
  - phase: 175-73
    provides: Plan73 local preflight and evidence contract for the approved read scope
  - phase: 175-74
    provides: Safe blocked disposition pending fresh Plan73 PREFLIGHT_READY evidence
provides:
  - Rulesets-only Plan73 policy observation with explicit parent inclusion and effective repository read permission
  - Closed policy evidence with exact source/mirror tag applicability and fail-closed validation
  - Offline Node collector contract tests for route rejection, pagination, bounded projection, and response caps
affects: [175-76, release-candidate]
actuals:
  tokens: 9431
  tasks: 2
  commits: 2
  plan_head_before: 39b698763bb0356fb38ed4c444ceff8f6c79c83d
  plan_head_after: f49231cbc121c444e1082467931581512ffb9501
tech-stack:
  added: []
  patterns: [parent-inclusive ruleset pagination, path-separator-aware ref matching, closed applicability evidence, local fetch stubs]
key-files:
  created:
    - script/release_candidate/ios_tag_source_collector_policy.test.mjs
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-75-SUMMARY.md
  modified:
    - lib/mix/tasks/crosswake.release.mirror_tag_026.ex
    - script/release_candidate/ios_tag_source_collector.mjs
    - lib/crosswake/release_candidate/ios_mirror_tag_repair.ex
    - lib/crosswake/release_candidate/ios_tag_source_evidence.ex
    - test/crosswake/release_candidate/ios_mirror_tag_repair_test.exs
decisions:
  - "Observe tag policy only through the approved rulesets list with includes_parents=true and repository read permission; keep the retired protection route unreachable."
  - "Classify only explicit, complete ruleset conditions; unsupported patterns, missing parent/repository scope, incomplete pages, or unknown applicability cannot produce ready evidence."
  - "Keep REL-13 and REL-17 open, candidate readiness blocked, and the release hold active until fresh independent prerequisites pass."
metrics:
  duration: 31min
  completed: 2026-10-03
status: complete
requirements-completed: []
coverage:
  - id: D1
    description: "Plan73 policy observation uses the approved parent-inclusive rulesets route and validates exact tag applicability."
    requirement: REL-13
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/ios_mirror_tag_repair_test.exs"
        status: pass
      - kind: integration
        ref: "script/release_candidate/ios_tag_source_collector_policy.test.mjs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Retired routes, incomplete or ambiguous observations, and bounded collector failures fail closed without live requests."
    requirement: REL-17
    verification:
      - kind: integration
        ref: "node --test script/release_candidate/ios_tag_source_collector_policy.test.mjs"
        status: pass
      - kind: unit
        ref: "mix format --check-formatted [Plan75 Elixir paths]"
        status: pass
    human_judgment: false
---

# Phase 175 Plan 75: Rulesets-Only Plan73 Policy Evidence Summary

**Plan73's local policy path now observes parent-inclusive repository rulesets, validates exact tag applicability, and keeps the release hold blocked without performing a remote read.**

## Performance

- **Duration:** 31 min
- **Started:** 2026-10-03T15:45:17Z (active workstream handoff timestamp)
- **Completed:** 2026-10-03T16:16:34Z
- **Tasks:** 2
- **Files modified:** 6 implementation/test files plus this summary

## Accomplishments

- Removed `/tags/protection` from the coordinator and collector allowlists. The policy adapter now reads repository rulesets with `includes_parents=true` and retains the existing effective read-permission observation.
- Added a closed `tag_applicability` map for `refs/tags/ios-core-v0.2.6` and `refs/tags/v0.2.6`. The reducer requires explicit active tag target, enforcement, rules, repository scope, and ref include/exclude conditions; path wildcards do not cross `/`, and unsupported extglob forms remain UNKNOWN.
- Bound the applicability map into the canonical policy digest and updated the Plan73 evidence validator and Plan74 require-ready path to reject retired keys and UNKNOWN applicability.
- Added local fetch-stub tests for pre-fetch route rejection, one-page/empty and paginated rulesets, parent inclusion on every page, sanitized projection, skipped/repeated pages, oversized bodies, and the four-page cap. The focused ExUnit suite invokes these Node tests through the existing CI Mix lane.
- Preserved the existing `COVERAGE.md` OPT-OUT for the legacy endpoint; no new CI job was added.

## Verification

- `MIX_ENV=test mix test test/crosswake/release_candidate/ios_mirror_tag_repair_test.exs --max-cases 1` — passed, 24 tests, 0 failures. This includes the nested Node collector tests.
- `node --test script/release_candidate/ios_tag_source_collector_policy.test.mjs` — passed, 6 tests, 0 failures.
- `mix format --check-formatted lib/mix/tasks/crosswake.release.mirror_tag_026.ex lib/crosswake/release_candidate/ios_mirror_tag_repair.ex lib/crosswake/release_candidate/ios_tag_source_evidence.ex test/crosswake/release_candidate/ios_mirror_tag_repair_test.exs` — passed.
- `node --check script/release_candidate/ios_tag_source_collector.mjs` — passed.
- `node --check script/release_candidate/ios_tag_source_collector_policy.test.mjs` — passed.
- `rg -q 'legacy tag-protection endpoint.*OPT-OUT' .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/COVERAGE.md` — passed.
- No remote request, credential probe, Plan73 artifact, Plan74 action, CI rerun, tag write, merge, Gate 2, registry write, or publication was performed.

## Task Commits

1. **Task 1: Rulesets-only policy path and offline contract** — `ac47394e` (`feat(175-75): replace retired tag policy route with rulesets`).
2. **Task 2: Collector cap regressions** — `f49231cb` (`test(175-75): verify collector caps fail closed`).

## Files Created/Modified

- `lib/mix/tasks/crosswake.release.mirror_tag_026.ex` — rulesets-only policy reduction and tag applicability.
- `script/release_candidate/ios_tag_source_collector.mjs` — approved route, parent-inclusive pagination, and bounded sanitized ruleset projection.
- `lib/crosswake/release_candidate/ios_mirror_tag_repair.ex` — rulesets-only route allowlist and UNKNOWN defaults.
- `lib/crosswake/release_candidate/ios_tag_source_evidence.ex` — closed Plan73 policy validation and applicability contract.
- `test/crosswake/release_candidate/ios_mirror_tag_repair_test.exs` — fake policy and coordinator regression cases.
- `script/release_candidate/ios_tag_source_collector_policy.test.mjs` — local fetch-stub contract suite.

## Decisions Made

- Kept policy observation within the previously approved repository rulesets and permission reads; no authority or endpoint scope was added.
- Empty rulesets are known not to apply only when the complete parent-inclusive listing and repository permission observation succeed.
- REL-13/REL-17 remain OPEN; Plan55/70 remain UNKNOWN; candidate readiness remains BLOCKED; merge-policy remains UNKNOWN; release hold remains ACTIVE; Plans45–48 remain held.

## Deviations from Plan

None. The existing `COVERAGE.md` already stated the retired endpoint OPT-OUT and the supported rulesets replacement, so it was verified and preserved without a content change.

## Issues Encountered

The standard `state.advance-plan` helper could not parse this workstream's custom `current_plan` string. The specific Plan76 handoff was updated in the active workstream STATE and ROADMAP directly; the plan progress row and execution metrics were recorded through the SDK.

## User Setup Required

None for Plan75. Plan76 remains separately credential-gated and was not executed.

## Next Phase Readiness

Plan75's local acceptance criteria pass. Plan76 is the next separate Wave 6 action only when `CROSSWAKE_PLAN73_READ_TOKEN` is available: `$gsd-execute-phase 175 --ws quality-ratchet-release --wave 6`. Do not inspect alternate credentials or perform the Plan73 read before the gate is satisfied.

## Self-Check: PASSED

- The summary and all six Plan75 implementation/test artifacts exist.
- Both task commits are present: `ac47394e` and `f49231cb`.
- Focused ExUnit and Node tests, formatting, Node syntax, and the existing coverage OPT-OUT check pass.

---
*Phase: rehearsal-and-publish*
*Completed: 2026-10-03*
