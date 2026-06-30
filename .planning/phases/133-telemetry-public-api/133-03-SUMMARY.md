---
phase: 133-telemetry-public-api
plan: "03"
subsystem: telemetry
tags: [telemetry, elixir, logger, pii-safety, opt-in]

# Dependency graph
requires:
  - phase: 133-02
    provides: Crosswake.Telemetry facade with events/0 and event_doc type
provides:
  - attach_default_logger/1 — opt-in structured logger for all :active telemetry events
  - detach_default_logger/0 — removes the default logger handler
  - PII-safe __handle_event__/4 handler with exception-level override (D-14) and forbidden-key scrub (D-15)
  - all_forbidden_keys/0 — runtime union of Threadline + Sigra + Chimeway denylists
affects: [133-04, guides/telemetry.md documentation, TELEM-03 requirement]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "opt-in telemetry logger: core never auto-attaches; host calls attach_default_logger/1 explicitly (TELEM-03)"
    - "MFA handler ref: __handle_event__/4 is public @doc false to avoid :telemetry local-function advisory"
    - "exception-level override: List.last(event_name) == :exception forces :error regardless of configured level (D-14)"
    - "forbidden-key union: all_forbidden_keys/0 collects three subsystem denylists at call time (D-15)"
    - "encode: false default: structured map in Logger.metadata for host formatter; encode: true JSON-encodes (D-14)"

key-files:
  created: []
  modified:
    - lib/crosswake/telemetry.ex

key-decisions:
  - "attach_default_logger/1 uses MFA ref &__MODULE__.__handle_event__/4 (public @doc false) instead of &handle_event/4 (private capture) to suppress the :telemetry local-function advisory at runtime"
  - "D-14: encode: false is the default — structured map placed in Logger.metadata so host formatters handle JSON; encode: true JSON-encodes into the message string"
  - "D-13: no custom double-attach guard — rely on :telemetry's built-in {:error, :already_exists}; double-detach yields {:error, :not_found} from :telemetry.detach/1"
  - "D-15: all_forbidden_keys/0 is a private runtime union of Threadline + Sigra + Chimeway forbidden_metadata_keys/0 — reuses existing denylists, never duplicates them"
  - "TELEM-03 invariant: no call to attach_default_logger from any application-start or supervision-tree module; verified by acceptance grep"

patterns-established:
  - "Opt-in telemetry logger: host must call attach_default_logger/1 — core is never the caller"
  - "Exception override pattern: inspect last element of event_name tuple to detect :exception suffix, force :error level"
  - "PII scrub before any log emission — forbidden keys dropped from metadata via Map.drop/2 before Logger.log/2"

requirements-completed: [TELEM-03]

coverage:
  - id: D1
    description: "attach_default_logger/0 (default opts) returns :ok and registers handler 'crosswake-default-logger'"
    requirement: TELEM-03
    verification:
      - kind: unit
        ref: "test/crosswake/telemetry_test.exs#attach_default_logger/0 (default opts) returns :ok and registers the crosswake-default-logger handler"
        status: pass
    human_judgment: false
  - id: D2
    description: "Double attach_default_logger returns {:error, :already_exists} (relies on :telemetry built-in guard, no custom guard — D-13)"
    requirement: TELEM-03
    verification:
      - kind: unit
        ref: "test/crosswake/telemetry_test.exs#a second attach_default_logger call returns {:error, :already_exists}"
        status: pass
    human_judgment: false
  - id: D3
    description: "detach_default_logger/0 returns :ok; second call returns {:error, :not_found}"
    requirement: TELEM-03
    verification:
      - kind: unit
        ref: "test/crosswake/telemetry_test.exs#detach_default_logger/0 returns :ok; a second call returns {:error, :not_found}"
        status: pass
    human_judgment: false
  - id: D4
    description: ":exception events logged at :error even when configured level is :info (D-14 exception override)"
    requirement: TELEM-03
    verification:
      - kind: unit
        ref: "test/crosswake/telemetry_test.exs#:exception events are logged at :error level even when configured level is :info"
        status: pass
    human_judgment: false
  - id: D5
    description: "PII-safety: :access_token forbidden key is absent from log output when emitted on event metadata (D-15)"
    requirement: TELEM-03
    verification:
      - kind: unit
        ref: "test/crosswake/telemetry_test.exs#PII-safety: a forbidden metadata key (:access_token) present on an event is NOT logged"
        status: pass
    human_judgment: false
  - id: D6
    description: "Core never auto-attaches the logger (no application-start or supervision call to attach_default_logger in lib/)"
    requirement: TELEM-03
    verification:
      - kind: unit
        ref: "grep -rn attach_default_logger lib/ — only definitional references in telemetry.ex"
        status: pass
    human_judgment: false
  - id: D7
    description: "Phase 133 contract proof suite unaffected — 6/6 proof tests still GREEN"
    requirement: TELEM-03
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase133_telemetry_contract_test.exs"
        status: pass
    human_judgment: false

# Metrics
duration: 8min
completed: 2026-06-28
status: complete
---

# Phase 133 Plan 03: Default Logger Summary

**Opt-in structured logger for Crosswake.Telemetry: PII-safe (D-15), exception-level override (D-14), encode:false default — core never auto-attaches (TELEM-03)**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-28T13:04:00Z
- **Completed:** 2026-06-28T13:12:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- `attach_default_logger/1` implemented — accepts level atom or keyword opts; attaches handler `"crosswake-default-logger"` to all `:active` event start/stop/exception names via `:telemetry.attach_many/4`
- `detach_default_logger/0` implemented — delegates to `:telemetry.detach/1`; returns `:ok` or `{:error, :not_found}`
- `__handle_event__/4` (public `@doc false`) handler: forces `:error` level for `:exception` suffixed events (D-14), supports `encode: false` (structured map → Logger.metadata) and `encode: true` (JSON in message), scrubs PII via `all_forbidden_keys/0` union
- `all_forbidden_keys/0` private helper: runtime union of Threadline + Sigra + Chimeway `forbidden_metadata_keys/0` — reuses existing denylists, not duplicated (D-15)
- `normalize_opts/1` private helper: normalizes level atom shorthand or keyword opts with defaults `level: :info, encode: false`
- All 5 RED unit tests in `test/crosswake/telemetry_test.exs` turned GREEN
- Phase 133 contract proof suite (6/6) unaffected — no regressions
- `mix compile --warnings-as-errors` clean; no runtime `:telemetry` advisory (MFA ref used)
- Core never auto-attaches: acceptance grep confirms no application-start or supervision module calls `attach_default_logger`

## Task Commits

1. **Task 1: Implement attach_default_logger/1 + detach_default_logger/0** - `947bc2b` (feat)

## Files Created/Modified

- `lib/crosswake/telemetry.ex` — extended with `attach_default_logger/1`, `detach_default_logger/0`, `__handle_event__/4`, `normalize_opts/1`, `all_forbidden_keys/0`; `require Logger` added

## Decisions Made

- **MFA ref for handler:** Used `&__MODULE__.__handle_event__/4` with a `@doc false` public function instead of `&handle_event/4` (private capture) to avoid the `:telemetry` local-function performance advisory that fires at runtime when a private function is captured. The advisory is informational only but produces noise in test output.
- **D-13 no custom guard:** Double-attach returns `{:error, :already_exists}` from `:telemetry.attach_many/4` directly — no custom guard added. The error is surfaced to the caller, which is the correct behavior per D-13.
- **Logger.metadata for encode:false:** Structured event context placed in `Logger.metadata(crosswake_telemetry: context)` before `Logger.log/2` so host formatters (e.g. JSON formatters) can pick it up. This matches Oban's pattern and D-14.
- **[crosswake] prefix (D-20):** Log messages always prefixed with `[crosswake]` per the brand convention.

## Deviations from Plan

None — plan executed exactly as written. The MFA handler ref choice (public `@doc false` vs private capture) is an implementation detail within the task's action, not a deviation from intent.

## Issues Encountered

None. The implementation was straightforward once the three subsystem `forbidden_metadata_keys/0` functions were confirmed present. Compile was clean on first attempt.

## User Setup Required

None — no external service configuration required. Attachment is host-initiated only.

## Next Phase Readiness

- `attach_default_logger/1` and `detach_default_logger/0` are ready for documentation in `guides/telemetry.md` (Plan 04)
- TELEM-03 requirement is complete
- The full TELEM-01..04 suite will close at Plan 04 with the telemetry guide and mix.exs docs wiring

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced. PII scrubbing is active (D-15) and the exception-level guard is implemented (D-14). T-133-08 (PII disclosure) mitigated. T-133-09 (core auto-attach) mitigated — grep confirmed. T-133-10 (double-attach silent masking) accepted per plan — surfaced to caller. T-133-11 (log volume) mitigated — attaches only to :active event set.

---
*Phase: 133-telemetry-public-api*
*Completed: 2026-06-28*

## Self-Check: PASSED

- `lib/crosswake/telemetry.ex` exists and was modified: FOUND
- Task commit `947bc2b` exists: FOUND (git log confirmed)
- `test/crosswake/telemetry_test.exs` — 5/5 tests GREEN (verified)
- `test/crosswake/proof/phase133_telemetry_contract_test.exs` — 6/6 tests GREEN (verified)
- No auto-attach in `lib/`: grep confirmed only definitional references in `telemetry.ex`
