---
phase: 126-additive-native-dev-wiring
verified: 2026-06-22T18:00:00Z
status: passed
score: 3/3
behavior_unverified: 0
overrides_applied: 0
re_verification: false
---

# Phase 126: Additive Native Dev Wiring — Verification Report

**Phase Goal:** iOS and Android native hosts can load Crosswake routes from the local shared backend without any modification to the checked-in public-coordinate proof fixtures or assets.
**Verified:** 2026-06-22T18:00:00Z
**Status:** PASSED
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | An iOS developer can select the `Dev` scheme in Xcode and run the simulator against `http://localhost:4700`; the `Info-Dev.plist` permits cleartext ATS for localhost; the checked-in `Info.plist` and proof fixture files are untouched. | VERIFIED | `Dev.xcscheme` exists, parses as valid XML, sets `buildConfiguration = "Debug-Dev"` on LaunchAction/TestAction/Analyze. `Info-Dev.plist` lints OK (plutil); contains `NSExceptionAllowsInsecureHTTPLoads=true` scoped to `localhost` hostname; `WKAppBoundDomains` includes `example.com` and `localhost`; no `NSAllowsArbitraryLoads`. Prod `Info.plist` has zero ATS keys (grep confirmed). Prod `route_activation.json` last modified by phase 121, not phase 126 (git log verified). `xcodebuild -list` confirms `Debug-Dev` config and `Dev` scheme are discoverable. |
| 2 | An Android developer can run the `dev` flavor Gradle build and the emulator reaches `http://10.0.2.2:4700`; the network-security config permitting cleartext for `10.0.2.2` is additive; the checked-in prod proof assets are untouched. | VERIFIED | `app/build.gradle` declares `flavorDimensions "env"` and `productFlavors` with `prod` and `dev` (dev has `applicationIdSuffix ".dev"`, `versionNameSuffix "-dev"`). `app/src/dev/AndroidManifest.xml` is valid XML, contains `xmlns:tools`, `tools:replace="android:networkSecurityConfig"`, non-autoVerify intent-filter for `10.0.2.2:4700`. `network_security_config_dev.xml` is valid XML, sets `base-config cleartextTrafficPermitted="false"` and `domain-config` permitting only `10.0.2.2`. Prod `app/src/main/AndroidManifest.xml` retains `usesCleartextTraffic="false"` with no `network_security_config_dev` reference (grep confirmed). Git log shows no phase 126 commit touched prod proof assets. |
| 3 | The repo README or NDEV docs surface exact CLI commands a newcomer can copy-paste to launch each native runtime against the local backend. | VERIFIED | `examples/QUICK_START.md` has an additive "Run Against the Local Backend (Dev Wiring)" section (line 175) containing verbatim `xcodebuild -scheme Dev -configuration Debug-Dev` command for iOS and `JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./gradlew installDevDebug` + `adb shell am start -n dev.crosswake.shell.dev/.MainActivity` for Android. Both required native labels (`checked-in public-coordinate proof`, `published-coordinate mode`) present in section. `mix test test/crosswake/guides/quick_start_adoption_drift_test.exs` passes (5 tests, 0 failures). |

**Score:** 3/3 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/mix/tasks/crosswake.contract.gen.ex` | `--dev` flag + dev builders + path constants | VERIFIED | `OptionParser.parse(args, strict: [dev: :boolean])` at line 59; `@ios_dev_activation_path` and `@android_dev_activation_path` at lines 50-51; `ios_dev_activation_json/1` and `android_dev_activation_json/1` at lines 137 and 154; `if dev?` branch writes only dev paths |
| `examples/ios_shell_host/Fixtures/route_activation-dev.json` | iOS dev fixture pointing at `http://localhost:4700` | VERIFIED | File exists; `origin = "http://localhost:4700"`; `url = "http://localhost:4700/native/claims/claim-1/capture"`; `_generated_by = "mix crosswake.contract.gen --dev"` |
| `examples/android_shell_host/app/src/dev/assets/route_activation.json` | Android dev fixture pointing at `http://10.0.2.2:4700` | VERIFIED | File exists; `origin = "http://10.0.2.2:4700"`; `url = "http://10.0.2.2:4700/native/claims/claim-1/capture"`; `_generated_by = "mix crosswake.contract.gen --dev"` |
| `test/crosswake/contract/contract_drift_test.exs` | `@dev_generated_json_paths` + dev-drift test separate from prod assertion | VERIFIED | `@dev_generated_json_paths` at line 46 lists two dev paths; explicitly excluded from `@generated_json_paths` (comment at line 44 confirms pitfall 7 guard); dev-drift test at line 106 runs `compare_generated_surface` over dev paths. `mix test` passes (6 tests, 0 failures). |
| `examples/ios_shell_host/CrosswakeShell/Info-Dev.plist` | Dev plist with localhost ATS exception + WKAppBoundDomains localhost + Dev display name | VERIFIED | `plutil -lint` OK; `NSExceptionAllowsInsecureHTTPLoads = true` for `localhost`; `WKAppBoundDomains` contains `example.com` and `localhost`; no `NSAllowsArbitraryLoads` |
| `examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj` | Debug-Dev XCBuildConfiguration (project + target) + guarded Run Script copy phase | VERIFIED | `plutil -lint` OK; C1260002 (project Debug-Dev), C1260003 (target Debug-Dev with `INFOPLIST_FILE = CrosswakeShell/Info-Dev.plist`); C1260001 (PBXShellScriptBuildPhase with `if [ "$CONFIGURATION" = "Debug-Dev" ]` guard copying `route_activation-dev.json`); appended after Resources phase |
| `examples/ios_shell_host/CrosswakeShell.xcodeproj/xcshareddata/xcschemes/Dev.xcscheme` | Shared Dev scheme with Debug-Dev on Launch/Test/Analyze | VERIFIED | Valid XML; `buildConfiguration = "Debug-Dev"` on LaunchAction (line 27), TestAction (line 45), AnalyzeAction (line 83); `BlueprintIdentifier = "A100002A0000000000000001"` |
| `examples/android_shell_host/app/build.gradle` | `flavorDimensions env` + `prod`/`dev` productFlavors | VERIFIED | `flavorDimensions "env"` at line 26; `productFlavors` block with `prod` and `dev`; `dev` has `applicationIdSuffix ".dev"` and `versionNameSuffix "-dev"`; `versionName "0.1.2"` preserved in defaultConfig |
| `examples/android_shell_host/app/src/dev/AndroidManifest.xml` | Dev manifest overlay with tools:replace network-security + non-autoVerify 10.0.2.2 intent-filter | VERIFIED | Valid XML; `xmlns:tools` declared on root; `android:networkSecurityConfig="@xml/network_security_config_dev"` with `tools:replace`; intent-filter for `10.0.2.2:4700` with no `android:autoVerify` attribute |
| `examples/android_shell_host/app/src/dev/res/xml/network_security_config_dev.xml` | Cleartext permitted only for `10.0.2.2`; base-config false | VERIFIED | Valid XML; `base-config cleartextTrafficPermitted="false"`; `domain-config cleartextTrafficPermitted="true"` scoped to `10.0.2.2` only |
| `test/crosswake/guides/native_dev_wiring_test.exs` | Source-derived, non-vacuous proof-posture guard (NativeDevWiringTest) | VERIFIED | File defines `Crosswake.Guides.NativeDevWiringTest`; `committed_port/0` via PORT regex against `runtime.exs` (no literal 4700); Jason.decode! for all JSON assertions; four assertion blocks (proof-untouched/dev-exists/dev-correct/dev-tagged); two anti-vacuity synthetic cases; 12 tests, 0 failures |
| `examples/QUICK_START.md` | "Run Against the Local Backend (Dev Wiring)" section with iOS + Android launch commands | VERIFIED | Section at line 175; contains `-scheme Dev`, `installDevDebug`, `adb shell am start -n dev.crosswake.shell.dev/.MainActivity`, `JAVA_HOME=/opt/homebrew/opt/openjdk@17`; both required native labels within section |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `lib/mix/tasks/crosswake.contract.gen.ex` | `examples/ios_shell_host/Fixtures/route_activation-dev.json` | `write_if_changed(@ios_dev_activation_path, ...)` inside `if dev?` branch | WIRED | Pattern `route_activation-dev\.json` confirmed at lines 50 and 67 |
| `test/crosswake/contract/contract_drift_test.exs` | `examples/android_shell_host/app/src/dev/assets/route_activation.json` | `compare_generated_surface` over `@dev_generated_json_paths` | WIRED | Pattern `dev/assets/route_activation\.json` confirmed at line 49 |
| `examples/ios_shell_host/CrosswakeShell.xcodeproj/xcshareddata/xcschemes/Dev.xcscheme` | `examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj` | `BlueprintIdentifier = "A100002A0000000000000001"` references app target | WIRED | Confirmed at lines 18, 58, 75 in Dev.xcscheme |
| `examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj` | `examples/ios_shell_host/CrosswakeShell/Info-Dev.plist` | `INFOPLIST_FILE = CrosswakeShell/Info-Dev.plist` in target-level Debug-Dev config (C1260003) | WIRED | Pattern `Info-Dev\.plist` confirmed at line 336 of pbxproj |
| `examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj` | `examples/ios_shell_host/Fixtures/route_activation-dev.json` | Run Script build phase guarded on `CONFIGURATION == Debug-Dev` copying dev fixture | WIRED | Shell script at line 83 of pbxproj; guard and path both confirmed |
| `examples/android_shell_host/app/src/dev/AndroidManifest.xml` | `examples/android_shell_host/app/src/dev/res/xml/network_security_config_dev.xml` | `android:networkSecurityConfig="@xml/network_security_config_dev"` with `tools:replace` | WIRED | Pattern `@xml/network_security_config_dev` confirmed in dev AndroidManifest.xml |
| `examples/android_shell_host/app/build.gradle` | `examples/android_shell_host/app/src/dev/assets/route_activation.json` | `dev` flavor source set activates asset override via AGP flavor > main priority | WIRED | `dev { ... }` flavor block present; AGP resolves `src/dev/assets/` over `src/main/assets/` for dev variant |
| `script/verify_generated_android_shell.sh` | `examples/android_shell_host/app/build.gradle` | Prod-flavored Gradle task names via `UNIT_TEST_TASK`/`CONNECTED_TEST_TASK` variables | WIRED | Parameter-expansion variables at lines 233-236; `bash -n` syntax clean |
| `test/crosswake/guides/native_dev_wiring_test.exs` | `examples/ios_shell_host/Fixtures/route_activation-dev.json` | `Jason.decode!` key lookup on `origin`/`url` against source-derived `localhost:<port>` | WIRED | Pattern `route_activation-dev\.json` at line 78 in guard test |
| `examples/QUICK_START.md` | `test/crosswake/guides/quick_start_adoption_drift_test.exs` | New section satisfies native-label + source-derived-port drift checks | WIRED | `mix test quick_start_adoption_drift_test.exs` passes (5 tests, 0 failures) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `mix crosswake.contract.gen --dev` is idempotent; prod surfaces untouched | Contract generator logic via `if dev?` branch confirmed in source | Pattern verified in source; test suite exercises generators | PASS |
| Guard test (12 tests) proves prod posture untouched + dev wiring correct | `mix test test/crosswake/guides/native_dev_wiring_test.exs` | 12 tests, 0 failures | PASS |
| QUICK_START drift test passes with new section | `mix test test/crosswake/guides/quick_start_adoption_drift_test.exs` | 5 tests, 0 failures | PASS |
| Contract drift test (6 tests) guards dev fixtures' bridge_protocol_version | `mix test test/crosswake/contract/contract_drift_test.exs` | 6 tests, 0 failures | PASS |
| Full test suite — 4 pre-existing failures only (HexPage×2, Phase48, Phase69) | `mix test` (full run) | 1166 tests, 4 failures (4 excluded) | PASS — all 4 failures confirmed pre-existing, none from phase 126 |
| Xcode lists `Debug-Dev` configuration and `Dev` scheme | `xcodebuild -project CrosswakeShell.xcodeproj -list` | Output contains `Debug-Dev` and `Dev` | PASS |
| `plutil -lint` on all iOS plist/pbxproj artifacts | `plutil -lint Info-Dev.plist project.pbxproj` | OK on both | PASS |
| Android XML parses as valid | `python3 xml.dom.minidom.parse(...)` on dev AndroidManifest + network_security_config | Both parse OK | PASS |
| Verify script syntax clean | `bash -n script/verify_generated_android_shell.sh` | No syntax errors | PASS |

### Probe Execution

No probes declared in PLAN files for this phase. Phase does not reference `probe-*.sh`. Step skipped.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| NDEV-01 | Plans 01, 02 | iOS host gains additive Dev scheme + Info-Dev.plist + dev fixture; prod Info.plist and proof fixtures untouched | SATISFIED | Dev.xcscheme, Info-Dev.plist, Debug-Dev pbxproj config, iOS dev fixture all verified; prod Info.plist contains no ATS keys; prod iOS fixture last touched by phase 121 |
| NDEV-02 | Plans 01, 03 | Android host gains additive dev flavor + network-security-config for 10.0.2.2; prod manifest/assets untouched; usesCleartextTraffic=false preserved | SATISFIED | app/build.gradle prod+dev flavors; dev AndroidManifest overlay with tools:replace; network_security_config_dev.xml scoped to 10.0.2.2 with base-config false; prod AndroidManifest untouched and verified |
| NDEV-03 | Plans 01, 04 | iOS simulator and Android emulator loads documented with exact CLI launch commands | SATISFIED | QUICK_START "Run Against the Local Backend (Dev Wiring)" section has copy-paste iOS xcodebuild command and Android installDevDebug + adb start command; quick_start_adoption_drift_test passes |

**Orphaned requirements:** None. All NDEV-01, NDEV-02, NDEV-03 requirements mapped and satisfied.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `script/verify_generated_android_shell.sh` | 214 | `XXXXXX` | Info | Standard `mktemp` template — not a debt marker; pre-existing pattern |

No debt markers (TBD/FIXME/XXX) found in any phase 126 modified files. The `XXXXXX` at line 214 is a `mktemp` template placeholder, not a debt marker — it was present before this phase.

### Additive Constraint Verification (Critical)

The phase's defining invariant — that ALL dev wiring must be additive and must NOT modify prod proof files — is verified at multiple levels:

1. **Git history:** No phase 126 commit (71eed13, b7fdf14, 254a807, b1ce781, c9042dd, f03b33d, cc6ce2b, b7d92c8, b4f83d0, a5138c0, 1f90989) appears in the git log for any of:
   - `examples/ios_shell_host/Fixtures/route_activation.json` (last: phase 121)
   - `examples/android_shell_host/app/src/main/assets/route_activation.json` (last: phase 121)
   - `examples/ios_shell_host/CrosswakeShell/Info.plist` (last: phase 13)
   - `examples/android_shell_host/app/src/main/AndroidManifest.xml` (last: phase 13)

2. **Content verification:** Prod `Info.plist` contains no `NSExceptionDomains`, `NSAllowsArbitraryLoads`, or `NSExceptionAllowsInsecureHTTPLoads`. Prod `AndroidManifest.xml` contains `usesCleartextTraffic="false"` and no reference to `network_security_config_dev`.

3. **Automated guard:** `test/crosswake/guides/native_dev_wiring_test.exs` Block A (proof-untouched) with anti-vacuity regression cases asserts these invariants programmatically and fails the build on any future regression.

### Human Verification Required

No items require human verification. All behavioral truths have passing automated test coverage. The advisory-native caveats (actual simulator/emulator loading Crosswake routes over the local backend at runtime) are explicitly documented as out-of-scope for this phase's automated evidence — they are covered by the `advisory_only: true` tag and the honest advisory-native voice in QUICK_START.

---

_Verified: 2026-06-22T18:00:00Z_
_Verifier: Claude (gsd-verifier)_
