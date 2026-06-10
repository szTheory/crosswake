---
phase: 95-operator-surface
verified: 2026-06-10T14:00:00Z
status: gaps_found
score: 2/4
overrides_applied: 0
gaps:
  - truth: "mix crosswake.threadline prints an ORDERED Native->Bridge->Phoenix event table"
    status: failed
    reason: "Enum.sort_by/2 at crosswake.threadline.ex:96 uses Erlang structural term order on NaiveDateTime/DateTime structs. Erlang compares struct map keys alphabetically (:day before :month before :year), so events spanning a month or year boundary are sorted incorrectly. The task's core output claim — chronological sequence reconstruction — is wrong for real-world multi-month audit windows."
    artifacts:
      - path: "lib/mix/tasks/crosswake.threadline.ex"
        issue: "Enum.sort_by/2 without a comparator module; no test covers out-of-order timestamps spanning a month boundary (test uses same-day pre-sorted events)"
    missing:
      - "Replace bare Enum.sort_by/2 with a date-comparator variant: Enum.sort_by(&ts/1, NaiveDateTime) or an explicit fn a, b -> NaiveDateTime.compare(a,b) != :gt end"
      - "Add a test fixture with events supplied out of order spanning a month boundary"

  - truth: "mix crosswake.doctor emits threadline.pii_forbidden_field_present (error, fail-closed) correctly"
    status: failed
    reason: "Two independent defects make the fail-closed PII check either misfired or silently disabled. (1) CR-01: check_pii_fields/3 intersects schema fields with Crosswake.Threadline.Telemetry.forbidden_metadata_keys(), which includes :actor_ref. But :actor_ref is also a required canonical LEDG-02 column and is present in the generator-scaffolded schema (priv/templates/crosswake/audit/ledger.ex.eex:17). Every compliant host therefore receives a false :error finding for :actor_ref — the doctor simultaneously demands the column (drift check) and forbids it (PII check). (2) CR-02: The doctor only enters the schema-check branch when :audit_ledger is a map/list with a [:schema] key (doctor.ex:898-899). The documented config shape in the mix task moduledoc and mix crosswake.gen.audit output is a bare module atom (audit_ledger: MyApp.Audit.Ledger). A bare atom falls through the '_ -> []' catch-all (doctor.ex:906) — silently skipping both the PII check and the drift check on every correctly-configured host. The tests mask both defects: PiiLedgerSchema includes :actor_ref and only asserts :email in offending_keys; no test runs the 15-column canonical schema; the doctor tests configure via [schema: PiiLedgerSchema] (keyword shape), not the bare-atom shape the task documents."
    artifacts:
      - path: "lib/crosswake/doctor/doctor.ex"
        issue: "CR-01 (line 989-990): check_pii_fields/3 does not exclude @canonical_ledger_columns before intersecting with forbidden_metadata_keys — :actor_ref fires false :error on every canonical deployment. CR-02 (line 894-908): bare-atom :audit_ledger config falls through to [] catch-all, silently disabling all schema checks. CR-04 (line 899): config[:schema] || config[\"schema\"] raises ArgumentError when config is a keyword list without :schema key."
      - path: "test/crosswake/doctor/doctor_test.exs"
        issue: "No test verifies that the canonical 15-column schema produces zero PII and zero drift findings. Doctor tests use [schema: Module] keyword shape, which does not test the documented bare-atom config path."
    missing:
      - "In check_pii_fields/3: subtract @canonical_ledger_columns from forbidden_keys before intersecting — ledger_forbidden = MapSet.difference(MapSet.new(forbidden_keys), MapSet.new(@canonical_ledger_columns))"
      - "Normalize :audit_ledger config in one shared helper that accepts bare atom, keyword list, or map — both doctor and mix task must use the same normalization"
      - "Add a regression test: 15-column canonical schema produces zero threadline.pii_forbidden_field_present and zero threadline.ledger_schema_drift findings"
      - "Fix CR-04: use Keyword.keyword?(config) guard before string-key access to prevent ArgumentError on partial keyword configs"

deferred:
  - truth: "guides/threadline.md exists and is the authoritative operator guide"
    addressed_in: "Phase 96"
    evidence: "Phase 96 success criteria: 'A guides/threadline.md guide documents the header name, the AuditEvent field list, the forbidden-field list, the ephemeral-vs-durable posture...' (DOCS-01, DOCS-02, DOCS-03)"
---

# Phase 95: Operator Surface — Verification Report

**Phase Goal:** An operator can query the event sequence for a thread or actor in text form and the doctor + support matrix give honest, actionable Threadline posture — including a fail-closed PII error
**Verified:** 2026-06-10T14:00:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `mix crosswake.threadline --thread-id/--actor-ref` prints ordered Native->Bridge->Phoenix table with explicit ephemeral/durable posture | FAILED | Task exists, ephemeral/durable posture output is correct, tree rendering is implemented. However `Enum.sort_by/2` at line 96 uses Erlang structural term order — chronology is wrong across month/year boundaries. The tool's core claim is sequence reconstruction; incorrect ordering is incorrect output. (CR-03) |
| 2 | `mix crosswake.doctor` emits all 4 Threadline findings including fail-closed `threadline.pii_forbidden_field_present` :error | FAILED | All 4 findings are implemented. But (a) the PII check fires a false :error on every compliant host because `:actor_ref` is in `forbidden_metadata_keys` and is simultaneously a required canonical column (CR-01), and (b) the config-shape mismatch means schema checks are silently disabled when using the documented bare-atom config (CR-02). The "fail-closed" safety guarantee is broken in both directions. |
| 3 | Support matrix exposes `@audit_ledger_support_truth` with ephemeral-only non-blocking posture | VERIFIED | `@audit_ledger_support_truth` defined at support_matrix.ex:275, exported via `audit_ledger_support_truth/0` at line 476. Contains `ephemeral_posture: :supported`, `durable_posture: :supported`, correct posture statement, PII-free correlation description. Compile-time truth is correct. |
| 4 | All three operator surfaces use text output only; no LiveDashboard dependency introduced | VERIFIED | Grep across all three Phase 95 files finds no reference to LiveDashboard or live_dashboard. Mix task uses `Mix.shell().info/1`, doctor emits findings structs, support matrix is a module attribute. |

**Score:** 2/4 truths verified

### Deferred Items

Items not yet met but explicitly addressed in later milestone phases.

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | `guides/threadline.md` referenced as authoritative in 4 operator-facing strings (support_matrix docs_anchor, 4 doctor hints) | Phase 96 | Phase 96 success criteria: "A guides/threadline.md guide documents the header name, the AuditEvent field list, the forbidden-field list, the ephemeral-vs-durable posture..." (DOCS-01/02/03) |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/mix/tasks/crosswake.threadline.ex` | CLI timeline visualization task | WIRED — PARTIAL | Exists, substantive, wired. Defect: sort uses Erlang term order not date comparator (CR-03). Config disagrees with doctor (CR-02). |
| `test/mix/tasks/crosswake.threadline_test.exs` | 3 test groups, 4 tests | WIRED | Exists, 4 tests cover error/ephemeral/durable paths. Durable test uses same-day pre-sorted events, does not exercise sort correctness or actor-ref durable path. |
| `lib/crosswake/support_matrix/support_matrix.ex` | `@audit_ledger_support_truth` + `audit_ledger_support_truth/0` | VERIFIED | Attribute defined at line 275, accessor exported at line 476. Correct shape. |
| `test/crosswake/support_matrix/support_matrix_test.exs` | Tests for audit_ledger_support_truth/0 | VERIFIED | Exists with 10 new tests covering surface, proof_class, telemetry parity, deferred items, posture content. |
| `lib/crosswake/doctor/doctor.ex` | `phase_95_threadline_findings/2` with 4 finding types | WIRED — PARTIAL | Exists, wired at doctor.ex:153. PII check intersects wrong key set (CR-01). Config normalization silently disables schema checks for canonical config shape (CR-02). CR-04: keyword list without :schema key crashes doctor. |
| `test/crosswake/doctor/doctor_test.exs` | 5 tests for 4 findings | WIRED — PARTIAL | Exists with 5 tests. Tests use [schema: Module] keyword config shape, not documented bare-atom shape. No test runs canonical 15-column schema. PII test only asserts :email in offending_keys, masking false-positive for :actor_ref. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `lib/crosswake/doctor/doctor.ex` | Ecto schema reflection | `schema.__schema__(:fields)` | PARTIAL | Pattern exists at line 973. Gated behind is_map/is_list config guard — bare-atom config (canonical shape) falls through to `[] ` catch-all, bypassing reflection entirely. |
| `lib/mix/tasks/crosswake.threadline.ex` | Ecto Repo | `Application.get_env(:crosswake, :audit_repo)` | VERIFIED | `ledger_posture/0` reads `:audit_repo` and `:audit_ledger` from Application env (lines 64-65). Bare atom shape used and tested in durable path. |
| `lib/crosswake/doctor/doctor.ex` | `Crosswake.SupportMatrix` | `audit_ledger_support_truth/0` | VERIFIED | Called at doctor.ex:979 to retrieve forbidden_metadata_keys for PII intersection. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `crosswake.threadline.ex` — `render_durable/1` | `events` list | `repo.all(schema)` + in-memory filter | Yes (dynamic from repo, filtered in-memory) | FLOWING — with sort defect |
| `doctor.ex` — `check_pii_fields/3` | `offending` MapSet | `schema.__schema__(:fields)` intersected with `forbidden_metadata_keys` | Data flows but intersection logic is wrong — includes canonical :actor_ref as forbidden | HOLLOW — wrong key set |
| `doctor.ex` — `check_ledger_schema/1` | `schema_fields` | `schema.__schema__(:fields)` | Only reached for map/list config; bare-atom config never enters this branch | DISCONNECTED — for canonical config shape |

### Behavioral Spot-Checks

Step 7b: SKIPPED for ephemeral path (no runnable server). Logic path verified by code inspection.

| Behavior | Verified By | Result |
|----------|-------------|--------|
| Ephemeral posture output when no config | Code inspection + test at threadline_test.exs:42-50 | PASS — `Mix.shell().info("Posture: Ephemeral. No ledger configured.")` |
| Durable tree rendering (Native/Bridge/Phoenix) | Code inspection + test at threadline_test.exs:129-154 | PASS — tier labels, connectors present |
| Chronological sort across month boundary | Code inspection | FAIL — `Enum.sort_by/2` with no comparator uses Erlang term order on DateTime/NaiveDateTime structs |
| PII error on non-canonical PII field (:email) | test at doctor_test.exs:1322-1339 | PASS — :email triggers :error |
| No false PII error on canonical 15-column schema | No test exists | FAIL — :actor_ref is in forbidden_metadata_keys, fires false :error on compliant schema |
| Schema checks run with bare-atom audit_ledger config | Code inspection | FAIL — bare atom falls through to `_ -> []` at doctor.ex:906 |

### Probe Execution

Step 7c: No probe files declared in PLAN or present at `scripts/*/tests/probe-*.sh` for this phase. SKIPPED.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| OPER-01 | 95-02-PLAN.md | Operator can run `mix crosswake.threadline --thread-id/--actor-ref` and see ordered event table with ephemeral/durable posture | BLOCKED | Task exists and posture output works. Sort defect (CR-03) means the "ordered" claim fails for real event data spanning month/year boundaries. |
| OPER-02 | 95-01-PLAN.md | `mix crosswake.doctor` reports Threadline posture with 4 findings including fail-closed :error | BLOCKED | All 4 finding types implemented. False-positive PII error on canonical schema (CR-01) and silent skip of schema checks under documented config (CR-02) mean the feature is not honestly actionable. |
| OPER-03 | 95-01-PLAN.md | Support matrix exposes `@audit_ledger_support_truth` with ephemeral-only non-blocking posture | SATISFIED | `@audit_ledger_support_truth` defined and exported. Correct posture fields present. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/mix/tasks/crosswake.threadline.ex` | 96-102 | `Enum.sort_by/2` without comparator on DateTime/NaiveDateTime | BLOCKER | Chronological ordering is wrong across month/year boundaries — core output claim of the tool is incorrect |
| `lib/crosswake/doctor/doctor.ex` | 989-990 | PII key intersection includes canonical LEDG-02 column `:actor_ref` | BLOCKER | Every compliant host triggers a false `:error` finding; the PII safety check fires on correct deployments |
| `lib/crosswake/doctor/doctor.ex` | 894-908 | Config normalization only handles map/list; bare atom falls to `_ -> []` | BLOCKER | Schema PII and drift checks silently disabled for documented config shape |
| `lib/crosswake/doctor/doctor.ex` | 899 | `config["schema"]` on keyword list raises `ArgumentError` | BLOCKER | Doctor crashes with `ArgumentError` on partial keyword config missing `:schema` key |
| `test/crosswake/doctor/doctor_test.exs` | 2 + 1292-1370 | `Application.put_env` / `delete_env` in `async: true` module | WARNING | Race condition with any other async test reading `:audit_ledger`; `delete_env` without save/restore in ledger_not_configured test |

No unreferenced `TBD`, `FIXME`, or `XXX` debt markers were found in phase-95 files.

### Human Verification Required

None. All defects are verifiable by code inspection and test analysis.

### Gaps Summary

Two ROADMAP Success Criteria fail due to four interconnected code defects:

**SC-1 gap (OPER-01):** The `mix crosswake.threadline` task renders the correct posture labels and tree structure but uses `Enum.sort_by/2` without a comparator, which applies Erlang structural term order to `NaiveDateTime`/`DateTime` structs. Erlang compares struct keys alphabetically (`:day` before `:month` before `:year`), so events spanning a month or year boundary are sorted newest-first in some positions. The tool's stated purpose is chronological sequence reconstruction; this defect makes the output wrong for any real audit window.

**SC-2 gaps (OPER-02):** Three defects undermine the doctor's Threadline posture checks:

1. **CR-01 — False PII error on canonical schemas:** `check_pii_fields/3` computes the intersection of schema fields against `Crosswake.Threadline.Telemetry.forbidden_metadata_keys()`. That list includes `:actor_ref` (correctly excluded from telemetry). But `:actor_ref` is simultaneously a required canonical LEDG-02 column and present in the generator-scaffolded ledger template. Every host that runs `mix crosswake.gen.audit` and uses the resulting schema will receive an `:error`-severity `threadline.pii_forbidden_field_present` finding for `:actor_ref` — while the drift check simultaneously warns if `:actor_ref` is absent. The doctor contradicts itself, and the "fail-closed PII error" becomes a noise-only finding that operators must suppress.

2. **CR-02 — Config shape mismatch silently disables schema checks:** The doctor's `phase_95_threadline_findings/2` only branches into schema-check logic when `:audit_ledger` is a `map` or `list` (line 898). The canonical/documented config shape — in the mix task moduledoc and in the `mix crosswake.gen.audit` output — is a bare module atom (`audit_ledger: MyApp.Audit.Ledger`). A bare atom reaches the `_ -> []` fallback at line 906, silently running neither the PII check nor the drift check. A host can be misconfigured or have PII fields and the doctor gives a clean bill of health.

3. **CR-04 — Doctor crash on partial keyword config:** `config[:schema] || config["schema"]` at line 899 raises `ArgumentError` when `config` is a keyword list that lacks the `:schema` key, because `keyword["string_key"]` is not a valid operation on keyword lists.

The root fix for CR-02 and CR-04 is a shared `ledger_schema/1` normalization helper that accepts bare atom, keyword list, and map, used consistently in both the doctor and the mix task.

---

_Verified: 2026-06-10T14:00:00Z_
_Verifier: Claude (gsd-verifier)_
