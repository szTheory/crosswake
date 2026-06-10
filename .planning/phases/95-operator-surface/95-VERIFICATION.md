---
phase: 95-operator-surface
verified: 2026-06-10T18:00:00Z
status: passed
score: 4/4
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/4
  gaps_closed:
    - "Code.ensure_loaded?/1 guard — is_atom + not is_nil guard added at doctor.ex:896 (commit 5cb0d49)"
    - "Regression test added: string :schema map config must not crash the doctor (commit 3400248)"
    - "IO.inspect debug call removed from doctor_test.exs:184 (commit 5cb0d49)"
  gaps_remaining: []
  regressions: []
deferred:
  - truth: "guides/threadline.md exists and is the authoritative operator guide"
    addressed_in: "Phase 96"
    evidence: "Phase 96 success criteria: 'A guides/threadline.md guide documents the header name, the AuditEvent field list, the forbidden-field list, the ephemeral-vs-durable posture...' (DOCS-01, DOCS-02, DOCS-03)"
---

# Phase 95: Operator Surface — Re-Verification Report (95-05 Gap Closure)

**Phase Goal:** An operator can query the event sequence for a thread or actor in text form and the doctor + support matrix give honest, actionable Threadline posture — including a fail-closed PII error
**Verified:** 2026-06-10T18:00:00Z
**Status:** PASSED
**Re-verification:** Yes — after gap-closure plans 95-03, 95-04, and 95-05

## Gap Closure Assessment

The residual BLOCKER from the prior verification (3/4) was the missing `is_atom` guard before `Code.ensure_loaded?/1` at doctor.ex:896. Gap-closure plan 95-05 executed two commits:

| Commit | Change | Status |
|--------|--------|--------|
| `3400248` | RED test: string :schema map config must not crash the doctor | CONFIRMED |
| `5cb0d49` | Fix: replace `schema &&` with `is_atom(schema) and not is_nil(schema)` guard; remove IO.inspect debug call | CONFIRMED |

`mix test test/crosswake/doctor/doctor_test.exs:1436` — 1 test, 0 failures. The new test passes cleanly against the patched guard.

Total phase doctor test run: 37 tests, 2 failures. Count increased from 36 to 37 (new test added). The 2 failures are both pre-existing version-literal assertions at lines 94 and 199, predating Phase 95 and explicitly noted as out-of-scope.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `mix crosswake.threadline --thread-id/--actor-ref` prints ordered Native->Bridge->Phoenix table with explicit ephemeral/durable posture | VERIFIED | `Enum.sort_by(&timestamp_of/1, compare_ts fn)` at line 96 with 4-clause `compare_ts/2` (lines 115-129). Month-boundary regression test at threadline_test.exs:157-252 asserts `dec_pos < jan_pos < feb_pos` with out-of-order Dec-2025/Jan-2026/Feb-2026 events. `mix test test/mix/tasks/crosswake.threadline_test.exs` — 5 tests, 0 failures. |
| 2 | `mix crosswake.doctor` emits all 4 Threadline findings including fail-closed `threadline.pii_forbidden_field_present` :error | VERIFIED | `is_atom(schema) and not is_nil(schema) and Code.ensure_loaded?(schema)` guard at doctor.ex:896 (commit 5cb0d49). CR-01 `MapSet.difference` at line 1013. CR-02 bare-atom config normalization. CR-04 `Keyword.keyword?` guard at line 915. String :schema regression test passes (doctor_test.exs:1436). 37 tests, 2 pre-existing failures. |
| 3 | Support matrix exposes `@audit_ledger_support_truth` with ephemeral-only non-blocking posture | VERIFIED | `@audit_ledger_support_truth` defined at support_matrix.ex:275, exported via `audit_ledger_support_truth/0` at line 476. Correct `ephemeral_posture: :supported`, `durable_posture: :supported`, PII-free posture string, deferred list. `mix test test/crosswake/support_matrix/support_matrix_test.exs` — 52 tests, 0 failures. |
| 4 | All three operator surfaces use text output only; no LiveDashboard dependency introduced | VERIFIED | No reference to LiveDashboard or live_dashboard in any Phase 95 file. Mix task uses `Mix.shell().info/1`, doctor emits findings structs, support matrix is a compile-time module attribute. |

**Score:** 4/4 truths verified

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | `guides/threadline.md` referenced in 4 operator-facing strings (support_matrix docs_anchor, 3 doctor hints) | Phase 96 | Phase 96 success criteria: DOCS-01/02/03 — "A guides/threadline.md guide documents the header name, the AuditEvent field list, the forbidden-field list, the ephemeral-vs-durable posture..." |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/mix/tasks/crosswake.threadline.ex` | CLI timeline with chronological sort and posture output | VERIFIED | Date-comparator sort at line 96 with `compare_ts/2` dispatcher. Ephemeral and durable posture paths both functional. 5 tests pass. |
| `test/mix/tasks/crosswake.threadline_test.exs` | 5 tests including month-boundary regression | VERIFIED | 5 tests: argument error, ephemeral, durable (tier ordering), chronological month-boundary. 0 failures. |
| `lib/crosswake/support_matrix/support_matrix.ex` | `@audit_ledger_support_truth` + `audit_ledger_support_truth/0` | VERIFIED | Attribute at line 275, accessor at line 476. Correct shape with all required fields. |
| `test/crosswake/support_matrix/support_matrix_test.exs` | Tests for audit_ledger_support_truth/0 | VERIFIED | 52 tests, 0 failures. Includes telemetry parity, deferred items, posture content checks. |
| `lib/crosswake/doctor/doctor.ex` | `phase_95_threadline_findings/2` + `ledger_schema/1` + is_atom guard + CR-01/02/04 fixes | VERIFIED | `is_atom(schema) and not is_nil(schema) and Code.ensure_loaded?(schema)` at line 896. `ledger_schema/1` normalizes nil/keyword/map/bare-atom (lines 912-930). CR-01 `MapSet.difference` at line 1013. CR-04 `Keyword.keyword?` at line 915. |
| `test/crosswake/doctor/doctor_test.exs` | Canonical-schema test, bare-atom regression, keyword-without-schema regression, string-schema regression | VERIFIED | `CanonicalLedgerSchema` fixture at line 1386. Bare-atom and keyword-without-schema tests (lines 1394-1433). String :schema regression test at line 1436 (CR-05). 37 tests, 2 pre-existing failures. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `doctor.ex phase_95_threadline_findings/2` | `ledger_schema/1` | config normalization | VERIFIED | `schema = ledger_schema(audit_ledger_config)` at line 893. All 4 config shapes handled. |
| `doctor.ex check_pii_fields/3` | `@canonical_ledger_columns` | `MapSet.difference` | VERIFIED | `MapSet.difference(MapSet.new(forbidden_keys), MapSet.new(@canonical_ledger_columns))` at line 1013. |
| `doctor.ex` | `Code.ensure_loaded?/1` | is_atom + not is_nil guard | VERIFIED | `if is_atom(schema) and not is_nil(schema) and Code.ensure_loaded?(schema)` at line 896. String schema values now fall through to `else [] end` instead of crashing. |
| `mix/tasks/crosswake.threadline.ex query_events/4` | chronological ordering | `Enum.sort_by(&timestamp_of/1, compare_ts fn)` | VERIFIED | Line 96. `compare_ts/2` dispatches on NaiveDateTime/DateTime struct types including mixed pairs. |
| `doctor.ex` | `Crosswake.SupportMatrix` | `audit_ledger_support_truth/0` | VERIFIED | Called at line 998 to retrieve forbidden_metadata_keys for PII intersection. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `crosswake.threadline.ex render_durable/1` | `events` list | `repo.all(schema)` + in-memory filter + date-comparator sort | Yes — chronologically ordered, dynamic from repo | FLOWING |
| `doctor.ex check_pii_fields/3` | `offending` MapSet | `schema.__schema__(:fields)` intersected with `forbidden_keys` minus `@canonical_ledger_columns` | Correct for atom schema modules; string :schema now safely returns `[]` via is_atom guard | FLOWING |
| `doctor.ex check_ledger_schema/1` | `schema_fields` | `schema.__schema__(:fields)` | Reached for all documented config shapes via `ledger_schema/1` | FLOWING |

### Behavioral Spot-Checks

| Behavior | Verified By | Result |
|----------|-------------|--------|
| Ephemeral posture output when no config | test threadline_test.exs:42-50 | PASS — "Posture: Ephemeral. No ledger configured." |
| Durable tree rendering (Native/Bridge/Phoenix) | test threadline_test.exs:106-155 | PASS — tier labels, tree connectors present |
| Chronological sort across month boundary | test threadline_test.exs:230-251 | PASS — dec_pos < jan_pos < feb_pos with out-of-order Dec-2025/Jan-2026/Feb-2026 events |
| No false PII error on canonical 15-column schema | test doctor_test.exs:1395-1415 | PASS — zero pii_forbidden_field_present, zero ledger_schema_drift |
| PII error on genuine PII field (:email), :actor_ref not flagged | test doctor_test.exs:1333-1353 | PASS — :email in offending_keys, refute :actor_ref in offending_keys |
| Bare-atom audit_ledger config enters schema checks | test doctor_test.exs:1395-1415 | PASS — zero-findings assertion proves checks ran |
| Partial keyword config (no :schema key) does not crash | test doctor_test.exs:1418-1433 | PASS |
| String :schema map config does not crash doctor | test doctor_test.exs:1436-1452 | PASS — `is_atom(schema)` guard returns `[]` instead of raising FunctionClauseError |

### Probe Execution

Step 7c: No probe files declared in PLAN or present at `scripts/*/tests/probe-*.sh`. SKIPPED.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| OPER-01 | 95-02-PLAN.md, 95-04-PLAN.md | Operator can run `mix crosswake.threadline --thread-id/--actor-ref` and see ordered event table with ephemeral/durable posture | SATISFIED | Date-comparator sort verified. 5 tests pass. |
| OPER-02 | 95-01-PLAN.md, 95-03-PLAN.md, 95-05-PLAN.md | `mix crosswake.doctor` reports Threadline posture with 4 findings including fail-closed :error | SATISFIED | All 4 finding types implemented. CR-01/CR-02/CR-04 fixes verified. is_atom guard at doctor.ex:896 prevents FunctionClauseError on string :schema. Regression test passes. |
| OPER-03 | 95-01-PLAN.md | Support matrix exposes `@audit_ledger_support_truth` with denial/fallback posture | SATISFIED | `@audit_ledger_support_truth` defined and exported. Correct posture fields. 52 tests pass. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `test/crosswake/doctor/doctor_test.exs` | 94, 199 | Hardcoded version literals "0.1.0" and "bridge posture: crosswake.bridge@1.0.0" — stale, cause 2 pre-existing failures | WARNING | 2 failures on every test run; pre-existing from before Phase 95, out of scope |

No unreferenced `TBD`, `FIXME`, or `XXX` debt markers found in Phase 95 files. The `IO.inspect` debug call previously flagged at doctor_test.exs:184 was removed in commit 5cb0d49.

### Human Verification Required

None. All claims are verifiable by code inspection and test execution.

### Gaps Summary

No gaps. All four truths verified. Phase goal achieved.

The final BLOCKER from the prior verification (CR-05: string :schema value crashing `Code.ensure_loaded?/1`) is confirmed closed:

- `lib/crosswake/doctor/doctor.ex:896` — guard is now `is_atom(schema) and not is_nil(schema) and Code.ensure_loaded?(schema)`
- `test/crosswake/doctor/doctor_test.exs:1436` — regression test "does not crash on string :schema value in map config" passes (1 test, 0 failures)
- Committed in two TDD commits: RED (`3400248`) then GREEN + IO.inspect cleanup (`5cb0d49`)

---

_Verified: 2026-06-10T18:00:00Z_
_Verifier: Claude (gsd-verifier)_
_Re-verification: Yes — after gap-closure plans 95-03, 95-04, and 95-05_
