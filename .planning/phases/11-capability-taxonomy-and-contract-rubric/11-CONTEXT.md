# Phase 11: Capability Taxonomy And Contract Rubric - Context

**Gathered:** 2026-05-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Define the capability-family taxonomy, route-owner decision rubric, and manifest/support metadata Crosswake needs before broader capability delivery. This phase classifies and documents future capability surfaces; it does not widen the shipped capability catalog, add store-provider commerce adapters, or weaken route-local ownership boundaries.

</domain>

<decisions>
## Implementation Decisions

### Taxonomy shape
- **D-01:** Crosswake capability taxonomy is family-first and route-owner-aware. Public capability ids should name stable semantic families such as `haptics`, `share`, `app_info`, `deep_link`, `permissions.status`, `notification_token`, `media_capture`, `scanner`, `document_scan`, `paywall`, `purchase`, `restore`, and `entitlement_snapshot`, not generic plugin buckets or raw bridge command ids.
- **D-02:** Bridge commands remain operation-level protocol details under a family, not the primary public taxonomy. Example: `haptics` is the family; `haptics.impact` is a command.
- **D-03:** Crosswake should not publish umbrella/plugin-shaped capability buckets such as `device`, `media`, `payments`, `bridge`, or `native`. Those names hide ownership differences and make support truth dishonest.
- **D-04:** The public classification model should stay separate across two axes:
  - capability family taxonomy
  - route-owner/package/support classification metadata
- **D-05:** Package classification remains distinct from runtime ownership. `core`, `companion`, `example/docs-only`, and `defer` describe packaging and support posture, not which runtime owns a route interaction.

### Ownership rubric
- **D-06:** Crosswake should use a ladder-first ownership rubric as the primary public rule. Start by asking who must own the interaction loop on the route, not by asking what API shape looks convenient.
- **D-07:** Classify a family as `bounded_bridge` only when the route remains Phoenix-owned and the native action is low-frequency, semantic, request/reply, and non-authoritative.
- **D-08:** Classify a family as `native_screen` when native code must own the interaction loop, permission choreography, capture/scan session, or platform-specific UI fidelity.
- **D-09:** Classify a family as `backend_seam` or `defer` when the surface is primarily control-plane, provider-coupled, background-heavy, review-sensitive, or would require Crosswake to pretend route-local bridge calls own backend truth.
- **D-10:** Use a capability-scoring checklist only as an internal maintainer backstop, not as the public-facing primary rubric. The public rule should stay simple and ownership-first.
- **D-11:** Use a native-risk veto layer for policy-heavy or sensitive families. If a family materially depends on storefront rules, auth/browser policy, background delivery, scanner/camera loops, or audit/regulatory posture, bias toward `native_screen`, `companion`, or `defer`.
- **D-12:** Deep-link handling remains manifest-first shell activation truth, not a generic JS/native bridge authority. Route-local deep-link metadata may exist, but link resolution belongs to shell activation.

### Classification rules for candidate families
- **D-13:** `haptics`, `share`, `app_info`, `permissions.status`, and `notification_token` are the model bounded-bridge families.
- **D-14:** `media_capture`, `scanner`, and `document_scan` are native-screen-first families because they imply session loops, frequent native state, and stronger device/policy variance.
- **D-15:** `rollout`, `auth`, `audit`, and notification delivery providers stay Phoenix/backend seams rather than route-local bridge authority. Crosswake may later support them through companions or docs, but not as core bridge-owned families.
- **D-16:** Commerce family names such as `paywall`, `purchase`, `restore`, and `entitlement_snapshot` are valid taxonomy entries, but their core seam and provider boundaries remain milestone work centered in Phase 13 rather than full public capability support in Phase 11.

### Manifest and support metadata
- **D-17:** Phase 11 should use a manifest-primary capability contract with generated support output. Route entries stay lean and route-local; capability-family truth lives on capability registry entries.
- **D-18:** Extend the manifest capability registry with typed metadata that answers:
  - expected route owner
  - package class
  - proof class
  - rebuild expectation
  - prerequisites
  - denial behavior
  - fallback behavior
  - guide boundary link
- **D-19:** Keep the current platform baseline support matrix intact. Add capability-family support rendering derived from manifest truth instead of turning the support matrix into a second competing source of truth.
- **D-20:** Denial posture stays fail-closed. Capability metadata must never imply silent WebView fallback, generic wrapper degradation, or runtime authority wider than the active route declaration.
- **D-21:** Rebuild truth must stay explicit and separate from generic support status. Any family that needs new binary/runtime code must declare rebuild expectations directly instead of hiding them behind broad support labels.
- **D-22:** Do not duplicate family metadata on every route. Routes declare capability ids; the registry owns family-level semantics and support truth.

### Public exemplar set
- **D-23:** Phase 11 should publish a narrow, exemplar-aligned public example set rather than a broad “mobile API catalog.”
- **D-24:** The first canonical `core` example families are `deep_link`, `app_info`, `haptics`, and `share`. These reinforce Phoenix-owned routes, manifest-first shell truth, and low-frequency typed bridge semantics without widening runtime authority.
- **D-25:** The first `companion`-leaning example families are `media_capture`, `notification_token`, `rollout`, and `audit`. These fit Crosswake but carry meaningful native, backend, operator, or release-boundary pressure and should not be marketed as lightweight core capabilities.
- **D-26:** The first `example/docs-only` families are `permissions.status`, `auth`, and pre-Phase-13 commerce examples. These are useful for classification guidance but are not part of the first canonical supported capability set.
- **D-27:** `scanner` and `document_scan` remain deferred in the first public example set because they imply heavier native ownership, policy burden, and support-matrix breadth than this phase can honestly support.

### Developer ergonomics and planning posture
- **D-28:** The public rules should optimize for least surprise to Phoenix teams: small semantic family names, router-local declarations, typed manifest structs, explicit denial behavior, and backend-owned truth for security-sensitive or provider-heavy surfaces.
- **D-29:** Crosswake should shift normal classification and metadata-detail choices left within GSD. Downstream researcher, planner, and implementer agents should make principled decisions without re-asking unless a choice materially changes the public taxonomy, ownership rubric, package class boundaries, support claims, or backend-truth posture.

### the agent's Discretion
- Exact field names for new capability metadata, as long as the concepts above remain explicit and typed.
- Exact scoring checklist dimensions and thresholds used internally by maintainers, as long as the public rule stays ownership-first.
- Exact rendered guide structure and table layout for capability-family support output, as long as it derives from manifest truth and does not become a second source of truth.
- Exact example copy, guide headings, and doc ordering, as long as the exemplar-aligned narrow posture remains intact.

</decisions>

<specifics>
## Specific Ideas

- The right mental model is not “Crosswake has plugins.” The right mental model is “Crosswake classifies capability families by who should own the route interaction.”
- `haptics` should remain the archetypal bounded-bridge family: one-shot, semantic, low-frequency, no authority shift.
- `media_capture` should remain the archetypal native-screen family: capture locally, keep session and permission choreography native, and hand back staged evidence instead of pretending upload or reconciliation already happened.
- `notification_token` should be treated as evidence only. Receiving a token is not equivalent to notifications being fully configured, delivered, or authorized end-to-end.
- `permissions.status` only stays honest as a read-only snapshot or point-of-need fact surface. It should not become a generic permission-orchestration broker.
- `share` is valuable because it proves user-intent handoff without implying generic file or plugin authority.
- Deep links should remain shell truth. They are part of manifest-first activation, not page-owned navigation authority.
- Package class and runtime ownership should never be collapsed into one term. A companion can still expose a native-screen-first family; package shape does not override route-owner truth.
- Crosswake should learn from Hotwire Native’s separation of web-owned routes, bounded bridge components, and explicit native screens; Expo’s explicit runtime-version/rebuild truth; Tauri’s fail-closed scoped capabilities; and Capacitor’s plugin-sprawl footguns to avoid.
- Public docs should feel like a disciplined contract guide, not a feature catalog.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and Requirements
- `.planning/PROJECT.md` — project thesis, v3.0 milestone framing, and non-goals that Phase 11 must preserve
- `.planning/REQUIREMENTS.md` — `CAPA-01`, `CAPA-02`, `CAPA-03`, packaging ledger context, proof posture gate, and support truth gate
- `.planning/ROADMAP.md` — Phase 11 goal, plan breakdown, and success criteria
- `.planning/STATE.md` — current milestone position and current concerns around capability breadth and support honesty

### Prior Locked Decisions
- `.planning/phases/01-route-policy-foundation/01-CONTEXT.md` — route-local policy declarations, explicit runtime taxonomy, and typed schema posture
- `.planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md` — route-first manifest truth, narrow support matrix posture, and fail-closed compatibility model
- `.planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md` — bounded bridge rules, denial posture, and native-screen escape hatch principles
- `.planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md` — exemplar lane vocabulary and shared proof-artifact posture
- `.planning/phases/07-phoenix-saas-portal-exemplar/07-CONTEXT.md` — Phoenix-owned SaaS lane and `haptics` exemplar
- `.planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md` — explicit `:native_screen` capture corridor and pack/transfer/sensitivity posture
- `.planning/phases/09-local-first-content-flow-exemplar/09-CONTEXT.md` — offline honesty and route-local authority distinctions

### Existing Contract Surfaces
- `guides/bridge.md` — current bounded bridge contract and denial vocabulary
- `guides/native_shell.md` — manifest-first shell activation, route unavailable posture, and native capture escape hatch
- `guides/support_matrix.md` — current narrow platform baseline support surface
- `guides/adopter_profiles.md` — current exemplar lane framing that public capability examples must stay coherent with

### Existing Code Truth
- `lib/crosswake/manifest/types.ex` — current manifest structs and the capability registry shape
- `lib/crosswake/manifest/builder.ex` — current capability registry generation and route-entry construction
- `lib/crosswake/manifest/validator.ex` — current validation posture and canonical typed checks
- `lib/crosswake/bridge/registry.ex` — current bridge allowlist and command-to-capability mapping
- `lib/crosswake/support_matrix/support_matrix.ex` — current narrow support matrix baseline rules
- `lib/crosswake/support_matrix/renderer.ex` — current generated support output shape
- `lib/crosswake/policy/schema.ex` — current route policy DSL and typed declaration boundaries

### Research and Design Inputs
- `prompts/crosswake-gsd-project-brief.md` — authoritative route-policy and capability-ladder framing
- `prompts/crosswake-elixir-oss-dna.md` — maintainer house style around install truth, support honesty, proof lanes, and package boundaries
- `prompts/crosswake-integrations-and-companions.md` — companion classification heuristics and candidate seam context
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — broader ecosystem tradeoffs around capability ladders, native screens, and plugin-sprawl risks

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Manifest.Types.Capability`: current typed capability registry entry that should carry family metadata instead of pushing it into routes
- `Crosswake.Manifest.Builder.capability_registry/1`: current registry-construction seam where a canonical capability-family catalog can be introduced
- `Crosswake.Manifest.Validator`: existing canonical validation pattern that should enforce new metadata vocabularies
- `Crosswake.Bridge.Registry`: existing command allowlist proving commands and families should stay separate concepts
- `Crosswake.SupportMatrix.Renderer`: existing generated-doc surface that can render capability-family truth from manifest metadata

### Established Patterns
- Route-local declarations remain lean and declarative; shared truth lives in typed structs and registries.
- Fail-closed validation is preferred over broad fallback behavior.
- Generated docs are derived from canonical typed state rather than maintained by hand.
- Support claims stay intentionally narrow and proof-backed.

### Integration Points
- Manifest capability structs and serialization
- Manifest builder capability registry generation
- Manifest validator vocabulary checks
- Support guide rendering for capability-family truth
- Future doctor/support/proof extensions in Phases 12-14

</code_context>

<deferred>
## Deferred Ideas

- Broad public capability catalogs or plugin-marketplace framing
- Storefront/provider-specific billing adapters before Phase 13 commerce seam work
- Broad scanner/document-scan support claims before package, rebuild, and proof posture mature
- Generic permission-broker workflows or app-global permission onboarding abstractions
- Notification delivery, rollout orchestration, auth, or audit as route-local bridge-owned capabilities

</deferred>

---

*Phase: 11-capability-taxonomy-and-contract-rubric*
*Context gathered: 2026-05-19*
