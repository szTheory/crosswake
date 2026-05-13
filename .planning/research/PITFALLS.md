# Domain Pitfalls

**Domain:** Phoenix-native mobile substrate library for Phoenix/iOS/Android
**Researched:** 2026-05-12
**Overall confidence:** MEDIUM-HIGH

## Critical Pitfalls

Mistakes here usually force contract rewrites, support collapse, or platform rejection.

### Pitfall 1: Recreating a "One Runtime Everywhere" Story
**What goes wrong:** The library drifts from route policy into an implicit universal app framework. Teams start expecting every screen to work equally well as LiveView, offline island, or native surface.
**Why it happens:** Product pressure rewards a simpler pitch than the actual architecture. Convenience APIs blur ownership boundaries until runtime choice becomes accidental.
**Consequences:** Crosswake becomes a vague WebView wrapper on one side and a fake native-renderer promise on the other. Support claims sprawl faster than proof can keep up.
**Warning signs:**
- Early demos avoid naming which runtime owns each screen.
- New APIs abstract over runtime differences instead of exposing them.
- Docs use language like "write once" or "seamless everywhere."
- Example apps rely on bridge tricks instead of explicit route policy.
**Prevention strategy:** Make route ownership the primary product surface. Require every supported route mode to declare runtime, offline semantics, capabilities, and security sensitivity in the manifest. Reject API proposals that erase runtime boundaries.
**Recommended phase to address it:** Phase 1 - Product contract and route-policy DSL

### Pitfall 2: Treating the Bridge as a High-Frequency Rendering or State Bus
**What goes wrong:** The JS/native bridge starts carrying chatty UI state, streaming updates, or arbitrary commands rather than low-frequency semantic actions.
**Why it happens:** Once a bridge exists, teams route "just one more thing" through it instead of choosing native ownership or a real offline island.
**Consequences:** Janky UX, difficult debugging, protocol drift, and security exposure from ad hoc message shapes. The product becomes fragile at exactly the mobile boundary it is supposed to clarify.
**Warning signs:**
- Bridge messages are generic blobs instead of versioned commands/events.
- Native screens depend on frequent round-trips to stay interactive.
- Message volume becomes a performance topic in routine flows.
- The protocol has no explicit version negotiation or compatibility gate.
**Prevention strategy:** Define the bridge as semantic, bounded, and versioned. Support only narrow command categories, typed payloads, and explicit compatibility checks. Route high-interaction flows to native screens or offline islands instead of "bridge-first" implementations.
**Recommended phase to address it:** Phase 2 - Bridge contract, versioning, and compatibility gates

### Pitfall 3: Fake Offline Support
**What goes wrong:** "Offline" initially means browser/WebView caching, then later has to absorb drafts, media queues, reconciliation, and conflict handling it was never designed for.
**Why it happens:** Teams collapse very different offline modes into one marketing label.
**Consequences:** Data loss, duplicate writes, broken trust, and major redesign when real local-first workflows arrive.
**Warning signs:**
- Offline policy is boolean or vaguely named.
- Cached read-only routes and mutating workflows share the same mechanism.
- There is no explicit outbox/journal/reconciliation contract.
- Media capture or background retry is discussed as "later" despite offline claims.
**Prevention strategy:** Split offline into explicit classes: unavailable, cached read-only, local drafts, append-only journal/outbox, and server-authoritative commit. Make offline islands a first-class contract with local persistence and reconciliation rules from the start.
**Recommended phase to address it:** Phase 3 - Offline-island contract, journals, and reconciliation seams

### Pitfall 4: Weak Trust Boundaries Around Capabilities and Route Activation
**What goes wrong:** Any loaded route or embedded page can try to call native capabilities, or the shell cannot prove the active route is entitled to use them.
**Why it happens:** Capability access is bolted on after the bridge, and origin/route checks stay informal.
**Consequences:** Security bugs, review risk, and a product surface nobody can safely reason about.
**Warning signs:**
- Capability checks live only in host app code, not in a shared contract.
- The bridge does not verify active route, origin, manifest permissions, and runtime mode together.
- Sensitive routes can be cached without differentiated policy.
- Docs tell adopters to "be careful" instead of describing enforced defaults.
**Prevention strategy:** Make capability grants manifest-driven and deny-by-default. Enforce route allowlists, origin allowlists, active-route verification, capability version checks, and sensitivity-aware cache rules in the core contract and doctor tooling.
**Recommended phase to address it:** Phase 2 - Capability registry and security defaults

### Pitfall 5: Shell/Web Runtime Compatibility Drift
**What goes wrong:** Phoenix assets, route manifests, and bridge protocol evolve independently from iOS/Android shell releases.
**Why it happens:** The project acts like web deploy velocity still applies after native shells enter the system.
**Consequences:** App breakage after OTA/web updates, hard-to-reproduce support issues, and delayed store fixes.
**Warning signs:**
- No compatibility matrix between manifest version, bridge version, and shell version.
- Web deploys can introduce new capabilities without shell gating.
- Example hosts only test "latest everything."
- Rollback strategy is undefined.
**Prevention strategy:** Introduce compatibility gates early. Version the manifest, bridge, capabilities, and content-pack schemas independently. Add negotiated minimum/maximum supported versions and explicit failure modes when the shell is too old.
**Recommended phase to address it:** Phase 2 - Runtime manifest, support matrix, and compatibility enforcement

### Pitfall 6: Underestimating Store Policy and Billing Constraints
**What goes wrong:** Product plans assume the substrate can neutralize app-review or billing rules, especially for digital purchases, feature unlocking, or account flows.
**Why it happens:** Server-first teams over-apply web assumptions to app stores.
**Consequences:** Rejected releases, late native rewrites, and roadmap churn around paywalls, account management, or remote-config behavior.
**Warning signs:**
- Subscription/billing examples are in core scope before route/runtime basics are stable.
- Product docs imply WebView or server-hosted purchase flows can bypass store policy.
- Native purchase/entitlement boundaries are left for "integration phase later."
- Review-sensitive capabilities are described without explicit platform notes.
**Prevention strategy:** Treat billing and review constraints as architecture inputs, not downstream integrations. Keep billing/provider work example-only early. Document which flows must be native-owned or policy-aware and add review-risk notes to runtime modes that touch payments, account creation, or restricted capabilities.
**Recommended phase to address it:** Phase 1 - Product boundaries and non-goals, then Phase 4 - Example integrations

### Pitfall 7: Shipping Broad Support Claims Without Proof Lanes
**What goes wrong:** Crosswake claims to support Phoenix + iOS + Android + multiple route modes, but CI only proves unit-level Elixir behavior.
**Why it happens:** OSS velocity prioritizes code over install truth, host-app proof, and docs-contract verification.
**Consequences:** Support load spikes, trust drops, and regressions surface first in adopters' apps.
**Warning signs:**
- README claims exceed what example hosts verify.
- The only meaningful proof path requires physical devices, real vendors, or manual store flows.
- Generated host code is not round-tripped in CI.
- Compatibility/support matrix is absent or stale.
**Prevention strategy:** Make deterministic example-host proof a release gate. Split hermetic merge-blocking lanes from advisory device/store lanes. Treat docs, generators, doctors, and compatibility matrix as product surface with automated checks.
**Recommended phase to address it:** Phase 1 - Install truth and proof-lane foundation

## Moderate Pitfalls

### Pitfall 1: Scope Collapse Into Early Companion and Vendor Integrations
**What goes wrong:** Auth, notifications, media, billing, and observability companions all try to land in v1 core.
**Prevention strategy:** Classify integrations as core, companion, example-only, or defer. Keep `sigra`, `rulestead`, `rindle`, `chimeway`, and `threadline` design-aware but out of core unless they sharpen the base contract.
**Warning signs:**
- Core milestones keep absorbing vendor-specific requirements.
- Public APIs mention providers before the route-policy API is stable.
- Example integrations start defining core abstractions.
**Recommended phase to address it:** Phase 1 - Package boundaries and integration taxonomy

### Pitfall 2: No Doctor/Diagnostics Surface for Native and Host Setup
**What goes wrong:** Installation and upgrade failures turn into Slack/GitHub support archaeology because the library cannot explain shell mismatch, missing native wiring, or unsupported capabilities.
**Prevention strategy:** Ship doctor tasks, manifest inspection, and explicit incompatibility diagnostics as first-class features. Consider a mounted Phoenix diagnostics surface only if it improves install truth materially.
**Warning signs:**
- Setup docs rely on manual checklists.
- Errors surface as generic "bridge failed" or "capability unavailable."
- Support answers require maintainers to inspect generated host code manually.
**Recommended phase to address it:** Phase 2 - Doctor tooling and diagnostics

### Pitfall 3: Generated Host Code With Unclear Ownership
**What goes wrong:** Generators produce iOS/Android/Phoenix glue code, but nobody knows which files are safe to edit, regenerate, or diff across upgrades.
**Prevention strategy:** Separate library-owned protocol logic from host-owned app composition. Mark generated regions, keep templates intentional, and document upgrade paths before generators sprawl.
**Warning signs:**
- Regeneration overwrites user changes.
- Docs cannot answer "who owns this file?"
- Small host changes require forking generated templates.
**Recommended phase to address it:** Phase 1 - Generator boundaries and ownership model

### Pitfall 4: Telemetry That Is Either Too Low-Level or Not Correlated Across Runtimes
**What goes wrong:** The system emits lots of events, but operators still cannot answer which route mode failed, which shell version was involved, or whether a sync replay caused user-visible damage.
**Prevention strategy:** Emit domain telemetry keyed to route, runtime mode, manifest version, capability, shell version, and sync outcome. Design for auditability and failure triage, not implementation vanity metrics.
**Warning signs:**
- Events focus on individual bridge calls only.
- There is no common correlation ID across Phoenix and mobile surfaces.
- Support incidents depend on manual reproduction instead of observability.
**Recommended phase to address it:** Phase 3 - Telemetry and audit surfaces

## Minor Pitfalls

### Pitfall 1: Accessibility and Reduced-Motion as Web-Only Concerns
**What goes wrong:** Route policies and shell behavior ignore platform accessibility, motion, and offline-state UX parity.
**Prevention strategy:** Include accessibility and reduced-motion checks in shell/runtime guidelines and example hosts. Treat degraded/offline UX as a product surface, not a fallback afterthought.
**Warning signs:**
- Offline or loading states differ wildly by platform.
- Native transitions override reduced-motion preferences.
- Route mode examples omit accessibility notes.
**Recommended phase to address it:** Phase 4 - UX hardening and example-host polish

### Pitfall 2: Monorepo or Multi-Package Versioning Without Policy
**What goes wrong:** Core package, example hosts, and future companions evolve independently with no declared compatibility rules.
**Prevention strategy:** Declare versioning and release policy before adding sibling packages. Keep v1 package count low and publish a compatibility/support table.
**Warning signs:**
- Companions appear before release policy exists.
- Tags/releases do not state which shell or manifest versions they support.
- Maintainers rely on tribal knowledge for compatibility answers.
**Recommended phase to address it:** Phase 2 - Release discipline and support policy

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Product framing | Universal-runtime marketing pressure | Make route ownership and non-goals explicit in README, guides, and examples |
| Route policy DSL | Missing security/offline fields | Require runtime, offline class, capability list, and sensitivity metadata in the route contract |
| Bridge protocol | Ad hoc generic message passing | Ship typed semantic commands/events with version negotiation and compatibility failure modes |
| Shell/runtime integration | OTA/web deploy drift | Enforce manifest/bridge/shell compatibility checks and clear rollback behavior |
| Offline support | Cached-read logic stretched into local-first workflows | Separate cached routes from offline islands, journals, and reconciliation |
| Integrations | Billing/media/auth define the core too early | Keep companions example-driven until the substrate contract is stable |
| OSS adoption | Install friction and support confusion | Provide generators, doctor tooling, example-host proof lanes, and support matrix early |
| Releases | Broad claims without proof | Gate releases on docs-contract, generated-host verification, and deterministic core CI |

## Sources

- Project sources: `.planning/PROJECT.md`, `prompts/crosswake-gsd-project-brief.md`, `prompts/crosswake-research-synthesis.md`, `prompts/crosswake-elixir-oss-dna.md`, `prompts/crosswake-integrations-and-companions.md`
- Phoenix LiveView docs, official HexDocs: https://hexdocs.pm/phoenix_live_view/
- Apple App Store Review Guidelines, official: https://developer.apple.com/app-store/review/guidelines/
- Google Play Payments policy, official: https://support.google.com/googleplay/android-developer/answer/10281818
- Android WebView bridge/security docs, official Android Developers: https://developer.android.com/reference/android/webkit/WebView#addJavascriptInterface(java.lang.Object,%20java.lang.String)
- WebKit/WKScriptMessageHandler docs, official Apple Developer Documentation: https://developer.apple.com/documentation/webkit/wkscriptmessagehandler

## Confidence Notes

- **HIGH:** Route-boundary, install-truth, proof-lane, and OSS-support pitfalls are strongly supported by the Crosswake project brief and maintainer OSS DNA.
- **MEDIUM-HIGH:** Bridge, compatibility, and capability-boundary pitfalls are supported by project architecture plus current official platform docs for WebView/WebKit messaging surfaces.
- **MEDIUM:** Billing/review pitfalls are directionally clear from current Apple/Google policy docs, but exact app-review outcomes still depend on specific feature implementation details.
