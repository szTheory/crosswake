# Crosswake Parity Ledger

Canonical owner: `Crosswake.ParityLedger`.
Regenerate with `mix crosswake.contract.gen && mix crosswake.docs.sync`.

This guide is rendered from the shared contract corpora, the generated native constants and a registry of the tests that read each corpus. It shows which existing contracts the Elixir, Swift and Android suites execute, and which they do not.

The vector-set hash is the SHA-256 of the raw bytes of the shared bridge corpus. Equal hashes prove that the Swift and Kotlin suites load identical corpus bytes. They do not prove that the assertions in those suites are semantically equivalent.

The evidence is continuous integration on the repository head, not on a published artifact. `JVM test executed` means a Kotlin unit test ran on the JVM in CI; it says nothing about Android hardware.

The vector-set hash and this ledger ship from 0.2.12 on; 0.2.11 and earlier have neither.

## Corpora

The bridge corpus is shared: three byte-identical copies, one hash, and a generated constant on each native side that must equal it. Every other corpus is read from one location, so its hash is informational and no native constant pins it.

The vector-set hash and this ledger ship from 0.2.12 on; 0.2.11 and earlier have neither.

| Corpus | Files | Bytes sha256 | Shared | Android evidence | Elixir consumer | Swift consumer | Android consumer | Pinned executions |
|--------|-------|--------------|--------|------------------|-----------------|----------------|------------------|-------------------|
| bridge_contract_vectors | `test/fixtures/bridge_contract_vectors.json`; `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json`; `packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json` | sha256:3b64c8d81e1ca086494a1910aa5fb2d05d7a2d263b3d72f229f319d22e0064c0 | yes | JVM hermetic proof | `bridge_behavioral_vector_test.exs` (behavioral) | `BridgeConformanceTests.swift` (behavioral); `BridgeReplyLegTests.swift` (behavioral); `ActivationConformanceTests.swift` (metadata); `OfflineIslandAdmissionTests.swift` (metadata); `Phase180TwinFeasibilityTests.swift` (metadata); `VectorCorpusTests.swift` (integrity) | `BridgeConformanceTest.kt` (behavioral); `BridgeReplyLegTest.kt` (behavioral); `ActivationConformanceTest.kt` (metadata); `VectorCorpus.kt` (integrity); `VectorCorpusTest.kt` (integrity); `BridgeFixtures.kt` (integrity) | 15 loaded, 14 native, 9 Elixir, 2 reply-leg |
| navigation_topology_vectors | `priv/contract_vectors/navigation_topology_vectors.json` | sha256:eb5473bfcb4cb452fe86098823ac7024d12a19ef3bc8743e921c90e93122afe1 | no | not claimed | no consumer | `NavigationCoordinatorTests.swift` (behavioral) | no consumer | - |
| navigation_transition_vectors | `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/navigation_transition_vectors.json` | sha256:011e457eb55c05036a925c6b8b6fea4d05e52aa6e62c9faa94ae2ebe892d5ab2 | no | not claimed | no consumer | no consumer | no consumer | - |

A consumer is a declared test file that reads the corpus. `behavioral` executes vectors and asserts outcomes, `metadata` reads fields without executing each vector, and `integrity` loads or verifies the bytes. Only behavioral consumers produce an executed cell in the next section. A scan of the Kotlin and Swift test trees fails the registry check if a file names a corpus without being declared.

The navigation transition corpus has no test reader. Its only reader is the advisory navigation proof input, which records a file digest and executes no vector.

## Vectors

One row per vector. `ExUnit executed`, `Swift test executed` and `JVM test executed` mean a declared behavioral test ran that vector. `not applicable` means the vector is scoped away from that platform: Elixir-only vectors are not run natively, native-only vectors are not run in Elixir, and a reply leg is produced by the native shell. `no consumer` means no declared behavioral test reads that vector on that platform.

| Corpus | Vector | Expected outcome | Denial reason | Elixir | Swift | Android |
|--------|--------|------------------|---------------|--------|-------|---------|
| bridge_contract_vectors | vec-001-version-mismatch-deny | deny | compatibility_mismatch | ExUnit executed | not applicable | not applicable |
| bridge_contract_vectors | vec-002-unknown-command-deny | deny | undeclared_capability | ExUnit executed | Swift test executed | JVM test executed |
| bridge_contract_vectors | vec-003-canonical-version-ok | ok | - | ExUnit executed | Swift test executed | JVM test executed |
| bridge_contract_vectors | vec-004-inactive-route-deny | deny | inactive_route | ExUnit executed | Swift test executed | JVM test executed |
| bridge_contract_vectors | vec-005-origin-denied-deny | deny | origin_denied | ExUnit executed | Swift test executed | JVM test executed |
| bridge_contract_vectors | vec-006-pack-incompatible-deny | deny | pack_incompatible | ExUnit executed | Swift test executed | JVM test executed |
| bridge_contract_vectors | vec-007-capability-version-deny | deny | unavailable_capability | ExUnit executed | Swift test executed | JVM test executed |
| bridge_contract_vectors | vec-008-floor-bridge-shell-newer-allow | ok | - | not applicable | Swift test executed | JVM test executed |
| bridge_contract_vectors | vec-009-floor-bridge-shell-older-deny | deny | compatibility_mismatch | not applicable | Swift test executed | JVM test executed |
| bridge_contract_vectors | vec-010-floor-native-runtime-shell-newer-allow | ok | - | not applicable | Swift test executed | JVM test executed |
| bridge_contract_vectors | vec-011-floor-native-runtime-shell-older-deny | deny | compatibility_mismatch | not applicable | Swift test executed | JVM test executed |
| bridge_contract_vectors | vec-014-floor-capability-shell-newer-allow | ok | - | ExUnit executed | Swift test executed | JVM test executed |
| bridge_contract_vectors | vec-015-floor-capability-shell-older-deny | deny | unavailable_capability | ExUnit executed | Swift test executed | JVM test executed |
| bridge_contract_vectors | vec-016-floor-pack-shell-newer-allow | ok | - | not applicable | Swift test executed | JVM test executed |
| bridge_contract_vectors | vec-017-floor-pack-shell-older-deny | deny | pack_incompatible | not applicable | Swift test executed | JVM test executed |
| bridge_contract_vectors | vec-reply-001-ok-landing-pad | ok | - | not applicable | Swift test executed | JVM test executed |
| bridge_contract_vectors | vec-reply-002-adversarial-denial-message | deny | unavailable_capability | not applicable | Swift test executed | JVM test executed |
| navigation_topology_vectors | synthetic_authorized_root | ready | - | no consumer | Swift test executed | no consumer |
| navigation_topology_vectors | empty_inventory | unknown_blocking | - | no consumer | no consumer | no consumer |
| navigation_topology_vectors | invalid_parent | ready | - | no consumer | no consumer | no consumer |
| navigation_topology_vectors | incompatible_manifest | ready | - | no consumer | no consumer | no consumer |
| navigation_topology_vectors | authorization_denial | ready | - | no consumer | no consumer | no consumer |
| navigation_transition_vectors | navigate-once | applied | - | no consumer | no consumer | no consumer |
| navigation_transition_vectors | patch-no-growth | applied | - | no consumer | no consumer | no consumer |
| navigation_transition_vectors | duplicate | denied | - | no consumer | no consumer | no consumer |
| navigation_transition_vectors | malformed | denied | - | no consumer | no consumer | no consumer |

## Android-only commands

The Android shell parses these command wire values, but no shared vector lists them.

| Command | Status |
|---------|--------|
| `server.event.push` | Outside shared vectors and ungated. No platform is held to a shared contract for it, and its Android behavior is open debt, not a parity claim. |
| `server.state.update` | Outside shared vectors and ungated. No platform is held to a shared contract for it, and its Android behavior is open debt, not a parity claim. |
