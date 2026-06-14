# Stack Research

**Domain:** OSS library release & distribution — iOS SPM subtree mirroring, Android Maven Central publish, lockstep versioning, generate-time version injection
**Researched:** 2026-06-14
**Confidence:** HIGH (all versions verified against official releases; config syntax verified against official docs)

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `splitsh/lite` | v2.0.0 | Subtree-split `packages/crosswake-shell-core-ios/` → dedicated mirror repo, preserving full git history | Only fast, production-proven subtree splitter with CI GitHub Action ecosystem; Apollo iOS uses this exact pattern to solve the SwiftPM root-manifest constraint. v2.0.0 is the latest stable (released 2025-10-26). |
| `com.vanniktech.maven.publish` | 0.31.0 | Publish the Android AAR + sources/javadoc to Maven Central via Central Portal | Auto-generates required sources + javadoc jars, handles signing, defaults to Central Portal at 0.30.0+. **Use 0.31.0 not 0.36.0** — 0.36.0 requires Gradle 9.0.0 + AGP 8.13.0, which exceeds the project's current `gradle-8.7` + `compileSdk 34`. 0.31.0 works with Gradle 8.5+ and AGP 8.0.0+. |
| `googleapis/release-please-action` | v4.4.1 (SHA `5c625bf`) | Open/update Release PR; emit `release_created` + `tag_name` + `version` outputs that gate native publish jobs | Already wired. Manifest mode already active (`release-please-config.json` + `.release-please-manifest.json` exist). v5.0.0 (released 2026-04-22) exists but is a major bump (Node 24) with no config-format changes; stay on v4.4.1 until the project has a clear upgrade window. |
| SwiftPM (source distribution) | swift-tools 5.9 (existing) | Consumer-facing package format for iOS core | Already at 5.9 in `Package.swift`. Source distribution only — no `.binaryTarget`. The git tag IS the version; no version field in `Package.swift` is correct. |
| `EEx` version injection in `gen.shell` | — (Elixir stdlib) | Inject `Application.spec(:crosswake, :vsn)` at generate-time into iOS `.package(url:, from:)` and Android `implementation("…:x.y.z")` | LiveView Native's `mix lvn.swiftui.gen` does exactly this; it's Elixir stdlib, zero new deps. |

### Supporting Tools / Actions

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `splitsh/lite` binary (direct install) | v2.0.0 | GitHub Actions split-and-push step | Download tarball from GitHub releases in CI; more version-stable than third-party action wrappers around splitsh |
| `actions/checkout` | v4 | Checkout in splitsh CI job | Must use `fetch-depth: 0` — shallow clone breaks splitsh-lite |
| GPG in-memory signing | — (GnuPG, standard) | Sign Maven artifacts for Central Portal | Configure via `ORG_GRADLE_PROJECT_signingInMemoryKey` + `signingInMemoryKeyId` + `signingInMemoryKeyPassword` secrets; no keyring file needed in CI |
| `SwiftPackageIndex/PackageList` | — | Discoverability index for the iOS mirror repo | Submit a PR adding the mirror repo URL to `packages.json` after the first tag is live; SPI is index-only, not a host — one PR, done |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `release-please-config.json` `linked-versions` plugin | Lock Hex + iOS tag + Maven version together so a single Release PR bumps all three | Add `"plugins": [{"type": "linked-versions", "groupName": "crosswake", "components": ["hex", "ios-core", "android-core"]}]` alongside the existing `.` Elixir package entry; each package entry needs a `"component"` key |
| `release-please extra-files` | Update `mix.exs @version` and `build.gradle.kts version` via `x-release-please-version` inline annotation | Add per-package `"extra-files"` entries; annotate version lines with `# x-release-please-version` |
| `RELEASE_PLEASE_TOKEN` (fine-grained PAT) | Required for release-please-created PRs and tags to trigger required CI | **Critical gotcha (issue #1000):** `GITHUB_TOKEN` cannot trigger other workflow runs by design. Same-file job chaining via `needs: release-please` + `if: releases_created` bypasses this — it is job-graph chaining, not a new workflow event. The existing `release-please.yml` already uses this pattern for `publish-hex`; native publish jobs must live in the same file. |

---

## Config Blocks

### release-please-config.json — Updated shape

The existing config has one package at `.` with `release-type: elixir`. Add two more packages and the `linked-versions` plugin:

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "bootstrap-sha": "f788e312747e14b157c8498ba710f057534530f5",
  "bump-minor-pre-major": false,
  "bump-patch-for-minor-pre-major": true,
  "plugins": [
    {
      "type": "linked-versions",
      "groupName": "crosswake",
      "components": ["hex", "ios-core", "android-core"]
    }
  ],
  "packages": {
    ".": {
      "component": "hex",
      "release-type": "elixir",
      "skip-changelog": true,
      "extra-files": ["mix.exs"],
      "changelog-sections": [
        { "type": "feat", "section": "Features" },
        { "type": "fix", "section": "Bug Fixes" },
        { "type": "perf", "section": "Performance Improvements" },
        { "type": "deps", "section": "Dependencies" },
        { "type": "chore", "section": "Miscellaneous", "hidden": true },
        { "type": "docs", "section": "Documentation", "hidden": true },
        { "type": "test", "section": "Tests", "hidden": true },
        { "type": "ci", "section": "Continuous Integration", "hidden": true },
        { "type": "refactor", "section": "Refactoring", "hidden": true },
        { "type": "build", "section": "Build System", "hidden": true }
      ]
    },
    "packages/crosswake-shell-core-ios": {
      "component": "ios-core",
      "release-type": "simple",
      "skip-changelog": true
    },
    "packages/crosswake-shell-core-android": {
      "component": "android-core",
      "release-type": "simple",
      "skip-changelog": true,
      "extra-files": [
        {
          "type": "generic",
          "path": "packages/crosswake-shell-core-android/build.gradle.kts"
        }
      ]
    }
  }
}
```

**Note on `Package.swift`:** Do NOT add it to `extra-files`. The git tag is the SwiftPM version; SwiftPM reads the annotated tag, not a version field in the manifest. There is no `version` field in the iOS `Package.swift` to update.

**Note on `mix.exs`:** The generic updater finds lines annotated with `# x-release-please-version`. Add the annotation to the existing version line:
```elixir
@version "0.1.2" # x-release-please-version
```

**Note on `build.gradle.kts`:** The Android library module does not yet have a top-level `version` line. Add one (see Vanniktech config below) and annotate it:
```kotlin
version = "0.1.0" // x-release-please-version
```

### .release-please-manifest.json — Updated shape

```json
{
  ".": "0.1.2",
  "packages/crosswake-shell-core-ios": "0.1.0",
  "packages/crosswake-shell-core-android": "0.1.0"
}
```

Set the iOS and Android initial versions to `0.1.0` (the first published versions); linked-versions will sync them forward with the Hex package from there.

### packages/crosswake-shell-core-android/build.gradle.kts — Additions

```kotlin
plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
    id("kotlinx-serialization")
    id("com.vanniktech.maven.publish") version "0.31.0"
}

// Top-level version for release-please annotation and Maven publish
version = "0.1.0" // x-release-please-version

android {
    namespace = "dev.crosswake.shell.core"
    compileSdk = 34
    // ... existing config unchanged ...
}

mavenPublishing {
    publishToMavenCentral(SonatypeHost.CENTRAL_PORTAL, automaticRelease = true)
    signAllPublications()

    coordinates("io.github.sztheory", "crosswake-shell-core-android", version.toString())

    pom {
        name.set("Crosswake Shell Core Android")
        description.set("Android native shell core for the Crosswake Phoenix library.")
        inceptionYear.set("2024")
        url.set("https://github.com/szTheory/crosswake")

        licenses {
            license {
                name.set("MIT License")
                url.set("https://opensource.org/licenses/MIT")
                distribution.set("https://opensource.org/licenses/MIT")
            }
        }

        developers {
            developer {
                id.set("szTheory")
                name.set("szTheory")
                url.set("https://github.com/szTheory/")
            }
        }

        scm {
            url.set("https://github.com/szTheory/crosswake/")
            connection.set("scm:git:git://github.com/szTheory/crosswake.git")
            developerConnection.set("scm:git:ssh://git@github.com/szTheory/crosswake.git")
        }
    }
}
```

### Required GitHub Secrets for Android publish CI

```
ORG_GRADLE_PROJECT_mavenCentralUsername       # Sonatype user token (NOT your login — generate at central.sonatype.com)
ORG_GRADLE_PROJECT_mavenCentralPassword       # Sonatype user token password
ORG_GRADLE_PROJECT_signingInMemoryKey         # ASCII-armored GPG key: gpg --export-secret-keys --armor <key-id>
ORG_GRADLE_PROJECT_signingInMemoryKeyId       # Short key ID (last 8 hex chars)
ORG_GRADLE_PROJECT_signingInMemoryKeyPassword # GPG key passphrase
```

GPG public key **must be uploaded to a public keyserver** (`keys.openpgp.org` or `keyserver.ubuntu.com`) or Central Portal's signature verification will fail silently.

### iOS subtree-split CI job (append to release-please.yml)

```yaml
  publish-ios-core:
    name: Mirror iOS core to split repo
    needs: release-please
    if: ${{ needs.release-please.outputs.release_created == 'true' }}
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0   # REQUIRED — splitsh-lite needs full history; shallow clone breaks splits

      - name: Install splitsh-lite v2.0.0
        run: |
          curl -L https://github.com/splitsh/lite/releases/download/v2.0.0/lite_linux_amd64.tar.gz \
            | tar xz
          sudo mv splitsh-lite /usr/local/bin/splitsh-lite

      - name: Split packages/crosswake-shell-core-ios subtree
        run: |
          SHA=$(splitsh-lite --prefix=packages/crosswake-shell-core-ios)
          echo "SPLIT_SHA=$SHA" >> "$GITHUB_ENV"

      - name: Push split to mirror repo and tag
        env:
          MIRROR_TOKEN: ${{ secrets.MIRROR_PUSH_TOKEN }}
          TAG: ${{ needs.release-please.outputs.tag_name }}
        run: |
          git remote add mirror \
            "https://x-access-token:${MIRROR_TOKEN}@github.com/szTheory/crosswake-shell-core-ios.git"
          git push mirror "${SPLIT_SHA}:refs/heads/main" --force
          git push mirror "${SPLIT_SHA}:refs/tags/${TAG}" --force
```

`MIRROR_PUSH_TOKEN` is a fine-grained PAT with `Contents: write` on `szTheory/crosswake-shell-core-ios`. This is distinct from `RELEASE_PLEASE_TOKEN`.

**Tag naming:** push the bare release-please `tag_name` (e.g. `v0.1.2`) to the mirror — that is what SwiftPM resolves. Do not manufacture a compound tag.

### Android publish CI job (append to release-please.yml)

```yaml
  publish-android-core:
    name: Publish Android core to Maven Central
    needs: release-please
    if: ${{ needs.release-please.outputs.release_created == 'true' }}
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ needs.release-please.outputs.tag_name }}

      - uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Publish to Maven Central
        working-directory: packages/crosswake-shell-core-android
        env:
          ORG_GRADLE_PROJECT_mavenCentralUsername: ${{ secrets.ORG_GRADLE_PROJECT_mavenCentralUsername }}
          ORG_GRADLE_PROJECT_mavenCentralPassword: ${{ secrets.ORG_GRADLE_PROJECT_mavenCentralPassword }}
          ORG_GRADLE_PROJECT_signingInMemoryKey: ${{ secrets.ORG_GRADLE_PROJECT_signingInMemoryKey }}
          ORG_GRADLE_PROJECT_signingInMemoryKeyId: ${{ secrets.ORG_GRADLE_PROJECT_signingInMemoryKeyId }}
          ORG_GRADLE_PROJECT_signingInMemoryKeyPassword: ${{ secrets.ORG_GRADLE_PROJECT_signingInMemoryKeyPassword }}
        run: ./gradlew publishToMavenCentral --no-daemon
```

### gen.shell version injection — EEx template changes

**`lib/mix/tasks/crosswake.gen.shell.ex` — add `version` to `render_template` binding:**

```elixir
defp render_template(template_path, capabilities, local) do
  template =
    Application.app_dir(:crosswake, Path.join("priv/templates/crosswake/shell", template_path))

  version = Application.spec(:crosswake, :vsn) |> to_string()
  EEx.eval_file(template, assigns: [capabilities: capabilities, local: local, version: version])
end
```

**iOS `project.pbxproj.eex` — fix org and use `@version` + `upToNextMajorVersion`:**

Replace the existing `XCRemoteSwiftPackageReference` block (lines 53-61) with:

```eex
/* Begin XCRemoteSwiftPackageReference section */
    B10000010000000000000001 /* XCRemoteSwiftPackageReference "crosswake-shell-core-ios" */ = {
        isa = XCRemoteSwiftPackageReference;
        repositoryURL = "https://github.com/szTheory/crosswake-shell-core-ios.git";
        requirement = {
            kind = upToNextMajorVersion;
            minimumVersion = <%= @version %>;
        };
    };
/* End XCRemoteSwiftPackageReference section */
```

Use `upToNextMajorVersion` (SwiftPM `from:` equivalent) not `exactVersion` — allows native patch/minor updates without regeneration; breaking changes gate at majors.

**Android `app/build.gradle.eex` — fix group ID and use `@version`:**

Replace the existing remote dep line (currently `implementation 'dev.crosswake:shell-core-android:0.1.0'`):

```eex
<% if @local do %>
  implementation project(':crosswake-shell-core-android')
<% else %>
  implementation("io.github.sztheory:crosswake-shell-core-android:<%= @version %>")
<% end %>
```

---

## Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| `splitsh/lite` subtree mirror | `git subtree split` (built-in) | Slower, no CI action ecosystem, produces inconsistent SHAs across machines; splitsh-lite is purpose-built for this |
| `splitsh/lite` subtree mirror | SPM `localPackage` with monorepo `path:` | SwiftPM root-manifest constraint (SE-0292): package identity equals the repo root; no `subdirectory:` param exists; consumers cannot add a monorepo subdir as an SPM dep over git URL |
| Source distribution | `.binaryTarget` XCFramework | binaryTarget cannot declare its own deps, adds GPG checksum ceremony on every publish, breaks Catalyst/Linux toolchain consumers; source is simpler and correct for this library |
| `com.vanniktech.maven.publish` | `maven-publish` (Gradle built-in) | Built-in requires manual sources/javadoc jar wiring, manual POM, manual signing — Vanniktech wraps all of it and is the OSS community standard |
| 0.31.0 Vanniktech | 0.36.0 Vanniktech (latest) | 0.36.0 requires Gradle 9.0.0 + AGP 8.13.0; project currently on gradle-8.7 + compileSdk 34; upgrade cost exceeds benefit; revisit when Gradle is bumped |
| Central Portal | OSSRH (legacy Sonatype) | OSSRH sunset 2025-06-30 — it is gone; Central Portal is the only current path |
| `linked-versions` plugin | Independent per-platform versioning | Hotwire Native versions platforms independently because there is no codegen coupling them; Crosswake `gen.shell` derives native dep coordinates from the Hex version — they must be identical |
| Same-workflow job chaining | Separate `on: release: types: [published]` workflow | `GITHUB_TOKEN` does not trigger cross-workflow events (deliberate GitHub security restriction); same-file job chaining via `needs:` + `if: releases_created` bypasses this without a PAT for the publish step |
| `upToNextMajorVersion` in pbxproj | `exactVersion` (current broken template) | Exact pinning requires adopters to manually bump the generated file on every patch/minor release; `from:` range is the SPM convention |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `.binaryTarget` in Package.swift | Cannot declare deps; adds checksum ceremony; no cross-platform toolchain support | Source distribution — current Package.swift shape is already correct |
| `-SNAPSHOT` version suffix | Central Portal rejects snapshot coordinates in release deployments | Bare semver only: `0.1.0`, `0.1.2`, etc. |
| Re-tagging an existing semver on the mirror | Maven Central releases are immutable; iOS annotated tags cannot be force-pushed to a published dep | Cut a patch version; burn the slot if necessary |
| Branch-pinning SwiftPM dep (`branch: "main"`) | Discards version-sync guarantee; causes reproducibility failures (Capacitor issue #7735) | Pin to `upToNextMajorVersion` / `from:` with a semver tag |
| Hardcoded version literals in generated templates | Causes silent drift when the main version advances (LiveView Native `LiveViewNativeLiveForm` bug pattern) | Derive every native dep coordinate from `Application.spec(:crosswake, :vsn)` |
| Wrong org in iOS template (`crosswake/` prefix) | Current bug: `https://github.com/crosswake/crosswake-shell-core-ios.git` is a 404 | Fix to `https://github.com/szTheory/crosswake-shell-core-ios.git` |
| `on: release: types: [published]` workflow triggered by GITHUB_TOKEN release | Will not fire — GITHUB_TOKEN cannot chain-trigger other workflows | Inline publish jobs in the same `release-please.yml` file using `needs:` + `if: releases_created` |

---

## Version Compatibility

| Component | Version | Requires | Notes |
|-----------|---------|----------|-------|
| `splitsh/lite` | v2.0.0 | `fetch-depth: 0` in `actions/checkout` | Shallow clone produces broken/inconsistent splits |
| `com.vanniktech.maven.publish` | 0.31.0 | JDK 17, Gradle 8.5+, AGP 8.0+ | Compatible with project's existing `gradle-8.7` and `compileSdk 34` |
| `com.vanniktech.maven.publish` | 0.36.0 | JDK 17, Gradle 9.0.0+, AGP 8.13.0+ | Incompatible with current project Gradle config — do not use |
| `googleapis/release-please-action` | v4.4.1 (SHA `5c625bf`) | Node 20 | Current pinned version; v5.0.0 requires Node 24, no manifest config-format changes |
| `Package.swift` | swift-tools 5.9 (existing) | Xcode 15+ / Swift 5.9 on CI | Already correct; do not bump |
| `linked-versions` plugin | release-please ≥17.x | manifest mode enabled | v4.4.1 action ships release-please 17.3.0; compatible |
| SwiftPM `upToNextMajorVersion` | any SwiftPM | Mirror repo tag must be annotated `vX.Y.Z` | SPM resolves by git tag on the mirror repo |

---

## io.github.sztheory Namespace — One-Time Setup

1. Sign in to `central.sonatype.com` with the `szTheory` GitHub account (OAuth login).
2. Sonatype automatically provisions `io.github.sztheory` on first GitHub-authenticated login — no manual verification step required in most cases.
3. If not auto-provisioned: click username → View Namespaces → Add Namespace → enter `io.github.sztheory` → Verify Namespace → create a temporary public GitHub repo named with the verification key → Sonatype confirms within minutes.
4. Generate a user token (not login credentials) via central.sonatype.com → User Token — use as `mavenCentralUsername` / `mavenCentralPassword` secrets.

---

## Sources

- `splitsh/lite` releases: https://github.com/splitsh/lite/releases — v2.0.0 confirmed latest stable (HIGH confidence)
- `claudiodekker/splitsh-action` marketplace: https://github.com/marketplace/actions/splitsh-lite-action — workflow pattern verified (HIGH confidence)
- Vanniktech plugin releases: https://github.com/vanniktech/gradle-maven-publish-plugin/releases — 0.36.0 latest; 0.31.0 recommended; 0.36.0 Gradle 9 requirement confirmed (HIGH confidence)
- Vanniktech Central Portal docs: https://vanniktech.github.io/gradle-maven-publish-plugin/central/ — POM + signing + env var config verified (HIGH confidence)
- Vanniktech changelog: https://vanniktech.github.io/gradle-maven-publish-plugin/changelog/ — minimum version requirements per release confirmed (HIGH confidence)
- `googleapis/release-please-action` releases: https://github.com/googleapis/release-please-action/releases — v4.4.1 SHA `5c625bf`; v5.0.0 SHA `45996ed` confirmed (HIGH confidence)
- release-please manifest docs: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md — manifest + linked-versions config shape verified (HIGH confidence)
- release-please customizing docs: https://github.com/googleapis/release-please/blob/main/docs/customizing.md — extra-files + `x-release-please-version` annotation syntax verified (HIGH confidence)
- GITHUB_TOKEN downstream trigger limitation: https://github.com/googleapis/release-please-action/issues/1000 — same-file job chaining workaround confirmed (HIGH confidence)
- Central Portal namespace: https://central.sonatype.org/register/namespace/ — `io.github.USERNAME` auto-provisioned on GitHub OAuth login confirmed (HIGH confidence)
- SwiftPackageIndex/PackageList: https://github.com/SwiftPackageIndex/PackageList — PR-based `packages.json` submission (MEDIUM confidence — process not formally re-verified but stable)
- LiveView Native version injection pattern: `.planning/threads/release-distribution-truth.md` research + `Application.spec/2` Elixir stdlib (HIGH confidence)
- Existing project files read directly: `release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release-please.yml`, `packages/crosswake-shell-core-android/build.gradle.kts`, `packages/crosswake-shell-core-ios/Package.swift`, `lib/mix/tasks/crosswake.gen.shell.ex`, `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex`, `priv/templates/crosswake/shell/android/app/build.gradle.eex` (HIGH confidence)

---
*Stack research for: Crosswake v11.0 Release & Distribution Truth*
*Researched: 2026-06-14*
