# Phase 2: Manifest Truth And Compatibility - Context

**Gathered:** 2026-05-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 2 turns the Phase 1 route-policy truth into a versioned runtime contract that Phoenix hosts, native shells, diagnostics tooling, and adopters can trust before shipping artifacts. This phase defines the manifest shape, compatibility rules, doctor surface, and support/documentation posture. It does not yet prove native shell boot, bridge execution, or offline runtime behavior end to end.

</domain>

<decisions>
## Implementation Decisions

### Runtime manifest contract shape
- **D-01:** Crosswake should emit one canonical runtime manifest as a single versioned JSON artifact, not a family of loosely coupled manifest files.
- **D-02:** The manifest should be route-entry-first, keyed by Crosswake route `id`, not path-rule-first like Hotwire Native path configuration.
- **D-03:** The manifest should mirror the Phase 1 normalized route surface closely: `id`, route path/pattern, `runtime`, `offline`, `capabilities`, `packs`, `sync`, and `security`, with only minimal additional shell-facing metadata.
- **D-04:** The manifest should have explicit top-level sections for `manifest_schema_version`, `crosswake_version`, generation metadata, host truth, compatibility truth, support-matrix truth, capability registry truth, and compiled routes.
- **D-05:** Capability names and versions should live in a global manifest registry plus per-route allowlists, not only inline inside route entries.
- **D-06:** Support-matrix truth should be machine-readable from the same manifest contract so doctor tooling, docs, and proof lanes derive from one source of truth.
- **D-07:** Remote manifest updates may exist later, but only as versioned manifest replacement or companion data. Crosswake should not depend on unversioned overlays or rule-order semantics that silently change route meaning.

### Compatibility and activation policy
- **D-08:** Crosswake should use layered compatibility, not exact global lockstep and not best-effort degradation.
- **D-09:** Compatibility should be modeled as separate contract axes: `manifest_schema_version`, `bridge_protocol_version`, `native_runtime_version`, and capability versions; later phases can add pack and sync schema versions without collapsing them into one boolean.
- **D-10:** Native runtime compatibility must be treated separately from manifest schema compatibility. A shell can be structurally able to read a manifest but still be unable to activate specific routes safely.
- **D-11:** Crosswake should support bundled, cached, and remote manifests, with the bundled manifest as guaranteed boot truth and the remote manifest allowed to refine behavior only within the boundaries of the shipped native runtime.
- **D-12:** Route activation must fail closed when required runtime, bridge, origin, capability, or compatibility conditions are not met. Crosswake should not silently fall back to a generic WebView container for incompatible native or offline routes.
- **D-13:** Route-level compatibility gating is required. App boot compatibility alone is not enough because Crosswake’s core thesis is explicit runtime ownership per route.
- **D-14:** OTA-safe manifest or config updates must never imply new native behavior absent from the shipped binary. Remote manifest updates may select among existing runtime/capability options only.
- **D-15:** The first public support matrix should stay narrow and proof-oriented: one active Phoenix line, one active LiveView line, one iOS floor, one Android floor, plus exact shell/runtime artifact versions used in proof lanes.
- **D-16:** Public support posture should distinguish `supported`, `expected but unproven`, and `unsupported` instead of implying broad semver optimism.

### Doctor tooling and diagnostics posture
- **D-17:** Phase 2 should ship one primary public task, `mix crosswake.doctor`, focused on host and manifest truth first, not a broad native-environment preflight.
- **D-18:** Blocking doctor checks should cover installer state, router markers, policy module presence, policy compilation, manifest generation, manifest schema/compatibility validation, and support-matrix consistency.
- **D-19:** Native environment or toolchain checks may exist only as clearly labeled advisory checks behind an explicit flag or sibling task until native shell proof lanes exist.
- **D-20:** Doctor output should default to human-readable terminal output and support a stable structured mode such as `--format json` for CI, docs-contract checks, and future tooling.
- **D-21:** Doctor findings should be separated into `error`, `warning`, and `advisory`, with exit codes driven only by blocking contract failures.
- **D-22:** Doctor should reuse structured compiler diagnostics and machine-readable install-manifest data directly. It should not scrape rendered strings back into structure.
- **D-23:** Compatibility failures should be explained in operator language: route requires newer shell runtime, capability version missing, manifest built for newer bridge major, origin mismatch, or unsupported baseline.

### Documentation and public contract posture
- **D-24:** Phase 2 docs should make runtime ownership, compatibility boundaries, supported baselines, non-goals, and rough edges explicit enough that adopters can self-screen before implementation.
- **D-25:** Crosswake should market Phase 2 as manifest truth and compatibility truth, not as solved shell runtime support. Native shell generation exists, but shell boot/runtime credibility remains Phase 3 work.
- **D-26:** Support matrix and rough-edge docs are product surface, not cleanup work. They should be generated or mechanically checked where practical so written claims do not drift from implementation truth.

### Decision delegation posture
- **D-27:** Shift choices left within GSD by default. Downstream researcher, planner, and implementer agents should make principled decisions without re-asking unless a choice materially changes one of these: public product contract, support claims, compatibility policy, route taxonomy, security posture, or long-term upgrade surface.
- **D-28:** For internal implementation details such as module splits, helper naming, serializer organization, report formatting details, and exact code structure, the agent should choose least-surprise Phoenix/Elixir patterns without escalating.

### the agent's Discretion
- Exact manifest field names can be refined during planning as long as the layered contract shape above remains intact.
- Exact support baseline numbers can move with the current stable ecosystem at planning time, but the narrow-matrix posture stays fixed.
- The precise doctor report layout, grouping, and color treatment are agent discretion if the severity model and automation contract stay stable.
- Internal compiler, validator, and serializer module boundaries are agent discretion if they preserve the route-first manifest contract and machine-readable diagnostics.

</decisions>

<specifics>
## Specific Ideas

- Hotwire Native is a useful operational reference for bundled-plus-remote configuration and progressive native enhancement, but Crosswake should not inherit a `rules`-first contract surface.
- Expo’s runtime-version model is a strong lesson for native-runtime identity: any change that requires different native code needs an explicitly different runtime identity.
- React Native’s typed spec and Codegen posture is a good model for versioned, generated, low-ambiguity bridge and capability boundaries.
- Capacitor-style “web app plus plugins” drift is a cautionary example. Crosswake should avoid generic plugin sprawl and permission sprawl disguised as capability support.
- Android JavaScript bridge guidance and WebKit App-Bound Domains reinforce that the bridge should be treated as unsafe by default unless route, origin, and runtime checks all pass.
- App-store and store-policy realities mean remote manifest/config updates must stay within already-shipped native behavior. Crosswake should not create a covert code-update channel through manifest flexibility.
- The desired developer experience is strong happy-path ergonomics with honest failure messages, narrow supported baselines, good CI affordances, and minimal need for users to think through internal contract choices themselves.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Core planning context
- `.planning/PROJECT.md` — thesis, constraints, non-goals, and OSS posture
- `.planning/REQUIREMENTS.md` — Phase 2 requirement mapping and scope boundaries
- `.planning/ROADMAP.md` — Phase 2 goal and success criteria
- `.planning/STATE.md` — current project position and known Phase 2 concerns

### Prior phase decisions
- `.planning/phases/01-route-policy-foundation/01-CONTEXT.md` — locked route-policy, ownership-boundary, and diagnostics decisions that Phase 2 must build on
- `.planning/phases/01-route-policy-foundation/01-route-policy-foundation-03-SUMMARY.md` — structured compile diagnostics pattern and machine-readable warning/error posture

### Stable project research
- `.planning/research/SUMMARY.md` — synthesized architecture and roadmap rationale
- `.planning/research/ARCHITECTURE.md` — policy compiler, manifest, compatibility, and diagnostics system shape

### Prompt lineage and architecture guidance
- `prompts/crosswake-research-synthesis.md` — canonical architecture synthesis and stable conclusions
- `prompts/crosswake-gsd-project-brief.md` — authoritative project brief, runtime contract expectations, and support-matrix posture
- `prompts/crosswake-brand-book.md` — positioning guardrails, terminology, and docs/support presentation cues
- `prompts/crosswake-elixir-oss-dna.md` — maintainer OSS house style, install truth, and support honesty expectations
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — route/runtime architecture, compatibility, security, and store-policy lessons
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` — refined three-plane system and manifest/bridge guidance
- `prompts/elixir-mobile-oss-lib-deep-research.md` — ecosystem gap analysis and contract-first product framing
- `prompts/elixir-mobile-offlinesupport-stresstest-deep-research.md` — offline honesty constraints that affect manifest wording and support claims
- `prompts/elixir-mobile-offlinesupport-flashcard-app-stresstest-deep-research.md` — concrete offline-island boundary examples that Phase 2 should not overclaim yet

### Current implementation anchors
- `lib/crosswake/policy/route.ex` — current normalized route contract that the manifest should mirror
- `lib/crosswake/policy/compiler.ex` — route-policy compile pipeline and structured result shape
- `lib/crosswake/policy/diagnostic.ex` — machine-readable diagnostic format and Phoenix-style presentation baseline
- `lib/crosswake/install/manifest.ex` — existing manifest-writing utility and machine-readable artifact pattern
- `lib/mix/tasks/crosswake.install.ex` — installer contract and current install-manifest inputs
- `priv/templates/crosswake/install_manifest.json.eex` — existing scaffold-manifest JSON style
- `guides/install.md` — public install truth and explicit Phase 1/2 ownership boundaries

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Policy.Route` — normalized route struct that can become the manifest’s route-entry source
- `Crosswake.Policy.Compiler` — existing compile pipeline that already separates successful normalized output from structured diagnostics
- `Crosswake.Policy.Diagnostic` and related error/warning structs — reusable machine-readable diagnostic layer for doctor output
- `Crosswake.Install.Manifest` — current JSON rendering/persistence utility that establishes a machine-readable artifact pattern
- `mix crosswake.install` install-manifest output — existing host-truth data source for Phase 2 doctor checks

### Established Patterns
- Compile-time enforcement stays strict about local declarative truth and avoids environment-truth claims until later tooling phases.
- Public contract surfaces are additive, host-owned where appropriate, and explicit about ownership boundaries.
- Machine-readable artifacts and structured diagnostics are preferred over opaque text output.
- Route-local policy remains the authoritative Phoenix-side source of truth.

### Integration Points
- Manifest compilation should sit immediately downstream of the Phase 1 route-policy compiler.
- Doctor tooling should consume compiler results, install-manifest data, and support-matrix data from the same contract surface.
- Future iOS and Android shells in Phase 3 should treat the Phase 2 manifest as their boot and route-activation contract.
- Documentation and proof-lane checks should derive support claims from the same compatibility/support data emitted by the manifest layer.

</code_context>

<deferred>
## Deferred Ideas

- Native shell boot verification, real WebView/WKWebView runtime behavior, and deep-link handoff proof remain Phase 3.
- Typed request/reply bridge execution and capability dispatch remain Phase 3, even though Phase 2 sets the versioning and compatibility posture they must obey.
- Offline island journals, local-first mutation contracts, and reconciliation semantics remain Phase 4.
- Pack lifecycle, native-screen escape hatches, media transfer seams, and full proof lanes remain Phase 5.
- Broad native environment inspection, signing checks, simulator/emulator orchestration, and release/distribution workflows are deferred until the project has proven shell/runtime behavior to validate against.
- Wide compatibility promises across multiple Phoenix/LiveView lines are deferred until proof lanes justify them.

</deferred>

---

*Phase: 02-manifest-truth-and-compatibility*
*Context gathered: 2026-05-14*
