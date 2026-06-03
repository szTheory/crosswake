# Pitfalls Research

**Domain:** Production shell runtime line added to a route-policy-first Phoenix library that ships checked-in iOS/Android shells (Crosswake v4.0)
**Researched:** 2026-06-03
**Confidence:** HIGH — grounded in PROJECT.md + MILESTONE-ARC.md locked guardrails, Apple App Store Review Guidelines (current as of April 2026 Xcode 26 SDK mandate), Google Play policy deadlines (Android 15 / API 35 target requirement enforced August 2025 + August 2026), and multi-source verification of each claim.

---

## Critical Pitfalls

### Pitfall 1: Dishonest Support Truth — Claiming "Verified" Without Real Device Evidence

**What goes wrong:**
The compatibility matrix or doctor output lists a platform/OS version pair as `:verified` when the only evidence is CI hermetic (Elixir contract tests + Android JVM bridge tests + Swift compile checks). No physical device — and no cloud device farm — has ever run the shell against that target. Adopters ship to production assuming real-device compatibility is proven.

This maps directly to MILESTONE-ARC's open research flag: "What minimum Android evidence is required to move shell support from 'verification required' to fully verified?" If that question is not answered with an explicit promotion criterion before v4.0 ships, every row in the SupportMatrix that reads `:verified` is a silent lie.

The same failure mode applies to iOS: an Xcode 26 simulator build passing CI does not verify that the shell behaves correctly on physical iPhone hardware (e.g. entitlement checks, biometric sensor availability, battery-state permissions, hardware-accelerated camera for `file_picker`/Rindle flows).

**Why it happens:**
CI hermetic passes consistently. Device evidence requires provisioned hardware, cloud device farm costs, or explicit coordinator time. The support matrix is populated from the hermetic result because it is the closest thing to evidence available. "CI passed" gets promoted to "verified" without a defined promotion rubric.

**How to avoid:**
1. Define exactly two support truth states: `:hermetic_only` (CI-verified, no device evidence) and `:verified` (hermetic + at least one real-device or promotion-criteria promotion). Never use `:verified` for CI-only rows.
2. The native runtime-line policy (Phase 1 of v4.0) must codify these two states as named constants with explicit promotion criteria before any matrix population happens.
3. Doctor output must surface `:hermetic_only` rows as actionable warnings, not silent passes, so operators know the real evidence gap.
4. The Android verification closure plan (v4.0 feature 5) must define the minimum device-UAT scenarios required before a row can be promoted to `:verified` — this is the answer to the open research flag.

**Warning signs:**
- SupportMatrix has `:verified` rows that cite only a CI run ID (no device/farm evidence attached).
- The `mix crosswake.doctor` summary says "all platforms verified" when no device sessions have run.
- Promotion criteria comment in the CI workflow is missing or says "TBD."
- The rebuild policy contract references `:verified` platform ranges without a linked evidence artifact.

**Phase to address:**
Phase defining native runtime-line policy and SupportMatrix states (first v4.0 phase). States and promotion criteria must be locked before any other phase populates the matrix.

---

### Pitfall 2: Compatibility-Window / Rebuild-Policy Drift Between Manifest, Shell, and Docs

**What goes wrong:**
The manifest encodes `min_shell_version: "2.1"` and `min_ios: "16.0"`. The shell's Swift `Info.plist` has `LSMinimumSystemVersion` set to `"17.0"`. The docs say "iOS 15 and above." Three sources, three different answers. An adopter builds for iOS 15 and gets a crash on launch because the shell requires 17. Another adopter holds back from iOS 17 features because the docs (lowest number) say 15 is supported.

The same drift occurs across: Crosswake library version (in `mix.exs`), the manifest `compatibility.crosswake_version` range, the shell's `Crosswake-Version` HTTP header it sends, the doctor's "shell compatibility" check, the SupportMatrix table in `guides/native.md`, and the `CHANGELOG.md` rebuild notice. All six surfaces must agree or adopters face silent mismatch.

**Why it happens:**
Version ranges are updated one place (manifest, or docs, or the shell's native file) and the others are forgotten. The changes are in different languages and files (Elixir manifest, Swift Info.plist or Package.swift, Kotlin/Gradle build.gradle, Markdown docs), so no single linter or test catches cross-surface drift.

**How to avoid:**
1. The compatibility truth must have exactly one source: a machine-readable record in the Crosswake library (e.g. a module or config file) that both the manifest generator and the docs-contract test read from. Neither the shell native files nor the guides should be the authoritative source.
2. Checked-in shell files must reference the same range values from the Crosswake library's canonical compatibility record, or carry an explicit version comment that the docs-contract test scans and verifies against the canonical record.
3. A merge-blocking docs-contract test must assert that: (a) the guide's SupportMatrix table values match the canonical record, (b) the manifest `compatibility` field values match the canonical record, and (c) the shell fixture's minimum deployment target matches the canonical record.
4. Any PR that changes the compatibility range must update all three surfaces; the docs-contract test catches any incomplete update at merge time.

**Warning signs:**
- `mix crosswake.doctor` reports a different min iOS version than `guides/native.md`.
- The shell fixture Swift file has a deployment target that differs from the manifest's `min_ios` by more than one major version.
- A changelog entry mentions a rebuild requirement but doesn't update the manifest compatibility field.
- Doctor passes, but an adopter on a platform version inside the doctor's "supported" range gets a shell startup crash.

**Phase to address:**
Phase defining the rebuild and compatibility matrix (v4.0 Phase 2). The canonical record and the docs-contract test that locks all surfaces together must ship in the same phase as the matrix — never deferred.

---

### Pitfall 3: Rebuild Policy That Under-Claims or Over-Claims OTA Safety

**What goes wrong:**
Two symmetric failure modes:

**3a. Over-claiming OTA safety.** The rebuild policy contract says a capability-registry expansion (adding a new bridge command) is OTA-safe. An adopter ships the Crosswake library update without a native rebuild. The new bridge command silently fails because the native shell does not recognize it. No crash — just `:capability_unavailable` denials that the adopter did not anticipate and for which there is no clear error path.

**3b. Under-claiming OTA safety.** The rebuild policy says any library patch version requires a native rebuild. Adopters ignore the rule (perceived as overly conservative) and ship OTA anyway, which works fine for minor patches. The policy loses credibility and adopters stop following it, even for changes that genuinely require a rebuild (e.g. bridge envelope schema changes, entitlement XML changes, capability registry additions).

Platform policy reality (confirmed mid-2026): Apple requires App Store review for any native binary change, any Info.plist entitlement change, any push notification capability change, and any new privacy manifest declaration. WebKit/JavaScript-layer content updates to WKWebView are OTA-safe only if they do not change the app's primary purpose (Guideline 2.5.2 — enforced with heightened scrutiny in 2026). LiveView HTML/CSS updates rendered inside WKWebView are unambiguously OTA-safe. Bridge command vocabulary changes embedded in the shipped JS bundle that bridge to new native functions added post-review are not OTA-safe — they require App Store review of the native binary that handles the new function.

**Why it happens:**
The rebuild policy is written by the library maintainer (Elixir/Phoenix context) who reasons about OTA from a web deployment mindset. Native rebuild requirements have a higher cost and are easy to under-specify when the Elixir side has no real-device CI evidence to confirm what actually breaks.

**How to avoid:**
1. The rebuild policy must enumerate exactly which change classes force a native rebuild, with explicit rationale for each: bridge command schema change, new capability family, entitlement/permission addition, minimum SDK version bump, privacy manifest entry addition, push notification capability change, shell URL scheme change.
2. Changes that are OTA-safe must be equally explicit: Crosswake library patch versions that touch only Elixir-side manifest/policy logic with no change to bridge vocabulary, capability registry, or permission templates.
3. The rebuild policy contract should be machine-readable (an attribute or typespec comment in the Crosswake library) so the doctor can evaluate whether a library version upgrade requires a rebuild before the adopter ships.
4. The policy must be reviewed against current App Store Review Guidelines (2.5.2) and Google Play policy at each new major Crosswake version. The person reviewing must check the current guidelines directly — not rely on training data.

**Warning signs:**
- Rebuild policy lists "bridge command additions" as OTA-safe.
- Policy lists "any Crosswake patch version" as requiring a rebuild with no distinction.
- Doctor does not distinguish between "library upgrade is OTA-safe" and "library upgrade requires rebuild."
- Policy documentation references App Store 2.5.2 but was last reviewed more than six months ago.

**Phase to address:**
Phase defining native runtime-line policy (v4.0 Phase 1). The OTA-safe vs. rebuild-required taxonomy must be complete before permission templates or the diagnostics seam are built, because both of those are rebuild-triggering changes.

---

### Pitfall 4: Permission / Entitlement Templates That Drift From Declared Capabilities

**What goes wrong:**
The iOS `Info.plist` template includes `NSCameraUsageDescription` because the Rindle media companion needs it. Later, a host app doesn't include Rindle and removes the Rindle companion from its route policy. But the permission string stays in the Info.plist template (because it's a generated static template, not regenerated from the current capability set). The app now declares a camera permission it doesn't use. Apple's privacy manifest rules flag "excessive permission requests" and the app is rejected in review — or, worse, it passes review but users see a camera permission prompt for a feature the app never uses, eroding trust.

The symmetric failure: a capability that genuinely requires a permission (e.g. `notification_token` requires `UNUserNotificationCenter` authorization; `file_picker` on Android requires `READ_MEDIA_IMAGES` on API 33+) is omitted from the generated template because the template was hand-authored from a snapshot of enabled capabilities that was later updated without regenerating the template. The app crashes or silently fails at runtime when the capability is invoked.

**Why it happens:**
Permission templates are generated once at scaffold time, then checked in. They are not regenerated as the route policy or capability registry evolves. The link between "capability declared in route policy" and "permission required in template" is undocumented and informal, so drift accumulates invisibly.

**How to avoid:**
1. The permission template generator must be deterministic and re-runnable: given the current route policy + capability registry, it must produce the exact set of permissions required — no more, no less.
2. Doctor must check whether the checked-in permission template is consistent with the current capability declarations and emit a warning when drift is detected.
3. The template generation must be a mix task (or mix generator step) that adopters can re-run, not a one-time scaffold output.
4. Permissions must be documented per-capability in the capability registry: each capability entry should declare which iOS usage description keys and Android permission strings it requires. The template generator reads from this registry, not from a hand-maintained list.
5. The docs-contract test must assert that the guide's "required permissions" table matches the capability registry's permission declarations.

**Warning signs:**
- The checked-in iOS `Info.plist` has usage description keys for capabilities not declared in any route's `required_capabilities`.
- The Android `AndroidManifest.xml` template has `uses-permission` declarations not tied to any registered capability.
- Running the template generator produces a different output than the checked-in template.
- Doctor reports "all capabilities supported" but doesn't cross-check against permission template contents.

**Phase to address:**
Phase building iOS/Android permission and entitlement templates (v4.0 Phase 3). The capability-to-permission mapping in the registry must be defined in the same phase as the generator, not after.

---

### Pitfall 5: Apple App Review Traps — Entitlement Mismatch, Privacy Manifest Gaps, Xcode SDK Requirement

**What goes wrong:**
Three concrete Apple review traps that block or reject shell submissions:

**5a. Entitlement mismatch between template and provisioning profile.** The shell entitlements file (`.entitlements`) declares a capability (e.g. `com.apple.developer.push-notifications`) that is not enabled in the provisioning profile, or vice versa. The app installs fine in development but gets ITMS-90111 rejection or a runtime crash on launch from App Store builds because iOS checks entitlements against the code signature at launch time. (As of iOS 26, Apple added some leniency for certain type mismatches, but entitlement-presence mismatches still hard-fail.)

**5b. Missing privacy manifest for a bundled SDK.** Since May 2024 (enforced continuously), every third-party SDK bundled in the app must have a `PrivacyInfo.xcprivacy` file. From February 2025, this applies to new SDK additions too. If the Crosswake-generated shell includes a dependency (e.g. a crash reporter, a logging SDK, or any analytics library) that doesn't have a current `PrivacyInfo.xcprivacy`, the app is blocked before human review begins. This is especially dangerous if the permission/entitlement template phase adds new SDK dependencies.

**5c. Xcode 26 SDK requirement (enforced April 28, 2026).** Any new app or update submitted after April 28, 2026 must be built with the iOS 26 / iPadOS 26 SDK (Xcode 26). The generated shell's CI build must use Xcode 26 or later. If the CI action uses a pinned Xcode version below 26, submissions fail with a hard SDK version rejection. This is not a warning — it is a hard gate.

**Why it happens:**
5a: Entitlements and provisioning profiles are maintained separately by the host app developer. The template ships with an entitlements file, but the developer's Apple Developer account portal must have the matching capability enabled. The link between the template and the portal is documented in guides but not enforced mechanically.

5b: SDK privacy manifests are a relatively new requirement (enforced broadly since 2024) and easy to miss when third-party library versions are updated. The Crosswake shell itself might not have direct SDK dependencies, but any crash reporter or logging library the adopter adds to the shell will need one.

5c: CI Xcode versions are often pinned to avoid surprise builds and go stale.

**How to avoid:**
1. The entitlements template must carry an explicit comment for each entry: what capability it enables, what the provisioning profile portal step is, and what the rejection code will be if the profile is missing it. Doctor should check for entitlement-profile parity using `codesign --display --entitlements` output in the advisory lane.
2. The shell guide must include a "Privacy Manifest Checklist" section that lists every first-party Crosswake dependency and whether it has a `PrivacyInfo.xcprivacy`. Adopters adding crash reporters or analytics must be explicitly instructed to verify privacy manifest coverage before submission.
3. The CI shell build action must pin Xcode 26+ and include a step that asserts the SDK version against the Apple Upcoming Requirements page. The pinned version must be reviewed and updated at each major Crosswake release.
4. The permission/entitlement template phase must add a docs-contract test that asserts the guide's "entitlements required" section is parity-locked to the `.entitlements` template file contents.

**Warning signs:**
- CI Xcode version is pinned below 26 (any `xcode-version: "15.x"` or `xcode-version: "16.x"` in the CI workflow as of mid-2026).
- The `.entitlements` template has push notification entitlements but the guide doesn't document the portal capability step.
- No `PrivacyInfo.xcprivacy` in the shell or in any bundled dependency.
- Doctor passes with no advisory notes about entitlement-to-provisioning-profile verification.

**Phase to address:**
Phase building iOS permission and entitlement templates (v4.0 Phase 3). Xcode SDK version assertion belongs in the same phase as the CI shell build workflow update.

---

### Pitfall 6: Google Play Policy Traps — OTA Executable Download, Target SDK Drift, Play Integrity Gap

**What goes wrong:**
Three Android-specific store policy failure modes:

**6a. OTA executable code download (Play Policy §4.4).** Google Play policy prohibits apps from downloading executable code (dex, JAR, `.so` files) from any source other than Play. If the Crosswake shell ever bridges to a mechanism that downloads and loads a native library or compiled plugin at runtime, the app is in violation and subject to removal. The bounded bridge thesis already prevents this — but if a diagnostics export or crash reporter seam adds a "download updated reporter SDK" flow to the shell, that crosses the line.

**6b. Target SDK version falling below the required floor.** As of August 2025, new submissions and updates must target Android 15 (API level 35). Existing apps must also meet this floor. The Crosswake-generated Android shell's `build.gradle` `targetSdkVersion` must stay at or above the current Google Play floor. If the shell template is generated with a hardcoded `targetSdkVersion = 34` and the floor advances to 35 (or 36 in a future cycle), adopters who haven't updated the template will have submissions rejected. Google sends advance notice but rejections are hard gates.

**6c. Play Integrity API replacing SafetyNet (fully deprecated January 2025).** SafetyNet Attestation is permanently off as of May 2025. Any shell code or companion that used SafetyNet will silently fail or throw. If the diagnostics export seam or a CI hermetic test checks device integrity via SafetyNet, it will always return an error (not a meaningful verdict). Play Integrity API requires separate onboarding, quota allocation, and backend verification infrastructure.

**Why it happens:**
6a: Diagnostics export seams often look to "smart update" their reporting libraries — it seems like a good DX improvement.
6b: `targetSdkVersion` is set once in the template and never revisited unless a rejection forces it.
6c: SafetyNet references are copied from old code or documentation; the deprecation happened mid-development cycle and not every place was updated.

**How to avoid:**
1. The rebuild policy contract must explicitly list `targetSdkVersion` bump as a rebuild-required change. The doctor must check the current Play floor requirement against the shell template's declared `targetSdkVersion` and warn when they diverge.
2. The shell template's `build.gradle` must use a variable (e.g. `ext.targetSdk = 35`) and the doctor must cross-check this against the rebuild policy's declared minimum.
3. The diagnostics/crash export seam must be documented as host-owned with no Crosswake-side library download or dynamic loading.
4. Any CI test that references SafetyNet must be replaced with Play Integrity API with a debug provider in CI environments (Firebase App Check's debug provider is the standard CI escape hatch).

**Warning signs:**
- Shell template has hardcoded `targetSdkVersion 34` in `build.gradle` with no variable.
- Any reference to `com.google.android.gms:play-services-safetynet` in the shell template's dependencies.
- Doctor does not check or report the shell's declared `targetSdkVersion`.
- Diagnostics seam design includes a "self-update SDK" step.

**Phase to address:**
Phase defining the rebuild policy contract (v4.0 Phase 1) must include the `targetSdkVersion` floor rule. The shell template build file must be updated in the Android verification closure phase (v4.0 Phase 5) at the latest, but the policy must predate it.

---

### Pitfall 7: Diagnostics / Crash Export That Leaks PII, Tokens, or Route Parameters

**What goes wrong:**
The crash/diagnostic export seam attaches contextual data to crash reports or diagnostic exports: the current route ID, capability status, session state, or recent bridge commands. Among this context, a crash in the Sigra auth flow includes the raw session token or handoff ticket in the crash metadata. A bridge command diagnostic includes raw capability arguments (which may contain file paths with user content). A notification-open diagnostic includes the raw notification payload (which contains push token, route parameters, and possibly user IDs).

This violates the low-frequency bounded-bridge thesis and Crosswake's established telemetry rule from v3.9 (Chimeway): "low-cardinality telemetry that forbids raw tokens, payloads, route params, and PII." It also creates a privacy manifest obligation: if crash reports include user-identifying data, the PrivacyInfo.xcprivacy must declare it, and the App Store privacy nutrition label must reflect it accurately.

**Why it happens:**
Crash reporters are most useful when they have maximum context. The default configuration for most crash SDKs (Crashlytics, Sentry, Bugsnag) sends all set custom keys and breadcrumbs to their cloud service. A bridge command handler that logs its command and arguments for debugging will include those arguments in the next crash report if the logger is wired to the crash reporter's breadcrumbs. Session tokens end up in breadcrumbs because they are logged at session start.

**How to avoid:**
1. The crash/diagnostic export seam must define an explicit redaction interface: only a fixed, allowlisted set of diagnostic keys may be exported. The allowlist must be defined in the seam contract, not left to adopter discretion.
2. The allowlisted diagnostic keys must match the low-cardinality telemetry rules already established for Chimeway and Sigra: route ID (but not route parameters), capability name (but not capability arguments), shell version, Crosswake library version, session state label (e.g. `:authenticated`, `:anonymous`) — not session tokens or handoff tickets.
3. Bridge command diagnostics must strip all command arguments before export; only command name and outcome are allowed.
4. The diagnostic seam guide must include an explicit "What Is Never Exported" section mirroring v3.9's telemetry non-claims: no raw tokens, no provider payloads, no route params, no PII, no full notification payloads.
5. A docs-contract test must assert the guide carries these non-claims and that the seam's exported key allowlist matches the guide's declarations.

**Warning signs:**
- Diagnostic export includes a `session_token` key or any key with a value that looks like a JWT or UUID tied to a specific user session.
- Bridge command diagnostic export includes a `command_args` or `payload` field.
- Notification-open diagnostic includes the raw notification dictionary.
- Crash report custom keys include route parameters (e.g. `route_params: %{id: "user-123"}`).
- The privacy manifest or App Store privacy label says "no data collected" but the crash reporter is sending user-correlated crash data.

**Phase to address:**
Phase building the crash/diagnostic export seam (v4.0 Phase 4). The redaction allowlist and the docs-contract test must be in the same phase as the seam implementation — never deferred to a "privacy cleanup" phase.

---

### Pitfall 8: Diagnostics Export Violating the Low-Frequency Bounded-Bridge Thesis

**What goes wrong:**
The diagnostics export seam becomes a high-frequency channel. Every bridge command invocation emits a diagnostic event. The shell sends a diagnostic ping on every route transition. The diagnostics export batches 50 events per minute. The bounded bridge thesis (locked in MILESTONE-ARC) requires bridge contracts to be "semantic, typed, versioned, and low-frequency." A diagnostics channel that fires on every native interaction is not low-frequency and creates a continuous authority-adjacent signal that undermines the route-local, fail-closed posture of the capability system.

The risk is compounded on Android where a continuous diagnostic channel can affect battery, wake locks, and Play's background process limits. On iOS, continuous background network activity from a diagnostics channel that batches in the background requires `UIBackgroundModes` declaration, which requires App Store entitlement review.

**Why it happens:**
Diagnostics channels are commonly built with "emit everything, filter later" logic to aid debugging. This is reasonable for development builds but not for the shipped seam contract.

**How to avoid:**
1. The crash/diagnostic export seam must be defined as a crash-triggered or explicit-export-triggered channel, not an event-stream channel. Diagnostic data is written to local storage and exported only on crash or on explicit host invocation.
2. The bridge vocabulary for diagnostics must be typed and bounded: one command for "export diagnostic snapshot," one command for "clear diagnostic log" — not a streaming or subscription channel.
3. The seam contract must explicitly state the maximum export frequency (e.g. "exported at most once per session or on crash") and include this in the guide's "Design Constraints" section.
4. If real-time diagnostic streaming is needed for development builds, it must be gated behind a debug-mode flag that is off in production and not part of the public seam contract.

**Warning signs:**
- The diagnostics bridge command fires inside a capability request handler (i.e. it is called on every capability invocation).
- The seam design includes a `subscribe_to_diagnostics/1` or `stream_diagnostics/1` command.
- The Android shell has a background `WorkManager` job that polls and sends diagnostic data on a schedule.
- The iOS shell registers `fetch` or `processing` background modes for the diagnostic channel.

**Phase to address:**
Phase building the crash/diagnostic export seam (v4.0 Phase 4). The "export-only, not stream" constraint must be in the seam design document before implementation starts.

---

### Pitfall 9: CI-Only Android Verification Giving False Confidence About Shell Correctness

**What goes wrong:**
The Android verification closure consists entirely of: (a) JVM bridge tests that run on the host JVM (no Android runtime), (b) a Gradle build compile check, and (c) possibly a lint step. No emulator or physical device ever runs the shell. The SupportMatrix says "Android verified" and doctor shows green. An adopter ships to Google Play and discovers:

- The shell's WKWebView-equivalent (`WebView`) fails to load a LiveView page behind a self-signed cert in staging because the network security config is not set correctly.
- Deep link routing works in CI JVM tests but fails on device because the `intent-filter` schema in `AndroidManifest.xml` doesn't match the route pattern format the Crosswake manifest generates.
- The bounded bridge's JSON deserialization works in JVM tests but fails on older Android API levels due to SDK version behavior differences in `org.json`.
- Camera permission flow works in JVM tests but fails on a device running Android 14 because the file picker picker prompt requires `READ_MEDIA_IMAGES` (API 33+) not just `READ_EXTERNAL_STORAGE`.

**Why it happens:**
The project has an explicit hard constraint: no local Java runtime, Android JVM/emulator evidence is CI-only. This is a legitimate constraint for the maintainer's setup. But it creates a structural evidence gap: JVM bridge tests prove the Elixir-Kotlin message contract, not actual Android runtime behavior. The gap between JVM-test correctness and on-device correctness is not zero, and it can produce real failures in production.

**How to avoid:**
1. The Android verification closure must document the evidence gap explicitly and prominently in the guide and in the SupportMatrix: "Android hermetic CI proves bridge contract correctness on the JVM. Android device behavior (intent resolution, permission flows, WebView rendering, SDK version compatibility) requires device-UAT checklist completion before claiming `:verified` status."
2. The device-UAT checklist (v4.0 Phase 5) must list the categories that JVM tests cannot cover: deep link intent resolution, runtime permission flows, WebView network config, SDK API version behavior differences, hardware sensor availability.
3. Advisory emulator lanes must use the standard CI debug provider escape hatch (not Play Integrity — that requires real hardware for strong verdict) and must be marked `continue-on-error: true` with explicit promotion criteria matching the pattern from v3.7 and v3.9.
4. The SupportMatrix `android_status` field must distinguish `:jvm_hermetic` (CI-proved bridge contract) from `:device_verified` (UAT checklist + emulator/device evidence) — using a single `:verified` status for JVM-only evidence is a dishonesty trap.

**Warning signs:**
- SupportMatrix shows `android: :verified` with only CI run IDs from JVM bridge test jobs.
- The Android shell guide says "tested on Android 14" but the only evidence is Gradle compile + JVM tests.
- The device-UAT checklist doesn't exist or has no entries for permission flows, intent resolution, or WebView rendering.
- Doctor reports Android readiness as complete with no advisory notes about device evidence gaps.

**Phase to address:**
Phase defining the Android verification closure plan (v4.0 Phase 5). The evidence taxonomy (`:jvm_hermetic` vs. `:device_verified`) must be defined in Phase 1 alongside the iOS support truth states. The device-UAT checklist must explicitly cover the JVM-test blind spots.

---

### Pitfall 10: Device-UAT Checklist That Becomes Stale and Is No Longer Trusted

**What goes wrong:**
The device-UAT checklist is written at v4.0 milestone time and lists specific OS versions, device models, and test scenarios. Six months later, Android 16 ships and the checklist still says "Android 14 and 15." The minimum iOS version advances and the checklist still lists iOS 16 scenarios that no longer apply. A new capability family (e.g. from v4.1 archetype proof) is added but the UAT checklist is not updated to include its permission flow. The checklist becomes a "check the box" exercise that no longer reflects current reality.

The deeper failure: because the checklist is a static markdown document, there is no machine-checkable way to know if it is current with the capability registry, the SupportMatrix OS ranges, or the entitlement templates. It silently drifts.

**Why it happens:**
Checklists are written once and rarely revisited. There is no test or CI gate that enforces checklist-to-code parity. New capabilities are added without a policy that requires UAT checklist updates.

**How to avoid:**
1. The device-UAT checklist must be parity-locked to the capability registry: each capability family in the registry must have at least one UAT checklist scenario. A docs-contract test (or doctor check) must assert this 1:1 coverage.
2. The checklist must explicitly list the OS version ranges it covers, and the doctor must warn when the checklist's declared OS ranges fall below the SupportMatrix's claimed support range.
3. A capability registry addition policy (or a doctor gate) must require a UAT checklist update before a new capability can be marked `:supported` in the SupportMatrix.
4. The UAT checklist must be dated and include an explicit "last verified against" field (Crosswake version + OS versions tested). Doctor should warn when this field is more than one Crosswake major version stale.
5. The checklist must separate "always required" baseline scenarios (shell boot, WebView render, deep link, bounded bridge round-trip) from "capability-specific" scenarios so baseline staleness is visible independently.

**Warning signs:**
- UAT checklist lists an OS version that has been below the SupportMatrix minimum for more than one release cycle.
- A capability family exists in the registry with no corresponding UAT checklist entry.
- The checklist's "last verified" version is more than two Crosswake minor versions behind the current release.
- Doctor says "device UAT required" but gives no link or reference to the checklist.

**Phase to address:**
Phase building the Android verification closure plan (v4.0 Phase 5). The parity-lock mechanism (capability registry → UAT checklist coverage) must be built in the same phase as the initial checklist, not added later as tech debt.

---

### Pitfall 11: Host Responsibilities Leaking Into Shell — Hiding Adopter Obligations

**What goes wrong:**
The permission/entitlement templates are presented as "ready to use" with no documentation that the host app developer owns them. An adopter ships the template unchanged and their app gets rejected because:
- The push notification entitlement in the template requires an Apple Developer portal configuration the adopter hasn't done.
- The Info.plist camera usage description is a placeholder string ("Required for camera access") that doesn't explain the specific use case (App Store review requires a meaningful, non-generic description).
- The `AndroidManifest.xml` has `android:installLocation="auto"` but the host app's data model requires internal storage.

More broadly: the shells are checked-in proof artifacts, not standalone publishable packages. If the template generator or the guide implies the templates are "production-ready out of the box," adopters will skip the required host-owned configuration steps and hit review rejections or runtime failures.

**Why it happens:**
Template generators produce good defaults that work for the example host. The example host has all configurations correct. It is easy to copy the example output and not realize some entries are example-specific.

**How to avoid:**
1. Every generated template must carry inline comments marking adopter-owned fields explicitly: `<!-- ADOPT: replace with your app's specific camera use case description -->`, `<!-- ADOPT: enable "Push Notifications" in your Apple Developer portal for your App ID before shipping -->`.
2. The entitlement template guide must have a "Your Responsibilities" section that lists exactly what the host app developer must configure before App Store or Play Store submission.
3. Doctor must check for placeholder strings in the checked-in template (a configurable list of forbidden placeholder values like "Required for camera access") and warn the adopter before they submit.
4. The shells' README or guide must include a prominent callout: "These are checked-in proof artifacts showing the required structure. Your production app requires a fresh generation and host-owned configuration."

**Warning signs:**
- Permission usage description strings in the template are generic placeholders.
- Guide section for templates has no "Host Responsibilities" callout.
- Doctor does not check for unfilled placeholder values in permission descriptions.
- Entitlement template has `com.apple.developer.push-notifications` with no guide note about portal configuration.

**Phase to address:**
Phase building iOS/Android permission and entitlement templates (v4.0 Phase 3). The `<!-- ADOPT: ... -->` comment pattern and the doctor placeholder-check must ship in the same phase as the template generator.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Use `:verified` in SupportMatrix for CI-only Android evidence | Matrix looks complete | Adopters ship thinking device correctness is proven; real failures on device | Never — use `:jvm_hermetic` until device evidence exists |
| Single compatibility source in docs (not code) | Docs are easy to update | Manifest, shell, and doctor drift from docs; no machine check catches it | Never for the canonical record; docs may summarize but must cite the canonical source |
| Hard-code `targetSdkVersion` in shell build.gradle without doctor check | Less build infra | Silent Play submission rejection when Google advances the floor | Never without a doctor check that warns when the template is below the current floor |
| Generic placeholder text in permission usage descriptions | Templates ship quickly | App Store rejection for non-specific descriptions; adopters copy without editing | Acceptable only if marked with `<!-- ADOPT: -->` and guarded by a doctor placeholder check |
| Write UAT checklist once without a parity-lock test | Faster initial delivery | Checklist drifts from capability registry; becomes checkbox theater | Never for a checklist that gates `:verified` promotion — parity lock must ship with the checklist |
| Diagnostics seam as event stream (not export-on-crash) | Better DX for debugging | Violates bounded-bridge low-frequency thesis; requires background mode entitlements; battery impact | Never in production seam — use debug-mode-only streaming behind an explicit build flag |
| Skip redaction allowlist in diagnostics export | Simpler initial implementation | PII/token leakage in crash reports; privacy manifest underreporting; privacy nutrition label inaccuracy | Never — allowlist must be defined before the first export is wired |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Apple App Store review (Guideline 2.5.2) | Assume LiveView + WKWebView OTA updates are always allowed without checking the functional-change test | Verify each OTA update: does it change app purpose, add new native behavior, or bridge to a new native function not present at review time? If yes, submit a native rebuild |
| Apple privacy manifest (PrivacyInfo.xcprivacy) | Assume only the Crosswake shell needs a manifest; ignore third-party SDKs added by the adopter | Every bundled third-party SDK must have its own PrivacyInfo.xcprivacy; list first-party Crosswake dependencies and their manifest status in the guide's compliance checklist |
| Google Play target SDK floor | Pin `targetSdkVersion` at the value current at template generation time | Use a variable + doctor check; explicitly review Play's Policy Deadlines page at each Crosswake major release |
| Play Integrity API in CI | Call Play Integrity in CI JVM tests expecting a real verdict | Use Firebase App Check debug provider in CI; document that Play Integrity strong verdict requires real hardware and cannot be hermetically tested |
| SafetyNet (deprecated May 2025) | Copy-paste integrity check from pre-2025 code or examples | Replace all SafetyNet references with Play Integrity API; any `play-services-safetynet` dependency must be removed |
| Crash reporter custom keys | Log bridge command arguments as crash metadata for debugging | Only log command name and outcome; strip all arguments before any crash reporter `setCustomKey` call |
| Entitlement + provisioning profile | Generate `.entitlements` template assuming Apple Developer portal capabilities are pre-configured | Document each entitlement's portal prerequisite step; doctor should advisory-check entitlement-to-profile parity in the device lane |
| Android intent-filter deep links | Test deep link routing only in JVM bridge tests | Include intent-filter resolution in the device-UAT checklist; JVM tests cannot confirm Android's runtime intent dispatch |

---

## "Looks Done But Isn't" Checklist

- [ ] **SupportMatrix honesty:** Every platform/OS row distinguishes `:jvm_hermetic` (CI-only) from `:device_verified` (promotion criteria met). No row uses `:verified` for CI-only evidence.
- [ ] **Compatibility canonical source:** A single machine-readable record in the Crosswake library defines all version ranges. A docs-contract test asserts manifest, shell fixture, guide, and doctor all agree with the canonical record.
- [ ] **Rebuild policy completeness:** Policy explicitly classifies every change class (bridge command schema change, capability family addition, permission addition, entitlement addition, SDK version bump, privacy manifest entry addition) as either OTA-safe or rebuild-required.
- [ ] **Permission template generator is re-runnable:** Running the generator against the current route policy + capability registry produces the exact same output as the checked-in template. Any divergence is a doctor warning.
- [ ] **No placeholder permission strings:** Doctor checks for generic placeholder text in all usage description fields and `ADOPT:` comments are present for every host-owned field.
- [ ] **Entitlement-to-portal docs:** Every entitlement in the iOS template has a corresponding guide section explaining the Apple Developer portal step required.
- [ ] **Xcode SDK version in CI:** iOS CI workflow uses Xcode 26+ (enforced April 2026). Pinned version is documented with a "review at each major Crosswake release" note.
- [ ] **targetSdkVersion doctor check:** Android shell build.gradle uses a variable. Doctor checks the variable value against the current Google Play floor and warns when the template is below.
- [ ] **No SafetyNet references:** All Android shell code and CI tests use Play Integrity API. No `play-services-safetynet` dependency anywhere.
- [ ] **Diagnostics redaction allowlist:** Crash/diagnostic export seam has an explicit, tested allowlist. A docs-contract test asserts the guide's "what is never exported" section matches the allowlist.
- [ ] **Diagnostics is export-on-crash, not stream:** The seam bridge vocabulary has no subscribe or stream command. Debug streaming is a build-flag-only feature not part of the production seam contract.
- [ ] **Device-UAT checklist parity:** Each capability family in the registry has at least one UAT checklist entry. A doctor check or docs-contract test asserts this coverage.
- [ ] **Android JVM evidence gap documented:** SupportMatrix guide and doctor output explicitly state that JVM hermetic proof does not cover intent resolution, runtime permissions, WebView behavior, or SDK API level differences.
- [ ] **Host responsibilities documented:** Permission/entitlement template guide has an explicit "Your Responsibilities" section. Shells guide has a prominent "checked-in proof artifacts, not production-ready packages" callout.

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Dishonest `:verified` for CI-only evidence | Phase 1 (native runtime-line policy) — define `:jvm_hermetic` vs. `:device_verified` states before any matrix is populated | SupportMatrix has no `:verified` row without a linked device evidence artifact |
| Compatibility-window drift (manifest / shell / docs) | Phase 2 (rebuild and compatibility matrix) — canonical source + docs-contract test in same phase | Docs-contract test: manifest, shell fixture, guide, doctor all agree with canonical record |
| Rebuild policy over- or under-claiming OTA safety | Phase 1 (native runtime-line policy) — OTA-safe taxonomy locked before permission templates built | Policy explicitly classifies every change class; doctor distinguishes OTA-safe upgrades from rebuild-required upgrades |
| Permission template drift from declared capabilities | Phase 3 (iOS/Android permission and entitlement templates) — generator reads from capability registry | Re-running generator produces identical output to checked-in template; doctor warns on drift |
| Apple entitlement mismatch + privacy manifest gap | Phase 3 (iOS templates) — each entitlement has portal docs; privacy manifest checklist in guide | Docs-contract test: entitlement guide section exists for every `.entitlements` entry; CI Xcode version ≥ 26 |
| Google Play targetSdkVersion + OTA executable / SafetyNet | Phase 1 policy (SDK floor rule) + Phase 5 (Android shell CI) | Doctor warns when template `targetSdkVersion` < Play floor; no `safetynet` dependency in any shell file |
| Diagnostics export leaking PII / tokens | Phase 4 (crash/diagnostic export seam) — redaction allowlist + docs-contract test | No crash report key matches a token, route param, or PII pattern; allowlist test in merge-blocking lane |
| Diagnostics violating low-frequency bridge thesis | Phase 4 (seam design) — export-on-crash contract defined before implementation | Bridge vocabulary has no subscribe/stream command; seam contract states max export frequency |
| CI-only Android false confidence | Phase 1 (evidence taxonomy) + Phase 5 (Android verification closure) | SupportMatrix shows `:jvm_hermetic` not `:device_verified` until UAT checklist promotion criteria met |
| Device-UAT checklist staleness | Phase 5 (Android verification closure) — parity-lock test ships with checklist | Docs-contract test: every capability family has a UAT entry; doctor warns on stale "last verified" version |
| Host responsibilities hidden in templates | Phase 3 (templates) — `ADOPT:` comments + "Your Responsibilities" guide section | Doctor placeholder-string check; guide has explicit host responsibility section |

---

## Sources

- [Apple App Store Review Guidelines — Guideline 2.5.2 Dynamic Code](https://developer.apple.com/app-store/review/guidelines/)
- [Apple Upcoming Requirements — Xcode 26 SDK mandate April 28 2026](https://developer.apple.com/news/upcoming-requirements/)
- [Apple Privacy Manifest Files documentation](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [Apple — Adding a privacy manifest to your app or third-party SDK](https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk)
- [Apple — Diagnosing Issues with Entitlements](https://developer.apple.com/documentation/bundleresources/diagnosing-issues-with-entitlements)
- [Google Play Target API Level Requirements (targetSdkVersion ≥ 35 from August 2025)](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en)
- [Google Play Policy Deadlines](https://support.google.com/googleplay/android-developer/table/12921780?hl=en)
- [Play Integrity API overview (replaces SafetyNet, deprecated January 2025)](https://developer.android.com/google/play/integrity/overview)
- [Android Developers Blog — Stronger threat detection with Play Integrity API (October 2025)](https://android-developers.googleblog.com/2025/10/stronger-threat-detection-simpler.html)
- [Bitrise — What App Stores allow with OTA updates](https://bitrise.io/blog/post/what-app-stores-allow-with-ota-updates-apple-and-google-policy-explained)
- [Capgo — Ultimate Guide to App Store-Compliant OTA Updates](https://capgo.app/blog/ultimate-guide-to-app-store-compliant-ota-updates/)
- [NowSecure — Emulator vs Real Device Testing in Mobile App Security (April 2026)](https://www.nowsecure.com/blog/2026/04/15/emulator-vs-real-device-testing-in-mobile-app-security-closing-critical-coverage-gaps/)
- [Sentry — Mobile Privacy and PII in crash reporting](https://docs.sentry.io/security-legal-pii/security/mobile-privacy/)
- [Apple Developer Forums — Entitlements type mismatch iOS 26 leniency note](https://developer.apple.com/forums/thread/806195)
- `.planning/PROJECT.md` — v4.0 milestone constraints, locked guardrails, key decisions (direct inspection)
- `.planning/MILESTONE-ARC.md` — open research flag: "minimum Android evidence for `:verified`"; durable lessons: "hermetic and advisory proof lanes must stay separate"; "support claims must be narrow and documented" (direct inspection)

---
*Pitfalls research for: Crosswake v4.0 Production Shell Runtime Line — adding compatibility windows, rebuild policy, permission/entitlement templates, diagnostics export, and Android verification closure to a route-policy-first Phoenix library with checked-in iOS/Android shells*
*Researched: 2026-06-03*
