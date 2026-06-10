---
phase: 95-operator-surface
plan: "05"
subsystem: doctor
tags: [doctor, threadline, fail-closed, audit-ledger, pii-safety, tdd]
dependency_graph:
  requires: []
  provides: [fail-closed-schema-guard, string-schema-regression-test]
  affects: [lib/crosswake/doctor/doctor.ex, test/crosswake/doctor/doctor_test.exs]
tech_stack:
  added: []
  patterns: [is_atom+not_is_nil guard before Code.ensure_loaded?, TDD RED/GREEN]
key_files:
  created: []
  modified:
    - lib/crosswake/doctor/doctor.ex
    - test/crosswake/doctor/doctor_test.exs
decisions:
  - "Guard call-site only (phase_95_threadline_findings/2), not ledger_schema/1 — aligns with the prescribed single-line fix; ledger_schema/1 correctly returns whatever the config provides, the caller must type-check"
  - "is_atom(schema) and not is_nil(schema) — both guards required because is_atom(nil) returns true in Elixir"
  - "Removed leftover IO.inspect debug call from doctor_test.exs:184 (trivially safe, asserted value was report.status == :ok, unaffected by IO.inspect return)"
metrics:
  duration: ~5 minutes
  completed: "2026-06-10"
  tasks_completed: 1
  files_modified: 2
  commits: 2
requirements_satisfied: [OPER-02]
---

# Phase 95 Plan 05: Fail-Closed Doctor Guard (String :schema) Summary

One-liner: `is_atom + not is_nil` guard before `Code.ensure_loaded?/1` closes the last OPER-02 BLOCKER — doctor returns a report on string `:schema` map configs instead of crashing.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 (RED) | Add failing test for string :schema crashing doctor | 3400248 | test/crosswake/doctor/doctor_test.exs |
| 1 (GREEN) | Guard Code.ensure_loaded? against non-atom :schema | 5cb0d49 | lib/crosswake/doctor/doctor.ex, test/crosswake/doctor/doctor_test.exs |

## What Was Built

A single-line guard fix in `phase_95_threadline_findings/2` in `lib/crosswake/doctor/doctor.ex`:

**Before:**
```elixir
if schema && Code.ensure_loaded?(schema) do
```

**After:**
```elixir
if is_atom(schema) and not is_nil(schema) and Code.ensure_loaded?(schema) do
```

The `schema &&` truthiness check passed non-nil strings, which caused `Code.ensure_loaded?/1` to raise `FunctionClauseError` (it requires an atom). The classic `config/runtime.exs + System.get_env` pattern produces string module names (e.g. `%{schema: "MyApp.Audit.Ledger"}`), so this crash was a real-world production risk.

A CR-05 regression test was added to `test/crosswake/doctor/doctor_test.exs` at line 1436: "does not crash on string :schema value in map config". It uses `Application.put_env(:crosswake, :audit_ledger, %{schema: "MyApp.Audit.Ledger"})` and asserts `report != nil`.

Additionally, the leftover `IO.inspect(...)` debug call at line 184 was removed (safe — not affecting the assertion on `report.status`).

## TDD Gate Compliance

- RED: `test(95-05):` commit `3400248` — test added and confirmed failing with `FunctionClauseError`
- GREEN: `fix(95-05):` commit `5cb0d49` — guard fix applied; new test passes; existing canonical bare-atom test (line 1395) and CR-04 keyword test (line 1418) still pass

## Verification Results

```
37 tests, 2 failures
```

The 2 failures are the pre-existing version-literal assertions at lines 94/199 (out of scope). No new failures introduced. The new string-schema test passes. All prior threadline doctor tests pass.

Acceptance criteria verified:
- `grep -n "is_atom(schema) and not is_nil(schema) and Code.ensure_loaded?"` → match at line 896
- `grep -F 'if schema && Code.ensure_loaded?(schema)'` → no match (old guard gone)
- `grep -n "MyApp.Audit.Ledger"` → match at lines 1397 and 1439
- Git: RED commit `3400248` + GREEN commit `5cb0d49` both present

## Deviations from Plan

**1. [Rule 2 - Minor cleanup] Removed IO.inspect debug call from doctor_test.exs:184**
- **Found during:** GREEN verification
- **Issue:** `IO.inspect(Enum.filter(report.findings, & &1.severity == :error))` was a leftover debug fused with `;` before `assert report.status == :ok`
- **Fix:** Removed the IO.inspect call; assert is unchanged and still evaluates `report.status`
- **Files modified:** test/crosswake/doctor/doctor_test.exs
- **Commit:** 5cb0d49 (included in GREEN commit)

## Known Stubs

None — the guard is a complete, functional implementation. No placeholder values or TODO markers.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. The change is narrowly scoped to a call-site guard check within the existing `phase_95_threadline_findings/2` function. No new threat surface.

## Self-Check: PASSED
