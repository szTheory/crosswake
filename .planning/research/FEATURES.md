# Feature Research

**Domain:** Production mobile shell runtime line for a Phoenix-native OSS library (v4.0)
**Researched:** 2026-06-03
**Confidence:** HIGH (core rebuild/OTA policy, permission templates), MEDIUM (diagnostics export seam, Android verification closure pattern)

---

## Context and Framing

v4.0's five target features are not independent product additions. They are hardening
work on a shell that already exists and already ships in `examples/`. The correct
question per feature is not "should we build X?" but "what does X need to express to be
credible for production adopters, and how does it connect to the existing manifest /
doctor / support / shell surfaces?"

Anti-feature thinking is especially important here because Crosswake is route-policy-first
and shell-second. Any feature that makes the shell feel like the product — rather than the
route-policy contract — erodes the thesis.

---

## Feature Area 1: Native Runtime-Line Policy (OTA-safe vs. Rebuild Contract)

### What adopters expect

Teams running hybrid/embedded-webview-plus-native apps reason about change safety through
a simple binary: "did this change touch anything in the native binary?" If yes, a store
submission is required (full rebuild cycle). If no, the change can ship over-the-air
without store review.

The well-established industry pattern (Expo runtime versions, Capacitor, CodePush) is:

**OTA-safe changes** (web/server layer only):
- LiveView/Phoenix content changes
- Route configuration changes that only affect server-side routing logic
- Asset updates, copy, styling changes within the web layer
- Backend business logic, auth, and entitlement changes
- Crosswake library version bumps that only touch Elixir/Phoenix-side modules

**Forces a native rebuild** (binary layer changes):
- Adding or removing a native permission declaration (Info.plist / AndroidManifest.xml)
- Adding or updating a native entitlement (Entitlements.plist)
- Updating the iOS deployment target or minimum SDK version
- Updating or adding a native SDK dependency (Swift Package / Gradle dependency)
- Changing the WKWebView configuration or native bridge message handler registration
- Updating the Android JVM bridge code, package name, or signing config
- Any change to files inside the `ios/` or `android/` shell directories

**The compatibility window** is the range of native shell versions that can safely run
without a rebuild when the Crosswake library version changes. If the library change is
OTA-safe, the existing shell binary remains compatible. If the library change includes a
rebuild-required item, the compatibility window closes for that version pair.

The Expo `fingerprint` policy is the state-of-the-art pattern: the runtime version
increments automatically whenever anything that may impact the native runtime changes,
making incompatible OTA pushes impossible while requiring builds more frequently. The
`appVersion` policy is weaker but common — it relies on developer discipline to bump the
version when native code changes. Crosswake's policy contract should express something
equivalent: a machine-checkable criterion for whether a library version bump is
OTA-safe or forces a rebuild.

### Table Stakes (missing = shell runtime line is not credible)

| Feature | Why Expected | Complexity | Dependencies |
|---------|--------------|------------|--------------|
| Explicit OTA-safe vs. rebuild-required classification per library version bump | Adopters cannot confidently ship or pin shell versions without this; every hybrid runtime line publishes this — Capacitor, Expo, Cordova all do it | MEDIUM | Existing manifest/support matrix surface from v3.6; changelog pipeline from v3.3 |
| Compatibility window expression in support matrix | Operators need to answer "which shell version range is valid for my current Crosswake version?" | MEDIUM | `SupportMatrix` from v3.6; `mix crosswake.doctor` |
| Doctor check that detects version pair outside compatibility window | Without this, incompatibility is silent until runtime breakage | LOW | `mix crosswake.doctor` from v2/v3.6 |
| Rebuild-required flag in CHANGELOG entries | Every breaking native change must be labeled so adopters do not have to read diffs | LOW | Changelog pipeline from v3.3 |

### Differentiators

| Feature | Value Proposition | Complexity | Dependencies |
|---------|-------------------|------------|--------------|
| Fingerprint-style rebuild trigger list in doctor output | Surfaces the exact set of conditions that closed the compatibility window, not just a flag | MEDIUM | Doctor surface; manifest |
| Support matrix `rebuild_required: true/false` field surfaced per version pair | Operators can machine-read rebuild requirements across upgrade paths | MEDIUM | `SupportMatrix` from v3.6 |

### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Automatic OTA push / silent bundle swapping in the shell | Sounds like zero-downtime deploys | Would require Crosswake to own delivery infrastructure and claim OTA safety for content it cannot verify; Apple App Store rules restrict feature-level changes via OTA even when the mechanism is technically allowed | Document OTA-safe boundary; let the adopter's server/deployment system handle content delivery |
| Pinning Crosswake to a specific shell binary version at runtime | Would "solve" compatibility automatically | Hidden coupling between library version and binary state; breaks adopters who update the library through normal package management without knowing the shell pin | Explicit documented compatibility windows; doctor warning; adopter-owned upgrade path |
| Declaring shell compatibility globally across all native platforms in one flag | Simpler to understand | iOS and Android have distinct rebuild triggers and compatibility postures; collapsing them loses signal | Platform-specific compatibility fields in the matrix |

---

## Feature Area 2: Rebuild and Compatibility Matrix via Support Truth and Doctor

### What adopters expect

A compatibility matrix in a mobile library should answer:
- Which Crosswake version requires which minimum iOS/Android SDK/OS version
- Which shell version is required for a given Crosswake version
- Which changes are OTA-safe vs. require a native rebuild
- Whether the current installed combination is valid (doctor check)

The matrix is not just documentation — it is a machine-readable contract. Teams comparing
"what version of the library shipped with what shell" need this to be authoritative, not
aspirational. The pattern from Titanium, Capacitor, and React Native native modules:
a table with explicit minimum/maximum columns and a clear "rebuild required for upgrade"
column per row.

iOS-specific: Apple requires apps to keep pace with minimum supported iOS versions as part
of App Store review (apps must target current SDK within a year of new SDK release). The
compatibility matrix must express the iOS deployment target range and flag when a
Crosswake version requires a deployment target bump that forces a rebuild.

Android-specific: minSdkVersion and targetSdkVersion drive compatibility. Google Play
requires apps to target the current year's API level by August 31 each year. The matrix
must express the required minSdkVersion and targetSdkVersion and flag when they advance.

### Table Stakes

| Feature | Why Expected | Complexity | Dependencies |
|---------|--------------|------------|--------------|
| Crosswake version to shell version compatibility table (per platform) | Adopters must know which shell they need for a given library version without reading source | MEDIUM | `SupportMatrix` from v3.6 |
| Min/target iOS deployment target range per Crosswake version | App Store requires current SDK targeting; teams need advance warning | LOW | `SupportMatrix` |
| Min/target Android SDK version range per Crosswake version | Google Play enforcement is time-based; stale targets cause Play Store rejection | LOW | `SupportMatrix` |
| Doctor warning when current shell is outside compatibility window | Silent incompatibility is a production incident waiting to happen | LOW | `mix crosswake.doctor` |
| Doctor warning when iOS deployment target or Android minSdk is below required | Proactive upgrade warning prevents app store rejection surprises | LOW | `mix crosswake.doctor` |

### Differentiators

| Feature | Value Proposition | Complexity | Dependencies |
|---------|-------------------|------------|--------------|
| Upgrade path narrative in doctor output for out-of-window version pairs | "You need to rebuild the shell for this upgrade" is more actionable than a bare version mismatch | MEDIUM | Doctor; support matrix |
| Support matrix `mix crosswake.support_matrix` output with rebuild-required column | Machine-readable for adopters who script their upgrade verification | MEDIUM | `SupportMatrix` from v3.6 |

### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Automated migration scripts that mutate the shell's native files | Solves the upgrade problem automatically | Crosswake does not own the host app's native files; mutating them silently violates the host-owned authority principle established throughout v3.x | Upgrade guidance as doctor output; explicit adopter action required for native file changes |
| Cross-platform single-version claim ("Crosswake 4.0 supports iOS 16+ and Android 8+") without per-feature granularity | Marketing simplicity | Different capabilities require different OS minimums; a single claim hides which capabilities require which floor | Per-capability and per-platform matrix rows |

---

## Feature Area 3: iOS/Android Permission and Entitlement Templates (Host-Owned Generated Artifacts)

### What adopters expect

Permission and entitlement setup is one of the highest-friction parts of shipping a hybrid
app. Adopters expect the library to:
1. Tell them exactly which permissions and entitlements are required for which capabilities
2. Provide copy-pasteable or generated starting templates
3. Make it clear that the adopter owns these files, not the library

The "honest" requirement is critical. Apple's App Store review rejects apps that declare
permissions without usage descriptions or entitlements without demonstrated use. Since iOS
Spring 2024 (enforced from May 1, 2024), all iOS apps must include a `PrivacyInfo.xcprivacy`
file declaring required-reason API access (NSPrivacyAccessedAPITypes). Failing to include
accurate required-reason entries causes App Store rejection. This is not aspirational — it
is a hard review gate.

Android uses AndroidManifest.xml for permissions. Normal, dangerous, and signature
permissions have different behaviors. `dangerous` permissions (camera, location, contacts,
notification post) require runtime request dialogs. Permissions declared but not used can
trigger Play Store policy violations.

Entitlements (iOS-specific) are key-value pairs in Entitlements.plist that expand the
app sandbox. WKWebView-based shells may require specific entitlements for push
notifications (APS environment), app groups (shared container access), or associated
domains. These must match the provisioning profile exactly or the app fails to build.

The adopter ownership principle is: the library shows what is required and provides a
correct template; the adopter adds it to their project and signs it. The library must not
attempt to inject into or overwrite the adopter's native project files.

### Table Stakes

| Feature | Why Expected | Complexity | Dependencies |
|---------|--------------|------------|--------------|
| Documented per-capability permission requirements (iOS Info.plist keys + Android AndroidManifest.xml entries) | Adopters hit App Store / Play Store rejection without this; it is the most common first-time adopter failure | MEDIUM | Capability registry from v3.1; existing shell code |
| Generated or copy-pasteable Info.plist permission entry templates with usage description placeholders | Usage descriptions are required by Apple review; missing them = rejection; adopters must customize the strings | MEDIUM | Existing iOS shell in `examples/` |
| Generated or copy-pasteable AndroidManifest.xml permission entry templates | Same principle for Android; dangerous permissions need to be declared | LOW | Existing Android shell in `examples/` |
| iOS PrivacyInfo.xcprivacy template with NSPrivacyAccessedAPITypes entries for APIs used by the shell | Required by Apple since May 2024; missing = App Store rejection; WKWebView and common APIs have required-reason categories | HIGH | iOS shell; capability registry |
| iOS Entitlements.plist template for capabilities that require entitlements (push, associated domains) | Missing entitlements = build failure or app rejection | MEDIUM | iOS shell; Chimeway (v3.9) for APS environment entitlement |
| Doctor check that identifies missing permissions for enabled capabilities | Adopters should not learn about missing permissions from App Store review rejection | MEDIUM | `mix crosswake.doctor`; capability registry |

### Differentiators

| Feature | Value Proposition | Complexity | Dependencies |
|---------|-------------------|------------|--------------|
| Host-owned vs. library-injected language explicitly documented | Prevents the mistake of letting Crosswake touch native project files; keeps the contract honest | LOW | Generator surface from v1 |
| Per-capability permission/entitlement diff in doctor — "you enabled X, which requires Y" | More actionable than a static template; surfaces only what the adopter's current capability set requires | MEDIUM | Capability registry; doctor |
| Explicit guidance on which permissions are dangerous and require runtime request dialog | Adopters who miss this ship apps that silently fail on devices | MEDIUM | Docs surface |

### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Library-injected permission mutations (writing to Info.plist, AndroidManifest.xml, Entitlements.plist) | Automates a friction-heavy step | Crosswake does not own the host's native files; mutating them silently violates host-owned authority, prevents adopters from reasoning about their own entitlements, and can corrupt provisioning profiles | Generated templates + doctor guidance; adopter must apply them explicitly |
| Bundling a PrivacyInfo.xcprivacy on behalf of the adopter as a library artifact | Convenience | A library's PrivacyInfo.xcprivacy covers the library's own API usage, not the host app's; conflating the two causes an incomplete privacy manifest at review time | Separate: shell template (host-owned, generated) vs. library privacy manifest (Crosswake's own required-reason API usage if any) |
| "Enable all permissions" default template | Reduces adopter friction | Declares permissions the adopter may not use, triggering Play Store policy violations and App Store questions about unused permission requests | Capability-scoped templates that include only what the declared capabilities require |

---

## Feature Area 4: Crash and Diagnostic Export Seam

### What adopters expect

In hybrid/embedded-webview-plus-native architectures, crash attribution is hard because
a single user-visible failure can originate in three distinct layers:
1. The native shell (Swift/Kotlin crash, OOM, OS kill)
2. The web/LiveView layer (unhandled JS exception, network failure, WebView process termination)
3. The bridge (message dispatch failure, capability timeout, deserialization error)

Adopters expect:
- The shell to not swallow crash signals silently
- Some form of structured export that lets the adopter wire up their own crash reporter
  (Sentry, Crashlytics, Bugsnag, New Relic, etc.)
- The library to NOT ship a crash reporter of its own (dependency injection nightmare)
- Clarity about which layer a failure came from

The "seam" pattern is correct: the shell exposes callbacks / hooks that fire when something
goes wrong, and the adopter routes those events to whatever observability toolchain they
use. This keeps the library dependency-free on the observability side while giving adopters
actionable diagnostic signals.

For WebView/web-layer diagnostics, the shell needs to surface:
- WebView process termination (iOS: `webViewWebContentProcessDidTerminate`; Android:
  `onRenderProcessGone`)
- Navigation load failures with error codes
- Bridge message dispatch failures

For native-layer diagnostics, the shell exposes:
- Launch failure reasons (missing capabilities, compatibility mismatch)
- Route activation failures with denial codes
- Bridge timeout or malformed-message events

The existing Crosswake denial vocabulary and telemetry redaction posture (from v3.6-v3.9)
establishes the right baseline: structured, low-cardinality events with no raw tokens,
PII, or provider payloads. The diagnostic export seam should follow the same posture.

### Table Stakes

| Feature | Why Expected | Complexity | Dependencies |
|---------|--------------|------------|--------------|
| WebView termination callback seam in the iOS shell (webViewWebContentProcessDidTerminate equivalent) | WebView process kills are silent without this; adopters who hit OOM crashes have no signal | MEDIUM | Existing iOS shell WKWebView setup |
| WebView render process gone callback seam in the Android shell (onRenderProcessGone equivalent) | Same principle for Android WebView | MEDIUM | Existing Android shell WebView setup |
| Bridge error / dispatch failure export hook in both shells | Bridge failures are currently opaque; adopters wiring up observability need this | MEDIUM | Existing bridge contract |
| Structured diagnostic event taxonomy (layer attribution: native / web / bridge) | Without layer attribution, crash reporters show undifferentiated noise | MEDIUM | Existing telemetry posture from v3.6 |
| Guidance on wiring the seam to common crash reporters | Adopters do not know how to connect the seam to Sentry/Crashlytics without an example | LOW | Docs surface |

### Differentiators

| Feature | Value Proposition | Complexity | Dependencies |
|---------|-------------------|------------|--------------|
| Navigation failure export with Crosswake denial codes where applicable | Connects crash/diagnostic export to the existing denial vocabulary, making observability data actionable | MEDIUM | Denial vocabulary from v3.x |
| Shell readiness failure export at launch (compatibility mismatch, missing permissions, unsupported capability) | Surfaces setup errors as structured events rather than silent fallback or crash | MEDIUM | Doctor surface; compatibility matrix |
| Doctor check that verifies the diagnostic export seam is wired (detects no-op / missing hook) | Prevents adopters from shipping with diagnostics disabled | LOW | Doctor surface |

### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Crosswake shipping a first-party crash reporter / SDK dependency | Single-library convenience | Adds a non-optional native SDK dependency to every adopter's shell, forces a native rebuild if the SDK updates, creates licensing and privacy manifest complications | Diagnostic export seam + guidance; adopter chooses their reporter |
| Automatic crash report upload from the shell | Reduces operator effort | Requires network access, data collection consent, and crash reporter account setup that Crosswake cannot own; also risks shipping PII before the adopter has configured redaction | Seam-only; adopter handles upload |
| Raw WebView console log export in production | Useful for debugging | Production log export is a PII/token leak vector; LiveView socket traffic and route params can appear in console | Structured event taxonomy with redaction rules; debug-only console export |

---

## Feature Area 5: Android Verification Closure

### What adopters expect

The existing hermetic/advisory CI split (established in v3.2, validated repeatedly
through v3.9) is the correct pattern. Android verification closure for v4.0 means:

1. **CI-hermetic / merge-blocking**: JVM bridge tests and unit-level shell logic tests
   run in CI with no Android runtime required. These have run since v3.1 and are the
   existing merge-blocking evidence class.

2. **Advisory emulator/device lane**: An instrumented test lane that runs against an
   Android emulator (via `android-emulator-runner` GitHub Action on Ubuntu runners with
   hardware acceleration). This lane is advisory — it does not block PRs — but it has
   explicit promotion criteria that must be met before a production-ready claim is made.

3. **Device-UAT checklist**: A written checklist of behaviors that require physical device
   or real-user verification that CI cannot provide. For a CI-only / no-local-device
   maintainer, this checklist is the honesty instrument: it explicitly names what has not
   been proven hermetically, who is responsible for verifying it, and what the promotion
   path looks like.

The industry pattern for OSS mobile libraries with CI-only maintainers:
- Firebase Test Lab (free tier: 10 virtual + 5 physical device-hours/day): suitable for
  advisory lane on a scheduled workflow, not PR-blocking
- BrowserStack/Sauce Labs/AWS Device Farm: pay-per-use advisory cloud devices
- Emulator-based hermetic CI: fastest, most reproducible, suitable for merge-blocking
  logic tests; cannot prove hardware sensor behavior, real push delivery, or
  biometric/face ID flows

A credible device-UAT checklist for a CI-only maintainer distinguishes:
- **Emulator-provable**: UI rendering, route activation, bridge message dispatch,
  capability deny/grant flows in emulated environments
- **Device-advisory**: Physical sensor behavior (haptics feel, camera capture quality),
  real push delivery, Play Integrity attestation, biometric prompt appearance, real
  network handoffs (WiFi to cellular)
- **Provider-advisory**: Play Store review flow, in-app purchase transaction
  (Play Billing), real FCM delivery

The existing Crosswake pattern (advisory with explicit promotion criteria, documented in
doctor `promotion_path` output) maps exactly onto this structure.

### Table Stakes (Android verification closure is not credible without these)

| Feature | Why Expected | Complexity | Dependencies |
|---------|--------------|------------|--------------|
| Android emulator CI lane (advisory, scheduled) with `android-emulator-runner` on Ubuntu | Shows that the shell boots, navigates, and bridges correctly on a real Android runtime; fills the gap between JVM tests and physical device proof | MEDIUM | Existing Android shell + JVM CI from v3.1 |
| Explicit promotion criteria for the emulator/device advisory lane | Without criteria, "advisory" is just "untested"; criteria define what must pass before a "production verified" claim is made | LOW | Hermetic/advisory split pattern from v3.2 |
| Device-UAT checklist with explicit column for CI-provable vs. device-advisory vs. provider-advisory | Honest labeling of what the CI-only maintainer cannot prove | LOW | Doctor; support matrix |
| Doctor output that distinguishes CI-verified from advisory-only Android claims | Adopters should not treat JVM bridge test passage as full Android verification | LOW | Doctor surface |
| Emulator lane result surfaced in support matrix (merge-blocking vs. advisory state) | Keeps the advisory lane visible; prevents it from being quietly dropped | MEDIUM | `SupportMatrix` from v3.6 |

### Differentiators

| Feature | Value Proposition | Complexity | Dependencies |
|---------|-------------------|------------|--------------|
| Firebase Test Lab integration (scheduled advisory, free tier) for real-device matrix coverage | Elevates advisory lane from emulator-only to real-device coverage on a subset of API levels without hardware cost | HIGH | Android shell build pipeline |
| Advisory promotion criteria documented in `mix crosswake.doctor` output | Surfaces the checklist items that block production promotion directly in the developer tool | MEDIUM | Doctor surface |
| Explicit "verification closure" language in support matrix for Android | Communicates to adopters that Android support has a separate verification tier from CI-hermetic | LOW | `SupportMatrix` |

### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Claiming full Android verification from JVM tests alone | JVM tests are fast and reproducible | JVM tests do not exercise the Android runtime, WebView rendering, OS permission dialogs, or Play Integrity; calling them "verified" is dishonest about what is actually proven | Explicit hermetic/advisory split with labeled evidence classes |
| Blocking PRs on the emulator lane | Adds real-device-level confidence to every PR | Android emulator startup on CI is 5-10 minutes; emulator-dependent tests have non-zero flake rates; blocking PRs on a flaky lane destroys developer experience | Emulator lane advisory on schedule; merge-blocking stays JVM-only |
| Broad real-device provider farm (AWS Device Farm, BrowserStack) as merge-blocking | Maximum device coverage | External device farm latency, cost, and flake make it unsuitable for PR blocking; adds external service dependency to the merge gate | Advisory scheduled lane with provider farm; document result in support matrix |

---

## Feature Dependencies

```
[Native Runtime-Line Policy]
    └──expressed in──> [Compatibility Matrix / Support Truth]
                           └──surfaced by──> [mix crosswake.doctor]
                           └──communicated via──> [CHANGELOG rebuild-required flags]

[Permission/Entitlement Templates]
    └──driven by──> [Capability Registry (v3.1)]
    └──verified by──> [mix crosswake.doctor]
    └──requires input from──> [iOS PrivacyInfo.xcprivacy requirements (Apple 2024)]

[Crash/Diagnostic Export Seam]
    └──follows posture of──> [Denial vocabulary + telemetry redaction (v3.6-v3.9)]
    └──surfaces via──> [Structured events with layer attribution]
    └──verified by──> [Doctor hook-wired check]

[Android Verification Closure]
    └──depends on──> [Existing JVM CI hermetic lane (v3.1+)]
    └──extends to──> [Advisory emulator lane]
    └──expressed in──> [Compatibility Matrix / Support Truth]
    └──documented in──> [Device-UAT checklist]
    └──surfaced by──> [mix crosswake.doctor]
```

### Dependency Notes

- Compatibility matrix requires existing support truth surface: `SupportMatrix` from
  v3.6 is the canonical surface; v4.0 adds fields (rebuild_required, shell_version_range,
  min_ios_target, min_android_sdk) rather than replacing it.
- Permission templates require capability registry: Templates should be scoped to
  what the adopter's declared capabilities actually require, not a blanket list. This
  ties the template generation to the capability registry from v3.1.
- Diagnostic export seam follows telemetry posture from v3.6-v3.9: No raw tokens,
  PII, route params, or provider payloads. Same redaction rules apply.
- Android verification closure extends, not replaces, the hermetic/advisory split:
  The JVM lane stays merge-blocking; the emulator lane is advisory. The split is the same
  pattern used in v3.2 (commerce), v3.7 (provider), v3.8 (auth), v3.9 (notification).
- PrivacyInfo.xcprivacy is a hard iOS gate since May 2024: This is not a nice-to-have;
  it is a current App Store review requirement. It must be in the template scope.

---

## MVP Definition (for v4.0)

All five feature areas are in scope for v4.0. The MVP within each area is the table-stakes
items. Differentiators are worth shipping if they fit within the milestone without
requiring new surfaces; defer to v4.1 if they require significant new infrastructure.

### Launch With (v4.0 minimum)

- [ ] OTA-safe vs. rebuild-required classification per library version change, expressed
      in the changelog and support matrix
- [ ] Compatibility matrix fields in `SupportMatrix` (shell version range, min iOS
      target, min Android SDK, rebuild_required) — machine-readable
- [ ] Doctor checks for version out-of-window, iOS deployment target below floor, Android
      minSdk below floor
- [ ] Per-capability permission/entitlement requirement docs and copy-pasteable templates
      for iOS Info.plist, Entitlements.plist, PrivacyInfo.xcprivacy, and Android
      AndroidManifest.xml
- [ ] Doctor check for missing permissions given enabled capabilities
- [ ] WebView termination / render-process-gone callback seams in both shells
- [ ] Bridge dispatch failure export hook in both shells
- [ ] Structured diagnostic event taxonomy (layer: native/web/bridge) following existing
      telemetry redaction posture
- [ ] Android emulator advisory CI lane (scheduled, not PR-blocking) with explicit
      promotion criteria
- [ ] Device-UAT checklist with CI-provable vs. device-advisory vs. provider-advisory
      columns and honest labels

### Add After Validation (v4.x)

- [ ] Firebase Test Lab integration in the advisory lane (trigger: emulator lane proves
      sufficient but real-device matrix coverage is worth the setup cost)
- [ ] Doctor output of advisory promotion criteria for Android verification closure
      (trigger: emulator lane is stable and adopters ask about production verification
      criteria)
- [ ] Per-capability permission/entitlement diff in doctor output (trigger: adopter
      feedback that the static template is too broad)

### Future Consideration (v4.1+)

- [ ] Fingerprint-style rebuild trigger list exposed in doctor output — depends on
      compatibility matrix being stable across two milestones
- [ ] Rebuild trigger detection automation (flag when a PR would require a rebuild based
      on changed files) — high complexity, deferred until the policy is proven stable

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| OTA-safe vs. rebuild-required classification in changelog + support matrix | HIGH | MEDIUM | P1 |
| Compatibility matrix fields in SupportMatrix | HIGH | MEDIUM | P1 |
| Doctor: version out-of-window + deployment target / minSdk floor warnings | HIGH | LOW | P1 |
| iOS permission + Entitlements.plist + PrivacyInfo.xcprivacy templates | HIGH | MEDIUM | P1 |
| Android AndroidManifest.xml permission templates | HIGH | LOW | P1 |
| Doctor: missing permissions for enabled capabilities | HIGH | MEDIUM | P1 |
| WebView termination / render-process-gone seam (both shells) | HIGH | MEDIUM | P1 |
| Bridge dispatch failure export hook | HIGH | MEDIUM | P1 |
| Structured diagnostic event taxonomy (layer attribution) | HIGH | MEDIUM | P1 |
| Android emulator advisory CI lane with promotion criteria | HIGH | MEDIUM | P1 |
| Device-UAT checklist (CI vs. device vs. provider columns) | HIGH | LOW | P1 |
| Upgrade path narrative in doctor for out-of-window pairs | MEDIUM | MEDIUM | P2 |
| Support matrix rebuild-required column readable by mix crosswake.support_matrix | MEDIUM | MEDIUM | P2 |
| Per-capability permission diff in doctor (not full static template) | MEDIUM | HIGH | P2 |
| Doctor: diagnostic export seam wired check | MEDIUM | LOW | P2 |
| Firebase Test Lab advisory lane integration | MEDIUM | HIGH | P3 |
| Fingerprint-style rebuild trigger detection | MEDIUM | HIGH | P3 |

---

## Sources

- [Bitrise: What App Stores allow with OTA updates](https://bitrise.io/blog/post/what-app-stores-allow-with-ota-updates-apple-and-google-policy-explained) — MEDIUM confidence; policy details verified against Expo docs
- [Expo runtime versions documentation](https://docs.expo.dev/eas-update/runtime-versions/) — HIGH confidence; authoritative Expo source on fingerprint/appVersion/nativeVersion policies
- [Expo CNG documentation](https://docs.expo.dev/workflow/continuous-native-generation/) — HIGH confidence; authoritative source on config plugin and permission generation pattern
- [Codemagic: React Native OTA what can be deployed](https://blog.codemagic.io/react-native-ota-what-can-be-deployed/) — MEDIUM confidence; practical rebuild-trigger list
- [Codemagic: React Native OTA Updates Guide 2026](https://blog.codemagic.io/react-native-ota-updates-guide/) — MEDIUM confidence; current state of OTA tooling
- [Apple Developer: Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files) — HIGH confidence; official Apple documentation
- [Apple Developer: Adding a privacy manifest to your app or third-party SDK](https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk) — HIGH confidence; official Apple enforcement documentation
- [Bitrise: Enforcement of Apple Privacy Manifest starting from May 1, 2024](https://bitrise.io/blog/post/enforcement-of-apple-privacy-manifest-starting-from-may-1-2024) — HIGH confidence; confirms enforcement date
- [Capgo: Privacy Manifest for iOS Apps](https://capgo.app/blog/privacy-manifest-for-ios-apps/) — MEDIUM confidence; practical guidance
- [Android Emulator Runner GitHub Action](https://github.com/marketplace/actions/android-emulator-runner) — HIGH confidence; standard mechanism for Android emulator CI
- [Android Developers: Types of CI automation](https://developer.android.com/training/testing/continuous-integration/automation) — HIGH confidence; official Android documentation on hermetic vs. instrumented test classification
- [Firebase Test Lab](https://firebase.google.com/docs/test-lab) — HIGH confidence; official Firebase documentation
- [Google OSS Library Breaking Change Policy](https://opensource.google/documentation/policies/library-breaking-change) — HIGH confidence; establishes major version bump and migration note requirements for breaking native changes
- [New Relic Android: native crash tracking](https://docs.newrelic.com/docs/mobile-monitoring/mobile-monitoring-ui/crashes/investigate-mobile-app-crash-report/) — MEDIUM confidence; crash export seam pattern reference
- [Median.co: WebView app diagnostics guide](https://median.co/blog/how-to-troubleshoot-webview-apps-debugging-guide) — MEDIUM confidence; layer-attribution diagnostic tooling overview

---

*Feature research for: v4.0 Production Shell Runtime Line (Crosswake)*
*Researched: 2026-06-03*
