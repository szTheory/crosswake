# Phase 34: MockStorefront And Idempotency Invariants - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement `CrosswakeExample.Commerce.MockStorefront` as a pure-Elixir, provider-neutral
evidence emitter — `simulate_purchase/1` consumes a `PurchaseIntent` and `simulate_restore/1`
consumes a `RestoreIntent`, each returning a `Crosswake.Commerce.Contracts.ReconciliationEvidence`
with `source: :storefront, provider: "mock"`. Prove its idempotency invariant against the
existing Phase 21 `ReconciliationInbox`/`ReconciliationKeys` (replay keyed on stable provider
identity, not `correlation_id`) and fence the source against forbidden provider tokens.

**In scope:** the `MockStorefront` module, its evidence-construction logic, the `@moduledoc`
swap-target documentation, the replay/idempotency invariant test, and the provider-vocabulary
fence test. **Requirements:** MOCK-01, MOCK-02, MOCK-03, WIRE-03.

**Out of scope:** reconciliation/LiveView wiring and `project_snapshot/2` plumbing (Phase 35),
the merge-blocking hermetic full-lane proof (Phase 36), the guides walkthrough (Phase 37).
No StoreKit / Play Billing / RevenueCat / any provider-SDK code (`provider: "mock"` only);
no persistent storage (in-memory/pure only); single subscription product (no multi-product).

</domain>

<decisions>
## Implementation Decisions

These four decisions all hang off one principle: **the mock's only real job is to manufacture
*stable provider identity* from intents that don't carry it.** `PurchaseIntent` is `{entry_id,
correlation_id}` and `RestoreIntent` is `{correlation_id}` only, but `ReconciliationEvidence`
requires `provider_reference` + `evidence_ref`. Since `ReconciliationKeys.event_key/1` is
`event::provider::provider_reference::event_kind::evidence_ref` and deliberately **excludes
`correlation_id`**, the replay invariant (Success Criterion #4 / WIRE-03) holds if and only if
the mock derives those fields from stable identity and never from `correlation_id`.

### A. Provider identity derivation (MOCK-01, WIRE-03)
- **D-01:** `provider_reference` is a deterministic function of `PurchaseIntent.entry_id`
  (e.g. `"mock_txn_" <> entry_id`). This models a real storefront transaction id: a
  network-retried submission of *the same purchase* carries the same transaction id even with
  a fresh `correlation_id`, so it dedupes.
- **D-02:** `evidence_ref` is deterministic from the same stable identity + `event_kind`
  (e.g. `"mock_evt_" <> entry_id <> "_purchase"`). It must NOT be random per-call, or
  `event_key` would differ between retries and replay detection would never fire.
- **D-03:** `correlation_id` is **never** part of identity. It is passed through to
  `ReconciliationInbox.ingest_evidence/2` via `opts[:correlation_id]`, where it lands in
  `trace_metadata` only (per `ReconciliationKeys.trace_metadata/2`). This is the explicit
  teaching contrast the replay test demonstrates.
- **D-04:** Evidence shape is fixed: `source: :storefront`, `provider: "mock"`,
  `event_kind: "purchase"` for purchases. Two purchases of the same `entry_id` with different
  `correlation_id` → identical `event_key` → `replay?: true` (the invariant); two different
  `entry_id` → different keys → not a replay.

### B. Restore identity semantics (MOCK-02)
- **D-05:** `MockStorefront` owns a **single canonical subscription product** identity as a
  module constant (e.g. `@subscription_entry_id "sub_pro_monthly"`), consistent with the
  single-subscription scope (AF-04). Both `simulate_purchase` (for that entry) and
  `simulate_restore` anchor `provider_reference` on this constant.
- **D-06:** `simulate_restore/1` resolves to that canonical product's stable `provider_reference`
  (NOT to `RestoreIntent.correlation_id`, which it has no other field), so restore evidence
  shares the same `subject_key` as the prior purchase — honestly modeling "restore re-grants
  the previously-purchased subscription." `event_kind: "restore"`, `source: :storefront`,
  `provider: "mock"`.
- **D-07:** Restore product selection is a **fixed module constant**, not a configurable opt
  (user decision). No `entry_id` arg threaded through restore — keeps the proof and the
  Phase 35 LiveView call sites simple, matches single-product scope.

### C. Determinism / clock seam (Phase 36 hermeticity)
- **D-08:** Identity refs are pure-deterministic (derived from `entry_id`), so the *only*
  nondeterminism is the `captured_at` timestamp. Both functions take an optional keyword
  (`simulate_purchase(intent, opts \\ [])`) where `captured_at` defaults to
  `DateTime.utc_now() |> DateTime.to_iso8601()` but can be injected.
- **D-09:** The Phase 36 hermetic proof injects a fixed `captured_at`. No RNG/seed or clock
  *behaviour* abstraction — that would over-engineer example code. Optional keyword + pure
  refs is sufficient for full determinism.

### D. Function / return shape + swap documentation (MOCK-03)
- **D-10:** Both functions return the **raw `%ReconciliationEvidence{}` struct directly** — no
  `{:ok, _}` wrapper. Matches Success Criteria #1/#2 wording ("return `ReconciliationEvidence{...}`")
  and the fact that a pure mock cannot fail.
- **D-11:** The `@moduledoc` explicitly names `simulate_purchase/1` and `simulate_restore/1` as
  the two functions a real StoreKit / Play Billing adapter would replace (Success Criterion #3 /
  MOCK-03) — making the drop-in swap target obvious.

### Claude's Discretion
- Exact string forms of `provider_reference` / `evidence_ref` prefixes, the concrete
  `@subscription_entry_id` value, and the precise `@moduledoc` swap-target wording.
- Whether identity derivation uses simple string concatenation vs a small private helper.
- Exact structure of the replay invariant test and the provider-vocabulary fence test
  (the fence reads `MockStorefront` source and asserts absence of `storekit`, `play_billing`,
  `play billing`, `revenuecat` — case-insensitive — per Success Criterion #5).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone / Requirements
- `.planning/REQUIREMENTS.md` — v3.4 requirements (MOCK-01/02/03, WIRE-03 for this phase) +
  Out of Scope table (AF-01..AF-08 anti-features; note AF-01 provider-SDK ban, AF-02 no
  persistence, AF-04 single subscription, AF-07 `provider: "mock"` only).
- `.planning/ROADMAP.md` §"Phase 34: MockStorefront And Idempotency Invariants" — goal + 5
  success criteria (criterion #4 = replay invariant, #5 = vocabulary fence).
- `.planning/threads/commerce-archetype-proof.md` — milestone thread / strategic intent.
- `.planning/research/SUMMARY.md` — reuse-don't-rebuild module inventory.
- `.planning/phases/33-corridor-routes-and-ci-infrastructure/33-CONTEXT.md` — prior phase
  decisions (corridor routes, `phase34-proof.yml` CI split this phase's tests run under).

### Commerce Contracts (reuse, do not modify — these are SHIPPED lib code in `crosswake 0.1.0`)
- `lib/crosswake/commerce/contracts.ex` §19-38 — `PurchaseIntent` (`{entry_id, correlation_id}`)
  and `RestoreIntent` (`{correlation_id}`); §150-183 — `ReconciliationEvidence` enforced keys
  (`source, provider, provider_reference, event_kind, evidence_ref, captured_at`) + optional
  (`integrity_digest, idempotency_ref`); `source` vocabulary `[:device, :storefront, :webhook, :support]`.
- `lib/crosswake/commerce/reconciliation.ex` — `authority_mutation_allowed_from_evidence?/1` → `false`
  (the mock-boundary fence anchor, asserted in Phase 36; referenced here for the swap-doc framing).

### Phase 21 Example-Host Modules (reuse — the invariant is proven *against* these)
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex` — `event_key/1`
  = `event::provider::provider_reference::event_kind::evidence_ref` (correlation_id EXCLUDED);
  `subject_key/2`; `trace_metadata/2` (where `correlation_id` lands). This file defines exactly
  why D-01..D-03 make the invariant hold.
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex` —
  `ingest_evidence/2`: replay detected via `opts[:seen_event_keys]` membership of `event_key`;
  `event_kind: "purchase" | "restore"` are success-like → `status: :awaiting_verification`;
  `opts[:correlation_id]` flows to trace metadata. The replay test drives this directly.
- `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex` —
  `project_snapshot/2` / `derived_state/1` (NOT wired here — Phase 35 — but listed so the
  planner sees the downstream consumer of this phase's evidence).

### Test Patterns (mirror)
- `test/crosswake/proof/phase21_reconciliation_example_test.exs` — existing evidence-construction
  + replay/key test patterns (`sample_evidence`, `provider_reference: "tx_..."`); the Phase 34
  invariant test follows the same hermetic, `Code.require_file`-at-module-scope idiom.
- `test/crosswake/commerce/reconciliation_test.exs` §131-139 — evidence struct fixture helper shape.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Commerce.Contracts.{PurchaseIntent, RestoreIntent, ReconciliationEvidence}` — shipped
  lib structs the mock consumes/produces. Zero new contract types needed.
- `CrosswakeExample.Commerce.ReconciliationKeys.event_key/1` + `ReconciliationInbox.ingest_evidence/2`
  — the idempotency machinery already exists; Phase 34 only feeds it mock-built evidence and
  asserts replay. No changes to these modules.
- `examples/phoenix_host/.../commerce/` is the established home for example commerce modules —
  `MockStorefront` lands alongside `reconciliation_inbox.ex` / `reconciliation_keys.ex`.

### Established Patterns
- Evidence construction in tests uses `struct!(Contracts.ReconciliationEvidence, ...)` with a
  `sample_evidence`/overrides helper (phase21 test) — mirror for the invariant test fixtures.
- Hermetic example-host tests reach example modules via `Code.require_file` at module scope and
  stay UNtagged so they run in the `phase34-proof.yml` merge-blocking lane (locked in Phase 33
  D-08); server/integration-backed tests get `@tag :requires_example_host`. The Phase 34 invariant
  test is hermetic (pure function calls + ingest) → untagged → merge-blocking.
- `provider:` is a plain `String.t()` ("mock"); `source:` is the atom `:storefront`. The mock
  emits the canonical atom source, not a provider-specific token.

### Integration Points
- `MockStorefront.simulate_purchase/1` output → `ReconciliationInbox.ingest_evidence/2` →
  (`replay?`, `status`, `event_key`, `subject_key`). This is the seam the invariant test exercises
  and that Phase 35 wires into the LiveView `handle_event` path.
- Tests run under the `phase34-proof.yml` hermetic job established in Phase 33.

</code_context>

<specifics>
## Specific Ideas

- Identity model in one line: `provider_reference := f(entry_id)`, `evidence_ref := g(entry_id,
  event_kind)`, `correlation_id := trace-only`. Same `entry_id` (or canonical restore product)
  + different `correlation_id` ⇒ same `event_key` ⇒ `replay?: true`.
- Replay test shape: build evidence from `simulate_purchase(%PurchaseIntent{entry_id: X,
  correlation_id: "c1"})`, capture `event_key`, then `simulate_purchase(%PurchaseIntent{entry_id:
  X, correlation_id: "c2"})` and `ingest_evidence(evidence2, seen_event_keys: [event_key1])` →
  assert `replay?: true`. Proves keying on stable provider identity, not transient device IDs.
- Single canonical subscription: a `@subscription_entry_id` module constant is the identity both
  purchase (of that entry) and restore anchor on.

</specifics>

<deferred>
## Deferred Ideas

- **Reconciliation/LiveView wiring + `project_snapshot/2`** — Phase 35 (WIRE-01, WIRE-02, STATE-01).
- **Merge-blocking hermetic full-lane proof + mock-boundary fence on
  `authority_mutation_allowed_from_evidence?/1`** — Phase 36 (PROOF-01, PROOF-03). Phase 34 proves
  only the *idempotency* invariant, not the full state lane.
- **`guides/commerce.md` walkthrough + docs-contract lock** — Phase 37 (DOCS-01, DOCS-02). The
  swap-target `@moduledoc` written here will be cited by that walkthrough.
- **Multi-product / consumable / non-consumable paywalls** — out of scope (AF-04); single
  subscription product is the canonical identity.

None of the above are scope creep into Phase 34 — they are correctly downstream.

</deferred>

---

*Phase: 34-MockStorefront And Idempotency Invariants*
*Context gathered: 2026-05-29*
