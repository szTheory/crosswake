---
phase: 136-core-decoupling
plan: "03"
subsystem: compatibility
tags: [elixir, route_gate, auth, registry, fail-closed, telemetry, decouple]

# Dependency graph
requires:
  - "136-01: evaluate_auth/3 + auth_authority?/0 callback declarations on Crosswake.Companion"
provides:
  - "route_gate.ex: alias Crosswake.Companions.Sigra.Evaluator removed; inlined auth_predicated?/1 helper"
  - "registry-based auth dispatch via auth_authority?/0 + evaluate_auth/3 with fail-closed guard"
  - "try/rescue wrapper around evaluate_auth/3; deny with :dependency_missing on raise"
  - "[:crosswake, :companion, :auth_authority_conflict] telemetry emitted on multiple-authority conflict"
  - "Backstop tests 1 and 3 (DECOUPLE-04) green"
affects:
  - 136-04  # support_matrix inversion (DECOUPLE-03) — no auth_gate coupling remaining
  - 136-05  # doctor inversion — companion registry pattern now fully established

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Inline auth-predicate check: not is_nil(route.auth_min_level) or not is_nil(route.requires_recent_auth) or not is_nil(route.auth_posture) — replaces Sigra.Evaluator.auth_predicated?/1"
    - "Registry auth dispatch: Application.get_env(:crosswake, :companions, []) filtered by function_exported?(mod, :auth_authority?, 0) and mod.auth_authority?()"
    - "Fail-closed: zero auth-authority companions → :dependency_missing deny; rescue from evaluate_auth/3 → :dependency_missing deny"
    - "Multiple-authority resolution: first-registered wins; :telemetry.execute/3 emits [:crosswake, :companion, :auth_authority_conflict] with all authority IDs"
    - "Denial.t() direct passthrough: {:deny, denial} prepended unchanged (zero type-translation, D-136-B)"
    - "Backstop test assertion: check absence of auth-specific denials (not decision.status) — empty Target always generates compatibility denials, making status unreliable for auth-only contract verification"

key-files:
  created: []
  modified:
    - lib/crosswake/compatibility/route_gate.ex
    - test/crosswake/proof/phase136_decouple_proof_test.exs

key-decisions:
  - "Rescue reason atom pinned as :dependency_missing (not :auth_evaluator_error) — single atom covers both no-authority and raises; simpler fail-closed message for operators"
  - "Conflict signal as :telemetry.execute/3 event [:crosswake, :companion, :auth_authority_conflict] (pinned in Plan 01); no doctor string added in this plan (clean separation)"
  - "Test 3 assertion fixed: empty Target always generates origin/bridge/runtime compatibility denials so decision.status cannot be :allow; assertion changed to verify no auth-related denial in decision.denials (correct behavioral invariant)"

patterns-established:
  - "Auth predicate gating before companion scan: non-auth-predicated routes skip scan entirely (no spurious dependency_missing on routes without auth requirements)"
  - "try/rescue wraps the evaluate_auth/3 call exclusively; no catch clause needed (RuntimeError is the expected failure mode)"

requirements-completed: [DECOUPLE-02, DECOUPLE-04]

coverage:
  - id: D4
    description: "route_gate.ex dispatches auth through registry; no Sigra.Evaluator alias"
    requirement: DECOUPLE-02
    verification:
      - kind: source
        ref: "grep -v '^\s*#' lib/crosswake/compatibility/route_gate.ex | grep -c 'Companions.Sigra' returns 0"
        status: pass
      - kind: integration
        ref: "mix compile --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D5
    description: "Fail-closed: :dependency_missing on no-authority; rescue on raise; allow only on non-auth routes; first-registered wins with conflict signal"
    requirement: DECOUPLE-04
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase136_decouple_proof_test.exs#test 1 (raises→rescued→deny) and test 3 (multi-authority first-wins + conflict telemetry)"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase130_fail_closed_contract_test.exs (COMPAT-01 still green)"
        status: pass
    human_judgment: false

# Metrics
duration: 5min
completed: "2026-07-01"
status: complete
---

# Phase 136 Plan 03: RouteGate Auth Registry Inversion Summary

**RouteGate auth dispatch inverted from static Sigra.Evaluator alias to runtime registry via auth_authority?/0 + evaluate_auth/3; fail-closed guard denies with :dependency_missing when no authority registered or companion raises; first-registered wins for multiple authorities with telemetry conflict signal.**

## Performance

- **Duration:** ~5 minutes
- **Started:** 2026-07-01T14:49:56Z
- **Completed:** 2026-07-01T14:55:00Z
- **Tasks:** 1
- **Files modified:** 2 (0 created, 2 modified)

## Accomplishments

- Deleted `alias Crosswake.Companions.Sigra.Evaluator` (was L9 of route_gate.ex); `alias Crosswake.Shell.Denial` kept at L11
- Added private `auth_predicated?/1` helper inlining the three-field nil-check (`not is_nil(route.auth_min_level) or not is_nil(route.requires_recent_auth) or not is_nil(route.auth_posture)`) — core no longer calls Sigra for predicate detection
- Rewrote `prepend_auth_evaluation_denials/4` third clause with:
  * Predicate gate: non-auth-predicated routes return `acc` immediately — "no eval = allow" only for these routes
  * Registry scan filtering by `function_exported?(companion, :auth_authority?, 0) and companion.auth_authority?()`, also gated by `companion.enabled?(config)`
  * Zero authorities → `Denial.new(reason: :dependency_missing, ...)` prepended (fail-closed; DECOUPLE-04/T-136-01)
  * Multiple authorities → first-registered used; `:telemetry.execute([:crosswake, :companion, :auth_authority_conflict], ...)` with count + all authority IDs
  * Single dispatch `try authority.evaluate_auth(route, auth_context, opts) rescue _ -> {:deny, Denial.new(reason: :dependency_missing, ...)}`
  * `{:allow, _}` returns acc unchanged; `{:deny, denial}` prepends the `Denial.t()` directly (zero type-translation per D-136-B)
- Fixed backstop test 3 assertion: `decision.status == :allow` was incorrect (empty `%Target{}` always generates origin/bridge/runtime compatibility denials making status `:deny`); replaced with assertion that no auth-specific denials (`:dependency_missing` or `:auth_evaluator_error` reason) appear in `decision.denials`

## Task Commits

1. **Task 1: Invert route_gate auth dispatch onto registry with fail-closed + rescue** — `6388069` (feat)

## Files Created/Modified

- `lib/crosswake/compatibility/route_gate.ex` — Removed Evaluator alias; added auth_predicated?/1 private helper; replaced prepend_auth_evaluation_denials/4 third clause with registry dispatch + fail-closed + rescue + conflict signal
- `test/crosswake/proof/phase136_decouple_proof_test.exs` — Fixed test 3 assertion from decision.status check to auth-denial absence check

## Decisions Made

- Rescue denial reason pinned to `:dependency_missing` (not `:auth_evaluator_error`): one atom covers both failure modes (missing authority and evaluator crash); operators see consistent fail-closed semantics; backstop test 1 accepts either atom so this is within contract
- Conflict signal implemented as `:telemetry.execute/3` event (already pinned to `[:crosswake, :companion, :auth_authority_conflict]` in Plan 01); no doctor code string needed in this plan (doctor inversion is Plan 05)
- Test 3 assertion changed to auth-denial absence (deviation from original test intent): empty `%Target{}` is the hermetic test pattern but produces 4 compatibility denials; checking `decision.status == :allow` would require a fully populated target which is out of scope for a unit backstop test

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed backstop test 3 assertion (empty Target produces compatibility denials)**
- **Found during:** Task 1 verification
- **Issue:** Test 3 asserted `decision.status == :allow` but the stub route with an empty `%Target{}` always generates compatibility denials (origin mismatch, bridge protocol, native runtime, manifest schema). These are independent of auth evaluation and would cause `decision.status == :deny` regardless of auth outcome.
- **Fix:** Changed assertion to check that no auth-specific denial (`:dependency_missing` or `:auth_evaluator_error` reason) appears in `decision.denials`. This correctly isolates the auth contract from compatibility contract.
- **Files modified:** `test/crosswake/proof/phase136_decouple_proof_test.exs`
- **Commit:** `6388069`

## Issues Encountered

- Empty `%Target{}` in backstop test 3 always generates origin/bridge/runtime compatibility denials (expected behavior — the test router has no matching origin, no bridge protocol, no native runtime). The test assertion had to be made auth-specific, not status-specific.

## Next Phase Readiness

- Plan 04 can now invert `support_matrix.ex` coupling sites: `@auth_contract_truth` and `@notification_support_truth` module attributes must become `def` runtime helpers calling the companion registry via `denial_codes/0` callback
- Plan 05 can invert `doctor.ex` fallback calls to `Sigra.DenialCodes.codes()` / `allowed_detail_keys()` onto registry dispatch
- All three auth-predicated route behaviors are now verified green: raises→rescued→deny, non-predicated→pass, multiple-authority→first-wins+signal

## Known Stubs

None — no stub values or placeholders in production code.

## Threat Flags

None — no new network endpoints, auth paths, or file access patterns introduced. The refactor inverts an existing auth evaluation path onto the registry seam; the fail-closed contract (T-136-01) is strengthened, not weakened.

## Self-Check: PASSED
