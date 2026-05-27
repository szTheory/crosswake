# Phase 21: Reconciliation Example - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Provide a minimal Phoenix-owned reconciliation inbox and entitlement projection example that covers purchase, restore, webhook, and support evidence flows; demonstrates provider-aware idempotency; and produces one authoritative entitlement snapshot with explicit pending, stale, denied, and granted outcomes.

This phase is example/docs-only and companion-ready. It does not ship provider adapters, does not move entitlement authority to device/storefront callbacks, and does not impose a persistence or job framework on host apps.

</domain>

<decisions>
## Implementation Decisions

### Example Artifact Shape
- **D-01:** Ship a hybrid artifact set: guide narrative + executable reference modules + hermetic tests.
- **D-02:** Keep executable reference code in example-host/docs-only surfaces, not core runtime packages.
- **D-03:** Documentation is guide-first and maps directly to runnable tests so adopters can move from concept to proof quickly with least surprise.

### Reconciliation Inbox Model
- **D-04:** Model reconciliation ingestion as append-only normalized evidence events (`device`, `storefront`, `webhook`, `support`) to preserve auditability.
- **D-05:** Maintain a canonical attempt projection/read model for operator ergonomics (status, replay visibility, verification metadata).
- **D-06:** Keep entitlement authority in one backend-projected snapshot lane model; evidence ingestion can advance reconciliation state but cannot directly grant authority.

### Idempotency And Replay Policy
- **D-07:** Use a two-key model: `event_key` for dedupe/replay safety and `subject_key` for serializing authoritative updates per entitlement subject.
- **D-08:** `event_key` and `subject_key` are provider-aware and backend-owned; transient device correlation IDs are trace metadata only, not idempotency authority.
- **D-09:** Duplicate events return idempotent replay outcomes (non-failing), increment replay metadata, and never directly mutate authority.
- **D-10:** Out-of-order or replacement-token evidence is recorded and reconciled through canonical subject mapping, with non-granting states until verified projection refreshes.

### Projection Output Contract
- **D-11:** Publish a dual-layer projection: full lane-structured snapshot remains authoritative, plus a derived top-level state for adopters (`stale`, `pending`, `denied`, `granted`).
- **D-12:** Precedence is explicit and deterministic: `stale`/unknown freshness is fail-closed first, `pending` remains non-granting reconciliation state, then `granted`/`denied` decisions apply when freshness and invariants are valid.
- **D-13:** Projection writes require monotonic ordering (`as_of` or equivalent) so older evidence cannot overwrite fresher authoritative snapshots.
- **D-14:** Any lane mismatch or unknown state is fail-closed with explicit reason metadata.

### Integration Boundary Posture
- **D-15:** Core owns normalized contracts, vocabulary, invariants, and docs/test truth only.
- **D-16:** Host apps own persistence schema choices, job orchestration, verification clients, and projection pipeline implementation.
- **D-17:** Companion/provider adapters own storefront SDK choreography, webhook/provider enum mapping, and provider-specific operational setup.
- **D-18:** Provider enums and SDK-specific lifecycle labels must never leak into core contract surfaces.

### Claude's Discretion
- Exact example module/file naming and internal helper decomposition, as long as the ownership boundaries above remain explicit.
- Whether example storage implementation uses ETS/in-memory fixtures or lightweight Ecto examples, as long as it is clearly non-prescriptive.
- Exact reason code names and test fixture composition, as long as semantics remain provider-neutral and fail-closed.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Scope And Requirements
- `.planning/ROADMAP.md` — Phase 21 goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` — RECN-01/02/03 plus v3.2 scope/proof/support guardrails.
- `.planning/PROJECT.md` — Phoenix-first thesis, backend-owned entitlement truth, and out-of-scope boundaries.
- `.planning/STATE.md` — current phase posture and operational constraints.
- `.planning/MILESTONE-ARC.md` — milestone sequencing and boundary posture.

### Prior Locked Decisions
- `.planning/phases/19-commerce-route-corridors/19-CONTEXT.md` — corridor ownership, denial posture, and provider-neutral vocabulary expectations.
- `.planning/phases/20-entitlement-lifecycle-semantics/20-CONTEXT.md` — lane semantics, evidence boundaries, idempotency framing, and fail-closed posture.

### Existing Commerce Contracts And Behavior
- `guides/commerce.md` — canonical reconciliation flow, authority-vs-evidence, and explicit non-goals.
- `lib/crosswake/commerce.ex` — backend seam behavior contract for intents, evidence ingestion, and snapshot reads.
- `lib/crosswake/commerce/contracts.ex` — lane-structured entitlement and evidence vocabulary.
- `lib/crosswake/commerce/reconciliation.ex` — reconciliation outcomes, evidence ingestion semantics, and authority separation.
- `test/crosswake/commerce/reconciliation_test.exs` — proof that evidence does not grant authority and replay remains non-granting.
- `test/crosswake/guides/commerce_test.exs` — guide contract expectations and vocabulary lock.

### Prompt Research Inputs (User-requested)
- `prompts/crosswake-integrations-and-companions.md` — companion boundary and adapter posture.
- `prompts/crosswake-elixir-oss-dna.md` — Elixir OSS ergonomics, install truth, and support posture.
- `prompts/crosswake-research-synthesis.md` — research synthesis constraints and tradeoff framing.
- `prompts/crosswake-gsd-project-brief.md` — project goals/positioning guardrails.
- `prompts/crosswake-brand-book.md` — communication clarity and consistency expectations.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — architecture tradeoffs.
- `prompts/elixir-mobile-apptypes-design-stresstest-deep-research.md` — ownership and app-type pressure.
- `prompts/elixir-mobile-offlinesupport-flashcard-app-stresstest-deep-research.md` — local-first caution patterns.
- `prompts/elixir-mobile-offlinesupport-stresstest-deep-research.md` — offline/freshness/fail-closed lessons.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` — sequencing and support-honesty guidance.
- `prompts/elixir-mobile-oss-lib-deep-research.md` — OSS library boundary and ecosystem patterns.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Commerce.Contracts` in `lib/crosswake/commerce/contracts.ex`: already encodes lane-structured entitlement and bounded evidence vocabulary.
- `Crosswake.Commerce.Reconciliation` in `lib/crosswake/commerce/reconciliation.ex`: already models non-granting reconciliation outcomes, ingestion semantics, and replay checks.
- `Crosswake.Commerce` behavior in `lib/crosswake/commerce.ex`: explicit seam for host-owned submission/ingestion/fetch orchestration.
- `guides/commerce.md` plus `test/crosswake/guides/commerce_test.exs`: existing docs-contract lane for adding Phase 21 example truth.

### Established Patterns
- Provider-specific terms are intentionally kept outside core vocabulary.
- Evidence and authority are explicitly separated, with merge-blocking tests proving no implicit grants.
- Fail-closed behavior with explicit reasoning is preferred over silent fallback.
- Support/docs/test parity is treated as product contract, not optional cleanup.

### Integration Points
- Extend commerce guide surfaces with a dedicated reconciliation-example section and docs-contract tests.
- Add example-host reference modules/tests for inbox events, canonical attempts, and snapshot projection semantics.
- Keep core contracts stable while showing host-owned seams for persistence/jobs/provider verification integration.

</code_context>

<specifics>
## Specific Ideas

- Recommendations should be one-shot, coherent across all phase decisions, and optimized for least-surprise developer experience.
- Prioritize explicit tradeoffs and practical defaults so downstream planning can proceed without additional founder decision loops.
- Keep architecture and developer ergonomics aligned: explicit ownership boundaries, predictable behavior, and user-friendly guide flow from concept to runnable proof.

</specifics>

<deferred>
## Deferred Ideas

None - discussion remained within Phase 21 scope.

</deferred>

---

*Phase: 21-reconciliation-example*
*Context gathered: 2026-05-27*
