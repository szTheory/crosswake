# Phase 71: Notification-Driven Workflow Proof - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove a production-shaped notification re-entry workflow over the real Chimeway, RouteGate, and Sigra contracts: a simulated notification tap produces semantic Chimeway open evidence for a manifest-known route/action, the backend-owned open-intent state is checked, and RouteGate enforces route policy plus Sigra recent-auth requirements before activation.

This phase is an archetype proof lane, not a push delivery platform, not a notification center, not a generic action registry, and not a new native/APNs/FCM proof. The merge-blocking output should be deterministic and CI-hermetic while showing that NOTF-01 and NOTF-02 hold: notification re-entry connects cleanly to token/session state, and unauthenticated or stale-auth notification taps fail closed without route bypass or silent dashboard fallback.

</domain>

<decisions>
## Implementation Decisions

### Proof Lane Architecture
- **D-01:** Build the primary merge-blocking proof as a targeted hermetic ExUnit lane, likely `test/crosswake/proof/phase71_notification_workflow_proof_test.exs`.
- **D-02:** The primary proof should use an inline manifest plus an inline stateful `IntentConsumer` test double that models issued, consumed, expired, replayed, revoked-binding, binding-mismatch, route-mismatch, and action-mismatch states. This keeps the lane fast, deterministic, and independent of Endpoint/Repo/PubSub/APNs/FCM/device state.
- **D-03:** Use the example-host Ecto Chimeway registry as implementation precedent and optional supporting/advisory evidence, not as the merge gate's only spine. Phase 63 already proves the slower example-host path; Phase 71 should prove the route-policy/auth workflow more adversarially.
- **D-04:** Do not introduce a new `NotificationWorkflow`, generic notification action registry, plugin bus, or reusable app-facing abstraction in Phase 71. Let archetype pressure expose gaps first.
- **D-05:** Add a targeted CI workflow, likely `.github/workflows/phase71-proof.yml`, shaped like prior phase proof lanes: pinned actions, `permissions: contents: read`, compile with warnings as errors, and a named merge-blocking job for the phase 71 proof. Native/device/APNs/FCM proof remains advisory only.

### Notification Re-Entry Spine
- **D-06:** Model the workflow as: token/binding context -> one-time Chimeway open intent -> `NotificationOpenEvidence` -> `Crosswake.Companions.Chimeway.Resolver.resolve/3` -> `RouteGate.evaluate/4` with `activation_source: :notification` and backend-projected Sigra `AuthContext`.
- **D-07:** Notification payload possession is evidence only. It must never grant route activation, session authority, auth freshness, subject authority, or mutation authority.
- **D-08:** Keep `notification_open` route-local and manifest-backed. The proof route should declare an explicit action allowlist, for example `notification_open: [actions: ["tap", "approve"]]`, rather than relying on a broad notification action registry.
- **D-09:** Use a SaaS notification workflow shape, such as an approval/task route, because it fits the v4.1 archetype lane and stresses auth-sensitive re-entry without widening into admin Phase 73. The target route should be `entry: :external`, notification-open enabled, and guarded by Sigra auth predicates.
- **D-10:** Use real Chimeway resolver, RouteGate, and Sigra contract/evaluator modules in the proof. Mock only the outside edge that would otherwise require backend storage or provider/device infrastructure.

### Sigra And RouteGate Authority
- **D-11:** Use backend-projected `Crosswake.Companions.Sigra.Contracts.AuthContext` values in tests. Do not treat `NotificationOpenEvidence.auth_context` as trusted payload data just because the struct currently accepts a broad value.
- **D-12:** The route should require meaningful auth posture, e.g. `auth_min_level: :mfa`, `requires_recent_auth: 300`, and strict/recent posture where supported by existing route types.
- **D-13:** Stale, missing, weak, revoked, cached, remembered, or version-mismatched auth must pass through as `:step_up_required` denials from RouteGate/Sigra. Do not wrap or translate those denials into Chimeway-only vocabulary.
- **D-14:** Phase 71 should prove step-up denial and fresh-auth allow behavior, but it should not implement a full step-up continuation flow unless the planner explicitly designs how Chimeway open intents survive or resume after auth challenge. Current registry behavior consumes the open intent before route auth succeeds, so a full continuation flow has double-consume risk and belongs in a later phase or a clearly scoped fix.
- **D-15:** Denied notification activation should halt. It must not redirect to dashboard/home or use a silent fallback that hides the denial. If a fallback route exists in a fixture, the phase should prove notification-source denials do not become bypasses.

### Adversarial Denial Matrix
- **D-16:** Positive proof cases: valid manifest route, allowed notification action, valid one-time intent, active binding, fresh backend Sigra auth -> `{:allow, decision}` and `decision.transition == :activate`.
- **D-17:** Auth denial cases: missing auth context -> `auth.step_up.missing_context`; stale recent auth -> `auth.step_up.stale_auth`; insufficient assurance -> `auth.step_up.insufficient_assurance`; revoked authority lane -> `auth.step_up.revoked`; remembered/cached authority on strict routes -> the existing Sigra denial vocabulary.
- **D-18:** Chimeway/open-intent denial cases: expired intent, replayed intent, revoked/non-active binding, binding mismatch, route mismatch, unknown route, notification-open disabled/missing, unsupported action, and action mismatch.
- **D-19:** Phase 71 should expose and fix or explicitly plan around two current gaps: the registry returns `:revoked` while public denial vocabulary includes `notification.open.binding_revoked`, and registry validation appears to check binding/route but not `intent.action_ref == evidence.action_ref`. The proof should lock the intended stable behavior.
- **D-20:** Redaction proof must include hostile metadata such as raw token keys, raw payload, notification title/body, route params, actor/session refs, device IDs, email, IP, and user agent. Denial details, telemetry metadata, support truth, and proof output must not leak them.
- **D-21:** The proof must not assert APNs/FCM delivery, tray display, Focus/Doze/background behavior, push metrics, read receipts, provider credentials, or real-device opens. It proves route activation semantics after a simulated notification-open evidence event.

### DX, Operator Truth, And UI Posture
- **D-22:** Keep the main deliverable proof-first. Add docs/support/operator updates only where the proof changes public truth or prevents adopter confusion.
- **D-23:** Support truth should say "notification-open workflow proof is hermetic route activation proof", not delivery proof. Preserve `delivery_supported: false` / provider-device advisory language.
- **D-24:** Guidance should clarify Chimeway + Sigra interplay: notification token/open evidence is not auth authority; token binding and one-time intent records are backend-owned; RouteGate and Sigra decide activation.
- **D-25:** If an example-host UI route is touched, keep it small: a compact Phoenix-owned proof/status panel on the target workflow route or queue, not a notification center, delivery dashboard, or native tray simulation.
- **D-26:** UI, if touched, should use existing Phoenix/LiveView defaults, semantic headings, real buttons/links, visible focus states, system light/dark behavior, and a polite `role="status"` region for state changes. Do not add a theme switcher or component library.
- **D-27:** Preferred microcopy: "Notification open resolved through RouteGate", "Recent authentication required before opening this route", "Open intent expired. No route was activated", "Binding revoked. Notification open denied", "APNs/FCM delivery is not part of this proof", and "Token evidence is bound by the backend; possession does not grant access".
- **D-28:** Avoid copy such as "push delivered", "notification guaranteed", "opened from APNs/FCM", "user authenticated by notification", or "real-time push workflow".

### The Agent's Discretion
- Exact helper/module names for the inline stateful intent consumer, fixture builders, route IDs, action refs, and auth-context builders, as long as the proof remains hermetic and uses real Chimeway/RouteGate/Sigra contract paths.
- Whether to add a narrow example-host proof/status surface or keep Phase 71 entirely proof/docs/operator focused, as long as no full endpoint/LiveView/native delivery surface is introduced.
- Exact workflow job names and whether phase 63 regression tests are referenced as context, as long as the phase 71 proof file is the named merge-blocking signal.
- Exact stable denial-code spelling for revoked binding/action mismatch, as long as public denial vocabulary is canonical, support-safe, and parity-locked.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone posture
- `.planning/PROJECT.md` - Crosswake thesis, v4.1 milestone posture, backend-owned authority, and notification non-claims.
- `.planning/REQUIREMENTS.md` - NOTF-01, NOTF-02, and PROOF-01 traceability.
- `.planning/ROADMAP.md` - Phase 71 goal, dependency on Phase 70, and success criteria.
- `.planning/STATE.md` - current v4.1 position and pending todo about Phase 71 route policies mapping Chimeway payloads to Sigra state.
- `.planning/MILESTONE-ARC.md` - v4.1 archetype-proof goal, hermetic proof posture, and non-goals for starter apps/new abstractions.
- `.planning/phases/70-subscription-saas-commerce-proof/70-CONTEXT.md` - immediately-prior archetype proof pattern: integrated product-shaped proof, backend authority, adversarial negatives, and hermetic CI.

### Chimeway notification-open contracts
- `lib/crosswake/companions/chimeway/contracts.ex` - `NotificationOpenEvidence`, `OpenResolution`, token/binding contracts, validation style, and forbidden token keys.
- `lib/crosswake/companions/chimeway/resolver.ex` - resolver path from notification-open evidence to manifest policy and RouteGate.
- `lib/crosswake/companions/chimeway/denial_codes.ex` - canonical notification-open denial vocabulary.
- `lib/crosswake/companions/chimeway/redaction.ex` - redaction and public-token filtering precedent.
- `lib/crosswake/companions/chimeway/telemetry.ex` - low-cardinality notification telemetry and forbidden metadata posture.
- `lib/crosswake/companions/chimeway/intent_consumer.ex` - behaviour seam the inline/stateful test consumer should satisfy.

### Route policy, manifest, and auth authority
- `lib/crosswake/compatibility/route_gate.ex` - activation-source handling, fail-closed transition behavior, and Sigra delegation.
- `lib/crosswake/companions/sigra/evaluator.ex` - backend-owned route-auth evaluation and `:step_up_required` denial pass-through.
- `lib/crosswake/companions/sigra/contracts.ex` - `AuthContext` and `SessionAuthorityLane` constructors/validation for proof fixtures.
- `lib/crosswake/companions/sigra/denial_codes.ex` - canonical sanitized Sigra denial details.
- `lib/crosswake/policy/schema.ex` - `notification_open` declaration shape and action validation.
- `lib/crosswake/manifest/types.ex` - route entry serialization and `notification_open` manifest truth.
- `lib/crosswake/shell/denial.ex` - canonical denial reasons and support-safe denial serialization.

### Example-host precedent
- `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex` - Ecto-backed token binding and notification-open intent lifecycle precedent.
- `examples/phoenix_host/lib/crosswake_example/chimeway/notification_open_intent.ex` - one-time open intent schema and state vocabulary.
- `examples/phoenix_host/lib/crosswake_example/chimeway/notification_open_intent_event.ex` - audit-event precedent, with no durable audit overclaim in Phase 71.
- `examples/phoenix_host/lib/crosswake_example/chimeway/token_binding.ex` - backend-owned token binding projection.
- `examples/phoenix_host/lib/crosswake_example/chimeway/metadata_sanitizer.ex` - example-host metadata allowlist.
- `examples/phoenix_host/README.md` - optional Chimeway background job scope and host-owned worker posture.

### Existing tests and proof lanes
- `test/crosswake/proof/phase63_notification_seam_proof_test.exs` - prior Chimeway seam proof and example-host script harness; use as precedent, not the whole Phase 71 proof.
- `test/crosswake/companions/chimeway/resolver_test.exs` - resolver unit coverage and denial behavior.
- `examples/phoenix_host/test/crosswake_example/chimeway/registry_notification_open_test.exs` - registry open-intent lifecycle coverage.
- `test/crosswake/compatibility/compatibility_test.exs` - notification activation denial and RouteGate compatibility behavior.
- `test/crosswake/compatibility/route_gate_test.exs` - Sigra delegation, kill-switch precedence, and route auth gate behavior.
- `test/crosswake/proof/phase46_sigra_auth_contract_test.exs` - Sigra route-auth proof precedent.
- `test/support/proof_assertions.ex` - fixture and exact-doc assertion helpers.

### Support, docs, and operator truth
- `guides/support_matrix.md` - notification surface support/non-claims and proof posture.
- `guides/companions.md` - Chimeway and Sigra companion guide truth.
- `guides/user_flows.md` - user-flow language for notification-driven re-entry.
- `lib/crosswake/support_matrix/support_matrix.ex` - canonical notification support truth accessor/data shape.
- `lib/crosswake/operator_inspection.ex` - route/operator truth surface for `notification_open` posture.
- `lib/crosswake/doctor/doctor.ex` and `lib/mix/tasks/crosswake.doctor.ex` - doctor readiness posture if Phase 71 exposes proof truth.

### Prompt corpus and project vision
- `prompts/crosswake-elixir-oss-dna.md` - install truth, public contract honesty, proof lanes, and Phoenix-native operator surfaces.
- `prompts/crosswake-brand-book.md` - boundary-aware brand voice, anti-hype, no magic/offline/delivery overclaims.
- `prompts/crosswake-integrations-and-companions.md` - Chimeway/Sigra companion positioning and persona/JTBD fit.
- `prompts/crosswake-research-synthesis.md` - route policy/runtime-boundary thesis and anti-patterns.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` - SaaS/customer portal fit, notification/deep-link route policy, sensitive-route auth footguns.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` - Hotwire Native path-configuration lessons, push-token/deep-link adapter shape, and no direct mutation by deep link without server confirmation.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Companions.Chimeway.Resolver.resolve/3` - already checks manifest route existence, `notification_open`, action allowlist, intent consumption, then delegates to RouteGate.
- `Crosswake.Companions.Chimeway.Contracts.NotificationOpenEvidence` - the typed evidence object used to simulate a notification tap without raw APNs/FCM payloads.
- `Crosswake.Companions.Chimeway.Contracts.OpenResolution` - the state object an inline intent consumer can return hermetically.
- `Crosswake.Companions.Chimeway.IntentConsumer` - the behaviour seam for a test consumer or host-owned backend consumer.
- `Crosswake.Compatibility.RouteGate.evaluate/4` - activation decision and transition source of truth.
- `Crosswake.Companions.Sigra.Contracts` and `Evaluator` - backend-owned auth-context construction and route-auth denial/allow behavior.
- `CrosswakeExample.Chimeway.Registry` - example-host Ecto lifecycle precedent for token binding/open-intent issue/consume, useful for implementation guidance and optional supporting tests.

### Established Patterns
- Archetype proof lanes are product-shaped, adversarial, and hermetic; provider/device/native lanes stay advisory until promotion criteria pass.
- Client/native/provider evidence is never authority. Backend-owned projections, bindings, intents, and route gates decide sensitive outcomes.
- Denial vocabularies are stable, typed, support-safe, and parity-locked across docs/support/operator surfaces.
- Optional host/Ecto state belongs in the example host or adopter app, not core Crosswake.
- Support truth and docs must distinguish notification-open routing from APNs/FCM delivery.

### Integration Points
- New proof file under `test/crosswake/proof/phase71_notification_workflow_proof_test.exs`.
- Possible narrow fixes in `lib/crosswake/companions/chimeway/resolver.ex`, `lib/crosswake/companions/chimeway/contracts.ex`, and `lib/crosswake/companions/chimeway/denial_codes.ex` if action mismatch or revoked-binding vocabulary gaps are confirmed.
- Possible example-host registry adjustment in `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex` if the plan chooses to lock action-ref matching in the real registry path.
- Possible support/docs parity updates in `guides/support_matrix.md`, `guides/companions.md`, `guides/user_flows.md`, `lib/crosswake/support_matrix/support_matrix.ex`, and operator/doctor surfaces.
- New targeted CI workflow `.github/workflows/phase71-proof.yml`.

</code_context>

<specifics>
## Specific Ideas

- Preferred proof story: simulated notification tap for a SaaS approval/task route -> `NotificationOpenEvidence` -> inline stateful intent consumer returns valid open resolution -> RouteGate receives `activation_source: :notification` -> missing/stale/weak auth halts with `:step_up_required` -> fresh backend Sigra auth activates.
- Preferred denial matrix includes: missing auth, stale auth, insufficient assurance, revoked session lane, expired intent, replayed intent, revoked binding, binding mismatch, route mismatch, unknown route, notification disabled, unsupported action, action mismatch, fallback bypass, raw payload leakage, and provider/device overclaim guard.
- Preferred microcopy if UI/docs are touched: "Notification open resolved through RouteGate", "Recent authentication required before opening this route", "Open intent expired. No route was activated", "Binding revoked. Notification open denied", "APNs/FCM delivery is not part of this proof", "Token evidence is bound by the backend; possession does not grant access".

</specifics>

<deferred>
## Deferred Ideas

- Full Sigra step-up continuation after notification-open denial, including preserving/resuming a Chimeway open intent through the auth ceremony. Valuable, but needs explicit lifecycle design to avoid double-consume or lost continuation.
- Real APNs/FCM delivery, provider credentials, tray display behavior, Focus/Doze/background delivery behavior, push metrics, and read receipts. These remain advisory/device/provider proof, not Phase 71 merge-blocking scope.
- Full Phoenix endpoint/Plug/LiveView E2E proof. Useful later if a UI route becomes public product surface, but too slow and broad for the Phase 71 merge gate.
- Notification center, in-app inbox, generic notification action registry, topic APIs, delivery dashboard, or native notification UI presentation.
- Durable audit capstone for notification-open decisions. Threadline-style audit belongs in the later audit capstone, not this phase.

</deferred>

---

*Phase: 71-notification-driven-workflow-proof*
*Context gathered: 2026-06-04*
