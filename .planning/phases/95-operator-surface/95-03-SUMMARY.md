---
phase: 95-operator-surface
plan: "03"
subsystem: doctor
tags: [doctor, threadline, pii-safety, fail-closed, audit-ledger, bug-fix]
requirements: [OPER-02]

dependency_graph:
  requires:
    - "95-01 (doctor threadline infrastructure — check_ledger_schema, check_pii_fields, @canonical_ledger_columns)"
  provides:
    - "ledger_schema/1 normalization helper for all :audit_ledger config shapes"
    - "Correct fail-closed PII check that does not false-positive on canonical :actor_ref"
  affects:
    - "lib/crosswake/doctor/doctor.ex"
    - "test/crosswake/doctor/doctor_test.exs"

tech_stack:
  added: []
  patterns:
    - "Elixir function-head dispatch for config normalization (nil / keyword / map / bare-atom)"
    - "MapSet.difference to subtract canonical columns from forbidden set before intersection"

key_files:
  created: []
  modified:
    - "lib/crosswake/doctor/doctor.ex — ledger_schema/1 helper, rewritten schema_findings block, CR-01 MapSet.difference fix"
    - "test/crosswake/doctor/doctor_test.exs — CanonicalLedgerSchema fixture, 2 new tests, strengthened PII test, env save/restore"

decisions:
  - "Use multi-clause function dispatch for ledger_schema/1 (nil / is_list / is_map / is_atom bare module) rather than a single case — cleaner guard semantics and avoids is_atom(nil)==true trap"
  - "Subtract @canonical_ledger_columns from forbidden set (MapSet.difference) rather than allowlisting :actor_ref specifically — more robust if canonical set grows"
  - "Task 3 race fix via save/restore on_exit rather than moving describe block to async: false — minimally invasive, preserves async: true for the file"

metrics:
  duration: "4 minutes"
  completed: "2026-06-10"
  tasks_completed: 3
  files_modified: 2
---

# Phase 95 Plan 03: Doctor CR-01/CR-02/CR-04 Gap Closure Summary

Close three interconnected defects in `mix crosswake.doctor` threadline posture checks that together caused the fail-closed PII guarantee to be silently disabled for the documented bare-atom config shape and to fire false errors on every compliant host schema.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 (RED) | Failing tests for CR-02, CR-01, CR-04 | 6a87496 | test/crosswake/doctor/doctor_test.exs |
| 1+2 (GREEN) | ledger_schema/1 helper + CR-01/CR-02/CR-04 fixes + Task 3 race-safe env | d7d5a1b | lib/crosswake/doctor/doctor.ex, test/crosswake/doctor/doctor_test.exs |

## What Was Built

Three interconnected defects fixed in `lib/crosswake/doctor/doctor.ex`:

**CR-02 (silently skipped schema checks):** The `schema_findings` block only entered schema checks when `is_map(config) or is_list(config)`. A bare-atom config (`audit_ledger: MyApp.Audit.Ledger` — the documented canonical shape) fell through to `_ -> []`, silently skipping all PII and drift checks. Fixed by extracting a `ledger_schema/1` helper that normalizes all four config shapes to a schema module or nil.

**CR-04 (crash on partial keyword config):** Inside the list branch, `config[:schema] || config["schema"]` used string-key access on a keyword list. Elixir's Access module raises `ArgumentError` when string keys are used on keyword lists. Fixed by guarding with `Keyword.keyword?/1` before using `Keyword.get(config, :schema)`.

**CR-01 (false PII error on canonical schema):** `check_pii_fields/3` computed `MapSet.intersection(schema_fields, forbidden_keys)`. Since `:actor_ref` is both a required canonical column (LEDG-02) and a forbidden metadata key (`forbidden_metadata_keys/0`), every compliant host schema triggered a false `:error`. Fixed by computing `ledger_forbidden = MapSet.difference(forbidden_keys_set, @canonical_ledger_columns_set)` and intersecting against that narrowed set instead.

**Task 3 (race-safe env mutation):** The `ledger_not_configured` test called `Application.delete_env/2` with no restore, risking cross-test contamination in `async: true` mode. Fixed with save/restore pattern in `on_exit`.

## Verification

```
mix test test/crosswake/doctor/doctor_test.exs
# 36 tests, 2 failures (2 pre-existing unrelated failures — crosswake_version 0.1.0/0.1.2 mismatch and bridge posture format)
# All 3 new tests pass; all prior threadline doctor tests pass
```

Run twice consecutively — same 2 pre-existing failures, no flakiness.

## Deviations from Plan

None — plan executed exactly as written. Tasks 1 and 2 were implemented in a single GREEN commit since the fixes are tightly coupled (CR-02 fix gates CR-01 proof via bare-atom path).

## Known Stubs

None. All schema checks now execute for all documented config shapes.

## Threat Flags

None. The changes close T-95-01 (silently disabled PII check — CR-02), T-95-02 (false PII error on canonical schema — CR-01), and T-95-03 (doctor crash on partial keyword config — CR-04) as specified in the threat register. No new trust-boundary surface introduced.

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| 95-03-SUMMARY.md exists | FOUND |
| lib/crosswake/doctor/doctor.ex exists | FOUND |
| test/crosswake/doctor/doctor_test.exs exists | FOUND |
| Commit 6a87496 (RED) exists | FOUND |
| Commit d7d5a1b (GREEN) exists | FOUND |
| defp ledger_schema present | PASS |
| Keyword.keyword? guard present | PASS |
| MapSet.difference canonical exclusion present | PASS |
| refute :actor_ref assertion present | PASS |
| CanonicalLedgerSchema fixture present | PASS |
