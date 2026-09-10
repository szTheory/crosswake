---
phase: "167"
slug: "documentation-and-pull-request-reconciliation"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-10"
---

# Phase 167 — Validation Strategy

> Per-phase validation contract for documentation authority, parked-adopter truth, and guarded pull-request reconciliation.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on the repository-pinned Elixir/OTP toolchain, Node built-in tests, repository scripts, Swift Package Manager, and read-only GitHub CLI queries |
| **Config file** | `test/test_helper.exs`; repository-policy fixtures under `test/js`; GitHub state queried immediately before and after each remote action |
| **Quick run command** | `mix test test/mix/tasks/crosswake.docs.sync_test.exs test/crosswake/support_matrix test/crosswake/capability_map` |
| **Full suite command** | `mix crosswake.docs.sync --check && mix crosswake.adoption_context.scan && node --test test/js/repository_verification.test.mjs` plus the existing `documentation-contracts`, package/ExDoc, and `Crosswake CI` owners |
| **Estimated runtime** | Focused local checks under 120 seconds after the pinned Erlang/Elixir toolchain is available; hosted GitHub checks are observed, not time-thresholded |

---

## Sampling Rate

- **After every task commit:** Run the smallest affected ExUnit or Node test and `mix crosswake.docs.sync --check` once generated projections exist.
- **After every plan wave:** Run the documentation-contract, package/ExDoc, privacy-scan, repository-policy, and docs-only-routing checks touched by that wave.
- **Before `$gsd-verify-work`:** Run the full recurring documentation proof, confirm `Crosswake CI` is green for the final code SHA, and validate the phase-local five-PR disposition artifact against freshly queried GitHub state.
- **Max feedback latency:** 120 seconds for focused local checks; no threshold for external GitHub queue time.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 167-W0-01 | TBD | 1 | DOC-01 | T-167-01, T-167-02 | Canonical claim data rejects every impossible evidence/source/activation combination before rendering | unit + negative fixtures | `mix test test/crosswake/support_matrix test/crosswake/capability_map` | ❌ W0 focused cross-field fixtures | ⬜ pending |
| 167-W0-02 | TBD | 1 | DOC-01 | T-167-03 | `mix crosswake.docs.sync --check` byte-compares both generated guides without writing or staging files and names source, target, and correction command on drift | Mix task integration | `mix test test/mix/tasks/crosswake.docs.sync_test.exs` | ❌ W0 | ⬜ pending |
| 167-W0-03 | TBD | 1 | DOC-01 | T-167-03, T-167-04 | The existing artifact policy accepts multiple fixed-purpose generators, rejects malformed/colliding records, and restores registered outputs | Node unit + negative fixtures | `node --test test/js/repository_verification.test.mjs` | ❌ W0 multi-record fixtures | ⬜ pending |
| 167-W0-04 | TBD | 2 | DOC-01, DOC-02 | T-167-01, T-167-05 | Current narratives agree with generated truth, preserve ExDoc topology, and expose no private adopter facts | ExUnit semantic + privacy scan | `mix crosswake.adoption_context.scan && mix test test/crosswake/guides test/crosswake/planning/first_adopter_context_test.exs` | ✅ existing homes; ❌ focused parked-state assertion | ⬜ pending |
| 167-W0-05 | TBD | 3 | DOC-03 | T-167-06, T-167-07 | Each PR mutation is preceded by exact head/base/check refresh and stops on any mismatch; release PRs remain open and unmerged | structured GitHub query + artifact validation | `gh pr list --state open --json number,headRefOid,baseRefOid,mergeStateStatus,statusCheckRollup` | ✅ CLI; ❌ phase-local validator | ⬜ pending |
| 167-W0-06 | TBD | 3 | DOC-03 | T-167-05, T-167-07 | The retained record contains only the five approved PR numbers, full SHAs, closed check/disposition values, current reason, and next gate | artifact schema + privacy scan | `mix crosswake.adoption_context.scan` plus the phase-local disposition verifier | ❌ W0 phase-local artifact verifier | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mix/tasks/crosswake.docs.sync_test.exs` — write mode, successful `--check`, drift failure, no-write proof, and exact remediation output.
- [ ] Focused canonical-claim fixtures — the three required claim layers and all five D-20 impossible combinations.
- [ ] Multi-record repository-policy fixtures — one/multiple argv, duplicate source/output, unordered output, unsafe argv, undeclared output, and restoration behavior.
- [ ] Focused parked-state/current-claim assertion — codename-only durable state and the exact external route/device resume gate.
- [ ] Phase-local disposition verifier — exact five-PR allowlist with full head/base SHAs, checks, disposition, current reason, next gate, and privacy-safe fields only.
- [ ] Restore or select the repository-pinned Erlang/Elixir toolchain before any local Mix verification claim.

---

## Manual-Only Verifications

All phase behavior and evidence evaluation is automated. If GitHub credentials or branch permissions are unavailable, a maintainer may supply that external authority, but exact-SHA/check assertions and post-action evidence remain automated. PR #115 and PR #57 are explicit non-mutation boundaries; their merges require the separate Phase 168 release approval.

---

## Security Threat References

| Ref | Threat | Required Mitigation |
|-----|--------|---------------------|
| T-167-01 | Reference-host evidence is rendered as current first-adopter support | Model evidence subject, source binding, and activation independently; reject contradictory combinations before rendering. |
| T-167-02 | Generated and authored documents become competing truth stores | Change executable owners first, regenerate byte-stable projections, and protect authored prose with semantic assertions only. |
| T-167-03 | A documentation parity check mutates or stages the worktree | Render in memory for `--check`; compare bytes without invoking writers; preserve index and working-tree state. |
| T-167-04 | A second artifact registry or CI context creates split authority | Extend `script/repository_artifact_policy.json` and the existing documentation/package owners only. |
| T-167-05 | Adopter identity, payload, credential, device, or private-route data leaks into docs/evidence | Use closed low-cardinality fields and the existing destination-aware privacy scanner; never echo untrusted values. |
| T-167-06 | PR state changes between observation and mutation | Refresh exact head/base/check state immediately before each action and stop on mismatch. |
| T-167-07 | A stale or release-triggering PR is merged accidentally | Apply only the locked disposition for each exact PR number; keep #115/#57 open and deferred to Phase 168. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification.
- [ ] Wave 0 covers all MISSING references.
- [ ] No watch-mode flags.
- [ ] Feedback latency is under 120 seconds for focused local checks.
- [ ] `nyquist_compliant: true` is set in frontmatter after validation.

**Approval:** pending
