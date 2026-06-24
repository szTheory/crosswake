---
phase: 124-compatibility-semantics-adopter-truth
verified: 2026-06-21T18:00:00Z
status: passed
score: 5/5
behavior_unverified: 0
overrides_applied: 0
re_verification: true
re_verification_meta:
  previous_status: gaps_found
  previous_score: 4/5
  gaps_closed:
    - "iOS BridgeChannel.swift capabilityAvailable() now uses SemVer.compatible (provides=request, demands=session) — exact == eliminated"
    - "Android BridgeChannel.kt 6 per-command != guards replaced by single capabilityAvailable(command, request) helper using SemVer.compatible"
    - "iOS ActivationCoordinator.resolve() now gates native_runtime_version via SemVer.compatible as first guard, mirroring Android ActivationCoordinator.kt:333"
    - "Phantom vec-012/013 (manifest_schema) removed from seed and regenerated fixture; vec-014 made discriminating (request 1.1.0 > session 1.0.0); native harnesses wired to decode per-vector request capabilities"
  gaps_remaining: []
  regressions: []
warnings:
  - id: WR-01
    source: "124-REVIEW.md"
    file: "lib/mix/tasks/crosswake.contract.gen.ex:258"
    severity: warning
    summary: "Generator comment for vec-014 overclaims: 'Exercised by both Elixir bridge_findings ... and native.' The Elixir bridge_behavioral_vector_test.exs make_permissive_request/1 hardcodes capabilities: %{'app_info' => '1.0.0'} and ignores request_override['capabilities']. Vec-014 runs in the Elixir suite but tests 1.0.0 vs 1.0.0 (vacuous pass under both == and >=). The discriminating floor proof (1.1.0 vs 1.0.0) is exercised only on native. The Elixir IMPLEMENTATION (compatible_version?/2) is correct floor semantics; the VECTOR PROOF is non-discriminating on the Elixir side."
    production_impact: none
    disposition: "Comment accuracy gap + test-coverage gap for the discriminating Elixir path. Does not block COMPAT-01: the requirement targets native exact-equality elimination; Elixir was never broken. Recommend either tagging vec-014 native_only or teaching the Elixir harness to honor request_override['capabilities']. See WR-01 in 124-REVIEW.md for the fix option."
  - id: WR-02
    source: "124-REVIEW.md"
    file: "packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt:127-133"
    severity: warning
    summary: "Android pack-requirement parser diverges from iOS on malformed 'test-pack@' (empty version): Android resolves requiredVersion to '' and fails closed, iOS drops the trailing empty component and allows 'present, any version'. Not exercised by any current vector."
    production_impact: latent
    disposition: "Pre-existing cross-platform divergence, not introduced by 124-06. Carry as follow-up."
  - id: WR-03
    source: "124-REVIEW.md"
    file: "packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/SemVer.swift:26-29"
    severity: warning
    summary: "SemVer.compatible unparseable-version fallback returns true for identical garbage strings (e.g. 'latest' >= 'latest'). 'fail-closed' label in doc-comment overstates the guarantee."
    production_impact: bounded
    disposition: "Matches pre-existing Elixir fallback. All inputs today are generated well-formed semver. Carry as follow-up; consider tightening SemVer.compatible to deny unconditionally on unparseable versions."
---

# Phase 124: Compatibility Semantics & Adopter Truth — Re-Verification Report

**Phase Goal:** The bridge-protocol compatibility check uses `>=` min-version-floor semantics across both Elixir and native, eliminating the exact-equality denial footgun; adopters have a clear decision table mapping each version-axis change to its rebuild requirement; doctor output names the full action sequence when a mismatch is detected.

**Verified:** 2026-06-21T18:00:00Z
**Status:** passed
**Re-verification:** Yes — after gap-closure plan 124-06 (COMPAT-01 blockers)
**Previous status:** gaps_found (4/5) — COMPAT-01 had 3 confirmed blockers; COMPAT-02..05 SATISFIED

---

## Re-Verification Mode: Focus Areas

Previous VERIFICATION.md (2026-06-20) identified 3 COMPAT-01 blockers:

1. iOS `BridgeChannel.swift:401` — `capabilityAvailable()` used `== requiredCapabilityVersion` (exact equality)
2. Android `BridgeChannel.kt:142,156,172,194,213,228` — six per-command blocks used `!= requiredCapabilityVersion` (exact inequality)
3. iOS `ActivationCoordinator.swift:resolve()` — zero `SemVer.compatible` calls; no native-runtime floor gate
4. `bridge_contract_vectors.json` — vec-012/013 phantom (manifest_schema, no native decode path); vec-014 non-discriminating (1.0.0 vs 1.0.0 passes by equality coincidence)

Gap-closure plan 124-06 executed 4 tasks across commits c1a2ab2, 02e0bbf, 614a1c7, 1ac6638. This re-verification focuses on confirming those blockers are closed, then regression-checks COMPAT-02..05.

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Zero exact-equality capability comparisons remain in native bridge code | VERIFIED | `grep -c '== requiredCapabilityVersion' BridgeChannel.swift` = 0; `grep -c '!= requiredCapabilityVersion' BridgeChannel.kt` = 0 |
| 1b | iOS `capabilityAvailable()` floors capability axis via `SemVer.compatible(provides=request, demands=session)` | VERIFIED | `BridgeChannel.swift:401`: `return SemVer.compatible(provides: request.capabilities[command.capability], demands: requiredCapabilityVersion)` confirmed in live code; 6 call sites unchanged; session-missing guard preserved at line 397 |
| 1c | Android `capabilityAvailable(command, request)` helper extracts SemVer floor, replacing all 6 inline guards | VERIFIED | `BridgeChannel.kt:308-311`: `private fun capabilityAvailable(command: BridgeCommand, request: BridgeRequestEnvelope)` present, 1 definition, 6 call sites (`grep -c 'capabilityAvailable(command, request)'` = 6); `SemVer.compatible(provides = request.capabilities[command.capability], demands = required)` at line 310 |
| 1d | iOS `ActivationCoordinator.resolve()` gates `native_runtime_version` via SemVer floor as first guard | VERIFIED | `ActivationCoordinator.swift:340`: `guard SemVer.compatible(provides: manifest.compatibility.nativeRuntimeVersion, demands: request.nativeRuntimeVersion)` is the FIRST guard inside `resolve()` (before the `route(for:` guard at line 352); uses `manifest.compatibility` (new property added in this plan); `grep -c 'SemVer.compatible' ActivationCoordinator.swift` = 1 |
| 1e | Discriminating capability ALLOW vector (request 1.1.0 > session 1.0.0) is driven through both native harnesses | VERIFIED | `test/fixtures/bridge_contract_vectors.json` vec-014: `request_override.capabilities["app.info.get"] = "1.1.0"`, `session_override.capabilities["app.info.get"] = "1.0.0"`, `expected_outcome: ok`; iOS `BridgeConformanceTests.swift:185` applies per-vector `requestOverride.capabilities ?? ["app.info.get": "1.0.0"]`; Android `BridgeConformanceTest.kt:142-147` applies `request_override.capabilities` via `applyRequestOverride`; vec-014 has no `native_only` flag so runs on both native harnesses |
| 1f | No phantom vectors remain: vec-012/013 (manifest_schema) removed; every remaining vector exercises a real decode-to-SemVer path | VERIFIED | `grep '"id":' bridge_contract_vectors.json` shows 15 vectors; vec-012 and vec-013 absent; `grep -c 'manifest_schema\|manifest-schema' bridge_contract_vectors.json` = 1 (top-level metadata field only, not a test vector); remaining vectors all map to `SemVer.compatible` call sites in native code |
| 2 | Each version axis mapped to rebuild class in one committed source, guarded by docs-contract test | VERIFIED (regression check) | `rebuild_decision_table/0` in `support_matrix.ex:532`; phase52 byte-parity guard present; no regression in 124-06 commits |
| 3 | `support_matrix.md` and `guides/compatibility.md` lead with decision table before prose | VERIFIED (regression check) | `support_matrix.md:133` has `## Rebuild Decision Table`; `compatibility.md` has `## Do I need to rebuild? (start here)` (`grep -c` = 2 matches); no regression |
| 4 | Doctor output names change class + full action sequence + denial reason + guide link | VERIFIED (regression check) | `publish_readiness.ex:683` `compatibility_rebuild_guidance_check`; wired at line 175; no regression |
| 5 | CHANGELOG entries carry upgrade-impact label | VERIFIED (regression check) | `grep -c '### Upgrade Impact' CHANGELOG.md` = 2; no regression |

**Score: 5/5 truths verified**

---

## COMPAT-01 Deep Verification

### Blocker 1 — Capability-version exact equality: CLOSED

**iOS `BridgeChannel.swift:396-402`** (was exact `==`, now floor):
```swift
private func capabilityAvailable(for command: BridgeCommand, request: BridgeRequestEnvelope) -> Bool {
    guard let requiredCapabilityVersion = session.capabilities[command.capability] else {
        return false
    }
    return SemVer.compatible(provides: request.capabilities[command.capability], demands: requiredCapabilityVersion)
}
```
- `grep -c '== requiredCapabilityVersion' BridgeChannel.swift` = 0 (CONFIRMED)
- `grep -c 'SemVer.compatible(provides: request.capabilities' BridgeChannel.swift` = 1 (CONFIRMED)
- Total `SemVer.compatible` calls in BridgeChannel.swift = 4 (bridge:182, runtime:183, pack:215, capability:401)

**Android `BridgeChannel.kt:308-311`** (was 6 inline guards, now one helper):
```kotlin
private fun capabilityAvailable(command: BridgeCommand, request: BridgeRequestEnvelope): Boolean {
    val required = session.capabilities[command.capability] ?: return false
    return SemVer.compatible(provides = request.capabilities[command.capability], demands = required)
}
```
- `grep -c '!= requiredCapabilityVersion' BridgeChannel.kt` = 0 (CONFIRMED)
- `grep -c 'private fun capabilityAvailable(' BridgeChannel.kt` = 1 (CONFIRMED)
- `grep -c 'capabilityAvailable(command, request)' BridgeChannel.kt` = 6 (CONFIRMED, one per command)
- Total `SemVer.compatible` calls in BridgeChannel.kt = 4 (bridge:102, runtime:103, pack:132, capability:310)

**Provides/demands direction:** Both platforms use `provides=request.capabilities[cap], demands=session.capabilities[cap]` — OPPOSITE of bridge/runtime sites (where provides=session). This correctly mirrors `compatibility.ex:585`: `compatible_version?(available_version = request.capabilities[cap], required_version = registry[cap].version)`.

### Blocker 2 — iOS ActivationCoordinator native-runtime gate: CLOSED

`ActivationCoordinator.swift:339-350` (was 0 SemVer calls, now has first-guard floor):
```swift
public func resolve(request: ActivationRequest, manifest: ShellManifest) -> ShellPresentation {
    guard SemVer.compatible(provides: manifest.compatibility.nativeRuntimeVersion, demands: request.nativeRuntimeVersion) else {
        return .denied(denial(reason: .compatibilityMismatch, ...))
    }
    guard let route = route(for: request, manifest: manifest) else { ... }  // line 352, AFTER floor gate
```

- `grep -c 'SemVer.compatible' ActivationCoordinator.swift` = 1 (CONFIRMED, was 0)
- `grep -c 'SemVer.compatible(provides: manifest.compatibility' ActivationCoordinator.swift` = 1 (CONFIRMED)
- Floor gate is FIRST statement in `resolve()` — line 340 precedes `route(for:` at line 352 (CONFIRMED from source)
- iOS `ShellManifest` now exposes `public let compatibility: Compatibility` (was missing despite nested struct existing); `ActivationConformanceTests.swift` construction sites updated
- Provides=manifest, demands=request — mirrors `ActivationCoordinator.kt:333` exactly

### Blocker 3 — Phantom vectors and non-discriminating vec-014: CLOSED

**Phantom vectors removed:**
- `grep '"id":' bridge_contract_vectors.json` — vec-012 and vec-013 absent from all 3 copies (canonical + 2 native resource copies)
- `grep -c 'manifest_schema' bridge_contract_vectors.json` = 1 (only the top-level metadata field `manifest_schema_version: "1.0.0"`, not a test vector)
- 15 vectors remain; all map to real decode-to-SemVer code paths in native

**Vec-014 discriminating (native):**
- `request_override.capabilities["app.info.get"] = "1.1.0"` (was "1.0.0")
- `session_override.capabilities["app.info.get"] = "1.0.0"`
- `expected_outcome: ok`
- Under pre-fix iOS `==`: `"1.1.0" == "1.0.0"` → false → deny → WOULD FAIL the test
- Under pre-fix Android `!=`: `"1.1.0" != "1.0.0"` → true → deny → WOULD FAIL the test
- Under fixed SemVer floor: `SemVer.compatible("1.1.0", "1.0.0")` → `1.1.0 >= 1.0.0` → true → allow → PASSES
- Both native harnesses decode `request_override.capabilities` and apply them to the request (iOS line 185, Android line 142-147)

---

## WR-01 Assessment: Elixir Harness Vacuous Coverage of Vec-014

**Finding (from 124-REVIEW.md):** The generator comment at `crosswake.contract.gen.ex:258` claims vec-014 is "Exercised by both Elixir bridge_findings (`compatible_version?` on capability axis) and native." This is false for the discriminating dimension.

**Evidence:**
- `bridge_behavioral_vector_test.exs:236`: `capabilities: %{"app_info" => "1.0.0"}` — hardcoded, not read from `request_override["capabilities"]`
- Vec-014 has no `native_only` flag, so the Elixir suite runs it
- The Elixir test actually evaluates `1.0.0 >= 1.0.0` (passes under both `==` and `>=`) — the discriminating `1.1.0 >= 1.0.0` path is NOT exercised in Elixir

**Verdict:** This is a **comment accuracy gap + test coverage gap**, NOT a production code defect.

- The Elixir `compatible_version?/2` at `compatibility.ex:585` IS correct floor semantics (has always been)
- COMPAT-01 required fixing the NATIVE exact-equality bug; Elixir was never broken
- The discriminating floor proof is real and complete on native (iOS + Android)
- The Elixir harness correctly exercises vec-014's session_override.capabilities (reads `1.0.0` from the session side) — only the REQUEST capabilities side is ignored
- The generator comment line 258 is inaccurate: it should say "Exercised by native harnesses; Elixir harness exercises this vector but does not decode request_override.capabilities (make_permissive_request hardcodes capabilities: %{'app_info' => '1.0.0'})"

**COMPAT-01 impact:** None. The requirement goal is "native exact-equality check is changed to negotiate by floor" — this is met. The Elixir floor proof exists via `compatibility_test.exs` independently of vec-014. WR-01 is a WARNING, not a BLOCKER, and does not prevent COMPAT-01 from being SATISFIED.

**Recommended follow-up (see WR-01 in 124-REVIEW.md):** Either (a) tag vec-014 `native_only: true` to stop the Elixir suite from claiming coverage it does not discriminate, or (b) teach `make_permissive_request` to honor `request_override["capabilities"]` (translating the command key to the registry capability_id).

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift` | `capabilityAvailable()` floors via `SemVer.compatible(provides=request, demands=session)` | VERIFIED | Line 401: floor call confirmed; 0 exact == remains; 4 total SemVer.compatible calls |
| `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt` | `capabilityAvailable(command, request)` helper + 6 call sites | VERIFIED | Line 308-311: 1 helper definition, 6 call sites, `SemVer.compatible(provides=request, demands=required)` at 310 |
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift` | `resolve()` gates `native_runtime_version` via SemVer floor as first guard | VERIFIED | Line 340: `guard SemVer.compatible(provides: manifest.compatibility.nativeRuntimeVersion, demands: request.nativeRuntimeVersion)`; precedes `route(for:` at 352 |
| `test/fixtures/bridge_contract_vectors.json` | No phantom vectors; vec-014 discriminating (1.1.0 vs 1.0.0); 3 copies byte-identical | VERIFIED | vec-012/013 absent; vec-014 confirmed; 3 copies regenerated by `mix crosswake.contract.gen` |
| `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift` | Decodes per-vector `request_override.capabilities`; skips `elixir_only` vectors | VERIFIED | Line 185: `requestOverride.capabilities ?? ["app.info.get": "1.0.0"]`; line 216: skips `elixirOnly` |
| `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeConformanceTest.kt` | `applyRequestOverride` applies `request_override.capabilities`; skips `elixir_only` | VERIFIED | Lines 142-147: `if (requestOverride.has("capabilities"))` → `result.copy(capabilities = caps)`; line 167: skips `elixir_only` |
| `lib/mix/tasks/crosswake.contract.gen.ex` | vec-012/013 removed from seed; vec-014 discriminating; vec-001 tagged `elixir_only` | VERIFIED | Seed confirmed; `mix crosswake.contract.gen` regenerates idempotently |
| `lib/crosswake/support_matrix/support_matrix.ex` | `rebuild_decision_table/0` (11 rows) | VERIFIED (no regression) | Line 532 confirmed; no 124-06 touches |
| `guides/compatibility.md` | Decision table leads guide | VERIFIED (no regression) | `## Do I need to rebuild? (start here)` at line 3; no regression |
| `lib/crosswake/doctor/publish_readiness.ex` | `compatibility_rebuild_guidance_check` | VERIFIED (no regression) | Line 683; wired at line 175; no regression |
| `CHANGELOG.md` | `### Upgrade Impact` in each release | VERIFIED (no regression) | `grep -c '### Upgrade Impact' CHANGELOG.md` = 2; no regression |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `BridgeChannel.swift:401` | `SemVer.swift` | `SemVer.compatible(provides: request.capabilities[cap], demands: requiredCapabilityVersion)` | VERIFIED | Was exact `==`, now floor; 0 exact == remain |
| `BridgeChannel.swift:182-183,215` | `SemVer.swift` | bridge, runtime, pack floor calls | VERIFIED (no regression) | Unchanged from initial verification |
| `BridgeChannel.kt:308-311` | `SemVer.kt` | `capabilityAvailable` helper → `SemVer.compatible(provides=req, demands=required)` | VERIFIED | Was 6 inline guards, now 1 helper |
| `BridgeChannel.kt:102-103,132` | `SemVer.kt` | bridge, runtime, pack floor calls | VERIFIED (no regression) | Unchanged |
| `ActivationCoordinator.swift:340` | `SemVer.swift` | `resolve()` first guard → `SemVer.compatible(provides: manifest.compatibility.nativeRuntimeVersion, demands: request.nativeRuntimeVersion)` | VERIFIED | Was missing (0 calls); now present; first in resolve() |
| `ActivationCoordinator.kt:333` | `SemVer.kt` | `SemVer.compatible(provides=manifest.nativeRuntimeVersion, demands=request.nativeRuntimeVersion)` | VERIFIED (no regression) | Reference implementation; unchanged |
| `BridgeConformanceTests.swift:185` | `vec-014.request_override.capabilities` | `requestOverride.capabilities ?? fallback` | VERIFIED | Per-vector request capabilities now decoded |
| `BridgeConformanceTest.kt:142-147` | `vec-014.request_override.capabilities` | `applyRequestOverride` → `result.copy(capabilities=caps)` | VERIFIED | Per-vector request capabilities now applied |

---

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| iOS exact `==` capability check eliminated | `grep -c '== requiredCapabilityVersion' BridgeChannel.swift` | 0 | PASS |
| iOS `capabilityAvailable()` uses `SemVer.compatible(provides: request.capabilities...)` | `grep -c 'SemVer.compatible(provides: request.capabilities' BridgeChannel.swift` | 1 | PASS |
| Android exact `!=` capability checks eliminated | `grep -c '!= requiredCapabilityVersion' BridgeChannel.kt` | 0 | PASS |
| Android helper exists and has 6 call sites | `grep -c 'private fun capabilityAvailable('` + `grep -c 'capabilityAvailable(command, request)'` | 1, 6 | PASS |
| iOS ActivationCoordinator has SemVer floor gate | `grep -c 'SemVer.compatible' ActivationCoordinator.swift` | 1 | PASS |
| iOS floor gate precedes route guard in resolve() | Source read: line 340 SemVer guard, line 352 route guard | Confirmed order | PASS |
| No phantom manifest_schema vectors | `grep -c 'manifest_schema' bridge_contract_vectors.json` | 1 (metadata only) | PASS |
| vec-014 has discriminating capability versions | JSON parse: `request_override.capabilities["app.info.get"] = "1.1.0"`, `session = "1.0.0"` | Confirmed | PASS |
| vec-012 and vec-013 absent | `grep '"id":' bridge_contract_vectors.json` | Neither present in 15 vectors | PASS |
| Android ActivationCoordinator floor gate not regressed | `grep -c 'SemVer.compatible' ActivationCoordinator.kt` | 1 (line 333) | PASS |
| COMPAT-02..05 files not touched by 124-06 commits | `git log --name-only c1a2ab2 02e0bbf 614a1c7 1ac6638` | Only native + vectors + harness files touched | PASS |
| CHANGELOG Upgrade Impact count | `grep -c '### Upgrade Impact' CHANGELOG.md` | 2 | PASS |

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|---------|
| COMPAT-01 | 124-01/06-PLAN.md | `>=` floor semantics across Elixir and native for ALL version axes | SATISFIED | Exact-equality eliminated on ALL native axes (bridge/runtime/pack were fixed in 124-01; capability and iOS activation gate closed in 124-06); Elixir `compatible_version?/2` was always correct floor; discriminating vec-014 proves the native fix |
| COMPAT-02 | 124-02-PLAN.md | Each version axis mapped to rebuild class in one source, guarded by docs-contract test | SATISFIED (no regression) | `rebuild_decision_table/0` (11 rows); phase52 byte-parity guard wired |
| COMPAT-03 | 124-03-PLAN.md | Support matrix + compatibility guide lead with decision table | SATISFIED (no regression) | `compatibility.md` decision-table-first; 6 `compatibility_test.exs` tests pass |
| COMPAT-04 | 124-04-PLAN.md | Doctor names change class + action sequence + denial reason + guide link | SATISFIED (no regression) | `compatibility_rebuild_guidance_check` at line 683; 4-step action sequence |
| COMPAT-05 | 124-05-PLAN.md | Changelog upgrade-impact label per release | SATISFIED (no regression) | 2x `### Upgrade Impact` in CHANGELOG.md; vocabulary+structural tests pass |

---

## Prohibition Compliance

| Prohibition | Status | Evidence |
|-------------|--------|---------|
| MUST NOT touch 124-02..05 deliverables | COMPLIANT | `git log --name-only` for 124-06 commits shows only BridgeChannel.swift/kt, ActivationCoordinator.swift, ActivationConformanceTests.swift, contract.gen.ex, bridge_contract_vectors.json (3 copies), BridgeConformanceTests.swift/.kt |
| MUST NOT regress bridge/runtime/pack floor sites | COMPLIANT | Lines 182-183,215 (iOS) and 102-103,132 (Android) unchanged; Android ActivationCoordinator.kt:333 unchanged |
| MUST NOT add third-party semver dependency | COMPLIANT | Reuses in-tree `SemVer.swift` / `SemVer.kt`; no package changes |
| MUST NOT invert capability-axis provides/demands | COMPLIANT | provides=request, demands=session in both platforms; matches compatibility.ex:585 |
| MUST NOT hand-edit bridge_contract_vectors.json | COMPLIANT | JSON is generated output; seed edited in contract.gen.ex; `mix crosswake.contract.gen` regenerated all 3 copies |
| MUST NOT leave phantom vectors | COMPLIANT | vec-012/013 removed; remaining 15 vectors all exercise real decode-to-SemVer paths |

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/mix/tasks/crosswake.contract.gen.ex` | 258 | Comment claims "Exercised by both Elixir ... and native" for vec-014 | WARNING (WR-01) | False claim: Elixir harness ignores `request_override["capabilities"]`; discriminating floor proof is native-only. Not a production defect. |
| `packages/crosswake-shell-core-android/.../BridgeChannel.kt` | 127-133 | Android pack-requirement parser malformed-`@` behavior diverges from iOS | WARNING (WR-02) | Latent cross-platform divergence; not exercised by any vector; pre-existing |
| `packages/crosswake-shell-core-ios/.../SemVer.swift` | 26-29 | `SemVer.compatible` identical-garbage strings return true (not strictly fail-closed) | WARNING (WR-03) | Bounded: all inputs are generated well-formed semver; matches Elixir fallback parity |

No BLOCKER anti-patterns found. TBD/FIXME/XXX scan: none found in files modified by 124-06 commits.

---

## Gaps Summary

No gaps remain. All 3 COMPAT-01 blockers from the previous verification are closed:

1. **iOS capability-version exact `==` → floor:** `BridgeChannel.swift:401` now calls `SemVer.compatible(provides: request.capabilities[command.capability], demands: requiredCapabilityVersion)`. Zero `== requiredCapabilityVersion` occurrences confirmed.

2. **Android capability-version 6x exact `!=` → floor helper:** `BridgeChannel.kt` has one `private fun capabilityAvailable(command, request)` that calls `SemVer.compatible(provides=request.capabilities[cap], demands=required)`, and 6 call sites replace the inline guards. Zero `!= requiredCapabilityVersion` occurrences confirmed.

3. **iOS ActivationCoordinator missing native-runtime gate → added:** `ActivationCoordinator.swift:340` is the first guard in `resolve()`, calling `SemVer.compatible(provides: manifest.compatibility.nativeRuntimeVersion, demands: request.nativeRuntimeVersion)`. The `ShellManifest.compatibility` property was added to surface the value.

4. **Phantom vectors and non-discriminating capability vec:** vec-012/013 removed; vec-014 uses request 1.1.0 vs session 1.0.0 (discriminating: passes under floor, would fail under old `==`); both native harnesses wire per-vector request capabilities.

**WR-01 note (from code review):** The generator comment at `contract.gen.ex:258` overclaims Elixir coverage of vec-014's discriminating dimension. This is a comment accuracy issue and a test-coverage gap — the Elixir floor implementation itself is correct and was never broken. COMPAT-01's core deliverable (eliminating native exact-equality) is complete. WR-01 is a non-blocking follow-up item (see 124-REVIEW.md for fix options).

COMPAT-02..05 spot-checked for regression: no regressions found.

**Phase 124 is ready to close.**

---

_Verified: 2026-06-21T18:00:00Z_
_Verifier: Claude (gsd-verifier)_
_Mode: Re-verification (initial: 2026-06-20T18:00:00Z, status: gaps_found 4/5)_
