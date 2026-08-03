# Phase 161: iOS Pronunciation Pack Seam - Research

**Researched:** 2026-08-03
**Domain:** iOS foreground immutable-media installation, integrity verification, and fail-closed route activation
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

## Implementation Decisions

### Provider trust boundary

- **D-01:** Add one narrow, versioned Swift `PackProvider` contract with asynchronous
  `status(for:)`, `install(_:)`, and `invalidate(_:)` operations. Each operation consumes an
  immutable `PackRequirement` and returns a closed typed result; arbitrary thrown provider details
  never become lifecycle, diagnostics, or proof data. — **Reversibility:** costly — once external
  iOS hosts implement the protocol, changing callback semantics or result cases requires a native
  compatibility migration.

- **D-02:** `PackRequirement` contains only opaque pack ID, exact required version, expected byte
  count, and expected SHA-256. Exact integrity values live in host-private native configuration,
  not the durable route inventory, public guides, diagnostics, or evidence. URLs, credentials,
  paths, archive names, content layout, codecs, and retention do not cross the provider seam.

- **D-03:** Treat the provider as trusted in-process host code. Crosswake validates that a returned
  installed record exactly binds to the requested ID, version, and size and attests verified
  integrity plus completed atomic promotion. Crosswake does not accept a filesystem URL and
  independently become the archive store. Nil providers, malformed/unknown results, cancellation,
  and operation failures remain non-available.

- **D-04:** The host provider stages a uniquely named artifact in Application Support on the final
  volume, streams SHA-256 off the main actor, compares exact size and digest, atomically
  replaces/promotes only verified bytes, and persists inventory only after commit. Heavy download,
  hashing, and file I/O never run on `@MainActor`.

- **D-05:** Provider operations are serialized per pack. `status` is side-effect-free; `install`
  and `invalidate` are idempotent for the same requirement. Staging files and an install command's
  return alone never grant availability.

### Restart, inventory, and invalidation truth

- **D-06:** On cold launch every required pack starts as `checking`. Crosswake reconciles provider
  storage into its closed inventory before activation. A prior `installing` or `invalidating`
  display state is never resumed optimistically after process death; staged debris is not
  inventory.

- **D-07:** Installation success must be followed by fresh provider status reconciliation before
  Crosswake records `available`. Route resolution within the running process consumes the current
  reconciled inventory rather than synchronously rehashing an archive on every navigation.

- **D-08:** Preserve a committed last-known-good artifact until its replacement is fully verified
  and atomically promoted. A failed update cannot destroy it. If the current declaration requires a
  newer version, retained old bytes are `stale` and route-blocking, not a fallback that silently
  activates.

- **D-09:** Invalidation is a trust-revocation operation, not merely best-effort deletion.
  Crosswake revokes availability before calling the provider, persists pending invalidation across
  relaunch, maps success to `not_installed`, and keeps `invalidation_failed` blocked even when bytes
  remain. Only successful invalidation or a later fully verified reinstall clears the revocation.

- **D-10:** Verification timestamps and last-known version are diagnostic context only. They never
  substitute for exact current requirement reconciliation or create authority.

### Failure and recovery contract

- **D-11:** Preserve the existing high-level lifecycle states: `checking`, `not_installed`,
  `installing`, `available`, `stale`, `invalidating`, and `failed`. Add a closed reason vocabulary:
  `provider_unavailable`, `transfer_interrupted`, `insufficient_storage`, `size_mismatch`,
  `digest_mismatch`, `version_mismatch`, `atomic_install_failed`,
  `inventory_persistence_failed`, `invalidation_failed`, `malformed_provider_result`, and
  `provider_failed`. — **Reversibility:** costly — these values feed host UI, diagnostics, tests,
  and retained low-cardinality proof, so renaming them requires a contract-version migration.

- **D-12:** Provider SDK errors are caught and mapped to the closed reasons. Raw errors, paths,
  URLs, response bodies, archive details, digest values, and file contents never reach telemetry,
  doctor output, inspection, logs, UI defaults, or evidence. Unknown bounded failures map to
  `provider_failed` without echoing input.

- **D-13:** Recovery is explicit and foreground-only: `not_installed` offers Install, `stale`
  offers Update, retryable failure offers Retry, and corrupt/revoked state offers the appropriate
  Invalidate-then-Install path. There is no automatic retry loop, background continuation, or
  silent downgrade to online-only mutation behavior.

- **D-14:** Crosswake exposes semantic state, permitted actions, owning layer, stable reason IDs,
  and stable accessibility identifiers. The host owns final learner copy and presentation. The
  reference/example view uses one primary action per state, text in addition to color, Dynamic
  Type-safe controls, accessible progress/status announcements, stable focus, reduced-motion-safe
  transitions, and system light/dark colors.

- **D-15:** Keep learner copy task-oriented and hide backend mechanics. Example learner failure:
  “Offline audio could not be verified. Try the download again while connected.” Developer
  diagnostics may name the stable rule and owner, for example `PACK-DIGEST-MISMATCH`, host pack
  provider, and the safe remediation. Success copy is brief: “Pronunciation audio is ready for
  offline use.”

### Phase 159 proof hookup and Phase 162 readiness

- **D-16:** Extend the existing generated proof lane rather than creating a new harness. A real
  local immutable fixture archive and a reference host provider are required acceptance evidence;
  fakes remain useful for exhaustive closed-result and failure injection tests but cannot replace
  genuine byte, hash, persistence, and atomic-promotion proof.

- **D-17:** XCTest owns deterministic provider and storage contracts: success from real fixture
  bytes; wrong size/digest/version; interruption; insufficient-storage, write, promotion, and
  persistence failures; same-volume atomic replacement; last-known-good preservation; explicit and
  failed invalidation; per-pack operation serialization; nil/malformed providers; and a newly
  instantiated provider/store proving relaunch reconciliation.

- **D-18:** XCUITest owns only user-observable behavior through stable accessibility identifiers:
  missing-provider denial, foreground installation to ready, terminate/relaunch persistence, and
  installed pronunciation audio playback with networking disabled. It does not inspect Swift
  internals, filesystem paths, archive layout, credentials, or hidden test authority.

- **D-19:** Do not add asset resolution to the public `PackProvider`. Offline-island audio
  consumption remains host-owned. The Phase 159 proof adapter gains only a narrow host-supplied
  operation that exercises installed pronunciation audio and reports the existing closed proof
  outcome; it does not expose archive paths or layout.

- **D-20:** Phase 161 makes deterministic `pack_audio_prerequisite` assertions capable of passing
  with real local bytes. Simulator/native-toolchain execution remains advisory and non-promoting.
  Phase 162 runs the same generated command on a physical iPhone and owns dated promotion.

- **D-21:** Recurring CI may protect Swift contract/fixture behavior, generator drift, failure
  mapping, accessibility identifiers, and privacy scanning. It does not gain a permanent physical
  device lane. Retained evidence contains only approved assertion IDs and closed outcomes—never
  archive bytes, digest values, URLs, paths, media, `.xcresult`, screenshots, logs, or raw output.

### the agent's Discretion

The user selected all four gray areas and delegated a coherent one-shot recommendation after
parallel expert research. Planning may choose exact Swift type and method names, internal actor or
serialization mechanics, private inventory encoding, test-fixture bytes, accessibility identifier
names, and the host-owned proof callback name. It may not weaken the requirement-bound provider,
closed results, relaunch reconciliation, revocation semantics, real-byte proof, host/core ownership,
privacy exclusions, explicit non-passing states, or Phase 161/162 evidence boundary.

### Deferred Ideas (OUT OF SCOPE)

None recorded in CONTEXT.md.
</user_constraints>

## Project Constraints (from AGENTS.md)

- Crosswake remains a Phoenix-first route-policy/runtime-contract system; each route retains explicit runtime ownership and no generic WebView/native-rendering abstraction is introduced.
- iOS-only foreground media work: Android is frozen; generic sync/storage, background transfer, native menu breadth, capture, scoring, dashboard, and commerce work are out of scope.
- Offline claims must distinguish cached read-only from local mutation; denials must be explicit and fail closed.
- Keep bridge APIs semantic, typed, versioned, and low-frequency; continuous offline authority belongs to the host/offline island.
- Never emit raw media, transcript, archive bytes, URLs, paths, credentials, account identifiers, tokens, or stable device identifiers to diagnostics, logs, inspection, telemetry, or proof.
- Preserve opaque scope/replay and backend-auth boundaries established by Phase 160.
- Automate every check that can be automated; do not plan human verification or UAT for deterministic contract, filesystem, simulator, or artifact checks.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PACK-01 | Host-supplied iOS foreground status/install/invalidate seam | Versioned async `PackProvider`, nil denial, per-pack serialization and reconciled inventory. |
| PACK-02 | Invalid conditions never report available | Closed provider result/reason mapping; status reconciliation is the sole availability authority. |
| PACK-03 | One immutable archive is size/SHA-256 verified then atomically installed | Host stages in Application Support, streams CryptoKit SHA-256, compares exact bytes, then promotes. |
| PACK-04 | Explicit Crosswake/host ownership boundary | Responsibility map and narrow non-path-bearing protocol prevent storage/distribution leakage. |
| PACK-05 | Explicitly no generic distribution/background/Android/scoring work | Non-goal guardrails and proof scope hold the phase to one foreground iOS archive. |

## Summary

Phase 161 should replace only the current simulated `PackStore` success path. The existing activation coordinator already blocks a route whenever `blockingStatus(for:)` returns a non-available status; retain that integration and feed it an inventory produced solely by fresh `PackProvider.status(for:)` reconciliation. `[VERIFIED: codebase grep]` The core must never receive a URL or archive path: it consumes a requirement and a closed provider result, validates the returned ID/version/size/verified-promotion attestation, persists its safe inventory, then allows activation. `[VERIFIED: codebase grep]`

Implement the concrete reference host provider as host-owned foreground work: stage one fixture/download artifact under Application Support on the final volume, count and stream it through `CryptoKit.SHA256`, compare the declared exact size/digest, atomically replace/promote only after verification, and persist host inventory only after promotion. Apple documents iterative SHA-256 updates for data too large for one buffer, Application Support for non-user-visible app support files, and `FileManager.replaceItemAt` as a no-data-loss replacement API. `[CITED: https://developer.apple.com/documentation/cryptokit/sha256] [CITED: https://developer.apple.com/documentation/foundation/using-the-file-system-effectively] [CITED: https://developer.apple.com/documentation/foundation/filemanager]`

The acceptance seam is already Phase 159's generated proof lane. Add the narrow host-owned audio exercise callback and make its `pack_audio_prerequisite` pass only after deterministic real local fixture bytes are installed and played with networking disabled. XCTest carries all byte/storage/relaunch fault injection; XCUITest carries only accessibility-visible installation, relaunch, and offline playback. Simulator/toolchain results remain advisory; physical-iPhone promotion and its dated artifact remain Phase 162. `[VERIFIED: codebase grep]`

**Primary recommendation:** Add a `@MainActor` lifecycle store backed by an injected async, `Sendable` host `PackProvider`; put transfer, hashing, files, and private inventory I/O in a per-pack actor/provider implementation, and accept availability only after a second successful `status` reconciliation.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Requirement declaration and route activation denial | iOS shell core | API/Backend | Core maps route requirements to closed lifecycle inventory; backend does not grant local media authority. `[VERIFIED: codebase grep]` |
| Foreground archive discovery, authentication, download, storage layout, playback | Host iOS adapter | Browser/offline island | The host owns transport, bytes, codecs, archive layout, and audio consumption; the public protocol exposes none of them. `[VERIFIED: 161-CONTEXT.md]` |
| SHA-256/size verification and atomic promotion | Host iOS adapter | iOS filesystem | Verification is performed beside staged bytes before host storage commits. `[CITED: https://developer.apple.com/documentation/cryptokit/sha256]` |
| Reconciled safe inventory and lifecycle state | iOS shell core | Host iOS adapter | Provider returns closed facts; Crosswake validates/binds them and drives activation state. `[VERIFIED: codebase grep]` |
| Deterministic byte/storage proof | XCTest host/core targets | Generated Phase 159 lane | Unit tests inject failures and inspect safe state; they do not disclose byte/path details. `[VERIFIED: 161-CONTEXT.md]` |
| User-observable foreground/relaunch/offline-audio proof | XCUITest generated host | Physical iPhone in Phase 162 | UI tests consume accessibility identifiers; real-device promotion is explicitly deferred. `[VERIFIED: 161-CONTEXT.md]` |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Swift Concurrency (`actor`, `async/await`) | Swift 6.3.3 installed; package minimum Swift 5.9 | Serialize each pack's host operation without blocking UI state | The existing shell uses `@MainActor` observable state and async entry points; actors isolate heavy work. `[VERIFIED: codebase grep]` |
| Apple CryptoKit `SHA256` | Xcode SDK 26.5 | Stream and finalize SHA-256 for staged bytes | Apple documents incremental hashing with `update` and `finalize`; use it rather than custom digest code. `[CITED: https://developer.apple.com/documentation/cryptokit/sha256]` |
| Foundation `FileManager` and `URL` | Xcode SDK 26.5 | Application Support, staging, promotion, cleanup | Apple documents Application Support for private support files and item replacement that avoids data loss. `[CITED: https://developer.apple.com/documentation/foundation/using-the-file-system-effectively] [CITED: https://developer.apple.com/documentation/foundation/filemanager]` |
| XCTest / XCUITest | Xcode 26.6 installed | Deterministic core and user-visible lifecycle proof | Existing core XCTest target and generated Phase 159 XCTest/XCUITest targets are the project test surfaces. `[VERIFIED: codebase grep]` |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Codable` | Swift standard library | Encode the private, safe inventory record | Use only for opaque ID/version/size, verification/promotion state, and safe timestamps/reasons. `[VERIFIED: codebase grep]` |
| SwiftUI accessibility APIs | Xcode SDK 26.5 | Stable identifiers/status announcements in reference host UI | Apply to visible lifecycle state and primary action only; final copy remains host-owned. `[VERIFIED: codebase grep]` |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Host-owned foreground provider | Generic Crosswake archive store/distribution API | Rejected: contradicts locked host ownership and PACK-05. `[VERIFIED: 161-CONTEXT.md]` |
| One asynchronous protocol with closed result types | Throwing URLs/filesystem handles across core boundary | Rejected: leaks host storage semantics and raw errors, and makes malformed input harder to fail closed. `[VERIFIED: 161-CONTEXT.md]` |
| XCTest fixture and controlled fault injection | Simulator-only click-through | Rejected: cannot prove byte/hash/atomic/inventory paths exhaustively; simulator is advisory. `[VERIFIED: 161-CONTEXT.md]` |

**Installation:** No new external package is needed. Use Apple SDK frameworks already available to the Swift package. `[VERIFIED: packages/crosswake-shell-core-ios/Package.swift]`

## Package Legitimacy Audit

No external packages are installed in this phase; the Package Legitimacy Gate is not applicable. `[VERIFIED: packages/crosswake-shell-core-ios/Package.swift]`

## Architecture Patterns

### System Architecture Diagram

```text
Route pack declaration
        |
        v
PackStore (@MainActor): checking -> provider.status(requirement)
        |                         |
        |                         +-- nil / malformed / failed --> closed blocked reason
        v
validated reconciled safe inventory
        |
        +-- exact id/version/size + verified promotion --> available --> ActivationCoordinator --> route
        |
        +-- any mismatch/revocation/failure -----------> blocked lifecycle --> RequiredPackView

Foreground install action
        |
        v
host PackProvider actor --> unique Application Support staging --> streamed size + SHA-256
        |                                                                  |
        |<------ failure: retain last-known-good, closed reason ---------+
        v
same-volume atomic promotion --> private host inventory commit --> fresh status reconciliation
```

### Recommended Project Structure

```text
packages/crosswake-shell-core-ios/
├── Sources/CrosswakeShellCore/
│   ├── PackProvider.swift         # public versioned requirement/result contract only
│   ├── PackStore.swift            # lifecycle, reconciliation, revocation, activation inventory
│   └── ActivationCoordinator.swift # existing route gate, unchanged ownership
└── Tests/CrosswakeShellCoreTests/
    ├── PackStoreTests.swift       # core contract and malformed/nil/failure behavior
    └── PackProviderFixtureTests.swift # real bytes, persistence, atomicity/relaunch fixtures
examples/ios_shell_host/CrosswakeShell/
├── PronunciationPackProvider.swift # reference host-only storage/download/audio behavior
└── RequiredPackView.swift          # semantic lifecycle + stable accessibility IDs
priv/templates/crosswake/proof_lane/ios/
└── ...                             # extend existing adapter and XCTest/XCUITest scaffold only
```

### Pattern 1: Closed capability result plus post-operation reconciliation

**What:** Make all three protocol operations `async` and return a non-extensible result payload that contains no thrown SDK error, URL, or path. The store emits transient state, awaits the provider, maps invalid/unknown/cancelled outcomes to a closed failure, then always calls `status(for:)` before making availability durable. `[VERIFIED: 161-CONTEXT.md]`

**When to use:** Every cold launch, install/update/retry, and subsequent route reactivation. `status` must be side-effect-free; only `install` and `invalidate` mutate host storage. `[VERIFIED: 161-CONTEXT.md]`

**Example:**

```swift
// Contract shape; keep names/version enum internal-planning discretion.
public protocol PackProvider: Sendable {
    func status(for requirement: PackRequirement) async -> PackProviderResult
    func install(_ requirement: PackRequirement) async -> PackProviderResult
    func invalidate(_ requirement: PackRequirement) async -> PackProviderResult
}

// The @MainActor store must call status after any non-failed install result.
let result = await provider.install(requirement)
guard case .installed(let record) = result,
      record.matches(requirement), record.integrityVerified, record.atomicPromotionCompleted
else { return failClosed(result) }
await reconcile(requirement) // only this can become .available
```

### Pattern 2: Host-owned staged verification and same-volume promotion

**What:** A host actor writes one uniquely named staging artifact on the destination's volume, reads it in bounded chunks while counting bytes and incrementally hashing, checks the exact requirement, then replaces/promotes the verified artifact and only then writes private inventory. `[CITED: https://developer.apple.com/documentation/cryptokit/sha256] [CITED: https://developer.apple.com/documentation/foundation/filemanager]`

**When to use:** The reference host provider and adopter integration; Crosswake core receives only the attestable record, never storage access. `[VERIFIED: 161-CONTEXT.md]`

**Example:**

```swift
// Runs in the provider actor, never @MainActor.
var digest = SHA256()
var count = 0
while let chunk = try handle.read(upToCount: 64 * 1024), !chunk.isEmpty {
    count += chunk.count
    digest.update(data: chunk)
}
guard count == requirement.expectedByteCount,
      Data(digest.finalize()).hexString == requirement.expectedSHA256
else { throw PackInstallFailure.digestOrSizeMismatch }

// `stagingURL` and `installedURL` are intentionally host-private and same-volume.
try promoteVerifiedStaging(stagingURL, replacing: installedURL)
try persistHostInventory(afterPromotionFor: requirement)
```

### Anti-Patterns to Avoid

- **Timed simulated success:** The current `Task.sleep` path produces `available` without real bytes; delete it rather than retaining it as a fallback. `[VERIFIED: codebase grep]`
- **Provider returns a URL or `Error`:** This violates the sealed/privacy-safe seam; map all host failures to a closed reason at the provider boundary. `[VERIFIED: 161-CONTEXT.md]`
- **Optimistic restart state:** Do not restore `installing`, `invalidating`, or `available` merely from display state; start `checking`, then reconcile. `[VERIFIED: 161-CONTEXT.md]`
- **Delete-first update:** Do not remove last-known-good bytes until replacement is verified and committed; old mismatched bytes must be `stale`, not available. `[VERIFIED: 161-CONTEXT.md]`
- **Inventory-first commit:** Do not write an available record before promotion succeeds; inventory persistence failure must remain blocked. `[VERIFIED: 161-CONTEXT.md]`
- **Public asset lookup:** The proof callback must exercise audio host-side without returning paths/layout through `PackProvider`. `[VERIFIED: 161-CONTEXT.md]`

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SHA-256 | Custom hashing or digest comparison | CryptoKit `SHA256` incremental API | Standard SHA-256 implementation supports chunked updates/finalization. `[CITED: https://developer.apple.com/documentation/cryptokit/sha256]` |
| Filesystem replacement | Delete destination then move staged file | Foundation replacement/promotion on one volume | Replace APIs are designed to avoid data loss; preserve last-known-good on error. `[CITED: https://developer.apple.com/documentation/foundation/filemanager]` |
| Download UX/URL auth/CDN | Crosswake networking/distribution layer | Host application's existing foreground download stack | Locked ownership keeps proprietary transport/layout and credentials outside core. `[VERIFIED: 161-CONTEXT.md]` |
| Device proof harness | New standalone pack test app | Phase 159 generated proof adapter/tests | Prevents duplicate proof systems and preserves host test ownership. `[VERIFIED: 161-CONTEXT.md]` |

**Key insight:** The only reusable Crosswake abstraction is the integrity-bound lifecycle contract; transport, file location, media layout, retention, and playback remain deliberately host-specific. `[VERIFIED: 161-CONTEXT.md]`

## Common Pitfalls

### Pitfall 1: Availability derived from an operation acknowledgement

**What goes wrong:** A provider reports install success or a staging file exists, and the UI becomes `available` without the durable installed record matching the current requirement. `[VERIFIED: 161-CONTEXT.md]`

**How to avoid:** Require an installed record that exactly binds opaque ID, version, and byte count and attests verification/promotion; then perform fresh `status` reconciliation before setting available. `[VERIFIED: 161-CONTEXT.md]`

**Warning signs:** `available` is reachable in a test where status fails, returns malformed data, the inventory write fails, or process restart occurs before reconciliation. `[VERIFIED: 161-CONTEXT.md]`

### Pitfall 2: Losing a valid pack during update

**What goes wrong:** An update deletes or overwrites the old archive before its replacement verifies, leaving no usable artifact after a bad transfer. `[VERIFIED: 161-CONTEXT.md]`

**How to avoid:** Stage separately on the final volume, verify, atomically replace, then persist; retained older bytes are route-blocking `stale` when version no longer matches. `[VERIFIED: 161-CONTEXT.md]`

**Warning signs:** Fault injection after staging or before promotion leaves no old file or allows old-version activation. `[VERIFIED: 161-CONTEXT.md]`

### Pitfall 3: revocation as best-effort deletion

**What goes wrong:** Invalidation fails but a prior inventory record still activates the route. `[VERIFIED: 161-CONTEXT.md]`

**How to avoid:** Persist revocation before provider deletion, block while pending/failed, and clear it only after confirmed invalidation or a fully verified reinstall. `[VERIFIED: 161-CONTEXT.md]`

### Pitfall 4: proof or diagnostics leak host data

**What goes wrong:** Tests export archive paths, hash values, bytes, file contents, SDK errors, or media. `[VERIFIED: 161-CONTEXT.md]`

**How to avoid:** Retain only existing assertion IDs and closed outcomes; tests may inspect private fixtures locally but evidence/doctor/log output must never serialize them. `[VERIFIED: 161-CONTEXT.md]`

## Code Examples

### Streaming SHA-256 over staged bytes

```swift
// Source: Apple CryptoKit SHA256 documentation
var hasher = SHA256()
for try await chunk in stagedFileChunks {
    hasher.update(data: chunk)
}
let digest = hasher.finalize()
// Compare to host-private expected digest without logging either value.
```

Apple documents `SHA256` incremental `update` and `finalize` for inputs too large for a single memory buffer. `[CITED: https://developer.apple.com/documentation/cryptokit/sha256]`

### Fail-closed activation after reconciliation

```swift
// `ActivationCoordinator` continues to ask PackStore for one blocking status.
if let blockingPack = packStore.blockingStatus(for: route.packs) {
    return .requiredPack(.init(routeID: route.id, runtimeLabel: "LiveView", status: blockingPack))
}
// No direct provider or filesystem access belongs here.
```

The current coordinator already has this gate, so planning should evolve PackStore rather than introduce a parallel activation path. `[VERIFIED: codebase grep]`

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Bundled JSON inventory plus timed UI transitions | Host-supplied asynchronous status/install/invalidate and reconciled inventory | Phase 161 | Simulated state cannot establish availability. `[VERIFIED: codebase grep]` |
| Generated proof can report `pack_audio_prerequisite` only as non-passing prerequisite | Generated host proof can pass deterministically only after real fixture install/audio exercise | Phase 161 | Keeps simulator advisory and reserves real-device promotion for Phase 162. `[VERIFIED: 161-CONTEXT.md]` |

**Deprecated/outdated:** `PackStore.installRequiredPack` and `invalidatePack` sleep-driven success behavior must be removed; retaining it as a fallback defeats PACK-02 and PACK-03. `[VERIFIED: codebase grep]`

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A concrete reference host provider can use Foundation's replacement API as the exact promotion primitive on the project’s iOS deployment target. | Architecture Patterns | The implementation may need a small POSIX rename wrapper or a more specific Foundation promotion sequence; retain same-volume and failure tests either way. |
| A2 | The private host inventory encoding can remain `Codable`/file-backed rather than a different host persistence mechanism. | Standard Stack | Planner must keep its schema private and test relaunch behavior regardless of backing store. |

## Open Questions

1. **Exact public Swift compatibility/version marker for `PackProvider`**
   - What we know: D-01 locks a versioned contract and considers result-case changes compatibility-sensitive. `[VERIFIED: 161-CONTEXT.md]`
   - What's unclear: whether versioning is a `contractVersion` field, protocol namespace, or an enum case in the checked-in package API.
   - Recommendation: make the contract version an explicit constant/value in the requirement/result API and add source-level compatibility tests before external host adoption. `[ASSUMED]`

2. **Reference host's private persistence format**
   - What we know: it must survive relaunch, be written only after promotion, and never enter evidence. `[VERIFIED: 161-CONTEXT.md]`
   - What's unclear: JSON file, UserDefaults index, or host-owned database is most appropriate for the example host.
   - Recommendation: use the smallest injectable private store with deterministic failure injection; do not surface it through core or guides. `[ASSUMED]`

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Xcode | Swift package, XCTest/XCUITest, simulator advisory run | ✓ | 26.6 | — `[VERIFIED: local command]` |
| Swift | Shell-core contract/fixture tests | ✓ | 6.3.3; package declares Swift tools 5.9 | — `[VERIFIED: local command]` |
| iOS SDK | CryptoKit/Foundation/iOS shell build | ✓ | 26.5 | — `[VERIFIED: local command]` |
| Physical iPhone | Phase 162 promotion only | Not required in Phase 161 | — | Keep Phase 161 hardware-free and advisory. `[VERIFIED: 161-CONTEXT.md]` |

**Missing dependencies with no fallback:** None for Phase 161 planning. `[VERIFIED: local command]`

**Missing dependencies with fallback:** None. `[VERIFIED: local command]`

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Swift XCTest for `CrosswakeShellCore`; generated XCTest/XCUITest host proof from Phase 159. `[VERIFIED: codebase grep]` |
| Config file | [Package.swift](../../../packages/crosswake-shell-core-ios/Package.swift) plus generated Xcode project/scheme. `[VERIFIED: codebase grep]` |
| Quick run command | `swift test --package-path packages/crosswake-shell-core-ios` |
| Full suite command | `mix test test/crosswake/proof_lane test/crosswake/offline/proof_lane_test.exs test/crosswake/proof_lane/ios_verifier_test.exs && swift test --package-path packages/crosswake-shell-core-ios` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PACK-01 | Async versioned provider contract; nil provider is blocked; status is side-effect-free | XCTest unit + compile contract | `swift test --package-path packages/crosswake-shell-core-ios --filter PackStoreTests/testNilProviderIsUnavailable` | ❌ Wave 0 |
| PACK-02 | interruption/storage/size/digest/version/promotion/persistence/malformed failures never become available | XCTest unit/fault injection | `swift test --package-path packages/crosswake-shell-core-ios --filter PackProviderFixtureTests` | ❌ Wave 0 |
| PACK-03 | real immutable fixture bytes are counted, SHA-256 verified, atomically promoted, then reconciled | XCTest integration fixture | `swift test --package-path packages/crosswake-shell-core-ios --filter PackProviderFixtureTests/testVerifiedFixturePromotesThenReconcilesAvailable` | ❌ Wave 0 |
| PACK-04 | core/host boundary excludes URL/path/error/archive layout and activation stays gate-owned | XCTest/API-shape + Elixir template contract | `mix test test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs` | Partial; extend Wave 0 |
| PACK-05 | no background/generic/Android claims; retained proof output contains only allowlisted closed values | ExUnit source/evidence contract | `mix test test/crosswake/proof_lane/evidence_test.exs test/crosswake/proof_lane/template_contract_test.exs` | ✅ extend assertions |
| PACK-01/03 | missing-provider denial, install-to-ready, relaunch persistence, host-owned offline audio operation | XCUITest generated-host behavior (simulator advisory) | generated Phase 159 iOS proof command after template rendering | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** affected Swift XCTest or focused ExUnit template/evidence test, plus formatting/typecheck. `[VERIFIED: AGENTS.md]`
- **Per wave merge:** full Swift package suite and focused Phase 159 proof-lane ExUnit suite. `[VERIFIED: codebase grep]`
- **Phase gate:** full suite green; generated iOS simulator/XCUITest run is advisory/non-promoting; no human UAT. `[VERIFIED: 161-CONTEXT.md]`

### Wave 0 Gaps

- [ ] `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/PackStoreTests.swift` — lifecycle/reconciliation/revocation and activation denial.
- [ ] `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/PackProviderFixtureTests.swift` plus a non-sensitive immutable fixture resource — real bytes, digest, atomic promotion, persistence and faults.
- [ ] A host-private fixture provider/storage abstraction enabling deterministic transfer/write/promotion/persistence error injection without logging details.
- [ ] Generated proof-lane adapter/contract/UI template changes for closed `pack_audio_prerequisite`, stable IDs, terminate/relaunch, and offline audio operation.
- [ ] ExUnit source/template/evidence regressions that reject asset paths, URLs, digest values, archive bytes, and raw output from retained evidence.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No direct auth implementation | Preserve Phase 160 backend-auth authority; provider never receives credentials through Crosswake. `[VERIFIED: 161-CONTEXT.md]` |
| V3 Session Management | No | Do not couple pack availability to tokens/session identifiers. `[VERIFIED: AGENTS.md]` |
| V4 Access Control | Yes | Activation allows only exact reconciled requirement; missing/malformed/nil provider blocks. `[VERIFIED: 161-CONTEXT.md]` |
| V5 Input Validation | Yes | Treat every provider response as untrusted at the core seam: exact ID/version/size and closed-case validation. `[VERIFIED: 161-CONTEXT.md]` |
| V6 Cryptography | Yes | Use CryptoKit SHA-256; compare exact expected digest without diagnostic exposure. `[CITED: https://developer.apple.com/documentation/cryptokit/sha256]` |
| V14 Configuration | Yes | Keep expected digest/size in host-private native configuration and not generated/public/evidence surfaces. `[VERIFIED: 161-CONTEXT.md]` |

### Known Threat Patterns for iOS pack seam

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Corrupt or substituted staged bytes | Tampering | Exact expected byte count and SHA-256 before promotion; reject mismatch. `[VERIFIED: 161-CONTEXT.md]` |
| Provider falsely reports availability | Spoofing | Validate returned record against requirement and require verified-promotion attestation plus fresh status. `[VERIFIED: 161-CONTEXT.md]` |
| Update failure destroys known-good bytes | Denial of service | Separate staging and atomic promotion only after verification. `[VERIFIED: 161-CONTEXT.md]` |
| Failed deletion reactivates revoked media | Elevation of privilege | Persist revocation first; failed invalidation remains blocked. `[VERIFIED: 161-CONTEXT.md]` |
| Paths/URLs/digests/raw errors leak through proof or diagnostics | Information disclosure | Closed reason IDs and evidence allowlist; never serialize host-private data. `[VERIFIED: 161-CONTEXT.md]` |
| Concurrent install/invalidate races | Tampering/DoS | Serialize per pack and make mutations idempotent for one requirement. `[VERIFIED: 161-CONTEXT.md]` |

## Sources

### Primary (HIGH confidence)

- Local implementation: `PackStore.swift`, `ActivationCoordinator.swift`, existing XCTest target, and Phase 159 templates — current timed success, activation gate, and reusable proof seams. `[VERIFIED: codebase grep]`
- [Phase 161 context](161-CONTEXT.md) — locked lifecycle, ownership, privacy, proof, and non-goal decisions. `[VERIFIED: 161-CONTEXT.md]`
- [Apple CryptoKit SHA256](https://developer.apple.com/documentation/cryptokit/sha256) — iterative hashing API. `[CITED: https://developer.apple.com/documentation/cryptokit/sha256]`
- [Apple Foundation file-system guidance](https://developer.apple.com/documentation/foundation/using-the-file-system-effectively) — Application Support and file persistence guidance. `[CITED: https://developer.apple.com/documentation/foundation/using-the-file-system-effectively]`
- [Apple FileManager](https://developer.apple.com/documentation/foundation/filemanager) — replacement API and thread-safety documentation. `[CITED: https://developer.apple.com/documentation/foundation/filemanager]`

### Secondary (MEDIUM confidence)

- Apple documentation was fetched through WebSearch because Context7 MCP is unavailable in this runtime; the research seam classified the verified WebSearch provider as MEDIUM. `[VERIFIED: research seam]`

### Tertiary (LOW confidence)

- None beyond A1–A2, which are explicitly marked `[ASSUMED]`.

## Metadata

**Confidence breakdown:**

- Standard stack: MEDIUM — Apple official docs were retrieved through the MEDIUM verified-web provider; project SDK/tool versions were checked locally.
- Architecture: HIGH — locked Phase 161 decisions and exact current code seams agree.
- Pitfalls: HIGH — all are direct locked lifecycle/security requirements or current timed-simulation behavior.

**Research date:** 2026-08-03
**Valid until:** 2026-08-10 (fast-moving planned contract and immediate phase window)
