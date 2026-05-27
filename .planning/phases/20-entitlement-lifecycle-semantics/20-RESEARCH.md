# Phase 20 Research: Entitlement Lifecycle Semantics

Date: 2026-05-27  
Phase: 20 - Entitlement Lifecycle Semantics  
Requirements: ENTL-01, ENTL-02, ENTL-03

## What This Phase Must Prove

Phase 20 is not a provider adapter phase. It is a core semantics phase.

- ENTL-01: `entitlement_snapshot` must become an explicit lane model for authority, access, reconciliation, freshness, effective dates, and evidence metadata.
- ENTL-02: Lifecycle taxonomy must represent pending/verification/grace/retry/canceled/revoked/refunded/expired/stale without leaking provider enums.
- ENTL-03: Device/storefront/webhook/support evidence must feed reconciliation but must not directly grant authority.

The critical planning question is: how do we make these semantics enforceable in code and testable as fail-closed invariants, not just docs language?

## Current Baseline (What Already Exists)

The codebase already has good primitives to extend:

- Typed contract baseline:
  - `lib/crosswake/commerce/contracts.ex`
  - `lib/crosswake/commerce/reconciliation.ex`
  - `lib/crosswake/commerce.ex`
- Provider-neutral boundary enforcement:
  - `lib/crosswake/policy/schema.ex`
  - `lib/crosswake/policy/validator.ex`
  - `lib/crosswake/manifest/validator.ex`
- Fail-closed denial and support truth surfaces:
  - `lib/crosswake/compatibility/compatibility.ex`
  - `lib/crosswake/doctor/doctor.ex`
  - `lib/crosswake/support_matrix/support_matrix.ex`
  - `guides/commerce.md`, `guides/support_matrix.md`
- Existing tests already encode anti-leak and anti-authority assumptions:
  - `test/crosswake/commerce/contracts_test.exs`
  - `test/crosswake/commerce/reconciliation_test.exs`
  - `test/crosswake/guides/commerce_test.exs`
  - `test/crosswake/policy/*`, `test/crosswake/manifest/*`, `test/crosswake/doctor/*`

Key gap: current entitlement semantics are still mostly flat fields and compile-time struct shape; lane-level invariants are not yet first-class runtime validation.

## Standard Stack

- Stay with current stack: typed Elixir structs + explicit constructor/validator functions + manifest/support/docs parity tests.
- Keep provider adapters out of core; no StoreKit/Play-specific modules in this phase.
- Keep additive contract evolution and provider-neutral atoms/strings at boundaries.
- Keep fail-closed behavior explicit in docs/support truth; do not infer authority from freshness/evidence.

## Architecture Pattern Recommendation

### 1) Lane-Oriented Snapshot Contract

Evolve `Crosswake.Commerce.Contracts.EntitlementSnapshot` from flat fields into explicit lanes:

- `authority` lane (backend authority truth)
- `access` lane (granted/denied + required reason)
- `reconciliation` lane (workflow state only)
- `freshness` lane (fresh/stale/unknown posture)
- `effective` lane (`effective_from`/`effective_until`)
- `evidence` lane (bounded metadata + provenance, no raw provider payload)
- ordering marker (`as_of` or monotonic snapshot version) for replay safety

Implementation note: keep top-level `EntitlementSnapshot` as the public type, but strongly consider nested lane structs (`AuthorityLane`, `AccessLane`, etc.) so pattern matching stays explicit and bounded.

### 2) Taxonomy Separation by Axis (No Enum Collapse)

Use orthogonal vocabularies instead of one lifecycle enum:

- `authority` vocabulary: include `:none`, `:active`, `:grace`, `:billing_retry`, `:canceled_scheduled_end`, `:revoked`, `:refunded`, `:expired`
- `access` vocabulary: keep `:granted | :denied` plus required `reason`
- `reconciliation` vocabulary: retain/extend `:pending_purchase`, `:pending_restore`, `:awaiting_verification`, `:projection_refreshed`, `:conflict`, `:verification_failed`, `:stale_authority`
- `freshness` vocabulary: `:fresh | :stale | :unknown`

Critical invariant: pending/reconciliation states are never authority grants.

### 3) Evidence Envelope as Non-Authoritative Input

Expand `ReconciliationEvidence` to include bounded provenance metadata:

- normalized source vocabulary: `:device | :storefront | :webhook | :support`
- idempotency-related references (provider-aware identifiers)
- integrity metadata (digest/reference) and opaque reference IDs
- no raw provider enum/status fields in core

Evidence remains append-only input posture and may advance reconciliation state, but cannot directly mutate authority lane.

## Boundary Rules To Lock (Provider-Neutral Core)

These should become explicit plan-level invariants and tests:

1. Provider-specific status names are invalid in core contract fields and validations.
2. Unknown provider statuses map to non-granting normalized states at adapter boundary.
3. Core evidence metadata may carry references/digests, not raw provider payload objects.
4. Authority lane changes are backend projection outputs only.
5. `freshness` does not auto-grant or auto-deny authority; fail-closed behavior must be explicit.
6. Route policy/manifest/support/doctor surfaces stay on Crosswake vocabulary only.

Existing modules to reuse for boundary posture:

- `Crosswake.Policy.Schema` and `Crosswake.Policy.Validator` patterns for provider-term rejection
- `Crosswake.Manifest.Validator.provider_specific_vocabulary?/1` pattern for deep vocabulary scanning

## Test Strategy (Especially ENTL-03)

### Contract Tests

Update/add tests in:

- `test/crosswake/commerce/contracts_test.exs`
- `test/crosswake/commerce/reconciliation_test.exs`

Must cover:

- lane presence and required fields
- taxonomy placement (e.g., `pending_restore` only reconciliation lane)
- invalid mixed states rejected by constructors/validators
- evidence source vocabulary includes `device/storefront/webhook/support` and excludes provider enums

### Authority Separation Tests (Merge-Blocking)

Add explicit negative tests proving evidence cannot grant authority:

- evidence submission with success-like status does not produce `authority: :active` without explicit backend projection transition
- `access: :granted` cannot be derived from evidence-only payload
- replayed duplicate evidence remains idempotent reconciliation input, not authority mutation
- stale freshness cannot silently map to authority grant

Best place to assert this behavior:

- `test/crosswake/commerce/reconciliation_test.exs`
- optionally a focused new file such as `test/crosswake/commerce/authority_separation_test.exs`

### Boundary Leakage Tests

Extend existing pattern tests to reject provider-specific leakage in core semantics:

- `test/crosswake/policy/schema_test.exs`
- `test/crosswake/policy/route_test.exs`
- `test/crosswake/manifest/validator_test.exs`
- `test/crosswake/guides/commerce_test.exs`

Assertions should fail on terms like `storekit`, `play_billing`, `revenuecat` in contract-facing vocab.

### Docs/Support Parity Tests

Keep truth synchronized:

- `test/crosswake/support_matrix/support_matrix_test.exs`
- `test/crosswake/support_matrix/renderer_test.exs`
- `test/crosswake/doctor/doctor_test.exs`
- `test/crosswake/guides/commerce_test.exs`

## Docs and Support Implications (Fail-Closed + Freshness)

Phase 20 should update semantics language now, while avoiding Phase 22 scope creep:

- `guides/commerce.md`
  - document lane model and invariants
  - add explicit freshness/fail-closed behavior table
  - clarify that stale/unknown freshness is an operator-visible state, not implicit authority transition
- `lib/crosswake/support_matrix/support_matrix.ex` + `guides/support_matrix.md`
  - tighten entitlement/reconciliation capability prerequisites and fallback wording to include freshness posture
- `lib/crosswake/doctor/doctor.ex` formatters/tests
  - if adding freshness findings now, keep minimal and semantic-only
  - avoid full operational stale-snapshot diagnostics that belong to Phase 22 support/proof expansion

## Sequencing Guidance For Planning Tasks

Recommended order:

1. **Contract model upgrade**
   - lane structs/types, vocabulary constants, constructor/validation functions
2. **Reconciliation alignment**
   - map existing outcomes into reconciliation lane semantics, keep idempotency rules explicit
3. **Boundary hardening**
   - provider-term rejection and no-leak enforcement for new contract fields
4. **Evidence-authority invariants**
   - implement and test non-authoritative evidence path
5. **Docs/support vocabulary sync**
   - commerce + support matrix text and renderer parity
6. **Verification sweep**
   - ensure merge-blocking tests cover ENTL-01/02/03 specifically

This order minimizes rework: contract and invariants first, docs/support sync after vocabulary stabilizes.

## Risks and Pitfalls

1. **Axis collapse regression**
   - risk: simplifying back into one lifecycle enum
   - control: typed lane structs + tests that assert orthogonality
2. **Provider leakage**
   - risk: provider statuses sneak into core fields/docs/tests
   - control: validator rejection + grep-based docs tests + manifest/policy checks
3. **Evidence-to-authority shortcut**
   - risk: convenience code grants access from evidence success
   - control: negative tests for ENTL-03; no authority mutation API in evidence path
4. **Freshness ambiguity**
   - risk: stale freshness interpreted inconsistently across docs/support
   - control: single canonical freshness vocabulary and explicit fail-closed guidance
5. **Scope bleed into Phase 21/22**
   - risk: full reconciliation example or support-proof operationalization added too early
   - control: keep Phase 20 contract-semantic and vocabulary-focused

## File-Level Change Map (Planning Input)

Primary implementation files:

- `lib/crosswake/commerce/contracts.ex`
- `lib/crosswake/commerce/reconciliation.ex`
- `lib/crosswake/commerce.ex`
- `lib/crosswake/manifest/builder.ex` (capability/support wording alignment if vocabulary changes)
- `lib/crosswake/support_matrix/support_matrix.ex`
- `guides/commerce.md`
- `guides/support_matrix.md`

Boundary enforcement files likely touched:

- `lib/crosswake/policy/schema.ex`
- `lib/crosswake/policy/validator.ex`
- `lib/crosswake/manifest/validator.ex`

Potential minimal diagnostic sync:

- `lib/crosswake/doctor/doctor.ex`
- `lib/crosswake/doctor/formatter.ex`
- `lib/crosswake/doctor/json_formatter.ex`

Likely tests to update/add:

- `test/crosswake/commerce/contracts_test.exs`
- `test/crosswake/commerce/reconciliation_test.exs`
- `test/crosswake/guides/commerce_test.exs`
- `test/crosswake/support_matrix/support_matrix_test.exs`
- `test/crosswake/support_matrix/renderer_test.exs`
- `test/crosswake/manifest/validator_test.exs`
- `test/crosswake/policy/schema_test.exs`
- `test/crosswake/policy/route_test.exs`
- `test/crosswake/doctor/doctor_test.exs` (only if freshness semantics are surfaced now)

## Requirement Mapping (Explicit)

### ENTL-01

Deliverables:

- lane-structured `EntitlementSnapshot`
- explicit freshness/effective/evidence metadata lanes
- projection ordering marker for replay safety

Acceptance checks:

- snapshot constructors/validators reject missing required lanes
- tests assert lane presence and typed vocabulary boundaries

### ENTL-02

Deliverables:

- orthogonal taxonomy across authority/access/reconciliation/freshness
- required lifecycle states represented in Crosswake-owned vocabulary
- no raw provider enums in core contracts

Acceptance checks:

- tests verify each required state exists in the correct lane
- tests reject provider-specific values in core semantic fields

### ENTL-03

Deliverables:

- evidence envelope supports device/storefront/webhook/support provenance
- evidence path remains non-authoritative by construction
- reconciliation may progress from evidence without authority grant

Acceptance checks:

- merge-blocking negative tests prove evidence cannot directly grant authority
- idempotency tests prove replay/duplicates do not mutate authority directly
- docs/support language states fail-closed evidence posture clearly
