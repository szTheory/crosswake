# Phase 80: Standalone Dependency Bootstrap - Context

**Gathered:** 2026-06-08
**Status:** Ready for planning

<domain>
## Phase Boundary

The iOS and Android host projects (demo apps) that integrate the Crosswake standalone dependencies. The focus is transitioning from local source generation to published package consumption.
</domain>

<decisions>
## Implementation Decisions

### Dependency Version Strategy
- **D-01:** Update the existing `examples/ios_shell_host` and `examples/android_shell_host` demo projects.
- **D-02:** Use the most recent published standalone packages for SPM/Maven instead of local file paths or bleeding-edge branches, ensuring the demos prove the released artifacts.

### Host Structure
- **D-03:** The native hosts should not contain any generated `ActivationCoordinator` or `BridgeChannel` source code. They must rely on the standalone dependencies.
- **D-04:** Leverage modern native UI stacks (SwiftUI, Jetpack Compose) within the demo apps where possible to demonstrate modern consumption.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project and Requirements
- `.planning/REQUIREMENTS.md` - For `SETUP-01` and `SETUP-02`
- `.planning/ROADMAP.md` - For phase boundaries and success criteria

### Guides
- `guides/install.md` - Note: This guide currently references old generated `ActivationCoordinator` instructions (from before v5.0). Downstream agents should recognize that v5.0's standalone dependency model takes precedence over the stale guide instructions for this phase.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The `examples/ios_shell_host` and `examples/android_shell_host` directories contain the existing host projects that will be refactored to use the new dependencies.

### Established Patterns
- Hermetic-vs-advisory CI split is the default pattern for environment-sensitive proof surfaces.
- Route policy and capability ladder (as detailed in PROJECT.md) dictate how the shell behaves.

### Integration Points
- Swift Package Manager (SPM) for the iOS host.
- Maven Central for the Android host.
</code_context>

<specifics>
## Specific Ideas

- Ensure we prove the actual "adoption evidence" — this means treating the example hosts exactly as a fresh adopter would treat them when adding the SPM/Maven packages.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope
</deferred>

---

*Phase: 80-Standalone Dependency Bootstrap*
*Context gathered: 2026-06-08*