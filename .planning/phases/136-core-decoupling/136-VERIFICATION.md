---
phase: 136-core-decoupling
verified: 2026-07-01T11:50:00Z
status: gaps_found
score: 5/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Full ExUnit suite passes (mix test --exclude requires_example_host --exclude advisory_only reports 0 failures)"
    status: failed
    reason: "34 failures in mix test. Root cause: in-repo Sigra/Chimeway companion modules do not implement the new evaluate_auth/3 and auth_authority?/0 callbacks. Tests that previously exercised Sigra.Evaluator through a direct call now get :dependency_missing instead of :step_up_required from the registry dispatch. Additionally, SupportMatrix.auth_contract_truth/0 returns denial_codes: [] sentinel because no Sigra companion is registered in the test env and the sentinel pattern does not populate from a companion lacking the denial_codes/0 callback implementation."
    artifacts:
      - path: "lib/crosswake/companions/sigra/evaluator.ex"
        issue: "Does not implement evaluate_auth/3 or auth_authority?/0 — companion module is never registered as an auth_authority?/0 companion in test env"
      - path: "lib/crosswake/companions/chimeway.ex"
        issue: "Does not implement evaluate_auth/3 or auth_authority?/0"
      - path: "lib/crosswake/support_matrix/support_matrix.ex"
        issue: "auth_contract_truth/0 returns denial_codes: [] because no in-tree companion implements denial_codes/0 callback"
    missing:
      - "In-tree Sigra companion entry-point module (lib/crosswake/companions/sigra.ex or equivalent) must implement evaluate_auth/3 and auth_authority?/0 and be registered in test env"
      - "OR: existing tests (phase46, phase47, phase54-58, phase71, phase73, route_gate_test, chimeway_resolver_test, doctor_test, support_matrix_test, operator_inspection_test, phase135_ci_ops_proof_test, doctor_publish_readiness_test) must be updated to register a stub companion with auth_authority?/0 + evaluate_auth/3 that returns :step_up_required — matching the pre-inversion behavior"
      - "OR: implement the callbacks in the in-tree Sigra modules and register Crosswake.Companions.Sigra as a companion in test/config; note this is a pre-extraction step that must land before Phase 137 dress rehearsal"
  - truth: "DECOUPLE-03 requirement checkbox is green (REQUIREMENTS.md)"
    status: failed
    reason: "REQUIREMENTS.md still shows DECOUPLE-03 as [ ] Pending (not Complete), confirming the requirement traceability is not closed. The implementation exists at the code level (runtime helpers in support_matrix.ex, doctor.ex) but the test suite regressions caused by the sentinel approach block acceptance."
    artifacts:
      - path: ".planning/REQUIREMENTS.md"
        issue: "DECOUPLE-03 row shows 'Pending' in the tracking table; checkbox is unchecked"
    missing:
      - "REQUIREMENTS.md DECOUPLE-03 checkbox must be marked complete — requires the test failures it caused to be resolved"
---

# Phase 136: Core Decoupling Verification Report

**Phase Goal:** Core compiles and operates correctly with no companion package present — all four compile-time sigra/chimeway references inverted onto the `:companions` registry seam.
**Verified:** 2026-07-01T11:50:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `mix compile --warnings-as-errors` passes with no crosswake_sigra/crosswake_chimeway in mix.exs | VERIFIED | Exit code 0; mix.exs deps contain only jason/nimble_options/phoenix/phoenix_live_view/telemetry/ex_doc |
| 2 | Phase-129 companion-contract freeze test and COMPAT-01 fail-closed test pass with no companion present | VERIFIED | phase129 (7 tests, 0 failures); phase130_fail_closed (4 tests, 0 failures) |
| 3 | Auth-predicated routes deny with :dependency_missing when no auth_authority?/0 companion registered; companion that raises is rescued and also denies | VERIFIED | All 5 backstop tests pass (5 tests, 0 failures); tests 1 and 3 directly exercise these behaviors |
| 4 | Crosswake.Telemetry aggregates via function_exported?/3 at runtime; baseline PII denylist always applied; zero static Sigra/Chimeway refs in telemetry.ex | VERIFIED | grep -c 'Companions.Sigra\|Companions.Chimeway' on non-comment lines returns 0; baseline_forbidden_metadata_keys/0 public; attach-time MapSet captured in closure |
| 5 | AST guard covers all lib/ minus lib/crosswake/companions/**; Sigra+Chimeway banned; prefix match catches child modules | VERIFIED | mix run -e "Crosswake.CompanionGuard.assert_no_static_refs!()" exits 0; check_source uses List.starts_with? |
| 6 | Full ExUnit suite passes (mix test reports 0 failures) | FAILED | mix test: 1213 tests, 34 failures — see Gap section below |

**Score:** 5/6 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/crosswake/companion.ex` | 11 callbacks (7 existing + 4 new optional: forbidden_metadata_keys/0, denial_codes/0, evaluate_auth/3, auth_authority?/0) | VERIFIED | @optional_callbacks keyword list has 5 entries; compiles clean |
| `lib/crosswake/telemetry.ex` | Runtime build_reserved_events/0; @baseline_forbidden_keys; baseline_forbidden_metadata_keys/0; attach-time cached MapSet | VERIFIED | All four present; no static companion refs on non-comment lines |
| `lib/crosswake/compatibility/route_gate.ex` | Evaluator alias removed; inlined auth_predicated?/1; registry dispatch; fail-closed + rescue | VERIFIED | grep Companions.Sigra returns 0 on non-comment lines; auth_predicated?/1 private helper present; try/rescue in prepend_auth_evaluation_denials/4 |
| `lib/crosswake/support_matrix/support_matrix.ex` | @auth_contract_truth_static + def auth_contract_truth/0 runtime helper; @notification_support_truth_static; SigraTelemetry alias removed | VERIFIED | grep Companions.Sigra/SigraTelemetry returns 0 on non-comment lines; def auth_contract_truth/0 aggregates denial_codes at call time |
| `lib/crosswake/doctor/doctor.ex` | Sigra.DenialCodes fallback defaults replaced with registry lookups | VERIFIED | grep Companions.Sigra returns 0 on non-comment lines |
| `lib/crosswake/companion_guard.ex` | Sigra+Chimeway in @extracted_companion_names; List.starts_with? prefix match; scope excludes companions/** | VERIFIED | Both names present at L43/L46; List.starts_with? at L101; companion_files subtraction in assert_no_static_refs!/0 |
| `lib/crosswake/policy/schema.ex` | SigraContracts alias removed; @mfa_level_vocabulary inlined | VERIFIED | Deviation from plan was caught and fixed by Plan 05 (5th coupling site discovered at runtime) |
| `test/crosswake/proof/phase136_decouple_proof_test.exs` | 5 backstop tests covering fail-closed/PII/attach-capture behaviors, all GREEN | VERIFIED | 5 tests, 0 failures confirmed by direct run |
| `test/crosswake/proof/phase129_companion_contract_freeze_test.exs` | Updated to 11-callback @expected_callbacks; passes | VERIFIED | 7 tests, 0 failures |
| `test/crosswake/proof/phase133_telemetry_contract_test.exs` | >= 24 count assertion removed; shape assertion added; passes | VERIFIED | 8 tests, 0 failures (confirmed in phase133 run) |
| `test/crosswake/proof/phase130_extraction_guards_test.exs` | Sigra assertion inverted to {:violation, _}; scope-exclusion test added; passes | VERIFIED | 13 tests, 0 failures |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `attach_default_logger/1` | Handler closure config | MapSet.union(@baseline_forbidden_keys, companion_keys) passed in :telemetry.attach_many config | WIRED | handler.config[:forbidden_keys] accessible; backstop test 5 verifies closure capture |
| `:companions registry` | `function_exported?(mod, :telemetry_events, 0)` | `build_reserved_events/0` Enum.flat_map over Application.get_env(:crosswake, :companions, []) | WIRED | Confirmed by zero static refs in telemetry.ex; backstop test 2 verifies empty reserved set with no companions |
| `:companions registry` | `auth_authority?/0` + `evaluate_auth/3` | `prepend_auth_evaluation_denials/4` registry scan filtered by function_exported? | WIRED | Confirmed by direct inspection; backstop tests 1/3 verify behavior |
| `:companions registry` | `denial_codes/0` callback | `auth_contract_truth/0` Enum.flat_map aggregation at call time | WIRED (hollow) | Code wired correctly but no in-tree companion implements denial_codes/0 — test env returns [] |
| `@extracted_companion_names` | `check_source/1` prefix walk | `Enum.any?(@banned_alias_parts, &List.starts_with?(parts, &1))` | WIRED | Confirmed by phase130 guard test (13 tests, 0 failures) |
| `assert_no_static_refs!/0` | `lib_files -- companion_files` | Path.wildcard two globs, list subtraction | WIRED | Verified by running assert_no_static_refs!() returning :ok |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| 5 backstop proof tests (DECOUPLE-01/04/05) | `mix test test/crosswake/proof/phase136_decouple_proof_test.exs` | 5 tests, 0 failures | PASS |
| Phase-129 freeze test (11-callback contract) | `mix test test/crosswake/proof/phase129_companion_contract_freeze_test.exs` | 7 tests, 0 failures | PASS |
| COMPAT-01 fail-closed test | `mix test test/crosswake/proof/phase130_fail_closed_contract_test.exs` | 4 tests, 0 failures | PASS |
| Phase-133 telemetry contract (shape assertion) | `mix test test/crosswake/proof/phase133_telemetry_contract_test.exs` | 8 tests, 0 failures | PASS |
| Phase-130 extraction guards (Sigra detection) | `mix test test/crosswake/proof/phase130_extraction_guards_test.exs` | 13 tests, 0 failures | PASS |
| AST static-ref guard (full lib scan) | `mix run -e "Crosswake.CompanionGuard.assert_no_static_refs!()"` | exit 0 | PASS |
| Compile gate | `mix compile --warnings-as-errors` | exit 0 | PASS |
| Full suite | `mix test` | 1213 tests, 34 failures | FAIL |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| DECOUPLE-01 | 136-02 | Telemetry aggregates via runtime registry; zero compile-time companion refs | SATISFIED | telemetry.ex non-comment grep returns 0; build_reserved_events/0 uses function_exported?/3 |
| DECOUPLE-02 | 136-03 | RouteGate resolves auth via registry; no static Sigra.Evaluator alias | SATISFIED | route_gate.ex non-comment grep returns 0; auth dispatch uses auth_authority?/0 + evaluate_auth/3 |
| DECOUPLE-03 | 136-04 | SupportMatrix/Doctor get companion denial codes at runtime; no module-eval companion calls | PARTIAL | Code implementation exists (def runtime helpers, registry lookups); REQUIREMENTS.md still shows Pending; 13 test regressions from the sentinel approach blocking full acceptance |
| DECOUPLE-04 | 136-03 | Auth-predicated routes fail closed with :dependency_missing; raises rescued | SATISFIED | Backstop tests 1 and 3 GREEN; try/rescue present; predicate gate in place |
| DECOUPLE-05 | 136-02 | 10-atom baseline PII denylist always applied; baseline_forbidden_metadata_keys/0 public | SATISFIED | @baseline_forbidden_keys 10 atoms; public def; attach-time MapSet; backstop tests 4 and 5 GREEN |
| DECOUPLE-06 | 136-05 | AST guard covers all lib/ minus companions/; Sigra+Chimeway banned; prefix match | SATISFIED | assert_no_static_refs!() returns :ok; phase130 guard test 13/13 GREEN |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/crosswake/support_matrix/support_matrix.ex` | sentinel fields | denial_codes: [], event_names: [], metadata_keys: [], forbidden_metadata_keys: [] in @auth_contract_truth_static | Warning | Sentinel [] values are accurate runtime state when no companion registered, per plan decision; not stubs in the traditional sense. However they cause 13+ test regressions in tests that assert denial_codes populated from Sigra. |

No `TBD`, `FIXME`, or `XXX` debt markers found in modified production files.

### Human Verification Required

None — all gaps are mechanically verifiable.

---

## Gaps Summary

**1 blocking gap — full suite not green.**

The 34 test failures all share the same root cause: the in-repo Sigra companion modules (`lib/crosswake/companions/sigra/evaluator.ex` and siblings) do NOT implement the four new optional callbacks (`evaluate_auth/3`, `auth_authority?/0`, `forbidden_metadata_keys/0`, `denial_codes/0`). No module in `lib/crosswake/companions/sigra/` has `@behaviour Crosswake.Companion` and no companion is registered in the test Application environment with `auth_authority?/0 = true`.

**Failure categories (34 total):**

- **Category A — :dependency_missing instead of :step_up_required (21 failures):** Tests in Phase46SigraAuthContractTest, Phase47CompanionArcTest, Phase55SessionHandoffTicketsTest, Phase56StepUpCeremonyTest, Phase71NotificationWorkflowProofTest, Phase73AuthSensitiveAdminWorkflowProofTest, RouteGateTest, Chimeway.ResolverTest set up auth-predicated routes and call RouteGate.evaluate but do not register a companion with `auth_authority?/0`. Previously Sigra.Evaluator was called directly (no registry); now the registry finds no auth_authority companion and returns :dependency_missing. Fix: add `auth_authority?/0 = true` and `evaluate_auth/3` (returning Sigra's evaluation) to the test stubs OR to the in-tree Sigra facade.

- **Category B — denial_codes: [] (13 failures):** Tests in Phase54SigraSessionAuthorityTest, Phase56StepUpCeremonyTest, Phase57AuthReturnBoundariesTest, Phase58AuthDiagnosticsCloseoutTest, Phase52OperatorTruthTest, SupportMatrixTest, DoctorTest, OperatorInspectionTest, Phase135CiOpsProofTest, Doctor.PublishReadinessTest assert that `SupportMatrix.auth_contract_truth()` returns populated `denial_codes`. The runtime helper now returns `[]` because no companion implements `denial_codes/0`. Fix: implement `denial_codes/0` in the in-tree Sigra companion facade, or update these tests to not assert specific denial_codes from SupportMatrix (moving those assertions to sigra's own companion-package test).

**Why this is a gap, not deferred:** Phase 136's own VALIDATION.md contract requires "Full suite must be green + mix compile --warnings-as-errors" before `/gsd-verify-work`. Plan 05's Task 3 acceptance criteria explicitly requires `mix test --exclude requires_example_host --exclude advisory_only` to report 0 failures. Plan 05's SUMMARY documents 32 failures and explicitly labels this a "Gap documented from Plan 04." The failures are direct regressions introduced by Phase 136's sentinel approach and registry inversion — they are not pre-Phase-136 failures.

**Phase 137 connection:** Phase 137 SC-3 requires a dress rehearsal where `mix test` passes — this will require implementing the callbacks in the extracted sigra package and registering it. However, the test regressions need to be resolved before Phase 137 extracts sigra, because Phase 137 requires a working baseline to dress-rehearse against. The fix can be done either: (a) in Phase 136 gap closure by adding callback implementations to the in-tree sigra companion modules and registering Sigra in the test env, or (b) at the start of Phase 137 before extraction begins. The VALIDATION.md contract places responsibility on Phase 136.

---

_Verified: 2026-07-01T11:50:00Z_
_Verifier: Claude (gsd-verifier)_
