---
phase: 138-crosswake-chimeway-extraction
plan: 02
subsystem: companion-extraction
tags: [elixir, hex, companion, chimeway, extraction, test-suite, cleanroom, chime-01, chime-02]

requires:
  - phase: 138-01
    provides: crosswake_chimeway package skeleton; all 7 chimeway source files moved from core;
      chimeway test files deleted from core; core suite green at 987 tests

provides:
  - packages/crosswake_chimeway/test/crosswake/companions/chimeway/ — 5 unit tests (MOVED)
  - packages/crosswake_chimeway/test/crosswake/companions/chimeway_test.exs — facade test (MOVED)
  - packages/crosswake_chimeway/test/crosswake/proof/phase59_chimeway_contract_test.exs — 4 TOKN-02/contract tests (MOVED)
  - test/crosswake/proof/phase59_chimeway_support_truth_test.exs — SupportMatrix.notification_support_truth/0 assertion retained in core
  - packages/crosswake_chimeway/test/crosswake/proof/phase71_notification_workflow_proof_test.exs — MOVED from sigra package
  - packages/crosswake_chimeway/test/crosswake/proof/phase138_chimeway_cleanroom_test.exs — NEW non-vacuous cleanroom proof
  - {:crosswake_sigra, path: ..., only: :test} dep added to packages/crosswake_chimeway/mix.exs

affects:
  - 138-03 (CI wiring — depends on complete test lane established here)
  - 138-04 (human publish gate)
  - packages/crosswake_sigra (phase71 removed — sigra no longer depends on chimeway)

tech-stack:
  added: []
  patterns:
    - "Code.ensure_loaded!/1 before put_env in cleanroom setup — BEAM module loading required for function_exported?/3"
    - "test-only path dep {:crosswake_sigra, path: ..., only: :test} for phase71 real AuthContext integration proof"
    - "Telemetry cleanroom via attach-time handler.config[:forbidden_keys] MapSet (DECOUPLE-05 seam; NOT a non-existent aggregator)"
    - "Phase59 split: static SupportMatrix.notification_support_truth/0 retained in core (no put_env needed — static function)"
    - "Chimeway report_state().details assertion moved to package (Chimeway not available in core — D-21 no-companion-dep rule)"

key-files:
  created:
    - packages/crosswake_chimeway/test/crosswake/companions/chimeway/contracts_test.exs
    - packages/crosswake_chimeway/test/crosswake/companions/chimeway/denial_codes_test.exs
    - packages/crosswake_chimeway/test/crosswake/companions/chimeway/redaction_test.exs
    - packages/crosswake_chimeway/test/crosswake/companions/chimeway/resolver_test.exs
    - packages/crosswake_chimeway/test/crosswake/companions/chimeway/telemetry_test.exs
    - packages/crosswake_chimeway/test/crosswake/companions/chimeway_test.exs
    - packages/crosswake_chimeway/test/crosswake/proof/phase59_chimeway_contract_test.exs
    - packages/crosswake_chimeway/test/crosswake/proof/phase71_notification_workflow_proof_test.exs
    - packages/crosswake_chimeway/test/crosswake/proof/phase138_chimeway_cleanroom_test.exs
    - test/crosswake/proof/phase59_chimeway_support_truth_test.exs
  modified:
    - packages/crosswake_chimeway/mix.exs (added test-only crosswake_sigra path dep)
  deleted:
    - packages/crosswake_sigra/test/crosswake/proof/phase71_notification_workflow_proof_test.exs

key-decisions:
  - "Phase59 split — Chimeway.report_state().details moved to PACKAGE (not core): Chimeway modules not available in core (D-21 no companion-dep rule); the plan's suggestion to put_env chimeway in core to call Chimeway.report_state() was structurally impossible — there is no path dep on crosswake_chimeway from core. The SupportMatrix.notification_support_truth/0 assertion stays in core as a simple static assertion (no put_env needed; function is static)."
  - "Code.ensure_loaded!(Chimeway) added to cleanroom setup: ExUnit does not auto-load BEAM modules into the BEAM atom table; function_exported?/3 returns false for unloaded modules causing events/0 to skip chimeway's telemetry_events/0 callback. This is the canonical pattern for companion clean-room proofs in package-scoped test suites."
  - "RESEARCH A2 correction confirmed: Crosswake.Telemetry.forbidden_metadata_keys/0 does NOT exist; the real seam is handler.config[:forbidden_keys] MapSet in the crosswake-default-logger handler after attach_default_logger/0."
  - "Chimeway forbidden_metadata_keys non-empty check omitted: Elixir's type checker correctly flags `chimeway_forbidden != []` as always-true (compile-time known non-empty list); the per-key MapSet membership assertions are the real proof."

requirements-completed: [CHIME-01, CHIME-02]

coverage:
  - id: D7
    description: "5 chimeway unit tests + facade test pass in the package lane; no chimeway-internal test remains in core (CHIME-01)"
    requirement: CHIME-01
    verification:
      - kind: integration
        ref: "cd packages/crosswake_chimeway && mix test test/crosswake/companions/: 42 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D8
    description: "phase59 split: 4 contract tests in package; notification_support_truth/0 static assertion in core (non-vacuous: always returns 1 element)"
    requirement: CHIME-01
    verification:
      - kind: integration
        ref: "mix test test/crosswake/proof/phase59_chimeway_support_truth_test.exs: 1 test, 0 failures"
        status: pass
    human_judgment: false
  - id: D9
    description: "phase71 in chimeway package with test-only sigra dep; proves Chimeway.Resolver + real Sigra produce auth.step_up.* codes end-to-end"
    requirement: CHIME-01
    verification:
      - kind: integration
        ref: "cd packages/crosswake_chimeway && mix test test/crosswake/proof/phase71_notification_workflow_proof_test.exs: 6 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D10
    description: "Non-vacuous cleanroom proof: chimeway events in Telemetry.events/0 + forbidden keys in attach-time handler config + not-auth-authority + no-runtime-sigra-dep (CHIME-02)"
    requirement: CHIME-02
    verification:
      - kind: integration
        ref: "cd packages/crosswake_chimeway && mix test test/crosswake/proof/phase138_chimeway_cleanroom_test.exs: 4 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D11
    description: "Full chimeway package suite green (52 tests, 0 failures) + core dress rehearsal green (988 tests, 0 failures)"
    requirement: CHIME-01
    verification:
      - kind: integration
        ref: "cd packages/crosswake_chimeway && mix test: 52/0; mix test --exclude requires_example_host --exclude engine_present: 988/0"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-07-02
status: complete
---

# Phase 138 Plan 02: Chimeway Test Suite Move and Clean-Room Proof Summary

**Chimeway test suite moved to the package (5 unit tests + facade + 4 phase59 tests), phase71 moved from sigra package to chimeway package with test-only sigra dep, phase59 SupportMatrix assertion retained in core, and a non-vacuous 4-test clean-room proof created using real attach-time telemetry seams (RESEARCH A2 corrected).**

## Performance

- **Duration:** 10 min
- **Started:** 2026-07-02T18:25:53Z
- **Completed:** 2026-07-02T18:35:53Z
- **Tasks:** 3
- **Files modified:** 12 (10 created, 1 modified, 1 deleted)

## Accomplishments

- MOVED 5 chimeway-internal unit tests (`contracts`, `denial_codes`, `redaction`, `resolver`, `telemetry`) from core `test/crosswake/companions/chimeway/` to `packages/crosswake_chimeway/test/crosswake/companions/chimeway/`
- MOVED `chimeway_test.exs` (facade) to `packages/crosswake_chimeway/test/crosswake/companions/`
- SPLIT `phase59_chimeway_contract_test.exs`: 4 chimeway-internal tests (TOKN-02 lifecycle, raw-token absence, struct aliases, delivery_accepted) → package; `Chimeway.report_state().details` assertion also moved to package (Chimeway not available in core); `SupportMatrix.notification_support_truth/0` static assertion → new core file `test/crosswake/proof/phase59_chimeway_support_truth_test.exs`
- MOVED `phase71_notification_workflow_proof_test.exs` from `packages/crosswake_sigra/test/crosswake/proof/` to `packages/crosswake_chimeway/test/crosswake/proof/` (primary subject is `Chimeway.Resolver`; deleted from sigra)
- ADDED `{:crosswake_sigra, path: "../../packages/crosswake_sigra", only: :test}` to `packages/crosswake_chimeway/mix.exs` deps for phase71's real `%SigraContracts.AuthContext{}` construction
- CREATED `packages/crosswake_chimeway/test/crosswake/proof/phase138_chimeway_cleanroom_test.exs` — 4-test non-vacuous cleanroom proof:
  - Test 1: chimeway telemetry events in `Crosswake.Telemetry.events/0` (non-vacuous via `Code.ensure_loaded!` + put_env)
  - Test 2: chimeway forbidden keys in attach-time `handler.config[:forbidden_keys]` MapSet (RESEARCH A2 correction — no public aggregator function)
  - Test 3: `refute function_exported?(Chimeway, :auth_authority?, 0)` — notification-only
  - Test 4: no non-test crosswake_sigra dep in `Mix.Project.config()[:deps]`

## Task Commits

1. **Task 1: Move chimeway tests to package, split phase59** — `e36ca93f` (feat)
2. **Task 2: Move phase71 to chimeway package with test-only sigra dep** — `4ac425a6` (feat)
3. **Task 3: Non-vacuous chimeway cleanroom proof** — `13a9c646` (feat)

## Files Created/Modified

- `packages/crosswake_chimeway/test/crosswake/companions/chimeway/{contracts,denial_codes,redaction,resolver,telemetry}_test.exs` — MOVED from core
- `packages/crosswake_chimeway/test/crosswake/companions/chimeway_test.exs` — MOVED from core
- `packages/crosswake_chimeway/test/crosswake/proof/phase59_chimeway_contract_test.exs` — SPLIT from core (4 chimeway-internal tests + report_state assertion)
- `packages/crosswake_chimeway/test/crosswake/proof/phase71_notification_workflow_proof_test.exs` — MOVED from sigra package
- `packages/crosswake_chimeway/test/crosswake/proof/phase138_chimeway_cleanroom_test.exs` — NEW non-vacuous cleanroom proof
- `packages/crosswake_chimeway/mix.exs` — added `{:crosswake_sigra, path: ..., only: :test}` dep
- `test/crosswake/proof/phase59_chimeway_support_truth_test.exs` — NEW core-retained static assertion
- DELETED: `packages/crosswake_sigra/test/crosswake/proof/phase71_notification_workflow_proof_test.exs`

## Decisions Made

- **Phase59 split — Chimeway.report_state().details moved to package:** The plan anticipated `put_env` in core to call `Chimeway.report_state()`, but core has D-21 no-companion-dep rule — there is no `crosswake_chimeway` path dep in core's `mix.exs`. The `report_state().details` assertion was moved with the 4 contract tests into the package where Chimeway is available. The `SupportMatrix.notification_support_truth/0` assertion — a static function with no companion dependency — stays in core as `phase59_chimeway_support_truth_test.exs`.

- **Code.ensure_loaded!(Chimeway) in cleanroom setup:** ExUnit compiles modules but does NOT auto-load them into the BEAM module table. `function_exported?/3` (used by `Crosswake.Telemetry.events/0`) returns `false` for unloaded modules, causing chimeway's `telemetry_events/0` callback to be skipped and producing vacuous 0-event assertions. `Code.ensure_loaded!` in setup forces loading before registration. This is the correct pattern for package-scoped cleanroom proofs.

- **RESEARCH A2 confirmed FALSE:** `Crosswake.Telemetry.forbidden_metadata_keys/0` does not exist. The real seam is `handler.config[:forbidden_keys]` MapSet read from `:telemetry.list_handlers([:crosswake])` after `attach_default_logger/0` (DECOUPLE-05).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Chimeway.report_state().details assertion moved to package, not core**
- **Found during:** Task 1 (reading core mix.exs — D-21 prohibits companion path deps in core)
- **Issue:** The plan suggested calling `Chimeway.report_state()` in the core-retained `phase59_chimeway_support_truth_test.exs` by registering chimeway via `put_env`. However, `Crosswake.Companions.Chimeway` is NOT available in core's test env (no `crosswake_chimeway` path dep in core `mix.exs` per D-21). `put_env` sets the registry key but cannot conjure the compiled module.
- **Fix:** Moved `report_state().details` assertion to the package's `phase59_chimeway_contract_test.exs` (where Chimeway IS available). The core test contains only the static `SupportMatrix.notification_support_truth/0` assertion.
- **Files modified:** `test/crosswake/proof/phase59_chimeway_support_truth_test.exs` (no put_env, static only), `packages/crosswake_chimeway/test/crosswake/proof/phase59_chimeway_contract_test.exs` (added report_state assertion)

**2. [Rule 1 - Bug] Code.ensure_loaded!(Chimeway) added to cleanroom setup**
- **Found during:** Task 3 (test failure: chimeway events = 0 despite put_env)
- **Issue:** ExUnit test processes do not auto-load modules into the BEAM atom table. `function_exported?(Crosswake.Companions.Chimeway, :telemetry_events, 0)` returned `false` even though the BEAM file was compiled, causing `Crosswake.Telemetry.events/0` to skip chimeway's callback and return 0 chimeway events. Both Test 1 and Test 2 would have vacuously passed (empty filter / baseline-only forbidden keys).
- **Fix:** Added `Code.ensure_loaded!(Chimeway)` in setup before `Application.put_env`. This forces the module into the BEAM table so `function_exported?/3` returns `true`.
- **Files modified:** `packages/crosswake_chimeway/test/crosswake/proof/phase138_chimeway_cleanroom_test.exs`

**3. [Rule 1 - Bug] Removed chimeway_forbidden != [] type-violation assertion**
- **Found during:** Task 3 (Elixir type checker warning: comparing dynamic(non_empty_list) to [] is always true)
- **Issue:** `ChimewayTelemetry.forbidden_metadata_keys()` returns a compile-time known non-empty list; asserting `!= []` is flagged as always-true by Elixir's type checker.
- **Fix:** Removed the redundant assertion; the per-key `MapSet.member?` assertions are the real non-vacuity proof.
- **Files modified:** `packages/crosswake_chimeway/test/crosswake/proof/phase138_chimeway_cleanroom_test.exs`

## Issues Encountered

None beyond the documented deviations. All deviations were auto-fixed as Rule 1 bugs (incorrect behavior / vacuity risks).

## Known Stubs

None — all test files exercise real production behavior. The cleanroom proof uses real `attach_default_logger/0` and `Telemetry.events/0` (not mocked). Phase71 uses real `SigraContracts.new_auth_context/1` (not a stub map).

## Threat Flags

None — this plan creates test files only, with one `mix.exs` modification adding a test-only dep. No new network endpoints, auth paths, file access patterns, or schema changes. The STRIDE mitigations were verified:
- T-138-04 (vacuity): `Code.ensure_loaded!` + per-key MapSet assertions prevent vacuous cleanroom pass
- T-138-05 (dep creep): Test 4 runtime-dep guard + `only: :test` scoping preserve CHIME-02
- T-138-06 (PII): raw-token-absence test + hostile-metadata test both moved WITH chimeway (TOKN-02 stays proven)
- T-138-07 (vacuous support truth): Static `notification_support_truth/0` is always-populated (non-vacuous by construction)

## Next Phase Readiness

- Plan 03 (Wave 3): CI wiring — GitHub Actions config for the chimeway package lane; the test lane must be green (52/0 ✓) before CI wiring
- The `--exclude` grep in Plan 03 should scope to `lib/` and non-test deps when checking the no-sigra-dep invariant (the `only: :test` sigra dep is legitimately present in `deps`)

---
*Phase: 138-crosswake-chimeway-extraction*
*Completed: 2026-07-02*
