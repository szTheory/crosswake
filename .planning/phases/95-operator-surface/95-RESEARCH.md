# Phase 95: Operator Surface - Research

**Researched:** 2026-06-09
**Domain:** Elixir CLI Tooling & Operator Experience
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Use a structured text tree with Unicode connectors (similar to `mix deps.tree` or `mix phx.routes`) rather than a dense, wide table. A tree intuitively maps the Native → Bridge → Phoenix sequence without horizontal scrolling, offering vastly superior DevEx.
- **D-02:** Cleanly print the ephemeral posture message ("Posture: Ephemeral. No ledger configured.") and exit 0. Since the ledger is opt-in, ephemeral is a valid, documented state, not a failure. Exiting 1 would violate the principle of least surprise and break CI scripts.
- **D-03:** List the exact offending keys and the Ecto schema/module name, but do *not* attempt AST parsing for line numbers. In Elixir, data-centric error reporting is idiomatic; AST parsing is brittle and prone to false positives in macro-heavy code.

### the agent's Discretion
(None specifically listed, but implementation details for tree output and configuration fetching are derived below.)

### Deferred Ideas (OUT OF SCOPE)
- A visual LiveDashboard / LiveView timeline UI is deferred to a future `crosswake_dashboard` package (as noted in project requirements).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OPER-01 | `mix crosswake.threadline` prints tree timeline with posture | Elixir Mix task patterns, `OptionParser`, Ecto Repo queries, Unicode text-tree formatting |
| OPER-02 | `mix crosswake.doctor` reports Threadline posture | Doctor check implementations using `__schema__(:fields)` and app environment config |
| OPER-03 | Support matrix exposes `@audit_ledger_support_truth` | Adding module attributes in `Crosswake.SupportMatrix` |
</phase_requirements>

## Summary

This phase introduces the primary operator interfaces for the Threadline Audit feature. It consists of three components: a new CLI task (`mix crosswake.threadline`) that presents a timeline of events via a text-tree, static and reflection-based validations in the existing `mix crosswake.doctor` task, and the formal declaration of Threadline capabilities in the `Crosswake.SupportMatrix`. The implementation prioritizes data-centric diagnostics over brittle AST parsing, ensuring the ledger's integrity and compliance with privacy constraints (PII).

**Primary recommendation:** Use Ecto's `__schema__(:fields)` to enforce the PII blocklist cleanly during Doctor checks. Implement the text-tree formatter directly using recursive tree logic in Elixir to avoid heavy dependency footprints, honoring the text-only UI requirement.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| **Operator CLI UI** | API / Backend (Mix Task) | — | The timeline tree is rendered strictly in the console via a Mix task. |
| **Doctor Validations** | API / Backend (Doctor) | — | Schema checks and plug verifications run statically during host diagnostics. |
| **Support Contract** | API / Backend (SupportMatrix)| — | The baseline posture and support states are codified in compile-time module attributes. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `OptionParser` | (Built-in) | CLI arg parsing | Built into Elixir; zero-dependency way to parse `--thread-id`. |
| `Ecto.Query` | (Existing) | Fetching events | Standard way to query the database given a host's Ecto repo. |
| `Application` | (Built-in) | Configuration lookup | Idiomatic Elixir pattern (`Application.get_env`) to locate the host's ledger module. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Mix.Shell.IO` | (Built-in) | Output formatting | Preferred for emitting CLI messages (supports `info/1`, `error/1`). |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom tree formatting | `termtree` package | Crosswake limits external dependencies; a simple recursive text-tree formatter can be hand-rolled safely. |
| AST-based checks | `__schema__(:fields)` | AST parsing is too brittle for PII-field detection. Reflection via `__schema__` gives exactly what Ecto will persist. |

## Package Legitimacy Audit

> **Required** whenever this phase installs external packages.

**None.** This phase only utilizes built-in Elixir/Mix functionality and the existing Ecto dependency. No external packages are introduced.

## Architecture Patterns

### Text-Tree Output Formatting (OPER-01)
To satisfy **D-01**, `mix crosswake.threadline` should build a nested structure and format it cleanly with Unicode connectors (e.g., `├── `, `└── `, `│   `). Grouping events by tier (Native → Bridge → Phoenix) provides the chronological correlation required.

### Data-Centric Schema Validations (OPER-02 / D-03)
To validate the user's ledger against schema drift and PII rules without AST parsing, the doctor should rely on Ecto's reflection API. By dynamically loading the user-configured schema module, the doctor can check `schema.__schema__(:fields)`.

### Ledger Configuration Contract
The application must provide the ledger's configuration. The standard approach for Crosswake extensions is for the host to define them in `config.exs`:
```elixir
config :crosswake,
  audit_repo: MyApp.Repo,
  audit_ledger: MyApp.Audit.Ledger
```
If `Application.get_env(:crosswake, :audit_ledger)` is `nil`, the posture is `ephemeral`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PII Field Parsing | Regex or AST traversals | `schema.__schema__(:fields)` | D-03 strictly limits parsing. Ecto reflection natively extracts the exact field names. |
| CLI Argument Processing | Manual string splitting | `OptionParser.parse/2` | Robust handling of `--thread-id <id>` and `--actor-ref <ref>` with validation. |

## Common Pitfalls

### Pitfall 1: Breaking CI on Expected States
**What goes wrong:** `mix crosswake.threadline` exits with code `1` when the ledger is not configured.
**Why it happens:** Treating an unconfigured opt-in feature as an error state.
**How to avoid:** Explicitly follow **D-02**: Print the "Posture: Ephemeral" message using `Mix.shell().info/1` and allow the task to exit normally (which returns code `0`).

### Pitfall 2: Ecto Not Started in Mix Task
**What goes wrong:** The threadline task attempts to query the database, but it errors out because the Repo or Ecto application is not started.
**Why it happens:** Mix tasks do not start the application by default.
**How to avoid:** Call `Mix.Task.run("app.start")` (or explicitly start the Repo) within `mix crosswake.threadline` before attempting any database queries if the posture is `durable`.

### Pitfall 3: Crashing Doctor on Missing Module
**What goes wrong:** The doctor crashes when trying to call `__schema__(:fields)` on an `audit_ledger` module that fails to compile or was deleted.
**Why it happens:** Blindly executing reflection functions on unverified module atoms.
**How to avoid:** Use `Code.ensure_loaded?(schema)` before calling `__schema__/1`.

## Code Examples

### Idiomatic CLI Flag Parsing
```elixir
def run(args) do
  {opts, _, _} = OptionParser.parse(args, strict: [thread_id: :string, actor_ref: :string])
  
  thread_id = Keyword.get(opts, :thread_id)
  actor_ref = Keyword.get(opts, :actor_ref)

  cond do
    thread_id == nil and actor_ref == nil ->
      Mix.raise("Expected either --thread-id or --actor-ref")
    true ->
      execute(thread_id, actor_ref)
  end
end
```

### Fetching Ledger Posture
```elixir
def ledger_posture do
  repo = Application.get_env(:crosswake, :audit_repo)
  schema = Application.get_env(:crosswake, :audit_ledger)

  if repo && schema do
    {:durable, repo, schema}
  else
    :ephemeral
  end
end
```

### Validating Schema for PII (Doctor Check)
```elixir
defp check_pii_forbidden_fields(schema) do
  if Code.ensure_loaded?(schema) and function_exported?(schema, :__schema__, 1) do
    fields = schema.__schema__(:fields)
    forbidden = [:email, :ip_address, :user_id, :name] # derived from SupportMatrix
    
    offending_keys = Enum.filter(fields, &(&1 in forbidden))
    
    if offending_keys != [] do
      # emit threadline.pii_forbidden_field_present error
    end
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Wide dense console tables | Structured Text Trees (`├──`) | Phase 95 | Much better developer experience (DevEx) for reading temporal causality. |
| AST-based validations | Ecto Reflection (`__schema__`) | Phase 95 | Data-centric, robust, and zero false-positives when asserting schema compliance. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The application configures `:audit_repo` and `:audit_ledger` under the `:crosswake` application config. | Architecture Patterns | If the configuration format diverges, the Doctor and CLI tool will fail to detect durable posture, defaulting incorrectly to ephemeral. |
| A2 | The telemetry allowed/forbidden field list is defined inside the existing `Crosswake.SupportMatrix` or a shared auth/telemetry module (from Phase 91/94). | Common Examples | Code duplication if the forbidden list is hardcoded in the Doctor instead of pulling from the source of truth. |

## Open Questions

1. **How is the `Crosswake.Plug.Threadline` usage verified statically?**
   - What we know: Doctor must report `threadline.plug_missing`.
   - What's unclear: Does the doctor analyze the `router_path` string via Regex/Regex-like scanning or use the AST to verify the Plug is present in a pipeline?
   - Recommendation: Use a lightweight string scan (`String.contains?(contents, "plug Crosswake.Plug.Threadline")`) inside the router file read to avoid deep AST complexities, aligning with D-03's philosophy on AST parsing.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/crosswake/mix/tasks/threadline_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OPER-01 | `mix crosswake.threadline` tree output | unit | `mix test test/mix/tasks/crosswake.threadline_test.exs` | ❌ Wave 0 |
| OPER-02 | `mix crosswake.doctor` checks | unit | `mix test test/crosswake/doctor/doctor_test.exs` | ✅ Wave 0 |
| OPER-03 | `@audit_ledger_support_truth` exported | unit | `mix test test/crosswake/support_matrix/support_matrix_test.exs` | ✅ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test <specific_file>`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/mix/tasks/crosswake.threadline_test.exs` — covers OPER-01 (CLI format and exit code).

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | CLI `OptionParser` strict validation |
| V6 Cryptography | no | — |

### Known Threat Patterns for Elixir CLI

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| PII Data Leakage | Information Disclosure | Doctor enforces strict PII blocklist via `__schema__(:fields)` checks to prevent the persistent storage of PII in the local developer DB (OPER-02). |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/95-operator-surface/95-CONTEXT.md` - Phase constraints, decision records, and text-tree requirements.
- `.planning/REQUIREMENTS.md` - Canonical definitions for OPER-01, OPER-02, OPER-03.
- `lib/crosswake/doctor/doctor.ex` - Context on existing Doctor architecture.
- `lib/mix/tasks/crosswake.gen.audit.ex` - Context on how Phase 94 generates the ledger.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core Elixir tools perfectly match requirements.
- Architecture: HIGH - Dictated by detailed project design decisions (D-01 to D-03).
- Pitfalls: HIGH - Elixir/Mix task edge-cases (app unstarted) are well documented standard knowledge.

**Research date:** 2026-06-09
**Valid until:** 30 days
