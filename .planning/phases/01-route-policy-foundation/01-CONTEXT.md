# Phase 1: Route Policy Foundation - Context

**Gathered:** 2026-05-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 1 establishes the Phoenix-side authoring contract for Crosswake route policy. Phoenix hosts must be able to declare runtime ownership and route constraints per route, get actionable compile-time validation, and bootstrap the host-side installation path without yet proving native-shell runtime behavior, manifest compatibility handshakes, or offline execution.

</domain>

<decisions>
## Implementation Decisions

### Route policy declaration shape
- **D-01:** Crosswake should use a hybrid, router-adjacent DSL. Policy is authored next to Phoenix routes and compiled into normalized policy data for later manifest generation.
- **D-02:** The primary authoring surface should be a `crosswake:` route option plus scope-level `crosswake defaults:` support, not a separate manifest registry or external JSON/TOML authoring file.
- **D-03:** Compiled Crosswake policy should be attached to Phoenix route `metadata` so the raw Phoenix metadata escape hatch remains available and router introspection stays the source of truth.
- **D-04:** Route declarations should stay in the router, not in `config/*.exs`, to preserve locality, verified-route ergonomics, and least surprise for Phoenix users.

### Runtime taxonomy and naming
- **D-05:** The public runtime taxonomy for Phase 1 should have three ownership classes only: `:live_view`, `:offline_island`, and `:native_screen`.
- **D-06:** `adapter` should not be a peer route runtime in the public DSL. Reserve `adapter` for later capability, sync, or companion integration extension points.
- **D-07:** `runtime:` is the primary route key. `offline`, `capabilities`, `packs`, and `sync` are orthogonal axes around runtime ownership, not alternative route classes.
- **D-08:** Crosswake should use explicit, full nouns in the public DSL and docs. Avoid shorthand or hosting-leak terms like `:webview`, `:native`, or `:lv`.

### Route metadata surface
- **D-09:** Require `id` and `runtime` on every Crosswake-managed route.
- **D-10:** Default `offline: :unavailable`, `capabilities: []`, `packs: []`, and `sync: []` unless explicitly declared otherwise.
- **D-11:** Treat `security`/sensitivity as explicit policy, but only require an explicit declaration when the route enables caching, local-first semantics, media handling, billing-sensitive behavior, or sensitive native capabilities.
- **D-12:** Keep the Phase 1 route surface intentionally narrow: runtime ownership, offline policy, capability requirements, pack requirements, sync seam identity, and security sensitivity. Defer broader presentation or platform-tuning knobs unless they are needed for route truth.
- **D-13:** Use typed option schemas and normalized structs rather than raw nested maps everywhere. `NimbleOptions` should validate option shape; normalized route-policy structs should enforce semantic invariants.

### Compile-time validation posture
- **D-14:** Crosswake should be strict on local declarative truth and layered on world truth. Compile time is for contradictions, missing required metadata, unknown enum values, and architecturally forbidden combinations.
- **D-15:** Compile time should not require native artifacts, filesystem state, release packaging, support-matrix availability, or other environment-dependent facts. Those belong to later doctor, manifest, and release validation phases.
- **D-16:** Route coverage across the entire router should be a warning in Phase 1, not a hard error. Allow incremental adoption.
- **D-17:** Errors should aggregate by policy module where feasible and include route, file/line, offending keys, reason, and a minimal fix suggestion.
- **D-18:** Unknown declared capabilities should fail at compile time; valid capabilities invoked from an undeclared route should fail closed at runtime in later phases.

### Generator and ownership boundaries
- **D-19:** Phase 1 DX should ship a two-step additive setup path: `mix crosswake.install` for Phoenix host wiring and `mix crosswake.gen.shell ios|android` for host-owned native workspace skeletons.
- **D-20:** `mix crosswake.install` should be idempotent, patch the router with explicit markers, generate a host-owned Crosswake policy module, and record scaffold state in a machine-readable install manifest for future doctor/upgrade support.
- **D-21:** `mix crosswake.gen.shell` should generate host-owned native skeletons, local bundled fixtures, and handoff docs, but not pretend that native projects remain library-owned after generation.
- **D-22:** Crosswake-owned code should stay limited to the DSL, validators, policy normalization, manifest compiler groundwork, and diagnostics tooling. Generated Phoenix and native app files are host-owned and editable.
- **D-23:** Do not ship a `crosswake.new` framework-style template as the primary public entrypoint. Heavy full-app templates are acceptable for repo examples and proof lanes only.

### the agent's Discretion
- The planning agent should default to decisive, idiomatic choices unless a decision would materially change product boundaries, public contract wording, or long-term upgrade posture.
- Internal implementation details such as exact module splits, schema helper names, warning wording, and code organization should be agent discretion if they preserve the decisions above.
- Prefer least-surprise Phoenix/Elixir patterns over inventing novel abstractions.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Core planning context
- `.planning/PROJECT.md` — thesis, constraints, non-goals, and OSS posture
- `.planning/REQUIREMENTS.md` — Phase 1 requirements and scope boundaries
- `.planning/ROADMAP.md` — Phase goal and success criteria
- `.planning/STATE.md` — current project position and deferred items
- `.planning/research/SUMMARY.md` — synthesized architecture and roadmap rationale

### Prompt lineage and architecture guidance
- `prompts/crosswake-research-synthesis.md` — canonical prompt synthesis and stable architecture conclusions
- `prompts/crosswake-gsd-project-brief.md` — authoritative project brief and route-policy examples
- `prompts/crosswake-brand-book.md` — positioning guardrails and terminology constraints
- `prompts/crosswake-elixir-oss-dna.md` — maintainer OSS house style, install truth, and proof-lane expectations
- `prompts/crosswake-integrations-and-companions.md` — companion classification guidance and v1/v2 separation
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — route/runtime architecture patterns and cross-ecosystem lessons
- `prompts/elixir-mobile-apptypes-design-stresstest-deep-research.md` — app archetype guidance shaping runtime taxonomy
- `prompts/elixir-mobile-offlinesupport-stresstest-deep-research.md` — offline policy distinctions and cautions
- `prompts/elixir-mobile-offlinesupport-flashcard-app-stresstest-deep-research.md` — concrete local-first workflow constraints
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` — refined v1 direction and phased product contract
- `prompts/elixir-mobile-oss-lib-deep-research.md` — earlier ecosystem research and tradeoff context
- `prompts/new elixir oss lib prompt.txt` — original product goals, DX priorities, and cross-ecosystem concerns

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None yet. The repository is still in planning-only state with no library implementation to reuse.

### Established Patterns
- Planning artifacts are the current source of truth.
- Crosswake already commits to Phoenix-first route ownership, bounded bridge contracts, honest offline semantics, and diagnostics as product surface.

### Integration Points
- Phase 1 implementation will anchor in Phoenix router macros, route metadata, and Mix tasks.
- The Phase 1 policy representation must become the source for Phase 2 manifest generation and later doctor tooling.

</code_context>

<specifics>
## Specific Ideas

- The ideal authoring feel is Phoenix-native and router-local, closer to router macros plus typed metadata than to an external config file.
- Hotwire Native is a useful pattern source for generated output and path-rule thinking, but not for the primary authoring surface.
- Tauri-style deny-by-default capabilities and typed boundaries are strong security inspirations.
- React Native’s typed/generated boundary discipline is worth copying; its single-runtime worldview is not.
- LiveView Native’s repository being archived on 2026-02-10 is treated as a caution against coupling Crosswake to native rendering promises or fragile upstream internals.
- Error messages should feel closer to good Ecto/Phoenix ergonomics than to opaque DSL compiler failures.

</specifics>

<deferred>
## Deferred Ideas

- Desktop/Electron packaging is explicitly deferred beyond v1.
- Billing, app-store policy automation, permission choreography, and entitlement-heavy native flows belong to later native-shell and native-screen phases.
- Rich animations, audio engine depth, and polished device-heavy capability surfaces belong to later bridge/offline/native phases.
- E2E proof lanes, CI/CD hardening, telemetry depth, review/reputation workflows, and release choreography are important, but most of their implementation belongs after the route-policy surface is locked.
- Companion integrations with `sigra`, `rulestead`, `rindle`, `chimeway`, `threadline`, and others remain relevant context but should not distort the Phase 1 contract.

</deferred>

---

*Phase: 01-route-policy-foundation*
*Context gathered: 2026-05-12*
