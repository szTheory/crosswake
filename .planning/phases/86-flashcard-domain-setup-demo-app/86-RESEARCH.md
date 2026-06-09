<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Selected Language Learning / Flashcard app as the adoption evidence domain to rigorously stress-test the `Crosswake.Offline` island philosophy.

### the agent's Discretion
- (None explicitly listed in STATE.md)

### Deferred Ideas (OUT OF SCOPE)
- Full "write-once-run-anywhere" cross-platform UI.
- Native rendering of LiveView components.
- Expanding auth beyond the current scope needed for the demo app.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DEMO-01 | A Language Learning / Flashcard app is implemented as the exemplar for the "Offline Island" philosophy. | Ecto schemas, Phoenix context, and seeds provide the necessary backend structure for the demo app. |
</phase_requirements>

# Phase 86: Flashcard Domain Setup (Demo App) - Research

**Researched:** 2026-06-08
**Domain:** Phoenix Context, Ecto Schemas, Demo Seeding
**Confidence:** HIGH

## Summary

The objective of Phase 86 is to scaffold the backend domain for the Adoption Evidence Demo App (Flashcards). This involves setting up the primary Ecto schemas (`Deck`, `Card`, `Progress`), wrapping them in a standard Phoenix Context (`CrosswakeExample.Flashcards`), and generating a robust set of seeds for the demonstration cohort.

**Primary recommendation:** Build a dedicated `CrosswakeExample.Flashcards` context inside the existing `examples/phoenix_host` application, utilizing `binary_id` for primary keys to elegantly handle offline creation and synchronization via the Sync EventLog without key collision.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Domain Models | API / Backend | Database | `Deck`, `Card`, and `Progress` definitions belong in the Phoenix API, backed by Ecto Schemas for database storage. |
| Business Logic | API / Backend | — | The `Flashcards` context handles querying decks and generating the offline manifest payload. |
| Database Schema | Database | — | Ecto migrations manage the SQLite database schema and constraints. |
| Initial State | Database | API / Backend | Seeding requires inserting records into SQLite via Ecto repositories to ensure a consistent demo state. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Ecto | ~> 3.10 | Database querying and mapping | Standard Elixir data layer, pre-configured in `crosswake_example`. |
| Ecto.Schema | ~> 3.10 | Defining schema structs | Maps Elixir structs to database tables natively. |
| Ecto.Changeset | ~> 3.10 | Validating data | Built-in validation and casting. |

**Version verification:** 
The host application `examples/phoenix_host/mix.exs` currently specifies `ecto_sql ~> 3.10` and `ecto_sqlite3 ~> 0.16`.

## Package Legitimacy Audit

> **Required** whenever this phase installs external packages. 

*No new packages are installed in this phase. Existing dependencies within `examples/phoenix_host/mix.exs` are used.*

## Architecture Patterns

### Recommended Project Structure
```text
examples/phoenix_host/
├── priv/repo/migrations/
│   ├── [timestamp]_create_flashcard_decks.exs
│   ├── [timestamp]_create_flashcard_cards.exs
│   └── [timestamp]_create_flashcard_progress.exs
├── priv/repo/
│   └── seeds.exs
└── lib/crosswake_example/
    ├── flashcards.ex          # Context boundary
    └── flashcards/
        ├── deck.ex            # Ecto schema
        ├── card.ex            # Ecto schema
        └── progress.ex        # Ecto schema
```

### Pattern 1: Binary IDs (UUIDs) for Offline Sync
**What:** Using `binary_id` (UUIDs) instead of `integer` primary keys.
**When to use:** Crucial for models that may be created or referenced heavily in an offline/local-first environment. 
**Example:**
```elixir
defmodule CrosswakeExample.Flashcards.Card do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "flashcard_cards" do
    field :front_text, :string
    field :back_text, :string
    belongs_to :deck, CrosswakeExample.Flashcards.Deck

    timestamps()
  end
end
```

### Anti-Patterns to Avoid
- **Integer IDs:** Avoid auto-incrementing integers for `Card` or `Progress` models if they ever need to be created offline, as this leads to ID collision during synchronization.
- **Leaking Repo:** Do not call `CrosswakeExample.Repo` directly from LiveViews or Controllers; always route through the `CrosswakeExample.Flashcards` context boundary.
- **Overcomplicated Spaced Repetition (SRS):** For the demo app, keep `Progress` simple (e.g., `ease`, `interval`, `next_review_at`). Avoid implementing full SuperMemo-2 in the DB unless strictly required for the demo, as the actual calculation usually happens in the offline JS island anyway.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| UUID Generation | Hand-rolled random strings | `Ecto.UUID` (`:binary_id`) | Ecto natively supports autogenerating UUIDv4 strings. |

## Runtime State Inventory

*Step 2.5: SKIPPED (Greenfield domain creation, no rename/refactor)*

## Common Pitfalls

### Pitfall 1: Missing Foreign Key Indexes
**What goes wrong:** Database queries to find all cards for a deck become slow.
**Why it happens:** Ecto does not automatically generate indexes for `belongs_to` relationships in migrations.
**How to avoid:** Explicitly add `create index(:flashcard_cards, [:deck_id])` in the migration.

### Pitfall 2: Complex Auth for Demo Users
**What goes wrong:** Wasting time setting up a user authentication system.
**Why it happens:** Assuming `Progress` needs a strictly relational `User` table.
**How to avoid:** Hardcode a standard `user_id` string (e.g., "demo_user_1") or just use a generic `account_id` string on the `Progress` model, keeping it within scope ("Expanding auth beyond the current scope needed for the demo app" is Deferred).

## Code Examples

### Seeding Data Elegantly
```elixir
# priv/repo/seeds.exs
alias CrosswakeExample.Repo
alias CrosswakeExample.Flashcards.{Deck, Card}

deck = Repo.insert!(%Deck{title: "Elixir Basics", description: "Core concepts of Elixir"})

Repo.insert!(%Card{deck_id: deck.id, front_text: "What is OTP?", back_text: "Open Telecom Platform"})
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Integer PKs  | `binary_id` (UUID) | v6.0 Offline Island | Enables distributed creation of entities while offline without key conflicts upon sync. |

## Assumptions Log

*No `[ASSUMED]` claims in this research. All items verified from `crosswake_example` host and standard Phoenix/Ecto documentation.*

## Open Questions (RESOLVED)

1. **Seeding Mechanism**
   - What we know: Seeds need to be robust.
   - What's unclear: Should seeds be auto-run via `mix ecto.setup` alias, or just kept in a `Seeds` module?
   - Recommendation: Create `priv/repo/seeds.exs` as it is the standard mechanism in Phoenix for bootstrapping database state.
   - RESOLVED: Create `priv/repo/seeds.exs`.

## Environment Availability

Step 2.6: SKIPPED (No external dependencies beyond Elixir/Mix which are available).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `examples/phoenix_host/test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DEMO-01 | Context exposes functions to fetch Decks and Cards | unit | `mix test test/crosswake_example/flashcards_test.exs` | ❌ Wave 0 |
| DEMO-01 | Context can update Progress for a Card | unit | `mix test test/crosswake_example/flashcards_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `examples/phoenix_host/test/crosswake_example/flashcards_test.exs`
- [ ] `examples/phoenix_host/test/support/flashcards_fixtures.ex`

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | (Out of scope for Demo App) |
| V3 Session Management | no | (Out of scope for Demo App) |
| V4 Access Control | no | (Out of scope for Demo App) |
| V5 Input Validation | yes | Ecto.Changeset |

### Known Threat Patterns for Elixir / Ecto

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Over-posting in forms | Tampering | Explicit `cast/3` allow-lists in `Ecto.Changeset`. |

## Sources

### Primary (HIGH confidence)
- `examples/phoenix_host/mix.exs` - Host application configuration and Ecto presence.
- `.planning/REQUIREMENTS.md` - Confirmed DEMO-01 requirement for the Flashcard Domain context.
- `.planning/STATE.md` - Confirmed Deferred Auth requirement.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Ecto and Phoenix Contexts are fundamental Elixir patterns.
- Architecture: HIGH - Follows explicit Crosswake examples host conventions.
- Pitfalls: HIGH - Known Ecto and project-specific scope traps.

**Research date:** 2026-06-08 (Derived from state baseline)
**Valid until:** Next major Ecto/Phoenix upgrade.
