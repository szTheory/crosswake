# Phase 145: Native Registry & Mirror Parity - Context

**Gathered:** 2026-07-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 145 owns Crosswake's native registry parity slice for the lockstep core/native family. It hardens the iOS SwiftPM mirror credential path, keeps iOS and Android clean-room proofs independent when one registry path fails, and gives maintainers an explicit verify/backfill path for the missing iOS `v0.2.0` mirror tag.

This is release-ops product surface, not runtime/product breadth and not the full Phase 146 release-status command. The outcome should make the already-published `crosswake 0.2.0` + Android Maven state honest alongside a repaired/verifiable SwiftPM mirror state.

</domain>

<decisions>
## Implementation Decisions

### Mirror Token Strictness
- **D-01:** Keep the existing empty-secret failure and authenticated `git ls-remote mirror HEAD` read check, but do not treat read access as sufficient. The release job must also prove write authority before the real mirror mutation.
- **D-02:** Add a non-mutating write-authority probe before the real iOS mirror push, preferably `git push --dry-run --porcelain mirror "${SPLIT_SHA}:refs/heads/main" "${SPLIT_SHA}:refs/tags/v${VERSION}"` or an equivalent no-write probe that exercises Git push auth. This directly targets the SEED-003 failure class: a token that can be present/read but cannot push.
- **D-03:** The required credential should be described as a fine-grained PAT or GitHub App token scoped to `szTheory/crosswake-shell-core-ios` with repository `Contents:write`. The repo-scoped `GITHUB_TOKEN` for `szTheory/crosswake` is not acceptable for pushing to the separate mirror repository.
- **D-04:** Do not use routine scratch-ref create/delete as the normal release preflight. It is more authoritative than dry-run but mutates the mirror, can trigger webhooks, and belongs only in a deliberate fire-drill or backfill path if needed.
- **D-05:** The actual push remains the final authority. If the dry-run passes but the real push fails because of race, revocation, or branch protection, the job should fail closed with `[crosswake] FAIL` copy naming the mirror repo, expected tag, required permission, and next safe recovery command/path.

### `v0.2.0` Backfill Mechanism
- **D-06:** Make a maintained verify-first script the canonical MIRR-03 path. It should default to verification only and require an explicit apply flag before pushing anything. The planner may choose the exact name, but it should live in `script/` and be callable from CI.
- **D-07:** Provide a thin `workflow_dispatch` wrapper over the script for operator ergonomics and secret handling. The YAML must not duplicate backfill logic; it should validate typed inputs, call the script, and publish logs/summary. Runbook-only manual commands are break-glass appendix material, not the primary product surface.
- **D-08:** Do not make "rerun the original release job" the primary recovery guidance. Reruns can be useful only for an exact failed job while registry skips are confirmed; they are time/window/context-sensitive and can accidentally re-enter immutable Hex/Maven paths.
- **D-09:** The backfill path must be idempotent: if `refs/tags/v0.2.0` already exists on the SwiftPM mirror and points to the expected split SHA, report `[crosswake] OK` and exit 0 without pushing.
- **D-10:** If the mirror tag exists but points somewhere else, fail closed. Do not delete or move public SwiftPM version tags automatically; require a deliberate maintainer decision because SwiftPM consumers treat version tags as release identity.
- **D-11:** Before mutating the iOS mirror, verify that root Hex `0.2.0` and Android Maven `0.2.0` are already live or otherwise proven as the intended lockstep release state. This prevents a backfill command from becoming a blind tag writer.

### Backfill Source Of Truth
- **D-12:** Use the Release Please component release ref as the authoritative split input for `0.2.0`, not current `main`, current checkout, registry dates, or docs. For this backfill, prefer `refs/tags/ios-core-v0.2.0`.
- **D-13:** Verify that `refs/tags/hex-v0.2.0`, `refs/tags/ios-core-v0.2.0`, and `refs/tags/android-core-v0.2.0` all point to the same release commit before proceeding. Local verification during discussion showed all three point to `232a37ddeb32ab526142510fb71d746d2e10dc12`.
- **D-14:** Treat `.release-please-manifest.json` as version/lockstep truth, not commit truth. It should confirm `.`, `packages/crosswake-shell-core-ios`, and `packages/crosswake-shell-core-android` are all `0.2.0`, but the Git tag ref decides the source tree to split.
- **D-15:** Compute the mirror split from `packages/crosswake-shell-core-ios` at the release ref with the same pinned splitter family used by the release workflow. Local verification with `git subtree split --prefix=packages/crosswake-shell-core-ios ios-core-v0.2.0` produced `658d60253c58b7e0aedb576f16f40766fa677f23`; planners should confirm with the pinned `splitsh-lite v1.0.1` path used in CI before writing.
- **D-16:** For the backfill, prefer creating/verifying the `v0.2.0` tag over silently moving mirror `main`. If mirror `main` needs realignment, require an explicit option and use guarded semantics such as `--force-with-lease` after verifying there are no maintainer-owned mirror-only commits. SwiftPM version resolution needs the semver tag; branch realignment is secondary operator hygiene.

### Native Proof Decoupling And Reporting
- **D-17:** Preserve the independent proof DAG: `clean-room-proof-ios` depends on `release-please`, root Hex publish, and iOS publish/mirror only; `clean-room-proof-android` depends on `release-please`, root Hex publish, and Android Maven publish only. Neither native proof may need the other platform's publish job.
- **D-18:** Add an always-running native release rollup after native publish/proof jobs settle. It should use `always()` plus `needs.*.result` so skipped, failed, canceled, and successful platform paths are reported explicitly.
- **D-19:** The rollup should expose both per-platform state and aggregate state. Recommended vocabulary: `ios=published|proven|missing|failed|skipped`, `android=published|proven|failed|skipped`, and `native_core=complete|partial|none`. Do not flatten Android success into "native complete" when iOS is missing.
- **D-20:** Write a concise GitHub job summary for operator UX. The summary should name the released version, each platform's publish/proof state, whether SwiftPM backfill is needed, and the next safe command/workflow. Avoid burying the answer in raw logs.
- **D-21:** Emit a small machine-readable JSON artifact from the rollup for Phase 146 to consume later. This artifact is release evidence, not the final local `mix crosswake.release.status --json` implementation.
- **D-22:** A partial native state should be honest and visible. It may fail the aggregate rollup or failure-alert job, but it must not prevent the unaffected platform proof from running to completion.

### Guardrails And Verification
- **D-23:** Extend `script/check_release_workflow_integrity.exs` and `test/crosswake/proof/phase142_release_integrity_test.exs` rather than relying on code review. Release graph policy is product surface in this repo.
- **D-24:** Add stable scanner IDs for the new requirements. Suggested IDs: `release.mirror_token.write_preflight`, `release.ios_backfill.verify_first`, `release.ios_backfill.exact_release_ref`, `release.ios_backfill.tag_idempotent`, `release.ios_backfill.no_default_main_force`, `release.workflow.native_rollup_summary`, and `release.workflow.native_status_artifact`.
- **D-25:** Negative fixtures should prove real regressions: read-only-only token checks passing, current-HEAD backfill, backfill without explicit apply, existing tag mismatch ignored, iOS proof needing Android publish, Android proof needing iOS publish, and aggregate "native complete" copy when one platform failed.
- **D-26:** Keep mutation logic in scripts/workflows, not a public Mix task. Phase 146 may expose status through `mix crosswake.release.status`; Phase 145's mutation/backfill path is maintainer release operations, not adopter API.

### Operator Experience And Voice
- **D-27:** Treat GitHub Actions summaries, logs, workflow inputs, and runbook copy as the UI. The UI is text/JSON, but it still needs the same product discipline as a visible screen: scannable state, stable nouns, next action, no backend trivia unless it changes operator behavior.
- **D-28:** Use Crosswake brand voice: calm, explicit, technical, honest. Prefix release logs with `[crosswake]`. Avoid "magic", "seamless", or broad "native fixed" language.
- **D-29:** The operator job-to-be-done is: "Is the exact native artifact live and proven? If not, which platform failed, what can still be trusted, and what is the next safe recovery path?" All output should optimize for that question.
- **D-30:** Do not expose raw registry JSON, long Git internals, or token mechanics in the happy path. Surface only package, version, ref, expected split SHA, actual mirror tag state, proof state, and next command/path. Raw details can appear after a failure marker.

### Claude's Discretion
Downstream agents may choose exact script names, JSON field names, shell factoring, and whether the thin dispatch wrapper lives in the release workflow or a separate recovery workflow. They should not revisit the policy decisions above unless official GitHub, SwiftPM, Maven Central, Release Please, or Git behavior contradicts them.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning And Prior Decisions
- `.planning/PROJECT.md` - v18 thesis, release-integrity scope, and SEED-003 context.
- `.planning/REQUIREMENTS.md` - MIRR-01, MIRR-02, and MIRR-03 traceability.
- `.planning/ROADMAP.md` - Phase 145 boundary relative to PREF and STAT phases.
- `.planning/STATE.md` - current position and already-present v18 implementation spillover notes.
- `.planning/MILESTONE-ARC.md` - v18 arc naming the iOS mirror-token preflight and `v0.2.0` backfill path.
- `.planning/MILESTONES.md` - SEED-003 public project-memory note that iOS `v0.2.0` was not mirrored.
- `.planning/phases/144-published-core-compatibility-clean-room-proof/144-CONTEXT.md` - clean-room exactness and existing mirror/preflight guard context.
- `.planning/phases/143-guarded-auto-publish-train/143-CONTEXT.md` - exact-ref recovery, already-live semantics, and native recovery boundary.
- `.planning/phases/142-release-graph-governance-contract/142-CONTEXT.md` - exact gates, concurrency, cleanup-after-proof, and semantic scanner posture.

### Project Voice And Prompt Guidance
- `brandbook/BRAND-SPEC.md` - current voice and product-surface rules; supersedes `prompts/crosswake-brand-book.md`.
- `prompts/crosswake-elixir-oss-dna.md` - install truth, proof lanes, release truth, support matrices, and named verification commands.
- `prompts/crosswake-gsd-project-brief.md` - release discipline, proof posture, recovery-conscious flow, and explicit support truth as product features.
- `prompts/crosswake-research-synthesis.md` - Crosswake's boundary-aware architecture thesis and anti-scope guardrails.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - CI/CD, release targets, immutable recovery posture, and signing/secrets lessons.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` - diagnostic/operator surfaces and native package lessons.
- `prompts/crosswake-integrations-and-companions.md` - operator truth and companion-boundary context.

### Local Release Code
- `.github/workflows/release-please.yml` - iOS mirror publish job, native proof job DAG, Android publish/proof paths, and current fire-drill/preflight shape.
- `.github/workflows/hex-publish.yml` - exact-ref Hex recovery workflow; useful pattern but Phase 145 should stay native-specific.
- `release-please-config.json` - root/native linked group and component release refs.
- `.release-please-manifest.json` - current lockstep version truth for `.`, iOS core, and Android core.
- `script/check_release_workflow_integrity.exs` - semantic workflow scanner to extend for MIRR checks.
- `test/crosswake/proof/phase142_release_integrity_test.exs` - ExUnit wrapper and negative fixture pattern.
- `script/guarded_hex_publish.sh` - idempotent already-live style to mirror for native backfill copy.
- `script/verify_generated_ios_shell.sh` - local iOS mirror workaround and SwiftPM tag-resolution lessons.
- `packages/crosswake-shell-core-ios/Package.swift` - SwiftPM package being mirrored.
- `packages/crosswake-shell-core-android/build.gradle.kts` - Android Maven package version/publish configuration.
- `docs/COMPANION-PUBLISH-RUNBOOK.md` - existing phase-boundary and recovery runbook surface to update.
- `guides/support_matrix.md` - native shell support truth and proof labels.
- `guides/companion_compatibility.md` - current release-status phase boundary language.

### External Primary References Consulted
- `https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets` - Actions secret availability and masking guidance.
- `https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens` - PAT security, fine-grained token guidance, and GitHub App preference for long-lived integrations.
- `https://docs.github.com/en/rest/git/refs` - Git reference read/write permissions; `Contents:write` for creating/updating refs.
- `https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow` - `workflow_dispatch` operator flow and inputs.
- `https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax` - `needs`, `always()`, job skip/failure propagation, and permissions.
- `https://docs.github.com/en/actions/reference/workflows-and-actions/contexts` - `needs.*.result` and workflow context data.
- `https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#adding-a-job-summary` - GitHub Actions job summaries as operator UI.
- `https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency` - `queue: max`, pending-run replacement, and release queue semantics.
- `https://github.com/googleapis/release-please-action` - Release Please behavior and outputs.
- `https://github.com/marketplace/actions/release-please-action` - `paths_released`, `tag_name`, and `version` output descriptions.
- `https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md` - manifest/release component model and linked versioning context.
- `https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/releasingpublishingapackage/` - SwiftPM release model: single Git repo plus semver tag.
- `https://developer.apple.com/documentation/xcode/publishing-a-swift-package-with-xcode` - Apple package version tag guidance.
- `https://central.sonatype.org/publish/requirements/immutability/` - Maven Central repeatable artifact and roll-forward posture.
- `https://hex.pm/docs/faq` - Hex immutability/recovery posture.
- `https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html` - Hex publish behavior and recovery limits.
- `https://git-scm.com/docs/git-push` - `git push --dry-run` and `--force-with-lease` semantics.
- `https://github.com/splitsh/lite` - splitsh-lite subtree mirror tool used by the release workflow.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.github/workflows/release-please.yml`: already has exact path gates for iOS/Android native paths, `MIRROR_PUSH_TOKEN` empty/read checks, existing-tag skip, splitsh-lite `v1.0.1`, and decoupled iOS/Android clean-room proof jobs.
- `script/check_release_workflow_integrity.exs`: already checks `release.workflow.native_proof_decoupled` and `release.workflow.mirror_token_preflight`; extend it rather than adding an unrelated checker.
- `test/crosswake/proof/phase142_release_integrity_test.exs`: already has stable check-ID assertions and adversarial workflow/script mutation tests.
- `.release-please-manifest.json`: shows `.`, `packages/crosswake-shell-core-ios`, and `packages/crosswake-shell-core-android` at `0.2.0`.
- Local Git tags: `hex-v0.2.0`, `ios-core-v0.2.0`, and `android-core-v0.2.0` all point to `232a37ddeb32ab526142510fb71d746d2e10dc12`.
- Local split corroboration: `git subtree split --prefix=packages/crosswake-shell-core-ios ios-core-v0.2.0` produced `658d60253c58b7e0aedb576f16f40766fa677f23`.

### Established Patterns
- Release safety is encoded in small scripts, named workflow jobs, and ExUnit semantic scanners.
- Registry immutability is modeled as state: already-live exact artifacts are success, mismatched identity fails closed, and recovery is exact-ref/idempotent.
- Operator copy uses `[crosswake]`, names the package/version/ref, and gives a next safe action.
- Phase boundaries are explicit: Phase 145 may create native recovery evidence, while Phase 146 owns the finished local release-status command and JSON UX.

### Integration Points
- MIRR-01 connects to the `publish-ios-core` job, token preflight copy, `git remote` auth, `git ls-remote`, dry-run push, and scanner tests.
- MIRR-02 connects to the native proof `needs` graph, release rollup job, GitHub summaries, JSON artifact, and failure alert conditions.
- MIRR-03 connects to a new verify/backfill script, optional dispatch wrapper, docs/runbook updates, tag/ref verification, and support-matrix/release truth copy.

</code_context>

<specifics>
## Specific Ideas

Recommended iOS mirror release flow:

1. Split `packages/crosswake-shell-core-ios` at the Release Please release ref.
2. Fail if `MIRROR_PUSH_TOKEN` is absent.
3. Add the mirror remote using the token.
4. Check `git ls-remote mirror HEAD` for basic auth/readability.
5. If `refs/tags/v${VERSION}` exists and equals the expected split SHA, print OK and exit.
6. If the tag exists and differs, fail closed.
7. Run `git push --dry-run --porcelain mirror "${SPLIT_SHA}:refs/heads/main" "${SPLIT_SHA}:refs/tags/v${VERSION}"`.
8. Perform the real push only after the dry-run succeeds.

Recommended backfill command shape:

- Verify-only default: `script/<name> --version 0.2.0 --ref refs/tags/ios-core-v0.2.0`
- Mutation requires explicit apply: `script/<name> --version 0.2.0 --ref refs/tags/ios-core-v0.2.0 --apply`
- Optional main update is explicit: `--update-main`, guarded with `--force-with-lease` only after mirror-only commits are ruled out.

Recommended rollup JSON shape:

```json
{
  "version": "0.2.0",
  "native_core": "partial",
  "ios": {
    "released": true,
    "publish": "failed",
    "proof": "skipped",
    "next_action": "fix MIRROR_PUSH_TOKEN or run iOS mirror backfill"
  },
  "android": {
    "released": true,
    "publish": "success",
    "proof": "success"
  }
}
```

</specifics>

<deferred>
## Deferred Ideas

- Full local/text/JSON release status command completion remains Phase 146, though Phase 145 may emit a narrow CI artifact for it.
- Live registry probes in local status remain Phase 146 unless a probe is required to safely verify/backfill the iOS mirror.
- General Maven Central recovery and broader native package recovery UX beyond the iOS `v0.2.0` mirror gap remain out of scope unless needed to keep MIRR-02 reporting honest.
- No graphical dashboard/operator UI in Phase 145; future `crosswake_dashboard` remains DASH-01.
- New runtime capabilities, native feature breadth, offline-sync productization, and companion package additions remain deferred behind v18 release integrity.

</deferred>

---

*Phase: 145-Native Registry & Mirror Parity*
*Context gathered: 2026-07-08*
