---
phase: 40-runtime-gate-evaluation-and-fail-closed-denial
verified: 2026-05-30T09:09:00Z
status: passed
score: 8/8 must-haves verified
overrides_applied: 0
---

# Phase 40: Runtime Gate Evaluation and Fail-Closed Denial — Verification Report

**Phase Goal:** Route activation for a gated route fails closed by default — producing a structured, explainable denial — and kill switches short-circuit all other gate checks ahead of the standard evaluation path.
**Verified:** 2026-05-30T09:09:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A gated route with an active flag (no companion denies, no kill switch) activates normally (transition :activate) | VERIFIED | `transition_for(:allow, _route, _opts) -> :activate` in route_gate.ex line 61; SC#3c test registers KillSwitchCompanion with a non-gated route and confirms gate logic not invoked |
| 2 | When a companion returns {:deny, finding}, RouteGate.evaluate/4 produces :gate_denied denial with flag_key, reason, variant, evaluated_at all present and non-nil (D-03) | VERIFIED | `check_gate/3` builds `Denial.new(reason: :gate_denied, details: %{"flag_key" => ..., "reason" => "DISABLED", "variant" => "off", "evaluated_at" => ISO8601})` at lines 148-162; SC#1 test passes with all four assertions |
| 3 | When a companion returns true from kill_switch_active?/1, RouteGate produces :kill_switch_active denial and route_gated?/2 is never called (D-10, D-11) | VERIFIED | `check_kill_switches/3` uses `Enum.reduce_while` with `{:halt, ...}` on first true return; SC#2 test asserts `Process.get(:route_gated_called) == nil` and `Process.get(:kill_switch_active_called) == true` — 0 failures |
| 4 | A denied gated route with on_unavailable: :deny yields transition :halt; with on_unavailable: {:fallback_phoenix, :home} yields transition {:redirect, :home} (D-01) | VERIFIED | `transition_for/3` at lines 61-73: `:fallback_phoenix` clause before general deny clause; SC#3a and SC#3b tests pass |
| 5 | Non-gated routes (gated_by == nil) skip both kill-switch and gate evaluation entirely (D-11) | VERIFIED | `prepend_gate_evaluation_findings/3` clause `(%RouteEntry{gated_by: nil}, _target) -> acc` at line 84; SC#3c test asserts both Process spy keys remain nil |
| 6 | RouteGate.evaluate/4 makes no network call — all inputs are compiled manifest, target, and registered companion modules (SC#4) | VERIFIED | Hermeticity self-assertion in test refutes example-host router reference and `Code.require_file`; gate evaluation is pure over manifest + Application.get_env; test passes |
| 7 | RouteGate iterates ALL enabled companions for both kill-switch and gate checks; a companion returning false/pass abstains without opening the route (D-09) | VERIFIED | `prepend_gate_evaluation_findings/3` filters by `companion.enabled?/1`, then passes full list to `check_kill_switches/3` and `check_gate/3` both using `Enum.reduce_while`; :pass returns `{:cont, :pass}` |
| 8 | Hermetic proof test covers SC#1-4: :gate_denied details with all four fields, kill_switch short-circuit spy, on_unavailable transition variants, and network-free hermeticity assertion (D-14) | VERIFIED | `test/crosswake/proof/phase40_gate_evaluation_test.exs` — 6 tests, 0 failures; `async: false`, no `@tag` annotations |

**Score:** 8/8 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/crosswake/shell/denial.ex` | `:gate_denied` and `:kill_switch_active` in @reasons and reason typespec | VERIFIED | Both atoms appear 2 times each (in `@reasons` list and `@type reason` union); `Denial.reasons/0` returns them at runtime confirmed |
| `lib/crosswake/compatibility/route_gate.ex` | kill-switch short-circuit + gate evaluation steps wired into evaluate/4; transition_for reads on_unavailable | VERIFIED | `prepend_gate_evaluation_findings/3` present; `check_kill_switches/3` and `check_gate/3` private helpers; `transition_for/3` (arity 3) called at line 57 |
| `test/crosswake/proof/phase40_gate_evaluation_test.exs` | Hermetic proof covering SC#1-4 | VERIFIED | Module `Crosswake.Proof.Phase40GateEvaluationTest` exists; `async: false`; 6 tests, 0 failures |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `route_gate.ex` | `Application.get_env(:crosswake, :companions, [])` | companion registry read at evaluation time | VERIFIED | Line 89: `Application.get_env(:crosswake, :companions, [])` in `prepend_gate_evaluation_findings/3` |
| `route_gate.ex` | `Crosswake.Shell.Denial.new/1` | direct :gate_denied / :kill_switch_active denial construction | VERIFIED | `Denial.new(reason: :kill_switch_active, ...)` at line 121; `Denial.new(reason: :gate_denied, ...)` at line 149 |
| `route_gate.ex` | `:telemetry.span/3` | wrapping each companion callback | VERIFIED | `:telemetry.span([:crosswake, :companion, :kill_switch], ...)` line 111; `:telemetry.span([:crosswake, :companion, :route_gate], ...)` line 139 |

### Data-Flow Trace (Level 4)

Not applicable — this phase produces decision structs and denial values from pure in-memory computation (no rendering, no DB, no external service). Gate evaluation is a pure function over compiled manifest + companion modules; SC#4 self-asserts no network dependency.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| SC#1-4 hermetic proof | `mix test test/crosswake/proof/phase40_gate_evaluation_test.exs` | 6 tests, 0 failures | PASS |
| Full suite non-regression | `mix test --exclude requires_example_host` | 356 tests, 0 failures (38 excluded) | PASS |
| Compile clean | `mix compile --warnings-as-errors` | exits 0, no output | PASS |
| `Denial.reasons/0` runtime includes new atoms | `mix run -e 'true = :gate_denied in ... and :kill_switch_active in ...'` | exits 0 | PASS |

### Probe Execution

No probe scripts declared or present for this phase. Step 7c: SKIPPED (no `scripts/*/tests/probe-*.sh` for phase 40).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| GATE-03 | 40-01-PLAN.md | When a gate denies, route activation fails closed with a structured `:gate_denied` denial carrying an explainable, OpenFeature-shaped reason (`flag_key`, `reason`, `variant`, `evaluated_at`) | SATISFIED | `check_gate/3` in route_gate.ex builds denial with all four fields; SC#1 asserts all four present, non-nil, and correctly shaped; 356-test suite green |
| GATE-04 | 40-01-PLAN.md | Kill switches short-circuit ahead of all other gating and always fail closed (`:kill_switch_active`); the only fail-open path is an explicit `on_unavailable: :fallback_phoenix` | SATISFIED | `check_kill_switches/3` uses `Enum.reduce_while` with early halt; SC#2 asserts `route_gated?/2` never called; SC#3b confirms `{:fallback_phoenix, :home}` maps to `{:redirect, :home}`; no other fail-open path exists |

Both GATE-03 and GATE-04 status in REQUIREMENTS.md is listed as "Pending" (not yet updated post-phase), but implementation evidence fully satisfies both.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | — | — | No debt markers (TBD/FIXME/XXX), no stubs, no placeholder returns found in any modified file |

### Human Verification Required

None. All success criteria are programmatically verifiable (structured data shapes, transition values, process spy assertions, telemetry event names). The hermeticity self-assertion runs in-process.

### Gaps Summary

No gaps. All 8 must-have truths verified, all 3 artifacts substantive and wired, all 3 key links confirmed, both requirement IDs fully satisfied, full test suite green (356 tests, 0 failures), compile clean.

---

_Verified: 2026-05-30T09:09:00Z_
_Verifier: Claude (gsd-verifier)_
