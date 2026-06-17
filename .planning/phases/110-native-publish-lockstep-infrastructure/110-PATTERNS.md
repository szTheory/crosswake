# Phase 110: Native Publish & Lockstep Infrastructure - Pattern Map

**Mapped:** 2026-06-14
**Files analyzed:** 8 (6 modified + 2 new)
**Analogs found:** 7 / 8

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `mix.exs` (`@version` revert) | config | transform | self (current file) | exact |
| `release-please-config.json` | config | event-driven | self (current file) | exact — extend in place |
| `.release-please-manifest.json` | config | event-driven | self (current file) | exact — extend in place |
| `.github/workflows/release-please.yml` (ios-mirror job) | CI job | event-driven | existing `publish-hex` job in same file | exact — same `needs`/`if` gate |
| `.github/workflows/release-please.yml` (android-publish job) | CI job | event-driven | existing `publish-hex` job in same file | exact — same `needs`/`if` gate |
| `.github/workflows/release-please.yml` (fire-drill dispatch lane) | CI job | request-response | existing `workflow_dispatch` trigger on same file | role-match |
| `packages/crosswake-shell-core-android/build.gradle.kts` | config | batch (publish) | self (current file) | exact — add Vanniktech block |
| `SETUP.md` (new provisioning runbook) | documentation | — | no analog in repo | none |

---

## Pattern Assignments

### `mix.exs` — revert `@version` from `0.1.2` to `0.1.0`

**Analog:** self (`mix.exs` line 4)

**Current state (line 4 — the only line changed):**
```elixir
@version "0.1.2"
```

**Target state (D-04):**
```elixir
@version "0.1.0" # x-release-please-version
```

**Why:** D-04 mandates `mix.exs @version` must equal Hex's published version (`0.1.0`) so release-please can write the correct bump at the real cut. The `# x-release-please-version` annotation enables the `extra-files` generic updater to find and bump this line on Release PR merge.

**Read first:** `mix.exs` lines 1–10 (project/version block shown above — already in context).

---

### `release-please-config.json` — extend with packages + linked-versions

**Analog:** self — current file is the base; extend, do not rewrite.

**Current state (full file — 24 lines):**
```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "bootstrap-sha": "f788e312747e14b157c8498ba710f057534530f5",
  "bump-minor-pre-major": false,
  "bump-patch-for-minor-pre-major": true,
  "packages": {
    ".": {
      "release-type": "elixir",
      "skip-changelog": true,
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
    }
  }
}
```

**Target state (STACK.md verbatim — adds `plugins`, `component` keys, iOS + Android packages, `extra-files`, `release-as` pin on `.`):**
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
      "release-as": "0.1.2",
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

**Key decisions baked in:**
- `"component"` key required on every package for `linked-versions` to group them.
- `"release-as": "0.1.2"` on `.` is the one-time bootstrap pin (D-02/D-04). MUST be removed in a `chore:` commit immediately after `0.1.2` ships in Phase 111.
- iOS package entry has no `extra-files` — git tag IS the SwiftPM version; no file field to update.
- Android `extra-files` uses `"type": "generic"` with an absolute `"path"` from repo root — required because `build.gradle.kts` is not at the package root relative to `packages/crosswake-shell-core-android`.
- `Package.swift` must NOT appear in `extra-files` (no version field exists there).

**Read first:** `release-please-config.json` (full file — already in context above).

---

### `.release-please-manifest.json` — add iOS and Android entries

**Analog:** self — current file is the base.

**Current state (3 lines):**
```json
{
  ".": "0.1.0"
}
```

**Target state (D-04 — manifest `.` stays at `0.1.0` to match Hex; new entries baselined at `0.1.0`):**
```json
{
  ".": "0.1.0",
  "packages/crosswake-shell-core-ios": "0.1.0",
  "packages/crosswake-shell-core-android": "0.1.0"
}
```

**Note:** D-04 explicitly says keep manifest `.` = `0.1.0` (not `0.1.2`). The `release-as: "0.1.2"` pin in the config file overrides this for the first Release PR. After the `0.1.2` cut, release-please will write `"0.1.2"` here for all three entries.

**Read first:** `.release-please-manifest.json` (full file — already in context above).

---

### `.github/workflows/release-please.yml` — ios-mirror job

**Analog:** existing `publish-hex` job in the same file (lines 51–123). Copy the `needs`/`if`/`permissions`/`checkout` skeleton exactly; replace body with splitsh steps.

**Canonical analog — publish-hex job skeleton (lines 51–62):**
```yaml
  publish-hex:
    name: Publish to Hex.pm
    needs: release-please
    if: ${{ needs.release-please.outputs.release_created == 'true' }}
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
        with:
          ref: ${{ needs.release-please.outputs.tag_name }}
```

**Target job (append after `publish-hex`, before any new `android-publish` job):**
```yaml
  publish-ios-core:
    name: Mirror iOS core to split repo
    needs: release-please
    if: ${{ needs.release-please.outputs.release_created == 'true' }}
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
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
          git push mirror "${SPLIT_SHA}:refs/heads/main"
          git push mirror "${SPLIT_SHA}:refs/tags/${TAG}"
```

**Key decisions:**
- `fetch-depth: 0` on checkout — splitsh requires full history (not the tagged-ref checkout `publish-hex` uses).
- No `--scratch` flag per D-11 (stateless GitHub runners; BoltDB cache never exists).
- No `--force` on push per D-10 (structural tag immutability guard; ruleset is defense-in-depth only).
- `TAG` comes from `needs.release-please.outputs.tag_name` (same output `publish-hex` uses) — D-13.
- `MIRROR_PUSH_TOKEN` is a fine-grained PAT with `Contents: write` on mirror repo only — distinct from `RELEASE_PLEASE_TOKEN`.
- Checkout SHA `de0fac2e4500dabe0009e67214ff5f5447ce83dd` is the existing pinned SHA — use same pin.

**Read first:** `.github/workflows/release-please.yml` lines 51–62 (already in context above).

---

### `.github/workflows/release-please.yml` — android-publish job

**Analog:** existing `publish-hex` job (lines 51–123). Same `needs`/`if`/`permissions` skeleton; body is Gradle publish.

**Target job (append after `publish-ios-core`):**
```yaml
  publish-android-core:
    name: Publish Android core to Maven Central
    needs: release-please
    if: ${{ needs.release-please.outputs.release_created == 'true' }}
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
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

**Key decisions:**
- `actions/setup-java@v4` — SHA-pin this action when writing final plan (planner should look up current SHA).
- `publishToMavenCentral` (not `publishAndReleaseToMavenCentral`) — Vanniktech 0.31.0 USER_MANAGED mode; defaults to `automaticRelease=false`, stops at VALIDATED. D-07 explicitly forbids `automaticRelease=true` on first publish.
- `working-directory: packages/crosswake-shell-core-android` — Gradle wrapper is in the Android subproject.
- The 5 `ORG_GRADLE_PROJECT_*` env vars are the Vanniktech in-memory signing convention.

**Read first:** `.github/workflows/release-please.yml` lines 51–62 (analog skeleton, already in context).

---

### `.github/workflows/release-please.yml` — fire-drill workflow_dispatch lane (D-08)

**Analog:** The file already has `workflow_dispatch:` at line 17 (top-level workflow trigger). The fire-drill is a separate permanent job gated on `workflow_dispatch` input, NOT on `release_created`.

**Pattern — existing `workflow_dispatch` trigger (lines 13–18):**
```yaml
on:
  push:
    branches:
      - main
  workflow_dispatch:
```

**Target job (append after `publish-android-core` — a permanent rehearsal lane):**
```yaml
  android-publish-fire-drill:
    name: Android publish fire-drill (validated-upload → drop)
    if: ${{ github.event_name == 'workflow_dispatch' }}
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2

      - uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Preflight — assert required secrets are set
        env:
          MAVEN_USERNAME: ${{ secrets.ORG_GRADLE_PROJECT_mavenCentralUsername }}
          MAVEN_PASSWORD: ${{ secrets.ORG_GRADLE_PROJECT_mavenCentralPassword }}
          SIGNING_KEY: ${{ secrets.ORG_GRADLE_PROJECT_signingInMemoryKey }}
          SIGNING_KEY_ID: ${{ secrets.ORG_GRADLE_PROJECT_signingInMemoryKeyId }}
          SIGNING_PASSWORD: ${{ secrets.ORG_GRADLE_PROJECT_signingInMemoryKeyPassword }}
          MIRROR_TOKEN: ${{ secrets.MIRROR_PUSH_TOKEN }}
          RELEASE_TOKEN: ${{ secrets.RELEASE_PLEASE_TOKEN }}
          HEX_KEY: ${{ secrets.HEX_API_KEY }}
        run: |
          set -euo pipefail
          fail=0
          for var in MAVEN_USERNAME MAVEN_PASSWORD SIGNING_KEY SIGNING_KEY_ID SIGNING_PASSWORD MIRROR_TOKEN RELEASE_TOKEN HEX_KEY; do
            if [ -z "${!var:-}" ]; then
              echo "MISSING SECRET: $var"
              fail=1
            fi
          done
          [ "$fail" -eq 0 ] || exit 1
          echo "All 8 secrets present."

      - name: Local publish to ~/.m2 and assert artifacts
        working-directory: packages/crosswake-shell-core-android
        env:
          ORG_GRADLE_PROJECT_signingInMemoryKey: ${{ secrets.ORG_GRADLE_PROJECT_signingInMemoryKey }}
          ORG_GRADLE_PROJECT_signingInMemoryKeyId: ${{ secrets.ORG_GRADLE_PROJECT_signingInMemoryKeyId }}
          ORG_GRADLE_PROJECT_signingInMemoryKeyPassword: ${{ secrets.ORG_GRADLE_PROJECT_signingInMemoryKeyPassword }}
        run: |
          ./gradlew publishToMavenLocal --no-daemon
          M2="$HOME/.m2/repository/io/github/sztheory/crosswake-shell-core-android"
          VERSION=$(grep 'x-release-please-version' build.gradle.kts | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
          echo "Checking $M2/$VERSION/"
          for ext in aar sources.jar javadoc.jar pom; do
            f="$M2/$VERSION/crosswake-shell-core-android-$VERSION.$ext"
            [ -f "$f" ] || { echo "MISSING: $f"; exit 1; }
            [ -f "${f}.asc" ] || { echo "MISSING SIGNATURE: ${f}.asc"; exit 1; }
            echo "OK: $f"
          done
          # POM completeness check
          pom="$M2/$VERSION/crosswake-shell-core-android-$VERSION.pom"
          for field in name description url license developers scm; do
            grep -q "$field" "$pom" || { echo "POM missing field: $field"; exit 1; }
          done
          echo "All artifacts and POM fields verified."

      - name: Central Portal validated-upload → DROP
        working-directory: packages/crosswake-shell-core-android
        env:
          ORG_GRADLE_PROJECT_mavenCentralUsername: ${{ secrets.ORG_GRADLE_PROJECT_mavenCentralUsername }}
          ORG_GRADLE_PROJECT_mavenCentralPassword: ${{ secrets.ORG_GRADLE_PROJECT_mavenCentralPassword }}
          ORG_GRADLE_PROJECT_signingInMemoryKey: ${{ secrets.ORG_GRADLE_PROJECT_signingInMemoryKey }}
          ORG_GRADLE_PROJECT_signingInMemoryKeyId: ${{ secrets.ORG_GRADLE_PROJECT_signingInMemoryKeyId }}
          ORG_GRADLE_PROJECT_signingInMemoryKeyPassword: ${{ secrets.ORG_GRADLE_PROJECT_signingInMemoryKeyPassword }}
          MAVEN_USERNAME: ${{ secrets.ORG_GRADLE_PROJECT_mavenCentralUsername }}
          MAVEN_PASSWORD: ${{ secrets.ORG_GRADLE_PROJECT_mavenCentralPassword }}
        run: |
          set -euo pipefail
          ./gradlew publishToMavenCentral --no-daemon
          # Retrieve deployment ID via Portal API (0.31.0 does not log it)
          DEPLOYMENT_NAME="io.github.sztheory-$(date +%s)"
          echo "Polling for deployment matching name pattern..."
          DEPLOYMENT_ID=""
          for i in $(seq 1 20); do
            DEPLOYMENT_ID=$(curl -sf \
              -u "${MAVEN_USERNAME}:${MAVEN_PASSWORD}" \
              "https://central.sonatype.com/api/v1/publisher/deployments?name=${DEPLOYMENT_NAME}&state=VALIDATED" \
              | grep -oP '"id"\s*:\s*"\K[^"]+' | head -1 || true)
            [ -n "$DEPLOYMENT_ID" ] && break
            # Also check for FAILED — retain and report, don't drop
            FAILED=$(curl -sf \
              -u "${MAVEN_USERNAME}:${MAVEN_PASSWORD}" \
              "https://central.sonatype.com/api/v1/publisher/deployments?state=FAILED" \
              | grep -c '"id"' || true)
            [ "$FAILED" -gt 0 ] && { echo "Deployment FAILED — retain for inspection, not dropping"; exit 1; }
            echo "Waiting for VALIDATED state... ($i/20)"
            sleep 15
          done
          [ -n "$DEPLOYMENT_ID" ] || { echo "Timed out waiting for VALIDATED deployment"; exit 1; }
          echo "Deployment VALIDATED: $DEPLOYMENT_ID — dropping (frees version coordinate)"
          curl -sf -X DELETE \
            -u "${MAVEN_USERNAME}:${MAVEN_PASSWORD}" \
            "https://central.sonatype.com/api/v1/publisher/deployment/${DEPLOYMENT_ID}"
          echo "Fire-drill complete — version coordinate is FREE."
```

**Key decisions from D-07/D-08:**
- `publishToMavenCentral` (USER_MANAGED = VALIDATED, not PUBLISHED) — coordinate remains free after DROP.
- Poll for `VALIDATED` before dropping; handle `FAILED` by retaining (not dropping) for inspection.
- Deployment ID retrieved via Portal API because Vanniktech 0.31.0 does not log it.
- `DELETE /api/v1/publisher/deployment/{id}` is the confirmed drop endpoint (immutability scoped to PUBLISHED state only).
- `if: ${{ github.event_name == 'workflow_dispatch' }}` — fire-drill runs only on manual dispatch, never on push to main.

---

### `packages/crosswake-shell-core-android/build.gradle.kts` — add Vanniktech + POM

**Analog:** self — current file is the base; add plugin + `version` line + `mavenPublishing` block.

**Current state (full file — 35 lines):**
```kotlin
plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
    id("kotlinx-serialization")
}

android {
    namespace = "dev.crosswake.shell.core"
    compileSdk = 34

    defaultConfig {
        minSdk = 26
    }

    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    
    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.0")
    // Note: Android bridge may use WebKit/WebView and we might need androidx.webkit
    implementation("androidx.webkit:webkit:1.10.0")
}
```

**Target state — additions only (follow STACK.md verbatim; note `automaticRelease = false` per D-07):**

Add `id("com.vanniktech.maven.publish") version "0.31.0"` to `plugins {}`.

Add `version = "0.1.0" // x-release-please-version` immediately after the closing `}` of `plugins {}`.

Add `mavenPublishing {}` block after `dependencies {}`:

```kotlin
mavenPublishing {
    publishToMavenCentral(SonatypeHost.CENTRAL_PORTAL, automaticRelease = false)
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

**Critical note:** STACK.md shows `automaticRelease = true` in its example, but D-07 overrides: **use `automaticRelease = false`** (USER_MANAGED mode; stops at VALIDATED). This is the load-bearing safety guard for D-01.

**`version` line:** `"0.1.0"` (matching manifest baseline). The `// x-release-please-version` annotation allows the release-please generic updater to find and bump it.

**Read first:** `packages/crosswake-shell-core-android/build.gradle.kts` (full file — already in context above).

---

### `packages/crosswake-shell-core-ios/Package.swift` — verify unchanged

**Status:** UNCHANGED. Verify only — no edits required.

**Current state (full file — 27 lines, already verified):**
```swift
// swift-tools-version: 5.9
let package = Package(
    name: "CrosswakeShellCore",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "CrosswakeShellCore", targets: ["CrosswakeShellCore"]),
    ],
    targets: [
        .target(name: "CrosswakeShellCore"),
        .testTarget(name: "CrosswakeShellCoreTests", dependencies: ["CrosswakeShellCore"]),
    ]
)
```

No `version` field — correct. Git tag IS the SwiftPM version. Product name `CrosswakeShellCore` must remain exactly as-is (the EEX template `project.pbxproj.eex` references it; changing it breaks generated projects). The mirror repo receives an exact copy of this file via splitsh — no modifications needed.

---

### `SETUP.md` — new one-time provisioning runbook

**Analog:** none in repo. This is a new document.

**Content scope (from D-06 and STACK.md):**

The SETUP.md must cover these 8 items in order:

1. **Sonatype namespace provisioning** — sign in to `central.sonatype.com` with GitHub OAuth as `szTheory`; auto-provisions `io.github.sztheory`; manual verification path if auto-provision fails.
2. **Sonatype user token** — generate at central.sonatype.com → User Token (NOT login credentials); set as `ORG_GRADLE_PROJECT_mavenCentralUsername` / `…Password`.
3. **GPG key generation** — primary-key-only with signing capability, no signing subkey:
   ```
   gpg --quick-generate-key "szTheory <qiksnare13@gmail.com>" rsa4096 sign 0
   ```
   Export: `gpg --export-secret-keys --armor <KEYID>` → `ORG_GRADLE_PROJECT_signingInMemoryKey`.
   Short key ID (last 8 hex chars) → `ORG_GRADLE_PROJECT_signingInMemoryKeyId`.
   Passphrase → `ORG_GRADLE_PROJECT_signingInMemoryKeyPassword`.
4. **GPG public key upload** — upload to BOTH `keys.openpgp.org` and `keyserver.ubuntu.com` (Central Portal verification uses both).
5. **iOS mirror repo creation** — create `szTheory/crosswake-shell-core-ios` as empty public repo (no README, no initial commit — CI seeds on first release per D-09).
6. **MIRROR_PUSH_TOKEN** — fine-grained PAT, `Contents: write` on `szTheory/crosswake-shell-core-ios` ONLY; set as `MIRROR_PUSH_TOKEN` repo secret.
7. **Tag ruleset on mirror repo** — `gh api POST /repos/szTheory/crosswake-shell-core-ios/rulesets --input ruleset.json` with `target: tag`, rules `non_fast_forward` + `deletion`, `enforcement: active`, conditions `refs/tags/*`. Best-effort per D-10.
8. **Secret verification checklist** — run `gh secret list` and confirm all 8 names present: `HEX_API_KEY`, `ORG_GRADLE_PROJECT_mavenCentralUsername`, `ORG_GRADLE_PROJECT_mavenCentralPassword`, `ORG_GRADLE_PROJECT_signingInMemoryKey`, `ORG_GRADLE_PROJECT_signingInMemoryKeyId`, `ORG_GRADLE_PROJECT_signingInMemoryKeyPassword`, `MIRROR_PUSH_TOKEN`, `RELEASE_PLEASE_TOKEN`.

---

## Shared Patterns

### CI Job Gate Pattern
**Source:** `.github/workflows/release-please.yml` lines 51–57 (existing `publish-hex` job header)
**Apply to:** ALL new CI jobs in `release-please.yml` (`publish-ios-core`, `publish-android-core`)
```yaml
    needs: release-please
    if: ${{ needs.release-please.outputs.release_created == 'true' }}
    runs-on: ubuntu-latest
    permissions:
      contents: read
```
**Rationale:** This is the established job-graph chaining pattern that bypasses the `GITHUB_TOKEN` downstream-trigger limitation (STACK.md, issue #1000).

### Release Please Outputs Pattern
**Source:** `.github/workflows/release-please.yml` lines 32–36 (job-level `outputs:`)
**Apply to:** All new jobs that consume release metadata
```yaml
    outputs:
      release_created: ${{ steps.release.outputs.release_created }}
      tag_name: ${{ steps.release.outputs.tag_name }}
      version: ${{ steps.release.outputs.version }}
```
**Consume via:** `${{ needs.release-please.outputs.tag_name }}` / `.outputs.version`

### SHA-Pinned Checkout Pattern
**Source:** `.github/workflows/release-please.yml` line 59 (existing `publish-hex` checkout)
**Apply to:** ALL new CI jobs
```yaml
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
```
**Note:** `ios-mirror` job overrides `ref:` with `fetch-depth: 0` instead of `ref: tag_name` — full history required for splitsh. All other new jobs use `ref: ${{ needs.release-please.outputs.tag_name }}` to checkout the tagged commit.

### Version Annotation Pattern
**Apply to:** `mix.exs` line 4 and `build.gradle.kts` `version` line
```elixir
@version "0.1.0" # x-release-please-version    # mix.exs
```
```kotlin
version = "0.1.0" // x-release-please-version   # build.gradle.kts
```
This annotation is how release-please's `extra-files` generic updater locates version lines across arbitrary file types.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `SETUP.md` | documentation | — | No existing provisioning runbook pattern in codebase; content driven entirely by D-06 and STACK.md |

---

## Metadata

**Analog search scope:** `.github/workflows/`, `packages/crosswake-shell-core-android/`, `packages/crosswake-shell-core-ios/`, `mix.exs`, `release-please-config.json`, `.release-please-manifest.json`
**Files read:** 8 source files + CONTEXT.md + STACK.md + ARCHITECTURE.md
**Pattern extraction date:** 2026-06-14

**Phase 111 files explicitly OUT OF SCOPE for this phase (decided in 110, edited in 111):**
- `lib/mix/tasks/crosswake.gen.shell.ex` — `Application.spec(:crosswake)[:vsn]` version injection
- `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex` — fix org URL + `upToNextMajorVersion`
- `priv/templates/crosswake/shell/android/app/build.gradle.eex` — fix GAV + `<%= @version %>`
- `priv/templates/crosswake/shell/android/settings.gradle.eex` — verify non-local branch
- `.github/workflows/clean-room-proof.yml` — published-dep acceptance gate
