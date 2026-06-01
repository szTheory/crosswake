# Phase 53: Release Continuity and Closeout Hardening - Pattern Map

**Mapped:** 2026-06-01  
**Files analyzed:** 12  
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/planning/closeout_verifier.ex` (implied) | service | file-I/O, batch, transform | `lib/crosswake/doctor/publish_readiness.ex` | partial (flow-match) |
| `lib/mix/tasks/closeout.verify.ex` (implied) | utility | request-response | `lib/mix/tasks/crosswake.doctor.ex` | role-match |
| `test/crosswake/planning/closeout_verifier_test.exs` (implied) | test | file-I/O, batch | `test/crosswake/planning/milestone_arc_closeout_parity_test.exs` | exact (domain-match) |
| `lib/crosswake/doctor/publish_readiness.ex` | service | file-I/O, transform | `lib/crosswake/doctor/publish_readiness.ex` | exact |
| `lib/mix/tasks/crosswake.doctor.ex` | utility | request-response | `lib/mix/tasks/crosswake.doctor.ex` | exact |
| `test/crosswake/doctor/publish_readiness_test.exs` | test | request-response, transform | `test/crosswake/doctor/publish_readiness_test.exs` | exact |
| `test/crosswake/planning/milestone_arc_closeout_parity_test.exs` | test | file-I/O, transform | `test/crosswake/planning/milestone_arc_closeout_parity_test.exs` | exact |
| `test/crosswake/planning/summary_frontmatter_test.exs` | test | file-I/O, transform | `test/crosswake/planning/summary_frontmatter_test.exs` | exact |
| `test/support/proof_assertions.ex` | utility | transform | `test/support/proof_assertions.ex` | exact |
| `CHANGELOG.md` | config | transform | `CHANGELOG.md` | exact |
| `.planning/milestones/v3.6-CLOSEOUT.md` | config | file-I/O | `.planning/milestones/v3.6-CLOSEOUT.md` | exact |
| `.github/workflows/phase52-proof.yml` | config | event-driven, batch | `.github/workflows/phase52-proof.yml` | exact |

## Pattern Assignments

### `lib/crosswake/planning/closeout_verifier.ex` (service, file-I/O/batch/transform)
**Analog:** `lib/crosswake/doctor/publish_readiness.ex`

**Imports + typed structs** (`lib/crosswake/doctor/publish_readiness.ex:11`):
```elixir
alias Crosswake.Doctor.Check
alias Crosswake.OperatorInspection
alias Crosswake.SupportMatrix
```
Use nested `Report`/`Check` structs with `@enforce_keys` and explicit `@type` contracts (`:27-92`).

**Core run pipeline** (`lib/crosswake/doctor/publish_readiness.ex:94`):
```elixir
def run(opts \\ []) do
  cwd = Keyword.get(opts, :cwd, File.cwd!())
  support_matrix = Keyword.get_lazy(opts, :support_matrix, &SupportMatrix.canonical/0)
  inspection = inspection(opts)
  checks = build_checks(cwd, support_matrix, inspection, opts)
  status = if Enum.any?(checks, & &1.blocking), do: :not_ready, else: :ready
  %Report{schema_version: @schema_version, status: status, summary: summary(checks), checks: checks}
end
```

**Fail-closed check building style** (`lib/crosswake/doctor/publish_readiness.ex:174`): build error lists with deterministic `id`, `code`, `hint`, `details`; one check object per concern.

### `lib/mix/tasks/closeout.verify.ex` (utility, request-response)
**Analog:** `lib/mix/tasks/crosswake.doctor.ex` (secondary: `lib/mix/tasks/crosswake.inspect.ex`)

**Task skeleton + option parsing** (`lib/mix/tasks/crosswake.doctor.ex:1`):
```elixir
defmodule Mix.Tasks.Crosswake.Doctor do
  use Mix.Task
  @switches [...]
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)
    if invalid != [], do: Mix.raise("invalid options: #{inspect(invalid)}")
    ...
  end
end
```

**Output + non-zero failure contract** (`lib/mix/tasks/crosswake.doctor.ex:48`):
```elixir
Mix.shell().info(output)
if report.status == :error do
  Mix.raise("Crosswake doctor found blocking issues")
end
```

### `test/crosswake/planning/closeout_verifier_test.exs` (test, file-I/O/batch)
**Analog:** `test/crosswake/planning/milestone_arc_closeout_parity_test.exs`

**Path constants + required contract arrays** (`.../milestone_arc_closeout_parity_test.exs:4-50`): keep required keys and queue terms as module attributes.

**Artifact assertions with explicit messages** (`.../milestone_arc_closeout_parity_test.exs:99`):
```elixir
assert Regex.match?(~r/^#{Regex.escape(key)}:/m, frontmatter),
       "#{@closeout_path} frontmatter is missing #{key}:"
```

**Reusable parsing helpers** (`.../milestone_arc_closeout_parity_test.exs:156-183`): section extraction and frontmatter parsing via `Regex.run`.

### `lib/crosswake/doctor/publish_readiness.ex` (service)
**Analog:** self

**Stable ids and categorized checks** (`lib/crosswake/doctor/publish_readiness.ex:204-226`) with human message + hint + docs refs + structured details.

### `lib/mix/tasks/crosswake.doctor.ex` (utility)
**Analog:** self

**Router resolution / guardrail errors** (`lib/mix/tasks/crosswake.doctor.ex:55-67`): explicit `Mix.raise` for missing/unloaded modules.

### `test/crosswake/doctor/publish_readiness_test.exs` (test)
**Analog:** self

**Contract-wide shape assertions** (`test/crosswake/doctor/publish_readiness_test.exs:77-111`) and code-prefix invariants (`:113-135`).

### `test/crosswake/planning/milestone_arc_closeout_parity_test.exs` (test)
**Analog:** self

**Closeout enforcement wording lock** (`...:137-154`): assert exact fail-closed terms listed in Phase 53 target section.

### `test/crosswake/planning/summary_frontmatter_test.exs` (test)
**Analog:** self

**Frontmatter shape parser + loud-fail malformed key** (`test/crosswake/planning/summary_frontmatter_test.exs:72-95`), regex-based `requirements-completed` enforcement (`:44-46`).

### `test/support/proof_assertions.ex` (utility)
**Analog:** self

**Stable-id message format** (`test/support/proof_assertions.ex:8-13`) and reusable assert helpers for JSON normalization and file/content parity (`:15-67`).

### `CHANGELOG.md` (config)
**Analog:** self

**Public truth split pattern** (`CHANGELOG.md:8-14`): explicit “planning milestones vs Hex releases” + `[Unreleased]` boundary before published versions.

### `.planning/milestones/v3.6-CLOSEOUT.md` (config)
**Analog:** self

**Machine-readable frontmatter contract** (`.planning/milestones/v3.6-CLOSEOUT.md:1-39`) and deterministic fail-closed target list (`:137-153`).

### `.github/workflows/phase52-proof.yml` (config, event-driven)
**Analog:** self

**Two-lane proof topology** (`.github/workflows/phase52-proof.yml:36-83`): merge-blocking hermetic job + advisory `continue-on-error` job with explicit non-claim comments.

## Shared Patterns

### Stable Check Identity + Actionable Failures
**Source:** `test/support/proof_assertions.ex:8-13` and `lib/crosswake/doctor/publish_readiness.ex:204-226`  
**Apply to:** closeout verifier module/tests/task output.

### Fail-Closed Planning Artifact Validation
**Source:** `test/crosswake/planning/milestone_arc_closeout_parity_test.exs:99-154` and `test/crosswake/planning/summary_frontmatter_test.exs:44-95`  
**Apply to:** all closeout checks for roadmap/requirements/state/summary/validation/thread-release continuity.

### Thin Mix Task Wrapper
**Source:** `lib/mix/tasks/crosswake.doctor.ex:23-53` and `lib/mix/tasks/crosswake.inspect.ex:19-42`  
**Apply to:** `mix closeout.verify` should parse options, call shared module, render, and `Mix.raise` on blocking results.

### Proof Lane Split (Merge-blocking + Advisory)
**Source:** `.github/workflows/phase52-proof.yml:37-83`  
**Apply to:** any new Phase 53 workflow or updated proof lane wiring.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| none | — | — | Existing codebase already has close matches for all explicit and implied targets. |

## Metadata

**Analog search scope:** `lib/crosswake`, `lib/mix/tasks`, `test/crosswake`, `test/support`, `.github/workflows`, `.planning/milestones`  
**Files scanned:** 11 primary analog files (+ phase context/research artifacts)  
**Pattern extraction date:** 2026-06-01
