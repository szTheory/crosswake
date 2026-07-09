---
phase: 136-core-decoupling
plan: "01"
subsystem: testing
tags: [elixir, behaviour, callbacks, telemetry, auth, pii, nyquist, proof]

# Dependency graph
requires: []
provides:
  - "Crosswake.Companion behaviour extended with 4 optional callbacks: forbidden_metadata_keys/0, denial_codes/0, evaluate_auth/3, auth_authority?/0"
  - "Phase-129 freeze test updated to 11-callback expected set (was 7)"
  - "Five Nyquist backstop proof tests scaffolded covering DECOUPLE-01/04/05"
affects:
  - 136-02  # telemetry inversion depends on forbidden_metadata_keys/0 callback declaration
  - 136-03  # route_gate inversion depends on evaluate_auth/3 and auth_authority?/0 callback declaration
  - 136-04  # support_matrix inversion depends on denial_codes/0 callback declaration
  - 136-05  # doctor inversion depends on denial_codes/0 callback declaration

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Behaviour-only Wave 0: declare callbacks before any implementation so function_exported?/3 dispatch targets are stable"
    - "Freeze test co-mutation: companion.ex callback additions and @expected_callbacks MapSet change in same commit (D-12/D-17)"
    - "Nyquist backstop: five RED tests scaffold non-inferable behaviors before Wave 1 implements them"

key-files:
  created:
    - test/crosswake/proof/phase136_decouple_proof_test.exs
  modified:
    - lib/crosswake/companion.ex
    - test/crosswake/proof/phase129_companion_contract_freeze_test.exs

key-decisions:
  - "evaluate_auth/3 returns Denial.t() in Phase 136; Finding refactor deferred to Phase 137 (D-136-B)"
  - "Backstop test 1/3 use auth_min_level: :mfa (valid sigra vocabulary) to create auth-predicated routes in Router DSL"
  - "Backstop test 5 (attach-time capture) asserts handler.config[:forbidden_keys] MapSet — Plan 02 must pass forbidden set via config map to :telemetry.attach_many"
  - "Conflict signal pinned as [:crosswake, :companion, :auth_authority_conflict] (Claude discretion per CONTEXT.md)"
  - "Backstop test 1 accepts either :dependency_missing or :auth_evaluator_error denial reason — Plan 03 decides the exact atom"

patterns-established:
  - "Stub auth companions (StubAuthRaisesCompanion, StubAuthFirstCompanion, StubAuthSecondCompanion, StubForbiddenKeyCompanion) defined outside test module to avoid nested-module resolution issues"
  - "Application.put_env/on_exit reset pattern inherited from phase130/phase133 proof tests"

requirements-completed: [DECOUPLE-01, DECOUPLE-02, DECOUPLE-03, DECOUPLE-04, DECOUPLE-05, DECOUPLE-06]

coverage:
  - id: D1
    description: "Crosswake.Companion behaviour declares 4 new optional callbacks with correct arities and @optional_callbacks keyword list"
    requirement: DECOUPLE-01
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase129_companion_contract_freeze_test.exs#Companion behaviour callbacks are frozen at the Phase 129 contract shape"
        status: pass
      - kind: integration
        ref: "mix compile --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Phase-129 freeze test asserts 11-callback MapSet and passes"
    requirement: DECOUPLE-06
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase129_companion_contract_freeze_test.exs#all 7 tests"
        status: pass
    human_judgment: false
  - id: D3
    description: "Five Nyquist backstop tests authored, compiling, and RED pending Wave 1"
    requirement: DECOUPLE-04
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase136_decouple_proof_test.exs#5 tests, 5 failures (expected RED)"
        status: pass
    human_judgment: false

# Metrics
duration: 7min
completed: "2026-07-01"
status: complete
---

# Phase 136 Plan 01: Companion Behaviour Wave 0 Summary

**Crosswake.Companion extended to 11 callbacks (4 new optional: forbidden_metadata_keys/0, denial_codes/0, evaluate_auth/3, auth_authority?/0); Phase-129 freeze test updated; five Nyquist backstop RED tests scaffold fail-closed/PII/attach-capture contracts.**

## Performance

- **Duration:** ~7 minutes
- **Started:** 2026-07-01T14:30:33Z
- **Completed:** 2026-07-01T14:37:44Z
- **Tasks:** 3
- **Files modified:** 3 (1 created, 2 modified)

## Accomplishments

- Extended `Crosswake.Companion` behaviour from 7 to 11 callbacks: added `forbidden_metadata_keys/0`, `denial_codes/0`, `evaluate_auth/3`, `auth_authority?/0` as optional callbacks; `@optional_callbacks` expanded to 5-entry keyword list; module compiles clean with `--warnings-as-errors`
- Updated `phase129_companion_contract_freeze_test.exs` `@expected_callbacks` MapSet from 7 to 11 entries; all 7 freeze tests pass (MapSet.equal? holds at new 11-callback shape per D-12/D-17 same-commit rule)
- Scaffolded `phase136_decouple_proof_test.exs` with five backstop tests covering: (1) `evaluate_auth/3` raising → rescued → deny (DECOUPLE-04); (2) zero companions → non-empty events, empty reserved set (DECOUPLE-01); (3) multiple auth-authority companions → first-registered wins + conflict signal (DECOUPLE-04); (4) `baseline_forbidden_metadata_keys/0` exact 10-atom set (DECOUPLE-05); (5) forbidden-key set captured in handler config at attach time (DECOUPLE-05)

## Task Commits

1. **Task 1: Extend Companion behaviour with four optional callbacks** - `3439928` (feat)
2. **Task 2: Update Phase-129 freeze test to 11-callback expected set** - `3f6bd04` (test)
3. **Task 3: Scaffold five Nyquist backstop tests** - `0964b48` (test)

## Files Created/Modified

- `lib/crosswake/companion.ex` - Added 4 @callback declarations with @doc; expanded @optional_callbacks to 5-entry keyword list (11 total callbacks)
- `test/crosswake/proof/phase129_companion_contract_freeze_test.exs` - Added 4 callback tuples to @expected_callbacks with "Added in Phase 136 (DECOUPLE)" comment
- `test/crosswake/proof/phase136_decouple_proof_test.exs` - New file: 4 stub companion modules + 5 backstop test cases; RED pending Plans 02/03

## Decisions Made

- evaluate_auth/3 return type stays `{:allow, map()} | {:deny, Crosswake.Shell.Denial.t()}` in Phase 136; Finding.t() boundary refactor deferred to Phase 137 per D-136-B
- Backstop tests use `auth_min_level: :mfa` (valid sigra vocabulary atom) in the Router DSL for auth-predicated route creation; `:member` was rejected by NimbleOptions validation
- Multiple-authority conflict telemetry event pinned to `[:crosswake, :companion, :auth_authority_conflict]` per Claude's discretion (CONTEXT.md allows)
- Attach-time capture test asserts `handler.config[:forbidden_keys]` MapSet key; Plan 02 must pass the precomputed MapSet through `:telemetry.attach_many/4` config argument
- Backstop test 1 accepts either `:dependency_missing` or `:auth_evaluator_error` denial reason — Plan 03 will pin the exact atom when implementing the rescue path

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Router DSL validation rejects `auth_min_level: :member` via NimbleOptions (sigra vocabulary restricts valid atoms to `:mfa`, `:password`, etc.). Fixed inline by using `:mfa` as the auth level in the stub router — no plan deviation, just a valid vocabulary substitution.
- Elixir syntax error: cannot mix `key: value` and `key => value` in a map literal when the key is a variable. Fixed inline by building the probe metadata map using `Map.put/3` instead of literal syntax.

## Next Phase Readiness

- Plan 02 can immediately begin inverting `telemetry.ex` coupling sites: `build_reserved_events/0` (runtime aggregation), `all_forbidden_keys/0` (baseline MapSet + companion aggregation + handler closure cache), and exposing `baseline_forbidden_metadata_keys/0`
- Plan 03 can implement `prepend_auth_evaluation_denials/4` inversion with inline auth-predicate check, `auth_authority?/0` registry scan, no-companion guard (deny), and try/rescue wrapper
- Backstop tests 2 (reserved set empty) and 4 (baseline_forbidden_metadata_keys) are the GREEN gate for Plan 02
- Backstop tests 1 (auth raises) and 3 (multiple authority) are the GREEN gate for Plan 03
- All four new callbacks are in `@optional_callbacks` — `function_exported?/3` dispatch is immediately usable

## Known Stubs

None - no stub values or placeholders in production code.

## Threat Flags

None - no new network endpoints, auth paths, or file access patterns introduced. The new callback declarations are pure behaviour contract surface; no production auth dispatch logic added in this plan.

## Self-Check: PASSED
