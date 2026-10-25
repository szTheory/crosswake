---
phase: 175-rehearsal-and-publish
plan: 63
subsystem: release-evidence
tags: [github-actions, diagnostic, evidence, fail-closed]
requires:
  - phase: 175
    provides: Plan62 blocked evidence and Plan61 exact-SHA collection corrections
provides:
  - Plan63 independent run, jobs, workflow contents, and status diagnostic facts
  - Exclusive sanitized diagnostic artifact and lifecycle with hard no-rerun disposition
affects: [release-preflight, quality-ratchet-release]
actuals:
  tokens: null # Shared dirty changes prevent reliable plan-local diff measurement.
  tasks: 3
  commits: 0 # Git metadata writes are prohibited by the execution boundary.
tech-stack:
  added: []
  patterns: [bounded envelope diagnostics, independent evidence stages, exclusive read-only lifecycle]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-63-SUMMARY.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-ios-tag-026-plan63-diagnostic.json
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-ios-tag-026-plan63.lifecycle.jsonl
  modified:
    - lib/crosswake/release_candidate/ios_tag_source_runner.ex
    - lib/crosswake/release_candidate/ios_tag_source_evidence.ex
    - test/crosswake/release_candidate/ios_tag_source_runner_test.exs
    - test/crosswake/release_candidate/ios_tag_source_evidence_test.exs
    - .planning/workstreams/quality-ratchet-release/STATE.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/continue.md
key-decisions:
  - "Plan63 records only bounded response-shape facts; it does not infer an alternate workflow-content encoding."
  - "The one diagnostic attempt cannot request a CI rerun or promote repair/release eligibility."
patterns-established:
  - "Successful exact run and jobs facts remain intact when workflow-content decoding fails."
requirements-completed: []
coverage:
  - id: D1
    description: Independent run/job/workflow/status diagnostic stages and closed evidence schema
    verification:
      - kind: unit
        ref: mix test test/crosswake/release_candidate/ios_tag_source_evidence_test.exs test/crosswake/release_candidate/ios_tag_source_runner_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: One fresh read-only diagnostic with bounded safe facts and no rerun
    verification:
      - kind: other
        ref: Crosswake.ReleaseCandidate.IosTagSourceRunner.validate_plan63_artifacts!/0
        status: pass
    human_judgment: false
  - id: D3
    description: Matching Plan63 closeout markers preserve all release holds
    verification:
      - kind: other
        ref: Crosswake.ReleaseCandidate.IosTagSourceRunner.validate_plan63_closeout!/0
        status: pass
    human_judgment: false
duration: unknown
completed: 2026-10-01
status: complete
---

# Phase 175 Plan 63: Workflow Contents Diagnostic Summary

**The independent read-only diagnostic retained exact run and job facts while safely classifying the workflow contents envelope as invalid base64.**

## Performance

- **Duration:** unknown
- **Completed:** 2026-10-01
- **Tasks:** 3
- **Commits:** 0 (Git metadata writes prohibited by the execution boundary)

## Accomplishments

- Added a Plan63-only diagnostic schema and collector. The workflow contents probe now runs after run-roster and attempt-job collection, so a later contents failure does not erase successful facts.
- Added distinct safe reason codes and capped field/encoding/byte-count diagnostics. The artifact and lifecycle paths are exclusive; the lifecycle allows only task entry, reservation, and terminal collection.
- Collected exactly one fresh diagnostic as attempt `7cf763206444070c90d689177721a9f3`. Exact run `36438452825`, attempt 1, had a complete roster and 49 normalized jobs (47 SUCCESS, 2 FAILURE). Required status collection reconciled 49 total / 49 unique with completeness TRUE.
- Workflow contents had content and encoding fields, base64 encoding was declared, and the encoded length was within cap (111,781 bytes). Strict base64 decoding failed (`invalid_base64`); no decoded bytes, raw response, workflow bytes, or workflow-content hash were persisted. Aggregate proof remains UNKNOWN.
- CI rerun is `NOT_REQUESTED`; repair eligibility and candidate release readiness remain BLOCKED. Plan55 remains UNKNOWN, REL-13 and REL-17 remain OPEN, and the release hold remains ACTIVE.

## Verification

- Focused suites: 61 tests, 0 failures.
- `mix format --check-formatted` passed for the four owned implementation/test files.
- Scoped `git diff --check` passed.
- Plan63 artifact/lifecycle validator passed. The artifact contains only the closed schema; lifecycle readback binds all three events to the same opaque attempt ID.
- Plan63 closeout validator passed after identical markers were written to this summary, `STATE.md`, and `continue.md`.
- Plan59/60/62 artifact and lifecycle SHA-256 values match their pre-collection baselines. Plan61 has no separate artifact/lifecycle pair.

## External Actions and Boundary

The Plan63 collector ran once. It made bounded read-only collection requests only. No CI rerun request, source split, push dry-run, tag write, merge, Gate2, recovery, registry operation, publication, or release-gate closure occurred. The Plan63 output contains no raw provider response, workflow content, command output, credentials, or provider-content hash.

The contents predicate failed at base64 decoding after field presence, encoding recognition, and encoded-size checks passed. Do not infer a different encoding or silently normalize the response. A separately reviewed local plan may test a bounded, non-persisting decoder diagnostic against fake fixtures to distinguish line wrapping/padding from other malformed content before considering another fresh read-only attempt.

## Deviations from Plan

The shared execution boundary makes `.git` read-only, so code and closeout changes remain uncommitted. No staging, commit, reset, stash, clean, or worktree operation was performed.

## Next Action

Create a separately reviewed plan for local-only base64 decoder diagnostics and fake-fixture coverage. Any additional live collection requires its own exclusive attempt and fresh authorization review. Do not replay Plan63 or reuse its artifact/lifecycle. Preserve Plan55 UNKNOWN, REL-13/REL-17 OPEN, candidate release readiness BLOCKED, and the release hold ACTIVE.

<!-- plan63-closeout: {"attempt_id":"7cf763206444070c90d689177721a9f3","candidate_release_readiness":"BLOCKED","ci_rerun":"NOT_REQUESTED","plan55":"UNKNOWN","rel13":"OPEN","rel17":"OPEN","release_hold":"ACTIVE","schema":"crosswake-plan63-closeout/v1","sha256":"2d7a3f4d35008855ce721384e60b3d503e0524990f8e7fc7942ef4931bb14c8d"} -->

## Self-Check: PASSED

The Plan63 artifact, lifecycle, and summary exist. The Plan63 marker is identical in this summary, `STATE.md`, and `continue.md`; the artifact/lifecycle and closeout validators passed. Historical Plan59/60/62 evidence hashes match the captured baselines.
