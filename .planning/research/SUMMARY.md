# Research Summary: Adoption Evidence Demo App

**Domain:** Phoenix-native Mobile Shells (v5.1 Standalone Dependency Proof)
**Researched:** 2026-06-06
**Overall confidence:** HIGH

## Executive Summary

Following the major architectural shift in `v5.0` to **Standalone Publishable Shell Packages**, the `v5.1` milestone focuses on proving these packages in a realistic "Adoption Evidence" demo app. This app serves as the primary evidence that Crosswake has successfully eliminated the "eject trap" and boilerplate of previous versions.

The research identifies critical pitfalls in the transition from local project references to standalone SPM/Maven consumption, specifically around transitive dependency management and the lifecycle of new reactive state APIs. The demo app must not only show a "happy path" but must also demonstrate how to avoid memory leaks in the bridge and how to handle desyncs between server-published manifests and native binary capabilities.

## Key Findings

**Stack:** Phoenix-native backend utilizing standalone Crosswake SPM (iOS) and Maven (Android) dependencies with reactive state projections.
**Architecture:** Thin dependency-driven host projects where native UI observes shell state via Combine (iOS) and Flows (Android).
**Critical pitfall:** Relying on local project references during demo development, which masks integration friction and dependency conflicts that adopters will face.

## Implications for Roadmap

Based on research, suggested phase structure:

1. **Standalone Dependency Bootstrap** - Transition the demo app from local library references to standalone SPM/Maven consumption.
   - Addresses: Validates the `v5.0` distribution pipeline and ensures public visibility of all necessary headers/classes.
   - Avoids: The "Local Project Mirage" pitfall.

2. **Reactive State Bridge Proof** - Implement the reactive state API for a core capability (e.g., connection status or auth state).
   - Addresses: Proves the new reactive observer pattern.
   - Avoids: "Zombie" observers and memory leaks through explicit lifecycle binding.

3. **Capability Handshake & Doctoring** - Implement the "Local Truth" handshake where the native shell announces its registered components.
   - Addresses: Manifest-capability desync issues.
   - Avoids: Silent failures when the server expects a capability the binary lacks.

4. **Adoption Evidence Polish** - Finalize the demo app as "runnable documentation" with clear feature slices.
   - Addresses: Developer experience and copy-pasteability.
   - Avoids: "Kitchen Sink" obscurity.

**Phase ordering rationale:**
- Dependency bootstrap is the foundational blocker. Reactive state and Capability handshakes are the core architectural "evidence" to be proven. Polish comes last to ensure the underlying contracts are stable.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | v5.0 artifacts are already published/available; the stack is fixed. |
| Features | HIGH | Features are focused on proving existing v5.0 capabilities. |
| Architecture | HIGH | Reactive bridge patterns are well-understood in the broader mobile ecosystem (Hotwire/Turbo). |
| Pitfalls | HIGH | Pitfalls are based on common mobile OSS library failures and specific v5.0 changes. |

## Gaps to Address

- **CI Verification:** Defining how CI will verify the "clean slate" install of the demo app without using local cache or pre-installed artifacts.
- **Reactive Threading:** Establishing a standard "Main Thread" guarantee for all bridge-to-UI reactive updates to prevent host app crashes.
