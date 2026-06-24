---
phase: 126-additive-native-dev-wiring
plan: "04"
subsystem: proof-posture-guard
tags: [elixir, exunit, guard-test, anti-vacuity, quick-start, documentation, drift-test]

requires:
  - phase: 126-01
    provides: "dev fixtures (route_activation-dev.json for iOS + Android)"
  - phase: 126-02
    provides: "Info-Dev.plist with localhost ATS exception"
  - phase: 126-03
    provides: "network_security_config_dev.xml + dev AndroidManifest.xml"

provides:
  - "Crosswake.Guides.NativeDevWiringTest — source-derived, non-vacuous proof-posture guard (12 tests)"
  - "QUICK_START.md: single additive 'Run Against the Local Backend (Dev Wiring)' section (D-15/D-16)"

affects:
  - "Phase 128 see_it_run.md guide (references QUICK_START launch commands)"

tech-stack:
  added: []
  patterns:
    - "committed_port/0 + source_port!/3 helpers copied verbatim from port_registry_test.exs — single canonical pattern for source-derived port"
    - "Four-block guard structure: proof-untouched / dev-exists / dev-correct / dev-honestly-tagged + anti-vacuity"
    - "Jason.decode! key lookup for all JSON assertions — never String.contains? on raw JSON fixture values"
    - "Anti-vacuity via synthetic in-memory wrong-value cases (house idiom from native_evidence_drift_test)"
    - "QUICK_START drift-scanner compatibility: 10.0.2.2:4700 avoids wrong_port_failures; directory-level host refs avoid documented_path_failures fragility; both native labels in 1500-char window"

key-files:
  created:
    - test/crosswake/guides/native_dev_wiring_test.exs
  modified:
    - examples/QUICK_START.md

key-decisions:
  - "Source-derived port in guard test (committed_port/0 regex against runtime.exs) — closes the 10.0.2.2 coverage gap the existing QUICK_START scanner does not flag"
  - "Anti-vacuity proves assertions fire: synthetic plist-with-NSExceptionDomains + synthetic dev-fixture-still-at-proof-domain"
  - "Both native labels placed in new QUICK_START section (not relying solely on existing label block) — ensures native_label_failures scanner window covers new native host mentions"
  - "JAVA_HOME note placed immediately before/with the gradle command (D-16 caveat adjacent to command)"
  - "No new guides/ file created — Phase 128 owns guides/see_it_run.md"

patterns-established:
  - "Guard test idiom: four assertion blocks (untouched/exists/correct/tagged) + anti-vacuity regression cases; reusable for any future dev-wiring phase"

requirements-completed: [NDEV-03]

duration: 4min
completed: 2026-06-22
status: complete
---

# Phase 126 Plan 04: Proof-Posture Guard Test + QUICK_START Dev-Wiring Section Summary

**Source-derived, non-vacuous guard test (12 tests) proving prod proof posture is byte-untouched and dev wiring is correct; single additive QUICK_START section with iOS (-scheme Dev) + Android (installDevDebug) commands in honest advisory-native voice**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-22T17:16:59Z
- **Completed:** 2026-06-22T17:20:54Z
- **Tasks:** 2
- **Files modified:** 2 (1 created guard test, 1 modified QUICK_START.md)

## Accomplishments

- Created `test/crosswake/guides/native_dev_wiring_test.exs` defining `Crosswake.Guides.NativeDevWiringTest` with 12 tests across four assertion blocks:
  - **Block A (proof-untouched):** prod Info.plist lacks NSAllowsArbitraryLoads/NSExceptionDomains/localhost; prod iOS+Android fixtures have `origin == "https://example.crosswake.invalid"`; prod AndroidManifest has `usesCleartextTraffic="false"` and no `network_security_config_dev` reference
  - **Block B (dev-exists):** asserts all four dev wiring files exist (Info-Dev.plist, route_activation-dev.json, dev assets route_activation.json, network_security_config_dev.xml)
  - **Block C (dev-correct):** source-derived port via `committed_port/0` regex against runtime.exs; iOS dev fixture origin+url contain `localhost:<port>`; Android dev fixture contain `10.0.2.2:<port>`; Info-Dev.plist has NSExceptionDomains+localhost+NSExceptionAllowsInsecureHTTPLoads; network_security_config_dev.xml has 10.0.2.2+cleartextTrafficPermitted
  - **Block D (dev-honestly-tagged):** dev `_generated_by` starts with prod `_generated_by` for both iOS and Android fixtures
  - **Block E (anti-vacuity):** synthetic plist-with-NSExceptionDomains case; synthetic dev-fixture-still-at-proof-domain case
- Added single "Run Against the Local Backend (Dev Wiring)" section to QUICK_START.md:
  - Honest advisory-native opening sentence (D-16)
  - Both required native labels within section: "checked-in public-coordinate proof" and "published-coordinate mode"
  - Backend startup command (PORT=4700 mix phx.server + docker compose up alternative)
  - iOS: xcodebuild -scheme Dev -configuration Debug-Dev -destination iPhone 16 + Xcode scheme picker path
  - Android: JAVA_HOME=/opt/homebrew/opt/openjdk@17 installDevDebug (D-16 caveat adjacent) + adb shell am start -n dev.crosswake.shell.dev/.MainActivity

## Task Commits

Each task was committed atomically:

1. **Task 1: Source-derived proof-posture guard with anti-vacuity cases (D-14)** — `a5138c0` (test)
2. **Task 2: Additive QUICK_START dev-wiring section with honest voice (D-15/D-16)** — `1f90989` (docs)

## Files Created/Modified

- `test/crosswake/guides/native_dev_wiring_test.exs` — Created: Crosswake.Guides.NativeDevWiringTest, 12 tests, source-derived port, Jason.decode! JSON assertions, anti-vacuity regression cases
- `examples/QUICK_START.md` — Added: "Run Against the Local Backend (Dev Wiring)" section (37 lines) between Android Local-Development Walkthrough and Troubleshooting Quick Checks

## Decisions Made

- Copied `committed_port/0` + `source_port!/3` helpers verbatim from `port_registry_test.exs` — canonical pattern for source-derived port across guide tests
- No literal `4700` in the guard test; port always derived from `System.get_env("PORT") || "(\d+)"` regex against `examples/phoenix_host/config/runtime.exs`
- Anti-vacuity cases use in-memory synthetic values (not on-disk files) — mirrors the contract_drift_test idiom
- QUICK_START section includes BOTH required native labels within the section body (not relying on the 1500-char proximity to the existing label block elsewhere) — ensures the native_label_failures scanner window check passes for both `examples/ios_shell_host/CrosswakeShell.xcodeproj` and `examples/android_shell_host`
- References hosts at directory level only to avoid documented_path_failures fragility on paths deeper than the directory

## Deviations from Plan

None - plan executed exactly as written.

## Threat Mitigations Applied

| Threat ID | Mitigation Status |
|-----------|-----------------|
| T-126-01 | MITIGATED: Guard asserts prod plist/manifest/fixtures are byte-untouched; anti-vacuity cases prove assertions fire on regression |
| T-126-06 | MITIGATED: D-16 advisory-native voice in QUICK_START opener; both required native labels present; quick_start_adoption_drift_test.exs enforces labels and source-derived port |
| T-126-SC | N/A: No package-manager installs — ExUnit + Markdown only |

## Known Stubs

None — all assertions run against committed files; QUICK_START commands are exact copy-paste launch commands.

## Verification Results

- `mix test test/crosswake/guides/native_dev_wiring_test.exs`: 12 tests, 0 failures
- `mix test test/crosswake/guides/quick_start_adoption_drift_test.exs`: 5 tests, 0 failures
- Full `mix test`: 1166 tests, 4 failures (4 excluded) — the 4 failures are pre-existing carries from v14.0 (HexPage×2, Phase48, Phase69); orthogonal to Phase 126
- No new guides/ file created; host READMEs unchanged (`git diff` clean for those paths)

## Self-Check

Verifying all claims before proceeding:

- `test/crosswake/guides/native_dev_wiring_test.exs` FOUND (created — contains NativeDevWiringTest, committed_port/0, Jason.decode!, anti-vacuity tests)
- `examples/QUICK_START.md` FOUND (modified — contains "Run Against the Local Backend", "-scheme Dev", "installDevDebug", "adb shell am start", "JAVA_HOME", both native labels)
- Commits: a5138c0, 1f90989 both present
- `mix test test/crosswake/guides/native_dev_wiring_test.exs`: 12 tests, 0 failures
- `mix test test/crosswake/guides/quick_start_adoption_drift_test.exs`: 5 tests, 0 failures
- No literal 4700 in test file; PORT regex confirmed present
- No guides/see_it_run.md created; host READMEs unchanged

## Self-Check: PASSED

---
*Phase: 126-additive-native-dev-wiring*
*Completed: 2026-06-22*
