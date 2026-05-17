# Phase 6: Adopter Profile Matrix And Pressure Contract - Research

**Researched:** 2026-05-17
**Domain:** Public adopter-fit documentation and exemplar pressure planning for Crosswake
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
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

### Claude's Discretion
- Exact wording of profile blurbs, matrix cell copy, and guide-section titles.
- Exact module and route organization inside the shared example host, as long as profile lanes remain explicit and falsifiable.
- Exact representative route examples chosen for each profile, as long as they pressure the locked seams above and do not widen scope.
- Exact doc layout around the matrix, as long as support status remains in support docs and profile pressure remains in the Phase 6 artifact.

### Deferred Ideas (OUT OF SCOPE)
- Turning any of the exemplar lanes into a polished starter app, template, or copy-paste vertical sample.
- Widening `Selective Native Flow` into billing, entitlement, paywall, notification, or broad capability-broker proof in this milestone.
- Adding multiple offline-island archetypes, broad CRUD sync, collaborative sync, or background/offline media-transfer guarantees to the local-first lane.
- Creating separate full Phoenix/native host apps per profile unless later proof work proves the shared-host artifact class cannot carry a specific lane honestly.
- Adding new runtime classes or re-opening the route taxonomy during Phase 6.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROF-01 | Phoenix teams can inspect a published adopter-profile matrix that maps the three target app shapes to Crosswake runtime modes, required seams, and explicit non-goals. | Publish one lean guide with the locked seven-column matrix plus three short profile sections; keep support statuses and proof hook names out of the matrix itself. [CITED: .planning/REQUIREMENTS.md] [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md] |
| PROF-02 | Phoenix teams can tell which Crosswake surfaces each profile is meant to pressure before they run the exemplars. | Add per-profile pressure bullets and later-phase implications that point to shell, bridge, offline, packs, and shared example-host lanes. [CITED: .planning/REQUIREMENTS.md] [CITED: guides/native_shell.md] [CITED: guides/offline.md] [CITED: guides/packs.md] |
</phase_requirements>

## Summary

Phase 6 should ship a `public adopter-fit guide`, not a second support-truth table and not a sample-app specification. The current repo already separates `support_matrix.md` as proof/status truth from hand-authored behavior guides like `native_shell.md`, `offline.md`, `packs.md`, and `install.md`; Phase 6 should preserve that split by adding a lean matrix-and-prose guide that answers adopter-fit questions and points readers to existing proof surfaces for status details. [VERIFIED: codebase grep] [CITED: guides/support_matrix.md] [CITED: guides/native_shell.md] [CITED: guides/offline.md] [CITED: guides/packs.md] [CITED: guides/install.md]

The best artifact shape is one Markdown guide under `guides/` with exactly one matrix using the locked columns, followed by three short profile sections using the locked names `Phoenix SaaS Portal`, `Selective Native Flow`, and `Local-First Study Flow`. Each section should include representative routes, required seams, one failure vocabulary focus, proof posture summary, and explicit non-goals, because the phase context requires prose beside the table and later phases depend on a locked pressure contract. [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md] [CITED: .planning/ROADMAP.md] [CITED: .planning/REQUIREMENTS.md]

Phase 6 should avoid introducing new runtime classes, new canonical data structures, or template-grade example hosts. The repo already has one shared Phoenix example host with `:live_view`, packs, transfers, and one `:native_screen` route plus checked-in iOS and Android shell proof hooks; planning should treat those as the base artifact class and use Phase 6 only to define how later phases partition routes, fixtures, docs, and proof lanes by profile inside that shared structure. [CITED: examples/phoenix_host/lib/crosswake_example/router.ex] [CITED: script/verify_phase5_example_hosts.sh] [CITED: .planning/PROJECT.md] [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md]

**Primary recommendation:** Add `guides/adopter_profiles.md` as a hand-authored pressure guide, cross-link it from existing guides, and plan later exemplar work as lane additions inside the shared example host rather than as new starter apps. [VERIFIED: codebase grep] [CITED: guides/install.md] [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public adopter-profile matrix | Documentation guide | Support docs | Adopter-fit framing belongs in a hand-authored guide, while status truth already lives in `guides/support_matrix.md`. [VERIFIED: codebase grep] [CITED: guides/support_matrix.md] |
| Per-profile pressure contract | Documentation guide | Shared example host | The contract is described publicly in docs but must map to concrete route lanes and seams in the shared host. [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md] [CITED: examples/phoenix_host/lib/crosswake_example/router.ex] |
| Profile-lane isolation | Shared example host | Proof tooling | Later phases should separate routes/modules/fixtures/proof lanes inside one host instead of multiplying apps. [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md] [CITED: script/verify_phase5_example_hosts.sh] |
| Proof/update implications | Proof tooling | Documentation guide | The public install and support posture is already anchored on checked-in example hosts and scripts, so Phase 6 should prepare new proof hooks and guide crosslinks rather than invent a new proof surface. [CITED: guides/install.md] [CITED: guides/native_shell.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Markdown guides in `guides/` | repo-local | Public Phase 6 artifact surface | Existing adopter-facing behavior docs are hand-authored Markdown guides, so the new matrix belongs in the same surface. [VERIFIED: codebase grep] |
| Shared example host under `examples/phoenix_host` | repo-local | Downstream exemplar lane anchor | The repo already uses one checked-in Phoenix host as the public proof artifact class. [CITED: guides/install.md] [CITED: examples/phoenix_host/lib/crosswake_example/router.ex] |
| ExUnit docs/proof checks | repo-local | Guard against drift between docs and canonical truths | Existing tests already lock guide expectations and proof posture for support and offline claims. [VERIFIED: codebase grep] [CITED: test/crosswake/support_matrix/renderer_test.exs] [CITED: test/crosswake/offline/proof_lane_test.exs] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Crosswake.SupportMatrix.Renderer` | repo-local | Canonical status guide generation | Use only for `guides/support_matrix.md`; do not extend it to own the adopter-profile matrix. [CITED: lib/crosswake/support_matrix/renderer.ex] [CITED: test/crosswake/support_matrix/renderer_test.exs] |
| Existing guide set: `native_shell`, `offline`, `packs`, `install` | repo-local | Deep links for pressure details and proof posture | Use from the new profile guide to avoid duplicating behavior or status claims. [VERIFIED: codebase grep] [CITED: guides/native_shell.md] [CITED: guides/offline.md] [CITED: guides/packs.md] [CITED: guides/install.md] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| New hand-authored `guides/adopter_profiles.md` | Expand `guides/support_matrix.md` | Rejected because locked decisions keep status labels, baselines, and proof hook names in the support matrix, not in the profile matrix. [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md] |
| Shared example-host lane plan | Three separate sample apps | Rejected because the phase context locks one shared example host with hard-separated profile lanes as the primary artifact class. [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md] |
| Lean pressure matrix | Canonical generated matrix module | Rejected because only support-matrix truth is currently canonical/generated; behavior guides stay hand-authored. [VERIFIED: codebase grep] [CITED: lib/crosswake/support_matrix/renderer.ex] |

**Installation:**
```bash
# No new package installs are recommended for Phase 6.
# Reuse the existing Elixir/Phoenix, guides, tests, and example-host stack.
```

**Version verification:** No new external package versions are required for this phase; the recommended stack reuses repo-local guide, test, and example-host surfaces only. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
Adopter question
  -> guides/adopter_profiles.md
     -> Lean matrix:
        Profile
        Product shape
        Primary route classes
        Runtime ownership expectation
        Required seams
        What it pressures
        Explicit non-goals
     -> Per-profile prose sections
        -> Representative routes
        -> Failure/rough-edge focus
        -> Proof posture summary
        -> Links to support_matrix/native_shell/offline/packs/install
     -> Later-phase planning
        -> shared example-host route lanes
        -> profile-specific fixtures/modules
        -> future proof hooks/scripts/tests
```

The primary data flow for this phase is `adopter question -> profile guide -> linked support truth -> downstream exemplar lane planning`, not `manifest -> generated docs`. That split complements the existing renderer-backed support matrix instead of duplicating it. [CITED: guides/support_matrix.md] [CITED: lib/crosswake/support_matrix/renderer.ex]

### Recommended Project Structure
```text
guides/
├── adopter_profiles.md      # New Phase 6 public matrix + profile prose
├── support_matrix.md        # Existing status/proof truth
├── native_shell.md          # Existing SaaS/selective-native seam guide
├── offline.md               # Existing local-first seam guide
├── packs.md                 # Existing pack/transfer/native-capture seam guide
└── install.md               # Existing public install/proof path

examples/phoenix_host/lib/crosswake_example/
├── router.ex                # Shared lane entrypoint for later exemplar routes
└── ...profile modules...    # Later phases should split route modules by profile lane

script/
└── verify_phase5_example_hosts.sh   # Existing proof anchor to extend in later phases

test/crosswake/
└── ...docs/proof tests...    # Later phases should add guide integrity and profile-lane proof checks
```

### Pattern 1: Lean Matrix Plus Three Narrative Lanes
**What:** One matrix for comparison, followed by three small sections that explain why the profile exists and what it pressures. [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md]
**When to use:** Use for public adopter-fit and scope-setting docs where status truth already lives elsewhere. [CITED: guides/support_matrix.md]
**Example:**
```markdown
<!-- Source: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md -->
| Profile | Product shape | Primary route classes | Runtime ownership expectation | Required seams | What it pressures | Explicit non-goals |
|---------|---------------|-----------------------|-------------------------------|----------------|-------------------|--------------------|
| Phoenix SaaS Portal | Server-centric authenticated product surface | `:live_view` | Shell-hosted LiveView for most routes | bounded shell activation, one bridge affordance | denial UI, manifest-first route truth, support honesty | packs, offline islands, broad transfer seams |
```

### Pattern 2: Shared Example Host With Hard-Separated Profile Lanes
**What:** Keep one public Phoenix host and use route/module/fixture/proof separation per profile inside it. [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md]
**When to use:** Use for later exemplar phases so Crosswake proves architectural fit without turning into a starter-app catalog. [CITED: .planning/PROJECT.md] [CITED: .planning/seeds/SEED-001-example-app-stress-profiles.md]
**Example:**
```text
examples/phoenix_host/
  lib/crosswake_example/
    saas_portal/
    selective_native/
    local_first_study/
    router.ex
```

### Pattern 3: Cross-Link To Existing Truth Instead Of Re-Stating It
**What:** The profile guide should summarize proof posture in prose and then deep-link to the existing support/behavior guides for exact details. [VERIFIED: codebase grep]
**When to use:** Use whenever the new guide would otherwise repeat status labels, platform baselines, proof scripts, or bounded seam details. [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md]
**Example:**
```markdown
Proof posture:
This profile relies on the existing checked-in example-host contract and bounded shell truth.
Read `guides/support_matrix.md` for supported baselines and `guides/native_shell.md`
for denial and activation details.
```

### Anti-Patterns to Avoid
- **Support-matrix duplication:** Repeating status labels, platform baselines, or proof hook names in the adopter-profile matrix would violate locked decision D-09 and create drift against the canonical support matrix. [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md] [CITED: lib/crosswake/support_matrix/renderer.ex]
- **Starter-app drift:** Turning the guide into route-by-route app specs or turning later phases into three standalone sample apps would violate the shared-host and no-template decisions. [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md] [CITED: .planning/PROJECT.md]
- **Runtime-blur wording:** Any wording that markets Crosswake as a generic wrapper or plugin bus conflicts with the project thesis and brand guardrails. [CITED: .planning/PROJECT.md] [CITED: prompts/crosswake-brand-book.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Profile support status | A second canonical status table | Link to `guides/support_matrix.md` | Support status is already canonical, generated, and mechanically checked. [CITED: guides/support_matrix.md] [CITED: lib/crosswake/support_matrix/renderer.ex] |
| Exemplar artifact class | Three separate demo apps | One shared example host with lane separation | The milestone is about pressure and hardening, not starter-app productization. [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md] [CITED: .planning/seeds/SEED-001-example-app-stress-profiles.md] |
| New runtime or capability taxonomy | Fresh profile-specific abstractions | Existing route classes and declared seams | Locked decisions keep Phase 6 on already-declared seams only. [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md] |
| New proof system for docs | Bespoke scripts detached from existing proof hooks | Extend current example-host scripts/tests later | Install truth and proof posture are already anchored on checked-in example hosts. [CITED: guides/install.md] [CITED: script/verify_phase5_example_hosts.sh] |

**Key insight:** Phase 6 is strongest when it `routes adopters to the right existing truths` and `locks later exemplar pressure targets`; it gets weaker each time it tries to become a second status registry, a template catalog, or a new architecture layer. [CITED: .planning/PROJECT.md] [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Turning The Matrix Into A Second Support Matrix
**What goes wrong:** The table starts carrying `supported` labels, platform baselines, or proof hook names. [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md]
**Why it happens:** The repo already has a matrix-shaped support artifact, so it is easy to reuse that visual pattern for a different job. [CITED: guides/support_matrix.md]
**How to avoid:** Keep the Phase 6 matrix limited to the locked seven columns and push status details into support or behavior guides. [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md]
**Warning signs:** The draft includes `supported`, `verification required`, iOS/Android version floors, or exact script names inside matrix cells. [CITED: guides/support_matrix.md]

### Pitfall 2: Letting Profile Names Drift Into Market Buckets
**What goes wrong:** Public docs rename the profiles to generic buckets like “subscription app” or “learning app.” [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md]
**Why it happens:** Market labels feel natural for example apps, but they create expectations around billing, vendor integrations, or starter-app scope. [CITED: .planning/PROJECT.md] [CITED: prompts/crosswake-brand-book.md]
**How to avoid:** Use the locked names verbatim and keep the copy route-local and behavioral. [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md]
**Warning signs:** Draft headings introduce new top-level nouns that are not `Phoenix SaaS Portal`, `Selective Native Flow`, or `Local-First Study Flow`. [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md]

### Pitfall 3: Drifting Into Starter-App Specification
**What goes wrong:** The artifact starts enumerating broad app features, full IA trees, or vendor-heavy flows. [CITED: .planning/PROJECT.md]
**Why it happens:** Example planning naturally expands unless hard route-count and seam limits are enforced. [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md]
**How to avoid:** Keep each profile tied to one believable job-to-be-done, roughly 4-8 routes, and already-declared Crosswake seams only. [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md]
**Warning signs:** Billing, entitlement systems, broad CRUD sync, plugin brokers, or multiple native-screen categories appear in Phase 6 planning. [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md]

### Pitfall 4: Weak Downstream Handoff To Phases 7-10
**What goes wrong:** The guide reads well but leaves later phases to rediscover routes, seams, and rough-edge targets. [CITED: .planning/ROADMAP.md]
**Why it happens:** Public docs and internal planning often get separated, so the phase stops at copywriting. [VERIFIED: codebase grep]
**How to avoid:** Give each profile a short “pressures” list, representative routes, and explicit non-goals that map directly to the next phases. [CITED: .planning/REQUIREMENTS.md] [CITED: .planning/ROADMAP.md]
**Warning signs:** Phase 7-10 planning would still need to decide what each profile is actually meant to prove. [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md]

## Code Examples

Verified patterns from repo sources:

### Public Guide Skeleton
```markdown
<!-- Source: guides/support_matrix.md + .planning/phases/06.../06-CONTEXT.md -->
# Crosswake Adopter Profiles

This guide helps Phoenix teams answer which mobile product shape Crosswake is meant
to pressure first. It complements `guides/support_matrix.md`, which remains the
source of exact support status and proof-backed baselines.

## Adopter Profile Matrix

| Profile | Product shape | Primary route classes | Runtime ownership expectation | Required seams | What it pressures | Explicit non-goals |
|---------|---------------|-----------------------|-------------------------------|----------------|-------------------|--------------------|
| Phoenix SaaS Portal | ... | ... | ... | ... | ... | ... |
| Selective Native Flow | ... | ... | ... | ... | ... | ... |
| Local-First Study Flow | ... | ... | ... | ... | ... | ... |

## Phoenix SaaS Portal
- Representative routes: ...
- Rough-edge cautions: ...
- Proof posture summary: ...
- Why this profile exists: ...
```

### Later Lane Layout In Shared Example Host
```text
# Source: examples/phoenix_host/lib/crosswake_example/router.ex + 06-CONTEXT.md
/account/*
  -> Phoenix SaaS Portal lane
/capture/*
  -> Selective Native Flow lane
/study/*
  -> Local-First Study Flow lane
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| “Example apps” as broad demos or templates | One shared example host with hard-separated adopter lanes | Milestone v2.0 kickoff on 2026-05-17 | Keeps exemplar pressure realistic without turning Crosswake into starter-app product surface. [CITED: .planning/PROJECT.md] [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md] |
| Status matrix as a catch-all public matrix | Support matrix for proof/status truth, profile matrix for adopter-fit and pressure | Locked in Phase 6 context on 2026-05-17 | Prevents status drift and keeps the support matrix narrow and canonical. [CITED: guides/support_matrix.md] [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md] |

**Deprecated/outdated:**
- Treating the selective-native lane as a generic “subscription app” bucket is outdated for this milestone because the locked public name is `Selective Native Flow` and vendor-heavy scope is deferred. [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `guides/adopter_profiles.md` is the best exact filename for the new public guide. [ASSUMED] | Summary, Architecture Patterns | Low; renaming the file later is cheap, but planners would need to update link targets. |
| A2 | Later profile-lane tests will likely live under `test/crosswake/` beside existing guide/proof tests rather than under a new test app namespace. [ASSUMED] | Recommended Project Structure | Low; test path can move, but slice boundaries still stand. |

## Open Questions

1. **Should the new guide be linked from `guides/install.md`, `guides/compatibility.md`, or both?**
   - What we know: `install.md` already acts as a public guide map, and current tests lock some of those cross-links. [CITED: guides/install.md] [CITED: test/crosswake/support_matrix/renderer_test.exs]
   - What's unclear: The repo has no top-level README guide index, so the best discoverability link target is a repo-local choice. [VERIFIED: codebase grep]
   - Recommendation: Plan one slice that adds the guide, then a second small slice that wires links from `install.md` and whichever adjacent guide best matches the new profile framing. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Authentication implementation is not a Phase 6 deliverable; the SaaS profile only documents authenticated route pressure. [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md] |
| V3 Session Management | no | Session mechanics are not changed in Phase 6; only support posture and exemplar pressure are documented. [CITED: .planning/ROADMAP.md] |
| V4 Access Control | yes | Keep route allowlists, active-route checks, and fail-closed native ownership language explicit in profile docs. [CITED: guides/native_shell.md] [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md] |
| V5 Input Validation | yes | Preserve route-local, typed, existing seam vocabulary instead of broadening docs into implied generic capability access. [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md] [CITED: prompts/crosswake-brand-book.md] |
| V6 Cryptography | no | Phase 6 does not add crypto surfaces. [VERIFIED: codebase grep] |

### Known Threat Patterns for Crosswake profile docs

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Overbroad bridge implication from profile copy | Elevation of privilege | Keep bridge language bounded to existing declared capabilities and route-local seams. [CITED: guides/native_shell.md] [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md] |
| Generic WebView-wrapper interpretation | Spoofing | Repeat explicit runtime ownership and fail-closed denial posture in profile prose. [CITED: .planning/PROJECT.md] [CITED: prompts/crosswake-brand-book.md] |
| Offline overclaim in local-first lane | Tampering | Keep cached read-only and offline-island stories separate and reuse the existing replay/conflict vocabulary. [CITED: guides/offline.md] [CITED: .planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)
- `.planning/PROJECT.md` - milestone thesis, no-template boundary, shared example-host posture
- `.planning/REQUIREMENTS.md` - `PROF-01`, `PROF-02`, and downstream exemplar requirements
- `.planning/ROADMAP.md` - Phase 6-10 goals and dependencies
- `.planning/STATE.md` - current concerns about exemplar drift and proof sensitivity
- `.planning/phases/06-adopter-profile-matrix-and-pressure-contract/06-CONTEXT.md` - locked decisions for names, matrix schema, shared-host posture, and non-goals
- `.planning/seeds/SEED-001-example-app-stress-profiles.md` - seed rationale for stress-test exemplars rather than templates
- `guides/support_matrix.md` - existing proof/status truth surface
- `guides/native_shell.md` - bounded shell, denial, and bridge posture
- `guides/offline.md` - narrow cached read-only and offline-island posture
- `guides/packs.md` - pack, transfer, and native-capture seam posture
- `guides/install.md` - public install path and example-host proof anchor
- `examples/phoenix_host/lib/crosswake_example/router.ex` - current shared example-host topology
- `script/verify_phase5_example_hosts.sh` - current proof-lane anchor
- `lib/crosswake/support_matrix/renderer.ex` - canonical generated support-matrix pattern
- `test/crosswake/support_matrix/renderer_test.exs` - docs integrity checks around support/install guides
- `test/crosswake/offline/proof_lane_test.exs` - docs integrity checks around offline/support posture
- `prompts/crosswake-brand-book.md` - public language and anti-wrapper guardrails
- `prompts/crosswake-elixir-oss-dna.md` - install truth, support honesty, proof-lane posture
- `prompts/crosswake-gsd-project-brief.md` - Phoenix-first route-policy architecture brief
- `prompts/crosswake-research-synthesis.md` - stable architecture story and anti-patterns

### Secondary (MEDIUM confidence)
- None.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Phase 6 reuses existing repo-local docs, tests, and example-host patterns rather than introducing new dependencies.
- Architecture: HIGH - The locked Phase 6 context is specific about names, matrix schema, shared-host posture, and non-goals.
- Pitfalls: HIGH - Support-matrix duplication, starter-app drift, and runtime-blur risks are directly documented in project and phase context.

**Research date:** 2026-05-17
**Valid until:** 2026-06-16
