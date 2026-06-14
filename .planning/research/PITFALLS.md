# Pitfalls Research

**Domain:** Multi-language publishing + generator rewiring — OSS library (v11.0 Release & Distribution Truth)
**Researched:** 2026-06-14
**Confidence:** HIGH (Maven Central immutability docs, release-please issue #1000, SwiftPM SE-0292, repo-local template inspection), MEDIUM (splitsh-lite CI behavior, Package.swift product-name matching), LOW (only where community-pattern-only evidence)

---

## Critical Pitfalls

### Pitfall 1: Burning a Maven Central Version (IRREVERSIBLE)

**What goes wrong:**
A botched `io.github.sztheory:crosswake-shell-core-android:0.1.0` publish — wrong POM, missing signature, wrong namespace, wrong artifact layout — permanently occupies that version coordinate. Maven Central's immutability policy is absolute: once a release is publicly available, Sonatype will not delete or modify it. Publishing `0.1.2` with a broken POM means `0.1.2` is burned. The fix is to publish `0.1.3` and tell every adopter to skip `0.1.2`.

**Why it happens:**
Developers test the happy path against local Maven (`~/.m2`) which has no POM validation or GPG enforcement. The first time they see the Central Portal's real requirements is when the upload rejects — but if they bypass the dry-run and publish with `--no-sign` or an incomplete POM in a moment of frustration, they get a rejected artifact under the version they intended to ship. Rejected-but-published artifacts are still immutable on the namespace.

**How to avoid:**
1. Always run `./gradlew publishToMavenLocal` first and inspect `~/.m2/repository/io/github/sztheory/crosswake-shell-core-android/<version>/` for the full GAV layout, POM content, `.asc` signatures, and sources+javadoc jars before attempting Central Portal.
2. Use Vanniktech maven-publish (≥0.30.0) which defaults to Central Portal and auto-generates the mandatory jars.
3. Add a mandatory CI dry-run step (`./gradlew publishAllPublicationsToMavenCentralRepository --dry-run` or staging-only publish) that fails fast before the real push.
4. Never publish manually from a developer machine without the dry-run passing in CI first.
5. Reserve `0.1.0` as the published version for the first clean cut; if there is any doubt, use a staging namespace test.

**Warning signs:**
- Build script has no `maven-publish` or Vanniktech plugin yet (confirmed: `packages/crosswake-shell-core-android/build.gradle.kts` currently has only `namespace`, no publish config).
- No `group` or `version` declared in the library's `build.gradle.kts`.
- No GPG setup verified against a keyserver.
- No staging publish step in CI.

**Phase to address:** Phase A (native publish-config). The entire publish-config phase must include dry-run verification before any real publish attempt.

---

### Pitfall 2: GPG Key Not Reachable on a Public Keyserver (Breaks Maven Central Upload)

**What goes wrong:**
Central Portal requires GPG-signed artifacts and a public key discoverable at `keyserver.ubuntu.com`, `keys.openpgp.org`, or `pool.sks-keyservers.net`. If the key was generated locally and never pushed to a keyserver, upload validation rejects the signature verification. The error is not always obvious — it may look like a checksum mismatch or a generic upload failure.

**Why it happens:**
Developers generate a GPG key, sign artifacts, and test locally where the key is in the local keyring. The keyserver upload step (`gpg --keyserver keyserver.ubuntu.com --send-keys <KEY_ID>`) is easy to forget because signing "works" in local testing.

**How to avoid:**
1. After generating the GPG key, immediately publish to at minimum two keyservers: `gpg --keyserver keyserver.ubuntu.com --send-keys <KEY_ID>` and `gpg --keyserver keys.openpgp.org --send-keys <KEY_ID>`.
2. Verify propagation: `gpg --keyserver keyserver.ubuntu.com --recv-keys <KEY_ID>` from a clean environment (not the machine that signed).
3. Store the GPG private key and passphrase in GitHub Actions secrets (`GPG_PRIVATE_KEY`, `GPG_PASSPHRASE`), import with `gpg --import` in the CI publish job.
4. Add a CI pre-publish check that verifies the key is on the keyserver before attempting the publish.

**Warning signs:**
- No `GPG_PRIVATE_KEY` / `GPG_PASSPHRASE` secrets in the repository.
- No keyserver upload step documented anywhere.
- Maven Central upload fails with "signature verification failed" or generic 400 errors.

**Phase to address:** Phase A (native publish-config). Must be done before the first real publish attempt, not after.

---

### Pitfall 3: Relative-Path Dep in Generated Code Silently Produces an Unbuildable Adopter Project

**What goes wrong:**
`mix crosswake.gen.shell` currently defaults `--local false` but its non-local branch emits broken coordinates:
- iOS: `repositoryURL = "https://github.com/crosswake/crosswake-shell-core-ios.git"` (wrong org — real is `szTheory`; repo absent)
- Android: `implementation 'dev.crosswake:shell-core-android:0.1.0'` (wrong group ID — real will be `io.github.sztheory`; artifact never published)

An adopter running `mix crosswake.gen.shell ios` gets an Xcode project that Xcode tries to resolve, fails silently at SPM dependency resolution, and produces a build failure the adopter has no obvious way to diagnose. The generator has no warning and no validation that the referenced dep exists.

**Why it happens:**
The generator was written before the distribution infrastructure existed (v5.0 shipped the code, not the publish). The `--local` flag exists for monorepo development and the non-local branch was written as a placeholder. Nothing in the generation flow validates that the referenced URL/coordinates are real.

**How to avoid:**
1. Before changing any template, publish the native cores so the coordinates exist.
2. Rewire the iOS template: `repositoryURL = "https://github.com/szTheory/crosswake-shell-core-ios.git"` with the correct org.
3. Rewire the Android template: `implementation("io.github.sztheory:crosswake-shell-core-android:<%= @version %>")`.
4. The `--local` path in `settings.gradle.eex` (`project(':crosswake-shell-core-android').projectDir = new File('../../../packages/...')`) must remain for in-monorepo development but must never appear in a default (non-`--local`) generate.
5. Add a doctor check or post-generate warning that prints the dep coordinates and tells the adopter to verify `swift package resolve` / `gradle dependencies` succeed.

**Warning signs (current):**
- `app/build.gradle.eex` line 54: `implementation 'dev.crosswake:shell-core-android:0.1.0'` — wrong group ID and hardcoded version.
- `project.pbxproj.eex` line 56: `repositoryURL = "https://github.com/crosswake/crosswake-shell-core-ios.git"` — wrong org.
- No CI lane that runs `gen.shell` outside the monorepo and confirms `swift build` / `gradle build` succeed.

**Phase to address:** Phase B (template rewire). Must not touch templates until Phase A completes — the published coordinates must exist first, or the rewire introduces new broken coordinates.

---

### Pitfall 4: Hardcoded Satellite Version While Main Version Is Derived (Silent Drift)

**What goes wrong:**
The generator currently hardcodes `version = 0.1.0` in the Xcode project requirement (`requirement = { kind = exactVersion; version = 0.1.0; }`) and `implementation 'dev.crosswake:shell-core-android:0.1.0'`. If these are not derived at generate-time from the installed Crosswake Hex package version, they become stale as Crosswake releases advance. An adopter on Crosswake 0.1.5 generates shell code pinned to the 0.1.0 native deps — ABI-incompatible by design if the native protocol evolves.

LiveView Native hit exactly this bug: `LiveViewNativeLiveForm` was hardcoded to `from: "0.4.0-rc.1"` while the main package version was derived, causing silent protocol drift when the main package advanced.

**Why it happens:**
The native version coordinate looks like a constant at write-time. Developers assume the template will be regenerated; in reality the generator's "scaffold once" posture means the generated files are not safely regeneratable over host edits (the README says so explicitly). The version is written once and rots.

**How to avoid:**
1. Inject `Application.spec(:crosswake)[:vsn]` at generate-time into every native dep coordinate (the LiveView Native `lvn.swiftui.gen` pattern).
2. iOS: emit `.package(url: "https://github.com/szTheory/crosswake-shell-core-ios", from: "<%= @version %>")` using `upToNextMajor` semantics rather than `exactVersion` — allows adopters to receive patch/minor updates without regeneration, while the `Package.resolved` file pins the exact resolved version.
3. Android: emit `implementation("io.github.sztheory:crosswake-shell-core-android:<%= @version %>")`.
4. The `@version` assign must be sourced from the Hex package spec, not a module attribute or compile-time constant — this ensures it tracks Hex releases automatically.
5. Add a "published-dep parity" doctor check (graduation candidate from `threads/release-distribution-truth.md`) that asserts generated coordinates match `Application.spec(:crosswake)[:vsn]` post-generate.

**Warning signs:**
- Template files contain literal version strings (`0.1.0`) rather than EEx expressions.
- `render_template/3` only passes `[capabilities: capabilities, local: local]` — no `version` assign exists today.
- No test asserts that the generated version coordinate matches the installed Hex version.

**Phase to address:** Phase B (template rewire). The version injection must be implemented as part of the same work that rewires the URL/group-ID.

---

### Pitfall 5: SwiftPM Root-Manifest Constraint — Monorepo Subdir Is Not Consumable (IRREVERSIBLE by Architecture)

**What goes wrong:**
SwiftPM resolves packages by git repository identity, not subpath. The constraint (SE-0292) means `packages/crosswake-shell-core-ios/` inside the monorepo cannot be referenced over a git URL with a `subdirectory:` parameter in any Package.swift — the parameter does not exist in SwiftPM. Any attempt to teach adopters to add the monorepo URL with a subpath will fail at `swift package resolve` with an error about no `Package.swift` at the root.

**Why it happens:**
Developers coming from other ecosystems assume "publish a subdir" is analogous to npm workspaces or Maven subprojects. Maven subprojects publish fine to Central; SwiftPM subdir do not.

**How to avoid:**
1. The only correct path is a dedicated read-only mirror repository (`github.com/szTheory/crosswake-shell-core-ios`) that receives subtree-pushed commits from the monorepo via `splitsh-lite` in CI.
2. The mirror must have semver-annotated git tags (`0.1.2`, `0.1.3` etc.) — the tag IS the SwiftPM version; `Package.swift` carries no version field.
3. In CI, the subtree push job must run `fetch-depth: 0` (full history) — `splitsh-lite` requires full history to produce correct commit trees; shallow clones produce broken splits.
4. Never re-tag an existing version tag on the mirror repo — SwiftPM clients resolve by tag and `Package.resolved` locks the commit; a re-tag producing a different commit hash is a reproducibility violation.

**Warning signs:**
- `Package.swift` in `packages/crosswake-shell-core-ios/` has no version field (confirmed — correct, but only because SwiftPM versions come from git tags; the mirror repo must exist and have the tag).
- No `github.com/szTheory/crosswake-shell-core-ios` repo exists yet.
- No CI workflow that pushes to the mirror repo on release.

**Phase to address:** Phase A (native publish-config). The mirror repo must be created, the CI subtree-push job must be wired, and a test tag must be pushed before the template rewire in Phase B can reference a real URL.

---

### Pitfall 6: SwiftPM Product Name Must Match Package.swift Product Declaration (Silent Build Failure)

**What goes wrong:**
The Xcode project (`project.pbxproj`) references `CrosswakeShellCore` as the product name (`/* CrosswakeShellCore in Frameworks */`). If the `Package.swift` product declaration on the mirror repo ever changes the product name, or if the mirror repo name differs from what the `XCRemoteSwiftPackageReference` expects, Xcode produces a "missing package product" error that is confusing and non-obvious.

Currently `Package.swift` declares `.library(name: "CrosswakeShellCore", ...)` and the `.pbxproj` references `CrosswakeShellCore`. This is consistent, but the mirror repo is named `crosswake-shell-core-ios` (kebab-case) while the product is `CrosswakeShellCore` (CamelCase). SwiftPM resolves by product name, not repo name, so the mismatch is safe — but any refactor that renames the product without updating both `Package.swift` and the generated template breaks silently.

**Why it happens:**
Swift package product names and repository names follow different naming conventions. Developers rename one without updating the other.

**How to avoid:**
1. Treat the `Package.swift` product name (`CrosswakeShellCore`) and the `project.pbxproj` product reference as a coupled pair — any rename requires updating both.
2. Add a CI check on the mirror repo that verifies the `Package.swift` product name has not changed relative to the expected value used in the generator template.
3. Document the naming invariant explicitly: "The `Package.swift` library name must remain `CrosswakeShellCore`; the repo name is irrelevant to SwiftPM resolution."

**Warning signs:**
- Xcode shows "missing package product 'CrosswakeShellCore'" after adding the SPM dependency.
- The `Package.swift` `.library(name:)` does not match the generated `project.pbxproj` product reference.

**Phase to address:** Phase A (native publish-config) when setting up the mirror repo; Phase B (template rewire) must verify consistency.

---

### Pitfall 7: Release-Please GITHUB_TOKEN Does Not Trigger Downstream Native-Publish Workflows

**What goes wrong:**
The current `release-please.yml` uses `secrets.RELEASE_PLEASE_TOKEN || github.token`. When release-please creates a GitHub Release using the default `GITHUB_TOKEN`, that release event does NOT trigger other workflows that listen on `on: release: types: [published]`. GitHub deliberately prevents this loop to avoid recursive workflow runs. This means native-publish jobs gated on `release: published` simply never run.

This is a confirmed known issue documented in release-please-action issue #1000.

**Why it happens:**
Developers wire `on: release: types: [published]` and assume the release-please-created release will fire it. The documentation for this loop-prevention behavior is not prominent.

**How to avoid:**
1. Do NOT gate native publish jobs on `on: release: types: [published]`.
2. Instead, put native publish jobs as additional `needs:` steps within the same `release-please.yml` workflow, gated with `needs: release-please` and `if: ${{ needs.release-please.outputs.release_created == 'true' }}`. The existing `publish-hex` job already uses this pattern correctly — replicate it for iOS subtree-push and Android Maven Central publish.
3. Alternatively, use a fine-grained PAT (store as `RELEASE_PLEASE_TOKEN` secret) instead of `github.token` for the release-please step — PAT-created events DO trigger other workflows. The current `release-please.yml` already has the `|| github.token` fallback scaffolded for this.

**Warning signs:**
- A separate workflow file with `on: release: types: [published]` for native publishing — it will silently never trigger.
- Checking GitHub Actions runs after a release-please merge shows the release job ran but native publish jobs show no run record.

**Phase to address:** Phase A (native publish-config + CI wiring). The lockstep publish pipeline must be designed correctly before the first real publish attempt.

---

### Pitfall 8: release-please Manifest Mode Not Configured for Multi-Package Lockstep

**What goes wrong:**
The current `release-please-config.json` registers only the root package (`.`) with `release-type: elixir` and `.release-please-manifest.json` tracks only `{ ".": "0.1.0" }`. This single-package configuration will advance the Hex version independently of the iOS tag and Android library version. An adopter running `gen.shell` after `crosswake 0.1.2` ships but before native deps are tagged and published gets a generated project referencing `0.1.2` deps that do not exist yet.

**Why it happens:**
The release-please config was set up for Hex-only publishing during v3.3. Adding native packages was deferred until v11.0.

**How to avoid:**
1. Extend `release-please-config.json` to register the Android library path (`packages/crosswake-shell-core-android`) with `release-type: simple` and the iOS mirror trigger (or use `extra-files` to annotate `packages/crosswake-shell-core-android/build.gradle.kts` with `x-release-please-version`).
2. Use the `linked-versions` plugin in manifest mode to enforce that all registered packages advance together: the release PR carries one version and all packages' version files are updated atomically.
3. The iOS tag is not a version file that release-please updates — instead, the CI subtree-push job reads `needs.release-please.outputs.version` and uses it to create the annotated git tag on the mirror repo.
4. Verify: after a release-please PR merge, all three coordinates (Hex `mix.exs @version`, `build.gradle.kts version`, mirror repo tag) must carry the same version before the clean-room proof lane runs.

**Warning signs:**
- `release-please-config.json` packages block contains only `"."`.
- `.release-please-manifest.json` contains only `{ ".": "..." }`.
- After a release, `packages/crosswake-shell-core-android/build.gradle.kts` still has no `version` field.

**Phase to address:** Phase A (native publish-config). Must be done before the first publish so that the version source of truth is correct from day one.

---

### Pitfall 9: Branch-Pinning SwiftPM Dep (`branch: "main"`) Discards Version Guarantee

**What goes wrong:**
Pinning the SwiftPM dep with `branch: "main"` instead of `from: "x.y.z"` or `exactVersion` means every `swift package update` pulls whatever commit is on `main` of the mirror at that moment. The adopter's `Package.resolved` re-locks to a new commit hash on update — with no version signal. This is the Capacitor SPM migration bug (issue #7735).

In the generated `project.pbxproj` the requirement is currently `kind = exactVersion; version = 0.1.0` which is the right intent but uses `exactVersion` which prevents adopters from receiving patch/minor updates without regenerating.

**Why it happens:**
Branch-pinning is often used during development before tags exist. It gets committed and shipped. `exactVersion` is used when the developer over-corrects toward lock-step reproducibility without considering the adopter's update path.

**How to avoid:**
1. Use `from:` (up-to-next-major semantics) in the generated `.package(url:, from: "x.y.z")` Swift package dependency — not `branch:` and not `exactVersion`.
2. The `from:` constraint allows patch and minor updates to flow to the adopter naturally; breaking changes are gated at majors.
3. The `Package.resolved` file in the adopter's project pins the exact resolved version, providing reproducibility without preventing non-breaking updates.
4. The Xcode `.pbxproj` `requirement` block must use `kind = upToNextMajorVersion; minimumVersion = x.y.z` rather than `kind = exactVersion`.

**Warning signs:**
- Template `project.pbxproj.eex` uses `kind = exactVersion` (confirmed current state, line 58).
- Any generated `Package.swift` or `package-collection.json` that uses `branch: "main"`.

**Phase to address:** Phase B (template rewire). Change `exactVersion` to `upToNextMajorVersion` when injecting the version.

---

### Pitfall 10: Clean-Room Proof Lane Inside the Monorepo Does Not Prove Anything

**What goes wrong:**
All existing native proof lanes (`--local` paths in `settings.gradle.eex` and `project.pbxproj.eex`) resolve deps against the monorepo's `packages/` directory. A CI lane that runs `gen.shell` and builds inside the monorepo with `--local` never exercises the published coordinates. It proves only that the code compiles in the development layout. An adopter outside the repo who hits the 404 install path is not protected by this lane.

This is Crosswake's current situation: "The flagship claim is proven only inside this monorepo" (threads/release-distribution-truth.md).

**Why it happens:**
Clean-room proof requires an external repo and published deps — both of which did not exist until this milestone. CI proof lanes were written against what was available (monorepo-local deps) and were accepted as sufficient at the time.

**How to avoid:**
1. The acceptance gate must scaffold a host project in a temp directory OUTSIDE the monorepo — e.g., in `$RUNNER_TEMP` or a job-local workspace — using the default (non-`--local`) `gen.shell` invocation.
2. The clean-room job must have no access to the monorepo `packages/` directory to prevent accidental local resolution.
3. It must run `swift build` (or `xcodebuild -resolvePackageDependencies`) and `gradle build` against the published mirror tag and Maven Central artifact.
4. This lane must be required (merge-blocking) and must run after Phase A completes (published deps exist) and after Phase B completes (templates emit correct coordinates).

**Warning signs:**
- Proof lanes run `gen.shell --local` or reference `packages/` paths.
- CI proof passes even when `github.com/szTheory/crosswake-shell-core-ios` does not exist.
- No temp-directory scaffold step in any workflow file.

**Phase to address:** Phase B (clean-room proof). The lane should be the final gating step that proves both Phase A (real published deps) and Phase B (correct template coordinates) together.

---

### Pitfall 11: Re-Tagging an Existing SwiftPM Version Tag (IRREVERSIBLE for Adopters)

**What goes wrong:**
If a tag (`0.1.2`) is pushed to the mirror repo, an adopter resolves it and their `Package.resolved` locks the commit hash. If the tag is force-deleted and re-created pointing at a different commit, any adopter who has already resolved the old commit sees a hash mismatch — `swift package resolve` fails with a "checksum mismatch" or "different package at this version" error. The only fix is for every adopter to delete their `Package.resolved` and re-resolve, which may pull a different (newer) patch.

**Why it happens:**
A tag is pushed too early (e.g., before the subtree mirror has the correct content), then force-pushed to fix it.

**How to avoid:**
1. Never force-push or re-create a tag on the mirror repo.
2. Run the subtree-split in CI against the monorepo's release tag, not against `main`. This ensures the mirrored content matches the released Hex package.
3. If a tag is botched before any adopter has resolved it (within minutes of publish), delete the release on GitHub, delete the tag, and push a corrected new version tag. This is only acceptable if no `Package.resolved` files in the wild have locked the old hash.
4. Otherwise: publish `0.1.3` with the fix and communicate the skip.

**Warning signs:**
- CI subtree job pushes to the mirror on every `main` push rather than only on `release_created`.
- Tag creation happens in a manually-run job rather than the automated release pipeline.

**Phase to address:** Phase A (native publish-config). The CI job design must be review-gated so force-push is structurally prevented (branch protection on mirror + no `--force` in the push command).

---

### Pitfall 12: Wrong Maven namespace — `io.github.sztheory` Requires Verified Public GitHub Org/User

**What goes wrong:**
Maven Central's `io.github.*` namespace requires proof of ownership. The namespace `io.github.sztheory` maps to GitHub user `szTheory` (case-insensitive in GitHub, but case-sensitive in Maven GAV). If the namespace was not verified during initial Central Portal account setup, the upload is rejected with a namespace ownership error — not a POM error, a different class of failure entirely.

**Why it happens:**
The Central Portal's namespace verification is a one-time per-namespace step that happens during account setup. Developers who skip or rush setup and go straight to publishing hit this at upload time.

**How to avoid:**
1. Complete the Central Portal namespace verification for `io.github.sztheory` before writing a single line of publish config. The process requires creating a temporary public GitHub repository whose name matches the verification token Sonatype provides.
2. Use `io.github.sztheory` (all lowercase) as the Maven `groupId` — Maven GAV is case-sensitive and `szTheory` vs `sztheory` would be a different namespace.
3. Verify the namespace is listed as "verified" in the Central Portal dashboard before attempting any upload.

**Warning signs:**
- Central Portal account exists but namespace verification step was never completed.
- `build.gradle.kts` has `namespace = "dev.crosswake.shell.core"` (the Android namespace) — this is the application namespace, NOT the Maven groupId. They must be different: Maven groupId should be `io.github.sztheory`.
- Upload rejects with namespace/ownership error rather than POM validation error.

**Phase to address:** Phase A (native publish-config). Namespace verification is a prerequisite to all Android publish work.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Keep `exactVersion` in iOS template | Reproducible adopter builds | Adopter can't receive patch/minor fixes without regenerating shell | Never — switch to `upToNextMajorVersion` |
| Skip dry-run publish in CI | Faster first publish | Botched release burns a Maven Central version permanently | Never |
| Gate native publish on `release: published` event | Cleaner separation of concerns | GITHUB_TOKEN loop-prevention means the job never fires | Never — use `needs:` in the same workflow |
| Keep version literals in templates | Simpler template code | Version drifts from Hex axis silently; adopter gets ABI mismatch | Never for release coordinates |
| Shallow clone (`fetch-depth: 1`) in subtree-push CI job | Faster CI clone | splitsh-lite produces broken commit trees without full history | Never for the subtree-push job |
| Run clean-room proof with `--local` | Proof lane works without publishing | Proves nothing about the published install path | Never as the acceptance gate |
| Leave `release-please-config.json` single-package | No config change needed now | Hex and native versions advance independently; generated code references non-existent native versions | Never once native publishing is wired |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Maven Central Portal | Not uploading sources+javadoc jars — upload silently accepts but reviewer rejects | Vanniktech maven-publish auto-generates them; verify `*-sources.jar` and `*-javadoc.jar` are in the local Maven layout before publishing |
| Maven Central Portal | Using `-SNAPSHOT` suffix on a release version | Strip `-SNAPSHOT`; releases must use plain semver. release-please elixir type produces clean versions |
| SwiftPM mirror repo | Pushing to mirror on every commit | Only push tagged versions to mirror; continuous pushes produce unversioned commits that SPM cannot resolve by version |
| release-please linked-versions | Adding iOS `Package.swift` to `extra-files` | `Package.swift` has no version field — version comes from git tag. Only annotate `build.gradle.kts` and `mix.exs` in extra-files |
| Central Portal GPG | Using a subkey instead of the primary key ID in CI | Export the subkey and primary — Central Portal verifies the primary key is on a keyserver |
| splitsh-lite | Missing `--scratch` flag causes history bleed between runs | Use `splitsh-lite --prefix packages/crosswake-shell-core-ios --scratch` in CI to ensure clean splits |

---

## "Looks Done But Isn't" Checklist

- [ ] **Native publish configured:** The presence of `build.gradle.kts` does not mean publish config is present — verify `group`, `version`, Vanniktech plugin, POM block, and signing config are all declared.
- [ ] **iOS mirror repo:** A `Package.swift` that compiles locally is not a published package — the dedicated mirror repo must exist, have at least one semver tag, and be resolvable by a clean `swift package resolve` invocation outside the monorepo.
- [ ] **Generator templates rewired:** The generator running without error is not proof the coordinates are correct — check the rendered output for the exact URL, groupId, and version string before any clean-room test.
- [ ] **Version derived at generate-time:** `Application.spec(:crosswake)[:vsn]` returning a value in development does not guarantee it returns the correct value when the Hex package is installed by an adopter — test from a fresh `mix archive.install hex crosswake` environment.
- [ ] **Clean-room proof passes:** An in-monorepo build passing `--local` does not prove the published dep path — the clean-room lane must scaffold outside the repo and prove `swift build` + `gradle build` succeed against published artifacts.
- [ ] **GPG key on keyserver:** `gpg --list-keys` showing the key locally does not mean it is on a keyserver — run `gpg --keyserver keyserver.ubuntu.com --recv-keys <KEY_ID>` from a machine that never saw the key to verify.
- [ ] **release-please manifest covers all packages:** `release-please` completing without error on the current single-package config does not mean all three artifacts advance in lockstep — verify `release-please-config.json` packages block and `linked-versions` plugin are both present.
- [ ] **Lockstep verified end-to-end:** A CI run completing does not mean the three version coordinates match — add an explicit assertion step that compares `mix.exs @version`, `build.gradle.kts version`, and the latest mirror repo tag.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Burned Maven Central version | LOW-MEDIUM | Publish corrected artifact under the next patch version; document the skipped version in CHANGELOG; tell adopters to use the new version |
| Wrong iOS mirror tag | LOW (if caught before adoption) | Delete the GitHub release + tag (before any adopter resolves it); push corrected tag; HIGH if adopters have already locked the hash — publish new version |
| Wrong coordinates in generated code | MEDIUM | Push a patch release with corrected templates; adopters re-run `gen.shell` but the "scaffold once" posture means they may have edited the generated files — document migration steps |
| GPG key not on keyserver | LOW | Push the public key to keyserver; re-run the publish CI job |
| GITHUB_TOKEN not triggering native publish | LOW | Move native publish jobs into the release-please workflow using `needs:` pattern; no published artifact is lost, the job just never ran |
| splitsh shallow clone producing broken mirror | MEDIUM | Re-run the split with `fetch-depth: 0`; force-push to the mirror tag only if no adopter has resolved it yet |
| Wrong namespace verification | LOW (before first publish) | Complete the Central Portal verification flow; HIGH if a publish was attempted under an unverified namespace — contact Sonatype support |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Burned Maven Central version | Phase A: publish-config | Dry-run CI step must pass and be reviewed before real publish |
| GPG key not on keyserver | Phase A: publish-config | CI pre-publish step verifies key is reachable on keyserver |
| Relative-path / broken URL in generated code | Phase B: template rewire | Clean-room proof lane scaffolds outside monorepo and confirms `swift build` + `gradle build` succeed |
| Hardcoded satellite version (drift) | Phase B: template rewire | Doctor "published-dep parity" check asserts generated version = `Application.spec(:crosswake)[:vsn]` |
| SwiftPM subdir not consumable | Phase A: publish-config | Mirror repo exists with at least one semver tag; `swift package resolve` succeeds against mirror URL |
| SwiftPM product name mismatch | Phase A (mirror setup) + Phase B (template verification) | CI check on mirror repo verifies `Package.swift` product name matches template expectation |
| GITHUB_TOKEN not triggering downstream | Phase A: CI wiring | Native publish jobs run as `needs:` in release-please workflow; verify in first release dry-run |
| release-please not covering all packages | Phase A: publish-config | `release-please-config.json` has all three packages; dry-run PR shows three version bumps |
| Branch-pinning SwiftPM dep | Phase B: template rewire | Generated `project.pbxproj` uses `upToNextMajorVersion`; template test asserts `kind = upToNextMajorVersion` |
| Clean-room proof inside monorepo | Phase B: acceptance gate | Proof lane runs in `$RUNNER_TEMP`, no `packages/` in scope, `CROSSWAKE_PHASE5_NATIVE_PROOFS: 1` |
| Re-tagging existing SwiftPM version | Phase A: CI design | Mirror push job has no `--force`; mirror repo has tag protection; job only runs on `release_created` |
| Wrong Maven namespace | Phase A: publish-config | Central Portal namespace dashboard shows `io.github.sztheory` as verified before any publish config is written |

---

## Sources

- Maven Central Immutability Policy: https://central.sonatype.org/publish/requirements/immutability/
- Maven Central POM Requirements: https://central.sonatype.org/publish/requirements/
- OSSRH Sunset (June 30 2025) confirmed in search results: https://so.nwalsh.com/2025/06/01-maven
- release-please-action issue #1000 (GITHUB_TOKEN downstream trigger): https://github.com/googleapis/release-please-action/issues/1000
- release-please manifest mode docs: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md
- SwiftPM SE-0292 (root-manifest constraint): https://github.com/swiftlang/swift-evolution/blob/main/proposals/0145-package-manager-version-pinning.md
- splitsh-lite: https://github.com/splitsh/lite
- Capacitor SPM branch-pinning issue #7735 (referenced in pre-gathered research)
- Capacitor relative-path issue #6040 (referenced in pre-gathered research)
- LiveView Native satellite version drift (referenced in pre-gathered research)
- Repo-local evidence: `priv/templates/crosswake/shell/android/app/build.gradle.eex` line 54, `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex` line 56, `packages/crosswake-shell-core-android/build.gradle.kts`, `packages/crosswake-shell-core-ios/Package.swift`, `release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release-please.yml`

---
*Pitfalls research for: Multi-language publishing + generator rewiring (v11.0 Release & Distribution Truth)*
*Researched: 2026-06-14*
