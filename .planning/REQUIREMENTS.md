# Requirements: Crosswake — v4.0 Production Shell Runtime Line

**Defined:** 2026-06-03
**Core Value:** Make runtime boundaries explicit so Phoenix teams can ship credible mobile apps without hiding the tradeoffs between LiveView, offline, and native ownership.

## v1 Requirements

Requirements for milestone v4.0. Each maps to roadmap phases. ("User" = the adopting Phoenix team, the operator running diagnostics, or the Crosswake maintainer running proof, per requirement.)

### Runtime-Line Policy (RLINE)

- [x] **RLINE-01**: Adopters can determine, for any manifest/capability/shell change, whether it is OTA-safe or requires a native rebuild, classified per change class (bridge schema change, capability family add, permission add, entitlement add, SDK floor bump, privacy-manifest entry, push capability change, URL-scheme change).
- [x] **RLINE-02**: The rebuild/OTA policy is derived from the existing manifest `native_runtime_version` compatibility axis without introducing a new manifest schema field or breaking deployed shells.
- [x] **RLINE-03**: Operators can view a rebuild & compatibility matrix through `SupportMatrix` and `mix crosswake.doctor` showing which shell/runtime-line version supports which manifest/capability surface.
- [x] **RLINE-04**: Support truth distinguishes `:jvm_hermetic` from `:device_verified` evidence and never reports CI-only evidence as device-verified.
- [x] **RLINE-05**: Android support state carries explicit, documented promotion criteria for moving from `:verification_required` to `:supported`.

### Permission/Entitlement Templates (TMPL)

- [ ] **TMPL-01**: Adopters can generate host-owned iOS permission/entitlement scaffolds (Info.plist usage strings, Entitlements, `PrivacyInfo.xcprivacy`) via `mix crosswake.gen.shell`, with `ADOPT:` markers and without Crosswake writing real native values.
- [ ] **TMPL-02**: Adopters can generate host-owned Android permission scaffolds (AndroidManifest permission/feature stubs) via the generator with `ADOPT:` markers and host-owned values.
- [ ] **TMPL-03**: Generated permission/entitlement templates stay parity-locked to declared capability families — every capability requiring a permission or entitlement is represented in the templates.
- [ ] **TMPL-04**: `mix crosswake.doctor` flags un-replaced template placeholders and manifest↔shell↔docs permission/entitlement drift.

### Diagnostics Export (DIAG)

- [x] **DIAG-01**: The shell can export crash/diagnostic evidence to a host-owned endpoint as a fire-and-forget HTTP POST (iOS MetricKit, Android `ApplicationExitInfo`), not through the bounded bridge.
- [x] **DIAG-02**: Diagnostic export payloads carry layer attribution (native/web/bridge) and a stable, typed envelope schema.
- [x] **DIAG-03**: Diagnostic export applies an explicit, tested redaction allowlist that forbids raw tokens, payloads, route params, and PII (reusing the v3.9 Chimeway/Sigra redaction posture).
- [x] **DIAG-04**: `mix crosswake.doctor` and support truth report diagnostics-export readiness without implying a first-party crash-reporting service.

### Android Verification Closure (AVER)

- [ ] **AVER-01**: Maintainers can run merge-blocking hermetic JVM proof for the Android runtime-line reader and diagnostics export.
- [ ] **AVER-02**: The Android shell builds against updated toolchain floors (AGP/Kotlin/Gradle, `minSdk 30`, `compileSdk`/`targetSdk 35`) with hermetic proof.
- [ ] **AVER-03**: Maintainers can run an advisory (non-blocking) Android emulator lane with documented promotion criteria.
- [ ] **AVER-04**: A device-UAT checklist enumerates CI-provable / device-advisory / provider-advisory items and stays parity-locked to the capability registry.
- [ ] **AVER-05**: iOS CI builds against the Xcode 26 SDK so iOS shell proof remains App Store-submittable.

### Proof & Docs (PROOF)

- [ ] **PROOF-01**: A merge-blocking docs-contract test verifies that manifest ↔ shell fixture ↔ guide ↔ doctor agree on runtime-line, rebuild, permission/entitlement, and diagnostics truth.
- [ ] **PROOF-02**: Public guides document the runtime-line policy, rebuild/compatibility matrix, permission/entitlement templates, diagnostics export, and Android verification posture, parity-locked to live support/doctor truth.
- [ ] **PROOF-03**: Milestone closeout (`mix closeout.verify`, REL-01 gate) verifies all v4.0 requirements are mapped and no surface claims first-party shell packages, device-verified Android without evidence, or first-party crash-reporting/push delivery.

## v2 Requirements

Deferred to future milestones. Tracked but not in the current roadmap.

### Shell Distribution (SHELL)

- **SHELL-01**: Standalone publishable iOS/Android shell packages (deferred until release choreography is ready — arc non-goal).

### Device Proof (DPROOF)

- **DPROOF-01**: Promote the emulator/device lane to merge-blocking once promotion criteria are repeatedly met with stable evidence.
- **DPROOF-02**: Firebase Test Lab (or equivalent) device-matrix advisory lane as a distinct runtime-claim proof.

## Out of Scope

Explicitly excluded for v4.0. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Standalone/publishable shell packages | Arc non-goal until release choreography is ready; shells stay checked-in proof artifacts in `examples/`. |
| First-party crash-reporting service | Diagnostics is a host-owned export seam, not a Crosswake-operated reporter. |
| First-party push delivery | Out of scope since v3.9; v4.0 hardens shell runtime, not delivery. |
| New manifest JSON schema field for rebuild policy | Would force a `manifest_schema_version` bump and break deployed shells; policy derives from the existing `native_runtime_version` axis. |
| Merge-blocking emulator/device lane | Environment-sensitive; stays advisory with explicit promotion criteria (deferred to DPROOF-01). |
| Broad new native capability families | v4.0 hardens the existing runtime line; capability breadth is separate arc work. |
| New high-frequency bridge surface | Bridge stays semantic, typed, versioned, low-frequency; diagnostics uses an HTTP seam, not bridge vocabulary. |

## Traceability

Which phases cover which requirements. Filled during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| RLINE-01 | Phase 64 | Complete |
| RLINE-02 | Phase 64 | Complete |
| RLINE-03 | Phase 64 | Complete |
| RLINE-04 | Phase 64 | Complete |
| RLINE-05 | Phase 64 | Complete |
| TMPL-01 | Phase 66 | Pending |
| TMPL-02 | Phase 66 | Pending |
| TMPL-03 | Phase 66 | Pending |
| TMPL-04 | Phase 66 | Pending |
| DIAG-01 | Phase 65 | Complete |
| DIAG-02 | Phase 65 | Complete |
| DIAG-03 | Phase 65 | Complete |
| DIAG-04 | Phase 65 | Complete |
| AVER-01 | Phase 67 | Pending |
| AVER-02 | Phase 67 | Pending |
| AVER-03 | Phase 68 | Pending |
| AVER-04 | Phase 68 | Pending |
| AVER-05 | Phase 66 | Pending |
| PROOF-01 | Phase 69 | Pending |
| PROOF-02 | Phase 69 | Pending |
| PROOF-03 | Phase 69 | Pending |

**Coverage:**
- v1 requirements: 21 total
- Mapped to phases: 21 ✓
- Unmapped: 0

---
*Requirements defined: 2026-06-03*
*Last updated: 2026-06-03 — roadmap created; all 21 v1 requirements mapped across Phases 64-69.*
