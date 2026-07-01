---
phase: 136-core-decoupling
verified: 2026-07-01T14:20:00Z
status: passed
score: 6/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 5/6
  gaps_closed:
    - "Full ExUnit suite passes (mix test --exclude requires_example_host --exclude advisory_only reports 0 failures)"
    - "DECOUPLE-03 requirement checkbox is green (REQUIREMENTS.md)"
  gaps_remaining: []
  regressions: []
---

# Phase 136: Core Decoupling Verification Report

**Phase Goal:** Invert all four compile-time core→companion coupling sites onto the runtime `:companions` registry seam so core compiles without any companion present.
**Verified:** 2026-07-01T14:20:00Z
**Status:** passed
**Re-verification:** Yes — after gap-closure plan 136-06

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `mix compile --warnings-as-errors` passes with no crosswake_sigra/crosswake_chimeway in mix.exs deps | VERIFIED | Exit code 0; no companion packages in deps; mix.exs deps list is jason/nimble_options/phoenix/phoenix_live_view/telemetry/ex_doc only |
| 2 | Phase-129 companion-contract freeze test and COMPAT-01 fail-closed test pass with no companion present | VERIFIED | 37 combined backstop tests (phase136 x5, phase130_fail_closed x4, phase130_extraction_guards x13, phase129 x7, phase133 x8), all 37 pass |
| 3 | Auth-predicated routes deny with :dependency_missing when no auth_authority?/0 companion registered; companion that raises is rescued and also denies | VERIFIED | All 5 phase136 backstop proof tests pass; backstop Test 1 (no-authority → :dependency_missing) and Test 3 (raising companion → rescued → :dependency_missing) confirmed |
| 4 | Crosswake.Telemetry aggregates via function_exported?/3 at runtime; baseline PII denylist always applied; zero static Sigra/Chimeway refs in telemetry.ex | VERIFIED | grep for `Companions\.Sigra\|Companions\.Chimeway` on non-comment lines in telemetry.ex returns 0; backstop tests 4 and 5 pass |
| 5 | AST guard covers all lib/ minus lib/crosswake/companions/**; Sigra+Chimeway banned; prefix match catches child modules | VERIFIED | `mix run -e "Crosswake.CompanionGuard.assert_no_static_refs!()"` returns :ok (exit 0); assert_no_static_refs! uses List.starts_with? prefix match; phase130 extraction guard tests 13/13 pass |
| 6 | Full ExUnit suite passes (mix test --exclude requires_example_host --exclude advisory_only reports 0 failures) | VERIFIED | 1162 tests, 0 failures (61 excluded) — exit code 0 |

**Score:** 6/6 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/crosswake/companions/sigra.ex` | @behaviour Crosswake.Companion; 6 required + 5 optional callbacks (auth_authority?/0=true, evaluate_auth/3, denial_codes/0, forbidden_metadata_keys/0, telemetry_events/0); 3 non-behaviour accessors | VERIFIED | File exists; @behaviour declared; all 11 @impl callbacks present; evaluate_auth/3 delegates to Evaluator with Denial passthrough; auth_authority? returns true; tier: :reserved on every telemetry_events/0 map |
| `lib/crosswake/companions/chimeway.ex` | forbidden_metadata_keys/0 and telemetry_events/0 added; auth_authority?/0 intentionally absent | VERIFIED | forbidden_metadata_keys/0 @impl present delegating to ChimewayTelemetry; telemetry_events/0 @impl present with tier: :reserved maps; no auth_authority? definition |
| `lib/crosswake/support_matrix/support_matrix.ex` | auth_contract_truth/0 aggregates telemetry.event_names/metadata_keys/forbidden_metadata_keys/denial_codes/safe_detail_keys at runtime; companion_id/0 called first for BEAM loading | VERIFIED | function at L724-795; auth_authority scan with `_load = mod.companion_id()` before function_exported?; deep-merge into static map; all five fields populated from auth-authority companion |
| `mix.exs` | application/0 env: [companions: [Sigra, Chimeway]] alongside extra_applications: [:logger]; no config/ dir | VERIFIED | application/0 returns both extra_applications: [:logger] and env: [companions: [Crosswake.Companions.Sigra, Crosswake.Companions.Chimeway]]; `mix run -e "IO.inspect(Application.get_env(:crosswake, :companions, []))"` prints the two-module list |
| `lib/crosswake/companion_guard.ex` | Sigra+Chimeway in @extracted_companion_names; List.starts_with? prefix match; scope excludes companions/** | VERIFIED | Both module names at @extracted_companion_names; List.starts_with? at L101; companion_files subtraction in assert_no_static_refs!/0 |
| `test/crosswake/proof/phase136_decouple_proof_test.exs` | 5 backstop tests (fail-closed/PII/attach-capture behaviors), all GREEN, unchanged | VERIFIED | 5 tests, 0 failures |
| `.planning/REQUIREMENTS.md` | All DECOUPLE-01..06 checkboxes [x] and tracking table Complete | VERIFIED | All six DECOUPLE-* rows show [x] checkbox and "Complete" status in traceability table |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `mix.exs application/0 env:` | `Application.get_env(:crosswake, :companions, [])` | Every registry call site uses get_env not compile_env | WIRED | Confirmed: grep for `Application\.compile_env\b` in core files returns 0 actual call sites (comments only) |
| `:companions registry` | `auth_authority?/0` + `evaluate_auth/3` | `RouteGate.prepend_auth_evaluation_denials/4` scans registry via function_exported? | WIRED | Backstop tests 1 and 3 confirm :dependency_missing when no authority registered and when authority raises |
| `:companions registry` | `denial_codes/0` | `auth_contract_truth/0` flat_map + auth-authority selection | WIRED | support_matrix_test 54/54 passing; denial_codes populated from Sigra |
| `:companions registry` | `telemetry_event_names/0` + `telemetry_metadata_keys/0` + `forbidden_metadata_keys/0` | `auth_contract_truth/0` auth-authority companion accessors | WIRED | Telemetry fields populated at runtime; fail-closed to [] when no authority registered |
| `@extracted_companion_names` | `check_source/1` prefix walk | `List.starts_with?(@banned_alias_parts)` | WIRED | assert_no_static_refs!() returns :ok; phase130 guard test 13/13 |
| `lib/crosswake/companions/sigra.ex` | Excluded from assert_no_static_refs! scan | `lib_files -- companion_files` subtraction | WIRED | companions/** excluded; AST guard returns :ok with sigra.ex present |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| 5 backstop proof tests (DECOUPLE-01/04/05) | `mix test test/crosswake/proof/phase136_decouple_proof_test.exs` | 5 tests, 0 failures | PASS |
| Phase-129 freeze test (11-callback contract) | `mix test test/crosswake/proof/phase129_companion_contract_freeze_test.exs` | 7 tests, 0 failures | PASS |
| COMPAT-01 fail-closed test | `mix test test/crosswake/proof/phase130_fail_closed_contract_test.exs` | 4 tests, 0 failures | PASS |
| Phase-133 telemetry contract (shape assertion) | `mix test test/crosswake/proof/phase133_telemetry_contract_test.exs` | 8 tests, 0 failures | PASS |
| Phase-130 extraction guards (Sigra detection) | `mix test test/crosswake/proof/phase130_extraction_guards_test.exs` | 13 tests, 0 failures | PASS |
| Companions registry default | `mix run -e "IO.inspect(Application.get_env(:crosswake, :companions, []))"` | [Crosswake.Companions.Sigra, Crosswake.Companions.Chimeway] | PASS |
| AST static-ref guard (full lib scan) | `mix run -e "Crosswake.CompanionGuard.assert_no_static_refs!()"` | exit 0, output: guard_ok | PASS |
| Compile gate | `mix compile --warnings-as-errors` | exit 0 | PASS |
| Full suite | `mix test --exclude requires_example_host --exclude advisory_only` | 1162 tests, 0 failures (61 excluded) | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| DECOUPLE-01 | 136-02 | Telemetry aggregates via runtime registry; zero compile-time companion refs | SATISFIED | telemetry.ex non-comment grep returns 0; build_reserved_events/0 uses function_exported?/3; backstop tests 4/5 GREEN |
| DECOUPLE-02 | 136-03 | RouteGate resolves auth via registry; no static Sigra.Evaluator alias | SATISFIED | route_gate.ex non-comment grep returns 0; auth dispatch uses auth_authority?/0 + evaluate_auth/3; backstop tests 1/3 GREEN |
| DECOUPLE-03 | 136-04, 136-06 | SupportMatrix/Doctor get companion denial codes at runtime; no module-eval companion calls; Sigra facade wired via mix.exs env: | SATISFIED | auth_contract_truth/0 runtime aggregation verified; mix.exs env: contains [Sigra, Chimeway]; REQUIREMENTS.md checkbox [x] and tracking row Complete; support_matrix_test 54/54 |
| DECOUPLE-04 | 136-03 | Auth-predicated routes fail closed with :dependency_missing; raises rescued | SATISFIED | Backstop tests 1 and 3 GREEN; try/rescue in prepend_auth_evaluation_denials/4; phase130 fail-closed 4/4 |
| DECOUPLE-05 | 136-02 | 10-atom baseline PII denylist always applied; baseline_forbidden_metadata_keys/0 public | SATISFIED | @baseline_forbidden_keys 10 atoms; public def; attach-time MapSet; backstop tests 4/5 GREEN |
| DECOUPLE-06 | 136-05 | AST guard covers all lib/ minus companions/; Sigra+Chimeway banned; prefix match | SATISFIED | assert_no_static_refs!() returns :ok; phase130 guard test 13/13 GREEN |

### Anti-Patterns Found

No `TBD`, `FIXME`, or `XXX` debt markers found in modified production files (`sigra.ex`, `chimeway.ex`, `support_matrix.ex`, `mix.exs`).

The only comment references to `Companions.Sigra` in core files are in code comments explaining the inversion (e.g. `route_gate.ex:257` comment "Inlined from Sigra.Evaluator.auth_predicated?/1") — these are not static alias AST nodes and do not constitute coupling. Confirmed by AST guard returning :ok.

### Human Verification Required

None — all verification checks are mechanically deterministic.

---

## Re-verification Summary

**Previous status:** gaps_found (5/6 — full suite had 34 test regressions; DECOUPLE-03 checkbox unchecked)

**Gaps closed by Plan 136-06:**

1. Built `lib/crosswake/companions/sigra.ex` — `@behaviour Crosswake.Companion` facade with all 11 callbacks delegating to Sigra sub-modules; `evaluate_auth/3` passes `{:deny, Denial.t()}` through unchanged (D-136-B, no Finding conversion); `auth_authority?/0` returns true.

2. Extended `chimeway.ex` with `forbidden_metadata_keys/0` and `telemetry_events/0`; `auth_authority?/0` correctly absent.

3. Registered `[Sigra, Chimeway]` via `mix.exs application/0 env:` — idiomatic Hex library mechanism; no `config/` directory created; Sigra listed first for first-registered-wins auth authority scan.

4. Extended `SupportMatrix.auth_contract_truth/0` to aggregate `telemetry.event_names`, `telemetry.metadata_keys`, `telemetry.forbidden_metadata_keys`, `denial_codes`, and `safe_detail_keys` from the registered auth-authority companion at runtime via `function_exported?/3` dispatch; fail-closed when no auth authority is registered. BEAM module-loading guard (`companion_id/0` called before `function_exported?/3`) applied to avoid false-negative from deferred BEAM module loading.

5. Fixed `delete_env` state pollution: adding `env:` to `mix.exs` changed semantics of previously-harmless `Application.delete_env` calls in phases 38/40/41/43 test cleanup — patched with save/restore in setup blocks.

6. Pre-authorized test edits: `route_gate_test.exs` and `phase46_sigra_auth_contract_test.exs` now register `Crosswake.Companions.Sigra` (via put_env with save/restore) instead of clearing the registry — the tests' intent (auth-predicated route denies with :step_up_required) is preserved because the real Sigra evaluator is now dispatched. Phase 47 test updated to include Sigra in companion list.

7. Orchestrator resolved 3 escalated Category-B failures in `operator_inspection_test.exs` and `publish_readiness_test.exs` by prepending Sigra to their `[StubCompanion]` companion lists — architecturally required because re-sourcing auth contract data from statics would re-introduce exactly the coupling DECOUPLE-03 removes.

8. REQUIREMENTS.md DECOUPLE-03 flipped to Complete (checkbox `[x]` + tracking table row).

**Full suite result:** 1162 tests, 0 failures (61 excluded) — phase goal achieved.

---

_Verified: 2026-07-01T14:20:00Z_
_Verifier: Claude (gsd-verifier)_
