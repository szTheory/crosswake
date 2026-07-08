# Phase 145: Native Registry & Mirror Parity - Research

**Researched:** 2026-07-08
**Domain:** GitHub Actions native release operations, SwiftPM mirror backfill, release integrity proof
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Copied verbatim from `.planning/phases/145-native-registry-mirror-parity/145-CONTEXT.md`. [VERIFIED: 145-CONTEXT.md]

#### Mirror Token Strictness
- **D-01:** Keep the existing empty-secret failure and authenticated `git ls-remote mirror HEAD` read check, but do not treat read access as sufficient. The release job must also prove write authority before the real mirror mutation.
- **D-02:** Add a non-mutating write-authority probe before the real iOS mirror push, preferably `git push --dry-run --porcelain mirror "${SPLIT_SHA}:refs/heads/main" "${SPLIT_SHA}:refs/tags/v${VERSION}"` or an equivalent no-write probe that exercises Git push auth. This directly targets the SEED-003 failure class: a token that can be present/read but cannot push.
- **D-03:** The required credential should be described as a fine-grained PAT or GitHub App token scoped to `szTheory/crosswake-shell-core-ios` with repository `Contents:write`. The repo-scoped `GITHUB_TOKEN` for `szTheory/crosswake` is not acceptable for pushing to the separate mirror repository.
- **D-04:** Do not use routine scratch-ref create/delete as the normal release preflight. It is more authoritative than dry-run but mutates the mirror, can trigger webhooks, and belongs only in a deliberate fire-drill or backfill path if needed.
- **D-05:** The actual push remains the final authority. If the dry-run passes but the real push fails because of race, revocation, or branch protection, the job should fail closed with `[crosswake] FAIL` copy naming the mirror repo, expected tag, required permission, and next safe recovery command/path.

#### `v0.2.0` Backfill Mechanism
- **D-06:** Make a maintained verify-first script the canonical MIRR-03 path. It should default to verification only and require an explicit apply flag before pushing anything. The planner may choose the exact name, but it should live in `script/` and be callable from CI.
- **D-07:** Provide a thin `workflow_dispatch` wrapper over the script for operator ergonomics and secret handling. The YAML must not duplicate backfill logic; it should validate typed inputs, call the script, and publish logs/summary. Runbook-only manual commands are break-glass appendix material, not the primary product surface.
- **D-08:** Do not make "rerun the original release job" the primary recovery guidance. Reruns can be useful only for an exact failed job while registry skips are confirmed; they are time/window/context-sensitive and can accidentally re-enter immutable Hex/Maven paths.
- **D-09:** The backfill path must be idempotent: if `refs/tags/v0.2.0` already exists on the SwiftPM mirror and points to the expected split SHA, report `[crosswake] OK` and exit 0 without pushing.
- **D-10:** If the mirror tag exists but points somewhere else, fail closed. Do not delete or move public SwiftPM version tags automatically; require a deliberate maintainer decision because SwiftPM consumers treat version tags as release identity.
- **D-11:** Before mutating the iOS mirror, verify that root Hex `0.2.0` and Android Maven `0.2.0` are already live or otherwise proven as the intended lockstep release state. This prevents a backfill command from becoming a blind tag writer.

#### Backfill Source Of Truth
- **D-12:** Use the Release Please component release ref as the authoritative split input for `0.2.0`, not current `main`, current checkout, registry dates, or docs. For this backfill, prefer `refs/tags/ios-core-v0.2.0`.
- **D-13:** Verify that `refs/tags/hex-v0.2.0`, `refs/tags/ios-core-v0.2.0`, and `refs/tags/android-core-v0.2.0` all point to the same release commit before proceeding. Local verification during discussion showed all three point to `232a37ddeb32ab526142510fb71d746d2e10dc12`.
- **D-14:** Treat `.release-please-manifest.json` as version/lockstep truth, not commit truth. It should confirm `.`, `packages/crosswake-shell-core-ios`, and `packages/crosswake-shell-core-android` are all `0.2.0`, but the Git tag ref decides the source tree to split.
- **D-15:** Compute the mirror split from `packages/crosswake-shell-core-ios` at the release ref with the same pinned splitter family used by the release workflow. Local verification with `git subtree split --prefix=packages/crosswake-shell-core-ios ios-core-v0.2.0` produced `658d60253c58b7e0aedb576f16f40766fa677f23`; planners should confirm with the pinned `splitsh-lite v1.0.1` path used in CI before writing.
- **D-16:** For the backfill, prefer creating/verifying the `v0.2.0` tag over silently moving mirror `main`. If mirror `main` needs realignment, require an explicit option and use guarded semantics such as `--force-with-lease` after verifying there are no maintainer-owned mirror-only commits. SwiftPM version resolution needs the semver tag; branch realignment is secondary operator hygiene.

#### Native Proof Decoupling And Reporting
- **D-17:** Preserve the independent proof DAG: `clean-room-proof-ios` depends on `release-please`, root Hex publish, and iOS publish/mirror only; `clean-room-proof-android` depends on `release-please`, root Hex publish, and Android Maven publish only. Neither native proof may need the other platform's publish job.
- **D-18:** Add an always-running native release rollup after native publish/proof jobs settle. It should use `always()` plus `needs.*.result` so skipped, failed, canceled, and successful platform paths are reported explicitly.
- **D-19:** The rollup should expose both per-platform state and aggregate state. Recommended vocabulary: `ios=published|proven|missing|failed|skipped`, `android=published|proven|failed|skipped`, and `native_core=complete|partial|none`. Do not flatten Android success into "native complete" when iOS is missing.
- **D-20:** Write a concise GitHub job summary for operator UX. The summary should name the released version, each platform's publish/proof state, whether SwiftPM backfill is needed, and the next safe command/workflow. Avoid burying the answer in raw logs.
- **D-21:** Emit a small machine-readable JSON artifact from the rollup for Phase 146 to consume later. This artifact is release evidence, not the final local `mix crosswake.release.status --json` implementation.
- **D-22:** A partial native state should be honest and visible. It may fail the aggregate rollup or failure-alert job, but it must not prevent the unaffected platform proof from running to completion.

#### Guardrails And Verification
- **D-23:** Extend `script/check_release_workflow_integrity.exs` and `test/crosswake/proof/phase142_release_integrity_test.exs` rather than relying on code review. Release graph policy is product surface in this repo.
- **D-24:** Add stable scanner IDs for the new requirements. Suggested IDs: `release.mirror_token.write_preflight`, `release.ios_backfill.verify_first`, `release.ios_backfill.exact_release_ref`, `release.ios_backfill.tag_idempotent`, `release.ios_backfill.no_default_main_force`, `release.workflow.native_rollup_summary`, and `release.workflow.native_status_artifact`.
- **D-25:** Negative fixtures should prove real regressions: read-only-only token checks passing, current-HEAD backfill, backfill without explicit apply, existing tag mismatch ignored, iOS proof needing Android publish, Android proof needing iOS publish, and aggregate "native complete" copy when one platform failed.
- **D-26:** Keep mutation logic in scripts/workflows, not a public Mix task. Phase 146 may expose status through `mix crosswake.release.status`; Phase 145's mutation/backfill path is maintainer release operations, not adopter API.

#### Operator Experience And Voice
- **D-27:** Treat GitHub Actions summaries, logs, workflow inputs, and runbook copy as the UI. The UI is text/JSON, but it still needs the same product discipline as a visible screen: scannable state, stable nouns, next action, no backend trivia unless it changes operator behavior.
- **D-28:** Use Crosswake brand voice: calm, explicit, technical, honest. Prefix release logs with `[crosswake]`. Avoid "magic", "seamless", or broad "native fixed" language.
- **D-29:** The operator job-to-be-done is: "Is the exact native artifact live and proven? If not, which platform failed, what can still be trusted, and what is the next safe recovery path?" All output should optimize for that question.
- **D-30:** Do not expose raw registry JSON, long Git internals, or token mechanics in the happy path. Surface only package, version, ref, expected split SHA, actual mirror tag state, proof state, and next command/path. Raw details can appear after a failure marker.

### the agent's Discretion

Copied verbatim from `.planning/phases/145-native-registry-mirror-parity/145-CONTEXT.md`. [VERIFIED: 145-CONTEXT.md]

Downstream agents may choose exact script names, JSON field names, shell factoring, and whether the thin dispatch wrapper lives in the release workflow or a separate recovery workflow. They should not revisit the policy decisions above unless official GitHub, SwiftPM, Maven Central, Release Please, or Git behavior contradicts them.

### Deferred Ideas (OUT OF SCOPE)

Copied verbatim from `.planning/phases/145-native-registry-mirror-parity/145-CONTEXT.md`. [VERIFIED: 145-CONTEXT.md]

- Full local/text/JSON release status command completion remains Phase 146, though Phase 145 may emit a narrow CI artifact for it.
- Live registry probes in local status remain Phase 146 unless a probe is required to safely verify/backfill the iOS mirror.
- General Maven Central recovery and broader native package recovery UX beyond the iOS `v0.2.0` mirror gap remain out of scope unless needed to keep MIRR-02 reporting honest.
- No graphical dashboard/operator UI in Phase 145; future `crosswake_dashboard` remains DASH-01.
- New runtime capabilities, native feature breadth, offline-sync productization, and companion package additions remain deferred behind v18 release integrity.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MIRR-01 | The iOS mirror job fails fast when `MIRROR_PUSH_TOKEN` is absent or unusable. [VERIFIED: REQUIREMENTS.md] | Current workflow checks absent token and read access, but lacks a non-mutating push-authority probe; Git documents `git push --dry-run --porcelain` for no-update push checks. [VERIFIED: .github/workflows/release-please.yml] [CITED: https://git-scm.com/docs/git-push] |
| MIRR-02 | iOS and Android clean-room proofs no longer depend on each other when only one native registry path fails. [VERIFIED: REQUIREMENTS.md] | Current native proof `needs` are already platform-specific; Phase 145 should preserve that DAG and add an always-running rollup that reports partial native state using `needs.*.result`. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: script/check_release_workflow_integrity.exs] [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/contexts] |
| MIRR-03 | Maintainers have an explicit path to verify or backfill the missing iOS `v0.2.0` mirror tag. [VERIFIED: REQUIREMENTS.md] | Live probes show Hex `crosswake 0.2.0` and Maven Android `0.2.0` are live while the SwiftPM mirror lacks `refs/tags/v0.2.0`; the backfill should split `packages/crosswake-shell-core-ios` at `refs/tags/ios-core-v0.2.0`, verify first, and only push with explicit `--apply`. [VERIFIED: Hex.pm API] [VERIFIED: Maven Central metadata] [VERIFIED: GitHub git ls-remote] [VERIFIED: git subtree split] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Read `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` before planning or implementation work. [VERIFIED: AGENTS.md]
- Preserve the core thesis: Crosswake is Phoenix-first route-policy and runtime-contract infrastructure, not a universal UI framework. [VERIFIED: AGENTS.md]
- Keep runtime ownership explicit per route; do not collapse designs into generic WebView wrapper behavior or LiveView-driven native rendering. [VERIFIED: AGENTS.md]
- Treat bridge contracts as semantic, typed, versioned, and low-frequency. [VERIFIED: AGENTS.md]
- Keep offline claims honest; distinguish cached read-only behavior from true local-first mutation with journals, outboxes, and reconciliation. [VERIFIED: AGENTS.md]
- Treat diagnostics, support matrices, proof lanes, and rough-edge documentation as product surface, not cleanup work. [VERIFIED: AGENTS.md]
- Respect v1 scope boundaries before adding integrations or wider native breadth. [VERIFIED: AGENTS.md]
- Update planning artifacts as work progresses so requirements, roadmap state, and project decisions stay aligned. [VERIFIED: AGENTS.md]

## Summary

Phase 145 should be planned as a native release-ops parity phase, not as product runtime breadth. [VERIFIED: 145-CONTEXT.md] The existing release workflow already gates root/iOS/Android publishes on exact Release Please `paths_released`, already fails on an empty `MIRROR_PUSH_TOKEN`, performs a read check with `git ls-remote mirror HEAD`, and keeps iOS and Android clean-room proofs platform-specific. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: script/check_release_workflow_integrity.exs] The missing MIRR-01 work is write authority: add a no-mutation `git push --dry-run --porcelain` probe before the real mirror push, then extend the scanner/tests so read-only token checks cannot pass as sufficient. [CITED: https://git-scm.com/docs/git-push] [VERIFIED: 145-CONTEXT.md]

MIRR-03 is a targeted SwiftPM mirror repair. [VERIFIED: REQUIREMENTS.md] Local refs `hex-v0.2.0`, `ios-core-v0.2.0`, and `android-core-v0.2.0` all resolve to `232a37ddeb32ab526142510fb71d746d2e10dc12`; local subtree split of `packages/crosswake-shell-core-ios` at `ios-core-v0.2.0` resolves to `658d60253c58b7e0aedb576f16f40766fa677f23`. [VERIFIED: git rev-parse] [VERIFIED: git subtree split] Live public probes show Hex `crosswake 0.2.0` returns HTTP 200, Maven metadata lists Android `0.2.0` as latest/release, and the SwiftPM mirror has `v0.1.2` plus `main` at `6417ae6543219f1c35be120766827503eaa8ceea` but no `refs/tags/v0.2.0`. [VERIFIED: Hex.pm API] [VERIFIED: Maven Central metadata] [VERIFIED: GitHub git ls-remote]

Use one maintained verify-first script in `script/` for backfill and a thin `workflow_dispatch` wrapper for secrets/operator UX. [VERIFIED: 145-CONTEXT.md] The script should default to verification, fail closed on tag mismatch, require explicit `--apply` for mutation, verify Hex and Maven lockstep state before writing the iOS mirror, and keep optional mirror `main` realignment behind a separate explicit flag. [VERIFIED: 145-CONTEXT.md] GitHub job summaries and a narrow JSON artifact should report native partial state for Phase 146 without implementing the full local release-status command. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#adding-a-job-summary] [CITED: https://docs.github.com/en/actions/tutorials/store-and-share-data] [VERIFIED: 145-CONTEXT.md]

**Primary recommendation:** add iOS mirror push dry-run preflight, add `script/verify_ios_mirror_backfill.sh` or equivalent with `--apply` guarded mutation, add a thin manual-dispatch wrapper, add a native rollup summary/artifact job, and extend `script/check_release_workflow_integrity.exs` plus `test/crosswake/proof/phase142_release_integrity_test.exs` with the MIRR scanner IDs and negative fixtures. [VERIFIED: 145-CONTEXT.md] [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: script/check_release_workflow_integrity.exs]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| iOS mirror publish authorization | GitHub Actions release job | Git remote `szTheory/crosswake-shell-core-ios` | The token is an Actions secret consumed by `publish-ios-core`, but the authoritative check is whether the mirror remote accepts push auth for `refs/heads/main` and `refs/tags/v${VERSION}`. [VERIFIED: .github/workflows/release-please.yml] [CITED: https://git-scm.com/docs/git-push] |
| SwiftPM `v0.2.0` backfill | Maintainer CI script | GitHub mirror repository | SwiftPM resolves package versions from Git/SemVer version tags, so the missing public mirror tag is the release identity to repair. [CITED: https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/releasingpublishingapackage/] [CITED: https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html] |
| Lockstep state verification | Backfill script | Hex.pm API, Maven Central metadata, Release Please refs | Backfill must prove root Hex and Android Maven `0.2.0` are live/intended before it writes the iOS mirror tag. [VERIFIED: Hex.pm API] [VERIFIED: Maven Central metadata] [VERIFIED: 145-CONTEXT.md] |
| Native proof independence | GitHub Actions DAG | Semantic scanner | Current iOS/Android proof jobs depend only on root Hex plus their own native publish path; scanner/tests should keep that invariant. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: script/check_release_workflow_integrity.exs] |
| Native release rollup | GitHub Actions reporting job | JSON artifact for Phase 146 | `always()` plus `needs.*.result` can report success, failure, cancellation, and skip states after platform jobs settle. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax] [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/contexts] |
| Operator UX | GitHub Actions summary/logs/workflow inputs | Docs/runbook | Phase 145 operator surface is text and JSON in CI, not a public Mix task or graphical UI. [VERIFIED: 145-CONTEXT.md] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| GitHub Actions workflow syntax | Current GitHub Docs, read 2026-07-08 | Release orchestration, manual dispatch, job dependencies, `always()`, `needs.*.result`, summaries, and artifacts. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax] [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/contexts] | It is the existing release execution tier for Release Please, native publishing, clean-room proof, cleanup, and alerts. [VERIFIED: .github/workflows/release-please.yml] |
| `googleapis/release-please-action` | v4.1.3 pinned by SHA `45996ed1f6d02564a971a2fa1b5860e934307cf7` | Emits root/path release outputs and creates component tags. [VERIFIED: .github/workflows/release-please.yml] | Crosswake's root/native lockstep group already depends on `paths_released`, `tag_name`, and `version` outputs from this action. [CITED: https://github.com/googleapis/release-please-action#outputs] [VERIFIED: release-please-config.json] |
| Git | Local 2.41.0; docs latest page read 2026-07-08 | Ref verification, mirror remote reads, dry-run push authority checks, tag creation, and guarded branch updates. [VERIFIED: env audit] [CITED: https://git-scm.com/docs/git-push] | Git is the actual SwiftPM distribution substrate because the iOS package is a source mirror repository with SemVer tags. [VERIFIED: .github/workflows/release-please.yml] [CITED: https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html] |
| `splitsh-lite` | v1.0.1 pinned in workflow | Deterministic subtree split for `packages/crosswake-shell-core-ios`. [VERIFIED: .github/workflows/release-please.yml] | The release job already uses this splitter family, and splitsh-lite documents `--prefix` split SHA output for standalone repository pushes. [CITED: https://github.com/splitsh/lite] |
| Bash + curl + Python stdlib JSON | Bash 5.2.37, curl 8.7.1, Python 3.14.4 locally | Verify registry state, parse JSON/XML where needed, and orchestrate backfill from a maintained script. [VERIFIED: env audit] | Existing release helpers use shell, curl, and Python to avoid adding package dependencies for release operations. [VERIFIED: script/guarded_hex_publish.sh] [VERIFIED: .github/workflows/release-please.yml] |
| ExUnit | Elixir/Mix 1.19.5 locally | Semantic scanner wrapper and adversarial negative fixtures. [VERIFIED: env audit] | `test/crosswake/proof/phase142_release_integrity_test.exs` is the existing merge-blocking release-integrity proof pattern. [VERIFIED: test/crosswake/proof/phase142_release_integrity_test.exs] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `actions/checkout` | v7.0.0 pinned by SHA `9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0` | Checkout full history and exact release refs before splitting/backfill. [VERIFIED: .github/workflows/release-please.yml] | Use in release and manual backfill workflows; backfill needs `fetch-depth: 0` and exact tags. [VERIFIED: 145-CONTEXT.md] |
| `actions/setup-java` | v4.8.0 pinned by SHA `c1e323688fd81a25caa38c78aa6df2d33d3e20d9` | Android publish/proof jobs. [VERIFIED: .github/workflows/release-please.yml] | Phase 145 should not broaden Android recovery, but Maven state verification can rely on registry metadata instead of local Gradle when Java is unavailable. [VERIFIED: env audit] [VERIFIED: Maven Central metadata] |
| `actions/upload-artifact` | Existing GitHub Actions artifact mechanism | Upload the narrow native rollup JSON artifact for Phase 146. [CITED: https://docs.github.com/en/actions/tutorials/store-and-share-data] | Use only for release evidence JSON, not for implementing the full status command. [VERIFIED: 145-CONTEXT.md] |
| GitHub job summaries | `$GITHUB_STEP_SUMMARY` environment file | Human-scannable native release state. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#adding-a-job-summary] | Use in the native rollup and backfill dispatch wrapper so operators do not need to inspect raw logs first. [VERIFIED: 145-CONTEXT.md] |
| `gh` CLI | 2.95.0 locally | Existing issue/PR automation surface. [VERIFIED: env audit] | Not required for the core backfill path unless the planner extends failure-alert issue creation. [VERIFIED: .github/workflows/release-please.yml] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `git push --dry-run --porcelain` write probe | Scratch ref create/delete | Scratch refs more closely exercise mutation but mutate the mirror and can trigger hooks; context locks them to deliberate fire-drills/backfill, not routine preflight. [VERIFIED: 145-CONTEXT.md] [CITED: https://git-scm.com/docs/git-push] |
| Verify-first script plus dispatch wrapper | Runbook-only manual commands | Runbook commands are easy to drift, do not centralize secret handling, and are explicitly break-glass rather than primary product surface. [VERIFIED: 145-CONTEXT.md] |
| Exact Release Please component tag | Current `main` or current checkout | Current refs can drift from the `0.2.0` release identity; context locks `refs/tags/ios-core-v0.2.0` as source truth. [VERIFIED: 145-CONTEXT.md] [VERIFIED: git rev-parse] |
| Native rollup summary/artifact | Full `mix crosswake.release.status --json` completion | Phase 146 owns the local status command; Phase 145 may only emit narrow CI evidence for later consumption. [VERIFIED: 145-CONTEXT.md] |

**Installation:**

```bash
# No new package installation is recommended for Phase 145.
# The release workflow already installs splitsh-lite v1.0.1 in CI.
```

**Version verification:** No new registry packages are required. Existing tool/action versions were verified from workflow pins, local CLI probes, and official docs. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: env audit] [CITED: https://github.com/googleapis/release-please-action#outputs]

## Package Legitimacy Audit

Phase 145 should not install new external packages. [VERIFIED: 145-CONTEXT.md] The implementation can use existing pinned GitHub Actions, existing release scripts, shell, curl, Python stdlib, Git, splitsh-lite, and ExUnit. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: script/check_release_workflow_integrity.exs] [VERIFIED: env audit]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | - | - | - | - | OK | No package legitimacy gate required because no new external package install is recommended. [VERIFIED: 145-CONTEXT.md] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: no package install]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no package install]

## Architecture Patterns

### System Architecture Diagram

```text
Release Please component release
  |
  +-- paths_released includes packages/crosswake-shell-core-ios
  |     |
  |     v
  |  publish-ios-core
  |     |
  |     +-- split packages/crosswake-shell-core-ios at release ref
  |     +-- require MIRROR_PUSH_TOKEN
  |     +-- git ls-remote mirror HEAD (read/auth check)
  |     +-- if mirror tag vVERSION exists:
  |     |      expected SHA -> OK skip
  |     |      wrong SHA    -> FAIL closed
  |     +-- git push --dry-run --porcelain mirror SPLIT_SHA:main SPLIT_SHA:tag
  |     +-- real push to main and tag
  |     v
  |  clean-room-proof-ios
  |
  +-- paths_released includes packages/crosswake-shell-core-android
        |
        v
     publish-android-core -> clean-room-proof-android

After native jobs settle
  |
  v
native-release-rollup (always)
  |
  +-- reads needs.publish-ios-core.result / needs.clean-room-proof-ios.result
  +-- reads needs.publish-android-core.result / needs.clean-room-proof-android.result
  +-- writes GITHUB_STEP_SUMMARY
  +-- uploads native-release-status.json
```

For manual backfill:

```text
workflow_dispatch inputs: version, release_ref, apply, update_main
  |
  v
thin YAML validation
  |
  v
script/<ios-mirror-backfill>.sh
  |
  +-- verify manifest lockstep version
  +-- verify hex/android/ios component tags point to same release commit
  +-- compute split SHA with pinned splitter family
  +-- verify Hex 0.2.0 and Maven Android 0.2.0 live
  +-- inspect mirror tag v0.2.0
  |     expected -> OK, no push
  |     wrong    -> FAIL closed
  |     absent   -> verify-only report or --apply push tag
  +-- optional explicit --update-main guarded separately
```

### Recommended Project Structure

```text
script/
|-- check_release_workflow_integrity.exs       # extend with MIRR scanner IDs [VERIFIED: script/check_release_workflow_integrity.exs]
|-- verify_ios_mirror_backfill.sh              # new verify-first backfill script [VERIFIED: 145-CONTEXT.md]
`-- guarded_hex_publish.sh                     # existing Hex immutable-state model to mirror for copy [VERIFIED: script/guarded_hex_publish.sh]

.github/workflows/
|-- release-please.yml                         # add write preflight, rollup, artifact, optional dispatch wrapper [VERIFIED: .github/workflows/release-please.yml]
`-- ios-mirror-backfill.yml                    # acceptable alternative if planner prefers separate recovery workflow [VERIFIED: 145-CONTEXT.md]

test/crosswake/proof/
`-- phase142_release_integrity_test.exs        # extend existing fixture pattern for MIRR IDs [VERIFIED: test/crosswake/proof/phase142_release_integrity_test.exs]
```

### Pattern 1: Non-Mutating Mirror Write Preflight

**What:** Before real mirror mutation, run a dry-run push for both branch and tag refs. [VERIFIED: 145-CONTEXT.md] [CITED: https://git-scm.com/docs/git-push]

**When to use:** In `publish-ios-core`, after split SHA computation and before the real `git push mirror ...` calls. [VERIFIED: .github/workflows/release-please.yml]

**Example:**

```bash
# Source: https://git-scm.com/docs/git-push and .github/workflows/release-please.yml
set -euo pipefail

git ls-remote mirror HEAD >/dev/null

if git ls-remote --exit-code mirror "refs/tags/v${VERSION}" >/dev/null 2>&1; then
  actual="$(git ls-remote mirror "refs/tags/v${VERSION}" | awk '{print $1}')"
  if [ "$actual" = "$SPLIT_SHA" ]; then
    echo "[crosswake] OK: iOS mirror tag v${VERSION} already points to ${SPLIT_SHA}; no push attempted."
    exit 0
  fi
  echo "[crosswake] FAIL: iOS mirror tag v${VERSION} points to ${actual}, expected ${SPLIT_SHA}."
  exit 1
fi

git push --dry-run --porcelain mirror \
  "${SPLIT_SHA}:refs/heads/main" \
  "${SPLIT_SHA}:refs/tags/v${VERSION}"

git push mirror "${SPLIT_SHA}:refs/heads/main"
git push mirror "${SPLIT_SHA}:refs/tags/v${VERSION}"
```

### Pattern 2: Verify-First Backfill Script

**What:** A maintained script defaults to verification, requires `--apply` to push, and treats exact existing mirror tags as success. [VERIFIED: 145-CONTEXT.md]

**When to use:** For the missing `v0.2.0` SwiftPM mirror tag, and later for the same exact mirror-only recovery class if needed. [VERIFIED: 145-CONTEXT.md]

**Example:**

```bash
# Source: Phase 145 context plus Git/Hex/Maven live probes.
script/verify_ios_mirror_backfill.sh \
  --version 0.2.0 \
  --ref refs/tags/ios-core-v0.2.0

script/verify_ios_mirror_backfill.sh \
  --version 0.2.0 \
  --ref refs/tags/ios-core-v0.2.0 \
  --apply
```

The script should fail if `--ref` is `main`, `HEAD`, a branch name, or a bare version string; the release ref must be an exact tag ref or full commit SHA accepted by the script. [VERIFIED: 145-CONTEXT.md]

### Pattern 3: Native Rollup Summary And JSON Artifact

**What:** A job with `always()` and native job `needs` reads `needs.*.result`, writes a concise summary, and uploads a small JSON artifact. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax] [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/contexts] [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#adding-a-job-summary]

**When to use:** After `publish-ios-core`, `clean-room-proof-ios`, `publish-android-core`, and `clean-room-proof-android` settle. [VERIFIED: 145-CONTEXT.md]

**Example:**

```yaml
# Source: GitHub Actions workflow syntax, contexts, and job summary docs.
native-release-rollup:
  name: Native release rollup
  needs:
    - release-please
    - publish-ios-core
    - clean-room-proof-ios
    - publish-android-core
    - clean-room-proof-android
  if: ${{ always() }}
  runs-on: ubuntu-latest
  steps:
    - name: Summarize native release state
      run: |
        set -euo pipefail
        cat > native-release-status.json <<JSON
        {
          "version": "${{ needs.release-please.outputs.version }}",
          "ios": {
            "publish": "${{ needs.publish-ios-core.result }}",
            "proof": "${{ needs.clean-room-proof-ios.result }}"
          },
          "android": {
            "publish": "${{ needs.publish-android-core.result }}",
            "proof": "${{ needs.clean-room-proof-android.result }}"
          }
        }
        JSON
        {
          echo "### Crosswake native release"
          echo ""
          echo "- version: ${{ needs.release-please.outputs.version }}"
          echo "- ios publish: ${{ needs.publish-ios-core.result }}"
          echo "- ios proof: ${{ needs.clean-room-proof-ios.result }}"
          echo "- android publish: ${{ needs.publish-android-core.result }}"
          echo "- android proof: ${{ needs.clean-room-proof-android.result }}"
        } >> "$GITHUB_STEP_SUMMARY"
    # Pin the selected v4 action release by full commit SHA in the actual workflow.
    - uses: actions/upload-artifact@v4
      with:
        name: native-release-status
        path: native-release-status.json
```

### Anti-Patterns to Avoid

- **Read-only mirror token acceptance:** `git ls-remote` proves read/auth, not push authority; require the dry-run push probe before mutation. [VERIFIED: .github/workflows/release-please.yml] [CITED: https://git-scm.com/docs/git-push]
- **Current-main backfill:** Backfill from `refs/tags/ios-core-v0.2.0`, not from the current checkout or `main`. [VERIFIED: 145-CONTEXT.md]
- **Automatic tag correction:** If `v0.2.0` exists on the mirror and points to the wrong SHA, fail closed and require maintainer decision. [VERIFIED: 145-CONTEXT.md]
- **Proof cascade:** Do not add Android publish/proof as an iOS proof need or iOS publish/proof as an Android proof need. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: script/check_release_workflow_integrity.exs]
- **Full status scope creep:** Do not finish or redesign `mix crosswake.release.status`; only emit the narrow CI artifact Phase 146 can consume later. [VERIFIED: 145-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Git subtree history splitting | Custom copy/commit mirror builder | `splitsh-lite v1.0.1` in CI | The release workflow already pins the splitter family; context requires same family for backfill SHA parity. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: 145-CONTEXT.md] |
| Push-authority detection | Scratch ref create/delete by default | `git push --dry-run --porcelain` | Dry-run exercises push auth without routine mirror mutation or webhook side effects. [CITED: https://git-scm.com/docs/git-push] [VERIFIED: 145-CONTEXT.md] |
| Workflow semantic proof | New broad YAML parser dependency | Existing Elixir scanner and ExUnit wrapper | Crosswake already encodes release policy as product surface through stable scanner IDs. [VERIFIED: script/check_release_workflow_integrity.exs] [VERIFIED: test/crosswake/proof/phase142_release_integrity_test.exs] |
| Operator summary rendering | Log scraping | `$GITHUB_STEP_SUMMARY` and JSON artifact | GitHub provides first-class job summaries and artifacts; Phase 145 should make state visible without requiring raw-log inspection. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#adding-a-job-summary] [CITED: https://docs.github.com/en/actions/tutorials/store-and-share-data] |
| Registry identity parsing | Grep raw JSON/XML for state decisions | Python stdlib JSON and narrow XML/HTTP checks | Backfill safety depends on exact package/version/ref identity, not substring presence. [VERIFIED: script/guarded_hex_publish.sh] [VERIFIED: Hex.pm API] [VERIFIED: Maven Central metadata] |

**Key insight:** Native registry parity is mostly external state reconciliation, not application logic. [VERIFIED: 145-CONTEXT.md] The plan should centralize mutation in scripts/workflows, prove exact refs before writes, and encode the invariants in the existing scanner/tests so future releases cannot silently reintroduce SEED-003. [VERIFIED: 145-CONTEXT.md] [VERIFIED: script/check_release_workflow_integrity.exs]

## Common Pitfalls

### Pitfall 1: Read Access Masquerading As Write Access
**What goes wrong:** A present token passes `git ls-remote` but fails the real mirror push with a 403. [VERIFIED: 145-CONTEXT.md]
**Why it happens:** Read checks exercise authentication and repository visibility, not `Contents:write` push authority. [CITED: https://docs.github.com/en/rest/git/refs] [CITED: https://git-scm.com/docs/git-push]
**How to avoid:** Add `git push --dry-run --porcelain mirror "${SPLIT_SHA}:refs/heads/main" "${SPLIT_SHA}:refs/tags/v${VERSION}"` before mutation. [VERIFIED: 145-CONTEXT.md] [CITED: https://git-scm.com/docs/git-push]
**Warning signs:** Scanner accepts a workflow block with `git ls-remote mirror HEAD` but no `git push --dry-run`. [VERIFIED: script/check_release_workflow_integrity.exs]

### Pitfall 2: Tag Mismatch Auto-Correction
**What goes wrong:** A script deletes or moves a public SwiftPM tag when it finds a mismatch. [VERIFIED: 145-CONTEXT.md]
**Why it happens:** The script treats registry repair as internal cleanup instead of public release identity. [VERIFIED: 145-CONTEXT.md]
**How to avoid:** Exact match is OK, absent tag plus `--apply` may create, mismatch fails closed. [VERIFIED: 145-CONTEXT.md]
**Warning signs:** Script contains `git push --delete`, `:refs/tags/v${VERSION}`, or force-updates a tag by default. [VERIFIED: 145-CONTEXT.md]

### Pitfall 3: Backfilling From Mutable Source
**What goes wrong:** Backfill splits current `main` instead of the `ios-core-v0.2.0` component tag. [VERIFIED: 145-CONTEXT.md]
**Why it happens:** Current checkout is easier to script than exact Release Please component refs. [VERIFIED: 145-CONTEXT.md]
**How to avoid:** Validate `refs/tags/hex-v0.2.0`, `refs/tags/ios-core-v0.2.0`, and `refs/tags/android-core-v0.2.0` share the same commit before computing the split. [VERIFIED: git rev-parse] [VERIFIED: 145-CONTEXT.md]
**Warning signs:** Script defaults `--ref` to `HEAD` or `main`. [VERIFIED: 145-CONTEXT.md]

### Pitfall 4: Native Proof Cascade Hidden By Rollup
**What goes wrong:** iOS failure prevents Android proof from running, or a rollup labels Android success plus iOS missing as complete. [VERIFIED: 145-CONTEXT.md]
**Why it happens:** Jobs share broad native dependencies or summary code flattens platform state. [VERIFIED: 145-CONTEXT.md]
**How to avoid:** Preserve platform-specific proof `needs`, then summarize both platform and aggregate state. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: script/check_release_workflow_integrity.exs]
**Warning signs:** `clean-room-proof-ios` needs `publish-android-core`, or summary text says `native complete` without checking both platforms. [VERIFIED: 145-CONTEXT.md]

### Pitfall 5: Immutable Registry Rerun Guidance
**What goes wrong:** Recovery tells maintainers to rerun the original release job and accidentally re-enters Hex or Maven publish paths. [VERIFIED: 145-CONTEXT.md]
**Why it happens:** Release jobs combine multiple registries with different immutability/recovery semantics. [VERIFIED: 143-RESEARCH.md] [CITED: https://hex.pm/docs/faq] [CITED: https://central.sonatype.org/publish/requirements/immutability/]
**How to avoid:** Make the backfill path verify Hex/Maven already-live state but mutate only the SwiftPM mirror tag. [VERIFIED: 145-CONTEXT.md]
**Warning signs:** Runbook primary path says rerun Release Please instead of running the dedicated iOS mirror backfill workflow/script. [VERIFIED: docs/COMPANION-PUBLISH-RUNBOOK.md]

## Code Examples

Verified patterns from official sources and local code:

### Scanner ID Extension Pattern

```elixir
# Source: script/check_release_workflow_integrity.exs
defp mirror_token_write_preflight(jobs) do
  block = job_block(jobs, "publish-ios-core")

  check(
    "release.mirror_token.write_preflight",
    includes?(block, "git push --dry-run --porcelain mirror") and
      includes?(block, "${SPLIT_SHA}:refs/heads/main") and
      includes?(block, "${SPLIT_SHA}:refs/tags/v${VERSION}"),
    "publish-ios-core must prove mirror push authority with a non-mutating dry-run before real push"
  )
end
```

### Backfill Idempotency Branch

```bash
# Source: 145-CONTEXT.md and git ls-remote behavior.
tag_ref="refs/tags/v${VERSION}"
actual="$(git ls-remote mirror "$tag_ref" | awk '{print $1}')"

if [ -n "$actual" ]; then
  if [ "$actual" = "$SPLIT_SHA" ]; then
    echo "[crosswake] OK: iOS mirror ${tag_ref} already points to ${SPLIT_SHA}; no push attempted."
    exit 0
  fi

  echo "[crosswake] FAIL: iOS mirror ${tag_ref} points to ${actual}, expected ${SPLIT_SHA}."
  echo "[crosswake] What to do next: stop; do not move public SwiftPM tags automatically."
  exit 1
fi

if [ "$APPLY" != "1" ]; then
  echo "[crosswake] OK: verify-only; iOS mirror ${tag_ref} is absent and would be created at ${SPLIT_SHA}."
  exit 0
fi

git push mirror "${SPLIT_SHA}:${tag_ref}"
```

### Native Status JSON Shape

```json
{
  "version": "0.2.0",
  "native_core": "partial",
  "ios": {
    "released": true,
    "publish": "failed",
    "proof": "skipped",
    "mirror_tag": "missing",
    "next_action": "run iOS mirror backfill for refs/tags/ios-core-v0.2.0"
  },
  "android": {
    "released": true,
    "publish": "success",
    "proof": "success"
  }
}
```

This shape is phase evidence only, not the final Phase 146 CLI JSON contract. [VERIFIED: 145-CONTEXT.md]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Treating `git ls-remote` as enough mirror token validation | Read check plus `git push --dry-run --porcelain` write-authority preflight | Phase 145 planning target, 2026-07-08 [VERIFIED: 145-CONTEXT.md] | Detects read-only or wrong-repo mirror tokens before the irreversible push. [CITED: https://git-scm.com/docs/git-push] |
| Running native proofs as a coupled platform block | Independent iOS and Android proof jobs plus rollup | Decoupling already present by Phase 144; rollup belongs Phase 145 [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: 144-VERIFICATION.md] | Android proof can complete even when iOS mirror fails, and partial state becomes explicit. [VERIFIED: 145-CONTEXT.md] |
| Manual one-off SwiftPM mirror commands | Maintained verify-first script plus thin dispatch wrapper | Phase 145 target [VERIFIED: 145-CONTEXT.md] | Recovery becomes repeatable, idempotent, secret-aware, and testable through scanner fixtures. [VERIFIED: 145-CONTEXT.md] |
| Rerun whole release job for native recovery | Verify already-live Hex/Maven state, then repair only the missing SwiftPM tag | Phase 145 target [VERIFIED: 145-CONTEXT.md] | Avoids accidental re-entry into immutable Hex/Maven publish paths. [CITED: https://hex.pm/docs/faq] [CITED: https://central.sonatype.org/publish/requirements/immutability/] |
| Operator answer buried in logs | Job summary plus narrow JSON artifact | Phase 145 target [VERIFIED: 145-CONTEXT.md] | Maintainers can see platform state and next safe action from the workflow summary and Phase 146 can consume evidence. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#adding-a-job-summary] |

**Deprecated/outdated:**
- Accepting mirror read access as token health is outdated for this phase; write authority must be probed non-mutatingly. [VERIFIED: 145-CONTEXT.md]
- Treating native parity as all-or-nothing is outdated; partial native state should be explicit. [VERIFIED: 145-CONTEXT.md]
- Making a public Mix mutation task for mirror backfill is out of scope; mutation belongs in maintainer scripts/workflows. [VERIFIED: 145-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| - | None. All planning-critical claims are from phase context, local code/probes, or official docs. [VERIFIED: source audit] | - | - |

## Open Questions

1. **Should the backfill dispatch live in `release-please.yml` or a separate workflow?**
   - What we know: Context allows either, but requires thin YAML over script-owned logic. [VERIFIED: 145-CONTEXT.md]
   - What's unclear: Repository maintainers may prefer a separate workflow to reduce release workflow size. [VERIFIED: 145-CONTEXT.md]
   - Recommendation: Use a separate dispatch workflow only if the scanner can still verify it by path/env override; otherwise keep a small dispatch block in `release-please.yml`. [VERIFIED: script/check_release_workflow_integrity.exs]

2. **Should mirror `main` be realigned during `v0.2.0` backfill?**
   - What we know: SwiftPM version resolution needs the `v0.2.0` tag; mirror `main` currently points to `6417ae6543219f1c35be120766827503eaa8ceea`, the existing `v0.1.2` state. [VERIFIED: GitHub git ls-remote]
   - What's unclear: Whether maintainers want mirror branch hygiene in the same operation. [VERIFIED: 145-CONTEXT.md]
   - Recommendation: Default to tag-only; add optional `--update-main` only with explicit operator input and guarded `--force-with-lease` semantics after verifying no mirror-only commits. [VERIFIED: 145-CONTEXT.md] [CITED: https://git-scm.com/docs/git-push]

3. **Should a deliberate scratch-ref fire-drill be added now?**
   - What we know: Context forbids scratch-ref mutation as routine preflight but allows it as deliberate fire-drill/backfill path if needed. [VERIFIED: 145-CONTEXT.md]
   - What's unclear: Whether dry-run will be sufficient under mirror branch/tag protection rules. [VERIFIED: 145-CONTEXT.md]
   - Recommendation: Do not include scratch-ref mutation in the normal release job; document it as break-glass only if real dry-run/real-push behavior shows branch-protection ambiguity. [VERIFIED: 145-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Git | Ref checks, split source verification, mirror read/write probes | yes | 2.41.0 | CI has Git on runners. [VERIFIED: env audit] |
| Elixir | Scanner and ExUnit proof | yes | 1.19.5 with OTP 28 locally | CI uses `.tool-versions` through setup-beam; note local OTP differs from `.tool-versions` OTP 27.3. [VERIFIED: env audit] [VERIFIED: .tool-versions] |
| Mix | Test and scanner execution | yes | 1.19.5 | None needed. [VERIFIED: env audit] |
| Bash | Release/backfill scripts | yes | 5.2.37 | POSIX shell is possible but existing scripts use Bash. [VERIFIED: env audit] |
| curl | Registry probes | yes | 8.7.1 | Python HTTP is possible but not recommended. [VERIFIED: env audit] |
| Python 3 | JSON/XML parsing in scripts | yes | 3.14.4 | Elixir/Jason possible in Mix tasks, but Phase 145 should keep mutation out of public Mix task. [VERIFIED: env audit] [VERIFIED: 145-CONTEXT.md] |
| Swift | Local SwiftPM proof | yes | Apple Swift 6.3.3 | CI macOS runner for clean-room iOS proof. [VERIFIED: env audit] [VERIFIED: .github/workflows/release-please.yml] |
| Xcode | Local generated iOS proof | yes | Xcode 26.6 | CI macOS runner. [VERIFIED: env audit] [VERIFIED: .github/workflows/release-please.yml] |
| splitsh-lite | Local exact splitter parity | no | - | Workflow installs pinned v1.0.1; planner should rely on CI install path for final split parity. [VERIFIED: env audit] [VERIFIED: .github/workflows/release-please.yml] |
| Java runtime | Local Android Gradle proof | no | - | CI uses `actions/setup-java` Java 17; MIRR-03 can verify Maven live state without local Java. [VERIFIED: env audit] [VERIFIED: .github/workflows/release-please.yml] |
| Android Gradle wrapper | Android package proof when Java is present | yes | wrapper file present | CI setup-java path. [VERIFIED: env audit] |
| gh CLI | Existing PR/issue automation | yes | 2.95.0 | Not required for core MIRR implementation. [VERIFIED: env audit] |
| `MIRROR_PUSH_TOKEN` | Real mirror mutation | no local secret available | - | GitHub Actions secret; planner must not attempt live push locally. [VERIFIED: env audit] [VERIFIED: 145-CONTEXT.md] |

**Missing dependencies with no fallback:**
- None for planning and static verification. [VERIFIED: env audit]

**Missing dependencies with fallback:**
- `splitsh-lite` is missing locally; CI installs pinned v1.0.1. [VERIFIED: env audit] [VERIFIED: .github/workflows/release-please.yml]
- Java is missing locally; CI uses setup-java for Android publish/proof and MIRR-03 can rely on Maven metadata for live-state verification. [VERIFIED: env audit] [VERIFIED: Maven Central metadata]
- `MIRROR_PUSH_TOKEN` is not available locally; real mutation belongs in GitHub Actions with repo secret. [VERIFIED: env audit] [VERIFIED: 145-CONTEXT.md]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit through Mix 1.19.5 locally. [VERIFIED: env audit] |
| Config file | `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/crosswake/proof/phase142_release_integrity_test.exs` [VERIFIED: command passed] |
| Scanner command | `elixir script/check_release_workflow_integrity.exs` [VERIFIED: command passed] |
| Full suite command | `mix test --exclude requires_example_host --exclude advisory_only` or `mix verify` when companion package lanes are desired. [VERIFIED: mix.exs] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| MIRR-01 | iOS mirror publish job rejects absent/read-only token and requires dry-run push authority before real push. [VERIFIED: REQUIREMENTS.md] | Semantic scanner + negative fixture | `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase145_mirror` | Existing file yes; tag/tests need Wave 0 extension. [VERIFIED: test/crosswake/proof/phase142_release_integrity_test.exs] |
| MIRR-02 | iOS/Android proof jobs stay independent and native rollup reports partial state honestly. [VERIFIED: REQUIREMENTS.md] | Semantic scanner + negative fixture | `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase145_native_rollup` | Existing file yes; rollup checks need Wave 0 extension. [VERIFIED: test/crosswake/proof/phase142_release_integrity_test.exs] |
| MIRR-03 | Backfill script is verify-first, exact-ref, idempotent, tag-only by default, and guarded by explicit `--apply`. [VERIFIED: REQUIREMENTS.md] | Script unit/smoke + scanner fixtures | `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase145_ios_backfill` plus direct script dry-run fixture | Script missing; Wave 0 creates script and scanner fixture coverage. [VERIFIED: 145-CONTEXT.md] |

### Sampling Rate

- **Per task commit:** `elixir script/check_release_workflow_integrity.exs` and `mix test test/crosswake/proof/phase142_release_integrity_test.exs`. [VERIFIED: commands passed]
- **Per wave merge:** `mix test --exclude requires_example_host --exclude advisory_only` if touched files are broad; otherwise quick scanner/proof command is sufficient for workflow/script-only changes. [VERIFIED: test/test_helper.exs]
- **Phase gate:** Existing scanner and Phase 142 proof green, plus new MIRR negative fixtures green before `$gsd-verify-work`. [VERIFIED: commands passed] [VERIFIED: 145-CONTEXT.md]

### Wave 0 Gaps

- [ ] Add scanner IDs `release.mirror_token.write_preflight`, `release.ios_backfill.verify_first`, `release.ios_backfill.exact_release_ref`, `release.ios_backfill.tag_idempotent`, `release.ios_backfill.no_default_main_force`, `release.workflow.native_rollup_summary`, and `release.workflow.native_status_artifact`. [VERIFIED: 145-CONTEXT.md]
- [ ] Add negative fixtures to `test/crosswake/proof/phase142_release_integrity_test.exs` for read-only token checks, current-HEAD backfill, missing `--apply`, tag mismatch ignore, proof cross-dependencies, and false native-complete copy. [VERIFIED: 145-CONTEXT.md]
- [ ] Create the iOS mirror backfill script in `script/` and ensure verify-only mode can run without `MIRROR_PUSH_TOKEN`. [VERIFIED: 145-CONTEXT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | `MIRROR_PUSH_TOKEN` must be a fine-grained PAT or GitHub App token scoped to the mirror repo, not the source repo `GITHUB_TOKEN`. [VERIFIED: 145-CONTEXT.md] [CITED: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens] |
| V3 Session Management | no | No user session is introduced; this is CI secret and Git credential handling. [VERIFIED: 145-CONTEXT.md] |
| V4 Access Control | yes | GitHub refs create/update requires repository write permissions; require mirror repo `Contents:write`. [CITED: https://docs.github.com/en/rest/git/refs] [VERIFIED: 145-CONTEXT.md] |
| V5 Input Validation | yes | Validate workflow inputs and script args: semantic version, exact tag ref, explicit `--apply`, no branch/current-main default, exact split SHA/tag comparison. [VERIFIED: 145-CONTEXT.md] |
| V6 Cryptography | yes | Do not hand-roll crypto; rely on GitHub secret storage/masking and HTTPS Git transport. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets] [VERIFIED: .github/workflows/release-please.yml] |

### Known Threat Patterns for GitHub Actions Release Ops

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Read-only or wrong-repo token accepted as mirror-ready | Spoofing / Elevation of Privilege | Require dry-run push preflight and fail closed with mirror repo + required permission. [VERIFIED: 145-CONTEXT.md] |
| Secret leakage in logs or summary | Information Disclosure | Never echo token, keep raw token mechanics out of happy path, rely on GitHub masking. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets] [VERIFIED: 145-CONTEXT.md] |
| Branch/ref injection through workflow inputs | Tampering | Accept only exact tag refs/full SHAs for source, reject `main`, `HEAD`, branches, and bare version strings. [VERIFIED: 145-CONTEXT.md] |
| Public SwiftPM tag overwritten | Tampering / Repudiation | Treat mismatch as fail-closed and require deliberate maintainer decision; do not delete/move tags automatically. [VERIFIED: 145-CONTEXT.md] |
| Native partial failure hidden by aggregate state | Repudiation | Rollup must expose per-platform publish/proof result and aggregate native state. [VERIFIED: 145-CONTEXT.md] |
| Re-entering immutable registries during recovery | Tampering / Denial of Service | Verify Hex/Maven already-live state, but mutate only the SwiftPM mirror tag. [VERIFIED: 145-CONTEXT.md] [CITED: https://hex.pm/docs/faq] [CITED: https://central.sonatype.org/publish/requirements/immutability/] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/145-native-registry-mirror-parity/145-CONTEXT.md` - locked phase decisions, specific backfill refs, scanner IDs, and phase boundaries. [VERIFIED: 145-CONTEXT.md]
- `.planning/REQUIREMENTS.md` - MIRR-01, MIRR-02, MIRR-03 requirement text and phase mapping. [VERIFIED: REQUIREMENTS.md]
- `.planning/ROADMAP.md` - Phase 145 and Phase 146 boundary. [VERIFIED: ROADMAP.md]
- `.planning/STATE.md` and `.planning/PROJECT.md` - v18 context, SEED-003 carryover, and project constraints. [VERIFIED: STATE.md] [VERIFIED: PROJECT.md]
- `.github/workflows/release-please.yml` - current iOS mirror job, native proof DAG, and existing release workflow shape. [VERIFIED: .github/workflows/release-please.yml]
- `script/check_release_workflow_integrity.exs` and `test/crosswake/proof/phase142_release_integrity_test.exs` - existing scanner/test pattern and current green state. [VERIFIED: script/check_release_workflow_integrity.exs] [VERIFIED: test/crosswake/proof/phase142_release_integrity_test.exs]
- Live probes: `git rev-parse hex-v0.2.0 ios-core-v0.2.0 android-core-v0.2.0`, `git subtree split --prefix=packages/crosswake-shell-core-ios ios-core-v0.2.0`, `git ls-remote` for mirror tags/main, Hex API, and Maven Central metadata. [VERIFIED: command probes]

### Secondary (MEDIUM confidence)

- https://git-scm.com/docs/git-push - `--dry-run`, `--porcelain`, refspecs, and guarded force semantics. [CITED: https://git-scm.com/docs/git-push]
- https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax - `needs`, `always()`, job permissions, workflow syntax. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax]
- https://docs.github.com/en/actions/reference/workflows-and-actions/contexts - `needs.<job_id>.result`. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/contexts]
- https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#adding-a-job-summary - `$GITHUB_STEP_SUMMARY`. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#adding-a-job-summary]
- https://docs.github.com/en/actions/tutorials/store-and-share-data - workflow artifacts. [CITED: https://docs.github.com/en/actions/tutorials/store-and-share-data]
- https://docs.github.com/en/rest/git/refs - Git ref read/write permission requirements. [CITED: https://docs.github.com/en/rest/git/refs]
- https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens - fine-grained PATs and GitHub App guidance. [CITED: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens]
- https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/releasingpublishingapackage/ and https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html - SwiftPM Git/SemVer package release model. [CITED: https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/releasingpublishingapackage/] [CITED: https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html]
- https://hex.pm/docs/faq and https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html - Hex immutability and publish/revert/replace behavior. [CITED: https://hex.pm/docs/faq] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]
- https://central.sonatype.org/publish/requirements/immutability/ - Maven Central immutability posture. [CITED: https://central.sonatype.org/publish/requirements/immutability/]
- https://github.com/googleapis/release-please-action and https://github.com/splitsh/lite - Release Please outputs and splitsh-lite usage. [CITED: https://github.com/googleapis/release-please-action] [CITED: https://github.com/splitsh/lite]

### Tertiary (LOW confidence)

- None used for planning-critical claims. [VERIFIED: source audit]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new packages, existing workflow pins and local tools verified. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: env audit]
- Architecture: HIGH - phase context is specific, current workflow/scanner shape was read, and scanner/tests passed. [VERIFIED: 145-CONTEXT.md] [VERIFIED: command probes]
- Pitfalls: HIGH - pitfalls map directly to locked decisions, live registry state, and existing scanner gaps. [VERIFIED: 145-CONTEXT.md] [VERIFIED: GitHub git ls-remote]

**Research date:** 2026-07-08
**Valid until:** 2026-08-07 for local phase planning; re-check GitHub/Git/SwiftPM docs and live registry refs before any actual mirror mutation. [VERIFIED: current date] [CITED: https://git-scm.com/docs/git-push]
