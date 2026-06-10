---
phase: 95-operator-surface
reviewed: 2026-06-10T15:34:10Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - lib/crosswake/doctor/doctor.ex
  - lib/crosswake/support_matrix/support_matrix.ex
  - lib/mix/tasks/crosswake.threadline.ex
  - test/crosswake/doctor/doctor_test.exs
  - test/crosswake/support_matrix/support_matrix_test.exs
  - test/mix/tasks/crosswake.threadline_test.exs
findings:
  critical: 2
  warning: 2
  info: 7
  total: 11
status: issues_found
---

# Phase 95: Code Review Report (fresh review after gap-closure 95-05)

**Reviewed:** 2026-06-10T15:34:10Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Phase 95 delivers the `phase_95_threadline_findings` doctor category (OPER-03), the
`mix crosswake.threadline` Mix task for durable ledger inspection, and the
`audit_ledger_support_truth` SupportMatrix entry. Gap-closure plan 95-05 added an
`is_atom(schema)` guard before `Code.ensure_loaded?/1` at `doctor.ex:896` and a
companion regression test that proves a string `:schema` value does not crash the doctor.
Both are present and correct.

**Pre-existing failures excluded per instructions:** `doctor_test.exs` lines ~94 and ~199
carry hardcoded version literals (`"0.1.0"` and `"1.0.0"`) that are now stale, causing two
pre-existing test failures. These are not counted as new findings.

**New issues found:** Two BLOCKER-class crashes in `render_durable/1` of the Mix task that
would fire the first time any host uses the canonical `:utc_datetime_usec` ledger schema in
durable mode. Two WARNING-level issues affect test reliability and task schema normalization.
Seven INFO-level quality and defensive-programming gaps round out the report.

---

## Critical Issues

### CR-01: `NaiveDateTime.to_string/1` crashes on `%DateTime{}` timestamps in `render_durable/1`

**File:** `lib/mix/tasks/crosswake.threadline.ex:174`

**Issue:** `render_durable/1` formats event timestamps with
`NaiveDateTime.to_string(timestamp)`. `NaiveDateTime.to_string/1` accepts only
`%NaiveDateTime{}` structs; it raises `FunctionClauseError` for a `%DateTime{}` argument.
The canonical audit ledger schema uses `:utc_datetime_usec` for `:occurred_at` and
`:recorded_at`, which Ecto materialises as `%DateTime{}` structs. In production, any host
running `mix crosswake.threadline --thread-id <id>` with the canonical schema will crash on
every event render — the task becomes completely unusable in durable mode.

The test suite exercises only `~N[...]` (`NaiveDateTime`) values via `inserted_at` and never
sets `:occurred_at`, so this bug is untested and invisible in CI.

**Fix:**
```elixir
# Replace line 174 — use String interpolation which works for both struct types
timestamp_str =
  if timestamp do
    " (#{timestamp})"
  else
    ""
  end
```

---

### CR-02: `compare_ts/2` has no catch-all — crashes on non-struct timestamps

**File:** `lib/mix/tasks/crosswake.threadline.ex:96,115-129`

**Issue:** `compare_ts/2` defines four pattern-match clauses for
`{NaiveDateTime, NaiveDateTime}`, `{DateTime, DateTime}`, `{NaiveDateTime, DateTime}`, and
`{DateTime, NaiveDateTime}`. There is no catch-all. `timestamp_of/1` deliberately falls
through to string-keyed map fields (`Map.get(event, "occurred_at")` and
`Map.get(event, "inserted_at")`); if those fields contain ISO-8601 string values (plausible
for JSON-decoded or non-typed Ecto virtual fields), `compare_ts/2` receives two strings and
raises `FunctionClauseError`, crashing `Enum.sort_by/3` mid-sort and aborting the task.

The same shape issue applies in `render_durable/1` at line 174: if a string timestamp
reaches `NaiveDateTime.to_string/1` it also crashes (covered independently in CR-01 via the
DateTime variant; the string variant is a second crash path in the same line).

**Fix:**
```elixir
# Add a catch-all clause after the four typed clauses in compare_ts/2:
defp compare_ts(_a, _b), do: :eq
```

Or, for a more defensive approach that also coerces string timestamps in render_durable:

```elixir
defp compare_ts(a, b) do
  NaiveDateTime.compare(to_naive(a), to_naive(b))
end

defp to_naive(%NaiveDateTime{} = ts), do: ts
defp to_naive(%DateTime{} = ts), do: DateTime.to_naive(ts)
defp to_naive(ts) when is_binary(ts) do
  case NaiveDateTime.from_iso8601(ts) do
    {:ok, parsed} -> parsed
    _ -> ~N[1970-01-01 00:00:00]
  end
end
defp to_naive(_), do: ~N[1970-01-01 00:00:00]
```

---

## Warnings

### WR-01: `doctor_test.exs` uses `async: true` while six tests mutate global `Application` env

**File:** `test/crosswake/doctor/doctor_test.exs:2,1335,1365,1398,1420,1439`

**Issue:** The module declares `async: true` but the `phase_95_threadline_findings` describe
block contains six tests that call `Application.put_env(:crosswake, :audit_ledger, ...)` and
`Application.delete_env(:crosswake, :audit_ledger)`. Because `Doctor.run/1` reads
`:audit_ledger` via `Application.get_env` (line 890 of doctor.ex), any other test running
concurrently that also calls `Doctor.run/1` will observe a spurious `:audit_ledger` value
injected by a sibling test, triggering unexpected `threadline.pii_forbidden_field_present` or
`threadline.ledger_schema_drift` findings and causing false failures. The suite is
non-deterministic under parallel execution.

The companion task test (`crosswake.threadline_test.exs:2`) correctly uses `async: false` for
the same reason.

**Fix:** Move the `phase_95_threadline_findings` tests into a separate file with
`async: false`:
```elixir
# test/crosswake/doctor/doctor_threadline_test.exs
defmodule Crosswake.Doctor.ThreadlineTest do
  use ExUnit.Case, async: false
  # ... move phase_95 tests here ...
end
```

---

### WR-02: `ledger_posture/0` in the Mix task passes raw `:audit_ledger` config to `repo.all/1`

**File:** `lib/mix/tasks/crosswake.threadline.ex:63-79`

**Issue:** `ledger_posture/0` reads `:audit_ledger` verbatim from `Application.get_env` and
passes it unmodified to `repo.all(schema)` at line 79. Ecto's `Repo.all/1` requires a
queryable — either a bare module atom or an `Ecto.Query.t()`. If a host configures
`:audit_ledger` as a keyword list (`[schema: MyApp.Audit.Ledger]`) or a map
(`%{schema: MyApp.Audit.Ledger}`), the task calls `repo.all([schema: MyApp.Audit.Ledger])`
which Ecto cannot interpret and raises at runtime. The doctor counterpart correctly normalises
through `ledger_schema/1`; the task lacks this step entirely.

**Fix:**
```elixir
def ledger_posture do
  repo = Application.get_env(:crosswake, :audit_repo)
  raw = Application.get_env(:crosswake, :audit_ledger)
  schema = normalize_ledger_schema(raw)

  if repo && schema do
    {:durable, repo, schema}
  else
    :ephemeral
  end
end

# Mirror doctor.ex ledger_schema/1 normalisation:
defp normalize_ledger_schema(nil), do: nil
defp normalize_ledger_schema(cfg) when is_list(cfg) do
  if Keyword.keyword?(cfg), do: Keyword.get(cfg, :schema), else: nil
end
defp normalize_ledger_schema(cfg) when is_map(cfg) do
  Map.get(cfg, :schema) || Map.get(cfg, "schema")
end
defp normalize_ledger_schema(cfg)
     when is_atom(cfg) and not is_nil(cfg) and not is_boolean(cfg), do: cfg
defp normalize_ledger_schema(_), do: nil
```

---

## Info

### IN-01: `ledger_posture/0` reads Application env before `app.start` — runtime.exs hosts report false "Ephemeral"

**File:** `lib/mix/tasks/crosswake.threadline.ex:51-59,63-72`

**Issue:** `run/1` calls `ledger_posture()` — which reads `:audit_repo` and `:audit_ledger`
from `Application.get_env` — before invoking `Mix.Task.run("app.start")`. `app.start` is
called only inside the `:durable` branch (line 56). Hosts that configure their Repo and
ledger in `config/runtime.exs` (the conventional production location) will read a nil env
before the application boots and see `"Posture: Ephemeral. No ledger configured."`, even
though a durable ledger exists. This produces a false negative during incident triage.

**Fix:** Call `Mix.Task.run("app.config")` at the top of `run/1`, before reading posture.

---

### IN-02: `render_durable/1` silently drops events with unrecognized or nil `tier`

**File:** `lib/mix/tasks/crosswake.threadline.ex:139-142`

**Issue:** Events are grouped by tier and then filtered against `["native", "bridge",
"phoenix"]`. Events with a nil, misspelled, or future tier value are silently omitted from
the rendered timeline. For an "honest append-only sequence reconstruction" tool, silent
omission is a correctness hazard. The `String.capitalize(tier)` fallback at line 150 is
also dead code — `tier` is always one of `@tier_order` at that point due to the filter.

**Fix:** Render remaining groups under an `"Other (unrecognized tier)"` bucket, or print
a summary line: `"N event(s) with unrecognized tier omitted"`.

---

### IN-03: `guides/threadline.md` is referenced in operator-facing hints but does not exist

**File:** `lib/crosswake/support_matrix/support_matrix.ex:280`; `lib/crosswake/doctor/doctor.ex:944,962,1026`

**Issue:** Three Phase-95 doctor findings hint at `"guides/threadline.md"` and the
SupportMatrix `docs_anchor` points there. The file does not exist in the repository. No test
asserts the anchor file is present.

**Fix:** Create `guides/threadline.md` (or repoint anchors to an existing guide), and add a
docs-integrity assertion that the file exists.

---

### IN-04: `compare_ts/2` `DateTime`/`NaiveDateTime` mixed-pair clauses are untested

**File:** `test/mix/tasks/crosswake.threadline_test.exs:115-129`

**Issue:** `compare_ts/2` defines clauses for `{NaiveDateTime, DateTime}` (line 121) and
`{DateTime, NaiveDateTime}` (line 126), and `{DateTime, DateTime}` (line 118). Every test
fixture uses only `~N[...]` `NaiveDateTime` values, so these three clauses are never
exercised by the test suite. If they contain a regression (e.g., wrong timezone assumption
in `DateTime.from_naive!/2`), it would go undetected.

**Fix:** Add a test fixture that includes at least one `%DateTime{}` timestamp (e.g., using
`~U[2026-06-10 12:00:00Z]` for `:occurred_at`) to exercise the DateTime comparison path and
the `NaiveDateTime.to_string`/`DateTime` render path simultaneously.

---

### IN-05: Timestamp fallback chain is duplicated between `timestamp_of/1` and `render_durable/1`

**File:** `lib/mix/tasks/crosswake.threadline.ex:102-108,166-170`

**Issue:** The four-step `occurred_at`/`inserted_at` atom/string fallback chain appears once
in `timestamp_of/1` (with epoch sentinel) and again inline in `render_durable/1` (without
sentinel). If these chains drift, the sort key and the displayed timestamp will disagree for
the same event.

**Fix:** Have `render_durable/1` call `timestamp_of/1` for consistency:
```elixir
timestamp = timestamp_of(event)
timestamp_str = if timestamp == ~N[1970-01-01 00:00:00], do: "", else: " (#{timestamp})"
```

---

### IN-06: Non-Ecto module yields a misleading "missing all 15 columns" drift warning

**File:** `lib/crosswake/doctor/doctor.ex:989-995`

**Issue:** If the configured schema module loads but does not implement `__schema__/1`,
`rescue _ -> []` swallows the error and `check_schema_drift/2` reports every canonical
column as missing — a confusing diagnosis for "this module is not an Ecto schema." The PII
check silently passes at the same time.

**Fix:** Emit a distinct `threadline.ledger_schema_invalid` advisory finding when
`function_exported?(schema, :__schema__, 1)` is false, instead of silently returning an
empty field list.

---

### IN-07: Ledger PII check skipped entirely when install manifest is missing

**File:** `lib/crosswake/doctor/doctor.ex:884`

**Issue:** `phase_95_threadline_findings(nil, _cwd), do: []` gates all threadline checks —
including the `:error`-class PII safety check — on install-manifest presence. The PII check
depends only on `Application.get_env`, not on the install manifest. A host with a
misconfigured schema that contains PII-forbidden fields but has not yet run
`mix crosswake.install` will receive no PII finding.

**Fix:** Split the guard: skip only `check_threadline_plug/1` when install manifest is nil;
always run `check_audit_ledger_configured/1` and the ledger schema checks.

---

_Reviewed: 2026-06-10T15:34:10Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
