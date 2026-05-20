# Phase 7: Phoenix SaaS Portal Exemplar - Context

**Gathered:** 2026-05-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 7 proves the `Phoenix SaaS Portal` adopter lane inside the shared example host. It must show a believable authenticated product shape that stays mostly `:live_view`, runs inside the manifest-first mobile shells, uses one bounded native affordance through an already-declared Crosswake seam, and publishes proof and guidance that make the supported, degraded, and deferred boundaries of the server-centric SaaS profile explicit.

This phase does not widen into offline islands, packs as a primary story, native capture, broad transfer workflows, billing abstractions, identity-provider integrations, plugin-style capability breadth, or template-grade sample-app scope.

</domain>

<decisions>
## Implementation Decisions

### Product slice and route emphasis
- **D-01:** The exemplar should be an approvals-led SaaS portal, with account health as supporting context rather than the primary story.
- **D-02:** The exemplar should feel like a real mobile companion for routine work: review account health, inspect approval items, and confirm approvals without leaving Phoenix ownership.
- **D-03:** Keep the lane to five primary routes so the proof stays falsifiable and does not drift into starter-app territory.
- **D-04:** The recommended route set is:
  - `/saas/dashboard`
  - `/saas/accounts/:id`
  - `/saas/approvals`
  - `/saas/approvals/:id`
  - `/saas/settings/profile`
- **D-05:** `dashboard` and `accounts/:id` provide product context and account-health drill-in, but `approvals` and `approvals/:id` are the center of gravity.
- **D-06:** `settings/profile` exists as a normal authenticated route, not as the primary product slice. It may carry supporting shell/account truth, but it must not steal focus from the approvals flow.
- **D-07:** Do not switch the primary slice to support inbox, uploads, analytics-heavy dashboarding, or admin-console breadth. Those options add pressure in the wrong places for Phase 7.

### Authenticated surface posture
- **D-08:** The example host should use ordinary Phoenix session auth and host-owned auth scaffolding rather than a Crosswake auth abstraction.
- **D-09:** Model one authenticated account boundary with one lightweight role split only.
- **D-10:** The role split should be narrow and testable, such as `member` versus `approver`.
- **D-11:** `member` can view the SaaS routes; `approver` can also execute one guarded approval action.
- **D-12:** Authz should be enforced in ordinary Phoenix/LiveView places: plugs, `live_session` / `on_mount`, and the approval action itself. Do not rely on routing alone.
- **D-13:** Fixture data should stay minimal-realistic: one account, two seeded users, and a small approval queue. Enough realism to pressure authenticated route ownership, not enough breadth to imply a reusable auth product.
- **D-14:** Docs must say clearly that auth/session code in the example host is host-owned example code, not a public Crosswake auth surface.
- **D-15:** Keep SSO, OAuth/OIDC, passkeys, MFA, org switching, impersonation, mobile token choreography, and vendor auth guidance out of scope for this phase.

### Native affordance choice
- **D-16:** The one primary bounded native affordance for the SaaS lane should be `haptics.impact`.
- **D-17:** Use `haptics.impact` at low-frequency, product-meaningful moments such as approval confirmation or another single routine confirm action.
- **D-18:** Keep the LiveView route and server-authoritative action as the product owner; the native affordance is only a supporting shell signal.
- **D-19:** `app.info.get` may appear only as secondary supporting context in docs or a tiny profile/settings surface if it helps explain shell/runtime truth, but it is not the primary Phase 7 affordance.
- **D-20:** Do not make `files.pick`, transfer commands, or other broader native seams the main SaaS proof. Those blur Phase 7 into transfer or native-flow pressure that belongs elsewhere.
- **D-21:** The bridge posture must remain semantic, typed, versioned, request/reply-only, and low-frequency, exactly as locked in prior phases.

### Support, proof, and documentation emphasis
- **D-22:** Docs and proof for this phase should lead with shell truth, not capability demos.
- **D-23:** The emphasis order is:
  1. manifest-first activation, deep-link normalization, and explicit `route unavailable` behavior
  2. authenticated `:live_view` product routes staying Phoenix-owned inside the shell
  3. one bounded native affordance through a declared seam
- **D-24:** The SaaS lane should prove that Crosswake is not a generic wrapper: denied or unsupported routes fail closed onto explicit denial UI instead of silently degrading into a WebView fallback.
- **D-25:** Public support/proof status remains in `guides/support_matrix.md` and existing install/support surfaces. Phase 7 docs should explain the SaaS profile boundaries without duplicating the support matrix.
- **D-26:** The public proof artifact remains the shared checked-in example host plus the paired iOS and Android hosts. Do not create a separate sample app or alternative proof system for the SaaS lane.
- **D-27:** Generated native shells remain scaffold-once, host-owned artifacts. Phase 7 should preserve that upgrade and ownership honesty.

### Phoenix and ecosystem idiomaticity
- **D-28:** Stay close to standard Phoenix/Plug/LiveView patterns: router grouping, plugs, `live_session`, `on_mount`, session-backed auth, Ecto-backed list/detail queries, and one guarded action.
- **D-29:** The exemplar should resemble a clean Phoenix product slice, not a special-purpose Crosswake demo harness.
- **D-30:** Learn from Hotwire Native’s discipline: keep the main flow web-first, add one bounded bridge seam, and reserve native screens for later phases that truly need them.
- **D-31:** Learn from Expo/Tauri-style compatibility and capability honesty: keep native/runtime compatibility and route-local capability boundaries explicit and narrow.
- **D-32:** Learn from Phoenix’s auth generator/scopes posture: example auth code can be app-owned and customizable without becoming part of Crosswake core.

### Tradeoffs accepted
- **D-33:** Accept a narrower product story than a “full mobile SaaS app” so Phase 7 pressures route truth instead of feature breadth.
- **D-34:** Accept a modest native affordance because a small, honest `haptics.impact` proof is architecturally stronger than a broader but noisier file/upload or native-flow demo.
- **D-35:** Accept server authority everywhere in this lane. No cached-write, queued-write, or offline-draft implication belongs in the SaaS exemplar.

### Decision delegation posture
- **D-36:** Shift normal Phase 7 implementation choices left within GSD. Researcher and planner agents should not re-ask about route naming, auth scaffolding style, or the bounded affordance choice unless a proposal would materially change the approvals-led slice, the lightweight-role posture, the one-affordance limit, or the support-truth-first documentation order.
- **D-37:** Internal implementation details such as exact module boundaries, fixture names, query organization, LiveView component breakdown, and proof assertion shapes are agent discretion as long as they preserve the decisions above.

### the agent's Discretion
- Exact names for the two roles, as long as the split remains lightweight and approval-centric.
- Exact approval-domain nouns, fixture copy, and seeded sample records.
- Exact location of the `haptics.impact` invocation, as long as it stays tied to one low-frequency product confirmation.
- Exact docs layout for the SaaS lane, as long as shell truth leads and support-matrix duplication is avoided.

</decisions>

<specifics>
## Specific Ideas

- The strongest story is “routine mobile approvals in a Phoenix-owned shell,” not “mobile dashboarding” and not “mobile file workflows.”
- `route unavailable` should stay the primary failure vocabulary focus for the SaaS lane, because Phase 7 is about proving explicit shell truth and safe denial before it proves richer native breadth.
- The approval action is the natural place to attach `haptics.impact`, because it gives real mobile value without changing route ownership.
- One lightweight role split is enough to make the lane feel like a product instead of a toy while still avoiding auth-system scope creep.
- `settings/profile` should behave like an ordinary signed-in product route, not a diagnostics lab.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Core planning context
- `.planning/PROJECT.md` — project thesis, current milestone goal, and no-wrapper / no-template boundaries
- `.planning/REQUIREMENTS.md` — `SAAS-01`, `SAAS-02`, and surrounding v2 scope boundaries
- `.planning/ROADMAP.md` — Phase 7 goal and success criteria
- `.planning/STATE.md` — current milestone position and exemplar-drift concerns

### Prior phase decisions
- `.planning/phases/01-route-policy-foundation/01-CONTEXT.md` — route taxonomy, host-owned generator posture, and Phoenix-first public contract
- `.planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md` — manifest-first activation, denial UI, bounded bridge posture, and fail-closed shell truth
- `.planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md` — locked SaaS-profile meaning, route budget, shared example-host lane contract, and support-truth boundaries

### Phase-local and host-local artifact boundaries
- `guides/adopter_profiles.md` — public SaaS-profile framing and non-goals
- `guides/native_shell.md` — shell activation, denial, and bridge contract guidance
- `guides/support_matrix.md` — canonical support-status surface that Phase 7 must not duplicate
- `guides/install.md` — public install and proof-lane posture
- `examples/phoenix_host/README.md` — shared example-host lane contract, representative SaaS routes, and proof-extension rules
- `examples/phoenix_host/lib/crosswake_example/router.ex` — current shared host topology that Phase 7 must extend
- `script/verify_adopter_profile_contract.sh` — current profile-contract proof scaffold
- `script/verify_phase5_example_hosts.sh` — base example-host proof entrypoint Phase 7 should extend rather than replace

### Prompt lineage and project guidance
- `prompts/crosswake-brand-book.md` — terminology and anti-wrapper messaging guardrails
- `prompts/crosswake-research-synthesis.md` — stable architecture thesis and app-archetype framing
- `prompts/crosswake-gsd-project-brief.md` — product thesis, capability ladder, and “prefer decisive recommendations” directive
- `prompts/crosswake-elixir-oss-dna.md` — OSS house style, support-truth posture, and proof-first guidance
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — runtime-boundary and app-archetype lessons
- `prompts/elixir-mobile-apptypes-design-stresstest-deep-research.md` — archetype pressure and scope-drift cautions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `examples/phoenix_host/lib/crosswake_example/router.ex` already provides one shared example-host router that can gain a `CrosswakeExample.SaaSPortal.*` lane without multiplying apps.
- `guides/adopter_profiles.md` and `examples/phoenix_host/README.md` already lock the representative SaaS route class, route budget, and non-goals.
- `guides/native_shell.md` and `guides/support_matrix.md` already publish the shell-truth and support-truth posture the SaaS lane should extend.
- The current shell and bridge contract already include `haptics.impact` as a bounded low-frequency affordance.

### Established Patterns
- Shared example-host artifacts are the public proof class.
- Route-local, typed, bounded contracts are preferred over plugin-style breadth.
- Support truth lives in guides and proof hooks, not in marketing language.
- Host-owned example code is acceptable when ownership boundaries stay explicit.

### Integration Points
- Phase 7 should add a `CrosswakeExample.SaaSPortal.*` route/module/fixture lane inside the shared host.
- The route set should remain mostly `:live_view` and authenticated, with one explicit low-frequency bridge interaction.
- Proof should extend the existing adopter-profile contract and example-host verification scripts with SaaS-lane assertions rather than inventing a new lane harness.
- Docs should link back to existing shell/support/install guides instead of restating their full contract surfaces.

</code_context>

<deferred>
## Deferred Ideas

- Attachments, uploads, file-pick flows, or other broader transfer seams as the main SaaS story
- Push notifications, support inbox flows, drafts, or offline read/write claims
- Billing, entitlements, paywalls, or app-store-policy-sensitive commerce flows
- OAuth/OIDC, SSO, MFA, passkeys, org switching, impersonation, or vendor auth integrations
- Multiple role families, richer RBAC systems, or admin/backoffice sub-products
- Native-screen ownership, packs as the primary pressure, native capture, or plugin-style capability expansion
- Turning the shared example host into a polished starter app or reusable SaaS template

</deferred>

---

*Phase: 07-phoenix-saas-portal-exemplar*
*Context gathered: 2026-05-17*
