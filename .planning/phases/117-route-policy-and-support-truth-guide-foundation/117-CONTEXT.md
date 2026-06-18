# Phase 117: Route-Policy And Support-Truth Guide Foundation - Context

**Gathered:** 2026-06-18T20:37:43Z
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 117 makes Crosswake's first-read mental model obvious before the runnable quick start and collateral phases build on it. It delivers the route-policy/start-here guide path, a web-to-mobile migration guide for existing Phoenix SaaS teams, and a consistent support-truth vocabulary across README, ExDoc guide grouping, guide maps, and the support matrix entry points.

This phase is documentation architecture and support-label foundation. It is not the full command-verified quick start, not the v12 adoption guide rewrite, not native host evidence classification, not collateral capture, and not new capability breadth.

</domain>

<decisions>
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

### Claude's Discretion

The user delegated Phase 117 discussion decisions to Claude after the initial workflow prompt. Downstream agents may choose exact file names only within these bounds: `guides/route_policy.md` and `guides/web_to_mobile_migration.md` are the recommended defaults; a support-truth helper guide is optional and must not replace the canonical support matrix. Planners may decide exact ExDoc group labels if they preserve the Start / Adopt / Runtime Owners / Truth / Advanced reading order.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Requirements

- `.planning/PROJECT.md` - Current v13 thesis, active constraints, route-policy/product decisions, and non-goals.
- `.planning/REQUIREMENTS.md` - Phase 117 requirements: GUIDE-01, MIGRATE-01, TRUTH-01.
- `.planning/ROADMAP.md` - Phase 117 success criteria and 117-01/117-02/117-03 plan split.
- `.planning/STATE.md` - Current position, v13 blockers, native-host drift caveat, and Phase 117 next-step framing.
- `.planning/phases/116-proof-debt-and-release-truth/116-CONTEXT.md` - Carry-forward boundaries from Phase 116, especially avoiding Phase 118 quick-start/adoption scope and Phase 119 native classification overclaim.

### v13 Research

- `.planning/research/SUMMARY.md` - v13 research synthesis, phase ordering, and adopter-confidence constraints.
- `.planning/research/v13-support-truth-guides.md` - Primary research for this phase: route-policy story, support guide map, migration path, ExDoc navigation, and support-label copy.
- `.planning/research/v13-proof-path-docs.md` - Adjacent proof-path drift research; use to avoid accidentally pulling Phase 118 scope into Phase 117.
- `.planning/research/v13-native-evidence.md` - Adjacent native evidence caveats; use vocabulary carefully but leave classification to Phase 119.
- `.planning/research/v13-collateral-ci.md` - Adjacent artifact/collateral constraints; useful for ensuring labels created in Phase 117 work for Phase 120.

### Public Guide Surfaces

- `README.md` - First-read route-policy positioning, proof/support posture, guide map, and current baseline.
- `mix.exs` - ExDoc extras/groups, HexDocs landing page, package file inclusion, current package version.
- `guides/user_flows.md` - Strong existing "Who should own this route?" mental model and three canonical jobs; preserve and promote.
- `guides/adopter_profiles.md` - Existing adopter-profile matrix and representative routes to align with route-policy/migration guide examples.
- `guides/support_matrix.md` - Canonical support-status surface and dense matrix that needs a friendlier entry legend.
- `guides/install.md` - Public install and proof-entry path; link new guide path without rewriting Phase 118 quick start.
- `guides/native_shell.md` - Manifest-first activation, native-owned routes, route-unavailable posture, and native evidence caveats.
- `guides/bridge.md` - Bounded bridge request/reply vocabulary and denial posture.
- `guides/offline.md` - Cached read-only versus offline-island boundaries.
- `guides/capabilities.md` - Capability family ownership and defer/backend seam vocabulary.
- `guides/compatibility.md` - Compatibility, fail-closed, and runtime-line posture.
- `guides/adoption.md` - Known Phase 118 rewrite target; avoid relying on its stale offline mutation language as current truth.
- `examples/QUICK_START.md` - Known Phase 118 rewrite target; do not make Phase 117 depend on its current commands.

### Code And Generated Truth

- `lib/crosswake/policy/schema.ex` - Route-policy DSL source of truth for runtime, offline, entry, security, auth, commerce, packs, sync, transfers, and notification-open fields.
- `lib/crosswake/policy/route.ex` - Route validation rules, including cache/island contract constraints and gating defaults.
- `lib/crosswake/manifest/builder.ex` - How route policy becomes manifest, capability registry, support entries, and guide anchors.
- `lib/crosswake/manifest/validator.ex` - Fail-closed validation and support-truth requirements downstream docs should match.
- `lib/crosswake/doctor/doctor.ex` - Doctor surface that the route-policy guide should present as adopter-facing product output.
- `lib/crosswake/support_matrix/support_matrix.ex` - Canonical support matrix data and promotion/action/change-class vocabulary.
- `lib/crosswake/support_matrix/renderer.ex` - Deterministic generated support matrix Markdown; update this if changing the matrix intro/legend.
- `test/crosswake/support_matrix/renderer_test.exs` - Existing renderer tests for deterministic support matrix output.
- `test/crosswake/support_matrix/support_matrix_test.exs` - Existing support matrix truth tests.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `guides/user_flows.md`: Already contains the strongest conceptual route-owner narrative and three canonical jobs. Reuse it as Start Here/JTBD companion rather than replacing it.
- `guides/adopter_profiles.md`: Provides representative route sets for Phoenix SaaS Portal, Selective Native Flow, and Local-First Study Flow. Use these as examples in route-policy and migration guides.
- `guides/support_matrix.md`: Canonical support truth exists but is dense. Phase 117 should add first-read explanation, not invent a competing matrix.
- `mix.exs`: ExDoc extras and grouping are already centralized; Phase 117 can add new guide files and reader-oriented groups there.
- `lib/crosswake/support_matrix/renderer.ex`: The support matrix is rendered deterministically. Changes to generated matrix prose should go through the renderer and tests.
- `lib/crosswake/policy/schema.ex` and `lib/crosswake/policy/route.ex`: These are the route-policy syntax and validation sources for examples.

### Established Patterns

- Docs are product surface in Crosswake. Prior phases treat support matrices, proof lanes, ExDoc extras, and docs-contract tests as correctness artifacts, not cleanup.
- Route ownership is authoritative and per-route. Capability, pack, sync, transfer, auth, and provider language must hang off the route owner rather than becoming a generic capability catalog.
- Generated/canonical docs need parity protection. If `guides/support_matrix.md` is generated, update source and tests rather than direct-editing output only.
- The project already uses a required-versus-advisory proof split. Phase 117 should make that split readable before collateral and native evidence phases reuse it.

### Integration Points

- README and HexDocs main page are the first public entry points because `mix.exs` sets `main: "readme"`.
- New guide files must be listed in ExDoc extras/groups and are included in the package because `package.files` includes `guides`.
- Support-truth vocabulary touches README, `guides/support_matrix.md`, `mix.exs` guide groups, and later artifact captions. Keep the terms stable now so Phase 118-120 can reuse them.
- Phase 117 should prepare labels for native evidence without choosing the checked-in host strategy; that decision remains Phase 119.

</code_context>

<specifics>
## Specific Ideas

- Auto-selected all gray areas after the user asked for an automated pass: route-policy guide shape, migration guide shape, support-truth vocabulary, and README/ExDoc wiring.
- Recommended new guide defaults: `guides/route_policy.md` and `guides/web_to_mobile_migration.md`.
- Recommended ExDoc grouping: Start, Adopt, Runtime Owners, Truth, Advanced/Companions. Exact labels may vary, but this reading order should hold.
- Recommended first-read support legend terms: merge-blocking proof, advisory evidence, local-dev proof, generated public-coordinate proof, JVM hermetic proof, emulator evidence, device evidence, verification-required, rebuild-required.
- Existing copy to preserve/promote: "Who should own this route?", "Route policy for Phoenix apps that go mobile", and "Declare which runtime owns each route."

</specifics>

<deferred>
## Deferred Ideas

- Full command-verified `examples/QUICK_START.md` rewrite remains Phase 118.
- Full `guides/adoption.md` rewrite around app-owned IndexedDB outbox, reconnect-triggered `flushOutbox`, `/study/sync`, Ecto idempotency, outbox deletion, and conflict semantics remains Phase 118.
- Quick-start/adoption drift guard for wrong commands, port/path claims, `Crosswake.mutate`, and bridge-owned offline mutation language remains Phase 118.
- Checked-in iOS/Android host evidence classification, native guide reconciliation, Android UAT relabeling, and native coordinate drift guard remain Phase 119.
- Browser/native screenshots, recordings, artifact manifests, advisory native capture, and full troubleshooting/rough-edge examples remain Phase 120.
- DASH-01 and NTV-01 remain deferred unless v13 later proves they are necessary for adopter evidence visibility.

</deferred>

---

*Phase: 117-Route-Policy And Support-Truth Guide Foundation*
*Context gathered: 2026-06-18T20:37:43Z*
