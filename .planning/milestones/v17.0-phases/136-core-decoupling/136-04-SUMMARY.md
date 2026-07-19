---
phase: 136-core-decoupling
plan: "04"
subsystem: testing
tags: [elixir, support-matrix, doctor, stale-beam, runtime-registry, denial-codes, decouple]

# Dependency graph
requires:
  - phase: 136-01
    provides: "denial_codes/0 optional callback declared on Crosswake.Companion behaviour"
provides:
  - "SupportMatrix.auth_contract_truth/0 and notification_support_truth/0 are def runtime helpers; no module-eval companion call; no SigraTelemetry alias"
  - "Doctor phase_46_auth_findings/1 obtains denial_codes and safe_detail_keys via :companions registry; no static Sigra.DenialCodes reference"
affects:
  - 136-05  # companion_guard.ex AST prefix-walk fix builds on these removals

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Stale-beam footgun fix: @attr module attribute with companion calls -> @attr_static map + def runtime helper that reads :companions registry"
    - "Sentinel pattern: companion-sourced fields set to [] in static map; callers (Doctor) fill via registry at runtime"
    - "Application.get_env(:crosswake, :companions, []) + function_exported?(mod, :denial_codes, 0) aggregation in def body"

key-files:
  created: []
  modified:
    - lib/crosswake/support_matrix/support_matrix.ex
    - lib/crosswake/doctor/doctor.ex

key-decisions:
  - "Sentinel approach for companion-sourced fields: static map holds [] sentinels; runtime helpers (auth_contract_truth/0) populate denial_codes via registry aggregation; notification_support_truth/0 returns static map as-is (no denial_codes field)"
  - "auth_contract_truth/0 now aggregates denial_codes at call time via function_exported?(mod, :denial_codes, 0) over :companions registry; safe_detail_keys remains [] (no companion exposes it separately)"
  - "Doctor Map.get/3 fallback: replaced Sigra.DenialCodes.codes() default with inline registry aggregation; safe_detail_keys defaults to []"

patterns-established:
  - "Module attribute split pattern: @foo_static holds pure static data; def foo/0 computes companion-sourced fields at runtime from registry"

requirements-completed: [DECOUPLE-03]

coverage:
  - id: D1
    description: "SupportMatrix.auth_contract_truth/0 is a def runtime helper computing denial_codes via :companions registry; no Sigra alias or module-eval companion call remains"
    requirement: DECOUPLE-03
    verification:
      - kind: integration
        ref: "grep -v '^\\s*#' lib/crosswake/support_matrix/support_matrix.ex | grep -c 'Companions.Sigra\\|SigraTelemetry' → 0"
        status: pass
      - kind: integration
        ref: "mix compile --warnings-as-errors"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase133_telemetry_contract_test.exs#8 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D2
    description: "SupportMatrix.notification_support_truth/0 is a def runtime helper; Chimeway.Telemetry companion calls removed; telemetry fields are [] sentinels"
    requirement: DECOUPLE-03
    verification:
      - kind: integration
        ref: "grep -v '^\\s*#' lib/crosswake/support_matrix/support_matrix.ex | grep -c 'Companions.Chimeway' → 0"
        status: pass
      - kind: integration
        ref: "mix compile --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D3
    description: "Doctor phase_46_auth_findings/1 obtains denial_codes via :companions registry; no static Sigra.DenialCodes reference remains in doctor.ex"
    requirement: DECOUPLE-03
    verification:
      - kind: integration
        ref: "grep -v '^\\s*#' lib/crosswake/doctor/doctor.ex | grep -c 'Companions.Sigra' → 0"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase130_fail_closed_contract_test.exs#4 tests, 0 failures"
        status: pass
    human_judgment: false

# Metrics
duration: 5min
completed: "2026-07-01"
status: complete
---

# Phase 136 Plan 04: SupportMatrix + Doctor Runtime Inversion Summary

**Stale-beam footgun eliminated: @auth_contract_truth and @notification_support_truth module attributes converted to def runtime helpers; Doctor's Sigra.DenialCodes fallback defaults replaced with :companions registry lookups via denial_codes/0 callback.**

## Performance

- **Duration:** ~5 minutes
- **Started:** 2026-07-01T14:58:56Z
- **Completed:** 2026-07-01T15:04:09Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Removed `alias Crosswake.Companions.Sigra.Telemetry, as: SigraTelemetry` from support_matrix.ex (L16 coupling site A)
- Converted `@auth_contract_truth` (110-line list-of-maps with 5 companion call sites at L211-213/L226-227) from module attribute to `@auth_contract_truth_static` map + `def auth_contract_truth/0` runtime helper that aggregates `denial_codes` from the `:companions` registry via `function_exported?(mod, :denial_codes, 0)`
- Converted `@notification_support_truth` (22-line map with 3 Chimeway.Telemetry call sites at L266-269) from module attribute to `@notification_support_truth_static` + `def notification_support_truth/0` returning static sentinel-filled map
- Replaced both `Map.get(auth_truth, :denial_codes, Sigra.DenialCodes.codes())` and `Map.get(auth_truth, :safe_detail_keys, Sigra.DenialCodes.allowed_detail_keys())` in `doctor.ex phase_46_auth_findings/1` with runtime registry lookup (denial_codes) and `[]` default (safe_detail_keys)
- `mix compile --warnings-as-errors` clean; phase133 telemetry contract (8/8 pass) and phase130 fail-closed contract (4/4 pass) green

## Task Commits

1. **Task 1: Convert support_matrix stale-beam attributes to runtime helpers** - `392d0fb` (refactor)
2. **Task 2: Replace doctor Sigra.DenialCodes fallback defaults with runtime lookups** - `5d4a06b` (refactor)

## Files Created/Modified

- `lib/crosswake/support_matrix/support_matrix.ex` - Removed SigraTelemetry alias; converted @auth_contract_truth and @notification_support_truth from module attributes to @_static maps + def runtime helpers; updated public accessors with runtime registry aggregation and @doc explaining sentinel pattern
- `lib/crosswake/doctor/doctor.ex` - Replaced static Sigra.DenialCodes.codes() and .allowed_detail_keys() Map.get/3 fallback defaults with :companions registry lookup and [] default respectively; added comment explaining DECOUPLE-03 rationale

## Decisions Made

- Sentinel approach (option a from RESEARCH.md Open Question 2): companion-sourced fields (event_names, metadata_keys, forbidden_metadata_keys, denial_codes, safe_detail_keys) set to `[]` in the static map; `auth_contract_truth/0` runtime helper fills `denial_codes` by aggregating over the `:companions` registry; `notification_support_truth/0` returns sentinels as-is since no `denial_codes` callback applies to Chimeway's telemetry-only surface
- `safe_detail_keys` defaults to `[]` in both SupportMatrix and Doctor — no companion currently exposes this separately, and the sentinel accurately reflects the runtime state without a static companion reference
- Used `@auth_contract_truth_static` / `@notification_support_truth_static` as the module attribute names for the pure-static data, keeping the static Elixir map expression (no function calls) for compile-time safety

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None - the sentinel `[]` values for telemetry fields (event_names, metadata_keys, forbidden_metadata_keys) are accurate runtime state when no companion is registered, not placeholder stubs. They reflect the real value of the registry at call time.

## Threat Flags

None - no new network endpoints, auth paths, or file access patterns introduced. This is a pure refactor converting module-eval calls to runtime registry reads.

## Self-Check: PASSED
