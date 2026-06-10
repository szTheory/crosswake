# Phase 96: Docs-Contract + Proof - Pattern Map

**Mapped:** 2026-06-10
**Files analyzed:** 7 new/modified files
**Analogs found:** 7 / 7

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `guides/threadline.md` | docs (restructure) | static | `guides/companions.md` | exact — "Core Contract First" house style |
| `test/crosswake/proof/phase96_threadline_docs_contract_test.exs` | test (hermetic proof) | request-response | `test/crosswake/proof/phase91_threadline_contract_closeout_test.exs` + `test/crosswake/guides/release_boundaries_test.exs` | exact — same proof lane + contains-exact pattern |
| `examples/phoenix_host/lib/crosswake_example/audit/ledger.ex` | model (committed gen.audit output) | CRUD | `examples/phoenix_host/lib/crosswake_example/saas_portal/handoff_audit_event.ex` | role-match — same Ecto schema + changeset pattern |
| `examples/phoenix_host/priv/repo/migrations/TIMESTAMP_create_crosswake_audit_events.exs` | migration | batch | `examples/phoenix_host/priv/repo/migrations/20260602060100_create_sigra_handoff_audit_events.exs` | role-match — same SQLite migration pattern |
| `examples/phoenix_host/test/crosswake_example/threadline/phase96_example_host_ledger_proof_test.exs` | test (advisory Ecto-backed proof) | CRUD + request-response | `test/mix/tasks/crosswake.threadline_test.exs` + `examples/phoenix_host/test/crosswake_example/flashcards_test.exs` | exact — same Mix.Task.reenable + Repo.delete_all cleanup |
| `.github/workflows/phase96-proof.yml` | config (CI workflow, merge-blocking) | event-driven | `.github/workflows/phase75-closeout-gate.yml` + `.github/workflows/phase73-proof.yml` | exact — pinned-SHA, compile-then-test, `push: ['**']` + `pull_request` triggers |
| `.github/workflows/phase96-proof-advisory.yml` | config (CI workflow, advisory) | event-driven | `.github/workflows/phase23-proof.yml` (advisory job section) | exact — schedule/dispatch-gated job, `::notice` annotation |

---

## Pattern Assignments

### `guides/threadline.md` (docs, restructure)

**Analog:** `guides/companions.md`

**H2 outline pattern** (companions.md lines 1–10):
```markdown
# Companion Integrations

Crosswake companions are first-party, typed integration seams. They are not a generic plugin bus, and they do not override route ownership. ...

## Core Contract First

Every companion implements `Crosswake.Companion` and lives in-tree under ...
```

**Key style rules extracted:**
- Opening paragraph states the thing honestly with explicit non-goals inline ("not a generic plugin bus")
- `## Core Contract First` is the first H2 — place the contract (fields, header, event names) before any operational how-to
- A "What This Guide Does Not Claim" section (non-goals as H2) appears mid-guide, not as a footer footnote
- No "Note:" / "Tip:" callout boxes — plain section text only
- `host-owned` vocabulary: `config :crosswake, :companions, [...]` — always host-configures, never Crosswake-owned

**Existing opening sentence (keep verbatim — anchor for support_matrix_test.exs):**
```
Threadline is Crosswake's honest, PII-free correlation thread across the three
tiers of a Crosswake application: Native -> Bridge -> Phoenix.
```
Source: `guides/threadline.md` line 3.

**Existing Doctor findings table to keep intact** (lines 55–62):
```markdown
| Code | Severity | Meaning |
| --- | --- | --- |
| `threadline.plug_missing` | advisory | ... |
| `threadline.ledger_not_configured` | advisory | ... |
| `threadline.pii_forbidden_field_present` | error | ... |
| `threadline.ledger_schema_drift` | warning | ... |
| `threadline.ledger_schema_invalid` | advisory | ... |
```

---

### `test/crosswake/proof/phase96_threadline_docs_contract_test.exs` (test, hermetic proof)

**Analogs:**
- `test/crosswake/proof/phase91_threadline_contract_closeout_test.exs` — module structure, `async: false`, aliasing public API
- `test/crosswake/guides/release_boundaries_test.exs` — `File.read!` + `assert guide =~` contains-exact pattern
- `test/crosswake/support_matrix/support_matrix_test.exs` lines 267–273 — custom failure message pattern
- `test/crosswake/proof/phase52_operator_truth_test.exs` lines 215–221 — hermetic lane self-guard

**Module declaration pattern** (phase91, lines 1–3):
```elixir
defmodule Crosswake.Proof.Phase96ThreadlineDocsContractTest do
  use ExUnit.Case, async: false
```

**Contains-exact pattern** (release_boundaries_test.exs lines 1–30):
```elixir
test "guide surfaces publish the four change classes and rebuild-first wording" do
  install = File.read!("guides/install.md")
  assert install =~ "Do I need to rebuild?"
  assert install =~ "docs-only"
end
```
Note: `File.read!` uses a repo-root-relative path (no `Path.join/__DIR__`). ExUnit runs from repo root.

**Custom failure message pattern** (support_matrix_test.exs lines 267–273):
```elixir
test "entry docs_anchor file exists in the repository" do
  [entry] = Crosswake.SupportMatrix.audit_ledger_support_truth()
  [path | _fragment] = String.split(entry.docs_anchor, "#", parts: 2)

  assert File.exists?(path),
         "docs_anchor #{entry.docs_anchor} is referenced by doctor hints but #{path} does not exist"
end
```

**Hermetic lane self-guard pattern** (phase52, lines 215–221):
```elixir
test "hermetic lane guard keeps module untagged at file level and env-independent" do
  source = File.read!(__ENV__.file)

  refute Regex.match?(~r/^\s*@moduletag\s+:/m, source)
  refute String.contains?(source, "Crosswake" <> "Example.")
  refute String.contains?(source, "MIX_INCLUDE_" <> "RULESTEAD")
  refute String.contains?(source, "MIX_INCLUDE_" <> "RINDLE")
end
```
For phase96: keep the first two `refute` lines; the last two env-var checks are phase52-specific and should be omitted.

**Code-derived parity pattern** (support_matrix_test.exs lines 287–303):
```elixir
test "entry telemetry.forbidden_metadata_keys matches Crosswake.Threadline.Telemetry" do
  alias Crosswake.Threadline.Telemetry, as: ThreadlineTelemetry
  [entry] = Crosswake.SupportMatrix.audit_ledger_support_truth()
  assert entry.telemetry.forbidden_metadata_keys == ThreadlineTelemetry.forbidden_metadata_keys()
end
```
Phase96 adapts this: instead of asserting equality between two structs, it asserts each key from the public accessor appears in the guide string via `Atom.to_string(key)`.

**Loop-per-key pattern to copy:**
```elixir
for key <- Crosswake.Threadline.Telemetry.metadata_keys() do
  key_str = Atom.to_string(key)
  assert guide =~ key_str,
         "guides/threadline.md must document telemetry metadata key '#{key_str}' — " <>
         "add it to the Propagation Contract section"
end
```

**Hardcoded ledger column list with co-location comment** (from RESEARCH.md skeleton):
```elixir
# Co-location note: this list must stay in sync with @canonical_ledger_columns
# in lib/crosswake/doctor/doctor.ex. If a third consumer needs the list,
# extract Crosswake.Audit.Ledger.canonical_columns/0 — but not until then.
@canonical_ledger_columns [
  "thread_id", "correlation_id", "route_id", "actor_ref", "actor_kind",
  "event_class", "event_type", "outcome", "provenance", "occurred_at",
  "recorded_at", "idempotency_key", "metadata", "row_hash", "prev_hash"
]
```

---

### `examples/phoenix_host/lib/crosswake_example/audit/ledger.ex` (model, CRUD)

**Analog:** `priv/templates/crosswake/audit/ledger.ex.eex` (the exact template that generates it)

This file IS the rendered output of the template. Copy the template and substitute `<%= app_module %>` with `CrosswakeExample`.

**Full schema structure** (template lines 1–129):
```elixir
defmodule CrosswakeExample.Audit.Ledger do
  @moduledoc """
  Standard host-owned audit ledger for Crosswake events.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @forbidden_keys [
    "email", "phone", "ip_address", "ssn", "name", "first_name", "last_name", "address",
    :email, :phone, :ip_address, :ssn, :name, :first_name, :last_name, :address
  ]

  schema "crosswake_audit_events" do
    field :thread_id, :string
    field :correlation_id, :string
    field :route_id, :string
    field :actor_ref, :string
    field :actor_kind, :string
    field :event_class, :string
    field :event_type, :string
    field :outcome, :string
    field :provenance, Ecto.Enum, values: [:device_claimed, :backend_accepted]
    field :occurred_at, :utc_datetime_usec
    field :recorded_at, :utc_datetime_usec
    field :idempotency_key, :string
    field :metadata, :map
    field :row_hash, :string
    field :prev_hash, :string
  end
  ...
  def record_in_multi(multi, name, attrs) do
    Ecto.Multi.insert(multi, name, changeset(%__MODULE__{}, attrs))
  end
end
```

**Note on `tier` field (RESEARCH.md Open Question #1):** The template does not include `tier` in the base 15 columns. The planner must decide whether to add `field :tier, :string` as an example-host extension beyond the base contract (consistent with how Sigra schemas add domain columns). The PROOF-02 test seeds events with a `tier` key. If `tier` is not in the schema, the `cast/3` will silently drop it and the threadline task will group all events under "Other (unrecognized tier)."

**Secondary analog for module shape:** `examples/phoenix_host/lib/crosswake_example/saas_portal/handoff_audit_event.ex` — same `use Ecto.Schema` + `import Ecto.Changeset` + `schema "table_name" do` + `changeset/2` pattern.

---

### `examples/phoenix_host/priv/repo/migrations/TIMESTAMP_create_crosswake_audit_events.exs` (migration)

**Analog:** `priv/templates/crosswake/audit/migration.exs.eex` (the exact template)

**Full migration structure** (template lines 1–25):
```elixir
defmodule CrosswakeExample.Repo.Migrations.CreateCrosswakeAuditEvents do
  use Ecto.Migration

  def change do
    create table(:crosswake_audit_events) do
      add :thread_id, :string, null: false
      add :correlation_id, :string, null: false
      add :route_id, :string, null: false
      add :actor_ref, :string, null: false
      add :actor_kind, :string, null: false
      add :event_class, :string, null: false
      add :event_type, :string, null: false
      add :outcome, :string, null: false
      add :provenance, :string, null: false
      add :occurred_at, :utc_datetime_usec, null: false
      add :recorded_at, :utc_datetime_usec, null: false
      add :idempotency_key, :string, null: false
      add :metadata, :map
      add :row_hash, :string
      add :prev_hash, :string
    end

    create unique_index(:crosswake_audit_events, [:idempotency_key])
  end
end
```

**Timestamp format:** Use the same `YYYYMMDDHHMMSS` pattern as existing migrations (e.g., `20260609020455`). Pick a timestamp later than the most recent migration (`20260609020457`) — e.g., `20260611000000`.

**Note on `tier` migration:** If `tier` is added to the schema, add `add :tier, :string` here as well (nullable, no `null: false` — it is an optional host extension beyond LEDG-02).

---

### `examples/phoenix_host/test/crosswake_example/threadline/phase96_example_host_ledger_proof_test.exs` (test, advisory Ecto-backed proof)

**Analogs:**
- `test/mix/tasks/crosswake.threadline_test.exs` — `Application.put_env` setup + `Mix.Task.reenable` + `on_exit` restore pattern
- `examples/phoenix_host/test/crosswake_example/flashcards_test.exs` — `Repo.delete_all` in `setup do` (not `on_exit`), `async: false` implied

**Module declaration + async flag** (threadline_test.exs line 1–3):
```elixir
defmodule CrosswakeExample.Threadline.Phase96ExampleHostLedgerProofTest do
  use ExUnit.Case, async: false  # ecto_sqlite3 has no sandbox async support
```

**Application.put_env + on_exit restore pattern** (crosswake.threadline_test.exs lines 19–40):
```elixir
setup do
  prev_repo = Application.get_env(:crosswake, :audit_repo)
  prev_ledger = Application.get_env(:crosswake, :audit_ledger)
  Application.delete_env(:crosswake, :audit_repo)
  Application.delete_env(:crosswake, :audit_ledger)

  on_exit(fn ->
    if prev_repo do
      Application.put_env(:crosswake, :audit_repo, prev_repo)
    else
      Application.delete_env(:crosswake, :audit_repo)
    end

    if prev_ledger do
      Application.put_env(:crosswake, :audit_ledger, prev_ledger)
    else
      Application.delete_env(:crosswake, :audit_ledger)
    end
  end)

  :ok
end
```
For phase96 PROOF-02: use `Application.put_env` (not `delete_env`) in the setup body to set the real `CrosswakeExample.Repo` and `CrosswakeExample.Audit.Ledger`.

**Repo.delete_all cleanup pattern** (flashcards_test.exs lines 7–12):
```elixir
setup do
  Repo.delete_all(CrosswakeExample.Flashcards.Progress)
  Repo.delete_all(CrosswakeExample.Flashcards.Card)
  Repo.delete_all(CrosswakeExample.Flashcards.Deck)
  :ok
end
```
For phase96: `Repo.delete_all(CrosswakeExample.Audit.Ledger)` at the TOP of setup, before `Application.put_env` calls.

**Mix.Task.reenable pattern** (crosswake.threadline_test.exs lines 129–133):
```elixir
test "prints durable posture and tree-formatted events grouped by tier" do
  output =
    capture_io(fn ->
      Mix.Task.reenable(@task)
      Mix.Task.run(@task, ["--thread-id", "test-thread-123"])
    end)
```
For phase96 PROOF-02: use `Mix.Shell.Process` instead of `capture_io`. The shell-swap + reenable pattern:
```elixir
Mix.Shell.Process.flush()
original_shell = Mix.shell()
Mix.shell(Mix.Shell.Process)
Mix.Task.reenable("crosswake.threadline")
Mix.Task.run("crosswake.threadline", ["--thread-id", thread_id])
Mix.shell(original_shell)
assert_received {:mix_shell, :info, [msg]}
assert msg =~ "Posture: Durable"
```

**record_in_multi/3 seed pattern** (from RESEARCH.md skeleton, confirmed from template lines 126–128):
```elixir
{:ok, _result} =
  Ecto.Multi.new()
  |> CrosswakeExample.Audit.Ledger.record_in_multi(:audit_event, %{
    thread_id: thread_id,
    ...
    provenance: :backend_accepted,
    occurred_at: DateTime.utc_now(),
    recorded_at: DateTime.utc_now(),
    idempotency_key: "idem-proof-96-#{System.unique_integer([:positive])}"
  })
  |> Repo.transaction()
```

---

### `.github/workflows/phase96-proof.yml` (config, merge-blocking CI workflow)

**Primary analog:** `.github/workflows/phase75-closeout-gate.yml` (cleanest hermetic Elixir-only workflow)
**Secondary analog:** `.github/workflows/phase73-proof.yml` (multi-job structure with merge-blocking + advisory)

**Trigger shape** — copy `push: branches: ['**']` from phase90-proof.yml (D-02 says "phase90 shape"); note phase75 only triggers on `main` push + PR:
```yaml
on:
  push:
    branches:
      - '**'
  pull_request:
```

**Permissions + job structure** (phase75-closeout-gate.yml lines 1–35):
```yaml
name: Phase 75 Closeout Gate

permissions:
  contents: read

on:
  pull_request:
  push:
    branches:
      - main

jobs:
  merge-blocking-closeout-gate:
    name: merge-blocking phase 75 closeout gate
    runs-on: ubuntu-latest
    timeout-minutes: 10

    steps:
      - name: Checkout
        uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6

      - name: Setup BEAM
        uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1
        with:
          elixir-version: "1.19.5"
          otp-version: "27.3"

      - name: Install Elixir dependencies
        run: mix deps.get

      - name: Compile (warnings as errors)
        run: mix compile --warnings-as-errors

      - name: Run closeout verification
        run: mix closeout.verify
```

**Exact pinned SHA values to use** (phase73-proof.yml lines 38–43, phase75-closeout-gate.yml lines 20–23):
```yaml
uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6
uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1
```

**Job id for branch protection** (D-02, must be exact):
```yaml
jobs:
  merge-blocking-threadline-docs-contract-proof:
```

**multi-file `mix test` step pattern** (phase23-proof.yml lines 88–93):
```yaml
- name: Run hermetic threadline docs contract proof
  run: |
    mix test \
      test/crosswake/proof/phase91_threadline_contract_closeout_test.exs \
      test/crosswake/proof/phase92_server_propagation_closeout_test.exs \
      test/crosswake/proof/phase96_threadline_docs_contract_test.exs \
      test/crosswake/plug/threadline_test.exs \
      ...
```

---

### `.github/workflows/phase96-proof-advisory.yml` (config, advisory CI workflow)

**Primary analog:** `.github/workflows/phase23-proof.yml` advisory job (lines 102–182), with D-06 modification

**Key difference from phase23 advisory:** Phase23 uses `continue-on-error: true` — D-06 explicitly prohibits this. Phase96 advisory instead uses a job-level `if:` guard so the job never runs on PR/push at all.

**Advisory trigger pattern** (phase23-proof.yml lines 34–44):
```yaml
on:
  workflow_dispatch:
  schedule:
    - cron: "0 6 * * 1"   # Weekly Monday 06:00 UTC
```
Note: No `pull_request` or `push` trigger on the advisory workflow — the job-level `if:` guard is redundant insurance, but the workflow-level trigger scope is the primary gate.

**Advisory job structure** (phase23 advisory + D-06 changes):
```yaml
jobs:
  advisory-threadline-example-host-ledger-proof:
    name: advisory threadline example-host ledger proof (ecto-backed)
    runs-on: ubuntu-latest
    timeout-minutes: 15
    if: ${{ github.event_name == 'schedule' || github.event_name == 'workflow_dispatch' }}
    # NO continue-on-error: true — that renders failures green in PR UI (D-06)
```

**Notice annotation step** (phase23-proof.yml lines 173–182):
```yaml
- name: Advisory lane status summary
  run: |
    echo "::notice title=Advisory lane::This lane is advisory only and"
    echo "::notice::cannot gate merge. Failures here do NOT retract any"
    echo "::notice::merge-blocking commerce support claim."
```

**working-directory for example-host test step:**
```yaml
- name: Run example-host ledger proof
  run: mix test test/crosswake_example/threadline/phase96_example_host_ledger_proof_test.exs
  working-directory: examples/phoenix_host
```

---

## Shared Patterns

### Hermetic Lane Self-Guard
**Source:** `test/crosswake/proof/phase52_operator_truth_test.exs` lines 215–221
**Apply to:** `phase96_threadline_docs_contract_test.exs` (hermetic lane only; NOT the advisory example-host test)
```elixir
test "hermetic lane guard keeps module untagged at file level and env-independent" do
  source = File.read!(__ENV__.file)
  refute Regex.match?(~r/^\s*@moduletag\s+:/m, source)
  refute String.contains?(source, "Crosswake" <> "Example.")
end
```

### File.read! Guide Path Convention
**Source:** `test/crosswake/guides/release_boundaries_test.exs` line 5
**Apply to:** `phase96_threadline_docs_contract_test.exs`
```elixir
guide = File.read!("guides/threadline.md")
```
Path is repo-root-relative, no `Path.join(__DIR__, ...)`. ExUnit runs from repo root by convention.

### Application.put_env + on_exit Restore
**Source:** `test/mix/tasks/crosswake.threadline_test.exs` lines 20–40
**Apply to:** `phase96_example_host_ledger_proof_test.exs`
```elixir
prev_repo = Application.get_env(:crosswake, :audit_repo)
prev_ledger = Application.get_env(:crosswake, :audit_ledger)
Application.put_env(:crosswake, :audit_repo, CrosswakeExample.Repo)
Application.put_env(:crosswake, :audit_ledger, CrosswakeExample.Audit.Ledger)
on_exit(fn ->
  if prev_repo, do: Application.put_env(:crosswake, :audit_repo, prev_repo),
    else: Application.delete_env(:crosswake, :audit_repo)
  if prev_ledger, do: Application.put_env(:crosswake, :audit_ledger, prev_ledger),
    else: Application.delete_env(:crosswake, :audit_ledger)
end)
```

### Pinned SHA Actions
**Source:** `.github/workflows/phase73-proof.yml` lines 38–43
**Apply to:** Both `.github/workflows/phase96-proof.yml` and `.github/workflows/phase96-proof-advisory.yml`
```yaml
uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6
uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1
with:
  elixir-version: "1.19.5"
  otp-version: "27.3"
```

### Separate compile + test Steps
**Source:** `.github/workflows/phase75-closeout-gate.yml` lines 31–35
**Apply to:** Both CI workflows
```yaml
- name: Compile (warnings as errors)
  run: mix compile --warnings-as-errors

- name: Run hermetic proof
  run: mix test ...
```
Do NOT fold `--warnings-as-errors` into `mix test`. This is a repo convention (D-02).

---

## No Analog Found

All files have analogs. No entries in this section.

---

## Critical Implementation Notes for Planner

These notes capture decisions that affect multiple files simultaneously and must be planned as atomic constraints:

1. **Atomicity of workflow + test file:** `phase96_threadline_docs_contract_test.exs` and `.github/workflows/phase96-proof.yml` must land in the same commit. The workflow's `mix test` step lists the proof test by path; `mix test <nonexistent path>` fails loudly. Shipping the workflow without the test file makes CI permanently red.

2. **`tier` field decision is cross-cutting:** Whether the example-host schema includes `field :tier, :string` affects the schema file, the migration, AND what assertions the PROOF-02 test can make (tier-grouped section headers vs "Other (unrecognized tier)"). The planner must resolve this before writing any of the three PROOF-02 files. Recommendation from RESEARCH.md: add `tier: :string` as an optional host extension column.

3. **Guide restructure must preserve two contains-exact anchors:**
   - Opening sentence (`guides/threadline.md` line 3) — verified by `support_matrix_test.exs` `docs_anchor` assertions
   - Doctor findings table codes — verified by `test/crosswake/doctor/doctor_threadline_test.exs`
   Neither test is in the phase96 workflow file list, but breaking them would break other merge-blocking lanes.

4. **Branch protection job id registration:** The job id `merge-blocking-threadline-docs-contract-proof` must match the YAML key exactly. Register in GitHub branch protection only AFTER the workflow's first completed run (GitHub only lists job ids post-run).

5. **`support_matrix_test.exs` line-scoping in workflow:** D-03 allows scoping to `path:LINE`. The threadline describe block starts around line 254. Use `test/crosswake/support_matrix/support_matrix_test.exs:254` or include the full file only if it runs clean in the hermetic lane (no pre-existing failures in that block).

---

## Metadata

**Analog search scope:** `test/crosswake/proof/`, `test/crosswake/guides/`, `test/mix/tasks/`, `examples/phoenix_host/test/`, `.github/workflows/`, `guides/`, `priv/templates/crosswake/audit/`
**Files scanned:** 16 source files read directly
**Pattern extraction date:** 2026-06-10
