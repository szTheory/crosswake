# Thread: Release & Distribution Truth

**Opened:** 2026-06-14 (milestone next-step assessment, post-v10.0)
**Status:** RESOLVED by v11.0 — historical thread retained for evidence; current open follow-up is adopter-confidence proof, not distribution
**Lens:** adopter-first ("a Phoenix SaaS dev who would actually install this")

## The gap (verified repo-local, high confidence)

> 2026-06-18 refresh: This gap is now historical. v11.0 shipped `crosswake 0.1.2` to Hex, Maven Central, and the SwiftPM mirror, rewired `gen.shell` to generated version-matched published coordinates, and added clean-room/parity proof. Keep the research below as evidence for why v11.0 existed, but do not treat its "unpublished" claims as current truth.

Crosswake is a mature *codebase* (~88% done for scope) but a partial *installable product* (~70%). The missing delta is foundational distribution, not features:

1. **Hex publishes only `0.1.0`** (2026-05-29). `mix.exs` is at `@version "0.1.2"` but `0.1.2` is staged-but-uncut; `[Unreleased]`/`[0.1.2]` in `CHANGELOG.md` explicitly defer "full Sigra auth/session machinery, Chimeway notification delivery, and standalone generated shell packages" as *not in the published package*. So planning v3.4→v10.0 (commerce archetype, first-party companions, Sigra auth, Chimeway, standalone shells, demo, Threadline, brand) lives in `main`, uninstallable. The Hex axis is intentionally distinct from `vN.0` planning tags — but the shipped surface was never re-published.
2. **The v5.0 "no eject trap" thesis is not actually distributed.** `mix crosswake.gen.shell` defaults to `--local false` (`lib/mix/tasks/crosswake.gen.shell.ex:61`). The **default** generated output references deps that don't exist:
   - iOS: `repositoryURL = "https://github.com/crosswake/crosswake-shell-core-ios.git"` (`priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex:56`) — wrong org (real is `szTheory`), repo absent.
   - Android: `implementation 'dev.crosswake:shell-core-android:0.1.0'` (`priv/templates/crosswake/shell/android/app/build.gradle.eex:54`) — Maven artifact never published — plus a local `project(':crosswake-shell-core-android')` monorepo include.
   - The native cores have **no versioning/publishing config** (`packages/crosswake-shell-core-android/build.gradle.kts` has only `namespace`; `packages/crosswake-shell-core-ios/Package.swift` has no version) and **no publish CI** (only `hex-publish.yml` + `release-please.yml` exist). Native proof lanes only ever ran with `--local` against monorepo paths.
   - → An adopter running `gen.shell` in their own repo gets an unbuildable project. The flagship claim is proven only inside this monorepo.

## Recommended milestone scope

> 2026-06-18 refresh: Completed by v11.0 Release & Distribution Truth. Do not re-scope this as a new milestone unless a future release breaks the published-coordinate guarantee.

"Cut a Hex release" is a near button-press (`doctor --check-publish` ready, release-please wired) — do NOT milestone that. The milestone makes the standalone-package thesis real:

1. **Publish iOS core** — SwiftPM can't consume a monorepo subdir (root-manifest constraint, SE-0292). Auto **subtree-mirror** `packages/crosswake-shell-core-ios/` → dedicated `github.com/szTheory/crosswake-shell-core-ios` with semver git tags (Apollo iOS pattern, `splitsh-lite` in CI).
2. **Publish Android core** — add `group`/`version`/`maven-publish` via Vanniktech `com.vanniktech.maven.publish`, verify `io.github.sztheory` namespace, publish to the **Central Portal** (OSSRH sunset 2025-06-30). ~½–1 day; footguns: GPG signing (public key on a keyserver), mandatory POM (name/desc/url/license/developers/scm), immutable releases, no `-SNAPSHOT`.
3. **Rewire `gen.shell` templates** — inject `Application.spec(:crosswake)[:vsn]` at generate-time (LiveView Native `lvn.swiftui.gen` pattern) → `.package(url:, from: "x.y.z")` (iOS) and `implementation("io.github.sztheory:crosswake-shell-core-android:x.y.z")` (Android). Delete the `crosswake/` placeholder remote and the relative-path default. Derive every native dep version from the one source of truth — never hardcode a satellite literal (LVN's drift bug).
4. **Lockstep versioning** — release-please **manifest mode + `linked-versions`** so Hex + SPM mirror tag + Maven carry the same version the generated code references. Gate native publish jobs with `needs: release-please` + `if: releases_created` (default `GITHUB_TOKEN` won't trigger downstream `release: published` workflows).
5. **Acceptance gate (proves the thesis):** one CI lane that scaffolds a host **outside the monorepo**, default (not `--local`), and confirms `swift build` / `gradle build` resolve the *published* deps and compile.
6. Reconcile `guides/adoption.md` (currently documents a 404 install path), `guides/support_matrix.md`, and CHANGELOG to published truth; cut Hex `0.1.2`.

**Suggested split if too big:** Phase A = native publish-config + actual publish + Hex cut · Phase B = template rewire + clean-room build proof + doc reconciliation.

**"Done enough":** an adopter outside this repo adds the Hex dep, runs `gen.shell` (default), and gets iOS+Android projects that resolve published, version-matched deps and build — proven by the clean-room CI lane.

## Ordering after this wedge

2026-06-18 current ordering after v11/v12:

1. **Adopter Confidence & Native Evidence** — make the now-real distribution and offline proof runnable, visual, and current for adopters.
2. **DASH-01 operator metric surfacing** — useful after the proof path is trustworthy.
3. **NTV-01 native physical storage budgets** — valuable but narrower and higher-cost than confidence/collateral.
4. **New capability breadth** — defer until the existing thesis is easy to see and run.

## Graduation candidate
**"Published-dep parity" graduated in v11.0** as the permanent generator-coordinate parity guard. The next graduation candidate is **adopter-evidence freshness**: proof/collateral should make clear which evidence is merge-blocking, advisory simulator/device proof, or documentation/collateral only.

## Evidence index
- `mix.exs:4` `@version "0.1.2"`; `CHANGELOG.md` `[Unreleased]`/`[0.1.2]`/`[0.1.0]`; `git tag` shows only `v0.1.0` on the Hex axis.
- `lib/mix/tasks/crosswake.gen.shell.ex:61` `--local` defaults false.
- `priv/templates/.../project.pbxproj.eex:49,56`; `priv/templates/.../app/build.gradle.eex:52,54`; `priv/templates/.../settings.gradle.eex:21-22`.
- `packages/crosswake-shell-core-{ios/Package.swift, android/build.gradle.kts}` — no publish config.
- `.github/workflows/` — `hex-publish.yml`, `release-please.yml`; no native publish lane.

## Research sources (2025-2026 practice)
SwiftPM root-manifest constraint (Swift Forums / SE-0292) · Apollo iOS git-subtree split · OSSRH sunset → Central Portal (central.sonatype.org) · Vanniktech maven-publish-plugin · release-please manifest/linked-versions + downstream-trigger gotcha (action #1000) · LiveView Native generate-time version injection.

---

## Research detail (for execution — captured from the 2026-06-14 assessment subagents so it survives context clears)

### Ecosystem footguns — 5 named, each from the lib that learned it the hard way
1. **"Use latest" in generated code/docs** — *Hotwire Native* docs literally print `<latest-version>` and teach the Xcode GUI add-package dialog with no pinning → non-reproducible builds, silent breakage. **Fix:** inject the exact version at generate-time.
2. **Branch-pinning a SwiftPM dep (`branch: "main"`)** — *Capacitor's* SPM migration pinned `capacitor-swift-pm.git` to `main` (issue #7735), discarding the version-sync guarantee. **Fix:** pin to a tag / `from:`, never a branch.
3. **Relative-path deps that break outside the exact layout** — *Capacitor* (`../../node_modules/...` breaks under pnpm/monorepo hoisting, #6040) and *Hotwire demos* (local `path = ..`). **This is Crosswake's current bug.** **Fix:** published versioned deps only.
4. **Hardcoded satellite-package version while the main one is derived** — *LiveView Native* hardcodes `LiveViewNativeLiveForm` `from: "0.4.0-rc.1"` while deriving the main package → silent drift. **Fix:** derive *every* native dep version from the one source of truth (`Application.spec(:crosswake)[:vsn]`).
5. **Treating a SwiftPM monorepo subdir as consumable over a git URL** — SwiftPM forbids it (root-manifest constraint; package identity = repo name, SE-0292; no `subdirectory:` param). *Apollo iOS* solved it by **subtree-splitting** the package to a dedicated read-only repo via `splitsh-lite` in CI, preserving monorepo co-development. **Fix:** mirror, don't try to publish the subdir.

### Distribution how-to specifics
- **iOS:** keep `swift-tools 5.9` (toolchain floor, not consumer Swift), platforms at lowest supported (iOS 15 / macOS 12), annotated SemVer tags (`x.y.z`), never re-tag. **Source distribution, not binary** (`.binaryTarget` can't declare deps, adds checksum ceremony for no payoff). After first tag, PR to `SwiftPackageIndex/PackageList` for discoverability (SPI is index-only, not a host). **Gotcha:** generated product reference must match the *mirror repo name*, not the manifest `name:`.
- **Android:** Maven Central is layout-agnostic (ingests GAV + aar + POM + signatures) — monorepo subproject publishes fine, the *opposite* of the SwiftPM constraint. Vanniktech `com.vanniktech.maven.publish` (≥0.30.0 defaults to Central Portal; auto-generates sources+javadoc jars, signs). Namespace `io.github.sztheory` (verify via a temporary public repo). **Footguns:** GPG public key must be on a keyserver or verification fails; mandatory POM (name/desc/url/licenses/developers/scm) or upload rejected; no `-SNAPSHOT` for releases; **releases are immutable** — a botched `0.1.0` burns the version. Effort ≈ ½–1 day, dominated by GPG+POM, not review latency.
- **Lockstep:** release-please **manifest mode + `linked-versions`** registering Hex pkg + iOS mirror + Android lib in one group (highest-version-wins → identical versions). Propagate via `extra-files` generic updater annotating `mix.exs version:` and `build.gradle.kts version` with `x-release-please-version`; leave `Package.swift` alone (the git tag IS the SwiftPM version). Gate publish jobs `needs: release-please` + `if: releases_created` — the default `GITHUB_TOKEN` does NOT trigger downstream `release: published` workflows (loop-prevention). Best lockstep comparable to steal discipline from: **Tauri (covector)** / **Capacitor (lerna fixed mode)**; Hotwire Native's independent per-platform versioning is the *wrong* fit because it has no codegen tying versions together.
- **Template fix (LiveView Native pattern):** `mix lvn.swiftui.gen` reads `Application.spec(:live_view_native_swiftui)[:vsn]` and templates it into the SwiftPM dep as `from: "<%= @version %>"`. Crosswake mirror: read `Application.spec(:crosswake)[:vsn]`, emit iOS `.package(url: "https://github.com/szTheory/crosswake-shell-core-ios", from: "x.y.z")` and Android `implementation("io.github.sztheory:crosswake-shell-core-android:x.y.z")`. Prefer `from:` (up-to-next-major) so native patch/minor flow without regeneration; gate breaking changes at majors.

### Adopter-facing gaps ranked (from the adopter-experience subagent) — informs milestone #2/#3 ordering, NOT this one
1. 🔴 Native shell proof incomplete & conditionally gated — iOS proof local-only/fragile (Xcode+simulator, fails silent), default CI runs `CROSSWAKE_PHASE5_NATIVE_PROOFS: 0`.
2. 🔴 Android device/emulator proof missing — support matrix marks it `supported` but proof is JVM-hermetic only; `android_uat.md` is a bare checklist.
3. 🟡 Route policy DSL taught only by example — no `guides/route_policy.md`; syntax scattered across bridge/offline/native_shell/commerce guides.
4. 🟡 Pack versioning/availability underspecified — `packs.md` (78 lines) is vocabulary only; no declare/version/compatibility example.
5. 🟡 Android setup rough — `verify_generated_android_shell.sh` auto-downloads JDK/SDK/emulator to `~/.crosswake/...` (~20-30 min first run), undocumented.
6. 🟡 Offline integration path thin — `adoption.md` documents a 404 install path; no schema/migration/conflict-resolution walkthrough (ties to `mix crosswake.gen.sync`).
7. 🟡 Commerce provider adapters are seams not impls (by design) — needs an explicit "provider adapter roadmap" note.
8. 🟡 No troubleshooting / rough-edges guide — denial codes have no "if you see X check Y" flow.
9. 🟡 No migration story (existing Phoenix web app → mobile) — guides assume greenfield.
10. 🟡 ExDoc API modules don't cross-link to guides.

> Rough adopter effort to ship today (small team): ~4-8 weeks; iOS confidence medium, Android low-to-medium. Most of #1/#2/#5/#6 are partly *downstream* of fixing distribution (you can't honestly CI-prove a published native dep until it's published and consumed clean-room).

### Source reality check (from the source-truth subagent) — "what's real" baseline
- **Real & substantive:** policy/compiler (~1.8K LOC), manifest+compatibility (~3.7K), doctor (~3.6K, deep + fail-closed + publish-readiness), companions (~6.3K: sigra/chimeway/rindle + storekit/playbilling evidence), support_matrix (~1.7K), bridge (7 cmd families), offline (replay/journal/sync), commerce (corridor+entitlement seam). 9 real generators (gen.shell produces buildable Xcode+Gradle from 12 iOS/11 Android EEX templates). Test suite ~30K LOC / 133 files / **0 skipped** / 57 profile-proof lanes.
- **Native cores ARE substantive** (~1.9K LOC iOS, ~2.0K Android, parallel coordinator/channel architecture) — just **unpublished & test-thin** (1 test file each).
- **Repo hygiene (adopter first impression):** ~19 tracked root scripts (`fix_*.py`, `update_*.py`, `*.swift`), `erl_crash.dump`, `crosswake-checkpoint-*.bundle` — low-signal cruft to clean (consider folding a quick cleanup into the distribution milestone or its pre-step).
- **Subagent IDs (this session only — gone after `/clear`):** distribution research `a55084059009701d9`; adversarial ranking `af8a225575402dfcb` (its own plan file: `/Users/jon/.claude/plans/i-need-to-understand-modular-panda-agent-af8a225575402dfcb.md`).
