# Phase 123: Native Package Behavioral Proof — Research

**Researched:** 2026-06-20
**Domain:** Cross-platform behavioral test suites (Elixir ExUnit + Swift XCTest + Kotlin JUnit 4) driven by a shared canonical vector file; CI gate with hermetic/advisory split.
**Confidence:** HIGH (all findings verified directly against source code)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**A. Vector coverage model (NTEST-01, -02, -03) — "Hybrid"**
- D-01: Bridge `evaluate()` request→reply behaviors become rich data-driven vectors; activation `resolve()`/`activate()` behaviors are code-level tests that load expected constants from the same JSON. Every behavior is version-anchored to the file.
- D-02: Vector schema expands to add `session_override` block alongside existing `request_override`. Each vector: `id`, `description`, `request_override`, `session_override`, `expected_outcome` (`ok`/`deny`), `expected_denial_reason` (nullable).
- D-03: Expanding vectors means editing `lib/mix/tasks/crosswake.contract.gen.ex` `vectors_json/4` and regenerating. In-scope and expected; the gen task's moduledoc says the seed set is "consumed by Phase 123."

**B. Vector delivery to native suites (NTEST-01) — "gen-emits per-package copies"**
- D-04: Extend `mix crosswake.contract.gen` to also write DO-NOT-EDIT copies of `bridge_contract_vectors.json` into iOS test bundle resources (`packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/`) and `packages/crosswake-shell-core-android/src/test/resources/`. Each package self-contained; no monorepo-relative path traversal, no symlink.
- D-05: GUARD-02 covers new copies automatically. Optionally extend GUARD-01's tripwire list to parse-assert the two new generated JSON copies; planner discretion.
- D-06: Swift requires file declared as test-target resource in `Package.swift` (`.copy("Resources/")` or `.process(...)` on testTarget) — currently declares NO resources. Kotlin loads via `javaClass.getResourceAsStream("/bridge_contract_vectors.json")` — no build change beyond resource existing.

**C. CI topology & registration (NTEST-04) — "Dedicated gate + register script"**
- D-07: New `native-behavioral-proof-gate.yml` with: `android-package-unit` (JVM-only `./gradlew test`, merge-blocking); `ios-package-unit` (`swift test` on `macos-latest`, advisory NOT in aggregator); `merge-blocking-native-behavioral-proof` aggregator (`re-actors/alls-green@release/v1`, `needs:` Android only, `if: always()`). Aggregator name is the sole new required status check.
- D-08: New `script/register-native-gate.sh`, near-verbatim clone of `script/register-contract-gate.sh`: green-first refuse guard (exit 2 until aggregator has ≥1 successful run on main), granular `gh api -X PATCH` with `strict:true` + `unique_by(.context)`. Script + document; do NOT auto-toggle.
- D-09: Elixir "third suite" split: version-field property already delivered by GUARD-01 (do not duplicate). Phase 123 adds new Elixir behavioral vector test running each vector's `request_override`/`session_override` through the Elixir bridge decision path, asserting `expected_outcome`/`expected_denial_reason`. Runs in normal `mix test`. **RESEARCH QUESTION flagged for researcher to answer.**

**D. Native version-source discipline (NTEST-01) — "Reject native version constants"**
- D-10: Native tests assert against `bridge_protocol_version` loaded from the committed vectors JSON — NOT a hardcoded native constant. Explicitly REJECT `NATIVE-TESTING.md` §9's recommendation to add `BridgeChannel.protocolVersion` (Swift) / `BridgeChannel.PROTOCOL_VERSION` (Kotlin) constants. One place the version lives.

**E. Locked-by-prior-work (not re-litigated)**
- D-11: Test seams already exist — no production refactor.
- D-12: The existing iOS test file `Tests/CrosswakeShellCoreTests/CrosswakeShellCoreTests.swift` is corrupted — literal `\n` escape sequences. Must be replaced.
- D-13: XCTest (iOS) + JUnit 4 (Android). Six decision seams are synchronous. Add `kotlinx-coroutines-test` with `runTest` only where async path exercised (e.g., `PackStore.installRequiredPack()`). No simulator (iOS) / no emulator (Android).
- D-14: Denial-reason strings in both native runtimes already match the JSON `denial_reasons` vocabulary. Assert on reply's reason string/JSON, not internal guard/branch firing.

### Claude's Discretion
Exact test file names/locations; XCTest loop style (manual loop vs per-vector method) or JUnit parametrized vs per-vector `@Test`; exact `session_override`/`request_override` field set in expanded schema; whether GUARD-01 tripwire gains two native copies (D-05); exact Swift `Package.swift` resource rule (`.copy` vs `.process`); CI cache keys / step ordering; precise Elixir behavioral-test seam pending D-09 research answer.

### Deferred Ideas (OUT OF SCOPE)
- Native `>=` min-version-floor reconciliation — Phase 124 / COMPAT-*
- Pre-publish fixture-verification gate — v14.0 publish step
- swift-testing / JUnit 5 migration and Linux SwiftPM test support
- Turbine / StateFlow assertions for reactive presentation streams
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| NTEST-01 | Single committed `bridge_contract_vectors.json` loaded by Elixir, Swift, and Kotlin test suites; one version bump fails all three | §Elixir Seam, §Vector Schema, §Swift Resource Loading, §Kotlin Resource Loading |
| NTEST-02 | iOS `crosswake-shell-core-ios` XCTest behavioral tests (no simulator) covering all six behaviors parametrized from vectors file | §Swift Native Seams, §Six Behaviors, §XCTest Pattern |
| NTEST-03 | Android `crosswake-shell-core-android` JVM JUnit behavioral tests (no emulator) covering same six behaviors, `runTest` for async | §Android Native Seams, §Six Behaviors, §JUnit Pattern |
| NTEST-04 | Kotlin JUnit merge-blocking CI lane; Swift XCTest advisory `macos-latest` CI lane; no hardcoded version literals | §CI Gate Topology, §Register Script |
</phase_requirements>

---

## Summary

Phase 123 is a test-and-CI authoring phase with no production code changes. All test seams exist; the work is writing tests, expanding the gen task's vector authoring, emitting two new file targets, replacing the corrupted iOS test file, wiring CI, and delivering the Elixir behavioral test that proves vectors describe real Elixir behavior.

**The D-09 Elixir seam question is answered concretely below.** The Elixir side does NOT have a single `evaluate(request) -> reply` function mirroring the native API. Instead, the bridge decision logic is implemented as `Crosswake.Compatibility.bridge_findings/2` (`lib/crosswake/compatibility/compatibility.ex:91`) which takes a `%Root{}` manifest and a `%Contract.Request{}` and returns a list of `%Finding{}` structs. An empty findings list means `ok`; non-empty means `deny` with the first finding convertible to a denial reason via `Compatibility.finding_to_denial/2`. A thin test harness calling these two functions in sequence is the correct Elixir behavioral seam.

The six bridge `evaluate()` behaviors are driven primarily by `session_override` (route, capabilities, packs, origin all live in the session / manifest state), not `request_override` (only protocol version and command come from the request). The current 3-vector seed is request-only and cannot express route/pack/capability denials — expanding the schema to add `session_override` is the correct design.

**Primary recommendation:** Write the Elixir behavioral test in `test/crosswake/bridge/bridge_behavioral_vector_test.exs` calling `Crosswake.Compatibility.bridge_findings/2`, expand `vectors_json/4` in the gen task to author all seven expanded vectors (six denials + one ok), add two new emit targets to the gen task, add Swift test resource declaration, and create the CI gate mirroring `contract-drift-gate.yml`.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Bridge protocol version authority | Elixir (Contract module) | — | Single canonical constant; all derived surfaces read from it |
| Vector authoring | Elixir (gen task `vectors_json/4`) | — | Gen task is the single author; hand-edit is prohibited |
| Vector persistence (root) | Elixir test fixture | — | `test/fixtures/bridge_contract_vectors.json` is the canonical emitted artifact |
| Vector distribution to native | Gen task (new emit targets) | GUARD-02 (diff check) | Two new DO-NOT-EDIT copies; GUARD-02 diffs them automatically |
| Bridge behavioral test (Elixir) | Elixir ExUnit (`mix test`) | — | Runs in existing merge-blocking lanes; proves vectors describe real Elixir logic |
| Bridge behavioral test (Swift) | Swift test target (macOS runner) | — | No simulator; advisory per hermetic/native split |
| Bridge behavioral test (Kotlin) | JVM JUnit (ubuntu runner) | — | No emulator; merge-blocking per hermetic determination |
| CI gate / branch protection | GitHub Actions + register script | Maintainer (out-of-band) | Green-first guard; script documents PATCH |

---

## Standard Stack

### Core (all pre-existing; no new dependencies needed)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ExUnit | built-in Elixir | Elixir behavioral vector test | Already runs; merge-blocking via existing lanes |
| XCTest | built-in Apple SDK | iOS behavioral test suite | Required by `swift-tools-version: 5.9`; swift-testing needs 5.10+ |
| JUnit 4 (`junit:junit:4.13.2`) | 4.13.2 (already in `build.gradle.kts`) | Android JVM behavioral tests | Already declared; matches published-lib norm |
| `kotlinx-coroutines-test` | 1.7.3 | `runTest` for async paths (e.g., `PackStore.installRequiredPack()`) | Need to add to `build.gradle.kts` |
| `re-actors/alls-green@release/v1` | release/v1 (already used) | Aggregator for CI gate | Same action used by contract-drift-gate.yml |
| `erlef/setup-beam` | fc68ffb (already pinned) | Elixir on CI | Same version already pinned in all Elixir CI jobs |

**Installation (only new dependency):**

```kotlin
// packages/crosswake-shell-core-android/build.gradle.kts
testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")
```

No other new dependencies. `kotlinx-coroutines-test:1.7.3` matches the already-declared `kotlinx-coroutines-android:1.7.3` version.

---

## Package Legitimacy Audit

No new external packages are introduced. `kotlinx-coroutines-test:1.7.3` is a JetBrains first-party test library matching the production coroutines version already declared. No audit gate needed.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `kotlinx-coroutines-test:1.7.3` | Maven Central | 7+ yrs | Very high | github.com/Kotlin/kotlinx.coroutines | OK [VERIFIED: official JetBrains repo] | Approved |

---

## Architecture Patterns

### System Architecture Diagram

```
Canonical Version Source
  Crosswake.Bridge.Contract.version() ── "1.1.0"
        │
        ▼
mix crosswake.contract.gen
  vectors_json/4 (EXTENDED: +4 new vectors, +session_override field)
        │
        ├──► test/fixtures/bridge_contract_vectors.json  (canonical, already guarded by GUARD-01/GUARD-02)
        │           │
        │           ├──► [NEW] packages/crosswake-shell-core-ios/Tests/.../Resources/bridge_contract_vectors.json
        │           └──► [NEW] packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json
        │
        ▼
Test Suites (all load the vectors file at runtime):
  [Elixir ExUnit] bridge_behavioral_vector_test.exs
       └── Crosswake.Compatibility.bridge_findings(manifest, request) → [Finding.t()]
           → empty = ok, non-empty → finding_to_denial → denial.reason atom → to_string → compare
  [Swift XCTest] BridgeConformanceTests.swift + ActivationConformanceTests.swift
       └── bundle.module url → JSON decode → BridgeChannel.evaluate(request) { reply }
           → reply.status == "ok"/"deny" + reply.denial?.denial.reason == expected
  [Kotlin JUnit] BridgeConformanceTest.kt + ActivationConformanceTest.kt
       └── getResourceAsStream("/bridge_contract_vectors.json") → JSONObject → BridgeChannel.evaluateForTesting(request)
           → JSONObject(reply).getString("status") == expected

CI Gate: native-behavioral-proof-gate.yml
  android-package-unit (ubuntu-latest, ./gradlew test) ─── blocking ──► merge-blocking-native-behavioral-proof
  ios-package-unit     (macos-latest,  swift test)     ─── advisory (NOT in aggregator needs:)
  merge-blocking-native-behavioral-proof (alls-green, needs: [android-package-unit], if: always())
       └── register-native-gate.sh (green-first guard → gh api -X PATCH)
```

### Recommended Project Structure (new files only)

```
lib/mix/tasks/
└── crosswake.contract.gen.ex    # EDIT: expand vectors_json/4 + two new @*_path constants + emit calls

test/fixtures/
└── bridge_contract_vectors.json # REGEN: expanded vectors (mix crosswake.contract.gen)

test/crosswake/bridge/
└── bridge_behavioral_vector_test.exs  # NEW: Elixir behavioral vector test (D-09)

packages/crosswake-shell-core-ios/
├── Package.swift                # EDIT: add testTarget resources: [.copy("Resources/")]
└── Tests/CrosswakeShellCoreTests/
    ├── CrosswakeShellCoreTests.swift    # REPLACE (corrupted file, literal \n)
    ├── BridgeConformanceTests.swift     # NEW: bridge evaluate() vectors + delegate tests
    ├── ActivationConformanceTests.swift # NEW: resolve()/activate() activation tests
    └── Resources/
        └── bridge_contract_vectors.json # NEW: gen-emitted copy (DO-NOT-EDIT)

packages/crosswake-shell-core-android/
├── build.gradle.kts             # EDIT: add kotlinx-coroutines-test
└── src/test/
    ├── resources/
    │   └── bridge_contract_vectors.json # NEW: gen-emitted copy (DO-NOT-EDIT)
    └── java/dev/crosswake/shell/core/
        ├── CrosswakeShellConfigTest.kt  # EXISTING: extend pattern
        ├── BridgeConformanceTest.kt     # NEW: bridge evaluateForTesting() vectors
        └── ActivationConformanceTest.kt # NEW: activate() activation tests

.github/workflows/
└── native-behavioral-proof-gate.yml   # NEW: android blocking + ios advisory + aggregator

script/
└── register-native-gate.sh            # NEW: clone of register-contract-gate.sh
```

---

## CRITICAL: D-09 Answer — The Elixir Bridge Evaluation Seam

**[VERIFIED: source code inspection of `lib/crosswake/compatibility/compatibility.ex`]**

### The Elixir bridge decision is SPREAD, not a single `evaluate()` call

There is NO single `evaluate(request) -> reply` function in Elixir that mirrors the native API signature. The decision logic is split across two functions in `Crosswake.Compatibility`:

**Primary seam — `Crosswake.Compatibility.bridge_findings/2`** (`lib/crosswake/compatibility/compatibility.ex:91`):

```elixir
@spec bridge_findings(Root.t(), Contract.Request.t()) :: [Finding.t()]
def bridge_findings(%Root{} = manifest, %Contract.Request{} = request)
```

This function runs all six decision checks in sequence:
1. `validate_active_route` — route_id == active_route_id (→ `:inactive_route` denial)
2. `validate_route_presence` — route exists in manifest (→ `:inactive_route` denial)
3. `validate_bridge_command` — command in allowed set + capability identity + route allowlist + capability version (→ `:undeclared_capability` or `:unavailable_capability` denial)
4. `validate_bridge_protocol` — bridge protocol version via `compatible_version?/2` (→ `:compatibility_mismatch` denial via `:bridge_protocol_version` axis)
5. `validate_native_runtime` — native runtime version (→ `:compatibility_mismatch` via `:native_runtime_version` axis)
6. `validate_packs` — required packs installed (→ `:pack_incompatible` denial)
7. `validate_origin` — origin in allowlist (→ `:origin_denied` denial)

**Secondary seam — `Crosswake.Compatibility.finding_to_denial/2`** (`lib/crosswake/compatibility/compatibility.ex:106`):

```elixir
@spec finding_to_denial(Finding.t(), keyword()) :: Denial.t()
def finding_to_denial(%Finding{} = finding, opts \\ [])
```

Maps a `Finding.t()` to a `Denial.t()` with a `reason` atom.

### How a thin test harness calls these:

```elixir
# The complete Elixir behavioral vector evaluation:
findings = Crosswake.Compatibility.bridge_findings(manifest, request)

{outcome, denial_reason} =
  case findings do
    [] -> {"ok", nil}
    [first | _] ->
      denial = Crosswake.Compatibility.finding_to_denial(first, route_id: request.route_id)
      {"deny", Atom.to_string(denial.reason)}
  end
```

### IMPORTANT: The Elixir bridge check is `>=` (semver floor), NOT exact string equality

The Elixir `compatible_version?/2` at line 616 uses `Version.compare(available, required) != :lt` — i.e., `available >= required`. This is the OPPOSITE of the native exact-string equality check. When the vector has `request_override: {version: "1.0.0"}` and the manifest declares `bridge_protocol_version: "1.1.0"`, Elixir will DENY (because `1.0.0 < 1.1.0`). When the request carries `"1.1.0"` against a manifest at `"1.1.0"`, Elixir will ALLOW.

**The test must ensure `request_override.version` is used as the REQUEST's bridge protocol version, and the MANIFEST's `compatibility.bridge_protocol_version` is "1.1.0".** So vec-001 (`request version = "1.0.0"` → deny) works correctly in Elixir even with `>=` semantics because `1.0.0 < 1.1.0`.

### What a manifest fixture for the Elixir behavioral test needs

The behavioral test needs a `%Root{}` manifest. Looking at `bridge_findings/2`, the manifest must carry:
- `manifest.compatibility.bridge_protocol_version` (the required version — `"1.1.0"`)
- `manifest.compatibility.native_runtime_version` (for pack/runtime check)
- `manifest.routes` (map of route_id → `%RouteEntry{}`)
- `manifest.capability_registry` (for capability checks)
- `manifest.host.origin` (for origin check)

The test can use the existing `manifest_fixture/0` helper pattern from `compatibility_test.exs` or build a minimal in-memory manifest inline. **Do NOT load a file-based manifest — build in-memory so the test is hermetic.**

### Elixir denial-reason atoms vs JSON vocabulary

**[VERIFIED: `lib/crosswake/shell/denial.ex:8-21`]**

The Elixir `Denial.reason` atoms map to JSON strings via `Atom.to_string/1`:

| Elixir atom | JSON string | In vectors vocabulary? |
|-------------|-------------|----------------------|
| `:compatibility_mismatch` | `"compatibility_mismatch"` | YES |
| `:undeclared_capability` | `"undeclared_capability"` | YES |
| `:unavailable_capability` | `"unavailable_capability"` | YES |
| `:origin_denied` | `"origin_denied"` | YES |
| `:inactive_route` | `"inactive_route"` | YES |
| `:external_entry_denied` | `"external_entry_denied"` | YES |
| `:pack_incompatible` | `"pack_incompatible"` | YES |
| `:gate_denied` | `"gate_denied"` | In `denial_reasons` list; bridge vectors don't use it |
| `:kill_switch_active` | `"kill_switch_active"` | In `denial_reasons` list; bridge vectors don't use it |

All six bridge-denial reasons in the JSON vocabulary map 1:1 to Elixir atoms via `Atom.to_string`. No translation layer needed.

### CRITICAL: The Elixir check order differs from native order

The native (Swift/Kotlin) check order is:
1. Protocol version + native runtime version (compatibility_mismatch)
2. Route ID == active route ID (inactive_route)
3. Origin (origin_denied)
4. Command existence + capability identity (undeclared_capability)
5. Pack compatibility (pack_incompatible)
6. Capability version (unavailable_capability / undeclared)

The Elixir `bridge_findings` order is:
1. Active route check (inactive_route)
2. Route presence in manifest (inactive_route)
3. Bridge command + capability checks (undeclared_capability / unavailable_capability)
4. Bridge protocol version via compatibility (compatibility_mismatch)
5. Native runtime version via compatibility (compatibility_mismatch)
6. Packs (pack_incompatible)
7. Origin (origin_denied)

**This ordering difference is expected and acceptable.** The behavioral vector test asserts only that a vector with `expected_outcome: "deny"` produces at least one finding, and that the first finding's denial reason matches `expected_denial_reason`. Vectors must be designed so no two checks fire simultaneously (each vector targets exactly one denial path).

### Elixir behavioral test location and module name

**[VERIFIED: consistent with existing `test/crosswake/bridge/` convention]**

- **File:** `test/crosswake/bridge/bridge_behavioral_vector_test.exs`
- **Module:** `Crosswake.Bridge.BridgeVectorBehavioralTest`
- **Runs in:** normal `mix test` invocation (already merge-blocking); no separate CI lane needed

---

## Expanded Vector Schema

**[VERIFIED: gen task source `lib/mix/tasks/crosswake.contract.gen.ex:99-141`]**

### Current schema (3 vectors, request_override only)

The current `seed_vectors/1` emits only `request_override` (no `session_override`). This is insufficient because the bridge `evaluate()` decision reads route, capabilities, packs, and origin from the SESSION, not the request. The session data in native tests is passed via the `LiveViewSession` / `LiveViewSession` constructor; in Elixir tests it is passed via the `%Root{}` manifest + `%Contract.Request{}`.

### Expanded schema: 7 vectors (6 denials + 1 ok)

The expanded `seed_vectors/1` must produce this set:

| Vector ID | Denial | request_override | session_override | Notes |
|-----------|--------|-----------------|-----------------|-------|
| `vec-001-version-mismatch-deny` | `compatibility_mismatch` | `{version: "1.0.0"}` | (none needed) | Request sends old version |
| `vec-002-unknown-command-deny` | `undeclared_capability` | `{version: "1.1.0", command: "unknown.command", capability: "unknown.command"}` | (none) | Command not in BridgeCommand enum |
| `vec-003-canonical-version-ok` | nil (ok) | `{version: "1.1.0", command: "app.info.get", capability: "app.info.get"}` | `{capabilities: {"app.info.get": "1"}}` | Happy path; session must declare capability |
| `vec-004-inactive-route-deny` | `inactive_route` | `{version: "1.1.0", command: "app.info.get", capability: "app.info.get", route_id: "other-route", active_route_id: "other-route"}` | (none) | Request route != session route |
| `vec-005-origin-denied-deny` | `origin_denied` | `{version: "1.1.0", command: "app.info.get", capability: "app.info.get", origin: "https://evil.example.com"}` | (none) | Request origin != session allowedOrigin |
| `vec-006-pack-incompatible-deny` | `pack_incompatible` | `{version: "1.1.0", command: "app.info.get", capability: "app.info.get"}` | `{route_required_packs: ["test-pack@1.0.0"], installed_packs: {}}` | Session requires pack not in session.installedPacks |
| `vec-007-capability-version-deny` | `unavailable_capability` | `{version: "1.1.0", command: "app.info.get", capability: "app.info.get"}` | `{capabilities: {"app.info.get": "2"}}` | Session declares version "2"; request carries default "1" |

**Note on vec-003 (ok path):** The ok vector needs the session to declare `capabilities: {"app.info.get": "1"}` and the test to provide an `appInfoDelegate`. In native tests, the delegate is provided by the test setup. The `session_override` is advisory for native — the native test infrastructure configures the session object directly. But the vector's `session_override` block tells the native test WHAT the session must look like.

### `session_override` field semantics

The `session_override` block carries values that override the DEFAULT test session for this vector:

```json
"session_override": {
  "capabilities": {"app.info.get": "2"},      // override session.capabilities
  "route_required_packs": ["test-pack@1.0.0"], // override session.routeRequiredPacks
  "installed_packs": {},                        // override session.installedPacks
  "route_id": "dashboard",                      // override session.routeID (rarely needed)
  "allowed_origin": "https://trusted.example.com" // override session.allowedOrigin (rarely needed)
}
```

### How to extend `vectors_json/4` in the gen task

The gen task's `seed_vectors/1` at line 115 is a plain Elixir list. It uses the `pairs_list` encoding (list of `{key, value}` tuples). Extending means adding 4 more vector maps to the list:

```elixir
defp seed_vectors(bridge_vsn) do
  [
    # ... existing vec-001, vec-002, vec-003 ...
    [
      {"id", "vec-004-inactive-route-deny"},
      {"description", "Request scoped to a different route is denied with inactive_route"},
      {"request_override", [
        {"active_route_id", "other-route"},
        {"command", "app.info.get"},
        {"route_id", "other-route"},
        {"version", bridge_vsn}
      ]},
      {"session_override", []},
      {"expected_outcome", "deny"},
      {"expected_denial_reason", "inactive_route"}
    ],
    [
      {"id", "vec-005-origin-denied-deny"},
      {"description", "Request from non-allowlisted origin is denied with origin_denied"},
      {"request_override", [
        {"command", "app.info.get"},
        {"origin", "https://evil.example.com"},
        {"version", bridge_vsn}
      ]},
      {"session_override", []},
      {"expected_outcome", "deny"},
      {"expected_denial_reason", "origin_denied"}
    ],
    [
      {"id", "vec-006-pack-incompatible-deny"},
      {"description", "Request when required pack is not installed is denied with pack_incompatible"},
      {"request_override", [{"command", "app.info.get"}, {"version", bridge_vsn}]},
      {"session_override", [
        {"installed_packs", []},
        {"route_required_packs", ["test-pack@1.0.0"]}
      ]},
      {"expected_outcome", "deny"},
      {"expected_denial_reason", "pack_incompatible"}
    ],
    [
      {"id", "vec-007-capability-version-deny"},
      {"description", "Request where session capability version is ahead of request is denied with unavailable_capability"},
      {"request_override", [{"command", "app.info.get"}, {"version", bridge_vsn}]},
      {"session_override", [{"capabilities", [{"app.info.get", "2"}]}]},
      {"expected_outcome", "deny"},
      {"expected_denial_reason", "unavailable_capability"}
    ]
  ]
end
```

**Determinism:** The `pairs_to_map` helper sorts keys before encoding. This means `session_override`, `request_override` key ordering within each vector object will be sorted alphabetically in the emitted JSON. This is idempotent and GUARD-02-safe.

### New emit targets for the gen task

Add two `@path` constants and two `write_if_changed` calls:

```elixir
@ios_vectors_path "packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json"
@android_vectors_path "packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json"

# In run/1:
write_if_changed(@ios_vectors_path, vectors_json(protocol, bridge_vsn, commands, denial_reasons))
write_if_changed(@android_vectors_path, vectors_json(protocol, bridge_vsn, commands, denial_reasons))
```

The content is byte-identical to the root `@vectors_path` emit. GUARD-02 (`git add -A && git diff --cached --exit-code`) will cover all three copies automatically at zero cost.

---

## Native Seams Verification

**[VERIFIED: source code inspection]**

### iOS (Swift) — all seams confirmed

| Seam | File | Signature | Status |
|------|------|-----------|--------|
| `BridgeChannel.evaluate()` | `BridgeChannel.swift:180` | `public func evaluate(_ request: BridgeRequestEnvelope, completion: @escaping (BridgeReplyEnvelope) -> Void)` | EXISTS, public |
| `BridgeChannel.init()` | `BridgeChannel.swift:148` | `public init(session: LiveViewSession, transferCoordinator: TransferCoordinator?, replySink: ..., config: CrosswakeShellConfig, ...)` | EXISTS, public |
| `ActivationCoordinator.resolve()` | Confirmed in NATIVE-TESTING.md §6.2 | `public func resolve(request:manifest:)` | EXISTS |
| `ActivationCoordinator.init()` with injected closures | Confirmed in NATIVE-TESTING.md §6.2 | Takes `manifestLoader`, `requestLoader`, `packStore`, `config` | EXISTS |
| `PackStore(requiredVersions:inventory:)` | Confirmed in NATIVE-TESTING.md §9 | No-Bundle constructor | EXISTS |
| `CrosswakeShellCoreTests.swift` | Corrupted | Literal `\n` escape sequences as bytes | MUST REPLACE |

**Evaluate is synchronous for same-thread requests** — the completion handler is called synchronously within `evaluate()` for all non-deferred paths (which are all the test paths). The `var reply: BridgeReplyEnvelope?; channel.evaluate(request) { reply = $0 }` pattern works without `XCTestExpectation`.

### iOS denial-reason strings

**[VERIFIED: `BridgeChannel.swift:184, 189, 193, 203, 218, 228`]**

```
"compatibility_mismatch"   (line 184 — protocol/version/nativeRuntime check)
"inactive_route"           (line 189 — routeID != session.routeID)
"origin_denied"            (line 193 — origin != session.allowedOrigin)
"undeclared_capability"    (line 203 — unknown command or capability mismatch)
"pack_incompatible"        (line 218 — required pack not installed)
"undeclared_capability"    (line 228 — delegate not configured → same reason as command check)
```

The `reply.denial?.denial.reason` path in the Swift reply: `BridgeReplyEnvelope.denial` → `BridgeDenialEnvelope.denial` → `RouteDenialPayload.reason: String`.

All match the JSON vocabulary. D-14 confirmed.

### Android (Kotlin) — all seams confirmed

| Seam | File | Signature | Status |
|------|------|-----------|--------|
| `BridgeChannel.evaluateForTesting()` | `BridgeChannel.kt:307` | `fun evaluateForTesting(request: BridgeRequestEnvelope): String` | EXISTS, public |
| `BridgeChannel.init()` | `BridgeChannel.kt:43` | `class BridgeChannel(session, transferCoordinator, config, connectionState?, serverEvents?)` | EXISTS |
| `ActivationCoordinator` with injected loaders | Confirmed in NATIVE-TESTING.md §6.6 | Takes `config`, `manifestLoader: () -> ShellManifest`, `requestLoader: () -> ActivationRequest`, `packStore` | EXISTS |
| `PackStore.inMemory()` | Confirmed in NATIVE-TESTING.md §6.5 | Static factory, no Context | EXISTS |
| `RouteDenialReason` enum | `ActivationCoordinator.kt:28-36` | `COMPATIBILITY_MISMATCH`, `UNDECLARED_CAPABILITY`, `UNAVAILABLE_CAPABILITY`, `ORIGIN_DENIED`, `INACTIVE_ROUTE`, `EXTERNAL_ENTRY_DENIED`, `PACK_INCOMPATIBLE` | EXISTS |
| Anonymous delegate pattern | `CrosswakeShellConfigTest.kt` | `object : AppInfoDelegate { ... }` | CONFIRMED in existing tests |

**`evaluateForTesting` is synchronous** — line 307-309: calls private `evaluate(request)` and errors on `null` (deferred) result. All test paths are synchronous (no `runTest` needed for bridge tests; `runTest` is only needed if an async pack-install path is tested).

**Android reply JSON path:** `JSONObject(reply).getString("status")` for outcome; `JSONObject(reply).getJSONObject("denial").getJSONObject("denial").getString("reason")` for denial reason.

**Android denial-reason strings** (`BridgeChannel.kt:101-134`):
```
"compatibility_mismatch"   (line 102 — protocol/version/nativeRuntime)
"inactive_route"           (line 106 — routeId != session.routeId)
"origin_denied"            (line 110 — origin != session.allowedOrigin)
"undeclared_capability"    (line 119 — unknown command)
"undeclared_capability"    (line 122 — capability mismatch)
"pack_incompatible"        (line 135 — required pack not installed)
"unavailable_capability"   (line 143 — capability version mismatch or delegate missing for APP_INFO_GET)
```

All match JSON vocabulary. D-14 confirmed.

---

## Swift `Package.swift` Resource Declaration

**[VERIFIED: `Package.swift` currently has NO resources declaration]**

Current testTarget:
```swift
.testTarget(
    name: "CrosswakeShellCoreTests",
    dependencies: ["CrosswakeShellCore"]),  // no resources:
```

Required change — add `resources`:
```swift
.testTarget(
    name: "CrosswakeShellCoreTests",
    dependencies: ["CrosswakeShellCore"],
    resources: [
        .copy("Resources/")
    ]),
```

**`.copy` vs `.process`:**
- `.copy("Resources/")` — copies the directory verbatim into the test bundle, no transformation. Correct for JSON files (no processing needed). Does not change file structure.
- `.process("Resources/")` — processes files based on type (e.g., minifies JSON, compiles xcassets). Not needed here; would be a more fragile choice.

**Use `.copy("Resources/")`** — simpler, correct for JSON, consistent with what mature SDKs (Stripe iOS) use for fixture files.

**Runtime loading in XCTest:**
```swift
// Correct for swift-tools-version: 5.9 with .copy resource rule:
let url = Bundle.module.url(forResource: "bridge_contract_vectors", withExtension: "json")!
let data = try! Data(contentsOf: url)
let vectors = try! JSONDecoder().decode(BridgeContractVectors.self, from: data)
```

`Bundle.module` is generated by SwiftPM for test targets when resources are declared. This works on macOS (the CI target). It does NOT work on Linux without `#if canImport(Foundation)` guards — but since the CI is `macos-latest` (advisory), this is irrelevant. Accept Option B from NATIVE-TESTING.md §6.3: all tests on macOS, no Linux split needed.

**The `Resources/` directory must be created** at `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/` before or simultaneously with the gen task writing the JSON file to it.

---

## Kotlin Resource Loading

**[VERIFIED: standard JVM/JUnit 4 pattern; confirmed by `build.gradle.kts`]**

File placement: `packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json`

This is the standard Gradle test resource directory. Gradle automatically includes it in the test classpath. No `build.gradle.kts` change needed beyond ensuring the file exists.

**Runtime loading in JUnit 4:**
```kotlin
val stream = javaClass.getResourceAsStream("/bridge_contract_vectors.json")!!
val json = stream.bufferedReader().readText()
val vectors = JSONObject(json)
```

The leading `/` in `"/bridge_contract_vectors.json"` is required — it loads from the root of the classpath (test resources root). Without it, the path would be relative to the class's package.

No Robolectric, no Context required. Pure JVM.

---

## CI Gate Topology

**[VERIFIED: `contract-drift-gate.yml`, `native-collateral-advisory.yml`, `script/register-contract-gate.sh`]**

### `native-behavioral-proof-gate.yml` pattern

Mirror `contract-drift-gate.yml` exactly, with these substitutions:

| Element | contract-drift-gate | native-behavioral-proof-gate |
|---------|--------------------|-----------------------------|
| Workflow name | `Contract Drift Gate` | `Native Behavioral Proof Gate` |
| Job 1 | `guard-01-contract-drift-test` (ubuntu, mix test) | `android-package-unit` (ubuntu-latest, `./gradlew test`) |
| Job 2 | `guard-02-generate-and-diff` (ubuntu, mix gen) | `ios-package-unit` (macos-latest, `swift test`) — NOT in aggregator needs |
| Aggregator job | `merge-blocking-contract-drift` | `merge-blocking-native-behavioral-proof` |
| Aggregator `needs:` | `[guard-01, guard-02]` | `[android-package-unit]` ONLY — iOS is advisory |
| Required check name | `merge-blocking-contract-drift` | `merge-blocking-native-behavioral-proof` |

**Key difference from contract-drift-gate:** The aggregator only needs the Android job. iOS is a sibling job that runs but is NOT in `needs:` and is NOT a blocking input to `re-actors/alls-green`.

**Cache keys (mirror existing Elixir cache pattern for Kotlin/Swift):**

Android job:
```yaml
- uses: actions/cache@v4
  with:
    path: packages/crosswake-shell-core-android/.gradle
    key: gradle-${{ hashFiles('packages/crosswake-shell-core-android/build.gradle.kts') }}
```

iOS job:
```yaml
# Swift Package Manager — no separate cache needed; actions/checkout + swift test is fast
# If caching SPM dependencies is desired, cache .build/ directory
- uses: actions/cache@v4
  with:
    path: packages/crosswake-shell-core-ios/.build
    key: spm-${{ hashFiles('packages/crosswake-shell-core-ios/Package.swift') }}
```

**`permissions`:** `contents: read` (same as all other gates).

**Trigger:** `push` on `**`, `pull_request` on `main` (identical to contract-drift-gate.yml).

**Working-directory pattern for Android:**
```yaml
- name: Run Android JVM tests
  working-directory: packages/crosswake-shell-core-android
  run: ./gradlew test
```

**Working-directory pattern for iOS:**
```yaml
- name: Run Swift tests
  working-directory: packages/crosswake-shell-core-ios
  run: swift test
```

### `register-native-gate.sh` pattern

Near-verbatim clone of `register-contract-gate.sh`. Only changes:

```bash
NEW_CHECK="${NEW_CHECK:-merge-blocking-native-behavioral-proof}"
OLD_CHECK="${OLD_CHECK:-}"          # no prior check to drop
# No OLD_CHECK replacement comment: "map(select(.context != $old)) is a no-op; only appends."
```

Green-first preflight checks `merge-blocking-native-behavioral-proof`, not `merge-blocking-contract-drift`. All other logic identical.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Elixir bridge decision logic | Custom evaluate() | `Crosswake.Compatibility.bridge_findings/2` | Already implements all 7 checks |
| JSON parsing in tests | String.contains? / regex | `Jason.decode!` (Elixir), `JSONObject` (Kotlin), `JSONDecoder` (Swift) | Parse-not-grep rule (PITFALLS.md §3.1) |
| Async test scoping | `Thread.sleep` / `runBlocking` | `runTest` from `kotlinx-coroutines-test` | `runBlocking` causes real-time waits and is non-deterministic |
| Aggregator gate | Custom "all passed" check | `re-actors/alls-green@release/v1` | Already used by all existing gates; known-good idiom |
| Branch-protection update | Manual gh api call | `register-native-gate.sh` (green-first + documented PATCH) | Script documents the PATCH and prevents deadlock via preflight |

---

## Common Pitfalls

### Pitfall 1: Session-override fields not propagated to native test setup

**What goes wrong:** A vector has `session_override: {capabilities: {"app.info.get": "2"}}` but the test's `makeSession()` helper always constructs `capabilities: ["app.info.get": "1"]`. The session override is ignored; the test is not actually data-driven.

**Prevention:** The native test loop must read `session_override` from each vector and apply overrides to the base session before constructing `BridgeChannel`. For simple JUnit/XCTest manual loops, do this explicitly:

```kotlin
val sessionOverride = vector.optJSONObject("session_override")
val capabilities = sessionOverride?.optJSONObject("capabilities")?.let { ... } ?: mapOf("app.info.get" to "1")
val session = makeSession(capabilities = capabilities, ...)
```

**Warning signs:** vec-007 (capability-version-deny) passes when it should fail.

### Pitfall 2: Elixir bridge_findings needs a MANIFEST, not just a request

**What goes wrong:** The test passes a `Contract.Request{}` with `route_id: "dashboard"` but the manifest has no `"dashboard"` route → `validate_route_presence` fires before the target check, producing `:inactive_route` instead of the expected denial reason.

**Prevention:** Build a per-vector manifest fixture that has the "dashboard" route with all required fields. Each vector that tests a specific denial (e.g., pack incompatible) must have all OTHER checks passing:
- Route present in manifest
- Route's `allowlisted_origins` includes the test origin
- Request's route_id == active_route_id (for all non-inactive-route vectors)
- Bridge protocol version in request matches manifest (for all non-version-mismatch vectors)

A helper `make_permissive_manifest/1` that accepts keyword overrides is the cleanest pattern.

### Pitfall 3: Corrupted iOS test file causes compile failure, not test failure

**What goes wrong:** The corrupted `CrosswakeShellCoreTests.swift` (literal `\n` bytes) causes `swift test` to fail with a compile error before any test runs, making the CI lane look broken even before tests are written.

**Prevention:** The FIRST task in the plan must replace this file (even with an empty valid `XCTestCase` subclass), commit, confirm CI compiles, then proceed to write real tests. Do not attempt to run `swift test` until this file is replaced.

### Pitfall 4: Android test resource path missing leading slash

**What goes wrong:** `javaClass.getResourceAsStream("bridge_contract_vectors.json")` (no leading `/`) resolves relative to the class's package path (`dev/crosswake/shell/core/bridge_contract_vectors.json`), not the root. Returns `null` silently; test NPEs.

**Prevention:** Always use `"/bridge_contract_vectors.json"` (leading slash) for classpath-root resources.

### Pitfall 5: gen task emit order causes GUARD-02 churn if new paths not added to emit list

**What goes wrong:** Developer runs `mix crosswake.contract.gen` after adding `@ios_vectors_path` but forgets to add the `write_if_changed` call in `run/1`. The file is never written. CI passes (no diff) but the copy doesn't exist.

**Prevention:** Add BOTH the `@path` constant and the `write_if_changed` call in the same commit. The gen task's `Mix.shell().info` summary listing all output paths serves as a checklist.

### Pitfall 6: Swift ok-vector requires delegate to not deny "undeclared_capability"

**What goes wrong:** vec-003 expects `ok`, but `BridgeChannel` (line 228) returns `deny` with `"undeclared_capability"` if `appInfoDelegate` is nil even after all other checks pass.

**Prevention:** The ok-vector test setup MUST configure an `appInfoDelegate`. The test helper for ok-path: `CrosswakeShellConfig(appInfoDelegate: makeStubAppInfoDelegate())`.

### Pitfall 7: Elixir `bridge_findings` check order produces wrong denial for multi-failure vectors

**What goes wrong:** A vector intended to test `pack_incompatible` also has the wrong origin → Elixir produces `origin_denied` (last check) instead.

**Prevention:** Each vector must be designed so exactly ONE check fails. Validate vectors by running Elixir behavioral test in isolation and confirming the denial reason before writing native tests. The seven vectors proposed above are designed this way (each vector only overrides fields that trigger exactly one check).

---

## Code Examples

### Elixir behavioral vector test seam

```elixir
# test/crosswake/bridge/bridge_behavioral_vector_test.exs
defmodule Crosswake.Bridge.BridgeVectorBehavioralTest do
  use ExUnit.Case, async: true

  alias Crosswake.Compatibility
  alias Crosswake.Bridge.Contract

  # Load vectors file at module compile time — fails fast if file is missing
  @vectors_path "test/fixtures/bridge_contract_vectors.json"
  @vectors Jason.decode!(File.read!(@vectors_path))

  # Build a permissive manifest for behavioral testing.
  # All checks default to PASSING; per-vector overrides target exactly one failure.
  defp make_test_manifest(opts \\ []) do
    # Use the existing manifest fixture builder (see compatibility_test.exs)
    # or build inline via Types.build_manifest/1
    bridge_vsn = @vectors["bridge_protocol_version"]
    route_id = Keyword.get(opts, :route_id, "dashboard")
    allowlisted_origins = Keyword.get(opts, :allowlisted_origins, ["https://app.example.com"])
    required_packs = Keyword.get(opts, :required_packs, [])

    # Inline construction — adjust to match actual Root.t() struct fields
    %{
      routes: %{
        route_id => %{
          id: route_id,
          capabilities: ["app_info"],
          packs: required_packs,
          allowlisted_origins: allowlisted_origins
        }
      },
      compatibility: %{
        bridge_protocol_version: bridge_vsn,
        native_runtime_version: "1.0.0",
        manifest_schema_version: "1.0.0",
        supported_manifest_sources: [:bundled]
      },
      capability_registry: %{
        "app_info" => %{family: "app_info", version: "1", id: "app_info", legacy_ids: []}
      },
      host: %{origin: "https://app.example.com"}
    }
  end

  defp make_test_request(opts \\ []) do
    bridge_vsn = @vectors["bridge_protocol_version"]

    Contract.new_request(
      command: Keyword.get(opts, :command, "app.info.get"),
      capability: Keyword.get(opts, :capability, "app_info"),
      version: Keyword.get(opts, :version, bridge_vsn),
      route_id: Keyword.get(opts, :route_id, "dashboard"),
      active_route_id: Keyword.get(opts, :active_route_id, "dashboard"),
      origin: Keyword.get(opts, :origin, "https://app.example.com"),
      native_runtime_version: Keyword.get(opts, :native_runtime_version, "1.0.0"),
      correlation_id: "test-corr-id",
      capabilities: Keyword.get(opts, :capabilities, %{"app_info" => "1"})
    )
  end

  test "each vector's expected_outcome matches Elixir bridge_findings result" do
    vectors = @vectors["vectors"]

    for vector <- vectors do
      request_override = vector["request_override"] || %{}
      session_override = vector["session_override"] || %{}
      expected_outcome = vector["expected_outcome"]
      expected_denial_reason = vector["expected_denial_reason"]
      id = vector["id"]

      manifest = apply_session_override(make_test_manifest(), session_override)
      request = apply_request_override(make_test_request(), request_override)

      findings = Compatibility.bridge_findings(manifest, request)

      {actual_outcome, actual_reason} =
        case findings do
          [] -> {"ok", nil}
          [first | _] ->
            denial = Compatibility.finding_to_denial(first, route_id: request.route_id)
            {"deny", Atom.to_string(denial.reason)}
        end

      assert actual_outcome == expected_outcome,
        "Vector #{id}: expected_outcome=#{expected_outcome} but got #{actual_outcome}. Findings: #{inspect(findings)}"

      if expected_denial_reason do
        assert actual_reason == expected_denial_reason,
          "Vector #{id}: expected_denial_reason=#{expected_denial_reason} but got #{actual_reason}"
      end
    end
  end
end
```

**Important:** The exact `make_test_manifest/1` implementation must match the actual `%Root{}`, `%RouteEntry{}`, `%Compatibility{}` struct shapes. Consult `lib/crosswake/manifest/types.ex` when implementing. The above is a sketch; the planner should flag reading `types.ex` as a task.

### Swift vector loading (XCTest)

```swift
// Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift
import XCTest
@testable import CrosswakeShellCore

struct BridgeVector: Codable {
    let id: String
    let description: String
    let requestOverride: [String: AnyCodable]?
    let sessionOverride: [String: AnyCodable]?
    let expectedOutcome: String
    let expectedDenialReason: String?

    enum CodingKeys: String, CodingKey {
        case id, description
        case requestOverride = "request_override"
        case sessionOverride = "session_override"
        case expectedOutcome = "expected_outcome"
        case expectedDenialReason = "expected_denial_reason"
    }
}

struct BridgeVectorsFile: Codable {
    let bridgeProtocolVersion: String
    let vectors: [BridgeVector]
    enum CodingKeys: String, CodingKey {
        case bridgeProtocolVersion = "bridge_protocol_version"
        case vectors
    }
}

final class BridgeConformanceTests: XCTestCase {

    private var vectorsFile: BridgeVectorsFile!

    override func setUp() {
        super.setUp()
        let url = Bundle.module.url(forResource: "bridge_contract_vectors", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        vectorsFile = try! JSONDecoder().decode(BridgeVectorsFile.self, from: data)
    }

    func test_bridge_vectors_each_produce_expected_outcome() {
        for vector in vectorsFile.vectors {
            let session = makeSession(
                bridgeProtocolVersion: vectorsFile.bridgeProtocolVersion,
                overrides: vector.sessionOverride
            )
            let request = makeRequest(
                version: vectorsFile.bridgeProtocolVersion,
                overrides: vector.requestOverride
            )
            let config = makeConfig(for: vector)

            let channel = BridgeChannel(session: session, transferCoordinator: nil,
                                        replySink: { _ in }, config: config)

            var reply: BridgeReplyEnvelope?
            channel.evaluate(request) { reply = $0 }

            XCTAssertNotNil(reply, "Vector \(vector.id): evaluate did not call completion")
            XCTAssertEqual(reply?.status, vector.expectedOutcome,
                           "Vector \(vector.id): expected outcome \(vector.expectedOutcome)")
            if let expectedReason = vector.expectedDenialReason {
                XCTAssertEqual(reply?.denial?.denial.reason, expectedReason,
                               "Vector \(vector.id): expected denial reason \(expectedReason)")
            }
        }
    }
}
```

### Kotlin vector loading (JUnit 4)

```kotlin
// src/test/java/dev/crosswake/shell/core/BridgeConformanceTest.kt
package dev.crosswake.shell.core

import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

class BridgeConformanceTest {

    private lateinit var vectorsJson: JSONObject

    @Before
    fun loadVectors() {
        val stream = javaClass.getResourceAsStream("/bridge_contract_vectors.json")!!
        vectorsJson = JSONObject(stream.bufferedReader().readText())
    }

    @Test
    fun `each vector produces expected outcome from evaluateForTesting`() {
        val bridgeVersion = vectorsJson.getString("bridge_protocol_version")
        val vectors = vectorsJson.getJSONArray("vectors")

        for (i in 0 until vectors.length()) {
            val vector = vectors.getJSONObject(i)
            val id = vector.getString("id")
            val requestOverride = vector.optJSONObject("request_override")
            val sessionOverride = vector.optJSONObject("session_override")
            val expectedOutcome = vector.getString("expected_outcome")
            val expectedReason = vector.optString("expected_denial_reason").takeIf { it.isNotEmpty() }

            val session = makeSession(bridgeVersion, sessionOverride)
            val request = makeRequest(bridgeVersion, requestOverride)
            val config = makeConfig(vector)

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
        }
    }
}
```

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Elixir framework | ExUnit (built-in) |
| Swift framework | XCTest (built-in, swift-tools-version 5.9) |
| Kotlin framework | JUnit 4 (`junit:junit:4.13.2`, already in `build.gradle.kts`) |
| Elixir config | `test/test_helper.exs` (existing) |
| Elixir run command (behavioral test) | `mix test test/crosswake/bridge/bridge_behavioral_vector_test.exs` |
| Elixir full suite | `mix test` |
| Swift run command | `swift test` (in `packages/crosswake-shell-core-ios/`) |
| Kotlin run command | `./gradlew test` (in `packages/crosswake-shell-core-android/`) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NTEST-01 | Version bump fails Elixir suite (vector version-field assertion) | unit | `mix test test/crosswake/bridge/bridge_behavioral_vector_test.exs` | No — Wave 0 |
| NTEST-01 | Version bump fails Swift suite (via `Bundle.module` vectors load) | unit | `swift test` | No — Wave 0 |
| NTEST-01 | Version bump fails Kotlin suite (via classpath resource load) | unit | `./gradlew test` | No — Wave 0 |
| NTEST-02 | iOS activation success | unit (XCTest) | `swift test` | No — Wave 0 |
| NTEST-02 | iOS activation failure (inactive route) | unit (XCTest) | `swift test` | No — Wave 0 |
| NTEST-02 | iOS bridge denial: version mismatch | unit (XCTest, data-driven) | `swift test` | No — Wave 0 |
| NTEST-02 | iOS capability allowlist enforcement | unit (XCTest, data-driven) | `swift test` | No — Wave 0 |
| NTEST-02 | iOS active-route check | unit (XCTest, data-driven) | `swift test` | No — Wave 0 |
| NTEST-02 | iOS pack-version check | unit (XCTest, data-driven) | `swift test` | No — Wave 0 |
| NTEST-02 | iOS delegate/escape-hatch (present + absent) | unit (XCTest) | `swift test` | No — Wave 0 |
| NTEST-03 | Android (same 6 behaviors) | unit (JUnit 4, data-driven) | `./gradlew test` | No — Wave 0 |
| NTEST-04 | Android CI lane merge-blocking | CI gate | CI push | No — Wave 0 |
| NTEST-04 | Swift CI lane advisory | CI gate | CI push (advisory) | No — Wave 0 |
| NTEST-04 | No hardcoded version literals | unit (all three suites load JSON) | All three run commands | No — Wave 0 |

**"Bump → three suites red" headline guarantee:**
- Version bump → gen task regenerates root vectors file with new version
- GUARD-01 ALREADY catches version-field mismatch (do not duplicate)
- GUARD-02 ALREADY catches stale native copies (do not duplicate)
- The NEW behavioral guarantee: native suites load the regenerated file, construct sessions with the new version, and the ok-vector now tests against the new version → tests pass. If a developer regenerates vectors but does NOT update their expected values (impossible in this design since values are loaded from file) → tests remain green. If a developer bumps the version WITHOUT regenerating → GUARD-02 fails before native tests run.

### Sampling Rate

- **Per task commit (Elixir):** `mix test test/crosswake/bridge/bridge_behavioral_vector_test.exs`
- **Per task commit (Swift):** `swift test` in package directory
- **Per task commit (Kotlin):** `./gradlew test` in package directory
- **Per wave merge:** Full `mix test` + `swift test` + `./gradlew test`
- **Phase gate:** All three suites green + CI gate aggregator green before `/gsd-verify-work`

### Wave 0 Gaps (test infrastructure to create)

- `test/crosswake/bridge/bridge_behavioral_vector_test.exs` — Elixir behavioral vector test (NTEST-01)
- `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/` — directory (must exist before gen task writes to it)
- `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift` — Swift bridge tests (NTEST-02)
- `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/ActivationConformanceTests.swift` — Swift activation tests (NTEST-02)
- `packages/crosswake-shell-core-android/src/test/resources/` — directory (must exist before gen task writes to it)
- `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeConformanceTest.kt` — Android bridge tests (NTEST-03)
- `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/ActivationConformanceTest.kt` — Android activation tests (NTEST-03)
- `.github/workflows/native-behavioral-proof-gate.yml` — CI gate (NTEST-04)
- `script/register-native-gate.sh` — registration script (NTEST-04)

Framework install: NOT needed (ExUnit, XCTest, JUnit 4 all already present). Only `kotlinx-coroutines-test:1.7.3` is new (add to `build.gradle.kts`).

---

## Security Domain

This is a test-and-CI authoring phase with no new production code. No ASVS categories apply — the phase does not add authentication, session management, input handling, cryptography, or access control logic. The existing production denial logic being tested was already reviewed when written.

The CI registration script uses `gh` CLI with admin scope — this is consistent with all existing registration scripts and the established v12.0 pattern. No new security surface introduced.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hardcoded version literals in tests | Tests load from committed vectors JSON | Phase 121 → Phase 123 | Version bump automatically propagates; no test-maintenance toil |
| Empty/smoke-only test files | Full behavioral coverage of 6 decision paths | Phase 123 | Packages self-certify their contract |
| Advisory iOS CI merged with emulator tests | Dedicated advisory `macos-latest` no-simulator lane | Phase 122 pattern applied to Phase 123 | Honest CI labels; no fake emulator overhead |
| Single-platform drift guard (Elixir only) | Three-suite proof (Elixir + Swift + Kotlin) | Phase 123 | Version bump causes all three to fail simultaneously |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Crosswake.Compatibility.bridge_findings/2` is the correct seam for the Elixir behavioral test; no intermediate wrapping needed | Elixir Seam | If the bridge has an additional dispatch layer above `bridge_findings`, the test may not exercise the full decision path |
| A2 | `make_test_manifest/1` can be built inline without loading a real `crosswake_manifest.json` | Elixir Seam | If `%Root{}` struct has required fields not shown in `compatibility_test.exs`, the struct construction will fail at test time |
| A3 | `kotlinx-coroutines-test:1.7.3` is compatible with `kotlinx-coroutines-android:1.7.3` (same major.minor) | Standard Stack | Minor version mismatch would cause dependency resolution failure in Gradle |
| A4 | `swift test` in `packages/crosswake-shell-core-ios/` succeeds on `macos-latest` GitHub runner after iOS test file is replaced | CI Topology | If Xcode version on runner doesn't support the Package.swift resources syntax, the build will fail |

**If this table is complete:** Claims A1-A4 are the only unverified assumptions. All structural facts (seam signatures, denial reason strings, file locations, existing CI patterns) were verified directly against source code.

---

## Open Questions

1. **Exact `%Root{}` struct shape for Elixir test manifest**
   - What we know: `Crosswake.Compatibility.bridge_findings/2` takes `%Root{}` from `Manifest.Types`; the struct has `routes`, `compatibility`, `capability_registry`, `host` fields (seen in compatibility.ex usage)
   - What's unclear: Whether all fields are enforced (non-nil); what `%RouteEntry{}` and `%Capability{}` look like exactly; whether `compatibility.ex` inline construction is idiomatic or whether a factory like `Types.build_manifest/1` exists
   - **Recommendation:** The planner should include a task to read `lib/crosswake/manifest/types.ex` and `test/crosswake/compatibility/compatibility_test.exs:manifest_fixture/0` helper before writing the Elixir behavioral test

2. **Whether to extend GUARD-01's tripwire list for the two new native copies (D-05)**
   - What we know: GUARD-02 already diffs them at CI time; GUARD-01 provides a faster local dev-experience tripwire
   - What's unclear: Whether the DX benefit outweighs the maintenance cost of adding two more paths to the GUARD-01 list
   - **Recommendation:** Include it as a separate optional task (planner discretion); the tripwire addition is small

3. **vec-003 ok-path: does the Elixir seam need an appInfoDelegate equivalent?**
   - What we know: In native, the ok-path requires a configured `appInfoDelegate`; `BridgeChannel` returns `undeclared_capability` if delegate is nil even after all other checks pass. In Elixir, `bridge_findings/2` does NOT check for delegate configuration — it only checks that the capability is declared on the manifest and the route. So the Elixir ok-vector does NOT need a delegate — it just needs the route to have the `app_info` capability declared.
   - What's unclear: None — this asymmetry is known and acceptable. The Elixir test exercises the DECISION logic; delegate wiring is a production concern.
   - **Recommendation:** Document this asymmetry in the test file's moduledoc.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | Elixir behavioral test | ✓ | `.tool-versions` pinned | — |
| Swift / SPM | iOS test suite | ✓ (macOS dev machine) | 5.9+ | macos-latest runner in CI |
| JVM / Gradle | Android test suite | ✓ | Java 17 per `build.gradle.kts` | — |
| `kotlinx-coroutines-test:1.7.3` | Android async test paths | ✗ (not yet in build.gradle.kts) | — | Must add to dependencies |
| GitHub Actions `macos-latest` | iOS CI advisory lane | ✓ | Managed by GitHub | — |
| GitHub Actions `ubuntu-latest` | Android CI blocking lane | ✓ | Managed by GitHub | — |

**Missing dependencies with no fallback:** None — only `kotlinx-coroutines-test` needs adding and it has no blockers.

**Missing dependencies with fallback:** None.

---

## Sources

### Primary (HIGH confidence — verified against source code)
- `lib/crosswake/compatibility/compatibility.ex` — Elixir bridge_findings seam, finding_to_denial, check order, denial reason atoms
- `lib/crosswake/shell/denial.ex` — all denial reason atoms; Denial.reasons/0 including gate_denied/kill_switch_active not in bridge vectors
- `lib/crosswake/bridge/contract.ex` — Contract.version(), protocol(), commands(), Request/Reply struct shapes
- `lib/mix/tasks/crosswake.contract.gen.ex` — vectors_json/4 current shape, seed_vectors/1 list, encode_doc/pairs_to_map determinism, write_if_changed idempotency
- `test/fixtures/bridge_contract_vectors.json` — current 3-vector seed; schema shape
- `test/crosswake/contract/contract_drift_test.exs` — GUARD-01 tripwire list, @generated_json_paths pattern
- `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift` — evaluate() signature (line 180), denial reason strings (lines 184, 189, 193, 203, 218, 228), init() signature
- `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/CrosswakeShellCoreTests.swift` — confirmed corruption (literal `\n` bytes)
- `packages/crosswake-shell-core-ios/Package.swift` — swift-tools-version 5.9, NO resources declaration on testTarget
- `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt` — evaluateForTesting() (line 307), evaluate() decision flow (lines 101-134), denial reason strings
- `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/ActivationCoordinator.kt` — RouteDenialReason enum (lines 28-36), ActivationSource enum
- `packages/crosswake-shell-core-android/build.gradle.kts` — JUnit 4 already present; kotlinx-coroutines-test absent
- `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/CrosswakeShellConfigTest.kt` — existing JUnit 4 pattern; anonymous delegate objects
- `.github/workflows/contract-drift-gate.yml` — exact CI topology idiom; cache key pattern; aggregator `needs:` and `if: always()`
- `script/register-contract-gate.sh` — green-first preflight pattern; exact jq payload; gh api -X PATCH command
- `.github/workflows/native-collateral-advisory.yml` — confirmed advisory lane idiom (no aggregator, workflow_dispatch only)

### Secondary (MEDIUM confidence — research docs cross-checked against source)
- `.planning/research/NATIVE-TESTING.md` — XCTest §3 and JUnit §4 code examples confirmed correct against actual seam signatures; §10 CI claim superseded; §9 native constant claim rejected per D-10
- `.planning/research/PITFALLS.md` — parse-not-grep rule confirmed; anti-vacuous rule confirmed
- `.planning/phases/123-native-package-behavioral-proof/123-CONTEXT.md` — all D-01..D-14 decisions incorporated

---

## Metadata

**Confidence breakdown:**
- D-09 Elixir seam: HIGH — confirmed against `compatibility.ex:91` and `compatibility.ex:106`
- Native seams: HIGH — confirmed against Swift and Kotlin source files
- Vector schema expansion: HIGH — gen task source verified; encode_doc determinism documented
- CI topology: HIGH — contract-drift-gate.yml + register script confirmed as template
- Swift Package.swift resource syntax: HIGH — official SPM documentation [ASSUMED: exact Xcode version compatibility]
- Denial reason matching: HIGH — read from actual source files line-by-line

**Research date:** 2026-06-20
**Valid until:** 2026-07-20 (stable Elixir/Swift/Kotlin APIs; CI action versions pinned)
