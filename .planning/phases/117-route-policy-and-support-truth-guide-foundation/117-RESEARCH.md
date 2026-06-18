# Phase 117: Route-Policy And Support-Truth Guide Foundation - Research

**Researched:** 2026-06-18  
**Domain:** Crosswake documentation architecture, route-policy DSL truth, ExDoc navigation, support-matrix rendering  
**Confidence:** HIGH for repo-local findings; MEDIUM for exact final copy choices

<user_constraints>
## User Constraints (from CONTEXT.md)

All items in this section are copied from `.planning/phases/117-route-policy-and-support-truth-guide-foundation/117-CONTEXT.md`. [VERIFIED: .planning/phases/117-route-policy-and-support-truth-guide-foundation/117-CONTEXT.md]

### Locked Decisions

## Implementation Decisions

### Route-Policy Start-Here Guide

- **D-01:** Add a dedicated `guides/route_policy.md` as the GUIDE-01 anchor instead of relying only on `guides/user_flows.md`. The existing `guides/user_flows.md` should remain the narrative/JTBD ramp and link into the route-policy guide; do not delete or bury its strongest "Who should own this route?" framing.
- **D-02:** Open the route-policy guide with Crosswake's one job: declare, enforce, and diagnose which runtime owns each route as a Phoenix app crosses into mobile. Owner selection comes before syntax.
- **D-03:** The guide must cover the full owner decision set in one place: plain `:live_view`, `:live_view` with a bounded bridge affordance, cached read-only routes, `:offline_island`, `:native_screen`, backend/provider seams, and explicit defers.
- **D-04:** Each owner class should include a current route-policy example and the downstream truth it creates: manifest fields, doctor/support posture, denial/fallback behavior, and the rough edge it intentionally does not hide.
- **D-05:** Route-policy examples should use current semantic fields from the DSL (`runtime`, `offline`, `entry`, `capabilities`, `cache_contract`, `island_contract`, `packs`, `sync`, `transfers`, `security`, `gated_by`, `on_unavailable`, `auth_*`, and notification-open posture where relevant). Do not invent a simplified pseudo-DSL that downstream docs later need to unwind.
- **D-06:** Keep capability discussion subordinate to route ownership. The guide may mention `haptics`, `app_info`, `share`, `file_picker`, `media_capture`, commerce, auth, notification, and media evidence only to show why their owner class matters. It must not read like a plugin catalog.

### Web-To-Mobile Migration Guide

- **D-07:** Add `guides/web_to_mobile_migration.md` for MIGRATE-01. Frame it as an operational route inventory guide for existing Phoenix SaaS teams, not a general mobile rewrite essay.
- **D-08:** The migration guide should default most routes to Phoenix/LiveView first. Promotion requires a concrete reason: one degradable bounded native affordance, read-only degraded use, true local mutation/replay, native-owned device session, backend/provider authority, or defer.
- **D-09:** Organize the migration guide around passes: inventory routes by user job, assign an initial owner, add only required seams, run doctor/support checks, then capture evidence for only the owner classes the app actually uses.
- **D-10:** Include a "do not migrate this" section. It should explicitly reject moving normal SaaS forms native just because the app is mobile, high-frequency client authority through the bridge, cached LiveView pages as offline mutation, device/provider events as authority without backend reconciliation, and local native hosts as published-coordinate proof.
- **D-11:** Keep this guide concise and connected. Link to `guides/route_policy.md`, `guides/bridge.md`, `guides/offline.md`, `guides/native_shell.md`, `guides/capabilities.md`, `guides/compatibility.md`, and `guides/support_matrix.md` instead of duplicating their reference material.

### Support-Truth Vocabulary

- **D-12:** Add a friendly first-read support-truth legend before sending readers into the dense support matrix. This can live in README plus the support matrix intro; a separate `guides/support_truth.md` is acceptable only if planning finds it improves navigation without creating a second source of truth.
- **D-13:** Keep `guides/support_matrix.md` canonical. If its intro or legend changes, update the generator/source (`lib/crosswake/support_matrix/renderer.ex` and/or canonical support data) and tests rather than hand-editing generated output into drift.
- **D-14:** Use one vocabulary across README, guide map, ExDoc groups, matrix intro, and future artifact captions: merge-blocking proof, advisory evidence, local-dev proof, generated public-coordinate proof, JVM hermetic proof, emulator evidence, device evidence, verification-required, and rebuild-required.
- **D-15:** Define every support label by both what it proves and what it does not prove. In particular: "supported" is not the same as device-verified; JVM hermetic proof is not emulator or physical-device proof; emulator evidence is not physical-device proof; local-dev proof is not published-coordinate proof; visual collateral is not correctness proof by itself.
- **D-16:** Avoid vague support copy such as "Verified Android", "native support", or "offline support" without a proof class. Prefer exact labels such as "Android JVM hermetic proof", "advisory emulator evidence", "cached read-only", or "offline island with app-owned outbox".

### README, Guide Map, And ExDoc Wiring

- **D-17:** README should stay compact. It should promote the one-job route-policy sentence, point evaluators to the new route-policy/start-here path, include or link the support-truth label legend, and keep the detailed doctrine in guides.
- **D-18:** Update `mix.exs` ExDoc extras and groups so the guide path matches how adopters read: Start, Adopt, Runtime Owners, Truth, and Advanced/Companions. Keep `README.md` as the HexDocs landing page.
- **D-19:** New guides added to ExDoc extras must be real files in the same change. The package `files` already includes `guides`, but planners should preserve the established "extras and shipped guide files move together" discipline to avoid HexDocs drift.
- **D-20:** README, install guide, and guide maps should point to `guides/route_policy.md` and `guides/web_to_mobile_migration.md` before asking readers to decode the full support matrix. The support matrix remains the canonical reference after the first-read legend.
- **D-21:** Phase 117 may add or update cheap docs-contract tests if they pin guide presence, ExDoc grouping, support-label vocabulary, or support-matrix rendering parity. Do not absorb Phase 118's quick-start/adoption drift guard or Phase 119's native coordinate guard.

### Phase Boundary With 118-120

- **D-22:** Do not rewrite `examples/QUICK_START.md` or `guides/adoption.md` in full during Phase 117. Phase 118 owns command verification, current port/path/setup commands, and the v12 IndexedDB outbox/reconnect/Ecto adoption rewrite.
- **D-23:** Do not settle whether checked-in iOS/Android hosts are published-coordinate proof or local-development proof during Phase 117. Phase 119 owns that evidence-label decision. Phase 117 can define the vocabulary and avoid overclaiming.
- **D-24:** Do not capture screenshots, recordings, artifact manifests, or full troubleshooting examples during Phase 117. Phase 120 owns collateral and troubleshooting. Phase 117 should provide the vocabulary those artifacts will use.
- **D-25:** Maintain Crosswake's voice: precise, short, example-heavy, and candid. Avoid "magic", "just works", "native mobile with no native work", "everything works offline", "plugin", "WebView wrapper", and any phrase that hides route ownership or proof class.

### the agent's Discretion

The user delegated Phase 117 discussion decisions to Claude after the initial workflow prompt. Downstream agents may choose exact file names only within these bounds: `guides/route_policy.md` and `guides/web_to_mobile_migration.md` are the recommended defaults; a support-truth helper guide is optional and must not replace the canonical support matrix. Planners may decide exact ExDoc group labels if they preserve the Start / Adopt / Runtime Owners / Truth / Advanced reading order.

### Deferred Ideas (OUT OF SCOPE)

- Full command-verified `examples/QUICK_START.md` rewrite remains Phase 118.
- Full `guides/adoption.md` rewrite around app-owned IndexedDB outbox, reconnect-triggered `flushOutbox`, `/study/sync`, Ecto idempotency, outbox deletion, and conflict semantics remains Phase 118.
- Quick-start/adoption drift guard for wrong commands, port/path claims, `Crosswake.mutate`, and bridge-owned offline mutation language remains Phase 118.
- Checked-in iOS/Android host evidence classification, native guide reconciliation, Android UAT relabeling, and native coordinate drift guard remain Phase 119.
- Browser/native screenshots, recordings, artifact manifests, advisory native capture, and full troubleshooting/rough-edge examples remain Phase 120.
- DASH-01 and NTV-01 remain deferred unless v13 later proves they are necessary for adopter evidence visibility.
</user_constraints>

## Project Constraints (from AGENTS.md)

- Crosswake must stay a Phoenix-first route-policy and runtime-contract system, not a universal UI framework. [VERIFIED: AGENTS.md]
- Runtime ownership must stay explicit per route; do not collapse docs into generic WebView wrapper behavior or LiveView-driven native rendering. [VERIFIED: AGENTS.md]
- Bridge contracts must remain semantic, typed, versioned, and low-frequency; continuous client authority belongs outside the bridge. [VERIFIED: AGENTS.md]
- Offline claims must distinguish cached read-only behavior from true local-first mutation with journals, outboxes, and reconciliation. [VERIFIED: AGENTS.md]
- Diagnostics, support matrices, proof lanes, and rough-edge documentation are product surface. [VERIFIED: AGENTS.md]
- v1 scope boundaries in `.planning/PROJECT.md` and `.planning/REQUIREMENTS.md` constrain integrations and native breadth. [VERIFIED: AGENTS.md]
- No project-local skills were found under `.codex/skills/` or `.agents/skills/`. [VERIFIED: filesystem discovery]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GUIDE-01 | Public adopter guide path explains Crosswake's one job and covers route-owner classes with current examples and links to manifest/doctor/support truth. | Add `guides/route_policy.md`, reuse `guides/user_flows.md` and actual route declarations from `examples/phoenix_host/lib/crosswake_example/router.ex`; source fields from `lib/crosswake/policy/schema.ex` and `lib/crosswake/policy/route.ex`. [VERIFIED: .planning/REQUIREMENTS.md, guides/user_flows.md, examples/phoenix_host/lib/crosswake_example/router.ex, lib/crosswake/policy/schema.ex, lib/crosswake/policy/route.ex] |
| MIGRATE-01 | Web-to-mobile migration guide helps existing Phoenix SaaS teams inventory routes and promote only justified seams. | Add `guides/web_to_mobile_migration.md`, use the three adopter profiles and the route-by-route decision questions already present. [VERIFIED: .planning/REQUIREMENTS.md, guides/adopter_profiles.md, guides/user_flows.md] |
| TRUTH-01 | README, ExDoc grouping, support matrix entry points, and guide maps use one support-truth vocabulary with a friendly legend before the dense matrix. | Update compact README/guide links, `mix.exs` extras/groups, and support matrix renderer/guide/tests together; current renderer parity tests already enforce generated output. [VERIFIED: .planning/REQUIREMENTS.md, README.md, mix.exs, lib/crosswake/support_matrix/renderer.ex, test/crosswake/support_matrix/renderer_test.exs] |
</phase_requirements>

## Summary

Phase 117 is a documentation-architecture phase with live code contracts behind it: the planner should add two new guide files, wire them into README/ExDoc navigation, and make support-truth labels readable without changing product behavior. [VERIFIED: .planning/ROADMAP.md, .planning/phases/117-route-policy-and-support-truth-guide-foundation/117-CONTEXT.md]

The strongest reusable material already exists in `guides/user_flows.md` and `guides/adopter_profiles.md`; the new `route_policy.md` should promote that route-owner framing and add current DSL examples rather than replacing it. [VERIFIED: guides/user_flows.md, guides/adopter_profiles.md]

The highest-risk implementation area is `guides/support_matrix.md`: it is generated by `Crosswake.SupportMatrix.Renderer.render/1`, has byte-identity tests, and currently fails parity because the on-disk intro differs from the renderer intro. [VERIFIED: lib/crosswake/support_matrix/renderer.ex, test/crosswake/support_matrix/renderer_test.exs, command `mix test test/crosswake/support_matrix/renderer_test.exs test/crosswake/support_matrix/support_matrix_test.exs`]

**Primary recommendation:** Plan 117 as docs plus docs-contract work: 117-01 owns `guides/route_policy.md`, 117-02 owns `guides/web_to_mobile_migration.md`, and 117-03 owns support-truth vocabulary, README/ExDoc wiring, renderer parity, and tests. [VERIFIED: .planning/ROADMAP.md, .planning/phases/117-route-policy-and-support-truth-guide-foundation/117-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Route-policy first-read guide | Docs / HexDocs | Policy + Manifest + Doctor source | The guide is public documentation, but examples must match route policy schema, manifest output, and doctor posture. [VERIFIED: mix.exs, lib/crosswake/policy/schema.ex, lib/crosswake/manifest/builder.ex, lib/crosswake/doctor/doctor.ex] |
| Web-to-mobile migration guide | Docs / HexDocs | Existing adopter guide set | Migration guidance should classify route jobs and link reference guides instead of changing runtime code. [VERIFIED: guides/user_flows.md, guides/adopter_profiles.md, guides/bridge.md, guides/offline.md, guides/native_shell.md] |
| Support-truth legend and matrix intro | Support matrix source | README + guides + ExDoc | The canonical matrix is rendered from `Crosswake.SupportMatrix.canonical()` through `Renderer.render/1`; public docs consume that truth. [VERIFIED: lib/crosswake/support_matrix/support_matrix.ex, lib/crosswake/support_matrix/renderer.ex, guides/support_matrix.md] |
| ExDoc navigation | `mix.exs` docs config | Guide files | `mix.exs` sets `main: "readme"`, lists extras, and groups extras; new guide files must be present before being listed. [VERIFIED: mix.exs] |
| Phase validation | ExUnit docs-contract tests | `mix docs` smoke | Existing guide/support tests assert guide wiring, support-matrix byte parity, and release-truth boundaries. [VERIFIED: test/crosswake/guides/user_flows_test.exs, test/crosswake/guides/adopter_profiles_test.exs, test/crosswake/guides/release_boundaries_test.exs, test/crosswake/support_matrix/renderer_test.exs] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 | Compile and run ExUnit docs-contract tests. | Project declares Elixir `~> 1.19`, and local runtime is Elixir/Mix 1.19.5. [VERIFIED: mix.exs, command `elixir --version`, command `mix --version`] |
| Phoenix | 1.8.7 locked | Route examples and Phoenix-first docs context. | Crosswake extends Phoenix route ownership rather than replacing Phoenix. [VERIFIED: mix.exs, mix.lock, README.md] |
| Phoenix LiveView | 1.1.30 locked | LiveView route-owner examples. | LiveView remains the server-owned baseline route class. [VERIFIED: mix.exs, mix.lock, guides/user_flows.md] |
| ExDoc | 0.40.3 locked | HexDocs extras, grouping, and docs generation. | `mix.exs` centralizes public extras and groups for HexDocs. [VERIFIED: mix.exs, mix.lock] |
| ExUnit | Elixir bundled | Docs-contract and support-matrix tests. | Existing tests already guard guide wiring and support truth. [VERIFIED: test/crosswake/guides/user_flows_test.exs, test/crosswake/support_matrix/renderer_test.exs] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| NimbleOptions | 1.1.1 locked | Route-policy option schema validation. | Use as the source for allowed route-policy fields and values in guide examples. [VERIFIED: mix.exs, mix.lock, lib/crosswake/policy/schema.ex] |
| Jason | 1.4.5 locked | Manifest/support JSON in existing tests and tools. | Relevant only when tests inspect manifest JSON, not for guide authoring. [VERIFIED: mix.exs, mix.lock, test/crosswake/guides/release_boundaries_test.exs] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| New docs generator | Markdown guide files plus ExDoc extras | Use the existing Markdown + ExDoc path; adding another docs system would create a second source of truth. [VERIFIED: mix.exs, guides/*.md] |
| Hand-written support matrix | `Crosswake.SupportMatrix.Renderer` | Hand edits break byte-parity tests and drift from canonical support data. [VERIFIED: lib/crosswake/support_matrix/renderer.ex, test/crosswake/support_matrix/renderer_test.exs] |
| New support-label package | Existing support matrix data and renderer | No package install is needed for this phase. [VERIFIED: .planning/phases/117-route-policy-and-support-truth-guide-foundation/117-CONTEXT.md, mix.exs] |

**Installation:**

```bash
# No new packages for Phase 117.
```

**Version verification:** Existing dependency versions were verified from `mix.exs`, `mix.lock`, `elixir --version`, and `mix --version`. [VERIFIED: mix.exs, mix.lock, command output]

## Package Legitimacy Audit

Phase 117 should not install external packages. [VERIFIED: .planning/phases/117-route-policy-and-support-truth-guide-foundation/117-CONTEXT.md]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | n/a | n/a | n/a | n/a | n/a | No install planned. [VERIFIED: mix.exs, phase scope] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: no new packages planned]  
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no new packages planned]

## Architecture Patterns

### System Architecture Diagram

```text
README / HexDocs landing
  -> route-policy start path
  -> guides/route_policy.md
     -> route owner decision examples
     -> Crosswake.Policy.Schema / Route validations
     -> Manifest.Builder route entries and capability registry
     -> Doctor posture and denial/support findings
     -> guides/support_matrix.md canonical reference

README / HexDocs landing
  -> guides/web_to_mobile_migration.md
     -> route inventory by user job
     -> default to :live_view
     -> promote to bounded bridge / cached read-only / offline island / native screen / backend seam / defer
     -> run doctor and inspect support matrix

Crosswake.SupportMatrix.canonical()
  -> Renderer.render/1
  -> guides/support_matrix.md
  -> renderer byte-parity tests
  -> README / ExDoc / future artifact label vocabulary
```

This diagram describes documentation and support-truth data flow, not file ownership. [VERIFIED: README.md, mix.exs, lib/crosswake/support_matrix/renderer.ex, test/crosswake/support_matrix/renderer_test.exs]

### Recommended Project Structure

```text
guides/
├── route_policy.md                 # new GUIDE-01 anchor
├── web_to_mobile_migration.md      # new MIGRATE-01 anchor
├── user_flows.md                   # preserve JTBD/start-here narrative
├── adopter_profiles.md             # preserve profile examples
└── support_matrix.md               # generated canonical support truth

lib/crosswake/support_matrix/
├── support_matrix.ex               # canonical support data
└── renderer.ex                     # generated Markdown intro/legend/tables

test/crosswake/guides/
├── route_policy_test.exs           # recommended new docs-contract test
├── web_to_mobile_migration_test.exs# recommended new docs-contract test
└── release_boundaries_test.exs     # existing release/support boundary guard

test/crosswake/support_matrix/
├── renderer_test.exs               # update when legend/intro changes
└── support_matrix_test.exs         # update only if canonical data changes
```

The new guide tests do not exist yet and should be Wave 0 tasks in the relevant plans. [VERIFIED: filesystem discovery, existing tests]

### Pattern 1: Source-Backed Route Examples

**What:** Use real Crosswake router declarations in examples, with exact DSL fields from `Crosswake.Policy.Schema`. [VERIFIED: lib/crosswake/policy/schema.ex, examples/phoenix_host/lib/crosswake_example/router.ex]

**When to use:** Every owner-class example in `guides/route_policy.md`. [VERIFIED: 117-CONTEXT.md D-04/D-05]

**Example:**

```elixir
# Source: examples/phoenix_host/lib/crosswake_example/router.ex
live("/approvals/:id", ApprovalLive,
  crosswake: [
    id: "saas-approval",
    runtime: :live_view,
    entry: :external,
    capabilities: ["haptics.impact"],
    offline: :cached_read_only,
    security: :standard
  ]
)
```

### Pattern 2: Offline Claims Split By Contract

**What:** `cache_contract` belongs to cached read-only routes, and `island_contract` belongs to `runtime: :offline_island` with `offline: :local_first`. [VERIFIED: lib/crosswake/policy/route.ex]

**When to use:** Route-policy guide and migration guide explanations of cached read-only vs local-first mutation. [VERIFIED: guides/offline.md, guides/user_flows.md]

**Example:**

```elixir
# Source: test/support/router_fixtures.ex
live "/study-session", Crosswake.TestSupport.StudySessionLive,
  crosswake: [
    id: "study-session",
    runtime: :offline_island,
    offline: :local_first,
    island_contract: :study_session_v1,
    packs: [[id: :study_session_media, version: "3.0.0", kind: :media]],
    sync: [:study_reviews]
  ]
```

### Pattern 3: Generated Support Matrix

**What:** Change matrix intro/legend in the renderer and keep `guides/support_matrix.md` byte-identical to `Renderer.render(SupportMatrix.canonical())`. [VERIFIED: lib/crosswake/support_matrix/renderer.ex, test/crosswake/support_matrix/renderer_test.exs]

**When to use:** Any support-truth legend or matrix entry-point change in 117-03. [VERIFIED: 117-CONTEXT.md D-13]

**Example:**

```elixir
# Source: lib/crosswake/support_matrix/renderer.ex
rendered = Crosswake.SupportMatrix.Renderer.render(Crosswake.SupportMatrix.canonical())
on_disk = File.read!("guides/support_matrix.md")
assert rendered == on_disk
```

### Pattern 4: ExDoc Extras Move With Files

**What:** Add new guide files to `mix.exs` `extras` only when the files exist, then group extras by reader task. [VERIFIED: mix.exs, 117-CONTEXT.md D-18/D-19]

**When to use:** 117-03, after 117-01 and 117-02 create the new guide files. [VERIFIED: .planning/ROADMAP.md wave ordering]

**Example target shape:**

```elixir
# Source pattern: mix.exs docs/0
groups_for_extras: [
  Start: ["README.md", "guides/user_flows.md"],
  Adopt: ["guides/install.md", "guides/route_policy.md", "guides/web_to_mobile_migration.md"],
  "Runtime Owners": ["guides/bridge.md", "guides/offline.md", "guides/native_shell.md"],
  Truth: ["guides/support_matrix.md", "guides/compatibility.md"]
]
```

The labels may vary, but the Start -> Adopt -> Runtime Owners -> Truth -> Advanced reading order is locked by context. [VERIFIED: 117-CONTEXT.md]

### Anti-Patterns To Avoid

- **Pseudo-DSL examples:** They hide real validation constraints and create downstream docs debt. Use current schema fields. [VERIFIED: 117-CONTEXT.md D-05, lib/crosswake/policy/schema.ex]
- **Second support matrix:** A helper legend is allowed only if it does not replace `guides/support_matrix.md` as canonical. [VERIFIED: 117-CONTEXT.md D-12/D-13]
- **Capability catalog positioning:** Capability families should explain route ownership, not become the guide's organizing principle. [VERIFIED: 117-CONTEXT.md D-06, guides/capabilities.md]
- **Phase scope absorption:** Do not do Phase 118 quick-start/adoption rewrite, Phase 119 native evidence decision, or Phase 120 collateral/troubleshooting capture. [VERIFIED: 117-CONTEXT.md D-22/D-24]

## Source-Of-Truth Field Map

| Field / Concept | Current Truth | Guide Use |
|-----------------|---------------|-----------|
| `runtime` | Allowed values are `:live_view`, `:offline_island`, and `:native_screen`; `:adapter` is reserved future extension. [VERIFIED: lib/crosswake/policy/schema.ex] | Explain route owner choices around these three current runtime owners. |
| `offline` | Allowed values are `:unavailable`, `:cached_read_only`, and `:local_first`. [VERIFIED: lib/crosswake/policy/schema.ex] | Distinguish no offline, cached reads, and local-first mutation. |
| `entry` | Allowed values are `:internal_only` and `:external`; external entry is not supported on offline-island routes. [VERIFIED: lib/crosswake/policy/schema.ex, lib/crosswake/policy/route.ex] | Use for deep link / notification / shell entry examples. |
| `cache_contract` | Requires `offline: :cached_read_only`. [VERIFIED: lib/crosswake/policy/route.ex] | Use for cached read-only routes only. |
| `island_contract` | Requires `runtime: :offline_island` with `offline: :local_first`. [VERIFIED: lib/crosswake/policy/route.ex] | Use for the offline island example. |
| `capabilities` | List of semantic family ids or legacy-compatible ids; manifest validator checks them against capability registry. [VERIFIED: lib/crosswake/policy/schema.ex, lib/crosswake/manifest/validator.ex] | Prefer semantic family vocabulary, while acknowledging existing examples use `haptics.impact`, `share`, and `:camera`. |
| `packs` | Content or media pack requirements are normalized and must be unique per route. [VERIFIED: lib/crosswake/policy/schema.ex, lib/crosswake/policy/route.ex] | Use for offline content and native capture examples. |
| `sync` | List of sync seam ids; island contract builder uses the first seam when present. [VERIFIED: lib/crosswake/policy/schema.ex, lib/crosswake/manifest/builder.ex] | Use for local-first replay examples without claiming generic sync. |
| `transfers` | Transfer declarations are normalized; `source: :native_capture` requires `runtime: :native_screen`. [VERIFIED: lib/crosswake/policy/schema.ex, lib/crosswake/policy/route.ex, lib/crosswake/manifest/validator.ex] | Use for native capture and file-picker/transfer examples. |
| `security` / `auth_*` | Sensitive routes and recent-auth routes resolve to strict auth posture; cached-read-only auth posture is restricted. [VERIFIED: lib/crosswake/policy/route.ex] | Keep security examples narrow and source-backed. |
| `gated_by` / `on_unavailable` | `on_unavailable` requires `gated_by`; a missing `on_unavailable` defaults gated routes to `:deny`. [VERIFIED: lib/crosswake/policy/route.ex] | Use for explicit deny/fallback posture. |
| `notification_open` | Accepts `true` or actions list; compatibility code requires route-policy declaration before notification-open activation. [VERIFIED: lib/crosswake/policy/schema.ex, lib/crosswake/compatibility/compatibility.ex] | Mention only as route-entry posture, not notification delivery support. |
| `commerce` | Corridor role values include `:paywall_entry`, `:purchase_intent`, `:restore_intent`, and `:account_management`; provider-specific terms are rejected. [VERIFIED: lib/crosswake/policy/schema.ex, lib/crosswake/policy/route.ex] | Use as backend/provider seam examples, not device authority. |

## Plan-Specific Recommendations

| Roadmap Plan | Likely File Ownership | Verification | Risks / Edge Cases |
|--------------|-----------------------|--------------|--------------------|
| 117-01 route-policy guide | Add `guides/route_policy.md`; update `guides/user_flows.md` to link to it; optionally add README teaser only if 117-03 will finish navigation. [VERIFIED: 117-CONTEXT.md, guides/user_flows.md] | Add `test/crosswake/guides/route_policy_test.exs`; run it with user-flow/adopter-profile tests. [VERIFIED: existing docs-test pattern] | Do not duplicate `user_flows.md`; preserve "Who should own this route?" and the three canonical jobs. [VERIFIED: guides/user_flows.md] |
| 117-02 web-to-mobile migration guide | Add `guides/web_to_mobile_migration.md`; link from route-policy guide and optionally user flows. [VERIFIED: 117-CONTEXT.md] | Add `test/crosswake/guides/web_to_mobile_migration_test.exs`; assert route inventory, default-to-LiveView, promotion criteria, and "do not migrate this" warnings. [VERIFIED: guides/adopter_profiles_test.exs pattern] | Keep it concise; link reference guides instead of copying bridge/offline/native-shell details. [VERIFIED: 117-CONTEXT.md D-11] |
| 117-03 support labels / README / ExDoc / matrix | Update README guide map and compact legend, `mix.exs` extras/groups, `guides/install.md` links, `lib/crosswake/support_matrix/renderer.ex`, regenerated `guides/support_matrix.md`, and support matrix tests. [VERIFIED: README.md, mix.exs, lib/crosswake/support_matrix/renderer.ex] | Run support matrix tests, guide tests, release-boundary tests, and `mix docs` if ExDoc grouping changes. [VERIFIED: test/crosswake/support_matrix/renderer_test.exs, test/crosswake/guides/release_boundaries_test.exs] | Current support-matrix parity already fails; 117-03 should reconcile renderer and on-disk guide before or while adding the friendly legend. [VERIFIED: targeted test run] |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Support matrix generation | Hand-authored matrix or manual table edits | `Crosswake.SupportMatrix.canonical()` plus `Crosswake.SupportMatrix.Renderer.render/1` | Tests enforce byte identity and support data is shared with manifest/doctor surfaces. [VERIFIED: lib/crosswake/support_matrix/support_matrix.ex, lib/crosswake/support_matrix/renderer.ex, test/crosswake/support_matrix/renderer_test.exs] |
| Route-policy syntax | Simplified pseudo-DSL | Actual `crosswake: [...]` declarations from router/test fixtures | The schema has important constraints around offline, auth, gating, packs, sync, and transfers. [VERIFIED: lib/crosswake/policy/schema.ex, lib/crosswake/policy/route.ex] |
| Docs navigation | Separate custom docs index | `mix.exs` `extras` and `groups_for_extras` | Crosswake already publishes README/guides via ExDoc extras. [VERIFIED: mix.exs] |
| Support labels | Ad hoc terms like "Verified Android" | Locked vocabulary: merge-blocking proof, advisory evidence, local-dev proof, generated public-coordinate proof, JVM hermetic proof, emulator evidence, device evidence, verification-required, rebuild-required | Prevents evidence laundering and supports Phase 119/120 labels. [VERIFIED: 117-CONTEXT.md D-14/D-16] |
| Migration advice | Generic mobile rewrite essay | Route inventory by user job and owner class | The phase requirement is for Phoenix SaaS route classification, not mobile architecture theory. [VERIFIED: .planning/REQUIREMENTS.md, 117-CONTEXT.md D-07/D-10] |

**Key insight:** Phase 117 is a source-of-truth alignment phase; custom shortcuts create new drift where tests already enforce rendered docs, route-policy validation, and guide graph boundaries. [VERIFIED: tests and code listed above]

## Common Pitfalls

### Pitfall 1: Existing Support-Matrix Parity Drift

**What goes wrong:** The planner assumes support-matrix tests are green before changing the legend. [VERIFIED: targeted test run]

**Why it happens:** `guides/support_matrix.md` intro differs from `Renderer.render(SupportMatrix.canonical())`. [VERIFIED: lib/crosswake/support_matrix/renderer.ex, guides/support_matrix.md]

**How to avoid:** Include a task in 117-03 to reconcile the current intro and new legend through renderer output, then update the checked-in guide. [VERIFIED: test/crosswake/support_matrix/renderer_test.exs]

**Warning signs:** `mix test test/crosswake/support_matrix/renderer_test.exs test/crosswake/support_matrix/support_matrix_test.exs` fails on byte identity. [VERIFIED: command output]

### Pitfall 2: Route-Policy Guide Becomes Capability Catalog

**What goes wrong:** The guide leads with native affordances rather than route owners. [VERIFIED: 117-CONTEXT.md D-06]

**Why it happens:** `guides/capabilities.md` has many family rows and can pull copy toward plugin-catalog language. [VERIFIED: guides/capabilities.md]

**How to avoid:** Start each section with owner decisions, then mention capability families only as consequences. [VERIFIED: guides/user_flows.md, guides/capabilities.md]

**Warning signs:** First-read copy says "native API access", "plugin", or "verified Android" without proof labels. [VERIFIED: 117-CONTEXT.md D-16/D-25]

### Pitfall 3: Phase 118 Scope Leakage

**What goes wrong:** 117 rewrites `examples/QUICK_START.md` or `guides/adoption.md` fully. [VERIFIED: 117-CONTEXT.md D-22]

**Why it happens:** Those files are known stale or partial after Phase 116 safety edits. [VERIFIED: examples/QUICK_START.md, guides/adoption.md, .planning/phases/116-proof-debt-and-release-truth/116-CONTEXT.md]

**How to avoid:** Link toward the new mental-model guides but leave command verification and full offline rewrite to Phase 118. [VERIFIED: .planning/ROADMAP.md]

**Warning signs:** Tasks include port/path proof, `Crosswake.mutate` scanning, or clean-checkout command verification. [VERIFIED: .planning/REQUIREMENTS.md QUICK-01/ADOPT-01/DRIFT-02]

### Pitfall 4: Native Evidence Decision Leakage

**What goes wrong:** 117 labels checked-in native hosts as published-coordinate or local-dev proof as a final decision. [VERIFIED: 117-CONTEXT.md D-23]

**Why it happens:** The support vocabulary needs terms that Phase 119 will later apply. [VERIFIED: .planning/research/v13-native-evidence.md]

**How to avoid:** Define terms and non-claims, but say Phase 119 classifies checked-in host evidence. [VERIFIED: .planning/ROADMAP.md Phase 119]

**Warning signs:** Docs state checked-in iOS/Android hosts "prove published coordinates" before Phase 119. [VERIFIED: 117-CONTEXT.md D-23]

### Pitfall 5: ExDoc Extras Drift

**What goes wrong:** New guide files exist but are absent from HexDocs, or extras reference missing files. [VERIFIED: mix.exs, 117-CONTEXT.md D-19]

**Why it happens:** `mix.exs` extras and guides can change in separate plans. [VERIFIED: mix.exs]

**How to avoid:** In 117-03, update `extras` only after both new guides exist, and add a docs-contract assertion for extras/file presence. [VERIFIED: existing test patterns]

**Warning signs:** `mix docs` fails, or `groups_for_extras` references a file not present in `guides/`. [VERIFIED: mix.exs]

## Code Examples

### Plain LiveView Route

```elixir
# Source: examples/phoenix_host/lib/crosswake_example/router.ex
live("/dashboard", DashboardLive,
  crosswake: [
    id: "saas-dashboard",
    runtime: :live_view,
    offline: :cached_read_only,
    security: :standard
  ]
)
```

### Bounded Bridge Affordance

```elixir
# Source: examples/phoenix_host/lib/crosswake_example/router.ex
live("/approvals/:id", ApprovalLive,
  crosswake: [
    id: "saas-approval",
    runtime: :live_view,
    entry: :external,
    capabilities: ["haptics.impact"],
    offline: :cached_read_only,
    security: :standard
  ]
)
```

### Cached Read-Only Route With Transfer

```elixir
# Source: examples/phoenix_host/lib/crosswake_example/router.ex
live("/library", CrosswakeExample.LibraryLive,
  crosswake: [
    id: "library",
    cache_contract: :lesson_library_v1,
    packs: [[id: :lesson_library, version: "1.2.0", kind: :content]],
    transfers: [
      [
        id: :lesson_import,
        intent: :import,
        source: :native_picker,
        verification: :required,
        media_types: ["application/pdf"]
      ]
    ]
  ]
)
```

### Native-Owned Route

```elixir
# Source: examples/phoenix_host/lib/crosswake_example/router.ex
live("/claims/:id/capture", ClaimCaptureLive,
  crosswake: [
    id: "selective-native-claim-capture",
    runtime: :native_screen,
    capabilities: [:camera],
    packs: [[id: :camera_capture_assets, version: "1.0.0", kind: :media]],
    transfers: [
      [
        id: :capture_upload,
        intent: :upload,
        source: :native_capture,
        verification: :required,
        media_types: ["image/*"]
      ]
    ],
    offline: :cached_read_only,
    security: :sensitive
  ]
)
```

### Gated Route

```elixir
# Source: examples/phoenix_host/lib/crosswake_example/router.ex
live("/beta-feature", BetaFeatureLive,
  crosswake: [
    id: "gating-beta-feature",
    gated_by: :rulestead,
    on_unavailable: :deny
  ]
)
```

## State Of The Art

| Old Approach | Current Approach | When Changed / Verified | Impact |
|--------------|------------------|-------------------------|--------|
| README and user-flow links were the first conceptual route-policy path. | Add dedicated `guides/route_policy.md`, while preserving `guides/user_flows.md` as the JTBD ramp. | Phase 117 context, 2026-06-18. [VERIFIED: 117-CONTEXT.md] | Gives GUIDE-01 a single anchor without deleting existing strong copy. |
| ExDoc grouping is broad: `Setup`, `Capabilities`, `Guides`. | Reorder around Start, Adopt, Runtime Owners, Truth, and Advanced/Companions. | Phase 117 context, 2026-06-18. [VERIFIED: mix.exs, 117-CONTEXT.md] | Matches adopter reading order and makes the new guide path visible. |
| Support matrix intro has status legend only. | Add friendlier proof-label legend before dense tables. | Phase 117 requirement. [VERIFIED: .planning/REQUIREMENTS.md TRUTH-01] | Prevents readers from equating "supported" with device-verified. |
| Native evidence classification is ambiguous. | Phase 117 defines vocabulary; Phase 119 applies checked-in host classification. | v13 roadmap split. [VERIFIED: .planning/ROADMAP.md] | Avoids overclaiming while preparing stable labels. |

**Deprecated/outdated:**

- Generic WebView wrapper or LiveView-native-renderer language is out of scope. [VERIFIED: AGENTS.md, README.md]
- "Offline support" without cached-read-only vs offline-island distinction is misleading. [VERIFIED: AGENTS.md, guides/offline.md]
- "Verified Android" without proof class is forbidden by Phase 117 context. [VERIFIED: 117-CONTEXT.md D-16]

## Assumptions Log

All claims in this research are sourced from repo files or command output; no `[ASSUMED]` claims are required. [VERIFIED: Sources section]

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| none | n/a | n/a | n/a |

## Open Questions (RESOLVED)

1. **Should support-truth legend live only in README plus support-matrix intro, or also in `guides/support_truth.md`?**  
   What we know: A separate helper guide is allowed only if it does not create a second source of truth. [VERIFIED: 117-CONTEXT.md D-12]  
   RESOLVED: Use README plus the support-matrix intro for the support-truth legend. Do not add `guides/support_truth.md` in Phase 117 unless execution discovers a hard navigation need; `guides/support_matrix.md` remains the canonical source, rendered through `Crosswake.SupportMatrix.Renderer`. [VERIFIED: 117-CONTEXT.md D-12/D-13, 117-03-PLAN.md Task 1]

2. **Should existing support-matrix parity drift be fixed as a separate first task in 117-03?**  
   What we know: Targeted support-matrix tests currently fail on renderer/guide byte identity. [VERIFIED: command output]  
   RESOLVED: Fix support-matrix intro/parity inside 117-03 Task 1 by updating `lib/crosswake/support_matrix/renderer.ex`, regenerating `guides/support_matrix.md`, and updating renderer/support-matrix tests. The parity fix and friendly legend belong in the same task because they touch the same canonical renderer/output/test path. [VERIFIED: test/crosswake/support_matrix/renderer_test.exs, 117-03-PLAN.md Task 1]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | ExUnit tests and docs-contract checks | yes | 1.19.5 | none needed. [VERIFIED: command `elixir --version`] |
| Mix | Test/docs commands | yes | 1.19.5 | none needed. [VERIFIED: command `mix --version`] |
| ExDoc | HexDocs extras and grouping | yes, locked dep | 0.40.3 | `mix docs` only after deps are available. [VERIFIED: mix.lock] |
| GSD `init.phase-op` query | Phase context discovery | yes via global `gsd-tools` | version not reported | Direct file discovery. [VERIFIED: command `gsd-tools query init.phase-op 117`] |
| GSD `classify-confidence` / `research-plan` seam | Optional research-cache protocol | no | command unavailable | Use repo-local evidence and explicit provenance tags. [VERIFIED: command failures] |

**Missing dependencies with no fallback:** none for implementation. [VERIFIED: local command checks]  
**Missing dependencies with fallback:** GSD research-cache helpers are unavailable, but phase research is repo-local and all claims are sourced directly. [VERIFIED: command failures]

## Validation Architecture

`workflow.nyquist_validation` is absent from `.planning/config.json`, so validation architecture is enabled by default. [VERIFIED: .planning/config.json]

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Mix 1.19.5. [VERIFIED: command `mix --version`] |
| Config file | No standalone ExUnit config found in required files; tests are standard `test/**/*.exs`. [VERIFIED: filesystem discovery] |
| Quick run command | `mix test test/crosswake/guides/user_flows_test.exs test/crosswake/guides/adopter_profiles_test.exs test/crosswake/guides/release_boundaries_test.exs` [VERIFIED: command passed] |
| Support matrix command | `mix test test/crosswake/support_matrix/renderer_test.exs test/crosswake/support_matrix/support_matrix_test.exs` [VERIFIED: command currently fails on parity drift] |
| Full suite command | `mix test` [VERIFIED: Mix project] |
| Docs smoke | `mix docs` after ExDoc navigation changes. [VERIFIED: mix.exs] |

### Phase Requirements To Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| GUIDE-01 | Route-policy guide exists, uses real owner classes, includes route examples, links manifest/doctor/support truth, and avoids framework/WebView/plugin positioning. | docs-contract | `mix test test/crosswake/guides/route_policy_test.exs -x` | No, Wave 0. [VERIFIED: filesystem discovery] |
| MIGRATE-01 | Migration guide inventories routes by job, defaults to LiveView, defines promotion criteria, includes "do not migrate this", and links reference guides. | docs-contract | `mix test test/crosswake/guides/web_to_mobile_migration_test.exs -x` | No, Wave 0. [VERIFIED: filesystem discovery] |
| TRUTH-01 | README, ExDoc extras/groups, support-matrix intro/legend, and guide map share support-label vocabulary. | docs-contract + renderer parity | `mix test test/crosswake/support_matrix/renderer_test.exs test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/guides/release_boundaries_test.exs` | Existing tests partially cover; new assertions needed. [VERIFIED: existing tests] |

### Sampling Rate

- **Per task commit:** Run the smallest guide-specific test plus any touched support-matrix test. [VERIFIED: existing test granularity]
- **Per wave merge:** Run guide tests plus support matrix tests. [VERIFIED: test locations]
- **Phase gate:** Run `mix test test/crosswake/guides/user_flows_test.exs test/crosswake/guides/adopter_profiles_test.exs test/crosswake/guides/release_boundaries_test.exs test/crosswake/support_matrix/renderer_test.exs test/crosswake/support_matrix/support_matrix_test.exs` and `mix docs` after `mix.exs` changes. [VERIFIED: mix.exs, tests]

### Wave 0 Gaps

- [ ] `test/crosswake/guides/route_policy_test.exs` - covers GUIDE-01. [VERIFIED: missing file]
- [ ] `test/crosswake/guides/web_to_mobile_migration_test.exs` - covers MIGRATE-01. [VERIFIED: missing file]
- [ ] Add TRUTH-01 label assertions to existing support/guide tests. [VERIFIED: test/crosswake/support_matrix/renderer_test.exs, test/crosswake/guides/release_boundaries_test.exs]
- [ ] Reconcile existing support-matrix byte-parity failure before declaring 117-03 green. [VERIFIED: targeted test run]

## Security Domain

`security_enforcement` is absent from `.planning/config.json`, so security review expectations remain enabled. [VERIFIED: .planning/config.json]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes, as documentation of existing route auth predicates | Use existing `auth_min_level`, `requires_recent_auth`, `auth_posture`, and Sigra support truth; do not add auth behavior. [VERIFIED: lib/crosswake/policy/schema.ex, lib/crosswake/policy/route.ex, lib/crosswake/support_matrix/support_matrix.ex] |
| V3 Session Management | yes, as docs boundary | Preserve backend-owned session authority; device/provider evidence is not session authority. [VERIFIED: guides/support_matrix.md, lib/crosswake/support_matrix/support_matrix.ex] |
| V4 Access Control | yes | Route allow/deny, `entry`, `gated_by`, `on_unavailable`, manifest validation, and route-unavailable posture are existing controls. [VERIFIED: lib/crosswake/policy/route.ex, lib/crosswake/manifest/validator.ex, guides/native_shell.md] |
| V5 Input Validation | yes | Route DSL uses NimbleOptions validation and manifest validator enforces registry/pack/transfer truth. [VERIFIED: lib/crosswake/policy/schema.ex, lib/crosswake/manifest/validator.ex] |
| V6 Cryptography | no new crypto | Do not introduce crypto or token schemes in documentation examples. [VERIFIED: Phase 117 scope] |

### Known Threat Patterns For Phase 117

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Evidence laundering: advisory native/emulator/JVM proof described as device support | Spoofing / Repudiation | Use exact support-label vocabulary and define what each label does not prove. [VERIFIED: 117-CONTEXT.md D-14/D-16, guides/support_matrix.md] |
| Device/provider evidence treated as backend/session authority | Elevation of privilege / Spoofing | Keep backend/provider seam language explicit and point to support matrix non-claims. [VERIFIED: lib/crosswake/support_matrix/support_matrix.ex, guides/capabilities.md] |
| Cached read-only presented as offline mutation | Tampering | Require cached-read-only vs offline-island distinction in guide tests. [VERIFIED: guides/offline.md, lib/crosswake/policy/route.ex] |
| Bridge described as high-frequency or mutation authority | Tampering / Elevation of privilege | Preserve request/reply-only bounded bridge language and leave Phase 118 adoption rewrite out of scope. [VERIFIED: guides/bridge.md, 117-CONTEXT.md D-22] |

## Sources

### Primary (HIGH confidence)

- `AGENTS.md` - project constraints and working rules. [VERIFIED: AGENTS.md]
- `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` - v13 scope, Phase 117 requirements, success criteria, and boundaries. [VERIFIED: local files]
- `.planning/phases/117-route-policy-and-support-truth-guide-foundation/117-CONTEXT.md` - locked decisions and deferred scope. [VERIFIED: local file]
- `.planning/phases/116-proof-debt-and-release-truth/116-CONTEXT.md` - adjacent Phase 116 boundaries. [VERIFIED: local file]
- `.planning/research/SUMMARY.md`, `v13-support-truth-guides.md`, `v13-proof-path-docs.md`, `v13-native-evidence.md`, `v13-collateral-ci.md` - v13 research synthesis and adjacent scope caveats. [VERIFIED: local files]
- `README.md`, `mix.exs`, `guides/*.md`, `examples/QUICK_START.md` - public docs surfaces. [VERIFIED: local files]
- `lib/crosswake/policy/schema.ex`, `lib/crosswake/policy/route.ex`, `lib/crosswake/manifest/builder.ex`, `lib/crosswake/manifest/validator.ex`, `lib/crosswake/doctor/doctor.ex`, `lib/crosswake/support_matrix/support_matrix.ex`, `lib/crosswake/support_matrix/renderer.ex` - code truth. [VERIFIED: local files]
- `test/crosswake/support_matrix/renderer_test.exs`, `test/crosswake/support_matrix/support_matrix_test.exs`, `test/crosswake/guides/user_flows_test.exs`, `test/crosswake/guides/adopter_profiles_test.exs`, `test/crosswake/guides/release_boundaries_test.exs` - test patterns and current failures. [VERIFIED: local files and command output]

### Secondary (MEDIUM confidence)

- Prior v13 research cites official Phoenix, ExDoc, Hotwire Native, Capacitor, Playwright, GitHub Actions, Apple Simulator, and Android docs for onboarding/evidence patterns. This Phase 117 research did not re-fetch external docs because the requested scope is repo-local and the existing local research already captured those references. [VERIFIED: .planning/research/*.md]

### Tertiary (LOW confidence)

- None used. [VERIFIED: Assumptions Log]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - verified from `mix.exs`, `mix.lock`, and local runtime commands. [VERIFIED: mix.exs, mix.lock, command output]
- Architecture: HIGH - verified from required docs, route policy source, manifest builder, doctor, support matrix, and tests. [VERIFIED: local files]
- Pitfalls: HIGH - support-matrix parity failure reproduced; scope boundaries are locked in context. [VERIFIED: command output, 117-CONTEXT.md]
- External docs patterns: MEDIUM - inherited from prior v13 research, not re-fetched in this run. [VERIFIED: .planning/research/*.md]

**Research date:** 2026-06-18  
**Valid until:** 2026-07-18 for local docs/code structure; re-check before implementation if Phase 118/119/120 lands first. [VERIFIED: current date, roadmap phase order]
