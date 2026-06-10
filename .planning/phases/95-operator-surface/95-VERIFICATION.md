---
phase: 95-operator-surface
verified: 2026-06-10T16:00:00Z
status: gaps_found
score: 3/4
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 2/4
  gaps_closed:
    - "mix crosswake.threadline prints an ORDERED Native->Bridge->Phoenix event table (CR-03 chronological sort fix)"
    - "mix crosswake.doctor CR-02 bare-atom config now enters schema checks via ledger_schema/1"
    - "mix crosswake.doctor CR-01 false PII error on :actor_ref eliminated via MapSet.difference"
    - "mix crosswake.doctor CR-04 crash on partial keyword config eliminated via Keyword.keyword? guard"
  gaps_remaining:
    - "Code.ensure_loaded?/1 still called without is_atom guard — non-atom :schema value crashes doctor"
  regressions: []
gaps:
  - truth: "mix crosswake.doctor emits threadline.pii_forbidden_field_present (error, fail-closed) correctly"
    status: partial
    reason: "Primary defects CR-01/CR-02/CR-04 are fixed and tested. Residual: ledger_schema/1 map and keyword clauses can return a non-atom :schema value (e.g. a string from %{schema: \"MyApp.Audit.Ledger\"} or [schema: \"MyApp.Audit.Ledger\"]). The call site at doctor.ex:896 evaluates Code.ensure_loaded?(schema) without an is_atom guard. Code.ensure_loaded?/1 requires an atom and raises FunctionClauseError on a string, crashing the doctor instead of emitting a finding. A fail-closed guarantee requires the doctor to always return a report."
    artifacts:
      - path: "lib/crosswake/doctor/doctor.ex"
        issue: "Line 896: `if schema && Code.ensure_loaded?(schema)` — no is_atom guard. ledger_schema/1 map clause (line 922-924) returns Map.get result without type-checking, so a string schema value passes the `schema &&` check and crashes Code.ensure_loaded?."
      - path: "test/crosswake/doctor/doctor_test.exs"
        issue: "No test exercises a string :schema value (e.g. [schema: \"MyApp.Audit.Ledger\"] or %{schema: \"MyApp.Audit.Ledger\"}) to assert doctor returns a report without raising."
    missing:
      - "At doctor.ex line 896: change guard to `if is_atom(schema) and not is_nil(schema) and Code.ensure_loaded?(schema)`, OR add a nil-returning clause to ledger_schema/1 for non-atom returned values"
      - "Add a regression test: Application.put_env(:crosswake, :audit_ledger, schema: \"MyApp.Audit.Ledger\") — assert doctor returns a report without raising"
deferred:
  - truth: "guides/threadline.md exists and is the authoritative operator guide"
    addressed_in: "Phase 96"
    evidence: "Phase 96 success criteria: 'A guides/threadline.md guide documents the header name, the AuditEvent field list, the forbidden-field list, the ephemeral-vs-durable posture...' (DOCS-01, DOCS-02, DOCS-03)"
---

# Phase 95: Operator Surface — Re-Verification Report

**Phase Goal:** An operator can query the event sequence for a thread or actor in text form and the doctor + support matrix give honest, actionable Threadline posture — including a fail-closed PII error
**Verified:** 2026-06-10T16:00:00Z
**Status:** gaps_found
**Re-verification:** Yes — after gap-closure plans 95-03 (doctor CR-01/CR-02/CR-04) and 95-04 (threadline chronological sort)

## Gap Closure Assessment

The two gaps from the initial verification (OPER-01 chronological sort, OPER-02 PII/config defects) were targeted by gap-closure plans 95-03 and 95-04 which both executed and committed. Three of the four prior CR defects are confirmed fixed. One residual defect from the fresh code review (95-REVIEW.md CR-01: no `is_atom` guard before `Code.ensure_loaded?/1`) was in scope of 95-03 but was omitted from the implementation. It is a partial gap, not a full regression, but it prevents the "fail-closed PII error" claim from being fully honest.

| Gap Closure | Commits | Status |
|------------|---------|--------|
| CR-03 chronological sort (OPER-01) | 8968d9d (RED), 75a8c31 (GREEN) | CLOSED |
| CR-02 bare-atom config normalization (OPER-02) | 6a87496 (RED), d7d5a1b (GREEN) | CLOSED |
| CR-01 false :actor_ref PII error (OPER-02) | d7d5a1b (GREEN) | CLOSED |
| CR-04 keyword crash without :schema (OPER-02) | d7d5a1b (GREEN) | CLOSED |
| CR-04 residual: is_atom guard before Code.ensure_loaded? | not applied | BLOCKER |

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `mix crosswake.threadline --thread-id/--actor-ref` prints ordered Native->Bridge->Phoenix table with explicit ephemeral/durable posture | VERIFIED | `Enum.sort_by(&timestamp_of/1, fn a, b -> compare_ts(a, b) != :gt end)` at line 96 with 4-clause `compare_ts/2` dispatcher (lines 115-129). Month-boundary regression test at threadline_test.exs:157-252 with out-of-order Dec-2025/Jan-2026/Feb-2026 events asserts `dec_pos < jan_pos < feb_pos`. `mix test test/mix/tasks/crosswake.threadline_test.exs` → 5 tests, 0 failures. |
| 2 | `mix crosswake.doctor` emits all 4 Threadline findings including fail-closed `threadline.pii_forbidden_field_present` :error | PARTIAL | CR-01/CR-02/CR-04 primary fixes verified in code and tests. Residual: `Code.ensure_loaded?(schema)` at doctor.ex:896 lacks `is_atom` guard. A string `:schema` value (from `%{schema: "MyApp.Audit.Ledger"}` or `[schema: "..."]`) passes through `ledger_schema/1` and crashes the doctor with `FunctionClauseError` instead of returning a report. No regression test for this path. `mix test test/crosswake/doctor/doctor_test.exs` → 36 tests, 2 failures (both pre-existing version-literal failures unrelated to this phase). |
| 3 | Support matrix exposes `@audit_ledger_support_truth` with ephemeral-only non-blocking posture | VERIFIED | `@audit_ledger_support_truth` defined at support_matrix.ex:275, exported via `audit_ledger_support_truth/0` at line 476. Correct `ephemeral_posture: :supported`, `durable_posture: :supported`, PII-free posture string, deferred list. `mix test test/crosswake/support_matrix/support_matrix_test.exs` → 52 tests, 0 failures. |
| 4 | All three operator surfaces use text output only; no LiveDashboard dependency introduced | VERIFIED | No reference to LiveDashboard or live_dashboard in any Phase 95 file. Mix task uses `Mix.shell().info/1`, doctor emits findings structs, support matrix is a compile-time module attribute. |

**Score:** 3/4 truths verified (Truth 2 is PARTIAL — BLOCKER residual defect)

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | `guides/threadline.md` referenced in 4 operator-facing strings (support_matrix docs_anchor, 3 doctor hints) | Phase 96 | Phase 96 success criteria: DOCS-01/02/03 — "A guides/threadline.md guide documents the header name, the AuditEvent field list, the forbidden-field list, the ephemeral-vs-durable posture..." |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/mix/tasks/crosswake.threadline.ex` | CLI timeline visualization with chronological sort | VERIFIED | Exists. Date-comparator sort at line 96 with `compare_ts/2` dispatcher. Ephemeral and durable posture paths both functional. 5 tests pass. |
| `test/mix/tasks/crosswake.threadline_test.exs` | 5 tests including month-boundary regression | VERIFIED | Exists. 5 tests: argument error, ephemeral, durable (tier ordering), chronological month-boundary. 0 failures. |
| `lib/crosswake/support_matrix/support_matrix.ex` | `@audit_ledger_support_truth` + `audit_ledger_support_truth/0` | VERIFIED | Attribute at line 275, accessor at line 476. Correct shape with all required fields. |
| `test/crosswake/support_matrix/support_matrix_test.exs` | Tests for audit_ledger_support_truth/0 | VERIFIED | 52 tests, 0 failures. Includes telemetry parity, deferred items, posture content checks. |
| `lib/crosswake/doctor/doctor.ex` | `phase_95_threadline_findings/2` + `ledger_schema/1` + CR-01/CR-02/CR-04 fixes | PARTIAL | `ledger_schema/1` helper exists (lines 912-930) and normalizes nil/keyword/map/bare-atom. CR-01 `MapSet.difference` at line 1013. CR-04 `Keyword.keyword?` at line 915. Residual: no `is_atom` guard at line 896 before `Code.ensure_loaded?`. |
| `test/crosswake/doctor/doctor_test.exs` | Canonical-schema test, bare-atom regression, keyword-without-schema regression | PARTIAL | `CanonicalLedgerSchema` fixture at line 1386. Bare-atom and keyword-without-schema tests present (lines 1394-1433). No test for string `:schema` value crashing `Code.ensure_loaded?`. 36 tests, 2 pre-existing failures. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `doctor.ex phase_95_threadline_findings/2` | `ledger_schema/1` | config normalization | VERIFIED | `schema = ledger_schema(audit_ledger_config)` at line 893. All 4 config shapes handled. |
| `doctor.ex check_pii_fields/3` | `@canonical_ledger_columns` | `MapSet.difference` | VERIFIED | `MapSet.difference(MapSet.new(forbidden_keys), MapSet.new(@canonical_ledger_columns))` at line 1013. |
| `doctor.ex` | `Code.ensure_loaded?/1` | schema guard | PARTIAL | `if schema && Code.ensure_loaded?(schema)` at line 896 — `schema &&` does not guarantee atom type; string values crash. |
| `mix/tasks/crosswake.threadline.ex query_events/4` | chronological ordering | `Enum.sort_by(&timestamp_of/1, compare_ts fn)` | VERIFIED | Line 96. `compare_ts/2` dispatches on NaiveDateTime/DateTime struct types including mixed pairs. |
| `doctor.ex` | `Crosswake.SupportMatrix` | `audit_ledger_support_truth/0` | VERIFIED | Called at line 998 to retrieve forbidden_metadata_keys for PII intersection. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `crosswake.threadline.ex render_durable/1` | `events` list | `repo.all(schema)` + in-memory filter + date-comparator sort | Yes — chronologically ordered, dynamic from repo | FLOWING |
| `doctor.ex check_pii_fields/3` | `offending` MapSet | `schema.__schema__(:fields)` intersected with `forbidden_keys` minus `@canonical_ledger_columns` | Correct for atom schema modules; string schema value crashes before this point | FLOWING for valid atom configs; CRASH PATH for string :schema values |
| `doctor.ex check_ledger_schema/1` | `schema_fields` | `schema.__schema__(:fields)` | Reached for all documented config shapes via `ledger_schema/1` | FLOWING |

### Behavioral Spot-Checks

| Behavior | Verified By | Result |
|----------|-------------|--------|
| Ephemeral posture output when no config | test threadline_test.exs:42-50 | PASS — "Posture: Ephemeral. No ledger configured." |
| Durable tree rendering (Native/Bridge/Phoenix) | test threadline_test.exs:106-155 | PASS — tier labels, tree connectors present |
| Chronological sort across month boundary | test threadline_test.exs:230-251 | PASS — dec_pos < jan_pos < feb_pos with out-of-order Dec-2025/Jan-2026/Feb-2026 events |
| No false PII error on canonical 15-column schema | test doctor_test.exs:1395-1415 | PASS — zero pii_forbidden_field_present, zero ledger_schema_drift |
| PII error on genuine PII field (:email), :actor_ref not flagged | test doctor_test.exs:1333-1353 | PASS — :email in offending_keys, refute :actor_ref in offending_keys |
| Bare-atom audit_ledger config enters schema checks | test doctor_test.exs:1395-1415 (proves checks ran via zero-findings assertion) | PASS |
| Partial keyword config (no :schema key) does not crash | test doctor_test.exs:1418-1433 | PASS |
| String :schema value does not crash doctor | No test; code inspection confirms crash path exists | FAIL — Code.ensure_loaded?("...") raises FunctionClauseError |

### Probe Execution

Step 7c: No probe files declared in PLAN or present at `scripts/*/tests/probe-*.sh`. SKIPPED.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| OPER-01 | 95-02-PLAN.md, 95-04-PLAN.md | Operator can run `mix crosswake.threadline --thread-id/--actor-ref` and see ordered event table with ephemeral/durable posture | SATISFIED | Date-comparator sort verified. 5 tests pass. |
| OPER-02 | 95-01-PLAN.md, 95-03-PLAN.md | `mix crosswake.doctor` reports Threadline posture with 4 findings including fail-closed :error | BLOCKED | All 4 finding types implemented. CR-01/CR-02/CR-04 primary fixes verified. Residual: no is_atom guard before Code.ensure_loaded?/1 — string :schema config crashes doctor. Fail-closed guarantee not fully achieved. |
| OPER-03 | 95-01-PLAN.md | Support matrix exposes `@audit_ledger_support_truth` with denial/fallback posture | SATISFIED | `@audit_ledger_support_truth` defined and exported. Correct posture fields. 52 tests pass. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/crosswake/doctor/doctor.ex` | 896 | `Code.ensure_loaded?(schema)` without `is_atom(schema)` guard — non-atom :schema value crashes doctor | BLOCKER | String :schema config crashes doctor with FunctionClauseError instead of returning a report; "fail-closed PII error" claim is not fully honest |
| `test/crosswake/doctor/doctor_test.exs` | 184 | `IO.inspect(Enum.filter(report.findings, & &1.severity == :error))` — leftover debug call fused to assertion | WARNING | Prints `[]` to test output on every run; production test noise |
| `test/crosswake/doctor/doctor_test.exs` | 94, 199 | Hardcoded version literals "0.1.0" and "bridge posture: crosswake.bridge@1.0.0" — stale, cause 2 pre-existing failures | WARNING | 2 failures on every test run; misleading "RED" state for the doctor test file overall; pre-existing from before Phase 95 |

No unreferenced `TBD`, `FIXME`, or `XXX` debt markers found in Phase 95 files.

### Human Verification Required

None. All remaining defect is verifiable by code inspection and targeted test execution.

### Gaps Summary

**One residual BLOCKER prevents OPER-02 from being fully satisfied:**

The 95-03 gap-closure plan prescribed — in the CR-04 fix section — adding an `is_atom(schema)` guard before `Code.ensure_loaded?/1`. The keyword-access half of CR-04 (`Keyword.keyword?` guard) was applied. The atom-type-guard half was omitted.

The call site at doctor.ex:896 is:
```elixir
if schema && Code.ensure_loaded?(schema) do
```

`ledger_schema/1` map clause at lines 922-924 returns `Map.get(config, :schema) || Map.get(config, "schema")` without type-checking the returned value. A string module name — the classic `config/runtime.exs` + `System.get_env` pattern, e.g. `%{schema: "MyApp.Audit.Ledger"}` — returns a non-nil string that passes `schema &&` and then crashes `Code.ensure_loaded?("MyApp.Audit.Ledger")` with `FunctionClauseError`. The doctor crashes instead of reporting, which is contrary to the "fail-closed PII error" goal.

**Fix (1 line):**
```elixir
schema_findings =
  if is_atom(schema) and not is_nil(schema) and Code.ensure_loaded?(schema) do
    check_ledger_schema(schema)
  else
    []
  end
```

**Regression test to add:**
```elixir
test "does not crash on string :schema value in config" do
  Application.put_env(:crosswake, :audit_ledger, schema: "MyApp.Audit.Ledger")
  on_exit(fn -> Application.delete_env(:crosswake, :audit_ledger) end)
  report = Doctor.run(...)
  assert report != nil
end
```

This is a narrow, single-line fix. The prior three CR defects are confirmed closed.

---

_Verified: 2026-06-10T16:00:00Z_
_Verifier: Claude (gsd-verifier)_
_Re-verification: Yes — after gap-closure plans 95-03 and 95-04_
