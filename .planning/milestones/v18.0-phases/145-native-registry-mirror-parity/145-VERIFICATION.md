---
phase: 145-native-registry-mirror-parity
status: passed
verified: 2026-07-08T19:02:50Z
requirements:
  - MIRR-01
  - MIRR-02
  - MIRR-03
score: 12/12
behavior_unverified: 0
overrides_applied: 0
human_verification: []
---

# Phase 145: Native Registry & Mirror Parity Verification Report

**Phase Goal:** Harden the iOS mirror token path, decouple native clean-room proofs, and document/backfill the missing `v0.2.0` SwiftPM tag.
**Verified:** 2026-07-08T19:02:50Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | MIRR-01 iOS mirror publishing fails fast when `MIRROR_PUSH_TOKEN` is absent. | VERIFIED | `.github/workflows/release-please.yml` checks `MIRROR_TOKEN` before remote setup and exits with `[crosswake] FAIL` copy. Scanner IDs `release.mirror_token.preflight` and `release.workflow.mirror_token_preflight` passed. |
| 2 | MIRR-01 checks mirror read access and write authority before real mirror mutation. | VERIFIED | `publish-ios-core` runs `git ls-remote mirror HEAD`, then `git push --dry-run --porcelain mirror "${SPLIT_SHA}:refs/heads/main" "${SPLIT_SHA}:refs/tags/v${VERSION}"` before the real pushes. Scanner ID `release.mirror_token.write_preflight` passed. |
| 3 | MIRR-01 mirror tag handling is idempotent and fail-closed. | VERIFIED | Workflow exits 0 when existing `refs/tags/v${VERSION}` equals `SPLIT_SHA`, and fails without tag movement when the existing tag points elsewhere. `:phase145_mirror` fixtures passed. |
| 4 | MIRR-02 iOS and Android clean-room proofs no longer depend on the sibling native publish job. | VERIFIED | `clean-room-proof-ios` needs `publish-ios-core` but not `publish-android-core`; `clean-room-proof-android` needs `publish-android-core` but not `publish-ios-core`. Scanner IDs `release.workflow.native_proof_decoupled`, `release.ios_proof.decoupled`, and `release.android_proof.decoupled` passed. |
| 5 | MIRR-02 native release state is summarized after jobs settle rather than by coupling proof DAGs. | VERIFIED | `native-release-rollup` has `if: ${{ always() }}`, needs both native publish/proof paths, reads `needs.*.result`, and reports `native_core=none|partial|complete` plus next action. |
| 6 | MIRR-02 emits machine-readable rollup evidence. | VERIFIED | Rollup writes `native-release-status.json` and uploads artifact `native-release-status` with `if-no-files-found: error`. Scanner IDs `release.workflow.native_rollup_summary` and `release.workflow.native_status_artifact` passed. |
| 7 | MIRR-03 backfill is verify-first; mutation requires explicit `--apply` and token. | VERIFIED | `script/verify_ios_mirror_backfill.sh` defaults `APPLY=0`, reports absent mirror tags without requiring `MIRROR_PUSH_TOKEN`, and fails `--apply` without the token. Script fixture suite passed. |
| 8 | MIRR-03 source authority is exact Release Please component refs and lockstep metadata. | VERIFIED | Script rejects `main`, `master`, `HEAD`, `heads/*`, `refs/heads/*`, bare `v*`, and bare version-like refs; requires `refs/tags/ios-core-v${VERSION}`; checks `hex-v${VERSION}`, `ios-core-v${VERSION}`, and `android-core-v${VERSION}` commit equality plus `.release-please-manifest.json` root/iOS/Android versions. |
| 9 | MIRR-03 verifies already-live root/native registry state before iOS mirror mutation. | VERIFIED | Script checks Hex `crosswake VERSION` and Maven `io.github.sztheory:crosswake-shell-core-android:VERSION` before apply-mode mutation, with env overrides only for local fixture tests. |
| 10 | MIRR-03 mirror mutation is tag-first, idempotent, and fail-closed. | VERIFIED | Script computes the iOS split with splitsh-lite v1.0.1, treats exact existing `refs/tags/v${VERSION}` as success, fails mismatched public tags without delete/move, dry-runs before apply push, and gates `main` realignment behind explicit `--update-main` with `--force-with-lease`. |
| 11 | MIRR-03 workflow wrapper is thin and scanner-backed. | VERIFIED | `.github/workflows/ios-mirror-backfill.yml` exposes typed `version`, `release_ref`, `apply`, and `update_main` inputs, defaults to `0.2.0` / `refs/tags/ios-core-v0.2.0` / verify-only, installs splitsh-lite v1.0.1, and delegates to `script/verify_ios_mirror_backfill.sh`. Scanner checks bind defaults to named input blocks and `:phase145_ios_backfill` fixtures passed. |
| 12 | Operator docs keep offline/native claims honest. | VERIFIED | Runbook documents verify/apply commands, exact/missing/mismatch outcomes, live Hex/Maven preconditions, and why rerunning the original release job is not primary recovery. Support/compatibility guides state SwiftPM mirror backfill is registry evidence, not device/emulator proof or companion floor normalization. |

**Score:** 12/12 truths verified (0 behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `.github/workflows/release-please.yml` | MIRR-01 preflight and MIRR-02 rollup | VERIFIED | Contains dry-run mirror write-authority probe, exact/mismatch tag handling, decoupled native proof needs, and always-running native rollup/artifact. |
| `script/verify_ios_mirror_backfill.sh` | Verify-first iOS mirror backfill | VERIFIED | Strict Bash with exact-ref validation, lockstep tag/manifest checks, live registry checks, splitsh-lite v1.0.1 split, idempotent tag behavior, and guarded apply/main paths. |
| `.github/workflows/ios-mirror-backfill.yml` | Manual operator wrapper | VERIFIED | `workflow_dispatch` wrapper validates inputs, checks out full history, installs splitsh-lite, passes token only to script step, and writes `$GITHUB_STEP_SUMMARY`. |
| `script/check_release_workflow_integrity.exs` | MIRR-01/MIRR-02/MIRR-03 scanner IDs | VERIFIED | Emits `release.mirror_token.write_preflight`, `release.workflow.native_*`, and `release.ios_backfill.*` IDs with env-overridable backfill fixture paths. |
| `test/crosswake/proof/phase142_release_integrity_test.exs` | Adversarial scanner fixtures | VERIFIED | Covers mirror dry-run decoys, native proof coupling, rollup artifact/partial-state regressions, and iOS backfill default/ref/idempotency/main-force regressions. |
| `test/crosswake/proof/phase145_ios_backfill_script_test.exs` | Backfill script behavior fixtures | VERIFIED | Local Git fixtures cover verify-only/no-token, apply-without-token, exact-tag no-op, and mismatched-tag fail-closed behavior. |
| `docs/COMPANION-PUBLISH-RUNBOOK.md` | Operator recovery path | VERIFIED | Documents canonical verify/apply commands and state outcomes. |
| `guides/support_matrix.md` and `guides/companion_compatibility.md` | Support truth boundaries | VERIFIED | Keep registry status separate from device/emulator proof and compatibility floor claims. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `.github/workflows/release-please.yml` | iOS mirror repository | dry-run then real push | VERIFIED | Token presence, read access, exact tag state, and dry-run write authority all happen before mutation. |
| `.github/workflows/release-please.yml` | native proof jobs | `needs.*.result` rollup | VERIFIED | Rollup observes final job results and does not add sibling publish dependencies to proof jobs. |
| `.github/workflows/ios-mirror-backfill.yml` | `script/verify_ios_mirror_backfill.sh` | `bash script/verify_ios_mirror_backfill.sh "${args[@]}"` | VERIFIED | Workflow delegates all registry/tag/split decisions to the script. |
| `script/verify_ios_mirror_backfill.sh` | Release Please tags and manifest | exact ref/tag/manifest checks | VERIFIED | Backfill source identity comes from component tags and manifest version truth, not current checkout branch state. |
| `script/check_release_workflow_integrity.exs` | ExUnit fixtures | env-overridable fixture paths | VERIFIED | Tests mutate temp script/workflow files and assert stable scanner failure IDs. |
| docs/guides | release artifacts | recovery/support wording | VERIFIED | Operator docs match implemented command names, refs, state outcomes, and support boundaries. |

### Automated Verification

| Command | Result |
|---|---|
| `bash -n script/verify_ios_mirror_backfill.sh` | passed |
| `elixir script/check_release_workflow_integrity.exs` | passed; all release integrity IDs OK |
| `mix test test/crosswake/proof/phase142_release_integrity_test.exs test/crosswake/proof/phase145_ios_backfill_script_test.exs` | passed; 62 tests, 0 failures |
| `grep -n "verify_ios_mirror_backfill.sh" docs/COMPANION-PUBLISH-RUNBOOK.md && grep -n "refs/tags/ios-core-v0.2.0" docs/COMPANION-PUBLISH-RUNBOOK.md && grep -n "SwiftPM" guides/support_matrix.md && grep -n "Phase 145" guides/companion_compatibility.md` | passed |
| `git diff --check 10bafece..HEAD -- ':!.planning/**'` | passed |

### Code Review

| Finding | Status | Evidence |
|---|---|---|
| MIRR-03 scanner accepted any `default: false` instead of the named `apply` / `update_main` input defaults. | RESOLVED | Commit `3ff2c5c5` added `workflow_input_default?/3` and negative fixtures for `apply default: true` and `update_main default: true`; focused tests passed. |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| MIRR-01 | 145-01 | The iOS mirror job fails fast when `MIRROR_PUSH_TOKEN` is absent or unusable. | SATISFIED | Token presence, mirror read access, dry-run write authority, exact tag no-op, mismatch fail-closed behavior, scanner, and fixtures all passed. |
| MIRR-02 | 145-02 | iOS and Android clean-room proofs no longer depend on each other when only one native registry path fails. | SATISFIED | Proof DAGs are sibling-decoupled and `native-release-rollup` reports partial/complete state after jobs settle. |
| MIRR-03 | 145-03 | Maintainers have an explicit path to verify or backfill the missing iOS `v0.2.0` mirror tag. | SATISFIED | Verify-first script, manual workflow wrapper, scanner fixtures, script fixtures, and runbook/support docs are present and verified. |

No orphaned Phase 145 requirement IDs were found in `.planning/REQUIREMENTS.md`; `MIRR-01`, `MIRR-02`, and `MIRR-03` are mapped to Phase 145 and marked complete.

### Human Verification Required

None for phase completion. Live apply-mode mirror mutation still requires the external `MIRROR_PUSH_TOKEN` setup documented in `145-USER-SETUP.md`.

### Gaps Summary

No blocking gaps found. Phase 145 delivers the native registry parity guardrails, rollup evidence, and verify-first iOS mirror backfill path without widening native proof or compatibility-floor claims.

---

_Verified: 2026-07-08T19:02:50Z_
_Verifier: Codex inline verification fallback_
