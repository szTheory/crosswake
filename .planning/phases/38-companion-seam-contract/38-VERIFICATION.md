---
phase: 38-companion-seam-contract
verified: 2026-05-29T21:35:00Z
status: passed
score: 9/9 must-haves verified
overrides_applied: 0
---

# Phase 38: Companion Seam Contract Verification Report

**Phase Goal:** A maintainer can define a first-party companion by implementing `Crosswake.Companion` — the shared behaviour that all companions (rulestead, rindle, sigra) build on, generalized from `Crosswake.Commerce`. Optional-dependency handling, in-tree convention, and telemetry are wired through `mix crosswake.doctor` with a fail-closed `:error` posture.
**Verified:** 2026-05-29T21:35:00Z
**Status:** PASSED
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A module can declare `@behaviour Crosswake.Companion` and is given exactly 6 callbacks with no `__using__` macro or extra boilerplate | VERIFIED | `lib/crosswake/companion.ex` has exactly 6 `@callback` declarations, no `defmacro __using__`, no `use`. SC#1 fixture compiles warning-free under `--warnings-as-errors`. |
| 2 | `Crosswake.Companion.State` is a typed struct with `@enforce_keys` and `@type t` mirroring the commerce contracts idiom | VERIFIED | `lib/crosswake/companion/state.ex`: `@enforce_keys [:companion_id, :enabled, :dependency_status, :gate_status, :kill_switch_status, :checked_at]`, `details: %{}` default last, three helper types, full `@type t`. |
| 3 | `mix.exs` declares `{:telemetry, "~> 1.0"}` as a direct runtime dependency (no `only:`, no `optional: true`) | VERIFIED | `mix.exs` line 44: `{:telemetry, "~> 1.0"}` — no scope qualifier, before `{:ex_doc, ...}`. |
| 4 | `phase_38_companion_seam_findings/0` emits an `:error` finding `companion.dependency_missing` (NOT a warning) when an enabled companion's optional dependency is absent | VERIFIED | `doctor.ex` lines 532-548: `{true, {:error, mods}}` branch emits `check(:error, "companion.dependency_missing", ...)`. SC#2 proof test asserts `finding.severity == :error` and `report.status == :error`. |
| 5 | The `[:crosswake, :companion, :validate_dependency]` telemetry span is emitted with `companion_id` metadata | VERIFIED | `doctor.ex` lines 523-530: `:telemetry.span([:crosswake, :companion, :validate_dependency], %{companion_id: companion_id, route_id: nil}, fn -> ... end)`. SC#4 test asserts `{:telemetry_stop, %{companion_id: :stub_companion, result: :ok}}` received within 1000ms. |
| 6 | `Crosswake.Commerce` is byte-for-byte untouched (D-12) | VERIFIED | `git diff --quiet lib/crosswake/commerce.ex` exits 0. |
| 7 | Hermetic proof test passes and is deterministic (`async: false` to fix shared-global-env race) | VERIFIED | `use ExUnit.Case, async: false` with comment explaining CR-01. All 4 tests pass: hermeticity self-assertion, SC#1, SC#2, SC#4. `mix test test/crosswake/proof/phase38_companion_contract_test.exs` exits 0. |
| 8 | No premature `.github/workflows/` companion CI (D-13) | VERIFIED | No companion-related file under `.github/workflows/`. Existing `phase34-proof.yml` hermetic lane picks up untagged test automatically. |
| 9 | No `lib/crosswake/companions/` directory (D-14) | VERIFIED | Directory does not exist. Convention documented in `@moduledoc` of `Crosswake.Companion` only. |

**Score:** 9/9 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/crosswake/companion.ex` | `Crosswake.Companion` behaviour with 6 `@callback` declarations (D-05) | VERIFIED | All 6 callbacks present verbatim per D-05: `companion_id/0`, `enabled?/1`, `route_gated?/2`, `kill_switch_active?/1`, `validate_dependency/0`, `report_state/0`. Alias block: `State`, `Finding`, `Target`, `RouteEntry`. Moduledoc contains `lib/crosswake/companions/<name>/` and all three telemetry event-name contracts. |
| `lib/crosswake/companion/state.ex` | Typed struct with `@enforce_keys` on 6 D-09 fields | VERIFIED | Exact `@enforce_keys` list. `details: %{}` default last. Three helper types (`dependency_status`, `gate_status`, `kill_switch_status`). `@type t` with all 7 fields typed. |
| `mix.exs` | `{:telemetry, "~> 1.0"}` direct runtime dep | VERIFIED | Line 44, no `only:`, no `optional: true`. `mix compile --warnings-as-errors` exits 0. |
| `lib/crosswake/doctor/doctor.ex` | `phase_38_companion_seam_findings/0` with fail-closed `:error` and telemetry span | VERIFIED | Private function at line 514. Reads `Application.get_env(:crosswake, :companions, [])`. Wraps `validate_dependency/0` in `:telemetry.span/3` synchronously (D-11c). Fail-closed `:error` on `{true, {:error, mods}}`. Advisory on `{false, :ok}`. Wired into `run/1` at line 130/136. |
| `test/support/stub_companion.ex` | `StubCompanion` + `BrokenCompanion` fixtures with all 6 `@behaviour Crosswake.Companion` callbacks | VERIFIED | Both modules present, `@impl true` on all 6 callbacks. `BrokenCompanion.validate_dependency/0` returns `{:error, [Crosswake.TestSupport.DeliberatelyAbsentLib]}`. `DeliberatelyAbsentLib` confirmed absent from `lib/`. |
| `test/crosswake/proof/phase38_companion_contract_test.exs` | Hermetic proof with 4 tests: hermeticity, SC#1, SC#2, SC#4 | VERIFIED | `async: false`, untagged. All 4 tests pass. SC#2 asserts `finding.code == "companion.dependency_missing"`, `severity == :error`, `details.missing_modules == [DeliberatelyAbsentLib]`, `report.status == :error`. SC#4 asserts telemetry `:stop` event with `companion_id: :stub_companion`. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `lib/crosswake/companion.ex` | `lib/crosswake/companion/state.ex` | `report_state/0` callback returns `State.t()` | WIRED | `@callback report_state() :: State.t()` confirmed in file. |
| `lib/crosswake/companion.ex` | `lib/crosswake/manifest/types.ex` | `route_gated?/2` first arg is `RouteEntry.t()` | WIRED | `@callback route_gated?(route :: RouteEntry.t(), ...)` confirmed. |
| `lib/crosswake/doctor/doctor.ex` | `Application.get_env(:crosswake, :companions, [])` | Registry read in `phase_38_companion_seam_findings/0` | WIRED | Line 515: `companions = Application.get_env(:crosswake, :companions, [])`. |
| `lib/crosswake/doctor/doctor.ex` | `:telemetry.span` | Wraps `validate_dependency/0` call | WIRED | Lines 523-530: `:telemetry.span([:crosswake, :companion, :validate_dependency], ...)`. |
| `test/crosswake/proof/phase38_companion_contract_test.exs` | `lib/crosswake/doctor/doctor.ex` | `Doctor.run` asserts `companion.dependency_missing` finding | WIRED | Lines 155-180: `Doctor.run/1` called, finding asserted with `code == "companion.dependency_missing"`. |

### Data-Flow Trace (Level 4)

Not applicable — no UI-rendering artifacts. All data flows are through Elixir behaviour callbacks and ExUnit assertions verified by the live proof test run.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase38 proof test (all 4 tests: hermeticity, SC#1, SC#2, SC#4) | `mix test test/crosswake/proof/phase38_companion_contract_test.exs` | 4 tests, 0 failures in 0.2s | PASS |
| Full hermetic lane (318 tests, 38 excluded) | `mix test --exclude requires_example_host` | 318 tests, 0 failures in 1.1s | PASS |
| Compile with warnings-as-errors (MIX_ENV=test) | `MIX_ENV=test mix compile --warnings-as-errors` | Exit 0, no output | PASS |
| Commerce seam untouched | `git diff --quiet lib/crosswake/commerce.ex` | Exit 0 | PASS |

### Probe Execution

No probe scripts declared for this phase. Behavioral spot-checks above serve as the equivalent.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| COMP-01 | 38-01 | `Crosswake.Companion` behaviour with 6 declared callbacks, generalized from commerce seam | SATISFIED | `lib/crosswake/companion.ex` defines all 6 callbacks per D-05. SC#1 fixture proves behaviour satisfiable with zero boilerplate. |
| COMP-02 | 38-02 | Enabled companion with missing optional library fails closed with explicit doctor `:error` naming the dep | SATISFIED | `phase_38_companion_seam_findings/0` emits `:error` finding `companion.dependency_missing` with `details: %{missing_modules: mods}`. SC#2 proof test asserts `report.status == :error`. |
| COMP-03 | 38-01, 38-02 | In-tree convention documented; `[:crosswake, :companion, ...]` telemetry with static event names differentiated by `companion_id` metadata | SATISFIED | `@moduledoc` names `lib/crosswake/companions/<name>/` and all three telemetry event-name contracts. Real `:validate_dependency` span emits with `companion_id` metadata; SC#4 asserts the `:stop` event. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None | — | — | — | — |

No `TBD`, `FIXME`, or `XXX` markers in any phase-modified file. No placeholder returns. No stub implementations. `DeliberatelyAbsentLib` is intentionally absent — it is the missing-dep fixture, not a stub.

### Human Verification Required

None. All success criteria (SC#1/SC#2/SC#4) are verified by automated proof tests that pass deterministically.

### Gaps Summary

No gaps. All 9 observable truths verified. All 3 requirement IDs (COMP-01, COMP-02, COMP-03) satisfied. Constraints D-12/D-13/D-14 honored. Test suite green (318 tests, 0 failures, 38 excluded). Compilation clean under `--warnings-as-errors`.

---

_Verified: 2026-05-29T21:35:00Z_
_Verifier: Claude (gsd-verifier)_
