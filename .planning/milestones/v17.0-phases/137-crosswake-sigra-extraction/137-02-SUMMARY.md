---
phase: 137-crosswake-sigra-extraction
plan: "02"
subsystem: sigra-internal
tags: [finding-boundary, auth, step-up, evaluator, ceremony, host-contract, pii-sanitize]
dependency_graph:
  requires: [137-01]
  provides: [Evaluator.deny/4 Finding output, StepUpCeremony Finding-based, host issue_intent Finding contract, Plan-01 shim removed]
  affects:
    - lib/crosswake/companions/sigra/evaluator.ex
    - lib/crosswake/companions/sigra/step_up_ceremony.ex
    - lib/crosswake/companions/sigra.ex
    - examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_plug.ex
    - examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_on_mount.ex
    - test/crosswake/proof/phase56_step_up_ceremony_test.exs
    - test/crosswake/compatibility/route_gate_test.exs
    - test/crosswake/proof/phase54_sigra_session_authority_test.exs
tech_stack:
  added: []
  patterns: [Finding-at-source sanitize, Finding boundary end-to-end, host error contract migration, shim removal]
key_files:
  created: []
  modified:
    - lib/crosswake/companions/sigra/evaluator.ex
    - lib/crosswake/companions/sigra/step_up_ceremony.ex
    - lib/crosswake/companions/sigra.ex
    - examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_plug.ex
    - examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_on_mount.ex
    - test/crosswake/proof/phase56_step_up_ceremony_test.exs
    - test/crosswake/compatibility/route_gate_test.exs
    - test/crosswake/proof/phase54_sigra_session_authority_test.exs
decisions:
  - "D-137-A realized: Evaluator.deny/4 now emits %Finding{axis: :auth} natively; Plan-01 Denial->Finding shim removed from sigra facade"
  - "T-137-05: DenialCodes.sanitize_details/1 runs once at source in deny/4 before Finding construction; @generic_message bypasses sanitize"
  - "T-137-06 preserved: issue_attrs reads finding.details['max_auth_age_seconds'] — test-guarded in phase56 fixture"
  - "T-137-07 preserved: deny/4 always populates finding.code from caller-supplied dotted code (never nil)"
  - "Open Q1 resolved: host issue_intent error contract is {:error, %Finding{axis: :auth}}; normalize_issue_result accepts it and returns {:deny, finding}"
  - "handoff.ex: no step-up ceremony changes — all Denial arms are RouteGate/SigraHandoff (non-ceremony); stay as Denial per plan Task 3"
  - "route_gate_test.exs and phase54 test updated to Finding shape (direct Evaluator assertions); RouteGate-level assertions unchanged (RouteGate still translates Finding->Denial)"
metrics:
  duration_minutes: 15
  completed_date: "2026-07-01"
  tasks_completed: 4
  tasks_total: 4
  files_modified: 8
status: complete
---

# Phase 137 Plan 02: SIGRA-Internal Finding Boundary Summary

**One-liner:** Evaluator.deny/4 emits %Finding{axis: :auth} at source with once-at-source PII sanitize; StepUpCeremony fully re-pointed to Finding; host issue_intent error contract migrated to {:error, Finding.t()}; Plan-01 Denial->Finding shim removed; core suite green.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Evaluator.deny/4 emits %Finding{axis: :auth}; sanitize at source; drop Denial alias | 0c58cae | evaluator.ex, phase54_sigra_session_authority_test.exs |
| 2 | StepUpCeremony on Finding — re-point match, normalize_issue_result, max_auth_age_seconds guard | 0214b09 | step_up_ceremony.ex |
| 3 | Migrate host issue_intent error contract to Finding; remove Plan-01 facade shim | 505ec3e | step_up_plug.ex, step_up_on_mount.ex, sigra.ex |
| 4 | Update phase56, route_gate_test, phase73 fixtures to the Finding shape | 7156998 | phase56_step_up_ceremony_test.exs, route_gate_test.exs |

## What Was Built

### Task 1: Evaluator.deny/4 → %Finding{axis: :auth}

Changed `deny/4` in `evaluator.ex` to emit `%Finding{axis: :auth, code: code, message: @generic_message, route_id: route.id, details: sanitized}` instead of `Denial.new(reason: :step_up_required, ...)`.

Key invariants preserved:
- **T-137-05 PII guard:** `DenialCodes.sanitize_details/1` runs once at source — the existing sanitize pipeline (Map.put_new :evaluated_at, maybe_put_ref :challenge_ref/:step_up_token_ref, then sanitize) is preserved exactly.
- **T-137-07 code guard:** `finding.code` is always the caller-supplied dotted code string (never nil) — prevents silent downgrade to `Atom.to_string(reason)` at the `finding_to_denial/2` boundary.
- **T-137-05 message guard:** `@generic_message` constant flows directly into `Finding.message` without going through sanitize — no raw PII in message field.

Replaced `alias Crosswake.Shell.Denial` with `alias Crosswake.Compatibility.Finding`. Updated `@spec evaluate_route_auth` return type to `{:deny, Finding.t()}`.

Updated `phase54_sigra_session_authority_test.exs` fixture to assert `%Finding{axis: :auth}` shape instead of `denial.reason == :step_up_required`.

### Task 2: StepUpCeremony fully Finding-based

Migrated all Denial references from `step_up_ceremony.ex`:
- Semantic match re-pointed: `{:deny, %Denial{reason: :step_up_required, code: code}}` → `{:deny, %Finding{axis: :auth, code: code}}`
- Catch-all deny arm: `%Denial{}` → `%Finding{axis: :auth}`
- `issue_challenge/4`: param renamed `denial` → `finding`
- `normalize_issue_result/1`: host-error arm changed from `{:error, %Denial{} = denial}` to `{:error, %Finding{axis: :auth} = finding}`, returning `{:deny, finding}` — resolves Open Question 1
- `normalize_issue_result/1`: fallback constructs `%Finding{axis: :auth, code: "auth.step_up_intent.projection_failed", message: @generic_or_existing_message, details: %{}}` instead of `Denial.new(...)`
- `issue_attrs/4`: param `%Denial{} = denial` → `%Finding{axis: :auth} = finding`; `Map.get(finding.details, "max_auth_age_seconds")` preserved (T-137-06: dropping this silently removes the step-up max-age Elevation of Privilege guard); `route_denial_code: finding.code`

Removed `alias Crosswake.Shell.Denial`; added `alias Crosswake.Compatibility.Finding`. Updated `@spec evaluate_or_issue` return type to `{:deny, Finding.t()}`.

### Task 3: Host contract migration + shim removal

**step_up_plug.ex / step_up_on_mount.ex:**
- Post-ceremony deny arm: `{:deny, %Denial{}}` → `{:deny, %Finding{axis: :auth}}`
- `denied_path/1`: accepts `%Finding{axis: :auth}` and extracts `finding.code` for the redirect URL
- `issue_intent/1`: added `else` clause converting `{:error, %Denial{}}` from `StepUp.issue/challenge/to_contract_intent` to `{:error, %Finding{axis: :auth}}` (matching the new `normalize_issue_result` host contract)
- `alias Crosswake.Shell.Denial` kept (still used in the else clause to match Denial from StepUp)
- `alias Crosswake.Compatibility.Finding` added

**handoff.ex:** No changes — its `%Denial{}` arms are all from RouteGate evaluate (which returns `%{denial: %Denial{}}`) and `SigraHandoff` flows — not part of the step-up ceremony path. These stay as Denial per plan guidance.

**sigra.ex:** Removed the Plan-01 Denial→Finding shim. The `evaluate_auth/3` deny arm now simply passes the Finding through unchanged (`{:deny, finding} -> {:deny, finding}`). Removed the now-unused `alias Crosswake.Compatibility.Finding`.

### Task 4: Test fixture migration

**phase56_step_up_ceremony_test.exs:**
- `evaluator_result: {:deny, Denial.new(...)}` fixtures migrated to `{:deny, %Finding{axis: :auth, ...}}` for both challengeable (insufficient_assurance, stale_auth) and non-challengeable (revoked) arms
- `host_denial` fixture migrated from `Denial.new(...)` to `%Finding{axis: :auth, ...}`; `{:deny, ^host_denial}` pin assertion preserved (Finding passthrough)
- `alias Crosswake.Compatibility.Finding` added; `alias Crosswake.Shell.Denial` kept (still used in direct Denial behavior tests: "step-up intent denials keep the existing public step-up shell reason", etc.)

**test/crosswake/compatibility/route_gate_test.exs:**
- Two tests that called `Evaluator.evaluate_route_auth` directly and checked `denial.reason == :step_up_required` updated to assert `%Finding{axis: :auth}` pattern and `finding.code`
- RouteGate-level assertions (via `RouteGate.evaluate`) unchanged — RouteGate still returns `%{denial: %Denial{}}` after translating via `finding_to_denial/2`
- `alias Crosswake.Compatibility.Finding` added

**phase73_auth_sensitive_admin_workflow_proof_test.exs:** No changes needed — uses `StepUpCeremony.evaluate_or_issue` with real evaluator (not `evaluator_result:` fixture), and all assertions go through `RouteGate.evaluate` which still returns Denial. Already passing.

## Verification Results

| Check | Result |
|-------|--------|
| `mix compile --warnings-as-errors` (core) | PASS |
| `cd examples/phoenix_host && mix compile --warnings-as-errors` | PASS |
| `grep -c "Crosswake.Shell.Denial" evaluator.ex` | 0 (PASS) |
| `grep -c "Crosswake.Shell.Denial" step_up_ceremony.ex` | 0 (PASS) |
| `mix test test/crosswake/proof/phase54_sigra_session_authority_test.exs` | PASS — 7 tests, 0 failures |
| `mix test test/crosswake/proof/phase56_step_up_ceremony_test.exs --exclude requires_example_host` | PASS — 10 tests, 0 failures (1 excluded) |
| `mix test test/crosswake/proof/phase73_auth_sensitive_admin_workflow_proof_test.exs --exclude requires_example_host` | PASS — 10 tests, 0 failures |
| `mix test --exclude requires_example_host --exclude engine_present` | PASS — 1165 tests, 0 failures (61 excluded) |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] phase54_sigra_session_authority_test.exs fixture checking `denial.reason`**

- **Found during:** Task 1 verification
- **Issue:** `phase54_sigra_session_authority_test.exs` L156 called `Evaluator.evaluate_route_auth` and asserted `denial.reason == :step_up_required` — a `Denial` struct field. After Task 1 flipped the Evaluator to return `Finding`, this test failed with `KeyError: key :reason not found in %Finding{}`.
- **Fix:** Updated assertion to `%Finding{axis: :auth} = finding` pattern match and `finding.code` check (plan says phase54 tests should "Evaluator.evaluate_route_auth/3 returns {:deny, %Finding{axis: :auth}}").
- **Files modified:** test/crosswake/proof/phase54_sigra_session_authority_test.exs
- **Commit:** 0c58cae

**2. [Rule 1 - Bug] route_gate_test.exs fixtures checking `denial.reason` on direct Evaluator calls**

- **Found during:** Task 4 — full suite run
- **Issue:** Two tests in `route_gate_test.exs` called `Evaluator.evaluate_route_auth` directly and checked `.reason == :step_up_required`. After Task 1, the Evaluator returns Finding (not Denial), causing `KeyError: key :reason not found in %Finding{}`.
- **Fix:** Updated both test assertions to `%Finding{axis: :auth}` pattern match and `.code` checks. Added `alias Crosswake.Compatibility.Finding`.
- **Files modified:** test/crosswake/compatibility/route_gate_test.exs
- **Commit:** 7156998

None of the production code paths were incorrectly broken — only direct-Evaluator test assertions that assumed Denial shape needed updating.

## Known Stubs

None — all Finding fields populated, all ceremony paths wired.

## Threat Flags

No new network endpoints, auth paths, file access patterns, or schema changes beyond those in the plan's threat model. All four threat mitigations (T-137-05, T-137-06, T-137-07, T-137-08) implemented and test-verified.

## Self-Check

### Modified files exist

- `/Users/jon/projects/crosswake/lib/crosswake/companions/sigra/evaluator.ex` — FOUND
- `/Users/jon/projects/crosswake/lib/crosswake/companions/sigra/step_up_ceremony.ex` — FOUND
- `/Users/jon/projects/crosswake/lib/crosswake/companions/sigra.ex` — FOUND
- `/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_plug.ex` — FOUND
- `/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_on_mount.ex` — FOUND
- `/Users/jon/projects/crosswake/test/crosswake/proof/phase56_step_up_ceremony_test.exs` — FOUND
- `/Users/jon/projects/crosswake/test/crosswake/compatibility/route_gate_test.exs` — FOUND
- `/Users/jon/projects/crosswake/test/crosswake/proof/phase54_sigra_session_authority_test.exs` — FOUND

### Commits exist

- 0c58cae — FOUND (Task 1: Evaluator + phase54 fixture)
- 0214b09 — FOUND (Task 2: StepUpCeremony)
- 505ec3e — FOUND (Task 3: host contract + shim removal)
- 7156998 — FOUND (Task 4: phase56 + route_gate_test fixtures)

## Self-Check: PASSED
