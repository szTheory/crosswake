# Phase 96: Docs-Contract + Proof - Research

**Researched:** 2026-06-10
**Domain:** Documentation integrity / mechanically-verified guide contracts / ExUnit proof lanes / GitHub Actions CI
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01 — Docs-parity mechanism (DOCS-01):**
- New test file: `test/crosswake/proof/phase96_threadline_docs_contract_test.exs`
- Code-derived: loop `Crosswake.Threadline.Telemetry.metadata_keys/0`, `forbidden_metadata_keys/0`, and event names; assert each appears in the guide (`assert guide =~ Atom.to_string(key)`)
- Header name: derived via `Crosswake.Plug.Threadline.init([])[:header_name]` (NimbleOptions-validated default — `"x-crosswake-thread-id"`)
- 15 ledger columns: hardcoded in the test (no public accessor; LEDG-02 is a frozen contract). Add a co-location comment cross-referencing Doctor's `@canonical_ledger_columns`
- Loop each key individually; assert prose-form strings (`"thread_id"`), not atom syntax (`:thread_id`); every assertion carries a custom failure message naming the missing contract element and file to update (precedent: `test/crosswake/support_matrix/support_matrix_test.exs:267`)

**D-02 — Hermetic merge-blocking lane (PROOF-01):**
- New workflow: `.github/workflows/phase96-proof.yml` — `name: Phase 96 Proof - Threadline Docs Contract`
- Job id: `merge-blocking-threadline-docs-contract-proof` (this exact string goes in branch protection)
- Trigger: `push: branches: ['**']` + `pull_request` (phase90 shape); `ubuntu-latest`; `permissions: contents: read`; actions pinned to commit SHAs (phase73/75 pattern); `timeout-minutes` set; `mix compile --warnings-as-errors` as a separate step before `mix test` (repo convention — do NOT fold)

**D-03 — Test file selection (PROOF-01):**
- Explicit file list (matches all 20+ existing proof workflows); NO tag-based `--only`
- Baseline file set:
  - `test/crosswake/proof/phase91_threadline_contract_closeout_test.exs`
  - `test/crosswake/proof/phase92_server_propagation_closeout_test.exs`
  - `test/crosswake/proof/phase96_threadline_docs_contract_test.exs` (new)
  - `test/crosswake/plug/threadline_test.exs`
  - `test/crosswake/live/threadline_test.exs`
  - `test/crosswake/threadline/telemetry_test.exs`
  - `test/crosswake/threadline/id_test.exs`
  - `test/crosswake/doctor/doctor_threadline_test.exs`
  - `test/mix/tasks/crosswake.gen.audit_test.exs`
- `support_matrix_test.exs` included only for the threadline-relevant lines (scoped by path:LINE if needed); add comment block above `mix test` step mapping each file to the contract it proves

**D-04 — Advisory example-host lane (PROOF-02):**
- Commit `mix crosswake.gen.audit` output (schema `CrosswakeExample.Audit.Ledger` + timestamped migration) into `examples/phoenix_host` — consistent with three already-committed Sigra audit schema+migration pairs
- The committed schema is the canonical durable-posture adopter example

**D-05 — Advisory example-host test (PROOF-02):**
- ExUnit test in the example host; `async: false` (ecto_sqlite3 has no sandbox async support)
- Seed via `Ecto.Multi` + `CrosswakeExample.Audit.Ledger.record_in_multi/3` + `Repo.transaction`
- `Mix.Task.reenable("crosswake.threadline")` + `Mix.Task.run(...)` with `Mix.Shell.Process` (not bare `capture_io` — subtask stdout bleeds through); assert shell mailbox for `"Posture: Durable"` and the seeded event
- Cleanup via `Repo.delete_all` in `setup` (before, not `on_exit` — SQLite serialized-write race)
- Config via `Application.put_env(:crosswake, :audit_repo/:audit_ledger)` + `on_exit` restore

**D-06 — Advisory lane CI mechanics (PROOF-02):**
- Separate `phase96-proof-advisory.yml`; job gated `if: github.event_name == 'schedule' || github.event_name == 'workflow_dispatch'`; weekly Monday cron (`0 6 * * 1`)
- NOT `continue-on-error: true` (known GitHub UX trap — failed jobs render green on PRs)
- Final `::notice title=Advisory lane::` annotation step

**D-07 — Guide structure (DOCS-01/02/03):**
H2 outline in order:
1. What Threadline Is
2. What Threadline Is NOT
3. The Propagation Contract
4. Posture: Ephemeral vs Durable
5. The Audit Ledger Schema (LEDG-02)
6. PII-Free by Construction
7. Operations
8. Doctor Findings (keep existing Code|Severity|Meaning table)
9. Honest Limitations
10. Deferred Non-Claims

**D-08 — Contract content verbatim (DOCS-01):**
- 15 ledger fields as a `| field | type | meaning |` table (including `provenance` as `Ecto.Enum` `:device_claimed | :backend_accepted`)
- TWO forbidden lists must be presented without conflation:
  - Telemetry denylist: `Crosswake.Threadline.Telemetry.forbidden_metadata_keys/0` (20 keys)
  - Ledger PII guard: 8 keys from generated template (`email`, `phone`, `ip_address`, `ssn`, `name`, `first_name`, `last_name`, `address`)

**D-09 — Anti-scope section (DOCS-02):**
- Real H2 section "What Threadline Is NOT"; framed "non-goals by design, not deferred features"
- Item language anchored to REQUIREMENTS.md Out of Scope table (exact text feeds contains-exact tests): not APM, not OTel replacement, not a logging framework (sets metadata, never emits log lines), not a plugin/event bus, no PII, no session replay

**D-10 — Locked microcopy (DOCS-01/02/03):**
- Hash chain: "`row_hash` and `prev_hash` detect gaps and overwrites after the fact. Hash-chaining does not prevent tampering — it reports it." Never the adjective "secure."
- WebView gap: deliberate scoping truth, not a bug; mention `_crosswake_thread_id` connect-param path for LiveView mounts
- OTel coexistence: standard `:telemetry` events, zero OTel dependency, host may attach an OTel handler to bridge spans
- Terminal-critical scope: "terminal critical events — auth handoffs, commerce receipts, step-up resolutions, route denials — not high-frequency request logging"
- Vocabulary: `host-owned`, `actor_ref` (never "user id"), `append-only`, `device-claimed`/`backend-accepted`; banned: "magic," "seamless," "universal," "automatically" for `record_in_multi` path
- Keep existing opening sentence verbatim (anchor): "Threadline is Crosswake's … PII-free correlation thread across the three tiers …"
- No "Note:"/"Tip:" callout boxes — house style uses plain sections

### Claude's Discretion
- Exact table column phrasing in the ledger schema table, section prose length, and ordering of files within the workflow's `mix test` list
- Whether `test/crosswake/guides/` vs `test/crosswake/proof/` hosts the docs-contract test — research recommends `test/crosswake/proof/phase96_threadline_docs_contract_test.exs` as the anchor; planner may also keep a thin guides-style test if it reduces duplication

### Deferred Ideas (OUT OF SCOPE)
- `Crosswake.Audit.Ledger.canonical_columns/0` public introspection function — extract only when a third consumer needs the column list
- Hash-chain verification task (`row_hash`/`prev_hash` integrity walking) and `crosswake_dashboard` LiveDashboard UI
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOCS-01 | `guides/threadline.md` documents header name, AuditEvent field list, forbidden-field list, ephemeral-vs-durable posture, module/task names, and "terminal critical events only" scope — each mechanically asserted `contains-exact` against the code (merge-blocking) | Shipped symbols inventoried below; test pattern verified from `release_boundaries_test.exs` and `support_matrix_test.exs` |
| DOCS-02 | Guide includes mechanically-checked "What Threadline is NOT" anti-scope section | Anti-scope language sourced from REQUIREMENTS.md Out of Scope table; contains-exact test pattern confirmed |
| DOCS-03 | Guide documents honest limitations: WebView WebSocket/fetch/XHR header gaps, hash-chain tamper detection, OTel coexistence with zero dependency | Limitation content confirmed from shipped code (`Plug.Threadline`, `Telemetry`); microcopy locked in D-10 |
| PROOF-01 | Hermetic, merge-blocking proof lane: Plug metadata+telemetry emission, telemetry forbidden-key rejection, `gen.audit` idempotency, doctor findings, `guides/threadline.md` parity — no Ecto/network/device | CI workflow shape confirmed from phase73/75; file list confirmed from phase92 closeout; hermetic guard pattern confirmed from phase52 |
| PROOF-02 | Advisory example-host proof lane: real Ecto-backed `record_in_multi/3` persistence, `mix crosswake.threadline` reconstruction with `durable` posture against seeded ledger | Example host uses ecto_sqlite3; `Repo.delete_all` cleanup confirmed from flashcards_test; `Mix.Task.reenable` pattern confirmed from threadline_test.exs; advisory CI pattern confirmed from phase23 |
</phase_requirements>

---

## Summary

Phase 96 is a documentation-integrity and proof-lane phase. No new runtime features ship. The goal is to make `guides/threadline.md` the mechanically-verified public contract for Threadline, then prove it in two CI lanes: a merge-blocking hermetic lane (PROOF-01) and an advisory example-host lane (PROOF-02).

The guide already exists (70 lines, written as Phase 95's IN-03 fix). It covers posture, the mix task, and doctor findings — but lacks the H2 anti-scope section, the honest-limitations section, the verbatim 15-field ledger table, the forbidden-key list, telemetry module names, and "terminal critical events only" scope. The restructure expands it using the D-07 outline without replacing the opening sentence (which is a contains-exact anchor used by support_matrix_test.exs's docs_anchor assertions).

The entire decision space was locked during the discuss-phase with two research rounds. All major choices — assertion strategy, workflow trigger shape, advisory mechanics, guide structure, forbidden-key presentation — are locked decisions. Research below inventories the shipped symbols and test patterns that must be reproduced exactly in the new test file and CI workflows.

**Primary recommendation:** Follow the locked decisions to the letter. Every open planner choice (prose length, exact table column headers, file ordering in `mix test` list) is discretionary, but nothing else is.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Guide restructure (`guides/threadline.md`) | Source files (documentation) | — | Static Markdown in repo root; no runtime tier |
| Docs-parity assertions | Test layer (hermetic ExUnit) | — | Reads guide from disk + calls public API functions; no Ecto |
| Merge-blocking proof lane | CI / GitHub Actions | Test layer | Workflow selects test files; test layer does the assertions |
| Advisory example-host lane | CI / GitHub Actions | Example host (Ecto + SQLite) | Workflow triggers the example host test suite; test invokes Mix task against SQLite ledger |
| `gen.audit` output committed to example host | Source files (example host) | — | Schema + migration files committed to git; not generated at CI time |

---

## Shipped Symbol Inventory (VERIFIED)

All symbols below were read directly from the shipped source files. These are the exact values that tests must assert and the guide must contain.

### Header Name
[VERIFIED: lib/crosswake/plug/threadline.ex]

```elixir
# From NimbleOptions schema default:
header_name: [type: :string, default: "x-crosswake-thread-id"]

# Derivation pattern for tests (D-01):
Crosswake.Plug.Threadline.init([])[:header_name]
# => "x-crosswake-thread-id"
```

The guide must contain `X-Crosswake-Thread-Id` (human-readable form; HTTP header names are case-insensitive). The test derives the value via `init([])` to avoid hardcoding.

### Telemetry Event Names (3 total)
[VERIFIED: lib/crosswake/threadline/telemetry.ex]

```elixir
@event_names [
  [:crosswake, :threadline, :request, :start],
  [:crosswake, :threadline, :request, :stop],
  [:crosswake, :threadline, :request, :exception]
]
```

Public accessor: `Crosswake.Threadline.Telemetry.event_names/0`

### Telemetry Metadata Keys (4 total — PROP-02 allowlist)
[VERIFIED: lib/crosswake/threadline/telemetry.ex]

```elixir
@metadata_keys [:thread_id, :correlation_id, :route_id, :source]
```

Public accessor: `Crosswake.Threadline.Telemetry.metadata_keys/0`

### Telemetry Forbidden Metadata Keys (20 total)
[VERIFIED: lib/crosswake/threadline/telemetry.ex]

```elixir
@forbidden_metadata_keys [
  :access_token, :actor_id, :actor_ref, :authorization_code,
  :credential_id, :device_id, :email, :id_token, :ip, :nonce,
  :org_id, :passkey_credential_id, :pkce_verifier, :provider_payload,
  :raw_return_to, :refresh_token, :return_to, :session_ref,
  :subject_ref, :user_agent
]
```

Public accessor: `Crosswake.Threadline.Telemetry.forbidden_metadata_keys/0`

Note: `:actor_ref` is both a canonical ledger column AND a forbidden telemetry key. The Doctor's `check_pii_fields/3` specifically excludes canonical ledger columns from the forbidden set to prevent false positives. The guide must present the two lists separately.

### Audit Ledger Columns (15 total — LEDG-02)
[VERIFIED: lib/crosswake/audit/ledger.ex and priv/templates/crosswake/audit/ledger.ex.eex]

```
:thread_id, :correlation_id, :route_id, :actor_ref, :actor_kind,
:event_class, :event_type, :outcome, :provenance, :occurred_at,
:recorded_at, :idempotency_key, :metadata, :row_hash, :prev_hash
```

Same list lives in `Crosswake.Doctor.@canonical_ledger_columns` (hardcoded constant — co-location comment target per D-01). No public accessor.

`provenance` type is `Ecto.Enum, values: [:device_claimed, :backend_accepted]` (from template).
`idempotency_key` has a unique index on `crosswake_audit_events`.

### Ledger PII Guard (8 string + atom keys — template-side forbidden list)
[VERIFIED: priv/templates/crosswake/audit/ledger.ex.eex]

```elixir
@forbidden_keys [
  "email", "phone", "ip_address", "ssn", "name", "first_name", "last_name", "address",
  :email, :phone, :ip_address, :ssn, :name, :first_name, :last_name, :address
]
```

This is the 8-key set (each in string + atom form) in the generated `reject_pii_in_metadata/1` changeset guard. The guide must present this as a separate list from the 20-key telemetry denylist.

### Mix Task Names
[VERIFIED: lib/mix/tasks/crosswake.gen.audit.ex, lib/mix/tasks/crosswake.threadline.ex]

- `mix crosswake.gen.audit` — scaffold host-owned ledger schema + migration
- `mix crosswake.threadline` — inspect thread sequence (with `--thread-id` or `--actor-ref`)

### Doctor Finding Codes
[VERIFIED: lib/crosswake/doctor/doctor.ex (phase_95_threadline_findings)]

| Code | Severity | Check key |
|------|----------|-----------|
| `threadline.plug_missing` | `:advisory` | `threadline_posture` |
| `threadline.ledger_not_configured` | `:advisory` | `threadline_posture` |
| `threadline.ledger_schema_drift` | `:warning` | `threadline_posture` |
| `threadline.pii_forbidden_field_present` | `:error` | `threadline_posture` |
| `threadline.ledger_schema_invalid` | `:advisory` | `threadline_posture` |

### Generated Schema Module Name (example host)
[VERIFIED: priv/templates/crosswake/audit/ledger.ex.eex]

For `CrosswakeExample` app module: `CrosswakeExample.Audit.Ledger`

`record_in_multi/3` signature (generated into schema):
```elixir
def record_in_multi(multi, name, attrs) do
  Ecto.Multi.insert(multi, name, changeset(%__MODULE__{}, attrs))
end
```

Note: CONTEXT.md says "record_in_multi/2" in PROOF-02 description but the generated function is `/3` (multi, name, attrs). The PROOF-02 test must use the `/3` arity from the generated schema module.

---

## Architecture Patterns

### System Architecture Diagram

```
guides/threadline.md (source of truth)
        |
        | assert guide =~ "string"
        v
test/crosswake/proof/phase96_threadline_docs_contract_test.exs
        |                                       |
        | calls                                 | reads file
        v                                       v
Crosswake.Threadline.Telemetry.*        File.read!("guides/threadline.md")
Crosswake.Plug.Threadline.init([])
        |
        | all tests run via
        v
.github/workflows/phase96-proof.yml
  [merge-blocking job]
        |
        | merge gate
        v
branch protection: merge-blocking-threadline-docs-contract-proof

examples/phoenix_host/lib/crosswake_example/audit/ledger.ex  (committed output of gen.audit)
examples/phoenix_host/priv/repo/migrations/..._create_crosswake_audit_events.exs
        |
        | real Ecto + SQLite
        v
examples/phoenix_host/test/.../phase96_example_host_ledger_proof_test.exs
  Repo.delete_all -> seed via record_in_multi/3 -> Mix.Task.run "crosswake.threadline"
  -> assert Mix.Shell.Process mailbox for "Posture: Durable"
        |
        | runs on schedule/dispatch only
        v
.github/workflows/phase96-proof-advisory.yml
  [advisory job, not merge-blocking]
```

### Recommended File Structure

```
guides/
└── threadline.md                    # restructured (existing — do not rename)

test/crosswake/proof/
└── phase96_threadline_docs_contract_test.exs  # new — PROOF-01 + DOCS-01/02/03

examples/phoenix_host/
├── lib/crosswake_example/audit/
│   └── ledger.ex                    # new — committed gen.audit output
├── priv/repo/migrations/
│   └── YYYYMMDDHHMMSS_create_crosswake_audit_events.exs  # new
└── test/crosswake_example/
    └── threadline/
        └── phase96_example_host_ledger_proof_test.exs    # new — PROOF-02

.github/workflows/
├── phase96-proof.yml                # new — merge-blocking
└── phase96-proof-advisory.yml       # new — advisory
```

---

## Existing Test Patterns (VERIFIED)

### Pattern 1: Contains-Exact Docs Test (release_boundaries_test.exs)
[VERIFIED: test/crosswake/guides/release_boundaries_test.exs]

```elixir
defmodule Crosswake.Guides.ReleaseBoundariesTest do
  use ExUnit.Case, async: true

  test "guide surfaces publish the four change classes..." do
    install = File.read!("guides/install.md")
    assert install =~ "Do I need to rebuild?"
    assert install =~ "docs-only"
    # ...each assertion is a separate string
  end
end
```

Key: `async: true` is acceptable for pure file-read tests. The phase96 test is in `test/crosswake/proof/` and follows the proof convention of `async: false` (phase92 uses `async: true` but only because it doesn't mutate Application env).

### Pattern 2: Code-Derived Parity (support_matrix_test.exs)
[VERIFIED: test/crosswake/support_matrix/support_matrix_test.exs lines 287-303]

```elixir
test "entry telemetry.forbidden_metadata_keys matches Crosswake.Threadline.Telemetry" do
  alias Crosswake.Threadline.Telemetry, as: ThreadlineTelemetry
  [entry] = Crosswake.SupportMatrix.audit_ledger_support_truth()
  assert entry.telemetry.forbidden_metadata_keys == ThreadlineTelemetry.forbidden_metadata_keys()
end
```

The phase96 test applies the same code-derived equality pattern but against the guide text, not a SupportMatrix struct.

### Pattern 3: Custom Failure Messages (support_matrix_test.exs)
[VERIFIED: test/crosswake/support_matrix/support_matrix_test.exs line ~262]

The `docs_anchor` test uses a custom failure message via `assert ..., "docs_anchor #{entry.docs_anchor} is referenced by doctor hints but #{path} does not exist"`. The phase96 test must apply this pattern to every assertion.

### Pattern 4: Hermetic Lane Guard (phase52_operator_truth_test.exs)
[VERIFIED: test/crosswake/proof/phase52_operator_truth_test.exs lines 215-221]

```elixir
test "hermetic lane guard keeps module untagged at file level and env-independent" do
  source = File.read!(__ENV__.file)
  refute Regex.match?(~r/^\s*@moduletag\s+:/m, source)
  refute String.contains?(source, "Crosswake" <> "Example.")
  # ...
end
```

The phase96 proof test must include this self-guard pattern — reading its own source and asserting it carries no `@moduletag` and no example-host dependency.

### Pattern 5: Mix.Task.reenable + Application.put_env cleanup (crosswake.threadline_test.exs)
[VERIFIED: test/mix/tasks/crosswake.threadline_test.exs]

```elixir
setup do
  prev_repo = Application.get_env(:crosswake, :audit_repo)
  prev_ledger = Application.get_env(:crosswake, :audit_ledger)
  Application.put_env(:crosswake, :audit_repo, MockRepo)
  Application.put_env(:crosswake, :audit_ledger, MockLedgerSchema)

  on_exit(fn ->
    if prev_repo do
      Application.put_env(:crosswake, :audit_repo, prev_repo)
    else
      Application.delete_env(:crosswake, :audit_repo)
    end
    # ...
  end)
end

# In test:
Mix.Task.reenable("crosswake.threadline")
Mix.Task.run("crosswake.threadline", ["--thread-id", "test-thread-123"])
```

The PROOF-02 test must replicate this pattern but use real Ecto + `CrosswakeExample.Repo` instead of mock modules, and use `Mix.Shell.Process` instead of `capture_io`.

### Pattern 6: Example Host Repo.delete_all Cleanup (flashcards_test.exs)
[VERIFIED: examples/phoenix_host/test/crosswake_example/flashcards_test.exs]

```elixir
setup do
  Repo.delete_all(CrosswakeExample.Flashcards.Progress)
  # more delete_alls...
  :ok
end
```

PROOF-02 must use `Repo.delete_all(CrosswakeExample.Audit.Ledger)` in `setup do` (before test body), not `on_exit`. No `Ecto.Adapters.SQL.Sandbox` — ecto_sqlite3 does not support async sandbox.

### Pattern 7: CI Workflow Structure (phase73-proof.yml)
[VERIFIED: .github/workflows/phase73-proof.yml]

```yaml
permissions:
  contents: read

jobs:
  merge-blocking-threadline-docs-contract-proof:  # must match branch protection job id
    runs-on: ubuntu-latest
    timeout-minutes: N
    if: ${{ github.event_name == 'pull_request' || ... }}

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
      - name: Run hermetic proof
        run: mix test test/file1.exs test/file2.exs
```

Pinned SHA values: `actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd` and `erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93`. These are the exact SHAs used in phase73 and phase75.

### Pattern 8: Advisory Lane Structure (phase23-proof.yml)
[VERIFIED: .github/workflows/phase23-proof.yml]

```yaml
advisory-lane-job:
  runs-on: ubuntu-latest
  timeout-minutes: N
  if: ${{ github.event_name == 'schedule' || github.event_name == 'workflow_dispatch' }}
  continue-on-error: true  # NOTE: phase23 uses this; D-06 says NOT to use it

  steps:
    # ...
    - name: Advisory lane status summary
      run: |
        echo "::notice title=Advisory lane::This lane is advisory only..."
```

**Critical distinction for D-06:** Phase23's advisory job uses `continue-on-error: true`, but D-06 explicitly prohibits this because it renders failed jobs green on PRs. Phase96's advisory lane instead gates the entire job with `if: github.event_name == 'schedule' || ...` so the job never runs on PRs at all — it can't fail there.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Header name value in tests | Hardcode `"x-crosswake-thread-id"` | `Crosswake.Plug.Threadline.init([])[:header_name]` | NimbleOptions validates it; code-derivation detects renames |
| Telemetry key lists | Hardcode key lists | `Telemetry.metadata_keys/0`, `Telemetry.forbidden_metadata_keys/0` | Published API; equality assertion detects additions/removals |
| Ledger column list | Derive programmatically | Hardcode 15 columns (frozen LEDG-02 contract); co-locate comment pointing to `@canonical_ledger_columns` | No public accessor; adding a public API now is explicitly deferred |
| Advisory lane fail-silencing | `continue-on-error: true` | Job-level `if:` guard on schedule/dispatch | `continue-on-error` renders failures green in PR UI (GitHub UX bug) |
| Mix.Task capture in example-host test | `capture_io/1` | `Mix.Shell.Process` | Subtask stdout bleeds through `capture_io`; shell process mailbox gives clean assertions |

---

## Common Pitfalls

### Pitfall 1: Registering CI Job by Display Name Instead of Job ID
**What goes wrong:** Branch protection setting names the workflow job by its `name:` display string (e.g., "Phase 96 Proof - Threadline Docs Contract") instead of the job id key (e.g., `merge-blocking-threadline-docs-contract-proof`). GitHub silently never matches the check.
**Why it happens:** GitHub UI shows display names in most places, but branch protection requires the exact YAML job id.
**How to avoid:** The job id in YAML must be `merge-blocking-threadline-docs-contract-proof`. Register AFTER the workflow's first completed run (GitHub only lists job ids post-run).
**Warning signs:** Branch protection shows "required check — no recent status" despite CI running.

### Pitfall 2: `mix test <nonexistent path>` Fails Loudly
**What goes wrong:** A file listed in the workflow's `mix test` command is renamed or hasn't been created yet when the workflow runs.
**Why it happens:** ExUnit file list is validated at startup; a missing file is a hard error.
**How to avoid:** The new proof test file (`phase96_threadline_docs_contract_test.exs`) must be committed in the same commit as the workflow. Do not ship the workflow without the test file.
**Warning signs:** Workflow fails with "no files matched pattern."

### Pitfall 3: Mix.Task Once-Semantics (Vacuous Pass)
**What goes wrong:** `Mix.Task.run/2` in a second test call returns `:noop` because Mix marks the task as "already ran." Assertions on output pass vacuously because the task didn't actually run.
**Why it happens:** Mix tasks default to `use Mix.Task` which marks them as run-once per compile session.
**How to avoid:** Call `Mix.Task.reenable("crosswake.threadline")` immediately before EVERY `Mix.Task.run(...)` call in the test.
**Warning signs:** Tests pass even when assertions would fail if the task had run with wrong args.

### Pitfall 4: `tier` Not Set on Seeded Events
**What goes wrong:** Seeded events lack an explicit `tier` field. They all fall into the "Other (unrecognized tier)" bucket. Output assertions for "Native", "Bridge", "Phoenix" section headers fail.
**Why it happens:** `tier` is not part of the LEDG-02 canonical columns — it must be added as a host-schema field or set explicitly.
**How to avoid:** Set `tier` explicitly to `"native"` / `"bridge"` / `"phoenix"` on seeded events per D-05.
**Warning signs:** Test output shows `"Other (unrecognized tier)"` where canonical tier names are expected.

### Pitfall 5: SQLite Serialized-Write Race in Cleanup
**What goes wrong:** `Repo.delete_all` in `on_exit` runs after the next test's setup starts (SQLite enforces serialized writes). Race produces "database is locked" errors.
**Why it happens:** `on_exit` callbacks run after the test process exits but before the next test begins; SQLite's write-serialization makes this a timing hazard.
**How to avoid:** Put `Repo.delete_all` in `setup do` (runs before the test body), not `on_exit`.
**Warning signs:** Intermittent "database is locked" or "SQLITE_BUSY" errors in the test suite.

### Pitfall 6: Conflating the Two Forbidden-Key Lists
**What goes wrong:** Guide presents one combined forbidden-key list. Readers (and contains-exact tests) can't distinguish the telemetry denylist (20 keys — what Plug strips from metadata) from the ledger PII guard (8 keys — what `reject_pii_in_metadata/1` blocks in schema changesets).
**Why it happens:** Both are "forbidden" but serve different purposes and contain different keys.
**How to avoid:** Present them in separate sections per D-08. The test asserts strings from both lists independently.
**Warning signs:** Test failure: assertion on a key like `"ip_address"` (ledger PII guard only) fails because it was written to check `forbidden_metadata_keys/0` (telemetry denylist — has `:ip`, not `:ip_address`).

### Pitfall 7: Breaking Existing docs_anchor Assertions
**What goes wrong:** Restructuring `guides/threadline.md` renames or moves sections. `support_matrix_test.exs` has a `docs_anchor` assertion that the file exists at `"guides/threadline.md"`. Doctor hints also cite `"guides/threadline.md"`. If the file is renamed, both break.
**Why it happens:** The guide path is hardcoded in `Crosswake.SupportMatrix.audit_ledger_support_truth/0` and in doctor `check_*` hint strings.
**How to avoid:** Do NOT rename `guides/threadline.md`. After restructuring, re-run `support_matrix_test.exs` and `doctor_threadline_test.exs` to verify no contains-exact references in those tests broke.
**Warning signs:** `support_matrix_test.exs` "entry docs_anchor file exists in the repository" test fails.

---

## Code Examples

### Phase96 Docs Contract Test Skeleton
```elixir
# Source: research of phase52 hermetic guard pattern + phase92 closeout pattern
defmodule Crosswake.Proof.Phase96ThreadlineDocsContractTest do
  use ExUnit.Case, async: false

  # ---------------------------------------------------------------------------
  # Hermetic lane self-guard (phase52 pattern)
  # ---------------------------------------------------------------------------
  test "hermetic lane guard — module is untagged and has no example-host dependency" do
    source = File.read!(__ENV__.file)
    refute Regex.match?(~r/^\s*@moduletag\s+:/m, source),
           "phase 96 proof module must not carry @moduletag — tag-based selection is not used in this repo's proof lanes"
    refute String.contains?(source, "Crosswake" <> "Example."),
           "phase 96 proof module must not depend on example-host modules — keep the hermetic lane hermetic"
  end

  # ---------------------------------------------------------------------------
  # DOCS-01: Header name
  # ---------------------------------------------------------------------------
  test "guide documents the X-Crosswake-Thread-Id header name" do
    guide = File.read!("guides/threadline.md")
    header = Crosswake.Plug.Threadline.init([])[:header_name]

    assert guide =~ header,
           "guides/threadline.md must document the header name '#{header}' — update the guide if the Plug default changes"
  end

  # ---------------------------------------------------------------------------
  # DOCS-01: Telemetry metadata keys (code-derived, one assertion per key)
  # ---------------------------------------------------------------------------
  test "guide documents all telemetry metadata keys" do
    guide = File.read!("guides/threadline.md")

    for key <- Crosswake.Threadline.Telemetry.metadata_keys() do
      key_str = Atom.to_string(key)
      assert guide =~ key_str,
             "guides/threadline.md must document telemetry metadata key '#{key_str}' — add it to the Propagation Contract section"
    end
  end

  # ---------------------------------------------------------------------------
  # DOCS-01: Forbidden metadata keys (telemetry denylist)
  # ---------------------------------------------------------------------------
  test "guide documents the telemetry forbidden metadata key list" do
    guide = File.read!("guides/threadline.md")

    for key <- Crosswake.Threadline.Telemetry.forbidden_metadata_keys() do
      key_str = Atom.to_string(key)
      assert guide =~ key_str,
             "guides/threadline.md must document forbidden telemetry key '#{key_str}' — update the PII-Free by Construction section"
    end
  end

  # ---------------------------------------------------------------------------
  # DOCS-01: Ledger columns (hardcoded — LEDG-02 frozen contract)
  # Co-location note: this list must stay in sync with @canonical_ledger_columns
  # in lib/crosswake/doctor/doctor.ex. If a third consumer needs the list,
  # extract Crosswake.Audit.Ledger.canonical_columns/0 — but not until then.
  # ---------------------------------------------------------------------------
  @canonical_ledger_columns [
    "thread_id", "correlation_id", "route_id", "actor_ref", "actor_kind",
    "event_class", "event_type", "outcome", "provenance", "occurred_at",
    "recorded_at", "idempotency_key", "metadata", "row_hash", "prev_hash"
  ]

  test "guide documents all 15 canonical LEDG-02 ledger columns" do
    guide = File.read!("guides/threadline.md")

    for col <- @canonical_ledger_columns do
      assert guide =~ col,
             "guides/threadline.md must document ledger column '#{col}' — add it to the Audit Ledger Schema (LEDG-02) table"
    end
  end
end
```

### Phase96 Advisory Proof Workflow Trigger Shape
```yaml
# Source: research of phase23-proof.yml advisory pattern + D-06
name: Phase 96 Proof - Threadline Docs Contract (Advisory)

permissions:
  contents: read

on:
  workflow_dispatch:
  schedule:
    - cron: "0 6 * * 1"   # Weekly Monday 06:00 UTC

jobs:
  advisory-threadline-example-host-ledger-proof:
    name: advisory threadline example-host ledger proof (ecto-backed)
    runs-on: ubuntu-latest
    timeout-minutes: 15
    if: ${{ github.event_name == 'schedule' || github.event_name == 'workflow_dispatch' }}
    # Note: NO continue-on-error: true — that renders failures green in PR UI.
    # The if: guard prevents this job from running on PR/push events entirely.

    steps:
      # ... setup steps ...
      - name: Run example-host ledger proof
        run: mix test test/crosswake_example/threadline/phase96_example_host_ledger_proof_test.exs
        working-directory: examples/phoenix_host

      - name: Advisory lane notice
        if: always()
        run: |
          echo "::notice title=Advisory lane::Example-host Ecto-backed ledger proof is advisory only."
          echo "::notice::Failures here do NOT gate merge. Proof requires a seeded SQLite ledger."
```

### PROOF-02 Example-Host Test Skeleton
```elixir
# Source: research of crosswake.threadline_test.exs + flashcards_test.exs patterns + D-05
defmodule CrosswakeExample.Threadline.Phase96ExampleHostLedgerProofTest do
  use ExUnit.Case, async: false  # ecto_sqlite3 no sandbox async support

  alias CrosswakeExample.Repo

  setup do
    # Cleanup BEFORE (not on_exit) — SQLite serialized-write race (D-05)
    Repo.delete_all(CrosswakeExample.Audit.Ledger)

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

    :ok
  end

  test "record_in_multi/3 persists a durable ledger event and mix crosswake.threadline reconstructs it" do
    thread_id = "proof-96-#{System.unique_integer([:positive])}"

    # Seed via record_in_multi/3 (generated function — 3-arity: multi, name, attrs)
    {:ok, _result} =
      Ecto.Multi.new()
      |> CrosswakeExample.Audit.Ledger.record_in_multi(:audit_event, %{
        thread_id: thread_id,
        correlation_id: "corr-proof-96",
        route_id: "proof-route",
        actor_ref: "proof-actor",
        actor_kind: "user",
        event_class: "auth",
        event_type: "auth.step_up",
        outcome: "success",
        provenance: :backend_accepted,
        occurred_at: DateTime.utc_now(),
        recorded_at: DateTime.utc_now(),
        idempotency_key: "idem-proof-96-#{System.unique_integer([:positive])}",
        tier: "phoenix"  # must be set explicitly or falls into Other bucket
      })
      |> Repo.transaction()

    # Use Mix.Shell.Process to capture task output without subtask stdout bleed
    Mix.Shell.Process.flush()
    original_shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)

    Mix.Task.reenable("crosswake.threadline")
    Mix.Task.run("crosswake.threadline", ["--thread-id", thread_id])

    Mix.shell(original_shell)

    # Assert durable posture header
    assert_received {:mix_shell, :info, [msg]}
    assert msg =~ "Posture: Durable"
  end
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `continue-on-error: true` for advisory lanes | Job-level `if:` gate on `schedule`/`workflow_dispatch` | Phase23 introduced `continue-on-error`; D-06 prohibits it for phase96 | Failures no longer render green on PRs |
| Tag-based test selection (`--only tag`) | Explicit file list in `mix test` | Established by phase23; confirmed by phase52/64/65 anti-tag guard | File-list rot fails closed; tag silencing fails open |
| Docs as narrative prose | Docs as mechanically-verified contract | Phase69 docs-parity pattern; phase96 applies it to Threadline | Guide drift is a CI failure, not a review concern |

**Deprecated/outdated patterns:**
- `@moduletag` on proof modules: explicitly prohibited by the hermetic lane self-guard test (phase52 pattern)
- Hardcoding the header name `"x-crosswake-thread-id"` in tests: use `init([])[:header_name]` for rename-safety

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `record_in_multi/3` is the correct arity (CONTEXT.md says "/2" once but the generated template has three params: `multi, name, attrs`) | Shipped Symbol Inventory; PROOF-02 test skeleton | Test would fail with FunctionClauseError if wrong arity is called |
| A2 | `tier` field must be added to the generated `crosswake_audit_events` table schema (it's not in the LEDG-02 canonical 15 columns, but the mix crosswake.threadline task groups by it) | Pitfall 4; PROOF-02 test skeleton | Seeded events would fall into "Other (unrecognized tier)" bucket; tier-based output assertions fail |

**Note on A1:** Reading the generated template directly (`priv/templates/crosswake/audit/ledger.ex.eex:126`) confirms `/3`. The CONTEXT.md reference to "record_in_multi/2" appears to be a typo in the discuss-phase document.

**Note on A2:** The `mix crosswake.threadline` task groups by `tier` column, but `tier` is not in the LEDG-02 canonical columns list (`@canonical_ledger_columns`). The crosswake.threadline_test.exs mock schemas include a `tier` field. The planner must decide: add `tier` to the generated schema as a host-optional field, or seed without it and assert only "Other (unrecognized tier)". Either approach is valid — the test just needs to be written consistently with the schema that ships.

---

## Open Questions

1. **Does `tier` need to be in the committed gen.audit schema?**
   - What we know: `mix crosswake.threadline` groups events by `tier`; mock test schemas in `crosswake.threadline_test.exs` include `tier`; the canonical LEDG-02 columns do not include `tier`; PROOF-02 seeded events set `tier` explicitly per D-05
   - What's unclear: Whether the `priv/templates/crosswake/audit/ledger.ex.eex` generated schema needs a `tier` field added, or whether the PROOF-02 test seeds events with a `tier` key that gets stored in the `:map` `metadata` field, or whether a separate migration adds `tier` to the example-host schema
   - Recommendation: Planner should add `tier: :string` as an optional column to the generated schema (consistent with how Sigra's audit schemas add domain-specific columns beyond the base contract). This is the example-host's own extension of the base LEDG-02 contract. Alternatively, the test can assert only "Posture: Durable" and skip tier-based section assertions — but D-05 explicitly says "assert the seeded event," implying tier-based grouping works.

2. **Should `support_matrix_test.exs` be scoped by line in the phase96 workflow?**
   - What we know: The full support_matrix_test.exs has 300+ lines; D-03 says "include only if it runs clean in the lane" and allows `path.exs:LINE` scoping
   - What's unclear: Whether the threadline-specific tests (lines ~255-303) can be isolated cleanly without running the rest of the file
   - Recommendation: Run only the relevant describe block using `path:LINE` scoping for the smallest lines range that covers the docs_anchor assertions. The planner should verify this runs clean.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All ExUnit tests | Yes | `~> 1.19` (mix.exs) | — |
| Erlang/OTP | All ExUnit tests | Yes | 27.3 (from workflow pins) | — |
| ecto_sqlite3 | PROOF-02 example-host test | Yes | `~> 0.16` (example host mix.exs) | — |
| GitHub Actions | CI workflows | Yes (assumed) | — | — |

**Missing dependencies with no fallback:** None identified.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (standard Elixir, no config file needed) |
| Config file | `test/test_helper.exs` (main lib); `examples/phoenix_host/test/test_helper.exs` (example host — single line: `ExUnit.start()`) |
| Quick run command (hermetic) | `mix test test/crosswake/proof/phase96_threadline_docs_contract_test.exs` |
| Full suite command | `mix test` (main lib); `cd examples/phoenix_host && mix test` (example host) |
| Example-host run | `cd examples/phoenix_host && mix test test/crosswake_example/threadline/phase96_example_host_ledger_proof_test.exs` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DOCS-01 | Guide contains header name, all 15 ledger columns, all telemetry keys, task names, "terminal critical events" scope | hermetic unit | `mix test test/crosswake/proof/phase96_threadline_docs_contract_test.exs` | No — Wave 0 |
| DOCS-02 | Guide contains "What Threadline Is NOT" section with anti-scope items | hermetic unit | same | No — Wave 0 |
| DOCS-03 | Guide documents WebView gap, hash-chain tamper detection, OTel coexistence | hermetic unit | same | No — Wave 0 |
| PROOF-01 | Hermetic CI lane passes: Plug+telemetry, forbidden-key rejection, gen.audit idempotency, doctor findings, guide parity | CI integration | `.github/workflows/phase96-proof.yml` | No — Wave 0 |
| PROOF-02 | Advisory: Ecto-backed record_in_multi/3 + threadline reconstruction | advisory integration | `.github/workflows/phase96-proof-advisory.yml` | No — Wave 0 |

### Wave 0 Gaps
- [ ] `test/crosswake/proof/phase96_threadline_docs_contract_test.exs` — covers DOCS-01/02/03 + PROOF-01 parity
- [ ] `examples/phoenix_host/lib/crosswake_example/audit/ledger.ex` — committed gen.audit output (PROOF-02)
- [ ] `examples/phoenix_host/priv/repo/migrations/TIMESTAMP_create_crosswake_audit_events.exs` — committed migration (PROOF-02)
- [ ] `examples/phoenix_host/test/crosswake_example/threadline/phase96_example_host_ledger_proof_test.exs` — covers PROOF-02
- [ ] `.github/workflows/phase96-proof.yml` — merge-blocking CI lane (PROOF-01)
- [ ] `.github/workflows/phase96-proof-advisory.yml` — advisory CI lane (PROOF-02)

---

## Security Domain

Not applicable. This phase writes documentation and test assertions; it introduces no authentication, session management, input handling, or cryptographic operations. The shipped runtime code (Plug, Telemetry, Doctor) is already security-reviewed. The guides document the existing PII-free-by-construction posture but do not change it.

---

## Sources

### Primary (HIGH confidence)
- `lib/crosswake/threadline/telemetry.ex` — verified event_names, metadata_keys, forbidden_metadata_keys values
- `lib/crosswake/plug/threadline.ex` — verified header_name NimbleOptions default `"x-crosswake-thread-id"`
- `lib/crosswake/audit/ledger.ex` — verified defstruct with 15 columns
- `priv/templates/crosswake/audit/ledger.ex.eex` — verified generated schema, record_in_multi/3 arity, @forbidden_keys (8 ledger PII keys)
- `priv/templates/crosswake/audit/migration.exs.eex` — verified column definitions + unique_index on idempotency_key
- `lib/crosswake/doctor/doctor.ex` — verified @canonical_ledger_columns, all 5 threadline finding codes + severities
- `guides/threadline.md` — verified current 70-line content, opening sentence anchor
- `test/crosswake/guides/release_boundaries_test.exs` — verified contains-exact docs test pattern
- `test/crosswake/support_matrix/support_matrix_test.exs:255-303` — verified docs_anchor assertions + code-derived parity pattern + custom failure message pattern
- `test/crosswake/proof/phase52_operator_truth_test.exs:215-221` — verified hermetic lane guard pattern (no @moduletag, no CrosswakeExample.)
- `test/crosswake/proof/phase91_threadline_contract_closeout_test.exs` — verified phase91 is hermetic, uses async: false
- `test/crosswake/proof/phase92_server_propagation_closeout_test.exs` — verified hermetic self-assertion pattern
- `test/mix/tasks/crosswake.threadline_test.exs` — verified Mix.Task.reenable + Application.put_env cleanup pattern
- `test/mix/tasks/crosswake.gen.audit_test.exs` — verified gen.audit task invocation pattern
- `test/crosswake/doctor/doctor_threadline_test.exs` — verified doctor threadline finding codes match shipped source
- `.github/workflows/phase73-proof.yml` — verified SHA-pinned actions, compile-then-test step structure
- `.github/workflows/phase75-closeout-gate.yml` — verified Elixir/OTP versions (1.19.5/27.3), permissions: contents: read
- `.github/workflows/phase23-proof.yml` — verified advisory lane pattern (schedule/dispatch gating, ::notice annotation)
- `examples/phoenix_host/test/crosswake_example/flashcards_test.exs` — verified Repo.delete_all setup (not on_exit) pattern
- `examples/phoenix_host/config/config.exs` — verified single config file (no test-env split)
- `examples/phoenix_host/mix.exs:29` — verified ecto_sqlite3 ~> 0.16 dependency
- `.planning/phases/96-docs-contract-proof/96-CONTEXT.md` — all locked decisions sourced here

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; all assertions use shipped Elixir stdlib + existing project patterns
- Architecture: HIGH — every file path, function name, and module name verified from source
- Pitfalls: HIGH — all pitfalls derived from code inspection and explicit CONTEXT.md warnings
- CI patterns: HIGH — verified from existing workflow files with exact SHA pins

**Research date:** 2026-06-10
**Valid until:** Stable (guide file paths and public API names are frozen contract; LEDG-02 columns are frozen)
