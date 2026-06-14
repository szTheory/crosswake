---
phase: 110-native-publish-lockstep-infrastructure
plan: "01"
subsystem: release-infrastructure
tags: [release-please, linked-versions, android, maven-central, vanniktech, lockstep-versioning]
dependency_graph:
  requires: []
  provides:
    - release-please-linked-versions-config
    - android-maven-central-publish-config
  affects:
    - release-please-config.json
    - .release-please-manifest.json
    - mix.exs
    - packages/crosswake-shell-core-android/build.gradle.kts
tech_stack:
  added:
    - "com.vanniktech.maven.publish 0.31.0 (Gradle plugin for Maven Central publish)"
    - "release-please linked-versions plugin (lockstep version propagation)"
  patterns:
    - "x-release-please-version annotation for extra-files generic updater"
    - "USER_MANAGED Central Portal mode (automaticRelease=false) for validated-stop without burning coordinates"
    - "Maven groupId io.github.sztheory distinct from Android namespace dev.crosswake.shell.core"
key_files:
  created: []
  modified:
    - mix.exs
    - release-please-config.json
    - .release-please-manifest.json
    - packages/crosswake-shell-core-android/build.gradle.kts
decisions:
  - "D-04 honored: mix.exs @version reverted to 0.1.0 (true published Hex version); manifest . stays at 0.1.0; release-as: 0.1.2 one-time bootstrap pin retained on . package"
  - "D-07 honored: automaticRelease=false in publishToMavenCentral — stops at VALIDATED, never auto-publishes; publishAndReleaseToMavenCentral never used"
  - "Vanniktech 0.31.0 selected over 0.36.0 — 0.36.0 requires Gradle 9 + AGP 8.13 which exceeds project's gradle-8.7 + compileSdk 34"
  - "Package.swift excluded from all extra-files — SwiftPM reads annotated git tag, not a version field in the manifest"
  - "Android extra-files uses repo-root-relative path to build.gradle.kts (required because file is not at the package root)"
metrics:
  duration: "~12 minutes"
  completed: "2026-06-14"
  tasks_completed: 2
  files_modified: 4
---

# Phase 110 Plan 01: Version Drift Reconciliation + Lockstep Config Summary

**One-liner:** Release-please wired to linked-versions manifest mode (hex/ios-core/android-core) with reverted mix.exs baseline and a complete signed USER_MANAGED Vanniktech publish block on the Android core.

## What Was Built

### Task 1: Version drift reconciliation + release-please linked-versions config (commit 6838232)

Reconciled the drift between the published Hex version (0.1.0) and the in-tree `mix.exs` (0.1.2):

- `mix.exs` line 4: `@version "0.1.2"` → `@version "0.1.0" # x-release-please-version` (D-04: reverts to true published baseline so release-please writes the correct bump at the real cut)
- `release-please-config.json`: Added `"plugins"` array with one `linked-versions` object grouping `["hex", "ios-core", "android-core"]`; added `"component": "hex"`, `"release-as": "0.1.2"` (one-time bootstrap pin per D-02/D-04 — retained for Phase 111 cleanup), and `"extra-files": ["mix.exs"]` to the `.` package; added `"packages/crosswake-shell-core-ios"` entry (`ios-core`, `simple`, `skip-changelog`, no extra-files); added `"packages/crosswake-shell-core-android"` entry (`android-core`, `simple`, `skip-changelog`, generic extra-files pointing to `packages/crosswake-shell-core-android/build.gradle.kts`)
- `.release-please-manifest.json`: Added `"packages/crosswake-shell-core-ios": "0.1.0"` and `"packages/crosswake-shell-core-android": "0.1.0"` alongside the existing `".": "0.1.0"` (all three at true published baseline, not 0.1.2)

### Task 2: Vanniktech Maven Central publish config + signed POM (commit 2101a99)

Added the complete Android publish configuration to `packages/crosswake-shell-core-android/build.gradle.kts`:

- `id("com.vanniktech.maven.publish") version "0.31.0"` added as last entry in `plugins {}` block
- `version = "0.1.0" // x-release-please-version` added immediately after the plugins block closing brace (the line the release-please generic updater bumps via the config wired in Task 1)
- `mavenPublishing {}` block added after `dependencies {}`:
  - `publishToMavenCentral(SonatypeHost.CENTRAL_PORTAL, automaticRelease = false)` — USER_MANAGED mode, stops at VALIDATED (D-07, load-bearing for D-01)
  - `signAllPublications()` for GPG signing
  - `coordinates("io.github.sztheory", "crosswake-shell-core-android", version.toString())` — Maven groupId is `io.github.sztheory`; Android `namespace = "dev.crosswake.shell.core"` is unchanged
  - Complete POM block with all six fields: `name.set`, `description.set`, `inceptionYear.set`, `url.set`, `licenses { license { } }` (MIT), `developers { developer { } }` (szTheory), `scm { }` (GitHub crosswake repo)

## Verification Results

**Task 1 python3 assertion:** PASSED — all JSON structure asserts exit 0; manifest baselines correct.

**Task 2 grep chain:** PASSED — Vanniktech plugin present, version annotation present, USER_MANAGED mode confirmed, coordinates correct, signAllPublications present, `publishAndReleaseToMavenCentral` absent, `automaticRelease = true` absent, all six POM fields present.

## Deviations from Plan

None — plan executed exactly as written. All D-level overrides applied:
- D-04: `mix.exs @version` → `"0.1.0"`, manifest `.` kept at `"0.1.0"`, `release-as: "0.1.2"` pin retained
- D-07: `automaticRelease = false` (STACK.md showed `true` — overridden)
- PATTERNS.md referenced in plan does not exist in this phase directory, but all required configuration was available verbatim in STACK.md and the plan's action sections

## Known Stubs

None — all configuration values are concrete and load-bearing. No placeholder text, empty arrays, or TODO markers were introduced.

## Threat Surface Scan

No new threat surfaces introduced beyond those already covered by the plan's threat model (T-110-01 through T-110-04). Mitigations applied:

| Threat | Mitigation Applied |
|--------|--------------------|
| T-110-01: Auto-publish risk | `automaticRelease = false` set; verify chain confirmed absence of `publishAndReleaseToMavenCentral` and `automaticRelease = true` |
| T-110-02: Unsigned/incomplete POM | `signAllPublications()` present; all six POM fields verified by grep chain |
| T-110-03: Manifest off-by-one | Manifest baselined at `0.1.0`; `release-as: "0.1.2"` one-time pin present; python3 assertion verifies all three baselines |
| T-110-04: Secrets in build file | No secret values written; signing credentials injected at CI time via `ORG_GRADLE_PROJECT_*` env |

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| mix.exs | FOUND |
| release-please-config.json | FOUND |
| .release-please-manifest.json | FOUND |
| packages/crosswake-shell-core-android/build.gradle.kts | FOUND |
| 110-01-SUMMARY.md | FOUND |
| commit 6838232 | FOUND |
| commit 2101a99 | FOUND |
