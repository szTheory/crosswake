# Phase 16: System Context Bridges (Deep Link, Permissions Status) - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 16 delivers the first Crosswake support for system-context capabilities that can be queried or resolved without handing the interaction loop to native code. In scope are manifest-first deep-link activation and a read-only `permissions.status` bridge. This phase does not add generic navigation authority, permission-request orchestration, or broad plugin-style system introspection.

</domain>

<decisions>
## Implementation Decisions

### Deep-link authority and activation model
- **D-01:** In Phase 16, `deep_link` remains inbound shell activation only. Universal links, app links, notifications, and app-entry URLs normalize into manifest-first activation before any runtime mounts.
- **D-02:** Phase 16 does **not** add an outbound `deep_link` bridge command or any route-local navigation authority. Outbound behavior stays ordinary Phoenix URL generation and shell/native platform linking outside the bounded bridge.
- **D-03:** Downstream planning should treat inbound deep-link handling as part of the shell activation contract, not the bridge contract. The bridge must not become a navigation bus.

### Deep-link declaration posture
- **D-04:** Deep-link entry must be explicitly declared in route policy metadata and derived into manifest truth. Deep-linkability is fail-closed by default, not ambient across every manifest route.
- **D-05:** The route policy should support scope defaults plus per-route overrides, but the underlying model stays explicit opt-in. Defaults must not silently widen sensitive or internal routes.
- **D-06:** Activation denials and diagnostics must distinguish between "route does not exist" and "route exists but is not approved for external entry." Support truth and doctor output should surface that difference explicitly.

### `permissions.status` scope
- **D-07:** The first shipped `permissions.status` contract stays narrow, read-only, and capability-keyed. It should cover only point-of-need permission facts that align to immediate Crosswake capability prerequisites and near-term proof/doctor work.
- **D-08:** Phase 16 must not expose a broad generic OS-permission snapshot surface, app-wide permission dashboard semantics, or permission-request orchestration. Request flows remain separate later-phase work.
- **D-09:** Any permission alias exposed publicly must be something Crosswake can name, document, diagnose, and fail closed around in route policy, support matrix, and doctor output.

### `permissions.status` reply shape
- **D-10:** The primary Phoenix-facing reply contract should use a small Crosswake-owned normalized status enum, with optional platform detail carried in a secondary field.
- **D-11:** Route logic and normal caller ergonomics should branch on the normalized primary status first. Platform-native facts such as limited scope, requestability, or native status labels may appear in `detail`, but `detail` must remain secondary.
- **D-12:** The public primary contract must not depend on platform-specific status strings or pretend to know richer blocked/requestability states than a read-only check can honestly guarantee on both iOS and Android.

### Decision delegation posture
- **D-13:** Shift normal implementation choices left within GSD for this phase. Researcher, planner, and implementer agents should make principled decisions without re-asking unless a choice materially changes public contract semantics, fail-closed behavior, support claims, security posture, or compatibility/versioning rules.

### the agent's Discretion
- Exact route-policy field naming for explicit deep-link entry metadata, as long as it reads as route-entry policy rather than bridge capability authority.
- Exact normalized status enum member names and optional detail field names, as long as the contract stays small, typed, and stable across platforms.
- Exact internal registry structure for mapping capability prerequisites to permission aliases, as long as the public `permissions.status` surface remains narrow and honest.
- Exact doctor copy, denial wording, and guide wording, as long as "inactive route" and "not approved for external entry" remain clearly distinct.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Core planning context
- `.planning/PROJECT.md` — project thesis, fail-closed posture, and explicit runtime-ownership constraints
- `.planning/REQUIREMENTS.md` — v3.1 support-truth and capability-boundary expectations
- `.planning/ROADMAP.md` — Phase 16 goal, plan split, and success criteria
- `.planning/STATE.md` — current milestone position and known capability-phase concerns
- `.planning/milestones/v3.1-CONTEXT.md` — milestone-wide framing for native capabilities, doctor posture, and fail-closed expectations

### Prior locked phase decisions
- `.planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md` — manifest-first activation, bounded bridge rules, denial posture, and shell authority boundaries
- `.planning/phases/11-capability-taxonomy-and-contract-rubric/11-CONTEXT.md` — capability-family taxonomy, `deep_link` shell-truth posture, and `permissions.status` read-only boundary
- `.planning/phases/14-proof-doctor-and-support-truth/14-CONTEXT.md` — doctor and support-matrix expectations for explicit prerequisites and denial behavior
- `.planning/phases/15-base-capability-bridges/15-CONTEXT.md` — command naming, allowlist posture, and fail-closed bridge conventions

### Prompt lineage and project research
- `prompts/crosswake-brand-book.md` — anti-drift product language and boundary constraints
- `prompts/crosswake-gsd-project-brief.md` — authoritative Phoenix-first route-policy framing and explicit runtime ladder
- `prompts/crosswake-elixir-oss-dna.md` — install truth, support-truth, proof-lane, and maintainer house-style expectations
- `prompts/crosswake-research-synthesis.md` — stable architecture story and anti-patterns
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — cross-ecosystem route/runtime/capability lessons
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` — three-plane system guidance, path/activation lessons, and bridge-boundary cautions
- `prompts/elixir-mobile-oss-lib-deep-research.md` — broader product-shape tradeoffs and successful ecosystem patterns

### Current contract and guide surfaces
- `guides/native_shell.md` — manifest-first activation, route-unavailable posture, and shell-boundary guidance
- `guides/bridge.md` — bounded bridge contract and explicit note that `deep_link` is not bridge authority
- `guides/capabilities.md` — capability-family framing, `permissions.status` read-only posture, and package/support classifications
- `guides/support_matrix.md` — current support posture for `deep_link`, `permissions.status`, and related capability families

### Current code anchors
- `lib/crosswake/shell/activation.ex` — canonical Elixir activation request/decision contract
- `examples/ios_shell_host/CrosswakeShell/ActivationCoordinator.swift` — iOS manifest-first activation and incoming URL normalization
- `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt` — Android manifest-first activation and deep-link handling
- `lib/crosswake/manifest/types.ex` — typed manifest/support structs and stable contract patterns
- `lib/crosswake/manifest/builder.ex` — capability catalog and support metadata source of truth
- `lib/crosswake/policy/validator.ex` — current route policy validation seam and capability vocabulary
- `lib/crosswake/support_matrix/support_matrix.ex` — canonical support truth structure
- `lib/crosswake/doctor/doctor.ex` — current doctor posture and shell/bridge verification structure
- `test/crosswake/shell/activation_test.exs` — current activation expectations and denial vocabulary
- `test/crosswake/bridge/registry_test.exs` — existing fail-closed command/registry expectations
- `examples/phoenix_host/lib/crosswake_example/router.ex` — current host route-policy shape and manifest-driven route declarations

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Shell.Activation`: already provides a typed Elixir activation request/decision contract with deep-link as a first-class activation source.
- iOS and Android `ActivationCoordinator`: already normalize incoming URLs into activation requests and enforce manifest-first route resolution.
- `Crosswake.Manifest.Builder.capability_catalog/0`: already carries family-level metadata for `deep_link` and `permissions.status`, making it the right seam for tightening support truth.
- `Crosswake.Policy.Validator`: already enforces route-policy invariants and is the natural place to validate explicit deep-link entry metadata.
- `Crosswake.Doctor` and `Crosswake.SupportMatrix`: already expose support posture and denial vocabulary, and should be extended rather than bypassed.

### Established Patterns
- Manifest truth is shared, typed, and preferred over shell-local ad hoc configuration.
- Bridge commands are deliberately low-frequency, semantic, and versioned; navigation authority is kept outside the bridge.
- Route-local declarations remain explicit and fail closed by default.
- Support claims stay narrow and proof-backed, with doctor guidance treated as product surface.

### Integration Points
- Route-policy DSL and manifest serialization need a new explicit entry-policy seam for deep-link-approved routes.
- Shell activation logic on both platforms needs to consume route-entry policy and return more precise denial reasons.
- `permissions.status` needs typed bridge command/response structs, native-shell query implementations, registry wiring, and doctor/support-matrix updates that stay aligned with capability prerequisites.
- Example host routes and proof tests should exercise both positive and denied deep-link entry and narrow permission-status queries.

</code_context>

<specifics>
## Specific Ideas

- Hotwire Native path configuration is the best positive model for explicit entry policy and native-owned activation; copy the discipline, not the Rails-specific shape.
- Tauri capability scoping is the best adjacent lesson for default-deny authority boundaries; deep-link entry should feel like scoped authority, not ambient reachability.
- Expo and `react-native-permissions` provide a useful permissions abstraction lesson: normalize the primary answer, keep richer platform facts in secondary fields.
- User preference for this phase: optimize for cohesive, least-surprise recommendations and strong DX; shift ordinary implementation judgment left to downstream GSD agents unless a decision materially changes the public contract.

</specifics>

<deferred>
## Deferred Ideas

- Outbound deep-link ergonomics, if later needed, should arrive as Phoenix-side URL helpers or a separately named family rather than widening `deep_link` into route-local bridge authority.
- Broad app-wide permission dashboards, generic permission brokers, or request flows belong in later phases if the capability/support posture ever proves them honestly.
- Rich platform-specific permission state exposure as a primary public contract is explicitly deferred; only secondary detail escape hatches are acceptable in this phase.

</deferred>

---

*Phase: 16-system-context-bridges*
*Context gathered: 2026-05-20*
