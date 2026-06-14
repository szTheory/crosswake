# Project Research Summary

**Project:** Crosswake v11.0 — Release & Distribution Truth
**Domain:** Multi-language OSS library distribution — Hex + SwiftPM subtree mirror + Maven Central, generate-time version injection, lockstep release, clean-room build proof
**Researched:** 2026-06-14
**Confidence:** HIGH

## Executive Summary

Crosswake is a mature codebase (~88% feature-complete) but a partial installable product (~70%). The v5.0 "no eject trap" thesis — replace generated shell logic with standalone SPM/Maven dependencies — is fully implemented in the monorepo but has never been distributed. The flagship failure is concrete: an adopter running `mix crosswake.gen.shell ios` today receives an Xcode project whose SPM reference points at `https://github.com/crosswake/crosswake-shell-core-ios.git` (wrong org, repo absent), and `mix crosswake.gen.shell android` emits `implementation 'dev.crosswake:shell-core-android:0.1.0'` (wrong group ID, artifact never published). The adoption guide documents this 404 install path as working — which makes it actively harmful, not merely incomplete.

The recommended approach, grounded in Apollo iOS, LiveView Native, and Capacitor precedent, is a strict two-phase sequence: Phase A publishes the native cores and wires lockstep versioning before any template is touched, then Phase B rewires templates, proves the published path via a clean-room CI lane, reconciles docs, and cuts Hex 0.1.2. The ordering is non-negotiable: you cannot clean-room-prove an unpublished dep, and you must not cut the Hex release while `gen.shell` still emits broken coordinates. The milestone is complete when a CI job scaffolds a host project in `$RUNNER_TEMP` — outside the monorepo, no `--local`, against published artifacts — and `swift build` plus `./gradlew assembleDebug` both exit 0.

The top risks are irreversibility and silent breakage. Maven Central releases are immutable: a botched `io.github.sztheory:crosswake-shell-core-android:0.1.2` publish (wrong POM, missing GPG signature, unverified namespace) burns that version coordinate permanently. SwiftPM version tags on the mirror repo cannot be force-replaced once any adopter has resolved them. GPG key missing from a public keyserver causes upload rejection with a non-obvious error. The `GITHUB_TOKEN` loop-prevention rule means native publish jobs wired on `on: release: types: [published]` silently never fire. Every one of these has a concrete prevention protocol in the research.

## Key Findings

### Recommended Stack

All tool choices are constrained by what the repository currently runs, not what the latest versions support. The project is on `gradle-8.7` and `compileSdk 34`, which makes Vanniktech maven-publish 0.36.0 (requires Gradle 9.0+) incompatible. The Hex release pipeline uses `googleapis/release-please-action` at `v4.4.1` (SHA `5c625bf`) already pinned in `release-please.yml`. The SwiftPM package is already at `swift-tools 5.9` and already structured correctly for source distribution — nothing about the iOS package itself needs to change; only the mirror repo and CI job are missing.

**Core technologies:**
- `splitsh/lite` v2.0.0: subtree-split `packages/crosswake-shell-core-ios/` to a dedicated mirror repo on every release. The only production-proven approach because SwiftPM's SE-0292 root-manifest constraint makes a monorepo subdir unconsuable over a git URL. Apollo iOS uses this exact pattern.
- `com.vanniktech.maven.publish` 0.31.0 (NOT 0.36.0): publishes Android AAR + auto-generated sources/javadoc jars to Maven Central via Central Portal with GPG signing. 0.31.0 is the newest version compatible with Gradle 8.5+/AGP 8.0+; 0.36.0 requires Gradle 9.0.0+, which exceeds the project's current `gradle-8.7`.
- `googleapis/release-please-action` v4.4.1 with `linked-versions` plugin: one Release PR advances Hex, iOS mirror tag, and Android Maven version atomically. Required because `gen.shell` derives native dep coordinates from `Application.spec(:crosswake)[:vsn]` — if the three registries carry different version numbers, the generated code references a coordinate that may not exist in the registry the adopter hits first.
- EEx + `Application.spec(:crosswake, :vsn)` (Elixir stdlib, zero new deps): generate-time version injection into iOS `.pbxproj.eex` and Android `build.gradle.eex`. This is the LiveView Native `lvn.swiftui.gen` pattern exactly.
- Maven Central namespace `io.github.sztheory`: auto-provisioned on GitHub OAuth login to `central.sonatype.com` with the `szTheory` account. Must be verified before any publish config is written.

**Supporting constraints:**
- `actions/checkout@v4` with `fetch-depth: 0` is mandatory in the splitsh job — shallow clones break splitsh-lite's commit-tree construction.
- `MIRROR_PUSH_TOKEN` (fine-grained PAT, `Contents: write` on the mirror repo) is distinct from `RELEASE_PLEASE_TOKEN`. Both must be distinct from `GITHUB_TOKEN`, which cannot trigger downstream workflow runs by design (release-please-action issue #1000).
- SwiftPM `upToNextMajorVersion` (not `exactVersion`, not `branch:`): lets adopters receive patches and minors without regenerating. `exactVersion` (the current broken template behavior) forces manual regeneration on every patch. `branch:` discards version-sync entirely (the Capacitor issue #7735 anti-pattern).

### Expected Features

**Must have (table stakes) — all P1, none skippable for milestone closeout:**
- iOS SPM core published at a semver git tag on `github.com/szTheory/crosswake-shell-core-ios`. Without this, any iOS dep URL fails SPM resolution.
- Android core published to Maven Central as `io.github.sztheory:crosswake-shell-core-android:0.1.2`. Without this, the generated Gradle dep is a 404 that looks like a typo to the adopter.
- `gen.shell` injects `Application.spec(:crosswake, :vsn)` at generate-time — never a literal version string in the non-local branch.
- Default mode (`--local false`) emits resolvable coordinates only. The `--local true` monorepo-dev path remains unchanged.
- `guides/adoption.md` updated to published truth. A guide documenting a 404 install path is net-harmful.
- Clean-room CI acceptance lane: scaffold host in `$RUNNER_TEMP` outside monorepo, run `gen.shell` without `--local`, `swift build` + `./gradlew assembleDebug`, assert exit 0. Single observable definition of milestone completion.
- Hex 0.1.2 cut — the final step, after native publish verified and clean-room proof passes.
- release-please manifest mode + `linked-versions` group: wire in Phase A before the first publish, or lockstep is broken from the start.

**Should have (differentiators) — P2, do within this milestone but not gating closeout:**
- `mix doctor --check-publish` "published-dep parity" check: asserts generated shell dep coordinates point at published, resolvable, version-matched artifacts. Graduation candidate from `release-distribution-truth.md`. The structural analog to v10.0's `brand-structural` drift gate. Wire into CI as merge-blocking after publish.
- SwiftPM `from:` constraint (`upToNextMajorVersion`) instead of `exactVersion`: template change required in Phase B.
- Source distribution for iOS (not `.binaryTarget`): already correct; document the decision to prevent future XCFramework proposals.

**Defer to post-v11.0:**
- Real device/emulator proof (iOS simulator CI, Android emulator CI): follows once the distribution path is honest.
- Route-policy-101 guide, troubleshooting guide, web-to-mobile migration: teaching a broken install path is net-harmful; these follow v11.0.
- Companion package extraction, new capability breadth: overbuilding on an undistributed base.

### Architecture Approach

The distribution architecture adds a mirror repo and two CI jobs to the existing monorepo without altering monorepo co-development. The monorepo remains authoritative. The iOS mirror (`github.com/szTheory/crosswake-shell-core-ios`) is a read-only CI output: splitsh-lite re-materializes it from full git history on every release. The Android library publishes from the monorepo subproject directly — unlike SwiftPM, Gradle has no root-manifest constraint. The `--local true` proof lane (`phase79-proof.yml`) is preserved unchanged as the PR merge-blocker. The clean-room lane is a post-release acceptance gate, not a PR gate — wiring it as a PR gate creates a chicken-and-egg deadlock against unpublished deps.

**Major components:**
1. `mix.exs @version` — single source of truth; all downstream systems derive from it via `Application.spec/2` or release-please `extra-files` updater.
2. `crosswake.gen.shell` task (modified) — adds `version: Application.spec(:crosswake, :vsn) |> to_string()` assign in `render_template/3`.
3. `project.pbxproj.eex` (modified) — fixes org to `szTheory`, replaces `exactVersion` with `upToNextMajorVersion`, injects `<%= @version %>`.
4. `app/build.gradle.eex` (modified) — replaces hardcoded GAV with `implementation("io.github.sztheory:crosswake-shell-core-android:<%= @version %>")`.
5. `packages/crosswake-shell-core-android/build.gradle.kts` (modified) — adds Vanniktech 0.31.0, `version = "0.1.0" // x-release-please-version`, full POM with `io.github.sztheory` coordinates.
6. `release-please.yml` ios-mirror job (new) — splitsh-lite with `fetch-depth: 0`; pushes to mirror; creates annotated tag from `outputs.tag_name`.
7. `release-please.yml` android-publish job (new) — `./gradlew publishToMavenCentral --no-daemon` with five `ORG_GRADLE_PROJECT_*` secrets.
8. `clean-room-proof.yml` job (new) — scaffolds host in `$RUNNER_TEMP`, `gen.shell` without `--local`, `swift build` + `gradle build`. Runs as `needs: [ios-mirror, android-publish]`.
9. `release-please-config.json` (modified) — `linked-versions` plugin; iOS + Android package entries; `extra-files` annotations.

**Version propagation flow (summary):**
```
mix.exs @version "0.1.2"  (single source of truth)
  -> Application.spec(:crosswake)[:vsn] -> render_template/3 -> @version assign
      -> project.pbxproj.eex: minimumVersion = 0.1.2 (upToNextMajorVersion)
      -> app/build.gradle.eex: io.github.sztheory:...-android:0.1.2
  -> release-please extra-files: bumps mix.exs @version + build.gradle.kts version on release PR
  -> release-please outputs.version: ios-mirror tag + android-publish GAV
```

**Release trigger flow:**
```
Release PR merged -> release_created == true
  -> publish-hex (existing)
  -> ios-mirror: splitsh + annotated tag on szTheory/crosswake-shell-core-ios (new)
  -> android-publish: Vanniktech to Central Portal (new)
      -> clean-room-proof: scaffold outside monorepo, swift + gradle build (new)
```

### Critical Pitfalls

**IRREVERSIBLE — must get right before any publish:**

1. **Burning a Maven Central version** — wrong POM, missing GPG signature, or unverified namespace at publish time permanently occupies that version coordinate. Prevention: `./gradlew publishToMavenLocal` + inspect `~/.m2` layout before any Central Portal attempt; CI dry-run gate required; never publish from a developer machine without CI dry-run passing. Phase A must include an explicit dry-run verification step.

2. **GPG key not on a public keyserver** — Central Portal rejects uploads if the public key is not on `keyserver.ubuntu.com` or `keys.openpgp.org`. The error is non-obvious. Prevention: push to two keyservers immediately after key generation; verify from a clean environment before writing any publish CI config.

3. **Re-tagging an existing iOS mirror version tag** — `Package.resolved` locks the commit hash; a re-tag producing a different hash causes `checksum mismatch` for all adopters who resolved the original. Prevention: CI push job has no `--force`; mirror repo has tag protection; job runs only on `release_created`.

**SILENT BREAKAGE — non-obvious adopter failures:**

4. **GITHUB_TOKEN does not trigger downstream `release: published` workflows** — GitHub's loop-prevention rule silently drops these events. Native publish jobs wired this way never run. Prevention: all native publish jobs run as `needs:` steps in the same `release-please.yml` with `if: needs.release-please.outputs.release_created == 'true'`. The existing `publish-hex` job already uses this pattern.

5. **Hardcoded satellite version in generated templates** — literal version strings in EEX non-local branches drift silently as Crosswake advances (LiveView Native's documented `LiveViewNativeLiveForm` bug). An adopter on Hex 0.1.5 generates shell code pinned to 0.1.0 native deps. Prevention: every native dep coordinate in the non-local branch uses `<%= @version %>` only; never a literal.

6. **SwiftPM root-manifest constraint makes monorepo subdir unconsuable** — SE-0292 makes package identity equal to the repo root; there is no `subdirectory:` parameter. Architectural, not configurable. Prevention: subtree mirror is the only correct path.

7. **splitsh-lite requires `fetch-depth: 0`** — shallow clones produce broken commit trees. Prevention: ios-mirror job must include `fetch-depth: 0` in `actions/checkout@v4`; no exception.

## Implications for Roadmap

The research imposes a hard A-before-B phase constraint with four dependency chains that make reordering impossible:

- Cannot clean-room-prove a dep that does not exist yet (clean-room lane requires published artifacts from Phase A).
- Must not cut Hex 0.1.2 while `gen.shell` emits broken coordinates (even a brief window exposes adopters to a broken scaffold).
- Template rewire requires knowing final published coordinates (org `szTheory`, group `io.github.sztheory`, version from Hex) — only final after Phase A is wired.
- `doctor --check-publish` parity check requires published artifacts; must be post-publish-only.

### Phase A: Native Publish Infrastructure

**Rationale:** Everything in Phase B depends on real published artifacts at correct coordinates. This phase creates them and wires lockstep. It has no dependency on template changes and can proceed immediately.

**Delivers:**
- `github.com/szTheory/crosswake-shell-core-ios` mirror repo with `v0.1.2` annotated tag, resolvable via `swift package resolve`.
- `io.github.sztheory:crosswake-shell-core-android:0.1.2` on Maven Central, visible in `search.maven.org`.
- `release-please-config.json` updated with `linked-versions` plugin + iOS + Android package entries + `extra-files` annotations.
- CI pipeline: `ios-mirror` + `android-publish` jobs in `release-please.yml` under `needs: release-please` + `if: release_created`.
- GPG key infrastructure: public key on two keyservers, five `ORG_GRADLE_PROJECT_*` secrets, `MIRROR_PUSH_TOKEN` PAT.

**Must-avoid pitfalls:** 1 (burned Maven version — dry-run gate), 2 (GPG keyserver — verify before first publish), 3 (re-tagging — no force, branch protection), 7 (GITHUB_TOKEN — same-workflow needs:), 8 (manifest not multi-package — wire linked-versions now), 11 (re-tagging mirror — no --force), 12 (wrong namespace — verify io.github.sztheory in Central Portal first).

**Suggested internal step order:**
1. Central Portal namespace verification (`io.github.sztheory`) — blocking prerequisite; most likely human-time bottleneck.
2. GPG key generation + keyserver upload (two servers) + CI secrets provisioning.
3. `release-please-config.json` / `.release-please-manifest.json` multi-package wiring + `build.gradle.kts` Vanniktech plugin + POM.
4. Local dry-run: `./gradlew publishToMavenLocal`, inspect `~/.m2` layout for all required jars + `.asc` files.
5. Create `github.com/szTheory/crosswake-shell-core-ios` empty public repo + `MIRROR_PUSH_TOKEN` secret.
6. CI job wiring: ios-mirror + android-publish jobs in `release-please.yml`.
7. First real publish via CI (triggered by Release PR merge).
8. Verify: iOS tag resolves from clean `swift package resolve`; Android artifact appears in Maven search.

**Research flag:** No additional research phase needed. All tools and config shapes are fully specified. Main execution risk is the one-time GPG + Sonatype namespace setup.

---

### Phase B: Template Rewire + Clean-Room Proof + Doc Reconciliation

**Rationale:** Gated on Phase A because the clean-room lane cannot pass until published artifacts exist, and the template rewire introduces the correct org/group/coordinates that only become final when Phase A is complete. Doing Phase B before Phase A would mean rewriting templates twice or shipping a gap between Hex cut and correct templates.

**Delivers:**
- `gen.shell` task: `version: Application.spec(:crosswake, :vsn) |> to_string()` added to `render_template/3`.
- `project.pbxproj.eex`: org fixed to `szTheory`, `exactVersion` replaced with `upToNextMajorVersion; minimumVersion = <%= @version %>`.
- `app/build.gradle.eex`: hardcoded GAV replaced with `implementation("io.github.sztheory:crosswake-shell-core-android:<%= @version %>")`.
- `clean-room-proof.yml`: scaffolds in `$RUNNER_TEMP`, runs `gen.shell` (no `--local`), `swift build` + `./gradlew assembleDebug`, asserts exit 0. Runs as `needs: [ios-mirror, android-publish]`.
- `guides/adoption.md` reconciled to real published install path; `guides/support_matrix.md` updated.
- `mix doctor --check-publish` "published-dep parity" check wired as merge-blocking CI lane.
- Hex 0.1.2 cut — the final step, triggered after clean-room proof passes.

**Must-avoid pitfalls:** 3 (broken URL — do not change templates until Phase A artifacts exist), 4 (hardcoded version drift — inject `@version` only), 9 (branch/exact pinning — use `upToNextMajorVersion`), 10 (clean-room proof inside monorepo — must scaffold outside in `$RUNNER_TEMP` with no `packages/` access).

**Suggested internal step order:**
1. Template rewire: `gen.shell` version assign + both EEX template fixes (URL, GAV, version expression).
2. Verify locally: `mix crosswake.gen.shell ios` and `mix crosswake.gen.shell android` emit correct dep strings.
3. `clean-room-proof.yml` job wiring.
4. Verify clean-room lane passes against Phase A published artifacts (milestone acceptance gate).
5. `doctor --check-publish` parity check wiring.
6. `guides/adoption.md` + `guides/support_matrix.md` reconciliation.
7. Merge -> release-please opens PR -> merge -> Hex 0.1.2 published -> clean-room proof runs post-release as final acceptance.

**Research flag:** No additional research phase needed. EEX template editing is stdlib Elixir. Clean-room CI job shape is fully specified in ARCHITECTURE.md. Doctor check design is specified in FEATURES.md.

---

### Phase Ordering Rationale

- **Cannot clean-room-prove an unpublished dep.** The clean-room lane is the milestone acceptance gate. It cannot run until both mirror tag and Maven artifact exist. Those come from Phase A.
- **Do not cut Hex while gen.shell emits broken coordinates.** The current default `gen.shell` path produces a broken scaffold. Cutting Hex 0.1.2 before Phase B template rewire exposes adopters to it during the gap.
- **Template rewire should happen once, to final coordinates.** Final published coordinates (correct org, correct group ID) are known only after Phase A is wired.
- **Lockstep config must precede the first publish.** If `release-please-config.json` is updated after the first native publish, the manifest is out of sync and the first linked bump will fail.

### Research Flags

**No research phase needed for either phase.** All tools, config shapes, CI job patterns, and template changes are fully specified in the research files with HIGH-confidence sources. The Vanniktech plugin config block, splitsh CI job, release-please manifest shape, and EEX template changes are reproduced verbatim in STACK.md and ARCHITECTURE.md.

**Validate during execution (not research-phase items):**
- Central Portal namespace auto-provisioning: in most cases GitHub OAuth login auto-provisions `io.github.sztheory`; if not, the manual verification flow requires a temporary public repo (allocate 30 minutes).
- splitsh-lite `--scratch` flag in v2.0.0: PITFALLS.md cites it to prevent history bleed between runs; verify flag existence in `splitsh-lite --help` before committing to the CI job template.
- `Package.swift` product name coupling: template references `CrosswakeShellCore` as product name; `Package.swift` declares `.library(name: "CrosswakeShellCore", ...)` — these must stay coupled; document the invariant.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All versions verified against official releases and changelogs. Vanniktech 0.31.0 vs 0.36.0 constraint verified against Gradle version requirement in plugin changelog. splitsh v2.0.0 confirmed latest stable. release-please v4.4.1 SHA confirmed. |
| Features | HIGH | Grounded in repo-local file inspection — actual template bugs confirmed at exact line numbers, not inferred. Table stakes vs deferral boundary is firm based on dependency graph. |
| Architecture | HIGH | Built from actual file inspection of all 9 modified + 3 new components. Data flow diagrams match actual file structure. Build order is dependency-derived. |
| Pitfalls | HIGH (critical), MEDIUM (Pitfall 6 / product name) | Critical pitfalls confirmed with official docs and named issues. Pitfall 6 (product name / repo name mismatch) is community-pattern-based. |

**Overall confidence:** HIGH

### Gaps to Address

- **splitsh-lite `--scratch` flag in v2.0.0**: PITFALLS.md cites it as preventing history bleed between runs; verify it exists in v2.0.0 before committing to the CI job template. If absent, re-evaluate the split-and-push sequence. Resolution: check `splitsh-lite --help` output in Phase A CI wiring step.
- **Central Portal staging dry-run API**: research recommends a staging dry-run; `publishToMavenLocal` is the available dry-run path but does not exercise the Central Portal upload path. Resolution: accept local Maven inspection as the dry-run; wire a CI `--dry-run` flag if the Vanniktech task supports it.
- **`doctor --check-publish` HTTP HEAD endpoint**: design calls for asserting reachability against a Maven Central API endpoint for artifact status. The 2025+ Central Portal API endpoint for artifact lookup was not independently verified. Resolution: scope the Phase B parity check to URL format correctness + registry reachability; full artifact download proof is delegated to the clean-room lane.

## Sources

### Primary (HIGH confidence)
- Vanniktech gradle-maven-publish-plugin changelog + docs: https://vanniktech.github.io/gradle-maven-publish-plugin/ — version compatibility matrix, POM requirements, Central Portal config
- `googleapis/release-please-action` releases + issue #1000: https://github.com/googleapis/release-please-action — v4.4.1 SHA `5c625bf`, GITHUB_TOKEN downstream trigger limitation, same-workflow job chaining pattern
- release-please manifest docs: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md — linked-versions plugin, extra-files, x-release-please-version annotation syntax
- Central Portal namespace docs: https://central.sonatype.org/register/namespace/ — io.github.USERNAME auto-provisioning, GPG keyserver requirements
- Maven Central immutability policy: https://central.sonatype.org/publish/requirements/immutability/
- splitsh/lite releases: https://github.com/splitsh/lite/releases — v2.0.0 confirmed latest stable (released 2025-10-26)
- SwiftPM SE-0292 root-manifest constraint: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0292-package-registry-service.md
- Apollo iOS subtree mirror pattern: https://www.apollographql.com/blog/how-apollo-manages-swift-packages-in-a-monorepo-with-git-subtrees
- Repo-local file inspection: `lib/mix/tasks/crosswake.gen.shell.ex`, `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex`, `priv/templates/crosswake/shell/android/app/build.gradle.eex`, `settings.gradle.eex`, `packages/crosswake-shell-core-android/build.gradle.kts`, `packages/crosswake-shell-core-ios/Package.swift`, `.github/workflows/release-please.yml`, `release-please-config.json`, `.release-please-manifest.json`
- OSSRH sunset confirmation: https://so.nwalsh.com/2025/06/01-maven (shutdown 2025-06-30; Central Portal is the only current path)

### Secondary (MEDIUM confidence)
- LiveView Native generate-time version injection pattern: referenced in `.planning/threads/release-distribution-truth.md` — `Application.spec(:live_view_native_swiftui)[:vsn]` pattern; GitHub source not independently fetched
- Capacitor branch-pinning issue #7735 and relative-path issue #6040: referenced in pre-gathered research; not independently re-verified
- splitsh-lite `--scratch` flag: referenced in PITFALLS.md integration gotchas; not independently verified against v2.0.0 release notes
- SwiftPackageIndex/PackageList PR submission process: https://github.com/SwiftPackageIndex/PackageList — stable process, not re-verified for 2026

### Tertiary (LOW confidence)
- Central Portal staging dry-run API availability: inferred from general Sonatype documentation; 2025+ Central Portal staging UI not independently verified
- Maven Central API endpoint for artifact status lookup (doctor check design): exact endpoint not independently verified for Central Portal 2025+ API

---
*Research completed: 2026-06-14*
*Ready for roadmap: yes*
