# Project Research Summary

**Project:** Crosswake v4.0 Production Shell Runtime Line
**Domain:** Production hardening of checked-in iOS/Android shells for a Phoenix-native OSS library (route-policy-first hybrid runtime)
**Researched:** 2026-06-03
**Confidence:** HIGH

## Executive Summary

v4.0 hardens Crosswake's existing checked-in iOS/Android shells into a documented, proof-backed production runtime line. It is not new product surface — it is honest contracts, generated host-owned templates, a diagnostics seam, and CI/verification closure layered onto surfaces that already exist (route policy, manifest/compatibility contract, bounded bridge, capability registry, `mix crosswake.doctor`, generated `SupportMatrix`, operator inspection, Sigra auth, Chimeway notification seam). All four researchers converged on the same structural insight: **no new hex dependencies, no manifest schema bump, and no bridge vocabulary expansion.** The entire milestone is new Elixir modules plus extensions to Doctor/SupportMatrix, EEx-generated native templates in `examples/`, and a two-lane CI proof split (hermetic merge-blocking + advisory emulator/device) following the established v3.2–v3.9 pattern.

The recommended approach is contracts-and-support-truth first, then the diagnostics seam, then generator templates (plus the Apple Xcode 26 CI fix), then the iOS shell, then the Android shell with JVM proof, and finally CI/Android verification closure with support-truth promotion. Rebuild policy is **derived from the existing `compatibility.native_runtime_version` axis** rather than a new manifest field — adding a field would force a `manifest_schema_version` bump and break every deployed shell. Diagnostics export is a fire-and-forget HTTP POST to a host-owned endpoint (the Chimeway pattern), not a bridge command, preserving the bounded-bridge thesis.

The dominant risk is not technical difficulty — it is **support-truth dishonesty**. JVM-CI-only Android evidence must never be claimed as device-verified; Android stays `:verification_required` until hermetic JVM proof passes and explicit promotion criteria (emulator/device evidence + device-UAT checklist) are met. Three surfaces — manifest, shell native files, and docs — must stay parity-locked via a machine-checkable docs-contract test that ships *with* the compatibility matrix, not after. Platform-policy hard gates current in 2026 (Apple Xcode 26 SDK mandate, Apple OTA Guideline 2.5.2, `PrivacyInfo.xcprivacy`, Google Play `targetSdkVersion ≥ 35`, SafetyNet death → Play Integrity) are concrete, enforced, and must be reflected in templates and CI.

## Key Findings

### Recommended Stack

**No new hex.pm dependencies.** All Elixir work is new modules (`Crosswake.RuntimeLine`, `Crosswake.Shell.DiagnosticExport`) and extensions to existing `Doctor` / `SupportMatrix`, using stdlib EEx, `jason`, and `nimble_options` already in the dependency graph. Native diagnostics use platform stdlib only — no third-party SDK surface. See `STACK.md`.

**Core technologies:**
- **EEx + `mix crosswake.gen.shell`** (existing): generate host-owned permission/entitlement + runtime-line templates — same proven mechanism used for all shell files since v1.
- **iOS `MetricKit`** (Apple stdlib, iOS 14+; `MXCrashDiagnostic.jsonRepresentation()` iOS 15+): crash/diagnostic export with zero SPM dependency.
- **Android `ApplicationExitInfo`** (API 30 stdlib, `getHistoricalProcessExitReasons()`): typed exit records — requires `minSdk 26 → 30` (safe; API 30 = Android 11).
- **Build version bumps** (one-line each): AGP `8.4.1 → 8.5.1`, Kotlin `1.9.24 → 2.0.21` (K2), Gradle wrapper `→ 8.11.1`, `compileSdk 35` / `targetSdk 35`.
- **Apple Xcode 26 SDK** in iOS CI (hard mandate since 2026-04-28).
- **`ReactiveCircus/android-emulator-runner@v2.36.0`** on `macos-15`, `api-level 35`, `aosp_atd`, `continue-on-error: true` — advisory lane only.

**What NOT to add:** no standalone/publishable shell packages, no JS-framework abstraction, no broad native SDKs, no first-party crash reporter, no new high-frequency bridge surface, no new manifest JSON field, SafetyNet (dead — use Play Integrity).

### Expected Features

All five v4.0 feature areas are P1 table stakes for a credible shell runtime line. See `FEATURES.md`.

**Must have (table stakes):**
- **Native runtime-line policy** — explicit OTA-safe vs. rebuild-required classification per change class (bridge schema change, capability family add, permission add, entitlement add, SDK floor bump, privacy-manifest entry, push capability change, URL-scheme change).
- **Rebuild & compatibility matrix** — projected through `SupportMatrix` + doctor; expresses which shell version supports which manifest/capability surface.
- **Permission/entitlement templates** — host-owned generated scaffolds with `ADOPT:`/`# HOST OWNED` markers; **`PrivacyInfo.xcprivacy` (`NSPrivacyAccessedAPITypes`)** is a hard App Store gate since May 2024 and the highest-complexity item.
- **Crash/diagnostic export seam** — fire-and-forget HTTP POST to a host-owned endpoint with layer attribution (native/web/bridge) and the v3.9 redaction allowlist.
- **Android verification closure** — hermetic JVM (merge-blocking) + advisory emulator/device + device-UAT checklist with honest CI-provable / device-advisory / provider-advisory columns.

**Should have (competitive):**
- Doctor placeholder/drift checks (un-replaced template text, manifest↔shell↔docs disagreement).
- Capability-registry ↔ device-UAT-checklist parity test so the checklist can't go stale.

**Defer (later milestones):** standalone shell packages, broad native breadth, first-party push delivery, emulator/device lanes promoted to merge-blocking.

### Architecture Approach

Every v4.0 feature attaches to an existing surface; no new high-frequency bridge or standalone-package coupling is introduced. Rebuild policy is derived at evaluation time from the existing `Compatibility` `native_runtime_version` axis (no new manifest field). Permission/entitlement templates are commented scaffold stubs from `gen.shell`, parity-locked to capability families with `rebuild: :native_required` via a new doctor check — the library never emits actual entitlement values (bundle IDs, provisioning profiles are host-owned). Diagnostic export is an HTTP seam mirroring Chimeway token registration, not bridge vocabulary. See `ARCHITECTURE.md`.

**Major components:**
1. **`Crosswake.RuntimeLine` / `RebuildPolicy`** (new Elixir) — OTA-safe vs. rebuild-required derivation; feeds doctor + support matrix.
2. **`SupportMatrix.runtime_line_truth/0` + doctor checks** (extend existing) — compatibility matrix projection and evidence-taxonomy truth (`:jvm_hermetic` vs. `:device_verified`).
3. **`Crosswake.Shell.DiagnosticExport`** (new Elixir) — envelope schema + redaction allowlist for the HTTP diagnostics seam.
4. **`gen.shell` template additions** (extend existing) — permission/entitlement + runtime-line EEx scaffolds with placeholder/drift doctor checks.
5. **iOS/Android shell readers + diagnostics** (`RuntimeLinePolicyReader`, `DiagnosticExport` in Swift/Kotlin, `examples/` proof artifacts).
6. **CI two-lane proof + docs-contract parity test** — hermetic merge-blocking, advisory emulator/device, manifest↔shell↔docs↔doctor parity gate.

### Critical Pitfalls

Full detail in `PITFALLS.md`.

1. **Support-truth dishonesty (#1 risk)** — never claim JVM-CI evidence as device-verified. Lock the `:jvm_hermetic` vs. `:device_verified` taxonomy first, before populating any matrix; Android stays `:verification_required` until promotion criteria met.
2. **Three-surface drift (manifest / shell native files / docs)** — no single test locks them today. Ship a docs-contract parity test reading from a canonical code-side record *with* the compatibility-matrix phase.
3. **Platform-policy hard gates** — Apple Xcode 26 SDK (since 2026-04-28), OTA Guideline 2.5.2 (a bridge command calling a native function absent at review time is not OTA-safe), Google Play `targetSdkVersion ≥ 35`, SafetyNet dead (use Play Integrity with a CI debug-provider escape hatch). Bake into templates + CI, not docs prose.
4. **Permission/entitlement template drift & overreach** — templates must stay parity-locked to declared capabilities and must never write host-owned native files; `PrivacyInfo.xcprivacy` must be generated correctly (App Store rejection otherwise).
5. **Diagnostics PII/token leak** — the crash/diagnostic seam is the likeliest leak vector; reuse the v3.9 Chimeway/Sigra redaction allowlist (no raw tokens, payloads, route params, PII) with an explicit, tested allowlist defined before any export code is written.

## Implications for Roadmap

Suggested seven-area structure (contracts-first, proof-always). The roadmapper continues phase numbering from v3.9 (last phase was 63, so v4.0 begins at Phase 64).

### Phase A: Runtime-Line Policy Contract & Support-Truth Taxonomy
**Rationale:** Everything downstream depends on locking the evidence taxonomy (`:jvm_hermetic` vs. `:device_verified`), the OTA-safe vs. rebuild-required change classification, and the `targetSdkVersion` floor rule — before any claim is populated.
**Delivers:** `Crosswake.RuntimeLine` / `RebuildPolicy`, `SupportMatrix.runtime_line_truth/0`, doctor stubs, operator-inspection types. No native code.
**Avoids:** Support-truth dishonesty; rebuild-policy drift.

### Phase B: Diagnostic Export Seam (Elixir)
**Rationale:** Define the redaction allowlist and envelope schema before any native export code exists.
**Delivers:** `Crosswake.Shell.DiagnosticExport`, sanitize/redaction allowlist, envelope fixtures, doctor check. No native code.
**Avoids:** PII/token leakage; bounded-bridge violation (HTTP seam, not bridge command).

### Phase C: Generator Templates + Xcode 26 CI Fix
**Rationale:** Emit templates from the locked contracts; fix the hard Apple CI gate in the same phase that introduces template generation so they can't drift.
**Delivers:** EEx templates (runtime-line reader, diagnostics, permission/entitlement stubs incl. `PrivacyInfo.xcprivacy`), `gen.shell` extensions, `@platform_definitions` additions, placeholder/drift doctor check, iOS CI on Xcode 26, ExUnit proof.
**Uses:** EEx generator pattern; host-owned `ADOPT:` markers.

### Phase D: iOS Shell Implementation
**Rationale:** Native mirror of the locked contracts/templates.
**Delivers:** `RuntimeLinePolicyReader.swift`, `DiagnosticExport.swift` (MetricKit), `ActivationCoordinator` integration, entitlements template with portal-step docs, `PrivacyInfo.xcprivacy` contract, iOS proof-script extension.

### Phase E: Android Shell + JVM Hermetic Proof
**Rationale:** Closes the JVM-hermetic evidence gap (merge-blocking) before any advisory device claims.
**Delivers:** `RuntimeLinePolicyReader.kt`, `DiagnosticExport.kt` (ApplicationExitInfo), JVM unit tests (hermetic, merge-blocking), AGP/Kotlin/Gradle/minSdk/compileSdk/targetSdk bumps. Hermetic merge-blocking; emulator/device advisory.

### Phase F: Android Verification Closure + Device-UAT Checklist
**Rationale:** Honestly document what JVM tests cannot cover.
**Delivers:** Advisory emulator lane (`continue-on-error: true`), device-UAT checklist with CI-provable / device-advisory / provider-advisory columns, capability-registry ↔ UAT-checklist parity test, explicit promotion criteria.

### Phase G: Docs-Contract Parity Gate & Android Support Promotion
**Rationale:** Final gate — only after all prior CI passes can Android support truth be promoted.
**Delivers:** Merge-blocking docs-contract test (manifest ↔ shell fixture ↔ guide ↔ doctor all agree), guide updates, Android `SupportEntry` promoted from `:verification_required` only if/when promotion criteria are met.

### Phase Ordering Rationale
- **Contracts/support-truth before code:** locks evidence + rebuild taxonomy so no surface can overclaim.
- **Generator before native:** templates emit from locked contracts; iOS/Android mirror them.
- **Hermetic before advisory:** JVM proof (merge-blocking) precedes the advisory emulator/device lane.
- **Parity gate + promotion last:** Android stays `:verification_required` until the final docs-contract gate and promotion criteria pass.

### Research Flags
**Phases likely needing deeper research during planning:** NONE — all five areas are HIGH-confidence and grounded in existing Crosswake surfaces + verified platform policy.

Phases with standard patterns (skip research-phase): all — rebuild policy (existing `Compatibility` patterns), permission templates (existing `gen.shell` EEx), diagnostics seam (v3.9 Chimeway HTTP + redaction posture), Android verification (v3.1+ hermetic/advisory split), device-UAT checklist (v3.2–v3.9 precedent).

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | No new hex deps; iOS/Android SDK versions verified vs. official release notes; Xcode 26 mandate confirmed (2026-04-28) |
| Features | HIGH | Derived from existing Crosswake surfaces; permission requirements verified vs. App Store Review Guideline 2.5.2 + Google Play policy deadlines |
| Architecture | HIGH | All new modules attach to proven surfaces (Compatibility, SupportMatrix, Doctor); diagnostic seam follows Chimeway HTTP pattern; grounded in committed source |
| Pitfalls | HIGH | Platform-policy claims verified against current Apple/Google sources; Crosswake-specific drift pitfalls grounded in PROJECT.md + MILESTONE-ARC |

**Overall confidence:** HIGH

### Gaps to Address
- **`minSdk 30` hard vs. opt-in-with-warning** in generated shells — resolve during the Android shell phase (affects template guard logic, not stack choice).
- **`ApplicationExitInfo` trace-stream inclusion** in the diagnostic payload (trace streams can be large) — scope decision for the diagnostics-export phase; default to structured exit-reason metadata only unless justified.
- **Minimum Android evidence for `:supported` promotion** — define concrete promotion criteria in Phase A and enforce at the Phase G gate (open MILESTONE-ARC research flag).

## Sources

### Primary (HIGH confidence)
- Committed Crosswake source — `Manifest.Types.Compatibility`, `Doctor`, `SupportMatrix`, `gen.shell`, `phase18/phase23/phase58-proof.yml`, Chimeway `DiagnosticExport` pattern.
- Apple Developer — App Store Review Guideline 2.5.2 (OTA executable code), `PrivacyInfo.xcprivacy` / `NSPrivacyAccessedAPITypes` (enforced since May 2024), Xcode 26 SDK Upcoming Requirements (2026-04-28), MetricKit / `MXCrashDiagnostic`.
- Android Developers / Google Play — `ApplicationExitInfo` (API 30), `targetSdkVersion ≥ 35` floor (Aug 2025), Play Integrity (SafetyNet deprecation May 2025), AGP/Kotlin/Gradle release notes.

### Secondary (MEDIUM confidence)
- Capacitor / Expo (`fingerprint`) / CodePush — established OTA-safe vs. rebuild-required boundary conventions.
- `ReactiveCircus/android-emulator-runner` usage; Firebase Test Lab free tier as advisory-lane extension point.

---
*Research completed: 2026-06-03*
*Ready for roadmap: yes*
