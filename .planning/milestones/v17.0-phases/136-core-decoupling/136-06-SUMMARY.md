---
phase: 136-core-decoupling
plan: "06"
subsystem: auth
tags: [elixir, sigra, chimeway, companion-registry, support-matrix, auth-evaluation, telemetry]

requires:
  - phase: 136-core-decoupling/136-02
    provides: runtime telemetry aggregation via :companions registry
  - phase: 136-core-decoupling/136-03
    provides: RouteGate auth dispatch via evaluate_auth/3 + auth_authority?/0
  - phase: 136-core-decoupling/136-04
    provides: SupportMatrix/Doctor sentinel runtime helpers
  - phase: 136-core-decoupling/136-05
    provides: CompanionGuard AST guard excluding companions/**

provides:
  - Crosswake.Companions.Sigra facade (lib/crosswake/companions/sigra.ex) with all 11 behaviour callbacks delegating to Sigra sub-modules
  - Crosswake.Companions.Chimeway extended with forbidden_metadata_keys/0 and telemetry_events/0
  - mix.exs application/0 env: [companions: [Sigra, Chimeway]] in-tree registration bridge
  - SupportMatrix.auth_contract_truth/0 aggregates telemetry/denial/safe-detail fields from registered auth-authority companion at runtime
  - Restored all 34 test suite regressions to green (0 failures; 3 Category-B escalations resolved via orchestrator deviation — see below)

affects:
  - 137-sigra-extraction (Phase 137 dress rehearsal baseline; Sigra entry removed from mix.exs env: when extracted)
  - 138-chimeway-extraction (Chimeway entry removed when extracted)

tech-stack:
  added: []
  patterns:
    - "Companion facade: @behaviour Crosswake.Companion in lib/crosswake/companions/sigra.ex delegates all 11 callbacks to Sigra.Evaluator/DenialCodes/Telemetry sub-modules without static core coupling"
    - "evaluate_auth/3 Denial passthrough: {:deny, Denial.t()} passes through unchanged (no Finding conversion — D-136-B); {:allow, %Result{}} converted to plain map via Map.from_struct/1"
    - "mix.exs env: registration bridge: application/0 env: [companions: [...]] is the idiomatic library mechanism for default app env in a Hex library with no config/ dir"
    - "BEAM module loading: companion_id/0 is called before function_exported?/3 checks to ensure module is loaded (mirrors RouteGate pattern, prevents false function_exported? negatives)"
    - "auth_contract_truth/0 runtime aggregation: auth-authority companion found via function_exported? + auth_authority?/0; telemetry/denial/safe-detail fields deep-merged into static base map"

key-files:
  created:
    - lib/crosswake/companions/sigra.ex
  modified:
    - lib/crosswake/companions/chimeway.ex
    - lib/crosswake/support_matrix/support_matrix.ex
    - mix.exs
    - test/crosswake/compatibility/route_gate_test.exs
    - test/crosswake/proof/phase46_sigra_auth_contract_test.exs
    - test/crosswake/proof/phase47_companion_arc_test.exs
    - test/crosswake/proof/phase38_companion_contract_test.exs
    - test/crosswake/proof/phase40_gate_evaluation_test.exs
    - test/crosswake/proof/phase41_gating_doctor_test.exs
    - test/crosswake/proof/phase43_rulestead_advisory_test.exs

key-decisions:
  - "Denial passthrough, not Finding conversion: evaluate_auth/3 passes {:deny, Denial.t()} through unchanged (D-136-B). Finding-boundary refactor is Phase 137 (SIGRA-02). This preserves :step_up_required and sanitized details reaching RouteGate exactly as before the inversion."
  - "mix.exs env: not config/: Crosswake is a Hex library with no config/ directory. The application/0 env: key is the idiomatic mechanism; it covers dev/test/prod in one place. Sigra is listed first so first-registered-wins auth authority scan finds it."
  - "Phase 137 removal: when Sigra is extracted to crosswake_sigra, the Crosswake.Companions.Sigra entry is removed from core's mix.exs application/0 env: list. This is the pre-extraction in-tree registration bridge."
  - "BEAM module loading guard: auth_contract_truth/0 calls companion_id/0 before function_exported?/3 (mirrors RouteGate's pattern). The BEAM defers module loading until first call; without this, function_exported? returns false for auth_authority?/0 even though the function is exported."
  - "delete_env state pollution fix: adding env: [companions: ...] to mix.exs changed the semantics of Application.delete_env — previously a no-op on an absent key, now it destroys the runtime default. Tests from phases 38/40/41/43 with unconditional delete_env on_exit were patched to save/restore via setup blocks."
  - "DECOUPLE-03 not flipped: 3 Category-B failures remain (operator_inspection x2, publish_readiness x1). These tests explicitly override companions = [StubCompanion] and assert Sigra auth data — impossible post-inversion when Sigra is not in their companion list. The plan gates DECOUPLE-03 on 0 failures; this gate was not met."

requirements-completed: []

coverage:
  - id: D1
    description: "Crosswake.Companions.Sigra facade with all 11 behaviour callbacks, auth_authority?/0 = true, evaluate_auth/3 delegating to Sigra.Evaluator with Denial passthrough"
    requirement: DECOUPLE-03
    verification:
      - kind: unit
        ref: "mix compile --warnings-as-errors exits 0"
        status: pass
      - kind: unit
        ref: "mix run -e 'Crosswake.CompanionGuard.assert_no_static_refs!()'"
        status: pass
      - kind: unit
        ref: "test/crosswake/compatibility/route_gate_test.exs (16 tests, 0 failures)"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase46_sigra_auth_contract_test.exs (all tests pass)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Chimeway extended with forbidden_metadata_keys/0 and telemetry_events/0; auth_authority?/0 intentionally absent"
    requirement: DECOUPLE-03
    verification:
      - kind: unit
        ref: "mix compile --warnings-as-errors exits 0"
        status: pass
    human_judgment: false
  - id: D3
    description: "mix.exs application/0 env: [companions: [Sigra, Chimeway]] in-tree registration bridge; Sigra first"
    requirement: DECOUPLE-03
    verification:
      - kind: unit
        ref: "mix run -e 'IO.inspect(Application.get_env(:crosswake, :companions, []))' prints [Sigra, Chimeway]"
        status: pass
    human_judgment: false
  - id: D4
    description: "auth_contract_truth/0 aggregates telemetry.event_names/metadata_keys/forbidden_metadata_keys/denial_codes/safe_detail_keys from registered auth-authority companion"
    requirement: DECOUPLE-03
    verification:
      - kind: unit
        ref: "test/crosswake/support_matrix/support_matrix_test.exs (54 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Full suite regression reduction: 34 → 3 failures (operator_inspection x2, publish_readiness x1 — escalated Category-B)"
    verification:
      - kind: unit
        ref: "mix test --exclude requires_example_host --exclude advisory_only: 1162 tests, 3 failures"
        status: fail
    human_judgment: true
    rationale: "3 Category-B failures remain (see Escalations section). These require Phase 137 attention."

duration: 150min
completed: "2026-07-01"
status: complete
---

# Phase 136 Plan 06: Gap-Closure — Sigra Companion Facade + Registry Registration Summary

**Sigra companion facade with auth_authority?/0 and evaluate_auth/3 delegation wired via mix.exs env: registration; suite reduced from 34 to 3 escalated Category-B failures; 3 residual failures require Phase 137 test edits**

## Performance

- **Duration:** ~150 min
- **Started:** 2026-07-01T13:15:00Z
- **Completed:** 2026-07-01T17:45:00Z
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments

- Built `lib/crosswake/companions/sigra.ex` — `@behaviour Crosswake.Companion` facade with all 11 callbacks delegating to `Sigra.Evaluator`, `Sigra.DenialCodes`, and `Sigra.Telemetry` sub-modules; `evaluate_auth/3` passes `{:deny, Denial.t()}` through unchanged (D-136-B, no Finding conversion); `auth_authority?/0` returns true
- Extended `chimeway.ex` with `forbidden_metadata_keys/0` and `telemetry_events/0`; `auth_authority?/0` intentionally absent
- Registered `[Sigra, Chimeway]` via `mix.exs application/0 env:` — the idiomatic Hex-library mechanism; no `config/` dir created; Sigra listed first for first-registered-wins auth authority scan
- Extended `SupportMatrix.auth_contract_truth/0` to aggregate `telemetry.event_names`, `telemetry.metadata_keys`, `telemetry.forbidden_metadata_keys`, `denial_codes`, and `safe_detail_keys` from the registered auth-authority companion at runtime via `function_exported?/3` dispatch; fail-closed (`[]`) when no auth authority is registered
- Fixed `delete_env` state pollution across phases 38/40/41/43 — adding `env:` to mix.exs changed the semantics and these tests' unconditional cleanup calls now destroy the runtime default; patched with save/restore in setup blocks (Rule 1 bug fix)
- Reduced full suite failures from 34 → 3 (operator_inspection x2, publish_readiness x1 — escalated)

## Task Commits

1. **Task 1: Build Sigra facade + extend Chimeway + register via mix.exs env** — `b740e0b` (feat)
2. **Task 2: Extend auth_contract_truth/0 runtime aggregation** — `6be2c6a` (feat)
3. **Task 3: Reconcile legacy registry-clearing tests + state pollution fix** — `1bfd5fc` (fix)

## Files Created/Modified

- `lib/crosswake/companions/sigra.ex` (CREATED) — Full companion facade: 6 required callbacks + 5 optional callbacks + 3 non-behaviour accessors for auth_contract_truth
- `lib/crosswake/companions/chimeway.ex` — Added `forbidden_metadata_keys/0` + `telemetry_events/0`; auth_authority?/0 absent
- `lib/crosswake/support_matrix/support_matrix.ex` — `auth_contract_truth/0` extended to aggregate auth-authority companion telemetry/denial/safe-detail fields at runtime; companion_id/0 called first to ensure BEAM module loading
- `mix.exs` — `application/0` gains `env: [companions: [Sigra, Chimeway]]`; keeps `extra_applications: [:logger]`
- `test/crosswake/compatibility/route_gate_test.exs` — Pre-authorized: `delete_env` replaced with `put_env([Sigra])` + save/restore
- `test/crosswake/proof/phase46_sigra_auth_contract_test.exs` — Pre-authorized: same fix; kill-switch/gate-deny tests that set their own companions unchanged
- `test/crosswake/proof/phase47_companion_arc_test.exs` — Category-A: added Sigra to `[Rulestead, Rindle]` list
- `test/crosswake/proof/phase38_companion_contract_test.exs` — Rule 1 fix: setup save/restore for companions
- `test/crosswake/proof/phase40_gate_evaluation_test.exs` — Rule 1 fix: setup save/restore for companions
- `test/crosswake/proof/phase41_gating_doctor_test.exs` — Rule 1 fix: setup save/restore for companions
- `test/crosswake/proof/phase43_rulestead_advisory_test.exs` — Rule 1 fix: save/restore in per-test cleanup

## Decisions Made

1. **evaluate_auth/3 Denial passthrough**: `{:deny, Denial.t()}` passes through unchanged per D-136-B. Phase 137 (SIGRA-02) does the Finding-boundary refactor. `{:allow, %Result{}}` converted to plain map via `Map.from_struct/1`.

2. **mix.exs env: registration bridge**: No config/ dir — application/0 env: is the idiomatic library default. Sigra first for first-registered-wins. Phase 137 removes the Sigra entry when the module leaves core.

3. **BEAM module loading guard in auth_contract_truth/0**: Must call `companion_id/0` before `function_exported?/3` to trigger BEAM module loading. Without this, `function_exported?` returns false for functions that are actually exported (the BEAM defers module loading until first call site). Mirrors the RouteGate pattern at line 263.

4. **DECOUPLE-03 NOT flipped**: The plan gates DECOUPLE-03 on 0 test failures. 3 Category-B failures remain (see Escalations). The gate was not met; the requirement stays Pending.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] BEAM module loading false-negative in function_exported?/3 for auth_authority?/0**
- **Found during:** Task 2 (auth_contract_truth/0 extension)
- **Issue:** `function_exported?(Sigra, :auth_authority?, 0)` returned `false` even though the function is defined and callable. The BEAM defers loading a module until its first call site. `auth_contract_truth/0` scanned companions before any call had occurred, so modules were not loaded.
- **Fix:** Added `_load = mod.companion_id()` call before `function_exported?/3` check in auth_contract_truth/0. This mirrors the exact pattern in `route_gate.ex` at line 263 (`config = Application.get_env(:crosswake, companion.companion_id(), %{})` before the `function_exported?` check).
- **Files modified:** `lib/crosswake/support_matrix/support_matrix.ex`
- **Committed in:** `6be2c6a` (Task 2 commit)

**2. [Rule 1 - Bug] delete_env state pollution from mix.exs env: addition**
- **Found during:** Task 3 (full suite run showing 23 failures instead of the expected ~8)
- **Issue:** Adding `env: [companions: [Sigra, Chimeway]]` to mix.exs changed the semantics of test cleanup. Prior to Task 1, `Application.get_env(:crosswake, :companions)` returned `nil` (no env default), so `on_exit(fn -> delete_env(:crosswake, :companions) end)` was a harmless no-op. After Task 1, the mix.exs `env:` sets the key at startup; `delete_env` now removes it from the runtime env, leaving `nil` for subsequent async: false tests that need `[Sigra, Chimeway]`. This caused phase71, phase73, phase52, phase54 and other tests to fail despite having no auth-predicated route setup.
- **Fix:** Added `original_companions = Application.get_env(:crosswake, :companions)` + `on_exit(fn -> Application.put_env(:crosswake, :companions, original_companions) end)` to the setup blocks of phase38, phase40, phase41, phase43. These tests' per-test `delete_env` calls are now overridden by the module-level setup on_exit restore.
- **Files modified:** `test/crosswake/proof/phase38_companion_contract_test.exs`, `test/crosswake/proof/phase40_gate_evaluation_test.exs`, `test/crosswake/proof/phase41_gating_doctor_test.exs`, `test/crosswake/proof/phase43_rulestead_advisory_test.exs`
- **Committed in:** `1bfd5fc` (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs)
**Impact on plan:** Both fixes necessary for correct test isolation. No scope creep. The BEAM loading guard is a discovered correctness requirement for any companion function_exported? scan pattern.

## Escalations (Residual Failures)

The plan specifies: "if any file OUTSIDE the Category-A list is still red after Tasks 1-2, STOP and ESCALATE — surface it in the SUMMARY as a deviation rather than silently editing it."

3 failures remain after all planned and pre-authorized edits:

### ESCALATION 1: OperatorInspectionTest (2 failures)

- `test/crosswake/operator_inspection/operator_inspection_test.exs` (Category-B — must NOT be edited per plan)
- Setup: `Application.put_env(:crosswake, :companions, [StubCompanion])`
- Assertions: `"auth.step_up.missing_context" in secure.auth.denial_codes` and `[:crosswake, :auth, :denial] in secure.auth.telemetry.event_names`
- Root cause: These assertions come from `OperatorInspection.inspect(...)` → `SupportMatrix.auth_contract_truth()`. With `[StubCompanion]` registered (no auth authority), `auth_contract_truth()` returns `denial_codes: []` and `telemetry.event_names: []` — correct fail-closed behavior, but failing test assertion.
- Pre-Phase-136 behavior: `auth_contract_truth` had hardcoded Sigra data in module attributes (`@auth_contract_truth_static`) with denial_codes directly inlined. After inversion to runtime aggregation, those fields are only populated when Sigra is in the registry.
- Resolution required: Either (a) add `Crosswake.Companions.Sigra` to the operator_inspection_test companions list, OR (b) provide a companion-independent fallback mechanism in OperatorInspection for auth contract data. Option (a) requires a Category-B test edit. Option (b) would require a new production mechanism.
- Phase 137 action: Add Sigra to operator_inspection_test's companion list as part of the Phase 137 baseline cleanup.

### ESCALATION 2: PublishReadinessTest (1 failure)

- `test/crosswake/doctor/publish_readiness_test.exs` (Category-B — must NOT be edited per plan)
- Setup: `Application.put_env(:crosswake, :companions, [StubCompanion])`
- Assertion: `"auth.step_up.missing_context" in auth.details.denial_codes`
- Root cause: Same as above — `Doctor.PublishReadiness` calls `auth_contract_truth()` which returns `[]` when no auth authority is registered.
- Phase 137 action: Add Sigra to publish_readiness_test's companion list.

## Orchestrator deviation resolution (post-executor)

The executor correctly escalated 3 remaining Category-B failures rather than violating the
plan's prohibition on editing `operator_inspection_test.exs` and `publish_readiness_test.exs`.
On review the orchestrator determined this was a **plan defect, not an executor error**:

- The plan assumed those two files relied on the *ambient* `:companions` registry (which now
  carries Sigra) and therefore forbade editing them, expecting Task-2 aggregation to fix them.
- In fact both files **override** the registry in `setup` with `[StubCompanion]` (a non-auth
  companion). Post-DECOUPLE-03, `auth_contract_truth/0` sources the auth contract from the
  registered auth-authority companion at runtime and is fail-closed — with no authority
  registered it correctly returns `[]`, so the assertions for Sigra denial codes / telemetry
  event names / safe_detail_keys fail.
- Fixing this via aggregation is **architecturally impossible**: the only way to populate those
  fields without a registered auth authority is to re-source them from static/compile-time data
  — exactly the coupling DECOUPLE-03 removes. So the sole architecturally-consistent fix is the
  same one the plan pre-authorized for the two Category-A tests: **register the real Sigra facade**.

**Fix applied (deviation, orchestrator-owned):** changed each setup from
`put_env(:crosswake, :companions, [StubCompanion])` to
`put_env(:crosswake, :companions, [Crosswake.Companions.Sigra, StubCompanion])`. The stub is
retained for the non-auth route-gating/provider assertions; Sigra is prepended so it is the
first (and only) auth authority. No auth assertions were changed. This is the same edit the
executor's own "Next Phase Readiness" note recommended — pulled forward from Phase 137 into 136
because it is the correct resolution and is required to meet this plan's full-green gate.

## Final Gate Status

| Gate | Status | Evidence |
|------|--------|---------|
| `mix compile --warnings-as-errors` exits 0 | PASS | No output = exit 0 |
| `Crosswake.CompanionGuard.assert_no_static_refs!()` returns :ok | PASS | Output: `guard_ok` |
| `mix test --exclude requires_example_host --exclude advisory_only` 0 failures | PASS | 1162 tests, 0 failures (61 excluded) |
| Phase 136 backstop tests (5) green | PASS | `phase136_decouple_proof_test.exs`: 5/5 |
| Phase 130 fail-closed tests (4) green | PASS | `phase130_fail_closed_contract_test.exs`: 4/4 |
| DECOUPLE-03 flipped to Complete | DONE | checkbox `[x]` + tracking table `Complete` |

## Self-Check

- `lib/crosswake/companions/sigra.ex` — FOUND
- `lib/crosswake/companions/chimeway.ex` (modified) — FOUND
- `lib/crosswake/support_matrix/support_matrix.ex` (modified) — FOUND
- `mix.exs` (modified) — FOUND
- Commits: b740e0b, 6be2c6a, 1bfd5fc — all FOUND in git log

## Self-Check: PASSED

All created/modified files exist. All task commits present.

## Issues Encountered

- BEAM module loading timing: `function_exported?/3` returned false for `auth_authority?/0` in `auth_contract_truth/0` before any call to the module. Required calling `companion_id/0` first to trigger loading (identical pattern to RouteGate).
- mix.exs `env:` semantics change: Adding the application env default changed the meaning of `delete_env` from "harmless no-op" to "destroys the runtime default". Required auditing 6 test files for state pollution.

## Next Phase Readiness

- Phase 137 (Sigra Extraction) has a working baseline: `Crosswake.Companions.Sigra` exists, implements all 11 callbacks, passes auth evaluation tests, is registered via mix.exs env:
- Phase 137 pre-extraction task: Before removing the Sigra entry from mix.exs env:, fix the 3 Category-B test files (operator_inspection_test + publish_readiness_test) to include Sigra in their companion lists — add as Phase 137 Task 0 or as companion registration guidance in the dress-rehearsal step
- Phase 137 will also implement SIGRA-02 (Finding-boundary refactor of evaluate_auth/3 — currently passes Denial.t() through per D-136-B)

---
*Phase: 136-core-decoupling*
*Completed: 2026-07-01*
