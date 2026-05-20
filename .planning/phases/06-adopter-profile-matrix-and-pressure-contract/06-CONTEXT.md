# Phase 6: Adopter Profile Matrix And Pressure Contract - Context

**Gathered:** 2026-05-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 6 defines the public adopter-profile matrix and the exact pressure contract that later exemplar phases will use. This phase must publish three adopter profiles, map each one to explicit route classes and runtime-ownership expectations, identify the required Crosswake seams each profile depends on, and state what each profile is meant to validate or challenge in Phases 7-10.

This phase does not turn exemplars into starter apps, widen Crosswake into billing or plugin-bus breadth, or add new runtime classes. It clarifies the support posture and exemplar structure that the existing v1 substrate will be pressured through.

</domain>

<decisions>
## Implementation Decisions

### Profile framing
- **D-01:** Use runtime-pressure framing for the public profile names, not category-marketing framing and not internal capability labels.
- **D-02:** The three public profiles are `Phoenix SaaS Portal`, `Selective Native Flow`, and `Local-First Study Flow`.
- **D-03:** `Phoenix SaaS Portal` means a server-centric Phoenix product shape where most authenticated mobile routes stay `:live_view` inside the shell and only narrow native affordances are added through declared seams.
- **D-04:** `Selective Native Flow` means a mostly Phoenix-owned app shape where one device-heavy or entitlement-sensitive route moves into explicit `:native_screen` ownership without turning the rest of the app into a generic native wrapper.
- **D-05:** `Local-First Study Flow` means a study-oriented or training-oriented flow where meaningful work continues offline through an `:offline_island`, durable journal/outbox replay, and explicit cached read-only neighboring routes.
- **D-06:** Keep the names behavioral and route-local. Do not rename the profiles to generic market buckets such as `Subscription App` or `Learning App`, because that would invite template and vendor-scope expectations.

### Matrix shape and publication posture
- **D-07:** The adopter-profile matrix should stay lean and route-pressure-oriented rather than becoming a second support matrix.
- **D-08:** Each matrix row should include exactly these columns: `Profile`, `Product shape`, `Primary route classes`, `Runtime ownership expectation`, `Required seams`, `What it pressures`, and `Explicit non-goals`.
- **D-09:** Status labels such as `supported`, `verification required`, platform-version baselines, and exact proof-hook names do not belong in the profile matrix itself. Those remain in `guides/support_matrix.md` and adjacent support docs.
- **D-10:** Each profile should have supporting prose below or beside the matrix covering representative routes, rough-edge cautions, proof posture summary, and why the profile exists.
- **D-11:** The matrix is an adopter-fit and pressure artifact first. It may reference later exemplar phases, but it should not collapse into roadmap-only planning language.

### Exemplar artifact shape
- **D-12:** Later exemplar phases should build on one checked-in example host with hard-separated profile lanes, not three separate full sample apps.
- **D-13:** The checked-in iOS and Android example hosts remain paired public proof artifacts with that shared Phoenix host rather than multiplying host apps per profile.
- **D-14:** Per-profile isolation should come from route/module/fixture/proof-lane separation inside the shared example host, not from separate template-grade applications.
- **D-15:** Small secondary fixtures are acceptable only if a later proof lane genuinely needs tighter hermetic isolation. They are secondary to the shared example-host artifact class.
- **D-16:** The exemplar structure must never imply that Crosswake ships blessed starter apps or app templates as a primary product surface.

### Pressure contract by profile
- **D-17:** `Phoenix SaaS Portal` should pressure bounded shell activation, manifest-first route truth, denial UI, authenticated `:live_view` route behavior, one low-frequency bridge affordance, and support/documentation honesty for server-centric product surfaces.
- **D-18:** `Phoenix SaaS Portal` should keep packs, offline islands, native capture, broad transfer seams, billing abstractions, and plugin-style capability breadth out of scope for its primary proof target.
- **D-19:** `Selective Native Flow` should pressure one explicit `:native_screen` route, required packs where relevant, native-capture or other narrow native handoff semantics, route-local transfer seams such as `transfer.upload.prepare`, route-local sensitivity, and the fail-closed contract around native ownership.
- **D-20:** `Selective Native Flow` should not widen into billing, entitlement systems, broad permission brokers, multiple native-screen categories, or generic upload/container fallback behavior in Phase 8.
- **D-21:** `Local-First Study Flow` should pressure the distinction between cached read-only routes and true `:offline_island` ownership, plus journal/outbox durability, replay outcomes, conflict vocabulary, route-local offline states, and proof-backed rough-edge guidance.
- **D-22:** `Local-First Study Flow` should not widen into broad CRUD sync, collaborative sync, media-heavy offline transfer, background-sync guarantees, or multiple offline-island stories in Phase 9.
- **D-23:** Across all three profiles, Crosswake should keep one primary failure vocabulary per lane so later docs and proof lanes can clearly state what is proven, what is rough-edge, and what is deferred.

### Realism boundary and scope guardrails
- **D-24:** Exemplars should be minimal-realistic, not toy demos and not template-grade sample apps.
- **D-25:** Each exemplar should prove one believable job-to-be-done and stay roughly within 4-8 routes.
- **D-26:** Exemplars should exercise only already-declared Crosswake seams: `:live_view`, `:offline_island`, `:native_screen`, packs, transfers, bounded bridge capabilities, shell activation truth, and offline replay semantics.
- **D-27:** Use generic or fake domain data and avoid vendor-heavy billing, identity-provider, analytics, push, or third-party SDK choices unless a later phase is explicitly about that integration boundary.
- **D-28:** Shared scaffolding is acceptable when it preserves proof clarity, but any convenience abstraction that blurs lane boundaries or turns the example host into a kitchen-sink demo is out of scope.
- **D-29:** The exemplar milestone should maximize architectural pressure and adopter trust, not copy-paste app completeness.

### Ecosystem lessons to preserve
- **D-30:** Learn from Hotwire Native’s separation of web shell, bridge components, and native screens, but keep Crosswake Phoenix-first and route-policy-first rather than path-rule-first.
- **D-31:** Learn from Expo’s runtime-version honesty that native/runtime compatibility must stay explicit when native behavior changes.
- **D-32:** Learn from Android’s offline-first guidance that local data truth and queued writes need explicit contracts, not marketing claims.
- **D-33:** Learn from Capacitor’s success in web-first extensibility, but avoid inheriting plugin-sprawl expectations or a generic capability bus in Crosswake core.
- **D-34:** Learn from WebView security guidance on Android and WebKit that broad JS/native bridge authority is unsafe by default. Keep origin allowlists, active-route checks, and route-local capability gating explicit.

### Decision delegation posture
- **D-35:** Shift normal implementation choices left within GSD for this phase. Researcher and planner agents should make principled decisions without re-asking unless a choice would materially change public profile names, the matrix schema, the shared-vs-multiple-example-host posture, or the milestone’s no-template/no-plugin-bus boundary.

### the agent's Discretion
- Exact wording of profile blurbs, matrix cell copy, and guide-section titles.
- Exact module and route organization inside the shared example host, as long as profile lanes remain explicit and falsifiable.
- Exact representative route examples chosen for each profile, as long as they pressure the locked seams above and do not widen scope.
- Exact doc layout around the matrix, as long as support status remains in support docs and profile pressure remains in the Phase 6 artifact.

</decisions>

<specifics>
## Specific Ideas

- The matrix should help an adopter answer one question quickly: “Is my mobile surface mostly LiveView, one explicit native escape, or a real offline island?”
- `Phoenix SaaS Portal` is the natural place to prove shell truth without making Crosswake read like a wrapper.
- `Selective Native Flow` should likely reuse the existing native-capture and transfer seams rather than inventing a new policy-sensitive native domain.
- `Local-First Study Flow` should stay anchored to the existing study-session offline-island story instead of widening into a second offline archetype this milestone.
- The overall artifact shape should resemble a proof-backed guide with one lean table plus three short profile sections, not a catalog of demos.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Core planning context
- `.planning/PROJECT.md` — project thesis, milestone goal, active requirements, and anti-template stance
- `.planning/REQUIREMENTS.md` — PROF-01 and PROF-02 plus the downstream Phase 7-10 requirements this matrix must guide
- `.planning/ROADMAP.md` — Phase 6 goal, success criteria, and sequencing into the three exemplar phases and hardening phase
- `.planning/STATE.md` — current milestone position and current concerns about exemplar drift
- `.planning/seeds/SEED-001-example-app-stress-profiles.md` — seed rationale, early profile shape, and explicit “stress-test exemplars, not templates” guidance

### Prior phase decisions
- `.planning/phases/01-route-policy-foundation/01-CONTEXT.md` — route taxonomy, host-owned example/template posture, and explicit noun-based public DSL
- `.planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md` — bounded shell, denial, and bridge posture that the SaaS and selective-native profiles must preserve
- `.planning/phases/04-honest-offline-contract/04-CONTEXT.md` — cached read-only versus offline-island distinction and replay/conflict guardrails for the local-first profile
- `.planning/phases/05-packs-native-escape-and-proof-lanes/05-RESEARCH.md` — pack, transfer, and native-escape constraints relevant to the selective-native profile
- `.planning/phases/05-packs-native-escape-and-proof-lanes/05-UI-SPEC.md` — public UI vocabulary and route-facing product-surface expectations where applicable

### Prompt lineage and architecture guidance
- `prompts/crosswake-research-synthesis.md` — stable route-policy architecture conclusions and primary adopter archetypes
- `prompts/crosswake-gsd-project-brief.md` — authoritative project brief and capability ladder
- `prompts/crosswake-elixir-oss-dna.md` — maintainer OSS house style, example-host proof posture, and support-truth expectations
- `prompts/crosswake-brand-book.md` — language and positioning guardrails for public-facing profile names and docs
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — broad app-archetype lessons and capability-ladder comparisons
- `prompts/elixir-mobile-apptypes-design-stresstest-deep-research.md` — stress-test matrix lessons and cautions against widening into generic wrapper behavior

### Current public artifact surfaces
- `guides/support_matrix.md` — current proof-backed support status surface that the profile matrix must not duplicate
- `guides/native_shell.md` — shell activation, denial, native-capture, and bridge contract guidance relevant to SaaS and selective-native profiles
- `guides/offline.md` — current narrow offline support claims that the local-first profile must preserve
- `guides/packs.md` — route-local pack and transfer contract guidance relevant to selective-native pressure
- `guides/install.md` — checked-in example-host proof posture and adopter-facing install truth

### Current example and proof anchors
- `examples/phoenix_host/lib/crosswake_example/router.ex` — current shared example host already exercising `:live_view`, packs, transfers, and one `:native_screen` route
- `script/verify_phase5_example_hosts.sh` — current checked-in example-host proof entrypoint that later exemplar phases should extend rather than bypass

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `examples/phoenix_host/lib/crosswake_example/router.ex` — already provides one shared example-host topology where separate profile lanes can be introduced without multiplying Phoenix apps.
- `guides/support_matrix.md` — demonstrates the existing narrow proof/status surface that Phase 6 should complement rather than duplicate.
- `guides/native_shell.md`, `guides/offline.md`, and `guides/packs.md` — already publish the three main substrate stories that map cleanly onto the three adopter profiles.
- `script/verify_phase5_example_hosts.sh` — provides the current proof-lane anchor for checked-in example hosts and should likely remain the base verification entrypoint.

### Established Patterns
- Crosswake treats checked-in example hosts as the public proof artifact class and generated hosts as secondary verification.
- Public docs separate support truth from broader architectural guidance.
- Route-local, typed, bounded contracts are preferred over generic capability or template abstractions.
- The project repeatedly chooses explicit names, narrow support claims, and fail-closed behavior over breadth marketing.

### Integration Points
- Phase 6 output should feed directly into Phase 7-10 planning so each later exemplar phase has a locked pressure target rather than needing to rediscover scope.
- The shared example host should become the locus for profile-lane route organization, fixture shaping, and later proof-lane expansion.
- Support docs, proof lanes, and any doctor/guidance additions in later phases should reference the same profile vocabulary defined here.

</code_context>

<deferred>
## Deferred Ideas

- Turning any of the exemplar lanes into a polished starter app, template, or copy-paste vertical sample.
- Widening `Selective Native Flow` into billing, entitlement, paywall, notification, or broad capability-broker proof in this milestone.
- Adding multiple offline-island archetypes, broad CRUD sync, collaborative sync, or background/offline media-transfer guarantees to the local-first lane.
- Creating separate full Phoenix/native host apps per profile unless later proof work proves the shared-host artifact class cannot carry a specific lane honestly.
- Adding new runtime classes or re-opening the route taxonomy during Phase 6.

</deferred>

---

*Phase: 06-adopter-profile-matrix-and-pressure-contract*
*Context gathered: 2026-05-17*
