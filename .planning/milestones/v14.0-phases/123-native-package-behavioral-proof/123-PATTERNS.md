# Phase 123: Native Package Behavioral Proof — Pattern Map

**Mapped:** 2026-06-20
**Files analyzed:** 11 new/modified files
**Analogs found:** 11 / 11

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mix/tasks/crosswake.contract.gen.ex` (EDIT) | utility / gen task | batch | itself (existing `seed_vectors/1`, `write_if_changed`) | self |
| `test/crosswake/bridge/bridge_behavioral_vector_test.exs` (NEW) | test | CRUD / request-response | `test/crosswake/compatibility/compatibility_test.exs` | exact |
| `packages/crosswake-shell-core-ios/Package.swift` (EDIT) | config | — | itself (existing testTarget block, lines 23–25) | self |
| `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/CrosswakeShellCoreTests.swift` (REPLACE) | test | — | `test/crosswake/compatibility/compatibility_test.exs` structure | partial |
| `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift` (NEW) | test | request-response | `test/crosswake/compatibility/compatibility_test.exs` (structure) + RESEARCH.md §Code Examples (Swift) | role-match |
| `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/ActivationConformanceTests.swift` (NEW) | test | request-response | `test/crosswake/compatibility/compatibility_test.exs` (structure) + RESEARCH.md §Code Examples | role-match |
| `packages/crosswake-shell-core-android/build.gradle.kts` (EDIT) | config | — | itself (existing `testImplementation` line 41) | self |
| `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeConformanceTest.kt` (NEW) | test | request-response | `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/CrosswakeShellConfigTest.kt` | exact |
| `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/ActivationConformanceTest.kt` (NEW) | test | request-response | `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/CrosswakeShellConfigTest.kt` | exact |
| `.github/workflows/native-behavioral-proof-gate.yml` (NEW) | config / CI | event-driven | `.github/workflows/contract-drift-gate.yml` | exact |
| `script/register-native-gate.sh` (NEW) | utility / script | request-response | `script/register-contract-gate.sh` | exact |

---

## Pattern Assignments

### `lib/mix/tasks/crosswake.contract.gen.ex` (EDIT — gen task)

**Analog:** itself

**Existing `@path` constant pattern** (lines 33–36):
```elixir
@ios_activation_path "examples/ios_shell_host/Fixtures/route_activation.json"
@android_activation_path "examples/android_shell_host/app/src/main/assets/route_activation.json"
@vectors_path "test/fixtures/bridge_contract_vectors.json"
@docs_snippet_path "docs/_contract_snippet.md"
```
Copy this pattern and add two new constants immediately after `@vectors_path`:
```elixir
@ios_vectors_path "packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json"
@android_vectors_path "packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json"
```

**Existing `run/1` emit pattern** (lines 47–50):
```elixir
write_if_changed(@ios_activation_path, ios_activation_json(bridge_vsn))
write_if_changed(@android_activation_path, android_activation_json(bridge_vsn))
write_if_changed(@vectors_path, vectors_json(protocol, bridge_vsn, commands, denial_reasons))
write_if_changed(@docs_snippet_path, docs_snippet(bridge_vsn))
```
Add two more `write_if_changed` calls after the `@vectors_path` emit, before `@docs_snippet_path`:
```elixir
write_if_changed(@ios_vectors_path, vectors_json(protocol, bridge_vsn, commands, denial_reasons))
write_if_changed(@android_vectors_path, vectors_json(protocol, bridge_vsn, commands, denial_reasons))
```
Content is byte-identical to the root `@vectors_path` emit — pass the same `vectors_json/4` call.

**Existing summary `Mix.shell().info` pattern** (lines 52–58) — extend the string to list the two new paths.

**Existing `seed_vectors/1` list structure** (lines 115–141):
```elixir
defp seed_vectors(bridge_vsn) do
  [
    [
      {"id", "vec-001-version-mismatch-deny"},
      {"description", "Request with a stale bridge_protocol_version is denied with compatibility_mismatch"},
      {"request_override", [{"version", "1.0.0"}]},
      {"expected_outcome", "deny"},
      {"expected_denial_reason", "compatibility_mismatch"}
    ],
    # ... vec-002, vec-003 ...
  ]
end
```
Each vector is a keyword pairs list (`[{key, value}, ...]`). Extend this list with 4 new vectors using the same pairs-list encoding. The expanded schema adds a `{"session_override", [...]}` key to each vector. Existing vec-001 through vec-003 must gain `{"session_override", []}` (empty, not absent) for schema consistency with the new vectors.

**`write_if_changed/2` — the idempotent write pattern** (lines 226–248):
```elixir
defp write_if_changed(relative_path, contents) do
  path = Path.expand(relative_path)
  File.mkdir_p!(Path.dirname(path))
  case File.read(path) do
    {:ok, existing} when existing == contents ->
      Mix.shell().info("  unchanged: #{relative_path}")
      :unchanged
    {:ok, _different} ->
      File.write!(path, contents)
      Mix.shell().info("  updated:   #{relative_path}")
      :updated
    {:error, :enoent} ->
      File.write!(path, contents)
      Mix.shell().info("  created:   #{relative_path}")
      :created
    {:error, reason} ->
      Mix.raise("could not write #{relative_path}: #{:file.format_error(reason)}")
  end
end
```
`File.mkdir_p!(Path.dirname(path))` creates the `Resources/` directory automatically — no separate mkdir task needed.

**`pairs_to_map/1` + `encode_doc/1` determinism** (lines 170–220): do not change; all new vector content encoded through the same path, so GUARD-02 safety is inherited automatically.

---

### `test/crosswake/bridge/bridge_behavioral_vector_test.exs` (NEW — Elixir behavioral vector test)

**Analog:** `test/crosswake/compatibility/compatibility_test.exs`

**Module + use pattern** (lines 1–11 of analog):
```elixir
defmodule Crosswake.Bridge.BridgeVectorBehavioralTest do
  use ExUnit.Case, async: true

  alias Crosswake.Compatibility
  alias Crosswake.Bridge.Contract
  alias Crosswake.Manifest.Types
  alias Crosswake.SupportMatrix
end
```

**Manifest fixture builder pattern** from analog `bridge_manifest_fixture/0` (lines 445–482):
```elixir
defp bridge_manifest_fixture do
  Types.new_root(
    crosswake_version: "0.1.0",
    generated_at: "2026-05-16T00:00:00Z",
    host: Types.new_host(),
    compatibility:
      Types.new_compatibility(
        native_runtime_version: "1.0.0",
        bridge_protocol_version: "1.0.0"   # <-- use @vectors["bridge_protocol_version"] here
      ),
    support_matrix: SupportMatrix.canonical(),
    capability_registry: %{
      "app.info.get" => Types.new_capability(id: "app.info.get", version: "1.0.0"),
      "file_picker" => Types.new_capability(id: "file_picker", version: "1.0.0")
    },
    routes: %{
      "dashboard" =>
        Types.new_route_entry(
          id: "dashboard",
          path: "/dashboard",
          runtime: :live_view,
          offline: :unavailable,
          capabilities: ["app.info.get"],
          allowlisted_origins: [Types.default_origin()]
        )
    }
  )
end
```
Use `Types.new_root/1`, `Types.new_host/0`, `Types.new_compatibility/1`, `Types.new_route_entry/1`, `Types.new_capability/1`, `SupportMatrix.canonical/0` — all confirmed in analog. Accept `bridge_protocol_version` from `@vectors["bridge_protocol_version"]`, not hardcoded.

**`bridge_findings` call pattern** from analog (lines 161–187):
```elixir
findings =
  Compatibility.bridge_findings(
    manifest,
    Contract.new_request(
      command: "files.pick",
      capability: "file_picker",
      route_id: "library",
      active_route_id: "dashboard",
      origin: "https://untrusted.example",
      native_runtime_version: "0.9.0",
      correlation_id: "bridge-1",
      capabilities: %{"file_picker" => "0.9.0"},
      installed_packs: %{}
    )
  )
```
`Contract.new_request/1` is the constructor. All keyword fields are named. The request carries `installed_packs:` (the Elixir side's session-equivalent for pack state).

**`finding_to_denial` call pattern** from analog (lines 210–233):
```elixir
denial = Compatibility.finding_to_denial(finding, route_id: "library")
assert %Denial{reason: :pack_incompatible, route_id: "library"} = denial
```
Pass `route_id:` as keyword opt. Map `denial.reason` → `Atom.to_string(denial.reason)` to compare against JSON vocabulary strings.

**Vector iteration pattern** (RESEARCH.md §Code Examples, Elixir section):
```elixir
@vectors_path "test/fixtures/bridge_contract_vectors.json"
@vectors Jason.decode!(File.read!(@vectors_path))

test "each vector's expected_outcome matches Elixir bridge_findings result" do
  for vector <- @vectors["vectors"] do
    # apply overrides, call bridge_findings, assert outcome + reason
  end
end
```
Load vectors at module compile time (`@vectors` module attribute) — fails fast if file is missing.

**Key implementation notes:**
- The `make_permissive_manifest/1` helper must set `compatibility.bridge_protocol_version` to `@vectors["bridge_protocol_version"]` (not `Contract.version()` directly, to ensure the test is driven by the committed file).
- Per pitfall 2 in RESEARCH.md: each vector's manifest must have the route present AND all non-targeted checks passing. Use keyword overrides on a base permissive manifest.
- The Elixir check order differs from native (see RESEARCH.md §CRITICAL: The Elixir check order). Design each vector so exactly one check fires.

---

### `packages/crosswake-shell-core-ios/Package.swift` (EDIT)

**Analog:** itself (lines 23–25)

**Current testTarget block** (lines 23–25):
```swift
.testTarget(
    name: "CrosswakeShellCoreTests",
    dependencies: ["CrosswakeShellCore"]),
```

**Required change** — add `resources:` using `.copy`:
```swift
.testTarget(
    name: "CrosswakeShellCoreTests",
    dependencies: ["CrosswakeShellCore"],
    resources: [
        .copy("Resources/")
    ]),
```
`.copy("Resources/")` is the correct rule for JSON files under swift-tools-version 5.9. The `Resources/` directory must exist at `Tests/CrosswakeShellCoreTests/Resources/` before `swift build` runs (created by the gen task via `File.mkdir_p!`).

---

### `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/CrosswakeShellCoreTests.swift` (REPLACE)

**Current state:** corrupted — literal `\n` escape sequences; will not compile.

**Replacement pattern:** replace with a minimal valid XCTestCase subclass that compiles and imports:
```swift
import XCTest
@testable import CrosswakeShellCore

// This file intentionally left minimal.
// Behavioral tests live in BridgeConformanceTests.swift and ActivationConformanceTests.swift.
final class CrosswakeShellCoreTests: XCTestCase {}
```
This is the first task — must be committed and CI-green before writing real test content.

---

### `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift` (NEW)

**Analog:** `test/crosswake/compatibility/compatibility_test.exs` (structure) + RESEARCH.md §Swift vector loading

**Imports and test class pattern** (RESEARCH.md §Code Examples Swift):
```swift
import XCTest
@testable import CrosswakeShellCore

final class BridgeConformanceTests: XCTestCase {

    private var vectorsFile: BridgeVectorsFile!

    override func setUp() {
        super.setUp()
        let url = Bundle.module.url(forResource: "bridge_contract_vectors", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        vectorsFile = try! JSONDecoder().decode(BridgeVectorsFile.self, from: data)
    }
```
`Bundle.module` requires the `resources: [.copy("Resources/")]` declaration in `Package.swift`. This only works on macOS (the CI target); no Linux guard needed (advisory lane, Option B).

**Codable model pattern** (RESEARCH.md §Code Examples):
```swift
struct BridgeVectorsFile: Codable {
    let bridgeProtocolVersion: String
    let vectors: [BridgeVector]
    enum CodingKeys: String, CodingKey {
        case bridgeProtocolVersion = "bridge_protocol_version"
        case vectors
    }
}
```
`snake_case` JSON keys → `camelCase` Swift properties via `CodingKeys`.

**Synchronous evaluate pattern** (from `BridgeChannel.swift:180` — RESEARCH.md verified):
```swift
var reply: BridgeReplyEnvelope?
channel.evaluate(request) { reply = $0 }
// No XCTestExpectation needed — completion is synchronous for test paths
XCTAssertEqual(reply?.status, vector.expectedOutcome)
if let expectedReason = vector.expectedDenialReason {
    XCTAssertEqual(reply?.denial?.denial.reason, expectedReason)
}
```
`reply.denial?.denial.reason` is the Swift path: `BridgeReplyEnvelope.denial` → `BridgeDenialEnvelope.denial` → `RouteDenialPayload.reason: String`.

**Pitfall 6 (ok-vector delegate):** The ok-vector test setup MUST configure `appInfoDelegate` in the config — `BridgeChannel` (line 228) returns `undeclared_capability` if delegate is nil even after all other checks pass.

**D-10 enforcement:** Load `bridgeProtocolVersion` from `vectorsFile.bridgeProtocolVersion` — never hardcode it or add a `BridgeChannel.protocolVersion` constant.

---

### `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/ActivationConformanceTests.swift` (NEW)

**Analog:** same as `BridgeConformanceTests.swift` structure

**Pattern:** XCTest class with `setUp` loading `vectorsFile` for the version constant. Activation tests are code-level (not vector-parametrized) but load `bridgeProtocolVersion` from the vectors file for version-anchoring per D-01.

**Key seams** (from NATIVE-TESTING.md §6.2, confirmed by RESEARCH.md):
- `ActivationCoordinator` with injected `manifestLoader`, `requestLoader`, `packStore`, `config` closures
- `PackStore(requiredVersions:inventory:)` — no-Bundle constructor
- `RouteDenialReason` enum values
- Six decision paths: LiveView success, `Denied`/`RequiredPack`

```swift
import XCTest
@testable import CrosswakeShellCore

final class ActivationConformanceTests: XCTestCase {
    private var bridgeProtocolVersion: String!

    override func setUp() {
        super.setUp()
        let url = Bundle.module.url(forResource: "bridge_contract_vectors", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        bridgeProtocolVersion = json["bridge_protocol_version"] as! String
    }
    // Tests call resolve(request:manifest:) and activate(_:) using bridgeProtocolVersion
}
```

---

### `packages/crosswake-shell-core-android/build.gradle.kts` (EDIT)

**Analog:** itself (line 41)

**Current testImplementation block** (line 41):
```kotlin
testImplementation("junit:junit:4.13.2")
```

**Required addition** — append after existing testImplementation:
```kotlin
testImplementation("junit:junit:4.13.2")
testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")
```
Version `1.7.3` matches the already-declared `kotlinx-coroutines-android:1.7.3` (line 36). No other changes needed — Gradle includes `src/test/resources/` in classpath automatically.

---

### `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeConformanceTest.kt` (NEW)

**Analog:** `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/CrosswakeShellConfigTest.kt`

**Package + imports pattern** (analog lines 1–5):
```kotlin
package dev.crosswake.shell.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
```
Add `import org.junit.Before` and `import org.json.JSONObject`.

**Anonymous delegate pattern** (analog lines 17–23):
```kotlin
val mockRouteDelegate = object : RouteDelegate {
    override val registeredRoutes: List<String> = listOf("user_profile", "settings")
    override fun isRouteRegistered(routeId: String): Boolean {
        return registeredRoutes.contains(routeId)
    }
}
```
Use `object : DelegateName { ... }` for all delegate stubs — no mocking library.

**JUnit 4 test class pattern** (analog lines 7–66):
```kotlin
class BridgeConformanceTest {

    private lateinit var vectorsJson: JSONObject

    @Before
    fun loadVectors() {
        val stream = javaClass.getResourceAsStream("/bridge_contract_vectors.json")!!
        vectorsJson = JSONObject(stream.bufferedReader().readText())
    }
```
Leading `/` in resource path is required (classpath-root, per RESEARCH.md pitfall 4).

**`evaluateForTesting` call + reply JSON parse pattern** (RESEARCH.md §Code Examples Kotlin):
```kotlin
val channel = BridgeChannel(session, transferCoordinator = null, config = config)
val replyJson = JSONObject(channel.evaluateForTesting(request))

assertEquals("Vector $id: expected_outcome", expectedOutcome, replyJson.getString("status"))
if (expectedReason != null) {
    val reason = replyJson
        .getJSONObject("denial")
        .getJSONObject("denial")
        .getString("reason")
    assertEquals("Vector $id: expected_denial_reason", expectedReason, reason)
}
```
`evaluateForTesting` is synchronous — no `runTest` / `runBlocking` needed for bridge tests.

**D-10 enforcement:** Load `bridgeVersion` from `vectorsJson.getString("bridge_protocol_version")` — never declare `BridgeChannel.PROTOCOL_VERSION`.

**Session override application** (RESEARCH.md §pitfall 1): the test loop must read `session_override` from each vector and apply overrides to the base session before constructing `BridgeChannel`.

---

### `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/ActivationConformanceTest.kt` (NEW)

**Analog:** `CrosswakeShellConfigTest.kt` (same pattern as above)

**Pattern:** JUnit 4 class with `@Before` loading `vectorsJson` for `bridge_protocol_version`. Activation tests are code-level but load the version constant from the JSON per D-01. Uses `ActivationCoordinator` with injected loaders and `PackStore.inMemory(...)`.

```kotlin
class ActivationConformanceTest {

    private lateinit var bridgeProtocolVersion: String

    @Before
    fun loadVectors() {
        val stream = javaClass.getResourceAsStream("/bridge_contract_vectors.json")!!
        val json = JSONObject(stream.bufferedReader().readText())
        bridgeProtocolVersion = json.getString("bridge_protocol_version")
    }
    // Tests use bridgeProtocolVersion when constructing manifests/requests
}
```

---

### `.github/workflows/native-behavioral-proof-gate.yml` (NEW)

**Analog:** `.github/workflows/contract-drift-gate.yml` (exact topology mirror)

**Permissions + trigger pattern** (analog lines 34–43):
```yaml
permissions:
  contents: read

on:
  push:
    branches:
      - '**'
  pull_request:
    branches:
      - main
```
Copy verbatim.

**Blocking job pattern** (analog job `guard-01-contract-drift-test`, lines 46–71) → new job `android-package-unit`:
```yaml
android-package-unit:
  name: android-package-unit
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/cache@v4
      with:
        path: packages/crosswake-shell-core-android/.gradle
        key: gradle-${{ hashFiles('packages/crosswake-shell-core-android/build.gradle.kts') }}
    - name: Run Android JVM tests
      working-directory: packages/crosswake-shell-core-android
      run: ./gradlew test
```
No `erlef/setup-beam` — Gradle uses Java 17, available on `ubuntu-latest` by default.

**Advisory job pattern** (analog job `guard-02-generate-and-diff`) → new job `ios-package-unit`:
```yaml
ios-package-unit:
  name: ios-package-unit
  runs-on: macos-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/cache@v4
      with:
        path: packages/crosswake-shell-core-ios/.build
        key: spm-${{ hashFiles('packages/crosswake-shell-core-ios/Package.swift') }}
    - name: Run Swift tests
      working-directory: packages/crosswake-shell-core-ios
      run: swift test
```
This job is NOT in the aggregator `needs:` — it is advisory only (D-07).

**Aggregator pattern** (analog lines 113–122):
```yaml
merge-blocking-native-behavioral-proof:
  name: merge-blocking-native-behavioral-proof
  if: always()
  needs: [android-package-unit]     # iOS is NOT here — advisory only
  runs-on: ubuntu-latest
  steps:
    - name: Roll up results
      uses: re-actors/alls-green@release/v1
      with:
        jobs: ${{ toJSON(needs) }}
```
`needs:` contains ONLY `android-package-unit`. The `if: always()` is required (same as analog). `merge-blocking-native-behavioral-proof` is the sole new required status check name.

---

### `script/register-native-gate.sh` (NEW)

**Analog:** `script/register-contract-gate.sh` (near-verbatim clone)

**Header comment + usage pattern** (analog lines 1–32): copy and update check name and workflow filename references.

**Parameters block** (analog lines 39–46):
```bash
REPO="${REPO:-szTheory/crosswake}"
BRANCH="${BRANCH:-main}"
NEW_CHECK="${NEW_CHECK:-merge-blocking-contract-drift}"   # <-- change to merge-blocking-native-behavioral-proof
ACTIONS_APP_ID="${ACTIONS_APP_ID:-15368}"
OLD_CHECK="${OLD_CHECK:-}"    # no prior context to drop; leave empty
DRY_RUN="${DRY_RUN:-0}"
```

**`jq` payload pattern** (analog lines 56–69): copy verbatim. The `map(select(.context != $old))` is a no-op for this gate (same as contract gate — `OLD_CHECK` is empty).

**Green-first preflight pattern** (analog lines 88–99):
```bash
if ! gh api "repos/${REPO}/commits/${BRANCH}/check-runs" \
     | jq -e --arg n "$NEW_CHECK" \
       '.check_runs | any(.name==$n and .conclusion=="success")' >/dev/null 2>&1; then
  echo "REFUSING (exit 2): '${NEW_CHECK}' has no successful run on ${BRANCH} yet."
  exit 2
fi
```
Checks `merge-blocking-native-behavioral-proof` conclusion, not any sibling job.

**`gh api -X PATCH` application** (analog lines 104–105):
```bash
gh api -X PATCH "${EP}" --input <(echo "$desired")
```
Copy verbatim.

Only changes from `register-contract-gate.sh`:
1. `NEW_CHECK` default value: `merge-blocking-native-behavioral-proof`
2. Header comments referencing `native-behavioral-proof-gate.yml` and `NTEST-04`
3. Final `echo` message updated to reference the new check name

---

## Shared Patterns

### Elixir manifest construction (all Elixir tests)
**Source:** `test/crosswake/compatibility/compatibility_test.exs` lines 411–482
**Apply to:** `bridge_behavioral_vector_test.exs`

Use `Types.new_root/1`, `Types.new_host/0`, `Types.new_compatibility/1` (with keyword overrides), `Types.new_route_entry/1`, `Types.new_capability/1`, `SupportMatrix.canonical/0`. Never build raw `%Root{}` struct literals — use the factory functions.

```elixir
# Canonical factory call pattern from compatibility_test.exs:
Types.new_root(
  crosswake_version: "0.1.0",
  generated_at: "2026-05-16T00:00:00Z",
  host: Types.new_host(),
  compatibility: Types.new_compatibility(
    native_runtime_version: "1.0.0",
    bridge_protocol_version: bridge_vsn   # from @vectors["bridge_protocol_version"]
  ),
  support_matrix: SupportMatrix.canonical(),
  capability_registry: %{
    "app.info.get" => Types.new_capability(id: "app.info.get", version: "1.0.0")
  },
  routes: %{
    "dashboard" => Types.new_route_entry(
      id: "dashboard",
      path: "/dashboard",
      runtime: :live_view,
      offline: :unavailable,
      capabilities: ["app.info.get"],
      allowlisted_origins: [Types.default_origin()]
    )
  }
)
```

### Version-from-file discipline (all three test suites)
**Source:** D-10, CONTEXT.md
**Apply to:** `bridge_behavioral_vector_test.exs`, `BridgeConformanceTests.swift`, `ActivationConformanceTests.swift`, `BridgeConformanceTest.kt`, `ActivationConformanceTest.kt`

Never hardcode a version string in any test file. Always load from the committed vectors JSON:
- Elixir: `@vectors Jason.decode!(File.read!("test/fixtures/bridge_contract_vectors.json"))` → `@vectors["bridge_protocol_version"]`
- Swift: `Bundle.module.url(forResource: "bridge_contract_vectors", withExtension: "json")` → `JSONDecoder().decode(BridgeVectorsFile.self, ...)`
- Kotlin: `javaClass.getResourceAsStream("/bridge_contract_vectors.json")` → `JSONObject(...).getString("bridge_protocol_version")`

### Anonymous delegate stubs (Kotlin tests)
**Source:** `CrosswakeShellConfigTest.kt` lines 17–23, 41–55
**Apply to:** `BridgeConformanceTest.kt`, `ActivationConformanceTest.kt`

```kotlin
val mockDelegate = object : AppInfoDelegate {
    override fun getAppInfo() = emptyMap<String, String>()
}
```
All delegate stubs use `object : InterfaceName { ... }`. No mocking library.

### CI job step order (workflow files)
**Source:** `.github/workflows/contract-drift-gate.yml` lines 46–71
**Apply to:** `native-behavioral-proof-gate.yml`

Pattern: `checkout → cache → tool setup (if needed) → install deps → run → step summary`. Cache key is `${{ hashFiles('path/to/lockfile') }}`.

### `re-actors/alls-green` aggregator
**Source:** `.github/workflows/contract-drift-gate.yml` lines 113–122
**Apply to:** `native-behavioral-proof-gate.yml`

```yaml
if: always()
needs: [blocking-job-only]   # advisory jobs NOT in needs:
runs-on: ubuntu-latest
steps:
  - uses: re-actors/alls-green@release/v1
    with:
      jobs: ${{ toJSON(needs) }}
```

---

## No Analog Found

All files have clear analogs. No entries in this section.

---

## Metadata

**Analog search scope:** `test/crosswake/`, `lib/mix/tasks/`, `packages/crosswake-shell-core-android/`, `packages/crosswake-shell-core-ios/`, `.github/workflows/`, `script/`
**Files scanned:** 10 source files read directly
**Pattern extraction date:** 2026-06-20
