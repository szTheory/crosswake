---
phase: 110-native-publish-lockstep-infrastructure
plan: "03"
subsystem: release-ci
tags: [github-actions, splitsh-lite, maven-central, ios-mirror, lockstep, fire-drill, workflow_dispatch]
dependency_graph:
  requires:
    - release-please-linked-versions-config  # 110-01: manifest + linked-versions + android publish config
    - publish-credential-runbook             # 110-02: SETUP.md with 8 secret names preflight asserts
  provides:
    - publish-ios-core-job
    - publish-android-core-job
    - android-publish-fire-drill-job
    - lockstep-truth-assertion-job
  affects:
    - .github/workflows/release-please.yml
tech_stack:
  added:
    - "splitsh-lite v2.0.0 (installed via curl from GitHub Releases tarball in CI)"
    - "actions/setup-java@c1e323688fd81a25caa38c78aa6df2d33d3e20d9 # v4.8.0 (SHA-pinned)"
  patterns:
    - "Same-workflow job chaining via needs: release-please + if: release_created (LOCK-02, Pitfall 7 avoidance)"
    - "No --force mirror push — non-fast-forward rejection is the durable tag-immutability guard (D-10)"
    - "No --scratch splitsh-lite — stateless GitHub runners have no BoltDB cache (D-11)"
    - "USER_MANAGED Central Portal mode (automaticRelease=false) — validated-upload then DROP frees coordinate (D-07)"
    - "Dispatch-only fire-drill + lockstep-truth for on-demand proof within Phase 110 (D-08, D-05)"
key_files:
  created: []
  modified:
    - .github/workflows/release-please.yml
decisions:
  - "publish-ios-core checkout omits ref: so splitsh-lite gets the full unfiltered HEAD (the split produces a fresh tree from full history; checking out the tag ref instead would give a detached HEAD of the tag commit which is correct but the step description clarifies: the split references HEAD, not a specific ref)"
  - "fire-drill polls FAILED before VALIDATED on each iteration — FAILED deployments are retained (not dropped) per D-07; a FAILED deployment signals a real publish problem that must be investigated before any DROP"
  - "lockstep-truth asserts all four coordinates (mix.exs, build.gradle.kts, manifest., manifest-android) — the iOS manifest baseline is excluded because the iOS tag is driven by tag_name output, not a version file that release-please updates"
  - "0.1.2 appears only in a comment explaining Phase 111 context — the assertion script is variable-driven, not hardcoded against 0.1.2 (D-05 compliance)"
metrics:
  duration: "~18 minutes"
  completed: "2026-06-14"
  tasks_completed: 3
  files_modified: 1
---

# Phase 110 Plan 03: Native Publish CI + Fire-Drill + Lockstep Truth Summary

**One-liner:** Three CI jobs added to release-please.yml — iOS splitsh mirror + Android Maven Central (release-gated), a permanent dispatch-only Android publish fire-drill (preflight → local asserts → validated-upload → DROP), and a dispatch-only lockstep-truth assertion proving the three configured version coordinates are internally consistent.

## What Was Built

### Task 1: publish-ios-core and publish-android-core release-gated jobs (commit 15125d5)

Added two jobs to `.github/workflows/release-please.yml` after the existing `publish-hex` job:

**publish-ios-core** (`name: Mirror iOS core to split repo`):
- `needs: release-please` + `if: release_created == 'true'` — same LOCK-02 gate as `publish-hex`
- `permissions: { contents: read }` — least privilege
- Checkout with `fetch-depth: 0` (REQUIRED — splitsh-lite needs full history; no `ref:` set so the split runs against full HEAD)
- Installs `splitsh-lite v2.0.0` from the version-pinned GitHub Releases tarball (`lite_linux_amd64.tar.gz`)
- Runs `splitsh-lite --prefix=packages/crosswake-shell-core-ios` — NO `--scratch` (D-11: stateless runners have no BoltDB cache)
- Pushes `${SPLIT_SHA}:refs/heads/main` and `${SPLIT_SHA}:refs/tags/${TAG}` to the mirror — NO `--force` on either push (D-10: non-fast-forward rejection is the durable tag-immutability guard)
- Tag uses `needs.release-please.outputs.tag_name` — same output `publish-hex` uses (D-13 lockstep tag consistency)

**publish-android-core** (`name: Publish Android core to Maven Central`):
- Same `needs`/`if`/`runs-on`/`permissions` gate
- Checkout with `ref: ${{ needs.release-please.outputs.tag_name }}` (builds the exact tagged commit)
- `actions/setup-java@c1e323688fd81a25caa38c78aa6df2d33d3e20d9 # v4.8.0`, java 17, temurin (SHA-pinned per CVE-2025-30066 house standard)
- Five `ORG_GRADLE_PROJECT_*` secrets injected as env vars
- Runs `./gradlew publishToMavenCentral --no-daemon` — USER_MANAGED mode (automaticRelease=false from 110-01 wiring stops at VALIDATED, never auto-publishes)

**Footguns avoided (all verified by the check chain):**
- No `publishAndReleaseToMavenCentral` anywhere
- No `on: release` / `release: published` listener (Pitfall 7)
- No `--force` on mirror push (D-10, Pitfall 11)
- No `--scratch` on splitsh-lite (D-11)

### Task 2: android-publish-fire-drill workflow_dispatch lane (commit 68c237b)

Added `android-publish-fire-drill` job to release-please.yml (`name: Android publish fire-drill (validated-upload -> drop)`):

- Gated ONLY on `github.event_name == 'workflow_dispatch'` — never fires on push or release event
- `permissions: { contents: read }` — least privilege

**Step 3 "Preflight — assert required secrets are set":**
- Maps all 8 secrets as env vars: `HEX_API_KEY`, five `ORG_GRADLE_PROJECT_*`, `MIRROR_PUSH_TOKEN`, `RELEASE_PLEASE_TOKEN`
- `set -euo pipefail`; loops all 8 variable names; if any is empty: prints `MISSING SECRET: $var` (name only, NEVER value) and exits 1 (T-110-12 compliant)

**Step 4 "Local publish to ~/.m2 and assert artifacts":**
- Runs `./gradlew publishToMavenLocal --no-daemon` with the three signing secrets
- Derives `VERSION` from `build.gradle.kts` via `grep '// x-release-please-version'`
- For each of `aar`, `sources.jar`, `javadoc.jar`, `pom`: asserts the artifact exists at `~/.m2/repository/io/github/sztheory/crosswake-shell-core-android/$VERSION/` AND its `.asc` signature exists; missing artifact or signature exits 1
- Asserts all 6 POM mandatory fields: `name`, `description`, `url`, `license`, `developers`, `scm`; missing field exits 1

**Step 5 "Central Portal validated-upload -> DROP":**
- Runs `./gradlew publishToMavenCentral --no-daemon` (USER_MANAGED — stops at VALIDATED per `automaticRelease=false`)
- Polls up to 20 times (15s sleep) for `state=VALIDATED` via `GET /api/v1/publisher/deployments?size=10&state=VALIDATED`
- On each iteration also checks `state=FAILED`: if a FAILED deployment exists → prints "Deployment FAILED — retain for inspection, not dropping" + exits 1 (does NOT drop FAILED deployments — retains for diagnosis per D-07)
- If no VALIDATED after 20 attempts → exits 1 with timeout message
- Once VALIDATED found → `curl -X DELETE ... /api/v1/publisher/deployment/${DEPLOYMENT_ID}` to DROP → frees the version coordinate
- Ends with success echo confirming coordinate is FREE

### Task 3: lockstep-truth dispatch-only assertion job (commit a9daa47)

Added `lockstep-truth` job (`name: Assert lockstep version coordinates match`):

- Gated ONLY on `github.event_name == 'workflow_dispatch'` — on-demand alongside the fire-drill
- Single step "Assert lockstep version coordinates match":
  - Extracts `mix.exs @version` via `grep '# x-release-please-version'`
  - Extracts `build.gradle.kts version` via `grep '// x-release-please-version'`
  - Extracts `manifest .` baseline via `python3` JSON parse of `.release-please-manifest.json`
  - Extracts `manifest packages/crosswake-shell-core-android` baseline
  - Asserts all four are equal; on mismatch: prints all four coordinate values and exits 1
  - On success: echoes the agreed version
  - Does NOT assert against a hardcoded `0.1.2` — purely internal consistency check (D-05: the assertion is about CONFIG correctness at the `0.1.0` baseline per D-04)

## Verification Results

All three tasks' verify chains exit 0:

| Check | Result |
|-------|--------|
| Task 1: YAML structural (needs/if gating, both jobs present) | PASSED |
| Task 1: splitsh-lite --prefix command present | PASSED |
| Task 1: lite_linux_amd64.tar.gz tarball URL | PASSED |
| Task 1: fetch-depth: 0 present | PASSED |
| Task 1: actions/setup-java SHA pinned | PASSED |
| Task 1: publishToMavenCentral --no-daemon | PASSED |
| Task 1: no publishAndReleaseToMavenCentral | PASSED |
| Task 1: no on: release listener | PASSED |
| Task 1: no --force on mirror push | PASSED |
| Task 1: no --scratch on splitsh-lite | PASSED |
| Task 2: dispatch-gated (workflow_dispatch only) | PASSED |
| Task 2: publishToMavenLocal --no-daemon | PASSED |
| Task 2: publisher/deployment API reference | PASSED |
| Task 2: state=VALIDATED poll | PASSED |
| Task 2: state=FAILED retain check | PASSED |
| Task 2: curl -X DELETE drop | PASSED |
| Task 2: MISSING SECRET name-only error | PASSED |
| Task 2: all 6 POM field assertions | PASSED |
| Task 3: lockstep-truth job present, dispatch-gated | PASSED |
| Final: YAML valid (full file parse) | PASSED |

## Deviations from Plan

**1. PATTERNS.md file absent (pre-existing gap from 110-01)**

The plan's `<read_first>` for all three tasks references `110-PATTERNS.md` as the "verbatim target bodies" source. This file does not exist (the 110-01 SUMMARY notes this: "PATTERNS.md referenced in plan does not exist in this phase directory"). The plan was fully executable from the combined content of `110-CONTEXT.md`, `research/STACK.md`, and `research/PITFALLS.md` plus the explicit action specifications in the plan itself. No deviation in output — all job bodies were derived from the authoritative sources.

This is a documentation gap, not a blocking issue. No auto-fix action needed (it's a planning artifact reference, not code).

Otherwise — plan executed exactly as written. All D-level overrides applied:
- D-07: `publishToMavenCentral` not `publishAndReleaseToMavenCentral`; fire-drill uses validated-upload then DROP
- D-08: fire-drill is permanent dispatch-only lane (not a one-off)
- D-10: no `--force` on mirror push
- D-11: no `--scratch` on splitsh-lite

## Known Stubs

None. All CI job logic is concrete and load-bearing:
- Secret names match exactly the 8 names documented in SETUP.md (110-02)
- splitsh-lite tarball URL is version-pinned to v2.0.0
- Portal API endpoints (`/api/v1/publisher/deployments`, `/api/v1/publisher/deployment/{id}`) are the correct production endpoints
- All SHA pins are the values specified in the plan interfaces

## Threat Flags

No new threat surfaces beyond the plan's threat model (T-110-09 through T-110-14). All mitigations applied:

| Threat | Mitigation Applied |
|--------|--------------------|
| T-110-09: Accidental coordinate burn | `publishToMavenCentral` only; `publishAndReleaseToMavenCentral` absent; fire-drill DROPs VALIDATED; verify chain confirms |
| T-110-10: GITHUB_TOKEN downstream trigger footgun | All native publish jobs in release-please.yml under `needs: release-please` + `if: release_created`; no `on: release` listener; verify chain confirms |
| T-110-11: Mirror tag force-moved | No `--force` on either mirror push; `git push` will reject non-fast-forward; verify chain confirms |
| T-110-12: Secrets echoed to logs | Preflight prints var NAMES only; no `echo $SECRET` anywhere; curl uses `-u user:pass` (Actions masks); fire-drill never echoes env var values |
| T-110-13: Un-pinned supply chain (CVE-2025-30066) | `actions/checkout` + `actions/setup-java` SHA-pinned with `# vX` comments; splitsh-lite from version-pinned v2.0.0 tarball URL |
| T-110-14: Dangling deployment on CI crash | FAILED retained (not dropped); VALIDATED dropped; SUMMARY documents that a CI crash mid-upload may leave a deployment requiring manual DROP via the Central Portal dashboard — the fire-drill is the rehearsal surface |

**Operator note for T-110-14:** If the fire-drill CI job crashes after the `publishToMavenCentral` step but before the DELETE poll completes, a VALIDATED deployment may persist in the Central Portal. Log into `central.sonatype.com`, navigate to Deployments, and manually drop it to free the version coordinate. This is the expected recovery path — the fire-drill exists precisely to surface this scenario in a safe (non-release) context.

## Handoff Note for Phase 111

Per the plan's output spec (recorded here per requirement):

1. **Remove `release-as: "0.1.2"` pin** from `release-please-config.json` in a `chore:` commit immediately after `0.1.2` ships. This is the #1 post-bootstrap footgun (D-04): leaving it in means every subsequent Release PR will also propose `0.1.2` indefinitely.

2. **iOS mirror landing-page README** ("read-only distribution mirror; develop at canonical repo; no issues/PRs here") — write it when the mirror is first seeded on Phase 111's real cut (D-09 decision; Phase 110 deliberately leaves the mirror empty).

3. **SPI/PackageList submission** — submit a PR to `SwiftPackageIndex/PackageList` adding `github.com/szTheory/crosswake-shell-core-ios` after the first real tag exists (Phase 111). Submitting before a real tag produces a poor "no releases" display.

4. **The release-gated jobs (`publish-ios-core`, `publish-android-core`) will fire for the first time on Phase 111's real coordinated `0.1.2` cut.** The on-demand fire-drill and lockstep-truth jobs are the only executable proofs available within Phase 110.

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| `.github/workflows/release-please.yml` | FOUND |
| commit 15125d5 (Task 1) | FOUND |
| commit 68c237b (Task 2) | FOUND |
| commit a9daa47 (Task 3) | FOUND |
| `publish-ios-core` job in YAML | FOUND |
| `publish-android-core` job in YAML | FOUND |
| `android-publish-fire-drill` job in YAML | FOUND |
| `lockstep-truth` job in YAML | FOUND |
| YAML parses cleanly | CONFIRMED |
