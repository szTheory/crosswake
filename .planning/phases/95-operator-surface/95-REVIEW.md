---
phase: 95-operator-surface
reviewed: 2026-06-10T13:47:13Z
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
  warning: 6
  info: 8
  total: 16
status: issues_found
---

# Phase 95: Code Review Report (Re-review after gap-closure 95-03/95-04)

**Reviewed:** 2026-06-10T13:47:13Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Narrative Findings (AI reviewer)

## Summary

Re-review after gap-closure plans 95-03/95-04. The four prior critical fixes were verified against the actual code and by executing the test suite:

**Fix verification (prior review findings):**

- **Prior CR-01 (false `:actor_ref` PII error) — FIXED and sound.** `check_pii_fields/3` (doctor.ex:1008-1033) now subtracts `@canonical_ledger_columns` from the forbidden set via `MapSet.difference/2` before intersecting. The new canonical-schema regression test (doctor_test.exs:1395-1415) asserts zero PII and zero drift findings for the exact 15-column schema, and the PII test now asserts `refute :actor_ref in offending_keys`. Verified passing.
- **Prior CR-02 (doctor/task config-shape disagreement) — FIXED and sound.** `ledger_schema/1` (doctor.ex:912-930) now normalizes nil, keyword list, map, and bare-atom shapes, matching the mix task's documented `audit_ledger: MyApp.Audit.Ledger` shape. The bare-atom regression test verifies the schema checks run through that shape. Verified passing.
- **Prior CR-03 (structural-term timestamp sort) — FIXED and sound.** `query_events/4` now sorts with an explicit comparator (`compare_ts/2`, threadline.ex:96-129) that dispatches on `NaiveDateTime`/`DateTime` struct types, including mixed pairs via `DateTime.from_naive!/2`. The new month-boundary test supplies out-of-order Dec-2025/Jan-2026/Feb-2026 events and asserts chronological output. Verified passing. (Residual gap: non-struct timestamp values still crash — see WR-06.)
- **Prior CR-04 (keyword config without `:schema` crashes) — PARTIALLY FIXED.** The `config["schema"]`-on-keyword-list `ArgumentError` is gone (`Keyword.keyword?/1` + `Keyword.get/2`), and the `foo: :bar` regression test passes. However, the second half of the prescribed fix — guarding `Code.ensure_loaded?/1` with `is_atom(schema)` — was **not applied**. A non-atom `:schema` value still crashes the doctor. Re-raised as CR-01 below.

**New blocking findings:** the residual `Code.ensure_loaded?/1` crash path (CR-01), and two failing assertions in `doctor_test.exs` at HEAD (CR-02) — the reviewed test file is red, which invalidates any "GREEN" gate claim over these files.

Carried-over warnings WR-01 through WR-05 from the prior review remain unfixed (the gap-closure plans scoped only the criticals); they are restated below so they are not silently dropped.

## Critical Issues

### CR-01: Non-atom `:schema` config value crashes `mix crosswake.doctor` with `FunctionClauseError` — residual half of prior CR-04 left unfixed

**File:** `lib/crosswake/doctor/doctor.ex:893-896,912-930`
**Issue:** `ledger_schema/1` returns whatever value sits under `:schema` (keyword) or `:schema`/`"schema"` (map) without type-checking it. Line 896 then evaluates `if schema && Code.ensure_loaded?(schema)`. Empirically verified in this review: `Code.ensure_loaded?("MyApp.Ledger")` raises `FunctionClauseError` (it requires an atom). So a host configured with a string module name — the classic `config/runtime.exs` + `System.get_env` mistake, e.g. `config :crosswake, :audit_ledger, schema: "MyApp.Audit.Ledger"` or `%{"schema" => "MyApp.Audit.Ledger"}` — crashes the entire doctor run instead of receiving a finding. The prior review's CR-04 fix prescription explicitly included `is_atom(schema)` in the guard; the gap-closure applied the keyword-access half and omitted the atom guard. The new CR-04 regression test (`foo: :bar`) covers a *missing* `:schema` key but not a *non-atom* `:schema` value, so the residual path is untested.
**Fix:**
```elixir
schema_findings =
  if is_atom(schema) and not is_nil(schema) and Code.ensure_loaded?(schema) do
    check_ledger_schema(schema)
  else
    []
  end
```
(Alternatively normalize inside `ledger_schema/1`: return `nil` for any non-atom resolved value.) Add a regression test with `Application.put_env(:crosswake, :audit_ledger, schema: "MyApp.Audit.Ledger")` asserting the doctor returns a report without raising.

### CR-02: Two failing assertions in `doctor_test.exs` at HEAD — the reviewed test file is red

**File:** `test/crosswake/doctor/doctor_test.exs:94,199`
**Issue:** Running `mix test` on the three reviewed test files yields 2 failures, both in `doctor_test.exs`:
- Line 94: `assert report.support.release_policy.crosswake_version == "0.1.0"` — fails; `mix.exs` is at `@version "0.1.2"`.
- Line 199: `assert human =~ "bridge posture: crosswake.bridge@1.0.0"` — fails; `Crosswake.Bridge.Contract` is at `@version "1.1.0"`.

The version bumps did not originate in this phase, but the file under review carries hardcoded version literals that are now stale, and the suite covering the Phase 95 fixes does not pass at HEAD. A red gate cannot honestly verify the gap-closure work (the 95-03 commit message claims GREEN; that claim does not hold for the full file at current HEAD). This is exactly the dishonest-closeout failure mode this project has been burned by before.
**Fix:** Derive the expectations from source-of-truth instead of literals:
```elixir
assert report.support.release_policy.crosswake_version ==
         Mix.Project.config()[:version]

assert human =~ "bridge posture: #{Crosswake.Bridge.Contract.protocol()}@#{Crosswake.Bridge.Contract.version()}"
```

## Warnings

### WR-01: `ledger_posture/0` reads config before `app.start` — `config/runtime.exs` hosts misreported as "Ephemeral" (carried over, unfixed)

**File:** `lib/mix/tasks/crosswake.threadline.ex:51-59,62-72`
**Issue:** `run/1` calls `ledger_posture()` (which reads `Application.get_env(:crosswake, :audit_repo)` / `:audit_ledger`) *before* `Mix.Task.run("app.start")`, and `app.start` is only invoked inside the `:durable` branch. Hosts that configure their Repo and ledger in `config/runtime.exs` (the conventional place) will see "Posture: Ephemeral. No ledger configured." and exit 0 even though a durable ledger exists — a false negative during incident triage.
**Fix:** Call `Mix.Task.run("app.config")` (or `app.start`) at the top of `run/1`, before reading posture.

### WR-02: `render_durable/1` silently drops events whose `tier` is nil or outside `@tier_order` (carried over, unfixed)

**File:** `lib/mix/tasks/crosswake.threadline.ex:139-142`
**Issue:** Events are grouped by tier and then filtered to `["native", "bridge", "phoenix"]`. Any matched event with a missing, misspelled, or future tier value vanishes from the rendered timeline with no indication. For a tool whose contract is "honest append-only sequence reconstruction," silently omitting matched events is a correctness hazard. Note also that the `String.capitalize(tier)` default at line 150 is dead code — `tier` can only be one of `@tier_order` at that point because of the filter at line 141.
**Fix:** Render remaining groups under an `Other (unrecognized tier)` bucket, or print `"N event(s) with unrecognized tier omitted"`.

### WR-03: `guides/threadline.md` still does not exist but is referenced from operator-facing strings (carried over, unfixed)

**File:** `lib/crosswake/support_matrix/support_matrix.ex:280`; `lib/crosswake/doctor/doctor.ex:944,962,1026`
**Issue:** Re-verified this review: `guides/threadline.md` is absent from the repo. The SupportMatrix `docs_anchor` and three Phase 95 doctor hints direct operators to a guide that does not exist. The support_matrix test asserts only string equality of the anchor, not file existence.
**Fix:** Ship `guides/threadline.md` (or repoint anchors to an existing guide), and add a docs-integrity assertion that the anchor file exists.

### WR-04: Leftover `IO.inspect` debug artifact in doctor test (carried over, unfixed)

**File:** `test/crosswake/doctor/doctor_test.exs:184`
**Issue:** `IO.inspect(Enum.filter(report.findings, & &1.severity == :error)); assert report.status == :ok` — leftover debugging fused onto an assertion with a semicolon. Confirmed during this review's test run: it prints `[]` into the test output stream on every run.
**Fix:** Delete the `IO.inspect(...)` call; keep the assertion on its own line.

### WR-05: Phase 95 doctor tests mutate global Application env inside an `async: true` module (carried over, partially improved)

**File:** `test/crosswake/doctor/doctor_test.exs:2,1335-1337,1365-1367,1398-1400,1420-1422`
**Issue:** `Crosswake.DoctorTest` is `async: true`, yet five phase-95 tests call `Application.put_env(:crosswake, :audit_ledger, ...)` — process-global state that races with any other concurrently running async module reading the same key. The `ledger_not_configured` test (1292-1306) now correctly saves and restores the prior value; the other four (PII, drift, canonical-schema, CR-04 keyword) merely `delete_env` in `on_exit` without restoring a pre-existing value, so they can destroy config another test depends on.
**Fix:** Move the env-mutating tests into an `async: false` module, or apply the save/restore pattern from `crosswake.threadline_test.exs:20-37` to all five.

### WR-06: `compare_ts/2` has no clause for non-struct timestamps — string timestamp values crash sort and render

**File:** `lib/mix/tasks/crosswake.threadline.ex:96-129,172-177`
**Issue:** New code introduced by the CR-03 fix. `timestamp_of/1` (lines 102-108) deliberately supports string-keyed events (`Map.get(event, "occurred_at")`, `Map.get(event, "inserted_at")`) — the same string-keyed shapes the rest of the task tolerates for `tier` and `event_type`. But string-keyed events plausibly carry *string* timestamp values (ISO-8601 from a JSONB column or decoded payload). `compare_ts/2` has clauses only for `%NaiveDateTime{}` and `%DateTime{}` struct pairs, so a binary timestamp raises `FunctionClauseError` mid-sort and crashes the task. The render path has the same defect: `NaiveDateTime.to_string(timestamp)` at line 174 raises on a binary. The comparator comment claims `timestamp_of` "Returns a NaiveDateTime or DateTime," but nothing enforces that.
**Fix:** Add a fallback clause that parses or coerces, e.g.:
```elixir
defp compare_ts(a, b), do: NaiveDateTime.compare(coerce_naive(a), coerce_naive(b))

defp coerce_naive(%NaiveDateTime{} = ts), do: ts
defp coerce_naive(%DateTime{} = ts), do: DateTime.to_naive(ts)
defp coerce_naive(ts) when is_binary(ts) do
  case NaiveDateTime.from_iso8601(ts) do
    {:ok, parsed} -> parsed
    _ -> ~N[1970-01-01 00:00:00]
  end
end
defp coerce_naive(_), do: ~N[1970-01-01 00:00:00]
```
and route the render-path timestamp through the same coercion before `NaiveDateTime.to_string/1`.

## Info

### IN-01: Threadline plug detection is an exact-string match (carried over)

**File:** `lib/crosswake/doctor/doctor.ex:935`
**Issue:** `String.contains?(contents, "plug Crosswake.Plug.Threadline")` produces a false `threadline.plug_missing` advisory when the host uses `alias Crosswake.Plug.Threadline` + `plug Threadline`, parentheses, or non-standard spacing.
**Fix:** Match with `~r/plug\s+(Crosswake\.Plug\.)?Threadline\b/` or document the exact-string limitation in the hint.

### IN-02: `--actor-ref` silently ignored when both flags passed; invalid switches discarded (carried over)

**File:** `lib/mix/tasks/crosswake.threadline.ex:41-48,82-95`
**Issue:** The `cond` filter gives `--thread-id` undocumented precedence; passing both silently drops the actor-ref constraint. `_invalid` from `OptionParser.parse/2` is discarded, so typos like `--thread_id` fall through to the generic error.
**Fix:** `Mix.raise` when both flags are provided (or document precedence), and raise on non-empty `invalid`.

### IN-03: Durable posture with zero matching events renders nothing after the header (carried over)

**File:** `lib/mix/tasks/crosswake.threadline.ex:131-132`
**Issue:** When the filter matches no events, output is just "Posture: Durable" — indistinguishable from a rendering failure.
**Fix:** Print `"No events found for <filter>"` when the filtered list is empty.

### IN-04: `audit_ledger_support_truth` telemetry map omits `:authority_source` and `:proof_class` (carried over)

**File:** `lib/crosswake/support_matrix/support_matrix.ex:283-288`
**Issue:** Sibling truth entries (`@notification_support_truth`, `@diagnostic_export_support_truth`, `@auth_contract_truth`) all carry `authority_source` and `proof_class` inside `telemetry`; the audit-ledger entry does not, so consumers reading those keys get `nil` instead of an explicit posture.
**Fix:** Add `authority_source: :diagnostic_evidence_only, proof_class: :advisory` (or intended values) for shape parity.

### IN-05: Timestamp fallback chain duplicated between `timestamp_of/1` and `render_durable/1`

**File:** `lib/mix/tasks/crosswake.threadline.ex:102-108,166-170`
**Issue:** New duplication introduced by the CR-03 fix: the four-step `occurred_at`/`inserted_at` atom/string fallback chain exists once in `timestamp_of/1` (with epoch sentinel) and again inline in `render_durable/1` (without). If the chains drift, the sort key and the displayed timestamp will disagree for the same event.
**Fix:** Have `render_durable/1` call `timestamp_of/1` (or a shared `timestamp_of(event, default)` helper) and treat the sentinel as "no timestamp."

### IN-06: Non-Ecto module configured as schema yields misleading "missing all 15 columns" drift warning (carried over)

**File:** `lib/crosswake/doctor/doctor.ex:989-995`
**Issue:** If the configured module loads but does not export `__schema__/1`, `rescue _ -> []` swallows the error and the drift check reports every canonical column missing — a confusing diagnosis for "this module is not an Ecto schema" — while the PII check silently passes.
**Fix:** Emit a distinct `threadline.ledger_schema_invalid` finding when `function_exported?(schema, :__schema__, 1)` is false.

### IN-07: Ledger config/PII/drift checks are skipped entirely when the install manifest is missing

**File:** `lib/crosswake/doctor/doctor.ex:884`
**Issue:** `phase_95_threadline_findings(nil, _cwd), do: []` gates all threadline checks — including the `:error`-class PII safety check, which depends only on Application config — on install-manifest presence. A host with a misconfigured ledger schema but no install manifest gets no PII finding at all. Only the router-plug check actually needs the manifest.
**Fix:** Split the clause: skip only `check_threadline_plug/1` when the install manifest is nil; always run the ledger config and schema checks.

### IN-08: Durable-path test coverage gaps remain (carried over, narrowed)

**File:** `test/mix/tasks/crosswake.threadline_test.exs:64-103,163-204`
**Issue:** The month-boundary sort test closes the biggest prior gap, but: the `--actor-ref` durable path is still untested, no fixture exercises a non-matching `thread_id` (filter exclusion), the `DateTime` and mixed `DateTime`/`NaiveDateTime` comparator clauses (threadline.ex:118-129) are never executed by any test (all fixtures use `NaiveDateTime`), `MockRepo.all/2` / `MockRepoBoundary.all/2` are dead clauses, and the mock schema struct fields are unused.
**Fix:** Add an `--actor-ref` durable test, a mixed-fixture test with `~U[...]` DateTime values, and a fixture event with a different `thread_id` asserting exclusion.

---

_Reviewed: 2026-06-10T13:47:13Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
