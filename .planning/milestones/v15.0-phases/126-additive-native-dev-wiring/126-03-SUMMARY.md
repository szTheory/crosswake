---
phase: 126-additive-native-dev-wiring
plan: "03"
subsystem: android-dev-flavor
tags: [android, gradle, product-flavors, network-security-config, manifest-overlay, dev-wiring]

requires:
  - phase: 126-01
    provides: "examples/android_shell_host/app/src/dev/assets/route_activation.json (generated dev fixture)"

provides:
  - "flavorDimensions env + prod/dev productFlavors in app/build.gradle (dev.crosswake.shell.dev installs side-by-side)"
  - "app/src/dev/AndroidManifest.xml: tools:replace network-security overlay + non-autoVerify 10.0.2.2:4700 intent-filter"
  - "app/src/dev/res/xml/network_security_config_dev.xml: cleartext scoped to 10.0.2.2 only; base-config default-off"
  - "Migrated examples/-path Gradle task names: testProdDebugUnitTest / connectedProdDebugAndroidTest"
  - "QUICK_START.md: installProdDebug (proof walkthrough)"

affects:
  - 126-04-proof-posture-guard (guard test asserts prod manifest untouched + dev files exist)

tech-stack:
  added: []
  patterns:
    - "flavorDimensions / productFlavors DSL (AGP 8.5.0): prod flavor needs no src/prod/ directory (AGP resolves to src/main)"
    - "networkSecurityConfig in dev source-set overlay overrides inline usesCleartextTraffic; scoped per-domain with base-config false"
    - "tools:replace on manifest application attribute requires xmlns:tools declared on root manifest element"
    - "Parameter-expansion variable approach for conditional Gradle task names: ${VAR:+new_value} / ${VAR:-default}"

key-files:
  created:
    - examples/android_shell_host/app/src/dev/AndroidManifest.xml
    - examples/android_shell_host/app/src/dev/res/xml/network_security_config_dev.xml
  modified:
    - examples/android_shell_host/app/build.gradle
    - script/verify_generated_android_shell.sh
    - examples/QUICK_START.md

key-decisions:
  - "prod flavor uses no applicationIdSuffix/versionNameSuffix (proof build stays dev.crosswake.shell); no src/prod/ directory needed"
  - "tools:replace on networkSecurityConfig attribute rather than full manifest replacement (minimal overlay)"
  - "dev intent-filter omits android:autoVerify entirely (pitfall 3: autoVerify on 10.0.2.2 would fail asset-link verification and could cascade to proof domain on older APIs)"
  - "base-config cleartextTrafficPermitted=false preserves default-off posture; cleartext permitted only in domain-config for 10.0.2.2"
  - "Parameter-expansion conditional (not if/else) for UNIT_TEST_TASK/CONNECTED_TEST_TASK: examples/ branch gets prod-flavored tasks; generated-from-template branch retains unflavored tasks"

requirements-completed: [NDEV-02]

duration: 8min
completed: 2026-06-22
status: complete
---

# Phase 126 Plan 03: Android Dev Product Flavor + Network-Security Config Summary

**Android host gains an additive `dev` product flavor with `networkSecurityConfig` cleartext scoped to 10.0.2.2 only, a non-autoVerify dev intent-filter, and migrated examples/-path Gradle task names**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-22T17:10:47Z
- **Completed:** 2026-06-22T17:18:00Z
- **Tasks:** 3
- **Files modified:** 5 (1 modified build.gradle, 2 created dev source-set files, 1 modified verify script, 1 modified QUICK_START.md)

## Accomplishments

- Extended `app/build.gradle` with `flavorDimensions "env"` + `prod` (proof/default, no suffix) and `dev` (`applicationIdSuffix ".dev"`, `versionNameSuffix "-dev"`) productFlavors; `versionName "0.1.2"` and library coordinate untouched
- Created `app/src/dev/AndroidManifest.xml` with `xmlns:tools` declared, `tools:replace="android:networkSecurityConfig"` overlay, and a non-autoVerify http intent-filter for `10.0.2.2:4700`
- Created `app/src/dev/res/xml/network_security_config_dev.xml` with `base-config cleartextTrafficPermitted="false"` and `domain-config cleartextTrafficPermitted="true"` scoped to `10.0.2.2`
- Prod `app/src/main/AndroidManifest.xml` byte-untouched: `usesCleartextTraffic="false"` preserved, no `network_security_config_dev` reference
- Migrated `script/verify_generated_android_shell.sh` two examples/-path Gradle invocations via parameter-expansion variables (`UNIT_TEST_TASK`, `CONNECTED_TEST_TASK`); generated-from-template path retains unflavored names
- Updated `examples/QUICK_START.md` `installDebug` → `installProdDebug` in proof walkthrough

## Task Commits

Each task was committed atomically:

1. **Task 1: Add prod + dev product flavors to app/build.gradle** — `cc6ce2b` (feat)
2. **Task 2: Create dev source-set overlay — dev AndroidManifest.xml + network_security_config_dev.xml** — `b7d92c8` (feat)
3. **Task 3: Migrate examples/-path Gradle invocations (D-10 blast radius)** — `b4f83d0` (feat)

## Files Created/Modified

- `examples/android_shell_host/app/build.gradle` — Added `flavorDimensions "env"` + `prod`/`dev` `productFlavors` block after `buildTypes`, before `buildFeatures`
- `examples/android_shell_host/app/src/dev/AndroidManifest.xml` — Dev manifest overlay: `xmlns:tools`, `tools:replace` network-security config, non-autoVerify `10.0.2.2:4700` intent-filter
- `examples/android_shell_host/app/src/dev/res/xml/network_security_config_dev.xml` — Network-security config: base-config false, domain-config true for `10.0.2.2`
- `script/verify_generated_android_shell.sh` — UNIT_TEST_TASK/CONNECTED_TEST_TASK variables; examples/ path uses prod-flavored tasks; template path uses unflavored tasks
- `examples/QUICK_START.md` — `installDebug` → `installProdDebug` in Android Local-Development Walkthrough

## Decisions Made

- Minimal dev manifest overlay: only `networkSecurityConfig` replace + dev intent-filter; merger inherits everything else from main
- `app/src/prod/` directory NOT created (AGP resolves `prod` flavor to `src/main` when no explicit `src/prod/` exists — Assumption A1 confirmed)
- Parameter-expansion form for task-name variables chosen over an `if/else` block (cleaner, idiomatic shell, matches RESEARCH recommendation)

## Deviations from Plan

None - plan executed exactly as written.

## Threat Mitigations Applied

| Threat ID | Mitigation Status |
|-----------|------------------|
| T-126-01 | MITIGATED: `networkSecurityConfig` in dev source-set only; host-pinned to `10.0.2.2`; `base-config cleartextTrafficPermitted="false"`; prod manifest `usesCleartextTraffic="false"` byte-untouched |
| T-126-04 | MITIGATED: dev intent-filter omits `autoVerify` entirely |
| T-126-05 | MITIGATED: two examples/-path invocations migrated in lockstep; `bash -n` clean; CI workflows untouched |

## Known Stubs

None — all dev source-set files are fully wired to the generated dev fixture committed in Plan 01.

## Self-Check

Verifying all claims before proceeding:

- `examples/android_shell_host/app/build.gradle` FOUND (modified — contains `flavorDimensions`, `applicationIdSuffix`, `versionName "0.1.2"`)
- `examples/android_shell_host/app/src/dev/AndroidManifest.xml` FOUND (created — contains `xmlns:tools`, `tools:replace`, `10.0.2.2`)
- `examples/android_shell_host/app/src/dev/res/xml/network_security_config_dev.xml` FOUND (created — contains `10.0.2.2`, `cleartextTrafficPermitted="false"`)
- `script/verify_generated_android_shell.sh` FOUND (modified — contains `ProdDebug`, `bash -n` clean)
- `examples/QUICK_START.md` FOUND (modified — contains `installProdDebug`, no bare `gradlew installDebug`)
- Commits: cc6ce2b, b7d92c8, b4f83d0 all present
- Prod `app/src/main/AndroidManifest.xml` diff: clean (untouched)
- `.github/workflows/` diff: clean (untouched)

## Self-Check: PASSED

---
*Phase: 126-additive-native-dev-wiring*
*Completed: 2026-06-22*
