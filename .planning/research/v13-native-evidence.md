# v13.0 Native Evidence Truth Research

**Project:** Crosswake  
**Scope:** Native evidence truth for v13.0 only  
**Researched:** 2026-06-18  
**Confidence:** HIGH for repo evidence; MEDIUM for simulator/emulator artifact recommendations until exercised on CI/hardware

## Recommendation

Use both truth lanes, but do not blend them.

1. **Public adopter install proof:** Generated non-local shells are the authoritative proof that Crosswake resolves published `0.1.2` native coordinates. This is already backed by generator templates, generator tests, release clean-room proof, and `generator_coordinate_parity`.
2. **Checked-in native host proof:** Prefer converting the checked-in iOS and Android hosts to published-coordinate defaults for v13, so screenshots/videos from those hosts can honestly say they exercise the public `0.1.2` native package path.
3. **Local development proof:** Keep local package consumption as an explicitly labeled developer workflow through `mix crosswake.gen.shell --local`, local README instructions, or a separate local-dev verification command. Do not let local package references appear in public proof screenshots without a visible `local-dev proof` label.

If converting the checked-in hosts destabilizes v13, the fallback is acceptable but weaker: label the checked-in iOS/Android hosts as **local-development proof only**, and route published-coordinate proof exclusively through freshly generated clean-room shells. The status quo is not acceptable because the repo currently lets local/stale checked-in host coordinates sit next to public proof claims.

## Options Matrix

| Option | What It Means | Pros | Cons | Recommendation |
|--------|---------------|------|------|----------------|
| A. Checked-in hosts prove published `0.1.2` | Update checked-in iOS to remote SwiftPM `szTheory/crosswake-shell-core-ios` and Android to Maven `io.github.sztheory:crosswake-shell-core-android:0.1.2`; keep `--local` for contributor iteration. | Strongest adopter story; screenshot/video artifacts can be public-coordinate evidence; aligns examples with v11 release truth. | Local native-core iteration needs an explicit alternate path; may require regenerating/refreshing fixtures and docs. | **Preferred v13 target.** |
| B. Checked-in hosts are local-dev proof | Leave checked-in hosts local or repo-oriented, but label them everywhere as local-dev evidence; generated clean-room shells remain the only published-coordinate proof. | Lowest code churn; honest if examples are mainly maintainer fixtures. | Weaker for adopters; screenshots from checked-in hosts cannot prove public coordinates; support matrix needs careful split language. | Acceptable fallback only. |
| C. Check in both published and local variants | Add separate published-coordinate and local-dev host directories or build flavors. | Maximum explicitness. | More maintenance surface; more docs and CI matrix weight; risks two drifting demo apps. | Avoid for v13 unless Option A is impossible and local-dev ergonomics are critical. |
| D. Keep current ambiguity | Rely on generator proof while checked-in hosts retain local/stale coordinates and public docs keep treating them as proof artifacts. | No work. | Contradicts NATIVE-01; undercuts v11 release truth; screenshots would be misleading. | Reject. |

## Repo Evidence

### Published-coordinate path is real

- `mix.exs` declares `@version "0.1.2"`.
- `.planning/PROJECT.md` and `.planning/STATE.md` state that `crosswake 0.1.2` is live on Hex, Maven Central, and the SwiftPM mirror, and that `gen.shell` emits resolvable version-matched coordinates.
- `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex` renders the non-local path as `XCRemoteSwiftPackageReference` with `https://github.com/szTheory/crosswake-shell-core-ios.git`, `upToNextMajorVersion`, and `minimumVersion = @version`.
- `priv/templates/crosswake/shell/android/app/build.gradle.eex` renders the non-local path as `implementation("io.github.sztheory:crosswake-shell-core-android:@version")`.
- `test/mix/tasks/crosswake_gen_shell_test.exs` asserts non-local generator output uses the published iOS and Android coordinates, rejects `XCLocalSwiftPackageReference`, rejects the old `dev.crosswake:shell-core-android`, and separately verifies `--local` output.
- Focused verification run on 2026-06-18: `mix test test/mix/tasks/crosswake_gen_shell_test.exs` passed with `4 tests, 0 failures`.
- `.github/workflows/release-please.yml` has clean-room proof jobs that install the just-cut Hex archive, generate iOS/Android shells in `$RUNNER_TEMP` outside the monorepo, then run `swift build` and `gradle build` against published dependencies.
- `lib/crosswake/doctor/publish_readiness.ex` has `generator_coordinate_parity` checks that fail if non-local templates emit local iOS refs, old iOS org refs, old Android GAVs, or local Android project dependencies.

### Checked-in native hosts do not currently prove published coordinates

- `examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj` labels the section as `XCRemoteSwiftPackageReference`, but the object is `isa = XCLocalSwiftPackageReference` with `relativePath = "../../packages/crosswake-shell-core-ios"`.
- `examples/android_shell_host/app/build.gradle` still has `versionName "0.1.0"` and `implementation 'dev.crosswake:shell-core-android:0.1.0'`.
- `examples/ios_shell_host/README.md` and `examples/android_shell_host/README.md` say the hosts are real native project artifacts adopters ship, but do not label the coordinate mode.
- `guides/support_matrix.md` says shell claims are backed by checked-in example hosts plus generated-shell verification hooks. That wording is too broad while checked-in hosts do not match the published-coordinate story.
- `script/verify_phase5_example_hosts.sh` runs the checked-in host verification scripts when `CROSSWAKE_PHASE5_NATIVE_PROOFS` is enabled, but those scripts inherit whatever coordinate mode the checked-in hosts currently contain.

### Existing evidence hooks are useful but not visual collateral

- `script/verify_generated_ios_shell.sh` can generate or target an iOS project, run `xcodebuild -list`, build for testing, boot a simulator, install the `.app`, launch it, and terminate it. It explicitly comments that this is build/install/launch proof, not full XCTest execution.
- `script/verify_generated_android_shell.sh` can generate or target an Android project, install toolchains, create an API 34 AVD, and run `testDebugUnitTest connectedDebugAndroidTest`.
- Neither script currently captures screenshots, screen recordings, logs as named artifacts, or a machine-readable evidence manifest.
- The demo routes provide the right visual coverage: `/saas/dashboard` or `/native/claims` for LiveView, `/bridge-proof` for bounded bridge, `/offline` or `/study/session` for offline island, and `selective-native-claim-capture` for native-screen activation.
- The native capture screens stage local placeholder media through an explicit transfer seam. They are good native-screen evidence, but not proof of production camera/media support.

## Recommended Requirements And Acceptance Criteria

### NATIVE-01: Native Coordinate Truth

**Requirement:** Checked-in native host evidence must be classified as published-coordinate proof or local-development proof, with no ambiguous stale coordinates.

Acceptance criteria:

- A v13 decision records the two valid evidence labels: `published-coordinate proof` and `local-dev proof`.
- Preferred path: checked-in iOS host uses remote SwiftPM `https://github.com/szTheory/crosswake-shell-core-ios.git` with the Crosswake `0.1.2` version floor, and checked-in Android host uses `io.github.sztheory:crosswake-shell-core-android:0.1.2`.
- Fallback path: if either checked-in host remains local, its README, quick start, support matrix entry, and any screenshots/videos label it `local-dev proof` and do not claim public install proof.
- No public proof path references `dev.crosswake:shell-core-android:0.1.0` or silently uses `XCLocalSwiftPackageReference`.
- The generator docs show the default published-coordinate path and `--local` path separately.
- Add a guard that fails on either stale checked-in host coordinates or missing local-dev labels, depending on the chosen option.

### COLL-01: Native Visual Evidence

**Requirement:** v13 should produce durable visual evidence for iOS and Android without promoting simulator/emulator support beyond what was actually proven.

Acceptance criteria:

- Artifacts exist for both platforms, named with platform, coordinate mode, Crosswake version, commit SHA, and date.
- Each artifact bundle includes a short manifest containing: command used, project path, coordinate mode, package version, platform/runtime version, route or flow captured, support label, and known limitations.
- Capture at least these flows across Phoenix host plus native shells:
  - LiveView route: `/saas/dashboard`, `/native/claims`, or another manifest-known LiveView route.
  - Bounded bridge: `/bridge-proof` plus native share-sheet invocation where practical.
  - Offline island: `/offline` or `/study/session`, including queued/replayed state from the v12 IndexedDB outbox path.
  - Native screen: `selective-native-claim-capture` showing `Native capture` and `Stage For Transfer`.
- Simulator/emulator artifacts are labeled `advisory simulator evidence` or `advisory emulator evidence` unless v13 also adds repeatable promotion criteria and merge-blocking support.
- Native-screen evidence says `staged local placeholder/transfer seam proof`, not `camera support` or `media upload support`.

### TRUTH-01: Support Claim Labeling

**Requirement:** Support docs and quick-start copy must distinguish generated public install proof, checked-in demo proof, local-dev proof, and advisory simulator/emulator collateral.

Acceptance criteria:

- `guides/support_matrix.md`, its source renderer/data, README/quick start references, and native shell guide use the same labels.
- `script/verify_generated_ios_shell.sh` evidence is described as build/install/launch proof unless a later test lane promotes it.
- Android JVM/hermetic evidence is not described as device support. Emulator evidence is separate and advisory by default.
- Any artifact page or README link states whether the underlying host used published coordinates or local packages.

## Suggested Artifact Plan

### iOS

- Run the generated or checked-in host in published-coordinate mode.
- Use `script/verify_generated_ios_shell.sh` as the build/install/launch baseline.
- Add a collateral-only wrapper that captures:
  - `xcrun simctl io <device> screenshot artifacts/native/ios/<flow>.png`
  - `xcrun simctl io <device> recordVideo artifacts/native/ios/<flow>.mp4` for short flows where stable
  - `xcrun simctl spawn <device> log stream` or launch output as supplemental text when useful
- Do not call this XCTest coverage unless `xcodebuild test` is actually run and stable.

### Android

- Run the generated or checked-in host in published-coordinate mode.
- Use `script/verify_generated_android_shell.sh` as the unit/connected-test baseline.
- For visual collateral, either run an emulator with a display-capable configuration or capture headless frames using:
  - `adb exec-out screencap -p > artifacts/native/android/<flow>.png`
  - `adb shell screenrecord /sdcard/<flow>.mp4` followed by `adb pull`
- If the current verification script keeps `-no-window`, label video/screenshots as emulator frame captures, not observed manual UI review.

### Phoenix Host

- Use Playwright screenshots for the web proof routes, especially `/bridge-proof` and `/offline`.
- Tie offline screenshots to the v12 real path: UI action while offline, IndexedDB outbox evidence, reconnect-triggered flush, and server/Ecto assertion. A screenshot alone is not enough for offline correctness.

## Risks And Footguns

| Risk | Severity | Why It Matters | Mitigation |
|------|----------|----------------|------------|
| Screenshot from local host is marketed as published install proof | High | Reintroduces the exact v11 distribution ambiguity v13 is meant to remove. | Artifact manifest must include coordinate mode; docs must label local-dev proof. |
| Android stale GAV remains in checked-in host | High | `dev.crosswake:shell-core-android:0.1.0` is not the public Maven Central coordinate. | Update to `io.github.sztheory:...:0.1.2` or label the host local-dev and exclude from public install proof. |
| iOS local package section masquerades as remote package proof | High | Current pbxproj section title says remote while `isa` is local. | Update pbxproj or add explicit local-dev label plus guard. |
| `upToNextMajorVersion` is read as exact `0.1.2` resolution | Medium | SwiftPM may resolve according to semver rules; exact resolved version needs Package.resolved/build logs. | Claim `0.1.2 version floor` unless the artifact captures the resolved tag. |
| Simulator/emulator evidence overpromotes device support | Medium | Environment-sensitive native proof can be flaky and narrow. | Label advisory; require promotion criteria before merge-blocking support claims. |
| Native capture screenshot implies production camera/media support | Medium | The demo stages placeholder local media through a transfer seam. | Caption as native-screen/transfer-boundary proof only. |
| Generated-host and checked-in-host proof collapse into one support-matrix row | Medium | Readers cannot tell which path proves install truth. | Split wording by artifact class and coordinate mode. |
| Local native-core iteration becomes painful after switching checked-in hosts to published deps | Medium | Maintainers need fast repo-local native changes. | Keep `--local` and local-dev verification documented, but out of public proof collateral. |
| Artifact capture scripts become flaky required CI | Medium | Visual proof is environment-sensitive. | Keep visual artifact capture advisory until repeatability is demonstrated. |

## Non-Goals

- Do not implement new native capabilities.
- Do not promote simulator/emulator evidence to physical-device support in v13 unless separate promotion criteria are added and met.
- Do not claim production camera capture, media upload, or background sync from the native capture demo.
- Do not make Crosswake a generic WebView wrapper or LiveView-native-rendering framework.
- Do not add broad Android/iOS OS support matrices beyond the support truth already documented.
- Do not replace the generator clean-room proof with screenshots. Visual collateral supplements mechanical proof; it does not prove dependency resolution or offline reconciliation by itself.
- Do not commit release or workflow changes from this research task.

## Sources Inspected

- `AGENTS.md`
- `.planning/PROJECT.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/threads/adoption-evidence-demo.md`
- `.planning/research/v13-proof-path-docs.md`
- `mix.exs`
- `lib/mix/tasks/crosswake.gen.shell.ex`
- `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex`
- `priv/templates/crosswake/shell/android/app/build.gradle.eex`
- `priv/templates/crosswake/shell/android/settings.gradle.eex`
- `test/mix/tasks/crosswake_gen_shell_test.exs`
- `lib/crosswake/doctor/publish_readiness.ex`
- `test/crosswake/doctor/publish_readiness_test.exs`
- `.github/workflows/release-please.yml`
- `script/verify_generated_ios_shell.sh`
- `script/verify_generated_android_shell.sh`
- `script/verify_phase5_example_hosts.sh`
- `examples/ios_shell_host/README.md`
- `examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj`
- `examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift`
- `examples/ios_shell_host/CrosswakeShell/NativeCaptureView.swift`
- `examples/android_shell_host/README.md`
- `examples/android_shell_host/app/build.gradle`
- `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/MainActivity.kt`
- `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/NativeCaptureActivity.kt`
- `examples/android_shell_host/app/src/androidTest/java/dev/crosswake/shell/LiveViewBootInstrumentedTest.kt`
- `examples/phoenix_host/lib/crosswake_example/router.ex`
- `examples/phoenix_host/lib/crosswake_example/bridge_proof_live.ex`
- `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex`
- `guides/native_shell.md`
- `guides/install.md`
- `guides/support_matrix.md`
