# Phase 158: Adoption Reset and Route Map - Context

**Gathered:** 2026-07-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Freeze the first-adopter operating boundary before implementation resumes:

1. make the infrastructure framing, Alpha/public-v1 split, reversal condition, stop list, and
   privacy boundary durable and discoverable;
2. preserve v20 as stopped/partial without turning abandoned Phase 156-157 planning into shipped
   evidence;
3. define an honest, sanitized route-inventory contract with one runtime owner, authority story,
   offline posture, fallback, and remote-disable posture for every known surface;
4. align canonical capability/support truth with the first-adopter sequence; and
5. route durable, public, fast-changing, host-private, and secret information to the correct
   surfaces with automated privacy checks.

This phase does not implement the proof-lane generator, scoped replay, the iOS pack provider, or
physical-device proof. It does not add a dashboard, generic sync/storage, native-control breadth,
Android work, or a Crosswake feature-flag service.

</domain>

<decisions>
## Implementation Decisions

### Inventory completion

- **D-01:** Separate **policy-contract completeness** from **adopter-instance completeness**.
  Phase 158 may close when GET-6, v20 stopped/partial truth, public support truth, privacy routing,
  and the known-surface ownership/default map are durable. It must not fabricate adopter-specific
  route facts that have not been supplied.

- **D-02:** Every missing adopter-supplied value uses the explicit state
  `unknown_blocking`. Blank cells, optimistic defaults, inferred product details, and prose that
  can be mistaken for confirmation are forbidden.

- **D-03:** Keep TODO-002 open until sanitized concrete route rows exist. Phase 159 may build the
  configurable host-proof scaffold from the frozen contract, but no external-host proof or
  physical-device support claim may be promoted while required route inputs remain
  `unknown_blocking`.

- **D-04:** If customer Alpha is web-only, complete the bounded reset/inventory and pause
  Crosswake. Resume adopter integration only when the public-v1 mobile path is active.

### Route-row privacy and granularity

- **D-05:** Use a layered inventory: retain a compact product-surface/default-ownership table for
  discovery, then require one sanitized row per concrete Phoenix route pattern before that route
  participates in adopter-host proof. A route pattern is a compiled route such as
  `/study/session/:id`, not a database record, lesson, learner, or other resource instance.

- **D-06:** Family defaults may reduce repetition only for non-sensitive posture. Auth, recent
  auth, scope, mutation, media, fallback, and remote-disable fields must be explicit per concrete
  route; they never inherit silently.

- **D-07:** Route-row status uses the closed vocabulary `confirmed_sanitized`, `known_default`,
  `unknown_blocking`, and `not_applicable`. Unknown safety-critical posture fails closed.

- **D-08:** The durable sanitized row contract contains only:
  opaque route ID; sanitized path pattern; runtime owner; offline posture; low-cardinality mutation
  categories; staleness class; auth level/recent-auth requirement; scope/logout/account-switch
  posture; media requirement with size band, codec family, and integrity requirement; online,
  offline, denied, corrupt-pack, and disabled fallbacks; entry/replay disablement posture; and
  queued-data retention posture.

- **D-09:** Durable route rows must not contain raw/free-form payload examples, learner or customer
  data, account IDs, credentials, tokens, stable device IDs, proprietary curriculum taxonomy,
  exact archive filenames/layout, URLs, CDN/auth details, actual host flag names, product copy,
  price, geography, or revealing links. Exact byte counts, digests, endpoints, and flag names live
  in host configuration when integration begins.

- **D-10:** Validate inventory input as closed, structured data with the same discipline as an
  Ecto embedded schema and changeset: cast only named fields, reject unknown keys, use closed enums,
  require safety fields, and return calm field-specific errors without echoing rejected sensitive
  values. Phase 158 should not add a runtime database or public generic inventory framework merely
  to obtain this validation.

### Capability and support-truth vocabulary

- **D-11:** `adoption_implication` becomes the canonical capability-map vocabulary. The public
  guide continues to render the column as **Adoption implication**.

- **D-12:** Preserve `v20_implication` as a legacy renderer/input alias for one compatibility
  window because `Crosswake.CapabilityMap.canonical/0` and map-based renderer inputs make the row
  shape observable even though `Row` is hidden from generated documentation. Normalize both names
  through one function, prefer the canonical field, and fail if both are present with conflicting
  values. — **Reversibility:** costly — removing the alias immediately could break external
  pattern matches or renderer inputs; later removal needs a documented compatibility change.

- **D-13:** New canonical rows use `adoption_implication`. Historical rows may name v20 as
  provenance, but current recommendations must not present Native Controls Pack 1 as the active
  organizing axis. Tests must prove canonical new-field usage, legacy-map compatibility,
  conflicting-dual-value rejection, and deterministic guide regeneration.

### Context routing and privacy enforcement

- **D-14:** Use one centralized routing matrix with these destinations:
  settled architecture, sanitized route posture, and non-goals in durable git; generic
  first-adopter support claims in public guides; fast-changing execution in codename-only Linear
  issues; exact endpoints/flags/archive metadata/account mapping in the host repository or runtime
  configuration; credentials and private terms in secret storage/environment only; and raw
  answers/media/transcripts/account or device identifiers in none of the planning, telemetry,
  diagnostic, inspection, aggregate, or evidence surfaces.

- **D-15:** Keep scanning scope explicit but drift-checked. Classify active governing documents,
  Phase 158 context/log artifacts, TODO-002, codename-only Linear drafts, `AGENTS.md`, the
  capability map, and support matrix. Exclude historical milestone archives, prompt lineage,
  superseded brand seeds, raw fixtures/evidence, and git history. Never search history or external
  sources to rediscover adopter identity.

- **D-16:** Always-on public CI enforces the codename/public-phrase split, generic prohibited
  identity/commercial patterns, forbidden field vocabulary, routing-matrix coverage, and a
  synthetic private-term canary. It must not claim knowledge of a private term that was not
  supplied.

- **D-17:** A privileged/local scan accepts real prohibited terms through
  `CROSSWAKE_PRIVATE_ADOPTER_TERMS` (or an equivalent secret-backed runtime input). Terms are
  case-insensitive, never printed, persisted, uploaded, embedded in artifacts, or included in test
  failure text. Failures report only a stable rule ID and affected path. Ordinary fork PRs do not
  fail merely because private CI secrets are unavailable; protected adoption-context validation
  must run the privileged check before promotion.

- **D-18:** Credential-oriented scanners may remain later defense-in-depth, but Phase 158 does not
  add a new scanner service or dependency. Their default patterns do not replace the
  adopter-context routing and private-term contract.

### Maintainer experience and communication

- **D-19:** Phase 158 has no new end-user UI. Its primary user experience is the maintainer's
  inventory, validation, and failure-recovery flow. Tables use meaningful headings and text status
  (never color alone); errors name the route reference, missing field, and safe remediation; and
  all copy follows the ratified brand voice: calm, exact, operational, and free of framework
  theatrics.

- **D-20:** Optimize for a solo maintainer: deterministic browser-free ExUnit checks, one canonical
  path matrix, one implication normalizer, no dashboard, no new label family, and no external
  service required for the core Phase 158 proof.

### the agent's Discretion

The user delegated exact implementation mechanics after requesting one coherent, research-backed
recommendation set. Planning may choose the smallest internal module/helper boundaries, exact
status serialization shape, test-fixture names, and compatibility-window removal note that satisfy
the decisions above. It may not weaken explicit unknowns, privacy exclusions, route-local
authority, or proof-promotion gates.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Governing first-adopter decisions

- `.planning/ADR-FIRST-B2C-ADOPTER.md` — GET-6, reversal conditions, privacy boundaries, stop list,
  iOS-only posture, pack boundary, and broad sync non-goals.
- `.planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md` — complete strategy, surface audit, route inputs,
  ownership boundaries, stakeholder lenses, proof sequence, and stop date.
- `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` — current default route ownership, inventory
  fields, study/pack invariants, and physical-iPhone exit test.
- `.planning/FIRST-B2C-ADOPTER-LINEAR-ISSUE-DRAFTS.md` — codename-only fast-changing execution
  routing.
- `.planning/todos/TODO-002-first-b2c-adopter-route-inputs.md` — unresolved sanitized concrete
  route inputs; remains open until supplied.
- `AGENTS.md` — repository working rules, privacy restrictions, current priority, and stop list.

### Active milestone truth

- `.planning/PROJECT.md` — project thesis, first-adopter forcing function, constraints, and durable
  project decisions.
- `.planning/REQUIREMENTS.md` — RESET-01 through RESET-04 and v21 non-goals.
- `.planning/ROADMAP.md` — Phase 158 boundary, target, success criteria, canonical strategy source,
  downstream ordering, and stop date.
- `.planning/STATE.md` — current position, blockers, decisions, deferred work, and working-tree
  warning.
- `.planning/MILESTONES.md` — canonical v20 stopped/partial history.
- `.planning/milestones/v20.0-ROADMAP.md` — delivered/retained versus stopped v20 phases and
  abandoned-evidence classification.
- `.planning/milestones/v20.0-REQUIREMENTS.md` — satisfied, partial, and dropped v20 requirement
  truth.

### Capability and support truth

- `lib/crosswake/capability_map.ex` — canonical capability rows and the legacy
  `v20_implication` field being migrated.
- `lib/crosswake/capability_map/renderer.ex` — deterministic public-guide rendering and map
  normalization boundary.
- `lib/crosswake/support_matrix/support_matrix.ex` — canonical platform/support posture.
- `lib/crosswake/support_matrix/renderer.ex` — deterministic support-matrix guide rendering.
- `guides/capability_map.md` — public first-adopter capability and adoption implications.
- `guides/support_matrix.md` — public first-adopter readiness, Android freeze, replay privacy, pack,
  and physical-device proof posture.
- `test/crosswake/capability_map/capability_map_test.exs` — row-shape and first-adopter pressure
  contracts.
- `test/crosswake/capability_map/renderer_test.exs` — renderer vocabulary, escaping, and
  deterministic guide contract.
- `test/crosswake/support_matrix/support_matrix_test.exs` — canonical support truth.
- `test/crosswake/support_matrix/renderer_test.exs` — rendered support-guide parity.

### Route policy, privacy, and proof precedents

- `lib/crosswake/router.ex` — Phoenix route metadata and `crosswake_defaults` precedent.
- `lib/crosswake/policy/schema.ex` — closed route-policy input schema.
- `lib/crosswake/policy/route.ex` — normalized route contract.
- `guides/route_policy.md` — public route-owner vocabulary and fail-closed behavior.
- `guides/adoption.md` — current route-local offline-island recipe and replay vocabulary.
- `test/crosswake/planning/first_adopter_context_test.exs` — current discoverability, naming, and
  prohibited-information checks.

### Project design DNA

- `prompts/crosswake-research-synthesis.md` — stable route-policy/runtime-boundary conclusions from
  the prompt lineage.
- `prompts/crosswake-elixir-oss-dna.md` — install truth, support honesty, proof lanes, docs, release,
  and solo-maintainer patterns.
- `prompts/ARCHITECTURE-CODE-WALKTHROUGH-DNA.md` — ownership-first documentation and conceptual
  spine.
- `brandbook/BRAND-SPEC.md` — ratified brand and voice authority; supersedes
  `prompts/crosswake-brand-book.md`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Crosswake.Router` and `crosswake_defaults`: existing layered Phoenix route metadata pattern;
  useful as the conceptual precedent for family defaults plus concrete route overrides.
- `Crosswake.Policy.Schema` and `Crosswake.Policy.Route`: existing closed-schema and normalization
  posture; inventory validation should mirror their explicitness without becoming runtime policy.
- `Crosswake.CapabilityMap` plus its renderer: canonical-source/generated-guide pattern for
  adoption implications and compatibility normalization.
- `Crosswake.SupportMatrix` plus its renderer: canonical public support truth already contains the
  iOS-first, Android-frozen, scoped-replay, pack, and physical-device distinctions.
- `Crosswake.Planning.FirstAdopterContextTest`: existing browser-free privacy/discoverability
  guard that can be refactored around a centralized routing matrix and synthetic canary.

### Established Patterns

- Canonical Elixir source renders public Markdown; generated guides are checked for byte parity.
- Explicit denials and `verification_required` are preferred over silent fallback or optimistic
  promotion.
- Host-owned, fast-changing, or domain-specific facts stay outside Crosswake core.
- Curated manifests/path lists are normal in this repository, but they need non-vacuous drift
  checks because unregistered files otherwise escape protection.
- Hermetic deterministic checks are merge-blocking; device/provider/secret-dependent evidence is
  advisory or privileged and must state its limitation.
- The working tree contains a pre-existing `.planning/config.json` modification that this phase
  must preserve untouched.

### Integration Points

- Extend the route-policy map with status semantics, layered row rules, allowed/forbidden fields,
  and explicit outstanding sanitized input.
- Migrate capability-map row vocabulary and renderer normalization while regenerating the public
  guide.
- Centralize first-adopter path classification and update privacy/discoverability tests.
- Reconcile v20 stopped/partial truth, Phase 158 planning artifacts, active milestone docs, and
  public guides together.
- Keep TODO-002 and STATE blockers accurate until concrete sanitized route rows are supplied.

</code_context>

<specifics>
## Specific Ideas

- Treat `unknown_blocking` as useful product truth, not an incomplete blank to be worked around.
- Use a Phoenix-like layered model: safe defaults reduce repetition, concrete routes retain
  authority.
- Make privacy errors say, for example, “`privacy.private_term` failed in
  `.planning/...`; replace the value with an opaque reference,” never repeat the matched term.
- Use size bands and codec families in durable planning; exact size/hash values appear only at host
  integration time.
- Preserve the brand's “Declare the crossing. Keep the boundary honest.” posture through plain
  operational wording rather than visual or taxonomy expansion.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 158. Credential-scanner services, generic machine-readable
inventory frameworks, dashboards, and product UI remain outside this phase.

</deferred>

---

*Phase: 158-adoption-reset-and-route-map*
*Context gathered: 2026-07-30*
