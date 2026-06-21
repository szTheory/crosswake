---
phase: 123-native-package-behavioral-proof
plan: "02"
subsystem: ios-behavioral-tests
tags: [xctest, bridge-conformance, activation-conformance, bundle-module, vectors, ntest-02]
dependency_graph:
  requires: [123-01]
  provides: [ios_bridge_conformance_xctest, ios_activation_conformance_xctest, swift_test_green]
  affects: [123-04]
tech_stack:
  added: []
  patterns: [bundle-module-resource, data-driven-xctest, main-actor-test-class, weak-ref-arc-guard]
key_files:
  created:
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/ActivationConformanceTests.swift
  modified:
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/CrosswakeShellCoreTests.swift
    - packages/crosswake-shell-core-ios/Package.swift
decisions:
  - "Session capabilities and request capabilities are decoupled: request uses a fixed baseline so vec-007 capability-version mismatch fires correctly (session has 2.0.0, request carries 1.0.0)"
  - "StubAppInfoDelegate held as strong local var in each test — CrosswakeShellConfig.appInfoDelegate is weak, so a temporary stub is deallocated before evaluate() runs without a strong reference"
  - "ActivationConformanceTests annotated @MainActor to allow synchronous PackStore and ActivationCoordinator construction (both are @MainActor); PackStore default parameter removed from helper to avoid nonisolated context initializer error"
  - "SessionOverride decodes mixed JSON (empty array [] vs keyed object) via try? decoder.unkeyedContainer() probe; empty array carries no overrides"
metrics:
  duration: "4m 30s"
  completed: "2026-06-20"
  tasks: 3
  files: 4
status: complete
---

# Phase 123 Plan 02: iOS Behavioral Test Suites Summary

XCTest behavioral suites for `crosswake-shell-core-ios` covering all six bridge contract behaviors — data-driven from `bridge_contract_vectors.json` via Bundle.module, no simulator, no hardcoded version literals. Full `swift test` suite is green (6 tests, 0 failures) on macOS.

## What Was Built

### Task 1: Replace corrupted test file + Package.swift resources

**`CrosswakeShellCoreTests.swift`** — replaced the corrupted file (literal `\n` escape bytes on one line, would not compile) with a minimal valid XCTestCase subclass pointing to the behavioral test files.

**`Package.swift`** — added `resources: [.copy("Resources/")]` to the testTarget block so `Bundle.module` exposes the gen-emitted `bridge_contract_vectors.json`. `.copy` is correct for JSON files under swift-tools-version 5.9.

`swift test` verified: compiles and runs green (0 tests, no compile errors) before any behavioral tests were written.

### Task 2: BridgeConformanceTests.swift

**`BridgeConformanceTests.swift`** — data-driven XCTest class driving `BridgeChannel.evaluate(_:completion:)` against all 7 vectors.

**Codable models:**
- `BridgeVectorsFile` (bridgeProtocolVersion, nativeRuntimeVersion, vectors) — CodingKeys for snake_case
- `BridgeVector` (id, description, requestOverride, sessionOverride, expectedOutcome, expectedDenialReason) — CodingKeys for snake_case
- `SessionOverride` — custom decoder handles mixed JSON (empty `[]` vs keyed object with capabilities/installed_packs/route_required_packs)

**setUp** loads `bridge_contract_vectors.json` via `Bundle.module.url(forResource:withExtension:)` and decodes to `BridgeVectorsFile`.

**`test_bridge_vectors_data_driven`** iterates all 7 vectors:
- Builds `LiveViewSession` from permissive baseline, applies sessionOverride
- Builds `BridgeRequestEnvelope` from permissive baseline, applies requestOverride
- Request capabilities use a fixed baseline (`"app.info.get": "1.0.0"`) independent of session capabilities
- For ok-path vector (vec-003): `StubAppInfoDelegate` held as strong local variable (config holds weak reference)
- Asserts `reply?.status == vector.expectedOutcome` and `reply?.denial?.denial.reason == expectedDenialReason` per vector (vector id in every failure message)

**Delegate escape-hatch tests (2 tests):**
- `test_appInfoGet_with_delegate_returns_ok`: delegate present → status ok
- `test_appInfoGet_without_delegate_returns_deny`: delegate absent → status deny, reason undeclared_capability

**Behaviors covered:** version mismatch (vec-001), unknown command (vec-002), canonical ok (vec-003), inactive route (vec-004), origin denied (vec-005), pack incompatible (vec-006), capability version mismatch (vec-007), delegate escape-hatch.

### Task 3: ActivationConformanceTests.swift

**`ActivationConformanceTests.swift`** — `@MainActor` XCTest class driving `ActivationCoordinator.resolve(request:manifest:)`.

**setUp** loads `bridge_protocol_version` from vectors file via `JSONSerialization` for version anchoring per D-01.

**Tests (3):**
- `test_activation_success_resolves_to_liveView`: permissive manifest + request → `ShellPresentation.liveView`, session.bridgeProtocolVersion matches vectors file
- `test_activation_denies_inactive_route`: empty manifest (no routes) → `ShellPresentation.denied(.inactiveRoute)`
- `test_activation_blocks_when_required_pack_missing`: route with `packs: ["content-pack@1.0.0"]`, empty inventory → `ShellPresentation.requiredPack`

All tests use injected `manifestLoader`/`requestLoader` closures and `PackStore(requiredVersions:inventory:)` (no Bundle, no simulator — D-11).

## Decisions Made

- **Session/request capabilities decoupled:** The request carries a fixed baseline capability version (`"app.info.get": "1.0.0"`). This ensures vec-007 fires `capabilityAvailable() → false` when the session declares `"2.0.0"`, as intended by the vector. Passing session.capabilities to both would always match.
- **`@MainActor` on ActivationConformanceTests:** `PackStore.init` and `ActivationCoordinator.init` are `@MainActor`-isolated. Annotating the test class `@MainActor` lets them be called synchronously; Swift default parameters in helper signatures can't initialize `@MainActor` types in nonisolated context, so PackStore construction was moved into each test body.
- **`SessionOverride` mixed-type decoder:** The vectors JSON uses `[]` for empty session_override and a keyed object for non-empty. A `try? decoder.unkeyedContainer()` probe distinguishes the two cases; on success (empty array), all override fields default to nil.
- **Strong delegate reference:** `CrosswakeShellConfig` stores delegate references as `weak`. A `StubAppInfoDelegate` created inline and passed to the config is immediately eligible for deallocation in ARC. All tests that need a delegate hold a strong local variable.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Session and request capabilities were aliased — vec-007 got wrong denial reason**
- **Found during:** Task 2 first run
- **Issue:** `makeRequest` was called with `sessionCapabilities: session.capabilities` and used them verbatim as `request.capabilities`. For vec-007, session has `{"app.info.get": "2.0.0"}` and request also got `"2.0.0"` → `capabilityAvailable()` returned true → fell through to delegate check → `undeclared_capability` instead of `unavailable_capability`.
- **Fix:** Request capabilities use a fixed baseline `["app.info.get": "1.0.0"]` independent of session. Session and request capabilities are now independently constructed.
- **Files modified:** `BridgeConformanceTests.swift`
- **Commit:** 71eed26

**2. [Rule 1 - Bug] StubAppInfoDelegate deallocated before evaluate() for ok-path vector**
- **Found during:** Task 2 first run
- **Issue:** `StubAppInfoDelegate()` created inline in `makeConfig(for:appInfoDelegate:)` call; `CrosswakeShellConfig` stores `weak var appInfoDelegate`. ARC released the stub before `channel.evaluate()` ran → `config.appInfoDelegate == nil` → `undeclared_capability` instead of `ok`.
- **Fix:** Hold `let stubDelegate = StubAppInfoDelegate()` as a strong local variable in the test loop and in each delegate escape-hatch test.
- **Files modified:** `BridgeConformanceTests.swift`
- **Commit:** 71eed26

**3. [Rule 1 - Bug] PackStore default parameter caused nonisolated context compiler error**
- **Found during:** Task 3 compile
- **Issue:** `func makeCoordinator(..., packStore: PackStore = PackStore(requiredVersions: [:], inventory: []))` — default parameter values are evaluated in nonisolated context, but `PackStore.init` is `@MainActor`. Swift 5.9 strict concurrency error.
- **Fix:** Removed default parameter; added `emptyPackStore()` helper called from within the `@MainActor` test methods.
- **Files modified:** `ActivationConformanceTests.swift`
- **Commit:** d76c962

## Known Stubs

None. All tests drive real production seams and assert on observable reply values.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes. Tests read only the committed resource via Bundle.module (hermetic). No production code was modified. T-123-04 (D-10): no `BridgeChannel.protocolVersion` constant added. T-123-05 (D-14): all assertions on `reply.status` and `reply.denial?.denial.reason` — no internal guard assertions.

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/CrosswakeShellCoreTests.swift` | FOUND |
| `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift` | FOUND |
| `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/ActivationConformanceTests.swift` | FOUND |
| `packages/crosswake-shell-core-ios/Package.swift` resources rule | FOUND |
| commit 0238717 (Task 1 — corrupted file + resources) | FOUND |
| commit 71eed26 (Task 2 — BridgeConformanceTests) | FOUND |
| commit d76c962 (Task 3 — ActivationConformanceTests) | FOUND |
| `swift test` — 6 tests, 0 failures | PASSED |
| No bridge version literal in test files | CONFIRMED |
