---
phase: 136-core-decoupling
plan: "05"
subsystem: testing
tags: [elixir, companion-guard, ast-walk, prefix-match, decouple, sigra, chimeway, schema]

# Dependency graph
requires:
  - phase: 136-02
    provides: "telemetry.ex inverted — no static Sigra/Chimeway alias; assert_no_static_refs!/0 now returns :ok for telemetry.ex"
  - phase: 136-03
    provides: "route_gate.ex inverted — alias Crosswake.Companions.Sigra.Evaluator removed; auth dispatch via registry"
  - phase: 136-04
    provides: "support_matrix.ex + doctor.ex inverted — no static Sigra/Chimeway alias; sentinel [] for companion-sourced fields"
provides:
  - "CompanionGuard.check_source/1 uses prefix matching (List.starts_with?) — child modules like Sigra.Evaluator detected"
  - "Sigra and Chimeway added to @extracted_companion_names — banned set is now complete for Phase 136"
  - "assert_no_static_refs!/0 scope excludes lib/crosswake/companions/**/*.ex — in-tree companion self-references not flagged"
  - "policy/schema.ex decoupled from Crosswake.Companions.Sigra.Contracts — @mfa_level_vocabulary inlined"
  - "Phase-130 test proves child-module prefix detection for Sigra + scope-exclusion non-vacuity"
  - "All 5 backstop tests in phase136_decouple_proof_test.exs GREEN"
affects:
  - "All future companion extraction phases (137-139) — guard enforces the boundary before and after extraction"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Prefix-match via Enum.any?(@banned_alias_parts, &List.starts_with?(parts, &1)) in Macro.prewalk — guard clause cannot use Enum.any?"
    - "Scope exclusion via list subtraction: lib_files -- companion_files (Path.wildcard has no native negative glob)"
    - "MFA vocabulary inlining: static constant extracted from companion to core module attribute (stable, known contract)"

key-files:
  created: []
  modified:
    - lib/crosswake/companion_guard.ex
    - lib/crosswake/policy/schema.ex
    - test/crosswake/proof/phase130_extraction_guards_test.exs

key-decisions:
  - "Prefix matching via Enum.any? + List.starts_with? in function body (not when guard) — Elixir guards cannot call non-guard-safe functions (Pitfall 7)"
  - "Scope exclusion: lib_files -- companion_files list subtraction, not a glob pattern — Path.wildcard has no negative-glob support"
  - "policy/schema.ex decoupling: inline @mfa_level_vocabulary as module attribute — vocabulary is a stable 4-atom contract, no runtime companion lookup needed for schema validation"

patterns-established:
  - "Banned-alias list subtraction pattern: Path.wildcard two globs, subtract the exclusion set"

requirements-completed: [DECOUPLE-06]

coverage:
  - id: D1
    description: "CompanionGuard.check_source/1 uses List.starts_with? prefix match — child modules like Sigra.Evaluator detected"
    requirement: DECOUPLE-06
    verification:
      - kind: unit
        ref: "mix test test/crosswake/proof/phase130_extraction_guards_test.exs — 13 tests, 0 failures"
        status: pass
      - kind: integration
        ref: "mix compile --warnings-as-errors — exit 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "assert_no_static_refs!/0 scope excludes lib/crosswake/companions/**/*.ex"
    requirement: DECOUPLE-06
    verification:
      - kind: integration
        ref: "mix run -e 'Crosswake.CompanionGuard.assert_no_static_refs!()' — :ok"
        status: pass
      - kind: unit
        ref: "phase130_extraction_guards_test.exs scope-exclusion test"
        status: pass
    human_judgment: false
  - id: D3
    description: "All 5 backstop tests in phase136_decouple_proof_test.exs pass against fully-inverted core"
    requirement: DECOUPLE-06
    verification:
      - kind: integration
        ref: "mix test test/crosswake/proof/phase136_decouple_proof_test.exs — 5 tests, 0 failures"
        status: pass
    human_judgment: false

# Metrics
duration: 9min
completed: "2026-07-01"
status: complete
---

# Phase 136 Plan 05: Companion Guard Extension + Phase Merge Gate Summary

**Prefix-matching AST guard with Sigra+Chimeway banned and in-tree companion scope excluded; policy/schema.ex decoupled from static Sigra.Contracts alias; Phase-130 test updated to prove child-module detection and scope exclusion; all 5 DECOUPLE backstop tests GREEN.**

## Performance

- **Duration:** ~9 minutes
- **Started:** 2026-07-01T15:19:58Z
- **Completed:** 2026-07-01T15:29:00Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Extended `@extracted_companion_names` in `companion_guard.ex` with `"Crosswake.Companions.Sigra"` and `"Crosswake.Companions.Chimeway"` (with comments explaining Phase 136 addition)
- Replaced exact-match guard clause (`when parts in @banned_alias_parts`) with unconditional match + `Enum.any?(@banned_alias_parts, &List.starts_with?(parts, &1))` in function body — now catches child modules like `Sigra.Evaluator`, `Sigra.DenialCodes`, `Chimeway.Telemetry`
- Updated `assert_no_static_refs!/0` scope: compute `lib_files` and `companion_files` via two `Path.wildcard/1` calls, then walk `lib_files -- companion_files` — in-tree sigra/chimeway self-references excluded
- Discovered and fixed a previously-missed coupling site (Rule 2): `lib/crosswake/policy/schema.ex` had `alias Crosswake.Companions.Sigra.Contracts, as: SigraContracts` with a call to `SigraContracts.mfa_level_vocabulary()` in `validate_auth_min_level/1`. Fixed by inlining `@mfa_level_vocabulary [:none, :password, :mfa, :phishing_resistant]` as a module attribute, removing the static companion alias.
- Updated `phase130_extraction_guards_test.exs`:
  - Updated L86-103 test description: Plans 02/03 removed the Sigra.Evaluator alias from route_gate.ex; test still correctly returns `:ok` (no residual Sigra alias in core)
  - Inverted L122-136 assertion from `:ok` to `{:violation, _}` — Sigra is now extracted/banned
  - Added scope-exclusion test: `assert_no_static_refs!/0` returns `:ok` proving companion dir excluded
- Confirmed all 5 backstop tests in `phase136_decouple_proof_test.exs` GREEN

## Task Commits

1. **Task 1: Prefix-match guard, Sigra+Chimeway banned, scope exclusion** - `c9227e6` (feat)
2. **Task 2: Invert Sigra non-vacuity + add scope-exclusion test** - `2fdc581` (test)
3. **Task 3: Full-suite + zero-companion compile gate** — verification gate, no code changes (all 5 backstop tests GREEN; see Gap section)

## Files Created/Modified

- `lib/crosswake/companion_guard.ex` — Extended `@extracted_companion_names` with Sigra+Chimeway; replaced exact-match with prefix-match via `Enum.any?/List.starts_with?`; scoped `assert_no_static_refs!/0` to exclude `lib/crosswake/companions/**/*.ex`
- `lib/crosswake/policy/schema.ex` — Removed `alias Crosswake.Companions.Sigra.Contracts`; added `@mfa_level_vocabulary` module attribute; changed `validate_auth_min_level/1` to use `@mfa_level_vocabulary` instead of `SigraContracts.mfa_level_vocabulary()`
- `test/crosswake/proof/phase130_extraction_guards_test.exs` — Updated test descriptions; inverted Sigra non-vacuity assertion from `:ok` to `{:violation, _}`; added scope-exclusion test (13 tests, 0 failures)

## Decisions Made

- **Prefix-match in function body not guard clause**: `Enum.any?/2` and `List.starts_with?/2` are not guard-safe; the `when` clause was removed and the test moved to the function body using `if` (Pitfall 7)
- **Scope exclusion via list subtraction**: `lib_files -- companion_files` is idiomatic and correct; `Path.wildcard` has no native negative-glob support
- **policy/schema.ex mfa_level_vocabulary inlined**: The vocabulary is a stable, known 4-atom list; no runtime companion lookup needed for schema validation; the inline pattern is preferable to a runtime registry scan for schema validation correctness

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Decoupling] policy/schema.ex static Sigra.Contracts alias not in plan**
- **Found during:** Task 1 (running `assert_no_static_refs!/0` revealed the violation)
- **Issue:** `lib/crosswake/policy/schema.ex` contained `alias Crosswake.Companions.Sigra.Contracts, as: SigraContracts` and called `SigraContracts.mfa_level_vocabulary()` in `validate_auth_min_level/1`. This was a coupling site missed by Plans 02/03/04 and not listed in the RESEARCH (CONTEXT.md lists only 4 coupling sites; `schema.ex` is a 5th).
- **Fix:** Inlined `@mfa_level_vocabulary [:none, :password, :mfa, :phishing_resistant]` as a module attribute (the vocabulary is a static 4-atom constant in `Sigra.Contracts` — not dynamic); removed the static alias. The inline is documented with a comment explaining the Phase 137+ extraction path.
- **Files modified:** `lib/crosswake/policy/schema.ex`
- **Commit:** `c9227e6`

## Phase Merge Gate Results (Task 3)

### compile gate
`mix compile --warnings-as-errors` exits 0.

### Backstop tests (phase136_decouple_proof_test.exs)
All 5 backstop tests GREEN:
- Test 1 (DECOUPLE-04): evaluate_auth/3 raising rescued → :deny — PASS
- Test 2 (DECOUPLE-01): zero companions → non-empty events, empty reserved set — PASS
- Test 3 (DECOUPLE-04): multiple auth_authority?/0 → first-registered wins + conflict telemetry — PASS
- Test 4 (DECOUPLE-05): baseline_forbidden_metadata_keys/0 returns exactly 10-atom set — PASS
- Test 5 (DECOUPLE-05): forbidden key captured at attach time, scrubbed after registry cleared — PASS

### Full suite
`mix test --exclude requires_example_host --exclude advisory_only` — 1162 tests, 32 failures (61 excluded)

The 32 failures are pre-existing gaps from Plans 02/03/04, NOT introduced by Plan 05:
- 19 of the 32 failures existed before Plan 04 changes (established by git bisect)
- 13 additional failures introduced by Plan 04's sentinel `[]` approach for `denial_codes` and telemetry fields in `auth_contract_truth/0` and `notification_support_truth/0`
- These tests assert that `SupportMatrix.auth_contract_truth()` returns populated `denial_codes` (from Sigra) — now they receive `[]` because no Sigra companion is registered in test env
- Plan 05 (Task 1+2) introduced 0 new failures — the test count remains 32

**Gap documented from Plan 04:** Tests asserting populated `denial_codes` from `SupportMatrix.auth_contract_truth/0` (e.g., phase54, phase56, phase57 proof tests; `Crosswake.SupportMatrixTest`, `Crosswake.DoctorTest`) receive `denial_codes: []` because no Sigra companion is registered. These tests need either: (a) test-time Sigra companion registration, or (b) fixture-based assertions decoupled from runtime companion presence. This is out of scope for Phase 136 (Plan 04's SUMMARY documented the sentinel choice as intentional).

## Known Stubs

- `@mfa_level_vocabulary` in `policy/schema.ex` is an intentional inline (not a stub) — the list is a stable, known contract. A comment documents the Phase 137+ path where the extracted Sigra companion will provide this via a `mfa_level_vocabulary/0` callback.

## Threat Flags

None — no new network endpoints, auth paths, or file access patterns introduced. This is a pure compile-time guard extension and schema decoupling refactor.

## Self-Check: PASSED
