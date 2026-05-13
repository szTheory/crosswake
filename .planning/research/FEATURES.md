# Feature Landscape

**Domain:** Phoenix-native mobile substrate library for Phoenix teams shipping iOS and Android apps
**Researched:** 2026-05-12

## Table Stakes

Features adopters should reasonably expect from `Crosswake` v1. Missing these would make the library feel incomplete or unserious.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Route policy DSL with manifest generation and validation | This is the product thesis. Teams need one authoritative way to declare which runtime owns each route, what capabilities it needs, and whether it can degrade offline. | Med | Must compile to explicit runtime truth for Phoenix, iOS, and Android. Confidence: HIGH |
| Native shell contract with navigation and deep-link handoff | A mobile substrate must own app entry, route transitions, lifecycle hooks, and deep-link routing across shell and LiveView/native screens. | Med | Keep shell opinionated enough to be reviewable, but not a UI framework. Confidence: HIGH |
| Bounded capability registry and bridge contract | Mobile teams expect access to baseline device affordances such as camera, files, share sheet, notifications, haptics, and links. Adjacent stacks like Capacitor and Expo make this table stakes. | High | Crosswake should expose semantic, allowlisted capabilities instead of ad hoc message passing. Confidence: HIGH |
| Explicit offline policy per route | Mobile users expect at least graceful failure, cached reads, and draft preservation under bad connectivity. | High | v1 should support `:unavailable`, `:cached_read_only`, and draft/outbox seams before ambitious local-first sync. Confidence: HIGH |
| Upload, download, and media transfer seams | Phoenix/LiveView already supports interactive uploads on the web; mobile teams will expect a credible path for file picking, capture handoff, transfer progress, and retry semantics. | Med | This should be contract-level in v1, not a full media platform. Confidence: HIGH |
| Push-notification and deep-link entry contract | Mobile apps need notification taps to land in the correct route/runtime mode, even if provider integrations vary. | Med | Core should define token registration, event receipt, and deep-link dispatch seams; provider delivery can stay companion/example scope. Confidence: MEDIUM |
| Compatibility gating for binaries, manifests, and OTA-safe content updates | Modern mobile teams expect fast non-native fixes, but platform rules still require strict native/runtime compatibility boundaries. | High | Crosswake should make incompatible manifest or capability changes fail closed instead of hoping store binaries catch up. Confidence: HIGH |
| Security and privacy defaults around capabilities, caching, and route activation | Mobile routes expand the blast radius of vague trust assumptions. Store policies also force consent, minimization, and permission clarity. | High | Capability allowlists, route-scoped checks, cache sensitivity flags, and privacy metadata should be core, not optional. Confidence: HIGH |
| Generators, doctor diagnostics, example hosts, and a support matrix | For Phoenix OSS, install truth is product truth. Teams will not trust a mobile substrate without a proof lane and diagnostics. | Med | Treat docs, example-host verification, and support claims as public API. Confidence: HIGH |

## Differentiators

These are high-value follow-ons that can make Crosswake meaningfully better than “Phoenix plus a shell,” but they should land after the core contract is stable.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Offline islands with first-class local execution and reconciliation | This is the strongest architectural differentiator once the basic route policy exists. It gives Phoenix teams an explicit answer for workflows that cannot depend on LiveView round-trips. | High | Requires local storage contract, mutation outbox, replay rules, and conflict semantics. Confidence: HIGH |
| Content packs and media packs | Strong fit for learning, training, and content-heavy apps where offline assets matter as much as screens. | High | Best added once manifest/versioning and transfer seams are proven. Confidence: MEDIUM |
| Native screen adapters as disciplined escape hatches | Gives teams a clean path for camera, audio capture, advanced media, billing surfaces, or other platform-heavy flows without pretending everything belongs in LiveView. | High | Should ship as narrow, named adapters or templates, not a generic native-rendering abstraction. Confidence: HIGH |
| Phoenix-mounted diagnostics and manifest inspection UI | Fits the maintainer’s OSS style and materially improves adoption, debugging, and support. | Med | Useful once runtime manifests, capability negotiation, and compatibility gates exist. Confidence: HIGH |
| Rollouts, kill switches, and runtime experiments via remote config | A strong safety feature for staged rollout of native screens, bridge affordances, and offline modes. | Med | Likely best as a `rulestead` companion or tightly documented integration. Confidence: MEDIUM |
| First-party companion integrations for auth, notifications, media, and auditability | Tight integrations with `sigra`, `chimeway`, `rindle`, and `threadline` would make Crosswake feel like a coherent Phoenix-mobile ecosystem instead of a raw substrate. | Med | Keep the core thin; add companions only where the boundary is crisp. Confidence: MEDIUM |
| Route-class telemetry and mobile journey observability | Operators need to know which runtime mode fails, stalls, or causes churn. | Med | Valuable after the public runtime contract is stable. Confidence: MEDIUM |

## Anti-Features

Features Crosswake should explicitly not build, because they either contradict the thesis or create rewrite-level scope risk.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Universal UI abstraction across all screens | It collapses the core thesis back into “one runtime everywhere” and invites endless widget-surface work. | Keep runtime ownership explicit per route. |
| LiveView driving native rendering as a high-frequency render loop | This would over-couple Crosswake to unstable rendering internals and create performance/debugging pain. | Use bounded bridge components and native screens for selective flows. |
| Ad hoc bidirectional message bus between LiveView and native | Generic messaging becomes an unversioned escape hatch that bypasses security, compatibility, and support boundaries. | Expose semantic capabilities and typed bridge contracts only. |
| “Offline magically works” sync | Hidden local state and auto-reconciliation create trust failures and painful rewrites. | Make offline modes explicit, with named guarantees and visible conflict handling. |
| Broad first-party billing, identity-provider, and payment-provider abstractions in core | Store policy differences and provider churn would dominate the roadmap and blur the substrate’s value. | Keep billing and IdP work as examples or later companions. |
| “Wrap my Phoenix app in a WebView and ship it” mode | It undermines review credibility, hides runtime boundaries, and makes the product look disposable. | Ship an honest shell plus route policy, capability, and native escape-hatch story. |
| Unsafe OTA or remote updates that can change native assumptions | Apple and Android both impose compatibility limits around app binaries, code, and commerce behavior. | Allow only compatibility-checked non-native updates and fail closed on mismatches. |
| Browser-engine or desktop-packaging ambitions in the v1 core | These add platform surface area before the mobile contract is proven. | Revisit after iOS/Android route policy and shell contracts are stable. |

## Feature Dependencies

```text
Route policy DSL
  -> Manifest generation + validation
  -> Native shell contract
  -> Capability registry + bridge versioning
  -> Security/caching defaults

Capability registry + bridge versioning
  -> Push/deep-link contract
  -> Upload/media seams
  -> Native screen adapters

Explicit offline policy
  -> Draft persistence / outbox seams
  -> Offline islands
  -> Content packs / media packs

Manifest + compatibility gating
  -> OTA-safe content updates
  -> Diagnostics / doctor
  -> Support matrix and proof lanes

Proof lanes + diagnostics
  -> Companion integrations
  -> Operator diagnostics UI
  -> Strong public support claims
```

## MVP Recommendation

Prioritize:

1. Route policy DSL, manifest generation, and compatibility validation
2. Native shell contract with navigation, lifecycle, and deep-link handoff
3. Bounded capability registry plus a very small bridge surface
4. Explicit offline policy declaration with cached-read and draft/outbox seams
5. Generators, doctor diagnostics, example hosts, and an honest support matrix

Defer:

- Offline islands: powerful, but only after route policy and compatibility truth are stable
- Native screen adapter catalog: add selectively after proving the bridge contract
- Billing and provider integrations: keep out of v1 core because policy churn will overwhelm the substrate thesis
- Broad companion ecosystem: design for it now, ship only the highest-leverage companions later

## Sources

- Project context: [PROJECT.md](../PROJECT.md), [crosswake-gsd-project-brief.md](../../prompts/crosswake-gsd-project-brief.md), [crosswake-research-synthesis.md](../../prompts/crosswake-research-synthesis.md), [crosswake-elixir-oss-dna.md](../../prompts/crosswake-elixir-oss-dna.md), [crosswake-integrations-and-companions.md](../../prompts/crosswake-integrations-and-companions.md)
- Expo EAS Update docs, last updated March 5, 2026: https://docs.expo.dev/eas-update/introduction/ (HIGH)
- Expo push notifications overview, last updated June 6, 2025: https://docs.expo.dev/push-notifications/overview/ (MEDIUM)
- Capacitor documentation: https://capacitorjs.com/docs (HIGH)
- Phoenix LiveView uploads: https://hexdocs.pm/phoenix_live_view/uploads.html (HIGH)
- Phoenix LiveView JavaScript interoperability: https://hexdocs.pm/phoenix_live_view/js-interop.html (HIGH)
- Apple App Review Guidelines, accessed May 12, 2026: https://developer.apple.com/app-store/review/guidelines/ (HIGH)
- Google Play payments policy, accessed May 12, 2026: https://support.google.com/googleplay/android-developer/answer/10281818 (HIGH)
- LiveView Native site, accessed May 12, 2026: https://native.live/ (MEDIUM)
