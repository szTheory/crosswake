---
phase: 145
slug: native-registry-mirror-parity
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-08
---

# Phase 145 - Validation Strategy

> Per-phase validation contract for native registry and mirror parity work.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit bundled with Elixir/Mix 1.19.5 plus dependency-free Elixir workflow scanner |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `elixir script/check_release_workflow_integrity.exs && mix test test/crosswake/proof/phase142_release_integrity_test.exs` |
| **Phase-focused command** | `elixir script/check_release_workflow_integrity.exs && mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase145_mirror && mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase145_native_rollup && mix test test/crosswake/proof/phase145_ios_backfill_script_test.exs && mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase145_ios_backfill` |
| **Full suite command** | `mix test --exclude requires_example_host --exclude advisory_only` |
| **Estimated runtime** | ~20 seconds focused, ~45 seconds full local hermetic gate |

---

## Sampling Rate

- **After every task commit:** Run the task's focused `<verify>` command.
- **After every plan wave:** Run `elixir script/check_release_workflow_integrity.exs` plus the relevant tagged Phase 145 ExUnit group.
- **Before `/gsd:verify-work`:** Run the full Phase 145 focused command and `mix test test/crosswake/proof/phase142_release_integrity_test.exs`.
- **Max feedback latency:** ~20 seconds for targeted Phase 145 feedback.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 145-01-01 | 01 | 1 | MIRR-01 | T-145-01 | `publish-ios-core` requires `MIRROR_PUSH_TOKEN`, validates read access, and proves write authority with non-mutating `git push --dry-run --porcelain` before the real mirror push. | scanner + ExUnit negative fixture | `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase145_mirror` | scanner/test files exist; Phase 145 IDs pending | pending |
| 145-01-02 | 01 | 1 | MIRR-01 | T-145-02 | Failure copy names `szTheory/crosswake-shell-core-ios`, `refs/tags/v${VERSION}`, required `Contents:write`, and the next safe recovery path without exposing token values. | scanner + source assertion | `elixir script/check_release_workflow_integrity.exs` | workflow/scanner exist; check pending | pending |
| 145-02-01 | 02 | 2 | MIRR-02 | T-145-03 | `clean-room-proof-ios` and `clean-room-proof-android` depend only on root Hex plus their own native publish path, never on the sibling platform. | scanner + ExUnit negative fixture | `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase145_native_rollup` | existing decoupling check present; Phase 145 regression fixtures pending | pending |
| 145-02-02 | 02 | 2 | MIRR-02 | T-145-04 | An always-running native rollup uses `needs.*.result`, reports per-platform state, writes `$GITHUB_STEP_SUMMARY`, and uploads a narrow JSON status artifact. | scanner + fixture | `elixir script/check_release_workflow_integrity.exs && mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase145_native_rollup` | workflow/scanner exist; rollup missing | pending |
| 145-03-01 | 03 | 3 | MIRR-03 | T-145-05 | Backfill script defaults to verify-only, rejects current `main`/`HEAD`, requires explicit `--apply` for mutation, and verifies the exact Release Please component ref before split. | script smoke + scanner fixture | `bash -n script/verify_ios_mirror_backfill.sh && mix test test/crosswake/proof/phase145_ios_backfill_script_test.exs` | script and fixture test missing; scanner/test files exist | pending |
| 145-03-02 | 03 | 3 | MIRR-03 | T-145-06 | Existing mirror tag at the expected split SHA exits 0 without push; existing mirror tag mismatch fails closed and does not delete or move public tags. | script fixture + scanner fixture | `mix test test/crosswake/proof/phase145_ios_backfill_script_test.exs` | script and fixture test missing; scanner/test files exist | pending |
| 145-03-03 | 03 | 3 | MIRR-03 | T-145-07 | Thin `workflow_dispatch` wrapper validates typed inputs, delegates to the script, and publishes a concise job summary without duplicating backfill logic. | scanner + workflow fixture | `elixir script/check_release_workflow_integrity.exs` | workflow/scanner exist; wrapper pending | pending |

---

## Requirement Coverage

| Requirement | Coverage Target | Automated Evidence | Status |
|-------------|-----------------|--------------------|--------|
| MIRR-01 | iOS mirror publish fails fast on absent/unusable credentials and includes a push-authority dry-run before the real mirror mutation. | `release.mirror_token.write_preflight` scanner ID plus `:phase145_mirror` negative fixtures for read-only-only preflight. | planned |
| MIRR-02 | Native proof jobs remain platform-independent and partial native states are visible through an always-running rollup summary/artifact. | `release.workflow.native_rollup_summary`, `release.workflow.native_status_artifact`, existing/native decoupling checks, and `:phase145_native_rollup` fixtures. | planned |
| MIRR-03 | Maintainers can verify or explicitly apply the missing iOS `v0.2.0` mirror tag using exact release refs and idempotent tag checks. | `release.ios_backfill.*` scanner IDs, script smoke tests, workflow-dispatch fixture, and `:phase145_ios_backfill` fixtures. | planned |

---

## Wave 0 Requirements

- [ ] `script/check_release_workflow_integrity.exs` exposes Phase 145 scanner IDs: `release.mirror_token.write_preflight`, `release.ios_backfill.verify_first`, `release.ios_backfill.exact_release_ref`, `release.ios_backfill.tag_idempotent`, `release.ios_backfill.no_default_main_force`, `release.workflow.native_rollup_summary`, and `release.workflow.native_status_artifact`.
- [ ] `test/crosswake/proof/phase142_release_integrity_test.exs` contains Phase 145 tags and negative fixtures for read-only-only token checks, current-HEAD backfill, backfill without explicit `--apply`, existing tag mismatch ignored, iOS proof needing Android publish, Android proof needing iOS publish, and false `native_core=complete` copy when one platform failed.
- [ ] The iOS mirror backfill script exists in `script/`, defaults to verify-only, and can run verification mode without `MIRROR_PUSH_TOKEN`.
- [ ] `test/crosswake/proof/phase145_ios_backfill_script_test.exs` executes mocked verify-only/no-token, apply-token, exact-tag, and mismatched-tag branches without public remotes.
- [ ] Native rollup JSON shape is stable enough for Phase 146 to consume without claiming the full `mix crosswake.release.status --json` surface complete.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real `MIRROR_PUSH_TOKEN` can push to `szTheory/crosswake-shell-core-ios` | MIRR-01, MIRR-03 | The local test suite cannot safely exercise a live secret or mutate the public mirror by default. | Run the dispatch workflow or release job in apply mode only after scanner/script proof is green; confirm the job summary reports the expected package, version, release ref, split SHA, and mirror tag state. |

---

## Validation Sign-Off

- [ ] All tasks have focused automated verification.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all missing scanner, fixture, and script references.
- [ ] No watch-mode flags.
- [ ] Feedback latency < 20 seconds for focused checks.
- [ ] `nyquist_compliant: true` set in frontmatter after execution evidence passes.

**Approval:** pending
