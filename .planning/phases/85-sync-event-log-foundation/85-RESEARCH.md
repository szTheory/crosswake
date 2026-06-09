# Phase 85: Sync & Event Log Foundation - Research

**Researched:** 2024-06-08
**Domain:** Crosswake Sync, Idempotency, Ecto Schema Templates
**Confidence:** HIGH

## Summary

Crosswake's sync foundation bridges the client's `Crosswake.Offline.Journal.Entry` to the server's authoritative state via Replay Requests. The server must durably log these mutation requests in an `EventLog` to ensure idempotency when clients retry over spotty networks. Because Crosswake deliberately avoids coupling core framework code to `Ecto.Schema` (as seen in the `SelectiveNative` and `Chimeway` companions, as well as the `phase8_selective_native_lane_test.exs` tests), `Crosswake.Sync.EventLog` will define the structural contracts, while the actual Ecto schema and Phoenix controller logic are host-owned, generated into the host application (much like `crosswake.gen.shell` or existing examples). 

**Primary recommendation:** Define the core structs (`Crosswake.Sync.EventLog.Entry`) in the library, but provide Ecto schemas and a SyncController as generated host templates so the developer retains ownership of the `Repo` and schema table names.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Idempotency Key Gen | Client | API / Backend | Client generates UUIDv4 `idempotency_key` (via Journal). Backend enforces uniqueness. |
| Sync Event Storage | Database / Storage | API / Backend | PostgreSQL `sync_event_logs` table with unique constraint on `idempotency_key` ensures atomicity. |
| Reconciliation | API / Backend | Database | Phoenix controllers receive Replay Request batches, use `Ecto.Multi` for atomicity, and return `Outcome` payloads. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ecto | ~> 3.10 | Database abstractions | Standard Elixir DB toolkit. |
| ecto_sql | ~> 3.10 | PostgreSQL integration | Used by the Phoenix host to define unique constraints on idempotency keys. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| phoenix | ~> 1.7 | HTTP routing / JSON | For the reconciliation controller endpoint. |

## Package Legitimacy Audit
No new packages are being installed in this phase.

## Architecture Patterns

### System Architecture Diagram

```text
[Client (Offline Journal)]
         |
         | 1. POST /api/sync/replay (Batch of Replay Requests)
         v
[Phoenix Controller (SyncController)]
         |
         | 2. Map Requests to Ecto Changesets
         v
[Ecto.Multi Transaction (SyncContext)]
         |
         | 3a. Insert EventLog entries (on_conflict: nothing, conflict_target: idempotency_key)
         | 3b. Apply Business Logic for valid new requests
         v
[PostgreSQL Database]
         |
         | 4. Return accepted/rejected/conflict Outcomes
         v
[Client (Updates Journal Status)]
```

### Pattern 1: Host-Owned Ecto Schemas
**What:** Crosswake does not embed Ecto schemas in the `lib/crosswake/` core directory.
**When to use:** When adding data layers like `Sync.EventLog` to the framework.
**Example:**
```elixir
# In the host application (e.g., generated via mix task or docs)
defmodule MyApp.Sync.EventLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "crosswake_sync_event_logs" do
    field :idempotency_key, :string
    field :route_id, :string
    field :sync_seam, :string
    field :operation, :string
    field :payload, :map
    field :status, :string
    field :authoritative_state, :map
    field :reason, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(event_log, attrs) do
    event_log
    |> cast(attrs, [:idempotency_key, :route_id, :sync_seam, :operation, :payload, :status, :authoritative_state, :reason])
    |> validate_required([:idempotency_key, :route_id, :sync_seam, :operation, :status])
    |> unique_constraint(:idempotency_key)
  end
end
```

### Pattern 2: Ecto.Multi with `on_conflict: :nothing`
**What:** Inserting replay batches via `Ecto.Multi` while gracefully ignoring duplicates.
**When to use:** In the Sync controller/context for atomic idempotent batch processing.

### Anti-Patterns to Avoid
- **Coupling Core to Ecto:** Do not define `Ecto.Schema` inside `lib/crosswake/sync/`. The core library is strictly isolated from Ecto dependency.
- **Application-Level Idempotency Checks:** Do not manually check for duplicate `idempotency_key` via `Repo.get_by` followed by an insert. Use database unique constraints (`on_conflict: :nothing`) to avoid race conditions.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Atomic idempotent inserts | Manual lock + check + insert | `Ecto.Multi.insert_all(..., on_conflict: :nothing)` | Prevents race conditions during concurrent client retries. |

## Common Pitfalls

### Pitfall 1: Leaking Ecto into Crosswake Core
**What goes wrong:** Ecto schemas and `Repo` calls are added to `lib/crosswake/sync/`.
**Why it happens:** Attempting to provide a "batteries included" `EventLog`.
**How to avoid:** Define pure structs (`Crosswake.Sync.EventLog.Entry`) in the core, and provide generator templates (`priv/templates/...`) for the host application to use.

### Pitfall 2: Handling Replay Duplicates Badly
**What goes wrong:** Client sends a replay request that was already successfully processed. Server throws a uniqueness constraint error instead of succeeding.
**Why it happens:** The endpoint fails to recognize the duplicate as a successful retry.
**How to avoid:** If `on_conflict: :nothing` drops the insert because it exists, query the database for the existing record by `idempotency_key` and simply return the previously computed `Crosswake.Offline.Replay.Outcome`.

## Code Examples

### Handling Batch Idempotent Inserts
```elixir
# Inside a Sync context module on the server
Ecto.Multi.new()
|> Ecto.Multi.insert_all(:sync_logs, MyApp.Sync.EventLog, valid_events,
  on_conflict: :nothing,
  conflict_target: :idempotency_key,
  returning: true
)
|> Repo.transaction()
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Ad-hoc `ReviewEvent` | Unified `Crosswake.Sync.EventLog` | Phase 85 | Removes the need for individual sync tables for every domain concept; routes all offline reloads through one idempotency layer. |

## Open Questions (RESOLVED)

1. **Generation Strategy**
   - What we know: Crosswake prefers additive install manifests and explicit host ownership.
   - What's unclear: Should the Sync schema be generated via a new mix task (e.g. `mix crosswake.gen.sync`) or just provided as documentation templates?
   - Recommendation: Add a generator or extend `crosswake.install` so users get it out-of-the-box.
   - **RESOLVED:** The planner confirmed we will implement a generator `mix crosswake.gen.sync` for this.
