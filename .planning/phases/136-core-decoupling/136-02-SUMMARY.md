---
phase: 136-core-decoupling
plan: "02"
subsystem: telemetry
tags: [elixir, telemetry, pii, security, decouple, runtime-aggregation, forbidden-keys]

# Dependency graph
requires:
  - "136-01 — Crosswake.Companion behaviour extended with forbidden_metadata_keys/0 callback"
provides:
  - "Crosswake.Telemetry.baseline_forbidden_metadata_keys/0 — 10-atom public PII denylist"
  - "build_reserved_events/0 converted to runtime registry aggregation (zero static companion refs)"
  - "Forbidden-key MapSet built once in attach_default_logger/1 and captured in handler closure config"
  - "Phase-133 reserved-tier test is count-independent and shape-asserts the :reserved tier"
affects:
  - 136-03  # route_gate inversion (Plan 03); unblocked by telemetry inversion landing green
  - 136-04  # support_matrix inversion; unblocked
  - 136-05  # doctor inversion; unblocked

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Attach-time-cached MapSet: compute forbidden keys once in attach_default_logger/1 and pass as map config key to :telemetry.attach_many — handler closure reads from config, not per-event aggregation"
    - "Baseline PII floor via @module_attribute: 10 hardcoded atoms always unioned at attach; missing companion cannot weaken the floor"
    - "Runtime reserved-events aggregation: build_reserved_events/0 follows the L59-62 companion iteration pattern (Application.get_env + Enum.flat_map + function_exported?/3)"
    - "Handler config as map (not keyword list): enables :telemetry.list_handlers/1 inspector to read handler.config[:forbidden_keys] for attach-time capture verification"

key-files:
  created: []
  modified:
    - lib/crosswake/telemetry.ex
    - test/crosswake/proof/phase133_telemetry_contract_test.exs

key-decisions:
  - "Handler config passed to :telemetry.attach_many as a map (not keyword list) to support inspector reads via handler.config[:forbidden_keys] in backstop test 5"
  - "build_reserved_events/0 filters companion telemetry_events/0 for tier: :reserved, not re-uses; companion events() goes through the events/0 companion_events path already (dedup by Enum.uniq_by)"
  - "Threadline.Telemetry.forbidden_metadata_keys/0 kept as direct in-tree call in attach_default_logger/1 (Threadline stays in-tree for Phase 136 per scope boundary)"
  - "all_forbidden_keys/0 removed entirely — replaced by attach-time-cached MapSet in handler config"

patterns-established:
  - "Map.get/3 (not Keyword.get) in __handle_event__/4 — handler config is now a map, not keyword list"

requirements-completed: [DECOUPLE-01, DECOUPLE-05]

coverage:
  - id: D4
    description: "build_reserved_events/0 uses Application.get_env(:crosswake, :companions) + function_exported?/3 — zero static Sigra/Chimeway refs"
    requirement: DECOUPLE-01
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase136_decouple_proof_test.exs#DECOUPLE-01: events/0 with no companions returns non-empty list AND empty reserved set"
        status: pass
      - kind: grep
        ref: "grep -v '^\s*#' lib/crosswake/telemetry.ex | grep -c 'Companions.Sigra\|Companions.Chimeway' → 0"
        status: pass
      - kind: integration
        ref: "mix compile --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D5
    description: "baseline_forbidden_metadata_keys/0 returns exactly the 10-atom set"
    requirement: DECOUPLE-05
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase136_decouple_proof_test.exs#DECOUPLE-05: baseline_forbidden_metadata_keys/0 is callable and returns exactly the 10-atom set"
        status: pass
    human_judgment: false
  - id: D6
    description: "Forbidden key from companion captured at attach — persists after registry cleared"
    requirement: DECOUPLE-05
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase136_decouple_proof_test.exs#DECOUPLE-05: forbidden key from companion is scrubbed even after companion registry is cleared"
        status: pass
    human_judgment: false
  - id: D7
    description: "Phase-133 reserved-tier test is count-independent and passes with zero companions"
    requirement: DECOUPLE-01
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase133_telemetry_contract_test.exs#TELEM-04 :reserved tier events are excluded from declared=>emitted check"
        status: pass
    human_judgment: false

# Metrics
duration: 4min
completed: "2026-07-01"
status: complete
---

# Phase 136 Plan 02: Telemetry Inversion + Baseline PII Denylist Summary

**Telemetry module inverted onto runtime :companions registry with zero static Sigra/Chimeway references; 10-atom baseline PII denylist added and captured once in handler closure at attach time; Phase-133 reserved-tier test made count-independent.**

## Performance

- **Duration:** ~4 minutes
- **Started:** 2026-07-01T14:42:15Z
- **Completed:** 2026-07-01T14:46:55Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Replaced `build_reserved_events/0` static `Crosswake.Companions.Sigra.Telemetry.event_names()` ++ `Crosswake.Companions.Chimeway.Telemetry.event_names()` calls with runtime aggregation via `Application.get_env(:crosswake, :companions, [])` + `function_exported?(mod, :telemetry_events, 0)` filter for `:reserved` tier entries — zero static companion refs remain in `telemetry.ex`
- Added `@baseline_forbidden_keys` module attribute with exactly 10 hardcoded atoms (`:access_token, :refresh_token, :id_token, :authorization_code, :token, :session_ref, :subject_ref, :actor_id, :ip, :email`) and exposed `baseline_forbidden_metadata_keys/0` public function with semver contract @doc
- Updated `attach_default_logger/1` to build a merged forbidden-key `MapSet` once at attach time (baseline union Threadline union companion keys via `function_exported?/3`) and pass it as a map config argument to `:telemetry.attach_many/4`; updated `__handle_event__/4` to read from `Map.get(config, :forbidden_keys)` instead of calling the now-removed `all_forbidden_keys/0`
- Removed `all_forbidden_keys/0` private function (no longer needed; replaced by attach-time-cached MapSet)
- Replaced `length(reserved_events) >= 24` assertion and `stable_id_message` block in `phase133_telemetry_contract_test.exs` with count-independent shape assertion (`match?(%{event: [_ | _], tier: :reserved, measurements: m, metadata: meta} when is_list(m) and is_list(meta)`); test passes with zero companions registered

## Task Commits

1. **Task 1: Invert reserved events + add baseline PII denylist + cache forbidden set** - `f486a43` (feat)
2. **Task 2: Replace phase133 >= 24 count assertion with count-independent shape assertion** - `9ef0d7d` (test)

## Files Created/Modified

- `lib/crosswake/telemetry.ex` - Added @baseline_forbidden_keys (10 atoms) + baseline_forbidden_metadata_keys/0 public API; converted build_reserved_events/0 to runtime registry aggregation; updated attach_default_logger/1 to build+cache forbidden MapSet; updated __handle_event__/4 to read config as map; removed all_forbidden_keys/0
- `test/crosswake/proof/phase133_telemetry_contract_test.exs` - Replaced >= 24 assertion with shape assertion; kept no-overlap invariant and TELEM-01 stub-seeded merge test unchanged

## Decisions Made

- Handler config passed to `:telemetry.attach_many` as a map (`%{level: ..., encode: ..., forbidden_keys: ...}`) rather than a keyword list — enables `:telemetry.list_handlers/1` inspector to read `handler.config[:forbidden_keys]` for attach-time capture verification in backstop test 5
- `build_reserved_events/0` filters companion `telemetry_events/0` output for `:reserved` tier entries specifically — companion `:active` events flow through the existing `companion_events` path in `events/0` (dedup via `Enum.uniq_by`)
- `Crosswake.Threadline.Telemetry.forbidden_metadata_keys/0` kept as direct in-tree call in `attach_default_logger/1` (Threadline stays in-tree for Phase 136 per scope boundary)
- `all_forbidden_keys/0` removed entirely after the per-event aggregation is replaced by the attach-time-cached MapSet

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Next Phase Readiness

- Plan 03 can now implement `prepend_auth_evaluation_denials/4` inversion: the auth-dispatch path is the only remaining `Crosswake.Companions.Sigra` reference in `route_gate.ex` (`alias` and `Evaluator.evaluate_route_auth/3`)
- Backstop tests 1 (auth raises → deny) and 3 (multiple authority → first wins) are the GREEN gate for Plan 03
- Backstop tests 2 (zero companions, reserved empty) and 4 (baseline keys) and 5 (attach capture) are all GREEN after this plan

## Known Stubs

None - no stub values or placeholders in production code.

## Threat Flags

None - no new network endpoints, auth paths, or file access patterns introduced. The baseline PII denylist is an internal security hardening (T-136-05 mitigated); the forbidden-key caching change is a correctness fix (T-136-06 mitigated).

## Self-Check: PASSED
