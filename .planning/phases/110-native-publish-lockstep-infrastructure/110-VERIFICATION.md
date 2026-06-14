---
phase: 110-native-publish-lockstep-infrastructure
verified: 2026-06-14T21:00:00Z
status: human_needed
score: 8/8 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 6/8
  gaps_closed:
    - "The ios-mirror and android-publish CI jobs live inside release-please.yml under needs: release-please + if: releases_created (commit 61fb9b1)"
    - "The Android POM license matches the repository license (Apache-2.0) (commit 9c86332)"
  gaps_remaining: []
  regressions: []
human_verification:
  - test: "Run the android-publish-fire-drill workflow_dispatch lane after secrets are provisioned per SETUP.md"
    expected: "Preflight passes (all 8 secrets present), local publish produces AAR + sources.jar + javadoc.jar + POM + .asc files in ~/.m2, POM fields validated, Central Portal upload reaches VALIDATED state, deployment is successfully DROPped via DELETE API call, fire-drill reports 'Version coordinate is FREE'"
    why_human: "Requires provisioned credentials (8 GitHub Actions secrets), a real Sonatype account, a GPG key on keyservers, and network access to Central Portal. Cannot be verified by static analysis."
  - test: "Run the lockstep-truth workflow_dispatch lane"
    expected: "Job completes with 'LOCKSTEP OK: all coordinates agree on version 0.1.0' — the four version coordinates (mix.exs, build.gradle.kts, manifest., manifest android) are mutually consistent"
    why_human: "Requires a GitHub Actions runner to dispatch and observe job output. The assertion logic is verified locally (all four agree on 0.1.0), but the CI job itself has not run."
  - test: "Verify GPG public key is discoverable on keys.openpgp.org and keyserver.ubuntu.com"
    expected: "gpg --keyserver keys.openpgp.org --recv-keys <KEYID> returns 'imported: 1' from a clean environment"
    why_human: "Requires a human to run SETUP.md sections 3-4: generate the GPG keypair, export, upload to both keyservers, verify receipt. Cannot be checked from code."
  - test: "Verify Sonatype namespace io.github.sztheather is active in Central Portal"
    expected: "Login to central.sonatype.com confirms io.github.sztheather namespace is verified and active"
    why_human: "No status API exists for Central Portal namespace verification. Documented as a known preflight blind spot in SETUP.md."
---

# Phase 110: Native Publish & Lockstep Infrastructure Verification Report

**Phase Goal:** Published native cores exist at correct coordinates and lockstep versioning ensures one release bumps all three registries
**Verified:** 2026-06-14T21:00:00Z
**Status:** human_needed
**Re-verification:** Yes — after gap closure (commits 61fb9b1 and 9c86332)

## Critical Scoping Context Applied

Per the load-bearing scope decision D-01: no real publish happens in Phase 110. ROADMAP Success Criteria #1-4 require runtime/human actions (clean-room swift package resolve, Maven Central visibility, GPG keyserver presence, live release PR) and are classified as `human_needed` / deferred to Phase 111 where the real cut happens. Verification focuses on what Phase 110 ACTUALLY delivers: the static configuration, CI job wiring, runbook, and fire-drill lane.

## Re-Verification Summary

Two blockers from the initial `gaps_found` verdict were fixed in commits 61fb9b1 and 9c86332. Both are now VERIFIED.

| Gap | Commit | Fix | Status |
|-----|--------|-----|--------|
| Wrong output name on publish gates (LOCK-02 / SC#5) | 61fb9b1 | `releases_created` forwarded in outputs block; all three `if:` gates updated; iOS tag uses clean `v${VERSION}` | CLOSED |
| Wrong Android POM license (MIT vs Apache-2.0) | 9c86332 | `name.set("The Apache License, Version 2.0")`, URL updated, `distribution.set("repo")` added | CLOSED |

All 8 must-haves are now VERIFIED. Status advances from `gaps_found` to `human_needed` because the runtime/human items (SC#1-4 per D-01) remain outstanding.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | mix.exs @version equals 0.1.0 with x-release-please-version annotation | VERIFIED | Line 4: `@version "0.1.0" # x-release-please-version` — confirmed by grep |
| 2 | release-please groups Hex + iOS + Android under one linked-versions component group | VERIFIED | release-please-config.json: plugins[0].type=linked-versions, components=["hex","ios-core","android-core"] |
| 3 | The release-please manifest tracks all three packages baselined at 0.1.0 | VERIFIED | .release-please-manifest.json: {".":"0.1.0", "packages/crosswake-shell-core-ios":"0.1.0", "packages/crosswake-shell-core-android":"0.1.0"} |
| 4 | The Android library declares a complete, signed Maven Central publish config under io.github.sztheather | VERIFIED | build.gradle.kts: Vanniktech 0.31.0 plugin, publishToMavenCentral(CENTRAL_PORTAL, automaticRelease=false), signAllPublications(), coordinates("io.github.sztheather",...), all 6 POM fields present |
| 5 | The Android publish stops at VALIDATED (automaticRelease=false), never auto-publishing | VERIFIED | build.gradle.kts line 41: `publishToMavenCentral(SonatypeHost.CENTRAL_PORTAL, automaticRelease = false)`. No publishAndReleaseToMavenCentral anywhere. |
| 6 | A human operator can follow SETUP.md to provision every credential the publish path needs | VERIFIED | SETUP.md: 375 lines, all 8 secret names present, GPG footgun-safe command, empty mirror repo creation, tag ruleset with non_fast_forward+deletion, documented preflight blind spots |
| 7 | The ios-mirror and android-publish CI jobs live inside release-please.yml under needs: release-please + if: releases_created | VERIFIED | `releases_created: ${{ steps.release.outputs.releases_created }}` in outputs block (line 38). All three publish jobs (publish-hex line 61, publish-ios-core line 135, publish-android-core line 172) gate on `releases_created == 'true'`. Singular `release_created` appears only in a comment. iOS mirror tag uses `v${VERSION}` from `version` output, not component-prefixed `tag_name`. |
| 8 | The Android POM license matches the repository license (Apache-2.0) | VERIFIED | build.gradle.kts: `name.set("The Apache License, Version 2.0")`, `url.set("https://www.apache.org/licenses/LICENSE-2.0.txt")`, `distribution.set("repo")`. Matches repo LICENSE (Apache License 2.0) and mix.exs line 72 (licenses: ["Apache-2.0"]). |

**Score:** 8/8 truths verified

### Deferred Items

Items not yet met but explicitly addressed in later milestone phases or classified as human/runtime checks per D-01.

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Running swift package resolve against github.com/szTheory/crosswake-shell-core-ios with a semver tag resolves (SC#1) | Phase 111 + human provisioning | D-01: first real tag is Phase 111. Phase 110 equivalent: splitsh produces a resolvable tree; publish-ios-core job wiring is correct. |
| 2 | io.github.sztheather:crosswake-shell-core-android:0.1.2 visible in Maven Central (SC#2) | Phase 111 | Real 0.1.2 cut is Phase 111. Phase 110 proves the path via validated-upload→drop fire-drill. |
| 3 | Merging a release PR causes a single release-please run to advance all three registries (SC#4) | Phase 111 | D-01: on-demand lockstep-truth assertion and fire-drill lane are the Phase 110 equivalent. SC#4 requires a live release. |

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `mix.exs` | @version with x-release-please-version annotation | VERIFIED | `@version "0.1.0" # x-release-please-version` at line 4 |
| `release-please-config.json` | linked-versions plugin + 3 component-keyed packages + release-as pin | VERIFIED | All assertions pass: linked-versions, hex/ios-core/android-core components, release-as 0.1.2 on . package |
| `.release-please-manifest.json` | Three-package manifest baselined at 0.1.0 | VERIFIED | All three keys at 0.1.0 |
| `packages/crosswake-shell-core-android/build.gradle.kts` | Vanniktech publish block, complete POM, version annotation, Apache-2.0 license | VERIFIED | Structure complete and wired. License corrected to Apache-2.0 (commit 9c86332). |
| `SETUP.md` | One-time provisioning runbook, 8 named secrets, GPG footgun-safe command | VERIFIED | 375 lines, all 8 secrets named, footgun-safe GPG command, empty mirror repo, ruleset, preflight blind spots documented |
| `.github/workflows/release-please.yml` | publish-ios-core, publish-android-core, android-publish-fire-drill, lockstep-truth, releases_created gate | VERIFIED | All 4 jobs exist. All three publish jobs gate on `releases_created == 'true'` (commit 61fb9b1). iOS tag uses clean `v${VERSION}`. |

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| release-please-config.json | build.gradle.kts | extra-files generic updater, x-release-please-version annotation | VERIFIED | Path `packages/crosswake-shell-core-android/build.gradle.kts` in extra-files; `version = "0.1.0" // x-release-please-version` at line 8 |
| release-please-config.json | mix.exs | extra-files ["mix.exs"], x-release-please-version annotation | VERIFIED | `"extra-files": ["mix.exs"]` on . package; `@version "0.1.0" # x-release-please-version` in mix.exs |
| publish-ios-core / publish-android-core | release-please job outputs | needs: release-please + if: releases_created == 'true' | VERIFIED | Commit 61fb9b1: outputs block line 38 forwards `releases_created`; all three publish jobs use the plural gate. Singular `release_created` is in a comment only. |
| publish-ios-core | iOS mirror repo | splitsh-lite v2.0.0 + v${VERSION} tag via MIRROR_PUSH_TOKEN | VERIFIED | Tag derived from `version` output (not component-prefixed `tag_name`), producing SwiftPM-resolvable `v0.1.2` form. |
| android-publish-fire-drill | Central Portal deployments API | validated-upload then DELETE /api/v1/publisher/deployment/{id} | VERIFIED (structural) | publisher/deployment endpoint present, VALIDATED poll and FAILED retain logic present, curl -X DELETE confirmed. Actual network execution is human/CI verification. |
| build.gradle.kts mavenPublishing | io.github.sztheather:crosswake-shell-core-android | coordinates() call | VERIFIED | `coordinates("io.github.sztheather", "crosswake-shell-core-android", version.toString())` at line 44 |

## Data-Flow Trace (Level 4)

Not applicable — this phase delivers CI configuration, a runbook, and Gradle/Elixir publish config. No dynamic data rendering components.

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Lockstep assertion: all four version coordinates agree | Python3 parse of mix.exs, build.gradle.kts, manifest (locally) | All four return 0.1.0 — LOCKSTEP OK | PASS |
| release-please-config.json JSON validity and structure | Python3 assertions against all required keys | All assertions pass | PASS |
| .release-please-manifest.json baseline correctness | Python3 assertions | All three keys at 0.1.0 | PASS |
| build.gradle.kts: no auto-publish path | grep for publishAndReleaseToMavenCentral, automaticRelease=true | Both absent | PASS |
| release-please.yml: releases_created forwarded in outputs | grep for releases_created in outputs block | Line 38: `releases_created: ${{ steps.release.outputs.releases_created }}` | PASS |
| release-please.yml: all 3 publish jobs gate on releases_created | grep for if: releases_created | Lines 61, 135, 172: all three use plural gate | PASS |
| release-please.yml: no residual singular release_created gate | grep for release_created excluding releases_created | Only appears in comment (line 35) | PASS |
| iOS mirror tag uses v${VERSION} not component tag_name | grep for tag_name vs version in push step | VERSION env var uses `version` output; tag is `v${VERSION}` | PASS |
| build.gradle.kts: Apache-2.0 license | grep for "The Apache License, Version 2.0" | Found at line 54 | PASS |
| build.gradle.kts: Apache license URL | grep for apache.org/licenses/LICENSE-2.0 | Found at line 55 | PASS |
| build.gradle.kts: distribution.set("repo") | grep for distribution | Found at line 56 | PASS |
| License cross-consistency: LICENSE file, mix.exs, build.gradle.kts | Head LICENSE + grep mix.exs + grep build.gradle.kts | All three: Apache-2.0 | PASS |
| release-please.yml: no --force on mirror push | grep for --force | Absent (local.hex --force is unrelated) | PASS |
| release-please.yml: no --scratch on splitsh | grep for --scratch | Absent | PASS |
| SETUP.md: all 8 secret names present | Shell loop grep | All 8 found | PASS |

## Probe Execution

No probe scripts exist in `scripts/*/tests/probe-*.sh` for this phase. Step 7c: SKIPPED (no probe scripts; CI-only workflow phase).

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| PUB-01 | 110-03 | iOS shell core published to github.com/szTheory/crosswake-shell-core-ios with semver tags | VERIFIED (structural) | publish-ios-core job: splitsh-lite v2.0.0, fetch-depth:0, no --force, tag is `v${VERSION}` (clean SwiftPM-resolvable form). Gates on `releases_created == 'true'` (commit 61fb9b1). Real push is human/Phase 111. |
| PUB-02 | 110-01, 110-03 | Android shell core published to Maven Central under io.github.sztheather with complete signed POM | VERIFIED (structural) | Vanniktech 0.31.0, USER_MANAGED mode, all six POM fields present, signAllPublications, coordinates correct, license Apache-2.0 (commit 9c86332). publish-android-core gates on `releases_created == 'true'`. Real upload is human/Phase 111. |
| PUB-03 | 110-01, 110-02, 110-03 | Publishing prerequisites established and recorded | VERIFIED (config) / human_needed (execution) | SETUP.md records all 8 secrets + GPG + namespace + runbook. fire-drill lane present with preflight, local-publish assertions, validated-upload→drop. Fire-drill execution is human/CI verification. |
| LOCK-01 | 110-01 | One version via release-please manifest mode + linked-versions | VERIFIED | release-please-config.json: linked-versions plugin, 3 components, manifest baseline at 0.1.0 for all three packages |
| LOCK-02 | 110-03 | Native publish CI jobs triggered by release-please release within same workflow using releases_created | VERIFIED | Commit 61fb9b1: outputs block now forwards `releases_created`; all three publish jobs gate on `needs.release-please.outputs.releases_created == 'true'`. Exact plural form matches REQUIREMENTS.md LOCK-02 and ROADMAP SC#5. |

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `.github/workflows/release-please.yml` | 288-303 | Fire-drill drops deployments[0] from filtered VALIDATED list without correlating to this run's upload ID | WARNING | Can accidentally DROP an unrelated concurrent VALIDATED deployment (CR-03 from code review). Not a blocker: concurrent deploys are unlikely in practice; noted for Phase 111 hardening. |
| `.github/workflows/release-please.yml` | 148-156 | iOS mirror push step lacks set -euo pipefail; git remote add not idempotent | WARNING | A failed push or retry would continue silently; may fail on second release (main already has history). Not a blocker for Phase 110 since no real push occurs here. |
| `.github/workflows/release-please.yml` | 24-26 | cancel-in-progress: true scoped to entire workflow | WARNING | A push to main mid-publish could cancel an in-progress Hex or Android publish. Acceptable for Phase 110; recommend scoping for Phase 111. |
| `.github/workflows/release-please.yml` | 139-141 | splitsh-lite binary downloaded without SHA-256 checksum verification | WARNING | Supply-chain gap; compromised release asset runs with MIRROR_PUSH_TOKEN access. Noted for Phase 111 hardening. |

No blockers remain in anti-patterns. All four items are carry-forward warnings from initial verification, unchanged by the two gap-closure commits.

## Human Verification Required

### 1. Android Publish Fire-Drill (workflow_dispatch)

**Test:** After provisioning all 8 secrets per SETUP.md, trigger the `android-publish-fire-drill` job via workflow_dispatch on the `main` branch.
**Expected:** Preflight passes (all 8 secrets present and non-empty). Local publish to ~/.m2 produces crosswake-shell-core-android-0.1.0.aar, crosswake-shell-core-android-0.1.0.pom, sources.jar, javadoc.jar, and .asc signatures for each. POM contains all 6 fields with correct Apache-2.0 license. Central Portal upload reaches VALIDATED state. Deployment is DROPped via DELETE. Final echo confirms "Version coordinate is FREE."
**Why human:** Requires provisioned GitHub Actions secrets, active Sonatype account, GPG key on keyservers, and live Central Portal access.

### 2. Lockstep Truth CI Lane (workflow_dispatch)

**Test:** Trigger the `lockstep-truth` job via workflow_dispatch.
**Expected:** Job prints all four coordinates (mix.exs, build.gradle.kts, manifest., manifest android) and exits with "LOCKSTEP OK: all coordinates agree on version 0.1.0"
**Why human:** Requires GitHub Actions runner; local simulation confirms 0.1.0 agreement but actual CI job has not been dispatched.

### 3. GPG Key on Public Keyservers

**Test:** Run `gpg --keyserver keyserver.ubuntu.com --recv-keys <KEYID>` and `gpg --keyserver keys.openpgp.org --recv-keys <KEYID>` from a clean environment.
**Expected:** Both commands return "imported: 1"
**Why human:** Requires human to execute SETUP.md sections 3-4 (GPG keygen, upload to both keyservers, verify). No code to inspect.

### 4. Sonatype Namespace Verification

**Test:** Log in to central.sonatype.com and confirm io.github.sztheather namespace status.
**Expected:** Namespace shows as verified in the Central Portal UI.
**Why human:** No status API exists for Central Portal namespace verification. Documented as a known preflight blind spot in SETUP.md.

## Gaps Summary

No code gaps remain. Both blockers from the initial verification are resolved:

**CLOSED — BLOCKER 1 (commit 61fb9b1): Wrong output name on publish gates (LOCK-02 / SC#5)**

The `release-please` job's `outputs:` block now forwards `releases_created: ${{ steps.release.outputs.releases_created }}` (line 38). All three publish jobs (`publish-hex` line 61, `publish-ios-core` line 135, `publish-android-core` line 172) gate on `needs.release-please.outputs.releases_created == 'true'`. The singular `release_created` appears only in a comment. The iOS mirror tag was also corrected from the component-prefixed `tag_name` (which would be `hex-v0.1.2`, not SwiftPM-resolvable) to `v${VERSION}` derived from the plain `version` output.

**CLOSED — BLOCKER 2 (commit 9c86332): Wrong license in Android POM (PUB-02 correctness)**

The Android POM now declares `The Apache License, Version 2.0` with URL `https://www.apache.org/licenses/LICENSE-2.0.txt` and `distribution.set("repo")`. This matches the repo LICENSE file (Apache License 2.0) and mix.exs (licenses: ["Apache-2.0"]). All three license declarations are now mutually consistent.

The remaining `human_needed` items are structurally out-of-scope for Phase 110 per D-01: they require live credential provisioning, CI runners, keyserver uploads, and/or Central Portal account access. They are not code gaps.

---

_Verified: 2026-06-14T21:00:00Z_
_Re-verification: Yes — after gap closure (commits 61fb9b1, 9c86332)_
_Verifier: Claude (gsd-verifier)_
