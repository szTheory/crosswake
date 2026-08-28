# Phase 161: iOS Pronunciation Pack Seam - Pattern Map

**Mapped:** 2026-08-03  
**Files analyzed:** 16 planned new/modified files  
**Analogs found:** 13 / 16

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/PackProvider.swift` | provider contract/model | request-response | `lib/crosswake/packs/contracts.ex` | cross-language contract match |
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/PackStore.swift` | store | event-driven | existing `PackStore.swift` | exact role |
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift` | controller/coordinator | request-response | existing `ActivationCoordinator.swift` | exact role |
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeShellConfig.swift` | config | request-response | existing `CrosswakeShellConfig.swift` | exact role |
| `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/PackStoreTests.swift` | test | event-driven | `ActivationConformanceTests.swift` | role match |
| `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/PackProviderFixtureTests.swift` | test | file-I/O | `ActivationConformanceTests.swift` | partial; no existing file-I/O fixture test |
| `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/pronunciation-pack-fixture.*` | test fixture | file-I/O | `Resources/bridge_contract_vectors.json` | role match |
| `examples/ios_shell_host/CrosswakeShell/PronunciationPackProvider.swift` | host service/provider | file-I/O | `PermissionStatusProvider.swift` | role-only; no storage provider exists |
| `examples/ios_shell_host/CrosswakeShell/RequiredPackView.swift` | component | event-driven | existing `RequiredPackView.swift` | exact role |
| `examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift` | composition root | request-response | existing `CrosswakeShellApp.swift` | exact role |
| `examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj` | build config | batch | existing `project.pbxproj` | exact role |
| `priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex` | template/host-adapter contract | request-response | existing `ProofLaneDriver.swift.eex` | exact role |
| `priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex` | test template | request-response | existing `ProofLaneContractTests.swift.eex` | exact role |
| `priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex` | UI test template | event-driven | existing `ProofLaneUITests.swift.eex` | exact role |
| `lib/crosswake/proof_lane/evidence.ex` | service/model | transform | existing `evidence.ex` | exact role |
| `test/crosswake/proof_lane/{evidence_test,template_contract_test}.exs` | test | transform | existing proof-lane tests | exact role |

## Pattern Assignments

### `PackProvider.swift` (provider contract/model, request-response)

**Analog:** `lib/crosswake/packs/contracts.ex`

**Closed lifecycle vocabulary** (lines 8-10, 56-83):

```elixir
@type state ::
        :checking | :not_installed | :installing | :available | :stale | :invalidating | :failed

@enforce_keys [:state, :pack_id, :required_version]
defstruct [:state, :pack_id, :required_version, :version, :bytes,
  :verification, :install, :stale_reason, :failure, :invalidation, :last_known_state]
```

Copy the closed-type approach into Swift: a versioned `Sendable` protocol; immutable requirement; explicit installed attestation and closed result/reason enums. Do not copy Elixir’s extensible `atom()` failure type: Phase 161 requires the explicitly closed reason vocabulary. The public type must expose neither `URL`, path, archive layout, raw digest, nor `Error`.

### `PackStore.swift` (store, event-driven)

**Analog:** existing `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/PackStore.swift`

**Observable actor-bound state** (lines 55-79):

```swift
@MainActor
public final class PackStore: ObservableObject {
    @Published public private(set) var statuses: [String: RequiredPackStatus]

    public func blockingStatus(for packReferences: [String]) -> RequiredPackStatus? {
        packReferences
            .compactMap(parse(packReference:))
            .compactMap { statuses[$0.packID] ?? fallbackStatus(packID: $0.packID, requiredVersion: $0.requiredVersion) }
            .first(where: { $0.state != .available })
    }
}
```

**Safe state derivation** (lines 182-228):

```swift
if record.status == "invalidating" {
    state = .invalidating
} else if record.integrityStatus != "verified" || record.verifiedAt == nil {
    state = .failed
    failureReason = "verification_missing"
} else if record.installedVersion != requiredVersion {
    state = .stale
} else {
    state = .available
}
```

Retain the store’s `@MainActor`, published private-set status map, and activation-facing `blockingStatus`. Replace lines 81-131’s simulated `Task.sleep` success with injected provider calls, closed-result validation, and fresh `status(for:)` reconciliation. Cold starts must seed `checking`, then reconcile; only an exact ID/version/size plus verified-atomic-promotion attestation can write `available`. Persisted invalidation intent must block before calling the provider and stay blocked on failure.

### `ActivationCoordinator.swift` (controller/coordinator, request-response)

**Analog:** existing `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift`

**Dependency injection and bounded fallback** (lines 221-249):

```swift
private let packStore: PackStore
private let config: CrosswakeShellConfig

public init(..., packStore: PackStore, config: CrosswakeShellConfig) {
    self.packStore = packStore
    self.config = config
}
```

**Fail-closed route gate** (lines 376-385):

```swift
if let blockingPack = packStore.blockingStatus(for: route.packs) {
    transferCoordinator = nil
    return .requiredPack(
        RequiredPackPresentation(routeID: route.id, runtimeLabel: "LiveView", status: blockingPack)
    )
}
```

Keep this gate before runtime resolution. Bootstrap must await/reconcile required packs before activation (or present `checking`); reactivation remains the single post-operation route-resolution path. Do not create a WebView fallback or transfer authority for unavailable media.

### `CrosswakeShellConfig.swift` and `CrosswakeShellApp.swift` (config/composition root, request-response)

**Analogs:** existing `CrosswakeShellConfig.swift`; `examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift`

**Optional host delegate wiring** (`CrosswakeShellConfig.swift` lines 3-31):

```swift
public weak var permissionStatusDelegate: PermissionStatusDelegate?

public init(..., permissionStatusDelegate: PermissionStatusDelegate? = nil, ...) {
    self.permissionStatusDelegate = permissionStatusDelegate
}
```

**Composition-root injection** (`CrosswakeShellApp.swift` lines 194-215):

```swift
let config = CrosswakeShellConfig(
    appInfoDelegate: appInfoProvider,
    hapticsDelegate: hapticsProvider,
    permissionStatusDelegate: permissionProvider,
    notificationTokenDelegate: notificationTokenProvider,
    shareDelegate: uiActionDelegates,
    filesPickDelegate: uiActionDelegates,
    routeDelegate: routeDelegate
)
_shell = StateObject(wrappedValue: CrosswakeShell(config: config))
```

Add the provider exactly as an optional host-supplied dependency, then instantiate the concrete provider only in the example host composition root. A nil provider is an explicit blocked state, never a bundled inventory fallback. Keep expected size/digest configuration host-private.

### `PackStoreTests.swift` and `PackProviderFixtureTests.swift` (tests, event-driven/file-I/O)

**Analog:** `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/ActivationConformanceTests.swift`

**Test factory style** (lines 20-69):

```swift
func makeCoordinator(..., packStore: PackStore) -> ActivationCoordinator {
    ActivationCoordinator(
        manifestLoader: { manifest },
        requestLoader: { request },
        packStore: packStore,
        config: CrosswakeShellConfig()
    )
}
```

**Fail-closed assertion shape** (lines 107-137):

```swift
let result = coordinator.resolve(request: request, manifest: manifest)
guard case let .requiredPack(presentation) = result else {
    XCTFail("Expected requiredPack presentation, got \(result)")
    return
}
XCTAssertEqual(presentation.routeID, "dashboard")
```

Add deterministic fake providers only for closed-result/malformed/nil/failure injection. Put real fixture byte streaming, SHA-256, same-volume promotion, faulting persistence, last-known-good preservation, serialization, invalidation/relaunch in the fixture-provider test suite. Keep paths/digests/raw provider errors out of failure messages and test output. Follow the existing bundle resource convention in `Package.swift` lines 23-28 for the immutable non-sensitive test fixture.

### `PronunciationPackProvider.swift` (host provider/service, file-I/O)

**Closest analog:** `examples/ios_shell_host/CrosswakeShell/PermissionStatusProvider.swift` (host-owned delegate implementation); **no file-I/O provider analog exists.**

**Host-owned concrete provider shape** (same app’s `NotificationTokenProvider`, lines 87-126):

```swift
@MainActor
final class NotificationTokenProvider: ObservableObject, NotificationTokenDelegate {
    private(set) var registrationState = "unconfigured"

    func markConfigured() { ... }
    func currentToken() -> BridgeChannel.NotificationTokenCommandSnapshot { ... }
}
```

Use the ownership pattern (concrete host class conforming to a core protocol) but deliberately change isolation: the pack provider should be a per-pack actor / non-`@MainActor` implementation. It owns Application Support lookup, uniquely named same-volume staging, incremental CryptoKit hashing, atomic replacement, and private inventory persistence. Return only closed `PackProviderResult` facts; never add public asset lookup.

### `RequiredPackView.swift` (component, event-driven)

**Analog:** existing `examples/ios_shell_host/CrosswakeShell/RequiredPackView.swift`

**Semantic action selection** (lines 80-112):

```swift
Button(primaryTitle, action: primaryHandler)
    .buttonStyle(.borderedProminent)
    .disabled(status.state == .installing || status.state == .invalidating || status.state == .checking)

switch status.state {
case .notInstalled: return "Install Required Pack"
case .stale: return "Update Pack"
case .failed: return "Retry Install"
```

Retain one primary action and disabled transient states, but add stable accessibility identifiers and announcements. Render only semantic state, closed reason/rule, owner, and safe remediation; do not render archive paths, hashes, transport data, or raw provider errors. Preserve text alongside state color and Dynamic-Type-safe scroll layout.

### Phase 159 proof templates (template/test, request-response and event-driven)

**Analogs:** `ProofLaneDriver.swift.eex`, `ProofLaneContractTests.swift.eex`, and `ProofLaneUITests.swift.eex`

**Narrow host-adapter contract** (`ProofLaneDriver.swift.eex` lines 4-20):

```swift
enum ProofLaneOutcome: String { case passed, blocked, unavailable }
struct ProofLaneSnapshot { let outcome: ProofLaneOutcome; let prerequisite: ProofLanePrerequisite; let shellBooted: Bool }
protocol ProofLaneHostAdapter {
  func observe() -> ProofLaneSnapshot
  var retry: (() -> Void)? { get }
}
```

Extend this contract with one host-supplied installed-audio exercise operation and retain only closed outcome/prerequisite facts. It must not return a URL, archive path/layout, digest, bytes, or raw playback error.

**Process/relaunch and accessibility test form** (`ProofLaneUITests.swift.eex` lines 4-12, 46-52):

```swift
app.launch()
assertAdapterDerivedPassedOutcome(in: app)
app.terminate()
app.launch()
assertAdapterDerivedPassedOutcome(in: app)

XCTAssertTrue(outcome.label.hasPrefix("Passed: "))
```

Add visible missing-provider denial, foreground install-to-ready, relaunched reconciliation, and offline-audio assertions through stable IDs only. Continue treating simulator/XCUITest runs as advisory; Phase 162 alone promotes physical-iPhone proof.

### `lib/crosswake/proof_lane/evidence.ex` and proof-lane ExUnit tests (service/test, transform)

**Analog:** existing `lib/crosswake/proof_lane/evidence.ex`

**Allowlisted retained evidence** (lines 9-36, 50-57):

```elixir
@schema_keys [:schema_version, :crosswake_version, :template_version, :commit_ref,
              :route_id, :assertion_ids, :status, :outcome, :captured_at,
              :retention_label, :device_class, :approved_hashes]
@outcomes [:passed, :blocked, :unavailable]
@assertion_ids ~w(browser_offline_island shell_boot auth_continuity relaunch_persistence replay_prerequisite pack_audio_prerequisite)

with :ok <- atom_keys(input),
     :ok <- exact_keys(input),
     :ok <- no_sensitive_value(input) do
  validate_fields(input)
end
```

Keep the existing `pack_audio_prerequisite` identifier—do not introduce a support-label family. Extend its contract tests so a pass requires the new closed adapter result and real-byte prerequisite, while retained evidence remains assertion IDs and closed outcomes only. Preserve the sensitive-term and URL rejection behavior at lines 169-201.

## Shared Patterns

### Fail-closed lifecycle and activation

**Sources:** `PackStore.swift` lines 74-79 and `ActivationCoordinator.swift` lines 376-385.  
**Apply to:** provider result mapping, store reconciliation, coordinator bootstrap, and tests.

Only `.available` is unblocking. Every nil provider, malformed/unknown result, cancellation, mismatch, failed persistence/promotion, and failed invalidation must resolve to a displayed blocked lifecycle state.

### Core/host ownership boundary

**Sources:** `CrosswakeShellConfig.swift` lines 3-31 and `CrosswakeShellApp.swift` lines 194-215.  
**Apply to:** `PackProvider.swift`, config, reference host provider, and proof adapter.

The core declares typed capability and validates closed facts; the host provides concrete implementation and private configuration. No URLs, credentials, filesystem objects, archive layout, codec, or playback API crosses the core contract.

### Privacy-safe evidence

**Source:** `lib/crosswake/proof_lane/evidence.ex` lines 9-36 and 169-201.  
**Apply to:** all proof output, diagnostics, and failure tests.

Retain only approved assertion IDs and closed outcomes. Explicitly reject raw media, paths, URLs, digests, archive names, `.xcresult`, screenshots, logs, and raw output.

### Test ownership split

**Sources:** `ActivationConformanceTests.swift` lines 20-137 and `ProofLaneUITests.swift.eex` lines 4-65.  
**Apply to:** all Phase 161 tests.

XCTest owns provider/storage byte and lifecycle fault injection; XCUITest owns stable-ID, user-visible installation/relaunch/offline-playback behavior. No new Android or physical-device lane belongs to this phase.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `PronunciationPackProvider.swift` | host provider | file-I/O | No existing host archive/staging/hash/atomic-promotion implementation; follow the narrow provider contract plus research’s host-only implementation constraints. |
| `PackProviderFixtureTests.swift` | test | file-I/O | Existing Swift tests cover activation only; no real-byte or faulting filesystem fixture precedent exists. |
| `PackProvider.swift` | provider contract | request-response | No Swift provider protocol with a versioned closed result exists; use the Elixir closed-contract precedent without copying its open failure atom. |

## Metadata

**Analog search scope:** `packages/crosswake-shell-core-ios`, `examples/ios_shell_host`, `priv/templates/crosswake/proof_lane/ios`, `lib/crosswake/packs`, `lib/crosswake/proof_lane`, `test/crosswake/proof_lane`  
**Files scanned:** 30 source/template/test files (build outputs excluded)  
**Pattern extraction date:** 2026-08-03
