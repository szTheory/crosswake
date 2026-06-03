---
phase: 40-runtime-gate-evaluation-and-fail-closed-denial
plan: "01"
subsystem: companion-gate
tags: [gate, kill-switch, denial, route-gate, telemetry, openfeature]
requires: [phase-38-companion-contract, phase-39-route-policy-gating-dsl]
provides: [gate-denied-denial, kill-switch-active-denial, route-gate-telemetry]
affects: [RouteGate.evaluate/4, Shell.Denial, Decision.transition]
tech-stack:
  added: []
  patterns: [telemetry-span-keathley, openfeature-reason-strings, fail-closed-and-semantics]
key-files:
  created:
    - test/crosswake/proof/phase40_gate_evaluation_test.exs
  modified:
    - lib/crosswake/shell/denial.ex
    - lib/crosswake/compatibility/route_gate.ex
    - test/crosswake/doctor/doctor_test.exs
decisions:
  - ":gate_denied and :kill_switch_active bypass finding_to_denial/2 — produced as Denial.t() directly in RouteGate (flag_key/evaluated_at are RouteGate-scoped)"
  - "transition_for/2 promoted to /3 taking (status, route, opts) so {:fallback_phoenix, id} on_unavailable maps to {:redirect, id} transition"
  - "Gate denials prepend ahead of compatibility denials in the denials list (fail-closed AND-semantics)"
  - "doctor_test denial_reasons snapshot updated to include :gate_denied and :kill_switch_active (additive, correct)"
requirements-completed: [GATE-03, GATE-04]
metrics:
  duration: "362s"
  completed: "2026-05-30"
  tasks_completed: 3
  files_changed: 4
---

# Phase 40 Plan 01: Runtime Gate Evaluation and Fail-Closed Denial Summary

Wire `kill_switch_active?/1` and `route_gated?/2` companion callbacks into `RouteGate.evaluate/4` producing structured `:gate_denied` / `:kill_switch_active` denials with kill-switch short-circuit and OpenFeature-shaped explainability details, satisfying GATE-03 and GATE-04.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 (RED) | Write failing hermetic proof for SC#1-4 | 1c7be8e | test/crosswake/proof/phase40_gate_evaluation_test.exs |
| 2 (feat) | Add :gate_denied and :kill_switch_active to Shell.Denial | d2fa897 | lib/crosswake/shell/denial.ex |
| 3 (GREEN) | Wire gate + kill-switch evaluation into RouteGate.evaluate/4 | b1bb459 | lib/crosswake/compatibility/route_gate.ex, test/crosswake/proof/phase40_gate_evaluation_test.exs, test/crosswake/doctor/doctor_test.exs |

## Verification Results

- `mix test test/crosswake/proof/phase40_gate_evaluation_test.exs` — 6 tests, 0 failures (SC#1-4 all GREEN)
- `mix test --exclude requires_example_host` — 356 tests, 0 failures (38 excluded) — no regression
- `mix compile --warnings-as-errors` — passes cleanly

## Success Criteria

- [x] SC#1 (GATE-03): `:gate_denied` denial carries `flag_key` ("test_flag"), `reason` ("DISABLED"), `variant` ("off"), `evaluated_at` (ISO8601 string) — all present and non-nil
- [x] SC#2 (GATE-04): kill switch produces `:kill_switch_active` and short-circuits — `route_gated?/2` never called (Process spy asserts `nil`)
- [x] SC#3a: `on_unavailable: :deny` → `transition :halt`
- [x] SC#3b: `on_unavailable: {:fallback_phoenix, :home}` → `transition {:redirect, :home}`
- [x] SC#3c: Non-gated route with registered companion — gate/kill-switch logic not invoked
- [x] SC#4: No network call in evaluation path — pure over manifest + registered companion modules (hermeticity self-assertion)
- [x] `Shell.Denial.reasons/0` includes `:gate_denied` and `:kill_switch_active`
- [x] `Decision.transition` typespec includes `{:redirect, atom()}`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated doctor_test denial_reasons snapshot**
- **Found during:** Task 3 full suite run
- **Issue:** `Crosswake.DoctorTest` had a hardcoded list of denial reason strings that excluded `:gate_denied` and `:kill_switch_active`. Adding these to `Shell.Denial.@reasons` caused the doctor report to include them, breaking the assertion.
- **Fix:** Added `"gate_denied"` and `"kill_switch_active"` to the expected list in `doctor_test.exs`
- **Files modified:** `test/crosswake/doctor/doctor_test.exs`
- **Commit:** b1bb459

### Implementation Note

**Gate denials bypass `finding_to_denial/2`:** The plan correctly specified Option A (produce `Denial.t()` directly). The initial attempt threaded gate denials through the findings pipeline, which failed because `finding_to_denial/2` only accepts `Finding.t()` structs. Fixed by accumulating gate denials in a separate list (`gate_denials`) that prepends to `compatibility_denials` before building the `Decision`.

## Known Stubs

None.

## Threat Flags

None. No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced. All inputs are developer-controlled compile/config data per the threat model (T-40-SC: zero new dependencies).

## Self-Check: PASSED
