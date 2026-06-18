# Crosswake v13 Collateral and CI Evidence Research

**Project:** Crosswake v13.0 Adopter Confidence & Native Evidence  
**Focus:** demo/collateral proof package and CI integration  
**Researched:** 2026-06-18  
**Mode:** ecosystem / repo-truth research  
**Overall confidence:** HIGH for repo evidence, MEDIUM for external practice comparison

## Executive Recommendation

The highest-leverage v13 package is a **browser-first, CI-artifact-first adopter proof path with a small curated committed screenshot set**.

Make the deterministic browser route tour the required proof surface. It should exercise and capture the Phoenix host routes that already demonstrate the core thesis: LiveView, bounded bridge, offline island, and native-screen route policy/fallback. Keep native iOS simulator and Android emulator evidence **advisory** until checked-in host dependency truth is reconciled and the simulator/emulator jobs prove they are repeatable enough to promote.

Do not make videos the primary proof artifact. Use committed PNG screenshots for README/guides and CI artifacts for richer evidence: Playwright HTML report, traces, browser screenshots, native simulator/emulator screenshots, short native recordings, logs, and a machine-readable proof manifest. Videos are good "seeing is believing" collateral, but they are too large and environment-sensitive to be merge-blocking.

## Local Evidence

### Milestone truth

- `.planning/PROJECT.md` defines v13 as a seeing-is-believing proof path: runnable quick start, route-policy guide, rough-edge docs, migration docs, ExDoc linking, native simulator/emulator evidence, and screenshot/video collateral (`.planning/PROJECT.md:11-18`).
- `.planning/STATE.md` explicitly says v13 should not add capability breadth, that `TODO-001` is a precondition risk, and that simulator/device/native evidence stays advisory unless promoted by repeatable support truth (`.planning/STATE.md:57-62`).
- `.planning/STATE.md` also records the active blockers: public docs drift, checked-in native host drift, and absence of durable adopter screenshots/videos/artifact uploads (`.planning/STATE.md:83-87`).

### Existing browser proof

- The Phoenix host Playwright config is already tuned for deterministic browser E2E: one worker, retries in CI, service workers blocked, test DB reset, and a Phoenix web server on port 4002 (`examples/phoenix_host/playwright.config.ts:3-25`).
- The offline proof is now real. It clicks `/offline`, toggles network offline, queues through the UI, observes the IndexedDB outbox without writing app state, dispatches the `online` event, waits for `/study/sync`, asserts an Ecto row, asserts the outbox empties, and proves idempotency (`examples/phoenix_host/e2e/offline_sync.spec.ts:12-95`).
- The offline-sync workflow is a permanent merge gate with structural guards and a single required aggregator, `merge-blocking-offline-sync-e2e` (`.github/workflows/offline-sync-e2e-gate.yml:1-30`, `.github/workflows/offline-sync-e2e-gate.yml:43-135`).
- There are currently no `upload-artifact`, `playwright-report`, `test-results`, or `retention-days` patterns in `.github/workflows`, `examples/phoenix_host`, or `brandbook/e2e` based on repo search. v13 will need to add the artifact upload convention.

### Routes available for collateral

- Offline island and bridge proof routes exist under `/offline` and `/bridge-proof` (`examples/phoenix_host/lib/crosswake_example/router.ex:93-116`).
- LiveView SaaS routes exist under `/saas/dashboard`, `/saas/accounts/:id`, `/saas/approvals`, and a bounded haptics route at `/saas/approvals/:id` (`examples/phoenix_host/lib/crosswake_example/router.ex:151-219`).
- Native-screen policy is visible at `/native/claims/:id/capture`, with `runtime: :native_screen`, camera capability, media pack, and native-capture transfer (`examples/phoenix_host/lib/crosswake_example/router.ex:239-281`).
- Commerce also has native-screen intent routes, but these are less useful for v13 collateral because they risk expanding into provider/storefront expectations (`examples/phoenix_host/lib/crosswake_example/router.ex:295-321`).

### Existing brand/collateral pattern

- Brand work already established the correct split: `brand-structural` is required, `brand-visual` is advisory because visual/render checks are more environment-sensitive (`.github/workflows/brandbook-verify.yml:3-16`, `.github/workflows/brandbook-verify.yml:90-125`).
- Brand collateral uses committed, size-bounded social/README assets with explicit regeneration notes (`brandbook/collateral/README.md:1-34`).
- Brand visual tests intentionally avoid committed screenshot baselines and use pixel sampling to catch blank/broken renders while avoiding font-dependent text sampling (`brandbook/e2e/tests/collateral-render.spec.ts:3-6`, `brandbook/e2e/tests/collateral-render.spec.ts:89-130`).

### Existing native and release proof

- Release-time clean-room proof already proves generated iOS and Android shells outside the monorepo against published artifacts: iOS installs the just-cut Hex archive, generates a shell under `$RUNNER_TEMP`, and runs `swift build`; Android does the same and runs `gradle build` with Maven propagation polling (`.github/workflows/release-please.yml:200-310`).
- The permanent Android fire-drill validates generated Maven artifacts and signatures before dropping a Central Portal deployment (`.github/workflows/release-please.yml:312-479`).
- `script/verify_generated_ios_shell.sh` can generate or verify an iOS shell, create/boot a simulator, build-for-testing, install the app, launch it, and terminate it (`script/verify_generated_ios_shell.sh:25-31`, `script/verify_generated_ios_shell.sh:127-182`).
- `script/verify_generated_android_shell.sh` can provision Android tooling, create an AVD, boot it headlessly, and run unit plus connected tests when `CROSSWAKE_ANDROID_CONNECTED_TESTS=1` (`script/verify_generated_android_shell.sh:102-138`, `script/verify_generated_android_shell.sh:141-197`, `script/verify_generated_android_shell.sh:230-237`).
- There is already an Android emulator advisory lane. It is explicitly non-blocking and currently only proves emulator boot plus a placeholder for future connected checks (`.github/workflows/phase68-proof.yml:1-46`).

### Native host drift

- Checked-in iOS host uses a local Swift package reference to `../../packages/crosswake-shell-core-ios`, not the published SwiftPM mirror (`examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj:53-58`).
- Checked-in Android host still depends on stale `dev.crosswake:shell-core-android:0.1.0`, not the v11 published Maven coordinate (`examples/android_shell_host/app/build.gradle:62-64`).
- `mix.exs` is at `0.1.2`, while README still says `0.1.0` and CHANGELOG still frames `0.1.2` as unpublished (`mix.exs:1-10`, `README.md:143-151`, `CHANGELOG.md:28-40`).
- `examples/QUICK_START.md` references `mix setup` and `examples/ios_shell_host/ios_shell_host.xcodeproj`, which do not match the current example host proof path (`examples/QUICK_START.md:15-44`).
- `guides/adoption.md` still describes a generic `Crosswake.mutate` bridge sync model instead of the v12 app-owned IndexedDB outbox/reconnect proof (`guides/adoption.md:13-42`).
- `TODO-001` records deterministic and flaky example-host test debt. A public proof package should not depend on that unresolved state (`.planning/todos/TODO-001-phoenix-host-pre-existing-test-failures.md:20-52`).

## External Practice Comparison

Use current official docs only as guardrails, not as a reason to overbuild:

- GitHub's artifact action supports named paths, `if-no-files-found`, `retention-days`, compression options, overwrite behavior, hidden-file exclusion, artifact outputs, immutable artifact names in v4+, and a 500-artifacts-per-job limit. This supports a bounded, named artifact taxonomy with short retention and fail-closed missing-artifact checks. Source: GitHub `actions/upload-artifact` docs (`https://github.com/actions/upload-artifact`, lines 367-414, 504-599, 672-682).
- Playwright's CI guide uploads the HTML report as a GitHub Actions artifact with retention, and warns that reports, traces, logs, and artifacts can contain secrets. Source: Playwright CI docs (`https://playwright.dev/docs/ci-intro`, lines 104-168 and 193-265).
- Playwright videos are off by default and can be limited to first retry; videos are saved into the test output directory after context closure. Source: Playwright video docs (`https://playwright.dev/docs/videos`, lines 104-130).
- Playwright screenshot comparisons exist, but pixel thresholds need explicit control. Crosswake should not turn adopter collateral into a broad visual regression suite. Source: Playwright visual comparison and config docs (`https://playwright.dev/docs/test-snapshots`, lines 91-105; `https://playwright.dev/docs/test-configuration`, lines 242-264).
- Apple Simulator supports command-line `simctl` video recording, including H.264 and mask options. This is appropriate for advisory macOS-runner collateral, not required merge gates. Source: Apple WWDC Simulator session (`https://developer.apple.com/videos/play/wwdc2020/10647/`, lines 287-300).
- Android adb supports `screencap` and `screenrecord`; `screenrecord` has no audio, rotation limitations, and a default/maximum 180-second limit. Android Emulator can also record WebM/GIF via emulator controls or command line. Source: Android adb and emulator docs (`https://developer.android.com/tools/adb`, lines 1112-1172; `https://developer.android.com/studio/run/emulator-record-screen`, lines 547-568).

## Options

| Decision | Option | Pros | Cons | Recommendation |
|----------|--------|------|------|----------------|
| Screenshots vs videos | Committed screenshots | Durable in README/guides, small, easy to inspect in PRs | Can stale if not regenerated | Commit a small curated PNG set only |
| Screenshots vs videos | CI videos | Best for "seeing is believing" flow evidence | Larger, slower, more flaky, harder to review | Upload short advisory videos as CI artifacts; do not commit |
| Browser vs native | Browser route tour | Already real, cheap on Ubuntu, proves Phoenix-owned route policy and offline path | Does not show native chrome/shell trust | Make required and artifact-backed |
| Browser vs native | iOS simulator | Strong adopter trust for shell launch and native framing | macOS runner cost, simulator variance, checked-in host currently local-only | Advisory until host dependency truth is fixed |
| Browser vs native | Android emulator | Strong native breadth signal, existing advisory lane | Slow, tooling download cost, emulator flake | Advisory, scheduled/dispatch/main only |
| Artifact storage | CI artifacts only | Fresh, complete, no repo bloat | Expire; weak README first impression | Use for rich reports/videos/logs |
| Artifact storage | Committed docs assets | Durable public collateral | Can drift; package size pressure | Commit only 4-6 optimized screenshots plus manifest |
| Required vs advisory | Required all lanes | Simple dashboard, high confidence if green | Native flake blocks contributors and overstates support | Required browser structural lane; advisory native lanes |

## Recommended Artifact Taxonomy

### Committed assets

Commit only curated, optimized screenshots plus a manifest. Prefer a path that makes docs intent explicit:

```text
guides/assets/adopter-proof/
  manifest.json
  phoenix-liveview-dashboard.png
  bounded-bridge-proof.png
  offline-island-queued.png
  offline-island-reconnected.png
  native-screen-route-policy.png
  ios-shell-launch-advisory.png       # optional only after host truth is reconciled
  android-shell-launch-advisory.png   # optional only after host truth is reconciled
```

Manifest fields should include:

- `crosswake_version`
- `git_sha`
- `captured_at`
- `route`
- `runtime_owner`
- `proof_class` (`merge_blocking`, `advisory`, or `collateral_only`)
- `source_job`
- `notes`

Do not commit videos. Do not commit Playwright reports, traces, native build products, simulator devices, generated shell projects, or emulator logs.

### CI artifacts

Use unique names per job and attempt:

| Artifact | Contents | Lane | Retention |
|----------|----------|------|-----------|
| `crosswake-adopter-browser-${{ github.sha }}-${{ github.run_attempt }}` | browser screenshots, `manifest.json`, Playwright HTML report, traces/videos on retry/failure | required browser route tour | 30 days |
| `crosswake-native-ios-advisory-${{ github.sha }}-${{ github.run_attempt }}` | xcodebuild log, simulator launch log, screenshots, short mp4 if recorded, manifest | advisory iOS | 14 days |
| `crosswake-native-android-advisory-${{ github.sha }}-${{ github.run_attempt }}` | Gradle/adb/emulator logs, screenshots, short mp4/webm, manifest | advisory Android | 14 days |
| `crosswake-release-cleanroom-${version}` | links/summary to release clean-room proof logs and coordinates; no generated projects unless needed for debugging | release-only evidence index | release run default |

Artifact upload rules:

- `if-no-files-found: error` for every expected screenshot/manifest artifact.
- Do not include hidden files.
- Use short retention for native video artifacts.
- Use low/no compression for video-heavy artifacts if upload time becomes material.
- Add a `$GITHUB_STEP_SUMMARY` table with artifact names, proof class, routes covered, and support label.

## CI and DevOps Recommendations

1. Add `adopter-proof.yml` with three lanes:
   - `merge-blocking-adopter-proof-browser`: Ubuntu, Phoenix host, Playwright route tour, semantic assertions, screenshot capture, artifact upload.
   - `advisory-native-ios-evidence`: macOS, generated or reconciled shell, simulator launch, screenshot/optional short recording, `continue-on-error: true`.
   - `advisory-native-android-evidence`: macOS or maintained emulator action, generated or reconciled shell, emulator launch, screenshot/optional short recording, `continue-on-error: true`.

2. Keep the required browser lane structural:
   - Assert routes load and show expected runtime/posture copy.
   - Assert the bridge proof emits the expected bounded request envelope or visible UI state.
   - Reuse the v12 offline proof for real outbox/reconnect/Ecto truth rather than creating a separate fake demo flow.
   - Capture screenshots as side effects, but do not use full-page screenshot baselines as the required assertion.

3. Keep native evidence advisory unless all promotion conditions pass:
   - Checked-in native hosts either use published `0.1.2` coordinates or are clearly labeled local-development proof.
   - CI runs native launch/capture successfully for a defined freshness window.
   - The support matrix and docs distinguish simulator evidence from device support.
   - Failure mode is visible in CI, but does not block merges.

4. Do not duplicate release clean-room proof in ordinary PRs:
   - The release workflow already proves external `swift build` and `gradle build` after publishing.
   - v13 should surface those results in docs/artifact summaries, not run full registry propagation proof on every PR.

5. Add a lightweight artifact manifest validator:
   - Verify every expected screenshot exists and is non-empty.
   - Verify `manifest.json` contains version, SHA, route, proof class, and source job.
   - Verify advisory files cannot be described as merge-blocking in the manifest.

6. Add docs links, not a media portal:
   - README gets one visual "proof strip" and a link to the proof guide.
   - `examples/QUICK_START.md` becomes runnable and points to CI artifacts for fresh recordings.
   - `guides/support_matrix.md` distinguishes `collateral_only`, `advisory`, and `merge_blocking` evidence.

## Acceptance Criteria

- `TODO-001` is resolved or explicitly excluded from the public proof path.
- README, CHANGELOG, quick start, install guide, and adoption guide agree on `0.1.2` published truth.
- Checked-in native hosts either prove published coordinates or clearly state they are local-development proof.
- Browser adopter proof runs in CI, passes deterministic semantic assertions, captures the core routes, and uploads the artifact package.
- Browser proof artifact includes at least:
  - LiveView route screenshot (`/saas/dashboard` or `/decks`)
  - Bounded bridge screenshot (`/bridge-proof`)
  - Offline island queued state screenshot (`/offline`)
  - Offline island reconnected/synced state screenshot
  - Native-screen route-policy/fallback screenshot (`/native/claims/:id/capture` or equivalent)
  - `manifest.json`
- iOS and Android evidence lanes upload labeled advisory artifacts when they run, and their failure does not block merges.
- No artifact or committed asset claims device support, provider support, local-first mutation support, or native runtime breadth beyond the route/flow actually captured.
- Committed screenshot budget is explicit and small; videos are not committed.
- Artifact uploads fail closed when expected files are missing.

## Flaky-Risk Controls

- Browser required lane:
  - Keep one worker and DB reset pattern from the existing Playwright config.
  - Block service workers to avoid cache masking.
  - Use semantic locators and response waits, not sleep-based assertions.
  - Keep retries low and investigate flakes rather than hiding them with high retry counts.
  - Upload Playwright report and trace on failure.

- iOS advisory lane:
  - Use `xcrun simctl bootstatus` before capture.
  - Use status bar overrides before screenshots/videos where possible to stabilize time/network chrome.
  - Record short clips only, preferably 10-20 seconds.
  - Save simulator logs and xcodebuild logs with the artifact.
  - Do not promote until repeated green runs prove launch/capture is stable.

- Android advisory lane:
  - Prefer existing AVD boot readiness checks (`sys.boot_completed`) and headless emulator settings.
  - Keep `screenrecord` short and avoid rotation during capture.
  - Capture `adb exec-out screencap -p` for deterministic screenshots.
  - Always upload emulator log and Gradle output when the lane runs.
  - Schedule heavy emulator work and keep PR execution opt-in or path-scoped.

- Artifact hygiene:
  - Exclude hidden files.
  - Never upload local `.env`, keychains, provisioning profiles, generated `.git` directories, or build caches.
  - Treat Playwright traces/reports as potentially sensitive and keep them in GitHub artifact storage rather than public web hosting.

## Non-Goals

- No universal UI demo framework.
- No broad visual regression suite.
- No required simulator/emulator branch-protection lane in v13.
- No TestFlight, Play Store, physical-device farm, or provider SDK proof.
- No committed videos or full Playwright reports.
- No new capability breadth to make collateral more impressive.
- No claim that checked-in native hosts prove public install truth until dependency drift is reconciled.
- No public hosting of PR traces/reports that might contain secrets.

## Sources

Local repo evidence:

- `.planning/PROJECT.md`
- `.planning/STATE.md`
- `.planning/todos/TODO-001-phoenix-host-pre-existing-test-failures.md`
- `.github/workflows/offline-sync-e2e-gate.yml`
- `.github/workflows/brandbook-verify.yml`
- `.github/workflows/release-please.yml`
- `.github/workflows/phase68-proof.yml`
- `examples/phoenix_host/playwright.config.ts`
- `examples/phoenix_host/e2e/offline_sync.spec.ts`
- `examples/phoenix_host/lib/crosswake_example/router.ex`
- `examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj`
- `examples/android_shell_host/app/build.gradle`
- `script/verify_generated_ios_shell.sh`
- `script/verify_generated_android_shell.sh`

External sources:

- GitHub `actions/upload-artifact`: https://github.com/actions/upload-artifact
- Playwright CI guide: https://playwright.dev/docs/ci-intro
- Playwright videos: https://playwright.dev/docs/videos
- Playwright visual comparisons: https://playwright.dev/docs/test-snapshots
- Playwright configuration: https://playwright.dev/docs/test-configuration
- Apple Simulator session: https://developer.apple.com/videos/play/wwdc2020/10647/
- Android adb docs: https://developer.android.com/tools/adb
- Android emulator screen recording: https://developer.android.com/studio/run/emulator-record-screen

