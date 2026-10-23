---
phase: 175-rehearsal-and-publish
plan: 105
subsystem: release-evidence
tags: [ios-mirror, read-scope, bounded-read, release-hold]
requires:
  - phase: 175-rehearsal-and-publish
    provides: Plan104's comparison snapshot for the source split, mirror refs, and PR #219
provides:
  - Locally tested Plan105 scope, one-use approval, preflight, and terminal inspection path
  - One exact-approved Plan105 attempt with an inspected UNKNOWN result
affects: [REL-13, REL-17, Phase175 release hold]
actuals:
  tokens: 28000
  tasks: 3
  commits: 0
tech-stack:
  added: []
  patterns:
    - One-use approval bound to an exclusive attempt and exact read scope
    - Sanitized terminal evidence with unknown operation counts preserved
key-files:
  created:
    - lib/crosswake/release_candidate/plan105_mirror_tag.ex
    - script/release_candidate/plan105_mirror_tag_collector.mjs
    - test/crosswake/release_candidate/plan105_mirror_tag_test.exs
    - 175-105-SUMMARY.md
  modified:
    - lib/mix/tasks/crosswake.release.mirror_tag_026.ex
key-decisions:
  - "The exact ALLOW applied only to attempt 818ff8e63b58aee8ef00878bdc76cb37 and its displayed scope digest."
  - "The single preflight ended UNKNOWN and is consumed; do not retry it or infer current source, mirror, candidate, policy, or permission facts."
  - "REL-13/14/15/17 remain OPEN, readiness BLOCKED, tag authority NONE, and the release hold ACTIVE."
patterns-established:
  - "A read approval authorizes one bounded observation only; it grants no tag-write or release authority."
requirements-completed: []
coverage:
  - id: D1
    description: "Offline fake and local repository checks prove the scoped path and one-ref create-only refspec behavior."
    requirement: REL-13
    verification:
      - kind: unit
        ref: "mix test test/crosswake/release_candidate/plan105_mirror_tag_test.exs --max-cases 1 (8 tests, 0 failures)"
        status: pass
      - kind: other
        ref: "node --check script/release_candidate/plan105_mirror_tag_collector.mjs"
        status: pass
    human_judgment: false
  - id: D2
    description: "One exact-approved preflight is sealed and independently inspected as UNKNOWN without granting a tag attempt."
    requirement: REL-17
    verification:
      - kind: other
        ref: "mix crosswake.release.mirror_tag_026 --mode plan105-inspect --expect ready-or-held --attempt-id 818ff8e63b58aee8ef00878bdc76cb37 --json (exit 0; terminal UNKNOWN)"
        status: pass
    human_judgment: false
duration: not separately measured
completed: 2026-10-08
status: complete
---

# Phase 175 Plan105 Summary

**The exact-approved current check stopped before it could confirm any source, mirror, PR, policy, or permission facts. The attempt is sealed as UNKNOWN and must not be repeated.**

## Accomplishments

- Added a new Plan105 Mix path for preparing and inspecting a fixed read scope, recording one exact read decision, and running at most one approved preflight.
- Added fake-only tests for pending, approval, ready, changed, unavailable, and redaction behavior. A temporary local bare Git repository proved the exact tag refspec creates one ref and a second push cannot update it. The collector rejects force, extra-ref, and overflow dry-run output.
- Prepared attempt `818ff8e63b58aee8ef00878bdc76cb37` and inspected it as PENDING with zero recorded requests, Git operations, permission checks, credential-helper checks, dry runs, and tag attempts.
- The user selected ALLOW for this exact attempt and scope. The authorization was recorded and inspected before the single preflight invocation.
- The preflight ended `UNKNOWN / INCOMPLETE_CANDIDATE_FACTS`. The terminal inspector passed and confirmed that no dry run or tag attempt occurred. Permission and credential-helper checks both remained at zero.

## What the result means

The first current-information snapshot did not finish, so there are no usable current facts. The saved record marks the public-request and Git-operation counts UNKNOWN. The collector advances to Git operations only after the first PR, commit, repository, and ruleset snapshot completes; the inspector shows zero permission checks, consistent with the failure happening before that point. The collector did not save which request or safe transport error caused the stop. We cannot tell from this attempt whether GitHub rejected a request, the network failed, or a returned response did not match the expected shape.

The consumed attempt is not eligible for another run. Plan106's separate tag decision and write are ineligible because no `PREFLIGHT_READY` result exists. No tag, CI, merge, registry, or release operation occurred. REL-13/14/15/17 remain OPEN; readiness BLOCKED; write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE; Plans45–48 HELD; Phase175 INCOMPLETE.

## Evidence

- Scope: `evidence/175-plan105-818ff8e63b58aee8ef00878bdc76cb37-read-scope.json`
- Read authorization: `evidence/175-plan105-818ff8e63b58aee8ef00878bdc76cb37-read-authorization.json`
- Preflight: `evidence/175-plan105-818ff8e63b58aee8ef00878bdc76cb37-preflight.json`
- Lifecycle: `evidence/175-plan105-818ff8e63b58aee8ef00878bdc76cb37.lifecycle.jsonl`
- Scope SHA-256: `631a22d25de802e52b4f6c07f67ba74b6fc1e9f573a2c2036405b884b76cb449`
- Read authorization SHA-256: `615ef27dcec842f4744eba28dc20a20cee17bd21d415da35b9b7b6babd2e6247`
- Preflight SHA-256: `f7580f963b3c2b79fbae54a4cc1471fc447101b63ded1c9ebbfaafac15588b1e`
- Collector SHA-256: `c83e551564cec8c44c05cce30922b2e71c8ff7b5bfd8e823363a8cad56184cad`

No raw provider response, command output, credential-helper value, or credential was retained. The local Git test used only a temporary bare repository and did not contact the mirror.

## Verification

- `mix test test/crosswake/release_candidate/plan105_mirror_tag_test.exs --max-cases 1` — 8 tests, 0 failures.
- `node --check script/release_candidate/plan105_mirror_tag_collector.mjs` — passed.
- The Plan105 PENDING, read-decision, and terminal inspectors all exited 0; terminal status is UNKNOWN.

## Next Phase Readiness

Plan106 cannot run because this attempt did not produce `PREFLIGHT_READY`. Plan105's consumed attempt and its scope-bound ALLOW cannot be reused. The next GSD action is to plan local repairs: make the collector retain a small, safe reason for an early GitHub-information failure, and complete/prove the production apply adapter that currently returns `production_apply_not_available`. This command plans local work only: `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research`. Do not start another live read until the diagnostic path is proven locally and a fresh exact ALLOW is recorded; do not attempt a tag write until the production adapter is proven locally and a separate exact tag ALLOW is recorded.

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-10-08*
