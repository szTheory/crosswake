---
phase: 124-compatibility-semantics-adopter-truth
reviewed: 2026-06-20T00:00:00Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - lib/crosswake/doctor/publish_readiness.ex
  - lib/crosswake/manifest/types.ex
  - lib/crosswake/support_matrix/renderer.ex
  - lib/crosswake/support_matrix/support_matrix.ex
  - lib/mix/tasks/crosswake.contract.gen.ex
  - packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/ActivationCoordinator.kt
  - packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt
  - packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/SemVer.kt
  - packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeConformanceTest.kt
  - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift
  - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/SemVer.swift
  - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift
findings:
  critical: 3
  warning: 2
  info: 1
  total: 6
status: issues_found
---

# Phase 124: Code Review Report

**Reviewed:** 2026-06-20
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

This phase ports Elixir's `compatible_version?/2` floor-semantics (`>=`) to Swift and Kotlin native helpers and adds an adopter-facing rebuild decision table, doctor advisory check, and changelog label. The Elixir Renderer and SupportMatrix changes are clean and correct. The SemVer helper implementations are largely faithful to the Elixir spec. Three correctness defects remain.

The two most severe are an outright missing floor gate in iOS `ActivationCoordinator` and an unreconverted exact-match on the capability-version axis in both native platforms — the second defect being precisely the D-06 scope item the phase plan declared as "clean sweep of EVERY native exact-match version footgun." The third critical defect is a silent test gap: the manifest_schema_version floor vectors (vec-012/vec-013) exercise a field that neither native test harness applies to the actual bridge call, so those vectors give false conformance confidence.

---

## Critical Issues

### CR-01: iOS ActivationCoordinator missing `nativeRuntimeVersion` floor gate

**File:** `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift:333`

**Issue:** The iOS `resolve(request:manifest:)` function never calls `SemVer.compatible` for `nativeRuntimeVersion`. Android's `resolve` at `ActivationCoordinator.kt:332-343` correctly guards `!SemVer.compatible(provides = manifest.nativeRuntimeVersion, demands = request.nativeRuntimeVersion)` as the first check. The iOS equivalent has no corresponding guard at all. A request demanding a newer native runtime than the installed shell provides will proceed to session creation rather than being denied with `compatibility_mismatch`.

D-03 of the phase context explicitly names the iOS `ActivationCoordinator` as one of four fix sites, and the fix applies D-01's direction: `manifest.nativeRuntimeVersion` (what the shell provides) must be `>=` `request.nativeRuntimeVersion` (what is demanded). The iOS site is simply absent.

**Fix:** Insert the following guard immediately at the top of `resolve(request:manifest:)` in `ActivationCoordinator.swift`, mirroring the Android implementation:

```swift
// COMPAT-01: shell must provide >= the demanded native runtime floor.
guard SemVer.compatible(provides: manifest.nativeRuntimeVersion, demands: request.nativeRuntimeVersion) else {
    return .denied(
        denial(
            reason: .compatibilityMismatch,
            routeID: request.routeID,
            manifest: manifest,
            message: "This route requires a newer shell binary to boot.",
            hint: "This shell binary is below the minimum native runtime version required by the server. Update to a shell at or above the requested native runtime version."
        )
    )
}
```

---

### CR-02: Capability-version check still uses exact-match `==` in both native platforms

**File (iOS):** `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift:401`
**File (Kotlin):** `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt:142` (and repeated at lines 156, 172, 194, 213, 229)

**Issue:** `capabilityAvailable(for:request:)` in Swift returns `request.capabilities[command.capability] == requiredCapabilityVersion` — exact equality. Every per-command capability check in `BridgeChannel.kt` performs `request.capabilities[command.capability] != requiredCapabilityVersion` — also exact equality. Elixir's `compatibility.ex:585` uses `compatible_version?(available_version, required_version)` which is a `>=` floor, not equality. Phase context D-06 explicitly scoped capability-version floors into this phase as a "clean sweep of EVERY native exact-match version footgun," and vec-014/vec-015 are the floor conformance vectors for this axis. The exact-match residual means a shell shipping capability version `1.1.0` will incorrectly deny a request asking for `1.0.0`, reintroducing the original footgun on the capability axis.

The floor direction here is: `session.capabilities[id]` (what the shell provides) must be `>=` `request.capabilities[id]` (what the request demands). This matches Elixir's `available_version` (from `target.capabilities`) vs `required_version` (from the capability registry).

**Fix (Swift):**

```swift
private func capabilityAvailable(for command: BridgeCommand, request: BridgeRequestEnvelope) -> Bool {
    guard let requiredCapabilityVersion = session.capabilities[command.capability] else {
        return false
    }
    // COMPAT-01 / D-06: session (provides) >= request (demands) — floor semantics.
    return SemVer.compatible(
        provides: request.capabilities[command.capability],
        demands: requiredCapabilityVersion
    )
}
```

**Fix (Kotlin):** Extract a `capabilityAvailable` helper and replace the repeated `!= requiredCapabilityVersion` guards:

```kotlin
private fun capabilityAvailable(command: BridgeCommand, request: BridgeRequestEnvelope): Boolean {
    val required = session.capabilities[command.capability] ?: return false
    // COMPAT-01 / D-06: request (provides) >= session required (demands) — floor semantics.
    return SemVer.compatible(
        provides = request.capabilities[command.capability],
        demands = required
    )
}
```

Note: The direction must be verified carefully. In `BridgeChannel` the session holds what the manifest declares as the required version (the "floor"), and the request carries what the client says it has. So `provides = request.capabilities[id]`, `demands = session.capabilities[id]`. Confirm this matches Elixir's `available_version = Map.get(request.capabilities, capability_id)`, `required_version` from capability registry — yes, `provides` = request capabilities, `demands` = manifest/session capability version.

---

### CR-03: vec-012 and vec-013 manifest_schema_version floor vectors are phantom — neither native harness applies the override

**File (vectors source):** `lib/mix/tasks/crosswake.contract.gen.ex:262-278`
**File (iOS harness):** `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift:55-90`
**File (Android harness):** `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeConformanceTest.kt:70-122`

**Issue:** vec-012 sets `request_override: [{"manifest_schema_version", "1.0.0"}]` and `session_override: [{"manifest_schema_version", "2.0.0"}]`. Neither native test harness decodes `manifest_schema_version` from `request_override` or `session_override` — the field is silently discarded. Neither harness applies the field to any bridge call parameter. Because neither `BridgeRequestEnvelope` nor `LiveViewSession` has a `manifest_schema_version` field at the bridge layer (it lives in the activation manifest, not in bridge requests), the vectors probe a non-existent bridge-layer check. Both vec-012 and vec-013 will trivially pass as `"ok"` because the baseline permissive request goes through unmodified, but for the wrong reason: there is no `manifest_schema_version` check in `BridgeChannel.evaluate` at all.

The phase context marks these vectors `"native_only": true` but the vectors themselves are specified against the bridge-layer test harness, not the activation-layer harness. The `manifest_schema_version` floor belongs in `ActivationCoordinator.resolve`, not in `BridgeChannel.evaluate`. The vectors will pass with the wrong interpretation, creating false confidence that the manifest_schema floor is proven by the bridge conformance suite.

**Fix:** Either (a) remove vec-012/vec-013 from the bridge vectors file and add activation-layer floor vectors that drive `ActivationCoordinator.resolve` with a `manifest.nativeRuntimeVersion` or schema version override, or (b) keep them as documentation-only vectors with a comment that they are not exercisable at the bridge layer and add activation-layer tests separately. Do NOT leave them counted as proven floor vectors for the manifest_schema_version axis.

---

## Warnings

### WR-01: Kotlin `SemVer.compare` uses integer subtraction — wraps to wrong sign for pathological version numbers

**File:** `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/SemVer.kt:69`

**Issue:**

```kotlin
val diff = a[i] - b[i]
```

`Int` subtraction in Kotlin overflows silently at `Int.MAX_VALUE`. A version component of `2147483648` (exceeds `Int.MAX_VALUE`) parsed via `toIntOrNull()` returns `null` (safe — parse fails before compare). However a component of exactly `Int.MAX_VALUE` = `2147483647` compared to `0` produces `2147483647 - 0 = 2147483647` (correct). But `2147483647` compared to `-1` (which `toIntOrNull()` on a negative string would return) could produce wrong-sign results. More concretely: if someone feeds `"2147483648.0.0"`, `toIntOrNull()` returns `null` so `parse` returns `null` and the fallback fires. So in practice the parse guard prevents reaching the overflow. The real risk is two large components whose subtraction flips sign without parse returning null — e.g. `Int.MAX_VALUE` vs `1`: `2147483647 - 1 = 2147483646` (correct), `1 - 2147483647 = -2147483646` (correct). Integer overflow would require a component > `Int.MAX_VALUE` which `toIntOrNull()` rejects. The net risk is extremely low for version strings, but the pattern is fragile.

**Fix:** Use `a[i].compareTo(b[i])` instead of subtraction to avoid the overflow class entirely:

```kotlin
private fun compare(a: List<Int>, b: List<Int>): Int {
    for (i in 0..2) {
        val cmp = a[i].compareTo(b[i])
        if (cmp != 0) return cmp
    }
    return 0
}
```

---

### WR-02: `action_sequence_for` fallback clause returns a generic string when given an unknown class, silently masking future taxonomy drift

**File:** `lib/crosswake/doctor/publish_readiness.ex:795-797`

**Issue:**

```elixir
defp action_sequence_for(_unknown_class) do
  ["Consult guides/compatibility.md for upgrade guidance"]
end
```

`per_class_guidance_map/0` (line 801) calls `action_sequence_for` indirectly only for the `"native or companion rebuild required"` expansion — the other three classes get their action from `change_class_entries/0` via `SupportMatrix.change_classes/1`. But `action_sequence_for` is also called directly at line 687 with `detected_class || "native or companion rebuild required"`. If `detected_class` is not `nil` (drift detected) it will be `"native or companion rebuild required"` — so the `_unknown_class` clause can only be reached if called with a novel string. There is no test pinning the four canonical class names against `action_sequence_for` clauses. If a change class is renamed in the taxonomy, the fallback swallows it silently.

**Fix:** Add a guard that raises or logs a warning on unrecognized class strings, or add a clause that matches the `@change_class_keys` module attribute (the 4 canonical strings) to make the compiler enforce exhaustiveness on future renames:

```elixir
defp action_sequence_for(unknown_class) do
  require Logger
  Logger.warning("compatibility_rebuild_guidance: unknown change class #{inspect(unknown_class)} — falling back to generic guidance")
  ["Consult guides/compatibility.md for upgrade guidance"]
end
```

---

## Info

### IN-01: iOS and Android test harnesses silently skip `native_only: true` vectors without assertion or logging

**File (iOS):** `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift:180-209`
**File (Android):** `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeConformanceTest.kt:147-213`

**Issue:** Seven vectors (vec-008 through vec-017) carry `"native_only": true`. Neither harness reads or respects this field — they run all vectors through `BridgeChannel.evaluate` regardless. This is actually correct behavior for vec-008 through vec-011 and vec-016/vec-017 (which do exercise bridge-layer checks). However for vec-012/vec-013 (covered in CR-03) the absence of `native_only` filtering means a non-applicable vector runs and passes trivially without exercising the intended check. If future vectors are added that are genuinely inapplicable at the bridge layer (e.g. ActivationCoordinator-only), the harness will silently report them as passing.

**Fix:** Add a `native_only` field to the vector models and either assert `native_only == true` vectors are handled specially, or add a comment documenting that all bridge-layer vectors are expected to be runnable and `native_only` is metadata-only. Either way document the convention so future vector authors know what `native_only` means in the bridge suite context.

---

_Reviewed: 2026-06-20_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
