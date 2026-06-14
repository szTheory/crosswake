# Architecture Research

**Domain:** Release & Distribution Truth — v11.0 integration of iOS subtree mirror, Android Maven publish, lockstep versioning, generate-time version injection, and clean-room CI into the existing Crosswake monorepo
**Researched:** 2026-06-14
**Confidence:** HIGH (grounded in actual repo file inspection; pre-gathered research in `threads/release-distribution-truth.md` verified against real file contents)

---

## Standard Architecture

### System Overview

```
crosswake/ (monorepo root — Elixir lib at root)
│
├── mix.exs                          # @version "0.1.2" — SINGLE SOURCE OF TRUTH for version
├── release-please-config.json       # MODIFIED: add packages/ entries + linked-versions group
├── .release-please-manifest.json    # MODIFIED: add Android + iOS mirror versions
│
├── lib/mix/tasks/crosswake.gen.shell.ex   # MODIFIED: read Application.spec(:crosswake)[:vsn]
│
├── priv/templates/crosswake/shell/
│   ├── ios/CrosswakeShell.xcodeproj/project.pbxproj.eex   # MODIFIED: version var + correct org
│   └── android/
│       ├── app/build.gradle.eex      # MODIFIED: version var + correct GAV + remove local block
│       └── settings.gradle.eex       # MODIFIED: remove local project() include from non-local branch
│
├── packages/
│   ├── crosswake-shell-core-ios/    # UNCHANGED source; mirror handles distribution
│   │   └── Package.swift            # UNCHANGED (no version field — git tag IS the version)
│   └── crosswake-shell-core-android/
│       ├── build.gradle.kts         # MODIFIED: add group, version, maven-publish plugin
│       └── gradle.properties        # NEW or MODIFIED: signing/publish config
│
├── .github/workflows/
│   ├── release-please.yml           # MODIFIED: add ios-mirror and android-publish jobs
│   ├── phase79-proof.yml            # MODIFIED: rename/split into --local lane + clean-room lane
│   └── clean-room-proof.yml         # NEW: scaffolds host outside monorepo, proves published deps
│
└── examples/phoenix_host/           # UNCHANGED — example host, not part of distribution

─────────────────────────────────────────────────────────────────

github.com/szTheory/crosswake-shell-core-ios  (NEW — separate read-only mirror repo)
│
└── [subtree-split of packages/crosswake-shell-core-ios/]
    └── Package.swift                # Product name: CrosswakeShellCore
    └── Sources/CrosswakeShellCore/  # ActivationCoordinator, BridgeChannel, ...
    └── Tests/CrosswakeShellCoreTests/
    (semver git tags: 0.1.2, 0.1.3, ...)

─────────────────────────────────────────────────────────────────

Maven Central (Central Portal)
└── io.github.sztheory:crosswake-shell-core-android:0.1.2
    (published from packages/crosswake-shell-core-android/ in monorepo CI)
```

---

## Component Responsibilities

| Component | Status | Responsibility | Communicates With |
|-----------|--------|---------------|-------------------|
| `mix.exs @version` | EXISTING — single source of truth | Canonical version string for all platforms | `gen.shell` task (reads via `Application.spec`), release-please (via `extra-files` annotation) |
| `release-please-config.json` | MODIFIED | Manifest mode + `linked-versions` group; version bump writes Hex + Android `build.gradle.kts` | `.release-please-manifest.json`, `mix.exs`, Android build file |
| `.release-please-manifest.json` | MODIFIED | Records current version for each package entry (`"."`, `"packages/crosswake-shell-core-android"`) | release-please action |
| `crosswake.gen.shell` task | MODIFIED | Reads `Application.spec(:crosswake)[:vsn]` at generate-time; passes `@version` assign into EEX templates | iOS + Android EEX templates |
| `project.pbxproj.eex` | MODIFIED | Emits `XCRemoteSwiftPackageReference` pointing at `github.com/szTheory/crosswake-shell-core-ios` with `from: "@version"` | SwiftPM dep resolution |
| `app/build.gradle.eex` | MODIFIED | Emits `implementation("io.github.sztheory:crosswake-shell-core-android:@version")` | Gradle dep resolution |
| `settings.gradle.eex` | MODIFIED | Non-local branch removes the `include ':crosswake-shell-core-android'` project() block entirely | Gradle project config |
| `packages/crosswake-shell-core-android/build.gradle.kts` | MODIFIED | Adds Vanniktech `com.vanniktech.maven.publish` plugin; declares `GROUP`, `VERSION_NAME`, POM metadata | Gradle publish task, Maven Central |
| `release-please.yml` ios-mirror job | NEW CI JOB | Runs `splitsh-lite` to split `packages/crosswake-shell-core-ios/` → `github.com/szTheory/crosswake-shell-core-ios`; creates semver annotated tag | iOS mirror repo, SwiftPM consumers |
| `release-please.yml` android-publish job | NEW CI JOB | Runs `./gradlew publishReleasePublicationToMavenCentral` in `packages/crosswake-shell-core-android/`; requires GPG secret + OSSRH token | Maven Central Portal |
| `phase79-proof.yml` (--local lane) | EXISTING — preserved unchanged | Hermetic proof against monorepo paths; `gen.shell --local`; `swift build` + `gradle build` in-tree | monorepo `packages/` paths |
| `clean-room-proof.yml` | NEW | Scaffolds host in `$RUNNER_TEMP` (outside monorepo), runs `gen.shell` (no `--local`), proves `swift build` + `gradle build` resolve published deps | Published SPM mirror + Maven Central |

---

## Recommended Project Structure (delta — new/changed files only)

```
crosswake/
├── release-please-config.json           # MODIFIED — manifest mode, linked-versions, extra-files
├── .release-please-manifest.json        # MODIFIED — add Android package entry
│
├── lib/mix/tasks/crosswake.gen.shell.ex # MODIFIED — @version assign injected from Application.spec
│
├── priv/templates/crosswake/shell/
│   ├── ios/CrosswakeShell.xcodeproj/
│   │   └── project.pbxproj.eex          # MODIFIED — correct org (szTheory), version var
│   └── android/
│       ├── app/build.gradle.eex         # MODIFIED — correct GAV (io.github.sztheory), version var
│       └── settings.gradle.eex          # MODIFIED — local block only, non-local is clean
│
├── packages/crosswake-shell-core-android/
│   ├── build.gradle.kts                 # MODIFIED — add Vanniktech plugin, GROUP, VERSION_NAME, POM
│   └── gradle.properties                # MODIFIED/NEW — SONATYPE_USERNAME, signing config keys
│
└── .github/workflows/
    ├── release-please.yml               # MODIFIED — add ios-mirror + android-publish jobs
    ├── phase79-proof.yml                # PRESERVED UNCHANGED (--local lane stays)
    └── clean-room-proof.yml             # NEW — published-dep acceptance gate
```

---

## Architectural Patterns

### Pattern 1: Subtree Mirror for SwiftPM Distribution

**What:** SwiftPM enforces a root-manifest constraint (SE-0292) — it cannot consume a subdirectory of a git repo as a package. The package identity equals the repo name. The solution is to run `splitsh-lite` in CI to split `packages/crosswake-shell-core-ios/` into a dedicated read-only mirror repo (`github.com/szTheory/crosswake-shell-core-ios`) and push annotated semver tags there. The monorepo subdirectory remains the authoritative source for development; the mirror is the distribution artifact.

**When to use:** Any OSS library distributed via SwiftPM from a monorepo (Apollo iOS uses exactly this pattern).

**Trade-offs:** Monorepo co-development is fully preserved — developers continue editing `packages/crosswake-shell-core-ios/` directly, running the `--local` proof lane, and committing to main. The mirror is a CI-only output. No force-pushes, no divergence — splitsh re-materializes from history on every run.

**Sequence:**
```
release-please job merges → creates v0.1.2 tag on main
    ↓ (needs: release-please, if: releases_created)
ios-mirror job:
    splitsh-lite --prefix=packages/crosswake-shell-core-ios/ → SHA
    git push https://github.com/szTheory/crosswake-shell-core-ios.git <SHA>:refs/heads/main
    git tag -a "0.1.2" <SHA> -m "Release 0.1.2"
    git push https://github.com/szTheory/crosswake-shell-core-ios.git 0.1.2
```

**Critical detail:** The product reference in the generated `project.pbxproj` must match the mirror repo name (`crosswake-shell-core-ios`), not the `Package.swift` manifest `name:` field (`CrosswakeShellCore`). The EEX template currently uses `repositoryURL = "https://github.com/crosswake/crosswake-shell-core-ios.git"` (wrong org). Fix: `"https://github.com/szTheory/crosswake-shell-core-ios.git"`.

### Pattern 2: Vanniktech Maven Publish for Android Core

**What:** Add `com.vanniktech.maven.publish` (≥0.30.0) to `packages/crosswake-shell-core-android/build.gradle.kts`. The plugin defaults to Central Portal (OSSRH was sunset 2025-06-30), auto-generates sources + javadoc jars, and handles GPG signing. The Android core publishes directly from the monorepo subproject — unlike iOS, SwiftPM's root-manifest constraint has no Gradle equivalent; the monorepo structure is fine.

**When to use:** Any Android library needing Maven Central publication from a monorepo subproject.

**Key configuration additions to `packages/crosswake-shell-core-android/build.gradle.kts`:**
```kotlin
plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
    id("kotlinx-serialization")
    id("com.vanniktech.maven.publish") version "0.30.0"  // NEW
}

mavenPublishing {
    coordinates("io.github.sztheory", "crosswake-shell-core-android", version)
    pom {
        name.set("Crosswake Shell Core Android")
        description.set("Android native shell core for the Crosswake Phoenix library")
        url.set("https://github.com/szTheory/crosswake")
        licenses { license { name.set("MIT"); url.set("https://opensource.org/licenses/MIT") } }
        developers { developer { id.set("szTheory"); name.set("szTheory") } }
        scm { url.set("https://github.com/szTheory/crosswake") }
    }
}
```

**Trade-offs:** GPG public key must be on a keyserver (keys.openpgp.org or keyserver.ubuntu.com) before the first publish or the upload is rejected. Releases are immutable on Maven Central — a botched 0.1.2 burns that version. Test the full publish pipeline against a Sonatype snapshot repo or staging slot before the first real cut.

### Pattern 3: Generate-Time Version Injection (LiveView Native Pattern)

**What:** `mix crosswake.gen.shell` already passes a `local` boolean assign to EEX templates via `EEx.eval_file(template, assigns: [capabilities: capabilities, local: local])`. Add a `version` assign read from `Application.spec(:crosswake)[:vsn]` and thread it into both template renderers.

**When to use:** Any generator that emits dep coordinates referencing the generating library's own version. LVN's `mix lvn.swiftui.gen` is the canonical example.

**Modified call site in `lib/mix/tasks/crosswake.gen.shell.ex`:**
```elixir
defp render_template(template_path, capabilities, local) do
  template =
    Application.app_dir(:crosswake, Path.join("priv/templates/crosswake/shell", template_path))

  version = Application.spec(:crosswake)[:vsn] |> to_string()
  EEx.eval_file(template, assigns: [capabilities: capabilities, local: local, version: version])
end
```

**iOS template change** (`project.pbxproj.eex`, lines 54-61, `else` branch):
```
repositoryURL = "https://github.com/szTheory/crosswake-shell-core-ios.git";
requirement = {
    kind = upToNextMajorVersion;
    minimumVersion = <%= @version %>;
};
```
Use `upToNextMajorVersion` (not `exactVersion`) so patch/minor updates flow without regeneration; breaking changes gated at majors.

**Android template change** (`app/build.gradle.eex`, line 54, `else` branch):
```groovy
implementation 'io.github.sztheory:crosswake-shell-core-android:<%= @version %>'
```

**Pitfall to eliminate:** The current template has two bugs. First, wrong org in the iOS URL (`crosswake/` instead of `szTheory/`). Second, `exactVersion` pinning for iOS (fragile; forces regeneration on every minor/patch). Both fixed in the same template edit.

### Pattern 4: Manifest Mode + Linked-Versions for Lockstep

**What:** release-please manifest mode registers multiple packages in `release-please-config.json` under a `linked-versions` group so all carry the same version. The Hex package (at repo root `.`) and the Android library (`packages/crosswake-shell-core-android`) are the two packages that need version bumps in files. iOS does not need a file version bump because the git tag on the mirror IS the SwiftPM version.

**Modified `release-please-config.json`:**
```json
{
  "bootstrap-sha": "...",
  "linked-versions": true,
  "packages": {
    ".": {
      "release-type": "elixir",
      "extra-files": ["mix.exs"]
    },
    "packages/crosswake-shell-core-android": {
      "release-type": "simple",
      "extra-files": ["build.gradle.kts"]
    }
  }
}
```

**`extra-files` annotation strategy:** release-please's generic updater updates files if they contain `x-release-please-version` marker comments adjacent to version strings. Add `# x-release-please-version` to the `VERSION_NAME` line in `build.gradle.kts` and the `@version` line in `mix.exs`.

**Modified `.release-please-manifest.json`:**
```json
{
  ".": "0.1.2",
  "packages/crosswake-shell-core-android": "0.1.2"
}
```

**Why GITHUB_TOKEN does not work for downstream triggers:** The default `GITHUB_TOKEN` loop-prevention rule means a release created by one workflow does not trigger `on: release: published` in another. The native publish jobs must run as downstream steps within the same `release-please.yml` workflow using `needs: release-please` + `if: needs.release-please.outputs.release_created == 'true'`, not as separate workflows listening for the release event.

### Pattern 5: --local Lane Preservation + Clean-Room Lane Addition

**What:** The existing `phase79-proof.yml` runs `gen.shell --local` against monorepo paths and must stay unchanged — it is the hermetic developer feedback loop. A new `clean-room-proof.yml` proves the published-dep path by scaffolding a host project in `$RUNNER_TEMP` (outside the monorepo checkout), running `mix crosswake.gen.shell` without `--local`, and confirming `swift build` / `gradle build` resolve and compile against the published artifacts.

**Dependency:** The clean-room lane cannot run until both the iOS mirror tag and the Maven artifact for the target version are publicly accessible. It must be gated with `needs: [ios-mirror, android-publish]` and run only when `releases_created == 'true'`. It cannot be a merge-blocking PR gate — it is a post-release acceptance proof.

**Why this preserves monorepo co-development:** The `--local` lane remains the PR merge-blocker for native compilation correctness. The clean-room lane proves distribution truth after release, not during development.

---

## Data Flow

### Version Propagation Flow

```
mix.exs @version "0.1.2"                   ← single source of truth
    │
    ├── Application.spec(:crosswake)[:vsn]  ← read at generate-time in gen.shell task
    │       ↓
    │   render_template/3 assigns @version
    │       ↓
    │   project.pbxproj.eex → "from: 0.1.2" (iOS SwiftPM dep)
    │   app/build.gradle.eex → "io.github.sztheory:...android:0.1.2"
    │
    ├── release-please extra-files updater  ← bumps on release PR merge
    │       ↓
    │   mix.exs @version bumped (elixir release-type handles this natively)
    │   build.gradle.kts VERSION_NAME bumped (via x-release-please-version marker)
    │
    └── release-please.yml outputs.version  ← available to downstream CI jobs
            ↓
        ios-mirror job → annotated tag "x.y.z" on szTheory/crosswake-shell-core-ios
        android-publish job → publishes io.github.sztheory:...:x.y.z to Maven Central
```

### Release Trigger Flow

```
git push to main (conventional commit feat:/fix:)
    ↓
release-please job runs
    ├── no release_created → opens/updates Release PR only; stops here
    └── release_created == true (Release PR was merged)
            ↓
        [needs: release-please, if: release_created]
        ├── publish-hex job      (existing) — publishes crosswake x.y.z to Hex.pm
        ├── ios-mirror job       (NEW) — splitsh + tag on iOS mirror repo
        └── android-publish job  (NEW) — Vanniktech publishRelease to Central Portal
                ↓
            [needs: [ios-mirror, android-publish], if: release_created]
            └── clean-room-proof job (NEW) — scaffolds outside monorepo, proves published deps compile
```

### Generate-Time Template Rendering Flow

```
Developer runs: mix crosswake.gen.shell ios [--local] [--target PATH]
    ↓
gen.shell task parses args; local = false (default)
    ↓
render_template/3:
    Application.spec(:crosswake)[:vsn] → "0.1.2"     ← NEW
    assigns: [capabilities: [...], local: false, version: "0.1.2"]  ← NEW
    ↓
project.pbxproj.eex renders (@local == false branch):
    XCRemoteSwiftPackageReference
        repositoryURL = "https://github.com/szTheory/crosswake-shell-core-ios.git"  ← FIXED org
        kind = upToNextMajorVersion                                                  ← FIXED strategy
        minimumVersion = 0.1.2                                                       ← INJECTED
    ↓
written to native/ios/crosswake_shell/CrosswakeShell.xcodeproj/project.pbxproj
```

### --local vs Clean-Room Build Paths

```
--local path (existing, preserved):
    gen.shell ios --local
        ↓ project.pbxproj.eex (@local == true branch)
        XCLocalSwiftPackageReference relativePath = "../../../packages/crosswake-shell-core-ios"
        ↓
    xcodebuild resolves from monorepo packages/ directory

Clean-room path (NEW):
    gen.shell ios  (no --local, run outside monorepo in $RUNNER_TEMP)
        ↓ project.pbxproj.eex (@local == false branch)
        XCRemoteSwiftPackageReference url = "...szTheory/crosswake-shell-core-ios.git" tag "0.1.2"
        ↓
    swift build / xcodebuild resolves from github.com/szTheory/crosswake-shell-core-ios
    (proves the published artifact is real and the version matches)
```

---

## Integration Points

### New Components and Their Integration Surface

| Boundary | Direction | Integration Mechanism | Key File(s) |
|----------|-----------|----------------------|-------------|
| `mix.exs @version` → `gen.shell` task | Library runtime → task | `Application.spec(:crosswake)[:vsn]` call | `lib/mix/tasks/crosswake.gen.shell.ex` |
| `gen.shell` task → iOS template | Task → EEX | `@version` assign in `EEx.eval_file/2` | `priv/templates/.../project.pbxproj.eex` |
| `gen.shell` task → Android template | Task → EEX | `@version` assign in `EEx.eval_file/2` | `priv/templates/.../app/build.gradle.eex`, `settings.gradle.eex` |
| `release-please` job → `ios-mirror` job | CI → CI | `needs:` + `outputs.release_created` | `.github/workflows/release-please.yml` |
| `release-please` job → `android-publish` job | CI → CI | `needs:` + `outputs.release_created` | `.github/workflows/release-please.yml` |
| `ios-mirror` job → mirror repo | CI → external repo | `splitsh-lite` + git push + annotated tag | `github.com/szTheory/crosswake-shell-core-ios` |
| `android-publish` job → Maven Central | CI → Maven Central Portal | Vanniktech `publishReleasePublicationToMavenCentral` Gradle task | `packages/crosswake-shell-core-android/build.gradle.kts` |
| `clean-room-proof` job → published deps | CI → SwiftPM/Maven | `swift build` + `gradle build` in `$RUNNER_TEMP` | `.github/workflows/clean-room-proof.yml` |
| monorepo `packages/crosswake-shell-core-ios/` → mirror repo | Source → distribution | splitsh-lite (CI only, not a git submodule or remote) | Monorepo unmodified; mirror is a read-only output |
| `release-please-config.json` → `mix.exs` | Config → version file | `extra-files` annotation + `elixir` release-type | `mix.exs`, `release-please-config.json` |
| `release-please-config.json` → `build.gradle.kts` | Config → version file | `extra-files` + `x-release-please-version` marker comment | `packages/crosswake-shell-core-android/build.gradle.kts` |

### Modified vs New Components

**MODIFIED (existing files changed):**
- `lib/mix/tasks/crosswake.gen.shell.ex` — add `version` assign to `render_template/3`
- `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex` — fix org URL, change `exactVersion` → `upToNextMajorVersion`, inject `<%= @version %>`
- `priv/templates/crosswake/shell/android/app/build.gradle.eex` — fix GAV (`io.github.sztheory:crosswake-shell-core-android:<%= @version %>`), inject version
- `priv/templates/crosswake/shell/android/settings.gradle.eex` — confirm non-local branch has no `project()` include (currently correct; verify no leakage)
- `packages/crosswake-shell-core-android/build.gradle.kts` — add Vanniktech plugin, `GROUP`, `VERSION_NAME`, mandatory POM metadata
- `release-please-config.json` — add manifest mode `linked-versions: true`, Android package entry, `extra-files` annotations
- `.release-please-manifest.json` — add `"packages/crosswake-shell-core-android": "0.1.2"` entry
- `.github/workflows/release-please.yml` — add `ios-mirror`, `android-publish`, `clean-room-proof` jobs

**NEW (do not exist yet):**
- `.github/workflows/clean-room-proof.yml` — published-dep acceptance gate (or added as jobs in `release-please.yml`)
- `github.com/szTheory/crosswake-shell-core-ios` — new GitHub repository (empty mirror, seeded by first splitsh run)
- GPG key infrastructure for Maven signing (outside repo; CI secrets: `SIGNING_KEY_ID`, `SIGNING_KEY`, `SIGNING_PASSWORD`, `SONATYPE_USERNAME`, `SONATYPE_PASSWORD`)

**UNCHANGED (explicitly preserved):**
- `packages/crosswake-shell-core-ios/Package.swift` — no version field; git tag IS the SwiftPM version
- `packages/crosswake-shell-core-ios/Sources/` — all 11 Swift source files untouched
- `packages/crosswake-shell-core-android/src/` — Android library source untouched
- `.github/workflows/phase79-proof.yml` — `--local` lane preserved as merge-blocking hermetic proof
- `examples/phoenix_host/` — unaffected
- All other `.github/workflows/phase*.yml` — unaffected

---

## Suggested Build Order (Dependency-Respecting)

The key dependency constraint: **nothing can be clean-room-proved until the dep is published**. Version injection depends on lockstep being defined. Android publish config must exist before Android publish CI runs.

```
Step 1 — Establish version infrastructure (no publish yet, no CI change):
    a. release-please-config.json: add linked-versions + Android package entry + extra-files markers
    b. .release-please-manifest.json: add Android entry at current version
    c. packages/crosswake-shell-core-android/build.gradle.kts: add Vanniktech plugin + POM
    d. mix.exs / build.gradle.kts: add x-release-please-version marker comments
    └── Verify: `./gradlew :crosswake-shell-core-android:publishToMavenLocal` works locally

Step 2 — Template rewire (depends on version infrastructure being designed; no publish needed):
    a. lib/mix/tasks/crosswake.gen.shell.ex: add version assign
    b. project.pbxproj.eex: fix org URL, exactVersion → upToNextMajorVersion, inject @version
    c. app/build.gradle.eex: fix GAV + inject @version
    d. settings.gradle.eex: verify (already clean in non-local branch)
    └── Verify: `mix crosswake.gen.shell ios` and `android` generate correct dep strings

Step 3 — iOS mirror repo creation (prerequisite for ios-mirror CI job):
    a. Create github.com/szTheory/crosswake-shell-core-ios (empty public repo)
    b. Add deploy key or PAT secret for CI push access
    └── Do NOT push yet — first push happens via CI in step 5

Step 4 — Android publish dry-run (prerequisite for production CI job):
    a. Configure GPG key + upload public key to keyserver
    b. Add SONATYPE_USERNAME + SONATYPE_PASSWORD to GitHub Actions secrets
    c. Add SIGNING_KEY_ID + SIGNING_KEY + SIGNING_PASSWORD to GitHub Actions secrets
    d. Run `./gradlew publishReleasePublicationToMavenCentralPortal` against staging namespace
    └── Verify: artifact appears in Central Portal staging; POM validates

Step 5 — CI wiring (depends on steps 1-4 being solid):
    a. release-please.yml: add ios-mirror job (splitsh-lite + git push + tag)
    b. release-please.yml: add android-publish job (gradle publish)
    c. Confirm existing publish-hex job unchanged
    └── Verify: manually trigger on a test tag; confirm mirror tag appears + Maven artifact visible

Step 6 — Clean-room proof lane (depends on step 5 — needs a published version to resolve):
    a. Add clean-room-proof job (needs: [ios-mirror, android-publish])
    b. Job: scaffold in $RUNNER_TEMP, run gen.shell (no --local), swift build + gradle build
    c. This is a post-release gate, not a PR gate
    └── Verify: lane passes on the first real release cut

Step 7 — Doc reconciliation + Hex cut (depends on step 6 proving the path is real):
    a. Update guides/adoption.md to published install path
    b. Update guides/support_matrix.md
    c. Reconcile CHANGELOG [0.1.2] entry
    d. Merge → release-please opens PR → merge → Hex 0.1.2 published
    └── clean-room-proof runs post-release as final acceptance
```

---

## Anti-Patterns

### Anti-Pattern 1: Clean-Room Lane as PR Merge Gate

**What people do:** Wire the published-dep proof as a required PR check.

**Why it's wrong:** It creates a chicken-and-egg deadlock — the published dep does not exist until the release is cut; the release cannot be cut until the proof passes. A PR gate against published deps forces pinning to the previous version for every PR, which defeats the purpose.

**Do this instead:** Run clean-room-proof only post-release (`needs: [ios-mirror, android-publish]`, gated on `release_created == true`). Keep `phase79-proof.yml` (`--local`) as the PR merge-blocker for native compilation correctness.

### Anti-Pattern 2: Using `exactVersion` in Generated SwiftPM Dep

**What people do:** Pin `kind = exactVersion; version = 0.1.2` in `project.pbxproj.eex` (current behavior).

**Why it's wrong:** Forces adopters to regenerate the shell on every patch/minor Crosswake release. Breaks the "scaffold once" philosophy the README already declares.

**Do this instead:** Use `kind = upToNextMajorVersion; minimumVersion = 0.1.2`. Adopters receive patches and minors automatically; breaking changes require a major bump which also requires regeneration — consistent with semantic versioning intent.

### Anti-Pattern 3: Separate Workflow Listening for `release: published`

**What people do:** Create a separate workflow (`on: release: types: [published]`) for native publish jobs.

**Why it's wrong:** GitHub's loop-prevention rule blocks the default `GITHUB_TOKEN` from triggering downstream `release: published` workflows when the release was created by another workflow (release-please). The downstream jobs silently never fire.

**Do this instead:** Keep all release-gated jobs in the same `release-please.yml` with `needs: release-please` + `if: needs.release-please.outputs.release_created == 'true'`. If a PAT is needed (`RELEASE_PLEASE_TOKEN`), the existing workflow already accommodates it.

### Anti-Pattern 4: Hardcoding the Native Dep Version as a Literal String in Templates

**What people do:** Set `version = 0.1.2` (or any literal) directly in the EEX template.

**Why it's wrong:** The template drifts from `mix.exs @version` silently (this is LVN's documented drift bug with `LiveViewNativeLiveForm`). An adopter generating on `0.1.3` gets a template referencing `0.1.2`.

**Do this instead:** Always derive from `Application.spec(:crosswake)[:vsn]` at generate-time. The EEX template should contain only `<%= @version %>` — never a literal version string in the non-local branch.

### Anti-Pattern 5: Attempting to Publish the iOS Core from the Monorepo Subdir via a git URL

**What people do:** Reference `packages/crosswake-shell-core-ios` as a git URL with a `path:` parameter, or try to make SwiftPM resolve a monorepo subdirectory remotely.

**Why it's wrong:** SwiftPM's root-manifest constraint (SE-0292) makes the package identity equal to the repository root. There is no `subdirectory:` parameter for remote dependencies. This simply does not work — it was the original bug in the template.

**Do this instead:** Subtree-mirror to a dedicated repo. This is a one-time setup cost (create the repo + add the splitsh CI step); after that it is fully automated.

---

## Scaling Considerations

This architecture's "scale" is adopter scale (how many Phoenix teams install and use Crosswake), not request throughput. The distribution architecture must hold up across these adopter-count scenarios:

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0–10 adopters | Current approach sufficient; clean-room proof lane catches regressions early |
| 10–100 adopters | Binary XCFramework distribution may reduce cold-build times for iOS; not needed now (source dist is fine and simpler) |
| 100+ adopters | Maven Central Central Portal handles unlimited download scale; SwiftPM mirrors are git-native (CDN-free); Hex.pm is CDN-backed. No changes needed at this scale. |

### First Bottleneck

GPG signing ceremony and Maven Central Portal approval for the `io.github.sztheory` namespace. This is a one-time manual step that must precede the first Android publish CI run. Allocate time before Step 4 above; it is the most likely blocking dependency in Phase A.

---

## Sources

- Pre-gathered research: `.planning/threads/release-distribution-truth.md` (HIGH confidence — repo-verified)
- Actual file inspection: `lib/mix/tasks/crosswake.gen.shell.ex`, `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex`, `priv/templates/crosswake/shell/android/app/build.gradle.eex`, `settings.gradle.eex`
- Actual file inspection: `packages/crosswake-shell-core-android/build.gradle.kts`, `packages/crosswake-shell-core-ios/Package.swift`
- Actual file inspection: `.github/workflows/release-please.yml`, `.github/workflows/phase79-proof.yml`, `release-please-config.json`, `.release-please-manifest.json`
- SwiftPM SE-0292 root-manifest constraint (referenced in research thread; Apollo iOS subtree pattern)
- Vanniktech maven-publish-plugin docs (≥0.30.0 Central Portal default; referenced in research thread)
- release-please manifest mode + linked-versions + downstream trigger gotcha (referenced in research thread)
- LiveView Native `mix lvn.swiftui.gen` generate-time injection pattern (referenced in research thread)

---
*Architecture research for: Crosswake v11.0 Release & Distribution Truth*
*Researched: 2026-06-14*
