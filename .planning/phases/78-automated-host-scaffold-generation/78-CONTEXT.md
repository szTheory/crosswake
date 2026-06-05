# Phase 78: Automated Host Scaffold Generation - Context

**Gathered:** 2026-06-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Update `mix crosswake.gen.shell` to scaffold thin iOS and Android host apps that consume the newly extracted standalone Crosswake Core SDKs (SPM/Maven) instead of copying raw source files. The generated apps must include the necessary "glue" code to boot the shell and observe its state, alongside minimal permission scaffolding.

</domain>

<decisions>
## Implementation Decisions

### Dependency Resolution (Local vs Remote)
- **D-01:** The generator must output remote SPM/Maven dependency references by default, targeting the stable release of `crosswake-shell-core`. This provides adopters with a clean, standard dependency tree without manual repository management.
- **D-02:** Introduce a `--local` flag (or detect if running inside the Crosswake mono-repo) that overrides the dependencies to point to the local `packages/crosswake-shell-core-*` paths. This is essential for maintaining hermetic CI proof lanes and allowing maintainers to iterate on both Elixir and native core simultaneously without publishing.

### Permission Templating (Aggressive vs Minimal)
- **D-03:** The generated `Info.plist` and `AndroidManifest.xml` must be strictly minimal, including only what is necessary to boot the shell (e.g., standard Internet permissions).
- **D-04:** Do not litter the manifests with massive blocks of commented-out capability permissions. Instead, embed a single prominent comment block linking to the official Crosswake "Capabilities and Permissions" documentation. This aligns with the Phoenix ecosystem ethos: generate the minimum to boot, and let the documentation guide explicit capability expansion.

### Glue Code Architecture (Root vs Coordinator)
- **D-05:** Do not bind `CrosswakeShell` directly into the root `App` (iOS) or `MainActivity` (Android).
- **D-06:** Generate a dedicated `CrosswakeCoordinator` (iOS) / `CrosswakeViewModel` (Android) as the "Glue" layer. This layer will initialize the `CrosswakeShell` instance, subscribe to its reactive state (as decided in Phase 77), and expose a clean state interface to a dumb root View.
- **D-07:** This design pattern treats the native shell like a GenServer in a supervision tree: its lifecycle and state management are explicitly separated from the UI rendering layer, honoring Crosswake's principle of explicit boundary ownership and tear-free UI renders.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone posture
- `.planning/PROJECT.md` - Crosswake thesis, explicit runtime boundaries, and native abstraction limits.
- `.planning/REQUIREMENTS.md` - GEN-01, GEN-02, and GEN-03 traceability.
- `.planning/ROADMAP.md` - Phase 78 goal and scaffold generation boundaries.
- `.planning/phases/77-reactive-state-api-standardization/77-CONTEXT.md` - Phase 77 reactive state and API standardization decisions.

### Architectural Research & Guidelines
- `prompts/crosswake-elixir-oss-dna.md` - Maintainer house style, minimal generation footprints, and explicit documentation routing.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - Library ergonomics and scaffolding design for native environments.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/mix/tasks/crosswake.gen.shell.ex` - The existing mix task generator that will be refactored to emit the new thin scaffolds.
- `priv/templates/crosswake.gen.shell/` - Template directory to be completely overhauled for the SPM/Maven paradigm.

### Established Patterns
- Phoenix generators (`mix phx.gen.*`) serve as the gold standard for minimal, focused output that defers complex configuration to well-documented manual steps.
- The `examples/phoenix_host` environment will use the `--local` flag to act as the primary proof artifact for this generation strategy.

</code_context>

<specifics>
## Specific Ideas

- The generated UI should be clean and immediately functional, displaying the shell's reactive state (e.g., a simple view that reacts to `isOnline` or connection status) to prove the plumbing works out-of-the-box.
- The Swift Package Manager configuration should ideally be a standard `Package.swift` dependency in a raw Xcode project, and the Maven configuration should slot cleanly into a standard `build.gradle.kts` setup.

</specifics>

<deferred>
## Deferred Ideas

- Automated App Store / Play Store deployment workflows from the generated scaffold.
- E2E hermetic verification of the v5.0 core extraction (Phase 79).

</deferred>

---

*Phase: 78-automated-host-scaffold-generation*
*Context gathered: 2026-06-05*