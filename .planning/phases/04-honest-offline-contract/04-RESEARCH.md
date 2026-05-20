# Phase 4: Honest Offline Contract - Research

**Researched:** 2026-05-16
**Domain:** Explicit cached-read and local-first offline contracts for one honest Crosswake route class
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Reference workflow and proof shape
- **D-01:** Use a study/session review loop as the single named offline-island exemplar.
- **D-02:** Pair that exemplar with a neighboring LiveView-backed cached read-only lesson or library route so Crosswake proves the difference between degraded reads and true local-first mutation.
- **D-03:** Do not expand into inspection forms, task queues, media upload flows, or broad capability-heavy field workflows in Phase 4.
- **D-04:** Keep the exemplar focused on semantic review/session actions with low bridge chatter, not capability-heavy native behavior.

### Public offline contract shape
- **D-05:** Keep `runtime` as the ownership axis and keep `offline` as the coarse public summary class.
- **D-06:** Do not leave `offline: :local_first` as a docs-only promise; add explicit typed subcontracts for cached routes and offline islands.
- **D-07:** Cached read-only routes and mutating offline islands must not share one indistinct contract surface.
- **D-08:** Keep the route DSL small and Phoenix-native: additive top-level route options with richer behavior referenced through named contracts.
- **D-09:** Exact field names are flexible, but the direction is locked: additive typed cache and island contracts, not inferred behavior from `sync`, `packs`, or rule ordering.

### Mutation, journal, and reconciliation
- **D-10:** Use a hybrid local-first model: local draft state for in-progress UI plus an append-only mutation journal or outbox for committed offline actions.
- **D-11:** Phoenix and Ecto stay server-authoritative; offline islands project optimistic local state but reconcile explicitly.
- **D-12:** Committed offline actions need immutable journal entries with client mutation id, idempotency key, sync seam, resource identity, operation, payload, base checkpoint/version, timestamps, and status.
- **D-13:** Replay must return explicit accepted, rejected, or conflict outcomes plus updated authoritative state or checkpoint data.
- **D-14:** Do not mutate canonical rows locally.
- **D-15:** Prove one narrow replay and reconciliation seam, not a generic sync framework.

### Local storage and failure visibility
- **D-16:** Design durability around SQLite-backed native stores on iOS and Android, not browser storage.
- **D-17:** Keep background replay claims honest: persistence, retry hooks, and eventual replay are in scope; guaranteed sync timing is not.
- **D-18:** Phase 4 may define seams future pack work can reuse, but must not require full pack lifecycle breadth now.
- **D-19:** Ship a minimum slice of route-local user truth plus structured developer or operator diagnostics.
- **D-20:** User-facing states must distinguish cached read-only or stale, saved locally, queued for replay, replay failure, and conflict-required resolution.
- **D-21:** Conflicts and data-loss-risk states may interrupt; stale reads and queued replay should usually stay inline.
- **D-22:** Extend `mix crosswake.doctor` and JSON output with offline checks and machine-readable findings rather than adding a mounted diagnostics UI.
- **D-23:** Operator support should come from structured telemetry/logs keyed by route id, runtime, offline mode, sync seam, journal entry id, manifest/runtime versions, correlation id, and terminal outcome.
- **D-24:** Telemetry should emphasize state transitions and terminal outcomes over noisy low-level events.

### Product honesty and scope guardrails
- **D-25:** Product language must explicitly distinguish cached read-only degradation from true local-first mutation.
- **D-26:** The bridge must not become a high-frequency state bus for the offline island.
- **D-27:** Phase 4 support claims stay narrow: one honest local-first workflow with explicit replay and reconciliation.
- **D-28:** Mounted diagnostics UI, inspection/media-heavy offline workflows, broad taxonomies, and generic sync-framework APIs remain deferred.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OFFL-01 | LiveView-backed route can run as cached read-only with explicit staleness policy and cache restrictions. | Add a typed cache contract referenced from route policy and manifest entries instead of overloading the existing `offline` enum. |
| OFFL-02 | One offline island can complete its intended workflow without LiveView round-trips while offline. | Model a single study-session island with local read truth, local draft projection, and semantic action queueing. |
| OFFL-03 | Offline mutations persist as local drafts or journal/outbox entries and expose explicit reconciliation hooks. | Add immutable journal-entry and replay-outcome contracts keyed by sync seam and server checkpoint/idempotency fields. |
| OFFL-04 | Developers and operators can inspect telemetry or diagnostics for offline replay, sync, and reconciliation failures. | Extend doctor and JSON output with offline posture plus route-level transition/outcome telemetry vocabulary. |
</phase_requirements>

## Recommended Architecture

Phase 4 should stay contract-first and route-first, exactly like earlier phases. The smallest credible shape is:

1. Extend route policy and manifest truth with explicit named `cache_contract` and `offline_island_contract` references.
2. Add typed offline contract modules in Elixir that define cache policy, island metadata, journal entries, replay requests, replay outcomes, and route-local status vocabulary.
3. Use one named exemplar only: a study/session island paired with a cached lesson/library route.
4. Extend doctor, JSON formatter, and guides from that same contract truth so support claims are generated from the implementation surface rather than written separately.

The repo’s current implementation posture supports this well. `Crosswake.Policy.Schema`, `Crosswake.Policy.Route`, `Crosswake.Manifest.Types`, and `Crosswake.Manifest.Builder` already centralize route-local truth. `Crosswake.Doctor` and its formatters already render product-level support posture from typed contracts. Phase 4 should preserve those patterns rather than creating a parallel offline subsystem config file or a native-only source of truth.

## Recommended Plan Decomposition

### Plan 04-01: Explicit Offline Route Contracts
Create the public contract surface for cached routes and offline islands.

- Extend route policy with additive contract references instead of a larger `offline` enum.
- Extend manifest route entries with typed cache and island contract payloads.
- Preserve current route-local, fail-closed validation style.

### Plan 04-02: Journal, Replay, and Reconciliation Contract
Make the study/session exemplar real enough to support honest local-first mutation claims.

- Add immutable journal-entry and replay request/outcome types.
- Add route-level island contract truth for local draft projection and replay seams.
- Keep Phoenix/Ecto authoritative and encode explicit accept/reject/conflict outcomes.

### Plan 04-03: Offline State Truth, Telemetry, and Doctor
Turn the contract into inspectable product surface.

- Define stable route-local offline states and transition vocabulary.
- Extend `mix crosswake.doctor` and JSON output with offline checks and findings.
- Add machine-readable operator-facing fields keyed to route id, sync seam, journal id, manifest version, and terminal outcome.

### Plan 04-04: Proof and Adopter Guidance
Lock the support posture down to what the code proves.

- Publish one public offline guide that explains cached read-only versus offline island behavior using the study/session exemplar.
- Extend compatibility or support docs and tests so support claims stay narrow and honest.
- Add proof fixtures or verification checks that assert the exemplar contract and support vocabulary.

## Reusable Repo Anchors

| Surface | Why It Matters |
|---------|----------------|
| `lib/crosswake/policy/schema.ex` | Existing typed DSL surface for additive route options. |
| `lib/crosswake/policy/route.ex` | Normalized route struct that should grow contract references cleanly. |
| `lib/crosswake/manifest/types.ex` | Canonical typed manifest boundary for new offline subcontracts and replay types. |
| `lib/crosswake/manifest/builder.ex` | Existing route-entry assembly point where policy truth becomes manifest truth. |
| `lib/crosswake/doctor/doctor.ex` | Existing product-level diagnostic entrypoint suitable for offline posture checks. |
| `lib/crosswake/doctor/check.ex` | Stable structured-finding model for new offline diagnostics. |
| `lib/crosswake/doctor/formatter.ex` | Human-readable offline posture surface. |
| `lib/crosswake/doctor/json_formatter.ex` | Machine-readable offline posture surface. |
| `test/support/router_fixtures.ex` | Current managed-route examples already exercise `:cached_read_only` and `:offline_island` hints. |
| `lib/crosswake/bridge/contract.ex` | Good typed-envelope reference for replay request/reply shape without introducing a generic bus. |
| `lib/crosswake/shell/activation.ex` | Good route-first decision pattern showing request -> typed decision -> `to_map/1`. |

## Patterns To Follow

### Pattern 1: Additive Contract References, Not Enum Inflation
Keep `offline` as the coarse summary and add explicit typed contract fields for the real mechanics.

Example direction:

```elixir
crosswake: [
  id: "study_session",
  runtime: :offline_island,
  offline: :local_first,
  cache_contract: nil,
  island_contract: "study.session.v1"
]
```

### Pattern 2: Immutable Journal Entries With Explicit Replay Outcomes
Committed local actions should append journal entries, not mutate authoritative rows directly.

```elixir
%JournalEntry{
  id: "01J...",
  route_id: "study_session",
  sync_seam: "study_reviews",
  operation: :grade_card,
  client_mutation_id: "01J...",
  idempotency_key: "study_session:01J...",
  base_checkpoint: "lesson-42:v7",
  status: :queued
}
```

Replay should resolve to typed outcomes such as `:accepted`, `:rejected`, or `:conflict`.

### Pattern 3: Route-Local Offline Vocabulary
Offline status must stay specific to the route and workflow:

- `cached_read_only`
- `stale`
- `saved_locally`
- `queued_for_replay`
- `replay_failed`
- `conflict_requires_attention`

These states should exist in one typed contract used by doctor output, JSON output, and docs.

### Pattern 4: Doctor and Docs Read From Contract Truth
Do not hand-maintain support language separately. Render offline posture from typed route, manifest, and exemplar contract data.

## Anti-Patterns To Reject

| Instead of | Reject Because | Use |
|------------|----------------|-----|
| Reusing only `offline: :cached_read_only | :local_first` | Too coarse to support honest claims or diagnostics | Add explicit typed cache and island contract fields |
| Direct local mutation of canonical server rows | Hides conflict/pending truth and weakens replay auditability | Append-only journal plus local draft projection |
| Generic sync-framework abstractions | Pulls Phase 4 beyond one narrow exemplar | One study/session replay seam only |
| App-wide offline banner as the primary UX | Hides route ownership and state specificity | Route-local offline state vocabulary |
| Mounted diagnostics dashboard in Phase 4 | Adds product surface before the core event contract is stable | Extend doctor + JSON output |

## Likely File-Level Shape

The most likely implementation shape is:

```text
lib/crosswake/policy/schema.ex
lib/crosswake/policy/route.ex
lib/crosswake/manifest/types.ex
lib/crosswake/manifest/builder.ex
lib/crosswake/offline/contracts.ex
lib/crosswake/offline/journal.ex
lib/crosswake/offline/replay.ex
lib/crosswake/offline/status.ex
lib/crosswake/doctor/doctor.ex
lib/crosswake/doctor/formatter.ex
lib/crosswake/doctor/json_formatter.ex
guides/offline.md
test/crosswake/policy/*
test/crosswake/manifest/*
test/crosswake/doctor/*
test/crosswake/offline/*
test/mix/tasks/crosswake_doctor_test.exs
```

Exact module splits are implementation discretion, but the contract should remain route-first, typed, and additive.

## Confidence Notes

- Confidence is **HIGH** that the right Phase 4 move is to extend existing route and manifest truth rather than create a separate offline config system.
- Confidence is **HIGH** that the exemplar should be narrowed to one study/session island plus one cached neighboring route.
- Confidence is **HIGH** that doctor and support truth should remain the main operator/developer surface for this phase.
- Confidence is **MEDIUM-HIGH** on exact module boundaries for the new offline contract types; the repo has not introduced an `offline/` namespace yet, but the typed-struct pattern is already stable elsewhere.

## Sources

- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/phases/04-honest-offline-contract/04-CONTEXT.md`
- `.planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md`
- `.planning/phases/03-native-shell-boot-and-bounded-bridge/03-RESEARCH.md`
- `.planning/research/SUMMARY.md`
- `.planning/research/ARCHITECTURE.md`
- `.planning/research/STACK.md`
- `.planning/research/FEATURES.md`
- `.planning/research/PITFALLS.md`
- `lib/crosswake/policy/schema.ex`
- `lib/crosswake/policy/route.ex`
- `lib/crosswake/manifest/types.ex`
- `lib/crosswake/manifest/builder.ex`
- `lib/crosswake/doctor/doctor.ex`
- `lib/crosswake/doctor/check.ex`
- `lib/crosswake/doctor/formatter.ex`
- `lib/crosswake/doctor/json_formatter.ex`
- `test/support/router_fixtures.ex`

## RESEARCH COMPLETE

Phase 4 should be planned as four narrow slices: explicit offline route contracts, journal/replay/reconciliation for one study-session island, offline state/telemetry/doctor posture, and proof/docs/support truth.
