---
phase: 110-native-publish-lockstep-infrastructure
verified: 2026-06-14T20:00:00Z
status: gaps_found
score: 6/8 must-haves verified
overrides_applied: 0
gaps:
  - truth: "The ios-mirror and android-publish CI jobs live inside release-please.yml under needs: release-please + if: releases_created"
    status: failed
    reason: "Workflow gates on singular release_created output (needs.release-please.outputs.release_created == 'true') — but manifest mode with linked-versions emits the PLURAL aggregate output releases_created. The singular top-level output is empty/undefined in multi-package manifest mode. This means publish-hex, publish-ios-core, and publish-android-core are ALL silently skipped on every real release. The release-please job only exposes [release_created, tag_name, version] in its outputs block — releases_created is never forwarded. REQUIREMENTS.md LOCK-02 and ROADMAP Success Criterion #5 both specify releases_created (plural) explicitly."
    artifacts:
      - path: ".github/workflows/release-please.yml"
        issue: "Line 33: outputs only release_created (singular). Lines 54, 128, 161: if: gate uses release_created == 'true'. The publish path silently never fires in manifest+linked-versions mode."
    missing:
      - "Add releases_created: ${{ steps.release.outputs.releases_created }} to the release-please job outputs block"
      - "Change all three publish job if: conditions from release_created == 'true' to releases_created == 'true'"
      - "Verify exact output key names against googleapis/release-please-action v4.1.3 for the path-scoped tag/version outputs"
  - truth: "The Android library POM declares the correct license (Apache-2.0, matching the repo LICENSE and mix.exs)"
    status: failed
    reason: "build.gradle.kts POM declares MIT License (name.set('MIT License'), url 'https://opensource.org/licenses/MIT'). The repository LICENSE file is Apache-2.0. mix.exs line 72 publishes to Hex as licenses: ['Apache-2.0']. Publishing to Maven Central under MIT misrepresents the license and is immutable once PUBLISHED. The fire-drill POM check only greps for presence of a <license tag, not the correct license, so the self-test does not catch this. The six POM fields ARE structurally present (PUB-03 completeness satisfied), but license content is wrong."
    artifacts:
      - path: "packages/crosswake-shell-core-android/build.gradle.kts"
        issue: "Lines 54-57: name.set('MIT License') / url.set('https://opensource.org/licenses/MIT'). Should be Apache License, Version 2.0 to match LICENSE file and Hex publish metadata."
    missing:
      - "Change name.set to 'The Apache License, Version 2.0'"
      - "Change url.set to 'https://www.apache.org/licenses/LICENSE-2.0.txt'"
      - "Change distribution.set to 'repo' (standard Maven distribution value)"
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
  - test: "Verify Sonatype namespace io.github.sztheory is active in Central Portal"
    expected: "Login to central.sonatype.com confirms io.github.sztheory namespace is verified and active"
    why_human: "No status API exists for Central Portal namespace verification. Documented as a known preflight blind spot in SETUP.md."
---

# Phase 110: Native Publish & Lockstep Infrastructure Verification Report

**Phase Goal:** Published native cores exist at correct coordinates and lockstep versioning ensures one release bumps all three registries
**Verified:** 2026-06-14
**Status:** gaps_found
**Re-verification:** No — initial verification

## Critical Scoping Context Applied

Per the load-bearing scope decision D-01: no real publish happens in Phase 110. ROADMAP Success Criteria #1-4 require runtime/human actions (clean-room swift package resolve, Maven Central visibility, GPG keyserver presence, live release PR) and are classified as `human_needed` / deferred to Phase 111 where the real cut happens. Verification focuses on what Phase 110 ACTUALLY delivers: the static configuration, CI job wiring, runbook, and fire-drill lane.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | mix.exs @version equals 0.1.0 with x-release-please-version annotation | VERIFIED | Line 4: `@version "0.1.0" # x-release-please-version` — confirmed by grep |
| 2 | release-please groups Hex + iOS + Android under one linked-versions component group | VERIFIED | release-please-config.json: plugins[0].type=linked-versions, components=["hex","ios-core","android-core"] — Python assertion passes |
| 3 | The release-please manifest tracks all three packages baselined at 0.1.0 | VERIFIED | .release-please-manifest.json: {".":"0.1.0", "packages/crosswake-shell-core-ios":"0.1.0", "packages/crosswake-shell-core-android":"0.1.0"} |
| 4 | The Android library declares a complete, signed Maven Central publish config under io.github.sztheory | VERIFIED | build.gradle.kts: Vanniktech 0.31.0 plugin, publishToMavenCentral(CENTRAL_PORTAL, automaticRelease=false), signAllPublications(), coordinates("io.github.sztheory",...), all 6 POM fields structurally present |
| 5 | The Android publish stops at VALIDATED (automaticRelease=false), never auto-publishing | VERIFIED | build.gradle.kts line 41: `publishToMavenCentral(SonatypeHost.CENTRAL_PORTAL, automaticRelease = false)`. No publishAndReleaseToMavenCentral anywhere. |
| 6 | A human operator can follow SETUP.md to provision every credential the publish path needs | VERIFIED | SETUP.md: 375 lines, all 8 secret names present, GPG footgun-safe command present, empty mirror repo creation, tag ruleset with non_fast_forward+deletion, documented preflight blind spots |
| 7 | The ios-mirror and android-publish CI jobs live inside release-please.yml under needs: release-please + if: releases_created | FAILED — BLOCKER | Jobs exist and are structurally wired under needs: release-please, but gate uses singular `release_created` not plural `releases_created`. REQUIREMENTS.md LOCK-02 and ROADMAP SC#5 both require `releases_created`. In manifest+linked-versions mode, googleapis/release-please-action@v4 emits the plural aggregate; the singular output is empty. All three publish jobs silently skip. SETUP.md line 245 even says `releases_created` while the workflow uses `release_created`. |
| 8 | The Android POM license matches the repository license (Apache-2.0) | FAILED — BLOCKER | build.gradle.kts POM declares MIT License. The repo LICENSE file is Apache-2.0; mix.exs declares licenses: ["Apache-2.0"]. Immutable once PUBLISHED to Maven Central. The fire-drill POM completeness check passes (grep finds `<license`) but does not catch wrong license content. |

**Score:** 6/8 truths verified

### Deferred Items

Items not yet met but explicitly addressed in later milestone phases or classified as human/runtime checks per D-05.

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Running swift package resolve against github.com/szTheory/crosswake-shell-core-ios with a semver tag resolves (SC#1) | Phase 111 + human provisioning | D-05: "within 110 the equivalent proof is: splitsh produces a resolvable tree pushed to the mirror" — first real tag is Phase 111 |
| 2 | io.github.sztheory:crosswake-shell-core-android:0.1.2 visible in Maven Central (SC#2) | Phase 111 | The real 0.1.2 cut is Phase 111. Phase 110 proves the publish path via validated-upload→drop. |
| 3 | Merging a release PR causes a single release-please run to advance all three registries (SC#4) | Phase 111 | D-05: the on-demand lockstep-truth assertion and fire-drill lane are the Phase 110 equivalent |

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `mix.exs` | Reverted @version with x-release-please-version annotation | VERIFIED | `@version "0.1.0" # x-release-please-version` at line 4 |
| `release-please-config.json` | linked-versions plugin + 3 component-keyed packages + release-as pin | VERIFIED | All assertions pass: linked-versions, hex/ios-core/android-core components, release-as 0.1.2 on . package, Package.swift absent from extra-files |
| `.release-please-manifest.json` | Three-package manifest baselined at 0.1.0 | VERIFIED | All three keys at 0.1.0 |
| `packages/crosswake-shell-core-android/build.gradle.kts` | Vanniktech publish block, complete POM, version annotation, Apache-2.0 license | PARTIAL | Structure complete and wired. License is MIT instead of Apache-2.0 — BLOCKER |
| `SETUP.md` | One-time provisioning runbook, 8 named secrets, GPG footgun-safe command | VERIFIED | 375 lines, all 8 secrets named, footgun-safe GPG command, empty mirror repo, ruleset, preflight blind spots documented |
| `.github/workflows/release-please.yml` | publish-ios-core, publish-android-core, android-publish-fire-drill, lockstep-truth | PARTIAL | All 4 jobs exist. publish-ios-core and publish-android-core gate on wrong output name (release_created vs releases_created) — BLOCKER |

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| release-please-config.json | build.gradle.kts | extra-files generic updater, x-release-please-version annotation | VERIFIED | Path `packages/crosswake-shell-core-android/build.gradle.kts` in extra-files; `version = "0.1.0" // x-release-please-version` at line 8 |
| release-please-config.json | mix.exs | extra-files ["mix.exs"], x-release-please-version annotation | VERIFIED | `"extra-files": ["mix.exs"]` on . package; `@version "0.1.0" # x-release-please-version` in mix.exs |
| publish-ios-core / publish-android-core | release-please job outputs | needs: release-please + if: release_created == 'true' | FAILED — BLOCKER | Gate exists structurally but uses singular output (release_created). Manifest+linked-versions mode emits releases_created (plural). Publish jobs silently skip. LOCK-02 and SC#5 require releases_created. |
| android-publish-fire-drill | Central Portal deployments API | validated-upload then DELETE /api/v1/publisher/deployment/{id} | VERIFIED (structural) | publisher/deployment endpoint present, state=VALIDATED poll and state=FAILED retain logic present, curl -X DELETE confirmed. Actual network execution is human/CI verification. |
| build.gradle.kts mavenPublishing | io.github.sztheory:crosswake-shell-core-android | coordinates() call | VERIFIED | `coordinates("io.github.sztheory", "crosswake-shell-core-android", version.toString())` at line 44 |

## Data-Flow Trace (Level 4)

Not applicable — this phase delivers CI configuration, a runbook, and Gradle/Elixir publish config. No dynamic data rendering components.

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Lockstep assertion: all four version coordinates agree | Python3 parse of mix.exs, build.gradle.kts, manifest (locally) | All four return 0.1.0 — LOCKSTEP OK | PASS |
| release-please-config.json JSON validity and structure | Python3 assertions against all required keys | All assertions pass | PASS |
| .release-please-manifest.json baseline correctness | Python3 assertions | All three keys at 0.1.0 | PASS |
| build.gradle.kts: no auto-publish path | grep for publishAndReleaseToMavenCentral, automaticRelease=true | Both absent | PASS |
| release-please.yml: no --force on mirror push | grep for --force | Absent (local.hex --force is unrelated) | PASS |
| release-please.yml: no --scratch on splitsh | grep for --scratch | Absent | PASS |
| release-please.yml: no release: published listener | grep for on: release | Absent | PASS |
| SETUP.md: all 8 secret names present | Shell loop grep | All 8 found | PASS |
| release-please.yml YAML validity | python3 yaml.safe_load | Valid | PASS |

## Probe Execution

No probe scripts exist in `scripts/*/tests/probe-*.sh` for this phase. Step 7c: SKIPPED (no probe scripts; CI-only workflow phase).

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| PUB-01 | 110-03 | iOS shell core published to github.com/szTheory/crosswake-shell-core-ios with semver tags | PARTIAL — BLOCKER | publish-ios-core job is structurally present and correct (splitsh-lite v2.0.0, fetch-depth:0, no --force, tag_name output). Gate fires on wrong output name (release_created vs releases_created), so the job silently never runs on a release. |
| PUB-02 | 110-01, 110-03 | Android shell core published to Maven Central under io.github.sztheory with complete signed POM | PARTIAL — BLOCKER | Vanniktech 0.31.0, USER_MANAGED mode, all six POM fields present, signAllPublications, coordinates correct. License is MIT instead of Apache-2.0 (immutable once published). publish-android-core job silently never fires (wrong gate output name). |
| PUB-03 | 110-01, 110-02, 110-03 | Publishing prerequisites established and recorded | VERIFIED (config) / human_needed (execution) | SETUP.md records all 8 secrets + GPG + namespace + runbook. fire-drill lane present with preflight, local-publish assertions, validated-upload→drop. Fire-drill execution is human/CI verification. |
| LOCK-01 | 110-01 | One version via release-please manifest mode + linked-versions | VERIFIED | release-please-config.json: linked-versions plugin, 3 components, manifest baseline at 0.1.0 for all three packages |
| LOCK-02 | 110-03 | Native publish CI jobs triggered by release-please release within same workflow using releases_created | FAILED — BLOCKER | REQUIREMENTS.md explicitly specifies `if: releases_created` (plural). Implemented as `release_created` (singular). In manifest+linked-versions mode, the plural aggregate output fires; singular is empty. All three publish jobs are dead gates. |

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `.github/workflows/release-please.yml` | 33, 54, 128, 161 | Uses `release_created` (singular) instead of `releases_created` (plural) for manifest-mode release-please | BLOCKER | publish-hex, publish-ios-core, publish-android-core silently skip on every release |
| `packages/crosswake-shell-core-android/build.gradle.kts` | 54-57 | POM declares MIT License; repo is Apache-2.0 | BLOCKER | Wrong license published to Maven Central (immutable) |
| `.github/workflows/release-please.yml` | 288-303 | Fire-drill drops deployments[0] from filtered list without correlating to this run's upload | WARNING | Can accidentally DROP an unrelated concurrent VALIDATED deployment (CR-03 from code review) |
| `.github/workflows/release-please.yml` | 148-156 | iOS mirror push step lacks set -euo pipefail; git remote add not idempotent | WARNING | A failed push or retry would continue silently; may fail on second release (main already has history) |
| `.github/workflows/release-please.yml` | 24-26 | cancel-in-progress: true scoped to entire workflow | WARNING | A push to main mid-publish could cancel an in-progress Hex or Android publish |
| `.github/workflows/release-please.yml` | 139-141 | splitsh-lite binary downloaded without SHA-256 checksum verification | WARNING | Supply-chain gap; compromised release asset runs with MIRROR_PUSH_TOKEN access |

## Human Verification Required

### 1. Android Publish Fire-Drill (workflow_dispatch)

**Test:** After provisioning all 8 secrets per SETUP.md, trigger the `android-publish-fire-drill` job via workflow_dispatch on the `main` branch.
**Expected:** Preflight passes (all 8 secrets present and non-empty). Local publish to ~/.m2 produces crosswake-shell-core-android-0.1.0.aar, crosswake-shell-core-android-0.1.0.pom, sources.jar, javadoc.jar, and .asc signatures for each. POM contains all 6 fields. Central Portal upload reaches VALIDATED state. Deployment is DROPped via DELETE. Final echo confirms "Version coordinate is FREE."
**Why human:** Requires provisioned GitHub Actions secrets, active Sonatype account, GPG key on keyservers, and live Central Portal access. Note: after fixing BLOCKER CR-02 (license) first.

### 2. Lockstep Truth CI Lane (workflow_dispatch)

**Test:** Trigger the `lockstep-truth` job via workflow_dispatch.
**Expected:** Job prints all four coordinates (mix.exs, build.gradle.kts, manifest., manifest android) and exits with "LOCKSTEP OK: all coordinates agree on version 0.1.0"
**Why human:** Requires GitHub Actions runner; local simulation confirms 0.1.0 agreement but actual CI job has not been dispatched.

### 3. GPG Key on Public Keyservers

**Test:** Run `gpg --keyserver keyserver.ubuntu.com --recv-keys <KEYID>` and `gpg --keyserver keys.openpgp.org --recv-keys <KEYID>` from a clean environment.
**Expected:** Both commands return "imported: 1"
**Why human:** Requires human to execute SETUP.md sections 3-4 (GPG keygen, upload to both keyservers, verify). No code to inspect.

### 4. Sonatype Namespace Verification

**Test:** Log in to central.sonatype.com and confirm io.github.sztheory namespace status.
**Expected:** Namespace shows as verified in the Central Portal UI.
**Why human:** No status API exists for Central Portal namespace verification. Documented as a known preflight blind spot in SETUP.md.

## Gaps Summary

Two genuine correctness blockers prevent the phase goal from being fully achieved:

**BLOCKER 1: Wrong output name on publish gates (LOCK-02 / SC#5 failure)**

The most critical defect. The workflow uses `release_created` (singular) but googleapis/release-please-action@v4 in manifest+linked-versions mode emits `releases_created` (plural) as the aggregate flag. The singular output is empty/undefined. Result: every publish job (`publish-hex`, `publish-ios-core`, `publish-android-core`) has an `if:` condition that evaluates to `'' == 'true'` = false, so all three are silently skipped on every real release. The entire publish path is structurally wired but functionally dead. This directly violates REQUIREMENTS.md LOCK-02 and ROADMAP Success Criterion #5 (both specify `releases_created` explicitly). Note this is a pre-existing bug on `publish-hex` that this phase propagated to the two new jobs; the ROADMAP SC#5 requirement is unambiguous about the plural form.

**BLOCKER 2: Wrong license in Android POM (PUB-02 correctness gap)**

The Android POM declares MIT License but the repository is Apache-2.0 (LICENSE file, mix.exs:72). This is a legal/correctness defect that becomes immutable once the artifact reaches PUBLISHED state on Maven Central. The fire-drill's POM check only asserts presence of a `<license` tag, not the correct license content, so it would pass with the wrong license. Fix before any real fire-drill or publish run.

Both blockers require targeted edits and no architectural changes. The rest of the phase deliverables — the lockstep manifest config, signed Vanniktech publish config, SETUP.md runbook, fire-drill lane structure, and lockstep-truth assertion — are correctly implemented and substantive.

---

_Verified: 2026-06-14_
_Verifier: Claude (gsd-verifier)_
