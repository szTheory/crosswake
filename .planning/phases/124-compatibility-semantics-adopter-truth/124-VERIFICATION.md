---
phase: 124-compatibility-semantics-adopter-truth
verified: 2026-06-20T18:00:00Z
status: gaps_found
score: 4/5
behavior_unverified: 0
overrides_applied: 0
re_verification: false
gaps:
  - truth: "Native bridge code negotiates by >= min-version-floor rather than exact equality, matching compatible_version?/2, for ALL version axes including capability-version"
    status: failed
    reason: "CR-01 (iOS ActivationCoordinator missing nativeRuntimeVersion gate) and CR-02 (capability-version still uses exact == in both native platforms) are CONFIRMED unfixed in the live codebase. These are D-06-scoped items and direct COMPAT-01 requirements."
    artifacts:
      - path: "packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift:401"
        issue: "capabilityAvailable() returns `request.capabilities[command.capability] == requiredCapabilityVersion` — exact equality, not SemVer.compatible floor"
      - path: "packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt:142,156,172,194,213,228"
        issue: "Six per-command capability checks use `request.capabilities[command.capability] != requiredCapabilityVersion` — exact equality, not SemVer.compatible floor"
      - path: "packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift:333"
        issue: "resolve(request:manifest:) has ZERO SemVer.compatible calls; no nativeRuntimeVersion gate. Android ActivationCoordinator.kt:333 has this gate; iOS does not. D-03 names both as required fix sites."
    missing:
      - "iOS BridgeChannel.swift capabilityAvailable(): replace `request.capabilities[command.capability] == requiredCapabilityVersion` with `SemVer.compatible(provides: request.capabilities[command.capability], demands: requiredCapabilityVersion)`"
      - "Android BridgeChannel.kt: extract capabilityAvailable helper and replace 6x `!= requiredCapabilityVersion` guards with SemVer.compatible(provides = request.capabilities[command.capability], demands = required)"
      - "iOS ActivationCoordinator.swift resolve(): add guard SemVer.compatible(provides: manifest.nativeRuntimeVersion, demands: request.nativeRuntimeVersion) at the top, mirroring Android ActivationCoordinator.kt:333"
      - "CR-03 phantom vectors: vec-012 and vec-013 (manifest_schema_version floor) pass trivially because neither native harness decodes or applies manifest_schema_version to any bridge call — these are not proven floor vectors"
      - "Capability floor conformance vectors (vec-014 allow, vec-015 deny) do NOT prove floor semantics: vec-014 sets session.capabilities[app.info.get]=1.0.0 and request.capabilities default to 1.0.0 — equality happens to pass; the distinguishing case (session=1.1.0, request demands 1.0.0) is never tested with the exact-match code still in place"
---

# Phase 124: Compatibility Semantics & Adopter Truth — Verification Report

**Phase Goal:** The bridge-protocol compatibility check uses `>=` min-version-floor semantics across both Elixir and native, eliminating the exact-equality denial footgun; adopters have a clear decision table mapping each version-axis change to its rebuild requirement; doctor output names the full action sequence when a mismatch is detected.

**Verified:** 2026-06-20T18:00:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

---

## Step 0: Previous Verification

No prior VERIFICATION.md found. Proceeding as initial verification.

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Native bridge code negotiates by `>=` floor for bridge_protocol + native_runtime + pack-version axes in BridgeChannel | PARTIALLY VERIFIED | BridgeChannel.swift:182-183,215 and BridgeChannel.kt:102-103,132 all use SemVer.compatible — confirmed in live code |
| 1b | Native capability-version checks use `>=` floor (D-06 scope) | FAILED (BLOCKER) | BridgeChannel.swift:401 uses `==`; BridgeChannel.kt:142,156,172,194,213,228 use `!=` — six exact-equality sites confirmed unfixed |
| 1c | iOS ActivationCoordinator gates nativeRuntimeVersion via SemVer floor (D-03 site 4) | FAILED (BLOCKER) | ActivationCoordinator.swift:333 `resolve()` has 0 SemVer.compatible calls; no native_runtime gate at all. Android correctly has gate at ActivationCoordinator.kt:333. |
| 1d | Floor conformance vectors prove allow+deny for every floored axis through both native check sites | FAILED (BLOCKER) | vec-012/013 (manifest_schema) are phantom — native harnesses do not decode manifest_schema_version. vec-014 (capability allow) passes by equality coincidence, not floor semantics. |
| 2 | Each version axis mapped to rebuild class in one committed source, guarded by docs-contract test | VERIFIED | rebuild_decision_table/0 in support_matrix.ex (11 rows, D-09 mapping); phase52 byte-parity guard present at line 161; 6 phase52 tests pass |
| 3 | support_matrix.md and guides/compatibility.md lead with decision table before prose; machine-tested | VERIFIED | compatibility.md line 3: `## Do I need to rebuild? (start here)` at byte 200; prose sentinel at byte 3854; 6 compatibility_test.exs tests pass; support_matrix.md line 133 has `## Rebuild Decision Table` |
| 4 | Doctor output names change class + full action sequence + denial reason + guide link | VERIFIED | publish_readiness.ex:696-722 names change class in message, ordered 4-step sequence (1-4), denial_vocabulary, docs_reference: guides/compatibility.md |
| 5 | CHANGELOG entries carry an upgrade-impact label | VERIFIED | CHANGELOG.md lines 35 and 64 have `### Upgrade Impact`; release_boundaries_test.exs structural + vocabulary tests pass (8 tests, 0 failures) |

**Score: 4/5 truths verified** (Truth 1 partially — 3 sub-truths FAIL constitute COMPAT-01 gaps)

---

## Critical Targeted Check Results (per Orchestrator brief)

### Check (a) — Capability-version exact `==` in native: CONFIRMED GAP

**iOS `BridgeChannel.swift:396-401`:**

```swift
private func capabilityAvailable(for command: BridgeCommand, request: BridgeRequestEnvelope) -> Bool {
    guard let requiredCapabilityVersion = session.capabilities[command.capability] else {
        return false
    }
    return request.capabilities[command.capability] == requiredCapabilityVersion  // EXACT ==, not floor
}
```

`capabilityAvailable` is called at lines 223, 236, 251, 270, 324, 338 — six call sites, all routing through the exact-equality check.

**Android `BridgeChannel.kt:142,156,172,194,213,228`:**

Six per-command blocks use `request.capabilities[command.capability] != requiredCapabilityVersion` — exact inequality, not `!SemVer.compatible(...)`. Elixir's `compatibility.ex:585` uses `compatible_version?(available_version, required_version)` which is `>=` floor. The D-06 "clean sweep" of every native exact-match was NOT completed for capability-version. Verdict: **BLOCKER — COMPAT-01 not satisfied for capability axis.**

### Check (b) — iOS ActivationCoordinator nativeRuntimeVersion gate: CONFIRMED MISSING

`ActivationCoordinator.swift resolve(request:manifest:)` at line 333 has NO `SemVer.compatible` call (confirmed: `grep -c "SemVer.compatible" ActivationCoordinator.swift` → 0). The first check is `route(for: request, manifest: manifest)` — no version floor gate precedes it.

Android `ActivationCoordinator.kt:333` correctly has:
```kotlin
if (!SemVer.compatible(provides = manifest.nativeRuntimeVersion, demands = request.nativeRuntimeVersion))
```

The SUMMARY documents this as intentional ("iOS routes its native-runtime floor through BridgeChannel only"). However, the code review (CR-01) disagreed: a request demanding a newer native runtime than the installed shell provides can proceed to session creation on iOS when routed through `ActivationCoordinator.resolve()`, since BridgeChannel only runs after a session is live. D-03 explicitly names `ActivationCoordinator.swift` as a required fix site. Verdict: **BLOCKER — iOS/Android parity gap, not an acceptable omission per D-03.**

**Note on the SUMMARY justification:** The claim "iOS routes its native-runtime floor through BridgeChannel only" does NOT hold architecturally — ActivationCoordinator.resolve runs during route activation before BridgeChannel.evaluate is ever called. A missing gate here means iOS would activate a session that Android would deny at this stage.

### Check (c) — Pack-version floored in native: CONFIRMED FIXED

- iOS `BridgeChannel.swift:215`: `SemVer.compatible(provides: installedVersion ?? "", demands: requiredVersion!)` — floor semantics confirmed.
- Android `BridgeChannel.kt:132`: `SemVer.compatible(provides = installedVersion ?: "", demands = requiredVersion)` — floor semantics confirmed.

**Verdict: PASS for pack-version floor.**

### Check (d) — Capability/pack floor conformance vectors: PARTIALLY PHANTOM

**vec-014 (capability allow) — NOT a floor-semantics proof:**

- `session_override.capabilities["app.info.get"] = "1.0.0"`
- `makeRequest` hardcodes `requestCapabilities = ["app.info.get": "1.0.0"]` (line 154)
- Actual evaluation: `request.capabilities["app.info.get"] == "1.0.0"` vs `requiredCapabilityVersion = "1.0.0"` → **equality holds** → allow
- This passes even with the exact `==` still in place. It does NOT prove floor semantics. The distinguishing scenario (session capability = "1.1.0", request demands "1.0.0") is not tested.

**vec-015 (capability deny) — correctly models deny but also passes with exact equality:**

- `session_override.capabilities["app.info.get"] = "2.0.0"`, `request.capabilities["app.info.get"] = "1.0.0"` (default)
- Both `SemVer.compatible("1.0.0", "2.0.0")` AND `"1.0.0" != "2.0.0"` produce deny — the exact-match code produces the same result

**vec-012/013 (manifest_schema floor) — PHANTOM per CR-03:**

Neither native harness decodes `manifest_schema_version` from `request_override` or `session_override`. There is no `manifest_schema_version` field in `BridgeRequestEnvelope` or `LiveViewSession`. These vectors pass trivially without testing any bridge code path for manifest_schema floor.

**Pack floor vectors (vec-016, vec-017) — FUNCTIONAL:** Native harnesses decode `installed_packs` and `route_required_packs` from session_override and these are applied to `SemVer.compatible` in the fixed pack check. Pack floor IS behaviorally proven.

**Bridge/runtime floor vectors (vec-008 through vec-011) — FUNCTIONAL:** Session overrides for `bridge_protocol_version` and `native_runtime_version` are applied by both harnesses (SUMMARY documents harness extensions). These pass through the fixed `SemVer.compatible` calls at BridgeChannel.swift:182-183 and BridgeChannel.kt:102-103.

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `SemVer.swift` | Hand-ported floor helper | VERIFIED | 64 LOC, normalize + tri-state + fail-closed, 0 third-party deps |
| `SemVer.kt` | Hand-ported floor helper | VERIFIED | 74 LOC, normalize + compare + fail-closed; WR-01: subtraction overflow risk (minor, not blocker) |
| `BridgeChannel.swift` | bridge+runtime+pack floored via SemVer | PARTIAL | bridge+runtime+pack floored at lines 182-183,215; capability still exact == at line 401 |
| `BridgeChannel.kt` | bridge+runtime+pack floored via SemVer | PARTIAL | bridge+runtime+pack floored at lines 102-103,132; 6 capability checks still exact != at lines 142-228 |
| `ActivationCoordinator.kt` | nativeRuntimeVersion floored via SemVer | VERIFIED | Line 333: `!SemVer.compatible(provides = manifest.nativeRuntimeVersion, demands = request.nativeRuntimeVersion)` |
| `ActivationCoordinator.swift` | nativeRuntimeVersion floored via SemVer | FAILED | No SemVer.compatible calls at all; no version gate in resolve() |
| `test/fixtures/bridge_contract_vectors.json` | Floor vectors (allow+deny per axis) | PARTIAL | 20 occurrences of "floor"; vec-012/013 phantom; vec-014 not proving floor; vec-008-011,016-017 functional |
| `lib/crosswake/support_matrix/support_matrix.ex` | rebuild_decision_table/0 (11 rows) | VERIFIED | Public def, 11 rows, D-09 mapping confirmed |
| `lib/crosswake/support_matrix/renderer.ex` | Rebuild Decision Table section | VERIFIED | rebuild_decision_table_section/1 present, wired in render/1 |
| `guides/support_matrix.md` | ## Rebuild Decision Table section | VERIFIED | Line 133 confirmed |
| `test/crosswake/proof/phase52_operator_truth_test.exs` | assert_contains_exact for Rebuild Decision Table | VERIFIED | Line 161 confirmed |
| `guides/compatibility.md` | Decision table leads guide (JTBD first) | VERIFIED | `## Do I need to rebuild? (start here)` at line 3, byte 200 |
| `test/crosswake/guides/compatibility_test.exs` | 6 docs-contract tests | VERIFIED | 6 tests, 0 failures: ordering, mirror, axes, asymmetry, no-second-matrix, count-once |
| `lib/crosswake/doctor/publish_readiness.ex` | compatibility_rebuild_guidance_check | VERIFIED | Lines 683-744; action_sequence_for/1; contract_version_parity_errors/1 extracted |
| `CHANGELOG.md` | ### Upgrade Impact in each release | VERIFIED | Lines 35 and 64 confirmed |
| `CONTRIBUTING.md` | Human intent-gate convention | VERIFIED | Created with 4-class table + worst-case-wins rule |
| `test/crosswake/guides/release_boundaries_test.exs` | Structural + vocabulary Upgrade Impact tests | VERIFIED | 8 tests, 0 failures (6 pre-existing + 2 new) |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| BridgeChannel.swift:182-183 | SemVer.swift | SemVer.compatible(provides:demands:) | VERIFIED | bridge+runtime floored |
| BridgeChannel.swift:215 | SemVer.swift | SemVer.compatible(provides:installedVersion??…,demands:) | VERIFIED | pack version floored |
| BridgeChannel.swift:396-401 | SemVer.swift | capabilityAvailable() — MISSING LINK | FAILED | Still uses `==` raw equality |
| ActivationCoordinator.swift:333 | SemVer.swift | SemVer.compatible() in resolve() | FAILED | No call exists (0 calls confirmed) |
| BridgeChannel.kt:102-103 | SemVer.kt | SemVer.compatible(provides=…,demands=…) | VERIFIED | bridge+runtime floored |
| BridgeChannel.kt:132 | SemVer.kt | SemVer.compatible for pack | VERIFIED | pack version floored |
| BridgeChannel.kt:142-228 | SemVer.kt | capability checks — MISSING LINK | FAILED | 6 sites still use `!=` exact equality |
| ActivationCoordinator.kt:333 | SemVer.kt | SemVer.compatible(provides=manifest.nativeRuntimeVersion,…) | VERIFIED | Correctly wired |
| compatibility_rebuild_guidance_check | contract_version_parity_errors/1 | Shared detector extracted at line 627 | VERIFIED | Anti-disagreement guarantee holds |
| Renderer.render/1 | rebuild_decision_table/0 | rebuild_decision_table_section/1 called in render/1 | VERIFIED | Phase52 byte-parity guard auto-covers |
| compatibility.md table | Renderer.render(canonical()) | Mirror assertion in compatibility_test.exs test 2 | VERIFIED | 4 class strings asserted in both |

---

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| BridgeChannel.swift capability check uses exact == | `grep -n "== requiredCapabilityVersion" BridgeChannel.swift` | Line 401 found | FAIL — exact equality present |
| iOS ActivationCoordinator has no SemVer.compatible | `grep -c "SemVer.compatible" ActivationCoordinator.swift` | 0 | FAIL — missing gate |
| Android ActivationCoordinator has SemVer floor gate | `grep -c "SemVer.compatible" ActivationCoordinator.kt` | 1 | PASS — gate confirmed |
| BridgeChannel.kt capability uses exact != | `grep -c "!= requiredCapabilityVersion" BridgeChannel.kt` | 6 | FAIL — 6 exact-equality sites |
| Pack-version floor wired in iOS | `grep "SemVer.compatible.*installedVersion" BridgeChannel.swift` | Line 215 | PASS |
| Pack-version floor wired in Android | `grep "SemVer.compatible.*installedVersion" BridgeChannel.kt` | Line 132 | PASS |
| Floor vectors exist in JSON | `grep -c floor test/fixtures/bridge_contract_vectors.json` | 20 | PARTIAL (phantom vec-012/013; vec-014 proves equality not floor) |
| Doctor check named in build_checks | `grep -n "compatibility_rebuild_guidance_check" publish_readiness.ex` | Line 175 | PASS |
| CHANGELOG Upgrade Impact count | `grep -c "### Upgrade Impact" CHANGELOG.md` | 2 | PASS |

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `BridgeChannel.swift` | 401 | `== requiredCapabilityVersion` exact equality | BLOCKER | Capability-version floor not implemented (D-06 gap) |
| `BridgeChannel.kt` | 142,156,172,194,213,228 | `!= requiredCapabilityVersion` exact equality | BLOCKER | Same D-06 gap on Android — 6 sites |
| `ActivationCoordinator.swift` | 333 | No SemVer.compatible call in resolve() | BLOCKER | iOS/Android parity gap; valid denial missing on iOS activation path |
| `SemVer.kt` | 69 | `val diff = a[i] - b[i]` integer subtraction | WARNING (WR-01) | Theoretical overflow risk; practically guarded by toIntOrNull() parse, but fragile pattern |
| `publish_readiness.ex` | 795-797 | `action_sequence_for(_unknown_class)` silent fallback | WARNING (WR-02) | Future taxonomy rename silently degrades to generic message with no error |
| `bridge_contract_vectors.json` | vec-012,vec-013 | manifest_schema floor vectors | BLOCKER | Phantom: neither native harness applies manifest_schema_version to any bridge call |
| `bridge_contract_vectors.json` | vec-014 | capability allow vector | WARNING | Does not distinguish floor from equality (both 1.0.0) |

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|---------|
| COMPAT-01 | 124-01-PLAN.md | >= floor semantics across Elixir AND native for all axes | PARTIAL — BLOCKED | bridge/runtime/pack axes floored; capability axis still exact == in both native platforms; iOS ActivationCoordinator gate missing |
| COMPAT-02 | 124-02-PLAN.md | Each version axis mapped to rebuild class in one source, guarded by docs-contract test | SATISFIED | rebuild_decision_table/0 (11 rows), phase52 byte-parity guard wired |
| COMPAT-03 | 124-03-PLAN.md | support matrix + compatibility guide lead with decision table | SATISFIED | compatibility.md restructured decision-table-first; 6 compatibility_test.exs tests pass |
| COMPAT-04 | 124-04-PLAN.md | Doctor names change class + action sequence + denial reason + guide link | SATISFIED | compatibility_rebuild_guidance_check names class in message, 4-step sequence, denial_vocabulary, docs_reference |
| COMPAT-05 | 124-05-PLAN.md | Changelog upgrade-impact label per release | SATISFIED | 2x `### Upgrade Impact` in CHANGELOG.md; vocabulary+structural tests in release_boundaries_test.exs |

---

## Gaps Summary

The phase achieves COMPAT-02 through COMPAT-05 cleanly. The critical failure is **COMPAT-01**, specifically the D-06 scope: "a clean sweep of EVERY native exact-match version footgun."

Three concrete blockers prevent goal achievement:

**Blocker 1 — Capability-version axis not floored (iOS and Android):**
- `BridgeChannel.swift:401`: `capabilityAvailable()` still uses `request.capabilities[command.capability] == requiredCapabilityVersion`. This is called 6 times per bridge request.
- `BridgeChannel.kt:142,156,172,194,213,228`: Six per-command blocks use `!= requiredCapabilityVersion`.
- Elixir `compatibility.ex:585` floors capability version via `compatible_version?`. Native does not.
- Practical impact: a shell with capability version 1.1.0 will deny a request demanding 1.0.0 (the exact footgun the phase was meant to eliminate, on the capability axis).

**Blocker 2 — iOS ActivationCoordinator nativeRuntimeVersion gate is absent:**
- `ActivationCoordinator.swift:333` `resolve()` has zero SemVer.compatible calls.
- Android `ActivationCoordinator.kt:333` correctly gates `!SemVer.compatible(provides = manifest.nativeRuntimeVersion, demands = request.nativeRuntimeVersion)`.
- D-03 names iOS ActivationCoordinator as one of four required fix sites. The SUMMARY's claim that "iOS routes its native-runtime floor through BridgeChannel only" is incorrect: ActivationCoordinator.resolve runs during route activation before BridgeChannel.evaluate; a missing gate here creates a real iOS/Android behavioral parity gap.

**Blocker 3 — Phantom floor conformance vectors for manifest_schema and capability axes:**
- vec-012/013 (manifest_schema floor): neither native harness decodes `manifest_schema_version` from session/request overrides; the vectors exercise no code and pass trivially.
- vec-014 (capability allow): `makeRequest` hardcodes `requestCapabilities = ["app.info.get": "1.0.0"]`; session override also sets `"1.0.0"`. Equality check passes by coincidence (1.0.0 == 1.0.0). The scenario distinguishing floor from equality — session provides "1.1.0", request demands "1.0.0" — is not tested. With the exact `==` still in BridgeChannel, this vector cannot detect the bug.

**Recommended minimal fix set for re-planning:**
1. iOS BridgeChannel.swift: Replace `capabilityAvailable()` body to use `SemVer.compatible(provides: request.capabilities[command.capability], demands: requiredCapabilityVersion)`.
2. Android BridgeChannel.kt: Extract `capabilityAvailable` helper; use `SemVer.compatible(provides = request.capabilities[command.capability], demands = required)` for all 6 commands.
3. iOS ActivationCoordinator.swift `resolve()`: Add SemVer floor guard at top (mirror Android ActivationCoordinator.kt:333).
4. bridge_contract_vectors.json: Fix vec-014 to set session.capabilities["app.info.get"] = "1.1.0" so the allow case requires floor (not just equality). Remove or re-scope vec-012/013 (no bridge-layer manifest_schema_version check exists to test); if desired, add activation-layer floor vectors covering manifest_schema at ActivationCoordinator.

---

_Verified: 2026-06-20T18:00:00Z_
_Verifier: Claude (gsd-verifier)_
