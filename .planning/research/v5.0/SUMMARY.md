# Research Summary: v5.0 Standalone Publishable Shell Packages

**Domain:** Mobile SDK Architecture & Dependency Management
**Researched:** 2026-06-03
**Overall confidence:** HIGH

## Executive Summary

Crosswake's early phases successfully proved the hermetic viability of generated iOS and Android shells. However, as the bridge, auth, and commerce capabilities expand, generating full source code (`ActivationCoordinator`, `BridgeChannel`) directly into the host project creates an "eject trap". Adopters modifying these files face significant friction ("version drift") when updating to newer Crosswake releases. 

Modern mobile SDK architecture favors a "Binary Core + Hosted Glue" approach. By extracting the core routing, bridge enforcement, and manifest resolution logic into standalone publishable dependencies (Swift Package Manager for iOS, Maven AAR for Android), Crosswake can guarantee core contract integrity while exposing specific, typed Delegate protocols or StateFlows for host customization (e.g., haptics, file picking, and UI overrides). 

## Key Findings

**Stack:** Swift Package Manager (SPM) for iOS and Maven Central (AAR) for Android.
**Architecture:** Binary Core with Reactive State (ObservableObject/StateFlow) and strictly-typed Delegate interfaces.
**Critical pitfall:** The "Leaky Abstraction / Boilerplate Trap"—forcing adopters to implement massive Java-style callback interfaces instead of modern reactive streams and optional lambdas.

## Implications for Roadmap

Based on research, suggested phase structure for v5.0:

1. **Phase 1: Shell Extraction & Interface Design** - Isolate `ActivationCoordinator` and `BridgeChannel` into SPM/Maven libraries without changing their internal behavior. Define the `CrosswakeShellDelegate` boundary.
   - Addresses: Core packaging and capability encapsulation.
   - Avoids: Mixing feature work with architectural refactoring.

2. **Phase 2: Reactive State & Initialization Standardization** - Replace raw object generation in the host with a single `CrosswakeShell.initialize(config)` entry point. Ensure state is exposed via modern reactive patterns (`@Published` in iOS, `StateFlow` in Android).
   - Addresses: Developer ergonomics and SDK onboarding.
   - Avoids: The boilerplate trap.

3. **Phase 3: Automated Host Scaffold Generation** - Update `mix crosswake.gen.shell` to output thin, dependency-driven host projects rather than full source copies.
   - Addresses: The "eject trap" and backward compatibility for generation tooling.
   - Avoids: Forcing adopters to manually string together the new dependencies.

**Phase ordering rationale:**
- Extracting the core logic first ensures we find all hidden dependencies and tight couplings. Refining the public API (Phase 2) builds on the isolated core. Updating the generation tooling (Phase 3) is the final integration step that consumes the new artifacts.

**Research flags for phases:**
- Phase 2: Likely needs deeper research on how best to handle entitlements and Info.plist / AndroidManifest.xml permissions that the core SDK requires but the host app must ultimately declare.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | SPM and Maven are industry standards for their respective platforms. |
| Features | HIGH | The boundary between core logic and host logic is well-defined by existing generated files. |
| Architecture | HIGH | Modern patterns strongly support extracting complex logic into libraries while providing reactive state. |
| Pitfalls | MEDIUM | Requires careful API design to ensure the Delegate/Callback pattern doesn't become overly burdensome for custom use cases. |

## Gaps to Address

- **Permission Management:** How will the core SDK communicate required `Info.plist` or `AndroidManifest.xml` changes to the host? We currently rely on manual templates.
- **Transfers & Background Work:** Ensuring the extracted `TransferCoordinator` can reliably operate in the background without being overly constrained by the host lifecycle.
