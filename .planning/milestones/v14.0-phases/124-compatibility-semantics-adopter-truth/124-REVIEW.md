---
phase: 124-compatibility-semantics-adopter-truth
reviewed: 2026-06-21T16:33:19Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - lib/mix/tasks/crosswake.contract.gen.ex
  - packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt
  - packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeConformanceTest.kt
  - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift
  - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift
  - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/ActivationConformanceTests.swift
  - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift
findings:
  critical: 0
  warning: 3
  info: 3
  total: 6
status: issues_found
---

# Phase 124: Code Review Report

**Reviewed:** 2026-06-21T16:33:19Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

This is the COMPAT-01 gap-closure diff (`c632c96..HEAD`). It converts native bridge
capability-version comparisons from exact `==`/`!=` to `>=` min-version-floor via
`SemVer.compatible`, and adds an iOS `ActivationCoordinator.resolve()` native-runtime
floor gate that mirrors the pre-existing Android gate. I verified the four primary
correctness axes the prompt called out, and all four pass on the dimensions that matter
most for shipping safety:

1. **Capability-axis direction is correct.** Both iOS (`BridgeChannel.swift:401`) and
   Kotlin (`BridgeChannel.kt:310`) call
   `compatible(provides = request.capabilities[...], demands = session.capabilities[...])`
   — provides=request, demands=session, the OPPOSITE of the bridge/runtime sites
   (provides=session) exactly as required for the capability axis.
2. **Fail-closed on nil/missing versions holds.** `capabilityAvailable` returns `false`
   when the session declares no version (`?: return false` / `guard let ... else return
   false`), and `SemVer.compatible` returns `false` for nil/empty `provides` or `demands`
   on both platforms (`SemVer.swift:20-24`, `SemVer.kt:25`).
3. **The iOS `ShellManifest.compatibility` decode does not break existing construction
   sites.** The only iOS construction site (`ActivationConformanceTests.swift:32`) was
   updated to pass `compatibility:`, and the only decoded manifest JSON
   (`examples/ios_shell_host/Fixtures/crosswake_manifest.json:349`) carries a
   `compatibility.native_runtime_version` key. No iOS test fixture lacks the key; a missing
   key fail-closes to a `.denied(.compatibilityMismatch)` via the `activate`/`bootstrap`
   catch.
4. **The `elixir_only` / `native_only` vector-skip logic is symmetric.** Native harnesses
   skip `elixir_only` and run `native_only`; the Elixir harness skips `native_only` and runs
   `elixir_only`. iOS and Android both skip on the same `elixir_only` flag. The three
   committed `bridge_contract_vectors.json` copies are byte-identical and the phantom
   `manifest_schema` vectors (vec-012/013) are removed consistently from all three.

The findings below are quality/robustness issues, not ship-blockers. The most important is
WR-01: vec-014 — the "DISCRIMINATING" capability-floor vector — is **not actually
discriminating in the Elixir harness**, contradicting the dual-coverage claim authored in
`crosswake.contract.gen.ex`. The floor proof holds only on native; the Elixir half is
vacuous on that dimension.

## Warnings

### WR-01: vec-014 capability-floor vector is non-discriminating (vacuous) in the Elixir harness, contradicting the in-file dual-coverage claim

**File:** `lib/mix/tasks/crosswake.contract.gen.ex:257-273` (comment at 257-263; vector at 264-273)
**Issue:**
The generator comment for the capability-floor vectors asserts:

> "capability-version floor — both directions / Exercised by both Elixir bridge_findings
> (`compatible_version?` on capability axis) and native."

vec-014 is intentionally NOT tagged `native_only` or `elixir_only`, so it runs in the Elixir
behavioral harness (`test/crosswake/bridge/bridge_behavioral_vector_test.exs:86`, out of
scope but the direct consumer of this generated file). Its discriminating property is that
the **request** provides capability `1.1.0` against a **session** floor of `1.0.0`
(`request_override.capabilities = {"app.info.get": "1.1.0"}`,
`session_override.capabilities = {"app.info.get": "1.0.0"}`), which yields `ok` under `>=`
but `deny` under the pre-fix `==`.

The Elixir `make_permissive_request/1` builder hardcodes request capabilities to
`%{"app_info" => "1.0.0"}` and never reads `request_override["capabilities"]`. It therefore
tests `1.0.0`-provides vs a `1.0.0` registry floor (the registry version is derived from
`session_override.capabilities["app.info.get"] = "1.0.0"`), which returns `ok` under BOTH
`==` and `>=`. The vector passes in Elixir but exercises none of its discriminating
dimension there. The generated `description` text ("returns ok under >= floor but would
return deny under the pre-fix == equality check, proving the floor is applied") is true only
on native; in Elixir the claim is false. This is exactly the vacuous-coverage failure mode
the phase set out to eliminate (anti-vacuous behavioral proof, D-09).

**Fix:** Either (a) tag vec-014 `native_only: true` so the Elixir suite stops implicitly
claiming to prove a floor it does not exercise, and rely on the native suites for the
capability-floor discrimination; or (b) teach the Elixir harness to honor
`request_override["capabilities"]` (translating the command key to the registry
capability_id) so the `1.1.0`-provides path is genuinely run; or (c) soften the generated
comment/description so it does not assert Elixir coverage of the floor.

```elixir
# Option (a), in crosswake.contract.gen.ex vec-014:
{"request_override",
 [{"capabilities", [{"app.info.get", "1.1.0"}]}, {"capability", "app.info.get"},
  {"command", "app.info.get"}, {"version", bridge_vsn}]},
{"session_override", [{"capabilities", [{"app.info.get", "1.0.0"}]}]},
{"expected_outcome", "ok"},
{"expected_denial_reason", nil},
{"native_only", true}   # <-- add; Elixir cannot discriminate this vector as built
```

### WR-02: Android pack-requirement parser diverges from iOS on a malformed `pkg@` (empty version) requirement

**File:** `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt:127-133` (iOS counterpart `BridgeChannel.swift:210-216`)
**Issue:**
The pack-requirement parser splits on `"@"`. For a malformed requirement such as
`"test-pack@"` (trailing `@`, empty version), Android computes
`requiredVersion = parts.getOrNull(1) = ""` (empty string, non-null), then calls
`SemVer.compatible(provides = installedVersion ?: "", demands = "")`. `SemVer.compatible`
treats an empty `demands` as fail-closed `false`, so any route declaring `"test-pack@"`
becomes permanently `pack_incompatible` even when the pack is installed. iOS uses
`split(separator: "@", maxSplits: 1)`, which drops the trailing empty component, yielding
`parts.count == 1` → `requiredVersion = nil` → the "present, any version" branch
(`installedVersion != nil`). The two platforms therefore disagree on identical malformed
manifest input. Not exercised by any current vector, so latent, but a real cross-platform
divergence in security-relevant deny logic.

**Fix:** Normalize the empty-version case on Android to match iOS:

```kotlin
val requiredVersion = parts.getOrNull(1)?.takeIf { it.isNotBlank() }
val installedVersion = session.installedPacks[packId]
if (requiredVersion == null) installedVersion != null
else SemVer.compatible(provides = installedVersion ?: "", demands = requiredVersion)
```

### WR-03: `SemVer.compatible` unparseable-version fallback can silently ALLOW identical garbage, undercutting the "fail-closed" label

**File:** `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/SemVer.swift:26-29` and `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/SemVer.kt:28-33`
**Issue:**
When either version string fails to parse to three numeric components, both ports fall back
to raw `==` (`provides == demands`). The doc-comment frames this as "fail-closed," but it is
only fail-closed for *mismatched* garbage; for *identical* garbage it returns `true` (allow).
Example: `compatible(provides: "latest", demands: "latest")` → `true`. For a floor
comparison this is wrong — an unparseable provided version should never satisfy a floor. The
risk is bounded today because all version inputs flow from generated fixtures and the
canonical Elixir contract (well-formed semver), but a future manifest authoring mistake would
be silently ALLOWED rather than denied. This mirrors the pre-existing Elixir fallback
(`available == required`), so it is intentional parity, but the "fail-closed" labeling
overstates the guarantee.

**Fix:** Deny unconditionally on the unparseable path for the floor semantics, or restrict
the raw-`==` allow to the bridge-protocol exact-identity axis only:

```swift
guard let pComponents = parse(normalize(p)),
      let dComponents = parse(normalize(d)) else {
    return false   // unparseable provided/demanded version cannot satisfy a floor
}
```

If exact string-equality parity with Elixir's fallback must be preserved, document
explicitly that identical-but-unparseable strings ALLOW, so the "fail-closed" doc-comment
is not relied upon by future readers.

## Info

### IN-01: iOS and Android expose different wire command strings for the connection/state-update seam

**File:** `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift:19` vs `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt:21`
**Issue:** iOS declares `case connectionStateUpdate = "connection.state.update"` while
Android declares `SERVER_STATE_UPDATE("server.state.update")`. Not part of the 124-06 diff,
and not exercised by any conformance vector, so invisible to the suite. Flagging because the
phase premise is cross-platform contract parity; a future vector covering state updates would
surface this as a hard divergence.
**Fix:** Confirm the canonical wire value in `Crosswake.Bridge.Contract.commands()`, align
both platforms, and add a conformance vector asserting the command is recognized.

### IN-02: Generated-JSON idempotency depends on an unguarded BEAM "small map < 32 keys" assumption

**File:** `lib/mix/tasks/crosswake.contract.gen.ex:345-359`
**Issue:** The encoder pre-sorts pairs and routes through `Map.new/1`, relying on BEAM's
small-map insertion-order stability for deterministic key order (and thus
`write_if_changed/2` no-churn). The comment is candid about this, but no object is asserted
to stay under 32 keys. If a future axis pushes a generated object to ≥32 keys, the three
committed vector copies will churn on every `mix crosswake.contract.gen` run and the
generate-and-diff CI gate will flap. Maintainability landmine, not a current defect.
**Fix:** Add an encoder guard that raises if any object reaches 32 keys (forcing a move to an
explicitly-ordered encoding), or encode the pre-sorted pairs list directly without
round-tripping through `Map.new/1`.

### IN-03: iOS `SessionOverride.installed_packs` decode swallows all errors via a `try?` type probe

**File:** `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift:105-109`
**Issue:** The decoder probes `installed_packs` as `[String]` with `try?` to distinguish the
empty-array form from the object form, swallowing all errors. If a future vector encodes
`installed_packs` with the wrong value type (e.g. version as Int) the probe silently yields
`installedPacks = nil` ("no packs installed") instead of failing the test, masking a
malformed fixture. Test-only, low impact, but weakens the suite's ability to catch bad
vectors.
**Fix:** Decode `installed_packs` explicitly against the two known JSON shapes and let an
unexpected shape throw (fail the test) rather than degrade to nil.

---

_Reviewed: 2026-06-21T16:33:19Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
