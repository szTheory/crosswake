---
phase: 175-rehearsal-and-publish
plan: 138
subsystem: release-candidate-preflight
tags: [node, diagnostics, fake-process]
requires:
  - phase: 175-rehearsal-and-publish
    provides: Plan137 terminal UNKNOWN exact-head preflight receipt
provides:
  - Safe SHAPE/INVALID_SHAPE classification for rejected dry-run envelopes that recognized the expected row once
  - Focused fake-process regressions preserving process error precedence and fail-closed readiness
affects: [175-106, 175-46, 175-47, 175-48, 175-89]
requirements-completed: []
key-files:
  created:
    - evidence/175-plan138-local-diagnostic.json
    - 175-138-SUMMARY.md
  modified:
    - script/release_candidate/plan105_mirror_tag_collector.mjs
    - script/release_candidate/plan105_mirror_tag_collector.test.mjs
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-137-SUMMARY.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-LEARNINGS.md
    - AGENTS.md
    - .planning/workstreams/quality-ratchet-release/STATE.md
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md
    - .planning/estimation-calibration.json
key-decisions:
  - "Only row_count=1 with accepted=false maps to SHAPE/INVALID_SHAPE; parser acceptance remains unchanged."
  - "An earlier PROCESS diagnostic remains authoritative for nonzero process exits."
  - "The actual unexpected stdout bytes from Plan137 remain unknown and are not reconstructed."
completed: 2026-10-10
status: complete
---

# Phase 175 Plan 138: Dry-Run Failure Classification Summary

This local fix makes the next check say “the preview output format was invalid” when that is what happened. It does not change what output is accepted, recover Plan137's discarded output, or make a tag safe to create.

## Accomplishments

- Changed the rejected dry-run classifier so `row_count=1` maps to `TAG_DRY_RUN / SHAPE / INVALID_SHAPE`. All other fallback classifications and earlier process diagnostics retain precedence.
- Added injected fake-process cases for an unexpected extra line and an extra blank line. Both remain `accepted=false`, are not ready, and record zero tag/CI attempts.
- Confirmed a nonzero process exit retains the existing `PROCESS / PROCESS_EXIT_NONZERO` diagnostic.
- Kept dry-run output schema, strict parsing, privacy, limits, and release authority unchanged. The exact bytes from Plan137 were not retained and remain unknown.
- Corrected the active workstream handoff to reflect completed Wave40 and the new local Wave41 repair.

## Verification

- Focused Node filter: 4 test cases passed, 0 failed; all provider and process behavior came from injected fixtures.
- `node --check` passed for the collector and its test file.
- Scoped `git diff --check` passed for both source files.
- Evidence records zero network requests, host credential accesses, credential helper calls, live Git operations, live dry-runs, tag attempts, and CI requests.

The initial focused run exposed an incorrect test expectation: the process runner already assigns `PROCESS_EXIT_NONZERO` before dry-run parsing. The plan and regression were corrected to preserve that existing diagnostic, then the focused run passed.

## Release Posture

Plan137's attempt `6cc49f9e1427613969cee5a64721dbd9` remains consumed with terminal result SHA-256 `0cb6783ab9b1e0ed3e61ef23175febcf2c67286e9980053e6d2aeb30ded825ff`. Its `UNKNOWN / OBSERVATION_UNAVAILABLE` result is unchanged. Plan106 and Plans46–48/89 remain held; REL-13/14/15/17 remain open; readiness remains blocked; write permission and merge policy remain unknown; tag authority is none; release hold remains active. No new observation or release action was performed.

No further GSD command is eligible until fresh, independently verifiable candidate/policy evidence supports a materially distinct bounded observation path and a separately reviewed plan.

## Lesson for future handoffs

Start with ordinary language: what was checked, what happened, what remains unknown because the record did not keep the relevant detail, whether anything was changed, and what can happen next. Explain internal status codes after that. Avoid phrases such as “current evidence” unless the specific observation is named.
