# Feature Research: v11.0 Release & Distribution Truth

**Domain:** Multi-language OSS package distribution — Hex + SwiftPM + Maven Central, generate-time version injection, lockstep release, clean-room build proof
**Researched:** 2026-06-14
**Confidence:** HIGH (grounded in: Apollo iOS blog / git subtree pattern; release-please manifest docs; SwiftPM SE-0292 root-manifest constraint; Maven Central OSSRH sunset docs; LiveView Native generator source; Vanniktech plugin docs; Hotwire Native getting-started page; release-please-action issue #1000 GITHUB_TOKEN limitation)

---

## Context: The Gap This Milestone Closes

The v5.0 "no eject trap" thesis — replace generated shell logic with standalone SPM/Maven dependencies — is implemented but not distributed. Current state:

- `mix crosswake.gen.shell ios` (default, `--local false`) emits a `.pbxproj` with `repositoryURL = "https://github.com/crosswake/crosswake-shell-core-ios.git"` (wrong org; repo absent).
- `mix crosswake.gen.shell android` emits `implementation 'dev.crosswake:shell-core-android:0.1.0'` (Maven artifact never published).
- When `--local` is true, templates use monorepo-relative paths (`../../../packages/…`) that break outside the exact checkout layout.
- `packages/crosswake-shell-core-ios/Package.swift` has no version. `packages/crosswake-shell-core-android/build.gradle.kts` has no `group`/`version`/`maven-publish`. No native publish CI exists.
- `guides/adoption.md` documents the SPM/Maven install path as if it works; it leads to a 404 build.

Every feature below is evaluated against one observable adopter test: a Phoenix developer outside this monorepo adds `{:crosswake, "~> 0.1.2"}` to their `mix.exs`, runs `mix crosswake.gen.shell ios` and `mix crosswake.gen.shell android`, and gets projects that `swift build` and `gradle build` without modification.

---

## Table Stakes (Users Expect These)

Missing any one of these makes the published library claim false and the adoption guide actively harmful.

| Feature | Why Expected | Complexity | Notes / Dependencies |
|---------|--------------|------------|----------------------|
| **iOS SPM core published at a semver git tag on a dedicated mirror repo** | SwiftPM cannot consume a monorepo subdir (SE-0292 root-manifest constraint; package identity = repo root). Any dep URL pointing at the monorepo silently fails resolution. Adopter assumes a dep URL works before even reading further docs. | MEDIUM | Requires creating `github.com/szTheory/crosswake-shell-core-ios`; adding CI job that runs `git subtree split` (or `splitsh-lite`) on every release and pushes + annotated-tags the mirror. The `Package.swift` already has correct structure; no code changes needed to the package itself. One-time repo setup + CI wiring. |
| **Android core published to Maven Central under `io.github.sztheory` namespace** | Adopters adding a Gradle dep assume it resolves from `mavenCentral()` — which is already in the generated `settings.gradle`. A 404 artifact is indistinguishable from a typo. | MEDIUM | Add `group`/`version` to `packages/crosswake-shell-core-android/build.gradle.kts`; apply `com.vanniktech.maven.publish` (>=0.30.0 defaults to Central Portal; OSSRH was shut down 2025-06-30 so the Central Portal path is mandatory). GPG signing + public key on `keyserver.ubuntu.com`. Mandatory POM fields: name, description, url, licenses, developers, scm. Effort ~half day dominated by GPG and POM setup, not review latency. Releases are immutable — a botched `0.1.0` burns the version. |
| **`gen.shell` templates inject the Crosswake Hex version at generate-time** | The generated `Package.swift` dep or `build.gradle` dep must reference the exact version of the native core that matches the Hex package the adopter installed. Hardcoded or absent versions produce non-reproducible builds or resolution failures. | LOW | Read `Application.spec(:crosswake)[:vsn]` in `crosswake.gen.shell.ex` (the LiveView Native `lvn.swiftui.gen` pattern: `Application.spec(:live_view_native_swiftui)[:vsn]`). Pass `version` into the EEX assign alongside `capabilities` and `local`. iOS template: emit `.package(url: "https://github.com/szTheory/crosswake-shell-core-ios", from: "<%= @version %>")`. Android template: emit `implementation("io.github.sztheory:crosswake-shell-core-android:<%= @version %>")`. Delete the current hardcoded `version = 0.1.0` and `'dev.crosswake:shell-core-android:0.1.0'` literals. Dependency: the published artifacts must exist before this template change is testable end-to-end. |
| **Default mode (`--local false`) generates resolvable, version-matched dep coordinates** | `--local false` is the default. The current default produces a build that fails immediately. This is the flagship adopter experience. | LOW | Follows from the template rewire above. The `--local true` path (monorepo dev) can remain unchanged. The non-local path must never reference a monorepo-relative path or a nonexistent URL. |
| **`guides/adoption.md` and support matrix reflect published truth** | A guide that documents a 404 install path is net-harmful — it creates support burden and erodes trust faster than having no guide. | LOW | Update `guides/adoption.md` to: remove the phantom install instructions, document the real SPM/Maven dep coordinates and version constraint, explain that `gen.shell` injects the version automatically. Reconcile `guides/support_matrix.md` to whatever native proof level is honest at cut time. Cut Hex `0.1.2` to publish the changes. |
| **Clean-room CI acceptance lane outside the monorepo** | The only proof that "an adopter can build" is actually running the build as an adopter would — in a fresh directory, with no monorepo context, against published artifacts. Internal CI running `--local true` is not this proof. | HIGH | A GitHub Actions workflow that: (1) checks out the monorepo only to invoke `mix crosswake.gen.shell ios` and `mix crosswake.gen.shell android` into a temp directory, (2) `cd`s into the generated output, (3) runs `swift build` (or `xcodebuild -scheme`) and `./gradlew assembleDebug`, (4) asserts exit 0. Must run against the *published* Hex version + *published* native artifacts, not monorepo paths. This is the single observable definition of "done" for the milestone. Complexity is high because it requires real published artifacts to exist first; it is the last step and gates the closeout. |

---

## Differentiators (Competitive Advantage)

These are not expected by adopters who haven't seen them, but they are what separates "distributes a library" from "maintains a distribution discipline." Each maps to a failure mode from a comparable project.

| Feature | Value Proposition | Complexity | Notes / Dependencies |
|---------|-------------------|------------|----------------------|
| **Lockstep versioning via release-please manifest + `linked-versions`** | Guarantees Hex `0.1.2`, iOS mirror tag `0.1.2`, and Maven `io.github.sztheory:crosswake-shell-core-android:0.1.2` are always the same number. The generated code always references a version that exists in all three registries simultaneously. Prevents the LiveView Native drift bug (hardcoded satellite version diverges from main). | MEDIUM | Extend `release-please-config.json` with `linked-versions` plugin grouping all three packages. Add iOS mirror package entry and Android package entry to the manifest. Use `extra-files` generic updater to propagate the version into `build.gradle.kts` via `x-release-please-version` annotation. Leave `Package.swift` alone — the git tag IS the SwiftPM version. Gate native publish jobs with `needs: release-please` + `if: releases_created`. Critical: use `RELEASE_PLEASE_TOKEN` (fine-grained PAT), not `GITHUB_TOKEN` — the default token does not trigger downstream workflows (release-please-action issue #1000); this is already established practice in the current `release-please.yml`. |
| **`mix doctor --check-publish` "published-dep parity" check** | After publish, a doctor check asserts the generated shell dep coordinates point at published, resolvable, version-matched artifacts — not monorepo paths. Structural analogue to the v10.0 `brand-structural` drift gate: a merge-blocking CI assertion that the distribution thesis stays honest. Catches regressions where a template edit re-introduces a local path or wrong org URL. | LOW | Add a doctor finding that reads `Application.spec(:crosswake)[:vsn]`, constructs the expected iOS URL + Android GAV, and asserts reachability (HTTP HEAD against `https://github.com/szTheory/crosswake-shell-core-ios/releases/tag/{vsn}` and `https://central.sonatype.com/api/v1/publisher/status?…`). Wire into CI as a merge-blocking check after publish. Dependency: published artifacts must exist. This is the graduation candidate from the `release-distribution-truth.md` thread. |
| **`from:` (up-to-next-major) SwiftPM constraint, not exact pinning** | `from: "0.1.2"` resolves the minimum and allows native patch/minor updates to flow without regeneration — the standard SwiftPM consumer expectation. Exact pinning (`exact: "0.1.2"`) forces adopters to re-run `gen.shell` on every patch. Branch pinning (`branch: "main"`) discards the version guarantee entirely (Capacitor issue #7735 anti-pattern). | LOW | Template change only; complexity is documentation and decision. `upToNextMajor(from: "0.1.2")` is the SPM idiomatic form; `.package(url:, from: "0.1.2")` is the shorthand. Gate breaking changes at major versions. |
| **Source distribution for iOS, not `.binaryTarget`** | Binary targets cannot declare their own Swift package dependencies, require checksum ceremony, and add download-size opacity. Source distribution is idiomatic for a framework-level package. Swift Package Index can index it. | LOW | `Package.swift` already uses source targets. This is a non-decision that should be documented to prevent future "let's ship an XCFramework" proposals. |

---

## Anti-Features (Explicitly Avoid)

Each of these appears attractive but causes concrete, documented failures in comparable projects.

| Feature | Why Requested | Why Problematic | Correct Alternative |
|---------|---------------|-----------------|---------------------|
| **"Use latest" in docs or templates (no version specified)** | Simplifies docs; avoids the "which version?" question | Hotwire Native does exactly this — docs say "add the package URL" with no version; adopters get non-reproducible builds, silent breakage on next SPM resolve. Xcode auto-resolves to whatever HEAD the remote has, which may be incompatible. | Inject the exact version at generate-time. Docs show version-pinned examples. |
| **Branch-pinning a SwiftPM dep (`branch: "main"`)** | Feels like "always current"; tempting during development | Capacitor's SPM migration pinned `capacitor-swift-pm.git` to `branch: "main"` (issue #7735), discarding version-sync. Packages using branch deps cannot themselves be used as versioned deps by other packages — blocks composition. SPM explicitly prohibits publishing a versioned package that has branch-pinned deps. | Pin to a tag using `from:` or `exact:`. Use the mirror tag that corresponds to the Hex version. |
| **Monorepo-relative local paths in the default non-local mode** | Easiest to implement during local dev; sidesteps the publish requirement | Capacitor (pnpm/monorepo hoisting breaks `../../node_modules/…`) and Hotwire demo local paths are the textbook example. This is Crosswake's current bug in the default path. Any adopter outside the exact checkout layout gets an immediate build failure with a confusing error. | Published versioned artifacts only in default mode. `--local true` path kept for monorepo development. |
| **Binary/AAR distribution via GitHub Releases instead of Maven Central** | Avoids GPG setup and Maven POM ceremony | Not indexed by `mavenCentral()` — adopters must add a custom repository URL. Breaks the promise that a standard `settings.gradle` with `mavenCentral()` suffices. No transitive dependency metadata. No immutability guarantee. | Publish to Maven Central via Central Portal. The ceremony is ~half a day; the benefit is indefinite. |
| **Independent per-platform version numbers** | Easier for platform maintainers; each platform "releases when ready" | If iOS is `0.2.0` and Android is `0.1.4` and Hex is `0.1.3`, the generated code (which must reference specific versions) has no single number to read from `Application.spec(:crosswake)[:vsn]`. The adopter must manage three version variables. This is Hotwire Native's model — wrong fit for Crosswake because Crosswake has codegen that ties the versions together. | `linked-versions` in release-please manifest mode. One version everywhere. |
| **Separate "native publish" milestone after the Hex cut** | Seems lower risk; decouple the steps | Cuts Hex `0.1.2` while `gen.shell` still emits nonexistent dep coordinates. Any adopter who installs `0.1.2` before native publish completes gets a broken scaffold. The adoption guide (which will reference `0.1.2`) becomes actively harmful during the window between Hex cut and native publish. | Publish native cores first (or atomically). Hex cut is the last step, after native publish and template rewire are verified. |
| **Shipping a Package.swift with a `version:` field** | Looks explicit; matches the project's version | `Package.swift` has no `version:` field in the manifest spec. The git tag IS the SwiftPM version — SwiftPM resolves `from: "0.1.2"` by looking for git tags named `0.1.2` or `v0.1.2`. Adding a `version:` to `Package.swift` is a no-op that creates confusion. | Apply annotated git tags to the mirror repo. No change to `Package.swift`. |

---

## Feature Dependencies

```
[iOS mirror repo + semver tag]
    └──required-by──> [gen.shell iOS template: from: "<%= @version %>"]
                          └──required-by──> [clean-room swift build proof]

[Maven Central publish: io.github.sztheory:crosswake-shell-core-android:x.y.z]
    └──required-by──> [gen.shell Android template: implementation("io.github.sztheory:...:x.y.z")]
                          └──required-by──> [clean-room gradle build proof]

[gen.shell version inject (Application.spec(:crosswake)[:vsn])]
    └──required-by──> [lockstep: version in template matches published artifact version]

[release-please linked-versions config]
    └──required-by──> [lockstep: Hex ver = iOS tag = Maven ver at every release]
    └──enhanced-by──> [published-dep parity doctor check]

[clean-room CI acceptance lane]
    └──required-by──> [closeout gate: milestone "done"]
    └──depends-on──> [all of the above must exist and be real]

[guides/adoption.md reconciliation + Hex 0.1.2 cut]
    └──depends-on──> [clean-room proof passes first]
    └──is-last-step──> [do not cut 0.1.2 while gen.shell still emits broken coordinates]
```

### Dependency Notes

- **iOS mirror required before gen.shell template change**: The template can be written in advance, but the clean-room test will fail until the mirror exists and has the target tag. The wiring order within Phase A is: create repo → push code → apply tag → verify `swift build` resolves → commit template change.
- **Maven Central publish required before Android template change**: Same sequencing. The artifact must exist at `io.github.sztheory:crosswake-shell-core-android:0.1.2` before the clean-room `gradle build` can pass.
- **Version inject depends on `Application.spec` returning the right version**: The Hex package must have `@version "0.1.2"` in `mix.exs` and be compiled in the adopter's dep tree. This is guaranteed once the adopter installs the Hex dep; the assign is computed at mix task runtime, not at compile time of the library.
- **Doctor parity check conflicts with pre-publish state**: The doctor check should only be enabled (or set to non-failing) after at least one successful publication. Wire it into post-publish CI, not pre-publish.

---

## MVP Definition for v11.0

### Phase A: Publish Native Cores

- [ ] Create `github.com/szTheory/crosswake-shell-core-ios`, add CI subtree-split job, push code, apply annotated tag `0.1.2` — verify `swift build` resolves from the tag.
- [ ] Add `group`/`version`/Vanniktech `maven-publish` to `packages/crosswake-shell-core-android/build.gradle.kts`; configure Central Portal credentials + GPG; publish `io.github.sztheory:crosswake-shell-core-android:0.1.2` — verify it appears in `search.maven.org`.
- [ ] Wire `release-please-config.json` `linked-versions` to group Hex + iOS mirror + Android, so future releases stay lockstep.
- [ ] Hex `0.1.2` cut (after native publish verified — not before).

### Phase B: Template Rewire + Proof + Docs

- [ ] Inject `Application.spec(:crosswake)[:vsn]` into `gen.shell` EEX assigns; rewrite iOS and Android dep blocks to use injected version at correct published coordinates; delete hardcoded literals and wrong-org URL.
- [ ] Clean-room CI lane: generate outside monorepo, `swift build`, `./gradlew assembleDebug`, assert exit 0 against published `0.1.2` artifacts.
- [ ] Reconcile `guides/adoption.md` to published truth; update support matrix.
- [ ] Add `doctor --check-publish` parity check as merge-blocking CI lane (graduation candidate).

### Defer to Post-v11.0

- [ ] Real native device proof (iOS simulator CI, Android emulator CI) — currently out of scope per milestone definition; follows once the distribution path is honest.
- [ ] Route-policy-101 guide, troubleshooting guide, web-to-mobile migration — teaching a broken install path is net-harmful; these follow v11.0.
- [ ] Companion package extraction, new capability breadth — overbuilding on an undistributed base.

---

## Feature Prioritization Matrix

| Feature | Adopter Value | Implementation Cost | Priority |
|---------|---------------|---------------------|----------|
| iOS mirror + semver tag | HIGH (blocks any iOS adoption) | MEDIUM | P1 |
| Maven Central publish | HIGH (blocks any Android adoption) | MEDIUM | P1 |
| gen.shell version inject | HIGH (broken default is the flagship anti-feature) | LOW | P1 |
| Clean-room CI acceptance lane | HIGH (only real proof of the milestone thesis) | HIGH | P1 |
| guides/adoption.md reconciliation | HIGH (active harm if wrong) | LOW | P1 |
| Hex 0.1.2 cut | HIGH (makes v10.0 work publicly installable) | LOW | P1 — last step |
| release-please linked-versions | HIGH (prevents drift at next release) | MEDIUM | P1 — do with Phase A |
| `from:` constraint (not exact/branch) | MEDIUM (ergonomics, future updates) | LOW | P1 — template decision |
| doctor parity check | MEDIUM (structural drift guard) | LOW | P2 — graduation candidate |
| Source vs binary iOS decision | LOW (correct by default, doc it) | LOW | P2 — document not build |

**Priority key:**
- P1: Required for milestone closeout (adopter can build)
- P2: Should do in this milestone but not blocking; add after P1 lane passes

---

## Ecosystem Comparable Patterns (Evidence Base)

| Pattern | Comparable Project | How They Do It | Crosswake Application |
|---------|-------------------|---------------|----------------------|
| Monorepo subdir → standalone SPM package | Apollo iOS | CI git subtree split + push to read-only mirror repo on every merge; adopters consume the mirror URL | `packages/crosswake-shell-core-ios/` → `github.com/szTheory/crosswake-shell-core-ios` via CI subtree job |
| Generate-time version injection | LiveView Native (`lvn.swiftui.gen`) | `Application.spec(:live_view_native_swiftui)[:vsn]` read at generate-time, templated into SwiftPM dep as `from:` | `Application.spec(:crosswake)[:vsn]` → iOS `from:` + Android GAV version segment |
| Lockstep multi-platform release | Tauri (covector) / Capacitor (lerna fixed mode) | Single version number across all platform packages; bump in one place propagates everywhere | release-please manifest `linked-versions` group |
| "Use latest" anti-pattern | Hotwire Native iOS docs | Getting-started page says "enter the URL" with no version — Xcode resolves to whatever HEAD is | Inject exact version; never emit a dep without a version constraint |
| Branch-pin anti-pattern | Capacitor SPM migration (issue #7735) | Pinned `branch: "main"`, discarding version-sync; composition blocked | `from:` only; branch never appears in emitted templates |
| Maven Central mandatory: Central Portal | All Android libraries post-2025-06-30 | OSSRH shut down; must use `central.sonatype.com`; Vanniktech >=0.30.0 defaults to this | Vanniktech plugin with Central Portal credentials; no OSSRH |
| GITHUB_TOKEN doesn't trigger downstream workflows | release-please-action issue #1000 | Default token's releases don't trigger `release: published` events | Use `RELEASE_PLEASE_TOKEN` (fine-grained PAT) already in use; gate native publish with `needs: release-please` + `if: releases_created` in same workflow |

---

## Acceptance Behavior: Observable Criteria for Clean-Room Proof

The clean-room lane passes when, in a CI runner with no monorepo checkout and no local `packages/` directory:

1. `mix archive.install hex crosswake 0.1.2 --force` succeeds.
2. `mix crosswake.gen.shell ios --target /tmp/test-host` emits a `.pbxproj` containing `repositoryURL = "https://github.com/szTheory/crosswake-shell-core-ios.git"` and a version string matching `0.1.2` with no local-path reference.
3. `cd /tmp/test-host/native/ios/crosswake_shell && swift build` exits 0. Package resolution contacts the mirror repo and resolves the `0.1.2` tag.
4. `mix crosswake.gen.shell android --target /tmp/test-host` emits a `build.gradle` containing `implementation("io.github.sztheory:crosswake-shell-core-android:0.1.2")` and a `settings.gradle` with only `mavenCentral()` (no local project include).
5. `cd /tmp/test-host/native/android/crosswake_shell && ./gradlew assembleDebug` exits 0. Gradle resolves the artifact from Maven Central.

This is not aspirational — it is the literal observable output of the acceptance CI lane, runnable by any maintainer or contributor to validate the milestone claim.

---

## Sources

- Apollo iOS subtree pattern: [apollographql.com/blog](https://www.apollographql.com/blog/how-apollo-manages-swift-packages-in-a-monorepo-with-git-subtrees) (HIGH confidence — first-party blog post)
- release-please manifest + linked-versions: [github.com/googleapis/release-please/docs/manifest-releaser.md](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md) (HIGH confidence — official docs)
- release-please GITHUB_TOKEN downstream trigger limitation: [googleapis/release-please-action issue #1000](https://github.com/googleapis/release-please-action/issues/1000) (HIGH confidence — maintainer confirmed)
- SwiftPM `from:` vs `branch:` restriction: [Swift Forums SPM dependency resolution thread](https://forums.swift.org/t/spm-dependency-resolution-version-vs-tag-branch/30089) + [swift-evolution SE-0292](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0292-package-registry-service.md) (HIGH confidence — Apple official)
- Maven Central OSSRH sunset + Central Portal requirement: [central.sonatype.org/publish/requirements/gpg](https://central.sonatype.org/publish/requirements/gpg/) (HIGH confidence — Sonatype official)
- Vanniktech gradle-maven-publish-plugin: [vanniktech.github.io/gradle-maven-publish-plugin](https://vanniktech.github.io/gradle-maven-publish-plugin/what/) (HIGH confidence — official docs)
- Hotwire Native "no version specified" anti-pattern: [native.hotwired.dev/ios/getting-started](https://native.hotwired.dev/ios/getting-started) (HIGH confidence — live docs, confirmed URL-only instruction with no version)
- Capacitor branch-pin anti-pattern: referenced in `.planning/threads/release-distribution-truth.md` as issue #7735 (MEDIUM confidence — thread research; not independently re-verified here)
- LiveView Native version-injection pattern: referenced in `.planning/threads/release-distribution-truth.md` (MEDIUM confidence — thread research; GitHub source not independently fetched due to tool constraints)
- Existing Crosswake code: `lib/mix/tasks/crosswake.gen.shell.ex`, `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex`, `priv/templates/crosswake/shell/android/app/build.gradle.eex`, `priv/templates/crosswake/shell/android/settings.gradle.eex`, `packages/crosswake-shell-core-{ios/Package.swift,android/build.gradle.kts}`, `.github/workflows/release-please.yml`, `release-please-config.json` (HIGH confidence — read directly)

---

*Feature research for: v11.0 Release & Distribution Truth — multi-language OSS distribution flows*
*Researched: 2026-06-14*
