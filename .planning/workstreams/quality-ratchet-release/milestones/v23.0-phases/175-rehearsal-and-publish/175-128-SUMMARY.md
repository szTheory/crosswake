---
phase: 175-rehearsal-and-publish
plan: 128
subsystem: release-evidence
tags: [plan105, current-read, git-subtree, release-hold]
requires:
  - phase: 175-rehearsal-and-publish
    provides: Plan127's repaired Elixir decoder and fake-process regression
provides:
  - One scope-bound current read with a sealed terminal UNKNOWN result and no promoted facts
  - A local reproduction and repair for macOS wc-padded Git subtree progress
affects: [Plan129, REL-13, REL-17]
actuals:
  tokens: not measured
  tasks: 3
  commits: 0
tech-stack:
  added: []
  patterns: [bounded progress parsing, plain-language scope-bound approval]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-128-SUMMARY.md
  modified:
    - script/release_candidate/plan105_mirror_tag_collector.mjs
    - script/release_candidate/plan105_mirror_tag_collector.test.mjs
    - AGENTS.md
  - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-128-PLAN.md
    - .planning/workstreams/quality-ratchet-release/STATE.md
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/.continue-here.md
key-decisions:
  - "The one authorized read is terminal UNKNOWN and cannot be retried or promoted to current facts."
  - "Accept only bounded space padding in the Git subtree denominator, which comes from wc -l output."
  - "A plain-language ALLOW/HOLD is bound internally to the one card just shown; users do not copy hashes."
patterns-established:
  - "Stream and validate Git subtree progress without retaining process output."
  - "Scope one-use approval to the displayed attempt without exposing hash-copying as a user task."
requirements-completed: []
coverage:
  - id: D1
    description: "The local subtree parser accepts the actual padded denominator and still enforces its byte, record, counter, and split identity checks."
    requirement: REL-13
    verification:
      - kind: unit
        ref: "node --test script/release_candidate/plan105_mirror_tag_collector.test.mjs"
        status: pass
      - kind: integration
        ref: "Local no-network split of the pinned source commit; 3,804 progress records and expected split OID"
        status: pass
    human_judgment: false
  - id: D2
    description: "The scope-bound current read is sealed once and does not promote incomplete results to facts or release authority."
    verification:
      - kind: other
        ref: "Offline validation of attempt ee95e7a2150e8a34b9738a1c5ca4693d authorization, result, counts, and lifecycle"
        status: pass
    human_judgment: false
duration: not measured
completed: 2026-10-10
status: complete
---

# Phase 175 Plan 128 Summary

**The one current read returned no usable facts; a local reproduction exposed and fixed the exact subtree progress formatting mismatch.**

Plan128 branch: ALLOW/UNKNOWN
Plan128 result SHA-256: f05e2d876f140f29b3258da0f7c02cdb3705b056e1b18c29fdef24b1d7fc795f

## Accomplishments

- Applied the user's plain-language approval to the one PENDING Plan128 card. The decision was bound internally to that attempt and its displayed scope, card, and collector. No hashes were requested from the user.
- The one authorized read ended `ALLOW/UNKNOWN`, result SHA-256 `f05e2d876f140f29b3258da0f7c02cdb3705b056e1b18c29fdef24b1d7fc795f`. It retained no current facts. Its safe diagnostic is `SUBTREE_SPLIT / PROCESS_STDERR_NONEMPTY`.
- Terminal counts are 7 GitHub requests, 11 Git operations, 1 credential-helper check, 2 permission checks, and zero dry-run, tag, or CI attempts. The lifecycle contains exactly one read intent and one terminal result. This attempt and approval are spent; no retry occurred.
- A no-network reproduction against the pinned source commit showed why the existing parser rejected the split: macOS `wc -l` pads its count with spaces. All 3,804 records had four spaces before the denominator. The parser now accepts only a bounded 0–8 ASCII-space pad in that position; tabs, excess padding, malformed records, bad transitions, incomplete output, and incorrect split/tree identities still fail closed.
- The full Node collector suite passed: 101 tests, 0 failures. A fresh local shared clone and detached checkout reproduced the exact split with exit status 0, 92,883 stderr bytes classified as 3,804 valid progress records, four-space padding, and the expected split object ID. No network was used and no process output was retained.

## Files Changed

- `script/release_candidate/plan105_mirror_tag_collector.mjs` — accept the bounded `wc -l` padding used by the local Git subtree progress format.
- `script/release_candidate/plan105_mirror_tag_collector.test.mjs` — cover padded counts and reject tab or excessive padding.
- `AGENTS.md` — record that the user may answer `allow` or `hold` in plain language; the coordinator binds it internally to the displayed scope.
- `175-128-PLAN.md` — correct the terminal validator so safe diagnostic values such as `PROCESS_STDERR_NONEMPTY` are not mistaken for raw process output.
- Active state and handoff documents — record the sealed result, local repair, preserved holds, and next command.

## Deviations from Plan

After Task 3 returned UNKNOWN, the evidence identified a separate, reproducible local bug in the progress parser. The plan's existing assertion used a substring scan over the serialized result and incorrectly rejected the allowlisted diagnostic value because it contains the word `stderr`. The assertion now checks structured keys, allowed reasons, and the required null facts for UNKNOWN instead of rejecting safe diagnostic values. The distinct `wc -l` padding bug was repaired and verified before handoff.

No new provider read was made during this repair. The repair does not turn the consumed read into current facts or authorize a future read.

## Release Posture and Next Step

Last completed phase: 174. Phase175 remains IN PROGRESS and INCOMPLETE. Plan106 remains HELD; REL-13/14/15/17 remain OPEN; readiness BLOCKED; write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE.

The distinct local parser defect is now reproduced and repaired, so the exact next GSD command is `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research` to plan a fresh one-use read with the corrected collector. Any new read needs its own displayed scope and plain-language approval. The user does not need to copy digests into a reply. No write, push, dry-run, tag, CI, merge, registry, publication, or release-authority operation occurred.

The local split check removed its temporary checkout when it exited. The environment denied process-list access, so I could not inspect unrelated processes.

No commit was made because `phase_commit_docs.175=false`.

---
*Phase: 175-rehearsal-and-publish*
*Plan: 128*
*Completed: 2026-10-10*
