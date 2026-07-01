---
phase: 137-crosswake-sigra-extraction
plan: "01"
subsystem: compatibility
tags: [finding-boundary, auth, route-gate, companion-contract]
dependency_graph:
  requires: []
  provides: [Finding.:code/:details fields, :auth clause in finding_to_denial/2, evaluate_auth/3 Finding.t() contract, RouteGate Finding→Denial translation, StubSigraAbsentCompanion]
  affects: [lib/crosswake/compatibility/compatibility.ex, lib/crosswake/compatibility/route_gate.ex, lib/crosswake/companion.ex, lib/crosswake/companions/sigra.ex, test/support/stub_companion.ex, test/crosswake/compatibility/compatibility_test.exs]
tech_stack:
  added: []
  patterns: [Finding boundary refactor, fail-closed auth gate, shim pattern for backward compatibility]
key_files:
  created: []
  modified:
    - lib/crosswake/compatibility/compatibility.ex
    - lib/crosswake/compatibility/route_gate.ex
    - lib/crosswake/companion.ex
    - lib/crosswake/companions/sigra.ex
    - test/support/stub_companion.ex
    - test/crosswake/compatibility/compatibility_test.exs
decisions:
  - "D-137-A: evaluate_auth/3 callback returns {:deny, Finding.t()}; RouteGate owns Finding→Denial translation via finding_to_denial/2"
  - "D-137-B: :auth clause in finding_to_denial/2 returns :step_up_required; base_details/merge block guarded with cond so :auth passes details UNMERGED (audit fix ①)"
  - "D-137-D: StubSigraAbsentCompanion with auth_authority?/0 == false drives :dependency_missing fail-closed path"
  - "Shim approach chosen for sigra facade: converts returned Denial to %Finding{axis: :auth} so callback contract holds this wave; Plan 02 removes shim"
metrics:
  duration_minutes: 4
  completed_date: "2026-07-01"
  tasks_completed: 3
  tasks_total: 3
  files_modified: 6
status: complete
---

# Phase 137 Plan 01: D-4 Finding Boundary Core Side Summary

**One-liner:** Finding struct gains :code/:details auth fields, :auth clause in finding_to_denial/2 passes details UNMERGED, evaluate_auth/3 callback returns Finding.t() with RouteGate owning translation, and StubSigraAbsentCompanion added for fail-closed proof.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add Finding :code/:details fields, :auth translation clause, and guard base_details merge | cc87362 | compatibility.ex, compatibility_test.exs |
| 2 | Flip evaluate_auth/3 callback to Finding.t() and translate Finding→Denial in RouteGate | 4381202 | companion.ex, route_gate.ex, sigra.ex |
| 3 | Add StubSigraAbsentCompanion for the engine-absent fail-closed proof | 26722cb | stub_companion.ex |

## What Was Built

### Task 1: Finding struct + :auth clause + base_details guard

Added two OPTIONAL fields to `Crosswake.Compatibility.Finding`:
- `:code` (String.t() | nil, default nil) — auth sub-classification string
- `:details` (map(), default `%{}`) — already-sanitized structured evidence

Added `:auth` clause to `finding_to_denial/2` (before the catch-all `axis ->`) returning `{:step_up_required, finding.code, %{}, finding.details}`. The empty recovery map (`%{}`) signals that the host owns ceremony routing.

Replaced the unconditional `if finding.axis == :pack_version` guard on the base_details/merge block with a `cond` expression:
- `:auth` arm — passes `details` through UNMERGED (audit fix ①): `base_details/1` injects `:axis` for all axes and `:auth` is not in the sigra allowlist
- `:pack_version and current_route_id` arm — existing pack_details pass-through preserved
- `true` arm — `Map.merge(base_details(finding), details)` for all other axes (unchanged)

Three new behavior tests added to `compatibility_test.exs`:
- `:auth Finding` with populated code → `:step_up_required` with details UNMERGED and no `:axis` key
- `:auth Finding` with nil code → falls back to `"step_up_required"` string (documented T-137-03)
- Non-auth Finding with new struct still builds (additive, non-breaking)

### Task 2: Callback contract + RouteGate translation

Changed `Companion.evaluate_auth/3` `@callback` return type from `{:deny, Crosswake.Shell.Denial.t()}` to `{:deny, Finding.t()}` and updated the `@doc` prose to explain that core translates the Finding to a Denial at the RouteGate boundary (D-137-A).

Changed `RouteGate.prepend_auth_evaluation_denials/4` accumulation `case` to pattern-match on the deny arm:
- `{:deny, %Finding{} = finding}` → calls `Compatibility.finding_to_denial(finding, route_id: route.id)` before prepending (D-137-A)
- `{:deny, %Denial{} = denial}` → pass-through for the try/rescue fail-closed path (which still constructs Denial directly)

Added a Phase 137 shim to the sigra facade `evaluate_auth/3`: when the Evaluator returns `{:deny, denial}`, the facade wraps it into `%Finding{axis: :auth, message: denial.message, code: denial.code, details: denial.details, hint: denial.hint, route_id: denial.route_id}` before returning `{:deny, finding}`. This satisfies the new callback contract end-to-end this wave. Plan 02 removes the shim when `Evaluator.deny/4` emits Finding natively.

### Task 3: StubSigraAbsentCompanion

Added `Crosswake.TestSupport.StubSigraAbsentCompanion` to `test/support/stub_companion.ex` beside the existing rulestead/rindle absent stubs, mirroring their structure exactly:
- `companion_id/0` → `:sigra`
- `enabled?/1` → reads `Map.get(config, :enabled, false)` (disabled by default — absent companion)
- `validate_dependency/0` → `{:error, [Crosswake.Companions.Sigra]}` (models post-extraction state)
- `report_state/0` → `dependency_status: {:missing, [Crosswake.Companions.Sigra]}`, gate/kill-switch `:unconfigured`
- `auth_authority?/0` → `false` (optional callback, @impl true — engine absent = no authority)

The `false` auth_authority ensures that when this stub is registered as the sole companion on an auth-predicated route, RouteGate finds no authority and emits `:dependency_missing` (fail-closed).

## Verification Results

| Check | Result |
|-------|--------|
| `mix compile --warnings-as-errors` | PASS |
| `mix test test/crosswake/compatibility/compatibility_test.exs` | PASS — 15 tests, 0 failures (12 existing + 3 new) |
| `mix test test/crosswake/proof/phase46_sigra_auth_contract_test.exs` | PASS — 9 tests, 0 failures |
| `mix test --exclude requires_example_host --exclude engine_present` | PASS — 1165 tests, 0 failures (61 excluded) |

## Deviations from Plan

### Auto-added

**1. [Rule 2 - Missing critical functionality] RouteGate rescue path pass-through for Denial**

- **Found during:** Task 2 implementation
- **Issue:** The `try/rescue` block in `prepend_auth_evaluation_denials/4` constructs a `Denial` directly on error. After changing the `case result do` deny arm to pattern-match `%Finding{}`, the rescue-path Denial would be unmatched.
- **Fix:** Added a second `{:deny, %Denial{} = denial}` arm to the case that passes the pre-built Denial through unchanged. This ensures the fail-closed rescue path is never double-wrapped.
- **Files modified:** lib/crosswake/compatibility/route_gate.ex
- **Commit:** 4381202

None — plan executed with one auto-add to ensure the rescue path remains correct.

## Known Stubs

None — no placeholder text, hardcoded empty values, or components without data sources wired. The D-137-A shim in `sigra.ex` is intentional (documented in code and plan) and will be removed in Plan 02.

## Threat Flags

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries beyond those already in the plan's threat model.

## Self-Check

### Created files exist

- `test/support/stub_companion.ex` — already existed, modified in place (FOUND)

### Modified files exist

- `/Users/jon/projects/crosswake/lib/crosswake/compatibility/compatibility.ex` — FOUND
- `/Users/jon/projects/crosswake/lib/crosswake/compatibility/route_gate.ex` — FOUND
- `/Users/jon/projects/crosswake/lib/crosswake/companion.ex` — FOUND
- `/Users/jon/projects/crosswake/lib/crosswake/companions/sigra.ex` — FOUND
- `/Users/jon/projects/crosswake/test/support/stub_companion.ex` — FOUND
- `/Users/jon/projects/crosswake/test/crosswake/compatibility/compatibility_test.exs` — FOUND

### Commits exist

- cc87362 — FOUND (Task 1)
- 4381202 — FOUND (Task 2)
- 26722cb — FOUND (Task 3)

## Self-Check: PASSED
