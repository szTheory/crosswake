<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Schema and Ecto Types
- **D-01: Provenance Field as Ecto.Enum:** Use `Ecto.Enum` for the `provenance` field `{:device_claimed, :backend_accepted}` to enforce at the application layer while generating a standard string or integer column in the database, avoiding native DB enums for simpler migrations.
- **D-02: Opaque Actor Ref and HMAC Helper:** The `actor_ref` is stored as an opaque string. Provide a helper (e.g., `Crosswake.Audit.actor_ref/2`) that uses `:crypto.mac` to anonymize internal user IDs, mirroring the pattern in `Chimeway.Redaction.fingerprint_token/2`.
- **D-08: Customizable Schema Name:** Convention over Configuration. The generator automatically derives the host app's base namespace and enforces `MyApp.Audit.Ledger` and table `crosswake_audit_ledger` instead of taking it as a CLI argument. This eliminates wiring boilerplate for day-2 ops tools.
- **D-09: Metadata Serialization:** Native Ecto `:map` (JSONB). Use Ecto `:map` for metadata, seamlessly translating to JSONB in Postgres, allowing the `reject_pii_in_metadata/1` guard to iterate over native Elixir map keys. No extra serialization dependencies required.

### Security and PII Guard
- **D-03: Changeset Fail-Closed Guard:** The `reject_pii_in_metadata/1` is implemented as an Ecto Changeset function. It iterates over the keys in the `metadata` map and adds an error if any key matches a generated `@forbidden_keys` list (e.g., email, ip, name). This ensures records cannot be inserted if PII slips in.
- **D-07: HMAC Secret Source:** Dual-mode fallback. The `actor_ref` helper defaults to checking the app config (`Application.get_env(:crosswake, :audit_hmac_secret)`) but accepts overrides via keyword list (`opts`).

### Immutability and Hashing
- **D-04: Append-Only by Omission:** Do not generate any `update` or `delete` functions or changeset wrappers for them. The Ecto schema should be treated as insert-only.
- **D-05: Advisory Hash Computation:** The `row_hash` and `prev_hash` are computed prior to insert. To avoid race conditions blocking concurrent inserts, `prev_hash` is "best effort" or "advisory" at insert time. The docstrings must explicitly state this is advisory for offline tamper detection. Use `:crypto.hash(:sha256, ...)` for the `row_hash`.

### Generator UX
- **D-06: Idempotent File Generation:** If the target migration or schema file already exists, `mix crosswake.gen.audit` prints `[crosswake] reused` and skips overwriting. Specifically for the migration: check for existing by name suffix (e.g., `*create_crosswake_audit_ledger.exs`). Scan for the suffix. If found, print `[crosswake] reused`. If absent, generate with a fresh timestamp. This prevents duplicate migration footguns.

### the agent's Discretion
None

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LEDG-01 | A team can run `mix crosswake.gen.audit` to scaffold a host-owned Ecto audit schema and thin writer — idempotent, never overwriting host edits. | Identified Mix generator and suffix-scanning patterns matching `gen.sync` behavior. |
| LEDG-02 | The generated ledger records terminal critical events with the canonical columns. | Listed the exact Ecto schema structure and types required to mirror `Crosswake.Audit.Ledger`. |
| LEDG-03 | The ledger is PII-free by construction — opaque `actor_ref` (HMAC), `reject_pii_in_metadata/1` guard fails closed on forbidden keys. | Documented the `:crypto.mac` approach and the Ecto Changeset fail-closed array-iteration pattern for metadata string/atom keys. |
| LEDG-04 | First-class `provenance ∈ {:device_claimed, :backend_accepted}`. | Addressed using `Ecto.Enum` mapped to a string field in Postgres. |
| LEDG-05 | `record/1` or `record_in_multi/2` provided, with accurate transactionality docstrings. | Provided standard function signatures for Ecto Repo schema insertion vs `Ecto.Multi.insert`. |
| LEDG-06 | Append-only — no update/delete helpers. Advisory `row_hash`/`prev_hash`. | Documented `:crypto.hash(:sha256)` computations and `prev_hash` best-effort fetching prior to insert. |
</phase_requirements>

# Phase 94: Audit Ledger Contract + Generator - Research

**Researched:** 2026-06-09
**Domain:** Elixir / Ecto / Mix Task Generators
**Confidence:** HIGH

## Summary

The phase provides a mix generator (`mix crosswake.gen.audit`) that creates an opt-in, PII-free, append-only Ecto audit ledger. The generator writes a host-owned Ecto schema (`MyApp.Audit.Ledger`), a thin writer, and an idempotent migration. The core package will also export a `Crosswake.Audit.Ledger` contract struct as a canonical event shape, but the actual database interaction is completely owned by the host app. 

The security posture heavily relies on removing PII before it reaches the DB, utilizing OTP's built-in `:crypto` to HMAC the `actor_ref` and providing a fail-closed Ecto Changeset validation to reject forbidden PII keys in the `metadata` JSONB map.

**Primary recommendation:** Use standard Mix Generator practices (`Mix.Task`, `EEx.eval_file`, Ecto schema generation) and standard `:crypto` functions (`:crypto.mac`, `:crypto.hash`) for PII redaction and hashing, closely mirroring the file idempotency behavior found in `crosswake.gen.sync`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Audit Contract | API / Backend (Core) | — | The `Crosswake.Audit.Ledger` struct defines the canonical event shape for all backend producers. |
| DB Schema & Migration | API / Backend (Host) | Database | Generator creates host-owned Ecto schema and Postgres migration files, so the host retains full db ownership. |
| HMAC Anonymization | API / Backend (Host) | — | PII (actor_ref) must be redacted *before* it enters the DB layer; handled in application logic via `actor_ref/2`. |
| Tamper Hashing | API / Backend (Host) | — | Advisory hashes computed at application layer prior to DB insert; Ecto is the source of truth for the hash. |
| Append-Only Guard | API / Backend (Host) | — | Enforced structurally by omitting `update` or `delete` wrappers from the generated thin writer module. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Ecto | ~> 3.10 | Schema, Migrations, Changesets | The Elixir ecosystem standard for database interaction. |
| :crypto | OTP built-in | HMAC (`:crypto.mac`) & SHA256 (`:crypto.hash`) | Standard OTP module, zero extra dependencies, used in Chimeway. |
| Mix | OTP built-in | Task generation and EEx templating | Standard Elixir tool for building `mix` tasks and scaffolding. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Host-owned schema | Library-owned schema (`Crosswake.AuditEvents`) | Library-owned means hosts can't easily extend or manage DB indices. Host-owned guarantees operational control. |
| Ecto.Enum | Postgres Native Enum | Native DB enums make migrations complex if the enum needs to grow. Ecto.Enum translates cleanly to `string`. |
| ExCrypto / Bcrypt | `:crypto` | Adding dependencies for simple hashing adds unnecessary weight when Erlang `:crypto` is readily available. |

## Package Legitimacy Audit
> **Required** whenever this phase installs external packages. 

*No external packages are installed in this phase. The solution relies strictly on built-in `:crypto`, `Ecto` (already present), and `Mix`.*

## Architecture Patterns

### Recommended Project Structure
```text
lib/crosswake/audit/ledger.ex         # Core contract struct defining canonical shape
lib/mix/tasks/crosswake.gen.audit.ex  # Generator Mix Task
priv/templates/crosswake/audit/ledger.ex.eex      # Template for MyApp.Audit.Ledger
priv/templates/crosswake/audit/migration.exs.eex  # Template for Ecto migration
```

### Pattern 1: Idempotent File Generation
**What:** Generator tasks should check for existing files to avoid overwriting host edits.
**When to use:** In `mix crosswake.gen.audit` when writing the schema or migration.
**Example:**
```elixir
defp ensure_file(path, contents) do
  if File.exists?(path) do
    Mix.shell().info("  [crosswake] reused #{Path.relative_to_cwd(path)}")
  else
    File.write!(path, contents)
    Mix.shell().info("  [crosswake] created #{Path.relative_to_cwd(path)}")
  end
end

defp migration_exists?(dir, suffix) do
  dir |> File.ls!() |> Enum.any?(&String.ends_with?(&1, suffix))
end
```

### Pattern 2: Fail-Closed PII Guard in Changeset
**What:** An Ecto Changeset function that iterates over the `metadata` map and rejects if it contains any key in a forbidden PII list.
**When to use:** When validating the schema changeset before insert.
**Example:**
```elixir
@forbidden_keys [:email, :phone, :ip_address, :ssn, :name, :first_name, :last_name, :address]

def reject_pii_in_metadata(changeset) do
  case get_change(changeset, :metadata) do
    nil -> changeset
    metadata ->
      Enum.reduce(@forbidden_keys, changeset, fn key, cs ->
        if Map.has_key?(metadata, key) or Map.has_key?(metadata, to_string(key)) do
          add_error(cs, :metadata, "contains forbidden PII key: #{key}")
        else
          cs
        end
      end)
  end
end
```

### Pattern 3: Advisory Hash Computation
**What:** Using `:crypto.hash(:sha256, ...)` to generate a `row_hash` and `prev_hash` before insertion.
**When to use:** Inside the thin writer's insertion preparation.
**Example:**
```elixir
defp compute_hashes(changeset) do
  payload = "#{get_field(changeset, :thread_id)}|#{get_field(changeset, :actor_ref)}|#{get_field(changeset, :event_class)}"
  hash = :crypto.hash(:sha256, payload) |> Base.encode16(case: :lower)
  
  # prev_hash is advisory at insert time
  prev = fetch_latest_hash() || "genesis"
  
  changeset
  |> put_change(:row_hash, hash)
  |> put_change(:prev_hash, prev)
end
```

### Anti-Patterns to Avoid
- **Generating DB Native Enums:** Causes pain during db migrations. Use Ecto string field paired with `Ecto.Enum`.
- **Generating `update` or `delete` contexts:** The ledger must be append-only. Only generate `record/1` and `record_in_multi/2`.
- **Requiring `actor_ref` HMAC secret as a mandatory CLI arg:** Use dual-mode configuration fallback (`Application.get_env` or `opts` keyword list) for developer ergonomics.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| File existing checks | Custom string manipulation for migration timestamps | Mix's standard patterns / checking by migration suffix (`*create_crosswake_audit_events.exs`) | Standard behavior, handles existing timestamps gracefully without duplicate migrations. |
| HMAC Anonymization | Custom hashing | `:crypto.mac(:hmac, :sha256, ...)` | Erlang built-in provides cryptographically secure HMAC without dependency weight. |
| JSON DB fields | Raw database string encoding | Ecto `:map` type | Serializes perfectly to JSONB in Postgres, and allows checking map keys directly in Elixir changesets. |

## Common Pitfalls

### Pitfall 1: Migration Race Conditions / Duplication
**What goes wrong:** Running the generator twice creates two migration files with different timestamps.
**Why it happens:** Generator always uses `DateTime.utc_now()` for the filename prefix.
**How to avoid:** Check `priv/repo/migrations/` for any file ending in the expected suffix (e.g., `_create_crosswake_audit_events.exs`). If found, skip generation and print `[crosswake] reused`.

### Pitfall 2: Silently Accepting PII
**What goes wrong:** A developer passes `metadata: %{"email" => "user@example.com"}` and it gets stored in the DB.
**Why it happens:** Ecto `:map` allows arbitrary shapes without validation.
**How to avoid:** The generated schema MUST include `reject_pii_in_metadata/1` as part of the `changeset/2` pipeline, enforcing it as a fail-closed hard error.

### Pitfall 3: Blocking Inserts on `prev_hash`
**What goes wrong:** High-throughput concurrent inserts fail due to race conditions when reading `prev_hash`.
**Why it happens:** Database locks when querying the strict last row.
**How to avoid:** The CONTEXT D-05 mandates that `prev_hash` is advisory and best-effort at insert time. The docstrings must reflect this.

## Code Examples

### Standalone and Multi Writes
```elixir
@doc """
Records an audit event immediately.
Not transactionally atomic with caller mutations.
"""
def record(attrs) do
  %__MODULE__{}
  |> changeset(attrs)
  |> Repo.insert()
end

@doc """
Appends the audit event to an existing Ecto.Multi.
Provides transactional guarantees.
"""
def record_in_multi(multi, name, attrs) do
  changeset = changeset(%__MODULE__{}, attrs)
  Ecto.Multi.insert(multi, name, changeset)
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| DB Triggers for Auditing | Application-Layer Ledger | Now | Allows rich metadata, unified correlation IDs, and application-level PII checking. |
| Library-Owned Schema | Host-Owned Generated Schema | Phase 94 | Hosts can customize indexes, table partitioning, and db locations without library forks. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `crosswake_audit_events` is the correct DB table name over `crosswake_audit_ledger` | Architecture | The DB table name might not match downstream testing expectations. LEDG-02 explicitly asks for `crosswake_audit_events`. We will fulfill LEDG-02 while keeping `MyApp.Audit.Ledger` as the module name (per D-08). |
| A2 | PII Guard checking covers string and atom keys. | Architecture Patterns | If not checking both, string-keyed JSON maps might bypass the guard. |

## Open Questions

1. **Table Naming Conflict**
   - What we know: CONTEXT D-08 specifies table `crosswake_audit_ledger`. REQUIREMENTS (LEDG-02) specifies `crosswake_audit_events`.
   - Recommendation: Default to schema module `MyApp.Audit.Ledger` and table name `crosswake_audit_events` to satisfy both the module convention and the formal requirement statement.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Mix / Elixir | Generation Task | ✓ | 1.19.5 | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LEDG-01 | Generator scaffolds schema/migration idempotently | unit | `mix test test/mix/tasks/crosswake.gen.audit_test.exs` | ❌ Wave 0 |
| LEDG-02 | Generated ledger has canonical columns | unit | `mix test test/mix/tasks/crosswake.gen.audit_test.exs` | ❌ Wave 0 |
| LEDG-03 | PII metadata guard fails closed, actor_ref HMAC works | unit | `mix test test/crosswake/audit/ledger_test.exs` | ❌ Wave 0 |
| LEDG-04 | Provenance is Ecto.Enum | unit | `mix test test/mix/tasks/crosswake.gen.audit_test.exs` | ❌ Wave 0 |
| LEDG-05 | `record/1` and `record_in_multi/2` exist | unit | `mix test test/mix/tasks/crosswake.gen.audit_test.exs` | ❌ Wave 0 |
| LEDG-06 | Append-only, advisory hash | unit | `mix test test/mix/tasks/crosswake.gen.audit_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/mix/tasks/crosswake.gen.audit_test.exs` — covers LEDG-01, LEDG-02, LEDG-04, LEDG-05, LEDG-06
- [ ] `test/crosswake/audit/ledger_test.exs` — covers the `Crosswake.Audit.Ledger` struct and its validation constraints (LEDG-03)

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Ecto Changeset validations + `reject_pii_in_metadata/1` |
| V6 Cryptography | yes | `:crypto.mac` for HMAC, `:crypto.hash` for hashing. No custom crypto. |

### Known Threat Patterns for Elixir / Ecto

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| PII Injection in Logs | Information Disclosure | PII allowlist/denylist in Changesets before inserting to JSONB. |
| Audit Trail Tampering | Tampering | Advisory hash chains (`prev_hash`, `row_hash`) created at insertion to detect offline DB edits. |

## Sources

### Primary (HIGH confidence)
- `094-CONTEXT.md` - Phase constraints and decisions
- `REQUIREMENTS.md` - Phase requirements
- `lib/crosswake/threadline/telemetry.ex` - Telemetry keys and PII patterns
- `lib/crosswake/companions/chimeway/redaction.ex` - Pattern for HMAC hashing using `:crypto.mac`

### Secondary (MEDIUM confidence)
- Standard HexDocs for `Ecto.Enum` and `Ecto.Changeset`

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core Elixir/OTP standard functions
- Architecture: HIGH - Mapped directly from provided guidelines
- Pitfalls: HIGH - Documented common generator footguns

**Research date:** 2026-06-09
**Valid until:** 2026-07-09
