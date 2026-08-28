---
phase: 160-scoped-replay-and-auth-safety
plan: "09"
subsystem: Phoenix scoped replay admission and idempotency
tags: [elixir, phoenix, replay, opaque-scope, idempotency, authorization]
requires:
  - phase: 160-02
    provides: host replay admission and ordered sync controller
  - phase: 160-07
    provides: scope-qualified ReviewEvent idempotency model
provides:
  - Full-string opaque scope validation before host authority resolution
  - Status-aware persisted idempotency outcomes for duplicates and race recovery
  - Accepted-only browser acknowledgement prefixes
affects: [scoped-replay, offline-island, first-adopter-proof, security-audit]
tech-stack:
  added: []
  patterns: [anchored opaque identifier validation, closed persisted-outcome mapper, ordered retained rejection]
key-files:
  created:
    - .planning/phases/160-scoped-replay-and-auth-safety/160-09-SUMMARY.md
  modified:
    - examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex
    - examples/phoenix_host/lib/crosswake_example/local_first/study.ex
    - examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex
    - examples/phoenix_host/test/crosswake_example/local_first/replay_admission_test.exs
    - examples/phoenix_host/test/crosswake_example/local_first/study_test.exs
    - examples/phoenix_host/test/crosswake_example/local_first/sync_controller_test.exs
    - lib/crosswake/offline/journal.ex
    - examples/phoenix_host/priv/static/offline_study.js
key-decisions:
  - "Opaque scope validation consumes the entire value, rejecting a trailing newline before host authority callbacks run."
  - "Existing accepted and rejected ReviewEvent rows map through one closed status-aware outcome function in duplicate and race recovery paths."
  - "Only outcome: :accepted advances accepted_records; rejected work remains retained and halts ordered draining."
metrics:
  duration: 6m
  completed_date: 2026-08-02
  tasks_completed: 2
  files_modified: 8
status: complete
---

# Phase 160 Plan 09: Scoped Replay and Auth Safety Summary

Phoenix now rejects malformed opaque scope references before authority resolution and preserves persisted rejected replay work through the browser-facing response boundary.

## Tasks Completed

1. **Trace one opaque scope through exact host admission**
   - Added boundary tests for 16- and 128-byte URL-safe payloads plus hostile values.
   - Replaced the host’s prefix/length check with a full-string positive-version opaque-scope matcher.
   - Proved malformed scopes invoke no session, route, feature, Sigra, or domain callback.

2. **Preserve persisted rejected outcomes through duplicate, race, and controller response paths**
   - Added a closed mapper from ReviewEvent status to accepted or rejected outcomes.
   - Used that mapper for duplicate and recovery lookups, preserving null-scope legacy tombstones.
   - Routed rejected outcomes to the retained controller collection and prevented accepted-prefix advancement.

## Verification

- `cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first/replay_admission_test.exs test/crosswake_example/local_first/study_test.exs test/crosswake_example/local_first/sync_controller_test.exs` — 18 tests passed.
- `cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first` — 18 tests passed.
- `cd examples/phoenix_host && node --check priv/static/offline_study.js` — passed.
- Core and browser exact-end scope checks were smoke-verified after tightening the shared grammar.

The existing unrelated `@after_digest_barrier` compiler warning remains outside this plan’s scope.

## Commits

- `842c2b52` — `test(160-09): add hostile scope admission regressions`
- `5e8ad04e` — `fix(160-09): enforce exact opaque scope grammar`
- `6a294ed9` — `test(160-09): add rejected replay outcome regressions`
- `699d9fd4` — `fix(160-09): retain persisted rejected replay outcomes`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Require exact end-of-value scope matching across layers**
- **Found during:** Task 1
- **Issue:** `$` accepted a terminal newline in the runtime’s regular-expression semantics, so the intended full-string grammar was not actually complete.
- **Fix:** Used Elixir’s `\\z` exact end anchor in host and core validation, and an equivalent exact end assertion in the browser pattern.
- **Files modified:** `examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex`, `lib/crosswake/offline/journal.ex`, `examples/phoenix_host/priv/static/offline_study.js`
- **Commit:** `5e8ad04e`

## Known Stubs

None.

## Security and External Boundaries

- Scope values remain opaque and non-echoing; no decoding, normalization, telemetry, or logging was introduced.
- The change closes T-160-01 and T-160-05 implementation gaps without promoting real adopter or device prerequisites.
- TODO-002 and real adopter route, session, and device inputs remain `unknown_blocking`.

## Self-Check: PASSED

- Verified all eight modified runtime/test files exist.
- Verified task commits `842c2b52`, `5e8ad04e`, `6a294ed9`, and `699d9fd4` exist in git history.
- No plan stubs, skipped tests, or unrun planned verification remain.
