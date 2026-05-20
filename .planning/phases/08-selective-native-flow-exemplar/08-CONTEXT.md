# Phase 8: Selective Native Flow Exemplar - Context

**Gathered:** 2026-05-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 8 proves the `Selective Native Flow` adopter lane inside the shared example host. It must show a mostly Phoenix-owned product shape where one narrow route becomes explicitly `:native_screen`, while surrounding routes stay manifest-driven Phoenix routes. The exemplar must use declared pack, transfer, and capability seams, keep native ownership fail-closed, and make any contract gaps explicit instead of widening Crosswake into a broader capability or entitlement platform.

This phase does not widen into billing or entitlement systems, multiple native-screen families, OCR or scanner-specific capability expansion, generic upload fallback behavior, background upload guarantees, offline draft claims, or starter-app breadth.

</domain>

<decisions>
## Implementation Decisions

### Product slice
- **D-01:** The selective-native exemplar should be a claims-evidence capture lane, not a billing/paywall lane, scanner lane, receipt/OCR lane, or generic media-upload demo.
- **D-02:** The lane should feel like a believable mobile companion flow where Phoenix owns the queue, detail, and review surfaces, and one native route owns the device-heavy capture step.
- **D-03:** The claims domain is chosen because it pressures the exact seams Crosswake wants to harden in Phase 8: one explicit `:native_screen`, route-local pack readiness, route-local transfer preparation, sensitive-route truth, and fail-closed activation.
- **D-04:** Keep the domain generic and fixture-light. Do not pull the lane toward insurance, healthcare, finance-policy, or vendor-specific compliance semantics.

### Route map and lane structure
- **D-05:** The lane should use four routes under a dedicated `/native` scope:
  - `/native/claims`
  - `/native/claims/:id`
  - `/native/claims/:id/capture`
  - `/native/submissions/:id/review`
- **D-06:** Exactly one route in the lane is `:native_screen`: `/native/claims/:id/capture`.
- **D-07:** The surrounding routes stay Phoenix-owned `:live_view` routes. No second native route, no hidden native fallback, and no generic top-level `/camera` demo route as the public exemplar shape.
- **D-08:** Use nested capture (`/native/claims/:id/capture`) instead of a flat `/native/capture` route so the ownership boundary stays explicit in the URL and does not depend on hidden app state.
- **D-09:** The module and router shape should mirror the existing SaaS lane pattern with a dedicated `CrosswakeExample.SelectiveNative.*` namespace and its own `live_session :selective_native`.

### Pack posture and activation gating
- **D-10:** Use context-dependent pack gating. Only the native capture route should require a pack gate; surrounding Phoenix routes should remain usable without that pack being installed.
- **D-11:** The capture route should declare a route-local required pack and fail closed when the pack is unavailable or incompatible.
- **D-12:** The primary degraded-path vocabulary for this lane is `pack_incompatible`.
- **D-13:** The exemplar must prove both pack-ready and pack-blocked capture activation paths in docs and proof lanes.
- **D-14:** Do not make the whole lane pack-gated, and do not downplay packs enough that Phase 8 stops pressuring `NATIVE-02`.

### Native handoff and submission shape
- **D-15:** The native route should return one staged local artifact to Phoenix, not a multi-artifact draft set, metadata bundle contract, or immediate server submission.
- **D-16:** The intended flow is: Phoenix claim detail -> native capture -> Phoenix review -> explicit `transfer.upload.prepare`.
- **D-17:** `captured locally`, `staged`, `uploaded`, and `reviewed/submitted` are distinct states and must stay visibly distinct in docs, fixtures, and proof.
- **D-18:** Phoenix owns review, submission intent, and any metadata edits. Native owns only the capture step and local staging needed for the explicit handoff.
- **D-19:** Do not imply background upload completion, resumable transfer guarantees, or app-local draft workflows in this phase.

### Security, sensitivity, and review posture
- **D-20:** The lane should use a narrow sensitive corridor rather than marking the entire `/native` lane sensitive.
- **D-21:** Ordinary surrounding routes such as `/native/claims` and `/native/claims/:id` should stay `security: :standard`.
- **D-22:** The native capture route and the immediate review route should be `security: :sensitive`.
- **D-23:** Review must happen before `transfer.upload.prepare`. No auto-upload and no upload-before-review shortcut.
- **D-24:** User-facing posture should stay plain and explicit: captured media is local to the device until the user reviews and confirms upload.
- **D-25:** Failures should stay route-local and fail-closed. Do not broaden the lane into a generic permission or media broker.

### Phoenix and ecosystem idiomaticity
- **D-26:** Keep the Phoenix-owned parts idiomatic: router scope + `live_session`, small bounded fixtures, LiveView list/detail/review surfaces, and Ecto-backed claim/submission state.
- **D-27:** Keep the native-owned part idiomatic to the existing Crosswake substrate: one manifest-declared `:native_screen`, one route-local pack requirement, one explicit transfer seam, one stable denial vocabulary.
- **D-28:** Learn from Hotwire Native’s discipline: most screens remain web-owned, native screens get explicit route ownership, and the bridge does not become a generic workflow bus.
- **D-29:** Learn from Expo/Capacitor and platform-native capture APIs that local media selection/capture should yield local artifacts first, not imply automatic upload or entitlement success.
- **D-30:** Keep DX explicit and unsurprising. Example-host code should read like a clean Phoenix slice plus one disciplined native seam, not like a framework demo or plugin showcase.

### Tradeoffs accepted
- **D-31:** Accept a narrower single-artifact flow because it keeps the selective-native story crisp and avoids Phase 9-style offline draft semantics.
- **D-32:** Accept that the capture route pressures pack readiness and fail-closed activation more than broad media lifecycle realism.
- **D-33:** Accept that the lane proves one canonical selective-native posture rather than multiple alternative native patterns in the same phase.

### Decision delegation posture
- **D-34:** Shift normal implementation decisions left within GSD for this phase. Downstream agents should not re-ask about the product slice, route map, pack posture, single-artifact handoff, or sensitive-corridor review flow unless a proposal would materially change the Phase 8 pressure target.

### the agent's Discretion
- Exact fixture names, sample claim nouns, and seeded copy, as long as the domain stays generic and claims/evidence-oriented.
- Exact route ids and module boundaries beneath `CrosswakeExample.SelectiveNative.*`, as long as there is exactly one `:native_screen` route and the four-route lane shape stays intact.
- Exact pack identifier and staged-artifact metadata fields, as long as the capture route alone owns the pack gate and explicit `transfer.upload.prepare` handoff.
- Exact proof assertions, docs structure, and UI copy, as long as `pack_incompatible`, staged-before-upload truth, and the fail-closed native boundary stay explicit.

</decisions>

<specifics>
## Specific Ideas

- The lane should read as “capture evidence for a claim from a Phoenix-owned workflow,” not “here is a generic camera demo.”
- The strongest URL shape is nested capture: `/native/claims/:id/capture`.
- The user-facing mental model should be simple: open claim, capture locally, review in Phoenix, then explicitly upload.
- `pack_incompatible` should feel like a route-local truth about the capture step, not a global app readiness mode.
- The example should show that a native screen can be first-class without turning the rest of the app into a native container or plugin bus.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Core planning context
- `.planning/PROJECT.md` — project thesis, milestone goal, and explicit no-wrapper / no-magic boundaries
- `.planning/REQUIREMENTS.md` — `NATIVE-01`, `NATIVE-02`, and surrounding v2 scope boundaries
- `.planning/ROADMAP.md` — Phase 8 goal and success criteria
- `.planning/STATE.md` — current milestone position and selective-native cautions

### Prior phase decisions
- `.planning/phases/05-packs-native-escape-and-proof-lanes/05-RESEARCH.md` — pack lifecycle, native capture, transfer seams, and proof-lane constraints
- `.planning/phases/05-packs-native-escape-and-proof-lanes/05-UI-SPEC.md` — native capture, pack, transfer, and proof-surface UX contract
- `.planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md` — locked meaning of the selective-native profile and milestone non-goals
- `.planning/phases/07-phoenix-saas-portal-exemplar/07-CONTEXT.md` — shared example-host lane pattern and proof-truth posture to preserve

### Current public artifact surfaces
- `guides/adopter_profiles.md` — current selective-native profile framing, representative routes, and non-goals
- `guides/packs.md` — required-pack contract, transfer states, and native-capture handoff contract
- `guides/native_shell.md` — manifest-first activation, fail-closed shell posture, and native capture boundary
- `guides/bridge.md` — bounded bridge vocabulary and explicit `transfer.upload.prepare` semantics
- `guides/support_matrix.md` — canonical support-status surface that Phase 8 docs must complement rather than duplicate
- `guides/install.md` — public proof-entry surface and example-host posture

### Example-host and proof anchors
- `examples/phoenix_host/README.md` — shared host rules and selective-native route-budget contract
- `examples/phoenix_host/lib/crosswake_example/router.ex` — current shared host topology and existing native-capture substrate
- `script/verify_adopter_profile_contract.sh` — current adopter-profile contract verification scaffold
- `script/verify_phase5_example_hosts.sh` — base checked-in example-host proof entrypoint to extend
- `test/crosswake/proof/phase5_proof_lane_test.exs` — current example-host proof shape and manifest assertions

### Prompt lineage and architecture guidance
- `prompts/crosswake-gsd-project-brief.md` — authoritative route-policy and capability-ladder framing
- `prompts/crosswake-research-synthesis.md` — stable architecture thesis and anti-patterns
- `prompts/crosswake-brand-book.md` — terminology and anti-wrapper messaging guardrails
- `prompts/crosswake-elixir-oss-dna.md` — OSS house style, support honesty, and proof-first posture
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — app-archetype pressure lessons for native-screen ownership
- `prompts/elixir-mobile-apptypes-design-stresstest-deep-research.md` — runtime-mode stress-test guidance and design tradeoffs

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `examples/phoenix_host/lib/crosswake_example/router.ex` already contains one native-capture route, route-local packs, and explicit transfer seams that Phase 8 should reuse rather than reinvent.
- The `CrosswakeExample.SaaSPortal.*` lane shows the desired shared-host structure for a bounded exemplar namespace with its own Phoenix-owned route group.
- `guides/packs.md` and `guides/native_shell.md` already publish the exact staged-versus-transferred and fail-closed vocabulary this lane should extend.
- `script/verify_phase5_example_hosts.sh` and `test/crosswake/proof/phase5_proof_lane_test.exs` already define the expected proof style: checked-in example hosts first, generated hosts second.

### Established Patterns
- Shared example hosts are the public proof artifact class.
- Route-local contracts are preferred over generic media, plugin, or bridge authority.
- Native capture is already treated as a true `:native_screen`, not a web-container fallback.
- Support claims and degraded behavior stay explicit and proof-backed.

### Integration Points
- Phase 8 should add a new `CrosswakeExample.SelectiveNative.*` lane beside the existing SaaS lane inside the shared Phoenix host.
- The capture route should integrate with the existing pack and transfer substrate, but become lane-scoped and product-shaped instead of remaining a generic `/camera` demo.
- Proof should add lane-specific assertions for exactly one `:native_screen` route, route-local pack gating, and staged-before-upload semantics.
- Docs should update the selective-native profile and example-host lane contract so the nested claims-evidence route map becomes canonical.

</code_context>

<deferred>
## Deferred Ideas

- Billing or paywall native routes, StoreKit/Play Billing, receipt verification, and entitlement sync
- Barcode/NFC scanner flows, fraud-sensitive check-in semantics, or scanner-specific capability expansion
- OCR, receipt parsing, document scanning, or richer media-processing features
- Multi-artifact draft sets, app-local offline draft workflows, or Phase 9-style reconciliation semantics
- Background upload guarantees, resumable transfers, or generic app-wide media-transfer management
- Multiple native-screen families inside the same exemplar lane

</deferred>

---

*Phase: 08-selective-native-flow-exemplar*
*Context gathered: 2026-05-18*
