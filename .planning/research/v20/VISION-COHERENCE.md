# v20.0 Native Controls Pack 1 — Vision Coherence

**Lens:** Vision-coherence / project-strategy
**Milestone:** v20.0 Native Controls Pack 1
**Repo:** crosswake
**Prepared:** 2026-07-12

Sources read: `.planning/PROJECT.md`, `.planning/MILESTONE-ARC.md`, `.planning/DECISIONS.md`, `.planning/RETROSPECTIVE.md`, `prompts/crosswake-gsd-project-brief.md`, `prompts/crosswake-research-synthesis.md`, `prompts/crosswake-integrations-and-companions.md`, `prompts/crosswake-elixir-oss-dna.md`, `prompts/elixir-mobile-oss-refined-plan-deep-research.md`, `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md`, `guides/capability_map.md`, `.planning/phases/152-capability-map-collateral-and-v20-handoff/152-V20-HANDOFF.md`, `.planning/seeds/SEED-002-phoenix-first-native-capabilities-and-commerce.md`, plus repo inspection of `lib/crosswake/bridge/commands/`, `lib/crosswake/companion.ex`, and `packages/`.

---

## 1. Core vs Companion

**Verdict: Native Controls Pack 1 belongs in CORE. Do not create `crosswake_controls`.**

Apply the project's own companion criteria (`prompts/crosswake-integrations-and-companions.md`, `crosswake-elixir-oss-dna.md`): a companion is a bounded seam to an **external szTheory library** with its own persona, its own optional runtime dependency, and (per the OSS-DNA doc) is justified specifically "when it materially reduces unnecessary dependencies." `rulestead`/`rindle`/`sigra`/`chimeway`/`threadline` all satisfy this: each is a standalone library, each gates an optional dependency via `Crosswake.Companion`'s `@behaviour` + `function_exported?/3` seam, each has independent versioning and its own adopter persona (feature flags, media, auth, notifications, audit).

Native Controls Pack 1 candidates (alert/confirm, menu/action-button, haptics, share, toast/review-prompt) have **none of that texture**:
- No external Elixir dependency to gate — no optional-dep story, no `Code.ensure_loaded?` seam, nothing to fail closed on at the Elixir layer.
- No host-owned schema, no independent persona — they are pure typed contract + native platform API calls layered on the *existing* bridge/capability-registry/route-policy substrate.
- Direct repo precedent: `haptics`, `share`, `app_info`, `deep_link`, `permissions.status`, `notification_token`, and `file_picker` already ship today as `lib/crosswake/bridge/commands/*.ex` — in **core**, since v3.1, never companion. Pack 1 controls are the same category of thing extending the same directory, not a new architectural layer.
- The capability map's own "Package owner" column (produced in the prior phase, `guides/capability_map.md`) already classifies alert/confirm, menu/action-button, and toast/review-prompt as **core**; only `notification_token` reads as first-party-companion (Chimeway) evidence.
- The deep-research architecture stance (`elixir-mobile-oss-refined-plan-deep-research.md`, `elixir-mobile-architecture-apptypes-stresstest-deep-research.md`) treats "RoutePolicy, BridgeComponent, NativeScreen" as **one first-class architectural triad** — bridge components are not an optional extension of the core thesis, they *are* part of the core thesis, on par with route policy itself. The heavier things that *do* get a `package:` designation in that research (StoreKit, Play Billing) are exactly the ones Crosswake already treats as companions/adapters, not core bridge commands.

The one candidate with real companion texture is `notification_token`: its *evidence* is a Chimeway concern already. Pack 1's job there is a **documentation/support-truth pass** that keeps the read confined to "provider-tagged evidence" language — not new core command surface, and definitely not new companion code. Nothing about Pack 1 requires touching the companion registry at all.

**Anti-pattern to name explicitly:** extracting a `crosswake_controls` companion package would look disciplined (the extraction playbook is now familiar from v16/v17) but would actually invert five milestones of precedent and companion-boundary discipline for a capability set with zero external dependency to justify the split. That is process cargo-culting, not architecture, and it dilutes what "companion" means in this project.

## 2. The Catalog Line (verbatim rule)

> **A proposed native affordance belongs in Crosswake core as a bounded bridge command only if it passes ALL six:**
> **(a) Route-local & declarable** — route policy can name it as a per-route capability requirement with an explicit allowlist entry and a fail-closed default.
> **(b) Low-frequency, request/reply or fire-and-forget** — never a persistent high-frequency/streaming channel.
> **(c) Zero external SDK/provider/account dependency** — pure typed contract + native platform API call; no third-party SDK, no provider account, no durable host-owned schema.
> **(d) Semantically bounded** — the command vocabulary is closed and finite (named actions like `haptics.trigger`, `share.open`, `alert.confirm`), never an arbitrary-payload or arbitrary-native-code escape hatch.
> **(e) Fails closed to a Phoenix-owned equivalent** — when unsupported or undeclared, the route renders a meaningful non-native fallback (a LiveView modal instead of a native alert, a flash instead of a toast), never a silent no-op or crash.
> **(f) Backend/Phoenix stays authoritative** — the native affordance is UX/feedback layered on server-decided state; it is never itself the source of truth.
>
> **It crosses into a generic plugin catalog the moment ANY of these is true:**
> - the command set is extensible by hosts registering arbitrary native handlers (a plugin registry) instead of a closed, Crosswake-maintained vocabulary;
> - it requires a provider SDK, external account, or device certificate (that is companion or later-pack territory — StoreKit, APNs delivery, camera SDKs);
> - it needs durable host-owned data ownership beyond a route-scoped ephemeral request (that is companion or later-pack territory — e.g. notification-token *binding* is Chimeway, not Pack 1);
> - it has no meaningful non-native fallback, i.e. Crosswake becomes required for basic function (violates "runtime ownership is explicit," not mandatory);
> - it is high-frequency or streaming (camera feed, audio stream, live location) — that is capture/device territory, named and deferred.

**Applied to the 7 Pack 1 candidates:** alert/confirm — passes all six, IN. menu/action-button — passes all six provided actions resolve only through manifest-known route/command ids (same discipline as notification-open routing), IN. haptics — already core, passes, IN (hardening only). share — passes, IN, but needs honest per-platform support-truth language (handoff already flags this). toast/review-prompt — passes, IN, but must respect platform review-prompt rate limits (App Store `SKStoreReviewController` / Play `ReviewManager` throttling) as a documented rough edge, not silently ignored. `permissions.status` — already a read-only surface, stays IN as-is, zero new work. `notification_token` — fails (c)-style texture (its authority lives with Chimeway); Pack 1 treats it as a **doc pass on an existing companion's evidence**, not a new core command.

**Applied to deferred later packs:** capture/device (camera, scanner, document scan, NFC) fails (b)/(c) — high complexity, native-screen ownership, backend-verification proof not yet built — correctly deferred to Capture & Device Controls. Commerce/paywall fails (c)/(f) outright — provider SDK + backend-authority concerns already own that lane (StoreKit/Play Billing companions) — correctly deferred. Offline sync/native storage fails (c) (durable local state) — correctly deferred. Operator dashboard is a different axis entirely (maintainer-facing inspection tooling, not a route-local user affordance) — outside this rule's domain, its own arc.

## 3. Arc Coherence

**Steelmanning the alternative: `crosswake_dashboard` (DASH-01) as v20 instead of controls.**

The case: Threadline's audit ledger, telemetry-as-public-API, doctor/support-matrix, and `mix crosswake.release.status` are now substantial, dogfoodable machinery with **no visual surface** — a LiveDashboard plugin would compound directly on the v16-v18 release-integrity and audit investment, is lower architectural risk than new bridge surface (server-only, no new native contract, no catalog-drift exposure), is explicitly named with its own promotion trigger ("maintainer need for a self-contained inspection surface after support truth stabilizes"), and self-referentially proves the project's own "diagnostics are product surface" thesis. It is a genuinely defensible next wedge on its own merits, not a strawman.

**v20-controls still wins, on evidence, not default deference to the handoff:**
1. **Sequencing was purpose-built and just landed.** `MILESTONE-ARC.md`'s dependency graph states v19 precedes v20 *specifically* so "examples should expose the real capability gaps before Crosswake widens official native-control APIs" — v19 just shipped exactly that evidence (capability map, route-tour proof, this handoff). Skipping to the dashboard strands a freshly-produced, purpose-built input.
2. **Dashboard's own promotion criterion isn't met.** The named trigger is "after support truth stabilizes" — but native controls are about to add new support-matrix rows (proof posture, rebuild requirements, platform truth per control). Building the dashboard first means rebuilding it once Pack 1 lands; building Pack 1 first means the dashboard (whenever it comes) has a stable, larger support-truth surface to visualize.
3. **Adopter value vs. maintainer value.** The 2026-07-09 decision note in `MILESTONE-ARC.md` states the maintainer's actual stated goal directly: "a polished production-ready framework with native controls for common use cases... similar in category coverage to Hotwire Native Bridge Components." That is an external-adopter-facing goal; the dashboard is maintainer/operator-facing. Both matter, but the arc has already prioritized adopter-facing breadth after two release-integrity milestones (v18) built entirely for operator/maintainer trust — the pendulum should swing to adopter value now, not stay on operator tooling a third time.
4. **Risk timing.** The catalog-drift risk this document exists to guard against is highest *right after* a showcase milestone generates pressure to "just add the obvious stuff." Addressing it now, with the arc's guardrails freshly reinforced, is lower-risk than deferring it past another milestone.

**Verdict: endorse the handoff.** It is well-supported by independently re-derivable evidence (precedent, sequencing, stated adopter goal, risk timing) — not treated as scripture, but confirmed on its merits.

## 4. Scope Contract — the Wedge

**Named wedge: "Alert/Confirm + Menu/Action-Button on a shared Control Contract, with Haptics/Share hardened to the same grade as free riders."**

Two *new* command families are required to prove the shape generalizes — haptics and share are already precedent (they shipped in v3.1); hardening them to Pack-1 support-truth grade is valuable but does not exercise "add a wholly new command," so it cannot be the proof point alone. Alert/confirm and menu/action-button are the two most universally adopter-valuable UI affordances (confirmation dialogs and action menus appear in nearly every SaaS/admin flow — AdminPilot's approval routes are the direct showcase precedent) and they are genuinely new command shapes: alert/confirm is a native-UI-takeover-then-reply pattern; menu/action-button is a route-declared-allowlist-of-actions pattern. Together they stress two different contract shapes, which is what "cheap for 4..N" requires.

**Must be in the wedge (reusable machinery — the load-bearing part):**
- A shared control-contract shape (request/response envelope: route id, active-route id, capability, command, protocol version, origin, correlation id — already specified in the handoff's "Candidate Contract Requirements") implemented once as a common pattern/behaviour, not copy-pasted per control.
- A route-policy DSL declaration pattern for UI-affordance capabilities, reused (not reinvented) by every future control.
- A fallback-render helper pattern (LiveView-owned non-native equivalent) so every future control has an obvious non-native counterpart by construction, not by convention.
- A support-matrix/doctor/proof-lane wiring pattern that a new control can adopt by filling in data, not writing new plumbing.
- A **structural, merge-blocking test that enforces the catalog-line rule** (closed/enumerable command vocabulary, no dynamic handler registration) — the v3.4 "provider-vocabulary fence as a test" pattern, applied here as a "closed-command-vocabulary fence."

**Merely first instance (cheap to replicate after the wedge):** the specific alert/confirm semantics; the specific menu/action-button semantics; native iOS/Android implementations of those two. Controls 3-5 (harden haptics, harden share, add toast/review-prompt) become fast-follow work that fills in the same recipe rather than inventing new plumbing — mirroring how v16 proved extraction on rulestead/rindle before propagating to sigra/chimeway/threadline.

This satisfies all four asks: (a) proves the shape end-to-end via two wholly new commands through the full pipeline; (b) delivers real value standalone (confirm/menu affordances are broadly useful); (c) cannot be mistaken for a plugin catalog because the wedge *ships the catalog-line rule as a structural test*, not just prose; (d) leaves capture/device, commerce/paywall, offline-sync/native-storage, and operator-dashboard cleanly named with promotion criteria already established in the v19 handoff — carry them forward verbatim into v20's Out-of-Scope, don't re-litigate.

## 5. Anti-Scope for v20 (for REQUIREMENTS.md)

- **Camera, scanner, document-scan, NFC capture** — Fieldserv evidence shows real demand, but these need native-screen ownership and backend-verification proof that doesn't exist yet. Belongs to Capture & Device Controls; promote only after that pack's own proof lane exists.
- **Notification permission *request* UX** (only `permissions.status` read stays) — requesting OS permissions is a platform ceremony with review implications Pack 1 hasn't earned the right to own; ships read-only snapshot only.
- **APNs/FCM delivery assurance or any "notifications just work" claim** — Chimeway owns token binding and open-routing; core must never imply delivery guarantees it cannot prove.
- **StoreKit/Play Billing/RevenueCat production integration** — commerce authority stays backend-projected; provider-SDK productionization is its own later milestone (Commerce/Paywall Productionization), not a Pack 1 side quest.
- **Native storage budgets or durable local journals for content packs** — that's Offline Sync/Native Storage Productization; Pack 1 controls are ephemeral request/reply, never persistent local state.
- **Operator dashboard routes / `crosswake_dashboard`** — separate maintainer-facing arc, gated on support-truth stabilizing *after* Pack 1 ships, not folded in opportunistically because "we're touching support-matrix code anyway."
- **A generic bridge-command registry that lets host apps register arbitrary native handlers** — the entire point of Pack 1 is a closed, Crosswake-maintained vocabulary; "bring your own bridge command" is precisely the plugin bus this project has repeatedly ruled out.
- **A new `crosswake_controls` companion package** — tempting because extraction is now a familiar playbook, but per Section 1 these controls have no external dependency to gate; extracting anyway is process cargo-culting, not architecture.
- **Menu/action-button as a dynamic native-code injection point** (host-supplied closures registered at runtime) — actions must resolve only through manifest-known route/command ids, same discipline as notification-open routing (v3.9 precedent).
- **Manipulative or rate-limit-ignoring review-prompt/toast triggering** — must respect platform-imposed review-prompt throttling and stay honest UX evidence, never an engagement-gaming pattern.
- **Any claim that Pack 1 controls eliminate native rebuild requirements** — new bridge commands are additive capability-registry entries; support matrix must keep naming rebuild-required cases explicitly, consistent with the v14.0 compatibility precedent.

## 6. Requirement Categories

| Category | Focus | Reqs | Notes |
|----------|-------|------|-------|
| **CTRL** | Control-contract machinery (request/response envelope, route-policy declaration pattern, fallback-render helper, closed-vocabulary structural test) | 3-4 | **Load-bearing.** Must land green before any control ships — mirrors v17's DECOUPLE-before-extraction precedent. |
| **ALRT** | Alert/confirm command family: contract, iOS+Android implementation + fallback, proof/support-matrix wiring | 2-3 | First new-shape proof point. |
| **MENU** | Menu/action-button command family: route-declared allowlisted actions, iOS+Android implementation + fallback, proof | 2-3 | Second new-shape proof point; reuses CTRL machinery. |
| **HRDN** | Harden existing haptics/share to Pack-1 grade: platform support-truth completion, doctor/support-matrix parity, advisory→hardened promotion where evidenced | 2-3 | Fast-follow using CTRL recipe, not new plumbing. |
| **EVID** | Read-only evidence surfaces: `permissions.status` and `notification_token` documentation/support-truth pass | 2 | No new command surface — confines existing surfaces to honest language. |
| **PROOF** | Route-tour browser proof for all Pack 1 controls, native-shell proof-lane decision (Open Decision #5 from the handoff), capability-map/support-matrix regeneration feeding a v21 handoff | 2-3 | Closes the loop the same way v19's PROOF category did. |

CTRL is the load-bearing phase: like v17's core-decoupling gate or v16's extraction-recipe-on-two-packages, every other category depends on its contract shape, DSL pattern, and structural catalog-line test landing first.
