---
phase: 153-ios-mirror-unblock
verified: 2026-07-30T21:02:24Z
status: passed
score: 31/31 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 153: iOS Mirror Unblock Verification Report

**Phase Goal:** The iOS SwiftPM shell-core mirror can receive `0.2.0`+ releases again, so this milestone's and every future native release can actually reach iOS adopters.
**Verified:** 2026-07-30T21:02:24Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | The `crosswake-shell-core-ios` mirror repo carries a `v0.2.0` tag matching the live Hex/Maven `0.2.0` core, confirmed via `mix crosswake.release.status --live`. | VERIFIED | Live `git ls-remote` shows mirror `refs/tags/v0.2.0` at `658d60253c58b7e0aedb576f16f40766fa677f23`; Hex and Maven `0.2.0` probes returned HTTP success; `mix crosswake.release.status --live` exited 0 and reported core/native `hex`, `ios-core`, and `android-core` live state `ok`. |
| 2 | A single native shell-core release run publishes Hex, Maven, and the iOS mirror together in one coordinated pass. | VERIFIED | `.github/workflows/release-please.yml` wires `publish-ios-core` after `release-please` and `publish-hex`, checks out the release tag, computes the iOS split, and pushes `main` plus `v${VERSION}` atomically; `publish-android-core`, `clean-room-proof-*`, and `native-release-rollup` remain in the same release workflow. |
| 3 | A missing or invalid mirror push credential (`MIRROR_DEPLOY_KEY`) fails CI with a hard, named error instead of a silent 403. | VERIFIED | `publish-ios-core` has a fail-fast `MIRROR_DEPLOY_KEY is not configured` preflight and classifies SSH auth failure as `MIRROR_DEPLOY_KEY cannot authenticate`; `native-release-rollup` fails partial native releases and `release-failure-alert` includes native jobs. |
| 4 | Backfill lane checkout no longer persists a `GITHUB_TOKEN` extraheader that can hijack the mirror remote. | VERIFIED | `.github/workflows/ios-mirror-backfill.yml` checkout has `persist-credentials: false`; structural scanner `release.ios_backfill.ssh_transport` passed. |
| 5 | Backfill lane authenticates to the mirror over SSH with `MIRROR_DEPLOY_KEY`, never an HTTPS URL-embedded token. | VERIFIED | Backfill workflow loads SHA-pinned `webfactory/ssh-agent` with `MIRROR_DEPLOY_KEY`; script default remote is `git@github.com:szTheory/crosswake-shell-core-ios.git`; `rg` found no `x-access-token` in `.github/` or `script/`. |
| 6 | `apply=false` backfill performs a real dry-run push probe, proving write scope. | VERIFIED | `script/verify_ios_mirror_backfill.sh` runs `git push --dry-run --porcelain` before the verify-only return; live run `30316715897` logged `MIRROR_DEPLOY_KEY has WRITE scope`. |
| 7 | Backfill `--update-main` uses explicit `--force-with-lease=refs/heads/main:<sha-read-via-ls-remote>`. | VERIFIED | Script reads `current_main` with `git ls-remote` and pushes with `--force-with-lease="refs/heads/main:${current_main}"`; phase tests cover stale-lease and disjoint-history behavior. |
| 8 | Backfill ancestry guard distinguishes unknown local object from known non-ancestor. | VERIFIED | Script checks `git cat-file -e "${current_main}^{commit}"` before `merge-base`; unknown object logs advisory, known non-ancestor fails closed. |
| 9 | Existing published mirror tags are never moved by the backfill path. | VERIFIED | Script fail-closes when an existing mirror tag points at a different SHA and only pushes unforced tag refspecs; phase tests prove existing tag immutability. |
| 10 | Hermetic bare-repo fixtures prove the push semantics offline. | VERIFIED | `mix test --only phase153_ios_mirror_unblock` passed 19 tests, including explicit lease, stale lease, tag immutability, parity, and scanner decoys. |
| 11 | Write-enabled deploy key and `MIRROR_DEPLOY_KEY` secret exist. | VERIFIED | Read-only live evidence: `gh secret list` shows `MIRROR_DEPLOY_KEY` on `szTheory/crosswake`; `gh repo deploy-key list` shows `crosswake monorepo split (write)` as `read-write` on the mirror. |
| 12 | CI push credential was exercised in verify-only mode before mutation. | VERIFIED | Run `30316715897` succeeded and logged exact release-ref agreement, live Hex/Maven checks, split SHA `658d60253c58b7e0aedb576f16f40766fa677f23`, dry-run write scope, and no mutation. |
| 13 | Go/no-go was evaluated before mutation and the split SHA recorded. | VERIFIED | Verify-only run logs contain the split SHA; later tag and main evidence match that same SHA. |
| 14 | Mirror `refs/tags/v0.2.0` exists and equals the recorded split SHA. | VERIFIED | Live `git ls-remote` shows `refs/tags/v0.2.0` at `658d60253c58b7e0aedb576f16f40766fa677f23`; tag push run `30316962777` succeeded. |
| 15 | Mirror `main` was separately re-baselined with a leased force-push and `v0.1.2` still resolves. | VERIFIED | Live `refs/heads/main` equals `658d60253c58b7e0aedb576f16f40766fa677f23`; `refs/tags/v0.1.2` remains `6417ae6543219f1c35be120766827503eaa8ceea`; run `30578674382` logged `updated mirror main ... with --force-with-lease`. |
| 16 | Phase 153-02 steps occurred in strict order. | VERIFIED | Read-only run evidence shows verify-only fire drill `30316715897` on 2026-07-28T00:14Z, tag push `30316962777` on 2026-07-28T00:19Z, and corrected main re-baseline `30578674382` on 2026-07-30T20:19Z. |
| 17 | `publish-ios-core` uses `persist-credentials: false` and SSH `MIRROR_DEPLOY_KEY`. | VERIFIED | Release workflow checkout is tag-pinned with `persist-credentials: false`, followed by `MIRROR_DEPLOY_KEY` preflight and SSH agent. |
| 18 | `publish-ios-core` splits from the release tag with full history. | VERIFIED | Workflow checks out `ref: ${{ needs.release-please.outputs.tag_name }}` with `fetch-depth: 0`; scanner `release.ios.checkout_ref_pinned` passed. |
| 19 | `publish-ios-core` gates on `release-please` and `publish-hex`, not Android. | VERIFIED | `needs: [release-please, publish-hex]`; scanner `release.ios.hex_gated` passed. |
| 20 | Release mirror push is one atomic command for `main` and tag, with an explicit lease scoped to `main`. | VERIFIED | Workflow builds `MIRROR_PUSH_ARGS=(--force-with-lease="refs/heads/main:${CURRENT_MAIN_SHA}")`, dry-runs the same atomic form, then runs `git push --atomic mirror ... refs/heads/main ... refs/tags/v${VERSION}`. |
| 21 | `publish-ios-core` keeps `permissions: contents: read`. | VERIFIED | Workflow job retains `permissions: contents: read`; push auth is SSH deploy key. |
| 22 | `release-failure-alert.needs` includes native jobs plus rollup. | VERIFIED | Structural scanner `release.workflow.release_failure_alert_native` passed; release workflow includes native job results in alerting. |
| 23 | `native-release-rollup` exits 1 for incomplete native releases after writing diagnostics. | VERIFIED | Workflow writes `native-release-status.json`, uploads it with `if: ${{ always() }}`, then exits 1 when a native platform released without complete proof; scanner passed. |
| 24 | Retired token touch points are updated. | VERIFIED | `rg MIRROR_PUSH_TOKEN .github/ script/` found no code references in active workflow/script paths; Android fire drill now checks `MIRROR_DEPLOY_KEY`. The old GitHub secret still exists externally, but code no longer uses it. |
| 25 | Every release-lane fix has a structural invariant and decoy tests. | VERIFIED | `elixir script/check_release_workflow_integrity.exs` passed all phase 153 scanner IDs; phase tests passed. |
| 26 | Every released `ios-core-vX` tag has a mirror `vX` tag and violation turns the merge button red. | VERIFIED | `script/check_ios_mirror_parity.sh` passed against the real mirror; `python3 script/list_merge_blocking_checks.py` discovers `merge-blocking-ios-mirror-parity`; live branch protection includes `merge-blocking-ios-mirror-parity`; latest main workflow runs are green. |
| 27 | Parity gate keys on released `ios-core-v*` tags, never `.release-please-manifest.json`. | VERIFIED | Script enumerates `git tag --list 'ios-core-v*'`; source guard test asserts absence of manifest keying; `rg release-please-manifest script/check_ios_mirror_parity.sh` is only explanatory comments and no manifest read. |
| 28 | Missing live mirror tags become `:error`, not `:warning`. | VERIFIED | `live_registry_checks/2` emits `release.live_registry_presence` with `status: :error` for non-bootstrap `:missing`; targeted release-status tests pass. |
| 29 | `:missing` and `:unavailable` are distinct fatal codes. | VERIFIED | `release.live_registry_presence` and `release.live_registry_unverifiable` are separate `:error` checks; `probe_with_retry/3` retries real probes and preserves fake-probe injection seam. |
| 30 | Parity failure microcopy is parser-compatible and adopter-facing. | VERIFIED | `script/check_ios_mirror_parity.sh` emits `[crosswake] FAIL: release.ios_mirror_parity - ...`, names `.package(... from: "X")`, and gives one `gh workflow run ios-mirror-backfill.yml` command. |
| 31 | Parity invariant has non-vacuous tests. | VERIFIED | `mix test --only phase153_ios_mirror_unblock` passed 19 tests, including parity-holds, parity-violated, extra-tags-ok, network-unreachable, source guard, and scanner decoys. |

**Score:** 31/31 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `script/verify_ios_mirror_backfill.sh` | Backfill verification/apply script with SSH transport, dry-run write probe, exact refs, explicit lease | VERIFIED | 276 lines, executable, `bash -n` passed; live runs exercised verify-only, tag push, and main re-baseline. |
| `.github/workflows/ios-mirror-backfill.yml` | Human-dispatched backfill lane with deploy-key SSH | VERIFIED | SHA-pinned checkout, `persist-credentials: false`, SHA-pinned `webfactory/ssh-agent`, script invocation wired. |
| `.github/workflows/release-please.yml` | Coordinated Hex/iOS/Android release workflow | VERIFIED | `publish-ios-core` gated after Hex, atomic mirror push, native rollup fail-closed, native failure alerting wired. |
| `script/check_release_workflow_integrity.exs` | Structural release workflow invariants | VERIFIED | `elixir script/check_release_workflow_integrity.exs` exited 0 and emitted OK for all relevant scanner IDs. |
| `script/check_ios_mirror_parity.sh` | Merge-blocking live mirror parity script | VERIFIED | 187 lines, executable, `bash -n` passed, real mirror check exited 0. |
| `.github/workflows/merge-blocking-ios-mirror-parity.yml` | Required merge-blocking parity workflow | VERIFIED | Literal job/context name is registered in branch protection; recent main runs are green. |
| `lib/crosswake/release_status.ex` | Honest live registry status aggregation | VERIFIED | Distinguishes `:missing`, `:unavailable`, and bootstrap-pending; targeted tests pass. |
| `test/crosswake/proof/phase153_ios_mirror_unblock_test.exs` | Phase proof tests and decoys | VERIFIED | 19 phase-tagged tests pass. |
| `test/mix/tasks/crosswake_release_status_test.exs` | Release status tests | VERIFIED | 17 tests pass. |
| GitHub deploy key and `MIRROR_DEPLOY_KEY` secret | External credential artifacts | VERIFIED | Read-only `gh` checks confirm secret and write-enabled deploy key exist. |
| Mirror refs `v0.2.0`, `v0.1.2`, `main` | Live SwiftPM mirror state | VERIFIED | Live refs match expected SHAs. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `ios-mirror-backfill.yml` | `script/verify_ios_mirror_backfill.sh` | Workflow checkout + SSH agent + script call | WIRED | Workflow loads `MIRROR_DEPLOY_KEY`, disables persisted credentials, then calls the script with exact user inputs. |
| `MIRROR_DEPLOY_KEY` secret | Mirror push auth | `webfactory/ssh-agent` + `git@github.com` remote | WIRED | Live secret exists; live deploy key is read-write; workflows use SSH remote. |
| `verify_ios_mirror_backfill.sh --update-main` | Explicit lease value | `git ls-remote refs/heads/main` -> `--force-with-lease=refs/heads/main:${current_main}` | WIRED | Code and tests verify this path. |
| Release Please tag output | iOS split mirror publish | checkout `ref: tag_name` -> `git subtree split` -> atomic push | WIRED | Prevents retroactive `github.sha` drift and partial mirror state. |
| `publish-hex` | `publish-ios-core` | `needs: [release-please, publish-hex]` | WIRED | Least-recoverable iOS mirror runs after Hex. |
| Native jobs | Failure persistence | `native-release-rollup` -> `release-failure-alert` -> issue creation | WIRED | Scanner confirms native jobs and rollup are in alerting path. |
| Local `ios-core-v*` tags | Branch protection | parity script -> workflow job -> required check | WIRED | Live required contexts include `merge-blocking-ios-mirror-parity`; registration audit passes. |
| Live probe result | Release status exit behavior | probe status -> `live_registry_checks/2` -> `exit_code/1` | WIRED | Targeted tests pass; live iOS probe reports OK. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `script/check_ios_mirror_parity.sh` | Local/mirror version sets | `git tag --list 'ios-core-v*'` and unauthenticated `git ls-remote --tags` | Yes | VERIFIED - real mirror run returned OK for `0.1.2` and `0.2.0`. |
| `lib/crosswake/release_status.ex` | Live registry entries | HTTP and git live probes | Yes | VERIFIED - live command reports core/native Hex, iOS mirror, and Maven states `ok`; unrelated bootstrap companion warnings do not affect MIRROR. |
| `.github/workflows/release-please.yml` | Release version and tag identity | `needs.release-please.outputs.version` and `tag_name` | Yes | VERIFIED - workflow uses release-please outputs directly for checkout and mirror tag. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Live mirror parity holds | `script/check_ios_mirror_parity.sh` | Exit 0; mirror carries tags for `0.1.2` and `0.2.0` | PASS |
| Release workflow structural invariants hold | `elixir script/check_release_workflow_integrity.exs` | Exit 0; all phase 153 release/backfill IDs OK | PASS |
| Live release status confirms iOS mirror | `mix crosswake.release.status --live` | Exit 0; core/native live states OK; overall status warning only for unrelated bootstrap-pending companions | PASS |
| Phase behavior tests pass | `mix test --only phase153_ios_mirror_unblock` | 19 tests, 0 failures | PASS |
| Release status tests pass | `mix test test/mix/tasks/crosswake_release_status_test.exs` | 17 tests, 0 failures | PASS |
| Branch protection carries parity gate | `gh api ...required_status_checks -q '.contexts'` | Context list includes `merge-blocking-ios-mirror-parity` | PASS |
| Registered-check audit | `script/check_required_checks_registered.sh` | OK: all 26 declared merge-blocking lanes registered | PASS |

### Probe Execution

| Probe | Command | Result | Status |
|---|---|---|---|
| Conventional probe scripts | `find scripts -path '*/tests/probe-*.sh' -type f` | No phase-relevant probe scripts found | SKIP |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| MIRROR-01 | 153-01, 153-02, 153-04 | Mirror carries `v0.2.0` matching live Hex/Maven `0.2.0` core | SATISFIED | Live Hex and Maven probes OK; live mirror `v0.2.0` equals recorded split SHA; `v0.1.2` still resolves; `mix crosswake.release.status --live` exits 0 with iOS mirror OK. |
| MIRROR-02 | 153-01, 153-03, 153-04 | Native release publishes Hex, Maven, and iOS mirror in one run; mirror push failure is hard/named | SATISFIED | Release workflow coordinates Hex/iOS/Android; mirror push is SSH, tag-pinned, Hex-gated, atomic, explicitly leased; native rollup fails partial releases; native failures alert; parity gate is registered required check. |

No orphaned Phase 153 requirements found in `.planning/REQUIREMENTS.md`. Phase 153.1 requirements are explicitly separate and not part of this verification.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `.github/workflows/release-please.yml` | 423 | Dynamic `ssh-keyscan` host-key learning | WARNING | Matches 153-REVIEW WR-01: non-interactive SSH works, but the host key is learned dynamically rather than pinned. This is a hardening issue, not a failure of MIRROR-01/02 because the parity gate and live mirror checks still detect real mirror drift. |
| `.github/workflows/ios-mirror-backfill.yml` | 80 | Dynamic `ssh-keyscan` host-key learning | WARNING | Same as above for the backfill lane. |

No unreferenced `TBD`, `FIXME`, or `XXX` markers were found in phase-modified files. The only `TODO` grep hit was historical release-as cleanup copy in `release-please.yml`, not a phase completion stub.

### Human Verification Required

None.

### Gaps Summary

No blocking gaps found. The phase goal is achieved: iOS adopters can resolve the current `crosswake-shell-core-ios` `v0.2.0` mirror tag, future native releases have a coordinated Hex/iOS/Android release path with hard named failures, and the live parity guard is registered as a required merge-blocking check.

---

_Verified: 2026-07-30T21:02:24Z_
_Verifier: the agent (gsd-verifier)_
