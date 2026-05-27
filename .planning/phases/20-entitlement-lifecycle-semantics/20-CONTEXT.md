# Phase 20: Entitlement Lifecycle Semantics - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Expand normalized core commerce contract semantics so entitlement snapshots explicitly model authority, access, reconciliation lifecycle, freshness, effective dates, and evidence metadata while preserving backend-owned entitlement truth and provider-neutral core vocabulary.

This phase defines core semantic contracts and invariants only. It does not ship StoreKit/Play/provider adapters, does not move entitlement authority onto device callbacks, and does not widen scope into a billing engine.

</domain>

<decisions>
## Implementation Decisions

### Snapshot Model Shape
- **D-01:** `EntitlementSnapshot` will be lane-structured, not a single lifecycle enum and not an unstructured bag of flags.
- **D-02:** The canonical lanes are `authority`, `access`, `reconciliation`, `freshness`, `effective`, and `evidence`.
- **D-03:** Snapshot writes remain backend-owned projection outputs; device/storefront/webhook/support events cannot directly write authority.
- **D-04:** Snapshot semantics must support explicit invariants per lane (e.g., stale freshness cannot silently imply authority denial or grant).
- **D-05:** Snapshot contract will include projection ordering metadata (`as_of`/version-style monotonic marker) to prevent stale overwrite during replay/reconciliation.

### Lifecycle Taxonomy
- **D-06:** Lifecycle state modeling is orthogonal across axes: authority state is distinct from access decision, reconciliation workflow state, and freshness state.
- **D-07:** Pending states (`pending_purchase`, `pending_restore`, `awaiting_verification`) are reconciliation states, not authority states.
- **D-08:** Canonical authority vocabulary includes explicit semantics for `active`, `grace`, `billing_retry`, `canceled_scheduled_end`, `revoked`, `refunded`, and `expired` (plus explicit "none/not-entitled" posture).
- **D-09:** `access` remains intentionally minimal (`granted`/`denied`) with required reason metadata so operators and adopters can explain decisions.
- **D-10:** Freshness is explicit (`fresh`/`stale`/`unknown` style posture) and fail-closed behavior must be deliberate and documented, never inferred from provider lifecycle states.

### Evidence Envelope Boundaries
- **D-11:** Core evidence source vocabulary is normalized and bounded: `device`, `storefront`, `webhook`, `support`.
- **D-12:** Core evidence envelopes carry provenance/integrity/idempotency metadata and references (IDs/digests/opaque refs), but do not embed raw provider payloads or provider lifecycle enums.
- **D-13:** Idempotency identity is backend-owned and provider-aware (`provider + provider_reference + event_kind` style), never transient device correlation ID alone.
- **D-14:** Evidence ingestion is append-only evidence posture; evidence updates can progress reconciliation but cannot grant authority without backend verification/projection rules.

### Provider Mapping Boundary
- **D-15:** Provider-specific enum/state mapping is boundary-owned (companion/adapter + host reconciliation boundary), not core-owned.
- **D-16:** Unknown/new provider statuses must map to explicit non-granting normalized states (pending/awaiting-verification/fail-closed guidance), never implicit grant.
- **D-17:** Core contracts, route policy, manifest, doctor, and support truth must remain provider-neutral and reject provider vocabulary leakage.
- **D-18:** Merge-blocking tests should prove provider values do not leak into core contracts and prove evidence cannot directly grant authority.

### Developer Ergonomics and Least Surprise
- **D-19:** Keep contracts typed and explicit (`@enforce_keys`, typespecs, stable atom vocabularies, helper predicates) so adopters can reason about entitlement state with straightforward pattern matching.
- **D-20:** Prefer additive evolution and compatibility-safe taxonomy extension over frequent semantic rewrites, with docs/support/doctor language synchronized to the same vocabulary.

### Claude's Discretion
- Exact field/module naming for lane structs and helper functions as long as lane boundaries and invariants remain explicit.
- Specific reason code naming style as long as they remain stable, operator-friendly, and provider-neutral.
- Internal projection metadata shape (`snapshot_version` vs equivalent monotonic marker) as long as replay ordering safety is preserved.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Scope, Requirements, and Prior Decisions
- `.planning/ROADMAP.md` — Phase 20 goal and success criteria (`ENTL-01`, `ENTL-02`, `ENTL-03`).
- `.planning/REQUIREMENTS.md` — entitlement lifecycle requirements and v3.2 scope guardrails.
- `.planning/PROJECT.md` — backend-owned entitlement truth, provider-neutral core, fail-closed posture.
- `.planning/STATE.md` — current phase position and milestone constraints.
- `.planning/phases/19-commerce-route-corridors/19-CONTEXT.md` — corridor semantics, denial posture, and vocabulary continuity into Phase 20.

### Existing Commerce and Contract Surfaces
- `guides/commerce.md` — canonical authority-vs-evidence stance and reconciliation flow.
- `lib/crosswake/commerce/contracts.ex` — current typed commerce contract structs (baseline to evolve).
- `lib/crosswake/commerce/reconciliation.ex` — current reconciliation vocabulary and idempotency framing.
- `lib/crosswake/commerce.ex` — backend seam callbacks and authority boundary.
- `lib/crosswake/manifest/types.ex` — typed manifest contract patterns and provider-neutral schema style.
- `lib/crosswake/policy/schema.ex` — provider-specific commerce term rejection posture.
- `lib/crosswake/policy/route.ex` — commerce declaration validation patterns.
- `lib/crosswake/support_matrix/support_matrix.ex` — support truth vocabulary and corridor ownership framing.
- `lib/crosswake/doctor/doctor.ex` — explicit denial/fail-closed diagnostic posture.

### Prompt Research Inputs (User-requested)
- `prompts/crosswake-integrations-and-companions.md` — companion boundary posture and adapter separation.
- `prompts/crosswake-elixir-oss-dna.md` — OSS ergonomics, install/support truth, least-surprise DX.
- `prompts/crosswake-research-synthesis.md` — architecture and tradeoff synthesis constraints.
- `prompts/crosswake-gsd-project-brief.md` — project scope and strategic positioning.
- `prompts/crosswake-brand-book.md` — clarity and consistency expectations for developer-facing surfaces.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — architecture tradeoffs under mobile/runtime pressure.
- `prompts/elixir-mobile-apptypes-design-stresstest-deep-research.md` — app-type boundary and ownership pressure.
- `prompts/elixir-mobile-offlinesupport-flashcard-app-stresstest-deep-research.md` — local-first/evidence/freshness caution patterns.
- `prompts/elixir-mobile-offlinesupport-stresstest-deep-research.md` — offline/freshness/fail-closed contract lessons.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` — sequencing and support-honesty guardrails.
- `prompts/elixir-mobile-oss-lib-deep-research.md` — library boundary and ecosystem pattern guidance.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Commerce.Contracts` (`lib/crosswake/commerce/contracts.ex`): typed contract baseline for snapshot/evidence shape expansion.
- `Crosswake.Commerce.Reconciliation` (`lib/crosswake/commerce/reconciliation.ex`): existing workflow-oriented vocabulary and idempotency framing.
- `Crosswake.Commerce` behavior (`lib/crosswake/commerce.ex`): explicit backend seam for submit/ingest/fetch authority flows.
- `Crosswake.Manifest.Types` (`lib/crosswake/manifest/types.ex`): established typed-struct + serializer patterns suitable for additive semantic contract evolution.

### Established Patterns
- Provider-specific vocabulary is rejected at core policy boundaries (`policy/schema` + validators).
- Core contracts use typed structs + explicit keys and avoid implicit dynamic payloads.
- Support/doctor/docs are treated as product surfaces and must share canonical vocabulary.
- Fail-closed posture is explicit and user-guided rather than silent fallback.

### Integration Points
- Expand contract structs and vocab in `lib/crosswake/commerce/contracts.ex`.
- Align reconciliation outcome vocabulary and attempt/evidence semantics in `lib/crosswake/commerce/reconciliation.ex`.
- Update commerce-facing docs/tests (`guides/commerce.md`, `test/crosswake/commerce/contracts_test.exs`, `test/crosswake/commerce/reconciliation_test.exs`) to enforce semantics.
- Keep policy/manifest/support/doctor provider-neutral language consistent as Phase 20 semantics land.

</code_context>

<specifics>
## Specific Ideas

- One-shot recommendation posture requested: cohesive architecture with explicit tradeoffs, least surprise, and strong developer ergonomics.
- Emphasize idiomatic Elixir/Phoenix library design: typed contracts, explicit invariants, additive compatibility evolution, and clear operator-facing semantics.
- Keep user-facing behavior honest: pending/reconciliation/freshness states are explicit and explainable, not hidden behind generic status labels.

</specifics>

<deferred>
## Deferred Ideas

None - discussion stayed within Phase 20 scope.

</deferred>

---

*Phase: 20-entitlement-lifecycle-semantics*
*Context gathered: 2026-05-27*
