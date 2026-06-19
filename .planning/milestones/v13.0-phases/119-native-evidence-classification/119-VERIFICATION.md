---
phase: 119-native-evidence-classification
verified: 2026-06-19T21:25:00Z
status: passed
score: 3/3 requirements verified
behavior_unverified: 0
overrides_applied: 0
gaps: []
deferred: []
residual_risks:
  - "Native simulator, emulator, and physical-device behavior remains advisory unless promoted by a later support contract; this phase verifies coordinate defaults, labels, docs, templates, and drift guards."
---

# Phase 119: Native Evidence Classification Verification Report

**Phase Goal:** Users can tell exactly whether native evidence proves published coordinates, local-development hosts, or advisory simulator/emulator collateral.  
**Verified:** 2026-06-19T21:25:00Z  
**Status:** passed

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Checked-in iOS and Android hosts default to published native package coordinates. | VERIFIED | iOS project uses the SwiftPM mirror; Android host and generated template use `io.github.sztheory:crosswake-shell-core-android:0.1.2`; generator/readiness tests passed. |
| 2 | The maintainer/local-development path remains explicit and labeled instead of silently masquerading as adopter install truth. | VERIFIED | Host READMEs and generated templates distinguish checked-in public-coordinate proof from `--local` maintainer paths; native drift guard passed. |
| 3 | Public native docs and support surfaces use the same evidence-label vocabulary. | VERIFIED | Install, native shell, compatibility, Android UAT, support matrix, host READMEs, and support-matrix renderer/tests were reconciled; support-matrix tests passed. |
| 4 | Public proof avoids stale Android coordinates, silent iOS local package references, and physical-device overclaims. | VERIFIED | `Crosswake.Guides.NativeEvidenceDriftTest` scans source docs/templates/host files and includes synthetic stale-coordinate, missing-label, and overclaim regressions; drift guard passed. |

**Score:** 3/3 requirements verified.

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj` | Checked-in iOS host uses published SwiftPM mirror by default | VERIFIED | Plan 119-01 summary records removal of silent local package default. |
| `examples/android_shell_host/app/build.gradle` | Checked-in Android host uses published Maven coordinate by default | VERIFIED | Plan 119-01 summary records `io.github.sztheory:crosswake-shell-core-android:0.1.2`. |
| `examples/ios_shell_host/README.md` and `examples/android_shell_host/README.md` | Host evidence class and limitations are explicit | VERIFIED | Public-coordinate proof and local-dev/advisory labels are documented. |
| `guides/install.md`, `guides/native_shell.md`, `guides/compatibility.md`, `guides/android_uat.md`, `guides/support_matrix.md` | Native docs use consistent labels and current `0.1.2` truth | VERIFIED | Support matrix renderer/source and docs tests passed. |
| `priv/templates/crosswake/shell/ios/README.md.eex`, `priv/templates/crosswake/shell/android/README.md.eex`, `priv/templates/crosswake/shell/android/app/build.gradle.eex` | Generated templates preserve coordinate and evidence-label truth | VERIFIED | Generator/readiness and drift guard tests passed. |
| `test/crosswake/guides/native_evidence_drift_test.exs` | Drift guard blocks stale native evidence truth | VERIFIED | Targeted test passed, 10 tests and 0 failures. |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Generator/readiness native coordinate proof | `mix test test/mix/tasks/crosswake_gen_shell_test.exs test/crosswake/doctor/publish_readiness_test.exs` | 13 tests, 0 failures | PASS |
| Support-matrix label rendering | `mix test test/crosswake/support_matrix/renderer_test.exs test/crosswake/support_matrix/support_matrix_test.exs` | 66 tests, 0 failures | PASS |
| Native evidence drift guard | `mix test test/crosswake/guides/native_evidence_drift_test.exs` | 10 tests, 0 failures | PASS |

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| NATIVE-01 | `119-01-PLAN.md` | Checked-in native hosts use published coordinates by default or are explicitly labeled local-dev proof | SATISFIED | Host coordinate changes, host README labels, generator/readiness tests. |
| NATIVE-02 | `119-02-PLAN.md` | Native docs and support surfaces distinguish published-coordinate proof, local-dev proof, and advisory evidence | SATISFIED | Docs/template updates, support-matrix renderer/source updates, support-matrix tests. |
| DRIFT-03 | `119-03-PLAN.md` | Native evidence drift is mechanically guarded | SATISFIED | Source-derived drift scanner and synthetic regressions passed. |

## Human Verification Required

None. Native simulator/emulator collateral remains advisory; this phase verifies evidence classification, coordinate defaults, docs/templates, and drift prevention.

## Gaps Summary

No blocking gaps found. Phase 119 satisfies NATIVE-01, NATIVE-02, and DRIFT-03 with automated verification evidence.

---

_Verified: 2026-06-19T21:25:00Z_  
_Verifier: codex-inline_
