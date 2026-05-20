# Phase 9: Local-First Content Flow Exemplar - Research

**Researched:** 2026-05-18
**Domain:** Phoenix Offline Reconciliation & Local-First Exemplar
**Confidence:** HIGH

## Summary

Phase 9 proves the Local-First Content Flow adopter lane within the shared example Phoenix host. It establishes a realistic study session or flashcard flow that pressures Crosswake's `offline: :island` and `offline: :cached` route postures. The local-first mutation strategy leverages an append-only journal model instead of fragile last-write-wins (LWW) state mutation. This ensures that disconnected offline events—even from multiple devices—are deterministically reconciled on the Phoenix server without data loss.

**Primary recommendation:** Use an append-only `review_events` journal on the offline island that syncs to a dedicated Phoenix reconciliation controller, recomputing canonical progress state server-side.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
#### Product slice
- **D-01:** The local-first exemplar should be a study session or flashcard flow, which inherently requires offline progression and eventual synchronization.
- **D-02:** The lane should feel like a believable offline-capable application where the user can complete meaningful work while disconnected, relying on the journal, outbox, and replay mechanisms built in Phase 4.
- **D-03:** The domain is chosen because it pressures offline islands, cached read-only degradation, and content packs.

#### Route map and lane structure
- **D-04:** The lane should use dedicated routes under a `/local` or `/study` scope to keep the exemplar distinct from Phase 7 (SaaS) and Phase 8 (Selective Native).
- **D-05:** Routes should clearly demonstrate `offline: :island` and `offline: :cached` postures.
- **D-06:** The module and router shape should use a dedicated `CrosswakeExample.LocalFirst.*` namespace.

#### Offline and Cache Posture
- **D-07:** The exemplar must prove both offline-island work (mutable journal/outbox) and cached read-only degradation (can view but not change).
- **D-08:** The sync and reconciliation process must be explicit, proving that adopters can verify how replays happen.

#### Security, sensitivity, and review posture
- **D-09:** The local-first story must stay honest about what can be achieved fully locally, what is merely cached for read-only access, and what strictly requires server authority.

### the agent's Discretion
None explicitly declared in CONTEXT.md.

### Deferred Ideas (OUT OF SCOPE)
- This phase does not build generalized local-first database replication, CRDT primitives, complex background sync engines, or offline identity provisioning.
</user_constraints>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| **Content Delivery** | API / Backend | CDN | The Phoenix server bundles cards/lessons into a `ContentPack` (`daily_study`). |
| **Offline Rendering** | Native Shell / Local | — | The local native shell renders the `offline: :island` view during the study session. |
| **Mutation Journal** | Native Shell / Local | — | Study actions are logged as an append-only `review_events` log on the client outbox. |
| **State Recomputation**| API / Backend | — | The server resolves events in an `Ecto.Multi` transaction to derive canonical card progress, eliminating multi-device conflict. |
| **Conflict UI** | Frontend Server (SSR)| — | A Phoenix LiveView route explicitly surfaces server-rejected offline actions (e.g., card was deleted remotely). |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Ecto` | Current | Data modeling and transaction management | `Ecto.Multi` allows safe batched inserts of `review_events` and derivation of progress. |
| `Phoenix.LiveView`| Current | Replay history and conflict resolution UI | Idiomatic real-time views for exposing explicit offline outbox rejections to the user. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Jason` | Current | JSON Parsing | Serializing and deserializing outbox sync payloads containing the review events. |

## Architecture Patterns

### System Architecture Diagram

```
[Native Shell Offline]                           [Phoenix Server Online]
      │                                                     │
      │ 1. Start session (loads daily_study pack)           │
      ▼                                                     │
[Study Island UI]                                           │
      │                                                     │
      │ 2. User reviews card (Good/Hard)                    │
      ▼                                                     │
[Local Outbox (Append-Only Journal)]                        │
      │                                                     │
      │ 3. Shell regains connectivity                       │
      │ 4. Push sync payload (array of events)              │
      ├────────────────────────────────────────────────────►│
      │                                                     ▼
      │                                         [Reconciliation Endpoint]
      │                                                     │
      │                                                     │ 5. Validate base checkpoint
      │                                                     │ 6. Ecto.Multi inserts events
      │                                                     │ 7. Derive new card_progress
      │                                                     ▼
      │ 8. Return explicit outcome (accepted/rejected)  [Database (Canonical)]
      ◄─────────────────────────────────────────────────────┤
      │                                                     │
      ▼                                                     │
[History UI (LiveView)]                                     │
      (Displays rejections e.g., "Card Deleted Remote")     │
```

### Recommended Project Structure
```
lib/crosswake_example/
└── local_first/
    ├── study.ex                  # Context managing Ecto operations and sync logic
    ├── review_event.ex           # Ecto schema for append-only study events
    ├── study_session_live.ex     # LiveView for the island posture (offline: :island)
    └── study_history_live.ex     # LiveView for conflict/history (offline: :cached)
lib/crosswake_example_web/
└── controllers/
    └── sync_controller.ex        # API endpoint for receiving the client outbox journal
```

### Pattern 1: Append-Only Event Journal
**What:** Instead of trying to sync final state (like `card.due_at`), the client stores raw semantic events (e.g., `card_id=123, rating=good, elapsed_ms=1500`).
**When to use:** Whenever offline mutations can happen concurrently on multiple devices, avoiding silent Last-Write-Wins (LWW) data loss.
**Example:**
```elixir
# Sync Controller Payload Format
%{
  "events" => [
    %{"client_mutation_id" => "evt_1", "card_id" => 42, "rating" => "good", "timestamp" => "2026-05-18T10:00:00Z"},
    %{"client_mutation_id" => "evt_2", "card_id" => 45, "rating" => "hard", "timestamp" => "2026-05-18T10:05:00Z"}
  ],
  "base_checkpoint" => "chk_abc123"
}
```

### Anti-Patterns to Avoid
- **Last-Write-Wins (LWW) Mutations:** Mutating the `card_progress` row on the device and syncing the final state. This silently destroys data if the user studied on their phone and iPad while offline.
- **Silent Conflict Resolution:** Swallowing errors on the server if a review event fails. Crosswake philosophy requires an explicit failure status presented to the user.
- **Complex CRDTs:** Do not introduce CRDT libraries for simple study flows; an Ecto.Multi event-append model is sufficient and standard.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Multi-master sync engine | Background CRDT sync layer | explicit `Ecto.Multi` | CRDTs are out of scope. Crosswake requires explicit, point-in-time synchronization outcomes. |
| Client-side conflict UI inside Native | Native Swift/Kotlin UI | LiveView `study_history` | Crosswake pushes conflict resolution to Phoenix so the server remains authoritative and development remains Elixir-centric. |

**Key insight:** Ecto is already perfect at batch inserts and transaction isolation. Push the complexity into standard Elixir contexts.

## Common Pitfalls

### Pitfall 1: Missing Idempotency Keys
**What goes wrong:** A network timeout occurs during sync. The device retries, and the server inserts duplicate review events, artificially advancing the user's progress.
**Why it happens:** The sync endpoint lacks unique constraint checking.
**How to avoid:** Every `review_event` must have a client-generated `client_mutation_id`. The server schema should have a unique index on this column.

### Pitfall 2: Opaque Sync Failures
**What goes wrong:** An event fails because the lesson was deleted on the server, but the user is never told.
**Why it happens:** The sync controller drops the failure silently to keep the happy path working.
**How to avoid:** The sync endpoint must return an explicit `rejected` reason for that specific event, and the local history UI must surface it.

## Code Examples

Verified patterns from official sources:

### Ecto Multi Sync Reconciliation
```elixir
def sync_events(events) do
  Ecto.Multi.new()
  |> Ecto.Multi.insert_all(:insert_events, CrosswakeExample.LocalFirst.ReviewEvent, events, 
       on_conflict: :nothing, conflict_target: :client_mutation_id)
  |> Ecto.Multi.run(:update_progress, fn repo, %{insert_events: _} -> 
       # Recompute user progress based on inserted events
       {:ok, :computed}
     end)
  |> CrosswakeExample.Repo.transaction()
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Last-Write-Wins Sync | Append-Only Event Sourcing | Standardized in Phase 4 | Offline actions from multiple devices no longer silently overwrite each other. |
| Magic background sync | Explicit Sync Routes | Standardized in Phase 4 | Developers own the reconciliation logic instead of relying on a black-box sync library. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The sync controller payload should be processed synchronously. | Architecture Patterns | If payloads are large, a background job (Oban) might be needed, but for an exemplar, sync is preferred. |
| A2 | `client_mutation_id` uniqueness is sufficient for idempotency. | Pitfalls | If devices generate colliding UUIDs (rare), events could be incorrectly dropped. |

## Open Questions (RESOLVED)

1. **Conflict Resolution Granularity**
   - What we know: If a card is deleted remotely, the review event is rejected.
   - What's unclear: Should the entire sync batch fail, or just that specific event?
   - Resolution: Use event-level granularity. The sync controller will return a mixed response (some accepted, some rejected) so valid study progress isn't blocked by one deleted card.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Standard Phoenix session/token boundary on the sync route |
| V3 Session Management | yes | Existing Crosswake bridge auth |
| V4 Access Control | yes | Enforce user_id scope in the sync controller (users cannot sync events for others) |
| V5 Input Validation | yes | Ecto changesets validate timestamp formats and enums (e.g., rating = 'good'/'hard') |
| V6 Cryptography | no | N/A |

### Known Threat Patterns for Elixir/Phoenix

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Insecure Direct Object Reference (IDOR) | Elevation of Privilege | Ensure the sync controller strictly filters events by the authenticated user's ID before inserting. |
| Replay Attacks | Tampering | Use `client_mutation_id` uniqueness to discard duplicate submissions. |

## Sources

### Primary (HIGH confidence)
- `guides/offline.md` - Verified offline contract limitations, confirming append-only journal durability and explicit replay.
- `.planning/phases/09-local-first-content-flow-exemplar/09-PATTERNS.md` - Verified file architectures and analogies for the `LocalFirst` namespace.
- `.planning/phases/09-local-first-content-flow-exemplar/09-CONTEXT.md` - Verified strict bounds for the local-first implementation (avoiding CRDTs).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Directly follows Phoenix/Ecto idiomatic event sourcing capabilities.
- Architecture: HIGH - Adheres to Crosswake's fail-closed, explicit reconciliation posture defined in Phase 4.
- Pitfalls: HIGH - Addresses standard distributed system synchronization risks in the context of Elixir.

**Research date:** 2026-05-18
**Valid until:** 2027-05-18
