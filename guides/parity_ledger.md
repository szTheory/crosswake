# Crosswake Parity Ledger

Canonical owner: `Crosswake.ParityLedger`.
Regenerate with `mix crosswake.contract.gen && mix crosswake.docs.sync`.

This guide is rendered from the shared contract corpora, the generated native constants and a registry of the tests that read each corpus. It shows which existing contracts the Elixir, Swift and Android suites execute, and which they do not.

The vector-set hash is the SHA-256 of the raw bytes of the shared bridge corpus. Equal hashes prove that the Swift and Kotlin suites load identical corpus bytes. They do not prove that the assertions in those suites are semantically equivalent.

The evidence is continuous integration on the repository head, not on a published artifact. `JVM test executed` means a Kotlin unit test ran on the JVM in CI; it says nothing about Android hardware.

The vector-set hash and this ledger are not in a published release yet; see CHANGELOG `[Unreleased]`.

## Corpora

The bridge corpus is shared: three byte-identical copies, one hash, and a generated constant on each native side that must equal it. Every other corpus is read from one location, so its hash is informational and no native constant pins it.

The vector-set hash and this ledger are not in a published release yet; see CHANGELOG `[Unreleased]`.

| Corpus | Files | Bytes sha256 | Shared | Android evidence |
|--------|-------|--------------|--------|------------------|
| bridge_contract_vectors | `test/fixtures/bridge_contract_vectors.json`; `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json`; `packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json` | sha256:3b64c8d81e1ca086494a1910aa5fb2d05d7a2d263b3d72f229f319d22e0064c0 | yes | JVM hermetic proof |
| navigation_topology_vectors | `priv/contract_vectors/navigation_topology_vectors.json` | sha256:eb5473bfcb4cb452fe86098823ac7024d12a19ef3bc8743e921c90e93122afe1 | no | not claimed |
| navigation_transition_vectors | `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/navigation_transition_vectors.json` | sha256:011e457eb55c05036a925c6b8b6fea4d05e52aa6e62c9faa94ae2ebe892d5ab2 | no | not claimed |
