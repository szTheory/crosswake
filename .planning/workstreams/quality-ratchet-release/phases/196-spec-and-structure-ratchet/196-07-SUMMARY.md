---
phase: 196-spec-and-structure-ratchet
plan: "07"
subsystem: testing
tags: [elixir, privacy, offline, boundary-tests]
status: complete
requires:
  - phase: 196-06
    provides: Sequential execution base and non-vacuity guard
provides:
  - Explicit Journal suffix and constant-error privacy boundaries
  - Absolute route anchors and exhaustive closed observation field/key checks
  - Value-free receipts for nine executed mutation controls
affects: [196-13, 196-14, 196-15, SPEC-03]
tech-stack:
  added: []
  patterns: [Pinned boundary tables, Forged-struct projection revalidation, Finally-restored mutation controls]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/privacy-boundaries.json
  modified:
    - test/crosswake/offline/journal_test.exs
    - test/crosswake/offline/safe_observation_test.exs
    - lib/crosswake/offline/safe_observation.ex
key-decisions:
  - Preserve Journal domain storage and repair only the demonstrated SafeObservation route-anchor defect.
  - Retain closed case identities, counts and process outcomes without rejected operands or raw failure logs.
requirements-completed: []
requirements-pending: [SPEC-03]
actuals:
  tokens: 4653
  tasks: 2
  commits: 3
plan_head_before: 4a2d1611c3072be941e33d2fdea139be6730fd0f
plan_head_after: 605b752e3e9aff3db83467941c9a587a22caad15
coverage:
  - id: D10
    description: Scope suffix boundaries and closed constant errors
    requirement: SPEC-03
    verification:
      - kind: unit
        ref: mix test test/crosswake/offline/journal_test.exs
        status: pass
    human_judgment: false
  - id: D11
    description: Every closed observation field and key is validated before projections
    requirement: SPEC-03
    verification:
      - kind: unit
        ref: mix test test/crosswake/offline/safe_observation_test.exs
        status: pass
    human_judgment: false
duration: 6min
completed: 2026-10-27
---

# Phase 196 Plan 07: Scope and observation privacy boundaries Summary

**Journal suffix tables preserve constant errors; SafeObservation rejects trailing LF and revalidates every closed field and measurement before telemetry, logger and doctor projections.**

## Performance

- Started: 2026-10-27T15:56:05Z; production verification complete: 2026-10-27T16:01:00Z.
- Tasks: 2/2; production/evidence files: 4.
- Actuals use 18,609 realized diff characters divided by four, rounded up to 4,653. The persisted plan ledger measures three task commits before this SUMMARY; metadata commits are separate.

## Accomplishments

- Journal explicitly pins 24 unique cases: three accepted and 21 rejected. Suffix lengths 15/16/128/129, legal ASCII alphabet, LF/CRLF, embedded newline, prefix/suffix/NUL/space injection, nil/integer/float/list/map/atom/empty/singleton values, multibyte/lookalike prefixes and invalid encoding are exercised. Accepted values return unchanged. Rejections expose only the exact constant ArgumentError message, struct fields, inspection and formatted banner; captured logging remains empty. Proof-facing serialization contains only closed labels. Legitimate domain scope metadata remains unchanged.
- SafeObservation independently pins all eight fields, six enum domains with 24 accepted field/value pairs and 17 distinct atoms. The 78 cross-domain exclusions preserve intentional shared atoms while rejecting every other domain combination. Each field has 14 hostile encoding/type variants (112 executions), with eight missing-field, eight string-field-key, four unknown-key and nine additional route grammar cases.
- All three measurement keys accept integer endpoints 0 and 1,000,000 (six cases). Each key rejects 17 invalid values and eight hostile/unknown key variants (51 value and 24 key cases). These include 1,000,001, negative values, exact floating endpoints, strings, nested maps, lists, nil, LF/CRLF, Unicode and invalid encoding. Empty measurements remain valid. Two opposite insertion-order constructions produce identical exact projections.
- The new tables execute 35 valid and 295 rejected cases, each through five entry points: constructor, validate, telemetry, logger and doctor. Rejections use forged structs after construction checks. This gives 1,650 table boundary executions, plus 40 nonmap/foreign-struct entry checks and one constructor rejection of its own struct. Existing tests remain alongside these additions. Exact rule/path equality also pins the complete two-field Error struct; rejected operands do not enter assertion messages or receipts.

## Task Commits

1. Task 196-07-01 — `fef37c55`: scope suffix and constant-diagnostic tables plus value-free evidence.
2. Task 196-07-02 RED — `d3f46839`: observation field/key/projection tables and real trailing-LF regression.
3. Task 196-07-02 GREEN — `605b752e`: replace route line anchors with absolute anchors; retain executed controls.

No tracked file deletions occurred. Each commit ran the Phase193 privacy script conditionally with absolute arguments for every scoped file, followed immediately by a rescan.

## Verification and controls

1. `mix test test/crosswake/offline/journal_test.exs` — exit0, four tests, zero failures. Re-run after restoring controls also passed.
2. `mix test test/crosswake/offline/safe_observation_test.exs` — original source RED exit2, 11 tests, exactly two failures in the dedicated trailing-LF test and field-route-LF table. Both were the planned rejection assertions, because the original validator accepted LF. No fixture/import/discovery failure authorized the fix. After the repair: exit0, 11 tests, zero failures.
3. `mix test test/crosswake/offline/journal_test.exs test/crosswake/offline/safe_observation_test.exs` — final exit0, 15 tests, zero failures.
4. `mix format --check-formatted lib/crosswake/offline/safe_observation.ex test/crosswake/offline/journal_test.exs test/crosswake/offline/safe_observation_test.exs` — exit0 after explicitly formatting all three files.
5. `git diff --check` — exit0.
6. `elixir script/check_absence_is_not_success.exs --collections-mode enforce` — exit0, 311 files, 84 reviewed findings, delta0. This checks that the new tables do not regress the previous plan's collection contract; no baseline was changed.

Mutation controls executed sequentially in the same checkout via Python subprocess calls to the corresponding exact `mix test` command. Each mutation started from the saved source bytes, required process exit2 and the named failed assertion, captured output only in process memory, and restored the original bytes in `finally`. Final passing tests recompiled restored production code. The committed JSON retains closed identities/counts rather than failure logs.

| Control | Exit | Failed tests | Result |
|---|---:|---:|---|
| Journal line anchors | 2 | 1 | Target scope table failed |
| Journal minimum widened | 2 | 1 | Target scope table failed |
| Journal maximum widened | 2 | 1 | Target scope table failed |
| Observation line anchors | 2 | 2 | Both LF assertions failed |
| Measurement maximum widened | 2 | 1 | Measurement table failed |
| Measurement maximum exclusive | 2 | 2 | Measurement and ordering tests failed |
| Measurement minimum widened | 2 | 1 | Measurement table failed |
| Measurement minimum exclusive | 2 | 2 | Measurement and ordering tests failed |
| Measurement floats accepted | 2 | 1 | Measurement table failed |

## Source identities

SHA256 identities after final restoration and formatting:

- Journal source: `48b89872653886c64cf6ac882dc9804be32fdc2f50f363ba54c795ce6c841bff` (unchanged).
- SafeObservation source: `fc44a5e6fcbc7e92059d6e2f833503bc0d7762dafb00fc78649b46bc0c996965`.
- Journal tests: `ce166a4a5858b48981c0938e951c8ad7249838ae7d418874414e0eb213f3e76b`.
- SafeObservation tests: `677b41bdba5d8c6e37a49b65f88d2a199ad65abb59868fe735df51e14efaa920`.

## Decisions and deviations

Followed D-10/D-11 with no production/schema/dependency expansion. Journal's required behavior already existed, so no Journal implementation change was needed; real anchor and bound mutations proved the new tests discriminate. SafeObservation's only production change is the planned absolute-anchor correction. No refactor was necessary. The plan is `type: execute` and configured TDD mode is false; a separate test-only RED commit and GREEN fix nevertheless preserve the intended regression sequence. Raw ExUnit failure reports were not committed, following the governing value-free privacy requirement.

During test development, corrected test expectations for ArgumentError's standard exception marker and the legitimate integer measurement value 1 before recording the LF RED. No additional production defect was found. The sandbox initially refused git index/ledger writes; the authorized local commit succeeded on escalation after reading the unchanged index state. No automatic approval rejection occurred.

No stubs, skipped tests, unrun plan verification or new security surface remain. No authentication setup was needed. No push, PR, merge, release, tag or remote deletion occurred.

## Next readiness

Last completed phase remains195. Active phase196 now has seven completed plans; next eligible plan is196-08. Exact next command: `$gsd-execute-phase 196 --ws quality-ratchet-release`, resuming at196-08-PLAN.md. All eight Phase196 requirements and GR-06 remain pending independent phase verification. Full mutation pilot, other guards, CI promotion and delivery remain with later plans; adopter work stays parked.

## Self-Check: PASSED

The SUMMARY, receipt and both test files exist. All three recorded task commits are ancestors of HEAD605b752e. No tracked deletions or untracked generated files remain.
