# Phase 78: Automated Host Scaffold Generation - Research

**Researched:** 2026-06-05
**Domain:** Elixir CLI Generators / Native Build Scaffolding (SPM/Maven)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** The generator must output remote SPM/Maven dependency references by default, targeting the stable release of `crosswake-shell-core`. This provides adopters with a clean, standard dependency tree without manual repository management.
- **D-02:** Introduce a `--local` flag (or detect if running inside the Crosswake mono-repo) that overrides the dependencies to point to the local `packages/crosswake-shell-core-*` paths. This is essential for maintaining hermetic CI proof lanes and allowing maintainers to iterate on both Elixir and native core simultaneously without publishing.
- **D-03:** The generated `Info.plist` and `AndroidManifest.xml` must be strictly minimal, including only what is necessary to boot the shell (e.g., standard Internet permissions).
- **D-04:** Do not litter the manifests with massive blocks of commented-out capability permissions. Instead, embed a single prominent comment block linking to the official Crosswake "Capabilities and Permissions" documentation. This aligns with the Phoenix ecosystem ethos: generate the minimum to boot, and let the documentation guide explicit capability expansion.
- **D-05:** Do not bind `CrosswakeShell` directly into the root `App` (iOS) or `MainActivity` (Android).
- **D-06:** Generate a dedicated `CrosswakeCoordinator` (iOS) / `CrosswakeViewModel` (Android) as the "Glue" layer. This layer will initialize the `CrosswakeShell` instance, subscribe to its reactive state (as decided in Phase 77), and expose a clean state interface to a dumb root View.
- **D-07:** This design pattern treats the native shell like a GenServer in a supervision tree: its lifecycle and state management are explicitly separated from the UI rendering layer, honoring Crosswake's principle of explicit boundary ownership and tear-free UI renders.

### the agent's Discretion
- The generated UI should be clean and immediately functional, displaying the shell's reactive state (e.g., a simple view that reacts to `isOnline` or connection status) to prove the plumbing works out-of-the-box.
- The Swift Package Manager configuration should ideally be a standard `Package.swift` dependency in a raw Xcode project, and the Maven configuration should slot cleanly into a standard `build.gradle.kts` setup.

### Deferred Ideas (OUT OF SCOPE)
- Automated App Store / Play Store deployment workflows from the generated scaffold.
- E2E hermetic verification of the v5.0 core extraction (Phase 79).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GEN-01 | `mix crosswake.gen.shell` must be updated to output a thin, dependency-driven host project that consumes the new SPM/Maven artifacts instead of full source copies. | Use Elixir EEx templates to output `build.gradle.kts` and Xcode `project.pbxproj` configuring remote or `--local` dependencies. |
| GEN-02 | The generated host app must contain a "Glue" layer that wires the library into the host app lifecycle and observes its state for UI rendering. | Implement `CrosswakeCoordinator`/`CrosswakeViewModel` Elixir template fixtures rendering modern reactive state (`@Published`/`StateFlow`). |
| GEN-03 | The generation tooling must configure or template the necessary host permission requests (`Info.plist` / `AndroidManifest.xml`) required by the core SDK. | Embed minimalistic manifests with Phoenix-ethos single-comment documentation linking to capability guides. |
</phase_requirements>

## Summary

This phase pivots the `mix crosswake.gen.shell` Elixir task from outputting a "fat" host project with copy-pasted core files (e.g., `ActivationCoordinator.swift`, `BridgeChannel.kt`) to a "thin" host project. The thin host relies on `crosswake-shell-core` as an external SPM or Maven dependency.

**Primary recommendation:** Introduce a `--local` switch to `crosswake.gen.shell` options. Clean out legacy fat templates in Elixir's `priv/templates/` and replace them with standard dependency blocks in Gradle/Xcode templates. Implement the new glue layer components (`CrosswakeCoordinator` and `CrosswakeViewModel`) to satisfy D-05 and D-06, while drastically simplifying `crosswake_gen_shell_test.exs` which currently asserts heavily on the legacy full-source files.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Dependency Resolution Flag | CLI (Elixir) | — | `--local` CLI flag triggers template conditional rendering. |
| Shell Initialization Glue | Native Client | — | iOS `CrosswakeCoordinator` & Android `CrosswakeViewModel` map library state to UI. |
| Permission Provisioning | Native Client | — | `AndroidManifest.xml` and `Info.plist` generated with absolute minimum boots limits. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir (Mix) | 1.19+ | Scaffolding Engine | Project standard for `mix phx.gen.*` styled tooling. |
| EEx | Built-in | Text Templating | Elixir standard for safe string interpolations and conditional file output. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Raw Xcode `project.pbxproj` | `Tuist` / `Xcodegen` | Raw `.pbxproj` avoids adding external dependency tools for the adopter, respecting Phoenix defaults. |

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| crosswake-shell-core-ios | Local/Internal | N/A | N/A | First-party | [OK] | Approved |
| crosswake-shell-core-android | Local/Internal | N/A | N/A | First-party | [OK] | Approved |

*Note: No third-party packages are installed during this generation update. First-party extracted packages are consumed.*

## Architecture Patterns

### Recommended Project Structure (Generated Output)
```
native/ios/crosswake_shell/
├── CrosswakeShellApp.swift       # Dumb Root App (D-05)
├── CrosswakeCoordinator.swift    # Glue Layer (D-06) / Initializes SDK
├── Info.plist                    # Minimal permissions + capability doclink (D-03)
└── CrosswakeShell.xcodeproj/     # Configured for remote/local SPM package (GEN-01)

native/android/crosswake_shell/
├── app/build.gradle              # Configured for remote/local Maven AAR (GEN-01)
├── src/main/AndroidManifest.xml  # Minimal internet permission + capability doclink (D-03)
├── src/main/java/.../MainActivity.kt         # Dumb Root Activity (D-05)
└── src/main/java/.../CrosswakeViewModel.kt   # Glue Layer (D-06) / Initializes SDK
```

### Pattern 1: GenServer-style Shell Initialization (D-07)
**What:** Decouple native shell state completely from the rendering root view.
**Example:**
```swift
// iOS CrosswakeCoordinator (Glue)
class CrosswakeCoordinator: ObservableObject {
    @Published var state: CrosswakeState = .initializing
    private let shell: CrosswakeShell

    init() {
        self.shell = CrosswakeShell.initialize()
        // Subscribe to SDK's publisher
        self.shell.$state.assign(to: &$state)
    }
}
```

### Anti-Patterns to Avoid
- **Massive Commented Capabilities:** Do not embed hundreds of lines of commented XML for camera, bluetooth, etc. Output a single 3-line comment linking to `https://docs.crosswake.dev/capabilities`.
- **Destructive Regeneration:** The README must still clarify that this scaffold is host-owned and generated once.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| CLI Option Parsing | Manual `argv` matching | `OptionParser` | `lib/mix/tasks/crosswake.gen.shell.ex` already has `[target: :string, router: :string]`. Use `OptionParser` for new `--local` flag. |
| Test Validation | E2E execution in unit tests | `assert ios_output =~ "..."` | Use the existing ExUnit file assertions for generator output validation instead of slow compiler runs. |

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None | None |
| Live service config | None | None |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts | `examples/phoenix_host/native/*/crosswake_shell` projects | Re-generate using `mix crosswake.gen.shell --local` after updating task so hermetic lane is current. |
| Test artifacts | `test/mix/tasks/crosswake_gen_shell_test.exs` assertions | **Code edit**: Existing tests assert the presence of fat source files (e.g., `ActivationCoordinator.swift`). These tests must be heavily refactored to check for the thin glue layer and SPM/Maven configurations. |

## Common Pitfalls

### Pitfall 1: Generator Test Failures (Legacy Assertions)
**What goes wrong:** CI fails immediately after updating the generator because `crosswake_gen_shell_test.exs` expects 20+ legacy files to exist.
**Why it happens:** The test asserts on the exact file strings and paths generated by the "fat" paradigm.
**How to avoid:** Aggressively refactor `crosswake_gen_shell_test.exs` in the same commit as the generator template updates to assert on `CrosswakeCoordinator.swift`, `CrosswakeViewModel.kt`, and the dependency block in project files.

### Pitfall 2: Local Paths in iOS `.pbxproj` Strings
**What goes wrong:** Generating a valid Xcode project file with a local path SPM dependency string is notoriously flaky.
**Why it happens:** EEx templating into a 10,000-line `.pbxproj` can misalign UUIDs or paths.
**How to avoid:** Prove the `--local` template block hermetically. `Package.swift` is suggested by discretion rules, but if using standard `.pbxproj`, ensure the local path substitution uses relative resolution safely.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | Generator Tooling | ✓ | 1.19.5 | — |
| Xcodebuild | iOS validation | ✓ | 26.5 | — |
| Java / Gradle | Android validation | ✗ | — | Skip Android local hermetic verification; rely on Phase 79 CI lanes. |

**Missing dependencies with fallback:**
- Java is missing on this local machine. Android build proofs (`verify_generated_android_shell.sh`) should be executed strictly in CI lanes, while Phase 78 Elixir-level ExUnit generator testing is local-first.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/mix/tasks/crosswake_gen_shell_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| GEN-01 | Generator outputs SPM/Maven refs and respects `--local` flag | unit | `mix test test/mix/tasks/crosswake_gen_shell_test.exs` | ✅ Wave 0 (needs refactor) |
| GEN-02 | Glue layer `CrosswakeCoordinator` generated | unit | `mix test test/mix/tasks/crosswake_gen_shell_test.exs` | ✅ Wave 0 (needs refactor) |
| GEN-03 | Minimal Manifest generated w/ Capability Link | unit | `mix test test/mix/tasks/crosswake_gen_shell_test.exs` | ✅ Wave 0 (needs refactor) |

### Wave 0 Gaps
- [ ] `test/mix/tasks/crosswake_gen_shell_test.exs` — **CRITICAL**: The current test strictly enforces the "Fat" structure (checks for `ActivationCoordinator`, `BridgeChannel`, `PackStore` etc. inside the generated app). This file must be gutted and rewritten to assert only the "Thin" structure and dependency references.

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | `OptionParser` strict checking |

### Known Threat Patterns for Elixir CLI
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path Traversal in `--target` | Tampering | Use `Path.expand/1` safely and restrict out-of-tree execution if applicable (already handled). |

## Sources
### Primary (HIGH confidence)
- `.planning/phases/78-automated-host-scaffold-generation/78-CONTEXT.md` - Phase bounds and decisions.
- `lib/mix/tasks/crosswake.gen.shell.ex` - Generator current state.
- `test/mix/tasks/crosswake_gen_shell_test.exs` - Current generator assertions.

## Metadata
**Confidence breakdown:**
- Standard stack: HIGH - Core Elixir/Mix tooling.
- Architecture: HIGH - Dictated cleanly by D-05/D-06/D-07.
- Pitfalls: HIGH - ExUnit test mismatch is clearly evident in the source tree.

**Research date:** 2026-06-05
**Valid until:** 2026-07-05