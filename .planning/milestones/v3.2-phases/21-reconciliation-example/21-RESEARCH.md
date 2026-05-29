# Phase 21 Research: Reconciliation Example

Date: 2026-05-27  
Phase: 21 - Reconciliation Example  
Requirements: RECN-01, RECN-02, RECN-03

## 1) What This Phase Must Prove

Phase 21 is an implementation example phase, not a provider adapter phase and not a core entitlement redesign.

- **RECN-01:** Show a minimal Phoenix-owned reconciliation inbox flow that accepts evidence from `purchase`, `restore`, `webhook`, and `support` paths.
- **RECN-02:** Demonstrate idempotency with provider-aware backend identity, explicitly not transient device correlation IDs.
- **RECN-03:** Show one authoritative entitlement projection path that produces explicit `stale`, `pending`, `denied`, and `granted` outcomes.

Planning must preserve the v3.2 thesis already locked in prior phases:

- Entitlement authority is backend-owned and projection-owned.
- Device/storefront/webhook/support signals are evidence, not direct grants.
- Provider adapters and storefront SDK choreography remain out of scope.
- The deliverable is `example/docs-only` and companion-ready, without imposing storage/job framework choices on core.

## 2) Baseline / Reusable Assets

The repository already contains most primitives needed to build a minimal reference implementation.

- **Core contracts already model required semantics**
  - `lib/crosswake/commerce/contracts.ex` provides lane-structured `EntitlementSnapshot` and canonical `ReconciliationEvidence` source vocabulary.
  - `lib/crosswake/commerce/reconciliation.ex` provides evidence ingestion, replay detection shape, and explicit non-authoritative outcomes.
  - `lib/crosswake/commerce.ex` keeps orchestration thin and backend-owned.

- **Current docs already define canonical flow**
  - `guides/commerce.md` already states the ingestion -> reconciliation -> projection sequence and authority/evidence separation.
  - `test/crosswake/guides/commerce_test.exs` already locks key commerce vocabulary and canonical flow wording.

- **Current tests already enforce fail-closed basics**
  - `test/crosswake/commerce/contracts_test.exs` enforces lane vocabulary, bounded evidence source values, and snapshot shape.
  - `test/crosswake/commerce/reconciliation_test.exs` enforces replay handling and "evidence cannot grant authority."

- **Example host pattern is already established**
  - Proof tests already load checked-in example host code via `Crosswake.TestSupport.ExampleHost.load!/0`.
  - This supports placing Phase 21 runnable reference modules in `examples/phoenix_host` without moving logic into core runtime packages.

## 3) Recommended Architecture + Boundaries

### Recommended artifact set

Use a **hybrid artifact** approach for least surprise and planning clarity:

1. Guide narrative in `guides/commerce.md` (or a tightly linked dedicated reconciliation section/file).
2. Executable reference modules in `examples/phoenix_host/lib/crosswake_example/commerce/`.
3. Hermetic tests in top-level `test/` that exercise those reference modules.

This keeps the phase concrete while preserving `example/docs-only` scope.

### Reference module boundaries (example-host only)

Recommended module split:

- `CrosswakeExample.Commerce.ReconciliationInbox`
  - Accepts typed `ReconciliationEvidence`.
  - Records append-only normalized events (in-memory store or host-provided persistence callback).
  - Computes idempotency/replay metadata.
  - Produces canonical attempt records.

- `CrosswakeExample.Commerce.ReconciliationKeys`
  - Computes:
    - `event_key` for dedupe/replay safety.
    - `subject_key` for per-subject authoritative serialization.
  - Explicitly ignores transient device correlation IDs as identity authority.

- `CrosswakeExample.Commerce.EntitlementProjection`
  - Applies verified reconciliation outcomes to one canonical `EntitlementSnapshot`.
  - Enforces monotonic projection ordering (`as_of` guard) so older evidence cannot overwrite fresher snapshots.
  - Exposes both:
    - full lane-structured snapshot (`authority` source of truth), and
    - derived top-level state (`stale | pending | denied | granted`) for consumer ergonomics.

### Key algorithmic rules to lock during planning

- **Dual-key idempotency**
  - `event_key`: provider-aware dedupe identity (ex: provider + provider_reference + event_kind + stable event identity).
  - `subject_key`: canonical entitlement subject identity used to serialize authoritative updates and resolve out-of-order events.

- **Non-authoritative ingestion**
  - Ingestion can return statuses like `awaiting_verification` and replay metadata.
  - It cannot write `authority` directly.

- **Projection precedence (fail-closed)**
  - `stale`/freshness-unknown first.
  - then unresolved reconciliation -> `pending`.
  - then access-derived `granted`/`denied` only when freshness and invariants are valid.
  - lane mismatch or unknown state returns fail-closed outcome with reason metadata.

### Out-of-scope guardrails (must remain explicit)

- No StoreKit/Play Billing/RevenueCat adapters in this phase.
- No provider SDK callback implementations in core.
- No mandatory Ecto schema, queue, or background job framework contract.
- No generic billing engine behavior in `lib/crosswake`.

## 4) Test / Verification Strategy

Phase 21 should be validated as merge-blocking hermetic proof for RECN requirements.

- **Reference example behavior tests (new)**
  - Verify append-only inbox ingestion for each source: `:device`, `:storefront`, `:webhook`, `:support`.
  - Verify duplicate event replay returns idempotent non-failing response and does not grant authority.
  - Verify out-of-order evidence cannot regress canonical projection because of `as_of` monotonic guard.

- **Idempotency semantics tests (new)**
  - Assert `event_key` dedupes retries.
  - Assert `subject_key` serializes authoritative updates for a subject.
  - Assert transient correlation IDs do not define identity authority.

- **Projection state tests (new)**
  - Assert deterministic derivation of `stale`, `pending`, `denied`, and `granted`.
  - Assert stale/unknown freshness remains fail-closed.
  - Assert pending reconciliation states remain non-granting.

- **Docs contract tests (update existing)**
  - Extend `test/crosswake/guides/commerce_test.exs` to lock:
    - minimal reconciliation inbox example presence,
    - dual-key idempotency guidance,
    - projection precedence semantics.

- **Suggested verification commands**
  - `mix test test/crosswake/proof/phase21_reconciliation_example_test.exs`
  - `mix test test/crosswake/guides/commerce_test.exs`
  - `mix test test/crosswake/commerce/contracts_test.exs test/crosswake/commerce/reconciliation_test.exs`
  - `mix test`

## 5) Risks / Pitfalls

1. **Authority shortcut regression**  
   Risk: reference code accidentally mutates authority during evidence ingestion.  
   Control: negative tests for non-authoritative ingestion; projection-only authority updates.

2. **Weak idempotency keys**  
   Risk: relying on transient correlation IDs or source-local IDs causes duplicate grants or dropped updates.  
   Control: lock dual-key model (`event_key` + `subject_key`) in both guide and tests.

3. **Projection overwrite race**  
   Risk: older/out-of-order evidence overwrites fresher snapshot.  
   Control: monotonic `as_of` guard and explicit stale conflict behavior.

4. **Provider leakage into core/example contracts**  
   Risk: StoreKit/Play enum terms leak into example vocabulary and guide copy.  
   Control: use existing provider-neutral vocabulary checks and docs tests.

5. **Scope creep into adapter infrastructure**  
   Risk: adding provider clients, webhook verifiers, job pipelines, or schema mandates.  
   Control: keep those as host-owned placeholders/interfaces; do not implement adapters.

6. **Docs/runtime drift**  
   Risk: guide narrative diverges from executable reference behavior.  
   Control: docs tests assert exact example terms and flow order.

## 6) File-Level Change Map

Recommended primary files for Phase 21 planning:

- `guides/commerce.md` (modify)
  - Add minimal reconciliation inbox + projection example section.
  - Add explicit dual-key idempotency guidance and projection precedence table.

- `test/crosswake/guides/commerce_test.exs` (modify)
  - Lock new example section wording and requirement-specific vocabulary.

- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex` (new)
  - Append-only event ingestion reference module.

- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex` (new)
  - `event_key` and `subject_key` derivation reference module.

- `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex` (new)
  - Monotonic projection + derived state mapping reference module.

- `test/crosswake/proof/phase21_reconciliation_example_test.exs` (new)
  - Hermetic tests proving RECN-01/02/03 behavior against example-host modules.

Optional/conditional (only if required for discoverability):

- `examples/phoenix_host/README.md` (modify)
  - Add pointer to reconciliation example modules and boundary statement.

Not recommended for this phase unless a clear gap appears:

- Core contract modules in `lib/crosswake/commerce/*` (already provide needed primitives).
- Support matrix / doctor surfaces (primarily Phase 22 scope).

## 7) Explicit Requirement Mapping

### RECN-01 - Minimal Phoenix-owned reconciliation inbox example

**What to deliver**
- Example-host module that accepts purchase/restore/webhook/support evidence into an append-only inbox stream.
- Canonical attempt projection/read model for operator-friendly status visibility.
- Guide section that explains ownership boundaries and ingestion flow.

**How to prove**
- Tests ingest each evidence source and verify normalized event records and attempt statuses.
- Tests assert no direct authority grants during ingestion.

### RECN-02 - Provider-aware idempotency guidance (not transient correlation ID)

**What to deliver**
- Explicit dual-key idempotency guidance:
  - `event_key` for dedupe/replay.
  - `subject_key` for serialized authoritative updates.
- Example code that computes both keys from provider-aware fields.

**How to prove**
- Replay test for duplicate `event_key`.
- Ordering/serialization tests by `subject_key`.
- Negative test showing correlation ID changes do not redefine authority identity.

### RECN-03 - One authoritative projection with stale/pending/denied/granted

**What to deliver**
- Example projection module that updates one canonical `EntitlementSnapshot` and enforces monotonic `as_of`.
- Derived top-level state helper (`stale | pending | denied | granted`) with deterministic precedence.

**How to prove**
- Tests for each derived state and precedence ordering.
- Tests proving stale/unknown freshness is fail-closed.
- Tests proving pending states remain non-granting until verified projection refresh.

## Planning Decisions To Lock Before Execution

1. Exact `event_key` and `subject_key` field composition for the example contract.
2. Whether the reference persistence sample is in-memory only or includes optional Ecto-shaped pseudocode.
3. Whether to add a dedicated guide subsection in `guides/commerce.md` or split to `guides/commerce_reconciliation_example.md` with backlink.
4. Whether the new example proof file belongs under `test/crosswake/proof/` (recommended for example-host coupling) or `test/crosswake/commerce/`.
